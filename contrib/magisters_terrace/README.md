# Magisters' Terrace escape orb

Object 188173 casts spell 46841. The installed 5.4.8 SpellEffect.dbc supplies
only TARGET_DEST_DB for effect 0. The destination exists in spell_target_position
(map 530), but the destination LOS exemption in Spell::CheckEffectTarget requires
an explicit TARGET_UNIT_CASTER as well. The correction sets self as TargetA and
keeps the database destination as TargetB, matching the existing LOS exemption.

The correction applies to all difficulty spell stores. The escape object is
spawned with mask 6 (normal and heroic). No database change is required.

Run `python3 contrib/magisters_terrace/run_escape_test.py`. This compiles the
production correction and LOS exemption and checks that unrelated spells retain
their target handling. After installing/restarting worldserver, verify clicking
the orb teleports the player to Quel'Danas on both normal and heroic.

## Delrissa progression gate

Encounter completion now records Delrissa's death independently of corpse
availability and counts the four lackey deaths. Lackey engagement starts the
encounter, and repeated engagement notifications cannot reset the count. A failed
attempt clears both death states; completed encounters cannot be reset by late
creature callbacks. The gate restores its state when created after completion
or loading an instance save. The other progression doors use the same restoration
pattern. Database spawns already cover normal and heroic (mask 6).

Run `python3 contrib/magisters_terrace/run_delrissa_test.py`. It checks all five
positions of Delrissa in the kill order, repeated engagement, door loading and
wipe/retry. Historical saves that never recorded DONE cannot be reconstructed
from the saved encounter counters alone; verify with a fresh encounter if an
old instance remains blocked after upgrade.
