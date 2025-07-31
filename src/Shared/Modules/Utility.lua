--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local Hitbox = require(SharedModules.Hitbox)

--// VARIABLES
local random: Random = Random.new(tick())

local minusAnglesX90: CFrame = CFrame.Angles(math.rad(-90), 0, 0)
local anglesX90: CFrame = CFrame.Angles(math.rad(90), 0, 0)

local Module = {}

--// MODULE FUNCTIONS
function Module.CloneInstance<T>(instance: T, parent: Instance?, positionOrCFrame: (Vector3 | CFrame)?): T
	local clonedInstance = (instance :: Instance):Clone()

	if positionOrCFrame then
		if clonedInstance:IsA("Model") and typeof(positionOrCFrame) == "CFrame" then
			clonedInstance:PivotTo(positionOrCFrame)
		elseif clonedInstance:IsA("BasePart") then
			if typeof(positionOrCFrame) == "Vector3" then
				clonedInstance.Position = positionOrCFrame
			elseif typeof(positionOrCFrame) == "CFrame" then
				clonedInstance.CFrame = positionOrCFrame
			end
		end
	end

	clonedInstance.Parent = parent
	return instance
end

function Module.DelayDestruction(delayTime: number, instance: Instance): ()
	task.delay(delayTime, function()
		instance:Destroy()
	end)
end

function Module.GetRandomNumber(min: number, max: number, decimals: boolean): number
	if decimals then
		return random:NextNumber(min, max)
	else
		return random:NextInteger(min, max)
	end
end

function Module.GetFloorNormalAndPosition(origin: Vector3, length: number, yOffset: number?): (Vector3?, Vector3?)
	if yOffset then
		origin += Vector3.new(0, yOffset, 0)
	end

	local result: Hitbox.RaycastResult? = Hitbox.Raycast(origin, Vector3.new(0, -length, 0), {
		Target = "Map",
	}, false)

	if result then
		return result.Normal, result.Position
	else
		return nil, nil
	end
end

function Module.GetCFrameFromNormal(
	normal: Vector3,
	position: Vector3,
	upVector: Vector3?,
	upsideDown: Vector3?
): CFrame
	local lookAlong: CFrame
	if upsideDown then
		if upVector then
			lookAlong = CFrame.lookAlong(position, normal, upVector) * anglesX90
		else
			lookAlong = CFrame.lookAlong(position, normal) * anglesX90
		end
	else
		if upVector then
			lookAlong = CFrame.lookAlong(position, normal, upVector) * minusAnglesX90
		else
			lookAlong = CFrame.lookAlong(position, normal) * minusAnglesX90
		end
	end

	local x: number, y: number, z: number = lookAlong:ToOrientation()
	if math.abs(math.deg(x)) < 0.001 then
		x = 0
	end

	return CFrame.new(position) * CFrame.fromEulerAnglesYXZ(x, y, z)
end

return Module
