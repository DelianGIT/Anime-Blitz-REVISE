--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local ByteNet = require(Packages.ByteNet)

--// REMOTE EVENT
return ByteNet.defineNamespace("Vfx", function()
	return {
		Cast = ByteNet.definePacket({
			value = ByteNet.struct({
				Caster = ByteNet.inst :: Model,
				Data = ByteNet.optional(ByteNet.unknown),
				Timestamp = ByteNet.float64,
				Identifier = ByteNet.struct({
					Pack = ByteNet.string,
					Vfx = ByteNet.string,
					Function = ByteNet.optional(ByteNet.string),
				}),
			}),
		})
	}
end)
