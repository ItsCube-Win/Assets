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

local watermark = Instance.new("ImageLabel")
watermark.Size = UDim2.new(0, 465, 0, 82)
watermark.Position = UDim2.new(0.39, 0, 0.037, 0)
watermark.AnchorPoint = Vector2.new(0, 0.4)
watermark.ScaleType = Enum.ScaleType.Fit
watermark.BackgroundTransparency = 1
watermark.ZIndex = 10
watermark.Parent = screenGui
-- это было долго но кайфы
local gameImages = {
    [142823291] = "rbxassetid://89417474649125",      -- Murder Mystery 2
    [95082159892680] = "rbxassetid://109870431155558",  -- +1 Keyboard Escape
    [537413528] = "rbxassetid://89239249828079", -- BABFT
    [1488] = "rbxassetid://133777044310192", -- MMV -- бля где взять то айди
    [1962086868] = "rbxassetid://123496994777895", -- Tower OF hell
    [1] = "rbxassetid://110844669490628",     -- Ocean Dih ( test )
}

local DEFAULT_IMAGE = "rbxassetid://101471535225376"

local placeId = game.PlaceId
local imageId = gameImages[placeId] or DEFAULT_IMAGE
watermark.Image = imageId
print("Project Inf | WaterMark")
