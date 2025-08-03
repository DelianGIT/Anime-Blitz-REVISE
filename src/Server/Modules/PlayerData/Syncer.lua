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
local LoadedPlayersList = require(script.Parent.LoadedPlayersList)

--// REMOTE EVENTS
local RemoteEvents = require(ReplicatedStorage.RemoteEvents.PlayerDataSync)
local Sync = RemoteEvents.Sync
local Request = RemoteEvents.Request
local Synced = RemoteEvents.Synced

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
local function getPlayerData(player: Player): Store.PlayerData?
	local playerData: Store.PlayerData? = playerDataAtom()[player]
	if not playerData then
		repeat
			task.wait()
			playerData = playerDataAtom()[player]
		until playerData or player.Parent ~= Players
	end
	return playerData
end

local function filterPlayerData(playerData: Store.PlayerData)
	return Sift.Dictionary.withKeys(playerData :: any, "Team", "CharacterData")
end

local function filterPayload(player: Player, payload: any): any
	local payloadData = Sift.Dictionary.copy(payload.data)
	payload = Sift.Dictionary.copy(payload)
	payload.data = payloadData

	local playerData
	if payload.type == "init" then
		playerData = getPlayerData(player)
	elseif payload.type == "patch" then
		local allPlayerData: Store.PlayerDataMap? = payloadData.PlayerData
		if allPlayerData then
			playerData = allPlayerData[player]
		end
	end

	if playerData then
		playerData = filterPlayerData(playerData)
		if Sift.isEmpty(playerData) then
			playerData = nil
		end
	end

	payloadData.PlayerData = playerData

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
	if not Sift.isEmpty(payload.data) then
		Sync.sendTo(payload :: any, player)
	end
end)

--// EVENTS
Request.listen(function(_, player: Player?)
	if player then
		syncer:hydrate(player)
	end
end)

Synced.listen(function(_, player: Player?)
	if player then
		table.insert(LoadedPlayersList, player)
	end
end)

return Module