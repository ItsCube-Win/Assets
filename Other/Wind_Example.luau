    -- Secure WindUI load
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

-- Theme
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

-- Main Window
local Window = WindUI:CreateWindow({
    Title = "InDex",
    Icon = "door-open",
    Author = "by cube.win ft. ezbypasso",
    Folder = "InDex",
    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    ToggleKey = Enum.KeyCode.LeftShift,
    Transparent = true,
    Theme = "Dark",
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

Window:EditOpenButton({ Enabled = false })
Window:Open()

-- ===== Speed system =====
local speedEnabled = false
local targetSpeed = 16
local originalWalkSpeed = 16

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function getHumanoid()
    local char = player.Character
    return char and char:FindFirstChild("Humanoid")
end

local function updateOriginalSpeed()
    local hum = getHumanoid()
    if hum then
        originalWalkSpeed = hum.WalkSpeed
    end
end

local function applySpeed()
    local hum = getHumanoid()
    if not hum then return end
    if speedEnabled then
        if hum.WalkSpeed ~= targetSpeed then
            hum.WalkSpeed = targetSpeed
        end
    else
        if hum.WalkSpeed ~= originalWalkSpeed then
            hum.WalkSpeed = originalWalkSpeed
        end
    end
end

local function enforceSpeed()
    while true do
        RunService.Heartbeat:Wait()
        applySpeed()
    end
end

local function onCharacterAdded(char)
    task.wait(0.1)
    updateOriginalSpeed()
    applySpeed()
    local hum = char:WaitForChild("Humanoid")
    hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if not speedEnabled and hum.WalkSpeed ~= originalWalkSpeed then
            hum.WalkSpeed = originalWalkSpeed
        elseif speedEnabled and hum.WalkSpeed ~= targetSpeed then
            hum.WalkSpeed = targetSpeed
        end
    end)
end

-- ===== Infinite Jump =====
local infJumpEnabled = false
local currentMethod = "Classic [ Detected in most games ]"
local platformLiftSpeed = 0.03

local spacePressed = false
local platformPart = nil
local platformConnection = nil

local function classicJumpHandler()
    if not infJumpEnabled or currentMethod ~= "Classic [ Detected in most games ]" then return end
    local isSpaceDown = UserInputService:IsKeyDown(Enum.KeyCode.Space)
    if isSpaceDown and not spacePressed then
        local hum = getHumanoid()
        if hum and hum.Health > 0 then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
    spacePressed = isSpaceDown
end

local function createPlatform()
    if platformPart then platformPart:Destroy() end
    platformPart = Instance.new("Part")
    platformPart.Name = "BypassPlatform"
    platformPart.Size = Vector3.new(30, 1, 30)
    platformPart.Anchored = true
    platformPart.Locked = true
    platformPart.BrickColor = BrickColor.new("Bright blue")
    platformPart.Transparency = 0.3
    platformPart.Material = Enum.Material.Neon
    platformPart.Parent = workspace
    return platformPart
end

local function updatePlatformPosition()
    if not platformPart then return end
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        local targetPos = Vector3.new(hrp.Position.X, hrp.Position.Y - 4, hrp.Position.Z)
        platformPart.Position = targetPos
    end
end

local function liftPlatform()
    if not platformPart then return end
    platformPart.Position = platformPart.Position + Vector3.new(0, platformLiftSpeed, 0)
end

local function platformHeartbeat()
    updatePlatformPosition()
    liftPlatform()
end

local function startPlatform()
    if platformConnection then platformConnection:Disconnect() end
    platformPart = createPlatform()
    updatePlatformPosition()
    platformConnection = RunService.Heartbeat:Connect(platformHeartbeat)
end

local function stopPlatform()
    if platformConnection then
        platformConnection:Disconnect()
        platformConnection = nil
    end
    if platformPart then
        platformPart:Destroy()
        platformPart = nil
    end
end

local function stopCurrentMethod()
    if currentMethod == "Platform [ Undetected ]" then
        stopPlatform()
    end
end

local function startCurrentMethod()
    if not infJumpEnabled then return end
    if currentMethod == "Platform [ Undetected ]" then
        startPlatform()
    end
end

local function setMethod(method)
    local wasEnabled = infJumpEnabled
    if wasEnabled then
        stopCurrentMethod()
    end
    currentMethod = method
    if wasEnabled then
        startCurrentMethod()
    end
end

local function classicJumpLoop()
    while true do
        RunService.Heartbeat:Wait()
        classicJumpHandler()
    end
end

-- ===== Visual features =====
local noFogEnabled = false
local thirdPersonEnabled = false
local unlockMouseEnabled = false
local fullBrightEnabled = false
local cursorCheckConnection = nil

-- Light Ball variables
local lightBallEnabled = false
local lightBallBrightness = 5
local lightBallPart = nil
local lightBallLight = nil
local lightBallWeld = nil

-- No Fog
local function applyNoFog(state)
    if state then
        Lighting.FogEnd = 0
        Lighting.FogStart = 0
    else
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
    end
end

local function toggleNoFog(state)
    noFogEnabled = state
    applyNoFog(state)
end

Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
    if noFogEnabled then
        Lighting.FogEnd = 0
    end
end)
Lighting:GetPropertyChangedSignal("FogStart"):Connect(function()
    if noFogEnabled then
        Lighting.FogStart = 0
    end
end)

