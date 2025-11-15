--[[
    GameManager
    Controls the wave loop, base health, and RemoteEvent updates.
    Later phases will extend this script to integrate cure progress and alliances.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:FindFirstChild("Shared") or Instance.new("Folder")
sharedFolder.Name = "Shared"
sharedFolder.Parent = ReplicatedStorage

local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents") or Instance.new("Folder")
remoteFolder.Name = "RemoteEvents"
remoteFolder.Parent = ReplicatedStorage

local function getOrCreateRemote(name)
    local remote = remoteFolder:FindFirstChild(name)
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = remoteFolder
    end
    return remote
end

local Config = require(sharedFolder:WaitForChild("Config"))
local WaveConfig = require(sharedFolder:WaitForChild("WaveConfig"))
local Spawner = require(script.Parent:WaitForChild("Spawner"))

local waveAnnounce = getOrCreateRemote("WaveAnnounce")
local waveUpdate = getOrCreateRemote("WaveUpdate")

local statusFolder = ReplicatedStorage:FindFirstChild("GameStatus") or Instance.new("Folder")
statusFolder.Name = "GameStatus"
statusFolder.Parent = ReplicatedStorage

local baseHealthValue = statusFolder:FindFirstChild("BaseHealth") or Instance.new("IntValue")
baseHealthValue.Name = "BaseHealth"
baseHealthValue.Value = Config.Base.MaxHealth
baseHealthValue.Parent = statusFolder

local waveValue = statusFolder:FindFirstChild("CurrentWave") or Instance.new("IntValue")
waveValue.Name = "CurrentWave"
waveValue.Value = 0
waveValue.Parent = statusFolder

local zombiesAliveValue = statusFolder:FindFirstChild("ZombiesAlive") or Instance.new("IntValue")
zombiesAliveValue.Name = "ZombiesAlive"
zombiesAliveValue.Value = 0
zombiesAliveValue.Parent = statusFolder

local timeLeftValue = statusFolder:FindFirstChild("WaveTimeLeft") or Instance.new("IntValue")
timeLeftValue.Name = "WaveTimeLeft"
timeLeftValue.Value = 0
timeLeftValue.Parent = statusFolder

local baseCaptureZone = workspace:WaitForChild("BaseCaptureZone")
local spawnController = Spawner.new({
    TargetPart = baseCaptureZone,
    OnZombieSpawned = function()
        zombiesAliveValue.Value += 1
        waveUpdate:FireAllClients({
            wave = waveValue.Value,
            timeLeft = timeLeftValue.Value,
            zombiesAlive = zombiesAliveValue.Value,
            baseHealth = baseHealthValue.Value,
        })
    end,
    OnZombieRemoved = function()
        zombiesAliveValue.Value = math.max(zombiesAliveValue.Value - 1, 0)
    end,
    OnBaseDamaged = function(amount)
        baseHealthValue.Value = math.max(baseHealthValue.Value - amount, 0)
        if baseHealthValue.Value <= 0 then
            spawnController:StopWave()
            waveAnnounce:FireAllClients({message = "Base destroyed! Survivors failed."})
        end
    end,
})

local waveIndex = 0
local matchActive = true
local countdown = Config.Waves.InitialCountdown

local function broadcastWave()
    waveUpdate:FireAllClients({
        wave = waveValue.Value,
        timeLeft = timeLeftValue.Value,
        zombiesAlive = zombiesAliveValue.Value,
        baseHealth = baseHealthValue.Value,
    })
end

local function regenBase()
    baseHealthValue.Value = math.min(Config.Base.MaxHealth, baseHealthValue.Value + Config.Base.WaveClearRegen)
end

local function getWaveData(index)
    return WaveConfig[index] or WaveConfig[#WaveConfig]
end

local function runCountdown(seconds, message)
    for i = seconds, 1, -1 do
        waveAnnounce:FireAllClients({message = string.format("%s %d", message, i)})
        timeLeftValue.Value = i
        broadcastWave()
        task.wait(1)
    end
end

local function startWave()
    waveIndex += 1
    local waveData = getWaveData(waveIndex)
    waveValue.Value = waveData.number or waveIndex
    zombiesAliveValue.Value = 0
    timeLeftValue.Value = waveData.timeLimit
    waveAnnounce:FireAllClients({message = string.format("Wave %d incoming!", waveValue.Value)})
    spawnController:StartWave(waveData)

    local timer = waveData.timeLimit
    while timer > 0 and baseHealthValue.Value > 0 do
        timer -= 1
        timeLeftValue.Value = timer
        broadcastWave()

        if spawnController:IsFinishedSpawning() and zombiesAliveValue.Value <= 0 then
            waveAnnounce:FireAllClients({message = string.format("Wave %d cleared!", waveValue.Value)})
            regenBase()
            return
        end
        task.wait(1)
    end

    waveAnnounce:FireAllClients({message = string.format("Wave %d timer expired!", waveValue.Value)})
end

local function intermission()
    runCountdown(Config.Waves.Intermission, "Next wave in")
end

local function mainLoop()
    runCountdown(countdown, "Prepare!")

    while matchActive and baseHealthValue.Value > 0 do
        startWave()
        if baseHealthValue.Value <= 0 then
            break
        end
        intermission()
    end
end

task.spawn(function()
    mainLoop()
end)
