-- @ScriptType: ModuleScript
local module = {}
local RegenerateModule = require(script.Parent.Regenerate)
local RunService = game:GetService("RunService")
local Tasks = {}
Tasks.__index = Tasks
module.__index = module
local SharedModules = script.Parent.Parent.Parent.Shared
local Network = require(SharedModules.Network)
function module.New(Data, Server)
	if not Data.VoxelHolder then return end 
	local self = setmetatable({}, module)
	self.VoxelHolder = Data.VoxelHolder
	self.Object = Data.VoxelHolder.PrimaryPart
	self.RegenerateFunction = RegenerateModule.New(self.Object, Server)
	self.RegenerationTime = Data.RegenerationTime  or 15
	self.RenderId = Data.Id
	self:Start()
	return self
end

function module:Start()
	local VoxelHolder = self.VoxelHolder
	if Tasks[VoxelHolder] and Tasks[VoxelHolder].TimeLeft and Tasks[VoxelHolder].TimeLeft > self.RegenerationTime then
		return 
	end
	local RenderIds = {}
	if Tasks[VoxelHolder] then
		task.cancel(Tasks[VoxelHolder].Handle)
		for Index, Value in Tasks[VoxelHolder].Ids do
			RenderIds[Index] = Value
 		end
		Tasks[VoxelHolder] = nil
	end
	if not Tasks[VoxelHolder]  then
		RenderIds[self.RenderId]= true
		Tasks[VoxelHolder] = {
			TimeLeft = self.RegenerationTime, 
			Ids = RenderIds
		}
		Tasks[VoxelHolder].Handle = task.spawn(function()
			while Tasks[VoxelHolder] and Tasks[VoxelHolder].TimeLeft > 0 do
				local dt = RunService.Heartbeat:Wait() 
				Tasks[VoxelHolder].TimeLeft = Tasks[VoxelHolder].TimeLeft - dt
			end

			if Tasks[VoxelHolder] and Tasks[VoxelHolder].TimeLeft <= 0 then
				self.RegenerateFunction:Regenerate()
				Network:FireAll("DestroyVoxelRender", RenderIds)
			end
			Tasks[VoxelHolder] = nil

		end)
	end

end

return module
