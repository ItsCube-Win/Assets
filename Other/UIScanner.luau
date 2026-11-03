
local function log(...) print("[ImageScanner]", ...) end
local function warnLog(...) warn("[ImageScanner]", ...) end

if getgenv().ImageScannerLoaded then
    local old = getgenv().ImageScannerGui
    if old then pcall(function() old:Destroy() end) end
end
getgenv().ImageScannerLoaded = true

local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContentProvider  = game:GetService("ContentProvider")
local LocalPlayer      = Players.LocalPlayer

if not LocalPlayer then warnLog("LocalPlayer нет"); return end

local function getGuiParent()
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    if CoreGui then
        local ok = pcall(function() local _ = CoreGui:GetChildren() end)
        if ok then return CoreGui end
    end
    return LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
end

local parent = getGuiParent()
if not parent then warnLog("Нет родителя GUI"); return end

-- ==================== ФАЙЛЫ ====================
local CAN_SAVE = (type(writefile) == "function") and (type(makefolder) == "function")
local SAVE_FOLDER = "ImageScanner"
if CAN_SAVE then
    pcall(function()
        if type(isfolder) == "function" then
            if not isfolder(SAVE_FOLDER) then makefolder(SAVE_FOLDER) end
        else pcall(makefolder, SAVE_FOLDER) end
    end)
end

-- ==================== HTTP ====================
local function httpGetBinary(url)
    if type(request) == "function" then
        local ok, r = pcall(request, { Url = url, Method = "GET" })
        if ok and r and r.Body and #r.Body > 0 then return r.Body, r.StatusCode end
    end
    if type(http_request) == "function" then
        local ok, r = pcall(http_request, { Url = url, Method = "GET" })
        if ok and r and r.Body and #r.Body > 0 then return r.Body, r.StatusCode end
    end
    if syn and type(syn.request) == "function" then
        local ok, r = pcall(syn.request, { Url = url, Method = "GET" })
        if ok and r and r.Body and #r.Body > 0 then return r.Body, r.StatusCode end
    end
    local ok, b = pcall(function() return game:HttpGet(url, true) end)
    if ok and b and #b > 0 then return b, 200 end
    return nil, 0
end

local function detectFormat(d)
    if not d or #d < 100 then return nil end
    local s = d:sub(1, 4)
    if s == "\137PNG" then return "png" end
    if d:sub(1,2) == "\255\216" then return "jpg" end
    if s == "RIFF" and d:sub(9,12) == "WEBP" then return "webp" end
    if s == "GIF8" then return "gif" end
    return nil
end

local function getThumbnailUrl(id)
    for _, size in ipairs({ "720x720", "420x420", "250x250", "150x150" }) do
        local url = "https://thumbnails.roblox.com/v1/assets?assetIds="
            .. tostring(id) .. "&size=" .. size .. "&format=Png"
        local body = httpGetBinary(url)
        if body then
            local u = body:match('"imageUrl":"(.-)"')
            local state = body:match('"state":"(.-)"')
            if u and u ~= "" and u ~= "null" then
                return u:gsub("\\/", "/"), state
            end
            if state and state ~= "Completed" then return nil, state end
        end
    end
    return nil, "NoThumbnail"
end

local function probeAsset(id)
    local _, code = httpGetBinary("https://assetdelivery.roblox.com/v1/asset/?id=" .. tostring(id))
    return code or 0
end

local function downloadImage(id)
    local thumbUrl, state = getThumbnailUrl(id)
    if thumbUrl then
        local d = httpGetBinary(thumbUrl)
        local f = detectFormat(d)
        if f then return d, f, "ok" end
    end
    if state == "Blocked" then return nil, nil, "blocked" end
    if state == "Unavailable" then return nil, nil, "unavailable" end
    if state == "Pending" then return nil, nil, "pending" end
    for _, u in ipairs({
        "https://assetdelivery.roblox.com/v1/asset/?id=" .. tostring(id),
        "https://assetdelivery.roblox.com/v1/asset?id=" .. tostring(id),
    }) do
        local b = httpGetBinary(u)
        if b then
            local inner = b:match('<url>.-id=(%d+)</url>')
            if inner then
                local t2 = getThumbnailUrl(inner)
                if t2 then
                    local d2 = httpGetBinary(t2)
                    local f2 = detectFormat(d2)
                    if f2 then return d2, f2, "ok" end
                end
            end
            local f = detectFormat(b)
            if f then return b, f, "ok" end
        end
    end
    return nil, nil, "private"
end

local function saveImage(id)
    if not CAN_SAVE then return false, "writefile недоступен", "error" end
    local data, fmt, reason = downloadImage(id)
    if not data then return false, "недоступно: " .. tostring(reason), reason end
    local path = SAVE_FOLDER .. "/" .. tostring(id) .. "." .. (fmt or "png")
    local ok, err = pcall(writefile, path, data)
    if ok then return true, path, "ok" end
    if syn and syn.crypt and syn.crypt.base64 then
        local ok2 = pcall(function() writefile(path, syn.crypt.base64.encode(data)) end)
        if ok2 then return true, path, "ok" end
    end
    return false, tostring(err), "error"
end

