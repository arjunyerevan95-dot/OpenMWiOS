#include "apps/openmw/ios/openmw_ios_touch_state.hpp"
#include <cassert>
#include <iostream>
#include <limits>
#include <string>
#include <vector>

using namespace OpenMWIOS::Touch;
static bool near(float a, float b) { return std::abs(a-b) < 0.001f; }

int main()
{
    int checks = 0;
    const auto check = [&](bool ok) { if (!ok) { std::cerr << "Failed check " << checks + 1 << '\n'; std::abort(); } ++checks; };
    // Virtual storage only emits edges when observed: two consecutive fast taps.
    bool storage = false, observed = false;
    std::string edges;
    const auto set = [&](bool v) { storage = v; };
    const auto observe = [&] { if (storage != observed) { edges += storage ? 'P' : 'R'; observed = storage; } };
    check(dispatchPauseShortTap(false, false, set, observe));
    check(dispatchPauseShortTap(false, false, set, observe));
    check(edges == "PRPR" && !storage && !observed);
    check(!dispatchPauseShortTap(true, false, set, observe));
    check(!dispatchPauseShortTap(false, true, set, observe));
    check(edges == "PRPR");

    MenuGesture menu;
    check(!menu.expired(100));
    check(menu.begin(1, {20,20}, 100));
    check(!menu.begin(2, {20,20}, 100.1)); // second finger cannot own Menu
    check(!menu.finish(2, false) && menu.touch() == 1);
    check(!menu.expired(100.749));
    check(menu.finish(1, false) && !menu.touch());
    check(!menu.finish(1, false)); // repeated terminal callback
    check(menu.begin(1, {20,20}, 200)); // reuse UITouch address, new deadline
    check(menu.expired(200.75));
    menu.cancel(); // editor consumes it
    check(!menu.finish(1, false));
    check(menu.begin(3, {20,20}, 300));
    menu.move(3, {35,20});
    check(!menu.touch() && !menu.finish(3, false));
    check(menu.begin(4, {20,20}, 400));
    check(!menu.finish(4, true) && !menu.touch());
    check(menu.begin(5, {20,20}, 500));
    menu.cancel(); // background/mode transition
    check(!menu.expired(501) && !menu.finish(5, false));

    // Device menu policy has exactly one touch owner, never a system virtual pad.
    for (int mask = 0; mask < 16; ++mask)
    {
        const bool ready=mask&1, keyboard=mask&2, mouse=mask&4, pad=mask&8;
        const auto p = devicePolicy(ready, keyboard, mouse, pad);
        check(p.touch == (ready && !keyboard && !mouse && !pad));
        check(p.controllerMenus == pad);
    }
    auto layout = makeLayout(844,390,{0,47,21,47});
    auto profile = profileFromLayout(layout);
    check(validProfile(profile) && near(profile.idleOpacity,0.20f));
    profile.customized = true;
    profile.buttons[0].center = {0.55f,0.65f};
    profile.buttons[0].radius = 0.08f;
    profile.movementRadius = 0.19f;
    profile.idleOpacity = 0.35f;
    applyProfile(layout,profile);
    auto roundTrip=profileFromLayout(layout);
    check(near(roundTrip.buttons[0].center.x,0.55f) && near(roundTrip.buttons[0].center.y,0.65f));
    check(near(roundTrip.buttons[0].radius,0.08f) && near(roundTrip.movementRadius,0.19f));
    auto rotated=makeLayout(390,844,{47,0,34,0});
    applyProfile(rotated,profile);
    check(near(normalizedPoint(rotated,rotated.buttons[0].bounds.center).x,0.55f));
    for(const auto& b : rotated.buttons)
    {
        check(b.bounds.center.x >= rotated.safeArea.left + b.bounds.radius);
        check(b.bounds.center.y >= rotated.safeArea.top + b.bounds.radius);
        check(b.bounds.center.x + b.bounds.radius <= rotated.width - rotated.safeArea.right);
        check(b.bounds.center.y + b.bounds.radius <= rotated.height - rotated.safeArea.bottom);
    }
    auto bad=profile; bad.version=99; check(!validProfile(bad));
    bad=profile; bad.buttons[2].radius=0; check(!validProfile(bad));
    bad=profile; bad.buttons[2].center.x=std::numeric_limits<float>::quiet_NaN(); check(!validProfile(bad));
    bad=profile; bad.idleOpacity=std::numeric_limits<float>::infinity(); check(!validProfile(bad));
    bad=profile; bad.movementRadius=-1; check(!validProfile(bad));
    bad=profile; bad.buttons[2].center.y=2; check(!validProfile(bad));
    auto untouched=makeLayout(844,390,{0,47,21,47});
    bad=profile; bad.version=99; applyProfile(untouched,bad);
    check(near(untouched.buttons[0].bounds.center.x,makeLayout(844,390,{0,47,21,47}).buttons[0].bounds.center.x));

    // Actual editor state used by UIKit: cancel, done, reset confirmation, undo.
    ProfileEditor editor;
    editor.begin(profile);
    profile.idleOpacity=0.65f;
    editor.finish(false,profile);
    check(!editor.active && near(profile.idleOpacity,0.35f));
    editor.begin(profile); profile.idleOpacity=0.45f; editor.finish(true,profile);
    check(!editor.active && near(profile.idleOpacity,0.45f));
    editor.begin(profile);
    const float oldX=layout.buttons[0].bounds.center.x;
    editor.reset(layout,profile);
    check(editor.resetArmed && near(layout.buttons[0].bounds.center.x,oldX));
    editor.reset(layout,profile);
    check(editor.resetApplied && near(profile.idleOpacity,0.45f));
    check(!near(layout.buttons[0].bounds.center.x,oldX));
    editor.reset(layout,profile);
    check(!editor.resetApplied && near(layout.buttons[0].bounds.center.x,oldX));
    editor.finish(false,profile);
    check(near(profile.idleOpacity,0.45f));

    // Ownership/release semantics across buttons, movement, look, menu passthrough.
    layout=makeLayout(844,390,{0,47,21,47});
    Ownership owner;
    const auto a=layout.buttons[0];
    auto binding=owner.begin(10,a.bounds.center,layout);
    check(binding && binding->action == a.action);
    check(!owner.begin(10,a.bounds.center,layout));
    auto other=owner.begin(11,a.bounds.center,layout);
    check(!other || other->action != a.action);
    check(owner.end(10).has_value() && !owner.end(10));
    owner.clear();
    check(owner.bindings().empty());
    check(!owner.begin(20,{400,200},layout,false)); // ordinary menu touch passes through
    auto movement=owner.begin(30,{90,200},layout);
    check(movement && movement->role == Role::Movement);
    auto look=owner.begin(31,{500,200},layout);
    check(look && look->role == Role::Look);
    check(!owner.begin(32,{90,200},layout));
    check(movementVector({0,0},50,{0,0}).magnitude == 0);
    check(near(movementVector({0,0},50,{100,0}).magnitude,1));
    owner.clear(); // cancel/editor/background: every ownership record discarded
    check(!owner.end(30) && !owner.end(31));
    std::cout << "PASS " << checks << " executable input/layout/profile checks\n";
}
