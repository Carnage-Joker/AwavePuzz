# Installation Guide - AwavePuzz

This guide will help you set up and run the AwavePuzz zombie survival game in Roblox Studio.

## Prerequisites

- **Roblox Studio** (latest version)
- **Roblox Account** (for testing and publishing)
- Basic understanding of Roblox Studio interface
- This repository cloned or downloaded

## Table of Contents

1. [Quick Start](#quick-start)
2. [Detailed Setup](#detailed-setup)
3. [Map Configuration](#map-configuration)
4. [Testing](#testing)
5. [Troubleshooting](#troubleshooting)

---

## Quick Start

For experienced Roblox developers:

1. Open Roblox Studio
2. Create new place or open existing project
3. Import scripts from `src/` to appropriate locations:
   - `src/server/*` → ServerScriptService
   - `src/client/*` → StarterPlayer.StarterPlayerScripts
   - `src/shared/*` → ReplicatedStorage
4. Configure spawn points
5. Test in multiplayer

---

## Detailed Setup

### Step 1: Create or Open a Roblox Place

1. Launch **Roblox Studio**
2. Choose one of:
   - **New Place**: File → New → Baseplate
   - **Existing Place**: Open from your games

### Step 2: Project Structure Setup

Create the following folder structure in your Roblox game:

```
Workspace
├── Map (your game map)
├── Base (the central base to defend)
├── ZombieSpawnPoints (folder)
└── ResourceSpawnPoints (folder)

ServerScriptService
├── GameServer
├── PlayerManager
├── WaveManager
├── BaseManager
├── CureCraftingManager
└── ResourceSpawner

ServerStorage
└── (future: zombie models, etc.)

ReplicatedStorage
└── Shared
    ├── GameConfig
    └── GameState

StarterPlayer
└── StarterPlayerScripts
    └── ClientController

StarterGui
└── (future: UI elements)
```

### Step 3: Import Server Scripts

1. In **ServerScriptService**, create ModuleScripts for each server file from `src/server/`:
   
   **MainServer** (Script, not ModuleScript!)
   - Copy contents from `src/server/MainServer.lua`
   
   **GameManager**
   - Copy contents from `src/server/GameManager.lua`
   
   **PlayerManager**
   - Copy contents from `src/server/PlayerManager.lua`
   
   **WaveManager**
   - Copy contents from `src/server/WaveManager.lua`
   
   **BaseManager**
   - Copy contents from `src/server/BaseManager.lua`
   
   **Spawner**
   - Copy contents from `src/server/Spawner.lua`
   
   **CureService**
   - Copy contents from `src/server/CureService.lua`
   
   **AllianceService**
   - Copy contents from `src/server/AllianceService.lua`
   
   **WeaponService**
   - Copy contents from `src/server/WeaponService.lua`
   
   **ShopService**
   - Copy contents from `src/server/ShopService.lua`
   
   **MapManager**
   - Copy contents from `src/server/MapManager.lua`
   
   **ResourceSpawner**
   - Copy contents from `src/server/ResourceSpawner.lua`
   
   **AIScripts Folder**
   - Create folder "AIScripts" in ServerScriptService
   - Inside it, create ModuleScript "ZombieBrain"
   - Copy contents from `src/server/AIScripts/ZombieBrain.lua`

### Step 4: Import Shared Scripts

1. In **ReplicatedStorage**, create a folder named "Shared"
2. Inside "Shared", create ModuleScripts from `src/shared/`:
   
   **GameConfig**
   - Copy contents from `src/shared/GameConfig.lua`
   
   **GameState**
   - Copy contents from `src/shared/GameState.lua`
   
   **WaveConfig**
   - Copy contents from `src/shared/WaveConfig.lua`
   
   **ZombieTypes**
   - Copy contents from `src/shared/ZombieTypes.lua`
   
   **WeaponConfig**
   - Copy contents from `src/shared/WeaponConfig.lua`
   
   **MapConfig**
   - Copy contents from `src/shared/MapConfig.lua`

### Step 5: Import Client Scripts

1. In **StarterPlayer** → **StarterPlayerScripts**, create:
   
   **ClientController**
   - Insert ModuleScript
   - Copy contents from `src/client/ClientController.lua`
   
   **WeaponController.client**
   - Insert LocalScript
   - Copy contents from `src/client/WeaponController.client.lua`

2. In **StarterGui**, create LocalScripts for UI from `src/client/UI/`:
   
   **WaveUI**
   - Copy contents from `src/client/UI/WaveUI.client.lua`
   
   **BaseHealthUI**
   - Copy contents from `src/client/UI/BaseHealthUI.client.lua`
   
   **CureUI**
   - Copy contents from `src/client/UI/CureUI.client.lua`
   
   **AllianceUI**
   - Copy contents from `src/client/UI/AllianceUI.client.lua`
   
   **ShopUI**
   - Copy contents from `src/client/UI/ShopUI.client.lua`
   
   **InventoryUI**
   - Copy contents from `src/client/UI/InventoryUI.client.lua`

### Step 6: Create ServerStorage Structure

1. In **ServerStorage**, create a folder named "Maps"
2. (Optional) Add custom map models to the Maps folder
   - Each map should have "ZombieSpawnPoints" and "ResourceSpawnPoints" folders
   - The game will use a default map if none are provided

3. (Optional) Create a folder named "ZombieModels" for custom zombie models
   - Add R15 or R6 character models with Humanoid and HumanoidRootPart
   - Name them: Walker, Runner, Brute, Spitter, Boss
   - The game will create basic zombies if none are provided

### Step 7: Verify Script Structure

All scripts should be using proper Roblox service imports. The scripts in `src/` already use correct patterns like:

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- For requiring modules:
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlayerManager = require(script.Parent.PlayerManager)
```

No changes needed - just copy the files as-is from `src/` to Roblox Studio.

---

## Map Configuration

### Creating the Base

1. In **Workspace**, create a Part or Model named "Base"
2. Position it in the center of your map
3. Add a Script to the Base to handle damage visualization (optional)

### Setting Up Zombie Spawn Points

1. In **Workspace**, create a Folder named "ZombieSpawnPoints"
2. Add multiple Parts (or just use their Position)
3. Name them "SpawnPoint1", "SpawnPoint2", etc.
4. Position them around the perimeter of your play area
5. These mark where zombies will spawn

### Setting Up Resource Spawn Points

1. In **Workspace**, create a Folder named "ResourceSpawnPoints"
2. Add multiple Parts
3. Name them "ResourcePoint1", "ResourcePoint2", etc.
4. Position them throughout the map
5. Players will find cure components at these locations

### Recommended Map Layout

```
+-----------------------------------+
|                                   |
|  [Zombie]      [Resource]        |
|                                   |
|         [Resource]                |
|  [Zombie]         [BASE]  [Zombie]|
|                   [Resource]      |
|                                   |
|  [Resource]               [Zombie]|
|                                   |
+-----------------------------------+
```

**Tips:**
- Keep the base centrally located
- Distribute spawn points evenly around edges
- Place resources at varying distances from base
- Add cover and obstacles for tactical gameplay

---

## Testing

### Local Testing (Single Player)

1. Click **Play** button in Roblox Studio
2. Game should start automatically
3. Test basic functionality:
   - Wave spawning
   - Player health
   - Base health tracking
   - Component collection

### Multiplayer Testing

1. Click dropdown next to Play button
2. Select number of players (2-8)
3. Click **Start**
4. Test with multiple clients:
   - Alliance formation
   - Betrayal mechanics
   - Component sharing
   - Cooperative defense

### Testing Checklist

- [ ] Game starts correctly
- [ ] Players can join (up to 8)
- [ ] Waves spawn zombies
- [ ] Zombies attack players and base
- [ ] Health systems work
- [ ] Components can be collected
- [ ] Cure progress updates
- [ ] Alliances can be formed/broken
- [ ] Victory condition works (cure crafted)
- [ ] Defeat conditions work (base destroyed / all dead)

---

## Troubleshooting

### Common Issues

#### Issue: "Script is not a ModuleScript"
**Solution:** Make sure you created ModuleScripts, not regular Scripts, for the modules.

#### Issue: "Attempt to index nil value"
**Solution:** Check your `require()` paths are correct. Use absolute paths like `game.ReplicatedStorage.Shared.GameConfig`.

#### Issue: "Player not being added"
**Solution:** Ensure PlayerManager is properly initialized before players join.

#### Issue: "Waves not starting"
**Solution:** Check that MainServer script is running and calling `gameServer:startGame()`.

#### Issue: "Components not spawning"
**Solution:** 
- Verify ResourceSpawnPoints folder exists in Workspace
- Ensure spawn points are properly positioned
- Check ResourceSpawner is initialized in GameServer

### Debug Output

Add print statements to track game flow:

```lua
-- In MainServer.lua
print("Game server initialized")

-- When wave starts
print("Wave " .. waveNumber .. " started!")

-- When player collects component
print(player.Name .. " collected " .. componentName)
```

### Console Commands

You can add admin commands for testing:

```lua
-- In MainServer.lua
game.ReplicatedStorage.AdminCommand.OnServerEvent:Connect(function(player, command)
    if command == "skipwave" then
        gameServer:startNextWave()
    elseif command == "healbase" then
        gameServer.baseManager:repairBase(1000)
    end
end)
```

---

## Configuration

To adjust game balance, edit `src/shared/GameConfig.lua`:

```lua
-- Make game easier
GameConfig.STARTING_HEALTH = 150
GameConfig.BASE_HEALTH = 1500
GameConfig.ZOMBIE_DAMAGE = 5

-- Make game harder  
GameConfig.ZOMBIE_HEALTH_MULTIPLIER = 1.5
GameConfig.ZOMBIES_PER_WAVE_MULTIPLIER = 2.0
GameConfig.WAVE_DELAY = 20
```

---

## Next Steps

After basic setup:

1. **Add Zombie Models**
   - Create or import zombie characters
   - Add zombie AI scripts
   - Connect to WaveManager spawn system

2. **Create UI**
   - Health bars
   - Wave counter
   - Cure progress bar
   - Alliance indicators

3. **Add Visual Effects**
   - Spawn effects
   - Damage indicators
   - Victory/defeat animations

4. **Implement Remote Events**
   - Client-server communication
   - Alliance requests
   - Component collection feedback

5. **Polish and Balance**
   - Playtest extensively
   - Adjust difficulty curve
   - Add sound effects
   - Optimize performance

---

## Publishing

When ready to publish:

1. File → Publish to Roblox
2. Choose a name and description
3. Set game icon and thumbnail
4. Configure settings:
   - Max players: 8
   - Genre: Adventure / Survival
   - Enable filtering enabled
5. Make it public or keep private for testing

---

## Support

For issues or questions:
- Check the [API Documentation](API_DOCUMENTATION.md)
- Review the [Game Design Document](GAME_DESIGN.md)
- Visit the GitHub repository issues page

---

**Installation Guide Version**: 1.0  
**Last Updated**: 2025-11-15  
**Compatible with**: Roblox Studio (Latest)