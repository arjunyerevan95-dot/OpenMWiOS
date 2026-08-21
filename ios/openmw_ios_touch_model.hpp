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
    };

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
        float lookBoundaryX = 0.f;
        std::array<Button, 8> buttons;
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
        const float edge = clamp(shortSide * 0.035f, 12.f, 28.f);
        const float stickRadius = clamp(shortSide * 0.17f, 54.f, 96.f);
        const float buttonRadius = clamp(shortSide * 0.075f, 24.f, 42.f);
        const float buttonStep = buttonRadius * 2.f + clamp(shortSide * 0.025f, 8.f, 18.f);

        layout.movement.center = {
            safeArea.left + edge + stickRadius,
            layout.height - safeArea.bottom - edge - stickRadius,
        };
        layout.movement.radius = stickRadius;
        layout.movementCaptureRadius = stickRadius * 1.4f;
        layout.lookBoundaryX = layout.width * 0.38f;

        const float right = layout.width - safeArea.right - edge - buttonRadius;
        const float bottom = layout.height - safeArea.bottom - edge - buttonRadius;
        const std::array<Action, 8> actions = {
            Action::Activate,
            Action::Attack,
            Action::Jump,
            Action::ReadyWeapon,
            Action::ReadyMagic,
            Action::Inventory,
            Action::Pause,
            Action::Sneak,
        };
        const std::array<Point, 8> offsets = {
            Point{ 0.f, 0.f },
            Point{ -buttonStep, 0.f },
            Point{ 0.f, -buttonStep },
            Point{ -buttonStep, -buttonStep },
            Point{ -2.f * buttonStep, -buttonStep },
            Point{ 0.f, -2.f * buttonStep },
            Point{ -buttonStep, -2.f * buttonStep },
            Point{ -2.f * buttonStep, -2.f * buttonStep },
        };

        for (std::size_t index = 0; index < layout.buttons.size(); ++index)
        {
            layout.buttons[index] = {
                actions[index],
                Circle{ Point{ right + offsets[index].x, bottom + offsets[index].y }, buttonRadius },
            };
        }
        return layout;
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
        std::optional<Binding> begin(std::uintptr_t touchId, Point point, const Layout& layout)
        {
            if (mBindings.find(touchId) != mBindings.end())
                return std::nullopt;

            for (const Button& button : layout.buttons)
            {
                if (button.bounds.contains(point, 1.15f) && !actionOwned(button.action))
                    return add(touchId, { Role::Button, button.action, point });
            }

            if (layout.movement.contains(point, layout.movementCaptureRadius / layout.movement.radius)
                && !roleOwned(Role::Movement))
            {
                return add(touchId, { Role::Movement, std::nullopt, point });
            }

            if (point.x >= layout.lookBoundaryX && !roleOwned(Role::Look))
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
