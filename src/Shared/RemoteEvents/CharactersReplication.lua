--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local ByteNet = require(Packages.ByteNet)

--// REMOTE EVENT
return ByteNet.defineNamespace("CharactersReplication", function()
	return {
		AddExistingCharacters = ByteNet.definePacket({
			value = ByteNet.struct({
				NetworkId = ByteNet.uint8,
				CharactersNames = ByteNet.map(ByteNet.uint8, ByteNet.string)
			}),
		}),

		AddCharacter = ByteNet.definePacket({
			value = ByteNet.struct({
				Id = ByteNet.uint8,
				CharacterName = ByteNet.string
			})
		}),

		RemoveCharacter = ByteNet.definePacket({
			value = ByteNet.struct({
				Id = ByteNet.uint8,
				CharacterName = ByteNet.string
			})
		}),

		ClientReplicateCFrame = ByteNet.definePacket({
			value = ByteNet.struct({
				Timestamp = ByteNet.float32,
				CFrame = ByteNet.cframe
			})
		}),

		ServerReplicateCFrame = ByteNet.definePacket({
			value = ByteNet.struct({
				Timestamps = ByteNet.map(ByteNet.uint8, ByteNet.float32),
				CFrames = ByteNet.map(ByteNet.uint8, ByteNet.cframe)
			})
		}),

		TickRateChanged = ByteNet.definePacket({
			value = ByteNet.struct({
				Id = ByteNet.uint8,
				TickRate = ByteNet.float32
			})
		}),

		TogglePlayerReplication = ByteNet.definePacket({
			value = ByteNet.struct({
				Id = ByteNet.uint8,
				Toggle = ByteNet.bool
			})
		})
	}
end)
