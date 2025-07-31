--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// CONSTANTS
local VISUALIZE = true
local VISUALIZATION_LIFETIME = 0.1

--// VARIABLES
local visualizationsFolder: Folder = workspace.Ignore.HitboxVisualisations

local template: Part = ReplicatedStorage.Miscellaneous.HitboxVisualization

local xAngles90: CFrame = CFrame.Angles(math.rad(90), 0, 0)

local Module = {}

--// FUNCTIONS
local function makePart(size: Vector3, cframe: CFrame): Part
	local part: Part = template:Clone()
	part.Size = size
	part.CFrame = cframe
	return part
end

local function isEnabled(visualize: boolean?): boolean
	if visualize or (visualize == nil and VISUALIZE) then
		return true
	else
		return false
	end
end

local function showVisualization(visualization: Part): ()
	visualization.Parent = visualizationsFolder

	task.delay(VISUALIZATION_LIFETIME, function()
		visualization:Destroy()
	end)
end

--// MODULE PROPERTIES
Module.Folder = visualizationsFolder

--// MODULE FUNCTIONS
Module.MakePart = makePart
Module.IsEnabled = isEnabled
Module.Show = showVisualization

function Module.Raycast(origin: Vector3, direction: Vector3, show: boolean?): ()
	local visualization: Part =
		makePart(Vector3.new(0.5, 0.5, direction.Magnitude), CFrame.lookAlong(origin + direction / 2, direction))
	if isEnabled(show) then
		showVisualization(visualization, show)
	end
end

function Module.Spherecast(origin: Vector3, direction: Vector3, radius: number, show: boolean?): ()
	local visualization: Part = makePart(
		Vector3.new(direction.Magnitude, radius, radius),
		CFrame.lookAlong(origin + direction / 2, direction) * xAngles90
	)
	if isEnabled(show) then
		showVisualization(visualization, show)
	end
end

function Module.SpatialQuery(cframe: CFrame, size: Vector3, show: boolean?): ()
	local visualization: Part = makePart(size, cframe)
	if isEnabled(show) then
		showVisualization(visualization, show)
	end
end

function Module.PreciseSpatialQuery(part: BasePart, show: boolean?): ()
	local visualization: Part = makePart(part.Size, part.CFrame)
	if isEnabled(show) then
		showVisualization(visualization, show)
	end
end

return Module
