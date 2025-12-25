# Archived Client Scripts

This folder contains the original LocalScript files that have been converted to ModuleScripts and are now managed by the single ClientController.client.lua entrypoint.

## Why These Files Are Archived

As part of the refactoring effort to stabilize the codebase, all client-side LocalScripts have been:

1. **Converted to ModuleScripts** - Located in `src/client/Modules/`
2. **Centrally initialized** - Loaded and initialized by `ClientController.client.lua`
3. **Prevented from auto-running** - No longer execute on their own

## Original Files

These `.disabled` files represent the previous architecture where multiple LocalScripts ran simultaneously, causing:
- Camera instability
- Input conflicts
- Duplicate bindings
- Race conditions

## New Architecture

The new architecture uses:
- **Single entrypoint:** `ClientController.client.lua`
- **Module-based subsystems:** Camera, Movement, Weapons, Animation, Audio, Menu, UI
- **Explicit initialization:** All systems initialized in a controlled order
- **No conflicts:** Only one script executes, preventing duplicate systems

## Do Not Delete

These files are kept for reference and documentation purposes. They demonstrate the evolution of the codebase and may be useful for:
- Understanding the original implementation
- Comparing old vs new approaches
- Debugging if issues arise
- Documentation of refactoring decisions

---

**Date Archived:** December 2025  
**Reason:** Client architecture refactoring - single entrypoint implementation
