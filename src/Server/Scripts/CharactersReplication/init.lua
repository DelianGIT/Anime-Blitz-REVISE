--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Charm = require(Packages.Charm)
local Sift = require(Packages.Sift)

--// MODULES
local ServerModules = ServerScriptService.Modules
local PlayerData = require(ServerModules.PlayerData)
local LoadedPlayersList = require(ServerModules.LoadedPlayersList)

local SharedModules = ReplicatedStorage.Modules
local Snapshot = require(SharedModules.Snapshot)

local Grid = require(script.Grid)

local Configs = require(ReplicatedStorage.Configs)

--// REMOTE EVENTS
local RemoteEvents = require(ReplicatedStorage.RemoteEvents.CharactersReplication)
local AddExistingCharacters = RemoteEvents.AddExistingCharacters
local AddCharacter = RemoteEvents.AddCharacter
local RemoveCharacter = RemoteEvents.RemoveCharacter
local ClientReplicateCFrame = RemoteEvents.ClientReplicateCFrame
local ServerReplicateCFrame = RemoteEvents.ServerReplicateCFrame
local TickRateChanged = RemoteEvents.TickRateChanged

--// TYPES
type Data = {
	Player: Player,
	Snapshot: Snapshot.Snapshot,
	ClientLastTick: number?,
}

--// CONSTANTS
local MAX_ID = 255
local PROXIMITY = 100
local TICK_RATE = Configs.TickRate

--// VARIABLES
local camera: Camera = workspace.CurrentCamera

local charactersAssetsFolder: Folder = ReplicatedStorage.Assets.Characters
local defaultRig: Model = ReplicatedStorage.Miscellaneous.Rig

local characterDataAtom = PlayerData.Atoms.CharacterData
local characterAtom = PlayerData.Atoms.Character
local snapshotsAtom = PlayerData.Atoms.Snapshot
local loadedAtom = PlayerData.Atoms.Loaded
local rootCFrameAtom = PlayerData.Atoms.RootCFrame

local idStack: { number } = {}
local playerIdMap: { [Player]: number } = {}
local idMap: { [number]: Data } = {}
local lastReplicatedTimes: { [number]: number } = {}
local playerTickRates: { [number]: number } = {}
local replicators: { [number]: Model } = {}

local incrementalFactoryUid: number = 0

--// FUNCTIONS
local function getNextId(): number
	local reusedId: number? = table.remove(idStack)
	if reusedId then
		return reusedId
	end

	if incrementalFactoryUid + 1 == MAX_ID then
		error("Max Id reached, please investigate")
	end
	incrementalFactoryUid += 1

	return incrementalFactoryUid
end

local function returnID(id: number): ()
	table.insert(idStack, id)
end

local function turnOffCollisionsAndAnchor(character: Model): ()
	(character :: any).Humanoid:Destroy();
	(character :: any).HumanoidRootPart.Anchored = true

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
end

local function addExistingCharacters(player: Player, id: number): ()
	local count: number = 0
	local charactersNames: { [number]: string } = {}
	for otherPlayer, otherId in pairs(playerIdMap) do
		if otherPlayer == player then
			continue
		end

		local character: Model? = otherPlayer.Character
		if character then
			charactersNames[otherId] = character.Name
		end
	end

	if count == 0 and not RunService:IsStudio() then
		warn("No existing players found to initialize for player", player)
	else
		AddExistingCharacters.sendTo({
			NetworkId = id,
			CharactersNames = charactersNames
		}, player)
	end
end

local function addCharacter(player: Player, character: Model, id: number): ()
	local replicator: Model
	local characterData = characterDataAtom()[player]
	if characterData then
		local model: Model? = (charactersAssetsFolder :: any)[characterData.Name].Character
		if model then
			replicator = model:Clone()
		else
			replicator = defaultRig:Clone()
		end
	else
		replicator = defaultRig:Clone()
	end

	turnOffCollisionsAndAnchor(replicator)
	replicator.Name = player.Name
	replicator.Parent = camera
	replicators[id] = replicator

	Grid.AddEntity(character, "Player")

	AddCharacter.sendToList({
		Id = id,
		CharacterName = character.Name,
	}, LoadedPlayersList)
end

local function removeCharacter(character: Model?, id: number): ()
	local replicator: Model? = replicators[id]
	if replicator then
		replicator:Destroy()
		replicators[id] = nil
	end

	if character then
		Grid.RemoveEntity(character)

		RemoveCharacter.sendToList({
			Id = id,
			CharacterName = character.Name
		}, LoadedPlayersList)
	end
