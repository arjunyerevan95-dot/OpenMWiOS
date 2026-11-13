#pragma once
#include <SDL_video.h>
#ifdef __cplusplus
extern "C" {
#else
#include <stdbool.h>
#endif
void openmw_ios_install_touch_controls(SDL_Window* window);
void openmw_ios_set_touch_enabled(bool enabled);
void openmw_ios_set_gameplay_mode(bool gameplay);
void openmw_ios_set_weapon_ready(bool ready);
void openmw_ios_shutdown_touch_controls(void);
#ifdef __cplusplus
}
#endif
