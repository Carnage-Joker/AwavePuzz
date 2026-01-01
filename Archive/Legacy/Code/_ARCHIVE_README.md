# Archived Code

This directory contains legacy and archived code that is no longer actively used in the game.

**DO NOT USE CODE FROM THIS DIRECTORY IN PRODUCTION**

## Contents

### Server/
Legacy server-side code including:
- `CureCraftingManager.lua` - Old cure crafting implementation (replaced by CureSynthesisService)
- `GameServer.lua` - Deprecated game server (replaced by MainServer and GameManager)

### Client/
Legacy client-side code including:
- Disabled `.client.lua` files - Old UI controllers and FPS implementations
- All functionality has been replaced by modular systems in StarterPlayer/StarterPlayerScripts/

**Note**: Files have `.disabled` extension to prevent accidental execution.

## Purpose

This archived code is kept for:
1. Historical reference
2. Understanding design evolution
3. Potential feature recovery if needed
4. Learning from past implementations

## What Was Removed

**January 2026 Cleanup:**
- ✅ Removed `Original_src_Structure/` - Exact duplicates of active code in ServerScriptService, StarterPlayer, and ReplicatedStorage
- ✅ Removed `DevTools/` - Development tools moved to ServerStorage/DevOnly/

## Safety

This code is intentionally placed 3 levels deep (Archive/Legacy/Code/) to prevent accidental inclusion in the active codebase.
