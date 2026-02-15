-- @ScriptType: ModuleScript
local module = {}
module.DefaultDestructConfig = {
	VoxelSize = 5,
	VoxelLifeItem = 10, -- seconds
	Regenerate = true,
	RegenerationTime = 15,
	SpawnVoxels = false,
	Debug = false,
	GreedyMerge = false
}
function module.Validate(Config)
	if not Config then
		return module.DefaultDestructConfig
	end
	for ConfigName, ConfigValue in module.DefaultDestructConfig do
		if Config[ConfigName] then continue end
		Config[ConfigName] = ConfigValue
	end
	return Config
end

local CollectionService = game:GetService("CollectionService")
return module
