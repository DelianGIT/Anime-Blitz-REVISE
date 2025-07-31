--!strict
--// VARIABLES
local Module = {}

--// MODULE FUNCTIONS
function Module.Load(
	target: Model | AnimationController | Humanoid | Animator,
	animation: Animation,
	dontAutoDestroy: boolean?
): AnimationTrack
	local animator: Animator?
	if target:IsA("Animator") then
		animator = target
	elseif target:IsA("AnimationController") or target:IsA("Humanoid") then
		animator = target:FindFirstChild("Animator") :: Animator?
	else
		local animationController: (AnimationController | Humanoid)? = (
			target:FindFirstChild("AnimationController") :: AnimationController?
		) or target:FindFirstChild("Humanoid") :: Humanoid

		if not animationController then
			error(`Can't find an animation controller in {target:GetFullName()}`)
		else
			animator = animationController:FindFirstChild("Animator") :: Animator?
		end
	end
	if not animator then
		error(`Can't find an animator in {target:GetFullName()}`)
	end

	local animationTrack: AnimationTrack = animator:LoadAnimation(animation)
	if not dontAutoDestroy then
		animationTrack.Stopped:Once(function()
			animationTrack:Destroy()
		end)
	end

	return animationTrack
end

function Module.Play(
	target: Model | AnimationController | Humanoid | Animator,
	animation: Animation,
	dontAutoDestroy: boolean?
): AnimationTrack
	local animationTrack: AnimationTrack = Module.Load(target, animation, dontAutoDestroy)
	animationTrack:Play()
	return animationTrack
end

return Module
