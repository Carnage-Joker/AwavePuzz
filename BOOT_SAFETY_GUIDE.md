# Boot Safety & Entry Points Guide

## Overview

This document describes the boot safety system, entry points, and duplicate-run guards implemented in AwavePuzz to ensure clean, deterministic game initialization.

## Single Entry Points

### Server Entry Point

**File:** `ServerScriptService/MainServerScript.legacy.lua`

This is the **single server entry point** for the entire game. Despite the "legacy" naming (historical), this is the active boot script.

**Features:**
- **Duplicate execution guard** using script attribute
- **Deterministic 6-phase boot sequence**
- **Character auto-load control** (disabled until ready)
- **Service initialization** in correct dependency order
- **Heartbeat connection management** with reload protection

**Duplicate Guard:**
```lua
-- Guard against duplicate execution
if script:GetAttribute("Initialized") then
    warn("[MainServerScript] Already initialized, skipping duplicate execution")
    return
end
script:SetAttribute("Initialized", true)
```

**Boot Phases:**
1. **Phase 0:** Character auto-load control
2. **Phase 1:** Initialize RemoteRegistry (creates all remotes)
3. **Phase 2:** Load shared configuration and validate assets
4. **Phase 3:** Initialize services (GameManager, AllianceService, etc.)
5. **Phase 4:** Set up player connection handlers
6. **Phase 5:** Start main game loop (Heartbeat)
7. **Phase 6:** Auto-start logic

### Client Entry Points

**Primary Entry:** `StarterPlayer/StarterPlayerScripts/BootClient.lua` (LocalScript)

**Features:**
- **Ultra-simple guard** using global variable
- **Delegates all logic** to BootModule.lua (ModuleScript pattern)
- **Eliminates RunContext duplication** issues

**Duplicate Guard:**
```lua
if _G.__AwavePuzzBootClientStarted then
    warn("[BOOT][CLIENT] CRITICAL: Duplicate BootClient.lua execution detected!")
    return
end
_G.__AwavePuzzBootClientStarted = true
```

**Delegation Chain:**
```
BootClient.lua (LocalScript)
    ↓ delegates to
BootModule.lua (ModuleScript)
    ↓ delegates to
ClientMainModule.lua (ModuleScript)
```

**Boot Module:** `StarterPlayer/StarterPlayerScripts/BootModule.lua`

**Features:**
- **Immediate camera control** (scriptable, black screen)
- **Title screen display** before any gameplay
- **Loading manager initialization** with progress tracking
- **Deterministic boot order**

**Client Main:** `StarterPlayer/StarterPlayerScripts/ClientMainModule.lua`

**Features:**
- **Duplicate guard** using script attribute
- **Connection tracking** for cleanup (BUG-007 fix)
- **Phase-based initialization** (RemoteRegistry → Config → Modules → UI)
- **Loading progress updates** via LoadingManager

## RemoteRegistry System

### Purpose

Single source of truth for all RemoteEvents and RemoteFunctions in the game. Eliminates duplicate remote creation and ensures deterministic initialization.

**File:** `ReplicatedStorage/Shared/Remotes/RemoteRegistry.lua`

### Features

- **132 defined remotes** (complete registry)
- **Server creates** remotes on boot
- **Client waits** for remotes with timeout
- **Handles duplicates** automatically
- **Type validation** (Event vs Function)
- **Deterministic logging** with version number

### Usage Pattern

**Server:**
```lua
local RemoteRegistry = require(ReplicatedStorage.Shared.Remotes.RemoteRegistry)
local remotes = RemoteRegistry.initializeServer()
-- remotes is a table: { RemoteName = RemoteEvent/RemoteFunction }
```

**Client:**
```lua
local RemoteRegistry = require(ReplicatedStorage.Shared.Remotes.RemoteRegistry)
local remotes = RemoteRegistry.initializeClient(10) -- 10 second timeout
if not remotes then
    error("Failed to initialize remotes")
end
```

### Deprecated System

`ServerScriptService/RemoteEventsBootstrap.lua` is **fully deprecated** and kept only for backward compatibility. All new code should use RemoteRegistry.

## Boot Validation & Testing

### Boot Smoke Tests

**File:** `tests/boot_smoke_tests.lua`

Comprehensive test suite that validates:
1. **Entry point guards** (server and client)
2. **RemoteRegistry initialization**
3. **RemoteEvents folder creation**
4. **Core configuration modules** loading
5. **Service initialization** (server only)
6. **Character auto-load control**
7. **Boot log determinism**
8. **No duplicate folders**
9. **Client-server synchronization**
10. **Module timeout values**

