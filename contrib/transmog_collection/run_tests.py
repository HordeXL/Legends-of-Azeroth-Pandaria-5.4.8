#!/usr/bin/env python3
"""Compile actual collection and application methods against a fake item/DB world."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[2]
source = (root / 'src/server/game/CustomTransmogrification/CustomTransmogrification.cpp').read_text(encoding='utf-8-sig')
a = source.index('namespace\n{\nbool IsCollectibleAppearance')
b = source.index('\n#ifdef PRESETS', a)
code = source[a:b]
a = code.index('void Transmogrification::CollectInventory(')
b = code.index('TransmogTrinityStrings Transmogrification::TransmogrifyAppearance(', a)
code = code[:a] + code[b:]
with tempfile.TemporaryDirectory(prefix='transmog-collection-test-') as directory:
    directory = Path(directory)
    (directory / 'collection-under-test.inc').write_text(code)
    ui = (root / 'src/server/scripts/World/transmog_scripts.cpp').read_text(encoding='utf-8-sig')
    start = ui.index('    void ShowTransmogItems(')
    end = ui.index('\n};', start)
    (directory / 'menu-under-test.inc').write_text('struct Menu {\n' + ui[start:end] + '\n};\n')
    subprocess.run(['c++', '-std=c++17', '-Wall', '-Wextra', '-Werror', '-pthread',
                    '-I', str(directory), str(Path(__file__).with_name('regression.cpp')),
                    '-o', str(directory / 'test')], check=True)
    subprocess.run([str(directory / 'test')], check=True, timeout=10)
