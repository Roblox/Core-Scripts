--[[
		// Filename: PurchasePromptScript3.lua
		// Version 2.0
		// Release 253
		// Written by: jeditkacheff/jmargh/0xBAADF00D
		// Description: Handles in game purchases

		// Note: Converted for VR by 0xBAADF00D 6/30/16
]]--
--Enable this script only if FFlagVRPurchasePromptsEnabled = True
local vrPurchasePromptsEnabledSuccess, vrPurchasePromptsEnabled = pcall(function() return settings():GetFFlag("VRPurchasePromptsEnabled") end)
vrPurchasePromptsEnabled = vrPurchasePromptsEnabled and vrPurchasePromptsEnabledSuccess
if not vrPurchasePromptsEnabled then
	return
end

--[[ Services ]]--
local GuiService = game:GetService('GuiService')
local HttpService = game:GetService('HttpService')
local HttpRbxApiService = game:GetService('HttpRbxApiService')
local InsertService = game:GetService('InsertService')
local MarketplaceService = game:GetService('MarketplaceService')
local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService("RunService")

--[[ Script Variables ]]--
local RobloxGui = script.Parent
local ThirdPartyProductName = nil

--[[ Flags ]]--
local platform = UserInputService:GetPlatform()
local IsNativePurchasing = platform == Enum.Platform.XBoxOne or 
							platform == Enum.Platform.IOS or 
							platform == Enum.Platform.Android or
							platform == Enum.Platform.UWP

local IsCurrentlyPrompting = false
local IsCurrentlyPurchasing = false
local IsPurchasingConsumable = false
local IsCheckingPlayerFunds = false
RobloxGui:WaitForChild("Modules"):WaitForChild("TenFootInterface")
local TenFootInterface = require(RobloxGui.Modules.TenFootInterface)
local isTenFootInterface = TenFootInterface:IsEnabled()
local IsVRMode = false
local freezeControllerActionName = "doNothingActionPrompt"
local freezeThumbstick1Name = "doNothingThumbstickPrompt"
local freezeThumbstick2Name = "doNothingThumbstickPrompt"
local _,largeFont = pcall(function() return Enum.FontSize.Size42 end)
largeFont = largeFont or Enum.FontSize.Size36
local scaleFactor = 3
local purchaseState = nil

--[[ Purchase Data ]]--
local PurchaseData = {
	AssetId = nil,
	ProductId = nil,
	CurrencyType = nil,
	EquipOnPurchase = nil,
	ProductInfo = nil,
	ItemDescription = nil,
}

--[[ Constants ]]--
local BASE_URL = game:GetService('ContentProvider').BaseUrl:lower()
BASE_URL = string.gsub(BASE_URL, "/m.", "/www.")
local THUMBNAIL_URL = BASE_URL.."thumbs/asset.ashx?assetid="
-- Images
local BG_IMAGE = 'rbxasset://textures/ui/Modal.png'
local PURCHASE_BG = 'rbxasset://textures/ui/LoadingBKG.png'
local BUTTON_LEFT = 'rbxasset://textures/ui/ButtonLeft.png'
local BUTTON_LEFT_DOWN = 'rbxasset://textures/ui/ButtonLeftDown.png'
local BUTTON_RIGHT = 'rbxasset://textures/ui/ButtonRight.png'
local BUTTON_RIGHT_DOWN = 'rbxasset://textures/ui/ButtonRightDown.png'
local BUTTON = 'rbxasset://textures/ui/SingleButton.png'
local BUTTON_DOWN = 'rbxasset://textures/ui/SingleButtonDown.png'
local ROBUX_ICON = 'rbxasset://textures/ui/RobuxIcon.png'
local TIX_ICON = 'rbxasset://textures/ui/TixIcon.png'
local ERROR_ICON = 'rbxasset://textures/ui/ErrorIcon.png'
local A_BUTTON = "rbxasset://textures/ui/Settings/Help/AButtonDark.png"
local B_BUTTON = "rbxasset://textures/ui/Settings/Help/BButtonDark.png"
local DEFAULT_XBOX_IMAGE = 'rbxasset://textures/ui/Shell/Icons/ROBUXIcon@1080.png'
local VR_BUTTON = 'rbxasset://textures/ui/VR/button.png'
local VR_BUTTON_DOWN = 'rbxasset://textures/ui/VR/buttonSelected.png'
local emptySelectionImage = Instance.new("ImageLabel")
emptySelectionImage.Name = "EmptySelectionImage"
emptySelectionImage.Visible = false
--Context Actions
local CONTROLLER_CONFIRM_ACTION_NAME = "CoreScriptPurchasePromptControllerConfirm"
local CONTROLLER_CANCEL_ACTION_NAME = "CoreScriptPurchasePromptControllerCancel"
local GAMEPAD_BUTTONS = {}

local ERROR_MSG = {
	PURCHASE_DISABLED = "In-game purchases are temporarily disabled",
	INVALID_FUNDS = "your account does not have enough ROBUX",
	UNKNOWN = "ROBLOX is performing maintenance",
	UNKNWON_FAILURE = "something went wrong"
}
local PURCHASE_MSG = {
	SUCCEEDED = "Your purchase of itemName succeeded!",
	FAILED = "Your purchase of itemName failed because errorReason. Your account has not been charged. Please try again later.",
	PURCHASE = "Want to buy the assetType\nitemName for",
	PURCHASE_TIX = "Want to buy the assetType\nitemName for",
	FREE = "Would you like to take the assetType itemName for FREE?",
	FREE_BALANCE = "Your account balance will not be affected by this transaction.",
	BALANCE_FUTURE = "Your balance after this transaction will be ",
	BALANCE_NOW = "Your balance is now ",
	ALREADY_OWN = "You already own this item. Your account has not been charged.",
	MOCK_PURCHASE = "This is a test purchase; your account will not be charged.",
	MOCK_PURCHASE_SUCCESS = "This was a test purchase."
}
local PURCHASE_FAILED = {
	DEFAULT_ERROR = 0,
	IN_GAME_PURCHASE_DISABLED = 1,
	CANNOT_GET_BALANCE = 2,
	CANNOT_GET_ITEM_PRICE = 3,
	NOT_FOR_SALE = 4,
	NOT_ENOUGH_TIX = 5,
	UNDER_13 = 6,
	LIMITED = 7,
	DID_NOT_BUY_ROBUX = 8,
	PROMPT_PURCHASE_ON_GUEST = 9,
	THIRD_PARTY_DISABLED = 10,
}
local PURCHASE_STATE = {
	DEFAULT = 1,
	FAILED = 2,
	SUCCEEDED = 3,
	BUYITEM = 4,
	BUYROBUX = 5,
	BUYINGROBUX = 6,
	BUYBC = 7
}

local function studioMockPurchasesEnabled()
	local result = false
	pcall(function() result = settings():GetFFlag("StudioMockPurchasesEnabled") and settings():GetFFlag("StudioUseMarketplaceApiClient") and game:GetService("RunService"):IsStudio() end)
	return result
end

local function useNewMarketplaceMethods()
	if game:GetService("RunService"):IsStudio() then
		flagExists, flagValue = pcall(function() return settings():GetFFlag("StudioUseMarketplaceApiClient") end)
	else
		flagExists, flagValue = pcall(function() return settings():GetFFlag("RCCUseMarketplaceApiClient") end)
	end
	return flagExists and flagValue
end

local BC_LVL_TO_STRING = {
	"Builders Club",
	"Turbo Builders Club",
	"Outrageous Builders Club",
}
local ASSET_TO_STRING = {
	[1]  = "Image";
	[2]  = "T-Shirt";
	[3]  = "Audio";
	[4]  = "Mesh";
	[5]  = "Lua";
	[6]  = "HTML";
	[7]  = "Text";
	[8]  = "Hat";
	[9]  = "Place";
	[10] = "Model";
	[11] = "Shirt";
	[12] = "Pants";
	[13] = "Decal";
	[16] = "Avatar";
	[17] = "Head";
	[18] = "Face";
	[19] = "Gear";
	[21] = "Badge";
	[22] = "Group Emblem";
	[24] = "Animation";
	[25] = "Arms";
	[26] = "Legs";
	[27] = "Torso";
	[28] = "Right Arm";
	[29] = "Left Arm";
	[30] = "Left Leg";
	[31] = "Right Leg";
	[32] = "Package";
	[33] = "YouTube Video";
	-- NOTE: GamePass and Plugin AssetTypeIds are different on ST1, ST2 and ST3
	[34] = "Game Pass";	
	[38] = "Plugin";
	[0]  = "Product";
}
local BC_ROBUX_PRODUCTS = { 90, 180, 270, 360, 450, 1000, 2750 }
local NON_BC_ROBUX_PRODUCTS = { 80, 160, 240, 320, 400, 800, 2000 }

local DIALOG_SIZE = UDim2.new(0, 324, 0, 180)
local DIALOG_SIZE_TENFOOT = UDim2.new(0, 324*scaleFactor, 0, 180*scaleFactor)
local SHOW_POSITION = UDim2.new(0.5, -162, 0.5, -90)
local SHOW_POSITION_TENFOOT = UDim2.new(0.5, -162*scaleFactor, 0.5, -90*scaleFactor)
local HIDE_POSITION = UDim2.new(0.5, -162, 0, -181)
local HIDE_POSITION_TENFOOT = UDim2.new(0.5, -162*scaleFactor, 0, -180*scaleFactor - 1)
local BTN_SIZE = UDim2.new(0, 162, 0, 44)
local BTN_SIZE_TENFOOT = UDim2.new(0, 162*scaleFactor, 0, 44*scaleFactor)
local BTN_SIZE_VR = UDim2.new(0.5, -20, 0, 75)
local BODY_SIZE = UDim2.new(0, 324, 0, 136)
local BODY_SIZE_TENFOOT = UDim2.new(0, 324*scaleFactor, 0, 136*scaleFactor)
local TWEEN_TIME = 0.3

local BTN_L_POS = UDim2.new(0, 0, 0, 136)
local BTN_L_POS_TENFOOT = UDim2.new(0, 0, 0, 136*scaleFactor)
local BTN_L_POS_VR = UDim2.new(0, 10, 0, 225)
local BTN_R_POS = UDim2.new(0.5, 0, 0, 136)
local BTN_R_POS_TENFOOT = UDim2.new(0.5, 0, 0, 136*scaleFactor)
local BTN_R_POS_VR = UDim2.new(0.5, 10, 0, 225)
local BTN_M_POS_VR = UDim2.new(0.25, 0, 0, 225)

