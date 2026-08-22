#import "openmw_ios_renderer_diagnostics.h"

#import "openmw_ios_paths.h"

#import <Foundation/Foundation.h>

#include <atomic>
#include <cstdio>
#include <cstdlib>
#include <mutex>
#include <string>
#include <unordered_map>

namespace
{
    constexpr unsigned long long MaxFileBytes = 256 * 1024;

    struct FamilyState
    {
        unsigned int count = 0;
        unsigned int budget = 0;
        bool exhausted = false;
    };

    std::mutex sMutex;
    bool sStarted = false;
    bool sEnabled = false;
    unsigned long long sBytes = 0;
    uint32_t sNextSample = 1;
    NSString* sPath = nil;
    NSString* sSession = nil;
    std::unordered_map<std::string, FamilyState> sFamilies;
    std::unordered_map<uint64_t, int> sTextureCategories;

    unsigned int budgetForFamily(const std::string& family)
    {
        if (family == "session")
            return 2;
        if (family.rfind("r1.asset", 0) == 0)
            return 48;
        if (family.rfind("r1.upload", 0) == 0)
            return 48;
        if (family.rfind("r1.draw", 0) == 0)
            return 96;
        if (family.rfind("r1.state", 0) == 0)
            return 48;
        if (family.rfind("r2.intent", 0) == 0)
            return 16;
        if (family.rfind("r2.received", 0) == 0)
            return 32;
        if (family.rfind("r2.applied", 0) == 0)
            return 32;
        if (family == "summary")
            return 8;
        return 8;
    }

    NSString* safeString(const char* value)
    {
        if (!value)
            return @"";
        NSString* result = [NSString stringWithUTF8String:value];
        return result ?: @"<invalid-utf8>";
    }

    bool appendRecord(NSDictionary* record)
    {
        NSError* error = nil;
        NSData* json = [NSJSONSerialization dataWithJSONObject:record options:0 error:&error];
        if (!json || error)
            return false;
        NSMutableData* line = [NSMutableData dataWithData:json];
        const unsigned char newline = '\n';
        [line appendBytes:&newline length:1];
        if (sBytes + line.length > MaxFileBytes)
            return false;
        NSFileHandle* handle = [NSFileHandle fileHandleForWritingAtPath:sPath];
        if (!handle)
            return false;
        [handle seekToEndOfFile];
        [handle writeData:line];
        [handle closeFile];
        sBytes += line.length;
        return true;
    }

    void beginLocked()
    {
        if (sStarted)
            return;
        sStarted = true;
        const char* enabled = std::getenv("OPENMW_IOS_RENDERER_DIAGNOSTICS");
        sEnabled = enabled && std::string(enabled) == "1";
        if (!sEnabled)
            return;

        NSString* documents = safeString(openmw_ios_documents_path());
        NSString* directory = [documents stringByAppendingPathComponent:@"OpenMW"];
        [[NSFileManager defaultManager] createDirectoryAtPath:directory
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
        sPath = [[directory stringByAppendingPathComponent:@"renderer-diagnostic.jsonl"] copy];
        [[NSFileManager defaultManager] createFileAtPath:sPath contents:[NSData data] attributes:nil];
        sSession = [NSUUID.UUID.UUIDString copy];
        appendRecord(@{
            @"schema" : @"openmw-ios-renderer-diagnostic-v1",
            @"session" : sSession,
            @"sample" : @0,
            @"family" : @"session",
            @"source" : @"ios",
            @"correlation" : @"startup",
            @"detail" : @"enabled=1;path=Documents/OpenMW/renderer-diagnostic.jsonl;max_bytes=262144"
        });
    }
}

extern "C" void openmw_ios_renderer_diag_begin(void)
{
    @autoreleasepool
    {
        std::lock_guard<std::mutex> lock(sMutex);
        beginLocked();
    }
}

extern "C" int openmw_ios_renderer_diag_enabled(void)
{
    std::lock_guard<std::mutex> lock(sMutex);
    beginLocked();
    return sEnabled ? 1 : 0;
}

extern "C" uint32_t openmw_ios_renderer_diag_record(
    const char* family, const char* source, const char* correlation, const char* detail)
{
    @autoreleasepool
    {
        std::lock_guard<std::mutex> lock(sMutex);
        beginLocked();
        if (!sEnabled || sBytes >= MaxFileBytes)
            return 0;

        const std::string familyKey = family ? family : "unknown";
        FamilyState& state = sFamilies[familyKey];
        if (state.budget == 0)
            state.budget = budgetForFamily(familyKey);
        if (state.count >= state.budget)
        {
            if (!state.exhausted)
            {
                state.exhausted = true;
                appendRecord(@{
                    @"schema" : @"openmw-ios-renderer-diagnostic-v1",
                    @"session" : sSession,
                    @"sample" : @(sNextSample++),
                    @"family" : safeString(family),
                    @"source" : @"budget",
                    @"correlation" : @"exhausted",
                    @"detail" : [NSString stringWithFormat:@"budget=%u", state.budget]
                });
            }
            return 0;
        }

        ++state.count;
        const uint32_t sample = sNextSample++;
        if (!appendRecord(@{
                @"schema" : @"openmw-ios-renderer-diagnostic-v1",
                @"session" : sSession,
                @"sample" : @(sample),
                @"family" : safeString(family),
                @"source" : safeString(source),
                @"correlation" : safeString(correlation),
                @"detail" : safeString(detail)
            }))
            return 0;
        return sample;
    }
}

extern "C" void openmw_ios_renderer_diag_register_texture(
    uint64_t hash, int category, const char* identity, const char* detail)
{
    {
        std::lock_guard<std::mutex> lock(sMutex);
        beginLocked();
        if (!sEnabled || hash == 0 || category == OPENMW_IOS_RENDERER_TEXTURE_NONE)
            return;
        sTextureCategories[hash] = category;
    }
    char correlation[32];
    snprintf(correlation, sizeof(correlation), "%016llx", (unsigned long long)hash);
    std::string combined = "category=" + std::to_string(category) + ";identity="
        + (identity ? identity : "") + ";" + (detail ? detail : "");
    openmw_ios_renderer_diag_record("r1.asset", "openmw", correlation, combined.c_str());
}

extern "C" int openmw_ios_renderer_diag_texture_category(uint64_t hash)
{
    std::lock_guard<std::mutex> lock(sMutex);
    beginLocked();
    const auto found = sTextureCategories.find(hash);
    return found == sTextureCategories.end() ? OPENMW_IOS_RENDERER_TEXTURE_NONE : found->second;
}

extern "C" uint64_t openmw_ios_renderer_diag_hash(const void* data, size_t size)
{
    if (!data || size == 0)
        return 0;
    const unsigned char* bytes = static_cast<const unsigned char*>(data);
    uint64_t hash = UINT64_C(14695981039346656037);
    for (size_t i = 0; i < size; ++i)
    {
        hash ^= bytes[i];
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}
