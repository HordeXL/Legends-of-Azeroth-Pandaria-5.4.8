# GM class spell commands

Both commands require GM access and operate on the issuing player, regardless
of the selected target. They are not commands to run on a selected player/bot.

```text
.learn all my class
.unlearn all my class
```

`learn` restores native class-skill rewards, learns the class spell list and
**all 18 own-class talents**, and restores the active specialization's spells.
This preserves the historical GM all-talents behavior; it is not a normal PvE
talent build. Other-class talents are excluded using Talent.dbc ownership.

`.learn all my spells` restores level-appropriate baseline class-skill spells
and the **active specialization's spells**, including generic-family and
level-zero passives. It does not add, remove or select talents in either spec.
Direct talent spells are excluded even when present in baseline skill data
(e.g. Hunter Intimidation and Paladin Sacred Shield). No specialization spells
are granted when no specialization is selected. Existing extra spells from
earlier GM commands are not removed by this learning command.

`unlearn` identifies known class spells through class-skill masks,
specialization ownership and talent ownership, using the class spell family
only as a fallback for internal class spells. This includes generic-family
abilities such as Warlock Pandemic/Soul Shards and Death Knight Path of Frost,
as well as generic-family talents such as Warlock Soul Link. Explicit ownership
by another class takes precedence over a coincidental family match.
Talent records are cleared in both specs, affected active action buttons are
cleaned, and changes are saved. The command refuses to run in combat. It keeps
specialization selection, glyph unlocks, and non-class skills such as racial
abilities, professions, languages, riding and companions. Normal automatic
class-skill/spec learning on login, level-up or spec switch still applies: this
is not a permanent class-disable feature.

The ordinary `.unlearn <spell ID or link> [all]` command still operates on the
selected player. The new class command deliberately does not remove foreign
class spells: cleaning damage from an old buggy command requires a targeted
audit, not removing every spell outside the player's spell family.

Automated ownership regression (run from a Visual Studio developer shell):

```powershell
./contrib/class_commands_548/test_class_ownership.ps1
```

The test runs the production selection policy against the local 5.4.8 DBCs
for all 11 classes: every talent, every available player specialization spell,
and shared skill/glyph/mount exclusions. It includes regressions for generic
spell families, shared class abilities and DK's flying mount. The learning
policy is also checked for all 34 player specs at levels 1, 10 and 90, excluding
every talent and inactive-spec spell and covering Affliction's core abilities.
This validates
spell selection, not live character state transitions. One stale Affliction
specialization record references missing spell 117197 and is skipped, matching
the core's missing-spell handling.

Manual validation on a disposable GM character:

1. Record the spellbook, glyph unlocks, professions, racial abilities and both
   talent specs; select a different player to verify that `my` still means self.
2. Run `learn` twice. Verify own-class spells, active spec spells and own-class
   talents; no Hunter talents should appear on a Warlock.
3. Run `unlearn` twice outside combat. Verify own-class spells/talents are
   removed, shared skills and glyph unlocks survive, and the selected other
   character is unchanged. Check both saved talent specs.
4. Run `learn` again. On Affliction verify Agony, Unstable Affliction, Malefic
   Grasp, Drain Soul, baseline spells and passives. Choose a normal talent build
   before using this test character for ordinary PvE.
5. Verify `.unlearn <ID> all` still works and class-unlearn is refused in combat.
6. With a normal six-talent build, run `.learn all my spells` twice. Verify both
   saved talent maps are unchanged, active-spec spells are restored, and no
   talents or inactive-spec abilities are newly granted. Repeat below level 90.
