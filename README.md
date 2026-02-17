# Aether Wave: Convergence

*Survive. Cooperate. Betray.*

A multiplayer Roblox first-person shooter zombie survival game featuring wave-based combat, cure-crafting puzzles, alliance systems, dynamic music, achievements, and an immersive narrative experience with full FPS mechanics!

> **📊 NEW: [Production Readiness Report](PRODUCTION_READINESS_REPORT.md)** - Comprehensive overview of all game features, what's working, what's not, and how to get production-ready (95% complete!)

## 🎮 Game Overview

**Aether Wave: Convergence** is a cooperative survival FPS where up to 8 players defend a base against increasingly difficult waves of zombies infected by the Aether Virus. Players must work together (or betray each other) to collect cure components and craft a cure before the base is destroyed or all players are eliminated.

### 🎬 Immersive Narrative Experience

The game features a compelling story-driven introduction and conclusion:

- **Title Screen**: "Aether Wave: Convergence" with atmospheric presentation
- **Epic Epilogue**: A multi-page cinematic intro that explains:
  - The **Aether Virus outbreak** and how it transforms humans
  - The **five cure components** needed to stop the convergence
  - The **tension between survival and betrayal**
  - Why **alliances are crucial** even with the risk of backstabbing
- **Victory Credits**: 🆕 Scrolling credits showing survivors, their stats, and development team
- **Skippable**: Press ESC to skip the intro and jump straight into action
- **Emotional storytelling** that emphasizes the human cost and moral choices

### 🏆 NEW: Achievement System

Track your accomplishments with an achievement system featuring:

- **Combat Achievements**: First Blood, Headshot Specialist, Last Stand
- **Cooperation Achievements**: Trusted Ally, Team Player
- **Betrayal Achievements**: The Betrayer, Lone Wolf  
- **Cure Achievements**: Component Collector, The Savior
- **Challenge Achievements**: Perfect Run, Clutch Save
- **Rarity System**: Common, Uncommon, Rare, Epic, Legendary
- **Visual Notifications**: Achievement pop-ups with icons and descriptions

### 🎵 NEW: Dynamic Music System

Atmospheric music that adapts to the game:

- **Title Theme**: Plays during title screen and epilogue
- **Gameplay Ambient**: Calm ambient music during low-intensity moments
- **Combat Intense**: Dramatic music during high-wave combat
- **Victory Theme**: Triumphant music when the cure is complete
- **Defeat Theme**: Somber music when the base falls
- **Credits Music**: Reflective music during victory credits
- **Smooth Transitions**: Music fades between tracks for seamless experience

### 🎖️ NEW: Victory Credits

When you complete the cure:

- **Survivor List**: Shows all players who survived with their stats
- **Kill Counts**: Individual player kill statistics
- **Component Collection**: Shows who contributed most to the cure
- **Development Credits**: Game design and development team
- **Special Thanks**: Community acknowledgments
- **Closing Message**: "Thank you for playing. The choice was always yours."
- **Auto-Scrolling**: Credits scroll cinematically from bottom to top

## 🔫 First-Person Shooter Features

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
- Strategic base defense mechanics with **Defensive Base Camp**:
  - **Automatically created** at map center
  - **30x30 stud platform** with defensive walls (12 studs high)
  - **4 gates** at cardinal directions (semi-transparent, passable)
  - **8 cover positions** arranged in a circle for tactical defense
  - Configurable via `GameConfig.AUTO_CREATE_BASE_CAMP`
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

**✨ NEW: Repository restructured to match Roblox Studio layout!**

