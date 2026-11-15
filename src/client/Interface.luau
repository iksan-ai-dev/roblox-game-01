-- Starfall Rush, client side: builds every pixel of the game screen.
-- One module owns the whole GUI — background, arena, HUD, start and end
-- panels — so the layout the code draws is the layout the pictures show.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Interface = {}
local C = Config.COLORS

local function frame(name: string, parent: Instance): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BorderSizePixel = 0
	f.BackgroundTransparency = 0
	f.Parent = parent
	return f
end

local function label(name: string, parent: Instance, text: string, size: number, color: Color3, bold: boolean): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size
	l.TextColor3 = color
	l.Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham
	l.Parent = parent
	return l
end

local function button(name: string, parent: Instance, text: string, size: number): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.BackgroundColor3 = C.BUTTON
	b.BorderSizePixel = 0
	b.Text = text
	b.TextSize = size
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold
	b.AutoButtonColor = true
	b.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = b
	return b
end

-- A five-pointed star drawn as text: the same glyph the pictures use.
local function starLabel(parent: Instance, size: number): TextLabel
	local s = label("StarGlyph", parent, "★", size, C.STAR, true)
	s.TextScaled = true
	return s
end

function Interface.build(): { [string]: any }
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "StarfallGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 10
	gui.Parent = playerGui

	-- Night-sky background with a top-to-bottom gradient.
	local bg = frame("Background", gui)
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = C.BG_TOP
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(C.BG_TOP, C.BG_BOTTOM)
	gradient.Parent = bg

	-- The fixed starfield: the same dots, in the same places, as the
	-- screenshots render, so a picture and the game agree.
	for _, star in Config.STARFIELD do
		local dot = frame("Star", bg)
		dot.Size = UDim2.fromOffset(star[3] * 2, star[3] * 2)
		dot.Position = UDim2.new(star[1], 0, star[2], 0)
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		dot.BackgroundTransparency = 0.35
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = dot
	end

	-- HUD: score, lives, level and time across the top, above the arena.
	local hud = frame("Hud", gui)
	hud.AnchorPoint = Vector2.new(0.5, 0)
	hud.Position = UDim2.new(0.5, 0, 0, 48)
	hud.Size = UDim2.fromOffset(Config.ARENA_WIDTH, 56)
	hud.BackgroundTransparency = 1

	local scoreLabel = label("Score", hud, "SCORE 0", 26, C.TEXT, true)
	scoreLabel.Size = UDim2.fromOffset(160, 56)
	scoreLabel.TextXAlignment = Enum.TextXAlignment.Left

	local livesLabel = label("Lives", hud, "♥♥♥", 26, C.HEART, true)
	livesLabel.Position = UDim2.fromOffset(160, 0)
	livesLabel.Size = UDim2.fromOffset(160, 56)

	local levelLabel = label("Level", hud, "LEVEL 1", 26, C.TEXT, true)
	levelLabel.Position = UDim2.fromOffset(320, 0)
	levelLabel.Size = UDim2.fromOffset(160, 56)

	local timeLabel = label("Time", hud, "1:30", 26, C.TEXT, true)
	timeLabel.Position = UDim2.fromOffset(480, 0)
	timeLabel.Size = UDim2.fromOffset(160, 56)
	timeLabel.TextXAlignment = Enum.TextXAlignment.Right

	-- Progress to the 500-point win, a gold bar under the HUD.
	local progressBack = frame("ProgressBack", gui)
	progressBack.AnchorPoint = Vector2.new(0.5, 0)
	progressBack.Position = UDim2.new(0.5, 0, 0, 108)
	progressBack.Size = UDim2.fromOffset(Config.ARENA_WIDTH, 6)
	progressBack.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	local progressFill = frame("ProgressFill", progressBack)
	progressFill.Size = UDim2.fromScale(0, 1)
	progressFill.BackgroundColor3 = C.GOLD

	-- The arena: a bordered box that clips the falling items at its edge.
	local arena = frame("Arena", gui)
	arena.AnchorPoint = Vector2.new(0.5, 0.5)
	arena.Position = UDim2.fromScale(0.5, 0.5)
	arena.Size = UDim2.fromOffset(Config.ARENA_WIDTH, Config.ARENA_HEIGHT)
	arena.BackgroundColor3 = C.ARENA
	arena.BorderColor3 = C.ARENA_BORDER
	arena.BorderSizePixel = 2
	arena.ClipsDescendants = true

	-- The player's ship: a cyan hull with a white cockpit window.
	local ship = frame("Ship", arena)
	ship.Size = UDim2.fromOffset(Config.PLAYER_WIDTH, Config.PLAYER_HEIGHT)
	ship.BackgroundColor3 = C.SHIP
	ship.BorderSizePixel = 0
	local shipCorner = Instance.new("UICorner")
	shipCorner.CornerRadius = UDim.new(0, 10)
	shipCorner.Parent = ship
	local cockpit = frame("Cockpit", ship)
	cockpit.AnchorPoint = Vector2.new(0.5, 0)
	cockpit.Position = UDim2.fromScale(0.5, 0)
	cockpit.Size = UDim2.fromOffset(22, 12)
	cockpit.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	local cockpitCorner = Instance.new("UICorner")
	cockpitCorner.CornerRadius = UDim.new(0, 6)
	cockpitCorner.Parent = cockpit

	-- Start panel: title, how to play, and the big green PLAY button.
	local startPanel = frame("StartPanel", gui)
	startPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	startPanel.Position = UDim2.fromScale(0.5, 0.5)
	startPanel.Size = UDim2.fromOffset(560, 420)
	startPanel.BackgroundColor3 = C.PANEL
	startPanel.BorderColor3 = C.GOLD
	startPanel.BorderSizePixel = 2
	local startCorner = Instance.new("UICorner")
	startCorner.CornerRadius = UDim.new(0, 16)
	startCorner.Parent = startPanel

	local title = label("Title", startPanel, "STARFALL RUSH", 52, C.GOLD, true)
	title.Position = UDim2.fromOffset(0, 28)
	title.Size = UDim2.fromOffset(560, 64)

	local tagline = label("Tagline", startPanel, "Catch the stars. Dodge the meteors.", 22, C.TEXT, false)
	tagline.Position = UDim2.fromOffset(0, 100)
	tagline.Size = UDim2.fromOffset(560, 30)

	local howto = label(
		"HowTo",
		startPanel,
		"◀ ▶  or  A / D  to steer your ship\n★  Gold star  =  +10 points  —  500 wins\n☄  Red meteor  =  −1 life  —  3 lives, 90 seconds",
		20,
		C.MUTED,
		false
	)
	howto.Position = UDim2.fromOffset(0, 150)
	howto.Size = UDim2.fromOffset(560, 96)

	local playButton = button("PlayButton", startPanel, "▶  PLAY", 28)
	playButton.AnchorPoint = Vector2.new(0.5, 0)
	playButton.Position = UDim2.new(0.5, 0, 0, 268)
	playButton.Size = UDim2.fromOffset(240, 64)

	local bestStart = label("Best", startPanel, "Best: 0", 20, C.MUTED, false)
	bestStart.Position = UDim2.fromOffset(0, 348)
	bestStart.Size = UDim2.fromOffset(560, 28)

	-- End panel: the result, the final score, and play again.
	local endPanel = frame("EndPanel", gui)
	endPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	endPanel.Position = UDim2.fromScale(0.5, 0.5)
	endPanel.Size = UDim2.fromOffset(480, 360)
	endPanel.BackgroundColor3 = C.PANEL
	endPanel.BorderColor3 = C.GOLD
	endPanel.BorderSizePixel = 2
	endPanel.Visible = false
	local endCorner = Instance.new("UICorner")
	endCorner.CornerRadius = UDim.new(0, 16)
	endCorner.Parent = endPanel

	local resultLabel = label("Result", endPanel, "YOU WIN!", 48, C.GOLD, true)
	resultLabel.Position = UDim2.fromOffset(0, 36)
	resultLabel.Size = UDim2.fromOffset(480, 60)

	local finalLabel = label("FinalScore", endPanel, "Score: 0", 28, C.TEXT, true)
	finalLabel.Position = UDim2.fromOffset(0, 116)
	finalLabel.Size = UDim2.fromOffset(480, 40)

	local bestEnd = label("Best", endPanel, "Best: 0", 22, C.MUTED, false)
	bestEnd.Position = UDim2.fromOffset(0, 164)
	bestEnd.Size = UDim2.fromOffset(480, 32)

	local againButton = button("AgainButton", endPanel, "↻  PLAY AGAIN", 24)
	againButton.AnchorPoint = Vector2.new(0.5, 0)
	againButton.Position = UDim2.new(0.5, 0, 0, 224)
	againButton.Size = UDim2.fromOffset(240, 56)

	return {
		gui = gui,
		hud = hud,
		scoreLabel = scoreLabel,
		livesLabel = livesLabel,
		levelLabel = levelLabel,
		timeLabel = timeLabel,
		progressFill = progressFill,
		arena = arena,
		ship = ship,
		startPanel = startPanel,
		playButton = playButton,
		bestStart = bestStart,
		endPanel = endPanel,
		resultLabel = resultLabel,
		finalLabel = finalLabel,
		bestEnd = bestEnd,
		againButton = againButton,
	}
