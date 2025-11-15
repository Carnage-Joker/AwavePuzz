-- CureService.lua
-- Server script that manages cure crafting puzzle system and win condition

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local CureService = {}
CureService.__index = CureService

function CureService.new(gameManager)
	local self = setmetatable({}, CureService)
	
	self.gameManager = gameManager -- Reference to GameManager to trigger victory
	
	-- Cure progress tracking
	self.componentsCollected = {}
	self.totalComponentsNeeded = #GameConfig.CURE_COMPONENT_NAMES * GameConfig.CURE_COMPONENTS_REQUIRED
	
	-- Initialize component counts
	for _, componentName in ipairs(GameConfig.CURE_COMPONENT_NAMES) do
		self.componentsCollected[componentName] = 0
	end
	
	-- Player contributions
	self.playerContributions = {} -- UserId -> contribution count
	
	-- Cure stations
	self.cureStations = {}
	
	-- Remote events
	self.remoteEvents = {}
	self:setupRemoteEvents()
	
	-- Setup cure stations
	self:setupCureStations()
	
	return self
end

function CureService:setupRemoteEvents()
	local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEventsFolder then
		remoteEventsFolder = Instance.new("Folder")
		remoteEventsFolder.Name = "RemoteEvents"
		remoteEventsFolder.Parent = ReplicatedStorage
	end
	
	-- Cure Action (player attempts puzzle or deposits component)
	local cureActionEvent = remoteEventsFolder:FindFirstChild("CureAction")
	if not cureActionEvent then
		cureActionEvent = Instance.new("RemoteEvent")
		cureActionEvent.Name = "CureAction"
		cureActionEvent.Parent = remoteEventsFolder
	end
	self.remoteEvents.CureAction = cureActionEvent
	
	-- Cure Update (server to client)
	local cureUpdateEvent = remoteEventsFolder:FindFirstChild("CureUpdate")
	if not cureUpdateEvent then
		cureUpdateEvent = Instance.new("RemoteEvent")
		cureUpdateEvent.Name = "CureUpdate"
		cureUpdateEvent.Parent = remoteEventsFolder
	end
	self.remoteEvents.CureUpdate = cureUpdateEvent
	
	-- Connect handler
	cureActionEvent.OnServerEvent:Connect(function(player, actionType, data)
		self:handleCureAction(player, actionType, data)
	end)
end

