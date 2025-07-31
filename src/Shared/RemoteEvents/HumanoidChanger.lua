--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local ByteNet = require(Packages.ByteNet)

--// REMOTE EVENT
return ByteNet.defineNamespace("HumanoidChanger", function()
	return {
		Change = ByteNet.definePacket({
			value = ByteNet.struct({
				Name = ByteNet.string,
				Properties = ByteNet.map(ByteNet.string, ByteNet.uint8),
				Params = ByteNet.struct({
					Priority = ByteNet.uint8,
					Duration = ByteNet.optional(ByteNet.float32),
					TweenInfo = ByteNet.optional(ByteNet.inst :: TweenInfo),
				})
			}),
		}),

		Cancel = ByteNet.definePacket({
			value = ByteNet.string
		})
	}
end)
