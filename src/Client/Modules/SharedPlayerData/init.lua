--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local CharmSync = require(Packages.CharmSync)

--// MODULES
local SharedAtoms = require(script.SharedAtoms)

--// REMOTE EVENTS
local RemoteEvents = require(ReplicatedStorage.RemoteEvents.SharedAtomsSync)
local Sync = RemoteEvents.Sync
local Request = RemoteEvents.Request

--// SYNCER
local syncer = CharmSync.client({
	atoms = SharedAtoms :: any,
	ignoreUnhydrated = true,
})

--// EVENTS
Sync.listen(function(payload: any)
	syncer:sync(payload)
end)

--// REQUESTING THE INITIAL STATE
Request.send()
Sync.wait()

return SharedAtoms