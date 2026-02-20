# AwavePuzz Documentation Index

This document provides a comprehensive guide to all documentation available for the AwavePuzz project.

## 📖 Getting Started

If you're new to the project, start here:

1. **[README.md](README.md)** - Project overview, features, and quick start guide
2. **[QUICKSTART.md](QUICKSTART.md)** - Quick start guide for the restructured repository
3. **[INSTALLATION.md](INSTALLATION.md)** - Step-by-step installation guide for Roblox Studio
4. **[GAME_DESIGN.md](GAME_DESIGN.md)** - Understand the game mechanics and design philosophy

### Repository Structure Notes

- **[ASSET_PLACEHOLDERS.md](ASSET_PLACEHOLDERS.md)** - Documentation for placeholder files
- **[docs/STRUCTURE.md](docs/STRUCTURE.md)** - Detailed project structure guide

## 🔧 Development Documentation

### Core Technical References

#### [API_DOCUMENTATION.md](API_DOCUMENTATION.md)
**45KB | 1,888 lines**

Complete API reference for all game modules, including:
- GameConfig and configuration modules
- Server-side services (GameServer, PlayerManager, WaveManager, etc.)
- Client-side controllers
- Shared utilities and modules
- Detailed method signatures and usage examples

#### [CODE_ARCHITECTURE.md](CODE_ARCHITECTURE.md)
**7.5KB | 208 lines**

Explains the code organization and architectural decisions:
- Shared utilities (MathUtil, RemoteEventUtil)
- Active vs legacy code
- Migration guides
- Best practices for development

### Implementation Documentation

#### [docs/implementation/overview.md](docs/implementation/overview.md)

Current implementation status and feature summary:
- All implemented systems overview
- Architecture notes
- Known limitations

#### [docs/implementation/alliance-v2.md](docs/implementation/alliance-v2.md)

Detailed alliance pooling and betrayal system implementation.

#### [docs/implementation/base-camp.md](docs/implementation/base-camp.md)

Base camp system implementation details.

#### [docs/implementation/device-compatibility.md](docs/implementation/device-compatibility.md)

Cross-platform compatibility implementation (mobile, console, VR).

### System-Specific Documentation

#### [FPS_DOCUMENTATION.md](FPS_DOCUMENTATION.md)
**16KB | 606 lines**

Complete guide to the first-person shooter system:
- First-person camera mechanics
- Movement system (sprint, crouch, stamina)
- Weapon mechanics (recoil, spread, ADS, fire modes)
- Reload system and ammo management
- HUD elements (crosshair, hitmarkers, damage indicators)
- Audio system
- Menu system
- Configuration and tuning guide

#### [docs/ANIMATIONS.md](docs/ANIMATIONS.md)

Consolidated animation documentation including:
- **Animation Creation Guide** – step-by-step tutorial for creating weapon animations
- **Animation Quick Reference** – quick reference card for animation configuration
- **Animation Validation Checklist** – pre-release animation checklist
- **Weapon Animations** – comprehensive weapon animation system guide (viewmodel, procedural animations, event-driven integration)

### Feature Documentation

#### [docs/features/puzzle-system.md](docs/features/puzzle-system.md)

Complete puzzle system documentation:
- 6 puzzle types explained
- Gameplay flow (collection, attempt, synthesis phases)
- Betrayal mechanics and puzzle stealing
- Server architecture
- Client UI
- Configuration options
- Setup and testing procedures
- Troubleshooting guide

#### [docs/features/zombie-ai.md](docs/features/zombie-ai.md)

Zombie AI behavior and improvements documentation:
- AI targeting system
- Attack mechanics
- Movement and pathfinding
- Animation integration
- Configuration options
- Performance considerations
- Tactical AI system overview

For advanced AI features, see:
- [docs/ai_changes.md](docs/ai_changes.md) - Detailed tactical AI implementation
- [docs/ai_testing_guide.md](docs/ai_testing_guide.md) - Testing procedures for AI systems

#### [docs/features/alliance-system.md](docs/features/alliance-system.md)

Alliance pooling system documentation:
- Alliance graph mechanics
- Resource pooling
- Betrayal mechanics
- Configuration

#### [docs/features/base-camp.md](docs/features/base-camp.md)

Base camp system feature documentation:
- Automatic generation
- Defensive structures
- Visual design
- Configuration options

#### [docs/features/map-structure.md](docs/features/MAP_STRUCTURE.md)

Map structure standards and creation guide:
- Required folder structure
- Spawn point requirements
- Map validation
- Creating new maps

#### [docs/features/device-compatibility.md](docs/features/DEVICE_COMPATIBILITY.md)

Cross-platform device compatibility:
- PC/Mac, Mobile, Console, VR support
- InputManager system
- Platform-specific controls
- UI scaling

### Testing Documentation

#### [docs/TESTING_GUIDE.md](docs/TESTING_GUIDE.md)

Consolidated testing documentation including:
- Bug-specific test guides (Bug 005/006, ammo fix, weapon origin fix)
- Boot smoke test validation report
- Comprehensive test suite summary and README
- General testing guide and audit-change testing
- Lobby state machine test plan
- Loading progress bar, title screen first load, and zombie hit reaction test guides
- Test suite quick reference and validation reports

