-- @ScriptType: Script
# AwavePuzz Project Structure

This document describes the organization and conventions of the AwavePuzz repository.

## Overview

AwavePuzz is a Roblox multiplayer zombie survival game with wave-based combat, cure-crafting puzzles, and alliance systems. The codebase is organized into distinct folders for server logic, client scripts, and shared configurations.

## Directory Structure

```
AwavePuzz/
├── src/
│   ├── server/          # Server-side game logic (ServerScriptService)
│   ├── client/          # Client-side UI and controls (StarterPlayerScripts)
│   └── shared/          # Shared modules (ReplicatedStorage)
├── docs/                # Project documentation
└── [root markdown files] # High-level documentation
```

## Detailed Folder Map

### src/server/ - Server-Side Logic

Server scripts handle all game logic in a server-authoritative manner for security and multiplayer consistency.

#### Core Managers
- `MainServer.lua` - Entry point that initializes all server systems
- `GameManager.lua` - Orchestrates game states, waves, win/lose conditions
- `WaveManager.lua` - Manages wave progression and zombie counts
- `PlayerManager.lua` - Tracks player state, inventory, currency, health
- `BaseManager.lua` - Manages base health and damage tracking
- `MapManager.lua` - Handles map loading and spawn point management
- `LobbyManager.lua` - Manages pre-round lobby and map voting

#### Combat & Weapons
- `WeaponService.lua` - Server-authoritative weapon logic and raycast validation
- `FPSWeaponService.lua` - Enhanced FPS weapon features (recoil, spread, ADS)
- `Spawner.lua` - Zombie spawning logic with strategic distribution
- `IntelligentSpawnGenerator.lua` - Generates valid spawn points on maps

#### Game Systems
- `CureService.lua` - Manages cure progress and component collection
- `PuzzleService.lua` - Handles puzzle generation and validation
- `AllianceService.lua` - Manages player alliances and betrayals
- `ShopService.lua` - Weapon and upgrade purchase system
- `ResourceSpawner.lua` - Spawns cure components on the map
- `SpectatorManager.lua` - Spectator mode for eliminated players
- `SprintService.lua` - Sprint mechanics and stamina management

#### Support Scripts
- `GameServer.lua` - Alternative server entry point
- `CureCraftingManager.lua` - Legacy cure crafting logic
- `CureStationSetup.lua` - Cure station initialization

#### AI
- `AI/` - Artificial intelligence scripts
  - `ZombieBrain.lua` - Zombie AI controller with pathfinding and targeting

#### Tests (Debug Only)
- `Tests/` - Test and debug scripts (require `GameConfig.DEBUG = true`)
  - `TestPuzzleSystem.lua` - Puzzle system validation
  - `AmmoSystemFix.lua` - Ammo system debugging
  - `FixSystemAmmo.lua` - Ammo fix utilities
  - `SpawnPointVisualizer.lua` - Visual debug tool for spawn points

### src/client/ - Client-Side Scripts

Client scripts handle UI, input, and visual feedback. They communicate with the server via RemoteEvents.

#### Entry Points & Controllers
- `FPSWeaponController.client.lua` - Primary FPS weapon input controller
- `FPSMovementController.client.lua` - FPS movement with sprinting
- `FPSMenuController.client.lua` - FPS menu system
- `FPSAudioController.client.lua` - Sound effects for weapons and movement
- `FirstPersonCamera.client.lua` - Standalone first-person camera
- `WeaponController.client.lua` - Basic weapon input (fallback/simple version)
- `SprintController.client.lua` - Sprint input handling

#### Modules (Not Scripts)
These are ModuleScripts that are required by other scripts, not standalone:
- `ClientController.lua` - Client game state controller module
- `FPS/FirstPersonCamera.lua` - Modular camera implementation
- `FPS/FirstPersonController.client.lua` - Bootstrap for modular camera

#### UI Scripts
All UI scripts are LocalScripts (`.client.lua`) that run when placed in StarterGui:
- `UI/FPSHUD.client.lua` - FPS HUD with crosshair and ammo
- `UI/PlayerHUD.client.lua` - Player health and status display
- `UI/WaveUI.client.lua` - Wave information display
- `UI/BaseHealthUI.client.lua` - Base health bar
- `UI/CureUI.client.lua` - Cure progress display
- `UI/PuzzleUI.client.lua` - Puzzle interaction interface
- `UI/PuzzleMenuUI.client.lua` - Puzzle menu system
- `UI/InventoryUI.client.lua` - Component and currency display
- `UI/ShopUI.client.lua` - Shop interface
- `UI/AllianceUI.client.lua` - Alliance management UI
- `UI/MapVotingUI.client.lua` - Map voting interface
- `UI/ScoreboardUI.client.lua` - Player scoreboard
- `UI/SpectatorUI.client.lua` - Spectator mode interface

### src/shared/ - Shared Configuration

Shared ModuleScripts accessible by both server and client for configuration and utilities.

