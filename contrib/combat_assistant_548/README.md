# Combat Assistant 5.4.8

This is an isolated single-button assistant for the 5.4.8 client. The current
tracked source supports every playable class and every MoP specialization.
Patch 0001 is retained as the historical Retribution-only first stage; the
live files in `modules/mod_playerbots/src/CombatAssistant.cpp` and
`addon/CombatAssistant548` are authoritative for the current implementation.

## Safety boundary

- The client addon only displays the server recommendation and sends one
  `.combatassist cast` request for each physical click/key press.
- The server alone chooses the recommendation from known spells for the
  character's active specialization. The client cannot request an arbitrary
  spell ID.
- Every spell uses the normal non-triggered spell path. GCD, cooldown, known
  spell, resource, target, range, facing, immunity and line-of-sight checks stay
  active.
- There is no timer-driven automatic casting. Every cast still requires one
  physical click or key press.
- The feature defaults to disabled with
  `AiPlayerbot.CombatAssistant.Enabled = 0`.

## Shared priority for all classes

The server reads the active specialization and known spell book on every
request. A selected MoP talent is therefore eligible only when that character
actually learned it; changing specialization or talents does not require an
addon profile change.

The common priority is:

1. Break hard loss of control with an available class/racial answer.
2. Use an emergency self-heal at critical health.
3. Use the first available class defensive during dangerous health loss.
4. Protect the lowest-health attacked group member with a class-appropriate
   external defensive when one exists.
5. Break roots/slows, interrupt an interruptible hostile cast, and cleanse a
   removable harmful effect with the dispel types available to the class.
6. For healer specializations, heal the lowest-health group member.
7. Prefer a learned active talent when it is useful and normally castable.
8. Continue the specialization's resource builder/spender, proc, DoT and core
   damage priority.

Damage recommendations dynamically switch between single-target and area
rotations. Tanks switch at two engaged enemies clustered within eight yards of
the selected target so they can establish group threat. Damage dealers switch
at three. In dungeon and raid groups, a damage dealer waits until every counted
enemy is attacking a living tank; neutral or unrelated nearby packs are not
counted. Ground-targeted area spells are placed on the selected enemy.

Direct ally spells are cast on the server-selected ally without changing the
player's selected hostile target. Normal range, line-of-sight, immunity,
cooldown, resource, GCD and arena restrictions remain authoritative; the
assistant never uses triggered casts to bypass them.

The all-class layer is mechanically build/start verified. Its individual
class/spec priorities, talent choices and edge-case crowd-control answers still
need gameplay verification before being treated as final tuning.

## Retribution-specific priority

1. For hard loss of control, a Human uses Every Man for Himself first; Divine
   Shield is the fallback if the racial is unknown or unavailable.
2. At less than 15% health, an instant self-heal: Eternal Flame, Word of Glory,
   or Flash of Light only when three-stack Selfless Healer makes it instant.
3. Divine Protection when at most 70% health after losing at least 20 percentage
   points of health during the current two-second damage window.
4. If Divine Protection is unavailable during that burst, Hand of Purity is
   offered for harmful periodic damage when that talent is learned; otherwise
   an absent Sacred Shield is offered when that talent is learned.
5. Hand of Protection on the lowest-health attacked group member at 25% health
   or below, when the normal spell checks allow it.
6. Hand of Freedom for root or movement slow.
7. Rebuke when the hostile target is casting an interruptible spell.
8. Cleanse when the Retribution Paladin has a removable poison or disease.
   Harmful magic is not selected because magic dispel requires Holy's Sacred
   Cleansing capability in this client version.
9. Inquisition when at least three Holy Power (or Divine Purpose) is available
   and the buff is absent.
10. A flashing/free Divine Crusader Divine Storm proc.
11. Execution Sentence, when learned and usable.
12. Hammer of Wrath, when usable.
13. Templar's Verdict at three Holy Power or with Divine Purpose.
14. Art of War Exorcism.
15. Crusader Strike, Judgment, then Exorcism as builders.

Hand of Protection uses its server-selected ally directly and does not alter the
player's selected hostile target. Lay on Hands is intentionally not in the
assistant whitelist, so arena restrictions cannot leave the assistant waiting
on an unusable Lay on Hands recommendation.

Normal cast-time healing remains manual. Only the explicit sub-15% instant-heal
emergency rule is included.

## Affliction PvE priority

Affliction has a dedicated player-controlled priority outside battlegrounds and
arenas. It also works solo on world training dummies. Bot rotations are separate.

