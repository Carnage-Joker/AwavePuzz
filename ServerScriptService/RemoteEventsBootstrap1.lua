-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "RemoteEvents"
	folder.Parent = ReplicatedStorage
end

local function ensureRemoteEvent(name: string)
	local ev = folder:FindFirstChild(name)
	if ev and not ev:IsA("RemoteEvent") then
		ev:Destroy()
		ev = nil
	end
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = folder
	end
	return ev
end

local names = {
	"AnimationFire",
	"AnimationSprint",
	"AnimationADS",
	"AnimationFireReplicate",
	"AnimationSprintReplicate",
	"AnimationADSReplicate",
}

for _, n in ipairs(names) do
	ensureRemoteEvent(n)
end

print("[RemoteEventsBootstrap] Animation remotes ready:", #names)
