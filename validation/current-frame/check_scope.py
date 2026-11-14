import pathlib,subprocess
BASE="568323258e0a17f294b91797b68cd29222c374ab"
allowed={"apps/openmw/ios/openmw_ios_menu_touch.hpp","validation/menu-touch/README.md","validation/menu-touch/test.cpp",".github/workflows/push.yml","ios-deps/patches/sdl2/0002-uikit-desktop-opengl-via-egl.patch",".github/workflows/current-frame-ios.yml", "apps/openmw/ios/openmw_ios_touch_controls.mm", "apps/openmw/ios/openmw_ios_touch_model.hpp", "validation/wo40/held_attack_swipe.cpp", "apps/openmw/ios/openmw_ios_use_gesture.hpp", "apps/openmw/ios/openmw_ios_parry_gesture.hpp", "apps/openmw/ios/openmw_ios_touch_controls.h", "apps/openmw/mwinput/inputmanagerimp.cpp"}
changed=subprocess.check_output(["git","diff","--name-only",BASE],text=True).splitlines()
assert all(p in allowed or (p.startswith("validation/current-frame/") or p.startswith("validation/use-drag/") or p.startswith("validation/parry-gesture/")) for p in changed),changed
p=pathlib.Path("ios-deps/patches/sdl2/0002-uikit-desktop-opengl-via-egl.patch")
s=p.read_text()
assert 'SDL_GetHintBoolean("SDL_UIKIT_EGL_CURRENT_FRAME", SDL_TRUE)' in s
subprocess.run(["git","apply","--numstat",str(p)],check=True)
def ring(current):
 b=[None,None];out=[]
 for f in range(6):
  b[f%2]=f
  out.append(b[f%2 if current else (f+1)%2])
 return out
assert ring(False)==[None,0,1,2,3,4]
assert ring(True)==list(range(6))
print("Scope, patch syntax and ring-selection model pass; GPU/device validation pending.")

workflow=pathlib.Path(".github/workflows/current-frame-ios.yml").read_text()
assert "BUNDLE_ID=org.openmw.ios.zinktouch" in workflow
assert "APP_NAME=OpenMW Zink Touch" in workflow
assert "framediagnostic" not in workflow
subprocess.run(["git","diff","--exit-code","52aa732749de0aa3803f888bc2e2c1221349b24e","--","ios-deps","components/files","ios/OpenMW"],check=True)
