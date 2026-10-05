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

## Scarlet Halls exit recurrence (2026-10-03)

`Errors/2026-10-03 11.38.56 Crash - 14812.txt` reports another build 18414
access violation. Image base `0x00007FF641C40000` and fault address
`0x00007FF64240A3CB` again give RVA `0x7CA3CB`, matching the September teardown
failure. The next caller is at RVA `0xE73640`, also matching that cleanup path.
`gx.log` records `D3D11 Device Destroyed` at 11:38:56.618, approximately 74 ms
before the crash at 11:38:56.692. The report lists no loaded addons. The server
later completed all four filler-bot cleanup operations and halted normally.

This report predates the first Scarlet Halls progression build installation
(11:45), and does not establish that the bucket mechanic caused the crash.
It establishes the same client teardown failure, not its original corruption
source. No speculative network packet or client binary patch was made.

With the game closed, the active client's `WTF/Config.wtf` was backed up to
`WTF/Config.before-exit-crash-20261003-115446.wtf` and only `gxApi` was changed
from `D3D11` to `D3D9`. The reverse replacement was compared with the original
text to verify no other setting changed. The dump, text report and relevant
logs are preserved in `Build/scarlet-halls-audit/client-exit-20261003`.

This is a reversible workaround and diagnostic comparison, not a verified crash
fix. Repeat the same dungeon entry/combat/leave/game-exit sequence with D3D9.
If it still crashes, compare the new report's relative fault address and graphics
shutdown log before making further changes.

## D3D9 retest still crashes (2026-10-03 13:07)

The user repeated dungeon entry followed by logout/game exit in another dungeon.
The corresponding server log records bot preparation on map 1004 (Scarlet
Monastery), followed by all four bot cleanup completions and normal server
shutdown. This recurrence is not confined to the Scarlet Halls script.

`2026-10-03 13.07.58 Crash - 22448.txt` again reports `_Wow-64.exe`, build 18414,
image base `0x00007FF641C40000`, and fault `0x00007FF64240A3CB` (RVA `0x7CA3CB`).
The invalid read is from `0x000000006E92CA80`. The caller remains RVA `0xE73640`
inside graphics-resource list cleanup during exit callbacks. No addons were
loaded. Both the saved config and the D3D9 device initialization in `gx.log`
confirm that this run used D3D9. Therefore switching from D3D11 to D3D9 did not
resolve the crash; it must no longer be presented as a successful workaround.

The loaded-module list includes NVIDIA `nvspcap64.dll` and `nvppex.dll`, but
their presence alone does not establish responsibility for the invalid pointer.
The immediate fault still does not identify the operation that first damaged
or invalidated the resource list. Neither a driver fault nor malformed server
data has been proven.

Crash text/dump, graphics/connection logs, server log, and both local x64 client
executable hashes are preserved under
`Build/scarlet-halls-audit/client-exit-20261003-130758`. No executable patch or
additional graphics-setting change was applied. The next requested isolation
test is to start the same client and exit from the login screen without logging
into an account. A reproduction there would demonstrate that the failure can
occur without a world-server session; a clean exit there would leave the
world-entry/exit path under investigation.

## Isolation results and logout response regression (2026-10-03)

The user subsequently confirmed two clean exit cases with the same client:
exit directly from the login screen, and character login/logout in the ordinary
world without joining a dungeon or bot group. The reproduced failure therefore
currently requires more than merely starting the client or entering the world.
Dungeon travel and the managed group lifecycle remain relevant differences;
these comparisons alone do not distinguish between them.

The logout audit found a separate, concrete wire-format regression in
`WorldPackets::Character::LogoutResponse::Write()`. Commit `c8a926633ccc8701ff7661fd3b403b36ff5edf69`
(2024-06-16) moved serialization out of `HandleLogoutRequestOpcode`, changing
the original `WriteBit(instantLogout); FlushBits();` into `uint8(Instant)`.
Both the pre-refactor implementation and the local SkyFire 5.4.8 implementation
write the reason first and then the MSB-first flag. The repair restores that
encoding: an accepted instant response is `00 00 00 00 80`, rather than
`00 00 00 00 01`. The opcode remains `0x008F`, payload length five bytes.
This common server serializer serves both client architectures.

`contrib/logout_protocol_548/test.ps1` links the actual built game/shared
libraries and verifies opcode, size, and exact payload for ten combinations of
reason and instant flag. All cases pass. A separate local negative-control
build using the old production serializer fails the accepted-instant case,
confirming the test catches this regression. The x64 RelWithDebInfo game build,
staged worldserver link, and executable `--version` check pass.

After the user stopped worldserver, the staged executable/PDB were installed
and hash-verified; the previous pair is backed up in
`Build/server-before-logout-response-20261003-134633`. An isolated localhost
startup on port 18086 initialized the world in 23 seconds with an empty
`DBErrors.log`, then received `server shutdown 0`. Logs are under
`Build/logout-response-smoke`. The normal server config was not modified.

