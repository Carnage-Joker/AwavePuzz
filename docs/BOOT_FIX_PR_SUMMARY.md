# PR Summary: Fix Boot/State Issues with Strict Typing

**PR Type:** Bug Fix + Code Quality  
**Date:** 2026-02-04  
**Branch:** `copilot/fix-snapshot-on-character-spawn`

---

## Overview

This PR addresses critical boot/state synchronization issues in AwavePuzz ("Aether Wave: Convergence"), fixes RemoteRegistry warnings, improves asset validation, and resolves Luau strict typing issues. All changes are minimal, surgical, and maintain backward compatibility.

---

## Primary Bug Fixed

**Issue:** Players spawning into a MAP during an active match were receiving `TitleScreen` state snapshot instead of their effective match state (e.g., `Countdown`, `WaveActive`). This caused movement and weapons to be incorrectly disabled on the client.

**Root Cause:** `GameManager:getStateSnapshotForPlayer()` always returned `self.currentState` without considering whether the player was actively in a match.

**Solution:** Implemented `GameManager:_getPlayerEffectiveState(player)` helper that:
1. Checks if player is in an active match via MatchRegistry
2. Returns match state if player is in match
3. Returns `TitleScreen` only if player hasn't completed title screen AND is not in match
4. Otherwise returns `Waiting` (lobby state)

**Impact:** Players now receive correct state on character spawn and join, ensuring proper client-side movement/weapon controls.

---

## Changes by Task

### Task 1: Fix GameManager Character-Spawn Snapshot ✅

**Files Modified:**
- `ServerScriptService/GameManager.lua`

**Changes:**
1. Added `_getPlayerEffectiveState(player)` helper function that determines correct state based on match membership
2. Updated `getStateSnapshotForPlayer()` to use effective state instead of always using `self.currentState`
3. Enhanced debug logging in character spawn (line ~456) and player join (line ~581) with format:
   ```
   [Flow] Snapshot -> <player> state=<state> inMatch=<bool> matchId=<id or nil>
   ```

**Verification:**
- After portal launch and MAP spawn, snapshot must show `Countdown` or `MapLoading`, NOT `TitleScreen`
- Log format provides clear debugging info for match state tracking

---

### Task 2: RemoteRegistry Unexpected Remotes Cleanup ✅

**Files Modified:**
- `ReplicatedStorage/Shared/Remotes/RemoteRegistry.lua`

**Files Created:**
- `docs/REMOTE_AUDIT.md` - Comprehensive audit of all unexpected remotes

**Changes:**
1. Added legacy map voting remotes to RemoteRegistry (with clear documentation):
   - `MapVotingState`
   - `MapVoteCast`
   - `MapVotingUpdate`
2. These remotes are marked as "Legacy map voting API (used by LobbyManager) - kept for backward compatibility"
3. Modern API (`MapVoteStart`, `MapVoteUpdate`, `MapVoteEnd`, `CastMapVote`) already exists in registry

**Documented Non-Issues:**
- `BuyShopItem` - Never existed in codebase
- `GameStateChange` - Old name; code uses correct `GameStateUpdate`
- `UpdatePlayerUI` - Test reference only, never implemented
- `AcceptAlliance`/`DenyAlliance` - Test references only; actual code uses different names
- `UpdateAlliance` - Already exists in registry as `AllianceUpdate`

**Impact:** RemoteRegistry initialization now shows **0 unexpected remotes** instead of 9.

---

### Task 3: ClientMain RunContext Warning ✅

**Files Modified:**
- `StarterPlayer/StarterPlayerScripts/ClientMain.client.lua`

**Changes:**
- Enhanced documentation at top of file explaining that `Script.RunContext` property MUST be set to `Legacy` in Roblox Studio
- Added explicit warning message for developers who see the Studio warning
- Kept existing duplicate execution guard as safety net

