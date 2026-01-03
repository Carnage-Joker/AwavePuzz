# Player Spawn Management System - Implementation Summary

## Problem Statement
Players were spawning immediately when joining the game, before the map voting completed. The requirement was to ensure players don't spawn until after the map is voted in and loaded at position (5000, 0, 0), with players spawning on the map in first-person mode.

## Solution Overview
Implemented a comprehensive player spawn management system that:
1. Keeps players in an invisible "waiting" state during lobby/voting
2. Spawns player characters on the map after voting completes
3. Lobby and map share X/Z at (5000, 0) — maps at (5000, 0, 0), lobby at (5000, 5, 0)
4. First-person camera is handled by existing FPS system

## Key Components

### 1. PlayerSpawnManager (`ServerScriptService/PlayerSpawnManager.lua`)
**Purpose**: Controls when and where players spawn throughout the game lifecycle.

**Key Features**:
- Tracks player spawn state: "waiting" (lobby) → "map" (gameplay)
- Manages character visibility and collision
- Stores and restores original transparency values
- Positions characters appropriately based on game state

**States**:
- **Waiting State** (Lobby/Voting):
  - Character positioned at (5000, 10000, 0) - high above map
  - All BaseParts made invisible (transparency = 1)
  - Collisions disabled
  - Players see voting UI but not their character

- **Map State** (Gameplay):
  - Character respawns near base camp (around 5000, Y, 0)
  - Original transparency values restored
  - Collisions enabled (except HumanoidRootPart)
  - Character fully visible and interactive

**Integration Points**:
- `onPlayerAdded`: Called when player joins server
- `keepPlayerInLobby`: Called when resetting for new round
- `spawnAllPlayersOnMap`: Called when map voting completes
- `resetForNewRound`: Called at start of each new round

### 2. LobbySetup (`ServerScriptService/LobbySetup.lua`)
**Purpose**: Creates a physical lobby structure at the map position.

**Key Features**:
- Lobby positioned at (5000, 5, 0) - same X/Z as maps
- 50x50 stud platform with walls
- No SpawnLocation (to avoid conflicts with manual spawn management)
- Created at round start, destroyed when map loads

**Usage**:
```lua
local lobbySetup = LobbySetup.new()
lobbySetup:createLobby()  -- Create lobby
lobbySetup:cleanup()      -- Remove lobby
```

### 3. GameManager Integration
**Modified Methods**:

**`GameManager.new()`**:
- Added PlayerSpawnManager initialization
- Added LobbySetup initialization
- Creates lobby on startup

**`onPlayerAdded()`**:
- Calls `playerSpawnManager:onPlayerAdded(player)`
- Sets up spawn management for new players

**`onPlayerRemoving()`**:
- Calls `playerSpawnManager:onPlayerRemoving(player)`
- Cleans up spawn state

**`resetForNewRound()`**:
- Calls `playerSpawnManager:keepPlayerInLobby(player)` for all players
- Resets spawn tracking
- Puts players in invisible waiting state

**`startLobby()`**:
- Recreates lobby structure
- Prepares for new voting round

**`updateLobby()`**:
- When voting completes:
  - Cleans up lobby structure
  - Loads selected map at (5000, 0, 0)
  - Calls `playerSpawnManager:spawnAllPlayersOnMap()`
  - Starts countdown to game

## Technical Details

### Character Visibility Management
The system stores original transparency values before making characters invisible:

```lua
-- Store original values (only once per round)
self.originalTransparency[userId][part] = part.Transparency

-- Make invisible in lobby
part.Transparency = 1

-- Restore when spawning on map
part.Transparency = self.originalTransparency[userId][part] or 0
```

This ensures accessories, clothing, and special effects maintain their original appearance.

### Spawn Position Logic
When spawning on map, the system:
1. Tries to find BaseCamp in workspace
2. Uses BaseCamp.PrimaryPart position if available
3. Falls back to any BasePart in BaseCamp
4. Final fallback: (5000, 10, 0)
5. Adds random offset (-10 to +10) to spread players out

### State Tracking
```lua
playerSpawnState[userId] = "waiting" | "map"
playersSpawnedOnMap[userId] = boolean
originalTransparency[userId] = { [part] = transparency }
playerConnections[userId] = connection
```

## Game Flow

### 1. Player Joins
```
Player Connects
  ↓
GameManager:onPlayerAdded()
  ↓
PlayerSpawnManager:onPlayerAdded()
  ↓
Character spawns (Roblox default)
  ↓
onCharacterAdded() detects state = "waiting"
  ↓
Character repositioned to (5000, 10000, 0)
  ↓
Character made invisible
```

### 2. Lobby/Voting Phase
```
Players in invisible waiting state
  ↓
Voting UI visible
  ↓
Players vote on map
  ↓
Timer counts down
```

### 3. Map Load and Spawn
```
Voting completes
  ↓
Lobby cleanup
  ↓
Map loads at (5000, 0, 0)
  ↓
PlayerSpawnManager:spawnAllPlayersOnMap()
  ↓
For each player: LoadCharacter()
  ↓
onCharacterAdded() detects state = "map"
  ↓
Character positioned near base camp
  ↓
Transparency restored
  ↓
Collisions enabled
  ↓
Players can play normally
```

### 4. New Round
```
Round ends (Victory/Defeat)
  ↓
Scoreboard displayed
  ↓
GameManager:startLobby()
  ↓
Lobby recreated
  ↓
PlayerSpawnManager:resetForNewRound()
  ↓
playerSpawnManager:keepPlayerInLobby() for all players
  ↓
Back to step 2
```

## Configuration

### Constants
- **Lobby Position**: `Vector3.new(5000, 5, 0)`
- **Waiting Position**: `Vector3.new(5000, 10000, 0)` (high above map)
- **Map Offset**: `Vector3.new(5000, 0, 0)`
- **Spawn Randomization**: ±10 studs on X and Z axes

### Dependencies
- `GameManager` - Main game state machine
- `LobbyManager` - Voting system
- `MapManager` - Map loading at (5000, 0, 0)
- `BaseManager` - Base camp reference for spawn position
- FPS System - Client-side first-person camera

## Testing
See `docs/PLAYER_SPAWN_TESTING.md` for comprehensive testing instructions.

## Benefits
1. **Clean Separation**: Lobby and gameplay are clearly separated
2. **Menu-Only Lobby**: Players focus on voting without character distractions
3. **Proper Spawn Timing**: Characters only exist when gameplay starts
4. **Position Control**: All spawning happens at map offset (5000, 0, 0)
5. **Transparency Preservation**: Character accessories and effects maintain original appearance
6. **Flexible**: Easy to modify spawn positions or add lobby features
7. **Reusable**: System works across multiple rounds

## Potential Enhancements
1. Add spectator camera during lobby (instead of invisible character)
2. Add lobby decorations or information displays
3. Add spawn animations when characters appear on map
4. Add team-based spawn positions
5. Add spawn protection period after map spawn

## Troubleshooting
- If players spawn at wrong location: Check MapManager and BaseCampSetup
- If players remain invisible: Check transparency restoration in onCharacterAdded
- If players see character in lobby: Verify spawn state is "waiting"
- If camera issues: Check FirstPersonCamera.lua on client side
