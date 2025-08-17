--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local CharmSync = require(Packages.CharmSync)
local Sift = require(Packages.Sift)

--// MODULES
local Atoms = require(script.Atoms)

--// REMOTE EVENTS
local RemoteEvents = require(ReplicatedStorage.RemoteEvents.DataSync)
local SyncRemoteEvent = RemoteEvents.Sync
local RequestRemoteEvent = RemoteEvents.Request

--// TYPES
export type TemporaryData = Atoms.TemporaryData
export type TemporaryDataAtom = Atoms.TemporaryDataAtom
export type Atom<T> = Atoms.Atom<T>

--// VARIABLES
local temporaryDataAtom: TemporaryDataAtom = Atoms.TemporaryDataAtom

local sharedAtoms = Atoms.SharedAtoms
local Module = {}

--// MODULE PROPERTIES
Module.TemporaryDataAtom = temporaryDataAtom
Module.SharedAtoms = sharedAtoms

--// SYNCER
local syncer = CharmSync.client({
	atoms = Sift.Dictionary.merge({
		TemporaryData = temporaryDataAtom
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