#import "openmw_ios_touch_controls.h"

#import "openmw_ios_logging.h"
#import "openmw_ios_touch_icons.hpp"
#import "openmw_ios_touch_model.hpp"

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#include <SDL.h>

#include <array>
#include <cmath>
#include <cstdint>
#include <string>

namespace
{
    using OpenMWIOS::Touch::Action;
    using OpenMWIOS::Touch::Binding;
    using OpenMWIOS::Touch::Layout;
    using OpenMWIOS::Touch::Role;

    constexpr CGFloat TouchOverlayTag = 0x4f4d5754; // OMWT
    constexpr float MovementDeadZone = 0.2f;
    constexpr float LookSensitivity = 1.25f;
    constexpr int DiagnosticBudget = 48;

    std::uintptr_t touchId(UITouch* touch)
    {
        return reinterpret_cast<std::uintptr_t>((__bridge void*)touch);
    }

    int controllerButtonForAction(Action action)
    {
        switch (action)
        {
            case Action::Activate:
                return SDL_CONTROLLER_BUTTON_A;
            case Action::ReadyWeapon:
                return SDL_CONTROLLER_BUTTON_X;
            case Action::ReadyMagic:
                return SDL_CONTROLLER_BUTTON_Y;
            case Action::Inventory:
                return SDL_CONTROLLER_BUTTON_B;
            case Action::Pause:
                return SDL_CONTROLLER_BUTTON_START;
            case Action::Sneak:
                return SDL_CONTROLLER_BUTTON_LEFTSTICK;
            case Action::Journal:
                return SDL_CONTROLLER_BUTTON_LEFTSHOULDER;
            case Action::TogglePOV:
            case Action::QuickSave:
            case Action::Wait:
            case Action::Attack:
            case Action::Jump:
                return -1;
        }
        return -1;
    }

    int controllerAxisForAction(Action action)
    {
        switch (action)
        {
            case Action::Attack:
                return SDL_CONTROLLER_AXIS_TRIGGERRIGHT;
            case Action::Jump:
                return SDL_CONTROLLER_AXIS_TRIGGERLEFT;
            default:
                return -1;
        }
    }

    SDL_Scancode fallbackScancodeForAction(Action action)
    {
        switch (action)
        {
            case Action::Activate:
                return SDL_SCANCODE_SPACE;
            case Action::Jump:
                return SDL_SCANCODE_E;
            case Action::ReadyWeapon:
                return SDL_SCANCODE_F;
            case Action::ReadyMagic:
                return SDL_SCANCODE_R;
            case Action::Pause:
                return SDL_SCANCODE_ESCAPE;
            case Action::Sneak:
                return SDL_SCANCODE_LCTRL;
            case Action::Journal:
                return SDL_SCANCODE_J;
            case Action::TogglePOV:
                return SDL_SCANCODE_TAB;
            case Action::QuickSave:
                return SDL_SCANCODE_F5;
            case Action::Wait:
                return SDL_SCANCODE_T;
            case Action::Attack:
            case Action::Inventory:
                return SDL_SCANCODE_UNKNOWN;
        }
        return SDL_SCANCODE_UNKNOWN;
    }

    NSString* labelForAction(Action action)
    {
        switch (action)
        {
            case Action::Activate:
                return @"USE";
            case Action::Attack:
                return @"ATK";
            case Action::Jump:
                return @"JMP";
            case Action::ReadyWeapon:
                return @"WPN";
            case Action::ReadyMagic:
                return @"MAG";
            case Action::Inventory:
                return @"INV";
            case Action::Pause:
                return @"MENU";
            case Action::Sneak:
                return @"SNK";
            case Action::Journal:
                return @"JRN";
            case Action::TogglePOV:
                return @"POV";
            case Action::QuickSave:
                return @"SAVE";
            case Action::Wait:
                return @"WAIT";
        }
        return @"?";
    }

