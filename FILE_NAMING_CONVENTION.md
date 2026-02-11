# File Naming Convention Update - Summary

**Date**: 2026-02-11  
**Version**: 3.0

## Overview

All Lua files in the AwavePuzz repository now use simple `.lua` extensions without additional dots in filenames. This prevents compatibility issues with Roblox sync tools like Rojo and GitSync.

## Changes Made

### 1. File Renamings

| Old Name | New Name | Location |
|----------|----------|----------|
| `Main.server.lua` | `MainServerScript.lua` | ServerScriptService/ |
| `Boot.client.lua` | `BootClient.lua` | StarterPlayer/StarterPlayerScripts/ |

### 2. Disabled Files Moved to DevOnly

All disabled and legacy files have been moved to `ServerStorage/DevOnly/`:

- ClientMainLegacy.lua
- LocalScriptDisabled.lua
- LocalScript1Disabled.lua
- MainServerCompatibilityShim.lua
- MainServerOldVersion.lua
- ClientControllerDisabled.lua
- ClientMainClientDisabled.lua
- FirstPersonCameraDisabled.lua
- FirstPersonControllerArchivedDisabled.lua

### 3. Placeholder Files Deleted

Removed 83 placeholder files:
- 57 files in `ReplicatedStorage/RemoteEvents/*.txt.lua`
- 7 files in `ReplicatedStorage/Animations/Weapons/Shotgun/*.txt.lua`
- 3 files in `ServerStorage/Maps/*_PLACEHOLDER.txt.lua`
- 7 files in `ServerStorage/Models/*_PLACEHOLDER.txt.lua`
- 6 files in `ServerStorage/ZombieModels/*_PLACEHOLDER.txt.lua`
- 1 file `ServerStorage/ZombieModels/_README.txt.lua`
- 2 files in `ReplicatedStorage/Animations/Weapons/Shotgun/`

### 4. Code Updates

Updated comments in:
- `ServerScriptService/MainServerScript.lua`
- `ServerScriptService/GameManager.lua`
- `ServerScriptService/CureService.lua`
- `StarterPlayer/StarterPlayerScripts/BootClient.lua`
- `StarterPlayer/StarterPlayerScripts/ClientMainModule.lua`

### 5. Documentation Updates

**INSTALLATION.md (Version 3.0)**
- Complete file structure with all 93 current files
- Exact names and directory placements
- Removed outdated content
- Added file naming convention notes
- Streamlined setup instructions

**README.md**
- Updated repository structure diagram
- Added file naming convention note
- Updated references to installation guide

**New: ServerStorage/DevOnly/README.md**
- Documents all disabled/legacy files
- Explains test files and development tools
- Notes file naming convention

## Naming Convention

### ✅ Correct Format
- `MainServerScript.lua` - Server script entry point
- `BootClient.lua` - Client script entry point
- `GameManager.lua` - Module script
- `FPSWeaponController.lua` - Module script

### ❌ Old Format (No Longer Used)
- ~~`Main.server.lua`~~
- ~~`Boot.client.lua`~~
- ~~`GameManager.module.lua`~~
- ~~`Placeholder.txt.lua`~~

## Script Type Identification

In Roblox Studio, script types are determined by the **instance class**, not the filename:

- **Script** - Server-side script (e.g., MainServerScript)
- **LocalScript** - Client-side script (e.g., BootClient)
- **ModuleScript** - Reusable module (e.g., GameManager)

Filenames should **only** have the `.lua` extension.

## Benefits

1. **Compatibility**: Works seamlessly with all Roblox sync tools (Rojo, GitSync, etc.)
2. **Clarity**: No confusion about script types - determined by instance class in Roblox
3. **Consistency**: All files follow the same naming pattern
4. **Maintainability**: Easier to identify and manage files
5. **Clean Repository**: No placeholder or disabled files cluttering active directories

## Migration Guide

### For Existing Installations

If you have an existing Roblox game with the old file names:

1. **In Roblox Studio**, rename:
   - `Main` → `MainServerScript` (keep as Script)
   - `Boot` → `BootClient` (keep as LocalScript)

2. Delete or disable:
   - Any files ending in `.txt.lua`
   - Legacy/disabled script copies

3. No code changes needed - script types remain the same

### For New Installations

Follow the updated [INSTALLATION.md](INSTALLATION.md) guide which has the complete current structure with correct file names.

## Testing

All file renamings have been tested to ensure:
- ✅ No broken references in code
- ✅ All requires/imports still work
- ✅ Comments updated to reflect new names
- ✅ Documentation accurate and complete

## Exception

The `tests/heartbeat_leak_test.server.lua` file retains its `.server.lua` extension as it's a test file specifically for testing server script behavior.

## Support

For questions about the new naming convention:
- See [INSTALLATION.md](INSTALLATION.md) - Complete installation guide
- See [README.md](README.md) - Repository overview
- See [ServerStorage/DevOnly/README.md](ServerStorage/DevOnly/README.md) - Disabled files reference

---

**Last Updated**: 2026-02-11  
**Version**: 3.0
