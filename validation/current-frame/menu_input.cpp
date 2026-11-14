#include "../../apps/openmw/ios/openmw_ios_menu_input.hpp"
#include <cassert>
#include <iostream>
namespace OpenMWIOS::Touch
{
    std::uint32_t generation=1;
    std::uint32_t inputGeneration() { return generation; }
    void invalidateInput() { ++generation; }
}
int main()
{
    using namespace OpenMWIOS::Touch;
    MenuInput router;
    MyGUI::Widget map,list,modal;
    map.direct=true;
    auto& gui=MyGUI::InputManager::getInstance();
    float x=0,y=0;int wheel=0;
    auto event=[&](unsigned phase,float px,float py,unsigned time=100,bool cancelled=false,bool enabled=true) {
        SDL_TouchFingerEvent e;
        e.type=phase;e.timestamp=time;e.touchId=MenuDevice;e.fingerId=(std::int64_t(inputGeneration())<<32)|1;
        e.x=px/500;e.y=py/250;e.dx=500;e.dy=250;e.pressure=cancelled?-1.f:1.f;
        router.handle(e,x,y,wheel,enabled);
    };
    gui.picked=&map;
    event(SDL_FINGERDOWN,100,100);
    event(SDL_FINGERMOTION,120,110,120); // ordinary 20ms pan, no hold
    assert(map.presses==1 && map.drags==1 && wheel==0 && x==240 && y==220);
    event(SDL_FINGERUP,120,110,140);
    assert(!gui.captured && map.releases==1 && map.clicks==0);
    event(SDL_FINGERDOWN,100,100,150);event(SDL_FINGERUP,100,100,160);
    event(SDL_FINGERDOWN,100,100,180);event(SDL_FINGERUP,100,100,190);
    assert(map.clicks==2); // both taps reach normal MyGUI double-click detection
    event(SDL_FINGERDOWN,100,100,200);event(SDL_FINGERMOTION,130,100,210);
    event(SDL_FINGERUP,130,100,220,true);
    assert(!gui.captured && map.clicks==2);
    gui.picked=&list;
    event(SDL_FINGERDOWN,100,100,300);event(SDL_FINGERMOTION,100,64,310);
    assert(wheel==-120 && list.presses==0);
    event(SDL_FINGERMOTION,100,100,320);event(SDL_FINGERUP,100,100,330);
    assert(wheel==0 && list.clicks==0);
    event(SDL_FINGERDOWN,100,100,400);event(SDL_FINGERMOTION,64,100,410);
    event(SDL_FINGERUP,28,110,420);assert(wheel==-240 && list.presses==0);
    event(SDL_FINGERDOWN,100,100,500);gui.picked=&modal;
    event(SDL_FINGERUP,100,100,510);assert(modal.clicks==0 && list.clicks==0);
    gui.picked=&map;event(SDL_FINGERDOWN,100,100,600);event(SDL_FINGERMOTION,130,100,610);
    gui.unlinkWidget(&map);gui.picked=&modal; // modal creation drops MyGUI capture
    event(SDL_FINGERUP,130,100,620);assert(modal.clicks==0 && !gui.captured);
    gui.picked=&map;event(SDL_FINGERDOWN,100,100,700);
    map.visible=false;event(SDL_FINGERUP,100,100,710);map.visible=true;
    assert(map.clicks==2);
    event(SDL_FINGERDOWN,100,100,800);MyGUI::WidgetManager::getInstance().destroy(&map);
    event(SDL_FINGERUP,100,100,810);assert(map.clicks==2);
    event(SDL_FINGERDOWN,100,100,900);event(SDL_FINGERMOTION,130,100,910);
    event(SDL_FINGERUP,130,100,920,false,false);assert(!gui.captured && map.clicks==2);
    event(SDL_FINGERDOWN,100,100,1000);MyGUI::RenderManager::getInstance().view.width=1100;
    event(SDL_FINGERUP,100,100,1010);assert(map.clicks==2);
    MyGUI::RenderManager::getInstance().view.width=1000;
    event(SDL_FINGERDOWN,100,100,1100);
    SDL_TouchFingerEvent stale;stale.touchId=MenuDevice;stale.fingerId=(std::int64_t(inputGeneration())<<32)|1;
    invalidateInput();router.handle(stale,x,y,wheel,true);assert(!gui.captured);
    std::cout<<"PASS production menu routing: immediate pan, natural scroll, taps, cancel, modal/overlap, removal, scaling, disabled/stale input\n";
}
