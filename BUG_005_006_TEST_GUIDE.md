# Testing Guide for BUG-005 and BUG-006 Fixes

This guide provides step-by-step instructions for testing the fixes for BUG-005 and BUG-006.

---

## Automated Tests

Both bugs have automated test scripts that can be run in Roblox Studio.

### Running the Tests

1. Open the project in Roblox Studio
2. Open the Server Console (View → Output)
3. Run the test commands below

#### Test BUG-005 (Kill Tracking After Respawn)

**Command:**
```lua
dofile(game.ServerScriptService.Parent.Parent.tests.kill_tracking_respawn_test)
```

Or if tests are in ServerStorage:
```lua
require(game.ServerStorage.tests.kill_tracking_respawn_test)
```

**Expected Output:**
```
==============================================
=== KILL TRACKING RESPAWN TEST (BUG-005) ====
==============================================

--- Test 1: Kill Tracking After Multiple Respawns ---
✅ Initial character has no kill tracking attributes
✅ Respawn 1: Kill tracking attributes cleared successfully
✅ Respawn 2: Kill tracking attributes cleared successfully
✅ Respawn 3: Kill tracking attributes cleared successfully
✅ Test 1 PASSED: Kill tracking attributes cleared on all respawns

--- Test 2: Died Event Can Be Reconnected After Respawn ---
✅ Test 2 PASSED: Can reconnect Died event after respawn

==============================================
TEST SUMMARY
==============================================
Tests Passed: 2 / 2

✅ ALL TESTS PASSED!
BUG-005 (Kill tracking after respawn) has been fixed.
```

#### Test BUG-006 (Portal Queue Corruption)

**Command:**
```lua
require(game.ServerStorage.tests.portal_queue_corruption_test)
```

**Expected Output:**
```
==============================================
=== PORTAL QUEUE CORRUPTION TEST (BUG-006) ==
==============================================

--- Test 1: Per-Portal Debounce Keys ---
✅ Test 1 PASSED: Per-portal debounce keys working correctly

--- Test 2: Atomic Queue Duplicate Prevention ---
✅ Test 2 PASSED: Atomic duplicate prevention working correctly

--- Test 3: Rapid Portal Touch Simulation ---
✅ Test 3 PASSED: Rapid portal touches prevented duplication

--- Test 4: Different Portal Touch Not Debounced ---
✅ Test 4 PASSED: Player can switch between different portals

==============================================
TEST SUMMARY
==============================================
Tests Passed: 4 / 4

✅ ALL TESTS PASSED!
BUG-006 (Portal queue corruption) has been fixed.
```

---

## Manual Testing

Manual testing is recommended to verify the fixes work in actual gameplay scenarios.

### BUG-005: Kill Tracking After Respawn

**Scenario**: Verify kill rewards are granted on each death, not just the first.

**Prerequisites:**
- 2 players in the game
- Both players have weapons

**Test Steps:**

1. **Setup**
   - Player A (Attacker) and Player B (Victim) join the game
   - Note Player A's currency/kill count before test

2. **First Kill**
   - Player A shoots and kills Player B
   - Verify Player A receives kill reward (check currency increase)
   - Note the reward amount

3. **Second Kill** (Testing respawn fix)
   - Wait for Player B to respawn
   - Player A shoots and kills Player B again
   - **Expected**: Player A receives kill reward again (same amount as first kill)
   - **Bug behavior**: Player A would NOT receive reward on second kill

4. **Third Kill** (Confirm consistency)
   - Wait for Player B to respawn
   - Player A shoots and kills Player B a third time
   - **Expected**: Player A receives kill reward again

**Success Criteria:**
- ✅ Kill rewards granted on all 3 kills
- ✅ Reward amounts are consistent
- ✅ No errors in Output console
- ✅ Alliance service notified of kills (if alliances enabled)

**Debug Verification:**

Check the Output console for these messages:
```
[WeaponService] PvP Kill: PlayerA eliminated PlayerB
```

This should appear for each kill, not just the first one.

---

### BUG-006: Portal Queue Corruption

**Scenario**: Verify rapid portal touches don't add players to queue multiple times.

**Prerequisites:**
- Lobby area with at least 1 portal configured
- Portal visual indicator showing queue count

**Test Steps:**

1. **Setup**
   - Player joins the game in lobby
   - Locate a portal (should have a queue indicator showing "0/8")

2. **Rapid Touch Test**
   - Rapidly touch/click the portal multiple times (10+ touches in 1 second)
   - **Expected**: Player added to queue only once
   - **Bug behavior**: Player would appear in queue multiple times
   - Check portal indicator shows "1/8" (not "2/8" or higher)

3. **Multiple Players Test** (if 2+ players available)
   - Have 2 players rapidly touch the same portal
   - **Expected**: Queue shows "2/8"
   - **Bug behavior**: Queue might show "3/8" or "4/8" due to duplicates

