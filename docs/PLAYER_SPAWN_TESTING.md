# Player Spawn Management Testing Guide

## Overview
This guide describes how to test the new player spawn management system that ensures players spawn in a lobby waiting area before the map loads, then spawn on the map at position (5000, 0, 0) after voting completes.

## Changes Made

### New Components
1. **PlayerSpawnManager** (`ServerScriptService/PlayerSpawnManager.lua`)
   - Manages when and where players spawn
   - Keeps players in invisible waiting state during lobby
   - Spawns players on map after voting completes

2. **LobbySetup** (`ServerScriptService/LobbySetup.lua`)
   - Creates a physical lobby structure at (5000, 0, 0)
   - Provides a waiting area (though players are invisible during voting)
   - Destroyed when map loads, recreated for next round

3. **GameManager Integration**
   - Modified to use PlayerSpawnManager
   - Spawns players in lobby during waiting/voting phase
   - Spawns players on map after map loads

## Expected Behavior

### Player Join Flow
1. **Player Joins Server**
   - Player character spawns initially
   - PlayerSpawnManager immediately detects and repositions character to (5000, 10000, 0) - high above map
   - Character is made invisible and non-collidable (menu-only state)
   - Player sees voting UI but doesn't see their character

2. **Lobby/Voting Phase**
   - Players remain in invisible waiting state
   - Players can see and interact with map voting UI
   - No character visible or interactive
   - Physical lobby structure exists at (5000, 0, 0) but is mostly decorative

3. **Map Loads After Voting**
   - Selected map loads at position (5000, 0, 0)
   - Physical lobby is destroyed (cleanup)
   - PlayerSpawnManager spawns all players on the map
   - Characters reload and spawn near base camp (around 5000, Y, 0)
   - Characters become visible and interactive
   - Players can now play the game normally

4. **New Round**
   - After round ends, players return to invisible lobby state
   - Lobby structure is recreated
   - Process repeats from step 2

## Testing Checklist

### In Roblox Studio

1. **Initial Player Join**
   - [ ] Open the game in Roblox Studio
   - [ ] Start a test server with at least 2 players
   - [ ] Verify players spawn but are invisible (high above map)
   - [ ] Verify lobby UI is visible and functional
   - [ ] Check Output window for PlayerSpawnManager logs

2. **Lobby State**
   - [ ] Players should NOT see their characters
   - [ ] Players should see voting UI
   - [ ] Check that physical lobby exists at (5000, 0, 0) using Workspace explorer
   - [ ] Verify players are at position approximately (5000, 10000, 0)

3. **Vote and Map Load**
   - [ ] Cast votes for a map
   - [ ] Wait for voting to complete
   - [ ] Verify map loads at position (5000, 0, 0)
   - [ ] Verify lobby structure is destroyed
   - [ ] Check Output window for "Map loaded, spawning players on map" message

4. **Character Spawn on Map**
   - [ ] Verify all players' characters reload
   - [ ] Verify characters spawn near base camp (around position 5000, Y, 0)
   - [ ] Verify characters are now VISIBLE
   - [ ] Verify characters can move and interact
   - [ ] Verify first-person camera works (handled by FPS system)
   - [ ] Verify collisions work properly

5. **Gameplay**
   - [ ] Play through a wave to ensure normal gameplay works
   - [ ] Verify weapons, movement, and combat work as expected
   - [ ] Check that nothing broke with spawn changes

6. **New Round**
   - [ ] Complete or fail the round
   - [ ] Verify lobby is recreated
   - [ ] Verify players return to invisible state
   - [ ] Start new voting round
   - [ ] Repeat tests to ensure system works across multiple rounds

## Debugging

### Common Issues

**Issue: Players spawn at wrong location**
- Check MapManager to ensure map loads at (5000, 0, 0)
- Check BaseCampSetup to ensure base camp is created properly
- Review PlayerSpawnManager.getMapSpawnPosition() logic

**Issue: Players remain invisible after spawning on map**
- Check character visibility restoration in PlayerSpawnManager.onCharacterAdded()
- Verify spawn state is set to "map" before LoadCharacter() is called
- Check Output window for any errors

**Issue: Players see character during lobby**
- Verify playerSpawnState is set to "waiting" during lobby
- Check that onCharacterAdded() is making characters invisible
- Ensure keepPlayerInLobby() is called during resetForNewRound()

**Issue: Camera doesn't work**
- First-person camera is handled by FirstPersonCamera.lua on client side
- Check ClientController.client.lua is running properly
- Verify FPSConfig.lua has correct camera settings

### Debug Output
Check the Output window in Studio for these log messages:
- `[PlayerSpawnManager] Player X added, preparing spawn management`
- `[PlayerSpawnManager] Character added for X, state: waiting`
- `[PlayerSpawnManager] Positioned X in lobby waiting area (high above map)`
- `[GameManager] Map loaded, spawning players on map`
- `[PlayerSpawnManager] Spawning all players on map`
- `[PlayerSpawnManager] Positioned X on map at (position)`

### Console Commands
You can test spawn states manually in the command bar:
```lua
-- Get the GameManager
local gameManager = require(game.ServerScriptService.GameManager)

-- Get the PlayerSpawnManager (assuming it's accessible)
local spawnManager = gameManager.playerSpawnManager

-- Check a player's spawn state
local player = game.Players:GetChildren()[1]
print(spawnManager:getPlayerSpawnState(player))

-- Force spawn a player on map
spawnManager:spawnPlayerOnMap(player)
```

## Expected Log Output

### Player Join
```
[PlayerSpawnManager] Player Username added, preparing spawn management
[PlayerSpawnManager] Character added for Username, state: waiting
[PlayerSpawnManager] Positioned Username in lobby waiting area (high above map)
```

### Map Load and Spawn
```
[GameManager] Entering lobby...
[LobbyManager] Map voting started with N available maps
[LobbyManager] Voting ended. Selected map: MapName
[GameManager] Map loaded, spawning players on map
[PlayerSpawnManager] Spawning all players on map
[PlayerSpawnManager] Spawning Username on map
[PlayerSpawnManager] Character added for Username, state: map
[PlayerSpawnManager] Positioned Username on map at (5000, Y, Z)
```

## Notes
- The lobby structure at (5000, 0, 0) is primarily decorative during the waiting phase
  - It provides a physical space that could be used for visual elements or future features
  - Players themselves are invisible and positioned high above the map during voting
  - The structure is destroyed when the map loads to avoid conflicts
- Players have characters during lobby but they are invisible and positioned at (5000, 10000, 0)
- The FPS camera system automatically handles first-person view when characters spawn
- Each new round recreates the lobby and respawns players through the same flow
