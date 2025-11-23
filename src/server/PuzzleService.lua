-- PuzzleService.lua
-- Server-side puzzle management system
-- Handles puzzle generation, validation, and tracking for cure synthesis

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PuzzleConfig = require(ReplicatedStorage.Shared.PuzzleConfig)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local PuzzleService = {}
PuzzleService.__index = PuzzleService

function PuzzleService.new(cureService, playerManager)
	local self = setmetatable({}, PuzzleService)
	
	self.cureService = cureService
	self.playerManager = playerManager
	
	-- Track puzzle state per player
	-- Structure: playerPuzzles[userId] = {componentName = {solved = bool, attempts = num, currentPuzzle = data}}
	self.playerPuzzles = {}
	
	-- Track which players have completed all 5 component puzzles and can attempt final
	self.playersReadyForFinal = {}
	
	-- Track puzzle instances for validation
	self.activePuzzles = {}
	
	self:setupRemoteEvents()
	
	print("[PuzzleService] Initialized")
	
	return self
end

function PuzzleService:setupRemoteEvents()
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then
		remoteEvents = Instance.new("Folder")
		remoteEvents.Name = "RemoteEvents"
		remoteEvents.Parent = ReplicatedStorage
	end
	
	-- Create puzzle-related remote events
	local eventNames = {
		"RequestPuzzle",      -- Client requests to start a puzzle
		"SubmitPuzzleAnswer", -- Client submits puzzle solution
		"PuzzleUpdate",       -- Server sends puzzle state updates
		"PuzzleFailed",       -- Server notifies puzzle failure
		"PuzzleCompleted",    -- Server notifies puzzle completion
		"OpenPuzzleUI",       -- Server tells client to open puzzle UI
		"RequestPuzzleProgress", -- Client requests puzzle progress data
	}
	
	for _, eventName in ipairs(eventNames) do
		local event = remoteEvents:FindFirstChild(eventName)
		if not event then
			event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = remoteEvents
		end
	end
	
	-- Connect event handlers
	remoteEvents.RequestPuzzle.OnServerEvent:Connect(function(player, componentName)
		self:handlePuzzleRequest(player, componentName)
	end)
	
	remoteEvents.SubmitPuzzleAnswer.OnServerEvent:Connect(function(player, componentName, answer)
		self:handlePuzzleAnswer(player, componentName, answer)
	end)
	
	remoteEvents.RequestPuzzleProgress.OnServerEvent:Connect(function(player)
		self:sendPuzzleProgress(player)
	end)
end

-- Send puzzle progress to client
function PuzzleService:sendPuzzleProgress(player)
	local progress = self:getPuzzleProgress(player)
	
	-- Add component counts from CureService
	if self.playerManager then
		local playerData = self.playerManager:GetPlayerData(player)
		if playerData and playerData.CureComponents then
			progress.componentCounts = {}
			for _, componentName in ipairs(GameConfig.CURE_COMPONENT_NAMES) do
				local count = 0
				for _, comp in ipairs(playerData.CureComponents) do
					if comp == componentName then
						count = count + 1
					end
				end
				progress.componentCounts[componentName] = count
			end
		end
	end
	
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents and remoteEvents:FindFirstChild("PuzzleUpdate") then
		remoteEvents.PuzzleUpdate:FireClient(player, {
			type = "progress",
			progress = progress
		})
	end
end

function PuzzleService:initializePlayer(player)
	local userId = player.UserId
	
	if not self.playerPuzzles[userId] then
		self.playerPuzzles[userId] = {}
		
		-- Initialize puzzle state for each component
		for componentName, puzzleData in pairs(PuzzleConfig.ComponentPuzzles) do
			self.playerPuzzles[userId][componentName] = {
				solved = false,
				attempts = 0,
				currentPuzzle = nil,
				lastAttemptTime = 0
			}
		end
		
		-- Initialize final puzzle state
		self.playerPuzzles[userId]["FinalSynthesis"] = {
			solved = false,
			attempts = 0,
			currentPuzzle = nil,
			lastAttemptTime = 0
		}
	end
end

