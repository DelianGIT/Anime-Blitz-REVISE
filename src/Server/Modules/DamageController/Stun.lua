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
local HumanoidChanger = require(ServerModules.CharacterController.HumanoidChanger)
local PlayerData = require(ServerModules.PlayerData)

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
local stunAtom = PlayerData.Atoms.Stun

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
			local currentStun: Stun? = stunAtom()[player]
			if currentStun and currentStun.StartTimestamp == startTimestamp then
				Module.Cancel(player)
			end
		end)
	end

	stunAtom(function(state)
		return Sift.Dictionary.set(state, player, {
			WalkSpeed = walkSpeed,
			JumpPower = jumpPower,
			StartTimestamp = startTimestamp,
		})
	end)

	Apply.sendTo(params, player)
end

function Module.Cancel(player: Player): ()
	local stun: Stun? = stunAtom()[player]
	if not stun then
		return
	end

	local walkSpeed: number? = stun.WalkSpeed
	local jumpPower: number? = stun.JumpPower
	if jumpPower or walkSpeed then
		HumanoidChanger.Cancel(player, "Stun")
	end

	local state = stunAtom()
	state = Sift.Dictionary.removeKey(state, player)
	stunAtom(state)

	Cancel.sendTo(nil, player)
end

--// EVENTS
Charm.observe(PlayerData.Atoms.Character :: any, function(_, player: Player)
	return function()
		local state = stunAtom()
		state = Sift.Dictionary.removeKey(state, player)
		stunAtom(state)
	end
end)

return Module