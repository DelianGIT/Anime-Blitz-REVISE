--!strict
--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)

--// TYPES
type Animations = { [string]: Animation }
type AnimationTracks = { [string]: AnimationTrack }

--// VARIABLES
local animations: { [string]: Animations } = {}
local animationTracks: { [string]: AnimationTracks } = {}
local Module = {}

local animator: Animator?

--// MODULE FUNCTIONS
function Module.AddAnimations(name: string, animationsToAdd: { [string]: Animation }): AnimationTracks?
	if animations[name] then
		warn(`Animations {name} are added already`)
		return nil
	end

	if animator then
		local _animationsPack: Animations = {}
		local _animationTracks: AnimationTracks = {}

		for name, animation in pairs(animationsToAdd) do
			_animationsPack[name] = animation
			_animationTracks[name] = animator:LoadAnimation(animation)
		end

		animations[name] = _animationsPack
		animationTracks[name] = _animationTracks

		return _animationTracks
	else
		animations[name] =  Sift.Dictionary.copyDeep(animationsToAdd)

		return nil
	end
end

function Module.RemoveAnimations(name: string): ()
	if not animations[name] then
		warn(`Animations {name} don't exist`)
		return
	end

	animations[name] = nil

	local _animationTracks: AnimationTracks? = animationTracks[name]
	if _animationTracks then
		for _, animationTrack in pairs(_animationTracks) do
			animationTrack:Destroy()
		end
	end
end

function Module.HasAnimations(name: string): boolean
	if animations[name] then
		return true
	else
		return false
	end
end

function Module.GetTracks(name: string): AnimationTracks?
	if animator then
		return animationTracks[name]
	else
		return nil
	end
end

function Module._SetAnimator(_animator: Animator?): ()
	animator = _animator

	if animator then
		for _name, _animations in pairs(animations) do
			local _animationTracks: AnimationTracks = {}
			for name, animation in pairs(_animations) do
				_animationTracks[name] = animator:LoadAnimation(animation)
			end
			animationTracks[_name] = _animationTracks
		end
	else
		for _, _animationTracks in pairs(animationTracks) do
			for _, animationTrack in pairs(_animationTracks) do
				animationTrack:Destroy()
			end
		end
		animationTracks = {}
	end
end

return Module
