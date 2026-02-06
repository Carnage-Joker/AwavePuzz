-- @ScriptType: ModuleScript
-- BootModule.lua
-- FIRST LOAD CLIENT LOGIC
-- Ensures Title Screen appears before ANY map, lobby, or character is visible
-- Implements deterministic boot order: Camera → UI → Server Ready → Spawn
-- Pattern: LocalScript → ModuleScript eliminates RunContext duplicate execution issues

local BootModule = {}

function BootModule.run()
	print("=== [BOOTMODULE] Starting client initialization ===")
	
	local StarterGui = game:GetService("StarterGui")
	local Workspace = game:GetService("Workspace")
	
	local camera = Workspace.CurrentCamera
	
	----------------------------------------------------------------
	-- PHASE 0: IMMEDIATE CAMERA CONTROL + BLACK SCREEN
	----------------------------------------------------------------
	
	print("[BOOTMODULE] Phase 0: Taking immediate camera control...")
	
	-- Set camera to scriptable BEFORE anything else
	camera.CameraType = Enum.CameraType.Scriptable
	
	-- Position camera in a neutral/safe position (black void)
	-- This prevents any flash of the default spawn or lobby
	camera.CFrame = CFrame.new(Vector3.new(0, 100000, 0)) -- Far above world to avoid any map/skybox content
	
	-- Disable default Roblox UI during boot
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	end)
	
	print("[BOOTMODULE] Phase 0 complete: Camera scriptable, screen black")
	
	----------------------------------------------------------------
	-- PHASE 0.5: CREATE AND SHOW TITLE SCREEN IMMEDIATELY
	----------------------------------------------------------------
	
	print("[BOOTMODULE] Phase 0.5: Creating and showing TitleScreenUI immediately...")
	
	-- Load TitleScreenUI module and create instance BEFORE other systems
	local clientModules = script.Parent:WaitForChild("Modules", 10)
	local uiFolder = clientModules and clientModules:FindFirstChild("UI")
	local titleScreenModule = uiFolder and uiFolder:FindFirstChild("TitleScreenUI")
	
	local titleScreenInstance = nil
	local loadingManager = nil
	
	if titleScreenModule then
		local success, TitleScreenClass = pcall(function()
			return require(titleScreenModule)
		end)
		if success and TitleScreenClass then
			-- TitleScreenUI.new() creates the UI and sets DisplayOrder=200
			local newSuccess, newResult = pcall(function()
				return TitleScreenClass.new()
			end)
			if newSuccess and newResult then
				titleScreenInstance = newResult
				
				-- Call show() immediately to display the title screen
				-- This happens BEFORE remotes are bound, which is intentional
				-- The show() method handles this gracefully and will enable interaction later
				titleScreenInstance:show()
				print("[BOOTMODULE] ✓ TitleScreenUI displayed immediately")
				
				-- Initialize LoadingManager and connect to TitleScreenUI
				local LoadingManagerModule = clientModules and clientModules:FindFirstChild("LoadingManager")
				if LoadingManagerModule then
					local lmSuccess, LoadingManagerClass = pcall(function()
						return require(LoadingManagerModule)
					end)
					if lmSuccess and LoadingManagerClass then
						loadingManager = LoadingManagerClass.new()
						
						-- Connect loading progress to TitleScreenUI
						loadingManager:onProgressChanged(function(progress, phaseName)
							if titleScreenInstance then
								titleScreenInstance:updateLoadingProgress(progress, phaseName)
							end
						end)
						
						-- Store globally so ClientMainModule can use it
						shared.__AwavePuzzLoadingManager = loadingManager
						print("[BOOTMODULE] ✓ LoadingManager initialized and connected to TitleScreenUI")
					else
						warn("[BOOTMODULE] ✗ Failed to load LoadingManager:", LoadingManagerClass)
					end
				else
					warn("[BOOTMODULE] ✗ LoadingManager module not found")
				end
				
				-- Store globally so ClientMainModule can bind remotes later
				shared.__AwavePuzzTitleScreenInstance = titleScreenInstance
				print("[BOOTMODULE] ✓ TitleScreenUI created and shown with DisplayOrder=200")
				print("[BOOTMODULE] ✓ Title screen visible NOW (remotes will be bound later)")
			else
				warn("[BOOTMODULE] ✗ Failed to create TitleScreenUI instance:", newResult)
			end
		else
			warn("[BOOTMODULE] ✗ Failed to load TitleScreenUI:", TitleScreenClass)
		end
	else
		warn("[BOOTMODULE] ✗ TitleScreenUI module not found")
	end
	
	if titleScreenInstance then
		print("[BOOTMODULE] Phase 0.5 complete: TitleScreenUI visible on screen")
	else
		warn("[BOOTMODULE] Phase 0.5 complete: TitleScreenUI not created; continuing without title screen")
	end
	
	----------------------------------------------------------------
	-- PHASE 1: DELEGATE TO CLIENT MAIN MODULE
	----------------------------------------------------------------
	
	print("[BOOTMODULE] Phase 1: Loading ClientMainModule...")
	
	-- Load ClientMainModule to initialize all systems
	-- ClientMainModule will handle:
	-- - Binding remotes to TitleScreenUI (already displayed)
	-- - Initializing all other game systems
	-- - Restoring camera control after title dismissed
	local ClientMainModule = require(script.Parent:WaitForChild("ClientMainModule"))
	ClientMainModule.initialize()
	
	print("[BOOTMODULE] Phase 1 complete: ClientMainModule initialized")
	
	----------------------------------------------------------------
	-- BOOT COMPLETE
	----------------------------------------------------------------
	
	print("=== [BOOTMODULE] Client initialization complete ===")
end

return BootModule
