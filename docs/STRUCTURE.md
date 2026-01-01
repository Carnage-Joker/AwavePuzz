# AwavePuzz Project Structure

**Last Updated**: 2025-12-25  
**Version**: 2.0 (Restructured)

This document describes the organization and conventions of the AwavePuzz repository after the major restructure to match Roblox Studio's directory layout.

**📖 For a complete documentation index, see [DOCUMENTATION.md](../DOCUMENTATION.md)**

## Overview

AwavePuzz is a Roblox multiplayer zombie survival game with wave-based combat, cure-crafting puzzles, and alliance systems. The repository is now structured to **exactly mirror** the Roblox Studio game hierarchy for simplified development and installation.

## Directory Structure

```
AwavePuzz/
├── ServerScriptService/         # Server-side game logic
│   ├── AI/                      # Zombie AI and controllers
│   └── *.lua                    # Server managers and services
├── ReplicatedStorage/           # Shared resources
│   ├── Shared/                  # Shared modules (configs, utils)
│   ├── RemoteEvents/            # RemoteEvent placeholders (.txt)
│   └── Animations/              # Animation placeholders (.txt)
│       └── Weapons/             # Weapon-specific animations
├── StarterPlayer/               # Player initialization
│   └── StarterPlayerScripts/    # Client-side controllers
│       ├── Modules/             # Client modules
│       │   └── UI/              # UI module scripts
│       └── FPS/                 # FPS system modules
├── StarterGui/                  # UI LocalScripts
│   └── *.lua                    # UI controllers
├── ServerStorage/               # Server-only assets
│   ├── Maps/                    # Map models (placeholders)
│   ├── Models/                  # Weapon/object models (placeholders)
│   ├── ZombieModels/            # Zombie models (placeholders)
│   └── DevOnly/                 # Developer tools
├── Archive/                     # Archived legacy code
│   └── Legacy/
│       └── Code/                # 3 levels deep for safety
│           ├── Server/          # Archived server code
│           ├── Client/          # Archived client code
│           ├── DevTools/        # Archived dev tools
│           └── Original_src_Structure/  # Original src/ backup
└── docs/                        # Project documentation
```

## Roblox Studio Mapping

This structure **directly corresponds** to Roblox Studio's service hierarchy:

| Repository Directory | Roblox Studio Location |
|---------------------|------------------------|
| `ServerScriptService/` | `game.ServerScriptService` |
| `ReplicatedStorage/Shared/` | `game.ReplicatedStorage.Shared` |
| `ReplicatedStorage/RemoteEvents/` | `game.ReplicatedStorage.RemoteEvents` |
| `ReplicatedStorage/Animations/` | `game.ReplicatedStorage.Animations` |
| `StarterPlayer/StarterPlayerScripts/` | `game.StarterPlayer.StarterPlayerScripts` |
| `StarterGui/` | `game.StarterGui` |
| `ServerStorage/Maps/` | `game.ServerStorage.Maps` |
| `ServerStorage/Models/` | `game.ServerStorage.Models` |
| `ServerStorage/ZombieModels/` | `game.ServerStorage.ZombieModels` |

---

## ServerScriptService/

**Purpose**: Server-side game logic running on the Roblox server  
**Script Type**: Scripts (run automatically) and ModuleScripts (require()d)  
**File Count**: 27 Lua files

### Main Entry Point

- **`MainServer.lua`** (Script) - Main entry point that initializes all server systems

### Core Managers

- **`GameManager.lua`** - Orchestrates game states, waves, win/lose conditions
- **`WaveManager.lua`** - Manages wave progression and zombie counts
- **`PlayerManager.lua`** - Tracks player state, inventory, currency, health
- **`BaseManager.lua`** - Manages base health and damage tracking
- **`MapManager.lua`** - Handles map loading and spawn point management
- **`LobbyManager.lua`** - Manages pre-round lobby and map voting

### Combat & Weapons

