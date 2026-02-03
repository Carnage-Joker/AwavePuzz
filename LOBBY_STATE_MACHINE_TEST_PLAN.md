# Lobby State Machine - Manual Testing Plan

## Overview
This document describes how to manually test the new lobby resolution state machine in Roblox Studio.

## What Was Changed
Replaced the simple `_lobbyResolved` boolean flag with a proper state machine (`LobbyResolutionStates`) that tracks each phase of lobby resolution:
1. **VOTING** - Players voting for map
2. **MAP_LOADING** - Map load initiated
3. **MAP_LOADED** - Map successfully loaded (transitions to configuration)
4. **CONFIGURING** - Configuring spawners and notifying spawn manager
5. **SPAWNING** - Spawning players
6. **COMPLETE** - Ready to transition to game
7. **FAILED** - Map load failed (will retry)

## Test Scenarios

### Test 1: Normal Lobby Flow
**Purpose**: Verify normal lobby resolution works correctly

**Steps**:
1. Open the game in Roblox Studio
2. Start the game with minimum players
3. Wait for lobby voting to complete
4. Observe the console output

**Expected Output**:
```
[Flow] Lobby -> MapLoading(<mapId>) - Voting complete
[Flow] MapLoading -> Attempting to load map: <mapId>
[Flow] MapLoaded -> Map <mapId> loaded successfully
[Flow] MapLoaded -> Configuring -> Preparing to configure spawners
[Flow] Configuring -> Spawning -> Configuring spawners and notifying spawn manager
[Flow] Spawning -> Complete -> Spawning all players on map
[Flow] Complete -> StartGame -> Starting game
```

**Success Criteria**:
- ✅ All state transitions occur in order
- ✅ No duplicate map loads
- ✅ Players spawn correctly on the map
- ✅ Game starts normally

### Test 2: Map Load Failure with Retry
**Purpose**: Verify retry logic when map fails to load

**Setup**:
1. Temporarily modify `MapManager:load()` to return false (simulate failure)
2. Or use an invalid map ID in the voting system

**Steps**:
1. Start the game
2. Wait for lobby voting to complete
3. Observe retry behavior

**Expected Output**:
```
[Flow] Lobby -> MapLoading(<mapId>) - Voting complete
[Flow] MapLoading -> Attempting to load map: <mapId>
[GameManager] Failed to load map: <mapId> (attempt 1)
[Flow] MapLoading -> Attempting to load map: <mapId>
[GameManager] Failed to load map: <mapId> (attempt 2)
[Flow] MapLoading -> Attempting to load map: <mapId>
[GameManager] Failed to load map: <mapId> (attempt 3)
[GameManager] Max lobby retries reached, will try default map
[Flow] MapLoading -> Attempting to load map: nil
[Flow] MapLoaded -> Map <defaultMap> loaded successfully
...
```

**Success Criteria**:
- ✅ System retries up to MAX_LOBBY_RETRIES (3) times
- ✅ After max retries, falls back to default map
- ✅ Debounce prevents rapid retries (1 second between attempts)
- ✅ No race conditions or double loads

### Test 3: Multi-Map Disabled
**Purpose**: Verify state machine works when ENABLE_MULTI_MAP is false

**Setup**:
1. Set `GameConfig.ENABLE_MULTI_MAP = false`

**Steps**:
1. Start the game
2. Wait for lobby to resolve

**Expected Output**:
```
[Flow] Lobby -> MapLoading(<mapId>) - Voting complete
[Flow] MapLoading -> Attempting to load map: <mapId>
[Flow] Complete -> StartGame -> Starting game
```

**Success Criteria**:
- ✅ Skips directly to COMPLETE state when multi-map disabled
- ✅ Game starts normally

### Test 4: Race Condition Prevention
**Purpose**: Verify no double-loading occurs

**Steps**:
1. Start the game
2. Watch for any duplicate map loading attempts
3. Monitor for double spawning of players

**Expected Behavior**:
- ✅ Each state transition occurs exactly once
- ✅ Map loads only once per lobby cycle
- ✅ Players spawn only once
- ✅ No error messages about duplicate entities

### Test 5: State Persistence Across Failures
**Purpose**: Verify state is properly maintained during failures

**Setup**:
1. Simulate intermittent map loading failures

**Expected Behavior**:
- ✅ State machine returns to MAP_LOADING after FAILED state
- ✅ Retry counter increments correctly
- ✅ Selected map ID persists across retries
- ✅ After max retries, state resets properly for default map

## Monitoring Tools

### Console Commands
```lua
-- Recommended: rely on [Flow] logs in the Output window to observe
-- lobby state transitions and retry counts in real time.
--
-- You should see messages such as:
--   [Flow][Lobby] state=VOTING
--   [Flow][Lobby] state=FAILED retry=1
--
-- Optional: if the GameManager exposes a dedicated runtime Instance
-- (for example, a Folder named "GameManagerState" under ServerScriptService)
-- and sets attributes on it for debugging, you can inspect them like this:

local gmState = game.ServerScriptService:FindFirstChild("GameManagerState")

if gmState then
    print("Lobby state:", gmState:GetAttribute("LobbyResolutionState"))
    print("Retry count:", gmState:GetAttribute("LobbyRetryCount"))
else
    warn("GameManagerState instance not found; use [Flow] logs in the Output window instead.")
end

-- Note: ModuleScripts like GameManager do not automatically expose these
-- attributes. They must be explicitly set on a real Instance at runtime
-- by your game code if you want to inspect them via GetAttribute().
```

### Output Panel
Monitor the Output panel in Roblox Studio for:
- State transition messages (prefixed with `[Flow]`)
- Warning messages for failures
- Error messages for unexpected issues

## Known Issues to Watch For

### Pre-Refactor Issues (Should Now Be Fixed)
- ❌ Double map loading
- ❌ Race conditions on map load failure
- ❌ Players spawning before map loads
- ❌ Infinite retry loops

### Post-Refactor Expected Behavior
- ✅ Single map load per lobby cycle
- ✅ Proper retry with max limit
- ✅ Clear state transitions
- ✅ Graceful fallback to default map

## Configuration Values

Located in `ReplicatedStorage/Shared/GameConfig.lua`:

```lua
-- Lobby settings
LOBBY_VOTING_TIME = 30 -- seconds
ENABLE_MULTI_MAP = true
MAX_LOBBY_RETRIES = 3 -- New setting

-- Security settings
Security.LOBBY_DEBOUNCE_TIME = 1.0 -- seconds between retry attempts
```

## Debugging Tips

1. **Enable verbose logging**: Watch the Output panel for `[Flow]` messages
2. **Check timing**: Verify debounce works (1 second between retries)
3. **Monitor state**: Each state should transition exactly once per cycle
4. **Test edge cases**: Try invalid maps, network issues, rapid player joins
5. **Verify cleanup**: Ensure state machine resets properly on new lobby start

## Success Criteria Summary

The refactor is successful if:
1. ✅ No race conditions occur during lobby resolution
2. ✅ Map loads exactly once per lobby cycle
3. ✅ Failed map loads trigger proper retry logic
4. ✅ System falls back to default map after max retries
5. ✅ Players spawn correctly after map loads
6. ✅ Game starts normally after lobby resolution
7. ✅ State machine resets properly for next lobby cycle
8. ✅ All console messages show proper state flow

## Reporting Issues

If you encounter issues during testing, please include:
- The console output showing state transitions
- The specific state where the issue occurred
- Any error messages
- Steps to reproduce
- Expected vs actual behavior
