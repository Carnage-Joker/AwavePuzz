-- @ScriptType: Script
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
3. Import scripts from `src/` to appropriate locations:
   - `src/server/*` → ServerScriptService
   - `src/client/*` → StarterPlayer.StarterPlayerScripts and StarterGui
   - `src/shared/*` → ReplicatedStorage.Shared
4. Configure spawn points and workspace elements
5. Test in multiplayer

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
│   ├── 📜 MainServer.lua (Script) - Main entry point, initializes all services
│   ├── 📦 GameManager.lua (ModuleScript) - Orchestrates game state, waves, win/lose
│   ├── 📦 GameServer.lua (ModuleScript) - Core game controller
│   ├── 📦 PlayerManager.lua (ModuleScript) - Player data, inventory, currency
│   ├── 📦 WaveManager.lua (ModuleScript) - Wave timing and zombie counts
│   ├── 📦 BaseManager.lua (ModuleScript) - Base health and damage tracking
│   ├── 📦 Spawner.lua (ModuleScript) - Zombie spawning and AI initialization
│   ├── 📦 CureService.lua (ModuleScript) - Cure progress and component tracking
│   ├── 📦 CureCraftingManager.lua (ModuleScript) - Legacy cure crafting system
│   ├── 📦 PuzzleService.lua (ModuleScript) - Puzzle generation and validation
│   ├── 📦 AllianceService.lua (ModuleScript) - Player alliance management
│   ├── 📦 WeaponService.lua (ModuleScript) - Server-authoritative weapon handling
│   ├── 📦 FPSWeaponService.lua (ModuleScript) - FPS ammo and reload management
│   ├── 📦 ShopService.lua (ModuleScript) - In-game shop and purchases
│   ├── 📦 MapManager.lua (ModuleScript) - Multi-map loading system
│   ├── 📦 LobbyManager.lua (ModuleScript) - Pre-round lobby and map voting
│   ├── 📦 SpectatorManager.lua (ModuleScript) - Dead player spectator system
│   ├── 📦 ResourceSpawner.lua (ModuleScript) - Cure component spawning
│   ├── 📦 SprintService.lua (ModuleScript) - Server-authoritative stamina
│   └── 📁 AIScripts (Folder)
│       └── 📦 ZombieBrain.lua (ModuleScript) - Zombie AI and pathfinding
│
├── ReplicatedStorage
│   ├── 📁 Shared (Folder)
│   │   ├── 📦 GameConfig.lua (ModuleScript) - Core game settings
│   │   ├── 📦 GameState.lua (ModuleScript) - Game state definitions
│   │   ├── 📦 WaveConfig.lua (ModuleScript) - Wave progression settings
│   │   ├── 📦 ZombieTypes.lua (ModuleScript) - Zombie stats and types
│   │   ├── 📦 WeaponConfig.lua (ModuleScript) - Weapon definitions
│   │   ├── 📦 FPSConfig.lua (ModuleScript) - FPS camera and controls
│   │   ├── 📦 MapConfig.lua (ModuleScript) - Available maps configuration
│   │   ├── 📦 PuzzleConfig.lua (ModuleScript) - Puzzle definitions
│   │   ├── 📦 UIScaleConfig.lua (ModuleScript) - UI scaling breakpoints
│   │   ├── 📦 UIScaleManager.lua (ModuleScript) - Responsive UI utilities
│   │   └── 📦 CureStationSetup.lua (ModuleScript) - Cure station initialization
│   └── 📁 RemoteEvents (Folder) - Created automatically by services
│       ├── WaveAnnounce (RemoteEvent)
│       ├── WaveUpdate (RemoteEvent)
│       ├── GameStateUpdate (RemoteEvent)
│       ├── CureUpdate (RemoteEvent)
│       ├── BaseHealthUpdate (RemoteEvent)
│       ├── PlayerHealthUpdate (RemoteEvent)
│       ├── WeaponFire (RemoteEvent)
│       ├── WeaponEquip (RemoteEvent)
│       ├── WeaponReload (RemoteEvent)
│       ├── WeaponLoadoutUpdate (RemoteEvent)
│       ├── WeaponHitConfirm (RemoteEvent)
│       ├── ShopCatalog (RemoteEvent)
│       ├── ShopPurchase (RemoteEvent)
│       ├── AllianceRequest (RemoteEvent)
│       ├── AllianceResponse (RemoteEvent)
│       ├── AllianceUpdate (RemoteEvent)
│       ├── BetrayalNotify (RemoteEvent)
│       ├── ComponentCollected (RemoteEvent)
│       ├── RequestPuzzle (RemoteEvent)
│       ├── PuzzleStart (RemoteEvent)
│       ├── PuzzleSubmit (RemoteEvent)
│       ├── PuzzleResult (RemoteEvent)
│       ├── SprintRequest (RemoteEvent)
│       ├── StaminaUpdate (RemoteEvent)
│       ├── MapVoteStart (RemoteEvent)
│       ├── MapVoteUpdate (RemoteEvent)
│       ├── MapVoteEnd (RemoteEvent)
│       ├── MapUpdate (RemoteEvent)
│       ├── SpectatorEnter (RemoteEvent)
│       ├── SpectatorExit (RemoteEvent)
│       ├── SpectatorTargetUpdate (RemoteEvent)
│       ├── SpectatorAliveList (RemoteEvent)
│       ├── ScoreboardUpdate (RemoteEvent)
│       ├── ShowScoreboard (RemoteEvent)
│       ├── HideScoreboard (RemoteEvent)
│       ├── InventoryUpdate (RemoteEvent)
│       └── AmmoUpdate (RemoteEvent)
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
│       ├── 📦 ClientController.lua (ModuleScript) - Client game state
│       ├── 📄 WeaponController.client.lua (LocalScript) - Basic weapon input
│       ├── 📄 FPSWeaponController.client.lua (LocalScript) - Full FPS weapon system
│       ├── 📄 FirstPersonCamera.client.lua (LocalScript) - FPS camera controller
│       ├── 📄 FPSMovementController.client.lua (LocalScript) - Movement with crouch/sprint
│       ├── 📄 FPSAudioController.client.lua (LocalScript) - Weapon and footstep sounds
│       ├── 📄 FPSMenuController.client.lua (LocalScript) - Controller-friendly menus
│       ├── 📄 SprintController.client.lua (LocalScript) - Sprint input handler
│       └── 📁 FPS (Folder)
│           ├── 📦 FirstPersonCamera.lua (ModuleScript) - Camera module
│           └── 📄 FirstPersonController.client.lua (LocalScript) - Camera bootstrap
│
└── StarterGui
    ├── 📄 WaveUI.client.lua (LocalScript) - Wave number and time display
    ├── 📄 BaseHealthUI.client.lua (LocalScript) - Base health bar
    ├── 📄 CureUI.client.lua (LocalScript) - Cure progress display
    ├── 📄 AllianceUI.client.lua (LocalScript) - Alliance interface
    ├── 📄 ShopUI.client.lua (LocalScript) - In-game shop
    ├── 📄 InventoryUI.client.lua (LocalScript) - Player inventory
    ├── 📄 PlayerHUD.client.lua (LocalScript) - Health bar and compass
    ├── 📄 FPSHUD.client.lua (LocalScript) - Crosshair, ammo counter
    ├── 📄 PuzzleUI.client.lua (LocalScript) - Puzzle minigame interface
    ├── 📄 PuzzleMenuUI.client.lua (LocalScript) - Puzzle selection menu
    ├── 📄 MapVotingUI.client.lua (LocalScript) - Map voting in lobby
    ├── 📄 SpectatorUI.client.lua (LocalScript) - Spectator controls
    └── 📄 ScoreboardUI.client.lua (LocalScript) - Player scoreboard
