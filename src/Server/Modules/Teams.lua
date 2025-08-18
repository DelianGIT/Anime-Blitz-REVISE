--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Charm = require(Packages.Charm)
local Sift = require(Packages.Sift)

--// MODULES
local ServerModules = ServerScriptService.Modules
local PlayerData = require(ServerModules.PlayerData)

--// TYPES
type Team = "A" | "B" | "None"

--// VARIABLES
local teamAtom = PlayerData.Atoms.Team

local Module = {}

--// MODULE PROPERTIES
Module.TeamA = Charm.computed(function()
	local teamMembers: { Player } = {}
	for player, team in pairs(teamAtom()) do
		if team == "A" then
			table.insert(teamMembers, player)
		end
	end
	return teamMembers
end)

Module.TeamB = Charm.computed(function()
	local teamMembers: { Player } = {}
	for player, team in pairs(teamAtom()) do
		if team == "B" then
			table.insert(teamMembers, player)
		end
	end
	return teamMembers
end)

--// MODULE FUNCTIONS
function Module.Add(player: Player, team: "A" | "B"): ()
	local currentTeam: Team = teamAtom()[player]
	if currentTeam == "None" then
		teamAtom(function(state)
			return Sift.Dictionary.set(state, player, team :: Team)
		end)
	else
		error(`Player is already in team {currentTeam}`)
	end
end

function Module.Remove(player: Player): ()
	local currentTeam: Team = teamAtom()[player]
	if currentTeam ~= "None" then
		teamAtom(function(state)
			return Sift.Dictionary.set(state, player, "None" :: Team)
		end)
	else
		error(`Player isn't in team`)
	end
end

function Module.AreInSame(player1: Player, player2: Player, noneIsDifferent: boolean?): boolean
	local state: { [Player]: Team } = teamAtom()
	local team1: Team = state[player1]
	local team2: Team = state[player2]

	if team1 == team2 then
		if noneIsDifferent and team1 == "None" then
			return false
		else
			return true
		end
	else
		return false
	end
end

return Module