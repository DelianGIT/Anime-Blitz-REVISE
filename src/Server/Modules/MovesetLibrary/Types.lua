--// SERVICES
local ServerScriptService = game:GetService("ServerScriptService")

--// MODULES
local ServerModules = ServerScriptService.Modules
local Sequence = require(ServerModules.Sequence)

--// TYPES
export type Args = {
	Player: Player,
	Character: Model,
	MoveData: MoveData,
	Cache: { [any]: any },
	Communicator: any,
	Data: any
}

export type CooldownData = {
	Type: "Start" | "End" | "Manual",
	Duration: number,
}
export type Cooldown = {
	Duration: number,
	StartTimestamp: number,
	TempDuration: number?,
}

export type MoveData = {
	Duration: number,
	Cooldown: CooldownData?,
	StartIsSequence: boolean?,
	EndIsSequence: boolean?,
}

export type MoveFunctions = {
	Start: (Args) -> (),
	End: (Args) -> (),
	Cancel: (Args) -> (),
}

export type Move = {
	Data: MoveData,
	Functions: MoveFunctions,
}
export type Moves = { [string]: Move }

export type Moveset = {
	Name: string,
	Moves: Moves,
	Communicator: any?,
	Cooldowns: { [string]: Cooldown }
}

export type ActiveMove = {
	Name: string,
	State: "Start" | "ReadyToEnd" | "End" | "Cancel",
	StartTimestamp: number?,
	Cache: { [any]: any },
	Cancelled: boolean?,
	RequestedEnd: boolean?,
	Track: Sequence.Track?
}

return true