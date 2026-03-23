--[[
	StageGenerator — Creates obstacle sections for each tower stage
	Each stage type generates different obstacles between checkpoints.
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local StageGenerator = {}

local KILL_COLOR = Color3.fromRGB(255, 50, 50)
local SAFE_COLOR = Color3.fromRGB(100, 100, 100)
local LAVA_COLOR = Color3.fromRGB(255, 80, 0)
local NEON_COLOR = Color3.fromRGB(100, 200, 255)

-- Helper: create a kill brick
local function createKillBrick(size, position, parent)
	local brick = Instance.new("Part")
	brick.Size = size
	brick.Position = position
	brick.Anchored = true
	brick.Color = KILL_COLOR
	brick.Material = Enum.Material.Neon
	brick.Parent = parent

	brick.Touched:Connect(function(hit)
		local character = hit.Parent
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid.Health = 0
			end
		end
	end)

	return brick
end

-- Helper: create a safe platform
local function createPlatform(size, position, color, parent)
	local part = Instance.new("Part")
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Color = color or SAFE_COLOR
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = parent
	return part
end

-- Stage: Kill Bricks — scattered red bricks between safe platforms
function StageGenerator.KillBricks(yBase, width, height, parent)
	-- Safe stepping stones
	local numPlatforms = math.random(5, 8)
	for i = 1, numPlatforms do
		local x = math.random(-width/3, width/3)
		local z = math.random(-width/3, width/3)
		local y = yBase + (i / numPlatforms) * height
		createPlatform(Vector3.new(4, 1, 4), Vector3.new(x, y, z), SAFE_COLOR, parent)
	end

	-- Kill bricks filling the gaps (fewer = fairer)
	for i = 1, 7 do
		local x = math.random(-width/3, width/3)
		local z = math.random(-width/3, width/3)
		local y = yBase + (i / 8) * height  -- distribute evenly in Y
		createKillBrick(
			Vector3.new(math.random(3, 5), 1, math.random(3, 5)),
			Vector3.new(x, y, z),
			parent
		)
	end
end

-- Stage: Spinners — rotating beams to jump over
function StageGenerator.Spinners(yBase, width, height, parent)
	local numLevels = math.random(3, 5)

	for i = 1, numLevels do
		local y = yBase + (i / (numLevels + 1)) * height

		-- Platform to stand on
		createPlatform(
			Vector3.new(width - 4, 1, width - 4),
			Vector3.new(0, y, 0),
			SAFE_COLOR,
			parent
		)

		-- Spinning beam (shorter so there's a gap to jump through)
		local spinner = createKillBrick(
			Vector3.new(width * 0.5, 3, 2),
			Vector3.new(0, y + 2, 0),
			parent
		)

		-- Animate rotation (consistent speed so players can learn timing)
		local speed = 1.2
		local offset = math.random() * math.pi * 2
		RunService.Heartbeat:Connect(function()
			if spinner and spinner.Parent then
				local angle = (tick() * speed + offset) % (math.pi * 2)
				spinner.CFrame = CFrame.new(0, y + 2, 0) * CFrame.Angles(0, angle, 0)
			end
		end)
	end
end

-- Stage: Narrow Beams — thin paths over void
function StageGenerator.NarrowBeams(yBase, width, height, parent)
	local numBeams = math.random(4, 7)
	local prevEnd = Vector3.new(0, yBase, -width/3)

	for i = 1, numBeams do
		local y = yBase + (i / (numBeams + 1)) * height
		local x = math.random(-width/3, width/3)
		local z = math.random(-width/3, width/3)
		local endPos = Vector3.new(x, y, z)

		-- Beam connecting platforms (4 studs wide = walkable)
		local beam = createPlatform(
			Vector3.new(4, 1, 8),
			Vector3.new((prevEnd.X + endPos.X) / 2, y, (prevEnd.Z + endPos.Z) / 2),
			Color3.fromRGB(150, 150, 150),
			parent
		)

		-- Small landing platforms
		createPlatform(Vector3.new(5, 1, 5), endPos, NEON_COLOR, parent)

		prevEnd = endPos
	end
end

-- Stage: Moving Platforms — platforms that slide back and forth
function StageGenerator.MovingPlatforms(yBase, width, height, parent)
	local numPlatforms = math.random(4, 6)

	for i = 1, numPlatforms do
		local y = yBase + (i / (numPlatforms + 1)) * height
		local platform = createPlatform(
			Vector3.new(6, 1, 6),
			Vector3.new(0, y, 0),
			Color3.fromRGB(50, 150, 255),
			parent
		)

		-- Animate movement (consistent speed, alternating direction per platform)
		local axis = (i % 2 == 0) and "X" or "Z"
		local range = width / 4
		local speed = 0.8  -- consistent so players can learn
		local offset = i * math.pi / 3  -- staggered but predictable

		RunService.Heartbeat:Connect(function()
			if platform and platform.Parent then
				local pos = math.sin(tick() * speed + offset) * range
				if axis == "X" then
					platform.CFrame = CFrame.new(pos, y, 0)
				else
					platform.CFrame = CFrame.new(0, y, pos)
				end
			end
		end)
	end
end

-- Stage: Disappearing Tiles — floor that vanishes when stepped on
function StageGenerator.DisappearingTiles(yBase, width, height, parent)
	local gridSize = 5
	local tileSize = (width - 4) / gridSize
	local y = yBase + height / 2

	for gx = 1, gridSize do
		for gz = 1, gridSize do
			local x = (gx - (gridSize + 1) / 2) * tileSize
			local z = (gz - (gridSize + 1) / 2) * tileSize

			local tile = createPlatform(
				Vector3.new(tileSize - 0.5, 1, tileSize - 0.5),
				Vector3.new(x, y, z),
				Color3.fromRGB(200, 200, 100),
				parent
			)

			local debounce = false
			tile.Touched:Connect(function(hit)
				if debounce then return end
				local character = hit.Parent
				if not character or not character:FindFirstChildOfClass("Humanoid") then return end
				debounce = true

				-- Flash red then disappear (1.5s warning = fair)
				tile.Color = KILL_COLOR
				task.wait(1.5)
				tile.Transparency = 1
				tile.CanCollide = false

				-- Reappear quickly (1.5s = keeps pace)
				task.wait(1.5)
				tile.Transparency = 0
				tile.CanCollide = true
				tile.Color = Color3.fromRGB(200, 200, 100)
				debounce = false
			end)
		end
	end

	-- Add some permanent safe tiles
	for i = 1, 3 do
		createPlatform(
			Vector3.new(3, 1.5, 3),
			Vector3.new(math.random(-5, 5), y + 0.5, math.random(-5, 5)),
			Color3.fromRGB(50, 200, 50),
			parent
		)
	end
end

-- Stage: Lava Jumps — platforms over lava with gaps
function StageGenerator.LavaJumps(yBase, width, height, parent)
	-- Lava floor
	local lavaFloor = createKillBrick(
		Vector3.new(width, 1, width),
		Vector3.new(0, yBase + 1, 0),
		parent
	)
	lavaFloor.Color = LAVA_COLOR
	lavaFloor.Material = Enum.Material.Neon

	-- Jumping platforms above lava
	local numPlatforms = math.random(6, 10)
	for i = 1, numPlatforms do
		local x = math.random(-width/3, width/3)
		local z = math.random(-width/3, width/3)
		local y = yBase + 3 + (i / numPlatforms) * (height - 4)
		local size = math.random(3, 6)
		createPlatform(
			Vector3.new(size, 1, size),
			Vector3.new(x, y, z),
			Color3.fromRGB(100, 100, 100),
			parent
		)
	end
end

-- Stage: Wall Hop — vertical climb between two walls
function StageGenerator.Wallhop(yBase, width, height, parent)
	-- Two walls facing each other
	local wallWidth = 1
	local gap = 5  -- 5 studs = doable jump (7 stud max jump)

	local leftWall = createPlatform(
		Vector3.new(wallWidth, height, width/2),
		Vector3.new(-gap/2, yBase + height/2, 0),
		Color3.fromRGB(80, 80, 120),
		parent
	)

	local rightWall = createPlatform(
		Vector3.new(wallWidth, height, width/2),
		Vector3.new(gap/2, yBase + height/2, 0),
		Color3.fromRGB(80, 80, 120),
		parent
	)

	-- Small ledges to hop between
	local numLedges = math.random(6, 10)
	for i = 1, numLedges do
		local y = yBase + (i / (numLedges + 1)) * height
		local side = (i % 2 == 0) and -1 or 1
		createPlatform(
			Vector3.new(3, 1, 4),
			Vector3.new(side * (gap/2 - 2), y, math.random(-5, 5)),
			NEON_COLOR,
			parent
		)
	end
end

-- Stage: Speed Run — straight corridor with closing walls
function StageGenerator.SpeedRun(yBase, width, height, parent)
	local corridorLength = width * 2
	local y = yBase + height / 2

	-- Floor
	createPlatform(
		Vector3.new(8, 1, corridorLength),
		Vector3.new(0, y, 0),
		Color3.fromRGB(150, 150, 150),
		parent
	)

	-- Kill walls that sweep across the corridor (duck or jump!)
	local numWalls = math.random(3, 5)
	for i = 1, numWalls do
		local z = -corridorLength/2 + (i / (numWalls + 1)) * corridorLength

		-- Alternate: high walls (jump over) and low walls (walk under gap)
		local isHigh = (i % 2 == 0)
		local wallY = isHigh and (y + 5) or (y + 2)
		local wallSize = isHigh and Vector3.new(12, 2, 1) or Vector3.new(12, 3, 1)

		local wall = createKillBrick(wallSize, Vector3.new(0, wallY, z), parent)

		-- Walls sweep left-to-right at consistent speed
		local speed = 1.0
		local startX = 10

		RunService.Heartbeat:Connect(function()
			if wall and wall.Parent then
				local t = (math.sin(tick() * speed + i) + 1) / 2
				wall.CFrame = CFrame.new(startX * (t * 2 - 1), wallY, z)
			end
		end)
	end
end

-- Main stage generation function
function StageGenerator.generateStage(stageType, yBase, width, height, parent)
	local generator = StageGenerator[stageType]
	if generator then
		generator(yBase, width, height, parent)
	else
		-- Fallback: simple platforms
		StageGenerator.KillBricks(yBase, width, height, parent)
	end
end

return StageGenerator
