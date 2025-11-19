# Phase 3 Implementation - Testing Guide

## Overview
Phase 3 implements the Cure System - the primary win condition for AwavePuzz. Players must collect cure components from around the map and work together to reach 100% cure progress.

## What Was Implemented

### Server-Side Components

1. **CureService.lua** (ServerScriptService)
   - Server-authoritative cure progress tracking
   - Component deposit handling
   - Puzzle validation system
   - ProximityPrompt integration for cure stations
   - Win condition triggering at 100%

2. **ResourceSpawner.lua** (ServerScriptService)
   - Spawns cure components around the map
   - Touch-based collection system
   - Color-coded components for easy identification
   - Configurable spawn rates and limits

3. **GameManager.server.lua** (Updated)
   - Integrated CureService and ResourceSpawner
   - Resource spawning during waves and intermissions
   - Victory condition when cure completes

### Client-Side Components

4. **CureUI.client.lua** (StarterGui)
   - Always-visible progress bar (top-right corner)
   - Detailed component breakdown (toggle with C key or click)
   - Color-coded progress indication
   - Real-time updates from server

### Configuration

5. **Config.lua** (ReplicatedStorage/Shared)
   - Added Cure configuration section:
     ```lua
     Config.Cure = {
         ComponentsRequired = 5,  -- 5 of each component needed
         ComponentNames = {
             "Chemical A",
             "Chemical B",
             "Biological Sample",
             "Research Notes",
             "Catalyst"
         },
         ResourceSpawnRate = 45,  -- Seconds between spawns
         MaxResourcesOnMap = 10,  -- Max concurrent resources
     }
     ```

## Setup Instructions for Roblox Studio

### Workspace Setup

1. **Create CureStations Folder**
   - In Workspace, create a Folder named "CureStations"
   - Add Part(s) or Model(s) as cure stations
   - CureService will automatically add ProximityPrompts

2. **Create SpawnPoints Structure** (if not already present)
   - In Workspace, create a Folder named "SpawnPoints"
   - Inside SpawnPoints, create "ItemSpawns" or "ResourceSpawns" folder
   - Add Part objects as spawn points (at least 4-8 recommended)
   - Parts should be positioned around the map for variety

3. **BaseCaptureZone** (should already exist from Phase 1)
   - Ensure there's a Part or Model named "BaseCaptureZone" in Workspace

### Script Placement

All scripts are already in the correct locations:

- `ServerScriptService/CureService.lua` (ModuleScript)
- `ServerScriptService/ResourceSpawner.lua` (ModuleScript)
- `ServerScriptService/GameManager.server.lua` (Script)
- `StarterGui/CureUI.client.lua` (LocalScript)
- `ReplicatedStorage/Shared/Config.lua` (ModuleScript)

## Testing Procedures

### Test 1: Initial Setup Verification

1. **Start Test Server**
   - Open Roblox Studio
   - Go to Test tab → Start
   - Check Output for initialization messages:
     ```
     Phase 3 systems initialized: CureService and ResourceSpawner
     Registered X cure stations
     ResourceSpawner initialized with X spawn points
     CureUI initialized (Press C to toggle details)
     ```

2. **Verify UI Appears**
   - Top-right corner should show "Cure Progress" frame
   - Should display "0%" and "0 / 25 Components"
   - Press C key to toggle detailed view

### Test 2: Resource Spawning

1. **Wait for Resource Spawn** (default 45 seconds)
   - Colored parts should appear at spawn points
   - Each has a label showing component name
   - Parts should be rotating and glowing (Neon material)

2. **Verify Component Colors**
   - Chemical A: Blue
   - Chemical B: Orange
   - Biological Sample: Green
   - Research Notes: Yellow
   - Catalyst: Purple

3. **Check Spawn Limits**
   - Maximum 10 resources should be on map at once
   - No new spawns until count is below max

### Test 3: Component Collection

1. **Walk into a Resource**
   - Character should collide with the part
   - Resource should disappear
   - Output should show: "[PlayerName] collected [ComponentName]"

2. **Check UI Update**
   - Progress bar should increase
   - Component count should increment
   - Progress percentage should update

3. **Verify Cure Progress Formula**
   - Total needed: 25 components (5 of each type)
   - Each component = 4% progress
   - Progress = (collected / 25) * 100

### Test 4: Cure Station Interaction

1. **Find a Cure Station**
   - Look for green Neon part (default) with ProximityPrompt
   - Approach until prompt appears

2. **Activate Cure Station**
   - Press E (or assigned key) to interact
   - Detail UI should open automatically
   - Shows all component types and progress

3. **Verify Station Functionality**
   - Can view current progress
   - Shows breakdown of each component type
   - Checkmarks appear when component complete (5/5)

### Test 5: Win Condition

1. **Collect All Components**
   - For quick testing, lower ComponentsRequired to 2 in Config.lua
   - Collect components until progress reaches 100%

2. **Verify Victory**
   - Output should show: "=== CURE COMPLETE ==="
   - Wave announce should show: "CURE COMPLETE! Victory!"
   - Zombie spawning should stop
   - Game should end

