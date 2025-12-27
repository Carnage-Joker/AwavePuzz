# Gameplay Systems Documentation

## Ammo System

### Overview
The game now implements a comprehensive ammo management system with magazine and reserve caps to prevent unlimited ammo exploits.

### Architecture
- **FPSConfig.lua**: Defines weapon stats including ammo caps
- **FPSWeaponService.lua**: Server-authoritative ammo tracking and enforcement
- **ItemSpawner.lua**: Manages ammo pack pickups

### Ammo Caps
Each weapon has the following ammo properties:
- `MagSize`: Magazine capacity (how many rounds can be loaded)
- `MaxMagazineAmmo`: Maximum magazine capacity (same as MagSize, enforced on reload)
- `ReserveAmmo`: Starting reserve ammunition
- `MaxReserveAmmo`: Maximum reserve ammunition (enforced on pickups and adds)

#### Default Weapon Ammo Caps
| Weapon  | Mag Size | Max Reserve | Total Max |
|---------|----------|-------------|-----------|
| Pistol  | 12       | 96          | 108       |
| SMG     | 30       | 180         | 210       |
| Shotgun | 6        | 48          | 54        |
| Rifle   | 10       | 60          | 70        |

### Server Authority
- All ammo tracking is server-side
- Client cannot spoof ammo counts
- Ammo pickups validated on server
- Reload operations validated and clamped to max values

### Ammo Pickups
- Ammo packs add `GameConfig.AMMO_PACK_AMOUNT` (default: 30) to reserve
- Pickups are clamped to `MaxReserveAmmo` - cannot exceed cap
- If reserve is already at max, pickup has no effect

### Debug Logging
When `GameConfig.DEBUG = true`:
- Logs ammo additions showing before/after values
- Logs pickup events with current/max values
- Logs reload operations

## Health Pack System

### Overview
Health packs restore player health reliably with proper validation and Humanoid synchronization.

### Implementation
- **ItemSpawner.lua**: Manages health pack spawning and collection
- **PlayerManager.lua**: Handles health restoration with validation

### Behavior
- Health packs restore `GameConfig.HEALTH_PACK_AMOUNT` (default: 50) HP
- Health is clamped to both `GameConfig.STARTING_HEALTH` and `Humanoid.MaxHealth`
- Cannot pick up health pack when at full health
- Health state synchronized between PlayerManager and Humanoid

### Debug Logging
When `GameConfig.DEBUG = true`:
- Logs pre-heal and post-heal health values
- Logs PlayerData.health and Humanoid.Health synchronization
- Tracks healing amount applied

## Scoreboard & Stat Tracking

### Overview
The scoreboard now tracks comprehensive player statistics including kills, deaths, wins, components collected, and puzzle solves.

### Architecture
- **GameManager.lua**: Central stat storage and broadcasting
- **WeaponService.lua**: Tracks kill attribution via LastHitBy attribute
- **CureService.lua**: Tracks component collection
- **PuzzleService.lua**: Tracks puzzle completion
- **ScoreboardUI.lua**: Client-side display

### Tracked Statistics
Each player has the following stats:
- `kills`: Zombie kills (attributed via LastHitBy)
- `deaths`: Player deaths
- `roundWins`: Rounds won (alive at victory)
- `roundLosses`: Rounds lost (dead at defeat or all players dead)
- `componentsCollected`: Total cure components collected
- `puzzleSolves`: Total puzzles solved (including final synthesis)

### Stat Update Flow

#### Kill Tracking
1. Zombie takes damage → `LastHitBy` attribute set to player UserId
2. Zombie dies → `Spawner:onZombieDied()`
3. `WeaponService:onZombieKilled()` checks `LastHitBy` attribute
4. `GameManager:incrementPlayerKills()` called
5. `GameManager:broadcastScoreboard()` sends update to all clients

#### Component Collection
1. Player collects component → `CureService:handleDepositComponent()`
2. Component added to player inventory
3. `GameManager:incrementPlayerComponentsCollected()` called
4. Scoreboard updated

#### Puzzle Solves
1. Player completes puzzle → `PuzzleService:onPuzzleCompleted()`
2. Puzzle marked as solved
3. `GameManager:incrementPlayerPuzzleSolves()` called via CureService reference
4. Scoreboard updated

### Scoreboard Display
Columns (left to right):
1. **Player**: Player name (bolded for local player)
2. **Kills**: Zombie kills
3. **Deaths**: Times died
4. **Wins**: Rounds won
5. **Parts**: Cure components collected
6. **Puzzles**: Puzzles solved

### Server Authority
- All stats stored server-side in `GameManager.playerStats`
- Stats broadcast to all clients via `ScoreboardUpdate` RemoteEvent
- Stats persist across waves within same round
- Stats reset between rounds (in `resetForNewRound()`)

## Spectator Mode Lifecycle

### Overview
Dead players enter spectator mode during rounds and must be properly restored to normal state at round end.

### Architecture
- **SpectatorManager.lua**: Manages spectator state and camera targeting
- **GameManager.lua**: Coordinates round transitions and spectator reset

### Spectator Flow

#### Entering Spectator Mode
1. Player dies → `GameManager:onPlayerDied()`
2. `SpectatorManager:onPlayerDied()` called
3. Player marked as dead, character made invisible
4. `IsSpectating` attribute set on character (zombies ignore)
5. Camera set to third-person targeting alive player

#### During Spectator Mode
- Player can cycle between alive players with Q/E keys
- Spectator UI shows alive player count
- Dead player's character is invisible to all
- Zombies ignore spectating players

#### Exiting Spectator Mode
Spectator mode ends when:
1. Round ends (victory or defeat)
2. Transitioning to LOBBY or WAITING state
3. New round starts

Reset sequence:
1. `SpectatorManager:endRound()` called in victory/defeat
2. `SpectatorManager:reset()` called in round transitions
3. All spectators exit via `exitSpectatorMode()`
4. `IsSpectating` attribute removed
5. Character visibility restored
6. Dead player flags cleared

### Key Methods

#### SpectatorManager:startRound()
Called at wave 1 start, initializes spectator tracking for the round.

#### SpectatorManager:endRound()
Called at round end (victory/defeat), exits all spectators.

#### SpectatorManager:reset()
Called when transitioning to LOBBY or WAITING, fully resets spectator state.

### Round Transition Flow
```
WAVE_ACTIVE (death) → Spectator Mode Active
  ↓
VICTORY/DEFEAT → endRound() called
  ↓
SCOREBOARD → Display stats
  ↓
WAITING or LOBBY → reset() called → Normal state restored
```

### Important Notes
- Spectator mode ONLY active during WAVE_ACTIVE and INTERMISSION states
- All spectators MUST exit before new round starts
- Character respawns handled by GameManager separately
- SpectatorManager does NOT handle respawning, only camera and visibility

## Debug Mode

### Enabling Debug Mode
Set `GameConfig.DEBUG = true` in `ReplicatedStorage/Shared/GameConfig.lua`

### Debug Output
When enabled, you'll see detailed logs for:
- Ammo additions and pickups
- Health pack usage and healing
- Stat increments (kills, components, puzzles)
- Round transitions and spectator state changes

### Production
**Always set `GameConfig.DEBUG = false` in production** to avoid log spam.
