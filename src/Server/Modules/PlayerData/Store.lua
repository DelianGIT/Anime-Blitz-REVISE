--!strict
--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)
local Lyra = require(Packages.Lyra)
local Charm = require(Packages.Charm)

--// MODULES
local PersistentDataTemplate = require(script.Parent.PersistentDataTemplate)
local PlayerDataTemplate = require(script.Parent.PlayerDataTemplate)

--// TYPES
export type PersistentData = typeof(PersistentDataTemplate.Template)
export type PlayerData = PlayerDataTemplate.Data
export type PlayerDataMap = { [Player]: PlayerData }
export type PlayerDataAtom = Charm.Atom<PlayerDataMap>

--// VARIABLES
local loadedPlayersList: { Player } = {}
local Module = {}

--// SETTING UP PERSISTENT DATA STORE
local dataStore = Lyra.createPlayerStore({
	name = "PlayerData",
	template = PersistentDataTemplate.Template,
	schema = PersistentDataTemplate.Schema,
} :: any)

--// SETTING UP ATOMS
local atom: PlayerDataAtom = Charm.atom({})

--// MODULE PROPERTIES
Module.Atom = atom
Module.DataStore = dataStore
Module.LoadedPlayersList = loadedPlayersList

--// EVENTS
Players.PlayerAdded:Connect(function(player: Player)
	dataStore:loadAsync(player)
	
	atom(function(data: PlayerDataMap)
		local nextData: PlayerDataMap = Sift.Dictionary.copy(data)
		nextData[player] = Sift.Dictionary.copyDeep(PlayerDataTemplate)
		return nextData
	end)

	table.insert(loadedPlayersList, player)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	dataStore:unloadAsync(player)

	atom(function(data: PlayerDataMap)
		local nextData: PlayerDataMap = Sift.Dictionary.copy(data)
		nextData[player] = nil
		return nextData
	end)

	table.remove(loadedPlayersList, table.find(loadedPlayersList, player))
end)

game:BindToClose(function()
	dataStore:closeAsync()
end)

return Module
