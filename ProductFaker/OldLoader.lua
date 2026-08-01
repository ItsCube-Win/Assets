    --[[
    Thunderstorm v0.4
    Tabs: Listener | Pinned | Settings
    Toggle: RightShift (PC) | S button (Mobile)
]]

local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UIS                = game:GetService("UserInputService")
local MPS                = game:GetService("MarketplaceService")
local HS                 = game:GetService("HttpService")
local Lighting           = game:GetService("Lighting")
local RunService         = game:GetService("RunService")
local tost               = tostring

local PINNED_FILE        = "thunderstorm_pinned.json"

local player             = Players.LocalPlayer
local playerGui          = player:WaitForChild("PlayerGui")
local CoreGui            = game:GetService("CoreGui")

if CoreGui:FindFirstChild("ThunderstormUI") then
    CoreGui.ThunderstormUI:Destroy()
end

local Themes = {
    Dark = {
        bg        = Color3.fromRGB(12,  12,  15),
        surface   = Color3.fromRGB(18,  18,  22),
        surfaceHi = Color3.fromRGB(25,  25,  30),
        border    = Color3.fromRGB(45,  45,  55),
        borderHi  = Color3.fromRGB(80,  80,  95),
        accent    = Color3.fromRGB(220, 220, 220),
        accentDim = Color3.fromRGB(120, 120, 120),
        green     = Color3.fromRGB(0,   255, 127),
        greenDim  = Color3.fromRGB(20,  70,  45),
        red       = Color3.fromRGB(255, 90,  90),
        redDim    = Color3.fromRGB(60,  18,  18),
        amber     = Color3.fromRGB(255, 200, 60),
        text      = Color3.fromRGB(240, 240, 240),
        textMuted = Color3.fromRGB(150, 150, 150),
        textDim   = Color3.fromRGB(90,  90,  90),
    },
    Light = {
        bg        = Color3.fromRGB(244, 246, 250),
        surface   = Color3.fromRGB(250, 252, 255),
        surfaceHi = Color3.fromRGB(255, 255, 255),
        border    = Color3.fromRGB(211, 216, 228),
        borderHi  = Color3.fromRGB(176, 186, 207),
        accent    = Color3.fromRGB(41,  49,  65),
        accentDim = Color3.fromRGB(102, 112, 134),
        green     = Color3.fromRGB(0,   170, 90),
        greenDim  = Color3.fromRGB(211, 241, 224),
        red       = Color3.fromRGB(210, 65, 65),
        redDim    = Color3.fromRGB(247, 225, 225),
        amber     = Color3.fromRGB(222, 152, 35),
        text      = Color3.fromRGB(46,  53,  69),
        textMuted = Color3.fromRGB(100, 110, 130),
        textDim   = Color3.fromRGB(148, 156, 173),
    },
}
local currentTheme = "Dark"
local C = {}
for k, v in pairs(Themes[currentTheme]) do
    C[k] = v
end

local UI = {
    Main = nil,
    Loading = nil,
    GameInfo = nil,
    CountLabel = nil,
    RateLabel = nil,
    TabBar = nil,
    LogArea = nil,
    PinnedScroll = nil,
    Tabs = {},
    Entries = {},
    PinnedEntries = {},
    ActiveAutoButtons = {},
    ActiveSpamButtons = {},
    Conns = {},
    Labels = {
        SignalTypes = {},
        PinnedTypes = {},
    },
    ReopenGui = nil,
}

local State = {
    isMobile        = UIS.TouchEnabled,
    vp              = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1920, 1080),
    autoSpeed       = 100,
    latestEvent     = nil,
    showProductNames= true,
    showSignalText  = true,
    eventCount      = 0,
    pinCount        = 0,
    suppressCounter = 0,
    rateSmooth      = 0,
    uiVisible       = false,
    isCollapsed     = false,
    activeTab       = nil,
    globalPinned    = {},
    pinnedDataList  = {},
    signalTimestamps= {},
}

local PW  = State.isMobile and math.floor(State.vp.X * 0.92) or 780
local PH  = State.isMobile and math.floor(State.vp.Y * 0.75) or 480
local TH  = State.isMobile and 46 or 52
local FH  = State.isMobile and 46 or 50
local TABH= State.isMobile and 36 or 34
local BH  = State.isMobile and 36 or 28
local FS, FM, FL = 13, (State.isMobile and 15 or 14), (State.isMobile and 17 or 16)

-- resolve product name from id
local nameCache = {}
local function getProductName(id, sigType)
    if nameCache[id] then return nameCache[id] end
    local name = nil
    pcall(function()
        if sigType == "Product" then
            local info = MPS:GetProductInfo(id, Enum.InfoType.Product)
            if info and info.Name then name = info.Name end
        elseif sigType == "Gamepass" then
            local info = MPS:GetProductInfo(id, Enum.InfoType.GamePass)
            if info and info.Name then name = info.Name end
        else
            local info = MPS:GetProductInfo(id, Enum.InfoType.Asset)
            if info and info.Name then name = info.Name end
        end
    end)
    if not name then
        pcall(function()
            local url
            if sigType == "Gamepass" then
                url = "https://economy.roblox.com/v1/game-pass/"..tostring(id).."/game-pass-product-info"
            elseif sigType == "Product" then
                url = "https://economy.roblox.com/v2/developer-products/"..tostring(id).."/info"
            end
            if url then
                local res = game:HttpGet(url)
                local data = HS:JSONDecode(res)
                if data and data.Name then
                    name = data.Name
                elseif data and data.name then
                    name = data.name
                end
            end
        end)
    end
    if not name then
        for _, infoType in ipairs({Enum.InfoType.GamePass, Enum.InfoType.Product, Enum.InfoType.Asset}) do
            pcall(function()
                local info = MPS:GetProductInfo(id, infoType)
                if info and info.Name and info.Name ~= "" then name = info.Name end
            end)
            if name then break end
        end
    end
    if name then nameCache[id] = name end
    return name
end

