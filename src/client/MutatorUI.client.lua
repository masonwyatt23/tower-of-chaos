--[[
	MutatorUI — Mutator voting panel, wheel animation, and active mutator badges
	Shows during intermission for voting, animated result reveal, and
	persistent badges during rounds.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
local MutatorCandidates = Remotes:WaitForChild("MutatorCandidates", 15)
local MutatorVote = Remotes:WaitForChild("MutatorVote", 15)
local MutatorResult = Remotes:WaitForChild("MutatorResult", 15)
local ActiveMutators = Remotes:WaitForChild("ActiveMutators", 15)

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- State
local hasVoted = false
local voteButtons = {}
local voteCountdown = 0

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MutatorHUD"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 5
screenGui.Parent = PlayerGui

--------------------------------------------------------------------------------
-- VOTE PANEL
--------------------------------------------------------------------------------

local votePanel = Instance.new("Frame")
votePanel.Name = "VotePanel"
votePanel.Size = UDim2.new(0, 400, 0, 260)
votePanel.Position = UDim2.new(0.5, -200, 0.5, -130)
votePanel.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
votePanel.BackgroundTransparency = 0.08
votePanel.BorderSizePixel = 0
votePanel.Visible = false
votePanel.ZIndex = 50
votePanel.Parent = screenGui
Instance.new("UICorner", votePanel).CornerRadius = UDim.new(0, 14)

local voteStroke = Instance.new("UIStroke")
voteStroke.Color = Color3.fromRGB(180, 120, 255)
voteStroke.Thickness = 2
voteStroke.Parent = votePanel

-- Title
local voteTitle = Instance.new("TextLabel")
voteTitle.Name = "Title"
voteTitle.Size = UDim2.new(1, 0, 0, 40)
voteTitle.Position = UDim2.new(0, 0, 0, 5)
voteTitle.BackgroundTransparency = 1
voteTitle.Text = "VOTE FOR A MUTATOR!"
voteTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
voteTitle.TextSize = 20
voteTitle.Font = Enum.Font.GothamBold
voteTitle.ZIndex = 51
voteTitle.Parent = votePanel

-- Timer label
local voteTimerLabel = Instance.new("TextLabel")
voteTimerLabel.Name = "Timer"
voteTimerLabel.Size = UDim2.new(1, 0, 0, 25)
voteTimerLabel.Position = UDim2.new(0, 0, 1, -30)
voteTimerLabel.BackgroundTransparency = 1
voteTimerLabel.Text = "10s remaining"
voteTimerLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
voteTimerLabel.TextSize = 14
voteTimerLabel.Font = Enum.Font.Gotham
voteTimerLabel.ZIndex = 51
voteTimerLabel.Parent = votePanel

-- Create 3 vote button slots
local function createVoteButton(index)
	local btn = Instance.new("TextButton")
	btn.Name = "VoteBtn_" .. index
	btn.Size = UDim2.new(0, 350, 0, 45)
	btn.Position = UDim2.new(0.5, -175, 0, 50 + (index - 1) * 55)
	btn.BackgroundColor3 = Color3.fromRGB(60, 40, 100)
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 16
	btn.Font = Enum.Font.GothamBold
	btn.ZIndex = 52
	btn.AutoButtonColor = true
	btn.Parent = votePanel
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(120, 80, 180)
	btnStroke.Thickness = 1
	btnStroke.Parent = btn

	return btn
end

for i = 1, 3 do
	voteButtons[i] = createVoteButton(i)
end

--------------------------------------------------------------------------------
-- RESULT BANNER (wheel animation + result display)
--------------------------------------------------------------------------------

local resultBanner = Instance.new("Frame")
resultBanner.Name = "ResultBanner"
resultBanner.Size = UDim2.new(0, 500, 0, 70)
resultBanner.Position = UDim2.new(0.5, -250, 0.35, 0)
resultBanner.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
resultBanner.BackgroundTransparency = 0.08
resultBanner.BorderSizePixel = 0
resultBanner.Visible = false
resultBanner.ClipsDescendants = true
resultBanner.ZIndex = 60
resultBanner.Parent = screenGui
Instance.new("UICorner", resultBanner).CornerRadius = UDim.new(0, 14)

local resultStroke = Instance.new("UIStroke")
resultStroke.Color = Color3.fromRGB(255, 215, 0)
resultStroke.Thickness = 2
resultStroke.Parent = resultBanner

-- Wheel container (scrolls horizontally)
local wheelContainer = Instance.new("Frame")
wheelContainer.Name = "WheelContainer"
wheelContainer.Size = UDim2.new(0, 2000, 1, 0)
wheelContainer.Position = UDim2.new(0, 0, 0, 0)
wheelContainer.BackgroundTransparency = 1
wheelContainer.ZIndex = 61
wheelContainer.Parent = resultBanner

-- Result text (shown after wheel stops)
local resultText = Instance.new("TextLabel")
resultText.Name = "ResultText"
resultText.Size = UDim2.new(1, 0, 1, 0)
resultText.BackgroundTransparency = 1
resultText.Text = ""
resultText.TextColor3 = Color3.fromRGB(255, 215, 0)
resultText.TextSize = 22
resultText.Font = Enum.Font.GothamBold
resultText.ZIndex = 65
resultText.Visible = false
resultText.Parent = resultBanner

-- Pointer indicator (center line)
local pointer = Instance.new("Frame")
pointer.Name = "Pointer"
pointer.Size = UDim2.new(0, 3, 1, 0)
pointer.Position = UDim2.new(0.5, -1, 0, 0)
pointer.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
pointer.BorderSizePixel = 0
pointer.ZIndex = 63
pointer.Parent = resultBanner

--------------------------------------------------------------------------------
-- ACTIVE MUTATOR BADGES (top-right during round)
--------------------------------------------------------------------------------

local badgeContainer = Instance.new("Frame")
badgeContainer.Name = "MutatorBadges"
badgeContainer.Size = UDim2.new(0, 160, 0, 70)
badgeContainer.Position = UDim2.new(1, -170, 0, 50)
badgeContainer.BackgroundTransparency = 1
badgeContainer.BorderSizePixel = 0
badgeContainer.Visible = false
badgeContainer.ZIndex = 40
badgeContainer.Parent = screenGui

local badgeLayout = Instance.new("UIListLayout")
badgeLayout.FillDirection = Enum.FillDirection.Vertical
badgeLayout.Padding = UDim.new(0, 4)
badgeLayout.SortOrder = Enum.SortOrder.LayoutOrder
badgeLayout.Parent = badgeContainer

local function createBadge(name, order)
	local badge = Instance.new("Frame")
	badge.Name = "Badge_" .. order
	badge.Size = UDim2.new(1, 0, 0, 30)
	badge.BackgroundColor3 = Color3.fromRGB(100, 50, 180)
	badge.BackgroundTransparency = 0.15
	badge.BorderSizePixel = 0
	badge.LayoutOrder = order
	badge.Parent = badgeContainer
	Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 6)

	local badgeLabel = Instance.new("TextLabel")
	badgeLabel.Size = UDim2.new(1, -10, 1, 0)
	badgeLabel.Position = UDim2.new(0, 5, 0, 0)
	badgeLabel.BackgroundTransparency = 1
	badgeLabel.Text = name
	badgeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	badgeLabel.TextSize = 14
	badgeLabel.Font = Enum.Font.GothamBold
	badgeLabel.TextXAlignment = Enum.TextXAlignment.Left
	badgeLabel.ZIndex = 41
	badgeLabel.Parent = badge

	return badge
end

local function clearBadges()
	for _, child in ipairs(badgeContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function showBadges(mutators)
	clearBadges()
	if #mutators == 0 then
		badgeContainer.Visible = false
		return
	end
	for i, m in ipairs(mutators) do
		createBadge(m.name, i)
	end
	badgeContainer.Visible = true
end

--------------------------------------------------------------------------------
-- WHEEL ANIMATION
--------------------------------------------------------------------------------

local function playWheelAnimation(allNames, winnerNames, callback)
	-- Clear old wheel items
	for _, child in ipairs(wheelContainer:GetChildren()) do
		child:Destroy()
	end

	resultText.Visible = false
	resultBanner.Visible = true
	wheelContainer.Visible = true

	-- Build a long strip of mutator names
	local itemWidth = 160
	local totalItems = 30
	local items = {}
	for i = 1, totalItems do
		local name = allNames[((i - 1) % #allNames) + 1]
		local itemLabel = Instance.new("TextLabel")
		itemLabel.Size = UDim2.new(0, itemWidth, 1, 0)
		itemLabel.Position = UDim2.new(0, (i - 1) * itemWidth, 0, 0)
		itemLabel.BackgroundTransparency = 1
		itemLabel.Text = name
		itemLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
		itemLabel.TextSize = 18
		itemLabel.Font = Enum.Font.GothamBold
		itemLabel.ZIndex = 62
		itemLabel.Parent = wheelContainer
		table.insert(items, itemLabel)
	end

	-- Place the winner name near the end so wheel "lands" on it
	if winnerNames[1] then
		items[totalItems - 3].Text = winnerNames[1]
	end

	-- Resize container to fit
	wheelContainer.Size = UDim2.new(0, totalItems * itemWidth, 1, 0)

	-- Start position: show beginning
	local startX = 0
	-- End position: land on the winner (item totalItems-3), centered in banner
	local endX = -((totalItems - 3) * itemWidth - 250 + itemWidth / 2)

	wheelContainer.Position = UDim2.new(0, startX, 0, 0)

	-- Animate with deceleration (EaseOut)
	local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local tween = TweenService:Create(wheelContainer, tweenInfo, {
		Position = UDim2.new(0, endX, 0, 0)
	})
	tween:Play()

	tween.Completed:Connect(function()
		-- Brief pause, then show result text
		task.wait(0.5)
		wheelContainer.Visible = false

		local displayText = "MUTATORS: " .. winnerNames[1]
		if winnerNames[2] then
			displayText = displayText .. " + " .. winnerNames[2]
		end
		resultText.Text = displayText
		resultText.Visible = true

		-- Hide after 5 seconds
		task.delay(5, function()
			resultBanner.Visible = false
			resultText.Visible = false
		end)

		if callback then callback() end
	end)
end

--------------------------------------------------------------------------------
-- EVENT HANDLERS
--------------------------------------------------------------------------------

-- Receive vote candidates OR vote count update
MutatorCandidates.OnClientEvent:Connect(function(candidates, duration, voteCounts)
	-- Vote count update only
	if candidates == nil and voteCounts then
		for i, btn in ipairs(voteButtons) do
			local candidateId = btn:GetAttribute("MutatorId")
			if candidateId and voteCounts[candidateId] then
				local name = btn:GetAttribute("MutatorName") or ""
				btn.Text = name .. "  [" .. voteCounts[candidateId] .. " votes]"
			end
		end
		return
	end

	-- New vote round
	if not candidates then return end

	hasVoted = false
	voteCountdown = duration or 10
	votePanel.Visible = true

	for i, btn in ipairs(voteButtons) do
		if candidates[i] then
			local m = candidates[i]
			btn.Text = m.name .. "  [0 votes]"
			btn.BackgroundColor3 = Color3.fromRGB(60, 40, 100)
			btn.AutoButtonColor = true
			btn:SetAttribute("MutatorId", m.id)
			btn:SetAttribute("MutatorName", m.name)
			btn.Visible = true
		else
			btn.Visible = false
		end
	end

	-- Countdown timer
	task.spawn(function()
		while voteCountdown > 0 and votePanel.Visible do
			voteTimerLabel.Text = voteCountdown .. "s remaining"
			task.wait(1)
			voteCountdown = voteCountdown - 1
		end
		votePanel.Visible = false
	end)
end)

-- Vote button clicks
for i, btn in ipairs(voteButtons) do
	btn.MouseButton1Click:Connect(function()
		if hasVoted then return end
		local mutatorId = btn:GetAttribute("MutatorId")
		if not mutatorId then return end

		hasVoted = true
		MutatorVote:FireServer(mutatorId)

		-- Visual feedback: highlight voted button, gray others
		for j, otherBtn in ipairs(voteButtons) do
			if j == i then
				otherBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
				otherBtn.AutoButtonColor = false
			else
				otherBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
				otherBtn.AutoButtonColor = false
			end
		end
	end)
end

-- Receive vote result: play wheel animation
MutatorResult.OnClientEvent:Connect(function(resultData, allNames)
	-- Hide vote panel
	votePanel.Visible = false

	if not resultData or #resultData == 0 then return end

	local winnerNames = {}
	for _, m in ipairs(resultData) do
		table.insert(winnerNames, m.name)
	end

	playWheelAnimation(allNames, winnerNames, function()
		-- Badges will be shown when ActiveMutators fires
	end)
end)

-- Receive active mutators (during round, or for late joiners)
ActiveMutators.OnClientEvent:Connect(function(mutators)
	if not mutators or #mutators == 0 then
		showBadges({})
	else
		showBadges(mutators)
	end
end)

print("[MutatorUI] Initialized")
