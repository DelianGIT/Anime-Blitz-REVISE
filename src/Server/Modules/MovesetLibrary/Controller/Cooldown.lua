--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)

--// MODULES
local ServerModules = ServerScriptService.Modules
local PlayerData = require(ServerModules.PlayerData)

local Types = require(script.Parent.Parent.Types)

--// TYPES
type Cooldown = Types.Cooldown
type Cooldowns = { [string]: Cooldown }

--// VARIABLES
local movesetAtom = PlayerData.Atoms.Moveset

local Module = {}

--// MODULE FUNCTIONS
function Module.Create(moves: Types.Moves): Cooldowns
	local cooldowns: Cooldowns = {}
	for name, move in pairs(moves) do
		local cooldownData: Types.CooldownData? = move.Data.Cooldown
		if not cooldownData then
			continue
		end

		cooldowns[name] = {
			Duration = cooldownData.Duration,
			StartTimestamp = 0
		}
	end
	return cooldowns
end

function Module.Start(player: Player, name: string, oneTimeDuration: number?): ()
	local moveset: Types.Moveset? = movesetAtom()[player]
	if not moveset then
		error(`Player {player} doesn't have a moveset`)
	end

	local cooldowns = moveset.Cooldowns
	local cooldown: Cooldown? = cooldowns[name]
	if not cooldown then
		error(`Player {player} doesn't have cooldown {name} in the moveset {moveset.Name}`)
	end

	cooldown.TempDuration = oneTimeDuration
	cooldown.StartTimestamp = os.clock()

	cooldowns = Sift.Dictionary.set(cooldowns, name, cooldown)
	moveset = Sift.Dictionary.copy(moveset)
	moveset.Cooldowns = cooldowns
	movesetAtom(function(state)
		return Sift.Dictionary.set(state, player, moveset)
	end)
end

function Module.Stop(player: Player, name: string): ()
	local moveset: Types.Moveset? = movesetAtom()[player]
	if not moveset then
		error(`Player {player} doesn't have a moveset`)
	end

	local cooldowns = moveset.Cooldowns
	local cooldown: Cooldown? = cooldowns[name]
	if not cooldown then
		error(`Player {player} doesn't have cooldown {name} in the moveset {moveset.Name}`)
	end

	cooldown.TempDuration = nil
	cooldown.StartTimestamp = 0

	cooldowns = Sift.Dictionary.set(cooldowns, name, cooldown)
	moveset = Sift.Dictionary.copy(moveset)
	moveset.Cooldowns = cooldowns
	movesetAtom(function(state)
		return Sift.Dictionary.set(state, player, moveset)
	end)
end

function Module.IsOnCooldown(player: Player, name: string): boolean
	local moveset: Types.Moveset? = movesetAtom()[player]
	if not moveset then
		error(`Player {player} doesn't have a moveset`)
	end

	local cooldowns = moveset.Cooldowns
	local cooldown: Cooldown? = cooldowns[name]
	if not cooldown then
		error(`Player {player} doesn't have cooldown {name} in the moveset {moveset.Name}`)
	end

	local duration: number = cooldown.TempDuration or cooldown.Duration
	return os.clock() - cooldown.StartTimestamp < duration
end

function Module.HasCooldown(player: Player, name: string)
	local moveset: Types.Moveset? = movesetAtom()[player]
	if not moveset then
		error(`Player {player} doesn't have a moveset`)
	end

	if moveset.Cooldowns[name] then
		return true
	else
		return false
	end
end

return Module