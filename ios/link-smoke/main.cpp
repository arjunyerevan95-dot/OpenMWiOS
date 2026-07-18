#include <SDL.h>

#include <GL/gl.h>
#include <OpenAL/al.h>
#include <OpenThreads/Thread>
#include <BulletCollision/CollisionShapes/btBoxShape.h>
#include <LinearMath/btAlignedAllocator.h>
#include <MyGUI_LogManager.h>
#include <DetourAlloc.h>
#include <Recast.h>
#include <RecastAlloc.h>
#include <RecastDump.h>
#include <boost/geometry/geometries/box.hpp>
#include <boost/iostreams/filtering_stream.hpp>
#include <boost/iostreams/filter/zlib.hpp>
#include <boost/program_options/options_description.hpp>
#include <ft2build.h>
#include FT_FREETYPE_H
#include <jpeglib.h>

extern "C"
{
#include <lua.h>
#include <lauxlib.h>
}

#include <lz4.h>
#include <osg/Group>
#include <osgAnimation/Animation>
#include <osgDB/Registry>
#include <osgFX/Scribe>
#include <osgGA/GUIEventAdapter>
#include <osgParticle/ParticleSystem>
#include <osgShadow/ShadowedScene>
#include <osgSim/DOFTransform>
#include <osgText/Text>
#include <osgUtil/Optimizer>
#include <osgViewer/Viewer>
#include <png.h>
#include <sqlite3.h>
#include <unicode/ucol.h>
#include <unicode/uversion.h>
#include <yaml-cpp/yaml.h>
#include <zlib.h>

#include <openmw_ios_osg_plugins.hpp>

extern "C"
{
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/avutil.h>
#include <libswresample/swresample.h>
#include <libswscale/swscale.h>
}

extern "C" int SDL_main(int, char**)
{
    FT_Library freetype = nullptr;
    FT_Init_FreeType(&freetype);
    FT_Done_FreeType(freetype);

    jpeg_error_mgr jpegError;
    jpeg_std_error(&jpegError);
    lua_State* lua = luaL_newstate();
    lua_close(lua);

    UVersionInfo unicodeVersion{};
    u_getVersion(unicodeVersion);
    UErrorCode icuStatus = U_ZERO_ERROR;
    UCollator* collator = ucol_open("", &icuStatus);
    if (collator != nullptr)
        ucol_close(collator);

    osg::ref_ptr<osg::Group> group = new osg::Group;
    osg::ref_ptr<osgAnimation::Animation> animation = new osgAnimation::Animation;
    animation->computeDuration();
    osg::ref_ptr<osgFX::Scribe> scribe = new osgFX::Scribe;
    osg::ref_ptr<osgGA::GUIEventAdapter> event = new osgGA::GUIEventAdapter;
    osg::ref_ptr<osgParticle::ParticleSystem> particles = new osgParticle::ParticleSystem;
    osg::ref_ptr<osgShadow::ShadowedScene> shadow = new osgShadow::ShadowedScene;
    osg::ref_ptr<osgSim::DOFTransform> dof = new osgSim::DOFTransform;
    osg::ref_ptr<osgText::Text> text = new osgText::Text;
    osgUtil::Optimizer optimizer;
    optimizer.reset();
    osg::ref_ptr<osgViewer::Viewer> viewer = new osgViewer::Viewer;

    void* bulletMemory = btAlignedAlloc(64, 16);
    btAlignedFree(bulletMemory);
    btBoxShape bulletShape(btVector3(1, 1, 1));
    btVector3 bulletInertia;
    bulletShape.calculateLocalInertia(1, bulletInertia);

    MyGUI::LogManager* myguiLog = MyGUI::LogManager::getInstancePtr();
    void* recastMemory = rcAlloc(64, RC_ALLOC_TEMP);
    rcFree(recastMemory);
    void* detourMemory = dtAlloc(64, DT_ALLOC_TEMP);
    dtFree(detourMemory);
    rcPolyMesh emptyMesh{};
    const bool debugDumpResult = duDumpPolyMeshToObj(emptyMesh, nullptr);
    const char* sqliteVersion = sqlite3_libversion();

    YAML::Node yaml = YAML::Load("smoke: true");
    boost::program_options::options_description options("smoke");
    boost::iostreams::filtering_istream stream;
    stream.push(boost::iostreams::zlib_decompressor());
    SDL_version sdlVersion{};
    SDL_GetVersion(&sdlVersion);

    const unsigned versions = avcodec_version() + avformat_version() + avutil_version()
        + swresample_version() + swscale_version() + png_access_version_number()
        + static_cast<unsigned>(zlibVersion()[0]) + LZ4_versionNumber() + sdlVersion.major;
    const bool linked = glGetString(GL_VERSION) != nullptr || alGetString(AL_VERSION) != nullptr
        || osgDB::Registry::instance() != nullptr || !yaml.IsNull() || options.options().empty()
        || stream.empty() || group.valid() || animation.valid() || scribe.valid() || event.valid()
        || particles.valid() || shadow.valid() || dof.valid() || text.valid() || viewer.valid()
        || bulletInertia.length2() != 0 || myguiLog != nullptr || debugDumpResult
        || sqliteVersion == nullptr || OpenThreads::Thread::CurrentThreadId() != 0
        || versions != 0 || unicodeVersion[0] != 0 || U_SUCCESS(icuStatus);
    return linked ? 0 : 1;
}
