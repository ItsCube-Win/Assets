
local Bin_1337 = Instance.new("ScreenGui")
local Watermark = Instance.new("Frame")
local Ms = Instance.new("TextLabel")
local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
local FPS = Instance.new("TextLabel")
local UITextSizeConstraint_2 = Instance.new("UITextSizeConstraint")
local Image = Instance.new("ImageLabel")


Bin_1337.Name = "Bin_1337"
Bin_1337.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
Bin_1337.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Bin_1337.IgnoreGuiInset = true

Watermark.Name = "Watermark"
Watermark.Parent = Bin_1337
Watermark.BackgroundColor3 = Color3.new(1, 1, 1)
Watermark.BackgroundTransparency = 1
Watermark.BorderColor3 = Color3.new(0, 0, 0)
Watermark.BorderSizePixel = 0
Watermark.Position = UDim2.new(0.375881523, 0, 0.00835322216, 0)
Watermark.Size = UDim2.new(0, 353, 0, 61)

Ms.Name = "Ms"
Ms.Parent = Watermark
Ms.BackgroundColor3 = Color3.new(1, 1, 1)
Ms.BackgroundTransparency = 1
Ms.BorderColor3 = Color3.new(0, 0, 0)
Ms.BorderSizePixel = 0
Ms.Position = UDim2.new(0.541076481, 0, 0.00835331157, 0)
Ms.Size = UDim2.new(0, 78, 0, 61)
Ms.Font = Enum.Font.SourceSans
Ms.Text = "0 ms"
Ms.TextColor3 = Color3.new(0.831373, 0.831373, 0.831373)
Ms.TextScaled = true
Ms.TextSize = 14
Ms.TextWrapped = true
Ms.TextXAlignment = Enum.TextXAlignment.Left

UITextSizeConstraint.Parent = Ms
UITextSizeConstraint.MaxTextSize = 25

FPS.Name = "FPS"
FPS.Parent = Watermark
FPS.BackgroundColor3 = Color3.new(1, 1, 1)
FPS.BackgroundTransparency = 1
FPS.BorderColor3 = Color3.new(0, 0, 0)
FPS.BorderSizePixel = 0
FPS.Position = UDim2.new(0.728045344, 0, 0.00835331157, 0)
FPS.Size = UDim2.new(0, 83, 0, 61)
FPS.Font = Enum.Font.SourceSans
FPS.Text = "0 FPS"
FPS.TextColor3 = Color3.new(0.831373, 0.831373, 0.831373)
FPS.TextScaled = true
FPS.TextSize = 14
FPS.TextWrapped = true
FPS.TextXAlignment = Enum.TextXAlignment.Left

UITextSizeConstraint_2.Parent = FPS
UITextSizeConstraint_2.MaxTextSize = 25

Image.Name = "Image"
Image.Parent = Watermark
Image.AnchorPoint = Vector2.new(0.5, 0)
Image.BackgroundColor3 = Color3.new(1, 1, 1)
Image.BackgroundTransparency = 1
Image.BorderColor3 = Color3.new(0, 0, 0)
Image.BorderSizePixel = 0
Image.Position = UDim2.new(0.5, 0, 0.0083532175, 0)
Image.Size = UDim2.new(0, 405, 0, 61)
Image.ZIndex = -1
Image.Image = "rbxassetid://96628667085349"
Image.ScaleType = Enum.ScaleType.Fit

local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer


local gui = player:WaitForChild("PlayerGui"):WaitForChild("Bin_1337")
local msLabel = gui.Watermark.Ms
local fpsLabel = gui.Watermark.FPS

local lastTime = tick()
local frameCount = 0
local currentFPS = 0
local currentMS = 0

RunService.Heartbeat:Connect(function(deltaTime)
	frameCount = frameCount + 1
	local now = tick()
	local elapsed = now - lastTime

	if elapsed >= 0.5 then
		currentFPS = frameCount / elapsed
		currentMS = (elapsed / frameCount) * 1000
		fpsLabel.Text = string.format("%.0f FPS", currentFPS)
		msLabel.Text = string.format("%.0f ms", currentMS)
		frameCount = 0
		lastTime = now
	end
end)
