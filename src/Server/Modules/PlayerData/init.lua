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

--// VARIABLES
local inProcess: { [Player]: true } = {}

--// EVENTS
Players.PlayerAdded:Connect(function(player: Player)
	if inProcess[player] then
		player:Kick("Error while loading data")
	end
	inProcess[player] = true
	
	PersistentDataStore:loadAsync(player)

	for name, value in pairs(AtomsDefaultValues :: any) do
		(Atoms :: any)[name](function(state)
			if typeof(value) == "table" then
				value = Sift.Dictionary.copyDeep(value)
			end
			
			return Sift.Dictionary.set(state, player, value)
		end)
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	if not inProcess[player] then
		return
	end

	PersistentDataStore:unloadAsync(player)

	for _, atom in pairs(Atoms :: any) do
		atom(function(state)
			return Sift.Dictionary.removeKey(state, player)
		end)
	end

	inProcess[player] = nil
end)

return {
	Atoms = Atoms,
	PersistentDataStore = PersistentDataStore
}