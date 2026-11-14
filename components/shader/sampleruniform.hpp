#ifndef OPENMW_COMPONENTS_SHADER_SAMPLERUNIFORM_H
#define OPENMW_COMPONENTS_SHADER_SAMPLERUNIFORM_H

#include <map>
#include <mutex>

#include <osg/Uniform>

namespace Shader
{
    // ShaderVisitor's opaque-depth binding is immutable once a program is
    // created. Reuse identical uniforms without sharing animated material data.
    // The texture unit is part of the key: managers may reserve different units.
    // Callers must not modify the returned uniform.
    inline osg::ref_ptr<osg::Uniform> opaqueDepthSamplerUniform(int textureUnit)
    {
        static std::mutex mutex;
        static std::map<int, osg::ref_ptr<osg::Uniform>> uniforms;
        const std::lock_guard<std::mutex> lock(mutex);
        auto [it, inserted] = uniforms.try_emplace(textureUnit);
        if (inserted)
            it->second = new osg::Uniform("opaqueDepthTex", textureUnit);
        return it->second;
    }
}

#endif
