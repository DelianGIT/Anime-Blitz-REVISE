--!strict
--// SERVICES
local RunService = game:GetService("RunService")

--// MODULES
local Visualization = require(script.Parent.Visualization)

--// TYPES
export type Hit = Model | BasePart
export type Hits = { Model } | { BasePart }
type Target = "Players" | "NPCs" | "Living" | "Map"
export type Params<T> = {
	Target: Target,
	Params: T?,
	Blacklist: { Instance }?,
}
export type CustomRaycastResult = {
	Normal: Vector3,
	Position: Vector3,
	Instance: Hit,
	Distance: number,
}

local LIVING_RAYCAST_PARAMS = RaycastParams.new()
LIVING_RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Include
LIVING_RAYCAST_PARAMS.FilterDescendantsInstances = {
	workspace.Living.NPCs,
	if RunService:IsServer() then workspace.CurrentCamera else workspace.Living.Players,
}

local PLAYERS_RAYCAST_PARAMS = RaycastParams.new()
PLAYERS_RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Include
PLAYERS_RAYCAST_PARAMS.FilterDescendantsInstances = {
	if RunService:IsServer() then workspace.CurrentCamera else workspace.Living.Players,
}

local NPCS_RAYCAST_PARAMS = RaycastParams.new()
NPCS_RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Include
NPCS_RAYCAST_PARAMS.FilterDescendantsInstances = {
	workspace.Living.NPCs,
}

local MAP_RAYCAST_PARAMS = RaycastParams.new()
MAP_RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Include
MAP_RAYCAST_PARAMS.FilterDescendantsInstances = {
	workspace.Map,
}

local ALL_RAYCAST_PARAMS = RaycastParams.new()
ALL_RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Include
ALL_RAYCAST_PARAMS.FilterDescendantsInstances = {
	workspace.Living.NPCs,
	if RunService:IsServer() then workspace.CurrentCamera else workspace.Living.Players,
	workspace.Map,
}

local LIVING_OVERLAP_PARAMS = OverlapParams.new()
LIVING_OVERLAP_PARAMS.FilterType = Enum.RaycastFilterType.Include
LIVING_OVERLAP_PARAMS.FilterDescendantsInstances = {
	workspace.Living.NPCs,
	if RunService:IsServer() then workspace.CurrentCamera else workspace.Living.Players,
}

local PLAYERS_OVERLAP_PARAMS = OverlapParams.new()
PLAYERS_OVERLAP_PARAMS.FilterType = Enum.RaycastFilterType.Include
PLAYERS_OVERLAP_PARAMS.FilterDescendantsInstances = {
	if RunService:IsServer() then workspace.CurrentCamera else workspace.Living.Players,
}

local NPCS_OVERLAP_PARAMS = OverlapParams.new()
NPCS_OVERLAP_PARAMS.FilterType = Enum.RaycastFilterType.Include
NPCS_OVERLAP_PARAMS.FilterDescendantsInstances = {
	workspace.Living.NPCs,
}

local MAP_OVERLAP_PARAMS = OverlapParams.new()
MAP_OVERLAP_PARAMS.FilterType = Enum.RaycastFilterType.Include
MAP_OVERLAP_PARAMS.FilterDescendantsInstances = {
	workspace.Map,
}

--// VARIABLES
local livingFolder = workspace.Living
local playersFolder: Folder = livingFolder.Players
local npcsFolder: Folder = livingFolder.NPCs
local replicatorsFolder: Camera? = if RunService:IsServer() then workspace.CurrentCamera else nil

local raycastParamsStorage: { [Target]: RaycastParams } = {
	Players = PLAYERS_RAYCAST_PARAMS,
	NPCs = NPCS_RAYCAST_PARAMS,
	Living = LIVING_RAYCAST_PARAMS,
	Map = MAP_RAYCAST_PARAMS,
}
local overlapParamsStorage: { [Target]: OverlapParams } = {
	Players = PLAYERS_OVERLAP_PARAMS,
	NPCs = NPCS_OVERLAP_PARAMS,
	Living = LIVING_OVERLAP_PARAMS,
	Map = MAP_OVERLAP_PARAMS,
}
local Module = {}

--// FUNCTIONS
if RunService:IsServer() then
	function getCharacterFromInstance(instance: Instance): Model?
		local character: Instance = instance
		local parent: Instance = instance.Parent :: Instance

		repeat
			character = parent
			parent = character.Parent :: Instance
		until parent == replicatorsFolder or parent == npcsFolder or parent == workspace

		if parent == workspace then
			return nil
		elseif parent == replicatorsFolder then
			return playersFolder:FindFirstChild(character.Name) :: Model?
		else
			return character :: Model?
		end
	end