    UIImage* imageForAction(Action action)
    {
        static std::array<UIImage*, OpenMWIOS::Touch::ActionCount> images;
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            using namespace OpenMWIOS::Touch::Icons;
            const auto png = [](const char* encoded) {
                NSString* string = [NSString stringWithUTF8String:encoded];
                NSData* data = [[NSData alloc] initWithBase64EncodedString:string options:0];
                return [UIImage imageWithData:data];
            };
            images[static_cast<std::size_t>(Action::Pause)] = png(icon1);
            images[static_cast<std::size_t>(Action::Attack)] = png(icon2);
            images[static_cast<std::size_t>(Action::Inventory)] = png(icon3);
            images[static_cast<std::size_t>(Action::Jump)] = png(icon4);
            images[static_cast<std::size_t>(Action::Activate)] = png(icon6);
            images[static_cast<std::size_t>(Action::ReadyWeapon)] = png(icon7);
            images[static_cast<std::size_t>(Action::ReadyMagic)] = png(icon8);
            images[static_cast<std::size_t>(Action::Sneak)] = png(icon9);
            images[static_cast<std::size_t>(Action::Journal)] = png(journalIcon);
            images[static_cast<std::size_t>(Action::TogglePOV)] = png(thirdPersonIcon);
            images[static_cast<std::size_t>(Action::QuickSave)] = png(saveIcon);
            images[static_cast<std::size_t>(Action::Wait)] = png(waitIcon);
        });
        return images[static_cast<std::size_t>(action)];
    }

    SDL_Window* currentSDLWindow()
    {
        SDL_Window* window = SDL_GetKeyboardFocus();
        if (!window)
            window = SDL_GetMouseFocus();
        return window;
    }

    Uint32 currentSDLWindowId()
    {
        SDL_Window* window = currentSDLWindow();
        return window ? SDL_GetWindowID(window) : 0;
    }

    void pushKey(SDL_Scancode scancode, bool down)
    {
        if (scancode == SDL_SCANCODE_UNKNOWN)
            return;
        SDL_Event event{};
        event.type = down ? SDL_KEYDOWN : SDL_KEYUP;
        event.key.timestamp = SDL_GetTicks();
        event.key.windowID = currentSDLWindowId();
        event.key.state = down ? SDL_PRESSED : SDL_RELEASED;
        event.key.repeat = 0;
        event.key.keysym.scancode = scancode;
        event.key.keysym.sym = SDL_GetKeyFromScancode(scancode);
        event.key.keysym.mod = KMOD_NONE;
        SDL_PushEvent(&event);
    }

    void pushRelativeMouse(float dx, float dy)
    {
        const int xrel = static_cast<int>(std::lround(dx * LookSensitivity));
        const int yrel = static_cast<int>(std::lround(dy * LookSensitivity));
        if (xrel == 0 && yrel == 0)
            return;

        int x = 0;
        int y = 0;
        SDL_GetMouseState(&x, &y);
        SDL_Event event{};
        event.type = SDL_MOUSEMOTION;
        event.motion.timestamp = SDL_GetTicks();
        event.motion.windowID = currentSDLWindowId();
        event.motion.which = 0;
        event.motion.state = 0;
        event.motion.x = x;
        event.motion.y = y;
        event.motion.xrel = xrel;
        event.motion.yrel = yrel;
        SDL_PushEvent(&event);
    }

    void pushMouseButton(Uint8 button, bool down)
    {
        int x = 0;
        int y = 0;
        SDL_GetMouseState(&x, &y);
        SDL_Event event{};
        event.type = down ? SDL_MOUSEBUTTONDOWN : SDL_MOUSEBUTTONUP;
        event.button.timestamp = SDL_GetTicks();
        event.button.windowID = currentSDLWindowId();
        event.button.which = 0;
        event.button.button = button;
        event.button.state = down ? SDL_PRESSED : SDL_RELEASED;
        event.button.clicks = down ? 1 : 0;
        event.button.x = x;
        event.button.y = y;
        SDL_PushEvent(&event);
    }

    UIWindow* gameplayWindow()
    {
        UIWindow* candidate = UIApplication.sharedApplication.keyWindow;
        if (candidate && !candidate.hidden && candidate.rootViewController)
            return candidate;

        if (@available(iOS 13.0, *))
        {
            for (UIScene* scene in UIApplication.sharedApplication.connectedScenes)
            {
                if (![scene isKindOfClass:UIWindowScene.class])
                    continue;
                UIWindowScene* windowScene = (UIWindowScene*)scene;
                for (UIWindow* window in windowScene.windows)
                {
                    if (window.isKeyWindow && !window.hidden && window.rootViewController)
                        return window;
                }
            }
        }
        return nil;
    }
}

@interface OpenMWTouchOverlay : UIView
@end

