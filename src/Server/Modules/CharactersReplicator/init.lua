--!strict
--// SERVICES
local Players = game:GetService("Players")
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
local NpcReplicationConfigs = require(SharedModules.NpcReplicationConfigs)

local Grid = require(script.Grid)

local Configs = require(ReplicatedStorage.Configs)

--// REMOTE EVENTS
local RemoteEvents = require(ReplicatedStorage.RemoteEvents.CharactersReplication)
local ClientReplicateCFrame = RemoteEvents.ClientReplicateCFrame
local ServerReplicateCFrame = RemoteEvents.ServerReplicateCFrame
local TickRateChanged = RemoteEvents.TickRateChanged
local TogglePlayerReplication = RemoteEvents.TogglePlayerReplication
local AddExistingCharacters = RemoteEvents.AddExistingCharacters
local AddCharacter = RemoteEvents.AddCharacter
local RemoveCharacter = RemoteEvents.RemoveCharacter

--// TYPES
type Data = {
	Player: Player?,
	Snapshot: Snapshot.Snapshot,
	ClientLastTick: number?,
	ServerOwned: boolean?,
	NpcType: string?,
	Model: Model?,
	LastCFrame: CFrame?
}

--// CONSTANTS
local NPC_MODEL_CACHE = Instance.new("Folder")
NPC_MODEL_CACHE.Name = "NPC_MODEL_CACHE"
NPC_MODEL_CACHE.Parent = ReplicatedStorage

local TICK_RATE = Configs.TickRate
local MAX_ID = 2 ^ 16 - 1
local PROXIMITY = 100

--// VARIABLES
local camera: Camera = workspace.CurrentCamera

local charactersAssetsFolder: Folder = ReplicatedStorage.Assets.Characters
local defaultRig: Model = ReplicatedStorage.Miscellaneous.Rig

local loadedAtom = PlayerData.Atoms.Loaded
local snapshotAtom = PlayerData.Atoms.Snapshot
local characterAtom = PlayerData.Atoms.Character
local characterDataAtom = PlayerData.SharedAtoms.CharacterData
local rootCFrameAtom = PlayerData.Atoms.RootCFrame

local idStack: { number } = {}
local playerIdMap: { [Player]: number } = {}
local idMap: { [number]: Data } = {}
local lastReplicatedTimes: { [number]: number } = {}
local playerTickRates: { [number]: number } = {}
local replicators: { [number]: Model } = {}
local automaticNpcUpdate: { [number]: Model } = {}
local Module = {}

local incrementalFactoryUid: number = 0

--// FUNCTIONS
local function getNextId(): number
	local reusedId: number? = table.remove(idStack)
	if reusedId then
		return reusedId
	end

	if incrementalFactoryUid + 1 == MAX_ID then
		error("Max ID reached, please investigate.")
	end
	incrementalFactoryUid += 1

	return incrementalFactoryUid
end

local function returnId(id: number): ()
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

local function createReplicator(player: Player, id: number): ()
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
end

local function addExistingCharacters(player: Player, id: number)
	local count: number = 0
	local charactersNames: { [number]: string } = {}

	local characters: { [Player]: Model } = {}

	for _player, _id in pairs(playerIdMap) do
		if _player == player then
			continue
		end

		local character: Model? = characters[_player]
		if character then
			charactersNames[_id] = character.Name
		end
	end

	if count == 0 then
		warn("No existing players found to initialize for player", player)
		return
	end

	AddExistingCharacters.send({
		NetworkId = id,
		CharactersNames = charactersNames
	}, player)
end

local function addCharacter(player: Player, character: Model): ()
	local humanoidRootPart: BasePart = (character :: any).HumanoidRootPart
	if humanoidRootPart:GetNetworkOwner() ~= player then
		repeat
			task.wait()
		until humanoidRootPart:GetNetworkOwner() == player or player.Parent ~= Players
		if player.Parent ~= Players then 
			return
		end
	end
	humanoidRootPart.Anchored = true

	local id: number = playerIdMap[player]
	createReplicator(player, id)

	Grid.AddEntity(character, "Player")

	AddCharacter.sendToList({
		Id = id,
		CharacterName = character.Name,
	}, LoadedPlayersList)