**Running Tests:**

In Roblox Studio Command Bar:
```lua
local tests = require(game.ReplicatedStorage.tests.boot_smoke_tests)
tests.runAll()
```

Or use the quick runner:
```lua
require(game.ReplicatedStorage.tests.run_boot_tests)
```

### Expected Output

```
============================================================
BOOT SMOKE TEST SUITE
Baseline + Safety Nets - Entry Points, Module Loading, Boot
============================================================

--- Entry Point Tests ---
✅ PASS: Server Entry Point Guard - Duplicate execution guard is active
ℹ️  INFO: Skipping client test (not running on server)

--- Module Loading Tests ---
✅ PASS: RemoteRegistry Initialization - RemoteRegistry loaded successfully (version 1.0.0)
✅ PASS: RemoteEvents Folder - RemoteEvents folder contains 132 remotes
✅ PASS: Core Configuration Modules - All 6 core modules present and loadable
✅ PASS: Service Initialization - All 9 services present and loadable

--- Boot Configuration Tests ---
✅ PASS: Character Auto-Load Control - CharacterAutoLoads correctly disabled
✅ PASS: Boot Log Format - RemoteRegistry has VERSION for deterministic logging
✅ PASS: Deprecated Module Detection - Deprecated module check complete
✅ PASS: No Duplicate RemoteEvents Folders - Exactly one RemoteEvents folder found

--- Synchronization Tests ---
ℹ️  INFO: Skipping client-server sync test (not running on server)
✅ PASS: Module Timeout Values - GameConfig loaded quickly (0.01s)

============================================================
BOOT SMOKE TEST RESULTS
============================================================
Tests Passed: 10
Tests Failed: 0
Total Tests: 10

✅ ALL TESTS PASSED - Boot system is healthy
============================================================
```

### Boot Validation Test

**File:** `ServerScriptService/BootValidationTest.lua`

Legacy test script that validates:
- Lobby creation idempotency
- Map pivot positioning
- CureStations dev gating
- Asset validation module
- ModalManager improvements
- InputActionRegistry conflict detection

**Note:** This is more focused on specific subsystem validation rather than boot process itself.

## Clean Boot Expectations

### Expected Behavior

When running "Server & Clients" in Roblox Studio:

1. **Server console shows:**
   - `=== [BOOT][SERVER] Aether Wave: Convergence Server Starting ===`
   - Phase-by-phase initialization messages
   - `[BOOT][SERVER] Phase N complete: ...` for each phase
   - `=== [BOOT][SERVER] Server Ready ===`
   - No red errors

2. **Client console shows:**
   - `=== [BOOT][CLIENT] Entry point - Delegating to BootModule ===`
   - `[BOOTMODULE] Phase 0: Taking immediate camera control...`
   - `[BOOTMODULE] Phase 0.5: Creating and showing TitleScreenUI...`
   - `[BOOT][CLIENT] Aether Wave: Convergence Client Starting ===`
   - Phase-by-phase initialization messages
   - No red errors

### Known Warnings (Safe)

These warnings are expected and safe:
- `[RemoteEventsBootstrap] Initializing (DEPRECATED - use RemoteRegistry)` - Backward compatibility
- Asset validation warnings if placeholder assets are used
- `⚠️ Boot-time validation found N invalid asset(s)` - Non-blocking

### Red Errors (Not Acceptable)

If you see any of these, the boot process has failed:
- `CRITICAL: Failed to load ...`
- Script errors or stack traces
- Infinite yields
- Module require failures

## Module Load Error Prevention

### Timeout Guidelines

**All WaitForChild() calls must have timeouts:**
- Shared folder: 10 seconds
- Config modules: 5 seconds
- RemoteRegistry: 5 seconds
- Client modules: 10 seconds

**Never use:**
```lua
local module = folder:WaitForChild("ModuleName") -- ❌ No timeout - can infinite yield
```

**Always use:**
```lua
local module = folder:WaitForChild("ModuleName", 5) -- ✅ With timeout
if not module then
    error("Failed to load module")
end
```

### Service Initialization Order

**Critical dependencies must initialize first:**

```
1. AllianceService (no dependencies)
2. GameManager (depends on AllianceService)
3. PlayerManager (extracted from GameManager)
4. Other services (depend on PlayerManager)
```

**In code:**
```lua
local allianceService = AllianceService.new()
local gameManager = GameManager.new(allianceService)
local playerManager = gameManager:getPlayerManager()
local cureService = CureService.new(gameManager, playerManager)
```

### Circular Dependency Prevention

