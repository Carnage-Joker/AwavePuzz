# Base Damage Throttling - Quick Start Guide

## 🎯 What Was Fixed

**Problem**: Base HP dropped from 1000→0 in < 5 seconds when zombies reached it
**Solution**: Per-attacker cooldown system prevents instant melt while maintaining pressure

## ⚡ Quick Test in Roblox Studio

### Option 1: Automated Test (Recommended)
```lua
-- Copy/paste in Studio Server Command Bar:
loadstring(game:GetService("ServerScriptService"):WaitForChild("tests"):WaitForChild("base_damage_throttle_test").Source)()
```

**Expected Results**:
- ✅ Time-to-destruction: 15-30 seconds (not < 5 seconds)
- ✅ Cooldown blocks rapid attacks
- ✅ Memory cleanup works

### Option 2: Manual Test
1. Start game in Studio (Play Solo)
2. Use console to spawn 10 zombies:
   ```lua
   for i = 1, 10 do
       game:GetService("ServerScriptService"):WaitForChild("Spawner"):WaitForChild("spawnZombie")("Walker")
   end
   ```
3. Let zombies reach base
4. Watch base health bar
5. Base should last 15-30 seconds (not < 5)

## 📊 How It Works

### Before Fix
```
10 zombies × 10 attacks/sec × 10 damage = 1000 damage in 1 second
❌ Base destroyed in < 5 seconds (instant melt)
```

### After Fix
```
10 zombies × 1 attack/2sec × 10 damage = 50 damage/sec
✅ Base destroyed in ~20 seconds (controlled pressure)
```

## ⚙️ Configuration

Located in: `ReplicatedStorage/Shared/GameConfig.lua`

```lua
GameConfig.BASE_DAMAGE_COOLDOWN = 2.0  -- Seconds between attacks from same zombie
```

### Tuning Guide
- **Easy**: `3.0` seconds (base lasts 25-40s with 10 zombies)
- **Normal**: `2.0` seconds (base lasts 15-30s with 10 zombies) ← Default
- **Hard**: `1.5` seconds (base lasts 8-15s with 10 zombies)

## 🔍 What Changed

### Files Modified
1. **GameConfig.lua**: Added `BASE_DAMAGE_COOLDOWN = 2.0`
2. **BaseManager.lua**: Cooldown tracking and enforcement
3. **ZombieBrain.lua**: Cleanup when zombies die

### Key Features
- ✅ Each zombie can only damage base once per cooldown period
- ✅ Multiple zombies can attack simultaneously (but each respects own cooldown)
- ✅ Automatic cleanup when zombies die (no memory leak)
- ✅ Server-authoritative (no client exploits)
- ✅ Configurable difficulty tuning

## 📈 Expected Performance

### With 10 Zombies (Average Damage: 10)
| Cooldown | Time to Destruction |
|----------|---------------------|
| 3.0s     | ~30 seconds         |
| 2.0s     | ~20 seconds         |
| 1.5s     | ~13 seconds         |

### Scaling with Zombie Count
| Zombies | Time (2.0s cooldown) |
|---------|----------------------|
| 5       | ~40 seconds          |
| 10      | ~20 seconds          |
| 20      | ~10 seconds          |
| 30      | ~7 seconds           |

## 🐛 Troubleshooting

### Base still dies too fast
- Increase `BASE_DAMAGE_COOLDOWN` to `2.5` or `3.0`
- Check if special zombies (Breacher/Bruiser) are spawning (they do 1.5-2x damage)

### Base takes too long to destroy
- Decrease `BASE_DAMAGE_COOLDOWN` to `1.5` or `1.0`
- Verify zombies are actually reaching the base

### No visible change
- Make sure you restarted the game after changing config
- Check console logs for `[BaseManager] DAMAGE:` messages
- Verify test script runs without errors

## 📝 Console Logs

**Normal damage (accepted)**:
```
[BaseManager] DAMAGE: Base took 10.0 damage from Zombie_1 (Health: 990.0/1000.0)
```

**Blocked damage** (silent, no log):
- When zombie is on cooldown, damage is silently rejected
- This is normal and prevents log spam

## 📚 Full Documentation

For detailed information, see:
- **Tuning Guide**: `docs/BASE_DAMAGE_THROTTLING.md`
- **Implementation**: `docs/IMPLEMENTATION_SUMMARY_BASE_THROTTLE.md`
- **Test Script**: `tests/base_damage_throttle_test.lua`

## ✅ Verification Checklist

Before considering this complete:
- [ ] Run automated test script (passes all 4 tests)
- [ ] Manual test with 10 zombies (base lasts 15-30s)
- [ ] Check console logs show damage being applied
- [ ] Verify no memory leaks (cooldown map doesn't grow)
- [ ] Test in multiplayer (2+ players)

## 🎮 Gameplay Impact

**Before**: Zombies reaching base = instant defeat
**After**: Zombies at base = intense pressure requiring immediate response

**Strategy**: Players must actively defend base when zombies approach, but have time to react and clear zombies before catastrophic failure.

---

## Support

If you encounter issues:
1. Check console logs for errors
2. Run the automated test script
3. Verify configuration is correct
4. Check that zombies are spawning correctly
5. Report any issues with logs and reproduction steps
