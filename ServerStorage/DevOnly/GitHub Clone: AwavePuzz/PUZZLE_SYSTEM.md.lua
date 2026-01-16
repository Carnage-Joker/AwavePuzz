-- @ScriptType: Script
# Puzzle System Documentation - AwavePuzz

## Overview

The puzzle system is a core mechanic in AwavePuzz that requires players to solve mini-games at cure stations after collecting 5 of each component type. Successfully completing all 6 puzzles (5 component-specific + 1 final synthesis) is necessary to synthesize the cure and win the game.

## Puzzle Types

### 1. Mathematical Puzzle (Chemical A)
- **Type**: Arithmetic/Geometric sequences and equations
- **Description**: Players must identify patterns in number sequences or solve simple equations
- **Time Limit**: 60 seconds
- **Examples**:
  - Arithmetic: `2, 4, 6, ?, 10` (Answer: 8)
  - Geometric: `2, 4, 8, ?, 32` (Answer: 16)
  - Equation: `7 × 5 = ?` (Answer: 35)

### 2. Pattern Matching Puzzle (Chemical B)
- **Type**: Shape and number pattern recognition
- **Description**: Players must identify the next element in a repeating pattern
- **Time Limit**: 60 seconds
- **Examples**:
  - Shape: `Circle, Square, Triangle, Circle, Square, ?` (Answer: Triangle)
  - Numbers: `2, 4, 6, 8, ?` (Answer: 10)

### 3. Color Matching Puzzle (Biological Sample)
- **Type**: Color arrangement
- **Description**: Players must arrange scrambled colors in the correct order
- **Time Limit**: 45 seconds
- **Difficulty**: Easy
- **Example**: Arrange RGB spectrum from red to violet

### 4. Logic Puzzle (Research Notes)
- **Type**: Deduction grid (simplified)
- **Description**: Use logical clues to deduce correct arrangements
- **Time Limit**: 90 seconds
- **Difficulty**: Hard
- **Note**: Simplified for MVP - currently requires entering "correct" as answer

### 5. Abstract Puzzle (Catalyst)
- **Type**: Node connection (simplified)
- **Description**: Connect nodes to form complete circuit
- **Time Limit**: 60 seconds
- **Difficulty**: Medium
- **Note**: Simplified for MVP - currently requires entering "circuit" as answer

### 6. Final Synthesis Puzzle
- **Type**: Multi-stage combination
- **Description**: Combines elements from all 5 component puzzles in sequence
- **Time Limit**: 120 seconds
- **Difficulty**: Very Hard
- **Requirement**: All 5 component puzzles must be solved first
- **Result**: Completing this puzzle synthesizes the cure and triggers victory

## Gameplay Flow

### Component Collection Phase
1. Players collect cure component pieces scattered around the map
2. Each component type requires 5 pieces to unlock its puzzle
3. Components collected: Chemical A, Chemical B, Biological Sample, Research Notes, Catalyst

### Puzzle Attempt Phase
1. When a player has 5 of a specific component, they receive a notification
2. Player approaches any cure station (green glowing structure)
3. Press the interaction prompt to open the puzzle menu
4. Select which component puzzle to attempt
5. Solve the puzzle within the time limit
6. Upon success, receive currency reward and component is "locked in"

### Final Synthesis Phase
1. After solving all 5 component puzzles, player can attempt final synthesis
2. Final synthesis is a multi-stage puzzle combining all previous puzzle types
3. Successfully completing final synthesis:
   - Awards large currency bonus
   - Synthesizes the cure
   - Triggers victory condition for all players

## Betrayal Mechanics

### Component Stealing
- Breaking an alliance allows stealing collected components from the betrayed player
- 50% chance to steal each component type
- Stolen components can be used by the betrayer

### Puzzle Stealing
- Breaking an alliance allows stealing solved puzzles from the betrayed player
- 50% chance to steal each solved puzzle
- Betrayed player has 50% chance to have their puzzles reset

### Strategy Implications
- **Early Game**: Cooperation beneficial for component collection
- **Mid Game**: Trust becomes important as puzzles are solved
- **Late Game**: Risk vs reward - betray to steal progress or maintain alliance for shared victory

## Server Architecture

### PuzzleService (Server)
- Manages puzzle state per player
- Validates puzzle solutions server-side (anti-cheat)
- Tracks puzzle attempts and cooldowns
- Handles betrayal mechanics
- Triggers victory condition on final synthesis

### CureService Integration
- Tracks component collection per player
- Notifies when puzzles become available
- Updates global cure progress
- Coordinates with PuzzleService for puzzle triggering

### Remote Events
- `RequestPuzzle` - Client requests to start a puzzle
- `SubmitPuzzleAnswer` - Client submits solution
- `OpenPuzzleUI` - Server tells client to display puzzle
- `PuzzleCompleted` - Server notifies successful completion
- `PuzzleFailed` - Server notifies failure

## Client UI

