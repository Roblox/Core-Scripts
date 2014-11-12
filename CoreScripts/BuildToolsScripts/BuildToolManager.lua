-- Responsible for giving out tools in personal servers

-- first, lets see if buildTools have already been created
-- create the object in ReplicatedStorage if not
local container = Game:GetService("ReplicatedStorage")
local toolsArray = container:FindFirstChild("BuildToolsModel")
local ownerArray = container:FindFirstChild("OwnerToolsModel")
local hasBuildTools = false

local function waitForProperty(instance, name)
	while not instance[name] do
		instance.Changed:wait()
	end
end

waitForProperty(Game:GetService("Players"),"LocalPlayer")
waitForProperty(Game:GetService("Players").LocalPlayer,"userId")

local player = Game:GetService("Players").LocalPlayer
if not player then 
	script:Destroy()
	return 
end

function getIds(idTable, assetTable)
	for i = 1, #idTable do
		local model = Game:GetService("InsertService"):LoadAsset(idTable[i])
		if model then
			local children = model:GetChildren()
			for i = 1, #children do
				if children[i]:IsA("Tool") then
					table.insert(assetTable,children[i])
				end
			end
		end
	end
end

function storeInContainer(modelName, assetTable)
	local model = Instance.new("Model")
	model.Archivable = false
	model.Name = modelName
	
	for i = 1, #assetTable do
		assetTable[i].Parent = model
	end
	
	if not container:FindFirstChild(modelName) then -- no one beat us to it, we get to insert
		model.Parent = container
	end
end

if not toolsArray then -- no one has made build tools yet, we get to!
	local buildToolIds = {}
	local ownerToolIds = {}

	local BaseUrl = game:GetService("ContentProvider").BaseUrl:lower()

	if BaseUrl:find("www.roblox.com") or BaseUrl:find("gametest1") then
		table.insert(buildToolIds,73089166) -- PartSelectionTool
		table.insert(buildToolIds,73089190) -- DeleteTool
		table.insert(buildToolIds,73089204) -- CloneTool
		table.insert(buildToolIds,73089214) -- RotateTool
		table.insert(buildToolIds,73089229) -- RecentPartTool
		table.insert(buildToolIds,73089239) -- ConfigTool
		table.insert(buildToolIds,73089259) -- WiringTool
	elseif BaseUrl:find("gametest2") then
		table.insert(buildToolIds,70353315) -- PartSelectionTool
		table.insert(buildToolIds,70353317) -- DeleteTool
		table.insert(buildToolIds,70353314) -- CloneTool
		table.insert(buildToolIds,70353318) -- RotateTool
		table.insert(buildToolIds,70353316) -- RecentPartTool
		table.insert(buildToolIds,70353319) -- ConfigTool
		table.insert(buildToolIds,70353320) -- WiringTool
	end
	
	table.insert(buildToolIds,58921588) -- ClassicTool
	table.insert(ownerToolIds, 65347268) -- OwnerCameraTool

	-- next, create array of our tools
	local buildTools = {}
	local ownerTools = {}
	
	getIds(buildToolIds, buildTools)
	getIds(ownerToolIds, ownerTools)
	
	storeInContainer("BuildToolsModel",buildTools)
	storeInContainer("OwnerToolsModel",ownerTools)
	
	toolsArray = container:FindFirstChild("BuildToolsModel")
	ownerArray = container:FindFirstChild("OwnerToolsModel")
end

local localBuildTools = {}

function giveBuildTools()
	if not hasBuildTools then
		hasBuildTools = true
		local theTools = toolsArray:GetChildren()
		for i = 1, #theTools do
			local toolClone = theTools[i]:clone()
			if toolClone then
				toolClone.Parent = player:findFirstChild("Backpack")
				table.insert(localBuildTools,toolClone)
			end
		end
	end
end

function giveOwnerTools()
	local theOwnerTools = ownerArray:GetChildren()
	for i = 1, #theOwnerTools do
		local ownerToolClone = theOwnerTools[i]:clone()
		if ownerToolClone then
			ownerToolClone.Parent = player:findFirstChild("Backpack")
			table.insert(localBuildTools,ownerToolClone)
		end
	end
end

function removeBuildTools()
	if not hasBuildTools then return end
	hasBuildTools = false
	for k,v in pairs(localBuildTools) do
		v:Destroy()
	end localBuildTools = {}
end

if player.HasBuildTools then
	giveBuildTools()
end
if player.PersonalServerRank >= 255 then
	giveOwnerTools()
end

local debounce = false
player.Changed:connect(function(prop)
	if prop == "HasBuildTools" then
		while debounce do
			wait(0.5)
		end
		
		debounce = true
		
		if player.HasBuildTools then
			giveBuildTools()
		else
			removeBuildTools()
		end
		
		if player.PersonalServerRank >= 255 then
			giveOwnerTools()
		end
		
		debounce = false
	elseif prop == "PersonalServerRank" then
		if player.PersonalServerRank >= 255 then
			giveOwnerTools()
		elseif player.PersonalServerRank <= 0 then
			player:Kick() -- you're banned, goodbye!
			Game:SetMessage("You're banned from this PBS")
		end
	end
end)

player.CharacterAdded:connect(function()
	hasBuildTools = false
	if player.HasBuildTools then
		giveBuildTools()
	end
	if player.PersonalServerRank >= 255 then
		giveOwnerTools()
	end
end)
