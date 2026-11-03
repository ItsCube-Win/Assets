-- ==================== CONFIG ====================
local ROOT        = "_https"
local SOURCE_DIR  = ROOT .. "/Source"
local PLACES_FILE = ROOT .. "/places.json"
local CONFIG_FILE = ROOT .. "/config.json"
local IGNORE_FILE = ROOT .. "/ignore.json"

local CONTEXT_LINES = 2
local MAX_DESC_LEN  = 3600
local MAX_LIST_LEN  = 1500
local DEBUG_PATHS   = true

-- ==================== SERVICES ====================
local HttpService        = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players            = game:GetService("Players")
local CoreGui            = game:GetService("CoreGui")

-- ==================== DEFAULT IGNORE LIST ====================
local DEFAULT_IGNORE = {
    prefixes = {
        "CoreGui", "CorePackages", "RobloxReplicatedStorage",
        "Stats", "TextChatService", "Chat", "AdService",
        "AnalyticsService", "AppStorageService", "AssetService",
        "AvatarEditorService", "BrowserService", "ChatbotUIService",
        "CloudLocalizationTable", "ContentProvider", "ContextActionService",
        "ControllerService", "CookiesService", "DraftsService",
        "DraggerService", "GamepadService", "GeometryService",
        "GuiService", "HapticService", "Hopper", "HttpService",
        "InsertService", "JointCreationService", "KeyboardService",
        "KeyframeSequenceProvider", "LocalizationService", "LogService",
        "LuaWebService", "MarketplaceService", "MaterialService",
        "MemStorageService", "MessageBusService", "MouseService",
        "NetworkClient", "NetworkServer", "NotificationService",
        "PathfindingService", "PhysicsService", "PlayerEmulatorService",
        "PluginGuiService", "ProcessInstancePhysicsService",
        "ProximityPromptService", "ReplicatedFirst",
        "RobloxPluginGuiService", "RbxAnalyticsService", "ScriptContext",
        "ScriptService", "Selection", "SessionService", "SocialService",
        "SoundService", "SpeechService", "StarterPack",
        "StopWatchReporter", "Studio", "StylingService",
        "TaskScheduler", "Teams", "TeleportService", "TestService",
        "TextBoxService", "TextureGenerationService", "TimeSyncService",
        "TimerService", "TouchInputService", "TracerService",
        "UserGameSettings", "UserInputService", "UserService",
        "VRService", "VRStatusService", "VersionControlService",
        "VirtualInputManager", "VirtualUser", "Visit",
        "VoiceChatInternal", "VoiceChatService", "WebViewService",
        "Workspace/Camera", "Workspace/CurrentCamera", "Workspace/Terrain",
        "Workspace/Players", "Players",
    },
    classes = {
        "UIGradient", "UIStroke", "UICorner", "UIPadding",
        "UIListLayout", "UIGridLayout", "UIPageLayout", "UITableLayout",
        "UISizeConstraint", "UIAspectRatioConstraint",
        "UITextSizeConstraint", "UIScale", "UIShadow",
        "UISelectionImage", "ParticleEmitter", "Beam", "Trail",
        "Smoke", "Fire", "Sparkles", "Attachment",
    },
}

-- ==================== IGNORE LOADER ====================
local IgnorePrefixes, IgnoreClasses = {}, {}

local function loadIgnoreList()
    if not isfile(IGNORE_FILE) then
        local ok, encoded = pcall(HttpService.JSONEncode, HttpService, DEFAULT_IGNORE)
        if ok then
            pcall(writefile, IGNORE_FILE, encoded)
            print("[https] Created default " .. IGNORE_FILE)
        end
    end

    local data = {}
    if isfile(IGNORE_FILE) then
        local ok, raw = pcall(readfile, IGNORE_FILE)
        if ok and raw and #raw > 0 then
            local ok2, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
            if ok2 and type(decoded) == "table" then data = decoded end
        end
    end

    IgnorePrefixes = {}
    IgnoreClasses  = {}

    for _, p in ipairs(data.prefixes or DEFAULT_IGNORE.prefixes) do
        IgnorePrefixes[#IgnorePrefixes + 1] = p
    end
    for _, c in ipairs(data.classes or DEFAULT_IGNORE.classes) do
        IgnoreClasses[c] = true
    end
end

-- ==================== MESSAGEBOX ====================
local MessageBox
do
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/xHeptc/NotificationGUI/main/source.lua"
        ))()
    end)
    if ok and result then
        MessageBox = result
    else
        warn("[https] Failed to load MessageBox: " .. tostring(result))
        MessageBox = {
            Show = function(opts)
                warn("[https] " .. tostring(opts.Text) .. ": " .. tostring(opts.Description))
                if opts.Result then opts.Result("OK") end
            end
        }
    end
