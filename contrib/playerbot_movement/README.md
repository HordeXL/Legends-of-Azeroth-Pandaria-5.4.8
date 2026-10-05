# Continuous playerbot following

`MovementAction::Follow` previously tested a `FOLLOW_MOTION_TYPE` generator
with `ServerFacade::GetChaseTarget`, which only handles `CHASE_MOTION_TYPE`.
The duplicate-follow guard therefore never matched. Each eligible AI decision
called `MoveFollow` again; MotionMaster replaced the existing generator and
restarted its path. The guard also ran after spell interruption.

The new `GetFollowTarget` reads the proper player/creature follow generator.
A request to keep following the same target now returns before interrupting
spells or submitting movement. The active generator continues tracking the
moving leader. New targets and transitions out of chase still submit follow.
Pathfinding, collision checks, movement speed and reaction settings are unchanged.

Run `python3 contrib/playerbot_movement/run_follow_test.py`. The regression
compiles the production lookup and movement-submission code. It verifies that
200 repeated decisions preserve one follow command and do not stop spells,
while retargeting, chase transitions and creature lookup remain functional.
A worldserver build checks integration; movement smoothness needs a live-client
check in The Slave Pens after installation and restart.

## Group formation

Outside combat, living followers in the master's group use stable slots ordered
by GUID within their role. Tanks stand five yards ahead of master; other members
stand four yards behind, with three yards between slots and rows. The destination
rotates with master's orientation. Collision checks reduce the offsets in tight
spaces, falling back to master's position if no offset is valid. Existing combat
movement, spellcasting, battlegrounds and world-boss staging keep their own rules.

Run `python3 contrib/playerbot_movement/run_group_formation_test.py` for the
production eligibility and destination checks. In game, verify a five-player
party while moving, turning, stopping and passing through doorways; verify that
combat positioning takes over when either master or the bot enters combat.
