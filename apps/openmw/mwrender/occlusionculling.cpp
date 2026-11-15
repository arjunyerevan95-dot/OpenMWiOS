#include "occlusionculling.hpp"

#include <algorithm>
#include <cmath>
#include <queue>

#include <osg/AlphaFunc>
#include <osg/BoundingBox>
#include <osg/BoundingSphere>
#include <osg/Camera>
#include <osg/ComputeBoundsVisitor>
#include <osg/Geometry>
#include <osg/Group>
#include <osg/NodeVisitor>
#include <osg/Transform>
#include <osgUtil/CullVisitor>

#include <components/debug/debuglog.hpp>
#include <components/misc/constants.hpp>
#include <components/sceneutil/occlusionculling.hpp>
#include <components/terrain/terrainoccluder.hpp>

namespace
{
    class CollectMeshVisitor : public osg::NodeVisitor
    {
    public:
        CollectMeshVisitor()
            : osg::NodeVisitor(TRAVERSE_ALL_CHILDREN)
        {
        }

        void apply(osg::Transform& transform) override
        {
            osg::Matrix matrix;
            if (!mMatrixStack.empty())
                matrix = mMatrixStack.back();
            transform.computeLocalToWorldMatrix(matrix, this);
            mMatrixStack.push_back(matrix);
            traverse(transform);
            mMatrixStack.pop_back();
        }

        void apply(osg::Drawable& drawable) override
        {
            auto* geom = drawable.asGeometry();
            if (!geom)
                return;

            // Fail open for any inherited transparency or animation. Overrides do
            // not rescue a candidate: excluding an occluder costs speed, not pixels.
            for (const osg::Node* node : getNodePath())
            {
                if (node->getUpdateCallback())
                    return;
                const osg::StateSet* ss = node->getStateSet();
                if (ss && (ss->getAttribute(osg::StateAttribute::ALPHAFUNC)
                    || (ss->getMode(GL_BLEND) & osg::StateAttribute::ON)
                    || ss->getRenderingHint() == osg::StateSet::TRANSPARENT_BIN))
                    return;
            }

            const auto* verts = dynamic_cast<const osg::Vec3Array*>(geom->getVertexArray());
            if (!verts || verts->empty())
                return;

            osg::Matrix matrix;
            if (!mMatrixStack.empty())
                matrix = mMatrixStack.back();

            unsigned int baseVertex = static_cast<unsigned int>(mVertices.size());
            for (const auto& v : *verts)
                mVertices.push_back(v * matrix);

            for (unsigned int p = 0; p < geom->getNumPrimitiveSets(); ++p)
                collectTriangles(geom->getPrimitiveSet(p), baseVertex);
        }

        std::vector<osg::Vec3f> mVertices;
        std::vector<unsigned int> mIndices;

    private:
        void collectTriangles(const osg::PrimitiveSet* pset, unsigned int baseVertex)
        {
            unsigned int count = pset->getNumIndices();
            switch (pset->getMode())
            {
                case GL_TRIANGLES:
                    for (unsigned int i = 0; i + 2 < count; i += 3)
                    {
                        mIndices.push_back(baseVertex + pset->index(i));
                        mIndices.push_back(baseVertex + pset->index(i + 1));
                        mIndices.push_back(baseVertex + pset->index(i + 2));
                    }
                    break;
                case GL_TRIANGLE_STRIP:
                    for (unsigned int i = 0; i + 2 < count; ++i)
                    {
                        if (i % 2 == 0)
                        {
                            mIndices.push_back(baseVertex + pset->index(i));
                            mIndices.push_back(baseVertex + pset->index(i + 1));
                            mIndices.push_back(baseVertex + pset->index(i + 2));
                        }
                        else
                        {
                            mIndices.push_back(baseVertex + pset->index(i + 1));
                            mIndices.push_back(baseVertex + pset->index(i));
                            mIndices.push_back(baseVertex + pset->index(i + 2));
                        }
                    }
                    break;
                case GL_TRIANGLE_FAN:
                    for (unsigned int i = 1; i + 1 < count; ++i)
                    {
                        mIndices.push_back(baseVertex + pset->index(0));
                        mIndices.push_back(baseVertex + pset->index(i));
                        mIndices.push_back(baseVertex + pset->index(i + 1));
                    }
                    break;
                default:
                    break;
            }
        }

