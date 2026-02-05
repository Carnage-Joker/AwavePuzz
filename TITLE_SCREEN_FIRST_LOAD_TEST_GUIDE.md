# Title Screen First Load - Testing Guide

## Overview

This guide describes how to test the Title Screen First Load implementation in Roblox Studio. The changes ensure that the Title Screen is the **absolute first thing** players see when joining the game - no character, no map, no lobby flash.

## What Changed

### Server Changes
1. **CharacterAutoLoads = false**: Server now disables automatic character spawning
2. **ClientReady event (reserved)**: Defined on the server for future use; currently clients do not listen for this signal
3. **Explicit LoadCharacter()**: Server only spawns character after title screen is completed

### Client Changes
1. **Boot.client.lua**: New entry point that runs before ClientMainModule
2. **Immediate camera control**: Camera set to Scriptable mode at safe position (0, 10000, 0)
3. **CoreGui disabled**: Default Roblox UI hidden during boot
4. **State-driven initialization**: Client starts in TitleScreen state

## Testing Checklist

### ✅ Test 1: First Join - No Flash
**Goal**: Verify no map, lobby, or character is visible before title screen

**Steps:**
1. Open Roblox Studio
2. Open the AwavePuzz project
3. Click **Play** (single player test)
4. **OBSERVE**: What do you see first?

**Expected Results:**
- ✅ Black screen appears immediately
- ✅ Title Screen UI appears (game title + "Press any key to continue")
- ✅ NO map visible
- ✅ NO character visible
- ✅ NO lobby visible
- ✅ NO default Roblox spawn location visible

**Failure Indicators:**
- ❌ You see the lobby or map for even a single frame before title screen
- ❌ You see a character spawning before title screen
- ❌ You see default Roblox UI elements

### ✅ Test 2: Title Screen Interaction
**Goal**: Verify title screen responds correctly and transitions smoothly

**Steps:**
1. Join game (see Test 1)
2. Wait for Title Screen to appear
3. Press any key or click the screen
4. **OBSERVE**: What happens?

**Expected Results:**
- ✅ Title Screen fades out smoothly
- ✅ Character spawns in lobby
- ✅ CoreGui (Roblox UI) re-enables
- ✅ Camera control transfers to first-person camera
- ✅ Player can move around lobby
- ✅ Smooth transition with no jarring cuts

**Failure Indicators:**
- ❌ Title screen doesn't respond to input
- ❌ Character doesn't spawn after clicking
- ❌ Camera stays locked/frozen
- ❌ Player can't move after title screen

### ✅ Test 3: Server Output Logs
**Goal**: Verify server boot sequence is correct

**Steps:**
1. Open Output window in Roblox Studio (View → Output)
2. Clear output (right-click → Clear)
3. Click **Play**
4. **OBSERVE**: Server logs

**Expected Results:**
```
=== [BOOT][SERVER] Aether Wave: Convergence Server Starting ===
[BOOT][SERVER] Phase 0: Disabling character auto-load...
[BOOT][SERVER] Phase 0 complete: CharacterAutoLoads = false
[BOOT][SERVER] Phase 1: Initializing remote registry...
[RemoteRegistry] [BOOT][SERVER] Initializing remote registry...
[BOOT][SERVER] Phase 1 complete: Remote registry initialized
[BOOT][SERVER] Phase 2: Loading shared configuration...
[BOOT][SERVER] Phase 2 complete: Configuration loaded
[BOOT][SERVER] Phase 3: Initializing services...
[GameManager] Starting in TITLE_SCREEN state
...
[BOOT][SERVER] Phase 4: Setting up player connection handlers...
[STATE] Player [YourName] joined the game
[BOOT][SERVER] Sent ClientReady signal to [YourName]
...
=== [BOOT][SERVER] Server Ready ===
```

**Key Things to Check:**
- ✅ Phase 0 runs first and sets CharacterAutoLoads = false
- ✅ GameManager starts in TITLE_SCREEN state
- ✅ ClientReady signal is sent to player
- ✅ No errors or warnings about remotes

