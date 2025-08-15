--!strict
--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// MODULES
local ServerModules = ServerScriptService.Modules
local DataStore = require(ServerModules.DataStore)
local DamageController = require(ServerModules.DamageController)

local SharedModules = ReplicatedStorage.Modules
local Hitbox = require(SharedModules.Hitbox)

--// TYPES
export type Params = {
	Raycasting: boolean?,
	MaxDistance: number?,
}

--// CONSTANTS
local DESYNC_THRESHOLD = 3
local MAX_DESYNC = 5

--// VARIABLES
local snapshotsAtom = DataStore.Atoms.Snapshots

local Module = {}

--// FUNCTIONS
local function getDesyncMargin(humanoidRootPart: BasePart, latency: number): number
	local velocity: number = humanoidRootPart.AssemblyLinearVelocity.Magnitude
	return velocity * latency
end

local function getRewindedCFrame(player: Player, humanoidRootPart: BasePart, hitTimestamp: number): CFrame?
	local snapshot = (snapshotsAtom() :: any)[player]
	if not snapshot then
		return nil
	end

	local rewindedCFrame: CFrame? = snapshot:GetAt(hitTimestamp)
	return rewindedCFrame or humanoidRootPart.CFrame
end

local function checkDesync(player: Player, humanoidRootPart: BasePart, hitTimestamp: number, clientPosition: Vector3, hitName: string?): CFrame?
	local rewindedCFrame: CFrame? = getRewindedCFrame(player, humanoidRootPart, hitTimestamp)
	if not rewindedCFrame then
		return nil
	end
	local rewindedPosition: Vector3 = rewindedCFrame.Position

	local latency: number = player:GetNetworkPing() / 2
	local desyncMargin: number = getDesyncMargin(humanoidRootPart, latency)

	local desync: number = (clientPosition - rewindedPosition).Magnitude
	local maxDesync: number = math.min(DESYNC_THRESHOLD + desyncMargin, MAX_DESYNC)

	if desync < maxDesync then
		return rewindedCFrame
	else
		--TODO: calibrate desyncMargin and DESYNC_THRESHOLD, when done remove playerName from the function parameters
		warn(if hitName then player.Name .. " -> " .. hitName else player.Name)
		warn("DESYNC: " .. desync)
		warn("MAX DESYNC: " .. maxDesync)
		warn("DESYNC MARGIN: " .. desyncMargin)
		return nil
	end
end

local function checkAttacker(player: Player, hitTimestamp: number, playerPosition: Vector3): CFrame?
	local character: Model? = player.Character
	if not character then
		return nil
	end

	local humanoidRootPart: BasePart? = character:FindFirstChild("HumanoidRootPart") :: Part?
	if not humanoidRootPart then
		return nil
	end

	return checkDesync(player, humanoidRootPart, hitTimestamp, playerPosition)
end

local function checkHit(hit: Model, hitTimestamp: number, playerRewindedCFrame: CFrame, hitPosition: Vector3, params: Params?): CFrame?
	local hitPlayer: Player? = Players:GetPlayerFromCharacter(hit)
	if not hitPlayer then
		return nil
	end

	local hitHumanoidRootPart: BasePart? = hit:FindFirstChild("HumanoidRootPart") :: Part?
	if not hitHumanoidRootPart then
		return nil
	end

	local hitRewindedCFrame: CFrame? = checkDesync(hitPlayer, hitHumanoidRootPart, hitTimestamp, hitPosition, hitPlayer.Name)
	if not hitRewindedCFrame then
		return nil
	end

	if not params then
		return hitRewindedCFrame
	end

	local maxDistance: number? = params.MaxDistance
	if maxDistance then
		local distance: number = (playerRewindedCFrame.Position - hitRewindedCFrame.Position).Magnitude
		if distance > maxDistance then
			return nil
		end
	end

	local raycasting: boolean? = params.Raycasting
	if raycasting then
		local origin: Vector3 = playerRewindedCFrame.Position
		local direction: Vector3 = hitRewindedCFrame.Position - origin

		local raycastResult: Hitbox.RaycastResult? = Hitbox.Raycast(origin, direction, {
			Target = "Living"
		})
		if not raycastResult then
			return nil
		end
	end

	return hitRewindedCFrame
end

--// MODULE FUNCTIONS
function Module.Single(player: Player, hitTimestamp: number, playerPosition: Vector3, hit: Model, hitPosition: Vector3, params: Params?): (CFrame?, CFrame?)
	if not DamageController.IsHittable(hit) then
		return nil, nil
	end

	local playerRewindedCFrame: CFrame? = checkAttacker(player, hitTimestamp, playerPosition)
	if not playerRewindedCFrame then
		return nil, nil
	end

	local hitRewindedCFrame: CFrame? = checkHit(hit, hitTimestamp, playerRewindedCFrame, hitPosition, params)
	if not hitRewindedCFrame then
		return nil, nil
	end

	return playerRewindedCFrame, hitRewindedCFrame
end

function Module.Multiple(player: Player, hitTimestamp: number, playerPosition: Vector3, hits: { [Model]: Vector3 }, params: Params?): (CFrame?, { [Model]: CFrame}?)
	local playerRewindedCFrame: CFrame? = checkAttacker(player, hitTimestamp, playerPosition)
	if not playerRewindedCFrame then
		return nil, nil
	end

	local validatedHits: { [Model]: CFrame } = {}
	for hit, hitPosition in pairs(hits) do
		local hitRewindedCFrame: CFrame? = checkHit(hit, hitTimestamp, playerRewindedCFrame, hitPosition, params)
		if hitRewindedCFrame then
			validatedHits[hit] = hitRewindedCFrame
		end
	end

	return playerRewindedCFrame, validatedHits
end

return Module