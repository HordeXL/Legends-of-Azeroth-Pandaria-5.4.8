#!/usr/bin/env python3
"""Exercise production named-target registration, qualification and RS trigger."""
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


fixture = Path(__file__).with_name('raid_target_regression.cpp').read_text()
named_context = 'modules/mod_playerbots/src/strategy/NamedObjectContext.h'
value_context = 'modules/mod_playerbots/src/strategy/value/ValueContext.h'
for marker, path, production_marker, suffix in (
    ('// QUALIFIED', named_context, 'class Qualified', ';'),
    ('// FACTORY', named_context, 'template <class T>\nclass NamedObjectFactory', ';'),
    ('// TARGET_CLASS', 'modules/mod_playerbots/src/strategy/value/TargetValue.h',
     'class FindTargetValue', ';'),
    ('// TARGET_FACTORY', value_context, 'static UntypedValue* find_target', ''),
    ('// TARGET_CALCULATE', 'modules/mod_playerbots/src/strategy/value/TargetValue.cpp',
     'Unit* FindTargetValue::Calculate()', ''),
    ('// TRIGGER_CALCULATE', 'modules/mod_playerbots/src/strategy/raids/rubysanctum/RSTriggers.cpp',
     'bool RsBaltharusAvoidFrontTrigger::IsActive()', ''),
):
    fixture = fixture.replace(marker, block(path, production_marker) + suffix)

registration = next(line for line in (root / value_context).read_text().splitlines()
                    if 'creators["find target"]' in line)
fixture = fixture.replace('// TARGET_REGISTRATION', registration)
macro = next(line for line in (root / 'modules/mod_playerbots/src/Playerbots.h')
             .read_text().splitlines() if line.startswith('#define AI_VALUE2('))
fixture = fixture.replace('// AI_VALUE_MACRO', macro)

with tempfile.TemporaryDirectory(prefix='raid-target-') as directory:
    source = Path(directory) / 'test.cpp'
    binary = Path(directory) / 'test'
    source.write_text(fixture)
    subprocess.run(['c++', '-std=c++17', '-Wall', '-Wextra', '-Werror',
                    '-fsanitize=address,undefined', '-fno-omit-frame-pointer',
                    str(source), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
