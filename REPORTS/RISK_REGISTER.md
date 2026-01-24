# AwavePuzz - Risk Register

**Document Version:** 1.0  
**Generated:** 2026-01-24  
**Purpose:** Identify and track risks to system stability, performance, and player experience

---

## Risk Classification

### Severity Levels
- **CRITICAL:** System failure, data loss, or complete gameplay break
- **HIGH:** Major functionality impaired, significant player impact
- **MEDIUM:** Moderate issues, workarounds available
- **LOW:** Minor inconveniences, minimal impact

### Likelihood Levels
- **VERY LIKELY:** >80% chance, happens regularly
- **LIKELY:** 50-80% chance, happens occasionally
- **POSSIBLE:** 20-50% chance, might happen
- **UNLIKELY:** <20% chance, rare occurrence

### Risk Score = (Severity × Likelihood)
- **9-10:** RED - Address immediately
- **6-8:** ORANGE - Address urgently
- **3-5:** YELLOW - Monitor and plan fixes
- **1-2:** GREEN - Track but low priority

---

## Critical Risks (Score 9-10)

### RISK #1: Server Hangs on Startup ⚠️

| Property | Value |
|----------|-------|
| **Risk ID** | RS-001 |
| **Category** | Server Startup |
| **Severity** | CRITICAL (10) |
| **Likelihood** | VERY LIKELY (10) |
| **Risk Score** | 100 / 100 |
| **Status** | ACTIVE |

**Description:**  
Multiple `WaitForChild()` calls without timeouts throughout the codebase (30+ instances). If any required module is missing, the server hangs indefinitely.

**Impact:**
- Server completely unresponsive
- No error logs generated (infinite yield)
- Players unable to join
- Requires manual server restart
- Development time wasted debugging hangs

**Affected Components:**
- MainServer.lua (primary entrypoint)
- MapManager.lua
- ResourceSpawner.lua
- ItemSpawner.lua
- GameManager.lua
- All service initialization files

**Root Cause:**  
Pattern of `ReplicatedStorage:WaitForChild("Shared")` without timeout copied across codebase.

**Mitigation Strategy:**
1. Add 10-second timeout to all `WaitForChild()` calls
2. Add clear error messages when timeouts occur
3. Create lint rule to catch new `WaitForChild()` without timeout
4. Consider shared utility function for safe require with timeout

**Fix Priority:** IMMEDIATE (Phase 1)  
**Assigned To:** Development Team  
**Target Date:** Current sprint

---

### RISK #2: Zombie Spawn Positioning Failure ⚠️

| Property | Value |
|----------|-------|
| **Risk ID** | RS-002 |
| **Category** | Gameplay / Spawning |
| **Severity** | CRITICAL (10) |
| **Likelihood** | LIKELY (8) |
| **Risk Score** | 80 / 100 |
| **Status** | ACTIVE |

**Description:**  
Spawner uses fallback position `Vector3.new(0, 10, 0)` when no spawn points exist. Maps are positioned at `(5000, 0, 0)`, so zombies spawn 5000 studs away in the void.

**Impact:**
- Game completely unplayable
- Zombies never reach players
- Waves cannot progress
- Players confused (see zombies spawn far away)
- No obvious error message to developers

**Affected Components:**
- Spawner.lua (getNextSpawnPoint, getRandomSpawnPoint)
- Map loading validation
- Wave progression system

**Root Cause:**  
Hardcoded fallback position not updated when map positioning changed to (5000, 0, 0) pivot system.

**Mitigation Strategy:**
1. **Option A (Recommended):** Error loudly instead of providing bad fallback
2. **Option B:** Use map center `Vector3.new(5000, 10, 0)` as fallback
3. Add map validation check before waves start
4. Prevent wave start if spawn points < minimum threshold

**Fix Priority:** IMMEDIATE (Phase 1)  
**Assigned To:** Development Team  
**Target Date:** Current sprint

---

### RISK #3: AI System No-Target Crash ⚠️

| Property | Value |
|----------|-------|
| **Risk ID** | RS-003 |
| **Category** | AI / Gameplay |
| **Severity** | CRITICAL (10) |
| **Likelihood** | POSSIBLE (5) |
| **Risk Score** | 50 / 100 |
| **Status** | ACTIVE |

**Description:**  
If all players die/disconnect AND the base is destroyed, zombies have no valid target. Pathfinding to `nil` causes crashes or zombies standing idle indefinitely.

**Impact:**
- Server crashes (if pathfinding called with nil)
- Zombies stand idle forever (wave never completes)
- Game stuck in unwinnable state
- Wave manager never transitions
- Players forced to rejoin new server

