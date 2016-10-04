--	// FileName: ProcessCommands.lua
--	// Written by: TheGamer101
--	// Description: Module for processing commands using the client CommandModules

local module = {}
local methods = {}

--////////////////////////////// Include
--//////////////////////////////////////
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local clientChatModules = ReplicatedStorage:WaitForChild("ClientChatModules")
local commandModules = clientChatModules:WaitForChild("CommandModules")
local commandUtil = require(commandModules:WaitForChild("Util"))
local modulesFolder = script.Parent
local ChatSettings = require(clientChatModules:WaitForChild("ChatSettings"))
local ClassMaker = require(modulesFolder:WaitForChild("ClassMaker"))

function GetCommandFunctions()
  local commandFunctions = {}
	local commands = commandModules:GetChildren()
	for i = 1, #commands do
		if commands[i].Name ~= "Util" then
			local commandFunction = require(commands[i])
			table.insert(commandFunctions, commandFunction)
		end
	end
	return commandFunctions
end

function methods:ProcessChatCommands(message, ChatWindow)
  for i = 1, #self.CommandFunctions do
    local processedCommand = self.CommandFunctions[i](message, ChatWindow, ChatSettings)
    if processedCommand then
      return true
    end
  end
  return false
end

--///////////////////////// Constructors
--//////////////////////////////////////
ClassMaker.RegisterClassType("CommandProcessor", methods)

function module.new()
	local obj = {}

	obj.CommandFunctions = GetCommandFunctions()

	ClassMaker.MakeClass("CommandProcessor", obj)

	return obj
end

return module
