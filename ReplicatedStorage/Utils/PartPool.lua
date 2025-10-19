-- @ScriptType: ModuleScript
local Pool = {}
Pool.__index = Pool

local DefaultValues = {
	Anchored = true,
	Size = Vector3.zero,
	Position = Vector3.new(99999, 99999, 99999),
}

function Pool.new(Template, MaxParts, Parent)
	local self = setmetatable({}, Pool)
	self.Template = Template
	self.Pool = {}
	self.TemplateParent = Parent
	self._createFunction = function()
		local newInstance = Template:Clone()
		for property, value in DefaultValues do
			newInstance[property] = value
		end
		newInstance.Parent = Parent
		return newInstance
	end

	for i = 1, MaxParts do
		local part = self._createFunction()
		table.insert(self.Pool, part)
	end

	return self
end

function Pool:Get()
	if #self.Pool == 0 then
		self:HandleError(1)
	end
	return table.remove(self.Pool)
end

function Pool:Return(pooledpart)
	pooledpart.Parent = self.TemplateParent
	for property, value in DefaultValues do
		pooledpart[property] = value
	end
	table.insert(self.Pool, pooledpart)
end

function Pool:HandleError(Error)
	if Error == 1 then
		local newPart = self._createFunction()
		table.insert(self.Pool, newPart)
	end
end

return Pool
