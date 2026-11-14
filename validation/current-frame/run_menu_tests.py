"""Only menu/map input and the changed HUD gesture/ownership paths."""
import os,pathlib,shutil,subprocess,tempfile
root=pathlib.Path(__file__).resolve().parents[2]
compiler=os.environ.get('CXX') or shutil.which('clang++') or shutil.which('g++') or shutil.which('cl')
assert compiler,'C++17 compiler required'
with tempfile.TemporaryDirectory(prefix='openmw-menu-') as directory:
    d=pathlib.Path(directory)
    for name in ('MyGUI_InputManager.h','MyGUI_LayerManager.h','MyGUI_RenderManager.h','MyGUI_WidgetManager.h','SDL_events.h','SDL_timer.h'):
        (d/name).write_text('#include "'+str(root/'validation/current-frame/menu_stubs.hpp').replace('\\','/')+'"\n')
    for source in ('validation/menu-touch/test.cpp','validation/current-frame/menu_input.cpp','validation/current-frame/hud_gestures.cpp'):
        exe=d/('test.exe' if os.name=='nt' else 'test')
        if pathlib.Path(compiler).name.lower() in ('cl','cl.exe'):
            args=[compiler,'/nologo','/std:c++17','/EHsc','/W4','/WX',f'/I{d}',str(root/source),f'/Fo{d/"test.obj"}',f'/Fe{exe}']
        else:
            args=[compiler,'-std=c++17','-Wall','-Wextra','-Werror','-I',str(d),str(root/source),'-o',str(exe)]
        subprocess.run(args,check=True,cwd=d);subprocess.run([str(exe)],check=True,cwd=d)
adapter=(root/'apps/openmw/ios/openmw_ios_touch_controls.mm').read_text()
assert 'MyGUI::' not in adapter
assert 'pushMenuPointer' not in adapter
assert 'event.tfinger.x = point.x / view.width' in adapter
assert 'inputGeneration()) << 32' in adapter
assert 'UIImpactFeedbackGenerator' in adapter
assert 'OpenMWIOSTouchProfileV1' in adapter and 'validProfile(candidate)' in adapter
assert '[_pinchRecognizer release]' in adapter
map_source=(root/'apps/openmw/mwgui/mapwindow.cpp').read_text()
assert map_source.count('setUserString("OpenMWTouchDrag", "true")')==5
assert map_source.count('eventMouseButtonDoubleClick +=')==2
print('PASS thread boundary, exact map/marker receivers and preserved profile/pinch wiring; phone interaction check pending')
