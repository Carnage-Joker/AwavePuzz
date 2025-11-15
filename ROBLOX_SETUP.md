# Quick Setup Guide for Roblox Studio

This guide explains how to quickly set up AwavePuzz in Roblox Studio.

## Directory Structure in Roblox

Here's how to organize the scripts in your Roblox game:

```
Workspace
├── Base (Part or Model with NumberValue named "Health")
├── ZombieSpawnPoints (Folder with Parts)
├── CureStations (Folder with Parts or Models)
└── Zombies (Created automatically by spawner)

ServerScriptService
├── MainServer (Script - not ModuleScript!)
├── GameManager (ModuleScript)
├── Spawner (ModuleScript)
├── AllianceService (ModuleScript)
├── CureService (ModuleScript)
├── BaseManager (ModuleScript)
├── PlayerManager (ModuleScript)
├── WaveManager (ModuleScript)
├── ResourceSpawner (ModuleScript)
├── CureCraftingManager (ModuleScript)
├── GameServer (ModuleScript)
└── AIScripts (Folder)
    └── ZombieBrain (ModuleScript)

ServerStorage
└── ZombieModels (Folder)
    ├── Walker (Model - optional, will create basic if missing)
    ├── Runner (Model - optional)
    ├── Brute (Model - optional)
    ├── Spitter (Model - optional)
    └── Boss (Model - optional)

ReplicatedStorage
├── Shared (Folder)
│   ├── GameConfig (ModuleScript)
│   ├── GameState (ModuleScript)
│   ├── ZombieTypes (ModuleScript)
│   └── WaveConfig (ModuleScript)
└── RemoteEvents (Folder - created automatically)

StarterGui
├── WaveUI (LocalScript)
├── BaseHealthUI (LocalScript)
├── CureUI (LocalScript)
└── AllianceUI (LocalScript)

StarterPlayer
└── StarterPlayerScripts
    └── ClientController (ModuleScript)
```

## Quick Setup Steps

### 1. Create Folder Structure

1. Open Roblox Studio
2. Create the folder structure shown above
3. For each ModuleScript/Script, paste the corresponding code from `src/`

### 2. Setup Workspace

**Base:**
```
1. Create a Part or Model in Workspace named "Base"
2. Add a NumberValue inside it named "Health"
3. Set Health.Value to 1000
```

**Zombie Spawn Points:**
```
1. Create a Folder in Workspace named "ZombieSpawnPoints"
2. Add 4-8 Parts around your map perimeter
3. Name them SpawnPoint1, SpawnPoint2, etc.
```

**Cure Stations:**
```
1. Create a Folder in Workspace named "CureStations"
2. Add 1-3 Parts or Models where players can interact
3. ProximityPrompts will be added automatically by CureService
```

### 3. Import Scripts

#### ServerScriptService

Create these as **ModuleScripts** (except MainServer which is a **Script**):

| File | Type | Source Location |
|------|------|----------------|
| MainServer | Script | `src/server/MainServer.lua` |
| GameManager | ModuleScript | `src/server/GameManager.lua` |
| Spawner | ModuleScript | `src/server/Spawner.lua` |
| AllianceService | ModuleScript | `src/server/AllianceService.lua` |
| CureService | ModuleScript | `src/server/CureService.lua` |
| BaseManager | ModuleScript | `src/server/BaseManager.lua` |
| PlayerManager | ModuleScript | `src/server/PlayerManager.lua` |
| WaveManager | ModuleScript | `src/server/WaveManager.lua` |
| ResourceSpawner | ModuleScript | `src/server/ResourceSpawner.lua` |
| CureCraftingManager | ModuleScript | `src/server/CureCraftingManager.lua` |
| GameServer | ModuleScript | `src/server/GameServer.lua` |
| AIScripts/ZombieBrain | ModuleScript | `src/server/AIScripts/ZombieBrain.lua` |

#### ReplicatedStorage

Create a Folder named "Shared", then add these **ModuleScripts**:

| File | Source Location |
|------|----------------|
| GameConfig | `src/shared/GameConfig.lua` |
| GameState | `src/shared/GameState.lua` |
| ZombieTypes | `src/shared/ZombieTypes.lua` |
| WaveConfig | `src/shared/WaveConfig.lua` |

#### StarterGui

Create these as **LocalScripts**:

| File | Source Location |
|------|----------------|
| WaveUI | `src/client/UI/WaveUI.client.lua` |
| BaseHealthUI | `src/client/UI/BaseHealthUI.client.lua` |
| CureUI | `src/client/UI/CureUI.client.lua` |
| AllianceUI | `src/client/UI/AllianceUI.client.lua` |

#### StarterPlayerScripts

| File | Type | Source Location |
|------|------|----------------|
| ClientController | ModuleScript | `src/client/ClientController.lua` |

### 4. Test the Game

1. Click **Play** (or press F5)
2. You should see:
   - Console message: "=== AwavePuzz Server Starting ==="
   - UI elements appearing (Wave info, Base health, Cure progress)
   - Game will start automatically after 5 seconds
   - Basic zombie models will spawn (green blocks)

### 5. Controls

- **Tab**: Open Alliance Menu
- **Click on Cure Progress**: View detailed component list
- **Walk near Cure Stations**: Interact with ProximityPrompt

## Common Issues

### "attempt to call a nil value"
- Check that all require() paths are correct
- Use `game.ReplicatedStorage.Shared.GameConfig` format

### "ZombieModels folder not found"
- Create `ServerStorage/ZombieModels` folder
- Game will create basic zombie models automatically if missing

### "No spawn points available"
- Create `Workspace/ZombieSpawnPoints` folder
- Add at least one Part inside it

### UI not showing
- Make sure scripts are **LocalScripts** in StarterGui
- Check that ReplicatedStorage/RemoteEvents exists (auto-created)

## Next Steps

### Add Custom Zombie Models
1. Create R15 or R6 character models
2. Must have Humanoid and HumanoidRootPart
3. Place in ServerStorage/ZombieModels
4. Name them: Walker, Runner, Brute, Spitter, Boss

### Add Weapon System
1. Create weapon tool
2. Implement raycast shooting
3. Connect to DealDamage RemoteEvent
4. Reference zombie.Humanoid:TakeDamage()

### Customize Configuration
Edit `ReplicatedStorage/Shared/GameConfig.lua`:
- Adjust player/base health
- Change wave timing
- Modify zombie stats
- Tune cure requirements

## Testing Multiplayer

1. Click dropdown next to Play button
2. Select "2 Players" or more (up to 8)
3. Test alliance system
4. Test cure collection
5. Test wave progression

## Performance Tips

- Limit max zombies on screen (adjust wave configs)
- Use simple zombie models initially
- Optimize pathfinding interval if needed
- Use StreamingEnabled for large maps

---

**Need Help?**
- Check API_DOCUMENTATION.md for detailed function reference
- Review GAME_DESIGN.md for game mechanics
- See INSTALLATION.md for detailed setup

Happy game development! 🎮🧟‍♂️