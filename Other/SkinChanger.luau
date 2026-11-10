local CONFIG = {
    Debug = true,
    RefreshData = false,
    Blocked = {
        {"nik", "scythe"},
        {"bronze"},
        {"gold"},
        {"silver"},
        {"red hallow"},
        {"red raygun"},
        {"red traveler"},
        {"red seer"},
        {"blue elite"},
        {"blue seer"},
        {"yellow seer"},
    },
    GripOverrides = {
        Harvester = CFrame.fromMatrix(Vector3.new(0, -0.35, 0.55), Vector3.new(0, 0, -1), Vector3.new(0, 1, 0), Vector3.new(1, 0, 0)),
        Gingerscope = CFrame.fromMatrix(Vector3.new(0, -0.55, 0.80), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1)),
        Icepiercer = CFrame.fromMatrix(Vector3.new(0, -0.50, 0.70), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1)),
        Evergun = CFrame.fromMatrix(Vector3.new(0, -0.45, 0.65), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1)),
        ["Chroma Evergun"] = CFrame.fromMatrix(Vector3.new(0, -0.45, 0.65), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1)),
        ["Traveler's Gun"] = CFrame.fromMatrix(Vector3.new(0, -0.50, 0.70), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1)),
        ["Chroma Traveler's Gun"] = CFrame.fromMatrix(Vector3.new(0, -0.50, 0.70), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1)),
        Raygun = CFrame.fromMatrix(Vector3.new(0, -0.40, 0.60), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1)),
        ["Chroma Raygun"] = CFrame.fromMatrix(Vector3.new(0, -0.40, 0.60), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1)),
        ["Chroma Evergreen"] = CFrame.fromMatrix(Vector3.new(0, -0.8, 0.1), Vector3.new(1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, -1, 0)),
        Evergreen = CFrame.fromMatrix(Vector3.new(0, -0.8, 0.1), Vector3.new(1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, -1, 0)),
        Gingerscythe = CFrame.fromMatrix(Vector3.new(0, -0.7, 0.2), Vector3.new(1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, -1, 0)),
    },
    UseDataGrip = false,
    ChromaSpeed = 0.18,
}

if CONFIG.RefreshData or not isfile("mm2data.lua") then
    local result = request({
        Url = "https://raw.githubusercontent.com/Lutosys/opensrc/refs/heads/main/mm2meshes.lua",
        Method = "GET",
    })
    if result and result.Success then
        writefile("mm2data.lua", result.Body)
    end
end

local chunk = loadfile("mm2data.lua")
local data = chunk and chunk()
if not data then
    return warn("[skin] failed to load data")
end

local genv = (getgenv and getgenv()) or _G
local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function log(...)
    if CONFIG.Debug then
        print("[skin]", ...)
    end
end

