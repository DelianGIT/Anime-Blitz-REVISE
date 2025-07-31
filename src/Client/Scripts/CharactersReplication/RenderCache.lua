--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local Configs = require(ReplicatedStorage.Configs)

--// TYPES
type Data = {
	LastClockAt: number,
	LastClockDuration: number,
	RenderAt: number?,
}

--// CONSTANTS
local TICK_RATE = Configs.TickRate

--// VARIABLES
local clientClockInfo: { [number]: Data } = {}
local Module = {}

local playerTickRates: { [number]: number }, interpolationBuffer: any

--// MODULE FUNCTIONS
function Module.Init(_playerTickRates: { [number]: number }, _interpolationBuffer: any): ()
	playerTickRates = _playerTickRates
	interpolationBuffer = _interpolationBuffer
end

function Module.OnSnapshotUpdate(snapshot: { [number]: number }): ()
	local clock: number = os.clock()

	for id, currentSendTime in pairs(snapshot) do
		local info: Data = clientClockInfo[id]
		if not info then
			info = {
				LastClockAt = currentSendTime,
				LastClockDuration = clock
			} :: Data
			clientClockInfo[id] = info
		end

		if currentSendTime > info.LastClockAt then
			info.LastClockAt = currentSendTime
			info.LastClockDuration = clock

			if not info.RenderAt then
				local _delay: number = interpolationBuffer.GetBuffer(id, playerTickRates[id] or TICK_RATE)
				info.RenderAt = (currentSendTime - _delay) :: any
			end
		end
	end
end

function Module.Update(deltaTime: number): ()
	local clock: number = os.clock()

	for id, info in pairs(clientClockInfo) do
		local tickRate: number = playerTickRates[id] or TICK_RATE
		local _delay: number = interpolationBuffer.GetBuffer(id, tickRate)

		local estimatedServerTime: number = info.LastClockAt + (clock - info.LastClockDuration)
		local renderAt: number = (info.RenderAt or 0) + deltaTime
		local renderTimeError: number = _delay - (estimatedServerTime - renderAt)

		if math.abs(renderTimeError) > 0.1 then
			renderAt = estimatedServerTime - _delay
		elseif renderTimeError > 0.01 then
			renderAt = math.max(estimatedServerTime - _delay, renderAt - 0.1 * deltaTime)
		elseif renderTimeError < -0.01 then
			renderAt = math.min(estimatedServerTime - _delay, renderAt + 0.1 * deltaTime)
		end

		info.RenderAt = renderAt
	end
end

function Module.GetTargetRenderTime(id: number): number
	local info: Data? = clientClockInfo[id]
	if not info then
		warn(`RenderCache: No render time for network ID {id}`)
		return 0
	end

	local renderAt: number? = info.RenderAt
	if not renderAt then
		warn(`RenderCache: No render time for network ID {id}`)
		return 0
	end

	return renderAt
end

function Module.GetEstimatedServerTime(id: number): number
	local info: Data? = clientClockInfo[id]
	if info then
		return info.LastClockAt + (os.clock() - info.LastClockDuration)
	else
		warn(`RenderCache: No estimated server time for network ID {id}`)
		return 0
	end
end

function Module.Add(id: number)
	if not clientClockInfo[id] then
		clientClockInfo[id] = {
			LastClockAt = 0,
			LastClockDuration = 0
		}
	end
end

function Module.Remove(id: number)
	clientClockInfo[id] = nil
end

return Module