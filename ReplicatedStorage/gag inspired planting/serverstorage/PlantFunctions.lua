local module = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Spring = require(ReplicatedStorage.Client.Modules.Utils.Spring)

local AxisVector = {
	X = Vector3.xAxis,
	Y = Vector3.yAxis,
	Z = Vector3.zAxis,
}
local FaceAxisSign = {
	Top = { axis = "Y", sign = 1 },
	Bottom = { axis = "Y", sign = -1 },
	Right = { axis = "X", sign = 1 },
	Left = { axis = "X", sign = -1 },
	Front = { axis = "Z", sign = -1 },
	Back = { axis = "Z", sign = 1 },
}

local function GetFaceLocalOffset(size, face)
	local data = FaceAxisSign[face]
	if not data then
		error("invlid Face")
	end
	return AxisVector[data.axis] * (data.sign * size[data.axis] / 2)
end

function module.ChangeSize(Part, Axis, NewSize, options)
	local function ApplySize(value)
		local oldSize = Part.Size
		local difference = value - oldSize[Axis]
		local offset = Vector3.zero
		if Axis == "X" then
			offset = Part.CFrame.RightVector * (difference / 2)
		elseif Axis == "Y" then
			offset = Part.CFrame.UpVector * (difference / 2)
		elseif Axis == "Z" then
			offset = Part.CFrame.LookVector * (difference / 2)
		else
			error("invalid axis")
		end
		Part.Size = Vector3.new(
			Axis == "X" and value or oldSize.X,
			Axis == "Y" and value or oldSize.Y,
			Axis == "Z" and value or oldSize.Z
		)
		Part.CFrame += offset
	end

	options = options or {}
	local useSpring = options.useSpring
	if useSpring == nil then
		useSpring = false
	end

	if not useSpring then
		ApplySize(NewSize)
		return
	end

	local damping = options.damping or module.growDamping
	local duration = options.duration or module.growDuration
	local speed = options.speed or module.EstimateSpringSpeed(duration, damping)
	local minAlpha = options.minAlpha or module.minAlpha

	local startValue = Part.Size[Axis]
	if options.growFromZero then
		startValue = NewSize * minAlpha
		ApplySize(startValue)
	end

	module._RunAnimatedGrowth(function(alpha)
		ApplySize(startValue + (NewSize - startValue) * alpha)
	end, 0, 1, damping, speed, duration)
end
function module.GetPartsFacePositionCenter(part, Face)
	local cf = part.CFrame
	local offset = GetFaceLocalOffset(part.Size, Face)
	return (cf * CFrame.new(offset)).Position
end
function module.randomFloat(min,max)
	return min + math.random() * (max - min)
end
local FaceAxes = {
	Right = {
		normal = Vector3.xAxis,
		x = Vector3.zAxis,
		y = Vector3.yAxis,
	},
	Left = {
		normal = -Vector3.xAxis,
		x = -Vector3.zAxis,
		y = Vector3.yAxis,
	},
	Top = {
		normal = Vector3.yAxis,
		x = Vector3.xAxis,
		y = Vector3.zAxis,
	},
	Bottom = {
		normal = -Vector3.yAxis,
		x = Vector3.xAxis,
		y = -Vector3.zAxis,
	},
	Front = {
		normal = -Vector3.zAxis,
		x = Vector3.xAxis,
		y = Vector3.yAxis,
	},
	Back = {
		normal = Vector3.zAxis,
		x = -Vector3.xAxis,
		y = Vector3.yAxis,
	},
}
function module.GetPointsAlongFace(part, face, axis, count, spacing)
	local data = FaceAxes[face]
	assert(data, "Invalid face")
	assert(count >= 2, "Count must be at least 2")
	local points = {}
	local halfSize = part.Size / 2
	local center = part.Position + part.CFrame:VectorToWorldSpace(Vector3.new(
		data.normal.X * halfSize.X,
		data.normal.Y * halfSize.Y,
		data.normal.Z * halfSize.Z
		))
	local axisVector
	local length
	if axis == "X" then
		axisVector = data.x
		length = math.abs(part.Size:Dot(data.x))
	elseif axis == "Y" then
		axisVector = data.y
		length = math.abs(part.Size:Dot(data.y))
	else
		error("invalid axis")
	end
	local spacing = length / (count - 1)
	local start = -length / 2
	for i = 0, count - 1 do
		local offset = start + i * spacing
		local worldOffset = part.CFrame:VectorToWorldSpace(axisVector * offset)
		points[i + 1] = center + worldOffset
	end
	return points
end
function module.PlaceFaceAtCFrame(part, face, targetCFrame)
	local localOffset = GetFaceLocalOffset(part.Size, face)
	local worldOffset = targetCFrame:VectorToWorldSpace(localOffset)
	part:PivotTo(CFrame.new(targetCFrame.Position - worldOffset) * targetCFrame.Rotation)
end

