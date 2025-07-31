--!strict
--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local Signal = require(SharedModules.Signal)

local AnimationsStorage = require(script.AnimationsStorage)
local HumanoidChanger = require(script.HumanoidChanger)

--// VARIABLES
local player: Player = Players.LocalPlayer

local charactersFolder: Folder = workspace.Living.Players

local loadedSignal: Signal.Signal<Model, Humanoid> = Signal.new()
local diedSignal: Signal.Signal<Model> = Signal.new()

local Module = {}

local dead: boolean = true

--// MODULE PROPERTIES
Module.Loaded = loadedSignal
Module.Died = diedSignal

Module.Character = (nil :: any) :: Model
Module.Humanoid = (nil :: any) :: Humanoid
Module.HumanoidRootPart = (nil :: any) :: BasePart

--// FUNCTIONS
local function isCharacterLoaded(character: Model): boolean
	if not character.PrimaryPart then
		return false
	end

	if character.Parent ~= charactersFolder then
		return false
	end

	local humanoid: Humanoid? = character:FindFirstChild("Humanoid") :: Humanoid?
	if not humanoid or humanoid.Health <= 0 or not humanoid.RootPart then
		return false
	end

	if not humanoid:FindFirstChild("Animator") then
		return false
	end

	return true
end

local function waitForLoadedCharacter(character: Model): ()
	if character.Parent ~= charactersFolder then
		(character :: any).AncestryChanged:Wait()
	end

	if character.Parent then
		if not character.PrimaryPart then
			character:GetPropertyChangedSignal("PrimaryPart"):Wait()
		end

		local humanoid: Humanoid? = character:FindFirstChild("Humanoid") :: Humanoid?
		if not humanoid then
			humanoid = character:WaitForChild("Humanoid") :: Humanoid
		end

		if not (humanoid :: Humanoid).RootPart then
			humanoid.Changed:Wait()
		end

		if not (humanoid :: Humanoid):FindFirstChild("Animator") then
			(humanoid :: Humanoid):WaitForChild("Animator")
		end
	end
end

local function onDied(character: Model): ()
	if not dead then
		dead = true
		diedSignal:Fire(character)
		AnimationsStorage.SetAnimator(nil)
	end
end

local function listenForDied(character: Model, humanoid: Humanoid): ()
	humanoid.Died:Once(function()
		onDied(character)
	end)

	local removedConnection: RBXScriptConnection
	removedConnection = character.AncestryChanged:Connect(function()
		if not character:IsDescendantOf(workspace) then
			removedConnection:Disconnect()
			onDied(character)
		end
	end)
end

--// EVENTS
player.CharacterAdded:Connect(function(character: Model)
	if not isCharacterLoaded(character) then
		waitForLoadedCharacter(character)

		if not isCharacterLoaded(character) then
			return
		end
	end
	dead = false

	local humanoid: Humanoid = character:FindFirstChild("Humanoid") :: Humanoid
	HumanoidChanger.SetHumanoid(humanoid)

	local animator: Animator = humanoid:FindFirstChild("Animator") :: Animator
	AnimationsStorage.SetAnimator(animator)

	Module.Character = character
	Module.Humanoid = humanoid
	Module.HumanoidRootPart = humanoid.RootPart :: BasePart

	listenForDied(character, humanoid)

	loadedSignal:Fire(character, humanoid)
end)

return Module
