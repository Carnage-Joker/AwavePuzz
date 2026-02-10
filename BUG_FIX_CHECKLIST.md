# Bug Fix Checklist

Quick reference for developers working on bug fixes from the audit.

---

## 🔴 CRITICAL - Fix Before Production Deploy

### Security Exploits
- [ ] **BUG-004**: Fix wallhack exploit (WeaponService.lua:286-333)
  - Change dot product threshold from -0.5 to 0.7
  - Add raycast validation for line-of-sight
  - Test: Try shooting 90° off-target, should fail
  
- [ ] **BUG-009**: Fix client state authority (FPSWeaponController.lua:195-231)
  - Implement server confirmation for reload
  - Add request-response pattern with timeout
  - Test: Rapid fire exploit should be blocked

### Gameplay Breaking
- [ ] **BUG-002**: Fix wave spawning race condition (WaveManager.lua:46-69)
  - Replace mutex with queue-based spawning
  - Test: Concurrent spawns don't exceed max count
  
- [ ] **BUG-005**: Fix kill tracking after respawn (WeaponService.lua:454-491)
  - Clear "KilledByPlayer" attribute on CharacterAdded
  - Test: Kill same player 3 times, rewards granted each time
  
- [ ] **BUG-006**: Fix portal queue corruption (PortalMatchmakingService.lua:250-300)
  - Add per-portal debounce key
  - Implement atomic check-and-set
  - Test: Rapid portal touch doesn't duplicate player

### Critical Memory Leaks
- [ ] **BUG-001**: Fix infinite loop leak (FPSWeaponService.lua:419)
  - Add `_isRunning` flag to while loop
  - Implement cleanup() method
  - Test: Server restart doesn't create orphaned threads
  
- [ ] **BUG-003**: Fix CharacterAdded connection leak (GameManager.lua:556-568)
  - Initialize `_characterAddedConnections = {}` in constructor
  - Test: Memory profiler shows no leak after 100 respawns
  
- [ ] **BUG-007**: Fix mass event connection leak (70+ files)
  - Add `_connections = {}` table to each module
  - Store all OnClientEvent:Connect() calls
  - Implement cleanup() method for each module
  - Test: Memory stable after 10 rejoins
  
- [ ] **BUG-008**: Fix weapon state race condition (FPSWeaponController.lua:506-527)
  - Add weaponStats validation before using
  - Implement retry logic with 1s delay
  - Test: Late joiners can still shoot on first spawn

---

## 🟠 HIGH PRIORITY - Next Sprint

### Memory Leaks
- [ ] **BUG-010**: Fix heartbeat accumulation (Main.server.lua:220-230)
  - Disconnect old heartbeat before creating new
  - Test: Single heartbeat after server reload
  
- [ ] **BUG-013**: Fix death tracking table leak (GameManager.lua:163-164)
  - Clean up tables in onPlayerRemoving()
  - Test: Tables don't grow after 1000 player joins
  
- [ ] **BUG-014**: Fix RunService heartbeat leak (FPSWeaponController.lua:549)
  - Store heartbeat connection
  - Disconnect on character death
  - Test: Single heartbeat per alive character
  
- [ ] **BUG-015**: Fix input connection leak (Multiple files)
  - Store InputBegan/InputEnded connections
  - Disconnect on CharacterRemoving
  - Test: Input lag doesn't accumulate after 10 deaths

### Logic Errors
- [ ] **BUG-011**: Add player validation before FireClient (Multiple services)
  - Create safeFireClient() helper function
  - Check player.Parent and IsDescendantOf(game)
  - Test: No errors when player disconnects mid-update
  
- [ ] **BUG-012**: Fix ammo validation ordering (WeaponService.lua:345-361)
  - Validate shot BEFORE consuming ammo
  - Test: Failed shots don't consume ammo

---

## 🟡 MEDIUM PRIORITY - This Release

### Race Conditions
- [ ] **BUG-016**: Fix alliance graph mutex (AllianceGraph.lua)
  - Implement queue-based edge addition
  - Test: Concurrent alliance formations don't corrupt graph
  
- [ ] **BUG-024**: Fix TitleScreenUI singleton race (TitleScreenUI.lua:20-26)
  - Add atomic creation flag
  - Wait for creation to complete
  - Test: Rapid module loads don't create duplicates

### Logic Errors
- [ ] **BUG-017**: Add humanoid validation (PlayerManager.lua:114-134)
  - Check character.Parent before setup
  - Use FindFirstChild instead of WaitForChild
  - Test: Rapid respawns don't crash
  
