#include <components/nifosg/controller.hpp>
#include <components/sceneutil/material.hpp>

#include <gtest/gtest.h>
#include <osg/Uniform>

#include <array>
#include <string_view>

namespace
{
    using Target = Nif::NiMaterialColorController::TargetColor;
    constexpr std::array<const char*, 8> Names = { "material.diffuse", "material.ambient",
        "material.specular", "material.emission", "material.shininess", "material.emissiveMult",
        "material.specStrength", "material.vertexColorMode" };

    class ConstantSource : public SceneUtil::ControllerSource
    {
        float getValue(osg::NodeVisitor*) override { return 0.f; }
    };

    class MaterialColorTest : public testing::TestWithParam<Target>
    {
    };

    TEST_P(MaterialColorTest, InitializesIsolatedBuffersAndUpdatesOnlySelectedColor)
    {
        SceneUtil::MaterialConfig config;
        config.mDiffuse = { .1f, .2f, .3f, .4f };
        config.mAmbient = { .2f, .3f, .4f, .5f };
        config.mSpecular = { .3f, .4f, .5f, .6f };
        config.mEmission = { .4f, .5f, .6f, .7f };
        config.mShininess = 12.f;
        osg::ref_ptr<SceneUtil::Material> material = new SceneUtil::Material(config);
        osg::ref_ptr<osg::StateSet> original = new osg::StateSet;
        material->setStateSet(original, osg::StateAttribute::ON | osg::StateAttribute::PROTECTED);

        Nif::NiMaterialColorController record;
        record.mInterpolator = nullptr;
        record.mData = nullptr;
        record.mTargetColor = GetParam();
        osg::ref_ptr<NifOsg::MaterialColorController> controller
            = new NifOsg::MaterialColorController(&record, material);
        controller->setSource(std::make_shared<ConstantSource>());
        osg::ref_ptr<osg::StateSet> first = new osg::StateSet(*original, osg::CopyOp::SHALLOW_COPY);
        osg::ref_ptr<osg::StateSet> second = new osg::StateSet(*original, osg::CopyOp::SHALLOW_COPY);
        controller->setDefaults(first);
        controller->setDefaults(second);

        const char* selected = "material.ambient";
        if (GetParam() == Target::Diffuse) selected = "material.diffuse";
        if (GetParam() == Target::Specular) selected = "material.specular";
        if (GetParam() == Target::Emissive) selected = "material.emission";
        osg::NodeVisitor visitor;
        controller->apply(first, &visitor); // First active frame initializes all uniforms, as before.
        std::array<unsigned int, 8> before;
        for (std::size_t i = 0; i < Names.size(); ++i)
        {
            ASSERT_NE(first->getUniform(Names[i]), original->getUniform(Names[i]));
            ASSERT_NE(first->getUniform(Names[i]), second->getUniform(Names[i]));
            EXPECT_EQ(first->getUniformList().at(Names[i]).second,
                original->getUniformList().at(Names[i]).second);
            before[i] = first->getUniform(Names[i])->getModifiedCount();
        }
        osg::Vec4f initial;
        ASSERT_TRUE(original->getUniform(selected)->get(initial));
        controller->apply(first, &visitor);
        osg::Vec4f actual, untouched;
        ASSERT_TRUE(first->getUniform(selected)->get(actual));
        // Empty interpolation track uses its default zero RGB, retaining alpha.
        EXPECT_EQ(actual, osg::Vec4f(0.f, 0.f, 0.f, initial.a()));
        ASSERT_TRUE(original->getUniform(selected)->get(untouched));
        EXPECT_EQ(untouched, initial);
        ASSERT_TRUE(second->getUniform(selected)->get(untouched));
        EXPECT_EQ(untouched, initial);
        for (std::size_t i = 0; i < Names.size(); ++i)
            if (std::string_view(Names[i]) != selected)
                EXPECT_EQ(first->getUniform(Names[i])->getModifiedCount(), before[i]);
    }

    INSTANTIATE_TEST_SUITE_P(AllColors, MaterialColorTest,
        testing::Values(Target::Ambient, Target::Diffuse, Target::Specular, Target::Emissive));

