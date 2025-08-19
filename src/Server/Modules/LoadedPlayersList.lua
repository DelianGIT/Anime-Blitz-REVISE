--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Charm = require(Packages.Charm)
local Sift = require(Packages.Sift)

--// MODULES
local ServerModules = ServerScriptService.Modules
local PlayerData = require(ServerModules.PlayerData)
local CharacterController = require(ServerModules.CharacterController)

--// REMOTE EVENTS
local RemoteEvents = require(ReplicatedStorage.RemoteEvents.ClientLoaded)
local RemoteEvent = RemoteEvents.Loaded

--// VARIABLES
local loadedAtom = PlayerData.Atoms.Loaded

local Module: { Player } = {}

--// EVENTS
RemoteEvent.listen(function(_, player: Player?)
	if player then
		loadedAtom(function(state: { [Player]: boolean })
			return Sift.Set.add(state, player)
		end)

		CharacterController.Build(player)
	end
end)

--// OBSERVERS
Charm.observe(loadedAtom :: any, function(_, player: Player)
	table.insert(Module, player)
	
	return function()
		table.remove(Module, table.find(Module, player))
	end
end)

return Module