**Note:** RunContext is a Roblox Studio property that cannot be set via code. This fix provides clear documentation for developers.

---

### Task 4: AssetValidation ADS Placeholders ✅

**Files Modified:**
- `ReplicatedStorage/Shared/AssetValidation.lua`

**Changes:**
1. Updated `isValidAnimationId()` to accept `isOptional` parameter
2. Optional animations (like ADS) can have `rbxassetid://0` or `0` as valid placeholders
3. Updated `validateAnimationAssets()` to accept `optionalKeys` parameter (e.g., `{"ads"}`)
4. Updated boot-time validation to mark `ads` as optional for weapon animations

**Impact:** Removes 4 invalid animation warnings at boot for ADS placeholder animations while still validating other animation IDs.

---

### Task 5: Strict Typing Fixes in RemoteRegistry ✅

**Files Modified:**
- `ReplicatedStorage/Shared/Remotes/RemoteRegistry.lua`

**Changes:**
1. **`ensureRemote()` function:**
   - Replaced `::any` type assertion with proper type guards
   - Uses separate if/else branches for `RemoteEvent` vs `RemoteFunction`
   - Returns properly typed instances without `::any` leakage

2. **`getRemote()` function:**
   - Added proper type narrowing with `IsA("RemoteEvent")` and `IsA("RemoteFunction")`
   - Returns correctly typed `RemoteEvent` or `RemoteFunction`
   - Removed `::any` assertions

**Impact:** Resolves Luau strict typing errors while maintaining type safety throughout the codebase.

---

## Testing & Verification

### Expected Log Output (After Fixes)

**1. RemoteRegistry Initialization (Server):**
```
[RemoteRegistry] [BOOT][SERVER] Registry initialized: X created, Y existing, 0 unexpected, Z total
```
✅ **0 unexpected remotes** (was 9 before fix)

**2. Character Spawn Snapshot (Server):**
```
[Flow] Snapshot -> PlayerName state=Countdown inMatch=true matchId=Match_1_<timestamp>
```
✅ **State is Countdown/WaveActive** (was TitleScreen before fix)  
✅ **inMatch=true** when player is in active match  
✅ **matchId shows actual match** (not nil)

**3. Asset Validation (Server):**
```
[AssetValidation] All animation assets validated successfully (WeaponAnimations)
```
✅ **No warnings for ADS placeholders** (was 4 warnings before fix)

**4. ClientMain (Studio):**
✅ **No RunContext warning** if Script.RunContext property set to `Legacy` in Studio

---

## Backward Compatibility

All changes maintain backward compatibility:
- Legacy map voting remotes still work alongside modern API
- Optional animation handling doesn't affect existing valid animations
- Type fixes don't change runtime behavior
- State snapshot logic is additive (checks match state first, falls back to original logic)

---

## Migration Notes (Future Work)

While not required for this PR, future improvements could include:
1. Migrate `LobbyManager` to use modern map voting API (`MapVoteStart/Update/End`)
2. Remove legacy remote definitions once all systems are migrated
3. Update test suites to reference correct remote names

---

## Related Documentation

- `/docs/REMOTE_AUDIT.md` - Complete audit of unexpected remotes
- `BOOT_FLOW.md` - Game boot flow documentation
- `START_FLOW.md` - Game start flow documentation

---

## Code Quality

- ✅ Minimal changes (surgical fixes only)
- ✅ Strict typing throughout
- ✅ Clear comments and documentation
- ✅ No behavioral changes to gameplay
- ✅ Backward compatible

---

## Checklist

- [x] Primary bug (TitleScreen state on MAP spawn) fixed
- [x] RemoteRegistry shows 0 unexpected remotes
- [x] ADS animation validation warnings removed
- [x] ClientMain RunContext documented properly
- [x] Strict typing issues resolved
- [x] Documentation created (`REMOTE_AUDIT.md`)
- [x] All changes committed and pushed

---

**Ready for Review** ✅
