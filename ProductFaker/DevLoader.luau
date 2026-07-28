
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do task.wait() end

local oldGui = CoreGui:FindFirstChild("ThunderStormLite")
if oldGui then oldGui:Destroy() end


local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ThunderStormLite"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = CoreGui


local button = Instance.new("TextButton")
button.Name = "MainButton"
button.Size = UDim2.new(0, 220, 0, 48)
button.Position = UDim2.new(0.5, 0, 1, -60)
button.AnchorPoint = Vector2.new(0.5, 1)
button.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
button.BackgroundTransparency = 0.15
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextSize = 18
button.Font = Enum.Font.GothamBold
button.Text = "Waiting..."
button.BorderSizePixel = 0
button.AutoButtonColor = false
button.ZIndex = 10
button.Parent = screenGui


local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = button


local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Thickness = 1.5
stroke.Transparency = 0.3
stroke.Parent = button


local dragging, dragStart, startPos
button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = button.Position
    end
end)
button.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        button.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
button.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)


local LastPrompt = { Id = nil, Type = nil }


local function closePurchaseWindow()
    pcall(function()
        for _, child in ipairs(CoreGui:GetChildren()) do
            if child:IsA("ScreenGui") and child.Name == "FoundationOverlay" and child.Enabled then
                local saf = child:FindFirstChild("SafeAreaFrame")
                local portal = saf and saf:FindFirstChild("OverlayPortal")
                local backdrop = portal and portal:FindFirstChild("Backdrop")
                local sheet = portal and portal:FindFirstChild("SheetContainer")
                if backdrop and sheet then
                    local info = TweenInfo.new(0.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
                    TweenService:Create(backdrop, info, {BackgroundTransparency = 1}):Play()
                    local t = TweenService:Create(sheet, info, {Position = UDim2.new(0.5, 0, 0.5, 32)})
                    t:Play()
                    t.Completed:Connect(function()
                        GuiService:SetMenuIsOpen(true)
                        GuiService:SetMenuIsOpen(false)
                    end)
                    return
                end
            end
        end
        GuiService:SetMenuIsOpen(true)
        GuiService:SetMenuIsOpen(false)
    end)
end


local function fireFakeSignal(sigType, id)
    if not id then return end
    pcall(function()
        if sigType == "Product" then
            MarketplaceService:SignalPromptProductPurchaseFinished(LocalPlayer.UserId, id, true)
        elseif sigType == "Gamepass" then
            MarketplaceService:SignalPromptGamePassPurchaseFinished(LocalPlayer, id, true)
        elseif sigType == "Asset" then
            MarketplaceService:SignalPromptPurchaseFinished(LocalPlayer.UserId, id, true)
        elseif sigType == "Bundle" then
            MarketplaceService:SignalPromptBundlePurchaseFinished(LocalPlayer.UserId, id, true)
        elseif sigType == "Premium" then
            MarketplaceService:SignalPromptPremiumPurchaseFinished(true)
        else
            MarketplaceService:SignalPromptGamePassPurchaseFinished(LocalPlayer, id, true)
        end
    end)
end


local function updateButton(id, promptType)
    if id then
        LastPrompt.Id = id
        LastPrompt.Type = promptType
        button.Text = "ID: " .. tostring(id)
        button.BackgroundColor3 = Color3.fromRGB(40, 200, 40) 
        stroke.Color = Color3.fromRGB(0, 255, 100)
    else
        LastPrompt.Id = nil
        LastPrompt.Type = nil
        button.Text = "Waiting..."
        button.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        stroke.Color = Color3.fromRGB(255, 255, 255)
    end
end


local function capturePrompt(player, id, promptType)
    if player ~= LocalPlayer then return end
    updateButton(id, promptType)
end

MarketplaceService.PromptGamePassPurchaseRequested:Connect(function(player, id)
    capturePrompt(player, id, "Gamepass")
end)
MarketplaceService.PromptProductPurchaseRequested:Connect(function(player, id)
    capturePrompt(player, id, "Product")
end)
MarketplaceService.PromptPurchaseRequested:Connect(function(player, id)
    capturePrompt(player, id, "Asset")
end)
MarketplaceService.PromptBundlePurchaseRequested:Connect(function(player, id)
    capturePrompt(player, id, "Bundle")
end)
MarketplaceService.PromptPremiumPurchaseRequested:Connect(function(player)
    capturePrompt(player, 0, "Premium")
end)


button.MouseButton1Click:Connect(function()
    if not LastPrompt.Id then
        button.Text = "No ID!"
        task.wait(1)
        if not LastPrompt.Id then
            button.Text = "Waiting..."
        else
            button.Text = "ID: " .. tostring(LastPrompt.Id)
        end
        return
    end
    
    pcall(function()
        fireFakeSignal(LastPrompt.Type, LastPrompt.Id)
        closePurchaseWindow()
    end)

    button.Text = "Sent!"
    button.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    task.wait(0.8)
    button.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
    button.Text = "ID: " .. tostring(LastPrompt.Id)
end)

print("DevScript Tg: Project_Infinitex
