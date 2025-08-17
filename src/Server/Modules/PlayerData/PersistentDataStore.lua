--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Lyra = require(Packages.Lyra)

--// MODULES
local Modules = ReplicatedStorage.Modules
local t = require(Modules.t)

--// TYPES
export type Data = {}

--// TEMPLATE
local template: Data = {}

--// SCHEMA
local schema = t.any

--// CREATING DATA STORE
local dataStore = Lyra.createPlayerStore({
	name = "PlayerData",
	template = template,
	schema = schema
} :: any)

--// MODULE
return dataStore