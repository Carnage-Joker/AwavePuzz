# Puzzle System Installation Guide

## Quick Setup for Testing in Roblox Studio

### Step 1: File Placement

Place the following files in your Roblox Studio project:

#### Server Scripts (ServerScriptService)
1. **MainServer.lua** - Main entry point (already updated)
2. **PuzzleService.lua** - NEW: Puzzle management
3. **CureStationSetup.lua** - NEW: Cure station setup
4. **CureService.lua** - Updated with puzzle integration
5. **AllianceService.lua** - Updated with betrayal mechanics

#### Client Scripts (StarterPlayer > StarterPlayerScripts > UI or StarterGui)
1. **PuzzleUI.client.lua** - NEW: Puzzle mini-game interface
2. **PuzzleMenuUI.client.lua** - NEW: Puzzle selection menu
3. **CureUI.client.lua** - Already exists, works with puzzle system

#### Shared Modules (ReplicatedStorage > Shared)
1. **PuzzleConfig.lua** - NEW: Puzzle definitions
2. **GameConfig.lua** - Updated with spawning config fix

### Step 2: Workspace Setup

The puzzle system will automatically create a cure station if none exists, but you can create your own:

1. Create a folder in Workspace called "CureStations"
2. Add a Part or Model to this folder:
   - Name: "CureStation1" (or any name)
   - Size: 6x8x6 (or desired size)
   - Color: Green (or any color)
   - Material: Neon (for visibility)
   - Anchored: true
3. The CureStationSetup.lua script will automatically add ProximityPrompts

#### Recommended Cure Station Setup
```
Workspace/
└── CureStations/
    ├── CureStation1 (Part or Model)
    ├── CureStation2 (Part or Model) [Optional]
    └── CureStation3 (Part or Model) [Optional]
```

### Step 3: Testing the System

#### Basic Component Collection Test
1. Play the game in Studio
2. Collect cure component pickups (glowing colored parts that spawn)
3. Collect 5 of the same component type
4. You should see a notification: "Puzzle available!"

#### Puzzle Attempt Test
1. After collecting 5 components, approach a cure station
2. Press the interaction key (default: E)
3. Puzzle menu should open showing available puzzles
4. Select a component puzzle to attempt
5. Puzzle UI should open with the mini-game

#### Puzzle Solving Test
For quick testing, here are the simplified answers:
- **Mathematical**: Solve the sequence/equation (actual math required)
- **Pattern**: Find the next element (actual pattern required)
- **Color**: Arrange colors in order (click to swap)
- **Logic**: Type "correct" (simplified for MVP)
- **Abstract**: Type "circuit" (simplified for MVP)

#### Betrayal Test (2 Players Required)
1. Form an alliance with another player
2. Both players solve some puzzles
3. One player betrays the alliance
4. Check console logs to see puzzle stealing mechanics

### Step 4: Quick Test Script

To verify the puzzle system loaded correctly, paste this into the Roblox Studio Command Bar:

```lua
local RS = game:GetService("ReplicatedStorage")
local PC = require(RS.Shared.PuzzleConfig)
print("Component puzzles:", #PC.ComponentPuzzles)
for name, puzzle in pairs(PC.ComponentPuzzles) do
    print("-", name, ":", puzzle.name)
end
print("Math puzzle test:", PC.generateMathPuzzle().answer)
```

### Step 5: Verify Remote Events

After starting the server, check ReplicatedStorage for these RemoteEvents:
- RequestPuzzle
- SubmitPuzzleAnswer  
- OpenPuzzleUI
- PuzzleCompleted
- PuzzleFailed
- CureUpdate

These are created automatically by PuzzleService on initialization.

## Common Issues and Solutions

### Issue: "Puzzle menu not opening"
**Solution**: 
- Verify CureStations folder exists in Workspace
- Check that ProximityPrompt was added to the station
- Look for errors in Output window

### Issue: "Puzzle UI not appearing"
**Solution**:
- Ensure PuzzleUI.client.lua is in StarterPlayer.StarterPlayerScripts or StarterGui
- Check that RemoteEvent "OpenPuzzleUI" exists
- Look for client-side errors in Output

### Issue: "Answer submission not working"
**Solution**:
- Verify SubmitPuzzleAnswer RemoteEvent exists
- Check server console for validation errors
- Ensure answer format matches puzzle type (number for math, string for others)

### Issue: "Components not spawning"
**Solution**:
- Check ResourceSpawner.lua is running
- Verify CURE_COMPONENT_NAMES in GameConfig.lua
- Look for ItemSpawns or ResourceSpawns folder in Workspace

### Issue: "Betrayal not stealing puzzles"
**Solution**:
- Confirm AllianceService is linked to PuzzleService in MainServer.lua
- Check PuzzleConfig.BetrayalMechanics settings
- Verify both players had actually solved puzzles before betrayal

## Configuration Tips

### Adjust Puzzle Difficulty
Edit `src/shared/PuzzleConfig.lua`:

```lua
-- Make puzzles easier
PuzzleConfig.ComponentPuzzles["Chemical A"].timeLimit = 120  -- More time
PuzzleConfig.Penalties.maxAttempts = 0  -- Unlimited attempts
```

### Adjust Betrayal Mechanics
Edit betrayal settings:

```lua
PuzzleConfig.BetrayalMechanics = {
    canStealSolvedPuzzles = true,
    stealPercentage = 0.75,  -- Steal 75% instead of 50%
    betrayalPuzzleResetChance = 0.25,  -- Lower reset chance
}
```

### Adjust Rewards
Modify puzzle rewards:

```lua
PuzzleConfig.Rewards = {
    componentPuzzleSolved = 100,  -- More currency
    finalPuzzleSolved = 500,
    timeBonusMultiplier = 2.0,  -- Better time bonus
}
```

## Performance Notes

- Puzzle UI is lightweight (no heavy computations)
- Server-side validation prevents cheating
- Color puzzle may have slight performance impact with many blocks
- Timer updates run on Heartbeat (efficient)

## Next Steps

After basic testing:
1. Balance puzzle time limits based on difficulty
2. Test with multiple players
3. Verify betrayal mechanics work as intended
4. Adjust currency rewards for progression balance
5. Test final synthesis puzzle completion
6. Verify victory condition triggers correctly

## Need Help?

- Check PUZZLE_SYSTEM.md for detailed mechanics
- Review API_DOCUMENTATION.md for service methods
- Look at server console output for debugging info
- Test with TestPuzzleSystem.lua for component verification

---

**Version**: 1.0  
**Last Updated**: 2025-11-23  
**For**: AwavePuzz Puzzle System
