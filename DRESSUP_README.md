# Private Server Dress-Up Game - Setup Guide

## Overview

This is a **private-server-only** dress-up and self-expression game built for Roblox. Players can customize their outfits, complete activities to earn stats and currency, unlock titles, and receive positive affirmations.

### Key Features

- **Private Server Only**: Players must join via a private server
- **Outfit System**: 20+ items with color harmony and silhouette scoring
- **Activities**: Complete activities for rewards (Mirror Pose, Styling Desk, Garden Decor)
- **Stats**: Grace, Elegance, Confidence, Care
- **Titles**: 8 unlockable titles based on achievements
- **Affirmations**: Periodic positive messages
- **Safe Content**: All language focused on self-expression, no sexual content

## Project Structure

```
AwavePuzz/
├── ServerScriptService/
│   ├── PrivateServerGate.server.lua    # Enforces private server requirement
│   ├── Main.server.lua                  # Main server initialization
│   └── Services/
│       ├── DataService.lua              # Player data management
│       ├── StatsService.lua             # Stats tracking
│       ├── CurrencyService.lua          # Currency management
│       ├── OutfitService.lua            # Outfit catalog & equipping
│       ├── ActivityService.lua          # Activity system
│       ├── TitleService.lua             # Title unlocking
│       └── AffirmationService.lua       # Positive affirmations
├── ReplicatedStorage/Shared/
│   ├── Networking/
│   │   └── Remotes.lua                  # Centralized remote management
│   ├── Data/
│   │   ├── OutfitCatalog.lua            # 20+ outfit items
│   │   ├── ColorPalettes.lua            # Color harmony system
│   │   ├── Activities.lua               # 3 activities
│   │   └── Titles.lua                   # 8 titles
│   ├── Constants.lua                    # Game constants
│   └── Util.lua                         # Utility functions
└── StarterPlayer/StarterPlayerScripts/
    ├── ClientMain.client.lua            # Client initialization
    └── Controllers/
        ├── UIController.lua             # UI management
        ├── OutfitController.lua         # Outfit interactions
        ├── ActivityController.lua       # Activity interactions
        ├── TitleController.lua          # Title interactions
        └── NotificationController.lua   # Toast notifications
```

## Installation

### 1. Open Roblox Studio

1. Launch Roblox Studio
2. Create a new place or open an existing one

### 2. Copy Files to Roblox Studio

Copy the folders from this repository to your Roblox Studio project:

#### Server Scripts
- Copy `ServerScriptService/PrivateServerGate.server.lua` → `game.ServerScriptService`
- Copy `ServerScriptService/Main.server.lua` → `game.ServerScriptService`
- Copy `ServerScriptService/Services/` folder → `game.ServerScriptService.Services`

#### Shared Resources
- Copy `ReplicatedStorage/Shared/` folder → `game.ReplicatedStorage.Shared`

#### Client Scripts
- Copy `StarterPlayer/StarterPlayerScripts/ClientMain.client.lua` → `game.StarterPlayer.StarterPlayerScripts`
- Copy `StarterPlayer/StarterPlayerScripts/Controllers/` folder → `game.StarterPlayer.StarterPlayerScripts.Controllers`

### 3. Verify Structure

Your Roblox Studio hierarchy should look like this:

```
- ServerScriptService
  - PrivateServerGate (Script)
  - Main (Script)
  - Services (Folder)
    - DataService (ModuleScript)
    - StatsService (ModuleScript)
    - CurrencyService (ModuleScript)
    - OutfitService (ModuleScript)
    - ActivityService (ModuleScript)
    - TitleService (ModuleScript)
    - AffirmationService (ModuleScript)

- ReplicatedStorage
  - Remotes (Folder) - Created automatically by Remotes.lua
  - Shared (Folder)
    - Networking (Folder)
      - Remotes (ModuleScript)
    - Data (Folder)
      - OutfitCatalog (ModuleScript)
      - ColorPalettes (ModuleScript)
      - Activities (ModuleScript)
      - Titles (ModuleScript)
    - Constants (ModuleScript)
    - Util (ModuleScript)

- StarterPlayer
  - StarterPlayerScripts
    - ClientMain (LocalScript)
    - Controllers (Folder)
      - UIController (ModuleScript)
      - OutfitController (ModuleScript)
      - ActivityController (ModuleScript)
      - TitleController (ModuleScript)
      - NotificationController (ModuleScript)
```

