--[[
	ObbyUI — Main HUD for Tower Obby
	Shows: stage counter, round timer, coins, event countdown
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
local RoundStart = Remotes:WaitForChild("RoundStart", 15)
local RoundEnd = Remotes:WaitForChild("RoundEnd", 15)
local PlayerWin = Remotes:WaitForChild("PlayerWin", 15)
local StageReached = Remotes:WaitForChild("StageReached", 15)
local UpdateCoins = Remotes:WaitForChild("UpdateCoins", 15)
local EventInfo = Remotes:WaitForChild("EventInfo", 15)

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- State
local currentStage = 0
local totalStages = 0
local roundTimeRemaining = 0
local coins = 0
local roundActive = false

-- Build HUD
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ObbyHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- Stage counter (top center)
local stageFrame = Instance.new("Frame")
stageFrame.Size = UDim2.new(0, 250, 0, 70)
stageFrame.Position = UDim2.new(0.5, -125, 0, 10)
stageFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
stageFrame.BackgroundTransparency = 0.15
stageFrame.BorderSizePixel = 0
stageFrame.Parent = screenGui
Instance.new("UICorner", stageFrame).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", stageFrame).Color = Color3.fromRGB(255, 215, 0)

local stageLabel = Instance.new("TextLabel")
stageLabel.Name = "StageLabel"
stageLabel.Size = UDim2.new(1, 0, 0.55, 0)
stageLabel.Position = UDim2.new(0, 0, 0, 5)
stageLabel.BackgroundTransparency = 1
stageLabel.Text = "Stage 0/0"
stageLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
stageLabel.TextSize = 28
stageLabel.Font = Enum.Font.GothamBold
stageLabel.Parent = stageFrame

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(1, 0, 0.4, 0)
timerLabel.Position = UDim2.new(0, 0, 0.55, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "Waiting..."
timerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
timerLabel.TextSize = 16
timerLabel.Font = Enum.Font.Gotham
timerLabel.Parent = stageFrame

-- Coins display (top left)
local coinFrame = Instance.new("Frame")
coinFrame.Size = UDim2.new(0, 160, 0, 40)
coinFrame.Position = UDim2.new(0, 10, 0, 10)
coinFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
coinFrame.BackgroundTransparency = 0.15
coinFrame.BorderSizePixel = 0
coinFrame.Parent = screenGui
Instance.new("UICorner", coinFrame).CornerRadius = UDim.new(0, 8)

local coinLabel = Instance.new("TextLabel")
coinLabel.Size = UDim2.new(1, -10, 1, 0)
coinLabel.Position = UDim2.new(0, 10, 0, 0)
coinLabel.BackgroundTransparency = 1
coinLabel.Text = "Coins: 0"
coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinLabel.TextSize = 20
coinLabel.Font = Enum.Font.GothamBold
coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.Parent = coinFrame

-- Event banner (top, hidden by default)
local eventBanner = Instance.new("Frame")
eventBanner.Name = "EventBanner"
eventBanner.Size = UDim2.new(0.6, 0, 0, 35)
eventBanner.Position = UDim2.new(0.2, 0, 0, 85)
eventBanner.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
eventBanner.BorderSizePixel = 0
eventBanner.Visible = false
eventBanner.Parent = screenGui
Instance.new("UICorner", eventBanner).CornerRadius = UDim.new(0, 8)

local eventLabel = Instance.new("TextLabel")
eventLabel.Size = UDim2.new(1, 0, 1, 0)
eventLabel.BackgroundTransparency = 1
eventLabel.Text = ""
eventLabel.TextColor3 = Color3.fromRGB(30, 30, 30)
eventLabel.TextSize = 16
eventLabel.Font = Enum.Font.GothamBold
eventLabel.Parent = eventBanner

-- Win notification (center, hidden)
local winFrame = Instance.new("Frame")
winFrame.Name = "WinNotification"
winFrame.Size = UDim2.new(0, 400, 0, 80)
winFrame.Position = UDim2.new(0.5, -200, 0.3, 0)
winFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
winFrame.BackgroundTransparency = 0.1
winFrame.BorderSizePixel = 0
winFrame.Visible = false
winFrame.Parent = screenGui
Instance.new("UICorner", winFrame).CornerRadius = UDim.new(0, 14)

local winLabel = Instance.new("TextLabel")
winLabel.Size = UDim2.new(1, 0, 1, 0)
winLabel.BackgroundTransparency = 1
winLabel.Text = ""
winLabel.TextColor3 = Color3.fromRGB(30, 30, 30)
winLabel.TextSize = 24
winLabel.Font = Enum.Font.GothamBold
winLabel.Parent = winFrame

-- Skip button (bottom right)
local skipBtn = Instance.new("TextButton")
skipBtn.Name = "SkipButton"
skipBtn.Size = UDim2.new(0, 140, 0, 45)
skipBtn.Position = UDim2.new(1, -150, 1, -55)
skipBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
skipBtn.BorderSizePixel = 0
skipBtn.Text = "SKIP STAGE"
skipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
skipBtn.TextSize = 16
skipBtn.Font = Enum.Font.GothamBold
skipBtn.Parent = screenGui
Instance.new("UICorner", skipBtn).CornerRadius = UDim.new(0, 8)

skipBtn.MouseButton1Click:Connect(function()
	local SkipStage = Remotes:FindFirstChild("SkipStage")
	if SkipStage then
		SkipStage:FireServer()
	end
end)

-- Bottom buttons: SHOP, CODES
local shopBtn = Instance.new("TextButton")
shopBtn.Size = UDim2.new(0, 100, 0, 40)
shopBtn.Position = UDim2.new(0, 10, 1, -50)
shopBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
shopBtn.BorderSizePixel = 0
shopBtn.Text = "SHOP"
shopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
shopBtn.TextSize = 16
shopBtn.Font = Enum.Font.GothamBold
shopBtn.Parent = screenGui
Instance.new("UICorner", shopBtn).CornerRadius = UDim.new(0, 8)

shopBtn.MouseButton1Click:Connect(function()
	if _G.ShowShopUI then _G.ShowShopUI() end
end)

local codesBtn = Instance.new("TextButton")
codesBtn.Size = UDim2.new(0, 100, 0, 40)
codesBtn.Position = UDim2.new(0, 120, 1, -50)
codesBtn.BackgroundColor3 = Color3.fromRGB(150, 80, 200)
codesBtn.BorderSizePixel = 0
codesBtn.Text = "CODES"
codesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
codesBtn.TextSize = 16
codesBtn.Font = Enum.Font.GothamBold
codesBtn.Parent = screenGui
Instance.new("UICorner", codesBtn).CornerRadius = UDim.new(0, 8)

codesBtn.MouseButton1Click:Connect(function()
	if _G.ShowCodeUI then _G.ShowCodeUI() end
end)

-- Deaths counter (top right)
local deathFrame = Instance.new("Frame")
deathFrame.Size = UDim2.new(0, 120, 0, 35)
deathFrame.Position = UDim2.new(1, -130, 0, 10)
deathFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
deathFrame.BackgroundTransparency = 0.15
deathFrame.BorderSizePixel = 0
deathFrame.Parent = screenGui
Instance.new("UICorner", deathFrame).CornerRadius = UDim.new(0, 8)

local deathLabel = Instance.new("TextLabel")
deathLabel.Name = "DeathLabel"
deathLabel.Size = UDim2.new(1, -10, 1, 0)
deathLabel.Position = UDim2.new(0, 10, 0, 0)
deathLabel.BackgroundTransparency = 1
deathLabel.Text = "Deaths: 0"
deathLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
deathLabel.TextSize = 16
deathLabel.Font = Enum.Font.GothamBold
deathLabel.TextXAlignment = Enum.TextXAlignment.Left
deathLabel.Parent = deathFrame

-- Track deaths locally
local deaths = 0
player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		deaths = deaths + 1
		deathLabel.Text = "Deaths: " .. deaths
	end)
end)

-- Event handlers
RoundStart.OnClientEvent:Connect(function(numStages, duration)
	totalStages = numStages
	currentStage = 0
	roundTimeRemaining = duration
	roundActive = true
	stageLabel.Text = "Stage 0/" .. totalStages
	timerLabel.Text = Utils.formatTime(duration)
end)

RoundEnd.OnClientEvent:Connect(function(intermission)
	roundActive = false
	stageLabel.Text = "Round Over!"
	timerLabel.Text = "Next round in " .. intermission .. "s"
end)

StageReached.OnClientEvent:Connect(function(stage, total)
	currentStage = stage
	totalStages = total
	stageLabel.Text = "Stage " .. stage .. "/" .. total
end)

UpdateCoins.OnClientEvent:Connect(function(newCoins)
	coins = newCoins
	coinLabel.Text = "Coins: " .. Utils.formatNumber(coins)
end)

PlayerWin.OnClientEvent:Connect(function(playerName, isFirst, coinsEarned)
	local text = playerName .. " reached the top!"
	if isFirst then text = playerName .. " FIRST PLACE! +" .. coinsEarned .. " coins!" end
	winLabel.Text = text
	winFrame.Visible = true
	task.delay(4, function() winFrame.Visible = false end)
end)

EventInfo.OnClientEvent:Connect(function(info)
	if info.active then
		eventBanner.Visible = true
		eventLabel.Text = "EVENT: " .. info.name .. " — " .. Utils.formatTime(info.timeRemaining) .. " remaining"
	else
		if info.timeUntilNext and info.timeUntilNext < 3600 then
			eventBanner.Visible = true
			eventBanner.BackgroundColor3 = Color3.fromRGB(100, 100, 150)
			eventLabel.Text = "Next Event: " .. (info.nextEventName or "") .. " in " .. Utils.formatTime(info.timeUntilNext)
			eventLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			eventBanner.Visible = false
		end
	end
end)

-- Timer countdown
task.spawn(function()
	while true do
		task.wait(1)
		if roundActive and roundTimeRemaining > 0 then
			roundTimeRemaining = roundTimeRemaining - 1
			timerLabel.Text = Utils.formatTime(roundTimeRemaining)
		end
	end
end)

print("[ObbyUI] Initialized")
