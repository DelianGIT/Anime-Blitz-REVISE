--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)

--// MODULES
local ServerModules = ServerScriptService.Modules
local PlayerData = require(ServerModules.PlayerData)

--// CONSTANTS
local UNITS = {}

--// VARIABLES
local Module = {}

--// MODULE FUNCTIONS
function Module.Charge(player: Player, damageAmount: number): ()
	local playerData: PlayerData.Data = PlayerData.Get(player)
	local characterData = playerData.CharacterData
	if not characterData then
		return
	end

	local unit: number = UNITS[characterData.Category]
	local charge: number = playerData.UltimateCharge + damageAmount / unit
	charge = math.clamp(charge, 0, 100)

	PlayerData.Update(player, function()
		playerData = Sift.Dictionary.copy(playerData)
		playerData.UltimateCharge = charge
		return playerData
	end)
end

return Module