- [ ] **BUG-018**: Fix inventory ledger merge (InventoryLedger.lua)
  - Merge deductions instead of overwriting
  - Test: Alliance resources accumulate correctly
  
- [ ] **BUG-019**: Add spawn point validation (ItemSpawner.lua:86-102)
  - Generate fallback spawn points if nil
  - Test: Items spawn even without map spawn points
  
- [ ] **BUG-020**: Fix late joiner sync (GameManager.lua:608-616)
  - Add waveTimeRemaining to snapshot
  - Include serverTime for interpolation
  - Test: Late joiners see correct wave timer

### Memory Leaks
- [ ] **BUG-021**: Fix tween animation leak (Multiple UI files)
  - Call :Cancel() on all tweens before hide
  - Test: Tweens don't run after UI destroyed
  
- [ ] **BUG-022**: Fix CharacterAdded leak (Multiple client files)
  - Store connections in module
  - Disconnect in cleanup()
  - Test: No character reference leaks after 10 respawns
  
- [ ] **BUG-023**: Add remote timeout handling (Multiple UI files)
  - Implement fireWithTimeout() helper
  - Show error notification on timeout
  - Test: User gets feedback if server hangs
  
- [ ] **BUG-025**: Fix notification loop leak (AchievementUI.lua:189)
  - Add `_running` flag to while loop
  - Cancel thread in cleanup()
  - Test: Thread stops when UI destroyed

---

## Testing Checklist

After fixing each bug, verify:

### Security Tests
- [ ] Wallhack exploit blocked (attempt 90° shot)
- [ ] Rapid fire exploit blocked (100 shots/sec)
- [ ] Client state manipulation detected
- [ ] Server-side validation working

### Memory Leak Tests
- [ ] Server memory stable after 24 hours
- [ ] Client memory stable after 50 respawns
- [ ] Client memory stable after 10 rejoins
- [ ] No orphaned threads in profiler
- [ ] Connection count doesn't grow

### Gameplay Tests
- [ ] Waves spawn correct zombie count
- [ ] Kill rewards granted every time
- [ ] Portal matchmaking works correctly
- [ ] Weapons work on first spawn
- [ ] Late joiners see correct state

### Regression Tests
- [ ] All existing tests still pass
- [ ] No new bugs introduced
- [ ] Performance hasn't degraded
- [ ] UI still responsive

---

## Code Review Checklist

When reviewing fixes, ensure:

### Memory Management
- [ ] All connections stored in table
- [ ] cleanup() method implemented
- [ ] Connections disconnected before nil
- [ ] No while true without exit condition
- [ ] Tweens cancelled before destruction

### Security
- [ ] Server validates all client input
- [ ] Dot product threshold >= 0.7
- [ ] Raycast validation for shots
- [ ] No client-side state authority
- [ ] Rate limiting on remote events

### Error Handling
- [ ] Player validation before FireClient
- [ ] Nil checks before accessing properties
- [ ] pcall() wraps potentially failing code
- [ ] Warnings logged for debugging
- [ ] User feedback on errors

### Race Conditions
- [ ] Queue-based instead of mutex
- [ ] No check-then-act patterns
- [ ] Atomic operations where needed
- [ ] Proper initialization order

---

## Performance Benchmarks

Target metrics after fixes:

### Server
- Memory growth: < 10KB/hour
- CPU usage: < 30% average
- Heartbeat connections: 1 per server
- Event connections: Stable count

### Client
- Memory growth: < 5KB/hour
- FPS: 60+ on recommended hardware
- Input lag: < 50ms
- Heartbeat connections: 1 per character

### Network
- Remote event rate: < 100/sec per player
- Validation failures: < 1% of requests
- Timeout rate: < 0.1% of requests

---

## Definition of Done

A bug is considered fixed when:

1. ✅ Code changes implemented and reviewed
2. ✅ Unit tests added and passing
3. ✅ Manual testing confirms fix
4. ✅ No regressions detected
5. ✅ Performance benchmarks met
6. ✅ Documentation updated
7. ✅ Code merged to main branch
8. ✅ Deployed to staging environment
9. ✅ Verified in production-like scenario
10. ✅ Bug tracking ticket closed

---

**Track your progress:** Mark items as you complete them.

**Questions?** See `COMPREHENSIVE_BUG_AUDIT_2026.md` for detailed analysis.
