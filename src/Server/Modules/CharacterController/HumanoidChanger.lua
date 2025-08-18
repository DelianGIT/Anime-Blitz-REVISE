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
	StartTimestamp: number?
}

--// VARIABLES
local humanoidChangesAtom = PlayerData.Atoms.HumanoidChanges

local Module = {}

--// MODULE FUNCTIONS
function Module.Change(player: Player, name: string, properties: { [string]: any }, params: Params): ()
	local character: Model? = player.Character
	if not character then
		warn(`{player}'s character doesn't exist for {name}: {properties}`)
		return
	end

	local humanoid: Humanoid? = character:FindFirstChild("Humanoid") :: Humanoid?
	if not humanoid then
		warn(`{player}'s humanoid doesn't exist for {name}: {properties}`)
		return
	end

	local priority: number = params.Priority
	local allChanges: { [string]: Change } = humanoidChangesAtom()[player]
	local existingChange: Change? = allChanges[name]
	if existingChange and existingChange.Priority > priority then
		warn(`Change {name} exists with higher priority: {existingChange.Priority} > {priority}`)
		return
	end

	local startTimestamp: number?
	local duration: number? = params.Duration
	if duration then
		startTimestamp = os.clock()

		task.delay(duration, function()
			allChanges = humanoidChangesAtom()[player]

			local currentChange: Change = allChanges[name]
			if currentChange and currentChange.StartTimestamp == startTimestamp then
				Module.Cancel(player, name)
			end
		end)
	end

	local change: Change = {
		Properties = Sift.Dictionary.copyDeep(properties),
		Priority = priority,
		StartTimestamp = startTimestamp
	}

	allChanges = Sift.Dictionary.set(allChanges, name, change)
	humanoidChangesAtom(function(state)
		return Sift.Dictionary.set(state, player, allChanges)
	end)

	ChangeRemoteEvent.sendTo({
		Name = name,
		Properties = properties,
		Params = params,
	}, player)
end

function Module.Cancel(player: Player, name: string): ()
	local allChanges: { [string]: Change } = humanoidChangesAtom()[player]
	if not allChanges[name] then
		return
	end

	allChanges = Sift.Dictionary.removeKey(allChanges, name)
	humanoidChangesAtom(function(state)
		return Sift.Dictionary.set(state, player, allChanges)
	end)

	CancelRemoteEvent.sendTo(name, player)
end

function Module._ClearChanges(player: Player): ()
	local state = humanoidChangesAtom()[player]
	state = Sift.Dictionary.set(state, player, {})
	humanoidChangesAtom(state :: any)
end

return Module