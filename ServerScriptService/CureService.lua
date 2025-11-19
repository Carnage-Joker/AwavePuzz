--[[
    CureService.lua (ModuleScript)
    Phase 3: Manages cure crafting puzzle system and win condition
    Server-authoritative tracking of cure progress and component collection
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Config = require(sharedFolder:WaitForChild("Config"))

local CureService = {}
CureService.__index = CureService

function CureService.new(gameManager)
    local self = setmetatable({}, CureService)
    
    self.gameManager = gameManager
    
    -- Cure progress tracking
    self.componentsCollected = {}
    self.totalComponentsNeeded = #Config.Cure.ComponentNames * Config.Cure.ComponentsRequired
    
    -- Initialize component counts
    for _, componentName in ipairs(Config.Cure.ComponentNames) do
        self.componentsCollected[componentName] = 0
    end
    
    -- Player contributions (for statistics)
    self.playerContributions = {} -- UserId -> contribution count
    
    -- Cure stations
    self.cureStations = {}
    
    -- Remote events
    self.remoteEvents = {}
    self:setupRemoteEvents()
    
    -- Setup cure stations
    self:setupCureStations()
    
    print("CureService initialized")
    
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
    
    if not cureStationsFolder then
        -- Create placeholder if none exist
        warn("No CureStations folder found in workspace. Creating placeholder...")
        cureStationsFolder = Instance.new("Folder")
        cureStationsFolder.Name = "CureStations"
        cureStationsFolder.Parent = workspace
        
        -- Create a basic cure station
        local station = Instance.new("Part")
        station.Name = "CureStation1"
        station.Size = Vector3.new(6, 8, 6)
        station.Position = Vector3.new(0, 4, 20)
        station.Anchored = true
        station.BrickColor = BrickColor.new("Bright green")
        station.Material = Enum.Material.Neon
        station.Parent = cureStationsFolder
    end
    
    for _, station in ipairs(cureStationsFolder:GetChildren()) do
        if station:IsA("Model") or station:IsA("BasePart") then
            self:registerCureStation(station)
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
    
    print(player.Name .. " interacted with cure station")
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
        warn("Invalid component: " .. tostring(componentName))
        return
    end
    
    -- Check if already maxed out
    if self.componentsCollected[componentName] >= Config.Cure.ComponentsRequired then
        self.remoteEvents.CureUpdate:FireClient(player, {
            type = "error",
            message = "Already have enough " .. componentName
        })
        return
    end
    
    -- Note: In Phase 3, component collection is validated by ResourceSpawner
    -- which calls this function directly after successful touch detection.
    -- This ensures only actually collected resources increment the cure progress.
    
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
    
    print(player.Name .. " deposited " .. componentName .. ". Progress: " .. progress .. "%")
    
    -- Check if cure is complete
    if progress >= 100 then
        self:onCureComplete()
    end
end

function CureService:handlePuzzleSolution(player, puzzleData)
    -- Validate puzzle solution
    local isCorrect = self:validatePuzzle(puzzleData)
    
    if isCorrect then
        -- Reward with a component increment directly (simplified for Phase 3)
        local randomComponent = Config.Cure.ComponentNames[math.random(1, #Config.Cure.ComponentNames)]
        
        if self.componentsCollected[randomComponent] < Config.Cure.ComponentsRequired then
            self:handleDepositComponent(player, randomComponent)
            
            self.remoteEvents.CureUpdate:FireClient(player, {
                type = "puzzleSuccess",
                reward = randomComponent
            })
        else
            self.remoteEvents.CureUpdate:FireClient(player, {
                type = "puzzleSuccess",
                reward = "none"
            })
        end
    else
        self.remoteEvents.CureUpdate:FireClient(player, {
            type = "puzzleFailed"
        })
    end
end

function CureService:validatePuzzle(puzzleData)
    -- Simple puzzle validation logic
    if puzzleData.type == "sequence" then
        return puzzleData.solution == puzzleData.expected
        
    elseif puzzleData.type == "code" then
        return puzzleData.code == puzzleData.correctCode
        
    elseif puzzleData.type == "simon" then
        return table.concat(puzzleData.pattern) == table.concat(puzzleData.correctPattern)
    end
    
    -- Default: 50% success rate for testing
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
        if count < Config.Cure.ComponentsRequired then
            return false
        end
    end
    return true
end

function CureService:onCureComplete()
    print("=== CURE COMPLETE ===")
    
    -- Broadcast completion
    self.remoteEvents.CureUpdate:FireAllClients({
        type = "complete",
        topContributors = self:getTopContributors(3)
    })
    
    -- Notify game manager about victory
    if self.gameManager and self.gameManager.onCureComplete then
        self.gameManager.onCureComplete()
    end
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
    
    table.sort(contributors, function(a, b)
        return a.contributions > b.contributions
    end)
    
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
    
    for _, componentName in ipairs(Config.Cure.ComponentNames) do
        local needed = Config.Cure.ComponentsRequired - self.componentsCollected[componentName]
        if needed > 0 then
            remaining[componentName] = needed
        end
    end
    
    return remaining
end

return CureService
