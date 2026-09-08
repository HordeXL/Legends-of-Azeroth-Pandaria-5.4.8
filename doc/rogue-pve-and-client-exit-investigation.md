# Rogue PvE repair and client exit investigation (2026-09-08)

## Rogue implementation

Antavo (GUID 63, Subtlety 261) had six first-column talents and glyphs
468/392/404/397/469/731. The inspected combat segment contained finishers but no
poison damage, Shadow Dance or Premeditation casts. The old non-combat poison
strategy referenced unregistered item-based actions instead of MoP self buffs.

Changes:

- Maintain Deadly Poison (2823) through normal spell casting in group PvE.
  Missing poison can be restored in combat; early refresh below one minute is
  restricted to out-of-combat time. No repeated full-duration refresh or item
  insertion is required. The obsolete, nonfunctional poison item nodes are removed.
- Use a supported PvE talent baseline: Shadow Focus, Nerve Strike, Cheat Death,
  Burst of Speed, Prey on the Weak, Anticipation. The generic scoring bonus for
  replacing Throw no longer outranks this explicit rogue PvE preference.
- Select major glyphs Feint, Cloak of Shadows and Sprint; minor glyphs Safe Fall,
  Poisons and Blurred Speed. They are utility/survival improvements, not invented
  direct damage bonuses. Existing glyph slot type/level checks remain in use.
- Subtlety uses Shadow Dance with Slice and Dice active, sufficient energy,
  room for combo points, a valid engaged melee target, and a position behind it.
  Premeditation and Ambush are registered and used during the appropriate window.
- Burst of Speed is available against an already-engaged out-of-melee target,
  with an energy reserve and without replacing an existing speed buff. It does
  not itself move the bot or bypass the existing movement/pull checks.
- The PvE Fan of Knives priority wins over the Subtlety builder only when the
  existing medium-AoE trigger confirms a nearby tank-controlled pack. The final
  area-spell safety check still protects unpulled enemies and crowd control.
- New triggers are group-PvE-only. PvP talent/glyph scoring explicitly excludes
  the newly registered PvE actions, and the previous PvP AoE priority remains.

The profile is applied during the next managed preparation, not by changing the
offline database spell rows manually. This is a supported baseline, not a claim
of optimal simulated DPS for every encounter or gear set.

Verification: full RelWithDebInfo worldserver build succeeded with zero compiler
warnings/errors; 34 isolated C++ checks using the production ability-trigger body
passed. Local DBCs contain the six selected talents and three major/three minor
glyphs with the expected slot types. In-game DPS, poison procs, and the complete
staging/rotation cycle still need a fresh combat-log test.

## Repeated client exit crash: evidence, not a completed fix

Crash reports under the client's `Errors` directory:

- `2026-09-07 16.56.03 Crash - 38904.txt`
- `2026-09-08 11.28.08 Crash - 32380.txt`

Both report build 18414 `_Wow-64.exe`, error 132, access violation on a read at
runtime address `0x00007FF7F122A3CB`. The September 8 image base is
`0x00007FF7F0A60000`, giving RVA `0x7CA3CB` (preferred VA `0x1407CA3CB`).

Local binary disassembly shows:

- `0x1407CA3A0` walks/unlinks a linked list. The faulting instruction at
  `0x1407CA3CB` is `mov rcx, qword ptr [rdx]`.
- Its caller `0x140E73630` cleans up the global list at `0x1411AA440`.
  The next stack frame is in exit-callback processing (`0x140A9403F`).
- A producer at `0x140115F00` allocates an object then inserts it in that same
  list. It passes the embedded source string `CGxDevice\CGxDevice.cpp`, line
  `0xB64`, to its allocator path. This ties the list to graphics device resources.
- The client config currently selects `gxApi "D3D11"`.
- The server log contains all 24 bot cleanup completions followed by normal
  `Halting process...`. This does not rule out earlier bad server data, but no
  offending packet has been demonstrated by this stack.

Conclusion: the immediate failure is an invalid linked-list pointer during
client graphics-resource teardown. The evidence does NOT yet establish which
operation corrupted/staled that pointer, prove a GPU-driver bug, or identify a
specific server packet to change. No client executable patch or speculative
server packet change was applied.

Next discriminating test: repeat LFR entry/combat/leave/exit with DirectX 9, then
compare with DirectX 11 under the same conditions. The user was asked before
changing that setting. Keep the original config backed up and use one game
instance for the test (another `_Wow-64.exe` process from September 7 was still
running during inspection). A successful D3D9 test would be evidence for a
workaround/path-specific trigger, not proof of a complete root-cause repair.
