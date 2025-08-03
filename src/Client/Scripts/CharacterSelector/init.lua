--!strict
--// SERVICES
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Charm = require(Packages.Charm)

--// MODULES
local ClientModules = ReplicatedFirst.Modules
local PlayerData = require(ClientModules.PlayerData)
local AnimationsStorage = require(ClientModules.CharacterController.AnimationsStorage)

local Animate = require(script.Animate)

--// VARIABLES
local assetsFolder = ReplicatedStorage.Assets.Characters

local playerDataAtom: PlayerData.Atom = PlayerData.Atom

--// FUNCTIONS
local function getCharacterName()
	local characterData = playerDataAtom().CharacterData
	if characterData then
		return characterData.Name
	else
		return "Default"
	end
end

local function selectCharacter(characterName: string)
	AnimationsStorage.RemoveAnimations("Movement")
	AnimationsStorage.RemoveAnimations("Default")

	local characterFolder: any = assetsFolder:FindFirstChild(characterName)
	if not characterFolder then
		error(`Character folder {characterName} not found`)
	end

	AnimationsStorage.AddAnimations("Movement", {
		DoubleJump = characterFolder.DoubleJump,
	})

	local defaultAnimations: { [string]: Animation } = {}
	local defaultAnimationsFolder: Folder = characterFolder.DefaultAnimations
	for _, animation in ipairs(defaultAnimationsFolder:GetChildren()) do
		if animation:IsA("Animation") then
			defaultAnimations[`{animation.Name}_1`] = animation
		elseif animation:IsA("Folder") then
			local folderName: string = animation.Name
			for _, _animation in ipairs(animation:GetChildren()) do
				defaultAnimations[`{folderName}_{_animation.Name}`] = _animation :: Animation
			end
		end
	end
	AnimationsStorage.AddAnimations("Default", defaultAnimations)

	Animate.SelectAnimations(characterName)
end

--// EVENTS
Charm.subscribe(getCharacterName, selectCharacter)

--// SELECTING DEFAULT CHARACTER
selectCharacter("Default")

return true