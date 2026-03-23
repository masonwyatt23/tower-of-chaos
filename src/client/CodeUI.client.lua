--[[
	CodeUI — Promo code input for Tower Obby
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
local RedeemCode = Remotes:WaitForChild("RedeemCode", 15)
local CodeResult = Remotes:WaitForChild("CodeResult", 15)

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CodeGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Name = "CodeFrame"
frame.Size = UDim2.new(0, 280, 0, 140)
frame.Position = UDim2.new(0.5, -140, 0.5, -70)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
local s = Instance.new("UIStroke", frame); s.Color = Color3.fromRGB(100, 150, 255); s.Thickness = 2

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.Position = UDim2.new(0, 0, 0, 5)
title.BackgroundTransparency = 1
title.Text = "ENTER CODE"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 25, 0, 25)
closeBtn.Position = UDim2.new(1, -28, 0, 3)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function() frame.Visible = false end)

local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(1, -20, 0, 30)
textBox.Position = UDim2.new(0, 10, 0, 35)
textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
textBox.BorderSizePixel = 0
textBox.Text = ""
textBox.PlaceholderText = "Enter code..."
textBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
textBox.TextSize = 15
textBox.Font = Enum.Font.Gotham
textBox.ClearTextOnFocus = true
textBox.Parent = frame
Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 6)

local redeemBtn = Instance.new("TextButton")
redeemBtn.Size = UDim2.new(1, -20, 0, 30)
redeemBtn.Position = UDim2.new(0, 10, 0, 72)
redeemBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
redeemBtn.BorderSizePixel = 0
redeemBtn.Text = "REDEEM"
redeemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
redeemBtn.TextSize = 15
redeemBtn.Font = Enum.Font.GothamBold
redeemBtn.Parent = frame
Instance.new("UICorner", redeemBtn).CornerRadius = UDim.new(0, 6)

local resultLabel = Instance.new("TextLabel")
resultLabel.Size = UDim2.new(1, -20, 0, 20)
resultLabel.Position = UDim2.new(0, 10, 0, 108)
resultLabel.BackgroundTransparency = 1
resultLabel.Text = ""
resultLabel.TextSize = 13
resultLabel.Font = Enum.Font.GothamBold
resultLabel.Parent = frame

redeemBtn.MouseButton1Click:Connect(function()
	local code = textBox.Text
	if code == "" then return end
	RedeemCode:FireServer(code)
	redeemBtn.Text = "..."
end)

_G.ShowCodeUI = function() frame.Visible = true end

CodeResult.OnClientEvent:Connect(function(success, message)
	redeemBtn.Text = "REDEEM"
	resultLabel.Text = message
	resultLabel.TextColor3 = success and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
	task.delay(3, function() resultLabel.Text = "" end)
end)

print("[CodeUI] Initialized")
