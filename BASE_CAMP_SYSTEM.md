# Base Camp System Documentation

## Overview

The Base Camp System automatically creates a defensive structure in the center of the map that players must defend from zombie waves. The base camp serves as the primary objective in AwavePuzz - if it's destroyed, the game is lost.

## Features

### Automatic Creation
- Base camp is automatically generated when a map loads
- Position calculated as the center point between all zombie spawn points
- Uses raycasting to find proper ground level
- Integrates seamlessly with the existing BaseManager health system

### Defensive Structure

#### Base Platform
- **Size**: 30x30 studs
- **Material**: Concrete
- **Color**: Gray (RGB 100, 100, 100)
- **Purpose**: Central defensive position for players

#### Defensive Walls
- **Height**: 12 studs
- **Thickness**: 2 studs
- **Material**: Concrete
- **Color**: Dark gray (RGB 80, 80, 80)
- **Layout**: Four walls creating a square perimeter (North, South, East, West)

#### Gates
- **Count**: 4 (one per cardinal direction)
- **Width**: 8 studs
- **Height**: 8.4 studs (70% of wall height)
- **Material**: Wood
- **Color**: Brown (RGB 120, 80, 40)
- **Transparency**: 0.3 (semi-transparent)
- **Collision**: Disabled (players can pass through)
- **Purpose**: Visual indication of entry points while allowing free movement

#### Cover Positions
- **Count**: 8 positions
- **Size**: 4x3x1 studs each
- **Material**: Metal
- **Color**: Dark gray (RGB 70, 70, 70)
- **Layout**: Arranged in a circle 10 studs from center
- **Orientation**: Each facing outward for defensive positioning

### Zombie Targeting Integration

#### BaseCaptureZone Model
- Created alongside the base camp
- Contains a "HitBox" part that zombies target
- Invisible and non-collidable
- Size: 26x10x26 studs (slightly smaller than walls)
- Positioned at wall height center
- Integrated with existing TargetingService.lua

## Configuration

### GameConfig Settings

```lua
-- In ReplicatedStorage/Shared/GameConfig.lua
GameConfig.AUTO_CREATE_BASE_CAMP = true -- Enable/disable auto base camp creation
GameConfig.BASE_HEALTH = 1000 -- Base health pool
GameConfig.BASE_REGEN_RATE = 0 -- No regeneration by default
```

### BaseCampSetup Configuration

The `CAMP_CONFIG` table in `BaseCampSetup.lua` allows customization:

```lua
local CAMP_CONFIG = {
    BASE_SIZE = 30,           -- Size of central base structure (studs)
    WALL_HEIGHT = 12,         -- Height of defensive walls
    WALL_THICKNESS = 2,       -- Thickness of walls
    GATE_WIDTH = 8,           -- Width of gates in walls
    NUM_GATES = 4,            -- Number of gates (cardinal directions)
    COVER_COUNT = 8,          -- Number of cover positions
    COVER_SIZE = Vector3.new(4, 3, 1), -- Size of cover objects
    
    -- Colors (Color3.fromRGB)
    WALL_COLOR = Color3.fromRGB(80, 80, 80),
    BASE_COLOR = Color3.fromRGB(100, 100, 100),
    GATE_COLOR = Color3.fromRGB(120, 80, 40),
    COVER_COLOR = Color3.fromRGB(70, 70, 70),
    
    -- Materials
    WALL_MATERIAL = Enum.Material.Concrete,
    BASE_MATERIAL = Enum.Material.Concrete,
    GATE_MATERIAL = Enum.Material.Wood,
    COVER_MATERIAL = Enum.Material.Metal,
}
```

## Architecture

### File Structure

```
ServerScriptService/
├── BaseCampSetup.lua         -- Base camp creation and management
├── MapManager.lua            -- Integrates base camp with map loading
├── BaseManager.lua           -- Tracks base health (unchanged)
└── AI/
    └── TargetingService.lua  -- Zombie targeting (uses BaseCaptureZone)
```

### Integration Flow

1. **Map Load** (`MapManager:load()`)
   - Map model cloned into workspace
   - Spawn points extracted from map
   
2. **Base Camp Creation** (`BaseCampSetup:setupForMap()`)
   - Calculate center position from zombie spawn points
   - Create base platform, walls, gates, and cover
   - Create BaseCaptureZone model with HitBox
   - Parent structures to workspace
   
