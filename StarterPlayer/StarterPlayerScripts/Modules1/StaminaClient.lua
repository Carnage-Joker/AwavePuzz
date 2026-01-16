-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript
-- StaminaClient.client.lua
-- Client-side receiver for SprintService stamina updates
-- Fixes: "Remote event invocation queue exhausted ... StaminaUpdate; did you forget to implement OnClientEvent?"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local StaminaClient = {}
StaminaClient.__index = StaminaClient

-- Shared state (simple + compatible with existing UI modules)
_G.__AWAVE_STAMINA = _G.__AWAVE_STAMINA or {
	current = 100,
	max = 100,
	isSprinting = false,
}

-- Bindable for clean subscriptions
local staminaChanged = Instance.new("BindableEvent")
staminaChanged.Name = "StaminaChanged"

function StaminaClient.getChangedSignal()
	return staminaChanged.Event
end

local function getRemote(name)
	local folder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if not folder then
		warn("[StaminaClient] RemoteEvents folder missing")
		return nil
	end
	local re = folder:FindFirstChild(name)
	if re and re:IsA("RemoteEvent") then
		return re
	end
	warn("[StaminaClient] RemoteEvent missing:", name)
	return nil
end

local StaminaUpdate = getRemote("StaminaUpdate")
local SprintRequest = getRemote("SprintRequest")

-- Public API for movement modules to request sprint
function StaminaClient.requestSprint(wantsSprint: boolean)
	if SprintRequest then
		SprintRequest:FireServer(wantsSprint == true)
	end
end

function StaminaClient.initialize()
	if StaminaClient._initialized then return end
	StaminaClient._initialized = true

	if not StaminaUpdate then
		warn("[StaminaClient] Cannot initialize (StaminaUpdate missing)")
		return
	end

	StaminaUpdate.OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then return end

		local cur = tonumber(payload.current)
		local mx = tonumber(payload.max)
		local sprinting = payload.isSprinting == true

		if cur then _G.__AWAVE_STAMINA.current = cur end
		if mx then _G.__AWAVE_STAMINA.max = mx end
		_G.__AWAVE_STAMINA.isSprinting = sprinting

		staminaChanged:Fire(_G.__AWAVE_STAMINA)
	end)

	-- Optional: reset values on respawn (keeps HUD sane)
	player.CharacterAdded:Connect(function()
		-- don’t hard reset max; server will send fresh value anyway
		_G.__AWAVE_STAMINA.isSprinting = false
	end)

	print("[StaminaClient] ✓ Bound StaminaUpdate listener")
end

return StaminaClient
