# Portal Matchmaking System API Reference

This document provides API reference for the portal matchmaking system components.

## PortalMatchmakingService

**Location:** `ServerScriptService/PortalMatchmakingService.lua`

### Constructor

```lua
PortalMatchmakingService.new(gameManager) -> PortalMatchmakingService
```

Creates a new portal matchmaking service instance.

**Parameters:**
- `gameManager` (GameManager): Reference to the game manager

**Returns:** PortalMatchmakingService instance

### Methods

#### discoverPortals

```lua
:discoverPortals() -> void
```

Discovers and registers all portals in `Workspace.Lobby.Portals`.

Called automatically during initialization.

#### registerPortal

```lua
:registerPortal(portalPart) -> boolean
```

Registers a single portal for matchmaking.

**Parameters:**
- `portalPart` (BasePart|Model): The portal part or model

**Returns:** `true` if successful, `false` otherwise

**Expected Attributes on portalPart:**
- `PortalId` (string): Unique portal identifier
- `MapId` (string): Map to load or "Random"
- `MinPlayers` (number, optional): Minimum players for countdown
- `CountdownSeconds` (number, optional): Countdown duration

#### onPortalTouched

```lua
:onPortalTouched(portalId, player) -> void
```

Handles when a player touches a portal. Called internally by touch events.

**Parameters:**
- `portalId` (string): ID of the portal touched
- `player` (Player): Player who touched the portal

#### addPlayerToQueue

```lua
:addPlayerToQueue(portalId, player) -> boolean
```

Adds a player to a portal queue.

**Parameters:**
- `portalId` (string): ID of the portal
- `player` (Player): Player to add

**Returns:** `true` if successfully added, `false` otherwise

**Fires RemoteEvent:**
- `PortalQueueJoined` to player if successful

#### removePlayerFromQueue

```lua
:removePlayerFromQueue(player, portalId?) -> void
```

Removes a player from a portal queue.

**Parameters:**
- `player` (Player): Player to remove
- `portalId` (string, optional): Specific portal ID, or auto-detect

**Fires RemoteEvent:**
- `PortalQueueLeft` to player

#### onPlayerLeaveQueue

```lua
:onPlayerLeaveQueue(player) -> void
```

Handles player explicitly leaving queue via RemoteEvent.

**Parameters:**
- `player` (Player): Player leaving queue

#### launchMatch

```lua
:launchMatch(portalId) -> void
```

Launches a match for a portal queue. Called automatically when countdown ends.

**Parameters:**
- `portalId` (string): ID of the portal

**Calls:** `GameManager:startMatch(players, mapId, matchId)`

#### endMatch

```lua
:endMatch(matchId) -> void
```

Ends a match and returns players to lobby.

**Parameters:**
- `matchId` (string): ID of the match to end

**Should be called by:** GameManager when match/round ends

#### onPlayerDisconnect

```lua
:onPlayerDisconnect(player) -> void
```

Handles player disconnect cleanup.

**Parameters:**
- `player` (Player): Player who disconnected

**Called by:** GameManager:onPlayerRemoving()

#### update

```lua
:update(deltaTime) -> void
```

Update function for periodic tasks (match cleanup, etc.).

**Parameters:**
- `deltaTime` (number): Time since last update

**Called by:** GameManager:update()

#### getMatchRegistry

```lua
:getMatchRegistry() -> MatchRegistry
```

Returns the match registry instance.

**Returns:** MatchRegistry

#### getPortalInfo

```lua
:getPortalInfo(portalId) -> table?
```

Gets information about a specific portal.

**Parameters:**
- `portalId` (string): ID of the portal

**Returns:** Table with portal info or `nil` if not found

```lua
{
	portalId = string,
	queueCount = number,
	countdown = number,
	locked = boolean,
	config = table
}
```

#### getAllPortalsInfo

```lua
:getAllPortalsInfo() -> table[]
```

Gets information about all registered portals.

**Returns:** Array of portal info tables

---

## MatchRegistry

**Location:** `ServerScriptService/MatchRegistry.lua`

### Constructor

```lua
MatchRegistry.new() -> MatchRegistry
```

Creates a new match registry instance.

**Returns:** MatchRegistry instance

### Methods

#### createMatch

```lua
:createMatch(players, mapId) -> string?
```

Creates a new match with the given players.

**Parameters:**
- `players` (Player[]): Array of players in the match
- `mapId` (string): Map ID for the match

**Returns:** Match ID string, or `nil` if failed

#### getPlayerMatch

```lua
:getPlayerMatch(player) -> string?
```

Gets the match ID for a player.

**Parameters:**
- `player` (Player): Player to check

**Returns:** Match ID or `nil`

#### getMatch

```lua
:getMatch(matchId) -> table?
```

Gets match data.

**Parameters:**
- `matchId` (string): Match ID

**Returns:** Match data table or `nil`

```lua
{
	players = Player[],
	mapId = string,
	startTime = number,
	active = boolean
}
```

#### isPlayerInMatch

```lua
:isPlayerInMatch(player) -> boolean
```

Checks if a player is in any match.

