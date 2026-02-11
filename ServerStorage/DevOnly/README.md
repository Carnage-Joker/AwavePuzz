# DevOnly Folder

This folder contains disabled, legacy, and development-only files that are not part of the active game.

## Contents

### Disabled/Legacy Files (Archived)
These files have been replaced by newer implementations or are no longer in use:

- **ClientControllerDisabled.lua** - Old client controller (replaced by modular boot system)
- **ClientMainClientDisabled.lua** - Old client main script
- **ClientMainLegacy.lua** - Legacy client main implementation
- **MainServerCompatibilityShim.lua** - Legacy compatibility marker (actual boot in MainServerScript.lua)
- **MainServerOldVersion.lua** - Old version of MainServer (replaced by MainServerScript.lua)
- **FirstPersonCameraDisabled.lua** - Old FPS camera implementation
- **FirstPersonControllerArchivedDisabled.lua** - Archived FPS controller
- **LocalScriptDisabled.lua** - Disabled local script
- **LocalScript1Disabled.lua** - Disabled local script

### Test Files
Development and testing utilities:

- **AllianceSystemTests.lua** - Alliance system tests
- **AnimationValidationTest.lua** - Animation validation tests
- **AssetValidationTests.lua** - Asset validation tests
- **ConfigurationTests.lua** - Configuration tests
- **CoreSystemsTests.lua** - Core systems tests
- **CureAndPuzzleTests.lua** - Cure and puzzle tests
- **IntegrationTests.lua** - Integration tests
- **LobbySystemTests.lua** - Lobby system tests
- **MapSystemTests.lua** - Map system tests
- **MovementSystemTests.lua** - Movement system tests
- **ShopSystemTests.lua** - Shop system tests
- **SpawningSystemTests.lua** - Spawning system tests
- **SpectatorSystemTests.lua** - Spectator system tests
- **UISystemTests.lua** - UI system tests
- **WeaponSystemTests.lua** - Weapon system tests
- **TestFramework.lua** - Test framework utilities
- **TestRunner.lua** - Test runner

### Deprecated Systems
- **CureCraftingManager.lua** - Old cure crafting (replaced by CureSynthesisService)
- **AmmoSystemFix.lua** - Legacy ammo system fix

### Development Tools
- **MapGenerator.lua** - Map generation utilities
- **SpawnPointVisualizer.lua** - Spawn point visualization tool
- **VisualizeBaseCamp.lua** - Base camp visualization
- **TestBaseCamp.lua** - Base camp testing
- **TestBaseCampCleanup.lua** - Base camp cleanup utilities
- **TestBaseCampConfig.lua** - Base camp test configuration

## Important Notes

**These files are NOT loaded by the game** - They are stored here for reference and development purposes only.

**Do NOT move these files back to active directories** - They have been intentionally disabled or replaced.

**File Naming Convention** - As of 2026-02-11, all active files use simple `.lua` extensions without dots in the name (e.g., `MainServerScript.lua` not `Main.server.lua`) to prevent sync tool compatibility issues.
