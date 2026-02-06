-- @ScriptType: ModuleScript
-- LoadingManager.lua
-- Manages loading progress tracking during client boot
-- Reports progress to TitleScreenUI for visual feedback

local LoadingManager = {}
LoadingManager.__index = LoadingManager

-- Singleton instance
local instance = nil

-- Loading phases and their weights (total should be 100)
local LOADING_PHASES = {
	{name = "RemoteRegistry", weight = 10},
	{name = "Configuration", weight = 10},
	{name = "CoreSystems", weight = 30},
	{name = "UISystems", weight = 30},
	{name = "StateRouter", weight = 10},
	{name = "CharacterHandlers", weight = 5},
	{name = "Diagnostics", weight = 5},
}

function LoadingManager.new()
	if instance then
		return instance
	end
	
	local self = setmetatable({}, LoadingManager)
	
	self.currentProgress = 0
	self.totalWeight = 0
	self.completedWeight = 0
	self.isComplete = false
	self.callbacks = {}
	
	-- Calculate total weight
	for _, phase in ipairs(LOADING_PHASES) do
		self.totalWeight = self.totalWeight + phase.weight
	end
	
	instance = self
	print("[LoadingManager] Initialized with", #LOADING_PHASES, "phases")
	
	return self
end

-- Register a callback to be called when progress updates
function LoadingManager:onProgressChanged(callback)
	if typeof(callback) == "function" then
		table.insert(self.callbacks, callback)
	end
end

-- Register a callback to be called when loading completes
function LoadingManager:onLoadingComplete(callback)
	if typeof(callback) == "function" then
		if self.isComplete then
			-- Already complete, call immediately
			task.spawn(callback)
		else
			-- Store for later
			if not self.completeCallbacks then
				self.completeCallbacks = {}
			end
			table.insert(self.completeCallbacks, callback)
		end
	end
end

-- Update progress for a specific phase
function LoadingManager:updatePhase(phaseName, percentComplete)
	-- Find the phase
	local phase = nil
	for _, p in ipairs(LOADING_PHASES) do
		if p.name == phaseName then
			phase = p
			break
		end
	end
	
	if not phase then
		warn("[LoadingManager] Unknown phase:", phaseName)
		return
	end
	
	-- Calculate progress contribution
	local phaseContribution = phase.weight * (percentComplete / 100)
	
	-- Track phase progress
	if not self.phaseProgress then
		self.phaseProgress = {}
	end
	
	local oldContribution = self.phaseProgress[phaseName] or 0
	self.phaseProgress[phaseName] = phaseContribution
	
	-- Update total progress
	self.completedWeight = self.completedWeight - oldContribution + phaseContribution
	self.currentProgress = math.floor((self.completedWeight / self.totalWeight) * 100)
	
	-- Clamp to 0-100
	self.currentProgress = math.clamp(self.currentProgress, 0, 100)
	
	print(string.format("[LoadingManager] %s: %d%% (Total: %d%%)", phaseName, percentComplete, self.currentProgress))
	
	-- Notify callbacks
	for _, callback in ipairs(self.callbacks) do
		task.spawn(callback, self.currentProgress, phaseName)
	end
	
	-- Check if complete
	if self.currentProgress >= 100 and not self.isComplete then
		self:markComplete()
	end
end

-- Mark loading as complete
function LoadingManager:markComplete()
	if self.isComplete then
		return
	end
	
	self.isComplete = true
	self.currentProgress = 100
	
	print("[LoadingManager] Loading complete!")
	
	-- Notify complete callbacks
	if self.completeCallbacks then
		for _, callback in ipairs(self.completeCallbacks) do
			task.spawn(callback)
		end
	end
end

-- Get current progress (0-100)
function LoadingManager:getProgress()
	return self.currentProgress
end

-- Check if loading is complete
function LoadingManager:isLoadingComplete()
	return self.isComplete
end

-- Get singleton instance
function LoadingManager.getInstance()
	if not instance then
		return LoadingManager.new()
	end
	return instance
end

return LoadingManager
