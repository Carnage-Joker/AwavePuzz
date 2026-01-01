# Map Position and Lobby Improvements Implementation

## Overview

This update implements two key improvements to AwavePuzz:
1. Maps now load at position (5000, 0, 0) instead of the origin
2. Enhanced lobby system with better matchmaking features

## Changes Made

### 1. Map Positioning at (5000, 0, 0)

**File: `ServerScriptService/MapManager.lua`**

Maps are now positioned at (5000, 0, 0) to keep them separate from the spawn area and prevent any conflicts.

**Implementation:**
- When a map is cloned and loaded, it's automatically positioned at the offset
- Handles both models with PrimaryPart and models without (moves all parts individually)
- All spawn points (zombie, resource, item) are extracted at the new position
- BaseCampSetup automatically creates the base camp at the correct location since it calculates center from spawn points

**Code changes:**
```lua
-- Position the map at (5000, 0, 0) to keep it separate from spawn area
if self.currentMapModel.PrimaryPart then
    self.currentMapModel:SetPrimaryPartCFrame(CFrame.new(5000, 0, 0))
else
    -- If no PrimaryPart, move all parts
    local mapOffset = Vector3.new(5000, 0, 0)
    for _, descendant in ipairs(self.currentMapModel:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CFrame = descendant.CFrame + mapOffset
        end
    end
end
```

### 2. Enhanced Lobby System

#### A. Server-Side: LobbyManager Updates

**File: `ServerScriptService/LobbyManager.lua`**

**New Features:**
- Player ready status tracking
- Player waiting-for-friends status tracking
- Automatic timer extension when players are waiting
- Server switching via TeleportService
- Player status broadcasting

**New State Variables:**
```lua
self.playersReady = {}      -- userId -> boolean
self.playersWaiting = {}    -- userId -> boolean
self.extendedTimer = false  -- Timer extension flag
```

**New Remote Events:**
- `PlayerReady` - Client → Server: Player marks ready
- `PlayerWaiting` - Client → Server: Player waiting for friends
- `SwitchServer` - Client → Server: Request server switch
- `LobbyPlayersUpdate` - Server → Client: Broadcast player status

**Key Functions:**
- `handlePlayerReady(player)` - Mark player as ready
- `handlePlayerWaiting(player, isWaiting)` - Handle waiting status, extends timer
- `handleServerSwitch(player)` - Teleport player to different server
- `broadcastPlayerStatus()` - Send status update to all clients

#### B. Client-Side: New LobbyUI

**File: `StarterPlayer/StarterPlayerScripts/Modules/UI/LobbyUI.lua`**

**Features:**
- Clean, modern UI design with animations
- Shows total players, ready count, and waiting count
- Three main buttons:
  1. **"I'M READY"** - Toggle ready status
  2. **"WAITING FOR FRIENDS"** - Toggle waiting status
  3. **"SWITCH SERVER"** - Find a different server
- Dynamic status messages that update based on player state
- Smooth slide-in/slide-out animations
- Hover effects on buttons

**UI Layout:**
```
┌─────────────────────────────┐
│ LOBBY                       │
│ Players: 4 (2 ready, 1 waiting)
│ Vote for a map to begin!    │
│                             │
│ ┌───────────────────────┐   │
│ │    I'M READY          │   │
│ └───────────────────────┘   │
│                             │
│ ┌───────────────────────┐   │
│ │ WAITING FOR FRIENDS   │   │
│ └───────────────────────┘   │
│                             │
│ ┌───────────────────────┐   │
│ │   SWITCH SERVER       │   │
│ └───────────────────────┘   │
└─────────────────────────────┘
```

**Status Messages:**
- "Waiting for more players to join..." (< 2 players)
- "X player(s) waiting for friends" (when someone is waiting)
- "All players ready! Game starting soon..." (all ready)
- "Vote for a map to begin!" (normal state)

#### C. Client Integration

**File: `StarterPlayer/StarterPlayerScripts/ClientController.client.lua`**

Added "LobbyUI" to the list of UI modules to be initialized on client startup.

## How It Works

### Ready/Waiting System

1. **Player marks ready:**
   - Click "I'M READY" button
   - Client fires `PlayerReady` event to server
   - Server updates `playersReady[userId] = true`
   - Server broadcasts status to all clients
   - Button changes to "✓ READY" with green color

