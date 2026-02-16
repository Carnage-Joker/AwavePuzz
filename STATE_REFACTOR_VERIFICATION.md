# State Machine Refactor Verification Checklist

## Purpose
This checklist verifies that the match state ownership refactor successfully eliminates global state bleed between match and lobby states.

## Expected Behavior Changes

### Before Fix
- ❌ Players in portal matches received global Lobby/Scoreboard state
- ❌ Warnings: "Player X in match but global state is Scoreboard; defaulting to Countdown"
- ❌ Match-specific events (WaveAnnounce, WaveUpdate) broadcasted to all players including lobby
- ❌ Players could attempt to re-queue while in an active match

### After Fix
- ✅ Players in portal matches receive match-specific state from MatchRegistry
- ✅ No "defaulting to Countdown" warnings should appear
- ✅ Match-specific events only broadcast to match participants
- ✅ Players cannot re-queue while in an active match (blocked with feedback)
- ✅ Regression warning if player marked as in match but match state missing

## Test Scenario: Full Match Lifecycle

### 1. Initial Join - Lobby State
**Steps:**
1. Player joins server
2. Passes title screen (if enabled)
3. Enters lobby

**Expected:**
- Player state: `Lobby` or `Waiting`
- No match state in SessionState
- Player can see lobby portals

### 2. Queue Entry
**Steps:**
1. Player touches portal
2. Queue counter increments

**Expected:**
- SessionState shows `inQueue = true`, `portalId = [portal name]`
- Player sees queue status UI
- If player touches portal again while queued → ignored (no duplicate entry)
- If player already in match → rejected with message "Cannot join queue while in a match"

### 3. Match Launch - Countdown
**Steps:**
1. Enough players queue (min players threshold met)
2. Countdown reaches 0
3. Match launches

**Expected:**
- MatchRegistry creates match with state = `Countdown`
- SessionState marks players as `inMatch = true`, `matchId = [match ID]`, `isParticipant = true`
- GameManager._currentMatchId set
- Players spawned on map
- Only match players receive `GameStateUpdate` with state = `Countdown`
- Lobby players remain in lobby state (not affected)

### 4. Wave Active
**Steps:**
1. Countdown expires
2. Wave 1 starts

**Expected:**
- Match state transitions to `WaveActive`
- Only match players receive:
  - `WaveAnnounce` event
  - `WaveUpdate` events (periodic)
  - `CureUpdate` events
- Lobby players do not receive these events
- Check logs: No "defaulting to Countdown" warnings

### 5. Wave Completion - Intermission
**Steps:**
1. All zombies defeated
2. Wave complete

**Expected:**
- Match state transitions to `Intermission`
- Wave rewards granted only to match participants
- Next wave countdown starts

### 6. Victory or Defeat
**Steps:**
1. Complete cure (victory) OR base destroyed/all players dead (defeat)

**Expected:**
- Match state transitions to `Victory` or `Defeat`
- Only match players receive:
  - `ShowCredits` (on victory)
  - `ShowScoreboard`
- Stats updated only for match participants

### 7. Scoreboard Display
**Steps:**
1. Scoreboard timer expires

**Expected:**
- Match ends in MatchRegistry
- Match cleanup: `endMatch()` called
- SessionState cleared for all match players: `inMatch = false`, `matchId = nil`
- GameManager._currentMatchId cleared
- GameManager._matchParticipants cleared

### 8. Return to Lobby
**Steps:**
1. Players returned to lobby spawn

**Expected:**
- Player effective state: `Lobby` or `Waiting`
- No match state in SessionState
- Players can see portals again

### 9. Re-queue Test
**Steps:**
1. Player touches portal again
2. Attempts to join new match

**Expected:**
- Player successfully joins queue (not blocked)
- Can participate in new match without issues

## Edge Cases to Test

### Concurrent Matches
**Scenario:** Multiple portal matches running simultaneously

**Expected:**
- Each match has independent state in MatchRegistry
- Players only receive events for their own match
- Lobby players don't receive any match events

### Player Disconnect During Match
**Scenario:** Player leaves during active match

**Expected:**
- Player removed from MatchRegistry
- SessionState cleaned up on PlayerRemoving
- Other match players continue unaffected
- If all players leave, match marked inactive and cleaned up

### Regression: Corrupted State
**Scenario:** Player marked as in match but match doesn't exist (should not happen, but defensive)

**Expected:**
- Warning logged: "REGRESSION: Player X marked as in match Y but match state not found"
- Player's SessionState cleared automatically
- Player falls back to global state (recovery)

## Log Messages to Monitor

### Success Indicators
```
[MatchRegistry] Created match Match_X with N players on map [MapName]
[MatchRegistry] Match Match_X state: Countdown → WaveActive
[GameManager] Match Match_X complete, cleaning up
```

### Error Indicators (Should NOT Appear)
```
⛔ [GameManager] Player X in match but global state is Y; defaulting to Countdown
```

### Regression Warnings (Should NOT Appear Unless Real Bug)
```
⚠️ [GameManager] REGRESSION: Player X marked as in match Y but match state not found
```

## Performance Checks

### State Query Performance
- `_getPlayerEffectiveState()` should be fast (single MatchRegistry lookup)
- No noticeable lag when many players in different matches

### Event Broadcasting
- Match events only iterate match players (not all server players)
- Lobby events only iterate non-match players
- Should scale better than previous FireAllClients approach

## Success Criteria

✅ All test scenarios pass without errors
✅ No "defaulting to Countdown" warnings in logs
✅ Match-specific events properly isolated
✅ Player re-queue works after match ends
✅ No state corruption or desync issues
✅ Log messages indicate proper state transitions

## Known Limitations

- Global states (TitleScreen, Epilogue, Lobby, Waiting) still use GameManager.currentState
- This is intentional - these are pre-match/post-match states that should be global
- Portal matchmaking feature must be enabled (GameConfig.USE_PORTAL_MATCHMAKING)
