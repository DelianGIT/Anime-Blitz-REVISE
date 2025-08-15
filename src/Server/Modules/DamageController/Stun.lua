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
local CharacterController = require(ServerModules.CharacterController)
local HumanoidChanger = require(ServerModules.CharacterController.HumanoidChanger)
local DataStore = require(ServerModules.DataStore)

--// REMOTE EVENTS
local RemoteEvents = require(ReplicatedStorage.RemoteEvents.Stun)
local Apply = RemoteEvents.Apply
local Cancel = RemoteEvents.Cancel

--// TYPES
export type Params = {
	Duration: number?,
	WalkSpeed: number?,
	JumpPower: number?,
}
type Stun = {
	WalkSpeed: number?,
	JumpPower: number?,
	StartTimestamp: number?,
}

--// VARIABLES
local Module = {}

--// MODULE FUNCTIONS
function Module.Apply(player: Player, params: Params): ()
	local character: Model? = player.Character
	if not character then
		warn(`{player}'s character doesn't exist`)
		return
	end

	local duration: number? = params.Duration
	local walkSpeed: number? = params.WalkSpeed
	local jumpPower: number? = params.JumpPower
	if walkSpeed or jumpPower then
		HumanoidChanger.Change(player, "Stun", {
			WalkSpeed = walkSpeed,
			JumpPower = jumpPower,
		}, {
			Priority = 2,
			Duration = duration,
		}, true)
	end

	local startTimestamp: number?
	if duration then
		startTimestamp = os.clock()

		task.delay(duration, function()
			local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
			local currentStun: Stun? = tempData.Stun
			if currentStun and currentStun.StartTimestamp == startTimestamp then
				Module.Cancel(player)
			end
		end)
	end

	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
	tempData.Stun = {
		WalkSpeed = walkSpeed,
		JumpPower = jumpPower,
		StartTimestamp = startTimestamp,
	}
	DataStore.UpdateTemporaryData(player, tempData)

	Apply.sendTo(params, player)
end

function Module.Cancel(player: Player): ()
	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
	local stun: Stun? = tempData.Stun
	if not stun then
		return
	end

	local walkSpeed: number? = stun.WalkSpeed
	local jumpPower: number? = stun.JumpPower
	if jumpPower or walkSpeed then
		HumanoidChanger.Cancel(player, "Stun")
	end

	tempData = Sift.Dictionary.copy(tempData)
	tempData.Stun = nil
	DataStore.UpdateTemporaryData(player, tempData)

	Cancel.sendTo(nil, player)
end

--// EVENTS
Charm.observe(CharacterController.Atom :: any, function(_, player: Player)
	return function()
		local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
		tempData = Sift.Dictionary.copy(tempData)
		tempData.Stun = nil
		DataStore.UpdateTemporaryData(player, tempData)
	end
end)

return Module