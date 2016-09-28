--	// FileName: ObjectPool.lua
--	// Written by: TheGamer101
--	// Description: An object pool class used to avoid unnecessarily instantiating Instances.

local module = {}
--////////////////////////////// Include
--//////////////////////////////////////
local modulesFolder = script.Parent
local ClassMaker = require(modulesFolder:WaitForChild("ClassMaker"))

--////////////////////////////// Methods
--//////////////////////////////////////
local methods = {}

function methods:GetInstance(className)
  if self.InstancePoolsByClass[className] == nil then
    self.InstancePoolsByClass[className] = {}
  end
  local availableInstances = #self.InstancePoolsByClass[className]
  if availableInstances > 0 then
    local instance = self.InstancePoolsByClass[className][availableInstances]
    table.remove(self.InstancePoolsByClass[className])
    return instance
  end
  return Instance.new(className)
end

function methods:ReturnInstance(instance)
  if self.InstancePoolsByClass[instance.ClassName] == nil then
    self.InstancePoolsByClass[instance.ClassName] = {}
  end
  if #self.InstancePoolsByClass[instance.ClassName] < self.PoolSizePerType then
    table.insert(self.InstancePoolsByClass[instance.ClassName], instance)
  else
    instance:Destroy()
  end
end

--///////////////////////// Constructors
--//////////////////////////////////////
ClassMaker.RegisterClassType("ObjectPool", methods)

function module.new(poolSizePerType)
	local obj = {}
	obj.InstancePoolsByClass = {}
	obj.Name = "ObjectPool"
  obj.PoolSizePerType = poolSizePerType

	ClassMaker.MakeClass("ObjectPool", obj)

	return obj
end

return module
