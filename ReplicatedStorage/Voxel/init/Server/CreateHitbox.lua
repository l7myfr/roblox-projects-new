-- @ScriptType: ModuleScript
local Hitbox = {}
Hitbox.__index = Hitbox

function Hitbox.RegisterHitbox(Data)
	local self = setmetatable({}, Hitbox)
	local Position = Data.Position or Vector3.zero	
	local Size = Data.HitboxSize or Vector3.zero
	local Hitbox = Instance.new("Part")
	Hitbox.Parent = workspace.Ignored
	Hitbox.Position = Position
	Hitbox.Size = Size
	Hitbox.Transparency = Data.Debug == true and 0.5 or 1
	Hitbox.Anchored = true
	Hitbox.CanQuery = false
	Hitbox.CanCollide = false
	Hitbox.CanTouch = false
	Hitbox.Material = Enum.Material.Neon
	Hitbox.Color = Color3.new(1, 0, 0)
	local Settings = {}
	Settings.OverlapParams = OverlapParams.new()
	Settings.OverlapParams.FilterType = Enum.RaycastFilterType.Exclude
	Settings.OverlapParams.FilterDescendantsInstances = {workspace.Ignored}
	if Data.OverlapParams ~= nil then
		Settings.OverlapParams = Data.OverlapParams
	end
	self.Hitbox = Hitbox
	self.Settings = Settings
	return self
end
function Hitbox:GetPartsInParts()
	if not self.Hitbox then 
		self:Destroy()
		return {}
	end
	local Parts = workspace:GetPartsInPart(self.Hitbox, self.Settings.OverlapParams)
	return Parts
end

function Hitbox:Destroy()
	if not self.Hitbox then return end
	self.Hitbox:Destroy()
end

return Hitbox