**Verified clean:**
- Alliance modules → Only require config modules (no circular dependencies)
- AI modules → Only require config modules (no circular dependencies)
- PlayerSpawnManager → LobbySetup (one-way dependency, clean)

**How to avoid:**
- Services should accept dependencies via constructor
- Use late binding (setPuzzleService, setCureService) for mutual dependencies
- Never require() services from within service constructors

## Deterministic Boot Logs

### Log Format Standards

**All boot messages should follow this format:**

```lua
print("[BOOT][SERVER] Phase N: Description...")
print("[BOOT][CLIENT] Phase N: Description...")
print("[BOOT][SERVER] Phase N complete: Result")
```

**Service-specific logs:**
```lua
print("[ServiceName] Initialized")
print("[ServiceName] Phase N: Action")
```

**RemoteRegistry logs include version:**
```lua
print(string.format("%s [BOOT][SERVER] Initializing remote registry (version %s)", 
    LOG_PREFIX, RemoteRegistry.VERSION))
```

### Phase Numbering

Phases must be sequential and deterministic:
- **Phase 0:** Foundation setup (character control, camera, etc.)
- **Phase 1:** Critical dependencies (RemoteRegistry)
- **Phase 2:** Configuration loading
- **Phase 3:** Service initialization
- **Phase 4:** Connection handlers
- **Phase 5:** Main loop start
- **Phase 6+:** Optional post-boot logic

## Best Practices

### Entry Point Rules

1. **Never create multiple entry point scripts**
   - Server: Only MainServerScript.legacy.lua
   - Client: Only BootClient.lua

2. **Always use duplicate guards**
   - Server: Script attributes
   - Client: Global variables

3. **Delegate complex logic to ModuleScripts**
   - Prevents RunContext issues
   - Easier to test and maintain

### RemoteRegistry Rules

1. **Server always creates remotes**
   - Call `RemoteRegistry.initializeServer()` in Phase 1
   - Store returned remotes table for use

2. **Client always waits for remotes**
   - Call `RemoteRegistry.initializeClient(timeout)` with reasonable timeout
   - Handle failure case

3. **Never create remotes manually**
   - Add to RemoteRegistry REMOTE_DEFINITIONS instead
   - Let the system handle creation

### Module Loading Rules

1. **Always use timeouts on WaitForChild**
   - Minimum 5 seconds for local resources
   - 10 seconds for potentially slow resources

2. **Check for nil before requiring**
   ```lua
   local module = folder:WaitForChild("Module", 5)
   if not module then
       error("Failed to load module")
   end
   local loaded = require(module)
   ```

3. **Use pcall for non-critical requires**
   ```lua
   local success, result = pcall(function()
       return require(module)
   end)
   if not success then
       warn("Optional module failed to load:", result)
   end
   ```

## Troubleshooting

### "Infinite yield" warnings

**Symptom:** Script waits forever for a child that never appears

**Solution:**
1. Check that the child actually exists in the expected location
2. Verify the timeout is long enough (>= 5 seconds)
3. Add error handling for timeout case

### Duplicate execution detected

**Symptom:** Warning about duplicate execution from entry point guards

**Solution:**
1. Check for multiple copies of MainServerScript.legacy.lua
2. Check for multiple LocalScripts in StarterPlayerScripts
3. Verify guards are present and active

### RemoteEvents not found

**Symptom:** Client can't find RemoteEvents folder or specific remotes

**Solution:**
1. Verify server is running and initialized first
2. Check RemoteRegistry.initializeServer() was called
3. Increase client timeout if needed
4. Verify remote name is in REMOTE_DEFINITIONS

### Service initialization fails

**Symptom:** Error during service creation or initialization

**Solution:**
1. Check service initialization order (dependencies first)
2. Verify all required modules are present
3. Check for circular dependencies
4. Review service constructor parameters

## Testing Checklist

Before committing changes that affect boot:

- [ ] Run boot smoke tests (`boot_smoke_tests.lua`)
- [ ] Test "Server & Clients" mode in Studio
- [ ] Verify no red errors in output
- [ ] Verify entry point guards are active
- [ ] Verify all phases complete successfully
- [ ] Check for unexpected warnings
- [ ] Test with multiple clients joining
- [ ] Test server reload behavior

## Version History

- **v1.0.0** - Initial boot safety system
  - Single entry points established
  - Duplicate guards implemented
  - RemoteRegistry system complete
  - Boot smoke tests created
  - This documentation written

## Related Documentation

- `BOOT_FLOW.md` - Detailed boot sequence flow
- `API_DOCUMENTATION.md` - API reference for all systems
- `TESTING_GUIDE.md` - General testing procedures
- `tests/README.md` - Test suite documentation
