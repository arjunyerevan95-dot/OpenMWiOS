"""Lease this input-only follow-up to the delivered pinch-editor source."""
import subprocess
BASE='ca361f758df7c396f89fb0eebcfab92eba90d040'
allowed={
    '.github/workflows/current-frame-ios.yml',
    'apps/openmw/ios/openmw_ios_menu_input.hpp',
    'apps/openmw/ios/openmw_ios_menu_touch.hpp',
    'apps/openmw/ios/openmw_ios_touch_controls.h',
    'apps/openmw/ios/openmw_ios_touch_controls.mm',
    'apps/openmw/ios/openmw_ios_touch_model.hpp',
    'apps/openmw/ios/openmw_ios_touch_targets.hpp',
    'apps/openmw/mwgui/mapwindow.cpp',
    'apps/openmw/mwgui/hud.cpp',
    'apps/openmw/mwinput/inputmanagerimp.cpp',
    'apps/openmw/mwinput/mousemanager.cpp',
    'apps/openmw/mwinput/mousemanager.hpp',
    'components/sdlutil/events.hpp',
    'components/sdlutil/sdlinputwrapper.cpp',
}
changed=subprocess.check_output(['git','diff','--name-only',BASE],text=True).splitlines()
assert all(p in allowed or p.startswith('validation/current-frame/') for p in changed),changed
subprocess.run(['git','diff','--exit-code',BASE,'--','ios-deps','components/files','ios/OpenMW',
    'apps/openmw/ios/openmw_ios_parry_gesture.hpp','apps/openmw/ios/openmw_ios_use_gesture.hpp',
    'apps/openmw/ios/openmw_ios_touch_state.hpp'],check=True)
print('PASS input-only scope; renderer, dependencies, storage and existing parry/use/editor state preserved')
