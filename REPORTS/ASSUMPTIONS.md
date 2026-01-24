# AwavePuzz - Assumptions & Design Decisions

**Document Version:** 1.0  
**Generated:** 2026-01-24  
**Purpose:** Document assumptions made during the comprehensive audit

---

## 1. Map Positioning

### Assumption: Maps Load at (5000, 0, 0)

**Evidence Found:**
- `MapManager.lua` line 22: `local MAP_PIVOT_POSITION = Vector3.new(5000, 0, 0)`
- `pivotMapModelTo()` function explicitly positions maps at this coordinate
- Comments confirm this is intentional

**Validation:**  
✅ **CONFIRMED** - Maps consistently load at (5000, 0, 0) using `:PivotTo()` API.

**Implication:**  
All spawn positions, fallback coordinates, and positioning logic must account for this offset.

---

## 2. Server Initialization Order

### Assumption: MainServer.lua is Primary Entrypoint

**Evidence Found:**
- `MainServer.lua` is a Script (not ModuleScript) in ServerScriptService
- Contains all service initialization logic
- Runs automatically on server start

**Validation:**  
✅ **CONFIRMED** - MainServer.lua is the server entrypoint.

**Assumption: RemoteEventsBootstrap May Run in Parallel**

**Evidence Found:**
- `RemoteEventsBootstrap.lua` location and type not explicitly defined
- Services use `:WaitForChild()` to access RemoteEvents (defensive pattern)
- No explicit ordering mechanism

**Validation:**  
⚠️ **UNCONFIRMED** - Need to check if RemoteEventsBootstrap is a Script or ModuleScript.

**Recommendation:**  
Make RemoteEventsBootstrap a ModuleScript called explicitly from MainServer.lua to guarantee order.

---

## 3. Spawn Point Structure

### Assumption: Maps Have Standard Spawn Point Folders

**Evidence Found:**
- MapValidator checks for folders: `ZombieSpawnPoints`, `ResourceSpawns`, `ItemSpawns`
- Code expects BasePart children as spawn points
- Minimum 8 zombie spawn points required

**Validation:**  
✅ **CONFIRMED** via MapValidator.lua

**Assumption: Spawn Points are BasePart Instances**

**Evidence Found:**
- `collectPointsFromFolder()` in MapManager checks `point:IsA("BasePart")`
- Also supports Attachments and Models with PrimaryPart
- Uses `.Position` or `.WorldPosition`

**Validation:**  
✅ **CONFIRMED** - Multiple spawn point types supported.

---

## 4. Player Lifecycle

### Assumption: Character Can Be Nil or Removed Mid-Operation

**Evidence Found:**
- Multiple `Character.Parent` checks added during audit
- Player disconnect handled in `PlayerRemoving` event
- Character respawn creates new Character instance

**Validation:**  
✅ **CONFIRMED** - Roblox standard behavior.

**Implication:**  
All character interactions need validation that Character exists and is parented.

---

## 5. Service Dependencies

### Assumption: GameManager is Hub Service

**Evidence Found:**
- GameManager.new() creates 12+ sub-services
- Cross-service linking happens in MainServer.lua after all services created
- GameManager provides getters for services (getPlayerManager, getSpawner, etc.)

**Validation:**  
✅ **CONFIRMED** - Hub-and-spoke architecture.

**Assumption: Services Can Be nil During Initialization**

**Evidence Found:**
- Optional wiring in MainServer.lua uses `pcall()` to safely access services
- FPSWeaponService cleanup has nil guard added
- Some services may fail to initialize without breaking others

**Validation:**  
✅ **CONFIRMED** - Defensive pattern used throughout.

**Recommendation:**  
Add more nil guards for service interactions to handle partial initialization failures.

---

## 6. AI Behavior

### Assumption: Zombies Always Have a Target

**Original Assumption:**  
❌ **INVALID** - Found bug where no targets (no players + no base) causes crashes.

**Fix Applied:**  
Added wander behavior when no valid targets exist.

**Assumption: Targeting Service Returns Valid Position**

**Evidence Found:**
- TargetingService can return `nil, nil` when no targets
- ZombieBrain calls `selectBestTarget()` assuming non-nil return
- Added fallback wander behavior during audit

**Validation:**  
⚠️ **PARTIALLY VALID** - Fixed during audit.

---

## 7. Spawn Queue Behavior

### Assumption: processSpawnQueue() Always Runs

**Original Assumption:**  
❌ **INVALID** - Queue can grow infinitely if processing stops.

**Fix Applied:**  
Added MAX_QUEUE_SIZE limit of 500 zombies.

**Assumption: Spawn Queue is FIFO**

**Evidence Found:**
- `table.insert(self.spawnQueue, zombieType)` appends to end
- `table.remove(self.spawnQueue, 1)` removes from front

**Validation:**  
✅ **CONFIRMED** - Queue is FIFO (First In, First Out).

---

## 8. Client Initialization

