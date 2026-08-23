#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#include "ios_renderer_diag.h"

static unsigned int g_generation;
static float g_start;
static float g_end;
static float g_color[4];

int openmw_ios_renderer_diag_enabled(void)
{
    return 1;
}

unsigned int openmw_ios_renderer_diag_record(
    const char* family, const char* source, const char* correlation, const char* detail)
{
    static unsigned int sample = 0;
    ++sample;
    printf("{\"family\":\"%s\",\"source\":\"%s\",\"correlation\":\"%s\",\"detail\":\"%s\"}\n",
        family, source, correlation, detail);
    return sample;
}

int openmw_ios_renderer_diag_texture_category(uint64_t hash)
{
    return hash ? 1 : 0;
}

int openmw_ios_renderer_diag_texture_category_for_gl_name(unsigned int texture)
{
    return texture >= 41 && texture <= 43 ? 1 : 0;
}

int openmw_ios_renderer_diag_target_for_gl_name(unsigned int texture)
{
    return texture >= 41 && texture <= 43 ? (int)(texture - 40) : 0;
}

unsigned int openmw_ios_renderer_diag_matching_exterior_fog_generation(
    float start, float end, const float* color)
{
    if (!g_generation || fabsf(start - g_start) > 0.001f || fabsf(end - g_end) > 0.001f)
        return 0;
    for (int index = 0; index < 4; ++index)
        if (fabsf(color[index] - g_color[index]) > 0.001f)
            return 0;
    return g_generation;
}

uint64_t openmw_ios_renderer_diag_hash(const void* data, size_t size)
{
    const unsigned char* bytes = (const unsigned char*)data;
    uint64_t value = UINT64_C(14695981039346656037);
    for (size_t index = 0; index < size; ++index)
    {
        value ^= bytes[index];
        value *= UINT64_C(1099511628211);
    }
    return value;
}

static void set_exterior(unsigned int generation, float start, float end, const float* color)
{
    g_generation = generation;
    g_start = start;
    g_end = end;
    for (int index = 0; index < 4; ++index)
        g_color[index] = color[index];
}

static void targeted_draw(unsigned int program, unsigned int texture, int target,
    float start, float end, const float* color)
{
    wo31_diag_draw(program, texture, wo31_diag_texture_category_for_name(texture), target,
        1, 0x0302, 0x0303, 1, 0, 1, 0x0204, 0.5f, 1, 1, 0x0203,
        1, start, end, color, 1, 0, 1, 1, 6);
}

int main(void)
{
    const float mode[4] = { 0x2601, 0.f, 0.f, 0.f };
    const float color[4] = { 0.96f, 0.92f, 0.88f, 1.f };
    const float start_one[4] = { 2007.04f, 0.f, 0.f, 0.f };
    const float end_one[4] = { 7168.f, 0.f, 0.f, 0.f };
    const float start_two[4] = { 4014.08f, 0.f, 0.f, 0.f };
    const float end_two[4] = { 14336.f, 0.f, 0.f, 0.f };

    targeted_draw(7, 41, 1, start_one[0], end_one[0], color);
    targeted_draw(7, 44, 0, start_one[0], end_one[0], color);
    wo31_diag_fog_applied(7, 1, 2, 3, 4, 5, 1, 0, start_one[0], end_one[0], color);

    wo31_diag_fog_received(0x0B65, mode);
    wo31_diag_fog_received(0x0B63, start_one);
    wo31_diag_fog_received(0x0B64, end_one);
    wo31_diag_fog_received(0x0B66, color);
    set_exterior(1, start_one[0], end_one[0], color);

    wo31_diag_fog_applied(7, 1, 2, 3, 4, 5, 1, 0, start_one[0], end_one[0], color);
    targeted_draw(7, 41, 1, start_one[0], end_one[0], color);
    targeted_draw(8, 42, 2, start_one[0], end_one[0], color);
    targeted_draw(9, 43, 3, start_one[0], end_one[0], color);
    for (int index = 0; index < 8; ++index)
        targeted_draw(7, 41, 1, start_one[0], end_one[0], color);

    wo31_diag_fog_received(0x0B63, start_two);
    wo31_diag_fog_received(0x0B64, end_two);
    set_exterior(2, start_two[0], end_two[0], color);
    wo31_diag_fog_applied(7, 1, 2, 3, 4, 5, 1, 0, start_two[0], end_two[0], color);
    targeted_draw(7, 41, 1, start_two[0], end_two[0], color);
    return 0;
}
