-- @ScriptType: Script
# Quick Start Guide - Restructured Repository

**Date**: 2025-12-25  
**Repository Version**: 2.0 (Restructured)

## What Changed?

The AwavePuzz repository has been **completely restructured** to match the exact Roblox Studio directory layout. This makes installation and development much simpler!

### Before → After

| Old Structure | New Structure |
|---------------|---------------|
| `src/server/` | `ServerScriptService/` |
| `src/shared/` | `ReplicatedStorage/Shared/` |
| `src/client/` | `StarterPlayer/StarterPlayerScripts/` |
| `src/client/UI/` | `StarterGui/` |
| No placeholders | 109 asset placeholders created |

## 🚀 Getting Started (5 Steps)

### 1. Clone the Repository

```bash
git clone https://github.com/Carnage-Joker/AwavePuzz.git
cd AwavePuzz
```

### 2. Open Roblox Studio

- Launch Roblox Studio
- Create a new Baseplate or open existing place
- Ensure you have edit permissions

### 3. Copy Directories to Roblox

Simply drag and drop or copy the following folders:

```
AwavePuzz Repository → Roblox Studio
────────────────────────────────────
ServerScriptService/     → game.ServerScriptService
ReplicatedStorage/       → game.ReplicatedStorage
StarterPlayer/           → game.StarterPlayer
StarterGui/ (files)      → game.StarterGui (as LocalScript instances)
ServerStorage/           → game.ServerStorage (optional assets)
```

**Important**: When copying `StarterGui/` files, create them as **LocalScript** instances in Roblox Studio, not ModuleScripts.

### 4. Set Up Game Environment

In Roblox Studio Workspace, create:

1. **Base** (Part or Model)
   - Central base that players defend
   - Named "Base"

2. **ZombieSpawnPoints** (Folder)
   - Add 10-20 Parts around the map perimeter
   - Zombies spawn at these locations

3. **ResourceSpawnPoints** (Folder)
   - Add 15-25 Parts throughout the map
   - Cure components spawn here

### 5. Test the Game

- Press **Play** (F5) in Roblox Studio
- Test in **Local Server** mode (multiple players)
- Check Output window for any errors

**That's it!** The game should now be running.

## 📦 What's Included

### Active Code (Ready to Use)
- ✅ 27 Server scripts in `ServerScriptService/`
- ✅ 13 Shared config modules in `ReplicatedStorage/Shared/`
- ✅ 27 Client scripts in `StarterPlayer/StarterPlayerScripts/`
- ✅ 17 UI scripts in `StarterGui/`
- ✅ **Total: 84 Lua files**

### Placeholder Files (Need Creation)
- 📝 58 RemoteEvent placeholders (auto-created at runtime)
- 📝 36 Animation placeholders (weapon animations)
- 📝 15 Model placeholders (weapons, zombies, maps)
- 📝 **Total: 109 placeholders**

### Archived Code (Reference Only)
- 🗃️ Legacy implementations in `Archive/Legacy/Code/`
- 🗃️ Original `src/` structure backed up
- ⚠️ Do NOT use archived code in production

## 🎮 Optional: Create Assets

The game works without custom assets, but you can enhance it:

### Priority 1: Weapon Models
Create 3D weapon models for better visuals:
- Pistol, SMG, Shotgun, Rifle, AssaultRifle
- See `ServerStorage/Models/_README.txt` for requirements

### Priority 2: Weapon Animations
Animate weapon actions for polish:
- Idle, Fire, Reload, Equip, Sprint, ADS
- See `ReplicatedStorage/Animations/Weapons/` for structure
- Guide: [ANIMATION_CREATION_GUIDE.md](ANIMATION_CREATION_GUIDE.md)

### Priority 3: Zombie Models
Create custom zombie rigs for variety:
- Walker, Runner, Brute, Spitter, Boss
- See `ServerStorage/ZombieModels/_README.txt` for specs

### Priority 4: Custom Maps
Build themed environments:
- Research Facility, Desert Outpost, Urban Ruins
- Must include ZombieSpawnPoints and ResourceSpawnPoints folders
- See `ServerStorage/Maps/_README.txt` for layout

