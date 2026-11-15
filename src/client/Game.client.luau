-- Starfall Rush, client bootstrap: the game loop the player sees.
-- It steers the ship, drops the items the server spawns, and reports
-- every touch by item id — the server alone decides what it was worth.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Interface = require(script:WaitForChild("Interface"))
local Controls = require(script:WaitForChild("Controls"))
local Effects = require(script:WaitForChild("Effects"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StartGame = Remotes:WaitForChild("StartGame") :: RemoteEvent
local SpawnItem = Remotes:WaitForChild("SpawnItem") :: RemoteEvent
local ItemCaught = Remotes:WaitForChild("ItemCaught") :: RemoteEvent
local ItemHit = Remotes:WaitForChild("ItemHit") :: RemoteEvent
local StateChanged = Remotes:WaitForChild("StateChanged") :: RemoteEvent
local RemoveItem = Remotes:WaitForChild("RemoveItem") :: RemoteEvent

local gui = Interface.build()
local arena = gui.arena
local ship = gui.ship

local playing = false
local level = 1
local shipX = (Config.ARENA_WIDTH - Config.PLAYER_WIDTH) / 2
local shipY = Config.ARENA_HEIGHT - Config.PLAYER_BOTTOM_GAP - Config.PLAYER_HEIGHT

-- Live falling items by server id: their picture, kind, speed and the
-- top edge's height inside the arena, in pixels.
type FallingItem = {
	frame: Frame,
	kind: string,
	speed: number,
	y: number,
	x: number,
	radius: number,
	reported: boolean,
}
local items: { [number]: FallingItem } = {}

local function radiusFor(kind: string): number
	if kind == "meteor" then
		return Config.METEOR_RADIUS
	elseif kind == "heart" then
		return Config.HEART_RADIUS
	else
		return Config.STAR_RADIUS
	end
end

local function clearItems()
	for _, item in items do
		item.frame:Destroy()
	end
	table.clear(items)
end

local function placeShip()
	ship.Position = UDim2.fromOffset(math.floor(shipX + 0.5), shipY)
end

local function startRound()
	clearItems()
	shipX = (Config.ARENA_WIDTH - Config.PLAYER_WIDTH) / 2
	placeShip()
	StartGame:FireServer()
end

gui.playButton.MouseButton1Click:Connect(startRound)
gui.againButton.MouseButton1Click:Connect(startRound)

-- The server spawns; the client only draws what it is told to draw.
SpawnItem.OnClientEvent:Connect(function(id: number, kind: string, x: number, speed: number)
	if not playing then
		return
	end
	local frame = Interface.createFallingItem(arena, kind, x)
	items[id] = {
		frame = frame,
		kind = kind,
		speed = speed,
		y = -radiusFor(kind) * 2,
		x = x,
		radius = radiusFor(kind),
		reported = false,
	}
end)

-- The server confirms a removal (scored, hit, or the round ended).
RemoveItem.OnClientEvent:Connect(function(id: number)
	local item = items[id]
	if item then
		item.frame:Destroy()
		items[id] = nil
	end
end)

-- The server's snapshot is the truth: HUD, panels and the level-up flash.
StateChanged.OnClientEvent:Connect(function(snapshot: { [string]: any })
	local wasLevel = level
	level = snapshot.level
	Interface.updateHud(gui, snapshot)
	if snapshot.phase == "playing" then
		playing = true
		Interface.hidePanels(gui)
		if snapshot.level > wasLevel and wasLevel > 0 then
			Effects.levelUp(arena)
		end
	elseif snapshot.phase == "won" or snapshot.phase == "lost" then
		playing = false
		clearItems()
		Interface.showEnd(gui, snapshot.phase == "won", snapshot.score, snapshot.best)
	else
		playing = false
		clearItems()
		Interface.showStart(gui)
	end
end)

-- One frame: steer the ship, drop every item, and report every touch.
RunService.RenderStepped:Connect(function(dt: number)
	if not playing then
		return
	end

	local dir = Controls.direction()
	if dir ~= 0 then
		shipX = math.clamp(
			shipX + dir * Config.PLAYER_SPEED * dt,
			0,
			Config.ARENA_WIDTH - Config.PLAYER_WIDTH
		)
		placeShip()
	end

	for id, item in items do
		item.y += item.speed * dt
		item.frame.Position = UDim2.fromOffset(item.x, math.floor(item.y + 0.5))
		-- Past the floor: gone, and the server prunes it on its own.
		if item.y > Config.ARENA_HEIGHT then
			item.frame:Destroy()
			items[id] = nil
		elseif not item.reported then
			-- Overlap with the ship: the item's centre inside the ship's
			-- box, widened by the item's radius so a graze still counts.
			local cx = item.x + item.radius
			local cy = item.y + item.radius
			if cx >= shipX - item.radius
				and cx <= shipX + Config.PLAYER_WIDTH + item.radius
				and cy >= shipY
				and cy <= shipY + Config.PLAYER_HEIGHT
			then
				item.reported = true
				if item.kind == "star" then
					Effects.pop(item.frame)
					Interface.popup(arena, "+10", Config.COLORS.GOLD, cx, cy)
					ItemCaught:FireServer(id)
				elseif item.kind == "heart" then
					Effects.pop(item.frame)
					Interface.popup(arena, "+1 ♥", Config.COLORS.HEART, cx, cy)
					ItemCaught:FireServer(id)
				else
					Effects.hitFlash(arena)
					ItemHit:FireServer(id)
				end
			end
		end
	end
end)

Controls.bind()
placeShip()
Interface.showStart(gui)
print("Starfall Rush client ready.")
