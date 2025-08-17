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
local DataStore = require(ServerModules.DataStore)
local CharacterController = require(ServerModules.CharacterController)
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
local Module = {}

--// MODULE FUNCTIONS
function Module.Apply(player: Player, unitVector: Vector3, params: Params)
	local character: Model? = player.Character
	if not character then
		warn(`{player}'s character doesn't exist`)
		return
	end

	local priority: number = params.Priority
	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
	local existingKnockback: Knockback? = tempData.Knockback
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
			tempData = DataStore.GetTemporaryData(player)
			local currentKnockback: Knockback? = tempData.Knockback
			if currentKnockback and currentKnockback.StartTimestamp == startTimestamp then
				Module.Cancel(player)
			end
		end)
	end

	tempData = Sift.Dictionary.set(tempData, "Knockback", {
		StartTimestamp = startTimestamp,
		Priority = priority,
	})
	DataStore.UpdateTemporaryData(player, tempData)

	Apply.sendTo({
		UnitVector = unitVector,
		Params = params
	}, player)
end

function Module.Cancel(player: Player)
	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
	local knockback: Knockback? = tempData.Knockback
	if not knockback then
		return
	end

	tempData = Sift.Dictionary.set(tempData, "Knockback", nil)
	DataStore.UpdateTemporaryData(player, tempData)

	BodyMoversController.Destroy(player, "Knockback", "LinearVelocity")

	Cancel.sendTo(nil, player)
end

--// EVENTS
Charm.observe(CharacterController.Atom :: any, function(_, player: Player)
	return function()
		local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
		tempData = Sift.Dictionary.set(tempData, "Knockback", nil)
		DataStore.UpdateTemporaryData(player, tempData)
	end
end)

return Module