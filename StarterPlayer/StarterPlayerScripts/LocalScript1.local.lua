local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ViewModelController = require(game.ReplicatedStorage.Shared:WaitForChild("ViewModelController"))

local bindables = playerGui:WaitForChild("BindableEvents")
local weaponEquipped = bindables:WaitForChild("WeaponEquipped")

ViewModelController:SpawnViewModel()

weaponEquipped.Event:Connect(function(weaponId)
	-- later: swap weapon mesh attached to arms here
end)
