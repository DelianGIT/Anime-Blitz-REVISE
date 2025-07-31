--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)
local Charm = require(Packages.Charm)

--// MODULES
local ServerModules = ServerScriptService.Modules
local PlayerData = require(ServerModules.PlayerData)

--// TYPES
type Team = "A" | "B" | "None"

--// VARIABLES
local sharedAtoms = PlayerData.SharedAtoms
local teamA: Charm.Atom<{ [Player]: boolean }> = sharedAtoms.TeamA
local teamB: Charm.Atom<{ [Player]: boolean }> = sharedAtoms.TeamB

local Module = {}

--// MODULE PROPERTIES
Module.TeamA = teamA
Module.TeamB = teamB

--// MODULE FUNCTIONS
function Module.Add(player: Player, team: "A" | "B"): ()
	local playerData: PlayerData.Data = PlayerData.Get(player)
	local currentTeam: Team? = playerData.Team
	if currentTeam ~= "None" then
		error(`Player is already in team {currentTeam}`)
	end

	PlayerData.Update(player, function()
		playerData = Sift.Dictionary.copy(playerData)
		playerData.Team = team
		return playerData
	end)

	local atom: Charm.Atom<{ [Player]: boolean }>
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
	local playerData: PlayerData.Data = PlayerData.Get(player)
	local currentTeam: Team? = playerData.Team
	if not currentTeam then
		error(`Player isn't in team`)
	end

	PlayerData.Update(player, function()
		playerData = Sift.Dictionary.copy(playerData)
		playerData.Team = "None"
		return playerData
	end)

	local atom: Charm.Atom<{ [Player]: boolean }>
	if currentTeam == "A" then
		atom = teamA
	elseif currentTeam == "B" then
		atom = teamB
	end

	atom(function(state: { [Player]: boolean })
		return Sift.Set.delete(state, player)
	end)
end

--// OBSERVERS
Charm.observe(PlayerData.Atom :: any, function(_, player: Player)
	return function()
		if teamA()[player] then
			teamA(function(state: { [Player]: boolean })
				return Sift.Set.delete(state, player)
			end)
		elseif teamB()[player] then
			teamB(function(state: { [Player]: boolean })
				return Sift.Set.delete(state, player)
			end)
		end
	end
end)

return Module