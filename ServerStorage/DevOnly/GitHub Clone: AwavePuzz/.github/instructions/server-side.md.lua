-- @ScriptType: Script
---
applyTo: "src/server/**/*.lua"
---

# Server-Side Code Instructions

## Server Authority Rules

These scripts run in ServerScriptService and have full authority over game state.

### Critical Principles

1. **Never trust client input** - All data from clients must be validated
2. **All game state lives here** - Health, currency, cure progress, alliances
3. **Broadcast updates to clients** - Use RemoteEvents to notify clients of changes
4. **Handle edge cases** - Player disconnects, race conditions, invalid states

### Manager Pattern

Each major system should have a dedicated manager:
- `GameManager` - Overall game flow, win/lose conditions
- `PlayerManager` - Player data, health, inventory
- `WaveManager` - Wave spawning, progression, timers
- `BaseManager` - Base health and defense
- `CureCraftingManager` - Cure progress and validation
- `AllianceService` - Alliance management
- `ResourceSpawner` - Resource spawn logic
- `ZombieBrain` - AI and pathfinding

### Remote Event Handling

Always validate inputs from clients:

```lua
local RemoteEvent = game.ReplicatedStorage.RemoteEvents.ActionName

RemoteEvent.OnServerEvent:Connect(function(player, ...)
    -- Step 1: Validate player exists and has character
    if not player or not player.Character then 
        warn("Invalid player in RemoteEvent")
        return 
    end
    
    -- Step 2: Validate input parameters
    local arg1, arg2 = ...
    if typeof(arg1) ~= "expectedType" then
        warn("Invalid argument type from player: " .. player.Name)
        return
    end
    
    -- Step 3: Check permissions/cooldowns
    if not canPlayerPerformAction(player) then
        return
    end
    
    -- Step 4: Process the action
    -- Step 5: Update game state
    -- Step 6: Broadcast to relevant clients
end)
```

### Zombie AI Guidelines

- Use PathfindingService for navigation
- Store zombie stats in attributes
- Tag zombies with `IsZombie` attribute
- Track active zombies in `workspace.Zombies` folder
- Handle pathfinding failures gracefully
- Update target periodically (not every frame)

### Performance Considerations

- Use task.spawn() for concurrent operations
- Avoid tight loops without delays
- Clean up disconnected player data
- Destroy zombie instances when dead
- Use attributes instead of values for simple data

### Error Handling

```lua
local success, result = pcall(function()
    -- Risky operation
end)

if not success then
    warn("Error in system: " .. tostring(result))
    -- Handle gracefully
end
```

### Testing Checklist

- [ ] Works with multiple players simultaneously
- [ ] Handles player disconnect mid-action
- [ ] Validates all client inputs
- [ ] No exploitable race conditions
- [ ] Proper cleanup on player leave
- [ ] Broadcasts state updates to clients
