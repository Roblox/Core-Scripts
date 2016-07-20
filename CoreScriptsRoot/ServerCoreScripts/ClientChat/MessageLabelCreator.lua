local source = [[
local SpeakerDatabase = nil


local baseLabel = Instance.new("TextLabel")
baseLabel.Name = "MessageLabel"
baseLabel.TextColor3 = Color3.new(1, 1, 1)
baseLabel.BackgroundTransparency = 1
baseLabel.Size = UDim2.new(1, -16, 0, 0)
baseLabel.Font = Enum.Font.SourceSansBold
baseLabel.FontSize = Enum.FontSize.Size18
baseLabel.TextStrokeTransparency =  0.75
baseLabel.TextXAlignment = "Left"
baseLabel.TextYAlignment = "Top"
baseLabel.TextWrapped = true
baseLabel.TextStrokeColor3 = Color3.new(34/255,34/255,34/255)


local module = {}

function module:RegisterSpeakerDatabase(vSpeakerDatabase)
	SpeakerDatabase = vSpeakerDatabase
end

function module:CreateMessageLabel(fromSpeaker, message)
	local label = baseLabel:Clone()
	
	if (string.sub(message, 1, 4) == "/me ") then
		label.Text = fromSpeaker .. " " .. string.sub(message, 5)
		return label
	end
	
	local nameLabel = label:Clone()
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.Parent = label
	nameLabel.Text = ""
	
	local speaker = SpeakerDatabase:GetSpeaker(fromSpeaker)
	if (speaker ~= nil) then
		local tagsPrefix = ""
		local tagLabels = {}
		
		local tags = speaker.Tags or {}
		
		for tagId, tagData in pairs(tags) do
			tagsPrefix = tagsPrefix .. "[" .. tagData.Name .. "] "
			
			local tagLabel = nameLabel:Clone()
			tagLabel.Name = "TagLabel"
			tagLabel.Text = tagsPrefix
			tagLabel.TextColor3 = tagData.Color
			
			table.insert(tagLabels, 1, tagLabel)
		end
		
		for i, tag in pairs(tagLabels) do
			tag.Parent = label
		end
		
		nameLabel.Text = tagsPrefix		
		nameLabel.TextColor3 = speaker.NameColor or Color3.new(1, 1, 1)
		label.TextColor3 = speaker.ChatColor or Color3.new(1, 1, 1)

	end
	
	nameLabel.Text = nameLabel.Text .. "["..fromSpeaker.."]: "
	label.Text = nameLabel.Text .. message
	
	if (string.sub(message, 1, 1) == ">") then
		label.TextColor3 = Color3.new(120/255, 153/255, 34/255)
	end

	return label	
end

function module:CreateSystemMessageLabel(message)
	local label = baseLabel:Clone()
	label.Text = message
	
	return label
end

function module:CreateWelcomeMessageLabel(message)
	local label = baseLabel:Clone()
	label.Text = message
	--label.TextColor3 = Color3.new(1, 1, 0.35)
	
	return label
end

return module

]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script