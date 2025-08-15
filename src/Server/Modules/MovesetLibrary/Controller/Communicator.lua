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

--// REMOTE EVENT
local RemoteEvents = ReplicatedStorage.RemoteEvents
local MoveCommunication = require(RemoteEvents.Moveset).MoveCommunication

--// TYPES
type Function = (...any) -> ()
type Connection = {
	Function: Function,
	Thread: thread?,
}

--// CLASS
local Communicator = {}
Communicator.__index = Communicator

type CommunicatorData = {
	Player: Player,
	Connections: { [string]: Connection }
}
export type Communicator = typeof(setmetatable({} :: CommunicatorData, Communicator))

--// VARIABLES
local communicators: { [Player]: Communicator } = {}
local Module = {}

--// CLASS FUNCTIONS
function Communicator.Fire(self: Communicator, connectionName: string, ...: any): ()
	MoveCommunication.sendTo({
		ConnectionName = connectionName,
		Data = ...,
	}, self.Player)
end

function Communicator.Connect(self: Communicator, name: string, functionToConnect: Function): ()
	local connections: { [string]: Connection } = self.Connections
	connections[name] = {
		Function = functionToConnect
	}
end

function Communicator.Once(self: Communicator, name: string, functionToConnect: Function): ()
	local connections: { [string]: Connection } = self.Connections
	connections[name] = {
		Function = function(...: any)
			connections[name] = nil
			if functionToConnect then
				functionToConnect(...)
			end
		end
	}
end

function Communicator.Wait(self: Communicator, name: string, functionToConnect: Function): ()
	local thread: thread = coroutine.running()
	local connections: { [string]: Connection } = self.Connections
	connections[name] = {
		Function = function(...: any)
			connections[name] = nil
			if functionToConnect then
				functionToConnect(...)
			end
			coroutine.resume(thread)
		end,
		Thread = thread,
	}
	coroutine.yield()
end

function Communicator.Disconnect(self: Communicator, name: string): ()
	local connections: { [string]: Connection } = self.Connections
	local connection: Connection? = connections[name]
	if not connection then
		return
	end
	connections[name] = nil

	local thread: thread? = connection.Thread
	if thread then
		coroutine.resume(thread)
	end
end

--// MODULE FUNCTIONS
function Module.new(player: Player): Communicator
	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
	
	local existingCommunicator: Communicator? = tempData.MoveCommunicator :: Communicator?
	if existingCommunicator then
		error(`Player {player} already has MoveCommunicator`)
	end

	local communicator: Communicator = setmetatable({
		Player = player,
		Connections = {},
	}, Communicator)

	tempData = Sift.Dictionary.copy(tempData)
	tempData.MoveCommunicator = communicator
	DataStore.UpdateTemporaryData(player, tempData)

	communicators[player] = communicator

	return communicator
end

function Module.Destroy(player: Player): ()
	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
	local communicator: Communicator? = tempData.MoveCommunicator :: Communicator?
	if not communicator then
		error(`Player {player} doesn't have MoveCommunicator`)
	end

	tempData = Sift.Dictionary.copy(tempData)
	tempData.MoveCommunicator = nil
	DataStore.UpdateTemporaryData(player, tempData)

	communicators[player] = nil
end

--// EVENT
MoveCommunication.listen(function(data, player: Player?)
	if not player then
		return
	end

	local communicator: Communicator? = communicators[player]
	if not communicator then
		return
	end

	local connectionName: string = data.ConnectionName
	local connections: { [string]: Connection } = communicator.Connections
	local connection: Connection = connections[connectionName]
	if not connection then
		repeat
			task.wait()
			connection = connections[connectionName]
		until connection or not communicators[player]
	end

	connection.Function(data.Data)
end)

return Module