--[[ Utility Functions ]]--
local function lerp( start, finish, t)
	return (1 - t) * start + t * finish
end

local function formatNumber(value)
	return tostring(value):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

--[[ Gui Creation Functions ]]--
local function createFrame(name, size, position, bgTransparency, bgColor)
	local frame = Instance.new('Frame')
	frame.Name = name
	frame.Size = size
	frame.Position = position or UDim2.new(0, 0, 0, 0)
	frame.BackgroundTransparency = bgTransparency
	frame.BackgroundColor3 = bgColor or Color3.new()
	frame.BorderSizePixel = 0
	frame.ZIndex = 8

	return frame
end

local function createFrame3D(name, size, position, bgTransparency, bgColor)
	local frame = Instance.new("ImageLabel")
	frame.Name = name
	frame.Size = size + UDim2.new(0, 2, 0, 2)
	frame.Position = (position + UDim2.new(0, -1, 0, -1)) or UDim2.new(0, -1, 0, -1)
	frame.BackgroundTransparency = 1
	frame.ImageColor3 = bgColor or Color3.new()
	frame.ImageTransparency = bgTransparency
	frame.Image = "rbxasset://textures/ui/VR/rectBackgroundWhite.png"
	frame.ScaleType = Enum.ScaleType.Slice
	frame.SliceCenter = Rect.new(9, 9, 11, 11)
	frame.ZIndex = 8

	return frame
end

local function createTextLabel(name, size, position, font, fontSize, text)
	local textLabel = Instance.new('TextLabel')
	textLabel.Name = name
	textLabel.Size = size or UDim2.new(0, 0, 0, 0)
	textLabel.Position = position
	textLabel.BackgroundTransparency = 1
	textLabel.Font = font
	textLabel.FontSize = fontSize
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.Text = text
	textLabel.ZIndex = 8

	return textLabel
end

local function createImageLabel(name, size, position, image)
	local imageLabel = Instance.new('ImageLabel')
	imageLabel.Name = name
	imageLabel.Size = size
	imageLabel.BackgroundTransparency = 1
	imageLabel.Position = position
	imageLabel.Image = image

	return imageLabel
end

local function createImageButtonWithText(name, position, image, imageDown, text, font, fontSize)
	local imageButton = Instance.new('ImageButton')
	imageButton.Name = name
	imageButton.Size = isTenFootInterface and BTN_SIZE_TENFOOT or BTN_SIZE
	imageButton.Position = position
	imageButton.Image = image
	imageButton.BackgroundTransparency = 1
	imageButton.AutoButtonColor = false
	imageButton.ZIndex = 8
	imageButton.Modal = true

	if not fontSize then
		fontSize = isTenFootInterface and largeFont or Enum.FontSize.Size24
	end
	local textLabel = createTextLabel(name.."Text", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), font, fontSize, text)
	textLabel.ZIndex = 9
	textLabel.Parent = imageButton

	imageButton.MouseEnter:connect(function()
		imageButton.Image = imageDown
	end)
	imageButton.MouseLeave:connect(function()
		imageButton.Image = image
	end)
	imageButton.MouseButton1Click:connect(function()
		imageButton.Image = image
	end)

	return imageButton
end

local function createImageButtonWithText3D(name, position, image, imageDown, text, font, fontSize)
	local imageButton = createImageButtonWithText(name, position, image, imageDown, text, font, fontSize)
	imageButton.Size = BTN_SIZE_VR
	imageButton.SelectionGained:connect(function()
		imageButton.Image = imageDown
	end)
	imageButton.SelectionLost:connect(function()
		imageButton.Image = image
	end)
	imageButton.SelectionImageObject = emptySelectionImage
	return imageButton
end

--[[ Begin Gui Creation ]]--
local function create2DGui()
	local Gui = {}
	Gui.PurchaseDialog = isTenFootInterface and createFrame("PurchaseDialog", DIALOG_SIZE_TENFOOT, HIDE_POSITION_TENFOOT, 1, nil) or createFrame("PurchaseDialog", DIALOG_SIZE, HIDE_POSITION, 1, nil)
	Gui.PurchaseDialog.Visible = false
	Gui.PurchaseDialog.Parent = RobloxGui

		Gui.ContainerFrame = createFrame("ContainerFrame", UDim2.new(1, 0, 1, 0), nil, 1, nil)
		Gui.ContainerFrame.Parent = Gui.PurchaseDialog

			Gui.ContainerImage = createImageLabel("ContainerImage", isTenFootInterface and BODY_SIZE_TENFOOT or BODY_SIZE, UDim2.new(0, 0, 0, 0), BG_IMAGE)
			Gui.ContainerImage.ZIndex = 8
			Gui.ContainerImage.Parent = Gui.ContainerFrame

			Gui.ItemPreviewImage = isTenFootInterface and createImageLabel("ItemPreviewImage", UDim2.new(0, 64*scaleFactor, 0, 64*scaleFactor), UDim2.new(0, 27*scaleFactor, 0, 20*scaleFactor), "") or createImageLabel("ItemPreviewImage", UDim2.new(0, 64, 0, 64), UDim2.new(0, 27, 0, 20), "")
			Gui.ItemPreviewImage.ZIndex = 9
			Gui.ItemPreviewImage.Parent = Gui.ContainerFrame

			Gui.ItemDescriptionText = createTextLabel("ItemDescriptionText", isTenFootInterface and UDim2.new(0, 210*scaleFactor - 20, 0, 96*scaleFactor) or UDim2.new(0, 210, 0, 96), isTenFootInterface and UDim2.new(0, 110*scaleFactor, 0, 18*scaleFactor) or UDim2.new(0, 110, 0, 18),
				Enum.Font.SourceSans, isTenFootInterface and Enum.FontSize.Size48 or Enum.FontSize.Size18, PURCHASE_MSG.PURCHASE)
			Gui.ItemDescriptionText.TextXAlignment = Enum.TextXAlignment.Left
			Gui.ItemDescriptionText.TextYAlignment = Enum.TextYAlignment.Top
			Gui.ItemDescriptionText.TextWrapped = true
			Gui.ItemDescriptionText.Parent = Gui.ContainerFrame

			Gui.RobuxIcon = createImageLabel("RobuxIcon", isTenFootInterface and UDim2.new(0, 20*scaleFactor, 0, 20*scaleFactor) or UDim2.new(0, 20, 0, 20), UDim2.new(0, 0, 0, 0), ROBUX_ICON)
			Gui.RobuxIcon.ZIndex = 9
			Gui.RobuxIcon.Visible = false
			Gui.RobuxIcon.Parent = Gui.ContainerFrame

			Gui.TixIcon = createImageLabel("TixIcon", isTenFootInterface and UDim2.new(0, 20*scaleFactor, 0, 20*scaleFactor) or UDim2.new(0, 20, 0, 20), UDim2.new(0, 0, 0, 0), TIX_ICON)
			Gui.TixIcon.ZIndex = 9
			Gui.TixIcon.Visible = false
			Gui.TixIcon.Parent = Gui.ContainerFrame

			Gui.CostText = createTextLabel("CostText", UDim2.new(0, 0, 0, 0), UDim2.new(0, 0, 0, 0),
				Enum.Font.SourceSansBold, isTenFootInterface and largeFont or Enum.FontSize.Size18, "")
			Gui.CostText.TextXAlignment = Enum.TextXAlignment.Left
			Gui.CostText.Visible = false
			Gui.CostText.Parent = Gui.ContainerFrame

			Gui.PostBalanceText = createTextLabel("PostBalanceText", UDim2.new(1, -20, 0, 30), isTenFootInterface and UDim2.new(0, 10, 0, 100*scaleFactor) or UDim2.new(0, 10, 0, 100), Enum.Font.SourceSans,
				isTenFootInterface and Enum.FontSize.Size36 or Enum.FontSize.Size14, "")
			Gui.PostBalanceText.TextWrapped = true
			Gui.PostBalanceText.Parent = Gui.ContainerFrame

			Gui.BuyButton = createImageButtonWithText("BuyButton", isTenFootInterface and BTN_L_POS_TENFOOT or BTN_L_POS, BUTTON_LEFT, BUTTON_LEFT_DOWN, "Buy Now", Enum.Font.SourceSansBold)
			Gui.BuyButton.Parent = Gui.ContainerFrame
			Gui.BuyButtonText = Gui.BuyButton:FindFirstChild("BuyButtonText")

			local gamepadButtonXLocation = (Gui.BuyButton.AbsoluteSize.X/2 - Gui.BuyButtonText.TextBounds.X/2)/2
			local buyButtonGamepadImage = Instance.new("ImageLabel")
			buyButtonGamepadImage.BackgroundTransparency = 1
			buyButtonGamepadImage.Image = A_BUTTON
			buyButtonGamepadImage.Size = UDim2.new(1, -8, 1, -8)
			buyButtonGamepadImage.SizeConstraint = Enum.SizeConstraint.RelativeYY
			buyButtonGamepadImage.Parent = Gui.BuyButton
			buyButtonGamepadImage.Position = UDim2.new(0, gamepadButtonXLocation - buyButtonGamepadImage.AbsoluteSize.X/2, 0, 5)
			buyButtonGamepadImage.Visible = false
			buyButtonGamepadImage.ZIndex = Gui.BuyButton.ZIndex
			table.insert(GAMEPAD_BUTTONS, buyButtonGamepadImage)

			Gui.CancelButton = createImageButtonWithText("CancelButton", isTenFootInterface and BTN_R_POS_TENFOOT or BTN_R_POS, BUTTON_RIGHT, BUTTON_RIGHT_DOWN, "Cancel", Enum.Font.SourceSans)
			Gui.CancelButton.Parent = Gui.ContainerFrame

			local cancelButtonGamepadImage = buyButtonGamepadImage:Clone()
			cancelButtonGamepadImage.Image = B_BUTTON
			cancelButtonGamepadImage.ZIndex = Gui.CancelButton.ZIndex
			cancelButtonGamepadImage.Parent = Gui.CancelButton
			table.insert(GAMEPAD_BUTTONS, cancelButtonGamepadImage)

			Gui.BuyRobuxButton = createImageButtonWithText("BuyRobuxButton", isTenFootInterface and BTN_L_POS_TENFOOT or BTN_L_POS, BUTTON_LEFT, BUTTON_LEFT_DOWN, IsNativePurchasing and "Buy" or "Buy R$",
				Enum.Font.SourceSansBold)
			Gui.BuyRobuxButton.Visible = false
			Gui.BuyRobuxButton.Parent = Gui.ContainerFrame

			local buyRobuxGamepadImage = buyButtonGamepadImage:Clone()
			buyRobuxGamepadImage.ZIndex = Gui.BuyRobuxButton.ZIndex
			buyRobuxGamepadImage.Parent = Gui.BuyRobuxButton
			table.insert(GAMEPAD_BUTTONS, buyRobuxGamepadImage)

			Gui.BuyBCButton = createImageButtonWithText("BuyBCButton", isTenFootInterface and BTN_L_POS_TENFOOT or BTN_L_POS, BUTTON_LEFT, BUTTON_LEFT_DOWN, "Upgrade", Enum.Font.SourceSansBold)
			Gui.BuyBCButton.Visible = false
			Gui.BuyBCButton.Parent = Gui.ContainerFrame

			local buyBCGamepadImage = buyButtonGamepadImage:Clone()
			buyBCGamepadImage.ZIndex = Gui.BuyBCButton.ZIndex
			buyBCGamepadImage.Parent = Gui.BuyBCButton
			table.insert(GAMEPAD_BUTTONS, buyBCGamepadImage)

			Gui.FreeButton = createImageButtonWithText("FreeButton", isTenFootInterface and BTN_L_POS_TENFOOT or BTN_L_POS, BUTTON_LEFT, BUTTON_LEFT_DOWN, "Take Free", Enum.Font.SourceSansBold)
			Gui.FreeButton.Visible = false
			Gui.FreeButton.Parent = Gui.ContainerFrame

			Gui.OkButton = createImageButtonWithText("OkButton", isTenFootInterface and UDim2.new(0, 2, 0, 136*scaleFactor) or UDim2.new(0, 2, 0, 136), BUTTON, BUTTON_DOWN, "OK", Enum.Font.SourceSans)
			Gui.OkButton.Size = isTenFootInterface and UDim2.new(0, 320*scaleFactor, 0, 44*scaleFactor) or UDim2.new(0, 320, 0, 44)
			Gui.OkButton.Visible = false
			Gui.OkButton.Parent = Gui.ContainerFrame

			local okButtonGamepadImage = buyButtonGamepadImage:Clone()
			okButtonGamepadImage.ZIndex = Gui.OkButton.ZIndex
			okButtonGamepadImage.Parent = Gui.OkButton
			table.insert(GAMEPAD_BUTTONS, okButtonGamepadImage)

			Gui.OkPurchasedButton = createImageButtonWithText("OkPurchasedButton", isTenFootInterface and UDim2.new(0, 2, 0, 136*scaleFactor) or UDim2.new(0, 2, 0, 136), BUTTON, BUTTON_DOWN, "OK", Enum.Font.SourceSans)
			Gui.OkPurchasedButton.Size = isTenFootInterface and UDim2.new(0, 320*scaleFactor, 0, 44*scaleFactor) or UDim2.new(0, 320, 0, 44)
			Gui.OkPurchasedButton.Visible = false
			Gui.OkPurchasedButton.Parent = Gui.ContainerFrame

			local okPurchasedGamepadImage = buyButtonGamepadImage:Clone()
			okPurchasedGamepadImage.ZIndex = Gui.OkPurchasedButton.ZIndex
			okPurchasedGamepadImage.Parent = Gui.OkPurchasedButton
			table.insert(GAMEPAD_BUTTONS, okPurchasedGamepadImage)

		Gui.PurchaseFrame = createImageLabel("PurchaseFrame", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), PURCHASE_BG)
		Gui.PurchaseFrame.ZIndex = 8
		Gui.PurchaseFrame.Visible = false
		Gui.PurchaseFrame.Parent = Gui.PurchaseDialog

			Gui.PurchaseText = createTextLabel("PurchaseText", nil, UDim2.new(0.5, 0, 0.5, -36), Enum.Font.SourceSans,
				isTenFootInterface and largeFont or Enum.FontSize.Size36, "Purchasing")
			Gui.PurchaseText.Parent = Gui.PurchaseFrame

			Gui.LoadingFrames = {}
			local xOffset = -40
			for i = 1, 3 do
				local frame = createFrame("Loading", UDim2.new(0, 16, 0, 16), UDim2.new(0.5, xOffset, 0.5, 0), 0, Color3.new(132/255, 132/255, 132/255))
				table.insert(Gui.LoadingFrames, frame)
				frame.Parent = Gui.PurchaseFrame
				xOffset = xOffset + 32
			end

	return Gui
