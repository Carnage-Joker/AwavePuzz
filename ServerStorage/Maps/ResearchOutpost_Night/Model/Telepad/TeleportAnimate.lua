-- @ScriptType: LocalScript
while (script:FindFirstChild("TeleBallPointer") == nil) do script.ChildAdded:wait() end

local teleBallPointer = script.TeleBallPointer
local teleBall = teleBallPointer.Value
local endCFrame = teleBall.CFrame
local camera = game.Workspace.CurrentCamera
teleBall.CFrame = CFrame.new(teleBall.Position, teleBall.Position + camera.CoordinateFrame.lookVector)
camera.CameraType = "Attach"

newBG = Instance.new("BodyGyro")
newBG.Name = "CameraRotateForce"
newBG.P = 3000
newBG.maxTorque = Vector3.new(newBG.P, newBG.P, newBG.P)
newBG.cframe = endCFrame
newBG.Parent = teleBall

camera.CameraSubject = teleBall
