--!strict
--// VARIABLES
local Module = {}

--// FUNCTIONS
local function emitParticleEmitter(particleEmitter: ParticleEmitter): ()
	local duration: number? = particleEmitter:GetAttribute("EmitDuration") :: number?
	if duration then
		particleEmitter.Enabled = true
		task.delay(duration, function()
			particleEmitter.Enabled = false
		end)
		return
	end

	local count: number? = particleEmitter:GetAttribute("EmitCount") :: number?
	if count then
		local emitDelay: number? = particleEmitter:GetAttribute("EmitDelay") :: number?
		task.delay(emitDelay, function()
			particleEmitter:Emit(count)
		end)
	end
end

local function emitBeamOrTrail(beam: Trail): ()
	local duration: number? = beam:GetAttribute("EmitDuration") :: number?
	if duration and duration > 0 then
		beam.Enabled = true
		task.delay(duration, function()
			beam.Enabled = false
		end)
	end
end

--// MODULE FUNCTIONS
function Module.Emit(instance: Instance): ()
	if instance:IsA("ParticleEmitter") then
		emitParticleEmitter(instance)
	elseif instance:IsA("Beam") or instance:IsA("Trail") then
		emitBeamOrTrail(instance)
	else
		task.spawn(function()
			for _, childInstance in ipairs(instance:GetChildren()) do
				Module.Emit(childInstance)
			end
		end)
	end
end

function Module.Enable(instance: Instance): ()
	if instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail") then
		instance.Enabled = true
	else
		task.spawn(function()
			for _, childInstance in ipairs(instance:GetChildren()) do
				Module.Enable(childInstance)
			end
		end)
	end
end

function Module.Disable(instance: Instance): ()
	if instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail") then
		instance.Enabled = false
	else
		task.spawn(function()
			for _, childInstance in ipairs(instance:GetChildren()) do
				Module.Enable(childInstance)
			end
		end)
	end
end

return Module