@implementation OpenMWTouchOverlay
{
    OpenMWIOS::Touch::Ownership _ownership;
    Layout _layout;
    SDL_GameController* _virtualController;
    SDL_Joystick* _virtualJoystick;
    int _virtualDeviceIndex;
    std::array<bool, OpenMWIOS::Touch::ActionCount> _pressedActions;
    std::array<bool, 4> _fallbackDirections;
    CADisplayLink* _displayLink;
    BOOL _gameplayMode;
    BOOL _inputReady;
    int _diagnosticBudget;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = UIColor.clearColor;
        self.opaque = NO;
        self.multipleTouchEnabled = YES;
        self.userInteractionEnabled = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _virtualController = nullptr;
        _virtualJoystick = nullptr;
        _virtualDeviceIndex = -1;
        _pressedActions.fill(false);
        _fallbackDirections.fill(false);
        _gameplayMode = NO;
        _inputReady = NO;
        _diagnosticBudget = DiagnosticBudget;
        [self rebuildLayout];

        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateInputMode:)];
        [_displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
        self.hidden = YES;
    }
    return self;
}

- (void)dealloc
{
    [_displayLink invalidate];
    [self releaseAllInputs];
    if (_virtualController)
    {
        SDL_GameControllerClose(_virtualController);
        _virtualController = nullptr;
        _virtualJoystick = nullptr;
    }
    if (_virtualDeviceIndex >= 0)
        SDL_JoystickDetachVirtual(_virtualDeviceIndex);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self rebuildLayout];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent*)event
{
    (void)event;
    if (!_inputReady)
        return NO;
    if (_gameplayMode)
        return YES;

    const OpenMWIOS::Touch::Point touchPoint{ static_cast<float>(point.x), static_cast<float>(point.y) };
    for (const auto& button : _layout.buttons)
    {
        if (OpenMWIOS::Touch::visibleInMode(button.action, false) && button.bounds.contains(touchPoint, 1.15f))
            return YES;
    }
    return NO;
}

- (void)rebuildLayout
{
    const UIEdgeInsets insets = self.safeAreaInsets;
    _layout = OpenMWIOS::Touch::makeLayout(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds),
        { static_cast<float>(insets.top), static_cast<float>(insets.left), static_cast<float>(insets.bottom),
            static_cast<float>(insets.right) });
    [self setNeedsDisplay];
}

- (void)diagnose:(const char*)milestone detail:(NSString*)detail
{
    if (_diagnosticBudget <= 0)
        return;
    --_diagnosticBudget;
    openmw_ios_log(milestone, detail.UTF8String);
}

- (void)updateInputMode:(CADisplayLink*)displayLink
{
    (void)displayLink;
    const BOOL inputReady = SDL_WasInit(SDL_INIT_VIDEO) != 0;
    const BOOL gameplayMode = inputReady && SDL_ShowCursor(SDL_QUERY) == SDL_DISABLE;
    if (inputReady == _inputReady && gameplayMode == _gameplayMode)
        return;

    const BOOL modeChanged = gameplayMode != _gameplayMode;
    _inputReady = inputReady;
    _gameplayMode = gameplayMode;
    if (modeChanged)
        [self releaseAllInputs];
    self.hidden = !_inputReady;
    [self setNeedsDisplay];
    [self diagnose:"touch_mode_transition"
             detail:_gameplayMode ? @"mode=gameplay;controls=android-set"
                                  : @"mode=gui;controls=inv,journal,menu;other_touches=passthrough"];
}

- (BOOL)ensureVirtualController
{
    if (_virtualJoystick)
        return YES;
    if ((SDL_WasInit(SDL_INIT_JOYSTICK) & SDL_INIT_JOYSTICK) == 0)
        return NO;

    SDL_VirtualJoystickDesc descriptor{};
    descriptor.version = SDL_VIRTUAL_JOYSTICK_DESC_VERSION;
    descriptor.type = SDL_JOYSTICK_TYPE_GAMECONTROLLER;
    descriptor.naxes = SDL_CONTROLLER_AXIS_MAX;
    descriptor.nbuttons = SDL_CONTROLLER_BUTTON_MAX;
    descriptor.nhats = 0;
    descriptor.axis_mask = (Uint32{ 1 } << SDL_CONTROLLER_AXIS_MAX) - 1u;
    descriptor.button_mask = (Uint32{ 1 } << SDL_CONTROLLER_BUTTON_MAX) - 1u;
    descriptor.name = "OpenMW iOS Touch Controller";

    _virtualDeviceIndex = SDL_JoystickAttachVirtualEx(&descriptor);
    if (_virtualDeviceIndex < 0)
    {
        [self diagnose:"touch_virtual_controller" detail:[NSString stringWithFormat:@"attach=failed;error=%s", SDL_GetError()]];
        return NO;
    }

    _virtualController = SDL_GameControllerOpen(_virtualDeviceIndex);
    if (!_virtualController)
    {
        [self diagnose:"touch_virtual_controller" detail:[NSString stringWithFormat:@"open=failed;error=%s", SDL_GetError()]];
        SDL_JoystickDetachVirtual(_virtualDeviceIndex);
        _virtualDeviceIndex = -1;
        return NO;
    }
    _virtualJoystick = SDL_GameControllerGetJoystick(_virtualController);

    [self diagnose:"touch_virtual_controller"
             detail:@"attached=yes;axes=leftx,lefty,triggers;buttons=a,b,x,y,start,leftstick,leftshoulder"];
    return YES;
}

