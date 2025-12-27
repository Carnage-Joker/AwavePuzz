# Testing Guide for Gameplay Fixes

This document describes how to test the fixes for the gameplay bugs in Roblox Studio.

## Prerequisites
- Open the game in Roblox Studio
- Enable "Start Server and Players" test mode (minimum 1-2 players)
- Set `GameConfig.DEBUG = true` temporarily for detailed logging

## Test 1: Ammo Cap System

### Test 1.1: Magazine and Reserve Limits
**Goal**: Verify ammo cannot exceed max values

1. Start a test server with 1 player
2. Equip the Pistol (default weapon)
3. Check initial ammo: Should be 12/96 (mag/reserve)
4. Fire all bullets until magazine is empty (0/96)
5. Reload - Magazine should refill to 12, reserve should decrease to 84
6. Open developer console (F9) and verify no errors
7. Repeat until reserve is empty (0/0)
8. Try to reload with empty reserve - should do nothing

**Expected Results:**
- Pistol max: 12 magazine, 96 reserve
- Cannot reload when reserve is 0
- Magazine never exceeds 12
- Reserve never exceeds 96

### Test 1.2: Ammo Pack Pickup with Cap
**Goal**: Verify ammo packs respect max reserve

1. Fire several shots to reduce reserve to ~60
2. Walk over an Ammo Pack
3. Check ammo - reserve should increase by 30 (to ~90)
4. Fire a few more shots, walk over another Ammo Pack
5. Check ammo - reserve should cap at 96 (not exceed)
6. Check console for debug logs (if DEBUG enabled):
   ```
   [FPSWeaponService] Ammo pickup for PlayerName: Pistol (60 -> 90, max: 96)
   ```

**Expected Results:**
- Each ammo pack adds 30 to reserve
- Reserve never exceeds 96 even with multiple pickups
- Debug logs show before/after values and max cap

### Test 1.3: Different Weapons
**Goal**: Verify each weapon has correct caps

1. Buy SMG from shop (if available) or spawn with admin command
2. Check initial ammo: Should be 30/180 (mag/reserve)
3. Fire and reload several times
4. Collect ammo packs until reserve is maxed
5. Verify reserve caps at 180

**Expected Results per weapon:**
- Pistol: 12/96
- SMG: 30/180
- Shotgun: 6/48
- Rifle: 10/60

## Test 2: Health Pack Functionality

### Test 2.1: Basic Health Restoration
**Goal**: Verify health packs heal the player

1. Start test with 1 player
2. Take damage from a zombie (should reduce health below 100)
3. Check health in HUD (should show reduced health)
4. Walk over a Health Pack
5. Check health - should increase by 50 (default HEALTH_PACK_AMOUNT)
6. Check console for debug logs (if DEBUG enabled):
   ```
   [PlayerManager] Healing PlayerName: amount=50
     Before: playerData.health=50, isAlive=true
     After: playerData.health=100 (healed 50 HP)
   ```

**Expected Results:**
- Health increases by 50 per pack
- Health never exceeds 100 (or Humanoid.MaxHealth)
- Debug logs show healing calculation

### Test 2.2: Full Health Prevention
**Goal**: Verify cannot pick up health pack at full health

1. Ensure player is at full health (100/100)
2. Walk over a Health Pack
3. Health pack should NOT be consumed
4. Health remains at 100
5. Check console - should show "already at full health"

**Expected Results:**
- Health pack not consumed when at full health
- Player sees feedback message (if UI is implemented)
- No health change

### Test 2.3: Health Sync with Humanoid
**Goal**: Verify health syncs between PlayerManager and Humanoid

1. Take damage to reduce health to 50
2. Check Humanoid.Health in console: `game.Players.LocalPlayer.Character.Humanoid.Health`
3. Pick up health pack
4. Check Humanoid.Health again - should match PlayerManager health
5. Verify no desync between internal health and Humanoid

**Expected Results:**
- PlayerData.health and Humanoid.Health stay synchronized
- Healing updates both values
- Max health clamped to Humanoid.MaxHealth

## Test 3: Scoreboard Statistics

### Test 3.1: Kill Tracking
**Goal**: Verify kills increment when zombies are killed

1. Start test with 1-2 players
2. Press TAB to open scoreboard (or wait for end-of-round)
3. Check initial kills: Should be 0
4. Kill a zombie with your weapon
5. Check scoreboard again - Kills column should increment to 1
6. Kill more zombies, verify each increments the counter

**Expected Results:**
- Kills column updates in real-time
- Each zombie kill increments by 1
- Kills attributed to correct player (LastHitBy attribute)

### Test 3.2: Component Collection
**Goal**: Verify components collected stat updates

1. Collect a cure component from the map
2. Check scoreboard - Parts column should increment by 1
3. Collect more components, verify counter increases
4. Check with multiple players - each player's count is independent

**Expected Results:**
- Parts column shows total components collected
- Updates when player collects component
- Each player tracked separately

### Test 3.3: Puzzle Solves
**Goal**: Verify puzzle completion increments stat

1. Collect 5 of one component type
2. Interact with cure station to open puzzle
3. Complete the puzzle successfully
4. Check scoreboard - Puzzles column should increment by 1
5. Solve more puzzles, verify counter increases

**Expected Results:**
- Puzzles column shows total puzzles solved
- Increments after each successful puzzle completion
- Includes component puzzles and final synthesis

### Test 3.4: Deaths and Wins
**Goal**: Verify death/win tracking

1. Let player die to zombies
2. Check scoreboard - Deaths column should increment
3. Complete a round successfully (cure to 100% or survive)
4. Check scoreboard - Wins column should increment for alive players
5. Lose a round (base destroyed)
6. Check scoreboard - all players' Losses should increment

