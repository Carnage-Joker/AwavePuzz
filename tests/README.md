# AwavePuzz Test Suite

This directory contains testing infrastructure for AwavePuzz, including security tests, boot validation, and system integration tests.

## Test Categories

### Boot & Safety Tests
- **`boot_smoke_tests.lua`** - Boot system validation (12 tests)
- **`run_boot_tests.lua`** - Quick boot test runner for Roblox Studio

### Security Tests - Phase 1
- **`security_validation_tests.lua`** - Automated configuration checks (11 tests)
- **`run_security_tests.lua`** - Quick security test runner for Roblox Studio

### System Integration Tests
- **`title_screen_first_load_validator.lua`** - Title screen boot sequence validation
- **`wave_manager_spawn_test.lua`** - Wave manager spawn validation
- **`weapon_origin_reconstruction_test.lua`** - Weapon origin validation
- **`ui_duplicate_detection.lua`** - UI duplicate prevention tests
- **`input_action_registration_test.lua`** - Input action conflict detection

### Memory Leak Tests
- **`connection_leak_test.lua`** - Connection cleanup validation
- **`fps_weapon_heartbeat_leak_test.lua`** - FPS weapon heartbeat leak detection
- **`fps_weapon_validation_loop_leak_test.lua`** - FPS weapon validation loop leak detection
- **`heartbeat_leak_test.server.lua`** - Main heartbeat connection leak detection
- **`death_tracking_table_leak_test.lua`** - Death tracking cleanup validation
- **`epilogue_ui_cleanup_test.lua`** - Epilogue UI cleanup validation

### Race Condition & State Tests
- **`weapon_state_race_condition_test.lua`** - Weapon state consistency validation
- **`portal_queue_corruption_test.lua`** - Portal queue integrity validation
- **`kill_tracking_respawn_test.lua`** - Kill tracking respawn validation
- **`ammo_consumption_ordering_test.lua`** - Ammo consumption order validation
- **`base_damage_throttle_test.lua`** - Base damage throttle validation

### Test Documentation
- **`SECURITY_TEST_RESULTS.md`** - Security test results and analysis
- **`SECURITY_TESTING_GUIDE.md`** - Manual security testing procedures
- **`README_*.md`** - Individual test documentation files

## Quick Start

### Running Boot Smoke Tests

Validates boot system health, entry points, and module loading.

1. In Roblox Studio, ensure tests are in `ReplicatedStorage/tests/`
2. Open Command Bar (View → Command Bar)
3. Run:
```lua
local BootTests = require(game.ReplicatedStorage.tests.boot_smoke_tests)
BootTests.runAll()
```

**Or use the quick runner:**
```lua
require(game.ReplicatedStorage.tests.run_boot_tests)
```

**Expected Output:**
```
============================================================
BOOT SMOKE TEST SUITE
Baseline + Safety Nets - Entry Points, Module Loading, Boot
============================================================

--- Entry Point Tests ---
✅ PASS: Server Entry Point Guard - Duplicate execution guard is active
✅ PASS: Client Entry Point Guard - Client boot guard is active

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
✅ PASS: Client-Server Ready Signal - TitleScreenUI initialized and stored in shared
✅ PASS: Module Timeout Values - GameConfig loaded quickly (0.01s)

============================================================
BOOT SMOKE TEST RESULTS
============================================================
Tests Passed: 12
Tests Failed: 0
Total Tests: 12

✅ ALL TESTS PASSED - Boot system is healthy
============================================================
```

### Running Security Tests

Validates security configuration for BUG-004 and BUG-009.

1. In Roblox Studio, copy `security_validation_tests.lua` to `ReplicatedStorage/tests/`
2. Open Command Bar (View → Command Bar)
3. Run:
```lua
local SecurityTests = require(game.ReplicatedStorage.tests.security_validation_tests)
SecurityTests.runAll()
```

**Or use the quick runner:**
```lua
require(game.ReplicatedStorage.tests.run_security_tests)
```

## Important Note

The automated test suite (`security_validation_tests.lua`) performs **configuration and presence checks**, not behavior-level exploit testing. These tests verify that:
- Security configuration exists and is reasonable
- Required server-side validation methods are present
- Critical security modules can be loaded

For actual exploit prevention behavior testing (e.g., testing that shots from >15 studs away are rejected), see `SECURITY_TESTING_GUIDE.md` for manual testing procedures in Roblox Studio.

## Test Coverage Summary

### Boot & Safety Tests (12 tests)
1. Server entry point duplicate guard
2. Client entry point duplicate guard
3. RemoteRegistry initialization
4. RemoteEvents folder creation
5. Core configuration modules loading
6. Service initialization (server only)
7. Character auto-load control
8. Boot log determinism
9. Deprecated module detection
10. No duplicate RemoteEvents folders
11. Client-server ready signal
12. Module timeout values

### Security Tests (11 tests)
#### BUG-004: Wallhack Protection (3 tests)
1. Origin distance validation configuration
2. Direction alignment validation configuration
3. NaN protection implementation

#### BUG-009: Client Authority (6 tests)
1. Server-side ammo consumption
2. Currency server authority
3. Damage server authority
4. Shop purchase validation
5. Alliance request validation
6. Puzzle answer validation

#### Security Configuration (2 tests)
1. Security config existence
2. Ammo sync interval configuration

## Test Results

**Date**: 2026-02-10  
**Total Tests**: 11  
**Passed**: 11  
**Failed**: 0  
**Status**: ✅ **ALL PASSING**

## Documentation

For detailed information, see:
- **Test Results**: `SECURITY_TEST_RESULTS.md`
- **Testing Guide**: `SECURITY_TESTING_GUIDE.md`
- **Implementation Summary**: `../PHASE_1_SECURITY_FIXES_SUMMARY.md`
- **Security Overview**: `../SECURITY.md`

## Security Measures Tested

### Anti-Wallhack Protection
- ✅ Maximum fire distance (15 studs)
- ✅ Direction alignment (dot-product check)
- ✅ NaN value protection

### Server Authority
- ✅ Ammo consumption validation
- ✅ Fire rate limiting
- ✅ Currency management
- ✅ Damage calculations
- ✅ Shop purchases
- ✅ Alliance requests
- ✅ Puzzle answers

## Maintenance

These tests should be run:
- ✅ Before production deployment
- ✅ After security-related changes
- ✅ After major refactoring
- ✅ As part of regular security audits

## Troubleshooting

**Q**: Tests fail to run  
**A**: Ensure `security_validation_tests.lua` is in `ReplicatedStorage/tests/`

**Q**: Module not found error  
**A**: Verify the path in the require statement matches your folder structure

**Q**: All tests fail  
**A**: Check that you're running in Play mode, not Edit mode

## Contributing

When adding new security measures:
1. Add corresponding test to `security_validation_tests.lua`
2. Update `SECURITY_TEST_RESULTS.md` with new test
3. Document in `SECURITY_TESTING_GUIDE.md` if manual testing needed
4. Update this README with new test count

## Version History

- **v1.0** (2026-02-10): Initial release
  - 11 automated tests
  - Complete documentation
  - BUG-004 and BUG-009 coverage

---

**Last Updated**: 2026-02-10  
**Status**: ✅ Production Ready  
**Maintainer**: Security Team
