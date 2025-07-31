--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local Signal = require(SharedModules.Signal)

--// TYPES
export type Keyframe = {
	Timestamp: number,
	Function: (args: any, additionalArgs: any) -> (),
}

--// CLASS
local Track = {}
Track.__index = Track

type TrackData = {
	Keyframes: { Keyframe },
	Completed: Signal.Signal<boolean, string?>,
	Heartbeat: RBXScriptConnection?
}
export type Track = setmetatable<TrackData, typeof(Track)>

--// VARIABLES
local Module = {}

--// CLASS FUNCTIONS
function Track.Play(self: Track, args: any)
	if self.Heartbeat then
		warn(`Track is already playing`)
		return
	end

	local keyframes: { Keyframe } = self.Keyframes
	local keyframeIndex: number = 1
	local keyframe: Keyframe = keyframes[keyframeIndex]
	local timestamp: number = keyframe.Timestamp

	local passedTime: number = 0
	local heartbeat: RBXScriptConnection
	heartbeat = RunService.Heartbeat:Connect(function(deltaTime: number)
		passedTime += deltaTime
		if passedTime < timestamp then
			return
		end
		
		keyframeIndex += 1
		keyframe = keyframes[keyframeIndex]
		if keyframe then
			timestamp = keyframe.Timestamp
		else
			heartbeat:Disconnect()
		end

		local success: boolean, errorMessage: string? = (pcall :: any)(keyframe.Function, args)
		if not success then
			if heartbeat.Connected then
				heartbeat:Disconnect()
			end
			self.Completed:Fire(success, errorMessage)
		elseif not heartbeat.Connected then
			self.Completed:Fire(success, errorMessage)
		end
	end)
	self.Heartbeat = heartbeat
end

function Track.Stop(self: Track)
	local heartbeat: RBXScriptConnection? = self.Heartbeat
	if heartbeat then
		heartbeat:Disconnect()
		self.Heartbeat = nil
	else
		warn(`Track isn't playing`)
	end
end

--// MODULE FUNCTIONS
function Module.new(keyframes: { Keyframe }): Track
	return setmetatable({
		Keyframes = keyframes,
		Completed = Signal.new()
	}, Track) :: Track
end

return Module