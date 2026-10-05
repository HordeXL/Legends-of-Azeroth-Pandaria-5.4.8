#!/usr/bin/env python3
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
source = (root / 'src/server/worldserver/CommandLine/CliRunnable.cpp').read_text()
with tempfile.TemporaryDirectory(prefix='cli-eof-test-') as directory:
    directory = Path(directory)
    (directory / 'cli-under-test.inc').write_text(source[source.index('void CliThread()'):])
    executable = directory / 'cli-eof-test'
    subprocess.run(['c++', '-std=c++17', '-Wall', '-Wextra', '-Werror', '-I', str(directory),
                    str(root / 'contrib/debugger/cli_eof_regression.cpp'), '-lreadline',
                    '-o', str(executable)], check=True)
    with open('/dev/null') as stdin:
        subprocess.run([str(executable), '0'], stdin=stdin, check=True, timeout=5)
    subprocess.run([str(executable), '1'], input='server info\n', text=True, check=True, timeout=5)
