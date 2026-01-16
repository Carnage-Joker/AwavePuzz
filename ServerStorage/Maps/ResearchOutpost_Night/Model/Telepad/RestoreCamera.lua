-- @ScriptType: LocalScript
while script.Parent == nil do wait() end
while script.Parent:FindFirstChild("Humanoid") == nil do wait() end

game.Workspace.CurrentCamera.CameraType = "Custom"
game.Workspace.CurrentCamera.CameraSubject = script.Parent.Humanoid

script:remove()
