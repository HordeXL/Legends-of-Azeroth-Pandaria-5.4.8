#!/usr/bin/env python3
"""Exercise production tank-focus filtering and blocked-LOS assist movement."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]


def block(path, marker):
    source = (root / path).read_text()
    start = source.index(marker)
    end = source.index('{', start) + 1
    depth = 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]


fixture = Path(__file__).with_name('dps_los_regression.cpp').read_text()
fixture = fixture.replace('// TARGET_FILTER', block(
    'modules/mod_playerbots/src/strategy/value/DpsTargetValue.cpp',
    'auto isEngagedTarget ='))
fixture = fixture.replace('// LOS_RECOVERY', block(
    'modules/mod_playerbots/src/strategy/actions/AttackActions.cpp',
    'if (!bot->IsWithinLOSInMap(target))'))
with tempfile.TemporaryDirectory(prefix='dps-los-') as directory:
    source = Path(directory) / 'test.cpp'
    binary = Path(directory) / 'test'
    source.write_text(fixture)
    subprocess.run(['c++', '-std=c++17', '-Wall', '-Wextra', '-Werror',
                    str(source), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