```

---

### Source File to Roblox Location Mapping

| Source File | Roblox Location | Script Type |
|-------------|-----------------|-------------|
| **Server Scripts** |||
| `src/server/MainServer.lua` | ServerScriptService.MainServer | Script |
| `src/server/GameManager.lua` | ServerScriptService.GameManager | ModuleScript |
| `src/server/GameServer.lua` | ServerScriptService.GameServer | ModuleScript |
| `src/server/PlayerManager.lua` | ServerScriptService.PlayerManager | ModuleScript |
| `src/server/WaveManager.lua` | ServerScriptService.WaveManager | ModuleScript |
| `src/server/BaseManager.lua` | ServerScriptService.BaseManager | ModuleScript |
| `src/server/Spawner.lua` | ServerScriptService.Spawner | ModuleScript |
| `src/server/CureService.lua` | ServerScriptService.CureService | ModuleScript |
| `src/server/CureCraftingManager.lua` | ServerScriptService.CureCraftingManager | ModuleScript |
| `src/server/PuzzleService.lua` | ServerScriptService.PuzzleService | ModuleScript |
| `src/server/AllianceService.lua` | ServerScriptService.AllianceService | ModuleScript |
| `src/server/WeaponService.lua` | ServerScriptService.WeaponService | ModuleScript |
| `src/server/FPSWeaponService.lua` | ServerScriptService.FPSWeaponService | ModuleScript |
| `src/server/ShopService.lua` | ServerScriptService.ShopService | ModuleScript |
| `src/server/MapManager.lua` | ServerScriptService.MapManager | ModuleScript |
| `src/server/LobbyManager.lua` | ServerScriptService.LobbyManager | ModuleScript |
| `src/server/SpectatorManager.lua` | ServerScriptService.SpectatorManager | ModuleScript |
| `src/server/ResourceSpawner.lua` | ServerScriptService.ResourceSpawner | ModuleScript |
| `src/server/SprintService.lua` | ServerScriptService.SprintService | ModuleScript |
| `src/server/CureStationSetup.lua` | ReplicatedStorage.Shared.CureStationSetup | ModuleScript |
| `src/server/AIScripts/ZombieBrain.lua` | ServerScriptService.AIScripts.ZombieBrain | ModuleScript |
| **Shared Scripts** |||
| `src/shared/GameConfig.lua` | ReplicatedStorage.Shared.GameConfig | ModuleScript |
| `src/shared/GameState.lua` | ReplicatedStorage.Shared.GameState | ModuleScript |
| `src/shared/WaveConfig.lua` | ReplicatedStorage.Shared.WaveConfig | ModuleScript |
| `src/shared/ZombieTypes.lua` | ReplicatedStorage.Shared.ZombieTypes | ModuleScript |
| `src/shared/WeaponConfig.lua` | ReplicatedStorage.Shared.WeaponConfig | ModuleScript |
| `src/shared/FPSConfig.lua` | ReplicatedStorage.Shared.FPSConfig | ModuleScript |
| `src/shared/MapConfig.lua` | ReplicatedStorage.Shared.MapConfig | ModuleScript |
| `src/shared/PuzzleConfig.lua` | ReplicatedStorage.Shared.PuzzleConfig | ModuleScript |
| `src/shared/UIScaleConfig.lua` | ReplicatedStorage.Shared.UIScaleConfig | ModuleScript |
| `src/shared/UIScaleManager.lua` | ReplicatedStorage.Shared.UIScaleManager | ModuleScript |
| **Client Scripts** |||
| `src/client/ClientController.lua` | StarterPlayerScripts.ClientController | ModuleScript |
| `src/client/WeaponController.client.lua` | StarterPlayerScripts.WeaponController | LocalScript |
| `src/client/FPSWeaponController.client.lua` | StarterPlayerScripts.FPSWeaponController | LocalScript |
| `src/client/FirstPersonCamera.client.lua` | StarterPlayerScripts.FirstPersonCamera | LocalScript |
| `src/client/FPSMovementController.client.lua` | StarterPlayerScripts.FPSMovementController | LocalScript |
| `src/client/FPSAudioController.client.lua` | StarterPlayerScripts.FPSAudioController | LocalScript |
| `src/client/FPSMenuController.client.lua` | StarterPlayerScripts.FPSMenuController | LocalScript |
| `src/client/SprintController.client.lua` | StarterPlayerScripts.SprintController | LocalScript |
| `src/client/FPS/FirstPersonCamera.lua` | StarterPlayerScripts.FPS.FirstPersonCamera | ModuleScript |
| `src/client/FPS/FirstPersonController.client.lua` | StarterPlayerScripts.FPS.FirstPersonController | LocalScript |
| **UI Scripts** |||
| `src/client/UI/WaveUI.client.lua` | StarterGui.WaveUI | LocalScript |
| `src/client/UI/BaseHealthUI.client.lua` | StarterGui.BaseHealthUI | LocalScript |
| `src/client/UI/CureUI.client.lua` | StarterGui.CureUI | LocalScript |
| `src/client/UI/AllianceUI.client.lua` | StarterGui.AllianceUI | LocalScript |
| `src/client/UI/ShopUI.client.lua` | StarterGui.ShopUI | LocalScript |
| `src/client/UI/InventoryUI.client.lua` | StarterGui.InventoryUI | LocalScript |
| `src/client/UI/PlayerHUD.client.lua` | StarterGui.PlayerHUD | LocalScript |
| `src/client/UI/FPSHUD.client.lua` | StarterGui.FPSHUD | LocalScript |
| `src/client/UI/PuzzleUI.client.lua` | StarterGui.PuzzleUI | LocalScript |
| `src/client/UI/PuzzleMenuUI.client.lua` | StarterGui.PuzzleMenuUI | LocalScript |
| `src/client/UI/MapVotingUI.client.lua` | StarterGui.MapVotingUI | LocalScript |
| `src/client/UI/SpectatorUI.client.lua` | StarterGui.SpectatorUI | LocalScript |
| `src/client/UI/ScoreboardUI.client.lua` | StarterGui.ScoreboardUI | LocalScript |

---

## Detailed Setup

### Step 1: Create or Open a Roblox Place

1. Launch **Roblox Studio**
2. Choose one of:
   - **New Place**: File → New → Baseplate
   - **Existing Place**: Open from your games

### Step 2: Create Workspace Structure

Before importing scripts, set up the required Workspace elements:

1. **Create the Base** (Part or Model)
   - Add a Part or Model named `Base` to Workspace
   - Position it centrally in your map
   - This represents what players defend from zombies

2. **Create ZombieSpawnPoints folder**
   - In Workspace, create a Folder named `ZombieSpawnPoints`
   - Add Part instances inside (name them SpawnPoint1, SpawnPoint2, etc.)
   - Position around the perimeter of your play area
   - Zombies will spawn at these locations

3. **Create ResourceSpawnPoints folder**
   - In Workspace, create a Folder named `ResourceSpawnPoints`
   - Add Part instances inside (name them ResourcePoint1, ResourcePoint2, etc.)
   - Distribute throughout the map
   - Cure components will appear at these locations

4. **Create CureStations folder** (Optional)
   - In Workspace, create a Folder named `CureStations`
   - Add Part instances with ProximityPrompts for puzzle interaction

### Step 3: Import Server Scripts to ServerScriptService

Create the following scripts in **ServerScriptService**:

| Script Name | Type | Source File |
|-------------|------|-------------|
| MainServer | **Script** | `src/server/MainServer.lua` |
| GameManager | ModuleScript | `src/server/GameManager.lua` |
| GameServer | ModuleScript | `src/server/GameServer.lua` |
| PlayerManager | ModuleScript | `src/server/PlayerManager.lua` |
| WaveManager | ModuleScript | `src/server/WaveManager.lua` |
| BaseManager | ModuleScript | `src/server/BaseManager.lua` |
| Spawner | ModuleScript | `src/server/Spawner.lua` |
| CureService | ModuleScript | `src/server/CureService.lua` |
| CureCraftingManager | ModuleScript | `src/server/CureCraftingManager.lua` |
| PuzzleService | ModuleScript | `src/server/PuzzleService.lua` |
| AllianceService | ModuleScript | `src/server/AllianceService.lua` |
| WeaponService | ModuleScript | `src/server/WeaponService.lua` |
| FPSWeaponService | ModuleScript | `src/server/FPSWeaponService.lua` |
| ShopService | ModuleScript | `src/server/ShopService.lua` |
| MapManager | ModuleScript | `src/server/MapManager.lua` |
| LobbyManager | ModuleScript | `src/server/LobbyManager.lua` |
| SpectatorManager | ModuleScript | `src/server/SpectatorManager.lua` |
| ResourceSpawner | ModuleScript | `src/server/ResourceSpawner.lua` |
| SprintService | ModuleScript | `src/server/SprintService.lua` |

**AIScripts Folder:**
1. Create a Folder named `AIScripts` in ServerScriptService
2. Inside AIScripts, create:
   - `ZombieBrain` (ModuleScript) → `src/server/AIScripts/ZombieBrain.lua`

> **⚠️ Important**: Only `MainServer` should be a **Script**. All others are **ModuleScripts**.

### Step 4: Import Shared Scripts to ReplicatedStorage

1. In **ReplicatedStorage**, create a Folder named `Shared`
2. Create ModuleScripts inside the Shared folder:

| Script Name | Type | Source File |
|-------------|------|-------------|
| GameConfig | ModuleScript | `src/shared/GameConfig.lua` |
| GameState | ModuleScript | `src/shared/GameState.lua` |
| WaveConfig | ModuleScript | `src/shared/WaveConfig.lua` |
| ZombieTypes | ModuleScript | `src/shared/ZombieTypes.lua` |
| WeaponConfig | ModuleScript | `src/shared/WeaponConfig.lua` |
| FPSConfig | ModuleScript | `src/shared/FPSConfig.lua` |
| MapConfig | ModuleScript | `src/shared/MapConfig.lua` |
| PuzzleConfig | ModuleScript | `src/shared/PuzzleConfig.lua` |
| UIScaleConfig | ModuleScript | `src/shared/UIScaleConfig.lua` |
| UIScaleManager | ModuleScript | `src/shared/UIScaleManager.lua` |
| CureStationSetup | ModuleScript | `src/server/CureStationSetup.lua` |

> **Note**: `CureStationSetup.lua` is in the `src/server/` folder but must be placed in `ReplicatedStorage.Shared` for proper require paths.

### Step 5: Import Client Scripts to StarterPlayerScripts

In **StarterPlayer** → **StarterPlayerScripts**, create:

| Script Name | Type | Source File |
|-------------|------|-------------|
| ClientController | ModuleScript | `src/client/ClientController.lua` |
| WeaponController | LocalScript | `src/client/WeaponController.client.lua` |
| FPSWeaponController | LocalScript | `src/client/FPSWeaponController.client.lua` |
| FirstPersonCamera | LocalScript | `src/client/FirstPersonCamera.client.lua` |
| FPSMovementController | LocalScript | `src/client/FPSMovementController.client.lua` |
| FPSAudioController | LocalScript | `src/client/FPSAudioController.client.lua` |
| FPSMenuController | LocalScript | `src/client/FPSMenuController.client.lua` |
| SprintController | LocalScript | `src/client/SprintController.client.lua` |

**FPS Folder:**
1. Create a Folder named `FPS` in StarterPlayerScripts
2. Inside FPS, create:
   - `FirstPersonCamera` (ModuleScript) → `src/client/FPS/FirstPersonCamera.lua`
   - `FirstPersonController` (LocalScript) → `src/client/FPS/FirstPersonController.client.lua`

### Step 6: Import UI Scripts to StarterGui

In **StarterGui**, create LocalScripts:

| Script Name | Type | Source File |
|-------------|------|-------------|
| WaveUI | LocalScript | `src/client/UI/WaveUI.client.lua` |
| BaseHealthUI | LocalScript | `src/client/UI/BaseHealthUI.client.lua` |
| CureUI | LocalScript | `src/client/UI/CureUI.client.lua` |
| AllianceUI | LocalScript | `src/client/UI/AllianceUI.client.lua` |
| ShopUI | LocalScript | `src/client/UI/ShopUI.client.lua` |
| InventoryUI | LocalScript | `src/client/UI/InventoryUI.client.lua` |
| PlayerHUD | LocalScript | `src/client/UI/PlayerHUD.client.lua` |
| FPSHUD | LocalScript | `src/client/UI/FPSHUD.client.lua` |
| PuzzleUI | LocalScript | `src/client/UI/PuzzleUI.client.lua` |
| PuzzleMenuUI | LocalScript | `src/client/UI/PuzzleMenuUI.client.lua` |
| MapVotingUI | LocalScript | `src/client/UI/MapVotingUI.client.lua` |
| SpectatorUI | LocalScript | `src/client/UI/SpectatorUI.client.lua` |
| ScoreboardUI | LocalScript | `src/client/UI/ScoreboardUI.client.lua` |

### Step 7: Create ServerStorage Structure

1. In **ServerStorage**, create a Folder named `Maps`
   - (Optional) Add custom map Models to the Maps folder
   - Each map Model should contain:
     - `ZombieSpawnPoints` (Folder with Part spawn locations)
     - `ResourceSpawnPoints` (Folder with Part spawn locations)
   - The game will use the default Workspace map if none are provided

2. Create a Folder named `ZombieModels` (Optional)
   - Add R15 or R6 character Models with Humanoid and HumanoidRootPart
   - Name them: `Walker`, `Runner`, `Brute`, `Spitter`, `Boss`
   - The game will create basic zombies procedurally if none are provided

### Step 8: Verify RemoteEvents Folder

The RemoteEvents folder in ReplicatedStorage is created automatically by the server scripts when the game starts. You don't need to create these manually, but if you want to pre-create them:

1. In **ReplicatedStorage**, create a Folder named `RemoteEvents`
2. The following RemoteEvents will be used (created automatically if missing):

**Game State Events:**
- WaveAnnounce, WaveUpdate, GameStateUpdate, CureUpdate, BaseHealthUpdate

**Player Events:**
- PlayerHealthUpdate, InventoryUpdate

**Weapon Events:**
- WeaponFire, WeaponEquip, WeaponReload, WeaponLoadoutUpdate, WeaponHitConfirm, AmmoUpdate

**Shop Events:**
- ShopCatalog, ShopPurchase

**Alliance Events:**
- AllianceRequest, AllianceResponse, AllianceUpdate, BetrayalNotify

**Puzzle Events:**
- ComponentCollected, RequestPuzzle, PuzzleStart, PuzzleSubmit, PuzzleResult

**Sprint Events:**
- SprintRequest, StaminaUpdate

**Map/Lobby Events:**
- MapVoteStart, MapVoteUpdate, MapVoteEnd, MapUpdate

**Spectator Events:**
- SpectatorEnter, SpectatorExit, SpectatorTargetUpdate, SpectatorAliveList

**Scoreboard Events:**
- ScoreboardUpdate, ShowScoreboard, HideScoreboard

### Step 9: Verify Script Import Patterns

All scripts use proper Roblox service imports. The scripts in `src/` already use correct patterns:

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- For requiring shared modules:
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

-- For requiring sibling modules in ServerScriptService:
local PlayerManager = require(script.Parent.PlayerManager)
```

