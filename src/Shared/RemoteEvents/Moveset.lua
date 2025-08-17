--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local ByteNet = require(Packages.ByteNet)

--// REMOTE EVENT
return ByteNet.defineNamespace("Moveset", function()
	return {
		Give = ByteNet.definePacket({
			value = ByteNet.string
		}),

		Take = ByteNet.definePacket({
			value = ByteNet.nothing
		}),

		MoveCommunication = ByteNet.definePacket({
			value = ByteNet.struct({
				ConnectionName = ByteNet.string,
				Data = ByteNet.unknown
			})
		}),

		MoveControl = ByteNet.definePacket({
			value = ByteNet.struct({
				Action = ByteNet.string,
				MoveName = ByteNet.string
			})
		})
	}
end)
