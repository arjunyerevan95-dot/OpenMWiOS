#include <SDL.h>

#include <GL/gl.h>
#include <OpenAL/al.h>
#include <boost/geometry/geometries/box.hpp>
#include <boost/iostreams/filtering_stream.hpp>
#include <boost/iostreams/filter/zlib.hpp>
#include <boost/program_options/options_description.hpp>
#include <ft2build.h>
#include FT_FREETYPE_H
#include <jpeglib.h>
#include <lua.h>
#include <lauxlib.h>
#include <lz4.h>
#include <osg/Group>
#include <osgDB/Registry>
#include <png.h>
#include <unicode/uversion.h>
#include <yaml-cpp/yaml.h>
#include <zlib.h>

extern "C"
{
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswresample/swresample.h>
#include <libswscale/swscale.h>
}

USE_OSGPLUGIN(bmp)
USE_OSGPLUGIN(dds)
USE_OSGPLUGIN(freetype)
USE_OSGPLUGIN(jpeg)
USE_OSGPLUGIN(osg)
USE_OSGPLUGIN(png)
USE_SERIALIZER_WRAPPER_LIBRARY(osg)
USE_OSGPLUGIN(tga)

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
    osg::ref_ptr<osg::Group> group = new osg::Group;
    YAML::Node yaml = YAML::Load("smoke: true");
    boost::program_options::options_description options("smoke");
    boost::iostreams::filtering_istream stream;
    stream.push(boost::iostreams::zlib_decompressor());
    SDL_version sdlVersion{};
    SDL_GetVersion(&sdlVersion);

    const unsigned versions = avcodec_version() + avformat_version() + swresample_version() + swscale_version()
        + png_access_version_number() + static_cast<unsigned>(zlibVersion()[0]) + LZ4_versionNumber()
        + sdlVersion.major;
    const bool linked = glGetString(GL_VERSION) != nullptr || alGetString(AL_VERSION) != nullptr
        || osgDB::Registry::instance() != nullptr || !yaml.IsNull() || options.options().empty()
        || stream.empty() || group.valid() || versions != 0 || unicodeVersion[0] != 0;
    return linked ? 0 : 1;
}
