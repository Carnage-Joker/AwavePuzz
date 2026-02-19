# Zombie Hit Reaction System - Manual Testing Guide

## Prerequisites
- Roblox Studio installed
- AwavePuzz project loaded
- Test in Play mode (not Edit mode) for proper server simulation

## Testing Environment Setup

1. Open Roblox Studio
2. Load the AwavePuzz place
3. Ensure you're on the branch with hit reaction changes
4. Enable server-side output viewing (View → Output)

## Test 1: Basic Hit Reactions

### Objective
Verify zombies visually react to being shot

### Steps
1. Start a game session
2. Equip the starting pistol
3. Spawn some zombies (or wait for wave 1)
4. Shoot a zombie in the torso
5. Observe the zombie's reaction

### Expected Results
- ✅ Zombie should slightly shift/flinch in the direction of the bullet
- ✅ Movement should be subtle, not comedic
- ✅ Zombie should continue moving after the reaction

### Pass Criteria
- [ ] Zombies react visibly to hits
- [ ] Reactions are in correct direction
- [ ] No excessive physics (zombie doesn't fly across map)

## Test 2: Impulse Cooldown

### Objective
Verify impulse cooldown prevents physics spam

### Steps
1. Equip a rapid-fire weapon (SMG if available)
2. Hold down fire button on a single zombie
3. Observe the reaction frequency

### Expected Results
- ✅ Zombie should NOT react to every bullet
- ✅ Reactions should be throttled (max ~8 per second)
- ✅ No physics stuttering or jittering

### Pass Criteria
- [ ] Reactions are throttled correctly
- [ ] No excessive physics spam
- [ ] Zombie movement remains smooth

## Test 3: Headshot Impact

### Objective
Verify headshots are more impactful

### Steps
1. Spawn a zombie
2. Fire several body shots (5-6)
3. Note how many shots it takes to kill
4. Spawn another zombie
5. Fire only headshots
6. Note how many shots it takes to kill

### Expected Results
- ✅ Headshots should kill faster (2.0x damage)
- ✅ Headshots should deplete stability faster (1.6x)
- ✅ Zombie should stagger sooner with headshots

### Pass Criteria
- [ ] Headshots deal more damage
- [ ] Headshots feel more impactful
- [ ] Stability depletes faster on headshots

## Test 4: Leg Slow Effect

### Objective
Verify leg shots temporarily slow zombies

### Steps
1. Spawn a zombie
2. Wait for it to start moving toward you
3. Shoot it in the leg(s)
4. Observe its movement speed

### Expected Results
- ✅ Zombie should slow down immediately after leg hit
- ✅ Slow should be noticeable (60% of normal speed)
- ✅ Speed should restore after ~0.9 seconds
- ✅ Multiple leg hits should refresh the slow duration

### Pass Criteria
- [ ] Leg shots slow zombies
- [ ] Slow is noticeable but not excessive
- [ ] Speed restores after duration

## Test 5: Stagger Mechanics

### Objective
Verify stagger triggers after stability depletion

### Steps
1. Spawn a zombie
2. Fire multiple shots into it (aim for body/head)
3. Continue shooting until it staggers
4. Observe the stagger behavior

### Expected Results
- ✅ Zombie should stop moving completely (WalkSpeed = 0)
- ✅ Stagger should last 0.25-0.35 seconds
- ✅ Stronger impulse applied during stagger
- ✅ After stagger, zombie resumes normal movement
- ✅ Next stagger requires more hits (stability restored to 55%)

### Pass Criteria
- [ ] Stagger triggers after multiple hits
- [ ] Stagger duration is brief (< 0.5s)
- [ ] Movement resumes after stagger
- [ ] Consecutive staggers require work

## Test 6: Performance with Many Zombies

### Objective
Verify system scales to 50+ zombies

### Steps
1. Enable wave spawning
2. Progress to wave 10 (spawns 50 zombies)
3. Fight the wave normally
4. Monitor FPS and server stats
5. Check for any lag or stuttering

### Expected Results
- ✅ No significant FPS drop
- ✅ No server lag or stuttering
- ✅ All zombies react appropriately to hits
- ✅ No physics explosions or runaway behavior

### Pass Criteria
- [ ] FPS remains stable (>30 FPS)
- [ ] Server performance acceptable
- [ ] No physics anomalies
- [ ] System works with 50+ zombies

## Test 7: Console Output

### Objective
Verify no errors in output

### Steps
1. Run through Tests 1-6
2. Keep Output window open
3. Look for any errors or warnings

### Expected Results
- ✅ No errors from ZombieHitReactService
- ✅ No errors from WeaponService
- ✅ No errors from Spawner
- ✅ No physics-related warnings

### Pass Criteria
- [ ] No red error messages
- [ ] No warnings about failed operations
- [ ] Clean output during combat

## Test 8: Zombie Death During Effects

### Objective
Verify cleanup when zombie dies mid-effect

### Steps
1. Spawn a zombie
2. Shoot it in the legs to apply slow
3. Kill it before slow expires
4. Repeat with stagger:
   - Shoot to deplete stability
   - Trigger stagger
   - Kill during stagger

### Expected Results
- ✅ No errors when zombie dies during leg slow
- ✅ No errors when zombie dies during stagger
- ✅ State is cleaned up properly

### Pass Criteria
- [ ] No errors on zombie death
- [ ] State cleanup works correctly
- [ ] No memory leaks visible

## Test 9: Edge Cases

### Objective
Test unusual scenarios

### Steps
1. **Already dead zombie**: 
   - Spawn zombie
   - Kill it
   - Try to shoot corpse
   
2. **Missing parts**:
   - If possible, remove a leg from zombie model
   - Try to shoot where leg should be

3. **Rapid spawn/despawn**:
   - Spawn many zombies quickly
   - Kill them all quickly
   - Check for errors

### Expected Results
- ✅ No errors when shooting dead zombies
- ✅ No errors with missing parts
- ✅ Rapid spawn/despawn handled gracefully

### Pass Criteria
- [ ] System handles edge cases
- [ ] No crashes or errors
- [ ] Graceful degradation

## Test 10: Network Ownership

### Objective
Verify server has physics authority

### Steps
1. Enable network visualization (if available)
2. Spawn zombies
3. Check network owner of zombie parts

### Expected Results
- ✅ All zombie BaseParts owned by server (nil owner)
- ✅ Client cannot manipulate zombie physics

### Pass Criteria
- [ ] SetNetworkOwner(nil) works correctly
- [ ] Server has physics authority

## Debug Mode Testing

### Objective
Test debug logging

### Steps
1. Set `DEBUG = true` in ZombieHitReactService.lua
2. Run basic combat tests
3. Observe output

### Expected Results
- ✅ Detailed logs appear for:
  - State creation/cleanup
  - Impulse application
  - Stability changes
  - Limb detection
  - Stagger triggers
  - Speed changes

### Pass Criteria
- [ ] Debug logs are informative
- [ ] No excessive spam
- [ ] Logs help with debugging

## Final Checklist

### Functionality
- [ ] Hit reactions work visually
- [ ] Impulse cooldown prevents spam
- [ ] Headshots are more impactful
- [ ] Leg shots slow zombies
- [ ] Stagger mechanics work correctly
- [ ] System scales to 50+ zombies

### Performance
- [ ] No FPS drops
- [ ] No server lag
- [ ] No physics anomalies
- [ ] Memory usage acceptable

### Stability
- [ ] No errors in console
- [ ] No crashes
- [ ] Edge cases handled
- [ ] Cleanup works properly

### Polish
- [ ] Reactions feel good
- [ ] Timing feels right
- [ ] Combat feels more satisfying

## Tuning Recommendations

If any tests fail or reactions don't feel right, adjust these constants in `ZombieHitReactService.lua`:

### If reactions are too weak:
- Increase `BASE_IMPULSE` (try 60-70)
- Increase `STAGGER_IMPULSE_MULT` (try 2.5-3.0)

### If reactions are too strong:
- Decrease `BASE_IMPULSE` (try 30-35)
- Decrease `STAGGER_IMPULSE_MULT` (try 1.5)

### If zombies stagger too often:
- Increase `STABILITY_MAX` (try 120-150)
- Decrease stability multipliers (try 1.3 for head, 1.0 for leg)

### If zombies stagger too rarely:
- Decrease `STABILITY_MAX` (try 80)
- Increase stability multipliers (try 2.0 for head, 1.3 for leg)

### If leg slow is too strong/weak:
- Adjust `LEG_SLOW_SPEED` (0.4 = slower, 0.8 = faster)
- Adjust `LEG_SLOW_DURATION` (0.6 = shorter, 1.2 = longer)

## Reporting Issues

When reporting issues, include:
1. Which test failed
2. Expected vs actual behavior
3. Any errors in output
4. Steps to reproduce
5. Current tuning values (if changed)

## Success Criteria

The implementation is considered successful if:
- ✅ All 10 tests pass
- ✅ No errors in console
- ✅ Performance is acceptable with 50+ zombies
- ✅ Combat feels more satisfying
- ✅ System is tunable and maintainable
