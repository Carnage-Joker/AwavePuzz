# AwavePuzz System Runtime Flow Diagram

**Document Version:** 1.0  
**Generated:** 2026-01-24  
**Purpose:** Detailed runtime flow from server boot to gameplay loops

---

## Runtime Flow Overview

```
SERVER BOOT
    ↓
[1] Service Initialization
    ↓
[2] Map Loading & Setup
    ↓
[3] Spawner Initialization
    ↓
CLIENT BOOT (per player)
    ↓
[4] UI Initialization
    ↓
[5] Gameplay Loops (concurrent)
```

---

## [1] SERVER BOOT → Service Initialization

### Phase 1A: MainServer.lua Execution

```
game.ServerScriptService.MainServer (Script)
    │
    ├─→ Load ReplicatedStorage:WaitForChild("Shared")
    ├─→ require(GameConfig)
    │
    ├─→ [SERVICE CREATION]
    │   │
    │   ├── AllianceServiceV2.new()
    │   │   ├── Create AllianceGraph
    │   │   ├── Create PoolCalculator
    │   │   ├── Create InventoryLedger
    │   │   ├── Create BetrayalService
    │   │   └── Setup remote events
    │   │       ├── RequestAlliance
    │   │       ├── RespondAlliance
    │   │       ├── BreakAlliance
    │   │       └── AllianceUpdate
    │   │
    │   ├── GameManager.new(allianceService)
    │   │   ├── Create BaseManager
    │   │   ├── Create PlayerManager
    │   │   ├── Create WeaponService
    │   │   ├── Create FPSWeaponService
    │   │   ├── Create FPSAnimationService
    │   │   ├── Create Spawner
    │   │   │   ├── Create TargetingService
    │   │   │   ├── Create SurroundService
    │   │   │   ├── Create AIDirector
    │   │   │   ├── Create BossAuraService
    │   │   │   └── Create IntelligentSpawnGenerator
    │   │   ├── Create ResourceSpawner
    │   │   ├── Create ItemSpawner
    │   │   ├── Create MapManager
    │   │   ├── Create MapValidator
    │   │   ├── Create WaveManager
    │   │   ├── Create ShopService
    │   │   ├── Create LobbyManager
    │   │   ├── Create PlayerSpawnManager
    │   │   └── Create SpectatorManager
    │   │
    │   ├── SprintService.new(playerManager)
    │   ├── CureService.new(gameManager, playerManager)
    │   ├── PuzzleService.new(cureService, playerManager)
    │   │
    │   ├── [CROSS-SERVICE LINKING]
    │   │   ├── cureService:setPuzzleService(puzzleService)
    │   │   ├── cureService:setAllianceService(allianceService)
    │   │   ├── allianceService:setPuzzleService(puzzleService)
    │   │   ├── allianceService:setCureService(cureService)
    │   │   ├── allianceService:setPlayerManager(playerManager)
    │   │   ├── allianceService:setGameManager(gameManager)
    │   │   ├── gameManager:setCureService(cureService)
    │   │   └── weaponService:setFPSWeaponService(fpsWeaponService)
    │   │
    │   ├── AchievementService.new(playerManager, gameManager)
    │   ├── FunFactService.new()
    │   └── CureSynthesisService.new(cureService, waveManager, gameManager)
    │
    ├─→ [EVENT HANDLERS]
    │   ├── Players.PlayerAdded:Connect(onPlayerAdded)
    │   └── Players.PlayerRemoving:Connect(onPlayerRemoving)
    │
    └─→ [GAME LOOP]
        └── RunService.Heartbeat:Connect(update)
            └── gameManager:update(deltaTime)
```

### Phase 1B: RemoteEventsBootstrap.lua (Parallel Execution)

```
game.ServerScriptService.RemoteEventsBootstrap (Script)
    │
    └─→ Create all 40+ Remote Events in ReplicatedStorage
        ├── WeaponFire
        ├── WeaponEquip
        ├── WeaponReload
        ├── AmmoUpdate
        ├── GameStateUpdate
        ├── WaveUpdate
        ├── CureUpdate
        ├── ... (37+ more)
        └── Done
```

**⚠️ RACE CONDITION RISK:** MainServer and RemoteEventsBootstrap run in parallel.  
**Current Mitigation:** Most services use `:WaitForChild()` when accessing RemoteEvents.

---

## [2] Map Loading & Setup

### Triggered by: GameManager state transition (WAITING → LOBBY → PLAYING)

