--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// TYPES
type Args = {
	Player: Player,
	Character: Model,
	MoveData: MoveData,
	Cache: { [any]: any },
	Communicator: any,
	Data: any
}
type Cooldown = {
	Type: "Start" | "End" | "Manual",
	Duration: number,
}
type MoveData = {
	Duration: number,
	Cooldown: Cooldown?,
	StartIsSequence: boolean?,
	EndIsSequence: boolean?,
}
type MoveFunctions = {
	Start: (args: Args) -> (),
	End: (args: Args) -> (),
	Cancel: (args: Args) -> (),
}
type Move = {
	Data: MoveData,
	Functions: MoveFunctions,
}
export type Moves = { [string]: Move }

--// VARIABLES
local movesetsFolder: Folder = ServerScriptService.Movesets
local sharedMovesDataFolder: Folder = ReplicatedStorage.MovesData

local Module: { [string]: Moves } = {}

--// REQUIRING MOVESETS
for _, folder in ipairs(movesetsFolder:GetChildren()) do
	if not folder:IsA("Folder") then
		continue
	end
	local moveset: Moves = {}

	local movesetName: string = folder.Name
	local sharedMovesData: ModuleScript? = sharedMovesDataFolder:FindFirstChild(movesetName) :: ModuleScript?
	if sharedMovesData then
		sharedMovesData = require(sharedMovesData) :: any
	end

	for _, module in ipairs(folder:GetChildren()) do
		if not module:IsA("ModuleScript") then
			continue
		end

		local success: boolean, err: any = pcall(require, module)
		if not success then
			warn(`Move {module:GetFullName()} threw an error during requiring: {err}`)
			continue
		end

		local moveName: string = module.Name
		if sharedMovesData then
			local sharedData = (sharedMovesData :: any)[moveName]
			if sharedData then
				local moveData = err.Data

				for key, value in pairs(sharedData :: any) do
					moveData[key] = value
				end
			end
		end

		moveset[moveName] = err
	end

	Module[movesetName] = moveset
end

return Module
