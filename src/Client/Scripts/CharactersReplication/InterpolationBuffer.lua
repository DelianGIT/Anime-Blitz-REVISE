--!strict
--// MODULES
local RenderCache = require(script.Parent.RenderCache)

--// TYPES
type Data = {
	AverageLatency: number,
	Deviation: number,
	LastLatency: number?
}

--// CONSTANTS
local MIN_BUFFER = 0.09
local MAX_BUFFER = 0.5
local FIX = 0.2
local RECOVERY = 0.5
local ALPHA = 0.1

--// VARIABLES
local playerLatencies: { [number]: Data } = {}
local Module = {}

--// MODULE FUNCTIONS
function Module.RegisterPacket(networkId: number, serverTime: number): ()
	local clientNow: number = RenderCache.GetEstimatedServerTime(networkId)
	local latency: number = clientNow - serverTime
	if latency > 1 then
		playerLatencies[networkId] = nil

		RenderCache.Remove(networkId)
		RenderCache.Add(networkId)

		warn(`{networkId} latency too high, cleared cache to repredict in case of error:! {latency}`)
	end

	local data: Data? = playerLatencies[networkId]
	if not data then
		playerLatencies[networkId] = {
			AverageLatency = latency,
			Deviation = 0,
			LastLatency = latency
		}
		return
	end

	local lastLatency: number? = data.LastLatency
	if lastLatency then
		local delta: number = math.abs(latency - lastLatency)
		data.Deviation = data.Deviation * (1 - FIX) + delta * FIX
	end

	data.AverageLatency = data.AverageLatency * (1 - ALPHA) + latency * ALPHA
	data.LastLatency = latency
end

function Module.GetBuffer(networkId: number, tickRate: number): number
	local data: Data? = playerLatencies[networkId]
	if not data then
		return MIN_BUFFER
	end

	local recoveryMargin: number = tickRate * RECOVERY
	local rawBuffer: number = data.AverageLatency + data.Deviation + recoveryMargin

	local _buffer: number
	if rawBuffer < MIN_BUFFER then
		_buffer = MIN_BUFFER + (MIN_BUFFER - rawBuffer)
	else
		_buffer = rawBuffer
	end

	if _buffer > MAX_BUFFER then
		warn(`Interpolation buffer exceeded max! Was {_buffer}, clamped to {MAX_BUFFER}`)
		_buffer = MAX_BUFFER
	end

	return _buffer
end

return Module