**Parameters:**
- `player` (Player): Player to check

**Returns:** `true` if in a match, `false` otherwise

#### removePlayerFromMatch

```lua
:removePlayerFromMatch(player) -> void
```

Removes a player from their current match.

**Parameters:**
- `player` (Player): Player to remove

#### endMatch

```lua
:endMatch(matchId) -> void
```

Ends a match and cleans up.

**Parameters:**
- `matchId` (string): Match ID to end

#### getMatchPlayers

```lua
:getMatchPlayers(matchId) -> Player[]
```

Gets all players in a match.

**Parameters:**
- `matchId` (string): Match ID

**Returns:** Array of players

#### getActiveMatches

```lua
:getActiveMatches() -> table[]
```

Gets all active matches.

**Returns:** Array of match info tables

```lua
{
	id = string,
	playerCount = number,
	mapId = string,
	startTime = number
}
```

#### cleanupInactiveMatches

```lua
:cleanupInactiveMatches() -> number
```

Cleans up inactive matches.

**Returns:** Number of matches cleaned up

#### getStats

```lua
:getStats() -> table
```

Gets registry statistics.

**Returns:** Stats table

```lua
{
	activeMatches = number,
	totalPlayers = number,
	totalMatchesCreated = number
}
```

---

## GameManager Extensions

**Location:** `ServerScriptService/GameManager.lua`

### New Methods

#### startMatch

```lua
:startMatch(players, mapId, matchId) -> boolean
```

Starts a match for specific players on a specific map.

**Parameters:**
- `players` (Player[]): Array of players for this match
- `mapId` (string): Map ID to load
- `matchId` (string): Match ID from MatchRegistry

**Returns:** `true` if successful, `false` otherwise

**Called by:** PortalMatchmakingService:launchMatch()

**Behavior:**
1. Validates inputs
2. Loads specified map
3. Spawns only the match players on map
4. Starts countdown to first wave
5. Stores matchId for cleanup

### Modified Methods

#### update

Now calls `portalMatchmakingService:update(deltaTime)` if portal matchmaking is enabled.

#### onPlayerRemoving

Now calls `portalMatchmakingService:onPlayerDisconnect(player)` if portal matchmaking is enabled.

#### _cleanupRoundResources

Now calls `portalMatchmakingService:endMatch(matchId)` if portal matchmaking is enabled and matchId exists.

---

## LobbySetup Extensions

**Location:** `ServerScriptService/LobbySetup.lua`

### New Methods

#### createPortals

```lua
:createPortals() -> void
```

Creates portal models in the lobby.

Called automatically by `createLobby()` if `GameConfig.USE_PORTAL_MATCHMAKING` is `true`.

**Creates:**
- `Workspace.Lobby.Portals` folder
- Portal models with touch parts and visual indicators

#### createPortal

```lua
:createPortal(portalId, mapId, displayName, position) -> Model
```

Creates a single portal model.

**Parameters:**
- `portalId` (string): Unique portal ID
- `mapId` (string): Map to load
- `displayName` (string): Display name for UI
- `position` (Vector3): World position for portal

**Returns:** Portal Model

**Portal Structure:**
```
Model (portalId)
├─ TouchPart (BasePart, CanCollide=false)
│  └─ QueueIndicator (BillboardGui)
│     ├─ TitleFrame
│     │  └─ TitleLabel (displayName)
│     └─ StatusLabel ("0/8", countdown, etc.)
└─ Frame (BasePart, visual border)

Attributes:
- PortalId: string
- MapId: string
- MinPlayers: number
- CountdownSeconds: number
```

### Modified Methods

#### cleanup

Now also removes `Workspace.Lobby.Portals` if it exists.

---

## PortalQueueUI (Client)

**Location:** `StarterPlayerScripts/Modules/UI/PortalQueueUI.lua`

### Methods

#### show

```lua
PortalQueueUI.show(portalId, mapId) -> void
```

Shows the queue UI for a portal.

**Parameters:**
- `portalId` (string): Portal ID
- `mapId` (string): Map ID

**Called by:** Server via `PortalQueueJoined` RemoteEvent

#### hide

```lua
PortalQueueUI.hide() -> void
```

Hides the queue UI.

**Called by:** 
- User clicking "Leave Queue" button
- Server via `PortalQueueLeft` RemoteEvent

#### updateStatus

```lua
PortalQueueUI.updateStatus(status) -> void
```

Updates queue status display.

**Parameters:**
- `status` (table): Status data from server

```lua
{
	portalId = string,
	queueCount = number,
	maxPlayers = number,
	countdown = number?,
	status = "ready" | "countdown" | "locked" | "full"
}
```

**Called by:** Server via `PortalQueueStatus` RemoteEvent

#### initialize

```lua
PortalQueueUI.initialize() -> void
```

Initializes the UI module.

**Called by:** ClientController automatically

---

## RemoteEvents

### PortalQueueStatus

**Direction:** Server → All Clients

**Data Structure:**
```lua
{
	portalId = string,
	queueCount = number,
	maxPlayers = number,
	countdown = number?,
	locked = boolean,
	mapId = string,
	status = "ready" | "countdown" | "locked" | "full"
}
```

