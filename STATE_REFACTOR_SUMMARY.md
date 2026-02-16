# State Machine Refactor - Implementation Summary

## Problem Statement
Players in portal matches were receiving incorrect game state updates because the global `GameManager.currentState` was overriding match-specific states. This caused the infamous log warning:
```
⛔ Player X in match but global state is Scoreboard; defaulting to Countdown
```

## Root Cause
The architecture assumed all players were in the same game state. Portal matchmaking broke this assumption by creating isolated matches, but the codebase still used a single global state machine with a band-aid fallback to "Countdown" when states mismatched.

## Solution: Separate Match State Ownership

### 1. MatchRegistry State Tracking (MatchRegistry.lua)
**Added:**
- `MatchStates` constant table with match-specific states
- Match records now include `state` field initialized to `Countdown`
- `getMatchState(matchId)` - Query current state of a match
- `setMatchState(matchId, state)` - Update match state with validation

**Why:** Match objects need their own state independent of global GameManager state.

### 2. Player Effective State Resolution (GameManager.lua)
**Modified:** `_getPlayerEffectiveState(player)`

**Before:**
```lua
if self.currentState == "Countdown" or self.currentState == "WaveActive" ... then
    return self.currentState
else
    warn("...defaulting to Countdown")  -- Band-aid
    return "Countdown"
end
```

**After:**
```lua
if context.inMatch and context.matchId then
    local matchState = matchRegistry:getMatchState(context.matchId)
    if matchState then
        return matchState  -- Use actual match state
    else
        warn("REGRESSION: ...match state not found")
        -- Clear corrupted state, fall back to global
    end
end
return self.currentState  -- Global state for non-match players
```

**Why:** Removes band-aid logic by querying actual match state from MatchRegistry.

### 3. State Broadcast Targeting (GameManager.lua)
**Added:** `broadcastEvent(remoteEvent, data, matchOnly)`

Helper method that:
- `matchOnly = true`: Send only to current match players
- `matchOnly = false`: Send only to non-match players
- `matchOnly = nil`: Send to all players (legacy behavior)

**Updated Events:**
- `WaveAnnounce` → Match only
- `WaveUpdate` → Match only
- `CureUpdate` → Match only
- `ShowScoreboard` → Match only
- `ShowCredits` → Match only
- `MapUpdate` → Match only (when in match)
- `GameStateUpdate` → Targeted in setState()

**Why:** Prevents match events from contaminating lobby players and vice versa.

### 4. Match State Transitions (GameManager.lua)
**Modified:** `setState(newState, payload)`

Now detects match states and updates MatchRegistry:
```lua
if isMatchState and self._currentMatchId then
    matchRegistry:setMatchState(self._currentMatchId, newState)
end
```

Also targets broadcasts appropriately instead of `FireAllClients`.

**Why:** Keeps match state in MatchRegistry synchronized with GameManager transitions.

### 5. Match Lifecycle Cleanup (GameManager.lua)
**Modified:** `updateScoreboard(deltaTime)`

Added cleanup before transitioning to next state:
```lua
if self._currentMatchId then
    self.portalMatchmakingService:endMatch(self._currentMatchId)
    self._matchParticipants = nil
    self._currentMatchId = nil
end
```

**Why:** Ensures proper teardown of match state and player mappings.

### 6. Re-queue Prevention (PortalMatchmakingService.lua)
**Modified:** `onPortalTouched(portalId, player)`

Added dual check:
```lua
if self.matchRegistry:isPlayerInMatch(player) or 
   self.sessionState:isPlayerInMatch(player) then
    -- Reject with feedback
    return
end
```

**Why:** Prevents players from joining queue while in active match.

## Files Modified
1. `ServerScriptService/MatchRegistry.lua` - State tracking and accessors
2. `ServerScriptService/GameManager.lua` - State resolution, broadcasting, cleanup
3. `ServerScriptService/PortalMatchmakingService.lua` - Re-queue protection, getter
4. `STATE_REFACTOR_VERIFICATION.md` - Testing checklist (new)

## Architectural Principles

