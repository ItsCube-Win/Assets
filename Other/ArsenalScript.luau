
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

local getAsset = getcustomasset or getsynasset
if not (getAsset and writefile and isfile and makefolder and isfolder and listfiles and readfile) then
	warn("[Dynamic Island] Ваш executor не поддерживает нужные файловые функции.")
	return
end

local BASE_DIR = ".music"
local ASSETS_DIR = BASE_DIR .. "/Assets"
local MUSIC_DIR = ASSETS_DIR .. "/Music"
local ICON_DIR = ASSETS_DIR .. "/Icon"
local CONFIG_FILE = BASE_DIR .. "/config.json"

if not isfolder(BASE_DIR) then makefolder(BASE_DIR) end
if not isfolder(ASSETS_DIR) then makefolder(ASSETS_DIR) end
if not isfolder(MUSIC_DIR) then makefolder(MUSIC_DIR) end
if not isfolder(ICON_DIR) then makefolder(ICON_DIR) end

-- Читаем конфиг или создаем новый
local config = {}
if isfile(CONFIG_FILE) then
	local success, decoded = pcall(function()
		return HttpService:JSONDecode(readfile(CONFIG_FILE))
	end)
	if success and type(decoded) == "table" then
		config = decoded
	end
end

-- Функция для красивого сохранения JSON (чтобы _saved_state был в начале)
local function saveConfig()
	local jsonStr = "{\n"
	
	-- Сначала записываем состояние (если есть)
	if config._saved_state then
		jsonStr = jsonStr .. '    "_saved_state": {\n'
		jsonStr = jsonStr .. '        "last_played_index": ' .. tostring(config._saved_state.last_played_index) .. ',\n'
		jsonStr = jsonStr .. '        "last_time_position": ' .. tostring(config._saved_state.last_time_position) .. ',\n'
		jsonStr = jsonStr .. '        "last_saved_timestamp": ' .. tostring(config._saved_state.last_saved_timestamp) .. ',\n'
		jsonStr = jsonStr .. '        "was_playing": ' .. tostring(config._saved_state.was_playing) .. '\n'
		jsonStr = jsonStr .. '    }'
		-- Проверяем, есть ли другие ключи
		local hasOtherKeys = false
		for k, _ in pairs(config) do if k ~= "_saved_state" then hasOtherKeys = true break end end
		if hasOtherKeys then jsonStr = jsonStr .. ",\n" end
	end
	
	-- Записываем остальные треки
	local first = true
	for k, v in pairs(config) do
		if k ~= "_saved_state" then
			if not first then jsonStr = jsonStr .. ",\n" end
			first = false
			jsonStr = jsonStr .. '    "' .. k .. '": {\n'
			jsonStr = jsonStr .. '        "name": "' .. tostring(v.name) .. '",\n'
			jsonStr = jsonStr .. '        "artist": "' .. tostring(v.artist) .. '"\n'
			jsonStr = jsonStr .. '    }'
		end
	end
	jsonStr = jsonStr .. "\n}"
	writefile(CONFIG_FILE, jsonStr)
end

-- Создаем шаблон, если конфига не было
if not isfile(CONFIG_FILE) then
	config = {
		_saved_state = {
			last_played_index = 1,
			last_time_position = 0,
			last_saved_timestamp = 0,
			was_playing = false
		},
		track1 = { name = "Here You Come Again", artist = "Dolly Parton" },
		track2 = { name = "Track Two", artist = "Unknown" }
	}
	saveConfig()
end

-- Сканируем папку с музыкой
local PLAYLIST = {}
local musicFiles = listfiles(MUSIC_DIR)

for _, filePath in ipairs(musicFiles) do
	if filePath:match("%.mp3$") then
		local fileName = filePath:match("([^/\\]+)%.mp3$")
		local trackInfo = config[fileName] or {}
		local title = trackInfo.name or fileName
		local artist = trackInfo.artist or "Unknown"
		
		local iconPath = ICON_DIR .. "/" .. fileName .. ".png"
		local cover = ""
		if isfile(iconPath) then
			local iconSuccess, iconAsset = pcall(getAsset, iconPath)
			if iconSuccess and iconAsset then cover = iconAsset end
		end
		
		table.insert(PLAYLIST, { title = title, artist = artist, file = filePath, cover = cover })
	end
end