- (void)setFallbackDirection:(std::size_t)index scancode:(SDL_Scancode)scancode pressed:(bool)pressed
{
    if (_fallbackDirections[index] == pressed)
        return;
    _fallbackDirections[index] = pressed;
    pushKey(scancode, pressed);
}

- (void)updateMovementFrom:(OpenMWIOS::Touch::Point)origin to:(OpenMWIOS::Touch::Point)point
{
    const auto vector = OpenMWIOS::Touch::movementVector(origin, _layout.movementRadius, point, MovementDeadZone);
    if ([self ensureVirtualController])
    {
        SDL_JoystickSetVirtualAxis(_virtualJoystick, SDL_CONTROLLER_AXIS_LEFTX,
            static_cast<Sint16>(std::lround(vector.x * static_cast<float>(SDL_JOYSTICK_AXIS_MAX))));
        SDL_JoystickSetVirtualAxis(_virtualJoystick, SDL_CONTROLLER_AXIS_LEFTY,
            static_cast<Sint16>(std::lround(vector.y * static_cast<float>(SDL_JOYSTICK_AXIS_MAX))));
    }
    else
    {
        constexpr float DigitalThreshold = 0.35f;
        [self setFallbackDirection:0 scancode:SDL_SCANCODE_W pressed:vector.y < -DigitalThreshold];
        [self setFallbackDirection:1 scancode:SDL_SCANCODE_S pressed:vector.y > DigitalThreshold];
        [self setFallbackDirection:2 scancode:SDL_SCANCODE_A pressed:vector.x < -DigitalThreshold];
        [self setFallbackDirection:3 scancode:SDL_SCANCODE_D pressed:vector.x > DigitalThreshold];
    }
    [self setNeedsDisplay];
}

- (void)releaseMovement
{
    if (_virtualJoystick)
    {
        SDL_JoystickSetVirtualAxis(_virtualJoystick, SDL_CONTROLLER_AXIS_LEFTX, 0);
        SDL_JoystickSetVirtualAxis(_virtualJoystick, SDL_CONTROLLER_AXIS_LEFTY, 0);
    }
    [self setFallbackDirection:0 scancode:SDL_SCANCODE_W pressed:false];
    [self setFallbackDirection:1 scancode:SDL_SCANCODE_S pressed:false];
    [self setFallbackDirection:2 scancode:SDL_SCANCODE_A pressed:false];
    [self setFallbackDirection:3 scancode:SDL_SCANCODE_D pressed:false];
    [self setNeedsDisplay];
}

- (void)setAction:(Action)action pressed:(bool)pressed
{
    const std::size_t index = static_cast<std::size_t>(action);
    if (_pressedActions[index] == pressed)
        return;
    _pressedActions[index] = pressed;

    BOOL dispatched = NO;
    if ([self ensureVirtualController])
    {
        const int button = controllerButtonForAction(action);
        const int axis = controllerAxisForAction(action);
        if (button >= 0)
        {
            SDL_JoystickSetVirtualButton(_virtualJoystick, button, pressed ? SDL_PRESSED : SDL_RELEASED);
            dispatched = YES;
        }
        else if (axis >= 0)
        {
            SDL_JoystickSetVirtualAxis(_virtualJoystick, axis, pressed ? SDL_JOYSTICK_AXIS_MAX : 0);
            dispatched = YES;
        }
    }
    if (!dispatched)
    {
        if (action == Action::Attack)
            pushMouseButton(SDL_BUTTON_LEFT, pressed);
        else if (action == Action::Inventory)
            pushMouseButton(SDL_BUTTON_RIGHT, pressed);
        else
            pushKey(fallbackScancodeForAction(action), pressed);
    }

    [self diagnose:"touch_action_dispatch"
             detail:[NSString stringWithFormat:@"action=%@;pressed=%@;path=%@", labelForAction(action),
                         pressed ? @"yes" : @"no", _virtualJoystick ? @"virtual-controller" : @"fallback"]];
    [self setNeedsDisplay];
}

