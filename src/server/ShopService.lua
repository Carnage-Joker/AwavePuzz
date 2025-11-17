-- ShopService.lua
-- Handles server-authoritative weapon purchases and upgrades

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponConfig = require(ReplicatedStorage.Shared.WeaponConfig)

local ShopService = {}
ShopService.__index = ShopService

function ShopService.new(playerManager, weaponService)
        local self = setmetatable({}, ShopService)
        self.playerManager = playerManager
        self.weaponService = weaponService
        self.remoteEvents = {}
        self:setupRemoteEvents()
        return self
end

function ShopService:setupRemoteEvents()
        local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEventsFolder then
                remoteEventsFolder = Instance.new("Folder")
                remoteEventsFolder.Name = "RemoteEvents"
                remoteEventsFolder.Parent = ReplicatedStorage
        end

        local requestEvent = remoteEventsFolder:FindFirstChild("ShopRequest")
        if not requestEvent then
                requestEvent = Instance.new("RemoteEvent")
                requestEvent.Name = "ShopRequest"
                requestEvent.Parent = remoteEventsFolder
        end
        self.remoteEvents.ShopRequest = requestEvent

        local updateEvent = remoteEventsFolder:FindFirstChild("ShopUpdate")
        if not updateEvent then
                updateEvent = Instance.new("RemoteEvent")
                updateEvent.Name = "ShopUpdate"
                updateEvent.Parent = remoteEventsFolder
        end
        self.remoteEvents.ShopUpdate = updateEvent

        requestEvent.OnServerEvent:Connect(function(player, action, data)
                self:handleRequest(player, action, data)
        end)
end

function ShopService:handleRequest(player, action, data)
        if action == "catalog" then
                self:sendCatalog(player)
        elseif action == "purchase" and data and data.itemId then
                self:attemptPurchase(player, data.itemId)
        end
end

function ShopService:sendCatalog(player)
        if self.remoteEvents.ShopUpdate then
                self.remoteEvents.ShopUpdate:FireClient(player, {
                        type = "catalog",
                        items = WeaponConfig.getCatalog()
                })
        end
end

function ShopService:attemptPurchase(player, itemId)
        local catalog = WeaponConfig.getCatalog()
        local selectedItem = nil
        for _, item in ipairs(catalog) do
                if item.Id == itemId then
                        selectedItem = item
                        break
                end
        end

        if not selectedItem then
                self:sendResult(player, false, "Item not found")
                return
        end

        if selectedItem.Type == "weapon" then
                if self.playerManager:ownsWeapon(player, selectedItem.WeaponId) then
                        self:sendResult(player, false, "Weapon already unlocked")
                        return
                end

                if not self.playerManager:deductCurrency(player, selectedItem.Price) then
                        self:sendResult(player, false, "Not enough currency")
                        return
                end

                self.playerManager:addWeapon(player, selectedItem.WeaponId)
                self.playerManager:equipWeapon(player, selectedItem.WeaponId)
                self:sendResult(player, true, selectedItem.WeaponId .. " unlocked!")
        elseif selectedItem.Type == "upgrade" then
                if not self.playerManager:deductCurrency(player, selectedItem.Price) then
                        self:sendResult(player, false, "Not enough currency")
                        return
                end

                local success = self.weaponService:applyUpgrade(player, selectedItem.UpgradeId)
                if success then
                        self:sendResult(player, true, "Upgrade applied")
                else
                        -- refund if already owned
                        self.playerManager:addCurrency(player, selectedItem.Price)
                        self:sendResult(player, false, "Upgrade already owned")
                end
        end
end

function ShopService:sendResult(player, success, message)
        if self.remoteEvents.ShopUpdate then
                self.remoteEvents.ShopUpdate:FireClient(player, {
                        type = "result",
                        success = success,
                        message = message
                })
        end
end

return ShopService
