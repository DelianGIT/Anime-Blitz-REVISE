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

local Types = require(script.Types)
local Controller = require(script.Controller)
local Storage = require(script.Storage)
local Cooldown = require(script.Controller.Cooldown)

--// REMOTE EVENTS
local RemoteEvents = require(ReplicatedStorage.RemoteEvents.Moveset)
local Give = RemoteEvents.Give
local Take = RemoteEvents.Take

--// TYPES
type Moveset = Types.Moveset
type MoveData = Types.MoveData
type Moves = Types.Moves
type Cooldown = Types.Cooldown
type CooldownData = Types.CooldownData

--// VARIABLES
local movesetAtom = PlayerData.Atoms.Moveset

local Module = {}

--// MODULE FUNCTIONS
function Module.Give(player: Player, name: string): ()
	local moveset: Moveset? = movesetAtom()[player]
	if moveset then
		warn(`Player {player.Name} already has moveset {name}`)
		return
	end

	local storedMoves: Moves = Storage[name]
	if not storedMoves then
		warn(`Moveset {name} doesn't exist for player {player}`)
		return
	end

	local moves: Moves = {}
	for moveName, move in pairs(storedMoves) do
		local data: MoveData = Sift.Dictionary.copyDeep(move.Data)
		moves[moveName] = {
			Data = data,
			Functions = move.Functions,
		}
	end

	local state = movesetAtom()
	state = Sift.Dictionary.set(state, player, {
		Name = name,
		Moves = moves,
		Cooldowns = Cooldown.Create(moves)
	})
	movesetAtom(state :: { [Player]: Moveset })

	Give.sendTo(name, player)
end

function Module.TakeMoveset(player: Player): ()
	local moveset: Moveset? = movesetAtom()[player]
	if not moveset then
		warn(`Player {player.Name} doesn't have moveset`)
		return
	end

	Controller.Cancel(player, true)

	local state = movesetAtom()
	state = Sift.Dictionary.removeKey(state, player)
	movesetAtom(state)

	Take.sendTo(nil, player)
end

return Module