        std::vector<osg::Matrix> mMatrixStack;
    };
}

namespace MWRender
{
    OccluderMesh buildSimplifiedMesh(osg::Node* node, int gridRes, float shrinkFactor)
    {
        OccluderMesh mesh;

        CollectMeshVisitor cmv;
        node->accept(cmv);

        if (cmv.mIndices.empty() || cmv.mVertices.size() < 3)
        {
            osg::ComputeBoundsVisitor cbv;
            node->accept(cbv);
            mesh.aabb = cbv.getBoundingBox();
            return mesh;
        }

        for (const auto& v : cmv.mVertices)
            mesh.aabb.expandBy(v);
        // Preserve the original opaque triangles. Averaging/clustering vertices can
        // expand silhouettes and fill doors/windows; a bounding box is not an occluder.
        // Budgeting may omit whole triangles later, never invent coverage.
        // Bounded cost without geometry distortion: retain at most 1024 original
        // triangles, choosing largest surface area. Removing triangles can only
        // reduce occlusion coverage, never fill an arch/window.
        struct Triangle { unsigned int a, b, c; float area; };
        std::vector<Triangle> triangles;
        for (size_t i = 0; i + 2 < cmv.mIndices.size(); i += 3)
        {
            unsigned int a = cmv.mIndices[i], b = cmv.mIndices[i+1], c = cmv.mIndices[i+2];
            if (a >= cmv.mVertices.size() || b >= cmv.mVertices.size() || c >= cmv.mVertices.size()) continue;
            float area = ((cmv.mVertices[b]-cmv.mVertices[a]) ^ (cmv.mVertices[c]-cmv.mVertices[a])).length2();
            if (std::isfinite(area) && area > 0) triangles.push_back({a,b,c,area});
        }
        if (triangles.size() > 1024)
        {
            std::partial_sort(triangles.begin(), triangles.begin()+1024, triangles.end(),
                [](const Triangle& a, const Triangle& b){ return a.area > b.area; });
            triangles.resize(1024);
        }
        std::unordered_map<unsigned int, unsigned int> remap;
        for (const auto& tri : triangles)
            for (const auto index : {tri.a,tri.b,tri.c})
            {
                auto [it, added] = remap.emplace(index, mesh.vertices.size());
                if (added) mesh.vertices.push_back(cmv.mVertices[index]);
                mesh.indices.push_back(it->second);
            }
        (void)gridRes;
        (void)shrinkFactor;

        return mesh;
    }

    SceneOcclusionCallback::SceneOcclusionCallback(SceneUtil::OcclusionCuller* culler,
        Terrain::TerrainOccluder* occluder, int radiusCells, bool enableTerrainOccluder, bool enableDebugOverlay)
        : mCuller(culler)
        , mTerrainOccluder(occluder)
        , mRadiusCells(radiusCells)
        , mEnableTerrainOccluder(enableTerrainOccluder)
        , mEnableDebugOverlay(enableDebugOverlay)
    {
    }