end

-- Refresh the HUD from the server's snapshot: one writer, one reader.
function Interface.updateHud(gui: { [string]: any }, state: { [string]: any })
	gui.scoreLabel.Text = "SCORE " .. tostring(state.score)
	local hearts = ""
	for _ = 1, state.lives do
		hearts ..= "♥"
	end
	if hearts == "" then
		hearts = "—"
	end
	gui.livesLabel.Text = hearts
	gui.levelLabel.Text = "LEVEL " .. tostring(state.level)
	local minutes = math.floor(state.secondsLeft / 60)
	local seconds = state.secondsLeft % 60
	gui.timeLabel.Text = string.format("%d:%02d", minutes, seconds)
	gui.progressFill.Size = UDim2.fromScale(
		math.clamp(state.score / Config.WIN_SCORE, 0, 1),
		1
	)
	gui.bestStart.Text = "Best: " .. tostring(state.best)
end

function Interface.showStart(gui: { [string]: any })
	gui.startPanel.Visible = true
	gui.endPanel.Visible = false
end

function Interface.showEnd(gui: { [string]: any }, won: boolean, score: number, best: number)
	gui.startPanel.Visible = false
	gui.endPanel.Visible = true
	if won then
		gui.resultLabel.Text = "YOU WIN!"
		gui.resultLabel.TextColor3 = C.GOLD
	else
		gui.resultLabel.Text = "GAME OVER"
		gui.resultLabel.TextColor3 = C.RED
	end
	gui.finalLabel.Text = "Score: " .. tostring(score)
	gui.bestEnd.Text = "Best: " .. tostring(best)
