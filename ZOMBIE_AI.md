# Zombie AI and Animation Improvements

**Date**: 2025-11-23  
**Version**: 1.1  
**Status**: Implemented

## Overview

This document describes the improvements made to the zombie AI and animation system in AwavePuzz. The zombies now have a proper attack system, can target both players and the base, and support attack animations.

## Problem Statement

Previously, zombies had limited AI capabilities:
- Zombies only walked toward the nearest player
- They dealt no actual damage - just walked into targets
- No attack animations or visual feedback
- No ability to target the base directly
- Simple MoveTo behavior with no attack mechanics

## Solution

Implemented a comprehensive attack system with the following features:

### 1. Attack System
- **Proximity-Based Attacks**: Zombies now attack when within range (6 studs by default)
- **Attack Cooldown**: 1.5 second interval between attacks to prevent spam
- **Damage Dealing**: Zombies deal configurable damage to both players and the base
- **Server-Authoritative**: All damage is handled server-side via managers

### 2. Dual Targeting System
- **Target Selection**: Zombies choose between nearest player or the base
- **Distance-Based Priority**: Always targets the closest threat
- **Fallback Logic**: If no players exist, zombies attack the base
- **Dynamic Retargeting**: Recalculates target every 1 second

### 3. Animation Support
- **Attack Animation Loader**: Automatically loads attack animations from zombie models
- **Animation Playback**: Plays attack animation during each attack
- **Animator Integration**: Creates Animator component if needed
- **Graceful Fallback**: Works without animations if none are provided

## Technical Implementation

### Files Modified

#### 1. `src/shared/GameConfig.lua`
Added zombie attack configuration parameters:

```lua
-- Zombie Settings
GameConfig.ZOMBIE_DAMAGE = 10                   -- Increased from 1
GameConfig.ZOMBIE_ATTACK_RANGE = 6              -- NEW: Attack range in studs
GameConfig.ZOMBIE_ATTACK_INTERVAL = 1.5         -- NEW: Seconds between attacks
GameConfig.ZOMBIE_REPATH_INTERVAL = 0.4         -- Path recalculation frequency (reduced from 1.0 to prevent pausing)
```

**Changes:**
- Increased ZOMBIE_DAMAGE from 1 to 10 for meaningful attacks
- Added ZOMBIE_ATTACK_RANGE configuration
- Added ZOMBIE_ATTACK_INTERVAL for attack cooldown
- Added ZOMBIE_REPATH_INTERVAL for movement updates (now 0.4s for smoother movement)
- Removed invalid `Config.Spawning` section

#### 2. `src/server/AIScripts/ZombieBrain.lua`
Major rewrite with new attack and targeting systems:

**Constructor Changes:**
```lua
function ZombieBrain.new(zombieModel, stats, baseManager, playerManager)
```
- Added `baseManager` parameter for base damage
- Added `playerManager` parameter for player damage
- Added attack cooldown tracking
- Added attack animation support
- Reads attack parameters from GameConfig

**New Functions:**

1. **`loadAttackAnimation()`**
   - Creates Animator if needed
   - Searches for "AttackAnimation" in zombie model
   - Loads animation track for playback

2. **`playAttackAnimation()`**
   - Plays the attack animation if available
   - Called during each attack

3. **`getBasePosition()`** (local function)
   - Locates the base in workspace
   - Handles both Model and Part base types
   - Returns base position or nil

4. **`getNearestPlayerPosition()`** (enhanced)
   - Now returns player object in addition to position/distance
   - Used for targeting living players only

5. **`selectBestTarget()`** (local function)
   - Compares distances to nearest player and base
   - Returns closest target position, type ("player"/"base"), and player object
   - Implements intelligent target prioritization

6. **`tryAttack()`**
   - Checks if attack cooldown is ready
   - Verifies target is within attack range
   - Plays attack animation
   - Deals damage via appropriate manager
   - Resets attack cooldown

**Updated Functions:**

1. **`update(deltaTime)`**
   - Updates attack cooldown timer
   - Calls `tryAttack()` every frame
   - Uses dual targeting system
   - Stores current target info
   - Continues movement toward target

2. **`destroy()`**
   - Stops and cleans up animation tracks
   - Clears manager references
   - Prevents memory leaks

