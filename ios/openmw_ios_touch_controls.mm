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
    using OpenMWIOS::Touch::ControlProfile;
    using OpenMWIOS::Touch::Layout;
    using OpenMWIOS::Touch::Role;

    constexpr CGFloat TouchOverlayTag = 0x4f4d5754; // OMWT
    constexpr float MovementDeadZone = 0.2f;
    constexpr float LookSensitivity = 1.25f;
    constexpr int DiagnosticBudget = 48;
    constexpr NSTimeInterval MenuLongPressSeconds = 0.75;
    constexpr CGFloat EditorTouchSlop = 14.f;
    NSString* const TouchProfileDefaultsKey = @"OpenMWIOSTouchProfileV1";

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
                // This Objective-C++ source is compiled without ARC. The process-lifetime
                // icon cache must own each image after the surrounding autorelease pool drains.
                UIImage* image = [[UIImage alloc] initWithData:data];
                [data release];
                return image;
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
    ControlProfile _profile;
    ControlProfile _editorSnapshot;
    BOOL _editing;
    NSInteger _selectedControl;
    std::uintptr_t _editorTouchId;
    BOOL _editorResizing;
    OpenMWIOS::Touch::Point _editorLastPoint;
    std::uintptr_t _pendingMenuTouchId;
    std::uintptr_t _consumedMenuLongPressId;
    OpenMWIOS::Touch::Point _pendingMenuStart;
    BOOL _resetArmed;
    BOOL _resetApplied;
    ControlProfile _preResetProfile;
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
        _editing = NO;
        _selectedControl = -1;
        _editorTouchId = 0;
        _editorResizing = NO;
        _pendingMenuTouchId = 0;
        _consumedMenuLongPressId = 0;
        _resetArmed = NO;
        _resetApplied = NO;
        [self rebuildLayout];
        [self loadProfile];

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
    if (_editing)
        [self captureLayoutIntoProfile];
    [self rebuildLayout];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent*)event
{
    (void)event;
    if (!_inputReady)
        return NO;
    if (_editing)
        return YES;
    if (_gameplayMode && !_editing)
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
    OpenMWIOS::Touch::applyProfile(_layout, _profile);
    [self setNeedsDisplay];
}

- (void)loadProfile
{
    _profile = OpenMWIOS::Touch::profileFromLayout(_layout);
    NSDictionary* stored = [NSUserDefaults.standardUserDefaults dictionaryForKey:TouchProfileDefaultsKey];
    if (![stored isKindOfClass:NSDictionary.class]
        || [stored[@"version"] unsignedIntValue] != OpenMWIOS::Touch::ProfileVersion)
        return;

    NSArray* controls = stored[@"controls"];
    if (![controls isKindOfClass:NSArray.class] || controls.count != OpenMWIOS::Touch::ActionCount)
        return;
    _profile.version = OpenMWIOS::Touch::ProfileVersion;
    _profile.customized = YES;
    _profile.idleOpacity = OpenMWIOS::Touch::clamp([stored[@"opacity"] floatValue], 0.05f, 0.85f);
    _profile.movementRadius = [stored[@"movementRadius"] floatValue];
    for (std::size_t index = 0; index < OpenMWIOS::Touch::ActionCount; ++index)
    {
        NSDictionary* item = controls[index];
        if (![item isKindOfClass:NSDictionary.class])
        {
            _profile.customized = false;
            return;
        }
        _profile.buttons[index].center = { [item[@"x"] floatValue], [item[@"y"] floatValue] };
        _profile.buttons[index].radius = [item[@"radius"] floatValue];
    }
    [self rebuildLayout];
}

- (void)captureLayoutIntoProfile
{
    _profile.version = OpenMWIOS::Touch::ProfileVersion;
    _profile.customized = true;
    _profile.movementRadius = _layout.movementRadius / OpenMWIOS::Touch::safeShortSide(_layout);
    for (std::size_t index = 0; index < OpenMWIOS::Touch::ActionCount; ++index)
        OpenMWIOS::Touch::updateProfileButton(_profile, _layout, index);
}

