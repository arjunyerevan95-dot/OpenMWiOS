#include "components/sceneutil/occlusionculling.hpp"
#include <osg/Camera>
#include <cassert>
#include <limits>
int main(){
 osg::ref_ptr<SceneUtil::OcclusionCuller> c=new SceneUtil::OcclusionCuller(512,256);
 osg::ref_ptr<osg::Camera> main=new osg::Camera, shadow=new osg::Camera;
 osg::Matrixd proj=osg::Matrixd::perspective(60,2,0.1,1000), view;
 osg::BoundingBox behind(-.2,-.2,-10.2,.2,.2,-10), front(-.2,-.2,-2.2,.2,.2,-2);
 assert(c->testVisibleAABB(behind));
 c->beginFrame(view,proj);c->setCamera(main);
 assert(c->isForCamera(main));assert(!c->isForCamera(shadow)); assert(!c->isForCamera(nullptr));
 assert(c->testVisibleAABB(behind));
 std::vector<osg::Vec3f> wall={{-3,-3,-5},{3,-3,-5},{3,3,-5},{-3,3,-5}};
 std::vector<unsigned> ids={0,1,2,0,2,3};c->rasterizeOccluder(wall,ids);
 assert(!c->testVisibleAABB(behind));assert(c->testVisibleAABB(front));
 assert(c->testVisibleAABB(osg::BoundingBox(-1,-1,-1,1,1,1)));
 c->endFrame();assert(c->testVisibleAABB(behind)); assert(!c->isForCamera(main));
 c->beginFrame(view,proj);assert(c->testVisibleAABB(behind));
 ids[0]=999;c->rasterizeOccluder(wall,ids);assert(c->testVisibleAABB(behind));
 ids[0]=0;wall[0].x()=std::numeric_limits<float>::quiet_NaN();c->rasterizeOccluder(wall,ids);assert(c->testVisibleAABB(behind));
 // An arch/door aperture must remain visible: four original frame strips.
 c->beginFrame(view,proj);
 std::vector<osg::Vec3f> portal;
 std::vector<unsigned> portalIds;
 auto quad=[&](float x0,float y0,float x1,float y1){unsigned b=portal.size();
 portal.insert(portal.end(),{{x0,y0,-5},{x1,y0,-5},{x1,y1,-5},{x0,y1,-5}});
 portalIds.insert(portalIds.end(),{b,b+1,b+2,b,b+2,b+3});};
 quad(-3,-3,-1,3);quad(1,-3,3,3);quad(-1,1,1,3);quad(-1,-3,1,-1);
 c->rasterizeOccluder(portal,portalIds);assert(c->testVisibleAABB(behind));
 c->endFrame();view(0,0)=std::numeric_limits<double>::infinity();c->beginFrame(view,proj);assert(!c->isFrameActive());
}