```
AwavePuzz/
├── ServerScriptService/           # Server-side game logic
│   ├── AI/                        # Zombie AI and controllers
│   │   ├── ZombieBrain.lua        # Main zombie AI
│   │   ├── AIDirector.lua         # AI behavior manager
│   │   └── ...                    # Other AI systems
│   ├── GameManager.lua            # Main game controller
│   ├── PlayerManager.lua          # Player data and health management
│   ├── WaveManager.lua            # Wave spawning and progression
│   ├── WeaponService.lua          # Weapon system
│   ├── FPSWeaponService.lua       # FPS ammo/reload validation
│   └── ...                        # Other server services
├── ReplicatedStorage/             # Shared resources
│   ├── Shared/                    # Shared modules (configs, utils)
│   │   ├── GameConfig.lua         # Game configuration
│   │   ├── FPSConfig.lua          # FPS-specific configuration
│   │   ├── WeaponConfig.lua       # Weapon definitions
│   │   └── ...                    # Other shared configs
│   ├── RemoteEvents/              # 🆕 RemoteEvent instances (created at runtime)
│   └── Animations/                # 🆕 Animation definitions
│       └── Weapons/               # Weapon-specific animations
├── StarterPlayer/                 # Player initialization
│   └── StarterPlayerScripts/      # Client-side controllers
│       ├── BootClient.lua         # 🆕 Client entry point (LocalScript)
│       ├── Modules/               # Client modules
│       │   ├── FPSWeaponController.lua    # Weapon mechanics
│       │   ├── FPSMovement.lua            # Movement system
│       │   └── UI/                        # UI modules (all ModuleScripts)
│       └── FPS/                   # FPS camera system
├── StarterGui/                    # UI (handled by boot system now)
├── ServerStorage/                 # Server-only assets
│   ├── DevOnly/                   # 🆕 Disabled/legacy/test files (not loaded)
│   ├── Maps/                      # Map models
│   ├── Models/                    # Weapon/object models
│   └── ZombieModels/              # Zombie models
├── Archive/Legacy/Code/           # Archived legacy code (3 levels deep)
├── docs/                          # Documentation
│   ├── implementation/            # Implementation summaries
│   ├── features/                  # Feature documentation
│   ├── testing/                   # Testing guides
│   ├── summaries/                 # Historical summaries
│   └── STRUCTURE.md               # Complete structure guide
├── ASSET_PLACEHOLDERS.md          # Asset requirements guide
├── README.md
└── LICENSE
```

> **Important Notes**:
> - The repository uses Roblox service names (ServerScriptService, ReplicatedStorage, etc.) to match the game structure exactly
> - All Lua files use simple `.lua` extensions without dots in names (e.g., `MainServerScript.lua` NOT `Main.server.lua`) to prevent sync tool compatibility issues
> - See [INSTALLATION.md](INSTALLATION.md) for complete setup guide with exact file structure
> - See [docs/STRUCTURE.md](docs/STRUCTURE.md) for detailed architecture guide

## 📖 The Story: The Aether Wave

Twenty-three days ago, the Aether Energy Facility detected an anomaly. What began as a groundbreaking quantum research project became humanity's greatest threat. The **Aether Virus** (A-Wave strain) escaped containment.

### The Outbreak

The infected don't die—they **change**. The A-Wave virus rewrites neural pathways, consuming rational thought. What remains is driven by a singular purpose: spread the convergence. They were your friends, your colleagues, your family. Now they're something else entirely.

### The Cure

Five components scattered across the facility hold the key to salvation:
- **Chemical A** - Stabilizes neural pathways
- **Chemical B** - Reverses cellular decay  
- **Biological Sample** - Provides antibody template
- **Research Notes** - Contains synthesis protocol
- **Catalyst** - Triggers the reaction

Together, they can save what's left of humanity. But time is running out.

### The Choice

You're not alone. Other survivors remain. In this nightmare, **alliance is survival**. Together, you can cover more ground, defend the base, and complete the cure.

But resources are scarce, and the cure only needs one person to complete it. What happens when survival demands a choice? The facility's logs tell a dark story: the first research team had the cure within reach. They turned on each other. They all died.

**You can be different. You can work together. You can trust.**

Or you can repeat history. The choice is yours.

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

All game settings can be adjusted in `ReplicatedStorage/Shared/GameConfig.lua`:

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

**Note:** Test and debug scripts in `ServerStorage/DevOnly/` will only run when `GameConfig.DEBUG = true`.

## 🚀 Installation (Roblox Studio)

**✨ NEW: Simplified installation with restructured repository!**

For detailed setup instructions, see [INSTALLATION.md](INSTALLATION.md)

**Quick Start:**
1. Clone this repository
2. Open Roblox Studio
3. Create a new place or open an existing one
4. Copy directories directly to Roblox Studio:
   - `ServerScriptService/` → game.ServerScriptService
   - `ReplicatedStorage/Shared/` → game.ReplicatedStorage.Shared
   - `StarterPlayer/StarterPlayerScripts/` → game.StarterPlayer.StarterPlayerScripts
   - `StarterGui/` scripts → game.StarterGui (as LocalScript instances)
5. Set up the game environment (spawn points, base, etc.)
6. Replace placeholder .txt files with actual assets (see [ASSET_PLACEHOLDERS.md](ASSET_PLACEHOLDERS.md))
7. Test in multiplayer mode