#### [tests/README.md](tests/README.md)
**Complete Test Suite Documentation**

Overview of all test categories:
- **Boot & Safety Tests** - Boot system validation (12 tests)
- **Security Tests** - Configuration and exploit prevention (11 tests)
- **Memory Leak Tests** - Connection and cleanup validation
- **Race Condition Tests** - State consistency validation
- **System Integration Tests** - Cross-system validation

#### [tests/boot_smoke_tests.lua](tests/boot_smoke_tests.lua)
**Boot System Validation Suite**

Validates boot safety with 12 comprehensive tests.

Run in Studio Command Bar:
```lua
require(game.ReplicatedStorage.tests.run_boot_tests)
```

#### [tests/security_validation_tests.lua](tests/security_validation_tests.lua)
**Security Configuration Tests**

Automated security validation (11 tests).

Run in Studio Command Bar:
```lua
require(game.ReplicatedStorage.tests.run_security_tests)
```

#### [BOOT_SAFETY_GUIDE.md](BOOT_SAFETY_GUIDE.md)
**Boot System Safety Documentation**

Complete guide to boot safety, entry points, RemoteRegistry, and troubleshooting.

#### [docs/testing/TESTING_ALLIANCE_SYSTEM.md](docs/testing/TESTING_ALLIANCE_SYSTEM.md)

Complete testing guide for the alliance and betrayal system.

#### [docs/testing/TESTING_MAP_AND_LOBBY.md](docs/testing/TESTING_MAP_AND_LOBBY.md)

Testing guide for map positioning and lobby improvements.

### Consolidated Reference Documentation

#### [docs/BUG_FIXES.md](docs/BUG_FIXES.md)

All bug fix summaries consolidated in one place:
- Individual bug fix records (BUG-001, BUG-005/006, BUG-007, etc.)
- Ammo display, boot duplication, camera movement, cure station, UI fixes
- Memory leak, security hardening, and unfixable bugs documentation

#### [docs/AUDITS.md](docs/AUDITS.md)

All audit reports and production readiness assessments:
- Code consistency, executive summaries, findings verification
- Comprehensive audit reports (2026), cure synthesis, animation ID audits
- Camera movement audit, production readiness reports

#### [docs/IMPLEMENTATION_HISTORY.md](docs/IMPLEMENTATION_HISTORY.md)

Implementation history, refactors, and architecture decisions:
- Baseline safety, loading progress bar, puzzle, state refactor implementations
- Zombie hit reaction changes and security
- Completion summaries, investigation records, verification
- Module dependencies, UI/inventory architecture, file naming conventions, remote events list

#### [docs/PR_HISTORY.md](docs/PR_HISTORY.md)

Pull request history and stabilization records:
- PR stabilization summary, general PR summary
- Bug 005/006 PR summary, title screen first load PR summary

#### [docs/BOOT_SYSTEM.md](docs/BOOT_SYSTEM.md)

Complete boot system documentation:
- Boot flow and start flow diagrams
- Boot safety guide and quick reference
- Flow diagrams for the entire system

### Historical Documentation