-- ==================== ПАЛИТРА ====================
local C = {
    bg=Color3.fromRGB(20,20,26), bgSec=Color3.fromRGB(28,28,36),
    bgCard=Color3.fromRGB(36,36,46), bgCardH=Color3.fromRGB(46,46,58),
    bgInput=Color3.fromRGB(24,24,32), border=Color3.fromRGB(52,52,66),
    borderL=Color3.fromRGB(70,70,90), accent=Color3.fromRGB(120,100,255),
    success=Color3.fromRGB(80,190,120), warning=Color3.fromRGB(240,180,80),
    danger=Color3.fromRGB(230,90,90), text=Color3.fromRGB(235,235,245),
    textDim=Color3.fromRGB(150,150,170), textMut=Color3.fromRGB(110,110,130),
}

-- ==================== UI ХЕЛПЕРЫ ====================
local function addCorner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = o; return c end
local function addStroke(o, col, t, tr)
    local s = Instance.new("UIStroke"); s.Color = col or C.border; s.Thickness = t or 1
    s.Transparency = tr or 0; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = o; return s
end
local function addPad(o, t, r, b, l)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, t or 0); p.PaddingRight = UDim.new(0, r or t or 0)
    p.PaddingBottom = UDim.new(0, b or t or 0); p.PaddingLeft = UDim.new(0, l or r or t or 0)
    p.Parent = o; return p
end
local function tw(o, p, t)
    TweenService:Create(o, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play()
end

-- ==================== ROOT SCREEN GUI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ImageScannerGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999999
ScreenGui.Parent = parent
getgenv().ImageScannerGui = ScreenGui

-- ==================== ОБЩИЙ ФРЕЙМ ====================
local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

local function addShadow(frame)
    local Shadow = Instance.new("ImageLabel")
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 6)
    Shadow.Size = UDim2.new(1, 40, 1, 40)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://6014261993"
    Shadow.ImageColor3 = Color3.new(0,0,0)
    Shadow.ImageTransparency = 0.55
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    Shadow.ZIndex = -1
    Shadow.Parent = frame
end

-- ==================== ЭКРАН ВЫБОРА РЕЖИМА ====================
local InstallerFrame = Instance.new("Frame")
InstallerFrame.Name = "Installer"
InstallerFrame.Size = UDim2.new(0, 520, 0, 340)
InstallerFrame.Position = UDim2.new(0.5, -260, 0.5, -170)
InstallerFrame.BackgroundColor3 = C.bg
InstallerFrame.BorderSizePixel = 0
InstallerFrame.Active = true
InstallerFrame.Parent = ScreenGui
addCorner(InstallerFrame, 14)
addStroke(InstallerFrame, C.border, 1)
addShadow(InstallerFrame)

-- Title bar установщика
local InstTitleBar = Instance.new("Frame")
InstTitleBar.Size = UDim2.new(1, 0, 0, 52)
InstTitleBar.BackgroundColor3 = C.bgSec
InstTitleBar.BorderSizePixel = 0
InstTitleBar.Parent = InstallerFrame
addCorner(InstTitleBar, 14)
local ibFix = Instance.new("Frame", InstTitleBar)
ibFix.Size = UDim2.new(1, 0, 0, 14); ibFix.Position = UDim2.new(0, 0, 1, -14)
ibFix.BackgroundColor3 = C.bgSec; ibFix.BorderSizePixel = 0

local InstLogo = Instance.new("Frame")
InstLogo.Size = UDim2.new(0, 32, 0, 32)
InstLogo.Position = UDim2.new(0, 16, 0.5, -16)
InstLogo.BackgroundColor3 = C.accent
InstLogo.BorderSizePixel = 0
InstLogo.Parent = InstTitleBar
addCorner(InstLogo, 8)
local instLogoIcon = Instance.new("TextLabel")
instLogoIcon.Size = UDim2.new(1, 0, 1, 0)
instLogoIcon.BackgroundTransparency = 1
instLogoIcon.Text = "🖼"
instLogoIcon.TextSize = 16
instLogoIcon.Font = Enum.Font.GothamBold
instLogoIcon.TextColor3 = Color3.new(1,1,1)
instLogoIcon.Parent = InstLogo

local InstTitle = Instance.new("TextLabel")
InstTitle.Size = UDim2.new(1, -200, 0, 18)
InstTitle.Position = UDim2.new(0, 60, 0, 8)
InstTitle.BackgroundTransparency = 1
InstTitle.Text = "Image Scanner — Установка"
InstTitle.TextColor3 = C.text
InstTitle.Font = Enum.Font.GothamBold
InstTitle.TextSize = 15
InstTitle.TextXAlignment = Enum.TextXAlignment.Left
InstTitle.Parent = InstTitleBar

local InstSubtitle = Instance.new("TextLabel")
InstSubtitle.Size = UDim2.new(1, -200, 0, 16)
InstSubtitle.Position = UDim2.new(0, 60, 0, 28)
InstSubtitle.BackgroundTransparency = 1
InstSubtitle.Text = "Выбери режим работы"
InstSubtitle.TextColor3 = C.textMut
InstSubtitle.Font = Enum.Font.Gotham
InstSubtitle.TextSize = 11
InstSubtitle.TextXAlignment = Enum.TextXAlignment.Left
InstSubtitle.Parent = InstTitleBar

