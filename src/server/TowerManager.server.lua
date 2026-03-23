--[[
	TowerManager — Core game loop for Tower Obby
	Manages rounds, tower generation, win detection, and scoring.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObbyConfig = require(Shared:WaitForChild("ObbyConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Create remotes
local function createRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = Remotes
	return remote
end

local RoundStartRemote = createRemote("RoundStart")
local RoundEndRemote = createRemote("RoundEnd")
local PlayerWinRemote = createRemote("PlayerWin")
local StageReachedRemote = createRemote("StageReached")
local UpdateCoinsRemote = createRemote("UpdateCoins")
local SkipStageRemote = createRemote("SkipStage")

-- Game state
local currentTower = nil
local roundActive = false
local roundStartTime = 0
local winners = {}
local playerStages = {} -- [player] = current stage number

-- Player data
local PlayerData = {}

_G.ObbyPlayerData = PlayerData

function _G.GetPlayerData(player)
	return PlayerData[player]
end

function _G.AddCoins(player, amount)
	local data = PlayerData[player]
	if not data then return end
	data.coins = data.coins + amount
	data.totalCoins = data.totalCoins + math.max(0, amount)
	UpdateCoinsRemote:FireClient(player, data.coins)

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinStat = leaderstats:FindFirstChild("Coins")
		if coinStat then coinStat.Value = data.coins end
	end
end

function _G.InitializePlayerData(player, savedData)
	PlayerData[player] = savedData or {
		coins = 0,
		totalCoins = 0,
		wins = 0,
		gamesPlayed = 0,
		bestTime = 0,
		ownedTrails = {},
		equippedTrail = "",
		redeemedCodes = {},
	}
	playerStages[player] = 0
	UpdateCoinsRemote:FireClient(player, PlayerData[player].coins)
end

-- Generate tower using StageGenerator
local StageGenerator = require(script.Parent:WaitForChild("StageGenerator"))

local function generateTower()
	-- Clear old tower
	if currentTower then
		currentTower:Destroy()
	end

	local towerFolder = Instance.new("Folder")
	towerFolder.Name = "Tower"
	towerFolder.Parent = workspace

	-- Base platform (spawn area)
	local base = Instance.new("Part")
	base.Name = "TowerBase"
	base.Size = Vector3.new(60, 2, 60)
	base.Position = Vector3.new(0, -1, 0)
	base.Anchored = true
	base.Color = Color3.fromRGB(80, 80, 80)
	base.Material = Enum.Material.DiamondPlate
	base.Parent = towerFolder

	-- Spawn location
	local spawn = Instance.new("SpawnLocation")
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 1, 0)
	spawn.Anchored = true
	spawn.Color = Color3.fromRGB(50, 200, 50)
	spawn.Neutral = true
	spawn.Parent = towerFolder

	-- Generate random number of stages
	local numStages = math.random(ObbyConfig.MinStages, ObbyConfig.MaxStages)

	for i = 1, numStages do
		local yPos = i * ObbyConfig.StageHeight
		local stageType = pickRandomStage()

		-- Stage platform (checkpoint at bottom of each stage)
		local checkpoint = Instance.new("Part")
		checkpoint.Name = "Checkpoint_" .. i
		checkpoint.Size = Vector3.new(ObbyConfig.StageWidth, 1, ObbyConfig.StageWidth)
		checkpoint.Position = Vector3.new(0, yPos, 0)
		checkpoint.Anchored = true
		checkpoint.Color = Color3.fromRGB(50, 150, 50)
		checkpoint.Material = Enum.Material.SmoothPlastic
		checkpoint.Parent = towerFolder

		-- Stage number label
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 100, 0, 40)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.AlwaysOnTop = false
		billboard.Parent = checkpoint

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = "Stage " .. i
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.TextStrokeTransparency = 0.3
		label.Parent = billboard

		-- Checkpoint detection
		checkpoint.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = Players:GetPlayerFromCharacter(character)
			if player and playerStages[player] and playerStages[player] < i then
				playerStages[player] = i
				StageReachedRemote:FireClient(player, i, numStages)
			end
		end)

		-- Generate obstacles above the checkpoint
		StageGenerator.generateStage(stageType, yPos + 1, ObbyConfig.StageWidth, ObbyConfig.StageHeight - 2, towerFolder)
	end

	-- Win platform at the very top
	local winPlatform = Instance.new("Part")
	winPlatform.Name = "WinPlatform"
	winPlatform.Size = Vector3.new(ObbyConfig.StageWidth, 2, ObbyConfig.StageWidth)
	winPlatform.Position = Vector3.new(0, (numStages + 0.5) * ObbyConfig.StageHeight + 5, 0)
	winPlatform.Anchored = true
	winPlatform.Color = Color3.fromRGB(255, 215, 0)
	winPlatform.Material = Enum.Material.Neon
	winPlatform.Parent = towerFolder

	-- Win label
	local winBillboard = Instance.new("BillboardGui")
	winBillboard.Size = UDim2.new(0, 200, 0, 60)
	winBillboard.StudsOffset = Vector3.new(0, 5, 0)
	winBillboard.AlwaysOnTop = true
	winBillboard.Parent = winPlatform

	local winLabel = Instance.new("TextLabel")
	winLabel.Size = UDim2.new(1, 0, 1, 0)
	winLabel.BackgroundTransparency = 1
	winLabel.Text = "FINISH!"
	winLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	winLabel.TextScaled = true
	winLabel.Font = Enum.Font.GothamBold
	winLabel.TextStrokeTransparency = 0
	winLabel.Parent = winBillboard

	-- Win detection
	winPlatform.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if player and roundActive and not winners[player] then
			winners[player] = true
			local isFirst = false
			local winCount = 0
			for _ in pairs(winners) do winCount = winCount + 1 end
			isFirst = (winCount == 1)

			-- Award coins
			local coins = ObbyConfig.WinCoins
			if isFirst then coins = coins + ObbyConfig.FirstPlaceBonus end

			-- Check 2x coins pass
			if _G.HasGamePass and _G.HasGamePass(player, "DoubleCoins") then
				coins = coins * 2
			end

			-- Check event boost
			if _G.EventActive and _G.EventActive("2x_coins") then
				coins = coins * 2
			end

			if _G.AddCoins then
				_G.AddCoins(player, coins)
			end

			local data = PlayerData[player]
			if data then
				data.wins = data.wins + 1
				local elapsed = tick() - roundStartTime
				if data.bestTime == 0 or elapsed < data.bestTime then
					data.bestTime = elapsed
				end
			end

			PlayerWinRemote:FireAllClients(player.Name, isFirst, coins)
		end
	end)

	-- Title sign
	local signPart = Instance.new("Part")
	signPart.Size = Vector3.new(30, 10, 2)
	signPart.Position = Vector3.new(0, 8, -35)
	signPart.Anchored = true
	signPart.Color = Color3.fromRGB(30, 30, 50)
	signPart.Material = Enum.Material.SmoothPlastic
	signPart.Parent = towerFolder

	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = signPart

	local titleText = Instance.new("TextLabel")
	titleText.Size = UDim2.new(1, 0, 0.6, 0)
	titleText.Position = UDim2.new(0, 0, 0.05, 0)
	titleText.BackgroundTransparency = 1
	titleText.Text = "TOWER OF CHAOS"
	titleText.TextColor3 = Color3.fromRGB(255, 215, 0)
	titleText.TextScaled = true
	titleText.Font = Enum.Font.GothamBold
	titleText.Parent = signGui

	local subText = Instance.new("TextLabel")
	subText.Size = UDim2.new(1, 0, 0.3, 0)
	subText.Position = UDim2.new(0, 0, 0.65, 0)
	subText.BackgroundTransparency = 1
	subText.Text = numStages .. " Stages — Race to the Top!"
	subText.TextColor3 = Color3.fromRGB(200, 200, 200)
	subText.TextScaled = true
	subText.Font = Enum.Font.Gotham
	subText.Parent = signGui

	-- Back face
	local backGui = signGui:Clone()
	backGui.Face = Enum.NormalId.Back
	backGui.Parent = signPart

	currentTower = towerFolder
	return numStages