### State Ownership Hierarchy
```
Global States (GameManager.currentState)
├── TitleScreen
├── Epilogue  
├── Lobby
└── Waiting

Match States (MatchRegistry per matchId)
├── Countdown
├── WaveActive
├── Intermission
├── Victory
└── Defeat
```

### Player Effective State Resolution
```
Player → SessionState → Context
                         ├── inMatch? → Query MatchRegistry.getMatchState(matchId)
                         └── Not in match → Use GameManager.currentState
```

### Event Broadcasting
```
Match Events (WaveAnnounce, WaveUpdate, CureUpdate, etc.)
└── broadcastEvent(event, data, matchOnly=true)
    └── Iterate only match players from MatchRegistry

Global Events (Lobby, TitleScreen, etc.)
└── broadcastEvent(event, data, matchOnly=false)
    └── Iterate only non-match players

Legacy Events (FireAllClients fallback)
└── broadcastEvent(event, data, matchOnly=nil)
```

## Benefits

### Correctness
- ✅ Match players see match state, lobby players see lobby state
- ✅ No more "defaulting to Countdown" warnings
- ✅ Eliminates state bleed by design, not band-aids

### Performance
- ✅ Targeted broadcasts reduce network traffic
- ✅ O(match_size) instead of O(all_players) for match events
- ✅ Scales better with multiple concurrent matches

### Maintainability
- ✅ Clear ownership: match states in MatchRegistry, global states in GameManager
- ✅ Defensive: Regression warnings detect state corruption
- ✅ Documented: Comments explain dual checks and cleanup paths

## Testing
See `STATE_REFACTOR_VERIFICATION.md` for:
- Full match lifecycle test scenario
- Edge case testing (concurrent matches, player disconnect, state corruption)
- Log monitoring guidelines
- Success criteria

## Edge Case Handling

### Player Disconnect
- `MatchRegistry.removePlayerFromMatch()` removes player
- SessionState cleanup on `PlayerRemoving`
- Empty match marked inactive

### State Corruption Recovery
- Regression warning logged
- Player's SessionState cleared
- Falls back to global state

### Match Cleanup Paths
1. **Primary:** Scoreboard timer expires → `updateScoreboard()` cleanup
2. **Fallback:** Player disconnect → individual removal
3. **Safety:** Empty match → automatic inactive marking

## Compatibility Notes

### Breaking Changes
None - Changes are internal to state management.

### Configuration Requirements
- Portal matchmaking must be enabled: `GameConfig.USE_PORTAL_MATCHMAKING = true`
- Without portal matchmaking, code degrades gracefully (no MatchRegistry)

### State Name Compatibility
- Match state names intentionally match GameManager.States for seamless transition
- `Countdown` === `GameManager.States.COUNTDOWN` (string value)
- This allows direct passing of state names without conversion

## Security Considerations

### Server Authority
- ✅ All state transitions server-side only
- ✅ Clients receive filtered state via effective state resolution
- ✅ Re-queue check server-authoritative (cannot be bypassed)

### Validation
- ✅ Match state validation in `setMatchState()`
- ✅ Dual check for player-in-match (defense-in-depth)
- ✅ Regression detection prevents silent failures

## Future Enhancements

### Potential Improvements
1. **Shared Constants Module:** Extract state constants to avoid duplication
2. **Match State Machine:** Add state transition validation (e.g., can't go Countdown → Victory)
3. **Match Metrics:** Track match duration, player count, completion rate
4. **Server Shutdown Handling:** Explicit match cleanup on server close

### Not Implemented (Out of Scope)
- State persistence across server restarts (matches are ephemeral)
- Cross-server match migration (single-server architecture)
- Spectator state for non-participants (existing spectator system handles this)

## Rollback Plan
If issues arise, can revert to band-aid behavior by:
1. Restore original `_getPlayerEffectiveState()` with "defaulting to Countdown" logic
2. Revert `setState()` to `FireAllClients` broadcasting
3. Remove match state tracking from MatchRegistry

However, this returns to the original problem of state bleed.

## Conclusion
This refactor eliminates global state bleed by properly separating match lifecycle from global game flow. Match states are now owned by Match objects via MatchRegistry, with targeted event broadcasting and proper cleanup. The architecture scales to multiple concurrent matches and provides defensive recovery from state corruption.
