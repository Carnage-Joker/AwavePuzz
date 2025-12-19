# AwavePuzz - Zombie Wave Survival FPS

A multiplayer Roblox first-person shooter zombie survival game featuring wave-based combat, cure-crafting puzzles, and alliance systems. Now with full FPS mechanics including recoil, ADS, dynamic crosshairs, and more!

## 🎮 Game Overview

**AwavePuzz** is a cooperative survival FPS where up to 8 players defend a base against increasingly difficult waves of zombies. Players must work together (or betray each other) to collect cure components and craft a cure before the base is destroyed or all players are eliminated.

## 🔫 NEW: First-Person Shooter Features

### True First-Person Experience
- **First-person camera** locked to the player's head
- **Mouse-locked gameplay** - no cursor during combat
- **Configurable FOV** (50-120 degrees)
- **Mouse sensitivity** and invert Y-axis options

### Modern FPS Gunplay
- **Recoil system** - Camera kick with recovery
- **Spread system** - Dynamic accuracy based on movement/firing
- **ADS (Aim Down Sights)** - Right-click for precision aiming
- **Fire modes** - Semi-auto, burst, and full-auto weapons
- **Reload system** - Manual reload with R, auto-reload when empty
- **Magazine + reserve ammo** tracking

### ✨ NEW: Complete Weapon Animation System
- **Viewmodel arms** - Dedicated first-person arm and weapon rendering
- **6 animation types** per weapon:
  - Idle - Subtle breathing and weapon bob
  - Fire - Recoil and muzzle movement
  - Reload - Full magazine change sequence
  - Equip - Weapon draw animation
  - Sprint - Lowered weapon while running
  - ADS - Sight alignment animation
- **Procedural animations**:
  - Dynamic weapon sway following mouse movement
  - Breathing motion for realistic idle
  - Smooth recoil recovery
- **Event-driven integration** with weapon controller
- **Works with or without animation assets** - Uses procedural fallbacks

See [WEAPON_ANIMATIONS.md](WEAPON_ANIMATIONS.md) for complete animation system documentation and [ANIMATION_CREATION_GUIDE.md](ANIMATION_CREATION_GUIDE.md) for step-by-step animation creation.

### Polished FPS HUD
- **Dynamic crosshair** that expands with spread
- **Ammo counter** with low-ammo warnings
- **Hitmarkers** for hits, headshots, and kills
- **Damage vignette** and low-health indicators

### Controller-Friendly Menus
- **Keyboard navigation** - No mouse required
- **Settings menu** - Sensitivity, FOV, volume controls
- **Controls display** - In-game keybind reference

See [FPS_DOCUMENTATION.md](FPS_DOCUMENTATION.md) for complete FPS system documentation.

## 🌟 Key Features

### 1. **Multiplayer Support**
- Up to 8 players per server
- Real-time cooperative gameplay
- Player health tracking and death system

### 2. **Wave-Based Zombie Combat**
- Progressive difficulty scaling
- Zombies get stronger and more numerous each wave
- Strategic base defense mechanics
- **Improved AI**: Zombies intelligently target nearest player or base
- **Attack System**: Zombies attack when in range with cooldown
- **Animation Support**: Attack animations for visual feedback
- Base health system with damage tracking
- Reward payouts per kill based on weapon used

### 3. **Cure-Crafting Puzzle System** ✅ NEW
- 5 unique cure components to collect:
  - Chemical A (Mathematical Puzzle)
  - Chemical B (Pattern Matching Puzzle)
  - Biological Sample (Color Matching Puzzle)
  - Research Notes (Logic Puzzle)
  - Catalyst (Abstract Node Connection Puzzle)
- Each component requires 5 pieces to complete
- **Puzzle Mini-Games**: When 5 components are collected, players must solve a puzzle at cure stations
- **6 Total Puzzles**: 5 component-specific puzzles + 1 final synthesis puzzle
- Interactive cure stations with ProximityPrompts
- Time-limited puzzle challenges (45-120 seconds)
- Currency rewards for puzzle completion
- Final synthesis puzzle combines all 5 puzzle types and triggers victory
- Resources spawn randomly around the map
- Progress tracking system