**Affected Components:**
- TargetingService.lua (target selection)
- ZombieBrain.lua (pathfinding)
- WaveManager.lua (wave completion detection)

**Root Cause:**  
No fallback behavior when both player count = 0 and base destroyed. Edge case not considered.

**Mitigation Strategy:**
1. Add wander behavior when no targets exist
2. Force wave completion if no targets for 10+ seconds
3. Prevent base destruction if it would leave zero targets
4. Add server state check: if no targets, end game immediately

**Fix Priority:** IMMEDIATE (Phase 1)  
**Assigned To:** Development Team  
**Target Date:** Current sprint

---

## High Risks (Score 6-8)

### RISK #4: RemoteEvents Race Condition

| Property | Value |
|----------|-------|
| **Risk ID** | RS-004 |
| **Category** | Server Startup / Networking |
| **Severity** | HIGH (8) |
| **Likelihood** | LIKELY (7) |
| **Risk Score** | 56 / 100 |
| **Status** | ACTIVE |

**Description:**  
RemoteEventsBootstrap.lua and MainServer.lua run as parallel Scripts with no guaranteed order. Services may try to access RemoteEvents before they're created.

**Impact:**
- Services fail to initialize
- Missing remote event errors
- Networking broken (client-server communication fails)
- Players can't interact with game systems
- Inconsistent behavior between server restarts

**Mitigation Strategy:**
1. Convert RemoteEventsBootstrap to ModuleScript
2. Call explicitly from MainServer.lua before service creation
3. Add `WaitForChild()` guards when accessing RemoteEvents
4. Create RemoteEvents folder if it doesn't exist

**Fix Priority:** HIGH (Phase 2)  
**Target Date:** Next sprint

---

### RISK #5: Service Cleanup nil Reference Crashes

| Property | Value |
|----------|-------|
| **Risk ID** | RS-005 |
| **Category** | Player Disconnect |
| **Severity** | HIGH (8) |
| **Likelihood** | POSSIBLE (5) |
| **Risk Score** | 40 / 100 |
| **Status** | ACTIVE |

**Description:**  
`Players.PlayerRemoving` calls `fpsWeaponService:removePlayer(player)` without nil check. If service initialization failed, crashes on player disconnect.

**Impact:**
- Server crashes when players leave
- Affects all players on server
- Memory leaks (player data not cleaned up)
- Service instability

**Mitigation Strategy:**
1. Add nil guards for all service cleanup calls
2. Use pcall() wrapper for cleanup operations
3. Log cleanup failures for debugging
4. Ensure all services initialize successfully or fail gracefully

**Fix Priority:** HIGH (Phase 2)  
**Target Date:** Next sprint

---

### RISK #6: Infinite Spawn Queue Growth

| Property | Value |
|----------|-------|
| **Risk ID** | RS-006 |
| **Category** | Memory / Performance |
| **Severity** | HIGH (8) |
| **Likelihood** | UNLIKELY (4) |
| **Risk Score** | 32 / 100 |
| **Status** | ACTIVE |

**Description:**  
Spawner queue has no maximum size. If `processSpawnQueue()` stops running but `spawnWave()` continues, queue grows infinitely.

**Impact:**
- Memory leak
- Server performance degrades
- Eventually server crashes (out of memory)
- Affects all players on server

**Mitigation Strategy:**
1. Add max queue size (500 zombies)
2. Drop oldest/newest queued zombie when limit reached
3. Log warnings when queue is near capacity
4. Monitor queue size in production

**Fix Priority:** HIGH (Phase 2)  
**Target Date:** Next sprint

---

### RISK #7: Player Disconnect During Zombie Attack

| Property | Value |
|----------|-------|
| **Risk ID** | RS-007 |
| **Category** | AI / Player Interaction |
| **Severity** | HIGH (7) |
| **Likelihood** | LIKELY (7) |
| **Risk Score** | 49 / 100 |
| **Status** | ACTIVE |

**Description:**  
Zombie attack damage calculation doesn't validate Character.Parent before calling `damagePlayer()`. Player can disconnect between checks.

**Impact:**
- Server crashes on player disconnect during combat
- Affects all players on server
- Ruins gameplay experience
- Hard to reproduce in testing

**Mitigation Strategy:**
1. Add Character.Parent validation before damage
2. Use pcall() wrapper for damage calls
3. Cache player existence check
4. Add disconnect detection in combat system

**Fix Priority:** HIGH (Phase 2)  
**Target Date:** Next sprint

---

### RISK #8: ResourceSpawner Silent Failure

