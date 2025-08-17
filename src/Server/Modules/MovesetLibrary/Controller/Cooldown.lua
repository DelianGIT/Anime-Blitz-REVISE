--!strict
--// SERVICES
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)

--// MODULES
local ServerModules = ServerScriptService.Modules
local DataStore = require(ServerModules.DataStore)

--// TYPES
type Cooldown = {
	Duration: number,
	StartTimestamp: number,
	TempDuration: number?,
}

--// VARIABLES
local Module = {}

--// MODULE FUNCTIONS
function Module.Add(player: Player, name: string, duration: number): ()
	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
	tempData = Sift.Dictionary.copy(tempData)
	tempData.Cooldowns = Sift.Dictionary.set(tempData.Cooldowns, name, {
		Duration = duration,
		StartTimestamp = 0
	} :: Cooldown)
	DataStore.UpdateTemporaryData(player, tempData)
end

function Module.Remove(player: Player, name: string): ()
	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
	tempData = Sift.Dictionary.copy(tempData)
	tempData.Cooldowns = Sift.Dictionary.removeKey(tempData.Cooldowns, name)
	DataStore.UpdateTemporaryData(player, tempData)
end

function Module.RemoveAll(player: Player): ()
	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
	tempData = Sift.Dictionary.copy(tempData)
	tempData.Cooldowns = Sift.Dictionary.filter(tempData.Cooldowns)
	DataStore.UpdateTemporaryData(player, tempData)
end

function Module.Start(player: Player, name: string, duration: number?): ()
	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)

	local cooldowns: { [string]: Cooldown } = tempData.Cooldowns
	local cooldown: Cooldown? = cooldowns[name]
	if not cooldown then
		error(`Can't find cooldown {name} for player {player.Name}`)
	end

	cooldown = Sift.Dictionary.copy(cooldown)
	cooldown.StartTimestamp = os.clock()

	if duration then
		cooldown.TempDuration = duration
	else
		cooldown.TempDuration = nil
	end

	tempData = Sift.Dictionary.copy(tempData)
	tempData.Cooldowns = Sift.Dictionary.set(cooldowns, name, cooldown)
	DataStore.UpdateTemporaryData(player, tempData)
end

function Module.Stop(player: Player, name: string): ()
	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)

	local cooldowns: { [string]: Cooldown } = tempData.Cooldowns
	local cooldown: Cooldown? = (tempData.Cooldowns :: any)[name]
	if not cooldown then
		error(`Can't find cooldown {name}`)
	end

	cooldown = Sift.Dictionary.copy(cooldown)
	cooldown.StartTimestamp = 0

	tempData = Sift.Dictionary.copy(tempData)
	tempData.Cooldowns = Sift.Dictionary.set(cooldowns, name, cooldown)
	DataStore.UpdateTemporaryData(player, tempData)
end

function Module.IsOnCooldown(player: Player, name: string): boolean
	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)

	local cooldown: Cooldown = (tempData.Cooldowns :: any)[name]
	if not cooldown then
		error(`Can't find cooldown {name}`)
	end

	local duration: number? = cooldown.TempDuration
	if not duration then
		duration = cooldown.Duration
	end

	if (os.clock() - cooldown.StartTimestamp) < cooldown.Duration then
		return true
	else
		return false
	end
end

function Module.HasCooldown(player: Player, name: string): boolean
	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
	if (tempData.Cooldowns :: any)[name] then
		return true
	else
		return false
	end
end

return Module