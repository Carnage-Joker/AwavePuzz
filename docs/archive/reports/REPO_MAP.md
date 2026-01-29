# AwavePuzz Repository Map

**Document Version:** 1.0  
**Generated:** 2026-01-24  
**Purpose:** Complete repository structure, entrypoints, and architecture overview

---

## Executive Summary

AwavePuzz is a multiplayer Roblox zombie survival game with wave-based combat, cure-crafting puzzles, and alliance systems. The codebase follows a client-server architecture with:
- **267 active Lua files** (excluding Archive)
- **Server entrypoint:** `MainServer.lua` initializing 12+ services
- **Client entrypoint:** `ClientController.client.lua` managing 6 systems + 22 UI modules
- **40+ Remote Events** for client-server communication
- **Modular design** with clear separation of concerns

---

## 1. Folder Structure

```
AwavePuzz/
├── ServerScriptService/          # Server-side logic (35 files + AI + Alliance folders)
├── StarterPlayer/                # Client-side scripts and UI
│   └── StarterPlayerScripts/     # Client entrypoint + modules
│       ├── ClientController.client.lua  ⭐ CLIENT ENTRY
│       └── Modules/              # UI + FPS controllers
├── ReplicatedStorage/            # Shared modules and remote events
│   ├── Shared/                   # Config + utilities (19 modules)
│   ├── RemoteEvents/             # 40+ remote event definitions
│   └── Animations/               # Weapon animations
├── ServerStorage/                # Server-only assets
│   ├── ZombieModels/             # Zombie templates
│   ├── Maps/                     # Playable maps
│   └── DevOnly/                  # Development tools
├── StarterGui/                   # ⚠️ DEPRECATED (all .disabled files)
└── Archive/                      # Legacy code and duplicates
```

---

## 2. Server Entrypoint: MainServer.lua

**Location:** `/ServerScriptService/MainServer.lua`  
**Type:** Script (runs automatically on server start)

### Initialization Order

```lua
1. AllianceServiceV2.new()           -- Alliance system foundation
2. GameManager.new(allianceService)  -- Central hub (12+ services)
   ├── BaseManager
   ├── PlayerManager
   ├── Spawner (with AI subsystem)
   ├── WeaponService
   ├── FPSWeaponService
   ├── FPSAnimationService
   ├── MapManager
   ├── WaveManager
   ├── ShopService
   ├── ResourceSpawner
   └── ItemSpawner
3. SprintService.new(playerManager)
4. CureService.new(gameManager, playerManager)
5. PuzzleService.new(cureService, playerManager)
6. [Cross-service linking]
7. AchievementService.new(playerManager, gameManager)
8. FunFactService.new()
9. CureSynthesisService.new(cureService, waveManager, gameManager)
```

### Player Connection Handlers

```lua
Players.PlayerAdded:Connect()
  ├── gameManager:onPlayerAdded(player)
  ├── allianceService:initializePlayer(player)
  ├── cureService:initializePlayer(player)
  ├── puzzleService:initializePlayer(player)
  ├── sprintService:initializePlayer(player)
  └── achievementService:initializePlayer(player)

player.CharacterAdded:Connect()
  └── sprintService:onCharacterAdded(player, character)
```

### Service Dependency Graph

```
AllianceServiceV2 (independent)
    ↓ (injected into)
GameManager (hub)
    ├→ PlayerManager ────→ SprintService
    ├→ WeaponService     ↓
    ├→ FPSWeaponService  ↓
    ├→ Spawner (AI)      ↓
    │   ├→ TargetingService
    │   ├→ SurroundService
    │   ├→ AIDirector
    │   ├→ BossAuraService
    │   └→ IntelligentSpawnGenerator
    ├→ MapManager
    ├→ WaveManager ────→ CureSynthesisService
    └→ BaseManager       ↓
                         ↓
                    CureService ←─→ PuzzleService
                         ↑              ↑
                         └──────────────┴─→ AllianceServiceV2
```

---

## 3. Client Entrypoint: ClientController.client.lua

**Location:** `/StarterPlayer/StarterPlayerScripts/ClientController.client.lua`  
**Type:** LocalScript (runs automatically for each player)

### Initialization Order