end

local function showCentered(opts)
    opts = opts or {}
    opts.Position = UDim2.new(0.5, 0, 0.5, 0)

    local beforeGui = CoreGui:FindFirstChild("Notifications")
    local beforeChildren = {}
    if beforeGui then
        for _, c in ipairs(beforeGui:GetChildren()) do
            beforeChildren[c] = true
        end
    end

    MessageBox.Show(opts)

    task.defer(function()
        local gui = CoreGui:FindFirstChild("Notifications")
        if not gui then return end
        pcall(function() gui.IgnoreGuiInset = true end)
        pcall(function() gui.DisplayOrder = 10000 end)

        local newest
        for _, c in ipairs(gui:GetChildren()) do
            if c:IsA("GuiObject") and not beforeChildren[c] then
                newest = c
            end
        end
        if not newest then
            for _, c in ipairs(gui:GetChildren()) do
                if c:IsA("Frame") then newest = c end
            end
        end
        if not newest then return end

        task.wait()
        newest.AnchorPoint = Vector2.new(0.5, 0.5)
        newest.Position    = UDim2.new(0.5, 0, 0.5, 0)
    end)
end

local function notify(icon, text, description)
    showCentered({
        Text              = text,
        Description       = description,
        MessageBoxIcon    = icon,
        MessageBoxButtons = "OK"
    })
end

-- ==================== INIT ====================
local function ensureFolders()
    if not isfolder(ROOT)       then makefolder(ROOT) end
    if not isfolder(SOURCE_DIR) then makefolder(SOURCE_DIR) end
    if not isfile(PLACES_FILE)  then writefile(PLACES_FILE, "{}") end
    if not isfile(CONFIG_FILE) then
        writefile(CONFIG_FILE, HttpService:JSONEncode({
            webhook         = "",
            username        = "https",
            color           = 2829617,
            send_no_changes = nil
        }))
    end
end
ensureFolders()
loadIgnoreList()

-- ==================== JSON ====================
local function loadJSON(path)
    if not isfile(path) then return {} end
    local ok, data = pcall(readfile, path)
    if not ok or not data or #data == 0 then return {} end
    local ok2, decoded = pcall(HttpService.JSONDecode, HttpService, data)
    return ok2 and decoded or {}
end

local function saveJSON(path, tbl)
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, tbl)
    if not ok then return false, "JSONEncode: " .. tostring(encoded) end
    local ok2, err = pcall(writefile, path, encoded)
    if not ok2 then return false, "writefile: " .. tostring(err) end
    return true
end

-- ==================== TIME ====================
local function nowUnix()
    local ok, dt = pcall(function() return DateTime.now().UnixTimestamp end)
    if ok and dt then return dt end
    return os.time()
end

-- ==================== UTILS ====================
local function splitLines(text)
    local out = {}
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        table.insert(out, line)
    end
    if #out > 0 and out[#out] == "" then table.remove(out) end
    return out
end

local function hashBytes(str)
    local hash = 2166136261
    for i = 1, #str do
        hash = bit32.bxor(hash, string.byte(str, i))
        hash = (hash * 16777619) % 4294967296
    end
    return string.format("%08x", hash)
end

local function isUnderPlayer(obj)
    local current = obj
    while current and current ~= game do
        if current:IsA("Player") then return true end
        if current.Parent == workspace and current:IsA("Model") then
            if Players:GetPlayerFromCharacter(current) then return true end
        end
        current = current.Parent
    end
    return false
end

