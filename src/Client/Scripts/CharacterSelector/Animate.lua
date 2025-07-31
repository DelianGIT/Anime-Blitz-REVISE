--!strict
--// SERVICES
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local ClientModules = ReplicatedFirst.Modules
local CharacterController = require(ClientModules.CharacterController)
local AnimationsStorage = require(ClientModules.CharacterController.AnimationsStorage)

--// TYPES
type AnimationList = {
	Connections: { RBXScriptConnection },
	Count: number,
	TotalWeight: number,
	[string]: number,
}

-- stylua: ignore
type Pose = "GettingUp" | "FallingDown" | "PlatformStanding" |
			"Running" | "Standing" | "FreeFalling" |
			"Jumping" | "Physics"

--// CONSTANTS
local FALL_TRANSITION_TIME = 0.3

--// VARIABLES
local charactersAssetsFolder = ReplicatedStorage.Assets.Characters

local Module = {}

local animationTracks: { [string]: AnimationTrack }? = {}
local animations: { [string]: AnimationList }

local pose: Pose = "Standing"

local jumpAnimationDuration: number = 0
local jumpAnimationTime: number = 0
local lastTick: number = 0

local currentAnimationSpeed: number = 1
local currentAnimationName: string?, currentAnimationTrack: AnimationTrack?
local currentAnimationStoppedHandler: RBXScriptConnection?

--// FUNCTIONS
local function setAnimationSpeed(speed: number): ()
	if speed ~= currentAnimationSpeed then
		currentAnimationSpeed = speed;
		(currentAnimationTrack :: AnimationTrack):AdjustSpeed(currentAnimationSpeed)
	end
end

local function playAnimation(name: string, transitionTime: number): AnimationTrack?
	if not animationTracks then
		return nil
	end

	local animationList: AnimationList? = animations[name]
	if not animationList then
		error(`Animation {name} not found`)
	end

	local index: number = 1
	local animationName: string = `{name}_1`
	local roll: number = math.random(1, animationList.TotalWeight)
	local weight: number = animationList[animationName]
	while roll > weight do
		roll -= weight
		index += 1
		animationName = `{name}_{index}`
		weight = animationList[animationName]
	end

	if animationName == currentAnimationName then
		return nil
	end

	currentAnimationName = animationName
	currentAnimationSpeed = 1

	if currentAnimationStoppedHandler then
		currentAnimationStoppedHandler:Disconnect()
	end

	if currentAnimationTrack then
		currentAnimationTrack:Stop()
	end

	currentAnimationTrack = animationTracks[animationName];
	(currentAnimationTrack :: AnimationTrack):Play()
	currentAnimationStoppedHandler = (currentAnimationTrack :: AnimationTrack).Stopped:Connect(function()
		playAnimation(name, 0)
		setAnimationSpeed(currentAnimationSpeed)
	end)

	return currentAnimationTrack
end

local function stopAllAnimations(): ()
	currentAnimationName, currentAnimationSpeed = nil, 1

	if currentAnimationStoppedHandler then
		currentAnimationStoppedHandler:Disconnect()
		currentAnimationStoppedHandler = nil
	end

	if currentAnimationTrack then
		currentAnimationTrack:Stop()
		currentAnimationTrack = nil
	end
end

--// MODULE FUNCTIONS
function Module.SelectAnimations(characterName: string): ()
	local assetsFolder: Folder? = charactersAssetsFolder:FindFirstChild(characterName) :: Folder?
	if not assetsFolder then
		error(`There's no assets for character {characterName}`)
	end

	local animationsFolder: Folder? = assetsFolder:FindFirstChild("DefaultAnimations") :: Folder?
	if not animationsFolder then
		error(`There's no default animation for character {characterName}`)
	end

	animations = {}
	local animationsForStorage: { [string]: Animation } = {}

	for _, instance in ipairs(animationsFolder:GetChildren()) do
		local animationList: AnimationList = {
			Connections = {},
		} :: AnimationList

		local animationName: string = instance.Name
		local count: number, totalWeight: number = 0, 0
		if instance:IsA("Folder") then
			for index, animationInstance: Animation in ipairs(instance:GetChildren() :: { Animation }) do
				local weight: number = tonumber(animationInstance.Name) :: number

				local name: string = `{animationName}_{index}`
				animationList[name] = weight
				animationsForStorage[name] = animationInstance

				count += 1
				totalWeight += weight
			end
		elseif instance:IsA("Animation") then
			local name: string = `{animationName}_{1}`
			animationList[name] = 10
			animationsForStorage[name] = instance

			count += 1
			totalWeight += 10
		end

		animationList.Count = count
		animationList.TotalWeight = totalWeight

		animations[animationName] = animationList
	end

	if AnimationsStorage.HasAnimations("Default") then
		AnimationsStorage.RemoveAnimations("Default")
	end
	animationTracks = AnimationsStorage.AddAnimations("Default", animationsForStorage)
end

--// EVENTS
CharacterController.CharacterAdded:Connect(function()
	local humanoid: Humanoid = CharacterController.Humanoid

	animationTracks = AnimationsStorage.GetTracks("Default")

	humanoid.GettingUp:Connect(function()
		pose = "GettingUp"
	end)
	humanoid.FallingDown:Connect(function()
		pose = "FallingDown"
	end)
	humanoid.PlatformStanding:Connect(function()
		pose = "PlatformStanding"
	end)
	humanoid.FreeFalling:Connect(function()
		if jumpAnimationTime <= 0 then
			playAnimation("Fall", 1, FALL_TRANSITION_TIME)
		end
		pose = "FreeFalling"
	end)
	humanoid.Jumping:Connect(function()
		local animationTrack: AnimationTrack? = playAnimation("Jump", 1, 0.1)
		if animationTrack then
			jumpAnimationDuration = animationTrack.Length
		end
		jumpAnimationTime = jumpAnimationDuration
		pose = "Jumping"
	end)
	humanoid.Running:Connect(function(speed: number)
		if speed > 0 and humanoid.MoveDirection.Magnitude > 0.1 then
			playAnimation("Walk", 1, 0.1)
			pose = "Running"
		else
			playAnimation("Idle", 1, 0.1)
			pose = "Standing"
		end
	end)
	humanoid.StateChanged:Connect(function(old: Enum.HumanoidStateType, new: Enum.HumanoidStateType)
		if new == Enum.HumanoidStateType.Physics then
			pose = "Physics"
		end
	end)

	playAnimation("Idle", 1, 0.1)
	pose = "Standing"

	while animationTracks do
		task.wait(0.1)

		local currentTick: number = os.clock()
		if jumpAnimationTime > 0 then
			jumpAnimationTime -= currentTick - lastTick
		end
		lastTick = currentTick

		if pose == "FreeFall" and jumpAnimationTime <= 0 then
			playAnimation("Fall", 1, FALL_TRANSITION_TIME)
		elseif pose == "Running" then
			playAnimation("Walk", 1, 0.1)
		elseif
			(pose :: any) == "GettingUp"
			or (pose :: any) == "FallingDown"
			or (pose :: any) == "PlatformStanding"
			or (pose :: any) == "Physics"
		then
			stopAllAnimations()
		end
	end
end)

CharacterController.CharacterRemoving:Connect(function()
	animationTracks = nil
end)

return Module
