# Death Tracking Table Leak Test (BUG-013)

## Purpose
This test verifies that the memory leak fix for BUG-013 is working correctly by simulating 1000 player join/leave cycles and ensuring no table growth occurs.

## What It Tests
This automated test checks that the following tables in `GameManager.lua` are properly cleaned up when players leave:
- `playerStats` - Player kill/death statistics
- `_deathDebounce` - Death event debouncing
- `_spectatorCycleCooldown` - Spectator mode cooldowns
- `playersReadyForEpilogue` - Epilogue readiness tracking
- `playersCompletedEpilogue` - Epilogue completion tracking

Note: The BUG-013 fix also includes cleanup for `_deathConnections` (death event connections) and `_characterAddedConnections` (CharacterAdded event connections), but the current `death_tracking_table_leak_test.lua` script does not populate those tables and therefore does not directly validate their cleanup. Use Method 2 (Manual Verification) below if you need to inspect those tables explicitly.
## How to Run in Roblox Studio

### Method 1: Direct Test (Recommended)
1. Open your Roblox Studio project
2. Copy the contents of `death_tracking_table_leak_test.lua`
3. Create a new Script in `ServerScriptService`
4. Paste the test code
5. Run the game
6. Check the Output window for results

### Method 2: Manual Verification
If you can't run the automated test (due to GameManager dependencies), you can manually verify:

1. Open Roblox Studio and start a test server
2. Open the Developer Console (F9)
3. Add this code to a temporary Script in ServerScriptService:
```lua
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Find the MainServer script that has the GameManager instance
local mainServer = ServerScriptService:WaitForChild("Main", 10)
if not mainServer then
    warn("Could not find Main.server.lua")
    return
end

-- Monitor table sizes
local function checkTableSizes()
    -- This assumes you can access the GameManager instance
    -- You may need to modify Main.server.lua to expose it for testing
    print("=== Table Size Check ===")
    -- Add your monitoring code here
end

-- Run check every 10 seconds
while true do
    task.wait(10)
    checkTableSizes()
end
```

## Expected Results

### ✅ Test Passes When:
- Total table growth: 0 entries
- All tested tables show +0 growth after 1000 player cycles
- Output shows: "✅ TEST PASSED - No memory leaks detected!"

### ❌ Test Fails When:
- Any table shows positive growth
- Output shows specific tables that are leaking
- Example: "❌ playerStats: +1000 entries (LEAK)"

## Understanding the Results

The test creates 1000 mock players, initializes their data in the tracked tables, then calls `onPlayerRemoving()` for each. If the cleanup code is working correctly, all table entries should be removed, resulting in zero growth.

### Before the Fix
Without the BUG-013 fix, you would see:
```
❌ TEST FAILED - Memory leak detected!
The following tables are leaking:
  ❌ playerStats: +1000 entries (LEAK)
  ❌ _characterAddedConnections: +1000 entries (LEAK)
```

### After the Fix
With the fix applied, you should see:
```
✅ TEST PASSED - No memory leaks detected!
All tables properly cleaned up on player removal.
```

## Troubleshooting

### "Failed to load GameManager"
- Make sure you're running this in a Roblox Studio environment with the full game code
- Check that GameManager.lua exists in ServerScriptService

### "Cannot create GameManager instance"
- The GameManager may be a singleton
- You may need to access the existing instance instead of creating a new one
- Check Main.server.lua for how GameManager is instantiated

### Dependencies Not Found
- The test requires all GameManager dependencies to be present
- Make sure your Roblox Studio project is fully synced
- Check that ReplicatedStorage/Shared folder exists with all config files

## Related Files
- `ServerScriptService/GameManager.lua` - The file being tested
- `BUG_FIX_CHECKLIST.md` - Bug tracking checklist (BUG-013)

## Success Criteria
This test satisfies the BUG-013 requirement:
> Test: Tables don't grow after 1000 player joins

When this test passes, you can mark BUG-013 as complete in the checklist.
