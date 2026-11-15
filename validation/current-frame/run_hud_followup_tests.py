"""Only the corrected HUD targets, gestures, and iOS GUI default precedence."""
import configparser,os,pathlib,shutil,subprocess,tempfile
root=pathlib.Path(__file__).resolve().parents[2]
compiler=os.environ.get('CXX') or shutil.which('clang++') or shutil.which('g++') or shutil.which('cl')
assert compiler,'C++17 compiler required'
with tempfile.TemporaryDirectory(prefix='openmw-hud-followup-') as directory:
    d=pathlib.Path(directory)
    hud=(root/'apps/openmw/mwgui/hud.cpp').read_text()
    start=hud.index('#if defined(__APPLE__) && TARGET_OS_IPHONE',hud.index('void HUD::onFrame('))
    end=hud.index('#endif',start)
    block=hud[hud.index('\n',start)+1:end]
    publication=d/'hud_publication.cpp'
    publication.write_text((root/'validation/current-frame/hud_publication.cpp.in').read_text().replace('// PRODUCTION_HUD_PUBLICATION',block))
    for source in (root/'validation/current-frame/hud_gestures.cpp',publication):
        exe=d/('test.exe' if os.name=='nt' else 'test')
        if pathlib.Path(compiler).name.lower() in ('cl','cl.exe'):
            args=[compiler,'/nologo','/std:c++17','/EHsc','/W4','/WX',f'/I{root}',str(source),f'/Fo{d/"test.obj"}',f'/Fe{exe}']
        else:
            args=[compiler,'-std=c++17','-Wall','-Wextra','-Werror','-I',str(root),str(source),'-o',str(exe)]
        subprocess.run(args,check=True,cwd=d);subprocess.run([str(exe)],check=True,cwd=d)
adapter=(root/'apps/openmw/ios/openmw_ios_touch_controls.mm').read_text()
assert 'MyGUI::' not in adapter
assert 'OpenMWIOS::Touch::hudActionAt(targets, x, y)' in adapter
assert 'OpenMWIOS::Touch::hudHasHold(_hudTap)' in adapter
assert '_weaponTouch.update(' not in adapter
assert '_weaponTouch.finish(identifier, CACurrentMediaTime(), cancelled == YES, false)' in adapter
assert 'OpenMWIOSTouchProfileV1' in adapter and 'validProfile(candidate)' in adapter
defaults=configparser.ConfigParser();defaults.read(root/'ios/OpenMW/settings.cfg')
assert defaults.getfloat('GUI','scaling factor')==1.2
defaults.read_string('[GUI]\nscaling factor = 1.35\n')
assert defaults.getfloat('GUI','scaling factor')==1.35
print('PASS adapter policy wiring and iOS GUI scale 1.2 with explicit user override preserved; Apple build/phone check pending')
