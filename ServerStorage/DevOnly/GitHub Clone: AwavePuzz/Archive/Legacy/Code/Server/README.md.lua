-- @ScriptType: Script
# Archived Server Scripts

This folder contains legacy server implementations that have been replaced by newer, more feature-complete versions.

## Archived Files

### GameServer.lua
**Status:** LEGACY - Not used in MainServer.lua  
**Replacement:** GameManager.lua

GameServer.lua was the original game controller implementation. It has been superseded by GameManager.lua which provides:
- Better service integration
- Enhanced alliance system support
- Improved cure/puzzle mechanics
- More robust state management

**Note:** GameServer.lua is kept for reference and potential future use during development.

### CureCraftingManager.lua
**Status:** LEGACY/HELPER - Used by GameServer.lua (which itself is legacy)  
**Replacement:** CureService.lua

CureCraftingManager.lua provided simple cure progress calculation. It has been replaced by CureService.lua which offers:
- Per-player component tracking
- Alliance resource pooling
- Full PuzzleService integration
- Advanced cure progress mechanics

## Why These Files Are Archived

The codebase evolved to use more sophisticated services with better feature sets. The active game uses:
- **GameManager.lua** - Primary game controller
- **CureService.lua** - Advanced cure system with puzzle integration

## Do Not Delete

These files are preserved for:
- Reference during development
- Understanding system evolution
- Fallback if issues arise with new implementations
- Documentation of architectural decisions

---

**Date Archived:** December 2025  
**Reason:** Code evolution - replaced by more feature-complete implementations
