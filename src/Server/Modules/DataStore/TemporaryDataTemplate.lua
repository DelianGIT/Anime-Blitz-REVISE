--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local Snapshot = require(SharedModules.Snapshot)

--// TYPES
export type Data = {
	Team: "A" | "B" | "None",
	
	SpawnPoint: BasePart?,

	CharacterData: {
		Name: string,
		Category: string,
		Stats: {
			Health: number
		}
	}?,

	UltimateCharge: number,

	Level: number,
	Experience: number,

	Moveset: {
		Name: string,
		Moves: { [string]: any }
	}?,
	MoveCommunicator: any?,

	Cooldowns: { [string]: {
		Duration: number,
		StartTimestamp: number,
		TempDuration: number?
	} },

	Perks: { [string]: true },

	HumanoidChanges: {
		[string]: {
			Properties: { [string]: any },
			Priority: number,
			StartTimestamp: number?
		}
	},

	BodyMovers: {
		LinearVelocity: {
			[string]: {
				Priority: number,
				StartTimestamp: number?
			}
		}
	},

	Snapshot: Snapshot.Snapshot,

	RootCFrame: CFrame,

	Knockback: {
		Priority: number,
		StartTimestamp: number?,
	}?,

	Stun: {
		WalkSpeed: number?,
		JumpPower: number?,
		StartTimestamp: number?,
	}?
}

--// TEMPLATE
local template: Data = {
	Team = "None",

	UltimateCharge = 0,

	Level = 0,
	Experience = 0,

	Cooldowns = {},

	Perks = {},

	HumanoidChanges = {},
	BodyMovers = {
		LinearVelocity = {}
	}
} :: any

return template