import os, pathlib, platform, subprocess, tempfile
root=pathlib.Path(__file__).resolve().parents[2]
cxx=os.environ.get('CXX','c++');moc=root/'extern/maskedoc'
def run(args):subprocess.run(list(map(str,args)),check=True,cwd=root)
with tempfile.TemporaryDirectory(prefix='openmw-city-') as tmp:
 d=pathlib.Path(tmp); objs=[]
 arm=platform.machine().lower() in ('arm64','aarch64')
 units=[('MaskedOcclusionCulling.cpp',[] if arm else ['-msse4.1','-mxsave'])]
 if not arm: units += [('MaskedOcclusionCullingAVX2.cpp',['-mavx2','-mfma']),('MaskedOcclusionCullingAVX512.cpp',['-mavx512f','-mavx512bw'])]
 defs=['-DSSE2NEON_PRECISE_'+s+'=1' for s in ('MINMAX','DIV','SQRT','DP')]
 for file,flags in units:
  obj=d/(file+'.o');run([cxx,'-std=c++20','-O2',*defs,*flags,'-c',moc/file,'-o',obj]);objs.append(obj)
 core=d/'moc-core';run([cxx,'-std=c++20','-O2','-I'+str(moc),root/'validation/city-culling/moc_core.cpp',*objs,'-o',core]);run([core])
 # Apple ARM runner executes the real NEON backend before the iOS application build.
 if platform.system()=='Darwin': print('ARM MOC visibility/reset tests passed');raise SystemExit(0)
 inc=['-I'+str(root),'-I'+str(moc)]
 for name in ('visibility','mesh'):
  src=[root/'validation/city-culling'/f'{name}.cpp']
  if name=='visibility':src += [root/'components/sceneutil/occlusionculling.cpp',*objs];libs=['-losg','-lOpenThreads']
  else:src += [root/'apps/openmw/mwrender/occlusionculling.cpp'];libs=['-losg','-losgUtil','-lOpenThreads']
  out=d/name;run([cxx,'-std=c++20','-O2','-ffunction-sections','-fdata-sections',*inc,*src,'-Wl,--gc-sections',*libs,'-o',out]);run([out])
 print('Focused city-culling tests passed')