**Expected Results:**
- Deaths increment when player dies
- Wins increment for survivors at victory
- Losses increment for dead players or all on defeat
- Stats persist across waves in same round

### Test 3.5: Multiplayer Scoreboard
**Goal**: Verify scoreboard with multiple players

1. Start test with 2-3 players
2. Each player kills zombies, collects components
3. Check scoreboard on each client
4. Verify all players see same stats
5. Verify stats update in real-time across all clients

**Expected Results:**
- All clients see synchronized stats
- Stats update when any player performs action
- Scoreboard sorted by kills (highest first)
- Local player's row is highlighted

## Test 4: Spectator Mode Exit

### Test 4.1: Death and Spectate
**Goal**: Verify player enters spectator mode on death

1. Start test with 2 players in a round
2. Player 1 takes damage and dies
3. Verify Player 1 enters spectator mode:
   - Camera switches to third-person view of Player 2
   - Spectator UI appears
   - Player 1's character is invisible
4. Press Q/E to cycle between alive players (if multiple)

**Expected Results:**
- Dead player enters spectator immediately
- Camera targets alive player
- Dead player's character invisible to all
- Can cycle between alive players

### Test 4.2: Round End → Exit Spectator
**Goal**: Verify spectator mode exits at round end

1. Continue from Test 4.1 with Player 1 spectating
2. End the round (either victory or defeat)
3. Verify when round ends (VICTORY/DEFEAT state):
   - Spectator UI disappears for Player 1
   - Camera returns to first-person for Player 1
4. Check console for SpectatorManager:endRound() log
5. Proceed to lobby/waiting state
6. Verify Player 1 can play normally in next round

**Expected Results:**
- Spectator exits when round ends
- All players restored to normal state
- No players stuck in spectator mode
- Next round starts fresh without spectator flags

### Test 4.3: Multiple Death → Round Transition
**Goal**: Verify multiple spectators reset properly

1. Start round with 3+ players
2. Let 2 players die (both enter spectator)
3. End the round (any condition)
4. Verify BOTH dead players exit spectator
5. Check that transition to lobby/waiting succeeds
6. Start new round, verify all players can play

**Expected Results:**
- All spectators exit at round end
- No spectators remain in lobby/waiting
- All players have normal controls in new round
- No "IsSpectating" attributes remain

### Test 4.4: Victory Credits → Lobby Flow
**Goal**: Verify spectator reset through full flow

1. Start and complete a successful round (cure to 100%)
2. Have at least 1 dead player (spectating)
3. Observe flow: VICTORY → Credits → SCOREBOARD → LOBBY
4. Verify dead player exits spectator before lobby
5. Check SpectatorManager:reset() is called
6. Verify player can participate in map voting

**Expected Results:**
- Credits display shows survivors
- Scoreboard shows final stats
- Spectators exit before lobby
- All players can vote on maps
- New round starts clean

## Test 5: Integration Tests

### Test 5.1: Full Round with All Systems
**Goal**: Test all systems working together

1. Start multiplayer test with 3 players
2. Fight zombies, track kills on scoreboard
3. Collect components, verify Parts counter
4. Complete puzzles, verify Puzzles counter
5. Use ammo packs and health packs as needed
6. Let 1 player die (enters spectator)
7. Continue to victory
8. Verify final scoreboard shows all stats correctly
9. Transition to lobby, verify spectator exited
10. Start new round, verify stats reset but players ready

**Expected Results:**
- All systems work together without conflicts
- Stats tracked accurately throughout
- Ammo and health systems functional
- Spectator mode works correctly
- Clean transitions between states

## Debug Logging Reference

When `GameConfig.DEBUG = true`, you should see logs like:

```lua
-- Ammo System
[FPSWeaponService] Adding 30 ammo to Pistol for PlayerName (isReserve: true)
  Before: current=12, reserve=60, max=12, maxReserve=96
  After: current=12, reserve=90
[FPSWeaponService] Ammo pickup for PlayerName: Pistol (60 -> 90, max: 96)

-- Health System
[PlayerManager] Healing PlayerName: amount=50
  Before: playerData.health=50, isAlive=true
  Humanoid health: 50 -> 100 (max: 100)
  After: playerData.health=100 (healed 50 HP)

-- Stats System
[CureService] Player PlayerName collected Chemical A
[GameManager] PlayerStats: PlayerName kills increased to 5
[PuzzleService] PlayerName solved Chemical A puzzle in 45 seconds
```

## Troubleshooting

### Ammo Not Capping
- Check FPSConfig.lua has MaxReserveAmmo defined
- Verify FPSWeaponService is enforcing caps in addAmmo()
- Check console for errors

### Health Packs Not Working
- Check PlayerManager:healPlayer() is being called
- Verify Humanoid.Health is not already at max
- Check ItemSpawner for errors in onItemCollected()

### Stats Not Updating
- Verify GameManager has references to all services
- Check WeaponService passes gameManager to constructor
- Verify LastHitBy attribute is set on zombies
- Check RemoteEvents are firing properly

### Spectator Mode Stuck
- Check SpectatorManager:reset() is called at transitions
- Verify endRound() called before SCOREBOARD state
- Check for "IsSpectating" attribute on characters
- Look for errors in SpectatorManager

## Production Checklist

Before releasing fixes:
1. ✅ Set `GameConfig.DEBUG = false`
2. ✅ Test all scenarios above
3. ✅ Test with 8 players (max server size)
4. ✅ Test round -> lobby -> round cycle multiple times
5. ✅ Verify no memory leaks (long test session)
6. ✅ Check no console errors in any scenario
7. ✅ Verify scoreboard displays correctly on all devices
8. ✅ Test ammo/health caps with all weapons
