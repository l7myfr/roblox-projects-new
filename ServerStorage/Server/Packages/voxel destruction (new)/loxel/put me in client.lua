-- @ScriptType: LocalScript
-- unfinished local script
local ActiveVoxels = {}
local IndexToMaterial = Enum.Material:GetEnumItems()
local VoxelSyncEvent = game.ReplicatedStorage:WaitForChild("VoxelSyncEvent")
local function readBirthVoxelBuffer(Buffer)
	local BYTES_PER_VOXEL = 39  
	local results = {}

	local totalBytes = buffer.len(Buffer)
	local count = totalBytes / BYTES_PER_VOXEL

	for index = 0, count - 1 do
		local offset = index * BYTES_PER_VOXEL

		-- ID
		local id = buffer.readu32(Buffer, offset)

		-- Position
		local posX = buffer.readf32(Buffer, offset + 4)
		local posY = buffer.readf32(Buffer, offset + 8)
		local posZ = buffer.readf32(Buffer, offset + 12)

		-- Rotation
		local rotX = buffer.readi16(Buffer, offset + 16) / 100
		local rotY = buffer.readi16(Buffer, offset + 18) / 100
		local rotZ = buffer.readi16(Buffer, offset + 20) / 100

		-- Size (now f32)
		local sizeX = buffer.readf32(Buffer, offset + 22)
		local sizeY = buffer.readf32(Buffer, offset + 26)
		local sizeZ = buffer.readf32(Buffer, offset + 30)

		-- Color
		local r = buffer.readu8(Buffer, offset + 34) / 255
		local g = buffer.readu8(Buffer, offset + 35) / 255
		local b = buffer.readu8(Buffer, offset + 36) / 255

		-- Material
		local materialIndex = buffer.readu8(Buffer, offset + 37)
		local material = IndexToMaterial[materialIndex]

		-- Transparency
		local TransparencyRaw = buffer.readu8(Buffer, offset + 38)
		local Transparency = TransparencyRaw / 255
		-- Construct voxel table
		results[id] = {
			Position = Vector3.new(posX, posY, posZ),
			Rotation = Vector3.new(rotX, rotY, rotZ),
			Size = Vector3.new(sizeX, sizeY, sizeZ),
			Color = Color3.new(r, g, b),
			Material = material,
			Transparency = Transparency,
		}
	end

	return results
end
local function readUpdatePhysicsVoxelBuffer(Buffer)
	local BYTES_PER_VOXEL = 22  
	local results = {}

	local totalBytes = buffer.len(Buffer)
	local count = totalBytes / BYTES_PER_VOXEL

	for index = 0, count - 1 do
		local offset = index * BYTES_PER_VOXEL

		-- ID
		local id = buffer.readu32(Buffer, offset)

		-- Position
		local posX = buffer.readf32(Buffer, offset + 4)
		local posY = buffer.readf32(Buffer, offset + 8)
		local posZ = buffer.readf32(Buffer, offset + 12)

		-- Rotation
		local rotX = buffer.readi16(Buffer, offset + 16) / 100
		local rotY = buffer.readi16(Buffer, offset + 18) / 100
		local rotZ = buffer.readi16(Buffer, offset + 20) / 100

		-- Construct voxel table
		results[id] = {
			Position = Vector3.new(posX, posY, posZ),
			Rotation = Vector3.new(rotX, rotY, rotZ),
		}
	end

	return results
end
local InterpolationEnabled = true
local TweenService = game:GetService("TweenService")
local PhysicsTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In)


VoxelSyncEvent.OnClientEvent:Connect(function(mode, b)
	if mode == "Birth" then
		local Results = readBirthVoxelBuffer(b)
		for id, data in Results do
			local part = Instance.new("Part", workspace)
			part.Size = data.Size
			part.Position = data.Position
			part.Rotation = data.Rotation
			part.Color = data.Color
			part.Material = data.Material
			part.Anchored = true
			part.CanCollide = true
			part.Transparency = data.Transparency
			part.BottomSurface = Enum.SurfaceType.Smooth
			part.TopSurface = Enum.SurfaceType.Smooth
			ActiveVoxels[id] = {}
			ActiveVoxels[id][1] = part
		end
	elseif mode == "PhysicsUpdate" then
		local Results = readUpdatePhysicsVoxelBuffer(b)
		for id, data in Results do
			local debrisData = ActiveVoxels[id]
			if not debrisData then return end
			local Voxel = debrisData[1]
			if not ActiveVoxels[id] then continue end
			local targetCFrame = CFrame.new(data.Position) 
				* CFrame.Angles(
					math.rad(data.Rotation.X),
					math.rad(data.Rotation.Y),
					math.rad(data.Rotation.Z)
				)
			local finalCFrame = (InterpolationEnabled == false) and 
				targetCFrame or Voxel.CFrame:Lerp(targetCFrame, 1)

			local moveTween = TweenService:Create(Voxel, PhysicsTweenInfo, {
				CFrame = finalCFrame
			})
			moveTween:Play()
			if debrisData[2] then
				debrisData[2]:Destroy()
			end
			debrisData[2] = moveTween
		end
	end
end)
