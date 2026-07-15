local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("Bin")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Bin"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false

screenGui.DisplayOrder = 10
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

local BASE_WIDTH = 317
local BASE_HEIGHT = 48
local SCALE = 1.1  -- 110% вроде норм

local function createImage(assetId, zIndex)
    local img = Instance.new("ImageLabel")
    img.Image = assetId
    img.Size = UDim2.new(0, BASE_WIDTH * SCALE, 0, BASE_HEIGHT * SCALE)
    img.Position = UDim2.new(0.5, 0, 0, 13)
    img.AnchorPoint = Vector2.new(0.5, 0)
    img.ScaleType = Enum.ScaleType.Fit
    img.BackgroundTransparency = 1
    img.ZIndex = zIndex
    img.Parent = screenGui
    return img
end

-- ассеты фоток ( мб забанят )
local img1 = createImage("rbxassetid://136690013401899", 0)
local img2 = createImage("rbxassetid://122462078110645", 1)
