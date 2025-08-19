--!strict
--// SERVICES

--// TYPES
export type Data = {
	Timestamp: number,
	Value: CFrame,
}

--// CLASS
local Snapshot = {}
Snapshot.__index = Snapshot

type SnapshotData = {
	Cache: { Data },
	PivotIndex: number?,
}
export type Snapshot = setmetatable<SnapshotData, typeof(Snapshot)>

--// TYPES
local MAX_LENGTH = 30
local MAX_T = 256

--// VARIABLES
local halfT: number = MAX_T // 2

local Module = {}

--// FUNCTIONS
local function isGreater(t1: number, t2: number): boolean
	local delta: number = (t2 - t1) % MAX_T
	return delta > 0 and delta <= halfT
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

	local pivotTimestamp: number = cache[pivotIndex + 1].Timestamp
	if isGreater(pivotTimestamp, timestamp) then
		local nextIndex: number = (pivotIndex + 1) % MAX_LENGTH
		cache[nextIndex + 1] = data
		self.PivotIndex = nextIndex
	else
		local nextIndex: number = (pivotIndex - 1) % MAX_LENGTH
		local currentValue: Data? = data

		while nextIndex ~= pivotIndex and currentValue ~= nil do
			local snapshotEntry: Data? = cache[nextIndex + 1]
			if not snapshotEntry or isGreater(snapshotEntry.Timestamp, currentValue.Timestamp) then
				cache[nextIndex + 1] = currentValue
				currentValue = snapshotEntry :: Data
			end

			nextIndex = (nextIndex - 1) % MAX_LENGTH
		end
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
		local data: Data? = cache[currentIndex + 1]
		if not data then
			return nil
		end

		if isGreater(data.Timestamp, before) then
			return data
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

	local cache: { Data } = self.Cache
	local currentIndex: number = (pivotIndex + 1) % MAX_LENGTH
	local maxIndex: number = currentIndex

	repeat
		local data: Data? = cache[currentIndex + 1]
		if data and isGreater(after, data.Timestamp) then
			return data
		end

		currentIndex = (currentIndex + 1) % MAX_LENGTH
	until currentIndex == maxIndex

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

		local beforeTimestamp: number = before.Timestamp
		local afterTimestamp: number = after.Timestamp
		if beforeTimestamp > afterTimestamp then
			afterTimestamp += 256
		end

		if beforeTimestamp > at then
			at += 256
		end

		local alpha: number = math.map(at, beforeTimestamp, afterTimestamp, 0, 1)
		return before.Value:Lerp(after.Value, alpha)
	elseif before then
		return before.Value
	elseif after then
		return after.Value
	else
		return nil
	end
end

--// MODULE FUNCTIONS
function Module.new(): Snapshot
	return setmetatable({
		Cache = {},
	}, Snapshot) :: Snapshot
end

return Module
