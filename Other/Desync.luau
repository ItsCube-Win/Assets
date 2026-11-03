
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local LP         = Players.LocalPlayer

-- -------- Load Obsidian --------
local Library      = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

-- ============================================================
-- STATE
-- ============================================================
local state = {
    enabled     = false,
    origin      = nil,
    frozen      = nil,
    current     = nil,
    root        = nil,
    custom      = false,
    offset      = Vector3.new(0, 0, 0),
    marker      = nil,
    pickMode    = false,
    unlockMouse = false,
    prevUnlock  = false,
}

-- ============================================================
-- HELPERS
-- ============================================================
local function recomputeFrozen()
    if not state.origin then return end
    local off = state.custom and state.offset or Vector3.new(0, 0, 0)
    state.frozen = state.origin * CFrame.new(off)
end

local function updateMarker()
    if not state.enabled or not state.frozen then
        if state.marker then
            state.marker:Destroy()
            state.marker = nil
        end
        return
    end
    if not state.marker then
        local m = Instance.new("Part")
        m.Name = "DesyncMarker"
        m.Shape = Enum.PartType.Ball
        m.Size = Vector3.new(1.5, 1.5, 1.5)
        m.Material = Enum.Material.Neon
        m.Color = Color3.fromRGB(0, 200, 255)
        m.Transparency = 0.5
        m.CanCollide = false
        m.CanQuery   = false
        m.CanTouch   = false
        m.Anchored   = true
        m.Parent     = workspace

        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 170, 0, 30)
        bb.AlwaysOnTop = true
        bb.Parent = m

        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1
        tl.Text = "SERVER SEES YOU HERE"
        tl.TextColor3 = Color3.fromRGB(0, 200, 255)
        tl.TextStrokeTransparency = 0.3
        tl.Font = Enum.Font.GothamBold
        tl.TextSize = 13
        tl.Parent = bb

        state.marker = m
    end
    state.marker.CFrame = state.frozen
end

local function updateStatus()
    if not Options.StatusLabel then return end
    if state.enabled and state.frozen then
        Options.StatusLabel:SetText(string.format(
            "Frozen: %.0f, %.0f, %.0f",
            state.frozen.X, state.frozen.Y, state.frozen.Z))
    elseif state.origin then
        Options.StatusLabel:SetText(string.format(
            "Saved: %.0f, %.0f, %.0f",
            state.origin.X, state.origin.Y, state.origin.Z))
    else
        Options.StatusLabel:SetText("No anchor saved")
    end
end

-- -------- Unlock Mouse --------
local function setUnlockMouse(enabled)
    state.unlockMouse = enabled
    if enabled then
        pcall(function()
            UIS.MouseBehavior    = Enum.MouseBehavior.Default
            UIS.MouseIconEnabled = true
        end)
    end
end

pcall(function()
    local oldNewIndex
    oldNewIndex = hookmetamethod(game, "__newindex", newcclosure(function(self, key, value)
        if self == UIS and key == "MouseBehavior"
           and state.unlockMouse and not checkcaller()
        then
            return oldNewIndex(self, key, Enum.MouseBehavior.Default)
        end
        return oldNewIndex(self, key, value)
    end))
end)

RunService.RenderStepped:Connect(function()
    if not state.unlockMouse then return end
    pcall(function()
        if UIS.MouseBehavior ~= Enum.MouseBehavior.Default then
            UIS.MouseBehavior = Enum.MouseBehavior.Default
        end
        if not UIS.MouseIconEnabled then
            UIS.MouseIconEnabled = true
        end
    end)
end)

-- ============================================================
-- WINDOW
-- ============================================================
local Window = Library:CreateWindow({
    Title        = "Freeze Desync",
    Footer       = "v7 — Obsidian",
    Icon         = 95816097006870,
    NotifySide   = "Right",
    ShowCustomCursor = true,
})

local MainTab     = Window:AddTab("Main", "user")
local SettingsTab = Window:AddTab("UI Settings", "settings")

local ActionsGroup = MainTab:AddGroupbox({
    Side = "Left",
    Name = "Actions",
    IconName = "crosshair",
})

local ConfigGroup = MainTab:AddGroupbox({
    Side = "Right",
    Name = "Config",
    IconName = "settings",
})

