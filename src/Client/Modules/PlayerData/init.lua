--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Charm = require(Packages.Charm)
local CharmSync = require(Packages.CharmSync)
local Sift = require(Packages.Sift)

--// MODULES
local PlayerDataTemplate = require(script.PlayerDataTemplate)

--// REMOTE EVENTS
local RemoteEvents = require(ReplicatedStorage.RemoteEvents.PlayerDataSync)
local SyncRemoteEvent = RemoteEvents.Sync
local RequestRemoteEvent = RemoteEvents.Request

--// TYPES
export type Data = PlayerDataTemplate.Data
export type Atom = Charm.Atom<Data>

--// VARIABLES
local Module = {}

--// ATOMS
local playerDataAtom: Atom = Charm.atom({}) :: any

local teamA: Charm.Atom<{ [Player]: boolean }> = Charm.atom({})
local teamB: Charm.Atom<{ [Player]: boolean }> = Charm.atom({})

local sharedAtoms = {
	TeamA = teamA,
	TeamB = teamB
}

--// MODULE PROPERTIES
Module.Atom = playerDataAtom
Module.SharedAtoms = sharedAtoms

--// SYNCER
local syncer = CharmSync.client({
	atoms = Sift.Dictionary.merge({
		PlayerData = playerDataAtom
	}, sharedAtoms) :: any,
	ignoreUnhydrated = true,
})

--// EVENTS
SyncRemoteEvent.listen(function(payload: any)
	print(payload)
	syncer:sync(payload)
end)

--// REQUESTING THE INITIAL STATE
RequestRemoteEvent.send()

return Module