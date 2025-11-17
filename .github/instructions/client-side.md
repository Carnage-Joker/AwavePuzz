---
applyTo: "src/client/**/*.lua"
---

# Client-Side Code Instructions

## Client Responsibilities

These scripts run in StarterPlayerScripts and handle local player experience.

### What Clients Should Do

1. **Display UI** - Show game state, health, progress bars
2. **Handle Input** - Capture player actions, send to server via RemoteEvents
3. **Visual/Audio Effects** - Play sounds, particles, animations locally
4. **Smooth Updates** - Interpolate changes for better UX

### What Clients Should NOT Do

1. **Never decide game outcomes** - No damage calculation, no currency changes
2. **Never modify shared state** - Let the server be the source of truth
3. **Never trust local calculations** - Server validates everything

### Remote Event Usage

Always send actions to server for validation:

```lua
-- BAD: Client calculates damage
local damage = calculateDamage() -- NO!
player.Character.Humanoid.Health -= damage -- NO!

-- GOOD: Client sends action, server validates
local RemoteEvents = game.ReplicatedStorage.RemoteEvents
RemoteEvents.DealDamage:FireServer(targetZombie, weaponType)
```

### Listening to Server Updates

```lua
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateEvent = RemoteEvents:WaitForChild("UpdateName")

UpdateEvent.OnClientEvent:Connect(function(data)
    -- Update UI elements based on server data
    -- Don't modify game state, just display it
end)
```

### UI Patterns

#### Health Bar Example

```lua
local HealthBar = script.Parent
local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")

RemoteEvents.UpdateHealth.OnClientEvent:Connect(function(newHealth, maxHealth)
    local percentage = newHealth / maxHealth
    HealthBar.Size = UDim2.new(percentage, 0, 1, 0)
    HealthBar.Text = newHealth .. " / " .. maxHealth
end)
```

#### Weapon Input Example

```lua
local UserInputService = game:GetService("UserInputService")
local RemoteEvents = game.ReplicatedStorage.RemoteEvents

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Fire weapon - let server validate hit
        local mouse = Player:GetMouse()
        RemoteEvents.FireWeapon:FireServer(mouse.Hit.Position)
    end
end)
```

### Visual Feedback

Provide immediate feedback for better UX:

```lua
-- Play sound locally while waiting for server confirmation
local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://12345"
sound.Parent = workspace
sound:Play()

-- Server will handle actual damage
RemoteEvents.Attack:FireServer(target)
```

### Performance Tips

- Avoid running code every frame (RunService.Heartbeat)
- Use task.wait() with reasonable delays
- Cache UI elements instead of finding them repeatedly
- Destroy temporary effects after playing
- Use LocalScripts for UI, not regular Scripts

### Error Handling

```lua
-- Wait for important elements with timeout
local success, result = pcall(function()
    return game.ReplicatedStorage:WaitForChild("RemoteEvents", 10)
end)

if not success then
    warn("Failed to load RemoteEvents")
    -- Show error UI to player
    return
end
```

### Testing Checklist

- [ ] UI updates reflect server state accurately
- [ ] No client-side calculation of game-critical values
- [ ] Smooth transitions and feedback
- [ ] Handles server delays gracefully
- [ ] No errors when elements aren't immediately available
- [ ] Works in both Studio and live server
