# Asset Placeholders Documentation

This document details all placeholder files in the repository and what assets need to be created in Roblox Studio to replace them.

## ⚠️ IMPORTANT: AssetConfig.lua - Centralized Asset ID Management

**As of the latest update, all animation asset IDs, sound IDs, and music IDs are now centralized in a single configuration file.**

**Location**: `ReplicatedStorage/Shared/AssetConfig.lua`

### Why AssetConfig.lua?

This file acts like a `.env` configuration file, allowing you to manage all asset IDs in one place:
- ✅ **Single source of truth** for all asset IDs
- ✅ **No more scattered IDs** across multiple files
- ✅ **Easy updates** during refactors or asset changes
- ✅ **Clear documentation** for each asset ID
- ✅ **Helper functions** for accessing assets programmatically

### What's Included in AssetConfig.lua?

1. **Animation Asset IDs**
   - Weapon animations (Pistol, SMG, Shotgun, Rifle)
   - Zombie animations (idle, walk, run, etc.)

2. **Sound Asset IDs**
   - Weapon fire sounds (per weapon type)
   - Weapon reload sounds (per weapon type)
   - UI/Feedback sounds (hitmarkers, empty click, kill confirm)
   - Movement sounds (footsteps on different surfaces)
   - Damage feedback sounds
   - Menu/UI navigation sounds

3. **Music Asset IDs**
   - Title theme
   - Gameplay ambient
   - Combat intense
   - Victory/Defeat music
   - Credits music

### How to Update Asset IDs

Instead of searching through multiple files during refactors, simply:

1. Open `ReplicatedStorage/Shared/AssetConfig.lua`
2. Find the asset you want to update (e.g., `Pistol fire sound`)
3. Replace the placeholder ID with your actual Roblox asset ID
4. Format: `"rbxassetid://XXXXXXXX"` where `XXXXXXXX` is your asset ID
5. Save the file - changes propagate throughout the entire game!

### Example: Updating a Weapon Fire Sound

```lua
-- In AssetConfig.lua
AssetConfig.Sounds = {
    WeaponFire = {
        Pistol = "rbxassetid://1905367471", -- <-- Update this ID
        SMG = "rbxassetid://77130830495173",
        -- ...
    },
}
```

### Files That Reference AssetConfig.lua

The following files automatically use asset IDs from AssetConfig.lua:
- `ReplicatedStorage/Shared/FPSConfig.lua` (weapon animations)
- `StarterPlayer/StarterPlayerScripts/Modules/FPSAudioController.lua` (sounds)
- `ReplicatedStorage/Shared/StoryConfig.lua` (music)

You no longer need to update these files individually when asset IDs change!

---

## Overview

The repository includes placeholder `.txt` files to represent required RemoteEvents, Animations, and Models. In Roblox Studio, these should be replaced with actual Roblox instances.

---

## RemoteEvents

**Location**: `ReplicatedStorage/RemoteEvents/`  
**Count**: 58 placeholder files  
**Type**: Should be `RemoteEvent` instances in Roblox Studio

### Purpose

RemoteEvents handle client-server communication. The game creates these automatically at runtime, but you can pre-create them in Roblox Studio for organization.

### List of Required RemoteEvents

#### Game State Events (5)
- `WaveAnnounce` - Server announces new wave starting
- `WaveUpdate` - Server sends wave progress updates
- `GameStateUpdate` - Server broadcasts overall game state
- `CureUpdate` - Server broadcasts cure progress
- `BaseHealthUpdate` - Server sends base health updates

#### Player Events (4)
- `PlayerHealthUpdate` - Server sends player health for UI
- `InventoryUpdate` - Server sends player inventory state
- `CurrencyUpdate` - Server sends player currency balance
- `WeaponLoadoutUpdate` - Server sends player weapon loadout

#### Weapon Events (5)
- `WeaponFire` - Client requests to fire weapon (C→S)
- `WeaponEquip` - Client requests to equip weapon (C→S)
- `WeaponReload` - Client requests reload (C→S)
- `WeaponHitConfirm` - Server confirms hit on target (S→C)
- `AmmoUpdate` - Server sends ammo counts to client