```lua
1. Load Configuration
   ├── FPSConfig
   ├── GameConfig
   ├── ModalManager
   └── InputActionRegistry

2. Initialize Core Systems
   ├── Camera (FirstPersonCamera)
   ├── Movement (FPSMovement)
   ├── Weapon (FPSWeaponController)
   ├── Animation (FPSAnimationController)
   ├── Audio (FPSAudioController)
   ├── Music (MusicController)
   └── Menu (FPSMenuController)

3. Initialize UI Systems (22 modules)
   ├── TitleScreenUI
   ├── LobbyUI
   ├── FPSHUD
   ├── PlayerHUD
   ├── WaveUI
   ├── CureUI
   ├── SynthesisUI
   ├── PuzzleUI
   ├── PuzzleMenuUI
   ├── ShopUI
   ├── InventoryUI
   ├── AllianceUI
   ├── BaseHealthUI
   ├── ScoreboardUI
   ├── MapVotingUI
   ├── SpectatorUI
   ├── EpilogueUI
   ├── CreditsUI
   ├── AchievementUI
   ├── FunFactUI
   ├── TouchControlsUI
   └── ControlsTutorialUI

4. Character Event Handlers
   ├── player.CharacterAdded
   └── player.CharacterRemoving
```

---

## 4. Key Subsystems

### A. AI System (`/ServerScriptService/AI/`)

| Module | Purpose | Key Features |
|--------|---------|--------------|
| **ZombieBrain.lua** | Individual zombie AI controller | Continuous targeting, reduced hesitation (0.4s), waypoint skipping |
| **TargetingService.lua** | Target selection logic | Player vs base prioritization, proximity weighting |
| **SurroundService.lua** | Anti-pileup positioning | Allocates surround slots around targets |
| **AIDirector.lua** | Difficulty scaling | Manages zombie composition by wave |
| **BossAuraService.lua** | Boss special abilities | Aura effects, enhanced stats |
| **SpitterController.lua** | Spitter zombie behavior | Ranged attacks, special AI patterns |

### B. Spawning System (`/ServerScriptService/`)

| Module | Purpose |
|--------|---------|
| **Spawner.lua** | Main zombie spawner; manages spawn queue, active zombies, composition |
| **IntelligentSpawnGenerator.lua** | Dynamic spawn distribution across spawn points |
| **ResourceSpawner.lua** | Spawns ammo, health, resource pickups |
| **ItemSpawner.lua** | Spawns loot drops and purchasable items |

### C. UI System (`/StarterPlayer/StarterPlayerScripts/Modules/UI/`)

**22 UI Modules organized by category:**

| Category | Modules |
|----------|---------|
| **Game Flow** | TitleScreenUI, LobbyUI, EpilogueUI, CreditsUI |
| **Gameplay HUD** | FPSHUD, PlayerHUD, WaveUI, ScoreboardUI |
| **Economy** | ShopUI, InventoryUI |
| **Progression** | CureUI, SynthesisUI, PuzzleUI, PuzzleMenuUI |
| **Social** | AllianceUI, SpectatorUI |
| **Info Displays** | BaseHealthUI, MapVotingUI, AchievementUI, FunFactUI |
| **Mobile Support** | TouchControlsUI, ControlsTutorialUI |

### D. Weapon System

**Server Components** (`/ServerScriptService/`):
- **WeaponService.lua** - Weapon balance, configuration, validation
- **FPSWeaponService.lua** - Server-authoritative ammo tracking, reload logic
- **FPSAnimationService.lua** - Server replication of FPS animations

**Client Components** (`/StarterPlayer/StarterPlayerScripts/Modules/`):
- **FPSWeaponController.lua** - Client firing prediction, input handling
- **FPSAnimationController.lua** - Animation playback
- **FPSAudioController.lua** - Weapon sounds and footsteps

### E. Alliance System (`/ServerScriptService/Alliance/`)

| Module | Purpose |
|--------|---------|
| **AllianceServiceV2.lua** | Main manager for requests, responses, betrayal |
| **AllianceGraph.lua** | Undirected graph of alliances, component pooling |
| **PoolCalculator.lua** | Calculates shared resource pools for allies |
| **InventoryLedger.lua** | Tracks inventory across alliance networks |
| **BetrayalService.lua** | 3-outcome betrayal system with pool snapshots |

### F. Map System (`/ServerScriptService/`)

