#pragma once
// Small engine-input seam: exercises production MenuInput; UIKit/MyGUI remain device checks.
#include <cstdint>
#include <string>
#include <vector>
#include <algorithm>
constexpr unsigned SDL_FINGERDOWN=1, SDL_FINGERMOTION=2, SDL_FINGERUP=3;
struct SDL_TouchFingerEvent
{
    unsigned type=0, timestamp=0;
    std::int64_t touchId=0, fingerId=0;
    float x=0,y=0,dx=0,dy=0,pressure=1;
};
namespace MyGUI
{
    struct IntSize
    {
        int width=1000,height=500;
        bool operator!=(IntSize other) const { return width!=other.width || height!=other.height; }
    };
    struct Widget
    {
        bool visible=true,enabled=true,direct=false;
        Widget* parent=nullptr;
        int presses=0,releases=0,clicks=0,drags=0,wheels=0,lastX=0,lastY=0;
        Widget* getParent() { return parent; }
        bool getVisible() { return visible; }
        bool getEnabled() { return enabled; }
        bool getInheritedEnabled() { return enabled && (!parent || parent->getInheritedEnabled()); }
        std::string getUserString(const char*) { return direct ? "true" : ""; }
    };
    struct IUnlinkWidget { virtual ~IUnlinkWidget()=default; virtual void _unlinkWidget(Widget*)=0; };
    struct WidgetManager
    {
        std::vector<IUnlinkWidget*> listeners;
        static WidgetManager& getInstance() { static WidgetManager m; return m; }
        void registerUnlinker(IUnlinkWidget* p) { listeners.push_back(p); }
        void unregisterUnlinker(IUnlinkWidget* p) { listeners.erase(std::remove(listeners.begin(),listeners.end(),p),listeners.end()); }
        void destroy(Widget* p) { for(auto* l:listeners) l->_unlinkWidget(p); }
    };
    struct RenderManager
    {
        IntSize view;
        static RenderManager& getInstance() { static RenderManager m; return m; }
        IntSize getViewSize() { return view; }
    };
    struct MouseButton { enum Enum { Left }; };
    struct InputManager
    {
        Widget *picked=nullptr,*focus=nullptr;
        bool captured=false;
        int wheel=0;
        static InputManager& getInstance() { static InputManager m; return m; }
        bool isCaptureMouse() { return captured; }
        Widget* getMouseFocusWidget() { return focus; }
        void injectMouseMove(int x,int y,int z)
        {
            if (!captured) focus=picked;
            if(focus) { focus->wheels+=z-wheel; focus->lastX=x; focus->lastY=y; if(captured) ++focus->drags; }
            wheel=z;
        }
        void injectMousePress(int x,int y,MouseButton::Enum)
        { injectMouseMove(x,y,wheel);captured=true;if(focus) ++focus->presses; }
        void injectMouseRelease(int,int,MouseButton::Enum)
        { captured=false;if(focus){++focus->releases;++focus->clicks;} }
        void unlinkWidget(Widget* p)
        { if(focus==p) {if(captured) ++focus->releases;captured=false;focus=nullptr;} }
    };
}
