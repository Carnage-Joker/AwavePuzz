--!strict
-- @ScriptType: ModuleScript
-- ClientMainModule.lua
-- Main client boot logic extracted from ClientMain.client.lua
-- Converted to ModuleScript pattern to eliminate RunContext warnings

local ClientMainModule = {}

-- BUG-007 FIX: Connection tracking for cleanup
local _connections = {}

local function checkInitialized(script)
	if script:GetAttribute("Initialized") then
		warn("[ClientMain] Already initialized, skipping duplicate execution")
		return true
	end
	script:SetAttribute("Initialized", true)
	return false
end

local function bootClient()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	
	local player = Players.LocalPlayer
	
	print("=== [BOOT][CLIENT] Aether Wave: Convergence Client Starting ===")
	print(string.format("[BOOT][CLIENT] Player: %s", player.Name))
	
	-- Get LoadingManager instance from shared (initialized in BootModule)
	local loadingManager = shared.__AwavePuzzLoadingManager
	if not loadingManager then
		warn("[BOOT][CLIENT] LoadingManager not found in shared - progress tracking disabled")
	end
	
	----------------------------------------------------------------
	-- PHASE 1: Wait for Remote Registry
	----------------------------------------------------------------
	
	print("[BOOT][CLIENT] Phase 1: Waiting for remote registry...")
	if loadingManager then loadingManager:updatePhase("RemoteRegistry", 0) end
	
	local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
	if not SharedFolder then
		error("[ClientMain] CRITICAL: Failed to load Shared folder after 10 seconds")
	end
	
	if loadingManager then loadingManager:updatePhase("RemoteRegistry", 30) end
	
	local RemotesFolder = SharedFolder:WaitForChild("Remotes", 5)
	if not RemotesFolder then
		error("[ClientMain] CRITICAL: Failed to load Remotes folder after 5 seconds")
	end
	
	if loadingManager then loadingManager:updatePhase("RemoteRegistry", 60) end
	
	local RemoteRegistry = require(RemotesFolder:WaitForChild("RemoteRegistry", 5))
	local remotes = RemoteRegistry.initializeClient(10)
	if not remotes then
		error("[ClientMain] CRITICAL: Failed to initialize remote registry")
	end
	
	if loadingManager then loadingManager:updatePhase("RemoteRegistry", 100) end
	print("[BOOT][CLIENT] Phase 1 complete: Remote registry ready")
	
	----------------------------------------------------------------
	-- PHASE 2: Load Configuration
	----------------------------------------------------------------
	
	print("[BOOT][CLIENT] Phase 2: Loading configuration...")
	if loadingManager then loadingManager:updatePhase("Configuration", 0) end
	
	local FPSConfig = require(SharedFolder:WaitForChild("FPSConfig", 5))
	if loadingManager then loadingManager:updatePhase("Configuration", 25) end
	
	local GameConfig = require(SharedFolder:WaitForChild("GameConfig", 5))
	if loadingManager then loadingManager:updatePhase("Configuration", 50) end
	
	local ModalManager = require(SharedFolder:WaitForChild("ModalManager", 5))
	if loadingManager then loadingManager:updatePhase("Configuration", 75) end
	
	local InputActionRegistry = require(SharedFolder:WaitForChild("InputActionRegistry", 5))
	if loadingManager then loadingManager:updatePhase("Configuration", 100) end
	
	print("[BOOT][CLIENT] Phase 2 complete: Configuration loaded")
	
	----------------------------------------------------------------
	-- PHASE 3: Load Client Modules
	----------------------------------------------------------------
	
	print("[BOOT][CLIENT] Phase 3: Loading client modules...")
	
	local clientModules = script.Parent:WaitForChild("Modules", 10)
	if not clientModules then
		error("[ClientMain] CRITICAL: Modules folder not found in " .. script.Parent:GetFullName())
	end
	
	-- Core system modules
	local Camera = nil
	local Movement = nil
	local WeaponController = nil
	local AnimationController = nil
	local AudioController = nil
	local MenuController = nil
	local MusicController = nil
	local StaminaClient = nil
	local VoiceoverController = nil
	local CureStationInteraction = nil
	
	-- UI systems
	local UI = {}
	
	print("[BOOT][CLIENT] Phase 3 complete: Module references ready")
	
	----------------------------------------------------------------
	-- PHASE 4: Initialize Input Management
	----------------------------------------------------------------
	
	print("[BOOT][CLIENT] Phase 4: Initializing input management...")
	
	ModalManager.initialize()
	InputActionRegistry.initialize()
	
	print("[BOOT][CLIENT] Phase 4 complete: Input management initialized")
	
	----------------------------------------------------------------
	-- PHASE 5: Initialize Core Systems
	----------------------------------------------------------------
	
	print("[BOOT][CLIENT] Phase 5: Initializing core systems...")
	
	-- Camera System
	local function initializeCamera()
		print("[BOOT][CLIENT] Initializing Camera...")
		local cameraModule = clientModules:FindFirstChild("FirstPersonCamera")
		if cameraModule then
			local success, result = pcall(function()
				return require(cameraModule)
			end)
			
			if success then
				Camera = result
				if Camera.initialize then
					Camera.initialize()
				end
				print("[BOOT][CLIENT] ✓ Camera initialized")
			else
				warn("[BOOT][CLIENT] ✗ Camera failed to load:", result)
			end
		else
			warn("[BOOT][CLIENT] ✗ Camera module not found")
		end
	end
	
	-- Movement System
	local function initializeMovement()
		print("[BOOT][CLIENT] Initializing Movement...")
		local movementModule = clientModules:FindFirstChild("FPSMovement")
		if movementModule then
			local success, result = pcall(function()
				return require(movementModule)
			end)
			
			if success then
				Movement = result
				if Movement.initialize then
					Movement.initialize()
				end
				print("[BOOT][CLIENT] ✓ Movement initialized")
			else
				warn("[BOOT][CLIENT] ✗ Movement failed to load:", result)
			end
		else
			warn("[BOOT][CLIENT] ✗ Movement module not found")
		end
	end
	
	-- Weapon System
	local function initializeWeapon()
		print("[BOOT][CLIENT] Initializing Weapon System...")
		local weaponModule = clientModules:FindFirstChild("FPSWeaponController")
		if weaponModule then
			local success, result = pcall(function()
				return require(weaponModule)
			end)
			
			if success then
				WeaponController = result
				if WeaponController.initialize then
					WeaponController.initialize()
				end
				print("[BOOT][CLIENT] ✓ Weapon system initialized")
			else
				warn("[BOOT][CLIENT] ✗ Weapon system failed to load:", result)
			end
		else
			warn("[BOOT][CLIENT] ✗ Weapon module not found")
		end
	end
	
	-- Animation System
	local function initializeAnimation()
		print("[BOOT][CLIENT] Initializing Animations...")
		local animModule = clientModules:FindFirstChild("FPSAnimationController")
		if animModule then
			local success, result = pcall(function()
				return require(animModule)
			end)
			
			if success then
				AnimationController = result
				if AnimationController.initialize then
					AnimationController.initialize()
				end
				print("[BOOT][CLIENT] ✓ Animations initialized")
			else
				warn("[BOOT][CLIENT] ✗ Animations failed to load:", result)
			end
		else
			warn("[BOOT][CLIENT] ✗ Animation module not found")
		end
	end
	
	-- Audio System
	local function initializeAudio()
		print("[BOOT][CLIENT] Initializing Audio...")
		local audioModule = clientModules:FindFirstChild("FPSAudioController")
		if audioModule then
			local success, result = pcall(function()
				return require(audioModule)
			end)
			
			if success then
				AudioController = result
				if AudioController.initialize then
					AudioController.initialize()
				end
				print("[BOOT][CLIENT] ✓ Audio initialized")
			else
				warn("[BOOT][CLIENT] ✗ Audio failed to load:", result)
			end
		else
			warn("[BOOT][CLIENT] ✗ Audio module not found")
		end
	end
	
	-- Music System
	local function initializeMusic()
		print("[BOOT][CLIENT] Initializing Music...")
		local musicModule = clientModules:FindFirstChild("MusicController")
		if musicModule then
			local success, result = pcall(function()
				return require(musicModule)
			end)
			
			if success then
				MusicController = result
				if MusicController.initialize then
					MusicController.initialize()
				end
				print("[BOOT][CLIENT] ✓ Music initialized")
			else
				warn("[BOOT][CLIENT] ✗ Music failed to load:", result)
			end
		else
			warn("[BOOT][CLIENT] ✗ Music module not found")
		end
	end
	
	-- Menu System
	local function initializeMenu()
		print("[BOOT][CLIENT] Initializing Menu...")
		local menuModule = clientModules:FindFirstChild("FPSMenuController")
		if menuModule then
			local success, result = pcall(function()
				return require(menuModule)
			end)
			
			if success then
				MenuController = result
				if MenuController.initialize then
					MenuController.initialize()
				end
				print("[BOOT][CLIENT] ✓ Menu initialized")
			else
				warn("[BOOT][CLIENT] ✗ Menu failed to load:", result)
			end
		else
			warn("[BOOT][CLIENT] ✗ Menu module not found")
		end
	end
	
	-- Stamina System
	local function initializeStamina()
		print("[BOOT][CLIENT] Initializing Stamina...")
		local staminaModule = clientModules:FindFirstChild("StaminaClient")
		if staminaModule then
			local success, result = pcall(function()
				return require(staminaModule)
			end)
			
			if success then
				StaminaClient = result
				if StaminaClient.initialize then
					StaminaClient.initialize()
				end
				print("[BOOT][CLIENT] ✓ Stamina initialized")
			else
				warn("[BOOT][CLIENT] ✗ Stamina failed to load:", result)
			end
		else
			warn("[BOOT][CLIENT] ✗ Stamina module not found")
		end
	end
	
	-- Voiceover System
	local function initializeVoiceover()
		print("[BOOT][CLIENT] Initializing Voiceover...")
		local voiceoverModule = clientModules:FindFirstChild("VoiceoverController")
		if voiceoverModule then
			local success, result = pcall(function()
				return require(voiceoverModule)
			end)
			
			if success then
				VoiceoverController = result.new()
				print("[BOOT][CLIENT] ✓ Voiceover initialized")
			else
				warn("[BOOT][CLIENT] ✗ Voiceover failed to load:", result)
			end
		else
			warn("[BOOT][CLIENT] ✗ Voiceover module not found")
		end
	end
	
	-- Initialize all core systems in order
	if loadingManager then loadingManager:updatePhase("CoreSystems", 0) end
	
	initializeCamera()
	if loadingManager then loadingManager:updatePhase("CoreSystems", 11) end
	
	initializeMovement()
	if loadingManager then loadingManager:updatePhase("CoreSystems", 22) end
	
	initializeWeapon()
	if loadingManager then loadingManager:updatePhase("CoreSystems", 33) end
	
	initializeAnimation()
	if loadingManager then loadingManager:updatePhase("CoreSystems", 44) end
	
	initializeAudio()
	if loadingManager then loadingManager:updatePhase("CoreSystems", 55) end
	
	initializeMusic()
	if loadingManager then loadingManager:updatePhase("CoreSystems", 66) end
	
	initializeMenu()
	if loadingManager then loadingManager:updatePhase("CoreSystems", 77) end
	
	initializeStamina()
	if loadingManager then loadingManager:updatePhase("CoreSystems", 88) end
	
	initializeVoiceover()
	if loadingManager then loadingManager:updatePhase("CoreSystems", 94) end
	
	-- Cure Station Interaction (with E key support)
	local function initializeCureStationInteraction()
		print("[BOOT][CLIENT] Initializing Cure Station Interaction...")
		local interactionModule = clientModules:FindFirstChild("CureStationInteraction")
		if interactionModule then
			local success, result = pcall(function()
				return require(interactionModule)
			end)
			
			if success then
				CureStationInteraction = result.new()
				if CureStationInteraction.initialize then
					CureStationInteraction:initialize()
				end
				print("[BOOT][CLIENT] ✓ Cure Station Interaction initialized")
			else
				warn("[BOOT][CLIENT] ✗ Cure Station Interaction failed to load:", result)
			end
		else
			warn("[BOOT][CLIENT] ✗ Cure Station Interaction module not found")
		end
	end
	
	initializeCureStationInteraction()
	if loadingManager then loadingManager:updatePhase("CoreSystems", 100) end
	
	print("[BOOT][CLIENT] Phase 5 complete: Core systems initialized")
	
	----------------------------------------------------------------
	-- PHASE 6: Initialize UI Systems
	----------------------------------------------------------------
	
	print("[BOOT][CLIENT] Phase 6: Initializing UI systems...")
	if loadingManager then loadingManager:updatePhase("UISystems", 0) end
	
	local uiFolder = clientModules:FindFirstChild("UI")
	if not uiFolder then
		warn("[BOOT][CLIENT] ✗ UI folder not found")
	else
		-- UI modules that follow standard initialization pattern
		local uiModules = {
			"FPSHUD",
			"PlayerHUD",
			"WaveUI",
			"CureUI",
			"BaseHealthUI",
			"InventoryUI",
			"MapUI",
			"ShopUI",
			"AllianceUI",
			"PuzzleUI",
			"PuzzleMenuUI",
			"ScoreboardUI",
			"MapVotingUI",
			"LobbyUI",
			"SpectatorUI",
			-- NOTE: TitleScreenUI and EpilogueUI excluded - they use special bindRemotes pattern
			"AchievementUI",
			"CreditsUI",
			"FunFactUI",
			"SynthesisUI",
			"ControlsTutorialUI",
			"TouchControlsUI"
		}
		
		-- Only load PortalQueueUI if portal matchmaking is enabled
		if GameConfig and GameConfig.USE_PORTAL_MATCHMAKING then
			table.insert(uiModules, "PortalQueueUI")
		end
		
		local uiCount = 0
		local totalUiModules = #uiModules + 2 -- +2 for TitleScreenUI and EpilogueUI
		
		for i, moduleName in ipairs(uiModules) do
			local uiModule = uiFolder:FindFirstChild(moduleName)
			if uiModule then
				local success, result = pcall(function()
					return require(uiModule)
				end)
				
				if success and result ~= nil then
					UI[moduleName] = result
					-- Call initialize if it exists
					if typeof(result) == "table" and result.initialize then
						local initSuccess, initErr = pcall(result.initialize)
						if initSuccess then
							uiCount = uiCount + 1
						else
							warn(string.format("[BOOT][CLIENT] ✗ UI module %s initialize failed: %s", moduleName, tostring(initErr)))
						end
					else
						uiCount = uiCount + 1
					end
					
					-- Bind remotes if the module has bindRemotes method
					if typeof(result) == "table" and result.bindRemotes then
						local bindSuccess, bindErr = pcall(result.bindRemotes, result, remotes)
						if bindSuccess then
							print(string.format("[BOOT][CLIENT] ✓ %s remotes bound", moduleName))
						else
							warn(string.format("[BOOT][CLIENT] ✗ %s bindRemotes failed: %s", moduleName, tostring(bindErr)))
						end
					end
				elseif not success then
					warn(string.format("[BOOT][CLIENT] ✗ UI module %s failed to load: %s", moduleName, tostring(result)))
				end
			end
			
			-- Update progress after each UI module
			local progress = math.floor((i / totalUiModules) * 80) -- Reserve 20% for special handling
			if loadingManager then loadingManager:updatePhase("UISystems", progress) end
		end
		
		-- Special handling for TitleScreenUI - use pre-created instance from BootClient.lua
		-- BootClient.lua creates TitleScreenUI in Phase 0.5 (before other UI) for immediate display
		local titleScreenInstance = shared.__AwavePuzzTitleScreenInstance
		if titleScreenInstance then
			-- Bind remotes to the existing instance
			print("[BOOT][CLIENT] ✓ TitleScreenUI pre-created instance found, binding remotes...")
			titleScreenInstance:bindRemotes(remotes)
			UI.TitleScreenUI = titleScreenInstance
			uiCount = uiCount + 1
			print("[BOOT][CLIENT] ✓ TitleScreenUI remotes bound (instance created in Boot Phase 0.5, now fully interactive)")
		else
			-- Fallback: create instance if Boot didn't (shouldn't happen in normal flow)
			warn("[BOOT][CLIENT] ⚠ TitleScreenUI not found in shared, creating fallback instance")
			local titleScreenModule = uiFolder:FindFirstChild("TitleScreenUI")
			if titleScreenModule then
				local success, TitleScreenClass = pcall(function()
					return require(titleScreenModule)
				end)
				if success and TitleScreenClass then
					titleScreenInstance = TitleScreenClass.new()
					titleScreenInstance:bindRemotes(remotes)
					UI.TitleScreenUI = titleScreenInstance
					uiCount = uiCount + 1
					print("[BOOT][CLIENT] ✓ TitleScreenUI instance created (fallback) and remotes bound")
				else
					warn("[BOOT][CLIENT] ✗ TitleScreenUI failed to load")
				end
			end
		end
		
		if loadingManager then loadingManager:updatePhase("UISystems", 90) end
		
		-- Special handling for EpilogueUI - load module, create instance, bind remotes
		local epilogueModule = uiFolder:FindFirstChild("EpilogueUI")
		if epilogueModule then
			local success, EpilogueClass = pcall(function()
				return require(epilogueModule)
			end)
			if success and EpilogueClass then
				local epilogueInstance = EpilogueClass.new()
				epilogueInstance:bindRemotes(remotes)
				UI.EpilogueUI = epilogueInstance
				uiCount = uiCount + 1
				print("[BOOT][CLIENT] ✓ EpilogueUI instance created and remotes bound")
			else
				warn("[BOOT][CLIENT] ✗ EpilogueUI failed to load")
			end
		end
		
		print(string.format("[BOOT][CLIENT] ✓ %d UI systems initialized", uiCount))
	end
	
	if loadingManager then loadingManager:updatePhase("UISystems", 100) end
	print("[BOOT][CLIENT] Phase 6 complete: UI systems ready")
	
	----------------------------------------------------------------
	-- PHASE 6.5: Client State Router
	----------------------------------------------------------------
	
	print("[BOOT][CLIENT] Phase 6.5: Setting up client state router...")
	if loadingManager then loadingManager:updatePhase("StateRouter", 0) end
	
	-- State-based control for movement and weapons
	local function applyState(stateName)
		print(string.format("[ClientState] Applying state: %s", stateName))
		
		local enableMovement = false
		local enableWeapons = false
		local enableCamera = true  -- Default: camera is enabled
		
		-- Treat any epilogue-like state (e.g. "EpilogueActive", "ShowingEpilogue") as epilogue
		local isEpilogueState = typeof(stateName) == "string" and string.find(stateName, "Epilogue", 1, true) ~= nil
		
		-- Map states to movement/weapon enable flags
		if stateName == "TitleScreen" or isEpilogueState then
			-- Title and epilogue: no movement, no weapons, no camera control
			enableMovement = false
			enableWeapons = false
			enableCamera = false
		elseif stateName == "Lobby" or stateName == "Waiting" then
			-- Lobby/Waiting: can move, no weapons, camera enabled
			enableMovement = true
			enableWeapons = false
			enableCamera = true
		elseif stateName == "Countdown" or stateName == "WaveActive" or stateName == "Intermission" then
			-- Active gameplay: can move and use weapons, camera enabled
			enableMovement = true
			enableWeapons = true
			enableCamera = true
		elseif stateName == "Victory" or stateName == "Defeat" or stateName == "Scoreboard" then
			-- End states: can move, no weapons, camera enabled
			enableMovement = true
			enableWeapons = false
			enableCamera = true
		else
			-- Unknown state: safe defaults (allow movement, disable weapons)
			warn(string.format("[ClientState] Unknown state '%s', using safe defaults", tostring(stateName)))
			enableMovement = true
			enableWeapons = false
			enableCamera = true
		end
		
		-- Apply movement state
		if Movement and Movement.setEnabled then
			Movement.setEnabled(enableMovement)
		end
		
		-- Apply weapon state
		if WeaponController and WeaponController.setEnabled then
			WeaponController.setEnabled(enableWeapons)
		end
		
		-- Apply camera state
		-- During TitleScreen, keep camera scriptable
		-- After TitleScreen, restore normal camera control
		if Camera then
			local currentCamera = workspace.CurrentCamera
			if currentCamera then
				if not enableCamera then
					-- Keep camera scriptable during title/epilogue
					-- (BootClient.lua already set it, just maintain it)
					currentCamera.CameraType = Enum.CameraType.Scriptable
				else
					-- Re-enable camera control by restoring default camera type
					currentCamera.CameraType = Enum.CameraType.Custom
				end
			end
		end
	end
	
	if loadingManager then loadingManager:updatePhase("StateRouter", 50) end
	
	-- Connect to server GameStateUpdate
	if remotes.GameStateUpdate then
		_connections.gameStateUpdate = remotes.GameStateUpdate.OnClientEvent:Connect(function(data)
			if data and data.state then
				applyState(data.state)
			end
		end)
		print("[BOOT][CLIENT] ✓ Client state router connected to GameStateUpdate")
	else
		warn("[BOOT][CLIENT] ✗ GameStateUpdate remote not found")
	end
	
	-- Apply safe initial state (TitleScreen to disable movement/weapons/camera)
	applyState("TitleScreen")
	
	if loadingManager then loadingManager:updatePhase("StateRouter", 100) end
	print("[BOOT][CLIENT] Phase 6.5 complete: Client state router active")
	
	----------------------------------------------------------------
	-- PHASE 7: Character Lifecycle Handlers
	----------------------------------------------------------------
	
	print("[BOOT][CLIENT] Phase 7: Setting up character lifecycle...")
	if loadingManager then loadingManager:updatePhase("CharacterHandlers", 0) end
	
	local function onCharacterAdded(character)
		print(string.format("[STATE] Character added: %s", character.Name))
		
		-- Clear any stale GUI selections on respawn
		local GuiService = game:GetService("GuiService")
		pcall(function()
			GuiService.SelectedObject = nil
		end)
		
		-- Notify all systems of character spawn
		if Camera and Camera.onCharacterAdded then
			Camera.onCharacterAdded(character)
		end
		
		if Movement and Movement.onCharacterAdded then
			Movement.onCharacterAdded(character)
		end
		
		if WeaponController and WeaponController.onCharacterAdded then
			WeaponController.onCharacterAdded(character)
		end
		
		if AnimationController and AnimationController.onCharacterAdded then
			AnimationController.onCharacterAdded(character)
		end
		
		if StaminaClient and StaminaClient.onCharacterAdded then
			StaminaClient.onCharacterAdded(character)
		end
		
		-- BUG-015: Reinitialize menu controller on respawn
		if MenuController and MenuController.onCharacterAdded then
			MenuController.onCharacterAdded(character)
		end
		
		-- BUG-015: Reinitialize cure station interaction on respawn
		-- Guard against double-initialization; Phase 5 already initializes this
		if CureStationInteraction and CureStationInteraction.initialize and not CureStationInteraction.enabled then
			CureStationInteraction:initialize()
		end
	end
	
	if loadingManager then loadingManager:updatePhase("CharacterHandlers", 33) end
	
	local function onCharacterRemoving()
		print("[STATE] Character removing")
		
		-- Clear GUI selections before character removal
		local GuiService = game:GetService("GuiService")
		pcall(function()
			GuiService.SelectedObject = nil
		end)
		
		-- Notify all systems of character removal
		if Camera and Camera.onCharacterRemoving then
			Camera.onCharacterRemoving()
		end
		
		if Movement and Movement.onCharacterRemoving then
			Movement.onCharacterRemoving()
		end
		
		if WeaponController and WeaponController.onCharacterRemoving then
			WeaponController.onCharacterRemoving()
		end
		
		if AnimationController and AnimationController.onCharacterRemoving then
			AnimationController.onCharacterRemoving()
		end
		
		if StaminaClient and StaminaClient.onCharacterRemoving then
			StaminaClient.onCharacterRemoving()
		end
		
		-- BUG-015: Cleanup menu controller input connections
		if MenuController and MenuController.onCharacterRemoving then
			MenuController.onCharacterRemoving()
		end
		
		-- BUG-015: Cleanup cure station interaction connections
		if CureStationInteraction and CureStationInteraction.cleanup then
			CureStationInteraction:cleanup()
		end
	end
	
	if loadingManager then loadingManager:updatePhase("CharacterHandlers", 66) end
	
	-- Connect character events
	-- BUG-007 FIX: Store character lifecycle connections
	_connections.characterAdded = player.CharacterAdded:Connect(onCharacterAdded)
	_connections.characterRemoving = player.CharacterRemoving:Connect(onCharacterRemoving)
	
	-- Handle existing character
	if player.Character then
		task.defer(function()
			onCharacterAdded(player.Character)
		end)
	end
	
	if loadingManager then loadingManager:updatePhase("CharacterHandlers", 100) end
	print("[BOOT][CLIENT] Phase 7 complete: Character handlers connected")
	
	----------------------------------------------------------------
	-- PHASE 8: Post-Boot Diagnostics
	----------------------------------------------------------------
	
	print("[BOOT][CLIENT] Phase 8: Running post-boot diagnostics...")
	if loadingManager then loadingManager:updatePhase("Diagnostics", 0) end
	
	-- Run input action audit after all systems have initialized
	task.spawn(function()
		task.wait(1) -- Give systems time to settle
		InputActionRegistry.runStartupAudit()
	end)
	
	print("[BOOT][CLIENT] Phase 8 complete: Diagnostics running")
	if loadingManager then loadingManager:updatePhase("Diagnostics", 100) end
	
	----------------------------------------------------------------
	-- Client Ready
	----------------------------------------------------------------
	
	-- Mark loading as complete
	if loadingManager then
		loadingManager:markComplete()
		print("[BOOT][CLIENT] ✓ Loading complete - title screen ready for interaction")
	end
	
	print("=== [BOOT][CLIENT] Client Ready ===")
	print(string.format("[BOOT][CLIENT] Player: %s", player.Name))
	print(string.format("[BOOT][CLIENT] Version: %s", RemoteRegistry.VERSION))
	print("=== [BOOT][CLIENT] Client initialization complete ===")
	
	-- BUG-007 FIX: Setup cleanup orchestration
	-- Call cleanup when player leaves to prevent memory leaks
	Players.LocalPlayer.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			-- Player is leaving, cleanup all modules
			print("[BOOT][CLIENT] Player leaving, initiating cleanup...")
			
			-- Cleanup core modules
			if Camera and Camera.cleanup then pcall(Camera.cleanup) end
			if Movement and Movement.cleanup then pcall(Movement.cleanup) end
			if WeaponController and WeaponController.cleanup then pcall(WeaponController.cleanup) end
			if AnimationController and AnimationController.cleanup then pcall(AnimationController.cleanup) end
			if AudioController and AudioController.cleanup then pcall(AudioController.cleanup) end
			if MenuController and MenuController.cleanup then pcall(MenuController.cleanup) end
			if MusicController and MusicController.cleanup then pcall(MusicController.cleanup) end
			if StaminaClient and StaminaClient.cleanup then pcall(StaminaClient.cleanup) end
			if VoiceoverController and VoiceoverController.cleanup then pcall(VoiceoverController.cleanup) end
			if CureStationInteraction and CureStationInteraction.cleanup then pcall(CureStationInteraction.cleanup) end
			
			-- Cleanup UI modules
			for moduleName, module in pairs(UI) do
				if type(module) == "table" and module.cleanup then
					pcall(module.cleanup)
				end
			end
			
			-- Cleanup ClientMainModule's own connections
			ClientMainModule.cleanup()
			
			print("[BOOT][CLIENT] Cleanup complete")
		end
	end)
end

function ClientMainModule.initialize()
	if checkInitialized(script) then return end
	bootClient()
end

-- BUG-007 FIX: Cleanup method to disconnect all client connections
function ClientMainModule.cleanup()
	-- Disconnect all connections tracked in this module
	for name, connection in pairs(_connections) do
		if connection then
			connection:Disconnect()
		end
	end
	_connections = {}
	
	print("[ClientMain] Cleanup completed - all connections disconnected")
end

return ClientMainModule
