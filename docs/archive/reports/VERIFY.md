# AwavePuzz - Verification & Testing Guide

**Document Version:** 1.0  
**Generated:** 2026-01-24  
**Purpose:** Step-by-step manual testing procedure for Roblox Studio

---

## Pre-Testing Setup

### 1. Open Project in Roblox Studio

1. Launch Roblox Studio
2. Open `AwavePuzz` project
3. Verify all files are present:
   - ServerScriptService (35 files)
   - StarterPlayer/StarterPlayerScripts (30+ files)
   - ReplicatedStorage/Shared (19 modules)
   - ServerStorage/Maps (3+ maps)

### 2. Check Studio Settings

1. **View** → **Output** (open output window)
2. **Home** → **Test** → **Clients and Servers** (for multiplayer testing)
3. Enable **Script Errors** in output window
4. Clear output window before each test

### 3. Initial Sanity Check

Run game in single-player (F5) and check output for:
- ✅ No red errors on startup
- ✅ "=== Aether Wave: Convergence Server Starting ===" message
- ✅ All services initialize successfully
- ✅ "=== Server Ready ===" message appears

---

## Test Suite 1: Server Startup

### Test 1.1: Clean Server Start

**Objective:** Verify server starts without errors

**Steps:**
1. Press F5 to start test
2. Wait 10 seconds
3. Check output window

**Expected Results:**
```
=== Aether Wave: Convergence Server Starting ===
[MainServer] Loading shared configuration...
[MainServer] Configuration loaded successfully
[GameManager] Loading shared configuration...
AllianceService initialized
GameManager initialized
SprintService initialized
CureService initialized
PuzzleService initialized
Services linked
AchievementService initialized and linked
FunFactService initialized and linked
CureSynthesisService initialized and linked
=== Server Ready ===
```

**Pass Criteria:**
- ✅ No errors (red text)
- ✅ All services report initialization
- ✅ Server reaches "Ready" state
- ⚠️ Warnings are acceptable (yellow text)

**Fail Criteria:**
- ❌ Any red error messages
- ❌ Missing "Server Ready" message
- ❌ Server hangs/freezes

---

### Test 1.2: Missing Module Handling

**Objective:** Verify graceful failure when modules missing

**Steps:**
1. Temporarily rename `ReplicatedStorage/Shared/GameConfig.lua` to `GameConfig.lua.bak`
2. Press F5 to start test
3. Check output window

**Expected Results:**
```
=== Aether Wave: Convergence Server Starting ===
[MainServer] Loading shared configuration...
[MainServer] CRITICAL: Failed to load GameConfig module after 5 seconds. Check Shared folder structure.
```

**Pass Criteria:**
- ✅ Clear error message appears within 10 seconds
- ✅ Error explains what's missing
- ✅ Server errors instead of hanging forever

**Cleanup:**
1. Rename `GameConfig.lua.bak` back to `GameConfig.lua`
2. Verify Test 1.1 passes again

---

## Test Suite 2: Map Loading

### Test 2.1: Default Map Load

**Objective:** Verify map loads at correct position

**Steps:**
1. Start server (F5)
2. Wait for lobby countdown (or skip to playing state)
3. Check Workspace for loaded map

**Expected Results:**
- Map appears in Workspace with name "ActiveMap" or similar
- Map positioned at approximately (5000, 0, 0)
- Zombie spawn points visible (if visualized)
- Base camp exists

**Pass Criteria:**
- ✅ Map loads without errors
- ✅ Map is at position (5000, 0, 0) ± 10 studs
- ✅ "BaseCaptureZone" exists in Workspace
- ✅ No "map validation failed" errors

**Verification:**
```lua
-- Run in command bar:
local map = workspace:FindFirstChild("ActiveMap")
if map then
    print("Map found at:", map:GetPivot().Position)
else
    print("No map loaded")
end
```

---

### Test 2.2: Map with Missing Spawn Points

**Objective:** Verify error handling for invalid maps

