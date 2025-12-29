# Map Structure Standard

This document describes the standardized structure for AwavePuzz map models and how to create new maps.

## Overview

All maps in AwavePuzz follow a consistent folder structure that enables:
- Zombie spawning at designated points
- Resource (cure component) spawning
- Item (ammo/health pack) spawning near the base
- Automatic base camp generation
- Map validation before loading

## Map Location

All map models MUST be placed in:
```
ServerStorage/Maps/<MapName>
```

## Required Structure

Every map model MUST contain the following folder structure:

```
<MapName> (Model)
├── ZombieSpawnPoints (Folder) [REQUIRED]
│   ├── SpawnPoint (Part/Attachment) - at least 8 required
│   ├── SpawnPoint (Part/Attachment)
│   └── ...
└── SpawnPoints (Folder) [RECOMMENDED]
    ├── ResourceSpawns (Folder) [RECOMMENDED]
    │   ├── SpawnPoint (Part) - at least 4 recommended
    │   └── ...
    └── ItemSpawns (Folder) [RECOMMENDED]
        ├── SpawnPoint (Part) - at least 4 recommended
        └── ...
```

### Folder Descriptions

#### ZombieSpawnPoints (REQUIRED)
- Contains spawn points where zombies will appear during waves
- Each spawn point can be:
  - A `BasePart` (Part) - uses Position
  - An `Attachment` - uses WorldPosition  
  - A `Model` with a PrimaryPart - uses PrimaryPart.Position
- **Minimum:** 8 spawn points
- **Recommended:** 16+ spawn points distributed around the map perimeter
- **Layout:** Place in a ring around the outer edge of the playable area

#### SpawnPoints/ResourceSpawns (RECOMMENDED)
- Contains spawn points for cure components (resources)
- Uses Parts for spawn locations
- **Minimum:** 4 spawn points
- **Recommended:** 10+ spawn points
- **Layout:** Distribute in mid-to-outer ring, pulling players away from base
- **Note:** If missing, system falls back to legacy `ResourceSpawnPoints` folder

#### SpawnPoints/ItemSpawns (RECOMMENDED)
- Contains spawn points for ammo and health packs
- Uses Parts for spawn locations
- **Minimum:** 4 spawn points
- **Recommended:** 8+ spawn points
- **Layout:** Place near the base camp area for easier access

### Legacy Support

The system also supports the legacy convention:
- `ResourceSpawnPoints` (Folder) - directly under the map model
- If both legacy and standard exist, the standard takes precedence

## Optional Elements

### MapBounds (Part)
A Part defining the playable area boundaries. Used for:
- Keeping zombies within the map
- Preventing players from going out of bounds
- AI pathfinding constraints

### Base/BaseCore/BaseStation
Pre-placed base structures. If `GameConfig.AUTO_CREATE_BASE_CAMP` is `true`, the system will automatically generate a base camp at the map center calculated from zombie spawn points.

### CureStations (Folder)
Optional pre-placed cure stations. The game will use these instead of auto-generated ones if present.

## Creating a New Map

### Method 1: Use the MapGenerator Tool

The easiest way to create placeholder maps is to use the MapGenerator tool:

1. Open Roblox Studio
2. Open the Command Bar (View → Command Bar)
3. Run this command:
   ```lua
   require(game.ServerStorage.DevOnly.MapGenerator).generateAll()
   ```

This will create all maps defined in MapConfig with proper spawn point structures.

### Method 2: Manual Creation

1. **Create the Map Model**
   - In ServerStorage, navigate to the Maps folder
   - Create a new Model (Insert Object → Model)
   - Name it according to your MapConfig entry (e.g., "Village")

2. **Create ZombieSpawnPoints**
   - Add a Folder to the model named "ZombieSpawnPoints"
   - Add at least 8 Parts as spawn points
   - Position them around the outer perimeter
   - Recommended: Make them semi-transparent for easy editing
   - Parts should be Anchored and CanCollide = false

3. **Create SpawnPoints Structure**
   - Add a Folder named "SpawnPoints"
   - Inside SpawnPoints, add a Folder named "ResourceSpawns"
   - Add at least 4 Parts for resource spawning
   - Inside SpawnPoints, add a Folder named "ItemSpawns"
   - Add at least 4 Parts for item spawning

4. **Add Geometry** (optional)
   - Add ground planes, buildings, cover objects
   - All structural elements should be Anchored
   - Consider performance: avoid excessive detail

