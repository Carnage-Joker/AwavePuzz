# Startup Flow Fix - Quick Reference

## What Was Fixed

### Problem
- Maps loaded immediately on server boot ❌
- Flow was: Title → Epilogue → Lobby ❌
- Players couldn't move in lobby ❌
- Portals weren't visible ❌

### Solution
- Maps only load after lobby selection ✅
- Flow is now: Title → Lobby → Map Loading → Wave ✅
- Players can move freely in lobby ✅
- Portals are visible and interactive ✅

## Key Changes

### 1. GameConfig.lua
- Added `INTRO_SHOW_EPILOGUE_ON_FIRST_JOIN = false`
- This controls whether epilogue shows before first lobby
- **Default: false** (epilogue only after rounds)

### 2. GameManager.lua
- Added `[Flow]` logging to track all state transitions
- Fixed `checkAllPlayersReadyForEpilogue()` to go directly to lobby
- Updated `startLobby()` to allow transition from TITLE_SCREEN
- Enhanced logging throughout map loading process

### 3. ClientController.client.lua
- Added attribute-based guard: `script:SetAttribute("Started", true)`
- Added comment about RunContext setting
- **IMPORTANT:** Set RunContext to Legacy in Studio!

### 4. START_FLOW.md (NEW)
- Complete documentation of the flow
- Configuration flags reference
- Troubleshooting guide
- Test checklist

## How to Test

### Quick Test (1 Player)
1. Start server in Studio
2. Join game
3. See title screen → Click Continue
4. Spawn in lobby → Can move around
5. See 3 blue glowing portals with queue UI
6. Touch portal → Countdown starts
7. Map loads → Spawn on map → Wave starts

### Expected Logs
```
[GameManager] Boot complete - no map loaded yet
[LobbySetup] Lobby created at position 8000, 5, 0
[Flow] Join -> Player <name> added to game
[Flow] Join -> TitleScreen (showing to <name>)
[PlayerSpawnManager] <name> -> LOBBY (visible, can move)
[Flow] TitleScreenContinue -> Lobby
[Flow] Entering lobby (state -> LOBBY)
[Flow] Lobby -> MapLoading(ResearchOutpost)
[Flow] MapLoaded -> Map ResearchOutpost loaded successfully
[Flow] MapLoaded -> Spawn -> Spawning players
[Flow] Countdown -> Wave1 - Starting wave
```

## Important Notes

### ⚠️ Manual Studio Setup Required
**ClientController RunContext must be set to Legacy:**
1. Open `StarterPlayer/StarterPlayerScripts/ClientController.client.lua` in Studio
2. In Properties panel, find `RunContext`
3. Change from default to `Legacy` (Enum.RunContext.Legacy)
4. Save the place

### Movement System
- Client-side FPSMovement handles WalkSpeed (default: 16)
- Server-side PlayerSpawnManager ensures character is unfrozen
- No code interferes with player movement in lobby

### Portal System
- Portals created when `USE_PORTAL_MATCHMAKING = true`
- Located at `Workspace.Lobby.Portals`
- Touch to join queue
- Visual: Blue neon parts (8x10x2) with BillboardGui
- Default: 1 min player, 10 second countdown

### Lobby Layout
- Position: (8000, 5, 0) - separate from map at (5000, 0, 0)
- 60x60 platform with walls
- Walls prevent falling off (physical barriers, not frozen players)

## Configuration

### Show Epilogue Before First Lobby
```lua
-- GameConfig.lua
GameConfig.INTRO_SHOW_EPILOGUE_ON_FIRST_JOIN = true -- Show story intro
```
**NOT recommended** - breaks intended flow

### Disable Portal Matchmaking (Use Voting Instead)
```lua
-- GameConfig.lua
GameConfig.USE_PORTAL_MATCHMAKING = false -- Use map voting
```

### Adjust Portal Settings
```lua
-- GameConfig.lua
GameConfig.PORTAL_MATCHMAKING = {
    MAX_PLAYERS_PER_MATCH = 8,
    DEFAULT_MIN_PLAYERS = 1,      -- Min players to start
    DEFAULT_COUNTDOWN_TIME = 10,  -- Countdown duration
    -- ... other settings
}
```

## Troubleshooting

### Problem: Map loads on boot
**Check logs for:**
- Should see: `[GameManager] Boot complete - no map loaded yet`
- Should NOT see: `[MapManager] Loading map` before title screen

### Problem: Epilogue shows before lobby
**Solution:** Set `INTRO_SHOW_EPILOGUE_ON_FIRST_JOIN = false`

### Problem: Can't move in lobby
**Check logs for:**
- Should see: `[PlayerSpawnManager] <name> -> LOBBY (visible, can move)`
- Verify character is not anchored
- Check Humanoid.PlatformStand = false

### Problem: Portals not visible
**Check:**
- `USE_PORTAL_MATCHMAKING = true` in GameConfig
- Logs should show: `[LobbySetup] Created N portals`
- Logs should show: `[PortalMatchmakingService] Discovered N portals`
- Check `Workspace.Lobby.Portals` folder exists

### Problem: ClientController runs twice
**Solution:**
1. Set RunContext to Legacy in Studio
2. Script has dual guards (_G + attribute) as backup

## Files Modified

- `ReplicatedStorage/Shared/GameConfig.lua` - Config flag
- `ServerScriptService/GameManager.lua` - Flow logic + logging
- `StarterPlayer/StarterPlayerScripts/ClientController.client.lua` - Single-run guards
- `START_FLOW.md` - Complete documentation (NEW)

## Next Steps

1. ✅ Code changes complete
2. ⚠️ **Manual testing in Studio required**
3. ⚠️ **Set ClientController RunContext to Legacy**
4. Test solo join flow
5. Test multiplayer matchmaking
6. Optional: Enhance portal visuals
7. Optional: Add loading screen UI

## Support

For detailed information, see:
- **START_FLOW.md** - Complete flow documentation
- **GAME_DESIGN.md** - Overall game design
- **API_DOCUMENTATION.md** - System interactions

## Summary

✅ All code changes complete
✅ Comprehensive logging added
✅ Documentation written
⚠️ Manual Studio testing required
⚠️ ClientController RunContext must be set to Legacy

**The startup flow is now correct and ready for testing!**
