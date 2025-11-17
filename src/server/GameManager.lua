-- GameManager.lua
-- Main server-side game manager that orchestrates waves, base health, win/lose conditions

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local WaveConfig = require(ReplicatedStorage.Shared.WaveConfig)
local BaseManager = require(script.Parent.BaseManager)
local Spawner = require(script.Parent.Spawner)
local PlayerManager = require(script.Parent.PlayerManager)
local ResourceSpawner = require(script.Parent.ResourceSpawner)
local WeaponService = require(script.Parent.WeaponService)
local ShopService = require(script.Parent.ShopService)
local MapManager = require(script.Parent.MapManager)

local GameManager = {}
GameManager.__index = GameManager

-- Game states
GameManager.States = {
        WAITING = "Waiting",
        COUNTDOWN = "Countdown",
        WAVE_ACTIVE = "WaveActive",
        INTERMISSION = "Intermission",
        VICTORY = "Victory",
        DEFEAT = "Defeat"
}

function GameManager.new()
        local self = setmetatable({}, GameManager)

        -- Managers
        self.baseManager = BaseManager.new()
        self.playerManager = PlayerManager.new()
        self.weaponService = WeaponService.new(self.playerManager)
        self.shopService = ShopService.new(self.playerManager, self.weaponService)
        self.resourceSpawner = ResourceSpawner.new(self.playerManager)
        self.mapManager = MapManager.new()
        self.spawner = Spawner.new(self.weaponService)

        if GameConfig.ENABLE_MULTI_MAP then
                self.mapManager:loadDefault()
                self.spawner:setSpawnPoints(self.mapManager:getZombieSpawnPoints())
                self.resourceSpawner:setSpawnPoints(self.mapManager:getResourceSpawnPoints())
        else
                -- Load spawn points from workspace folders only
                self.spawner:loadSpawnPoints()
                -- Do not overwrite spawn points with potentially empty mapManager data
                -- self.spawner:setSpawnPoints(self.mapManager:getZombieSpawnPoints())
                -- self.resourceSpawner:setSpawnPoints(self.mapManager:getResourceSpawnPoints())
        end

        -- Game state
        self.currentState = GameManager.States.WAITING
        self.currentWave = 0
        self.cureProgress = 0

        -- Timers
        self.stateTimer = 0
        self.waveTimeLimit = 0
        self.waveTimeRemaining = 0

        -- Remote events (will be created if they don't exist)
        self.remoteEvents = {}
        self:setupRemoteEvents()

        return self
end

function GameManager:setupRemoteEvents()
        local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEventsFolder then
                remoteEventsFolder = Instance.new("Folder")
                remoteEventsFolder.Name = "RemoteEvents"
                remoteEventsFolder.Parent = ReplicatedStorage
        end

        -- Create remote events if they don't exist
        local eventNames = {
                "WaveAnnounce",
                "WaveUpdate",
                "GameStateUpdate",
                "CureUpdate",
                "BaseHealthUpdate",
                "MapUpdate"
        }

        for _, eventName in ipairs(eventNames) do
                local event = remoteEventsFolder:FindFirstChild(eventName)
                if not event then
                        event = Instance.new("RemoteEvent")
                        event.Name = eventName
                        event.Parent = remoteEventsFolder
                end
                self.remoteEvents[eventName] = event
        end
end

function GameManager:broadcastMap()
        if self.remoteEvents.MapUpdate then
                self.remoteEvents.MapUpdate:FireAllClients({
                        map = self.mapManager:getCurrentMapId()
                })
        end
end

function GameManager:onPlayerAdded(player)
        local success, message = self.playerManager:addPlayer(player)
        if not success then
                warn("Failed to add player:", message)
                return
        end
        self.weaponService:initializePlayer(player)
        self.shopService:sendCatalog(player)
end

function GameManager:onPlayerRemoving(player)
        self.playerManager:removePlayer(player)
        self.weaponService:removePlayer(player)
end

function GameManager:setState(newState)
        self.currentState = newState
        self.stateTimer = 0

        -- Broadcast state change
        if self.remoteEvents.GameStateUpdate then
                self.remoteEvents.GameStateUpdate:FireAllClients({
                        state = newState,
                        wave = self.currentWave,
                        baseHealth = self.baseManager:getHealth(),
                        cureProgress = self.cureProgress
                })
        end
end

function GameManager:startGame()
        if self.currentState ~= GameManager.States.WAITING then
                return false
        end

        print("Starting game...")
        self:setState(GameManager.States.COUNTDOWN)
        self.stateTimer = 5 -- 5 second countdown

        if GameConfig.ENABLE_MULTI_MAP then
                self:broadcastMap()
        end

        return true
end

function GameManager:startWave()
        self.currentWave = self.currentWave + 1

        local waveData = WaveConfig.getWave(self.currentWave)
        if not waveData then
                -- No more configured waves, generate endless mode
                waveData = self:generateEndlessWave()
        end

        print("Starting Wave " .. self.currentWave)

        -- Set wave state
        self:setState(GameManager.States.WAVE_ACTIVE)
        self.waveTimeLimit = waveData.TimeLimit
        self.waveTimeRemaining = waveData.TimeLimit

        -- Announce wave
        if self.remoteEvents.WaveAnnounce then
                self.remoteEvents.WaveAnnounce:FireAllClients({
                        waveNumber = self.currentWave,
                        timeLimit = waveData.TimeLimit,
                        zombieCount = waveData.ZombieCount
                })
        end

        -- Spawn zombies
        self.spawner:spawnWave(waveData.Composition)
end

function GameManager:generateEndlessWave()
        -- Generate procedural waves after configured waves end
        -- Note: Currently uses linear zombie count scaling. Additional difficulty scaling
        -- (health, speed, damage) could be applied for increased challenge in endless mode.
        local baseCount = 15 + (self.currentWave * 2)

        return {
                Number = self.currentWave,
                TimeLimit = 240,
                ZombieCount = baseCount,
                Composition = {
                        Walker = math.floor(baseCount * 0.4),
                        Runner = math.floor(baseCount * 0.3),
                        Brute = math.floor(baseCount * 0.2),
                        Spitter = math.floor(baseCount * 0.1)
                }
        }
end

function GameManager:checkWaveComplete()
        local zombiesAlive = self.spawner:getActiveZombieCount()

        if zombiesAlive <= 0 then
                print("Wave " .. self.currentWave .. " complete!")
                self:onWaveComplete()
                return true
        end

        return false
end

function GameManager:onWaveComplete()
        self:setState(GameManager.States.INTERMISSION)
        self.stateTimer = GameConfig.WAVE_DELAY

        -- Award bonus currency for wave completion
        for _, player in ipairs(Players:GetPlayers()) do
                self.playerManager:addCurrency(player, GameConfig.CURRENCY_PER_WAVE)
        end
end

function GameManager:updateCureProgress(progress)
        self.cureProgress = math.min(100, progress)

        -- Broadcast cure update
        if self.remoteEvents.CureUpdate then
                self.remoteEvents.CureUpdate:FireAllClients(self.cureProgress)
        end

        -- Check win condition
        if self.cureProgress >= 100 then
                self:onVictory()
        end
end

function GameManager:onVictory()
        print("VICTORY! Cure completed!")
        self:setState(GameManager.States.VICTORY)

        -- Stop spawning, clean up zombies
        self.spawner:clearAllZombies()
end

function GameManager:onDefeat(reason)
        print("DEFEAT! " .. reason)
        self:setState(GameManager.States.DEFEAT)

        -- Stop spawning, clean up zombies
        self.spawner:clearAllZombies()
end

function GameManager:checkLoseConditions()
        -- Check if base is destroyed
        if self.baseManager:isBaseDestroyed() then
                self:onDefeat("Base destroyed")
                return true
        end

        -- Check if all players are dead
        local players = game.Players:GetPlayers()
        local anyAlive = false

        for _, player in ipairs(players) do
                if player.Character then
                        local humanoid = player.Character:FindFirstChild("Humanoid")
                        if humanoid and humanoid.Health > 0 then
                                anyAlive = true
                                break
                        end
                end
        end

        if #players > 0 and not anyAlive then
                self:onDefeat("All players eliminated")
                return true
        end

        return false
end

function GameManager:updateCountdown(deltaTime)
        self.stateTimer = self.stateTimer - deltaTime
        self.resourceSpawner:update(deltaTime)

        if self.stateTimer <= 0 then
                -- Start first wave
                self:startWave()
        end
end

function GameManager:updateWave(deltaTime)
        -- Update wave timer
        self.waveTimeRemaining = self.waveTimeRemaining - deltaTime

        -- Update spawner
        self.spawner:update(deltaTime)

        -- Update resource spawner for pickups
        self.resourceSpawner:update(deltaTime)

        -- Broadcast wave update periodically
        if math.floor(self.waveTimeRemaining) % 5 == 0 then
                if self.remoteEvents.WaveUpdate then
                        self.remoteEvents.WaveUpdate:FireAllClients({
                                timeRemaining = math.floor(self.waveTimeRemaining),
                                zombiesAlive = self.spawner:getActiveZombieCount()
                        })
                end
        end

        -- Check if wave is complete
        self:checkWaveComplete()

        -- Check if time ran out
        if self.waveTimeRemaining <= 0 then
                print("Wave time limit reached!")
                self:onWaveComplete()
        end

        -- Check lose conditions
        self:checkLoseConditions()
end

function GameManager:updateIntermission(deltaTime)
        self.stateTimer = self.stateTimer - deltaTime

        -- Continue spawning resources during downtime
        self.resourceSpawner:update(deltaTime)

        if self.stateTimer <= 0 then
                -- Start next wave
                self:startWave()
        end
end

function GameManager:update(deltaTime)
        -- Update based on current state
        if self.currentState == GameManager.States.COUNTDOWN then
                self:updateCountdown(deltaTime)

        elseif self.currentState == GameManager.States.WAVE_ACTIVE then
                self:updateWave(deltaTime)

        elseif self.currentState == GameManager.States.INTERMISSION then
                self:updateIntermission(deltaTime)

        elseif self.currentState == GameManager.States.WAITING then
                -- Check if enough players to start
                local playerCount = #game.Players:GetPlayers()
                if playerCount >= 1 then -- Start with at least 1 player
                        self:startGame()
                end
                self.resourceSpawner:update(deltaTime)
        else
                -- Even when game is over, allow resource spawner to clean up timers
                self.resourceSpawner:update(deltaTime)
        end
end

function GameManager:getPlayerManager()
        return self.playerManager
end

function GameManager:getGameState()
        return {
                state = self.currentState,
                wave = self.currentWave,
                baseHealth = self.baseManager:getHealth(),
                baseHealthPercent = self.baseManager:getHealthPercentage(),
                cureProgress = self.cureProgress,
                zombiesRemaining = self.spawner:getActiveZombieCount(),
                timeRemaining = math.floor(self.waveTimeRemaining)
        }
end

return GameManager
