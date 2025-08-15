--!strict
--// SERVICES
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

--// MODULES
local ServerModules = ServerScriptService.Modules
local Teams = require(ServerModules.Teams)
local Level = require(ServerModules.Level)
local UltimateCharge = require(ServerModules.UltimateCharge)

local Stun = require(script.Stun)
local Knockback = require(script.Knockback)

--// TYPES
type Params = {
	DamageAmount: number,

	Stun: Stun.Params?,

	KnockbackVector: Vector3?,
	Knockback: Knockback.Params?,
}

--// VARIABLES
local livingFolder: Folder = workspace.Living

local Module = {}

--// MODULE FUNCTIONS
function Module.Deal(aPlayer: Player, tCharacter: Model, params: Params): boolean
	if not Module.IsHittable(tCharacter) then
		return false
	end

	local tPlayer: Player? = Players:FindFirstChild(tCharacter.Name) :: Player?
	if not tPlayer then
		return false
	end

	if Teams.AreInSame(aPlayer, tPlayer) then
		return false
	end

	local damageAmount: number = Module.CalculateDamage(params.DamageAmount);
	(tCharacter :: any).Humanoid:TakeDamage(damageAmount)

	Level.GiveExperience(aPlayer, damageAmount)
	UltimateCharge.Charge(aPlayer, damageAmount)

	local knockbackVector: Vector3? = params.KnockbackVector
	local knockback: Knockback.Params? = params.Knockback
	if knockback and knockbackVector then
		Knockback.Apply(tPlayer, knockbackVector, knockback)
	end

	local stun: Stun.Params? = params.Stun
	if stun then
		Stun.Apply(tPlayer, stun)
	end

	return true
end

function Module.CalculateDamage(baseDamageAmount: number): number
	return baseDamageAmount
end

function Module.IsHittable(tCharacter: Model): boolean
	if not tCharacter:IsA("Model") or not tCharacter:IsDescendantOf(livingFolder) then
		return false
	end

	local tHumanoid: Humanoid? = tCharacter:FindFirstChild("Humanoid") :: Humanoid?
	if not tHumanoid or tHumanoid.Health <= 0 then
		return false
	end

	if not tCharacter:FindFirstChild("HumanoidRootPart") then
		return false
	end

	return true
end

return Module