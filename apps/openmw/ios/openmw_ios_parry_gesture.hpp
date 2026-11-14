#pragma once
#include <cmath>
#include <cstdint>
namespace OpenMWIOS::Touch {
// Loading screens pump input before World/player construction completes.
// Never evaluate the player query outside normal running gameplay.
template <class Query>
bool weaponReadyForInput(bool controlsDisabled, bool eventsDisabled, bool gameRunning, bool guiMode, Query query)
{
    return !controlsDisabled && !eventsDisabled && gameRunning && !guiMode && query();
}
// A dedicated guard surface: immediate down/up, never promoted to look.
class ParryGesture {
    std::uintptr_t mTouch = 0;
public:
    void begin(std::uintptr_t id, float, float, double) { mTouch = id; }
    bool move(std::uintptr_t id, float, float, float&, float&) {
        return id != mTouch || !mTouch;
    }
    void finish(std::uintptr_t id, double, bool) {
        if (id == mTouch) cancel();
    }
    bool pressed(double, bool weaponReady) {
        if (!weaponReady) cancel();
        return mTouch != 0;
    }
    void cancel() { mTouch = 0; }
};
}