**Asset Creation Guide**: [ASSET_PLACEHOLDERS.md](ASSET_PLACEHOLDERS.md)

## 🔧 Configuration

All game settings are in `ReplicatedStorage/Shared/GameConfig.lua`:

```lua
-- Player Settings
MAX_PLAYERS = 8
STARTING_HEALTH = 100

-- Wave Settings
WAVE_DELAY = 30
BASE_ZOMBIES_PER_WAVE = 5

-- Zombie Settings
ZOMBIE_HEALTH = 50
ZOMBIE_DAMAGE = 10
ZOMBIE_SPEED = 16
```

Edit these values to tune the game difficulty and balance.

## 📚 Documentation

### Essential Reading
- **[README.md](README.md)** - Game overview and features
- **[INSTALLATION.md](INSTALLATION.md)** - Detailed setup instructions
- **[RESTRUCTURE_CHANGELOG.md](RESTRUCTURE_CHANGELOG.md)** - Complete restructure details

### Development Guides
- **[docs/STRUCTURE.md](docs/STRUCTURE.md)** - Project structure reference
- **[ASSET_PLACEHOLDERS.md](ASSET_PLACEHOLDERS.md)** - Asset requirements
- **[API_DOCUMENTATION.md](API_DOCUMENTATION.md)** - API reference
- **[FPS_DOCUMENTATION.md](FPS_DOCUMENTATION.md)** - FPS system guide

### System Specific
- **[REMOTE_EVENTS.md](REMOTE_EVENTS.md)** - Client-server communication
- **[GAME_DESIGN.md](GAME_DESIGN.md)** - Game mechanics and design
- **[ANIMATION_CREATION_GUIDE.md](ANIMATION_CREATION_GUIDE.md)** - Animation tutorial

## 🎯 First Time Setup Checklist

- [ ] Clone repository
- [ ] Open Roblox Studio
- [ ] Copy `ServerScriptService/` to Studio
- [ ] Copy `ReplicatedStorage/` to Studio
- [ ] Copy `StarterPlayer/` to Studio
- [ ] Copy `StarterGui/` files to Studio (as LocalScripts)
- [ ] Create Base in Workspace
- [ ] Create ZombieSpawnPoints folder with Parts
- [ ] Create ResourceSpawnPoints folder with Parts
- [ ] Test in Local Server mode
- [ ] Verify no errors in Output window
- [ ] (Optional) Create custom assets
- [ ] (Optional) Tune GameConfig settings

## ⚠️ Common Issues

### "RemoteEvent not found" Error
**Solution**: RemoteEvents are created automatically at runtime. If you see this error, the server scripts may not have initialized yet. Wait a few seconds.

### "Module not found" Error
**Solution**: Verify all folders are copied correctly:
- `ReplicatedStorage/Shared/` must contain all config files
- Check that folder names match exactly (case-sensitive)

### Zombies Not Spawning
**Solution**: 
- Ensure `ZombieSpawnPoints` folder exists in Workspace
- Add at least 5-10 Part instances inside the folder
- Parts should be positioned away from the Base

### Players Can't Collect Components
**Solution**:
- Ensure `ResourceSpawnPoints` folder exists in Workspace
- Add at least 10-15 Part instances inside the folder
- Parts should be distributed across the map

### Debug Mode
Enable debug output by setting in `ReplicatedStorage/Shared/GameConfig.lua`:
```lua
DEBUG = true  -- Shows detailed logging
```

## 🆘 Getting Help

1. **Check Documentation**: Review relevant .md files
2. **Check Output Window**: Look for error messages in Roblox Studio
3. **Verify Structure**: Ensure directories match the guide
4. **Read Placeholders**: Check _README.txt files in each directory
5. **Open Issue**: Create GitHub issue with "setup" label

## 🎉 You're Ready!

The repository is now structured for easy development and deployment. All code is in place and ready to run.

**Next Steps**:
1. Test the game in Roblox Studio
2. Experiment with GameConfig settings
3. Create custom assets (optional)
4. Share your creations!

---

**Repository**: [github.com/Carnage-Joker/AwavePuzz](https://github.com/Carnage-Joker/AwavePuzz)  
**License**: MIT  
**Version**: 2.0 (Restructured 2025-12-25)
