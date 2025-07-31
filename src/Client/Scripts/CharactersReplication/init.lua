--!strict
--// SERVICES
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// MODULES
local ClientModules = ReplicatedFirst.Modules
local CharacterController = require(ClientModules.CharacterController)

local SharedModules = ReplicatedStorage.Modules
local Snapshot = require(SharedModules.Snapshot)

local RenderCache = require(script.RenderCache)
local InterpolationBuffer = require(script.InterpolationBuffer)

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
	Snapshot: Snapshot.Snapshot,
	Character: Model,
	LastCFrame: CFrame?,
}

--// CONSTANTS
local TICK_RATE = Configs.TickRate

--// VARIABLES
local charactersFolder = workspace.Living.Players

local addedCharacters: { [number]: Model } = {}
local playerTickRates: { [number]: number } = {}
local idMap: { [number]: Data } = {}

local playerNetworkId: number = 300
local lastSent: number = os.clock()

local localCharacter: Model?

--// FUNCTIONS
local function addCharacter(character: Model, id: number): ()
	if addedCharacters[id] then
		warn(`Character {character} is added already`)
		return
	end

	local humanoidRootPart: Part = character:WaitForChild("HumanoidRootPart") :: Part

	local initalCFrame: CFrame = humanoidRootPart.CFrame
	local snapshot: Snapshot.Snapshot = Snapshot.new()
	snapshot:Push(os.clock(), initalCFrame)

	idMap[id] = {
		Snapshot = snapshot,
		Character = character,
		LastCFrame = initalCFrame
	}

	RenderCache.Add(id)
end

local function removeCharacter(character: Model, id: number): ()
	if not addedCharacters[id] then
		warn(`Character {character} isn't added`)
		return
	end

	addedCharacters[id] = nil
	idMap[id] = nil
	RenderCache.Remove(id)
end

--// EVENTS
AddExistingCharacters.listen(function(data)
	playerNetworkId = data.NetworkId
	for id, characterName in pairs(data.CharactersNames) do
		local character: Model = charactersFolder:WaitForChild(characterName) :: Model
		addCharacter(character, id)
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

ServerReplicateCFrame.listen(function(data)
	local timestamps: { [number]: number } = data.Timestamps
	local cframes: { [number]: CFrame } = data.CFrames

	for id, data in pairs(idMap) do
		local timestamp: number? = timestamps[id]
		if not timestamp then
			continue
		end

		local cframe: CFrame? = cframes[id]
		if not cframe then
			continue
		end

		InterpolationBuffer.RegisterPacket(id, timestamp, playerTickRates[id] or TICK_RATE)
		data.Snapshot:Push(timestamps[id], cframe)
	end

	RenderCache.OnSnapshotUpdate(timestamps)
end)

CharacterController.CharacterAdded:Connect(function(character: Model)
	localCharacter = character
end)

CharacterController.CharacterRemoving:Connect(function()
	localCharacter = nil
end)

RunService.PreRender:Connect(function(deltaTime: number)
	RenderCache.Update(deltaTime)

	for id, data in pairs(idMap) do
		local character: Model = data.Character
		if not character:IsDescendantOf(workspace) or character == localCharacter then
			continue
		end

		local humanoidRootPart: Part? = character:FindFirstChild("HumanoidRootPart") :: Part?
		if not humanoidRootPart or not humanoidRootPart:IsA("BasePart") then
			continue
		end

		local targetRenderTime: number = RenderCache.GetTargetRenderTime(id)
		local targetCFrame: CFrame? = data.Snapshot:GetAt(targetRenderTime)

		if targetCFrame then
			data.LastCFrame = targetCFrame

			if not humanoidRootPart:GetAttribute("DontReplicate") and humanoidRootPart.AssemblyRootPart == humanoidRootPart then
				(humanoidRootPart :: any).CFrame = targetCFrame
			end
		end
	end
end)

RunService.PostSimulation:Connect(function()
	local clock: number = os.clock()
	if clock - lastSent < (playerTickRates[playerNetworkId] or TICK_RATE) then
		return
	end
	lastSent = clock

	if not localCharacter then
		return
	end

	local humanoidRootPart: Part? = localCharacter:FindFirstChild("HumanoidRootPart") :: Part?
	if not humanoidRootPart or not humanoidRootPart:IsA("BasePart") then
		return
	end

	ClientReplicateCFrame.send({
		Timestamp = clock,
		CFrame = humanoidRootPart.CFrame,
	})
end)

return true