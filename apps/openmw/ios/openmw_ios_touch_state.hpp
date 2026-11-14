// WO40 input-only state shared by the UIKit adapter and executable host tests.
#pragma once
#include "openmw_ios_touch_model.hpp"

namespace OpenMWIOS::Touch
{
    struct DevicePolicy
    {
        bool touch;
        bool controllerMenus;
    };

    inline DevicePolicy devicePolicy(bool reported, bool keyboard, bool mouse, bool physicalController)
    {
        return { reported && !keyboard && !mouse && !physicalController, physicalController };
    }

    // No delayed block can outlive/reuse a UITouch address. The display link checks
    // the current gesture's monotonic deadline; every terminal path clears it.
    class MenuGesture
    {
    public:
        bool begin(std::uintptr_t id, Point point, double now)
        {
            if (!id || mTouch)
                return false;
            mTouch = id;
            mStart = point;
            mDeadline = now + 0.75;
            return true;
        }
        std::uintptr_t touch() const { return mTouch; }
        bool expired(double now) const { return mTouch && now >= mDeadline; }
        void move(std::uintptr_t id, Point point)
        {
            if (id == mTouch && std::hypot(point.x - mStart.x, point.y - mStart.y) > 14.f)
                cancel();
        }
        bool finish(std::uintptr_t id, bool cancelled)
        {
            if (!mTouch || id != mTouch)
                return false;
            cancel();
            return !cancelled;
        }
        void cancel() { mTouch = 0; mDeadline = 0; }
    private:
        std::uintptr_t mTouch = 0;
        Point mStart{};
        double mDeadline = 0;
    };

    // Selectively adapted from WO38 457ab881: SDL virtual setters alone do not
    // enqueue a press. Observe both edges, including between consecutive taps.
    template <class SetPressed, class Observe>
    bool dispatchPauseShortTap(bool cancelled, bool editorConsumed, SetPressed setPressed, Observe observe)
    {
        if (cancelled || editorConsumed)
            return false;
        setPressed(true);
        observe();
        setPressed(false);
        observe();
        return true;
    }

    inline bool validProfile(const ControlProfile& p)
    {
        if (p.version != ProfileVersion || !std::isfinite(p.idleOpacity)
            || p.idleOpacity < 0.05f || p.idleOpacity > 0.85f
            || !std::isfinite(p.movementRadius) || p.movementRadius <= 0.f || p.movementRadius > 1.f)
            return false;
        for (const auto& b : p.buttons)
            if (!std::isfinite(b.center.x) || !std::isfinite(b.center.y) || !std::isfinite(b.radius)
                || b.center.x < 0.f || b.center.x > 1.f || b.center.y < 0.f || b.center.y > 1.f
                || b.radius <= 0.f || b.radius > 1.f)
                return false;
        return true;
    }

    class EditorPinch
    {
        int mIndex = -1;
        Circle mCircle{};
        float mMovement = 0;
    public:
        bool active() const { return mIndex >= 0; }
        bool begin(bool editing, int index, const Layout& layout)
        {
            if (!editing || index < 0 || index > static_cast<int>(ActionCount)
                || (index < static_cast<int>(ActionCount) && layout.buttons[index].action == Action::Parry)) return false;
            mIndex = index; mMovement = layout.movementRadius;
            if (index < static_cast<int>(ActionCount)) mCircle = layout.buttons[index].bounds;
            return true;
        }
        void update(Layout& layout, float scale)
        {
            if (!active() || !std::isfinite(scale) || scale <= 0) return;
            if (mIndex == static_cast<int>(ActionCount))
                layout.movementRadius = clamp(mMovement * scale, 36.f, safeShortSide(layout) * 0.24f);
            else
            {
                auto& b = layout.buttons[mIndex];
                b.bounds = mCircle; b.bounds.radius *= scale;
                clampCircleToSafeArea(b.bounds, layout, b.action == Action::Pause ? 24.f : 18.f);
            }
        }
        void finish(Layout& layout, bool cancel)
        {
            if (active() && cancel)
            {
                if (mIndex == static_cast<int>(ActionCount)) layout.movementRadius = mMovement;
                else layout.buttons[mIndex].bounds = mCircle;
            }
            mIndex = -1;
        }
    };

    class ProfileEditor
    {
    public:
        bool active = false;
        bool resetArmed = false;
        bool resetApplied = false;
        void begin(const ControlProfile& profile)
        {
            mSnapshot = profile;
            active = true;
            changed();
        }
        void finish(bool save, ControlProfile& profile)
        {
            if (!active)
                return;
            if (!save)
                profile = mSnapshot;
            active = false;
            changed();
        }
        void changed() { resetArmed = resetApplied = false; }
        void reset(Layout& layout, ControlProfile& profile)
        {
            if (resetApplied)
            {
                profile = mBeforeReset;
                applyProfile(layout, profile);
                changed();
            }
            else if (resetArmed)
            {
                mBeforeReset = profileFromLayout(layout);
                mBeforeReset.customized = true;
                mBeforeReset.idleOpacity = profile.idleOpacity;
                layout = makeLayout(layout.width, layout.height, layout.safeArea);
                const float opacity = profile.idleOpacity; // accepted practical reset behavior
                profile = profileFromLayout(layout);
                profile.idleOpacity = opacity;
                resetArmed = false;
                resetApplied = true;
            }
            else
                resetArmed = true;
        }
    private:
        ControlProfile mSnapshot;
        ControlProfile mBeforeReset;
    };
}
