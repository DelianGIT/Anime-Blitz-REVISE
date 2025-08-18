--!strict
--// SERVICES
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Charm = require(Packages.Charm)

--// MODULES
local ClientModules = ReplicatedFirst.Modules
local SharedPlayerData = require(ClientModules.SharedPlayerData)

--// TYPES
type Team = "A" | "B" | "None"

--// VARIABLES
local localPlayer: Player = Players.LocalPlayer
local localPlayerName: string = localPlayer.Name

local charactersFolder = workspace.Living.Players

local assetsFolder = ReplicatedStorage.Miscellaneous.TeamsHighlights
local greenHighlight: Highlight = assetsFolder.Green
local redHighlight: Highlight = assetsFolder.Red
local whiteHighlight: Highlight = assetsFolder.White

local teamAtom = SharedPlayerData.Team

local myTeam: Team

--// DERIVING TEAM ATOM BY PLAYER NAMES
local derivedTeamAtom = Charm.computed(function()
	local state: { [string]: Team } = {}
	for player, team in pairs(teamAtom()) do
		state[player.Name] = team
	end
	return state
end)

--// FUNCTIONS
local function addHighlight(character: Model, team: Team): ()
	local existingHighlight: Highlight? = character:FindFirstChild("TeamHighlight") :: Highlight?
	if existingHighlight then
		existingHighlight:Destroy()
	end

	local highlight: Highlight
	if myTeam == "None" then
		if (team :: any) == "None" then
			highlight = whiteHighlight
		end
	else
		if myTeam == team then
			highlight = greenHighlight
		else
			highlight = redHighlight
		end
	end

	highlight = highlight:Clone()
	highlight.Name = "TeamHighlight"
	highlight.Parent = character
end

--// EVENTS
Charm.subscribe(derivedTeamAtom :: any, function(state: { [string]: Team })
	myTeam = state[localPlayerName]

	for _, character in ipairs(charactersFolder:GetChildren()) do
		local characterName: string = character.Name
		if localPlayerName ~= characterName and character:IsA("Model") then
			addHighlight(character :: Model, state[characterName])
		end
	end
end)

--// OBSERVERS
charactersFolder.ChildAdded:Connect(function(character: Instance)
	local characterName: string = character.Name
	if localPlayerName ~= characterName and character:IsA("Model") then
		addHighlight(character :: Model, derivedTeamAtom()[characterName])
	end
end)

charactersFolder.ChildRemoved:Connect(function(character: Instance)
	if localPlayerName == character.Name or not character:IsA("Model") then
		return
	end

	local existingHighlight: Highlight? = (character :: any):FindFirstChild("TeamHighlight") :: Highlight?
	if existingHighlight then
		existingHighlight:Destroy()
	end
end)

return true