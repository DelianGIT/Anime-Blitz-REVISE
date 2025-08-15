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
local DataStore = require(ClientModules.DataStore)

--// TYPES
type Team = "A" | "B" | "B"

--// VARIABLES
local localPlayer: Player = Players.LocalPlayer
local localPlayerName: string = localPlayer.Name

local charactersFolder = workspace.Living.Players

local assetsFolder = ReplicatedStorage.Miscellaneous.TeamsHighlights
local greenHighlight: Highlight = assetsFolder.Green
local redHighlight: Highlight = assetsFolder.Red
local whiteHighlight: Highlight = assetsFolder.White

local temporaryDataAtom: DataStore.TemporaryDataAtom = DataStore.TemporaryDataAtom
local teamAAtom: DataStore.Atom<boolean> = DataStore.SharedAtoms.TeamA
local teamBAtom: DataStore.Atom<boolean> = DataStore.SharedAtoms.TeamB

local myTeam: Team

--// FUNCTIONS
local function getCharacterTeam(character: Model): Team?
	local targetName: string = character.Name
	for player, _ in pairs(teamAAtom()) do
		if player.Name == targetName then
			return "A"
		end
	end
	for player, _ in pairs(teamBAtom()) do
		if player.Name == targetName then
			return "B"
		end
	end
	return nil
end

local function addHighlight(character: Model): ()
	local team: Team? = getCharacterTeam(character :: Model)
	if not team then
		return
	end

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
Charm.subscribe(function()
	return temporaryDataAtom().Team
end, function(team: Team)
	myTeam = team

	for _, character in ipairs(charactersFolder:GetChildren()) do
		if localPlayerName ~= character.Name then
			addHighlight(character :: Model)
		end
	end
end)

--// OBSERVERS
charactersFolder.ChildAdded:Connect(function(character: Instance)
	if localPlayerName ~= character.Name or not character:IsA("Model") then
		addHighlight(character :: any)
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