3. **Zombie Targeting** (`TargetingService:getBaseTarget()`)
   - Finds "BaseCaptureZone" in workspace
   - Returns HitBox position for zombie pathfinding
   
4. **Health Management** (`BaseManager`)
   - Tracks base health independently
   - Broadcasts damage updates to clients
   - Triggers defeat condition at 0 HP

## API Reference

### BaseCampSetup Class

#### Constructor
```lua
BaseCampSetup.new()
```
Creates a new BaseCampSetup instance.

**Returns**: `BaseCampSetup` instance

#### Methods

##### setupForMap
```lua
BaseCampSetup:setupForMap(mapManager)
```
Sets up the base camp for the current map using MapManager's spawn points.

**Parameters**:
- `mapManager` (MapManager): The map manager instance with loaded spawn points

**Returns**: 
- `baseCamp` (Model): The created base camp model
- `baseCaptureZone` (Model): The BaseCaptureZone model for zombie targeting

##### buildBaseCamp
```lua
BaseCampSetup:buildBaseCamp(centerPos, parentModel)
```
Builds the complete base camp structure at the specified position.

**Parameters**:
- `centerPos` (Vector3): Center position for the base camp
- `parentModel` (Instance, optional): Parent to place base camp under (defaults to workspace)

**Returns**:
- `baseCamp` (Model): The created base camp model
- `baseCaptureZone` (Model): The BaseCaptureZone model

##### calculateMapCenter
```lua
BaseCampSetup:calculateMapCenter(zombieSpawnPoints)
```
Calculates the center position of the map based on zombie spawn points.

**Parameters**:
- `zombieSpawnPoints` (table): Array of Vector3 positions

**Returns**: `Vector3` - The calculated center position (with ground-level Y)

##### cleanup
```lua
BaseCampSetup:cleanup()
```
Removes existing base camp and BaseCaptureZone from workspace.

**Returns**: None

### MapManager Integration

The MapManager automatically handles base camp creation:

```lua
-- In MapManager:load()
if GameConfig.AUTO_CREATE_BASE_CAMP and #self.zombieSpawnPoints > 0 then
    self.baseCampSetup:setupForMap(self)
end
```

## Usage Examples

### Default Usage (Automatic)

By default, the base camp is created automatically when maps load:

```lua
-- No code needed - works automatically when:
-- 1. GameConfig.AUTO_CREATE_BASE_CAMP = true (default)
-- 2. Map has zombie spawn points defined
-- 3. MapManager loads the map
```

### Manual Control

To disable automatic creation and manually create base camps:

```lua
-- In GameConfig.lua
GameConfig.AUTO_CREATE_BASE_CAMP = false

-- In your custom script
local BaseCampSetup = require(ServerScriptService.BaseCampSetup)
local baseCampSetup = BaseCampSetup.new()

-- Create at specific position
local centerPos = Vector3.new(0, 5, 0)
local baseCamp, baseCaptureZone = baseCampSetup:buildBaseCamp(centerPos)

-- Or use map manager's spawn points
local mapManager = MapManager.new()
mapManager:load("ResearchOutpost")
baseCampSetup:setupForMap(mapManager)
```

### Custom Base Camp

To create a custom base camp with different settings:

```lua
local BaseCampSetup = require(ServerScriptService.BaseCampSetup)
local baseCampSetup = BaseCampSetup.new()

-- Modify the CAMP_CONFIG before building
-- (Note: This requires editing BaseCampSetup.lua directly)
-- Alternatively, build custom structure and use BaseCaptureZone pattern

local centerPos = Vector3.new(0, 5, 0)

-- Create custom base camp
local baseCamp = Instance.new("Model")
baseCamp.Name = "BaseCamp"
baseCamp.Parent = workspace

-- Create your custom structures...

-- Create BaseCaptureZone for zombie targeting
local baseCaptureZone = Instance.new("Model")
baseCaptureZone.Name = "BaseCaptureZone"

local hitBox = Instance.new("Part")
hitBox.Name = "HitBox"
hitBox.Size = Vector3.new(30, 10, 30)
hitBox.Position = centerPos + Vector3.new(0, 5, 0)
hitBox.Anchored = true
hitBox.Transparency = 1
hitBox.CanCollide = false
hitBox.Parent = baseCaptureZone

baseCaptureZone.PrimaryPart = hitBox
baseCaptureZone.Parent = workspace
```

