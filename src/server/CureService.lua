-- CureService
-- Handles cure component deposits and related logic

local CureService = {}
CureService.__index = CureService

-- Constructor for CureService
function CureService.new(gameManager, playerManager)
    local self = setmetatable({}, CureService)
    self.gameManager = gameManager
    self.playerManager = playerManager
    -- Initialize other properties if needed
    return self
end

-- Add the missing handleDepositComponent method
function CureService:handleDepositComponent(player, componentName)
    -- TODO: Implement component deposit logic
    print("Depositing cure component:", componentName, "for player:", player.Name)

   
	local playerData = self:GetPlayerData(player)
	if not playerData then
		warn("No player data found for", player.Name)
		return false
	end
	
	if not playerData.CureComponents then
		playerData.CureComponents = {}
	end
	
	if playerData.CureComponents[componentName] then
		playerData.CureComponents[componentName] = playerData.CureComponents[componentName] + 1
	else
		playerData.CureComponents[componentName] = 1
	end
	
	local cureManager = self.gameManager:GetCureManager()
	if cureManager then
		cureManager:addComponent(player, componentName)
	end
	
	local playerData = self.playerManager:GetPlayerData(player)
	if not playerData then
		warn("No player data found for", player.Name)
		return false
	end
	
	if not playerData.CureComponents then
		playerData.CureComponents = {}
	end
	
	table.insert(playerData.CureComponents, componentName)
    self:CheckCureProgress(player)

    -- Fire an event to update the UI
	game.ReplicatedStorage.Events.CureComponentAdded:FireClient(player, componentName)
	print("Cure components for player:", player.Name, ":", playerData.CureComponents)
	return true
	
end

return CureService

