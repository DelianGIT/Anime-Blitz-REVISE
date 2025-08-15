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

--// TYPES
type Team = "A" | "B" | "None"

--// VARIABLES
local sharedAtoms = DataStore.SharedAtoms
local teamA: DataStore.Atom<boolean> = sharedAtoms.TeamA
local teamB: DataStore.Atom<boolean> = sharedAtoms.TeamB

local Module = {}

--// MODULE PROPERTIES
Module.TeamA = teamA
Module.TeamB = teamB

--// MODULE FUNCTIONS
function Module.Add(player: Player, team: "A" | "B"): ()
	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
	local currentTeam: Team? = tempData.Team
	if currentTeam ~= "None" then
		error(`Player is already in team {currentTeam}`)
	end

	tempData = Sift.Dictionary.copy(tempData)
	tempData.Team = team
	DataStore.UpdateTemporaryData(player, tempData)

	local atom: DataStore.Atom<boolean>
	if team == "A" then
		atom = teamA
	elseif team == "B" then
		atom = teamB
	end

	atom(function(state: { [Player]: boolean })
		return Sift.Set.add(state, player)
	end)
end

function Module.Remove(player: Player): ()
	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
	local currentTeam: Team? = tempData.Team
	if not currentTeam then
		error(`Player isn't in team`)
	end

	tempData = Sift.Dictionary.copy(tempData)
	tempData.Team = "None"
	DataStore.UpdateTemporaryData(player, tempData)

	local atom: DataStore.Atom<boolean>
	if currentTeam == "A" then
		atom = teamA
	elseif currentTeam == "B" then
		atom = teamB
	end

	atom(function(state: { [Player]: boolean })
		return Sift.Set.delete(state, player)
	end)
end

function Module.Get(player: Player): Team
	if teamA()[player] then
		return "A"
	elseif teamB()[player] then
		return "B"
	else
		return "None"
	end
end

function Module.AreInSame(player1: Player, player2: Player, noneIsDifferent: boolean?): boolean
	local team1: Team = Module.Get(player1)
	local team2: Team = Module.Get(player2)

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