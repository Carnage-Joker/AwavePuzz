# Phase 4 Testing Guide - Alliance System

## Quick Start Testing

This guide helps you test the Phase 4 Alliance System implementation in Roblox Studio.

## Prerequisites

Before testing, ensure:
- [ ] Roblox Studio installed
- [ ] Place file opened with AwavePuzz game
- [ ] All Phase 4 files properly placed:
  - `src/server/MainServer.lua`
  - `src/server/GameManager.lua`
  - `src/server/WeaponService.lua`
  - `src/server/AllianceService.lua`
  - `src/client/UI/AllianceUI.client.lua`

## Test Setup

### 1. Basic Game Setup
1. Open your AwavePuzz place in Roblox Studio
2. Verify all scripts are in correct locations
3. Start a local server test with at least 2 players

### 2. Multi-Player Test Server
```
In Roblox Studio:
1. Go to Test tab
2. Click "Start" dropdown
3. Select "2 Players" (or more for advanced testing)
4. Click "Start"
```

## Test Procedures

### Test 1: Alliance Formation ✓

**Objective**: Verify players can form alliances

**Steps**:
1. Start test server with 2 players
2. As Player 1, press `Tab` key to open Alliance UI
3. Verify Player 2 appears in the player list
4. Click "Ally" button next to Player 2's name
5. Switch to Player 2's window
6. Verify alliance request notification appears
7. Click "Accept" button
8. Switch back to Player 1
9. Verify notification "Alliance formed with Player2"

**Expected Results**:
- ✅ Alliance UI opens with Tab key
- ✅ Player list shows all other players
- ✅ Request notification appears for target player
- ✅ Accept/Decline buttons work
- ✅ Both players receive confirmation notification
- ✅ UI shows "Allied" status
- ✅ Button changes to "Betray"

### Test 2: Visual Indicators ✓

**Objective**: Verify allies have green highlights

**Steps**:
1. Continue from Test 1 (alliance formed)
2. As Player 1, look at Player 2's character
3. Verify green highlight effect visible
4. Switch to Player 2, look at Player 1
5. Verify Player 1 has green highlight
6. Move around and observe highlight persists

**Expected Results**:
- ✅ Green Highlight appears on allied character
- ✅ Highlight has green outline
- ✅ Highlight visible from all angles
- ✅ Highlight persists during movement
- ✅ Both players see highlights on each other

### Test 3: Friendly Fire Prevention ✓

**Objective**: Verify allies cannot damage each other

**Steps**:
1. Continue from Test 2 (allies with highlights)
2. As Player 1, equip a weapon
3. Aim at Player 2 (your ally)
4. Fire weapon at Player 2
5. Observe Player 2's health bar
6. Switch to Player 2's view
7. Confirm no damage taken

**Expected Results**:
- ✅ Weapon fires normally
- ✅ Raycast passes through ally
- ✅ No damage dealt to ally
- ✅ No hit markers or effects
- ✅ Ally's health unchanged
- ✅ Console shows no PvP hit log

**Note**: If you see damage, check:
- AllianceService properly initialized in MainServer
- WeaponService receives AllianceService reference
- Alliance actually formed (check UI shows "Allied")

### Test 4: PvP Between Non-Allies ✓

**Objective**: Verify non-allied players can damage each other

**Steps**:
1. Start fresh test with 3 players
2. Form alliance between Player 1 and Player 2
3. As Player 1, aim at Player 3 (NOT your ally)
4. Fire weapon at Player 3
5. Observe Player 3's health bar
6. Verify damage is dealt

**Expected Results**:
- ✅ Weapon fires normally
- ✅ Hit detection works on non-ally
- ✅ Damage dealt to non-allied player
- ✅ Hit confirmation sent to shooter
- ✅ Console logs PvP hit message
- ✅ Target's health decreases

### Test 5: Betrayal System ✓

**Objective**: Verify betrayal breaks alliance with cooldown

