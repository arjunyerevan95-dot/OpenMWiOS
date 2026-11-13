# Main-app current-frame integration
Uses the exact SDL current-frame mechanism from diagnostic 3235ecfe. User reported improved subjective responsiveness on iPhone. No measured millisecond claim.
Build identity stays OpenMW Zink Touch / org.openmw.ios.zinktouch. Install as update to existing guest; do not delete container. Config/save paths and touch source unchanged. No retail data bundled. Legacy buffering remains selectable by SDL_UIKIT_EGL_CURRENT_FRAME=false.
Device regression checks: existing saves/config retained, menus/rotation/background restore, MetalFX scale changes, FPS/thermal throughput and input latency at identical settings.
