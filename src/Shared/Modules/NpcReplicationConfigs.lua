--!strict
--// TYPES
export type Config = {
	TickRate: number,
	Buffer: number
}

--// CONFIGS
local configs: { [string]: Config } = {
	Default = {
		TickRate = 1 / 40,
		Buffer = 0.1,
	}
}

return configs