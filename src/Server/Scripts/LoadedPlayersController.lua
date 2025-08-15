--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)

--// MODULES
local ServerModules = ServerScriptService.Modules
local DataStore = require(ServerModules.DataStore)

--// REMOTE EVENTS
local RemoteEvents = require(ReplicatedStorage.RemoteEvents.ClientLoaded)
local RemoteEvent = RemoteEvents.Loaded

--// VARIABLES
local loadedPlayersAtom = DataStore.Atoms.LoadedPlayers

--// EVENTS
RemoteEvent.listen(function(_, player: Player?)
	if player then
		loadedPlayersAtom(function(state: { [Player]: boolean })
			return Sift.Set.add(state)
		end)
	end
end)

return true