**Repository Structure Changes:**
- ✅ Directory names now match Roblox services exactly
- ✅ No file reorganization needed during setup
- ✅ Placeholder files for all required assets
- ✅ Old `src/` structure archived in `Archive/Legacy/Code/`

For complete step-by-step instructions, asset creation guides, and structure information, refer to:
- [INSTALLATION.md](INSTALLATION.md) - Complete setup guide
- [ASSET_PLACEHOLDERS.md](ASSET_PLACEHOLDERS.md) - Asset requirements
- [docs/STRUCTURE.md](docs/STRUCTURE.md) - Project structure guide

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

**📖 Complete Documentation Index: [DOCUMENTATION.md](DOCUMENTATION.md)**

#### Core Documentation
- **[README.md](README.md)** - This file - game overview and quick start
- **[INSTALLATION.md](INSTALLATION.md)** - Complete setup guide for Roblox Studio
- **[GAME_DESIGN.md](GAME_DESIGN.md)** - Game design document and mechanics
- **[QUICKSTART.md](QUICKSTART.md)** - Quick start guide for the restructured repository
- **[SECURITY.md](SECURITY.md)** - 🆕 Security measures and anti-exploit documentation
- **[BOOT_SAFETY_GUIDE.md](BOOT_SAFETY_GUIDE.md)** - 🆕 Boot system safety, entry points, and testing
- **[BOOT_SAFETY_QUICK_REFERENCE.md](BOOT_SAFETY_QUICK_REFERENCE.md)** - 🆕 Quick reference for boot system changes
- **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)** - 🆕 Production deployment checklist

#### Technical References
- **[API_DOCUMENTATION.md](API_DOCUMENTATION.md)** - Complete API reference for all modules
- **[CODE_ARCHITECTURE.md](CODE_ARCHITECTURE.md)** - Code organization and architectural decisions
- **[docs/STRUCTURE.md](docs/STRUCTURE.md)** - Project structure and organization guide
- **[docs/REMOTE_EVENTS.md](docs/REMOTE_EVENTS.md)** - RemoteEvent reference with payload documentation

#### Implementation Documentation
- **[docs/implementation/overview.md](docs/implementation/overview.md)** - Implementation status and feature summary
- **[docs/implementation/alliance-v2.md](docs/implementation/alliance-v2.md)** - Alliance pooling and betrayal system
- **[docs/implementation/base-camp.md](docs/implementation/base-camp.md)** - Base camp system implementation
- **[docs/implementation/device-compatibility.md](docs/implementation/device-compatibility.md)** - Cross-platform support

#### Feature Documentation
- **[docs/features/puzzle-system.md](docs/features/puzzle-system.md)** - Puzzle mechanics and integration
- **[docs/features/zombie-ai.md](docs/features/zombie-ai.md)** - Zombie AI behavior and improvements
- **[docs/features/alliance-system.md](docs/features/alliance-system.md)** - Alliance pooling system
- **[docs/features/base-camp.md](docs/features/base-camp.md)** - Base camp feature documentation

#### System-Specific Documentation
- **[FPS_DOCUMENTATION.md](FPS_DOCUMENTATION.md)** - FPS system documentation and tuning guide
- **[WEAPON_ANIMATIONS.md](WEAPON_ANIMATIONS.md)** - Weapon animation system guide
- **[ANIMATION_CREATION_GUIDE.md](ANIMATION_CREATION_GUIDE.md)** - Step-by-step animation creation tutorial
- **[ANIMATION_QUICK_REFERENCE.md](ANIMATION_QUICK_REFERENCE.md)** - Quick reference for animation configuration

#### Testing Guides
- **[tests/README.md](tests/README.md)** - 🆕 Complete test suite documentation (boot, security, leaks, race conditions)
- **[tests/boot_smoke_tests.lua](tests/boot_smoke_tests.lua)** - 🆕 Boot system validation tests (12 tests)
- **[tests/security_validation_tests.lua](tests/security_validation_tests.lua)** - Security configuration tests (11 tests)
- **[docs/testing/TESTING_ALLIANCE_SYSTEM.md](docs/testing/TESTING_ALLIANCE_SYSTEM.md)** - Alliance system testing
- **[docs/testing/TESTING_MAP_AND_LOBBY.md](docs/testing/TESTING_MAP_AND_LOBBY.md)** - Map and lobby testing

### Project Structure

