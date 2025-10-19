-- @ScriptType: ModuleScript
-- Visualized version of your raycast avoidance function
local function visualizeRay(origin: Vector3, direction: Vector3, color: Color3, distance: number)
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = origin
	attachment.Parent = workspace.Terrain

	local beam = Instance.new("Beam")
	beam.Color = ColorSequence.new(color)
	beam.FaceCamera = true
	beam.Width0 = 0.05
	beam.Width1 = 0.05
	beam.Attachment0 = attachment

	local attachmentEnd = Instance.new("Attachment")
	attachmentEnd.WorldPosition = origin + direction * distance
	attachmentEnd.Parent = workspace.Terrain
	beam.Attachment1 = attachmentEnd
	beam.Parent = workspace.Terrain

	game:GetService("Debris"):AddItem(attachment, 0.001)
	game:GetService("Debris"):AddItem(attachmentEnd, 0.001)
	game:GetService("Debris"):AddItem(beam, 0.001)
end


return function(Boid)
	local velocity = Boid.Velocity
	local origin = Boid.Position
	local maxDistance = Boid.Settings.MaxDistance or 15

	local direction = velocity.Magnitude > 0 and velocity.Unit or Vector3.new(0, 0, -1)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude	
	rayParams.FilterDescendantsInstances = Boid.Settings.Exclude or {}

	-- Forward ray
	local result = workspace:Raycast(origin, direction * maxDistance, rayParams)
	--visualizeRay(origin, direction, result and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0), maxDistance)

	if not result then
		return Vector3.zero
	end

	local angleStep = 15
	for pitch = -45, 45, angleStep do
		for yaw = 0, 360, angleStep do
			local rot = CFrame.Angles(math.rad(pitch), math.rad(yaw), 0)
			local testDir = (CFrame.lookAt(Vector3.zero, direction) * rot).LookVector
			local testResult = workspace:Raycast(origin, testDir * maxDistance, rayParams)

			--visualizeRay(origin, testDir, testResult and Color3.fromRGB(255, 80, 0) or Color3.fromRGB(0, 180, 255), maxDistance)

			if not testResult then
				return testDir
			end
		end
	end

	-- Everything blocked
	return -direction
end