local InstClose = Instance.new("TextButton")
InstClose.Size = UDim2.new(0, 32, 0, 32)
InstClose.Position = UDim2.new(1, -44, 0.5, -16)
InstClose.BackgroundColor3 = C.bgCard
InstClose.Text = "✕"
InstClose.TextColor3 = C.textDim
InstClose.Font = Enum.Font.GothamBold
InstClose.TextSize = 14
InstClose.BorderSizePixel = 0
InstClose.AutoButtonColor = false
InstClose.Parent = InstTitleBar
addCorner(InstClose, 8)
InstClose.MouseEnter:Connect(function() tw(InstClose, {BackgroundColor3 = C.danger, TextColor3 = Color3.new(1,1,1)}, 0.12) end)
InstClose.MouseLeave:Connect(function() tw(InstClose, {BackgroundColor3 = C.bgCard, TextColor3 = C.textDim}, 0.12) end)
InstClose.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

makeDraggable(InstallerFrame, InstTitleBar)

-- Контейнер двух карточек режима
local InstContent = Instance.new("Frame")
InstContent.Size = UDim2.new(1, -32, 1, -84)
InstContent.Position = UDim2.new(0, 16, 0, 68)
InstContent.BackgroundTransparency = 1
InstContent.Parent = InstallerFrame

local InstLayout = Instance.new("UIListLayout")
InstLayout.FillDirection = Enum.FillDirection.Horizontal
InstLayout.Padding = UDim.new(0, 12)
InstLayout.SortOrder = Enum.SortOrder.LayoutOrder
InstLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
InstLayout.VerticalAlignment = Enum.VerticalAlignment.Center
InstLayout.Parent = InstContent

-- Функция построения карточки выбора
local function buildModeCard(title, subtitle, bullets, accentColor, order, onClick)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 220, 1, 0)
    card.BackgroundColor3 = C.bgCard
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.Parent = InstContent
    addCorner(card, 12)
    local cs = addStroke(card, C.border, 1)

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1, 0, 0, 4)
    top.BackgroundColor3 = accentColor
    top.BorderSizePixel = 0
    top.Parent = card
    addCorner(top, 4)

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(1, 0, 0, 48)
    icon.Position = UDim2.new(0, 0, 0, 16)
    icon.BackgroundTransparency = 1
    icon.Text = bullets.icon
    icon.TextSize = 34
    icon.Font = Enum.Font.GothamBold
    icon.TextColor3 = accentColor
    icon.Parent = card

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -20, 0, 22)
    t.Position = UDim2.new(0, 10, 0, 68)
    t.BackgroundTransparency = 1
    t.Text = title
    t.TextColor3 = C.text
    t.Font = Enum.Font.GothamBold
    t.TextSize = 15
    t.Parent = card

    local s = Instance.new("TextLabel")
    s.Size = UDim2.new(1, -20, 0, 16)
    s.Position = UDim2.new(0, 10, 0, 90)
    s.BackgroundTransparency = 1
    s.Text = subtitle
    s.TextColor3 = C.textMut
    s.Font = Enum.Font.Gotham
    s.TextSize = 11
    s.Parent = card

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, -20, 0, 90)
    list.Position = UDim2.new(0, 10, 0, 112)
    list.BackgroundTransparency = 1
    list.Parent = card

    local ll = Instance.new("UIListLayout")
    ll.Padding = UDim.new(0, 4)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Parent = list

    for i, line in ipairs(bullets.lines) do
        local li = Instance.new("TextLabel")
        li.Size = UDim2.new(1, 0, 0, 16)
        li.BackgroundTransparency = 1
        li.Text = "• " .. line
        li.TextColor3 = C.textDim
        li.Font = Enum.Font.Gotham
        li.TextSize = 11
        li.TextXAlignment = Enum.TextXAlignment.Left
        li.LayoutOrder = i
        li.Parent = list
    end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 34)
    btn.Position = UDim2.new(0, 10, 1, -46)
    btn.BackgroundColor3 = accentColor
    btn.Text = "Выбрать"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = card
    addCorner(btn, 8)

    btn.MouseEnter:Connect(function()
        tw(card, {BackgroundColor3 = C.bgCardH}, 0.12)
        tw(cs, {Color = accentColor}, 0.12)
        tw(btn, {BackgroundColor3 = accentColor:Lerp(Color3.new(1,1,1), 0.15)}, 0.12)
    end)
    btn.MouseLeave:Connect(function()
        tw(card, {BackgroundColor3 = C.bgCard}, 0.12)
        tw(cs, {Color = C.border}, 0.12)
        tw(btn, {BackgroundColor3 = accentColor}, 0.12)
    end)
    btn.MouseButton1Click:Connect(function()
        tw(InstallerFrame, {Size = UDim2.new(0, 520, 0, 200)}, 0.15)
        task.wait(0.15)
        onClick()
    end)
    return card
end

buildModeCard(
    "⚡ Быстрый", "Только ImageLabel и ImageButton",
    {
        icon = "⚡",
        lines = {
            "Мгновенный скан",
            "Минимум запросов",
            "Без проверки приватности",
            "Только UI-картинки",
        },
    },
    Color3.fromRGB(80, 180, 120), 1,
    function() installMode("quick") end
)

