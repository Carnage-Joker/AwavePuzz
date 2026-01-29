# AwavePuzz Comprehensive Test Suite Guide

**Version:** 1.0  
**Date:** 2026-01-29  
**Purpose:** Comprehensive testing with verbose logging to pinpoint bugs and errors

---

## Table of Contents

1. [Overview](#overview)
2. [Test Framework Architecture](#test-framework-architecture)
3. [Running Tests](#running-tests)
4. [Test Suites](#test-suites)
5. [Interpreting Results](#interpreting-results)
6. [Troubleshooting](#troubleshooting)
7. [Extending Tests](#extending-tests)

---

## Overview

The AwavePuzz Comprehensive Test Suite is a complete testing framework designed to:
- **Detect bugs early** with extensive validation across all game systems
- **Provide verbose logging** at multiple log levels for debugging
- **Test system integration** to ensure components work together correctly
- **Validate configurations** to catch setup errors before deployment
- **Track test metrics** including pass/fail rates and execution times

### Key Features

- ✅ **13 comprehensive test suites** covering all major systems
- ✅ **100+ individual tests** with detailed assertions
- ✅ **Verbose logging** with DEBUG, INFO, WARN, and ERROR levels
- ✅ **Modular architecture** for easy maintenance and extension
- ✅ **Detailed reporting** with statistics and failure analysis
- ✅ **Zero production impact** - runs only in Roblox Studio

---

## Test Framework Architecture

### Components

#### 1. TestFramework.lua
The core testing engine providing:
- **Assertion functions** - `assert`, `assertEqual`, `assertNotNil`, etc.
- **Logging system** - Multi-level logging with timestamps
- **Test execution** - Suite and test runner with lifecycle hooks
- **Result tracking** - Comprehensive statistics and reporting
- **Mock utilities** - Simple mocking for isolated testing

#### 2. TestRunner.lua
The main test orchestrator that:
- Loads all test suites dynamically
- Executes tests in sequence
- Generates final reports
- Provides convenience methods for different verbosity levels

#### 3. Test Suites
Individual test modules for each system:

| Suite | Purpose | Test Count |
|-------|---------|------------|
| CoreSystemsTests | GameManager, PlayerManager, BaseManager | 15+ |
| SpawningSystemTests | Spawner, ZombieBrain, AI systems | 14+ |
| WeaponSystemTests | Weapons, FPS, damage dealing | 12+ |
| CureAndPuzzleTests | Cure progress, puzzle generation | 12+ |
| AllianceSystemTests | Alliances, betrayal, resource pools | 10+ |
| ShopSystemTests | Shop service, purchases | 3+ |
| MapSystemTests | Map loading, validation | 3+ |
| LobbySystemTests | Lobby, matchmaking | 3+ |
| UISystemTests | UI managers, input handling | 3+ |
| MovementSystemTests | Sprint, movement validation | 2+ |
| SpectatorSystemTests | Spectator mode, death handling | 2+ |
| ConfigurationTests | All config modules | 10+ |
| IntegrationTests | Full system integration | 12+ |

---

## Running Tests

### Prerequisites

1. **Roblox Studio** must be running
2. Tests are located in `ServerStorage/DevOnly/`
3. Game must have all required modules in place

### Quick Start

Open the Roblox Studio Command Bar and run:

```lua
-- Run all tests with maximum verbosity (DEBUG level)
require(game.ServerStorage.DevOnly.TestRunner).debug()

-- Run all tests with normal verbosity (INFO level)
require(game.ServerStorage.DevOnly.TestRunner).test()

-- Run all tests with minimal output (WARN level only)
require(game.ServerStorage.DevOnly.TestRunner).quiet()

-- Run a specific test suite
require(game.ServerStorage.DevOnly.TestRunner).testSuite("CoreSystemsTests")
```

### Advanced Usage

```lua
-- Get reference to TestRunner
local TestRunner = require(game.ServerStorage.DevOnly.TestRunner)
local TestFramework = require(game.ServerStorage.DevOnly.TestFramework)

-- Run all tests with custom log level
TestRunner.runAll(TestFramework.LogLevel.DEBUG)

-- Run specific suite with custom log level
TestRunner.runSuite("WeaponSystemTests", TestFramework.LogLevel.INFO)
```

---

## Test Suites

### 1. CoreSystemsTests

**Purpose:** Validate core game systems and singleton managers

**Key Tests:**
- GameConfig loading and validation
- PlayerManager singleton pattern
- BaseManager health management
- GameManager state definitions
- RemoteEvents structure
- Module dependencies

**When to Run:** 
- After modifying any core system
- Before deploying changes
- As part of routine testing

### 2. SpawningSystemTests

**Purpose:** Test zombie and resource spawning systems

**Key Tests:**
- ZombieTypes configuration validation
- Spawner module initialization
- ResourceSpawner functionality
- ZombieBrain AI system
- Spawn point structure
- Spawn rate configuration

**When to Run:**
- After modifying AI behavior
- When adjusting spawn rates
- After map changes

### 3. WeaponSystemTests

**Purpose:** Validate weapon systems and damage mechanics

**Key Tests:**
- WeaponConfig validation
- WeaponService initialization
- FPSWeaponService functionality
- FPSAnimationService
- Weapon stats validation
- Raycast parameters

**When to Run:**
- After weapon balancing changes
- When adding new weapons
- After damage calculation modifications

### 4. CureAndPuzzleTests

**Purpose:** Test cure progression and puzzle systems

**Key Tests:**
- PuzzleConfig validation
- CureService functionality
- PuzzleService puzzle generation
- CureSynthesisService
- Cure component tracking
- Puzzle generation algorithms

**When to Run:**
- After modifying cure mechanics
- When adding new puzzle types
- After progression changes

### 5. AllianceSystemTests

**Purpose:** Validate alliance mechanics and resource sharing

**Key Tests:**
- AllianceService initialization
- AllianceGraph data structure
- BetrayalService functionality
- InventoryLedger operations
- PoolCalculator accuracy
- Alliance RemoteEvents

**When to Run:**
- After modifying alliance mechanics
- When testing multiplayer scenarios
- After betrayal system changes

### 6-11. Additional System Tests

**ShopSystemTests:** Shop purchases and currency  
**MapSystemTests:** Map loading and validation  
**LobbySystemTests:** Lobby and matchmaking  
**UISystemTests:** UI managers and input  
**MovementSystemTests:** Sprint and movement  
**SpectatorSystemTests:** Spectator mode

### 12. ConfigurationTests

**Purpose:** Validate all configuration modules

**Key Tests:**
- GameConfig completeness
- WaveConfig wave definitions
- MapConfig map data
- FPSConfig settings
- AssetValidation system
- ModalManager functionality

**When to Run:**
- After any configuration change
- Before deployment
- As part of CI/CD pipeline

### 13. IntegrationTests

**Purpose:** Test full system integration and game flow

**Key Tests:**
- MainServer initialization
- RemoteEvents bootstrap
- Shared module accessibility
- Manager creation and references
- Service lifecycle
- RemoteEvent communication
- Workspace structure
- Error handling
- Memory management
- Performance metrics

**When to Run:**
- After major changes to multiple systems
- Before release
- During integration testing phase

---

## Interpreting Results

### Test Output Format

```
[HH:MM:SS] [LEVEL] Message
```

### Log Levels

- **[DEBUG]** - Detailed information for debugging (most verbose)
- **[INFO]** - General information about test progress
- **[WARN]** - Warning messages for non-critical issues
- **[ERROR]** - Error messages for test failures

### Example Output

```
[14:23:45] [INFO] ═══════════════════════════════════════════════════════════
[14:23:45] [INFO] Creating test suite: CoreSystemsTests
[14:23:45] [INFO] ═══════════════════════════════════════════════════════════
[14:23:45] [INFO] 
[14:23:45] [INFO] ─────────────────────────────────────────────────────────
[14:23:45] [INFO] Running test: CoreSystemsTests.GameConfig_LoadsSuccessfully
[14:23:45] [INFO] ─────────────────────────────────────────────────────────
[14:23:45] [INFO] Testing GameConfig module loading...
[14:23:45] [DEBUG] ✓ Assertion passed: GameConfig should load
[14:23:45] [DEBUG] GameConfig loaded successfully
[14:23:45] [INFO] ✓ Test PASSED: GameConfig_LoadsSuccessfully
[14:23:45] [INFO] Test duration: 0.003 seconds
```

### Summary Report

After all tests complete, you'll see:

```
╔═══════════════════════════════════════════════════════════╗
║                     TEST SUMMARY REPORT                   ║
╚═══════════════════════════════════════════════════════════╝

Test Execution Statistics:
  Total Tests Run:    95
  Tests Passed:       92 (96.8%)
  Tests Failed:       3 (3.2%)
  Tests Skipped:      0
  Tests with Errors:  0

Assertion Statistics:
  Total Assertions:   347
  Passed Assertions:  342 (98.6%)
  Failed Assertions:  5 (1.4%)

Execution Time:
  Total Duration:     12.456 seconds
  Average per Test:   0.131 seconds

Failed Tests:
  1. WeaponSystemTests.WeaponConfig_HeadshotMultiplier
     Error: Expected HEADSHOT_MULTIPLIER to exist
     Duration: 0.002 seconds

═══════════════════════════════════════════════════════════
✓ Overall Status: ALL TESTS PASSED
═══════════════════════════════════════════════════════════
```

### Understanding Failures

1. **Read the error message** - Tells you what assertion failed
2. **Check the test name** - Identifies which system has the issue
3. **Look at the duration** - Fast failures usually indicate missing modules
4. **Review the logs** - Check DEBUG logs for detailed context
5. **Fix the issue** - Update code or configuration as needed
6. **Re-run tests** - Verify the fix resolves the issue

---

## Troubleshooting

### Common Issues

#### Issue: "Module not found"
**Cause:** Test suite trying to load a module that doesn't exist  
**Solution:** 
- Check if the module is properly placed in ServerScriptService or ReplicatedStorage
- Verify module name matches exactly (case-sensitive)
- Ensure module is not accidentally disabled

#### Issue: "Tests hang/timeout"
**Cause:** WaitForChild calls without timeout  
**Solution:**
- All WaitForChild calls in test code have 5-10 second timeouts
- If production code hangs, check for missing timeouts there

#### Issue: "Many tests skipped"
**Cause:** Optional modules not found  
**Solution:**
- This is normal for optional features not yet implemented
- Warnings will indicate which modules are missing
- No action needed unless feature should exist

#### Issue: "RemoteEvents not found"
**Cause:** RemoteEvents created at runtime  
**Solution:**
- Many RemoteEvents are created dynamically
- Tests check for folder structure first
- Run tests after game initialization for complete validation

### Debugging Failed Tests

1. **Run specific suite in DEBUG mode:**
   ```lua
   require(game.ServerStorage.DevOnly.TestRunner).testSuite("CoreSystemsTests")
   ```

2. **Add temporary debug logging:**
   ```lua
   -- In your test
   TestFramework:debug("Variable value: %s", tostring(myVariable))
   ```

3. **Check prerequisite tests:**
   - If a test fails, check earlier tests in the same suite
   - Failures cascade - fix earliest failures first

4. **Verify game state:**
   - Some tests assume certain game state
   - Try running tests at different points (lobby, game, etc.)

---

## Extending Tests

### Adding a New Test to Existing Suite

1. Open the appropriate test suite file (e.g., `CoreSystemsTests.lua`)
2. Add a new test function:

```lua
suite.tests["YourNewTest_Name"] = function()
    TestFramework:info("Testing your feature...")
    
    -- Your test code here
    local result = yourFunction()
    
    TestFramework:assertNotNil(result, "Result should not be nil")
    TestFramework:assertEqual(result.value, 42, "Should return 42")
    
    TestFramework:debug("Test completed successfully")
end
```

3. Run the test suite to verify

### Creating a New Test Suite

1. Create a new file in `ServerStorage/DevOnly/` (e.g., `MySystemTests.lua`)

2. Use this template:

```lua
-- MySystemTests.lua
-- Tests for my custom system

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TestFramework = require(script.Parent.TestFramework)

local suite = TestFramework:createSuite("MySystemTests")

--------------------------------------------------------------------------------
-- Your Test Category
--------------------------------------------------------------------------------

suite.tests["MyFirstTest"] = function()
    TestFramework:info("Testing my feature...")
    
    -- Test implementation
    TestFramework:assertTrue(true, "This test should pass")
    
    TestFramework:debug("Test completed")
end

suite.tests["MySecondTest"] = function()
    TestFramework:info("Testing another feature...")
    
    -- Test implementation
    
    TestFramework:debug("Test completed")
end

return suite
```

3. Update `TestRunner.lua` to include your new suite:

```lua
-- In TestRunner.loadTestSuites(), add your suite name:
local testFiles = {
    "CoreSystemsTests",
    "SpawningSystemTests",
    -- ... other suites ...
    "MySystemTests",  -- Add your suite here
}
```

### Best Practices for Writing Tests

1. **Test one thing at a time** - Each test should validate a single concept
2. **Use descriptive names** - `Module_MethodName_ExpectedBehavior`
3. **Add debug logging** - Help future developers understand test intent
4. **Handle optional features** - Use warnings for features that may not exist
5. **Clean up after tests** - Destroy created instances, reset state
6. **Test both success and failure** - Don't just test happy paths
7. **Use appropriate assertions** - Choose the most specific assertion available

### Available Assertion Methods

- `assert(condition, message)` - Basic assertion
- `assertEqual(actual, expected, message)` - Value equality
- `assertNotEqual(actual, expected, message)` - Value inequality
- `assertNil(value, message)` - Value is nil
- `assertNotNil(value, message)` - Value is not nil
- `assertTrue(value, message)` - Value is exactly true
- `assertFalse(value, message)` - Value is exactly false
- `assertType(value, expectedType, message)` - Type checking
- `assertInstanceOf(value, className, message)` - Instance type checking
- `assertGreaterThan(actual, threshold, message)` - Numeric comparison
- `assertLessThan(actual, threshold, message)` - Numeric comparison
- `assertTableContains(table, value, message)` - Table membership
- `assertArrayLength(array, expectedLength, message)` - Array size

---

## Maintenance

### When to Run Tests

- **Before committing code** - Catch bugs early
- **After refactoring** - Ensure no regressions
- **Before deployment** - Final validation
- **After bug fixes** - Verify fix and prevent regression
- **Weekly** - Routine health check

### Updating Tests

When you modify game code:

1. **Check affected tests** - Identify tests that cover modified code
2. **Update test expectations** - If behavior intentionally changed
3. **Add new tests** - For new features or bug fixes
4. **Run full suite** - Ensure no unexpected side effects

### Performance Monitoring

The test suite tracks:
- Total execution time
- Per-test execution time
- Module load times
- Assertion counts

Monitor these metrics over time to catch performance regressions.

---

## Contributing

To contribute new tests:

1. Follow the existing structure and naming conventions
2. Add comprehensive logging for debugging
3. Test your tests (meta-testing!) - ensure they pass and fail correctly
4. Document any special requirements or setup
5. Update this guide if adding significant new functionality

---

## Support

For issues with the test suite:
1. Check this guide's troubleshooting section
2. Review test output logs carefully
3. Run tests in DEBUG mode for maximum detail
4. Check that all required modules are in place

---

## Version History

**1.0** (2026-01-29)
- Initial comprehensive test suite
- 13 test suites covering all major systems
- 100+ individual tests
- Verbose logging system
- Complete documentation

---

## Conclusion

This comprehensive test suite provides extensive coverage of the AwavePuzz game systems with verbose logging to help identify bugs and errors quickly. By running these tests regularly and interpreting the results carefully, you can maintain high code quality and catch issues before they impact players.

**Remember:** Tests are only as good as the assertions they make. Keep tests updated as the game evolves, and add new tests for new features and bug fixes.

Happy testing! 🎮✅