#### 3. `src/server/Spawner.lua`
Updated to support attack system:

**Constructor Changes:**
```lua
function Spawner.new(weaponService, baseManager, playerManager)
```
- Added `baseManager` parameter
- Added `playerManager` parameter
- Stores references for passing to ZombieBrain

**Spawn Changes:**
```lua
local brain = ZombieBrain.new(zombieModel, stats, self.baseManager, self.playerManager)
```
- Passes managers to ZombieBrain for attack functionality

#### 4. `src/server/GameManager.lua`
Updated spawner initialization:

```lua
self.spawner = Spawner.new(self.weaponService, self.baseManager, self.playerManager)
```
- Passes baseManager and playerManager to Spawner
- Enables zombie attack system

### Architecture Diagram

```
┌─────────────────┐
│  GameManager    │
│                 │
│ - baseManager   │─────┐
│ - playerManager │─────┤
│ - spawner       │     │
└─────────────────┘     │
                        │
                        ▼
┌─────────────────┐   Pass managers
│    Spawner      │   to zombies
│                 │
│ - baseManager   │─────┐
│ - playerManager │─────┤
│ - zombieBrains  │     │
└─────────────────┘     │
                        │
                        ▼
┌─────────────────┐   Each zombie
│  ZombieBrain    │   has managers
│                 │
│ - baseManager   │◄────── Damage Base
│ - playerManager │◄────── Damage Players
│ - attackCooldown│
│ - attackRange   │
└─────────────────┘
        │
        │ Uses
        ▼
┌─────────────────┐
│   GameConfig    │
│                 │
│ - ATTACK_RANGE  │
│ - ATTACK_INTERVAL│
│ - ZOMBIE_DAMAGE │
└─────────────────┘
```

## Configuration Parameters

### Zombie Attack Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| `ZOMBIE_DAMAGE` | 10 | Damage dealt per attack |
| `ZOMBIE_ATTACK_RANGE` | 6 | Distance in studs at which zombies can attack |
| `ZOMBIE_ATTACK_INTERVAL` | 1.5 | Seconds between attacks (cooldown) |
| `ZOMBIE_REPATH_INTERVAL` | 0.4 | How often zombies recalculate their path (reduced from 1.0 to prevent pausing) |

These can be adjusted in `src/shared/GameConfig.lua` for balancing.

## Behavior Flow

### Every Frame (via update):

1. **Update Cooldowns**
   - Decrease attack cooldown by deltaTime
   - Decrease movement cooldown by deltaTime

2. **Try Attack** (if cooldown ready)
   - Select best target (player or base)
   - Check if target is within attack range
   - If yes:
     - Play attack animation
     - Deal damage to target
     - Reset attack cooldown
   - If no: continue to step 3

3. **Update Movement** (every 1 second)
   - Select best target (player or base)
   - Move toward target using Humanoid:MoveTo
   - Store current target information

### Target Selection Logic:

```
IF no players and no base:
    Do nothing
ELSE IF only players exist:
    Target nearest player
ELSE IF only base exists:
    Target base
ELSE:
    Calculate distance to nearest player
    Calculate distance to base
    Target whichever is closer
```

## Animation Support

### How to Add Attack Animations

To add custom attack animations to zombie models:

1. Create or obtain an attack animation
2. Upload animation to Roblox
3. Create an Animation instance in your zombie model
4. Name it "AttackAnimation"
5. Set the AnimationId property to your uploaded animation ID
6. The system will automatically find and load it

**Example structure:**
```
ZombieModel (Model)
├── HumanoidRootPart (Part)
├── Humanoid (Humanoid)
├── AttackAnimation (Animation) ← Add this
└── [other parts...]
```

**Without animations:**
- Zombies will still function normally
- They just won't play an animation during attacks
- No errors or warnings will occur

## Benefits

### Gameplay Improvements
- **More Engaging Combat**: Zombies feel more alive and threatening
- **Strategic Depth**: Players must protect the base, not just themselves
- **Better Pacing**: Attack cooldowns prevent instant kills
- **Visual Feedback**: Animations show when zombies are attacking

### Technical Improvements
- **Server-Authoritative**: All damage is validated server-side
- **Configurable**: Easy to tune for balance via GameConfig
- **Extensible**: Animation system ready for different zombie types
- **Clean Architecture**: Proper separation of concerns with managers

