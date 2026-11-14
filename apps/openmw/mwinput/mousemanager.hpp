#ifndef MWINPUT_MWMOUSEMANAGER_H
#define MWINPUT_MWMOUSEMANAGER_H

#include <components/sdlutil/events.hpp>
#include <components/settings/settings.hpp>
#ifdef __APPLE__
#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
#include "../ios/openmw_ios_menu_input.hpp"
#endif
#endif

namespace SDLUtil
{
    class InputWrapper;
}

namespace MWInput
{
    class BindingsManager;

    class MouseManager : public SDLUtil::MouseListener
    {
    public:
        MouseManager(BindingsManager* bindingsManager, SDLUtil::InputWrapper* inputWrapper, SDL_Window* window);

        virtual ~MouseManager() = default;

        void updateCursorMode();
        void update(float dt);

        void mouseMoved(const SDLUtil::MouseMotionEvent& arg) override;
        void mousePressed(const SDL_MouseButtonEvent& arg, Uint8 id) override;
        void mouseReleased(const SDL_MouseButtonEvent& arg, Uint8 id) override;
        void mouseWheelMoved(const SDL_MouseWheelEvent& arg) override;
#if defined(__APPLE__) && TARGET_OS_IPHONE
        void touchEvent(const SDL_TouchFingerEvent& arg) override;
        void cancelTouch() { mMenuInput.cancel(); }
#endif

        bool injectMouseButtonPress(Uint8 button);
        bool injectMouseButtonRelease(Uint8 button);
        void injectMouseMove(float xMove, float yMove, float mouseWheelMove);
        void warpMouse();
        void warpMouseToWidget(MyGUI::Widget* widget);

        void setMouseLookEnabled(bool enabled) { mMouseLookEnabled = enabled; }
        void setGuiCursorEnabled(bool enabled) { mGuiCursorEnabled = enabled; }

        int getMouseMoveX() const { return mMouseMoveX; }
        int getMouseMoveY() const { return mMouseMoveY; }

    private:
#if defined(__APPLE__) && TARGET_OS_IPHONE
        OpenMWIOS::Touch::MenuInput mMenuInput;
#endif
        BindingsManager* mBindingsManager;
        SDLUtil::InputWrapper* mInputWrapper;

        float mGuiCursorX;
        float mGuiCursorY;
        int mMouseWheel;
        bool mMouseLookEnabled;
        bool mGuiCursorEnabled;
        float mLastWarpX;
        float mLastWarpY;

        int mMouseMoveX;
        int mMouseMoveY;
    };
}
#endif

