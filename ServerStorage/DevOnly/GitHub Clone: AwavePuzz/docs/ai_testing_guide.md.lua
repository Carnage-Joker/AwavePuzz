-- @ScriptType: Script
# Zombie AI Testing Guide

**Related Documentation:**
- [ZOMBIE_AI.md](../ZOMBIE_AI.md) - Core zombie AI behavior
- [ai_changes.md](ai_changes.md) - Advanced tactical AI details

**For complete documentation index, see [DOCUMENTATION.md](../DOCUMENTATION.md)**

---

This guide provides step-by-step instructions for testing the new tactical AI system in Roblox Studio.

## Quick Start

### 1. Enable Debug Mode
In `src/shared/GameConfig.lua`, set:
```lua
GameConfig.AI.DEBUG_MODE = true
```

This will enable visual indicators for boss auras.

### 2. Test in Roblox Studio

#### Basic Testing Setup
1. Open the game in Roblox Studio
2. Click "Test" → "Play" (or press F5)
3. Start a game/round
4. Observe zombie behavior

## Test Cases

### Test 1: Overcrowding Prevention

**Objective**: Verify zombies don't pile up on the same target

**Steps**:
1. Start a wave with 10+ zombies
2. Stand still as a player
3. Observe zombie approach

**Expected**:
- Zombies spread in rings around you (8, 15, 25 studs)
- Max ~3 zombies attack you directly
- Others spread to flanks or divert to base
- No stacking on same point

### Test 2: Surround Slots

**Objective**: Verify slot-based positioning

**Steps**:
1. Spawn multiple zombies near player
2. Observe their final positions

**Expected**:
- Zombies occupy distinct slots in rings
- Visual spreading around target
- No overlap/collision

### Test 3: Boss Aura

**Objective**: Verify boss buff effects

**Steps**:
1. Wait for a boss wave (every 5th wave) or spawn a boss manually
2. Spawn regular zombies nearby
3. Observe behavior changes

**Expected**:
- Red debug sphere appears around boss (if debug enabled)
- Zombies within 40 studs move faster
- Increased flanking behavior
- More responsive retargeting

**Validation**:
```lua
-- In server console
-- Adjust these names if your MainServer/spawner are organized differently
local serverScriptService = game:GetService("ServerScriptService")
local mainServer = serverScriptService:WaitForChild("MainServer")
local spawner = mainServer:WaitForChild("spawner")
local stats = spawner.bossAuraService:getStats()
print("Active bosses:", stats.activeBosses)
print("Affected zombies:", stats.affectedZombies)
```

### Test 4: Spitter Ranged Combat

**Objective**: Verify Spitter maintains range and fires projectiles

**Steps**:
1. Wait for wave 3+ (when Spitters spawn)
2. Approach a Spitter zombie
3. Observe its behavior

**Expected**:
- Spitter keeps 15-40 stud distance
- Yellow telegraph indicator appears before attack
- Green acid projectile fires toward player
- Spitter doesn't charge into melee
- Uses cover when available

### Test 5: Base Pressure

**Objective**: Verify dynamic base targeting

**Steps**:
1. Play through multiple waves
2. Observe zombie distribution

**Expected**:
- 20-60% of zombies target base (varies by wave)
- Higher waves = more base pressure
- When players are low HP, fewer zombies attack base
- Base gets surrounded, not pile-up attacked

**Validation**:
```lua
-- In server console
local info = spawner.aiDirector:getStateInfo()
print("Base pressure:", info.basePressurePercent * 100, "%")
print("Surge active:", info.currentSurge)
```

### Test 6: Surge System

**Objective**: Verify periodic aggression surges

**Steps**:
1. Play for 1-2 minutes
2. Watch for surge events

**Expected**:
- Surges occur every 30-60 seconds
- Console message: "[AIDirector] Surge started!"
- Temporary increase in runners/flankers
- More aggressive behavior
- Lasts 15 seconds

### Test 7: New Archetypes

#### Flanker
**Expected**: Fast zombie (speed 20), prefers side/back attacks, 90% flank chance

#### Bruiser
**Expected**: Slow tank (speed 7), targets base 80% of time, 1.5x base damage

#### Screamer
**Expected**: Emits "call" every 10 seconds, console message appears, nearby zombies buffed

#### Breacher
**Expected**: Strongly prefers base (90%), deals 2x damage to base, 0.5x damage to players

### Test 8: Performance

**Objective**: Verify stable performance with many zombies

**Steps**:
1. Play to wave 5+
2. Let zombies accumulate
3. Monitor FPS

**Expected**:
- Server FPS stays above 30 with 50+ zombies
- No lag spikes
- Smooth movement
- No memory leaks over time

**Validation**:
- Press F9 to open Developer Console
- Check "ServerScriptService" stats
- Monitor memory usage

## Debug Commands

### In Server Console

#### Get AI Director State
```lua
-- Adjust these names if your MainServer/spawner are organized differently
local serverScriptService = game:GetService("ServerScriptService")
local mainServer = serverScriptService:WaitForChild("MainServer")
local spawner = mainServer:WaitForChild("spawner")
local info = spawner.aiDirector:getStateInfo()
print("Base Pressure:", info.basePressurePercent)
print("Surge Active:", info.currentSurge)
print("Next Surge In:", info.nextSurgeIn, "seconds")
```

#### Get Boss Aura Stats
```lua
local stats = spawner.bossAuraService:getStats()
print("Active Bosses:", stats.activeBosses)
print("Affected Zombies:", stats.affectedZombies)
print("Aura Radius:", stats.auraRadius)
```

#### Count Active Zombies
```lua
print("Active zombies:", #spawner.activeZombies)
print("Queued zombies:", #spawner.spawnQueue)
```

#### Force Enable Debug Mode
```lua
spawner.bossAuraService:setDebugMode(true)
```

## Common Issues

### Issue: Zombies still pile up
**Check**:
- Is TargetingService initialized in Spawner?
- Are services being updated in Spawner:update()?
- Check console for errors

### Issue: Spitters charge into melee
**Check**:
- Verify Spitter type in ZombieTypes.lua has `AIBehavior = "ranged"`
- Check SpitterController is created in ZombieBrain.new()
- Look for errors in SpitterController

### Issue: Boss aura not working
**Check**:
- Boss has `HasAura = true` in ZombieTypes
- BossAuraService is initialized
- Debug mode enabled to see visual indicator
- Check console for boss registration messages

### Issue: No surges happening
**Check**:
- AIDirector initialized with surge timer
- Check console for surge messages
- Verify `aiDirector:initializeSurgeTimer()` called on wave 1

## Performance Tuning

If performance is poor, adjust in `GameConfig.AI`:

```lua
-- Reduce update frequency
GameConfig.AI.DEFAULT_UPDATE_JITTER = 0.5
GameConfig.AI.MAX_UPDATE_JITTER = 1.5

-- Increase cache time
GameConfig.AI.LOS_CACHE_TIME = 1.0

-- Reduce overcrowding checks
GameConfig.AI.OVERCROWD_RADIUS = 10
```

## Success Criteria

All tests should show:
- ✅ No zombie pile-ups
- ✅ Visual spreading in rings
- ✅ Boss aura effects visible
- ✅ Spitters maintain range
- ✅ Base gets attacked by distributed zombies
- ✅ Surges occur periodically
- ✅ 30+ FPS with 50 zombies
- ✅ No errors in console

## Reporting Issues

If you encounter bugs, collect:
1. Console error messages
2. Wave number when issue occurred
3. Number of active zombies
4. Specific zombie type involved
5. Screenshot if visual issue

---

**Happy Testing!** 🎮
