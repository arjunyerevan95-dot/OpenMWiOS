#import <UIKit/UIKit.h>

@interface OpenMWProbeAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow* window;
@end

@implementation OpenMWProbeAppDelegate

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    (void)application;
    (void)launchOptions;

    UIViewController* viewController = [[UIViewController alloc] init];
    viewController.view.backgroundColor = [UIColor whiteColor];

    UILabel* label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = @"OpenMW iOS Bundle Probe";
    label.textColor = [UIColor blackColor];
    label.font = [UIFont systemFontOfSize:24.0 weight:UIFontWeightSemibold];
    label.textAlignment = NSTextAlignmentCenter;

    [viewController.view addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:viewController.view.centerXAnchor],
        [label.centerYAnchor constraintEqualToAnchor:viewController.view.centerYAnchor],
        [label.leadingAnchor constraintGreaterThanOrEqualToAnchor:viewController.view.leadingAnchor
                                                         constant:24.0],
        [label.trailingAnchor constraintLessThanOrEqualToAnchor:viewController.view.trailingAnchor
                                                        constant:-24.0],
    ]];

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = viewController;
    [self.window makeKeyAndVisible];

    return YES;
}

@end

int main(int argc, char* argv[])
{
    @autoreleasepool
    {
        return UIApplicationMain(
            argc,
            argv,
            nil,
            NSStringFromClass([OpenMWProbeAppDelegate class]));
    }
}
