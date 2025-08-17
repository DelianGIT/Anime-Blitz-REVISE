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

local Controller = require(script.Controller)
local Storage = require(script.Storage)
local Cooldown = require(script.Controller.Cooldown)

--// REMOTE EVENTS
local RemoteEvents = require(ReplicatedStorage.RemoteEvents.Moveset)
local Give = RemoteEvents.Give
local Take = RemoteEvents.Take

--// TYPES
type Moveset = {
	Name: string,
	Moves: Storage.Moves
}

--// VARIABLES
local Module = {}

--// MODULE FUNCTIONS
function Module.Give(player: Player, name: string): ()
	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)

	if tempData.Moveset then
		warn(`Player {player.Name} already has moveset {name}`)
		return
	end

	local storedMoves: Storage.Moves = Storage[name]
	if not storedMoves then
		warn(`Moveset {name} doesn't exist for player {player}`)
		return
	end

	local moves: Storage.Moves = {}
	for moveName, move in pairs(storedMoves) do
		local data = Sift.Dictionary.copyDeep(move.Data)
		moves[moveName] = {
			Data = data,
			Functions = move.Functions,
		}

		local cooldown = data.Cooldown
		if cooldown then
			Cooldown.Add(player, moveName, cooldown.Duration)
		end
	end

	tempData = Sift.Dictionary.set(tempData, "Moveset", {
		Name = name,
		Moves = moves
	})
	DataStore.UpdateTemporaryData(player, tempData)

	Give.sendTo(name, player)
end

function Module.TakeMoveset(player: Player): ()
	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
	local moveset: Moveset? = tempData.Moveset :: any
	if not moveset then
		warn(`Player {player.Name} doesn't have moveset`)
		return
	end

	Controller.Cancel(player, true)

	Cooldown.RemoveAll(player)

	tempData = Sift.Dictionary.removeKey(tempData, "Moveset")
	DataStore.UpdateTemporaryData(player, tempData)

	Take.sendTo(nil, player)
end

return Module