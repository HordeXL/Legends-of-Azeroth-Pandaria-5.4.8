#!/usr/bin/env python3
"""Compile policy and production planner against a small simulated world."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
source = root / 'modules/mod_playerbots/src/AI/AhnQirajStrategy.cpp'
with tempfile.TemporaryDirectory(prefix='aq40-tests-') as temp:
    temp = Path(temp)
    # Only replace core dependencies; compile every production decision body.
    (temp / 'strategy-under-test.inc').write_text('\n'.join(
        line for line in source.read_text().splitlines()
        if not line.startswith('#include')))
    for test in ('policy_regression', 'strategy_regression'):
        executable = temp / test
        subprocess.run(['c++', '-std=c++17', '-Wall', '-Wextra', '-Werror',
                        '-I', str(temp), str(root / 'contrib/aq40_playerbots' / (test + '.cpp')),
                        '-o', str(executable)], check=True)
        subprocess.run([str(executable)], check=True)
