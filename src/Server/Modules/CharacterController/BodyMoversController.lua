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

--// VARIABLES
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

	local playerData: PlayerData.Data = PlayerData.Get(player)
	local allBodyMovers: { [MoverType]: { [string]: BodyMover } } = playerData.BodyMovers :: any
	
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
			playerData = PlayerData.Get(player)
			allBodyMovers = playerData.BodyMovers :: any

			local currentMover: BodyMover = allBodyMovers[moverType][name]
			if currentMover and currentMover.StartTimestamp == startTimestamp then
				Module.Destroy(player, name, moverType)
			end
		end)
	end

	PlayerData.Update(player, function()
		bodyMovers = Sift.Dictionary.set(bodyMovers, name, {
			Priority = priority,
			StartTimestamp = startTimestamp,
		})

		allBodyMovers = Sift.Dictionary.set(allBodyMovers, moverType, bodyMovers)

		playerData = Sift.Dictionary.copy(playerData)
		playerData.BodyMovers = allBodyMovers :: any
		return playerData
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

	local playerData: PlayerData.Data = PlayerData.Get(player)
	local allBodyMovers: { [MoverType]: { [string]: BodyMover } } = playerData.BodyMovers :: any
	
	local bodyMovers: { [string]: BodyMover }? = allBodyMovers[moverType]
	if not bodyMovers then
		error(`Invalid {name} body mover type for {player}: {moverType}`)
	end

	PlayerData.Update(player, function()
		bodyMovers = Sift.Dictionary.removeKey(bodyMovers, name)

		allBodyMovers = Sift.Dictionary.set(allBodyMovers, moverType, bodyMovers)
		
		playerData = Sift.Dictionary.copy(playerData)
		playerData.BodyMovers = allBodyMovers :: any
		return playerData
	end)

	DestroyRemoteEvent.sendTo({
		Name = name,
		MoverType = moverType,
	}, player)
end

function Module._DestroyBodyMovers(player: Player): ()
	local playerData: PlayerData.Data = PlayerData.Get(player)
	local allBodyMovers: { [MoverType]: { [string]: BodyMover } } = playerData.BodyMovers :: any

	for _, bodyMovers in pairs(allBodyMovers) do
		table.clear(bodyMovers)
	end
end

return Module