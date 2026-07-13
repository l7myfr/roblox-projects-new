local module = {}
module.__index = module

local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Wheat = require(ServerStorage.Server.Modules.Classes.Plants.Wheat)
local PlantFunctions = require(ServerStorage.Server.Modules.PlantFunctions)

function module.init(server)
	local self = setmetatable({}, module)
	self.server = server
	return self
end
-- ok so uh thyis is fired every heartbeat from outside this function
-- by a custom framework ive made that i use in all my games
function module:Tick(dt)
	PlantFunctions.Update()
end
function module:Start()
	for _, farmland in CollectionService:GetTagged("Farmland")  do
		local points = PlantFunctions.GetRandomPoints(farmland, 4, 0.2, 1.5)
		for _, position in points do
			local Wheatclass = Wheat.init(position)
			Wheatclass:Start()
		end
	end
end
return module
