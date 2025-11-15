# AwavePuzz

Co-op wave-based zombie survival prototype for Roblox. This repository mirrors the
code/scripts that should be pasted into Studio while following the instructions
from `Custom_instructions.md`.

## Phase 1 – Core Loop

### Scope
* ServerScriptService
  * `GameManager.server.lua` controls countdowns, waves, base health, and
    broadcasts to UI through RemoteEvents.
  * `Spawner.lua` (module) spawns configured zombie archetypes and wires them to
    the shared AI behaviour.
  * `AIScripts/ZombieBrain.lua` moves zombies toward the capture zone and
    triggers base damage pulses when in range.
* ReplicatedStorage
  * `Shared/Config.lua`, `Shared/ZombieTypes.lua`, and `Shared/WaveConfig.lua`
    expose tunable values and wave definitions used throughout the server.
* StarterGui
  * `WaveUI.client.lua` listens to wave updates and shows the current wave,
    zombies alive, timer, and base health.

This phase only focuses on the wave cadence and base pressure. Damage, weapons,
alliances, and the cure system will arrive in later phases.

### Manual Studio Setup
1. **Base capture zone** – add a part named `BaseCaptureZone` (anchor it) inside
   `Workspace`. This is the object zombies will move toward and attack.
2. **Zombie models** – create `ServerStorage.ZombieModels` and add the template
   models named `Walker`, `Runner`, `Brute`, `Spitter`, and `Boss`, each with a
   `Humanoid` + `HumanoidRootPart`.
3. **Spawn points** – add a folder `Workspace.ZombieSpawns` containing multiple
   parts at the edges of the arena (the spawner randomly chooses among them).
4. **Workspace folders** – the scripts automatically create `Workspace.Zombies`
   to hold live zombie instances as waves run.

### Running the loop
1. Drop these scripts into the matching services/folders in Studio.
2. Press Play; after the short "Prepare" countdown, wave 1 begins.
3. Watch the `WaveStatusGui` for live wave/time/zombie/base info.

Future phases will extend these systems with weapons, cure crafting, alliances,
and additional UI.