Historical documentation has been archived for reference. See [docs/archive/README.md](docs/archive/README.md) for:
- **docs/archive/fixes/** - Bug fix and stabilization reports (15 files)
- **docs/archive/summaries/** - Implementation summaries and milestones (13 files)
- **docs/archive/reviews/** - Code reviews and project assessments (3 files)
- **docs/archive/reports/** - General project reports and audits (11 files)

These documents track the evolution of the codebase but are no longer actively maintained.

### Communication and Data Flow

#### [docs/REMOTE_EVENTS.md](docs/REMOTE_EVENTS.md)

Complete RemoteEvent reference:
- All RemoteEvents organized by domain
- Direction (Client → Server or Server → Client)
- Payload structure for each event
- Usage guidelines and examples
- Security considerations
- Naming conventions

#### [docs/STRUCTURE.md](docs/STRUCTURE.md)

Project structure and organization guide:
- File organization conventions
- Roblox hierarchy mapping
- Naming conventions
- Module dependencies

## 🎮 Gameplay Systems

### Core Mechanics

- **Multiplayer**: Up to 8 players, cooperative and competitive gameplay
- **Wave System**: Progressive zombie difficulty, 10 configured waves
- **FPS Combat**: Recoil, spread, ADS, multiple fire modes
- **Puzzle System**: 6 puzzles (5 components + final synthesis)
- **Alliance System**: Team up or betray other players
- **Cure Crafting**: Collect components, solve puzzles, synthesize cure

### Win/Lose Conditions

**Victory:** Complete the cure by solving all 6 puzzles
**Defeat:** Base destroyed or all players eliminated

## 🗂️ Documentation by Use Case

### "I want to set up the game"
1. [INSTALLATION.md](INSTALLATION.md) - Complete setup guide
2. [README.md](README.md) - Quick start section

### "I want to understand how the code works"
1. [CODE_ARCHITECTURE.md](CODE_ARCHITECTURE.md) - High-level architecture
2. [API_DOCUMENTATION.md](API_DOCUMENTATION.md) - Detailed API reference
3. [docs/implementation/overview.md](docs/implementation/overview.md) - What's implemented

### "I want to add weapon animations"
1. [docs/ANIMATIONS.md](docs/ANIMATIONS.md) - All animation docs consolidated
2. [BOOT_SAFETY_GUIDE.md](BOOT_SAFETY_GUIDE.md) - Boot safety for animation scripts

### "I want to tune game balance"
1. [FPS_DOCUMENTATION.md](FPS_DOCUMENTATION.md) - FPS system tuning
2. [GAME_DESIGN.md](GAME_DESIGN.md) - Design philosophy
3. [docs/features/puzzle-system.md](docs/features/puzzle-system.md) - Puzzle configuration

### "I want to add new features"
1. [CODE_ARCHITECTURE.md](CODE_ARCHITECTURE.md) - Architecture patterns
2. [docs/REMOTE_EVENTS.md](docs/REMOTE_EVENTS.md) - Communication patterns
3. [API_DOCUMENTATION.md](API_DOCUMENTATION.md) - Existing APIs to integrate with

### "I need to troubleshoot an issue"
1. [INSTALLATION.md](INSTALLATION.md) - Setup troubleshooting
2. [docs/ANIMATIONS.md](docs/ANIMATIONS.md) - Animation troubleshooting
3. [docs/features/puzzle-system.md](docs/features/puzzle-system.md) - Puzzle troubleshooting
4. [FPS_DOCUMENTATION.md](FPS_DOCUMENTATION.md) - FPS system troubleshooting
5. [docs/BUG_FIXES.md](docs/BUG_FIXES.md) - Historical bug fixes and known issues

## 📊 Documentation Statistics

- **Core Documentation**: 14 essential files in root directory
- **Technical References**: 4 additional reference files (CODE_ARCHITECTURE, MODULE_DEPENDENCIES, INPUT_ACTION_MAP, UI_INVENTORY_AND_ARCHITECTURE)
- **Implementation Docs**: 4 files in docs/implementation/
- **Feature Docs**: 6 files in docs/features/
- **Testing Guides**: 2 files in docs/testing/
- **Archived Docs**: 42 files in docs/archive/ (organized by category)
- **Total Active**: ~30 actively maintained documentation files
- **Total Including Archive**: ~72 documentation files
- **Most Comprehensive**: API_DOCUMENTATION.md (55KB)

## 🔍 Quick Search Guide

### Configuration Files
- Game balance → `ReplicatedStorage/Shared/GameConfig.lua`
- FPS settings → `ReplicatedStorage/Shared/FPSConfig.lua`
- Weapon stats → `ReplicatedStorage/Shared/WeaponConfig.lua`
- Wave progression → `ReplicatedStorage/Shared/WaveConfig.lua`
- Puzzle settings → `ReplicatedStorage/Shared/PuzzleConfig.lua`
- Zombie types → `ReplicatedStorage/Shared/ZombieTypes.lua`

### Key Modules
- Main entry point → `ServerScriptService/MainServer.lua`
- Game orchestration → `ServerScriptService/GameManager.lua`
- Zombie spawning → `ServerScriptService/Spawner.lua`
- Zombie AI → `ServerScriptService/AI/ZombieBrain.lua`
- Player data → `ServerScriptService/PlayerManager.lua`
- Alliances → `ServerScriptService/AllianceServiceV2.lua`
- Puzzles → `ServerScriptService/PuzzleService.lua`
- FPS camera → `StarterPlayer/StarterPlayerScripts/FPS/FirstPersonCamera.lua`
- FPS weapons → `StarterPlayer/StarterPlayerScripts/Modules/FPSWeaponController.lua`

## 🎯 Documentation Goals

This documentation aims to be:
- ✅ **Comprehensive** - Covers all systems in meticulous detail
- ✅ **Relevant** - Focuses on information developers need
- ✅ **Easy to Follow** - Clear structure and navigation
- ✅ **Practical** - Includes examples, troubleshooting, and use cases
- ✅ **Maintainable** - Organized and non-redundant

## 📝 Contributing to Documentation

When updating documentation:

1. **Keep it DRY** - Don't duplicate information across files
2. **Link between docs** - Use relative links to connect related information
3. **Update this index** - When adding new documentation files
4. **Follow the structure** - Use consistent formatting and organization
5. **Include examples** - Show, don't just tell
6. **Test your instructions** - Verify setup guides actually work

## 🆘 Getting Help

If you can't find what you're looking for:

1. Check this documentation index for the right file
2. Use your editor's search across all .md files
3. Check the [API_DOCUMENTATION.md](API_DOCUMENTATION.md) for technical details
4. Review [CODE_ARCHITECTURE.md](CODE_ARCHITECTURE.md) for design patterns
5. Open an issue on GitHub with your question

---

**Last Updated**: January 2026
**Documentation Version**: 4.0 (Consolidated into docs/ chapters)
**Project Status**: ✅ Complete and Production-Ready
