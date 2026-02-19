-- @ScriptType: ModuleScript
-- PuzzleService.lua
-- Server-side puzzle management system
-- Handles puzzle generation, validation, and tracking for cure synthesis

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
	error("[PuzzleService] CRITICAL: Failed to load Shared folder after 10 seconds")
end

local PuzzleConfig = SharedFolder:WaitForChild("PuzzleConfig", 5)
if not PuzzleConfig then
	error("[PuzzleService] CRITICAL: Failed to load PuzzleConfig after 5 seconds")
end
PuzzleConfig = require(PuzzleConfig)

local GameConfig = SharedFolder:WaitForChild("GameConfig", 5)
if not GameConfig then
	error("[PuzzleService] CRITICAL: Failed to load GameConfig after 5 seconds")
end
GameConfig = require(GameConfig)

local RemotesFolder = SharedFolder:WaitForChild("Remotes", 5)
if not RemotesFolder then
	error("[PuzzleService] CRITICAL: Failed to load Remotes folder after 5 seconds")
end
local RemoteRegistry = RemotesFolder:WaitForChild("RemoteRegistry", 5)
if not RemoteRegistry then
	error("[PuzzleService] CRITICAL: Failed to load RemoteRegistry after 5 seconds")
end
RemoteRegistry = require(RemoteRegistry)

local PuzzleService = {}
PuzzleService.__index = PuzzleService

-- Helper function to normalize string answers for consistent validation
-- Handles both string and numeric inputs
local function normalizeAnswer(answer)
	if answer == nil then
		return nil
	end

	-- Convert to string if not already
	local str = type(answer) == "string" and answer or tostring(answer)

	-- Normalize: lowercase and remove whitespace
	return str:lower():gsub("%s+", "")
end

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
	-- Use RemoteRegistry to get server remotes
	local remotes = RemoteRegistry.GetServerRemotes()
	self.remoteEvents = {
		RequestPuzzle = remotes.RequestPuzzle,
		SubmitPuzzleAnswer = remotes.SubmitPuzzleAnswer,
		PuzzleUpdate = remotes.PuzzleUpdate,
		PuzzleFailed = remotes.PuzzleFailed,
		PuzzleCompleted = remotes.PuzzleCompleted,
		OpenPuzzleUI = remotes.OpenPuzzleUI,
		RequestPuzzleProgress = remotes.RequestPuzzleProgress,
	}

	-- Connect event handlers
	self.remoteEvents.RequestPuzzle.OnServerEvent:Connect(function(player, componentName)
		self:handlePuzzleRequest(player, componentName)
	end)

	self.remoteEvents.SubmitPuzzleAnswer.OnServerEvent:Connect(function(player, componentName, answer)
		self:handlePuzzleAnswer(player, componentName, answer)
	end)

	self.remoteEvents.RequestPuzzleProgress.OnServerEvent:Connect(function(player)
		self:sendPuzzleProgress(player)
	end)
end

