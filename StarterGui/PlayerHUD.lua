-- @ScriptType: LocalScript
-- StarterGui/PlayerHUD (LocalScript) - DROP-IN REPLACEMENT
-- Pattern: LocalScript sits directly under StarterGui.
-- This script creates/owns a ScreenGui named "PlayerHUDGui".

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- -----------------------
-- ScreenGui owner
-- -----------------------
local function getOrCreateGui()
	local existing = playerGui:FindFirstChild("PlayerHUDGui")
	if existing and existing:IsA("ScreenGui") then
		return existing
	end

	local sg = Instance.new("ScreenGui")
	sg.Name = "PlayerHUDGui"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = playerGui
	return sg
end

local gui = getOrCreateGui()

-- -----------------------
-- Optional remotes
-- -----------------------
local function findRemote(name)
	local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not folder then return nil end
	local r = folder:FindFirstChild(name)
	return (r and r:IsA("RemoteEvent")) and r or nil
end

-- If you already have a unified HUD remote, keep these names.
local HudStateRemote   = findRemote("HUDState")     -- {mapName,wave,objective,health={current,max},stamina={current,max}}
local WaveStateRemote  = findRemote("WaveState")    -- {waveNumber}
local MatchStateRemote = findRemote("MatchState")   -- {mapName}

-- -----------------------
-- UI helpers
-- -----------------------
local function ensure(name, className, parent)
	local inst = parent:FindFirstChild(name)
	if inst then return inst end
	inst = Instance.new(className)
	inst.Name = name
	inst.Parent = parent
	return inst
end

local function corner(parent, px)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, px or 10)
	c.Parent = parent
	return c
end

-- -----------------------
-- Build UI
-- -----------------------
local root = ensure("Root", "Frame", gui)
root.AnchorPoint = Vector2.new(0, 1)
root.Position = UDim2.new(0, 16, 1, -16)
root.Size = UDim2.fromOffset(360, 140)
root.BackgroundTransparency = 0.25
root.BorderSizePixel = 0
corner(root, 14)

local title = ensure("Title", "TextLabel", root)
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(14, 10)
title.Size = UDim2.new(1, -28, 0, 20)
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextScaled = true
title.Text = "PLAYER"

local info = ensure("Info", "TextLabel", root)
info.BackgroundTransparency = 1
info.Position = UDim2.fromOffset(14, 34)
info.Size = UDim2.new(1, -28, 0, 18)
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextScaled = true
info.Text = "Map: -- | Wave: --"

local objective = ensure("Objective", "TextLabel", root)
objective.BackgroundTransparency = 1
objective.Position = UDim2.fromOffset(14, 54)
objective.Size = UDim2.new(1, -28, 0, 18)
objective.TextXAlignment = Enum.TextXAlignment.Left
objective.TextScaled = true
objective.Text = "Objective: --"

local hpLabel = ensure("HPLabel", "TextLabel", root)
hpLabel.BackgroundTransparency = 1
hpLabel.Position = UDim2.fromOffset(14, 78)
hpLabel.Size = UDim2.new(1, -28, 0, 18)
hpLabel.TextXAlignment = Enum.TextXAlignment.Left
hpLabel.TextScaled = true
hpLabel.Text = "HP: --/--"

local hpBack = ensure("HPBack", "Frame", root)
hpBack.Position = UDim2.fromOffset(14, 100)
hpBack.Size = UDim2.new(1, -28, 0, 12)
hpBack.BackgroundTransparency = 0.35
hpBack.BorderSizePixel = 0
corner(hpBack, 8)

local hpFill = ensure("HPFill", "Frame", hpBack)
hpFill.Position = UDim2.fromScale(0, 0)
hpFill.Size = UDim2.fromScale(1, 1)
hpFill.BorderSizePixel = 0
hpFill.BackgroundTransparency = 0.1
corner(hpFill, 8)

local stBack = ensure("StaminaBack", "Frame", root)
stBack.Position = UDim2.fromOffset(14, 118)
stBack.Size = UDim2.new(1, -28, 0, 8)
stBack.BackgroundTransparency = 0.5
stBack.BorderSizePixel = 0
corner(stBack, 8)

local stFill = ensure("StaminaFill", "Frame", stBack)
stFill.Position = UDim2.fromScale(0, 0)
stFill.Size = UDim2.fromScale(1, 1)
stFill.BorderSizePixel = 0
stFill.BackgroundTransparency = 0.2
corner(stFill, 8)

-- -----------------------
-- State
-- -----------------------
local mapName = "--"
local waveText = "--"
local objectiveText = "--"

local function clamp01(x)
	if x < 0 then return 0 end
	if x > 1 then return 1 end
	return x
end

local function setBar(fillFrame, ratio)
	fillFrame.Size = UDim2.fromScale(clamp01(ratio), 1)
end

local function refreshInfo()
	info.Text = string.format("Map: %s | Wave: %s", tostring(mapName), tostring(waveText))
	objective.Text = "Objective: " .. tostring(objectiveText)
end

-- -----------------------
-- Humanoid fallback
-- -----------------------
local hum
local lastHp, lastMaxHp = -1, -1

local function hookCharacter(char)
	hum = nil
	lastHp, lastMaxHp = -1, -1
	if not char then return end
	hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 10)
end

player.CharacterAdded:Connect(hookCharacter)
if player.Character then hookCharacter(player.Character) end

-- -----------------------
-- Remote handlers
-- -----------------------
local function applyHudPayload(payload)
	if typeof(payload) ~= "table" then return end

	if payload.mapName ~= nil then mapName = payload.mapName end
	if payload.wave ~= nil then waveText = payload.wave end
	if payload.objective ~= nil then objectiveText = payload.objective end

	if payload.stamina ~= nil then
		if typeof(payload.stamina) == "table" then
			local cur = tonumber(payload.stamina.current) or 0
			local mx = tonumber(payload.stamina.max) or 100
			setBar(stFill, (mx > 0) and (cur / mx) or 0)
		elseif typeof(payload.stamina) == "number" then
			setBar(stFill, payload.stamina)
		end
	end

	if payload.health ~= nil then
		if typeof(payload.health) == "table" then
			local cur = tonumber(payload.health.current) or 0
			local mx = tonumber(payload.health.max) or 100
			hpLabel.Text = string.format("HP: %d/%d", cur, mx)
			setBar(hpFill, (mx > 0) and (cur / mx) or 0)
		end
	end

	refreshInfo()
end

if HudStateRemote then
	HudStateRemote.OnClientEvent:Connect(applyHudPayload)
end

if WaveStateRemote then
	WaveStateRemote.OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then return end
		if payload.waveNumber ~= nil then
			waveText = tostring(payload.waveNumber)
			refreshInfo()
		end
	end)
end

if MatchStateRemote then
	MatchStateRemote.OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then return end
		if payload.mapName ~= nil then
			mapName = tostring(payload.mapName)
			refreshInfo()
		end
	end)
end

-- -----------------------
-- Loop
-- -----------------------
refreshInfo()

RunService.RenderStepped:Connect(function()
	if hum then
		local hp = hum.Health
		local mx = hum.MaxHealth
		if hp ~= lastHp or mx ~= lastMaxHp then
			lastHp, lastMaxHp = hp, mx
			hpLabel.Text = string.format("HP: %d/%d", math.floor(hp + 0.5), math.floor(mx + 0.5))
			setBar(hpFill, (mx > 0) and (hp / mx) or 0)
		end
	end
end)