function PuzzleService:checkPlayerHasComponents(player, componentName)
	-- Check if player has collected 5 of the specified component
	local playerData = self.playerManager:GetPlayerData(player)
	if not playerData or not playerData.CureComponents then
		return false
	end
	
	local count = 0
	for _, comp in ipairs(playerData.CureComponents) do
		if comp == componentName then
			count = count + 1
		end
	end
	
	return count >= GameConfig.CURE_COMPONENTS_REQUIRED
end

function PuzzleService:checkPlayerReadyForFinal(player)
	-- Check if player has solved all 5 component puzzles
	local userId = player.UserId
	local puzzleState = self.playerPuzzles[userId]
	
	if not puzzleState then
		return false
	end
	
	for componentName, _ in pairs(PuzzleConfig.ComponentPuzzles) do
		if not puzzleState[componentName] or not puzzleState[componentName].solved then
			return false
		end
	end
	
	return true
end

function PuzzleService:handlePuzzleRequest(player, componentName)
	local userId = player.UserId
	
	-- Initialize player if needed
	self:initializePlayer(player)
	
	local puzzleState = self.playerPuzzles[userId][componentName]
	if not puzzleState then
		warn("[PuzzleService] Invalid component name:", componentName)
		return
	end
	
	-- Check if puzzle already solved
	if puzzleState.solved then
		print("[PuzzleService]", player.Name, "already solved", componentName, "puzzle")
		return
	end
	
	-- Check retry delay
	local currentTime = tick()
	if puzzleState.lastAttemptTime > 0 then
		local timeSinceLastAttempt = currentTime - puzzleState.lastAttemptTime
		if timeSinceLastAttempt < PuzzleConfig.Penalties.retryDelay then
			local waitTime = math.ceil(PuzzleConfig.Penalties.retryDelay - timeSinceLastAttempt)
			self:sendPuzzleError(player, "Please wait " .. waitTime .. " seconds before retrying")
			return
		end
	end
	
	-- Check max attempts
	if PuzzleConfig.Penalties.maxAttempts > 0 and puzzleState.attempts >= PuzzleConfig.Penalties.maxAttempts then
		self:sendPuzzleError(player, "Maximum attempts reached for this puzzle")
		return
	end
	
	-- For component puzzles, verify player has collected 5 components
	if componentName ~= "FinalSynthesis" then
		if not self:checkPlayerHasComponents(player, componentName) then
			self:sendPuzzleError(player, "You need 5 " .. componentName .. " pieces to attempt this puzzle")
			return
		end
	else
		-- For final synthesis, check all component puzzles are solved
		if not self:checkPlayerReadyForFinal(player) then
			self:sendPuzzleError(player, "Complete all 5 component puzzles before attempting synthesis")
			return
		end
	end
	
	-- Generate puzzle based on component type
	local puzzle = self:generatePuzzle(componentName)
	puzzleState.currentPuzzle = puzzle
	puzzleState.attempts = puzzleState.attempts + 1
	
	print("[PuzzleService]", player.Name, "started puzzle for", componentName)
	
	-- Send puzzle to client
	self:sendPuzzleToClient(player, componentName, puzzle)
end

