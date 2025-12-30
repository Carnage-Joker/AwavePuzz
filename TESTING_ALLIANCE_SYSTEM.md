# Testing Guide: Alliance Pooling & Betrayal System

## Prerequisites

- Roblox Studio (latest version)
- At least 2 player slots for basic testing (3+ players recommended for comprehensive testing)
- Game loaded with updated alliance system

## Test Environment Setup

### Enable Multi-Player Testing in Studio

1. Open Roblox Studio
2. Go to **Test** tab
3. Click **Players** dropdown
4. Select at least **2 Players** (or **3+ Players** for full test coverage)
5. Click **Start** to begin local server test

## Test Scenarios

### Test 1: Alliance Formation

**Objective**: Verify alliance edges are created correctly

**Steps**:
1. Start with 2 players (Player1, Player2)
2. Player1 presses LeftShift to open Alliance Menu
3. Player1 clicks "Request" next to Player2
4. Player2 receives alliance request notification
5. Player2 accepts alliance request

**Expected Results**:
- ✓ Alliance formed notification appears for both players
- ✓ Players can see each other in alliance list
- ✓ Green highlight appears around ally character
- ✓ Friendly fire OFF (players can't damage each other)

**Console Verification**:
```
[AllianceServiceV2] Initialized with networked alliance pools
Player1 requested alliance with Player2
Player2 accepted alliance with Player1
```

### Test 2: Snapshot Creation

**Objective**: Verify snapshots capture pool state correctly

**Steps**:
1. Form alliance between Player1 and Player2
2. Both players collect resources/currency
3. Give Player1: 500 currency, 1 SMG weapon
4. Give Player2: 300 currency, 2 cure components
5. Player1 breaks alliance with Player2 (initiates betrayal)

**Expected Results**:
- ✓ Snapshots created at betrayal start
- ✓ Snapshot includes both players (component members)
- ✓ Snapshot captures correct totals (800 currency, 1 weapon, 2 components)

**Console Verification**:
```
[BetrayalService] Player1 betrayed Player2 - 30s window started
[PoolCalculator] Snapshot created: 2 members, 800 currency total
```

### Test 3: Outcome 1 - Successful Betrayal

**Objective**: Verify 75% pooled transfer on betrayer kill

**Setup**:
- Player1: 600 currency, SMG weapon
- Player2: 400 currency, Shotgun weapon
- Pool Total: 1000 currency, 2 weapons

**Steps**:
1. Player1 breaks alliance with Player2
2. Within 30 seconds, Player1 kills Player2

**Expected Results**:
- ✓ Player1 receives 75% of pooled resources
- ✓ Currency: Player1 gets +750 (75% of 1000)
- ✓ Weapons: Shotgun transferred (highest value)
- ✓ Notification: "Betrayal successful! You claimed 75% of their pool!"

**Console Verification**:
```
[BetrayalService] OUTCOME 1: Player1 killed Player2 - successful betrayal
[InventoryLedger] Transaction committed successfully
```

### Test 4: Outcome 2 - Failed Betrayal

**Objective**: Verify 75% pooled transfer on victim kill (mirrored)

**Setup**:
- Player1 (betrayer): 700 currency, Rifle weapon
- Player2 (victim): 300 currency, Pistol weapon
- Pool Total: 1000 currency, 2 weapons

**Steps**:
1. Player1 breaks alliance with Player2
2. Within 30 seconds, Player2 kills Player1

**Expected Results**:
- ✓ Player2 receives 75% of pooled resources
- ✓ Currency: Player2 gets +750 (75% of 1000)
- ✓ Weapons: Rifle transferred (highest value)
- ✓ Notification: "You defeated betrayer Player1 and claimed 75% of their pool!"

**Console Verification**:
```
[BetrayalService] OUTCOME 2: Player2 killed betrayer Player1 - failed betrayal
[InventoryLedger] Transaction committed successfully
```

### Test 5: Outcome 3 - Stalemate

**Objective**: Verify 100% personal transfer + Traitor flag

**Setup**:
- Player1 (betrayer): 500 personal currency, SMG weapon, 2 components
- Player2 (victim): 300 personal currency

**Steps**:
1. Player1 breaks alliance with Player2
2. Wait 30 seconds without either player killing the other
3. Window expires

**Expected Results**:
- ✓ Player2 receives 100% of Player1's PERSONAL inventory (not pooled)
- ✓ Currency: Player2 gets +500
- ✓ Weapons: SMG transferred
- ✓ Components: 2 components transferred
- ✓ Player1 marked as Traitor (cannot form alliances)
- ✓ All Player1's remaining alliances severed
- ✓ Notification to Player1: "Stalemate! You are marked as a Traitor."

**Console Verification**:
```
[BetrayalService] OUTCOME 3: Stalemate between Player1 and Player2
[BetrayalService] Player1 marked as traitor
```

### Test 6: Traitor Cannot Form Alliances

**Objective**: Verify traitor flag prevents alliance formation

**Setup**:
- Player1 marked as traitor from previous stalemate
- Player3 available for alliance

**Steps**:
1. Player1 tries to request alliance with Player3

**Expected Results**:
- ✓ Alliance request blocked
- ✓ Notification: "Traitors cannot form alliances"
- ✓ Player1 remains isolated

### Test 7: Disconnect During Betrayal (Betrayer)

**Objective**: Verify disconnect treated as death (Outcome 2)

**Setup**:
- Player1 betrays Player2
- Window active (within 30s)

**Steps**:
1. Player1 disconnects (close their test window)

**Expected Results**:
- ✓ System treats as if Player1 died
- ✓ Outcome 2 applied (Player2 wins)
- ✓ Player2 receives 75% of betrayer's pool

**Console Verification**:
```
[BetrayalService] Betrayer Player1 disconnected - applying Outcome 2
```

### Test 8: Disconnect During Betrayal (Victim)

**Objective**: Verify disconnect treated as death (Outcome 1)

**Setup**:
- Player1 betrays Player2
- Window active (within 30s)

**Steps**:
1. Player2 disconnects

**Expected Results**:
- ✓ System treats as if Player2 died
- ✓ Outcome 1 applied (Player1 wins)
- ✓ Player1 receives 75% of victim's pool

**Console Verification**:
```
[BetrayalService] Victim Player2 disconnected - applying Outcome 1
```

### Test 9: Friendly Fire - Direct vs Indirect Allies

**Objective**: Verify only direct allies protected

**Setup**:
- Player1 allied with Player2
- Player2 allied with Player3
- Player1 NOT directly allied with Player3 (indirect ally)

**Steps**:
1. Player1 shoots Player2
2. Player1 shoots Player3

**Expected Results**:
- ✓ Shot 1: No damage (Player2 is direct ally)
- ✓ Shot 2: Damage applied (Player3 is indirect ally)

**Console Verification**:
```
[WeaponService] PvP damage prevented (direct allies)
[WeaponService] PvP damage allowed (indirect allies)
```

### Test 10: Multiple Component Pool

**Objective**: Verify snapshot includes all connected players

**Setup**:
- Player1 allies with Player2
- Player2 allies with Player3
- Connected component: {Player1, Player2, Player3}

**Steps**:
1. Player1 breaks alliance with Player2 (betrays)
2. Check snapshot members

**Expected Results**:
- ✓ VictimSnapshot includes Player2 and Player3 (Player2's component)
- ✓ BetrayerSnapshot includes only Player1 (now isolated)
- ✓ Pool calculations correct for all members

## Common Issues & Troubleshooting

### Issue: Alliance request not appearing
**Solution**: Check RemoteEvents folder exists, verify AllianceUI script running

### Issue: Betrayal window not starting
**Solution**: Verify players are direct allies, check neither is locked/traitor

### Issue: Incorrect transfer amounts
**Solution**: Check snapshot creation, verify contribution ledger, review weapon values

### Issue: Console errors
**Solution**: Check all modules are in correct locations, verify no typos in require() paths

## Manual Testing Checklist

- [ ] Alliance formation works
- [ ] Alliance breaking starts betrayal
- [ ] Snapshot created correctly
- [ ] Outcome 1 (successful betrayal) transfers 75%
- [ ] Outcome 2 (failed betrayal) transfers 75%
- [ ] Outcome 3 (stalemate) transfers 100% personal + traitor flag
- [ ] Traitor cannot form alliances
- [ ] Disconnect during window resolves correctly
- [ ] Direct allies protected from friendly fire
- [ ] Indirect allies can damage each other
- [ ] No duping (totals match before/after)

## Automated Testing (Future)

Consider creating automated test scripts for:
- Component calculation algorithms
- Weapon selection determinism
- Transaction validation
- Edge case handling

## Performance Testing

Monitor with 8 players, multiple simultaneous betrayals:
- Frame rate impact
- Memory usage
- Network replication load
- Transaction processing time

