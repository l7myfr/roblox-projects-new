-- @ScriptType: ModuleScript

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TerrainGenerator = {}
function TerrainGenerator.Generate(self)
	local ChunkSize = 100
	local Settings = self.Settings
	local TotalWidthX = Settings.WidthX
	local NumChunks = math.ceil((TotalWidthX + 1) / ChunkSize)
	-- we js spliting up the workload hooray
	print("Number of chunks/threads working ", NumChunks)
	for i = 0, NumChunks - 1 do
		task.spawn(function()
			local StartX = i * ChunkSize
			local EndX = math.min(StartX + ChunkSize, TotalWidthX)
			if StartX == EndX then return end
			local thread = Instance.new("Actor")
			local Script = script.Parent.WorkerScripts.WorkerScriptHeightsTemplate:Clone()
			Script.Parent = thread
			thread.Name = `HeightActor_{i}`
			thread.Parent = game.ServerScriptService

			while not thread:GetAttribute("Loaded") do
				RunService.Heartbeat:Wait()
			end
			thread:SendMessage("Process", Settings, StartX, EndX)
		end)
	end
end


return TerrainGenerator