**Steps:**
1. Create test map in ServerStorage.Maps
2. Name it "TestMap"
3. Do NOT add ZombieSpawns folder
4. Modify MapConfig to load TestMap
5. Start server

**Expected Results:**
```
[MapValidator] Map validation failed:
[MapValidator] - Insufficient zombie spawn points (found: 0, required: 8)
```

**Pass Criteria:**
- ✅ Clear error message
- ✅ Map is rejected
- ✅ Fallback to default map occurs

**Cleanup:**
- Remove test map
- Reset MapConfig

---

## Test Suite 3: Spawning System

### Test 3.1: Zombie Spawning

**Objective:** Verify zombies spawn correctly

**Steps:**
1. Start server + 1 test client
2. Join game as player
3. Wait for wave to start
4. Observe zombie spawning

**Expected Results:**
- Zombies appear near map (not at world origin)
- Zombies spawn at designated spawn points
- Zombies immediately start moving
- No "No spawn points available" errors

**Pass Criteria:**
- ✅ Zombies spawn within 50 studs of map center (5000, 0, 0)
- ✅ Zombies target player or base
- ✅ Multiple zombies spawn over time
- ❌ **FAIL if zombies spawn at (0, 0, 0)** - critical bug!

**Verification:**
```lua
-- Check zombie positions (run in command bar):
local zombiesFolder = workspace:FindFirstChild("Zombies")
if zombiesFolder then
    for _, zombie in ipairs(zombiesFolder:GetChildren()) do
        local pos = zombie:GetPivot().Position
        print(zombie.Name, "at", pos)
        
        -- Check if near map
        local distanceFromMap = (pos - Vector3.new(5000, 0, 0)).Magnitude
        print("Distance from map center:", distanceFromMap)
    end
end
```

---

### Test 3.2: Resource Spawning

**Objective:** Verify resources spawn during gameplay

**Steps:**
1. Start wave
2. Wait 30 seconds
3. Look for resource pickups in map area

**Expected Results:**
- Ammo boxes appear on ground
- Health packs appear
- Resources glow/highlight (if visual effects enabled)

**Pass Criteria:**
- ✅ Resources spawn within map bounds
- ✅ At least 1 resource spawns per 30 seconds
- ✅ No errors in output about spawn points

---

### Test 3.3: Spawn Queue Limit

**Objective:** Verify spawn queue doesn't grow infinitely

**Steps:**
1. Modify WaveConfig to spawn 1000 zombies immediately
2. Start wave
3. Monitor output for warnings

**Expected Results:**
```
[Spawner] Spawn queue full (500 zombies queued). Dropping Walker spawn to prevent memory leak.
```

**Pass Criteria:**
- ✅ Warning appears when queue hits 500
- ✅ Server doesn't crash
- ✅ Zombies still spawn (queue processes)

**Cleanup:**
- Reset WaveConfig to normal values

---

## Test Suite 4: AI & Combat

### Test 4.1: Zombie AI Targeting

**Objective:** Verify zombies can find and attack targets

**Steps:**
1. Start server + 1 client
2. Spawn as player
3. Wait for zombies to spawn
4. Observe zombie behavior

**Expected Results:**
- Zombies move toward player
- Zombies pathfind around obstacles
- Zombies attack when in range
- Player takes damage

**Pass Criteria:**
- ✅ Zombies actively pursue player
- ✅ Zombies don't get stuck
- ✅ Zombies deal damage on contact
- ✅ No errors about "nil target"

---

### Test 4.2: No-Target Scenario

**Objective:** Verify zombies don't crash when no targets exist

**Steps:**
1. Start server + 1 client
2. Spawn as player
3. Start wave (zombies spawn)
4. Kill player (set health to 0)
5. Destroy base: `workspace.BaseCaptureZone:Destroy()`
6. Observe zombie behavior

**Expected Results:**
```
[ZombieBrain] No valid targets available. Zombie will wander.
```

**Pass Criteria:**
- ✅ Zombies continue moving (wander behavior)
- ✅ No server crash
- ✅ No nil reference errors
- ✅ Warning logged about no targets