end

local function removeCharacter(player: Player, character: Model): ()
	local id: number = playerIdMap[player]
	replicators[id]:Destroy()
	replicators[id] = nil

	Grid.RemoveEntity(character)
			
	RemoveCharacter.sendToList({
		Id = id,
		CharacterName = character.Name
	}, LoadedPlayersList)
end

local function addPlayer(player: Player): ()
	local id: number = getNextId()
	playerIdMap[player] = id

	local snapshot: Snapshot.Snapshot = Snapshot.new()
	snapshotAtom(function(state)
		return Sift.Dictionary.set(state, player, snapshot)
	end)

	idMap[id] = {
		Player = player,
		Snapshot = snapshot
	}
	lastReplicatedTimes[id] = 0

	addExistingCharacters(player, id)
end

local function removePlayer(player: Player): ()
	local id: number = playerIdMap[player]

	playerIdMap[player] = nil
	idMap[id] = nil
	lastReplicatedTimes[id] = nil
	playerTickRates[id] = nil

	returnId(id)
end

local function getNpcConfig(npcType: string?): any
	npcType = npcType or "Default"
	return NpcReplicationConfigs[npcType]
end

local function getTickRate(character: Model?, id: number): number
	local data: Data? = idMap[id]
	if data and data.ServerOwned then
		return getNpcConfig(data.NpcType).TICK_RATE
	end

	local baseTick: number = TICK_RATE
	if not character then
		return baseTick
	end

	local newTickRate: number
	local nearbyPlayers: { Model } = Grid.GetNearbyEntities(character, PROXIMITY, { "P[layer" })
	if #nearbyPlayers > 1 then
		newTickRate = baseTick
	else
		newTickRate = baseTick * 2
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

--// MODULE FUNCTIONS
function Module.ToggleReplication(player: Player, toggle: boolean): ()
	local id: number = playerIdMap[player]
	if not id then
		warn("Player not found in idMap")
		return
	end

	TogglePlayerReplication.sendToList({
		Id = id,
		Toggle = toggle
	}, LoadedPlayersList)
end

function Module.RegisterNpc(model: Model, npcType: string, automaticUpdate: boolean?)
	local id: number = getNextId()

	idMap[id] = {
		Snapshot = Snapshot.new(),
		ClientLastTick = os.clock(),
		ServerOwned = true,
		NpcType = npcType,
		Model = model,
	}
	lastReplicatedTimes[id] = 0

	local npcConfig: NpcReplicationConfigs.Config = getNpcConfig(npcType)
	playerTickRates[id] = npcConfig.TickRate
	TickRateChanged.sendToList({
		Id = id,
		TickRate = playerTickRates[id]
	}, LoadedPlayersList)

	model:SetAttribute("Id", id)
	model:SetAttribute("Type", npcType)

	local folder: Folder = camera:FindFirstChild(npcType) :: Folder
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = npcType
		folder.Parent = camera
	end
	model.Parent = folder

	pcall(function()
		(model :: any).HumanoidRootPart:SetNetworkOwner(nil)
	end)

	local cachedModel: Model = model:Clone()
	cachedModel.Name = tostring(id)
	cachedModel.Parent = NPC_MODEL_CACHE

	if automaticUpdate then
		automaticNpcUpdate[id] = model
	end
end

function Module.UnregisterNpc(idOrModel: number | Model): ()
	local id: number?
	if typeof(idOrModel) == "number" then
		id = idOrModel
	elseif typeof(idOrModel) == "Instance" then
		id = tonumber((idOrModel):GetAttribute("Id"))
	end
	if not id then
		error("Npc id isn't valid to unregister")
	end

	local data: Data? = idMap[id]
	if not data then
		return
	end

	idMap[id] = nil
	lastReplicatedTimes[id] = nil
	playerTickRates[id] = nil
	automaticNpcUpdate[id] = nil

	local cachedModel: Instance? = NPC_MODEL_CACHE:FindFirstChild(tostring(id))
	if cachedModel then
		cachedModel:Destroy()
	end

	local actualModel: Model? = data.Model
	if actualModel then
		Grid.RemoveEntity(actualModel)
	end

	returnId(id)
