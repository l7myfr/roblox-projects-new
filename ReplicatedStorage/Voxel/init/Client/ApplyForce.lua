-- @ScriptType: ModuleScript
local module = {}

function module.ApplyForce(Part, Data)
	local Settings = Data.Settings
	if not Settings.ApplyForce then return end
	if not Settings.ForceDirectionInflufencePart then return end

	local InfluencePart = Settings.ForceDirectionInflufencePart
	local BaseDirection = Settings.ForceVector or Vector3.new(0, 1, 0)
	local ForceMagnitude = Settings.Force or 5
	local WorldDirection = InfluencePart.CFrame:VectorToWorldSpace(BaseDirection.Unit)
	local Velocity = WorldDirection * ForceMagnitude

	Part.AssemblyLinearVelocity = Velocity
end

return module
