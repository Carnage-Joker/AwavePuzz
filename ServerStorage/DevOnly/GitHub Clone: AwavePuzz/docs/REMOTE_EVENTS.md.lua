-- @ScriptType: Script
# RemoteEvents Reference

This document lists all RemoteEvents used in AwavePuzz for client-server communication.

**📖 For a complete documentation index, see [DOCUMENTATION.md](../DOCUMENTATION.md)**

## Overview

All RemoteEvents are stored in `ReplicatedStorage/RemoteEvents/` and created using the `RemoteEventUtil` shared module.

### Naming Convention
- **PascalCase** with descriptive, action-oriented names
- Names should indicate the action or data being communicated
- Avoid generic names like "RemoteEvent1", "Event", "Update"

### Direction Notation
- **Client → Server**: Client sends request/data to server
- **Server → Client**: Server sends update/command to client
- **Bidirectional**: Used in both directions (rare, should be avoided)

## RemoteEvent List

### Game Management

#### WaveAnnounce
- **Direction**: Server → Client
- **Purpose**: Announces the start of a new wave
- **Payload**: `{ wave = number }`
- **Used By**: GameManager

#### WaveUpdate
- **Direction**: Server → Client
- **Purpose**: Updates wave status information
- **Payload**: `{ zombiesRemaining = number, timeRemaining = number }`
- **Used By**: GameManager

#### GameStateUpdate
- **Direction**: Server → Client
- **Purpose**: Updates overall game state
- **Payload**: `{ state = string, data = table }`
- **Used By**: GameManager

#### MapUpdate
- **Direction**: Server → Client
- **Purpose**: Sends map information to client
- **Payload**: `{ mapId = string, mapName = string }`
- **Used By**: GameManager

### Base & Cure System

#### BaseHealthUpdate
- **Direction**: Server → Client
- **Purpose**: Updates base health status
- **Payload**: `{ health = number, maxHealth = number }`
- **Used By**: GameManager, BaseManager

#### CureUpdate
- **Direction**: Server → Client
- **Purpose**: Updates cure progress percentage
- **Payload**: `{ progress = number }`
- **Used By**: GameManager, CureService

#### PlayerCureProgressUpdate
- **Direction**: Server → Client
- **Purpose**: Updates individual player's cure component collection
- **Payload**: `{ components = table }`
- **Used By**: CureService

### Puzzle System

#### RequestPuzzle
- **Direction**: Client → Server
- **Purpose**: Player requests to start a puzzle
- **Payload**: `{ componentName = string }`
- **Used By**: PuzzleService

#### SubmitPuzzleAnswer
- **Direction**: Client → Server
- **Purpose**: Player submits puzzle solution
- **Payload**: `{ componentName = string, answer = any }`
- **Used By**: PuzzleService

#### PuzzleUpdate
- **Direction**: Server → Client
- **Purpose**: Sends puzzle state updates
- **Payload**: `{ componentName = string, state = table }`
- **Used By**: PuzzleService

#### PuzzleFailed
- **Direction**: Server → Client
- **Purpose**: Notifies puzzle failure
- **Payload**: `{ componentName = string, reason = string }`
- **Used By**: PuzzleService

#### PuzzleCompleted
- **Direction**: Server → Client
- **Purpose**: Notifies puzzle completion
- **Payload**: `{ componentName = string, reward = table }`
- **Used By**: PuzzleService

#### OpenPuzzleUI
- **Direction**: Server → Client
- **Purpose**: Tells client to open puzzle UI
- **Payload**: `{ componentName = string, puzzleData = table }`
- **Used By**: PuzzleService

#### RequestPuzzleProgress
- **Direction**: Client → Server
- **Purpose**: Requests puzzle progress data
- **Payload**: None
- **Used By**: PuzzleService

### Weapon System

#### WeaponFire
- **Direction**: Client → Server
- **Purpose**: Player fires weapon
- **Payload**: `{ origin = Vector3, direction = Vector3, weaponId = string }`
- **Used By**: WeaponService

#### WeaponEquip
- **Direction**: Client → Server
- **Purpose**: Player requests to equip weapon
- **Payload**: `{ weaponId = string }`
- **Used By**: WeaponService

#### WeaponHitConfirm
- **Direction**: Server → Client
- **Purpose**: Confirms hit on target for visual feedback
- **Payload**: `{ hitPosition = Vector3, damage = number }`
- **Used By**: WeaponService