-- Third Person
local function toggleThirdPerson(state)
    thirdPersonEnabled = state
    player.CameraMode = state and Enum.CameraMode.Classic or Enum.CameraMode.LockFirstPerson
end

-- Unlock Mouse
local function toggleUnlockMouse(state)
    unlockMouseEnabled = state
    if state then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
        pcall(function()
            StarterGui:SetCore("MouseIconEnabled", true)
            local mouse = player:GetMouse()
            if mouse and mouse.Icon then
                mouse.Icon = "rbxasset://textures/Cursors/Arrow.png"
            end
        end)
        if not cursorCheckConnection then
            cursorCheckConnection = RunService.RenderStepped:Connect(function()
                if unlockMouseEnabled then
                    if UserInputService.MouseIconEnabled == false then
                        UserInputService.MouseIconEnabled = true
                    end
                    if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
                        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                    end
                    pcall(function()
                        StarterGui:SetCore("MouseIconEnabled", true)
                        local mouse = player:GetMouse()
                        if mouse and mouse.Icon and mouse.Icon == "" then
                            mouse.Icon = "rbxasset://textures/Cursors/Arrow.png"
                        end
                    end)
                else
                    if cursorCheckConnection then
                        cursorCheckConnection:Disconnect()
                        cursorCheckConnection = nil
                    end
                end
            end)
        end
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
        pcall(function()
            StarterGui:SetCore("MouseIconEnabled", false)
        end)
        if cursorCheckConnection then
            cursorCheckConnection:Disconnect()
            cursorCheckConnection = nil
        end
    end
end

-- FullBright
local originalBrightness = Lighting.Brightness
local originalAmbient = Lighting.Ambient
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalFogEnd = Lighting.FogEnd
local originalFogStart = Lighting.FogStart

local function applyFullBright(state)
    if state then
        if not fullBrightEnabled then
            originalBrightness = Lighting.Brightness
            originalAmbient = Lighting.Ambient
            originalOutdoorAmbient = Lighting.OutdoorAmbient
            originalFogEnd = Lighting.FogEnd
            originalFogStart = Lighting.FogStart
        end
        Lighting.Brightness = 1
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
        Lighting.FogEnd = 0
        Lighting.FogStart = 0
    else
        Lighting.Brightness = originalBrightness
        Lighting.Ambient = originalAmbient
        Lighting.OutdoorAmbient = originalOutdoorAmbient
        Lighting.FogEnd = originalFogEnd
        Lighting.FogStart = originalFogStart
    end
end

local function toggleFullBright(state)
    fullBrightEnabled = state
    applyFullBright(state)
end

Lighting:GetPropertyChangedSignal("Brightness"):Connect(function()
    if fullBrightEnabled then
        Lighting.Brightness = 1
    end
end)
Lighting:GetPropertyChangedSignal("Ambient"):Connect(function()
    if fullBrightEnabled then
        Lighting.Ambient = Color3.new(1,1,1)
    end
end)
Lighting:GetPropertyChangedSignal("OutdoorAmbient"):Connect(function()
    if fullBrightEnabled then
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
    end
end)
Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
    if fullBrightEnabled then
        Lighting.FogEnd = 0
    end