end
local function create3DGui()
	local Gui = {}

	local Dialog = require(RobloxGui.Modules.VR.Dialog)
	Gui.Dialog = Dialog.new("Confirm Purchase", Color3.new(0.01, 0.72, 0.34))

	Gui.PurchaseDialog = createFrame("PurchaseDialog", UDim2.new(1, 0, 0, 396), nil, 1, nil)
	Gui.Dialog:SetContent(Gui.PurchaseDialog)

		Gui.ContainerFrame = createFrame("ContainerFrame", UDim2.new(1, 0, 1, 0), nil, 1, nil)
		Gui.ContainerFrame.Parent = Gui.PurchaseDialog

			Gui.ItemPreviewImageFrame = createFrame("ItemPreviewImageFrame", UDim2.new(0, 150, 0, 150), UDim2.new(0, 0, 0, 0), 1, nil)
			Gui.ItemPreviewImageFrame.Parent = Gui.ContainerFrame
			Gui.ItemPreviewImage = createImageLabel("ItemPreviewImage", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), "")
			Gui.ItemPreviewImage.ZIndex = 9
			Gui.ItemPreviewImage.Parent = Gui.ItemPreviewImageFrame

			Gui.ItemDescriptionText = createTextLabel("ItemDescriptionText", UDim2.new(1, -170, 0, 200), UDim2.new(0, 170, 0, 0), Enum.Font.SourceSansBold, Enum.FontSize.Size36, "")
			Gui.ItemDescriptionText.TextWrapped = true
			Gui.ItemDescriptionText.TextXAlignment = Enum.TextXAlignment.Left
			Gui.ItemDescriptionText.TextYAlignment = Enum.TextYAlignment.Top
			Gui.ItemDescriptionText.Parent = Gui.ContainerFrame

			Gui.PriceFrame = createFrame("PriceFrame", UDim2.new(1, -150, 0, 75), UDim2.new(0, 170, 0, 75), 1)
			Gui.PriceFrame.Parent = Gui.ContainerFrame

			Gui.RobuxIcon = createImageLabel("RobuxIcon", UDim2.new(0, 46, 0, 46), UDim2.new(0, 29 * 0.5, 0, 29 * 0.5), ROBUX_ICON)
			Gui.RobuxIcon.Visible = false
			Gui.RobuxIcon.Parent = Gui.PriceFrame
			Gui.TixIcon = createImageLabel("TixIcon", UDim2.new(0, 0, 0, 0), UDim2.new(0, 0, 0, 0), "")

			Gui.CostText = createTextLabel("CostText", UDim2.new(1, -70, 1, -2), UDim2.new(0, 70, 0, 0), Enum.Font.SourceSansBold, Enum.FontSize.Size48, "")
			Gui.CostText.TextXAlignment = Enum.TextXAlignment.Left
			Gui.CostText.Parent = Gui.PriceFrame

			Gui.PostBalanceText = createTextLabel("PostBalanceText", UDim2.new(1, 0, 0, 75), UDim2.new(0, 0, 0, 150), Enum.Font.SourceSansBold, Enum.FontSize.Size24, "")
			Gui.PostBalanceText.Parent = Gui.ContainerFrame

			local scaleType = Enum.ScaleType.Slice
			local sliceCenter = Rect.new(10, 10, 54, 54)

			Gui.BuyButton = createImageButtonWithText3D("BuyButton", BTN_L_POS_VR, VR_BUTTON, VR_BUTTON_DOWN, "Buy", Enum.Font.SourceSansBold, Enum.FontSize.Size36)
			Gui.BuyButton.ScaleType = scaleType
			Gui.BuyButton.SliceCenter = sliceCenter
			Gui.BuyButton.Visible = false
			Gui.BuyButton.Parent = Gui.ContainerFrame

			Gui.CancelButton = createImageButtonWithText3D("CancelButton", BTN_R_POS_VR, VR_BUTTON, VR_BUTTON_DOWN, "Cancel", Enum.Font.SourceSansBold, Enum.FontSize.Size36)
			Gui.CancelButton.ScaleType = scaleType
			Gui.CancelButton.SliceCenter = sliceCenter
			Gui.CancelButton.Visible = false
			Gui.CancelButton.Parent = Gui.ContainerFrame

			Gui.BuyRobuxButton = createImageButtonWithText3D("BuyRobuxButton", UDim2.new(0, 10, 0, 225), VR_BUTTON, VR_BUTTON_DOWN, "Buy", Enum.Font.SourceSansBold, Enum.FontSize.Size36)
			Gui.BuyRobuxButton.ScaleType = scaleType
			Gui.BuyRobuxButton.SliceCenter = sliceCenter
			Gui.BuyRobuxButton.Visible = false
			Gui.BuyRobuxButton.Parent = Gui.ContainerFrame

			Gui.BuyBCButton = createImageButtonWithText3D("BuyBCButton", UDim2.new(0, 10, 0, 225), VR_BUTTON, VR_BUTTON_DOWN, "Upgrade", Enum.Font.SourceSansBold, Enum.FontSize.Size36)
			Gui.BuyBCButton.ScaleType = scaleType
			Gui.BuyBCButton.SliceCenter = sliceCenter
			Gui.BuyBCButton.Visible = false
			Gui.BuyBCButton.Parent = Gui.ContainerFrame

			Gui.FreeButton = createImageButtonWithText3D("FreeButton", UDim2.new(0, 10, 0, 225), VR_BUTTON, VR_BUTTON_DOWN, "Take Free", Enum.Font.SourceSansBold, Enum.FontSize.Size36)
			Gui.FreeButton.ScaleType = scaleType
			Gui.FreeButton.SliceCenter = sliceCenter
			Gui.FreeButton.Visible = false
			Gui.FreeButton.Parent = Gui.ContainerFrame

			Gui.OkButton = createImageButtonWithText3D("OkButton", UDim2.new(0.25, 0, 0, 225), VR_BUTTON, VR_BUTTON_DOWN, "Ok", Enum.Font.SourceSansBold, Enum.FontSize.Size36)
			Gui.OkButton.ScaleType = scaleType
			Gui.OkButton.SliceCenter = sliceCenter
			Gui.OkButton.Size = UDim2.new(0.5, 0, 0, Gui.OkButton.Size.Y.Offset)
			Gui.OkButton.Visible = false
			Gui.OkButton.Parent = Gui.ContainerFrame

			Gui.OkPurchasedButton = createImageButtonWithText3D("OkPurchasedButton", BTN_M_POS_VR, VR_BUTTON, VR_BUTTON_DOWN, "Ok", Enum.Font.SourceSansBold, Enum.FontSize.Size36)
			Gui.OkPurchasedButton.ScaleType = scaleType
			Gui.OkPurchasedButton.SliceCenter = sliceCenter
			Gui.OkPurchasedButton.Size = UDim2.new(0.5, 0, 0, Gui.OkPurchasedButton.Size.Y.Offset)
			Gui.OkPurchasedButton.Visible = false
			Gui.OkPurchasedButton.Parent = Gui.ContainerFrame

		Gui.PurchaseFrame = createFrame("PurchaseFrame", UDim2.new(1, 0, 1, 0), nil, 1, nil)
		Gui.PurchaseFrame.Visible = false
		Gui.PurchaseFrame.Parent = Gui.PurchaseDialog

			Gui.PurchaseText = createTextLabel("PurchaseText", nil, UDim2.new(0.5, 0, 0.5, -100), Enum.Font.SourceSans, Enum.FontSize.Size60, "Purchasing")
			Gui.PurchaseText.Parent = Gui.PurchaseFrame

			Gui.LoadingFrames = {}
			local scaleFactor = 3
			local xOffset = -40 * scaleFactor
			for i = 1, 3 do
				local frame = createFrame3D("Loading", UDim2.new(0, 16 * scaleFactor, 0, 16 * scaleFactor), UDim2.new(0.5, xOffset, 0.5, -50), 0, Color3.new(132/255, 132/255, 132/255))
				table.insert(Gui.LoadingFrames, frame)
				frame.Parent = Gui.PurchaseFrame
				xOffset = xOffset + (32 * scaleFactor)
			end

	return Gui
