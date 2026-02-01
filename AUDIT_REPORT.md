# AwavePuzz Modern Luau Refactor - Audit Report

**Date**: 2026-02-01  
**Purpose**: Comprehensive audit for converting to modern Luau with clear client/server boundaries

---

## Executive Summary

The AwavePuzz codebase is **mostly well-structured** with proper client/server separation. Key findings:

✅ **Good**:
- Single client entry point (`ClientController.client.lua`)
- Single server entry point (`MainServer.lua`)
- No Scripts in StarterPlayerScripts (only LocalScripts and ModuleScripts)
- Clear folder organization

⚠️ **Needs Refactoring**:
- Uses `_G` for singleton guard in ClientController
- Legacy `wait()` and `spawn()` calls throughout (~68 files)
- RemoteEventsBootstrap has side effects on require
- No centralized remote registry (remotes created ad-hoc)
- Missing :WaitForChild timeouts in some critical paths

---

## 1. Executable Scripts Inventory

### Server Scripts

| File | Type | Context | Status |
|------|------|---------|--------|
| `ServerScriptService/MainServer.lua` | Script | Server | ✅ PRIMARY ENTRY POINT |
| `ServerScriptService/ClientReady.lua` | Script | Server | ✅ Secondary listener |
| All other ServerScriptService/*.lua | ModuleScript | Server | ✅ Properly structured |

**Total**: 2 server scripts (entry points) + 45+ service modules

### Client Scripts

| File | Type | Context | Status |
|------|------|---------|--------|
| `StarterPlayerScripts/ClientController.client.lua` | LocalScript | Client | ✅ PRIMARY ENTRY POINT |
| All files in `StarterPlayerScripts/Modules/` | ModuleScript | Client | ✅ Properly structured |
| All files in `StarterPlayerScripts/FPS/` | ModuleScript | Client | ✅ Properly structured |

**Total**: 1 client script (entry point) + 30+ client modules

### RunContext Verification

✅ **NO SCRIPTS WITH NON-LEGACY RUNCONTEXT IN STARTERPLAYERSCRIPTS**

The only LocalScript in StarterPlayerScripts is `ClientController.client.lua`, and its comments request `RunContext = Legacy` to avoid duplicate execution. All other files are ModuleScripts (not executable).

---

## 2. Incorrectly Placed Scripts

✅ **NONE FOUND**

All scripts are in correct locations:
- Server scripts in `ServerScriptService/`
- Client scripts in `StarterPlayerScripts/`
- Shared modules in `ReplicatedStorage/Shared/`

---

## 3. Legacy Pattern Usage

### _G Singleton Pattern

**Location**: `StarterPlayerScripts/ClientController.client.lua` (line 11)

```lua
if _G.AwavePuzzClientControllerInitialized then
    error("[ClientController] CRITICAL: ClientController.client.lua is running multiple times!")
end
_G.AwavePuzzClientControllerInitialized = true
```

**Issue**: Uses global namespace for singleton guard  
**Fix**: Replace with idempotent pattern using script attributes only

---

### wait() Usage (40+ occurrences)

**Files affected**:
- `ServerScriptService/MainServer.lua` (line 230)
- `ServerScriptService/GameManager.lua` (multiple)
- `ServerScriptService/PortalMatchmakingService.lua` (multiple)
- All `StarterPlayerScripts/Modules/UI/*.lua` files
- Various server services

**Fix**: Replace all `wait()` with `task.wait()`

---

### spawn() Usage (28+ occurrences)

**Files affected**:
- `StarterPlayerScripts/Modules/UI/PlayerHUD.lua`
- `StarterPlayerScripts/Modules/UI/MapVotingUI.lua`
- `StarterPlayerScripts/Modules/FPSMovement.lua`
- Multiple server services

**Fix**: Replace all `spawn()` with `task.spawn()`

---

## 4. Modules with Side Effects on Require

### Critical: RemoteEventsBootstrap.lua

**Location**: `ServerScriptService/RemoteEventsBootstrap.lua`

**Side Effects** (lines 129-153):
```lua
local folder = getOrCreateRemoteEventsFolder()
local created = 0
local existing = 0
-- ... creates RemoteEvents at module level ...
```

**Issue**: Executes immediately when required, creates instances, modifies ReplicatedStorage  
**Fix**: Wrap in `initialize()` method, call explicitly from MainServer

---

### Moderate: Service Modules

Most service modules load dependencies at top-level but don't execute game logic:
- `GameManager.lua` - Requires multiple services (acceptable)
- `AllianceServiceV2.lua` - Requires dependencies (acceptable)
- Various UI modules - Require shared config (acceptable)

**Status**: These are acceptable as long as they don't execute gameplay logic on require

---

## 5. Remote Event Management

### Current System

**Creation**:
- `RemoteEventsBootstrap.lua` - Creates animation remotes
- `RemoteEventUtil.lua` - Utility for creating remotes on-demand
- Individual services call `RemoteEventUtil.getOrCreateEvents()` as needed

**Issues**:
1. No single source of truth for all remotes
2. No versioning or validation
3. Remotes created ad-hoc by services
4. No type-safe wrappers

**Remotes Created**:

**By RemoteEventsBootstrap**:
- AnimationFire
- AnimationSprint
- AnimationADS
- AnimationFireReplicate
- AnimationSprintReplicate
- AnimationADSReplicate

**By GameManager** (via RemoteEventUtil):
- WaveAnnounce
- WaveUpdate
- GameStateUpdate
- CureUpdate
- BaseHealthUpdate
- MapUpdate
- ScoreboardUpdate
- ShowScoreboard / HideScoreboard
- ShowTitleScreen / HideTitleScreen
- TitleScreenContinue
- ShowEpilogue / HideEpilogue
- EpilogueComplete
- ShowCredits / HideCredits
- AchievementUnlocked
- BetrayalStarted

**By Other Services** (various):
- SpectatorCycleTarget (SpectatorManager)
- SprintRequest (SprintService)
- PortalQueueUpdate (PortalMatchmakingService)
- PuzzlePickup / PuzzleSubmit (PuzzleService)
- And many more...

**Recommendation**: Create unified `RemoteRegistry.lua` that:
1. Defines all remotes in one place
2. Creates them on server boot
3. Provides type-safe wrappers
4. Validates expected vs actual remotes

---

## 6. Entry Point Analysis

### Server Entry: MainServer.lua

**Current Flow**:
1. Require RemoteEventsBootstrap (side effects!)
2. Load shared configuration
3. Validate assets
4. Require and instantiate services
5. Connect player events
6. Start Heartbeat loop
7. Auto-start logic in task.spawn

**Issues**:
- RemoteEventsBootstrap runs code on require
- Multiple services are instantiated inline (could be cleaner)

**Status**: ✅ Single entry point exists, needs minor cleanup

---

### Client Entry: ClientController.client.lua

**Current Flow**:
1. Check _G singleton guard (legacy)
2. Check attribute guard (backup)
3. Load configuration
4. Initialize systems (camera, movement, weapon, etc.)
5. Initialize UI modules
6. Connect character lifecycle events

**Issues**:
- Uses _G for singleton guard
- Comments request RunContext = Legacy

**Status**: ✅ Single entry point exists, needs _G removal

---

## 7. Lobby and Start Flow Issues

### Current State (Fixed in Previous Updates)

Based on BOOT_FLOW.md and START_FLOW.md:

✅ **Working**:
- No map loads on server boot
- Players spawn in lobby with movement enabled
- Title screen → Lobby → Map flow is correct
- Portals are visible and functional

**Verification Needed**:
- Confirm ClientController doesn't produce RunContext warnings
- Confirm no duplicate boot sequences
- Confirm lobby visibility and movement

---

## 8. Folder Structure

### Current Structure

```
AwavePuzz/
├── ServerScriptService/          # Server code
│   ├── MainServer.lua           # Entry point
│   ├── AI/                      # AI systems
│   ├── Alliance/                # Alliance systems
│   └── *.lua                    # Services (45+ files)
├── ReplicatedStorage/
│   ├── Shared/                  # Shared config/utils (22 files)
│   └── RemoteEvents/            # Created at runtime
├── StarterPlayer/
│   └── StarterPlayerScripts/    # Client code
│       ├── ClientController.client.lua  # Entry point
│       ├── Modules/             # Client modules
│       │   ├── UI/              # UI controllers (25 files)
│       │   └── *.lua            # Controllers
│       └── FPS/                 # FPS camera system
└── StarterGui/                  # (Empty - UI created at runtime)
```

### Proposed Modern Structure

```
AwavePuzz/
├── ServerScriptService/
│   ├── Main.server.lua          # NEW: Single server entry
│   └── Server/                  # NEW: Organized structure
│       ├── Services/            # ShopService, AllianceService, etc.
│       └── Systems/             # Game loop, waves, spawning
├── ReplicatedStorage/
│   └── Shared/                  # Shared modules
│       ├── Config/              # All config modules
│       ├── Remotes/             # NEW: RemoteRegistry
│       ├── Net/                 # NEW: Remote wrappers
│       └── Util/                # Pure utility functions
├── StarterPlayer/
│   └── StarterPlayerScripts/
│       ├── ClientMain.client.lua  # NEW: Renamed entry
│       └── Client/              # NEW: Organized structure
│           ├── Controllers/     # Movement, camera, weapons, audio
│           └── UI/              # UI controllers
└── StarterGui/                  # (Still empty)
```

**Note**: Folder reorganization should be optional and done carefully to avoid breaking existing Studio workflows.

---

## 9. Required Fixes

### High Priority

1. **Remove _G guard from ClientController** - Replace with attribute-only pattern
2. **Refactor RemoteEventsBootstrap** - Wrap side effects in initialize() method
3. **Create RemoteRegistry** - Single source of truth for all remotes
4. **Replace wait() with task.wait()** - 40+ files
5. **Replace spawn() with task.spawn()** - 28 files

### Medium Priority

6. **Add :WaitForChild timeouts** - Critical paths need timeout parameters
7. **Add boot logging** - [BOOT][SERVER], [BOOT][CLIENT], [STATE] prefixes
8. **Create Main.server.lua** - Rename and refactor MainServer.lua
9. **Create ClientMain.client.lua** - Rename ClientController.client.lua

### Low Priority (Optional)

10. **Reorganize folders** - Move to proposed structure (breaking change)
11. **Add --!strict annotations** - Type checking for entry points
12. **Create Net/ wrappers** - Type-safe remote calls

---

## 10. Migration Strategy

### Phase 1: No Breaking Changes
1. Replace legacy patterns (wait/spawn) in all files
2. Remove _G guard from ClientController
3. Add idempotent checks to RemoteEventsBootstrap
4. Create RemoteRegistry alongside existing system
5. Add boot logging

### Phase 2: Minor Breaking Changes
6. Rename MainServer.lua → Main.server.lua
7. Rename ClientController.client.lua → ClientMain.client.lua
8. Update RemoteEventsBootstrap to use RemoteRegistry
9. Add timeouts to critical :WaitForChild calls

### Phase 3: Optional Reorganization
10. Move files to new folder structure (if desired)
11. Update all requires to new paths
12. Create Net/ wrappers for type-safe remotes

---

## 11. Acceptance Criteria

After refactoring, the following must be true:

✅ **No RunContext warnings in Studio**  
✅ **Client boot logs appear exactly once per player join**  
✅ **Title screen shows first (not epilogue or map gameplay)**  
✅ **Lobby loads with portals visible and player can move**  
✅ **Map loads only when lobby/matchmaking resolves**  
✅ **Hot reload doesn't duplicate remote connections or boot sequences**  
✅ **No usage of _G for singleton guards**  
✅ **All wait() replaced with task.wait()**  
✅ **All spawn() replaced with task.spawn()**  
✅ **Critical paths use :WaitForChild with timeouts**  

---

## 12. Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Breaking existing functionality | High | Test thoroughly after each change |
| Roblox Studio workflow disruption | Medium | Keep folder moves optional |
| Remote connections duplication | Medium | Test hot reload extensively |
| Type errors from strict mode | Low | Add --!strict incrementally |
| Performance regression | Low | Modern task library is faster |

---

## 13. Estimated Effort

- **Phase 1** (No breaking changes): ~4-6 hours
- **Phase 2** (Minor breaking changes): ~2-3 hours
- **Phase 3** (Optional reorganization): ~3-4 hours
- **Testing**: ~2-3 hours per phase

**Total**: 11-16 hours for complete refactor

---

## Conclusion

The AwavePuzz codebase is in **good shape** for modernization. The main issues are:
1. Legacy patterns (wait/spawn/\_G)
2. RemoteEventsBootstrap side effects
3. Missing centralized remote registry

These can be fixed with **minimal breaking changes** following the phased approach outlined above.

**Recommended Approach**: Start with Phase 1 (non-breaking changes), test thoroughly, then proceed to Phase 2 if needed. Phase 3 (folder reorganization) is optional and should only be done if there's a strong need for restructuring.
