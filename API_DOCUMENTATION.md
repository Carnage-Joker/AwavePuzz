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
- [Spawner](#spawner)
- [ResourceSpawner](#resourcespawner)
- [CureService](#cureservice)
- [AllianceService](#allianceservice)
- [WeaponService](#weaponservice)
- [ShopService](#shopservice)
- [ZombieBrain](#zombiebrain)
- [MapManager](#mapmanager)
- [LobbyManager](#lobbymanager)
- [SpectatorManager](#spectatormanager)
- [ClientController](#clientcontroller)
- [FPSAnimationController](#fpsanimationcontroller)

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

#### Sprint Settings
```lua
SPRINT_SPEED_MULTIPLIER = 1.5  -- How much faster sprinting is compared to walking
STAMINA_MAX = 100              -- Maximum stamina
STAMINA_DEPLETION_RATE = 20    -- Stamina lost per second while sprinting
STAMINA_REGEN_RATE = 15        -- Stamina gained per second while not sprinting
STAMINA_REGEN_DELAY = 1.0      -- Seconds to wait after stopping sprint before regen starts
SPRINT_HOTKEY = "LeftShift"    -- Key to hold for sprinting
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
ZOMBIE_ATTACK_RANGE = 6               -- Attack range in studs
ZOMBIE_ATTACK_INTERVAL = 1.5          -- Seconds between attacks
ZOMBIE_REPATH_INTERVAL = 0.4          -- Path recalculation frequency (reduced from 1.0 to prevent pausing)
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

#### Lobby & Round Settings
```lua
LOBBY_VOTING_TIME = 20        -- Seconds for map voting
LOBBY_MIN_PLAYERS = 1         -- Minimum players to start voting
SCOREBOARD_DISPLAY_TIME = 10  -- Seconds to show scoreboard after round
ROUND_COUNTDOWN_TIME = 5      -- Countdown before round starts after voting
ONE_LIFE_PER_ROUND = true     -- Players only have one life per round
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

**Location**: `ServerScriptService/BaseManager.lua`  
**Type**: Server Module (Singleton)  
**Description**: Manages base health and status with security logging.

### Constructor

```lua
BaseManager.new() -> BaseManager
```

### Methods

#### damageBase
```lua
BaseManager:damageBase(damage: number, source: string?) -> boolean
```
**✅ UPDATED (2026-02-02)**: Now accepts optional source parameter for audit logging

Applies damage to base with source tracking.

**Parameters:**
- `damage` (number): Amount of damage to apply
- `source` (string, optional): Source identifier (e.g., zombie name, "Player")

**Returns:**
- `destroyed` (boolean): Whether base was destroyed

**Security:**
- Logs all damage events with source for auditing
- Server-authoritative validation

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

## Spawner

**Location**: `src/server/Spawner.lua`  
**Type**: Class  
**Description**: Manages zombie spawning, AI initialization, and zombie lifecycle. Integrates with BaseManager and PlayerManager for zombie attacks.

### Constructor

```lua
Spawner.new(weaponService, baseManager, playerManager) -> Spawner
```

Creates a new Spawner instance.

**Parameters:**
- `weaponService` (WeaponService): For handling zombie kills and rewards
- `baseManager` (BaseManager): Passed to zombie AI for base attacks
- `playerManager` (PlayerManager): Passed to zombie AI for player attacks

### Properties

```lua
.weaponService       -- Reference to WeaponService
.baseManager         -- Reference to BaseManager (for zombie attacks)
.playerManager       -- Reference to PlayerManager (for zombie attacks)
.spawnPoints         -- Array of spawn positions
.activeZombies       -- Array of active zombie models
.zombieBrains        -- Map of zombie model -> ZombieBrain instance
.zombieCount         -- Total zombies spawned (for naming)
```

### Methods

#### setSpawnPoints
```lua
Spawner:setSpawnPoints(points: table) -> void
```
Sets the spawn point positions from an array of Vector3s.

#### addSpawnPoint
```lua
Spawner:addSpawnPoint(position: Vector3) -> void
```
Adds a single spawn point position.

#### loadSpawnPoints
```lua
Spawner:loadSpawnPoints() -> void
```
Loads spawn points from workspace folder (fallback method).

#### getRandomSpawnPoint
```lua
Spawner:getRandomSpawnPoint() -> Vector3
```
Returns a random spawn point position.

#### getZombieModel
```lua
Spawner:getZombieModel(zombieType: string) -> Model|nil
```
Gets or creates a zombie model for the specified type.

**Parameters:**
- `zombieType` (string): Zombie type from ZombieTypes config

**Returns:**
- Cloned zombie model from ServerStorage.ZombieModels
- Or basic fallback model if custom model not found

#### spawnZombie
```lua
Spawner:spawnZombie(zombieType: string) -> Model|nil
```
Spawns a single zombie of the specified type.

**Parameters:**
- `zombieType` (string): Type from ZombieTypes (Walker, Runner, Brute, etc.)

**Returns:**
- The spawned zombie model or `nil` on failure

**Behavior:**
- Gets zombie stats from ZombieTypes
- Clones or creates zombie model
- Positions at random spawn point
- Sets zombie attributes (IsZombie, ZombieType, Reward)
- Initializes AI with ZombieBrain (passes managers for attacks)
- Sets up death handler
- Adds to active zombies list

#### spawnWave
```lua
Spawner:spawnWave(waveComposition: table) -> number
```
Spawns a complete wave of zombies.

**Parameters:**
- `waveComposition` (table): Map of zombie type to count

**Example:**
```lua
spawner:spawnWave({
    Walker = 5,
    Runner = 3,
    Brute = 1
})
```

**Returns:**
- Number of zombies successfully spawned

#### onZombieDied
```lua
Spawner:onZombieDied(zombie: Model) -> void
```
Called when a zombie dies. Handles cleanup and rewards.

**Behavior:**
- Removes from active zombies list
- Notifies WeaponService for kill rewards
- Destroys ZombieBrain instance
- Cleans up references

#### update
```lua
Spawner:update(deltaTime: number) -> void
```
Updates all active zombie AI brains.

**Parameters:**
- `deltaTime` (number): Time since last update

**Called By:**
- GameManager's main update loop

#### getActiveZombieCount
```lua
Spawner:getActiveZombieCount() -> number
```
Returns the number of living zombies.

#### clearAllZombies
```lua
Spawner:clearAllZombies() -> void
```
Destroys all active zombies and clears tracking.

**Used For:**
- Victory/defeat cleanup
- Round resets

### Integration Notes

**With ZombieBrain:**
- Passes `baseManager` and `playerManager` to each zombie's AI
- Enables zombies to attack both players and base
- Manages zombie AI lifecycle (create, update, destroy)

**With WeaponService:**
- Notifies on zombie kills
- Enables kill rewards and currency

**With GameManager:**
- Called every frame via `update(deltaTime)`
- Spawns waves on command
- Reports zombie counts

### Usage Example

```lua
-- Create spawner with manager references
local spawner = Spawner.new(weaponService, baseManager, playerManager)

-- Set spawn points
spawner:setSpawnPoints(mapManager:getZombieSpawnPoints())

-- Spawn a wave
spawner:spawnWave({
    Walker = 10,
    Runner = 5
})

-- Update in game loop
game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
    spawner:update(deltaTime)
end)
```

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

## CureService

**Location**: `src/server/CureService.lua`
**Type**: Class
**Description**: Handles cure component deposits, puzzle integration, and cure synthesis. Features per-player cure inventory and alliance resource pooling.

### Features

- Each player has their own separate inventory for cure resources
- Each player has their own cure progress meter
- When players form an alliance, their resources are pooled together
- Both allied players see the combined progress of the alliance

### Constructor

```lua
CureService.new(gameManager, playerManager) -> CureService
```

### Methods

#### setPuzzleService
```lua
CureService:setPuzzleService(puzzleService) -> void
```
Links the PuzzleService for puzzle integration.

#### setAllianceService
```lua
CureService:setAllianceService(allianceService) -> void
```
Links the AllianceService for alliance pooling.

#### initializePlayer
```lua
CureService:initializePlayer(player) -> void
```
Initializes player component tracking.

#### handleDepositComponent
```lua
CureService:handleDepositComponent(player, componentName) -> boolean
```
Handles when a player collects a cure component.

#### getEffectiveComponentCount
```lua
CureService:getEffectiveComponentCount(player, componentName) -> number
```
Returns the effective component count (pooled with allies if in alliance).

#### getPooledComponents
```lua
CureService:getPooledComponents(player) -> table
```
Returns all component counts pooled with allies.

#### calculatePlayerCureProgress
```lua
CureService:calculatePlayerCureProgress(player) -> number
```
Calculates cure progress for a player (individual or pooled with allies).

#### getPlayerComponents
```lua
CureService:getPlayerComponents(player) -> table
```
Returns player's individual component counts (not pooled).

#### getPlayerEffectiveComponents
```lua
CureService:getPlayerEffectiveComponents(player) -> table
```
Returns player's effective component counts (pooled if in alliance).

#### onAllianceFormed
```lua
CureService:onAllianceFormed(player1, player2) -> void
```
Called when an alliance is formed - updates progress for both players.

#### onAllianceBroken
```lua
CureService:onAllianceBroken(player1, player2) -> void
```
Called when an alliance is broken - updates progress for both players.

---

## AllianceService

**Location**: `src/server/AllianceService.lua`
**Type**: Class
**Description**: Manages player alliances and betrayals with resource pooling and conditional resource transfer.

### Features

- Allied players pool their cure resources and see combined progress
- Breaking an alliance initiates a betrayal (resources NOT transferred immediately)
- Betrayal is only successful when the instigator eliminates the victim
- If victim kills the betrayer instead, the victim claims ALL of the betrayer's resources

### Constructor

```lua
AllianceService.new() -> AllianceService
```

### Methods

#### setPuzzleService
```lua
AllianceService:setPuzzleService(puzzleService) -> void
```
Links the PuzzleService.

#### setCureService
```lua
AllianceService:setCureService(cureService) -> void
```
Links the CureService.

#### setPlayerManager
```lua
AllianceService:setPlayerManager(playerManager) -> void
```
Links the PlayerManager.

#### initializePlayer
```lua
AllianceService:initializePlayer(player) -> void
```
Initializes alliance tracking for a player.

#### createAlliance
```lua
AllianceService:createAlliance(player1, player2) -> void
```
Creates an alliance between two players.

#### breakAlliance
```lua
AllianceService:breakAlliance(player1, player2) -> void
```
Breaks an alliance (internal method, use handleBreakAlliance for full betrayal logic).

#### areAllied
```lua
AllianceService:areAllied(player1, player2) -> boolean
```
Checks if two players are allied.

#### getAllies
```lua
AllianceService:getAllies(player) -> table
```
Returns array of a player's allies.

#### onPlayerKilled
```lua
AllianceService:onPlayerKilled(deadPlayer, killerPlayer) -> void
```
Integration point - call when a player kills another player. Handles betrayal completion and survivor mechanics.

#### onBetrayerKillsVictim
```lua
AllianceService:onBetrayerKillsVictim(betrayer, victim) -> void
```
Called when a betrayer successfully eliminates their victim. Transfers 75% of resources.

#### onBetrayerKilled
```lua
AllianceService:onBetrayerKilled(betrayer, killer) -> void
```
Called when a betrayer is killed by their victim. Transfers 100% of resources to survivor.

#### transferCureComponents
```lua
AllianceService:transferCureComponents(recipient, source, transferRatio) -> void
```
Transfers cure components from one player to another.

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

## ZombieBrain

**Location**: `src/server/AIScripts/ZombieBrain.lua`  
**Type**: Class  
**Description**: AI controller for individual zombies, handling movement, targeting, and attacks.

### Constructor

```lua
ZombieBrain.new(zombieModel, stats, baseManager, playerManager) -> ZombieBrain|nil
```

Creates a new ZombieBrain instance for a zombie model.

**Parameters:**
- `zombieModel` (Model): The zombie model with Humanoid and HumanoidRootPart
- `stats` (table): Zombie stats from ZombieTypes config
- `baseManager` (BaseManager): Reference for dealing damage to base
- `playerManager` (PlayerManager): Reference for dealing damage to players

**Returns:**
- `ZombieBrain` instance or `nil` if model is invalid

### Properties

```lua
.zombieModel         -- The zombie model
.humanoid            -- The zombie's Humanoid
.rootPart            -- The zombie's HumanoidRootPart
.stats               -- Zombie stats table
.isActive            -- Whether AI is active
.baseManager         -- Reference to BaseManager
.playerManager       -- Reference to PlayerManager
.attackCooldown      -- Time remaining until next attack
.attackInterval      -- Seconds between attacks (from config)
.attackRange         -- Range in studs for attacks (from config)
.attackDamage        -- Damage dealt per attack
.currentTarget       -- Current target position
.currentTargetType   -- "player" or "base"
```

### Methods

#### loadAttackAnimation
```lua
ZombieBrain:loadAttackAnimation() -> void
```
Loads the attack animation from the zombie model if available. Searches for an Animation instance named "AttackAnimation" in the zombie model.

#### playAttackAnimation
```lua
ZombieBrain:playAttackAnimation() -> void
```
Plays the attack animation if one is loaded. Called automatically during attacks.

#### tryAttack
```lua
ZombieBrain:tryAttack() -> boolean
```
Attempts to attack the current target if within range and cooldown is ready.

**Returns:**
- `true` if attack was performed, `false` otherwise

**Behavior:**
- Checks attack cooldown
- Selects best target (player or base)
- Verifies target is within attack range
- Plays attack animation
- Deals damage via appropriate manager
- Resets attack cooldown

#### update
```lua
ZombieBrain:update(deltaTime: number) -> void
```
Updates the zombie AI every frame.

**Parameters:**
- `deltaTime` (number): Time since last update in seconds

**Behavior:**
- Updates attack cooldown
- Attempts to attack if target in range
- Recalculates path every ZOMBIE_REPATH_INTERVAL seconds (0.4s, reduced from 1.0s)
- Maintains continuous movement toward target during cooldown to prevent pausing
- Selects best target (nearest player or base)
- Moves toward target using Humanoid:MoveTo

#### destroy
```lua
ZombieBrain:destroy() -> void
```
Cleans up the zombie AI instance.

**Behavior:**
- Marks as inactive
- Stops attack animations
- Clears all references
- Prevents memory leaks

### AI Behavior

#### Target Selection
The zombie uses intelligent target selection:

1. **Priority**: Always targets the closest threat
2. **Players**: Targets alive players with >0 health
3. **Base**: Targets the base when no players are closer
4. **Fallback**: Targets base if no players exist
5. **Retargeting**: Recalculates every 1 second (configurable)

#### Attack System
- **Range Check**: Attacks only when within ZOMBIE_ATTACK_RANGE (6 studs)
- **Cooldown**: ZOMBIE_ATTACK_INTERVAL (1.5 seconds) between attacks
- **Damage**: Deals ZOMBIE_DAMAGE (10 HP) per attack
- **Animation**: Plays attack animation if available
- **Server-Side**: All damage is server-authoritative

#### Movement
- **Pathfinding**: Uses Humanoid:MoveTo for basic pathfinding
- **Update Rate**: Recalculates path every ZOMBIE_REPATH_INTERVAL (0.4 seconds, reduced from 1.0 to prevent idle pauses)
- **Movement Continuity**: Continues moving toward last known target during cooldown
- **Speed**: Set from zombie stats or ZOMBIE_SPEED config
- **Continuous**: Moves toward target between attacks

### Configuration

The ZombieBrain reads from GameConfig:

```lua
GameConfig.ZOMBIE_ATTACK_RANGE = 6      -- Attack range in studs
GameConfig.ZOMBIE_ATTACK_INTERVAL = 1.5 -- Seconds between attacks
GameConfig.ZOMBIE_REPATH_INTERVAL = 0.4 -- Path recalculation frequency (reduced from 1.0 to prevent pausing)
GameConfig.ZOMBIE_DAMAGE = 10           -- Damage per attack
```

### Animation Support

To add custom attack animations:

1. Create an Animation instance in the zombie model
2. Name it "AttackAnimation"
3. Set the AnimationId to your animation asset
4. The system will automatically load and play it

**Optional**: Zombies function normally without animations.

### Usage Example

```lua
-- Spawner creates zombie brain
local brain = ZombieBrain.new(zombieModel, stats, baseManager, playerManager)

-- Game loop updates brain
game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
    if brain and brain.isActive then
        brain:update(deltaTime)
    end
end)

-- Cleanup on zombie death
humanoid.Died:Connect(function()
    brain:destroy()
end)
```

---

## MapManager

**Location**: `src/server/MapManager.lua`
**Type**: Class
**Description**: Handles cloning of map models from `ServerStorage.Maps`, exposes spawn points to other systems, and manages automatic base camp creation.

### Constructor

```lua
MapManager.new() -> MapManager
```

Initializes the manager, creates a BaseCampSetup instance, and reads fallback spawn folders.

### Methods

#### load
```lua
MapManager:load(mapId: string) -> void
```
Selects a map, clones it into workspace, extracts spawn points, and creates base camp if enabled.

**Parameters:**
- `mapId` (string): The map identifier from MapConfig

**Note**: Automatically calls `BaseCampSetup:setupForMap()` if `GameConfig.AUTO_CREATE_BASE_CAMP` is true.

#### loadDefault
```lua
MapManager:loadDefault() -> void
```
Loads the default map specified in MapConfig.

#### getZombieSpawnPoints
```lua
MapManager:getZombieSpawnPoints() -> table
```
Returns table of zombie spawn positions.

**Returns**: Array of `Vector3` positions

#### getResourceSpawnPoints
```lua
MapManager:getResourceSpawnPoints() -> table
```
Returns table of resource spawn positions.

**Returns**: Array of `Vector3` positions

#### getCurrentMapId
```lua
MapManager:getCurrentMapId() -> string?
```
Returns the active map identifier for UI announcements.

**Returns**: `string` map ID or `nil` if no map loaded

#### extractPoints
```lua
MapManager:extractPoints() -> void
```
Internal method to extract spawn points from the current map model.

---

## BaseCampSetup

**Location**: `src/server/BaseCampSetup.lua`
**Type**: Class
**Description**: Creates and manages defensive base camp structures in the center of the map. Automatically generates walls, gates, cover positions, and zombie targeting zones.

### Constructor

```lua
BaseCampSetup.new() -> BaseCampSetup
```

Creates a new BaseCampSetup instance.

### Methods

#### setupForMap
```lua
BaseCampSetup:setupForMap(mapManager: MapManager) -> (Model, Model)
```
Sets up the base camp for the current map using MapManager's spawn points.

**Parameters:**
- `mapManager` (MapManager): The map manager instance with loaded spawn points

**Returns:**
- `baseCamp` (Model): The created base camp model
- `baseCaptureZone` (Model): The BaseCaptureZone model for zombie targeting

**Note**: This method is called automatically by MapManager when a map loads if `GameConfig.AUTO_CREATE_BASE_CAMP` is true.

#### buildBaseCamp
```lua
BaseCampSetup:buildBaseCamp(centerPos: Vector3, parentModel: Instance?) -> (Model, Model)
```
Builds the complete base camp structure at the specified position.

**Parameters:**
- `centerPos` (Vector3): Center position for the base camp
- `parentModel` (Instance, optional): Parent to place base camp under (defaults to workspace)

**Returns:**
- `baseCamp` (Model): The created base camp model containing platform, walls, gates, and cover
- `baseCaptureZone` (Model): The BaseCaptureZone model with HitBox for zombie targeting

**Structure Created:**
- Base platform (30x30 studs, concrete)
- 4 defensive walls (12 studs high, 2 studs thick)
- 4 gates at cardinal directions (8 studs wide, semi-transparent)
- 8 cover positions (4x3x1 studs, arranged in circle)
- BaseCaptureZone model with invisible HitBox

#### calculateMapCenter
```lua
BaseCampSetup:calculateMapCenter(zombieSpawnPoints: table) -> Vector3
```
Calculates the center position of the map based on zombie spawn points.

**Parameters:**
- `zombieSpawnPoints` (table): Array of Vector3 positions

**Returns**: `Vector3` - The calculated center position with ground-level Y coordinate

**Note**: Uses raycasting to find proper ground level. Falls back to Vector3.new(0, 5, 0) if no spawn points provided.

#### cleanup
```lua
BaseCampSetup:cleanup() -> void
```
Removes existing base camp and BaseCaptureZone from workspace.

**Note**: Called automatically when a new map is loaded to remove the previous base camp.

### Configuration

The base camp appearance is configured via the `CAMP_CONFIG` table in BaseCampSetup.lua:

```lua
local CAMP_CONFIG = {
    BASE_SIZE = 30,              -- Size of central base structure (studs)
    WALL_HEIGHT = 12,            -- Height of defensive walls
    WALL_THICKNESS = 2,          -- Thickness of walls
    GATE_WIDTH = 8,              -- Width of gates in walls
    NUM_GATES = 4,               -- Number of gates
    COVER_COUNT = 8,             -- Number of cover positions
    COVER_SIZE = Vector3.new(4, 3, 1), -- Size of cover objects
    
    -- Colors and materials
    WALL_COLOR = Color3.fromRGB(80, 80, 80),
    BASE_COLOR = Color3.fromRGB(100, 100, 100),
    GATE_COLOR = Color3.fromRGB(120, 80, 40),
    COVER_COLOR = Color3.fromRGB(70, 70, 70),
    
    WALL_MATERIAL = Enum.Material.Concrete,
    BASE_MATERIAL = Enum.Material.Concrete,
    GATE_MATERIAL = Enum.Material.Wood,
    COVER_MATERIAL = Enum.Material.Metal,
}
```

### Integration

The base camp system integrates with:
- **MapManager**: Automatic creation during map loading
- **TargetingService**: Zombies target the BaseCaptureZone HitBox
- **BaseManager**: Health tracking for the base (unchanged)
- **GameConfig**: Toggle auto-creation with `AUTO_CREATE_BASE_CAMP`

---

## LobbyManager

**Location**: `src/server/LobbyManager.lua`
**Type**: Class
**Description**: Manages the pre-round lobby where players vote on maps. Handles the game flow between rounds.

### Constructor

```lua
LobbyManager.new() -> LobbyManager
```

Creates a new LobbyManager instance.

### Methods

#### setMapManager
```lua
LobbyManager:setMapManager(mapManager: MapManager) -> void
```
Sets the MapManager reference for loading selected maps.

#### setGameManager
```lua
LobbyManager:setGameManager(gameManager: GameManager) -> void
```
Sets the GameManager reference for game state coordination.

#### getMapOptions
```lua
LobbyManager:getMapOptions() -> table
```
Returns array of available maps for voting.

**Returns:**
```lua
{
    { id = "MapId", name = "Map Name", description = "Map description" },
    ...
}
```

#### startVoting
```lua
LobbyManager:startVoting() -> boolean
```
Starts the map voting phase. Broadcasts MapVoteStart to all clients.

#### handlePlayerVote
```lua
LobbyManager:handlePlayerVote(player: Player, mapId: string) -> void
```
Handles a player's vote for a map. Updates vote counts and broadcasts to clients.

#### endVoting
```lua
LobbyManager:endVoting() -> string|nil
```
Ends voting and selects the winning map. Handles ties with random selection.

**Returns:**
- Selected map ID, or nil if voting wasn't active

#### update
```lua
LobbyManager:update(deltaTime: number) -> void
```
Updates the lobby state timer. Called from game loop.

#### isVotingActive
```lua
LobbyManager:isVotingActive() -> boolean
```
Returns whether map voting is currently active.

#### getSelectedMapId
```lua
LobbyManager:getSelectedMapId() -> string|nil
```
Returns the map ID selected after voting ends.

#### reset
```lua
LobbyManager:reset() -> void
```
Resets the lobby manager for a new round.

#### onPlayerLeave
```lua
LobbyManager:onPlayerLeave(player: Player) -> void
```
Cleans up player's vote when they leave the game.

### Remote Events

- `MapVoteStart` (Server → Client): Voting has started, includes map options
- `MapVoteUpdate` (Server → Client): Vote count updates and timer
- `MapVoteEnd` (Server → Client): Voting ended, shows selected map
- `CastMapVote` (Client → Server): Player casts their vote

---

## SpectatorManager

**Location**: `src/server/SpectatorManager.lua`
**Type**: Class
**Description**: Manages spectator mode for players who have died during a round. Dead players can spectate other living players until the round ends.

### Constructor

```lua
SpectatorManager.new() -> SpectatorManager
```

Creates a new SpectatorManager instance.

### Methods

#### onPlayerDied
```lua
SpectatorManager:onPlayerDied(player: Player) -> void
```
Marks a player as dead and puts them into spectator mode. Finds an alive player to spectate.

#### findAlivePlayer
```lua
SpectatorManager:findAlivePlayer(excludeUserId: number, spectator: Player) -> Player|nil
```
Finds an alive player to spectate, excluding the given user ID.

#### getAlivePlayers
```lua
SpectatorManager:getAlivePlayers() -> table
```
Returns array of all alive players.

#### cycleSpectatorTarget
```lua
SpectatorManager:cycleSpectatorTarget(player: Player, direction: string) -> void
```
Cycles the spectator's target to next/previous alive player.

**Parameters:**
- `player` (Player): The spectating player
- `direction` (string): "next" or "prev"

#### onSpectatorTargetDied
```lua
SpectatorManager:onSpectatorTargetDied(targetUserId: number) -> void
```
Called when a spectated player dies. Automatically cycles spectators to next target.

#### exitSpectatorMode
```lua
SpectatorManager:exitSpectatorMode(player: Player) -> void
```
Removes a player from spectator mode.

#### endRound
```lua
SpectatorManager:endRound() -> void
```
Exits all players from spectator mode at end of round.

#### reset
```lua
SpectatorManager:reset() -> void
```
Resets the spectator manager for a new round.

#### isPlayerDead
```lua
SpectatorManager:isPlayerDead(player: Player) -> boolean
```
Checks if a player is marked as dead this round.

#### isSpectating
```lua
SpectatorManager:isSpectating(player: Player) -> boolean
```
Checks if a player is currently in spectator mode.

#### broadcastAliveList
```lua
SpectatorManager:broadcastAliveList() -> void
```
Sends updated alive player list to all spectators.

### Remote Events

- `EnterSpectatorMode` (Server → Client): Put player into spectator mode
- `ExitSpectatorMode` (Server → Client): Remove player from spectator mode
- `SpectatorTargetUpdate` (Server → Client): Update who player is spectating
- `SpectatorCycleTarget` (Client → Server): Player wants to cycle target
- `SpectatorStateUpdate` (Server → Client): Update list of alive players

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

## FPSAnimationController

**Location**: `src/client/FPSAnimationController.client.lua`  
**Type**: Module  
**Description**: Client-side animation controller for first-person weapon animations. Manages viewmodel, animation playback, and procedural animations.

**See Also**: [WEAPON_ANIMATIONS.md](WEAPON_ANIMATIONS.md) for complete documentation.

### Properties

```lua
FPSAnimationController.enabled: boolean          -- Master enable/disable
FPSAnimationController.viewmodel: Model          -- Viewmodel containing arms and weapon
FPSAnimationController.currentWeapon: string     -- Currently equipped weapon ID
FPSAnimationController.isReloading: boolean      -- Whether reload is in progress
FPSAnimationController.isSprinting: boolean      -- Whether sprint animation is active
FPSAnimationController.isADS: boolean            -- Whether ADS animation is active
```

### Methods

#### createViewmodel
```lua
FPSAnimationController:createViewmodel() -> void
```
Creates or retrieves the viewmodel (first-person arms). Automatically creates placeholder arms if custom arms not found.

#### loadWeaponModel
```lua
FPSAnimationController:loadWeaponModel(weaponId: string) -> void
```
Loads a weapon model into the viewmodel. Looks for model in `ServerStorage.Guns.[weaponId]` or creates placeholder.

**Parameters:**
- `weaponId` - Weapon identifier (e.g., "Pistol", "SMG")

#### equipWeapon
```lua
FPSAnimationController:equipWeapon(weaponId: string) -> void
```
Equips a weapon, loading its model and playing equip animation.

**Parameters:**
- `weaponId` - Weapon to equip

**Side Effects:**
- Stops all current animations
- Loads weapon model
- Plays equip animation
- Starts idle animation after delay

#### playIdle
```lua
FPSAnimationController:playIdle(weaponId: string) -> void
```
Plays looping idle animation for the weapon.

#### playFire
```lua
FPSAnimationController:playFire(weaponId: string) -> void
```
Plays fire/shoot animation for the weapon. Non-looping, auto-cleans up.

#### playReload
```lua
FPSAnimationController:playReload(weaponId: string, reloadTime: number) -> void
```
Plays reload animation, automatically adjusting speed to match reload time.

**Parameters:**
- `weaponId` - Weapon being reloaded
- `reloadTime` - Duration of reload (from weapon stats)

#### playEquip
```lua
FPSAnimationController:playEquip(weaponId: string) -> void
```
Plays weapon equip/draw animation. Non-looping.

#### setSprinting
```lua
FPSAnimationController:setSprinting(isSprinting: boolean) -> void
```
Toggles sprint animation state.

**Parameters:**
- `isSprinting` - Whether player is sprinting

#### setADS
```lua
FPSAnimationController:setADS(isADS: boolean) -> void
```
Toggles ADS (aim down sights) animation state.

**Parameters:**
- `isADS` - Whether player is aiming

#### cancelReload
```lua
FPSAnimationController:cancelReload() -> void
```
Cancels reload animation if in progress.

#### stopAnimation
```lua
FPSAnimationController:stopAnimation(animationType: string) -> void
```
Stops a specific animation type.

**Parameters:**
- `animationType` - One of: "idle", "fire", "reload", "equip", "sprint", "ads"

#### stopAllAnimations
```lua
FPSAnimationController:stopAllAnimations() -> void
```
Stops all active animations.

### Procedural Animation Methods

#### updateWeaponSway
```lua
FPSAnimationController:updateWeaponSway(deltaTime: number) -> CFrame
```
Calculates weapon sway based on mouse movement. Called automatically in update loop.

**Returns:**
- CFrame offset for weapon sway

#### updateBreathing
```lua
FPSAnimationController:updateBreathing(deltaTime: number) -> CFrame
```
Calculates breathing idle motion. Called automatically in update loop.

**Returns:**
- CFrame offset for breathing

#### applyRecoilOffset
```lua
FPSAnimationController:applyRecoilOffset(vertical: number, horizontal: number) -> void
```
Applies recoil offset to viewmodel. Called by weapon controller when firing.

**Parameters:**
- `vertical` - Vertical recoil in degrees
- `horizontal` - Horizontal recoil in degrees

#### updateRecoilRecovery
```lua
FPSAnimationController:updateRecoilRecovery(deltaTime: number) -> CFrame
```
Smoothly recovers from recoil. Called automatically in update loop.

**Returns:**
- CFrame offset for recoil

#### updateViewmodelPosition
```lua
FPSAnimationController:updateViewmodelPosition(deltaTime: number) -> void
```
Main update function combining all procedural animations. Called every frame via RenderStepped.

**Parameters:**
- `deltaTime` - Time since last frame

### Events

The controller listens for the following BindableEvents in `PlayerGui.BindableEvents`:

- **WeaponFired** - Triggers `playFire()`
- **ReloadStarted** - Triggers `playReload()`
- **ReloadCanceled** - Triggers `cancelReload()`
- **WeaponEquipped** - Triggers `equipWeapon()`
- **ADSStateChanged** - Triggers `setADS()`
- **SprintStateChanged** - Triggers `setSprinting()`

### Configuration

All animation settings are in `FPSConfig.Animations`:

```lua
-- Enable/disable
FPSConfig.Animations.Enabled = true

-- Procedural settings
FPSConfig.Animations.WeaponSwayEnabled = true
FPSConfig.Animations.SwayAmount = 0.02
FPSConfig.Animations.SwaySpeed = 10

FPSConfig.Animations.BreathingEnabled = true
FPSConfig.Animations.BreathSpeed = 2
FPSConfig.Animations.BreathAmount = 0.01

FPSConfig.Animations.RecoilAnimationEnabled = true
FPSConfig.Animations.RecoilRecoverySpeed = 10

-- Animation asset IDs
FPSConfig.Animations.WeaponAnimations = {
    Pistol = {
        idle = "rbxassetid://0",
        fire = "rbxassetid://0",
        reload = "rbxassetid://0",
        equip = "rbxassetid://0",
        sprint = "rbxassetid://0",
        ads = "rbxassetid://0",
    },
    -- Repeat for each weapon
}

-- Weapon offsets
FPSConfig.Animations.WeaponOffsets = {
    Pistol = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(90), 0),
    -- Adjust per weapon
}
```

### Usage Example

```lua
-- Controller auto-initializes on client
-- No manual setup required

-- Manually trigger animation (typically done via events)
local FPSAnimationController = require(script.FPSAnimationController)

-- Equip weapon
FPSAnimationController:equipWeapon("Pistol")

-- Play fire animation
FPSAnimationController:playFire("Pistol")

-- Start reload
FPSAnimationController:playReload("Pistol", 1.5)

-- Toggle ADS
FPSAnimationController:setADS(true)
```

### Animation Asset Structure

For each weapon, provide 6 animation assets:

1. **Idle** - Looped, subtle weapon movement
2. **Fire** - Brief recoil animation (0.1-0.3s)
3. **Reload** - Full reload sequence (1.5-3s)
4. **Equip** - Weapon draw (0.3-0.5s)
5. **Sprint** - Looped, weapon lowered
6. **ADS** - Looped, sights aligned

See [ANIMATION_CREATION_GUIDE.md](ANIMATION_CREATION_GUIDE.md) for creating these animations.

### Integration with Weapon Controller

The FPSWeaponController automatically fires animation events:

```lua
-- In FPSWeaponController.client.lua
weaponFiredBindable:Fire({ weaponId = currentWeapon })     -- Fires on weapon shot
reloadStartedBindable:Fire({ weaponId, duration })         -- Fires on reload start
weaponEquippedBindable:Fire(weaponId)                      -- Fires on weapon equip
adsStateBindable:Fire(isADS)                               -- Fires on ADS toggle
```

FPSAnimationController listens to these events and responds automatically.

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
---

## AllianceServiceV2 (New Networked System)

**Location**: `ServerScriptService/AllianceServiceV2.lua`  
**Type**: Class  
**Description**: New alliance system with networked resource pooling, undirected alliance graph, and 3-outcome betrayal mechanics.

**See**: `ALLIANCE_POOLING_SYSTEM.md` for complete documentation

### Key Features

- Undirected alliance graph with connected components
- Direct-ally-only friendly fire protection
- Immutable snapshot pooling for betrayal
- 3-outcome betrayal system (75% pooled, 75% mirrored, 100% personal + Traitor)
- Disconnect treated as death
- Atomic transaction system preventing duping
- Deterministic weapon selection for transfers

### Core Modules

#### AllianceGraph

**Location**: `ServerScriptService/Alliance/AllianceGraph.lua`

```lua
-- Create graph
local graph = AllianceGraph.new()

-- Manage edges
graph:addEdge(player1, player2) -> boolean
graph:removeEdge(player1, player2) -> boolean
graph:removeAllEdges(player) -> boolean

-- Queries
graph:getDirectAllies(player) -> {Player}
graph:areDirectAllies(player1, player2) -> boolean
graph:getComponent(player) -> {userId}  -- BFS connected component
```

#### PoolCalculator

**Location**: `ServerScriptService/Alliance/PoolCalculator.lua`

```lua
-- Create calculator
local calc = PoolCalculator.new(playerManager, allianceGraph)

-- Get contribution for single player
calc:getContribution(playerId) -> {
    currency = number,
    resources = {[name]=count},
    components = {[name]=count},
    progressPoints = number,
    weapons = {list={}, valueTotal=number}
}

-- Create immutable snapshot
calc:snapshotPool(targetPlayer) -> {
    members = {userId1, userId2, ...},
    contributions = {[userId]=contribution},
    totals = {...},
    timestamp = number
}
```

#### InventoryLedger

**Location**: `ServerScriptService/Alliance/InventoryLedger.lua`

```lua
-- Create ledger
local ledger = InventoryLedger.new(playerManager)

-- Atomic transactions
ledger:begin() -> boolean
ledger:applyDeduction(userId, deductionStruct) -> boolean
ledger:applyGrant(userId, grantStruct) -> boolean
ledger:commit() -> boolean
ledger:rollback() -> boolean
```

#### BetrayalService

**Location**: `ServerScriptService/Alliance/BetrayalService.lua`

```lua
-- Create service
local service = BetrayalService.new(graph, calc, ledger, playerManager)

-- Start betrayal (removes edge, creates snapshots, starts 30s window)
service:startBetrayal(betrayer, victim) -> boolean, errorMessage

-- Handle kills during window
service:onPlayerKilled(killer, victim) -> void

-- Handle disconnects
service:onPlayerDisconnect(player) -> void

-- Query status
service:isPlayerLocked(player) -> boolean
service:isTraitor(player) -> boolean
```

#### WeaponValues

**Location**: `ReplicatedStorage/Shared/WeaponValues.lua`

```lua
WeaponValues.getValue(weaponId) -> number
WeaponValues.getTotalValue(weaponList) -> number
WeaponValues.sortWeapons(weaponList) -> sortedList  -- Deterministic
```

### Betrayal Outcomes

#### Outcome 1: Successful Betrayal
- **Trigger**: Betrayer kills victim within 30 seconds
- **Transfer**: 75% of victim's pooled resources to betrayer
- **Deduction**: Proportional across all members of victim's pool

#### Outcome 2: Failed Betrayal
- **Trigger**: Victim kills betrayer within 30 seconds
- **Transfer**: 75% of betrayer's pooled resources to victim
- **Deduction**: Proportional across all members of betrayer's pool

#### Outcome 3: Stalemate
- **Trigger**: 30 seconds expire without either killing the other
- **Transfer**: 100% of betrayer's PERSONAL inventory to victim
- **Penalty**: Betrayer marked as Traitor (cannot ally for rest of round)
- **Effect**: All of betrayer's remaining alliances severed

### Remote Events

#### BetrayalStarted
**Direction**: Server → Client

```lua
{
    type = "betrayer" | "victim",
    victim = string,  -- victim name (if betrayer)
    betrayer = string,  -- betrayer name (if victim)
    duration = number  -- window duration in seconds
}
```

#### BetrayalOutcome
**Direction**: Server → Client

```lua
{
    type = "success" | "victory" | "stalemate_betrayer" | "stalemate_victim",
    message = string
}
```

### Configuration

```lua
-- GameConfig.lua
POOLED_TRANSFER_PERCENT = 0.75  -- Outcome 1 & 2
PERSONAL_TRANSFER_PERCENT_ON_STALEMATE = 1.00  -- Outcome 3
BETRAYAL_WINDOW = 30  -- seconds
BETRAYAL_COOLDOWN = 60  -- seconds
```

### Integration

```lua
-- MainServer.lua
local AllianceService = require(script.Parent.AllianceServiceV2)
local allianceService = AllianceService.new()

-- Set dependencies
allianceService:setPlayerManager(playerManager)
allianceService:setCureService(cureService)
allianceService:setPuzzleService(puzzleService)

-- Initialize players
allianceService:initializePlayer(player)

-- Handle kills
allianceService:onPlayerKilled(deadPlayer, killerPlayer)

-- Handle disconnects
allianceService:removePlayer(player)  -- calls onPlayerDisconnect internally
```

### Security Features

- **Server-authoritative**: All calculations server-side
- **Snapshot immutability**: Pool values frozen at betrayal start
- **Atomic transactions**: No duping possible
- **Validation**: All deductions validated before application
- **Disconnect handling**: Treated as death, deductions still apply

### Acceptance Tests

✓ Graph pooling includes all connected component members  
✓ Friendly fire only OFF for direct allies  
✓ Snapshots don't change after betrayal start  
✓ No duping (deducted == transferred)  
✓ Disconnect doesn't avoid deductions  

