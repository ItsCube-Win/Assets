local WindUI = nil

local function httpGet(url)
    local success, result
    if syn and syn.request then
        success, result = pcall(function()
            return syn.request({ Url = url, Method = "GET" }).Body
        end)
        if success and result then return result end
    end
    if http and http.request then
        success, result = pcall(function()
            return http.request({ Url = url, Method = "GET" }).Body
        end)
        if success and result then return result end
    end
    success, result = pcall(function()
        return game:HttpGet(url)
    end)
    if success and result then return result end
    return nil
end

local urls = {
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
}

for _, url in ipairs(urls) do
    local content = httpGet(url)
    if content and type(content) == "string" and #content > 100 then
        local loadFunc, err = loadstring(content)
        if loadFunc then
            local ok, lib = pcall(loadFunc)
            if ok and type(lib) == "table" then
                WindUI = lib
                break
            end
        end
    end
    wait(0.5)
end

if not WindUI then
    error("WindUI failed to load")
end

WindUI:AddTheme({
    Name = "Default",
    Accent = Color3.fromHex("#18181b"),
    Background = Color3.fromHex("#101010"),
    Outline = Color3.fromHex("#FFFFFF"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Button = Color3.fromHex("#52525b"),
    Icon = Color3.fromHex("#a1a1aa"),
})
WindUI:SetTheme("Default")

local MainWindow = WindUI:CreateWindow({
    Title = "ThunderStorm",
    Icon = "zap",
    Author = "by Project Infinitex",
    Folder = "Thunderstorm",
    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    ToggleKey = Enum.KeyCode.LeftShift,
    Transparent = false,
    Theme = "Default",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = true,
    ScrollBarEnabled = false,
    User = {
        Enabled = true,
        Anonymous = false,
        Name = game:GetService("Players").LocalPlayer.DisplayName,
        Callback = function() end,
    },
})
MainWindow:Open()

MainWindow:EditOpenButton({
    Title = "ThunderStorm",
    Icon = "user-star",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("FF0F7B"), 
        Color3.fromHex("F89B29")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

local Main = MainWindow:Tab({
    Title = "General",
    Icon = "book-open-text",
    Locked = false,
})

local CoreGui = game:GetService("CoreGui")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do task.wait() end

if not getgenv().Settings then
    getgenv().Settings = {}
end
if getgenv().Settings.InstantPurchase == nil then
    getgenv().Settings.InstantPurchase = false
end

LastPrompt = { Id = nil, Type = nil, Nonce = 0 }
LastInstant = { PromptNonce = -1 }

local function fireFakeSignal(sigType, id)
    if not id then return end
    pcall(function()
        if sigType == "Product" then
            MarketplaceService:SignalPromptProductPurchaseFinished(LocalPlayer.UserId, id, true)
        elseif sigType == "Gamepass" then
            MarketplaceService:SignalPromptGamePassPurchaseFinished(LocalPlayer, id, true)
        elseif sigType == "Bulk" then
            MarketplaceService:SignalPromptBulkPurchaseFinished(LocalPlayer.UserId, id, true)
        elseif sigType == "Purchase" then
            MarketplaceService:SignalPromptPurchaseFinished(LocalPlayer.UserId, id, true)
        else
            MarketplaceService:SignalPromptGamePassPurchaseFinished(LocalPlayer, id, true)
        end
    end)
end

local function finishPurchase(id)
    fireFakeSignal(LastPrompt.Type, id)
end

local function runInstantPurchase(id)
    if not getgenv().Settings.InstantPurchase then return end
    if not id then return end
    if id ~= LastPrompt.Id then return end
    local promptNonce = LastPrompt.Nonce or 0
    if LastInstant.PromptNonce == promptNonce then
        return
    end
    LastInstant.PromptNonce = promptNonce
    finishPurchase(id)
end

local Preview = Main:Code({
    Title = "Information",
    Code = [[local Gamepass = 0
local GamepassName = "Waiting..."
local GamepassType = "Unknown"]],
})

local SendButton = Main:Button({
    Title = "Send Fake Gamepass",
    Desc = "No Gamepass selected",
    Locked = false,
    Callback = function()
        if not LastPrompt or not LastPrompt.Id then
            WindUI:Notify({
                Title = "No Gamepass",
                Content = "There is no detected gamepass/product yet.",
                Duration = 3,
                Icon = "alert-circle",
            })
            return
        end
        pcall(function()
            finishPurchase(LastPrompt.Id)
        end)
        WindUI:Notify({
            Title = "Sent",
            Content = "Fake signal sent for " .. tostring(LastPrompt.Id),
            Duration = 2,
            Icon = "check",
        })
    end
})

local AutoSendTogl = Main:Toggle({
    Title = "AutoSend",
    Value = getgenv().Settings.InstantPurchase or false,
    Callback = function(state)
        getgenv().Settings.InstantPurchase = state
        WindUI:Notify({
            Title = "AutoSend " .. (state and "ON" or "OFF"),
            Content = state and "Will automatically purchase when prompt appears." or "Manual mode.",
            Duration = 2,
            Icon = state and "toggle-right" or "toggle-left",
        })
    end
})


local ManualInput = Main:Input({
    Title = "Manual ID",
    Desc = "Enter Gamepass/Product ID",
    Value = "",
    Callback = function(value) end
})


local SetIDButton = Main:Button({
    Title = "Set Manual ID",
    Desc = "Apply entered ID",
    Locked = false,
    Callback = function()
        local value = ManualInput:GetValue() 
        local num = tonumber(value)
        if num and num > 0 then
            LastPrompt.Id = num
            LastPrompt.Type = "Gamepass"
            LastPrompt.Nonce = (LastPrompt.Nonce or 0) + 1
            updatePreview(num, "Gamepass")
            WindUI:Notify({
                Title = "ID Set",
                Content = "Manual ID set to " .. tostring(num),
                Duration = 2,
                Icon = "check",
            })
        else
            WindUI:Notify({
                Title = "Invalid ID",
                Content = "Please enter a valid number.",
                Duration = 2,
                Icon = "alert-circle",
            })
        end
    end
})

local function updatePreview(id, promptType)
    if not Preview or not SendButton then return end
    if not id then
        Preview:SetCode([[local Gamepass = 0
local GamepassName = "Waiting..."
local GamepassType = "Unknown"]])
        SendButton:SetDesc("No Gamepass selected")
        return
    end
    local name = "Unknown"
    local infoType
    if promptType == "Gamepass" then
        infoType = Enum.InfoType.GamePass
    elseif promptType == "Product" then
        infoType = Enum.InfoType.Product
    elseif promptType == "Purchase" then
        infoType = Enum.InfoType.Asset
    elseif promptType == "Bundle" then
        infoType = Enum.InfoType.Bundle
    end
    if infoType then
        local success, info = pcall(function()
            return MarketplaceService:GetProductInfo(id, infoType)
        end)
        if success and info then
            name = info.Name or "Unknown"
        end
    end
    local codeStr = string.format("local Gamepass = %d\nlocal GamepassName = %q\nlocal GamepassType = %q", id, name, promptType or "Unknown")
    Preview:SetCode(codeStr)
    SendButton:SetDesc("Selected Gamepass: " .. tostring(id) .. " - " .. name)
end

local function capturePrompt(player, id, promptType)
    if player ~= LocalPlayer then return end
    LastPrompt.Nonce = (LastPrompt.Nonce or 0) + 1
    LastPrompt.Id = id
    LastPrompt.Type = promptType
    updatePreview(id, promptType)
    if getgenv().Settings.InstantPurchase then
        task.spawn(function()
            runInstantPurchase(id)
        end)
    end
end

MarketplaceService.PromptGamePassPurchaseRequested:Connect(function(player, id)
    capturePrompt(player, id, "Gamepass")
end)
MarketplaceService.PromptProductPurchaseRequested:Connect(function(player, id)
    capturePrompt(player, id, "Product")
end)
MarketplaceService.PromptPurchaseRequested:Connect(function(player, id)
    capturePrompt(player, id, "Purchase")
end)
MarketplaceService.PromptBundlePurchaseRequested:Connect(function(player, id)
    capturePrompt(player, id, "Bundle")
end)
MarketplaceService.PromptPremiumPurchaseRequested:Connect(function(player)
    capturePrompt(player, 0, "Premium")
end)

task.spawn(function()
    local lastState = getgenv().Settings.InstantPurchase
    while true do
        task.wait(0.1)
        local currentState = getgenv().Settings.InstantPurchase
        if currentState ~= lastState then
            lastState = currentState
            AutoSendTogl:SetValue(currentState)
        end
    end
end)

WindUI:Notify({
    Title = "ThunderStorm",
    Content = "UI loaded! Waiting for purchase prompts.",
    Duration = 3,
    Icon = "zap",
})
