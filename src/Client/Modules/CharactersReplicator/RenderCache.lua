--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local NpcReplicationConfigs = require(SharedModules.NpcReplicationConfigs)

local Configs = require(ReplicatedStorage.Configs)

local InterpolationBuffer: any

--// TYPES
type ClockInfo = {
	LastClockAt: number,
	LastClockDuration: number,
	RenderAt: number?,
}

--// CONSTANTS
local TICK_RATE = Configs.TickRate

--// VARIABLES
local clientClockInfo: { [number]: ClockInfo } = {}
local isNPCMap: { [number]: boolean } = {}
local npcTypeMap: { [number]: string } = {}
local Module = {}

local playerTickRates: { [number]: number }

--// MODULE FUNCTIONS
function Module.Init(_playerTickRates: { [number]: number }, _interpolationBuffer: any): ()
	playerTickRates = _playerTickRates
	InterpolationBuffer = _interpolationBuffer
end

function Module.GetBuffer(networkId: number): number
	if isNPCMap[networkId] then
		local npcType: string = npcTypeMap[networkId] or "Default"

		local npcConfig: NpcReplicationConfigs.Config = NpcReplicationConfigs[npcType]
		if not npcConfig then
			warn(`No NPC config found for type {npcType}. Make sure to define it in the config`)
			npcConfig = NpcReplicationConfigs.Default
		end

		return npcConfig.Buffer 
	else
		local tickRate: number = playerTickRates[networkId] or TICK_RATE
		return InterpolationBuffer.GetBuffer(networkId, tickRate) :: number
	end
end

function Module.OnSnapshotUpdate(snapshot: { [number]: number }): ()
	local clock: number = os.clock()

	for networkId, sendTimestamp in pairs(snapshot) do
		local clockInfo: ClockInfo = clientClockInfo[networkId]
		if not clockInfo then
			clockInfo = {
				LastClockAt = sendTimestamp,
				LastClockDuration = clock
			} :: ClockInfo
			clientClockInfo[networkId] = clockInfo
		end

		if sendTimestamp > clockInfo.LastClockAt then
			clockInfo.LastClockAt = sendTimestamp
			clockInfo.LastClockDuration = clock

			if not clockInfo.RenderAt then
				local _delay: number = Module.GetBuffer(networkId)
				clockInfo.RenderAt = sendTimestamp - _delay
			end
		end
	end
end

function Module.Update(deltaTime: number): ()
	local clock: number = os.clock()

	for id, clockInfo in pairs(clientClockInfo) do
		local _delay: number = Module.GetBuffer(id)

		local estimatedServerTime: number = clockInfo.LastClockAt + (clock - clockInfo.LastClockDuration)
		local renderAt: number = (clockInfo.RenderAt or (estimatedServerTime - _delay)) + deltaTime

		local renderTimeError = _delay - (estimatedServerTime - renderAt)
		if math.abs(renderTimeError) > 0.1 then
			renderAt = estimatedServerTime - _delay
		elseif renderTimeError > 0.01 then
			renderAt = math.max(estimatedServerTime - _delay, renderAt - 0.1 * deltaTime)
		elseif renderTimeError < -0.01 then
			renderAt = math.min(estimatedServerTime - _delay, renderAt + 0.1 * deltaTime)
		end

		clockInfo.RenderAt = renderAt
	end
end

function Module.GetTargetRenderTime(networkId: number): number
	local clockInfo: ClockInfo? = clientClockInfo[networkId]
	if not clockInfo or not clockInfo.RenderAt then
		warn(`RenderCache: No render time for network ID {networkId}`)
		return 0
	end
	return clockInfo.RenderAt
end

function Module.GetEstimatedServerTime(networkId: number): number
	local clockInfo: ClockInfo? = clientClockInfo[networkId]
	if not clockInfo then
		warn(`RenderCache: No estimated server time for network ID {networkId}`)
		return 0
	end
	return clockInfo.LastClockAt + (os.clock() - clockInfo.LastClockDuration)
end

function Module.Add(networkId: number, isNPC: boolean?, npcType: string?): ()
	if not clientClockInfo[networkId] then
		clientClockInfo[networkId] = {
			LastClockAt = 0,
			LastClockDuration = 0
		}
	end

	isNPCMap[networkId] = isNPC or false
	if isNPC then
		npcTypeMap[networkId] = npcType or "Default"
	end
end

function Module.Remove(networkId: number): ()
	clientClockInfo[networkId] = nil
	isNPCMap[networkId] = nil
	npcTypeMap[networkId] = nil
end

return Module