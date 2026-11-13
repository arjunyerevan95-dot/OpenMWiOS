#ifndef OPENMW_IOS_USE_GESTURE_HPP
#define OPENMW_IOS_USE_GESTURE_HPP
#include <cstdint>
namespace OpenMWIOS::Touch {
// Activate is deferred until release so a long press cannot pick up the object
// before LuaPhysics receives its independent hold action.
class UseGesture {
    std::uintptr_t mTouch = 0;
    double mStart = 0;
    bool mDragging = false;
public:
    static constexpr double HoldSeconds = 0.35;
    enum class End { None, Tap, Drop };
    bool begin(std::uintptr_t id, double now) {
        if (!id || mTouch) return false;
        mTouch = id; mStart = now; mDragging = false; return true;
    }
    bool update(double now) {
        if (!mTouch || mDragging || now - mStart < HoldSeconds) return false;
        mDragging = true; return true;
    }
    End finish(std::uintptr_t id, double now, bool cancelled) {
        if (id != mTouch || !id) return End::None;
        const auto result = mDragging ? End::Drop :
            (!cancelled && now - mStart < HoldSeconds ? End::Tap : End::None);
        mTouch = 0; mDragging = false; return result;
    }
    void cancel() { mTouch = 0; mDragging = false; }
    std::uintptr_t touch() const { return mTouch; }
};
}
#endif
