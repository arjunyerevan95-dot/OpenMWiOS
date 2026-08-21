#pragma once

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <optional>
#include <unordered_map>

namespace OpenMWIOS::Touch
{
    struct Point
    {
        float x = 0.f;
        float y = 0.f;
    };

    struct Insets
    {
        float top = 0.f;
        float left = 0.f;
        float bottom = 0.f;
        float right = 0.f;
    };

    struct Circle
    {
        Point center;
        float radius = 0.f;

        bool contains(Point point, float expansion = 1.f) const
        {
            const float dx = point.x - center.x;
            const float dy = point.y - center.y;
            const float hitRadius = radius * expansion;
            return dx * dx + dy * dy <= hitRadius * hitRadius;
        }
    };

    enum class Action : std::uint8_t
    {
        Activate,
        Attack,
        Jump,
        ReadyWeapon,
        ReadyMagic,
        Inventory,
        Pause,
        Sneak,
        Journal,
    };

    constexpr std::size_t ActionCount = 9;

    struct Button
    {
        Action action;
        Circle bounds;
    };

    struct Layout
    {
        float width = 0.f;
        float height = 0.f;
        Insets safeArea;
        Circle movement;
        float movementCaptureRadius = 0.f;
        Circle look;
        float lookCaptureRadius = 0.f;
        std::array<Button, ActionCount> buttons;
    };

    inline float clamp(float value, float minimum, float maximum)
    {
        return std::max(minimum, std::min(value, maximum));
    }

    inline Layout makeLayout(float width, float height, Insets safeArea)
    {
        Layout layout;
        layout.width = std::max(width, 1.f);
        layout.height = std::max(height, 1.f);
        layout.safeArea = safeArea;

        const float shortSide = std::min(layout.width, layout.height);
        const float stickRadius = clamp(shortSide * 0.17f, 54.f, 96.f);
        const float buttonRadius = clamp(shortSide * 0.075f, 24.f, 42.f);
        const float contentWidth = std::max(layout.width - safeArea.left - safeArea.right, 1.f);
        const float contentHeight = std::max(layout.height - safeArea.top - safeArea.bottom, 1.f);

        const auto centerFromAndroidTopLeft = [&](float normalizedX, float normalizedY, float radius) {
            return Point{
                clamp(safeArea.left + normalizedX * contentWidth + radius, safeArea.left + radius,
                    layout.width - safeArea.right - radius),
                clamp(safeArea.top + normalizedY * contentHeight + radius, safeArea.top + radius,
                    layout.height - safeArea.bottom - radius),
            };
        };

        // Android 2.7.4 stores these as normalized top-left offsets in UI.cfg.
        // Preserve the grouping while deriving all physical positions from the
        // current safe-area geometry.
        layout.movement.center = centerFromAndroidTopLeft(0.048932366f, 0.5294487f, stickRadius);
        layout.movement.radius = stickRadius;
        layout.movementCaptureRadius = stickRadius * 1.4f;
        layout.look.center = centerFromAndroidTopLeft(0.71470284f, 0.5663806f, stickRadius);
        layout.look.radius = stickRadius;
        layout.lookCaptureRadius = stickRadius * 1.15f;

        struct AndroidButton
        {
            Action action;
            float normalizedX;
            float normalizedY;
            float radiusScale;
        };
        const std::array<AndroidButton, ActionCount> androidButtons = {
            AndroidButton{ Action::Activate, 0.24287565f, 0.7986111f, 1.f },
            AndroidButton{ Action::Attack, 0.8257772f, 0.41666666f, 1.2f },
            AndroidButton{ Action::Jump, 0.6476684f, 0.7986111f, 1.f },
            AndroidButton{ Action::ReadyWeapon, 0.92292744f, 0.6944444f, 1.f },
            AndroidButton{ Action::ReadyMagic, 0.92292744f, 0.5208333f, 1.f },
            AndroidButton{ Action::Inventory, 0.92292744f, 0.20833333f, 1.f },
            AndroidButton{ Action::Pause, 0.92292744f, 0.034722224f, 1.f },
            AndroidButton{ Action::Sneak, 0.8419689f, 0.034722224f, 1.f },
            // Recent Android exposes journal through its menu/utility layer.
            // iOS gives that semantic action a direct companion target.
            AndroidButton{ Action::Journal, 0.8419689f, 0.20833333f, 1.f },
        };

        for (std::size_t index = 0; index < layout.buttons.size(); ++index)
        {
            const float radius = buttonRadius * androidButtons[index].radiusScale;
            layout.buttons[index] = {
                androidButtons[index].action,
                Circle{ centerFromAndroidTopLeft(androidButtons[index].normalizedX,
                            androidButtons[index].normalizedY, radius),
                    radius },
            };
        }
        return layout;
    }

