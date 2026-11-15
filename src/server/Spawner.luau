-- Starfall Rush, server side: decides what falls, where and how fast.
-- The client only draws what this module spawns, so the difficulty curve
-- lives in one place and the pictures can show it honestly.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local Spawner = {}

export type Spawn = {
	id: number,
	kind: string, -- "star" | "meteor" | "heart"
	x: number, -- left edge inside the arena, in pixels
	speed: number, -- pixels per second
}

local rng = Random.new()

-- Pick the next falling item for the current level. Hearts are rare and
-- never appear on the first level, so the opening stays a clean tutorial.
function Spawner.pick(level: number): Spawn
	local kind = "star"
	local roll = rng:NextNumber()
	if level > 1 and roll < Config.HEART_CHANCE then
		kind = "heart"
	elseif roll < Config.HEART_CHANCE + Config.meteorChance(level) then
		kind = "meteor"
	end
	local radius = Config.STAR_RADIUS
	if kind == "meteor" then
		radius = Config.METEOR_RADIUS
	elseif kind == "heart" then
		radius = Config.HEART_RADIUS
	end
	-- Keep the whole item inside the arena, with a small margin.
	local maxX = Config.ARENA_WIDTH - radius * 2 - 8
	local x = 4 + rng:NextInteger(0, maxX)
	local speed = Config.fallSpeed(level) * (0.9 + rng:NextNumber() * 0.2)
	return { id = 0, kind = kind, x = x, speed = speed }
end

-- The pause before the next spawn, shorter as the level rises.
function Spawner.nextDelay(level: number): number
	return Config.spawnInterval(level) * (0.85 + rng:NextNumber() * 0.3)
end

return Spawner
