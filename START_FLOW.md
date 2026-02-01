# Start Flow Documentation

## Overview

This document describes the startup and game flow for Aether Wave: Convergence (AwavePuzz). The flow is designed to match the Figma design specifications and provide a smooth player experience from join to gameplay.

## High-Level Flow

```
Player Join → Title Screen → Lobby → Map Loading → Spawn → Countdown → Wave 1
```

## Detailed Flow

### 1. Server Boot

**What happens:**
- Server starts (`MainServer.lua`)
- `GameManager.new()` is called
- Lobby area is created at position (8000, 5, 0)
- **NO gameplay map loads** (this is intentional)
- If `USE_PORTAL_MATCHMAKING` is enabled, portals are discovered
- State is set to `TITLE_SCREEN`

**Expected logs:**
```
[GameManager] Boot complete - no map loaded yet (maps load after lobby/portal selection)
[LobbySetup] Lobby created at position 8000, 5, 0
[PortalMatchmakingService] Discovered N portals
```

**Config flags:**
- `ENABLE_MULTI_MAP` - Must be `true` for map loading system
- `USE_PORTAL_MATCHMAKING` - If `true`, enables portal-based matchmaking instead of voting
- `SHOW_TITLE_SCREEN` - If `true`, shows title screen on join

### 2. Player Join

**What happens:**
- Player connects to server
- `GameManager:onPlayerAdded()` is called
- Player character spawns in lobby area (visible, can move)
- Title screen UI is shown to player
- Player waits in lobby until clicking continue

**Expected logs:**
```
[Flow] Join -> Player <name> added to game
[Flow] Join -> TitleScreen (showing to <name>)
[PlayerSpawnManager] <name> -> LOBBY (visible, can move)
```

**Player experience:**
- Spawns in lobby area
- Can move around freely
- Sees title screen UI overlay
- Sees portals (3D parts with queue indicators)

### 3. Title Screen Continue

**What happens:**
- Player clicks "Continue" button on title screen
- `TitleScreenContinue` remote event fires
- Player is marked as ready
- When ALL players are ready, transition to lobby state

**Expected logs:**
```
[Flow] Player <name> passed title screen (TitleScreenContinue)
[Flow] All players passed title screen
[Flow] TitleScreenContinue -> Lobby (entering lobby)
[Flow] Entering lobby (state -> LOBBY)
```

**Config flags:**
- `INTRO_SHOW_EPILOGUE_ON_FIRST_JOIN` - If `true`, shows epilogue after title screen (default: `false`)
  - When `false`: Title → Lobby (recommended)
  - When `true`: Title → Epilogue → Lobby (for story-driven intro)

**Important notes:**
- Epilogue should NOT show on first join unless `INTRO_SHOW_EPILOGUE_ON_FIRST_JOIN` is `true`
- Epilogue is intended for post-round story content (Victory/Defeat → Epilogue → Lobby)
- Setting `INTRO_SHOW_EPILOGUE_ON_FIRST_JOIN = true` breaks the intended flow

### 4. Lobby State

**What happens:**
- State transitions to `LOBBY`
- Lobby area persists (not recreated)
- If `USE_PORTAL_MATCHMAKING` is enabled:
  - Players can walk to portals and queue
  - No map voting UI
- If `USE_PORTAL_MATCHMAKING` is disabled:
  - Map voting UI appears
  - Players vote for map
  - Timer counts down

**Expected logs:**
```
[Flow] Lobby -> Portal matchmaking enabled (players can queue at portals)
```
OR
```
[LobbyManager] Starting map voting
```

**Player experience:**
- Can move freely in lobby
- Can see other players
- Can interact with portals (if portal matchmaking enabled)
- Can vote for maps (if voting enabled)
- Portals show queue status (0/8 players)

**Lobby constraints:**
- Players can move (WalkSpeed/JumpPower normal)
- Players are visible (not frozen/hidden)
- Physical walls prevent leaving lobby area
- Portals are visible 3D parts in `Workspace.Lobby.Portals`

### 5. Map Loading (Portal Queue Ready OR Voting Complete)

**What happens:**

**A. Portal Matchmaking Path:**
- Portal queue reaches minimum players (default: 1)
- Countdown starts (default: 10 seconds)
- When countdown ends, `PortalMatchmakingService:launchMatch()` calls `GameManager:startMatch()`
- Map loads at pivot (5000, 0, 0)
- Only queued players spawn on map

**B. Map Voting Path:**
- Voting timer expires or all players vote
- `LobbyManager` determines winning map
- `GameManager:updateLobby()` detects voting complete
- Map loads at pivot (5000, 0, 0)
- All players spawn on map