-- ============================================================
-- CORE LOGIC
-- ============================================================
local function toggleDesync(enable)
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if enable and not root then
        Library:Notify({
            Title = "Desync",
            Description = "No character — try after respawn.",
            Time = 3,
        })
        task.defer(function()
            if Toggles.DesyncToggle then
                Toggles.DesyncToggle:SetValue(false)
            end
        end)
        return
    end

    if enable then
        if not state.origin then
            state.origin = root.CFrame
        end
        state.current = root.CFrame
        state.root    = root
        state.enabled = true
        recomputeFrozen()
        updateMarker()
    else
        if state.root and state.root.Parent and state.current then
            state.root.CFrame = state.current
            state.origin      = state.current
        end
        if state.marker then
            state.marker:Destroy()
            state.marker = nil
        end
        state.enabled  = false
        state.frozen   = nil
        state.current  = nil
        state.root     = nil
        state.pickMode = false
    end
    updateStatus()
end

-- UPD: берём настоящую текущую позицию (state.current при активном desync
-- или root.CFrame в остальных случаях), делаем её новым anchor'ом.
local function updatePositionHere()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local pos = (state.enabled and state.current) or root.CFrame
    state.origin = pos

    if state.enabled then
        recomputeFrozen()
        updateMarker()
    end
    updateStatus()

    Library:Notify({
        Title = "Position updated",
        Description = string.format("%.0f, %.0f, %.0f",
            pos.X, pos.Y, pos.Z),
        Time = 2,
    })
end

local function setPickMode(on)
    if on and not state.enabled then
        toggleDesync(true)
        if Toggles.DesyncToggle then
            Toggles.DesyncToggle:SetValue(true)
        end
    end
    if not state.enabled then return end

    state.pickMode = on
    if on then
        state.prevUnlock = state.unlockMouse
        setUnlockMouse(true)
        if Toggles.UnlockMouseToggle then
            Toggles.UnlockMouseToggle:SetValue(true)
        end
        if Options.StatusLabel then
            Options.StatusLabel:SetText("Click anywhere in world...")
        end
    else
        setUnlockMouse(state.prevUnlock or false)
        if Toggles.UnlockMouseToggle then
            Toggles.UnlockMouseToggle:SetValue(state.prevUnlock or false)
        end
        updateStatus()
    end
end

local function handlePickClick()
    local cam = workspace.CurrentCamera
    local mp  = UIS:GetMouseLocation()
    local ray = cam:ScreenPointToRay(mp.X, mp.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LP.Character, state.marker }
    local hit = workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
    if hit then
        state.origin = CFrame.new(hit.Position + Vector3.new(0, 3, 0))
        recomputeFrozen()
        updateMarker()
        updateStatus()
        setPickMode(false)
    else
        if Options.StatusLabel then
            Options.StatusLabel:SetText("No surface hit — try again")
        end
    end
end

-- ============================================================
-- UI — ACTIONS
-- ============================================================
local DesyncToggle = ActionsGroup:AddToggle("DesyncToggle", {
    Text    = "Enable Desync",
    Default = false,
    Tooltip = "Freezes your server position; you walk locally",
    Callback = function(v) toggleDesync(v) end,
})
DesyncToggle:AddKeyPicker("KeyDesync", {
    Default = "C",
    SyncToggleState = true,
    Mode    = "Toggle",
    Text    = "Toggle Desync",
})

ActionsGroup:AddToggle("UnlockMouseToggle", {
    Text    = "Unlock Mouse",
    Default = false,
    Tooltip = "Forces mouse to stay unlocked even if game locks it",
    Callback = function(v) setUnlockMouse(v) end,
})

ActionsGroup:AddButton({
    Text    = "Pick Position",
    Func    = function() setPickMode(not state.pickMode) end,
    Tooltip = "Click a spot in world to become server-visible there",
})

ActionsGroup:AddButton({
    Text    = "Update Position Here",
    Func    = updatePositionHere,
    Tooltip = "Sets server-visible position to where you stand right now",
})

ActionsGroup:AddDivider()

ActionsGroup:AddLabel("StatusLabel", {
    Text = "No anchor saved",
    DoesWrap = true,
})

-- ============================================================
-- UI — CONFIG
-- ============================================================
ConfigGroup:AddToggle("CustomToggle", {
    Text    = "Custom Offset",
    Default = false,
    Tooltip = "Add extra offset on top of anchor position",
    Callback = function(v)
        state.custom = v
        recomputeFrozen()
        updateMarker()
        updateStatus()
    end,
})

