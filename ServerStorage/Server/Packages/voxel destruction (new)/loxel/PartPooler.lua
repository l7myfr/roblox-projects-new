-- @ScriptType: ModuleScript
local SharedPooler = {}

local pools = {} 
local globalIdCounter = 0 

local STORAGE_LOCATION = Instance.new("Folder")
STORAGE_LOCATION.Name = "PartCache_Server"
STORAGE_LOCATION.Parent = workspace

local function createNewPart(poolData)
	globalIdCounter += 1

	local part = poolData.Template:Clone()
	part.Position = Vector3.new(0, 10000, 0) 
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = STORAGE_LOCATION


	table.insert(poolData.AvailableParts, part)
	return part
end

function SharedPooler.createPool(poolName, templatePart, initialSize)
	if pools[poolName] then return end 

	pools[poolName] = {
		Template = templatePart,
		AvailableParts = {}
	}

	for i = 1, initialSize do
		createNewPart(pools[poolName])
	end
	print(poolName .. " filled up. Total global parts created: " .. globalIdCounter)
end

function SharedPooler.Get(poolName, cf)
	local poolData = pools[poolName]
	if not poolData then 
		warn("Pool '" .. poolName .. "' has not been initialized!")
		return nil 
	end

	if #poolData.AvailableParts == 0 then
		createNewPart(poolData)
	end

	local part = table.remove(poolData.AvailableParts)
	part.CFrame = cf
	part.Transparency = 0
	part.Anchored = true 
	part.CanCollide = false 

	return part
end

function SharedPooler.Return(poolName, part)
	local poolData = pools[poolName]
	if not poolData then return end

	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Position = Vector3.new(0, 10000, 0)

	-- Reset physics properties if necessary
	if part:IsA("BasePart") then
		part.AssemblyLinearVelocity = Vector3.zero
		part.AssemblyAngularVelocity = Vector3.zero
	end

	part.Parent = STORAGE_LOCATION
	table.insert(poolData.AvailableParts, part)
end

return SharedPooler