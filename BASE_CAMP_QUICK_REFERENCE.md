# Base Camp Quick Reference

Quick reference guide for the base camp system.

## What Is It?

A defensive fortress automatically created at the center of each map. Players defend this from zombie waves - if it's destroyed, the game is lost.

## Quick Facts

- **Size**: 30 x 30 studs
- **Auto-Generated**: Creates when map loads
- **Position**: Center of map (calculated from spawn points)
- **Toggle**: `GameConfig.AUTO_CREATE_BASE_CAMP = true/false`

## Components at a Glance

| Component | Count | Material | Function |
|-----------|-------|----------|----------|
| Platform | 1 | Concrete | Central base |
| Walls | 4 | Concrete | Defense (12 studs high) |
| Gates | 4 | Wood | Entry points (passable) |
| Cover | 8 | Metal | Tactical positions |
| HitBox | 1 | Invisible | Zombie targeting |

## File Locations

| File | Location | Purpose |
|------|----------|---------|
| BaseCampSetup.lua | ServerScriptService/ | Main module |
| MapManager.lua | ServerScriptService/ | Integration |
| GameConfig.lua | ReplicatedStorage/Shared/ | Configuration |
| BASE_CAMP_SYSTEM.md | Root | Full documentation |
| BASE_CAMP_VISUAL_DESIGN.md | Root | Visual design guide |

## Quick Setup

### For Map Creators

1. Create "ZombieSpawnPoints" folder in your map
2. Add 4-8 Parts as spawn points around where you want the base
3. Base camp will auto-generate at the center

### Disable Auto-Generation

```lua
-- In ReplicatedStorage/Shared/GameConfig.lua
GameConfig.AUTO_CREATE_BASE_CAMP = false
```

### Customize Appearance

```lua
-- In ServerScriptService/BaseCampSetup.lua
local CAMP_CONFIG = {
    BASE_SIZE = 30,        -- Change size
    WALL_HEIGHT = 12,      -- Change height
    COVER_COUNT = 8,       -- Number of cover positions
    WALL_COLOR = Color3.fromRGB(80, 80, 80), -- Colors
    -- ... more options
}
```

## Testing

### Quick Visual Test
```lua
-- Run in Command Bar or Script
require(game.ServerScriptService.BaseCampSetup).new():buildBaseCamp(Vector3.new(0, 5, 0))
```

### Automated Tests
- **TestBaseCamp.lua** - Unit tests (ServerStorage/DevOnly/)
- **VisualizeBaseCamp.lua** - Visual demo (ServerStorage/DevOnly/)
- See **BASE_CAMP_TESTING.md** for full testing guide

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Base not appearing | Check `AUTO_CREATE_BASE_CAMP = true` |
| Wrong position | Adjust zombie spawn point positions |
| Zombies ignore base | Verify "BaseCaptureZone" exists in workspace |
| Customization not working | Edit BaseCampSetup.lua (not in Archive/) |

## API Quick Reference

### BaseCampSetup Class

```lua
local BaseCampSetup = require(ServerScriptService.BaseCampSetup)
local setup = BaseCampSetup.new()

-- Setup for current map
setup:setupForMap(mapManager)

-- Build at specific position
local baseCamp, zone = setup:buildBaseCamp(Vector3.new(0, 5, 0))

-- Calculate map center
local center = setup:calculateMapCenter(spawnPoints)

-- Cleanup existing
setup:cleanup()
```

### MapManager Integration

```lua
-- MapManager automatically creates base camp when loading maps
local MapManager = require(ServerScriptService.MapManager)
local mapManager = MapManager.new()
mapManager:loadDefault()  -- Base camp created automatically
```

## Key Design Decisions

1. **Auto-Generation**: Ensures consistency across maps
2. **Center Position**: Calculated from spawn points for optimal placement
3. **Passable Gates**: Visual only, don't block player movement
4. **Invisible HitBox**: Zombies target the base without visual clutter
5. **Configurable**: Easy to customize colors, sizes, materials
6. **Modular**: BaseCampSetup can be used independently

## Integration Points

- **MapManager**: Calls `setupForMap()` on map load
- **TargetingService**: Finds "BaseCaptureZone" for zombie AI
- **BaseManager**: Tracks base health (unchanged)
- **GameConfig**: `AUTO_CREATE_BASE_CAMP` toggle

## Common Use Cases

### Use Case 1: Default Behavior
- Leave `AUTO_CREATE_BASE_CAMP = true`
- Add zombie spawn points to map
- Base camp generates automatically

### Use Case 2: Custom Position
```lua
-- Disable auto-generation
GameConfig.AUTO_CREATE_BASE_CAMP = false

-- Create at specific position
local setup = BaseCampSetup.new()
setup:buildBaseCamp(Vector3.new(100, 5, 50))
```

### Use Case 3: Different Size
```lua
-- Edit CAMP_CONFIG in BaseCampSetup.lua
BASE_SIZE = 40,  -- Larger base
WALL_HEIGHT = 16, -- Taller walls
```

## Related Systems

- **BaseManager**: Health tracking (1000 HP default)
- **ZombieBrain**: Attack behavior when near base
- **TargetingService**: AI pathfinding to base
- **WaveManager**: Spawn zombies that target base
- **BaseHealthUI**: Visual health indicator

## Performance Notes

- All parts are **anchored** (no physics calculations)
- Created **once per map load** (not per wave)
- **~20-30 parts total** (minimal memory impact)
- **No frame rate impact** in testing

## Future Enhancements

Potential improvements:
- Multiple base camp templates (small/medium/large)
- Map-specific configurations
- Upgradeable walls
- Visual damage states
- Dynamic lighting

## Quick Links

- [Full Documentation](BASE_CAMP_SYSTEM.md)
- [Visual Design Guide](BASE_CAMP_VISUAL_DESIGN.md)
- [Testing Guide](ServerStorage/DevOnly/BASE_CAMP_TESTING.md)
- [API Reference](API_DOCUMENTATION.md#basecampsetup)
- [Game Design Doc](GAME_DESIGN.md)

## Support

For issues or questions:
1. Check [BASE_CAMP_TESTING.md](ServerStorage/DevOnly/BASE_CAMP_TESTING.md) troubleshooting section
2. Review [BASE_CAMP_SYSTEM.md](BASE_CAMP_SYSTEM.md) full documentation
3. Examine test scripts in ServerStorage/DevOnly/

---

**Version**: 1.0  
**Last Updated**: 2025-12-28  
**Status**: ✅ Implemented and Ready for Testing
