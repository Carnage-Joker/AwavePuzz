# UI Standards and Best Practices

## Overview

This document defines the required patterns and conventions for all client UI modules in AwavePuzz. Following these standards ensures:
- Consistent lifecycle management
- Safe connection cleanup (no memory leaks)
- Proper input routing through InputActionRegistry
- RemoteRegistry integration for multiplayer safety

## Module Structure

### Required Pattern

All UI modules **MUST** be ModuleScripts that return a table with these optional methods:

```lua
local UIModule = {}

-- Optional: Called once when UI is loaded by ClientMainModule
function UIModule.initialize()
    -- Setup code here
end

-- Optional: Called by ClientMainModule to bind remotes from RemoteRegistry
function UIModule.bindRemotes(remotes)
    -- Store and connect to remotes here
end

-- Required: Called when UI needs to be cleaned up
function UIModule.cleanup()
    -- Disconnect all connections
    -- Unregister input actions
    -- Destroy UI elements
end

return UIModule
```

## Connection Management

### Use UIConnectionMaid for ALL connections

**✅ REQUIRED:** Import and use UIConnectionMaid for tracking connections:

```lua
local UIConnectionMaid = require(SharedFolder:WaitForChild("UI"):WaitForChild("UIConnectionMaid"))

local maid = UIConnectionMaid.new()
```

### Connection Types

UIConnectionMaid safely handles:

```lua
-- RBXScriptConnection
maid:Give(button.MouseButton1Click:Connect(handler), "buttonClick")

-- Unsubscribe functions (e.g., from UIScaleManager)
maid:GiveFn(UIScaleManager.onScaleChanged(updateUI), "scaleChanged")

-- Disconnectable objects
maid:GiveTask({Disconnect = function() ... end}, "customTask")
```

### Button Connection Management

For dynamic button lists (shop items, puzzle menu, etc.):

```lua
local buttonMaid = UIConnectionMaid.new() -- Separate maid for transient connections

local function rebuildList(items)
    -- Clean up old button connections
    buttonMaid:Cleanup()
    
    -- Destroy old buttons
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Create new buttons
    for _, item in ipairs(items) do
        local button = Instance.new("TextButton")
        -- ... setup button ...
        
        -- Track connection in buttonMaid for automatic cleanup
        buttonMaid:Give(button.MouseButton1Click:Connect(function()
            handleItemClick(item)
        end))
    end
end
```

### Cleanup Pattern

```lua
function UIModule.cleanup()
    -- 1. Unregister input actions
    InputActionRegistry.unregister("ActionName1")
    InputActionRegistry.unregister("ActionName2")
    
    -- 2. Clean up all connections
    maid:Cleanup()
    buttonMaid:Cleanup()
    
    -- 3. Close modal if open
    if ModalManager.isModalOpen("UIName") then
        ModalManager.remove("UIName")
    end
    
    -- 4. Destroy UI elements
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
    end
end
```

## Remote Event Usage

### ✅ Use RemoteRegistry (Preferred)

```lua
local remotes = nil

function UIModule.bindRemotes(providedRemotes)
    if not providedRemotes then
        warn("[UIModule] bindRemotes: No remotes provided")
        return
    end
    
    remotes = providedRemotes
    
    -- Connect to remotes
    maid:Give(remotes.EventName.OnClientEvent:Connect(function(data)
        -- Handle event
    end), "eventName")
end
```

### ❌ AVOID Direct RemoteEvents Access

```lua
-- DON'T DO THIS:
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local myRemote = remoteFolder:WaitForChild("MyRemote")
```

**Exception:** Legacy UIs that haven't been migrated yet may use direct access temporarily, but should be migrated to RemoteRegistry.

## Input Handling

### InputActionRegistry Integration

All input **MUST** be registered with InputActionRegistry for conflict detection:

```lua
-- Register actions (call once during module initialization)
InputActionRegistry.register("UIToggle", "UIName", {Enum.KeyCode.B}, InputActionRegistry.Priority.TOGGLE_UI, true)
InputActionRegistry.register("UINavigateUp", "UIName", {Enum.KeyCode.Up}, InputActionRegistry.Priority.MODAL_UI, false)
InputActionRegistry.register("UINavigateDown", "UIName", {Enum.KeyCode.Down}, InputActionRegistry.Priority.MODAL_UI, false)
```

### Input Handling Pattern

```lua
local UserInputService = game:GetService("UserInputService")

-- Connect to UserInputService but gate with InputActionRegistry state
maid:Give(UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    -- Always check gameProcessedEvent first
    if gameProcessedEvent then
        return
    end
    
    -- Check if this UI is the top modal
    if not ModalManager.isTopModal("UIName") then
        return
    end
    
    -- Check if action is enabled in registry before handling
    if input.KeyCode == Enum.KeyCode.B then
        local action = InputActionRegistry.getAction("UIToggle")
        if action and action.enabled then
            -- Handle input
            toggleUI()
        end
    end
end), "inputBegan")
```

### Enable/Disable Actions

```lua
-- When UI opens
InputActionRegistry.enableOwner("UIName")

-- When UI closes
InputActionRegistry.disableOwner("UIName")
```

### Priority Levels

Use appropriate priority for your UI:

