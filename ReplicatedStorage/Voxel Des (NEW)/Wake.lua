--!strict
-- this is needed cus roblox keeps fucking putting unanchored parts to sleep
local WakeModule = {}

local RunService = game:GetService("RunService")

local activeParts: { [BasePart]: boolean } = {}

local TINY_VELOCITY = Vector3.new(0, -0.01, 0)

RunService.Heartbeat:Connect(function()
	for part, _ in activeParts do
		if part and part.Parent and not part.Anchored then
			part.AssemblyLinearVelocity += TINY_VELOCITY
		else
			activeParts[part] = nil
		end
	end
end)

function WakeModule.AddPart(part: BasePart)
	if not part:IsA("BasePart") then
		return
	end
	activeParts[part] = true
end

function WakeModule.RemovePart(part: BasePart)
	activeParts[part] = nil
end

function WakeModule.ClearAll()
	table.clear(activeParts)
end

return WakeModule