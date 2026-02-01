# Boot Flow Documentation

## Overview

This document describes the server boot flow and state transitions for AwavePuzz (Aether Wave: Convergence).

## Join Flow Diagram

```
Player joins from Roblox home page
    ↓
Boot / Loading Phase (no map loaded)
    ↓
Title Screen (client UI, first interaction)
    ↓
Lobby (player CAN MOVE; portals are visible and usable)
    ↓
Portal Queue / Matchmaking (or Map Voting if portal matchmaking disabled)
    ↓
Selected map loads at pivot (5000, 0, 0) and round starts
    ↓
Wave-based gameplay
    ↓
Victory or Defeat
    ↓
Scoreboard
    ↓
Epilogue (optional, only after round ends)
    ↓
Back to Lobby
```

## State Transitions

### Initial Boot (First Join)

1. **Server Start**
   - GameManager initializes in `TITLE_SCREEN` state (if `SHOW_TITLE_SCREEN = true`)
   - Lobby is created by LobbySetup
   - Portals are created if `USE_PORTAL_MATCHMAKING = true`
   - **NO MAP IS LOADED** (maps load only after portal queue or lobby voting)

2. **Player Joins**
   - Player character spawns in lobby (visible, can move)
   - Title Screen UI shows on client
   - Player clicks "Continue" on title screen

3. **After Title Screen**
   - State: `TITLE_SCREEN` → `LOBBY`
   - All players spawn in lobby with movement enabled
   - Portals are visible and usable
   - Lobby voting starts (if portal matchmaking disabled) OR portals accept players

4. **Portal Queue / Matchmaking**
   - Players walk into portals to join queue
   - Portal shows queue count (e.g., "3/8")
   - Countdown starts when minimum players reached
   - Match launches when countdown completes or max players reached

5. **Map Load & Round Start**
   - State: `LOBBY` → `COUNTDOWN` → `WAVE_ACTIVE`
   - Map loads at pivot position (5000, 0, 0)
   - Players teleport to map spawn points
   - Wave-based zombie survival begins

### Round End Flow

1. **Round Ends** (Victory or Defeat)
   - State: `WAVE_ACTIVE` → `VICTORY` or `DEFEAT`
   - Zombies cleared
   - Credits shown (on victory)

2. **Scoreboard**
   - State: `VICTORY/DEFEAT` → `SCOREBOARD`
   - Stats displayed for configured duration

3. **Epilogue** (optional)
   - State: `SCOREBOARD` → `EPILOGUE` (if `SHOW_EPILOGUE = true`)
   - Story cinematic plays
   - **This is the ONLY time epilogue should show** (not on first join!)

4. **Return to Lobby**
   - State: `EPILOGUE` → `LOBBY` (or `SCOREBOARD` → `LOBBY` if epilogue disabled)
   - Players return to lobby for next match
   - Portals reset and accept new queues

## Game States

| State | Description | Duration |
|-------|-------------|----------|
| `TITLE_SCREEN` | Initial state; title screen shown to players | Until all players continue or timeout |
| `LOBBY` | Players in lobby; can move and interact with portals/voting | Until map selected |
| `COUNTDOWN` | Pre-round countdown; players on map | `ROUND_COUNTDOWN_TIME` (default: 5s) |
| `WAVE_ACTIVE` | Active wave gameplay | Until wave complete or time limit |
| `INTERMISSION` | Between waves; shop available | `WAVE_DELAY` (default: 30s) |
| `VICTORY` | Cure completed; credits shown | `SCOREBOARD_DISPLAY_TIME` + credits time |
| `DEFEAT` | Base destroyed or all players dead | `SCOREBOARD_DISPLAY_TIME` |
| `SCOREBOARD` | End of round stats | 2 seconds |
| `EPILOGUE` | Story cinematic (only after round) | Until all players complete |
| `WAITING` | Waiting for minimum players | N/A |

## Key Configuration Values

### Feature Flags (GameConfig.lua)

