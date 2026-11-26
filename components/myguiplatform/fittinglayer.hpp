#ifndef OPENMW_MYGUIPLATFORM_FITTINGLAYER_H
#define OPENMW_MYGUIPLATFORM_FITTINGLAYER_H

#include <MyGUI_OverlappedLayer.h>
#include "viewportfit.hpp"

namespace MyGUIPlatform
{
    // An opt-in layer for one centered dialog. Drawing and picking share the same shrink-only transform.
    class FittingLayer final : public MyGUI::OverlappedLayer
    {
    public:
        MYGUI_RTTI_DERIVED(FittingLayer)
        void fit(const MyGUI::IntSize& content, SafeArea safe = {});
        void resizeView(const MyGUI::IntSize& view) override;
        MyGUI::ILayerItem* getLayerItemByPoint(int left, int top) const override;
        MyGUI::IntPoint getPosition(int left, int top) const override;
        void renderToTarget(MyGUI::IRenderTarget* target, bool update) override;

    private:
        MyGUI::IntSize mContent;
        SafeArea mSafe;
        ViewportFit mFit{ 1, 1, 1, 0, 0 };
        bool mTransformChanged = true;
    };
}
#endif
