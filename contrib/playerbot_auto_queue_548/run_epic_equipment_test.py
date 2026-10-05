#!/usr/bin/env python3
"""Compile production upgrade/durability functions against inventory fixtures."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]

def function(path, signature):
    source = (root / path).read_text()
    start = source.index(signature)
    end = source.index('{', start) + 1
    depth = 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]

with tempfile.TemporaryDirectory(prefix='bot-epic-gear-') as directory:
    for name, path, signature in [
        ('epic_equipment', 'modules/mod_playerbots/src/Factory/BotFactory.cpp',
         'void BotFactory::UpgradePveEquipment()'),
        ('durability', 'src/server/game/Entities/Player/Player.cpp',
         'void Player::DurabilityPointsLoss(Item* item, int32 points)'),
    ]:
        fixture = Path(__file__).with_name(name + '_regression.cpp').read_text()
        source = Path(directory) / (name + '.cpp')
        source.write_text(fixture.replace('// PRODUCTION', function(path, signature)))
        binary = Path(directory) / name
        subprocess.run(['c++', '-std=c++17', '-Wall', '-Wextra', '-I', str(root),
                        str(source), '-o', str(binary)], check=True)
        subprocess.run([str(binary)], check=True)
        print(name + ': passed')
