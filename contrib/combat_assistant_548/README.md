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
