# Runtime Issue Fixes - 2026-01-21

## Summary
Fixed four critical startup/runtime issues that were causing errors in Roblox output:

## 1. MainServer.lua GameConfig Nil Index Error

**Issue**: Line 181 attempted to access `GameConfig.MIN_PLAYERS_TO_START` but GameConfig was never required.

**Error Message**: 
```
ServerScriptService.MainServer line ~181 throws:
"attempt to index nil with 'MIN_PLAYERS_TO_START'"
```

**Fix**:
- Added `require(SharedFolder:WaitForChild("GameConfig"))` at the top of MainServer.lua
- Added safe fallback checks with warning message if config field is missing
- Default value of 1 player minimum ensures server never crashes

**Files Changed**: `ServerScriptService/MainServer.lua`

## 2. WeaponService Anti-Cheat Rejecting Valid Shots

**Issue**: WeaponService was rejecting legitimate shots in first-person mode due to direction validation comparing against head's LookVector instead of HumanoidRootPart.

**Error Message**:
```
"Rejected shot ... direction not aligned with look vector (dot: -0.99)"
```

**Root Cause**: In first-person mode, the head's rotation doesn't always match the camera's direction, leading to false positives.

**Fix**:
- Changed validation to use `HumanoidRootPart.CFrame.LookVector` instead of `head.CFrame.LookVector`
- Adjusted threshold from 0.3 (70° cone) to -0.5 (120° cone) to allow FPS camera freedom
- This prevents backward shots while allowing shots in the front half of the player
- Added temporary debug logging with detailed position/direction info for further diagnostics

**Files Changed**: `ServerScriptService/WeaponService.lua`

**Note**: The threshold can be further adjusted in `GameConfig.Security.MIN_WEAPON_FIRE_DOT_PRODUCT` if needed.

## 3. Invalid Sound Asset ID

**Issue**: Sound asset ID `rbxassetid://86072977471971` was causing "Asset type mismatch" errors.

**Error Message**:
```
"Asset type mismatch for sound id rbxassetid://86072977471971"
```

**Root Cause**: 
- Asset ID is 15 digits long (typical Roblox asset IDs are 9-13 digits)
- Asset ID was not found in Lua code, likely stored in a Roblox place file (ServerStorage/Workspace)
- The asset might point to a non-sound asset type

**Fix**:
- Added validation in `FPSAudioController.createSound()` to reject asset IDs longer than 13 digits
- Added `pcall()` guards around sound creation and playback to prevent crashes
- Invalid sounds now log warnings instead of crashing

**Files Changed**: `StarterPlayer/StarterPlayerScripts/Modules/FPSAudioController.lua`

**Manual Action Required**: 
In Roblox Studio, search ServerStorage and Workspace for Sound objects with invalid asset IDs and replace them with valid sound assets or remove them.

## 4. Invalid Animation Asset IDs

**Issue**: Animation asset IDs in FPSConfig were invalid (15-digit IDs like `rbxassetid://107261819756829`).

**Error Message**:
```
"Invalid animation id rbxassetid://107261819756829"
```

**Root Cause**: Asset IDs were too long to be valid Roblox animation IDs.

**Fix**:
- Replaced all invalid animation IDs in `FPSConfig.WeaponAnimations` with placeholder `"rbxassetid://0"`
- Existing `FPSAnimationController.loadAnimation()` already had `pcall()` guards to prevent crashes
- Invalid animations now return nil gracefully without spamming warnings

**Files Changed**: `ReplicatedStorage/Shared/FPSConfig.lua`

**Manual Action Required**:
Replace placeholder animation IDs with valid Roblox animation assets created in Roblox Studio.

## Testing Instructions

### In Roblox Studio:

1. **Verify Server Startup**:
   - Open the place in Roblox Studio
   - Click "Play" to start the server
   - Check Output window - should see no red errors about GameConfig
   - Should see: `"=== Aether Wave: Convergence Server Starting ==="`

2. **Test Weapon Shooting**:
   - Start a test server with 2+ players
   - Equip a weapon and fire in first-person mode
   - Should NOT see "Rejected shot" warnings in Output
   - Shots should register and damage zombies/players

3. **Check Asset Loading**:
   - Monitor Output for any "Asset type mismatch" errors
   - Should see at most warnings about missing placeholder assets (expected)
   - Should NOT see crashes or spam

4. **Verify Animations**:
   - Equip weapons and perform actions
   - Animations may not play (using placeholders) but should not error
   - Check Output for excessive animation warnings

### Expected Clean Output:
```
=== Aether Wave: Convergence Server Starting ===
AllianceService initialized
GameManager initialized
...
Server Ready ===
Waiting for players...
```

### Debug Logging (Temporary):
If weapon shots are still rejected, check the detailed debug output:
```
[WeaponService] SECURITY: Rejected shot from PlayerName - direction not aligned...
  Origin: (x, y, z), Direction: (x, y, z)
  HRP Position: (x, y, z), HRP LookVector: (x, y, z)
```

This helps diagnose if further threshold adjustment is needed.

## Configuration Options

### Security Threshold Adjustment:
If you want stricter weapon validation, add to `GameConfig.lua`:

```lua
GameConfig.Security = {
    MIN_WEAPON_FIRE_DOT_PRODUCT = 0.3,  -- 70° cone (stricter)
    MAX_WEAPON_FIRE_DISTANCE = 15,      -- Maximum distance from player
}
```

### Player Count Adjustment:
Change minimum players required to start:

```lua
GameConfig.MIN_PLAYERS_TO_START = 2  -- Recommended for alliance mechanics
```

## Summary of Changes

| File | Lines Changed | Description |
|------|--------------|-------------|
| `ServerScriptService/MainServer.lua` | +13, -1 | Added GameConfig require and safe fallbacks |
| `ServerScriptService/WeaponService.lua` | +30, -18 | Fixed direction validation and added debug logging |
| `ReplicatedStorage/Shared/FPSConfig.lua` | +10, -10 | Replaced invalid animation IDs with placeholders |
| `StarterPlayer/.../FPSAudioController.lua` | +34, -2 | Added validation and pcall guards for sounds |

**Total**: 78 insertions, 29 deletions across 4 files

## Future Cleanup

Once the fixes are confirmed working:
1. Remove debug logging from `WeaponService.lua` (lines with "Temporary debug logging")
2. Replace placeholder animation IDs with actual Roblox animation assets
3. Fix or remove invalid sound assets in Roblox place file