if #PLAYLIST == 0 then
	warn("[Dynamic Island] В папке .music/Assets/Music нет MP3 файлов!")
	table.insert(PLAYLIST, { title = "Нет файлов", artist = "Добавьте MP3", file = "", cover = "" })
end

--------------------------------------------------------------------
-- НАСТРОЙКИ UI
--------------------------------------------------------------------
local TOGGLE_KEY = Enum.KeyCode.M
local TRIGGER_Y = 36
local TRIGGER_HALF_W = 190
local LEAVE_DELAY = 0.25

local ACCENT = Color3.fromRGB(255, 255, 255)
local MUTED = Color3.fromRGB(150, 150, 155)
local ICON_IDLE = Color3.fromRGB(255, 255, 255)
local HEART_OFF = Color3.fromRGB(190, 190, 196)
local LIKE_COLOR = Color3.fromRGB(255, 45, 85)

local FULL_W, FULL_H = 360, 150
local SHOWN_Y = 14
local HIDDEN_Y = -(FULL_H + 30)

--------------------------------------------------------------------
-- УТИЛИТЫ
--------------------------------------------------------------------
local function tween(obj, time, props, style, dir)
	local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function formatTime(sec)
	sec = math.max(0, math.floor(sec or 0))
	return string.format("%d:%02d", sec // 60, sec % 60)
end

local function new(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props) do inst[k] = v end
	for _, c in ipairs(children or {}) do c.Parent = inst end
	return inst
end

local function corner(r) return new("UICorner", { CornerRadius = UDim.new(0, r) }) end

--------------------------------------------------------------------
-- ЗВУК
--------------------------------------------------------------------
local sound = Instance.new("Sound")
sound.Name = "IslandPlayerSound"
sound.Volume = 0.6
sound.Parent = SoundService

local index = 1
local playing = false

--------------------------------------------------------------------
-- GUI: ГЛОУ И ОСТРОВ
--------------------------------------------------------------------
local gui = new("ScreenGui", {
	Name = "DynamicIslandPlayer", ResetOnSpawn = false, IgnoreGuiInset = true,
	DisplayOrder = 50, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

local glowDefs = {
	{ w = 200, visible = 5,  alpha = 0.40 },
	{ w = 260, visible = 9,  alpha = 0.62 },
	{ w = 330, visible = 14, alpha = 0.80 },
	{ w = 420, visible = 20, alpha = 0.91 },
}
local glowLayers = {}
for i, d in ipairs(glowDefs) do
	local f = new("Frame", {
		Name = "Glow" .. i, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, d.visible - 60),
		Size = UDim2.fromOffset(d.w, 60), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
		BorderSizePixel = 0, Parent = gui,
	}, { corner(30) })
	glowLayers[i] = { frame = f, def = d }
end

local island = new("Frame", {
	Name = "Island", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, HIDDEN_Y),
	Size = UDim2.fromOffset(FULL_W, FULL_H), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0,
	ClipsDescendants = true, Active = true, Visible = false, Parent = gui,
}, {
	corner(24),
	new("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9, Thickness = 1 }),
})

local islandScale = new("UIScale", { Scale = 0.92, Parent = island })
local content = new("CanvasGroup", { Name = "Content", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1, Parent = island })

-- Обложка
local artHolder = new("Frame", { Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(54, 54), BackgroundTransparency = 1, Parent = content })
local art = new("ImageLabel", {
	Name = "Art", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(60, 60, 70), BorderSizePixel = 0, ScaleType = Enum.ScaleType.Crop, Image = "", Parent = artHolder,
}, {
	corner(10), new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 110, 140), Color3.fromRGB(90, 70, 200)), Rotation = 45 }),
})
local artScale = new("UIScale", { Scale = 0.88, Parent = art })

-- Тексты
local titleLabel = new("TextLabel", {
	Position = UDim2.fromOffset(82, 18), Size = UDim2.new(1, -150, 0, 20), BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = ACCENT, TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd, Text = "", Parent = content,
})
local artistLabel = new("TextLabel", {
	Position = UDim2.fromOffset(82, 40), Size = UDim2.new(1, -150, 0, 18), BackgroundTransparency = 1,
	Font = Enum.Font.Gotham, TextSize = 15, TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd, Text = "", Parent = content,
})

