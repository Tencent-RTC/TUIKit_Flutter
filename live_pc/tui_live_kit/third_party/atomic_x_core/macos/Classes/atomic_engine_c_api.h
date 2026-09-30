

#ifndef ATOMIC_ENGINE_PLUGIN_MACOS_ATOMIC_ENGINE_C_API_H_
#define ATOMIC_ENGINE_PLUGIN_MACOS_ATOMIC_ENGINE_C_API_H_

#include <stdint.h>

#if defined(_WIN32) || defined(__CYGWIN__)
#define ATOMIC_ENGINE_API __declspec(dllexport)
#else
#define ATOMIC_ENGINE_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif
ATOMIC_ENGINE_API void* AtomicEngine_Create(void);

#ifdef __cplusplus
}
#endif

#endif  // ATOMIC_ENGINE_PLUGIN_MACOS_ATOMIC_ENGINE_C_API_H_
