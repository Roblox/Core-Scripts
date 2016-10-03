--	// FileName: MessageLabelCreator.lua
--	// Written by: Xsitsu
--	// Description: Module to handle taking text and creating stylized GUI objects for display in ChatWindow.

local OBJECT_POOL_SIZE = 50

local module = {}
--////////////////////////////// Include
--//////////////////////////////////////
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local clientChatModules = ReplicatedStorage:WaitForChild("ClientChatModules")
local messageCreatorModules = clientChatModules:WaitForChild("MessageCreatorModules")
local messageCreatorUtil = require(messageCreatorModules:WaitForChild("Util"))
local modulesFolder = script.Parent
local moduleTransparencyTweener = require(modulesFolder:WaitForChild("TransparencyTweener"))
local ChatSettings = require(clientChatModules:WaitForChild("ChatSettings"))
local moduleObjectPool = require(modulesFolder:WaitForChild("ObjectPool"))
local ClassMaker = require(modulesFolder:WaitForChild("ClassMaker"))
local MessageSender = require(modulesFolder:WaitForChild("MessageSender"))

--////////////////////////////// Methods
--//////////////////////////////////////
local methods = {}

function ReturnToObjectPoolRecursive(instance, objectPool)
	local children = instance:GetChildren()
	for i = 1, #children do
		ReturnToObjectPoolRecursive(children[i], objectPool)
	end
	instance.Parent = nil
	objectPool:ReturnInstance(instance)
end

function GetMessageCreators()
	local typeToFunction = {}
	local creators = messageCreatorModules:GetChildren()
	for i = 1, #creators do
		if creators[i].Name ~= "Util" then
			local creator = require(creators[i])
			typeToFunction[creator[messageCreatorUtil.KEY_MESSAGE_TYPE]] = creator[messageCreatorUtil.KEY_CREATOR_FUNCTION]
		end
	end
	return typeToFunction
end

local function WrapIntoMessageObject(id, BaseFrame, BaseMessage, Tweener, StrongReferences, UpdateTextFunction, ObjectPool)
	local obj = {}

	obj.ID = id
	obj.BaseFrame = BaseFrame
	obj.BaseMessage = BaseMessage
	obj.Tweener = Tweener
	obj.StrongReferences = StrongReferences
	obj.UpdateTextFunction = UpdateTextFunction or function() warn("NO MESSAGE RESIZE FUNCTION") end
	obj.ObjectPool = ObjectPool
	obj.Destroyed = false

	function obj:TweenOut(duration)
		if not Destroyed then
			self.Tweener:Tween(duration, 1)
		end
	end

	function obj:TweenIn(duration)
		if not self.Destroyed then
			self.Tweener:Tween(duration, 0)
		end
	end

	function obj:Destroy()
		self.Tweener:UnregisterTweenObject(self)
		ReturnToObjectPoolRecursive(self.BaseFrame, self.ObjectPool)
		self.Destroyed = true
	end

	return obj
end

function methods:ProcessCreatedMessage(messageData, BaseFrame, BaseMessage, UpdateTextFunction)
	local Tweener = moduleTransparencyTweener.new()
	Tweener:RegisterTweenObjectProperty(BaseMessage, "TextTransparency")
	Tweener:RegisterTweenObjectProperty(BaseMessage, "TextStrokeTransparency")

	local StrongReferences = {}
	local function ProcessChild(child)
		if (child:IsA("TextLabel") or child:IsA("TextButton")) then
			Tweener:RegisterTweenObjectProperty(child, "TextTransparency")
			Tweener:RegisterTweenObjectProperty(child, "TextStrokeTransparency")
			table.insert(StrongReferences, child)
		elseif (child:IsA("ImageLabel") or child:Is("ImageButton")) then
			Tweener:RegisterTweenObjectProperty(child, "ImageTransparency")
			table.insert(StrongReferences, child)
		end
	end

	for i, v in pairs(BaseMessage:GetChildren()) do
		ProcessChild(v)
	end

	return WrapIntoMessageObject(messageData.ID, BaseFrame, BaseMessage, Tweener, StrongReferences, UpdateTextFunction, self.ObjectPool)
end

function methods:CreateMessageLabelFromType(messageData, messageType)
	local message = messageData.Message
	if messageType == "Message" then
		if string.sub(message, 1, 4) == "/me " then
			messageType = "MeCommandMessage"
		end
	elseif messageType == "EchoMessage" then
		if string.sub(message, 1, 4) == "/me " then
			messageType = "MeCommandChannelEchoMessage"
		end
	end
	if self.MessageCreators[messageType] then
		local BaseFrame, BaseMessage, UpdateTextFunction = self.MessageCreators[messageType](messageData)
		if BaseFrame then
			return self:ProcessCreatedMessage(messageData, BaseFrame, BaseMessage, UpdateTextFunction)
		end
	elseif self.DefaultCreatorType then
		local BaseFrame, BaseMessage, UpdateTextFunction = self.MessageCreators[self.DefaultCreatorType](messageData)
		if BaseFrame then
			return self:ProcessCreatedMessage(messageData, BaseFrame, BaseMessage, UpdateTextFunction)
		end
	else
		error("No message creator available for message type: " ..messageType)
	end
end

--///////////////////////// Constructors
--//////////////////////////////////////
ClassMaker.RegisterClassType("MessageLabelCreator", methods)

function module.new()
	local obj = {}

	obj.ObjectPool = moduleObjectPool.new(OBJECT_POOL_SIZE)
	obj.MessageCreators = GetMessageCreators()
	obj.DefaultCreatorType = messageCreatorUtil.DEFAULT_MESSAGE_CREATOR

	ClassMaker.MakeClass("MessageLabelCreator", obj)

	messageCreatorUtil:RegisterObjectPool(obj.ObjectPool)

	return obj
end

function module:RegisterGuiRoot(root)
	messageCreatorUtil:RegisterGuiRoot(root)
end

function module:GetStringTextBounds(text, font, fontSize, sizeBounds)
	return messageCreatorUtil:GetStringTextBounds(text, font, fontSize, sizeBounds)
end

return module