else
	function getCharacterFromInstance(instance: Instance): Model?
		local character: Instance = instance
		local parent: Instance = instance.Parent :: Instance

		repeat
			character = parent
			parent = character.Parent :: Instance
		until parent == playersFolder or parent == npcsFolder or parent == workspace

		if parent == workspace then
			return nil
		else
			return character :: Model?
		end
	end
end

local function getCharactersFromInstances(instances: { Instance }): { Model }
	local characters: { Model } = {}
	for _, instance: Instance in ipairs(instances) do
		local character: Model? = getCharacterFromInstance(instance)
		if character and not table.find(characters, character) then
			table.insert(characters, character)
		end
	end
	return characters
end

local function filterHit(hit: Hit, blacklist: { Instance }): Hit?
	for _, instance in ipairs(blacklist) do
		if hit:IsDescendantOf(instance) or hit == instance then
			return nil
		end
	end
	return hit
end

local function filterHits(hits: Hits, blacklist: { Instance }): Hits
	local filteredHits: Hits = {}
	for index, hit in ipairs(hits) do
		table.insert(filteredHits, filterHit(hit, blacklist))
	end
	return filteredHits
end

--// MODULE FUNCTIONS
function Module.Raycast(
	origin: Vector3,
	direction: Vector3,
	params: Params<RaycastParams>,
	visualize: boolean?
): CustomRaycastResult?
	Visualization.Raycast(origin, direction, visualize)

	local target: Target = params.Target
	local raycastParams: RaycastParams? = params.Params
	if not raycastParams then
		raycastParams = raycastParamsStorage[target]
	end

	local raycastResult: RaycastResult? = workspace:Raycast(origin, direction, raycastParams)
	if not raycastResult then
		return nil
	end

	local instance: Hit?
	if target == "Players" or target == "Entities" or target == "Living" then
		instance = getCharacterFromInstance(raycastResult.Instance)
	elseif target == "Map" then
		instance = raycastResult.Instance
	end
	if not instance then
		return nil
	end

	local blacklist: { Instance }? = params.Blacklist
	if blacklist then
		instance = filterHit(instance, blacklist)
		if not instance then
			return nil
		end
	end

	return {
		Normal = raycastResult.Normal,
		Position = raycastResult.Position,
		Distance = raycastResult.Distance,
		Instance = instance :: any,
	}
end

function Module.Spherecast(
	origin: Vector3,
	radius: number,
	direction: Vector3,
	params: Params<RaycastParams>,
	visualize: boolean?
): CustomRaycastResult?
	Visualization.Spherecast(origin, direction, radius, visualize)

	local target: Target = params.Target
	local raycastParams: RaycastParams? = params.Params
	if not raycastParams then
		raycastParams = raycastParamsStorage[target]
	end

	local result: RaycastResult? = workspace:Spherecast(origin, radius, direction, raycastParams)
	if not result then
		return nil
	end

	local instance: Hit?
	if target == "Players" or target == "Entities" or target == "Living" then
		instance = getCharacterFromInstance(result.Instance)
	elseif target == "Map" then
		instance = result.Instance
	end
	if not instance then
		return nil
	end

	local blacklist: { Instance }? = params.Blacklist
	if blacklist then
		instance = filterHit(instance, blacklist)
		if not instance then
			return nil
		end
	end

	return {
		Normal = result.Normal,
		Position = result.Position,
		Distance = result.Distance,
		Instance = instance :: any,
	}
end

function Module.SpatialQuery(cframe: CFrame, size: Vector3, params: Params<OverlapParams>, visualize: boolean?): Hits
	Visualization.SpatialQuery(cframe, size, visualize)

	local target: Target = params.Target
	local overlapParams: OverlapParams? = params.Params
	if not overlapParams then
		overlapParams = overlapParamsStorage[target]
	end

	local result: Hits = workspace:GetPartBoundsInBox(cframe, size, overlapParams)
	if target == "Players" or target == "Entities" or target == "Living" then
		result = getCharactersFromInstances(result :: { Instance })
	end

	local blacklist: { Instance }? = params.Blacklist
	if blacklist then
		result = filterHits(result, blacklist)
	end

	return result
end

function Module.PreciseSpatialQuery(part: BasePart, params: Params<OverlapParams>, visualize: boolean?): Hits
	Visualization.PreciseSpatialQuery(part, visualize)

	local target: Target = params.Target
	local overlapParams: OverlapParams? = params.Params
	if not overlapParams then
		overlapParams = overlapParamsStorage[target]
	end

	local result: Hits = workspace:GetPartsInPart(part, overlapParams)
	if target == "Players" or target == "Entities" or target == "Living" then
		result = getCharactersFromInstances(result :: { Instance })
	end

	local blacklist: { Instance }? = params.Blacklist
	if blacklist then
		result = filterHits(result, blacklist)
	end

	return result
end

return Module
