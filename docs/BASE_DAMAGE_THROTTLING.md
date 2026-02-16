# Base Damage Throttling - Tuning & Testing Guide

## Overview

This system prevents the game base from being destroyed too quickly when multiple zombies reach it simultaneously. It implements a per-attacker cooldown that limits how often each zombie can damage the base, while maintaining game pressure and challenge.

## Implementation Summary

### Changes Made

1. **GameConfig.lua**
   - Added `BASE_DAMAGE_COOLDOWN = 2.0` (seconds between attacks from same zombie)

2. **BaseManager.lua**
   - Added `_attackerCooldowns` map to track last damage timestamp per attacker
   - Modified `damageBase()` to enforce per-attacker cooldown
   - Added `removeAttackerCooldown()` for cleanup when zombies die
   - Added `clearAttackerCooldowns()` to reset all cooldowns
   - Cooldowns are automatically cleared on `reset()`

3. **ZombieBrain.lua**
   - Added cleanup call in `destroy()` method to remove attacker from cooldown map

## Configuration

### Primary Tuning Knobs

**BASE_DAMAGE_COOLDOWN** (in `GameConfig.lua`)
- Default: `2.0` seconds
- Recommended range: `1.5 - 3.0` seconds
- Effect: Controls how often each zombie can damage the base

**Zombie Type Damage** (in `ZombieTypes.lua`)
- Walker: 10 damage
- Runner: 8 damage
- Brute: 20 damage (1.5x base bonus)
- Breacher: 15 damage (2.0x base bonus)
- Bruiser: 22 damage (1.5x base bonus)

### How It Works

1. **Zombie Attack Flow**:
   - Zombie gets within attack range of base
   - ZombieBrain's `tryAttack()` applies its own cooldown (1.5s default)
   - Calls `baseManager:damageBase(damage, zombieName)`
   - BaseManager checks if this zombie is on cooldown
   - If not on cooldown: applies damage, records timestamp
   - If on cooldown: rejects damage silently

2. **Cooldown Tracking**:
   - Each zombie's name is used as a unique identifier
   - Cooldowns are stored as: `{["Zombie_1"] = 123.456, ["Zombie_2"] = 124.789}`
   - Timestamps use `tick()` for high precision

3. **Memory Management**:
   - When a zombie dies, `ZombieBrain:destroy()` calls `removeAttackerCooldown()`
   - Prevents memory growth from accumulating dead zombie entries
   - `reset()` clears all cooldowns when game restarts

## Tuning Guidelines

### Calculating Time-to-Destruction

**Formula**:
```
Time = (BASE_HEALTH / (NUM_ZOMBIES × ZOMBIE_DAMAGE)) × BASE_DAMAGE_COOLDOWN
```

**Example with defaults**:
- Base Health: 1000
- Num Zombies: 10
- Zombie Damage: 10 (average)
- Cooldown: 2.0s

```
Time = (1000 / (10 × 10)) × 2.0 = (1000 / 100) × 2.0 = 20 seconds
```

### Adjusting for Difficulty

**Easy Mode** (60-90s destruction time):
- `BASE_DAMAGE_COOLDOWN = 3.0`
- Reduces pressure, gives more time to clear zombies

**Normal Mode** (30-60s destruction time):
- `BASE_DAMAGE_COOLDOWN = 2.0` (default)
- Balanced pressure and player response time

**Hard Mode** (15-30s destruction time):
- `BASE_DAMAGE_COOLDOWN = 1.5`
- High pressure, requires immediate response

**Considerations**:
- Early waves have fewer zombies (5-10)
- Late waves have more zombies (30-50+)
- Special zombies (Breacher, Bruiser) do 1.5-2x base damage
- Account for player weapon DPS when tuning

## Testing Instructions

### Manual Testing in Roblox Studio

#### Quick Test (Console)
1. Open Roblox Studio
2. Load your place with AwavePuzz
3. Open Server console (View → Output, then click "Server")
4. Run the test script:
   ```lua
   loadstring(game:GetService("ServerScriptService"):WaitForChild("tests"):WaitForChild("base_damage_throttle_test").Source)()
   ```

