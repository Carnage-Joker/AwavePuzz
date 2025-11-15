-- MainServer.lua
-- Main server initialization script
-- Place this as a Script (not ModuleScript) in ServerScriptService

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Require managers
local GameManager = require(script.Parent.GameManager)
local AllianceService = require(script.Parent.AllianceService)
local CureService = require(script.Parent.CureService)

print("=== AwavePuzz Server Starting ===")

-- Initialize game manager
local gameManager = GameManager.new()
print("GameManager initialized")

-- Initialize alliance service
local allianceService = AllianceService.new()
print("AllianceService initialized")

-- Initialize cure service (needs reference to game manager)
local cureService = CureService.new(gameManager)
print("CureService initialized")

-- Link cure service to game manager
-- (so GameManager can call updateCureProgress on CureService)
gameManager.cureService = cureService

-- Player connection handlers
Players.PlayerAdded:Connect(function(player)
	print(player.Name .. " joined the game")
	
	-- Initialize player in alliance service
	allianceService:initializePlayer(player)
	
	-- Setup player character
	player.CharacterAdded:Connect(function(character)
		print(player.Name .. "'s character loaded")
		
		-- Wait for humanoid
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid then
			-- Setup health tracking
			humanoid.Died:Connect(function()
				print(player.Name .. " died")
				gameManager:checkLoseConditions()
			end)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	print(player.Name .. " left the game")
	
	-- Clean up player from alliance service
	allianceService:removePlayer(player)
end)

-- Main game loop
local lastUpdate = tick()
RunService.Heartbeat:Connect(function()
	local currentTime = tick()
	local deltaTime = currentTime - lastUpdate
	lastUpdate = currentTime
	
	-- Update game manager (handles waves, timers, etc.)
	gameManager:update(deltaTime)
end)

-- Wait for minimum players and start game automatically
-- (Optional: you can add a lobby system here)
task.spawn(function()
	print("Waiting for players...")
	
	-- Wait until at least 1 player joins
	repeat
		task.wait(1)
	until #Players:GetPlayers() >= 1
	
	print("Starting game with " .. #Players:GetPlayers() .. " players")
	
	-- Game will auto-start from GameManager's update loop
	-- when it detects players in WAITING state
end)

-- Debug commands (optional)
-- You can add admin commands here for testing

print("=== Server Ready ===")
