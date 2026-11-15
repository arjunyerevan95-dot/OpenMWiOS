#pragma once
#include "openmw_ios_touch_model.hpp"
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
    struct HudTargets { TargetRect stats, weapon, magic, map; std::uint32_t generation = 0; };
    inline TargetRect hudTarget(const HudTargets& targets, Action action)
    {
        switch (action)
        {
            case Action::Inventory: return targets.map;
            case Action::Journal: return targets.stats;
            case Action::ReadyWeapon: return targets.weapon;
            case Action::ReadyMagic: return targets.magic;
            default: return {};
        }
    }
    inline std::optional<Action> hudActionAt(const HudTargets& targets, float x, float y)
    {
        for (Action action : {Action::Inventory, Action::Journal, Action::ReadyWeapon, Action::ReadyMagic})
            if (hudTarget(targets, action).contains(x, y)) return action;
        return std::nullopt;
    }
    inline bool hudHasHold(Action action) { return action == Action::Journal; }
    inline std::uint32_t hudHiddenActions(const HudTargets& targets)
    {
        std::uint32_t hidden = 0;
        for (Action action : {Action::Inventory, Action::Journal, Action::ReadyWeapon, Action::ReadyMagic})
            if (hudTarget(targets, action).valid()) hidden |= 1u << static_cast<unsigned>(action);
        if (targets.stats.valid()) hidden |= 1u << static_cast<unsigned>(Action::Wait);
        return hidden;
    }
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
