-- @ScriptType: ModuleScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()
local IS_CLIENT = RunService:IsClient()

local Network = {}
Network._events = {}

local remoteFolder = ReplicatedStorage:FindFirstChild("NetworkRemotes") or Instance.new("Folder")
remoteFolder.Name = "NetworkRemotes"
remoteFolder.Parent = ReplicatedStorage
function Network:RegisterEvent(EventName)
	local remote = Instance.new("RemoteEvent")
	remote.Name = EventName
	remote.Parent = remoteFolder
end
local function RegisterEventPrivate(EventName)
	local remote = Instance.new("RemoteEvent")
	remote.Name = EventName
	remote.Parent = remoteFolder
	return
end
local function getRemote(name)
	local remote = remoteFolder:FindFirstChild(name)
	if not remote then
		if IS_SERVER then
			remote = RegisterEventPrivate(name)
		else
			remote = remoteFolder:WaitForChild(name)
		end
	end
	return remote
end

function Network:OnEvent(name, callback)
	if IS_CLIENT then
		local remote = getRemote(name)
		remote.OnClientEvent:Connect(callback)
	elseif IS_SERVER then
		local remote = getRemote(name)
		remote.OnServerEvent:Connect(function(player, ...)
			callback(player, ...)
		end)
	end
end

function Network:Fire(...)
	if IS_SERVER then
		local player, name, args = ...
		assert(typeof(player) == "Instance" and player:IsA("Player"), "Expected Player for server Fire")
		local remote = getRemote(name)
		remote:FireClient(player, select(3, ...))
	else
		local name = ...
		local remote = getRemote(name)
		remote:FireServer(select(2, ...))
	end
end


function Network:FireAll(name, ...)
	debug.traceback()
	assert(IS_SERVER, "FireAll can only be used on the server")
	local remote = getRemote(name)
	remote:FireAllClients(...)
end
return Network
