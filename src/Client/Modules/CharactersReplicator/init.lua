--!strict
--// SERVICES
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// MODULES
local ClientModules = ReplicatedFirst.Modules
local InterpolationBuffer = require(script.InterpolationBuffer)
local CharacterController = require(ClientModules.CharacterController)

local SharedModules = ReplicatedStorage.Modules
local Snapshot = require(SharedModules.Snapshot)

local Configs = require(ReplicatedStorage.Configs)

local RenderCache = require(script.RenderCache)

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
	Snapshot: Snapshot.Snapshot,
	LastCFrame: CFrame?,
	IsNpc: boolean?,
	NpcType: string?,
	Character: Model?
}

--// CONSTANTS
local TICK_RATE = Configs.TickRate

--// VARIABLES
local localPlayer: Player = Players.LocalPlayer

local camera: Camera = workspace.CurrentCamera
local charactersFolder = workspace.Living.Players

local npcModelCache = ReplicatedStorage.NpcModelCache

local lastSentCFrame: CFrame = CFrame.identity

local playerTickRates: { [number]: number } = {}
local idMap: { [number]: Data } = {}
local pausedPlayers: { [number]: boolean } = {}
local characters: { [number]: Model } = {}
local Module = {}

local lastSent: number = os.clock()
local playerNetworkId: number = 300

local localCharacter: Model?

--// FUNCTIONS
local function handleReplicatedData(timestamps: { [number]: number }, cframes: { [number]: CFrame })
	for id, serverTime in pairs(timestamps) do
		local data: Data? = idMap[id]
		if data and not data.IsNpc then
			InterpolationBuffer.RegisterPacket(id, serverTime)
		end
	end

	RenderCache.OnSnapshotUpdate(timestamps)

	for id, cframe in cframes do
		local data: Data? = idMap[id]
		if not data then
			continue
		end

		local npcType: string? = data.NpcType
		if data.IsNpc and npcType and not RenderCache.GetTargetRenderTime(id) then
			RenderCache.Add(id, true, npcType)
		end

		data.Snapshot:Push(timestamps[id], cframe)
	end
end

local function addCharacter(character: Model, id: number)
	if characters[id] then
		warn(`Character {character} is added already`)
		return
	end
	characters[id] = character

	local humanoidRootPart: Part = character:WaitForChild("HumanoidRootPart") :: Part
	humanoidRootPart.Anchored = false

	local initialCFrame: CFrame = humanoidRootPart.CFrame
	local snapshot: Snapshot.Snapshot = Snapshot.new()
	snapshot:Push(os.clock(), initialCFrame)

	idMap[id] = {
		Snapshot = snapshot,
		LastCFrame = initialCFrame
	}

	RenderCache.Add(id)
end

local function removeCharacter(character: Model, id: number): ()
	if not characters[id] then
		warn(`Character {character} isn't added`)
		return
	end

	characters[id] = nil
	idMap[id] = nil

	RenderCache.Remove(id)
end

--// MODULE FUNCTIONS
function Module.RegisterNpc(model: Model): ()
	local id: number? = tonumber(model:GetAttribute("NPC_ID"))
	if not id then
		error(`Npc model does not have an id attribute: {model:GetFullName()}`)
	end

	local clone = model:Clone()
	clone.Name = tostring(id)
	clone.Parent = camera;
	(clone :: any).HumanoidRootPart.Anchored = true

	local npcType: string = model:GetAttribute("Type") :: string
	local data: Data = idMap[id]
	if not data then
		data = {
			Snapshot = Snapshot.new(),
			IsNpc = true,
			NpcType = npcType,
			Character = clone
		}
		idMap[id] = data :: Data

		RenderCache.Add(id, true, npcType)
	else
		data.NpcType = npcType
		data.Character = clone
	end

	model.AncestryChanged:Connect(function()
		if not model.Parent then
			Module.UnregisterNpc(id)
			clone:Destroy()
		end
	end)
end

