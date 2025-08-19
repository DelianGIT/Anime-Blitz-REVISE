--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// MODULES
local ServerModules = ServerScriptService.Modules
local PlayerData = require(ServerModules.PlayerData)

local Types = require(script.Parent.Parent.Types)

--// REMOTE EVENTS
local RemoteEvents = require(ReplicatedStorage.RemoteEvents.Moveset)
local RemoteEvent = RemoteEvents.MoveCommunication

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
local movesetAtom = PlayerData.Atoms.Moveset

local Module = {}

--// CLASS FUNCTIONS
function Communicator.Fire(self: Communicator, connectionName: string, ...: any): ()
	RemoteEvent.sendTo({
		ConnectionName = connectionName,
		Data = ...
	}, self.Player)
end

function Communicator.Connect(self: Communicator, connectionName: string, functionToConnect: Function): ()
	self.Connections[connectionName] = {
		Function = functionToConnect
	}
end

function Communicator.Once(self: Communicator, connectionName: string, functionToConnect: Function): ()
	self.Connections[connectionName] = {
		Function = function(...: any)
			self:Disconnect(connectionName)
			functionToConnect(...)
		end
	}
end

function Communicator.Wait(self: Communicator, connectionName: string): ()
	local thread: thread = coroutine.running()
	self.Connections[connectionName] = {
		Function = function()
			self:Disconnect(connectionName)
			coroutine.resume(thread)
		end,
		Thread = thread
	}
	coroutine.yield()
end

function Communicator.Disconnect(self: Communicator, connectionName: string): ()
	local connections: { [string]: Connection } = self.Connections
	
	local connection: Connection? = connections[connectionName]
	if not connection then
		return
	end
	connections[connectionName] = nil

	local thread: thread? = connection.Thread
	if thread then
		coroutine.resume(thread)
	end
end

function Communicator.DisconnectAll(self: Communicator): ()
	for connectionName, _ in pairs(self.Connections) do
		self:Disconnect(connectionName)
	end
end

--// MODULE FUNCTIONS
function Module.new(player: Player): Communicator
	return setmetatable({
		Player = player,
		Connections = {}
	}, Communicator)
end

--// EVENT
RemoteEvent.listen(function(data, player: Player?)
	if not player then
		return
	end

	local moveset: Types.Moveset = movesetAtom()[player]
	if not moveset then
		error(`Player {player} doesn't have a moveset`)
	end

	local communicator: Communicator = moveset.Communicator
	local connections: { [string]: Connection } = communicator.Connections

	local connectionName: string = data.ConnectionName
	local connection: Connection = connections[connectionName]
	if not connection then
		repeat
			task.wait()
			connection = connections[connectionName]
		until connection or not movesetAtom()[player]
	end

	connection.Function(data.Data)
end)

return Module