```lua
InputActionRegistry.Priority.FULLSCREEN_STATE  -- 0: Title, Lobby, Epilogue
InputActionRegistry.Priority.MODAL_UI          -- 1: Shop, Puzzle, Alliance
InputActionRegistry.Priority.TOGGLE_UI         -- 2: Scoreboard
InputActionRegistry.Priority.CORE_GAMEPLAY     -- 3: Movement, Combat
InputActionRegistry.Priority.PASSIVE_DISPLAY   -- 4: HUD elements
```

## Modal Management

### ModalManager Integration

```lua
-- When opening modal UI
ModalManager.push("UIName", function()
    -- Close callback
    screenGui.Enabled = false
    InputActionRegistry.disableOwner("UIName")
end, ModalManager.Priority.MODAL)

-- Enable input actions after modal is pushed
InputActionRegistry.enableOwner("UIName")

-- When closing modal UI
ModalManager.remove("UIName")
InputActionRegistry.disableOwner("UIName")
```

## Common Anti-Patterns

### ❌ NEVER Fire Signals Manually

```lua
-- DON'T DO THIS:
button.MouseButton1Click:Fire()  -- Signals cannot be fired!
```

**Instead:** Store action data and call the handler function directly:

```lua
-- Store action data
local buttonData = {}
buttonData[button] = {itemId = item.Id, available = true}

-- In keyboard handler
if buttonData[selectedButton] and buttonData[selectedButton].available then
    handlePurchase(buttonData[selectedButton].itemId)
end
```

### ❌ NEVER Mix Connection Types Without Maid

```lua
-- DON'T DO THIS:
local connections = {}
connections.button = button.MouseButton1Click:Connect(...)
connections.scale = unsubscribeFunction  -- Different type!
connections.update = {Disconnect = function() ... end}  -- Another different type!

-- Cleanup will fail:
for _, conn in pairs(connections) do
    conn:Disconnect()  -- Won't work for unsubscribe functions!
end
```

**Instead:** Use UIConnectionMaid which handles all types safely.

### ❌ NEVER Skip InputActionRegistry Unregistration

```lua
-- DON'T DO THIS:
function cleanup()
    maid:Cleanup()
    -- Forgot to unregister input actions!
end
```

**Instead:** Always unregister actions in cleanup.

### ❌ NEVER Create Button Connections Without Cleanup

```lua
-- DON'T DO THIS:
for _, item in ipairs(items) do
    local button = Instance.new("TextButton")
    button.MouseButton1Click:Connect(...)  -- Leak on rebuild!
end
```

**Instead:** Track all button connections in a buttonMaid and cleanup before rebuild.

## Checklist for UI Module Review

Before submitting a UI module, verify:

- [ ] Uses UIConnectionMaid for all connections
- [ ] No `MouseButton1Click:Fire()` or manual signal firing
- [ ] No direct `ReplicatedStorage.RemoteEvents` usage (unless grandfathered)
- [ ] cleanup() function exists and is safe to call multiple times
- [ ] InputActionRegistry actions registered with appropriate priority
- [ ] InputActionRegistry actions unregistered in cleanup()
- [ ] Input handling gated by InputActionRegistry enabled state
- [ ] ModalManager integration for modal UIs
- [ ] Button connections tracked in separate buttonMaid for dynamic lists
- [ ] No connection leaks on list rebuild or UI reopen

## Testing Recommendations

### Stress Test

Open and close the UI 20+ times:

```lua
-- Test script
for i = 1, 20 do
    UI.open()
    task.wait(0.5)
    UI.close()
    task.wait(0.5)
end

-- Check maid:GetTaskCount() - should not increase
```

### Memory Leak Detection

```lua
-- Before opening UI
local initialCount = maid:GetTaskCount()

-- Open/close UI multiple times
-- ...

-- After closing UI
local finalCount = maid:GetTaskCount()
assert(finalCount == initialCount, "Connection leak detected!")
```

## Examples

See these modules for reference implementations:

- **ShopUI.lua** - Complete example with RemoteRegistry, buttonMaid, and gated input
- **PuzzleMenuUI.lua** - Example with dynamic button list and keyboard navigation
- **TitleScreenUI.lua** - Example with bindRemotes pattern
- **EpilogueUI.lua** - Example with bindRemotes and ModalManager

## Migration Guide

### For Legacy UIs

If migrating an existing UI module:

1. Add UIConnectionMaid imports and create maid instance
2. Replace connection tables with maid:Give() calls
3. Add buttonMaid for dynamic button lists
4. Replace direct RemoteEvents access with bindRemotes() method
5. Add InputActionRegistry.unregister() to cleanup()
6. Gate input handling with InputActionRegistry state checks
7. Test open/close 20+ times for leaks

### Compatibility Shim (Temporary)

For legacy UIs that cannot be migrated immediately:

```lua
-- Wrap legacy remotes to work with RemoteRegistry
local legacyShopRequest = remotes.ShopRequest or remoteFolder:WaitForChild("ShopRequest")
local legacyShopUpdate = remotes.ShopUpdate or remoteFolder:WaitForChild("ShopUpdate")
```

**Note:** This is a temporary measure. All UIs should be fully migrated to RemoteRegistry.

---

*Last Updated: 2026-02-14*
*Version: 1.0.0*
