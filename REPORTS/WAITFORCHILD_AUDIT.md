# WaitForChild Timeout Audit Report

**Generated:** 2026-01-24  
**Total WaitForChild Calls:** 579  
**Calls Without Timeout:** 449  
**Calls With Timeout:** 130  

## Status Summary

This audit identifies all `WaitForChild()` calls in the codebase and tracks which have been fixed with timeout parameters.

### Critical Files (Server Startup) - ✅ FIXED

These files block server initialization if dependencies are missing:

| File | Line | Call | Status | Timeout | Error Handling |
|------|------|------|--------|---------|----------------|
| MainServer.lua | 13 | `ReplicatedStorage:WaitForChild("Shared")` | ✅ Fixed | 10s | error() |
| MainServer.lua | 18 | `SharedFolder:WaitForChild("GameConfig")` | ✅ Fixed | 5s | error() |
| FPSWeaponService.lua | n/a | Multiple SharedFolder children | ✅ Fixed | 10s/5s | error() |
| SprintService.lua | 11-14 | Multiple SharedFolder children | ✅ Fixed | 10s/5s | error() |
| ShopService.lua | 7-9 | Multiple SharedFolder children | ✅ Fixed | 10s/5s | error() |
| WeaponService.lua | 15-18 | Multiple SharedFolder children | ✅ Fixed | 10s/5s | error() |
| CureService.lua | 21-23 | Multiple SharedFolder children | ✅ Fixed | 10s/5s | error() |
| PuzzleService.lua | 9-12 | Multiple SharedFolder children | ✅ Fixed | 10s/5s | error() |
| CureSynthesisService.lua | 11-14 | Multiple SharedFolder children | ✅ Fixed | 10s/5s | error() |
| AllianceServiceV2.lua | 14-16 | Multiple SharedFolder children | ✅ Fixed | 10s/5s | error() |
| PlayerManager.lua | 6-9 | Multiple SharedFolder children | ✅ Fixed | 10s/5s | error() |
| SpectatorManager.lua | 15-17 | Multiple SharedFolder children | ✅ Fixed | 10s/5s | error() |
| LobbyManager.lua | 15-17 | Multiple SharedFolder children | ✅ Fixed | 10s/5s | error() |
| FunFactService.lua | 9-11 | Multiple SharedFolder children | ✅ Fixed | 10s/5s | error() |
| AchievementService.lua | 8-10 | Multiple SharedFolder children | ✅ Fixed | 10s/5s | error() |
| FPSAnimationService.lua | 9-10 | Multiple SharedFolder children | ✅ Fixed | 10s/5s | error() |

### Alliance Services - ✅ FIXED

| File | Line | Call | Status | Timeout | Error Handling |
|------|------|------|--------|---------|----------------|
| BetrayalService.lua | 11-14 | Multiple SharedFolder children | ✅ Fixed | 10s/5s | error() |
| PoolCalculator.lua | 9-10 | Multiple SharedFolder children | ✅ Fixed | 10s/5s | error() |

### Client Controllers - ✅ FIXED

| File | Line | Call | Status | Timeout | Error Handling |
|------|------|------|--------|---------|----------------|
| ClientController.client.lua | 16 | `ReplicatedStorage:WaitForChild("Shared")` | ✅ Fixed | 10s | error() |
| ClientController.client.lua | 22-27 | Multiple SharedFolder children | ✅ Fixed | 5s | error() |

### Map and Spawn Systems - ✅ MOSTLY FIXED

| File | Line | Call | Status | Timeout | Notes |
|------|------|------|--------|-------|
| MapManager.lua | 12, 17-20 | Multiple WaitForChild | ✅ Fixed | 10s/5s | Already had timeouts |
| ResourceSpawner.lua | 12, 17 | SharedFolder and GameConfig | ✅ Fixed | 10s/5s | Already had timeouts |
| ItemSpawner.lua | 12, 17 | SharedFolder and GameConfig | ✅ Fixed | 10s/5s | Already had timeouts |
| GameManager.lua | 13, 18-20 | Multiple WaitForChild | ✅ Fixed | 10s/5s | Already had timeouts |

### Client-Side Modules - ⚠️ NEEDS ATTENTION

Many client-side modules still lack timeouts. These are lower priority since clients can reload, but should still be fixed:

| File | Approx Lines Without Timeout | Priority |
|------|------------------------------|----------|
| FPSWeaponController.lua | ~20 | Medium |
| FPSMovement.lua | ~15 | Medium |
| MusicController.lua | ~5 | Low |
| FirstPersonCamera.lua | ~3 | Low |
| FPSAudioController.lua | ~10 | Low |
| FPSHitmarkerController.lua | ~5 | Low |
| CureProgressUI.lua | ~8 | Low |
| Various UI controllers | ~50+ | Low |

### ReplicatedStorage Shared Modules - ⚠️ MEDIUM PRIORITY

These modules are loaded by both server and client:

| File | Lines | Status | Notes |
|------|-------|--------|-------|
| RemoteEventUtil.lua | Multiple | ⚠️ Pending | Needs timeout audit |
| Various Shared modules | ~100+ | ⚠️ Pending | Lower priority (mostly config) |

## Recommendations

### Immediate Actions (Critical)
1. ✅ **DONE:** All server startup files have timeouts and error handling
2. ✅ **DONE:** All manager services have proper error handling
3. ✅ **DONE:** RemoteEventsBootstrap now runs deterministically

### Short-term Actions (High Priority)
1. ⚠️ Add timeouts to client-side FPS modules (FPSWeaponController, FPSMovement)
2. ⚠️ Add timeouts to UI controller modules
3. ⚠️ Audit RemoteEventUtil for critical dependencies

### Long-term Actions (Medium Priority)
1. Add timeouts to all remaining client modules
2. Add timeout constants to GameConfig for consistency
3. Create helper function for consistent timeout + error handling pattern

## Pattern to Follow

```lua
-- Server-side (CRITICAL - must error on failure)
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
    error("[ServiceName] CRITICAL: Failed to load Shared folder after 10 seconds")
end

local ConfigModule = SharedFolder:WaitForChild("ConfigName", 5)
if not ConfigModule then
    error("[ServiceName] CRITICAL: Failed to load ConfigName after 5 seconds")
end
ConfigModule = require(ConfigModule)
```

```lua
-- Client-side (Warn but don't crash)
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
    warn("[ClientModule] Failed to load Shared folder after 10 seconds")
    return
end
```

## Statistics

- **Server Files Fixed:** 20/20 (100%)
- **Client Files Fixed:** 1/15 (~7%)
- **Overall Progress:** ~25% of critical paths secured
- **Remaining Work:** ~449 calls need timeout parameters

## Verification Steps

To verify no infinite yields occur:

1. Start server in Roblox Studio
2. Remove `ReplicatedStorage.Shared` folder
3. Observe server errors after 10 seconds (should not hang)
4. Restore folder and restart
5. Server should initialize normally

For client verification:
1. Join game as player
2. Remove SharedFolder during gameplay
3. Client should warn and degrade gracefully
4. No infinite client hangs should occur

---

**Last Updated:** 2026-01-24  
**Next Review:** After client module fixes
