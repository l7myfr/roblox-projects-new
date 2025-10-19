-- @ScriptType: ModuleScript
local module = {}
local Atbs = {
	"CastShadow",
	"CanCollide",
	"Transparency",
	"CanTouch"
}
module.__index = module
function module.New(Object, Server)
	local self = setmetatable({},module)
	self.Object = Object
	self.VoxelHolder = Object.Parent
	self.ServerData = Server
	return self
end
function module:CopyPropeties()
	for i, v in Atbs do
		self.Object[v]  = self.Object:GetAttribute(v)
	end
end
function module:Regenerate()
	self.Object.Parent = self.Object.Parent.Parent
	for _, Part in self.VoxelHolder:GetChildren() do
		if Part:IsA("Part") then
			self.ServerData.PooledClass:Return(Part)
		end
	end
	self.VoxelHolder:Destroy()

	if self.Object:HasTag("RegenPart") then
		self.Object:RemoveTag("RegenPart")
	end
	
	self:CopyPropeties()
end
return module
