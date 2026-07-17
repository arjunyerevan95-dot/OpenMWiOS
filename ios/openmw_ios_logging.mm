#import "openmw_ios_logging.h"

#import <Foundation/Foundation.h>

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
        NSDictionary* record = ${
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