function Module.UnregisterNpc(id: number)
	local data: Data? = idMap[id]
	if not data then
		return
	end

	if not data.Character then
		warn("Tried to unregister NPC that hasn't been registered yet")
		return
	end

	RenderCache.Remove(id)

	idMap[id] = nil
end

function Module.ToggleReplication(character: Model | Player, toggle: boolean)
	local id: number = characters[character]
	if toggle then
		pausedPlayers[id] = nil
	else
		pausedPlayers[id] = true
	end
end

--// CHECKING EXISTING NPCS
for _, npc in ipairs(npcModelCache:GetChildren()) do
	if npc:IsA("Model") then
		Module.RegisterNpc(npc)
	end
end

--// EVENTS
AddExistingCharacters.listen(function(data)
	playerNetworkId = data.NetworkId
	for id, characterName in pairs(data.CharactersNames) do
		task.spawn(function()
			local character: Model = charactersFolder:WaitForChild(characterName) :: Model
			addCharacter(character, id)
		end)
	end
end)

AddCharacter.listen(function(data)
	local character: Model = charactersFolder:WaitForChild(data.CharacterName) :: Model
	addCharacter(character, data.Id)
end)

RemoveCharacter.listen(function(data)
	local character: Model = charactersFolder:WaitForChild(data.CharacterName) :: Model
	removeCharacter(character, data.Id)
end)

TickRateChanged.listen(function(data)
	playerTickRates[data.Id] = data.TickRate
end)

TogglePlayerReplication.listen(function(data)
	if data.Toggle then
		pausedPlayers[data.Id] = nil
	else
		pausedPlayers[data.Id] = true
	end
end)

ServerReplicateCFrame.listen(function(data)
	handleReplicatedData(data.Timestamps, data.CFrames)
end)

npcModelCache.ChildAdded:Connect(function(model)
	if model:IsA("Model") then
		Module.RegisterNpc(model)
	end
end)

RunService.PreRender:Connect(function(deltaTime: number)
	RenderCache.Update(deltaTime)

	local humanoidRootParts: { BasePart } = {}
	local cframes: { CFrame } = {}
	local index: number = 0
	for id, data in pairs(idMap) do
		local character: Model? = characters[id] or data.Character
		if not character or character == localCharacter then
			continue
		end

		if pausedPlayers[id] then
			continue
		end

		local humanoidRootPart: BasePart? = character.PrimaryPart
		if not humanoidRootPart then
			continue
		end

		local targetRenderTime: number = RenderCache.GetTargetRenderTime(id)
		local targetCFrame: CFrame? = data.Snapshot:GetAt(targetRenderTime)
		if not targetCFrame then
			continue
		end

		data.LastCFrame = targetCFrame

		if humanoidRootPart.AssemblyRootPart == humanoidRootPart then
			index += 1
			humanoidRootParts[index] = humanoidRootPart
			cframes[index] = targetCFrame
		end
	end

	workspace:BulkMoveTo(humanoidRootParts, cframes)
end)

RunService.PostSimulation:Connect(function()
	local tickRate: number = playerTickRates[playerNetworkId] or TICK_RATE
	if os.clock() - lastSent < tickRate then
		return
	end
	lastSent = os.clock()

	local character: Model? = localPlayer.Character
	if not character then
		return
	end

	local humanoidRootPart: BasePart? = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoidRootPart then
		return
	end
	local currentCFrame: CFrame = humanoidRootPart.CFrame

	local changed: boolean = vector.magnitude(lastSentCFrame.Position - currentCFrame.Position :: any) >= 0.1
		or not lastSentCFrame.Rotation:FuzzyEq(currentCFrame.Rotation, 0.0001)
	lastSentCFrame = currentCFrame
	if not changed then
		return
	end

	ClientReplicateCFrame.send({
		Timestamp = os.clock(),
		CFrame = currentCFrame,
	})
end)

CharacterController.CharacterAdded:Connect(function(newCharacter: Model)
	localCharacter = newCharacter
end)
CharacterController.CharacterRemoving:Connect(function()
	localCharacter = nil
end)

return Module