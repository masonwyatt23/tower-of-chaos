local ObbyConfig = {}

-- Round settings
ObbyConfig.RoundDuration = 300       -- 5 minutes per round
ObbyConfig.IntermissionDuration = 20  -- 20 seconds between rounds (includes mutator vote)
ObbyConfig.MinStages = 10
ObbyConfig.MaxStages = 15
ObbyConfig.StageHeight = 18          -- studs between each stage
ObbyConfig.StageWidth = 30           -- stage platform size

-- Rewards
ObbyConfig.WinCoins = 100            -- coins for reaching the top
ObbyConfig.FirstPlaceBonus = 200     -- extra for first player to top
ObbyConfig.ParticipationCoins = 10   -- coins just for playing

-- Stage types (weights determine how often they appear)
ObbyConfig.StageTypes = {
	{name = "KillBricks",       weight = 3, description = "Dodge the red bricks!"},
	{name = "Spinners",         weight = 2, description = "Jump over the spinning beams!"},
	{name = "NarrowBeams",      weight = 3, description = "Walk the thin path!"},
	{name = "MovingPlatforms",  weight = 2, description = "Ride the moving platforms!"},
	{name = "DisappearingTiles",weight = 2, description = "The floor vanishes!"},
	{name = "LavaJumps",        weight = 3, description = "Jump across the lava!"},
	{name = "Wallhop",          weight = 1, description = "Hop between the walls!"},
	{name = "SpeedRun",         weight = 2, description = "Run before the walls close in!"},
}

-- Cosmetics (trails)
ObbyConfig.Trails = {
	{id = "fire",    name = "Fire Trail",    color = Color3.fromRGB(255, 100, 0),   price = 200},
	{id = "ice",     name = "Ice Trail",     color = Color3.fromRGB(100, 200, 255), price = 200},
	{id = "rainbow", name = "Rainbow Trail", color = Color3.fromRGB(255, 100, 255), price = 500},
	{id = "neon",    name = "Neon Trail",    color = Color3.fromRGB(0, 255, 100),   price = 300},
	{id = "galaxy",  name = "Galaxy Trail",  color = Color3.fromRGB(100, 50, 200),  price = 1000},
	{id = "gold",    name = "Gold Trail",    color = Color3.fromRGB(255, 215, 0),   price = 0, vip = true},
}

-- Scheduled Events (UTC times)
ObbyConfig.Events = {
	{name = "Free 2x Coins",    dayOfWeek = 7, hour = 20, duration = 7200,  reward = "2x_coins"},
	{name = "Double Rewards",   dayOfWeek = 4, hour = 0,  duration = 3600,  reward = "2x_rewards"},
	{name = "Free Skip",        dayOfWeek = 1, hour = 17, duration = 1800,  reward = "free_skip"},
	{name = "Mystery Gift",     dayOfWeek = 6, hour = 1,  duration = 900,   reward = "mystery"},
}

-- Game Passes
ObbyConfig.GamePasses = {
	DoubleCoins = {id = 0, name = "2x Coins",   price = 199},
	VIPTrail =    {id = 0, name = "VIP Trail",   price = 99},
	SpeedBoost =  {id = 0, name = "Speed Boost", price = 149, speedMultiplier = 1.3},
	SkipStage =   {id = 0, name = "Skip Stage",  price = 49},
}

-- Dev Products
ObbyConfig.Products = {
	SkipOnce =  {id = 0, name = "Skip This Stage", price = 9},
	ExtraLife = {id = 0, name = "Extra Life",       price = 19},
	CoinPack =  {id = 0, name = "1000 Coins",      price = 49, coins = 1000},
}

-- Mutator vote
ObbyConfig.MutatorVoteDuration = 10  -- seconds for mutator vote

-- Mutator definitions
ObbyConfig.Mutators = {
	{id = "low_gravity",  name = "Low Gravity",  description = "Gravity reduced! Float like a feather!"},
	{id = "double_speed", name = "Speed Demon",  description = "Everyone moves at double speed!"},
	{id = "giant",        name = "Giant Mode",   description = "Grow to 2x size!"},
	{id = "tiny",         name = "Shrink Ray",   description = "Shrink down to half size!"},
	{id = "fog",          name = "Fog of War",   description = "Thick fog rolls in!"},
	{id = "ice",          name = "Ice Floor",    description = "Checkpoints are slippery!"},
	{id = "bouncy",       name = "Bouncy",       description = "Extra jump power and lighter gravity!"},
	{id = "darkness",     name = "Lights Out",   description = "The lights go dark!"},
}

-- Achievements
ObbyConfig.Achievements = {
	{id = "first_win",       name = "First Victory",     trigger = "wins",           threshold = 1,    reward = 100},
	{id = "5_wins",          name = "Skilled Climber",    trigger = "wins",           threshold = 5,    reward = 500},
	{id = "25_wins",         name = "Tower Master",       trigger = "wins",           threshold = 25,   reward = 2500},
	{id = "100_wins",        name = "Tower Legend",       trigger = "wins",           threshold = 100,  reward = 10000},
	{id = "10_games",        name = "Regular Player",     trigger = "gamesPlayed",    threshold = 10,   reward = 200},
	{id = "50_games",        name = "Dedicated",          trigger = "gamesPlayed",    threshold = 50,   reward = 1000},
	{id = "1k_coins",        name = "Coin Collector",     trigger = "totalCoins",     threshold = 1000,  reward = 500},
	{id = "10k_coins",       name = "Rich Climber",       trigger = "totalCoins",     threshold = 10000, reward = 2000},
	{id = "50k_coins",       name = "Tower Tycoon",       trigger = "totalCoins",     threshold = 50000, reward = 10000},
	{id = "10_votes",        name = "Democracy!",         trigger = "mutatorVotes",   threshold = 10,   reward = 300},
	{id = "50_mutator_rounds", name = "Chaos Lover",      trigger = "roundsWithMutators", threshold = 50, reward = 2000},
}

-- Promo Codes
ObbyConfig.Codes = {
	TOWER    = 500,
	OBBY     = 200,
	CLIMB    = 1000,
	TYCOON   = 500,   -- cross-promo
	CHAOS    = 500,   -- mutator wheel promo
	CASHFLOW = 500,   -- Cross-promo: play CashFlow Empire
	GALAXY   = 500,   -- Cross-promo: play Galaxy Empire
	FOODIE   = 500,   -- Cross-promo: play Food Factory
}

return ObbyConfig
