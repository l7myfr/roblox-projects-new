-- @ScriptType: ModuleScript
local module = {}
local Network = require(script.Parent.Parent.Shared.Network)
function module.HandleEvent(EventName, CallbackSignal)
	Network:OnEvent(EventName, function(...)
		CallbackSignal:Fire(...)
	end)
end
return module
