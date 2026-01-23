local function getRelative(cf1, cf2)
	return cf2:ToObjectSpace(cf1)
end

local function CalculateLimb(limbCFrame, motor, torso, offset, dummyR15, dummyR6)
	offset = offset or Vector3.new()
	torso = torso or dummyR6.Torso.CFrame

	local r15Rel = dummyR6.HumanoidRootPart.CFrame * getRelative(
		limbCFrame,
		dummyR15.HumanoidRootPart.CFrame
	) + offset

	local cf = (torso * motor.C0):ToObjectSpace(r15Rel)
	return cf * motor.C1, r15Rel
end

local function ConvertR15ToR6(sequence: KeyframeSequence, dummyR15: Model, dummyR6: Model)
	local result = Instance.new("KeyframeSequence")
	result.Name = "R15ToR6_Converted"
	result.Priority = sequence.Priority
	result.Loop = sequence.Loop

	local defaults = {}
	for _, v in pairs(dummyR15:GetDescendants()) do
		if v:IsA("Motor6D") then defaults[v] = v.C0 end
	end

	dummyR15.Parent = workspace
	dummyR6.Parent = workspace

	for _, v in pairs(sequence:GetKeyframes()) do
		local kf = Instance.new("Keyframe")
		kf.Time = v.Time

		for _, pose in pairs(v:GetDescendants()) do
			if pose:IsA("Pose") then
				local part = dummyR15:FindFirstChild(pose.Name, true)
				local motor = part and part:FindFirstChildOfClass("Motor6D")
				if motor and defaults[motor] then
					motor.C0 = defaults[motor] * pose.CFrame
				end
			end
		end

		task.wait() 

		local r6Poses = {
			["Torso"] = Instance.new("Pose"),
			["Head"] = Instance.new("Pose"),
			["Right Arm"] = Instance.new("Pose"),
			["Left Arm"] = Instance.new("Pose"),
			["Right Leg"] = Instance.new("Pose"),
			["Left Leg"] = Instance.new("Pose"),
			["HumanoidRootPart"] = Instance.new("Pose")
		}

		for name, pose in pairs(r6Poses) do 
			pose.Name = name 
		end

		local torsoCF, torsoWorld = CalculateLimb(dummyR15.UpperTorso.CFrame, dummyR6.HumanoidRootPart["Root Hip"], nil, Vector3.new(0, -0.2, 0), dummyR15, dummyR6)
		r6Poses.Torso.CFrame = torsoCF

		r6Poses.Head.CFrame = CalculateLimb(dummyR15.Head.CFrame, dummyR6.Torso.Neck, torsoWorld, nil, dummyR15, dummyR6)
		r6Poses["Right Arm"].CFrame = CalculateLimb(dummyR15.RightLowerArm.CFrame, dummyR6.Torso["Right Shoulder"], torsoWorld, Vector3.new(0, 0.224, 0), dummyR15, dummyR6)
		r6Poses["Left Arm"].CFrame = CalculateLimb(dummyR15.LeftLowerArm.CFrame, dummyR6.Torso["Left Shoulder"], torsoWorld, Vector3.new(0, 0.224, 0), dummyR15, dummyR6)
		r6Poses["Right Leg"].CFrame = CalculateLimb(dummyR15.RightLowerLeg.CFrame, dummyR6.Torso["Right Hip"], torsoWorld, Vector3.new(0, 0.201, 0), dummyR15, dummyR6)
		r6Poses["Left Leg"].CFrame = CalculateLimb(dummyR15.LeftLowerLeg.CFrame, dummyR6.Torso["Left Hip"], torsoWorld, Vector3.new(0, 0.201, 0), dummyR15, dummyR6)

		r6Poses.HumanoidRootPart:AddSubPose(r6Poses.Torso)
		r6Poses.Torso:AddSubPose(r6Poses.Head)
		r6Poses.Torso:AddSubPose(r6Poses["Right Arm"])
		r6Poses.Torso:AddSubPose(r6Poses["Left Arm"])
		r6Poses.Torso:AddSubPose(r6Poses["Right Leg"])
		r6Poses.Torso:AddSubPose(r6Poses["Left Leg"])

		kf:AddPose(r6Poses.HumanoidRootPart)
		result:AddKeyframe(kf)
	end

	return result
end
