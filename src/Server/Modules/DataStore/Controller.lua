--!strict
--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Lyra = require(Packages.Lyra)
local Sift = require(Packages.Sift)

--// MODULES
local Atoms = require(script.Parent.Atoms)
local PersistentDataTemplate = require(script.Parent.PersistentDataTemplate)
local TemporaryDataTemplate = require(script.Parent.TemporaryDataTemplate)

--// TYPES
type TemporaryData = TemporaryDataTemplate.Data

--// VARIABLES
local persistentDataStore = Lyra.createPlayerStore({
	name = "PlayerData",
	template = PersistentDataTemplate.Template,
	schema = PersistentDataTemplate.Schema
} :: any)

local temporaryDataAtom: Atoms.TemporaryDataAtom = Atoms.TemporaryDataAtom

local atoms = Atoms.Atoms
local sharedAtoms = Atoms.SharedAtoms
local inProcess: { [Player]: true } = {}
local Module = {}

--// FUNCTIONS
local function removePlayerFromAtoms(player: Player, atomsTable: any): ()
	for _, atom in pairs(atomsTable) do
		atom(function(state: { [Player]: any })
			if Sift.Dictionary.has(state, player) then
				return Sift.Dictionary.removeKey(state, player)
			else
				return state
			end
		end)
	end
end

--// MODULE PROPERTIES
Module.PersistentDataStore = persistentDataStore

--// EVENTS
Players.PlayerAdded:Connect(function(player: Player)
	if inProcess[player] then
		player:Kick("Error while loading data")
	end
	inProcess[player] = true

	persistentDataStore:loadAsync(player)

	temporaryDataAtom(function(state: { [Player]: TemporaryData })
		local newData: TemporaryData = Sift.Dictionary.copyDeep(TemporaryDataTemplate)
		return Sift.Dictionary.set(state, player, newData)
	end)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	if not inProcess[player] then
		return
	end

	persistentDataStore:unloadAsync(player)

	temporaryDataAtom(function(state: { [Player]: TemporaryData })
		return Sift.Dictionary.removeKey(state, player)
	end)

	removePlayerFromAtoms(player, atoms)
	removePlayerFromAtoms(player, sharedAtoms)

	inProcess[player] = nil
end)

game:BindToClose(function()
	persistentDataStore:closeAsync()
end)

return Module