local TIF = TweenInfo.new(0.18, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local TIM = TweenInfo.new(0.30, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local TIS = TweenInfo.new(0.50, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local resizing = false

-- HELPERS
local function corner(inst, r)
    local c = Instance.new("UICorner", inst)
    c.CornerRadius = UDim.new(0, r or 10)
    return c
end

local function stroke(inst, col, t)
    local s = Instance.new("UIStroke", inst)
    s.Color     = col or C.border
    s.Thickness = t or 1
    return s
end

local function tw(inst, info, props)
    TweenService:Create(inst, info, props):Play()
end

local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(inp)
        if (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) and not resizing then
            dragging = true
            dragStart = inp.Position
            startPos = frame.Position
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
                    end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- VISUAL FX (merged script)
do
    local FX = {
        BLUR_SIZE = 24, BRIGHTNESS_TARGET = 1, TWEEN_TIME = 0.8,
        STAR_SIZE_MIN = 2, STAR_SIZE_MAX = 7, STAR_SPEED_MIN = 1.5, STAR_SPEED_MAX = 3.5, SPAWN_INTERVAL = 0.03,
        STAR_COLOR = Color3.fromRGB(255, 255, 255), PARALLAX_STRENGTH = 0.02, PARALLAX_SMOOTH = 0.08, FOG_DENSITY = 0.3,
        AMBIENT_SOUND_ID = "rbxassetid://9120386430", AMBIENT_VOLUME = 0.4,
        DUST_SIZE = UDim2.new(0, 3, 0, 3), DUST_LIFETIME = 0.8, DUST_SPAWN_RATE = 0.02, DUST_COLOR = Color3.fromRGB(255, 255, 255), DUST_Y_OFFSET = -55,
    }
    local S = {
        originalBrightness = Lighting.Brightness,
        blurEffect = nil, blurTween = nil,
        screenGui = nil, starContainer = nil, timeGui = nil, ambientSound = nil, dustGui = nil, dustContainer = nil, fpsPingGui = nil,
        starLoopRunning = false, dustLoopRunning = false,
        currentFps = 0, currentPing = 0, mouseX = 0, mouseY = 0, offsetX = 0, offsetY = 0, parallaxConnection = nil,
    }

    do
        local frames, lastTime = 0, tick()
        RunService.Heartbeat:Connect(function()
            frames = frames + 1
            if tick() - lastTime >= 1 then
                S.currentFps = math.floor(frames / (tick() - lastTime))
                S.currentPing = math.floor(player:GetNetworkPing() * 1000)
                frames = 0
                lastTime = tick()
            end
        end)
    end

    local function fxSetBlurAndBrightness(blurSize, brightness)
        if S.blurTween then S.blurTween:Cancel(); S.blurTween = nil end
        if blurSize > 0 then
            if not S.blurEffect then S.blurEffect = Instance.new("BlurEffect"); S.blurEffect.Size = 0; S.blurEffect.Parent = Lighting end
            S.blurTween = TweenService:Create(S.blurEffect, TweenInfo.new(FX.TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = blurSize})
            S.blurTween:Play()
        else
            if S.blurEffect then
                S.blurTween = TweenService:Create(S.blurEffect, TweenInfo.new(FX.TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 0})
                S.blurTween:Play()
                S.blurTween.Completed:Connect(function() if S.blurEffect then S.blurEffect:Destroy(); S.blurEffect = nil end end)
            end
        end
        TweenService:Create(Lighting, TweenInfo.new(FX.TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Brightness = brightness}):Play()
    end

    local function fxCreateStar()
        local s = Instance.new("Frame")
        s.BorderSizePixel = 0
        s.BackgroundColor3 = FX.STAR_COLOR
        s.AnchorPoint = Vector2.new(0.5, 0)
        local sz = math.random(FX.STAR_SIZE_MIN, FX.STAR_SIZE_MAX)
        s.Size = UDim2.new(0, sz, 0, sz)
        Instance.new("UICorner", s).CornerRadius = UDim.new(0, 1)
        return s
    end
    local function fxSpawnStar()
        if not S.starContainer then return end
        local s = fxCreateStar()
        s.Parent = S.starContainer
        s.ZIndex = 2
        local sz = math.random(FX.STAR_SIZE_MIN, FX.STAR_SIZE_MAX)
        s.Size = UDim2.new(0, sz, 0, sz)
        s.Position = UDim2.new(math.random(), 0, -0.05, 0)
        s.BackgroundTransparency = 0.1 + math.random() * 0.5
        local dur = math.random(FX.STAR_SPEED_MIN * 100, FX.STAR_SPEED_MAX * 100) / 100
        local tws = TweenService:Create(s, TweenInfo.new(dur, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Position = UDim2.new(s.Position.X.Scale, 0, 1.1, 0), BackgroundTransparency = 1})
        tws:Play()
        tws.Completed:Connect(function()
            if s and s.Parent then
                s:Destroy()
            end
        end)
    end
    local function fxStartStars()
        if S.starLoopRunning then return end
        S.starLoopRunning = true
        for _ = 1, 18 do
            fxSpawnStar()
        end
        task.spawn(function() while S.starLoopRunning and S.screenGui and S.screenGui.Enabled do fxSpawnStar(); task.wait(FX.SPAWN_INTERVAL) end end)
    end
    local function fxStopStars() S.starLoopRunning = false end

    local function fxStartParallax()
        local pos = UIS:GetMouseLocation(); S.mouseX, S.mouseY = pos.X, pos.Y
        S.parallaxConnection = RunService.Heartbeat:Connect(function()
            if not S.starContainer then return end
            local p = UIS:GetMouseLocation(); S.mouseX, S.mouseY = p.X, p.Y
            local vp = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1920, 1080)
            local tx = (S.mouseX / vp.X - 0.5) * FX.PARALLAX_STRENGTH * vp.X
            local ty = (S.mouseY / vp.Y - 0.5) * FX.PARALLAX_STRENGTH * vp.Y
            S.offsetX = S.offsetX + (tx - S.offsetX) * FX.PARALLAX_SMOOTH
            S.offsetY = S.offsetY + (ty - S.offsetY) * FX.PARALLAX_SMOOTH
            S.starContainer.Position = UDim2.new(0.5, S.offsetX, 0.5, S.offsetY)
        end)
    end
    local function fxStopParallax()
        if S.parallaxConnection then S.parallaxConnection:Disconnect(); S.parallaxConnection = nil end
        S.offsetX, S.offsetY = 0, 0
    end

    local function fxStartSound()
        local assetId = tonumber(string.match(FX.AMBIENT_SOUND_ID or "", "%d+"))
        if not assetId then return end
        local isSoundAsset = false
        pcall(function()
            local info = MPS:GetProductInfo(assetId, Enum.InfoType.Asset)
            if info and info.AssetTypeId == 3 then
                isSoundAsset = true
            end
        end)
        if not isSoundAsset then
            return
        end
        if S.ambientSound then S.ambientSound:Stop(); S.ambientSound:Destroy() end
        S.ambientSound = Instance.new("Sound")
        S.ambientSound.SoundId = FX.AMBIENT_SOUND_ID
        S.ambientSound.Looped = true
        S.ambientSound.Volume = 0
        S.ambientSound.Parent = playerGui
        S.ambientSound:Play()
        TweenService:Create(S.ambientSound, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Volume = FX.AMBIENT_VOLUME}):Play()
    end
    local function fxStopSound()
        if S.ambientSound then
            local t = TweenService:Create(S.ambientSound, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Volume = 0})
            t:Play()
            t.Completed:Connect(function() if S.ambientSound then S.ambientSound:Stop(); S.ambientSound:Destroy(); S.ambientSound = nil end end)
        end
    end

    local function fxCreateTimeGui()
        if S.timeGui then S.timeGui:Destroy() end
        S.timeGui = Instance.new("ScreenGui"); S.timeGui.Name = "ThunderstormFxTime"; S.timeGui.ResetOnSpawn = false; S.timeGui.DisplayOrder = 10; S.timeGui.Parent = playerGui
        local c = Instance.new("Frame"); c.Size = UDim2.new(0, 200, 0, 70); c.Position = UDim2.new(0, 20, 1, -90); c.BackgroundTransparency = 1; c.Parent = S.timeGui
        local d = Instance.new("TextLabel"); d.Name = "DateLabel"; d.Size = UDim2.new(1, 0, 0, 20); d.BackgroundTransparency = 1; d.TextColor3 = Color3.fromRGB(220,220,255); d.TextSize = 16; d.Font = Enum.Font.GothamMedium; d.TextXAlignment = Enum.TextXAlignment.Left; d.Parent = c
        local t = Instance.new("TextLabel"); t.Name = "TimeLabel"; t.Size = UDim2.new(1, 0, 0, 40); t.Position = UDim2.new(0,0,0,22); t.BackgroundTransparency = 1; t.TextColor3 = Color3.fromRGB(255,255,255); t.TextSize = 40; t.Font = Enum.Font.GothamBold; t.TextXAlignment = Enum.TextXAlignment.Left; t.Parent = c
        task.spawn(function()
            while S.timeGui and S.timeGui.Parent do
                local now = os.time() + 3 * 3600
                d.Text = os.date("!%A %d.%m", now)
                t.Text = os.date("!%H:%M:%S", now)
                task.wait(1)
            end
        end)
    end
    local function fxRemoveTimeGui() if S.timeGui then S.timeGui:Destroy(); S.timeGui = nil end end

    local function fxCreateFpsPingGui()
        if S.fpsPingGui then S.fpsPingGui:Destroy() end
        S.fpsPingGui = Instance.new("ScreenGui"); S.fpsPingGui.Name = "ThunderstormFxNet"; S.fpsPingGui.ResetOnSpawn = false; S.fpsPingGui.DisplayOrder = 10; S.fpsPingGui.Parent = playerGui
        local c = Instance.new("Frame"); c.Size = UDim2.new(0, 170, 0, 50); c.Position = UDim2.new(1, -20, 1, -30); c.AnchorPoint = Vector2.new(1,1); c.BackgroundTransparency = 1; c.Parent = S.fpsPingGui
        local f = Instance.new("TextLabel"); f.Name = "F"; f.Size = UDim2.new(1,0,0,24); f.BackgroundTransparency = 1; f.TextColor3 = Color3.fromRGB(255,255,255); f.TextSize = 18; f.Font = Enum.Font.GothamBold; f.TextXAlignment = Enum.TextXAlignment.Right; f.Parent = c
        local p = Instance.new("TextLabel"); p.Name = "P"; p.Size = UDim2.new(1,0,0,24); p.Position = UDim2.new(0,0,0,26); p.BackgroundTransparency = 1; p.TextColor3 = Color3.fromRGB(255,255,255); p.TextSize = 18; p.Font = Enum.Font.GothamBold; p.TextXAlignment = Enum.TextXAlignment.Right; p.Parent = c
        task.spawn(function()
            while S.fpsPingGui and S.fpsPingGui.Parent do
                f.Text = "FPS: " .. tostring(S.currentFps)
                p.Text = "Ping: " .. tostring(S.currentPing) .. " ms"
                task.wait(0.5)
            end
        end)
    end
    local function fxRemoveFpsPingGui() if S.fpsPingGui then S.fpsPingGui:Destroy(); S.fpsPingGui = nil end end

    local function fxCreateDust()
        if S.dustGui then S.dustGui:Destroy() end
        S.dustGui = Instance.new("ScreenGui"); S.dustGui.Name = "ThunderstormFxDust"; S.dustGui.ResetOnSpawn = false; S.dustGui.DisplayOrder = 5; S.dustGui.Parent = playerGui
        S.dustContainer = Instance.new("Frame"); S.dustContainer.Size = UDim2.new(1,0,1,0); S.dustContainer.BackgroundTransparency = 1; S.dustContainer.Parent = S.dustGui
        S.dustLoopRunning = true
        task.spawn(function()
            while S.dustLoopRunning and S.dustGui and S.dustGui.Parent do
                local p = UIS:GetMouseLocation()
                local d = Instance.new("Frame")
                d.Size = FX.DUST_SIZE; d.AnchorPoint = Vector2.new(0.5,0.5); d.Position = UDim2.new(0,p.X,0,p.Y + FX.DUST_Y_OFFSET)
                d.BackgroundColor3 = FX.DUST_COLOR; d.BackgroundTransparency = 0.4; d.BorderSizePixel = 0
                Instance.new("UICorner", d).CornerRadius = UDim.new(0, 1); d.Parent = S.dustContainer
                local twd = TweenService:Create(d, TweenInfo.new(FX.DUST_LIFETIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, p.X + math.random(-40,40), 0, p.Y + math.random(-40,40) + FX.DUST_Y_OFFSET), BackgroundTransparency = 1, Size = UDim2.new(0,1,0,1)})
                twd:Play(); twd.Completed:Connect(function() if d then d:Destroy() end end)
                task.wait(FX.DUST_SPAWN_RATE)
            end
        end)
    end
    local function fxRemoveDust() S.dustLoopRunning = false; if S.dustGui then S.dustGui:Destroy(); S.dustGui = nil end end

    local function fxHardCleanup(resetBrightness)
        fxStopStars()
        fxStopParallax()
        if S.screenGui then S.screenGui:Destroy(); S.screenGui = nil end
        if S.timeGui then S.timeGui:Destroy(); S.timeGui = nil end
        if S.fpsPingGui then S.fpsPingGui:Destroy(); S.fpsPingGui = nil end
        fxRemoveDust()
        fxStopSound()
        if resetBrightness then
            fxSetBlurAndBrightness(0, S.originalBrightness)
        end
    end

    setFxEnabled = function(enable, updateState)
        if updateState ~= false then
            fxEnabled = enable
        end
        if enable then
            fxHardCleanup(false)
            S.screenGui = Instance.new("ScreenGui"); S.screenGui.Name = "MatchaStarsGui"; S.screenGui.IgnoreGuiInset = true; S.screenGui.ResetOnSpawn = false; S.screenGui.DisplayOrder = 0; S.screenGui.Parent = playerGui
            S.starContainer = Instance.new("Frame"); S.starContainer.Size = UDim2.new(1,0,1,0); S.starContainer.BackgroundTransparency = 1; S.starContainer.AnchorPoint = Vector2.new(0.5,0.5); S.starContainer.Position = UDim2.new(0.5,0,0.5,0); S.starContainer.ClipsDescendants = false; S.starContainer.Parent = S.screenGui
            local atmos = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting); atmos.Density = FX.FOG_DENSITY
            fxStartSound(); fxCreateTimeGui(); fxCreateFpsPingGui(); fxCreateDust(); fxStartStars(); fxStartParallax(); fxSetBlurAndBrightness(FX.BLUR_SIZE, FX.BRIGHTNESS_TARGET)
        else
            local atmos = Lighting:FindFirstChildOfClass("Atmosphere")
            if atmos then TweenService:Create(atmos, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Density = 0}):Play() end
            fxHardCleanup(true)
        end
    end
end

-- SCREEN GUI
local sg = Instance.new("ScreenGui")
sg.Name            = "ThunderstormUI"
sg.ResetOnSpawn    = false
sg.ZIndexBehavior  = Enum.ZIndexBehavior.Global
sg.IgnoreGuiInset  = true
sg.Parent          = playerGui

