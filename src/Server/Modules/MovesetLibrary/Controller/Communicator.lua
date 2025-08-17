--!strict
--// SERVICES
local Players = game:GetService("Players")
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
local Module = {}

--// CLASS FUNCTIONS
function Communicator.Fire(self: Communicator, connectionName: string, ...: any): ()
	MoveCommunication.sendTo({
		ConnectionName = connectionName,
		Data = ...,
	}, self.Player)
end

function Communicator.Connect(self: Communicator, name: string, functionToConnect: Function): ()
	self.Connections[name] = {
		Function = functionToConnect
	} :: Connection
end

function Communicator.Once(self: Communicator, name: string, functionToConnect: Function): ()
	self.Connections[name] = {
		Function = function(...: any)
			self.Connections = Sift.Dictionary.removeKey(self.Connections, name)
			
			if functionToConnect then
				functionToConnect(...)
			end
		end
	} :: Connection
end

function Communicator.Wait(self: Communicator, name: string, functionToConnect: Function): ()
	local thread: thread = coroutine.running()
	
	self.Connections[name] = {
		Function = function(...: any)
			self.Connections = Sift.Dictionary.removeKey(self.Connections, name)
			
			if functionToConnect then
				functionToConnect(...)
			end

			coroutine.resume(thread)
		end,
		Thread = thread
	} :: Connection

	coroutine.yield()
end

function Communicator.Disconnect(self: Communicator, name: string): ()
	local connections: { [string]: Connection } = self.Connections
	local connection: Connection? = connections[name]
	if not connection then
		return
	end
	self.Connections[name] = nil

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

	tempData = Sift.Dictionary.set(tempData, "MoveCommunicator", communicator)
	DataStore.UpdateTemporaryData(player, tempData)

	return communicator
end

function Module.Destroy(player: Player): ()
	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
	
	local communicator: Communicator? = tempData.MoveCommunicator :: Communicator?
	if not communicator then
		error(`Player {player} doesn't have MoveCommunicator`)
	end

	tempData = Sift.Dictionary.removeKey(tempData, "MoveCommunicator")
	DataStore.UpdateTemporaryData(player, tempData)
end

--// EVENT
MoveCommunication.listen(function(data, player: Player?)
	if not player then
		return
	end

	local tempData: DataStore.TemporaryData = DataStore.GetTemporaryData(player)
	local communicator: Communicator? = tempData.MoveCommunicator
	if not communicator then
		return
	end

	local connectionName: string = data.ConnectionName
	local connection: Connection = communicator.Connections[connectionName]
	if not connection then
		repeat
			task.wait()
			connection = communicator.Connections[connectionName]
		until connection or player.Parent ~= Players
	end

	connection.Function(data.Data)
end)

return Module