#import "openmw_ios_renderer_diagnostics.h"

#import "openmw_ios_paths.h"

#import <Foundation/Foundation.h>

#include <algorithm>
#include <atomic>
#include <cmath>
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <deque>
#include <functional>
#include <mutex>
#include <string>
#include <thread>
#include <unordered_map>
#include <utility>
#include <vector>

namespace
{
    constexpr unsigned long long MaxFileBytes = 256 * 1024;
    constexpr size_t BlendRingCapacity = 48;
    constexpr unsigned int TargetDrawBudget = 96;

    struct FamilyState
    {
        unsigned int count = 0;
        unsigned int budget = 0;
        bool exhausted = false;
    };

    struct BlendEvent
    {
        uint64_t sequence = 0;
        unsigned long long thread = 0;
        std::string source;
        std::string site;
        std::string detail;
    };

    struct TargetDraw
    {
        uint64_t id = 0;
        unsigned int program = 0;
        unsigned int framebuffer = 0;
        unsigned char before[4] = { 0, 0, 0, 0 };
        unsigned char after[4] = { 0, 0, 0, 0 };
        bool hasBefore = false;
        bool hasAfter = false;
        bool changed = false;
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
    uint64_t sBlendSequence = 0;
    std::deque<BlendEvent> sBlendRing;
    std::string sTargetRequest;
    bool sTargetCaptureArmed = false;
    bool sTargetCaptureActive = false;
    bool sTargetCaptureComplete = false;
    uint64_t sNextTargetDraw = 1;
    unsigned int sTargetCandidateCount = 0;
    unsigned int sTargetChangedCount = 0;
    uint64_t sTargetLastChangedDraw = 0;
    std::unordered_map<uint64_t, TargetDraw> sTargetDraws;
    thread_local uint64_t sCurrentTargetDraw = 0;

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
        if (family == "r1.blend.transition")
            return 128;
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
        if (family.rfind("r3.", 0) == 0)
            return 112;
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
        NSString* requestPath = [directory stringByAppendingPathComponent:@"renderer-target-request.txt"];
        NSError* requestError = nil;
        NSString* request = [NSString stringWithContentsOfFile:requestPath
                                                      encoding:NSUTF8StringEncoding
                                                         error:&requestError];
        if (request && !requestError)
        {
            request = [request stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if (request.length > 0 && request.length <= 80)
                sTargetRequest = request.UTF8String;
        }
        appendRecord(@{
            @"schema" : @"openmw-ios-renderer-diagnostic-v1",
            @"session" : sSession,
            @"sample" : @0,
            @"family" : @"session",
            @"source" : @"ios",
            @"correlation" : @"startup",
            @"detail" : [NSString stringWithFormat:
                @"enabled=1;path=Documents/OpenMW/renderer-diagnostic.jsonl;max_bytes=262144;target_request=%@",
                sTargetRequest.empty() ? @"none" : safeString(sTargetRequest.c_str())]
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

extern "C" void openmw_ios_renderer_diag_blend_event(
    const char* source, const char* site, const char* detail)
{
    const unsigned long long thread
        = static_cast<unsigned long long>(std::hash<std::thread::id>{}(std::this_thread::get_id()));
    const std::string safeSite = site ? site : "unknown";
    std::vector<BlendEvent> flushEvents;
    {
        std::lock_guard<std::mutex> lock(sMutex);
        beginLocked();
        if (!sEnabled || !sTargetArmed[OPENMW_IOS_RENDERER_TARGET_CHIMNEY_SMOKE])
            return;
        BlendEvent event;
        event.sequence = ++sBlendSequence;
        event.thread = thread;
        event.source = source ? source : "unknown";
        event.site = safeSite;
        event.detail = detail ? detail : "";
        sBlendRing.push_back(std::move(event));
        while (sBlendRing.size() > BlendRingCapacity)
            sBlendRing.pop_front();
        if (safeSite == "glDrawElementsCommon" || safeSite == "draw_renderlist.native-draw")
        {
            flushEvents.assign(sBlendRing.begin(), sBlendRing.end());
            sBlendRing.clear();
        }
    }
    for (const BlendEvent& event : flushEvents)
    {
        char correlation[48];
        char combined[1024];
        std::snprintf(correlation, sizeof(correlation), "blend-%llu",
            static_cast<unsigned long long>(event.sequence));
        std::snprintf(combined, sizeof(combined), "sequence=%llu;thread=%llu;site=%s;%s",
            static_cast<unsigned long long>(event.sequence), event.thread, event.site.c_str(),
            event.detail.c_str());
        openmw_ios_renderer_diag_record(
            "r1.blend.transition", event.source.c_str(), correlation, combined);
    }
}

extern "C" void openmw_ios_renderer_diag_arm_exterior_fog(
    float start, float end, const float* color, float view_distance)
{
    if (!color)
        return;
    unsigned int generation = 0;
    bool armTargetCapture = false;
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
        if (!sTargetRequest.empty() && !sTargetCaptureComplete && !sTargetCaptureArmed)
        {
            sTargetCaptureArmed = true;
            armTargetCapture = true;
        }
    }
    char correlation[48];
    char detail[320];
    std::snprintf(correlation, sizeof(correlation), "generation-%u", generation);
    std::snprintf(detail, sizeof(detail),
        "generation=%u;start=%.6g;end=%.6g;view_distance=%.6g;color=%.6g,%.6g,%.6g,%.6g",
        generation, start, end, view_distance, color[0], color[1], color[2], color[3]);
    openmw_ios_renderer_diag_record("r2.arm", "openmw", correlation, detail);
    if (armTargetCapture)
    {
        std::snprintf(detail, sizeof(detail),
            "request=%s;generation=%u;target_ndc=0,0;draw_budget=%u;depth_sample=unsupported-gles2",
            sTargetRequest.c_str(), generation, TargetDrawBudget);
        openmw_ios_renderer_diag_record("r3.arm", "openmw", correlation, detail);
    }
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

extern "C" uint64_t openmw_ios_renderer_diag_osg_draw_begin(const void* drawable,
    const char* drawable_name, const char* parent_name, const char* camera_name,
    int camera_order, int render_bin, float render_depth, float eye_depth,
    const float* object_bounds, const float* ndc_bounds, int near_clipped)
{
    uint64_t draw = 0;
    {
        std::lock_guard<std::mutex> lock(sMutex);
        beginLocked();
        if (!sEnabled || !sTargetCaptureArmed || sTargetCaptureComplete
            || sTargetCandidateCount >= TargetDrawBudget)
            return 0;
        sTargetCaptureActive = true;
        draw = sNextTargetDraw++;
        TargetDraw target;
        target.id = draw;
        sTargetDraws.emplace(draw, target);
        ++sTargetCandidateCount;
        sCurrentTargetDraw = draw;
    }

    char correlation[48];
    char detail[1536];
    std::snprintf(correlation, sizeof(correlation), "draw-%llu",
        static_cast<unsigned long long>(draw));
    std::snprintf(detail, sizeof(detail),
        "drawable_ptr=%p;drawable=%s;parent=%s;camera=%s;camera_order=%d;render_bin=%d;"
        "render_depth=%.9g;eye_depth=%.9g;near_clipped=%d;"
        "object_bounds=%.9g,%.9g,%.9g,%.9g,%.9g,%.9g;"
        "ndc_bounds=%.9g,%.9g,%.9g,%.9g,%.9g,%.9g;target_ndc=0,0",
        drawable, drawable_name ? drawable_name : "", parent_name ? parent_name : "",
        camera_name ? camera_name : "", camera_order, render_bin, render_depth, eye_depth,
        near_clipped, object_bounds ? object_bounds[0] : 0.f, object_bounds ? object_bounds[1] : 0.f,
        object_bounds ? object_bounds[2] : 0.f, object_bounds ? object_bounds[3] : 0.f,
        object_bounds ? object_bounds[4] : 0.f, object_bounds ? object_bounds[5] : 0.f,
        ndc_bounds ? ndc_bounds[0] : 0.f, ndc_bounds ? ndc_bounds[1] : 0.f,
        ndc_bounds ? ndc_bounds[2] : 0.f, ndc_bounds ? ndc_bounds[3] : 0.f,
        ndc_bounds ? ndc_bounds[4] : 0.f, ndc_bounds ? ndc_bounds[5] : 0.f);
    openmw_ios_renderer_diag_record("r3.osg.candidate", "osg", correlation, detail);
    return draw;
}

extern "C" void openmw_ios_renderer_diag_osg_draw_end(uint64_t draw)
{
    if (draw != 0 && sCurrentTargetDraw == draw)
        sCurrentTargetDraw = 0;
}

extern "C" uint64_t openmw_ios_renderer_diag_current_osg_draw(void)
{
    return sCurrentTargetDraw;
}

extern "C" int openmw_ios_renderer_diag_target_capture_active(void)
{
    std::lock_guard<std::mutex> lock(sMutex);
    beginLocked();
    // The present-side sample must still run when no OSG drawable covers the
    // target.  Requiring a candidate here would erase the exact
    // coverage/composition observation WO37 is designed to make.
    return sEnabled && sTargetCaptureArmed && !sTargetCaptureComplete ? 1 : 0;
}

extern "C" void openmw_ios_renderer_diag_gl_draw_sample(uint64_t draw, int phase,
    unsigned int program, unsigned int framebuffer, const int* viewport,
    const unsigned char* rgba, const char* state_detail)
{
    if (draw == 0 || !rgba)
        return;
    bool emit = false;
    bool changed = false;
    unsigned char before[4] = { 0, 0, 0, 0 };
    {
        std::lock_guard<std::mutex> lock(sMutex);
        beginLocked();
        if (!sEnabled || !sTargetCaptureArmed || sTargetCaptureComplete)
            return;
        const auto found = sTargetDraws.find(draw);
        if (found == sTargetDraws.end())
            return;
        TargetDraw& target = found->second;
        target.program = program;
        target.framebuffer = framebuffer;
        if (phase == 0)
        {
            std::copy(rgba, rgba + 4, target.before);
            target.hasBefore = true;
        }
        else
        {
            std::copy(rgba, rgba + 4, target.after);
            target.hasAfter = true;
            target.changed = target.hasBefore && !std::equal(target.before, target.before + 4, target.after);
            changed = target.changed;
            std::copy(target.before, target.before + 4, before);
            if (target.changed)
            {
                ++sTargetChangedCount;
                sTargetLastChangedDraw = draw;
            }
            emit = true;
        }
    }
    if (!emit)
        return;

    char correlation[48];
    char detail[2048];
    std::snprintf(correlation, sizeof(correlation), "draw-%llu",
        static_cast<unsigned long long>(draw));
    std::snprintf(detail, sizeof(detail),
        "program=%u;framebuffer=%u;viewport=%d,%d,%d,%d;before=%u,%u,%u,%u;"
        "after=%u,%u,%u,%u;color_changed=%d;%s",
        program, framebuffer, viewport ? viewport[0] : 0, viewport ? viewport[1] : 0,
        viewport ? viewport[2] : 0, viewport ? viewport[3] : 0,
        static_cast<unsigned int>(before[0]), static_cast<unsigned int>(before[1]),
        static_cast<unsigned int>(before[2]), static_cast<unsigned int>(before[3]),
        static_cast<unsigned int>(rgba[0]), static_cast<unsigned int>(rgba[1]),
        static_cast<unsigned int>(rgba[2]), static_cast<unsigned int>(rgba[3]),
        changed ? 1 : 0, state_detail ? state_detail : "");
    openmw_ios_renderer_diag_record("r3.gl.draw", "gl4es", correlation, detail);
}

extern "C" void openmw_ios_renderer_diag_present_sample(unsigned int framebuffer,
    const int* viewport, const unsigned char* rgba)
{
    if (!rgba)
        return;
    unsigned int candidates = 0;
    unsigned int changed = 0;
    uint64_t lastChanged = 0;
    float fog[4] = { 0.f, 0.f, 0.f, 0.f };
    {
        std::lock_guard<std::mutex> lock(sMutex);
        beginLocked();
        if (!sEnabled || !sTargetCaptureArmed || sTargetCaptureComplete)
            return;
        candidates = sTargetCandidateCount;
        changed = sTargetChangedCount;
        lastChanged = sTargetLastChangedDraw;
        std::copy(sExteriorFogColor, sExteriorFogColor + 4, fog);
        sTargetCaptureComplete = true;
        sTargetCaptureArmed = false;
        sTargetCaptureActive = false;
        sCurrentTargetDraw = 0;
    }

    char detail[1024];
    std::snprintf(detail, sizeof(detail),
        "framebuffer=%u;viewport=%d,%d,%d,%d;presented_center=%u,%u,%u,%u;"
        "candidates=%u;color_changing_draws=%u;last_changed_draw=%llu;"
        "fog_color=%.9g,%.9g,%.9g,%.9g;depth_sample=unsupported-gles2;"
        "sky_rtt_sample=not-observed-observer-only;"
        "classification=%s",
        framebuffer, viewport ? viewport[0] : 0, viewport ? viewport[1] : 0,
        viewport ? viewport[2] : 0, viewport ? viewport[3] : 0,
        static_cast<unsigned int>(rgba[0]), static_cast<unsigned int>(rgba[1]),
        static_cast<unsigned int>(rgba[2]), static_cast<unsigned int>(rgba[3]), candidates, changed,
        static_cast<unsigned long long>(lastChanged), fog[0], fog[1], fog[2], fog[3],
        candidates == 0 ? "coverage-composition-candidate-no-osg-center-coverage"
            : (changed > 0 ? "drawn-pixel-candidate"
                           : "ambiguous-candidates-no-color-change"));
    openmw_ios_renderer_diag_record("r3.present", "ios", "target-center", detail);
    openmw_ios_renderer_diag_record("summary", "ios", "r3-target-pixel", detail);
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