| Property | Value |
|----------|-------|
| **Risk ID** | RS-008 |
| **Category** | Gameplay / Resources |
| **Severity** | HIGH (8) |
| **Likelihood** | POSSIBLE (5) |
| **Risk Score** | 40 / 100 |
| **Status** | ACTIVE |

**Description:**  
ResourceSpawner silently returns nil if no spawn points configured. No resources spawn during entire game with only a warning log.

**Impact:**
- Game becomes unplayable (no ammo, health, resources)
- Players run out of resources quickly
- No obvious indication of what's wrong
- Appears as "game balance" issue, not bug

**Mitigation Strategy:**
1. Error loudly instead of warning
2. Force map validation to include resource spawns
3. Provide emergency resource spawns at base if points missing
4. Add admin UI showing resource spawn status

**Fix Priority:** HIGH (Phase 2)  
**Target Date:** Next sprint

---

## Medium Risks (Score 3-5)

### RISK #9: Map Validation Insufficient Feedback

| Property | Value |
|----------|-------|
| **Risk ID** | RS-009 |
| **Category** | Map Loading |
| **Severity** | MEDIUM (5) |
| **Likelihood** | LIKELY (7) |
| **Risk Score** | 35 / 100 |
| **Status** | ACTIVE |

**Description:**  
MapValidator fails maps with < 8 spawn points but doesn't provide clear guidance on fix.

**Impact:**
- Custom maps rejected without explanation
- Developer confusion
- Wasted time debugging map issues
- Reduced community map contributions

**Mitigation Strategy:**
1. Add detailed error messages with counts
2. Provide recommended minimums vs hard minimums
3. Create map creation guide
4. Add in-game map validation tool

**Fix Priority:** MEDIUM (Phase 3)  
**Target Date:** Future sprint

---

### RISK #10: BaseCamp Setup No Fallback Spawn

| Property | Value |
|----------|-------|
| **Risk ID** | RS-010 |
| **Category** | Player Spawn |
| **Severity** | MEDIUM (6) |
| **Likelihood** | UNLIKELY (3) |
| **Risk Score** | 18 / 100 |
| **Status** | ACTIVE |

**Description:**  
If base camp can't be built, players have no guaranteed spawn location.

**Impact:**
- Players spawn at (0, 0, 0) default spawn
- Players fall through map or spawn wrong location
- Game doesn't start properly

**Mitigation Strategy:**
1. Create emergency SpawnLocation at map center
2. Validate spawn exists before player joins
3. Force spawn creation during map load

**Fix Priority:** MEDIUM (Phase 3)  
**Target Date:** Future sprint

---

### RISK #11: CureStation RemoteEvents Race

| Property | Value |
|----------|-------|
| **Risk ID** | RS-011 |
| **Category** | Server Startup |
| **Severity** | MEDIUM (5) |
| **Likelihood** | POSSIBLE (4) |
| **Risk Score** | 20 / 100 |
| **Status** | ACTIVE |

**Description:**  
CureStationSetup assumes RemoteEvents folder exists when it runs, but it might run before RemoteEventsBootstrap.

**Impact:**
- Cure interactions don't work
- Puzzle system broken
- Players can't progress

**Mitigation Strategy:**
1. Wait for RemoteEvents folder with timeout
2. Create folder if missing
3. Verify events exist before setup

**Fix Priority:** MEDIUM (Phase 3)  
**Target Date:** Future sprint

---

### RISK #12: ItemSpawner API Inconsistency

| Property | Value |
|----------|-------|
| **Risk ID** | RS-012 |
| **Category** | Code Quality |
| **Severity** | MEDIUM (4) |
| **Likelihood** | VERY LIKELY (9) |
| **Risk Score** | 36 / 100 |
| **Status** | ACTIVE |

**Description:**  
ItemSpawner returns empty table `{}` instead of `nil` when no spawn points found, causing confusion.

**Impact:**
- Code confusion
- Difficult to debug
- Potential logic errors in calling code

**Mitigation Strategy:**
1. Standardize return values (nil for failure)
2. Document API clearly
3. Add code review checks

**Fix Priority:** MEDIUM (Phase 3)  
**Target Date:** Future sprint

---

### RISK #13: SurroundService Map Unload Race

| Property | Value |
|----------|-------|
| **Risk ID** | RS-013 |
| **Category** | AI System |
| **Severity** | MEDIUM (5) |
| **Likelihood** | UNLIKELY (3) |
| **Risk Score** | 15 / 100 |
| **Status** | ACTIVE |

**Description:**  
If map unloads during pathfinding, target positions become invalid and zombies path incorrectly.

**Impact:**
- Zombies path to wrong locations
- Zombie AI appears broken
- Wave completion issues

