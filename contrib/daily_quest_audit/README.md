# Daily quest audit — 2026-09-26

Read-only audit of the running server's world database and current source tree.
No character or account data was queried. The initial audit made no database changes. The follow-up repair described below
updates eight object templates and removes exactly four explicitly authorized
NYI blocker records after a private backup.

## Initial audit results

- 1,589 daily-flagged quest templates; 72 deprecated templates excluded.
- 1,517 non-deprecated templates (this does **not** mean 1,517 playable quests).
- Four quest IDs explicitly disabled as `NYI` (not yet implemented):
  - 32262 and 32636 — Captive Audience.
  - 32268 and 32628 — Tactical Mana Bombs.
- 362 distinct additional candidates missing ordinary quest starter/ender relations.
  - 350 lack a static starter; 325 lack a static ender. These counts overlap.
  - Known LFG rewards, placeholder/test titles and applicable automatic quest flags
    are excluded from these candidate checks.
- No missing objective templates, missing explicit prerequisite templates,
  self-prerequisites, impossible level ranges or contradictory same-faction
  reputation intervals were found by the implemented checks.
- 44 reputation ceilings are listed for manual review. A ceiling alone is not a bug.
- Nine daily quests have giver NPCs with both C++ scripts and SmartAI names.
  These are recorded separately, not counted as bugs: CreatureAISelector prefers
  the C++ AI, and the redundant SmartAI may implement already-covered behavior.

The four disabled quest IDs represent two titles with variants. Disabled status
is confirmed from `disables.sourceType=1`, checked against DisableMgr and the
player quest eligibility code. They are unavailable to ordinary players.

## Interpretation and limits

**This audit cannot establish the exact total of broken daily quests.** The 362
candidates are not confirmed failures. Old content, especially older Golden Lotus
quests, may be intentionally unavailable in 5.4.8 without a deprecated flag.
Dynamic quest grants and scripted turn-ins also need individual inspection.
Passing these checks does not prove that a quest works.

The audit does not simulate accepting, playing, completing or resetting every
quest. Combat events, vehicle movement, credit spells, item drops, phasing,
spawn availability, prerequisites through conditions, and daily pool selection
require further targeted inspection and in-game verification. Script name text
presence is only a heuristic, not validation of registration or runtime behavior.

The previously corrected Dark Skies requirements are already present in this
snapshot. The flight implementation still requires the installed matching build.

## Files and reproduction

- `findings.tsv`: individual findings with IDs and confidence labels.
- `report.json`: counts, findings and separate manual-review lists.
- `audit.py`: read-only SELECT queries and source scan.

Run from an environment with database access, supplying a private MariaDB defaults
file that selects the world database:

```bash
python3 contrib/daily_quest_audit/audit.py --defaults-file /private/world.cnf
```

Do not commit credential files. Output contains world content only.

## Repairs implemented after the audit

`2026_09_26_04_world_thunder_pvp_dailies.sql` and
`go_thunder_daily_objective` repair both faction versions of Captive Audience
(32262/32636) and Tactical Mana Bombs (32268/32628).

As a temporary gameplay fallback, accepting any of these four quests now grants
all of its objective credit immediately: 5/5 captives or all three bomb sites.
The quest becomes ready to turn in; rewards still require the normal turn-in.
The existing object interactions remain available for quests accepted before the
matching server build was installed. A newly accepted quest is required to trigger
the automatic credit.

- Rune prisons require the matching incomplete quest and a living captive within
  three yards. Empty prisons do not award credit. The captive despawns immediately
  using its existing respawn settings, preventing repeat-click/double-player credit.
- Each bomb site requires the matching incomplete quest, the provided bomb case,
  and an unfinished objective. The three different objectives must each be used.
  The Alliance bridge and crystal sites have distinct, verified geographic mappings.
- All interactions require a living player on map 1064 within interaction distance.
- Bomb objects use the correct quest ID for quest sparkle visibility.
- Existing daily pools and the faction's PvP daily choice requirements are preserved.
  These quests therefore remain subject to daily selection.
- Exactly four `disables` rows with sourceType=1 and comment NYI were removed after
  explicit user approval. No player records or spawns were removed.
- Backup: `.private-backups/thunder-dailies-20260926/` (not published).

Validation: the production interaction callbacks pass the fixture in `run_tests.py`
for all eight objects, both factions, duplicate clicks, empty prisons, objective
caps, and invalid player/item/quest/map/distance cases. The full worldserver build
with `make -j16` passes. SQL bindings and absence of all four blockers are verified.
All 11 Sunreaver and 18 Kirin Tor captives are within three yards of their prison
objects; the other two Sunreaver prisons are intentionally empty. Clean-install
world archive hashes and gzip integrity are verified. **Client testing is pending.**

## Remaining work / triage

`triage.tsv` covers all 366 original findings, including the four repaired IDs.
This is not a claim that all candidates are fixed:

- 4 implemented (client verification pending).
- 45 internal tracking titles: do not expose as ordinary NPC daily quests.
- 15 development/obsolete placeholders: do not activate blindly.
- 135 require version-specific review (mostly Golden Lotus and legacy battlegrounds).
- 41 belong to pet battle questing. The current PetBattle implementation handles
  wild opponents, not trainer teams; winning battles does not yet award trainer
  quest objectives. These need proper subsystem implementation and team data,
  not merely added questgiver links.
- 126 still require individual availability and objective-source verification.

The latter groups remain unfinished. The current `report.json`/`findings.tsv` are
post-repair structural audit results; `candidates.json` retains original candidate
world quest descriptions for reproducible manual review.

References used to verify behavior and version scope:

- [Blizzard: 5.4 destruction of the Vale](https://worldofwarcraft.blizzard.com/en-gb/news/10624922/patch-54-destruction-of-the-vale-of-eternal-blossoms)
- [Captive Audience, Alliance](https://www.wowhead.com/mop-classic/quest=32636/captive-audience)
- [Tactical Mana Bombs, Horde](https://www.wowhead.com/quest=32268/tactical-mana-bombs)
- [Tactical Mana Bombs, Alliance](https://www.wowhead.com/quest=32628/tactical-mana-bombs)
