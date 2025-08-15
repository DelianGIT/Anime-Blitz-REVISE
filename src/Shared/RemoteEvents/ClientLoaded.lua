--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local ByteNet = require(Packages.ByteNet)

--// REMOTE EVENT
return ByteNet.defineNamespace("ClientLoaded", function()
	return {
		Loaded = ByteNet.definePacket({
			value = ByteNet.nothing
		})
	}
end)