#### Animation Replication Events (6)
- `AnimationFire` - Client notifies fire animation (C→S)
- `AnimationSprint` - Client notifies sprint state (C→S)
- `AnimationADS` - Client notifies ADS state (C→S)
- `AnimationFireReplicate` - Server replicates fire to others (S→C)
- `AnimationSprintReplicate` - Server replicates sprint to others (S→C)
- `AnimationADSReplicate` - Server replicates ADS to others (S→C)

#### Movement Events (2)
- `SprintRequest` - Client requests sprint toggle (C→S)
- `StaminaUpdate` - Server sends stamina values (S→C)

#### Shop Events (2)
- `ShopRequest` - Client requests shop action (C→S)
- `ShopUpdate` - Server sends updated shop state (S→C)

#### Alliance Events (4)
- `RequestAlliance` - Client requests alliance (C→S)
- `RespondAlliance` - Client responds to alliance request (C→S)
- `BreakAlliance` - Client requests to break alliance (C→S)
- `AllianceUpdate` - Server broadcasts alliance changes (S→C)

#### Puzzle/Cure Events (8)
- `RequestPuzzle` - Client requests a puzzle (C→S)
- `SubmitPuzzleAnswer` - Client submits answer (C→S)
- `PuzzleUpdate` - Server sends puzzle progress (S→C)
- `PuzzleFailed` - Server notifies puzzle failure (S→C)
- `PuzzleCompleted` - Server notifies completion (S→C)
- `OpenPuzzleUI` - Server commands puzzle UI open (S→C)
- `RequestPuzzleProgress` - Client requests progress (C→S)
- `PlayerCureProgressUpdate` - Server sends cure progress (S→C)

#### Lobby/Map Events (6)
- `MapVoteStart` - Server starts map voting (S→C)
- `MapVoteUpdate` - Server broadcasts vote counts (S→C)
- `MapVoteEnd` - Server announces vote results (S→C)
- `CastMapVote` - Client casts vote (C→S)
- `LobbyStateUpdate` - Server broadcasts lobby state (S→C)
- `MapUpdate` - Server sends current map info (S→C)

#### Spectator Events (5)
- `EnterSpectatorMode` - Client requests spectator mode (C→S)
- `ExitSpectatorMode` - Client requests exit spectator (C→S)
- `SpectatorTargetUpdate` - Server sends target info (S→C)
- `SpectatorCycleTarget` - Client requests target cycle (C→S)
- `SpectatorStateUpdate` - Server updates spectator state (S→C)

#### UI Events (9)
- `ScoreboardUpdate` - Server sends scoreboard data (S→C)
- `ShowScoreboard` - Server commands show scoreboard (S→C)
- `HideScoreboard` - Server commands hide scoreboard (S→C)
- `ShowTitleScreen` - Server commands show title (S→C)
- `HideTitleScreen` - Server commands hide title (S→C)
- `TitleScreenContinue` - Client indicates ready (C→S)
- `ShowEpilogue` - Server commands show epilogue (S→C)
- `HideEpilogue` - Server commands hide epilogue (S→C)
- `EpilogueComplete` - Client indicates epilogue done (C→S)

#### Achievement Events (1)
- `AchievementUnlocked` - Server notifies achievement unlock (S→C)

### How to Create in Roblox Studio

1. Create `RemoteEvents` folder in `ReplicatedStorage` (if not exists)
2. For each placeholder `.txt` file, create a `RemoteEvent` instance
3. Name it exactly as shown (without `.txt` extension)
4. The server code will find and use these RemoteEvents

**Note**: The game automatically creates missing RemoteEvents, so this is optional but recommended for organization.

---

## Animations

**Location**: `ReplicatedStorage/Animations/Weapons/`  
**Count**: 36 placeholder files (6 animations × 5 weapon types + 6 READMEs)  
**Type**: Should be `Animation` instances with `AnimationId` properties