| Module | Purpose |
|--------|---------|
| **MapManager.lua** | Loads maps from ServerStorage, positions at (5000, 0, 0) |
| **MapValidator.lua** | Validates spawn points, base position, objective markers |
| **BaseCampSetup.lua** | Configures base camp structure and health |

---

## 5. Remote Events Architecture

**Location:** `/ReplicatedStorage/RemoteEvents/` (40+ `.txt` files)  
**Bootstrap:** Created on startup via `RemoteEventsBootstrap.lua`

### Remote Event Categories

| Type | Count | Examples |
|------|-------|----------|
| **Weapon** | 7 | WeaponFire, WeaponEquip, WeaponReload, AmmoUpdate, WeaponHitConfirm |
| **Player State** | 8 | PlayerHealthUpdate, StaminaUpdate, AnimationFire, AnimationADS |
| **Game State** | 5 | GameStateUpdate, WaveUpdate, MapUpdate, LobbyStateUpdate |
| **UI/Notifications** | 6 | ShowScoreboard, AchievementUnlocked, WaveAnnounce |
| **Alliance** | 5 | RequestAlliance, RespondAlliance, AllianceUpdate, BreakAlliance |
| **Cure/Puzzle** | 7 | CureUpdate, PuzzleUpdate, SubmitPuzzleAnswer, PuzzleCompleted |
| **Economy** | 4 | InventoryUpdate, CurrencyUpdate, ShopUpdate, BaseHealthUpdate |
| **Other** | 8+ | Spectator, MapVote, TitleScreen, Epilogue events |

---

## 6. Configuration Files

**Location:** `/ReplicatedStorage/Shared/`

| File | Purpose | Key Settings |
|------|---------|--------------|
| **GameConfig.lua** | Core game mechanics | Wave timing, difficulty, spawn rates, min players |
| **FPSConfig.lua** | First-person settings | Camera sensitivity, FOV, animation speeds |
| **WeaponConfig.lua** | Weapon balance | Damage, fire rate, reload times per weapon |
| **WeaponValues.lua** | Weapon stat tables | Lookup tables for weapon properties |
| **MapConfig.lua** | Map definitions | Map list, spawn counts, objective data |
| **WaveConfig.lua** | Wave progression | Zombie composition, scaling, rewards |
| **PuzzleConfig.lua** | Puzzle definitions | Puzzle types, solutions, rewards |
| **ZombieTypes.lua** | Zombie stats | Walker, Brute, Runner, Spitter, Boss definitions |
| **FunFactConfig.lua** | Fun facts database | Random facts for downtime |

### Utility Modules

| File | Purpose |
|------|---------|
| **GameState.lua** | Shared game state enum (Lobby, Playing, Wave, GameOver) |
| **InputManager.lua** | Input handling and validation |
| **InputActionRegistry.lua** | Action binding definitions, conflict detection |
| **ModalManager.lua** | Modal dialog/window stacking and input routing |
| **UIScaleManager.lua** | Responsive UI scaling across devices |
| **MathUtil.lua** | Math helper functions |
| **RemoteEventUtil.lua** | Remote event creation and access utilities |

---

## 7. Duplicates and Archive

### StarterGui/ ⚠️ DEPRECATED

**Status:** All 22 UI files are `.disabled`

```
StarterGui/
├── AchievementUI.lua.disabled
├── AllianceUI.lua.disabled
├── [... 20 more .disabled files ...]
└── TouchControlsUI.lua.disabled
```

**Reason:** All UI moved to `StarterPlayer/StarterPlayerScripts/Modules/UI/`  
**Action:** Keep disabled for reference, but never use

### Archive/

```
Archive/
├── Legacy/Code/Server/
│   ├── GameServer.lua              # OLD main server (replaced by MainServer.lua)
│   └── CureCraftingManager.lua     # Legacy cure system
│
└── ReplicatedStorage_Client_UI_Duplicates_2026-01-20/
    └── UI/                         # 22 duplicate UI modules (same as current)
```

**Action:** Archived on 2026-01-20, documented in `DUPLICATE_CLEANUP_REPORT.md`

### ServerStorage/DevOnly/

Development utilities and test scripts:
- **Test Scripts:** TestMapSystem, TestBaseCamp, TestItemSpawner
- **Visualizers:** SpawnPointVisualizer, VisualizeBaseCamp
- **Fix Scripts:** AmmoSystemFix, FixSystemAmmo
- **GitHub Clone:** Documentation backups (not actual code)

