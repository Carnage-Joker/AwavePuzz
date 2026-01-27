# Ammo Display Investigation Report

## Problem Statement
Ammo is correctly displayed and updated in the lobby, but NOT when the round starts.

## System Architecture

### Client-Side Components
1. **FPSHUD.lua** - Displays ammo UI (bottom-right corner)
2. **FPSWeaponController.lua** - Handles weapon input and receives server updates
3. **BindableEvents** - Local events for communication between client modules

### Server-Side Components  
1. **FPSWeaponService.lua** - Tracks ammo per player/weapon, authoritative source
2. **GameManager.lua** - Orchestrates game state, handles character spawning
3. **PlayerManager.lua** - Manages player data including equipped weapons

### Communication Flow
```
Server (FPSWeaponService)
  ↓ AmmoUpdate RemoteEvent
Client (FPSWeaponController)
  ↓ AmmoUpdate BindableEvent
Client (FPSHUD)
  ↓ updateAmmoDisplay()
  ↓ UI Updated
```

## Behavior Analysis

### In Lobby (Working ✅)
1. Player joins game
2. `GameManager:onPlayerAdded()` called
3. `FPSWeaponService:initializePlayer()` initializes ammo
4. Server sends `AmmoUpdate` RemoteEvent
5. Client receives and displays ammo correctly

### When Round Starts (Not Working ❌)
1. `PlayerSpawnManager:spawnAllPlayersOnMap()` called
2. `player:LoadCharacter()` destroys and recreates character
3. `GameManager.hookCharacter()` called on respawn
4. Waits 0.1s (WEAPON_SYNC_DELAY)
5. Sends `WeaponLoadoutUpdate` and `AmmoUpdate`
6. **Expected**: Client receives and displays ammo
7. **Actual**: Ammo UI not updating (to be confirmed with debug logs)

## Potential Root Causes

### 1. Timing Issues
- **0.1s delay may not be sufficient** for client to be ready
- Client controllers may not be fully initialized after character respawn
- BindableEvent connections might not be ready

### 2. BindableEvent Synchronization
- FPSWeaponController creates/gets reference to BindableEvent on module load
- FPSHUD connects to BindableEvent on initialization
- If BindableEvent is recreated, references become stale
- **Risk**: FPSWeaponController fires old event, FPSHUD listens to new event

### 3. State Desynchronization
- Client's `currentWeapon` might not match server's `equippedWeapon`
- FPSWeaponController previously had checks that dropped mismatched updates
- Recent fixes added syncing logic, but might have edge cases

### 4. Missing Initialization
- Initial ammo display shows hardcoded values (30/120)
- If server update is delayed or lost, UI shows incorrect data
- No retry mechanism for failed updates

### 5. UI Visibility Logic
- `updateAmmoDisplay()` hides UI if current and reserve are both nil
- If server sends incomplete data or update is lost, UI becomes hidden
- Once hidden, subsequent updates might not make it visible again

## Investigation with Debug Logging

### Enabled Debug Flags
- `DEBUG_AMMO = true` in FPSWeaponService.lua
- `DEBUG_AMMO = true` in FPSWeaponController.lua  
- `DEBUG_AMMO = true` in FPSHUD.lua

### Expected Log Sequence (Working)
```
[FPSWeaponService] ✓ Sent ammo update to PlayerName: Pistol (current=30, reserve=120, max=30)
[FPSWeaponController] AmmoUpdate received - weaponId=Pistol, current=30, reserve=120, max=30
[FPSWeaponController] ✓ Ammo update applied: Pistol (current=30, reserve=120, max=30)
[FPSHUD] AmmoUpdate bindable event received - data type=table
[FPSHUD] AmmoUpdate data - current=30, reserve=120, max=30, isReloading=false
[FPSHUD] updateAmmoDisplay called - current=30, reserve=120, max=30, isReloading=false
[FPSHUD] ✓ Ammo display updated - showing 30/120 (max=30)
```

### If Broken, Look For
- Missing server send message → Server not calling sendAmmoUpdate
- Missing controller receive → RemoteEvent not firing or connection dropped
- Missing FPSHUD receive → BindableEvent not being fired or connection dropped
- Data validation failures → Incomplete data being sent
- UI hiding messages → UI becoming invisible due to missing data

## Recommended Fixes

### 1. Increase Weapon Sync Delay
Change `WEAPON_SYNC_DELAY` from 0.1 to 0.3 or 0.5 seconds to ensure client is ready.

### 2. Add Retry Logic
If ammo update fails to send or receive, retry after a delay.

### 3. Consolidate BindableEvent Creation
Ensure only ONE instance of each BindableEvent exists and all modules use same instance.

### 4. Add Heartbeat to Verify UI State
Periodically check if UI should be visible but isn't, and request server update.

### 5. Log All State Transitions
Add comprehensive logging to track every step of the update flow.

## Next Steps
1. Test with debug logging enabled
2. Capture console output during lobby and round start
3. Identify which step in the flow is failing
4. Implement targeted fix based on findings
5. Retest to confirm fix works
6. Disable debug logging
7. Document final solution