- **`USE_PORTAL_MATCHMAKING`** - Enable portal-based matchmaking (`true` = portals, `false` = voting)
- **`SHOW_TITLE_SCREEN`** - Show title screen on first join (`true`/`false`)
- **`SHOW_EPILOGUE`** - Show epilogue after rounds (`true`/`false`)
- **`ENABLE_MULTI_MAP`** - Enable multiple maps (`true`/`false`)

### Portal Matchmaking Settings (GameConfig.PORTAL_MATCHMAKING)

- **`MAX_PLAYERS_PER_MATCH`** - Maximum players per match (default: `8`)
- **`DEFAULT_MIN_PLAYERS`** - Minimum players to start countdown (default: `1`)
- **`DEFAULT_COUNTDOWN_TIME`** - Countdown duration in seconds (default: `10`)
- **`COUNTDOWN_CANCEL_THRESHOLD`** - Cancel if queue drops below this (default: `1`)
- **`POST_LAUNCH_COOLDOWN`** - Cooldown after match launch (default: `3`)
- **`TOUCH_DEBOUNCE_TIME`** - Debounce for portal touches (default: `0.5`)

### Timing Settings

- **`ROUND_COUNTDOWN_TIME`** - Pre-round countdown (default: `5`)
- **`WAVE_DELAY`** - Intermission between waves (default: `30`)
- **`LOBBY_VOTING_TIME`** - Lobby voting duration (default: `20`)
- **`SCOREBOARD_DISPLAY_TIME`** - Scoreboard display duration (default: `10`)
- **`TITLE_SCREEN_TIMEOUT`** - Auto-continue timeout (default: `30`)

## Lobby Settings

### Lobby Position

- **Lobby spawns 3000 studs from map pivot**: `(8000, 0, 0)` (when map pivot is at `5000, 0, 0`)
- **Player spawn position**: `(8000, 8, 0)` (8 studs above platform)

### Lobby Features

- **Platform**: 60x60 studs with walls
- **Movement**: Players can walk freely
- **Visibility**: Players are visible and not hidden
- **Portals**: 3 portals by default (left, center, right)

## Map Loading

### Map Pivot Position

- **All maps load at**: `(5000, 0, 0)`
- This is the authoritative position for all maps
- Spawn points, base camp, and resources are positioned relative to this pivot

### Map Loading Triggers

Maps are loaded by:

1. **Portal Matchmaking**: When a portal queue reaches countdown completion
   - `PortalMatchmakingService:launchMatch()` → `GameManager:startMatch()`
   
2. **Lobby Voting**: When voting completes (if portal matchmaking disabled)
   - `GameManager:updateLobby()` → `MapManager:load(selectedMapId)`

Maps are **NOT** loaded during:
- Server boot
- Player join
- Title screen display

## Portal System

### Portal Discovery

1. Portals are created by `LobbySetup:createPortals()` during lobby creation
2. Portals are placed in `Workspace.Lobby.Portals`
3. `PortalMatchmakingService:discoverPortals()` registers each portal

### Portal Queue Flow

1. **Player Touches Portal**
   - Touch detection via `TouchPart.Touched`
   - Debounce check (0.5s)
   - Player added to queue

2. **Queue Updates**
   - Queue count broadcast to all clients
   - Visual indicator updates (e.g., "3/8")
   - Client UI updates (PortalQueueUI)

3. **Countdown Start**
   - Triggered when queue ≥ `minPlayers`
   - Countdown duration: `countdownTime` seconds
   - Can be cancelled if queue drops below threshold

4. **Match Launch**
   - Up to 8 players selected from queue
   - Map determined (specific or random)
   - Match registered in MatchRegistry
   - Players teleported to map
   - Round starts

### Portal Attributes

Each portal has:
- **`PortalId`**: Unique identifier (e.g., "ResearchOutpost", "Random")
- **`MapId`**: Map to load (or "Random")
- **`MinPlayers`**: Minimum players to start countdown (default: 1)
- **`CountdownSeconds`**: Countdown duration (default: 10)

## Troubleshooting