-- Эквалайзер
local eq = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 22), Size = UDim2.fromOffset(22, 20), BackgroundTransparency = 1, Parent = content })
local eqBars = {}
for i = 1, 4 do
	eqBars[i] = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset((i - 1) * 6, 20), Size = UDim2.fromOffset(3, 4), BackgroundColor3 = LIKE_COLOR, BorderSizePixel = 0, Parent = eq }, { corner(2) })
end

-- Прогресс-бар
local barArea = new("Frame", { Position = UDim2.fromOffset(16, 78), Size = UDim2.new(1, -32, 0, 20), BackgroundTransparency = 1, Active = true, Parent = content })
local track = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 5), BackgroundColor3 = Color3.fromRGB(70, 70, 75), BorderSizePixel = 0, Parent = barArea }, { corner(3) })
local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(200, 200, 205), BorderSizePixel = 0, Parent = track }, { corner(3) })
local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(0, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = track }, { corner(10) })

local timeLeft = new("TextLabel", { Position = UDim2.fromOffset(16, 96), Size = UDim2.fromOffset(50, 14), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left, Text = "0:00", Parent = content })
local timeRight = new("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 96), Size = UDim2.fromOffset(50, 14), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Right, Text = "-0:00", Parent = content })

--------------------------------------------------------------------
-- ИКОНКИ
--------------------------------------------------------------------
local function newIcon(parent, w, h)
	local root = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, Parent = parent })
	local icon = { root = root, shapes = {} }
	function icon.setColor(color, time)
		for _, s in ipairs(icon.shapes) do
			if time then tween(s, time, { BackgroundColor3 = color }) else s.BackgroundColor3 = color end
		end
	end
	return icon
end

local function addBar(icon, parent, x, y, w, h, radius)
	local f = new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = ICON_IDLE, BorderSizePixel = 0, Parent = parent }, { corner(radius or 0) })
	table.insert(icon.shapes, f)
	return f
end

local function addTriangle(icon, parent, x, y, w, h, dir)
	local holder = new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, ClipsDescendants = true, Parent = parent })
	for i = 0, w - 1 do
		local f = (i + 0.5) / w
		local k = dir == 1 and (1 - f) or f
		local s = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(i, h / 2), Size = UDim2.fromOffset(2, math.max(2, h * k)), BackgroundColor3 = ICON_IDLE, BorderSizePixel = 0, Parent = holder })
		table.insert(icon.shapes, s)
	end
	return holder
end

local function buildSkip(parent, dir)
	local icon = newIcon(parent, 24, 18)
	addTriangle(icon, icon.root, 0, 0, 13, 18, dir)
	addTriangle(icon, icon.root, 11, 0, 13, 18, dir)
	return icon
end

local function buildPlayPause(parent)
	local icon = newIcon(parent, 26, 26)
	local pauseGroup = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = icon.root })
	local pauseScale = new("UIScale", { Scale = 0, Parent = pauseGroup })
	addBar(icon, pauseGroup, 3, 1, 7, 24, 3)
	addBar(icon, pauseGroup, 16, 1, 7, 24, 3)

	local playGroup = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = icon.root })
	local playScale = new("UIScale", { Scale = 1, Parent = playGroup })
	addTriangle(icon, playGroup, 4, 0, 21, 26, 1)

	local current = nil
	function icon.setPlaying(state, animated)
		if current == state then return end
		current = state
		local inScale, outScale = state and pauseScale or playScale, state and playScale or pauseScale
		local inGroup, outGroup = state and pauseGroup or playGroup, state and playGroup or pauseGroup
		if animated then
			inGroup.Visible = true; inScale.Scale = 0.3
			tween(inScale, 0.5, { Scale = 1 }, Enum.EasingStyle.Elastic)
			tween(outScale, 0.15, { Scale = 0 })
			task.delay(0.16, function() if current == state then outGroup.Visible = false end end)
		else
			inScale.Scale = 1; outScale.Scale = 0; inGroup.Visible = true; outGroup.Visible = false
		end
	end
	icon.setPlaying(false, false)
	return icon
end