function PuzzleService:generatePuzzle(componentName)
	local puzzleConfig = componentName == "FinalSynthesis" 
		and PuzzleConfig.FinalPuzzle 
		or PuzzleConfig.ComponentPuzzles[componentName]
	
	if not puzzleConfig then
		warn("[PuzzleService] No puzzle config for:", componentName)
		return nil
	end
	
	local puzzle = {
		type = puzzleConfig.type,
		name = puzzleConfig.name,
		description = puzzleConfig.description,
		timeLimit = puzzleConfig.timeLimit,
		startTime = tick()
	}
	
	-- Generate specific puzzle data based on type
	if puzzleConfig.type == PuzzleConfig.PuzzleTypes.MATHEMATICAL then
		puzzle.data = PuzzleConfig.generateMathPuzzle()
		
	elseif puzzleConfig.type == PuzzleConfig.PuzzleTypes.PATTERN then
		puzzle.data = PuzzleConfig.generatePatternPuzzle()
		
	elseif puzzleConfig.type == PuzzleConfig.PuzzleTypes.COLOR then
		-- Generate color puzzle
		local colorTemplate = PuzzleConfig.ColorPuzzles[1] -- Use spectrum for now
		local colors = {}
		for i, color in ipairs(colorTemplate.colors) do
			colors[i] = color
		end
		-- Shuffle colors
		for i = #colors, 2, -1 do
			local j = math.random(1, i)
			colors[i], colors[j] = colors[j], colors[i]
		end
		puzzle.data = {
			shuffled = colors,
			correct = colorTemplate.colors,
			type = colorTemplate.type
		}
		
	elseif puzzleConfig.type == PuzzleConfig.PuzzleTypes.LOGIC then
		-- Generate logic puzzle (simplified for implementation)
		local template = PuzzleConfig.LogicPuzzles[1]
		puzzle.data = {
			elements = template.elements,
			scientists = template.scientists,
			labs = template.labs,
			-- Generate clues and solution
			solution = self:generateLogicSolution(template)
		}
		
	elseif puzzleConfig.type == PuzzleConfig.PuzzleTypes.ABSTRACT then
		-- Generate node connection puzzle
		local template = PuzzleConfig.AbstractPuzzles[1]
		puzzle.data = {
			nodeCount = template.nodeCount,
			type = template.type,
			solution = self:generateAbstractSolution(template)
		}
		
	elseif puzzleConfig.type == PuzzleConfig.PuzzleTypes.SYNTHESIS then
		-- Final puzzle combines multiple stages
		puzzle.data = {
			stages = {
				{type = "math", puzzle = PuzzleConfig.generateMathPuzzle()},
				{type = "pattern", puzzle = PuzzleConfig.generatePatternPuzzle()},
				{type = "color", puzzle = {answer = "spectrum"}},
				{type = "logic", puzzle = {answer = "deduction"}},
				{type = "abstract", puzzle = {answer = "circuit"}}
			},
			currentStage = 1
		}
	end
	
	return puzzle
end

function PuzzleService:generateLogicSolution(template)
	-- Generate a valid solution for logic puzzle
	-- Simplified: just create a random valid mapping
	local solution = {}
	local usedLabs = {}
	
	for i, scientist in ipairs(template.scientists) do
		local element = template.elements[i]
		local lab = template.labs[i]
		solution[scientist] = {element = element, lab = lab}
	end
	
	return solution
end

function PuzzleService:generateAbstractSolution(template)
	-- Generate a valid solution for abstract puzzle
	-- Simplified: create a path through all nodes
	local solution = {}
	for i = 1, template.nodeCount do
		solution[i] = i
	end
	return solution
end

function PuzzleService:sendPuzzleToClient(player, componentName, puzzle)
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents and remoteEvents:FindFirstChild("OpenPuzzleUI") then
		remoteEvents.OpenPuzzleUI:FireClient(player, {
			componentName = componentName,
			puzzle = puzzle
		})
	end
end

function PuzzleService:sendPuzzleError(player, message)
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents and remoteEvents:FindFirstChild("PuzzleFailed") then
		remoteEvents.PuzzleFailed:FireClient(player, message)
	end
end

function PuzzleService:handlePuzzleAnswer(player, componentName, answer)
	local userId = player.UserId
	if not self.playerPuzzles[userId] then
		warn("[PuzzleService] Player not initialized:", player.Name)
		return
	end
	local puzzleState = self.playerPuzzles[userId][componentName]
	
	if not puzzleState or not puzzleState.currentPuzzle then
		warn("[PuzzleService] No active puzzle for", player.Name, componentName)
		return
	end
	
	-- Check time limit
	local elapsedTime = tick() - puzzleState.currentPuzzle.startTime
	if elapsedTime > puzzleState.currentPuzzle.timeLimit then
		self:onPuzzleFailed(player, componentName, "Time limit exceeded")
		return
	end
	
	-- Validate answer
	local isCorrect = self:validateAnswer(puzzleState.currentPuzzle, answer)
	
	if isCorrect then
		self:onPuzzleCompleted(player, componentName, elapsedTime)
	else
		self:onPuzzleFailed(player, componentName, "Incorrect answer")
	end
end

