--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local Modules = ReplicatedStorage.Modules
local t = require(Modules.t)

--// TYPES
export type Data = {}

--// TEMPLATE
local template: Data = {}

--// SCHEMA
local schema = t.any

--// MODULE
return {
	Template = template,
	Schema = schema
}