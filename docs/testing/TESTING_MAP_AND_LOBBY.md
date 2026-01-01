# Testing Checklist - Map Position and Lobby Improvements

## Pre-Testing Setup

1. Open the game in Roblox Studio
2. Ensure you have at least one map model in `ServerStorage/Maps`
3. Verify `GameConfig.ENABLE_MULTI_MAP = true`
4. Verify `GameConfig.AUTO_CREATE_BASE_CAMP = true`

## Test 1: Map Position at (5000, 0, 0)

### Expected Behavior:
- Map should appear at position (5000, 0, 0) in workspace
- Map should be named "ActiveMap"
- All spawn points should be offset to the map position

### Test Steps:
1. Start the game in Studio
2. Wait for lobby voting to complete
3. Open Explorer window
4. Find `workspace.ActiveMap`
5. Check the Position or CFrame of parts in the map

### Verification:
- [ ] ActiveMap exists in workspace
- [ ] ActiveMap parts have X position around 5000
- [ ] Map loads successfully without errors
- [ ] Console shows map loaded with spawn point counts

## Test 2: Base Camp at Map Center

### Expected Behavior:
- Base camp should be created at the center of the map
- Base camp should be at the same position offset as the map
- Players should spawn at the base camp

### Test Steps:
1. After map loads, find `workspace.BaseCamp`
2. Check its position in Properties
3. Spawn as a player
4. Note where you spawn

### Verification:
- [ ] BaseCamp exists in workspace
- [ ] BaseCamp position X is around 5000
- [ ] BaseCamp contains a SpawnLocation part
- [ ] Player spawns at the base camp location
- [ ] Player can see the map from spawn

## Test 3: Zombie Spawning

### Expected Behavior:
- Zombies should spawn around the map perimeter
- Zombies should pathfind to base camp correctly

### Test Steps:
1. Wait for first wave to start
2. Observe where zombies spawn
3. Watch zombies move toward base

### Verification:
- [ ] Zombies spawn at the map position (X around 5000)
- [ ] Zombies appear around the map perimeter
- [ ] Zombies pathfind to base camp successfully
- [ ] No zombies spawn at origin (0, 0, 0)

## Test 4: Resource and Item Spawning

### Expected Behavior:
- Resources should spawn at map position
- Items should spawn near base camp

### Test Steps:
1. Wait for resources to spawn
2. Look for glowing resource orbs
3. Check their positions

### Verification:
- [ ] Resources appear at the map (X around 5000)
- [ ] Resources are visible and collectible
- [ ] Items spawn near base camp

## Test 5: Lobby UI Display

### Expected Behavior:
- Lobby UI should appear when voting starts
- UI should show player counts
- Buttons should be interactive

### Test Steps:
1. Join game in Studio (test with multiple clients if possible)
2. Wait for lobby phase
3. Observe the lobby UI on the left side

### Verification:
- [ ] Lobby UI appears on left side of screen
- [ ] Shows "LOBBY" title
- [ ] Shows player count (e.g., "Players: 1 (0 ready, 0 waiting)")
- [ ] Shows three buttons: "I'M READY", "WAITING FOR FRIENDS", "SWITCH SERVER"
- [ ] UI has smooth slide-in animation

## Test 6: Ready System

### Expected Behavior:
- Clicking "I'M READY" should toggle ready status
- Button should change appearance when ready
- All clients should see updated counts

### Test Steps:
1. Click "I'M READY" button
2. Observe button changes
3. Check console for messages

### Verification:
- [ ] Button changes to "✓ READY" with green color
- [ ] Clicking again unmarks as ready
- [ ] Player count updates (e.g., "Players: 1 (1 ready, 0 waiting)")
- [ ] Console shows "[LobbyManager] Player {name} is ready"

## Test 7: Waiting for Friends System

### Expected Behavior:
- Clicking "WAITING FOR FRIENDS" should toggle waiting status
- Timer should extend on first wait
- Status message should update

### Test Steps:
1. During voting, click "WAITING FOR FRIENDS"
2. Observe timer on map voting UI
3. Check status message

### Verification:
- [ ] Button changes to "⏱ WAITING FOR FRIENDS" with orange color
- [ ] Voting timer extends (check console logs)
- [ ] Status message shows "X player(s) waiting for friends"
- [ ] Player count updates (e.g., "Players: 1 (0 ready, 1 waiting)")
- [ ] Console shows "[LobbyManager] Timer extended due to {name} waiting for friends"

## Test 8: Server Switch Button

