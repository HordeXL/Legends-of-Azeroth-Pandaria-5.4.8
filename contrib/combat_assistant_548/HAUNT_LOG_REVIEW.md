# Single-target Haunt review, 2026-09-09

Reviewed Grotroz's local combat-log window 16:09:15.609–16:11:52.369,
against one Training Dummy. The initial Soul Shard balance is not recorded:
the advanced resource fields are zero, so they must not be read as an actual
zero balance. Counts below use successful casts and power-type-7 energizes.

- 16 Shadow Trance energizes, each granting one shard.
- 16 successful Haunts and two Soulburns, each costing one shard.
- No recorded Drain Soul, Seed refund, Dark Refund or other shard energize.

Replaying those events from every possible initial whole-shard balance (0–4),
discarding impossible negative balances and applying the four-shard cap,
leaves **0–1 shards** after the Haunt cast at 16:11:27.823. No additional shard
gain is logged until 16:11:42.042. Starting at four shards instead gives one
remaining shard in that gap, after accounting for a gain wasted at the cap.
This is a reconstruction assuming no unlogged resource changes, not a direct
measurement of the player's resource bar.

| Time | Event |
| --- | --- |
| 16:11:27.823 | Previous Haunt cast succeeds; reconstructed balance 0–1 |
| 16:11:28.839 | Haunt arrives |
| 16:11:36.655 | Haunt expires |
| 16:11:42.042 | Shadow Trance grants one shard |
| 16:11:42.207 | Next Haunt cast starts |
| 16:11:42.886 | Cast succeeds |
| 16:11:43.933 | Haunt arrives |

The 7.278-second aura gap coincides with a resource shortage or the policy's
last-shard reserve outside Dark Soul/execute. The next cast starts 165 ms after
the resource proc. Keep the reserve: this log does not establish that removing
it improves total damage or later burst availability.

Two independently verified scheduling issues are fixed:

1. Refresh lead previously counted cast time plus 500 ms, but omitted missile
   flight. The observed Haunt flight is about one second. Include target
   distance divided by spell speed, matching the existing pending-cast guard.
2. Optional Pandemic refreshes and new Soulburn setup preceded due Haunt.
   Prefer an affordable due Haunt when none of the maintained DoTs is urgent,
   while preserving already prepared Soulburn and the four-target Seed policy.

Regression coverage checks ranged timing, optional refresh/setup ordering,
urgent primary and secondary DoTs, prepared Soulburn, Seed, unavailable Haunt
fallback, and 0/1/2-shard decisions. Existing channel tick protection and
duplicate-projectile suppression remain in place. A new in-game log is needed
to measure the change in Haunt uptime and DPS; no gain is claimed from replay.
