-- Starfall Rush: every number the game and its pictures agree on.
-- One module holds the layout, the tuning and the palette so the server,
-- the client and the screenshots all draw the same game.

local Config = {}

-- The game is a flat 2D arcade game drawn on a ScreenGui. The arena is a
-- 640x480 box centred on a 1280x720 screen; the HUD sits above it.
Config.SCREEN_WIDTH = 1280
Config.SCREEN_HEIGHT = 720
Config.ARENA_WIDTH = 640
Config.ARENA_HEIGHT = 480
Config.ARENA_X = (Config.SCREEN_WIDTH - Config.ARENA_WIDTH) / 2
Config.ARENA_Y = 120

-- The ship the player steers along the bottom of the arena.
Config.PLAYER_WIDTH = 64
Config.PLAYER_HEIGHT = 28
Config.PLAYER_BOTTOM_GAP = 36
Config.PLAYER_SPEED = 420 -- pixels per second

-- Falling things. Stars are worth points, meteors cost a life, hearts
-- give one back (rare, and never above the life cap).
Config.STAR_RADIUS = 14
Config.STAR_POINTS = 10
Config.METEOR_RADIUS = 16
Config.HEART_RADIUS = 14
Config.HEART_CHANCE = 0.05
Config.START_LIVES = 3
Config.MAX_LIVES = 3

-- Winning and losing. 500 points wins at once; when the 90 second timer
-- runs out the player wins with 300 or more, else loses.
Config.WIN_SCORE = 500
Config.TIMEOUT_WIN_SCORE = 300
Config.GAME_SECONDS = 90

-- Difficulty. A level is 100 points; speed and spawn rate grow with it.
Config.LEVEL_STEP = 100
Config.MAX_LEVEL = 5

function Config.levelForScore(score: number): number
	return math.min(Config.MAX_LEVEL, math.floor(score / Config.LEVEL_STEP) + 1)
end

function Config.fallSpeed(level: number): number
	return 140 + (level - 1) * 55
end

function Config.spawnInterval(level: number): number
	return math.max(0.35, 0.85 - (level - 1) * 0.12)
end

function Config.meteorChance(level: number): number
	return math.min(0.42, 0.22 + (level - 1) * 0.04)
end

-- Palette: a night sky, a deep blue arena, gold stars, red meteors.
Config.COLORS = {
	BG_TOP = Color3.fromRGB(11, 16, 38),
	BG_BOTTOM = Color3.fromRGB(30, 27, 75),
	ARENA = Color3.fromRGB(22, 33, 62),
	ARENA_BORDER = Color3.fromRGB(61, 90, 153),
	STAR = Color3.fromRGB(255, 209, 102),
	METEOR = Color3.fromRGB(239, 68, 68),
	METEOR_DARK = Color3.fromRGB(153, 27, 27),
	HEART = Color3.fromRGB(244, 114, 182),
	SHIP = Color3.fromRGB(34, 211, 238),
	SHIP_DARK = Color3.fromRGB(8, 145, 178),
	TEXT = Color3.fromRGB(240, 244, 255),
	MUTED = Color3.fromRGB(148, 163, 184),
	BUTTON = Color3.fromRGB(34, 197, 94),
	BUTTON_DARK = Color3.fromRGB(21, 128, 61),
	PANEL = Color3.fromRGB(15, 23, 42),
	GOLD = Color3.fromRGB(250, 204, 21),
	RED = Color3.fromRGB(248, 113, 113),
}

-- The starfield behind everything: fixed positions in 0..1 screen space
-- with a pixel radius at 1280x720, so the code and the pictures match.
Config.STARFIELD = {
	{ 0.04, 0.07, 2 }, { 0.11, 0.18, 1 }, { 0.17, 0.05, 2 }, { 0.24, 0.13, 1 },
	{ 0.31, 0.06, 2 }, { 0.38, 0.16, 1 }, { 0.45, 0.04, 2 }, { 0.53, 0.11, 1 },
	{ 0.60, 0.06, 2 }, { 0.67, 0.15, 1 }, { 0.74, 0.05, 2 }, { 0.81, 0.12, 1 },
	{ 0.88, 0.06, 2 }, { 0.95, 0.16, 1 }, { 0.07, 0.32, 1 }, { 0.14, 0.42, 2 },
	{ 0.21, 0.30, 1 }, { 0.28, 0.44, 2 }, { 0.35, 0.31, 1 }, { 0.42, 0.45, 2 },
	{ 0.58, 0.30, 1 }, { 0.65, 0.44, 2 }, { 0.72, 0.31, 1 }, { 0.79, 0.45, 2 },
	{ 0.86, 0.32, 1 }, { 0.93, 0.43, 2 }, { 0.05, 0.62, 2 }, { 0.12, 0.74, 1 },
	{ 0.19, 0.88, 2 }, { 0.27, 0.68, 1 }, { 0.34, 0.82, 2 }, { 0.41, 0.93, 1 },
	{ 0.59, 0.66, 2 }, { 0.66, 0.80, 1 }, { 0.73, 0.92, 2 }, { 0.80, 0.68, 1 },
	{ 0.87, 0.83, 2 }, { 0.94, 0.94, 1 }, { 0.50, 0.90, 2 }, { 0.97, 0.55, 1 },
}

return Config
