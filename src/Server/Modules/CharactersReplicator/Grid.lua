--!strict
--// TYPES
type GridCell = { [string]: { Model } }
type Grid = { [vector]: GridCell }

--// CONSTANTS
local GRID_SIZE = 50
local UPDATE_INTERVAL = 2

--// VARIABLES
local lastPositions: { [Model]: vector } = {}
local entities: { [Model]: string } = {}
local grid: Grid = {}
local Module = {}

local lastUpdate: number = 0

--// FUNCTIONS
local function hashPosition(position: Vector3): vector
	return vector.create(position.X // GRID_SIZE + 0.5, 0, position.Z // GRID_SIZE + 0.5)
end

local function dotMagnitude(position: Vector3): number
	return position:Dot(position)
end

local function processEntities(
	entitiesTable: { Model },
	position: Vector3,
	rangeSquared: number,
	nearbyEntities: { Model }
)
	for _, entity in entitiesTable do
		local entityPosition: Vector3 = entity:GetPivot().Position
		if dotMagnitude(entityPosition - position) <= rangeSquared then
			table.insert(nearbyEntities, entity)
		end
	end
end

local function processCell(
	cell: GridCell,
	entityTypes: { string }?,
	position: Vector3,
	rangeSquared: number,
	nearbyEntities: { Model }
)
	if entityTypes then
		for _, entityType in ipairs(entityTypes) do
			local entitiesTable = cell[entityType]
			if entitiesTable then
				processEntities(entitiesTable, position, rangeSquared, nearbyEntities)
			end
		end
	else
		for _, entitiesTable in pairs(cell) do
			processEntities(entitiesTable, position, rangeSquared, nearbyEntities)
		end
	end
end

local function removeOld(entity: Model, entityType: string, lastHash: vector): ()
	local oldCell: GridCell = grid[lastHash]
	if not oldCell then
		return
	end

	local index: number? = table.find(oldCell[entityType], entity)
	if not index then
		return
	end

	local entitiesInCell: { Model } = oldCell[entityType]
	table.remove(entitiesInCell, index)

	if #entitiesInCell == 0 then
		oldCell[entityType] = nil
	end

	if not next(oldCell) then
		grid[lastHash] = nil
	end
end

local function addNew(entity: Model, entityType: string, hash: vector): ()
	local cell: GridCell = grid[hash]
	if not cell then
		cell = {}
		grid[hash] = cell
	end

	local entitiesInCell: { Model } = cell[entityType]
	if not entitiesInCell then
		entitiesInCell = {}
		cell[entityType] = entitiesInCell
	end

	table.insert(entitiesInCell, entity)
	lastPositions[entity] = hash
end

--// MODULE FUNCTIONS
function Module.UpdateGrid(): ()
	local currentTime: number = os.clock()
	if currentTime - lastUpdate < UPDATE_INTERVAL then
		return
	end

	for entity, entityType in pairs(entities) do
		local position: Vector3 = entity:GetPivot().Position
		local hash: vector = hashPosition(position)

		local lastHash: vector = lastPositions[entity]
		if lastHash == hash then
			continue
		end
		if lastHash then
			removeOld(entity, entityType, lastHash)
		end

		addNew(entity, entityType, hash)
	end

	lastUpdate = currentTime
end

function Module.QueryGrid(position: Vector3, range: number, entityTypes: { string }?): { Model }
	Module.UpdateGrid()

	local rangeInCells: number = math.ceil(range / GRID_SIZE)
	local hash: vector = hashPosition(position)

	local startX: number, startZ: number = hash.x - rangeInCells, hash.z - rangeInCells
	local endX: number, endZ: number = hash.x + rangeInCells, hash.z + rangeInCells

	local nearbyEntities: { Model } = {}
	local rangeSquared: number = range ^ 2

	for xCell = startX, endX do
		for zCell = startZ, endZ do
			local cellKey: vector = vector.create(xCell, 0, zCell)
			local cell: GridCell = grid[cellKey]
			if cell then
				processCell(cell, entityTypes, position, rangeSquared, nearbyEntities)
			end
		end
	end

	return nearbyEntities
end

function Module.GetNearbyEntities(model: Model?, range: number, entityTypes: { string }?): { Model }
	if model then
		local position: Vector3 = model:GetPivot().Position
		return Module.QueryGrid(position, range, entityTypes)
	else
		warn("Model is nil")
		return {}
	end
end

function Module.AddEntity(entity: Model, entityType: string): ()
	entities[entity] = entityType
end

function Module.RemoveEntity(entity: Model): ()
	entities[entity] = nil
	lastPositions[entity] = nil
end

return Module