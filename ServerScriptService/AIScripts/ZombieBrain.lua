--[[
    ZombieBrain module
    Provides simple pathfinding and base attacking behaviour that can be attached
    to any zombie model. The Spawner passes callbacks for when the zombie reaches
    the base so the GameManager can process base damage.
]]

local PathfindingService = game:GetService("PathfindingService")

local ZombieBrain = {}
local brains = {}

local function moveAlongPath(humanoid, root, targetPosition)
    local path = PathfindingService:CreatePath()
    local success, _ = pcall(function()
        path:ComputeAsync(root.Position, targetPosition)
    end)

    if not success or path.Status ~= Enum.PathStatus.Success then
        humanoid:MoveTo(targetPosition)
        humanoid.MoveToFinished:Wait()
        return
    end

    local waypoints = path:GetWaypoints()
    for _, waypoint in ipairs(waypoints) do
        humanoid:MoveTo(waypoint.Position)
        local reached = humanoid.MoveToFinished:Wait()
        if not reached then
            break
        end
    end
end

function ZombieBrain.start(model, options)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then
        warn("ZombieBrain requires Humanoid and HumanoidRootPart")
        return function() end
    end

    local targetPart = options.TargetPart
    local attackInterval = options.AttackInterval or 2
    local attackRange = options.AttackRange or 5
    local onBaseAttack = options.OnBaseAttack
    local damage = options.Damage or 5

    local alive = true
    humanoid.Died:Connect(function()
        alive = false
    end)

    local movementThread = task.spawn(function()
        while alive and model.Parent do
            if targetPart then
                moveAlongPath(humanoid, root, targetPart.Position)
            else
                task.wait(1)
            end
            task.wait(0.2)
        end
    end)

    local attackThread = task.spawn(function()
        local lastAttack = 0
        while alive and model.Parent do
            if targetPart then
                local distance = (root.Position - targetPart.Position).Magnitude
                if distance <= attackRange then
                    local now = os.clock()
                    if now - lastAttack >= attackInterval then
                        lastAttack = now
                        if onBaseAttack then
                            onBaseAttack(damage, model)
                        end
                    end
                end
            end
            task.wait(0.2)
        end
    end)

    brains[model] = {movementThread, attackThread}

    return function()
        if movementThread then
            task.cancel(movementThread)
        end
        if attackThread then
            task.cancel(attackThread)
        end
        brains[model] = nil
    end
end

function ZombieBrain.stop(model)
    local threads = brains[model]
    if not threads then
        return
    end

    for _, thread in ipairs(threads) do
        task.cancel(thread)
    end
    brains[model] = nil
end

return ZombieBrain
