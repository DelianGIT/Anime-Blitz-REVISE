--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// MODULES
local ServerModules = ServerScriptService.Modules
local PlayerData = require(ServerModules.PlayerData)

--// REMOTE EVENTS
local RemoteEvents = ReplicatedStorage.RemoteEvents
local RemoteEvent = require(RemoteEvents.Vfx).Cast

--// TYPES
type Identifier = {
	Pack: string,
	Vfx: string,
	Function: string?,
}

--// CONSTANTS
local RENDER_DISTANCE = 1024

--// VARIABLES
local Module = {}

--// FUNCTIONS
local function canCast(player: Player, origin: Vector3?): boolean
	if not player.Character or (origin and player:DistanceFromCharacter(origin) > RENDER_DISTANCE) then
		return false
	else
		return true
	end
end

--// MODULE FUNCTIONS
function Module.Cast(player: Player, caster: Model, identifier: Identifier, origin: Vector3?, data: any?)
	if PlayerData.IsLoaded(player) and canCast(player, origin) then
		RemoteEvent.sendTo({
			Caster = caster,
			Identifier = identifier,
			Data = data,
			Timestamp = workspace:GetServerTimeNow()
		}, player)
	end
end

function Module.CastForAll(player: Player, caster: Model, identifier: Identifier, origin: Vector3?, data: any?, blacklist: { Player }?)
	local dataToSend = {
		Caster = caster,
		Identifier = identifier,
		Data = data,
		Timestamp = workspace:GetServerTimeNow()
	}

	for player, _ in pairs(PlayerData.Atom()) do
		if canCast(player, origin) then
			RemoteEvent.sendTo(dataToSend, player)
		end
	end
end

return Module