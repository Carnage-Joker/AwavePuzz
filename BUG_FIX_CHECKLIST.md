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
  
- [ ] **BUG-007**: Fix mass event connection leak (70+ files) — ONCLIENTEVENT SWEEP COMPLETE (STATIC TEST PASS; QA PENDING)
  - Summary: Static sweep completed — all `OnClientEvent` registrations were standardized to tracked connections + `cleanup()`. Remaining leak surface is runtime-only (input/tween/heartbeat threads).
  - Files audited (high‑impact): `PuzzleUI`, `PuzzleMenuUI`, `EpilogueUI`, `FPSHUD`, `CureUI`, `PlayerHUD`, `WaveUI` (see PR for full list)
  - Fix implemented: Replaced untracked `OnClientEvent:Connect()` with stored connection objects and `cleanup()` calls; added static checks in CI (`tests/connection_leak_test.lua`).
  - Automated tests (existing/new):
    - `tests/connection_leak_test.lua` — static detection (PASS)
    - TODO: `tests/connection_leak_runtime_test.lua` — Dev Console snapshot compare (adds CI gating)
  - Manual QA steps:
    1. Join + leave (rejoin) cycle ×10 on local server
    2. Capture Dev Console memory snapshots before/after
    3. Verify memory delta < 10MB and no orphaned connections in profiler
  - Next actions / owner / estimate:
    1. Add runtime memory regression test (`tests/connection_leak_runtime_test.lua`) — owner: `@frontend` — 2h
    2. Run QA manual verification and attach results to PR — owner: QA — 1h
    3. Sweep `FPSWeaponController`, `FPSMovement`, `MapVotingUI`, `LobbyUI` for input/tween/heartbeat leaks — owner: `@frontend` — 2–4h
    4. Close BUG-007 after tests + QA signoff
  - PR checklist:
    - [ ] Add runtime test
    - [ ] Attach QA memory snapshots
    - [ ] Reviewers: `@lead-dev`, `@qa`
  - Acceptance criteria:
    - Memory increase < 10MB after 10 rejoins (Dev Console)
    - No orphaned threads/connections reported in profiler
    - `tests/connection_leak_test.lua` passes in CI
  - Status: ONGOING — awaiting runtime test + QA signoff
  - Estimate to close: 4–6 hours (including QA)
  
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
  
- [ ] **BUG-015**: Fix input connection leak (Multiple files) — IN PROGRESS
  - Summary: Many UI/input modules were updated but low‑level input handlers and legacy controllers still need auditing (cause: uncaptured `UserInputService.InputBegan` / `InputEnded` connections).
  - Files audited/fixed so far: `TouchControlsUI`, `PuzzleMenuUI`, `ShopUI`, `EpilogueUI`, `FPSMenuController` (tracked & cleaned up)
  - Remaining audit list (priority): `FPSWeaponController`, `FPSMovement`, `CureStationUI`, `CureInteractionController`, `MapVotingUI`
  - Fix pattern: store input connections in module state, expose `cleanup()` to disconnect, reattach on respawn where necessary.
  - Tests:
    - `tests/input_connection_leak_test.lua` (client-side profiler + rejoin loop) — TODO
    - Manual: 10 respawns/rejoins, verify Input handlers count stable via Dev Console
  - Next actions / owners:
    1. Audit `FPSWeaponController` & `FPSMovement` and add missing cleanup — owner: `@frontend` — 2h
    2. Add `tests/input_connection_leak_test.lua` and CI gating — owner: `@qa` — 2h
    3. QA validation (10 respawns) and close bug — owner: QA — 1h
  - PR checklist:
    - [ ] Add cleanup to all modules with input handlers
    - [ ] Add unit/manual test to `tests/`
    - [ ] Reviewer: `@lead-dev`
  - Acceptance criteria: input handler count stable after 10 respawns; no input lag accumulation in profiler

### Logic Errors
- [x] **BUG-011**: Add player validation before FireClient (Multiple services) ✅ **FIXED**
  - Implemented `RemoteEventUtil.safeFireClient()` and replaced high-impact `FireClient` usages in `GameManager`, `WeaponService`, `PlayerManager`, and `CureService`
  - Added `tests/safe_fire_client_test.lua`
  - Test: `safeFireClient` returns false for nil/disconnected players and prevents FireClient exceptions
  - **Date**: 2026-02-13
  
