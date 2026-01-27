# Portal Matchmaking System Setup Guide

This guide explains how to enable and configure the new portal-based matchmaking system in AwavePuzz.

## Overview

The portal matchmaking system replaces the traditional map voting flow with physical portals in the lobby that players walk into to join queues. When enough players join a portal queue, a countdown begins and then launches a match for those players.

## Key Features

- **Server-Authoritative**: All matchmaking logic runs on the server for security
- **8 Players Per Match**: Each match instance is capped at 8 players
- **Multiple Portals**: Support for multiple portals running simultaneously
- **Specific or Random Maps**: Portals can be configured for specific maps or random selection
- **Queue Management**: Players can join/leave queues, see countdown timers
- **Overflow Handling**: If more than 8 players queue, they form subsequent matches

## Enabling Portal Matchmaking

### Step 1: Update GameConfig

Edit `/ReplicatedStorage/Shared/GameConfig.lua`:

```lua
-- Change this line from false to true:
GameConfig.USE_PORTAL_MATCHMAKING = true
```

### Step 2: Configure Portal Settings (Optional)

You can customize portal behavior in the same file:

```lua
GameConfig.PORTAL_MATCHMAKING = {
	MAX_PLAYERS_PER_MATCH = 8,        -- Maximum players per match instance
	DEFAULT_MIN_PLAYERS = 1,          -- Default minimum players to start countdown
	DEFAULT_COUNTDOWN_TIME = 10,      -- Default countdown seconds before match starts
	COUNTDOWN_CANCEL_THRESHOLD = 1,   -- Cancel countdown if queue drops below this
	POST_LAUNCH_COOLDOWN = 3,         -- Seconds to wait after launching before accepting new players
	TOUCH_DEBOUNCE_TIME = 0.5,        -- Seconds between processing touches from same player
	QUEUE_UPDATE_INTERVAL = 1,        -- Seconds between queue status broadcasts
}
```

### Step 3: Test in Roblox Studio

1. Open your place in Roblox Studio
2. Start a Local Server test with multiple players
3. You should see 3 portals in the lobby:
   - Research Outpost Portal (left)
   - Random Map Portal (center)
   - Village Portal (right)

## Portal Configuration

Portals are automatically created by `LobbySetup.lua` when `USE_PORTAL_MATCHMAKING` is enabled. They are placed in `Workspace.Lobby.Portals`.

Each portal has these attributes:
- `PortalId` (string): Unique identifier for the portal
- `MapId` (string): Map to load ("Random" for random selection)
- `MinPlayers` (number): Minimum players required to start countdown
- `CountdownSeconds` (number): How long the countdown lasts

### Adding Custom Portals

Edit `/ServerScriptService/LobbySetup.lua`, find the `createPortals` method:

```lua
-- Portal types to create
local portalTypes = {
	{ id = "ResearchOutpost", mapId = "ResearchOutpost", name = "Research Outpost" },
	{ id = "Random", mapId = "Random", name = "Random Map" },
	{ id = "Village", mapId = "Village", name = "Village" },
	-- Add more portals here:
	-- { id = "Dockyards", mapId = "Dockyards", name = "Dockyards" },
}
```

You'll also need to add positions for new portals:

```lua
local portalPositions = {
	Vector3.new(-20, 12, 0),  -- Left
	Vector3.new(0, 12, 0),    -- Center
	Vector3.new(20, 12, 0),   -- Right
	-- Add more positions for additional portals
	-- Vector3.new(-10, 12, 20),  -- Front-left
}
```

## How It Works

### Player Flow

1. **Join Lobby**: Player spawns in lobby, sees portals
2. **Touch Portal**: Player walks into a portal
3. **Queue Joined**: Player is added to portal queue, UI shows status
4. **Countdown**: When minimum players reached, countdown begins
5. **Match Launch**: When countdown ends, match starts with queued players
6. **Spawn on Map**: Only match players spawn on the selected map
7. **Play Round**: Standard wave-based gameplay
8. **Return to Lobby**: When match ends, players return to lobby

### Queue States

- **Ready**: Portal accepting players, waiting for minimum
- **Countdown**: Enough players, counting down to launch
- **Locked**: Match launching, no new players accepted
- **Cooldown**: Brief period after launch before accepting new players

### Overflow Behavior

