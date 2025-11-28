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
ZOMBIE_REPATH_INTERVAL = 1.0          -- Path recalculation frequency
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
- Recalculates path every ZOMBIE_REPATH_INTERVAL seconds
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
- **Update Rate**: Recalculates path every ZOMBIE_REPATH_INTERVAL (1.0 seconds)
- **Speed**: Set from zombie stats or ZOMBIE_SPEED config
- **Continuous**: Moves toward target between attacks

### Configuration

The ZombieBrain reads from GameConfig:

```lua
GameConfig.ZOMBIE_ATTACK_RANGE = 6      -- Attack range in studs
GameConfig.ZOMBIE_ATTACK_INTERVAL = 1.5 -- Seconds between attacks
GameConfig.ZOMBIE_REPATH_INTERVAL = 1.0 -- Path recalculation frequency
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