No changes needed - just copy the files as-is from `src/` to Roblox Studio.

---

## Map Configuration

### Creating the Base

1. In **Workspace**, create a Part or Model named "Base"
2. Position it in the center of your map
3. Add a Script to the Base to handle damage visualization (optional)

### Setting Up Zombie Spawn Points

1. In **Workspace**, create a Folder named "ZombieSpawnPoints"
2. Add multiple Parts (or just use their Position)
3. Name them "SpawnPoint1", "SpawnPoint2", etc.
4. Position them around the perimeter of your play area
5. These mark where zombies will spawn

### Setting Up Resource Spawn Points

1. In **Workspace**, create a Folder named "ResourceSpawnPoints"
2. Add multiple Parts
3. Name them "ResourcePoint1", "ResourcePoint2", etc.
4. Position them throughout the map
5. Players will find cure components at these locations

### Recommended Map Layout

```
+-----------------------------------+
|                                   |
|  [Zombie]      [Resource]        |
|                                   |
|         [Resource]                |
|  [Zombie]         [BASE]  [Zombie]|
|                   [Resource]      |
|                                   |
|  [Resource]               [Zombie]|
|                                   |
+-----------------------------------+
```

**Tips:**
- Keep the base centrally located
- Distribute spawn points evenly around edges
- Place resources at varying distances from base
- Add cover and obstacles for tactical gameplay