do
    local lf = Instance.new("Frame")
    lf.Size             = UDim2.new(0, PW, 0, PH)
    lf.Position         = UDim2.new(0, (State.vp.X - PW) / 2, 0, (State.vp.Y - PH) / 2)
    lf.BackgroundColor3 = C.bg
    lf.BorderSizePixel  = 0
    lf.ZIndex           = 100
    lf.Parent           = sg
    corner(lf, 16)
    stroke(lf, C.border, 1)
    makeDraggable(lf)

    local lglow = Instance.new("Frame")
    lglow.Size             = UDim2.new(0, 0, 0, 2)
    lglow.BackgroundColor3 = C.accent
    lglow.BorderSizePixel  = 0
    lglow.ZIndex           = 101
    lglow.Parent           = lf
    corner(lglow, 2)

    local llogo = Instance.new("TextLabel")
    llogo.Size               = UDim2.new(1, 0, 0, 60)
    llogo.Position           = UDim2.new(0, 0, 0.30, 0)
    llogo.BackgroundTransparency = 1
    llogo.Text               = "Thunderstorm"
    llogo.TextColor3         = C.accent
    llogo.TextSize           = 42
    llogo.Font               = Enum.Font.GothamBold
    llogo.ZIndex             = 101
    llogo.Parent             = lf

    local lsub = Instance.new("TextLabel")
    lsub.Size               = UDim2.new(1, 0, 0, 22)
    lsub.Position           = UDim2.new(0, 0, 0.30, 64)
    lsub.BackgroundTransparency = 1
    lsub.Text               = "Product Spoofer  \194\183  v0.4"
    lsub.TextColor3         = C.textDim
    lsub.TextSize           = 13
    lsub.Font               = Enum.Font.Gotham
    lsub.TextXAlignment     = Enum.TextXAlignment.Center
    lsub.ZIndex             = 101
    lsub.Parent             = lf

    local spinF = Instance.new("Frame")
    spinF.Size               = UDim2.new(0, 60, 0, 14)
    spinF.Position           = UDim2.new(0.5, -30, 0.62, 0)
    spinF.BackgroundTransparency = 1
    spinF.ZIndex             = 101
    spinF.Parent             = lf

    local dots = {}
    local dotRestY = {}
    for i = 1, 4 do
        local d = Instance.new("Frame")
        d.Size                 = UDim2.new(0, 10, 0, 10)
        d.Position             = UDim2.new(0, (i - 1) * 18, 0.5, -5)
        d.BackgroundColor3     = C.accent
        d.BackgroundTransparency = 0.3
        d.BorderSizePixel      = 0
        d.ZIndex               = 102
        d.Parent               = spinF
        corner(d, 999)
        dots[i] = d
        dotRestY[i] = d.Position
        d.Visible = false
    end

    local pbg = Instance.new("Frame")
    pbg.Size             = UDim2.new(0, PW * 0.55, 0, 3)
    pbg.Position         = UDim2.new(0.5, -PW * 0.275, 0.75, 0)
    pbg.BackgroundColor3 = C.surfaceHi
    pbg.BorderSizePixel  = 0
    pbg.ZIndex           = 101
    pbg.Visible          = false
    pbg.Parent           = lf
    corner(pbg, 2)

    local pbar = Instance.new("Frame")
    pbar.Size             = UDim2.new(0, 0, 1, 0)
    pbar.BackgroundColor3 = C.accent
    pbar.BorderSizePixel  = 0
    pbar.ZIndex           = 102
    pbar.Parent           = pbg
    corner(pbar, 2)

    local lstat = Instance.new("TextLabel")
    lstat.Size               = UDim2.new(1, 0, 0, 20)
    lstat.Position           = UDim2.new(0, 0, 0.75, 10)
    lstat.BackgroundTransparency = 1
    lstat.Text               = "Loading..."
    lstat.TextColor3         = C.textMuted
    lstat.TextSize           = 13
    lstat.Font               = Enum.Font.Gotham
    lstat.TextXAlignment     = Enum.TextXAlignment.Center
    lstat.ZIndex             = 101
    lstat.Parent           = lf


    local function startLoading()
        pbg.Visible = true; lstat.Visible = true
        for _, d in ipairs(dots) do d.Visible = true end
        local _e,_ls,_f = 0,0,false
        local SD, T = 0.5, 3.3
        local _m = {{t="Initializing...",p=0.1},{t="Hooking signals...",p=0.35},{t="Loading components...",p=0.6},{t="Almost ready...",p=0.85},{t="Done!",p=1}}
        local _lc
        _lc = RunService.Heartbeat:Connect(function(dt)
            if _f then return end
            _e=_e+dt
            for i=1,4 do
                local phase = (_e - (i-1)*0.12) % 0.6
                local bounce = math.sin((phase/0.6) * math.pi)
                dots[i].Position = UDim2.new(dotRestY[i].X.Scale, dotRestY[i].X.Offset, dotRestY[i].Y.Scale, dotRestY[i].Y.Offset - bounce*8)
                dots[i].BackgroundTransparency = 0.3 - bounce*0.3
            end
            local c=math.min(math.floor(_e/SD)+1,#_m)
            if c~=_ls then _ls=c; lstat.Text=_m[c].t
                tw(pbar,TweenInfo.new(0.45,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(_m[c].p,0,1,0)})
            end
            if _e>=T then
                _f=true; _lc:Disconnect()
                tw(lf,TIF,{BackgroundTransparency=1})
                tw(llogo,TIF,{TextTransparency=1})
                tw(lsub,TIF,{TextTransparency=1})
                tw(lstat,TIF,{TextTransparency=1})
                tw(pbg,TIF,{BackgroundTransparency=1})
                tw(pbar,TIF,{BackgroundTransparency=1})
                task.wait(0.5)
                lf.Visible=false; lf:Destroy()
                if UI.Main then
                    UI.Main.Visible=true
                    tw(UI.Main,TweenInfo.new(0.6,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundTransparency=0.15})
                end
            end
        end)
    end

    task.delay(0, function()
        startLoading()
    end)

end

-- MAIN PANEL
local panel = Instance.new("Frame")
panel.Name                 = "Panel"
panel.Size                 = UDim2.new(0, PW, 0, PH)
panel.Position             = UDim2.new(0, (State.vp.X - PW) / 2, 0, (State.vp.Y - PH) / 2)
panel.BackgroundColor3     = C.bg
panel.BorderSizePixel      = 0
panel.ClipsDescendants     = false
panel.BackgroundTransparency = 1
panel.Visible              = false
panel.ZIndex               = 1
panel.Parent               = sg
UI.Main = panel

corner(UI.Main, 12)
local pst = stroke(UI.Main, Color3.fromRGB(255, 255, 255), 1.5)
pst.Transparency = 0.85
UI.MainStroke = pst

local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 120, 120))
}
grad.Parent = pst
panel.ClipsDescendants     = false

do
    local tabBar = Instance.new("Frame")
    tabBar.Name             = "TabBar"
    tabBar.Size             = UDim2.new(0.35, 0, 0, BH)
    tabBar.Position         = UDim2.new(0.5, 0, 1, -20)
    tabBar.AnchorPoint      = Vector2.new(0.5, 1)
    tabBar.BackgroundColor3 = C.surfaceHi
    tabBar.BackgroundTransparency = 1
    tabBar.BorderSizePixel  = 0
    tabBar.ZIndex           = 500
    tabBar.Parent           = UI.Main
    local tst = stroke(tabBar, Color3.fromRGB(255, 255, 255), 1.5)
    tst.Transparency = 0.755
    UI.TabBarStroke = tst
    UI.TabBar = tabBar

    local countLabel = Instance.new("TextLabel")
    countLabel.Size             = UDim2.new(0, 140, 0, 20)
    local countLabel = Instance.new("TextLabel")
    countLabel.Size             = UDim2.new(0, 140, 0, 20)
    countLabel.Position         = UDim2.new(0, 20, 1, -34)
    countLabel.AnchorPoint      = Vector2.new(0, 0.5)
    countLabel.BackgroundTransparency = 1
    countLabel.Text             = "0 events captured"
    countLabel.TextColor3       = C.textDim
    countLabel.TextSize         = FS
    countLabel.Font             = Enum.Font.Gotham
    countLabel.ZIndex           = 500
    countLabel.Visible          = false
    countLabel.Parent           = UI.Main
    UI.OldCountLabel = countLabel

    local eventLabel = Instance.new("TextLabel")
    eventLabel.Size             = UDim2.new(0, 140, 0, 20)
    eventLabel.Position         = UDim2.new(0, 20, 0, -24)
    eventLabel.BackgroundTransparency = 1
    eventLabel.Text             = "0 events captured"
    eventLabel.TextColor3       = C.textDim
    eventLabel.TextSize         = FS
    eventLabel.Font             = Enum.Font.Gotham
    eventLabel.Parent           = UI.Main
    UI.CountLabel = eventLabel

    local rateLabel = Instance.new("TextLabel")
    rateLabel.Size             = UDim2.new(0, 110, 0, 20)
    rateLabel.Position         = UDim2.new(1, -110, 1, -34)
    rateLabel.AnchorPoint      = Vector2.new(1, 0.5)
    rateLabel.BackgroundTransparency = 1
    rateLabel.Text             = "0 sig/s"
    rateLabel.TextColor3       = C.textDim
    rateLabel.TextSize         = FS
    rateLabel.Font             = Enum.Font.Gotham
    rateLabel.TextXAlignment   = Enum.TextXAlignment.Right
    rateLabel.ZIndex           = 500
    rateLabel.Visible          = State.showRateMonitor
    rateLabel.Parent           = UI.Main
    UI.RateLabel = rateLabel
end

-- resize handle
do
    local h = Instance.new("Frame")
    h.Name             = "ResizeHandle"
    h.Size             = UDim2.new(0, 18, 0, 18)
    h.Position         = UDim2.new(1, -2, 1, -2)
    h.BackgroundTransparency = 1
    h.ZIndex           = 10
    h.Parent           = UI.Main
    corner(h, 4)

    local rs, ssz
    h.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            rs       = i.Position
            ssz      = UI.Main.AbsoluteSize
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if resizing and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - rs
            UI.Main.Size = UDim2.new(0, math.max(PW, ssz.X + d.X), 0, math.max(PH, ssz.Y + d.Y))
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end)
end