### Assumption: ClientController is Only Client Entrypoint

**Evidence Found:**
- `ClientController.client.lua` is single LocalScript in StarterPlayerScripts
- All other client logic is ModuleScript required by ClientController
- StarterGui UI files are all `.disabled`

**Validation:**  
✅ **CONFIRMED** - Single entrypoint pattern.

**Assumption: UI Modules Can Be Called Multiple Times**

**Original Assumption:**  
⚠️ **RISKY** - No guards prevent duplicate initialization.

**Fix Recommended:**  
Add initialization flags to prevent duplicate calls.

---

## 9. RemoteEvents Structure

### Assumption: All RemoteEvents Created on Startup

**Evidence Found:**
- RemoteEventsBootstrap creates 40+ events
- Services use RemoteEventUtil for consistent access
- `.txt` files in ReplicatedStorage/RemoteEvents define event names

**Validation:**  
✅ **CONFIRMED** - Centralized creation pattern.

**Assumption: RemoteEvents Folder Exists Before Services Need It**

**Original Assumption:**  
⚠️ **UNCERTAIN** - Race condition possible.

**Fix Applied:**  
Added `WaitForChild()` with timeouts when accessing RemoteEvents.

---

## 10. Zombie Spawning

### Assumption: Zombie Models Exist in ServerStorage

**Evidence Found:**
- Spawner clones from `ServerStorage.ZombieModels`
- ZombieTypes defines model names: Walker, Brute, Runner, Spitter, Boss
- Placeholders exist for missing models

**Validation:**  
✅ **CONFIRMED** - Standard asset location.

**Assumption: All Zombie Types Are Available**

**Evidence Found:**
- Placeholders suggest some models may be missing
- Code doesn't validate model existence before spawn attempts

**Validation:**  
⚠️ **UNCERTAIN** - May fail if models are missing.

**Recommendation:**  
Add validation that zombie models exist before attempting to spawn.

---

## 11. Configuration Files

### Assumption: GameConfig Defines All Tunable Parameters

**Evidence Found:**
- GameConfig.lua contains wave timing, spawn rates, damage values
- Other configs: WeaponConfig, MapConfig, WaveConfig, PuzzleConfig
- Services reference config values with fallbacks

**Validation:**  
✅ **CONFIRMED** - Centralized configuration pattern.

**Assumption: Config Files Are Always Available**

**Evidence Found:**
- All services require configs from Shared folder
- Original code used `WaitForChild()` without timeouts

**Validation:**  
⚠️ **CRITICAL** - Fixed during audit with timeouts.

---

## 12. Performance Assumptions

### Assumption: 50+ Zombies Can Run Simultaneously

**Evidence Found:**
- Spawn queue limit set to 500
- Each zombie has ZombieBrain with pathfinding
- AI Director scales composition by wave

**Validation:**  
⚠️ **UNCONFIRMED** - Needs performance testing.

**Recommendation:**  
Test with maximum zombie count (50+) to validate performance.

**Assumption: Pathfinding Doesn't Block Server**

**Evidence Found:**
- Pathfinding uses Roblox's built-in PathfindingService
- Async pattern with 0.4s repath interval
- Waypoint skipping reduces computation

**Validation:**  
⚠️ **UNCONFIRMED** - Needs stress testing.

---

## 13. Map Validation

### Assumption: Maps Require Minimum 8 Zombie Spawns

**Evidence Found:**
- MapValidator line 80-81 checks minimum spawn count
- Warning logged if below threshold
- Map rejected if validation fails

**Validation:**  
✅ **CONFIRMED** - Explicit validation in code.

**Assumption: Resource/Item Spawns Are Optional**

**Evidence Found:**
- ResourceSpawner/ItemSpawner warn if spawn points missing
- Changed to error during audit (no longer silent failure)

**Validation:**  
✅ **CONFIRMED** - But now errors instead of degrading gracefully.

---

## 14. Lobby & Matchmaking

### Assumption: Minimum 1 Player Required to Start

**Evidence Found:**
- MainServer.lua line 187: `minPlayers = 1` (fallback)
- GameConfig.MIN_PLAYERS_TO_START should define actual value
- Auto-start logic waits for player count

**Validation:**  
✅ **CONFIRMED** - Configurable minimum.

**Assumption: Lobby Transitions to PLAYING Automatically**

**Evidence Found:**
- GameManager state machine transitions via update loop
- LobbyManager handles countdown
- Manual start also possible

**Validation:**  
✅ **CONFIRMED** - Automatic transition exists.

---

## 15. Asset Placeholders

### Assumption: Assets Are Not All Implemented

**Evidence Found:**
- FPSAudioController uses `rbxassetid://0` for all sounds
- Zombie models have `_PLACEHOLDER.txt` files
- Weapon models also have placeholders

**Validation:**  
✅ **CONFIRMED** - Many assets are placeholders.

