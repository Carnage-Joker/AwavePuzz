# Weapon Origin Reconstruction Test

## Purpose

This test suite validates the server-authoritative origin reconstruction feature that fixes "origin behind player" false rejections in WeaponService.

## Problem Solved

The previous implementation validated client-provided shot origins, which led to false rejections due to:
- Camera offset from player head (FirstPersonOffset)
- Client/server position sync delays
- Rounding errors in position calculations
- Shoulder-cam or shift-lock camera positions

These caused legitimate shots to be rejected with errors like:
```
[WeaponService] SECURITY: Rejected shot from Player - origin behind player (localZ=-3.x)
```

## Solution

The server now **reconstructs the shot origin** from the player's character instead of trusting client data:
1. Server takes player's **Head position**
2. Adds **vertical offset** (0.5 studs) for camera height
3. Adds **forward offset** (2.0 studs) in the aim direction
4. Uses this reconstructed origin for all raycasts

This eliminates client/server mismatch while maintaining security.

## What This Test Validates

### Configuration Tests
- ✅ Server origin reconstruction is enabled
- ✅ Origin offsets are configured (forward, vertical)
- ✅ Behind-body tolerance is configured

### Method Tests
- ✅ `reconstructOrigin()` method exists in WeaponService
- ✅ Method can be called without errors

### Validation Tests
- ✅ Direction alignment validation is preserved (anti-wallhack)
- ✅ Rate limiting is preserved (anti-spam)
- ✅ Legacy validation fallback is available

## Running the Test

### In Roblox Studio

1. Open the game in Roblox Studio
2. Open the Command Bar (View → Command Bar)
3. Run:
```lua
local test = require(game.ServerScriptService.Tests.weapon_origin_reconstruction_test)
test.runAll()
```

### Expected Output

```
============================================================
WEAPON ORIGIN RECONSTRUCTION TEST SUITE
Tests for server-authoritative origin reconstruction
============================================================

--- Configuration Tests ---
✅ PASS: Config - Server Origin Reconstruction Enabled
✅ PASS: Config - Origin Offsets Configured
✅ PASS: Config - Behind Body Tolerance Configured

--- Origin Reconstruction Tests ---
✅ PASS: Method - reconstructOrigin Exists

--- Validation Preservation Tests ---
✅ PASS: Validation - Direction Alignment Still Enforced
✅ PASS: Validation - Rate Limiting Still Enforced

--- Integration Tests ---
✅ PASS: Integration - Legacy Validation Fallback Available

============================================================
RESULTS: 7 PASSED, 0 FAILED
============================================================

✅ All tests passed! Server-authoritative origin reconstruction is properly configured.
```

## Manual Testing in Studio

To verify the fix works during gameplay:

1. **Enable DEBUG logging**:
   - Open `ServerScriptService/WeaponService.lua`
   - Set `local DEBUG = true` on line 8

2. **Start a test game**:
   - Play the game in Studio
   - Equip a weapon
   - Fire several shots while moving and rotating

3. **Check Output window**:
   - Should see: `[WeaponService] DEBUG: Reconstructed origin for ...`
   - Should NOT see: `SECURITY: Rejected shot ... origin behind player`

4. **Test different scenarios**:
   - Fire while standing still
   - Fire while walking/running
   - Fire while turning rapidly
   - Fire at different angles (up, down, sideways)

5. **Verify no rejections**:
   - All shots should be accepted
   - No "origin behind player" warnings
   - No "origin not in line-of-sight" warnings

## Configuration

Edit `ReplicatedStorage/Shared/GameConfig.lua` to adjust:

```lua
GameConfig.Security = {
    USE_SERVER_ORIGIN = true,           -- Enable server-authoritative origin
    ORIGIN_FORWARD_OFFSET = 2.0,        -- Forward offset from head (studs)
    ORIGIN_VERTICAL_OFFSET = 0.5,       -- Vertical offset from head (studs)
    BEHIND_BODY_TOLERANCE = 1.0,        -- Tolerance for legacy validation (studs)
    MIN_WEAPON_FIRE_DOT_PRODUCT = 0.7,  -- Direction alignment (0.7 = ~45 degree cone)
}
```

## Security Maintained

The fix maintains all security validations:
- ✅ **Direction alignment**: Shots must align with player look vector (anti-wallhack)
- ✅ **Rate limiting**: Fire rate caps prevent spam (anti-exploit)
- ✅ **Ammo validation**: Server-side ammo consumption (anti-cheat)
- ✅ **Distance limits**: Server validates range (anti-teleport)

## Why It Fixes It

**Root Cause**: Client sent `camera.CFrame.Position` as origin, which is offset from head. Server validated against HRP position in local space, causing false rejections when camera was "behind" HRP due to offsets.

**Fix**: Server reconstructs origin from head position (server-side ground truth) using validated direction vector. This eliminates client/server position disagreements while preserving anti-cheat direction validation.

**Result**: No more false rejections from normal gameplay, exploitable origins still denied.
