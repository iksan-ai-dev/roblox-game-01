-- Starfall Rush, client side: reading the player's keys.
-- Arrow keys and A/D steer the ship. The bindings use ContextActionService
-- (not InputBegan with gameProcessedEvent) because Roblox's default camera
-- scripts already take the arrow keys, so a plain InputBegan handler
-- would never see them.

local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local Controls = {}

local movingLeft = false
local movingRight = false

local function onMoveLeft(_action: string, state: EnumItem, _input: InputObject)
	if state == Enum.UserInputState.Begin then
		movingLeft = true
	elseif state == Enum.UserInputState.End then
		movingLeft = false
	end
	return Enum.ContextActionResult.Pass
end

local function onMoveRight(_action: string, state: EnumItem, _input: InputObject)
	if state == Enum.UserInputState.Begin then
		movingRight = true
	elseif state == Enum.UserInputState.End then
		movingRight = false
	end
	return Enum.ContextActionResult.Pass
end

function Controls.bind()
	ContextActionService:BindAction(
		"StarfallMoveLeft",
		onMoveLeft,
		false,
		Enum.KeyCode.Left,
		Enum.KeyCode.A
	)
	ContextActionService:BindAction(
		"StarfallMoveRight",
		onMoveRight,
		false,
		Enum.KeyCode.Right,
		Enum.KeyCode.D
	)
end

function Controls.unbind()
	ContextActionService:UnbindAction("StarfallMoveLeft")
	ContextActionService:UnbindAction("StarfallMoveRight")
	movingLeft = false
	movingRight = false
end

-- The ship's steering for this frame: -1, 0 or +1. Held keys are read
-- directly too, so a key already down when the round starts still steers.
function Controls.direction(): number
	local left = movingLeft
		or UserInputService:IsKeyDown(Enum.KeyCode.Left)
		or UserInputService:IsKeyDown(Enum.KeyCode.A)
	local right = movingRight
		or UserInputService:IsKeyDown(Enum.KeyCode.Right)
		or UserInputService:IsKeyDown(Enum.KeyCode.D)
	if left and not right then
		return -1
	elseif right and not left then
		return 1
	else
		return 0
	end
end

return Controls
