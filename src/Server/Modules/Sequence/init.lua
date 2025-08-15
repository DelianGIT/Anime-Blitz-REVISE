--!strict
--// MODULES
local Track = require(script.Track)

--// TYPES
type Keyframe = Track.Keyframe
type Track = Track.Track

--// CLASS
local Sequence = {}
Sequence.__index = Sequence

type SequenceData = {
	Keyframes: { Keyframe },
	Tracks: { [string]: Track },
}
export type Sequence = setmetatable<SequenceData, typeof(Sequence)>

--// VARIABLES
local Module = {}

--// FUNCTIONS
local function sortKeyframes(keyframes: { [number]: (...any) -> () }): { Keyframe }
	local framesTimestamps: { number } = {}

	for timestamp: number, _ in pairs(keyframes) do
		table.insert(framesTimestamps, timestamp)
	end

	table.sort(framesTimestamps, function(a: number, b: number)
		return a < b
	end)

	local result = {}
	for _, value in ipairs(framesTimestamps) do
		table.insert(result, {
			Time = value,
			Function = keyframes[value],
		})
	end

	return result
end

--// CLASS FUNCTIONS
function Sequence.Play(self: Sequence, args: any): Track
	local track: Track = self:CreateTrack()
	track:Play(args)
	return track
end

function Sequence.CreateTrack(self: Sequence): Track
	return Track.new(self.Keyframes)
end

--// MODULE FUNCTIONS
function Module.new(keyframes: { [number]: (...any) -> () }): Sequence
	local sortedKeyframes: { Keyframe } = sortKeyframes(keyframes)
	return setmetatable({
		Keyframes = sortedKeyframes,
		Tracks = {},
	}, Sequence)
end

return Module