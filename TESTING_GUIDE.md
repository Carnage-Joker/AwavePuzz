# Quick Testing Guide: Title/Lobby/Portal Flow Fixes

## Prerequisites
- Open project in Roblox Studio
- Configure GameConfig settings as needed:
  - `SHOW_TITLE_SCREEN` (true/false)
  - `USE_PORTAL_MATCHMAKING` (true/false)

## Test Scenarios

### 1. RemoteEvent Duplication Check
**Goal**: Verify no duplicate RemoteEvents exist

**Steps**:
1. Start a test server in Studio
2. Open Output window
3. Look for warning messages about duplicate remotes
4. Check `ReplicatedStorage.RemoteEvents` folder in Explorer
5. Verify each remote exists only once

**Expected Result**: 
- No warnings about duplicate RemoteEvents
- All remotes in RemoteRegistry are present exactly once
- Console shows: `[RemoteRegistry] [BOOT][SERVER] Registry initialized: X created, Y existing`

### 2. Title Screen Flow (if SHOW_TITLE_SCREEN = true)
**Goal**: Test title screen appearance and dismissal

**Steps**:
1. Join game as a player
2. Observe title screen appears
3. Try to move (WASD keys)
4. Press any key to continue
5. Observe title screen fades out
6. Try to move again

**Expected Result**:
- Title screen appears on join
- Cannot move during title screen (WalkSpeed = 0)
- Console shows: `[ClientState] Applying state: TitleScreen`
- Console shows: `[FPSMovement] Movement disabled`
- After dismissal: Can move in lobby
- Console shows: `[ClientState] Applying state: Lobby`
- Console shows: `[FPSMovement] Movement enabled`

### 3. Lobby Movement & Weapon States
**Goal**: Verify movement enabled, weapons disabled in lobby

**Steps**:
1. In lobby state, test movement (WASD)
2. Try to fire weapon (Left Click)
3. Try to reload (R key)

**Expected Result**:
- Can move around freely
- Cannot fire weapons (no response to Left Click)
- Console shows: `[FPSWeaponController] Weapons disabled`

### 4. Portal Discovery (if USE_PORTAL_MATCHMAKING = true)
**Goal**: Verify portals are visible and functional

**Steps**:
1. Check Output window for portal discovery logs
2. Navigate to lobby area
3. Look for portal objects with billboard GUIs
4. Touch a portal
5. Observe queue count increase
6. Wait for countdown (or get more players)

**Expected Result**:
- Console shows: `[Flow] Lobby -> Discovering portals...`
- Console shows: `[PortalMatchmakingService] Starting portal discovery...`
- Console shows: `[PortalMatchmakingService] Found X potential portal objects`
- Console shows: `[PortalMatchmakingService] Discovery complete: X portals registered`
- Portals visible in lobby with "0/8" indicators
- Touching portal shows: `[PortalMatchmakingService] Player X joined portal Y queue`
- Queue count updates on billboard GUI

### 5. State Transitions
**Goal**: Verify movement/weapon states change with game state

**Steps**:
1. Start in Lobby
2. Queue for match or wait for countdown
3. Observe state changes as round starts
4. During countdown/wave, test movement and weapons
5. After round ends, observe states again

**Expected Result**:
```
Lobby:
- [ClientState] Applying state: Lobby
- [FPSMovement] Movement enabled
- [FPSWeaponController] Weapons disabled
- Can move, cannot shoot

Countdown:
- [ClientState] Applying state: Countdown
- [FPSWeaponController] Weapons enabled
- Can move AND shoot

WaveActive:
- [ClientState] Applying state: WaveActive
- Both movement and weapons enabled
- Full gameplay functionality

Victory/Defeat:
- [ClientState] Applying state: Victory/Defeat
- [FPSWeaponController] Weapons disabled
- Can move but not shoot
```

### 6. Lobby Structure Verification
**Goal**: Verify lobby folders exist in workspace

**Steps**:
1. In Studio Explorer, check workspace
2. Look for "Lobby" folder
3. Inside Lobby, look for "Portals" folder
4. Check portal objects inside Portals folder

**Expected Result**:
- workspace.Lobby exists
- workspace.Lobby.Portals exists
- Portal models present (if portal matchmaking enabled)
- Each portal has TouchPart and QueueIndicator BillboardGui
- Portals have attributes: PortalId, MapId, MinPlayers, CountdownSeconds

