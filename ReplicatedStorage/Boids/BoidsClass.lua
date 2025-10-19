-- @ScriptType: ModuleScript
local BoidsClass = {}
BoidsClass.__index = BoidsClass
local BoidTemplate = game.ReplicatedStorage.Part
local BoidRegistration = require(script.AddBoid)
local Janitor = require(script.Janitor)
local RunService = game:GetService("RunService")
function BoidsClass.new(Data)
	local self = setmetatable({}, BoidsClass)
	self.RegisteredBoids = {}
	self.Data = Data
	self.Cleanup = Janitor.new()
	return self
end

function BoidsClass:Start()
	for Index = self.Data.StartBoidsCount, 0, -1 do
		self:AddBoid()
	end
	local RateLimiter = self.Data.RateLimiter or 0.1
	-- rate limit how often boids update for uh preformance or wahtava
	local CurrentTick = tick()
	self.Cleanup:Add(
		RunService.Heartbeat:Connect(function(DT)
			if tick() - CurrentTick < RateLimiter then
				return
			end
			CurrentTick = tick()
			local CollectedBaseParts = {}
			local CollectedCFrames= {}
			for _, BoidClass in self.RegisteredBoids do
				BoidClass:Update(DT)
				if not BoidClass.BoidPart then continue end
				table.insert(CollectedBaseParts, BoidClass.BoidPart)
				table.insert(CollectedCFrames, BoidClass.CFrame)
			end
			-- apperantly bulkmoveto is a thing. thanks random dude on rsc :d
			workspace:BulkMoveTo(CollectedBaseParts, CollectedCFrames, Enum.BulkMoveMode.FireCFrameChanged)
		end),
		"Disconnect"
	)
	
end

function BoidsClass:Destroy()
	self.Cleanup:Destroy()
end

function BoidsClass:AddBoid()
	local BT = BoidTemplate:Clone()
	if self.Data.Debugging then
		BT.Color = self.Data.Color
	end
	BT.Parent = workspace.Boids
	local size = self.Data.BorderPart.Size
	local cf =  self.Data.BorderPart.CFrame

	local randomOffset = Vector3.new(
		(math.random() - 0.5) * size.X,
		(math.random() - 0.5) * size.Y,
		(math.random() - 0.5) * size.Z
	)
	self.Cleanup:Add(BT)
	BT.Position = cf.Position + cf:VectorToWorldSpace(randomOffset)
	local RegisteredBoid = BoidRegistration.RegisterBoid(BT, self)
	table.insert(self.RegisteredBoids, RegisteredBoid)
end
return BoidsClass
