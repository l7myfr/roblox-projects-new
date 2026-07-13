local wheat = {}
wheat.__index = wheat

local ServerStorage = game:GetService("ServerStorage")

local PlantFunctions = require(ServerStorage.Server.Modules.PlantFunctions)

local Assets = script

local useSpring = true
local growDuration = 60   
local growDamping = 1
local pointStagger = 0.05
function wheat.init(position, seed)
	-- probably not te best way of doing shit but who gon stop me right
	growDuration = math.random(5, 15)
	local self = setmetatable({}, wheat)
	self.Parts = {}
	self.Position = position
	self.Seed = seed or Random.new():NextInteger(1, 2 ^ 31 - 1)
	return self
end

function wheat:Destroy()
	for _, part in self.Parts do
		if part and part.Parent then
			part:Destroy()
		end
	end
	table.clear(self.Parts)
end

function wheat:Start()
	task.spawn(function()
		self:_Grow()
	end)
end

function wheat:_Grow()
	math.randomseed(self.Seed)

	-- stem
	local Stem = Assets.Stem:Clone()
	Stem.Parent = workspace
	table.insert(self.Parts, Stem)

	local startcframe = CFrame.new(self.Position) * Stem.CFrame.Rotation

	local stemLength = PlantFunctions.randomFloat(1.2, 1.5)
	local width = PlantFunctions.randomFloat(0.1, 0.2)
	local stemFinalSize = Vector3.new(stemLength, width, width)
	PlantFunctions.GrowPart(Stem, "Left", startcframe, stemFinalSize, {
		useSpring = useSpring,
		duration = growDuration,
		damping = growDamping,
		growWidth = false,
	})

	local upPosition = PlantFunctions.GetPartsFacePositionCenter(Stem, "Right")

	-- afterstem
	local afterStem = Assets.AfterStem:Clone()
	afterStem.Parent = workspace
	table.insert(self.Parts, afterStem)

	local afterStemLength = PlantFunctions.randomFloat(0.7, 1.1)
	local afterStemFinalSize = Vector3.new(afterStemLength, width - 0.05, width - 0.05)

	local x = math.rad(math.random(-15, 15))
	local y = math.rad(math.random(-15, 15))
	local z = math.rad(math.random(-15, 15))
	local afterstemRotation = CFrame.Angles(x, y, z)

	local afterStemTarget = CFrame.new(upPosition) * startcframe.Rotation * afterstemRotation
	PlantFunctions.GrowPart(afterStem, "Left", afterStemTarget, afterStemFinalSize, {
		useSpring = useSpring,
		duration = growDuration,
		damping = growDamping,
		growWidth = false,
	})

	local upPosition2 = PlantFunctions.GetPartsFacePositionCenter(afterStem, "Right")

	-- start wheat
	local startwheat = Assets.StartWheat:Clone()
	startwheat.Parent = workspace
	table.insert(self.Parts, startwheat)

	local startWheatLength = PlantFunctions.randomFloat(3.7, 4.5)
	local startWheatFinalSize = Vector3.new(startWheatLength, width + 0.03, width + 0.03)

	local continuationAmount = 0.5
	local wheatLean = CFrame.Angles(
		x * continuationAmount,
		y * continuationAmount,
		z * continuationAmount
	)

	local startWheatTarget = CFrame.new(upPosition2) * startcframe.Rotation * afterstemRotation * wheatLean
	PlantFunctions.GrowPart(startwheat, "Left", startWheatTarget, startWheatFinalSize, {
		useSpring = useSpring,
		duration = growDuration,
		damping = growDamping,
		growWidth = false,
	})

	-- wheat points
	local points = PlantFunctions.GetPointsAlongFace(startwheat, "Back", "X", 6, 0.5)
	local points2 = PlantFunctions.GetPointsAlongFace(startwheat, "Front", "X", 6, 0.5)
	local faceRotation = startwheat.CFrame.Rotation

	local function GrowWheatPoint(point, face, ySign, zSign)
		local px = math.rad(math.random(-30, 30))
		local py = math.rad(math.random(16, 25)) * ySign
		local pz = math.rad(math.random(80, 130)) * zSign
		local orientation = CFrame.Angles(px, py, 0)

		local wheatPoint = Assets.WheatPoints:Clone()
		wheatPoint.Parent = workspace
		table.insert(self.Parts, wheatPoint)
		local wpFinalSize = wheatPoint.Size

		local wpTarget = CFrame.new(point) * faceRotation * orientation
		PlantFunctions.GrowPart(wheatPoint, face, wpTarget, wpFinalSize, {
			useSpring = useSpring,
			duration = growDuration / growDuration - 0.5,
			damping = growDamping,
			growWidth = true,
		})

		--local tipFace = (face == "Front") and "Back" or "Front"
		--local tipPosition = PlantFunctions.GetPartsFacePositionCenter(wheatPoint, tipFace)

		--local wtp = Assets.WheatTopPart:Clone()
		--wtp.Parent = workspace
		--table.insert(self.Parts, wtp)
		--local wtpFinalSize = wtp.Size

		--local wtpTarget = CFrame.new(tipPosition) * faceRotation * CFrame.Angles(
		--	px * continuationAmount,
		--	py * continuationAmount,
		--	pz * continuationAmount
		--)
		--PlantFunctions.GrowPart(wtp, nil, wtpTarget, wtpFinalSize, {
		--	useSpring = useSpring,
		--	duration = growDuration,
		--	damping = growDamping,
		--	growWidth = true,
		--})
	end

	local pending = 0
	local allDone = Instance.new("BindableEvent")

	for i, point in points do
		if i == 1 or i == #points then continue end
		pending += 1
		task.spawn(function()
			GrowWheatPoint(point, "Front", 1, 1)
			pending -= 1
			if pending == 0 then allDone:Fire() end
		end)
		task.wait(pointStagger)
	end

	for i, point in points2 do
		if i == 1 or i == #points2 then continue end
		pending += 1
		task.spawn(function()
			GrowWheatPoint(point, "Back", -1, -1)
			pending -= 1
			if pending == 0 then allDone:Fire() end
		end)
		task.wait(pointStagger)
	end

	if pending > 0 then
		allDone.Event:Wait()
	end
	allDone:Destroy()
end

return wheat
