--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local t = require(SharedModules.t)

--// TEMPLATE
local template = {
}

--// SCHEMA
local schema = t.any

return {
	Template = template,
	Schema = schema,
}