-- TITLE BAR
do
    local tb = Instance.new("Frame")
    tb.Name = "TitleBar"
    tb.Size = UDim2.new(1, 0, 0, TH)
    tb.Position = UDim2.new(0, 0, 0, 0)
    tb.BackgroundColor3 = C.bg
    tb.BorderSizePixel = 0
    tb.ZIndex = 400
    tb.Parent = UI.Main
    UI.TitleBar = tb
    corner(UI.TitleBar, 12)

    local tbLine = Instance.new("Frame")
    tbLine.Size = UDim2.new(1, 0, 0, 1)
    tbLine.Position = UDim2.new(0, 0, 1, -1)
    tbLine.BackgroundColor3 = C.border
    tbLine.BorderSizePixel = 0
    tbLine.ZIndex = 402
    tbLine.Parent = tb
    UI.TitleBarLine = tbLine

    makeDraggable(UI.Main, tb)

    local liveDot = Instance.new("Frame")
    liveDot.Size             = UDim2.new(0, 9, 0, 9)
    liveDot.Position         = UDim2.new(0, 18, 0.5, 0)
    liveDot.AnchorPoint      = Vector2.new(0.5, 0.5)
    liveDot.BackgroundColor3 = C.green
    liveDot.BorderSizePixel  = 0
    liveDot.ZIndex           = 403
    liveDot.Parent           = tb
    corner(liveDot, 999)

    local liveLabel = Instance.new("TextLabel")
    liveLabel.Size               = UDim2.new(0, 46, 0, 20)
    liveLabel.Position           = UDim2.new(0, 28, 0.5, -10)
    liveLabel.BackgroundTransparency = 1
    liveLabel.Text               = "LIVE"
    liveLabel.TextColor3         = C.green
    liveLabel.TextSize           = 10
    liveLabel.Font               = Enum.Font.GothamBold
    liveLabel.TextXAlignment     = Enum.TextXAlignment.Left
    liveLabel.ZIndex             = 403
    liveLabel.Parent             = UI.TitleBar
    UI.LiveLabel = liveLabel

    task.spawn(function()
        local pt = 0
        while sg.Parent do
            local dt = task.wait()
            pt = pt + dt
            liveDot.BackgroundTransparency = 0.2 + 0.2 * math.sin(pt * 3)
        end
    end)

    local titleText = Instance.new("TextLabel")
    titleText.Size               = UDim2.new(1, 0, 1, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text               = "Thunderstorm"
    titleText.TextColor3         = C.text
    titleText.TextXAlignment     = Enum.TextXAlignment.Center
    titleText.TextSize           = 22
    titleText.Font               = Enum.Font.GothamBold
    titleText.ZIndex             = 402
    titleText.Parent             = UI.TitleBar
    UI.TitleText = titleText

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size             = UDim2.new(0, 28, 0, 28)
    closeBtn.Position         = UDim2.new(1, -38, 0.5, -14)
    closeBtn.BackgroundColor3 = C.surfaceHi
    closeBtn.Text             = "X"
    closeBtn.TextColor3       = C.textMuted
    closeBtn.TextSize         = 14
    closeBtn.Font             = Enum.Font.GothamBold
    closeBtn.BorderSizePixel  = 0
    closeBtn.AutoButtonColor  = false
    closeBtn.ZIndex           = 403
    closeBtn.Parent           = UI.TitleBar
    corner(closeBtn, 8)
    UI.CloseBtnStroke = stroke(closeBtn, C.border, 1)
    UI.CloseBtn = closeBtn

    -- Close button state is handled later by hideGui to keep reopen button logic consistent.

end

-- Stop / Clear buttons
local stopAllBtn = Instance.new("TextButton")
stopAllBtn.Size             = UDim2.new(0, 42, 0, BH)
stopAllBtn.Position         = UDim2.new(1, -35, 1, -20)
stopAllBtn.AnchorPoint      = Vector2.new(1, 1)
stopAllBtn.BackgroundColor3 = C.surfaceHi
stopAllBtn.Text             = "Stop"
stopAllBtn.TextColor3       = C.textMuted
stopAllBtn.TextSize         = FS
stopAllBtn.Font             = Enum.Font.GothamBold
stopAllBtn.BorderSizePixel  = 0
stopAllBtn.AutoButtonColor  = false
stopAllBtn.ZIndex           = 500
stopAllBtn.Parent           = UI.Main
corner(stopAllBtn, 8)
UI.StopAllBtnStroke = stroke(stopAllBtn, C.border, 1)
UI.StopAllBtn = stopAllBtn

local clearBtn = Instance.new("TextButton")
clearBtn.Size             = UDim2.new(0, 76, 0, BH)
clearBtn.Position         = UDim2.new(1, -80, 1, -20)
clearBtn.AnchorPoint      = Vector2.new(1, 1)
clearBtn.BackgroundColor3 = C.surfaceHi
clearBtn.Text             = "Clear"
clearBtn.TextColor3       = C.textMuted
clearBtn.TextSize         = FS
clearBtn.Font             = Enum.Font.GothamBold
clearBtn.BorderSizePixel  = 0
clearBtn.AutoButtonColor  = false
clearBtn.ZIndex           = 500
clearBtn.Parent           = UI.Main
corner(clearBtn, 7)
UI.ClearBtnStroke = stroke(clearBtn, C.border, 1)
UI.ClearBtn = clearBtn

-- SIDE GAME WINDOW
local gameInfoPanel = Instance.new("Frame")
gameInfoPanel.Name = "GameInfoPanel"
gameInfoPanel.Size = UDim2.new(0, 280, 0, 180)
gameInfoPanel.Position = UDim2.new(0, panel.Position.X.Offset + panel.Size.X.Offset + 10, 0, panel.Position.Y.Offset)
gameInfoPanel.BackgroundColor3 = C.bg
gameInfoPanel.BorderSizePixel = 0
gameInfoPanel.Visible = false
gameInfoPanel.ZIndex = 2
gameInfoPanel.Parent = sg
corner(gameInfoPanel, 12)
local gameInfoStroke = stroke(gameInfoPanel, C.border, 1)
UI.GameInfo = gameInfoPanel
UI.GameInfo.Position = UDim2.new(0, panel.Position.X.Offset + panel.Size.X.Offset + 10, 0, panel.Position.Y.Offset)

local gameInfoHeader = Instance.new("Frame")
gameInfoHeader.Size = UDim2.new(1, 0, 0, 38)
gameInfoHeader.BackgroundColor3 = C.bg
gameInfoHeader.BorderSizePixel = 0
gameInfoHeader.ZIndex = 3
gameInfoHeader.Parent = UI.GameInfo
corner(gameInfoHeader, 12)
UI.GameInfoHeader = gameInfoHeader

local gameInfoHeaderFill = Instance.new("Frame")
gameInfoHeaderFill.Size = UDim2.new(1, 0, 0, 14)
gameInfoHeaderFill.Position = UDim2.new(0, 0, 1, -14)
gameInfoHeaderFill.BackgroundColor3 = C.bg
gameInfoHeaderFill.BorderSizePixel = 0
gameInfoHeaderFill.ZIndex = 3
gameInfoHeaderFill.Parent = UI.GameInfoHeader
UI.GameInfoHeaderFill = gameInfoHeaderFill

local gameInfoTitle = Instance.new("TextLabel")
gameInfoTitle.Size = UDim2.new(1, -16, 1, 0)
gameInfoTitle.Position = UDim2.new(0, 8, 0, 0)
gameInfoTitle.BackgroundTransparency = 1
gameInfoTitle.Text = "Current Game"
gameInfoTitle.TextColor3 = C.text
gameInfoTitle.TextSize = 14
gameInfoTitle.Font = Enum.Font.GothamBold
gameInfoTitle.TextXAlignment = Enum.TextXAlignment.Left
gameInfoTitle.ZIndex = 4
gameInfoTitle.Parent = UI.GameInfoHeader
UI.GameInfoTitle = gameInfoTitle

local gameInfoImage = Instance.new("ImageLabel")
gameInfoImage.Size = UDim2.new(0, 78, 0, 78)
gameInfoImage.Position = UDim2.new(0, 10, 0, 48)
gameInfoImage.BackgroundColor3 = C.surfaceHi
gameInfoImage.BorderSizePixel = 0
gameInfoImage.Image = string.format("rbxthumb://type=GameIcon&id=%d&w=150&h=150", game.GameId ~= 0 and game.GameId or game.PlaceId)
gameInfoImage.ScaleType = Enum.ScaleType.Fit
gameInfoImage.ZIndex = 3
gameInfoImage.Parent = gameInfoPanel
corner(gameInfoImage, 10)
local gameImageStroke = stroke(gameInfoImage, C.border, 1)

local gameInfoName = Instance.new("TextLabel")
gameInfoName.Size = UDim2.new(1, -104, 0, 78)
gameInfoName.Position = UDim2.new(0, 96, 0, 48)
gameInfoName.BackgroundTransparency = 1
gameInfoName.TextWrapped = true
do
    local resolvedGameName = "Unknown Game"
    pcall(function()
        local info = MPS:GetProductInfo(game.PlaceId, Enum.InfoType.Asset)
        if info and info.Name then
            resolvedGameName = info.Name
        end
    end)
    gameInfoName.Text = resolvedGameName
end
gameInfoName.TextColor3 = C.text
gameInfoName.TextSize = 12
gameInfoName.Font = Enum.Font.GothamBold
gameInfoName.TextXAlignment = Enum.TextXAlignment.Left
gameInfoName.TextYAlignment = Enum.TextYAlignment.Center
gameInfoName.ZIndex = 3
gameInfoName.Parent = gameInfoPanel

local function getAccountAgeText(days)
    if days >= 365 then return string.format("%d y", math.floor(days / 365)) end
    if days >= 30 then return string.format("%d mo", math.floor(days / 30)) end
    return string.format("%d d", days)
end

local gameMetaPanel = Instance.new("Frame")
gameMetaPanel.Size = UDim2.new(1, -12, 0, 44)
gameMetaPanel.Position = UDim2.new(0, 6, 1, -50)
gameMetaPanel.BackgroundColor3 = C.surfaceHi
gameMetaPanel.BorderSizePixel = 0
gameMetaPanel.ZIndex = 3
gameMetaPanel.Parent = gameInfoPanel
corner(gameMetaPanel, 10)
local gameMetaStroke = stroke(gameMetaPanel, C.border, 1)

local gameMetaText = Instance.new("TextLabel")
gameMetaText.Size = UDim2.new(1, -10, 1, -8)
gameMetaText.Position = UDim2.new(0, 5, 0, 4)
gameMetaText.BackgroundTransparency = 1
gameMetaText.TextXAlignment = Enum.TextXAlignment.Left
gameMetaText.TextYAlignment = Enum.TextYAlignment.Top
gameMetaText.TextSize = 10
gameMetaText.Font = Enum.Font.Gotham
gameMetaText.TextColor3 = C.textDim
gameMetaText.Text = string.format("v0.4  |  %s (@%s)\nAge: %s  |  PlaceId: %d\nExecutor: %s", player.DisplayName, player.Name, getAccountAgeText(player.AccountAge), game.PlaceId, identifyexecutor and identifyexecutor() or "Unknown")
gameMetaText.ZIndex = 4
gameMetaText.Parent = gameMetaPanel

local gameStatusText = Instance.new("TextLabel")
gameStatusText.Size = UDim2.new(0, 90, 0, 14)
gameStatusText.Position = UDim2.new(1, -94, 0, 4)
gameStatusText.BackgroundTransparency = 1
gameStatusText.TextXAlignment = Enum.TextXAlignment.Right
gameStatusText.TextYAlignment = Enum.TextYAlignment.Top
gameStatusText.TextSize = 10
gameStatusText.Font = Enum.Font.GothamBold
do
    local okSignal = pcall(function()
        return typeof(MPS.SignalPromptPurchaseFinished) == "function"
    end)
    if okSignal then
        gameStatusText.Text = ""
        gameStatusText.TextColor3 = C.green
    else
        gameStatusText.Text = ""
        gameStatusText.TextColor3 = C.red
    end
end
gameStatusText.ZIndex = 4
gameStatusText.Parent = gameMetaPanel

-- TAB SYSTEM
local tabs = {}
local activeTab = nil

local function createPage()
    local p = Instance.new("Frame")
    p.Size             = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.BorderSizePixel  = 0
    p.Visible          = false
    p.Parent           = UI.Main
    return p
end

local function switchTab(name)
    if State.activeTab == name then return end
    State.activeTab = name
    for n, d in pairs(UI.Tabs) do
        local on = n == name
        d.page.Visible = on
        if d.btn then
            tw(d.btn, TIF, {
                BackgroundColor3       = C.surfaceHi,
                BackgroundTransparency = 1,
                TextColor3             = on and C.accent or C.textDim,
            })
            local iconImg = d.btn:FindFirstChild("Icon")
            if iconImg then
                tw(iconImg, TIF, {ImageColor3 = on and C.accent or C.textDim})
            end
            local s = d.btn:FindFirstChildOfClass("UIStroke")
            if s then tw(s, TIF, {Transparency = on and 0 or 1}) end
        end
    end
end
UI.SwitchTab = switchTab

local function addTab(name, labelOrIcon, order)
    local btn = Instance.new("TextButton")
    btn.Name                 = name .. "Btn"
    btn.Size                 = UDim2.new(0, BH, 0, BH)
    
    if order == 1 then
        btn.Position = UDim2.new(0.38, 0, 1, -34)
    elseif order == 2 then
        btn.Position = UDim2.new(0.5, 0, 1, -34)
    else
        btn.Position = UDim2.new(0.62, 0, 1, -34)
    end
    btn.AnchorPoint          = Vector2.new(0.5, 0.5)
    btn.BackgroundColor3     = C.surfaceHi
    btn.BackgroundTransparency = 1
    btn.AutoButtonColor      = false
    btn.ZIndex               = 600
    btn.LayoutOrder          = order
    btn.Visible              = true
    btn.Parent               = UI.Main
    corner(btn, 8)
    stroke(btn, C.borderHi, 1).Transparency = 1

    local isIcon = (type(labelOrIcon) == "string" and (labelOrIcon:find("rbxassetid://") or labelOrIcon:find("asset")))
    local iconImg
    if isIcon then
        btn.Text = ""
        iconImg = Instance.new("ImageLabel")
        iconImg.Name = "Icon"
        iconImg.Size = UDim2.new(0, 18, 0, 18)
        iconImg.Position = UDim2.new(0.5, 0, 0.5, 0)
        iconImg.AnchorPoint = Vector2.new(0.5, 0.5)
        iconImg.BackgroundTransparency = 1
        iconImg.Image = labelOrIcon
        iconImg.ImageColor3 = C.textDim
        iconImg.ZIndex = 700
        iconImg.Parent = btn
    else
        btn.Text = labelOrIcon
        btn.TextColor3 = C.textMuted
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamBold
    end

    local page = createPage()
    UI.Tabs[name] = {btn = btn, page = page}
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
    
    btn.MouseEnter:Connect(function()
        if State.activeTab ~= name then 
            if isIcon then tw(iconImg, TIF, {ImageColor3 = C.text}) else tw(btn, TIF, {TextColor3 = C.text}) end
        end
    end)
    btn.MouseLeave:Connect(function()
        if State.activeTab ~= name then 
            if isIcon then tw(iconImg, TIF, {ImageColor3 = C.textDim}) else tw(btn, TIF, {TextColor3 = C.textDim}) end
        end
    end)

    return page
end
UI.AddTab = addTab

-- LISTENER TAB
local listenerPage = addTab("Listener", "rbxassetid://7072718840", 1)

local logArea = Instance.new("ScrollingFrame")
logArea.Size                = UDim2.new(1, 0, 1, -(TH + 60))
logArea.Position            = UDim2.new(0, 0, 0, TH)
logArea.BackgroundTransparency = 1
logArea.BorderSizePixel     = 0
logArea.ScrollBarThickness  = State.isMobile and 6 or 3
logArea.ScrollBarImageColor3 = C.accentDim
logArea.CanvasSize          = UDim2.new(0,0,0,0)
logArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
logArea.Parent              = listenerPage

local listL = Instance.new("UIListLayout", logArea)
listL.SortOrder           = Enum.SortOrder.LayoutOrder
listL.Padding             = UDim.new(0, State.isMobile and 8 or 6)
listL.VerticalAlignment   = Enum.VerticalAlignment.Top

local lpad = Instance.new("UIPadding", logArea)
lpad.PaddingTop    = UDim.new(0, 6)
lpad.PaddingBottom = UDim.new(0, 6)
lpad.PaddingLeft   = UDim.new(0, 4)
lpad.PaddingRight  = UDim.new(0, 4)

listL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    logArea.CanvasSize = UDim2.new(0, 0, 0, listL.AbsoluteContentSize.Y + 12)
end)

