--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// MODULES
local Types = require(script.Parent.Types)

--// TYPES
type Moves = Types.Moves

--// VARIABLES
local movesetsFolder: Folder = ServerScriptService.Movesets
local sharedMovesetsDataFolder: Folder = ReplicatedStorage.SharedMovesetsData

local Module: { [string]: Moves } = {}

--// REQUIRING MOVESETS
for _, folder in ipairs(movesetsFolder:GetChildren()) do
	if not folder:IsA("Folder") then
		continue
	end
	local moveset: Moves = {}

	local movesetName: string = folder.Name
	local sharedMovesData: ModuleScript? = sharedMovesetsDataFolder:FindFirstChild(movesetName) :: ModuleScript?
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
