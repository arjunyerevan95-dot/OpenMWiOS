#import "openmw_ios_renderer_diagnostics.h"

#import "openmw_ios_paths.h"

#import <Foundation/Foundation.h>

#include <algorithm>
#include <atomic>
#include <cmath>
#include <cctype>
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
    std::unordered_map<uint64_t, int> sTextureTargets;
    std::unordered_map<unsigned int, int> sGLTextureCategories;
    std::unordered_map<unsigned int, int> sGLTextureTargets;
    bool sTargetArmed[4] = { false, false, false, false };
    unsigned int sExteriorFogGeneration = 0;
    float sExteriorFogStart = 0.f;
    float sExteriorFogEnd = 0.f;
    float sExteriorFogColor[4] = { 0.f, 0.f, 0.f, 0.f };
    float sExteriorViewDistance = 0.f;

    unsigned int budgetForFamily(const std::string& family)
    {
        if (family == "session")
            return 2;
        if (family == "handshake")
            return 4;
        if (family.rfind("r1.asset", 0) == 0)
            return 48;
        if (family.rfind("r1.upload", 0) == 0)
            return 48;
        if (family.rfind("r1.draw", 0) == 0)
            return 96;
        if (family.rfind("r1.state", 0) == 0)
            return 48;
        if (family.rfind("r1.bound", 0) == 0)
            return 48;
        if (family.rfind("r1.arm", 0) == 0)
            return 16;
        if (family.rfind("r1.target", 0) == 0)
            return 24;
        if (family.rfind("r2.intent", 0) == 0)
            return 16;
        if (family.rfind("r2.received", 0) == 0)
            return 32;
        if (family.rfind("r2.applied", 0) == 0)
            return 32;
        if (family.rfind("r2.arm", 0) == 0)
            return 8;
        if (family.rfind("r2.projection", 0) == 0)
            return 8;
        if (family.rfind("r2.content", 0) == 0)
            return 32;
        if (family.rfind("r2.clear", 0) == 0)
            return 8;
        if (family == "summary")
            return 24;
        return 8;
    }

    NSString* safeString(const char* value)
    {
        if (!value)
            return @"";
        NSString* result = [NSString stringWithUTF8String:value];
        return result ?: @"<invalid-utf8>";
    }

    std::string lowerString(const char* value)
    {
        std::string result = value ? value : "";
        std::transform(result.begin(), result.end(), result.begin(),
            [](unsigned char character) { return static_cast<char>(std::tolower(character)); });
        return result;
    }

    int targetForIdentity(int category, const char* identity)
    {
        const std::string path = lowerString(identity);
        const auto contains = [&path](const char* token) { return path.find(token) != std::string::npos; };
        if (category == OPENMW_IOS_RENDERER_TEXTURE_ALPHA_CARD
            && (contains("moss") || contains("fern") || contains("leaf") || contains("flora")
                || contains("tree")))
            return OPENMW_IOS_RENDERER_TARGET_FOLIAGE;
        if (category == OPENMW_IOS_RENDERER_TEXTURE_PARTICLE && contains("smoke"))
            return OPENMW_IOS_RENDERER_TARGET_CHIMNEY_SMOKE;
        if (category == OPENMW_IOS_RENDERER_TEXTURE_CONTROL)
            return OPENMW_IOS_RENDERER_TARGET_OPAQUE_CONTROL;
        return OPENMW_IOS_RENDERER_TARGET_NONE;
    }

    bool nearlyEqual(float left, float right)
    {
        return std::fabs(left - right)
            <= std::max(0.001f, std::max(std::fabs(left), std::fabs(right)) * 0.00001f);
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
        sTextureTargets[hash] = targetForIdentity(category, identity);
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

extern "C" void openmw_ios_renderer_diag_register_gl_texture(
    unsigned int texture, uint64_t hash, int category, const char* identity, const char* detail)
{
    int target = OPENMW_IOS_RENDERER_TARGET_NONE;
    bool firstArm = false;
    {
        std::lock_guard<std::mutex> lock(sMutex);
        beginLocked();
        if (!sEnabled || texture == 0 || hash == 0 || category == OPENMW_IOS_RENDERER_TEXTURE_NONE)
            return;
        sGLTextureCategories[texture] = category;
        const auto foundTarget = sTextureTargets.find(hash);
        target = foundTarget == sTextureTargets.end() ? targetForIdentity(category, identity) : foundTarget->second;
        sGLTextureTargets[texture] = target;
        if (target > OPENMW_IOS_RENDERER_TARGET_NONE && target <= OPENMW_IOS_RENDERER_TARGET_OPAQUE_CONTROL
            && !sTargetArmed[target])
        {
            sTargetArmed[target] = true;
            firstArm = true;
        }
    }
    char correlation[48];
    snprintf(correlation, sizeof(correlation), "texture-%u", texture);
    std::string combined = "hash=" + std::to_string(hash) + ";category=" + std::to_string(category)
        + ";target=" + std::to_string(target)
        + ";identity=" + (identity ? identity : "") + ";" + (detail ? detail : "");
    openmw_ios_renderer_diag_record("r1.bound", "osg", correlation, combined.c_str());
    if (firstArm)
    {
        openmw_ios_renderer_diag_record("r1.arm", "ios", correlation, combined.c_str());
        std::string summary = "target=" + std::to_string(target)
            + ";status=miss-until-first-applied-draw;identity=" + (identity ? identity : "");
        openmw_ios_renderer_diag_record("summary", "ios", "r1-target", summary.c_str());
    }
}

extern "C" int openmw_ios_renderer_diag_texture_category_for_gl_name(unsigned int texture)
{
    std::lock_guard<std::mutex> lock(sMutex);
    beginLocked();
    const auto found = sGLTextureCategories.find(texture);
    return found == sGLTextureCategories.end() ? OPENMW_IOS_RENDERER_TEXTURE_NONE : found->second;
}

extern "C" int openmw_ios_renderer_diag_target_for_hash(uint64_t hash)
{
    std::lock_guard<std::mutex> lock(sMutex);
    beginLocked();
    const auto found = sTextureTargets.find(hash);
    return found == sTextureTargets.end() ? OPENMW_IOS_RENDERER_TARGET_NONE : found->second;
}

extern "C" int openmw_ios_renderer_diag_target_for_gl_name(unsigned int texture)
{
    std::lock_guard<std::mutex> lock(sMutex);
    beginLocked();
    const auto found = sGLTextureTargets.find(texture);
    return found == sGLTextureTargets.end() ? OPENMW_IOS_RENDERER_TARGET_NONE : found->second;
}

extern "C" void openmw_ios_renderer_diag_arm_exterior_fog(
    float start, float end, const float* color, float view_distance)
{
    if (!color)
        return;
    unsigned int generation = 0;
    {
        std::lock_guard<std::mutex> lock(sMutex);
        beginLocked();
        if (!sEnabled)
            return;
        bool changed = sExteriorFogGeneration == 0 || !nearlyEqual(start, sExteriorFogStart)
            || !nearlyEqual(end, sExteriorFogEnd) || !nearlyEqual(view_distance, sExteriorViewDistance);
        for (int index = 0; index < 4; ++index)
            changed = changed || !nearlyEqual(color[index], sExteriorFogColor[index]);
        if (!changed)
            return;
        generation = ++sExteriorFogGeneration;
        sExteriorFogStart = start;
        sExteriorFogEnd = end;
        sExteriorViewDistance = view_distance;
        for (int index = 0; index < 4; ++index)
            sExteriorFogColor[index] = color[index];
    }
    char correlation[48];
    char detail[320];
    std::snprintf(correlation, sizeof(correlation), "generation-%u", generation);
    std::snprintf(detail, sizeof(detail),
        "generation=%u;start=%.6g;end=%.6g;view_distance=%.6g;color=%.6g,%.6g,%.6g,%.6g",
        generation, start, end, view_distance, color[0], color[1], color[2], color[3]);
    openmw_ios_renderer_diag_record("r2.arm", "openmw", correlation, detail);
}

extern "C" unsigned int openmw_ios_renderer_diag_matching_exterior_fog_generation(
    float start, float end, const float* color)
{
    if (!color)
        return 0;
    std::lock_guard<std::mutex> lock(sMutex);
    beginLocked();
    if (!sEnabled || sExteriorFogGeneration == 0 || !nearlyEqual(start, sExteriorFogStart)
        || !nearlyEqual(end, sExteriorFogEnd))
        return 0;
    for (int index = 0; index < 4; ++index)
        if (!nearlyEqual(color[index], sExteriorFogColor[index]))
            return 0;
    return sExteriorFogGeneration;
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
