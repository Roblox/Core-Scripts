--	// FileName: ChatServiceRunner.lua
--	// Written by: Xsitsu
--	// Description: Main script to initialize ChatService and run ChatModules.

local EventFolderName = "DefaultChatSystemChatEvents"
local EventFolderParent = game:GetService("ReplicatedStorage")
local modulesFolder = script

local ChatService = require(modulesFolder:WaitForChild("ChatService"))

local useEvents = {}

local EventFolder = EventFolderParent:FindFirstChild(EventFolderName)
if (not EventFolder) then
	EventFolder = Instance.new("Folder")
	EventFolder.Name = EventFolderName
	EventFolder.Archivable = false
	EventFolder.Parent = EventFolderParent
end

local function GetObjectWithNameAndType(parentObject, objectName, objectType)
	for i, child in pairs(parentObject:GetChildren()) do
		if (child:IsA(objectType) and child.Name == objectName) then
			return child
		end
	end

	return nil
end

local function CreateIfDoesntExist(parentObject, objectName, objectType)
	local obj = GetObjectWithNameAndType(parentObject, objectName, objectType)
	if (not obj) then
		obj = Instance.new(objectType)
		obj.Name = objectName
		obj.Parent = parentObject
	end
	useEvents[objectName] = obj

	return obj
end

CreateIfDoesntExist(EventFolder, "OnNewMessage", "RemoteEvent")
CreateIfDoesntExist(EventFolder, "OnMessageDoneFiltering", "RemoteEvent")
CreateIfDoesntExist(EventFolder, "OnNewSystemMessage", "RemoteEvent")
CreateIfDoesntExist(EventFolder, "OnChannelJoined", "RemoteEvent")
CreateIfDoesntExist(EventFolder, "OnChannelLeft", "RemoteEvent")
CreateIfDoesntExist(EventFolder, "OnMuted", "RemoteEvent")
CreateIfDoesntExist(EventFolder, "OnUnmuted", "RemoteEvent")
CreateIfDoesntExist(EventFolder, "OnMainChannelSet", "RemoteEvent")

CreateIfDoesntExist(EventFolder, "SayMessageRequest", "RemoteEvent")
CreateIfDoesntExist(EventFolder, "GetInitDataRequest", "RemoteFunction")

EventFolder = useEvents


local function CreatePlayerSpeakerObject(playerObj)
	--// If a developer already created a speaker object with the
	--// name of a player and then a player joins and tries to
	--// take that name, we first need to remove the old speaker object
	local speaker = ChatService:GetSpeaker(playerObj.Name)
	if (speaker) then
		ChatService:RemoveSpeaker(playerObj.Name)
	end

	speaker = ChatService:InternalAddSpeakerWithPlayerObject(playerObj.Name, playerObj)

	for i, channel in pairs(ChatService:GetAutoJoinChannelList()) do
		speaker:JoinChannel(channel.Name)
	end

	speaker.ReceivedMessage:connect(function(messageObj, channel)
		EventFolder.OnNewMessage:FireClient(playerObj, messageObj, channel)
	end)

	speaker.MessageDoneFiltering:connect(function(messageObj, channel)
		EventFolder.OnMessageDoneFiltering:FireClient(playerObj, messageObj, channel)
	end)

	speaker.ReceivedSystemMessage:connect(function(messageObj, channel)
		EventFolder.OnNewSystemMessage:FireClient(playerObj, messageObj, channel)
	end)

	speaker.ChannelJoined:connect(function(channel, welcomeMessage)
		local log = nil

		local channelObject = ChatService:GetChannel(channel)
		if (channelObject) then
			log = channelObject:GetHistoryLog()
		end
		EventFolder.OnChannelJoined:FireClient(playerObj, channel, welcomeMessage, log)
	end)

	speaker.ChannelLeft:connect(function(channel)
		EventFolder.OnChannelLeft:FireClient(playerObj, channel)
	end)

	speaker.Muted:connect(function(channel, reason, length)
		EventFolder.OnMuted:FireClient(playerObj, channel, reason, length)
	end)

	speaker.Unmuted:connect(function(channel)
		EventFolder.OnUnmuted:FireClient(playerObj, channel)
	end)

	speaker.MainChannelSet:connect(function(channel)
		EventFolder.OnMainChannelSet:FireClient(playerObj, channel)
	end)
end

EventFolder.SayMessageRequest.OnServerEvent:connect(function(playerObj, message, channel)
	local speaker = ChatService:GetSpeaker(playerObj.Name)
	if (speaker) then
		return speaker:SayMessage(message, channel)
	end

	return nil
end)

