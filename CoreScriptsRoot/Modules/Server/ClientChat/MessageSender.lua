--	// FileName: MessageSender.lua
--	// Written by: Xsitsu
--	// Description: Module to centralize sending message functionality.

local module = {}
--////////////////////////////// Include
--//////////////////////////////////////
local modulesFolder = script.Parent
local ClassMaker = require(modulesFolder:WaitForChild("ClassMaker"))

--////////////////////////////// Methods
--//////////////////////////////////////
local methods = {}

function methods:SendMessage(message, toChannel)
	self.SayMessageRequest:FireServer(message, toChannel)
end

function methods:RegisterSayMessageFunction(func)
	rawset(self, "SayMessageRequest", func)
end

--///////////////////////// Constructors
--//////////////////////////////////////
ClassMaker.RegisterClassType("MessageSender", methods)

function module.new()
	local obj = {}
	obj.SayMessageRequest = nil

	ClassMaker.MakeClass("MessageSender", obj)

	return obj
end

return module.new()
