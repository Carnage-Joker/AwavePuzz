-- @ScriptType: Script
-- WeaponConfig.lua
-- Defines the available weapons, upgrades, and shop items for AWavePuzz
-- Weapons include damage, fire rate, range, and pricing information


local WeaponConfig = {}

WeaponConfig.DefaultWeapon = "Standard Issue Pistol"

WeaponConfig.Weapons = {
	Pistol = {
		Name = "Standard Issue Pistol",
		ModelName = "Pistol",
		Damage = 18,
		FireRate = 0.35, -- seconds between shots
		Range = 175,
		Automatic = false,
		RewardBonus = 2,
		Price = 0
	},
	SMG = {
		Name = "Rapid SMG",
		ModelName = "SMG",
		Damage = 12,
		FireRate = 0.12,
		Range = 150,
		Automatic = true,
		RewardBonus = 1,
		Price = 450
	},
	Shotgun = {
		Name = "Scatter Shotgun",
		ModelName = "Shotgun",
		Damage = 35,
		FireRate = 0.8,
		Range = 90,
		PelletCount = 6,
		Automatic = false,
		RewardBonus = 4,
		Price = 700
	},
	Rifle = {
		Name = "Long-Range Rifle",
		ModelName = "Rifle",
		Damage = 42,
		FireRate = 0.6,
		Range = 250,
		Automatic = false,
		RewardBonus = 5,
		Price = 900
	}
}

WeaponConfig.Upgrades = {
	DAMAGE_I = {
		Id = "DAMAGE_I",
		Name = "Damage Boost I",
		Description = "+15% damage",
		Type = "stat",
		Stat = "Damage",
		Multiplier = 1.15,
		Price = 250
	},
	DAMAGE_II = {
		Id = "DAMAGE_II",
		Name = "Damage Boost II",
		Description = "+25% damage",
		Type = "stat",
		Stat = "Damage",
		Multiplier = 1.25,
		Price = 450
	},
	FIRERATE_I = {
		Id = "FIRERATE_I",
		Name = "Trigger Upgrade",
		Description = "10% faster fire-rate",
		Type = "stat",
		Stat = "FireRate",
		Multiplier = 0.9,
		Price = 350
	}
}

WeaponConfig.ShopItems = {
	{
		Id = "weapon_smg",
		Type = "weapon",
		WeaponId = "SMG",
		Price = WeaponConfig.Weapons.SMG.Price,
		Description = "Rapid-fire SMG great for clearing runners."
	},
	{
		Id = "weapon_shotgun",
		Type = "weapon",
		WeaponId = "Shotgun",
		Price = WeaponConfig.Weapons.Shotgun.Price,
		Description = "High burst damage for close range."
	},
	{
		Id = "weapon_rifle",
		Type = "weapon",
		WeaponId = "Rifle",
		Price = WeaponConfig.Weapons.Rifle.Price,
		Description = "Precision rifle ideal for bosses."
	},
	{
		Id = "upgrade_damage_i",
		Type = "upgrade",
		UpgradeId = "DAMAGE_I",
		Price = WeaponConfig.Upgrades.DAMAGE_I.Price,
		Description = WeaponConfig.Upgrades.DAMAGE_I.Description
	},
	{
		Id = "upgrade_damage_ii",
		Type = "upgrade",
		UpgradeId = "DAMAGE_II",
		Price = WeaponConfig.Upgrades.DAMAGE_II.Price,
		Description = WeaponConfig.Upgrades.DAMAGE_II.Description
	},
	{
		Id = "upgrade_firerate_i",
		Type = "upgrade",
		UpgradeId = "FIRERATE_I",
		Price = WeaponConfig.Upgrades.FIRERATE_I.Price,
		Description = WeaponConfig.Upgrades.FIRERATE_I.Description
	}
}

function WeaponConfig.getWeapon(weaponId)
	return WeaponConfig.Weapons[weaponId]
end

function WeaponConfig.getUpgrade(upgradeId)
	return WeaponConfig.Upgrades[upgradeId]
end

function WeaponConfig.getCatalog()
	return WeaponConfig.ShopItems
end

return WeaponConfig