2. **Player indicates waiting:**
   - Click "WAITING FOR FRIENDS" button
   - Client fires `PlayerWaiting` event with `true`
   - Server updates `playersWaiting[userId] = true`
   - If lobby timer is active and hasn't been extended, extends it
   - Server broadcasts status to all clients
   - Button changes to "⏱ WAITING FOR FRIENDS" with orange color

3. **Timer Extension:**
   - First player to mark "waiting" extends the lobby voting timer
   - Timer is extended to at least `LOBBY_VOTING_TIME` (20 seconds default)
   - Only extends once per lobby session (via `extendedTimer` flag)
   - Gives friends time to join before game starts

### Server Switching

1. Player clicks "SWITCH SERVER" button
2. Client fires `SwitchServer` event to server
3. Server uses `TeleportService:Teleport(placeId, player)` to move player to a different server
4. Player leaves current server and joins a random public server of the same game

### Status Broadcasting

- Server tracks all players' ready/waiting status
- When status changes, broadcasts update to all clients via `LobbyPlayersUpdate`
- Clients receive update and refresh UI display
- Shows: total players, ready count, waiting count, individual player statuses

## Benefits

### Map Positioning Benefits:
1. **Separation** - Maps are isolated from default spawn area
2. **Consistency** - All maps load at the same offset position
3. **Predictability** - Easier to debug and understand map placement
4. **No conflicts** - Avoids overlap with workspace objects at origin

### Lobby System Benefits:
1. **Better matchmaking** - Players can wait for friends without timer rushing
2. **Player agency** - Clear ready status shows who wants to start
3. **Flexibility** - Server switching allows finding better matches
4. **Social** - Waiting indicator shows intent to play with friends
5. **Transparency** - All players see who is ready/waiting

## Configuration

### GameConfig Settings Used:

```lua
GameConfig.LOBBY_VOTING_TIME = 20  -- Base voting duration
GameConfig.LOBBY_MIN_PLAYERS = 1   -- Minimum players to start
```

### How to Adjust:

**Increase wait time for friends:**
Change `LOBBY_VOTING_TIME` in `GameConfig.lua` to give more base time.

**Disable timer extension:**
Remove timer extension logic from `handlePlayerWaiting()` if you want strict timing.

**Customize UI appearance:**
Edit colors, sizes, and positions in `LobbyUI.lua` (lines 20-140).

## Testing Recommendations

1. **Map Position:**
   - Load game in Roblox Studio
   - Check that map appears at (5000, 0, 0) in workspace
   - Verify spawn points work correctly
   - Confirm base camp is created at map center

2. **Lobby Ready System:**
   - Test with 2+ players
   - Click "I'M READY" and verify button changes
   - Check that all clients see updated status
   - Verify ready count increments

3. **Waiting System:**
   - Click "WAITING FOR FRIENDS"
   - Verify timer extends (check console logs)
   - Confirm button shows waiting status
   - Test with multiple players waiting

4. **Server Switch:**
   - Click "SWITCH SERVER" button
   - Verify player is teleported to different server
   - Check that error handling works if teleport fails

## Known Limitations

1. **Server Switch Requires Published Game:**
   - TeleportService only works in published games
   - Will not work in Studio test mode
   - Players will see error in Studio but won't crash

2. **Timer Extension Once:**
   - Timer only extends once per lobby session
   - If timer expires, game starts regardless of waiting status
   - This prevents indefinite waiting

3. **No Server List:**
   - Players switch to random public servers
   - Cannot choose specific server or join friends directly
   - Roblox API limitation

## Future Enhancements

Possible improvements:
1. Show friend list and let players invite friends
2. Display server info (player count, ping) before switching
3. Allow party/group creation before switching servers
4. Add "kick" or "vote to start" for ready majority
5. Show estimated wait time for friends
6. Add quick chat messages in lobby
7. Allow map voting while waiting

## Files Modified

1. `ServerScriptService/MapManager.lua` - Map positioning
2. `ServerScriptService/LobbyManager.lua` - Ready/waiting system
3. `StarterPlayer/StarterPlayerScripts/Modules/UI/LobbyUI.lua` - New UI (created)
4. `StarterPlayer/StarterPlayerScripts/ClientController.client.lua` - UI registration

## Backwards Compatibility

- All changes are additive
- Existing gameplay systems unchanged
- Remote events are new additions
- UI is optional enhancement
- Map positioning transparent to gameplay

---

**Implementation Date:** January 1, 2026
**Status:** Complete - Ready for testing
