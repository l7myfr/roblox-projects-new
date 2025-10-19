-- @ScriptType: ModuleScript
local Client = {}
Client.__index = Client
local SharedModules = script.Parent.Shared
local PartPooler = require(SharedModules.PartPool)
local Signal = require(SharedModules.Signal)
local Network = require(SharedModules.Network)
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Destruction = require(ReplicatedStorage.Voxel.init.Server.Destruction)
Network:RegisterEvent("RenderVoxel")
Network:RegisterEvent("DoDestruction")
Network:RegisterEvent("DestroyVoxelRender")

function Client.init()
	if script:GetAttribute("Started") == true then 
		warn("Server: voxel destrution module can only be called once")
		return
	end
	script:SetAttribute("Started", true)
	local self = setmetatable({}, Client)
	self.PooledClass = PartPooler.new(Instance.new("Part"), 5000, workspace.Pooling.Client)
	
	return self
end

function Client:Start()
	Network:OnEvent("DoDestruction", function(Player, Settings)
		Destruction.DoDestruction(Settings, self)		
	end)
end
return Client
