--!strict
--// TYPES
type GridCell = { [string]: { Model } }

--// CONSTANTS
local GRID_SIZE = 50
local UPDATE_INTERVAL = 2

--// VARIABLES
local entities: { [Model]: string } = {}
local lastPositions: { [Model]: vector } = {}
local grid: { [vector]: GridCell } = {}
local Module = {}

local lastUpdate = 0

--// FUNCTIONS
local function hashPosition(position: Vector3 | vector): vector
	if typeof(position) == "Vector3" then
		return vector.create(position.X // GRID_SIZE + 0.5, 0, position.Z // GRID_SIZE + 0.5)
	else
		return vector.create(position.x // GRID_SIZE + 0.5, 0, position.z // GRID_SIZE + 0.5)
	end
end

local function dotMagnitude(position: Vector3): number
	return position:Dot(position)
end

local function removeOld(entity: Model, entityType: string, lastHash: vector): ()
	local oldCell: GridCell? = grid[lastHash]
	if not oldCell then
		return
	end

	local entitiesTable: { Model } = oldCell[entityType]
	local index: number? = table.find(entitiesTable, entity)
	if not index then
		return
	end

	table.remove(entitiesTable, index)

	if #entitiesTable == 0 then
		oldCell[entityType] = nil
	end

	if next(oldCell) == nil then
		grid[lastHash] = nil
	end
end

local function addNew(entity: Model, entityType: string, hash: vector): ()
	local cell: GridCell = grid[hash]
	if not cell then
		cell = {}
		grid[hash] = cell
	end

	local entitiesTable: { Model } = cell[entityType]
	if not entitiesTable then
		entitiesTable = {}
		cell[entityType] = entitiesTable
	end

	table.insert(entitiesTable, entity)
	lastPositions[entity] = hash
end

local function processEntities(
	entitiesTable: { Model },
	position: Vector3,
	rangeSquared: number,
	nearbyEntities: { Model }
): ()
	for _, entity in ipairs(entitiesTable) do
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
): ()
	if entityTypes then
		for _, entityType in ipairs(entityTypes) do
			local entitiesTable = cell[entityType]
			if entitiesTable then
				processEntities(entitiesTable, position, rangeSquared, nearbyEntities)
			end
		end
	else
		for _, entitiesTable in cell do
			processEntities(entitiesTable, position, rangeSquared, nearbyEntities)
		end
	end
end

--// MODULE FUNCTIONS
function Module.UpdateGrid()
	local clock: number = os.clock()
	if clock - lastUpdate < UPDATE_INTERVAL then
		return
	end

	for entity, entityType in entities do
		local position: Vector3 = entity:GetPivot().Position
		local hash: vector = hashPosition(position)
		local lastHash: vector? = lastPositions[entity]

		if lastHash ~= hash then
			if lastHash then
				removeOld(entity, entityType, lastHash)
			end

			addNew(entity, entityType, hash)
		end
	end

	lastUpdate = clock
end

function Module.QueryGrid(position: Vector3, range: number, entityTypes: { string }?): { Model }
	Module.UpdateGrid()

	local rangeInCells: number = math.ceil(range / GRID_SIZE)
	local hash: vector = hashPosition(position)

	local x: number, z: number = hash.x, hash.z
	local startX: number, startZ: number = x - rangeInCells, z - rangeInCells
	local endX: number, endZ: number = x + rangeInCells, z + rangeInCells

	local nearbyEntities: { Model } = {}
	local rangeSquared: number = range ^ 2

	for xCell = startX, endX do
		for zCell = startZ, endZ do
			local cellKey: vector = vector.create(xCell, 0, zCell)
			local cell: GridCell? = grid[cellKey]
			if cell then
				processCell(cell, entityTypes, position, rangeSquared, nearbyEntities)
			end
		end
	end

	return nearbyEntities
end

function Module.AddEntity(entity: Model, entityType: string): ()
	entities[entity] = entityType
end

function Module.RemoveEntity(entity: Model): ()
	entities[entity] = nil
	lastPositions[entity] = nil
end

function Module.GetNearbyEntities(model: Model?, range: number, entityTypes: { string }?): { any }
	if model then
		local position: Vector3 = model:GetPivot().Position
		return Module.QueryGrid(position, range, entityTypes)
	else
		return {}
	end
end

return Module