- **`WeaponService.lua`** - Server-authoritative weapon logic and raycast validation
- **`FPSWeaponService.lua`** - Enhanced FPS weapon features (ammo, reload, ADS)
- **`FPSAnimationService.lua`** - Animation replication for FPS system
- **`Spawner.lua`** - Zombie spawning logic with strategic distribution
- **`IntelligentSpawnGenerator.lua`** - Generates valid spawn points on maps

### Game Systems

- **`CureService.lua`** - Manages cure progress and component collection
- **`CureStationSetup.lua`** - Cure station initialization (moved to Shared)
- **`PuzzleService.lua`** - Handles puzzle generation and validation
- **`AllianceService.lua`** - Manages player alliances and betrayals
- **`ShopService.lua`** - Weapon and upgrade purchase system
- **`ResourceSpawner.lua`** - Spawns cure components on the map
- **`SpectatorManager.lua`** - Spectator mode for eliminated players
- **`SprintService.lua`** - Sprint mechanics and stamina management
- **`AchievementService.lua`** - Achievement tracking and unlocking

### AI Subfolder (`AI/`)

**Purpose**: Artificial intelligence for zombies and NPCs  
**File Count**: 6 Lua files

- **`ZombieBrain.lua`** - Main zombie AI controller with pathfinding and targeting
- **`AIDirector.lua`** - Manages overall AI behavior and difficulty
- **`TargetingService.lua`** - Target selection logic for zombies
- **`SurroundService.lua`** - Zombie surround behavior
- **`SpitterController.lua`** - Special behavior for Spitter zombie type
- **`BossAuraService.lua`** - Boss zombie aura effects

---

## ReplicatedStorage/

**Purpose**: Resources shared between server and client  
**Script Type**: ModuleScripts, RemoteEvents, Animations

### Shared/ Subfolder

**Purpose**: Configuration and utility modules accessible by both server and client  
**File Count**: 13 Lua files

#### Configuration Modules

- **`GameConfig.lua`** - Core game tuning parameters (health, waves, economy)
- **`WaveConfig.lua`** - Wave progression settings
- **`WeaponConfig.lua`** - Weapon stats and properties
- **`FPSConfig.lua`** - FPS system configuration
- **`ZombieTypes.lua`** - Zombie type definitions
- **`MapConfig.lua`** - Map definitions and properties
- **`PuzzleConfig.lua`** - Puzzle types and generation logic
- **`UIScaleConfig.lua`** - UI scaling settings for mobile
- **`StoryConfig.lua`** - Story and narrative configuration

#### Utility Modules

- **`RemoteEventUtil.lua`** - Utility for creating/managing RemoteEvents
- **`GameState.lua`** - Shared game state enum/constants
- **`MathUtil.lua`** - Math helper functions
- **`UIScaleManager.lua`** - Dynamic UI scaling manager

### RemoteEvents/ Subfolder

**Purpose**: Client-server communication events  
**File Count**: 58 placeholder .txt files

Placeholder `.txt` files representing RemoteEvents that will be created at runtime. In Roblox Studio, replace with actual `RemoteEvent` instances.

**Categories**:
- Game State Events (5)
- Player Events (4)
- Weapon Events (5)
- Animation Events (6)
- Movement Events (2)
- Shop Events (2)
- Alliance Events (4)
- Puzzle/Cure Events (8)
- Lobby/Map Events (6)
- Spectator Events (5)
- UI Events (9)
- Achievement Events (1)

See [ASSET_PLACEHOLDERS.md](../ASSET_PLACEHOLDERS.md) for complete list and details.

### Animations/ Subfolder

**Purpose**: Animation assets for weapons and characters  
**File Count**: 36 placeholder .txt files

Structure:
```
Animations/
└── Weapons/
    ├── Pistol/
    ├── SMG/
    ├── Shotgun/
    ├── Rifle/
    └── AssaultRifle/
        ├── Idle.txt
        ├── Fire.txt
        ├── Reload.txt
        ├── Equip.txt
        ├── Sprint.txt
        └── ADS.txt
```

