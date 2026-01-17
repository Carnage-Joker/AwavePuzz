# Base Camp Testing Guide

This folder contains test scripts for verifying the base camp system works correctly.

## Test Scripts

### TestBaseCamp.lua
**Purpose**: Automated unit tests for the BaseCampSetup module

**How to Run**:
1. Open Roblox Studio
2. Open the game
3. Copy the contents of `TestBaseCamp.lua`
4. Paste into a Script in ServerScriptService
5. Run the game
6. Check Output window for test results

**What it Tests**:
- Configuration loading
- BaseCampSetup instance creation
- Map center calculation
- Base camp structure creation
- Component verification (platform, walls, gates, cover)
- BaseCaptureZone creation and configuration
- Workspace placement
- Cleanup functionality

**Expected Output**:
```
===== Base Camp Test Script =====
✓ Modules loaded successfully

--- Test 1: Configuration ---
AUTO_CREATE_BASE_CAMP: true
✓ Configuration check passed

[... more tests ...]

✅ ALL TESTS PASSED!
Base camp system is working correctly
===================================
```

### VisualizeBaseCamp.lua
**Purpose**: Visual demonstration of base camp creation

**How to Run**:
1. Open Roblox Studio
2. Open the game
3. Copy the contents of `VisualizeBaseCamp.lua`
4. Paste into a Script in Workspace or ServerScriptService
5. Run the game
6. Use Studio camera to zoom to the center of the map

**What it Does**:
- Creates test zombie spawn points if none exist (8 points in a circle)
- Calculates map center based on spawn points
- Builds the complete base camp structure
- Adds a green marker beam at the center for easy location
- Prints component information to Output

**What to Look For**:
- Gray concrete platform (30x30 studs) at center
- 4 concrete walls around the platform (12 studs high)
- 4 semi-transparent wooden gates (one per side)
- 8 metal cover objects arranged in a circle
- Green marker beam pointing at center
- Red transparent spawn points around the perimeter

**Visual Features**:
- Walls: Gray concrete, solid
- Gates: Brown wood, semi-transparent, passable
- Cover: Dark gray metal, facing outward
- Platform: Gray concrete base

## Integration Testing

To test the base camp system in the actual game:

### Method 1: Via MapManager (Automatic)

1. Ensure `GameConfig.AUTO_CREATE_BASE_CAMP = true` in ReplicatedStorage/Shared/GameConfig.lua
2. Ensure your map has a "ZombieSpawnPoints" folder with spawn point Parts
3. Run the game normally
4. The base camp should appear automatically when the map loads
5. Check Output for: `[BaseCampSetup] Base camp created at position: X, Y, Z`

### Method 2: Manual Testing

1. In Roblox Studio, open the Command Bar (View > Command Bar)
2. Run this code:
```lua
local MapManager = require(game.ServerScriptService.MapManager)
local mapManager = MapManager.new()
mapManager:loadDefault()
```
3. The base camp should appear at the map center
4. Verify BaseCamp and BaseCaptureZone models exist in Workspace

## Zombie Targeting Test

To verify zombies target the base correctly:

1. Start the game with base camp enabled
2. Start a wave (or spawn test zombies)
3. Move away from the base
4. Observe zombies pathfinding toward the base camp
5. Verify they attack the base when in range (6 studs)
6. Check base health decreases in BaseHealthUI

## Troubleshooting

### Players Cannot Exit Base Camp

**Symptoms**: Players spawn in base camp but cannot leave through gates

**Cause**: This was a bug where walls were solid and spanned the full perimeter, overlapping with gates

**Solution**: Fixed in commit 713844e. Walls are now split into 8 segments (2 per side) with 8-stud gaps for gates. Each gate area now has a physical opening in the wall, allowing players to pass through.

**Verification**: 
1. Check that 8 wall segments exist (not 4 full walls)
2. Walk through each gate - should be no collision
3. Verify gaps are 8 studs wide at each cardinal direction

### Base Camp Not Appearing

**Symptoms**: No base camp in workspace after map load

**Checks**:
1. Verify `GameConfig.AUTO_CREATE_BASE_CAMP = true`
2. Check Output for errors or warnings
3. Verify zombie spawn points exist and are properly positioned
4. Check ServerScriptService contains BaseCampSetup.lua
5. Verify MapManager is loading correctly

