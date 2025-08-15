--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)
local Charm = require(Packages.Charm)

--// MODULES
local Atoms = require(script.Atoms)
local PersistentDataTemplate = require(script.PersistentDataTemplate)
local TemporaryDataTemplate = require(script.TemporaryDataTemplate)
local Controller = require(script.Controller)

--// TYPES
export type PersistentData = PersistentDataTemplate.Data
export type TemporaryData = TemporaryDataTemplate.Data
export type TemporaryDataAtom = Atoms.TemporaryDataAtom
export type Atom<T> = Atoms.Atom<T>

--// VARIABLES
local persistentDataStore = Controller.PersistentDataStore

local temporaryDataAtom: Atoms.TemporaryDataAtom = Atoms.TemporaryDataAtom

local loadedPlayersList: { Player } = {}
local Module = {}

--// REQUIRING SYNCER
require(script.Syncer)

--// MODULE PROPERTIES
Module.TemporaryDataAtom = temporaryDataAtom
Module.Atoms = Atoms.Atoms
Module.SharedAtoms = Atoms.SharedAtoms
Module.LoadedPlayers = loadedPlayersList

--// MODULE FUNCTIONS
function Module.GetPersistentData(player: Player): PersistentData
	return persistentDataStore:getAsync(player)
end

function Module.UpdatePersistentData(player: Player, updateFunc: (PersistentData) -> boolean): ()
	persistentDataStore:updateAsync(player, updateFunc)
end

function Module.GetTemporaryData(player: Player): TemporaryData
	return temporaryDataAtom()[player]
end

function Module.UpdateTemporaryData(player: Player, tempData: TemporaryData): ()
	temporaryDataAtom(function(state: { [Player]: TemporaryData })
		return Sift.Dictionary.set(state, player, tempData)
	end)
end

function Module.IsLoaded(player: Player): boolean
	if table.find(loadedPlayersList, player) then
		return true
	else
		return false
	end
end

--// OBSERVER
Charm.observe(Atoms.Atoms.LoadedPlayers :: any, function(_, player: Player)
	table.insert(loadedPlayersList, player)
	return function()
		table.remove(loadedPlayersList, table.find(loadedPlayersList, player))	
	end
end)

return Module