local function setEmpty(show)
    local e = logArea:FindFirstChild("EmptyState")
    if show and not e then
        local el = Instance.new("TextLabel")
        el.Name               = "EmptyState"
        el.Size               = UDim2.new(1, 0, 0, 240)
        el.BackgroundTransparency = 1
        el.Text               = "Waiting for events...\nAll marketplace signals will appear here."
        el.TextColor3         = C.textDim
        el.TextSize           = FM
        el.Font               = Enum.Font.Gotham
        el.TextWrapped        = true
        el.LayoutOrder        = 99999
        el.TextXAlignment     = Enum.TextXAlignment.Center
        el.Parent             = logArea
    elseif not show and e then
        e:Destroy()
    end
end

local SIG_COLOR = {
    Product  = Color3.fromRGB(100, 200, 255),
    Gamepass = Color3.fromRGB(61,  255, 160),
    Bulk     = Color3.fromRGB(255, 190,  60),
    Purchase = Color3.fromRGB(200, 200, 200),
}

local function showToast(msg, col)
    for _, oldToast in ipairs(UI.Entries) do
        if oldToast and oldToast.Name == "Toast" and oldToast.Parent then
            tw(oldToast, TIM, {BackgroundTransparency = 1, Position = UDim2.new(1, 10, 1, -50)})
            task.delay(0.35, function() pcall(function() oldToast:Destroy() end) end)
        end
    end

    col = col or C.accent
    local toast = Instance.new("Frame")
    toast.Name             = "Toast"
    toast.Size             = UDim2.new(0, 240, 0, 36)
    toast.Position         = UDim2.new(1, 10, 1, -50)
    toast.BackgroundColor3 = C.surface
    toast.BorderSizePixel  = 0
    toast.ZIndex           = 200
    toast.BackgroundTransparency = 1
    toast.Parent           = sg
    corner(toast, 8)
    stroke(toast, col, 1)

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1, -18, 1, 0)
    lbl.Position           = UDim2.new(0, 16, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = msg
    lbl.TextColor3         = C.text
    lbl.TextSize           = FS
    lbl.Font               = Enum.Font.Gotham
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.ZIndex             = 201
    lbl.Parent             = toast

    tw(toast, TIM, {BackgroundTransparency = 0, Position = UDim2.new(1, -250, 1, -50)})
    task.delay(2.2, function()
        if toast.Parent then
            tw(toast, TIM, {BackgroundTransparency = 1, Position = UDim2.new(1, 10, 1, -50)})
            task.delay(0.35, function() pcall(function() toast:Destroy() end) end)
        end
    end)
end
UI.ShowToast = showToast

State.signalTimestamps = {}
local function fireFakeSignal(sigType, id)
    local shouldTrackRate = State.suppressCounter == 0
    State.suppressCounter = State.suppressCounter + 1
    local ok = pcall(function()
        if     sigType == "Product"  then MPS:SignalPromptProductPurchaseFinished(player.UserId, id, true)
        elseif sigType == "Gamepass" then MPS:SignalPromptGamePassPurchaseFinished(player, id, true)
        elseif sigType == "Bulk"     then MPS:SignalPromptBulkPurchaseFinished(player.UserId, id, true)
        elseif sigType == "Purchase" then MPS:SignalPromptPurchaseFinished(player.UserId, id, true)
        end
    end)
    State.suppressCounter = State.suppressCounter - 1
    if ok and shouldTrackRate then
        local now = tick()
        table.insert(State.signalTimestamps, now)
        for i = #State.signalTimestamps, 1, -1 do
            if now - State.signalTimestamps[i] > 5 then table.remove(State.signalTimestamps, i) end
        end
        State.rateSmooth = State.rateSmooth * 0.9 + (#State.signalTimestamps / 5) * 0.1
        if UI.RateLabel then UI.RateLabel.Text = string.format("%.1f sig/s", State.rateSmooth) end
    end
end
UI.FireFakeSignal = fireFakeSignal

local function stopAllAutoAndSpam()
    for btn, data in pairs(UI.ActiveAutoButtons) do
        data.active = false
        if data.loop then task.cancel(data.loop) end
        if btn and btn.Parent then
            btn.Text = "Auto"; btn.TextColor3 = C.textMuted; btn.BackgroundColor3 = C.surfaceHi
        end
    end
    table.clear(UI.ActiveAutoButtons)
    for btn, data in pairs(UI.ActiveSpamButtons) do
        data.active = false
        if data.loop then task.cancel(data.loop) end
        if btn and btn.Parent then
            btn.Text = "\226\150\182"; btn.TextSize = 18; btn.TextColor3 = C.textMuted; btn.BackgroundColor3 = C.surfaceHi
        end
    end
    table.clear(UI.ActiveSpamButtons)
end
UI.StopAllAutoAndSpam = stopAllAutoAndSpam

stopAllBtn.MouseButton1Click:Connect(stopAllAutoAndSpam)

local globalPinned = {}
local function syncEntryPinState(entry, id)
    local isPinned = State.globalPinned[id] == true
    tw(entry, TweenInfo.new(0.18), {BackgroundColor3 = isPinned and C.surfaceHi or C.bg})
    local pinIcon = entry:FindFirstChild("PinIcon")
    local unpinBtn = entry:FindFirstChild("UnpinBtn", true)
    if pinIcon then pinIcon.Visible = isPinned end
    if unpinBtn then unpinBtn.Visible = isPinned end
end
local function updateLogVisuals(id, isPinned)
    for _, e in ipairs(UI.Entries) do
        if e:GetAttribute("SigID") == id then
            syncEntryPinState(e, id)
        end
    end
end
UI.UpdateLogVisuals = updateLogVisuals

local addPinnedEntry
local removePinnedEntryByID

local function getDisplayText(id, sigType)
    local text = tost(id)
    if State.showProductNames then
        local pName = getProductName(id, sigType)
        if pName then
            text = tost(id) .. " - " .. tost(pName)
        end
    end
    return text
end
UI.GetDisplayText = getDisplayText

local function addLog(label, id, sigType)
    if State.suppressCounter > 0 then return end
    UI.SetEmpty(false)
    State.eventCount = State.eventCount + 1

    local entry = Instance.new("Frame")
    entry:SetAttribute("SigID", id)
    entry:SetAttribute("SigType", sigType)
    entry:SetAttribute("CustomName", nil)
    entry.Size             = UDim2.new(1, -2, 0, State.isMobile and 56 or 46)
    entry.BackgroundColor3 = State.globalPinned[id] and C.surfaceHi or C.bg
    entry.BorderSizePixel  = 0
    entry.LayoutOrder      = -State.eventCount
    entry.Parent           = UI.LogArea
    corner(entry, 10)
    stroke(entry, C.border, 1)
    entry.BackgroundTransparency = 1
    tw(entry, TweenInfo.new(0.18), {BackgroundTransparency = 0})

    local sigCol = SIG_COLOR[sigType] or C.textMuted

    local dot = Instance.new("Frame")
    dot.Size             = UDim2.new(0, 8, 0, 8)
    dot.Position         = UDim2.new(0, 14, 0.5, -4)
    dot.BackgroundColor3 = sigCol
    dot.BorderSizePixel  = 0
    dot.Parent           = entry
    corner(dot, 999)

    local pinIcon = Instance.new("TextLabel")
    pinIcon.Name             = "PinIcon"
    pinIcon.Size             = UDim2.new(0, 18, 1, 0)
    pinIcon.Position         = UDim2.new(0, 24, 0, 0)
    pinIcon.BackgroundTransparency = 1
    pinIcon.Text             = "\240\159\147\140"
    pinIcon.TextColor3       = C.accent
    pinIcon.TextSize         = 12
    pinIcon.Font             = Enum.Font.GothamBold
    pinIcon.TextXAlignment   = Enum.TextXAlignment.Left
    pinIcon.Visible          = State.globalPinned[id] == true
    pinIcon.Parent           = entry

    local typeLbl = Instance.new("TextLabel")
    typeLbl.Name             = "TypeLbl"
    typeLbl.Size             = UDim2.new(0, 76, 1, 0)
    typeLbl.Position         = UDim2.new(0, 44, 0, 0)
    typeLbl.BackgroundTransparency = 1
    typeLbl.Text             = string.upper(label)
    typeLbl.TextColor3       = sigCol
    typeLbl.TextSize         = 10
    typeLbl.Font             = Enum.Font.GothamBold
    typeLbl.TextXAlignment   = Enum.TextXAlignment.Left
    typeLbl.Visible          = true
    typeLbl.Parent           = entry
    table.insert(UI.Labels.SignalTypes, typeLbl)

    local customName = nil
    local lastIdClick = 0
    local idLbl = Instance.new("TextButton")
    idLbl.Name             = "IdLbl"
    idLbl.Size             = UDim2.new(0, 200, 1, 0)
    idLbl.Position         = UDim2.new(0, 124, 0, 0)
    idLbl.BackgroundTransparency = 1
    idLbl.Text             = getDisplayText(id, sigType)
    idLbl.TextColor3       = C.text
    idLbl.TextSize         = 14
    idLbl.Font             = Enum.Font.GothamBold
    idLbl.TextXAlignment   = Enum.TextXAlignment.Left
    idLbl.TextTruncate     = Enum.TextTruncate.AtEnd
    idLbl.AutoButtonColor  = false
    idLbl.BorderSizePixel  = 0
    idLbl.Parent           = entry

    idLbl.MouseButton1Click:Connect(function()
        local now = tick()
        if now - lastIdClick < 0.4 then
            lastIdClick = 0
            local box = Instance.new("TextBox")
            box.Size             = idLbl.Size
            box.Position         = idLbl.Position
            box.BackgroundColor3 = C.surfaceHi
            box.Text             = customName or tost(id)
            box.TextColor3       = C.accent
            box.TextSize         = 13
            box.Font             = Enum.Font.GothamBold
            box.TextXAlignment   = Enum.TextXAlignment.Left
            box.ClearTextOnFocus = false
            box.BorderSizePixel  = 0
            box.ZIndex           = 10
            box.Parent           = entry
            corner(box, 4)
            stroke(box, C.accentDim, 1)
            box:CaptureFocus()
            box.FocusLost:Connect(function(entered)
                local newName = box.Text ~= "" and box.Text or tost(id)
                customName   = newName ~= tost(id) and newName or nil
                entry:SetAttribute("CustomName", customName)
                idLbl.Text   = customName or getDisplayText(id, sigType)
                idLbl.TextColor3 = customName and C.accent or C.text
                box:Destroy()
            end)
        else
            lastIdClick = now
        end
    end)
    idLbl.MouseEnter:Connect(function()
        tw(idLbl, TIF, {TextColor3 = C.accent})
    end)
    idLbl.MouseLeave:Connect(function()
        tw(idLbl, TIF, {TextColor3 = customName and C.accent or C.text})
    end)

    entry.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton3 or inp.UserInputType == Enum.UserInputType.MouseButton2 then
            if State.globalPinned[id] then
                State.globalPinned[id] = nil
                UI.UpdateLogVisuals(id, false)
                removePinnedEntryByID(id)
                UI.ShowToast("Unpinned from Pinned tab", C.textMuted)
            else
                State.globalPinned[id] = true
                UI.UpdateLogVisuals(id, true)
                UI.AddPinnedEntry(id, sigType, customName)
                UI.ShowToast("Pinned to Pinned tab", C.accent)
            end
        end
    end)

    local timeLbl = Instance.new("TextLabel")
    timeLbl.Size             = UDim2.new(0, 70, 1, 0)
    timeLbl.Position         = UDim2.new(0, 318, 0, 0)
    timeLbl.BackgroundTransparency = 1
    timeLbl.Text             = os.date("%H:%M:%S")
    timeLbl.TextColor3       = C.textDim
    timeLbl.TextSize         = FS
    timeLbl.Font             = Enum.Font.Gotham
    timeLbl.Parent           = entry

    local bf = Instance.new("Frame")
    bf.Size                 = UDim2.new(0, 258, 1, 0)
    bf.Position             = UDim2.new(1, -262, 0, 0)
    bf.BackgroundTransparency = 1
    bf.Parent               = entry

    local function mkBtn(txt, xOff)
        local b = Instance.new("TextButton")
        b.Size             = UDim2.new(0, 56, 0, BH)
        b.Position         = UDim2.new(0, xOff, 0.5, -BH/2)
        b.BackgroundColor3 = C.surfaceHi
        b.Text             = txt
        b.TextColor3       = C.textMuted
        b.TextSize         = FS
        b.Font             = Enum.Font.GothamBold
        b.BorderSizePixel  = 0
        b.AutoButtonColor  = false
        b.Parent           = bf
        corner(b, 7)
        stroke(b, C.border, 1)
        return b
    end

    local autoBtn = mkBtn("Auto", 0)
    local copyBtn = mkBtn("Copy", 62)
    local runBtn  = mkBtn("\226\150\182", 138)
    runBtn.Size     = UDim2.new(0, 42, 0, BH)
    runBtn.TextSize = 18
    local unpinBtn = mkBtn("Unpin", 186)
    unpinBtn.Name = "UnpinBtn"
    unpinBtn.Size = UDim2.new(0, 68, 0, BH)
    unpinBtn.Visible = State.globalPinned[id] == true

    unpinBtn.MouseButton1Click:Connect(function()
        if State.globalPinned[id] then
            State.globalPinned[id] = nil
            UI.UpdateLogVisuals(id, false)
            removePinnedEntryByID(id)
            UI.ShowToast("Unpinned from Pinned tab", C.textMuted)
        end
    end)

    copyBtn.MouseButton1Click:Connect(function()
        pcall(setclipboard, tost(id))
        copyBtn.Text = "Copied!"; copyBtn.TextColor3 = C.accent
        task.wait(1.5)
        if copyBtn.Parent then copyBtn.Text = "Copy"; copyBtn.TextColor3 = C.textMuted end
    end)

    local autoActive = false; local autoLoop = nil
    local function startAuto()
        if autoActive then return end
        autoActive = true
        autoBtn.Text = "Stop"; autoBtn.TextColor3 = C.red; autoBtn.BackgroundColor3 = Color3.fromRGB(40,15,15)
        autoLoop = task.spawn(function()
            while autoActive and autoBtn.Parent do
                UI.FireFakeSignal(sigType, id)
                task.wait(State.autoSpeed > 0 and 1/State.autoSpeed or 0.01)
            end
        end)
        UI.ActiveAutoButtons[autoBtn] = {active = true, loop = autoLoop}
    end
    local function stopAuto()
        autoActive = false
        if autoLoop then task.cancel(autoLoop) end
        UI.ActiveAutoButtons[autoBtn] = nil
        if autoBtn.Parent then autoBtn.Text = "Auto"; autoBtn.TextColor3 = C.textMuted; autoBtn.BackgroundColor3 = C.surfaceHi end
    end
    autoBtn.MouseButton1Click:Connect(function() if autoActive then stopAuto() else startAuto() end end)

    local holdStart = nil; local holdConn = nil; local spamLoop = nil; local isSpamming = false
    local function startSpam()
        if isSpamming then return end
        isSpamming = true
        runBtn.Text = "Spamming"; runBtn.TextSize = FS; runBtn.TextColor3 = C.amber
        spamLoop = task.spawn(function()
            while isSpamming and runBtn.Parent do UI.FireFakeSignal(sigType, id); task.wait(0.08) end
        end)
        UI.ActiveSpamButtons[runBtn] = {active = true, loop = spamLoop}
    end
    local function stopSpam()
        isSpamming = false
        if spamLoop then task.cancel(spamLoop) end
        UI.ActiveSpamButtons[runBtn] = nil
        if runBtn.Parent then runBtn.Text = "\226\150\182"; runBtn.TextSize = 18; runBtn.TextColor3 = C.textMuted; runBtn.BackgroundColor3 = C.surfaceHi end
    end
    runBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            holdStart = tick()
            holdConn  = task.spawn(function()
                while holdStart and (tick() - holdStart) < 3 do task.wait(0.1) end
                if holdStart and not isSpamming then startSpam() end
            end)
        end
    end)
    runBtn.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            local dur = holdStart and (tick() - holdStart) or 0
            holdStart = nil
            if holdConn then task.cancel(holdConn) end
            if isSpamming then
                stopSpam()
            elseif dur < 3 then
                UI.FireFakeSignal(sigType, id)
                runBtn.Text = "Sent!"; runBtn.TextSize = FS
                task.wait(1.5)
                if runBtn.Parent then runBtn.Text = "\226\150\182"; runBtn.TextSize = 18 end
            end
        end
    end)
    runBtn.MouseEnter:Connect(function()
        if not isSpamming and runBtn.Text == "\226\150\182" then tw(runBtn, TIF, {TextColor3 = C.accent, BackgroundColor3 = C.surface}) end
    end)
    runBtn.MouseLeave:Connect(function()
        if not isSpamming and runBtn.Text == "\226\150\182" then tw(runBtn, TIF, {TextColor3 = C.textMuted, BackgroundColor3 = C.surfaceHi}) end
    end)

    entry.AncestryChanged:Connect(function()
        if not entry.Parent then
            if autoActive then stopAuto() end
            if isSpamming then stopSpam() end
            for i = #UI.Labels.SignalTypes, 1, -1 do
                if UI.Labels.SignalTypes[i] == typeLbl then
                    table.remove(UI.Labels.SignalTypes, i)
                    break
                end
            end
            for i, e in ipairs(UI.Entries) do if e == entry then table.remove(UI.Entries, i); break end end
        end
    end)
    syncEntryPinState(entry, id)

    UI.CountLabel.Text = State.eventCount .. (State.eventCount == 1 and " event captured" or " events captured")
    table.insert(UI.Entries, entry)
    task.defer(function() UI.LogArea.CanvasPosition = Vector2.new(0, UI.LogArea.AbsoluteCanvasSize.Y) end)
    State.latestEvent = {sigType = sigType, id = id}
    UI.ShowToast(string.upper(sigType) .. "  " .. tost(id), C.text)

    if State.autoRunEnabled then
        UI.FireFakeSignal(sigType, id)
    end
