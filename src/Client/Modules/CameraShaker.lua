--!strict
--// SERVICES
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local Utility = require(SharedModules.Utility)

--// TYPES
type Origin = Vector3 | BasePart | Attachment
type Params = {
	Magnitude: number,
	Roughness: number,
	FadeOutDuration: number,
	FadeInDuration: number,
	PositionInfluence: Vector3?,
	RotationInfluence: Vector3?,
}
type Shake = Params & {
	Tick: number,
	Origin: Origin?,
	Radius: number?,
	FadeTime: number,
	FadingIn: boolean,
	FadingOut: boolean,
	Sustain: boolean,
}

--// CONSTANTS
local RENDER_PRIORITY = Enum.RenderPriority.Camera.Value + 1

local POSITION_INFLUENCE = Vector3.new(0.15, 0.15, 0.15)
local ROTATION_INFLUENCE = Vector3.new(1, 1, 1)

--// VARIABLES
local camera: Camera = workspace.CurrentCamera :: Camera

local zeroVector: Vector3 = Vector3.zero

local shakes: { [string]: Shake } = {}
local Module = {}

local active: boolean = false

--// FUNCTIONS
local function startFadeIn(shake: Shake): ()
	if shake.FadeInDuration == 0 then
		shake.FadeTime = 1
		shake.FadingIn = false
		shake.Sustain = true
	else
		shake.FadeTime = 0
		shake.FadingIn = true
		shake.Sustain = false
	end

	shake.FadingOut = false
end

local function startFadeOut(shake: Shake): ()
	if shake.FadeOutDuration == 0 then
		shake.FadeTime = 0
		shake.FadingOut = false
	else
		shake.FadeTime = 1
		shake.FadingOut = true
	end

	shake.FadingIn = false
	shake.Sustain = false
end

local function isShakeInactive(shake: Shake): boolean
	if shake.Sustain then
		return false
	elseif shake.FadingIn or shake.FadingOut then
		return false
	else
		return true
	end
end

local function updateFadeTime(shake: Shake, deltaTime: number): number
	local fadeTime: number = shake.FadeTime

	if shake.FadingIn then
		fadeTime += deltaTime / shake.FadeInDuration
		if fadeTime >= 1 then
			shake.Sustain = true
			shake.FadingIn = false :: any
		end
	elseif shake.FadingOut then
		fadeTime -= deltaTime / shake.FadeOutDuration
		if fadeTime <= 0 then
			shake.Sustain = false
			shake.FadingOut = false :: any
		end
	end

	shake.FadeTime = fadeTime
	return fadeTime
end

local function updateTick(shake: Shake, fadeTime: number, deltaTime: number): number
	local _tick: number = shake.Tick
	if shake.Sustain then
		_tick += deltaTime * shake.Roughness
	else
		_tick += deltaTime * shake.Roughness * fadeTime
	end

	shake.Tick = _tick
	return _tick
end

local function updateShake(shake: Shake, deltaTime: number): Vector3
	local fadeTime: number = updateFadeTime(shake, deltaTime)
	local _tick: number = updateTick(shake, fadeTime, deltaTime)

	return Vector3.new(math.noise(_tick, 0) * 0.5, math.noise(0, _tick) * 0.5, math.noise(0, 0, _tick) * 0.5)
		* shake.Magnitude
		* fadeTime
end

local function renderStep(deltaTime: number): ()
	local positionAdd: Vector3 = zeroVector
	local rotationAdd: Vector3 = zeroVector
	local cameraPosition: Vector3 = camera.CFrame.Position

	for id: string, shake: Shake in pairs(shakes) do
		if isShakeInactive(shake) then
			shakes[id] = nil
		else
			local distanceMod: number = 1
			local origin: Origin?, radius: number? = shake.Origin, shake.Radius
			if origin and radius then
				if typeof(origin) ~= "Vector3" then
					if origin:IsA("BasePart") then
						origin = origin.Position
					elseif origin:IsA("Attachment") then
						origin = origin.WorldPosition
					end
				end

				local distance: number = (origin :: Vector3 - cameraPosition).Magnitude
				if distance > radius then
					local fadeTime: number = updateFadeTime(shake, deltaTime)
					updateTick(shake, fadeTime, deltaTime)
					continue
				else
					distanceMod -= distance / radius
				end
			end

			local add: Vector3 = updateShake(shake, deltaTime) * distanceMod
			positionAdd += add * (shake.PositionInfluence or POSITION_INFLUENCE)
			rotationAdd += add * (shake.RotationInfluence or ROTATION_INFLUENCE)
		end
	end

	if active and Sift.isEmpty(shakes) then
		RunService:UnbindFromRenderStep("CameraShaker")
		active = false
	end

	camera.CFrame *= CFrame.new(positionAdd) * CFrame.fromOrientation(
		math.rad(rotationAdd.X),
		math.rad(rotationAdd.Y),
		math.rad(rotationAdd.Z)
	)
end

--// MODULE FUNCTIONS
function Module.MakeParams(
	magnitude: number,
	roughness: number,
	fadeOutDuration: number?,
	fadeInDuration: number?,
	positionInfluence: Vector3?,
	rotationInfluence: Vector3?
): Params
	return {
		Magnitude = magnitude,
		Roughness = roughness,
		FadeInDuration = fadeInDuration or 0,
		FadeOutDuration = fadeOutDuration or 0,
		PositionInfluence = positionInfluence or POSITION_INFLUENCE,
		RotationInfluence = rotationInfluence or ROTATION_INFLUENCE,
	}
end

function Module.Start(params: Params, duration: number?, origin: (Vector3 | BasePart)?, radius: number?): string
	local shake: Shake = Sift.Dictionary.copyDeep(params) :: Shake
	shake.Tick = Utility.GetRandomNumber(-100, 100, false)

	if origin then
		shake.Origin = origin
		shake.Radius = radius
	end

	local id: string = HttpService:GenerateGUID(false)
	shakes[id] = shake

	startFadeIn(shake)

	if duration then
		task.delay(duration, function()
			Module.Stop(id, false)
		end)
	end

	if not active then
		active = true
		RunService:BindToRenderStep("CameraShaker", RENDER_PRIORITY, renderStep)
	end

	return id
end

function Module.Stop(id: string, abruptly: boolean): ()
	local shake: Shake? = shakes[id]
	if not shake then
		warn("Can't find a shake with the given ID")
		return
	end

	if abruptly then
		shakes[id] = nil
	elseif not shake.FadingOut then
		startFadeOut(shake)
	end
end

return Module
