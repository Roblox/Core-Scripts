--build our gui

local popupFrame = Instance.new("Frame")
popupFrame.Position = UDim2.new(0.5,-165,0.5,-175)
popupFrame.Size = UDim2.new(0,330,0,350)
popupFrame.Style = Enum.FrameStyle.RobloxRound
popupFrame.ZIndex = 4
popupFrame.Name = "Popup"
popupFrame.Visible = false
popupFrame.Parent = script.Parent

local darken = popupFrame:clone()
darken.Size = UDim2.new(1,16,1,16)
darken.Position = UDim2.new(0,-8,0,-8)
darken.Name = "Darken"
darken.ZIndex = 1
darken.Parent = popupFrame

local acceptButton = Instance.new("TextButton")
acceptButton.Position = UDim2.new(0,20,0,270)
acceptButton.Size = UDim2.new(0,100,0,50)
acceptButton.Font = Enum.Font.ArialBold
acceptButton.FontSize = Enum.FontSize.Size24
acceptButton.Style = Enum.ButtonStyle.RobloxButton
acceptButton.TextColor3 = Color3.new(248/255,248/255,248/255)
acceptButton.Text = "Yes"
acceptButton.ZIndex = 5
acceptButton.Name = "AcceptButton"
acceptButton.Parent = popupFrame

local declineButton = acceptButton:clone()
declineButton.Position = UDim2.new(1,-120,0,270)
declineButton.Text = "No"
declineButton.Name = "DeclineButton"
declineButton.Parent = popupFrame

local okButton = acceptButton:clone()
okButton.Name = "OKButton"
okButton.Text = "OK"
okButton.Position = UDim2.new(0.5,-50,0,270)
okButton.Visible = false
okButton.Parent = popupFrame

local popupImage = Instance.new("ImageLabel")
popupImage.BackgroundTransparency = 1
popupImage.Position = UDim2.new(0.5,-140,0,0)
popupImage.Size = UDim2.new(0,280,0,280)
popupImage.ZIndex = 3
popupImage.Name = "PopupImage"
popupImage.Parent = popupFrame

local backing = Instance.new("ImageLabel")
backing.BackgroundTransparency = 1
backing.Size = UDim2.new(1,0,1,0)
backing.Image = "http://www.roblox.com/asset/?id=47574181"
backing.Name = "Backing"
backing.ZIndex = 2
backing.Parent = popupImage

local popupText = Instance.new("TextLabel")
popupText.Name = "PopupText"
popupText.Size = UDim2.new(1,0,0.8,0)
popupText.Font = Enum.Font.ArialBold
popupText.FontSize = Enum.FontSize.Size36
popupText.BackgroundTransparency = 1
popupText.Text = "Hello I'm a popup"
popupText.TextColor3 = Color3.new(248/255,248/255,248/255)
popupText.TextWrap = true
popupText.ZIndex = 5
popupText.Parent = popupFrame

script:remove()