- Read only this warlock's Agony, Corruption (aura 146739, cast spell 172), and
  Unstable Affliction. Refresh within the base-duration Pandemic window; without
  Pandemic, wait until the cast/GCD lead time. Player refresh checks do not use
  the pet-autocast rule that rejects an existing aura.
- Use Dark Soul: Misery during combat. Use learned Soulburn + Soul Swap to apply
  multiple needed DoTs. The two spells take separate physical presses, with
  action-bar overrides resolved through the same active auras as client casts.
- Reserve the last Soul Shard outside burst/execute, maintain Haunt when shards
  allow, and suppress duplicate Haunts while the previous cast/projectile is in
  flight. Display whole shards (the core stores 100 units per shard).
- Use Malefic Grasp above 20% and Drain Soul in the core's below-20% execute state.
  Repeated presses preserve the existing channel. Routine replacements wait
  until shortly after a tick; urgent DoTs, target changes and execute can pre-empt
  it. A replacement is validated before the channel is interrupted.
- Maintain DoTs on up to three engaged enemies. For four or more, prefer Seed,
  including its learned Soulburn version, while maintaining the primary DoTs.
  Do not overwrite an existing Seed: use damage to detonate it.
- Extra targets must already be engaged by the player/group. Dungeon/raid
  secondaries respect the shared three-second pull opening and tank collection.
  Seed also checks idle/CC neighbours in a conservative splash radius (at least
  15 yards). The scan cannot predict enemies entering the explosion later.
- Life Tap below 15% mana requires over 45% health; maintenance below 30% mana
  requires over 65% health. Moving casts respect the core's cast-while-walking
  auras, with Fel Flame as an available fallback.

Normal casts, including cooldown/resource/GCD/range/LoS checks, remain in effect.
Only a discarded recommendation probe may ignore an in-progress damage channel;
the actual replacement is always untriggered. Other channels remain manual.
Pet choice/control, trinket-proc snapshot optimization, target time-to-die
prediction, and normal Soul Swap inhale/exhale transfer are not automated by
this priority. These are not claims of theoretical maximum DPS.

### Training-dummy validation

1. Start the rebuilt server; use `/reload` if the client was open while the Lua
   file changed. Select Affliction and check `.combatassist status`. The usual
   `/ca548 bind2` binding continues to use the active specialization.
2. Enter `/combatlog` and confirm that logging is enabled. Hit one dummy for
   3–5 minutes using the assistant. Keep pet/talents/gear consistent between runs.
3. Separately test 2–3 nearby dummies after manually engaging each one. For Seed,
   engage at least four and ensure there are no untouched dummies in the splash
   radius. The assistant deliberately does not start those additional fights.
4. Stop combat and enter `/combatlog` again to disable/flush the log. Record the
   character name and approximate times for each segment.

The client writes `Logs/WoWCombatLog.txt`. Spell sequences, DoT uptime/ticks,
channel ticks, Haunt, Soulburn consumption, cooldown use and damage distribution
can be checked there. A never-dying dummy whose health stays high cannot validate
Drain Soul execute, kill-triggered shard returns, tank threat or raid mechanics.
Combat logs also do not prove optimal play across all gear/proc configurations.

Run `contrib/combat_assistant_548/test_affliction.ps1` from a VS x64 developer
PowerShell to test the actual production policy header. A server build validates
the spell-engine integration; gameplay still requires the recorded run above.

## Install

1. Apply/build the server changes and set
   `AiPlayerbot.CombatAssistant.Enabled = 1` in the active `playerbots.conf`.
2. Copy `addon/CombatAssistant548` into the 5.4.8 client's
   `Interface/AddOns` directory.
3. Enable `Combat Assistant 5.4.8` on the character-selection AddOns screen.
4. In Key Bindings, bind `Use recommended ability`, or click the displayed
   icon. Use `/ca548 unlock` to drag it and `/ca548 lock` afterward.

The addon creates its own button near the lower center of the screen. Nothing
has to be dragged from the spell book or placed on a normal action bar. The
optional Key Bindings entry only lets a keyboard key press the same addon
button. `/ca548 show` restores it if it was hidden.

Version 1.0.0 binds the recommendation button to key `2` once on login and
saves that WoW key binding. This replaces the action previously assigned to
`2`. Use `/ca548 bind2` to restore the binding or `/ca548 unbind2` to release
the key; binding changes must be made outside combat.

The source copy in this directory is intended to remain tracked in Git so the
matching addon is never lost when the server patch is moved to another machine.
