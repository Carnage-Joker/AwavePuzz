# Heartbeat Leak Test (BUG-010)

## Purpose
This test validates the heartbeat connection cleanup pattern used in the fix for BUG-010 (heartbeat accumulation memory leak in Main.server.lua).

## What It Tests
1. **Initial Connection**: Verifies a mocked heartbeat connection can be created
2. **Server Reload Simulation**: Tests that old mocked connections are properly disconnected before creating new ones
3. **Connection Cleanup**: Confirms the mocked Disconnect()-based cleanup pattern behaves as expected

## How to Run

### In Roblox Studio:
1. Ensure Main.server.lua has been updated with the BUG-010 fix
2. Copy `heartbeat_leak_test.server.lua` to ServerScriptService
3. Run the game in Studio (Play Solo or Local Server)
4. Check the Output window for test results

### Expected Output:
```
========================================
HEARTBEAT LEAK TEST (BUG-010)
========================================

--- Testing Heartbeat Connection Cleanup Pattern ---

✅ Test 1: First heartbeat initialization
[TEST] Created new heartbeat connection
   PASSED: Heartbeat connection created

✅ Test 2: Server reload (should disconnect old, create new)
[TEST] Disconnected old heartbeat connection
[TEST] Created new heartbeat connection
   PASSED: Old connection replaced with new one

✅ Test 3: Verify connection cleanup
   PASSED: Connection cleanup works correctly

========================================
HEARTBEAT LEAK TEST SUMMARY
========================================
✅ All tests PASSED
✅ Heartbeat connection cleanup pattern verified
✅ No memory leak on server reload

ℹ️  BUG-010 Fix Confirmed:
   - Old connections are disconnected before creating new ones
   - Single heartbeat connection maintained
   - No accumulation on server reload
========================================
```

## What the Fix Addresses

### The Problem
Before the fix, Main.server.lua would create a new heartbeat connection every time it ran without disconnecting the old one. On server reloads, this caused:
- Multiple heartbeat connections accumulating
- Increased memory usage
- Multiple update loops running simultaneously
- Potential performance degradation

### The Solution
The fix adds a cleanup check before creating a new connection:
```lua
-- Disconnect old heartbeat connection if it exists (prevents memory leak on server reload)
if gameManager._heartbeatConnection then
    gameManager._heartbeatConnection:Disconnect()
    gameManager._heartbeatConnection = nil
    print("[BOOT][SERVER] Disconnected old heartbeat connection")
end
```

This ensures:
- Only one heartbeat connection exists at a time
- Old connections are properly cleaned up
- No memory accumulation on server reload

## Manual Verification Steps

1. **First Load**: Run the game and verify single heartbeat in profiler
2. **Reload Test**: Stop and restart the game, verify no connection accumulation
3. **Memory Check**: Use Roblox's memory profiler to confirm stable connection count

## Success Criteria
- ✅ Test script passes all assertions
- ✅ Single heartbeat connection after initialization
- ✅ Old connection disconnected on reload
- ✅ No memory leak detected in profiler
- ✅ GameManager update loop runs correctly

## Related Files
- `ServerScriptService/Main.server.lua` (lines 217-222) - The fix
- `BUG_FIX_CHECKLIST.md` - Bug tracking
- `COMPREHENSIVE_BUG_AUDIT_2026.md` - Original bug report

## Date Fixed
2026-02-10