```
GameManager:update(deltaTime)
    │
    ├─→ [STATE: WAITING]
    │   └── Wait for min players
    │       └─→ Transition to LOBBY
    │
    ├─→ [STATE: LOBBY]
    │   ├── LobbyManager:startLobby()
    │   ├── Wait for countdown or player ready
    │   └─→ Transition to PLAYING
    │
    └─→ [STATE: PLAYING]
        └─→ MapManager:loadMap(mapName)
            │
            ├── Unload existing map (if any)
            │
            ├── Load map from ServerStorage.Maps[mapName]
            │
            ├── Position map at (5000, 0, 0)
            │   └── map:PivotTo(CFrame.new(5000, 0, 0))
            │
            ├── MapValidator:validate(map)
            │   ├── Check for ZombieSpawns folder
            │   ├── Check for ResourceSpawns folder
            │   ├── Check for ItemSpawns folder
            │   ├── Check for BaseCamp location
            │   └── Count spawn points
            │
            ├── BaseCampSetup:setupBaseCamp(map)
            │   ├── Create or find BaseCamp model
            │   ├── Position at (5000, 0, 0) + offset
            │   ├── Set BaseCamp.Health attribute
            │   └── BaseManager:setBaseCamp(baseCampModel)
            │
            ├── CureStationSetup:setupCureStations(map)
            │   ├── Find or create CureStations folder
            │   ├── Create 5 cure component stations
            │   └── Link to CureService
            │
            └── Return success or error
```

---

## [3] Spawner Initialization

### Triggered after map is loaded

```
GameManager:update(deltaTime) [STATE: PLAYING]
    │
    ├─→ WaveManager:startWave()
    │   └─→ Spawner:startWave(waveNumber)
    │       │
    │       ├── Calculate zombie composition
    │       │   └── AIDirector:getComposition(waveNumber)
    │       │       ├── Base: 70% Walkers, 20% Runners, 10% Brutes
    │       │       ├── Scale by wave number
    │       │       └── Add boss every 5 waves
    │       │
    │       ├── Discover spawn points
    │       │   ├── map:FindFirstChild("ZombieSpawns")
    │       │   └── Collect all child parts with "SpawnPoint" tag
    │       │
    │       ├── Initialize IntelligentSpawnGenerator
    │       │   └── Calculate spawn distribution across points
    │       │
    │       └── Start spawn loop
    │           └─→ [SPAWNING LOOP]
    │
    └─→ ResourceSpawner:initialize(map)
        │
        ├── Discover resource spawn points
        │   ├── map:FindFirstChild("ResourceSpawns")
        │   └── Collect all child parts
        │
        └── Start resource spawn loop
            └─→ [RESOURCE LOOP]
```

---

## [4] CLIENT BOOT → UI Initialization

### Per Player Connection

```
Server: Players.PlayerAdded:Connect(onPlayerAdded)
    ├─→ gameManager:onPlayerAdded(player)
    │   ├── PlayerManager:addPlayer(player)
    │   ├── FPSWeaponService:initializePlayer(player)
    │   └── Setup character spawn
    │
    ├─→ allianceService:initializePlayer(player)
    ├─→ cureService:initializePlayer(player)
    ├─→ puzzleService:initializePlayer(player)
    ├─→ sprintService:initializePlayer(player)
    └─→ achievementService:initializePlayer(player)

Player's Character Spawned
    └─→ player.CharacterAdded:Connect()
        ├── PlayerSpawnManager:spawnPlayer(player, map)
        ├── sprintService:onCharacterAdded(player, character)
        └── [Client boots below]
```

### Client-Side Boot

