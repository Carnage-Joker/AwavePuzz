# Flow and Security Architecture

This document describes the authoritative state sources, exploit mitigations, and how portal matchmaking and lobby voting are mutually exclusive in the AwavePuzz game.

## Table of Contents
- [Authoritative State Sources](#authoritative-state-sources)
- [Exploit Mitigations](#exploit-mitigations)
- [Portal Matchmaking vs Lobby Voting](#portal-matchmaking-vs-lobby-voting)
- [Security Best Practices](#security-best-practices)

## Authoritative State Sources

### SessionState Module (Single Source of Truth)

**Location**: `ServerScriptService/SessionState.lua`

The SessionState module is the single, authoritative source for tracking player context across all game systems:

```lua
PlayerContext = {
    passedTitle: bool,      -- Has player passed title screen?
    inQueue: bool,          -- Is player in a portal queue?
    portalId: string?,      -- Which portal queue (if any)?
    inMatch: bool,          -- Is player in an active match?
    matchId: string?,       -- Which match (if any)?
    isParticipant: bool,    -- Is player an active participant (affects game logic)?
}
```

**Key Operations**:
- `getPlayerContext(player)` - Get current player context
- `setPassedTitle(player, bool)` - Mark title screen passage
- `setQueued(player, portalId)` - Set queue state
- `setMatch(player, matchId, participant)` - Set match state
- `onPlayerRemoving(player)` - Cleanup on disconnect

**Integration Points**:
- GameManager uses SessionState for state snapshots and effective state determination
- PortalMatchmakingService updates SessionState when players join/leave queues
- MatchRegistry tracks match membership, but SessionState is the consolidated view

### Player Health Authority

**Location**: `ServerScriptService/PlayerManager.lua`

Player health uses a dual-sync system with internal state as the authoritative source:

- **Internal State**: `playerData.health` (game state, authoritative)
- **Humanoid Sync**: Humanoid.Health is synced from internal state
- **External Changes**: Detected via HealthChanged listener and applied to internal state
- **Recursion Prevention**: `_syncingHumanoid` flag prevents infinite loops

**Security Rules**:
1. Health is always clamped to `[0, GameConfig.STARTING_HEALTH]`
2. Dead players (`isAlive = false`) cannot be healed
3. External healing is only allowed for alive players
4. Server is the sole authority for health changes

### Weapon State Authority

**Location**: `ServerScriptService/WeaponService.lua`

Weapon firing is fully server-authoritative:

- **Equipped Weapon**: Server determines equipped weapon (ignores client payload)
- **Ammo**: Server validates and consumes ammo via FPSWeaponService
- **Fire Rate**: Server enforces both weapon-specific and hard-cap fire rates
- **Hit Detection**: Server performs all raycasts and damage application

### Match State Authority

**Location**: `ServerScriptService/MatchRegistry.lua` + SessionState

Match membership is tracked in multiple layers:

1. **MatchRegistry**: Authoritative for match membership
   - `activeMatches[matchId]` - Match data
   - `playerToMatch[userId]` - Player → Match mapping
   
2. **SessionState**: Consolidated view of match context
   - Includes participant status for game logic isolation
   
3. **GameManager**: Tracks match participants for round logic
   - `_matchParticipants[userId]` - Participants in current round
   - Only participants affect victory/defeat conditions
   - Only participants receive wave rewards

## Exploit Mitigations

### 1. Remote Spam Prevention

**Problem**: Clients could spam remote events to bypass rate limits, gain currency, or crash the server.

**Mitigation**:

#### WeaponService (Fire Rate)
```lua
-- Per-player rate limiting window
fireRateLimit[userId] = {
    count = number,      -- Fires in current window
    windowStart = tick() -- Window start time
}

-- Max 20 fires per second
if rateLimitData.count > MAX_FIRES_PER_WINDOW then
    warn("Rate limit exceeded")
    return
end

-- Hard cap minimum fire delay (0.05s)
-- Prevents config exploits
if timeSinceLastShot < MINIMUM_FIRE_DELAY then
    return
end
```

#### PortalMatchmakingService (Queue Leave)
```lua
-- Rate limit: 0.5s cooldown per player
remoteRateLimits[userId] = lastCallTime

if (now - lastCall) < 0.5 then
    warn("Rate limit exceeded")
    return
end

-- Validate player is actually queued
if not playerQueues[userId] then
    warn("Not queued, ignoring request")
    return
end
```

### 2. Weapon Firing Exploits

**Problems**:
- Shooting through walls (wallhack)
- Shooting backwards
- Spoofing origin position
- Shooting faster than intended
- Bypassing ammo

**Mitigations**:

#### Server-Authoritative Weapon ID
```lua
-- Ignore client payload, use server truth
local equipped = playerManager:getEquippedWeapon(player)
local weaponId = equipped -- Server decides, not client
```

#### Origin Validation
```lua
-- 1. Distance check (max 15 studs from player)
if distanceFromPlayer > maxDistance then
    return -- Too far
end

-- 2. Behind-player check (local space Z)
local localOffset = hrpCFrame:PointToObjectSpace(origin)
if localOffset.Z < -3 then
    return -- Origin behind player
end

-- 3. Vertical offset check
if math.abs(localOffset.Y) > 10 then
    return -- Origin too high/low
end
```

#### Direction Validation
```lua
-- Dot product with HumanoidRootPart LookVector
local dotProduct = direction:Dot(referenceVector)

-- Minimum 0.7 (≈45° cone, forward only)
if dotProduct < 0.7 then
    return -- Not facing target
end
```

#### Line-of-Sight Validation
```lua
-- 1. LOS from head to origin
local losResult = Workspace:Raycast(head.Position, origin - head.Position, params)
if losResult and losResult.Distance < actualDistance - 1 then
    return -- Origin blocked by wall
end

-- 2. LOS from head to hit position
local hitLosResult = Workspace:Raycast(head.Position, hitPosition - head.Position, params)
if hitLosResult and hitLosResult.Instance ~= targetInstance then
    return -- Hit position blocked
end
```

#### Ammo Authority
```lua
-- Server validates and consumes ammo
if not fpsWeaponService:validateShot(player, weaponId) then
    return -- No ammo
end

if not fpsWeaponService:consumeAmmo(player, weaponId, 1) then
    return -- Failed to consume
end
```

### 3. Health Sync Exploits

**Problems**:
- Healing while dead
- Health desync loops
- Setting health from client

**Mitigations**:

#### Recursion Prevention
```lua
-- Flag to prevent infinite loops
playerData._syncingHumanoid = true
humanoid.Health = newValue
playerData._syncingHumanoid = false

-- In HealthChanged listener
if playerData._syncingHumanoid then
    return -- Ignore our own changes
end
```

#### Dead Player Protection
```lua
if healthDelta > 0 then -- Healing
    if playerData.isAlive then
        -- Allow healing for alive players only
        playerData.health = math.min(MAX_HEALTH, newHealth)
    else
        -- SECURITY: Dead players stay dead
        humanoid.Health = 0
    end
end
```

#### Health Clamping
```lua
-- Always clamp to valid range
playerData.health = math.clamp(newHealth, 0, GameConfig.STARTING_HEALTH)
```

### 4. Queue Corruption

**Problems**:
- Duplicate players in queue
- Ghost players in queue (left but still counted)
- Countdown desync
- Locked portals after failed launch

**Mitigations**:

#### Atomic Operations
```lua
-- Check-and-set in one operation
for _, queuedPlayer in ipairs(portal.queue) do
    if queuedPlayer.UserId == player.UserId then
        return false -- Already queued
    end
end

table.insert(portal.queue, player)
playerQueues[userId] = { portalId = portalId }
sessionState:setQueued(player, portalId)
```

#### Periodic Validation
```lua
-- Every 2 seconds per portal
function validatePortalQueue(portalId)
    -- Remove players who:
    -- - Left game
    -- - Have no character
    -- - Are already in a match
    
    for i = #toRemove, 1, -1 do
        -- Remove invalid players
    end
end
```

#### Countdown Consistency
```lua
-- Use same threshold everywhere
local effectiveCancelThreshold = math.min(
    portal.config.minPlayers,
    self.countdownCancelThreshold
)

-- Cancel if below threshold
if #portal.queue < effectiveCancelThreshold then
    portal.countdown = 0
end
```

#### Rollback on Failure
```lua
-- If match launch fails, restore queue
if not success then
    portal.locked = false
    for _, player in ipairs(matchPlayers) do
        table.insert(portal.queue, player)
        playerQueues[userId] = { portalId = portalId }
        sessionState:setQueued(player, portalId)
    end
end
```

### 5. Match Isolation

**Problem**: Non-participants (late joiners, spectators) affecting match logic.

**Mitigation**:

#### Participant Tracking
```lua
-- Store participants at match start
self._matchParticipants = {}
for _, player in ipairs(players) do
    self._matchParticipants[player.UserId] = true
    self.sessionState:setMatch(player, matchId, true) -- participant = true
end
```

#### Wave Rewards (Participants Only)
```lua
-- Only grant to participants
for _, player in ipairs(Players:GetPlayers()) do
    if self._matchParticipants[player.UserId] then
        playerManager:addCurrency(player, CURRENCY_PER_WAVE)
        rewardCount = rewardCount + 1
    end
end
```

#### Defeat Conditions (Participants Only)
```lua
-- Only check participants for defeat
for _, player in ipairs(players) do
    if self._matchParticipants[player.UserId] then
        participantCount = participantCount + 1
        if not spectatorManager:isPlayerDead(player) then
            anyAlive = true
        end
    end
end

if participantCount > 0 and not anyAlive then
    self:onDefeat("All players eliminated")
end
```

#### Cleanup on Match End
```lua
-- Clear participants and SessionState
if self._matchParticipants then
    for _, player in ipairs(Players:GetPlayers()) do
        if self._matchParticipants[player.UserId] then
            self.sessionState:setMatch(player, nil, false)
        end
    end
    self._matchParticipants = {}
end
```

## Portal Matchmaking vs Lobby Voting

These two systems are **mutually exclusive** and controlled by the feature flag `GameConfig.USE_PORTAL_MATCHMAKING`.

### Portal Matchmaking Mode (`USE_PORTAL_MATCHMAKING = true`)

**How It Works**:
1. Players spawn in lobby after passing title screen
2. Lobby contains portals (one per map)
3. Players touch portals to join queues
4. When queue reaches `minPlayers`, countdown starts
5. First 8 players launch into match, others stay queued
6. Match plays independently of global state
7. After match, players return to lobby

**Key Behaviors**:
- Lobby voting does NOT start
- Portals remain visible and functional throughout
- Multiple matches can run simultaneously (future)
- Late joiners enter lobby, not active matches
- Global state stays "Lobby" while matches are "WaveActive"

**State Isolation**:
```lua
-- Player in match sees match state
if context.inMatch then
    return "WaveActive" -- or "Countdown", "Victory", "Defeat"
end

-- Player in lobby sees lobby state
return "Lobby"
```

**Lobby Preservation**:
```lua
-- Don't destroy lobby when portal matchmaking is enabled
if self.lobbySetup and not GameConfig.USE_PORTAL_MATCHMAKING then
    self.lobbySetup:cleanup() -- Only cleanup in voting mode
end
```

### Lobby Voting Mode (`USE_PORTAL_MATCHMAKING = false`)

**How It Works**:
1. Players spawn in lobby after passing title screen
2. After `LOBBY_VOTING_TIME`, voting starts
3. All players vote for a map
4. Winning map loads, lobby is cleaned up
5. All players spawn on map together
6. Single shared match for all players
7. After match, return to lobby (recreated)

**Key Behaviors**:
- Portal code does nothing (service not initialized)
- Lobby voting system handles map selection
- Single match for all players
- Global state transitions apply to everyone
- Lobby is destroyed during map load

**Voting Flow**:
```lua
-- Start voting after delay
if numReadyPlayers >= MIN_PLAYERS then
    lobbyManager:startVoting()
end

-- After voting resolves
local winningMap = lobbyManager:getVotingResult()
mapManager:load(winningMap)

-- Cleanup lobby (portal matchmaking disabled)
lobbySetup:cleanup()
```

### Configuration

**GameConfig.lua**:
```lua
-- Portal matchmaking feature flag
GameConfig.USE_PORTAL_MATCHMAKING = true -- or false

-- Portal matchmaking settings (only used if enabled)
GameConfig.PORTAL_MATCHMAKING = {
    MAX_PLAYERS_PER_MATCH = 8,
    DEFAULT_MIN_PLAYERS = 1,
    DEFAULT_COUNTDOWN_TIME = 10,
    COUNTDOWN_CANCEL_THRESHOLD = 1,
    POST_LAUNCH_COOLDOWN = 3,
    TOUCH_DEBOUNCE_TIME = 0.5,
    QUEUE_UPDATE_INTERVAL = 1,
}

-- Lobby voting settings (only used if portal matchmaking disabled)
GameConfig.LOBBY_VOTING_TIME = 5
GameConfig.LOBBY_MIN_PLAYERS = 1
```

## Security Best Practices

### 1. Server-Only Validation

All remote event handlers must use `RunService:IsServer()` guard:

```lua
local RunService = game:GetService("RunService")

if not RunService:IsServer() then
    error("This module can only be required on the server")
end
```

### 2. Never Trust Client Data

```lua
-- BAD: Trust client's weaponId
local weaponId = payload.weaponId

-- GOOD: Use server authority
local weaponId = playerManager:getEquippedWeapon(player)
```

### 3. Validate All Inputs

```lua
-- Type validation
if typeof(origin) ~= "Vector3" then
    return
end

-- Range validation
if damage < 0 or damage > MAX_DAMAGE then
    return
end

-- State validation
if not playerData or not playerData.isAlive then
    return
end
```

### 4. Rate Limiting

```lua
-- Track per-player rate limits
local lastAction = rateLimits[userId]
if lastAction and (now - lastAction) < COOLDOWN then
    return
end
rateLimits[userId] = now
```

### 5. Atomic Operations

```lua
-- Lock during critical section
portal.locked = true

-- Perform operations
local success = performOperation()

-- Always unlock (even on failure)
portal.locked = false

-- Rollback on failure
if not success then
    rollbackChanges()
end
```

### 6. Connection Cleanup

```lua
-- Track connections
playerData.connections = {}

-- Store connection
playerData.connections.healthChanged = connection

-- Cleanup on remove
if playerData.connections.healthChanged then
    playerData.connections.healthChanged:Disconnect()
    playerData.connections.healthChanged = nil
end
```

### 7. State Consistency

```lua
-- Use SessionState as single source of truth
local context = sessionState:getPlayerContext(player)

-- Update all related systems together
sessionState:setMatch(player, matchId, true)
matchRegistry:addPlayer(player, matchId)
gameManager._matchParticipants[userId] = true
```

## Verification Checklist

- [x] Late joiners stay in title/lobby and do not affect active match
- [x] Portals don't disappear in lobby when portal matchmaking is on
- [x] Queue cannot duplicate players; countdown cancels/starts correctly
- [x] Match is capped at 8; overflow forms later matches
- [x] Weapon fire cannot be spammed for higher DPS; ammo cannot be bypassed
- [x] Health sync does not loop; dead players can't be healed
- [x] SessionState provides single source of truth for player context
- [x] All security validations are in place and enforced

---

**Last Updated**: 2026-02-11

**Related Files**:
- `ServerScriptService/SessionState.lua`
- `ServerScriptService/GameManager.lua`
- `ServerScriptService/PortalMatchmakingService.lua`
- `ServerScriptService/WeaponService.lua`
- `ServerScriptService/PlayerManager.lua`
- `ServerScriptService/MatchRegistry.lua`
- `ReplicatedStorage/Shared/GameConfig.lua`