buildModeCard(
    "🔬 Глубокий", "Все классы + проверка приватности",
    {
        icon = "🔬",
        lines = {
            "Тоглы классов",
            "HTTP-статусы",
            "Пометка 🔒 приватных",
            "Тогл «скрыть недоступные»",
        },
    },
    C.accent, 2,
    function() installMode("deep") end
)

-- ==================== УСТАНОВКА РЕЖИМА ====================
local Installed = false

function installMode(mode)
    if Installed then return end
    Installed = true

    -- Удаляем установщик
    InstallerFrame:Destroy()

    -- Создаём главное окно
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 720, 0, 500)
    Main.Position = UDim2.new(0.5, -360, 0.5, -250)
    Main.BackgroundColor3 = C.bg
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Parent = ScreenGui
    addCorner(Main, 14)
    addStroke(Main, C.border, 1)
    addShadow(Main)

    -- Title bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 52)
    TitleBar.BackgroundColor3 = C.bgSec
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Main
    addCorner(TitleBar, 14)
    local tbFix = Instance.new("Frame", TitleBar)
    tbFix.Size = UDim2.new(1, 0, 0, 14); tbFix.Position = UDim2.new(0, 0, 1, -14)
    tbFix.BackgroundColor3 = C.bgSec; tbFix.BorderSizePixel = 0

    local Logo = Instance.new("Frame")
    Logo.Size = UDim2.new(0, 32, 0, 32)
    Logo.Position = UDim2.new(0, 16, 0.5, -16)
    Logo.BackgroundColor3 = (mode == "quick") and Color3.fromRGB(80, 180, 120) or C.accent
    Logo.BorderSizePixel = 0
    Logo.Parent = TitleBar
    addCorner(Logo, 8)
    local logoIcon = Instance.new("TextLabel")
    logoIcon.Size = UDim2.new(1, 0, 1, 0)
    logoIcon.BackgroundTransparency = 1
    logoIcon.Text = (mode == "quick") and "⚡" or "🔬"
    logoIcon.TextSize = 16
    logoIcon.Font = Enum.Font.GothamBold
    logoIcon.TextColor3 = Color3.new(1,1,1)
    logoIcon.Parent = Logo

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -260, 0, 18)
    Title.Position = UDim2.new(0, 60, 0, 8)
    Title.BackgroundTransparency = 1
    Title.Text = "Image Scanner  ·  " .. ((mode == "quick") and "Быстрый" or "Глубокий")
    Title.TextColor3 = C.text
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 15
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar

    local Subtitle = Instance.new("TextLabel")
    Subtitle.Size = UDim2.new(1, -260, 0, 16)
    Subtitle.Position = UDim2.new(0, 60, 0, 28)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = "Готов"
    Subtitle.TextColor3 = C.textMut
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.TextSize = 11
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left
    Subtitle.Parent = TitleBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 32, 0, 32)
    CloseBtn.Position = UDim2.new(1, -44, 0.5, -16)
    CloseBtn.BackgroundColor3 = C.bgCard
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = C.textDim
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 14
    CloseBtn.BorderSizePixel = 0
    CloseBtn.AutoButtonColor = false
    CloseBtn.Parent = TitleBar
    addCorner(CloseBtn, 8)
    CloseBtn.MouseEnter:Connect(function() tw(CloseBtn, {BackgroundColor3 = C.danger, TextColor3 = Color3.new(1,1,1)}, 0.12) end)
    CloseBtn.MouseLeave:Connect(function() tw(CloseBtn, {BackgroundColor3 = C.bgCard, TextColor3 = C.textDim}, 0.12) end)
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 32, 0, 32)
    MinBtn.Position = UDim2.new(1, -82, 0.5, -16)
    MinBtn.BackgroundColor3 = C.bgCard
    MinBtn.Text = "—"
    MinBtn.TextColor3 = C.textDim
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 14
    MinBtn.BorderSizePixel = 0
    MinBtn.AutoButtonColor = false
    MinBtn.Parent = TitleBar
    addCorner(MinBtn, 8)
    MinBtn.MouseEnter:Connect(function() tw(MinBtn, {BackgroundColor3 = C.bgCardH, TextColor3 = C.text}, 0.12) end)
    MinBtn.MouseLeave:Connect(function() tw(MinBtn, {BackgroundColor3 = C.bgCard, TextColor3 = C.textDim}, 0.12) end)

    makeDraggable(Main, TitleBar)

    -- Toolbar
    local Toolbar = Instance.new("Frame")
    Toolbar.Size = UDim2.new(1, -32, 0, 44)
    Toolbar.Position = UDim2.new(0, 16, 0, 64)
    Toolbar.BackgroundTransparency = 1
    Toolbar.Parent = Main

    local SearchFrame = Instance.new("Frame")
    SearchFrame.Size = UDim2.new(0, 250, 1, 0)
    SearchFrame.BackgroundColor3 = C.bgInput
    SearchFrame.BorderSizePixel = 0
    SearchFrame.Parent = Toolbar
    addCorner(SearchFrame, 8)
    addStroke(SearchFrame, C.border, 1)

    local SearchIcon = Instance.new("TextLabel")
    SearchIcon.Size = UDim2.new(0, 32, 1, 0)
    SearchIcon.Position = UDim2.new(0, 6, 0, 0)
    SearchIcon.BackgroundTransparency = 1
    SearchIcon.Text = "🔍"
    SearchIcon.TextSize = 14
    SearchIcon.TextColor3 = C.textMut
    SearchIcon.Parent = SearchFrame

    local SearchBox = Instance.new("TextBox")
    SearchBox.Size = UDim2.new(1, -48, 1, 0)
    SearchBox.Position = UDim2.new(0, 40, 0, 0)
    SearchBox.BackgroundTransparency = 1
    SearchBox.Text = ""
    SearchBox.PlaceholderText = "Поиск по ID..."
    SearchBox.PlaceholderColor3 = C.textMut
    SearchBox.TextColor3 = C.text
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.TextSize = 13
    SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    SearchBox.ClearTextOnFocus = false
    SearchBox.Parent = SearchFrame

    local function makeBtn(text, color, w, x)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, w, 1, 0)
        b.Position = UDim2.new(0, x, 0, 0)
        b.BackgroundColor3 = color
        b.Text = text
        b.TextColor3 = Color3.new(1,1,1)
        b.Font = Enum.Font.GothamSemibold
        b.TextSize = 12
        b.BorderSizePixel = 0
        b.AutoButtonColor = false
        b.Parent = Toolbar
        addCorner(b, 8)
        b.MouseEnter:Connect(function() tw(b, {BackgroundColor3 = color:Lerp(Color3.new(1,1,1), 0.15)}, 0.12) end)
        b.MouseLeave:Connect(function() tw(b, {BackgroundColor3 = color}, 0.12) end)
        return b
    end

    local CopyBtn    = makeBtn("Копир.",    Color3.fromRGB(90,170,110), 80,  258)
    local ScanBtn    = makeBtn("Скан",      C.accent, 80,  346)
    local SaveAllBtn = makeBtn("Сохранить", Color3.fromRGB(80,140,220), 110, 434)
    local ClearBtn   = makeBtn("Очистить",  Color3.fromRGB(180,80,80), 90,  552)

    -- Toggles row (только для deep mode)
    local ContentTop = 116
    local toggles = {}
    local hidePrivate = false
    local hideChip = nil
    local toggleRow = nil

    if mode == "deep" then
        local ToggleRow = Instance.new("Frame")
        ToggleRow.Size = UDim2.new(1, -32, 0, 32)
        ToggleRow.Position = UDim2.new(0, 16, 0, 116)
        ToggleRow.BackgroundTransparency = 1
        ToggleRow.Parent = Main
        toggleRow = ToggleRow

        local ToggleLayout = Instance.new("UIListLayout")
        ToggleLayout.FillDirection = Enum.FillDirection.Horizontal
        ToggleLayout.Padding = UDim.new(0, 6)
        ToggleLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ToggleLayout.Parent = ToggleRow

        toggles.ImageLabel = true
        toggles.ImageButton = true
        toggles.Decal = false
        toggles.Texture = false
        toggles.Sky = false
        toggles.SurfaceAppearance = false

        local function makeToggle(label, key, order, w)
            local chip = Instance.new("TextButton")
            chip.Size = UDim2.new(0, w or 110, 1, 0)
            chip.BackgroundColor3 = toggles[key] and C.accent or C.bgCard
            chip.Text = (toggles[key] and "✓ " or "  ") .. label
            chip.TextColor3 = toggles[key] and Color3.new(1,1,1) or C.textDim
            chip.Font = Enum.Font.GothamSemibold
            chip.TextSize = 11
            chip.BorderSizePixel = 0
            chip.AutoButtonColor = false
            chip.LayoutOrder = order
            chip.Parent = ToggleRow
            addCorner(chip, 6)
            local cs = addStroke(chip, toggles[key] and C.accent or C.border, 1)

            chip.MouseEnter:Connect(function()
                if not toggles[key] then tw(chip, {BackgroundColor3 = C.bgCardH, TextColor3 = C.text}, 0.12) end
            end)
            chip.MouseLeave:Connect(function()
                if not toggles[key] then tw(chip, {BackgroundColor3 = C.bgCard, TextColor3 = C.textDim}, 0.12) end
            end)
            chip.MouseButton1Click:Connect(function()
                toggles[key] = not toggles[key]
                if toggles[key] then
                    chip.Text = "✓ " .. label
                    tw(chip, {BackgroundColor3 = C.accent, TextColor3 = Color3.new(1,1,1)}, 0.12)
                    tw(cs, {Color = C.accent}, 0.12)
                else
                    chip.Text = "  " .. label
                    tw(chip, {BackgroundColor3 = C.bgCard, TextColor3 = C.textDim}, 0.12)
                    tw(cs, {Color = C.border}, 0.12)
                end
            end)
        end

        makeToggle("ImageLabel", "ImageLabel", 1)
        makeToggle("ImageButton", "ImageButton", 2)
        makeToggle("Decal", "Decal", 3)
        makeToggle("Texture", "Texture", 4)
        makeToggle("Sky", "Sky", 5)
        makeToggle("SurfaceApp.", "SurfaceAppearance", 6)

        hideChip = Instance.new("TextButton")
        hideChip.Size = UDim2.new(0, 150, 1, 0)
        hideChip.BackgroundColor3 = C.bgCard
        hideChip.Text = "  Скрыть приватные"
        hideChip.TextColor3 = C.textDim
        hideChip.Font = Enum.Font.GothamSemibold
        hideChip.TextSize = 11
        hideChip.BorderSizePixel = 0
        hideChip.AutoButtonColor = false
        hideChip.LayoutOrder = 7
        hideChip.Parent = ToggleRow
        addCorner(hideChip, 6)
        addStroke(hideChip, C.border, 1)

        ContentTop = 160
    end

    -- Content
    local ContentBg = Instance.new("Frame")
    ContentBg.Size = UDim2.new(1, -32, 1, -(ContentTop + 56))
    ContentBg.Position = UDim2.new(0, 16, 0, ContentTop)
    ContentBg.BackgroundColor3 = C.bgSec
    ContentBg.BorderSizePixel = 0
    ContentBg.Parent = Main
    addCorner(ContentBg, 10)
    addStroke(ContentBg, C.border, 1)

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, -8, 1, -8)
    Scroll.Position = UDim2.new(0, 4, 0, 4)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.ScrollBarThickness = 6
    Scroll.ScrollBarImageColor3 = C.borderL
    Scroll.ScrollBarImageTransparency = 0.3
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    Scroll.ScrollingEnabled = true
    Scroll.Active = true
    Scroll.ClipsDescendants = true
    Scroll.ElasticBehavior = Enum.ElasticBehavior.Never
    Scroll.Parent = ContentBg
    addCorner(Scroll, 8)
    addPad(Scroll, 10)

    local Grid = Instance.new("UIGridLayout")
    Grid.CellSize = UDim2.new(0, 128, 0, 150)
    Grid.CellPadding = UDim2.new(0, 10, 0, 10)
    Grid.SortOrder = Enum.SortOrder.LayoutOrder
    Grid.Parent = Scroll

    local EmptyMsg = Instance.new("TextLabel")
    EmptyMsg.Size = UDim2.new(1, 0, 1, 0)
    EmptyMsg.BackgroundTransparency = 1
    EmptyMsg.Text = "Нажми Скан чтобы найти изображения"
    EmptyMsg.TextColor3 = C.textMut
    EmptyMsg.Font = Enum.Font.Gotham
    EmptyMsg.TextSize = 13
    EmptyMsg.ZIndex = 2
    EmptyMsg.Parent = ContentBg

    -- Логика
    local foundIds = {}
    local foundSet = {}
    local cardsByLabel = {}
    local lastStats = { objects = 0, matched = 0, emptyProp = 0, badId = 0 }

    local function updateSubtitle(extra)
        if extra then Subtitle.Text = extra; return end
        Subtitle.Text = ("%d изображений · проверено %d"):format(#foundIds, lastStats.objects)
    end

    local function extractId(str)
        if type(str) ~= "string" or str == "" then return nil end
        local id = str:match("rbxassetid://(%d+)")
        if id then return id end
        id = str:match("rbxasset://(%d+)")
        if id then return id end
        id = str:match("roblox%.com/asset/%?id=(%d+)")
        if id then return id end
        id = str:match("roblox%.com/asset%?id=(%d+)")
        if id then return id end
        id = str:match("assetid:///*(%d+)")
        if id then return id end
        if str:match("^%d+$") then return str end
        return nil
    end

    local function extractAllIds(obj)
        local ids = {}
        local ok, v = pcall(function() return obj.Image end)
        if ok and type(v) == "string" and v ~= "" then
            local c = extractId(v); if c then table.insert(ids, c) end
        end
        ok, v = pcall(function() return obj.Texture end)
        if ok and type(v) == "string" and v ~= "" then
            local c = extractId(v); if c then table.insert(ids, c) end
        end
        if obj:IsA("Sky") then
            for _, face in ipairs({ "SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp" }) do
                local ok2, val = pcall(function() return obj[face] end)
                if ok2 and type(val) == "string" and val ~= "" then
                    local c = extractId(val); if c then table.insert(ids, c) end
                end
            end
        end
        return ids
    end

    -- Классы для режима
    local function isClassEnabled(obj)
        if mode == "quick" then
            return obj:IsA("ImageLabel") or obj:IsA("ImageButton")
        else
            for cls, on in pairs(toggles) do
                if on and obj:IsA(cls) then return true end
            end
            return false
        end
    end

    local function addCard(id)
        if foundSet[id] then return end
        foundSet[id] = true
        table.insert(foundIds, id)

        local Card = Instance.new("Frame")
        Card.Name = "C_" .. id
        Card.BackgroundColor3 = C.bgCard
        Card.BorderSizePixel = 0
        Card.ClipsDescendants = true
        Card.Parent = Scroll
        addCorner(Card, 10)
        local cStroke = addStroke(Card, C.border, 1)

        local imgWrap = Instance.new("Frame")
        imgWrap.Size = UDim2.new(1, -16, 0, 90)
        imgWrap.Position = UDim2.new(0, 8, 0, 8)
        imgWrap.BackgroundColor3 = C.bgInput
        imgWrap.BorderSizePixel = 0
        imgWrap.ClipsDescendants = true
        imgWrap.Parent = Card
        addCorner(imgWrap, 8)

        local img = Instance.new("ImageLabel")
        img.Size = UDim2.new(1, 0, 1, 0)
        img.BackgroundTransparency = 1
        img.Image = "rbxassetid://" .. id
        img.ScaleType = Enum.ScaleType.Fit
        img.Parent = imgWrap

        local statusIcon = Instance.new("TextLabel")
        statusIcon.Size = UDim2.new(1, 0, 1, 0)
        statusIcon.BackgroundTransparency = 1
        statusIcon.Text = ""
        statusIcon.TextSize = 28
        statusIcon.Font = Enum.Font.GothamBold
        statusIcon.TextColor3 = C.textMut
        statusIcon.Visible = false
        statusIcon.Parent = imgWrap

        -- В deep режиме — проверяем приватность
        if mode == "deep" then
            task.spawn(function()
                task.wait(2)
                local code = probeAsset(id)
                if code == 403 or code == 401 then
                    statusIcon.Text = "🔒"
                    statusIcon.TextColor3 = C.warning
                    statusIcon.Visible = true
                    Card:SetAttribute("Private", true)
                elseif code == 404 then
                    statusIcon.Text = "🚫"
                    statusIcon.TextColor3 = C.danger
                    statusIcon.Visible = true
                    Card:SetAttribute("Private", true)
                elseif code == 429 then
                    statusIcon.Text = "⏳"
                    statusIcon.TextColor3 = C.warning
                    statusIcon.Visible = true
                end
            end)
        end

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -16, 0, 18)
        label.Position = UDim2.new(0, 8, 0, 104)
        label.BackgroundTransparency = 1
        label.Text = id
        label.TextColor3 = C.textDim
        label.Font = Enum.Font.Code
        label.TextSize = 11
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = Card

        local saveBtn = Instance.new("TextButton")
        saveBtn.Size = UDim2.new(0, 26, 0, 22)
        saveBtn.Position = UDim2.new(1, -34, 0, 100)
        saveBtn.BackgroundColor3 = C.warning
        saveBtn.Text = "⤓"
        saveBtn.TextSize = 14
        saveBtn.Font = Enum.Font.GothamBold
        saveBtn.TextColor3 = Color3.fromRGB(30,30,30)
        saveBtn.BorderSizePixel = 0
        saveBtn.AutoButtonColor = false
        saveBtn.Visible = CAN_SAVE
        saveBtn.Parent = Card
        addCorner(saveBtn, 6)

        saveBtn.MouseButton1Click:Connect(function()
            saveBtn.Text = "…"
            saveBtn.BackgroundColor3 = C.textMut
            task.spawn(function()
                local ok2, path, reason = saveImage(id)
                if ok2 then
                    saveBtn.Text = "✓"; saveBtn.BackgroundColor3 = C.success
                else
                    saveBtn.Text = "✕"
                    saveBtn.BackgroundColor3 = (reason == "blocked" or reason == "private") and C.warning or C.danger
                    warnLog("Ошибка:", id, reason or path)
                end
                task.wait(2)
                if saveBtn then saveBtn.Text = "⤓"; saveBtn.BackgroundColor3 = C.warning end
            end)
        end)

        local hit = Instance.new("TextButton")
        hit.Size = UDim2.new(1, 0, 0, 100)
        hit.Position = UDim2.new(0, 0, 0, 0)
        hit.BackgroundTransparency = 1
        hit.Text = ""
        hit.Parent = Card

        hit.MouseEnter:Connect(function()
            tw(Card, {BackgroundColor3 = C.bgCardH}, 0.12)
            tw(cStroke, {Color = C.accent}, 0.12)
        end)
        hit.MouseLeave:Connect(function()
            tw(Card, {BackgroundColor3 = C.bgCard}, 0.12)
            tw(cStroke, {Color = C.border}, 0.12)
        end)
        hit.MouseButton1Click:Connect(function()
            if setclipboard then
                setclipboard(id)
                local old = label.Text
                if mode == "deep" then
                    local code = probeAsset(id)
                    local st = code == 200 and "✓ доступна" or
                               code == 403 and "🔒 приватная" or
                               code == 404 and "🚫 удалена" or
                               code == 429 and "⏳ лимит" or
                               ("HTTP " .. tostring(code))
                    label.Text = "ID скопирован · " .. st
                    label.TextColor3 = code == 200 and C.success or C.warning
                else
                    label.Text = "✓ Скопировано"
                    label.TextColor3 = C.success
                end
                task.wait(2)
                if label then label.Text = old; label.TextColor3 = C.textDim end
            end
        end)

        cardsByLabel[id] = { card = Card, label = label }
        EmptyMsg.Visible = false

        -- Учитываем тогл "скрыть приватные" при добавлении
        if mode == "deep" and hidePrivate and Card:GetAttribute("Private") then
            Card.Visible = false
        end
    end

    local function filterCards(q)
        q = (q or ""):lower():gsub("%s", "")
        for id, e in pairs(cardsByLabel) do
            if e.card and e.card.Parent then
                local match = (q == "" or id:lower():find(q, 1, true))
                if match then
                    if mode == "deep" and hidePrivate and e.card:GetAttribute("Private") then
                        e.card.Visible = false
                    else
                        e.card.Visible = true
                    end
                else
                    e.card.Visible = false
                end
            end
        end
    end

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        filterCards(SearchBox.Text)
    end)

    -- Тогл скрыть приватные
    if mode == "deep" and hideChip then
        hideChip.MouseButton1Click:Connect(function()
            hidePrivate = not hidePrivate
            if hidePrivate then
                hideChip.Text = "✓ Скрыть приватные"
                tw(hideChip, {BackgroundColor3 = C.danger, TextColor3 = Color3.new(1,1,1)}, 0.12)
            else
                hideChip.Text = "  Скрыть приватные"
                tw(hideChip, {BackgroundColor3 = C.bgCard, TextColor3 = C.textDim}, 0.12)
            end
            filterCards(SearchBox.Text)
        end)
    end

    local function scan()
        for _, ch in ipairs(Scroll:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        foundIds = {}
        foundSet = {}
        cardsByLabel = {}
        lastStats = { objects = 0, matched = 0, emptyProp = 0, badId = 0 }

        local visited = {}
        local selfGui = ScreenGui

        local function visit(obj)
            if visited[obj] then return end
            visited[obj] = true
            if selfGui and (obj == selfGui or obj:IsDescendantOf(selfGui)) then return end

            lastStats.objects = lastStats.objects + 1

            if isClassEnabled(obj) then
                lastStats.matched = lastStats.matched + 1
                local ids = extractAllIds(obj)
                if #ids == 0 then
                    lastStats.emptyProp = lastStats.emptyProp + 1
                else
                    for _, id in ipairs(ids) do
                        if id and #id > 0 then
                            addCard(id)
                        else
                            lastStats.badId = lastStats.badId + 1
                        end
                    end
                end
            end

            for _, child in ipairs(obj:GetChildren()) do
                pcall(visit, child)
            end
        end

        pcall(visit, game)

        if CoreGui then
            pcall(function()
                for _, ch in ipairs(CoreGui:GetChildren()) do
                    if ch ~= selfGui then pcall(visit, ch) end
                end
            end)
        end

        updateSubtitle()
        EmptyMsg.Visible = (#foundIds == 0)
        log(("Скан [%s] · Объектов: %d | классов: %d | пустых: %d | ID: %d")
            :format(mode, lastStats.objects, lastStats.matched, lastStats.emptyProp, #foundIds))
    end

    ScanBtn.MouseButton1Click:Connect(function()
        Subtitle.Text = "Сканирование..."
        task.wait(0.05)
        scan()
    end)

    ClearBtn.MouseButton1Click:Connect(function()
        for _, ch in ipairs(Scroll:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        foundIds = {}; foundSet = {}; cardsByLabel = {}
        SearchBox.Text = ""
        EmptyMsg.Visible = true
        Subtitle.Text = "Готов"
    end)

    CopyBtn.MouseButton1Click:Connect(function()
        if #foundIds == 0 then Subtitle.Text = "Нечего копировать"; return end
        if not setclipboard then Subtitle.Text = "setclipboard недоступен"; return end

        local text = table.concat(foundIds, "\n")
        local len = #text
        setclipboard(text)

        local verified, readBack = false, nil
        if type(getclipboard) == "function" then
            local ok2, cb = pcall(getclipboard)
            if ok2 and cb then
                readBack = #cb
                verified = (cb == text)
            end
        end

        if verified then
            Subtitle.Text = ("✓ %d ID · %d символов · проверено"):format(#foundIds, len)
        elseif readBack then
            Subtitle.Text = ("⚠ %d ID · %d символов (в буфере %d)"):format(#foundIds, len, readBack)
        else
            Subtitle.Text = ("Скопировано %d ID · %d символов"):format(#foundIds, len)
        end

        task.wait(4)
        if Subtitle then updateSubtitle() end
    end)

    local saving = false
    SaveAllBtn.MouseButton1Click:Connect(function()
        if saving then return end
        if not CAN_SAVE then Subtitle.Text = "writefile недоступен"; return end
        if #foundIds == 0 then Subtitle.Text = "Сначала Скан"; return end
        saving = true
        task.spawn(function()
            local okc, failc = 0, 0
            for i, id in ipairs(foundIds) do
                Subtitle.Text = ("Сохр %d/%d · %s"):format(i, #foundIds, id)
                local ok2 = saveImage(id)
                if ok2 then okc = okc + 1 else failc = failc + 1 end
                task.wait(0.2)
            end
            Subtitle.Text = ("✓ %d · ✕ %d · всего %d"):format(okc, failc, #foundIds)
            task.wait(4)
            if Subtitle then updateSubtitle() end
            saving = false
        end)
    end)

    -- Минимизация
    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        local h = (mode == "quick") and 500 or 500
        local target = minimized and UDim2.new(0, 720, 0, 52) or UDim2.new(0, 720, 0, h)
        tw(Main, {Size = target}, 0.2)
        MinBtn.Text = minimized and "▢" or "—"
    end)

    -- Автоскан
    task.spawn(function()
        task.wait(0.3)
        Subtitle.Text = "Сканирование..."
        scan()
    end)

    log("Режим установлен:", mode)
end

log("Установщик загружен")