**Steps**:
1. Continue from Test 1 (alliance formed)
2. As Player 1, press Tab to open Alliance UI
3. Find Player 2 in list (shows "Allied")
4. Click "Betray" button
5. Observe notifications
6. Verify green highlight disappears
7. Try to shoot Player 2
8. Verify damage now dealt
9. Try to immediately re-ally with Player 2
10. Verify cooldown message appears

**Expected Results**:
- ✅ Betray button visible for allies
- ✅ Clicking Betray breaks alliance
- ✅ Both players notified of betrayal
- ✅ Green highlights removed immediately
- ✅ PvP enabled between former allies
- ✅ Weapon damage now works
- ✅ Cannot re-ally for 60 seconds
- ✅ Cooldown message displayed

### Test 6: Betrayal Cooldown ✓

**Objective**: Verify 60-second cooldown enforcement

**Steps**:
1. Continue from Test 5 (just betrayed)
2. Wait 10 seconds
3. Try to ally with Player 2 again
4. Verify cooldown message
5. Wait remaining 50 seconds (total 60s)
6. Try to ally with Player 2 again
7. Verify request goes through

**Expected Results**:
- ✅ Immediate re-ally blocked
- ✅ Cooldown message: "You must wait before forming new alliances after a betrayal"
- ✅ After 60 seconds, can request alliance
- ✅ Normal alliance flow resumes

### Test 7: Character Respawn ✓

**Objective**: Verify highlights persist after respawn

**Steps**:
1. Form alliance between two players
2. Verify green highlights visible
3. As Player 2, reset character (Home > Reset Character)
4. Wait for character to respawn
5. As Player 1, look at Player 2's new character
6. Verify green highlight reappears

**Expected Results**:
- ✅ Alliance persists after respawn
- ✅ Highlight briefly disappears during respawn
- ✅ Highlight automatically recreated on new character
- ✅ Friendly fire still prevented
- ✅ Alliance UI still shows "Allied" status

### Test 8: Alliance Request Rejection ✓

**Objective**: Verify rejecting alliance request

**Steps**:
1. Start test with 2 players (no alliance)
2. As Player 1, request alliance with Player 2
3. As Player 2, see notification popup
4. Click "Decline" button
5. Switch to Player 1
6. Verify rejection notification

**Expected Results**:
- ✅ Request notification appears for Player 2
- ✅ Decline button works
- ✅ Player 1 receives rejection notification
- ✅ No alliance formed
- ✅ No highlights appear
- ✅ Both players can still request later

### Test 9: Multiple Alliances ✓

**Objective**: Verify multiple simultaneous alliances

**Steps**:
1. Start test with 4 players
2. Player 1 allies with Player 2
3. Player 1 allies with Player 3
4. Player 1 allies with Player 4
5. Verify highlights on all allies
6. Test friendly fire with each ally
7. Verify none can damage Player 1

**Expected Results**:
- ✅ Can form multiple alliances
- ✅ All allies show green highlights
- ✅ Friendly fire prevented with all allies
- ✅ UI shows multiple "Allied" statuses
- ✅ Can betray individual alliances

### Test 10: Player Disconnect ✓

**Objective**: Verify alliance cleanup on disconnect

**Steps**:
1. Form alliance between Player 1 and Player 2
2. Close Player 2's client window (disconnect)
3. As Player 1, press Tab to check Alliance UI
4. Verify Player 2 no longer in list
5. Verify highlight cleaned up
6. Verify no errors in output console

**Expected Results**:
- ✅ Player removed from alliance list
- ✅ Highlight automatically removed
- ✅ Alliance data cleaned up
- ✅ No memory leaks
- ✅ No errors in console
- ✅ Player 1 can continue playing normally

## Common Issues and Solutions

### Issue: Alliance UI Not Opening
**Symptom**: Tab key doesn't open alliance menu
**Solution**:
- Check AllianceUI.client.lua is in StarterGui or StarterPlayer.StarterPlayerScripts
- Verify script is not disabled
- Check output console for errors