end)
Lighting:GetPropertyChangedSignal("FogStart"):Connect(function()
    if fullBrightEnabled then
        Lighting.FogStart = 0
    end
end)

-- Time Set
local function setTime(timeOption)
    if timeOption == "Day" then
        Lighting.ClockTime = 14
    elseif timeOption == "Night" then
        Lighting.ClockTime = 0
    end
end

-- ===== Light Ball =====
local function createLightBall()
    if lightBallPart then
        lightBallPart:Destroy()
        lightBallPart = nil
        lightBallLight = nil
        lightBallWeld = nil
    end
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root then return end

    lightBallPart = Instance.new("Part")
    lightBallPart.Name = "LightBall"
    lightBallPart.Size = Vector3.new(1,1,1)
    lightBallPart.Anchored = false
    lightBallPart.CanCollide = false
    lightBallPart.Transparency = 1
    lightBallPart.Material = Enum.Material.Neon
    lightBallPart.BrickColor = BrickColor.new("Bright white")
    lightBallPart.Parent = char

    lightBallLight = Instance.new("PointLight")
    lightBallLight.Parent = lightBallPart
    lightBallLight.Brightness = lightBallBrightness
    lightBallLight.Range = 100
    lightBallLight.Color = Color3.new(1,1,1)
    lightBallLight.Shadows = false

    lightBallWeld = Instance.new("Weld")
    lightBallWeld.Part0 = root
    lightBallWeld.Part1 = lightBallPart
    lightBallWeld.C0 = CFrame.new(0, 0, 0)
    lightBallWeld.Parent = lightBallPart
end

local function destroyLightBall()
    if lightBallPart then
        lightBallPart:Destroy()
        lightBallPart = nil
        lightBallLight = nil
        lightBallWeld = nil
    end
end

local function toggleLightBall(state)
    lightBallEnabled = state
    if state then
        createLightBall()
    else
        destroyLightBall()
    end
end

local function updateLightBallBrightness(value)
    lightBallBrightness = value
    if lightBallLight then
        lightBallLight.Brightness = value
    end
end

-- Восстановление при респавне
player.CharacterAdded:Connect(function(char)
    if lightBallEnabled then
        task.wait(0.1)
        createLightBall()
    end
end)

-- ===== Aspect Ratio =====
local aspectRatioEnabled = false
local aspectRatioValue = 0.5
local aspectConnection = nil

local function applyAspectRatio(state)
    if not camera then return end
    if state then
        local cf = camera.CFrame
        local scaleMatrix = CFrame.new(0, 0, 0, 1, 0, 0, 0, aspectRatioValue, 0, 0, 0, 1)
        camera.CFrame = cf * scaleMatrix
    else
        local cf = camera.CFrame
        local invScale = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1/aspectRatioValue, 0, 0, 0, 1)
        camera.CFrame = cf * invScale
    end
end

local function toggleAspectRatio(state)
    aspectRatioEnabled = state
    if state then
        if not aspectConnection then
            aspectConnection = RunService.RenderStepped:Connect(function()
                if aspectRatioEnabled then
                    applyAspectRatio(true)
                end
            end)
        end
        applyAspectRatio(true)
    else
        if aspectConnection then
            aspectConnection:Disconnect()
            aspectConnection = nil
        end
        applyAspectRatio(false)
    end
end

-- ===== Fun: Spin =====
local spinEnabled = false
local spinSpeed = 90
local spinConnection = nil

local function toggleSpin(state)
    spinEnabled = state
    if state then
        if not spinConnection then
            spinConnection = RunService.Heartbeat:Connect(function(deltaTime)
                if spinEnabled then
                    local char = player.Character
                    if char then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinSpeed * deltaTime), 0)
                        end
                    end
                else
                    if spinConnection then
                        spinConnection:Disconnect()
                        spinConnection = nil
                    end
                end
            end)
        end
    else
        if spinConnection then
            spinConnection:Disconnect()
            spinConnection = nil
        end
    end
end

