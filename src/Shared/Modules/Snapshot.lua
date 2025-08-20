--!strict
--// TYPES
export type Data = {
	Timestamp: number,
	Value: CFrame
}

--// CONSTANTS
local MAX_LENGTH = 30
local MAX_T = 256
local HALF_T = MAX_T // 2

--// CLASS
local Snapshot = {}
Snapshot.__index = Snapshot

type SnapshotData = {
	Cache: { Data },
	PivotIndex: number?
}
export type Snapshot = setmetatable<SnapshotData, typeof(Snapshot)>

--// VARIABLES
local Module = {}

--// FUNCTIONS
local function isGreater(t1: number, t2: number): boolean
	local delta: number = (t2 - t1) % MAX_T
	return delta > 0 and delta <= HALF_T
end

--// CLASS FUNCTIONS
function Snapshot.Push(self: Snapshot, timestamp: number, value: CFrame): ()
	local data: Data = {
		Timestamp = timestamp,
		Value = value,
	}

	local cache: { Data } = self.Cache
	local pivotIndex: number? = self.PivotIndex
	if not pivotIndex then
		cache[1] = data
		self.PivotIndex = 0
		return
	end

	local pivotValue: number = cache[pivotIndex + 1].Timestamp
	if isGreater(pivotValue, timestamp) then
		local nextIndex: number = (pivotIndex + 1) % MAX_LENGTH
		cache[nextIndex + 1] = data
		self.PivotIndex = nextIndex
		return
	end

	local nextIndex: number = (pivotIndex - 1) % MAX_LENGTH
	local currentValue: Data = data

	while nextIndex ~= pivotIndex and currentValue do
		local snapshotEntry: Data? = cache[nextIndex + 1]
		if not snapshotEntry or isGreater(snapshotEntry.Timestamp, currentValue.Timestamp) then
			cache[nextIndex + 1] = currentValue
			currentValue = snapshotEntry :: Data
		end

		nextIndex = (nextIndex - 1) % MAX_LENGTH
	end
end

function Snapshot.GetLatest(self: Snapshot): Data?
	local pivotIndex: number? = self.PivotIndex
	if pivotIndex then
		return self.Cache[pivotIndex + 1]
	else
		return nil
	end
end

function Snapshot.GetBefore(self: Snapshot, before: number): Data?
	local pivotIndex: number? = self.PivotIndex
	if not pivotIndex then
		return nil
	end

	local cache: { Data } = self.Cache
	local currentIndex: number = pivotIndex

	repeat
		local value: Data? = cache[currentIndex + 1]
		if not value then
			return nil
		end

		if isGreater(value.Timestamp, before) then
			return value
		end

		currentIndex = (currentIndex - 1) % MAX_LENGTH
	until currentIndex == pivotIndex

	return nil
end

function Snapshot.GetAfter(self: Snapshot, after: number): Data?
	local pivotIndex: number? = self.PivotIndex
	if not pivotIndex then
		return nil
	end

	local currentIndex: number = (pivotIndex + 1) % MAX_LENGTH
	local cache: { Data } = self.Cache

	repeat
		local value = cache[currentIndex + 1]

		if value and isGreater(after, value.Timestamp) then
			return value
		end

		currentIndex = (currentIndex + 1) % MAX_LENGTH
	until currentIndex == (pivotIndex + 1) % MAX_LENGTH

	return nil
end

function Snapshot.GetAt(self: Snapshot, at: number): CFrame?
	local pivotIndex: number? = self.PivotIndex
	if not pivotIndex then
		return nil
	end

	local cache: { Data } = self.Cache
	if #cache == 1 then
		return cache[pivotIndex + 1].Value
	end

	local before: Data? = self:GetBefore(at)
	local after: Data? = self:GetAfter(at)

	if before and after then
		if before == after then
			return before.Value
		end

		local beforeTime: number = before.Timestamp
		local afterTime: number = after.Timestamp
		if beforeTime > afterTime then
			afterTime += 256
		end

		if beforeTime > at then
			at += 256
		end

		local alpha: number = math.map(at, beforeTime, afterTime, 0, 1)
		return before.Value:Lerp(after.Value, alpha)
	elseif before then
		warn("Tried to fetch a time that was ahead of snapshot storage!")
		return before.Value
	elseif after then
		warn("Tried to fetch a time that was behind  snapshot storage!")
		return after.Value
	end

	return nil
end

function Snapshot.Clear(self: Snapshot): ()
	self.Cache = {}
	self.PivotIndex = nil
end

--// MODULE FUNCTIONS
function Module.new(): Snapshot
	return setmetatable({
		Cache = {}
	} :: SnapshotData, Snapshot)
end

return Module