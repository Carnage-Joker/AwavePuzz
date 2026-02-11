# Test Plan: Game Flow and Security Hardening

This document provides manual test steps for validating the security hardening and game flow improvements in AwavePuzz.

## Prerequisites

- Roblox Studio with AwavePuzz project loaded
- 2+ test accounts (for multiplayer testing)
- `GameConfig.USE_PORTAL_MATCHMAKING` set to desired mode

## Manual Test Steps

### Test 1: Portal Matchmaking Flow

**Objective**: Verify portal matchmaking works correctly with no exploits.

**Steps**:
1. Set `GameConfig.USE_PORTAL_MATCHMAKING = true`
2. Start game in Studio (Local Server, 4+ players)
3. Pass title screen on Player 1
4. Verify Player 1 spawns in lobby with visible portals
5. Touch a portal with Player 1
6. Verify queue UI shows "1/8"
7. Join same portal with Player 2
8. Verify queue shows "2/8"
9. Wait for countdown to reach 0
10. Verify match launches for both players
11. Verify lobby portals remain visible (don't disappear)
12. Join Player 3 to server while match is active
13. Verify Player 3 spawns in lobby (not in active match)
14. Verify Player 3 can queue for portals

**Expected Results**:
- ✅ Portals visible and functional in lobby
- ✅ Queue count updates correctly
- ✅ Countdown starts at minPlayers (default 1)
- ✅ Match launches correctly
- ✅ Late joiners go to lobby, not match
- ✅ Portals persist during active match

**Security Checks**:
- ✅ No duplicate players in queue
- ✅ Queue count accurate
- ✅ Countdown cancels if players leave
- ✅ Max 8 players per match enforced

---

### Test 2: Weapon Firing Validation

**Objective**: Verify weapon firing exploits are prevented.

**Steps**:
1. Start a match (portal or voting mode)
2. Equip pistol on Player 1
3. Fire normally at a zombie
4. Verify hit registers correctly
5. Attempt to fire rapidly by spamming click
6. Verify fire rate is capped (no faster than allowed)
7. Deplete all ammo
8. Attempt to fire with no ammo
9. Verify shot is blocked

**Expected Results**:
- ✅ Normal shots work correctly
- ✅ Fire rate is enforced (can't spam faster than intended)
- ✅ Ammo is consumed server-side
- ✅ Can't fire without ammo
- ✅ Damage is applied correctly

**Security Checks**:
- ✅ Fire rate hard cap prevents config exploits
- ✅ Ammo cannot be bypassed
- ✅ Server-side validation blocks invalid shots
- ✅ LOS checks prevent wallhacks

---

### Test 3: Health Sync Authority

**Objective**: Verify health sync works without exploits.

**Steps**:
1. Start a match
2. Take damage from a zombie on Player 1
3. Verify health decreases correctly
4. Verify health UI updates
5. Pick up a health pack
6. Verify health increases (if alive)
7. Die (health reaches 0)
8. Verify player enters spectator mode
9. Attempt to heal while dead (if possible via item)
10. Verify healing is blocked for dead players

**Expected Results**:
- ✅ Health decreases from damage
- ✅ Health increases from healing (alive only)
- ✅ Dead players stay dead
- ✅ No health desync
- ✅ Health UI matches server state

**Security Checks**:
- ✅ Dead players cannot be healed
- ✅ Health is always clamped to valid range
- ✅ No infinite health sync loops
- ✅ Server is sole authority for health

---

### Test 4: Match Participant Isolation

**Objective**: Verify only match participants affect game logic.

**Steps**:
1. Enable portal matchmaking
2. Start a match with Player 1 and Player 2
3. Have Player 3 join server (stays in lobby)
4. Complete wave 1 in the match
5. Verify only Player 1 and Player 2 receive wave rewards
6. Have all match players die
7. Verify match ends in defeat
8. Verify Player 3 in lobby is unaffected

**Expected Results**:
- ✅ Wave rewards only go to participants
- ✅ Defeat triggered only by participant deaths
- ✅ Late joiners don't affect match logic
- ✅ Participants correctly tracked

**Security Checks**:
- ✅ SessionState correctly identifies participants
- ✅ Non-participants don't get rewards
- ✅ Non-participants don't affect win/loss

---

### Test 5: Queue Validation and Cleanup

**Objective**: Verify queue handles edge cases correctly.

**Steps**:
1. Join portal queue with Player 1
2. Leave game with Player 1 (disconnect)
3. Wait 2-3 seconds
4. Verify Player 1 is removed from queue
5. Join portal with Player 2
6. Start countdown
7. Leave portal area with Player 2 (walk away)
8. Verify countdown cancels or Player 2 is removed
9. Join 9 players to same portal
10. Verify first 8 launch, 9th remains queued

**Expected Results**:
- ✅ Disconnected players removed from queue
- ✅ Invalid players removed by periodic validation
- ✅ Countdown cancels if below threshold
- ✅ Max 8 players per match enforced
- ✅ Overflow players remain queued

**Security Checks**:
- ✅ No ghost players in queue
- ✅ Queue count always accurate
- ✅ No duplicate players
- ✅ Atomic operations prevent corruption

---

### Test 6: Lobby vs Portal Matchmaking Modes

**Objective**: Verify mutual exclusivity of voting and portal systems.

**Portal Mode (USE_PORTAL_MATCHMAKING = true)**:
1. Start game
2. Pass title screen
3. Verify lobby has visible portals
4. Verify NO voting UI appears
5. Join portal and launch match
6. Verify lobby persists during match
7. Verify portals remain functional

**Voting Mode (USE_PORTAL_MATCHMAKING = false)**:
1. Set `GameConfig.USE_PORTAL_MATCHMAKING = false`
2. Start game
3. Pass title screen
4. Wait for voting to start
5. Verify voting UI appears
6. Vote for a map
7. Verify map loads after voting
8. Verify lobby is cleaned up during map load

**Expected Results**:
- ✅ Portal mode: portals work, no voting
- ✅ Voting mode: voting works, no portals
- ✅ Systems are mutually exclusive
- ✅ No conflicts or errors

---

### Test 7: Remote Event Spam Prevention

**Objective**: Verify rate limiting prevents remote spam.

**Note**: This requires client-side modification or scripting to test properly. For basic validation:

**Steps**:
1. Rapidly spam fire button (click as fast as possible)
2. Verify fire rate is capped
3. Rapidly enter/exit portal queue
4. Verify rate limiting prevents spam
5. Check server console for security warnings

**Expected Results**:
- ✅ Fire rate limited (max 20/sec window + hard cap)
- ✅ Queue leave rate limited (0.5s)
- ✅ Security warnings appear for spam attempts
- ✅ Server doesn't crash or lag

**Security Checks**:
- ✅ Rate limiters active
- ✅ Spam attempts logged
- ✅ Server performance unaffected

---

### Test 8: Session State Consistency

**Objective**: Verify SessionState tracks player context correctly.

**Steps**:
1. Start game with debugging output enabled
2. Pass title screen on Player 1
3. Check console for "SessionState" logs
4. Join portal queue
5. Verify logs show `inQueue=true`
6. Launch match
7. Verify logs show `inMatch=true, isParticipant=true`
8. Complete match
9. Verify logs show `inMatch=false, isParticipant=false`

**Expected Results**:
- ✅ SessionState logs appear
- ✅ Context updates correctly at each stage
- ✅ All systems use SessionState for state checks
- ✅ No state drift between systems

**Security Checks**:
- ✅ Single source of truth maintained
- ✅ State transitions are atomic
- ✅ No conflicting states

---

### Test 9: Connection Cleanup

**Objective**: Verify no memory leaks from connections.

**Steps**:
1. Start game with 4 players
2. Have players join, die, respawn, and leave
3. Repeat for several rounds
4. Check server memory usage (Studio performance stats)
5. Verify no excessive memory growth

**Expected Results**:
- ✅ Memory usage stays stable
- ✅ No connection leaks
- ✅ Cleanup happens on player removal

**Security Checks**:
- ✅ All connections tracked
- ✅ All connections disconnected on cleanup
- ✅ No warnings about uncleaned connections

---

### Test 10: Edge Cases and Rollback

**Objective**: Verify system handles failures gracefully.

**Steps**:
1. Queue for a portal with invalid MapId (if possible)
2. Verify match doesn't launch
3. Verify players returned to queue
4. Verify portal unlocks
5. Force a match launch failure (e.g., delete map during countdown)
6. Verify rollback occurs correctly
7. Verify no players stuck in limbo

**Expected Results**:
- ✅ Failed launches are handled
- ✅ Rollback restores queue state
- ✅ Portals unlock after failure
- ✅ Players can re-queue

**Security Checks**:
- ✅ Atomic operations maintain consistency
- ✅ Rollback restores all state (including SessionState)
- ✅ No partial states

---

## Automated Checks (If Test Framework Available)

If you have a test framework (e.g., TestEZ), implement these automated tests:

### Test 1: SessionState API
```lua
-- Test player context tracking
local player = mockPlayer()
sessionState:initializePlayer(player)
assert(sessionState:hasPassedTitle(player) == false)

sessionState:setPassedTitle(player, true)
assert(sessionState:hasPassedTitle(player) == true)
```

### Test 2: Rate Limiting
```lua
-- Test fire rate limiting
local weaponService = WeaponService.new(...)
local player = mockPlayer()

-- Fire multiple times rapidly
for i = 1, 30 do
    weaponService:handleWeaponFire(player, validPayload)
end

-- Verify max 20 accepted (rate limit)
assert(fireCount <= 20)
```

### Test 3: Health Clamping
```lua
-- Test health authority
local playerManager = PlayerManager.getInstance()
playerManager:addPlayer(player)

-- Try to set health above max
playerManager:setHealth(player, 999999)
assert(playerManager:getHealth(player) <= GameConfig.STARTING_HEALTH)

-- Try to heal dead player
playerManager:setHealth(player, 0)
playerManager:setHealth(player, 100)
assert(playerManager:getHealth(player) == 0) -- Should stay dead
```

### Test 4: Match Participant Isolation
```lua
-- Test participant tracking
local gameManager = GameManager.new()
local participants = {player1, player2}
local nonParticipant = player3

gameManager:startMatch(participants, "TestMap", "match1")

-- Verify only participants tracked
assert(gameManager._matchParticipants[player1.UserId] == true)
assert(gameManager._matchParticipants[player2.UserId] == true)
assert(gameManager._matchParticipants[player3.UserId] == nil)
```

### Test 5: Queue Atomicity
```lua
-- Test queue operations
local portalService = PortalMatchmakingService.new(...)
portalService:registerPortal(mockPortal)

-- Add player twice (should reject second)
portalService:addPlayerToQueue("portal1", player1)
local result = portalService:addPlayerToQueue("portal1", player1)
assert(result == false) -- Duplicate rejected

-- Verify queue size is 1
assert(#portalService.portals["portal1"].queue == 1)
```

---

## Performance Validation

### Memory Leak Check
1. Run game for 30+ minutes with players joining/leaving
2. Monitor memory usage in Studio performance stats
3. Verify memory stays stable (no continuous growth)

### Server Performance Check
1. Simulate 8 players in a match
2. Have all players fire weapons continuously
3. Monitor server FPS and network stats
4. Verify no significant lag or performance degradation

---

## Done Criteria

All tests must pass with these results:

- ✅ Late joiners stay in title/lobby and do not affect active match
- ✅ Portals don't disappear in lobby when portal matchmaking is on
- ✅ Queue cannot duplicate players; countdown cancels/starts correctly
- ✅ Match is capped at 8; overflow forms later matches
- ✅ Weapon fire cannot be spammed for higher DPS; ammo cannot be bypassed
- ✅ Health sync does not loop; dead players can't be healed
- ✅ No remote duplication warnings; all remotes are owned/registered consistently
- ✅ All RBXScriptConnections are cleaned on player removal and character respawn
- ✅ SessionState provides consistent player context across all systems
- ✅ Security validations block exploit attempts

---

**Last Updated**: 2026-02-11

**Related Documents**:
- `docs/flow_and_security.md` - Architecture and security details
- `TESTING_GUIDE.md` - General testing guide
- `INSTALLATION.md` - Setup instructions
