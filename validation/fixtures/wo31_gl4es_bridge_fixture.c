#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#include "ios_renderer_diag.h"

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
    return texture == 41 ? 1 : 0;
}

uint64_t openmw_ios_renderer_diag_hash(const void* data, size_t size)
{
    const unsigned char* bytes = (const unsigned char*)data;
    uint64_t value = UINT64_C(14695981039346656037);
    for (size_t i = 0; i < size; ++i)
    {
        value ^= bytes[i];
        value *= UINT64_C(1099511628211);
    }
    return value;
}

int main(void)
{
    const float fog_color[4] = { 0.96f, 0.92f, 0.88f, 1.f };
    const float fog_start[4] = { 2007.04f, 0.f, 0.f, 0.f };
    const float fog_end[4] = { 7168.f, 0.f, 0.f, 0.f };
    const unsigned char alpha_texture[4] = { 0, 64, 128, 255 };

    wo31_diag_handshake("fixture-get-proc-address");
    wo31_diag_handshake("must-be-bounded-to-one-record");
    wo31_diag_texture_upload(41, alpha_texture, sizeof(alpha_texture), 0x1908, 1, 1, 1, 0, 1);
    wo31_diag_draw(7, 41, wo31_diag_texture_category_for_name(41), 1, 1, 0, 1, 0,
        1, 0x0204, 0.5f, 1, fog_start[0], fog_end[0], fog_color, 6);
    wo31_diag_fog_received(0x0B63, fog_start);
    wo31_diag_fog_received(0x0B64, fog_end);
    wo31_diag_fog_applied(7, 1, fog_start[0], fog_end[0], fog_color);
    return 0;
}
