# Installation Guide - AwavePuzz

This guide will help you set up and run the AwavePuzz zombie survival game in Roblox Studio.

## Prerequisites

- **Roblox Studio** (latest version)
- **Roblox Account** (for testing and publishing)
- Basic understanding of Roblox Studio interface
- This repository cloned or downloaded

## Table of Contents

1. [Quick Start](#quick-start)
2. [Complete File Structure Reference](#complete-file-structure-reference)
3. [Detailed Setup](#detailed-setup)
4. [Map Configuration](#map-configuration)
5. [Testing](#testing)
6. [Troubleshooting](#troubleshooting)

---

## Quick Start

For experienced Roblox developers:

1. Open Roblox Studio
2. Create new place or open existing project
3. Copy directories directly from repository to Roblox Studio:
   - `ServerScriptService/*` → game.ServerScriptService
   - `ReplicatedStorage/Shared/*` → game.ReplicatedStorage.Shared
   - `StarterPlayer/StarterPlayerScripts/*` → game.StarterPlayer.StarterPlayerScripts
   - `StarterGui/*` scripts → game.StarterGui (as LocalScript instances)
4. Configure spawn points and workspace elements
5. Test in multiplayer

> **Important Note on File Naming**: All Lua files use only `.lua` extension without additional dots (e.g., `MainServerScript.lua` NOT `Main.server.lua`). This prevents issues with Roblox sync tools like Rojo and GitSync.

---

## Complete File Structure Reference

Below is the complete Roblox file structure showing every file from this repository, its type (Script, LocalScript, or ModuleScript), and its location in the Roblox hierarchy.

### Legend

| Symbol | Type | Description |
|--------|------|-------------|
| 📜 | **Script** | Server-side script that runs automatically |
| 📄 | **LocalScript** | Client-side script that runs automatically |
| 📦 | **ModuleScript** | Reusable module (must be `require()`d) |
| 📁 | **Folder** | Container for organization |
| 🧱 | **Part/Model** | Physical game object |

---

### Complete Roblox Hierarchy

```
game
├── Workspace
│   ├── 🧱 Base (Part or Model) - The central base players defend
│   │   └── Health displayed/tracked by BaseManager
│   ├── 📁 ZombieSpawnPoints (Folder)
│   │   ├── 🧱 SpawnPoint1 (Part)
│   │   ├── 🧱 SpawnPoint2 (Part)
│   │   └── ... (additional spawn points)
│   ├── 📁 ResourceSpawnPoints (Folder)
│   │   ├── 🧱 ResourcePoint1 (Part)
│   │   ├── 🧱 ResourcePoint2 (Part)
│   │   └── ... (additional resource points)
│   ├── 📁 CureStations (Folder) - Optional cure station locations
│   │   └── 🧱 CureStation1 (Part with ProximityPrompt)
│   └── 📁 Zombies (Folder) - Created at runtime for active zombies
│
├── ServerScriptService
│   ├── 📜 MainServerScript.lua (Script) - Main entry point, initializes all services
│   ├── 📦 GameManager.lua (ModuleScript) - Orchestrates game state, waves, win/lose
│   ├── 📦 PlayerManager.lua (ModuleScript) - Player data, inventory, currency
│   ├── 📦 WaveManager.lua (ModuleScript) - Wave timing and zombie counts
│   ├── 📦 BaseManager.lua (ModuleScript) - Base health and damage tracking
│   ├── 📦 Spawner.lua (ModuleScript) - Zombie spawning and AI initialization
│   ├── 📦 CureService.lua (ModuleScript) - Cure progress and component tracking
│   ├── 📦 CureSynthesisService.lua (ModuleScript) - Cure synthesis system
│   ├── 📦 PuzzleService.lua (ModuleScript) - Puzzle generation and validation
│   ├── 📦 AllianceServiceV2.lua (ModuleScript) - Player alliance management
│   ├── 📦 WeaponService.lua (ModuleScript) - Server-authoritative weapon handling
│   ├── 📦 FPSWeaponService.lua (ModuleScript) - FPS ammo and reload management
│   ├── 📦 FPSAnimationService.lua (ModuleScript) - FPS animation synchronization
│   ├── 📦 ShopService.lua (ModuleScript) - In-game shop and purchases
│   ├── 📦 MapManager.lua (ModuleScript) - Multi-map loading system
│   ├── 📦 LobbyManager.lua (ModuleScript) - Pre-round lobby and map voting
│   ├── 📦 SpectatorManager.lua (ModuleScript) - Dead player spectator system
│   ├── 📦 ResourceSpawner.lua (ModuleScript) - Cure component spawning
│   ├── 📦 SprintService.lua (ModuleScript) - Server-authoritative stamina
│   ├── 📦 AchievementService.lua (ModuleScript) - Achievement tracking
│   ├── 📦 VoiceoverService.lua (ModuleScript) - Story voiceover system
│   ├── 📦 FunFactService.lua (ModuleScript) - Fun fact display service
│   ├── 📦 PortalMatchmakingService.lua (ModuleScript) - Portal matchmaking
│   ├── 📦 PlayerSpawnManager.lua (ModuleScript) - Player spawn handling
│   ├── 📦 ItemSpawner.lua (ModuleScript) - Item spawning system
│   ├── 📦 RemoteEventsBootstrap.lua (ModuleScript) - RemoteEvent initialization
│   ├── 📦 SessionState.lua (ModuleScript) - Session state management
│   ├── 📦 MatchRegistry.lua (ModuleScript) - Match tracking registry
│   ├── 📦 MapValidator.lua (ModuleScript) - Map validation utilities
│   ├── 📦 BaseCampSetup.lua (ModuleScript) - Base camp initialization
│   ├── 📦 CureStationSetup.lua (ModuleScript) - Cure station setup
│   ├── 📦 LobbySetup.lua (ModuleScript) - Lobby initialization
│   ├── 📦 IntelligentSpawnGenerator.lua (ModuleScript) - Intelligent spawn point generation
│   ├── 📦 SpawnPointVisualizer.lua (ModuleScript) - Spawn point visualization
│   ├── 📦 ClientReady.lua (ModuleScript) - Client ready signal handling
│   ├── 📦 BootValidationTest.lua (ModuleScript) - Boot validation utilities
│   ├── 📁 AI (Folder)
│   │   ├── 📦 ZombieBrain.lua (ModuleScript) - Zombie AI and pathfinding
│   │   ├── 📦 AIDirector.lua (ModuleScript) - AI director system
│   │   ├── 📦 TargetingService.lua (ModuleScript) - Zombie targeting logic
│   │   ├── 📦 SpitterController.lua (ModuleScript) - Spitter zombie controller
│   │   ├── 📦 BossAuraService.lua (ModuleScript) - Boss aura effects
│   │   └── 📦 SurroundService.lua (ModuleScript) - Zombie surround mechanics
│   └── 📁 Alliance (Folder)
│       ├── 📦 AllianceGraph.lua (ModuleScript) - Alliance graph structure
│       ├── 📦 BetrayalService.lua (ModuleScript) - Betrayal mechanics
│       ├── 📦 InventoryLedger.lua (ModuleScript) - Inventory ledger tracking
│       └── 📦 PoolCalculator.lua (ModuleScript) - Alliance pool calculations
│
├── ReplicatedStorage
│   ├── 📁 Shared (Folder)
│   │   ├── 📦 GameConfig.lua (ModuleScript) - Core game settings
│   │   ├── 📦 GameState.lua (ModuleScript) - Game state definitions
│   │   ├── 📦 WaveConfig.lua (ModuleScript) - Wave progression settings
│   │   ├── 📦 ZombieTypes.lua (ModuleScript) - Zombie stats and types
│   │   ├── 📦 WeaponConfig.lua (ModuleScript) - Weapon definitions
│   │   ├── 📦 WeaponValues.lua (ModuleScript) - Weapon stat values
│   │   ├── 📦 FPSConfig.lua (ModuleScript) - FPS camera and controls
│   │   ├── 📦 MapConfig.lua (ModuleScript) - Available maps configuration
│   │   ├── 📦 PuzzleConfig.lua (ModuleScript) - Puzzle definitions
│   │   ├── 📦 UIScaleConfig.lua (ModuleScript) - UI scaling breakpoints
│   │   ├── 📦 UIScaleManager.lua (ModuleScript) - Responsive UI utilities
│   │   ├── 📦 AssetConfig.lua (ModuleScript) - Asset ID configuration
│   │   ├── 📦 AssetValidation.lua (ModuleScript) - Asset validation utilities
│   │   ├── 📦 FunFactConfig.lua (ModuleScript) - Fun fact definitions
│   │   ├── 📦 StoryConfig.lua (ModuleScript) - Story and lore configuration
│   │   ├── 📦 PortalConfig.lua (ModuleScript) - Portal system configuration
│   │   ├── 📦 InputActionRegistry.lua (ModuleScript) - Input action definitions
│   │   ├── 📦 InputManager.lua (ModuleScript) - Input management utilities
│   │   ├── 📦 ModalManager.lua (ModuleScript) - Modal dialog management
│   │   ├── 📦 MathUtil.lua (ModuleScript) - Math utility functions
│   │   ├── 📦 RemoteEventUtil.lua (ModuleScript) - RemoteEvent utilities
│   │   ├── 📦 UIDebugConfig.lua (ModuleScript) - UI debugging configuration
│   │   └── 📁 Remotes (Folder)
│   │       └── 📦 RemoteRegistry.lua (ModuleScript) - Remote event registry
│   └── 📁 RemoteEvents (Folder) - Created automatically at runtime by RemoteEventsBootstrap
│       ├── WaveAnnounce (RemoteEvent)
│       ├── WaveUpdate (RemoteEvent)
│       ├── GameStateUpdate (RemoteEvent)
│       ├── CureUpdate (RemoteEvent)
│       ├── BaseHealthUpdate (RemoteEvent)
│       ├── PlayerHealthUpdate (RemoteEvent)
│       ├── PlayerCureProgressUpdate (RemoteEvent)
│       ├── WeaponFire (RemoteEvent)
│       ├── WeaponEquip (RemoteEvent)
│       ├── WeaponReload (RemoteEvent)
│       ├── WeaponLoadoutUpdate (RemoteEvent)
│       ├── WeaponHitConfirm (RemoteEvent)
│       ├── ShopRequest (RemoteEvent)
│       ├── ShopUpdate (RemoteEvent)
│       ├── RequestAlliance (RemoteEvent)
│       ├── RespondAlliance (RemoteEvent)
│       ├── AllianceUpdate (RemoteEvent)
│       ├── BreakAlliance (RemoteEvent)
│       ├── RequestPuzzle (RemoteEvent)
│       ├── RequestPuzzleProgress (RemoteEvent)
│       ├── OpenPuzzleUI (RemoteEvent)
│       ├── SubmitPuzzleAnswer (RemoteEvent)
│       ├── PuzzleUpdate (RemoteEvent)
│       ├── PuzzleCompleted (RemoteEvent)
│       ├── PuzzleFailed (RemoteEvent)
│       ├── SprintRequest (RemoteEvent)
│       ├── StaminaUpdate (RemoteEvent)
│       ├── CastMapVote (RemoteEvent)
│       ├── MapVoteStart (RemoteEvent)
│       ├── MapVoteUpdate (RemoteEvent)
│       ├── MapVoteEnd (RemoteEvent)
│       ├── MapUpdate (RemoteEvent)
│       ├── EnterSpectatorMode (RemoteEvent)
│       ├── ExitSpectatorMode (RemoteEvent)
│       ├── SpectatorCycleTarget (RemoteEvent)
│       ├── SpectatorTargetUpdate (RemoteEvent)
│       ├── SpectatorStateUpdate (RemoteEvent)
│       ├── ScoreboardUpdate (RemoteEvent)
│       ├── ShowScoreboard (RemoteEvent)
│       ├── HideScoreboard (RemoteEvent)
│       ├── InventoryUpdate (RemoteEvent)
│       ├── CurrencyUpdate (RemoteEvent)
│       ├── AmmoUpdate (RemoteEvent)
│       ├── LobbyStateUpdate (RemoteEvent)
│       ├── ShowTitleScreen (RemoteEvent)
│       ├── HideTitleScreen (RemoteEvent)
│       ├── TitleScreenContinue (RemoteEvent)
│       ├── ShowEpilogue (RemoteEvent)
│       ├── HideEpilogue (RemoteEvent)
│       ├── EpilogueComplete (RemoteEvent)
│       ├── AchievementUnlocked (RemoteEvent)
│       ├── AnimationFire (RemoteEvent)
│       ├── AnimationFireReplicate (RemoteEvent)
│       ├── AnimationADS (RemoteEvent)
│       ├── AnimationADSReplicate (RemoteEvent)
│       ├── AnimationSprint (RemoteEvent)
│       └── AnimationSprintReplicate (RemoteEvent)
│
├── ServerStorage
│   ├── 📁 Maps (Folder) - Optional custom maps
│   │   └── 📁 MapName (Model) - Each map as a model
│   │       ├── 📁 ZombieSpawnPoints (Folder)
│   │       └── 📁 ResourceSpawnPoints (Folder)
│   └── 📁 ZombieModels (Folder) - Optional custom zombie models
│       ├── 🧱 Walker (Model) - R15/R6 with Humanoid
│       ├── 🧱 Runner (Model)
│       ├── 🧱 Brute (Model)
│       ├── 🧱 Spitter (Model)
│       └── 🧱 Boss (Model)
│
├── StarterPlayer
│   └── StarterPlayerScripts
│       ├── 📄 BootClient.lua (LocalScript) - Client boot entry point
│       ├── 📦 BootModule.lua (ModuleScript) - Boot module implementation
│       ├── 📦 ClientMainModule.lua (ModuleScript) - Client main module
│       ├── 📁 Modules (Folder)
│       │   ├── 📦 CureStationInteraction.lua (ModuleScript) - Cure station interaction handler
│       │   ├── 📦 FPSAnimationController.lua (ModuleScript) - FPS animation controller
│       │   ├── 📦 FPSAudioController.lua (ModuleScript) - FPS audio controller
│       │   ├── 📦 FPSMenuController.lua (ModuleScript) - FPS menu controller
│       │   ├── 📦 FPSMovement.lua (ModuleScript) - FPS movement controller
│       │   ├── 📦 FPSWeaponController.lua (ModuleScript) - FPS weapon controller
│       │   ├── 📦 FirstPersonCamera.lua (ModuleScript) - First-person camera module
│       │   ├── 📦 LoadingManager.lua (ModuleScript) - Loading screen manager
│       │   ├── 📦 MusicController.lua (ModuleScript) - Music playback controller
│       │   ├── 📦 StaminaClient.lua (ModuleScript) - Client stamina handler
│       │   ├── 📦 ViewModelController.lua (ModuleScript) - Weapon view model controller
│       │   ├── 📦 VoiceoverController.lua (ModuleScript) - Voiceover playback controller
│       │   └── 📁 UI (Folder)
│       │       ├── 📦 AchievementUI.lua (ModuleScript) - Achievement UI
│       │       ├── 📦 AllianceUI.lua (ModuleScript) - Alliance interface
│       │       ├── 📦 BaseHealthUI.lua (ModuleScript) - Base health bar
│       │       ├── 📦 ControlsTutorialUI.lua (ModuleScript) - Controls tutorial overlay
│       │       ├── 📦 CreditsUI.lua (ModuleScript) - Credits screen
│       │       ├── 📦 CureUI.lua (ModuleScript) - Cure progress display
│       │       ├── 📦 EpilogueUI.lua (ModuleScript) - Epilogue screen
│       │       ├── 📦 FPSHUD.lua (ModuleScript) - FPS HUD (crosshair, ammo)
│       │       ├── 📦 FunFactUI.lua (ModuleScript) - Fun fact display
│       │       ├── 📦 InventoryUI.lua (ModuleScript) - Player inventory
│       │       ├── 📦 LobbyUI.lua (ModuleScript) - Lobby interface
│       │       ├── 📦 MapUI.lua (ModuleScript) - Map display
│       │       ├── 📦 MapVotingUI.lua (ModuleScript) - Map voting interface
│       │       ├── 📦 NotificationUI.lua (ModuleScript) - Notification system
│       │       ├── 📦 PlayerHUD.lua (ModuleScript) - Player health and status
│       │       ├── 📦 PortalQueueUI.lua (ModuleScript) - Portal queue interface
│       │       ├── 📦 PuzzleMenuUI.lua (ModuleScript) - Puzzle selection menu
│       │       ├── 📦 PuzzleUI.lua (ModuleScript) - Puzzle minigame interface
│       │       ├── 📦 ScoreboardUI.lua (ModuleScript) - Player scoreboard
│       │       ├── 📦 ShopUI.lua (ModuleScript) - In-game shop
│       │       ├── 📦 SpectatorUI.lua (ModuleScript) - Spectator controls
│       │       ├── 📦 SynthesisUI.lua (ModuleScript) - Cure synthesis interface
│       │       ├── 📦 TitleScreenUI.lua (ModuleScript) - Title screen
│       │       ├── 📦 TouchControlsUI.lua (ModuleScript) - Mobile touch controls
│       │       └── 📦 WaveUI.lua (ModuleScript) - Wave number and time display
│       └── 📁 FPS (Folder)
│           └── 📁 Archived (Folder) - Archived FPS implementations
│
└── StarterGui
    └── (UI scripts are now in StarterPlayerScripts/Modules/UI as ModuleScripts)
```

> **Note on UI Scripts**: All UI scripts are now ModuleScripts located in `StarterPlayerScripts/Modules/UI/` and are loaded by the BootClient system. They are no longer placed directly in StarterGui as LocalScripts.

---

### Repository to Roblox Location Mapping

> **Important**: All file names use only the `.lua` extension. No additional dots like `.server.lua` or `.client.lua` are used to avoid sync tool compatibility issues.

| Repository File | Roblox Location | Script Type | Notes |
|-----------------|-----------------|-------------|-------|
| **Server Scripts** ||||
| `ServerScriptService/MainServerScript.lua` | ServerScriptService.MainServerScript | Script | Main entry point |
| `ServerScriptService/GameManager.lua` | ServerScriptService.GameManager | ModuleScript | |
| `ServerScriptService/PlayerManager.lua` | ServerScriptService.PlayerManager | ModuleScript | |
| `ServerScriptService/WaveManager.lua` | ServerScriptService.WaveManager | ModuleScript | |
| `ServerScriptService/BaseManager.lua` | ServerScriptService.BaseManager | ModuleScript | |
| `ServerScriptService/Spawner.lua` | ServerScriptService.Spawner | ModuleScript | |
| `ServerScriptService/CureService.lua` | ServerScriptService.CureService | ModuleScript | |
| `ServerScriptService/CureSynthesisService.lua` | ServerScriptService.CureSynthesisService | ModuleScript | |
| `ServerScriptService/PuzzleService.lua` | ServerScriptService.PuzzleService | ModuleScript | |
| `ServerScriptService/AllianceServiceV2.lua` | ServerScriptService.AllianceServiceV2 | ModuleScript | |
| `ServerScriptService/WeaponService.lua` | ServerScriptService.WeaponService | ModuleScript | |
| `ServerScriptService/FPSWeaponService.lua` | ServerScriptService.FPSWeaponService | ModuleScript | |
| `ServerScriptService/FPSAnimationService.lua` | ServerScriptService.FPSAnimationService | ModuleScript | |
| `ServerScriptService/ShopService.lua` | ServerScriptService.ShopService | ModuleScript | |
| `ServerScriptService/MapManager.lua` | ServerScriptService.MapManager | ModuleScript | |
| `ServerScriptService/LobbyManager.lua` | ServerScriptService.LobbyManager | ModuleScript | |
| `ServerScriptService/SpectatorManager.lua` | ServerScriptService.SpectatorManager | ModuleScript | |
| `ServerScriptService/ResourceSpawner.lua` | ServerScriptService.ResourceSpawner | ModuleScript | |
| `ServerScriptService/SprintService.lua` | ServerScriptService.SprintService | ModuleScript | |
| `ServerScriptService/AchievementService.lua` | ServerScriptService.AchievementService | ModuleScript | |
| `ServerScriptService/VoiceoverService.lua` | ServerScriptService.VoiceoverService | ModuleScript | |
| `ServerScriptService/FunFactService.lua` | ServerScriptService.FunFactService | ModuleScript | |
| `ServerScriptService/RemoteEventsBootstrap.lua` | ServerScriptService.RemoteEventsBootstrap | ModuleScript | |
| `ServerScriptService/AI/ZombieBrain.lua` | ServerScriptService.AI.ZombieBrain | ModuleScript | |
| `ServerScriptService/AI/AIDirector.lua` | ServerScriptService.AI.AIDirector | ModuleScript | |
| `ServerScriptService/AI/TargetingService.lua` | ServerScriptService.AI.TargetingService | ModuleScript | |
| `ServerScriptService/AI/SpitterController.lua` | ServerScriptService.AI.SpitterController | ModuleScript | |
| `ServerScriptService/AI/BossAuraService.lua` | ServerScriptService.AI.BossAuraService | ModuleScript | |
| `ServerScriptService/AI/SurroundService.lua` | ServerScriptService.AI.SurroundService | ModuleScript | |
| **Shared Scripts** ||||
| `ReplicatedStorage/Shared/GameConfig.lua` | ReplicatedStorage.Shared.GameConfig | ModuleScript | |
| `ReplicatedStorage/Shared/GameState.lua` | ReplicatedStorage.Shared.GameState | ModuleScript | |
| `ReplicatedStorage/Shared/WaveConfig.lua` | ReplicatedStorage.Shared.WaveConfig | ModuleScript | |
| `ReplicatedStorage/Shared/ZombieTypes.lua` | ReplicatedStorage.Shared.ZombieTypes | ModuleScript | |
| `ReplicatedStorage/Shared/WeaponConfig.lua` | ReplicatedStorage.Shared.WeaponConfig | ModuleScript | |
| `ReplicatedStorage/Shared/WeaponValues.lua` | ReplicatedStorage.Shared.WeaponValues | ModuleScript | |
| `ReplicatedStorage/Shared/FPSConfig.lua` | ReplicatedStorage.Shared.FPSConfig | ModuleScript | |
| `ReplicatedStorage/Shared/MapConfig.lua` | ReplicatedStorage.Shared.MapConfig | ModuleScript | |
| `ReplicatedStorage/Shared/PuzzleConfig.lua` | ReplicatedStorage.Shared.PuzzleConfig | ModuleScript | |
| `ReplicatedStorage/Shared/UIScaleConfig.lua` | ReplicatedStorage.Shared.UIScaleConfig | ModuleScript | |
| `ReplicatedStorage/Shared/UIScaleManager.lua` | ReplicatedStorage.Shared.UIScaleManager | ModuleScript | |
| `ReplicatedStorage/Shared/AssetConfig.lua` | ReplicatedStorage.Shared.AssetConfig | ModuleScript | |
| `ReplicatedStorage/Shared/AssetValidation.lua` | ReplicatedStorage.Shared.AssetValidation | ModuleScript | |
| `ReplicatedStorage/Shared/Remotes/RemoteRegistry.lua` | ReplicatedStorage.Shared.Remotes.RemoteRegistry | ModuleScript | |
| **Client Scripts** ||||
| `StarterPlayer/StarterPlayerScripts/BootClient.lua` | StarterPlayerScripts.BootClient | LocalScript | Client entry point |
| `StarterPlayer/StarterPlayerScripts/BootModule.lua` | StarterPlayerScripts.BootModule | ModuleScript | |
| `StarterPlayer/StarterPlayerScripts/ClientMainModule.lua` | StarterPlayerScripts.ClientMainModule | ModuleScript | |
| `StarterPlayer/StarterPlayerScripts/Modules/FPSWeaponController.lua` | StarterPlayerScripts.Modules.FPSWeaponController | ModuleScript | |
| `StarterPlayer/StarterPlayerScripts/Modules/FPSMovement.lua` | StarterPlayerScripts.Modules.FPSMovement | ModuleScript | |
| `StarterPlayer/StarterPlayerScripts/Modules/FirstPersonCamera.lua` | StarterPlayerScripts.Modules.FirstPersonCamera | ModuleScript | |
| `StarterPlayer/StarterPlayerScripts/Modules/UI/*` | StarterPlayerScripts.Modules.UI.* | ModuleScript | All UI modules |

> **Note**: The repository structure now matches Roblox Studio exactly. Simply copy folders directly without reorganization.

---

## Detailed Setup

### Step 1: Create Roblox Place

1. Launch Roblox Studio
2. File → New → Baseplate (or open existing place)

### Step 2: Create Workspace Elements

**Required Setup in Workspace:**

1. **Base** - Part or Model named "Base" (what players defend)
2. **ZombieSpawnPoints** - Folder with Part children positioned around map edges
3. **ResourceSpawnPoints** - Folder with Part children distributed across map

**Optional:**
4. **CureStations** - Folder with Parts that have ProximityPrompts for puzzle interaction

### Step 3: Import Server Scripts to ServerScriptService

Create the following scripts in **ServerScriptService**:

| Script Name | Type | Repository File |
|-------------|------|-----------------|
| MainServerScript | **Script** | `ServerScriptService/MainServerScript.lua` |
| GameManager | ModuleScript | `ServerScriptService/GameManager.lua` |
| PlayerManager | ModuleScript | `ServerScriptService/PlayerManager.lua` |
| WaveManager | ModuleScript | `ServerScriptService/WaveManager.lua` |
| BaseManager | ModuleScript | `ServerScriptService/BaseManager.lua` |
| Spawner | ModuleScript | `ServerScriptService/Spawner.lua` |
| CureService | ModuleScript | `ServerScriptService/CureService.lua` |
| CureSynthesisService | ModuleScript | `ServerScriptService/CureSynthesisService.lua` |
| PuzzleService | ModuleScript | `ServerScriptService/PuzzleService.lua` |
| AllianceServiceV2 | ModuleScript | `ServerScriptService/AllianceServiceV2.lua` |
| WeaponService | ModuleScript | `ServerScriptService/WeaponService.lua` |
| FPSWeaponService | ModuleScript | `ServerScriptService/FPSWeaponService.lua` |
| FPSAnimationService | ModuleScript | `ServerScriptService/FPSAnimationService.lua` |
| ShopService | ModuleScript | `ServerScriptService/ShopService.lua` |
| MapManager | ModuleScript | `ServerScriptService/MapManager.lua` |
| LobbyManager | ModuleScript | `ServerScriptService/LobbyManager.lua` |
| SpectatorManager | ModuleScript | `ServerScriptService/SpectatorManager.lua` |
| ResourceSpawner | ModuleScript | `ServerScriptService/ResourceSpawner.lua` |
| SprintService | ModuleScript | `ServerScriptService/SprintService.lua` |
| AchievementService | ModuleScript | `ServerScriptService/AchievementService.lua` |
| VoiceoverService | ModuleScript | `ServerScriptService/VoiceoverService.lua` |
| FunFactService | ModuleScript | `ServerScriptService/FunFactService.lua` |
| RemoteEventsBootstrap | ModuleScript | `ServerScriptService/RemoteEventsBootstrap.lua` |

**AI Folder:**
1. Copy the `AI` folder from `ServerScriptService/AI/` to game.ServerScriptService
2. Contains: `ZombieBrain`, `AIDirector`, `TargetingService`, `SpitterController`, `BossAuraService`, `SurroundService` (all ModuleScripts)

**Alliance Folder:**
1. Copy the `Alliance` folder from `ServerScriptService/Alliance/` to game.ServerScriptService
2. Contains: `AllianceGraph`, `BetrayalService`, `InventoryLedger`, `PoolCalculator` (all ModuleScripts)

> **⚠️ Important**: Only `MainServerScript` should be a **Script**. All others are **ModuleScripts**.

### Step 4: Import Shared Scripts to ReplicatedStorage

1. Copy the `ReplicatedStorage/Shared/` folder from the repository to game.ReplicatedStorage
2. This includes all configuration ModuleScripts:

| Script Name | Type | Repository File |
|-------------|------|-----------------|
| GameConfig | ModuleScript | `ReplicatedStorage/Shared/GameConfig.lua` |
| GameState | ModuleScript | `ReplicatedStorage/Shared/GameState.lua` |
| WaveConfig | ModuleScript | `ReplicatedStorage/Shared/WaveConfig.lua` |
| ZombieTypes | ModuleScript | `ReplicatedStorage/Shared/ZombieTypes.lua` |
| WeaponConfig | ModuleScript | `ReplicatedStorage/Shared/WeaponConfig.lua` |
| WeaponValues | ModuleScript | `ReplicatedStorage/Shared/WeaponValues.lua` |
| FPSConfig | ModuleScript | `ReplicatedStorage/Shared/FPSConfig.lua` |
| MapConfig | ModuleScript | `ReplicatedStorage/Shared/MapConfig.lua` |
| PuzzleConfig | ModuleScript | `ReplicatedStorage/Shared/PuzzleConfig.lua` |
| UIScaleConfig | ModuleScript | `ReplicatedStorage/Shared/UIScaleConfig.lua` |
| UIScaleManager | ModuleScript | `ReplicatedStorage/Shared/UIScaleManager.lua` |
| AssetConfig | ModuleScript | `ReplicatedStorage/Shared/AssetConfig.lua` |
| AssetValidation | ModuleScript | `ReplicatedStorage/Shared/AssetValidation.lua` |
| FunFactConfig | ModuleScript | `ReplicatedStorage/Shared/FunFactConfig.lua` |
| StoryConfig | ModuleScript | `ReplicatedStorage/Shared/StoryConfig.lua` |
| PortalConfig | ModuleScript | `ReplicatedStorage/Shared/PortalConfig.lua` |
| InputActionRegistry | ModuleScript | `ReplicatedStorage/Shared/InputActionRegistry.lua` |
| InputManager | ModuleScript | `ReplicatedStorage/Shared/InputManager.lua` |
| ModalManager | ModuleScript | `ReplicatedStorage/Shared/ModalManager.lua` |
| MathUtil | ModuleScript | `ReplicatedStorage/Shared/MathUtil.lua` |
| RemoteEventUtil | ModuleScript | `ReplicatedStorage/Shared/RemoteEventUtil.lua` |
| UIDebugConfig | ModuleScript | `ReplicatedStorage/Shared/UIDebugConfig.lua` |

**Remotes Folder:**
1. Copy the `Remotes` folder from `ReplicatedStorage/Shared/Remotes/` to game.ReplicatedStorage.Shared
2. Contains: `RemoteRegistry.lua` (ModuleScript)

### Step 5: Import Client Scripts to StarterPlayerScripts

Copy the `StarterPlayer/StarterPlayerScripts/` folders from the repository to game.StarterPlayer.StarterPlayerScripts:

**Root Level:**
| Script Name | Type | Repository File |
|-------------|------|-----------------|
| BootClient | **LocalScript** | `StarterPlayer/StarterPlayerScripts/BootClient.lua` |
| BootModule | ModuleScript | `StarterPlayer/StarterPlayerScripts/BootModule.lua` |
| ClientMainModule | ModuleScript | `StarterPlayer/StarterPlayerScripts/ClientMainModule.lua` |

**Modules Folder:**
1. Copy the `Modules` folder from `StarterPlayer/StarterPlayerScripts/Modules/` to game.StarterPlayer.StarterPlayerScripts
2. Contains all client-side controller modules and UI modules

Key files include:
- `Modules/FPSWeaponController.lua` (ModuleScript)
- `Modules/FPSMovement.lua` (ModuleScript)
- `Modules/FirstPersonCamera.lua` (ModuleScript)
- `Modules/FPSAnimationController.lua` (ModuleScript)
- `Modules/FPSAudioController.lua` (ModuleScript)
- `Modules/LoadingManager.lua` (ModuleScript)
- `Modules/MusicController.lua` (ModuleScript)
- `Modules/ViewModelController.lua` (ModuleScript)
- `Modules/VoiceoverController.lua` (ModuleScript)
- `Modules/UI/*` (All UI ModuleScripts)

> **Note**: All UI scripts are now ModuleScripts in the `Modules/UI/` folder, loaded by the boot system. They are no longer placed directly in StarterGui.

### Step 6: StarterGui Setup

**No manual setup required for StarterGui**. All UI scripts are now ModuleScripts located in `StarterPlayer/StarterPlayerScripts/Modules/UI/` and are loaded automatically by the boot system.

If you copied the `Modules/UI/` folder in Step 5, you're all set. The boot system will handle loading and initializing all UI components.

### Step 7: ServerStorage Setup (Optional)

**Maps Folder:**
- Create `ServerStorage/Maps` folder
- Add custom map Models with `ZombieSpawnPoints` and `ResourceSpawnPoints` folders
- Game uses Workspace map if none provided

**ZombieModels Folder:**
- Create `ServerStorage/ZombieModels` folder
- Add R15/R6 Models named: Walker, Runner, Brute, Spitter, Boss
- Must have Humanoid and HumanoidRootPart
- Game creates basic zombies if none provided

### Step 8: Verify RemoteEvents Folder

The RemoteEvents folder in ReplicatedStorage is created automatically by `RemoteEventsBootstrap.lua` when the game starts. You don't need to create these manually.

**Automatic Creation**: When `MainServerScript` runs, it calls `RemoteEventsBootstrap` which creates all necessary RemoteEvent instances in `ReplicatedStorage/RemoteEvents/`. This includes all game state, player, weapon, shop, alliance, puzzle, sprint, map/lobby, spectator, and scoreboard events.

### Step 9: Verify Script Names and Types

All scripts use proper Roblox service imports and are ready to use. **Important naming convention**:

- **Server Scripts**: Regular `.lua` extension only (e.g., `MainServerScript.lua` NOT `Main.server.lua`)
- **Client Scripts**: Regular `.lua` extension only (e.g., `BootClient.lua` NOT `Boot.client.lua`)
- **Module Scripts**: Regular `.lua` extension only (e.g., `GameManager.lua`)

This naming convention prevents compatibility issues with Roblox sync tools like Rojo and GitSync.

```lua
-- Example imports in scripts:
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- For requiring shared modules:
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

-- For requiring sibling modules in ServerScriptService:
local PlayerManager = require(script.Parent.PlayerManager)
```

No changes needed - the repository structure matches Roblox Studio exactly. Simply copy folders as-is.

---

## Map Configuration

### Required Workspace Setup

1. **Base** - Part/Model in center of map (players defend this)
2. **ZombieSpawnPoints** - Folder with Parts around map perimeter
3. **ResourceSpawnPoints** - Folder with Parts distributed across map

### Layout Tips

- Keep base centrally located
- Distribute 6-12 zombie spawn points around edges
- Place 8-15 resource points at varying distances from base
- Add cover and obstacles for tactical gameplay

---

## Testing

### Single Player Test
1. Click **Play** in Roblox Studio
2. Verify: Wave spawning, player health, base health, component collection

### Multiplayer Test  
1. Click Play dropdown → Select 2-8 players → Start
2. Verify: Alliances, betrayal, component sharing, cooperative defense

### Key Features to Test
- Title screen and lobby system
- Wave spawning and zombie AI
- FPS weapons (shooting, reloading, ADS)
- Sprint and stamina
- Puzzle minigames and cure synthesis
- Alliance system
- Spectator mode on death
- Scoreboard (TAB key)
- Victory (cure 100%) and defeat (base destroyed) conditions

---

## Troubleshooting

### Common Issues

**"Script is not a ModuleScript"**  
Make sure you created ModuleScripts (not Scripts) for all modules. Only `MainServerScript` and `BootClient` should be Scripts/LocalScripts.

**"Attempt to index nil value"**  
Check `require()` paths. Use: `require(game.ReplicatedStorage.Shared.GameConfig)`

**"Waves not starting"**  
Verify `MainServerScript` is a Script (not ModuleScript) in ServerScriptService and is enabled.

**"Components not spawning"**  
Ensure ResourceSpawnPoints folder exists in Workspace with Part children positioned on the map.

### Debugging Tips

Check the Output window in Roblox Studio for error messages. The boot sequence prints detailed status messages showing what's loading.

---

## Configuration

Game balance settings are in `ReplicatedStorage/Shared/GameConfig.lua`. Edit in Roblox Studio to adjust difficulty:

```lua
-- Example adjustments
GameConfig.STARTING_HEALTH = 150          -- Player starting health
GameConfig.BASE_HEALTH = 1500             -- Base starting health  
GameConfig.ZOMBIE_DAMAGE = 5              -- Damage zombies deal
GameConfig.ZOMBIE_HEALTH_MULTIPLIER = 1.5 -- Zombie health scaling
```

See `WaveConfig.lua`, `WeaponConfig.lua`, and `ZombieTypes.lua` for additional tuning options.

---

## Next Steps

The game is functional after basic setup. Optional enhancements:

1. **Custom Zombie Models** - Add R15/R6 models to `ServerStorage.ZombieModels` (Walker, Runner, Brute, Spitter, Boss)
2. **Custom Maps** - Create map models in `ServerStorage.Maps` with spawn point folders
3. **Sound Effects** - Update `AssetConfig.lua` with Roblox sound asset IDs
4. **Balance Tuning** - Adjust config files and playtest with multiple players

---

## Publishing

To publish your game:

1. **File → Publish to Roblox**
2. Set game name and description
3. Configure max players: **8**
4. Set genre: Adventure / Survival
5. Add game icon and thumbnails
6. Enable FilteringEnabled (should be on by default)

---

## Support

For help or questions:
- **Documentation**: See [DOCUMENTATION.md](DOCUMENTATION.md) for complete docs index
- **API Reference**: See [API_DOCUMENTATION.md](API_DOCUMENTATION.md)
- **Game Design**: See [GAME_DESIGN.md](GAME_DESIGN.md)
- **GitHub Issues**: Visit the repository issues page

---

**Installation Guide Version**: 3.0  
**Last Updated**: 2026-02-11  
**Compatible with**: Roblox Studio (Latest)