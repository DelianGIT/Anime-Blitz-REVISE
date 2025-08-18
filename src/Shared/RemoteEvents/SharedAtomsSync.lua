--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local ByteNet = require(Packages.ByteNet)

--// REMOTE EVENT
return ByteNet.defineNamespace("SharedAtomsSync", function()
	return {
		Sync = ByteNet.definePacket({
			value = ByteNet.struct({
				type = ByteNet.string,
				data = ByteNet.struct({
					Team = ByteNet.map(ByteNet.inst :: Player, ByteNet.string :: ("A" | "B" | "None")),
					CharacterData = ByteNet.optional(ByteNet.struct({
						Name = ByteNet.string,
						Category = ByteNet.string,
						Properties = ByteNet.struct({
							Health = ByteNet.uint8
						})
					}))
				})
			})
		}),

		Request = ByteNet.definePacket({
			value = ByteNet.nothing
		})
	}
end)