local function trim(s)
    return (tostring(s):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function assetId(s)
    if type(s) ~= "string" then return nil end
    return s:match("%d+")
end

local function sameAsset(a, b)
    return assetId(a) == assetId(b)
end

local function isBlocked(name, w)
    local itemName = (type(w) == "table" and type(w.Meta) == "table" and w.Meta.ItemName) or ""
    local hay = (tostring(name) .. " " .. tostring(itemName)):lower()
    for _, group in ipairs(CONFIG.Blocked) do
        local all = true
        for _, word in ipairs(group) do
            if not hay:find(word, 1, true) then
                all = false
                break
            end
        end
        if all then return true end
    end
    return false
end

local nameToKey = {}
for key, w in pairs(data) do
    nameToKey[key] = key
    if type(w) == "table" and type(w.Meta) == "table" and w.Meta.ItemName then
        nameToKey[w.Meta.ItemName] = key
        nameToKey[w.Meta.ItemName:lower()] = key
    end
end

local templates, pending = {}, {}

local function fetchTemplate(url)
    for attempt = 1, 3 do
        local ok, mp = pcall(function()
            return AssetService:CreateMeshPartAsync(url)
        end)
        if ok and mp then
            templates[url] = mp
            return
        end
        task.wait(0.35 * attempt)
    end
    templates[url] = false
end

local function startFetch(url)
    if templates[url] == nil and not pending[url] then
        pending[url] = true
        task.delay(8, function()
            if templates[url] == nil then
                templates[url] = false
            end
        end)
        task.spawn(fetchTemplate, url)
    end
end

local function peekTemplate(url)
    local c = templates[url]
    if c ~= nil then return c or nil end
    startFetch(url)
    return nil
end

local function getMeshTemplate(url)
    startFetch(url)
    local t0 = os.clock()
    while templates[url] == nil and os.clock() - t0 < 8 do
        task.wait(0.05)
    end
    return templates[url] or nil
end

local function nativeSize(meshId)
    local id = assetId(meshId)
    if not id then return nil end
    local tpl = peekTemplate("rbxassetid://" .. id)
    return tpl and tpl.Size or nil
end

local BASEPART = {
    Part = true, MeshPart = true, UnionOperation = true, WedgePart = true,
    CornerWedgePart = true, TrussPart = true, Seat = true, SpawnLocation = true,
}

local SKIP = {
    Script = true, LocalScript = true, ModuleScript = true,
    RigidConstraint = true, Weld = true, WeldConstraint = true,
    Motor6D = true, ManualWeld = true, Snap = true,
}

local EFFECT = {
    Sound = true, ParticleEmitter = true, Beam = true, Trail = true,
    Fire = true, Smoke = true, Sparkles = true,
    PointLight = true, SpotLight = true, SurfaceLight = true,
    Attachment = true,
}

local function treeFromDisplay(display)
    local root, cur
    for _, item in ipairs(display) do
        local n = {Class = item.Class, Name = item.Name, Props = item.Props or {}, Children = {}}
        if BASEPART[item.Class] then
            if not root then
                root = n
            else
                table.insert(root.Children, n)
            end
            cur = n
        elseif cur then
            table.insert(cur.Children, n)
        end
    end
    return root
end

local function addChildren(d, list)
    for _, c in ipairs(list or {}) do
        local cls, p = c.Class, c.Props or {}
        if cls == "SpecialMesh" then
            if not d.meshid and p.MeshId and trim(p.MeshId) ~= "" then
                d.kind = "special"
                d.meshid = trim(p.MeshId)
                d.textureid = trim(p.TextureId or "")
                d.scale = p.Scale or Vector3.one
                d.offset = p.Offset or Vector3.zero
            end
        elseif cls == "Decal" and (c.Name == "Chroma" or (p.Texture and tostring(p.Texture):lower():find("chroma"))) then
            table.insert(d.decals, {
                Texture = trim(p.Texture or ""),
                Face = p.Face or Enum.NormalId.Front,
                Color = p.Color3,
                Transparency = p.Transparency or 0,
            })
        elseif BASEPART[cls] then
            table.insert(d.extras, c)
        elseif cls == "Attachment" then
            if p.RelCF and (c.Name == "CustomAttachment" or not d.attachCF) then
                d.attachCF = p.RelCF
            end
            table.insert(d.rootItems, c)
        elseif EFFECT[cls] or (not SKIP[cls] and not BASEPART[cls]) then
            table.insert(d.rootItems, c)
        end
    end
end

local function analyze(name, w)
    local tree = w.Model
    if type(tree) ~= "table" then
        tree = type(w.Display) == "table" and treeFromDisplay(w.Display) or nil
    end
    if not tree then return nil end

    local d = {name = name, decals = {}, extras = {}, rootItems = {}}
    d.chroma = (type(w.Meta) == "table" and w.Meta.Chroma) or false

    local root = tree
    local rest = tree.Children
    local containerKids
    if not BASEPART[tree.Class] then
        root = nil
        containerKids = {}
        for _, c in ipairs(tree.Children or {}) do
            if not root and BASEPART[c.Class] then
                root = c
            else
                table.insert(containerKids, c)
            end
        end
        if not root then return nil end
        rest = root.Children
    end

    local rp = root.Props or {}
    d.partSize = rp.Size
    if root.Class == "MeshPart" and rp.MeshId and trim(rp.MeshId) ~= "" then
        d.kind = "meshpart"
        d.meshid = trim(rp.MeshId)
        d.textureid = trim(rp.TextureID or rp.TextureId or "")
    end

    addChildren(d, rest)
    if containerKids then
        addChildren(d, containerKids)
    end

    if not d.meshid and #d.extras == 0 and #d.rootItems == 0 then
        return nil
    end
    d.hideRoot = not d.meshid
    return d
end

local dataCache = {}
local function getWeaponData(name)
    if not name then return nil end
    local key = nameToKey[name] or nameToKey[tostring(name):lower()] or name
    local c = dataCache[key]
    if c ~= nil then return c or nil end

    local w = data[key]
    local d
    if type(w) == "table" and not isBlocked(key, w) then
        local ok, res = pcall(analyze, key, w)
        if ok then d = res end
    end
    dataCache[key] = d or false
    return d
end

local function getScale(d)
    if d.kind == "special" then return d.scale end
    local native = nativeSize(d.meshid)
    if native and d.partSize then
        return d.partSize / native
    end
    return Vector3.one
end

local chromaState = setmetatable({}, {__mode = "k"})
local liveDecals = setmetatable({}, {__mode = "k"})
local enforceSize = setmetatable({}, {__mode = "k"})
local liveSounds = setmetatable({}, {__mode = "k"})

local function clearChroma(part)
    local st = chromaState[part]
    if st then
        for _, dec in ipairs(st.decals) do
            liveDecals[dec] = nil
            pcall(function() dec:Destroy() end)
        end
        chromaState[part] = nil
    end
end

local function syncChroma(part, d)
    if not d then return end
    if #d.decals == 0 and not d.chroma then
        clearChroma(part)
        return
    end

    local st = chromaState[part]
    if st and st.key == d.name then
        local good = true
        for _, dec in ipairs(st.decals) do
            if not dec.Parent or not dec.Parent:IsDescendantOf(part) then
                good = false
                break
            end
        end
        if good then return end
    end

    clearChroma(part)
    for _, child in ipairs(part:GetDescendants()) do
        if child:IsA("Decal") and (child.Name == "Chroma" or child.Name:lower():find("chroma")) then
            child:Destroy()
        end
    end

    local list = {}
    for _, dd in ipairs(d.decals) do
        local dec = Instance.new("Decal")
        dec.Name = "Chroma"
        dec.Texture = dd.Texture
        dec.Face = dd.Face or Enum.NormalId.Front
        dec.Color3 = dd.Color or Color3.new(1, 0, 0)
        dec.Transparency = dd.Transparency or 0
        dec.Parent = part
        liveDecals[dec] = true
        table.insert(list, dec)
    end

    if d.chroma and #list == 0 then
        local dec = Instance.new("Decal")
        dec.Name = "Chroma"
        dec.Texture = "rbxassetid://0"
        dec.Face = Enum.NormalId.Front
        dec.Color3 = Color3.new(1, 0, 0)
        dec.Transparency = 0.99
        dec.Parent = part
        liveDecals[dec] = true
        table.insert(list, dec)
    end

    chromaState[part] = {key = d.name, decals = list}
end

RunService.RenderStepped:Connect(function()
    local hue = (os.clock() * CONFIG.ChromaSpeed) % 1
    local c = Color3.fromHSV(hue, 1, 1)
    for dec in pairs(liveDecals) do
        if dec.Parent then
            dec.Color3 = c
        else
            liveDecals[dec] = nil
        end
    end
    for part, size in pairs(enforceSize) do
        if part.Parent then
            if (part.Size - size).Magnitude > 0.01 then
                part.Size = size
            end
        else
            enforceSize[part] = nil
        end
    end
end)

local mounts = setmetatable({}, {__mode = "k"})
local hidden = setmetatable({}, {__mode = "k"})

local function newMeshPart(meshId)
    local id = assetId(meshId)
    if id then
        local tpl = getMeshTemplate("rbxassetid://" .. id)
        if tpl then return tpl:Clone() end
    end
    local mp = Instance.new("MeshPart")
    pcall(function()
        mp.MeshId = trim(meshId or "")
    end)
    return mp
end

local function buildNode(node, parent, ctx)
    local cls = node.Class
    if SKIP[cls] then return nil end
    local props = node.Props or {}
    local inst
    if cls == "MeshPart" then
        inst = newMeshPart(props.MeshId)
    else
        local ok, i = pcall(Instance.new, cls)
        if not ok or not i then
            ctx.failed[cls] = (ctx.failed[cls] or 0) + 1
            return nil
        end
        inst = i
    end
    pcall(function()
        inst.Name = node.Name or cls
    end)
    for k, v in pairs(props) do
        if k ~= "RelCF" and not (cls == "MeshPart" and k == "MeshId") then
            if type(v) == "string" then v = trim(v) end
            pcall(function()
                inst[k] = v
            end)
        end
    end
    if BASEPART[cls] then
        pcall(function()
            inst.Anchored = false
            inst.CanCollide = false
            inst.CanTouch = false
            inst.CanQuery = false
            inst.Massless = true
        end)
        if cls == "MeshPart" and props.Size then
            enforceSize[inst] = props.Size
        end
        table.insert(ctx.parts, {inst = inst, rel = props.RelCF})
    elseif cls == "Decal" and (node.Name == "Chroma" or (node.Name and node.Name:lower():find("chroma"))) then
        liveDecals[inst] = true
    elseif cls == "Sound" then
        pcall(function()
            if props.SoundId and trim(props.SoundId) ~= "" then
                inst.SoundId = trim(props.SoundId)
            end
            local n = (inst.Name or ""):lower()
            if inst.Looped or n:find("hold") or n:find("idle") or n:find("equip") or n:find("loop") then
                inst.Looped = true
                liveSounds[inst] = true
            end
        end)
    end
    inst.Parent = parent
    for _, child in ipairs(node.Children or {}) do
        buildNode(child, inst, ctx)
    end
    ctx.count = ctx.count + 1
    return inst
end

local function destroyMount(target)
    local m = mounts[target]
    if m then
        m.dead = true
        for _, inst in ipairs(m.items) do
            pcall(function()
                inst:Destroy()
            end)
        end
        mounts[target] = nil
    end
end

local function syncExtras(target, d)
    local m = mounts[target]
    if #d.extras == 0 and #d.rootItems == 0 then
        if m then destroyMount(target) end
        return
    end
    if m and m.name == d.name and (m.building or (m.folder and m.folder.Parent == target)) then
        return
    end
    if m then destroyMount(target) end
    m = {name = d.name, building = true, items = {}}
    mounts[target] = m
    task.spawn(function()
        local ctx = {parts = {}, failed = {}, count = 0}
        local folder = Instance.new("Folder")
        folder.Name = "SkinExtras"
        table.insert(m.items, folder)
        for _, node in ipairs(d.extras) do
            buildNode(node, folder, ctx)
        end
        for _, node in ipairs(d.rootItems) do
            local inst = buildNode(node, target, ctx)
            if inst then
                table.insert(m.items, inst)
            end
        end
        if m.dead then
            for _, inst in ipairs(m.items) do
                pcall(function()
                    inst:Destroy()
                end)
            end
            return
        end
        for _, p in ipairs(ctx.parts) do
            local w = Instance.new("Weld")
            w.Part0 = target
            w.Part1 = p.inst
            w.C0 = p.rel or CFrame.new()
            w.Parent = p.inst
        end
        folder.Parent = target
        m.folder = folder
        m.building = false
        for _, inst in ipairs(m.items) do
            if inst:IsA("Sound") and inst.Looped and not inst.IsPlaying then
                pcall(function()
                    inst:Play()
                end)
            end
        end
    end)
end

local function gripFor(d, meshid)
    if CONFIG.GripOverrides[d.name] then
        return CONFIG.GripOverrides[d.name]
    end
    if type(data[d.name]) == "table" and type(data[d.name].Meta) == "table" then
        local iname = data[d.name].Meta.ItemName
        if iname and CONFIG.GripOverrides[iname] then
            return CONFIG.GripOverrides[iname]
        end
    end
    if CONFIG.UseDataGrip and d.attachCF then
        return d.attachCF
    end
    meshid = meshid or ""
    if meshid:find("79401392") then
        return CFrame.fromMatrix(Vector3.new(0, -0.7, -0.3), Vector3.new(1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, -1, 0))
    elseif meshid:find("6600918074") then
        return CFrame.new(1, -0.36, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)
    end
    return CFrame.fromMatrix(Vector3.new(0, -0.5, 0.7), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1))
