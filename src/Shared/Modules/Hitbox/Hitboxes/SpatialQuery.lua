--!strict
--// SERVICES
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local Signal = require(SharedModules.Signal)

local BaseFunctions = require(script.Parent.Parent.BaseFunctions)
local Visualization = require(script.Parent.Parent.Visualization)

--// TYPES
type RequestParams = BaseFunctions.Params<OverlapParams>
type Hits = BaseFunctions.Hits

type HitboxParams = {
	SingleHit: boolean?,
	DisableOnHit: boolean?,
	Interval: number?,
	Visualize: boolean?,
}

type Geometry = {
	CFrame: CFrame,
	Size: Vector3,
} | BasePart

--// CLASS
local Hitbox = {}
Hitbox.__index = Hitbox

type HitboxData = {
	Geometry: Geometry,
	RequestParams: RequestParams,
	Hitted: Signal.Signal<Hits>,
	SingleHit: boolean?,
	DisableOnHit: boolean?,
	Visualization: Part?,
	Interval: number?,

	Id: string?,
	EnabledTimestamp: number?,
	Thread: thread?,
	InitBlacklist: { Instance }?,
	LastActivationTimestamp: number?,
	Destroyed: boolean?,
}
type Hitbox = setmetatable<HitboxData, typeof(Hitbox)>

--// VARIABLES
local enabledHitboxes: { [string]: Hitbox } = {}
local Module = {}

local heartbeatConnection: RBXScriptConnection?

--// FUNCTIONS
local function isDestroyed(hitbox: Hitbox): ()
	if hitbox.Destroyed then
		error("Hitbox is destroyed")
	end
end

local function heartbeat(): ()
	local noHitboxes: boolean = true

	local currentTime: number?
	for _, hitbox: Hitbox in pairs(enabledHitboxes) do
		noHitboxes = false

		local interval: number? = hitbox.Interval
		if interval then
			currentTime = currentTime or os.clock()
			if currentTime - (hitbox.LastActivationTimestamp :: number) < interval then
				continue
			else
				hitbox.LastActivationTimestamp = currentTime
			end
		end

		local result: Hits = hitbox:GetHits()
		if not result then
			continue
		end

		if hitbox.DisableOnHit then
			hitbox:Disable()
		end

		if hitbox.SingleHit then
			local blacklist: { Instance } = (hitbox.RequestParams :: any).Blacklist
			for _, instance in ipairs(result) do
				if not table.find(blacklist, instance) then
					table.insert(blacklist, instance)
				end
			end
		end

		hitbox.Hitted:Fire(result)
	end

	if noHitboxes then
		(heartbeatConnection :: RBXScriptConnection):Disconnect()
		heartbeatConnection = nil
	end
end

--// CLASS FUNCTIONS
function Hitbox.GetHits(self: Hitbox): Hits
	isDestroyed(self)

	local geometry: Geometry = self.Geometry
	local cframe: CFrame = geometry.CFrame
	local size: Vector3 = geometry.Size

	local visualization: Part? = self.Visualization
	if visualization then
		visualization.CFrame = cframe
		visualization.Size = size

		if not self.Id then
			Visualization.Show(visualization)
		end
	end

	return BaseFunctions.SpatialQuery(cframe, size, self.RequestParams)
end

function Hitbox.Enable(self: Hitbox, duration: number?, yieldTillHitted: number?, disableOnHit: boolean?): ()
	isDestroyed(self)

	if self.Id then
		warn(`Hitbox is enabled already`)
		return
	end

	local thread: thread?
	if yieldTillHitted then
		thread = coroutine.running()
		self.Thread = thread
	end

	if self.SingleHit then
		local requestParams: RequestParams = self.RequestParams
		local blacklist: { Instance }? = requestParams.Blacklist
		if not blacklist then
			blacklist = {}
			requestParams.Blacklist = blacklist
		end

		self.InitBlacklist = table.clone(blacklist)
	end

	local visualization: BasePart? = self.Visualization
	if visualization then
		visualization.Parent = Visualization.Folder
	end

	local id: string = HttpService:GenerateGUID()
	self.Id = id
	enabledHitboxes[id] = self

	if not heartbeatConnection then
		heartbeatConnection = RunService.Heartbeat:Connect(heartbeat)
	end

	if duration then
		local timestamp: number = os.clock()
		self.EnabledTimestamp = timestamp

		task.delay(duration, function()
			if self.EnabledTimestamp == timestamp then
				self:Disable()
			end
		end)
	end

	if yieldTillHitted then
		coroutine.yield()
	end
end

function Hitbox.Disable(self: Hitbox): ()
	isDestroyed(self)

	local id: string? = self.Id
	if not id then
		warn(`Hitbox is disabled already`)
		return
	end
	enabledHitboxes[id] = nil
	self.Id = nil

	local visualization: Part? = self.Visualization
	if visualization then
		visualization.Parent = nil
	end

	local initBlacklist: { Instance }? = self.InitBlacklist
	if initBlacklist then
		self.InitBlacklist = nil
		self.RequestParams.Blacklist = initBlacklist
	end

	if self.Interval then
		self.LastActivationTimestamp = 0
	end

	local thread: thread? = self.Thread
	if thread then
		coroutine.resume(thread)
		self.Thread = nil
	end

	self.EnabledTimestamp = nil
end

function Hitbox.Destroy(self: Hitbox): ()
	isDestroyed(self)

	if self.Id then
		self:Disable()
	end

	local visualization: BasePart? = self.Visualization
	if visualization then
		visualization:Destroy()
	end
end

--// MODULE FUNCTIONS
function Module.new(geometry: Geometry, hitboxParams: HitboxParams, requestParams: RequestParams): Hitbox
	local cframe: CFrame = geometry.CFrame
	local size: Vector3 = geometry.Size
	if not cframe or not size then
		error(`Invalid geometry for SpatialQuery hitbox: {geometry}`)
	end

	local visualization: Part?
	if Visualization.IsEnabled(hitboxParams.Visualize) then
		visualization = Visualization.SpatialQuery(cframe, size, false)
	end

	local interval: number? = hitboxParams.Interval
	return setmetatable({
		Geometry = geometry,
		RequestParams = requestParams,
		Hitted = Signal.new(),
		SingleHit = hitboxParams.SingleHit,
		DisableOnHit = hitboxParams.DisableOnHit,
		Visualization = visualization,
		Interval = interval,
		LastActivationTimestamp = if interval then 0 else nil,
	}, Hitbox) :: Hitbox
end

return Module