Each weapon requires 6 animations. See [ASSET_PLACEHOLDERS.md](../ASSET_PLACEHOLDERS.md) for specifications.

---

## StarterPlayer/StarterPlayerScripts/

**Purpose**: Client-side scripts that run when player joins  
**Script Type**: LocalScripts (run automatically) and ModuleScripts (require()d)  
**File Count**: 27 Lua files

### Root Controllers

- **`ClientController.client.lua`** (LocalScript) - Main client controller
- **`ClientController.lua`** (ModuleScript) - Client game state module

### FPS Subfolder (`FPS/`)

**Purpose**: First-person camera and control system

- **`FirstPersonCamera.lua`** (ModuleScript) - Modular camera implementation
- Plus archived implementations in `FPS/Archived/`

### Modules Subfolder (`Modules/`)

**Purpose**: Client-side modules for various systems

#### Core Modules

- **`FPSAnimationController.lua`** - Animation playback and replication
- **`FPSAudioController.lua`** - Sound effects for weapons and movement
- **`FPSMenuController.lua`** - Pause menu and settings
- **`FPSMovement.lua`** - Movement mechanics (sprint, crouch)
- **`FPSWeaponController.lua`** - Weapon input and firing
- **`FirstPersonCamera.lua`** - Camera controller module
- **`MusicController.lua`** - Dynamic music system

#### UI Subfolder (`Modules/UI/`)

**File Count**: 17 UI module files

These are **ModuleScripts** used by LocalScripts in StarterGui:

- **`AchievementUI.lua`** - Achievement notification system
- **`AllianceUI.lua`** - Alliance management interface
- **`BaseHealthUI.lua`** - Base health bar display
- **`CreditsUI.lua`** - Victory credits screen
- **`CureUI.lua`** - Cure progress display
- **`EpilogueUI.lua`** - Story epilogue interface
- **`FPSHUD.lua`** - Crosshair, ammo, hitmarkers
- **`InventoryUI.lua`** - Player inventory display
- **`MapVotingUI.lua`** - Map voting interface
- **`PlayerHUD.lua`** - Player health and status
- **`PuzzleMenuUI.lua`** - Puzzle selection menu
- **`PuzzleUI.lua`** - Puzzle minigame interface
- **`ScoreboardUI.lua`** - Player scoreboard
- **`ShopUI.lua`** - In-game shop interface
- **`SpectatorUI.lua`** - Spectator mode controls
- **`TitleScreenUI.lua`** - Title screen interface
- **`WaveUI.lua`** - Wave information display

---

## StarterGui/

**Purpose**: UI LocalScripts that create and manage user interfaces  
**Script Type**: LocalScripts (converted from ModuleScripts)  
**File Count**: 17 Lua files

All files are copies of `StarterPlayerScripts/Modules/UI/` for direct use as LocalScripts in StarterGui:

- `AchievementUI.lua`
- `AllianceUI.lua`
- `BaseHealthUI.lua`
- `CreditsUI.lua`
- `CureUI.lua`
- `EpilogueUI.lua`
- `FPSHUD.lua`
- `InventoryUI.lua`
- `MapVotingUI.lua`
- `PlayerHUD.lua`
- `PuzzleMenuUI.lua`
- `PuzzleUI.lua`
- `ScoreboardUI.lua`
- `ShopUI.lua`
- `SpectatorUI.lua`
- `TitleScreenUI.lua`
- `WaveUI.lua`

**Note**: In Roblox Studio, these should be LocalScript instances, not ModuleScripts.

---

## ServerStorage/

**Purpose**: Server-only assets not replicated to clients  
**File Count**: 15 placeholder files (+ 4 in DevOnly)

### Maps/ Subfolder

**Purpose**: Map models with spawn points  
**Placeholders**: 3 maps

