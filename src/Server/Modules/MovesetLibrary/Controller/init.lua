--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)

--// MODULES
local ServerModules = ServerScriptService.Modules
local DataStore = require(ServerModules.DataStore)
local Sequence = require(ServerModules.Sequence)

local Storage = require(script.Parent.Storage)
local Validator = require(script.Validator)
local Cooldown = require(script.Cooldown)
local Communicator = require(script.Communicator)

--// REMOTE EVENTS
local RemoteEvents = require(ReplicatedStorage.RemoteEvents.Moveset)
local RemoteEvent = RemoteEvents.MoveControl

--// TYPE
type CooldownType = Storage.CooldownType
type Cooldown = Storage.Cooldown

type Moveset = {
	Name: string,
	Moves: Storage.Moves
}
type Move = Storage.Move
type MoveFunctions = Storage.MoveFunctions
type MoveData = Storage.MoveData
type MoveState = "Start" | "ReadyToEnd" | "End" | "Cancel"

type Args = Storage.Args
type ActiveMove = {
	Name: string,
	State: MoveState,
	StartTimestamp: number?,
	Cache: { [any]: any },
	Cancelled: boolean?,
	RequestedEnd: boolean?,
	Track: Sequence.Track?
}

--// VARIABLES
local Module = {}

--// FUNCTIONS
local function finish(
	player: Player,
	moveName: string,
	cooldownType: CooldownType?
): ()
	if cooldownType == "End" then
		Cooldown.Start(player, moveName)
	end

	RemoteEvent.sendTo({
		Action = "Finished",
		MoveName = moveName,
	}, player)

	Communicator.Destroy(player)

	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
	tempData.ActiveMove = nil
	DataStore.UpdateTemporaryData(player, tempData)
end

--// MODULE FUNCTIONS
function Module.Start(player: Player, moveName: string, data: any, forced: boolean?): ()
	local isValid: boolean, reason: string? = Validator.Start(player, moveName)
	if not isValid then
		if not forced then
			RemoteEvent.sendTo({
				Action = "StartInvalid",
				MoveName = moveName
			}, player)
		end
		warn(`{player.Name} Invalid start: {reason}`)
		return
	else
		if not forced then
			RemoteEvent.sendTo({
				Action = "StartValid",
				MoveName = moveName,
			}, player)
		end
	end

	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
	local moveset: Moveset = tempData.Moveset :: Moveset
	local move: Move = moveset.Moves[moveName]
	local moveFunctions: MoveFunctions = move.Functions
	local moveData: MoveData = move.Data

	local duration: number?, startTimestamp: number?
	local endFunction: (Args) -> () | Sequence.Sequence = moveFunctions.End
	if endFunction then
		duration = moveData.Duration

		if duration then
			startTimestamp = os.clock()
		end
	end

	local cache: { [any]: any } = {}
	local activeMove: ActiveMove = {
		Name = moveName,
		State = "Start",
		Cache = cache,
		StartTimestamp = startTimestamp
	}

	tempData = Sift.Dictionary.copy(tempData)
	tempData.ActiveMove = activeMove :: any
	DataStore.UpdateTemporaryData(player, tempData)

	local cooldownType: CooldownType?
	local cooldown: Cooldown? = moveData.Cooldown
	if cooldown then
		cooldownType = cooldown.Type

		if cooldownType == "Begin" then
			Cooldown.Start(player, moveName)
		end
	end

	local communicator: Communicator.Communicator = Communicator.new(player)
	local args: Args = {
		Player = player,
		Character = player.Character :: Model,
		MoveData = moveData,
		Cache = cache,
		Communicator = communicator,
		Data = data
	}

	local success: boolean, errorMessage: string?
	local startFunction: (Args) -> () | Sequence.Sequence = moveFunctions.Start
	if typeof(startFunction) == "table" then
		local track: Sequence.Track = (startFunction :: Sequence.Sequence):CreateTrack()
		
		activeMove = Sift.Dictionary.copy(activeMove)
		activeMove.Track = track
		tempData = Sift.Dictionary.copy(tempData)
		tempData.ActiveMove = activeMove :: any
		DataStore.UpdateTemporaryData(player, tempData)

		track.Completed:Once(function(_success: boolean, _errorMessage: string?)
			success, errorMessage = _success, _errorMessage
		end)
	elseif typeof(startFunction) == "function" then
		success, errorMessage = pcall(startFunction, args)
	end
	
	tempData = DataStore.GetTemporaryData(player)
	activeMove = tempData.ActiveMove :: ActiveMove
	if activeMove.Cancelled then
		return
	end

	if not success then
		warn(`Start of {moveName} of moveset {moveset.Name} for {player.Name} threw an error: {errorMessage}`)
		Module.Cancel(player)
	else
		if endFunction then
			local moveState: MoveState = activeMove.State
			if moveState == "End" then
				activeMove = Sift.Dictionary.copy(activeMove)
				activeMove.State = "ReadyToEnd"
				tempData = Sift.Dictionary.copy(tempData)
				tempData.ActiveMove = activeMove :: any
				DataStore.UpdateTemporaryData(player, tempData)

				Module.End(player, moveName, nil, true)
			else
				activeMove = Sift.Dictionary.copy(activeMove)
				activeMove.State = "ReadyToEnd"
				tempData = Sift.Dictionary.copy(tempData)
				tempData.ActiveMove = activeMove :: any
				DataStore.UpdateTemporaryData(player, tempData)
				tempData = Sift.Dictionary.set(tempData, "ActiveMove", activeMove :: any)

				if duration then
					task.delay(duration, function()
						tempData = DataStore.GetTemporaryData(player)

						local currentActiveMove: ActiveMove? = tempData.ActiveMove :: ActiveMove?
						if currentActiveMove and currentActiveMove.StartTimestamp == startTimestamp then
							Module.End(player, moveName, nil, true)
						end
					end)
				end
			end
		else
			finish(player, moveName, cooldownType)
		end
	end
