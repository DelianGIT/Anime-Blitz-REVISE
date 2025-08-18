--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)
local Charm = require(Packages.Charm)

--// MODULES
local ServerModules = ServerScriptService.Modules
local PlayerData = require(ServerModules.PlayerData)
local BodyMoversController = require(ServerModules.CharacterController.BodyMoversController)

--// REMOTE EVENTS
local RemoteEvents = require(ReplicatedStorage.RemoteEvents.Knockback)
local Apply = RemoteEvents.Apply
local Cancel = RemoteEvents.Cancel

--// TYPES
export type Params = {
	Priority: number,
	Velocity: number,
	Duration: number?,
	FromPoint: boolean?,
}
type Knockback = {
	Priority: number,
	StartTimestamp: number?,
}

--// VARIABLES
local knockbackAtom = PlayerData.Atoms.Knockback

local Module = {}

--// MODULE FUNCTIONS
function Module.Apply(player: Player, unitVector: Vector3, params: Params)
	local character: Model? = player.Character
	if not character then
		warn(`{player}'s character doesn't exist`)
		return
	end

	local priority: number = params.Priority
	local existingKnockback: Knockback? = knockbackAtom()[player]
	if existingKnockback and existingKnockback.Priority > priority then
		warn(`Exists knockback with higher priority: {existingKnockback.Priority} > {priority}`)
		return
	end

	BodyMoversController.Create(player, "Knockback", "LinearVelocity", {
		Priority = priority
	}, true)

	local startTimestamp: number?
	local duration: number? = params.Duration
	if duration then
		startTimestamp = os.clock()

		task.delay(duration, function()
			local currentKnockback: Knockback? = knockbackAtom()[player]
			if currentKnockback and currentKnockback.StartTimestamp == startTimestamp then
				Module.Cancel(player)
			end
		end)
	end

	knockbackAtom(function(state)
		return Sift.Dictionary.set(state, player, {
			StartTimestamp = startTimestamp,
			Priority = priority,
		})
	end)

	Apply.sendTo({
		UnitVector = unitVector,
		Params = params
	}, player)
end

function Module.Cancel(player: Player)
	local knockback: Knockback? = knockbackAtom()[player]
	if not knockback then
		return
	end

	local state = knockbackAtom()
	state = Sift.Dictionary.removeKey(state, player)
	knockbackAtom(state)

	BodyMoversController.Destroy(player, "Knockback", "LinearVelocity")

	Cancel.sendTo(nil, player)
end

--// EVENTS
Charm.observe(PlayerData.Atoms.Character :: any, function(_, player: Player)
	return function()
		local state = knockbackAtom()
		state = Sift.Dictionary.removeKey(state, player)
		knockbackAtom(state)
	end
end)

return Module