---

## Testing

### Local Testing (Single Player)

1. Click **Play** button in Roblox Studio
2. Game should start automatically
3. Test basic functionality:
   - Wave spawning
   - Player health
   - Base health tracking
   - Component collection

### Multiplayer Testing

1. Click dropdown next to Play button
2. Select number of players (2-8)
3. Click **Start**
4. Test with multiple clients:
   - Alliance formation
   - Betrayal mechanics
   - Component sharing
   - Cooperative defense

### Testing Checklist

- [ ] Game starts correctly
- [ ] Players can join (up to 8)
- [ ] Lobby and map voting works
- [ ] Waves spawn zombies
- [ ] Zombies attack players and base
- [ ] Player health system works
- [ ] Base health system works
- [ ] FPS weapon system works (shooting, reloading, ADS)
- [ ] Sprint and stamina system works
- [ ] Components can be collected
- [ ] Puzzle minigames can be completed
- [ ] Cure progress updates
- [ ] Alliances can be formed/broken
- [ ] Shop purchases work
- [ ] Spectator mode works when player dies
- [ ] Scoreboard displays correctly (press TAB)
- [ ] Victory condition works (cure completed)
- [ ] Defeat conditions work (base destroyed / all dead)
- [ ] Round restarts after victory/defeat

---