```
game.StarterPlayer.StarterPlayerScripts.ClientController (LocalScript)
    │
    ├─→ Wait for ReplicatedStorage:WaitForChild("Shared", 10)
    ├─→ Wait for script.Parent:WaitForChild("Modules", 10)
    │
    ├─→ [LOAD CONFIGURATION]
    │   ├── require(FPSConfig)
    │   ├── require(GameConfig)
    │   ├── require(ModalManager)
    │   └── require(InputActionRegistry)
    │
    ├─→ [INITIALIZE CORE SYSTEMS]
    │   ├── initializeCamera()
    │   │   └── FirstPersonCamera.initialize()
    │   ├── initializeMovement()
    │   │   └── FPSMovement.initialize()
    │   ├── initializeWeapon()
    │   │   └── FPSWeaponController.initialize()
    │   │       ├── Setup input bindings
    │   │       ├── Connect WeaponFire remote event
    │   │       └── Start firing loop
    │   ├── initializeAnimation()
    │   │   └── FPSAnimationController.initialize()
    │   ├── initializeAudio()
    │   │   └── FPSAudioController.initialize()
    │   ├── initializeMusic()
    │   │   └── MusicController.initialize()
    │   └── initializeMenu()
    │       └── FPSMenuController.initialize()
    │
    ├─→ [INITIALIZE UI SYSTEMS] (22 modules)
    │   ├── TitleScreenUI.initialize()
    │   ├── LobbyUI.initialize()
    │   ├── FPSHUD.initialize()
    │   │   ├── Connect to AmmoUpdate
    │   │   ├── Connect to PlayerHealthUpdate
    │   │   └── Start HUD update loop
    │   ├── PlayerHUD.initialize()
    │   ├── WaveUI.initialize()
    │   │   └── Connect to WaveAnnounce
    │   ├── CureUI.initialize()
    │   │   └── Connect to CureUpdate
    │   ├── SynthesisUI.initialize()
    │   ├── PuzzleUI.initialize()
    │   │   └── Connect to PuzzleUpdate
    │   ├── ShopUI.initialize()
    │   │   └── Connect to ShopUpdate
    │   ├── InventoryUI.initialize()
    │   │   └── Connect to InventoryUpdate
    │   ├── AllianceUI.initialize()
    │   │   └── Connect to AllianceUpdate
    │   ├── BaseHealthUI.initialize()
    │   │   └── Connect to BaseHealthUpdate
    │   ├── ScoreboardUI.initialize()
    │   │   └── Connect to ShowScoreboard/HideScoreboard
    │   ├── MapVotingUI.initialize()
    │   ├── SpectatorUI.initialize()
    │   ├── EpilogueUI.initialize()
    │   ├── CreditsUI.initialize()
    │   ├── AchievementUI.initialize()
    │   │   └── Connect to AchievementUnlocked
    │   ├── FunFactUI.initialize()
    │   ├── TouchControlsUI.initialize()
    │   └── ControlsTutorialUI.initialize()
    │
    ├─→ [CHARACTER EVENT HANDLERS]
    │   ├── player.CharacterAdded:Connect()
    │   └── player.CharacterRemoving:Connect()
    │
    └─→ [CLIENT READY]
        └── Fire ClientReady remote event
```

---

## [5] Gameplay Loops (Concurrent Execution)

### Server-Side Loops

#### A. Main Game Loop (RunService.Heartbeat)

```
[Every frame, ~60 FPS]

gameManager:update(deltaTime)
    ├─→ Check server enabled flag
    ├─→ Current state machine
    │   ├── WAITING: Check player count → LOBBY
    │   ├── LOBBY: Countdown → PLAYING
    │   ├── PLAYING: Wave management → GAMEOVER
    │   └── GAMEOVER: Results → WAITING
    │
    ├─→ WaveManager:update(deltaTime)
    │   ├── Update wave timer
    │   ├── Check wave completion
    │   └── Transition to next wave
    │
    ├─→ BaseManager:update(deltaTime)
    │   ├── Check base health
    │   └── Trigger game over if destroyed
    │
    ├─→ CureService:update(deltaTime)
    │   ├── Update cure progress
    │   └── Check win condition
    │
    └─→ AI updates (via Spawner)
```

#### B. Zombie Spawning Loop (task.spawn in Spawner)

```
[Continuous during active wave]

Spawner:_spawnLoop()
    ├─→ Wait for spawn interval (from WaveConfig)
    ├─→ Check if wave is active
    ├─→ Check if spawn queue has space
    │
    ├─→ Get spawn point from IntelligentSpawnGenerator
    │
    ├─→ Create zombie from composition
    │   ├── Clone zombie model from ServerStorage
    │   ├── Position at spawn point
    │   ├── Create ZombieBrain.new(zombie, targetingService, surroundService)
    │   └── Add to active zombies list
    │
    ├─→ ZombieBrain:start()
    │   └─→ [ZOMBIE AI LOOP]
    │
    └─→ Repeat until wave ends
```

#### C. Individual Zombie AI Loop (per zombie)

