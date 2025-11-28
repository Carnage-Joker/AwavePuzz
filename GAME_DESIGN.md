# Game Design Document - AwavePuzz

## Executive Summary

**Title**: AwavePuzz - Zombie Wave Survival  
**Genre**: Multiplayer Survival, Wave Defense, Puzzle  
**Platform**: Roblox  
**Target Players**: 1-8 players per server  
**Core Loop**: Defend base → Collect components → Craft cure or die trying

## Game Concept

AwavePuzz is a multiplayer zombie survival game that combines intense wave-based combat with a strategic puzzle element. Players must balance defending their base from increasingly difficult zombie waves while searching for and collecting components to craft a cure - the only way to win.

## Core Gameplay Pillars

### 1. Combat & Survival
- **Wave-based zombie encounters** with progressive difficulty
- **Base defense** - protect the central structure
- **Health management** - no respawns, every decision matters
- **Resource management** - balance offense and collection

### 2. Puzzle & Strategy
- **Cure crafting system** - collect 5 different components
- **Resource scarcity** - limited components on map
- **Strategic decisions** - when to fight, when to collect

### 3. Social Dynamics
- **Alliance formation** - team up for better survival
- **Betrayal mechanics** - steal resources from allies
- **Trust vs. competition** - balance cooperation with self-interest

## Detailed Game Systems

### Player System

**Health**
- Starting: 100 HP
- No regeneration
- No respawns
- Death is permanent for the round

**Abilities**
- Movement and combat
- Sprint (Left Shift): 1.5x speed, consumes stamina
- Component collection
- Alliance management

**Stamina**
- Starting/Max: 100
- Depletion rate: 20 per second (while sprinting)
- Regeneration rate: 15 per second (when not sprinting)
- Regeneration delay: 1 second after stopping sprint

### Wave System

**Progression Formula**
```
Zombie Count = Base × (Multiplier ^ (Wave - 1))
Zombie Health = Base HP × (Health Multiplier ^ (Wave - 1))
```

**Default Values**
- Base zombies: 5
- Multiplier: 1.5x
- Health multiplier: 1.2x
- Wave delay: 30 seconds

**Example Progression**
- Wave 1: 5 zombies @ 50 HP each
- Wave 2: 8 zombies @ 60 HP each
- Wave 3: 11 zombies @ 72 HP each
- Wave 4: 17 zombies @ 86 HP each
- Wave 5: 25 zombies @ 104 HP each

### Zombie AI

**Behavior**
- Intelligent target selection: nearest player or base
- Proximity-based attack system (6 stud range)
- Attack animations when available
- Continuous movement toward target
- Server-authoritative damage dealing
- Dynamic retargeting every second

**Targeting System**
- Priority: Always attacks closest threat
- Players: Targets alive players first
- Base: Targets base when no players closer
- Retargeting: Updates path every 1 second

**Attack System**
- Attack Range: 6 studs
- Attack Interval: 1.5 seconds (cooldown)
- Animation Support: Plays attack animation if available
- Damage Dealing: Server-side validation

**Stats (Base)**
- Health: 50 HP
- Damage: 10 HP per hit
- Speed: 16 studs/second
- Attack cooldown: 1.5 seconds
- Attack range: 6 studs
- Repath interval: 1.0 seconds

### Base System

**Structure**
- Central defensive point
- Health pool: 1000 HP
- No regeneration
- Destructible by zombies

**Importance**
- Primary objective to defend
- Loss condition if destroyed
- Strategic positioning point

### Cure Crafting System

**Components Required**
1. Chemical A (5 pieces)
2. Chemical B (5 pieces)
3. Biological Sample (5 pieces)
4. Research Notes (5 pieces)
5. Catalyst (5 pieces)

**Total**: 25 component pieces

**Collection**
- Spawned randomly at designated points
- Maximum 10 on map at once
- Spawn rate: 45 seconds
- Instant pickup on touch

**Progress Tracking**
- Individual player contribution
- Global cure progress (0-100%)
- Visual indicators for completion

### Alliance System

**Formation**
- Mutual agreement required
- Instant activation
- Prevents friendly fire

**Benefits**
- Coordinated defense
- Resource sharing strategies
- Better survival odds

**Betrayal**
- Break alliance at any time
- Cooldown: 60 seconds before rejoining
- Enables PvP with former ally

**Strategic Considerations**
- Early game: cooperation is beneficial
- Late game: competition for final components
- Risk/reward of trust

### Win/Lose Conditions

**Victory Condition**
- Craft the complete cure
- All 5 components collected (5 pieces each)
- Any surviving players win together

**Defeat Conditions**
1. Base destroyed (0 HP)
2. All players eliminated (0 survivors)

**Game States**
- Waiting: Waiting for minimum players
- Lobby: Map voting phase
- Countdown: Pre-round countdown
- WaveActive: Active wave gameplay
- Intermission: Break between waves
- Victory: Cure crafted successfully
- Defeat: Failure condition met
- Scoreboard: End-of-round scoreboard display

### Round Flow

