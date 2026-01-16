-- @ScriptType: Script
# Code Architecture - AwavePuzz

This document explains the code organization, architectural decisions, and clarifies why certain files may appear duplicated.

## Table of Contents
- [Overview](#overview)
- [Shared Utilities](#shared-utilities)
- [Client Systems](#client-systems)
- [Server Systems](#server-systems)
- [Legacy vs Active Code](#legacy-vs-active-code)

---

## Overview

AwavePuzz is structured as a modular Lua codebase for Roblox, with clear separation between:
- **Client-side code** (`src/client/`) - Runs on each player's device
- **Server-side code** (`src/server/`) - Runs on the game server
- **Shared code** (`src/shared/`) - Configuration and utilities used by both

---

## Shared Utilities

Located in `src/shared/`, these modules provide reusable functionality:

### MathUtil.lua
Consolidated mathematical utility functions used across the codebase:
- `clamp(value, min, max)` - Constrains a value between min and max
- `lerp(a, b, t)` - Linear interpolation between two values
- `smoothLerp(a, b, t)` - Smooth interpolation using cosine
- `map(value, inMin, inMax, outMin, outMax)` - Remaps a value from one range to another
- `round(value)` - Rounds to nearest integer
- `roundToDecimal(value, decimals)` - Rounds to specified decimal places

**Previous Implementation:** Before consolidation, `clamp()` and `lerp()` were duplicated in 3 client files.

### RemoteEventUtil.lua
Unified remote event creation and management:
- `getOrCreateEvent(eventName)` - Creates or retrieves a RemoteEvent
- `getOrCreateEvents(eventNames)` - Batch creation of multiple RemoteEvents
- `getOrCreateFunction(functionName)` - Creates or retrieves a RemoteFunction
- `waitForEvent(eventName, timeout)` - Client-side helper to wait for events

**Previous Implementation:** Before consolidation, the remote event creation pattern was duplicated in 11 server files.

---

## Client Systems

### Weapon Controllers

The game includes TWO weapon controller implementations for different feature levels:

#### WeaponController.client.lua (Basic)
- **Purpose:** Simple weapon input handling
- **Features:** Basic firing, weapon switching (1-4 keys)
- **Lines:** 138
- **Use Case:** Fallback/simple implementation or for testing
- **Location:** `StarterPlayerScripts.WeaponController`

#### FPSWeaponController.client.lua (Advanced)
- **Purpose:** Full FPS weapon system
- **Features:**
  - Recoil system with camera kick
  - Dynamic spread based on movement/firing
  - ADS (Aim Down Sights)
  - Magazine + reserve ammo system
  - Manual reload (R key)
  - Fire modes (semi-auto, burst, full-auto)
  - Spread recovery and crosshair updates
- **Lines:** 338
- **Use Case:** Primary FPS gameplay
- **Location:** `StarterPlayerScripts.FPSWeaponController`

**Note:** These are NOT duplicates - they serve different purposes. The basic version is simpler and can be used for testing or as a fallback.

### Camera Systems

The game includes TWO camera implementations for different architectural approaches:

#### FirstPersonCamera.client.lua (Standalone)
- **Purpose:** Complete FPS camera in a single file
- **Features:**
  - Mouse-locked first-person view
  - FOV transitions (sprint, ADS)
  - Character transparency management
  - Configurable sensitivity and look smoothing
  - Recoil application
- **Lines:** 419
- **Architecture:** Monolithic - all logic in one LocalScript
- **Use Case:** Primary implementation (documented in FPS_DOCUMENTATION.md)
- **Location:** `StarterPlayerScripts.FirstPersonCamera`

#### FPS/FirstPersonCamera.lua + FirstPersonController.client.lua (Modular)
- **Purpose:** Modular camera system
- **Files:**
  - `FirstPersonCamera.lua` (149 lines) - ModuleScript with camera logic
  - `FirstPersonController.client.lua` (48 lines) - Bootstrap LocalScript
- **Architecture:** Modular - separated concerns
- **Use Case:** Alternative/experimental implementation
- **Location:** `StarterPlayerScripts.FPS/`

**Note:** Both camera systems provide similar functionality but use different architectures:
- **Standalone version:** Easier to understand, all code in one place
- **Modular version:** Better separation of concerns, more testable

The documentation primarily references the standalone version (`FirstPersonCamera.client.lua`).

---

## Server Systems

### Cure/Puzzle Management

#### CureService.lua (Active)
- **Purpose:** Main cure system integrated with puzzles and alliances
- **Features:**
  - Per-player component tracking
  - Alliance resource pooling
  - Integration with PuzzleService
  - Cure progress updates
- **Lines:** 477
- **Status:** ✅ ACTIVE - Used in MainServer.lua

#### CureCraftingManager.lua (Legacy/Helper)
- **Purpose:** Simple cure progress calculation
- **Features:**
  - Component collection tracking
  - Progress percentage calculation
  - Cure completion checking
- **Lines:** 101
- **Status:** ⚠️ LEGACY - Used in GameServer.lua (which itself is legacy)

**Note:** `CureCraftingManager` is a simpler, standalone version. The active game uses `CureService` which has more features including puzzle integration.

### GameServer.lua (Legacy)

- **Purpose:** Original game controller
- **Status:** ⚠️ LEGACY - Not used in MainServer.lua
- **Replacement:** `GameManager.lua` is the active game controller

**Why it exists:** Kept for reference and potential future use. The codebase evolved to use `GameManager` which has more features.

---

## Code Organization Best Practices

### When Adding New Features

1. **Check for existing utilities** in `src/shared/`:
   - Use `MathUtil` for math operations
   - Use `RemoteEventUtil` for creating RemoteEvents
   - Add new shared utilities to these modules rather than duplicating

2. **Server services should**:
   - Use `RemoteEventUtil.getOrCreateEvents()` for setting up RemoteEvents
   - Follow the singleton pattern where appropriate (e.g., `PlayerManager`)
   - Keep service logic focused on a single responsibility

3. **Client scripts should**:
   - Use `MathUtil` for mathematical operations
   - Use `RemoteEventUtil.waitForEvent()` to wait for server events
   - Keep UI logic separate from game logic

### File Naming Conventions

- **`.client.lua`** - LocalScript that runs on the client
- **`.server.lua`** - Script that runs on the server (not commonly used in this project)
- **`.lua`** - ModuleScript that can be required by other scripts

---

## Migration from Legacy Code

If you need to migrate from legacy systems to active systems:

### From GameServer to GameManager
- `GameServer.new()` → `GameManager.new(allianceService)`
- Game state is managed by `GameManager` and its connected services

### From CureCraftingManager to CureService
- `CureCraftingManager.new()` → `CureService.new(gameManager, playerManager)`
- Link with `PuzzleService` and `AllianceService` for full functionality
- Use per-player component tracking instead of global state

---

## Summary

**Key Principles:**
1. **Shared utilities** reduce code duplication (MathUtil, RemoteEventUtil)
2. **Multiple implementations** serve different purposes (basic vs. advanced features)
3. **Legacy code** is kept for reference but not actively used
4. **Modular architecture** allows flexibility and experimentation

**Active Systems:**
- GameManager (not GameServer)
- CureService (primary cure system)
- FPSWeaponController (advanced weapons)
- FirstPersonCamera.client.lua (primary camera)
- All services use shared RemoteEventUtil

**Maintained for Flexibility:**
- WeaponController (basic weapon alternative)
- FPS/FirstPersonCamera (modular camera alternative)
- CureCraftingManager (simple cure logic helper)
