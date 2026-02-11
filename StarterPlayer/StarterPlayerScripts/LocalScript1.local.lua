local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ViewModelController = require(game.ReplicatedStorage.Shared:WaitForChild("ViewModelController"))

-- BUG-007 FIX: Connection tracking for cleanup
local _connections = {}

local bindables = playerGui:WaitForChild("BindableEvents")
local weaponEquipped = bindables:WaitForChild("WeaponEquipped")

ViewModelController:SpawnViewModel()

_connections.weaponEquipped = weaponEquipped.Event:Connect(function(weaponId)
	-- later: swap weapon mesh attached to arms here
end)

-- BUG-007 FIX: Cleanup on script removal
script.AncestryChanged:Connect(function(_, parent)
	if parent == nil then
		for name, connection in pairs(_connections) do
			if connection then
				connection:Disconnect()
			end
		end
		_connections = {}
	end
end)