**Debug Code**:
```lua
-- Run in Command Bar
local config = require(game.ReplicatedStorage.Shared.GameConfig)
print("AUTO_CREATE_BASE_CAMP:", config.AUTO_CREATE_BASE_CAMP)

local mapManager = require(game.ServerScriptService.MapManager)
local mm = mapManager.new()
print("Spawn points:", #mm:getZombieSpawnPoints())
```

### Zombies Not Targeting Base

**Symptoms**: Zombies ignore the base camp

**Checks**:
1. Verify "BaseCaptureZone" model exists in Workspace
2. Check BaseCaptureZone has a "HitBox" part
3. Verify HitBox is positioned correctly (not underground)
4. Check TargetingService is enabled and working

**Debug Code**:
```lua
-- Run in Command Bar
local zone = workspace:FindFirstChild("BaseCaptureZone")
if zone then
    print("BaseCaptureZone found")
    local hitbox = zone:FindFirstChild("HitBox")
    if hitbox then
        print("HitBox found at:", hitbox.Position)
        print("HitBox properties:", hitbox.Size, hitbox.Transparency)
    else
        warn("HitBox not found!")
    end
else
    warn("BaseCaptureZone not found!")
end
```

### Base Camp Position Wrong

**Symptoms**: Base camp appears at unexpected location

**Possible Causes**:
- Spawn points not evenly distributed
- Spawn points too close together
- Missing spawn points on some sides

**Solution**:
1. Check spawn point positions in ZombieSpawnPoints folder
2. Ensure spawn points are spread around where you want the center
3. Adjust spawn point positions to move the calculated center
4. For manual positioning, call `baseCampSetup:buildBaseCamp(customPosition)`

## Performance Testing

### FPS Check
- Run game with base camp enabled
- Check FPS (Shift+F5 in Studio)
- Base camp should have minimal impact (all parts anchored)

### Memory Check
- Use Studio Performance Stats
- Base camp adds ~20-30 parts total
- Memory impact should be negligible

## Configuration Testing

Test different CAMP_CONFIG values in BaseCampSetup.lua:

1. **Size Variations**:
   - BASE_SIZE: Try 20, 30, 40
   - WALL_HEIGHT: Try 8, 12, 16
   
2. **Layout Variations**:
   - COVER_COUNT: Try 4, 8, 12
   - GATE_WIDTH: Try 6, 8, 10

3. **Visual Variations**:
   - Change colors (WALL_COLOR, etc.)
   - Change materials (try Brick, Metal, Wood)

## Test Checklist

Use this checklist when testing the base camp system:

- [ ] Base camp appears at map center
- [ ] Platform is 30x30 studs
- [ ] 8 wall segments exist (2 per side, split to create gate openings)
- [ ] Wall segments are 12 studs high
- [ ] Gaps of 8 studs exist at each cardinal direction for gates
- [ ] 4 gates exist at cardinal directions
- [ ] Gates are semi-transparent (0.3)
- [ ] Gates are passable (CanCollide = false)
- [ ] **Players can walk through gate openings and exit the base camp**
- [ ] 8 cover positions arranged in circle
- [ ] Cover objects face outward
- [ ] BaseCaptureZone exists in workspace
- [ ] HitBox exists in BaseCaptureZone
- [ ] HitBox is invisible (Transparency = 1)
- [ ] Health NumberValue exists
- [ ] Health matches GameConfig.BASE_HEALTH
- [ ] Zombies pathfind to base
- [ ] Zombies attack base when in range
- [ ] Base health decreases on attack
- [ ] Base camp cleanup works on map change

## Success Criteria

The base camp system is working correctly when:

1. ✅ Base camp automatically appears when map loads
2. ✅ Structure is visually correct (platform, walls, gates, cover)
3. ✅ Zombies correctly target and attack the base
4. ✅ Base health system integrates properly
5. ✅ No performance issues or errors
6. ✅ Cleanup works when changing maps

---

**Last Updated**: 2025-12-28  
**Related Documentation**: BASE_CAMP_SYSTEM.md