**Mitigation Strategy:**
1. Cache base position with expiry
2. Validate target still exists before pathfinding
3. Gracefully handle missing targets

**Fix Priority:** MEDIUM (Phase 3)  
**Target Date:** Future sprint

---

### RISK #14: ClientController Duplicate Initialization

| Property | Value |
|----------|-------|
| **Risk ID** | RS-014 |
| **Category** | Client Stability |
| **Severity** | MEDIUM (5) |
| **Likelihood** | UNLIKELY (3) |
| **Risk Score** | 15 / 100 |
| **Status** | ACTIVE |

**Description:**  
No guards prevent calling initialization functions twice, leading to duplicate event handlers.

**Impact:**
- Memory leaks
- Duplicate UI elements
- Event handlers fire multiple times
- Performance degradation

**Mitigation Strategy:**
1. Add initialization flags
2. Check flags before initialization
3. Warn on duplicate calls

**Fix Priority:** MEDIUM (Phase 3)  
**Target Date:** Future sprint

---

## Low Risks (Score 1-2)

### RISK #15: Audio Asset Loading Failures

| Property | Value |
|----------|-------|
| **Risk ID** | RS-015 |
| **Category** | Audio / Assets |
| **Severity** | LOW (2) |
| **Likelihood** | VERY LIKELY (10) |
| **Risk Score** | 20 / 100 |
| **Status** | KNOWN ISSUE |

**Description:**  
All weapon sounds use placeholder `rbxassetid://0`, which fail to load.

**Impact:**
- No weapon sounds
- Reduced player experience
- Doesn't break gameplay

**Mitigation Strategy:**
1. Add fallback behavior for missing assets
2. Log missing assets for replacement
3. Continue gameplay without sound

**Fix Priority:** LOW (Phase 4)  
**Target Date:** When assets available

---

### RISK #16: FPSConfig WaitForChild Timeout

| Property | Value |
|----------|-------|
| **Risk ID** | RS-016 |
| **Category** | Client Startup |
| **Severity** | LOW (3) |
| **Likelihood** | UNLIKELY (2) |
| **Risk Score** | 6 / 100 |
| **Status** | TRACKED |

**Description:**  
FPSConfig WaitForChild lacks explicit timeout, but parent folder already has timeout.

**Impact:**
- Client hangs if FPSConfig missing
- Protected by parent timeout

**Mitigation Strategy:**
1. Add explicit timeout for clarity
2. Part of broader WaitForChild fix

**Fix Priority:** LOW (Phase 4)  
**Target Date:** With other timeout fixes

---

## Risk Summary Dashboard

### By Severity
| Severity | Count | Total Score |
|----------|-------|-------------|
| CRITICAL | 3 | 230 |
| HIGH | 5 | 217 |
| MEDIUM | 6 | 139 |
| LOW | 2 | 26 |
| **TOTAL** | **16** | **612** |

### By Category
| Category | Risk Count | Highest Risk |
|----------|------------|--------------|
| Server Startup | 5 | RS-001 (100) |
| Gameplay | 3 | RS-002 (80) |
| AI System | 4 | RS-003 (50) |
| Player Interaction | 2 | RS-007 (49) |
| Map Loading | 2 | RS-009 (35) |
| Code Quality | 2 | RS-012 (36) |
| Assets | 1 | RS-015 (20) |

### Fix Priority Phases

**Phase 1 (IMMEDIATE - Current Sprint):**
- RS-001: WaitForChild timeouts
- RS-002: Spawner positioning
- RS-003: AI no-target handling

**Phase 2 (HIGH - Next Sprint):**
- RS-004: RemoteEvents race condition
- RS-005: Service cleanup guards
- RS-006: Spawn queue limit
- RS-007: Disconnect during combat
- RS-008: ResourceSpawner error handling

**Phase 3 (MEDIUM - Future Sprint):**
- RS-009 through RS-014: Medium priority fixes

**Phase 4 (LOW - As Time Permits):**
- RS-015, RS-016: Low priority improvements

---

## Monitoring & Mitigation

### Production Monitoring
- Track server startup failures
- Monitor spawn positioning errors
- Log AI target selection failures
- Track player disconnect crashes
- Monitor memory usage (spawn queues)

### Automated Checks
- Lint rule: WaitForChild without timeout
- CI check: Validate all maps before deployment
- Unit tests: Spawner fallback behavior
- Integration tests: AI no-target scenarios

### Player Impact Tracking
- Monitor support tickets for spawn issues
- Track server crash frequency
- Monitor gameplay completion rates
- Survey player experience

---

**End of Risk Register**
