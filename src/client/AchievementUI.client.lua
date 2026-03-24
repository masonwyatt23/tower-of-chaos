--[[
	AchievementUI — Achievement unlock banner
	Shows a sliding notification when achievements are earned.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Create ScreenGui for achievement banners
local achievementGui = Instance.new("ScreenGui")
achievementGui.Name = "AchievementGUI"
achievementGui.ResetOnSpawn = false
achievementGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
achievementGui.Parent = PlayerGui

-- Format coin amounts with commas
local function formatCoins(amount)
	local formatted = tostring(math.floor(amount))
	local k
	while true do
		formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return formatted
end

-- Show achievement banner sliding in from the top
local function showAchievementBanner(name, reward)
	local banner = Instance.new("Frame")
	banner.Size = UDim2.new(0, 400, 0, 60)
	banner.Position = UDim2.new(0.5, -200, 0, -60)
	banner.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
	banner.BorderSizePixel = 0
	banner.ZIndex = 50
	banner.Parent = achievementGui

	local bannerCorner = Instance.new("UICorner")
	bannerCorner.CornerRadius = UDim.new(0, 10)
	bannerCorner.Parent = banner

	local bannerStroke = Instance.new("UIStroke")
	bannerStroke.Color = Color3.fromRGB(255, 215, 0)
	bannerStroke.Thickness = 2
	bannerStroke.Parent = banner

	local titleText = Instance.new("TextLabel")
	titleText.Size = UDim2.new(1, -20, 0, 25)
	titleText.Position = UDim2.new(0, 10, 0, 5)
	titleText.BackgroundTransparency = 1
	titleText.Text = "ACHIEVEMENT UNLOCKED"
	titleText.TextColor3 = Color3.fromRGB(255, 215, 0)
	titleText.TextSize = 14
	titleText.Font = Enum.Font.GothamBold
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.ZIndex = 51
	titleText.Parent = banner

	local nameText = Instance.new("TextLabel")
	nameText.Size = UDim2.new(0.6, 0, 0, 25)
	nameText.Position = UDim2.new(0, 10, 0, 30)
	nameText.BackgroundTransparency = 1
	nameText.Text = name
	nameText.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameText.TextSize = 18
	nameText.Font = Enum.Font.GothamBold
	nameText.TextXAlignment = Enum.TextXAlignment.Left
	nameText.ZIndex = 51
	nameText.Parent = banner

	local rewardText = Instance.new("TextLabel")
	rewardText.Size = UDim2.new(0.35, 0, 0, 25)
	rewardText.Position = UDim2.new(0.6, 0, 0, 30)
	rewardText.BackgroundTransparency = 1
	rewardText.Text = "+" .. formatCoins(reward) .. " Coins"
	rewardText.TextColor3 = Color3.fromRGB(100, 255, 100)
	rewardText.TextSize = 16
	rewardText.Font = Enum.Font.GothamBold
	rewardText.TextXAlignment = Enum.TextXAlignment.Right
	rewardText.ZIndex = 51
	rewardText.Parent = banner

	-- Slide in from top
	local slideIn = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(banner, slideIn, {Position = UDim2.new(0.5, -200, 0, 10)}):Play()

	-- Slide out after 4 seconds
	task.delay(4, function()
		local slideOut = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local tween = TweenService:Create(banner, slideOut, {Position = UDim2.new(0.5, -200, 0, -70)})
		tween:Play()
		tween.Completed:Connect(function() banner:Destroy() end)
	end)
end

-- Listen for achievement unlocks from server
task.spawn(function()
	local AchievementUnlocked = Remotes:WaitForChild("AchievementUnlocked", 10)
	if AchievementUnlocked then
		AchievementUnlocked.OnClientEvent:Connect(function(info)
			if info then
				showAchievementBanner(info.name, info.reward)
			end
		end)
	end
end)

print("[AchievementUI] Initialized")
