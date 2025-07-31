--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// REMOTE EVENTS
local RemoteEvents = require(ReplicatedStorage.RemoteEvents.BodyMoversController)
local CreateRemoteEvent = RemoteEvents.Create
local DestroyRemoteEvent = RemoteEvents.Destroy

--// TYPES
type MoverType = "LinearVelocity"
type MoverInstance = LinearVelocity

type Params = {
	Priority: number,
	Duration: number?,
	MoverProperties: { [string]: any }?,
}
type BodyMover = {
	Instance: MoverInstance,
	Priority: number,
	StartTimestamp: number?,
}

--// VARIABLES
local templatesFolder = ReplicatedStorage.Miscellaneous.BodyMovers

local allBodyMovers: { [MoverType]: { [string]: BodyMover } } = {
	LinearVelocity = {}
}
local Module = {}

local rootAttachment: Attachment?, humanoidRootPart: BasePart?

--// FUNCTIONS
local function getPrioritizedMover(movers: { [string]: BodyMover }): (BodyMover?, number)
	local prioritizedMover: BodyMover?
	local highestPriority: number = 0

	for _, mover in pairs(movers) do
		local priority: number = mover.Priority
		if priority > highestPriority then
			prioritizedMover, highestPriority = mover, priority
		end
	end

	return prioritizedMover, highestPriority
end

--// MODULE FUNCTIONS
function Module.Create(name: string, moverType: MoverType, params: Params): MoverInstance
	if not rootAttachment then
		error(`Root attachment doesn't exist for {moverType}_{name}`)
	end

	if not humanoidRootPart then
		error("HumanoidRootPart doesn't exist")
	end

	local bodyMovers: { [string]: BodyMover }? = allBodyMovers[moverType]
	if not bodyMovers then
		error(`Invalid body mover type: {moverType}`)
	end

	local priority: number = params.Priority
	local existingMover: BodyMover? = bodyMovers[name]
	if existingMover and existingMover.Priority > priority then
		error(`Exists body mover {moverType}_{name} with higher priority`)
	end

	local moverInstance: MoverInstance?
	if existingMover then
		moverInstance = existingMover.Instance
	else
		moverInstance = (templatesFolder :: any)[moverType]:Clone()
		moverInstance.Attachment = rootAttachment

		local properties: { [string]: any }? = params.MoverProperties
		if properties then
			for key: string, value: any in pairs(properties) do
				(moverInstance :: any)[key] = value
			end
		end

		moverInstance.Parent = humanoidRootPart
	end

	local prioritizedMover: BodyMover?, moverPriority: number = getPrioritizedMover(bodyMovers)
	if prioritizedMover then
		if priority >= moverPriority then
			prioritizedMover.Instance.Enabled = false
			moverInstance.Enabled = true
		else
			moverInstance.Enabled = false
		end
	end

	local startTimestamp: number?
	local duration: number? = params.Duration
	if duration then
		startTimestamp = os.clock()

		task.delay(duration, function()
			local currentMover: BodyMover = bodyMovers[name]
			if currentMover and currentMover.StartTimestamp == startTimestamp then
				Module.Destroy(name, moverType)
			end
		end)
	end

	bodyMovers[name] = {
		Instance = moverInstance,
		Priority = priority,
		StartTimestamp = startTimestamp,
	}

	return moverInstance
end

function Module.Destroy(name: string, moverType: MoverType): ()
	local bodyMovers: { [string]: BodyMover } = allBodyMovers[moverType]
	local bodyMover: BodyMover? = bodyMovers[name]
	if not bodyMover then
		warn(`Body mover {moverType}_{name} doesn't exist`)
		return
	end
	bodyMovers[name] = nil

	bodyMover.Instance:Destroy()

	local prioritizedMover: BodyMover?, _ = getPrioritizedMover(bodyMovers)
	if prioritizedMover then
		prioritizedMover.Instance.Enabled = true
	end
end

function Module.SetHumanoidRootPart(_humanoidRootPart: BasePart?): ()
	humanoidRootPart = _humanoidRootPart

	if humanoidRootPart then
		rootAttachment = Instance.new("Attachment")
		rootAttachment.Name = "BodyMoversAttachment"
		rootAttachment.Parent = humanoidRootPart
	else
		(rootAttachment :: Attachment):Destroy()
		rootAttachment = nil

		for _, bodyMovers in pairs(allBodyMovers) do
			for name, bodyMover in pairs(bodyMovers) do
				bodyMover.Instance:Destroy()
				bodyMovers[name] = nil
			end
		end
	end
end

--// EVENTS
CreateRemoteEvent.listen(function(data)
	Module.Create(data.Name, data.MoverType, data.Params)
end)

DestroyRemoteEvent.listen(function(data)
	Module.Destroy(data.Name, data.MoverType)
end)

return Module