EventFolder.GetInitDataRequest.OnServerInvoke = (function(playerObj)
	local speaker = ChatService:GetSpeaker(playerObj.Name)
	if not (speaker and speaker:GetPlayer()) then
		CreatePlayerSpeakerObject(playerObj)
		speaker = ChatService:GetSpeaker(playerObj.Name)
	end

	local data = {}
	data.Channels = {}
	data.SpeakerExtraData = {}

	for i, channelName in pairs(speaker:GetChannelList()) do
		local channelObj = ChatService:GetChannel(channelName)
		if (channelObj) then
			local channelData =
			{
				channelName,
				channelObj.WelcomeMessage,
				channelObj:GetHistoryLog(),
			}

			table.insert(data.Channels, channelData)
		end
	end

	for i, oSpeakerName in pairs(ChatService:GetSpeakerList()) do
		local oSpeaker = ChatService:GetSpeaker(oSpeakerName)
		data.SpeakerExtraData[oSpeakerName] = oSpeaker.ExtraData
	end

	return data
end)

local function DoJoinCommand(speakerName, channelName, fromChannelName)
	local speaker = ChatService:GetSpeaker(speakerName)
	local channel = ChatService:GetChannel(channelName)

	if (speaker) then
		if (channel) then
			if (channel.Joinable) then
				if (not speaker:IsInChannel(channel.Name)) then
					speaker:JoinChannel(channel.Name)
				end
			else
				speaker:SendSystemMessage("You cannot join channel '" .. channelName .. "'.", fromChannelName)
			end
		else
			speaker:SendSystemMessage("Channel '" .. channelName .. "' does not exist.", fromChannelName)
		end
	end
end

local function DoLeaveCommand(speakerName, channelName, fromChannelName)
	local speaker = ChatService:GetSpeaker(speakerName)
	local channel = ChatService:GetChannel(channelName)

	if (speaker) then
		if (speaker:IsInChannel(channelName)) then
			if (channel.Leavable) then
				speaker:LeaveChannel(channel.Name)
			else
				speaker:SendSystemMessage("You cannot leave channel '" .. channelName .. "'.", fromChannelName)
			end
		else
			speaker:SendSystemMessage("You are not in channel '" .. channelName .. "'.", fromChannelName)
		end
	end
end

ChatService:RegisterProcessCommandsFunction("default_commands", function(fromSpeaker, message, channel)
	if (string.sub(message, 1, 6):lower() == "/join ") then
		DoJoinCommand(fromSpeaker, string.sub(message, 7), channel)
		return true
	elseif (string.sub(message, 1, 3):lower() == "/j ") then
		DoJoinCommand(fromSpeaker, string.sub(message, 4), channel)
		return true

	elseif (string.sub(message, 1, 7):lower() == "/leave ") then
		DoLeaveCommand(fromSpeaker, string.sub(message, 8), channel)
		return true
	elseif (string.sub(message, 1, 3):lower() == "/l ") then
		DoLeaveCommand(fromSpeaker, string.sub(message, 4), channel)
		return true

	elseif (string.sub(message, 1, 3) == "/e " or string.sub(message, 1, 7) == "/emote ") then
		-- Just don't show these in the chatlog. The animation script listens on these.
		return true

	end

	return false
end)


local allChannel = ChatService:AddChannel("All")
local systemChannel = ChatService:AddChannel("System")

allChannel.Leavable = false
allChannel.AutoJoin = true

systemChannel.Leavable = false
systemChannel.AutoJoin = true
systemChannel.WelcomeMessage = "This channel is for system and game notifications."

systemChannel.SpeakerJoined:connect(function(speakerName)
	systemChannel:MuteSpeaker(speakerName)
end)


local function TryRunModule(module)
	if module:IsA("ModuleScript") then
		local ret = require(module)
		if (type(ret) == "function") then
			ret(ChatService)
		end
	end
end

local modules = game:GetService("Chat"):WaitForChild("ChatModules")
modules.ChildAdded:connect(function(child)
	local success, returnval = pcall(TryRunModule, child)
	if not success and returnval then
		print("Error running module " ..child.Name.. ": " ..returnval)
	end
end)

for i, module in pairs(modules:GetChildren()) do
	local success, returnval = pcall(TryRunModule, module)
	if not success and returnval then
		print("Error running module " ..module.Name.. ": " ..returnval)
	end
end

local Players = game:GetService("Players")
Players.PlayerRemoving:connect(function(playerObj)
	if (ChatService:GetSpeaker(playerObj.Name)) then
		ChatService:RemoveSpeaker(playerObj.Name)
	end
end)
