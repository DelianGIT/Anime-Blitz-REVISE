--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local ByteNet = require(Packages.ByteNet)

--// REMOTE EVENT
return ByteNet.defineNamespace("Knockback", function()
	return {
		Apply = ByteNet.definePacket({
			value = ByteNet.struct({
				UnitVector = ByteNet.vec3,
				Params = ByteNet.struct({
					Priority = ByteNet.uint8,
					Velocity = ByteNet.uint8,
					Duration = ByteNet.optional(ByteNet.float32),
					FromPoint = ByteNet.optional(ByteNet.bool),
				})
			}),
		}),

		Cancel = ByteNet.definePacket({
			value = ByteNet.nothing
		})
	}
end)