end

-- Pick random stage type based on weights
function pickRandomStage()
	local totalWeight = 0
	for _, stage in ipairs(ObbyConfig.StageTypes) do
		totalWeight = totalWeight + stage.weight
	end
	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, stage in ipairs(ObbyConfig.StageTypes) do
		cumulative = cumulative + stage.weight
		if roll <= cumulative then
			return stage.name
		end
	end
	return ObbyConfig.StageTypes[1].name
end

-- Respawn player at their last checkpoint (not bottom!)
local function respawnAtCheckpoint(player)
	local stage = playerStages[player] or 0
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	if stage > 0 and currentTower then
		local checkpoint = currentTower:FindFirstChild("Checkpoint_" .. stage)
		if checkpoint then
			hrp.CFrame = CFrame.new(checkpoint.Position + Vector3.new(0, 3, 0))
			return
		end
	end
	-- Fallback: spawn at base
	hrp.CFrame = CFrame.new(0, 5, 0)
end

-- Hook death → respawn at checkpoint for each player
local function setupDeathRespawn(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			-- Track deaths
			local data = PlayerData[player]
			if data then
				data.deaths = (data.deaths or 0) + 1
			end
			-- Respawn after brief delay
			task.wait(1.5)
			player:LoadCharacter()
		end)
		-- Teleport to checkpoint after respawn
		task.wait(0.5)
		if roundActive then
			respawnAtCheckpoint(player)
		end
	end)