### Purpose

Weapon animations provide visual feedback for player actions. Each weapon needs 6 animations.

### Required Animations per Weapon

Each weapon type needs these animations:

1. **Idle** - Subtle breathing and weapon bob
   - Purpose: Default state when holding weapon
   - Duration: ~2 seconds (looped)
   - Movement: Gentle vertical bob, subtle rotation

2. **Fire** - Recoil and muzzle movement
   - Purpose: Visual feedback when shooting
   - Duration: ~0.2-0.3 seconds
   - Movement: Quick backward recoil, muzzle flash position

3. **Reload** - Magazine change sequence
   - Purpose: Shows reloading process
   - Duration: 1.5-3 seconds (varies by weapon)
   - Movement: Magazine removal, new magazine insertion

4. **Equip** - Weapon draw animation
   - Purpose: Shows weapon being equipped
   - Duration: ~0.5-0.7 seconds
   - Movement: Weapon brought into view from off-screen

5. **Sprint** - Lowered weapon while running
   - Purpose: Shows weapon lowered during sprint
   - Duration: ~0.3 seconds (transition, then looped)
   - Movement: Weapon lowered to waist/side position

6. **ADS** - Sight alignment animation
   - Purpose: Brings sights to eye level for aiming
   - Duration: ~0.2-0.3 seconds
   - Movement: Weapon raised to eye level, sight alignment

### Weapon Types

- **Pistol** - Starting weapon, quick animations
- **SMG** - Fast fire rate, minimal recoil animation
- **Shotgun** - Heavy recoil, pump action for reload
- **Rifle** - Precision weapon, steady ADS animation
- **AssaultRifle** - Burst fire, moderate recoil

### Animation Creation Guide

See [ANIMATION_CREATION_GUIDE.md](ANIMATION_CREATION_GUIDE.md) for step-by-step instructions on creating weapon animations in Roblox Studio.

### How to Create in Roblox Studio

1. Create weapon viewmodel rig (first-person arms + weapon)
2. Animate using Roblox Animation Editor
3. Publish animation to get AnimationId
4. Create folder structure: `ReplicatedStorage/Animations/Weapons/[WeaponName]/`
5. Create `Animation` instance for each animation type
6. Set `AnimationId` property to published animation asset ID
7. Name animations: `Idle`, `Fire`, `Reload`, `Equip`, `Sprint`, `ADS`

**Fallback**: The game includes procedural animation fallbacks if animations are missing.

### Animation Specifications

| Animation | Priority | Loop | Speed |
|-----------|----------|------|-------|
| Idle | Idle | ✅ Yes | 1.0 |
| Fire | Action | ❌ No | 1.5 |
| Reload | Action | ❌ No | 1.0 |
| Equip | Action | ❌ No | 1.2 |
| Sprint | Movement | ✅ Yes | 1.0 |
| ADS | Action | ❌ No | 1.3 |

---

## Models

### Zombie Models

**Location**: `ServerStorage/ZombieModels/`  
**Count**: 5 placeholder files  
**Type**: Should be R15 or R6 character Model instances

#### Required Models

1. **Walker** - Basic zombie type
   - Speed: Normal
   - Health: Base zombie health
   - Behavior: Targets nearest player or base
   - Appearance: Standard infected humanoid

2. **Runner** - Fast zombie type
   - Speed: 1.5x faster than Walker
   - Health: 0.7x Walker health
   - Behavior: Aggressively pursues players
   - Appearance: Lean, athletic build

3. **Brute** - Tank/heavy zombie type
   - Speed: 0.7x Walker speed
   - Health: 3x Walker health
   - Behavior: Slow but powerful, targets base
   - Appearance: Large, muscular build

4. **Spitter** - Ranged attack zombie
   - Speed: Same as Walker
   - Health: 0.8x Walker health
   - Behavior: Ranged acid attacks
   - Appearance: Bloated, diseased appearance

5. **Boss** - Boss zombie type
   - Speed: 0.8x Walker speed
   - Health: 10x Walker health
   - Behavior: Special abilities, aura effects
   - Appearance: Unique, imposing design

