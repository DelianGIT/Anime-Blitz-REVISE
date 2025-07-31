--!strict
--// MODULES
local BaseFunctions = require(script.BaseFunctions)
local PreciseSpatialQuery = require(script.Hitboxes.PreciseSpatialQuery)
local Raycast = require(script.Hitboxes.Raycast)
local SpatialQuery = require(script.Hitboxes.SpatialQuery)
local Spherecast = require(script.Hitboxes.Spherecast)

--// TYPES
export type RaycastResult = Raycast.CustomRaycastResult

--// VARIABLES
local Module = {}

--// MODULE FUNCTIONS
Module.Raycast = BaseFunctions.Raycast
Module.Spherecast = BaseFunctions.Spherecast
Module.SpatialQuery = BaseFunctions.SpatialQuery
Module.PreciseSpatialQuery = BaseFunctions.PreciseSpatialQuery

Module.CreateRaycast = Raycast.new
Module.CreateSpherecast = Spherecast.new
Module.CreateSpatialQuery = SpatialQuery.new
Module.CreatePreciseSpatialQuery = PreciseSpatialQuery.new

return Module