## Troubleshooting

### Common Issues

#### Issue: "Script is not a ModuleScript"
**Solution:** Make sure you created ModuleScripts, not regular Scripts, for the modules.

#### Issue: "Attempt to index nil value"
**Solution:** Check your `require()` paths are correct. Use absolute paths like `game.ReplicatedStorage.Shared.GameConfig`.

#### Issue: "Player not being added"
**Solution:** Ensure PlayerManager is properly initialized before players join.

#### Issue: "Waves not starting"
**Solution:** Check that MainServer script is running and calling `gameServer:startGame()`.

#### Issue: "Components not spawning"
**Solution:** 
- Verify ResourceSpawnPoints folder exists in Workspace
- Ensure spawn points are properly positioned
- Check ResourceSpawner is initialized in GameServer

### Debug Output

Add print statements to track game flow:

```lua
-- In MainServer.lua
print("Game server initialized")

-- When wave starts
print("Wave " .. waveNumber .. " started!")

-- When player collects component
print(player.Name .. " collected " .. componentName)
```

### Console Commands

You can add admin commands for testing:

```lua
-- In MainServer.lua
game.ReplicatedStorage.AdminCommand.OnServerEvent:Connect(function(player, command)
    if command == "skipwave" then
        gameServer:startNextWave()
    elseif command == "healbase" then
        gameServer.baseManager:repairBase(1000)
    end
end)
```

