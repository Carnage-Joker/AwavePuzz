-- ModalManager.lua
-- Manages UI modal priority and ensures only one modal is active at a time
-- Provides global ESC/Backspace handling for closing topmost modal

local UserInputService = game:GetService("UserInputService")

local ModalManager = {}
ModalManager._stack = {}
ModalManager._initialized = false
ModalManager._connection = nil

-- Modal priority levels (higher = more important, blocks lower priority)
ModalManager.Priority = {
	FULLSCREEN = 100,  -- TitleScreen, Epilogue, Lobby (blocks everything)
	MODAL = 50,        -- Shop, PuzzleUI, AllianceUI (blocks gameplay)
	PANEL = 25,        -- Scoreboard, MapVoting (overlay, doesn't block)
	NOTIFICATION = 10  -- Achievements, Fun Facts (passive)
}

--------------------------------------------------------------------------------
-- MODAL MANAGEMENT
--------------------------------------------------------------------------------

-- Push a modal onto the stack
function ModalManager.push(modalName, closeCallback, priority)
	assert(type(modalName) == "string", "modalName must be a string")
	assert(type(closeCallback) == "function", "closeCallback must be a function")
	priority = priority or ModalManager.Priority.MODAL
	
	-- Check if modal already on stack
	for _, entry in ipairs(ModalManager._stack) do
		if entry.name == modalName then
			warn(string.format("[ModalManager] Modal '%s' is already on the stack", modalName))
			return false
		end
	end
	
	-- Add to stack
	table.insert(ModalManager._stack, {
		name = modalName,
		close = closeCallback,
		priority = priority,
		timestamp = tick()
	})
	
	-- Sort by priority (highest first)
	table.sort(ModalManager._stack, function(a, b)
		return a.priority > b.priority
	end)
	
	print(string.format("[ModalManager] Pushed modal: %s (priority %d), stack size: %d", 
		modalName, priority, #ModalManager._stack))
	
	return true
end

-- Remove a specific modal from the stack
function ModalManager.remove(modalName)
	for i, entry in ipairs(ModalManager._stack) do
		if entry.name == modalName then
			table.remove(ModalManager._stack, i)
			print(string.format("[ModalManager] Removed modal: %s, stack size: %d", 
				modalName, #ModalManager._stack))
			return true
		end
	end
	
	warn(string.format("[ModalManager] Modal '%s' not found in stack", modalName))
	return false
end

-- Close the topmost modal (highest priority)
function ModalManager.closeTop()
	if #ModalManager._stack == 0 then
		return false
	end
	
	local topModal = ModalManager._stack[1]  -- Sorted by priority, so [1] is highest
	print(string.format("[ModalManager] Closing top modal: %s", topModal.name))
	
	-- Call the close callback
	local success, err = pcall(topModal.close)
	if not success then
		warn(string.format("[ModalManager] Error closing modal '%s': %s", topModal.name, tostring(err)))
	end
	
	-- Remove from stack
	ModalManager.remove(topModal.name)
	
	return true
end

-- Close all modals
function ModalManager.closeAll()
	local count = #ModalManager._stack
	
	while #ModalManager._stack > 0 do
		ModalManager.closeTop()
	end
	
	print(string.format("[ModalManager] Closed all modals (%d)", count))
end

-- Check if any modals are open
function ModalManager.hasActiveModal()
	return #ModalManager._stack > 0
end

-- Get the topmost modal name (nil if none)
function ModalManager.getTopModal()
	if #ModalManager._stack > 0 then
		return ModalManager._stack[1].name
	end
	return nil
end

-- Get all modal names in the stack (sorted by priority)
function ModalManager.getAllModals()
	local names = {}
	for _, entry in ipairs(ModalManager._stack) do
		table.insert(names, entry.name)
	end
	return names
end

-- Check if a specific modal is open
function ModalManager.isModalOpen(modalName)
	for _, entry in ipairs(ModalManager._stack) do
		if entry.name == modalName then
			return true
		end
	end
	return false
end

-- Check if gameplay should be blocked (modal priority >= MODAL)
function ModalManager.shouldBlockGameplay()
	for _, entry in ipairs(ModalManager._stack) do
		if entry.priority >= ModalManager.Priority.MODAL then
			return true
		end
	end
	return false
end

-- Check if a modal is the topmost one (useful for input handling)
function ModalManager.isTopModal(modalName)
	return ModalManager.getTopModal() == modalName
end

--------------------------------------------------------------------------------
-- GLOBAL INPUT HANDLING
--------------------------------------------------------------------------------

local function handleGlobalInput(input, gameProcessedEvent)
	-- Don't process if Roblox UI already consumed it
	if gameProcessedEvent then return end
	
	-- ESC or Backspace closes the topmost modal
	if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
		if ModalManager.closeTop() then
			-- Mark input as processed (prevent other systems from handling)
			-- Note: We can't actually mark it as processed in Lua, but the modal
			-- should have already closed, preventing double-handling
		end
	end
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function ModalManager.initialize()
	if ModalManager._initialized then
		warn("[ModalManager] Already initialized")
		return
	end
	
	-- Set up global ESC/Backspace handler
	ModalManager._connection = UserInputService.InputBegan:Connect(handleGlobalInput)
	
	ModalManager._initialized = true
	print("[ModalManager] Initialized - Global ESC/Backspace handler active")
end

function ModalManager.cleanup()
	if ModalManager._connection then
		ModalManager._connection:Disconnect()
		ModalManager._connection = nil
	end
	
	ModalManager.closeAll()
	ModalManager._initialized = false
	print("[ModalManager] Cleaned up")
end

--------------------------------------------------------------------------------
-- DEBUG UTILITIES
--------------------------------------------------------------------------------

function ModalManager.debugPrintStack()
	print("=== ModalManager Stack ===")
	if #ModalManager._stack == 0 then
		print("  (empty)")
	else
		for i, entry in ipairs(ModalManager._stack) do
			print(string.format("  [%d] %s (priority %d)", i, entry.name, entry.priority))
		end
	end
	print("==========================")
end

return ModalManager
