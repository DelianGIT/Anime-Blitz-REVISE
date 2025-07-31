--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)

--// TYPES
type Key = Enum.KeyCode | Enum.UserInputType
type State = "Begin" | "End"
type BindedFunction = () -> ()
type KeybindsFolder = { [string]: Keybind }
type KeysFolder = { [Key]: KeybindsFolder }

-- // CONSTANTS
local BUFFER_TIME_WINDOW = 0.5

--// CLASS
local Keybind = {}
Keybind.__index = Keybind

type KeybindData = {
	Name: string,
	State: State,
	Key: Key,
	BindedFunction: BindedFunction,
	CanBeBuffered: boolean,

	Disabled: boolean,
	Destroyed: boolean,
}
type Keybind = setmetatable<KeybindData, typeof(Keybind)>

--// VARIABLES
local processes: { thread } = {}
local statesFolder: { [State]: KeysFolder } = {
	Begin = {},
	End = {},
}
local Module = {}

--// FUNCTIONS
local function getKeybindsFolder(keysFolder: KeysFolder, key: Key): KeybindsFolder
	local keybindsFolder: KeybindsFolder = keysFolder[key]
	if not keybindsFolder then
		keybindsFolder = {}
		keysFolder[key] = keybindsFolder
	end
	return keybindsFolder
end

local function getKeyFromInput(input: InputObject): Key
	local inputType: Enum.UserInputType = input.UserInputType
	if inputType == Enum.UserInputType.Keyboard then
		return input.KeyCode
	else
		return inputType
	end
end

local function bufferProcess(keybind: Keybind): (boolean, string?)
	local thread: thread = coroutine.running()
	table.insert(processes, thread)

	local timestamp: number = os.clock()
	if #processes > 1 then
		coroutine.yield()
	end

	local success: boolean, errorMessage: string?
	if (os.clock() - timestamp) <= BUFFER_TIME_WINDOW then
		success, errorMessage = pcall(keybind.BindedFunction)
	end

	local index: number? = table.find(processes, thread)
	if index then
		table.remove(processes, index)

		if processes[1] then
			coroutine.resume(processes[1])
		end
	end

	return success, errorMessage
end

local function processInput(state: State, input: InputObject): ()
	local key: Key = getKeyFromInput(input)
	local keybindsFolder: KeybindsFolder? = statesFolder[state][key]
	if not keybindsFolder then
		return
	end

	for _, keybind: Keybind in pairs(keybindsFolder) do
		if keybind.Disabled then
			continue
		end

		task.spawn(function()
			local success: boolean, errorMessage: string?
			if keybind.CanBeBuffered then
				success, errorMessage = bufferProcess(keybind)
			else
				success, errorMessage = pcall(keybind.BindedFunction)
			end

			if success == false then
				warn(`Keybind {keybind.State}_{keybind.Key.Name}_{keybind.Name} threw an error: {errorMessage}`)
			end
		end)
	end
end

--// CLASS FUNCTIONS
function Keybind.Enable(self: Keybind): ()
	if self.Disabled then
		self.Disabled = false
	end
end

function Keybind.Disable(self: Keybind): ()
	if not self.Disabled then
		self.Disabled = true
	end
end

function Keybind.Destroy(self: Keybind): ()
	local key: Key = self.Key
	local keysFolder: KeysFolder = statesFolder[self.State]

	local keybindsFolder: KeybindsFolder = keysFolder[key]
	keybindsFolder[self.Name] = nil

	self.Destroyed = true

	if Sift.isEmpty(keybindsFolder) then
		keysFolder[key] = nil
	end
end

--// MODULE FUNCTIONS
function Module.Add(name: string, state: State, key: Key, funcToBind: BindedFunction, canBeBuffered: boolean): Keybind
	local keybind: Keybind = setmetatable({
		Name = name,
		State = state,
		Key = key,
		BindedFunction = funcToBind,
		CanBeBuffered = canBeBuffered,

		Disabled = false,
		Destroyed = false,
	}, Keybind)

	local folder: KeybindsFolder = getKeybindsFolder(statesFolder[state], key)
	folder[name] = keybind

	return keybind
end

--// EVENTS
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if not gameProcessedEvent then
		processInput("Begin", input)
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if not gameProcessedEvent then
		processInput("End", input)
	end
end)

return Module
