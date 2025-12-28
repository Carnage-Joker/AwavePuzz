# Base Camp Visual Design

This document describes the visual appearance and layout of the automatically generated base camp.

## Overview

The base camp is a defensive fortress automatically created at the center of the map. It provides players with a strategic position to defend against zombie waves.

## Dimensions

- **Total Area**: 30 x 30 studs
- **Wall Height**: 12 studs
- **Wall Thickness**: 2 studs
- **Gate Width**: 8 studs
- **Cover Size**: 4 x 3 x 1 studs

## Structure Layout

```
Top View (not to scale):

                    N (North)
                       ↑
    ╔═══════════╦════════════╦═══════════╗
    ║           ║   Gate N   ║           ║
    ║  NW Wall  ╚════════════╝  NE Wall  ║
    ║                                    ║
    ║        ●              ●            ║  E (East)
W ← ╣ Gate W  ●    BASE    ●   Gate E   ║ ←
    ║        ●   PLATFORM  ●            ╣ →
    ║                                    ║
    ║  SW Wall  ╔════════════╗  SE Wall  ║
    ║           ║   Gate S   ║           ║
    ╚═══════════╩════════════╩═══════════╝
                       ↓
                    S (South)

Legend:
  ║ ╔ ╗ ╚ ╝ ═ ╣  = Walls (concrete, 12 studs high, 2 studs thick)
  Gate N/S/E/W  = Semi-transparent wooden gates (passable)
  ●             = Cover positions (8 total, arranged in circle)
  BASE PLATFORM = 30x30 stud concrete platform (ground level)
```

## Side View

```
     12 studs
    ┌─────────┐
    │         │  Wall
    │         │
    │         │
    │         │
    │         │
    │         │
────┴─────────┴──── Base Platform (1 stud high)
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ Ground Level
```

## Components Detail

### Base Platform
- **Type**: Part
- **Size**: 30 x 1 x 30 studs
- **Material**: Concrete
- **Color**: Gray (RGB 100, 100, 100)
- **Position**: At ground level (calculated via raycasting)
- **Function**: Central defensive position

### Walls (4 total)
- **Type**: Part (anchored)
- **Dimensions**: 
  - North/South: 30 x 12 x 2 studs
  - East/West: 2 x 12 x 30 studs
- **Material**: Concrete
- **Color**: Dark Gray (RGB 80, 80, 80)
- **Position**: On each edge of the platform
- **Function**: Defensive barrier against zombies

### Gates (4 total)
- **Type**: Part (anchored)
- **Dimensions**: 8 x 8.4 x 2 studs
- **Material**: Wood
- **Color**: Brown (RGB 120, 80, 40)
- **Transparency**: 0.3 (semi-transparent)
- **CanCollide**: False (players can pass through)
- **Position**: Center of each wall (N/S/E/W)
- **Attribute**: IsGate = true
- **Function**: Visual entry/exit points, doesn't block movement

### Cover Positions (8 total)
- **Type**: Part (anchored)
- **Size**: 4 x 3 x 1 studs each
- **Material**: Metal
- **Color**: Dark Gray (RGB 70, 70, 70)
- **Layout**: Arranged in a circle, 10 studs from center
- **Rotation**: Each facing outward from center
- **Function**: Tactical cover for defensive positions

### BaseCaptureZone (Invisible)
- **Type**: Model
- **Contains**: 
  - HitBox (Part): 26 x 10 x 26 studs
  - Health (NumberValue): Set to BASE_HEALTH (1000)
- **HitBox Properties**:
  - Transparency: 1.0 (invisible)
  - CanCollide: False
  - Position: Center of base camp, elevated
- **Function**: Zombie targeting point (AI uses this)

## Color Palette

```
Platform:  ████ Gray    (RGB 100, 100, 100) - Concrete
Walls:     ████ Gray    (RGB 80, 80, 80)    - Concrete
Gates:     ████ Brown   (RGB 120, 80, 40)   - Wood (30% transparent)
Cover:     ████ Gray    (RGB 70, 70, 70)    - Metal
```

## Material Types

- **Concrete**: Platform and Walls - Solid, defensive appearance
- **Wood**: Gates - Rustic, makeshift appearance
- **Metal**: Cover - Industrial, tactical appearance

## Tactical Layout

### Cover Position Arrangement

The 8 cover positions are strategically placed:

```
           Cover_1 (0°)
              ●
    ●                     ●
Cover_8 (315°)      Cover_2 (45°)

●         BASE          ●
Cover_7 (270°)    Cover_3 (90°)

    ●                     ●
Cover_6 (225°)      Cover_4 (135°)
              ●
           Cover_5 (180°)
```

Each cover position is:
- **10 studs** from the center
- **Rotated** to face outward (provides cover from outside attacks)
- **Evenly spaced** at 45° intervals