    void SceneOcclusionCallback::setupDebugOverlay()
    {
        unsigned int w, h;
        mCuller->getResolution(w, h);
        if (w == 0 || h == 0)
            return;

        mDepthPixels.resize(w * h);

        // Create image to hold depth data (luminance float -> converted to RGBA)
        mDebugImage = new osg::Image;
        mDebugImage->allocateImage(w, h, 1, GL_LUMINANCE, GL_FLOAT);

        // Create texture from image
        mDebugTexture = new osg::Texture2D(mDebugImage);
        mDebugTexture->setFilter(osg::Texture::MIN_FILTER, osg::Texture::NEAREST);
        mDebugTexture->setFilter(osg::Texture::MAG_FILTER, osg::Texture::NEAREST);
        mDebugTexture->setWrap(osg::Texture::WRAP_S, osg::Texture::CLAMP_TO_EDGE);
        mDebugTexture->setWrap(osg::Texture::WRAP_T, osg::Texture::CLAMP_TO_EDGE);
        mDebugTexture->setResizeNonPowerOfTwoHint(false);

        // Create POST_RENDER camera in corner of screen
        mDebugCamera = new osg::Camera;
        mDebugCamera->setName("OcclusionDebugCamera");
        mDebugCamera->setReferenceFrame(osg::Transform::ABSOLUTE_RF);
        mDebugCamera->setRenderOrder(osg::Camera::POST_RENDER, 100);
        mDebugCamera->setAllowEventFocus(false);
        mDebugCamera->setClearMask(0);
        mDebugCamera->setProjectionMatrix(osg::Matrix::ortho2D(0, 1, 0, 1));
        mDebugCamera->setViewMatrix(osg::Matrix::identity());
        mDebugCamera->getOrCreateStateSet()->setMode(GL_DEPTH_TEST, osg::StateAttribute::OFF);
        mDebugCamera->getOrCreateStateSet()->setMode(GL_LIGHTING, osg::StateAttribute::OFF);
        mDebugCamera->setCullingActive(false);

        // Scale viewport to show in bottom-left corner (400px wide, aspect-correct height)
        float displayWidth = 400.0f;
        float displayHeight = displayWidth * static_cast<float>(h) / static_cast<float>(w);
        mDebugCamera->setViewport(0, 0, static_cast<int>(displayWidth), static_cast<int>(displayHeight));

        // Create textured quad
        osg::ref_ptr<osg::Geometry> quad
            = osg::createTexturedQuadGeometry(osg::Vec3(0, 0, 0), osg::Vec3(1, 0, 0), osg::Vec3(0, 1, 0));
        quad->setCullingActive(false);

        osg::StateSet* ss = quad->getOrCreateStateSet();
        ss->setTextureAttributeAndModes(0, mDebugTexture, osg::StateAttribute::ON);

        mDebugCamera->addChild(quad);
    }

    void SceneOcclusionCallback::updateDebugOverlay(osgUtil::CullVisitor* cv)
    {
        if (!mDebugCamera)
            return;

        unsigned int w, h;
        mCuller->getResolution(w, h);

        // Read depth buffer from MOC
        mCuller->computePixelDepthBuffer(mDepthPixels.data());

        // Copy to image (normalize: MOC stores 1/w, so closer = larger values)
        float* imageData = reinterpret_cast<float*>(mDebugImage->data());
        for (unsigned int i = 0; i < w * h; ++i)
        {
            float d = mDepthPixels[i];
            // MOC depth is 1/w (reciprocal clip-space w). 0 = far/empty, larger = closer.
            // Clamp and invert for visualization: dark = far, bright = near
            imageData[i] = std::min(d * 50.0f, 1.0f);
        }
        mDebugImage->dirty();

        // Inject debug camera into the cull visitor so it gets rendered
        unsigned int traversalMask = cv->getTraversalMask();
        cv->setTraversalMask(0xffffffff);
        mDebugCamera->accept(*cv);
        cv->setTraversalMask(traversalMask);
    }

