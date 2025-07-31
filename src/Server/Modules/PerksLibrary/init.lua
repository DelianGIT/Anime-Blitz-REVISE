--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)

--// MODULES
local ServerModules = ServerScriptService.Modules
local PlayerData = require(ServerModules.PlayerData)

local Storage = require(script.Storage)

--// VARIABLES
local Module = {}

--// MODULE FUNCTIONS
function Module.Update(player: Player)
	local playerData: PlayerData.Data = PlayerData.Get(player)
	
	local moveset = playerData.Moveset
	if not moveset then
		error(`Player {player} doesn't have moveset`)
	end

	local movesetName: string = moveset.Name
	local pack: Storage.Pack? = Storage[movesetName]
	if not pack then
		error(`{player}'s moveset {movesetName} doesn't have perks`)
	end

	local level: number = playerData.Level
	local perks: Storage.Perks? = pack[level]
	if not perks then
		return
	end

	--TODO: Add request for client
	local number: number = 1

	local perk: Storage.Perk? = perks[number]
	if not perk then
		error(`Perk {number} for level {level} doesn't exist in {player}'s moveset {movesetName}`)
	end

	local playerPerks: { [string]: true } = playerData.Perks
	local perkIdentifier: string = `{level}_{number}`
	if playerPerks[perkIdentifier] then
		error(`Player {player} already has perk {perkIdentifier} from moveset {movesetName}`)
	end

	PlayerData.Update(player, function()
		playerData = Sift.Dictionary.copy(playerData)
		playerData.Perks[perkIdentifier] = perk.Apply(player)
		return playerData
	end)
end

return Module