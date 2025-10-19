-- @ScriptType: ModuleScript
local BoidClass = {}
BoidClass.__index = BoidClass

-- Math behaviors
local Bounds = require(script.Math.Bounds)
local Seperation = require(script.Math.Seperation)
local Align = require(script.Math.Align)
local Cohesion = require(script.Math.Cohesion)
local ClampVelocity = require(script.Math.ClampVelocity)
local UnobstructedRay = require(script.Math.UnobstructedRay)

function BoidClass.RegisterBoid(BoidPart: BasePart, BoidGroup,Settings)
	local self = setmetatable({}, BoidClass)
	self.BoidPart = BoidPart
	self.BoidGroup = BoidGroup
	self.Velocity = Vector3.zero
	self.CFrame = CFrame.new()
	self.Position = BoidPart.Position
	self.Settings = BoidGroup.Data
	self.VisibleBoids = { Separation = {}, Alignment = {}, Cohesion = {} }

	return self
end

function BoidClass:Update(dt: number)
	local BoidPart = self.BoidPart
	if not BoidPart or not BoidPart:IsA("BasePart") then
		return
	end
	self.VisibleBoids = { Separation = {}, Alignment = {}, Cohesion = {} }
	local BoidPosition = self.Position
	-- js doing it here so we dont have to do them in the math module thingi es
	for _, OtherBoid in self.BoidGroup.RegisteredBoids do
		if OtherBoid == self then continue end
		local OtherBoidPosition = OtherBoid.Position
		local Dist = (BoidPosition- OtherBoidPosition).Magnitude
		if (Dist < self.Settings.SeparationRange) then
			table.insert(self.VisibleBoids.Separation, OtherBoid)
		end
		if (Dist < self.Settings.CohesionRange) then
			table.insert(self.VisibleBoids.Cohesion, OtherBoid)
		end
		if (Dist < self.Settings.AlignmentRange) then
			table.insert(self.VisibleBoids.Alignment, OtherBoid)
		end
	end
	local SeparationVelocity = Seperation(self) -- steer away from nearby boids to avoid crowding
	local AlignmentVelocity = Align(self) -- align direction with nearby boids
	local CohesionVelocity = Cohesion(self) -- steer toward the average position of nearby boids
	local BoundVelocity = Bounds(self) -- keep the boid within the simulation bounds
	local UnobstructedVelocity = UnobstructedRay(self) -- avoid obstacles using raycasting

	-- add them all up yay
	self.Velocity += 
		SeparationVelocity 
		+ AlignmentVelocity 
		+ CohesionVelocity 
		+ BoundVelocity 
		+ UnobstructedVelocity  * 150
	ClampVelocity(self)
	self.Position += self.Velocity * dt
		if self.Velocity.Magnitude > 0 then
		self.CFrame = CFrame.lookAt(self.Position, self.Position + self.Velocity)
	end
end

return BoidClass