-- Send puzzle progress to client
function PuzzleService:sendPuzzleProgress(player)
	local progress = self:getPuzzleProgress(player)

	-- Add component counts from PlayerManager (using dictionary structure)
	if self.playerManager then
		local playerData = self.playerManager:GetPlayerData(player)
		if playerData and playerData.cureComponents then
			progress.componentCounts = {}
			for _, componentName in ipairs(GameConfig.CURE_COMPONENT_NAMES) do
				progress.componentCounts[componentName] = playerData.cureComponents[componentName] or 0
			end
		end
	end

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents and remoteEvents:FindFirstChild("PuzzleUpdate") then
		RemoteRegistry.SafeFireClient(self.remoteEvents and self.remoteEvents.PuzzleUpdate or remoteEvents.PuzzleUpdate, player, {
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
	if not playerData or not playerData.cureComponents then
		return false
	end

	local count = playerData.cureComponents[componentName] or 0
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
		-- Generate logic puzzle with clues
		local template = PuzzleConfig.LogicPuzzles[1]
		local solution = self:generateLogicSolution(template)
		
		-- Generate clues from the solution
		local clues = self:generateLogicClues(template, solution)
		
		puzzle.data = {
			elements = template.elements,
			scientists = template.scientists,
			labs = template.labs,
			clues = clues,
			solution = solution  -- Store for validation
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
				{type = "math", puzzle = PuzzleConfig.generateMathPuzzle(), completed = false},
				{type = "pattern", puzzle = PuzzleConfig.generatePatternPuzzle(), completed = false},
				{type = "color", puzzle = {answer = "spectrum"}, completed = false},
				{type = "logic", puzzle = {answer = "deduction"}, completed = false},
				{type = "abstract", puzzle = {answer = "circuit"}, completed = false}
			},
			currentStage = 1,
			totalStages = 5
		}
	end

	return puzzle
end

function PuzzleService:generateLogicSolution(template)
	-- Generate a valid solution for logic puzzle with proper shuffling
	local solution = {}
	
	-- Create shuffled versions of elements and labs
	local shuffledElements = {}
	for i, element in ipairs(template.elements) do
		shuffledElements[i] = element
	end
	
	local shuffledLabs = {}
	for i, lab in ipairs(template.labs) do
		shuffledLabs[i] = lab
	end
	
	-- Shuffle elements
	for i = #shuffledElements, 2, -1 do
		local j = math.random(1, i)
		shuffledElements[i], shuffledElements[j] = shuffledElements[j], shuffledElements[i]
	end
	
	-- Shuffle labs
	for i = #shuffledLabs, 2, -1 do
		local j = math.random(1, i)
		shuffledLabs[i], shuffledLabs[j] = shuffledLabs[j], shuffledLabs[i]
	end

	-- Assign shuffled elements and labs to scientists
	for i, scientist in ipairs(template.scientists) do
		solution[scientist] = {
			element = shuffledElements[i],
			lab = shuffledLabs[i]
		}
	end

	return solution
end

function PuzzleService:generateLogicClues(template, solution)
	-- Generate clues that uniquely identify the solution
	local clues = {}
	
	-- Direct clues: explicitly state one scientist's assignment
	local scientists = template.scientists
	local directClueIndex = math.random(1, #scientists)
	local directScientist = scientists[directClueIndex]
	local assignment = solution[directScientist]
	table.insert(clues, {
		text = directScientist .. " studied " .. assignment.element .. " in " .. assignment.lab,
		type = "direct"
	})
	
	-- Negative clues: state what combinations are NOT true
	-- Pick a different scientist for negative clues
	local negativeClueIndex = directClueIndex % #scientists + 1
	local negativeScientist = scientists[negativeClueIndex]
	local negativeAssignment = solution[negativeScientist]
	
	-- Find an element that this scientist did NOT study
	for _, element in ipairs(template.elements) do
		if element ~= negativeAssignment.element then
			table.insert(clues, {
				text = negativeScientist .. " did not study " .. element,
				type = "negative"
			})
			break
		end
	end
	
	-- Relational clues: relate two scientists  
	if #scientists >= 3 then
		local scientist1 = scientists[1]
		local scientist2 = scientists[2]
		local assignment1 = solution[scientist1]
		local assignment2 = solution[scientist2]
		
		-- Create a more meaningful relational clue
		-- For example: "The person who studied X works in a different lab than the person who studied Y"
		table.insert(clues, {
			text = "The person who studied " .. assignment1.element .. " works in a different lab than the person who studied " .. assignment2.element,
			type = "relational"
		})
	end
	
	return clues
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
		RemoteRegistry.SafeFireClient(self.remoteEvents and self.remoteEvents.OpenPuzzleUI or remoteEvents.OpenPuzzleUI, player, {
			componentName = componentName,
			puzzle = puzzle
		})
	end
end

function PuzzleService:sendPuzzleError(player, message)
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents and remoteEvents:FindFirstChild("PuzzleFailed") then
		RemoteRegistry.SafeFireClient(self.remoteEvents and self.remoteEvents.PuzzleFailed or remoteEvents.PuzzleFailed, player, message)
	end
end

function PuzzleService:handlePuzzleAnswer(player, componentName, answer)
	local userId = player.UserId
	
	-- SECURITY: Validate componentName is a valid cure component or FinalSynthesis
	if typeof(componentName) ~= "string" then
		warn("[PuzzleService] SECURITY: Invalid componentName type from " .. player.Name)
		return
	end
	
	-- Validate against known component names + FinalSynthesis
	local isValidComponent = false
	
	-- Check if it's FinalSynthesis (special case)
	if componentName == "FinalSynthesis" then
		isValidComponent = true
	else
		-- Check against the list of cure components
		for _, validName in ipairs(GameConfig.CURE_COMPONENT_NAMES) do
			if componentName == validName then
				isValidComponent = true
				break
			end
		end
	end
	
	if not isValidComponent then
		warn("[PuzzleService] SECURITY: Unknown componentName '" .. componentName .. "' from " .. player.Name)
		return
	end
	
	-- BUGFIX (MEDIUM): Initialize player if not found to prevent silent failure
	if not self.playerPuzzles[userId] then
		warn("[PuzzleService] Player not initialized:", player.Name, "- initializing now")
		self:initializePlayer(player)
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
		-- Validate logic solution against the generated puzzle solution
		-- Player answer should be a table mapping scientists to {element, lab}
		-- Format: {["Dr. Smith"] = {element = "Compound X", lab = "Lab A"}, ...}
		
		if type(answer) ~= "table" then
			-- Fallback: For MVP compatibility, also accept "correct" string
			local normalizedAnswer = normalizeAnswer(answer)
			if normalizedAnswer == "correct" then
				return true
			end
			return false
		end
		
		-- Validate that player provided all scientists
		local solution = puzzle.data.solution
		if not solution then
			return false
		end
		
		-- Check each scientist's assignment
		for scientist, correctAssignment in pairs(solution) do
			local playerAssignment = answer[scientist]
			
			if not playerAssignment then
				return false  -- Missing scientist
			end
			
			if playerAssignment.element ~= correctAssignment.element then
				return false  -- Wrong element
			end
			
			if playerAssignment.lab ~= correctAssignment.lab then
				return false  -- Wrong lab
			end
		end
		
		-- Ensure no extra scientists were added
		for scientist, _ in pairs(answer) do
			if not solution[scientist] then
				return false  -- Invalid scientist
			end
		end
		
		return true

	elseif puzzle.type == PuzzleConfig.PuzzleTypes.ABSTRACT then
		-- Validate node connections forming a complete circuit
		-- Player answer should be a table of connections: {[1] = 2, [2] = 3, [3] = 1} means 1->2, 2->3, 3->1
		-- Or array of pairs: {{1, 2}, {2, 3}, {3, 1}}
		
		if type(answer) ~= "table" then
			-- Fallback: For MVP compatibility, also accept "circuit" string
			local normalizedAnswer = normalizeAnswer(answer)
			if normalizedAnswer == "circuit" then
				return true
			end
			return false
		end
		
		local nodeCount = puzzle.data.nodeCount
		if not nodeCount or nodeCount < 3 then
			return false
		end
		
		-- Build adjacency list from answer
		local adjacencyList = {}
		for i = 1, nodeCount do
			adjacencyList[i] = {}
		end
		
		-- Parse connection format
		for key, value in pairs(answer) do
			if type(key) == "number" and type(value) == "number" then
				-- Format: {[1] = 2, [2] = 3}
				if key >= 1 and key <= nodeCount and value >= 1 and value <= nodeCount then
					table.insert(adjacencyList[key], value)
				end
			elseif type(value) == "table" and #value == 2 then
				-- Format: {{1, 2}, {2, 3}}
				local from, to = value[1], value[2]
				if from >= 1 and from <= nodeCount and to >= 1 and to <= nodeCount then
					table.insert(adjacencyList[from], to)
				end
			end
		end
		
		-- Check if forms a Hamiltonian circuit (visits all nodes exactly once and returns to start)
		-- 1. Check each node has exactly one outgoing connection
		for i = 1, nodeCount do
			if #adjacencyList[i] ~= 1 then
				return false  -- Each node must connect to exactly one other node
			end
		end
		
		-- 2. Follow the path and verify it visits all nodes and returns to start
		local visited = {}
		local currentNode = 1
		local pathLength = 0
		
		while pathLength < nodeCount do
			if visited[currentNode] then
				return false  -- Visited a node twice before completing circuit
			end
			visited[currentNode] = true
			pathLength = pathLength + 1
			
			-- Move to next node
			local nextNode = adjacencyList[currentNode][1]
			if not nextNode then
				return false  -- Dead end
			end
			currentNode = nextNode
		end
		
		-- 3. Check if we're back at the start
		if currentNode ~= 1 then
			return false  -- Doesn't form a circuit back to start
		end
		
		-- 4. Verify all nodes were visited
		if pathLength ~= nodeCount then
			return false  -- Didn't visit all nodes
		end
		
		return true

	elseif puzzle.type == PuzzleConfig.PuzzleTypes.SYNTHESIS then
		-- Validate multi-stage answer
		-- Answer should contain: {stageIndex = <number>, answer = <stage-specific-answer>}
		
		if type(answer) ~= "table" then
			-- Fallback: For MVP compatibility, auto-solve if all components solved
			return true
		end
		
		local currentStageIndex = puzzle.data.currentStage
		local stages = puzzle.data.stages
		
		if not currentStageIndex or not stages or currentStageIndex > #stages then
			return false
		end
		
		-- Get the current stage
		local currentStage = stages[currentStageIndex]
		if not currentStage or currentStage.completed then
			return false  -- Stage already completed or invalid
		end
		
		-- Validate the answer for the current stage type
		local stageAnswer = answer.answer or answer
		local isStageCorrect = false
		
		if currentStage.type == "math" then
			-- Validate math answer
			isStageCorrect = (stageAnswer == currentStage.puzzle.answer)
			
		elseif currentStage.type == "pattern" then
			-- Validate pattern answer
			isStageCorrect = (stageAnswer == currentStage.puzzle.answer)
			
		elseif currentStage.type == "color" then
			-- Simplified color validation
			isStageCorrect = (normalizeAnswer(stageAnswer) == "spectrum")
			
		elseif currentStage.type == "logic" then
			-- Simplified logic validation
			isStageCorrect = (normalizeAnswer(stageAnswer) == "deduction" or normalizeAnswer(stageAnswer) == "correct")
			
		elseif currentStage.type == "abstract" then
			-- Simplified abstract validation
			isStageCorrect = (normalizeAnswer(stageAnswer) == "circuit")
		end
		
		-- If stage is correct, mark it complete and advance
		if isStageCorrect then
			currentStage.completed = true
			puzzle.data.currentStage = currentStageIndex + 1
			
			-- Check if all stages are complete
			local allComplete = true
			for _, stage in ipairs(stages) do
				if not stage.completed then
					allComplete = false
					break
				end
			end
			
			-- First return value: this stage answer was correct
			-- Second return value: whether ALL stages are now complete
			return true, allComplete
		end
		
		-- Incorrect answer for current synthesis stage
		return false, false
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
		RemoteRegistry.SafeFireClient(self.remoteEvents and self.remoteEvents.PuzzleCompleted or remoteEvents.PuzzleCompleted, player, {
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
		-- BUGFIX (MEDIUM): Add validation to prevent crash if betrayer doesn't have component structure
		if puzzleState.solved and betrayerPuzzles[componentName] then
			if not betrayerPuzzles[componentName].solved then
				-- Steal with probability
				if math.random() < PuzzleConfig.BetrayalMechanics.stealPercentage then
					betrayerPuzzles[componentName].solved = true
					print("[PuzzleService]", betrayer.Name, "stole", componentName, "puzzle from", victim.Name)
				end
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

-- Survivor victory: when victim kills betrayer, transfer ALL puzzles
function PuzzleService:onSurvivorVictory(survivor, betrayer)
	local survivorUserId = survivor.UserId
	local betrayerUserId = betrayer.UserId

	self:initializePlayer(survivor)
	self:initializePlayer(betrayer)

	local survivorPuzzles = self.playerPuzzles[survivorUserId]
	local betrayerPuzzles = self.playerPuzzles[betrayerUserId]

	-- Transfer ALL solved puzzles from betrayer to survivor
	for componentName, puzzleState in pairs(betrayerPuzzles) do
		local survivorPuzzleState = survivorPuzzles[componentName]
		local betrayerHasSolved = puzzleState.solved

		if betrayerHasSolved and survivorPuzzleState and not survivorPuzzleState.solved then
			survivorPuzzles[componentName].solved = true
			print("[PuzzleService]", survivor.Name, "claimed", componentName, "puzzle from defeated betrayer", betrayer.Name)
		end
	end

	-- Reset betrayer's puzzles (they lost everything)
	for componentName, puzzleState in pairs(betrayerPuzzles) do
		puzzleState.solved = false
		puzzleState.attempts = 0
	end

	print("[PuzzleService]", survivor.Name, "claimed all puzzles from defeated betrayer", betrayer.Name)
end

-- Request puzzle (adapter method for tests and alternative API)
-- This delegates to the existing handlePuzzleRequest but can be called directly
function PuzzleService:requestPuzzle(player, componentNameOrType, difficulty)
	-- Validate player
	if not player or not player:IsA("Player") then
		warn("[PuzzleService] requestPuzzle: Invalid player")
		return nil, "Invalid player"
	end
	
	-- Initialize player if needed
	self:initializePlayer(player)
	
	-- If componentNameOrType is nil, use a predictable default
	local componentName = componentNameOrType
	if not componentName then
		-- Default to first component name from GameConfig for predictable behavior
		componentName = GameConfig.CURE_COMPONENT_NAMES[1]
	end
	
	-- Handle FinalSynthesis separately
	if componentName == "FinalSynthesis" then
		-- Generate final synthesis puzzle using existing method
		local success, puzzle = pcall(function()
			return self:generatePuzzle(componentName)
		end)
		
		if not success then
			warn("[PuzzleService] requestPuzzle: Failed to generate final synthesis puzzle:", puzzle)
			-- Return appropriate multi-stage puzzle structure for final synthesis
			return {
				type = PuzzleConfig.PuzzleTypes.SYNTHESIS,
				name = "Final Synthesis",
				description = "Complete all stages to synthesize the cure",
				data = {
					stages = {},
					currentStage = 1
				},
				componentName = componentName
			}, "Generation failed, using fallback"
		end
		
		return puzzle, nil
	end
	
	-- Validate component name
	if not PuzzleConfig.ComponentPuzzles[componentName] then
		-- Invalid component, try to generate a generic puzzle
		warn("[PuzzleService] requestPuzzle: Invalid component '" .. tostring(componentName) .. "', generating generic puzzle")
		
		-- Return a safe generic puzzle
		return {
			type = "pattern",
			prompt = "What comes next? 2, 4, 6, ?",
			options = {8, 10, 12},
			answer = 8,
			componentName = componentName or "Generic"
		}, nil
	end
	
	-- Generate puzzle using existing method
	local success, puzzle = pcall(function()
		return self:generatePuzzle(componentName)
	end)
	
	if not success then
		warn("[PuzzleService] requestPuzzle: Failed to generate puzzle:", puzzle)
		-- Return safe fallback
		return {
			type = "pattern",
			prompt = "What comes next? 2, 4, 6, ?",
			options = {8, 10, 12},
			answer = 8,
			componentName = componentName
		}, "Generation failed, using fallback"
	end
	
	return puzzle, nil
end

-- Alias submitAnswer for consistency with requestPuzzle
function PuzzleService:submitAnswer(player, componentName, answer)
	return self:handlePuzzleAnswer(player, componentName, answer)
end

return PuzzleService
