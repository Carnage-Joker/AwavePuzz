# AwavePuzz - Zombie Wave Survival Game

A multiplayer Roblox zombie survival game featuring wave-based combat, cure-crafting puzzles, and alliance systems.

## 🎮 Game Overview

**AwavePuzz** is a cooperative survival game where up to 8 players defend a base against increasingly difficult waves of zombies. Players must work together (or betray each other) to collect cure components and craft a cure before the base is destroyed or all players are eliminated.

## 🌟 Key Features

### 1. **Multiplayer Support**
- Up to 8 players per server
- Real-time cooperative gameplay
- Player health tracking and death system

### 2. **Wave-Based Zombie Combat**
- Progressive difficulty scaling
- Zombies get stronger and more numerous each wave
- Strategic base defense mechanics
- Base health system with damage tracking

### 3. **Cure-Crafting Puzzle System**
- 5 unique cure components to collect:
  - Chemical A
  - Chemical B
  - Biological Sample
  - Research Notes
  - Catalyst
- Each component requires 5 pieces to complete
- Resources spawn randomly around the map
- Progress tracking system

### 4. **Alliance System**
- Team up with other players for better survival
- Allied players can't damage each other
- Betrayal mechanics with cooldown system
- Strategic decision-making between cooperation and competition

### 5. **Win/Lose Conditions**
**Victory:** Successfully craft the cure by collecting all required components

**Defeat:** Game ends when:
- Base health reaches zero
- All players are eliminated

## 📁 Project Structure

```
AwavePuzz/
├── src/
│   ├── server/          # Server-side game logic
│   │   ├── GameServer.lua         # Main game controller
│   │   ├── PlayerManager.lua      # Player data and health management
│   │   ├── WaveManager.lua        # Wave spawning and progression
│   │   ├── BaseManager.lua        # Base health and defense
│   │   ├── CureCraftingManager.lua # Cure puzzle system
│   │   └── ResourceSpawner.lua    # Resource spawn management
│   ├── client/          # Client-side UI and controls
│   │   └── ClientController.lua   # Client game controller
│   └── shared/          # Shared modules
│       ├── GameConfig.lua         # Game configuration and constants
│       └── GameState.lua          # Game state management
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
- Can form and break alliances
- Collect cure components to contribute to victory

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

## 🔧 Configuration

All game settings can be adjusted in `src/shared/GameConfig.lua`:

```lua
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

## 🚀 Installation (Roblox Studio)

1. Clone this repository
2. Open Roblox Studio
3. Create a new place or open an existing one
4. Import the `src` folder structure into your game:
   - Place `server` scripts in `ServerScriptService`
   - Place `client` scripts in `StarterPlayer.StarterPlayerScripts`
   - Place `shared` modules in `ReplicatedStorage`
5. Set up the game environment (spawn points, base, etc.)
6. Configure spawn points in the map for resources
7. Test in multiplayer mode

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
- **Language**: Lua
- **Platform**: Roblox
- **Architecture**: Modular server-client system
- **Design Pattern**: Object-oriented with manager classes

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎯 Future Enhancements

Potential features for future development:
- Weapon and upgrade systems
- Multiple base locations
- Special zombie types
- Power-ups and abilities
- Leaderboard system
- Custom game modes
- Additional puzzle mechanics

## 🤔 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests
- Improve documentation

---

**Created by**: Carnage-Joker  
**Repository**: [github.com/Carnage-Joker/AwavePuzz](https://github.com/Carnage-Joker/AwavePuzz)
