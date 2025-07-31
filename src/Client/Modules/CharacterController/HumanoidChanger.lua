--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)

--// REMOTE EVENTS
local RemoteEvents = require(ReplicatedStorage.RemoteEvents.HumanoidChanger)
local ChangeRemoteEvent = RemoteEvents.Change
local CancelRemoteEvent = RemoteEvents.Cancel

--// TYPES
type Params = {
	Priority: number,
	Duration: number?,
	TweenInfo: TweenInfo?,
}
type Change = {
	Properties: { [string]: any },
	Priority: number,
	StartTimestamp: number?,
	Tween: Tween?,
}

--// CONSTANTS
local BASE_VALUES = {
	WalkSpeed = 32,
	JumpPower = 35,
}

--// VARIABLES
local allChanges: { [string]: Change } = {}
local Module = {}

local humanoid: Humanoid?

--// FUNCTIONS
local function getPrioritizedChange(): (Change?, number)
	local prioritizedChange: Change?
	local highestPriority: number = 0

	for _, change: Change in pairs(allChanges) do
		local priority: number = change.Priority
		if priority > highestPriority then
			prioritizedChange, highestPriority = change, priority
		end
	end

	return prioritizedChange, highestPriority
end

--// MODULE FUNCTIONS
function Module.Change(name: string, properties: { [string]: any }, params: Params): ()
	if not humanoid then
		warn(`Humanoid doesn't exist for {name}: {properties}`)
		return
	end

	local priority: number = params.Priority
	local existingChange: Change? = allChanges[name]
	if existingChange and existingChange.Priority > priority then
		warn(`Change {name} exists with higher priority`)
		return
	end

	local tween: Tween?
	local prioritizedChange: Change?, highestPriority: number = getPrioritizedChange()
	if priority >= highestPriority then
		if prioritizedChange then
			tween = prioritizedChange.Tween
			if tween then
				tween:Pause()
			end
		end

		local tweenInfo: TweenInfo? = params.TweenInfo
		if tweenInfo then
			tween = TweenService:Create(humanoid, tweenInfo, properties)
			tween:Play()
		else
			for propertyName, value in pairs(properties) do
				(humanoid :: any)[propertyName] = value
			end
		end
	end

	local startTimestamp: number?
	local duration: number? = params.Duration
	if duration then
		startTimestamp = os.clock()

		task.delay(duration, function()
			local currentChange: Change = allChanges[name]
			if currentChange and currentChange.StartTimestamp == startTimestamp then
				Module.Cancel(name)
			end
		end)
	end

	allChanges[name] = {
		Properties = Sift.Dictionary.copyDeep(properties),
		Priority = priority,
		StartTimestamp = startTimestamp,
		Tween = tween,
	}
end

function Module.Cancel(name: string): ()
	local change: Change? = allChanges[name]
	if not change then
		warn(`Change {name} doesn't exist`)
		return
	end

	local wasPrioritized: boolean
	local prioritizedChange: Change?, _ = getPrioritizedChange()
	if prioritizedChange == change then
		wasPrioritized = true
	end

	allChanges[name] = nil

	local tween: Tween? = change.Tween
	if tween then
		tween:Pause()
	end

	if not humanoid or not wasPrioritized then
		return
	end

	prioritizedChange, _ = getPrioritizedChange()
	if prioritizedChange then
		tween = prioritizedChange.Tween
		if tween then
			tween:Play()
		else
			for propertyName, value in pairs(prioritizedChange.Properties) do
				(humanoid :: any)[propertyName] = value
			end
		end
	else
		for propertyName, _ in pairs(change.Properties) do
			(humanoid :: any)[propertyName] = BASE_VALUES[propertyName]
		end
	end
end

function Module.SetHumanoid(_humanoid: Humanoid): ()
	humanoid = _humanoid

	if humanoid then
		for propertyName, value in pairs(BASE_VALUES) do
			(humanoid :: any)[propertyName] = value
		end
	else
		allChanges = {}
	end
end

--// EVENTS
ChangeRemoteEvent.listen(function(data)
	Module.Change(data.Name, data.Properties, data.Params)
end)

CancelRemoteEvent.listen(function(data)
	Module.Cancel(data)
end)

return Module