local function onOffsetInput()
    state.offset = Vector3.new(
        tonumber(Options.OffsetX.Value) or 0,
        tonumber(Options.OffsetY.Value) or 0,
        tonumber(Options.OffsetZ.Value) or 0
    )
    recomputeFrozen()
    updateMarker()
    updateStatus()
end

ConfigGroup:AddInput("OffsetX", {
    Text = "X Offset", Default = "0", Placeholder = "0",
    Finished = true, Numeric = false,
    Callback = onOffsetInput,
})
ConfigGroup:AddInput("OffsetY", {
    Text = "Y Offset", Default = "0", Placeholder = "0",
    Finished = true, Numeric = false,
    Callback = onOffsetInput,
})
ConfigGroup:AddInput("OffsetZ", {
    Text = "Z Offset", Default = "0", Placeholder = "0",
    Finished = true, Numeric = false,
    Callback = onOffsetInput,
})

ConfigGroup:AddDivider()
ConfigGroup:AddLabel("Keybinds")

ConfigGroup:AddLabel("Pick Position"):AddKeyPicker("KeyPick", {
    Default = "V",
    Mode    = "Press",
    Text    = "Pick Position",
    NoUI    = false,
    Callback = function()
        if state.enabled then
            setPickMode(not state.pickMode)
        end
    end,
})

ConfigGroup:AddLabel("Update Position"):AddKeyPicker("KeyUpdatePos", {
    Default = "U",
    Mode    = "Press",
    Text    = "Update Position Here",
    NoUI    = false,
    Callback = function() updatePositionHere() end,
})

-- ============================================================
-- MAIN LOOP
-- ============================================================
RunService:BindToRenderStep("DesyncLocalRestore", Enum.RenderPriority.First.Value, function()
    if state.enabled and state.root and state.current and state.root.Parent then
        state.root.CFrame = state.current
    end
end)

RunService.Heartbeat:Connect(function()
    if not state.enabled or not state.root or not state.root.Parent then return end
    state.current = state.root.CFrame
    if state.frozen then
        state.root.CFrame = state.frozen
    end
end)

-- ============================================================
-- PICK CLICK HANDLER
-- ============================================================
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if state.pickMode
       and input.UserInputType == Enum.UserInputType.MouseButton1
       and state.enabled
    then
        handlePickClick()
    end
end)

-- ============================================================
-- RESPAWN
-- ============================================================
LP.CharacterAdded:Connect(function()
    if state.enabled then
        toggleDesync(false)
        if Toggles.DesyncToggle then
            Toggles.DesyncToggle:SetValue(false)
        end
    end
    if state.marker then
        state.marker:Destroy()
        state.marker = nil
    end
    state.frozen  = nil
    state.current = nil
    state.root    = nil
    state.pickMode = false
    updateStatus()
end)

-- ============================================================
-- UI SETTINGS — Menu Keybind + Keybind Menu + Unload
-- ============================================================
local MenuGroup = SettingsTab:AddGroupbox({
    Side = "Left",
    Name = "Menu",
    IconName = "wrench",
})

-- Открыть/закрыть окно со списком биндов
MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text    = "Open Keybind Menu",
    Tooltip = "Shows the list of all keybinds",
    Callback = function(value)
        Library.KeybindFrame.Visible = value
    end,
})

MenuGroup:AddLabel("Menu bind")
    :AddKeyPicker("MenuKeybind", {
        Default = "RightShift",
        NoUI    = true,
        Text    = "Menu keybind",
    })

MenuGroup:AddDivider()

MenuGroup:AddButton({
    Text = "Unload Script",
    Func = function() Library:Unload() end,
    Tooltip = "Полностью выгружает меню и скрипт",
})

-- Подключаем MenuKeybind к самому меню Obsidian
Library.ToggleKeybind = Options.MenuKeybind

-- ============================================================
-- ADDONS
-- ============================================================
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({
    "KeyDesync", "KeyPick", "KeyUpdatePos", "MenuKeybind",
})

ThemeManager:SetFolder("FreezeDesync")
SaveManager:SetFolder("FreezeDesync/configs")

SaveManager:BuildConfigSection(SettingsTab)
ThemeManager:ApplyToTab(SettingsTab)

updateStatus()
Library:Notify({
    Title = "Freeze Desync",
    Description = "Loaded. C=desync, V=pick, U=update pos.",
    Time = 4,
})
