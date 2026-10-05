#!/usr/bin/env python3
"""Exercise the production instance-release helper with a small fake world."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
source = (root / 'src/server/game/Handlers/MiscHandler.cpp').read_text()
start = source.index('bool ResurrectAtInstanceEntrance(')
end = source.index('\n}\n}', start) + 2
with tempfile.TemporaryDirectory(prefix='instance-release-') as directory:
    directory = Path(directory)
    (directory / 'release-under-test.inc').write_text(source[start:end])
    executable = directory / 'test'
    subprocess.run(['c++', '-std=c++17', '-Wall', '-Wextra', '-Werror',
                    '-I', str(directory), str(Path(__file__).with_name('regression.cpp')),
                    '-o', str(executable)], check=True)
    subprocess.run([str(executable)], check=True, timeout=10)