- [ ] **BUG-012**: Fix ammo validation ordering (WeaponService.lua:345-361)
  - Problem: Server currently decrements/accepts ammo state before performing full validation (hit validation, cooldowns, and anti-spam). Failed validations may still consume ammo.
  - Fix: Reorder server-side logic so validation (including LOS raycast, cooldown, and server-side hit confirmation) occurs BEFORE decrementing player ammo. Add unit tests that assert no ammo change on invalid shots.
  - Example change summary:
    - `if not validateShot(player, payload) then return end`
    - `playerAmmo = playerAmmo - 1` (only after validation passes)
  - Tests:
    - Add `tests/ammo_consumption_ordering_test.lua` (unit) — simulate invalid shot payloads and assert ammo unchanged
    - Manual: Attempt malformed/obstructed shot; verify client ammo not decremented and server does not award shots
  - PR checklist:
    - [ ] Unit test added (`tests/ammo_consumption_ordering_test.lua`)
    - [ ] Regression test for server-side hit validation
    - [ ] Reviewer: `@combat-dev`
  - Status: not-started → recommended next owner: `@combat-dev` — estimate: 2–3 hours

---

## 🟡 MEDIUM PRIORITY - This Release

### Race Conditions
- [ ] **BUG-016**: Fix alliance graph mutex (AllianceGraph.lua)
  - Problem: Current mutex/check-then-act pattern can corrupt `AllianceGraph` when multiple alliance requests race concurrently.
  - Fix: Implement queue-based edge addition with an atomic "processNext" worker and granular locks per-player key. Replace check-then-act with enqueue/process pattern.
  - Implementation notes:
    - Add `_edgeQueue` table and `_processing` flag to `AllianceGraph`
    - Provide `enqueueEdgeRequest(srcId, dstId)` → processed serially by `processEdgeQueue()`
    - Use defensive checks when applying changes and persist via `Graph:commit()` only after validation
  - Tests:
    - Add `tests/alliance_graph_mutex_test.lua` (simulate 50 concurrent alliance requests, verify graph integrity)
    - Manual: Stress test with multiple rapid alliance requests in Studio
  - Next actions / owner / estimate:
    - Implement queue + unit tests — owner: `@gameplay-dev` — 3–4 hours
    - CI: add stress test scenario — owner: `@qa` — 1–2 hours
  - Acceptance criteria: graph remains consistent under concurrent requests; no data races detected in stress test
  
- [ ] **BUG-024**: Fix TitleScreenUI singleton race (TitleScreenUI.lua:20-26)
  - Add atomic creation flag
  - Wait for creation to complete
  - Test: Rapid module loads don't create duplicates

### Logic Errors
- [ ] **BUG-017**: Add humanoid validation (PlayerManager.lua:114-134)
  - Problem: `PlayerManager` assumes `Character` is fully parented and `Humanoid` exists; rapid respawns can cause nil accesses.
  - Fix: Guard all Character/Humanoid access with `if character and character.Parent then` and use `FindFirstChild("Humanoid")` with timeout fallback logic. Return early if humanoid not present and retry with a short backoff where appropriate.
  - Code pattern example:
    - `local humanoid = character:FindFirstChild("Humanoid") if not humanoid then return end`
  - Tests:
    - `tests/humanoid_validation_test.lua` — simulate rapid respawns and assert no crashes
    - Manual: Rapidly toggle spawn in Studio and verify no nil-index errors in output
  - Next actions / owner / estimate: `@player-dev` — 1–2 hours
  - Acceptance criteria: No crashes or errors during 50 rapid respawns in Studio
  
- [ ] **BUG-018**: Fix inventory ledger merge (InventoryLedger.lua)
  - Problem: Ledger merge currently overwrites resource deductions instead of summing them, causing lost resources when multiple transactions apply to the same item.
  - Fix: Change merge semantics to accumulate (add/subtract) amounts for identical ledger keys; add reconciliation step to validate invariants after merge.
  - Example:
    - `ledger[key] = (ledger[key] or 0) + delta` instead of assignment
  - Tests:
    - `tests/inventory_ledger_merge_test.lua` — unit tests for concurrent merges and reconciliation
    - Manual: Simulate concurrent alliance purchases and verify total resources deducted equals expected
  - Next actions / owner / estimate: `@economy-dev` — 2–3 hours
  - Acceptance criteria: No resource loss under concurrent operations; unit tests added and passing
  
- [ ] **BUG-019**: Add spawn point validation (ItemSpawner.lua:86-102)
  - Problem: `ItemSpawner` assumes map spawn points exist; nil spawn arrays cause silent fails or nil-index errors.
  - Fix: Validate spawn-point arrays and generate safe fallback points (e.g., map center + offset grid) when none are provided. Log warnings for missing map metadata.
  - Tests:
    - `tests/item_spawner_fallback_test.lua` — assert items spawn at fallback locations when map spawn list is empty
    - Manual: Load map with missing spawn points and verify items still spawn
  - Next actions / owner / estimate: `@map-dev` — 1–2 hours
  - Acceptance criteria: Items spawn reliably even when map spawn points are absent; no runtime errors logged
  
