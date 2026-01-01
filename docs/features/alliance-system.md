# Alliance Pooling & Betrayal System Documentation

## Overview

The Alliance Pooling & Betrayal System implements a networked alliance graph where players can form undirected alliance edges, pool their resources within connected components, and engage in a 3-outcome betrayal system.

## Key Concepts

### Alliance Graph

- **Undirected Edges**: Alliances are bidirectional connections between players
- **Connected Components**: Groups of players connected via alliance edges
- **Direct vs Indirect Allies**:
  - **Direct Allies**: Players with a direct edge (friendly fire OFF)
  - **Indirect Allies**: Players connected through other players (friendly fire ON)

### Resource Pooling

Resources are pooled across all players in a connected component:
- Currency
- Inventory items (resources)
- Cure components
- Weapons (tracked by value)
- Progress points (if applicable)

### Snapshot System

When a betrayal starts, the system takes an immutable snapshot of both the victim's and betrayer's pools:
- **Member list**: All playerIds in the component
- **Per-member contribution ledger**: Detailed breakdown of each player's contribution
- **Totals**: Aggregated values across all members

Snapshots ensure transfers are calculated from the pool state at betrayal start, preventing exploits.

## Three Betrayal Outcomes

### Outcome 1: Successful Betrayal
**Condition**: Betrayer kills victim within 30 seconds

**Effect**:
- 75% of victim's pooled resources transferred to betrayer
- Deductions applied proportionally across all members of victim's pool
- Weapons selected deterministically by value

### Outcome 2: Failed Betrayal (Mirrored)
**Condition**: Victim kills betrayer within 30 seconds

**Effect**:
- 75% of betrayer's pooled resources transferred to victim
- Deductions applied proportionally across all members of betrayer's pool
- Same mechanics as Outcome 1, but reversed

### Outcome 3: Stalemate
**Condition**: 30 seconds expire without either player killing the other

**Effect**:
- 100% of betrayer's PERSONAL inventory transferred to victim
- Betrayer marked with Traitor flag (cannot form alliances for rest of round)
- ALL of betrayer's remaining alliance edges severed
- Betrayer isolated for remainder of round

## Disconnect Policy

**"Disconnect is treated as death"**

If a player disconnects:
- Immediately marked as dead
- All alliance edges removed
- If in an active betrayal window:
  - **Disconnecting betrayer**: Applies Outcome 2 (victim wins)
  - **Disconnecting victim**: Applies Outcome 1 (betrayer wins)
- Snapshot deductions still apply even after disconnect (prevents exploit)

## System Architecture

### Core Modules

1. **AllianceGraph** (`ServerScriptService/Alliance/AllianceGraph.lua`)
   - Manages undirected alliance edges
   - Calculates connected components using BFS
   - Provides direct ally queries

2. **PoolCalculator** (`ServerScriptService/Alliance/PoolCalculator.lua`)
   - Creates snapshots with member contributions
   - Calculates pool totals
   - Tracks weapon values

3. **InventoryLedger** (`ServerScriptService/Alliance/InventoryLedger.lua`)
   - Atomic transaction system
   - Validates and applies deductions
   - Applies grants
   - Ensures no duping

4. **BetrayalService** (`ServerScriptService/Alliance/BetrayalService.lua`)
   - Manages 30-second betrayal windows
   - Handles outcome resolution
   - Applies proportional transfers
   - Manages traitor flags

5. **AllianceServiceV2** (`ServerScriptService/AllianceServiceV2.lua`)
   - Wrapper service integrating all modules
   - Handles alliance requests/responses
   - Manages betrayal initiation
   - Integrates with other game systems

6. **WeaponValues** (`ReplicatedStorage/Shared/WeaponValues.lua`)
   - Defines weapon values for transfer calculations
   - Provides deterministic weapon sorting

## Integration Points

### MainServer.lua
- Creates AllianceServiceV2 instance
- Links with PlayerManager, CureService, PuzzleService
- Handles player lifecycle events

### WeaponService.lua
- Checks direct alliance for friendly fire
- Calls `allianceService:onPlayerKilled()` on player death

### AllianceUI.lua (Client)
- Displays betrayal notifications
- Shows betrayal timers
- Displays traitor status

## Proportional Transfer System

### Numeric Categories (Currency, Resources, Progress)
```lua
deduction[playerId] = floor(contribution[playerId] * transferPercent)
```

### Integer Categories (Components)
```lua
deduction[playerId] = floor(componentCount[playerId] * transferPercent)
```

### Weapons (Discrete Items)
1. Calculate target weapon value: `floor(totalWeaponValue * transferPercent)`
2. Build deterministic candidate list (sorted by value desc, weaponId asc, ownerId asc)
3. Select weapons in order until cumulative value >= target
4. Deduct from original owners
5. Transfer to winner

### Remainder Distribution
- Floor operations create remainders
- Remainders distributed deterministically by stable ordering
- Ensures total deducted == total transferred

## Security & Exploit Prevention

### No Duping
- Atomic transactions ensure balanced transfers
- Validation before deductions
- Rollback on failure

### Snapshot Immutability
- Pool values frozen at betrayal start
- Cannot be manipulated during window
- Disconnect doesn't avoid deductions

### Server Authority
- All calculations server-side
- Client only displays status
- No trust of client data

## Constants

```lua
POOLED_TRANSFER_PERCENT = 0.75  -- 75% on Outcome 1 & 2
PERSONAL_TRANSFER_PERCENT_ON_STALEMATE = 1.00  -- 100% on Outcome 3
BETRAYAL_WINDOW_DURATION = 30  -- seconds
BETRAYAL_COOLDOWN = 60  -- seconds before new betrayal
```

## Acceptance Tests

### Graph Pooling
✓ If victim is indirectly connected to everyone, snapshot includes all players
✓ Totals equal sum of all pooled values

### Friendly Fire
✓ Only direct allies protected
✓ Indirect allies can damage each other

### Snapshot Immutability
✓ Pool totals don't change after betrayal start
✓ Alliance changes elsewhere don't affect snapshots

### No Duping
✓ Total transferred == total deducted (per category)
✓ Validation prevents impossible deductions

### Disconnect Exploit-Proof
✓ Disconnecting doesn't avoid deductions
✓ Disconnect during window resolves correctly
✓ Snapshot deductions apply to disconnected players

## Usage Examples

### Forming an Alliance
1. Player A requests alliance with Player B
2. Player B accepts
3. AllianceGraph creates undirected edge
4. Resources now pooled

### Initiating Betrayal
1. Player A breaks alliance with Player B
2. Edge immediately removed (friendly fire ON)
3. Snapshots created for both pools
4. Both players locked from alliance changes
5. 30-second window starts

### Outcome Resolution
- **Kill within 30s**: Apply pooled transfer (75%)
- **No kill within 30s**: Apply stalemate (100% personal + Traitor flag)

## Future Enhancements

- Real-time timer display in UI
- Visual traitor indicator (red outline/icon)
- Betrayal history tracking
- Statistics for betrayals/survivals
- Alliance component size limits

## Troubleshooting

### Common Issues

**Issue**: Betrayal doesn't start
- Check if players are direct allies
- Verify neither player is locked
- Check betrayer isn't marked as traitor

**Issue**: Transfer amounts incorrect
- Verify snapshots created correctly
- Check weapon value table
- Review proportional calculation logic

**Issue**: Disconnect not handled
- Verify `onPlayerDisconnect` called
- Check window cleanup logic
- Review outcome resolution

## API Reference

See `API_DOCUMENTATION.md` for full API details of each module.