    void SceneOcclusionCallback::operator()(osg::Node* node, osgUtil::CullVisitor* cv)
    {
        // Only run occlusion for the main scene camera.
        // Skip shadow cameras, water reflection, and any other cameras.
        osg::Camera* cam = cv->getCurrentCamera();
        if (!cam || cam->getName() != Constants::SceneCamera)
        {
            traverse(node, cv);
            return;
        }

        // The scene is traversed multiple times per frame: once for the main cull pass,
        // and again by MWShadowTechnique::cullShadowReceivingScene (same camera name).
        // Only set up MOC on the first traversal; subsequent passes just traverse normally.
        if (!cv->getFrameStamp()) { traverse(node, cv); return; }
        unsigned int frameNumber = cv->getFrameStamp()->getFrameNumber();
        if (frameNumber == mLastFrameNumber)
        {
            traverse(node, cv);
            return;
        }
        mLastFrameNumber = frameNumber;

        // Skip if no terrain data (interiors)
        if (!mTerrainOccluder->hasTerrainData())
        {
            traverse(node, cv);
            return;
        }

        // Begin occlusion frame with camera matrices
        mCuller->beginFrame(cam->getViewMatrix(), cam->getProjectionMatrix());
        mCuller->setCamera(cam);

        // Build and rasterize terrain occluder mesh
        if (mEnableTerrainOccluder)
        {
            mPositions.clear();
            mIndices.clear();
            mTerrainOccluder->build(cv->getEyePoint(), mRadiusCells, mPositions, mIndices);

            if (!mPositions.empty())
                mCuller->rasterizeOccluder(mPositions, mIndices);
        }

        // Continue normal cull traversal — CellOcclusionCallbacks will test against the buffer
        traverse(node, cv);

        mCuller->endFrame();

        // Update debug overlay AFTER traversal (terrain + building occluders now in buffer)
        if (mEnableDebugOverlay)
        {
            if (!mDebugCamera)
                setupDebugOverlay();
            updateDebugOverlay(cv);
        }

        static int frameCount = 0;
        if (++frameCount % 300 == 0)
        {
            const auto terrainTris = mIndices.size() / 3;
            const auto bldgTris = mCuller->getNumBuildingTris();
            const auto terrainVerts = mPositions.size();
            const auto bldgVerts = mCuller->getNumBuildingVerts();
            Log(Debug::Info) << "OcclusionCull: terrain tris=" << terrainTris << " terrain verts=" << terrainVerts
                             << " bldg occluders=" << mCuller->getNumBuildingOccluders() << " bldg tris=" << bldgTris
                             << " bldg verts=" << bldgVerts << " total tris=" << (terrainTris + bldgTris)
                             << " total verts=" << (terrainVerts + bldgVerts) << " tested=" << mCuller->getNumTested()
                             << " occluded=" << mCuller->getNumOccluded();
        }
    }

    PagedOccluderCallback::PagedOccluderCallback(SceneUtil::OcclusionCuller* culler, float maxDistance)
        : mCuller(culler)
        , mMaxDistanceSq(maxDistance * maxDistance)
    {
    }

    void PagedOccluderCallback::operator()(osg::Node* node, osgUtil::CullVisitor* cv)
    {
        if (!cv->getCurrentCamera() || cv->getCurrentCamera()->getName() != Constants::SceneCamera
            || !mCuller->isForCamera(cv->getCurrentCamera()))
        {
            traverse(node, cv);
            return;
        }

        // Transform chunk bounding sphere from local to world space.
        // The chunk sits under a PAT, so node->getBound() is in chunk-local space.
        const osg::BoundingSphere& bs = node->getBound();
        if (bs.valid())
        {
            osg::Matrixd viewInverse;
            viewInverse.invert(cv->getCurrentCamera()->getViewMatrix());
            const osg::Matrixd modelToWorld = *cv->getModelViewMatrix() * viewInverse;
            const osg::Vec3f worldCenter = bs.center() * modelToWorld;
            const float r = bs.radius();

            osg::BoundingBox worldBB(worldCenter.x() - r, worldCenter.y() - r, worldCenter.z() - r, worldCenter.x() + r,
                worldCenter.y() + r, worldCenter.z() + r);

            // If entire chunk is occluded, skip rasterization AND traversal
            if (!mCuller->testVisibleAABB(worldBB))
                return;

            // Rasterize nearby building occluder meshes for visible chunks
            const osg::Vec3f eyeWorld(viewInverse(3, 0), viewInverse(3, 1), viewInverse(3, 2));

            if (auto* udc = node->getUserDataContainer())
            {
                for (unsigned int i = 0; i < udc->getNumUserObjects(); ++i)
                {
                    if (auto* pod = dynamic_cast<PagedOccluderData*>(udc->getUserObject(i)))
                    {
                        for (const auto& occMesh : pod->mOccluderMeshes)
                        {
                            if (occMesh.indices.empty())
                                continue;

                            const osg::Vec3f center = occMesh.aabb.center();
                            if (occMesh.aabb.contains(eyeWorld) || (center - eyeWorld).length2() > mMaxDistanceSq)
                                continue;

                            mCuller->rasterizeOccluder(occMesh.vertices, occMesh.indices);
                            mCuller->incrementBuildingOccluders(static_cast<unsigned int>(occMesh.indices.size() / 3),
                                static_cast<unsigned int>(occMesh.vertices.size()));
                        }
                        break;
                    }
                }
            }
        }

        traverse(node, cv);
    }