- [ ] **BUG-020**: Fix late joiner sync (GameManager.lua:608-616)
  - Problem: Late joiners miss `waveTimeRemaining` and `serverTime` in snapshots causing incorrect timers and UI jitter.
  - Fix: Include `waveTimeRemaining`, `serverTime` (server tick), and `waveNumber` in the snapshot sent to late joiners; ensure interpolation uses serverTime offset.
  - Tests:
    - `tests/late_joiner_sync_test.lua` — simulate late join and assert UI timer matches server within 200ms
    - Manual: Join during active wave and confirm timer alignment
  - Next actions / owner / estimate: `@net-dev` — 1–2 hours
  - Acceptance criteria: Late joiner timer matches server snapshot; no desynchronization observed in 10 manual trials

### Memory Leaks
- [ ] **BUG-021**: Fix tween animation leak (Multiple UI files) — PARTIAL
  - Summary: Major hotspots fixed (cancellation and `:Cancel()` added). Remaining UIs require audit for pulsing threads and persistent tween lists.
  - Remaining priority list: `MapVotingUI`, `ScoreboardUI`, `LobbyUI`, `AchievementUI` (verify all existing fixes applied)
  - Fix pattern: store Tween/Task handles, call `:Cancel()`/`:CancelTween()` in `cleanup()`, avoid `while true` loops without `_running` guard.
  - Tests:
    - `tests/tween_leak_test.lua` — client profiler + rejoin loop to ensure no active tweens after UI destroyed
    - Manual: Open/close UI repeatedly and verify active Tween count in DevTools
  - Next actions / owner / estimate:
    1. Audit `MapVotingUI`, `ScoreboardUI`, `LobbyUI` — owner: `@ui-dev` — 2 hours
    2. Add `tests/tween_leak_test.lua` to CI — owner: `@qa` — 2 hours
  - Acceptance criteria: No active tweens after UI destroyed; profiler shows stable tween count across repeated opens/closes
  
- [ ] **BUG-022**: Fix CharacterAdded leak (Multiple client files)
  - Problem: Several client modules rely on `CharacterAdded` but do not store/disconnect connections on cleanup causing retained references after respawn.
  - Fix pattern: store `CharacterAdded` connections in module-local table, disconnect in `cleanup()` and reattach on respawn. Initialize connection tables in module `init()` to avoid first-call leaks.
  - Files to update: `PlayerHUD`, `FPSHUD`, `CureUI`, `WaveUI` (verify existing `cleanup()` actually disconnects)
  - Tests:
    - `tests/characteradded_client_leak_test.lua` — simulate 10 respawns and assert connection count stable
    - Manual: Respawn ×10 and confirm no retained Character references in profiler
  - Next actions / owner / estimate: `@frontend` — 2–3 hours
  - Acceptance criteria: No CharacterAdded reference leaks after 10 respawns; client memory stable in profiler
  
- [ ] **BUG-023**: Add remote timeout handling (Multiple UI files)
  - Problem: UI waits indefinitely for server responses; lack of timeout leads to stuck UI states.
  - Fix: Implement `RemoteEventUtil.fireWithTimeout(remoteEvent, payload, timeoutSec)` that returns success/failure and use it across high‑impact UIs (`SynthesisUI`, `ShopUI`, `CureUI`). Show friendly notification on timeout and provide retry option.
  - Tests:
    - `tests/remote_timeout_test.lua` — simulate delayed server response and assert UI shows timeout/warning
    - Manual: Force server delay and ensure UI recovers and provides retry
  - Next actions / owner / estimate: `@ui-dev` — 2–3 hours
  - Acceptance criteria: No UI lockups on delayed server response; `RemoteEventUtil.fireWithTimeout` used in all critical UI paths
  
- [ ] **BUG-025**: Fix notification loop leak (AchievementUI.lua:189)
  - Problem: Notification loop uses an unbounded `while true` with no `_running` guard, causing threads to persist after UI destruction.
  - Fix: Add `_running` flag and track spawned thread handle; set `_running = false` and cancel thread in `cleanup()`; replace `while true` with `while _running`.
  - Code pattern:
    - `local _running = true; task.spawn(function() while _running do ... end end)`
    - `function cleanup() _running = false; task.cancel(threadHandle) end`
  - Tests:
    - `tests/notification_loop_leak_test.lua` — assert no background threads after UI destroyed
    - Manual: Open/close Achievements UI ×20 and verify no thread growth in profiler
  - Next actions / owner / estimate: `@ui-dev` — 1 hour
  - Acceptance criteria: No persistent threads from AchievementUI after destruction; test added to CI

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