- (void)saveProfile
{
    [self captureLayoutIntoProfile];
    NSMutableArray* controls = [NSMutableArray arrayWithCapacity:OpenMWIOS::Touch::ActionCount];
    for (const auto& control : _profile.buttons)
    {
        [controls addObject:@{
            @"x" : @(control.center.x),
            @"y" : @(control.center.y),
            @"radius" : @(control.radius),
        }];
    }
    NSDictionary* stored = @{
        @"version" : @(OpenMWIOS::Touch::ProfileVersion),
        @"opacity" : @(_profile.idleOpacity),
        @"movementRadius" : @(_profile.movementRadius),
        @"controls" : controls,
    };
    [NSUserDefaults.standardUserDefaults setObject:stored forKey:TouchProfileDefaultsKey];
}

- (CGRect)editorToolbarRect
{
    const CGFloat width = MIN(CGRectGetWidth(self.bounds) - self.safeAreaInsets.left - self.safeAreaInsets.right - 24.f, 460.f);
    return CGRectMake(CGRectGetMidX(self.bounds) - width * 0.5f,
        CGRectGetHeight(self.bounds) - self.safeAreaInsets.bottom - 54.f, width, 42.f);
}

- (OpenMWIOS::Touch::Circle)editorMovementPreview
{
    const float radius = _layout.movementRadius;
    return { { _layout.safeArea.left + radius + 18.f,
                 _layout.height - _layout.safeArea.bottom - radius - 70.f },
        radius };
}

- (NSInteger)editorToolbarItemAtPoint:(CGPoint)point
{
    const CGRect toolbar = [self editorToolbarRect];
    if (!CGRectContainsPoint(toolbar, point))
        return -1;
    const CGFloat itemWidth = CGRectGetWidth(toolbar) / 5.f;
    return MIN(4, MAX(0, static_cast<NSInteger>((point.x - CGRectGetMinX(toolbar)) / itemWidth)));
}

- (void)enterEditor
{
    const std::uintptr_t triggeringTouch = _pendingMenuTouchId;
    [self releaseAllInputs];
    _consumedMenuLongPressId = triggeringTouch;
    _editorSnapshot = _profile.customized ? _profile : OpenMWIOS::Touch::profileFromLayout(_layout);
    _editing = YES;
    _selectedControl = static_cast<NSInteger>(Action::Pause);
    _resetArmed = NO;
    _resetApplied = NO;
    [self diagnose:"touch_editor" detail:@"state=entered;trigger=menu-long-press;input=suppressed"];
    [self setNeedsDisplay];
}

- (void)leaveEditorSaving:(BOOL)save
{
    if (save)
        [self saveProfile];
    else
    {
        _profile = _editorSnapshot;
        [self rebuildLayout];
    }
    _editing = NO;
    _selectedControl = -1;
    _editorTouchId = 0;
    _resetArmed = NO;
    _resetApplied = NO;
    [self diagnose:"touch_editor" detail:save ? @"state=done;profile=saved" : @"state=cancelled;profile=restored"];
    [self setNeedsDisplay];
}

- (void)resetEditorLayout
{
    const float opacity = _profile.idleOpacity;
    _layout = OpenMWIOS::Touch::makeLayout(_layout.width, _layout.height, _layout.safeArea);
    _profile = OpenMWIOS::Touch::profileFromLayout(_layout);
    _profile.idleOpacity = opacity;
    [self setNeedsDisplay];
}

