--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local Utility = require(SharedModules.Utility)
local ParticleUtility = require(SharedModules.ParticleUtility)

--// TYPES
type Data = {
	Dust: Part,
	HumanoidConnection: RBXScriptConnection,
	DustConnection: RBXScriptConnection?
}

--// VARIABLES
local charactersFolder = workspace.Living.Players
local ignoreFolder = workspace.Ignore

local assetsFolder = ReplicatedStorage.Assets
local dustTemplate = assetsFolder.RunDust

local allData: { [Model]: Data } = {}
local Module = {}

--// FUNCTIONS
local function connectDust(dust: Part, humanoidRootPart: Part): RBXScriptConnection
	local dustEnabled: boolean = false
	return RunService.Heartbeat:Connect(function()
		local normal: Vector3?, position: Vector3? = Utility.GetFloorNormalAndPosition(humanoidRootPart.Position, 4)
		if normal and position then
			local cframe: CFrame = Utility.GetCFrameFromNormal(normal, position, humanoidRootPart.CFrame.LookVector)
			dust.CFrame = cframe

			if not dustEnabled then
				dustEnabled = true
				ParticleUtility.Enable(dust)
			end
		elseif dustEnabled then
			dustEnabled = false
			ParticleUtility.Disable(dust)
		end
	end)
end

local function addCharacter(character: Model)
	local humanoid: Humanoid? = character:WaitForChild("Humanoid") :: Humanoid?
	if not humanoid then
		return
	end

	local humanoidRootPart: Part? = character:WaitForChild("HumanoidRootPart") :: Part
	if not humanoidRootPart then
		return
	end

	local dust: Part = Utility.CloneInstance(dustTemplate, ignoreFolder)
	
	local data: Data = {
		Dust = dust
	} :: any

	local dustConnection: RBXScriptConnection?

	local humanoidConnection: RBXScriptConnection
	humanoidConnection = humanoid.Running:Connect(function(speed: number)
		if speed > 0 and humanoid.MoveDirection.Magnitude > 0.1 then
			if not dustConnection then
				dustConnection = connectDust(dust, humanoidRootPart)
			end
		else
			if dustConnection then
				ParticleUtility.Disable(dust)

				dustConnection:Disconnect()
				dustConnection = nil
			end
		end
	end)
	data.HumanoidConnection = humanoidConnection

	allData[character] = data
end

local function removeCharacter(character: Model)
	local data: Data? = allData[character]
	if not data then
		return
	end
	allData[character] = nil

	local dust: Part = data.Dust
	ParticleUtility.Disable(dust)
	Utility.DelayDestruction(2.2, dust)

	data.HumanoidConnection:Disconnect()

	local dustConnection: RBXScriptConnection? = data.DustConnection
	if dustConnection then
		dustConnection:Disconnect()
	end
end

--// EVENTS
charactersFolder.ChildAdded:Connect(function(character: Instance)
	if character:IsA("Model") then
		addCharacter(character)
	end
end)

charactersFolder.ChildRemoved:Connect(function(character: Instance)
	if character:IsA("Model") then
		removeCharacter(character)
	end
end)

return Module