#pragma once
#include "openmw_ios_menu_touch.hpp"
#include "openmw_ios_touch_targets.hpp"
#include <MyGUI_InputManager.h>
#include <MyGUI_LayerManager.h>
#include <MyGUI_RenderManager.h>
#include <MyGUI_ScrollBar.h>
#include <MyGUI_WidgetManager.h>
#include <SDL_events.h>
#include <SDL_timer.h>

#include <algorithm>

namespace OpenMWIOS::Touch
{
    // Owned and invoked exclusively by MouseManager on the engine thread.
    class MenuInput : public MyGUI::IUnlinkWidget
    {
        MenuTouch mGesture;
        MyGUI::Widget* mTarget = nullptr;
        MyGUI::IntSize mView;
        float mWidth = 0, mHeight = 0, mWheelRemainder = 0;
        int mStartX = 0, mStartY = 0;
        bool mPressed = false;

        static MyGUI::ScrollBar* touchSlider(MyGUI::Widget* widget)
        {
            for (; widget; widget = widget->getParent())
                if (widget->getUserString("OpenMWTouchSlider") == "true")
                    return widget->castType<MyGUI::ScrollBar>(false);
            return nullptr;
        }

        static void moveSlider(MyGUI::ScrollBar& slider, int x)
        {
            const float fraction = std::clamp(
                static_cast<float>(x - slider.getAbsoluteCoord().left - 20) / std::max(1, slider.getWidth() - 40),
                0.f, 1.f);
            const auto position = static_cast<size_t>(std::lround(fraction * (slider.getScrollRange() - 1)));
            if (position != slider.getScrollPosition())
            {
                slider.setScrollPosition(position);
                slider.eventScrollChangePosition(&slider, position);
            }
        }

        void _unlinkWidget(MyGUI::Widget* widget) override
        {
            if (widget == mTarget) { mTarget = nullptr; cancel(); }
        }
        bool visible() const
        {
            for (auto* widget = mTarget; widget; widget = widget->getParent())
                if (!widget->getVisible() || !widget->getEnabled()) return false;
            return mTarget != nullptr;
        }
    public:
        MenuInput() { MyGUI::WidgetManager::getInstance().registerUnlinker(this); }
        ~MenuInput() { MyGUI::WidgetManager::getInstance().unregisterUnlinker(this); }
        void cancel()
        {
            // Reset mouse focus/capture without removing a modal root or synthesizing clicks.
            auto* target = mTarget;
            const bool pressed = mPressed;
            mPressed = false; mTarget = nullptr; mGesture.cancel(); mWheelRemainder = 0;
            if (pressed && target)
            {
                auto& input = MyGUI::InputManager::getInstance();
                if (input.getMouseFocusWidget() == target) input._resetMouseFocusWidget();
            }
        }
        void handle(const SDL_TouchFingerEvent& event, float& cursorX, float& cursorY, int& wheel, bool enabled)
        {
            if (event.touchId != MenuDevice) return;
            const auto token = static_cast<std::uint64_t>(event.fingerId);
            if (!enabled || (token >> 32) != inputGeneration()) { cancel(); return; }
            const auto id = static_cast<std::uintptr_t>(token);
            auto& input = MyGUI::InputManager::getInstance();
            const auto view = MyGUI::RenderManager::getInstance().getViewSize();
            const int x = static_cast<int>(std::lround(event.x * view.width));
            const int y = static_cast<int>(std::lround(event.y * view.height));
            const float pointX = event.x * event.dx, pointY = event.y * event.dy;
            const double now = event.timestamp / 1000.0;
            if (event.type == SDL_FINGERDOWN)
            {
                if (mTarget || input.isCaptureMouse()) return;
                cursorX = static_cast<float>(x); cursorY = static_cast<float>(y);
                input.injectMouseMove(x, y, wheel); // MyGUI performs clipping, z-order and modal filtering.
                auto* target = input.getMouseFocusWidget();
                if (!target || !target->getInheritedEnabled()) return;
                auto* slider = touchSlider(target);
                const bool direct = slider || target->getUserString("OpenMWTouchDrag") == "true";
                if (!mGesture.begin(id, pointX, pointY, now, direct)) return;
                mTarget = slider ? slider : target;
                mStartX = x; mStartY = y; mView = view;
                mWidth = event.dx; mHeight = event.dy;
                return;
            }
            if (!mGesture.owns(id)) return;
            if (!visible() || view != mView || event.dx != mWidth || event.dy != mHeight
                || (mPressed && input.getMouseFocusWidget() != mTarget)) { cancel(); return; }
            auto* slider = touchSlider(mTarget);
            if (!mPressed && (!slider || !mGesture.dragging()))
            {
                // Revalidate a deferred tap/scroll against any newly overlapping/modal window.
                input.injectMouseMove(mStartX, mStartY, wheel);
                auto* focused = input.getMouseFocusWidget();
                if (slider ? touchSlider(focused) != slider : focused != mTarget) { cancel(); return; }
            }
            if (event.type == SDL_FINGERUP && event.pressure < 0) { cancel(); return; }
            const float delta = mGesture.move(id, pointX, pointY, now);
            if (slider)
            {
                if (mGesture.dragging() || event.type == SDL_FINGERUP)
                    moveSlider(*slider, x);
                if (event.type == SDL_FINGERUP)
                    cancel();
                return;
            }
            if (mGesture.dragging())
            {
                if (!mPressed)
                {
                    mPressed = true;
                    input.injectMousePress(mStartX, mStartY, MyGUI::MouseButton::Left);
                    if (!mTarget || input.getMouseFocusWidget() != mTarget) { cancel(); return; }
                }
                cursorX = static_cast<float>(x); cursorY = static_cast<float>(y);
                input.injectMouseMove(x, y, wheel);
            }
            else if (delta != 0)
            {
                mWheelRemainder += delta * 120.f;
                const int steps = static_cast<int>(mWheelRemainder);
                mWheelRemainder -= steps; wheel += steps;
                cursorX = static_cast<float>(mStartX); cursorY = static_cast<float>(mStartY);
                input.injectMouseMove(mStartX, mStartY, wheel);
            }
            if (event.type == SDL_FINGERUP)
            {
                const bool tap = mGesture.finish(id, false);
                if (tap)
                {
                    cursorX = static_cast<float>(mStartX); cursorY = static_cast<float>(mStartY);
                    mPressed = true;
                    input.injectMousePress(mStartX, mStartY, MyGUI::MouseButton::Left);
                    if (mTarget && input.getMouseFocusWidget() == mTarget)
                    {
                        input.injectMouseRelease(mStartX, mStartY, MyGUI::MouseButton::Left);
                        mPressed = false;
                    }
                }
                // A completed pan must not turn into a marker double-click.
                cancel();
            }
        }
    };
}
