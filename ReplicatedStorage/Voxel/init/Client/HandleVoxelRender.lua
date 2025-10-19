-- @ScriptType: ModuleScript
local module = {}
local RunService = game:GetService("RunService")
local ApplyForce = require(script.Parent.ApplyForce)
module.__index = module
local function Copy(Part, Data)
	Part.Position = Data.Position
	Part.Size = Data.Size
	Part.Color = Data.Color
	Part.Transparency = Data.Transparency
	Part.Material = Data.Material
	Part.TopSurface = Data.TopSurface
	Part.BottomSurface = Data.BottomSurface
	Part.LeftSurface = Data.LeftSurface
	Part.RightSurface = Data.RightSurface
	Part.FrontSurface = Data.FrontSurface
	Part.BackSurface = Data.BackSurface
end
function module.new(RenderVoxelData, Clientself)
	local self = setmetatable({}, module)
	self.Client = Clientself
	self.CachedParts = {}
	for _, PartData in RenderVoxelData.Parts do
		self:AddVoxel(PartData, RenderVoxelData)
		RunService.Heartbeat:Wait()
	end
	return self
end

function module:Destroy()
	for _, part in self.CachedParts do
		if not part then continue end
		self.Client.PooledClass:Return(part)
	end
end
function module:AddVoxel(PartData, RenderVoxelData)
	local Part = self.Client.PooledClass:Get()
	Copy(Part, PartData)
	Part.Anchored = false
	ApplyForce.ApplyForce(Part, RenderVoxelData)
	table.insert(self.CachedParts, Part)
end
return module