```
[Continuous per zombie until death]

ZombieBrain:_mainLoop()
    ├─→ [TARGETING PHASE]
    │   ├── TargetingService:selectTarget(zombie)
    │   │   ├── Find nearby players
    │   │   ├── Find base camp
    │   │   ├── Weight by proximity
    │   │   └── Return best target
    │   └── Set zombie.target
    │
    ├─→ [SURROUND SLOT ALLOCATION]
    │   ├── SurroundService:requestSlot(zombie, target)
    │   └── Assign surround position
    │
    ├─→ [PATHFINDING]
    │   ├── PathfindingService:CreatePath()
    │   ├── path:ComputeAsync(zombie.Position, targetPosition)
    │   └── Get waypoints
    │
    ├─→ [MOVEMENT LOOP]
    │   ├── For each waypoint
    │   │   ├── zombie.Humanoid:MoveTo(waypoint.Position)
    │   │   ├── Wait 0.4s (reduced hesitation)
    │   │   └── Skip waypoint if close enough
    │   ├── Handle blocked paths
    │   │   ├── Repath after 0.3s jitter
    │   │   └── Fallback: move directly toward target
    │   └── Attack when in range
    │
    ├─→ [ATTACK PHASE]
    │   ├── Check distance to target
    │   ├── If in range: deal damage
    │   └── Continue targeting
    │
    └─→ Repeat until zombie dies or target changes
```

#### D. Resource Spawning Loop (task.spawn in ResourceSpawner)

```
[Continuous during gameplay]

ResourceSpawner:_spawnLoop()
    ├─→ Wait for resource spawn interval
    ├─→ Check active resource count
    │
    ├─→ Select random resource spawn point
    │
    ├─→ Roll resource type (ammo, health, currency)
    │
    ├─→ Create resource pickup
    │   ├── Clone from ServerStorage or create part
    │   ├── Position at spawn point
    │   ├── Add proximity detection
    │   └── Add to active resources list
    │
    ├─→ Resource.Touched:Connect()
    │   ├── Detect player
    │   ├── Give resource to player
    │   ├── PlayerManager:addAmmo/addHealth/addCurrency
    │   └── Destroy resource
    │
    └─→ Repeat indefinitely
```

#### E. Sprint/Stamina Management (SprintService)

```
[Continuous per player]

SprintService:update(deltaTime) [called from somewhere]
    ├─→ For each player
    │   ├── Check if sprinting (input state)
    │   ├── Drain stamina if sprinting
    │   ├── Regenerate stamina if not sprinting
    │   ├── Update player WalkSpeed
    │   └── Fire StaminaUpdate remote event
    │
    └─→ Repeat every frame or tick
```

---

### Client-Side Loops

#### A. Camera Update Loop (RunService.RenderStepped)

```
[Every render frame, ~60 FPS]

FirstPersonCamera:update()
    ├─→ Get mouse movement (UserInputService)
    ├─→ Apply mouse sensitivity
    ├─→ Clamp vertical angle (prevent over-rotation)
    ├─→ Update camera CFrame
    │   ├── Position: character.Head.Position + offset
    │   │   └── Apply recoil offset if firing
    │   └── Rotation: based on mouse delta
    │
    └─→ Update viewmodel position (weapon model in camera)
```

#### B. Movement Update Loop (RunService.Heartbeat)

```
[Every frame, ~60 FPS]

FPSMovement:update()
    ├─→ Get input state (W, A, S, D, Space, Shift)
    ├─→ Calculate move direction
    ├─→ Apply to character Humanoid
    │   └── humanoid:Move(moveVector)
    ├─→ Handle jumping
    └─→ Update animation state (idle, walk, sprint)
```

#### C. Weapon Firing Loop (UserInputService input + prediction)

```
[Triggered by mouse click or touch]

FPSWeaponController:startFiring()
    ├─→ [FIRING LOOP]
    │   ├─→ Check ammo (client prediction)
    │   ├─→ Fire WeaponFire remote event to server
    │   │
    │   ├─→ [CLIENT PREDICTION]
    │   │   ├── Raycast from camera
    │   │   ├── Create visual effects (muzzle flash, tracer)
    │   │   ├── Play weapon sound
    │   │   ├── Apply recoil to camera
    │   │   ├── Decrement ammo locally
    │   │   └── Update HUD immediately
    │   │
    │   ├─→ Wait for fire rate delay
    │   └─→ Repeat while mouse held
    │
    └─→ [SERVER VALIDATION]
        └── WeaponFire.OnServerEvent
            ├── FPSWeaponService:validateShot(player)
            ├── WeaponService:dealDamage(target, damage)
            ├── Fire AmmoUpdate to client (correction if mismatch)
            └── Replicate shot to other clients
```

#### D. UI Update Loops (per UI module)

```
[Example: FPSHUD update]

FPSHUD:updateLoop()
    ├─→ [LOCAL STATE]
    │   └── Display cached values (ammo, health)
    │
    ├─→ [REMOTE EVENT LISTENERS]
    │   ├── AmmoUpdate.OnClientEvent
    │   │   └── Update ammo display
    │   ├── PlayerHealthUpdate.OnClientEvent
    │   │   └── Update health display
    │   └── StaminaUpdate.OnClientEvent
    │       └── Update stamina bar
    │
    └─→ Repeat every frame (RunService.Heartbeat)
```