3. **Check Victory UI**
   - Progress bar turns gold at 100%
   - Title changes to "Cure Complete!"
   - Detail view shows all components complete

### Test 6: Multi-Player Testing

1. **Start Multi-Player Test**
   - Test → Start → 2-4 Players

2. **Verify Collection Sync**
   - Have one player collect a resource
   - All players should see progress update
   - All players should see contributor name in output

3. **Test Concurrent Collection**
   - Multiple players collect resources simultaneously
   - Verify no race conditions or double-counting
   - All progress updates should be accurate

### Test 7: Integration with Wave System

1. **Start a Game**
   - Wait for waves to begin
   - Verify resources spawn during waves

2. **Check Intermission Spawning**
   - Resources should continue spawning during intermission
   - Spawn timer continues between waves

3. **Test Victory During Wave**
   - Complete cure while zombies are active
   - Zombies should stop spawning
   - Existing zombies may remain (as expected)

## Common Issues and Solutions

### Issue: No resources spawning

**Solutions:**
1. Check Output for "ResourceSpawner initialized with X spawn points"
2. If X = 0, create ItemSpawns/ResourceSpawns folder with Parts
3. Verify spawn points are BasePart instances
4. Check if max resources (10) already on map

### Issue: Cure stations not interactable

**Solutions:**
1. Verify CureStations folder exists in Workspace
2. Check that ProximityPrompts were created (look inside Parts)
3. Ensure MaxActivationDistance = 10 (in ProximityPrompt)
4. Make sure player is within range

### Issue: Progress not updating

**Solutions:**
1. Check Output for collection messages
2. Verify RemoteEvents folder exists in ReplicatedStorage
3. Check that CureUpdate RemoteEvent exists
4. Restart client if UI is frozen

### Issue: Components not color-coded

**Solutions:**
1. Check that part.Material = Neon
2. Verify getComponentColor() function in ResourceSpawner
3. Default colors defined for all 5 component types

### Issue: Victory not triggering

**Solutions:**
1. Verify progress reaches exactly 100%
2. Check gameManager.onCureComplete exists
3. Ensure matchActive flag not already false
4. Check Output for "=== CURE COMPLETE ===" message

## Configuration Tuning

### Quick Testing Configuration

For faster testing, edit `ReplicatedStorage/Shared/Config.lua`:

```lua
Config.Cure = {
    ComponentsRequired = 2,      -- Was: 5 (only need 2 of each)
    ComponentNames = {
        "Chemical A",
        "Chemical B",
        "Biological Sample",
        "Research Notes",
        "Catalyst"
    },
    ResourceSpawnRate = 10,      -- Was: 45 (spawn every 10 seconds)
    MaxResourcesOnMap = 15,      -- Was: 10 (allow more resources)
}
```

### Balanced Configuration

For balanced gameplay:

```lua
Config.Cure = {
    ComponentsRequired = 5,      -- Standard: 25 total components
    ComponentNames = { ... },    -- Keep as is
    ResourceSpawnRate = 45,      -- Standard: spawn every 45 seconds
    MaxResourcesOnMap = 10,      -- Standard: max 10 concurrent
}
```

### Challenge Configuration

For harder gameplay:

```lua
Config.Cure = {
    ComponentsRequired = 10,     -- Hard: 50 total components
    ComponentNames = { ... },    -- Keep as is
    ResourceSpawnRate = 60,      -- Hard: spawn every 60 seconds
    MaxResourcesOnMap = 8,       -- Hard: max 8 concurrent
}
```

## Performance Considerations

1. **Resource Cleanup**
   - Resources auto-cleanup on collection
   - No memory leaks from uncollected resources
   - Old connections properly disconnected

2. **Update Frequency**
   - Resource spawner updates once per second
   - UI updates only when progress changes
   - Network traffic minimized

3. **Spawn Point Efficiency**
   - Random selection from available points
   - No pathfinding required for spawning
   - Minimal server load

## Success Criteria

Phase 3 is successfully implemented when:

- ✅ Resources spawn at configured intervals
- ✅ Players can collect components by walking into them
- ✅ Cure progress updates in real-time for all players
- ✅ Cure stations are interactable with ProximityPrompts
- ✅ Detailed UI shows component breakdown
- ✅ Victory triggers at 100% completion
- ✅ All players receive victory notification
- ✅ Game ends when cure completes
- ✅ No errors in Output during gameplay
- ✅ Multi-player synchronization works correctly

## Next Steps

After Phase 3 verification:

1. **Phase 4: Alliance System**
   - Player-to-player alliances
   - No friendly fire between allies
   - Betrayal mechanics

2. **Phase 5: Polish & Balancing**
   - Sound effects
   - Visual effects
   - UI improvements
   - Difficulty tuning

## Support

For issues or questions:
1. Check Output for error messages
2. Verify all files are in correct locations
3. Review this testing guide
4. Check IMPLEMENTATION_SUMMARY.md for architecture details
5. Review API_DOCUMENTATION.md for function references
