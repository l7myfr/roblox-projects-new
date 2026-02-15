local module = {}

local RESULT_BUFFER = {} 

function module.ComputeVoxels(object, Settings, HitboxCF, HitboxSize)
	local goalSize = Settings.VoxelSize or 4
	local results = {} 

	local hbInverse = HitboxCF:Inverse()
	local hbHalf = HitboxSize * 0.5


	local stack = {object.CFrame, object.Size, false} 
	local stackPtr = 3

	while stackPtr > 0 do
		local isFullyInside = stack[stackPtr]
		local size = stack[stackPtr - 1]
		local cf = stack[stackPtr - 2]
		stackPtr -= 3

		local isHit = true
		local fullyContained = isFullyInside

		if not isFullyInside then
			local relCF = hbInverse * cf
			local absPos = Vector3.new(math.abs(relCF.X), math.abs(relCF.Y), math.abs(relCF.Z))

			local _, _, _, R00, R01, R02, R10, R11, R12, R20, R21, R22 = relCF:GetComponents()

			local hSize = size * 0.5
			local projX = math.abs(R00) * hSize.X + math.abs(R01) * hSize.Y + math.abs(R02) * hSize.Z
			local projY = math.abs(R10) * hSize.X + math.abs(R11) * hSize.Y + math.abs(R12) * hSize.Z
			local projZ = math.abs(R20) * hSize.X + math.abs(R21) * hSize.Y + math.abs(R22) * hSize.Z

			if absPos.X > (hbHalf.X + projX) or absPos.Y > (hbHalf.Y + projY) or absPos.Z > (hbHalf.Z + projZ) then
				isHit = false
			else
				fullyContained = (absPos.X + projX <= hbHalf.X) and (absPos.Y + projY <= hbHalf.Y) and (absPos.Z + projZ <= hbHalf.Z)
			end
		end

		if not isHit then
			table.insert(results, {cf = cf, size = size, isVoxel = false})
			continue
		end

		if size.X <= goalSize and size.Y <= goalSize and size.Z <= goalSize then
			table.insert(results, {cf = cf, size = size, isVoxel = true})
			continue
		end

		local dx, dy, dz = size.X, size.Y, size.Z
		local newSize, offset
		if dx >= dy and dx >= dz then
			newSize = Vector3.new(dx * 0.5, dy, dz)
			offset = cf.RightVector * (dx * 0.25)
		elseif dy >= dz then
			newSize = Vector3.new(dx, dy * 0.5, dz)
			offset = cf.UpVector * (dy * 0.25)
		else
			newSize = Vector3.new(dx, dy, dz * 0.5)
			offset = cf.LookVector * (dz * 0.25)
		end

		stack[stackPtr + 1] = cf + offset
		stack[stackPtr + 2] = newSize
		stack[stackPtr + 3] = fullyContained

		stack[stackPtr + 4] = cf - offset
		stack[stackPtr + 5] = newSize
		stack[stackPtr + 6] = fullyContained
		stackPtr += 6
	end
	return results
end

return module