#### Configuration
- `GameConfig.lua` - Core game tuning parameters (health, waves, economy)
- `WaveConfig.lua` - Wave progression settings
- `WeaponConfig.lua` - Weapon stats and properties
- `FPSConfig.lua` - FPS system configuration
- `ZombieTypes.lua` - Zombie type definitions
- `MapConfig.lua` - Map definitions and properties
- `PuzzleConfig.lua` - Puzzle types and generation logic
- `UIScaleConfig.lua` - UI scaling settings for mobile

#### Utilities
- `RemoteEventUtil.lua` - Utility for creating/managing RemoteEvents
- `GameState.lua` - Shared game state enum/constants
- `MathUtil.lua` - Math helper functions
- `UIScaleManager.lua` - Dynamic UI scaling manager

## Naming Conventions

### File Naming
1. **LocalScripts (Client)**: Use `.client.lua` suffix
   - Example: `WeaponController.client.lua`, `FPSHUD.client.lua`
   - These execute automatically when placed in StarterGui or StarterPlayerScripts

2. **ModuleScripts**: Use `.lua` suffix only
   - Example: `GameConfig.lua`, `ZombieBrain.lua`, `ClientController.lua`
   - These are required by other scripts using `require()`

3. **Server Scripts**: Use `.lua` suffix
   - Example: `GameManager.lua`, `Spawner.lua`
   - These execute automatically when placed in ServerScriptService

### Folder Naming
- Use **PascalCase** for folders: `AI`, `Tests`, `UI`
- Use descriptive names that indicate purpose
- Group related functionality together

### RemoteEvent Naming
- Use **PascalCase** with descriptive, action-oriented names
- Include direction in documentation (Client → Server / Server → Client)
- Examples:
  - `WeaponFire` (Client → Server)
  - `WaveAnnounce` (Server → Client)
  - `RequestPuzzle` (Client → Server)
  - `PuzzleCompleted` (Server → Client)

See [REMOTE_EVENTS.md](./REMOTE_EVENTS.md) for complete list.

## What Belongs Where

### Production Code (src/server, src/client, src/shared)
- All code that runs in the actual game
- Configuration files
- Game systems and managers
- UI scripts and controllers
- AI logic

### Test/Debug Code (src/server/Tests)
- Test scripts and utilities
- Debug visualization tools
- Temporary fix scripts
- Experimental code

**IMPORTANT**: All test scripts must check `GameConfig.DEBUG` and early-exit if false.

### Documentation (docs/, root .md files)
- Architecture documentation
- API references
- Setup guides
- Design documents

## Development Guidelines

### Server Authority
- **All game logic MUST be server-authoritative**
- Never trust client for:
  - Damage calculations
  - Currency/inventory changes
  - Cure progress
  - Alliance state
  - Spawn locations
- Validate all client inputs on server

### ModuleScript vs LocalScript
- **ModuleScript**: Code that is `require()`d by other scripts
  - Returns a table/module
  - Does not execute on its own
  - Use `.lua` suffix only

- **LocalScript**: Code that executes on client
  - Runs automatically when placed in StarterGui/StarterPlayerScripts
  - Use `.client.lua` suffix

### Debug Mode
Test and debug scripts are gated behind `GameConfig.DEBUG`:

```lua
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
if not GameConfig.DEBUG then
    return -- Early exit if DEBUG is false
end
```

This prevents test code from running in production.

## RemoteEvent Communication

All client-server communication uses RemoteEvents from `ReplicatedStorage/RemoteEvents/`.

### Creating RemoteEvents
Use `RemoteEventUtil` for consistency:

```lua
local RemoteEventUtil = require(ReplicatedStorage.Shared.RemoteEventUtil)
local events = RemoteEventUtil.getOrCreateEvents({
    "EventName1",
    "EventName2"
})
```

### Documentation Requirements
Every RemoteEvent setup should include:
- Direction (Client → Server / Server → Client)
- Expected payload structure
- Purpose

Example:
```lua
-- RemoteEvent Documentation:
-- - WeaponFire: Client -> Server, player fires weapon {origin = Vector3, direction = Vector3, weaponId = string}
```

## Integration with Roblox

This repository is designed to sync with Roblox Studio:

- `src/server/` → `ServerScriptService/`
- `src/client/` → `StarterPlayer/StarterPlayerScripts/` or `StarterGui/`
- `src/shared/` → `ReplicatedStorage/Shared/`

See [INSTALLATION.md](../INSTALLATION.md) for setup instructions.

## Future Structure Improvements

Potential organizational enhancements for future development:

1. **Services Folder**: Group service modules separately from managers
2. **Systems Folder**: Dedicated folder for major game systems (Cure, Alliance, etc.)
3. **Client Controllers**: Separate folder for client-side controllers
4. **Configs Subfolder**: Move all config files into `shared/Config/`

These changes should be considered when the codebase grows significantly.

## Related Documentation

- [API_DOCUMENTATION.md](../API_DOCUMENTATION.md) - API reference
- [CODE_ARCHITECTURE.md](../CODE_ARCHITECTURE.md) - Architecture overview
- [REMOTE_EVENTS.md](./REMOTE_EVENTS.md) - RemoteEvent reference
- [INSTALLATION.md](../INSTALLATION.md) - Setup guide
- [GAME_DESIGN.md](../GAME_DESIGN.md) - Game design document