module.growDuration = 1.5
module.growDamping = 1
module.minAlpha = 0.04
module.settleAlpha = 0.995

local function AlphaAtTime(t, damping)
	local dampingSquared = damping * damping
	local angFreq, sinTheta, cosTheta
	if dampingSquared < 1 then
		angFreq = math.sqrt(1 - dampingSquared)
		local exponential = math.exp(-damping * t) / angFreq
		cosTheta = exponential * math.cos(angFreq * t)
		sinTheta = exponential * math.sin(angFreq * t)
	elseif dampingSquared == 1 then
		angFreq = 1
		local exponential = math.exp(-damping * t)
		cosTheta, sinTheta = exponential, exponential * t
	else
		angFreq = math.sqrt(dampingSquared - 1)
		local angFreq2 = 2 * angFreq
		local u = math.exp((-damping + angFreq) * t) / angFreq2
		local v = math.exp((-damping - angFreq) * t) / angFreq2
		cosTheta, sinTheta = u + v, u - v
	end
	return 1 - (angFreq * cosTheta + damping * sinTheta)
end

function module.EstimateSpringSpeed(duration, damping)
	local lo, hi = 0, 50
	for _ = 1, 40 do
		local mid = (lo + hi) / 2
		if AlphaAtTime(mid, damping) < module.settleAlpha then
			lo = mid
		else
			hi = mid
		end
	end
	return hi / duration
end

module._activeJobs = {}
function module._RunAnimatedGrowth(apply, startAlpha, targetAlpha, damping, speed, duration)
	local alphaSpring = Spring.new(startAlpha, damping, speed)
	alphaSpring.Target = targetAlpha

	apply(startAlpha)

	table.insert(module._activeJobs, {
		apply = apply,
		spring = alphaSpring,
		minAlpha = math.min(startAlpha, targetAlpha),
		maxAlpha = math.max(startAlpha, targetAlpha),
		targetAlpha = targetAlpha,
		startTime = os.clock(),
		duration = duration,
		thread = coroutine.running(),
	})

	coroutine.yield()
end

function module.Update()
	local jobs = module._activeJobs
	local i = 1
	while i <= #jobs do
		local job = jobs[i]
		if os.clock() - job.startTime >= job.duration then
			job.apply(job.targetAlpha)
			table.remove(jobs, i)
			coroutine.resume(job.thread)
			-- list shifted
		else
			local alpha = math.clamp(job.spring.Position, job.minAlpha, job.maxAlpha)
			job.apply(alpha)
			i += 1
		end
	end
end

--[[
was forced to document this cus i kept getting lost. aint i js the best scripter
	options:
		useSpring   (bool)   -- true (default) animates smoothly with a Spring;
		                        false applies the final size/position instantly.
		growWidth   (bool)   -- false (default) sets Y/Z (width) instantly and
		                        only animates X (length) true animates all
		                        three axes together.
		duration    (number) -- how many real seconds the grow animation should take 
		damping     (number) -- Spring damping
		speed       (number) -- Spring speed. 
		minAlpha    (number) -- starting size fraction
\
]]
function module.GrowPart(part, anchorFace, targetCFrame, finalSize, options)
	options = options or {}
	local useSpring = options.useSpring
	if useSpring == nil then
		useSpring = true
	end
	local growWidth = options.growWidth
	local damping = options.damping or module.growDamping
	local duration = options.duration or module.growDuration
	local speed = options.speed or module.EstimateSpringSpeed(duration, damping)
	local minAlpha = options.minAlpha or module.minAlpha

	local function apply(alpha)
		if growWidth then
			part.Size = finalSize * alpha
		else
			part.Size = Vector3.new(finalSize.X * alpha, finalSize.Y, finalSize.Z)
		end
		if anchorFace then
			module.PlaceFaceAtCFrame(part, anchorFace, targetCFrame)
		else
			part:PivotTo(targetCFrame)
		end
	end

	if not useSpring then
		apply(1)
		return
	end

	module._RunAnimatedGrowth(apply, minAlpha, 1, damping, speed, duration)
end

function module.GetRandomPoints(part, count, minDistance, maxDistance)
	local points = {}
	local size = part.Size
	local cf = part.CFrame

	local maxAttempts = 1000
	local attempts = 0

	while #points < count and attempts < maxAttempts do
		attempts += 1

		local localPos = Vector3.new(
			(math.random() - 0.5) * size.X,
			0,
			(math.random() - 0.5) * size.Z
		)

		local worldPos = cf:PointToWorldSpace(localPos)

		local valid = true

		for _, point in points do
			local dist = (worldPos - point).Magnitude

			if dist < minDistance then
				valid = false
				break
			end
		end

		if valid and #points > 0 then
			local closeEnough = false

			for _, point in points do
				if (worldPos - point).Magnitude <= maxDistance then
					closeEnough = true
					break
				end
			end

			valid = closeEnough
		end

		if valid then
			table.insert(points, worldPos)
		end
	end

	return points
end
return module