function CureService:setupCureStations()
	-- Find cure stations in workspace
	local cureStationsFolder = workspace:FindFirstChild("CureStations")
	if cureStationsFolder then
		for _, station in ipairs(cureStationsFolder:GetChildren()) do
			if station:IsA("Model") or station:IsA("BasePart") then
				self:registerCureStation(station)
			end
		end
	end
	
	print("Registered " .. #self.cureStations .. " cure stations")
end

function CureService:registerCureStation(station)
	-- Setup proximity prompt for interaction
	local primaryPart = station:IsA("Model") and station.PrimaryPart or station
	
	if primaryPart then
		local proximityPrompt = primaryPart:FindFirstChild("ProximityPrompt")
		if not proximityPrompt then
			proximityPrompt = Instance.new("ProximityPrompt")
			proximityPrompt.ActionText = "Use Cure Station"
			proximityPrompt.ObjectText = "Cure Research"
			proximityPrompt.HoldDuration = 0.5
			proximityPrompt.MaxActivationDistance = 10
			proximityPrompt.Parent = primaryPart
		end
		
		-- Connect interaction
		proximityPrompt.Triggered:Connect(function(player)
			self:onStationInteraction(player, station)
		end)
		
		table.insert(self.cureStations, station)
	end
end

function CureService:onStationInteraction(player, station)
	-- Open cure UI for player
	self.remoteEvents.CureUpdate:FireClient(player, {
		type = "openUI",
		station = station,
		components = self.componentsCollected,
		progress = self:getCureProgress()
	})
end

function CureService:handleCureAction(player, actionType, data)
	if actionType == "depositComponent" then
		self:handleDepositComponent(player, data.componentName)
		
	elseif actionType == "solvePuzzle" then
		self:handlePuzzleSolution(player, data)
		
	elseif actionType == "requestProgress" then
		self:sendProgressUpdate(player)
	end
end

function CureService:handleDepositComponent(player, componentName)
	-- Validate component
	if not componentName or not self.componentsCollected[componentName] then
		print("Invalid component: " .. tostring(componentName))
		return
	end
	
	-- Check if already maxed out
	if self.componentsCollected[componentName] >= GameConfig.CURE_COMPONENTS_REQUIRED then
		self.remoteEvents.CureUpdate:FireClient(player, {
			type = "error",
			message = "Already have enough " .. componentName
		})
		return
	end
	
	-- Check if player has this component (would need inventory system)
	-- For now, we'll allow direct deposit
	
	-- Add component
	self.componentsCollected[componentName] = self.componentsCollected[componentName] + 1
	
	-- Track player contribution
	if not self.playerContributions[player.UserId] then
		self.playerContributions[player.UserId] = 0
	end
	self.playerContributions[player.UserId] = self.playerContributions[player.UserId] + 1
	
	-- Calculate progress
	local progress = self:getCureProgress()
	
	-- Broadcast update to all players
	self.remoteEvents.CureUpdate:FireAllClients({
		type = "progress",
		progress = progress,
		components = self.componentsCollected,
		contributor = player.Name,
		componentAdded = componentName
	})
	
	-- Update game manager
	if self.gameManager then
		self.gameManager:updateCureProgress(progress)
	end
	
	print(player.Name .. " deposited " .. componentName .. ". Progress: " .. progress .. "%")
	
	-- Check if cure is complete
	if progress >= 100 then
		self:onCureComplete()
	end
end

function CureService:handlePuzzleSolution(player, puzzleData)
	-- Validate puzzle solution
	-- This is a placeholder for puzzle mechanics
	-- Actual implementation would depend on puzzle type
	
	local isCorrect = self:validatePuzzle(puzzleData)
	
	if isCorrect then
		-- Reward with a component or progress
		local randomComponent = GameConfig.CURE_COMPONENT_NAMES[math.random(1, #GameConfig.CURE_COMPONENT_NAMES)]
		self:handleDepositComponent(player, randomComponent)
		
		self.remoteEvents.CureUpdate:FireClient(player, {
			type = "puzzleSuccess",
			reward = randomComponent
		})
	else
		self.remoteEvents.CureUpdate:FireClient(player, {
			type = "puzzleFailed"
		})
	end
end

function CureService:validatePuzzle(puzzleData)
	-- Placeholder puzzle validation
	-- In a real implementation, this would check puzzle-specific solutions
	
	if puzzleData.type == "sequence" then
		-- Check if sequence matches expected
		return puzzleData.solution == puzzleData.expected
		
	elseif puzzleData.type == "code" then
		-- Check if code is correct
		return puzzleData.code == puzzleData.correctCode
		
	elseif puzzleData.type == "simon" then
		-- Check if pattern matches
		return table.concat(puzzleData.pattern) == table.concat(puzzleData.correctPattern)
	end
	
	-- Default: 50% chance (for testing)
	return math.random() > 0.5
end

function CureService:getCureProgress()
	local totalCollected = 0
	
	for _, count in pairs(self.componentsCollected) do
		totalCollected = totalCollected + count
	end
	
	return math.floor((totalCollected / self.totalComponentsNeeded) * 100)
end

function CureService:isCureComplete()
	for componentName, count in pairs(self.componentsCollected) do
		if count < GameConfig.CURE_COMPONENTS_REQUIRED then
			return false
		end
	end
	return true
end

function CureService:onCureComplete()
	print("CURE COMPLETE!")
	
	-- Broadcast completion
	self.remoteEvents.CureUpdate:FireAllClients({
		type = "complete",
		topContributors = self:getTopContributors(3)
	})
	
	-- Game manager handles victory state
	-- Already called via updateCureProgress
end

function CureService:getTopContributors(count)
	local contributors = {}
	
	for userId, contributionCount in pairs(self.playerContributions) do
		local player = game.Players:GetPlayerByUserId(userId)
		if player then
			table.insert(contributors, {
				name = player.Name,
				contributions = contributionCount
			})
		end
	end
	
	-- Sort by contributions
	table.sort(contributors, function(a, b)
		return a.contributions > b.contributions
	end)
	
	-- Return top N
	local topN = {}
	for i = 1, math.min(count, #contributors) do
		table.insert(topN, contributors[i])
	end
	
	return topN
end

function CureService:sendProgressUpdate(player)
	self.remoteEvents.CureUpdate:FireClient(player, {
		type = "progress",
		progress = self:getCureProgress(),
		components = self.componentsCollected
	})
end

function CureService:getRemainingComponents()
	local remaining = {}
	
	for _, componentName in ipairs(GameConfig.CURE_COMPONENT_NAMES) do
		local needed = GameConfig.CURE_COMPONENTS_REQUIRED - self.componentsCollected[componentName]
		if needed > 0 then
			remaining[componentName] = needed
		end
	end
	
	return remaining
end

return CureService
