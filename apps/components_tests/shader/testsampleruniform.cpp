#include <components/shader/sampleruniform.hpp>
#include <gtest/gtest.h>
#include <osg/StateSet>
#include <array>
#include <thread>

namespace
{
    TEST(OpaqueDepthSampler, SharesOnlyIdenticalBindings)
    {
        auto first = Shader::opaqueDepthSamplerUniform(3);
        auto same = Shader::opaqueDepthSamplerUniform(3);
        auto other = Shader::opaqueDepthSamplerUniform(4);
        EXPECT_EQ(first, same);
        EXPECT_NE(first, other);
        EXPECT_EQ(first->getName(), "opaqueDepthTex");
        EXPECT_EQ(first->getType(), osg::Uniform::INT);
        int unit = -1;
        ASSERT_TRUE(first->get(unit));
        EXPECT_EQ(unit, 3);
        ASSERT_TRUE(other->get(unit));
        EXPECT_EQ(unit, 4);
    }

    TEST(OpaqueDepthSampler, StateSetRemovalDoesNotAffectAnotherMaterial)
    {
        osg::ref_ptr<osg::StateSet> first = new osg::StateSet;
        osg::ref_ptr<osg::StateSet> second = new osg::StateSet;
        auto uniform = Shader::opaqueDepthSamplerUniform(5);
        first->addUniform(uniform);
        second->addUniform(uniform);
        first->removeUniform("opaqueDepthTex");
        EXPECT_EQ(first->getUniform("opaqueDepthTex"), nullptr);
        EXPECT_EQ(second->getUniform("opaqueDepthTex"), uniform.get());
        auto replacement = Shader::opaqueDepthSamplerUniform(6);
        first->addUniform(replacement);
        EXPECT_NE(first->getUniform("opaqueDepthTex"), second->getUniform("opaqueDepthTex"));
        int unit = -1;
        ASSERT_TRUE(second->getUniform("opaqueDepthTex")->get(unit));
        EXPECT_EQ(unit, 5);
    }

    TEST(OpaqueDepthSampler, ConcurrentCreationReturnsOneUniform)
    {
        std::array<osg::ref_ptr<osg::Uniform>, 8> uniforms;
        std::array<std::thread, 8> workers;
        for (std::size_t i = 0; i < workers.size(); ++i)
            workers[i] = std::thread([&, i] { uniforms[i] = Shader::opaqueDepthSamplerUniform(17); });
        for (auto& worker : workers)
            worker.join();
        for (auto& uniform : uniforms)
            EXPECT_EQ(uniform, uniforms.front());
    }
}
