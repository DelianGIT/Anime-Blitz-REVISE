--!strict
--// FUNCTIONS
local function requireScripts(folder: Folder | Script): ()
	for _, module: Instance in ipairs(folder:GetChildren()) do
		if module:IsA("Folder") then
			requireScripts(module)
			continue
		elseif not module:IsA("ModuleScript") then
			continue
		end

		local success: boolean, err: string?, yielded: boolean
		task.spawn(function()
			success, err = pcall(require, module)
			yielded = false
		end)

		if yielded then
			warn("Yielded while requiring" .. module:GetFullName())
		end
		if success == false then
			error(`{module:GetFullName()} threw an error while requiring: {err}`)
		end
	end
end

--// REQUIRING SCRIPTS
requireScripts(script)

print("Server loaded")
