#pragma once

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

enum openmw_ios_renderer_texture_category
{
    OPENMW_IOS_RENDERER_TEXTURE_NONE = 0,
    OPENMW_IOS_RENDERER_TEXTURE_ALPHA_CARD = 1,
    OPENMW_IOS_RENDERER_TEXTURE_PARTICLE = 2,
    OPENMW_IOS_RENDERER_TEXTURE_CONTROL = 3
};

enum openmw_ios_renderer_target_kind
{
    OPENMW_IOS_RENDERER_TARGET_NONE = 0,
    OPENMW_IOS_RENDERER_TARGET_FOLIAGE = 1,
    OPENMW_IOS_RENDERER_TARGET_CHIMNEY_SMOKE = 2,
    OPENMW_IOS_RENDERER_TARGET_OPAQUE_CONTROL = 3
};

// Diagnostics are disabled unless OPENMW_IOS_RENDERER_DIAGNOSTICS=1.
void openmw_ios_renderer_diag_begin(void);
int openmw_ios_renderer_diag_enabled(void);
uint32_t openmw_ios_renderer_diag_record(const char* family, const char* source, const char* correlation,
    const char* detail);
void openmw_ios_renderer_diag_register_texture(
    uint64_t hash, int category, const char* identity, const char* detail);
int openmw_ios_renderer_diag_texture_category(uint64_t hash);
void openmw_ios_renderer_diag_register_gl_texture(
    unsigned int texture, uint64_t hash, int category, const char* identity, const char* detail);
int openmw_ios_renderer_diag_texture_category_for_gl_name(unsigned int texture);
int openmw_ios_renderer_diag_target_for_hash(uint64_t hash);
int openmw_ios_renderer_diag_target_for_gl_name(unsigned int texture);
void openmw_ios_renderer_diag_blend_event(
    const char* source, const char* site, const char* detail);
void openmw_ios_renderer_diag_arm_exterior_fog(
    float start, float end, const float* color, float view_distance);
unsigned int openmw_ios_renderer_diag_matching_exterior_fog_generation(
    float start, float end, const float* color);
uint64_t openmw_ios_renderer_diag_hash(const void* data, size_t size);

#ifdef __cplusplus
}
#endif
