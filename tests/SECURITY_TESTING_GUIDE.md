# Security Testing Guide - Manual Testing in Roblox Studio

This guide describes how to manually test security fixes for BUG-004 (Wallhack) and BUG-009 (Client Authority) in Roblox Studio.

## Prerequisites

1. Open the AwavePuzz project in Roblox Studio
2. Ensure you're in "Edit" mode (not "Play Solo" yet)
3. Have the Output window open (View → Output)

---

## Automated Test Suite

### Running the Automated Tests

1. Open Roblox Studio with the AwavePuzz project
2. Open the Command Bar (View → Command Bar)
3. Paste and run:

```lua
local SecurityTests = require(game.ServerStorage.Parent.tests.security_validation_tests)
SecurityTests.runAll()
```

4. Check the Output window for results
5. Expected output:

```
============================================================
SECURITY VALIDATION TEST SUITE
Testing BUG-004 (Wallhack) and BUG-009 (Client Authority)
============================================================

--- BUG-004: Wallhack Protection Tests ---
✅ PASS: Wallhack - Origin Distance Validation
✅ PASS: Wallhack - Direction Alignment Validation
✅ PASS: Wallhack - NaN Protection

--- BUG-009: Client Authority Tests ---
✅ PASS: Client Authority - Server Ammo Consumption
✅ PASS: Client Authority - Currency Server Authority
✅ PASS: Client Authority - Damage Server Authority
✅ PASS: Client Authority - Shop Purchase Validation
✅ PASS: Client Authority - Alliance Request Validation
✅ PASS: Client Authority - Puzzle Answer Validation

--- Security Configuration Tests ---
✅ PASS: Security Config - Existence Check
✅ PASS: Security Config - Ammo Sync Interval

============================================================
RESULTS: 11 PASSED, 0 FAILED
============================================================
```

---

## Manual Testing (Advanced)

### Test 1: Wallhack Protection - Origin Distance

**What to test**: Verify the server rejects shots from positions far from the player.

**Steps**:
1. Start "Play" mode in Roblox Studio
2. Obtain a weapon in-game
3. Open the Server-side Command Bar (in Play mode: View → Server → Command)
4. Simulate a shot from an invalid position:

```lua
-- Get the first player
local player = game.Players:GetChildren()[1]
local WeaponService = require(game.ServerScriptService.WeaponService)

-- Try to fire from 100 studs away (should be rejected)
local fakeOrigin = player.Character.HumanoidRootPart.Position + Vector3.new(100, 0, 0)
local fakeDirection = Vector3.new(0, 0, -1)

-- This should show a security warning in Output
WeaponService:handleWeaponFire(player, {
    origin = fakeOrigin,
    direction = fakeDirection,
    weaponId = "Pistol"
})
```

**Expected Result**: 
- Output shows: `[WeaponService] SECURITY: Rejected shot from [PlayerName] - origin too far from player`
- No damage is dealt
- Player's weapon doesn't fire

---

### Test 2: Wallhack Protection - Direction Alignment

**What to test**: Verify the server rejects shots that aren't aligned with where the player is facing.

**Steps**:
1. Start "Play" mode
2. Use Server-side Command Bar:

```lua
local player = game.Players:GetChildren()[1]
local WeaponService = require(game.ServerScriptService.WeaponService)

-- Get player's position and shoot backwards
local hrp = player.Character.HumanoidRootPart
local origin = hrp.Position
local backwardDirection = -hrp.CFrame.LookVector -- Shoot backwards

WeaponService:handleWeaponFire(player, {
    origin = origin,
    direction = backwardDirection,
    weaponId = "Pistol"
})
```

**Expected Result**:
- Output shows: `[WeaponService] SECURITY: Rejected shot from [PlayerName] - direction not aligned`
- No damage is dealt

---

### Test 3: Client Authority - Ammo Manipulation

**What to test**: Verify that client cannot bypass server-side ammo consumption.

**Steps**:
1. Start "Play" mode
2. Get a weapon with limited ammo
3. Fire until ammo reaches 0
4. Try to fire again

**Expected Result**:
- Server rejects shot when ammo is 0
- Client shows "no ammo" state
- Weapon cannot fire without reload

**Additional Test** (Server Command):
```lua
local player = game.Players:GetChildren()[1]
local FPSWeaponService = require(game.ServerScriptService.FPSWeaponService)

-- Try to consume more ammo than available
local success = FPSWeaponService:consumeAmmo(player, "Pistol", 999)
print("Ammo consumption result:", success) -- Should be false
```

---

### Test 4: Client Authority - Currency Manipulation

**What to test**: Verify that currency cannot be modified client-side.

