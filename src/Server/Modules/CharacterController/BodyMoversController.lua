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

-- // REMOTE EVENTS
local RemoteEvents = require(ReplicatedStorage.RemoteEvents.BodyMoversController)
local CreateRemoteEvent = RemoteEvents.Create
local DestroyRemoteEvent = RemoteEvents.Destroy

--// TYPES
type MoverType = "LinearVelocity"

type Params = {
	Priority: number,
	Duration: number?,
	MoverProperties: { [string]: any }?,
}
type BodyMover = {
	Priority: number,
	StartTimestamp: number?,
}
type AllBodyMovers = { [MoverType]: { [string]: BodyMover } }

--// VARIABLES
local bodyMoversAtom = PlayerData.Atoms.BodyMovers :: any

local Module = {}

--// MODULE FUNCTIONS
function Module.Create(player: Player, name: string, moverType: MoverType, params: Params): ()
	local character: Model? = player.Character
	if not character then
		error(`{player}'s character doesn't exist for {moverType}_{name}`)
	end

	local humanoidRootPart: Part? = character:FindFirstChild("HumanoidRootPart") :: Part?
	if not humanoidRootPart then
		error(`{player}'s HumanoidRootPart doesn't exist for {moverType}_{name}`)
	end

	local allBodyMovers: AllBodyMovers = bodyMoversAtom()[player]
	
	local bodyMovers: { [string]: BodyMover }? = allBodyMovers[moverType]
	if not bodyMovers then
		error(`Invalid {name} body mover type for {player}: {moverType}`)
	end

	local priority: number = params.Priority
	local existingMover: BodyMover? = bodyMovers[name]
	if existingMover and existingMover.Priority > priority then
		error(`{player} has body mover {moverType}_{name} with higher priority`)
	end

	local startTimestamp: number?
	local duration: number? = params.Duration
	if duration then
		startTimestamp = os.clock()

		task.delay(duration, function()
			allBodyMovers = bodyMoversAtom()[player]

			local currentMover: BodyMover = allBodyMovers[moverType][name]
			if currentMover and currentMover.StartTimestamp == startTimestamp then
				Module.Destroy(player, name, moverType)
			end
		end)
	end

	bodyMovers = Sift.Dictionary.set(bodyMovers, name, {
		Priority = priority,
		StartTimestamp = startTimestamp,
	})

	allBodyMovers = Sift.Dictionary.set(allBodyMovers, moverType, bodyMovers)
	bodyMoversAtom(function(state)
		return Sift.Dictionary.set(state, player, allBodyMovers)
	end)

	CreateRemoteEvent.sendTo({
		Name = name,
		MoverType = moverType,
		Params = params,
	}, player)
end

function Module.Destroy(player: Player, name: string, moverType: MoverType): ()
	local character: Model? = player.Character
	if not character then
		error(`{player}'s character doesn't exist for {moverType}_{name}`)
	end

	local humanoidRootPart: Part? = character:FindFirstChild("HumanoidRootPart") :: Part?
	if not humanoidRootPart then
		error(`{player}'s HumanoidRootPart doesn't exist for {moverType}_{name}`)
	end

	local allBodyMovers: { [MoverType]: { [string]: BodyMover } } = bodyMoversAtom()[player]
	
	local bodyMovers: { [string]: BodyMover }? = allBodyMovers[moverType]
	if not bodyMovers then
		error(`Invalid {name} body mover type for {player}: {moverType}`)
	end

	bodyMovers = Sift.Dictionary.removeKey(bodyMovers, name)

	allBodyMovers = Sift.Dictionary.set(allBodyMovers, moverType, bodyMovers)
	bodyMoversAtom(function(state)
		return Sift.Dictionary.set(state, player, allBodyMovers)
	end)

	DestroyRemoteEvent.sendTo({
		Name = name,
		MoverType = moverType,
	}, player)
end

function Module._DestroyBodyMovers(player: Player): ()
	bodyMoversAtom(function(state)
		local allBodyMovers: AllBodyMovers = state[player]
		for moverType, _ in pairs(allBodyMovers) do
			allBodyMovers = Sift.Dictionary.set(allBodyMovers, moverType, {})
		end
		return Sift.Dictionary.set(state, player, allBodyMovers)
	end)
end

return Module