- (void)releaseAllInputs
{
    for (const auto& [identifier, binding] : _ownership.bindings())
    {
        (void)identifier;
        if (binding.role == Role::Button && binding.action)
            [self setAction:*binding.action pressed:false];
    }
    _ownership.clear();
    [self releaseMovement];
    for (std::size_t index = 0; index < _pressedActions.size(); ++index)
    {
        if (_pressedActions[index])
            [self setAction:static_cast<Action>(index) pressed:false];
    }
}

- (void)touchesBegan:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event
{
    (void)event;
    for (UITouch* touch in touches)
    {
        const CGPoint location = [touch locationInView:self];
        const OpenMWIOS::Touch::Point point{ static_cast<float>(location.x), static_cast<float>(location.y) };
        const auto binding = _ownership.begin(touchId(touch), point, _layout, _gameplayMode);
        if (!binding)
            continue;

        if (binding->role == Role::Movement)
        {
            [self updateMovementFrom:binding->startPoint to:point];
            const auto vector = OpenMWIOS::Touch::movementVector(
                binding->startPoint, _layout.movementRadius, point, MovementDeadZone);
            [self diagnose:"touch_movement_acquired"
                     detail:[NSString stringWithFormat:@"id=%llu;vector=%.3f,%.3f;magnitude=%.3f",
                                 static_cast<unsigned long long>(touchId(touch)), vector.x, vector.y, vector.magnitude]];
        }
        else if (binding->role == Role::Look)
        {
            [self diagnose:"touch_look_acquired"
                     detail:[NSString stringWithFormat:@"id=%llu", static_cast<unsigned long long>(touchId(touch))]];
        }
        else if (binding->role == Role::Button && binding->action)
        {
            [self setAction:*binding->action pressed:true];
            [self diagnose:"touch_action_pressed"
                     detail:[NSString stringWithFormat:@"id=%llu;action=%@",
                                 static_cast<unsigned long long>(touchId(touch)), labelForAction(*binding->action)]];
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event
{
    (void)event;
    for (UITouch* touch in touches)
    {
        const CGPoint location = [touch locationInView:self];
        const OpenMWIOS::Touch::Point point{ static_cast<float>(location.x), static_cast<float>(location.y) };
        const auto previous = _ownership.move(touchId(touch), point);
        if (!previous)
            continue;
        if (previous->role == Role::Movement)
            [self updateMovementFrom:previous->startPoint to:point];
        else if (previous->role == Role::Look)
        {
            const float dx = point.x - previous->lastPoint.x;
            const float dy = point.y - previous->lastPoint.y;
            pushRelativeMouse(dx, dy);
            [self diagnose:"touch_look_delta"
                     detail:[NSString stringWithFormat:@"id=%llu;delta=%.2f,%.2f",
                                 static_cast<unsigned long long>(touchId(touch)), dx, dy]];
        }
    }
}

- (void)finishTouches:(NSSet<UITouch*>*)touches cancelled:(BOOL)cancelled
{
    for (UITouch* touch in touches)
    {
        const auto binding = _ownership.end(touchId(touch));
        if (!binding)
            continue;
        if (binding->role == Role::Movement)
        {
            [self releaseMovement];
            [self diagnose:"touch_movement_released" detail:cancelled ? @"cancelled=yes" : @"cancelled=no"];
        }
        else if (binding->role == Role::Look)
            [self diagnose:"touch_look_released" detail:cancelled ? @"cancelled=yes" : @"cancelled=no"];
        else if (binding->role == Role::Button && binding->action)
        {
            [self setAction:*binding->action pressed:false];
            [self diagnose:"touch_action_released"
                     detail:[NSString stringWithFormat:@"action=%@;cancelled=%@", labelForAction(*binding->action),
                                 cancelled ? @"yes" : @"no"]];
        }
    }
}

- (void)touchesEnded:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event
{
    (void)event;
    [self finishTouches:touches cancelled:NO];
}

- (void)touchesCancelled:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event
{
    (void)event;
    [self finishTouches:touches cancelled:YES];
}

- (void)drawRect:(CGRect)rect
{
    (void)rect;
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context)
        return;

    CGContextSaveGState(context);
    CGContextSetLineWidth(context, 2.f);
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:1.f alpha:0.6f].CGColor);
    CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:0.f alpha:0.24f].CGColor);

    const auto drawCircle = [&](const OpenMWIOS::Touch::Circle& circle, bool filled) {
        const CGRect circleRect = CGRectMake(circle.center.x - circle.radius, circle.center.y - circle.radius,
            circle.radius * 2.f, circle.radius * 2.f);
        if (filled)
            CGContextFillEllipseInRect(context, circleRect);
        CGContextStrokeEllipseInRect(context, circleRect);
    };

    if (_gameplayMode)
    {
        for (const auto& [identifier, binding] : _ownership.bindings())
        {
            (void)identifier;
            if (binding.role == Role::Movement)
            {
                const OpenMWIOS::Touch::Circle dynamicBase{ binding.startPoint, _layout.movementRadius };
                drawCircle(dynamicBase, false);
                const auto vector = OpenMWIOS::Touch::movementVector(
                    binding.startPoint, _layout.movementRadius, binding.lastPoint, 0.f);
                OpenMWIOS::Touch::Point knob = binding.startPoint;
                knob.x += vector.x * _layout.movementRadius * 0.58f;
                knob.y += vector.y * _layout.movementRadius * 0.58f;
                drawCircle({ knob, _layout.movementRadius * 0.28f }, true);
                break;
            }
        }
    }

    NSDictionary<NSAttributedStringKey, id>* attributes = @{
        NSFontAttributeName : [UIFont boldSystemFontOfSize:12.f],
        NSForegroundColorAttributeName : UIColor.whiteColor,
    };
    for (const auto& button : _layout.buttons)
    {
        if (!OpenMWIOS::Touch::visibleInMode(button.action, _gameplayMode))
            continue;
        const bool pressed = _pressedActions[static_cast<std::size_t>(button.action)];
        UIImage* icon = imageForAction(button.action);
        const CGRect iconRect = CGRectMake(button.bounds.center.x - button.bounds.radius,
            button.bounds.center.y - button.bounds.radius, button.bounds.radius * 2.f, button.bounds.radius * 2.f);
        if (icon)
        {
            CGContextSaveGState(context);
            CGContextSetAlpha(context, pressed ? 0.95f : 0.64f);
            UIImage* tinted = [icon imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
            [tinted drawInRect:iconRect blendMode:kCGBlendModeNormal alpha:1.f];
            CGContextRestoreGState(context);
        }
        else
        {
            NSString* label = labelForAction(button.action);
            const CGSize size = [label sizeWithAttributes:attributes];
            const CGPoint origin = CGPointMake(button.bounds.center.x - size.width * 0.5f,
                button.bounds.center.y - size.height * 0.5f);
            [label drawAtPoint:origin withAttributes:attributes];
        }
    }
    CGContextRestoreGState(context);
}