-- ===== Fun: BHop =====
local bhopEnabled = false
local bhopJumpBoost = 5
local bhopSpeedCap = 100
local bhopDecelRate = 50
local bhopLowFriction = 0.01
local bhopActive = false
local bhopConnections = {}
local bhopState = {
    currSpeed = 16,
    lastHzSpeed = 0,
    lastDir = Vector3.new(),
    sliding = false,
    origProps = nil,
    slipProps = nil
}

local function getBaseSpeed() return 16 end

local function resetBhopState()
    bhopState.currSpeed = getBaseSpeed()
    bhopState.lastHzSpeed = 0
    bhopState.lastDir = Vector3.new()
    bhopState.sliding = false
end

local function cleanupBhop()
    if bhopActive then
        for _, c in pairs(bhopConnections) do
            if c then pcall(c.Disconnect, c) end
        end
        bhopConnections = {}
        local char = player.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hum then
                hum.WalkSpeed = getBaseSpeed()
            end
            if hrp and bhopState.origProps then
                hrp.CustomPhysicalProperties = bhopState.origProps
            end
        end
        resetBhopState()
        bhopActive = false
    end
end

local function setupBhop(character)
    if not bhopEnabled or not character then return end
    local hum = character:FindFirstChild("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    bhopState.origProps = hrp.CustomPhysicalProperties or PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1)
    bhopState.slipProps = PhysicalProperties.new(bhopState.origProps.Density, bhopLowFriction, bhopState.origProps.Elasticity, 100, bhopState.origProps.ElasticityWeight)
    resetBhopState()
    hum.WalkSpeed = getBaseSpeed()
    bhopState.currSpeed = getBaseSpeed()

    local jumpingConn = hum.Jumping:Connect(function()
        if not bhopEnabled then return end
        bhopState.currSpeed = math.min(bhopState.currSpeed + bhopJumpBoost, bhopSpeedCap)
        hum.WalkSpeed = bhopState.currSpeed
        bhopState.sliding = false
        if hrp then
            hrp.CustomPhysicalProperties = bhopState.origProps
        end
    end)
    bhopConnections.Jumping = jumpingConn

    local diedConn = hum.Died:Connect(function()
        cleanupBhop()
    end)
    bhopConnections.Died = diedConn

    bhopActive = true
end

RunService.Heartbeat:Connect(function(delta)
    if not bhopEnabled or not bhopActive then return end
    local char = player.Character
    if not char then
        if bhopActive then cleanupBhop() end
        return
    end
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then
        if bhopActive then cleanupBhop() end
        return
    end

    if not bhopState.origProps then
        bhopState.origProps = hrp.CustomPhysicalProperties or PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1)
        bhopState.slipProps = PhysicalProperties.new(bhopState.origProps.Density, bhopLowFriction, bhopState.origProps.Elasticity, 100, bhopState.origProps.ElasticityWeight)
    end

    if hum.MoveDirection.Magnitude > 0 then
        bhopState.lastDir = hum.MoveDirection.Unit
        bhopState.sliding = false
        hrp.CustomPhysicalProperties = bhopState.origProps
    end

    local hzNow = (hrp.Velocity * Vector3.new(1,0,1)).Magnitude
    if hzNow < bhopState.lastHzSpeed * 0.5 and bhopState.lastHzSpeed > 16 * 1.5 then
        bhopState.currSpeed = 16
        hum.WalkSpeed = 16
        bhopState.sliding = false
        hrp.CustomPhysicalProperties = bhopState.origProps
    end
    bhopState.lastHzSpeed = hzNow

    if hum.MoveDirection.Magnitude == 0 and bhopState.currSpeed > 16 then
        if not bhopState.sliding then
            bhopState.sliding = true
            hrp.CustomPhysicalProperties = bhopState.slipProps
            hrp.Velocity = Vector3.new(bhopState.lastDir.X * bhopState.currSpeed, hrp.Velocity.Y, bhopState.lastDir.Z * bhopState.currSpeed)
        end
        bhopState.currSpeed = math.max(16, bhopState.currSpeed - bhopDecelRate * delta)
        hum.WalkSpeed = bhopState.currSpeed
        local velHz = hrp.Velocity * Vector3.new(1,0,1)
        if velHz.Magnitude > 16 then
            hrp.Velocity = Vector3.new(bhopState.lastDir.X * bhopState.currSpeed, hrp.Velocity.Y, bhopState.lastDir.Z * bhopState.currSpeed)
        else
            bhopState.sliding = false
            hrp.CustomPhysicalProperties = bhopState.origProps
            hum.WalkSpeed = 16
            bhopState.currSpeed = 16
        end
    elseif hum.MoveDirection.Magnitude == 0 then
        bhopState.currSpeed = 16
        hum.WalkSpeed = 16
        bhopState.sliding = false
        hrp.CustomPhysicalProperties = bhopState.origProps
    else
        hum.WalkSpeed = bhopState.currSpeed
    end
end)