end

function Module.PushNpcTransform(id: number, cframe: CFrame, timestamp: number?): ()
	local data = idMap[id]
	if data and data.ServerOwned then
		timestamp = timestamp or os.clock()
		data.Snapshot:Push(timestamp, cframe)
		data.ClientLastTick = timestamp
	end
end

--// EVENTS
Charm.observe(loadedAtom :: any, function(_, player: Player)
	addPlayer(player)
	return function()
		removePlayer(player)
	end
end)

Charm.observe(characterAtom :: any, function(character: Model, player: Player)
	addCharacter(player, character)
	return function()
		removeCharacter(player, character)
	end
end)

ClientReplicateCFrame.listen(function(sentData, player: Player?)
	if not player then
		return
	end

	local id: number? = playerIdMap[player]
	if not id then
		return
	end

	local data: Data? = idMap[id]
	if not data then
		return
	end

	local snapshot: Snapshot.Snapshot? = data.Snapshot
	if not snapshot then
		return
	end

	local timestamp: number = sentData.Timestamp
	data.ClientLastTick = timestamp

	local cframe = sentData.CFrame
	snapshot:Push(timestamp, cframe)

	rootCFrameAtom(function(state)
		return Sift.Dictionary.set(state, player, cframe)
	end)
end)

RunService.PostSimulation:Connect(function()
	Grid.UpdateGrid()

	local clock: number = os.clock()
	local cframes: { [number]: CFrame } = {}
	local timestamps: { [number]: number } = {}

	for id, data in pairs(idMap) do
		local character: Model?
		if data.ServerOwned then
			character = data.Model
		else
			local player: Player? = data.Player
			if not player then
				continue
			end

			character = characterAtom()[player]
		end
		if not character then
			continue
		end

		local humanoidRootPart: BasePart? = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not humanoidRootPart then
			continue
		end

		local tickRate: number = getTickRate(character, id)
		local lastReplicated: number = lastReplicatedTimes[id]
		if clock - lastReplicated < tickRate then
			continue
		end
		lastReplicatedTimes[id] = clock

		local cframe: CFrame = CFrame.identity
		local latestSnapshot: Snapshot.Data? = data.Snapshot:GetLatest()
		if latestSnapshot then
			cframe = latestSnapshot.Value
		else
			cframe = humanoidRootPart.CFrame
		end

		local lastSentCFrame: CFrame = data.LastCFrame or CFrame.identity
		local changed = vector.magnitude(lastSentCFrame.Position - cframe.Position :: any) >= 0.1
			or not lastSentCFrame.Rotation:FuzzyEq(cframe.Rotation :: any, 0.0001);
		data.LastCFrame = cframe

		if not changed then
			continue
		end

		table.insert(cframes, cframe)
		table.insert(timestamps, data.ClientLastTick or clock)
	end

	ServerReplicateCFrame.sendToList({
		CFrames = cframes,
		Timestamps = timestamps
	}, LoadedPlayersList)

	for id, model in pairs(automaticNpcUpdate) do
		local humanoidRootPart: BasePart? = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not humanoidRootPart then
			continue
		end

		local rootCFrame: CFrame = humanoidRootPart.CFrame
		Module.PushNpcTransform(id, rootCFrame, clock)
	end

	local humanoidRootParts: { BasePart } = {}
	local targetCFrames: { CFrame } = {}
	for id, character in pairs(replicators) do
		local data: Data = idMap[id]
		if not data then
			continue
		end

		local humanoidRootPart: BasePart? = character:FindFirstChild("HumanoidRootPart") :: BasePart?
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
		workspace:BulkMoveTo(humanoidRootParts, targetCFrames)
	end
end)

return Module