---

### Test 4.3: Player Disconnect During Combat

**Objective:** Verify no crash when player disconnects mid-attack

**Steps:**
1. Start server + 2 clients
2. Have zombies target Player 1
3. While zombie is attacking, disconnect Player 1
4. Check output for errors

**Expected Results:**
- No errors
- Zombie retargets to Player 2 or base
- Server continues normally

**Pass Criteria:**
- ✅ No errors logged
- ✅ Zombie switches target
- ✅ Player 2 gameplay unaffected

---

## Test Suite 5: UI & Client

### Test 5.1: Client Initialization

**Objective:** Verify client starts without errors

**Steps:**
1. Start server + 1 client
2. Check output window on client side

**Expected Results:**
```
=== AwavePuzz Client Controller Starting ===
[ClientController] Player: [PlayerName]
[ClientController] Configuration loaded
[ClientController] Initializing Camera...
[ClientController] ✓ Camera initialized
[ClientController] Initializing Movement...
[ClientController] ✓ Movement initialized
...
[ClientController] ✓✓✓ Client initialization complete ✓✓✓
```

**Pass Criteria:**
- ✅ All systems report initialization
- ✅ No errors
- ✅ UI elements appear on screen
- ⚠️ Warnings about missing assets acceptable

---

### Test 5.2: Duplicate Initialization Prevention

**Objective:** Verify UI doesn't initialize twice

**Steps:**
1. Start client
2. Search output for "initialized" messages
3. Count how many times each system reports initialization

**Expected Results:**
- Each system initializes exactly once
- No "Already initialized" warnings

**Pass Criteria:**
- ✅ Each system: 1 init message only
- ⚠️ Future improvement: Add guards to prevent duplicates

---

### Test 5.3: PC + Mobile Input Parity

**Objective:** Verify game works on both PC and mobile

**Steps:**

**PC Test:**
1. Start client
2. Use WASD to move
3. Use mouse to look
4. Click to shoot
5. Press E to interact

**Mobile Test (Touch Emulator):**
1. Enable touch emulator in Studio
2. Test Device: iPhone X or iPad Pro
3. Verify touch controls appear
4. Test virtual joystick for movement
5. Test touch to shoot

**Pass Criteria:**
- ✅ All inputs work on PC
- ✅ Touch controls appear on mobile
- ✅ Virtual joystick functional
- ✅ No input conflicts

---

## Test Suite 6: Integration Tests

### Test 6.1: Full Gameplay Loop

**Objective:** Verify complete round from start to finish

**Steps:**
1. Start server + 2 clients
2. Players join lobby
3. Game starts automatically
4. Play through wave 1
5. Survive or fail
6. Check for game over or wave 2

**Expected Results:**
- Lobby → Playing → Wave 1 → (Win/Lose) → Results
- No errors throughout
- All systems function

**Pass Criteria:**
- ✅ Complete round without errors
- ✅ Wave transitions correctly
- ✅ Win/lose conditions work
- ✅ Game can restart

---

### Test 6.2: Player Join Mid-Game

**Objective:** Verify late join handling

**Steps:**
1. Start server + 1 client (Player 1)
2. Start wave
3. Add 2nd client (Player 2) during wave
4. Observe Player 2 spawn

**Expected Results:**
- Player 2 joins successfully
- Player 2 spawns at base or designated spawn
- Player 2 receives current game state
- No errors

**Pass Criteria:**
- ✅ Late join succeeds
- ✅ Player 2 can play immediately
- ✅ Game state syncs correctly

---

### Test 6.3: Multiplayer Stress Test

**Objective:** Verify server handles multiple players + zombies

**Steps:**
1. Start server + 4-8 clients
2. All players join game
3. Start wave 5+ (many zombies)
4. Monitor server performance

**Expected Results:**
- Game remains playable (30+ FPS)
- No severe lag
- All players can interact