end

function Module.End(player: Player, moveName: string?, data: any, forced: boolean?)
	local isValid: boolean, reason: string? = Validator.End(player, moveName)
	if not isValid then
		if not forced then
			RemoteEvent.sendTo({
				Action = "EndInvalid",
				MoveName = moveName :: string,
			}, player)
			warn(`{player.Name} Invalid end: {reason}`)
		end
		return
	else
		if forced then
			RemoteEvent.sendTo({
				Action = "ForceEnd",
				MoveName = moveName :: string,
			}, player)
		else
			RemoteEvent.sendTo({
				Action = "EndValid",
				MoveName = moveName :: string,
			}, player)
		end
	end

	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
	local activeMove: ActiveMove = tempData.ActiveMove :: ActiveMove
	moveName = moveName or activeMove.Name

	local moveset: Moveset = tempData.Moveset :: Moveset
	local move: Move = moveset.Moves[moveName]
	local moveFunctions: MoveFunctions = move.Functions
	local moveData: MoveData = move.Data

	local args: Args = {
		Player = player,
		Character = player.Character :: Model,
		MoveData = moveData,
		Cache = activeMove.Cache,
		Communicator = tempData.MoveCommunicator,
		Data = data
	}
	
	local success: boolean, errorMessage: string?
	local endFunction: (Args) -> () | Sequence.Sequence = moveFunctions.Start
	if typeof(endFunction) == "table" then
		local track: Sequence.Track = (endFunction :: Sequence.Sequence):CreateTrack()

		activeMove = Sift.Dictionary.copy(activeMove)
		activeMove.Track = track
		tempData = Sift.Dictionary.copy(tempData)
		tempData.ActiveMove = activeMove :: any
		DataStore.UpdateTemporaryData(player, tempData)

		track.Completed:Once(function(_success: boolean, _errorMessage: string?)
			success, errorMessage = _success, _errorMessage
		end)
	elseif typeof(endFunction) == "function" then
		success, errorMessage = pcall(endFunction, args)
	end

	tempData = DataStore.GetTemporaryData(player)
	activeMove = tempData.ActiveMove :: ActiveMove
	if activeMove.Cancelled then
		return
	end

	if not success then
		warn(`End of {moveName} of {moveset.Name} for {player.Name} threw an error: {errorMessage}`)
		Module.Cancel(player)
	else
		local cooldownType: CooldownType?
		local cooldown: Cooldown? = moveData.Cooldown
		if cooldown then
			cooldownType = cooldown.Type
		end
		finish(player, moveName, cooldownType)
	end
end

function Module.Cancel(player: Player, dontReplicate: boolean?)
	local isValid: boolean, reason: string? = Validator.Cancel(player)
	if not isValid then
		warn(`{player.Name} Invalid cancel: {reason}`)
		return
	end

	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
	local activeMove: ActiveMove = tempData.ActiveMove :: ActiveMove
	local moveName: string = activeMove.Name

	if not dontReplicate then
		RemoteEvent.sendTo({
			Action = "Cancel",
			MoveName = moveName,
		}, player)
	end

	local track: Sequence.Track? = activeMove.Track
	if track then
		track:Stop()
	end

	activeMove = Sift.Dictionary.copy(activeMove)
	activeMove.Cancelled = true
	tempData = Sift.Dictionary.copy(tempData)
	tempData.ActiveMove = activeMove :: any
	DataStore.UpdateTemporaryData(player, tempData)

	local moveset: Moveset = tempData.Moveset :: Moveset
	local move: Move = moveset.Moves[moveName]
	local moveData: MoveData = move.Data

	local cancelFunction: (args: Args) -> ()? = move.Functions.Cancel
	if cancelFunction then
		local success: boolean, errorMessage: string? = pcall(cancelFunction, {
			Player = player,
			Character = player.Character :: Model,
			MoveData = moveData,
			Cache = activeMove.Cache,
			Communicator = tempData.MoveCommunicator
		})
		
		if not success then
			warn(`Cancel of {moveName} of {moveset.Name} for {player.Name} threw an error: {errorMessage}`)
		end
	end

	local cooldown: Cooldown? = moveData.Cooldown
	if cooldown then
		if cooldown.Type == "End" then
			Cooldown.Start(player, moveName)
		end
	end

	Communicator.Destroy(player)

	tempData = Sift.Dictionary.copy(tempData)
	tempData.ActiveMove = nil
	DataStore.UpdateTemporaryData(player, tempData)
end

--// EVENTS

return Module