    inline bool visibleInMode(Action action, bool gameplayMode)
    {
        if (gameplayMode)
            return true;
        return action == Action::Inventory || action == Action::Pause || action == Action::Journal;
    }

    struct StickVector
    {
        float x = 0.f;
        float y = 0.f;
        float magnitude = 0.f;
    };

    inline StickVector movementVector(const Layout& layout, Point point, float deadZone = 0.2f)
    {
        const float radius = std::max(layout.movement.radius, 1.f);
        const float rawX = (point.x - layout.movement.center.x) / radius;
        const float rawY = (point.y - layout.movement.center.y) / radius;
        const float rawMagnitude = std::sqrt(rawX * rawX + rawY * rawY);
        const float clampedDeadZone = clamp(deadZone, 0.f, 0.95f);
        if (rawMagnitude <= clampedDeadZone)
            return {};

        const float directionX = rawX / rawMagnitude;
        const float directionY = rawY / rawMagnitude;
        const float magnitude = clamp((rawMagnitude - clampedDeadZone) / (1.f - clampedDeadZone), 0.f, 1.f);
        return { directionX * magnitude, directionY * magnitude, magnitude };
    }

    enum class Role : std::uint8_t
    {
        None,
        Movement,
        Look,
        Button,
    };

    struct Binding
    {
        Role role = Role::None;
        std::optional<Action> action;
        Point lastPoint;
    };

    class Ownership
    {
    public:
        std::optional<Binding> begin(std::uintptr_t touchId, Point point, const Layout& layout,
            bool gameplayMode = true)
        {
            if (mBindings.find(touchId) != mBindings.end())
                return std::nullopt;

            for (const Button& button : layout.buttons)
            {
                if (visibleInMode(button.action, gameplayMode) && button.bounds.contains(point, 1.15f)
                    && !actionOwned(button.action))
                    return add(touchId, { Role::Button, button.action, point });
            }

            if (gameplayMode
                && layout.movement.contains(point, layout.movementCaptureRadius / layout.movement.radius)
                && !roleOwned(Role::Movement))
            {
                return add(touchId, { Role::Movement, std::nullopt, point });
            }

            if (gameplayMode && layout.look.contains(point, layout.lookCaptureRadius / layout.look.radius)
                && !roleOwned(Role::Look))
                return add(touchId, { Role::Look, std::nullopt, point });

            return std::nullopt;
        }

        std::optional<Binding> move(std::uintptr_t touchId, Point point)
        {
            auto found = mBindings.find(touchId);
            if (found == mBindings.end())
                return std::nullopt;
            Binding previous = found->second;
            found->second.lastPoint = point;
            return previous;
        }

        std::optional<Binding> end(std::uintptr_t touchId)
        {
            auto found = mBindings.find(touchId);
            if (found == mBindings.end())
                return std::nullopt;
            Binding binding = found->second;
            mBindings.erase(found);
            return binding;
        }

        const std::unordered_map<std::uintptr_t, Binding>& bindings() const { return mBindings; }
        void clear() { mBindings.clear(); }

    private:
        std::unordered_map<std::uintptr_t, Binding> mBindings;

        std::optional<Binding> add(std::uintptr_t touchId, Binding binding)
        {
            mBindings.emplace(touchId, binding);
            return binding;
        }

        bool roleOwned(Role role) const
        {
            for (const auto& [touchId, binding] : mBindings)
            {
                (void)touchId;
                if (binding.role == role)
                    return true;
            }
            return false;
        }

        bool actionOwned(Action action) const
        {
            for (const auto& [touchId, binding] : mBindings)
            {
                (void)touchId;
                if (binding.action && *binding.action == action)
                    return true;
            }
            return false;
        }
    };
}
