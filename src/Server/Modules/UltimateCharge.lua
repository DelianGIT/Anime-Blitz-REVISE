--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)

--// MODULES
local ServerModules = ServerScriptService.Modules
local DataStore = require(ServerModules.DataStore)

--// CONSTANTS
local UNITS = {}

--// VARIABLES
local Module = {}

--// MODULE FUNCTIONS
function Module.Charge(player: Player, damageAmount: number): ()
	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
	local characterData = tempData.CharacterData
	if not characterData then
		return
	end

	local unit: number = UNITS[characterData.Category]
	local charge: number = tempData.UltimateCharge + damageAmount / unit
	charge = math.clamp(charge, 0, 100)

	tempData = Sift.Dictionary.set(tempData, "UltimateCharge", charge)
	DataStore.UpdateTemporaryData(player, tempData)
end

return Module