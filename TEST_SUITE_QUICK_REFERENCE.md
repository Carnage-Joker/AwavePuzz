# Test Suite Quick Reference

Quick commands for running the AwavePuzz comprehensive test suite.

## Run All Tests

```lua
-- Maximum verbosity (DEBUG) - Shows everything
require(game.ServerStorage.DevOnly.TestRunner).debug()

-- Normal verbosity (INFO) - Standard output
require(game.ServerStorage.DevOnly.TestRunner).test()

-- Minimal verbosity (WARN) - Only warnings and errors
require(game.ServerStorage.DevOnly.TestRunner).quiet()
```

## Run Specific Test Suite

```lua
local TestRunner = require(game.ServerStorage.DevOnly.TestRunner)

-- Run individual suites
TestRunner.testSuite("CoreSystemsTests")
TestRunner.testSuite("SpawningSystemTests")
TestRunner.testSuite("WeaponSystemTests")
TestRunner.testSuite("CureAndPuzzleTests")
TestRunner.testSuite("AllianceSystemTests")
TestRunner.testSuite("ConfigurationTests")
TestRunner.testSuite("IntegrationTests")
```

## Test Suites Available

| Suite Name | What It Tests |
|------------|---------------|
| CoreSystemsTests | GameManager, PlayerManager, BaseManager, core modules |
| SpawningSystemTests | Zombie spawning, AI, ResourceSpawner, spawn points |
| WeaponSystemTests | Weapons, FPS system, damage, ammo |
| CureAndPuzzleTests | Cure progression, puzzle generation, synthesis |
| AllianceSystemTests | Alliances, betrayal, shared resources |
| ShopSystemTests | Shop purchases, currency management |
| MapSystemTests | Map loading, validation, spawn points |
| LobbySystemTests | Lobby, matchmaking, player flow |
| UISystemTests | Input handling, modals, UI managers |
| MovementSystemTests | Sprint, stamina, movement |
| SpectatorSystemTests | Spectator mode, death handling |
| ConfigurationTests | All config modules validation |
| IntegrationTests | Full system integration, initialization |

## Interpreting Results

### Success
```
✓ Test PASSED: TestName
═══════════════════════════════════════════════════════════
✓ Overall Status: ALL TESTS PASSED
═══════════════════════════════════════════════════════════
```

### Failure
```
✗ Test FAILED: TestName
Error: Assertion failed: Expected X, got Y

Failed Tests:
  1. SuiteName.TestName
     Error: Detailed error message
     Duration: 0.XXX seconds
```

### Warning
```
⚠ WARNING: Module not found (may be optional)
```

## Log Levels

- **[DEBUG]** - Very detailed, every assertion and step
- **[INFO]** - Test progress and results
- **[WARN]** - Non-critical issues, optional features
- **[ERROR]** - Test failures and critical issues

## Common Test Patterns

### Check if Module Loads
```lua
suite.tests["Module_LoadsSuccessfully"] = function()
    TestFramework:info("Testing module loading...")
    local success, Module = pcall(function()
        return require(path.to.Module)
    end)
    TestFramework:assertTrue(success, "Module should load without errors")
    TestFramework:assertNotNil(Module, "Module should not be nil")
end
```

### Validate Configuration
```lua
suite.tests["Config_HasRequiredField"] = function()
    TestFramework:info("Testing configuration field...")
    TestFramework:assertNotNil(Config.FIELD_NAME, "Field should exist")
    TestFramework:assertType(Config.FIELD_NAME, "number", "Field should be number")
    TestFramework:assertGreaterThan(Config.FIELD_NAME, 0, "Field should be positive")
end
```

### Test Method Exists
```lua
suite.tests["Service_HasMethod"] = function()
    TestFramework:info("Testing method existence...")
    local Service = require(path.to.Service)
    TestFramework:assertNotNil(Service.methodName, "Method should exist")
    TestFramework:assertType(Service.methodName, "function", "Should be function")
end
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Module not found" | Check module is in correct location and not disabled |
| Tests hang | Look for WaitForChild without timeout in code |
| Many tests skipped | Normal for optional features not yet implemented |
| RemoteEvents not found | Many are created at runtime, warnings are normal |

## When to Run Tests

- ✅ Before committing code changes
- ✅ After refactoring any system
- ✅ Before deploying to production
- ✅ After fixing bugs (regression testing)
- ✅ Weekly as routine health check
- ✅ After merging branches

## Need Help?

See full documentation: **TEST_SUITE_GUIDE.md**

## Test Statistics

- **Total Test Suites:** 13
- **Total Tests:** 100+
- **Total Assertions:** 300+
- **Code Coverage:** All major game systems
- **Execution Time:** ~10-15 seconds (full suite)
