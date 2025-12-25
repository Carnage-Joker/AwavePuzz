# Runtime Error Fixes - Smoke Test Guide

This document describes the fixes applied to resolve runtime errors identified in playtest logs and provides verification steps.

## Issues Fixed

### 1. SpawnGenerator Visualizer Dependency Error
**Problem:** `IntelligentSpawnGenerator` tried to require `ServerScriptService.Tests.SpawnPointVisualizer` which doesn't exist, causing error logs.

**Fix:** 
- Made visualizer loading optional and conditional on `RunService:IsStudio()` AND `GameConfig.DEBUG_SPAWNS`
- Uses safe `FindFirstChild` checks instead of direct require
- Only logs success message when visualizer loads, no error when missing
- Added `GameConfig.DEBUG_SPAWNS` flag (default: false)

**Verification:**
- No "Tests is not a valid member..." error in output
- Spawn generation still works correctly
- Set `DEBUG_SPAWNS = true` in GameConfig to enable visualization (Studio only)

---

### 2. StaminaUpdate RemoteEvent Queue Exhaustion
**Problem:** Server fired `StaminaUpdate` events but client wasn't receiving them properly, causing queue overflow (2048+ dropped events).

**Root Cause:** FPSMovement module received the RemoteEvent but wasn't forwarding the `isSprinting` flag to the HUD bindable event.

**Fix:**
- FPSMovement now forwards all data including `isSprinting` to PlayerHUD
- Added server-side change detection (only sends when stamina changes >0.5 OR sprint state changes)
- Maintains existing 0.1s rate limiting

**Verification:**
- No "invocation queue exhausted" warnings
- Stamina bar updates smoothly in UI
- Sprint indicator shows/hides correctly when sprinting

---

### 3. ClientController Module Discovery
**Problem:** Potential timing issues with Modules folder not being found during initialization.

**Fix:**
- Extended WaitForChild timeout from 5s to 10s
- Improved error message to show full path if folder missing
- All modules exist in correct locations (no creation of empty folders)

**Verification:**
- No "module not found" warnings during startup
- Camera, Movement, Weapon, Animation, Audio, Music systems initialize correctly
- UI systems load successfully

---

### 4. UITextSizeConstraint Min/Max Inversion
**Problem:** "MaxFontSize smaller than MinFontSize" warnings when UI elements use TextScaled.

**Fix:**
- Added `UIScaleManager.enableTextScaled(textLabel, minSize, maxSize)` helper function
- Added `UIScaleManager.fixTextSizeConstraints(guiObject)` to repair existing constraints
- Both ensure MinTextSize <= MaxTextSize

**Verification:**
- No "MaxFontSize smaller than MinFontSize" warnings
- Text scaling works correctly across different screen sizes
- Call `UIScaleManager.fixTextSizeConstraints(playerGui)` to fix existing UI

**Usage Example:**
```lua
-- Instead of:
label.TextScaled = true

-- Use:
UIScaleManager.enableTextScaled(label, 10, 24)

-- Or fix existing UI:
UIScaleManager.fixTextSizeConstraints(playerGui)
```

---

### 5. Invalid GuiService.SelectedObject Warnings
**Problem:** "Setting GuiService.SelectedObject to invalid GuiObject" warnings during menu operations and character respawn.

**Fix:**
- Clear `GuiService.SelectedObject` when menu closes (FPSMenuController)
- Clear on character spawn/removal (ClientController)
- Wrapped in pcall for safety

**Verification:**
- No invalid SelectedObject warnings when opening/closing menus
- No warnings on character respawn
- Gamepad/console UI navigation still works

---

## Smoke Test Checklist

After applying these fixes, run the following test:

### Setup
1. Open project in Roblox Studio
2. Start a local server test with 1-2 players

### Test Steps
1. **Pass title/epilogue screens**
   - ✓ No SpawnGenerator errors in output
   
2. **Enter lobby and start wave**
   - ✓ Spawn points generate successfully
   - ✓ No visualizer errors
   
3. **Sprint and move for 30 seconds**
   - ✓ No StaminaUpdate queue warnings
   - ✓ Stamina bar updates smoothly
   - ✓ Sprint indicator appears when sprinting
   
4. **Open and close pause menu 3-4 times**
   - ✓ No SelectedObject warnings
   - ✓ Menu navigation works
   
5. **Die and respawn (if possible)**
   - ✓ No SelectedObject warnings
   - ✓ UI resets correctly
   
6. **Check Studio output**
   - ✓ No "Tests is not a valid member" errors
   - ✓ No "invocation queue exhausted" warnings
   - ✓ No "MaxFontSize smaller than MinFontSize" warnings
   - ✓ No "invalid GuiObject" warnings
   - ✓ All ClientController systems initialize successfully

### Expected Output
Clean startup with messages like:
```
[SpawnGenerator] Map bounds: ...
[SpawnGenerator] Target spawn points: ...
[ClientController] ✓ Camera initialized
[ClientController] ✓ Movement initialized
[ClientController] ✓ Weapon system initialized
[ClientController] ✓ Animations initialized
[ClientController] ✓ Audio initialized
[ClientController] ✓ Music initialized
[ClientController] ✓ Menu initialized
[ClientController] ✓ UI systems initialized
[ClientController] ✓✓✓ Client initialization complete ✓✓✓
```

---

## Notes

### Debug Spawn Visualization
To enable spawn point visualization for debugging:
1. Open `ReplicatedStorage/Shared/GameConfig.lua`
2. Set `GameConfig.DEBUG_SPAWNS = true`
3. Create `ServerScriptService/Tests/SpawnPointVisualizer.lua` module
4. Only works in Studio mode

### Rate Limiting
StaminaUpdate now sends:
- Every 0.1 seconds minimum (10 Hz)
- Only when stamina changes by >0.5 OR sprint state toggles
- This prevents ~99% of redundant updates

### UI Constraints
When creating new UI with TextScaled:
- Use `UIScaleManager.enableTextScaled()` helper
- Or manually ensure MinTextSize <= MaxTextSize
- Run `UIScaleManager.fixTextSizeConstraints(playerGui)` to repair existing UI

### GuiService Selection
The system now automatically clears GUI selection on:
- Menu close
- Character spawn
- Character death
This prevents console/gamepad navigation from holding stale references.
