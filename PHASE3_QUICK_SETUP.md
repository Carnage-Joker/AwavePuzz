# Phase 3 Quick Setup Guide

## Step-by-Step Setup in Roblox Studio

### Step 1: Open Your Place File

1. Open Roblox Studio
2. Load your AwavePuzz place file
3. If starting fresh, create a new place

### Step 2: Create Workspace Structure

#### 2.1: Create BaseCaptureZone (if not already present)
```
Workspace
└── BaseCaptureZone (Part)
    - Size: 20, 1, 20
    - Position: 0, 0.5, 0
    - Anchored: true
    - Color: Red/Pink
```

#### 2.2: Create CureStations Folder
```
Workspace
└── CureStations (Folder)
    └── CureStation1 (Part)
        - Size: 6, 8, 6
        - Position: 0, 4, 20 (or anywhere visible)
        - Anchored: true
        - Material: Neon
        - Color: Bright Green
```

#### 2.3: Create SpawnPoints Structure
```
Workspace
└── SpawnPoints (Folder)
    ├── ItemSpawns (Folder)
    │   ├── ItemSpawn1 (Part) - Position: 30, 2, 0
    │   ├── ItemSpawn2 (Part) - Position: -30, 2, 0
    │   ├── ItemSpawn3 (Part) - Position: 0, 2, 30
    │   ├── ItemSpawn4 (Part) - Position: 0, 2, -30
    │   ├── ItemSpawn5 (Part) - Position: 20, 2, 20
    │   ├── ItemSpawn6 (Part) - Position: -20, 2, 20
    │   ├── ItemSpawn7 (Part) - Position: 20, 2, -20
    │   └── ItemSpawn8 (Part) - Position: -20, 2, -20
    └── ZombieSpawnPoints (Folder)
        ├── SpawnPoint1 (Part) - Position: 50, 2, 0
        ├── SpawnPoint2 (Part) - Position: -50, 2, 0
        ├── SpawnPoint3 (Part) - Position: 0, 2, 50
        └── SpawnPoint4 (Part) - Position: 0, 2, -50
```

**Important Notes:**
- All spawn point Parts should be Anchored
- You can make them invisible: `Transparency = 1`
- Position Y should be slightly above ground (e.g., 2)

### Step 3: Copy Script Files

If you're starting fresh or the files are not in place:

#### 3.1: ServerScriptService Structure
```
ServerScriptService
├── GameManager (Script) - Copy from GameManager.server.lua
├── CureService (ModuleScript) - Copy from CureService.lua
├── ResourceSpawner (ModuleScript) - Copy from ResourceSpawner.lua
├── Spawner (ModuleScript) - Copy from Spawner.lua
└── AIScripts (Folder)
    └── ZombieBrain (ModuleScript) - Copy from ZombieBrain.lua
```

#### 3.2: ReplicatedStorage Structure
```
ReplicatedStorage
└── Shared (Folder)
    ├── Config (ModuleScript) - Copy from Config.lua
    ├── WaveConfig (ModuleScript) - Copy from WaveConfig.lua
    └── ZombieTypes (ModuleScript) - Copy from ZombieTypes.lua
```

#### 3.3: StarterGui Structure
```
StarterGui
├── CureUI (LocalScript) - Copy from CureUI.client.lua
└── WaveUI (LocalScript) - Copy from WaveUI.client.lua
```

### Step 4: Test the Game

1. Click **Test** tab in Ribbon
2. Click **Play** or **Start**
3. Watch the Output window for:
   ```
   Phase 3 systems initialized: CureService and ResourceSpawner
   Registered X cure stations
   ResourceSpawner initialized with X spawn points
   CureUI initialized (Press C to toggle details)
   ```

### Step 5: Verify Phase 3 Features

1. **Check UI**: Look for "Cure Progress" in top-right corner
2. **Wait for resources**: Colored parts should spawn after 45 seconds
3. **Collect a resource**: Walk into a colored part
4. **Check progress**: UI should update to show progress
5. **Open details**: Press C key to see component breakdown
6. **Test cure station**: Walk up to green station, press E to interact

## Quick Visual Checklist

- [ ] BaseCaptureZone exists in Workspace
- [ ] CureStations folder exists with at least 1 cure station
- [ ] SpawnPoints/ItemSpawns exists with at least 4 spawn points
- [ ] GameManager script exists in ServerScriptService
- [ ] CureService ModuleScript exists in ServerScriptService
- [ ] ResourceSpawner ModuleScript exists in ServerScriptService
- [ ] Config ModuleScript exists in ReplicatedStorage/Shared
- [ ] CureUI LocalScript exists in StarterGui
- [ ] No errors in Output window after starting game
- [ ] Cure Progress UI visible in top-right
- [ ] Resources spawn after waiting 45 seconds

## Minimal Test Setup

For the absolute minimum test setup:

1. **One cure station**: Any Part or Model in CureStations folder
2. **Four item spawns**: Four Parts in SpawnPoints/ItemSpawns folder
3. **One base zone**: BaseCaptureZone Part in Workspace
4. **All scripts**: In correct locations as listed above

The system will auto-create ProximityPrompts and fallback structures if anything is missing.

## Common Setup Errors

### Error: "BaseCaptureZone not found"
**Solution**: Create a Part named "BaseCaptureZone" in Workspace

### Error: "ResourceSpawner initialized with 0 spawn points"
**Solution**: Create SpawnPoints/ItemSpawns folder with Parts inside

### Error: "Registered 0 cure stations"
**Solution**: Create CureStations folder with at least one Part or Model

### Error: "Config not found"
**Solution**: Ensure Config ModuleScript exists in ReplicatedStorage/Shared

## Testing Tips

1. **Quick Test Mode**: Edit Config.lua:
   - Set `ComponentsRequired = 2` (instead of 5)
   - Set `ResourceSpawnRate = 10` (instead of 45)
   - This makes testing much faster

2. **Debug Mode**: Check Output window constantly
   - Shows when resources spawn
   - Shows when players collect items
   - Shows cure progress updates
   - Shows victory condition

3. **Multi-Player Test**: Use Test tab → Start with 2-4 players
   - Verify progress syncs across all players
   - Test concurrent collection

4. **UI Toggle**: Press C key to toggle detailed view
   - Shows all 5 component types
   - Shows progress for each (X / 5)
   - Shows checkmarks when complete

## Expected Behavior

When everything is set up correctly:

1. **Game starts**: No errors in Output
2. **After 45 seconds**: First resource spawns
3. **Walk into resource**: Resource disappears, progress updates
4. **After collecting 25 components**: Victory message appears
5. **UI updates**: Progress bar fills, turns gold at 100%
6. **Game ends**: "CURE COMPLETE! Victory!" message

## Need Help?

- Review full testing guide: PHASE3_TESTING.md
- Check implementation details: IMPLEMENTATION_SUMMARY.md
- Review API documentation: API_DOCUMENTATION.md
- Check game design: GAME_DESIGN.md

## Success!

If you see colored resources spawning and can collect them with progress updates, Phase 3 is working correctly! 🎉