4. **Portal Switching Test**
   - Player touches Portal A (joins queue)
   - Player immediately touches Portal B
   - **Expected**: Player removed from Portal A queue, added to Portal B queue
   - **Bug behavior**: Debounce might prevent portal switching

5. **Same Portal Re-touch Test**
   - Player in Portal A queue
   - Player touches Portal A again immediately
   - **Expected**: No duplicate entry, still "1/8"
   - **Bug behavior**: Might add player again, showing "2/8"

**Success Criteria:**
- ✅ Rapid touches only add player once
- ✅ Queue count matches actual player count
- ✅ Portal switching works immediately (no debounce blocking)
- ✅ Re-touching same portal doesn't create duplicates
- ✅ No errors in Output console

**Debug Verification:**

Check the Output console for these messages:

```
[PortalMatchmakingService] Player PlayerName joined portal PortalA queue (1/8)
```

If you see:
```
[PortalMatchmakingService] Player PlayerName already in portal PortalA queue (duplicate prevented)
```

This is **correct** - it means the duplicate prevention is working.

---

## Edge Case Testing

### BUG-005 Edge Cases

1. **Rapid Respawn**
   - Kill player, immediately force respawn
   - Verify attributes cleared even with rapid respawn

2. **Multiple Attackers**
   - Have Player A damage Player B, then Player C kills Player B
   - Verify Player C gets credit (LastAttackerUserId updates correctly)

3. **Respawn During Combat**
   - Start combat, trigger respawn before death
   - Verify attributes cleared on new character

### BUG-006 Edge Cases

1. **Portal Lock During Touch**
   - Have 7 players in queue (almost full)
   - 8th player touches rapidly as portal locks
   - Verify no duplicates even during lock transition

2. **Player Disconnect During Queue**
   - Join portal queue
   - Disconnect player
   - Verify queue cleaned up (not tested by automated test)

3. **Concurrent Portal Touches**
   - Have 4 players touch different portals simultaneously
   - Verify each player in correct portal queue (no cross-contamination)

---

## Performance Testing

### BUG-005 Performance

**Test**: Measure attribute clearing overhead
- Have player respawn 100 times
- Monitor frame time in Output
- **Expected**: < 1ms per respawn

### BUG-006 Performance

**Test**: Measure queue operation performance
- Simulate 50 rapid portal touches
- Monitor frame time in Output
- **Expected**: All touches processed < 50ms total

---

## Troubleshooting

### BUG-005 Issues

**Problem**: Attributes not cleared on respawn

**Debug Steps:**
1. Check Output for "[STATE] Player X's character loaded"
2. Verify humanoid exists: `print(player.Character:FindFirstChild("Humanoid"))`
3. Check attributes manually:
   ```lua
   local humanoid = player.Character.Humanoid
   print("DiedConnected:", humanoid:GetAttribute("WeaponServiceDiedConnected"))
   print("LastAttacker:", humanoid:GetAttribute("LastAttackerUserId"))
   ```

**Problem**: Kill rewards still not granted on respawn

**Debug Steps:**
1. Verify attributes ARE cleared (see above)
2. Check WeaponService is setting them on damage
3. Check Died event is actually firing

### BUG-006 Issues

**Problem**: Still seeing duplicate queue entries

**Debug Steps:**
1. Check Output for duplicate prevention messages
2. Verify debounce key format: `print(debounceKey)` should show "userId_portalId"
3. Check if race condition still occurring (very rare)

**Problem**: Portal switching not working

**Debug Steps:**
1. Check if portal is locked (can't switch to locked portal)
2. Verify removePlayerFromQueue is being called
3. Check Output for queue join/leave messages

---

## Reporting Issues

If tests fail or manual testing reveals issues:

1. **Capture Console Output**: Copy all messages from Output window
2. **Note Exact Steps**: Record exact sequence of actions that caused the issue
3. **Environment Details**: 
   - Roblox Studio version
   - Number of players in test
   - Which test failed
4. **Expected vs Actual**: Clearly state what should happen vs what did happen

---

## Success Criteria Summary

Both fixes are considered successful when:

### BUG-005
- ✅ Automated tests pass (2/2)
- ✅ Manual test: 3 consecutive kills all grant rewards
- ✅ Attributes cleared on every respawn
- ✅ No errors in console

### BUG-006  
- ✅ Automated tests pass (4/4)
- ✅ Manual test: Rapid touches only add once
- ✅ Portal switching works immediately
- ✅ Queue counts accurate
- ✅ No errors in console

---

**Last Updated**: 2026-02-10  
**Related Documents**: 
- `BUG_005_006_FIX_SUMMARY.md` - Detailed fix documentation
- `BUG_FIX_CHECKLIST.md` - Overall bug tracking