---

## Configuration

To adjust game balance, edit `src/shared/GameConfig.lua`:

```lua
-- Make game easier
GameConfig.STARTING_HEALTH = 150
GameConfig.BASE_HEALTH = 1500
GameConfig.ZOMBIE_DAMAGE = 5

-- Make game harder  
GameConfig.ZOMBIE_HEALTH_MULTIPLIER = 1.5
GameConfig.ZOMBIES_PER_WAVE_MULTIPLIER = 2.0
GameConfig.WAVE_DELAY = 20
```

---

## Next Steps

After basic setup, the game is fully functional. Consider these enhancements:

1. **Customize Zombie Models**
   - Add custom R15/R6 models to ServerStorage.ZombieModels
   - Models should have: Humanoid, HumanoidRootPart, Head
   - Name them: Walker, Runner, Brute, Spitter, Boss

2. **Add Custom Maps**
   - Create map models in ServerStorage.Maps
   - Include ZombieSpawnPoints and ResourceSpawnPoints folders
   - Configure MapConfig.lua with map details

3. **Add Sound Effects**
   - Update FPSAudioController with Roblox sound asset IDs
   - Add weapon sounds, footsteps, ambient audio

4. **Visual Polish**
   - Add spawn particle effects
   - Add hit indicators and damage numbers
   - Create victory/defeat animations

5. **Balance and Tune**
   - Adjust GameConfig.lua values for difficulty
   - Playtest with multiple players
   - Fine-tune wave progression in WaveConfig.lua

---

## Publishing

When ready to publish:

1. File → Publish to Roblox
2. Choose a name and description
3. Set game icon and thumbnail
4. Configure settings:
   - Max players: 8
   - Genre: Adventure / Survival
   - Enable filtering enabled
5. Make it public or keep private for testing

---

## Support

For issues or questions:
- Check the complete documentation index: [DOCUMENTATION.md](DOCUMENTATION.md)
- Review the [API Documentation](API_DOCUMENTATION.md)
- Review the [Game Design Document](GAME_DESIGN.md)
- Visit the GitHub repository issues page

---

**Installation Guide Version**: 2.0  
**Last Updated**: 2025-12-25  
**Compatible with**: Roblox Studio (Latest)