### Puzzle Menu UI
- Shows available component puzzles
- Displays requirements (5 components needed)
- Shows which puzzles are already solved
- Final synthesis button unlocks when all 5 are complete

### Puzzle UI
- Dynamic interface based on puzzle type
- Timer display (changes color as time runs out)
- Input methods appropriate to puzzle type:
  - Text input for mathematical/pattern puzzles
  - Click-to-swap for color puzzles
  - Text input for logic/abstract (simplified)
- Submit button to send answer

### Notifications
- Success notification with currency reward
- Failure notification with retry instructions
- Puzzle availability notifications

## Configuration

### Puzzle Timing
```lua
PuzzleConfig.ComponentPuzzles[componentName] = {
    timeLimit = 60, -- seconds
}
PuzzleConfig.FinalPuzzle = {
    timeLimit = 120, -- seconds
}
```

### Rewards
```lua
PuzzleConfig.Rewards = {
    componentPuzzleSolved = 50, -- Currency per component puzzle
    finalPuzzleSolved = 200, -- Currency for final synthesis
    timeBonusMultiplier = 1.5, -- Bonus for solving quickly
}
```

### Penalties
```lua
PuzzleConfig.Penalties = {
    retryDelay = 10, -- Seconds before can retry
    maxAttempts = 3, -- Max attempts per puzzle (0 = unlimited)
}
```

### Betrayal Settings
```lua
PuzzleConfig.BetrayalMechanics = {
    canStealSolvedPuzzles = true,
    canStealComponents = true,
    betrayalPuzzleResetChance = 0.5, -- 50% chance
    stealPercentage = 0.5, -- Steal 50% of progress
}
```

## Setup Instructions

### Roblox Studio Setup
1. Place cure stations in the workspace:
   - Create a folder named "CureStations" in Workspace
   - Add Part or Model instances to this folder
   - CureStationSetup.lua will automatically add ProximityPrompts

2. Or let the system create a default cure station at origin (0, 0, 0)

### Testing Procedures
1. **Test Component Collection**:
   - Collect 5 of one component type
   - Verify notification appears
   - Approach cure station
   - Verify puzzle menu opens

2. **Test Puzzle Completion**:
   - Attempt a puzzle
   - Submit correct answer
   - Verify success notification and currency reward
   - Verify puzzle shows as solved in menu

3. **Test Betrayal**:
   - Form alliance with another player
   - Both players solve some puzzles
   - Break alliance
   - Verify puzzle progress is affected

4. **Test Final Synthesis**:
   - Solve all 5 component puzzles
   - Verify final synthesis unlocks
   - Complete final synthesis
   - Verify victory condition triggers

## API Reference

### PuzzleService Methods
- `initializePlayer(player)` - Initialize puzzle tracking for player
- `handlePuzzleRequest(player, componentName)` - Start puzzle attempt
- `handlePuzzleAnswer(player, componentName, answer)` - Validate solution
- `checkPlayerReadyForFinal(player)` - Check if can attempt synthesis
- `onBetrayal(betrayer, victim)` - Handle puzzle stealing

### CureService Methods
- `handleDepositComponent(player, componentName)` - Process component collection
- `notifyPuzzleAvailable(player, componentName)` - Alert player puzzle is ready
- `onFinalSynthesisComplete(player)` - Trigger victory
- `canAttemptFinalSynthesis(player)` - Check synthesis eligibility

## Troubleshooting

### Puzzle Not Appearing
- Check player has 5 of the component
- Verify cure station has ProximityPrompt
- Check RemoteEvents exist in ReplicatedStorage

### Answer Not Validating
- Ensure answer format matches expected type (number for math, string for others)
- Check server console for validation messages
- Verify puzzle data was generated correctly

### Betrayal Not Working
- Confirm AllianceService is linked to PuzzleService
- Check betrayal config settings enabled
- Verify players were actually allied before betrayal

## Future Enhancements

### Potential Improvements
1. More complex logic puzzles with actual deduction grids
2. Advanced abstract puzzles with pathfinding visualization
3. Mini-game variations for replayability
4. Difficulty scaling based on wave number
5. Co-op puzzles requiring multiple players
6. Puzzle leaderboards (fastest completion times)
7. Visual effects for puzzle completion
8. Sound effects for puzzle interactions

### Balance Adjustments
- Time limits can be adjusted per puzzle type
- Betrayal mechanics can be tuned (steal percentage, reset chance)
- Reward values can be balanced
- Max attempts can be configured per difficulty

## Conclusion

The puzzle system adds strategic depth to AwavePuzz by requiring players to balance combat, resource collection, and puzzle-solving. The betrayal mechanics create tension and meaningful choices about cooperation versus competition. The final synthesis puzzle provides a clear victory path while maintaining the social dynamics that make each game unique.

---

**Version**: 1.0  
**Last Updated**: 2025-11-23  
**Status**: ✅ Implemented - Ready for Testing
