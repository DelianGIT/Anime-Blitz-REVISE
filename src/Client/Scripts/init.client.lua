--!strict
--// WATING FOR LOADED GAME
if not game:IsLoaded() then
	game.Loaded:Wait()
end

--// SERVICES
-- local ContentProvider = game:GetService("ContentProvider")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

--// MODULES
local ClientModules = ReplicatedFirst.Modules

--// REMOTE EVENTS
local RemoteEvents = require(ReplicatedStorage.RemoteEvents.ClientLoaded)
local RemoteEvent = RemoteEvents.Loaded

--// CONSTANTS
-- local PRELOADING = true

--// VARIABLES
-- local assetsFolder: Folder = ReplicatedStorage.Assets

--// DISABLING DEFAULT ROBLOX GUI
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.SelfView, false)

--// PRELOADING
-- if PRELOADING then
 	--TODO: Add preloading
-- end

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

--// REQUIRING SCRIPTS
requireFolder(script)

--// SYNCING SHARED PLAYER DATA
require(ClientModules.SharedPlayerData)

RemoteEvent.send()

print("Client loaded")