Each game round follows this flow:
1. **Lobby Phase**: Players vote on which map to play (20 seconds)
2. **Countdown**: Brief countdown before round starts (5 seconds)
3. **Gameplay**: Waves of zombies attack, players have ONE life per round
4. **Death**: Dead players enter spectator mode to watch remaining players
5. **Round End**: Victory (cure completed) or Defeat (all dead/base destroyed)
6. **Scoreboard**: Display player stats and scores (10 seconds)
7. **Return to Lobby**: Cycle repeats with new map vote

### Spectator Mode

When a player dies during a round:
- They enter spectator mode (no respawn during round)
- Can cycle through alive players with Q/E keys
- See who they're spectating and how many players remain
- Exit spectator mode when round ends

## Map Design Requirements

### Essential Elements

**1. Central Base**
- Defensible position
- Visual prominence
- Multiple approach angles
- Health indicator

**2. Zombie Spawn Points**
- Multiple locations around perimeter
- Distance from base
- Line of sight considerations

**3. Resource Spawn Points**
- Scattered throughout map
- Varying distances from base
- Risk/reward positioning
- Minimum 10 unique locations

**4. Player Spawn**
- Near base but not blocking
- Safe initial position
- Clear view of surroundings

### Layout Considerations

**Size**: Medium (allows 8 players to spread out)
**Theme**: Post-apocalyptic/laboratory setting
**Pathways**: Multiple routes between key points
**Cover**: Strategic positioning opportunities
**Verticality**: Optional multi-level design

## Technical Architecture

### Module Structure

**Server-Side**
- `GameServer.lua`: Main game loop and coordination
- `PlayerManager.lua`: Player state and health
- `WaveManager.lua`: Wave spawning logic
- `BaseManager.lua`: Base health tracking
- `CureCraftingManager.lua`: Puzzle system
- `ResourceSpawner.lua`: Component spawning

**Client-Side**
- `ClientController.lua`: UI updates and input
- Event listeners for server updates
- Visual feedback systems

**Shared**
- `GameConfig.lua`: Tunable parameters
- `GameState.lua`: State management

### Network Architecture

**Client → Server**
- Player actions (collect, attack, alliance)
- Movement and position updates
- UI interactions

**Server → Client**
- Game state updates
- Wave notifications
- Component spawns
- Alliance changes
- Win/lose conditions

## Balancing Considerations

### Difficulty Curve
- Early waves: manageable, learning period
- Mid waves: challenging, strategy required
- Late waves: intense, requires coordination

### Component Scarcity
- Spawn rate: balanced for ~5-10 minute games
- Competition factor: encourages exploration
- Cooperation incentive: sharing benefits all

### Alliance Balance
- Betrayal cooldown: prevents spam
- Friendly fire: prevents accidental kills
- Trust economy: risk/reward is balanced

## User Interface Requirements

### HUD Elements
- Player health bar
- Base health indicator
- Wave counter
- Cure progress bar
- Component inventory
- Alliance status
- Zombie counter

### Notifications
- Wave start announcements
- Component collection feedback
- Alliance formation/break
- Win/lose screens
- Player death notifications

### Menus
- Alliance management
- Component tracking
- Player list with status
- Settings

## Audio Design (Future)

### Music
- Ambient: Tense, atmospheric
- Combat: Intense, driving
- Victory: Triumphant
- Defeat: Somber

### Sound Effects
- Zombie sounds: growls, attacks
- Component collection: positive feedback
- Base damage: alarm, warning
- Alliance: notification sound
- Wave start: siren or bell

## Accessibility Considerations

- Clear visual indicators
- Audio cues for key events
- Colorblind-friendly UI
- Adjustable settings
- Tutorial system (future)

## Metrics & Analytics (Future)

### Track
- Average game length
- Win rate
- Most collected component
- Alliance formation rate
- Betrayal frequency
- Player death wave average
- Base survival rate

### Use For
- Balance adjustments
- Player behavior insights
- Feature prioritization
- Difficulty tuning

## Future Expansion Ideas

### Phase 2 Features
- Weapon system (temporary power-ups)
- Special zombie types (tank, fast, ranged)
- Multiple maps
- Difficulty modes

### Phase 3 Features
- Progression system
- Character customization
- Achievements
- Leaderboards

### Phase 4 Features
- Story mode
- Boss waves
- Seasonal events
- Custom game modes

## Development Priorities

### Phase 1 (Current)
✅ Core systems implementation
✅ Basic functionality
✅ Documentation

### Phase 2 (Next)
- Roblox integration
- Visual assets
- Testing with players

### Phase 3 (Polish)
- UI/UX improvements
- Sound design
- Performance optimization

### Phase 4 (Launch)
- Public testing
- Community feedback
- Iteration based on data

## Conclusion

AwavePuzz combines the tension of survival gameplay with the strategic depth of puzzle-solving and social dynamics. The wave-based structure provides escalating challenge, while the cure-crafting system creates a clear goal. The alliance system adds a layer of human unpredictability that makes each game unique.

The modular architecture allows for easy expansion and modification, while the focused core gameplay ensures a solid foundation. With proper execution, AwavePuzz can provide engaging multiplayer experiences that reward both cooperation and competition.

---

**Document Version**: 1.0  
**Last Updated**: 2025-11-15  
**Status**: Core Implementation Complete