### Issue: No Green Highlights Appearing
**Symptom**: Alliances form but no visual indicator
**Solution**:
- Check Roblox Studio has Highlights enabled (not blocked)
- Verify alliance actually formed (check UI shows "Allied")
- Check output console for Highlight creation errors
- Ensure characters have loaded fully

### Issue: Friendly Fire Not Prevented
**Symptom**: Allied players can still damage each other
**Solution**:
- Verify AllianceService initialized in MainServer.lua
- Check MainServer passes allianceService to GameManager
- Verify GameManager passes allianceService to WeaponService
- Check WeaponService.new() accepts allianceService parameter
- Review handleWeaponFire() for alliance check
- Check console logs for "areAllied" function calls

### Issue: PvP Not Working
**Symptom**: Non-allied players cannot damage each other
**Solution**:
- Verify players are NOT allied (check UI)
- Check weapon system working (can damage zombies?)
- Verify damagePlayer() function exists
- Check console for PvP hit logs
- Ensure PvP damage not filtered by other systems

### Issue: Betrayal Cooldown Not Working
**Symptom**: Can immediately re-ally after betrayal
**Solution**:
- Check GameConfig.BETRAYAL_COOLDOWN is set (should be 60)
- Verify AllianceService:isOnBetrayalCooldown() function
- Check os.time() working correctly
- Review betrayalCooldowns table updates

## Performance Testing

### Stress Test: Many Alliances
1. Start test with 8 players (max)
2. Form alliances between all players
3. Verify all highlights working
4. Test friendly fire with multiple allies
5. Break several alliances
6. Monitor performance (FPS, memory)

**Expected**: Should handle smoothly with no lag

### Stress Test: Rapid Alliance Changes
1. Form alliance
2. Immediately betray
3. Wait 60 seconds
4. Immediately re-ally
5. Repeat 5-10 times
6. Verify no memory leaks or errors

**Expected**: System should handle cleanly

## Validation Checklist

After completing all tests, verify:

- [ ] Alliance UI opens with Tab key
- [ ] Can request alliances with other players
- [ ] Accept/Decline workflow works correctly
- [ ] Green highlights appear on allies
- [ ] Highlights persist across respawns
- [ ] Allied players cannot damage each other
- [ ] Non-allied players can damage each other
- [ ] Betrayal breaks alliance immediately
- [ ] 60-second cooldown enforced after betrayal
- [ ] Multiple simultaneous alliances supported
- [ ] Player disconnect cleans up properly
- [ ] No memory leaks or errors
- [ ] Performance acceptable with 8 players

## Success Criteria

Phase 4 is validated when:
- ✅ All 10 tests pass
- ✅ No errors in output console
- ✅ Smooth gameplay with alliances
- ✅ Visual indicators work correctly
- ✅ Friendly fire prevention reliable
- ✅ Betrayal system works as designed
- ✅ Performance acceptable

## Next Steps

After validation:
1. Document any issues found
2. Test with real players (not just Studio)
3. Gather feedback on alliance mechanics
4. Consider Phase 5 enhancements
5. Prepare for public testing

## Notes for Developers

### Debug Console Commands
Watch for these log messages:
- "AllianceService initialized"
- "GameManager initialized"
- "Alliance formed with [PlayerName]"
- "[PlayerName] betrayed alliance with [PlayerName]"
- "[WeaponService] PvP: [Attacker] hit [Target] for [X] damage"

### Modifying Tests
To adjust for easier testing:
- Reduce BETRAYAL_COOLDOWN in GameConfig.lua (e.g., to 10 seconds)
- Add admin commands to force alliances
- Add debug UI to show alliance state
- Add console commands for testing

### Known Limitations in Testing
- Local test server may behave slightly differently than real server
- Network latency not simulated in Studio
- Character loading timing may vary
- Some edge cases require real player testing

---

**Document Version**: 1.0  
**Last Updated**: November 19, 2025  
**Status**: Ready for Testing