**Implication:**  
- Audio will not play (rbxassetid://0 fails)
- Some zombie types may not spawn
- Some weapons may have no models

**Recommendation:**  
Add fallback behavior for missing assets to prevent errors.

---

## 16. Data Persistence

### Assumption: No Persistent Data Storage

**Evidence Found:**
- No DataStoreService usage found in main code
- Achievements tracked in memory only
- Inventory/currency reset on disconnect

**Validation:**  
✅ **CONFIRMED** - Session-based data only.

**Implication:**  
Game is designed for single-session play without progression saving.

---

## 17. Mobile Support

### Assumption: Touch Controls Exist

**Evidence Found:**
- `TouchControlsUI.lua` module exists
- `ControlsTutorialUI.lua` includes mobile instructions
- InputActionRegistry handles multiple input types

**Validation:**  
✅ **CONFIRMED** - Mobile support implemented.

**Assumption: PC and Mobile Have Input Parity**

**Evidence Found:**
- ModalManager routes input based on device
- UI scales with UIScaleManager
- Touch controls overlay for mobile

**Validation:**  
✅ **CONFIRMED** - Designed for cross-platform play.

---

## 18. Multiplayer Considerations

### Assumption: Server-Authoritative for All Game Logic

**Evidence Found:**
- WeaponService validates damage on server
- FPSWeaponService tracks ammo server-side
- Client-side prediction for responsiveness only

**Validation:**  
✅ **CONFIRMED** - Server-authoritative design.

**Assumption: Up to 8 Players Per Server

**Evidence Found:**
- Game design documents mention 8-player cap
- No explicit limit in code found
- Roblox default supports more

**Validation:**  
⚠️ **UNCONFIRMED** - No enforced player cap in code.

**Recommendation:**  
Add MAX_PLAYERS check if 8-player limit is required.

---

## 19. Error Handling Philosophy

### Original Assumption: Silent Failures Are Acceptable

**Evidence Found:**
- Many systems used `warn()` for critical errors
- Fallback values like `Vector3.new(0, 10, 0)` used

**Fix Applied:**  
Changed to `error()` for critical failures to fail fast.

**New Philosophy: Fail Fast and Loud**

**Rationale:**
- Infinite yields worse than clear errors
- Silent failures hide bugs
- Loud failures force fixes

---

## 20. Testing Assumptions

### Assumption: No Automated Tests Exist

**Evidence Found:**
- No test files found in repository
- DevOnly/ contains manual test scripts
- Testing relies on Roblox Studio manual play

**Validation:**  
✅ **CONFIRMED** - Manual testing only.

**Implication:**  
Bugs must be caught through playtesting and code review.

---

## Summary of Assumptions

| # | Assumption | Status | Impact |
|---|------------|--------|--------|
| 1 | Maps at (5000, 0, 0) | ✅ Confirmed | Fixed spawn position bugs |
| 2 | MainServer is entrypoint | ✅ Confirmed | Clear initialization order |
| 3 | Standard spawn folders | ✅ Confirmed | Validation possible |
| 4 | Character can be nil | ✅ Confirmed | Added safety checks |
| 5 | GameManager is hub | ✅ Confirmed | Central orchestration |
| 6 | Zombies always have target | ❌ Invalid | Fixed with wander behavior |
| 7 | Queue always processes | ❌ Invalid | Fixed with size limit |
| 8 | ClientController only entry | ✅ Confirmed | Single init point |
| 9 | RemoteEvents on startup | ✅ Confirmed | Race condition fixed |
| 10 | Zombie models exist | ⚠️ Uncertain | May need validation |
| 11 | Configs always available | ⚠️ Critical | Fixed with timeouts |
| 12 | 50+ zombies perform well | ⚠️ Unconfirmed | Needs testing |
| 13 | Min 8 zombie spawns | ✅ Confirmed | Explicit validation |
| 14 | Min 1 player to start | ✅ Confirmed | Configurable |
| 15 | Assets are placeholders | ✅ Confirmed | Fallback needed |
| 16 | No data persistence | ✅ Confirmed | Session-based design |
| 17 | Mobile support exists | ✅ Confirmed | Cross-platform ready |
| 18 | Server-authoritative | ✅ Confirmed | Secure by design |
| 19 | Silent failures OK | ❌ Invalid | Changed to fail fast |
| 20 | No automated tests | ✅ Confirmed | Manual testing only |

---

## Recommendations Based on Assumptions

1. **Add model existence validation** before spawning zombies
2. **Enforce MAX_PLAYERS** limit if 8-player cap is required
3. **Performance test** with 50+ zombies under load
4. **Add fallback behavior** for missing assets (sounds, models)
5. **Convert RemoteEventsBootstrap** to ModuleScript for explicit ordering
6. **Add automated tests** for critical systems (spawning, AI, damage)
7. **Create map validation tool** in Roblox Studio for content creators
8. **Document asset requirements** for community map makers

---

**End of Assumptions Document**
