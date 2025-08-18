--!strict
--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)

--// MODULES
local PersistentDataStore = require(script.PersistentDataStore)
local Atoms = require(script.Atoms)
local AtomsDefaultValues = require(script.AtomsDefaultValues)
local SharedAtoms = require(script.SharedAtoms)
local SharedAtomsDefaultValues = require(script.SharedAtomsDefaultValues)
local Syncer = require(script.Syncer)

--// VARIABLES
local loadedDataPlayers: { [Player]: boolean } = {}

--// INITIALIZING ATOMS SYNCER
Syncer.Init(loadedDataPlayers)

--// FUNCTIONS
local function removePlayerFromAtoms(player: Player, atoms: any): ()
	for _, atom in pairs(atoms) do
		atom(function(state)
			return Sift.Dictionary.removeKey(state, player)
		end)
	end
end

local function setDefaultValues(player: Player, atoms: any, defaultValues: any): ()
	for name, value in pairs(defaultValues) do
		atoms[name](function(state)
			if typeof(value) == "table" then
				value = Sift.Dictionary.copyDeep(value)
			end
			
			return Sift.Dictionary.set(state, player, value)
		end)
	end
end

--// EVENTS
Players.PlayerAdded:Connect(function(player: Player)
	loadedDataPlayers[player] = false
	
	--PersistentDataStore:loadAsync(player)

	setDefaultValues(player, Atoms, AtomsDefaultValues)
	setDefaultValues(player, SharedAtoms, SharedAtomsDefaultValues)

	loadedDataPlayers[player] = true
end)

Players.PlayerRemoving:Connect(function(player: Player)
	--PersistentDataStore:unloadAsync(player)

	removePlayerFromAtoms(player, Atoms)
	removePlayerFromAtoms(player, SharedAtoms)

	loadedDataPlayers[player] = nil
end)

return {
	Atoms = Atoms,
	SharedAtoms = SharedAtoms,
	PersistentDataStore = PersistentDataStore
}