#### Model Requirements

Each zombie model must have:
- ✅ `Humanoid` instance
- ✅ `HumanoidRootPart` part
- ✅ R15 or R6 character rig structure
- ✅ Named parts matching rig requirements
- ⚠️ Recommended: Custom textures/meshes for variety
- ⚠️ Optional: Animations for attack, walk, idle

**Fallback**: The game creates basic zombie rigs procedurally if models are missing.

---

### Weapon Models

**Location**: `ServerStorage/Models/`  
**Count**: 5 placeholder files  
**Type**: Should be Tool or Model instances

#### Required Models

1. **Pistol** - Starting weapon
   - Damage: 15
   - Fire Rate: Semi-auto
   - Magazine: 12 rounds
   - Model Style: Modern semi-automatic pistol

2. **SMG** - Submachine gun
   - Damage: 10
   - Fire Rate: Full-auto, fast
   - Magazine: 30 rounds
   - Model Style: Compact SMG

3. **Shotgun** - Shotgun
   - Damage: 60 (close range)
   - Fire Rate: Slow, pump-action
   - Magazine: 6 shells
   - Model Style: Pump-action shotgun

4. **Rifle** - Precision rifle
   - Damage: 50
   - Fire Rate: Semi-auto, medium
   - Magazine: 10 rounds
   - Model Style: Marksman/sniper rifle

5. **AssaultRifle** - Assault rifle
   - Damage: 25
   - Fire Rate: Full-auto or burst
   - Magazine: 30 rounds
   - Model Style: Military assault rifle

#### Model Requirements

Each weapon model should include:
- ✅ `Handle` part for attachment to character
- ✅ `Muzzle` attachment point (for muzzle flash effects)
- ✅ `BarrelEnd` point (for raycast origin)
- ✅ `Sight` attachment point (for ADS alignment)
- ⚠️ Recommended: Custom meshes/textures
- ⚠️ Optional: Particle emitters for effects

**Fallback**: The game uses basic part-based weapons if models are missing.

---

### Other Models

**Location**: `ServerStorage/Models/`  
**Count**: 2 placeholder files

#### CureStation

- **Purpose**: Puzzle interaction station where players solve cure component puzzles
- **Requirements**:
  - Model or Part with `ProximityPrompt`
  - Interaction radius: ~10 studs
  - Visual indicator (screen, terminal, lab equipment)
  - Optional: Particle effects, sounds

#### ResourcePickup

- **Purpose**: Visual representation of cure component pickups
- **Requirements**:
  - Small model or part (~2-4 studs)
  - Distinct appearance per component type (different colors/shapes)
  - `ClickDetector` or `ProximityPrompt` for pickup
  - Optional: Glow effects, rotation animation

---

### Map Models

**Location**: `ServerStorage/Maps/`  
**Count**: 3 placeholder files  
**Type**: Should be Model instances containing full map layouts

#### Required Maps

1. **ResearchFacility** - Laboratory environment
   - Theme: Indoor facility, lab equipment
   - Size: Medium (200×200 studs)
   - Features: Corridors, rooms, central area

2. **DesertOutpost** - Outdoor desert setting
   - Theme: Military outpost in desert
   - Size: Large (300×300 studs)
   - Features: Open areas, buildings, cover

3. **UrbanRuins** - Destroyed city environment
   - Theme: Post-apocalyptic urban
   - Size: Medium-Large (250×250 studs)
   - Features: Ruined buildings, streets, debris

#### Map Requirements

Each map model must contain:
- ✅ `ZombieSpawnPoints` folder with Part instances (10-20 spawn points)
- ✅ `ResourceSpawnPoints` folder with Part instances (15-25 resource points)
- ✅ Terrain and structures
- ✅ Lighting configuration (Lighting properties)
- ⚠️ Optional: `CureStations` folder with interaction points (3-5 stations)
- ⚠️ Optional: Atmospheric effects, sound regions