    TEST(MaterialColorController, DefersInitializationUntilInputAndResetsEachBuffer)
    {
        osg::ref_ptr<SceneUtil::Material> material = new SceneUtil::Material;
        Nif::NiMaterialColorController record;
        record.mInterpolator = nullptr;
        record.mData = nullptr;
        osg::ref_ptr<NifOsg::MaterialColorController> controller
            = new NifOsg::MaterialColorController(&record, material);
        osg::ref_ptr<osg::StateSet> state = new osg::StateSet;
        controller->setDefaults(state);
        osg::NodeVisitor visitor;
        controller->apply(state, &visitor);
        for (const char* name : Names)
            EXPECT_EQ(state->getUniform(name), nullptr);
        controller->setSource(std::make_shared<ConstantSource>());
        controller->apply(state, &visitor);
        for (const char* name : Names)
            EXPECT_NE(state->getUniform(name), nullptr);
        state->getUniform("material.shininess")->set(37.f);
        controller->setSource(nullptr);
        controller->setDefaults(state);
        controller->apply(state, &visitor);
        float value = 0.f;
        ASSERT_TRUE(state->getUniform("material.shininess")->get(value));
        EXPECT_EQ(value, 37.f); // No-input reset does not overwrite inherited/custom values.
        controller->setSource(std::make_shared<ConstantSource>());
        controller->apply(state, &visitor);
        ASSERT_TRUE(state->getUniform("material.shininess")->get(value));
        EXPECT_EQ(value, 0.f); // First active update resets to base material, as before.
    }
    class MutableSource : public SceneUtil::ControllerSource
    {
    public:
        float time = 0.f;
        float getValue(osg::NodeVisitor*) override { return time; }
    };

    TEST(MaterialColorController, LinearAnimationAlternatesBuffersWithoutLeakingValues)
    {
        Nif::NiPosData data;
        data.mKeyList = std::make_shared<Nif::Vector3KeyMap>();
        data.mKeyList->mInterpolationType = Nif::InterpolationType_Linear;
        Nif::KeyT<osg::Vec3f> start{}, end{};
        start.mValue = { 0.f, .2f, .4f };
        end.mValue = { 1.f, .6f, .8f };
        data.mKeyList->mKeys = { { 0.f, start }, { 1.f, end } };
        Nif::NiMaterialColorController record;
        record.mInterpolator = nullptr;
        record.mData = &data;
        record.mTargetColor = Target::Diffuse;
        SceneUtil::MaterialConfig config;
        config.mDiffuse = { .8f, .7f, .6f, .3f };
        osg::ref_ptr<SceneUtil::Material> material = new SceneUtil::Material(config);
        osg::ref_ptr<NifOsg::MaterialColorController> controller
            = new NifOsg::MaterialColorController(&record, material);
        auto source = std::make_shared<MutableSource>();
        controller->setSource(source);
        osg::ref_ptr<osg::StateSet> first = new osg::StateSet;
        osg::ref_ptr<osg::StateSet> second = new osg::StateSet;
        controller->setDefaults(first);
        controller->setDefaults(second);
        osg::NodeVisitor visitor;
        controller->apply(first, &visitor);
        source->time = .5f;
        controller->apply(second, &visitor);
        osg::Vec4f a, b;
        ASSERT_TRUE(first->getUniform("material.diffuse")->get(a));
        ASSERT_TRUE(second->getUniform("material.diffuse")->get(b));
        EXPECT_EQ(a, osg::Vec4f(0.f, .2f, .4f, .3f));
        EXPECT_FLOAT_EQ(b.x(), .5f);
        EXPECT_FLOAT_EQ(b.y(), .4f);
        EXPECT_FLOAT_EQ(b.z(), .6f);
        EXPECT_EQ(b.a(), .3f);
        source->time = 1.f;
        controller->apply(first, &visitor);
        ASSERT_TRUE(first->getUniform("material.diffuse")->get(a));
        EXPECT_EQ(a, osg::Vec4f(1.f, .6f, .8f, .3f));
        osg::Vec4f unchanged;
        ASSERT_TRUE(second->getUniform("material.diffuse")->get(unchanged));
        EXPECT_EQ(unchanged, b);
        EXPECT_EQ(material->getDiffuse(), config.mDiffuse);
        osg::ref_ptr<NifOsg::MaterialColorController> copied
            = new NifOsg::MaterialColorController(*controller, osg::CopyOp::SHALLOW_COPY);
        osg::ref_ptr<osg::StateSet> third = new osg::StateSet;
        copied->setDefaults(third);
        copied->apply(third, &visitor);
        ASSERT_TRUE(third->getUniform("material.diffuse")->get(a));
        EXPECT_EQ(a, osg::Vec4f(1.f, .6f, .8f, .3f));
    }

}