end
UI.SetEmpty = setEmpty
UI.LogArea = logArea
UI.AddLog = addLog

clearBtn.MouseButton1Click:Connect(function()
    UI.StopAllAutoAndSpam()
    for _, e in ipairs(UI.Entries) do e:Destroy() end
    UI.Entries = {}; State.eventCount = 0; UI.CountLabel.Text = "0 events captured"; UI.SetEmpty(true)
end)

-- PINNED TAB
local pinnedPage = addTab("Pinned", "rbxassetid://7733920644", 2)
local pinnedScroll = Instance.new("ScrollingFrame")
pinnedScroll.Size                = UDim2.new(1, 0, 1, -(TH + 60))
pinnedScroll.Position            = UDim2.new(0, 0, 0, TH)
pinnedScroll.BackgroundTransparency = 1
pinnedScroll.BorderSizePixel     = 0
pinnedScroll.ScrollBarThickness  = 3
pinnedScroll.ScrollBarImageColor3 = C.accentDim
pinnedScroll.CanvasSize          = UDim2.new(0,0,0,0)
pinnedScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
pinnedScroll.Parent              = pinnedPage
UI.PinnedScroll = pinnedScroll

local pinnedLayout = Instance.new("UIListLayout", pinnedScroll)
pinnedLayout.SortOrder = Enum.SortOrder.LayoutOrder
pinnedLayout.Padding   = UDim.new(0, 6)

