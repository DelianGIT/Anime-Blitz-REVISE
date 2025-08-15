--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Charm = require(Packages.Charm)

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local SharedTemporaryDataFields = require(SharedModules.SharedTemporaryDataFields)

--// TYPES
export type TemporaryData = SharedTemporaryDataFields.Data
export type TemporaryDataAtom = Charm.Atom<TemporaryData>
export type Atom<T> = Charm.Atom<{ [Player]: T }>

--// TEMPORARY DATA ATOM
local temporaryDataAtom: TemporaryDataAtom = Charm.atom({} :: any)

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
	SharedAtoms = sharedAtoms
}