--!strict
--// SERVICES
local ServerScriptService = game:GetService("ServerScriptService")

--// TYPES
export type Perk = {
	Apply: (Player) -> boolean,
	Remove: (Player) -> boolean
}
export type Perks = { [number]: Perk }
export type Pack = { [number]: Perks }

--// VARIABLES
local Module: { [string]: Pack } = {}

--// REQUIRING PERKS
for _, packFolder in ipairs(ServerScriptService.Perks:GetChildren()) do
	local pack: Pack = {}

	for _, levelFolder in ipairs(packFolder:GetChildren()) do
		local perks: Perks = {}

		for _, perkModule in ipairs(levelFolder:GetChildren()) do
			local number: number = tonumber(perkModule.Name) :: number
			perks[number] = require(perkModule) :: any
		end

		local level: number = tonumber(levelFolder.Name) :: number
		pack[level] = perks
	end

	Module[packFolder.Name] = pack
end

return Module