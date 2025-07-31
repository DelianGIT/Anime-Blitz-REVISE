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
local Module = {}

--// MODULE FUNCTIONS
function Module.Change(player: Player, name: string, properties: { [string]: any }, params: Params): ()
	local character = player.Character
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
	local playerData: PlayerData.Data = PlayerData.Get(player)
	local allChanges: { [string]: Change } = playerData.HumanoidChanges
	local existingChange: Change? = allChanges[name]
	if existingChange and existingChange.Priority > priority then
		warn(`Change {name} exists with higher priority`)
		return
	end

	local startTimestamp: number?
	local duration: number? = params.Duration
	if duration then
		startTimestamp = os.clock()

		task.delay(duration, function()
			playerData = PlayerData.Get(player)
			local currentChange: Change = playerData.HumanoidChanges[name]
			if currentChange and currentChange.StartTimestamp == startTimestamp then
				Module.Cancel(player, name)
			end
		end)
	end

	PlayerData.Update(player, function()
		local change: Change = {
			Properties = Sift.Dictionary.copyDeep(properties),
			Priority = priority,
			StartTimestamp = startTimestamp
		}

		playerData = Sift.Dictionary.copy(playerData)
		playerData.HumanoidChanges = Sift.Dictionary.set(allChanges, name, change)
		return playerData
	end)

	ChangeRemoteEvent.sendTo({
		Name = name,
		Properties = properties,
		Params = params,
	}, player)
end

function Module.Cancel(player: Player, name: string): ()
	local playerData: PlayerData.Data = PlayerData.Get(player)
	local allChanges: { [string]: Change } = playerData.HumanoidChanges
	if not allChanges[name] then
		return
	end

	PlayerData.Update(player, function()
		playerData = Sift.Dictionary.copy(playerData)
		playerData.HumanoidChanges = Sift.Dictionary.removeKey(allChanges, name)
		return playerData
	end)

	CancelRemoteEvent.sendTo(name, player)
end

function Module._ClearChanges(player: Player): ()
	local playerData: PlayerData.Data = PlayerData.Get(player)
	PlayerData.Update(player, function()
		table.clear(playerData.HumanoidChanges)
		return playerData
	end)
end

return Module