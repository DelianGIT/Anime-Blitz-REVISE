--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Charm = require(Packages.Charm)

--// TYPES
type Atom<T> = Charm.Atom<T>

--// ATOMS
local team: Atom<{ [Player]: "A" | "B" | "None" }> = Charm.atom({})

local characterData: Atom<{
	Name: string,
	Category: string,
	Properties: {
		Health: number
	}
}?> = Charm.atom() :: any

return {
	Team = team,
	CharacterData = characterData
}