## Testing in Roblox Studio

### Testing Private Server Enforcement

The game requires a private server. Here's how to test:

#### Option 1: Mock Private Server (Testing Only)

For testing in Studio, temporarily modify `PrivateServerGate.server.lua`:

```lua
-- Add at top of file for testing
local TESTING_MODE = true  -- Set to false for production

local function isPrivateServer()
    if TESTING_MODE then
        return true  -- Bypass check for testing
    end
    return game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
end
```

#### Option 2: Test with Real Private Server

1. Publish your game to Roblox
2. Go to the game's page
3. Click "..." menu → "Configure this Place"
4. Go to "Access" settings
5. Create a private server (may require payment)
6. Join via the private server link

### Running the Game

1. Click **Play** (F5) in Roblox Studio
2. Check the **Output** window for initialization messages:
   ```
   🔒 PrivateServerGate active - Private server enforcement enabled
   🎮 Main.server.lua starting...
   ✅ Remotes initialized
   📊 DataService initialized
   📈 StatsService initialized
   💰 CurrencyService initialized
   👗 OutfitService initialized
   🎯 ActivityService initialized
   🏆 TitleService initialized
   💝 AffirmationService initialized
   ✅ All services initialized
   🎮 Main.server.lua initialized - Game ready!
   🎮 ClientMain starting...
   ✅ Client initialized
   ```

3. You should see:
   - Stats UI in top-left corner
   - Currency UI in top-right corner
   - Toast notifications appearing at bottom

### Testing Features

#### Test Outfit System (via Command Bar in Studio)

In the Command Bar (View → Command Bar), run:

```lua
-- Get services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players:GetChildren()[1]  -- Get first player

-- Get remote functions
local Remotes = require(ReplicatedStorage.Shared.Networking.Remotes)
local equipFunc = Remotes.getFunction("EquipOutfit")
local getCatalogFunc = Remotes.getFunction("GetCatalog")

-- Test: Get catalog
local catalog = getCatalogFunc:InvokeServer()
print("Catalog has", #catalog, "items")

-- Test: Give player an item and equip it
local ServerScriptService = game:GetService("ServerScriptService")
local DataService = require(ServerScriptService.Services.DataService)
local outfitService = require(ServerScriptService.Services.OutfitService)

-- Manually add item to test equipping
local testItemId = "hat_beret"
-- Note: In production, items must be purchased first
```

#### Test Activity System

In the Command Bar:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players:GetChildren()[1]

local Remotes = require(ReplicatedStorage.Shared.Networking.Remotes)
local completeActivityFunc = Remotes.getFunction("CompleteActivity")

-- Complete an activity
local result = completeActivityFunc:InvokeServer("mirror_pose")
print("Activity result:", result.success, result.message)
```

#### Test Title System

In the Command Bar:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players:GetChildren()[1]

local Remotes = require(ReplicatedStorage.Shared.Networking.Remotes)
local setTitleFunc = Remotes.getFunction("SetTitle")

-- Set title (novice is unlocked by default)
local result = setTitleFunc:InvokeServer("novice")
print("Title result:", result.success, result.message)
```

## Remote Events/Functions

### Client → Server Functions

- **GetCatalog()** - Returns outfit catalog
- **EquipOutfit(itemId)** - Equip an owned item
- **GetProfile()** - Returns player profile data
- **CompleteActivity(activityId)** - Complete an activity
- **SetTitle(titleId)** - Set active title