end

local function getTickInterval(character: Model?, id: number): number
	if not character then
		return TICK_RATE
	end
	
	local newTickRate: number
	local nearbyPlayers: { Model } = Grid.GetNearbyEntities(character, PROXIMITY, { "Player" })
	if #nearbyPlayers > 1 then
		newTickRate = TICK_RATE
	else
		newTickRate = TICK_RATE * 2
	end

	if newTickRate ~= playerTickRates[id] then
		playerTickRates[id] = newTickRate
		TickRateChanged.sendToList({
			Id = id,
			TickRate = newTickRate,
		}, LoadedPlayersList)
	end

	return newTickRate
end

--// OBSERVERS
Charm.observe(loadedAtom :: any, function(_, player: Player)
	local id: number = getNextId()
	playerIdMap[player] = id

	local snapshot: Snapshot.Snapshot = Snapshot.new()
	snapshotsAtom(function(state: { [Player]: Snapshot.Snapshot })
		return Sift.Dictionary.set(state, player, snapshot)
	end)

	idMap[id] = {
		Player = player,
		Snapshot = snapshot
	}
	lastReplicatedTimes[id] = 0

	addExistingCharacters(player, id)

	local character: Model? = characterAtom()[player]
	if character then
		addCharacter(player, character, id)
	end

	return function()
		removeCharacter(player.Character, id)

		playerIdMap[player] = nil
		idMap[id] = nil
		lastReplicatedTimes[id] = nil
		playerTickRates[id] = nil

		returnID(id)
	end
end)

Charm.observe(characterAtom :: any, function(character: Model, player: Player)
	local id: number = playerIdMap[player]
	if not id then
		return nil
	end

	addCharacter(player, character, id)

	return function()
		removeCharacter(character, id)
	end :: any
end)

--// EVENTS
ClientReplicateCFrame.listen(function(clientData, player: Player?)
	if not player then
		return
	end

	local id: number = playerIdMap[player]
	local data: Data? = idMap[id]
	if not data then
		return
	end

	local timestamp: number = clientData.Timestamp
	data.ClientLastTick = timestamp

	local cframe: CFrame = clientData.CFrame
	data.Snapshot:Push(timestamp, cframe)

	rootCFrameAtom(function(state)
		return Sift.Dictionary.set(state, player, cframe)
	end)
end)

RunService.PostSimulation:Connect(function()
	Grid.UpdateGrid()

	local cframes: { [number]: CFrame } = {}
	local timestamps: { [number]: number } = {}
	local clock: number = os.clock()

	local characters: { [Player]: Model } = characterAtom()
	for player, character in pairs(characters) do
		local humanoidRootPart: Part? = character:FindFirstChild("HumanoidRootPart") :: Part?
		if not humanoidRootPart then
			continue
		end

		local id: number? = playerIdMap[player]
		if not id then
			continue
		end

		local data: Data? = idMap[id]
		if not data then
			continue
		end

		local clientLastTick: number? = data.ClientLastTick
		if not clientLastTick then
			continue
		end

		local tickInterval: number = getTickInterval(character, id)
		local lastReplicated: number = lastReplicatedTimes[id]
		if clock - lastReplicated < tickInterval then
			continue
		end
		lastReplicatedTimes[id] = clock

		local latestSnapshot: Snapshot.Data? = data.Snapshot:GetLatest()
		if latestSnapshot then
			cframes[id] = latestSnapshot.Value
		else
			cframes[id] = humanoidRootPart.CFrame
		end

		timestamps[id] = clientLastTick
	end

	ServerReplicateCFrame.sendToList({
		CFrames = cframes,
		Timestamps = timestamps
	}, LoadedPlayersList)

	local humanoidRootParts: { Part } = {}
	local targetCFrames: { CFrame } = {}
	for id, clone in pairs(replicators) do
		local data: Data? = idMap[id]
		if not data then
			continue
		end

		local humanoidRootPart: Part? = clone:FindFirstChild("HumanoidRootPart") :: Part?
		if not humanoidRootPart then
			continue
		end

		local latestSnapshot: Snapshot.Data? = data.Snapshot:GetLatest()
		if latestSnapshot then
			table.insert(humanoidRootParts, humanoidRootPart)
			table.insert(targetCFrames, latestSnapshot.Value)
		end
	end

	if #humanoidRootParts > 0 then
		workspace:BulkMoveTo(humanoidRootParts :: any, targetCFrames)
	end
end)

return true