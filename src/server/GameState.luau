-- Starfall Rush, server side: the one place that owns the game state.
-- The client renders and reports what the player touches; this module
-- decides what it is worth, so a tampered client cannot invent points.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local GameState = {}

export type Phase = "menu" | "playing" | "won" | "lost"

export type State = {
	phase: Phase,
	score: number,
	lives: number,
	level: number,
	secondsLeft: number,
	best: number,
}

local state: State = {
	phase = "menu",
	score = 0,
	lives = Config.START_LIVES,
	level = 1,
	secondsLeft = Config.GAME_SECONDS,
	best = 0,
}

-- The registry of live falling items: id -> { kind, spawnedAt }. The
-- server spawns them and only it may score them, so a client report
-- names an id it must find here, of the kind the report claims. An item
-- that falls past the arena without being touched is pruned by age, so a
-- missed item never stays scoreable.
local liveItems: { [number]: { kind: string, at: number } } = {}
local nextItemId = 1

-- Seconds after which a falling item can no longer be caught: the arena
-- is 480 px tall and the slowest fall is 140 px/s, so 8 s covers it.
local ITEM_MAX_AGE = 8

function GameState.get(): State
	return state
end

function GameState.snapshot(): State
	return {
		phase = state.phase,
		score = state.score,
		lives = state.lives,
		level = state.level,
		secondsLeft = state.secondsLeft,
		best = state.best,
	}
end

function GameState.reset()
	state.phase = "playing"
	state.score = 0
	state.lives = Config.START_LIVES
	state.level = 1
	state.secondsLeft = Config.GAME_SECONDS
	table.clear(liveItems)
end

function GameState.registerItem(kind: string): number
	local id = nextItemId
	nextItemId += 1
	liveItems[id] = { kind = kind, at = os.clock() }
	return id
end

function GameState.forgetItem(id: number)
	liveItems[id] = nil
end

-- Drop every item older than ITEM_MAX_AGE: it fell past the arena.
function GameState.pruneStale()
	local now = os.clock()
	for id, item in liveItems do
		if now - item.at > ITEM_MAX_AGE then
			liveItems[id] = nil
		end
	end
end

function GameState.clearItems()
	table.clear(liveItems)
end

-- A catch is real only when the item is live and really a star (or a
-- heart). The item leaves the registry either way: one report per item.
function GameState.catchItem(id: number): (boolean, string?)
	local entry = liveItems[id]
	if entry == nil then
		return false, nil
	end
	local kind = entry.kind
	liveItems[id] = nil
	if kind == "star" then
		state.score += Config.STAR_POINTS
		state.level = Config.levelForScore(state.score)
		if state.score > state.best then
			state.best = state.score
		end
		if state.score >= Config.WIN_SCORE then
			state.phase = "won"
		end
		return true, "star"
	elseif kind == "heart" then
		if state.lives < Config.MAX_LIVES then
			state.lives += 1
		end
		return true, "heart"
	end
	return false, nil
end

-- A meteor hit is real only when the item is live and really a meteor.
function GameState.hitMeteor(id: number): boolean
	local entry = liveItems[id]
	if entry == nil or entry.kind ~= "meteor" then
		return false
	end
	liveItems[id] = nil
	state.lives -= 1
	if state.lives <= 0 then
		state.lives = 0
		state.phase = "lost"
	end
	return true
end

-- One second of the clock. Returns true when the timer ended the game.
function GameState.tickClock(): boolean
	if state.phase ~= "playing" then
		return false
	end
	state.secondsLeft -= 1
	if state.secondsLeft <= 0 then
		state.secondsLeft = 0
		if state.score >= Config.TIMEOUT_WIN_SCORE then
			state.phase = "won"
		else
			state.phase = "lost"
		end
		return true
	end
	return false
end

function GameState.endToMenu()
	state.phase = "menu"
	table.clear(liveItems)
end

return GameState
