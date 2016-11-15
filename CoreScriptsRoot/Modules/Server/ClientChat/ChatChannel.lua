--	// FileName: ChatChannel.lua
--	// Written by: Xsitsu
--	// Description: ChatChannel class for handling messages being added and removed from the chat channel.

local module = {}
--////////////////////////////// Include
--//////////////////////////////////////
local Chat = game:GetService("Chat")
local clientChatModules = Chat:WaitForChild("ClientChatModules")
local modulesFolder = script.Parent
local ClassMaker = require(modulesFolder:WaitForChild("ClassMaker"))

local ChatSettings = require(clientChatModules:WaitForChild("ChatSettings"))

--////////////////////////////// Methods
--//////////////////////////////////////
local methods = {}

function methods:Destroy()
	self.Destroyed = true
end

function methods:SetActive(active)
	if active == self.Active then
		return
	end
	if active == false then
		self.MessageLogDisplay:Clear()
	else
		self.MessageLogDisplay:SetCurrentChannelName(self.Name)
		for i = 1, #self.MessageLog do
			self.MessageLogDisplay:AddMessage(self.MessageLog[i])
		end
	end
	self.Active = active
end

function methods:UpdateMessageFiltered(messageData)
	local searchIndex = 1
	local searchTable = self.MessageLog
	local messageObj = nil
	while (#searchTable >= searchIndex) do
		local obj = searchTable[searchIndex]

		if (obj.ID == messageData.ID) then
			messageObj = obj
			break
		end

		searchIndex = searchIndex + 1
	end

	if messageObj then
		messageObj.Message = messageData.Message
		messageObj.IsFiltered = true
		if self.Active then
			self.MessageLogDisplay:UpdateMessageFiltered(messageObj)
		end
	end
end

function methods:AddMessageToChannel(messageData)
	table.insert(self.MessageLog, messageData)
	if self.Active then
		self.MessageLogDisplay:AddMessage(messageData)
	end
	if #self.MessageLog > ChatSettings.MessageHistoryLengthPerChannel then
		self:RemoveLastMessageFromChannel()
	end
end

function methods:RemoveLastMessageFromChannel()
	table.remove(self.MessageLog, 1)

	if self.Active then
		self.MessageLogDisplay:RemoveLastMessage()
	end
end

function methods:ClearMessageLog()
	rawset(self, "MessageLog", {})

	if self.Active then
		self.MessageLogDisplay:Clear()
	end
end

function methods:RegisterChannelTab(tab)
	rawset(self, "ChannelTab", tab)
end

--///////////////////////// Constructors
--//////////////////////////////////////
ClassMaker.RegisterClassType("ChatChannel", methods)

function module.new(channelName, messageLogDisplay)
	local obj = {}
	obj.Destroyed = false
	obj.Active = false

	obj.MessageLog = {}
	obj.MessageLogDisplay = messageLogDisplay
	obj.ChannelTab = nil
	obj.Name = channelName

	ClassMaker.MakeClass("ChatChannel", obj)

	return obj
end

return module
