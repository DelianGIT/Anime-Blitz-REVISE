--!strict
--// SERVICES
local ServerScriptService = game:GetService("ServerScriptService")

--// MODULES
local ServerModules = ServerScriptService.Modules
local PlayerData = require(ServerModules.PlayerData)

local Cooldown = require(script.Parent.Cooldown)

--// VARIABLES
local movesetAtom = PlayerData.Atoms.Moveset
local activeMoveAtom = PlayerData.Atoms.ActiveMove
local stunAtom = PlayerData.Atoms.Stun

local Module = {}

--// MODULE FUNCTIONS
function Module.Start(player: Player, moveName: string): (boolean, string?)
	local character: Model? = player.Character
	if not character then
		return false, "Character doesn't exist"
	end

	if not character:FindFirstChild("HumanoidRootPart") then
		return false, "Character doesn't have HumanoidRootPart"
	end

	local humanoid: Humanoid? = character:FindFirstChild("Humanoid") :: Humanoid?
	if not humanoid then
		return false, "Character doesn't have Humanoid"
	end

	if (character :: any).Humanoid.Health <= 0 then
		return false, "Character is dead"
	end

	if activeMoveAtom()[player] then
		return false, "Casting another move"
	end

	if stunAtom()[player] then
		return false, "Stunned"
	end

	local moveset = movesetAtom()[player]
	if not moveset then
		return false, "Doesn't have the moveset"
	end

	local move = moveset.Moves[moveName]
	if not move then
		return false, "Doesn't have the move"
	end

	if Cooldown.HasCooldown(player, moveName) and Cooldown.IsOnCooldown(player, moveName) then
		return false, "On cooldown"
	end

	return true, nil
end

function Module.End(player: Player, moveName: string?): (boolean, string?)
	local character: Model? = player.Character
	if not character then
		return false, "Character doesn't exist"
	end

	if not character:FindFirstChild("HumanoidRootPart") then
		return false, "Character doesn't have HumanoidRootPart"
	end

	local humanoid: Humanoid? = character:FindFirstChild("Humanoid") :: Humanoid?
	if not humanoid then
		return false, "Character doesn't have Humanoid"
	end

	if (character :: any).Humanoid.Health <= 0 then
		return false, "Character is dead"
	end

	local activeMove = activeMoveAtom()[player]
	if not activeMove then
		return false, "Not casting the move"
	end

	if activeMove.State == "End" then
		return false, "Already ending"
	elseif activeMove.RequestedEnd then
		return false, "Already requested end"
	end

	if stunAtom()[player] then
		return false, "Stunned"
	end

	local moveset = movesetAtom()[player]
	if not moveset then
		return false, "Doesn't have the moveset"
	end

	local move = moveset.Moves[moveName or activeMove.Name]
	if not move then
		return false, "Doesn't have the move"
	end

	if not move.Functions.End then
		return false, "Doesn't have an end function"
	end

	activeMove.RequestedEnd = true
	if activeMove.State ~= "ReadyToEnd" then
		repeat
			task.wait()
			activeMove = activeMoveAtom()[player]
		until not activeMove or activeMove.State == "ReadyToEnd"

		if not activeMove then
			return false, "Not casting the move"
		end
	end

	return true, nil
end

function Module.Cancel(player: Player): (boolean, string?)
	local activeMove = activeMoveAtom()[player]
	if not activeMove then
		return false, "Not casting the move"
	end

	if activeMove.State == "Cancel" then
		return false, "Already cancelling"
	end

	local moveset = movesetAtom()[player]
	if not moveset then
		return false, "Doesn't have the moveset"
	end

	local move = moveset.Moves[activeMove.Name]
	if not move then
		return false, "Doesn't have the move"
	end

	return true, nil
end

return Module