local pinnedPad = Instance.new("UIPadding", pinnedScroll)
pinnedPad.PaddingTop    = UDim.new(0, 6)
pinnedPad.PaddingBottom = UDim.new(0, 6)
pinnedPad.PaddingLeft   = UDim.new(0, 4)
pinnedPad.PaddingRight  = UDim.new(0, 4)

pinnedLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    pinnedScroll.CanvasSize = UDim2.new(0, 0, 0, pinnedLayout.AbsoluteContentSize.Y + 12)
end)

local pinnedEntries = {}
local pinnedDataList = {}
local pinnedCount = 0

local function refreshAllNameLabels()
    for _, e in ipairs(UI.Entries) do
        local id = e:GetAttribute("SigID")
        local sigType = e:GetAttribute("SigType")
        if id and sigType then
            local idLbl = e:FindFirstChild("IdLbl")
            local customName = e:GetAttribute("CustomName")
            if idLbl then
                idLbl.Text = customName or UI.GetDisplayText(id, sigType)
                idLbl.TextColor3 = customName and C.accent or C.text
            end
        end
    end
    for _, pe in ipairs(UI.PinnedEntries) do
        local id = pe:GetAttribute("SigID")
        local sigType = pe:GetAttribute("SigType")
        local pname = pe:FindFirstChild("PName")
        local displayName = pe:GetAttribute("DisplayName")
        if id and sigType and pname then
            pname.Text = displayName or UI.GetDisplayText(id, sigType)
            pname.TextColor3 = displayName and C.accent or C.text
        end
    end
end
UI.RefreshAllNameLabels = refreshAllNameLabels

do
    local function savePinnedToFile()
        pcall(function()
            if writefile then
                writefile(PINNED_FILE, HS:JSONEncode(State.pinnedDataList or {}))
            end
        end)
    end
    UI.SavePinnedToFile = savePinnedToFile

    local function loadPinnedFromFile()
        local ok, data = pcall(function()
            if isfile and isfile(PINNED_FILE) then
                return HS:JSONDecode(readfile(PINNED_FILE))
            end
            return {}
        end)
        State.pinnedDataList = ok and type(data) == "table" and data or {}
        return State.pinnedDataList
    end
    UI.LoadPinnedFromFile = loadPinnedFromFile
end

local function setPinnedEmpty(show)
    if not UI.PinnedScroll then return end
    local e = UI.PinnedScroll:FindFirstChild("PinnedEmpty")
    if show and not e then
        local el = Instance.new("TextLabel")
        el.Name               = "PinnedEmpty"
        el.Size               = UDim2.new(1, 0, 0, 200)
        el.BackgroundTransparency = 1
        el.Text               = "No pinned entries yet.\nRight-click or Middle-click an event in Listener to pin it."
        el.TextColor3         = C.textDim
        el.TextSize           = FM
        el.Font               = Enum.Font.Gotham
        el.TextWrapped        = true
        el.LayoutOrder        = 99999
        el.TextXAlignment     = Enum.TextXAlignment.Center
        el.Parent             = UI.PinnedScroll
    elseif not show and e then
        e:Destroy()
    end
end
UI.SetPinnedEmpty = setPinnedEmpty

removePinnedEntryByID = function(id)
    for i = #State.pinnedDataList, 1, -1 do
        if State.pinnedDataList[i].id == id then
            table.remove(State.pinnedDataList, i)
        end
    end
    for i = #UI.PinnedEntries, 1, -1 do
        local pe = UI.PinnedEntries[i]
        if pe:GetAttribute("SigID") == id then
            pe:Destroy()
            table.remove(UI.PinnedEntries, i)
        end
    end
    if UI.SavePinnedToFile then UI.SavePinnedToFile() end
    if #UI.PinnedEntries == 0 then UI.SetPinnedEmpty(true) end
end
UI.RemovePinnedEntryByID = removePinnedEntryByID

addPinnedEntry = function(id, sigType, displayName, skipSave)
    State.globalPinned[id] = true
    UI.SetPinnedEmpty(false)
    State.pinCount = State.pinCount + 1
    local sigCol = SIG_COLOR[sigType] or C.textMuted

    local dataEntry = {id = id, sigType = sigType, displayName = displayName}
    table.insert(State.pinnedDataList, dataEntry)
    if not skipSave and UI.SavePinnedToFile then UI.SavePinnedToFile() end

    local pe = Instance.new("Frame")
    pe:SetAttribute("SigID", id)
    pe:SetAttribute("SigType", sigType)
    pe:SetAttribute("DisplayName", displayName)
    pe.Size             = UDim2.new(1, -2, 0, State.isMobile and 56 or 46)
    pe.BackgroundColor3 = C.bg
    pe.BorderSizePixel  = 0
    pe.LayoutOrder      = State.pinCount
    pe.Parent           = UI.PinnedScroll
    corner(pe, 10)
    stroke(pe, C.border, 1)

    local pdot = Instance.new("Frame")
    pdot.Size             = UDim2.new(0, 8, 0, 8)
    pdot.Position         = UDim2.new(0, 14, 0.5, -4)
    pdot.BackgroundColor3 = sigCol
    pdot.BorderSizePixel  = 0
    pdot.Parent           = pe
    local ptype = Instance.new("TextLabel")
    ptype.Size               = UDim2.new(0, 70, 1, 0)
    ptype.Position           = UDim2.new(0, 28, 0, 0)
    ptype.BackgroundTransparency = 1
    ptype.Text               = string.upper(sigType)
    ptype.TextColor3         = sigCol
    ptype.TextSize           = 10
    ptype.Font               = Enum.Font.GothamBold
    ptype.TextXAlignment     = Enum.TextXAlignment.Left
    ptype.Visible            = true
    ptype.Parent             = pe
    table.insert(UI.Labels.PinnedTypes, ptype)

    local pname = Instance.new("TextButton")
    pname.Name               = "PName"
    pname.Size               = UDim2.new(0, 200, 1, 0)
    pname.Position           = UDim2.new(0, 100, 0, 0)
    pname.BackgroundTransparency = 1
    pname.Text               = displayName or UI.GetDisplayText(id, sigType)
    pname.TextColor3         = displayName and C.accent or C.text
    pname.TextSize           = FM
    pname.Font               = Enum.Font.GothamBold
    pname.TextXAlignment     = Enum.TextXAlignment.Left
    pname.TextTruncate       = Enum.TextTruncate.AtEnd
    pname.BorderSizePixel    = 0
    pname.AutoButtonColor    = false
    pname.Parent             = pe

    local lastPinClick = 0
    pname.MouseButton1Click:Connect(function()
        local now = tick()
        if now - lastPinClick < 0.4 then
            lastPinClick = 0
            local box = Instance.new("TextBox")
            box.Size             = pname.Size
            box.Position         = pname.Position
            box.BackgroundColor3 = C.surfaceHi
            box.Text             = pname.Text
            box.TextColor3       = C.accent
            box.TextSize         = FM
            box.Font             = Enum.Font.GothamBold
            box.TextXAlignment   = Enum.TextXAlignment.Left
            box.ClearTextOnFocus = false
            box.BorderSizePixel  = 0
            box.ZIndex           = 10
            box.Parent           = pe
            corner(box, 4)
            stroke(box, C.accentDim, 1)
            box:CaptureFocus()
            box.FocusLost:Connect(function()
                local newName = box.Text ~= "" and box.Text or tost(id)
                pname.Text = newName
                pname.TextColor3 = (newName ~= tost(id)) and C.accent or C.text
                dataEntry.displayName = (newName ~= tost(id)) and newName or nil
                if UI.SavePinnedToFile then UI.SavePinnedToFile() end
                box:Destroy()
            end)
        else
            lastPinClick = now
        end
    end)

    local pbf = Instance.new("Frame")
    pbf.Size                 = UDim2.new(0, 240, 1, 0)
    pbf.Position             = UDim2.new(1, -244, 0, 0)
    pbf.BackgroundTransparency = 1
    pbf.Parent               = pe

    local function mkPBtn(txt, xOff)
        local b = Instance.new("TextButton")
        b.Size             = UDim2.new(0, 52, 0, BH)
        b.Position         = UDim2.new(0, xOff, 0.5, -BH/2)
        b.BackgroundColor3 = C.surfaceHi
        b.Text             = txt
        b.TextColor3       = C.textMuted
        b.TextSize         = FS
        b.Font             = Enum.Font.GothamBold
        b.BorderSizePixel  = 0
        b.AutoButtonColor  = false
        b.Parent           = pbf
        corner(b, 7)
        stroke(b, C.border, 1)
        return b
    end

    local pautoBtn = mkPBtn("Auto", 0)
    local pcopyBtn = mkPBtn("Copy", 58)
    local prunBtn  = mkPBtn("\226\150\182", 126)
    prunBtn.Size   = UDim2.new(0, 42, 0, BH)
    prunBtn.TextSize = 18
    local pRemoveBtn = Instance.new("ImageButton")
    pRemoveBtn.Size = UDim2.new(0, 28, 0, 28)
    pRemoveBtn.Position = UDim2.new(1, -30, 0.5, -14)
    pRemoveBtn.BackgroundColor3 = C.surfaceHi
    pRemoveBtn.BorderSizePixel = 0
    pRemoveBtn.Image = "rbxassetid://5612339854"
    pRemoveBtn.ImageColor3 = C.red
    pRemoveBtn.Parent = pe
    corner(pRemoveBtn, 6)
    stroke(pRemoveBtn, C.border, 1)

    local pAutoActive = false; local pAutoLoop = nil
    local function startPAuto()
        if pAutoActive then return end
        pAutoActive = true
        pautoBtn.Text = "Stop"; pautoBtn.TextColor3 = C.red; pautoBtn.BackgroundColor3 = Color3.fromRGB(40,15,15)
        pAutoLoop = task.spawn(function()
            while pAutoActive and pautoBtn.Parent do
                UI.FireFakeSignal(sigType, id)
                task.wait(State.autoSpeed > 0 and 1/State.autoSpeed or 0.01)
            end
        end)
        UI.ActiveAutoButtons[pautoBtn] = {active = true, loop = pAutoLoop}
    end
    local function stopPAuto()
        pAutoActive = false
        if pAutoLoop then task.cancel(pAutoLoop) end
        UI.ActiveAutoButtons[pautoBtn] = nil
        if pautoBtn.Parent then pautoBtn.Text = "Auto"; pautoBtn.TextColor3 = C.textMuted; pautoBtn.BackgroundColor3 = C.surfaceHi end
    end
    pautoBtn.MouseButton1Click:Connect(function() if pAutoActive then stopPAuto() else startPAuto() end end)

    pcopyBtn.MouseButton1Click:Connect(function()
        pcall(setclipboard, tost(id))
        pcopyBtn.Text = "Done!"; pcopyBtn.TextColor3 = C.accent
        local RS3 = game:GetService("RunService")
        local ct=0; local cc
        cc = RS3.Heartbeat:Connect(function(dt)
            ct=ct+dt; if ct>=1.2 then cc:Disconnect()
                if pcopyBtn.Parent then pcopyBtn.Text="Copy"; pcopyBtn.TextColor3=C.textMuted end
            end
        end)
    end)

    prunBtn.MouseButton1Click:Connect(function()
        UI.FireFakeSignal(sigType, id)
        prunBtn.Text = "Sent!"; prunBtn.TextSize = FS
        local RS3 = game:GetService("RunService")
        local rt=0; local rc
        rc = RS3.Heartbeat:Connect(function(dt)
            rt=rt+dt; if rt>=1.2 then rc:Disconnect()
                if prunBtn.Parent then prunBtn.Text="\226\150\182"; prunBtn.TextSize = 18 end
            end
        end)
    end)

    pRemoveBtn.MouseButton1Click:Connect(function()
        if State.globalPinned[id] then
            State.globalPinned[id] = nil
            UI.UpdateLogVisuals(id, false)
            removePinnedEntryByID(id)
            UI.ShowToast("Unpinned from Pinned tab", C.textMuted)
        end
    end)
    
    pe.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton3 or inp.UserInputType == Enum.UserInputType.MouseButton2 then
            if State.globalPinned[id] then
                State.globalPinned[id] = nil
                UI.UpdateLogVisuals(id, false)
                removePinnedEntryByID(id)
                UI.ShowToast("Unpinned from Pinned tab", C.textMuted)
            end
        end
    end)

    pe.AncestryChanged:Connect(function()
        if not pe.Parent then
            if pAutoActive then stopPAuto() end
            for i = #UI.Labels.PinnedTypes, 1, -1 do
                if UI.Labels.PinnedTypes[i] == ptype then
                    table.remove(UI.Labels.PinnedTypes, i)
                    break
                end
            end
            for i, e in ipairs(UI.PinnedEntries) do if e == pe then table.remove(UI.PinnedEntries, i); break end end
        end
    end)

    table.insert(UI.PinnedEntries, pe)
    return pe