@end

namespace
{
    OpenMWTouchOverlay* sTouchOverlay = nil;
    int sInstallAttempts = 0;

    void attemptTouchInstall()
    {
        if (sTouchOverlay.superview)
            return;

        UIWindow* window = gameplayWindow();
        UIView* host = window.rootViewController.view;
        if (!host || CGRectIsEmpty(host.bounds))
        {
            if (++sInstallAttempts <= 120)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, static_cast<int64_t>(0.1 * NSEC_PER_SEC)),
                    dispatch_get_main_queue(), ^{ attemptTouchInstall(); });
            }
            else
                openmw_ios_log("touch_overlay_install", "result=failed;reason=no-gameplay-window");
            return;
        }

        UIView* existing = [host viewWithTag:TouchOverlayTag];
        if ([existing isKindOfClass:OpenMWTouchOverlay.class])
        {
            sTouchOverlay = (OpenMWTouchOverlay*)existing;
            return;
        }

        sTouchOverlay = [[OpenMWTouchOverlay alloc] initWithFrame:host.bounds];
        sTouchOverlay.tag = TouchOverlayTag;
        [host addSubview:sTouchOverlay];
        [host bringSubviewToFront:sTouchOverlay];
        const UIEdgeInsets safe = host.safeAreaInsets;
        NSString* detail = [NSString stringWithFormat:
            @"result=installed;bounds=%.0fx%.0f;safe_area=%.0f,%.0f,%.0f,%.0f;android_reference=2.7.4",
            CGRectGetWidth(host.bounds), CGRectGetHeight(host.bounds), safe.top, safe.left, safe.bottom, safe.right];
        openmw_ios_log("touch_overlay_install", detail.UTF8String);
    }
}

extern "C" void openmw_ios_install_touch_controls(void)
{
    dispatch_async(dispatch_get_main_queue(), ^{ attemptTouchInstall(); });
}
