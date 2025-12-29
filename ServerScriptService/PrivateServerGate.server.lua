--[[
	PrivateServerGate.server.lua
	Enforces private server requirement - kicks players not in a private server
]]

local Players = game:GetService("Players")

-- Check if this is a private server
local function isPrivateServer()
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
end

-- Kick message for non-private servers
local KICK_MESSAGE = [[
🔒 Private Server Required

This experience is designed for private servers only.

To play:
1. Go to the game page
2. Click "..." menu
3. Select "Configure this Place"
4. Create a private server

Thank you for understanding!
]]

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
	-- Small delay to ensure server info is available
	task.wait(0.5)
	
	if not isPrivateServer() then
		player:Kick(KICK_MESSAGE)
		warn(string.format("Kicked player %s - Not in a private server", player.Name))
	else
		print(string.format("Player %s joined private server (Owner: %d)", player.Name, game.PrivateServerOwnerId))
	end
end)

-- Also check existing players (in case script loads after players join)
for _, player in ipairs(Players:GetPlayers()) do
	if not isPrivateServer() then
		player:Kick(KICK_MESSAGE)
		warn(string.format("Kicked player %s - Not in a private server", player.Name))
	end
end

print("🔒 PrivateServerGate active - Private server enforcement enabled")