#### WeaponReload
- **Direction**: Client → Server
- **Purpose**: Player reloads weapon
- **Payload**: `{ weaponId = string }`
- **Used By**: FPSWeaponService

#### AmmoUpdate
- **Direction**: Server → Client
- **Purpose**: Updates player's ammo count
- **Payload**: `{ weaponId = string, current = number, reserve = number, max = number }`
- **Used By**: FPSWeaponService

### Player Management

#### InventoryUpdate
- **Direction**: Server → Client
- **Purpose**: Updates player's inventory
- **Payload**: `{ items = table }`
- **Used By**: PlayerManager

#### CurrencyUpdate
- **Direction**: Server → Client
- **Purpose**: Updates player's currency balance
- **Payload**: `{ amount = number }`
- **Used By**: PlayerManager

#### WeaponLoadoutUpdate
- **Direction**: Server → Client
- **Purpose**: Updates player's weapon loadout
- **Payload**: `{ weapons = table }`
- **Used By**: PlayerManager

#### PlayerHealthUpdate
- **Direction**: Server → Client
- **Purpose**: Updates player's health
- **Payload**: `{ health = number, maxHealth = number }`
- **Used By**: PlayerManager

### Alliance System

#### RequestAlliance
- **Direction**: Client → Server
- **Purpose**: Request alliance with another player
- **Payload**: `{ targetPlayer = Player }`
- **Used By**: AllianceService

#### RespondAlliance
- **Direction**: Client → Server
- **Purpose**: Respond to alliance request
- **Payload**: `{ requesterPlayer = Player, accept = boolean }`
- **Used By**: AllianceService

#### BreakAlliance
- **Direction**: Client → Server
- **Purpose**: Break existing alliance
- **Payload**: `{ targetPlayer = Player }`
- **Used By**: AllianceService

#### AllianceUpdate
- **Direction**: Server → Client
- **Purpose**: Updates alliance status
- **Payload**: `{ allies = table, status = string }`
- **Used By**: AllianceService

### Shop System

#### ShopRequest
- **Direction**: Client → Server
- **Purpose**: Request shop action (purchase, view catalog)
- **Payload**: `{ action = string, data = table }`
- **Valid Actions**: "catalog", "purchase", "upgrade"
- **Used By**: ShopService

#### ShopUpdate
- **Direction**: Server → Client
- **Purpose**: Updates shop catalog or purchase result
- **Payload**: `{ success = boolean, message = string, data = table }`
- **Used By**: ShopService

### Lobby & Map Voting

#### MapVoteStart
- **Direction**: Server → Client
- **Purpose**: Voting has started, send map options
- **Payload**: `{ maps = table, duration = number }`
- **Used By**: LobbyManager

#### MapVoteUpdate
- **Direction**: Server → Client
- **Purpose**: Update vote counts
- **Payload**: `{ votes = table }`
- **Used By**: LobbyManager

#### MapVoteEnd
- **Direction**: Server → Client
- **Purpose**: Voting ended, show selected map
- **Payload**: `{ selectedMapId = string, mapName = string }`
- **Used By**: LobbyManager

#### CastMapVote
- **Direction**: Client → Server
- **Purpose**: Player casts a vote
- **Payload**: `{ mapId = string }`
- **Used By**: LobbyManager

#### LobbyStateUpdate
- **Direction**: Server → Client
- **Purpose**: Update lobby state (timer, player count)
- **Payload**: `{ state = string, timeRemaining = number, playerCount = number }`
- **Used By**: LobbyManager

### Spectator System

#### EnterSpectatorMode
- **Direction**: Server → Client
- **Purpose**: Player enters spectator mode
- **Payload**: `{ targetPlayer = Player }`
- **Used By**: SpectatorManager

#### ExitSpectatorMode
- **Direction**: Server → Client
- **Purpose**: Player exits spectator mode
- **Payload**: None
- **Used By**: SpectatorManager

#### SpectatorTargetUpdate
- **Direction**: Server → Client
- **Purpose**: Updates spectator camera target
- **Payload**: `{ targetPlayer = Player }`
- **Used By**: SpectatorManager

#### SpectatorCycleTarget
- **Direction**: Client → Server
- **Purpose**: Request to cycle spectator target
- **Payload**: `{ direction = string }` ("next" or "prev")
- **Used By**: SpectatorManager