### Strategic Advantages

1. **Central Position**: Easy for players to fall back to
2. **360° Defense**: Cover positions allow defense from all directions
3. **Multiple Entry Points**: 4 gates provide flexible movement
4. **Visual Clarity**: Semi-transparent gates show where zombies can "enter"
5. **Height Advantage**: 12-stud walls provide line-of-sight from behind cover
6. **Team Coordination**: Multiple cover positions allow players to spread out

## Spawn Position

The base camp is automatically positioned at:

```lua
-- Calculated as the average of all zombie spawn points
local centerX = average(all spawn point X positions)
local centerY = ground level (via raycasting)
local centerZ = average(all spawn point Z positions)
```

Example with 4 spawn points:
```
Spawn Points:
  (50, 5, 0)   - East
  (0, 5, 50)   - North
  (-50, 5, 0)  - West
  (0, 5, -50)  - South

Calculated Center: (0, 5, 0)
```

## Visibility from Different Angles

### From Ground Level (Outside)
- Walls appear as solid concrete barriers
- Gates show as semi-transparent brown sections
- Cover visible around the perimeter
- Platform visible between wall sections

### From Elevated Position (Inside)
- Full view of interior space
- All 8 cover positions visible
- Gates provide natural exit points
- Platform serves as staging area

### From Zombie Perspective
- AI targets the invisible BaseCaptureZone HitBox
- Pathfinding leads zombies toward gates
- Zombies will attack walls if that's the shortest path
- Base health decreases as zombies attack

## Integration with Game Systems

### Zombie AI
- Zombies use TargetingService to find BaseCaptureZone
- HitBox position guides zombie pathfinding
- Zombies attack when within 6 studs of HitBox

### Base Health
- BaseManager tracks base health (1000 HP)
- Damage applies when zombies attack
- Health decreases with each zombie hit
- Defeat condition at 0 HP

### Player Movement
- Players can freely move through gates (CanCollide = false)
- Cover provides tactical positioning
- Platform serves as high ground (1 stud elevation)
- No collision restrictions inside base

## Customization Options

All visual aspects can be customized in BaseCampSetup.lua via CAMP_CONFIG:

```lua
local CAMP_CONFIG = {
    -- Dimensions
    BASE_SIZE = 30,           -- Default: 30 studs
    WALL_HEIGHT = 12,         -- Default: 12 studs
    WALL_THICKNESS = 2,       -- Default: 2 studs
    GATE_WIDTH = 8,           -- Default: 8 studs
    COVER_COUNT = 8,          -- Default: 8 positions
    
    -- Colors (RGB)
    WALL_COLOR = Color3.fromRGB(80, 80, 80),
    BASE_COLOR = Color3.fromRGB(100, 100, 100),
    GATE_COLOR = Color3.fromRGB(120, 80, 40),
    COVER_COLOR = Color3.fromRGB(70, 70, 70),
    
    -- Materials
    WALL_MATERIAL = Enum.Material.Concrete,
    BASE_MATERIAL = Enum.Material.Concrete,
    GATE_MATERIAL = Enum.Material.Wood,
    COVER_MATERIAL = Enum.Material.Metal,
}
```

## Visual Effects (Future)

Potential enhancements for visual appeal:

1. **Damage States**: Walls show cracks/damage as health decreases
2. **Lighting**: Spotlights at corners illuminate perimeter
3. **Particles**: Dust/debris when base takes damage
4. **Textures**: Weathered appearance for post-apocalyptic feel
5. **Decals**: Warning signs, directional arrows on walls
6. **Transparency**: Gates could pulse/glow when zombies near

## Comparison with Manual Base

| Feature | Auto-Generated | Manual Creation |
|---------|----------------|-----------------|
| Position | Center of map (calculated) | Designer-placed |
| Structure | Standardized layout | Custom design |
| Zombie Targeting | Automatic (BaseCaptureZone) | Requires manual setup |
| Setup Time | Instant (script runs) | Hours of building |
| Consistency | Same on all maps | Varies per map |
| Customization | Config-based | Full creative control |
| Testing | Automated scripts | Manual testing |

## Conclusion

The auto-generated base camp provides:
- ✅ Consistent defensive structure across all maps
- ✅ Optimal center positioning based on spawn points
- ✅ Tactical cover and defensive positions
- ✅ Seamless zombie AI integration
- ✅ Minimal setup time for map creators
- ✅ Configurable appearance and dimensions
- ✅ Professional appearance out-of-the-box

The standardized design ensures players always have a familiar defensive position regardless of which map is loaded, while the configuration system allows customization when needed.

---

**Version**: 1.0  
**Last Updated**: 2025-12-28  
**Related Documentation**: BASE_CAMP_SYSTEM.md, GAME_DESIGN.md
