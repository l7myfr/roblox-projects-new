-- @ScriptType: LocalScript
local ControllersFolder = game.ReplicatedStorage:WaitForChild("Client"):WaitForChild("Controllers")

local Controllers = {
	LoadedControllers = {},
	Pending = {} 
}
setmetatable({}, Controllers)
function Controllers:GetController(name: string)
	return Controllers.LoadedControllers[name]
end

function Controllers:WaitForController(name: string)
	local Controller = self:GetController(name)
	if Controller then
		return Controller
	end

	local thread = coroutine.running()
	if not self.Pending[name] then
		self.Pending[name] = {}
	end
	table.insert(self.Pending[name], thread)
	return coroutine.yield()
end
local function LoadController(ControllerModule)
	if ControllerModule:IsA("ModuleScript") then
		local success, Controller = pcall(require, ControllerModule)
		if success then
			if typeof(Controller) == "table" then
				if typeof(Controller.init) == "function" then
					Controller = Controller.init(Controllers)
				end
				if typeof(Controller.Start) == "function" then
					Controller:Start()
				end
				Controllers.LoadedControllers[ControllerModule.Name] = Controller
				if Controllers.Pending[ControllerModule.Name] then
					for _, thread in Controllers.Pending[ControllerModule.Name] do
						task.spawn(thread, Controller)
					end
					Controllers.Pending[ControllerModule.Name] = nil
				end
			else
				warn("[Controllers] Module did not return a table:", ControllerModule.Name)
			end
		else
			warn("[Controllers] Error requiring:", ControllerModule.Name, Controller)
		end
	end
end

for _, ControllerModule in ControllersFolder:GetDescendants() do
	task.spawn(function()
		LoadController(ControllerModule)
	end)
end
ControllersFolder.DescendantAdded:Connect(function(ControllerModule)
	LoadController(ControllerModule)
end)
