--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)
local CharmSync = require(Packages.CharmSync)

--// MODULES
local SharedAtoms = require(script.Parent.SharedAtoms)

--// REMOTE EVENTS
local RemoteEvents = require(ReplicatedStorage.RemoteEvents.SharedAtomsSync)
local Sync = RemoteEvents.Sync
local Request = RemoteEvents.Request

--// VARIABLES
local loadedDataPlayers: { [Player]: boolean } = {}
local Module = {}

--// FUNCTIONS
local function filterPayload(player: Player, payload: any): any
	payload = Sift.Dictionary.copy(payload)

	local payloadData = Sift.Dictionary.copy(payload.data)
	payload.data = payloadData

	local characterData = payloadData.CharacterData
	if characterData then
		characterData = (characterData :: any)[player]
	end
	payloadData.CharacterData = characterData
	
	return payload
end

--// MODULE FUNCTIONS
function Module.Init(_loadedDataPlayers: { [Player]: boolean })
	loadedDataPlayers = _loadedDataPlayers
end

--// SYNCER
local syncer = CharmSync.server({
	atoms = SharedAtoms :: any,
	interval = 0,
	preserveHistory = false,
	autoSerialize = false,
})

syncer:connect(function(player: Player, payload: any)
	payload = filterPayload(player, payload)
	if not Sift.isEmpty(payload.data) then
		Sync.sendTo(payload, player)
	end
end)

--// EVENTS
Request.listen(function(_, player: Player?)
	if not player then
		return
	end

	local isDataLoaded: boolean? = loadedDataPlayers[player]
	if isDataLoaded ~= true then
		repeat
			task.wait()
			isDataLoaded = loadedDataPlayers[player]
		until isDataLoaded or isDataLoaded == nil

		if isDataLoaded == nil then
			return
		end
	end

	syncer:hydrate(player)
end)

return Module