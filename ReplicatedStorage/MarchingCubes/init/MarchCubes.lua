-- @ScriptType: ModuleScript
local MarchCubes = {}

local MarchingTables = require(script.Parent.MarchingTables)
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsServer = RunService:IsServer()

local function createpart(position)
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Parent = workspace
	return part
end

local function GetConfigIndex(self, cubeCorners)
	local Threshold = self.Settings.SurfaceThreshold
	local index = 0
	for i = 1, 8 do
		-- something to do with bits likek 0001 0010 0011 ect. idk how to explain it better, fuck you future lemy
		if cubeCorners[i] > Threshold then
			index = bit32.bor(index, bit32.lshift(1, i - 1))
		end
	end
	return index
end

local function MarchCube(Position, cubeCorners, self, CellSize)
	local VerticesTable = table.create(12)
	local TrianglesTable = table.create(15)
	local Threshold = self.Settings.SurfaceThreshold
	local Tables = MarchingTables

	local ConfigI = GetConfigIndex(self, cubeCorners)
	if ConfigI == 0 or ConfigI == 255 then return end

	local TrianglesList = Tables.Triangles[ConfigI + 1]
	if not TrianglesList then return end

	-- Interpolates between two cube corners to find the surface vertex
	local function GetInterpolatedVertex(EdgeTableIndex)
		local EdgeIndex = EdgeTableIndex + 1
		if EdgeIndex < 1 or EdgeIndex > 12 then return nil end

		local CornerIndices = Tables.EdgeToCornerIndices[EdgeIndex]
		local A_i, B_i = CornerIndices[1], CornerIndices[2]

		local HeightA, HeightB = cubeCorners[A_i], cubeCorners[B_i]
		local Offsets = Tables.Edges[EdgeIndex]
		local AOffset, BOffset = Offsets[1], Offsets[2]

		-- Calculate world-space position of the edge's endpoints
		local EdgeStart = Position + Vector3.new(AOffset.x, AOffset.y, AOffset.z) * CellSize
		local EdgeEnd = Position + Vector3.new(BOffset.x, BOffset.y, BOffset.z) * CellSize

		-- t is the interpolation factor based on scalar field threshold crossing
		local t = math.clamp((Threshold - HeightA) / (HeightB - HeightA), 0, 1)
		local Vertex = EdgeStart:Lerp(EdgeEnd, t)

		table.insert(VerticesTable, Vertex)
		return #VerticesTable
	end

	-- Build triangle indices using interpolated edge vertices
	for i = 1, #TrianglesList, 3 do
		local e1, e2, e3 = TrianglesList[i], TrianglesList[i + 1], TrianglesList[i + 2]
		if e1 < 0 then break end

		local v1 = GetInterpolatedVertex(e1)
		local v2 = GetInterpolatedVertex(e2)
		local v3 = GetInterpolatedVertex(e3)

		table.insert(TrianglesTable, v1)
		table.insert(TrianglesTable, v2)
		table.insert(TrianglesTable, v3)
	end

	return VerticesTable, TrianglesTable
end

-- Main chunk processing function
function MarchCubes.ProcessChunk(self)
	local localVertices = table.create(1000)
	local localTriangles = table.create(3000)

	local Settings = self.Settings
	local Heights = self.Heights
	local Tables = MarchingTables

	local DetailScale = Settings.DetailScale
	local CellSize = Settings.CellSize / DetailScale
	local WidthZ, Height = Settings.WidthZ, Settings.Height
	local Step = 1 / DetailScale

	local Corners = Tables.Corners
	local counter = 0

	local xEnd = Settings.EndX
	local StartX = Settings.StartX

	-- Precompute total number of iterations
	local xSteps = math.floor((xEnd - StartX) / Step)
	local ySteps = math.floor(Height / Step)
	local zSteps = math.floor(WidthZ / Step)
	local totalIterations = xSteps * ySteps * zSteps

	local Value = Instance.new("IntValue")
	Value.Name = `HeightActor_{self.ThreadId}`
	Value.Parent = script
	local function ReportProgress(percent)
		Value.Value = percent
	end

	local processed = 0
	local lastReported = -1

	for x = StartX, xEnd - Step, Step do
		for y = 0, Height - Step, Step do
			for z = 0, WidthZ - Step, Step do
				local CubeCorners = table.create(8)

				if counter % 100000 == 0 then
					task.wait()
				end
				counter += 1

				for i = 1, 8 do
					local offset = Corners[i]
					local mapX = math.floor(x + offset.x * Step)
					local cx = mapX + 1
					local cy = math.floor(y + offset.y * Step) + 1
					local cz = math.floor(z + offset.z * Step) + 1

					if Heights[cx] and Heights[cx][cy] and Heights[cx][cy][cz] then
						CubeCorners[i] = Heights[cx][cy][cz]
					else
						CubeCorners[i] = 0
					end
				end

				local pos = Vector3.new(x, y, z)
				local verts, tris = MarchCube(pos, CubeCorners, self, CellSize)

				if verts and tris then
					local base = #localVertices
					table.move(verts, 1, #verts, base + 1, localVertices)
					for _, t in tris do
						table.insert(localTriangles, t + base)
					end
				end

				processed += 1
				local percent = math.floor((processed / totalIterations) * 100)
				if percent ~= lastReported then
					ReportProgress(percent)
					lastReported = percent
				end
			end
		end
	end
	Value:Destroy()
	return localVertices, localTriangles
end


local RenderMarchedCubes = require(script.Parent.RenderMarchedCube)

function MarchCubes.MarchCubes(self)
	print("Processing marching")
	local verts, tris = MarchCubes.ProcessChunk(self)

	local NewData = {
		Settings = self.Settings,
		Vertices = verts,
		Triangles = {},
	}
	local baseIndex = #verts
	for _, t in tris do
		table.insert(NewData.Triangles, t + baseIndex)
	end

	print("Rendering")
	RenderMarchedCubes.Render(NewData)
end

return MarchCubes