**Steps**:
1. Start "Play" mode
2. Note starting currency
3. Try client-side modification (should fail):

```lua
-- CLIENT COMMAND (won't work - for testing purposes)
local Players = game:GetService("Players")
local player = Players.LocalPlayer
-- Client has no direct access to modify currency
```

4. Server-side test:

```lua
-- SERVER COMMAND
local player = game.Players:GetChildren()[1]
local PlayerManager = require(game.ServerScriptService.PlayerManager)

-- Try to deduct more currency than available
local startCurrency = PlayerManager:getCurrency(player)
print("Starting currency:", startCurrency)

local success = PlayerManager:deductCurrency(player, startCurrency + 1000)
print("Deduction result:", success) -- Should be false

local endCurrency = PlayerManager:getCurrency(player)
print("Ending currency:", endCurrency) -- Should equal startCurrency
```

**Expected Result**:
- Deduction fails if amount > balance
- Currency remains unchanged

---

### Test 5: Client Authority - Shop Validation

**What to test**: Verify shop purchases are validated server-side.

**Steps**:
1. Open shop UI in-game
2. Try to purchase an item without enough currency
3. Server-side test:

```lua
-- SERVER COMMAND
local player = game.Players:GetChildren()[1]
local ShopService = require(game.ServerScriptService.ShopService)

-- Try to purchase with invalid item ID
ShopService:onShopAction(player, "purchase", { itemId = 12345 }) -- Number instead of string

-- Check Output for security warning
```

**Expected Result**:
- Invalid itemId type is rejected
- Output shows: `[ShopService] SECURITY: Invalid itemId type`

---

### Test 6: Alliance Request Validation

**What to test**: Verify alliance requests validate Player instances.

**Steps (requires 2 players in-game)**:

```lua
-- SERVER COMMAND
local AllianceService = require(game.ServerScriptService.AllianceServiceV2)
local player1 = game.Players:GetChildren()[1]

-- Try to form alliance with invalid target
AllianceService:handleAllianceRequest(player1, "InvalidTarget") -- String instead of Player

-- Check Output for security warning
```

**Expected Result**:
- Output shows: `[AllianceServiceV2] SECURITY: Invalid target type`
- Alliance is not formed

---

### Test 7: Puzzle Component Validation

**What to test**: Verify puzzle answers validate component names.

**Steps**:
1. Start a puzzle in-game
2. Server-side test:

```lua
-- SERVER COMMAND
local player = game.Players:GetChildren()[1]
local PuzzleService = require(game.ServerScriptService.PuzzleService)

-- Try to submit answer for invalid component
PuzzleService:handlePuzzleAnswer(player, "InvalidComponent", "someAnswer")

-- Check Output for security warning
```

**Expected Result**:
- Output shows: `[PuzzleService] SECURITY: Unknown componentName 'InvalidComponent'`
- Answer is rejected

---

## Monitoring Security Warnings

During gameplay, monitor the Output window for any security warnings:

**Wallhack Warnings**:
```
[WeaponService] SECURITY: Rejected shot from [PlayerName] - origin too far
[WeaponService] SECURITY: Rejected shot from [PlayerName] - direction not aligned
```

**Client Authority Warnings**:
```
[ShopService] SECURITY: Invalid itemId type from [PlayerName]
[AllianceServiceV2] SECURITY: Invalid requester/target type
[PuzzleService] SECURITY: Unknown componentName from [PlayerName]
```

**Any security warning indicates an attempted exploit and should be investigated.**

---

## Testing Checklist

Use this checklist when performing security testing:

- [ ] Run automated test suite (11 tests)
- [ ] Manually test wallhack origin distance rejection
- [ ] Manually test wallhack direction alignment rejection
- [ ] Manually test ammo consumption enforcement
- [ ] Manually test currency deduction validation
- [ ] Manually test shop purchase validation
- [ ] Manually test alliance request validation (requires 2 players)
- [ ] Manually test puzzle component validation
- [ ] Monitor Output window for security warnings during gameplay
- [ ] Verify no exploits can bypass server validation

---

## Troubleshooting

**Issue**: Tests fail to run  
**Solution**: Ensure the game is in Play mode (not Edit mode) and use Server-side Command Bar

**Issue**: Can't find SecurityTests module  
**Solution**: Check that `tests/security_validation_tests.lua` exists in the repository

**Issue**: Security warnings not appearing  
**Solution**: Check that Output window filter is set to "All" not just "Errors"

---

## Next Steps

After completing manual testing:
1. Document any issues found
2. Update SECURITY.md with findings
3. Fix any discovered vulnerabilities
4. Re-run tests to verify fixes
5. Monitor production deployment for security warnings

---

**Last Updated**: 2026-02-10  
**Version**: 1.0
