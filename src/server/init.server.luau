-- Starfall Rush, server bootstrap: owns the loop, the clock and the wire.
-- It spawns items, scores the client's reports through GameState and
-- broadcasts every change, so the client never keeps score of its own.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local GameState = require(script:WaitForChild("GameState"))
local Spawner = require(script:WaitForChild("Spawner"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StartGame = Remotes:WaitForChild("StartGame") :: RemoteEvent
local SpawnItem = Remotes:WaitForChild("SpawnItem") :: RemoteEvent
local ItemCaught = Remotes:WaitForChild("ItemCaught") :: RemoteEvent
local ItemHit = Remotes:WaitForChild("ItemHit") :: RemoteEvent
local StateChanged = Remotes:WaitForChild("StateChanged") :: RemoteEvent
local RemoveItem = Remotes:WaitForChild("RemoveItem") :: RemoteEvent

local function broadcast()
	StateChanged:FireAllClients(GameState.snapshot())
end

local function endRound()
	GameState.clearItems()
	broadcast()
end

-- A round starts from a clean slate: fresh score, lives, level and clock.
StartGame.OnServerEvent:Connect(function(player: Player)
	local state = GameState.get()
	if state.phase == "playing" then
		return
	end
	GameState.reset()
	broadcast()
end)

-- The client reports a catch by item id; only the server knows if the
-- item is real and what it is worth. A stale or forged id scores nothing.
ItemCaught.OnServerEvent:Connect(function(player: Player, itemId: number)
	local state = GameState.get()
	if state.phase ~= "playing" or typeof(itemId) ~= "number" then
		return
	end
	local ok, kind = GameState.catchItem(itemId)
	if ok then
		RemoveItem:FireAllClients(itemId)
		broadcast()
		if GameState.get().phase ~= "playing" then
			endRound()
		end
	end
end)

-- Same for a meteor hit: the server checks the id, then takes the life.
ItemHit.OnServerEvent:Connect(function(player: Player, itemId: number)
	local state = GameState.get()
	if state.phase ~= "playing" or typeof(itemId) ~= "number" then
		return
	end
	if GameState.hitMeteor(itemId) then
		RemoveItem:FireAllClients(itemId)
		broadcast()
		if GameState.get().phase ~= "playing" then
			endRound()
		end
	end
end)

-- The spawn loop: one item at a time, paced by the current level.
task.spawn(function()
	while true do
		task.wait(0.1)
		local state = GameState.get()
		if state.phase ~= "playing" then
			continue
		end
		local spawn = Spawner.pick(state.level)
		spawn.id = GameState.registerItem(spawn.kind)
		SpawnItem:FireAllClients(spawn.id, spawn.kind, spawn.x, spawn.speed)
		task.wait(Spawner.nextDelay(state.level))
	end
end)

-- The clock: one tick a second, and the timeout decides win or loss.
task.spawn(function()
	while true do
		task.wait(1)
		GameState.pruneStale()
		if GameState.get().phase == "playing" then
			if GameState.tickClock() then
				endRound()
			else
				broadcast()
			end
		end
	end
end)

print("Starfall Rush server ready: catch stars, dodge meteors, 500 wins.")