player.CharacterAdded:Connect(function(newChar)
    if bhopEnabled then
        cleanupBhop()
        task.wait(0.1)
        setupBhop(newChar)
    end
end)

local function toggleBhop(state)
    bhopEnabled = state
    if state then
        local char = player.Character
        if char then
            cleanupBhop()
            task.wait(0.1)
            setupBhop(char)
        end
    else
        cleanupBhop()
    end
end

-- ===== UI =====
local HumanoidTab = Window:Tab({
    Title = "Humanoid",
    Icon = "user",
    Locked = false,
})

HumanoidTab:Toggle({
    Title = "Speed toggle",
    Value = speedEnabled,
    Callback = function(state)
        speedEnabled = state
        if state then updateOriginalSpeed() end
        applySpeed()
    end,
})

HumanoidTab:Slider({
    Title = "Speed changer",
    Step = 1,
    Value = {
        Min = 16,
        Max = 999,
        Default = targetSpeed,
    },
    Callback = function(value)
        targetSpeed = value
        if speedEnabled then applySpeed() end
    end,
})

HumanoidTab:Toggle({
    Title = "Infinite Jump",
    Value = infJumpEnabled,
    Callback = function(state)
        infJumpEnabled = state
        if state then
            startCurrentMethod()
        else
            stopCurrentMethod()
        end
    end,
})

HumanoidTab:Dropdown({
    Title = "Inf Jump Method",
    Values = { "Classic [ Detected in most games ]", "Platform [ Undetected ]" },
    Value = currentMethod,
    Callback = function(option)
        setMethod(option)
    end,
})

HumanoidTab:Slider({
    Title = "Platform Lift Speed",
    Step = 0.01,
    Value = {
        Min = 0.01,
        Max = 0.45,
        Default = platformLiftSpeed,
    },
    Callback = function(value)
        platformLiftSpeed = value
    end,
})

-- Visual Tab
local VisualTab = Window:Tab({
    Title = "Visual",
    Icon = "eye",
    Locked = false,
})

local noFogToggle = VisualTab:Toggle({
    Title = "No Fog",
    Value = noFogEnabled,
    Callback = function(state)
        toggleNoFog(state)
    end,
})

VisualTab:Keybind({
    Title = "No Fog Keybind",
    Value = "F",
    Callback = function(key)
        noFogEnabled = not noFogEnabled
        toggleNoFog(noFogEnabled)
        noFogToggle:SetValue(noFogEnabled)
    end,
})

local thirdPersonToggle = VisualTab:Toggle({
    Title = "Third Person",
    Value = thirdPersonEnabled,
    Callback = function(state)
        toggleThirdPerson(state)
    end,
})

VisualTab:Keybind({
    Title = "Third Person Keybind",
    Value = "T",
    Callback = function(key)
        thirdPersonEnabled = not thirdPersonEnabled
        toggleThirdPerson(thirdPersonEnabled)
        thirdPersonToggle:SetValue(thirdPersonEnabled)
    end,
})

local unlockMouseToggle = VisualTab:Toggle({
    Title = "Unlock Mouse",
    Value = unlockMouseEnabled,
    Callback = function(state)
        toggleUnlockMouse(state)
    end,
})

VisualTab:Keybind({
    Title = "Unlock Mouse Keybind",
    Value = "M",
    Callback = function(key)
        unlockMouseEnabled = not unlockMouseEnabled
        toggleUnlockMouse(unlockMouseEnabled)
        unlockMouseToggle:SetValue(unlockMouseEnabled)
    end,
})