### 7. UI Duplicate Check
**Goal**: Ensure no duplicate UI instances

**Steps**:
1. Join game and wait for all UIs to initialize
2. Open Explorer and check PlayerGui
3. Count instances of each UI ScreenGui
4. Run the test script from tests/ui_duplicate_detection.lua

**Expected Result**:
- Each UI ScreenGui appears exactly once
- No duplicate TitleScreenUI instances
- No duplicate EpilogueUI instances
- Test script reports: "✅ TEST PASSED - No duplicates detected!"

## Console Log Patterns to Look For

### Successful Boot Sequence (Client)
```
[BOOT][CLIENT] Phase 1: Waiting for remote registry...
[BOOT][CLIENT] Phase 1 complete: Remote registry ready
[BOOT][CLIENT] Phase 5: Initializing core systems...
[BOOT][CLIENT] ✓ Movement initialized
[BOOT][CLIENT] ✓ Weapon system initialized
[BOOT][CLIENT] Phase 6: Initializing UI systems...
[BOOT][CLIENT] ✓ TitleScreenUI instance created and remotes bound
[TitleScreenUI] Remotes bound and ready
[BOOT][CLIENT] ✓ EpilogueUI instance created and remotes bound
[EpilogueUI] Remotes bound and ready
[BOOT][CLIENT] Phase 6.5: Setting up client state router...
[BOOT][CLIENT] ✓ Client state router connected to GameStateUpdate
[ClientState] Applying state: Waiting
[FPSMovement] Movement enabled
[FPSWeaponController] Weapons disabled
```

### Successful Portal Discovery (Server)
```
[Flow] Entering lobby (state -> LOBBY)
[LobbySetup] Created workspace.Lobby folder
[LobbySetup] Created workspace.Lobby.Portals folder
[LobbySetup] Portals folder is empty, creating default portals
[Flow] Lobby -> Discovering portals...
[PortalMatchmakingService] Starting portal discovery...
[PortalMatchmakingService] Found 3 potential portal objects in Portals folder
[PortalMatchmakingService] Registered portal Random (map: Random, minPlayers: 1)
[PortalMatchmakingService] Registered portal ResearchOutpost (map: ResearchOutpost, minPlayers: 1)
[PortalMatchmakingService] Registered portal Village (map: Village, minPlayers: 1)
[PortalMatchmakingService] Discovery complete: 3 portals registered
```

## Common Issues & Solutions

### Issue: "Cannot move in lobby"
**Solution**: Check console for state transitions. Should see:
- `[ClientState] Applying state: Lobby`
- `[FPSMovement] Movement enabled`
If not, verify GameStateUpdate is being fired by server.

### Issue: "Portals not visible"
**Solution**: Check console for portal discovery logs. If missing:
1. Verify USE_PORTAL_MATCHMAKING = true in GameConfig
2. Check workspace.Lobby.Portals folder exists
3. Check server logs for discovery errors

### Issue: "Duplicate RemoteEvents"
**Solution**: Check that UI modules don't use RemoteEventUtil.getOrCreateEvents.
All UI should use remotes passed from ClientMain via bindRemotes().

### Issue: "Weapons fire in lobby"
**Solution**: Check console for:
- `[ClientState] Applying state: Lobby`
- `[FPSWeaponController] Weapons disabled`
If weapons still fire, check shouldBlockGameplay() is gating input properly.

## Performance Monitoring

Watch for these metrics:
- Client initialization time: Should be < 5 seconds
- Portal discovery time: Should be < 1 second
- State transition lag: Should be instant (< 100ms)
- No memory leaks from duplicate UIs or event connections

## Acceptance Criteria

✅ All tests pass
✅ No duplicate RemoteEvents
✅ Title screen flow works (if enabled)
✅ Movement disabled in title, enabled in lobby
✅ Weapons disabled in lobby, enabled in gameplay
✅ Portals visible and functional (if enabled)
✅ No console errors during normal gameplay
✅ State transitions logged correctly
✅ No performance degradation

## Automated Testing (Future)

Consider adding these automated tests:
1. Unit test for applyState() function
2. Integration test for RemoteRegistry initialization
3. Integration test for portal discovery
4. UI duplicate detection (already exists in tests/)

## Reporting Issues

If any test fails, report with:
1. Test scenario name
2. Steps to reproduce
3. Expected result
4. Actual result
5. Console log output
6. Screenshots/videos if applicable
