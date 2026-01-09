# AwavePuzz - Module Dependencies

This document provides a visual reference for how modules and services are interconnected in the AwavePuzz project.

## Core Architecture

```
MainServer.lua (Entry Point)
    │
    ├─► AllianceServiceV2
    │       ├─► AllianceGraph
    │       ├─► PoolCalculator
    │       ├─► InventoryLedger
    │       └─► BetrayalService
    │
    ├─► GameManager (Core Game Loop)
    │       ├─► BaseManager
    │       ├─► PlayerManager (Singleton)
    │       ├─► Spawner
    │       │      └─► ZombieBrain
    │       │             ├─► AIDirector
    │       │             ├─► TargetingService
    │       │             ├─► SurroundService
    │       │             ├─► BossAuraService
    │       │             └─► SpitterController
    │       ├─► ResourceSpawner
    │       ├─► ItemSpawner
    │       ├─► WeaponService
    │       │      └─► FPSWeaponService
    │       ├─► FPSAnimationService
    │       ├─► ShopService
    │       ├─► MapManager
    │       │      └─► BaseCampSetup
    │       ├─► LobbyManager
    │       ├─► SpectatorManager
    │       ├─► PlayerSpawnManager
    │       └─► LobbySetup
    │
    ├─► CureService
    │       ├─► PuzzleService (Bidirectional)
    │       └─► AllianceServiceV2 (Bidirectional)
    │
    ├─► PuzzleService
    │       ├─► CureService (Bidirectional)
    │       └─► PlayerManager
    │
    ├─► SprintService
    │       └─► PlayerManager
    │
    ├─► AchievementService
    │       ├─► PlayerManager
    │       └─► GameManager
    │
    ├─► FunFactService (Independent)
    │
    └─► CureSynthesisService
            ├─► CureService
            ├─► PuzzleService
            └─► GameManager
```

## Shared Modules

All services have access to shared configuration modules:

```
ReplicatedStorage/Shared/
    ├─► GameConfig.lua          (Core game settings)
    ├─► WeaponConfig.lua        (Weapon definitions)
    ├─► ZombieTypes.lua         (Zombie definitions)
    ├─► WaveConfig.lua          (Wave progression)
    ├─► PuzzleConfig.lua        (Puzzle definitions)
    ├─► MapConfig.lua           (Map definitions)
    ├─► FPSConfig.lua           (FPS mechanics)
    ├─► FunFactConfig.lua       (Loading screen facts)
    ├─► StoryConfig.lua         (Story/dialogue)
    ├─► UIScaleConfig.lua       (UI scaling)
    ├─► WeaponValues.lua        (Weapon values for trading)
    ├─► GameState.lua           (Shared state utilities)
    ├─► RemoteEventUtil.lua     (RemoteEvent helper)
    ├─► MathUtil.lua            (Math utilities)
    ├─► InputManager.lua        (Input handling)
    └─► UIScaleManager.lua      (UI scaling manager)
```

## Client-Server Communication