- `ResearchFacility_PLACEHOLDER.txt`
- `DesertOutpost_PLACEHOLDER.txt`
- `UrbanRuins_PLACEHOLDER.txt`

Each map should be a Model containing:
- `ZombieSpawnPoints` folder
- `ResourceSpawnPoints` folder
- Terrain and structures

### Models/ Subfolder

**Purpose**: Weapon, object, and environment models  
**Placeholders**: 7 models

Weapon Models (5):
- `Pistol_PLACEHOLDER.txt`
- `SMG_PLACEHOLDER.txt`
- `Shotgun_PLACEHOLDER.txt`
- `Rifle_PLACEHOLDER.txt`
- `AssaultRifle_PLACEHOLDER.txt`

Other Models (2):
- `CureStation_PLACEHOLDER.txt`
- `ResourcePickup_PLACEHOLDER.txt`

### ZombieModels/ Subfolder

**Purpose**: Zombie character models  
**Placeholders**: 5 zombie types

- `Walker_PLACEHOLDER.txt` - Basic zombie
- `Runner_PLACEHOLDER.txt` - Fast zombie
- `Brute_PLACEHOLDER.txt` - Tank zombie
- `Spitter_PLACEHOLDER.txt` - Ranged zombie
- `Boss_PLACEHOLDER.txt` - Boss zombie

Each should be R15/R6 rig with Humanoid and HumanoidRootPart.

### DevOnly/ Subfolder

**Purpose**: Development and debug tools  
**File Count**: 4 Lua files (retained for development)

- `SpawnPointVisualizer.lua` - Visual debug for spawn points
- `TestPuzzleSystem.lua` - Puzzle system testing
- `FixSystemAmmo.lua` - Ammo system debugging
- `AmmoSystemFix.lua` - Ammo fix utilities

**Note**: These tools only run when `GameConfig.DEBUG = true`.

---

## Archive/

**Purpose**: Legacy and archived code isolated from production  
**Structure**: 3 levels deep for safety (`Archive/Legacy/Code/`)

### Archive/Legacy/Code/

#### Server/
Archived server-side code:
- `CureCraftingManager.lua` - Legacy cure crafting
- `GameServer.lua` - Old game server implementation

#### Client/
Archived client-side code:
- 11 disabled `.client.lua.disabled` files
- Old controller implementations
- Deprecated UI scripts

#### DevTools/
Archived development tools moved from `ServerStorage/DevOnly/`:
- Spawn point visualizers
- Puzzle tests
- System fixes

#### Original_src_Structure/
Complete backup of original `src/` directory structure before restructure.

**Safety**: Placing archived code 3 levels deep prevents accidental use in production.

---

## Naming Conventions

### File Naming

1. **LocalScripts (Client)**: Use `.client.lua` suffix (deprecated in new structure)
   - Example: `WeaponController.client.lua`
   - In StarterGui, these are just `.lua` as LocalScript instances

2. **ModuleScripts**: Use `.lua` suffix only
   - Example: `GameConfig.lua`, `ZombieBrain.lua`
   - Required by other scripts using `require()`

3. **Server Scripts**: Use `.lua` suffix
   - Example: `GameManager.lua`, `Spawner.lua`
   - Only `MainServer.lua` is a Script, others are ModuleScripts

### Directory Naming

- Use **PascalCase** for folders: `AI`, `Modules`, `UI`
- Match Roblox service names exactly: `ServerScriptService`, `ReplicatedStorage`
- Use descriptive names: `StarterPlayerScripts`, `ZombieModels`

### RemoteEvent Naming

- Use **PascalCase**: `WeaponFire`, `AllianceUpdate`
- Descriptive action-oriented names
- Direction suffix (optional):
  - `Request` - Client → Server
  - `Update` - Server → Client

See [REMOTE_EVENTS.md](../REMOTE_EVENTS.md) for complete list.

---

## Development Guidelines

### Server Authority

**All game logic MUST be server-authoritative**