---

## State Machine Summary

### GameManager States

```
WAITING
    ↓ (players >= minPlayers)
LOBBY
    ↓ (countdown expires or manual start)
PLAYING
    ├─→ WAVE_ACTIVE
    │   ├─→ WAVE_INTERMISSION
    │   └─→ [Repeat until win/lose]
    │
    ↓ (base destroyed or cure complete)
GAMEOVER
    ↓ (results shown, countdown)
WAITING (restart)
```

### Wave States (within PLAYING)

```
WAVE_INTERMISSION
    ↓ (countdown)
WAVE_ACTIVE
    ├─→ Spawn zombies
    ├─→ Players fight
    └─→ Check completion
        ├─→ All zombies dead → WAVE_INTERMISSION
        └─→ Base destroyed → GAMEOVER
```

---

## Critical Paths

### 1. Server Startup Critical Path

```
MainServer.lua loads
    → AllianceServiceV2 created
    → GameManager created (creates 12+ services)
    → Event handlers connected
    → Game loop starts
    → Server ready ✓
```

**Failure Points:**
- Missing Shared folder in ReplicatedStorage
- Service creation errors (missing dependencies)
- RemoteEvents not created before access

### 2. Map Loading Critical Path

```
GameManager state → PLAYING
    → MapManager:loadMap()
    → Map cloned from ServerStorage
    → Map positioned at (5000, 0, 0)
    → MapValidator checks spawn points
    → BaseCampSetup creates base
    → Spawner initializes with spawn points
    → Wave starts ✓
```

**Failure Points:**
- Map not found in ServerStorage
- Missing spawn point folders (ZombieSpawns, ResourceSpawns)
- Invalid map structure
- Base camp setup errors

### 3. Client Connection Critical Path

```
Player joins
    → Server: onPlayerAdded handlers
    → Client: ClientController boots
    → Client: Load Shared modules
    → Client: Initialize core systems
    → Client: Initialize UI modules
    → Client: Connect remote event listeners
    → Client: Character spawns
    → Client: Ready to play ✓
```

**Failure Points:**
- Shared folder not found (10s timeout)
- Modules folder not found
- UI module load errors
- RemoteEvents not found
- Character spawn errors

### 4. Zombie AI Critical Path

```
Wave starts
    → Spawner:_spawnLoop()
    → Create zombie from model
    → Create ZombieBrain
    → ZombieBrain:start()
    → Select target (player or base)
    → Pathfind to target
    → Move along path
    → Attack target when in range
    → Repeat until zombie dies ✓
```

**Failure Points:**
- No spawn points found
- Zombie model not found in ServerStorage
- No targets found (no players, no base)
- Pathfinding fails
- Movement gets stuck

---

## Timing and Performance

### Server Performance Budget

| System | Target | Notes |
|--------|--------|-------|
| **Main Loop** | < 5ms/frame | Runs at 60 FPS (16.67ms budget) |
| **Map Loading** | < 3 seconds | One-time per round |
| **Zombie Spawn** | < 50ms each | Staggered spawns |
| **AI per Zombie** | < 1ms/frame | 50+ zombies possible |
| **Total AI** | < 50ms/frame | For all zombies combined |

### Client Performance Budget

| System | Target | Notes |
|--------|--------|-------|
| **Camera Update** | < 1ms/frame | RenderStepped, critical for feel |
| **UI Update** | < 2ms/frame | Multiple UI modules |
| **Weapon Prediction** | < 5ms/shot | Client-side raycast |
| **Total Client** | < 10ms/frame | 60 FPS target |

---

## Network Traffic Patterns

### High-Frequency Events (every frame or frequent)

- **StaminaUpdate** - Every 0.1s when sprinting
- **WeaponFire** - Up to 10/s per player (automatic weapons)
- **AmmoUpdate** - After each shot or reload
- **PlayerHealthUpdate** - When taking damage

### Medium-Frequency Events (periodic)

- **WaveUpdate** - Every wave transition (~30-60s)
- **CureUpdate** - When progress changes (~5-10s)
- **AllianceUpdate** - When alliances form/break (~rare)
- **InventoryUpdate** - When picking up items (~5-10s)

### Low-Frequency Events (rare)

- **GameStateUpdate** - State transitions (minutes)
- **MapUpdate** - Map changes (per round)
- **AchievementUnlocked** - Achievement earned (rare)
- **ShowScoreboard** - End of round (minutes)

---

**End of System Runtime Flow Diagram**