### Server → Client Events

- **PushToast(toastData)** - Display toast notification
- **SyncStats(stats)** - Update player stats

## Game Features

### Stats System
- **Grace**: Gained from poses and elegant activities
- **Elegance**: Gained from styling and organization
- **Confidence**: Gained from self-expression activities
- **Care**: Gained from detail-oriented activities

### Currency System
- **Coins**: Earned from activities, used to buy items
- **Gems**: Rare currency, earned from special activities

### Outfit System
- **Slots**: Hat, Dress, Shoes, 3 Accessory slots
- **Scoring**: Outfits scored on color harmony, silhouette consistency, and balance
- **Catalog**: 20+ items with different styles and rarities

### Activities
1. **Mirror Pose Practice** - +5 Confidence, +3 Grace, +50 Coins
2. **Styling Desk Organization** - +8 Care, +2 Elegance, +50 Coins
3. **Garden Decoration** - +6 Elegance, +4 Care, +60 Coins, +1 Gem

All activities have a 5-minute cooldown.

### Titles
- **Style Novice** - Default starting title
- **Graceful** - Requires 50 Grace
- **Elegant Soul** - Requires 50 Elegance
- **Confident** - Requires 50 Confidence
- **Caring Heart** - Requires 50 Care
- **Fashionista** - Requires 15 owned items
- **Dedicated** - Requires 20 completed activities
- **Style Icon** - Requires 100 in all stats

## Troubleshooting

### "Player kicked - Not in private server"
- Set `TESTING_MODE = true` in PrivateServerGate.server.lua for Studio testing
- For production, ensure players join via private server link

### "Remote not found" errors
- Verify all files are in correct locations
- Check that Main.server.lua runs before client scripts
- Check Output window for initialization errors

### UI not appearing
- Verify ClientMain.client.lua is in StarterPlayerScripts
- Check that Controllers folder exists and contains all controllers
- Look for errors in Output window

### Stats not updating
- Check that SyncStats event is firing (add print statements)
- Verify DataService is properly initialized
- Check that profile is loaded for the player

## Architecture Notes

### Server Authority
- All game logic runs on server
- Client sends only item IDs, activity IDs, etc.
- Server validates all requests and owns game state

### Modular Design
- Services are self-contained with clear responsibilities
- Controllers handle client-side interactions
- Shared modules provide common functionality

### Data Flow
1. Client requests action via RemoteFunction
2. Server validates request
3. Server updates data in DataService
4. Server sends updates via RemoteEvent
5. Client updates UI

## Development

### Adding New Items
Edit `ReplicatedStorage/Shared/Data/OutfitCatalog.lua`:

```lua
{
    id = "new_item_id",
    name = "Display Name",
    slot = "Hat",  -- or "Dress", "Shoes", "Accessory"
    paletteTags = {"Pastel", "Elegant"},
    silhouette = "Elegant",
    rarity = "Rare",
    price = 500
}
```

### Adding New Activities
Edit `ReplicatedStorage/Shared/Data/Activities.lua`:

```lua
{
    id = "new_activity_id",
    name = "Activity Name",
    description = "What players do",
    cooldown = 300,
    rewards = {
        statRewards = {
            Grace = 5,
        },
        currencyRewards = {
            Coins = 100,
        },
    },
}
```

### Adding New Titles
Edit `ReplicatedStorage/Shared/Data/Titles.lua`:

```lua
{
    id = "new_title_id",
    name = "Title Name",
    description = "What it represents",
    unlockRequirements = {
        type = "stat",
        stat = "Grace",
        amount = 100,
    },
}
```

## Support

For issues or questions:
1. Check Output window for errors
2. Verify all files are in correct locations
3. Ensure structure matches the guide above
4. Test with `TESTING_MODE = true` first

## License

This game template is provided as-is for educational and development purposes.
