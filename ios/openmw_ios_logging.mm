#import "openmw_ios_logging.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

namespace
{
    NSString* startupLogPath()
    {
        NSURL* library = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory
                                                                 inDomains:NSUserDomainMask] firstObject];
        NSURL* directory = [library URLByAppendingPathComponent:@"OpenMW" isDirectory:YES];
        [[NSFileManager defaultManager] createDirectoryAtURL:directory
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:nil];
        return [[directory URLByAppendingPathComponent:@"startup.jsonl"] path];
    }
}

extern "C" void openmw_ios_log(const char* milestone, const char* detail)
{
    @autoreleasepool
    {
        NSDictionary* record = @{
            @"timestamp" : [[NSDate date] description],
            @"milestone" : milestone ? [NSString stringWithUTF8String:milestone] : @"unknown",
            @"detail" : detail ? [NSString stringWithUTF8String:detail] : @""
        };
        NSError* error = nil;
        NSData* json = [NSJSONSerialization dataWithJSONObject:record options:0 error:&error];
        if (!json || error)
            return;

        NSMutableData* line = [NSMutableData dataWithData:json];
        const unsigned char newline = '\n';
        [line appendBytes:&newline length:1];

        NSString* path = startupLogPath();
        NSFileManager* manager = [NSFileManager defaultManager];
        if (![manager fileExistsAtPath:path])
            [manager createFileAtPath:path contents:nil attributes:nil];
        NSFileHandle* handle = [NSFileHandle fileHandleForWritingAtPath:path];
        [handle seekToEndOfFile];
        [handle writeData:line];
        [handle synchronizeFile];
        [handle closeFile];
    }
}

extern "C" void openmw_ios_log_fatal(const char* detail)
{
    openmw_ios_log("fatal", detail);
}

extern "C" void openmw_ios_log_view_metrics(const char* milestone)
{
    @autoreleasepool
    {
        UIWindow* window = nil;
        if (@available(iOS 13.0, *))
        {
            for (UIScene* scene in UIApplication.sharedApplication.connectedScenes)
            {
                if (scene.activationState != UISceneActivationStateUnattached
                    && [scene isKindOfClass:UIWindowScene.class])
                {
                    UIWindowScene* windowScene = (UIWindowScene*)scene;
                    window = windowScene.windows.firstObject;
                    if (window)
                        break;
                }
            }
        }
        if (!window)
            window = UIApplication.sharedApplication.keyWindow;

        UIView* view = window.rootViewController.view;
        UIScreen* screen = window.screen ?: UIScreen.mainScreen;
        if (!view)
        {
            openmw_ios_log(milestone, "view=unavailable");
            return;
        }

        const CGRect bounds = view.bounds;
        const UIEdgeInsets safeArea = view.safeAreaInsets;
        NSInteger orientation = 0;
        if (@available(iOS 13.0, *))
            orientation = window.windowScene.interfaceOrientation;
        NSString* metrics = [NSString stringWithFormat:
            @"view_class=%@;bounds=%.0fx%.0f;content_scale=%.3f;screen_scale=%.3f;native_scale=%.3f;safe_area=%.0f,%.0f,%.0f,%.0f;orientation=%ld",
            NSStringFromClass(view.class), CGRectGetWidth(bounds), CGRectGetHeight(bounds), view.contentScaleFactor,
            screen.scale, screen.nativeScale, safeArea.top, safeArea.left, safeArea.bottom, safeArea.right,
            (long)orientation];
        openmw_ios_log(milestone, metrics.UTF8String);
    }
}