end

local function applyWeaponMesh(part, d, weaponType)
    if not d or not part or not part:IsA("BasePart") then return end

    if d.meshid then
        if hidden[part] then
            part.Transparency = 0
            hidden[part] = nil
        end

        if part:IsA("MeshPart") then
            local sp = part:FindFirstChildOfClass("SpecialMesh")
            if sp then sp:Destroy() end

            local size = (d.kind == "meshpart" and d.partSize) or d.partSize or part.Size
            local meshChanged = not sameAsset(part.MeshId, d.meshid)
            local texChanged = not sameAsset(part.TextureID, d.textureid)

            if meshChanged then part.MeshId = d.meshid end
            if texChanged then part.TextureID = d.textureid end
            if meshChanged or (part.Size - size).Magnitude > 0.01 then
                part.Size = size
            end
        else
            local mesh = part:FindFirstChildOfClass("SpecialMesh")
            if not mesh then
                mesh = Instance.new("SpecialMesh")
                mesh.Name = "Mesh"
                mesh.Parent = part
            end
            local meshChanged = not sameAsset(mesh.MeshId, d.meshid)
            if meshChanged then
                mesh.MeshType = Enum.MeshType.FileMesh
                mesh.MeshId = d.meshid
                mesh.Offset = d.offset or Vector3.zero
            end
            if not sameAsset(mesh.TextureId, d.textureid) then
                mesh.TextureId = d.textureid
            end
            local scale = getScale(d)
            if meshChanged or (mesh.Scale - scale).Magnitude > 0.001 then
                mesh.Scale = scale
            end
            if d.partSize and (meshChanged or (part.Size - d.partSize).Magnitude > 0.01) then
                part.Size = d.partSize
            end
        end
    else
        if part.Transparency < 1 then
            part.Transparency = 1
            hidden[part] = true
        end
    end

    syncChroma(part, d)
    syncExtras(part, d)

    if weaponType == "Gun" or weaponType == "Knife" then
        local tool = part:FindFirstAncestorOfClass("Tool")
        if tool then
            local g = gripFor(d, d.meshid)
            if tool.Grip ~= g then
                tool.Grip = g
            end
        end
    end