### 4. **Alliance System with Betrayal** ✅ PHASE 4 COMPLETE
- Team up with other players for better survival
- Allied players can't damage each other (friendly fire prevention)
- Visual indicators: Green highlights show who is allied
- **Betrayal Mechanics**: Breaking alliances allows stealing:
  - Solved puzzles (50% chance per puzzle)
  - Collected components (50% steal rate)
  - Potential puzzle reset for victim (50% chance)
- Betrayal cooldown: 60 seconds before forming new alliances
- Strategic decision-making between cooperation and competition
- PvP enabled between non-allied players
- Alliance UI accessible with Tab key

### 5. **Weapon & Upgrade System**
- Server-authoritative raycast weapons with fire-rate balancing
- Earn currency from kills and wave completions
- Camp Vendor shop with weapon unlocks and stat upgrades
- Hotkeys to swap between owned weapons on the fly

### 6. **Inventory & Resource Loop**
- Visible inventory tracker for cure components
- Server-spawned resource pickups scattered per map
- Cure stations validate inventory before allowing deposits

### 7. **Dynamic Map Support**
- MapManager clones any map model stored in `ServerStorage.Maps`
- Each map carries its own zombie/resource spawn points
- Clients receive map announcements at match start

### 8. **Win/Lose Conditions**
**Victory:** Successfully craft the cure by collecting all required components

**Defeat:** Game ends when:
- Base health reaches zero
- All players are eliminated

## 📁 Project Structure

```
AwavePuzz/
├── src/
│   ├── server/                    # Server-side game logic
│   │   ├── GameManager.lua        # Main game controller
│   │   ├── PlayerManager.lua      # Player data and health management
│   │   ├── WaveManager.lua        # Wave spawning and progression
│   │   ├── BaseManager.lua        # Base health and defense
│   │   ├── WeaponService.lua      # Weapon system
│   │   ├── FPSWeaponService.lua   # FPS ammo/reload validation
│   │   └── ...                    # Other services
│   ├── client/                    # Client-side UI and controls
│   │   ├── FirstPersonCamera.client.lua      # FPS camera controller
│   │   ├── FPSMovementController.client.lua  # Movement with crouch/sprint
│   │   ├── FPSWeaponController.client.lua    # Weapon mechanics
│   │   ├── FPSMenuController.client.lua      # Pause/settings menus
│   │   ├── FPSAudioController.client.lua     # Sound management
│   │   └── UI/
│   │       ├── FPSHUD.client.lua             # Crosshair, ammo, hitmarkers
│   │       └── ...                           # Other UI scripts
│   └── shared/                    # Shared modules
│       ├── GameConfig.lua         # Game configuration
│       ├── FPSConfig.lua          # FPS-specific configuration
│       └── ...                    # Other configs
├── FPS_DOCUMENTATION.md           # FPS system documentation
├── README.md
└── LICENSE
```

## 🎯 Game Mechanics

### Wave System
- Waves start automatically with a 30-second delay between waves
- Each wave increases zombie count by 1.5x
- Zombie health increases by 1.2x per wave
- Wave progression continues until players win or lose

### Player Mechanics
- Starting health: 100 HP
- No respawning (hardcore mode)
- Earn cash from kills and wave completions
- Purchase or upgrade weapons at the shop (default key **B**)
- Can form and break alliances
- Collect cure components to contribute to victory
- **Sprint**: Hold **Left Shift** to sprint (1.5x speed)
  - Stamina depletes while sprinting
  - Stamina regenerates when not sprinting (after 1 second delay)
  - Visual stamina bar in HUD
- **Crouch**: Toggle **Left Ctrl** (slower speed, smaller hitbox)

### FPS Controls

| Action | Key |
|--------|-----|
| Move | W/A/S/D |
| Look | Mouse |
| Fire | Left Click |
| Aim (ADS) | Right Click |
| Reload | R |
| Sprint | Left Shift (hold) |
| Crouch | Left Ctrl (toggle) |
| Jump | Space |
| Weapon Slots | 1, 2, 3, 4 |
| Shop | B |
| Alliance Menu | Tab |
| Pause Menu | Escape |