end

local Gui2D = create2DGui()
local Gui3D = nil

local function getCurrentGui()
	if IsVRMode and vrPurchasePromptsEnabled then
		return Gui3D
	end
	return Gui2D
end

local function noOpFunc() end

local function enableControllerMovement()
	game:GetService("ContextActionService"):UnbindCoreAction(freezeThumbstick1Name)
	game:GetService("ContextActionService"):UnbindCoreAction(freezeThumbstick2Name)
	game:GetService("ContextActionService"):UnbindCoreAction(freezeControllerActionName)
end

local function disableControllerMovement()
	game:GetService("ContextActionService"):BindCoreAction(freezeControllerActionName, noOpFunc, false, Enum.UserInputType.Gamepad1)
	game:GetService("ContextActionService"):BindCoreAction(freezeThumbstick1Name, noOpFunc, false, Enum.KeyCode.Thumbstick1)
	game:GetService("ContextActionService"):BindCoreAction(freezeThumbstick2Name, noOpFunc, false, Enum.KeyCode.Thumbstick2)
end

--[[ Purchase Data Functions ]]--
local function getCurrencyString(currencyType)
	return currencyType == Enum.CurrencyType.Tix and "Tix" or "R$"
end

local function setInitialPurchaseData(assetId, productId, currencyType, equipOnPurchase)
	PurchaseData.AssetId = assetId
	PurchaseData.ProductId = productId
	PurchaseData.CurrencyType = currencyType
	PurchaseData.EquipOnPurchase = equipOnPurchase

	IsPurchasingConsumable = productId ~= nil
end

local function setCurrencyData(playerBalance)
	PurchaseData.CurrencyType = Enum.CurrencyType.Robux
	PurchaseData.CurrencyAmount = tonumber(PurchaseData.ProductInfo['PriceInRobux'])

	if PurchaseData.CurrencyAmount == nil then
		PurchaseData.CurrencyAmount = 0
	end
end

local function setPreviewImageInternal(image)
	getCurrentGui().ItemPreviewImage.Image = image
end

local function setPreviewImageXbox(productInfo, assetId)
	-- get the asset id we want
	local id = nil
	if IsPurchasingConsumable and productInfo and productInfo["IconImageAssetId"] then
		id = productInfo["IconImageAssetId"]
	elseif assetId then
		id = assetId
	else
		setPreviewImageInternal(DEFAULT_XBOX_IMAGE)
		return
	end

	local path = 'asset-thumbnail/json?assetId=%d&width=100&height=100&format=png'
	path = BASE_URL..string.format(path, id)
	spawn(function()
		-- check if thumb has been generated, if not generated or if anything fails
		-- set to the default image
		local success, result = pcall(function()
			return game:HttpGetAsync(path)
		end)
		if not success then
			setPreviewImageInternal(DEFAULT_XBOX_IMAGE)
			return
		end

		local decodeSuccess, decodeResult = pcall(function()
			return HttpService:JSONDecode(result)
		end)
		if not decodeSuccess then
			setPreviewImageInternal(DEFAULT_XBOX_IMAGE)
			return
		end

		if decodeResult["Final"] == true then
			setPreviewImageInternal(THUMBNAIL_URL..tostring(id).."&x=100&y=100&format=png")
		else
			setPreviewImageInternal(DEFAULT_XBOX_IMAGE)
		end
	end)
end

local function setPreviewImage(productInfo, assetId)
	-- For now let's only run this logic on Xbox
	if platform == Enum.Platform.XBoxOne then
		setPreviewImageXbox(productInfo, assetId)
		return
	end
	if IsPurchasingConsumable then
		if productInfo then
			setPreviewImageInternal(THUMBNAIL_URL..tostring(productInfo["IconImageAssetId"]).."&x=100&y=100&format=png")
		end
	else
		if assetId then
			setPreviewImageInternal(THUMBNAIL_URL..tostring(assetId).."&x=100&y=100&format=png")
		end
	end
end

local function setVisible(...)
	local icons = { ... }
	for i, v in pairs(icons) do
		v.Visible = true
	end
end

local function setNotVisible(...)
	local icons = { ... }
	for i, v in pairs(icons) do
		v.Visible = false
	end
end

local function clearPurchaseData()
	local currentGui = getCurrentGui()
	for k,v in pairs(PurchaseData) do
		PurchaseData[k] = nil
	end
	--Gui3D doesn't have TixIcon, but this will be fine since setNotVisible loops and therefore will skip a nil.
	setNotVisible(currentGui.RobuxIcon, currentGui.TixIcon, currentGui.CostText)
end

--[[ Show Functions ]]--
local function setButtonsVisible(...)
	local args = {...}
	local argCount = select('#', ...)
	local currentGui = getCurrentGui()

	for _,child in pairs(currentGui.ContainerFrame:GetChildren()) do
		if child:IsA('ImageButton') then
			child.Visible = false
			for i = 1, argCount do
				if child == args[i] then
					child.Visible = true
				end
			end
		end
	end
end

local function tweenColorProperty(frame, endColor, duration, colorProp)
	local t = 0
	local prevTime = tick()
	colorProp = colorProp or "BackgroundColor3"
	local startColor = frame[colorProp]
	while t < duration do
		local s = t / duration
		local r = lerp(startColor.r, endColor.r, s)
		local g = lerp(startColor.g, endColor.g, s)
		local b = lerp(startColor.b, endColor.b, s)
		frame[colorProp] = Color3.new(r, g, b)
		--
		t = t + (tick() - prevTime)
		prevTime = tick()
		wait()
	end
	frame[colorProp] = endColor
end

local isPurchaseAnimating = false
local function startPurchaseAnimation()
	local currentGui = getCurrentGui()
	local scaleFactor = 1
	if IsVRMode and vrPurchasePromptsEnabled then
		scaleFactor = 3
	end

	if currentGui.PurchaseFrame.Visible then return end

	currentGui.ContainerFrame.Visible = false
	currentGui.PurchaseFrame.Visible = true
	currentGui.PurchaseText.Text = "Purchasing"

 
	spawn(function()
		isPurchaseAnimating = true
		local i = 1
		while isPurchaseAnimating do
			local frame = currentGui.LoadingFrames[i]

			local prevPosition = frame.Position
			local newPosition = UDim2.new(prevPosition.X.Scale, prevPosition.X.Offset, prevPosition.Y.Scale, prevPosition.Y.Offset - (2 * scaleFactor))
			local prevWidth, prevHeight = frame.Size.X.Offset, frame.Size.Y.Offset
			local expandedHeight = prevHeight + (4 * scaleFactor)

			local propertyName = "BackgroundColor3"
			if IsVRMode and vrPurchasePromptsEnabled then
				propertyName = "ImageColor3"
			end

			spawn(function()
				tweenColorProperty(frame, Color3.new(0, 162/255, 1), 0.25, propertyName)
			end)
			frame:TweenSizeAndPosition(UDim2.new(0, prevWidth, 0, expandedHeight), newPosition, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.25, true, function()
				spawn(function()
					tweenColorProperty(frame, Color3.new(132/255, 132/255, 132/255), 0.25, propertyName)
				end)
				frame:TweenSizeAndPosition(UDim2.new(0, prevWidth, 0, prevHeight), prevPosition, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.25, true)
			end)

			i = i + 1
			if i > 3 then
				i = 1
				wait(0.25)	-- small pause when starting from 1
			end
			wait(0.5)
		end
	end)
end

local function showRemoveVRHeadsetNotice()
	startPurchaseAnimation()
	getCurrentGui().PurchaseText.Text = "Remove your headset"
	--this is a placeholder; we'll get a design in a future iteration
end

local function stopPurchaseAnimation()
	isPurchaseAnimating = false
	local currentGui = getCurrentGui()
	currentGui.PurchaseFrame.Visible = false
	currentGui.ContainerFrame.Visible = true
end

