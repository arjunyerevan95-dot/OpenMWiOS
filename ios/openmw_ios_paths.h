#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// Returned pointers remain valid for the lifetime of the process.
const char* openmw_ios_documents_path(void);
const char* openmw_ios_library_path(void);
const char* openmw_ios_bundle_path(void);

#ifdef __cplusplus
}
#endif

