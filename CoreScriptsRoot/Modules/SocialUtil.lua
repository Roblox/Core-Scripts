--[[
	// FileName:    SocialUtil.lua
	// Written by:  TheGamer101
	// Description: Utility code related to social features.
]]
local SocialUtil = {}

--[[ Services ]]--
local Players = game:GetService("Players")

--[[ Constants ]]--
local THUMBNAIL_SIZE_MAP = {
	[Enum.ThumbnailSize.Size48x48]   =  48,
	[Enum.ThumbnailSize.Size180x180] = 180,
	[Enum.ThumbnailSize.Size420x420] = 420
}

local THUMBNAIL_FALLBACK_URLS = {
	[Enum.ThumbnailType.HeadShot] = "https://www.roblox.com/headshot-thumbnail/image?width=%d&height=%d&format=png&userId=%d",
	[Enum.ThumbnailType.AvatarBust] = "https://www.roblox.com/bust-thumbnail/image?width=%d&height=%d&format=png&userId=%d",
	[Enum.ThumbnailType.AvatarThumbnail] = "https://www.roblox.com/avatar-thumbnail/image?width=%d&height=%d&format=png&userId=%d"
}

local GET_PLAYER_IMAGE_DEFAULT_TIMEOUT = 5
local DEFAULT_THUMBNAIL_SIZE = Enum.ThumbnailSize.Size48x48
local DEFAULT_THUMBNAIL_TYPE = Enum.ThumbnailType.AvatarThumbnail
local GET_USER_THUMBNAIL_ASYNC_RETRY_TIME = 1

--[[ Utility ]]--
local function CreateSignal()
	local sig = {}

	local mSignaler = Instance.new('BindableEvent')

	local mArgData = nil
	local mArgDataCount = nil

	function sig:fire(...)
		mArgData = {...}
		mArgDataCount = select('#', ...)
		mSignaler:Fire()
	end

	function sig:connect(f)
		if not f then error("connect(nil)", 2) end
		return mSignaler.Event:Connect(function()
			f(unpack(mArgData, 1, mArgDataCount))
		end)
	end

	function sig:wait()
		mSignaler.Event:wait()
		if not mArgData then
			error("Missing arg data, likely due to :TweenSize/Position corrupting threadrefs.")
		end
		return unpack(mArgData, 1, mArgDataCount)
	end

	return sig
end

--[[ Functions ]]--

-- The thumbanil isn't guaranteed to be generated, this will just create the url using string.format and immediately return it.
function SocialUtil.GetFallbackPlayerImageUrl(userId, thumbnailSize, thumbnailType)
	local sizeNumber = THUMBNAIL_SIZE_MAP[thumbnailSize]
	if not sizeNumber then
		warn("SocialUtil.GetPlayerImage: No thumbnail size in map for " ..tostring(thumbnailSize))
		sizeNumber = THUMBNAIL_SIZE_MAP[DEFAULT_THUMBNAIL_SIZE]
	end
	
	local thumbnailFallbackUrl = THUMBNAIL_FALLBACK_URLS[thumbnailType]
	if not thumbnailFallbackUrl then
		warn("SocialUtil.GetPlayerImage: No thumbnail fallback url in map for " ..tostring(thumbnailType))
		thumbnailFallbackUrl = THUMBNAIL_FALLBACK_URLS[DEFAULT_THUMBNAIL_TYPE]
	end
	
	return thumbnailFallbackUrl:format(sizeNumber, sizeNumber, userId)
end

-- This function will wait for up to timeOut seconds for the thumbnail to be generated.
-- It will just return a fallback (probably N/A) url if it's not generated in time.
function SocialUtil.GetPlayerImage(userId, thumbnailSize, thumbnailType, timeOut)
	if not thumbnailSize then thumbnailSize = DEFAULT_THUMBNAIL_SIZE end
	if not thumbnailType then thumbnailType = DEFAULT_THUMBNAIL_TYPE end
	if not timeOut then timeOut = GET_PLAYER_IMAGE_DEFAULT_TIMEOUT end

	local finished = false
	local finishedSignal = CreateSignal() -- fired with one parameter: imageUrl

	delay(timeOut, function()
		if not finished then
			finished = true
			finishedSignal:fire(SocialUtil.GetFallbackPlayerImageUrl(userId, thumbnailSize, thumbnailType))
		end
	end)

	spawn(function()
		while true do
			if finished then
				break
			end
		
			local thumbnailUrl, isFinal = Players:GetUserThumbnailAsync(userId, thumbnailType, thumbnailSize)

			if finished then
				break
			end

			if isFinal then
				finished = true
				finishedSignal:fire(thumbnailUrl)
				break
			end
			
			wait(GET_USER_THUMBNAIL_ASYNC_RETRY_TIME)
		end
	end)

	local imageUrl = finishedSignal:wait()
	return imageUrl
end

return SocialUtil
