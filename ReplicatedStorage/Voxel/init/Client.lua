-- @ScriptType: ModuleScript
local Client = {}
Client.__index = Client
local SharedModules = script.Parent.Shared
local PartPooler = require(SharedModules.PartPool)
local Network = require(SharedModules.Network)
local Signal = require(SharedModules.Signal)
local EventHandler = require(script.EventHandler)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HandleVoxelRender = require(script.HandleVoxelRender)
function Client.init()
	if script:GetAttribute("Started") == true then 
		warn("Client: voxel destrution module can only be called once")
		return
	end
	script:SetAttribute("Started", true)
	local self = setmetatable({}, Client)
	self.PooledClass = PartPooler.new(Instance.new("Part"), 5000, workspace.Pooling.Client)
	self.OnRenderVoxelsSignal = Signal.new()
	self.OnVoxelRenderDestroy = Signal.new()
	self.VoxelRenders = {}
	return self
end

function Client:Start()
	-- handle rendering and destroying of voxel... obv.. lol 	
	EventHandler.HandleEvent("RenderVoxel",self.OnRenderVoxelsSignal)
	EventHandler.HandleEvent("DestroyVoxelRender",self.OnVoxelRenderDestroy)
	self.OnRenderVoxelsSignal:Connect(function(Data)
		self.VoxelRenders[Data.Id] = HandleVoxelRender.new(Data, self)
	end)
	self.OnVoxelRenderDestroy:Connect(function(RenderIds)
		for RenderId, Value in RenderIds do
			if not self.VoxelRenders[RenderId] then continue end
			self.VoxelRenders[RenderId]:Destroy()
			self.VoxelRenders[RenderId] = nil
		end
	end)






























	-- this is just a bad placeholder supposed to show off how the module work
	-- can be done on the server too. this is js for demonstration purposes
	local LP = game.Players.LocalPlayer

	LP:WaitForChild("Backpack")
	local function firetoolevent()
		local Settings = {
			VoxelSize = 6,
			ApplyForce = true,
			Force = 50,
			ForceDirectionInflufencePart = LP.Character.Humanoid.RootPart,
			ForceVector = Vector3.new(0,0, -1),
			Regenerate = true,
			RegenerationTime = 2,
			Debug = true	,
			Position = LP.Character.Humanoid.RootPart.Position,
			SpawnVoxels = true,
			HitboxSize = Vector3.new(5,5,5)
		}
		Network:Fire("DoDestruction",Settings)
	end
	LP.CharacterAdded:Connect(function(Char)
		LP.Backpack.ChildAdded:Connect(function(tool)
			tool.Activated:Connect(firetoolevent)
		end)
		for _, tool in LP.Backpack:GetChildren() do
			tool.Activated:Connect(firetoolevent)

		end
	end)
end
return Client