local function setPurchaseDataInGui(isFree, invalidBC)
	local currentGui = getCurrentGui()
	local  descriptionText = PurchaseData.CurrencyType == Enum.CurrencyType.Tix and PURCHASE_MSG.PURCHASE_TIX or PURCHASE_MSG.PURCHASE
	if isFree then
		descriptionText = PURCHASE_MSG.FREE
		currentGui.PurchaseText.Text = PURCHASE_MSG.FREE_BALANCE
	end

	local productInfo = PurchaseData.ProductInfo
	if not productInfo then
		return false
	end
	local itemDescription = string.gsub(descriptionText, "itemName", string.sub(productInfo["Name"], 1, 20))
	itemDescription = string.gsub(itemDescription, "assetType", ASSET_TO_STRING[productInfo["AssetTypeId"]] or "Unknown")
	local itemDescriptionText = currentGui.ItemDescriptionText
	if IsVRMode and vrPurchasePromptsEnabled then
		itemDescriptionText.Font = Enum.Font.SourceSansBold
		itemDescriptionText.FontSize = Enum.FontSize.Size36
	end
	itemDescriptionText.Text = itemDescription

	if not isFree then
		if PurchaseData.CurrencyType == Enum.CurrencyType.Tix then
			if not IsVRMode then
				currentGui.TixIcon.Visible = true
				currentGui.TixIcon.Position = UDim2.new(0, isTenFootInterface and 110*scaleFactor or 110, 0, itemDescriptionText.Position.Y.Offset + itemDescriptionText.TextBounds.y + (isTenFootInterface and 6*scaleFactor or 6))
			end
			currentGui.CostText.TextColor3 = Color3.new(204/255, 158/255, 113/255)
		else
			currentGui.RobuxIcon.Visible = true
			if not IsVRMode or not vrPurchasePromptsEnabled then
				currentGui.RobuxIcon.Position = UDim2.new(0, isTenFootInterface and 110*scaleFactor or 110, 0, itemDescriptionText.Position.Y.Offset + itemDescriptionText.TextBounds.y + (isTenFootInterface and 6*scaleFactor or 6))
			end
			currentGui.CostText.TextColor3 = Color3.new(2/255, 183/255, 87/255)
		end
		currentGui.CostText.Text = formatNumber(PurchaseData.CurrencyAmount)
		if not IsVRMode or not vrPurchasePromptsEnabled then
			currentGui.CostText.Position = UDim2.new(0, isTenFootInterface and 134*scaleFactor or 134, 0, itemDescriptionText.Position.Y.Offset + itemDescriptionText.TextBounds.y + (isTenFootInterface and 15*scaleFactor or 15))
		end
		currentGui.CostText.Visible = true
	end

	setPreviewImage(productInfo, PurchaseData.AssetId)
	purchaseState = PURCHASE_STATE.BUYITEM
	setButtonsVisible(isFree and currentGui.FreeButton or currentGui.BuyButton, currentGui.CancelButton)
	currentGui.PostBalanceText.Visible = true

	if invalidBC then
		local neededBcLevel = PurchaseData.ProductInfo["MinimumMembershipLevel"]
		currentGui.PurchaseText.Text = "This item requires "..BC_LVL_TO_STRING[neededBcLevel]..".\nClick 'Upgrade' to upgrade your Builders Club!"
		purchaseState = PURCHASE_STATE.BUYBC
		setButtonsVisible(currentGui.BuyBCButton, currentGui.CancelButton)
	end
	return true
end

local function getRobuxProduct(amountNeeded, isBCMember)
	local productArray = nil

	if platform == Enum.Platform.XBoxOne then
		productArray = {}
		local platformCatalogData = require(RobloxGui.Modules.PlatformCatalogData)

		local catalogInfo = platformCatalogData:GetCatalogInfoAsync()
		if catalogInfo then
			for _, productInfo in pairs(catalogInfo) do
				local robuxValue = platformCatalogData:ParseRobuxValue(productInfo)
				table.insert(productArray, robuxValue)
			end
		end
	else
		productArray = isBCMember and BC_ROBUX_PRODUCTS or NON_BC_ROBUX_PRODUCTS
	end

	table.sort(productArray, function(a,b) return a < b end)

	for i = 1, #productArray do
		if productArray[i] >= amountNeeded then
			return productArray[i]
		end
	end

	return nil
end

local function getRobuxProductToBuyItem(amountNeeded)
	local isBCMember = Players.LocalPlayer.MembershipType ~= Enum.MembershipType.None

	local productCost = getRobuxProduct(amountNeeded, isBCMember)
	if not productCost then
		return nil
	end

	--todo: we should clean all this up at some point so all the platforms have the
	-- same product names, or at least names that are very similar
	
	local isUsingNewProductId = (platform == Enum.Platform.Android) or (platform == Enum.Platform.UWP)

	local prependStr, appendStr, appPrefix = "", "", ""
	if isUsingNewProductId then
		prependStr = "robux"
		if isBCMember then
			appendStr = "bc"
		end
		appPrefix = "com.roblox.client."
	elseif platform == Enum.Platform.XBoxOne then
		local platformCatalogData = require(RobloxGui.Modules.PlatformCatalogData)

		local catalogInfo = platformCatalogData:GetCatalogInfoAsync()
		if catalogInfo then
			for _, productInfo in pairs(catalogInfo) do
				if platformCatalogData:ParseRobuxValue(productInfo) == productCost then
					return productInfo.ProductId, productCost
				end
			end
		end
	else -- used by iOS
		appendStr = isBCMember and "RobuxBC" or "RobuxNonBC"
		appPrefix = "com.roblox.robloxmobile."
	end

	local productStr = appPrefix..prependStr..tostring(productCost)..appendStr
	return productStr, productCost
end

local function setBuyMoreRobuxDialog(playerBalance)
	local currentGui = getCurrentGui()

	local playerBalanceInt = tonumber(playerBalance["robux"])
	local neededRobux = PurchaseData.CurrencyAmount - playerBalanceInt
	local productInfo = PurchaseData.ProductInfo

	local descriptionText = "You need %s more ROBUX to buy the %s %s"
	descriptionText = string.format(descriptionText, formatNumber(neededRobux), productInfo["Name"], ASSET_TO_STRING[productInfo["AssetTypeId"]] or "")

	purchaseState = PURCHASE_STATE.BUYROBUX
	setButtonsVisible(currentGui.BuyRobuxButton, currentGui.CancelButton)

	if IsNativePurchasing then
		local productCost = nil
		ThirdPartyProductName, productCost = getRobuxProductToBuyItem(neededRobux)
		--
		if not ThirdPartyProductName then
			descriptionText = "This item cost more ROBUX than you can purchase. Please visit www.roblox.com to purchase more ROBUX."
			purchaseState = PURCHASE_STATE.FAILED
			setButtonsVisible(currentGui.OkButton)
		else
			local remainder = playerBalanceInt + productCost - PurchaseData.CurrencyAmount
			descriptionText = descriptionText..". Would you like to buy "..formatNumber(productCost).." ROBUX?"
			
			local postBalanceText = currentGui.PostBalanceText
			postBalanceText.Text = "The remaining "..formatNumber(remainder).." ROBUX will be credited to your balance."
			postBalanceText.Visible = true
		end
	else
		descriptionText = descriptionText..". Would you like to buy more ROBUX?"
	end

	local itemDescriptionText = currentGui.ItemDescriptionText
	if IsVRMode and vrPurchasePromptsEnabled then
		itemDescriptionText.Font = Enum.Font.SourceSans
		itemDescriptionText.FontSize = Enum.FontSize.Size36
	end
	itemDescriptionText.Text = descriptionText
	setPreviewImage(productInfo, PurchaseData.AssetId)
end

local function showPurchasePrompt()
	local currentGui = getCurrentGui()

	stopPurchaseAnimation()
	currentGui.PurchaseDialog.Visible = true

	if isTenFootInterface then
		UserInputService.OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.ForceHide
	end
	if not IsVRMode or not vrPurchasePromptsEnabled then
		currentGui.PurchaseDialog:TweenPosition(isTenFootInterface and SHOW_POSITION_TENFOOT or SHOW_POSITION, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, TWEEN_TIME, true)
	else
		currentGui.Dialog:SetContent(Gui3D.PurchaseDialog)
		currentGui.Dialog:Show(true)
	end
	disableControllerMovement()
	if not IsVRMode or not vrPurchasePromptsEnabled then
		enableControllerInput()
	end
end

--[[ Close and Cancel Functions ]]--
local function onPurchaseFailed(failType)
	local currentGui = getCurrentGui()
	setButtonsVisible(currentGui.OkButton)
	setPreviewImageInternal(ERROR_ICON)
	currentGui.PostBalanceText.Text = ""

	local itemName = PurchaseData.ProductInfo and PurchaseData.ProductInfo["Name"] or ""
	local failedText = string.gsub(PURCHASE_MSG.FAILED, "itemName", string.sub(itemName, 1, 20))
	
	if itemName == "" then
		failedText = string.gsub(failedText, " of ", "")
	end
		
	if failType == PURCHASE_FAILED.DEFAULT_ERROR then
		failedText = string.gsub(failedText, "errorReason", ERROR_MSG.UNKNWON_FAILURE)
	elseif failType == PURCHASE_FAILED.IN_GAME_PURCHASE_DISABLED then
		failedText = string.gsub(failedText, "errorReason", ERROR_MSG.PURCHASE_DISABLED)
	elseif failType == PURCHASE_FAILED.CANNOT_GET_BALANCE then
		failedText = "Cannot retrieve your balance at this time. Your account has not been charged. Please try again later."
	elseif failType == PURCHASE_FAILED.CANNOT_GET_ITEM_PRICE then
		failedText = "We couldn't retrieve the price of the item at this time. Your account has not been charged. Please try again later."
	elseif failType == PURCHASE_FAILED.NOT_FOR_SALE then
		failedText = "This item is not currently for sale. Your account has not been charged."
		setPreviewImage(PurchaseData.ProductInfo, PurchaseData.AssetId)
	elseif failType == PURCHASE_FAILED.NOT_ENOUGH_TIX then
		failedText = "This item cost more tickets than you currently have. Try trading currency on www.roblox.com to get more tickets."
		setPreviewImage(PurchaseData.ProductInfo, PurchaseData.AssetId)
	elseif failType == PURCHASE_FAILED.UNDER_13 then
		failedText = "Your account is under 13. Purchase of this item is not allowed. Your account has not been charged."
	elseif failType == PURCHASE_FAILED.LIMITED then
		failedText = "This limited item has no more copies. Try buying from another user on www.roblox.com. Your account has not been charged."
		setPreviewImage(PurchaseData.ProductInfo, PurchaseData.AssetId)
	elseif failType == PURCHASE_FAILED.DID_NOT_BUY_ROBUX then
		failedText = string.gsub(failedText, "errorReason", ERROR_MSG.INVALID_FUNDS)
	elseif failType == PURCHASE_FAILED.PROMPT_PURCHASE_ON_GUEST then
		failedText = "You need to create a ROBLOX account to buy items, visit www.roblox.com for more info."
	elseif failType == PURCHASE_FAILED.THIRD_PARTY_DISABLED then
		failedText = "Third-party item sales have been disabled for this place. Your account has not been charged."
		setPreviewImage(PurchaseData.ProductInfo, PurchaseData.AssetId)
	end

	if IsVRMode and vrPurchasePromptsEnabled then
		setNotVisible(currentGui.RobuxIcon, currentGui.CostText)
	else
		setNotVisible(currentGui.RobuxIcon, currentGui.TixIcon, currentGui.CostText)
	end

	purchaseState = PURCHASE_STATE.FAILED

	if IsVRMode and vrPurchasePromptsEnabled then
		currentGui.ItemDescriptionText.Font = Enum.Font.SourceSans
		currentGui.ItemDescriptionText.FontSize = Enum.FontSize.Size36
	end
	currentGui.ItemDescriptionText.Text = failedText
	showPurchasePrompt()
