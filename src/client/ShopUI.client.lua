--[[
	ShopUI — Trail shop + game pass shop for Tower Obby
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObbyConfig = require(Shared:WaitForChild("ObbyConfig"))
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
local BuyTrail = Remotes:WaitForChild("BuyTrail", 15)
local EquipTrail = Remotes:WaitForChild("EquipTrail", 15)
local TrailUpdate = Remotes:WaitForChild("TrailUpdate", 15)

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local ownedTrails = {}
local equippedTrail = ""

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Name = "ShopFrame"
frame.Size = UDim2.new(0, 350, 0, 400)
frame.Position = UDim2.new(0.5, -175, 0.5, -200)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
local stroke = Instance.new("UIStroke", frame); stroke.Color = Color3.fromRGB(255, 215, 0); stroke.Thickness = 2

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "TRAIL SHOP"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.TextSize = 22
title.Font = Enum.Font.GothamBold
title.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function() frame.Visible = false end)

-- Unequip button
local unequipBtn = Instance.new("TextButton")
unequipBtn.Size = UDim2.new(1, -20, 0, 30)
unequipBtn.Position = UDim2.new(0, 10, 0, 42)
unequipBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
unequipBtn.BorderSizePixel = 0
unequipBtn.Text = "Unequip Trail"
unequipBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
unequipBtn.TextSize = 13
unequipBtn.Font = Enum.Font.Gotham
unequipBtn.Parent = frame
Instance.new("UICorner", unequipBtn).CornerRadius = UDim.new(0, 6)
unequipBtn.MouseButton1Click:Connect(function()
	EquipTrail:FireServer("")
end)

-- Trail list
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -85)
scroll.Position = UDim2.new(0, 10, 0, 78)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = scroll

local function buildTrailList()
	-- Clear existing
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	for i, trail in ipairs(ObbyConfig.Trails) do
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 55)
		card.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
		card.BorderSizePixel = 0
		card.LayoutOrder = i
		card.Parent = scroll
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

		-- Color preview
		local preview = Instance.new("Frame")
		preview.Size = UDim2.new(0, 30, 0, 30)
		preview.Position = UDim2.new(0, 8, 0.5, -15)
		preview.BackgroundColor3 = trail.color
		preview.BorderSizePixel = 0
		preview.Parent = card
		Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 6)

		-- Name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.45, 0, 0, 20)
		nameLabel.Position = UDim2.new(0, 48, 0, 5)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = trail.name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 14
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = card

		-- Price
		local priceText = trail.vip and "VIP" or (trail.price .. " coins")
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Size = UDim2.new(0.45, 0, 0, 20)
		priceLabel.Position = UDim2.new(0, 48, 0, 25)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = priceText
		priceLabel.TextColor3 = trail.vip and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 215, 0)
		priceLabel.TextSize = 12
		priceLabel.Font = Enum.Font.Gotham
		priceLabel.TextXAlignment = Enum.TextXAlignment.Left
		priceLabel.Parent = card

		-- Action button
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 80, 0, 30)
		btn.Position = UDim2.new(1, -90, 0.5, -15)
		btn.BorderSizePixel = 0
		btn.TextSize = 12
		btn.Font = Enum.Font.GothamBold
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Parent = card
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

		local isOwned = false
		for _, owned in ipairs(ownedTrails) do
			if owned == trail.id then isOwned = true break end
		end

		if equippedTrail == trail.id then
			btn.Text = "EQUIPPED"
			btn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		elseif isOwned then
			btn.Text = "EQUIP"
			btn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
			btn.MouseButton1Click:Connect(function()
				EquipTrail:FireServer(trail.id)
			end)
		else
			btn.Text = "BUY"
			btn.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
			btn.MouseButton1Click:Connect(function()
				BuyTrail:FireServer(trail.id)
			end)
		end
	end

	scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end

-- Update when trails change
TrailUpdate.OnClientEvent:Connect(function(owned, equipped)
	ownedTrails = owned or {}
	equippedTrail = equipped or ""
	buildTrailList()
end)

_G.ShowShopUI = function()
	frame.Visible = true
	buildTrailList()
end

-- Initial build
task.delay(3, buildTrailList)

print("[ShopUI] Initialized")