local function buildHeart(parent)
	local icon = newIcon(parent, 26, 26)
	local a = 12; local cx, cy = 13, 14.5; local off = a * 0.354
	local square = addBar(icon, icon.root, 0, 0, a, a, 2)
	square.AnchorPoint = Vector2.new(0.5, 0.5); square.Position = UDim2.fromOffset(cx, cy); square.Rotation = 45
	for _, sx in ipairs({ -1, 1 }) do
		local c = addBar(icon, icon.root, 0, 0, a, a, 0)
		c.AnchorPoint = Vector2.new(0.5, 0.5); c.Position = UDim2.fromOffset(cx + sx * off, cy - off)
		c:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0.5, 0)
	end
	icon.setColor(HEART_OFF)
	return icon
end

local function makeButton(props)
	local btn = new("TextButton", {
		Name = props.name, AnchorPoint = Vector2.new(0.5, 0.5), Position = props.position,
		Size = UDim2.fromOffset(props.size, props.size), BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = content,
	}, { corner(props.size // 2) })

	local scale = new("UIScale", { Scale = 1, Parent = btn })
	local icon = props.build(btn)
	local iconScale = new("UIScale", { Scale = 1, Parent = icon.root })
	local hovering = false

	btn.MouseEnter:Connect(function() hovering = true; tween(scale, 0.25, { Scale = 1.12 }, Enum.EasingStyle.Back); tween(btn, 0.2, { BackgroundTransparency = 0.88 }) end)
	btn.MouseLeave:Connect(function() hovering = false; tween(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back); tween(btn, 0.25, { BackgroundTransparency = 1 }) end)
	btn.MouseButton1Down:Connect(function() tween(scale, 0.1, { Scale = 0.82 }); tween(btn, 0.1, { BackgroundTransparency = 0.7 }) end)
	btn.MouseButton1Up:Connect(function() tween(scale, 0.35, { Scale = hovering and 1.12 or 1 }, Enum.EasingStyle.Elastic); tween(btn, 0.25, { BackgroundTransparency = hovering and 0.88 or 1 }) end)
	btn.Activated:Connect(function()
		iconScale.Scale = 0.7; tween(iconScale, 0.4, { Scale = 1 }, Enum.EasingStyle.Elastic)
		if props.onClick then props.onClick(btn, icon) end
	end)
	return btn, icon
end

--------------------------------------------------------------------
-- ЛОГИКА ПЛЕЕРА
--------------------------------------------------------------------
local toggle, change, playIcon, applyPlayState

local function setCover(t)
	local g = art:FindFirstChildOfClass("UIGradient")
	if t.cover and t.cover ~= "" then
		art.Image = t.cover; if g then g.Enabled = false end; art.BackgroundTransparency = 1
	else
		art.Image = ""; if g then g.Enabled = true end; art.BackgroundTransparency = 0
	end
end

local function loadTrack(i, autoplay)
	index = ((i - 1) % #PLAYLIST) + 1
	local t = PLAYLIST[index]

	sound:Stop()
	if t.file ~= "" and isfile(t.file) then
		local success, assetId = pcall(getAsset, t.file)
		if success and assetId then sound.SoundId = assetId else sound.SoundId = "" end
	else
		sound.SoundId = ""
	end

	sound.TimePosition = 0
	setCover(t)

	titleLabel.TextTransparency = 1; artistLabel.TextTransparency = 1
	titleLabel.Text = t.title; artistLabel.Text = t.artist
	tween(titleLabel, 0.35, { TextTransparency = 0 }); tween(artistLabel, 0.35, { TextTransparency = 0 })

	local s = artHolder:FindFirstChild("PopScale") or new("UIScale", { Name = "PopScale", Parent = artHolder })
	s.Scale = 0.85; tween(s, 0.5, { Scale = 1 }, Enum.EasingStyle.Elastic)

	fill.Size = UDim2.fromScale(0, 1); knob.Position = UDim2.fromScale(0, 0.5)

	playing = autoplay and (sound.SoundId ~= "")
	if playing then sound:Play() end
	applyPlayState(false)
end

applyPlayState = function(animated)
	if playIcon then playIcon.setPlaying(playing, animated) end
	tween(artScale, 0.45, { Scale = playing and 1 or 0.88 }, Enum.EasingStyle.Back)
end

toggle = function()
	if sound.SoundId == "" then return end
	playing = not playing
	if playing then sound:Play() else sound:Pause() end
	applyPlayState(true)
end

change = function(dir) loadTrack(index + dir, playing) end
sound.Ended:Connect(function() loadTrack(index + 1, true) end)

--------------------------------------------------------------------
-- КНОПКИ
--------------------------------------------------------------------
local BTN_Y = 122

makeButton({
	name = "Prev", size = 46, position = UDim2.new(0.5, -76, 0, BTN_Y),
	build = function(p) return buildSkip(p, -1) end,
	onClick = function() if sound.TimePosition > 3 then sound.TimePosition = 0 else change(-1) end end,
})

local _, pIcon = makeButton({
	name = "Play", size = 58, position = UDim2.new(0.5, 0, 0, BTN_Y),
	build = buildPlayPause, onClick = function() toggle() end,
})
playIcon = pIcon

makeButton({
	name = "Next", size = 46, position = UDim2.new(0.5, 76, 0, BTN_Y),
	build = function(p) return buildSkip(p, 1) end, onClick = function() change(1) end,
})

local liked = false
makeButton({
	name = "Like", size = 40, position = UDim2.new(1, -34, 0, BTN_Y),
	build = buildHeart,
	onClick = function(_, icon) liked = not liked; icon.setColor(liked and LIKE_COLOR or HEART_OFF, 0.25) end,
})

task.spawn(function()
	while gui.Parent do
		for _, bar in ipairs(eqBars) do
			local h = playing and math.random(4, 20) or 4
			tween(bar, 0.18, { Size = UDim2.fromOffset(3, h) }, Enum.EasingStyle.Sine)
		end
		task.wait(0.18)
	end
end)

--------------------------------------------------------------------
-- ПРОГРЕСС-БАР
--------------------------------------------------------------------
local dragging = false
local hoveringBar = false

local function barHover(state)
	hoveringBar = state
	local big = state or dragging
	tween(track, 0.2, { Size = UDim2.new(1, 0, 0, big and 9 or 5) })
	tween(knob, 0.25, { Size = big and UDim2.fromOffset(14, 14) or UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
	tween(fill, 0.2, { BackgroundColor3 = big and Color3.new(1, 1, 1) or Color3.fromRGB(200, 200, 205) })
end

barArea.MouseEnter:Connect(function() barHover(true) end)
barArea.MouseLeave:Connect(function() if not dragging then barHover(false) end end)

local function seekFromX(x)
	local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
	fill.Size = UDim2.fromScale(rel, 1); knob.Position = UDim2.fromScale(rel, 0.5)
	if sound.TimeLength > 0 then sound.TimePosition = rel * sound.TimeLength end
end

barArea.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true; barHover(true); seekFromX(input.Position.X)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then seekFromX(input.Position.X) end
end)

UserInputService.InputEnded:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then dragging = false; barHover(hoveringBar) end
end)

--------------------------------------------------------------------
-- АНИМАЦИЯ ОСТРОВА
--------------------------------------------------------------------
local shown = false
local pinned = false 
local token = 0

local function setShown(state)
	if shown == state then return end
	shown = state; token += 1; local my = token
	if state then
		island.Visible = true
		tween(island, 0.65, { Position = UDim2.new(0.5, 0, 0, SHOWN_Y) }, Enum.EasingStyle.Back)
		tween(islandScale, 0.6, { Scale = 1 }, Enum.EasingStyle.Back)
		tween(content, 0.45, { GroupTransparency = 0 })
	else
		pinned = false
		tween(island, 0.45, { Position = UDim2.new(0.5, 0, 0, HIDDEN_Y) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		tween(islandScale, 0.45, { Scale = 0.92 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		tween(content, 0.25, { GroupTransparency = 1 })
		task.delay(0.47, function() if token == my and not shown then island.Visible = false end end)
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == TOGGLE_KEY then
		if shown then setShown(false) else pinned = true; setShown(true) end
	end
end)

local touchMode = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
UserInputService.LastInputTypeChanged:Connect(function(t)
	if t == Enum.UserInputType.Touch then touchMode = true
	elseif t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.MouseButton1 then touchMode = false end
end)

local swipe = nil 
local function screenY(pos) return pos.Y + GuiService:GetGuiInset().Y end

UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.Touch or dragging then return end
	local y = screenY(input.Position)
	if not shown and y < 90 then swipe = { input = input, startY = y }
	elseif shown then
		if y > SHOWN_Y + FULL_H + 10 then setShown(false) else swipe = { input = input, startY = y } end
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not swipe or swipe.input ~= input or dragging then return end
	local dy = screenY(input.Position) - swipe.startY
	if not shown and dy > 30 then pinned = true; setShown(true); swipe = nil
	elseif shown and dy < -30 then setShown(false); swipe = nil end
end)

UserInputService.InputEnded:Connect(function(input)
	if swipe and swipe.input == input then swipe = nil end
end)

--------------------------------------------------------------------
-- СОХРАНЕНИЕ СОСТОЯНИЯ (ДЛЯ ТЕЛЕПОРТА)
--------------------------------------------------------------------
task.spawn(function()
	while gui.Parent do
		task.wait(2) -- Сохраняем каждые 2 секунды
		if playing and sound.IsPlaying then
			config._saved_state = {
				last_played_index = index,
				last_time_position = sound.TimePosition,
				last_saved_timestamp = os.time(), -- Запоминаем время
				was_playing = true
			}
			-- Чтобы не спамить записью на диск, сохраняем только если позиция изменилась
			if config._saved_state.last_time_position > 0 then
				pcall(saveConfig)
			end
		end
	end
end)

--------------------------------------------------------------------
-- ГЛАВНЫЙ ЦИКЛ
--------------------------------------------------------------------
local leaveTimer = 0
local prox = 0
local glow = 0.55

RunService.RenderStepped:Connect(function(dt)
	local len = sound.TimeLength
	if not dragging and len > 0 then
		local rel = math.clamp(sound.TimePosition / len, 0, 1)
		fill.Size = UDim2.fromScale(rel, 1); knob.Position = UDim2.fromScale(rel, 0.5)
	end
	timeLeft.Text = formatTime(sound.TimePosition); timeRight.Text = "-" .. formatTime(len - sound.TimePosition)

	local freeMouse = UserInputService.MouseBehavior == Enum.MouseBehavior.Default
	if not touchMode and freeMouse then
		local m = UserInputService:GetMouseLocation(); local W = gui.AbsoluteSize.X
		local dx = math.abs(m.X - W / 2); local dy = m.Y
		prox = math.clamp(1 - dy / 130, 0, 1) * math.clamp(1 - dx / 340, 0, 1)

		if not shown then
			if dy <= TRIGGER_Y and dx <= TRIGGER_HALF_W then setShown(true) end
		elseif not pinned then
			local inside = dx <= FULL_W / 2 + 40 and dy <= SHOWN_Y + FULL_H + 40
			if inside or dragging then leaveTimer = 0
			else
				leaveTimer += dt
				if leaveTimer >= LEAVE_DELAY then leaveTimer = 0; setShown(false) end
			end
		end
	else
		prox = 0
	end

	local target = shown and 0 or (0.55 + 0.45 * prox)
	glow += (target - glow) * math.clamp(dt * 10, 0, 1)
	for _, l in ipairs(glowLayers) do
		local d = l.def
		l.frame.BackgroundTransparency = 1 - (1 - d.alpha) * glow
		local vis = d.visible + prox * 7
		l.frame.Position = UDim2.new(0.5, 0, 0, vis - 60)
	end
end)

--------------------------------------------------------------------
-- СТАРТ И ВОССТАНОВЛЕНИЕ ПОСЛЕ ТЕЛЕПОРТА
--------------------------------------------------------------------
local resumeIndex = 1
local resumeTime = 0
local shouldResume = false

if config._saved_state then
	local st = config._saved_state
	local timeDiff = os.time() - (st.last_saved_timestamp or 0)
	
	-- Если прошло меньше 60 секунд с последнего сохранения и музыка играла — это телепорт!
	if timeDiff > 0 and timeDiff <= 60 and st.was_playing then
		shouldResume = true
		resumeIndex = st.last_played_index or 1
		resumeTime = st.last_time_position or 0
		print("[Dynamic Island] Обнаружен телепорт! Восстанавливаем трек " .. resumeIndex .. " на секунде " .. math.floor(resumeTime))
	end
end

if shouldResume then
	loadTrack(resumeIndex, true)
	-- Ждем загрузки звука и ставим на нужную секунду
	task.spawn(function()
		local timeout = 0
		while not sound.IsLoaded and timeout < 50 do
			task.wait(0.1)
			timeout += 1
		end
		if sound.IsLoaded then
			sound.TimePosition = resumeTime
		end
	end)
else
	loadTrack(1, false)
end