end
UI.AddPinnedEntry = addPinnedEntry

-- SETTINGS TAB
local settingsPage = addTab("Settings", "rbxassetid://6031280882", 3)

local sw = Instance.new("ScrollingFrame")
sw.Size                = UDim2.new(1, 0, 0, 200)
sw.Position            = UDim2.new(0, 0, 0, TH)
sw.BackgroundTransparency = 1
sw.BorderSizePixel     = 0
sw.ScrollBarThickness  = 3
sw.ScrollBarImageColor3 = C.accentDim
sw.CanvasSize          = UDim2.new(0,0,0,0)
sw.AutomaticCanvasSize = Enum.AutomaticSize.Y
sw.Parent              = settingsPage

local sl = Instance.new("UIListLayout", sw)
sl.SortOrder = Enum.SortOrder.LayoutOrder
sl.Padding   = UDim.new(0, 10)

local sp = Instance.new("UIPadding", sw)
sp.PaddingTop   = UDim.new(0, 8)
sp.PaddingLeft  = UDim.new(0, 4)
sp.PaddingRight = UDim.new(0, 4)

do
    local sw = Instance.new("ScrollingFrame")
    sw.Name             = "SettingsContent"
    sw.Size             = UDim2.new(1, -20, 1, -TH - 10)
    sw.Position         = UDim2.new(0, 10, 0, TH + 5)
    sw.BackgroundTransparency = 1
    sw.BorderSizePixel  = 0
    sw.ScrollBarThickness = 2
    sw.ScrollBarImageColor3 = C.accentDim
    sw.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sw.CanvasSize       = UDim2.new(0, 0, 0, 0)
    sw.Parent           = settingsPage

    local list = Instance.new("UIListLayout", sw)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 8)

    local function mkRow(title, desc, order)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -4, 0, 54)
        row.BackgroundColor3 = C.bg
        row.BorderSizePixel = 0
        row.LayoutOrder = order
        row.Parent = sw
        corner(row, 8)
        stroke(row, C.border, 1)

        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(0.65, 0, 0, 20)
        t.Position = UDim2.new(0, 12, 0, 8)
        t.BackgroundTransparency = 1
        t.Text = title
        t.TextColor3 = C.text
        t.TextSize = FM
        t.Font = Enum.Font.GothamBold
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.Parent = row

        local d = Instance.new("TextLabel")
        d.Size = UDim2.new(0.65, 0, 0, 14)
        d.Position = UDim2.new(0, 12, 0, 28)
        d.BackgroundTransparency = 1
        d.Text = desc
        d.TextColor3 = C.textDim
        d.TextSize = 9
        d.Font = Enum.Font.Gotham
        d.TextXAlignment = Enum.TextXAlignment.Left
        d.Parent = row

        return row
    end

    -- Speed
    local speedRow = mkRow("Signals per second", "1 slowest | 10000 fastest | Default: 100", 1)
    local speedBox = Instance.new("TextBox")
    speedBox.Size = UDim2.new(0, 100, 0, 30)
    speedBox.Position = UDim2.new(1, -116, 0.5, -15)
    speedBox.BackgroundColor3 = C.bg
    speedBox.Text = tost(State.autoSpeed)
    speedBox.TextColor3 = C.text
    speedBox.TextSize = FM
    speedBox.Font = Enum.Font.RobotoMono
    speedBox.Parent = speedRow
    corner(speedBox, 6)
    stroke(speedBox, C.border, 1)
    speedBox.FocusLost:Connect(function()
        local n = tonumber(speedBox.Text)
        if n and n >= 1 and n <= 10000 then
            State.autoSpeed = math.floor(n)
            speedBox.Text = tost(State.autoSpeed)
            tw(speedBox, TIF, {BackgroundColor3 = C.greenDim})
            task.wait(0.6)
            tw(speedBox, TIF, {BackgroundColor3 = C.bg})
        else
            tw(speedBox, TIF, {BackgroundColor3 = C.redDim})
            task.wait(0.6)
            tw(speedBox, TIF, {BackgroundColor3 = C.bg})
            speedBox.Text = tost(State.autoSpeed)
        end
    end)

end

-- UI CONTROL
do
    local function createReopenButton()
        if UI.ReopenBtn and UI.ReopenBtn.Parent then return UI.ReopenBtn end
        if not UI.ReopenGui then
            UI.ReopenGui = Instance.new("ScreenGui")
            UI.ReopenGui.Name = "ThunderstormReopenGui"
            UI.ReopenGui.ResetOnSpawn = false
            UI.ReopenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
            UI.ReopenGui.IgnoreGuiInset = true
            UI.ReopenGui.Parent = playerGui
        end
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 80, 0, 80)
        btn.Position = UDim2.new(0.5, 0, 0.5, 0)
        btn.AnchorPoint = Vector2.new(0.5, 0.5)
        btn.BackgroundColor3 = C.surface
        btn.Text = "S"
        btn.TextColor3 = C.accent
        btn.TextSize = 26
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.ZIndex = 1000
        btn.Parent = UI.ReopenGui
        btn.Visible = false
        corner(btn, 18)
        stroke(btn, C.accentDim, 1.5)
        makeDraggable(btn)
        btn.MouseButton1Click:Connect(function()
            UI.ShowGui()
        end)
        UI.ReopenBtn = btn
        return btn
    end

    local function showGui()
        sg.Enabled = true; State.uiVisible = true
        if UI.Main then UI.Main.Visible = true end
        if UI.ReopenBtn then UI.ReopenBtn.Visible = false end
    end
    local function hideGui()
        sg.Enabled = false; State.uiVisible = false
        if UI.Main then UI.Main.Visible = false end
        local btn = createReopenButton()
        btn.Visible = true
    end
    UI.HideGui = hideGui
    UI.ShowGui = showGui

    if UI.CloseBtn then
        UI.CloseBtn.MouseButton1Click:Connect(hideGui)
    end

    createReopenButton()

    if State.uiVisible then
        sg.Enabled = false
    end

    table.insert(UI.Conns, UIS.InputBegan:Connect(function(inp, gpe)
        if inp.UserInputType ~= Enum.UserInputType.Keyboard or gpe then return end
        -- UI open/close is controlled by the draggable button only.
    end))

    local function hook(signal, label, sigType)
        pcall(function()
            table.insert(UI.Conns, signal:Connect(function(_, id, _)
                if State.suppressCounter == 0 then UI.AddLog(label, id, sigType) end
            end))
        end)
    end
    hook(MPS.PromptProductPurchaseFinished, "Product", "Product")
    hook(MPS.PromptGamePassPurchaseFinished, "Gamepass", "Gamepass")
    hook(MPS.PromptBulkPurchaseFinished, "Bulk", "Bulk")
    hook(MPS.PromptPurchaseFinished, "Purchase", "Purchase")

    UI.SwitchTab("Listener")
    if UI.SetEmpty then UI.SetEmpty(true) end
    if State.fxEnabled then setFxEnabled(true, false) end
    if UI.LoadPinnedFromFile then
        local saved = UI.LoadPinnedFromFile()
        for _, d in ipairs(saved) do
            if d.id and d.sigType then UI.AddPinnedEntry(d.id, d.sigType, d.displayName, true) end
        end
    end

    print("[Thunderstorm] v0.5 loaded")
end
