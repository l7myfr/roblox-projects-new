-- @ScriptType: ModuleScript
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local module = {}
module.__index = module

local PartPooler = require(script.PartPooler)
local Divider = require(script.Divider)
local configModule = require(script.Config)
local BufferModule = require(script.Buffer)
local WakeModule = require(script.Wake)
local VoxelSyncEvent = Instance.new("RemoteEvent", ReplicatedStorage)
VoxelSyncEvent.Name = "VoxelSyncEvent"

local nextVoxelId = 0

local SLEEP_THRESHOLD = 0.1
local CHECK_INTERVAL = 0.1 
local UPDATE_PHYSICS_INTERVAL = 0.1

function module.init()
	local self = setmetatable({}, module)
	self.settledVoxels = {}

	local Template = Instance.new('Part')
	Template.Anchored = true
	Template.CanCollide = false
	Template.BottomSurface = Enum.SurfaceType.Smooth
	Template.TopSurface = Enum.SurfaceType.Smooth
	PartPooler.createPool("DestructionVoxels", Template, 15000)

	task.spawn(function()
		while task.wait(CHECK_INTERVAL) do
			self:monitorVoxels()
		end
	end)

	task.spawn(function()
		while task.wait(UPDATE_PHYSICS_INTERVAL) do
			local movableBuffer = {}
			local anyMoving = false

			for _, part in CollectionService:GetTagged("DestructedVoxel") do
				local id = part:GetAttribute("ID")
				if not id then continue end

				if not part.Anchored or self.settledVoxels[id] then
					movableBuffer[id] = part
					anyMoving = true
				end
			end

			if anyMoving then
				local Count = 0
				for _ in movableBuffer do
					Count+=1
				end
				local encodedBuffer = BufferModule.createPhysicsVoxelBuffer(movableBuffer)
				VoxelSyncEvent:FireAllClients("PhysicsUpdate", encodedBuffer)
				
				table.clear(self.settledVoxels)
			end
		end
	end)

	return self
end

function module:monitorVoxels()
	for _, part in CollectionService:GetTagged("DestructedVoxel") do
		if not part.Anchored and part.Parent ~= nil then
			local linearVel = part.AssemblyLinearVelocity.Magnitude
			local angularVel = part.AssemblyAngularVelocity.Magnitude

			if linearVel < SLEEP_THRESHOLD and angularVel < SLEEP_THRESHOLD then
				part.Anchored = true
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero

				local id = part:GetAttribute("ID")
				if id then
					self.settledVoxels[id] = true
				end
			end
		end
	end
end

function module:doDestruction(config, HitboxSize, HitboxCF)
	config = configModule.Validate(config)

	local params = OverlapParams.new() 
	local InitialParts = workspace:GetPartBoundsInBox(HitboxCF, HitboxSize, params)
	local part = Instance.new("Part", workspace)
	part.CanQuery = false
	part.CanCollide = false
	part.CanTouch = false
	part.Transparency = 0.5
	part.Anchored = true
	part.CFrame = HitboxCF
	part.Size=   HitboxSize
	game.Debris:AddItem(part, 0.2)
	local partsToReturn = {}
	local voxelsToReplicate = {}

	for _, originalPart in InitialParts do
		if not originalPart:IsA("Part") then continue end
		if not originalPart.CanCollide or originalPart:HasTag("RegenPart") or originalPart:HasTag("DestructedVoxel") then
			continue
		end
		if originalPart.Parent:FindFirstChildWhichIsA("Humanoid") or originalPart:FindFirstAncestorWhichIsA("Accessory") then
			continue
		end
		local color = originalPart.Color
		local material = originalPart.Material
		local transparency = originalPart.Transparency
		local parent = originalPart.Parent

		local voxelData = Divider.ComputeVoxels(originalPart, config, HitboxCF, HitboxSize)

		originalPart.Transparency = 1
		originalPart.CanCollide = false
		table.insert(partsToReturn, originalPart)

		for _, data in voxelData do
			local p = PartPooler.Get("DestructionVoxels", data.cf)

			local currentId = nextVoxelId
			nextVoxelId += 1
			p:SetAttribute("ID", currentId)
			WakeModule.AddPart(p)
			p.Size = data.size
			p.Color = data.isVoxel and color or (data.debugColor or color)
			p.Material = data.isVoxel and material or (data.debugColor and Enum.Material.Neon or material)
			p.Transparency = transparency
			p.Anchored = not data.isVoxel
			p.CanCollide = true
			p.Parent = data.isVoxel and workspace.Camera or workspace
			if data.isVoxel and config.SpawnVoxels then
				p:AddTag("DestructedVoxel")
				voxelsToReplicate[currentId] = p
			end
		end
	end
	local count = 0
	for _ in voxelsToReplicate do
		count += 1
	end
	if count > 0 then
		local birthBuffer = BufferModule.createBirthVoxelBuffer(voxelsToReplicate)
		VoxelSyncEvent:FireAllClients("Birth", birthBuffer)
	end

	for _, part in partsToReturn do
		PartPooler.Return("DestructionVoxels", part)
	end
end
function module:applyForce(originCF, range, force)
	local originPos = originCF.Position
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local nearbyParts = workspace:GetPartBoundsInRadius(originPos, range, params)

	for _, part in nearbyParts do
		if part:HasTag("DestructedVoxel") then
			part.Anchored = false 

			local direction = (part.Position - originPos)
			local distance = direction.Magnitude

			if distance == 0 then direction = Vector3.new(0, 1, 0) else direction = direction.Unit end

			local forceMultiplier = force * part:GetMass()
			part:ApplyImpulse(direction * forceMultiplier)
		end
	end
end

function module:applyForceInHitBox(forceOriginCF, force, hitboxCF, hitboxSize)
	local params = OverlapParams.new()
	local partsInBox = workspace:GetPartBoundsInBox(hitboxCF, hitboxSize, params)

	for _, part in partsInBox do
		if part:HasTag("DestructedVoxel") then
			part.Anchored = false 

			local direction
			if typeof(force) == "Vector3" then
				direction = force
			else
				direction = (part.Position - forceOriginCF.Position)
				if direction.Magnitude == 0 then direction = Vector3.new(0, 1, 0) else direction = direction.Unit end
				direction *= force
			end

			part:ApplyImpulse(direction * part:GetMass())
		end
	end
end

return module