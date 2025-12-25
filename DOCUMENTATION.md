# AwavePuzz Documentation Index

This document provides a comprehensive guide to all documentation available for the AwavePuzz project.

## 📖 Getting Started

If you're new to the project, start here:

1. **[README.md](README.md)** - Project overview, features, and quick start guide
2. **[QUICKSTART.md](QUICKSTART.md)** - ✨ Quick start guide for the restructured repository
3. **[INSTALLATION.md](INSTALLATION.md)** - Step-by-step installation guide for Roblox Studio
4. **[GAME_DESIGN.md](GAME_DESIGN.md)** - Understand the game mechanics and design philosophy

### Repository Structure Notes

The repository was recently restructured to match Roblox Studio's layout:
- **[RESTRUCTURE_CHANGELOG.md](RESTRUCTURE_CHANGELOG.md)** - Details on the restructuring changes
- **[ASSET_PLACEHOLDERS.md](ASSET_PLACEHOLDERS.md)** - Documentation for placeholder files

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
- Why certain files appear duplicate but serve different purposes
- Active vs legacy code
- Migration guides
- Best practices for development

#### [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)
**15KB | 406 lines**

Complete implementation status document:
- Feature checklist (all phases complete)
- File structure overview
- Configuration highlights
- Testing checklist
- Phase-by-phase development progress

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

#### [WEAPON_ANIMATIONS.md](WEAPON_ANIMATIONS.md)
**27KB | 946 lines**

Comprehensive weapon animation system guide:
- System architecture
- 6 animation types per weapon (idle, fire, reload, equip, sprint, ADS)
- Viewmodel system
- Procedural animations (sway, breathing, recoil recovery)
- Event-driven integration
- Configuration reference
- Troubleshooting guide

#### [ANIMATION_CREATION_GUIDE.md](ANIMATION_CREATION_GUIDE.md)
**12KB | 463 lines**

Step-by-step tutorial for creating weapon animations:
- Roblox Studio animation tools setup
- Creating each animation type
- Best practices and timing guidelines
- Exporting and publishing animations
- Integration with the game

#### [ANIMATION_QUICK_REFERENCE.md](ANIMATION_QUICK_REFERENCE.md)
**6.4KB | 212 lines**

Quick reference card for animation configuration:
- Animation types table
- Configuration locations
- Adding animation assets
- Procedural animation settings
- Weapon positioning
- Event flow diagram

#### [PUZZLE_SYSTEM.md](PUZZLE_SYSTEM.md)
**9.3KB | 271 lines**

Complete puzzle system documentation:
- 6 puzzle types explained
- Gameplay flow (collection, attempt, synthesis phases)
- Betrayal mechanics and puzzle stealing
- Server architecture
- Client UI
- Configuration options
- Setup and testing procedures
- Troubleshooting guide

#### [ZOMBIE_AI.md](ZOMBIE_AI.md)
**13KB | 406 lines**

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

### Communication and Data Flow

#### [docs/REMOTE_EVENTS.md](docs/REMOTE_EVENTS.md)
**13KB | 433 lines**

Complete RemoteEvent reference:
- All RemoteEvents organized by domain
- Direction (Client → Server or Server → Client)
- Payload structure for each event
- Usage guidelines and examples
- Security considerations
- Naming conventions

#### [docs/STRUCTURE.md](docs/STRUCTURE.md)
**Size varies**

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
3. [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - What's implemented

### "I want to add weapon animations"
1. [ANIMATION_CREATION_GUIDE.md](ANIMATION_CREATION_GUIDE.md) - Step-by-step tutorial
2. [ANIMATION_QUICK_REFERENCE.md](ANIMATION_QUICK_REFERENCE.md) - Quick config reference
3. [WEAPON_ANIMATIONS.md](WEAPON_ANIMATIONS.md) - Complete system documentation

### "I want to tune game balance"
1. [FPS_DOCUMENTATION.md](FPS_DOCUMENTATION.md) - FPS system tuning
2. [GAME_DESIGN.md](GAME_DESIGN.md) - Design philosophy
3. [PUZZLE_SYSTEM.md](PUZZLE_SYSTEM.md) - Puzzle configuration

### "I want to add new features"
1. [CODE_ARCHITECTURE.md](CODE_ARCHITECTURE.md) - Architecture patterns
2. [docs/REMOTE_EVENTS.md](docs/REMOTE_EVENTS.md) - Communication patterns
3. [API_DOCUMENTATION.md](API_DOCUMENTATION.md) - Existing APIs to integrate with

### "I need to troubleshoot an issue"
1. [INSTALLATION.md](INSTALLATION.md) - Setup troubleshooting
2. [WEAPON_ANIMATIONS.md](WEAPON_ANIMATIONS.md) - Animation troubleshooting
3. [PUZZLE_SYSTEM.md](PUZZLE_SYSTEM.md) - Puzzle troubleshooting
4. [FPS_DOCUMENTATION.md](FPS_DOCUMENTATION.md) - FPS system troubleshooting

## 📊 Documentation Statistics

- **Total Documentation Files**: 18 core documents + additional guides in docs/
- **Total Documentation Size**: ~220KB
- **Most Comprehensive**: API_DOCUMENTATION.md (45KB)
- **Quick References**: ANIMATION_QUICK_REFERENCE.md (6.4KB), QUICKSTART.md (7.2KB)

## 🔍 Quick Search Guide

### Configuration Files
- Game balance → `src/shared/GameConfig.lua`
- FPS settings → `src/shared/FPSConfig.lua`
- Weapon stats → `src/shared/WeaponConfig.lua`
- Wave progression → `src/shared/WaveConfig.lua`
- Puzzle settings → `src/shared/PuzzleConfig.lua`
- Zombie types → `src/shared/ZombieTypes.lua`

### Key Modules
- Main entry point → `src/server/MainServer.lua`
- Game orchestration → `src/server/GameManager.lua`
- Zombie spawning → `src/server/Spawner.lua`
- Zombie AI → `src/server/AIScripts/ZombieBrain.lua`
- Player data → `src/server/PlayerManager.lua`
- Alliances → `src/server/AllianceService.lua`
- Puzzles → `src/server/PuzzleService.lua`
- FPS camera → `src/client/FirstPersonCamera.client.lua`
- FPS weapons → `src/client/FPSWeaponController.client.lua`

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

**Last Updated**: 2025-12-25
**Documentation Version**: 2.0 (Consolidated)
**Project Status**: ✅ Complete and Production-Ready
