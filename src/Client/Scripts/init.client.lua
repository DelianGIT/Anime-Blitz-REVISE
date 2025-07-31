--!strict
--// WATING FOR LOADED GAME
if not game:IsLoaded() then
	game.Loaded:Wait()
end

--// SERVICES
-- local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterGui = game:GetService("StarterGui")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)

--// MODULES
local ClientModules = ReplicatedFirst.Modules
local PlayerData = require(ClientModules.PlayerData)

--// CONSTANTS
local PRELOADING = true

--// VARIABLES
-- local assetsFolder: Folder = ReplicatedStorage.Assets

--// DISABLING DEFAULT ROBLOX GUI
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.SelfView, false)

--// PRELOADING
if PRELOADING then
	--TODO: Add preloading
end

--// FUNCTIONS
local function requireModule(module: ModuleScript): ()
	local success: boolean, errorMessage: string?, yielded: boolean
	task.spawn(function()
		success, errorMessage = pcall(require, module)
		yielded = false
	end)

	if yielded then
		warn("Yielded while requiring" .. module:GetFullName())
	end

	if success == false then
		error(`{module:GetFullName()} threw an error while requiring: {errorMessage}`)
	end
end

local function requireFolder(folder: Folder | LocalScript | ModuleScript): ()
	for _, instance in ipairs(folder:GetChildren()) do
		if instance:IsA("Folder") then
			requireFolder(instance)
			continue
		elseif instance:IsA("ModuleScript") then
			requireModule(instance)
		end
	end
end

--// WAITING FOR THE INITIAL STATE
local playerDataAtom: PlayerData.Atom = PlayerData.Atom
repeat
	task.wait()
until not Sift.isEmpty(playerDataAtom() :: any)

--// REQUIRING SCRIPTS
requireFolder(script)

print("Client loaded")