function PuzzleService:validateAnswer(puzzle, answer)
	if not puzzle or not puzzle.data then
		return false
	end
	
	-- Validate based on puzzle type
	if puzzle.type == PuzzleConfig.PuzzleTypes.MATHEMATICAL then
		return answer == puzzle.data.answer
		
	elseif puzzle.type == PuzzleConfig.PuzzleTypes.PATTERN then
		return answer == puzzle.data.answer
		
	elseif puzzle.type == PuzzleConfig.PuzzleTypes.COLOR then
		-- Check if color order matches
		if type(answer) ~= "table" then return false end
		for i, color in ipairs(puzzle.data.correct) do
			local answerColor = answer[i]
			if not answerColor then
				return false
			end
			local dr = math.abs(color.R - answerColor.R)
			local dg = math.abs(color.G - answerColor.G)
			local db = math.abs(color.B - answerColor.B)
			if dr > 0.01 or dg > 0.01 or db > 0.01 then
				return false
			end
		end
		return true
		
	elseif puzzle.type == PuzzleConfig.PuzzleTypes.LOGIC then
		-- Validate logic solution
		-- TODO: Implement proper deduction grid validation
		-- Full implementation would include:
		--   1. Parse player's arrangement of elements/scientists/labs
		--   2. Check each arrangement against generated clues
		--   3. Verify no conflicts with given constraints
		--   4. Return true only if all constraints satisfied
		-- Example: If clue says "Dr. Smith studied Compound X in Lab A",
		-- verify player's grid matches this relationship
		-- See PUZZLE_SYSTEM.md for deduction puzzle examples
		return answer == "correct" -- Simplified for MVP
		
	elseif puzzle.type == PuzzleConfig.PuzzleTypes.ABSTRACT then
		-- Validate node connections
		-- TODO: Implement proper graph/circuit validation
		-- Full implementation would include:
		--   1. Parse player's connection data (node pairs)
		--   2. Build graph from connections
		--   3. Verify all nodes are connected
		--   4. Check no crossing lines (for planar graphs)
		--   5. Validate forms complete circuit (Hamiltonian path)
		-- Could use graph algorithms like DFS/BFS for connectivity check
		-- See PuzzleConfig.AbstractPuzzles for puzzle templates
		return answer == "circuit" -- Simplified for MVP
		
	elseif puzzle.type == PuzzleConfig.PuzzleTypes.SYNTHESIS then
		-- Validate multi-stage answer
		-- TODO: Implement multi-stage validation for final synthesis
		-- Full implementation would:
		--   1. Track current stage completion (1-5)
		--   2. Validate each stage answer separately:
		--      - Stage 1: Math answer validation
		--      - Stage 2: Pattern answer validation
		--      - Stage 3: Color arrangement validation
		--      - Stage 4: Logic deduction validation
		--      - Stage 5: Circuit connection validation
		--   3. Progress to next stage only if current stage correct
		--   4. Return true only when all 5 stages completed
		-- Could use puzzle.data.currentStage to track progress
		return true -- Simplified - full implementation would validate each stage
	end
	
	return false
end

function PuzzleService:onPuzzleCompleted(player, componentName, elapsedTime)
	local userId = player.UserId
	local puzzleState = self.playerPuzzles[userId][componentName]
	
	puzzleState.solved = true
	puzzleState.currentPuzzle = nil
	puzzleState.lastAttemptTime = tick()
	
	print("[PuzzleService]", player.Name, "solved", componentName, "puzzle in", math.floor(elapsedTime), "seconds")
	
	-- Award currency
	local reward = PuzzleConfig.Rewards.componentPuzzleSolved
	if componentName == "FinalSynthesis" then
		reward = PuzzleConfig.Rewards.finalPuzzleSolved
	end
	
	-- Time bonus
	local puzzleConfig = componentName == "FinalSynthesis" 
		and PuzzleConfig.FinalPuzzle 
		or PuzzleConfig.ComponentPuzzles[componentName]
	
	if elapsedTime < puzzleConfig.timeLimit / 2 then
		reward = math.floor(reward * PuzzleConfig.Rewards.timeBonusMultiplier)
	end
	
	self.playerManager:addCurrency(player, reward)
	
	-- Notify client
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents and remoteEvents:FindFirstChild("PuzzleCompleted") then
		remoteEvents.PuzzleCompleted:FireClient(player, {
			componentName = componentName,
			reward = reward,
			timeTaken = elapsedTime
		})
	end
	
	-- Check if player completed all component puzzles
	if componentName ~= "FinalSynthesis" then
		if self:checkPlayerReadyForFinal(player) then
			self.playersReadyForFinal[userId] = true
			print("[PuzzleService]", player.Name, "is ready for final synthesis puzzle!")
		end
	else
		-- Player completed final synthesis - trigger cure completion
		print("[PuzzleService]", player.Name, "completed FINAL SYNTHESIS! Cure is complete!")
		if self.cureService and self.cureService.onFinalSynthesisComplete then
			self.cureService:onFinalSynthesisComplete(player)
		end
	end