    CellOcclusionCallback::CellOcclusionCallback(SceneUtil::OcclusionCuller* culler, float occluderMinRadius,
        float occluderMaxRadius, float occluderShrinkFactor, int occluderMeshResolution, int occluderMaxMeshResolution,
        float occluderInsideThreshold, float occluderMaxDistance, bool enableStaticOccluders)
        : mCuller(culler)
        , mOccluderMinRadius(occluderMinRadius)
        , mOccluderMaxRadius(occluderMaxRadius)
        , mOccluderShrinkFactor(occluderShrinkFactor)
        , mOccluderMeshResolution(occluderMeshResolution)
        , mOccluderMaxMeshResolution(occluderMaxMeshResolution)
        , mOccluderInsideThreshold(occluderInsideThreshold)
        , mOccluderMaxDistanceSq(occluderMaxDistance * occluderMaxDistance)
        , mEnableStaticOccluders(enableStaticOccluders)
    {
    }

    const OccluderMesh& CellOcclusionCallback::getOccluderMesh(osg::Node* node)
    {
        osg::Matrixd matrix;
        if (auto* transform = dynamic_cast<osg::Transform*>(node))
            transform->computeLocalToWorldMatrix(matrix, nullptr);
        auto it = mMeshCache.find(node);
        if (it != mMeshCache.end() && it->second.owner.get() == node && it->second.transform == matrix)
            return it->second.mesh;
        CachedMesh entry;
        entry.owner = node;
        entry.transform = matrix;
        entry.mesh = buildSimplifiedMesh(node, mOccluderMeshResolution, 1.0f);
        auto& cached = mMeshCache[node];
        cached = std::move(entry);
        return cached.mesh;
    }

    void CellOcclusionCallback::operator()(osg::Group* node, osgUtil::CullVisitor* cv)
    {
        // If occlusion is not active this frame (interior, shadow camera, etc.), traverse normally
        if (!cv->getCurrentCamera() || cv->getCurrentCamera()->getName() != Constants::SceneCamera
            || !mCuller->isForCamera(cv->getCurrentCamera()))
        {
            traverse(node, cv);
            return;
        }

        // Current bounds cover the entire object, including transparent submeshes.
        // Only immutable static objects contribute occluders; actors/doors do not.
        for (auto it = mMeshCache.begin(); it != mMeshCache.end();)
            if (!it->second.owner.valid()) it = mMeshCache.erase(it); else ++it;
        for (int pass = 0; pass < 2; ++pass)
        {
            for (unsigned int i = 0; i < node->getNumChildren(); ++i)
            {
                osg::Node* child = node->getChild(i);
                bool staticOccluder = false, skipOcclusion = false;
                child->getUserValue("staticOccluder", staticOccluder);
                child->getUserValue("skipOcclusion", skipOcclusion);
                const osg::BoundingSphere& bs = child->getBound();
                const bool large = bs.valid() && bs.radius() >= mOccluderMinRadius;
                if (large != (pass == 0)) continue;
                osg::BoundingBox bb;
                if (bs.valid()) bb.expandBy(bs);
                if (!skipOcclusion && bb.valid() && !mCuller->testVisibleAABB(bb)) continue;
                if (mEnableStaticOccluders && staticOccluder && large && bs.radius() <= mOccluderMaxRadius
                    && (bs.center() - cv->getEyePoint()).length2() < mOccluderMaxDistanceSq)
                {
                    const auto& mesh = getOccluderMesh(child);
                    if (!mesh.indices.empty() && !mesh.aabb.contains(cv->getEyePoint()))
                    {
                        mCuller->rasterizeOccluder(mesh.vertices, mesh.indices);
                        mCuller->incrementBuildingOccluders(mesh.indices.size()/3, mesh.vertices.size());
                    }
                }
                child->accept(*cv);
            }
        }
    }
}
