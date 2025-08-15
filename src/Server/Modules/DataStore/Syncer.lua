--!strict
--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local CharmSync = require(Packages.CharmSync)
local Sift = require(Packages.Sift)

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local SharedTemporaryDataFields = require(SharedModules.SharedTemporaryDataFields)

local Atoms = require(script.Parent.Atoms)
local TemporaryDataTemplate = require(script.Parent.TemporaryDataTemplate)

--// REMOTE EVENTS
local RemoteEvents = require(ReplicatedStorage.RemoteEvents.DataSync)
local Sync = RemoteEvents.Sync
local Request = RemoteEvents.Request

--// VARIABLES
local temporaryDataAtom: Atoms.TemporaryDataAtom = Atoms.TemporaryDataAtom

local sharedAtoms = Atoms.SharedAtoms

--// FUNCTIONS
local function waitForTempData(player: Player): TemporaryDataTemplate.Data?
	local tempData: TemporaryDataTemplate.Data? = temporaryDataAtom()[player]
	if not tempData then
		repeat
			task.wait()
			tempData = temporaryDataAtom()[player]
		until tempData or player.Parent ~= Players
	end
	return tempData
end

local function filterTempData(tempData: TemporaryDataTemplate.Data): any
	return Sift.Dictionary.withKeys(tempData :: any, table.unpack(SharedTemporaryDataFields))
end

local function filterPayload(player: Player, payload: any)
	local payloadData = Sift.Dictionary.copy(payload.data)
	payload = Sift.Dictionary.copy(payload)
	payload.Data = payloadData

	local tempData: TemporaryDataTemplate.Data?
	local payloadType: "init" | "patch" = payload.type
	if payloadType == "init" then
		tempData = waitForTempData(player)
	else
		local allTempData: { [Player]: TemporaryDataTemplate.Data }? = payloadData.TemporaryData
		if allTempData then
			tempData = allTempData[player]
		end
	end

	if tempData then
		tempData = filterTempData(tempData)
		if Sift.isEmpty(tempData) then
			tempData = nil
		end
	end

	payloadData.TemporaryData = tempData

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
	if not Sift.isEmpty(payload.data) then
		Sync.sendTo(payload :: any, player)
	end
end)

--// EVENTS
Request.listen(function(_, player: Player?)
	if player then
		syncer:hydrate(player)
	end
end)

return true