end

local function closePurchaseDialog()
	local currentGui = getCurrentGui()
	if not IsVRMode or not vrPurchasePromptsEnabled then
		currentGui.PurchaseDialog:TweenPosition(isTenFootInterface and HIDE_POSITION_TENFOOT or HIDE_POSITION, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, TWEEN_TIME, true, function()
			currentGui.PurchaseDialog.Visible = false
			IsCurrentlyPrompting = false
			IsCurrentlyPurchasing = false
			IsCheckingPlayerFunds = false
			purchaseState = PURCHASE_STATE.DEFAULT
			if isTenFootInterface then
				UserInputService.OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.None
			end
		end)
	else
		IsCurrentlyPrompting = false
		IsCurrentlyPurchasing = false
		IsCheckingPlayerFunds = false
		purchaseState = PURCHASE_STATE.DEFAULT
		currentGui.Dialog:SetContent(nil)
		currentGui.Dialog:Close()
	end
end

-- Main exit point
local function onPromptEnded(isSuccess)
	local didPurchase = (purchaseState == PURCHASE_STATE.SUCCEEDED)

	closePurchaseDialog()
	if IsPurchasingConsumable then
		MarketplaceService:SignalPromptProductPurchaseFinished(Players.LocalPlayer.userId, PurchaseData.ProductId, didPurchase)
	else
		MarketplaceService:SignalPromptPurchaseFinished(Players.LocalPlayer, PurchaseData.AssetId, didPurchase)
	end
	clearPurchaseData()
	enableControllerMovement()
	disableControllerInput()
end

--[[ Purchase Validation ]]--
local function isMarketplaceDown() 		-- FFlag
	local success, result = pcall(function() return settings():GetFFlag('Order66') end)
	if not success then
		print("PurchasePromptScript: isMarketplaceDown failed because", result)
		return false
	end

	return result
end

local function checkMarketplaceAvailable() 	-- FFlag
	local success, result = pcall(function() return settings():GetFFlag("CheckMarketplaceAvailable") end)
	if not success then
		print("PurchasePromptScript: checkMarketplaceAvailable failed because", result)
		return false
	end

	return result
end

local function areThirdPartySalesRestricted() 	-- FFlag
	local success, result = pcall(function() return settings():GetFFlag("RestrictSales") end)
	if not success then
		print("PurchasePromptScript: areThirdPartySalesRestricted failed because", result)
		return false
	end

	return result
end


-- return success and isAvailable
local function isMarketplaceAvailable()
	local success, result = pcall(function()
		return HttpRbxApiService:GetAsync("my/economy-status", false,
			Enum.ThrottlingPriority.Extreme)
	end)
	if not success then
		print("PurchasePromptScript: isMarketplaceAvailable() failed because", result)
		return false
	end
	result = HttpService:JSONDecode(result)
	if result["isMarketplaceEnabled"] ~= nil then
		if result["isMarketplaceEnabled"] == false then
			return true, false
		end
	end
	return true, true
end

local function getProductInfo()
	local success, result = nil, nil
	if IsPurchasingConsumable then
		success, result = pcall(function()
			return MarketplaceService:GetProductInfo(PurchaseData.ProductId, Enum.InfoType.Product)
		end)
	else
		success, result = pcall(function()
			return MarketplaceService:GetProductInfo(PurchaseData.AssetId)
		end)
	end

	if not success or not result then
		print("PurchasePromptScript: getProductInfo failed because", result)
		return nil
	end

	if type(result) ~= 'table' then
		result = HttpService:JSONDecode(result)
	end

	return result
end

-- returns success, doesOwnItem
local function doesPlayerOwnItem()
	if not PurchaseData.AssetId or PurchaseData.AssetId <= 0 then
		return false, nil
	end

	local success, result = pcall(function()
		return MarketplaceService:PlayerOwnsAsset(Players.LocalPlayer, PurchaseData.AssetId)
	end)

	if not success then
		print("PurchasePromptScript: doesPlayerOwnItem() failed because", result)
		return false, nil
	end

	return true, result == true or result == 'true'
end

local function isFreeItem()
	return PurchaseData.ProductInfo and PurchaseData.ProductInfo["IsPublicDomain"] == true
end

local getPlayerBalance
if useNewMarketplaceMethods() then
	getPlayerBalance = function()
		local success, result = pcall(function()
			return MarketplaceService:GetRobuxBalance()
		end)

		if not success then
			print("PurchasePromptScript: GetRobuxBalance() failed because", result)
			return nil
		end

		local balance = {}
		balance.robux = result
		balance.tickets = 0
		return balance
	end
else
	getPlayerBalance = function()
		local apiPath = platform == Enum.Platform.XBoxOne and 'my/platform-currency-budget' or 'currency/balance'

		local success, result = pcall(function()
			return HttpRbxApiService:GetAsync(apiPath, true)
		end)

		if not success then
			print("PurchasePromptScript: getPlayerBalance() failed because", result)
			return nil
		end

		if result == '' then return end

		result = HttpService:JSONDecode(result)
		if platform == Enum.Platform.XBoxOne then
			result["robux"] = result["Robux"]
			result["tickets"] = "0"
		end

		return result
	end
end

local function isNotForSale()
	return PurchaseData.ProductInfo['IsForSale'] == false and PurchaseData.ProductInfo["IsPublicDomain"] == false
end

local function playerHasFundsForPurchase(playerBalance)
	local currencyTypeStr = nil
	if PurchaseData.CurrencyType == Enum.CurrencyType.Robux then
		currencyTypeStr = "robux"
	elseif PurchaseData.CurrencyType == Enum.CurrencyType.Tix then
		currencyTypeStr = "tickets"
	else
		return false
	end

	local playerBalanceInt = tonumber(playerBalance[currencyTypeStr])
	if not playerBalanceInt then
		return false
	end

	local postBalanceText = getCurrentGui().PostBalanceText

	local afterBalanceAmount = playerBalanceInt - PurchaseData.CurrencyAmount
	local currencyStr = getCurrencyString(PurchaseData.CurrencyType)
	if afterBalanceAmount < 0 and PurchaseData.CurrencyType == Enum.CurrencyType.Robux then
		postBalanceText.Visible = false
		return true, false
	elseif afterBalanceAmount < 0 and PurchaseData.CurrencyType == Enum.CurrencyType.Tix then
		postBalanceText.Visible = true
		postBalanceText.Text = "You need "..formatNumber(-afterBalanceAmount).." more "..currencyStr.." to buy this item."
		return true, false
	end


	if PurchaseData.CurrencyType == Enum.CurrencyType.Tix then
		postBalanceText.Text = PURCHASE_MSG.BALANCE_FUTURE..formatNumber(afterBalanceAmount).." "..currencyStr.."."
	else
		postBalanceText.Text = PURCHASE_MSG.BALANCE_FUTURE..currencyStr..formatNumber(afterBalanceAmount).."."
	end
	if studioMockPurchasesEnabled() then
		postBalanceText.Text = PURCHASE_MSG.MOCK_PURCHASE
	end

	return true, true
end

local function isUnder13()
	if PurchaseData.ProductInfo["ContentRatingTypeId"] == 1 then
		if Players.LocalPlayer:GetUnder13() then
			return true
		end
	end
	return false
end

local function isLimitedUnique()
	local productInfo = PurchaseData.ProductInfo
	if productInfo then
		if (productInfo["IsLimited"] or productInfo["IsLimitedUnique"]) and
			(productInfo["Remaining"] == "" or productInfo["Remaining"] == 0 or productInfo["Remaining"] == nil or productInfo["Remaining"] == "null") then
			return true
		end
	end
	return false
end