**Purpose:** Broadcast portal queue updates to all clients for UI updates.

### PortalQueueJoined

**Direction:** Server → Client

**Data Structure:**
```lua
{
	portalId = string,
	mapId = string,
	queueCount = number,
	maxPlayers = number
}
```

**Purpose:** Confirm to a player they successfully joined a queue.

### PortalQueueLeft

**Direction:** Server → Client

**Data Structure:**
```lua
{
	portalId = string
}
```

**Purpose:** Notify a player they left a queue.

### PortalLeaveQueue

**Direction:** Client → Server

**Data:** None (player is identified from event sender)

**Purpose:** Player requests to leave their current queue.

---

## Configuration Reference

### GameConfig.PORTAL_MATCHMAKING

```lua
{
	MAX_PLAYERS_PER_MATCH = 8,        -- Maximum players per match instance
	DEFAULT_MIN_PLAYERS = 1,          -- Default minimum players to start countdown
	DEFAULT_COUNTDOWN_TIME = 10,      -- Default countdown seconds
	COUNTDOWN_CANCEL_THRESHOLD = 1,   -- Cancel countdown if queue drops below this
	POST_LAUNCH_COOLDOWN = 3,         -- Cooldown after launching (seconds)
	TOUCH_DEBOUNCE_TIME = 0.5,        -- Touch debounce (seconds)
	QUEUE_UPDATE_INTERVAL = 1,        -- Queue broadcast interval (seconds)
}
```

### GameConfig.USE_PORTAL_MATCHMAKING

**Type:** boolean

**Default:** `false`

**Purpose:** Feature flag to enable portal matchmaking system. When `false`, the traditional voting system is used.

---

## State Machine

### Portal States

```
READY → COUNTDOWN → LOCKED → COOLDOWN → READY
  ↑                                         ↓
  └─────────── CANCELLED ←──────────────────┘
```

**READY:**
- Accepting players into queue
- Waiting for minimum players

**COUNTDOWN:**
- Enough players joined
- Countdown timer running
- Can cancel if players leave

**LOCKED:**
- Match is launching
- No new players accepted
- Current queue being processed

**COOLDOWN:**
- Brief period after launch
- Prevents immediate re-queue
- Queue cleared

**CANCELLED:**
- Queue dropped below threshold during countdown
- Returns to READY

### Match States

```
CREATED → ACTIVE → ENDED
```

**CREATED:**
- Match registered in MatchRegistry
- Players assigned to match
- Map not yet loaded

**ACTIVE:**
- Map loaded
- Players spawned
- Round in progress

**ENDED:**
- Round completed (victory/defeat)
- Players returned to lobby
- Match cleaned up from registry

---

## Error Handling

### Common Errors

**Portal Registration Failed:**
```
[PortalMatchmakingService] Portal part <name> has no PortalId
```
- Add `PortalId` attribute to portal part

**Match Creation Failed:**
```
[MatchRegistry] Cannot create match with no players
```
- Internal error, check queue processing

**Map Load Failed:**
```
[GameManager] startMatch: Failed to load map <mapId>
```
- Verify map exists in MapConfig and ServerStorage

### Validation Checks

The system validates:
- Player exists and is in game
- Portal exists and is registered
- Map ID is valid
- Queue not full before adding player
- Match not already exists for player
- Minimum player threshold met for countdown

---

## Performance Considerations

### Optimizations

1. **Touch Debouncing:** Prevents spam from rapid touches
2. **Countdown in Separate Task:** Non-blocking countdown execution
3. **Cached Spawn Points:** MapManager caches spawn points per map
4. **Broadcast Throttling:** Queue updates limited to 1Hz by default

### Scalability

- **Multiple Portals:** Each portal has independent queue and countdown
- **Concurrent Matches:** System supports multiple active matches simultaneously
- **Match Cleanup:** Inactive matches automatically cleaned up

### Memory Management

- **Connection Cleanup:** Touch connections managed by service
- **Match Cleanup:** Ended matches removed from registry
- **Portal Cleanup:** Portals destroyed when lobby is cleaned up

---

## Integration Examples

### Adding a New Map Portal

```lua
-- In LobbySetup.lua, createPortals() method:
local portalTypes = {
	{ id = "MyNewMap", mapId = "MyNewMap", name = "My New Map" },
	-- ... existing portals
}

-- Don't forget to add position:
local portalPositions = {
	Vector3.new(-30, 12, 0),  -- Position for new portal
	-- ... existing positions
}
```

### Custom Portal Per-Portal Settings

```lua
-- After creating portal in createPortal():
portal:SetAttribute("MinPlayers", 4)  -- Require 4 players
portal:SetAttribute("CountdownSeconds", 15)  -- 15 second countdown
```

### Handling Match Events

```lua
-- In your custom module:
local portalService = gameManager.portalMatchmakingService
if portalService then
	local registry = portalService:getMatchRegistry()
	local stats = registry:getStats()
	print("Active matches:", stats.activeMatches)
end
```