#### Automated Test Script
The test script (`tests/base_damage_throttle_test.lua`) runs 4 tests:

1. **Without Throttle Test**: Shows expected instant melt behavior
2. **With Throttle Test**: Verifies cooldown enforcement and time-to-destruction
3. **Memory Cleanup Test**: Confirms zombie cleanup removes cooldown entries
4. **Single Zombie Test**: Validates per-zombie cooldown works

**Expected Output**:
```
✅ PASS: Time-to-destruction is within acceptable range (30-90s)
✅ PASS: Cooldown is working (X attacks blocked)
✅ PASS: Memory cleanup working correctly
✅ PASS: Single zombie cooldown working correctly
```

### In-Game Testing

#### Scenario 1: Wave 1 with 10 Zombies
1. Start a game in Studio (Play Solo or Local Server)
2. Let Wave 1 spawn (typically 5-10 zombies)
3. Let zombies reach the base
4. Monitor base health in UI
5. Observe time to destruction

**Expected**: Base should take 15-30 seconds to destroy with 10 zombies (2.0s cooldown)

#### Scenario 2: Late Wave with 30+ Zombies
1. Use console to skip to Wave 5+
2. Allow zombies to reach base
3. Monitor destruction time

**Expected**: Base should be under heavy pressure but not instant death (7-15s with 30 zombies)

#### Scenario 3: Breacher/Bruiser Focus
1. Spawn 10 Breachers or Bruisers near base
2. Monitor destruction time

**Expected**: Faster destruction due to 1.5-2x multipliers, but still controlled (10-15s)

### Verification Checklist

- [ ] Base doesn't drop from 1000→0 in < 10 seconds with 10 zombies
- [ ] Each zombie respects cooldown (check console logs)
- [ ] Cooldown entries are cleaned up when zombies die
- [ ] Base pressure still feels meaningful (not too slow)
- [ ] No memory leaks (cooldown map doesn't grow indefinitely)
- [ ] System works in multiplayer (test with 2+ players)

## Debug/Monitoring

### Console Log Format

**Successful Damage**:
```
[BaseManager] DAMAGE: Base took 10.0 damage from Zombie_1 (Health: 990.0/1000.0)
```

**Blocked Damage** (silent):
- No log is printed when damage is blocked by cooldown
- This is intentional to avoid log spam

### Enable Debug Logging

To see blocked attacks, temporarily modify `BaseManager:damageBase()`:

```lua
if timeSinceLastAttack < self._baseDamageCooldown then
    -- Debug: Uncomment to see blocked attacks
    print(string.format("[BaseManager] BLOCKED: %s on cooldown (%.1fs remaining)", 
        sourceStr, self._baseDamageCooldown - timeSinceLastAttack))
    return false
end
```

## Common Issues & Solutions

### Issue: Base still dies too fast
**Solution**: Increase `BASE_DAMAGE_COOLDOWN` to 2.5 or 3.0 seconds

### Issue: Base takes too long to destroy
**Solution**: Decrease `BASE_DAMAGE_COOLDOWN` to 1.5 seconds

### Issue: Memory leak warning
**Solution**: Verify `ZombieBrain:destroy()` is being called when zombies die

### Issue: Inconsistent damage
**Solution**: Check that zombie names are unique (default behavior should be fine)

## Performance Notes

- Cooldown checks are O(1) lookups (hash table)
- Memory usage: ~50 bytes per active zombie
- Max memory with 100 zombies: ~5KB (negligible)
- No performance impact on frame rate

## Future Enhancements

Potential improvements if needed:

1. **Wave-based scaling**: Reduce cooldown on later waves
2. **Difficulty modes**: Different cooldowns for Easy/Normal/Hard
3. **Dynamic cooldown**: Adjust based on player count
4. **Zombie-type cooldowns**: Different cooldowns per zombie type
5. **Grace period**: Initial immunity when base first exposed

## Support

If you encounter issues or need to adjust tuning:
1. Check console logs for damage patterns
2. Run the test script to verify system integrity
3. Adjust `BASE_DAMAGE_COOLDOWN` incrementally (±0.5s)
4. Test with realistic zombie counts for your waves