**Expected logs:**
```
[Flow] Lobby -> MapLoading(<mapId>) - Starting match for N players
[Flow] MapLoading(<mapId>) -> Loading map...
[Flow] MapLoaded -> Map <mapId> loaded successfully
[Flow] MapLoaded -> Spawn -> Spawning N players on map
[Flow] Spawn -> Countdown -> Starting countdown
```

**Important notes:**
- Map MUST load at pivot (5000, 0, 0) - separate from lobby at (8000, 5, 0)
- With portal matchmaking, lobby persists for late joiners
- Without portal matchmaking, lobby is cleaned up after map load
- Double-load prevention: `_lobbyResolved` latch prevents race conditions

### 6. Player Spawn on Map

**What happens:**
- `PlayerSpawnManager:spawnPlayerOnMap()` is called for each player
- Player state changes from "waiting" (lobby) to "map"
- `player:LoadCharacter()` respawns player
- Character spawns near BaseCamp or at Spawn1-Spawn8 points
- Character is visible and can move

**Expected logs:**
```
[PlayerSpawnManager] <name> -> MAP (<position>)
[PlayerSpawnManager] Found valid spawn from bag (attempt N)
```

**Spawn logic:**
1. Prefer explicit spawn points (Spawn1-Spawn8 in ActiveMap/SpawnPoints/PlayerSpawns)
2. Fallback to BaseCampSpawn reference
3. Hard fallback to map offset + ground snap

### 7. Countdown

**What happens:**
- State transitions to `COUNTDOWN`
- Countdown timer starts (default: 5 seconds)
- Players can move but game hasn't started
- UI shows countdown
- When timer expires, wave 1 starts

**Expected logs:**
```
[Flow] Countdown -> Wave1 - Starting wave
```

**Config flags:**
- `ROUND_COUNTDOWN_TIME` - Countdown duration in seconds (default: 5)

### 8. Wave 1 Start

**What happens:**
- State transitions to `WAVE_ACTIVE`
- Wave 1 begins
- Zombies spawn
- Game is live

**Expected logs:**
```
[Flow] Countdown -> Wave1 - Starting wave
[GameManager] Spectator mode enabled for this round
```

## Configuration Flags

### Core Settings (GameConfig.lua)

| Flag | Default | Description |
|------|---------|-------------|
| `ENABLE_MULTI_MAP` | `true` | Enable map loading system |
| `USE_PORTAL_MATCHMAKING` | `true` | Use portals instead of voting |
| `SHOW_TITLE_SCREEN` | `true` | Show title screen on join |
| `SHOW_EPILOGUE` | `true` | Enable epilogue content |
| `INTRO_SHOW_EPILOGUE_ON_FIRST_JOIN` | `false` | Show epilogue before first lobby (NOT recommended) |

### Portal Matchmaking Settings (GameConfig.PORTAL_MATCHMAKING)

| Flag | Default | Description |
|------|---------|-------------|
| `MAX_PLAYERS_PER_MATCH` | `8` | Maximum players in one match |
| `DEFAULT_MIN_PLAYERS` | `1` | Minimum players to start match |
| `DEFAULT_COUNTDOWN_TIME` | `10` | Seconds for portal countdown |

### Lobby Settings

| Flag | Default | Description |
|------|---------|-------------|
| `LOBBY_VOTING_TIME` | `5` | Seconds for voting phase |
| `LOBBY_MIN_PLAYERS` | `1` | Minimum players to start lobby |

## Flow Logging

All flow transitions are logged with `[Flow]` prefix for easy debugging:

```
[Flow] Join -> TitleScreen
[Flow] TitleScreenContinue -> Lobby
[Flow] Lobby -> MapLoading(ResearchOutpost)
[Flow] MapLoaded -> Spawn -> Spawning 8 players
[Flow] Spawn -> Countdown -> Starting countdown
[Flow] Countdown -> Wave1
```

This makes it easy to track player progression through the game.

## Troubleshooting

### Problem: Map loads immediately on server boot

**Symptoms:**
- Map appears before title screen
- Players spawn on map instead of lobby

**Cause:**
- Old code called `mapManager:loadDefault()` in `GameManager.new()`

**Fix:**
- Verify lines 161-169 in `GameManager.lua` - map loading should be commented out
- Look for log: `[GameManager] Boot complete - no map loaded yet`

### Problem: Epilogue shows before lobby

**Symptoms:**
- After title screen, epilogue plays immediately
- Players can't get to lobby

**Cause:**
- `INTRO_SHOW_EPILOGUE_ON_FIRST_JOIN` is set to `true`

**Fix:**
- Set `GameConfig.INTRO_SHOW_EPILOGUE_ON_FIRST_JOIN = false`
- Epilogue should only show after rounds (Victory/Defeat → Epilogue → Lobby)

