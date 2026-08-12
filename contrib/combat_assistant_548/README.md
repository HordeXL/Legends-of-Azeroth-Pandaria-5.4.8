# Combat Assistant 5.4.8

This is an isolated, reversible prototype of a modern single-button assistant
for the 5.4.8 client. Patch 0001 supports Retribution Paladin only.

## Safety boundary

- The client addon only displays the server recommendation and sends one
  `.combatassist cast` request for each physical click/key press.
- The server chooses from a hard-coded Retribution whitelist. The client cannot
  request an arbitrary spell ID.
- Every spell uses the normal non-triggered spell path. GCD, cooldown, known
  spell, resource, target, range, facing, immunity and line-of-sight checks stay
  active.
- There is no timer-driven automatic casting. Healing is considered only by
  the explicit sub-15% instant-heal emergency rule below.
- The feature defaults to disabled with
  `AiPlayerbot.CombatAssistant.Enabled = 0`.

## Retribution priority

1. For hard loss of control, a Human uses Every Man for Himself first; Divine
   Shield is the fallback if the racial is unknown or unavailable.
2. At less than 15% health, an instant self-heal: Eternal Flame, Word of Glory,
   or Flash of Light only when three-stack Selfless Healer makes it instant.
3. Hand of Freedom for root or movement slow.
4. Rebuke when the hostile target is casting an interruptible spell.
5. Cleanse when the Retribution Paladin has a removable poison or disease.
   Harmful magic is not selected because magic dispel requires Holy's Sacred
   Cleansing capability in this client version.
6. Inquisition when at least three Holy Power (or Divine Purpose) is available
   and the buff is absent.
7. A flashing/free Divine Crusader Divine Storm proc.
8. Execution Sentence, when learned and usable.
9. Hammer of Wrath, when usable.
10. Templar's Verdict at three Holy Power or with Divine Purpose.
11. Art of War Exorcism.
12. Crusader Strike, Judgment, then Exorcism as builders.

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

The source copy in this directory is intended to remain tracked in Git so the
matching addon is never lost when the server patch is moved to another machine.
