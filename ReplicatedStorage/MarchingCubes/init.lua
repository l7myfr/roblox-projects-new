-- @ScriptType: ModuleScript
local Marching = {}
Marching.__index = Marching	
local Heights = require(script.Heights)
local MarchCubes = require(script.MarchCubes)
local RenderMarchedCube = require(script.RenderMarchedCube)


function Marching.init(settings)
	local self = setmetatable({}, Marching)
	self.Settings = {
		Height = settings.Heights or 100,
		WidthX = settings.Width or 250, 
		WidthZ = settings.Width or 250, 
		NoiseScale = settings.NoiseScale or 0.05,
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