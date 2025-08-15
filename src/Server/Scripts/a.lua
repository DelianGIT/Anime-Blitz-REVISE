--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Charm = require(Packages.Charm)

--// MODULES
local ServerModules = ServerScriptService.Modules
local DataStore = require(ServerModules.DataStore)
local CharacterController = require(ServerModules.CharacterController)

--// OBSERVER
Charm.observe(DataStore.Atoms.LoadedPlayers :: any, function(_, player: Player)
	CharacterController.Build(player)
end)

return true