If 10 players join a portal:
1. First 8 players form Match 1, countdown starts
2. When countdown ends, Match 1 launches
3. Remaining 2 players stay in queue
4. After cooldown, portal becomes ready again
5. When 6 more players join (total 8), Match 2 forms

## Client UI

When a player joins a portal queue, they see a UI at the bottom of the screen showing:
- Portal name and map
- Queue count (e.g., "3 / 8")
- Countdown timer (if active)
- Leave Queue button

The UI automatically hides when:
- Player leaves queue
- Match launches
- Portal queue is cancelled

## RemoteEvents

The system uses these RemoteEvents (created automatically):

**Server → Client:**
- `PortalQueueStatus`: Broadcast queue updates to all players
- `PortalQueueJoined`: Confirm player joined queue
- `PortalQueueLeft`: Notify player left queue

**Client → Server:**
- `PortalLeaveQueue`: Player requests to leave queue

## Architecture

### Key Components

1. **PortalMatchmakingService** (`ServerScriptService`)
   - Discovers and registers portals
   - Handles touch detection and queue management
   - Manages countdowns and match launching
   - Server-authoritative, no client trust

2. **MatchRegistry** (`ServerScriptService`)
   - Tracks active match instances
   - Maps players to matches
   - Handles match cleanup

3. **LobbySetup** (`ServerScriptService`)
   - Creates lobby area
   - Generates portal models (when enabled)
   - Cleanup on lobby reset

4. **PortalQueueUI** (`StarterPlayerScripts/Modules/UI`)
   - Client-side queue status display
   - Leave queue button
   - Auto-show/hide based on server events

5. **GameManager** (updated)
   - New `startMatch(players, mapId, matchId)` method
   - Spawns specific players for match
   - Match cleanup on round end

### Integration Points

The portal system integrates with existing systems:

- **MapManager**: Loads selected map
- **PlayerSpawnManager**: Spawns only match players
- **SpectatorManager**: Works with match-specific players
- **BaseManager, WaveManager**: Standard round flow

## Disabling Portal Matchmaking

To return to the traditional voting system:

1. Edit `GameConfig.lua`:
   ```lua
   GameConfig.USE_PORTAL_MATCHMAKING = false
   ```

2. Restart the game

The old lobby voting system will work as before. Portal code is not loaded when disabled.

## Troubleshooting

### Portals Not Appearing

1. Check `GameConfig.USE_PORTAL_MATCHMAKING` is `true`
2. Check Output for "[LobbySetup] Creating portals" message
3. Verify `Workspace.Lobby.Portals` folder exists

### Queue Not Starting

1. Verify portal has correct attributes (PortalId, MapId, MinPlayers)
2. Check if enough players in queue (>= MinPlayers)
3. Look for "[PortalMatchmakingService] Starting countdown" in Output

### Players Not Spawning on Map

1. Verify map exists in MapConfig and ServerStorage.Maps
2. Check "[GameManager] Starting match" appears in Output
3. Ensure PlayerSpawnManager has spawn points for the map

### Touch Not Working

1. Portals must have CanCollide = false on TouchPart
2. TouchPart must be a BasePart (not a Model)
3. Check debounce isn't blocking repeated touches

## Configuration Tips

### For Testing (Fast Matches)
```lua
DEFAULT_MIN_PLAYERS = 1,      -- Start with just 1 player
DEFAULT_COUNTDOWN_TIME = 5,   -- Short countdown
```

### For Production (Better Experience)
```lua
DEFAULT_MIN_PLAYERS = 2,      -- Wait for 2+ players
DEFAULT_COUNTDOWN_TIME = 10,  -- Give players time to join
```

### For High-Traffic Servers
```lua
MAX_PLAYERS_PER_MATCH = 8,        -- Keep at 8 for balance
POST_LAUNCH_COOLDOWN = 2,         -- Quick cooldown for next match
QUEUE_UPDATE_INTERVAL = 0.5,      -- More frequent updates
```

## Future Enhancements

Potential improvements you could add:

1. **Party System**: Allow friends to queue together
2. **Skill-Based Matching**: Match players of similar skill
3. **Map Voting in Queue**: Let queued players vote
4. **Portal Themes**: Visual customization per map
5. **Queue Priorities**: VIP players, etc.

## Support

For issues or questions:
1. Check Output window for error messages
2. Review this guide's Troubleshooting section
3. Check existing issues in the repository
4. Create a new issue with reproduction steps
