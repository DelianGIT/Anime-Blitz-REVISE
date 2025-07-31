--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local ByteNet = require(Packages.ByteNet)

--// REMOTE EVENT
return ByteNet.defineNamespace("BodyMoversController", function()
	return {
		Create = ByteNet.definePacket({
			value = ByteNet.struct({
				Name = ByteNet.string,
				MoverType = ByteNet.string :: ("LinearVelocity"),
				Params = ByteNet.struct({
					Priority = ByteNet.uint8,
					Duration = ByteNet.optional(ByteNet.float32),
					MoverProperties = ByteNet.optional(ByteNet.map(ByteNet.string, ByteNet.unknown))
				})
			}),
		}),

		Destroy = ByteNet.definePacket({
			value = ByteNet.struct({
				Name = ByteNet.string,
				MoverType = ByteNet.string :: ("LinearVelocity")
			}),
		})
	}
end)
