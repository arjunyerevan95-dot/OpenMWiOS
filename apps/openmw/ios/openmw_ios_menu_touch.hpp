#pragma once
#include <cmath>
#include <cstdint>

namespace OpenMWIOS::Touch
{
// The game thread selects the route from the actual MyGUI mouse-focus widget.
// Taps stay deferred; map motion starts a direct drag without a long hold.
class MenuTouch
{
    bool mDirect = false;
    std::uintptr_t mId = 0;
    float mStartX = 0, mStartY = 0, mLast = 0;
    int mAxis = 0;
    double mStarted = 0;
    bool mDragging = false;
    float mCurrentX = 0, mCurrentY = 0;
public:
    bool begin(std::uintptr_t id, float x, float y, double now = 0, bool direct = false)
    {
        if (!id || mId) return false;
        mId = id; mStartX = x; mStartY = y; mAxis = 0; mLast = 0;
        mDirect = direct; mStarted = now; mDragging = false; mCurrentX = x; mCurrentY = y;
        return true;
    }
    bool owns(std::uintptr_t id) const { return mId && id == mId; }
    float x() const { return mStartX; }
    float y() const { return mStartY; }
    bool dragging() const { return mDragging; }
    float currentX() const { return mCurrentX; }
    float currentY() const { return mCurrentY; }
    float move(std::uintptr_t id, float x, float y, double now = 0)
    {
        if (!owns(id)) return 0;
        mCurrentX = x; mCurrentY = y;
        if (mDragging) return 0;
        const float dx = x - mStartX, dy = y - mStartY;
        if (!mAxis)
        {
            if (std::hypot(dx, dy) < 8.f) return 0;
            if (mDirect || now - mStarted >= 0.4)
            {
                mDragging = true;
                return 0;
            }
            mAxis = std::abs(dx) > std::abs(dy) ? 1 : 2;
        }
        const float current = mAxis == 1 ? dx : dy;
        const float delta = current - mLast;
        mLast = current;
        // OpenMW MyGUI uses vertical wheel input for both vertical lists and
        // its horizontal inventory ItemView. Keep sign natural on either axis.
        return delta / 36.f;
    }
    bool finish(std::uintptr_t id, bool cancelled)
    {
        if (!owns(id)) return false;
        const bool tap = !cancelled && !mAxis && !mDragging;
        cancel();
        return tap;
    }
    void cancel() { mId = 0; mAxis = 0; mLast = 0; mDragging = false; }
};
}

