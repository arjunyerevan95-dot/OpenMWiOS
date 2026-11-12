import pathlib,subprocess
BASE="568323258e0a17f294b91797b68cd29222c374ab"
allowed={".github/workflows/push.yml","ios-deps/patches/sdl2/0002-uikit-desktop-opengl-via-egl.patch",".github/workflows/current-frame-ios.yml"}
changed=subprocess.check_output(["git","diff","--name-only",BASE,"HEAD"],text=True).splitlines()
assert all(p in allowed or p.startswith("validation/current-frame/") for p in changed),changed
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