end

function Interface.hidePanels(gui: { [string]: any })
	gui.startPanel.Visible = false
	gui.endPanel.Visible = false
end

-- One falling item's picture: a gold star, a red meteor with craters, or
-- a pink heart, each sized to the radius the server's config names.
function Interface.createFallingItem(arena: Frame, kind: string, x: number): Frame
	if kind == "star" then
		local star = frame("Star", arena)
		star.Size = UDim2.fromOffset(Config.STAR_RADIUS * 2, Config.STAR_RADIUS * 2)
		star.Position = UDim2.fromOffset(x, -Config.STAR_RADIUS * 2)
		star.BackgroundTransparency = 1
		starLabel(star, Config.STAR_RADIUS * 2)
		return star
	elseif kind == "meteor" then
		local meteor = frame("Meteor", arena)
		meteor.Size = UDim2.fromOffset(Config.METEOR_RADIUS * 2, Config.METEOR_RADIUS * 2)
		meteor.Position = UDim2.fromOffset(x, -Config.METEOR_RADIUS * 2)
		meteor.BackgroundColor3 = C.METEOR
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = meteor
		local crater = frame("Crater", meteor)
		crater.AnchorPoint = Vector2.new(0.5, 0.5)
		crater.Position = UDim2.fromScale(0.35, 0.35)
		crater.Size = UDim2.fromOffset(8, 8)
		crater.BackgroundColor3 = C.METEOR_DARK
		local craterCorner = Instance.new("UICorner")
		craterCorner.CornerRadius = UDim.new(1, 0)
		craterCorner.Parent = crater
		return meteor
	else -- heart
		local heart = frame("Heart", arena)
		heart.Size = UDim2.fromOffset(Config.HEART_RADIUS * 2, Config.HEART_RADIUS * 2)
		heart.Position = UDim2.fromOffset(x, -Config.HEART_RADIUS * 2)
		heart.BackgroundTransparency = 1
		local glyph = label("HeartGlyph", heart, "♥", Config.HEART_RADIUS * 2, C.HEART, true)
		glyph.TextScaled = true
		return heart
	end
end

-- A floating score popup at an arena position: "+10" in gold, rising.
function Interface.popup(arena: Frame, text: string, color: Color3, x: number, y: number)
	local p = label("Popup", arena, text, 24, color, true)
	p.AnchorPoint = Vector2.new(0.5, 0.5)
	p.Position = UDim2.fromOffset(x, y)
	p.Size = UDim2.fromOffset(80, 32)
	p.ZIndex = 5
	local tween = TweenService:Create(
		p,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.fromOffset(x, y - 48), TextTransparency = 1 }
	)
	tween:Play()
	tween.Completed:Connect(function()
		p:Destroy()
	end)
end

return Interface
