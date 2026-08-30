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
        TogglePOV,
        QuickSave,
        Wait,
    };

    constexpr std::size_t ActionCount = 12;

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
        float movementRadius = 0.f;
        float movementBoundaryX = 0.f;
        float lookBoundaryX = 0.f;
        std::array<Button, ActionCount> buttons;
    };

    constexpr std::uint32_t ProfileVersion = 1;

    struct NormalizedControl
    {
        // Center is normalized to the current safe-area rectangle. Radius is
        // normalized to its short side so profiles remain portable across
        // iPhone/iPad sizes and orientations.
        Point center;
        float radius = 0.f;
    };

    struct ControlProfile
    {
        std::uint32_t version = ProfileVersion;
        bool customized = false;
        float idleOpacity = 0.20f;
        float movementRadius = 0.f;
        std::array<NormalizedControl, ActionCount> buttons{};
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
        const float stickRadius = clamp(shortSide * 0.15f, 48.f, 92.f);
        const float contentWidth = std::max(layout.width - safeArea.left - safeArea.right, 1.f);
        const float contentHeight = std::max(layout.height - safeArea.top - safeArea.bottom, 1.f);

        // The archived Android OSC uses a 1024x768 virtual coordinate system.
        // Preserve its asymmetric placement, while resolving every point against
        // the current device safe area. Size follows Android's width scale.
        const auto androidButton = [&](float virtualX, float virtualY, float virtualSize) {
            const float radius = clamp(virtualSize * contentWidth / 2048.f, 22.f, 72.f);
            const float topLeftX = safeArea.left + virtualX * contentWidth / 1024.f;
            const float topLeftY = safeArea.top + virtualY * contentHeight / 768.f;
            return Point{
                clamp(topLeftX + radius, safeArea.left + radius,
                    layout.width - safeArea.right - radius),
                clamp(topLeftY + radius, safeArea.top + radius,
                    layout.height - safeArea.bottom - radius),
            };
        };

        layout.movementRadius = stickRadius;
        layout.movementBoundaryX = safeArea.left + contentWidth * 0.36f;
        layout.lookBoundaryX = layout.movementBoundaryX;

        struct AndroidButton
        {
            Action action;
            float virtualX;
            float virtualY;
            float virtualSize;
        };
        const std::array<AndroidButton, ActionCount> androidButtons = {
            AndroidButton{ Action::Activate, 330.f, 630.f, 70.f },
            AndroidButton{ Action::Attack, 800.f, 315.f, 120.f },
            AndroidButton{ Action::Jump, 624.f, 630.f, 70.f },
            AndroidButton{ Action::ReadyWeapon, 940.f, 560.f, 70.f },
            AndroidButton{ Action::ReadyMagic, 940.f, 450.f, 70.f },
            AndroidButton{ Action::Inventory, 940.f, 95.f, 70.f },
            AndroidButton{ Action::Pause, 940.f, 0.f, 70.f },
            AndroidButton{ Action::Sneak, 850.f, 0.f, 70.f },
            AndroidButton{ Action::Journal, 270.f, 0.f, 70.f },
            AndroidButton{ Action::TogglePOV, 90.f, 0.f, 70.f },
            AndroidButton{ Action::QuickSave, 180.f, 0.f, 70.f },
            AndroidButton{ Action::Wait, 360.f, 0.f, 70.f },
        };

        for (std::size_t index = 0; index < layout.buttons.size(); ++index)
        {
            const float radius = clamp(androidButtons[index].virtualSize * contentWidth / 2048.f, 22.f, 72.f);
            layout.buttons[index] = {
                androidButtons[index].action,
                Circle{ androidButton(androidButtons[index].virtualX,
                            androidButtons[index].virtualY, androidButtons[index].virtualSize),
                    radius },
            };
        }
        return layout;
    }

    inline Point normalizedPoint(const Layout& layout, Point point)
    {
        const float contentWidth = std::max(layout.width - layout.safeArea.left - layout.safeArea.right, 1.f);
        const float contentHeight = std::max(layout.height - layout.safeArea.top - layout.safeArea.bottom, 1.f);
        return { (point.x - layout.safeArea.left) / contentWidth,
            (point.y - layout.safeArea.top) / contentHeight };
    }

    inline Point denormalizedPoint(const Layout& layout, Point point)
    {
        const float contentWidth = std::max(layout.width - layout.safeArea.left - layout.safeArea.right, 1.f);
        const float contentHeight = std::max(layout.height - layout.safeArea.top - layout.safeArea.bottom, 1.f);
        return { layout.safeArea.left + point.x * contentWidth, layout.safeArea.top + point.y * contentHeight };
    }

    inline float safeShortSide(const Layout& layout)
    {
        return std::max(std::min(layout.width - layout.safeArea.left - layout.safeArea.right,
                            layout.height - layout.safeArea.top - layout.safeArea.bottom),
            1.f);
    }

    inline ControlProfile profileFromLayout(const Layout& layout)
    {
        ControlProfile profile;
        const float shortSide = safeShortSide(layout);
        profile.movementRadius = layout.movementRadius / shortSide;
        for (std::size_t index = 0; index < ActionCount; ++index)
        {
            profile.buttons[index].center = normalizedPoint(layout, layout.buttons[index].bounds.center);
            profile.buttons[index].radius = layout.buttons[index].bounds.radius / shortSide;
        }
        return profile;
    }

    inline void clampCircleToSafeArea(Circle& circle, const Layout& layout, float minimumRadius = 18.f)
    {
        const float maximumRadius = safeShortSide(layout) * 0.24f;
        circle.radius = clamp(circle.radius, minimumRadius, maximumRadius);
        circle.center.x = clamp(circle.center.x, layout.safeArea.left + circle.radius,
            layout.width - layout.safeArea.right - circle.radius);
        circle.center.y = clamp(circle.center.y, layout.safeArea.top + circle.radius,
            layout.height - layout.safeArea.bottom - circle.radius);
    }

    inline void applyProfile(Layout& layout, const ControlProfile& profile)
    {
        if (!profile.customized || profile.version != ProfileVersion)
            return;
        const float shortSide = safeShortSide(layout);
        layout.movementRadius = clamp(profile.movementRadius * shortSide, 36.f, shortSide * 0.24f);
        for (std::size_t index = 0; index < ActionCount; ++index)
        {
            layout.buttons[index].bounds.center = denormalizedPoint(layout, profile.buttons[index].center);
            layout.buttons[index].bounds.radius = profile.buttons[index].radius * shortSide;
            // Menu is the only way back into the editor, so retain a slightly
            // larger minimum and never permit it outside the safe area.
            const float minimumRadius = layout.buttons[index].action == Action::Pause ? 24.f : 18.f;
            clampCircleToSafeArea(layout.buttons[index].bounds, layout, minimumRadius);
        }
    }

    inline void updateProfileButton(ControlProfile& profile, const Layout& layout, std::size_t index)
    {
        if (index >= ActionCount)
            return;
        profile.version = ProfileVersion;
        profile.customized = true;
        profile.buttons[index].center = normalizedPoint(layout, layout.buttons[index].bounds.center);
        profile.buttons[index].radius = layout.buttons[index].bounds.radius / safeShortSide(layout);
        profile.movementRadius = layout.movementRadius / safeShortSide(layout);
    }

    inline bool visibleInMode(Action action, bool gameplayMode)
    {
        if (gameplayMode)
            return true;
        return action == Action::Inventory || action == Action::Pause || action == Action::Journal;
    }

    // A virtual SDL controller stores only the latest button value until its
    // next update. Keep a short Pause tap observable by placing one input
    // update between the press and release writes. Cancellation and a
    // long-press consumed by the editor must not leak a Pause pulse.
    template <class SetPressed, class ObserveInput>
    bool dispatchPauseShortTap(
        bool cancelled, bool consumedByLongPress, SetPressed setPressed, ObserveInput observeInput)
    {
        if (cancelled || consumedByLongPress)
            return false;

        setPressed(true);
        observeInput();
        setPressed(false);
        return true;
    }

    struct StickVector
    {
        float x = 0.f;
        float y = 0.f;
        float magnitude = 0.f;
    };

    inline StickVector movementVector(Point center, float radius, Point point, float deadZone = 0.2f)
    {
        radius = std::max(radius, 1.f);
        const float rawX = (point.x - center.x) / radius;
        const float rawY = (point.y - center.y) / radius;
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
        Point startPoint;
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
                    return add(touchId, { Role::Button, button.action, point, point });
            }

            if (gameplayMode && point.x <= layout.movementBoundaryX && !roleOwned(Role::Movement))
            {
                return add(touchId, { Role::Movement, std::nullopt, point, point });
            }

            if (gameplayMode && point.x >= layout.lookBoundaryX && !roleOwned(Role::Look))
                return add(touchId, { Role::Look, std::nullopt, point, point });

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
