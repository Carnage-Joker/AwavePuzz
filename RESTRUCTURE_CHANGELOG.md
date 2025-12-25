# Repository Restructure Changelog

**Date**: 2025-12-25  
**Purpose**: Restructure repository to match exact Roblox Studio game structure

## Overview

The repository has been completely restructured to mirror the exact directory structure used in Roblox Studio. This makes it easier to understand how files map to the game, simplifies installation, and provides clear organization.

## Major Changes

### 1. New Roblox-Compliant Directory Structure

The repository now uses Roblox service names as top-level directories:

```
AwavePuzz/
├── ServerScriptService/         # Server-side game logic
│   ├── AI/                      # Zombie AI and controllers
│   └── *.lua                    # Server managers and services
├── ReplicatedStorage/           # Shared resources
│   ├── Shared/                  # Shared modules (configs, utils)
│   ├── RemoteEvents/            # RemoteEvent placeholders
│   └── Animations/              # Animation placeholders
├── StarterPlayer/               # Player scripts
│   └── StarterPlayerScripts/    # Client controllers
│       ├── Modules/             # Client modules
│       │   └── UI/              # UI module scripts
│       └── FPS/                 # FPS system modules
├── StarterGui/                  # UI scripts (LocalScripts)
├── ServerStorage/               # Server-only assets
│   ├── Maps/                    # Map models (placeholders)
│   ├── Models/                  # Weapon and object models (placeholders)
│   ├── ZombieModels/            # Zombie character models (placeholders)
│   └── DevOnly/                 # Dev tools (retained)
└── Archive/                     # Archived legacy code
    └── Legacy/
        └── Code/                # 3 levels deep for safety
            ├── Server/          # Archived server code
            ├── Client/          # Archived client code
            ├── DevTools/        # Archived dev tools
            └── Original_src_Structure/  # Original src/ directory
```

### 2. File Migrations

#### Server Files (`src/server/` → `ServerScriptService/`)
- ✅ All 27 server Lua files moved to `ServerScriptService/`
- ✅ AI subfolder moved to `ServerScriptService/AI/` (6 files)
- ✅ Includes: GameManager, PlayerManager, WaveManager, WeaponService, etc.

#### Shared Files (`src/shared/` → `ReplicatedStorage/Shared/`)
- ✅ All 13 shared config files moved to `ReplicatedStorage/Shared/`
- ✅ Includes: GameConfig, WeaponConfig, FPSConfig, ZombieTypes, etc.

#### Client Files (`src/client/` → `StarterPlayer/StarterPlayerScripts/`)
- ✅ Client controllers moved to `StarterPlayer/StarterPlayerScripts/`
- ✅ Modules subfolder moved to `StarterPlayer/StarterPlayerScripts/Modules/`
- ✅ FPS subfolder moved to `StarterPlayer/StarterPlayerScripts/FPS/`
- ✅ Total 27 client Lua files organized properly

#### UI Files (`src/client/Modules/UI/` → `StarterGui/`)
- ✅ All 17 UI module files moved to `StarterGui/`
- ✅ Includes: FPSHUD, WaveUI, AllianceUI, PuzzleUI, etc.

### 3. Placeholder Files Created

#### RemoteEvents (58 placeholders)
Location: `ReplicatedStorage/RemoteEvents/`

All RemoteEvents documented in REMOTE_EVENTS.md now have placeholder .txt files:
- Game State Events (5): WaveAnnounce, WaveUpdate, GameStateUpdate, CureUpdate, BaseHealthUpdate
- Player Events (4): PlayerHealthUpdate, InventoryUpdate, CurrencyUpdate, WeaponLoadoutUpdate
- Weapon Events (5): WeaponFire, WeaponEquip, WeaponReload, WeaponHitConfirm, AmmoUpdate
- Animation Events (6): AnimationFire, AnimationSprint, AnimationADS, + Replicate versions
- Movement Events (2): SprintRequest, StaminaUpdate
- Shop Events (2): ShopRequest, ShopUpdate
- Alliance Events (4): RequestAlliance, RespondAlliance, BreakAlliance, AllianceUpdate
- Puzzle/Cure Events (8): RequestPuzzle, SubmitPuzzleAnswer, PuzzleUpdate, etc.
- Lobby/Map Events (6): MapVoteStart, MapVoteUpdate, MapVoteEnd, CastMapVote, etc.
- Spectator Events (5): EnterSpectatorMode, ExitSpectatorMode, etc.
- UI Events (9): ScoreboardUpdate, ShowScoreboard, ShowTitleScreen, ShowEpilogue, etc.
- Achievement Events (1): AchievementUnlocked

Each includes a _README.txt explaining their purpose.

#### Animations (36 placeholders)
Location: `ReplicatedStorage/Animations/Weapons/`

Created animation placeholders for 5 weapon types (Pistol, SMG, Shotgun, Rifle, AssaultRifle):
- Idle.txt - Breathing and weapon bob animation
- Fire.txt - Recoil and muzzle movement animation
- Reload.txt - Magazine change animation
- Equip.txt - Weapon draw animation
- Sprint.txt - Lowered weapon animation
- ADS.txt - Aim down sights animation

Each weapon folder includes a _README.txt with animation requirements.

#### Models (15 placeholders)
Location: `ServerStorage/ZombieModels/` and `ServerStorage/Models/`

**Zombie Models (5 placeholders)**:
- Walker_PLACEHOLDER.txt
- Runner_PLACEHOLDER.txt
- Brute_PLACEHOLDER.txt
- Spitter_PLACEHOLDER.txt
- Boss_PLACEHOLDER.txt

