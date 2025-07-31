--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Charm = require(Packages.Charm)

--// MODULES
local ServerModules = ServerScriptService.Modules
local Teams = require(ServerModules.Teams)

--// VARIABLES
local teamADevices: { [Player]: AudioDeviceInput } = {}
local teamBDevices: { [Player]: AudioDeviceInput } = {}

local teamAUserIds: { number } = {}
local teamBUserIds: { number } = {}

local Module = {}

local muted: boolean = false

--// FUNCTIONS
local function updateDevices(devices: { [Player]: AudioDeviceInput }, userIds: { number })
	for _, device in pairs(devices) do
		device:SetUserIdAccessList(userIds)
	end
end

--// MODULE FUNCTIONS
function Module.ToggleMute(toggle: boolean): ()
	for _, device in pairs(teamADevices) do
		device.Muted = toggle
	end
	for _, device in pairs(teamBDevices) do
		device.Muted = toggle
	end
end

--// OBSERVERS
local function observer(player: Player, teamDevices: { [Player]: AudioDeviceInput }, userIds: { number })
	local newDevice: AudioDeviceInput? = player:WaitForChild("AudioDeviceInput") :: AudioDeviceInput?
	if not newDevice then
		return nil :: any
	end
	teamADevices[player] = newDevice

	newDevice.Muted = muted
	newDevice.AccessType = Enum.AccessModifierType.Allow

	table.insert(userIds, player.UserId)
	updateDevices(teamADevices, userIds)

	return function()
		teamADevices[player] = nil

		table.remove(teamAUserIds, table.find(userIds, player.UserId))
		updateDevices(teamADevices, userIds)
	end
end

Charm.observe(Teams.TeamA :: any, function(_, player: Player)
	return observer(player, teamADevices, teamAUserIds)
end)

Charm.observe(Teams.TeamB :: any, function(_, player: Player)
	return observer(player, teamBDevices, teamBUserIds)
end)

return Module