**Failure Indicators:**
- ❌ CharacterAutoLoads message missing
- ❌ GameManager starts in WAITING or LOBBY state
- ❌ Errors about missing remotes (especially ClientReady)

### ✅ Test 4: Client Output Logs
**Goal**: Verify client boot sequence is correct

**Steps:**
1. Open Output window in Roblox Studio
2. Clear output
3. Click **Play**
4. **OBSERVE**: Client logs (may be mixed with server logs)

**Expected Results:**
```
=== [BOOT][CLIENT] Boot.client.lua - First Load Entry Point ===
[BOOT][CLIENT] Phase 1: Taking immediate camera control...
[BOOT][CLIENT] Phase 1 complete: Camera controlled, screen black
[BOOT][CLIENT] Phase 2: Loading ClientMainModule...
=== [BOOT][CLIENT] Aether Wave: Convergence Client Starting ===
[BOOT][CLIENT] Player: [YourName]
[BOOT][CLIENT] Phase 1: Waiting for remote registry...
[BOOT][CLIENT] Phase 1 complete: Remote registry ready
...
[BOOT][CLIENT] ✓ TitleScreenUI instance created and remotes bound
...
[ClientState] Applying state: TitleScreen
[BOOT][CLIENT] Phase 6.5 complete: Client state router active
...
[TitleScreenUI] Received GameStateUpdate with state=TitleScreen
[TitleScreenUI] Showing title screen
```

**Key Things to Check:**
- ✅ Boot.client.lua runs first
- ✅ Camera control is taken immediately
- ✅ ClientMainModule loads after Boot.client.lua
- ✅ TitleScreenUI is created and remotes are bound
- ✅ Initial state is TitleScreen
- ✅ Title screen shows in response to GameStateUpdate

**Failure Indicators:**
- ❌ ClientMain.client.lua runs instead of Boot.client.lua
- ❌ Camera control happens after UI initialization
- ❌ TitleScreenUI fails to load or bind remotes
- ❌ Initial state is not TitleScreen

### ✅ Test 5: Title Screen Continue Flow
**Goal**: Verify server responds to title screen continue and spawns character

**Steps:**
1. Join game and see title screen
2. Press any key to continue
3. **OBSERVE**: Output logs

**Expected Results:**
```
[TitleScreenUI] Player clicked continue, notifying server
[Flow] Player [YourName] passed title screen (TitleScreenContinue)
[Flow] Loading character for [YourName] after title screen
[STATE] Player [YourName]'s character loaded
[PlayerSpawnManager] [YourName] -> LOBBY (visible, can move)
[Flow] All players passed title screen
[Flow] TitleScreenContinue -> Lobby (entering lobby)
```

**Key Things to Check:**
- ✅ Title screen notifies server of continue
- ✅ Server calls LoadCharacter() after continue
- ✅ Character spawns in lobby (visible, can move)
- ✅ State transitions to Lobby

**Failure Indicators:**
- ❌ Character doesn't spawn after continue
- ❌ LoadCharacter() not called
- ❌ State doesn't transition to Lobby

### ✅ Test 6: Multi-Player Test
**Goal**: Verify multiple players can join and see title screen correctly

**Steps:**
1. In Studio, click **Play** and select **2 Players** or more
2. **OBSERVE**: Each player's viewport

**Expected Results:**
- ✅ Each player sees title screen first (no character/map flash)
- ✅ Players can progress through title screen independently
- ✅ Late-joining players still see title screen first
- ✅ State synchronization works across all clients

**Failure Indicators:**
- ❌ One player sees map/character while another is on title screen
- ❌ Late joiners skip title screen
- ❌ State desync between clients

## Common Issues and Solutions

### Issue: Character spawns before title screen
**Symptom**: Player appears in lobby before title screen shows

