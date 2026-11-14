#pragma once
#include <cstdint>
#include <cmath>

namespace OpenMWIOS::Touch
{
    constexpr std::int64_t MenuDevice = 0x4f4d574d; // OMWM, synthetic menu fingers only
    struct TargetRect
    {
        float left = 0, top = 0, right = 0, bottom = 0;
        bool contains(float x, float y) const
        { return right > left && bottom > top && x >= left && x < right && y >= top && y < bottom; }
        bool valid() const { return right > left && bottom > top; }
        bool operator==(const TargetRect& other) const
        { return left == other.left && top == other.top && right == other.right && bottom == other.bottom; }
    };
    struct HudTargets { TargetRect stats, weapon, mouse; std::uint32_t generation = 0; };
    // Only value snapshots cross between the engine and UIKit threads.
    std::uint32_t inputGeneration();
    void invalidateInput();
    void publishHudTargets(HudTargets targets);
    HudTargets hudTargets();

    class TapHold
    {
        std::uintptr_t mId = 0;
        float mX = 0, mY = 0;
        double mStarted = 0;
        bool mConsumed = false;
    public:
        enum class Result { None, Tap, Hold };
        bool begin(std::uintptr_t id, float x, float y, double now)
        {
            if (!id || mId) return false;
            mId = id; mX = x; mY = y; mStarted = now; mConsumed = false; return true;
        }
        bool owns(std::uintptr_t id) const { return mId && mId == id; }
        bool active() const { return mId != 0; }
        void move(std::uintptr_t id, float x, float y, bool inside)
        { if (owns(id) && (!inside || std::hypot(x-mX, y-mY) > 8.f)) mConsumed = true; }
        Result update(double now)
        {
            if (!mId || mConsumed || now-mStarted < 1.0) return Result::None;
            mConsumed = true; return Result::Hold;
        }
        Result finish(std::uintptr_t id, double now, bool cancelled, bool allowHold = true)
        {
            if (!owns(id)) return Result::None;
            Result result = Result::None;
            if (!cancelled && !mConsumed)
                result = allowHold && now-mStarted >= 1.0 ? Result::Hold : Result::Tap;
            cancel(); return result;
        }
        void cancel() { mId = 0; mConsumed = false; }
    };
}
