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
local characterDataAtom = PlayerData.SharedAtoms.CharacterData
local statsAtom = PlayerData.Atoms.Stats

local Module = {}

--// MODULE FUNCTIONS
function Module.Charge(player: Player, damageAmount: number): ()
	local characterData = characterDataAtom()[player]
	if not characterData then
		return
	end

	local stats = statsAtom()[player]

	local unit: number = UNITS[characterData.Category]
	local charge: number = stats.UltimateCharge + damageAmount / unit
	charge = math.clamp(charge, 0, 100)

	stats = Sift.Dictionary.copy(stats)
	stats.UltimateCharge = charge
	statsAtom(function(state)
		return Sift.Dictionary.set(state, player, stats)
	end)
end

return Module