- (void)activateEditorToolbarItem:(NSInteger)item
{
    switch (item)
    {
        case 0:
            _profile.idleOpacity = OpenMWIOS::Touch::clamp(_profile.idleOpacity - 0.05f, 0.05f, 0.85f);
            break;
        case 1:
            _profile.idleOpacity = OpenMWIOS::Touch::clamp(_profile.idleOpacity + 0.05f, 0.05f, 0.85f);
            break;
        case 2:
            [self leaveEditorSaving:YES];
            return;
        case 3:
            if (_resetApplied)
            {
                _profile = _preResetProfile;
                [self rebuildLayout];
                _resetApplied = NO;
                _resetArmed = NO;
            }
            else if (_resetArmed)
            {
                [self captureLayoutIntoProfile];
                _preResetProfile = _profile;
                [self resetEditorLayout];
                _resetApplied = YES;
                _resetArmed = NO;
            }
            else
                _resetArmed = YES;
            break;
        case 4:
            [self leaveEditorSaving:NO];
            return;
    }
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
    _pendingMenuTouchId = 0;
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

        if (_editing)
        {
            if (touchId(touch) == _consumedMenuLongPressId)
                continue;
            const NSInteger toolbarItem = [self editorToolbarItemAtPoint:location];
            if (toolbarItem >= 0)
            {
                [self activateEditorToolbarItem:toolbarItem];
                continue;
            }

            const auto movementPreview = [self editorMovementPreview];
            if (movementPreview.contains(point, 1.15f))
            {
                _selectedControl = OpenMWIOS::Touch::ActionCount;
                _editorTouchId = touchId(touch);
                _editorResizing = YES;
                _editorLastPoint = point;
                continue;
            }
            for (std::size_t index = 0; index < OpenMWIOS::Touch::ActionCount; ++index)
            {
                const auto& circle = _layout.buttons[index].bounds;
                if (!circle.contains(point, 1.25f))
                    continue;
                _selectedControl = static_cast<NSInteger>(index);
                _editorTouchId = touchId(touch);
                const float distance = std::hypot(point.x - circle.center.x, point.y - circle.center.y);
                _editorResizing = distance >= circle.radius * 0.68f;
                _editorLastPoint = point;
                break;
            }
            [self setNeedsDisplay];
            continue;
        }

        for (const auto& button : _layout.buttons)
        {
            if (button.action != Action::Pause || !OpenMWIOS::Touch::visibleInMode(button.action, _gameplayMode)
                || !button.bounds.contains(point, 1.15f) || _pendingMenuTouchId != 0)
                continue;
            _pendingMenuTouchId = touchId(touch);
            _pendingMenuStart = point;
            const std::uintptr_t candidate = _pendingMenuTouchId;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                               static_cast<int64_t>(MenuLongPressSeconds * NSEC_PER_SEC)),
                dispatch_get_main_queue(), ^{
                    if (_pendingMenuTouchId == candidate && !_editing)
                        [self enterEditor];
                });
            [self diagnose:"touch_menu_arbitration" detail:@"state=pending;pause_event=deferred"];
            break;
        }
        if (_pendingMenuTouchId == touchId(touch))
            continue;

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
        if (_editing)
        {
            if (touchId(touch) == _consumedMenuLongPressId || touchId(touch) != _editorTouchId)
                continue;
            if (_selectedControl == static_cast<NSInteger>(OpenMWIOS::Touch::ActionCount))
            {
                const auto preview = [self editorMovementPreview];
                _layout.movementRadius = OpenMWIOS::Touch::clamp(
                    std::hypot(point.x - preview.center.x, point.y - preview.center.y), 36.f,
                    OpenMWIOS::Touch::safeShortSide(_layout) * 0.24f);
            }
            else if (_selectedControl >= 0
                && _selectedControl < static_cast<NSInteger>(OpenMWIOS::Touch::ActionCount))
            {
                auto& circle = _layout.buttons[static_cast<std::size_t>(_selectedControl)].bounds;
                if (_editorResizing)
                    circle.radius = std::hypot(point.x - circle.center.x, point.y - circle.center.y);
                else
                {
                    circle.center.x += point.x - _editorLastPoint.x;
                    circle.center.y += point.y - _editorLastPoint.y;
                }
                const float minimum = _layout.buttons[static_cast<std::size_t>(_selectedControl)].action == Action::Pause
                    ? 24.f
                    : 18.f;
                OpenMWIOS::Touch::clampCircleToSafeArea(circle, _layout, minimum);
            }
            _editorLastPoint = point;
            _resetArmed = NO;
            _resetApplied = NO;
            [self setNeedsDisplay];
            continue;
        }
        if (touchId(touch) == _pendingMenuTouchId)
        {
            if (std::hypot(point.x - _pendingMenuStart.x, point.y - _pendingMenuStart.y) > EditorTouchSlop)
            {
                _pendingMenuTouchId = 0;
                [self diagnose:"touch_menu_arbitration" detail:@"state=cancelled;reason=movement"];
            }
            continue;
        }
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
        const std::uintptr_t identifier = touchId(touch);
        if (identifier == _consumedMenuLongPressId)
        {
            _consumedMenuLongPressId = 0;
            continue;
        }
        if (_editing && identifier == _editorTouchId)
        {
            _editorTouchId = 0;
            _editorResizing = NO;
            continue;
        }
        if (identifier == _pendingMenuTouchId)
        {
            _pendingMenuTouchId = 0;
            if (!cancelled)
            {
                [self setAction:Action::Pause pressed:true];
                [self setAction:Action::Pause pressed:false];
                [self diagnose:"touch_menu_arbitration" detail:@"state=short-tap;pause_event=dispatched"];
            }
            continue;
        }
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
        if (!_editing && !OpenMWIOS::Touch::visibleInMode(button.action, _gameplayMode))
            continue;
        const bool pressed = _pressedActions[static_cast<std::size_t>(button.action)];
        UIImage* icon = imageForAction(button.action);
        const CGRect iconRect = CGRectMake(button.bounds.center.x - button.bounds.radius,
            button.bounds.center.y - button.bounds.radius, button.bounds.radius * 2.f, button.bounds.radius * 2.f);
        if (icon)
        {
            CGContextSaveGState(context);
            const CGFloat alpha = _editing ? 0.82f : (pressed ? MIN(0.92f, _profile.idleOpacity + 0.42f)
                                                            : _profile.idleOpacity);
            CGContextSetAlpha(context, alpha);
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

    if (_editing)
    {
        CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:0.25f green:0.85f blue:1.f alpha:0.95f].CGColor);
        CGContextSetLineWidth(context, 3.f);
        const auto movement = [self editorMovementPreview];
        drawCircle(movement, false);

        if (_selectedControl >= 0)
        {
            OpenMWIOS::Touch::Circle selected = movement;
            NSString* selectedName = @"MOVE RADIUS";
            if (_selectedControl < static_cast<NSInteger>(OpenMWIOS::Touch::ActionCount))
            {
                const auto& button = _layout.buttons[static_cast<std::size_t>(_selectedControl)];
                selected = button.bounds;
                selectedName = labelForAction(button.action);
            }
            drawCircle({ selected.center, selected.radius + 7.f }, false);
            CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0.25f green:0.85f blue:1.f alpha:0.95f].CGColor);
            CGContextFillEllipseInRect(context, CGRectMake(selected.center.x + selected.radius - 7.f,
                                                       selected.center.y - 7.f, 14.f, 14.f));
            NSDictionary* selectedAttributes = @{
                NSFontAttributeName : [UIFont boldSystemFontOfSize:13.f],
                NSForegroundColorAttributeName : UIColor.whiteColor,
            };
            [selectedName drawAtPoint:CGPointMake(selected.center.x - selected.radius,
                                          selected.center.y - selected.radius - 25.f)
                         withAttributes:selectedAttributes];
        }

        const CGRect toolbar = [self editorToolbarRect];
        UIBezierPath* toolbarPath = [UIBezierPath bezierPathWithRoundedRect:toolbar cornerRadius:10.f];
        [[UIColor colorWithWhite:0.05f alpha:0.88f] setFill];
        [toolbarPath fill];
        NSArray<NSString*>* titles = @[
            @"OPACITY -",
            @"OPACITY +",
            @"DONE",
            _resetApplied ? @"UNDO" : (_resetArmed ? @"RESET?" : @"RESET"),
            @"CANCEL",
        ];
        const CGFloat itemWidth = CGRectGetWidth(toolbar) / titles.count;
        NSDictionary* toolbarAttributes = @{
            NSFontAttributeName : [UIFont boldSystemFontOfSize:11.f],
            NSForegroundColorAttributeName : UIColor.whiteColor,
        };
        for (NSUInteger index = 0; index < titles.count; ++index)
        {
            NSString* title = titles[index];
            const CGSize size = [title sizeWithAttributes:toolbarAttributes];
            [title drawAtPoint:CGPointMake(CGRectGetMinX(toolbar) + itemWidth * index + (itemWidth - size.width) * 0.5f,
                                   CGRectGetMidY(toolbar) - size.height * 0.5f)
                    withAttributes:toolbarAttributes];
        }
        NSString* help = @"Drag a control to move. Drag its edge dot to resize. Long-press MENU to edit.";
        NSDictionary* helpAttributes = @{
            NSFontAttributeName : [UIFont systemFontOfSize:12.f],
            NSForegroundColorAttributeName : [UIColor colorWithWhite:1.f alpha:0.9f],
        };
        const CGSize helpSize = [help sizeWithAttributes:helpAttributes];
        [help drawAtPoint:CGPointMake(CGRectGetMidX(self.bounds) - helpSize.width * 0.5f,
                              CGRectGetMinY(toolbar) - helpSize.height - 8.f)
              withAttributes:helpAttributes];
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
