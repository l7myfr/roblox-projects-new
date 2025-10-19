-- @ScriptType: ModuleScript
local module = {}
local SharedModules = script.Parent.Parent.Shared
local PartPooler = require(SharedModules.PartPool)
local Signal = require(SharedModules.Signal)
local Network = require(SharedModules.Network)
local ServerModules = script.Parent
local Divider = require(ServerModules.Divider)
local CreateHitbox = require(ServerModules.CreateHitbox)
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
function module.DoDestruction(Settings, self)
	local HitboxClass = CreateHitbox.RegisterHitbox(Settings)
	local Parts = {}
	local Id = HttpService:GenerateGUID()
	local ToReplicate = {
		Settings = Settings,
		Id = Id,
		Parts = {}	
	}
	Settings.Id = Id
	-- we will use this table to send information to the client to replicate the voxels on the client
	-- this will also keep dividing the parts till we get a suitable size
	repeat
		Parts = HitboxClass:GetPartsInParts()
		for index = #Parts, 1, -1 do
			local Part = Parts[index]
			if not Part:IsA("Part") then
				Parts[index] = nil
				continue 
			end

			if Part:HasTag("RegenPart") then
				Parts[index] = nil
				continue 
			end
			if Part:IsDescendantOf(workspace.Alive) then 
				Parts[index] = nil
				continue
			end
			local PartSplit = Divider.DividePart(Part, self, Settings)
			if PartSplit then continue end
			if Settings.SpawnVoxels ~= true then 
				Part:Destroy()
				continue
			end
			ToReplicate.Parts[#ToReplicate.Parts + 1] = {
				Position = Part.Position,
				Size = Part.Size,
				Color = Part.Color,
				Transparency = Part.Transparency,
				Material = Part.Material,
				TopSurface = Part.TopSurface,
				BottomSurface = Part.BottomSurface,
				LeftSurface = Part.LeftSurface,
				RightSurface = Part.RightSurface,
				FrontSurface = Part.FrontSurface,
				BackSurface = Part.BackSurface,

			}
			Part:Destroy()
		end
		RunService.Heartbeat:Wait()
	until #Parts == 0 
	HitboxClass:Destroy()
	if #ToReplicate.Parts == 0 then return end
	Network:FireAll("RenderVoxel", ToReplicate)
end
return module