**Pass Criteria:**
- ✅ Server FPS > 30
- ✅ Client FPS > 30
- ✅ No timeout errors
- ⚠️ Minor lag acceptable with 50+ zombies

---

## Test Suite 7: Error Scenarios

### Test 7.1: Invalid Map Load

**Steps:**
1. Set MapConfig to load non-existent map
2. Start server

**Expected:**
```
[MapManager] Map not found: [MapName]
[MapManager] Falling back to default map
```

**Pass:** ✅ Fallback works, game continues

---

### Test 7.2: Service Initialization Failure

**Steps:**
1. Intentionally break AllianceService (syntax error)
2. Start server

**Expected:**
```
[MainServer] ✗ AllianceService failed to initialize: [error]
[MainServer] Server will continue with reduced functionality
```

**Pass:** ✅ Server continues, other services work

---

### Test 7.3: RemoteEvents Missing

**Steps:**
1. Disable RemoteEventsBootstrap
2. Start server

**Expected:**
```
[GameManager] CRITICAL: Failed to load RemoteEvents folder
```

**Pass:** ✅ Clear error within 10 seconds

---

## Pass/Fail Criteria Summary

### Must Pass (Critical):
1. ✅ Server starts without hangs
2. ✅ Map loads at (5000, 0, 0)
3. ✅ Zombies spawn near map (not at origin)
4. ✅ Client initializes without errors
5. ✅ No crashes with missing targets
6. ✅ No crashes on player disconnect

### Should Pass (High):
7. ✅ Resources spawn correctly
8. ✅ Spawn queue limit enforced
9. ✅ AI pathfinding works
10. ✅ UI works on PC + mobile
11. ✅ Late join works
12. ✅ Multiplayer stable with 4+ players

### Nice to Have (Medium):
13. ⚠️ Graceful error messages
14. ⚠️ Performance > 30 FPS with 50+ zombies
15. ⚠️ No duplicate UI initialization

---

## Bug Reporting Template

If you find a bug during testing:

```markdown
### Bug: [Short Description]

**Severity:** Critical / High / Medium / Low

**Test Suite:** [Test number that failed]

**Steps to Reproduce:**
1. 
2. 
3. 

**Expected Behavior:**


**Actual Behavior:**


**Output Log:**
```
[Paste relevant output]
```

**Environment:**
- Roblox Studio Version: 
- Operating System: 
- Players in Test: 

**Screenshots/Video:**
[Attach if available]
```

---

## Test Results Checklist

### Critical Tests (Must Pass):
- [ ] Test 1.1: Clean Server Start
- [ ] Test 2.1: Default Map Load
- [ ] Test 3.1: Zombie Spawning (NOT at origin!)
- [ ] Test 4.2: No-Target Scenario
- [ ] Test 4.3: Player Disconnect
- [ ] Test 5.1: Client Initialization

### High Priority Tests (Should Pass):
- [ ] Test 1.2: Missing Module Handling
- [ ] Test 2.2: Invalid Map Handling
- [ ] Test 3.2: Resource Spawning
- [ ] Test 3.3: Spawn Queue Limit
- [ ] Test 4.1: Zombie AI Targeting
- [ ] Test 5.3: PC + Mobile Parity
- [ ] Test 6.1: Full Gameplay Loop
- [ ] Test 6.2: Late Join
- [ ] Test 6.3: Multiplayer Stress

### Medium Priority Tests (Nice to Have):
- [ ] Test 5.2: No Duplicate Init
- [ ] Test 7.1: Invalid Map Fallback
- [ ] Test 7.2: Service Failure Graceful
- [ ] Test 7.3: RemoteEvents Error

---

## Testing Sign-Off

**Tested By:** ___________________  
**Date:** ___________________  
**Studio Version:** ___________________

**Result:** PASS / FAIL / CONDITIONAL PASS

**Critical Issues Found:** ___

**High Priority Issues Found:** ___

**Medium Priority Issues Found:** ___

**Notes:**




**Approved for Production:** YES / NO

---

**End of Verification Guide**
