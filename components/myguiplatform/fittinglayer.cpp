#include "fittinglayer.hpp"

#include <MyGUI_RenderManager.h>

namespace MyGUIPlatform
{
    namespace
    {
        class FittedTarget final : public MyGUI::IRenderTarget
        {
            MyGUI::IRenderTarget* mTarget;
            MyGUI::RenderTargetInfo mInfo;
        public:
            FittedTarget(MyGUI::IRenderTarget* target, const ViewportFit& fit, MyGUI::IntSize view)
                : mTarget(target), mInfo(target->getInfo())
            {
                mInfo.pixScaleX = fit.scale / view.width;
                mInfo.pixScaleY = fit.scale / view.height;
                mInfo.hOffset = fit.left / view.width;
                mInfo.vOffset = fit.top / view.height;
            }
            void begin() override { mTarget->begin(); }
            void end() override { mTarget->end(); }
            void doRender(MyGUI::IVertexBuffer* buffer, MyGUI::ITexture* texture, size_t count) override
            { mTarget->doRender(buffer, texture, count); }
            const MyGUI::RenderTargetInfo& getInfo() const override { return mInfo; }
        };
    }

    void FittingLayer::fit(const MyGUI::IntSize& content, SafeArea safe)
    {
        mContent = content;
        mSafe = safe;
        resizeView(MyGUI::RenderManager::getInstance().getViewSize());
    }

    void FittingLayer::resizeView(const MyGUI::IntSize& view)
    {
        const auto fit = fitViewport(view.width, view.height, mContent.width, mContent.height, mSafe);
        mTransformChanged |= fit.width != mFit.width || fit.height != mFit.height || fit.scale != mFit.scale
            || fit.left != mFit.left || fit.top != mFit.top;
        mFit = fit;
        const MyGUI::IntSize size(fit.width, fit.height);
        if (size != mViewSize)
            MyGUI::OverlappedLayer::resizeView(size);
    }

    MyGUI::ILayerItem* FittingLayer::getLayerItemByPoint(int left, int top) const
    {
        return MyGUI::OverlappedLayer::getLayerItemByPoint(mFit.toLayerX(left), mFit.toLayerY(top));
    }

    MyGUI::IntPoint FittingLayer::getPosition(int left, int top) const
    {
        return { mFit.toLayerX(left), mFit.toLayerY(top) };
    }

    void FittingLayer::renderToTarget(MyGUI::IRenderTarget* target, bool update)
    {
        FittedTarget fitted(target, mFit, MyGUI::RenderManager::getInstance().getViewSize());
        MyGUI::OverlappedLayer::renderToTarget(&fitted, update || mTransformChanged);
        mTransformChanged = false;
    }
}