### Expected Behavior (Studio):
- Button click should trigger event
- Console should show attempt
- Will fail in Studio (TeleportService requires published game)

### Test Steps:
1. Click "SWITCH SERVER" button
2. Check console output

### Verification:
- [ ] Console shows "[LobbyManager] Player {name} requesting server switch"
- [ ] No crash or errors
- [ ] Button is clickable

### Expected Behavior (Published Game):
- Player should be teleported to different server

## Test 9: Multiple Players (Requires Multi-Client Testing)

### Expected Behavior:
- All players see each other's status
- Ready/waiting counts update for everyone
- Timer extension affects all clients

### Test Steps:
1. Join with 2+ clients
2. Have one player mark ready
3. Have another player mark waiting
4. Observe UI updates on both

### Verification:
- [ ] Both clients show updated player counts
- [ ] Status changes appear on all clients
- [ ] Timer extends for all clients when someone waits

## Test 10: Integration with Map Voting

### Expected Behavior:
- Lobby UI and Map Voting UI should work together
- Both UIs should be visible
- Map voting should still work normally

### Test Steps:
1. Wait for lobby phase
2. Observe both UIs (Lobby on left, Voting in center)
3. Vote for a map
4. Mark yourself as ready
5. Wait for voting to end

### Verification:
- [ ] Lobby UI on left side
- [ ] Map Voting UI in center
- [ ] Can interact with both UIs
- [ ] Voting completes normally
- [ ] Both UIs disappear after map selected
- [ ] Game starts normally

## Test 11: End-to-End Flow

### Test Steps:
1. Start game
2. Wait for lobby
3. Mark as ready
4. Vote for map
5. Wait for countdown
6. Verify spawn location
7. Play through a wave
8. Check that everything works

### Verification:
- [ ] Lobby appears correctly
- [ ] Ready/waiting system works
- [ ] Map voting completes
- [ ] Map loads at (5000, 0, 0)
- [ ] Player spawns at base camp
- [ ] Zombies spawn correctly
- [ ] Gameplay works normally
- [ ] No errors in console

## Test 12: Edge Cases

### Test Case A: No One Ready
- Expected: Game should start after voting time expires
- [ ] Works correctly

### Test Case B: Everyone Ready
- Expected: Status shows "All players ready! Game starting soon..."
- [ ] Status message updates correctly

### Test Case C: Toggle Ready/Waiting Rapidly
- Expected: No errors, last state wins
- [ ] No errors occur
- [ ] State updates correctly

### Test Case D: Multiple Players Waiting
- Expected: Timer only extends once
- [ ] Timer extends on first wait only
- [ ] Additional waits don't extend further

## Console Log Verification

### Expected Messages:
```
[MapManager] Loaded map 'MapName':
  - Zombie spawn points: X
  - Resource spawn points: Y
  - Item spawn points: Z
[LobbyManager] Map voting started with N available maps
[LobbyUI] Initialized
[LobbyManager] Player {name} is ready
[LobbyManager] Player {name} waiting status: true
[LobbyManager] Timer extended due to {name} waiting for friends
```

- [ ] All expected messages appear
- [ ] No error or warning messages related to new features
- [ ] Map position shows X coordinate around 5000

## Performance Check

### Verify:
- [ ] UI animations are smooth
- [ ] No lag when clicking buttons
- [ ] Map loading time is acceptable
- [ ] Game runs at stable FPS

## Bug Check

### Common Issues:
- [ ] No players stuck at origin (0, 0, 0)
- [ ] No zombies stuck at origin
- [ ] No duplicate base camps
- [ ] No invisible maps
- [ ] Spawn location works correctly
- [ ] UI doesn't block other UIs
- [ ] Buttons respond to clicks
- [ ] Remote events fire correctly

## Final Verification

After completing all tests:

- [ ] All "Expected Behavior" items verified
- [ ] No critical bugs found
- [ ] Console shows no errors
- [ ] Game is playable from start to finish
- [ ] Ready to merge changes

## Notes Section

Use this space to record any issues, observations, or suggestions:

---

## Testing Environment

- **Roblox Studio Version:** _________
- **Test Date:** _________
- **Tester:** _________
- **Number of Test Clients:** _________

## Test Results

- **Total Tests:** 12
- **Passed:** _________
- **Failed:** _________
- **Blocked:** _________

## Issues Found

| Issue # | Description | Severity | Status |
|---------|-------------|----------|--------|
| 1       |             |          |        |
| 2       |             |          |        |
| 3       |             |          |        |
