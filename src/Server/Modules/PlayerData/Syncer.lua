--!strict
--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Charm = require(Packages.Charm)
local CharmSync = require(Packages.CharmSync)
local Sift = require(Packages.Sift)

--// MODULES
local Store = require(script.Parent.Store)

--// REMOTE EVENTS
local RemoteEvents = require(ReplicatedStorage.RemoteEvents.PlayerDataSync)
local SyncRemoteEvent = RemoteEvents.Sync
local RequestRemoteEvent = RemoteEvents.Request

--// VARIABLES
local Module = {}

--// ATOMS
local playerDataAtom: Store.PlayerDataAtom = Store.Atom

local teamAAtom: Charm.Atom<{ [Player]: boolean }> = Charm.atom({})
local teamBAtom: Charm.Atom<{ [Player]: boolean }> = Charm.atom({})

local sharedAtoms = {
	TeamA = teamAAtom,
	TeamB = teamBAtom
}

--// MODULE PROPERTIES
Module.SharedAtoms = sharedAtoms

--// FUNCTIONS
local function filterPayload(player: Player, payload): any
	local playerData = playerDataAtom()[player]
	if payload.type == "init" and not playerData then
		repeat
			task.wait()
			playerData = playerDataAtom()[player]
		until playerData or player.Parent ~= Players
		if player.Parent ~= Players then
			return
		end
	end

	payload = Sift.Dictionary.copy(payload)
	payload.data = Sift.Dictionary.set(payload.data, "PlayerData", playerData)
	return payload
end

--// SYNCER
local syncer = CharmSync.server({
	atoms = Sift.Dictionary.merge({
		PlayerData = playerDataAtom
	}, sharedAtoms) :: any,
	interval = 0,
	preserveHistory = false,
	autoSerialize = false,
})

syncer:connect(function(player: Player, payload: any)
	payload = filterPayload(player, payload)
	if payload then
		SyncRemoteEvent.sendTo(payload :: any, player)
	end
end)

--// EVENTS
RequestRemoteEvent.listen(function(_, player: Player?)
	if player then
		syncer:hydrate(player)
	end
end)

return Module