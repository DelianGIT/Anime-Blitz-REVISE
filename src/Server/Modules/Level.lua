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
local PerksLibrary = require(ServerModules.PerksLibrary)

--// CONSTANTS
local LEVELS_REQUIREMENTS = {
	1000,
	1500
}

--// VARIABLES
local statsAtom = PlayerData.Atoms.Stats

local Module = {}

--// FUNCTIONS
local function getLevel(level: number, experience: number): (number, number)
	local requirement: number = LEVELS_REQUIREMENTS[level]
	
	while requirement and experience >= requirement do
		experience -= requirement
		level += 1

		requirement = LEVELS_REQUIREMENTS[level]
	end
	
	if not requirement then
		experience = 0
	end

	return level, experience
end

--// MODULE FUNCTIONS
function Module.GiveExperience(player: Player, damageAmount: number)
	local stats = statsAtom()[player]

	local currentLevel: number = stats.Level
	local currentExperience: number = stats.Experience + damageAmount
	local newLevel: number, newExperience: number = getLevel(currentLevel, currentExperience)

	stats = Sift.Dictionary.copy(stats)
	stats.Level = newLevel
	stats.Experience = newExperience
	statsAtom(function(state)
		return Sift.Dictionary.set(state, player, stats)
	end)

	if currentLevel ~= newLevel then
		PerksLibrary.Update(player)
	end
end

return Module