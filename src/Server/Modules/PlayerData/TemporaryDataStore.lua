--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Charm = require(Packages.Charm)

--// MODULES
local ServerModules = ServerScriptService.Modules
local Sequence = require(ServerModules.Sequence)

local SharedModules = ReplicatedStorage.Modules
local Snapshot = require(SharedModules.Snapshot)

--// TYPES
export type Atom<T> = Charm.Atom<{ [Player]: T }>

export type Atoms = {
	Team: Atom<"A" | "B" | "None">,

	CharacterData: Atom<{
		Name: string,
		Category: string,
		Stats: {
			Health: number
		}
	}>,

	Stats: Atom<{
		UltimateCharge: number,
		Level: number,
		Experience: number,
	}>,

	Moveset: Atom<{
		Name: string,
		Moves: { [string]: any }
	}>,

	MoveCommunicator: Atom<any>,

	MoveCooldowns: Atom<{ [string]: {
		Duration: number,
		StartTimestamp: number,
		TempDuration: number?
	} }>,

	ActiveMove: Atom<{
		Name: string,
		State: "Start" | "ReadyToEnd" | "End" | "Cancel",
		StartTimestamp: number?,
		Cache: { [any]: any },
		Cancelled: boolean?,
		RequestedEnd: boolean?,
		Track: Sequence.Track?
	}>,

	Perks: Atom<{ [string]: boolean }>,

	HumanoidChanges: Atom<{
		[string]: {
			Properties: { [string]: any },
			Priority: number,
			StartTimestamp: number?
		}
	}>,

	BodyMovers: Atom<{
		LinearVelocity: {
			[string]: {
				Priority: number,
				StartTimestamp: number?
			}
		}
	}>,

	Snapshot: Atom<Snapshot.Snapshot>,

	RootCFrame: Atom<CFrame>,

	Knockback: Atom<{
		Priority: number,
		StartTimestamp: number?,
	}>,

	Stun: Atom<{
		WalkSpeed: number?,
		JumpPower: number?,
		StartTimestamp: number?,
	}>
}

--// ATOM NAMES
local atomNames: { string } = {
	"Team",
	"CharacterData",
	"Stats",
	"Moveset",
	"MoveCommunicator",
	"MoveCooldowns",
	"ActiveMove",
	"Perks",
	"HumanoidChanges",
	"BodyMovers",
	"Snapshot",
	"RootCFrame",
	"Knockback",
	"Stun"
}

--// DEFAULT VALUES
local defaultValues = {
	Team = "None",

	Stats = {
		UltimateCharge = 0,
		Level = 0,
		Experience = 0
	},

	MoveCooldowns = {},

	Perks = {},

	HumanoidChanges = {},

	BodyMovers = {
		LinearVelocity = {}
	}
}

--// CREATING ATOMS
local atoms: Atoms = {} :: Atoms
for _, atomName in ipairs(atomNames) do
	(atoms :: any)[atomName] = Charm.atom({})
end

return {
	Atoms = atoms,
	DefaultValues = defaultValues
}