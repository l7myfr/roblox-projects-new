-- @ScriptType: ModuleScript
local module = {}
local MaterialToIndex = Enum.Material:GetEnumItems()
for index, material in ipairs(MaterialToIndex) do
	MaterialToIndex[material] = index
end

function module.createBirthVoxelBuffer(Results)
	local count = 0
	for _ in Results do
		count += 1
	end

	-- u32 ID: 4 bytes
	-- f32 Position (3): 12 bytes
	-- i16 Rotation (3): 6 bytes
	-- f32 Size (3): 12 bytes
	-- u8 Color (3): 3 bytes
	-- u8 Material: 1 byte
	-- u8 Transparency: 1 byte
	local BYTES_PER_VOXEL = 39
	local Buffer = buffer.create(count * BYTES_PER_VOXEL)

	local index = 0
	for id, part in Results do
		local offset = index * BYTES_PER_VOXEL

		-- ID
		buffer.writeu32(Buffer, offset, tonumber(id) or 0)

		-- Position
		local PartPos = part.Position
		buffer.writef32(Buffer, offset + 4, PartPos.X)
		buffer.writef32(Buffer, offset + 8, PartPos.Y)
		buffer.writef32(Buffer, offset + 12, PartPos.Z)

		-- Rotation
		local PartRot = part.Rotation
		buffer.writei16(Buffer, offset + 16, PartRot.X * 100)
		buffer.writei16(Buffer, offset + 18, PartRot.Y * 100)
		buffer.writei16(Buffer, offset + 20, PartRot.Z * 100)

		-- Size (now f32)
		local PartSize = part.Size
		buffer.writef32(Buffer, offset + 22, PartSize.X)
		buffer.writef32(Buffer, offset + 26, PartSize.Y)
		buffer.writef32(Buffer, offset + 30, PartSize.Z)

		-- Color
		local c = part.Color
		buffer.writeu8(Buffer, offset + 34, math.clamp(c.R * 255, 0, 255))
		buffer.writeu8(Buffer, offset + 35, math.clamp(c.G * 255, 0, 255))
		buffer.writeu8(Buffer, offset + 36, math.clamp(c.B * 255, 0, 255))

		-- Material
		buffer.writeu8(Buffer, offset + 37, MaterialToIndex[part.Material])

		-- Transparency
		local trans = part.Transparency or 0
		buffer.writeu8(Buffer, offset + 38, math.clamp(trans * 255, 0, 255))
		part.Transparency = 1
		index += 1
	end

	return Buffer
end
function module.createPhysicsVoxelBuffer(results)
	local count = 0
	for _ in results do
		count += 1
	end

	-- u32 ID: 4 bytes
	-- f32 Position (3): 12 bytes
	-- i16 Rotation (3): 6 bytes
	local BYTES_PER_VOXEL = 22
	local Buffer = buffer.create(count * BYTES_PER_VOXEL)

	local index = 0
	for id, part in results do
		local offset = index * BYTES_PER_VOXEL

		-- ID
		buffer.writeu32(Buffer, offset, tonumber(id or 2) or 0)

		-- Position
		local PartPos = part.Position
		buffer.writef32(Buffer, offset + 4, PartPos.X)
		buffer.writef32(Buffer, offset + 8, PartPos.Y)
		buffer.writef32(Buffer, offset + 12, PartPos.Z)

		-- Rotation
		local PartRot = part.Rotation
		buffer.writei16(Buffer, offset + 16, PartRot.X * 100)
		buffer.writei16(Buffer, offset + 18, PartRot.Y * 100)
		buffer.writei16(Buffer, offset + 20, PartRot.Z * 100)
		
		index += 1
	end

	return Buffer
end
return module