end

local InventoryModule = require(game.ReplicatedStorage.Modules.InventoryModule)
local ProfileData = require(game.ReplicatedStorage.Modules.ProfileData)
local Sync = require(game.ReplicatedStorage.Database.Sync)

local granted, blockedCount = 0, 0
for name, itemData in pairs(Sync.Weapons) do
    itemData.SortWithinGroup = itemData.SortWithinGroup or 0
    itemData.SortGroup = itemData.SortGroup or nil
    itemData.Name = itemData.Name or itemData.ItemName or name
    itemData.Rarity = itemData.Rarity or "Common"

    if isBlocked(name, data[name] or {Meta = {ItemName = itemData.ItemName or itemData.Name}}) then
        blockedCount = blockedCount + 1
    else
        local d = getWeaponData(name) or getWeaponData(itemData.ItemName) or getWeaponData(itemData.Name)
        if d then
            ProfileData.Weapons.Owned[name] = 1
            granted = granted + 1
        end
    end
end
log(("granted %d weapons, blocked %d"):format(granted, blockedCount))

pcall(function()
    local UpdateInventory = filtergc("table", {Keys = {"UpdateInventory"}}, true).UpdateInventory
    for _, func in pairs(getgc()) do
        if typeof(func) == "function" and islclosure(func) and debug.info(func, "l") == 122 and #debug.getupvalues(func) == 2 then
            UpdateInventory(debug.getupvalue(func, 2), InventoryModule.MyInventory)
        end
    end
end)