-- main validation function
local function canPurchase(disableUpsell)
	local currentGui = getCurrentGui()

	if not Players.LocalPlayer then
		return false
	end
	if useNewMarketplaceMethods() then
		if not MarketplaceService:PlayerCanMakePurchases(Players.LocalPlayer) then
			onPurchaseFailed(PURCHASE_FAILED.PROMPT_PURCHASE_ON_GUEST)
			return false
		end
	else
		if game.Players.LocalPlayer.userId < 0 then
			onPurchaseFailed(PURCHASE_FAILED.PROMPT_PURCHASE_ON_GUEST)
			return false
		end
	end

	if isMarketplaceDown() then 	-- FFlag
		onPurchaseFailed(PURCHASE_FAILED.IN_GAME_PURCHASE_DISABLED)
		return false
	end

	if checkMarketplaceAvailable() then 	-- FFlag
		local success, isAvailable = isMarketplaceAvailable()
		if success then
			if not isAvailable then
				onPurchaseFailed(PURCHASE_FAILED.IN_GAME_PURCHASE_DISABLED)
				return false
			end
		else
			onPurchaseFailed(PURCHASE_FAILED.DEFAULT_ERROR)
			return false
		end
	end

	PurchaseData.ProductInfo = getProductInfo()
	if not PurchaseData.ProductInfo then
		onPurchaseFailed(PURCHASE_FAILED.IN_GAME_PURCHASE_DISABLED)
		return false
	end

	if isNotForSale() then
		onPurchaseFailed(PURCHASE_FAILED.NOT_FOR_SALE)
		return false
	end

	-- check if owned by player; dev products are not owned	local isRestrictedThirdParty = false
	if not IsPurchasingConsumable then
		local success, doesOwnItem = doesPlayerOwnItem()
		if not success then
			onPurchaseFailed(PURCHASE_FAILED.DEFAULT_ERROR)
			return false
		elseif doesOwnItem then
			if not PurchaseData.ProductInfo then
				onPurchaseFailed(PURCHASE_FAILED.DEFAULT_ERROR)
				return false
			end
			purchaseState = PURCHASE_STATE.FAILED
			setPreviewImage(PurchaseData.ProductInfo, PurchaseData.AssetId)
			if IsVRMode then
				currentGui.ItemDescriptionText.Font = Enum.Font.SourceSans
				currentGui.ItemDescriptionText.FontSize = Enum.FontSize.Size36
			end
			currentGui.ItemDescriptionText.Text = PURCHASE_MSG.ALREADY_OWN
			currentGui.PostBalanceText.Visible = false
			setButtonsVisible(currentGui.OkButton)
			return true
		end
		
		-- most places will not need to sell third party assets.
		if areThirdPartySalesRestricted() and not game:GetService("Workspace").AllowThirdPartySales then
			local ProductCreator = tonumber(PurchaseData.ProductInfo["Creator"]["Id"])
			local RobloxCreator = 1
			if ProductCreator ~= game.CreatorId and ProductCreator ~= RobloxCreator then
				isRestrictedThirdParty = true
			end
		end
	end

	local isFree = isFreeItem()

	if not isFree and isRestrictedThirdParty then
		onPurchaseFailed(PURCHASE_FAILED.THIRD_PARTY_DISABLED)
		return false    
	end

	local playerBalance = getPlayerBalance()
	if not playerBalance then
		onPurchaseFailed(PURCHASE_FAILED.CANNOT_GET_BALANCE)
		return false
	end

	-- validate item price
	setCurrencyData(playerBalance)
	if not PurchaseData.CurrencyAmount and not isFree then
		onPurchaseFailed(PURCHASE_FAILED.CANNOT_GET_ITEM_PRICE)
		return false
	end

	-- check player funds
	local hasFunds = nil
	if not isFree then
		local success = nil
		success, hasFunds = playerHasFundsForPurchase(playerBalance)
		if success then
			if not hasFunds then
				if PurchaseData.CurrencyType == Enum.CurrencyType.Tix then
					onPurchaseFailed(PURCHASE_FAILED.NOT_ENOUGH_TIX)
					return false
				elseif not disableUpsell then
					setBuyMoreRobuxDialog(playerBalance)
				end
			end
		else
			onPurchaseFailed(PURCHASE_FAILED.CANNOT_GET_BALANCE)
			return false
		end
	end

	-- check membership type
	local invalidBCLevel = PurchaseData.ProductInfo["MinimumMembershipLevel"] > Players.LocalPlayer.MembershipType.Value

	-- check under 13
	if isUnder13() then
		onPurchaseFailed(PURCHASE_FAILED.UNDER_13)
		return false
	end

	if isLimitedUnique() then
		onPurchaseFailed(PURCHASE_FAILED.LIMITED)
		return false
	end

	if (hasFunds or isFree or invalidBCLevel) then
		if not setPurchaseDataInGui(isFree, invalidBCLevel) then
			onPurchaseFailed(PURCHASE_FAILED.DEFAULT_ERROR)
			return false
		end
	end

	return true
end

--[[ Purchase Functions ]]--
local function getToolAsset(assetId)
	local tool = InsertService:LoadAsset(assetId)
	if not tool then return nil end
	--
	if tool:IsA("Tool") then
		return tool
	end

	local children = tool:GetChildren()
	for i = 1, #children do
		if children[i]:IsA("Tool") then
			return children[i]
		end
	end
end

local function onPurchaseSuccess()
	local currentGui = getCurrentGui()

	IsCheckingPlayerFunds = false
	local descriptionText = PURCHASE_MSG.SUCCEEDED

	descriptionText = string.gsub(descriptionText, "itemName", string.sub(PurchaseData.ProductInfo["Name"], 1, 20))
	if IsVRMode then
		currentGui.ItemDescriptionText.Font = Enum.Font.SourceSans
		currentGui.ItemDescriptionText.FontSize = Enum.FontSize.Size36
	end
	currentGui.ItemDescriptionText.Text = descriptionText

	local playerBalance = getPlayerBalance()
	local currencyType = PurchaseData.CurrencyType == Enum.CurrencyType.Tix and "tickets" or "robux"
	local newBalance = playerBalance[currencyType]

	if currencyType == "robux" then
		currentGui.PostBalanceText.Text = PURCHASE_MSG.BALANCE_NOW..getCurrencyString(PurchaseData.CurrencyType)..formatNumber(newBalance).."."
	else
		currentGui.PostBalanceText.Text = PURCHASE_MSG.BALANCE_NOW..formatNumber(newBalance).." "..getCurrencyString(PurchaseData.CurrencyType).."."
	end

	if studioMockPurchasesEnabled() then
		currentGui.PostBalanceText.Text = PURCHASE_MSG.MOCK_PURCHASE_SUCCESS
	elseif isFreeItem() then
		currentGui.PostBalanceText.Visible = false
	end

	purchaseState = PURCHASE_STATE.SUCCEEDED

	setButtonsVisible(currentGui.OkPurchasedButton)
	stopPurchaseAnimation()
end

local function onAcceptPurchase()
	if IsCurrentlyPurchasing then return end

	if purchaseState ~= PURCHASE_STATE.BUYITEM then
		return
	end

	--
	disableControllerInput()
	IsCurrentlyPurchasing = true
	startPurchaseAnimation()
	local startTime = tick()
	local apiPath = nil
	local params = nil
	local currencyTypeInt = nil
	if PurchaseData.CurrencyType == Enum.CurrencyType.Robux or PurchaseData.CurrencyType == Enum.CurrencyType.Default then
		currencyTypeInt = 1
	elseif PurchaseData.CurrencyType == Enum.CurrencyType.Tix then
		currencyTypeInt = 2
	end

	local productId = PurchaseData.ProductInfo["ProductId"]
	if IsPurchasingConsumable then
		apiPath = "marketplace/submitpurchase"
		params = "productId="..tostring(productId).."&currencyTypeId="..tostring(currencyTypeInt)..
			"&expectedUnitPrice="..tostring(PurchaseData.CurrencyAmount).."&placeId="..tostring(game.PlaceId)
		params = params.."&requestId="..HttpService:UrlEncode(HttpService:GenerateGUID(false))
	else
		apiPath = "marketplace/purchase"
		params = "productId="..tostring(productId).."&currencyTypeId="..tostring(currencyTypeInt)..
			"&purchasePrice="..tostring(PurchaseData.CurrencyAmount or 0).."&locationType=Game&locationId="..tostring(game.PlaceId)
	end

	local submitPurchase
	if useNewMarketplaceMethods() then
		local requestId = HttpService:GenerateGUID(false)
		submitPurchase = function()
			return game:GetService("MarketplaceService"):PerformPurchase(IsPurchasingConsumable and Enum.InfoType.Product or Enum.InfoType.Asset, productId, PurchaseData.CurrencyAmount or 0, requestId)
		end
	else
		submitPurchase = function()
			return HttpRbxApiService:PostAsync(apiPath, params, true, Enum.ThrottlingPriority.Default, Enum.HttpContentType.ApplicationUrlEncoded)
		end
	end

	local success, result = pcall(submitPurchase)
	-- retry
	if IsPurchasingConsumable then
		local retries = 3
		local wasSuccess = success and result and result ~= ''
		while retries > 0 and not wasSuccess do
			wait(1)
			retries = retries - 1
			success, result = pcall(submitPurchase)
			wasSuccess = success and result and result ~= ''
		end
		--
		game:ReportInGoogleAnalytics("Developer Product", "Purchase",
			wasSuccess and ("success. Retries = "..(3 - retries)) or ("failure: " .. tostring(result)), 1)
	end

	if tick() - startTime < 1 then wait(1) end 		-- artifical delay to show spinner for at least 1 second

	if not IsVRMode then
		enableControllerInput()
	end

	if not success then
		print("PurchasePromptScript: onAcceptPurchase() failed because", result)
		onPurchaseFailed(PURCHASE_FAILED.DEFAULT_ERROR)
		return
	end

	if type(result) == "string" then
		result = HttpService:JSONDecode(result)
	end
	if result then
		if result["success"] == false then
			if result["status"] ~= "AlreadyOwned" then
				print("PurchasePromptScript: onAcceptPurchase() response failed because", tostring(result["status"]))
				if result["status"] == "EconomyDisabled" then
					onPurchaseFailed(PURCHASE_FAILED.IN_GAME_PURCHASE_DISABLED)
				else
					onPurchaseFailed(PURCHASE_FAILED.DEFAULT_ERROR)
				end
				return
			end
		end
	else
		print("PurchasePromptScript: onAcceptPurchase() failed to parse JSON of", productId)
		onPurchaseFailed(PURCHASE_FAILED.DEFAULT_ERROR)
		return
	end

	if PurchaseData.EquipOnPurchase and PurchaseData.AssetId and tonumber(PurchaseData.ProductInfo["AssetTypeId"]) == 19 then
		local tool = getToolAsset(tonumber(PurchaseData.AssetId))
		if tool then
			tool.Parent = Players.LocalPlayer.Backpack
		end
	end

	if IsPurchasingConsumable then
		if not result["receipt"] then
			print("PurchasePromptScript: onAcceptPurchase() failed because no dev product receipt was returned for", tostring(productId))
			onPurchaseFailed(PURCHASE_FAILED.DEFAULT_ERROR)
			return
		end
		MarketplaceService:SignalClientPurchaseSuccess(tostring(result["receipt"]), Players.LocalPlayer.userId, productId)
	else
		onPurchaseSuccess()
		if PurchaseData.CurrencyType == Enum.CurrencyType.Robux then
			MarketplaceService:ReportAssetSale(PurchaseData.AssetId, PurchaseData.CurrencyAmount)
		end
	end
end