**Weapon Models (5 placeholders)**:
- Pistol_PLACEHOLDER.txt
- SMG_PLACEHOLDER.txt
- Shotgun_PLACEHOLDER.txt
- Rifle_PLACEHOLDER.txt
- AssaultRifle_PLACEHOLDER.txt

**Other Models (2 placeholders)**:
- CureStation_PLACEHOLDER.txt
- ResourcePickup_PLACEHOLDER.txt

**Map Models (3 placeholders)**:
- ResearchFacility_PLACEHOLDER.txt
- DesertOutpost_PLACEHOLDER.txt
- UrbanRuins_PLACEHOLDER.txt

Each directory includes _README.txt with asset requirements and specifications.

### 4. Archived Code

All legacy and deprecated code moved to `Archive/Legacy/Code/` (3 levels deep):

#### Archived Items:
- `src/server/Archived/` → `Archive/Legacy/Code/Server/`
  - CureCraftingManager.lua (legacy)
  - GameServer.lua (legacy)
  
- `src/client/Archived/` → `Archive/Legacy/Code/Client/`
  - 11 disabled .client.lua files (old controllers)
  
- `src/client/FPS/Archived/` → `Archive/Legacy/Code/Client/`
  - Archived FPS implementations
  
- `src/client/UI/Archived/` → `Archive/Legacy/Code/Client/`
  - Archived UI implementations

- `ServerStorage/DevOnly/` → `Archive/Legacy/Code/DevTools/`
  - SpawnPointVisualizer.lua
  - TestPuzzleSystem.lua
  - FixSystemAmmo.lua
  - AmmoSystemFix.lua

- Original `src/` directory → `Archive/Legacy/Code/Original_src_Structure/`
  - Complete backup of original structure

**Safety Note**: Code placed 3 levels deep (Archive/Legacy/Code/) prevents accidental use in production.

### 5. Removed/Cleaned

- ❌ Old `src/` directory structure (moved to Archive)
- ✅ Empty directories cleaned up
- ✅ No duplicate code in production structure

## File Count Summary

| Location | Lua Files | Placeholders |
|----------|-----------|--------------|
| ServerScriptService | 27 | - |
| ReplicatedStorage/Shared | 13 | - |
| StarterPlayer/StarterPlayerScripts | 27 | - |
| StarterGui | 17 | - |
| ReplicatedStorage/RemoteEvents | - | 58 |
| ReplicatedStorage/Animations | - | 36 |
| ServerStorage (Models/Maps) | - | 15 |
| **Total Active Code** | **84** | **109** |

## Benefits of New Structure

### 1. **Direct Roblox Mapping**
- Directory names match Roblox Studio services exactly
- No mental translation needed between repo and game
- Clear understanding of where each file goes

### 2. **Simplified Installation**
- Copy entire directories to Roblox Studio
- No need to reorganize files during setup
- Easier for new developers to understand

### 3. **Better Documentation**
- Placeholder files document required assets
- README files explain each system's requirements
- Clear separation between code and assets

### 4. **Improved Safety**
- Archived code isolated 3 levels deep
- No risk of accidentally using deprecated code
- Clear distinction between active and legacy systems

### 5. **Professional Organization**
- Matches industry standard Roblox project structure
- Easier collaboration and onboarding
- Better version control granularity

## Migration Guide for Developers

### If You're Updating from Old Structure:

1. **Server Scripts**: 
   - Old: `src/server/*.lua` 
   - New: `ServerScriptService/*.lua`
   - Update: `require(script.Parent.ModuleName)` paths unchanged

2. **Shared Configs**: 
   - Old: `src/shared/*.lua`
   - New: `ReplicatedStorage/Shared/*.lua`
   - Update: `require(ReplicatedStorage.Shared.ConfigName)` unchanged

3. **Client Scripts**: 
   - Old: `src/client/*.lua`
   - New: `StarterPlayer/StarterPlayerScripts/*.lua`
   - Update: Paths remain compatible

4. **UI Scripts**: 
   - Old: `src/client/Modules/UI/*.lua`
   - New: `StarterGui/*.lua`
   - Update: Now LocalScripts in StarterGui (as documented)

### Require Path Changes:

**No changes needed!** The internal require paths remain the same:
```lua
-- Server requiring shared config (unchanged)
local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)

-- Server requiring sibling module (unchanged)
local PlayerManager = require(script.Parent.PlayerManager)

-- Client requiring shared config (unchanged)
local FPSConfig = require(game.ReplicatedStorage.Shared.FPSConfig)
```

## Next Steps

### For Installation:
1. See updated [INSTALLATION.md](INSTALLATION.md) for new setup instructions
2. Use [ASSET_PLACEHOLDERS.md](ASSET_PLACEHOLDERS.md) for asset creation guide
3. Refer to [docs/STRUCTURE.md](docs/STRUCTURE.md) for architecture overview

### For Development:
1. Use new directory structure for all changes
2. Never modify files in `Archive/` directory
3. Follow Roblox service naming conventions
4. Add new files to appropriate service directories

## Related Documentation

- [INSTALLATION.md](INSTALLATION.md) - Updated installation guide
- [ASSET_PLACEHOLDERS.md](ASSET_PLACEHOLDERS.md) - Asset requirements and specifications
- [docs/STRUCTURE.md](docs/STRUCTURE.md) - Project structure documentation
- [REMOTE_EVENTS.md](REMOTE_EVENTS.md) - RemoteEvent reference
- [Archive/Legacy/Code/_ARCHIVE_README.md](Archive/Legacy/Code/_ARCHIVE_README.md) - Archived code info

## Questions?

If you have questions about the restructure or need help migrating:
1. Check the updated documentation files
2. Review placeholder README files in each directory
3. Open an issue on GitHub with the "restructure" label