```
Server Services ──[RemoteEvents]──► Client UI Scripts

GameManager:
    WaveAnnounce ─────────────────► WaveUI
    WaveUpdate ───────────────────► WaveUI
    GameStateUpdate ──────────────► Multiple UIs
    CureUpdate ───────────────────► CureUI
    BaseHealthUpdate ─────────────► BaseHealthUI
    MapUpdate ────────────────────► MapVotingUI
    ScoreboardUpdate ─────────────► ScoreboardUI
    ShowScoreboard ───────────────► ScoreboardUI
    HideScoreboard ───────────────► ScoreboardUI
    ShowTitleScreen ──────────────► TitleScreenUI
    HideTitleScreen ──────────────► TitleScreenUI
    TitleScreenContinue ──────────► TitleScreenUI (Client → Server)
    ShowEpilogue ─────────────────► EpilogueUI
    HideEpilogue ─────────────────► EpilogueUI
    EpilogueComplete ─────────────► EpilogueUI (Client → Server)
    ShowCredits ──────────────────► CreditsUI
    HideCredits ──────────────────► CreditsUI
    AchievementUnlocked ──────────► AchievementUI
    BetrayalStarted ──────────────► AllianceUI

CureService:
    PlayerCureProgressUpdate ─────► CureUI
PlayerManager:
    InventoryUpdate ──────────────► InventoryUI
    CurrencyUpdate ───────────────► InventoryUI
    WeaponLoadoutUpdate ──────────► FPSHUD
    PlayerHealthUpdate ───────────► PlayerHUD

AllianceServiceV2:
    RequestAlliance ──────────────► AllianceUI (Client → Server)
    RespondAlliance ──────────────► AllianceUI (Client → Server)
    BreakAlliance ────────────────► AllianceUI (Client → Server)
    AllianceUpdate ───────────────► AllianceUI

BetrayalService:
    BetrayalStarted ──────────────► AllianceUI
    BetrayalOutcome ──────────────► AllianceUI
    BetrayalStatus ───────────────► AllianceUI

SpectatorManager:
    EnterSpectatorMode ───────────► SpectatorUI
    ExitSpectatorMode ────────────► SpectatorUI
    SpectatorTargetUpdate ────────► SpectatorUI
    SpectatorCycleTarget ─────────► SpectatorUI (Client → Server)
    SpectatorStateUpdate ─────────► SpectatorUI

LobbyManager:
    MapVotingState ───────────────► LobbyUI, MapVotingUI
    MapVotingUpdate ──────────────► LobbyUI, MapVotingUI
    MapVoteCast ──────────────────► LobbyUI, MapVotingUI (Client → Server)

ShopService:
    ShopRequest ──────────────────► ShopUI (Client → Server)
    ShopUpdate ───────────────────► ShopUI

WeaponService:
    WeaponFire ───────────────────► FPSWeaponController (Client → Server)
    WeaponReload ─────────────────► FPSWeaponController (Client → Server)
    WeaponHitConfirm ─────────────► FPSWeaponController
    WeaponEquip ──────────────────► FPSWeaponController (Client → Server)

PuzzleService:
    RequestPuzzle ────────────────► PuzzleUI (Client → Server)
    SubmitPuzzleAnswer ───────────► PuzzleUI (Client → Server)
    PuzzleUpdate ─────────────────► PuzzleUI
    PuzzleCompleted ──────────────► PuzzleUI
    PuzzleFailed ─────────────────► PuzzleUI
    OpenPuzzleUI ─────────────────► PuzzleMenuUI
    RequestPuzzleProgress ────────► PuzzleUI (Client → Server)

FPSWeaponService:
    WeaponReload ─────────────────► FPSWeaponController (Client → Server)
    AmmoUpdate ───────────────────► FPSHUD
    WeaponReload ─────────────────► FPSHUD

SprintService:
    SprintRequest ────────────────► FPSMovement (Client → Server)
    StaminaUpdate ────────────────► PlayerHUD

FunFactService:
    RequestFunFact ───────────────► FunFactUI (Client → Server)
    ShowFunFact ──────────────────► FunFactUI
    UpdateFactStats ──────────────► FunFactUI

FPSAnimationService:
    AnimationFire ────────────────► FPSAnimationController
    AnimationFireReplicate ───────► FPSAnimationController
    AnimationSprint ──────────────► FPSAnimationController
    AnimationSprintReplicate ─────► FPSAnimationController
    AnimationADS ─────────────────► FPSAnimationController
    AnimationADSReplicate ────────► FPSAnimationController

CureSynthesisService:
    StartSynthesis ───────────────► SynthesisUI (Client → Server)
    SynthesisStateUpdate ─────────► SynthesisUI
    SynthesisPuzzleComplete ──────► SynthesisUI
    SynthesisComplete ────────────► SynthesisUI
    SynthesisFailed ──────────────► SynthesisUI
```

## Module Initialization Flow