-- main entry point
local function onPurchasePrompt(player, assetId, equipIfPurchased, currencyType, productId)
	if player == Players.LocalPlayer and not IsCurrentlyPrompting then
		IsCurrentlyPrompting = true
		setInitialPurchaseData(assetId, productId, currencyType, equipIfPurchased)
		if canPurchase() then
			showPurchasePrompt()
		end
	end
end

function hasEnoughMoneyForPurchase()
	local playerBalance = getPlayerBalance()
	if playerBalance then
		local success, hasFunds = nil
		success, hasFunds = playerHasFundsForPurchase(playerBalance)
		return success and hasFunds
	end

	return false
end

function retryPurchase(overrideRetries)
	local canMakePurchase = canPurchase(true) and hasEnoughMoneyForPurchase()
	if not canMakePurchase then
		local retries = 40
		if overrideRetries then
			retries = overrideRetries
		end
		while retries > 0 and not canMakePurchase do
			wait(0.5)
			canMakePurchase = canPurchase(true) and hasEnoughMoneyForPurchase()
			retries = retries - 1
		end
	end

	return canMakePurchase
end

function nativePurchaseFinished(wasPurchased)
	if wasPurchased then
		local isPurchasing = retryPurchase()
		if isPurchasing then
			onAcceptPurchase()
		else
			onPurchaseFailed(PURCHASE_FAILED.DEFAULT_ERROR)
		end
	else
		onPurchaseFailed(PURCHASE_FAILED.DID_NOT_BUY_ROBUX)
		stopPurchaseAnimation()
	end
end

local function onBuyRobuxPrompt()
	if purchaseState ~= PURCHASE_STATE.BUYROBUX then
		return
	end
	if RunService:IsStudio() then
		warn("Can't buy R$ in Studio.")
		return
	end

	purchaseState = PURCHASE_STATE.BUYINGROBUX

	if IsVRMode then
		showRemoveVRHeadsetNotice()
	else
		startPurchaseAnimation()
	end
	if IsNativePurchasing then
		if platform == Enum.Platform.XBoxOne then
			spawn(function()
				local PlatformService = nil
				pcall(function() PlatformService = game:GetService('PlatformService') end)
				if PlatformService then
					local platformPurchaseReturnInt = -1
					local purchaseCallSuccess, purchaseErrorMsg = pcall(function()
						platformPurchaseReturnInt = PlatformService:BeginPlatformStorePurchase(ThirdPartyProductName)
					end)
					if purchaseCallSuccess then
						nativePurchaseFinished(platformPurchaseReturnInt == 0)
					else
						nativePurchaseFinished(purchaseCallSuccess)
					end
				end
			end)
		else
			MarketplaceService:PromptNativePurchase(Players.LocalPlayer, ThirdPartyProductName)
		end
	else
		IsCheckingPlayerFunds = true
		GuiService:OpenBrowserWindow(BASE_URL.."Upgrades/Robux.aspx")
	end
	MarketplaceService:ReportRobuxUpsellStarted()
end

local function onUpgradeBCPrompt()
	if purchaseState ~= PURCHASE_STATE.BUYBC then
		return
	end

	IsCheckingPlayerFunds = true
	GuiService:OpenBrowserWindow(BASE_URL.."Upgrades/BuildersClubMemberships.aspx")
end

function enableControllerInput()
	local cas = game:GetService("ContextActionService")

	--accept the purchase when the user presses the a button
	cas:BindCoreAction(
		CONTROLLER_CONFIRM_ACTION_NAME,
		function(actionName, inputState, inputObject)
			if inputState ~= Enum.UserInputState.Begin then return end
			
			if purchaseState == PURCHASE_STATE.SUCCEEDED then
				onPromptEnded()
			elseif purchaseState == PURCHASE_STATE.FAILED then
				onPromptEnded()
			elseif purchaseState == PURCHASE_STATE.BUYITEM then
				onAcceptPurchase()
			elseif purchaseState == PURCHASE_STATE.BUYROBUX then
				onBuyRobuxPrompt()
			elseif  purchaseState == PURCHASE_STATE.BUYBC then
				onUpgradeBCPrompt()
			end
		end,
		false,
		Enum.KeyCode.ButtonA
	)

	--cancel the purchase when the user presses the b button
	cas:BindCoreAction(
		CONTROLLER_CANCEL_ACTION_NAME,
		function(actionName, inputState, inputObject)
			if inputState ~= Enum.UserInputState.Begin then return end

			if (OkPurchasedButton.Visible or OkButton.Visible or CancelButton.Visible) and (not PurchaseFrame.Visible) then
				onPromptEnded(false)
			end
		end,
		false,
		Enum.KeyCode.ButtonB
	)
end

function disableControllerInput()
	local cas = game:GetService("ContextActionService")
	cas:UnbindCoreAction(CONTROLLER_CONFIRM_ACTION_NAME)
	cas:UnbindCoreAction(CONTROLLER_CANCEL_ACTION_NAME)
end

function showGamepadButtons()
	for _, button in pairs(GAMEPAD_BUTTONS) do
		button.Visible = true
	end
end

function hideGamepadButtons()
	for _, button in pairs(GAMEPAD_BUTTONS) do
		button.Visible = false
	end
end

function valueInTable(val, tab)
	for _, v in pairs(tab) do
		if v == val then
			return true
		end
	end
	return false
end

function onInputChanged(inputObject)
	local input = inputObject.UserInputType
	local inputs = Enum.UserInputType
	if valueInTable(input, {inputs.Gamepad1, inputs.Gamepad2, inputs.Gamepad3, inputs.Gamepad4}) then
		if inputObject.KeyCode == Enum.KeyCode.Thumbstick1 or inputObject.KeyCode == Enum.KeyCode.Thumbstick2 then
			if math.abs(inputObject.Position.X) > 0.1 or math.abs(inputObject.Position.Z) > 0.1 or math.abs(inputObject.Position.Y) > 0.1 then
				showGamepadButtons()
			end
		else
			showGamepadButtons()
		end
	else
		hideGamepadButtons()
	end
end
UserInputService.InputChanged:connect(onInputChanged)
UserInputService.InputBegan:connect(onInputChanged)
hideGamepadButtons()

--[[ Event Connections ]]--
local buttonEvents = {}

local function disconnectButtonEvents()
	for key, conn in pairs(buttonEvents) do
		conn:disconnect()
	end
	buttonEvents = {}
end

local function connectButtonEvents()
	disconnectButtonEvents()

	local currentGui = getCurrentGui()

	buttonEvents.Cancel = currentGui.CancelButton.MouseButton1Click:connect(function()
		if IsCurrentlyPurchasing then return end
		onPromptEnded(false)
	end)
	buttonEvents.Buy = currentGui.BuyButton.MouseButton1Click:connect(onAcceptPurchase)
	buttonEvents.Free = currentGui.FreeButton.MouseButton1Click:connect(onAcceptPurchase)
	buttonEvents.Ok = currentGui.OkButton.MouseButton1Click:connect(function()
		if purchaseState == PURCHASE_STATE.FAILED then
			onPromptEnded(false)
		end
	end)
	buttonEvents.OkPurchased = currentGui.OkPurchasedButton.MouseButton1Click:connect(function()
		if purchaseState == PURCHASE_STATE.SUCCEEDED then
			onPromptEnded(true)
		end
	end)
	buttonEvents.BuyRobux = currentGui.BuyRobuxButton.MouseButton1Click:connect(onBuyRobuxPrompt)
	buttonEvents.BuyBC = currentGui.BuyBCButton.MouseButton1Click:connect(onUpgradeBCPrompt)
end

connectButtonEvents() --Connect the 2D button events.

MarketplaceService.PromptProductPurchaseRequested:connect(function(player, productId, equipIfPurchased, currencyType)
	onPurchasePrompt(player, nil, equipIfPurchased, currencyType, productId)
end)
MarketplaceService.PromptPurchaseRequested:connect(function(player, assetId, equipIfPurchased, currencyType)
	onPurchasePrompt(player, assetId, equipIfPurchased, currencyType, nil)
end)
MarketplaceService.ServerPurchaseVerification:connect(function(serverResponseTable)
	if not serverResponseTable then
		onPurchaseFailed(PURCHASE_FAILED.DEFAULT_ERROR)
		return
	end

	if serverResponseTable["playerId"] and tonumber(serverResponseTable["playerId"]) == Players.LocalPlayer.userId then
		onPurchaseSuccess()
	end
end)

GuiService.BrowserWindowClosed:connect(function()
	if IsCheckingPlayerFunds then
		retryPurchase(4)
	end

	onPurchaseFailed(PURCHASE_FAILED.DID_NOT_BUY_ROBUX)
	stopPurchaseAnimation()
end)

if IsNativePurchasing then
	MarketplaceService.NativePurchaseFinished:connect(function(player, productId, wasPurchased)
		nativePurchaseFinished(wasPurchased)
	end)
end

local function switchGui(activeGui, newVRMode)
	if getCurrentGui() == activeGui then
		return
	end

	local assetId, productId, currencyType, equipOnPurchase = PurchaseData.AssetId, PurchaseData.ProductId, PurchaseData.CurrencyType, PurchaseData.EquipOnPurchase

	closePurchaseDialog()

	IsVRMode = newVRMode
	
	if activeGui then
		--Restart the state in case we changed in the middle of a purchase or dialog.
		if IsCurrentlyPrompting then
			setInitialPurchaseData(assetId, productId, currencyType, equipOnPurchase)
			showPurchasePrompt()
		end
		if IsCurrentlyPurchasing then
			setInitialPurchaseData(assetId, productId, currencyType, equipOnPurchase)
			startPurchaseAnimation()
		end
		connectButtonEvents()
	else
		error("Argument 1 to switchGui(activeGui) should be a valid Gui table.")
	end
end

if vrPurchasePromptsEnabled then
	local function onVREnabled(vrEnabled) 
		if vrEnabled == IsVRMode then
			return
		end
		if vrEnabled then
			if not Gui3D then
				Gui3D = create3DGui()
			end
			switchGui(Gui3D, true)
		else
			switchGui(Gui2D, false)
		end
	end

	spawn(function()
		repeat wait() until Players.LocalPlayer ~= nil
		onVREnabled(UserInputService.VREnabled)
	end)

	UserInputService.Changed:connect(function(prop)
		if prop == "VREnabled" then
			onVREnabled(UserInputService.VREnabled)
		end
	end)
end