### Issue: Epilogue shows on first join

**Cause**: `checkAllPlayersReadyForEpilogue()` was transitioning to `EPILOGUE` instead of `LOBBY`

**Fix**: Changed transition from `TITLE_SCREEN → EPILOGUE` to `TITLE_SCREEN → LOBBY`

### Issue: Players can't move in lobby

**Cause**: `PlayerSpawnManager` was freezing and hiding characters in "waiting" state

**Fix**: Changed lobby spawn to allow movement (`frozen=false`, `hidden=false`)

### Issue: Portals not visible

**Cause**: Portal matchmaking feature flag was disabled

**Fix**: Set `USE_PORTAL_MATCHMAKING = true` in GameConfig.lua

### Issue: Map loads on server boot

**Cause**: `GameManager.new()` was calling `MapManager:loadDefault()`

**Fix**: Removed map loading from constructor; maps now load only after portal/lobby selection

## Developer Notes

### Changing Portal Settings

To adjust portal matchmaking behavior, edit `GameConfig.PORTAL_MATCHMAKING`:

```lua
GameConfig.PORTAL_MATCHMAKING = {
    MAX_PLAYERS_PER_MATCH = 8,      -- Change max players per instance
    DEFAULT_MIN_PLAYERS = 2,         -- Require 2+ players to start
    DEFAULT_COUNTDOWN_TIME = 15,     -- 15 second countdown
    -- ... other settings
}
```

### Adding New Portals

1. Add portal definition to `PortalConfig.lua`:

```lua
MyNewMap = {
    Name = "My New Map",
    MapId = "MyNewMap",
    Description = "A cool new map",
    Color = Color3.fromRGB(255, 100, 100),
}
```

2. Portals will be created automatically by `LobbySetup:createPortals()`

### Disabling Portal Matchmaking

To revert to map voting:

1. Set `USE_PORTAL_MATCHMAKING = false` in GameConfig.lua
2. Restart server
3. Lobby will use traditional voting system instead of portals

## Code Locations

### Server

- **Main.server.lua**: `ServerScriptService/Main.server.lua` - **✨ NEW: Server entry point**
- **RemoteRegistry**: `ReplicatedStorage/Shared/Remotes/RemoteRegistry.lua` - **✨ NEW: Remote management**
- **GameManager**: `ServerScriptService/GameManager.lua` - Main state machine
- **LobbySetup**: `ServerScriptService/LobbySetup.lua` - Lobby creation and portals
- **PortalMatchmakingService**: `ServerScriptService/PortalMatchmakingService.lua` - Portal queue logic
- **PlayerSpawnManager**: `ServerScriptService/PlayerSpawnManager.lua` - Player spawning and lobby
- **MapManager**: `ServerScriptService/MapManager.lua` - Map loading

### Client

- **ClientMain.client.lua**: `StarterPlayerScripts/ClientMain.client.lua` - **✨ NEW: Client entry point**
- **TitleScreenUI**: `StarterPlayerScripts/Modules/UI/TitleScreenUI.lua` - Title screen
- **EpilogueUI**: `StarterPlayerScripts/Modules/UI/EpilogueUI.lua` - Epilogue cinematic
- **PortalQueueUI**: `StarterPlayerScripts/Modules/UI/PortalQueueUI.lua` - Portal queue display
- **LobbyUI**: `StarterPlayerScripts/Modules/UI/LobbyUI.lua` - Lobby interface

### Configuration

- **GameConfig**: `ReplicatedStorage/Shared/GameConfig.lua` - Game settings and feature flags
- **PortalConfig**: `ReplicatedStorage/Shared/PortalConfig.lua` - Portal definitions
- **MapConfig**: `ReplicatedStorage/Shared/MapConfig.lua` - Map definitions

---

**Last Updated**: 2026-02-01  
**AwavePuzz Version**: Modern Luau Refactor - v1.0  
**Changes**: New entry points (Main.server.lua, ClientMain.client.lua), RemoteRegistry, modern Luau patterns
