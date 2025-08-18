--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local CharmSync = require(Packages.CharmSync)
local Sift = require(Packages.Sift)

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local SharedPlayerDataFields = require(SharedModules.SharedPlayerDataFields)

local Atoms = require(script.Parent.Atoms)

--// REMOTE EVENTS
local RemoteEvents = require(ReplicatedStorage.RemoteEvents.DataSync)
local Sync = RemoteEvents.Sync
local Request = RemoteEvents.Request

--// VARIABLES
local sharedAtoms = Sift.Dictionary.withKeys(Atoms :: any, table.unpack(SharedPlayerDataFields))

--// FUNCTIONS
local function filterTempData(tempData: TemporaryDataTemplate.Data): any
	return Sift.Dictionary.withKeys(tempData :: any, table.unpack(SharedTemporaryDataFields))
end

local function filterPayload(player: Player, payload: any)
	local payloadData = Sift.Dictionary.copy(payload.data)
	payload = Sift.Dictionary.copy(payload)
	payload.data = payloadData

	local tempData: TemporaryDataTemplate.Data?
	local allTempData: { [Player]: TemporaryDataTemplate.Data }? = payloadData.TemporaryData
	if allTempData then
		tempData = allTempData[player]

		if tempData then
			tempData = filterTempData(tempData)
			if Sift.isEmpty(tempData) then
				tempData = nil
			end
		end

		payloadData.TemporaryData = tempData
	end

	return payload
end

--// SYNCER
local syncer = CharmSync.server({
	atoms = Sift.Dictionary.merge({
		TemporaryData = temporaryDataAtom
	}, sharedAtoms) :: any,
	interval = 0,
	preserveHistory = false,
	autoSerialize = false,
})

syncer:connect(function(player: Player, payload: any)
	payload = filterPayload(player, payload)
	if Sift.isEmpty(payload.data) then
		return
	end

	local dataSynced: boolean? = dataSyncedPlayers()[player]
	if dataSynced == true then
		Sync.sendTo(payload :: any, player)
	elseif dataSynced == false and payload.data.TemporaryData then
		dataSyncedPlayers(function(state: { [Player]: boolean })
			return Sift.Dictionary.set(state, player, true)
		end)
		syncer:hydrate(player)
	end
end)

--// EVENTS
Request.listen(function(_, player: Player?)
	if not player then
		return
	end

	local tempData: TemporaryDataTemplate.Data? = temporaryDataAtom()[player]
	if not tempData then
		dataSyncedPlayers(function(state: { [Player]: boolean })
			return Sift.Dictionary.set(state, player, false)
		end)
	else
		dataSyncedPlayers(function(state: { [Player]: boolean })
			return Sift.Dictionary.set(state, player, true)
		end)

		syncer:hydrate(player)
	end
end)

return true