-- @ScriptType: ModuleScript

local Signal = {}
Signal.__index = Signal

function Signal.new()
	local self = setmetatable({
		_connections = {},      
		_nextId = 0,
		_alive = true,
	}, Signal)
	return self
end

local function makeConnection(signal, id)
	local conn = {}
	function conn:Disconnect()
		if not signal._alive then return end
		for i = 1, #signal._connections do
			if signal._connections[i].id == id then
				table.remove(signal._connections, i)
				break
			end
		end
	end
	function conn.IsConnected()
		if not signal._alive then return false end
		for i = 1, #signal._connections do
			if signal._connections[i].id == id then
				return true
			end
		end
		return false
	end
	return conn
end

function Signal:Connect(fn)
	assert(self._alive, "Attempt to Connect to a destroyed Signal.")
	assert(type(fn) == "function", "Connect expects a function")
	self._nextId = self._nextId + 1
	local id = self._nextId
	table.insert(self._connections, { fn = fn, id = id })
	return makeConnection(self, id)
end

function Signal:Once(fn)
	assert(self._alive, "Attempt to Once on a destroyed Signal.")
	assert(type(fn) == "function", "Once expects a function")
	local conn
	conn = self:Connect(function(...)
		conn:Disconnect()
		fn(...)
	end)
	return conn
end
function Signal:Fire(...)
	if not self._alive then return end

	local snapshot = {}
	for i = 1, #self._connections do
		snapshot[i] = self._connections[i]
	end

	for i = 1, #snapshot do
		local entry = snapshot[i]
		if entry and entry.fn then
			local success, err = pcall(entry.fn, ...)
			if not success then
				warn(("Signal handler error: %s"):format(tostring(err)))
			end
		end
	end
end
function Signal:Wait()
	assert(self._alive, "Attempt to Wait on a destroyed Signal.")
	local co = coroutine.running()
	assert(co, "Wait must be called from a corotine.")

	local resultArgs
	local conn
	conn = self:Connect(function(...)
		conn:Disconnect()
		resultArgs = {...}
		local ok, err = pcall(coroutine.resume, co)
		if not ok then
			warn("Wait resume failed:", err)
		end
	end)

	coroutine.yield()

	if resultArgs then
		return table.unpack(resultArgs)
	end
	return nil
end

function Signal:Clear()
	if not self._alive then return end
	self._connections = {}
end

function Signal:Count()
	if not self._alive then return 0 end
	return #self._connections
end

function Signal:Destroy()
	if not self._alive then return end
	self._alive = false
	self._connections = nil
end

return Signal
