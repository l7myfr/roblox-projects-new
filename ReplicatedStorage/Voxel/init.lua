-- @ScriptType: ModuleScript
local IsServer = game["Run Service"]:IsServer()

if IsServer then
	return require(script.Server)
else
	script.Server:Destroy()
	return require(script.Client)
end