**Spawn Point Guidelines**:
- Zombie spawns: Around perimeter, away from base
- Resource spawns: Distributed throughout map, varying distances from base
- Base location: Central or strategic position

**Fallback**: The game uses Workspace-based spawn points if no maps are provided.

---

## Replacing Placeholders in Roblox Studio

### General Process

1. **Identify Placeholder**: Find the `.txt` placeholder file in repo
2. **Create Instance**: In Roblox Studio, create the appropriate instance type
3. **Name Correctly**: Use exact name from placeholder (without `.txt`)
4. **Configure Properties**: Set required properties (AnimationId, etc.)
5. **Test**: Verify the asset works in-game
6. **Document**: Note any custom configurations needed

### Quick Reference Table

| Placeholder Type | Roblox Instance | Required Properties | Location |
|------------------|-----------------|---------------------|----------|
| RemoteEvent | `RemoteEvent` | None | ReplicatedStorage/RemoteEvents |
| Animation | `Animation` | `AnimationId` | ReplicatedStorage/Animations/Weapons/[Type] |
| Zombie Model | `Model` | Humanoid, HumanoidRootPart, Rig | ServerStorage/ZombieModels |
| Weapon Model | `Tool` or `Model` | Handle, Attachments | ServerStorage/Models |
| Map Model | `Model` | SpawnPoint folders | ServerStorage/Maps |

---

## Asset Creation Priority

If you're creating assets incrementally, follow this priority order:

### Phase 1: Essential (Game will run without, but limited functionality)
1. ✅ RemoteEvents - Auto-created by game
2. ✅ Basic zombie rigs - Procedurally generated if missing

### Phase 2: Core Gameplay (Improves experience significantly)
1. 🎯 Weapon models - Better visual feedback
2. 🎯 Zombie models - Varied enemy types
3. 🎯 Basic animations (Fire, Reload) - Visual polish

### Phase 3: Polish (Professional quality)
1. ⭐ All weapon animations - Full animation set
2. ⭐ CureStation models - Immersive puzzle experience
3. ⭐ ResourcePickup models - Clear visual feedback

### Phase 4: Content Expansion (Additional content)
1. 🚀 Custom maps - Variety and replayability
2. 🚀 Advanced animations - Idle, Sprint, ADS
3. 🚀 Particle effects - Enhanced visuals

---

## Additional Resources

- **[AssetConfig.lua](ReplicatedStorage/Shared/AssetConfig.lua)** - **NEW!** Centralized asset ID configuration
- [ANIMATION_CREATION_GUIDE.md](ANIMATION_CREATION_GUIDE.md) - Step-by-step animation tutorial
- [WEAPON_ANIMATIONS.md](WEAPON_ANIMATIONS.md) - Weapon animation system documentation
- [INSTALLATION.md](INSTALLATION.md) - Complete setup guide
- [docs/STRUCTURE.md](docs/STRUCTURE.md) - Project structure reference

---

## Quick Reference: AssetConfig.lua Usage

### For Developers

**Reading asset IDs in your code:**
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetConfig = require(ReplicatedStorage.Shared.AssetConfig)

-- Get a weapon animation
local pistolIdleAnim = AssetConfig:GetWeaponAnimation("Pistol", "idle")

-- Get a sound
local pistolFireSound = AssetConfig:GetSound("WeaponFire", "Pistol")

-- Get music configuration
local titleMusic = AssetConfig:GetMusic("TitleTheme")
```

**Direct access:**
```lua
local AssetConfig = require(ReplicatedStorage.Shared.AssetConfig)

-- Access weapon animations directly
local animations = AssetConfig.Animations.WeaponAnimations.Pistol

-- Access sounds directly
local fireSound = AssetConfig.Sounds.WeaponFire.Pistol

-- Access music directly
local music = AssetConfig.Music.TitleTheme
```

---

## Questions or Issues?

If you need help creating assets or have questions about specifications:
1. Check the README files in each placeholder directory
2. Review the animation and model creation guides
3. Open an issue on GitHub with the "assets" label
