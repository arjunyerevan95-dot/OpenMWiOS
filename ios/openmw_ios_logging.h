#pragma once

#ifdef __cplusplus
extern "C"
{
#endif

void openmw_ios_log(const char* milestone, const char* detail);
void openmw_ios_log_fatal(const char* detail);
void openmw_ios_log_view_metrics(const char* milestone);

#ifdef __cplusplus
}
#endif