### Base Mechanics
- Starting health: 1000 HP
- No regeneration
- Must be defended from zombie attacks
- Critical for survival

### Cure Crafting
- Requires 5 of each component (25 total pieces)
- Components spawn periodically around the map
- Maximum 10 resources on map at once
- New resources spawn every 45 seconds
- Inventory is server-tracked; depositing consumes from your bag
- Puzzle mini-events can reward additional components

### Weapons & Upgrades
- Default pistol for every survivor
- Additional weapons: SMG, Shotgun, Rifle
- Damage/Firerate upgrade chips apply permanent buffs per player
- Raycast validation runs on the server to prevent exploits
- **FPS Weapon Features:**
  - Recoil with camera kick and recovery
  - Dynamic spread based on movement/firing
  - ADS (Aim Down Sights) for precision
  - Magazine + reserve ammo system
  - Manual reload with R key

### Map Rotation
- `ServerStorage.Maps` can contain themed arenas (e.g., Research Outpost, Desert Ruins)
- Each map provides its own `ZombieSpawnPoints` and `ResourceSpawnPoints`
- Fallback to legacy workspace folders when a map is missing

## 🔧 Configuration

All game settings can be adjusted in `src/shared/GameConfig.lua`:

```lua
-- Debug & Testing
DEBUG = false  -- Set to true to enable test/debug scripts

-- Player Settings
MAX_PLAYERS = 8
STARTING_HEALTH = 100

-- Base Settings
BASE_HEALTH = 1000

-- Wave Settings
WAVE_DELAY = 30
BASE_ZOMBIES_PER_WAVE = 5

-- Zombie Settings
ZOMBIE_HEALTH = 50
ZOMBIE_DAMAGE = 10
ZOMBIE_SPEED = 16

-- Resource Settings
RESOURCE_SPAWN_RATE = 45
MAX_RESOURCES_ON_MAP = 10
```

**Note:** Test and debug scripts in `src/server/Tests/` will only run when `GameConfig.DEBUG = true`.

## 🚀 Installation (Roblox Studio)

For detailed setup instructions, see [INSTALLATION.md](INSTALLATION.md)

**Quick Start:**
1. Clone this repository
2. Open Roblox Studio
3. Create a new place or open an existing one
4. Copy scripts from `src/` folders to appropriate Roblox locations:
   - `src/server/` → ServerScriptService
   - `src/client/` → StarterPlayer.StarterPlayerScripts and StarterGui
   - `src/shared/` → ReplicatedStorage/Shared
5. Set up the game environment (spawn points, base, etc.)
6. Configure workspace folders (ZombieSpawnPoints, CureStations, etc.)
7. Test in multiplayer mode

For complete step-by-step instructions, troubleshooting, and configuration options, refer to [INSTALLATION.md](INSTALLATION.md).

## 🎮 How to Play

1. **Join the Server**: Up to 8 players can join
2. **Defend the Base**: Fight off incoming zombie waves
3. **Collect Components**: Find and collect cure components scattered around the map
4. **Form Alliances**: Team up with other players for better survival odds
5. **Craft the Cure**: Collect all required components to win
6. **Stay Alive**: Avoid zombie attacks and manage your health

## 🤝 Alliance Strategies

### Cooperative Play
- Share resources and protect each other
- Coordinate defense positions
- Distribute component collection

### Competitive Play
- Betray alliances to hoard resources
- Strategic timing for betrayals
- Balance risk vs. reward

## 📊 Game State Tracking

The game tracks:
- Current wave number
- Base health and percentage
- Cure crafting progress (0-100%)
- Number of zombies remaining
- Players alive count
- Individual player health and components

## 🛠️ Development

This game is built using:
- **Language**: Lua (Roblox Luau)
- **Platform**: Roblox
- **Architecture**: Modular server-client system with server-authoritative design
- **Design Pattern**: Object-oriented with manager classes

### Documentation

