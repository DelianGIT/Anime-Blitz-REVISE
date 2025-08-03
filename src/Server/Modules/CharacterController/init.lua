--!strict
--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Charm = require(Packages.Charm)
local Sift = require(Packages.Sift)

--// MODULES
local ServerModules = ServerScriptService.Modules
local PlayerData = require(ServerModules.PlayerData)

local SharedModules = ReplicatedStorage.Modules
local Utility = require(SharedModules.Utility)

local HumanoidChanger = require(script.HumanoidChanger)
local BodyMoversController = require(script.BodyMoversController)

--// CONSTANTS
local DEFAULT_SPAWN_POINT = workspace.SpawnPoint

local SPAWN_OFFSET = CFrame.new(0, 3, 0)

--// VARIABLES
local charactersFolder = workspace.Living.Players

local assetsFolder = ReplicatedStorage.Assets.Characters

local atom: Charm.Atom<{ [Player]: Model }> = Charm.atom({})

local Module = {}

--// FUNCTIONS
local function applyStats(humanoid: Humanoid, stats): ()
	local health: number = stats.Health
	humanoid.MaxHealth = health
	humanoid.Health = health
end

local function buildDefaultCharacter(player: Player, spawnCFrame: CFrame): (Model, Humanoid)
	player:LoadCharacter()

	local character: Model = player.Character :: Model
	character.Archivable = true
	RunService.Heartbeat:Wait()
	character:PivotTo(spawnCFrame)
	character.Parent = charactersFolder

	return character, (character :: any).Humanoid
end

local function buildCustomCharacter(characterName: string, player: Player, spawnCFrame: CFrame): (Model, Humanoid)
	local characterAssetsFolder = assetsFolder:FindFirstChild(characterName)
	if not characterAssetsFolder then
		warn(`Can't find {characterName} assets for {player}`)
		return buildDefaultCharacter(player, spawnCFrame)
	end

	local model: Model? = characterAssetsFolder:FindFirstChild("Character") :: Model
	if not model then
		warn(`Can't find {characterName} character model for {player}`)
		return buildDefaultCharacter(player, spawnCFrame)
	end

	local character: Model = Utility.CloneInstance(model, charactersFolder, spawnCFrame)
	character.Name = player.Name
	player.Character = character
	return character, (character :: any).Humanoid
end

local function onDied(player: Player): ()
	HumanoidChanger._ClearChanges(player)
	BodyMoversController._DestroyBodyMovers(player)
	Module.Build(player)
end

--// MODULE PROPERTIES
Module.Atom = atom

--// MODULE FUNCTIONS
function Module.Build(player: Player): ()
	local existingCharacter: Model? = player.Character
	if existingCharacter then
		existingCharacter:Destroy()
		
		atom(function(state: { [Player]: Model })
			return Sift.Dictionary.removeKey(state, player)
		end)
	end

	local playerData: PlayerData.Data = PlayerData.Get(player)

	local spawnPoint: BasePart = playerData.SpawnPoint or DEFAULT_SPAWN_POINT
	local spawnCFrame: CFrame = spawnPoint.CFrame * SPAWN_OFFSET

	local newCharacter: Model, humanoid: Humanoid
	local characterData = playerData.CharacterData
	if not characterData then
		newCharacter, humanoid = buildDefaultCharacter(player, spawnCFrame)
	else
		newCharacter, humanoid = buildCustomCharacter(characterData.Name, player, spawnCFrame)
		applyStats(humanoid, characterData.Stats)
	end

	atom(function(state: { [Player]: Model })
		return Sift.Dictionary.set(state, player, newCharacter)
	end)

	local died: RBXScriptConnection, ancestryChanged: RBXScriptConnection
	died = humanoid.Died:Once(function()
		ancestryChanged:Disconnect()
		onDied(player)
	end)
	ancestryChanged = newCharacter.AncestryChanged:Once(function()
		died:Disconnect()
		if player.Parent == Players then
			onDied(player :: any)
		end
	end)
end

return Module