local function isMurder()
    local ok, result = pcall(function()
        local char = LocalPlayer.Character
        if char then
            for _, v in pairs(char:GetChildren()) do
                if v:IsA("Tool") and v:GetAttribute("ItemType") == "Knife" then
                    return true
                end
            end
        end
        for _, v in pairs(LocalPlayer.Backpack:GetChildren()) do
            if v:IsA("Tool") and v:GetAttribute("ItemType") == "Knife" then
                return true
            end
        end
        return false
    end)
    return ok and result or false
end

game.Workspace.ChildAdded:Connect(function(ch)
    if ch and ch:IsA("BasePart") and ch.Name == "StuckKnife" then
        local mesh = ch:WaitForChild("Mesh", 5)
        if mesh and isMurder() then
            local knifeName = ProfileData.Weapons.Equipped.Knife
            local d = getWeaponData(knifeName)
            if d and d.meshid then
                mesh.MeshId = d.meshid
                mesh.TextureId = d.textureid
                mesh.Scale = getScale(d)
                syncChroma(ch, d)
                syncExtras(ch, d)
            end
        end
    end
end)

local seenErr = {}
while task.wait() do
    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        if not char then return end

        local knifeName = ProfileData.Weapons.Equipped.Knife
        local gunName = ProfileData.Weapons.Equipped.Gun

        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local itemType = tool:GetAttribute("ItemType")
                local handle = tool:FindFirstChild("Handle")
                if handle then
                    if itemType == "Knife" and knifeName then
                        local d = getWeaponData(knifeName)
                        if d then
                            applyWeaponMesh(handle, d, "Knife")
                        end
                    elseif itemType == "Gun" and gunName then
                        local d = getWeaponData(gunName)
                        if d then
                            applyWeaponMesh(handle, d, "Gun")
                        end
                    end
                end
            end
        end

        local refGun = char:FindFirstChild("DisplayRefGun")
        if refGun and typeof(refGun.Value) == "Instance" and gunName then
            local d = getWeaponData(gunName)
            if d then
                applyWeaponMesh(refGun.Value, d)
            end
        end

        local refKnife = char:FindFirstChild("DisplayRefKnife")
        if refKnife and typeof(refKnife.Value) == "Instance" and knifeName then
            local d = getWeaponData(knifeName)
            if d then
                applyWeaponMesh(refKnife.Value, d)
            end
        end
    end)

    if not ok then
        err = tostring(err)
        if not seenErr[err] then
            seenErr[err] = true
            warn("[skin] " .. err)
        end
    end
end
