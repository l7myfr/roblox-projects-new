-- @ScriptType: ModuleScript
local Marching = {}
Marching.__index = Marching	
local Heights = require(script.Heights)
local MarchCubes = require(script.MarchCubes)
local RenderMarchedCube = require(script.RenderMarchedCube)


function Marching.init(settings)
	local self = setmetatable({}, Marching)
	self.Settings = {
		Height = settings.Heights or 500,
		WidthX = settings.Width or 500, 
		WidthZ = settings.Width or 500, 
		NoiseScale = settings.NoiseScale or 0.01,
		SurfaceThreshold = settings.SurfaceThreshold or 0.5,
		DetailScale =  settings.DetailScale or 1,
		CellSize = settings.CellSize or 1,
		Position =settings.Position or  Vector3.zero
	}
	return self
end

function Marching:Generate()
	Heights.Generate(self)
end
function Marching:Start()
	self:Generate()
end
return Marching