Never trust client for:
- ❌ Damage calculations
- ❌ Currency/inventory changes
- ❌ Cure progress
- ❌ Alliance state
- ❌ Spawn locations

Always validate client inputs on server.

### Script Types in Roblox

**Script** (Server):
- Runs automatically in ServerScriptService
- Server-side execution only
- Example: `MainServer.lua`

**LocalScript** (Client):
- Runs automatically in StarterGui/StarterPlayerScripts
- Client-side execution only
- Example: UI scripts in StarterGui

**ModuleScript** (Both):
- Does not run automatically
- Must be `require()`d by other scripts
- Can run on server or client depending on where it's required
- Example: Config files, utility modules

### Require Paths

```lua
-- Server requiring shared config
local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)

-- Server requiring sibling module
local PlayerManager = require(script.Parent.PlayerManager)

-- Client requiring shared config
local FPSConfig = require(game.ReplicatedStorage.Shared.FPSConfig)

-- Client requiring module
local FPSHUD = require(script.Parent.Modules.UI.FPSHUD)
```

---

## Integration with Roblox Studio

This repository structure allows **direct copying** to Roblox Studio:

1. Copy entire `ServerScriptService/` → ServerScriptService in Studio
2. Copy entire `ReplicatedStorage/` → ReplicatedStorage in Studio
3. Copy `StarterPlayer/StarterPlayerScripts/` → StarterPlayer.StarterPlayerScripts in Studio
4. Copy `StarterGui/` scripts → StarterGui in Studio (as LocalScript instances)
5. Copy `ServerStorage/` → ServerStorage in Studio

See [INSTALLATION.md](../INSTALLATION.md) for detailed setup instructions.

---

## File Count Summary

| Location | Active Lua Files | Placeholder Files |
|----------|------------------|-------------------|
| ServerScriptService | 27 | - |
| ReplicatedStorage/Shared | 13 | - |
| StarterPlayer/StarterPlayerScripts | 27 | - |
| StarterGui | 17 | - |
| ServerStorage/DevOnly | 4 | - |
| ReplicatedStorage/RemoteEvents | - | 58 |
| ReplicatedStorage/Animations | - | 36 |
| ServerStorage (Models/Maps) | - | 15 |
| **Total** | **88** | **109** |

---

## Related Documentation

- [DOCUMENTATION.md](../DOCUMENTATION.md) - Complete documentation index
- [ASSET_PLACEHOLDERS.md](../ASSET_PLACEHOLDERS.md) - Asset requirements and specifications
- [INSTALLATION.md](../INSTALLATION.md) - Complete setup guide
- [REMOTE_EVENTS.md](REMOTE_EVENTS.md) - RemoteEvent reference
- [API_DOCUMENTATION.md](../API_DOCUMENTATION.md) - API reference
- [CODE_ARCHITECTURE.md](../CODE_ARCHITECTURE.md) - Architecture overview

---

## Migration from Old Structure

If migrating from the old `src/` structure:

| Old Path | New Path |
|----------|----------|
| `src/server/*.lua` | `ServerScriptService/*.lua` |
| `src/server/AI/*.lua` | `ServerScriptService/AI/*.lua` |
| `src/shared/*.lua` | `ReplicatedStorage/Shared/*.lua` |
| `src/client/*.lua` | `StarterPlayer/StarterPlayerScripts/*.lua` |
| `src/client/Modules/*.lua` | `StarterPlayer/StarterPlayerScripts/Modules/*.lua` |
| `src/client/Modules/UI/*.lua` | `StarterGui/*.lua` |
| `src/*/Archived/*` | `Archive/Legacy/Code/*/` |

**No code changes required** - internal require paths remain unchanged.

---

## Questions?

For questions about the structure:
1. Check [DOCUMENTATION.md](../DOCUMENTATION.md) for comprehensive documentation index
2. Review placeholder README files in each directory
3. Open an issue on GitHub with the "structure" label