This repair is **not yet a demonstrated fix for the graphics teardown crash**.
The user's clean ordinary-world logout is an additional reason not to equate
the packet defect with the dungeon-specific reproduction. Repeat the failing
dungeon/leave/logout/exit sequence with the installed build. If it persists,
capture the world packet sequence and isolate dungeon travel from bot-group
cleanup before changing another packet or graphics setting.

## Post-fix dungeon reproduction (2026-10-03 18:16)

The user entered a dungeon, left it, then logged out and reproduced the crash.
`2026-10-03 18.16.51 Crash - 17964.txt` again reports RVA `0x7CA3CB` with the same
exit cleanup stack; this time the invalid read address is `0x6DD735D0`. The
installed worldserver SHA-256 matches the staged logout-response build
(`856E199992F4C41A1C7A87FE5E141817DD528DDE73A0F20B79293B77AAF28F82`).
The client still selects D3D9. Thus the packet-format repair did **not** resolve
the reported crash.

The server log again records map 1004 and four managed LFG bots, all of which
completed cleanup before normal server shutdown. It lacks a detailed packet
timeline, so it cannot establish whether group removal, teleport, an object
update, or another operation is responsible. Crash dump/text and logs are
preserved in `Build/scarlet-halls-audit/client-exit-20261003-181651`.

With worldserver stopped, only `PacketLogFile` in the local active config was
temporarily changed to `client-exit-diagnostic-20261003.pkt`; the original config
is backed up in `Build/client-exit-trace-20261003/worldserver.before.conf`.
The next server run will capture actual client/server packets in PKT 3.1 format.
The capture and backup stay local. The local `read_trace.ps1` summarizes the
relevant opcodes and timing; its header/payload/timestamp reader was checked with
a synthetic logout-response record. `disable_trace.ps1` restores just that
setting, preserving unrelated configuration edits. After the reproduction,
archive the capture before another server start (the logger opens it with `wb`)
and disable capture. No further speculative protocol or executable patch has
been made during this investigation step.

## Captured stale quest-object updates after LFG leave (2026-10-05)

The 14:31:41 crash (PID 1160) is again the same graphics teardown fault at RVA
`0x7CA3CB`. The server remained running. Its live packet capture, crash text/dump,
and logs were archived under `Build/client-exit-trace-20261005-143141` before
further server restarts. The user also tested direct solo travel into Scarlet
Halls with `.go xyz`, `.recall`, logout, and game exit: **no crash** without the
LFG group. This supports investigating the group-leave path rather than dungeon
loading alone.

The captured packet sequence exposes a concrete defect:

- Record 2485: `CMSG_GROUP_DISBAND`, 117.339 seconds into the capture.
- Record 2513: `SMSG_NEW_WORLD` moves the client from map 1001 to map 870.
- Record 2516: `SMSG_UPDATE_OBJECT` still names map 1001 and contains eight
  values-update blocks, after the client has been told to leave that map.
- Records 2528-2535: eight `CMSG_OBJECT_UPDATE_FAILED` messages for exactly those
  eight GUIDs. The same GUIDs recur at records 2766-2773. Five are Bucket of Meaty
  Dog Food creatures (entry 65379); three are gameobjects. The complete 598-byte
  stale packet decodes into those eight blocks without trailing bytes.
- At 141.231 seconds the client requests logout. The response is the corrected
  `00 00 00 00 80`, followed by an empty `SMSG_LOGOUT_COMPLETE`. The client then
  requests the character list and disconnects. The earlier packet repair is
  active, but did not resolve this dungeon reproduction.

The six captured group-list packets were also consumed exactly using the
[WPP 5.4.8 group parser](https://github.com/TrinityCore/WowPacketParser/blob/master/WowPacketParserModule.V5_4_8_18291/Parsers/GroupHandler.cs)
with a local byte-reader adapter; no length mismatch was found there.

`LFGGroupScript::OnRemoveMember` teleports the leaving player before
`Group::RemoveMember` calls `Player::UpdateForQuestWorldObjects`. During this
interval the player is out of the world but still has its old map/visibility
cache, which is reset on destination-map entry. The quest refresh previously
walked that cache and sent old-map values after `SMSG_NEW_WORLD`. It now returns
when `!IsInWorld()`, matching the protection already used by
`UpdateTriggerVisibility`. Normal in-world quest refresh remains enabled.

`contrib/logout_protocol_548/test_quest_visibility.ps1` compiles the production
function body with narrow engine doubles. It checks transfer-time suppression,
ordinary refresh of three gameobjects/five spell-click creatures, and empty
visibility. All pass; a negative control with the old guard fails by accessing
the old map. The x64 game build and worldserver link succeeded. After the user
stopped worldserver, the executable/PDB were installed with backup in
`Build/server-before-logout-response-20261005-144159`. The isolated startup took
24 seconds, with an empty DB error log, and was shut down normally.

The stale-packet defect is established; eliminating the exit crash still needs
the same LFG reproduction on this build. A separate next-run capture is enabled
locally as `Logs/client-exit-quest-visibility-20261005.pkt` to verify both the
absence of old-map values/failed-object responses and the gameplay outcome.
Disable `PacketLogFile` again after preserving that test capture.