end

-- Teleport all players back to spawn
local function resetPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		playerStages[player] = 0
		local character = player.Character
		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = CFrame.new(0, 5, 0)
			end
		end
	end
end

-- Main game loop
task.spawn(function()
	-- Lighting
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 10
	Lighting.Ambient = Color3.fromRGB(100, 100, 120)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 170)
	Lighting.Brightness = 1.5

	local sky = Instance.new("Sky")
	sky.StarCount = 3000
	sky.Parent = Lighting

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.2
	atmosphere.Offset = 0.5
	atmosphere.Color = Color3.fromRGB(180, 200, 255)
	atmosphere.Parent = Lighting

	-- Remove default baseplate
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then baseplate:Destroy() end

	while true do
		-- Generate new tower
		roundActive = false
		winners = {}
		local numStages = generateTower()

		-- Intermission
		RoundEndRemote:FireAllClients(ObbyConfig.IntermissionDuration)
		task.wait(ObbyConfig.IntermissionDuration)

		-- Start round
		roundActive = true
		roundStartTime = tick()
		resetPlayers()
		RoundStartRemote:FireAllClients(numStages, ObbyConfig.RoundDuration)

		-- Wait for round to end
		task.wait(ObbyConfig.RoundDuration)

		-- End round — give participation coins
		roundActive = false
		for player, _ in pairs(PlayerData) do
			if player.Parent and not winners[player] then
				-- Scale participation coins by stage reached (not flat 10)
				local stage = playerStages[player] or 0
				local coins = math.max(ObbyConfig.ParticipationCoins, stage * 5)
				if _G.AddCoins then
					_G.AddCoins(player, coins)
				end
			end
			local data = PlayerData[player]
			if data then
				data.gamesPlayed = data.gamesPlayed + 1
			end
		end

		RoundEndRemote:FireAllClients(ObbyConfig.IntermissionDuration)
		task.wait(2) -- brief pause before loop
	end
end)

-- Skip stage
SkipStageRemote.OnServerEvent:Connect(function(player)
	if not roundActive then return end
	local currentStage = playerStages[player] or 0
	local numStages = currentTower and #currentTower:GetChildren() or 0

	-- Check skip pass or free event
	local canSkip = false
	if _G.HasGamePass and _G.HasGamePass(player, "SkipStage") then
		canSkip = true
	elseif _G.EventActive and _G.EventActive("free_skip") then
		canSkip = true
	end

	if canSkip and currentStage < numStages then
		playerStages[player] = currentStage + 1
		-- Teleport to next checkpoint
		local checkpoint = currentTower:FindFirstChild("Checkpoint_" .. (currentStage + 1))
		if checkpoint then
			local character = player.Character
			if character then
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if hrp then
					hrp.CFrame = CFrame.new(checkpoint.Position + Vector3.new(0, 3, 0))
				end
			end
		end
		StageReachedRemote:FireClient(player, currentStage + 1, numStages)
	end
end)

-- Player management
Players.PlayerRemoving:Connect(function(player)
	playerStages[player] = nil
	winners[player] = nil
	task.delay(5, function()
		PlayerData[player] = nil
	end)
end)

-- Setup death respawn for each player
Players.PlayerAdded:Connect(function(player)
	setupDeathRespawn(player)
end)

-- Leaderboard
Players.PlayerAdded:Connect(function(player)
	task.wait(2)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coinStat = Instance.new("IntValue")
	coinStat.Name = "Coins"
	coinStat.Parent = leaderstats

	local winStat = Instance.new("IntValue")
	winStat.Name = "Wins"
	winStat.Parent = leaderstats

	local data = PlayerData[player]
	if data then
		coinStat.Value = data.coins
		winStat.Value = data.wins
	end
end)

print("[TowerManager] Initialized")
