#include "../../apps/openmw/ios/openmw_ios_touch_targets.hpp"
#include "../../apps/openmw/ios/openmw_ios_touch_model.hpp"
#include <cassert>
#include <iostream>
int main()
{
    using namespace OpenMWIOS::Touch;
    using R=TapHold::Result;
    TapHold gesture;
    assert(!gesture.begin(0,10,10,0));
    assert(gesture.begin(1,10,10,0) && !gesture.begin(2,10,10,0));
    assert(gesture.update(.999)==R::None);
    assert(gesture.finish(1,.999,false)==R::Tap);
    gesture.begin(1,10,10,0);assert(gesture.update(1)==R::Hold);
    assert(gesture.update(2)==R::None && gesture.finish(1,2,false)==R::None); // one haptic/hold, no tap
    gesture.begin(1,10,10,0);assert(gesture.finish(1,1.1,false)==R::Hold); // slow display frame
    gesture.begin(1,10,10,0);gesture.move(1,19,10,true);
    assert(gesture.update(2)==R::None && gesture.finish(1,2,false)==R::None);
    gesture.begin(1,10,10,0);gesture.move(1,10,10,false);
    assert(gesture.finish(1,.2,false)==R::None);
    gesture.begin(1,10,10,0);assert(gesture.finish(1,2,true)==R::None);
    gesture.begin(1,10,10,0);gesture.cancel();assert(gesture.update(2)==R::None);
    gesture.begin(1,10,10,0);assert(gesture.finish(1,2,false,false)==R::Tap); // mouse has no hold action
    TargetRect rect{.1f,.2f,.3f,.4f};assert(rect.contains(.2f,.3f) && !rect.contains(.3f,.3f));
    assert(!TargetRect{}.contains(0,0));
    HudTargets targets;
    targets.stats={.05f,.7f,.2f,.95f}; targets.weapon={.25f,.7f,.35f,.9f};
    targets.magic={.4f,.7f,.5f,.9f}; targets.map={.8f,.7f,.95f,.95f};
    assert(hudActionAt(targets,.85f,.8f)==Action::Inventory);
    assert(hudActionAt(targets,.45f,.8f)==Action::ReadyMagic);
    assert(hudActionAt(targets,.3f,.8f)==Action::ReadyWeapon);
    assert(hudActionAt(targets,.1f,.8f)==Action::Journal);
    assert(!hudActionAt(targets,.65f,.8f)); // no guessed corner hit area
    assert(!hudActionAt(targets,.95f,.8f));
    const auto bit=[](Action action){return 1u<<static_cast<unsigned>(action);};
    assert(hudHiddenActions(targets)==(bit(Action::Inventory)|bit(Action::ReadyMagic)
        |bit(Action::ReadyWeapon)|bit(Action::Journal)|bit(Action::Wait)));
    assert(hudHiddenActions({})==0); // every fallback stays available without its real HUD target
    targets.magic={}; assert(!(hudHiddenActions(targets)&bit(Action::ReadyMagic)));
    for (Action action : {Action::Inventory,Action::ReadyWeapon,Action::ReadyMagic})
    {
        assert(!hudHasHold(action));
        gesture.begin(1,10,10,0);
        assert(gesture.finish(1,.1,false,hudHasHold(action))==R::Tap);
        gesture.begin(1,10,10,0);
        assert(gesture.finish(1,1.5,false,hudHasHold(action))==R::Tap);
        gesture.begin(1,10,10,0);
        assert(gesture.finish(1,.1,true,hudHasHold(action))==R::None);
    }
    assert(hudHasHold(Action::Journal)); // only stats keep the one-second Wait hold
    auto layout=makeLayout(1000,500,{});auto profile=profileFromLayout(layout);
    profile.customized=true;profile.buttons[0].center={.4f,.6f};applyProfile(layout,profile);
    const auto saved=profile.buttons[0].center;
    Ownership ownership;
    auto control=layout.buttons[0];
    auto binding=ownership.begin(1,control.bounds.center,layout,true);
    assert(binding && binding->action==control.action);ownership.clear();
    const auto hidden=1u<<static_cast<unsigned>(control.action);
    binding=ownership.begin(1,control.bounds.center,layout,true,hidden);
    assert(!binding || binding->action!=control.action);
    assert(profile.buttons[0].center.x==saved.x && profile.buttons[0].center.y==saved.y);
    std::cout<<"PASS minimap/spell/weapon tap routes, fallback visibility, stats hold, cancel and custom-control ownership\n";
}
