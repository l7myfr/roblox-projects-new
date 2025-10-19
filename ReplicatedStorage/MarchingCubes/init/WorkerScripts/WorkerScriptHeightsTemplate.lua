-- @ScriptType: Script
local actor : Actor = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarchCubes = require(ReplicatedStorage.init.MarchCubes)
local function CreatePart(pos)
	local part = Instance.new("Part", workspace)
	part.CastShadow = false
	part.Position = pos
	part.Anchored = true
	part.Shape = Enum.PartType.Ball
	return part
end
local counter = 0
actor:BindToMessage("Process", function(Settings, StartX, EndX, Id)
	local Height = Settings.Height
	local WidthZ = Settings.WidthZ
	local SurfaceThreshold = Settings.SurfaceThreshold
	local NoiseScale = Settings.NoiseScale
	local pos = Settings.Position or Vector3.zero
	local HeightsNew = {}
	for x = StartX , EndX + 1 do
		local globalX = (x - 1) + pos.X
		if not HeightsNew[x] then HeightsNew[x] = {} end

		for y = 1, Height + 1 do
			local globalY = (y - 1) + pos.Y
			if not HeightsNew[x][y] then HeightsNew[x][y] = {} end

			for z = 1, WidthZ  + 1 do
				if counter % 100000 == 0 then
					task.wait()
				end
				counter += 1
				local globalZ = (z - 1) + pos.Z

				local worldX = globalX * NoiseScale
				local worldY = globalY * NoiseScale
				local worldZ = globalZ * NoiseScale

				local NoiseValue = math.noise(worldX, worldY, worldZ)
				local CHeight = Height * NoiseValue

				local DistanceToSurface
				if y <= CHeight - SurfaceThreshold then
					DistanceToSurface = 0
				elseif y > CHeight + SurfaceThreshold then
					DistanceToSurface = 1
				elseif y > CHeight then
					DistanceToSurface = y - CHeight
				else
					DistanceToSurface = CHeight - y
				end
				--if x % 10 == 0 and y % 10 == 0 and z % 10 == 0 then
				--	CreatePart(Vector3.new(globalX, globalY, globalZ)):SetAttribute("Dist", DistanceToSurface)
				--end

				HeightsNew[x][y][z] = DistanceToSurface
			end
		end
	end
	Settings.StartX = StartX
	Settings.EndX = EndX
	local NewData = {
		Settings = Settings,
		Heights = HeightsNew,
		Triangles = {},
		Vertices = {},
		ThreadId = Id
	}
	task.synchronize()
	MarchCubes.MarchCubes(NewData)
	actor:Destroy()

end)
actor:SetAttribute("Loaded", true)