end

function PuzzleService:onPuzzleFailed(player, componentName, reason)
	local userId = player.UserId
	local puzzleState = self.playerPuzzles[userId][componentName]
	
	puzzleState.currentPuzzle = nil
	puzzleState.lastAttemptTime = tick()
	
	print("[PuzzleService]", player.Name, "failed", componentName, "puzzle:", reason)
	
	-- Notify client
	self:sendPuzzleError(player, "Puzzle failed: " .. reason)
end

function PuzzleService:canAttemptPuzzle(player, componentName)
	local userId = player.UserId
	self:initializePlayer(player)
	
	local puzzleState = self.playerPuzzles[userId][componentName]
	if not puzzleState then
		return false, "Invalid puzzle"
	end
	
	if puzzleState.solved then
		return false, "Already solved"
	end
	
	if PuzzleConfig.Penalties.maxAttempts > 0 and puzzleState.attempts >= PuzzleConfig.Penalties.maxAttempts then
		return false, "Maximum attempts reached"
	end
	
	return true, "Can attempt"
end

function PuzzleService:getPuzzleProgress(player)
	local userId = player.UserId
	self:initializePlayer(player)
	
	local progress = {
		componentPuzzles = {},
		finalPuzzle = {},
		readyForFinal = false
	}
	
	for componentName, puzzleConfig in pairs(PuzzleConfig.ComponentPuzzles) do
		local puzzleState = self.playerPuzzles[userId][componentName]
		progress.componentPuzzles[componentName] = {
			solved = puzzleState.solved,
			attempts = puzzleState.attempts,
			name = puzzleConfig.name,
			type = puzzleConfig.type
		}
	end
	
	progress.finalPuzzle = {
		solved = self.playerPuzzles[userId]["FinalSynthesis"].solved,
		attempts = self.playerPuzzles[userId]["FinalSynthesis"].attempts
	}
	
	progress.readyForFinal = self:checkPlayerReadyForFinal(player)
	
	return progress
end

-- Betrayal mechanics
function PuzzleService:onBetrayal(betrayer, victim)
	if not PuzzleConfig.BetrayalMechanics.canStealSolvedPuzzles then
		return
	end
	
	local betrayerUserId = betrayer.UserId
	local victimUserId = victim.UserId
	
	self:initializePlayer(betrayer)
	self:initializePlayer(victim)
	
	local victimPuzzles = self.playerPuzzles[victimUserId]
	local betrayerPuzzles = self.playerPuzzles[betrayerUserId]
	
	-- Steal solved puzzles
	for componentName, puzzleState in pairs(victimPuzzles) do
		if puzzleState.solved and betrayerPuzzles[componentName] and not betrayerPuzzles[componentName].solved then
			-- Steal with probability
			if math.random() < PuzzleConfig.BetrayalMechanics.stealPercentage then
				betrayerPuzzles[componentName].solved = true
				print("[PuzzleService]", betrayer.Name, "stole", componentName, "puzzle from", victim.Name)
			end
		end
	end
	
	-- Potentially reset victim's puzzles
	if math.random() < PuzzleConfig.BetrayalMechanics.betrayalPuzzleResetChance then
		for componentName, puzzleState in pairs(victimPuzzles) do
			if componentName ~= "FinalSynthesis" then
				puzzleState.solved = false
				puzzleState.attempts = 0
			end
		end
		print("[PuzzleService]", victim.Name, "'s puzzles were reset by betrayal!")
	end
end

return PuzzleService
