-- This script is responsible for loading in all build tools for build mode

-- Script Globals
local buildTools = {}
local currentTools = {}

local BaseUrl = game:GetService("ContentProvider").BaseUrl:lower()

if BaseUrl:find("www.roblox.com") or BaseUrl:find("gametest1") then
    DeleteToolID = 73089190
    PartSelectionID = 73089166
    CloneToolID = 73089204
    RotateToolID = 73089214
    ConfigToolID = 73089239
    WiringToolID = 73089259
    classicToolID = 58921588
elseif BaseUrl:find("gametest2") then
    DeleteToolID = 70353317
    PartSelectionID = 70353315
    CloneToolID = 70353314
    RotateToolID = 70353318
    ConfigToolID = 70353319
    WiringToolID = 70353320
    classicToolID = 58921588
end

local player = nil
local backpack = nil

-- Basic Functions
local function waitForProperty(instance, name)
	while not instance[name] do
		instance.Changed:wait()
	end
end

local function waitForChild(instance, name)
	while not instance:FindFirstChild(name) do
		instance.ChildAdded:wait()
	end
end

waitForProperty(game:GetService("Players"),"LocalPlayer")
waitForProperty(game:GetService("Players").LocalPlayer,"userId")

-- we aren't in a true build mode session, don't give build tools and delete this script
if game:GetService("Players").LocalPlayer.userId < 1 then
	script:Destroy()
	return -- this is probably not necessesary, doing it just in case
end

-- Functions
function getLatestPlayer()
	waitForProperty(game:GetService("Players"),"LocalPlayer")
	player = game:GetService("Players").LocalPlayer
	waitForChild(player,"Backpack")
	backpack = player.Backpack
end

function waitForCharacterLoad()

	local startTick = tick()
	
	local playerLoaded = false
	
	local success = pcall(function() playerLoaded = player.AppearanceDidLoad end) --TODO: remove pcall once this in client on prod
	if not success then return false end
	
	while not playerLoaded do
		player.Changed:wait()
		playerLoaded = player.AppearanceDidLoad
	end
	
	return true
end

function showBuildToolsTutorial()
	local tutorialKey = "BuildToolsTutorial"
	if UserSettings().GameSettings:GetTutorialState(tutorialKey) == true then return end --already have shown tutorial
	
	local RbxGui = LoadLibrary("RbxGui")

	local frame, showTutorial, dismissTutorial, gotoPage = RbxGui.CreateTutorial("Build", tutorialKey, false)
	local firstPage = RbxGui.CreateImageTutorialPage(" ", "http://www.roblox.com/asset/?id=59162193", 359, 296, function() dismissTutorial() end, true)

	RbxGui.AddTutorialPage(frame, firstPage)
	frame.Parent = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
	
	game:GetService("GuiService"):AddCenterDialog(frame, Enum.CenterDialogType.UnsolicitedDialog,
		--showFunction
		function()
			frame.Visible = true
			showTutorial()
		end,
		--hideFunction
		function()
			frame.Visible = false
		end
	) 
	
	wait(1)
	showTutorial()
end

function clearLoadout()
	currentTools = {}

	local backpackChildren = game:GetService("Players").LocalPlayer.Backpack:GetChildren()
	for i = 1, #backpackChildren do
		if backpackChildren[i]:IsA("Tool") or backpackChildren[i]:IsA("HopperBin") then
			table.insert(currentTools,backpackChildren[i])
		end
	end
	
	if game:GetService("Players").LocalPlayer["Character"] then
		local characterChildren = game:GetService("Players").LocalPlayer.Character:GetChildren()
		for i = 1, #characterChildren do
			if characterChildren[i]:IsA("Tool") or characterChildren[i]:IsA("HopperBin") then
				table.insert(currentTools,characterChildren[i])
			end
		end
	end
	
	for i = 1, #currentTools do
		currentTools[i].Parent = nil
	end
end

function giveToolsBack()
	for i = 1, #currentTools do
		currentTools[i].Parent = game:GetService("Players").LocalPlayer.Backpack
	end
end

function backpackHasTool(tool)
	local backpackChildren = backpack:GetChildren()
	for i = 1, #backpackChildren do
		if backpackChildren[i] == tool then
			return true
		end
	end
	return false
end

function getToolAssetID(assetID)
	local newTool = game:GetService("InsertService"):LoadAsset(assetID)
	local toolChildren = newTool:GetChildren()
	for i = 1, #toolChildren do
		if toolChildren[i]:IsA("Tool") then
			return toolChildren[i]
		end
	end
	return nil
end

-- remove legacy identifiers
-- todo: determine if we still need this
function removeBuildToolTag(tool)
	if tool:FindFirstChild("RobloxBuildTool") then
		tool.RobloxBuildTool:Destroy()
	end
end

function giveAssetId(assetID,toolName)
	local theTool = getToolAssetID(assetID,toolName)
	if theTool and not backpackHasTool(theTool) then
		removeBuildToolTag(theTool)
		theTool.Parent = backpack
		table.insert(buildTools,theTool)
	end
end

function loadBuildTools()
	giveAssetId(PartSelectionID)
	giveAssetId(DeleteToolID)
	giveAssetId(CloneToolID)
	giveAssetId(RotateToolID)
	giveAssetId(WiringToolID)
	giveAssetId(ConfigToolID)
	
	-- deprecated tools
	giveAssetId(classicToolID)
end

function givePlayerBuildTools()
	getLatestPlayer()

	clearLoadout()

	loadBuildTools()
	
	giveToolsBack()
end

function takePlayerBuildTools()
	for k,v in ipairs(buildTools) do
		v.Parent = nil
	end
	buildTools = {}
end


-- Script start
getLatestPlayer()
waitForCharacterLoad()
givePlayerBuildTools()

-- If player dies, we make sure to give them build tools again
player.CharacterAdded:connect(function()
	takePlayerBuildTools()
	givePlayerBuildTools()
end)

showBuildToolsTutorial()