**Possible Causes:**
1. CharacterAutoLoads not set to false
2. Boot.client.lua not running first (ClientMain.client.lua still active)
3. Server calling LoadCharacter() too early

**Solution:**
- Check server logs for "CharacterAutoLoads = false" message
- Verify ClientMain.client.lua is disabled (should be .disabled extension)
- Check that LoadCharacter() is only called after TitleScreenContinue

### Issue: Title screen doesn't show
**Symptom**: Black screen persists, no title screen UI

**Possible Causes:**
1. TitleScreenUI module failed to load
2. RemoteRegistry missing ClientReady or GameStateUpdate
3. State not set to TitleScreen

**Solution:**
- Check client logs for TitleScreenUI initialization messages
- Verify ClientReady and GameStateUpdate remotes exist in RemoteRegistry
- Verify GameManager starts in TITLE_SCREEN state

### Issue: Camera stays frozen after title screen
**Symptom**: Can't look around after clicking continue

**Possible Causes:**
1. Camera not restored to normal control
2. FirstPersonCamera module not initializing
3. State not transitioning to Lobby

**Solution:**
- Check that camera.CameraType changes from Scriptable to Custom/Scriptable (FPS)
- Verify FirstPersonCamera.initialize() is called in ClientMainModule
- Check state transitions in output logs

### Issue: Player can't move after title screen
**Symptom**: Character spawns but movement doesn't work

**Possible Causes:**
1. Movement not re-enabled after title screen
2. State stuck in TitleScreen
3. FPSMovement module not initialized

**Solution:**
- Check ClientState logs for state transitions
- Verify applyState("Lobby") is called and enables movement
- Check that FPSMovement.setEnabled(true) is called

## Performance Validation

### Frame Timing
**Goal**: Ensure title screen appears within first few frames (< 1 second)

**Steps:**
1. Join game
2. Count frames or estimate time before title screen appears

**Expected:**
- Title screen visible within 0.5-1 second of join

**Acceptable:**
- Up to 2 seconds if network is slow

**Unacceptable:**
- More than 3 seconds to show title screen

## Regression Testing

### Verify Existing Features Still Work

After testing the new boot flow, verify these existing features:
- [ ] Lobby portals work
- [ ] Map voting works (if enabled)
- [ ] Wave gameplay starts correctly
- [ ] Weapons work
- [ ] Cure system works
- [ ] Alliance system works
- [ ] Shop works
- [ ] Spectator mode works

## Screenshot Checklist

Take screenshots of:
1. **Initial Join**: Black screen before title screen
2. **Title Screen**: Full title screen UI
3. **Transition**: Fade out (if visible)
4. **Lobby Spawn**: Character in lobby after title screen
5. **Output Logs**: Server and client boot logs

Save screenshots for documentation and debugging.

## Success Criteria

The implementation is successful if:
- ✅ No map, lobby, or character visible before title screen (0 frames of flash)
- ✅ Title screen appears within 1 second of join
- ✅ Title screen responds to input and transitions smoothly
- ✅ Character spawns only after title screen continue
- ✅ Camera control works correctly throughout
- ✅ Multi-player synchronization works
- ✅ No errors in output logs
- ✅ All existing features still work

## Failure Cases

The implementation fails if:
- ❌ Any visual flash of map/lobby/character before title screen
- ❌ Title screen doesn't show at all
- ❌ Character spawns automatically before title screen
- ❌ Camera or movement doesn't work after title screen
- ❌ Errors in output logs
- ❌ Existing features broken

## Reporting Issues

If you find issues during testing:

1. **Capture Output Logs**: Copy all relevant logs from Output window
2. **Take Screenshots**: Show the visual issue
3. **Document Steps**: Exact steps to reproduce
4. **Note Environment**: Studio version, settings, etc.
5. **Report**: Create a detailed issue report

---

**Last Updated**: 2026-02-05  
**Version**: 1.0  
**Related Files**: Boot.client.lua, Main.server.lua, GameManager.lua, ClientMainModule.lua