**✨ RESTRUCTURED:** Repository now matches Roblox Studio layout!

The repository is organized to match Roblox Studio services exactly:

- **`ServerScriptService/`** - Server-side game logic (was `src/server/`)
  - **`AI/`** - Artificial intelligence scripts (ZombieBrain, AIDirector, etc.)
- **`ReplicatedStorage/`** - Shared resources
  - **`Shared/`** - Configuration and utility modules (was `src/shared/`)
  - **`RemoteEvents/`** - 🆕 RemoteEvent placeholders (58 files)
  - **`Animations/`** - 🆕 Animation placeholders (36 files)
- **`StarterPlayer/StarterPlayerScripts/`** - Client-side controllers (was `src/client/`)
  - **`Modules/`** - Client modules and UI
  - **`FPS/`** - First-person system modules
- **`StarterGui/`** - 🆕 UI LocalScripts (was `src/client/UI/`)
- **`ServerStorage/`** - Server-only assets
  - **`Maps/`** - 🆕 Map models (placeholders)
  - **`Models/`** - 🆕 Weapon/object models (placeholders)
  - **`ZombieModels/`** - 🆕 Zombie models (placeholders)
  - **`DevOnly/`** - Dev tools (requires `GameConfig.DEBUG = true`)
- **`Archive/Legacy/Code/`** - 🆕 Archived legacy code (3 levels deep for safety)
- **`docs/`** - Project documentation

For detailed information about the structure, naming conventions, and documentation organization, see:
- [docs/STRUCTURE.md](docs/STRUCTURE.md) - Complete structure reference
- [DOCUMENTATION.md](DOCUMENTATION.md) - Documentation index

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎯 Current Features

The game currently includes:
- ✅ **First-Person Shooter Experience** (NEW!)
  - First-person camera with configurable FOV
  - Recoil, spread, and ADS mechanics
  - Dynamic crosshair and hitmarkers
  - Controller-friendly menus
- ✅ **Production-Ready Security** (NEW!)
  - Server-authoritative architecture
  - Anti-wallhack weapon validation (15 stud max fire distance)
  - Rate limiting and cooldown enforcement
  - Memory leak prevention with proper connection cleanup
  - Input validation and type checking
  - See [SECURITY.md](SECURITY.md) for complete details
- ✅ **Optimized Performance** (NEW!)
  - Proper resource cleanup on round end
  - Time-based debouncing to prevent race conditions
  - Death event connection lifecycle management
  - Efficient AI update loops with jitter
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
- ✅ Achievement system with rarity levels
- ✅ Dynamic music system
- ✅ Story-driven intro and credits

## 🛡️ Security Features

The game implements comprehensive security measures:

### Server Authority
- All damage calculations are server-side
- Currency changes are server-authoritative
- Ammo consumption is validated server-side
- Health modifications require server approval

### Anti-Exploit Measures
- **Weapon Fire Validation**: Origin position must be within 15 studs of player
- **Rate Limiting**: Fire rate, spectator cycling, map loading all have cooldowns
- **Input Validation**: All client payloads are type-checked and range-validated
- **Ownership Checks**: Players can only modify resources they own

### Performance & Stability
- Proper connection cleanup prevents memory leaks
- Time-based debouncing prevents race conditions
- Resource/item cleanup on round end
- Heartbeat connection tracking for shutdown cleanup

See [SECURITY.md](SECURITY.md) for complete security documentation.

## 🎮 FPS Controls & Configuration

- The first-person camera system is in `StarterPlayer/StarterPlayerScripts/FPS/FirstPersonCamera.lua`.
- Tune FOV, mouse sensitivity, smoothing, and head offsets in `ReplicatedStorage/Shared/FPSConfig.lua`.
- Mouse cursor is hidden and locked to center during play; Roblox shift-lock is suppressed.
- Characters are locally hidden in first-person to reduce clipping—disable by setting `HideCharacterInFirstPerson` to `false` in the config.
- To adjust how quickly the camera responds, tweak `MouseSensitivity` (base multiplier) and `MouseSmoothing` (higher values = more smoothing, slower response) in `FPSConfig`.

## 📚 Documentation

For detailed information, see the [Documentation](#documentation) section above for a complete list of guides and references.

## 🤔 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests
- Improve documentation

---

**Created by**: Carnage-Joker  
**Repository**: [github.com/Carnage-Joker/AwavePuzz](https://github.com/Carnage-Joker/AwavePuzz)