- **[INSTALLATION.md](INSTALLATION.md)** - Complete setup guide for Roblox Studio
- **[API_DOCUMENTATION.md](API_DOCUMENTATION.md)** - API reference and system interactions
- **[FPS_DOCUMENTATION.md](FPS_DOCUMENTATION.md)** - ✨ NEW: FPS system documentation and tuning guide
- **[GAME_DESIGN.md](GAME_DESIGN.md)** - Game design document and mechanics
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Implementation details and progress
- **[ZOMBIE_AI_IMPROVEMENTS.md](ZOMBIE_AI_IMPROVEMENTS.md)** - Zombie AI and animation improvements documentation
- **[docs/STRUCTURE.md](docs/STRUCTURE.md)** - 🆕 Project structure and organization guide
- **[docs/REMOTE_EVENTS.md](docs/REMOTE_EVENTS.md)** - 🆕 RemoteEvent reference with payload documentation

### Project Structure

The repository is organized into clear, logical sections:

- **`src/server/`** - Server-side game logic
  - **`AI/`** - Artificial intelligence scripts (ZombieBrain)
  - **`Tests/`** - Test and debug scripts (requires `GameConfig.DEBUG = true`)
- **`src/client/`** - Client-side UI and controls
  - **`UI/`** - User interface scripts
  - **`FPS/`** - First-person system modules
- **`src/shared/`** - Shared configurations and utilities
- **`docs/`** - 🆕 Project documentation

For detailed information about the project structure, naming conventions, and development guidelines, see [docs/STRUCTURE.md](docs/STRUCTURE.md).

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎯 Current Features

The game currently includes:
- ✅ **First-Person Shooter Experience** (NEW!)
  - First-person camera with configurable FOV
  - Recoil, spread, and ADS mechanics
  - Dynamic crosshair and hitmarkers
  - Controller-friendly menus
- ✅ Multiplayer support (up to 8 players)
- ✅ Wave-based zombie combat with progressive difficulty
- ✅ Server-authoritative raycast weapon system
- ✅ Weapon shop with upgrades (damage, fire rate)
- ✅ Cure-crafting puzzle system (5 components × 5 pieces each)
- ✅ Alliance system with betrayal mechanics
- ✅ Resource spawning and inventory management
- ✅ Dynamic map support with MapManager
- ✅ Base health and player tracking systems
- ✅ Victory/defeat conditions

## 🎮 FPS Controls & Configuration

- The new first-person camera runs client-side (see `src/client/FPS/FirstPersonController.client.lua`).
- Tune FOV, mouse sensitivity, smoothing, and head offsets in `src/shared/FPSConfig.lua`.
- Mouse cursor is hidden and locked to center during play; Roblox shift-lock is suppressed.
- Characters are locally hidden in first-person to reduce clipping—disable by setting `HideCharacterInFirstPerson` to `false` in the config.
- To adjust how quickly the camera responds, tweak `MouseSensitivity` (base multiplier) and `MouseSmoothing` (higher values = more smoothing, slower response) in `FPSConfig`.

## 📚 Documentation

For detailed information, see:
- **[INSTALLATION.md](INSTALLATION.md)** - Complete setup guide for Roblox Studio
- **[API_DOCUMENTATION.md](API_DOCUMENTATION.md)** - API reference and system interactions
- **[FPS_DOCUMENTATION.md](FPS_DOCUMENTATION.md)** - ✨ FPS system documentation and tuning guide
- **[WEAPON_ANIMATIONS.md](WEAPON_ANIMATIONS.md)** - ✨ NEW: Weapon animation system guide
- **[ANIMATION_CREATION_GUIDE.md](ANIMATION_CREATION_GUIDE.md)** - ✨ NEW: Step-by-step animation creation tutorial
- **[GAME_DESIGN.md](GAME_DESIGN.md)** - Game design document and mechanics
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Implementation details and progress
- **[PUZZLE_SYSTEM.md](PUZZLE_SYSTEM.md)** - Puzzle mechanics, types, and integration guide

## 🤔 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests
- Improve documentation

---

**Created by**: Carnage-Joker  
**Repository**: [github.com/Carnage-Joker/AwavePuzz](https://github.com/Carnage-Joker/AwavePuzz)