5. **Configure Lighting** (optional for variants)
   - Variants like "MapName_Night" can have different atmosphere
   - Modify ambient lighting, fog, time of day

## Adding a Map to the Game

### Step 1: Create the Model
Follow one of the creation methods above to create your map model in `ServerStorage/Maps`.

### Step 2: Add to MapConfig
Edit `ReplicatedStorage/Shared/MapConfig.lua`:

```lua
MapConfig.Maps = {
    -- ... existing maps ...
    
    YourMapName = {
        Name = "Display Name",
        Model = "YourMapName",  -- Must match folder name in ServerStorage.Maps
        Description = "Brief description of the map",
        Default = false,  -- Set to true for default map
        -- Optional: BaseCampConfig overrides
        BaseCampConfig = {
            BASE_SIZE = 35,
            WALL_COLOR = Color3.fromRGB(100, 80, 60),
        }
    }
}
```

### Step 3: Test the Map
1. Run the game in Roblox Studio
2. Check the output for validation messages
3. The map should appear in the voting screen
4. Verify spawn points are working correctly

## Validation

Maps are automatically validated when loaded. Check the output log for:
- `[MapValidator] Map 'MapName' is valid` - Map passed validation
- `[MapValidator] Map 'MapName' validation FAILED` - Map has errors

Validation checks:
- ✅ Required folders exist
- ✅ Minimum spawn point counts
- ⚠️ Warnings for low spawn point counts
- ℹ️ Spawn point count summary

## Spawn Point Layout Guidelines

### Zombie Spawns
- **Distance from center:** 80-100 studs
- **Distribution:** Even circular distribution
- **Quantity:** 16+ points
- **Purpose:** Zombies approach from all directions

### Resource Spawns  
- **Distance from center:** 40-60 studs
- **Distribution:** Mid-ring, away from player start
- **Quantity:** 10+ points
- **Purpose:** Pull players out from base for resource collection

### Item Spawns
- **Distance from center:** 15-25 studs
- **Distribution:** Near base camp
- **Quantity:** 8+ points
- **Purpose:** Provide safe access to supplies

## Map Variants

Variants are copies of existing maps with different atmosphere or minor changes:
- Same basic geometry
- Different lighting/ambiance
- Optional: blocked paths, additional cover
- Must have complete spawn point structure

Example: `ResearchOutpost_Night` is a variant of `ResearchOutpost`

## Troubleshooting

### "Map model 'MapName' missing in ServerStorage.Maps"
- Ensure the Model exists in ServerStorage/Maps
- Check that the Model name matches the MapConfig.Model value exactly (case-sensitive)

### "Insufficient zombie spawn points"
- Add more Parts to the ZombieSpawnPoints folder
- Ensure minimum of 8 spawn points

### "Map validation FAILED"
- Check output for specific error messages
- Verify required folders exist with correct names
- Ensure spawn points are valid objects (Parts, Attachments, or Models with PrimaryPart)

### Map doesn't appear in voting
- Check LobbyManager output for "Skipping map" warnings
- Verify the map model exists in ServerStorage.Maps
- Ensure MapConfig entry references correct Model name

## Performance Considerations

- Keep total part count under 1000 per map for optimal performance
- Use larger simple parts instead of many small parts
- Avoid transparency where possible
- Use terrain sparingly
- Test with 8 players and 50+ zombies

## Example: Simple Map Structure

```
Village (Model)
├── Ground (Part) - 180x1x180 base plane
├── ZombieSpawnPoints (Folder)
│   ├── ZombieSpawn_1 (Part) - Position: (80, 2, 0)
│   ├── ZombieSpawn_2 (Part) - Position: (56, 2, 56)
│   └── ... (14 more evenly distributed)
└── SpawnPoints (Folder)
    ├── ResourceSpawns (Folder)
    │   ├── ResourceSpawn_1 (Part) - Position: (45, 2, 0)
    │   └── ... (9 more distributed)
    └── ItemSpawns (Folder)
        ├── ItemSpawn_1 (Part) - Position: (18, 2, 0)
        └── ... (7 more near center)
```

## Reference Implementation

See `ServerStorage/DevOnly/MapGenerator.lua` for a complete reference implementation that generates valid maps programmatically.

---

**Last Updated:** 2025-12-29
**Game Version:** Multi-Map System v2.0