```
1. Server Starts
   └─► MainServer.lua loads

2. Create Alliance System
   └─► AllianceServiceV2.new()
       └─► Creates AllianceGraph, PoolCalculator, InventoryLedger, BetrayalService

3. Create Game Manager
   └─► GameManager.new(allianceService)
       ├─► Creates PlayerManager (singleton)
       ├─► Creates BaseManager (singleton)
       ├─► Creates WeaponService
       ├─► Creates FPSWeaponService
       ├─► Creates FPSAnimationService
       ├─► Creates ShopService
       ├─► Creates ResourceSpawner
       ├─► Creates ItemSpawner
       ├─► Creates Spawner
       ├─► Creates MapManager
       ├─► Creates LobbyManager
       ├─► Creates SpectatorManager
       ├─► Creates PlayerSpawnManager
       └─► Creates LobbySetup

4. Create Supporting Services
   ├─► CureService.new(gameManager, playerManager)
   ├─► PuzzleService.new(cureService, playerManager)
   ├─► SprintService.new(playerManager)
   ├─► AchievementService.new(playerManager, gameManager)
   ├─► FunFactService.new()
   └─► CureSynthesisService.new(cureService, waveManager, gameManager)

5. Link Services
   ├─► CureService:setPuzzleService(puzzleService)
   ├─► CureService:setAllianceService(allianceService)
   ├─► AllianceService:setPuzzleService(puzzleService)
   ├─► AllianceService:setCureService(cureService)
   ├─► AllianceService:setPlayerManager(playerManager)
   ├─► AllianceService:setGameManager(gameManager)
   ├─► GameManager:setCureService(cureService)
   ├─► GameManager:setAchievementService(achievementService)
   ├─► GameManager:setFunFactService(funFactService)
   └─► GameManager:setCureSynthesisService(cureSynthesisService)

6. Server Ready
   └─► Listening for player connections
```

## Key Design Patterns

### 1. Singleton Pattern
- **PlayerManager**: Single instance shared across all services
- **BaseManager**: Single instance for base health tracking

### 2. Dependency Injection
- Services receive their dependencies through constructors
- Example: `GameManager.new(allianceService)`
- Example: `CureService.new(gameManager, playerManager)`

### 3. Bidirectional Links
- CureService ↔ PuzzleService (mutual dependency)
- CureService ↔ AllianceService (for resource pooling)

### 4. Composition
- AllianceServiceV2 contains AllianceGraph, PoolCalculator, etc.
- GameManager contains multiple manager instances

### 5. Centralized Utilities
- RemoteEventUtil: Consistent RemoteEvent creation
- MathUtil: Shared math functions
- Configuration modules: Centralized game settings

## Service Responsibilities

| Service | Responsibility |
|---------|----------------|
| **GameManager** | Core game loop, state management, wave control |
| **PlayerManager** | Player data, inventory, currency, health |
| **AllianceServiceV2** | Alliance formation, resource pooling, betrayals |
| **CureService** | Cure component tracking, progress calculation |
| **PuzzleService** | Puzzle generation, validation, rewards |
| **WeaponService** | Weapon fire validation, damage calculation |
| **FPSWeaponService** | Ammo tracking, reload management |
| **ShopService** | Shop catalog, purchase validation |
| **Spawner** | Zombie spawning, AI initialization |
| **BaseManager** | Base health, damage, destruction |
| **MapManager** | Map loading, spawn point extraction |
| **LobbyManager** | Map voting, lobby state |
| **SpectatorManager** | Spectator mode, target cycling |
| **SprintService** | Stamina tracking, sprint validation |
| **AchievementService** | Achievement tracking, unlocking |
| **FunFactService** | Fun fact broadcasting |
| **CureSynthesisService** | Endgame synthesis mechanic |
| **FPSAnimationService** | Animation replication |

---

**Last Updated**: 2026-01-09  
**Architecture Version**: 1.0  
**Status**: Validated and Production Ready
