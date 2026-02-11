# Weapon State Race Condition Test (BUG-008)

## Overview
This test validates the fix for BUG-008: Weapon state race condition that affected late joiners.

## Problem
When players joined late or spawned for the first time, the `weaponStats` variable in FPSWeaponController.lua might not be immediately available when the `AmmoUpdate` event fired. This caused:
- Players unable to shoot on first spawn
- Missing weapon information in UI
- Potential crashes when accessing nil weaponStats

## Fix
The fix implements:
1. **Validation**: Check if `weaponStats` is nil before using it
2. **Immediate Retry**: Attempt to fetch weaponStats if it's nil
3. **Delayed Retry**: If still nil, retry after 1 second delay using `task.delay()`
4. **Fallback**: Use default magazine size if weaponStats still unavailable

## Running the Test

### Method 1: Roblox Studio Server Console
1. Open Roblox Studio with the AwavePuzz project
2. Start a local server with at least 1 player
3. Open the Server console (View → Output → Server)
4. Paste and run the contents of `weapon_state_race_condition_test.lua`

### Method 2: Script Insertion
1. Copy `weapon_state_race_condition_test.lua` into ServerScriptService
2. Set it as a Script (not LocalScript)
3. Start a test server
4. The test will run automatically and output results to the console

## Test Cases

### Test 1: Late Joiner Weapon Stats Available
- **Purpose**: Verify that ammo updates can be sent to late joiners
- **Method**: Simulates sending an AmmoUpdate event to a player
- **Expected**: Event fires successfully without errors

### Test 2: Weapon Stats Retry Logic
- **Purpose**: Verify the retry logic with 1-second delay
- **Method**: Sends ammo update without `max` field to trigger weaponStats lookup
- **Expected**: Client attempts to fetch weaponStats and retries after 1 second if nil

### Test 3: Late Joiner Can Shoot on First Spawn
- **Purpose**: End-to-end test of late joiner weapon functionality
- **Method**: 
  1. Loads player character
  2. Sends WeaponLoadoutUpdate
  3. Sends AmmoUpdate
  4. Player should be able to shoot
- **Expected**: Player can shoot immediately after spawn

## Manual Verification Required

Due to the client-side nature of the fix, manual verification is required:

1. **Enable Debug Logging**:
   - In `FPSWeaponController.lua`, set `DEBUG_AMMO = true` (line 20)
   
2. **Join as Late Player**:
   - Start a game server
   - Join as a player after the game has started
   - Check the client console for messages:
     - `⚠ weaponStats nil at ammo update` (if race condition occurs)
     - `⚠ weaponStats still nil, scheduling retry in 1s` (retry triggered)
     - `✓ weaponStats loaded on retry` (retry successful)

3. **Verify Shooting**:
   - As soon as you spawn, try to shoot (Left Click)
   - Weapon should fire successfully
   - No errors should appear in client console

4. **Check UI**:
   - Ammo counter should display correctly
   - Weapon name should be visible
   - Max ammo should update to the correct value after retry (may briefly show default value while weaponStats loads)

## Expected Results

### Success Criteria
✅ All 3 tests pass without errors  
✅ Late joiners can shoot immediately on spawn  
✅ No client-side errors when weaponStats is temporarily nil  
✅ Retry logic executes correctly (visible in debug logs)  
✅ Weapon UI displays correctly for late joiners  

### Failure Indicators
❌ Client errors when accessing nil weaponStats  
❌ Late joiners cannot shoot on first spawn  
❌ Ammo counter shows incorrect values  
❌ Weapon name missing in UI  
❌ Player has no weapon equipped after spawn  

## Implementation Details

The fix is located in `StarterPlayer/StarterPlayerScripts/Modules/FPSWeaponController.lua` at lines 493-588 (including the continuation of the original ammo update logic after the fix block):

```lua
-- BUG-008 FIX: Validate weaponStats before using to prevent race condition
-- For late joiners, weaponStats may not be loaded yet
if not weaponStats then
    if DEBUG_AMMO then
        warn(string.format("[FPSWeaponController] ⚠ weaponStats nil at ammo update, attempting to fetch for weapon '%s'", 
            tostring(data.weaponId)))
    end
    
    -- Try to fetch weaponStats
    weaponStats = getWeaponStats(data.weaponId)
    
    -- BUG-008 FIX: If still nil, retry after configured delay
    if not weaponStats then
        if DEBUG_AMMO then
            warn(string.format("[FPSWeaponController] ⚠ weaponStats still nil, scheduling retry in %.1fs for weapon '%s'", 
                WEAPON_STATS_RETRY_DELAY, tostring(data.weaponId)))
        end
        
        -- Capture the data locally to avoid race conditions with future AmmoUpdate events
        local capturedData = {
            weaponId = data.weaponId,
            current = data.current,
            reserve = data.reserve,
            max = data.max
        }
        
        -- Schedule retry with configured delay
        task.delay(WEAPON_STATS_RETRY_DELAY, function()
            -- Only retry if we're still using the same weapon
            if currentWeapon ~= capturedData.weaponId then
                if DEBUG_AMMO then
                    print(string.format("[FPSWeaponController] Skipping retry - weapon changed from '%s' to '%s'", 
                        tostring(capturedData.weaponId), tostring(currentWeapon)))
                end
                return
            end
            
            local retryStats = getWeaponStats(capturedData.weaponId)
            if retryStats then
                -- Update the module-level weaponStats
                weaponStats = retryStats
                
                if DEBUG_AMMO then
                    print(string.format("[FPSWeaponController] ✓ weaponStats loaded on retry for weapon '%s'", 
                        tostring(capturedData.weaponId)))
                end
                
                -- Update weapon info now that stats are available
                updateWeaponInfo(capturedData.weaponId)
                
                -- Re-apply the ammo values with newly loaded weaponStats
                local maxAmmo = capturedData.max
                if not maxAmmo and retryStats.MagSize then
                    maxAmmo = retryStats.MagSize
                end
                if not maxAmmo then
                    maxAmmo = DEFAULT_MAGAZINE_SIZE
                end
                
                ammoUpdateBindable:Fire({
                    current = capturedData.current,
                    reserve = capturedData.reserve,
                    max = maxAmmo,
                    isReloading = false
                })
                
                if DEBUG_AMMO then
                    print(string.format("[FPSWeaponController] ✓ Ammo re-applied on retry: %s (current=%d, reserve=%d, max=%d)", 
                        capturedData.weaponId, capturedData.current, capturedData.reserve, maxAmmo))
                end
            else
                warn(string.format("[FPSWeaponController] ✗ weaponStats still nil after retry for weapon '%s'", 
                    tostring(capturedData.weaponId)))
            end
        end)
    end
end
```

## Related Issues
- BUG-005: Kill tracking after respawn
- BUG-006: Cure station interaction fixes
- BUG-009: Server-authoritative reload state

## Notes
- The test requires at least 1 player in the server
- Some verification must be done manually on the client side
- Debug logging (`DEBUG_AMMO = true`) helps verify the retry logic
- The 1-second retry delay is a balance between responsiveness and resource usage
