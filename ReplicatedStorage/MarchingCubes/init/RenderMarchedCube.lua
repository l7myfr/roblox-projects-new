-- @ScriptType: ModuleScript
local RenderMesh = {}
local AssetService = game:GetService("AssetService")

local function vectorKey(v)
	return string.format("%.6f_%.6f_%.6f", v.X, v.Y, v.Z)
end

local MAX_TRIANGLES_PER_MESH = 20000
local function createpart(psotion, COlor)
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(0.5,0.5, 0.5)
	part.Position = psotion
	part.Anchored = true
	part.CanCollide = false
	part.Parent = workspace
	return part
end
function RenderMesh.Render(self)
	local triangleIndices = self.Triangles
	local vertexList = self.Vertices
	assert(#triangleIndices % 3 == 0, "Triangle index list must be a multiple of 3")
	local meshes = {}
	local Pos = self.Settings.Position or Vector3.zero
	local function createMeshPart(startIndex, endIndex)
		local editableMesh = AssetService:CreateEditableMesh()
		local vertexMap = {}

		local function getOrCreateVertex(v)
			local key = vectorKey(v)
			if vertexMap[key] then
				return vertexMap[key]
			else
				local index = editableMesh:AddVertex(v)
				vertexMap[key] = index
				return index
			end
		end


		for i = startIndex, endIndex, 3 do
			local A = vertexList[i]+ Pos
			local B = vertexList[i + 1] + Pos
			local C = vertexList[i + 2]  + Pos
			local v1 = getOrCreateVertex(A)
			local v2 = getOrCreateVertex(B)
			local v3 = getOrCreateVertex(C)
			editableMesh:AddTriangle(v1, v2, v3)
		end

		local meshContent = Content.fromObject(editableMesh)
		local meshPart = AssetService:CreateMeshPartAsync(meshContent, nil)
		
		meshPart.Name = "GeneratedMesh"
		meshPart.Anchored = true
		meshPart.Material = Enum.Material.SmoothPlastic
		meshPart.Color = Color3.fromRGB(255, 170, 100)
		meshPart.Parent = workspace

		return meshPart
	end


	local totalTriangles = #triangleIndices // 3

	for i = 0, totalTriangles - 1, MAX_TRIANGLES_PER_MESH do
		local startTriangle = i
		local endTriangle = math.min(i + MAX_TRIANGLES_PER_MESH - 1, totalTriangles - 1)

		local startIndex = startTriangle * 3 + 1
		local endIndex = endTriangle * 3 + 3

		local meshPart = createMeshPart(startIndex, endIndex)
		table.insert(meshes, meshPart)
	end

	return meshes
end



return RenderMesh