### Problem: Players can't move in lobby

**Symptoms:**
- Players are frozen or invisible in lobby
- Can't walk around

**Cause:**
- Old code froze/hid players in "waiting" state

**Fix:**
- Verify `PlayerSpawnManager.lua` lines 232-238 and 264-267
- Should set `freezeCharacter(character, false)` and `setCharacterHidden(character, false)`
- Look for log: `[PlayerSpawnManager] <name> -> LOBBY (visible, can move)`

### Problem: Portals not visible

**Symptoms:**
- No portals in lobby
- Can't queue for matches

**Cause:**
- Portals not created or not in correct location

**Fix:**
- Verify `LobbySetup:createPortals()` is called when `USE_PORTAL_MATCHMAKING = true`
- Check `Workspace.Lobby.Portals` folder exists
- Look for log: `[LobbySetup] Created N portals`
- Verify `PortalMatchmakingService:discoverPortals()` finds them
- Look for log: `[PortalMatchmakingService] Discovered N portals`

### Problem: Entry point runs multiple times

**Symptoms:**
- Warning in Studio: "script with a non-legacy RunContext..."
- Systems initialize twice
- Duplicate remote connections

**Cause:**
- Old entry points still enabled alongside new ones
- RunContext not properly configured

**Fix:**
1. Ensure old entry points are disabled:
   - `MainServer.lua` should be `MainServer.lua.disabled`
   - `ClientController.client.lua` should be `ClientController.client.lua.disabled`
2. Only `Main.server.lua` and `ClientMain.client.lua` should run
3. Both new entry points have idempotent guards (script attributes)

## Test Checklist

### Solo Join Test
- [ ] Player joins server
- [ ] See `[BOOT][SERVER]` logs for server boot
- [ ] See `[BOOT][CLIENT]` logs for client boot
- [ ] Title screen appears
- [ ] No map loaded yet (lobby only)
- [ ] Player clicks continue
- [ ] Lobby state entered
- [ ] Player can move freely
- [ ] Portals are visible with queue UI
- [ ] Player touches portal
- [ ] Countdown starts
- [ ] Map loads after countdown
- [ ] Player spawns on map
- [ ] Countdown to wave 1
- [ ] Wave 1 starts

### Two Player Test
- [ ] Both players see title screen
- [ ] Both click continue
- [ ] Both enter lobby together
- [ ] Both can move and see each other
- [ ] Both see portals
- [ ] Both queue at same portal
- [ ] Queue shows 2/8 players
- [ ] Countdown starts
- [ ] Both spawn on same map
- [ ] Wave 1 starts for both

### Late Joiner Test
- [ ] Match is in progress
- [ ] New player joins
- [ ] Title screen appears
- [ ] Player clicks continue
- [ ] Enters lobby (not active match)
- [ ] Can move and see portals
- [ ] Can queue for next match

### Config Flag Tests
- [ ] `USE_PORTAL_MATCHMAKING = false` → Map voting UI appears
- [ ] `INTRO_SHOW_EPILOGUE_ON_FIRST_JOIN = true` → Epilogue shows after title
- [ ] `INTRO_SHOW_EPILOGUE_ON_FIRST_JOIN = false` → Direct to lobby

## Related Files

### ✨ New Entry Points
- `ServerScriptService/Main.server.lua` - **NEW: Server entry point**
- `StarterPlayerScripts/ClientMain.client.lua` - **NEW: Client entry point**
- `ReplicatedStorage/Shared/Remotes/RemoteRegistry.lua` - **NEW: Remote management**

### Core Systems
- `ServerScriptService/GameManager.lua` - Main game state machine
- `ServerScriptService/PlayerSpawnManager.lua` - Player spawning logic
- `ServerScriptService/LobbySetup.lua` - Lobby and portal creation
- `ServerScriptService/PortalMatchmakingService.lua` - Portal queue system
- `ReplicatedStorage/Shared/GameConfig.lua` - Configuration flags

## Version History

- **v2.0** (2026-02-01) - Modern Luau Refactor
  - New entry points: Main.server.lua and ClientMain.client.lua
  - RemoteRegistry system for centralized remote management
  - Replaced all legacy patterns (wait/spawn/delay → task library)
  - Removed _G global usage
  - Phase-based boot logging with [BOOT][SERVER] and [BOOT][CLIENT]
  - Idempotent entry points with duplicate execution guards
  
- **v1.0** (2026-02-01) - Initial documentation after startup flow fix
  - Fixed map loading on boot
  - Fixed epilogue showing before lobby
  - Fixed player movement in lobby
  - Added comprehensive flow logging
  - Added INTRO_SHOW_EPILOGUE_ON_FIRST_JOIN config flag
