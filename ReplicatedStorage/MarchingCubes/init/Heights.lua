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

--local MarchCubes = require(ReplicatedStorage.init.MarchCubes)

--function TerrainGenerator.Generate(self)
--	local Settings = self.Settings
--	local Height = Settings.Height
--	local WidthX = Settings.WidthX
--	local WidthZ = Settings.WidthZ
--	local SurfaceThreshold = Settings.SurfaceThreshold
--	local NoiseScale = Settings.NoiseScale
--	self.Heights = {}
--	local Heights = self.Heights

--	local pos = Settings.Position or Vector3.zero
--	for x = 1, WidthX + 1 do
--		local globalX = (x - 1) + pos.X
--		if not Heights[x] then Heights[x] = {} end

--		for y = 1, Height + 1 do
--			local globalY = (y - 1) + pos.Y
--			if not Heights[x][y] then Heights[x][y] = {} end

--			for z = 1, WidthZ + 1 do



--				local globalZ = (z - 1) + pos.Z

--				local worldX = globalX * NoiseScale
--				local worldY = globalY * NoiseScale
--				local worldZ = globalZ * NoiseScale

--				local NoiseValue = math.noise(worldX, worldY, worldZ)
--				local CHeight = Height * NoiseValue

--				local DistanceToSurface
--				if y <= CHeight - SurfaceThreshold then
--					DistanceToSurface = 0
--				elseif y > CHeight + SurfaceThreshold then
--					DistanceToSurface = 1
--				elseif y > CHeight then
--					DistanceToSurface = y - CHeight
--				else
--					DistanceToSurface = CHeight - y
--				end
--				Heights[x][y][z] = DistanceToSurface
--			end
--		end
--	end
--	self.Settings.StartX = 1
--	self.Settings.EndX = WidthX
--	MarchCubes.MarchCubes(self)
--end



return TerrainGenerator