---

## 8. Load Order and Assumptions

### Server Load Order

1. **MainServer.lua** runs automatically (Script in ServerScriptService)
2. **RemoteEventsBootstrap.lua** may run before or after MainServer (order not guaranteed)
3. Services initialize in order defined in MainServer.lua
4. Cross-service linking happens after all services are created
5. Player connection handlers are set up last
6. **Assumption:** All Shared modules in ReplicatedStorage exist before MainServer runs

### Client Load Order

1. **ClientController.client.lua** runs automatically (LocalScript in StarterPlayerScripts)
2. Waits for ReplicatedStorage:WaitForChild("Shared", 10)
3. Waits for Modules folder in same directory
4. Systems initialize sequentially (Camera → Movement → Weapon → etc.)
5. UI modules load after core systems
6. **Assumption:** Server has already created RemoteEvents before client needs them

### Load Order Issues

⚠️ **Potential Issue:** RemoteEventsBootstrap.lua and MainServer.lua both run as Scripts in ServerScriptService with no guaranteed order. If MainServer tries to access RemoteEvents before they're created, errors may occur.

**Recommendation:** Use `:WaitForChild()` with timeout when accessing RemoteEvents, or ensure RemoteEventsBootstrap runs first by placing it alphabetically before MainServer (or using script priority).

---

## 9. Key Statistics

| Metric | Value |
|--------|-------|
| **Total Lua Files** | 286 (including Archive) |
| **Active Lua Files** | 267 (excluding Archive) |
| **Server Services** | 35+ modules in ServerScriptService |
| **Client Modules** | 30+ modules in StarterPlayerScripts/Modules |
| **UI Modules** | 22 (all in Modules/UI) |
| **Remote Events** | 40+ |
| **Config Files** | 10 |
| **Zombie Types** | 5 (Walker, Brute, Runner, Spitter, Boss) |
| **Playable Maps** | 3+ (Village, ResearchOutpost, variants) |
| **AI Modules** | 6 |
| **Alliance Modules** | 5 |

---

## 10. Critical Files

| File | Lines | Role | Dependencies |
|------|-------|------|--------------|
| **MainServer.lua** | ~200 | Server initialization | All server services |
| **GameManager.lua** | ~500+ | Central hub service | 12+ services |
| **ClientController.client.lua** | ~400 | Client initialization | All client modules |
| **ZombieBrain.lua** | ~400 | Individual zombie AI | TargetingService, SurroundService |
| **AllianceServiceV2.lua** | ~300 | Alliance management | AllianceGraph, PoolCalculator |
| **FPSWeaponService.lua** | ~300 | Server weapon logic | WeaponService, PlayerManager |
| **MapManager.lua** | ~200 | Map loading | MapValidator, MapConfig |
| **Spawner.lua** | ~400 | Zombie spawning | AI services, WaveManager |

---

## 11. Architecture Summary

**Pattern:** Hub-and-Spoke with Service-Oriented Architecture

**Hub Service:** GameManager orchestrates 12+ sub-services  
**Client Controller:** Single entrypoint loading 30+ modules  
**Communication:** 40+ Remote Events for client-server sync  
**Configuration:** Centralized in ReplicatedStorage/Shared  
**Assets:** Server-only in ServerStorage (maps, zombies)

**Strengths:**
- ✅ Clear separation of server/client
- ✅ Modular service design
- ✅ Centralized configuration
- ✅ Single entrypoints (MainServer, ClientController)

**Potential Issues:**
- ⚠️ Load order dependencies (RemoteEvents, Shared modules)
- ⚠️ GameManager hub is large (~500+ lines)
- ⚠️ Many cross-service dependencies require careful initialization order
- ⚠️ Duplicate code in Archive needs to be kept separate

---

## 12. Future Recommendations

1. **Add Script Load Order Control:** Use script priorities or WaitForChild with timeouts
2. **Break Up GameManager:** Consider splitting into smaller orchestrators
3. **Dependency Injection:** Use explicit DI container instead of manual wiring
4. **Documentation:** Auto-generate service dependency graphs
5. **Testing:** Add integration tests for service initialization order

---

**End of Repository Map**