## Testing

### In Roblox Studio

1. **Enable Base Camp Creation**
   - Ensure `GameConfig.AUTO_CREATE_BASE_CAMP = true`
   
2. **Set Up Zombie Spawn Points**
   - Create a folder named "ZombieSpawnPoints" in workspace or your map model
   - Add 4-8 Parts as spawn points around where you want the base
   - Space them evenly (50-100 studs from desired center)
   
3. **Test Map Load**
   - Run the game in Roblox Studio
   - Check console for "[BaseCampSetup] Base camp created at position: X, Y, Z"
   - Verify base camp appears in workspace
   - Verify "BaseCaptureZone" exists in workspace
   
4. **Test Zombie Targeting**
   - Start a wave
   - Verify zombies pathfind to the base camp
   - Verify zombies attack the base when in range
   - Check BaseManager health decreases

### Visual Verification Checklist

- [ ] Base platform (30x30 gray concrete) at map center
- [ ] Four walls (12 studs high) around the platform
- [ ] Four semi-transparent gates at cardinal directions
- [ ] Eight cover objects arranged in a circle
- [ ] BaseCaptureZone model exists in workspace
- [ ] HitBox part exists inside BaseCaptureZone (invisible)
- [ ] Zombies pathfind toward base camp
- [ ] Base health UI updates when base takes damage

## Troubleshooting

### Base Camp Not Appearing

**Problem**: No base camp is created when map loads

**Solutions**:
1. Check `GameConfig.AUTO_CREATE_BASE_CAMP` is `true`
2. Verify zombie spawn points exist in map or workspace
3. Check console for warnings/errors from BaseCampSetup
4. Verify BaseCampSetup.lua is in ServerScriptService

### Zombies Not Targeting Base

**Problem**: Zombies don't attack the base camp

**Solutions**:
1. Verify "BaseCaptureZone" model exists in workspace
2. Check BaseCaptureZone has a "HitBox" part
3. Ensure HitBox is properly positioned (not underground)
4. Verify TargetingService is finding BaseCaptureZone
5. Check zombie spawn points are set up correctly

### Base Camp in Wrong Location

**Problem**: Base camp appears at wrong position

**Solutions**:
1. Verify zombie spawn points are placed correctly
2. Check spawn points are evenly distributed around desired center
3. Adjust spawn point positions to move base camp center
4. Manually set position by modifying BaseCampSetup:buildBaseCamp() call

### Customization Not Working

**Problem**: Changes to CAMP_CONFIG don't take effect

**Solutions**:
1. Verify you're editing ServerScriptService/BaseCampSetup.lua (not Archive)
2. Ensure changes are saved before testing
3. Restart the game session in Studio
4. Check for syntax errors in modified config

## Performance Considerations

- Base camp is created once per map load (not per wave)
- All base camp parts are anchored (no physics calculations)
- Base camp cleanup is automatic when maps change
- Minimal network traffic (structures are created on server only)

## Future Enhancements

Potential improvements for future versions:

1. **Customizable Layouts**
   - Multiple base camp templates (small, medium, large)
   - Map-specific base camp configurations in MapConfig

2. **Defensive Upgrades**
   - Upgradeable walls (increase height/strength)
   - Automated turrets at cover positions
   - Repair system for damaged walls

3. **Visual Improvements**
   - Particle effects when base takes damage
   - Dynamic lighting inside base camp
   - Debris/damage visual states

4. **Strategic Features**
   - Ammo/health spawn points near base
   - Workbenches for weapon upgrades
   - Safe zones within base camp

## Related Documentation

- [GAME_DESIGN.md](./GAME_DESIGN.md) - Overall game design and base system
- [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) - Complete API reference
- [IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md) - Implementation status

## Conclusion

The Base Camp System provides an automatic, configurable defensive structure that enhances gameplay by giving players a clear objective to defend. The system integrates seamlessly with existing zombie AI, health management, and map loading systems while remaining flexible for customization and future enhancements.

---

**Version**: 1.0  
**Last Updated**: 2025-12-28  
**Status**: Implemented and Ready for Testing
