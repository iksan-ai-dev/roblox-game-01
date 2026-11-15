-- Starfall Rush, client side: the feel. Every action answers at once —
-- a caught star pops, a meteor hit shakes the arena and flashes it red,
-- a level-up washes it gold — so the player always knows what happened.

local TweenService = game:GetService("TweenService")

local Effects = {}

-- A quick scale pop on a caught star's picture, then it is gone.
function Effects.pop(item: GuiObject)
	local tween = TweenService:Create(
		item,
		TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(44, 44), Rotation = 25 }
	)
	tween:Play()
end

-- A short shake of the whole arena plus a red flash on a meteor hit.
function Effects.hitFlash(arena: Frame)
	local flash = Instance.new("Frame")
	flash.Name = "HitFlash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
	flash.BackgroundTransparency = 0.55
	flash.BorderSizePixel = 0
	flash.ZIndex = 8
	flash.Parent = arena
	local fade = TweenService:Create(
		flash,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)
	fade:Play()
	fade.Completed:Connect(function()
		flash:Destroy()
	end)
	local base = arena.Position
	local shake = TweenService:Create(
		arena,
		TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.new(base.X.Scale, base.X.Offset - 5, base.Y.Scale, base.Y.Offset) }
	)
	shake:Play()
	shake.Completed:Connect(function()
		arena.Position = base
	end)
end

-- A gold wash across the arena when the level rises.
function Effects.levelUp(arena: Frame)
	local wash = Instance.new("Frame")
	wash.Name = "LevelWash"
	wash.Size = UDim2.fromScale(1, 1)
	wash.BackgroundColor3 = Color3.fromRGB(250, 204, 21)
	wash.BackgroundTransparency = 0.75
	wash.BorderSizePixel = 0
	wash.ZIndex = 8
	wash.Parent = arena
	local fade = TweenService:Create(
		wash,
		TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)
	fade:Play()
	fade.Completed:Connect(function()
		wash:Destroy()
	end)
end

return Effects
