-- @ScriptType: ModuleScript
local Divider = {}
local Workspace = game:GetService("Workspace")
local RegenTask = require(script.Parent.Regeneration.NewTask)
local IGNORED_ALIVE = Workspace.Ignored
local ATTRIBUTES_TO_SET = { "CastShadow", "CanCollide", "Transparency", "CanQuery", "CanTouch" }

--// Copies over all relevant properties from one part to another.
local function TransferAttributes(destination, source)
	destination.Color = source.Color
	destination.Material = source.Material
	destination.Transparency = source.Transparency
	destination.Parent = source.Parent
	destination.Anchored = true
	destination.TopSurface = source.TopSurface
	destination.BottomSurface = source.BottomSurface
	destination.LeftSurface = source.LeftSurface
	destination.RightSurface = source.RightSurface
	destination.FrontSurface = source.FrontSurface
	destination.BackSurface = source.BackSurface
end

--// Creates a "VoxelHolder" parent for regeneration.
local function CreateAParent(object, Data,Server)
	if object.Parent and object.Parent.Name == "VoxelHolder" then
		Data.VoxelHolder = object.Parent
		if Data.Regenerate == true then
			RegenTask.New(Data, Server)
		end
		return 
	end
	if not object then return end
	local voxelHolder = Instance.new("Model")
	voxelHolder.Name = "VoxelHolder"
	voxelHolder.Parent = object.Parent
	object.Parent = voxelHolder

	local regenPart = object:Clone()
	if not regenPart then return end
	regenPart.Name = "RegenPart"
	regenPart.Transparency = 1
	regenPart.Anchored = true
	regenPart.CanQuery = false
	regenPart.CanCollide = false
	regenPart.Parent = voxelHolder
	regenPart:AddTag("RegenPart")

	for _, attributeName in ATTRIBUTES_TO_SET do
		regenPart:SetAttribute(attributeName, object[attributeName])
	end

	voxelHolder:AddTag("VoxelHolder")
	voxelHolder.PrimaryPart = regenPart
	Data.VoxelHolder = voxelHolder
	if Data.Regenerate == true then
		RegenTask.New(Data, Server)
	end
end

--// Main function to divide a part.
function Divider.DividePart(object, self, Settings)
	if not (object and object.Parent and object:IsA("Part") and object.Shape == Enum.PartType.Block and not object:IsDescendantOf(IGNORED_ALIVE)) then
		return false
	end

	CreateAParent(object, Settings, self)

	local size = object.Size
	local goalSize = Settings.VoxelSize or 5

	if size.X <= goalSize and size.Y <= goalSize and size.Z <= goalSize then
		return false
	end

	local dominantAxis
	if size.X > size.Y and size.X > size.Z then
		dominantAxis = "X"
	elseif size.Y > size.Z then
		dominantAxis = "Y"
	else
		dominantAxis = "Z"
	end

	local partOne =  self.PooledClass:Get()
	if not partOne then  -- sometimes it might not return a part if its destroyed. instead it will return nil causing a parent null error
		return {}
	end 
	TransferAttributes(partOne, object)
	local partTwo = self.PooledClass:Get()
	if not partTwo then
		return {}
	end
	TransferAttributes(partTwo, object)

	local originalCFrame = object.CFrame
	local newSize, offset
	if dominantAxis == "X" then
		newSize = Vector3.new(size.X / 2, size.Y, size.Z)
		offset = Vector3.new(size.X / 4, 0, 0)
	elseif dominantAxis == "Y" then
		newSize = Vector3.new(size.X, size.Y / 2, size.Z)
		offset = Vector3.new(0, size.Y / 4, 0)
	else 
		newSize = Vector3.new(size.X, size.Y, size.Z / 2)
		offset = Vector3.new(0, 0, size.Z / 4)
	end

	partOne.Size = newSize
	partTwo.Size = newSize
	partOne.CFrame = originalCFrame * CFrame.new(-offset)
	partTwo.CFrame = originalCFrame * CFrame.new(offset)

	if Settings.Debug then
		partOne.Color = Color3.fromHSV(math.random(), 1, 1)
		partTwo.Color = Color3.fromHSV(math.random(), 1, 1)
	end

	object:Destroy()

	return {partOne, partTwo}
end

return Divider