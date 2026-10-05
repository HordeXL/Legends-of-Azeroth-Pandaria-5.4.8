#!/usr/bin/env python3
"""Compile the actual Kypari Zar callbacks against a small world fixture."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[2]
source = (root / 'src/server/scripts/Pandaria/zone_dread_wastes.cpp').read_text()
code = source[source.index('namespace KypariZar'):source.index('// Evie Stormstout (31077)')]
harness = (Path(__file__).with_name('regression.cpp')).read_text()
with tempfile.TemporaryDirectory(prefix='kypari-zar-') as directory:
    cpp = Path(directory) / 'test.cpp'
    cpp.write_text(harness.replace('// PRODUCTION_SCRIPT', code.replace(' override', '')))
    binary = Path(directory) / 'test'
    subprocess.run(['c++', '-std=c++11', '-Wall', '-Wextra', '-Werror', str(cpp), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
