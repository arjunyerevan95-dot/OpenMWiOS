#pragma once

#ifdef __cplusplus
extern "C"
{
#endif

void openmw_ios_log(const char* milestone, const char* detail);
void openmw_ios_log_fatal(const char* detail);

#ifdef __cplusplus
}
#endif
