-- @ScriptType: ModuleScript


return function(boid)
	local Part = boid.Settings.BorderPart
	local REGION_SIZE = Part.Size
	local CENTER = Part.Position
	local RETURN_FORCE = 30
	local pos = boid.Position
	local steer = Vector3.zero

	local minBound = CENTER - REGION_SIZE / 2
	local maxBound = CENTER + REGION_SIZE / 2

	if pos.X < minBound.X then
		steer += Vector3.new(RETURN_FORCE, 0, 0)
	elseif pos.X > maxBound.X then
		steer += Vector3.new(-RETURN_FORCE, 0, 0)
	end

	if pos.Y < minBound.Y then
		steer += Vector3.new(0, RETURN_FORCE, 0)
	elseif pos.Y > maxBound.Y then
		steer += Vector3.new(0, -RETURN_FORCE, 0)
	end

	if pos.Z < minBound.Z then
		steer += Vector3.new(0, 0, RETURN_FORCE)
	elseif pos.Z > maxBound.Z then
		steer += Vector3.new(0, 0, -RETURN_FORCE)
	end

	return steer
end
