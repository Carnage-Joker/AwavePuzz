# API Documentation - AwavePuzz

This document describes the API for each module in the AwavePuzz game system.

## Table of Contents
- [GameConfig](#gameconfig)
- [WeaponConfig](#weaponconfig)
- [GameState](#gamestate)
- [GameServer](#gameserver)
- [PlayerManager](#playermanager)
- [WaveManager](#wavemanager)
- [BaseManager](#basemanager)
- [CureCraftingManager](#curecraftingmanager)
- [ResourceSpawner](#resourcespawner)
- [WeaponService](#weaponservice)
- [ShopService](#shopservice)
- [MapManager](#mapmanager)
- [ClientController](#clientcontroller)

---

## GameConfig

**Location**: `src/shared/GameConfig.lua`  
**Type**: Configuration Module  
**Description**: Contains all game configuration constants and tunable parameters.

### Constants

#### Player Settings
```lua
MAX_PLAYERS = 8                -- Maximum players per server
STARTING_HEALTH = 100          -- Player starting health
RESPAWN_ENABLED = false        -- Whether respawning is allowed
```

#### Base Settings
```lua
BASE_HEALTH = 1000            -- Base starting health
BASE_REGEN_RATE = 0           -- Health regeneration per second
```

#### Wave Settings
```lua
STARTING_WAVE = 1                     -- First wave number
WAVE_DELAY = 30                       -- Seconds between waves
ZOMBIES_PER_WAVE_MULTIPLIER = 1.5     -- Growth rate per wave
BASE_ZOMBIES_PER_WAVE = 5             -- Initial zombie count
```

#### Zombie Settings
```lua
ZOMBIE_HEALTH = 50                    -- Base zombie health
ZOMBIE_DAMAGE = 10                    -- Damage per attack
ZOMBIE_SPEED = 16                     -- Movement speed (studs/sec)
ZOMBIE_HEALTH_MULTIPLIER = 1.2        -- Health growth per wave
```

#### Cure Settings
```lua
CURE_COMPONENTS_REQUIRED = 5          -- Pieces needed per component
CURE_COMPONENT_NAMES = {              -- Available components
    "Chemical A",
    "Chemical B",
    "Biological Sample",
    "Research Notes",
    "Catalyst"
}
```

---

## WeaponConfig

**Location**: `src/shared/WeaponConfig.lua`
**Type**: Configuration Module
**Description**: Central catalog for every weapon, upgrade, and shop entry.

### Tables

```lua
WeaponConfig.DefaultWeapon -- Starting weapon id
WeaponConfig.Weapons -- Stats per weapon (Damage, FireRate, Range, RewardBonus, etc.)
WeaponConfig.Upgrades -- Upgrade definitions with affected stat + multiplier
WeaponConfig.ShopItems -- Ordered array used by the shop/camp vendor UI
```

### Helper Functions

```lua
WeaponConfig.getWeapon(weaponId) -> table
WeaponConfig.getUpgrade(upgradeId) -> table
WeaponConfig.getCatalog() -> {items}
```

---

## GameState

**Location**: `src/shared/GameState.lua`  
**Type**: Class  
**Description**: Manages overall game state and progression.

### Constructor

```lua
GameState.new() -> GameState
```
Creates a new GameState instance.

### Properties

```lua
.States = {
    WAITING = "Waiting",
    IN_PROGRESS = "InProgress",
    VICTORY = "Victory",
    DEFEAT = "Defeat"
}
```

### Methods

#### setState
```lua
GameState:setState(newState: string) -> void
```
Updates the current game state.

**Parameters:**
- `newState` (string): One of GameState.States values

#### getState
```lua
GameState:getState() -> string
```
Returns the current game state.

#### incrementWave
```lua
GameState:incrementWave() -> void
```
Increments the current wave counter.

#### setBaseHealth
```lua
GameState:setBaseHealth(health: number) -> void
```
Updates the base health value.

**Parameters:**
- `health` (number): New health value (clamped to >= 0)

#### updateCureProgress
```lua
GameState:updateCureProgress(progress: number) -> void
```
Updates the cure crafting progress.

**Parameters:**
- `progress` (number): Progress percentage (clamped to 0-100)

#### isGameOver
```lua
GameState:isGameOver() -> boolean
```
Returns whether the game has ended (victory or defeat).

---

## GameServer

**Location**: `src/server/GameServer.lua`  
**Type**: Class  
**Description**: Main server-side game controller coordinating all subsystems.

### Constructor

```lua
GameServer.new() -> GameServer
```
Creates a new GameServer instance with all subsystems initialized.

### Methods

#### startGame
```lua
GameServer:startGame() -> (boolean, string)
```
Starts the game session.

**Returns:**
- `success` (boolean): Whether game started successfully
- `message` (string): Success or error message

#### startNextWave
```lua
GameServer:startNextWave() -> table
```
Initiates the next zombie wave.

**Returns:**
- Wave info table with `waveNumber`, `zombieCount`, `zombieHealth`

#### onPlayerJoin
```lua
GameServer:onPlayerJoin(player: Player) -> (boolean, string)
```
Handles player joining the game.

**Parameters:**
- `player` (Player): Roblox Player instance

**Returns:**
- `success` (boolean): Whether player was added
- `message` (string): Success or error message

#### onPlayerLeave
```lua
GameServer:onPlayerLeave(player: Player) -> void
```
Handles player leaving the game.

#### damagePlayer
```lua
GameServer:damagePlayer(player: Player, damage: number) -> boolean
```
Applies damage to a player.

**Returns:**
- `died` (boolean): Whether player died from this damage

#### damageBase
```lua
GameServer:damageBase(damage: number) -> boolean
```
Applies damage to the base.

**Returns:**
- `destroyed` (boolean): Whether base was destroyed

#### collectCureComponent
```lua
GameServer:collectCureComponent(player: Player, componentName: string) -> (boolean, string)
```
Handles player collecting a cure component.

**Returns:**
- `success` (boolean): Whether collection succeeded
- `message` (string): Result message

#### createAlliance
```lua
GameServer:createAlliance(player1: Player, player2: Player) -> boolean
```
Forms an alliance between two players.

#### breakAlliance
```lua
GameServer:breakAlliance(player1: Player, player2: Player) -> boolean
```
Breaks an alliance between two players.

#### onZombieKilled
```lua
GameServer:onZombieKilled() -> void
```
Handles zombie death, checks for wave completion.

#### update
```lua
GameServer:update(deltaTime: number) -> void
```
Main game loop update function.

**Parameters:**
- `deltaTime` (number): Time since last update in seconds

#### getGameState
```lua
GameServer:getGameState() -> table
```
Returns current game state data for clients.

**Returns:**
```lua
{
    state: string,
    wave: number,
    baseHealth: number,
    baseHealthPercent: number,
    cureProgress: number,
    zombiesRemaining: number,
    playersAlive: number
}
```

---

## PlayerManager

**Location**: `src/server/PlayerManager.lua`  
**Type**: Class  
**Description**: Manages player data, health, and alliances.

### Constructor

```lua
PlayerManager.new() -> PlayerManager
```

### Methods

#### addPlayer
```lua
PlayerManager:addPlayer(player: Player) -> (boolean, string)
```
Adds a player to the game.

**Returns:**
- `success` (boolean): Whether player was added
- `message` (string): Result message

#### removePlayer
```lua
PlayerManager:removePlayer(player: Player) -> void
```
Removes a player from the game.

#### getPlayerData
```lua
PlayerManager:getPlayerData(player: Player) -> table|nil
```
Gets player data object.

**Returns:**
```lua
{
    player: Player,
    health: number,
    isAlive: boolean,
    cureComponents: table,
    lastBetrayalTime: number
}
```

#### damagePlayer
```lua
PlayerManager:damagePlayer(player: Player, damage: number) -> boolean
```
Applies damage to player.

**Returns:**
- `died` (boolean): Whether player died

#### healPlayer
```lua
PlayerManager:healPlayer(player: Player, amount: number) -> boolean
```
Heals a player.

#### getActivePlayers
```lua
PlayerManager:getActivePlayers() -> table
```
Returns array of alive players.

#### getAllPlayers
```lua
PlayerManager:getAllPlayers() -> table
```
Returns array of all players (alive or dead).

#### addAlliance
```lua
PlayerManager:addAlliance(player1: Player, player2: Player) -> boolean
```
Creates alliance between two players.

#### removeAlliance
```lua
PlayerManager:removeAlliance(player1: Player, player2: Player) -> boolean
```
Removes alliance between two players.

#### areAllied
```lua
PlayerManager:areAllied(player1: Player, player2: Player) -> boolean
```
Checks if two players are allied.

#### addCureComponent
```lua
PlayerManager:addCureComponent(player: Player, componentName: string) -> boolean
```
Adds a cure component to player's inventory.

#### getCureComponents
```lua
PlayerManager:getCureComponents(player: Player) -> table
```
Returns player's collected components.

---

## WaveManager

**Location**: `src/server/WaveManager.lua`  
**Type**: Class  
**Description**: Manages zombie wave spawning and progression.

### Constructor

```lua
WaveManager.new() -> WaveManager
```

### Methods

#### calculateZombiesForWave
```lua
WaveManager:calculateZombiesForWave(waveNumber: number) -> number
```
Calculates number of zombies for a given wave.

#### calculateZombieHealthForWave
```lua
WaveManager:calculateZombieHealthForWave(waveNumber: number) -> number
```
Calculates zombie health for a given wave.

#### startWave
```lua
WaveManager:startWave() -> table
```
Starts the next wave.

**Returns:**
```lua
{
    waveNumber: number,
    zombieCount: number,
    zombieHealth: number
}
```

#### spawnZombie
```lua
WaveManager:spawnZombie() -> table|nil
```
Spawns a single zombie.

**Returns:**
```lua
{
    health: number,
    damage: number,
    speed: number,
    id: string
}
```
Or `nil` if max zombies reached.

#### onZombieDeath
```lua
WaveManager:onZombieDeath() -> boolean
```
Called when a zombie dies.

**Returns:**
- `waveComplete` (boolean): Whether wave is finished

#### isWaveActive
```lua
WaveManager:isWaveActive() -> boolean
```
Returns whether a wave is currently active.

#### getCurrentWave
```lua
WaveManager:getCurrentWave() -> number
```
Returns current wave number.

#### getZombiesRemaining
```lua
WaveManager:getZombiesRemaining() -> number
```
Returns count of living zombies.

---

## BaseManager

**Location**: `src/server/BaseManager.lua`  
**Type**: Class  
**Description**: Manages base health and status.

### Constructor

```lua
BaseManager.new() -> BaseManager
```

### Methods

#### damageBase
```lua
BaseManager:damageBase(damage: number) -> boolean
```
Applies damage to base.

**Returns:**
- `destroyed` (boolean): Whether base was destroyed

#### repairBase
```lua
BaseManager:repairBase(amount: number) -> boolean
```
Repairs the base.

**Returns:**
- `success` (boolean): Whether repair succeeded

#### getHealth
```lua
BaseManager:getHealth() -> number
```
Returns current base health.

#### getHealthPercentage
```lua
BaseManager:getHealthPercentage() -> number
```
Returns base health as percentage (0-100).

#### isBaseDestroyed
```lua
BaseManager:isBaseDestroyed() -> boolean
```
Returns whether base is destroyed.

#### reset
```lua
BaseManager:reset() -> void
```
Resets base to full health.

---

## CureCraftingManager

**Location**: `src/server/CureCraftingManager.lua`  
**Type**: Class  
**Description**: Manages the cure puzzle system.

### Constructor

```lua
CureCraftingManager.new() -> CureCraftingManager
```

### Methods

#### addComponent
```lua
CureCraftingManager:addComponent(componentName: string) -> (boolean, string)
```
Adds a component to the cure.

**Returns:**
- `success` (boolean): Whether component was added
- `message` (string): Result message

#### getComponentCount
```lua
CureCraftingManager:getComponentCount(componentName: string) -> number
```
Returns count of a specific component.

#### getAllComponents
```lua
CureCraftingManager:getAllComponents() -> table
```
Returns all component counts.

#### getCureProgress
```lua
CureCraftingManager:getCureProgress() -> number
```
Returns cure progress percentage (0-100).

#### isCureCrafted
```lua
CureCraftingManager:isCureCrafted() -> boolean
```
Returns whether cure is complete.

#### getRemainingComponents
```lua
CureCraftingManager:getRemainingComponents() -> table
```
Returns components still needed.

#### checkCureComplete
```lua
CureCraftingManager:checkCureComplete() -> boolean
```
Checks if all components are collected.

#### reset
```lua
CureCraftingManager:reset() -> void
```
Resets cure progress.

---

## ResourceSpawner

**Location**: `src/server/ResourceSpawner.lua`  
**Type**: Class  
**Description**: Spawns physical resource pickups, awards inventory items on touch, and enforces the max resource limit per map.

### Constructor

```lua
ResourceSpawner.new(playerManager) -> ResourceSpawner
```

### Methods

#### addSpawnPoint
```lua
ResourceSpawner:addSpawnPoint(position: Vector3) -> void
```
Adds a resource spawn location.

#### getRandomComponent
```lua
ResourceSpawner:getRandomComponent() -> string
```
Returns a random component name.

#### spawnResource
```lua
ResourceSpawner:spawnResource() -> Instance|nil
```
Creates a glowing part at a random spawn point with the assigned component label.

#### collectResource
```lua
ResourceSpawner:collectResource(resourceId: string) -> string|nil
```
Collects a resource entry manually (used as fallback cleanup).

#### update
```lua
ResourceSpawner:update(deltaTime: number) -> nil
```
Updates timers and spawns resources periodically.

#### getActiveResourceCount
```lua
ResourceSpawner:getActiveResourceCount() -> number
```
Returns count of active resources on map.

---

## WeaponService

**Location**: `src/server/WeaponService.lua`
**Type**: Class
**Description**: Validates player shots, performs server-side raycasts, applies zombie damage, and rewards currency.

### Constructor

```lua
WeaponService.new(playerManager) -> WeaponService
```

### Methods

- `initializePlayer(player)` – Seeds default weapon loadout for a player.
- `handleWeaponFire(player, payload)` – Validates fire-rate and direction, raycasts, and damages zombies.
- `onZombieKilled(zombieModel)` – Grants the appropriate reward to the killer.
- `applyUpgrade(player, upgradeId)` – Persists stat upgrades that modify weapon data per player.

---

## ShopService

**Location**: `src/server/ShopService.lua`
**Type**: Class
**Description**: Owns the Camp Vendor logic, delivering catalog data and validating purchases via RemoteEvents.

### Methods

- `ShopService.new(playerManager, weaponService)` – Creates the service and binds `ShopRequest`/`ShopUpdate`.
- `sendCatalog(player)` – Fires current shop items to a client.
- `attemptPurchase(player, itemId)` – Deducts currency, unlocks weapons, or applies upgrades.

---

## MapManager

**Location**: `src/server/MapManager.lua`
**Type**: Class
**Description**: Handles cloning of map models from `ServerStorage.Maps` and exposes spawn points to other systems.

### Methods

- `MapManager.new()` – Initializes the manager and reads fallback spawn folders.
- `load(mapId)` / `loadDefault()` – Selects a map and extracts spawn points.
- `getZombieSpawnPoints()` – Returns table of zombie spawn `Vector3`s.
- `getResourceSpawnPoints()` – Returns table of resource spawn `Vector3`s.
- `getCurrentMapId()` – Returns the active map identifier for UI announcements.

---

## ClientController

**Location**: `src/client/ClientController.lua`  
**Type**: Class  
**Description**: Client-side game controller for UI and input.

### Constructor

```lua
ClientController.new() -> ClientController
```

### Methods

#### updateGameState
```lua
ClientController:updateGameState(stateData: table) -> void
```
Updates local game state from server.

#### updatePlayerHealth
```lua
ClientController:updatePlayerHealth(health: number) -> void
```
Updates player health display.

#### displayWaveStart
```lua
ClientController:displayWaveStart(waveNumber: number) -> void
```
Shows wave start notification.

#### displayCureProgress
```lua
ClientController:displayCureProgress(progress: number) -> void
```
Updates cure progress display.

#### displayAlliance
```lua
ClientController:displayAlliance(playerName: string, allied: boolean) -> void
```
Shows alliance formed/broken notification.

#### displayVictory
```lua
ClientController:displayVictory() -> void
```
Shows victory screen.

#### displayDefeat
```lua
ClientController:displayDefeat(reason: string) -> void
```
Shows defeat screen.

#### requestAlliance
```lua
ClientController:requestAlliance(targetPlayer: Player) -> void
```
Sends alliance request to server.

#### betrayAlliance
```lua
ClientController:betrayAlliance(targetPlayer: Player) -> void
```
Sends betrayal request to server.

#### collectComponent
```lua
ClientController:collectComponent(componentName: string) -> void
```
Sends component collection to server.

#### getGameState
```lua
ClientController:getGameState() -> table
```
Returns current client game state.

---

## Usage Examples

### Server Setup

```lua
-- Initialize game server
local GameServer = require(game.ServerScriptService.GameServer)
local gameServer = GameServer.new()

-- Start game when players ready
local success, message = gameServer:startGame()

-- Main game loop
game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
    gameServer:update(deltaTime)
end)

-- Handle player joining
game.Players.PlayerAdded:Connect(function(player)
    gameServer:onPlayerJoin(player)
end)

-- Handle zombie killed
-- (called from zombie script)
gameServer:onZombieKilled()
```

### Client Setup

```lua
-- Initialize client controller
local ClientController = require(game.ReplicatedStorage.ClientController)
local clientController = ClientController.new()

-- Update from server
remoteEvent.OnClientEvent:Connect(function(stateData)
    clientController:updateGameState(stateData)
end)

-- Request alliance
clientController:requestAlliance(targetPlayer)
```

---

**Document Version**: 1.0  
**Last Updated**: 2025-11-15