### Code Quality
- **Well-Documented**: Clear comments explaining functionality
- **Maintainable**: Modular design with focused functions
- **Robust**: Handles missing components gracefully
- **Performance**: Efficient cooldown system, throttled pathfinding

## Testing Recommendations

### Manual Testing Checklist

1. **Zombie vs Player**
   - [ ] Zombie walks toward player
   - [ ] Zombie stops and attacks when in range
   - [ ] Player health decreases on attack
   - [ ] Attack animation plays (if available)
   - [ ] Zombie doesn't attack during cooldown

2. **Zombie vs Base**
   - [ ] Zombie targets base when no players nearby
   - [ ] Zombie attacks base when in range
   - [ ] Base health decreases on attack
   - [ ] Multiple zombies can attack base simultaneously

3. **Target Switching**
   - [ ] Zombie switches from base to player when player is closer
   - [ ] Zombie switches from player to base when appropriate
   - [ ] Retargeting occurs smoothly

4. **Edge Cases**
   - [ ] Zombie behaves correctly when player dies
   - [ ] Zombie behaves correctly when base is destroyed
   - [ ] Multiple zombies don't interfere with each other
   - [ ] Zombie cleanup works properly on death

### Performance Testing

- Monitor with multiple zombies (10+)
- Check server FPS during active waves
- Verify no memory leaks over time
- Test with max players (8)

## Balancing Notes

### Attack Range (6 studs)
- Close enough to require proximity
- Far enough to feel natural
- Can be increased for ranged zombie types

### Attack Interval (1.5 seconds)
- Prevents instant kills
- Allows player reaction time
- Can be reduced for harder difficulty

### Attack Damage (10 HP)
- With 100 player HP, takes 10 hits to kill
- With 1000 base HP, takes 100 hits to destroy
- Can scale per zombie type (Brute = 20, Walker = 10, etc.)

### Repath Interval (0.4 seconds)
- Reduced from 1.0 to prevent pausing between path updates
- Reduces pathfinding overhead
- Still feels responsive
- Balance between performance and smoothness

## Future Enhancements

### Potential Additions
1. **Special Attacks**: Different attack types per zombie variant
2. **Attack Telegraph**: Visual warning before attack
3. **Combo System**: Multi-hit attack sequences
4. **Status Effects**: Poison, slow, etc.
5. **Smart Targeting**: Prefer injured players or damaged base
6. **Formation AI**: Coordinate attacks with other zombies
7. **Sound Effects**: Audio cues for attacks
8. **Particle Effects**: Visual effects on hit

### Performance Optimizations
1. **Spatial Partitioning**: Reduce target search overhead
2. **Animation Pooling**: Reuse animation tracks
3. **Attack Batching**: Group simultaneous attacks
4. **LOD System**: Simplify distant zombie AI

## Compatibility

### Backward Compatibility
- ✅ Works with existing zombie models
- ✅ Works without attack animations
- ✅ Maintains existing spawn system
- ✅ Compatible with all managers

### Requirements
- Roblox Luau runtime
- BaseManager for base damage
- PlayerManager for player damage
- GameConfig for configuration

## Changelog

### Version 1.1 (2025-11-23)
- ✨ Added proximity-based attack system
- ✨ Added dual targeting (players + base)
- ✨ Added attack animation support
- ✨ Added configurable attack parameters
- 🐛 Fixed zombies only walking into targets
- 🐛 Fixed lack of base targeting
- 🔧 Increased ZOMBIE_DAMAGE from 1 to 10
- 📝 Comprehensive documentation
- 🏗️ Updated Spawner and GameManager integration

### Version 1.0 (Original)
- Basic zombie AI with player targeting
- Simple MoveTo movement
- No attack system
- No base targeting

## Conclusion

These improvements transform zombies from simple walking enemies into proper threats with attack capabilities, dual targeting, and animation support. The implementation is server-authoritative, configurable, and extensible for future enhancements.

The system maintains clean architecture principles while adding significant gameplay depth. All changes are backward compatible and work with existing game systems.

---

**Implemented By**: GitHub Copilot  
**Review Status**: Ready for Testing  
**Documentation Version**: 1.0
