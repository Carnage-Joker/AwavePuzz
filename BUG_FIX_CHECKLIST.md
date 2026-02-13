# Bug Fix Checklist

Quick reference for developers working on bug fixes from the audit.

---

## 🔴 CRITICAL - Fix Before Production Deploy

### Security Exploits
- [x] **BUG-004**: Fix wallhack exploit (WeaponService.lua:286-333) ✅ **FIXED**
  - Change dot product threshold from -0.5 to 0.7
  - Add raycast validation for line-of-sight
  - Test: Try shooting 90° off-target, should fail
  - **Fix**: Changed dot product threshold from -0.5 to 0.7 (restricts to ~45-degree cone), added raycast line-of-sight validation from player's head to shot origin
  - **Date**: 2026-02-10
  
- [x] **BUG-009**: Fix client state authority (FPSWeaponController.lua:195-231) ✅ **FIXED**
  - Implement server confirmation for reload
  - Add request-response pattern with timeout
  - Test: Rapid fire exploit should be blocked
  - **Fix**: Added ReloadConfirm remote event, server sends confirmation when reload starts, client waits for confirmation with 2s timeout before setting isReloading state
  - **Date**: 2026-02-10

### Gameplay Breaking
- [x] **BUG-002**: Fix wave spawning race condition (WaveManager.lua:46-69)
  - Replace mutex with queue-based spawning
  - Test: Concurrent spawns don't exceed max count
  
- [x] **BUG-005**: Fix kill tracking after respawn (WeaponService.lua:454-491) ✅ **FIXED**
  - Clear WeaponServiceDiedConnected, LastAttackerUserId, and LastVictimUserId attributes on CharacterAdded
  - Test: Kill same player 3 times, rewards granted each time
  - **Fix**: Added cleanup in Main.server.lua CharacterAdded to clear WeaponServiceDiedConnected, LastAttackerUserId, and LastVictimUserId attributes
  - **Date**: 2026-02-10
  
- [x] **BUG-006**: Fix portal queue corruption (PortalMatchmakingService.lua:250-300) ✅ **FIXED**
  - Add per-portal debounce key
  - Implement atomic check-and-set
  - Test: Rapid portal touch doesn't duplicate player
  - **Fix**: Changed touchDebounce to use per-portal keys (userId_portalId), added atomic duplicate check in addPlayerToQueue
  - **Date**: 2026-02-10

### Critical Memory Leaks
- [x] **BUG-001**: Fix infinite loop leak (FPSWeaponService.lua:419) ✅ **FIXED**
  - Added `_isRunning` flag to the validation loop and stored task handle (`_ammoValidationTask`)
  - Implemented `cleanup()` to cancel loop and active tasks
  - Test: Verified cleanup stops validation loop and cancels reload tasks
  - **Date**: 2026-02-13
  
- [x] **BUG-003**: Fix CharacterAdded connection leak (GameManager.lua:556-568) ✅ **FIXED**
  - Now stores `CharacterAdded` connections per-player and disconnects previous connection before creating a new one
  - Cleanup removes connections on `onPlayerRemoving`
  - Test: No CharacterAdded connection growth after repeated respawns
  - **Date**: 2026-02-13
  
- [ ] **BUG-007**: Fix mass event connection leak (70+ files) — ONCLIENTEVENT SWEEP COMPLETE (QA PENDING)
  - ✅ OnClientEvent registrations audited and corrected where missing (sweep completed). Modules updated: `PuzzleUI`, `PuzzleMenuUI`, `EpilogueUI` (plus many modules already following the pattern).
  - ✅ `tests/connection_leak_test.lua` extended with a static source-inspection to catch `OnClientEvent` registrations that don't track connections.
  - Remaining scope: input/tween/thread/other non-remote connection leaks (see BUG‑015, BUG‑021).
  - Next actions:
    1. Run `tests/connection_leak_test.lua` and perform manual Dev-Console memory verification (10 rejoins)
    2. Sweep for Input/Tween/Heartbeat leaks and add missing `cleanup()` implementations
    3. Close BUG-007 after QA passes and memory is stable
  - Test: Memory increase < 10MB after 10 rejoins (manual + Dev Console)
  - Note: This item now focuses on non-remote connection types; `OnClientEvent` leak coverage is complete and gated for verification.
  
- [x] **BUG-008**: Fix weapon state race condition (FPSWeaponController.lua:506-527) ✅ **FIXED**
  - Added `weaponStats` validation and scheduled retry logic (`WEAPON_STATS_RETRY_DELAY`) for late joiners
  - Client re-applies ammo values on retry and derives `max` from `weaponStats` when needed
  - Test: Client handles AmmoUpdate when weaponStats is initially nil; retry succeeds
  - **Date**: 2026-02-13

---

## 🟠 HIGH PRIORITY - Next Sprint

### Memory Leaks
- [x] **BUG-010**: Fix heartbeat accumulation (Main.server.lua - heartbeat setup block) ✅ **FIXED**
  - Disconnect old heartbeat before creating new
  - Test: Single heartbeat after server reload
  - **Fix**: Added check to disconnect existing heartbeat connection stored in `shared` table before creating new one, uses Heartbeat's built-in deltaTime
  - **Date**: 2026-02-10
  
- [x] **BUG-013**: Fix death tracking table leak (GameManager.lua:163-164) ✅ **FIXED**
  - Clean up tables in onPlayerRemoving()
  - Test: Tables don't grow after 1000 player joins
  - **Status**: Already fixed in previous commits - all tables cleaned up properly (lines 667-687)
  - **Tables cleaned**: _deathDebounce, _deathConnections, _characterAddedConnections, _spectatorCycleCooldown, playersReadyForEpilogue, playersCompletedEpilogue, playerStats
  - **Test**: tests/death_tracking_table_leak_test.lua validates cleanup
  - **Date**: 2026-02-10
  
- [x] **BUG-014**: Fix RunService heartbeat leak (FPSWeaponController.lua:549) ✅ **FIXED**
  - Store heartbeat connection
  - Disconnect on character death
  - Test: Single heartbeat per alive character
  - **Fix**: Added heartbeatConnection variable (line 81), stored connection (line 551), added cleanup in onCharacterRemoving() (lines 640-644)
  - **Test**: tests/fps_weapon_heartbeat_leak_test.lua validates single heartbeat per character
  - **Date**: 2026-02-10
  
- [ ] **BUG-015**: Fix input connection leak (Multiple files)
  - Store InputBegan/InputEnded connections
  - Disconnect on CharacterRemoving
  - Test: Input lag doesn't accumulate after 10 deaths

### Logic Errors
- [x] **BUG-011**: Add player validation before FireClient (Multiple services) ✅ **FIXED**
  - Implemented `RemoteEventUtil.safeFireClient()` and replaced high-impact `FireClient` usages in `GameManager`, `WeaponService`, `PlayerManager`, and `CureService`
  - Added `tests/safe_fire_client_test.lua`
  - Test: `safeFireClient` returns false for nil/disconnected players and prevents FireClient exceptions
  - **Date**: 2026-02-13
  
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
- [x] Wallhack exploit blocked (attempt 90° shot) - Fix implemented with dot product threshold 0.7 and line-of-sight raycast
- [x] Rapid fire exploit blocked (100 shots/sec) - Fix implemented with server-authoritative reload confirmation
- [x] Client state manipulation detected - Reload state now requires server confirmation
- [x] Server-side validation working - Both fixes use server authority

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
