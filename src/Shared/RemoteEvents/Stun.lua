--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local ByteNet = require(Packages.ByteNet)

--// REMOTE EVENT
return ByteNet.defineNamespace("Stun", function()
	return {
		Apply = ByteNet.definePacket({
			value = ByteNet.struct({
				Duration = ByteNet.optional(ByteNet.float32),
				WalkSpeed = ByteNet.optional(ByteNet.uint8),
				JumpPower = ByteNet.optional(ByteNet.uint8),
			})
		}),

		Cancel = ByteNet.definePacket({
			value = ByteNet.nothing
		})
	}
end)
