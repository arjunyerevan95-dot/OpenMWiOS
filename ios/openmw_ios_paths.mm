#import "openmw_ios_paths.h"

#import <Foundation/Foundation.h>

namespace
{
    const char* copyPath(NSSearchPathDirectory directory)
    {
        NSArray<NSString*>* paths = NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES);
        NSString* path = paths.firstObject;
        return path ? strdup(path.fileSystemRepresentation) : nullptr;
    }
}

const char* openmw_ios_documents_path(void)
{
    static const char* path = copyPath(NSDocumentDirectory);
    return path;
}

const char* openmw_ios_library_path(void)
{
    static const char* path = copyPath(NSLibraryDirectory);
    return path;
}

const char* openmw_ios_bundle_path(void)
{
    static const char* path = strdup(NSBundle.mainBundle.bundlePath.fileSystemRepresentation);
    return path;
}

