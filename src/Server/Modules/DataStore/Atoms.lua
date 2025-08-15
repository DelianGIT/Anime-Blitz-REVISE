--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Charm = require(Packages.Charm)

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local Snapshot = require(SharedModules.Snapshot)

local TemporaryDataTemplate = require(script.Parent.TemporaryDataTemplate)

--// TYPES
export type TemporaryDataAtom = Charm.Atom<{ [Player]: TemporaryDataTemplate.Data }>
export type Atom<T> = Charm.Atom<{ [Player]: T }>

--// TEMPORARY DATA ATOM
local temporaryDataAtom: TemporaryDataAtom = Charm.atom({})

--// ATOMS
local loadedPlayers: Atom<boolean> = Charm.atom({})
local snapshots: Atom<Snapshot.Snapshot> = Charm.atom({})

local atoms = {
	LoadedPlayers = loadedPlayers,
	Snapshots = snapshots
}

--// SHARED ATOMS
local teamAAtom: Atom<boolean> = Charm.atom({})
local teamBAtom: Atom<boolean> = Charm.atom({})

local sharedAtoms = {
	TeamA = teamAAtom,
	TeamB = teamBAtom
}

--// MODULE
return {
	TemporaryDataAtom = temporaryDataAtom,
	Atoms = atoms,
	SharedAtoms = sharedAtoms
}