local fullBrightToggle = VisualTab:Toggle({
    Title = "FullBright",
    Value = fullBrightEnabled,
    Callback = function(state)
        toggleFullBright(state)
    end,
})

VisualTab:Keybind({
    Title = "FullBright Keybind",
    Value = "B",
    Callback = function(key)
        fullBrightEnabled = not fullBrightEnabled
        toggleFullBright(fullBrightEnabled)
        fullBrightToggle:SetValue(fullBrightEnabled)
    end,
})

VisualTab:Divider()

local timeMethod = "Day"
VisualTab:Dropdown({
    Title = "Time Option",
    Values = { "Day", "Night" },
    Value = timeMethod,
    Callback = function(option)
        timeMethod = option
    end,
})

VisualTab:Button({
    Title = "Time Set",
    Icon = "clock",
    Callback = function()
        setTime(timeMethod)
    end,
})

-- Aspect Ratio
VisualTab:Divider()

local aspectToggle = VisualTab:Toggle({
    Title = "Aspect Ratio",
    Value = aspectRatioEnabled,
    Callback = function(state)
        toggleAspectRatio(state)
    end,
})

VisualTab:Slider({
    Title = "Aspect Ratio Value",
    Step = 0.01,
    Value = {
        Min = 0.1,
        Max = 2.0,
        Default = aspectRatioValue,
    },
    Callback = function(value)
        aspectRatioValue = value
        if aspectRatioEnabled then
            applyAspectRatio(true)
        end
    end,
})

-- Light Ball
VisualTab:Divider()

local lightBallToggle = VisualTab:Toggle({
    Title = "Light Ball",
    Value = lightBallEnabled,
    Callback = function(state)
        toggleLightBall(state)
    end,
})

VisualTab:Slider({
    Title = "Light Brightness",
    Step = 0.5,
    Value = {
        Min = 0,
        Max = 20,
        Default = lightBallBrightness,
    },
    Callback = function(value)
        updateLightBallBrightness(value)
    end,
})

-- ===== Fun Tab =====
local FunTab = Window:Tab({
    Title = "Fun",
    Icon = "party-popper",
    Locked = false,
})

local spinToggle = FunTab:Toggle({
    Title = "Spin",
    Value = spinEnabled,
    Callback = function(state)
        toggleSpin(state)
    end,
})

FunTab:Slider({
    Title = "Spin Speed",
    Step = 1,
    Value = {
        Min = 0,
        Max = 5000,
        Default = spinSpeed,
    },
    Callback = function(value)
        spinSpeed = value
    end,
})

FunTab:Divider()

local bhopToggle = FunTab:Toggle({
    Title = "BHop (Speed Bunny Hop)",
    Value = bhopEnabled,
    Callback = function(state)
        toggleBhop(state)
    end,
})

FunTab:Slider({
    Title = "Jump Boost",
    Step = 1,
    Value = {
        Min = 1,
        Max = 50,
        Default = bhopJumpBoost,
    },
    Callback = function(value)
        bhopJumpBoost = value
    end,
})

FunTab:Slider({
    Title = "Max Speed Cap",
    Step = 1,
    Value = {
        Min = 20,
        Max = 300,
        Default = bhopSpeedCap,
    },
    Callback = function(value)
        bhopSpeedCap = value
    end,
})

FunTab:Slider({
    Title = "Deceleration",
    Step = 1,
    Value = {
        Min = 10,
        Max = 200,
        Default = bhopDecelRate,
    },
    Callback = function(value)
        bhopDecelRate = value
    end,
})

-- ===== Settings Tab =====
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
    Locked = false,
})

SettingsTab:Paragraph({
    Title = "Your ID",
    Desc = "@" .. game:GetService("Players").LocalPlayer.Name,
    Image = "user",
})

SettingsTab:Button({
    Title = "Destroy UI",
    Icon = "trash",
    Callback = function()
        Window:Destroy()
    end,
})

-- ===== Start background threads =====
coroutine.wrap(enforceSpeed)()
coroutine.wrap(classicJumpLoop)()

if player.Character then
    onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)
