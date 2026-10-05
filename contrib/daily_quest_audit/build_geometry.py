from pathlib import Path
import shlex,subprocess
f=Path('build/src/server/game/CMakeFiles/game.dir/flags.make').read_text().splitlines();args=['c++','-std=c++20','-Wno-deprecated-declarations','-O2','-ffunction-sections','-fdata-sections','-Wl,--gc-sections']
for l in f:
 if l.startswith(('CXX_INCLUDES =','CXX_DEFINES =')):args+=shlex.split(l.split('=',1)[1])
args+=['contrib/daily_quest_audit/check_points.cpp','-o','/tmp/daily_geometry','-Wl,--start-group','build/src/server/game/libgame.a','build/src/server/shared/libshared.a','build/src/server/database/libdatabase.a','build/src/common/libcommon.a','build/dep/g3dlite/libg3dlib.a','build/dep/fmt/libfmt.a','build/dep/SFMT/libsfmt.a','build/dep/recastnavigation/Detour/libDetour.a','-Wl,--end-group','-lboost_filesystem','-lboost_system','-lboost_program_options','-lboost_iostreams','-lboost_thread','-lboost_chrono','-lssl','-lcrypto','-lmariadb','-lz','-ldl','-lpthread']
r=subprocess.run(args,capture_output=True,text=True);Path('/tmp/daily-geometry-build.log').write_text(r.stderr); print(r.stderr[-5000:] if r.returncode else 'Build OK')
raise SystemExit(r.returncode)
