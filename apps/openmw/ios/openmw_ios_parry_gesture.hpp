#pragma once
#include <cmath>
#include <cstdint>
namespace OpenMWIOS::Touch {
class ParryGesture {
    std::uintptr_t mTouch = 0;
    float mX = 0, mY = 0;
    double mStart = 0, mPulseUntil = 0;
    bool mLooking = false, mHeld = false;
public:
    static constexpr double HoldDelay = 0.09;
    static constexpr double TapPulse = 0.12;
    static constexpr float Slop = 8.f;
    void begin(std::uintptr_t id, float x, float y, double now) {
        mTouch=id; mX=x; mY=y; mStart=now; mLooking=false; mHeld=false; mPulseUntil=0;
    }
    // First recognized swipe returns accumulated movement; subsequent moves use
    // ordinary per-touch deltas. No movement is lost during arbitration.
    bool move(std::uintptr_t id, float x, float y, float& dx, float& dy) {
        if (id != mTouch || !mTouch) return true;
        if (mLooking) return true;
        if (std::hypot(x-mX,y-mY) < Slop) return false;
        mLooking=true; mHeld=false; mPulseUntil=0; dx=x-mX; dy=y-mY; return true;
    }
    void finish(std::uintptr_t id, double now, bool cancelled) {
        if (id != mTouch || !mTouch) return;
        if (!cancelled && !mLooking && !mHeld && now-mStart < HoldDelay)
            mPulseUntil=now+TapPulse;
        mTouch=0; mHeld=false;
    }
    bool pressed(double now, bool weaponReady) {
        if (!weaponReady) { cancel(); return false; }
        if (mTouch && !mLooking && now-mStart >= HoldDelay) mHeld=true;
        return mHeld || now < mPulseUntil;
    }
    void cancel() { mTouch=0; mHeld=false; mPulseUntil=0; mLooking=false; }
};
}
