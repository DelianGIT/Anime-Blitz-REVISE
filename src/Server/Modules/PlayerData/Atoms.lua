--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Charm = require(Packages.Charm)

--// MODULES
local ServerModules = ServerScriptService.Modules
local MovesetLibraryTypes = require(ServerModules.MovesetLibrary.Types)

local SharedModules = ReplicatedStorage.Modules
local Snapshot = require(SharedModules.Snapshot)

--// TYPES
export type Atom<T> = Charm.Atom<{ [Player]: T }>

export type Atoms = {
	Stats: Atom<{
		UltimateCharge: number,
		Level: number,
		Experience: number,
	}>,

	Moveset: Atom<MovesetLibraryTypes.Moveset>,
	ActiveMove: Atom<MovesetLibraryTypes.ActiveMove>,

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
	}>,

	Loaded: Atom<boolean>,

	Character: Atom<Model>,

	SpawnPoint: Atom<BasePart>
}

--// ATOM NAMES
local atomNames: { string } = {
	"Stats",
	"Moveset",
	"ActiveMove",
	"Perks",
	"HumanoidChanges",
	"BodyMovers",
	"Snapshot",
	"RootCFrame",
	"Knockback",
	"Stun",
	"Loaded",
	"Character",
	"SpawnPoint"
}

--// CREATING ATOMS
local atoms: Atoms = {} :: Atoms
for _, atomName in ipairs(atomNames) do
	(atoms :: any)[atomName] = Charm.atom({})
end

return atoms