local function isIgnored(obj)
    if IgnoreClasses[obj.ClassName] then return true end

    local current = obj
    while current and current ~= game do
        if current:IsA("Player") then return true end
        current = current.Parent
    end

    local chain = {}
    local cur = obj
    while cur and cur ~= game do
        table.insert(chain, 1, cur.Name)
        cur = cur.Parent
    end
    local path = table.concat(chain, "/")
    for _, p in ipairs(IgnorePrefixes) do
        if path == p or path:sub(1, #p + 1) == p .. "/" then
            return true
        end
    end

    if isUnderPlayer(obj) then return true end
    return false
end

local function cleanSource(src)
    local lines = splitLines(src)
    local out, started = {}, false
    for _, line in ipairs(lines) do
        if not started then
            if line:match("^%-%-%s*Script path:") or
               line:match("^%-%-%s*Decompile time:") or
               line == "" then
            else
                started = true
            end
        end
        if started then
            line = line:gsub("%s*%-%-%s*Line:%s*%d+%s*$", "")
            table.insert(out, line)
        end
    end
    return table.concat(out, "\n")
end

-- ==================== SCAN ====================
local function makePathBuilder()
    local cache = {}
    return function(obj)
        if cache[obj] then return cache[obj] end
        local chain = {}
        local cur = obj
        while cur and cur ~= game and not cache[cur] do
            table.insert(chain, 1, cur)
            cur = cur.Parent
        end
        local base = cur and cache[cur] or ""
        for _, o in ipairs(chain) do
            base = (base == "" and o.Name) or (base .. "/" .. o.Name)
            cache[o] = base
        end
        return cache[obj]
    end
end

local function scanAll()
    local instances = {}
    local scripts   = {}
    local objects   = {}
    local getPath   = makePathBuilder()

    local total, scriptCount, decompiled, failed = 0, 0, 0, 0
    local t0 = tick()
    local decompileElapsed = 0

    for _, obj in ipairs(game:GetDescendants()) do
        if not isIgnored(obj) then
            local path = getPath(obj)
            instances[path] = obj.ClassName
            total = total + 1

            if obj:IsA("LuaSourceContainer") then
                scriptCount = scriptCount + 1
                objects[path] = obj

                local t1 = tick()
                local ok2, src = pcall(decompile, obj)
                decompileElapsed = decompileElapsed + (tick() - t1)

                if ok2 and type(src) == "string" and #src > 0 then
                    local cleaned = cleanSource(src)
                    scripts[path] = {
                        hash   = hashBytes(cleaned),
                        source = cleaned,
                    }
                    decompiled = decompiled + 1
                else
                    local ok, bc = pcall(getscriptbytecode, obj)
                    if ok and type(bc) == "string" and #bc > 0 then
                        scripts[path] = { hash = "bc:" .. hashBytes(bc) }
                    end
                    failed = failed + 1
                end
            end
        end
    end

    return instances, scripts, objects, {
        total = total, scripts = scriptCount,
        decompiled = decompiled, failed = failed,
        elapsed = tick() - t0,
        decompileElapsed = decompileElapsed,
    }
end

-- ==================== DIFF ====================
local function lineDiff(oldText, newText)
    local a, b = splitLines(oldText), splitLines(newText)
    local n, m = #a, #b
    if n * m > 25_000_000 then return nil end

    local dp = {}
    for i = 0, n do
        dp[i] = {}
        for j = 0, m do dp[i][j] = 0 end
    end
    for i = 1, n do
        for j = 1, m do
            if a[i] == b[j] then
                dp[i][j] = dp[i-1][j-1] + 1
            else
                dp[i][j] = math.max(dp[i-1][j], dp[i][j-1])
            end
        end
    end

    local ops = {}
    local i, j = n, m
    while i > 0 and j > 0 do
        if a[i] == b[j] then
            table.insert(ops, 1, { t = "same", s = a[i] })
            i, j = i - 1, j - 1
        elseif dp[i-1][j] >= dp[i][j-1] then
            table.insert(ops, 1, { t = "removed", s = a[i] })
            i = i - 1
        else
            table.insert(ops, 1, { t = "added", s = b[j] })
            j = j - 1
        end
    end
    while i > 0 do table.insert(ops, 1, { t = "removed", s = a[i] }); i = i - 1 end
    while j > 0 do table.insert(ops, 1, { t = "added",   s = b[j] }); j = j - 1 end
    return ops
end

local function formatDiff(ops, budget)
    if not ops then return "  (diff too large)" end

    local included = {}
    local hasAnyDiff = false
    for idx, op in ipairs(ops) do
        if op.t ~= "same" then
            hasAnyDiff = true
            for k = math.max(1, idx - CONTEXT_LINES),
                    math.min(#ops, idx + CONTEXT_LINES) do
                included[k] = true
            end
        end
    end

    if not hasAnyDiff then
        return "  (no textual changes)"
    end

    local out, totalLen = {}, 0
    local prevShown = nil
    local oldNo, newNo = 0, 0

    for idx, op in ipairs(ops) do
        if op.t == "same" then
            oldNo = oldNo + 1; newNo = newNo + 1
        elseif op.t == "removed" then
            oldNo = oldNo + 1
        elseif op.t == "added" then
            newNo = newNo + 1
        end

        if included[idx] then
            if prevShown and idx > prevShown + 1 then
                table.insert(out, "  ...")
            end
            local prefix, shownNo
            if op.t == "added" then prefix, shownNo = "+ ", newNo
            elseif op.t == "removed" then prefix, shownNo = "- ", oldNo
            else prefix, shownNo = "  ", newNo end
            local line = string.format("%s%d: %s", prefix, shownNo, op.s)
            if totalLen + #line > (budget or 3000) then
                table.insert(out, "... (truncated)")
                break
            end
            table.insert(out, line)
            totalLen = totalLen + #line + 1
            prevShown = idx
        end
    end
    return table.concat(out, "\n")
end

-- ==================== GROUPING ====================
local function groupByRoot(paths, classLookup)
    if #paths == 0 then return {} end

    local pathSet = {}
    for _, p in ipairs(paths) do pathSet[p] = true end

    local function parentPath(p) return p:match("^(.*)/[^/]+$") end

    local roots, rootOrder = {}, {}

    for _, p in ipairs(paths) do
        local cur = p
        while true do
            local parent = parentPath(cur)
            if not parent or not pathSet[parent] then break end
            cur = parent
        end
        if not roots[cur] then
            roots[cur] = { count = 0, classes = {} }
            table.insert(rootOrder, cur)
        end
        roots[cur].count = roots[cur].count + 1
        local cls = classLookup[p] or "Instance"
        roots[cur].classes[cls] = (roots[cur].classes[cls] or 0) + 1
    end

    table.sort(rootOrder)

    local lines = {}
    for _, root in ipairs(rootOrder) do
        local info = roots[root]
        if info.count == 1 then
            table.insert(lines, root .. "  (" .. (classLookup[root] or "Instance") .. ")")
        else
            local classList = {}
            for cls, cnt in pairs(info.classes) do
                table.insert(classList, cnt .. " " .. cls)
            end
            table.sort(classList)
            table.insert(lines, root .. "  (" .. table.concat(classList, ", ") .. ")")
        end
    end
    return lines
end

-- ==================== METADATA ====================
local function collectMetadata(instCount, scriptCount)
    local meta = {
        placeVersion = game.PlaceVersion,
        jobId        = game.JobId,
        instCount    = instCount,
        scriptCount  = scriptCount,
        lastUpdate   = nil,
        gameName     = "Place " .. game.PlaceId,
    }

    pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        if info then
            if info.Name then meta.gameName = info.Name end
            if info.Updated then
                local ok, dt = pcall(function()
                    return DateTime.fromIsoDate(info.Updated)
                end)
                if ok and dt then meta.lastUpdate = dt.UnixTimestamp end
            end
        end
    end)

    return meta
end

-- ==================== WEBHOOK ====================
local function sendWebhookOnce(content, description, meta, timings)
    local config = loadJSON(CONFIG_FILE)
    if not config.webhook or config.webhook == "" then
        return false, "webhook is not set", false
    end

    local fields = {
        { name = "Place Version", value = "`" .. tostring(meta.placeVersion) .. "`", inline = true },
        { name = "Instances",     value = "`" .. tostring(meta.instCount)    .. "`", inline = true },
        { name = "Scripts",       value = "`" .. tostring(meta.scriptCount)  .. "`", inline = true },
        { name = "Job ID",        value = "`" .. tostring(meta.jobId):sub(1, 12) .. "`", inline = true },
    }

    if meta.lastUpdate then
        table.insert(fields, {
            name   = "Last Game Update",
            value  = "<t:" .. meta.lastUpdate .. ":R>",
            inline = true
        })
    end

    if timings then
        table.insert(fields, {
            name   = "Timings",
            value  = ("`scan %.2fs / decompile %.2fs / save %.2fs`")
                     :format(timings.scan, timings.decompile, timings.save),
            inline = false
        })
    end

    local payload = {
        content  = content,
        username = config.username or "https",
        embeds   = {{
            description = "```diff\n" .. description .. "\n```",
            color       = config.color or 2829617,
            fields      = fields,
            footer      = { text = "By ThunderStorm" }
        }}
    }

    local ok, result = pcall(function()
        return request({
            Url     = config.webhook,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = HttpService:JSONEncode(payload)
        })
    end)

    if not ok then
        return false, tostring(result), false
    end

    -- Try to detect rate limit / server error for retry decision
    local retryable = false
    if type(result) == "table" then
        local code = result.StatusCode or result.status or result.Status
        if code == 429 or (code and code >= 500) then
            retryable = true
        end
    elseif type(result) == "number" then
        if result == 429 or result >= 500 then retryable = true end
    end

    return true, nil, retryable
end

local function sendWebhook(content, description, meta, timings)
    local maxAttempts = 3
    local lastErr
    for attempt = 1, maxAttempts do
        local ok, err, retryable = sendWebhookOnce(content, description, meta, timings)
        if ok then return true end
        lastErr = err
        if not retryable or attempt == maxAttempts then
            return false, err
        end
        task.wait(2)
    end
    return false, lastErr
end

-- ==================== MAIN ====================
local function runMain()
    local ok, err = pcall(function()

        local config        = loadJSON(CONFIG_FILE)
        local sendNoChanges = (config.send_no_changes == 1)

        local placeId      = tostring(game.PlaceId)
        local snapshotFile = SOURCE_DIR .. "/saved_" .. placeId .. ".json"

        local places = loadJSON(PLACES_FILE)
        if not places[placeId] then
            places[placeId] = "saved_" .. placeId .. ".json"
            saveJSON(PLACES_FILE, places)
            print("[https] New placeId: " .. placeId)
        end

        print("[https] Scanning...")
        local newInst, newScripts, objects, stats = scanAll()
        print(("[https] Total: %d instances, %d scripts (decompiled %d, failed %d), %.2fs (decompile %.2fs)")
            :format(stats.total, stats.scripts, stats.decompiled, stats.failed,
                    stats.elapsed, stats.decompileElapsed))

        local meta = collectMetadata(stats.total, stats.scripts)

        -- ===== FIRST RUN =====
        if not isfile(snapshotFile) then
            local t0 = tick()
            local savedOK, saveErr = saveJSON(snapshotFile, {
                placeName = meta.gameName,
                timestamp = nowUnix(),
                instances = newInst,
                scripts   = newScripts,
            })
            local saveElapsed = tick() - t0

            local timings = {
                scan      = stats.elapsed,
                decompile = stats.decompileElapsed,
                save      = saveElapsed,
            }

            local msg = ("First run completed.\n\n" ..
                         "Instances: %d\n" ..
                         "Scripts: %d\n" ..
                         "Decompiled: %d\n" ..
                         "Failed: %d\n\n" ..
                         "Timings:\n" ..
                         "  scan %.2fs\n" ..
                         "  decompile %.2fs\n" ..
                         "  save %.2fs\n\n" ..
                         "Snapshot saved. Webhook not sent.\n\n" ..
                         "By ThunderStorm")
                :format(stats.total, stats.scripts, stats.decompiled, stats.failed,
                        timings.scan, timings.decompile, timings.save)

            if not savedOK then
                msg = msg .. "\n\nSave error: " .. tostring(saveErr)
                notify("Error", "https", msg)
            else
                notify("Warning", "https", msg)
            end
            return
        end

        -- ===== COMPARE =====
        local oldSnap    = loadJSON(snapshotFile)
        local oldInst    = oldSnap.instances or {}
        local oldScripts = oldSnap.scripts   or {}

        local addedInst, removedInst = {}, {}
        for path in pairs(newInst) do
            if not oldInst[path] then table.insert(addedInst, path) end
        end
        for path in pairs(oldInst) do
            if not newInst[path] then table.insert(removedInst, path) end
        end

        local changedScripts = {}
        for path, data in pairs(newScripts) do
            local old = oldScripts[path]
            if old then
                local oldIsBC = old.hash:sub(1, 3) == "bc:"
                local newIsBC = data.hash:sub(1, 3) == "bc:"
                if oldIsBC ~= newIsBC then
                    -- format mismatch (decompile state changed) — silently update
                elseif old.hash ~= data.hash then
                    table.insert(changedScripts, path)
                end
            end
        end

        local hasChanges = (#addedInst + #removedInst + #changedScripts) > 0
        print(("[https] +%d inst / -%d inst / ~%d scripts")
            :format(#addedInst, #removedInst, #changedScripts))

        if DEBUG_PATHS then
            local show = math.min(#addedInst, 20)
            for i = 1, show do print("   + " .. addedInst[i]) end
            if #addedInst > show then print("   + ... (" .. (#addedInst - show) .. " more)") end

            show = math.min(#removedInst, 20)
            for i = 1, show do print("   - " .. removedInst[i]) end
            if #removedInst > show then print("   - ... (" .. (#removedInst - show) .. " more)") end

            for _, p in ipairs(changedScripts) do print("   ~ " .. p) end
        end

        -- ===== NO CHANGES =====
        if not hasChanges then
            local t0 = tick()
            local savedOK, saveErr = saveJSON(snapshotFile, {
                placeName = meta.gameName,
                timestamp = nowUnix(),
                instances = newInst,
                scripts   = oldScripts
            })
            local saveElapsed = tick() - t0

            if not sendNoChanges then
                notify("Warning", "https",
                    ("No changes detected.\n\n" ..
                     "Timings:\n  scan %.2fs\n  decompile %.2fs\n  save %.2fs\n\n" ..
                     "Webhook not sent.\n\nBy ThunderStorm")
                    :format(stats.elapsed, stats.decompileElapsed, saveElapsed))
                return
            end

            local timings = {
                scan      = stats.elapsed,
                decompile = stats.decompileElapsed,
                save      = saveElapsed,
            }

            local content = ("Log to **%s** · <t:%d:R>"):format(meta.gameName, nowUnix())
            local desc    = "No changes detected since last snapshot."
            local webhookOK, webhookErr = sendWebhook(content, desc, meta, timings)

            if webhookOK then
                notify("Warning", "https",
                    ("No changes detected.\nWebhook was sent.\n\n" ..
                     "Timings:\n  scan %.2fs\n  decompile %.2fs\n  save %.2fs\n\nBy ThunderStorm")
                    :format(timings.scan, timings.decompile, timings.save))
            else
                notify("Error", "https",
                    "Webhook failed:\n\n" .. tostring(webhookErr) .. "\n\nBy ThunderStorm")
            end
            return
        end

        -- ===== HAS CHANGES =====
        table.sort(addedInst)
        table.sort(removedInst)
        table.sort(changedScripts)

        local addedLines   = groupByRoot(addedInst, newInst)
        local removedLines = groupByRoot(removedInst, oldInst)

        local parts = {}
        local used = 0

        table.insert(parts, "# INSTANCE CHANGES")
        for _, line in ipairs(addedLines) do
            local l = "+ [NEW] " .. line
            if used + #l > MAX_LIST_LEN then
                table.insert(parts, "+ ... (truncated)"); break
            end
            table.insert(parts, l); used = used + #l + 1
        end
        used = 0
        for _, line in ipairs(removedLines) do
            local l = "- [DEL] " .. line
            if used + #l > MAX_LIST_LEN then
                table.insert(parts, "- ... (truncated)"); break
            end
            table.insert(parts, l); used = used + #l + 1
        end

        if #changedScripts > 0 then
            table.insert(parts, "")
            table.insert(parts, "# SCRIPT CHANGES")
            for _, path in ipairs(changedScripts) do
                local oldData = oldScripts[path]
                local oldSrc  = oldData and oldData.source
                local newData = newScripts[path]
                local newSrc  = newData and newData.source

                table.insert(parts, "")
                table.insert(parts, "=== " .. path .. " ===")

                if oldSrc and newSrc then
                    local ops = lineDiff(oldSrc, newSrc)
                    if ops then
                        local hasDiff = false
                        for _, op in ipairs(ops) do
                            if op.t ~= "same" then hasDiff = true break end
                        end
                        if hasDiff then
                            table.insert(parts, formatDiff(ops, 1200))
                        else
                            table.insert(parts,
                                ("  (no textual changes; source len %d -> %d)")
                                :format(#oldSrc, #newSrc))
                        end
                    else
                        table.insert(parts, "  (diff too large)")
                    end
                elseif newSrc then
                    table.insert(parts, "  (no previous source to diff)")
                elseif oldSrc then
                    table.insert(parts, "  (no current source to diff)")
                else
                    table.insert(parts, "  (no source available)")
                end
            end
        end

        local description = table.concat(parts, "\n")
        if #description > MAX_DESC_LEN then
            description = description:sub(1, MAX_DESC_LEN) .. "\n... (truncated)"
        end

        -- ===== SAVE SNAPSHOT =====
        local t0 = tick()
        local savedOK, saveErr = saveJSON(snapshotFile, {
            placeName = meta.gameName,
            timestamp = nowUnix(),
            instances = newInst,
            scripts   = newScripts
        })
        local saveElapsed = tick() - t0

        local timings = {
            scan      = stats.elapsed,
            decompile = stats.decompileElapsed,
            save      = saveElapsed,
        }

        local content = ("Log to **%s** · <t:%d:R>"):format(meta.gameName, nowUnix())
        local webhookOK, webhookErr = sendWebhook(content, description, meta, timings)

        local lines = {}
        table.insert(lines, ("+ %d instances added"):format(#addedInst))
        table.insert(lines, ("- %d instances removed"):format(#removedInst))
        table.insert(lines, ("~ %d scripts changed"):format(#changedScripts))
        table.insert(lines, "")
        table.insert(lines, "Snapshot saved: " .. (savedOK and "yes" or "no"))
        table.insert(lines, "Webhook sent: " .. (webhookOK and "yes" or "no"))
        table.insert(lines, "")
        table.insert(lines, ("Timings: scan %.2fs, decompile %.2fs, save %.2fs")
            :format(timings.scan, timings.decompile, timings.save))
        table.insert(lines, "")
        table.insert(lines, "By ThunderStorm")

        if not webhookOK then
            table.insert(lines, "")
            table.insert(lines, "Webhook error: " .. tostring(webhookErr))
            notify("Error", "https", table.concat(lines, "\n"))
        elseif not savedOK then
            table.insert(lines, "")
            table.insert(lines, "Save error: " .. tostring(saveErr))
            notify("Error", "https", table.concat(lines, "\n"))
        else
            notify("Warning", "https", table.concat(lines, "\n"))
        end
    end)

    if not ok then
        notify("Error", "https",
            "Script crashed:\n\n" .. tostring(err) .. "\n\nBy ThunderStorm")
        warn("[https] Fatal: " .. tostring(err))
    end
end

-- ==================== BOOT ====================
local function boot()
    local config = loadJSON(CONFIG_FILE)

    if config.send_no_changes == nil then
        showCentered({
            Text              = "https",
            Description       = "Send webhook even when no changes?\n\n" ..
                                "Yes = always send\n" ..
                                "No = only when changed\n\n" ..
                                "This is asked once. Change later in config.json.\n\n" ..
                                "By ThunderStorm",
            MessageBoxIcon    = "Question",
            MessageBoxButtons = "YesNo",
            Result = function(res)
                config.send_no_changes = (res == "Yes") and 1 or 0
                saveJSON(CONFIG_FILE, config)
                print("[https] send_no_changes = " .. config.send_no_changes)
                task.spawn(runMain)
            end
        })
    else
        task.spawn(runMain)
    end
end

boot()
