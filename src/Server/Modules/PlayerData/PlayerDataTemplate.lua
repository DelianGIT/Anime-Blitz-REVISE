--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local Snapshot = require(SharedModules.Snapshot)

--// TEMPLATE
local template: Data = {
	Team = "None",

	UltimateCharge = 0,

	Level = 0,
	Experience = 0,

	Perks = {},

	HumanoidChanges = {},
	BodyMovers = {
		LinearVelocity = {}
	}
} :: any

--// TYPE
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
		Name: string
	}?,

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

	RootCFrame: CFrame
}

return template