#### SpectatorStateUpdate
- **Direction**: Server → Client
- **Purpose**: Updates spectator state
- **Payload**: `{ isSpectating = boolean, target = Player }`
- **Used By**: SpectatorManager

### Scoreboard

#### ScoreboardUpdate
- **Direction**: Server → Client
- **Purpose**: Updates scoreboard data
- **Payload**: `{ players = table }`
- **Format**: `players = { { name = string, kills = number, deaths = number, score = number }, ... }`
- **Used By**: GameManager

#### ShowScoreboard
- **Direction**: Server → Client
- **Purpose**: Signals to display scoreboard
- **Payload**: None
- **Used By**: GameManager

#### HideScoreboard
- **Direction**: Server → Client
- **Purpose**: Signals to hide scoreboard
- **Payload**: None
- **Used By**: GameManager

### Sprint System

#### SprintStart
- **Direction**: Client → Server
- **Purpose**: Player starts sprinting
- **Payload**: None
- **Used By**: SprintService

#### SprintStop
- **Direction**: Client → Server
- **Purpose**: Player stops sprinting
- **Payload**: None
- **Used By**: SprintService

#### StaminaUpdate
- **Direction**: Server → Client
- **Purpose**: Updates player's stamina
- **Payload**: `{ stamina = number, maxStamina = number }`
- **Used By**: SprintService

## Usage Guidelines

### Creating RemoteEvents

Always use `RemoteEventUtil` to create events:

```lua
local RemoteEventUtil = require(ReplicatedStorage.Shared.RemoteEventUtil)

local events = RemoteEventUtil.getOrCreateEvents({
    "EventName1",
    "EventName2",
    "EventName3"
})
```

### Documenting RemoteEvents

When setting up RemoteEvents in a service, add clear documentation:

```lua
function ServiceName:setupRemoteEvents()
    -- RemoteEvent Documentation:
    -- - EventName1: Client -> Server, description {payload structure}
    -- - EventName2: Server -> Client, description {payload structure}
    self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
        "EventName1",
        "EventName2"
    })
    
    -- Connect handlers
    self.remoteEvents.EventName1.OnServerEvent:Connect(function(player, data)
        -- Handle event
    end)
end
```

### Client-Side Listening

```lua
local RemoteEventUtil = require(ReplicatedStorage.Shared.RemoteEventUtil)
local event = RemoteEventUtil.waitForEvent("EventName")

event.OnClientEvent:Connect(function(data)
    -- Handle server update
end)
```

### Server-Side Firing

```lua
-- Fire to all clients
self.remoteEvents.EventName:FireAllClients(data)

-- Fire to specific client
self.remoteEvents.EventName:FireClient(player, data)
```

## Security Considerations

### Server Validation
**Always validate client input on the server:**

```lua
self.remoteEvents.ClientAction.OnServerEvent:Connect(function(player, data)
    -- Validate player
    if not player or not player.Character then return end
    
    -- Validate data type
    if typeof(data) ~= "table" then return end
    
    -- Validate data contents
    if not data.requiredField then return end
    
    -- Process validated data
    self:handleAction(player, data)
end)
```

### Rate Limiting
Implement cooldowns for frequently-fired events:

```lua
local lastFire = {}

self.remoteEvents.FrequentAction.OnServerEvent:Connect(function(player, data)
    local userId = player.UserId
    local now = os.clock()
    
    if lastFire[userId] and now - lastFire[userId] < COOLDOWN then
        return -- Reject rapid fire
    end
    
    lastFire[userId] = now
    -- Process action
end)
```

### Sanity Checks
- Check ranges for numeric values
- Validate string lengths
- Verify player permissions
- Check game state before processing

## Maintenance

When adding new RemoteEvents:

1. ✅ Choose a descriptive, PascalCase name
2. ✅ Document direction and payload in service code
3. ✅ Update this document with the new event
4. ✅ Add validation on server-side handlers
5. ✅ Test both client and server behavior

## Related Documentation

- [STRUCTURE.md](./STRUCTURE.md) - Project structure guide
- [API_DOCUMENTATION.md](../API_DOCUMENTATION.md) - Full API reference
- [CODE_ARCHITECTURE.md](../CODE_ARCHITECTURE.md) - Architecture overview
