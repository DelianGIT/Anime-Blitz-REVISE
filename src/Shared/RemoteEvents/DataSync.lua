--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local ByteNet = require(Packages.ByteNet)

--// REMOTE EVENT
return ByteNet.defineNamespace("PlayerDataSync", function()
	return {
		Sync = ByteNet.definePacket({
			value = ByteNet.struct({
				type = ByteNet.string,
				data = ByteNet.struct({
					TemporaryData = ByteNet.unknown,
					TeamA = ByteNet.optional(ByteNet.map(ByteNet.inst :: Player, ByteNet.bool)),
					TeamB = ByteNet.optional(ByteNet.map(ByteNet.inst :: Player, ByteNet.bool))
				})
			})
		}),

		Request = ByteNet.definePacket({
			value = ByteNet.nothing
		})
	}
end)
