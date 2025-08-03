--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Charm = require(ReplicatedStorage.Packages.Charm)
local Sift = require(Packages.Sift)

--// MODULES
local Store = require(script.Store)
local Syncer = require(script.Syncer)
local LoadedPlayersList = require(script.LoadedPlayersList)

--// TYPES
export type Data = Store.PlayerData

--// VARIABLES
-- local dataStore = Store.DataStore
local atom: Store.PlayerDataAtom = Store.Atom

local Module = {}

--// MODULE PROPERTIES
Module.Atom = atom
Module.SharedAtoms = Syncer.SharedAtoms
Module.LoadedPlayersList = LoadedPlayersList

--// MODULE FUNCTIONS
-- function Module.GetPersistentData(player: Player): PersistentData
-- 	return dataStore:getAsync(player)
-- end

-- function Module.UpdatePersistentData(player: Player, transformFunction: (data: PersistentData) -> boolean): ()
-- 	dataStore:updateAsync(player, transformFunction)
-- end

function Module.Get(player: Player): Data
	return Charm.peek(atom :: any)[player]
end

function Module.Update(player: Player, updateFunc: () -> (Data?)): ()
	atom(function(data: Store.PlayerDataMap)
		local nextPlayerData: Data? = updateFunc()
		if nextPlayerData then
			data = table.clone(data)
			data[player] = nextPlayerData
			return Sift.Dictionary.set(data, player, nextPlayerData)
		else
			return data
		end
	end)
end

function Module.IsLoaded(player: Player): boolean
	if Module.Get(player) then
		return true
	else
		return false
	end
end

return Module
