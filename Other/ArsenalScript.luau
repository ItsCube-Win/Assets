-- ============================================================
-- Load Obsidian
-- ============================================================
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library     = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

-- ============================================================
-- GAME LOGIC (unchanged 1:1 from Neverlose)
-- ============================================================
local v1 = game:GetService("Players")
local v2 = game:GetService("Workspace")
local v3 = game:GetService("RunService")
local v4 = game:GetService("UserInputService")
local v5 = v1.LocalPlayer
local v6 = v2.CurrentCamera
local v7 = v5:GetMouse()
local v8  = false
local v9  = false
local v10 = nil
local v11 = nil
local v12 = 100
local v13 = {"Head"}
local v14 = 0.065
local v15 = 0.05
local v16 = true
local v17 = false
local v18 = false
local v19 = false
local v20 = 0
local v21 = true
local v22 = Color3.fromRGB(255, 0, 0)
local v23 = Color3.fromRGB(0, 255, 0)
local v24 = false
local v25 = 2

local v26 = Drawing.new("Circle")
v26.Thickness = v25
v26.Radius    = v12
v26.Filled    = false
v26.Color     = v22
v26.Visible   = false

local v32 = false
local v33 = 100
local v34 = "Head"
local v35 = true
local v36 = 0.065
local v37 = true
local v38 = false
local v39 = Color3.fromRGB(0, 255, 0)
local v40 = false
local v41 = 2

local v42 = Drawing.new("Circle")
v42.Thickness = v41
v42.Radius    = v33
v42.Filled    = false
v42.Color     = v39
v42.Visible   = false

local v48 = false
local v49 = 0.03
local v50 = 80
local v51 = 2000
local v52 = true
local v53 = "Head"
local v54 = 0.065
local v55 = true
local v56 = nil
local v57 = false
local v58 = false
local v59 = false
local v60 = Color3.fromRGB(0, 255, 255)
local v61 = false
local v62 = 2

local v63 = Drawing.new("Circle")
v63.Thickness = v62
v63.Radius    = v50
v63.Filled    = false
v63.Color     = v60
v63.Visible   = false

local v69 = false
local v70 = 0
local v71 = {}

local function v72(v137, v138)
    if v71[v138] then v71[v138]:Destroy() end
    local v139 = v137:FindFirstChild("Head") or v137:FindFirstChild("head")
    if not v139 then return end
    local v140 = Instance.new("BoxHandleAdornment")
    v140.Size = Vector3.new(2.2, 2.2, 2.2)
    v140.Adornee = v139
    v140.Color3 = Color3.fromRGB(255, 0, 0)
    v140.Transparency = 1
    v140.AlwaysOnTop = false
    v140.Visible = false
    v140.Parent = v139
    v71[v138] = v140
end
local function v73(v149)
    if v71[v149] then v71[v149]:Destroy() end
end
local function v74(v150, v151)
    v151:WaitForChild("Humanoid")
    task.wait(0.1)
    v72(v151, v150)
    v151.Humanoid.Died:Connect(function() v73(v150) end)
end
for v152, v153 in ipairs(v1:GetPlayers()) do
    if v153 ~= v5 and v153.Character then v74(v153, v153.Character) end
    v153.CharacterAdded:Connect(function(v401) v74(v153, v401) end)
end
v1.PlayerAdded:Connect(function(v154)
    if v154 ~= v5 then
        v154.CharacterAdded:Connect(function(v529) v74(v154, v529) end)
    end
end)

local function v75(v155) return v18 and (v155.Team == v5.Team) end
local function v76(v156, v157, v158)
    if not v158 then return false end
    local v159 = v6.CFrame.Position
    local v160 = (v157.Position - v159).unit * (v157.Position - v159).Magnitude
    local v161 = RaycastParams.new()
    v161.FilterDescendantsInstances = {v5.Character, v156}
    v161.FilterType = Enum.RaycastFilterType.Blacklist
    local v165 = v2:Raycast(v159, v160, v161)
    return v165 and v165.Instance ~= nil
end
local function v77(v166, v167) return v76(v166, v167, v16) end
local function v78(v168, v169) return v76(v168, v169, v52) end
local function v79(v170, v171) return v76(v170, v171, v35) end

local function v80(v172, v173, v174)
    local v175 = v174 or v12
    local v176, v177 = nil, v175
    for _, v403 in ipairs(v173) do
        local v404 = v172:FindFirstChild(v403)
        if v404 then
            local v530 = v6:WorldToViewportPoint(v404.Position)
            local v531 = (Vector2.new(v530.X, v530.Y) - Vector2.new(v7.X, v7.Y)).Magnitude
            if v531 < v177 and v530.Z > 0 then
                v177 = v531; v176 = v404
            end
        end
    end
    return v176
end

local function v81()
    local v178, v179, v180 = nil, nil, v12
    for _, v406 in ipairs(v1:GetPlayers()) do
        if v406 ~= v5 and v406.Character and not v75(v406) then
            local v532 = v406.Character:FindFirstChild("Humanoid")
            if v532 and (not v19 or v532.Health >= v20) then
                local v673 = v80(v406.Character, v13, v12)
                if v673 then
                    local v689 = v6:WorldToViewportPoint(v673.Position)
                    local v690 = (Vector2.new(v689.X, v689.Y) - Vector2.new(v7.X, v7.Y)).Magnitude
                    if v690 < v180 and not v77(v406.Character, v673) then
                        v180 = v690; v178 = v406; v179 = v673
                    end
                end
            end
        end
    end
    return v178, v179
end

local function v82(v181, v182, v183) return v181.Position + (v182 * v183) end
local function v83(v184, v185) return v184:Lerp(v185, v15) end
local function v84(v186, v187)
    local v188 = v186.Character.HumanoidRootPart.Velocity
    local v189 = v82(v187, v188, v14)
    v6.CFrame = v83(v6.CFrame, CFrame.new(v6.CFrame.Position, v189))
end

local function v85()
    local v191, v192, v193 = nil, nil, v33
    for _, v408 in ipairs(v1:GetPlayers()) do
        if v408 ~= v5 and v408.Character and not v75(v408) then
            local v533 = v408.Character:FindFirstChild("Humanoid")
            if v533 and v533.Health > 0 then
                local v674 = v408.Character:FindFirstChild(v34)
                if v674 then
                    local v691 = v6:WorldToViewportPoint(v674.Position)
                    local v692 = (Vector2.new(v691.X, v691.Y) - Vector2.new(v7.X, v7.Y)).Magnitude
                    if v692 < v193 and v691.Z > 0 then
                        if not v37 or not v79(v408.Character, v674) then
                            v193 = v692; v191 = v408; v192 = v674
                        end
                    end
                end
            end
        end
    end
    return v191, v192
end

v4.InputBegan:Connect(function(v194, v195)
    if v195 then return end
    if not v32 then return end
    if v194.UserInputType == Enum.UserInputType.MouseButton1 then
        local v449, v450 = v85()
        if v449 and v450 and v449.Character then
            local v598 = v449.Character.HumanoidRootPart.Velocity
            local v599 = v82(v450, v598, v36)
            local v600 = v6.CFrame
            v6.CFrame = CFrame.new(v6.CFrame.Position, v599)
            task.wait(0.02)
            v6.CFrame = v600
        end
    end
end)

local function v86() mouse1press(); task.wait(0.02); mouse1release() end

local function v87(v196, v197)
    if not v196 or not v196.Character then return false end
    local v198 = v196.Character:FindFirstChild("Humanoid")
    if not v198 or v198.Health <= 0 then return false end
    if not v197 then return false end
    local v199 = (v6.CFrame.Position - v197.Position).Magnitude
    if v199 > v51 then return false end
    if v78(v196.Character, v197) then return false end
    return true
end

local function v88()
    local v200, v201, v202 = nil, nil, (v55 and math.huge) or -math.huge
    for _, v410 in ipairs(v1:GetPlayers()) do
        if v410 ~= v5 and v410.Character and not v75(v410) then
            local v534 = v410.Character:FindFirstChild("Humanoid")
            if v534 and v534.Health > 0 then
                local v675 = v410.Character:FindFirstChild(v53)
                if v675 then
                    local v693 = v6:WorldToViewportPoint(v675.Position)
                    local v694 = (Vector2.new(v693.X, v693.Y) - Vector2.new(v7.X, v7.Y)).Magnitude
                    if v694 <= v50 and v693.Z > 0 then
                        local v695 = (v6.CFrame.Position - v675.Position).Magnitude
                        if v695 <= v51 and not v78(v410.Character, v675) then
                            if v55 then
                                if v695 < v202 then v202 = v695; v200 = v410; v201 = v675 end
                            elseif v694 < v202 then v202 = v694; v200 = v410; v201 = v675 end
                        end
                    end
                end
            end
        end
    end
    return v200, v201
end

local function v89(v203)
    if v57 then
        v58 = true
        while v57 do task.wait() end
    end
    v58 = false; v57 = true
    local v204 = v6.CFrame
    local v205 = v203.Character:FindFirstChild(v53)
    if not v205 then v57 = false; return end
    local v206 = v203.Character.HumanoidRootPart.Velocity
    v6.CFrame = CFrame.new(v6.CFrame.Position, v82(v205, v206, v54))
    while v48 and not v58 and v203 and v203.Character do
        local v411 = v5.Character and v5.Character:FindFirstChildOfClass("Tool")
        if v411 and (v411.Name:lower():find("knife") or v411.Name:lower():find("melee")) then break end
        local v412 = v203.Character:FindFirstChild(v53)
        if not v412 or not v87(v203, v412) then break end
        local v413 = v203.Character.HumanoidRootPart.Velocity
        v6.CFrame = CFrame.new(v6.CFrame.Position, v82(v412, v413, v54))
        v86(); v69 = true; v70 = 0.1
        task.wait(v49)
    end
    v6.CFrame = v204
    v57 = false; v56 = nil
end

v3.RenderStepped:Connect(function()
    if not v48 then
        if v57 then v58 = true end
        v56 = nil; return
    end
    local v208 = v5.Character and v5.Character:FindFirstChildOfClass("Tool")
    if v208 and (v208.Name:lower():find("knife") or v208.Name:lower():find("melee")) then return end
    if v57 then return end
    local v209 = v88()
    if v209 then v56 = v209; task.spawn(function() v89(v209) end) end
end)

v3.RenderStepped:Connect(function()
    if not v48 then v63.Visible = false; return end
    v63.Position = Vector2.new(v7.X, v7.Y + 50)
    v63.Radius = v50; v63.Thickness = v62
    if v61 then v63.Color = Color3.fromHSV(tick() % 1, 1, 1)
    elseif v69 and v70 > 0 then
        v63.Color = Color3.fromRGB(255, 255, 255); v70 = v70 - 0.016
        if v70 <= 0 then v69 = false end
    else v63.Color = v60 end
    v63.Visible = v59
end)

v3.RenderStepped:Connect(function()
    if not v8 then v26.Visible = false; return end
    v26.Position = Vector2.new(v7.X, v7.Y + 50)
    v26.Radius = v12; v26.Thickness = v25
    v26.Visible = v21
    local v219 = v22
    if v10 and v10.Character and v10.Character:FindFirstChild("Humanoid") then v219 = v23 end
    if v24 then v219 = Color3.fromHSV(tick() % 1, 1, 1) end
    v26.Color = v219
    if v9 then
        if v17 and v10 then
            local v604 = v10.Character:FindFirstChild("Head")
            if v604 then
                local v684 = v6:WorldToViewportPoint(v604.Position)
                local v685 = (Vector2.new(v684.X, v684.Y) - Vector2.new(v7.X, v7.Y)).Magnitude
                if v685 > v12 or v77(v10.Character, v604) or v75(v10) then v10 = nil end
            else v10 = nil end
        end
        if not v17 or not v10 then v10, v11 = v81() end
        if v10 and v11 then v84(v10, v11) end
    else v10 = nil end
end)

v3.RenderStepped:Connect(function()
    if not v32 or not v38 then v42.Visible = false; return end
    v42.Position = Vector2.new(v7.X, v7.Y + 50)
    v42.Radius = v33; v42.Thickness = v41
    if v40 then v42.Color = Color3.fromHSV(tick() % 1, 1, 1) else v42.Color = v39 end
    v42.Visible = true
end)

v7.Button2Down:Connect(function() if v8 then v9 = true end end)
v7.Button2Up:Connect(function() v9 = false end)

-- ---- Bhop speed ----
local v90 = false
local v91 = 5
local v92 = 100
local v93 = 50
local v94 = 0.01
local v95 = false
local v96 = {}
local v97 = {currSpeed=16,lastHzSpeed=0,lastDir=Vector3.new(),sliding=false,origProps=nil,slipProps=nil}
local function v98() return 16 end
local function v99()
    v97.currSpeed = v98(); v97.lastHzSpeed = 0; v97.lastDir = Vector3.new()
    v97.sliding = false
end
local function v100()
    if v95 then
        for _, v536 in pairs(v96) do if v536 then v536:Disconnect() end end
        v96 = {}
        local v457 = v5.Character
        if v457 then
            local v607 = v457:FindFirstChild("Humanoid")
            local v608 = v457:FindFirstChild("HumanoidRootPart")
            if v607 then v607.WalkSpeed = v98() end
            if v608 and v97.origProps then v608.CustomPhysicalProperties = v97.origProps end
        end
        v99(); v95 = false
    end
end
local function v101(v229)
    if not v90 or not v229 then return end
    local v230 = v229:FindFirstChild("Humanoid")
    local v231 = v229:FindFirstChild("HumanoidRootPart")
    if not v230 or not v231 then return end
    v97.origProps = v231.CustomPhysicalProperties or PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1)
    v97.slipProps = PhysicalProperties.new(v97.origProps.Density, v94, v97.origProps.Elasticity, 100, v97.origProps.ElasticityWeight)
    v99()
    v230.WalkSpeed = v98(); v97.currSpeed = v98()
    v96.Jumping = v230.Jumping:Connect(function()
        if not v90 then return end
        v97.currSpeed = math.min(v97.currSpeed + v91, v92)
        v230.WalkSpeed = v97.currSpeed
        v97.sliding = false
        if v231 then v231.CustomPhysicalProperties = v97.origProps end
    end)
    v96.Died = v230.Died:Connect(function() v100() end)
    v95 = true
end

v3.Heartbeat:Connect(function(v240)
    if not v90 or not v95 then return end
    local v241 = v5.Character
    if not v241 then if v95 then v100() end return end
    local v242 = v241:FindFirstChild("Humanoid")
    local v243 = v241:FindFirstChild("HumanoidRootPart")
    if not v242 or not v243 then if v95 then v100() end return end
    if not v97.origProps then
        v97.origProps = v243.CustomPhysicalProperties or PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1)
        v97.slipProps = PhysicalProperties.new(v97.origProps.Density, v94, v97.origProps.Elasticity, 100, v97.origProps.ElasticityWeight)
    end
    if v242.MoveDirection.Magnitude > 0 then
        v97.lastDir = v242.MoveDirection.Unit
        v97.sliding = false
        v243.CustomPhysicalProperties = v97.origProps
    end
    local v244 = (v243.Velocity * Vector3.new(1, 0, 1)).Magnitude
    if v244 < v97.lastHzSpeed * 0.5 and v97.lastHzSpeed > 16 * 1.5 then
        v97.currSpeed = 16; v242.WalkSpeed = 16; v97.sliding = false
        v243.CustomPhysicalProperties = v97.origProps
    end
    v97.lastHzSpeed = v244
    if v242.MoveDirection.Magnitude == 0 and v97.currSpeed > 16 then
        if not v97.sliding then
            v97.sliding = true
            v243.CustomPhysicalProperties = v97.slipProps
            v243.Velocity = Vector3.new(v97.lastDir.X * v97.currSpeed, v243.Velocity.Y, v97.lastDir.Z * v97.currSpeed)
        end
        v97.currSpeed = math.max(16, v97.currSpeed - v93 * v240)
        v242.WalkSpeed = v97.currSpeed
        local v472 = v243.Velocity * Vector3.new(1, 0, 1)
        if v472.Magnitude > 16 then
            v243.Velocity = Vector3.new(v97.lastDir.X * v97.currSpeed, v243.Velocity.Y, v97.lastDir.Z * v97.currSpeed)
        else
            v97.sliding = false; v243.CustomPhysicalProperties = v97.origProps
            v242.WalkSpeed = 16; v97.currSpeed = 16
        end
    elseif v242.MoveDirection.Magnitude == 0 then
        v97.currSpeed = 16; v242.WalkSpeed = 16
        v97.sliding = false; v243.CustomPhysicalProperties = v97.origProps
    else
        v242.WalkSpeed = v97.currSpeed
    end
end)

v5.CharacterAdded:Connect(function(v246)
    if v90 then v100(); task.wait(0.1); v101(v246) end
end)

-- ---- Auto Bhop ----
local v102 = false
local v103 = 0.1
local v104 = 0
v3.Heartbeat:Connect(function()
    if not v102 then return end
    local v247 = v5.Character
    if not v247 then return end
    local v248 = v247:FindFirstChild("Humanoid")
    if not v248 or v248:GetState() == Enum.HumanoidStateType.Dead then return end
    local v249 = v248.FloorMaterial ~= Enum.Material.Air
    if v249 and v248.MoveDirection.Magnitude > 0 then
        local v473 = tick()
        if v473 - v104 >= v103 then
            v248:ChangeState(Enum.HumanoidStateType.Jumping); v104 = v473
        end
    end
end)

-- ---- ESP ----
local v105 = {ESP={},Tracers={},Boxes={},Healthbars={},Names={},Snaplines={}}
local v106 = {Enemy=Color3.fromRGB(255, 25, 25),Ally=Color3.fromRGB(25, 255, 25),Health=Color3.fromRGB(0, 255, 0),Rainbow=nil}
local v107 = {}
local v108 = {
    Enabled=false,TeamCheck=false,ShowTeam=false,BoxESP=false,BoxStyle="Corner",BoxThickness=1,
    TracerESP=false,TracerOrigin="Bottom",HealthESP=false,HealthStyle="Bar",NameESP=false,
    Snaplines=false,MaxDistance=1000,RainbowEnabled=false,ChamsEnabled=false,
    ChamsFillColor=Color3.fromRGB(255, 0, 0),ChamsOutlineColor=Color3.fromRGB(255, 255, 255),
    ChamsTransparency=0.5,TextSize=14,BoxColor=Color3.fromRGB(255, 25, 25),
    TracerColor=Color3.fromRGB(255, 25, 25),NameColor=Color3.fromRGB(255, 255, 255)
}
local function v109(v250)
    if v108.RainbowEnabled then return v106.Rainbow end
    return (v250.Team == v5.Team and v106.Ally) or v106.Enemy
end
local function v110(v251)
    if v251 == v5 then return end
    local v252 = {TopLeft=Drawing.new("Line"),TopRight=Drawing.new("Line"),BottomLeft=Drawing.new("Line"),
                  BottomRight=Drawing.new("Line"),Left=Drawing.new("Line"),Right=Drawing.new("Line"),
                  Top=Drawing.new("Line"),Bottom=Drawing.new("Line")}
    for _, v419 in pairs(v252) do
        v419.Visible = false; v419.Color = v108.BoxColor; v419.Thickness = v108.BoxThickness
    end
    local v253 = Drawing.new("Line"); v253.Visible = false; v253.Color = v108.TracerColor; v253.Thickness = 1
    local v258 = {Outline=Drawing.new("Square"),Fill=Drawing.new("Square"),Text=Drawing.new("Text")}
    for _, v426 in pairs(v258) do
        v426.Visible = false
        if v426 == v258.Fill then v426.Color = v106.Health; v426.Filled = true
        elseif v426 == v258.Text then v426.Center = true; v426.Size = v108.TextSize; v426.Color = v106.Health end
    end
    local v259 = {Name=Drawing.new("Text")}
    v259.Name.Visible = false; v259.Name.Center = true
    v259.Name.Size = v108.TextSize; v259.Name.Color = v108.NameColor; v259.Name.Outline = true
    local v267 = Drawing.new("Line"); v267.Visible = false; v267.Color = v108.TracerColor; v267.Thickness = 1
    local v271 = Instance.new("Highlight")
    v271.FillColor = v108.ChamsFillColor; v271.OutlineColor = v108.ChamsOutlineColor
    v271.FillTransparency = v108.ChamsTransparency; v271.OutlineTransparency = 0
    v271.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    v271.Enabled = v108.ChamsEnabled
    v107[v251] = v271
    v105.ESP[v251] = {Box=v252,Tracer=v253,HealthBar=v258,Info=v259,Snapline=v267}
end
local function v111(v285)
    local v286 = v105.ESP[v285]
    if v286 then
        for _, v543 in pairs(v286.Box) do v543:Remove() end
        v286.Tracer:Remove()
        for _, v545 in pairs(v286.HealthBar) do v545:Remove() end
        v286.Info.Name:Remove(); v286.Snapline:Remove()
        v105.ESP[v285] = nil
    end
    if v107[v285] then v107[v285]:Destroy(); v107[v285] = nil end
end
local function v112()
    if v108.TracerOrigin == "Bottom" then return Vector2.new(v6.ViewportSize.X / 2, v6.ViewportSize.Y)
    elseif v108.TracerOrigin == "Top" then return Vector2.new(v6.ViewportSize.X / 2, 0)
    elseif v108.TracerOrigin == "Mouse" then return v4:GetMouseLocation()
    else return Vector2.new(v6.ViewportSize.X / 2, v6.ViewportSize.Y / 2) end
end
local function v113(v287)
    if not v108.Enabled then return end
    local v288 = v105.ESP[v287]
    if not v288 then return end
    local function hideAll()
        for _, v547 in pairs(v288.Box) do v547.Visible = false end
        v288.Tracer.Visible = false
        for _, v550 in pairs(v288.HealthBar) do v550.Visible = false end
        v288.Info.Name.Visible = false; v288.Snapline.Visible = false
    end
    local v289 = v287.Character
    if not v289 then hideAll(); return end
    local v290 = v289:FindFirstChild("HumanoidRootPart")
    if not v290 then hideAll(); return end
    local _, v292 = v6:WorldToViewportPoint(v290.Position)
    if not v292 then hideAll(); return end
    local v293 = v289:FindFirstChild("Humanoid")
    if not v293 or v293.Health <= 0 then hideAll(); return end
    local v294 = v6:WorldToViewportPoint(v290.Position)
    local v295 = (v290.Position - v6.CFrame.Position).Magnitude
    if not v292 or v295 > v108.MaxDistance then hideAll(); return end
    if v108.TeamCheck and v287.Team == v5.Team and not v108.ShowTeam then hideAll(); return end

    local v297 = (v108.RainbowEnabled and v106.Rainbow) or v108.BoxColor
    local v298 = (v108.RainbowEnabled and v106.Rainbow) or v108.TracerColor
    local v299 = (v108.RainbowEnabled and v106.Rainbow) or v108.NameColor

    local v300 = v289:GetExtentsSize()
    local v301 = v290.CFrame
    local v302, v303 = v6:WorldToViewportPoint((v301 * CFrame.new(0, v300.Y / 2, 0)).Position)
    local v304, v305 = v6:WorldToViewportPoint((v301 * CFrame.new(0, -v300.Y / 2, 0)).Position)
    if not v303 or not v305 then return end
    local v306 = v304.Y - v302.Y
    local v307 = v306 * 0.65
    local v308 = Vector2.new(v302.X - (v307 / 2), v302.Y)
    local v309 = Vector2.new(v307, v306)
    for _, v429 in pairs(v288.Box) do v429.Visible = false end
    if v108.BoxESP then
        if v108.BoxStyle == "Corner" then
            local v626 = v307 * 0.2
            v288.Box.TopLeft.From = v308
            v288.Box.TopLeft.To = v308 + Vector2.new(v626, 0); v288.Box.TopLeft.Visible = true
            v288.Box.TopRight.From = v308 + Vector2.new(v309.X, 0)
            v288.Box.TopRight.To = v308 + Vector2.new(v309.X - v626, 0); v288.Box.TopRight.Visible = true
            v288.Box.BottomLeft.From = v308 + Vector2.new(0, v309.Y)
            v288.Box.BottomLeft.To = v308 + Vector2.new(v626, v309.Y); v288.Box.BottomLeft.Visible = true
            v288.Box.BottomRight.From = v308 + Vector2.new(v309.X, v309.Y)
            v288.Box.BottomRight.To = v308 + Vector2.new(v309.X - v626, v309.Y); v288.Box.BottomRight.Visible = true
            v288.Box.Left.From = v308
            v288.Box.Left.To = v308 + Vector2.new(0, v626); v288.Box.Left.Visible = true
            v288.Box.Right.From = v308 + Vector2.new(v309.X, 0)
            v288.Box.Right.To = v308 + Vector2.new(v309.X, v626); v288.Box.Right.Visible = true
            v288.Box.Top.From = v308 + Vector2.new(0, v309.Y)
            v288.Box.Top.To = v308 + Vector2.new(0, v309.Y - v626); v288.Box.Top.Visible = true
            v288.Box.Bottom.From = v308 + Vector2.new(v309.X, v309.Y)
            v288.Box.Bottom.To = v308 + Vector2.new(v309.X, v309.Y - v626); v288.Box.Bottom.Visible = true
        else
            v288.Box.Left.From = v308
            v288.Box.Left.To = v308 + Vector2.new(0, v309.Y); v288.Box.Left.Visible = true
            v288.Box.Right.From = v308 + Vector2.new(v309.X, 0)
            v288.Box.Right.To = v308 + Vector2.new(v309.X, v309.Y); v288.Box.Right.Visible = true
            v288.Box.Top.From = v308
            v288.Box.Top.To = v308 + Vector2.new(v309.X, 0); v288.Box.Top.Visible = true
            v288.Box.Bottom.From = v308 + Vector2.new(0, v309.Y)
            v288.Box.Bottom.To = v308 + Vector2.new(v309.X, v309.Y); v288.Box.Bottom.Visible = true
        end
        for _, v583 in pairs(v288.Box) do
            if v583.Visible then v583.Color = v297; v583.Thickness = v108.BoxThickness end
        end
    end
    if v108.TracerESP then
        v288.Tracer.From = v112()
        v288.Tracer.To = Vector2.new(v294.X, v294.Y)
        v288.Tracer.Color = v298; v288.Tracer.Visible = true
    else v288.Tracer.Visible = false end
    if v108.HealthESP then
        local v499 = v293.Health / v293.MaxHealth
        local v500 = v306 * 0.8
        local v501 = 4
        local v502 = Vector2.new((v308.X - v501) - 2, v308.Y + ((v306 - v500) / 2))
        v288.HealthBar.Outline.Size = Vector2.new(v501, v500)
        v288.HealthBar.Outline.Position = v502; v288.HealthBar.Outline.Visible = true
        v288.HealthBar.Fill.Size = Vector2.new(v501 - 2, v500 * v499)
        v288.HealthBar.Fill.Position = Vector2.new(v502.X + 1, v502.Y + (v500 * (1 - v499)))
        v288.HealthBar.Fill.Color = Color3.fromRGB(255 - (255 * v499), 255 * v499, 0)
        v288.HealthBar.Fill.Visible = true
        if v108.HealthStyle == "Both" or v108.HealthStyle == "Text" then
            v288.HealthBar.Text.Text = math.floor(v293.Health)
            v288.HealthBar.Text.Position = Vector2.new(v502.X + v501 + 2, v502.Y + (v500 / 2))
            v288.HealthBar.Text.Visible = true
        else v288.HealthBar.Text.Visible = false end
    else
        for _, v585 in pairs(v288.HealthBar) do v585.Visible = false end
    end
    if v108.NameESP then
        v288.Info.Name.Text = v287.DisplayName
        v288.Info.Name.Position = Vector2.new(v308.X + (v307 / 2), v308.Y - 20)
        v288.Info.Name.Color = v299; v288.Info.Name.Visible = true
    else v288.Info.Name.Visible = false end
    if v108.Snaplines then
        v288.Snapline.From = Vector2.new(v6.ViewportSize.X / 2, v6.ViewportSize.Y)
        v288.Snapline.To = Vector2.new(v294.X, v294.Y)
        v288.Snapline.Color = v298; v288.Snapline.Visible = true
    else v288.Snapline.Visible = false end
    if v107[v287] then
        v107[v287].Enabled = v108.ChamsEnabled
        v107[v287].Parent = v289
        v107[v287].FillColor = v108.ChamsFillColor
        v107[v287].OutlineColor = v108.ChamsOutlineColor
    end
end
local function v114()
    for _, v432 in ipairs(v1:GetPlayers()) do
        local v433 = v105.ESP[v432]
        if v433 then
            for _, v668 in pairs(v433.Box) do v668.Visible = false end
            v433.Tracer.Visible = false
            for _, v671 in pairs(v433.HealthBar) do v671.Visible = false end
            v433.Info.Name.Visible = false; v433.Snapline.Visible = false
        end
    end
end
v1.PlayerAdded:Connect(v110)
v1.PlayerRemoving:Connect(v111)
for _, v311 in ipairs(v1:GetPlayers()) do
    if v311 ~= v5 then v110(v311) end
end

-- ============================================================
-- OBSIDIAN UI  (ported from Neverlose)
-- ============================================================
local Window = Library:CreateWindow({
    Title        = "Neverlose",
    Footer       = "Arsenal",
    NotifySide   = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Aimbot  = Window:AddTab("Aimbot", "crosshair"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Misc    = Window:AddTab("Misc", "wrench"),
    About   = Window:AddTab("About", "info"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

-- Helper: notifications (replaces v119 indicator)
local function Notify(title, desc, time)
    Library:Notify({ Title = title, Description = desc or "", Time = time or 2 })
end

Notify("Arsenal Ready", "Neverlose loaded successfully", 3)

-- ============================================================
-- AIMBOT TAB
-- ============================================================
local AimbotGroup = Tabs.Aimbot:AddGroupbox({ Side = "Left",  Name = "Aimbot",     IconName = "crosshair" })
local SilentGroup = Tabs.Aimbot:AddGroupbox({ Side = "Right", Name = "Silent Aim", IconName = "focus" })
local AutoFireGroup = Tabs.Aimbot:AddGroupbox({ Side = "Right", Name = "Auto Fire", IconName = "zap" })

-- ---- Aimbot ----
AimbotGroup:AddToggle("AimbotEnabled", {
    Text = "Aimbot Enabled",
    Default = false,
    Callback = function(Value)
        v8 = Value
        if not Value then v9 = false end
        Notify("Aimbot", Value and "ON" or "OFF", 2)
    end,
})
AimbotGroup:AddDropdown("AimParts", {
    Values = {"Head","HumanoidRootPart","Left Arm","Right Arm","Torso","Left Leg","Right Leg"},
    Default = "Head",
    Multi = true,
    Text = "Aim Part",
    Callback = function(Value)
        local parts = {}
        for k, v in pairs(Value) do if v then table.insert(parts, k) end end
        if #parts == 0 then parts = {"Head"} end
        v13 = parts
    end,
})
AimbotGroup:AddSlider("Smoothing", {
    Text = "Smooth", Default = 5, Min = 0, Max = 100, Rounding = 0,
    Callback = function(Value) v15 = 1 - (Value / 100) end,
})
v15 = 1 - (5 / 100) -- sync with default slider value

AimbotGroup:AddSlider("Prediction", {
    Text = "Prediction", Default = 65, Min = 0, Max = 200, Rounding = 1,
    Callback = function(Value) v14 = Value / 1000 end,
})
AimbotGroup:AddSlider("FOV", {
    Text = "Aimbot FOV", Default = 100, Min = 0, Max = 500, Rounding = 0,
    Callback = function(Value) v12 = Value; v26.Radius = Value end,
})
AimbotGroup:AddToggle("FOVVisible", {
    Text = "Show FOV Circle", Default = true,
    Callback = function(Value) v21 = Value; v26.Visible = Value and v8 end,
})
AimbotGroup:AddLabel("FOV Color"):AddColorPicker("FOVColorDefault", {
    Default = v22, Title = "FOV Color",
    Callback = function(Value) v22 = Value end,
})
AimbotGroup:AddLabel("FOV Target Color"):AddColorPicker("FOVColorTarget", {
    Default = v23, Title = "FOV Target Color",
    Callback = function(Value) v23 = Value end,
})
AimbotGroup:AddToggle("FOVRainbow", {
    Text = "FOV Rainbow", Default = false,
    Callback = function(Value) v24 = Value end,
})
AimbotGroup:AddSlider("FOVThickness", {
    Text = "FOV Thickness", Default = 2, Min = 1, Max = 10, Rounding = 0,
    Callback = function(Value) v25 = Value end,
})
AimbotGroup:AddToggle("WallCheck", {
    Text = "Wall Check", Default = true,
    Callback = function(Value) v16 = Value end,
})
AimbotGroup:AddToggle("StickyAim", {
    Text = "Sticky Aim", Default = false,
    Callback = function(Value) v17 = Value end,
})
AimbotGroup:AddToggle("TeamCheck", {
    Text = "Team Check", Default = false,
    Callback = function(Value) v18 = Value end,
})
AimbotGroup:AddToggle("HealthCheck", {
    Text = "Health Check", Default = false,
    Callback = function(Value) v19 = Value end,
})
AimbotGroup:AddSlider("MinHealth", {
    Text = "Min Health", Default = 0, Min = 0, Max = 100, Rounding = 0,
    Callback = function(Value) v20 = Value end,
})

-- ---- Silent Aim ----
SilentGroup:AddToggle("SilentAimEnabled", {
    Text = "Enable Silent Aim", Default = false,
    Callback = function(Value) v32 = Value end,
})
SilentGroup:AddSlider("SilentAimFOV", {
    Text = "Silent Aim FOV", Default = 100, Min = 10, Max = 500, Rounding = 0,
    Callback = function(Value) v33 = Value; v42.Radius = Value end,
})
SilentGroup:AddDropdown("SilentAimPart", {
    Values = {"Head","HumanoidRootPart","Torso"},
    Default = "Head", Multi = false, Text = "Silent Aim Part",
    Callback = function(Value) v34 = Value end,
})
SilentGroup:AddToggle("SilentWallCheck", {
    Text = "Wall Check", Default = true,
    Callback = function(Value) v35 = Value end,
})
SilentGroup:AddSlider("SilentPrediction", {
    Text = "Prediction", Default = 65, Min = 0, Max = 200, Rounding = 1,
    Callback = function(Value) v36 = Value / 1000 end,
})
SilentGroup:AddToggle("SilentVisibilityCheck", {
    Text = "Visibility Check", Default = true,
    Callback = function(Value) v37 = Value end,
})
SilentGroup:AddToggle("SilentFOVVisible", {
    Text = "Show FOV Circle", Default = false,
    Callback = function(Value) v38 = Value end,
})
SilentGroup:AddLabel("FOV Color"):AddColorPicker("SilentFOVColor", {
    Default = v39, Title = "Silent FOV Color",
    Callback = function(Value) v39 = Value end,
})
SilentGroup:AddToggle("SilentFOVRainbow", {
    Text = "FOV Rainbow", Default = false,
    Callback = function(Value) v40 = Value end,
})
SilentGroup:AddSlider("SilentFOVThickness", {
    Text = "FOV Thickness", Default = 2, Min = 1, Max = 10, Rounding = 0,
    Callback = function(Value) v41 = Value end,
})

-- ---- Auto Fire ----
AutoFireGroup:AddToggle("AutoFireEnabled", {
    Text = "Enable Auto Fire", Default = false,
    Callback = function(Value)
        v48 = Value
        if not Value and v57 then v58 = true end
    end,
})
AutoFireGroup:AddSlider("AutoFireShootDelay", {
    Text = "Shoot Delay (s)", Default = 0.03, Min = 0.01, Max = 0.2, Rounding = 3,
    Callback = function(Value) v49 = Value end,
})
AutoFireGroup:AddSlider("AutoFireFOV", {
    Text = "Auto Fire FOV", Default = 80, Min = 10, Max = 500, Rounding = 0,
    Callback = function(Value) v50 = Value; v63.Radius = Value end,
})
AutoFireGroup:AddSlider("AutoFireRange", {
    Text = "Range", Default = 2000, Min = 50, Max = 2000, Rounding = 0,
    Callback = function(Value) v51 = Value end,
})
AutoFireGroup:AddDropdown("AutoFireAimPart", {
    Values = {"Head","HumanoidRootPart","Torso"},
    Default = "Head", Multi = false, Text = "Aim Part",
    Callback = function(Value) v53 = Value end,
})
AutoFireGroup:AddSlider("AutoFirePrediction", {
    Text = "Prediction", Default = 65, Min = 0, Max = 200, Rounding = 1,
    Callback = function(Value) v54 = Value / 1000 end,
})
AutoFireGroup:AddToggle("AutoFireWallCheck", {
    Text = "Wall Check", Default = true,
    Callback = function(Value) v52 = Value end,
})
AutoFireGroup:AddToggle("AutoFirePrioritizeClosest", {
    Text = "Prioritize Closest", Default = true,
    Callback = function(Value) v55 = Value end,
})
AutoFireGroup:AddToggle("AutoFireFOVVisible", {
    Text = "Show FOV Circle", Default = false,
    Callback = function(Value) v59 = Value end,
})
AutoFireGroup:AddLabel("FOV Color"):AddColorPicker("AutoFireFOVColor", {
    Default = v60, Title = "Auto Fire FOV Color",
    Callback = function(Value) v60 = Value end,
})
AutoFireGroup:AddToggle("AutoFireFOVRainbow", {
    Text = "FOV Rainbow", Default = false,
    Callback = function(Value) v61 = Value end,
})
AutoFireGroup:AddSlider("AutoFireFOVThickness", {
    Text = "FOV Thickness", Default = 2, Min = 1, Max = 10, Rounding = 0,
    Callback = function(Value) v62 = Value end,
})

-- ============================================================
-- VISUALS TAB
-- ============================================================
local ESPGroup      = Tabs.Visuals:AddGroupbox({ Side = "Left",  Name = "Default ESP", IconName = "box" })
local ExtraESPGroup = Tabs.Visuals:AddGroupbox({ Side = "Right", Name = "Extra ESP",   IconName = "settings-2" })

ESPGroup:AddToggle("ESPEnabled", {
    Text = "Enable ESP", Default = false,
    Callback = function(Value)
        v108.Enabled = Value
        if not Value then
            v114()
        else
            for _, plr in ipairs(v1:GetPlayers()) do
                if plr ~= v5 and not v105.ESP[plr] then v110(plr) end
            end
        end
    end,
})
ESPGroup:AddToggle("ESPTeamCheck", {
    Text = "Team Check", Default = false,
    Callback = function(Value) v108.TeamCheck = Value end,
})
ESPGroup:AddToggle("ESPShowTeam", {
    Text = "Show Team", Default = false,
    Callback = function(Value) v108.ShowTeam = Value end,
})
ESPGroup:AddToggle("ESPBox", {
    Text = "Box ESP", Default = false,
    Callback = function(Value) v108.BoxESP = Value end,
})
ESPGroup:AddLabel("Box Color"):AddColorPicker("ESPBoxColor", {
    Default = v108.BoxColor, Title = "Box Color",
    Callback = function(Value) v108.BoxColor = Value end,
})
ESPGroup:AddToggle("ESPTracer", {
    Text = "Tracer ESP", Default = false,
    Callback = function(Value) v108.TracerESP = Value end,
})
ESPGroup:AddLabel("Tracer Color"):AddColorPicker("ESPTracerColor", {
    Default = v108.TracerColor, Title = "Tracer Color",
    Callback = function(Value) v108.TracerColor = Value end,
})
ESPGroup:AddDropdown("ESPTracerOrigin", {
    Values = {"Bottom","Top","Mouse","Center"},
    Default = "Bottom", Multi = false, Text = "Tracer Origin",
    Callback = function(Value) v108.TracerOrigin = Value end,
})
ESPGroup:AddToggle("ESPHealth", {
    Text = "Health Bar", Default = false,
    Callback = function(Value) v108.HealthESP = Value end,
})
ESPGroup:AddDropdown("ESPHealthStyle", {
    Values = {"Bar","Text","Both"},
    Default = "Bar", Multi = false, Text = "Health Style",
    Callback = function(Value) v108.HealthStyle = Value end,
})
ESPGroup:AddToggle("ESPName", {
    Text = "Name ESP", Default = false,
    Callback = function(Value) v108.NameESP = Value end,
})
ESPGroup:AddLabel("Name Color"):AddColorPicker("ESPNameColor", {
    Default = v108.NameColor, Title = "Name Color",
    Callback = function(Value) v108.NameColor = Value end,
})
ESPGroup:AddToggle("ESPSnaplines", {
    Text = "Snaplines", Default = false,
    Callback = function(Value) v108.Snaplines = Value end,
})
ESPGroup:AddToggle("ESPRainbow", {
    Text = "Rainbow Mode", Default = false,
    Callback = function(Value) v108.RainbowEnabled = Value end,
})

ExtraESPGroup:AddSlider("ESPMaxDistance", {
    Text = "Max Distance", Default = 1000, Min = 100, Max = 5000, Rounding = 0,
    Callback = function(Value) v108.MaxDistance = Value end,
})
ExtraESPGroup:AddDropdown("ESPBoxStyle", {
    Values = {"Corner","Full"},
    Default = "Corner", Multi = false, Text = "Box Style",
    Callback = function(Value) v108.BoxStyle = Value end,
})
ExtraESPGroup:AddSlider("ESPBoxThickness", {
    Text = "Box Thickness", Default = 1, Min = 1, Max = 5, Rounding = 0,
    Callback = function(Value) v108.BoxThickness = Value end,
})
ExtraESPGroup:AddToggle("ESPChams", {
    Text = "Chams", Default = false,
    Callback = function(Value)
        v108.ChamsEnabled = Value
        for _, plr in ipairs(v1:GetPlayers()) do
            if v107[plr] then v107[plr].Enabled = Value end
        end
    end,
})
ExtraESPGroup:AddLabel("Chams Fill Color"):AddColorPicker("ESPChamsFillColor", {
    Default = v108.ChamsFillColor, Title = "Chams Fill Color",
    Callback = function(Value) v108.ChamsFillColor = Value end,
})
ExtraESPGroup:AddLabel("Chams Outline Color"):AddColorPicker("ESPChamsOutlineColor", {
    Default = v108.ChamsOutlineColor, Title = "Chams Outline Color",
    Callback = function(Value) v108.ChamsOutlineColor = Value end,
})

-- ============================================================
-- MISC TAB
-- ============================================================
local BhopGroup     = Tabs.Misc:AddGroupbox({ Side = "Left",  Name = "Bunny Hop (Speed)", IconName = "rabbit" })
local AutoBhopGroup = Tabs.Misc:AddGroupbox({ Side = "Right", Name = "Auto Bhop",         IconName = "activity" })

BhopGroup:AddToggle("BhopEnabled", {
    Text = "Enable Speed Bhop", Default = false,
    Callback = function(Value)
        v90 = Value
        if Value then
            local char = v5.Character
            if char then v100(); task.wait(0.1); v101(char) end
            Notify("Speed Bhop", "ON", 2)
        else
            v100()
            Notify("Speed Bhop", "OFF", 2)
        end
    end,
})
BhopGroup:AddSlider("BhopJumpBoost", {
    Text = "Jump Boost", Default = 5, Min = 0, Max = 50, Rounding = 1,
    Callback = function(Value) v91 = Value end,
})
BhopGroup:AddSlider("BhopSpeedCap", {
    Text = "Max Speed Cap", Default = 100, Min = 20, Max = 300, Rounding = 1,
    Callback = function(Value) v92 = Value end,
})
BhopGroup:AddSlider("BhopDecelRate", {
    Text = "Deceleration", Default = 50, Min = 10, Max = 200, Rounding = 1,
    Callback = function(Value) v93 = Value end,
})

AutoBhopGroup:AddToggle("AutoBhopEnabled", {
    Text = "Enable Auto Bhop", Default = false,
    Callback = function(Value) v102 = Value end,
})
AutoBhopGroup:AddSlider("AutoBhopDelay", {
    Text = "Jump Delay (min)", Default = 0.1, Min = 0.05, Max = 0.3, Rounding = 3,
    Callback = function(Value) v103 = Value end,
})

-- ============================================================
-- ABOUT TAB
-- ============================================================
local AboutGroup = Tabs.About:AddGroupbox({ Side = "Left", Name = "About", IconName = "info" })
AboutGroup:AddLabel("Neverlose Arsenal Script")
AboutGroup:AddLabel("Version: 8.0 - Ultimate Edition")
AboutGroup:AddLabel("Features:")
AboutGroup:AddLabel("• Aimbot with FOV circle, colors & rainbow")
AboutGroup:AddLabel("• Silent Aim with own FOV circle")
AboutGroup:AddLabel("• Auto Fire with customizable FOV")
AboutGroup:AddLabel("• ESP: Box, Tracer, Health, Name, Snaplines, Chams")
AboutGroup:AddLabel("• Bunny Hop (Speed) and Auto Bhop")
AboutGroup:AddLabel("• All colors customizable, Rainbow mode")
AboutGroup:AddLabel("• Press Insert to toggle GUI")
AboutGroup:AddLabel("• Configs saved automatically")
AboutGroup:AddLabel("Made with love for Arsenal")

-- ============================================================
-- UI SETTINGS TAB
-- ============================================================
local UIGroup = Tabs["UI Settings"]:AddGroupbox({ Side = "Left", Name = "Menu", IconName = "wrench" })

UIGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor", Default = Library.ShowCustomCursor,
    Callback = function(Value) Library.ShowCustomCursor = Value end,
})
UIGroup:AddToggle("AlwaysOnTop", {
    Text = "Always On Top", Default = false,
    Callback = function(Value) Window:SetAlwaysOnTop(Value) end,
})
UIGroup:AddDropdown("NotificationSide", {
    Values = {"Left","Right"}, Default = "Right", Text = "Notification Side",
    Callback = function(Value) Library:SetNotifySide(Value) end,
})
UIGroup:AddDropdown("DPIDropdown", {
    Values = {"50%","75%","100%","125%","150%","175%","200%"},
    Default = "100%", Text = "DPI Scale",
    Callback = function(Value)
        local dpi = tonumber(Value:gsub("%%", ""))
        Library:SetDPIScale(dpi)
    end,
})
UIGroup:AddDivider()
UIGroup:AddLabel("Menu Bind"):AddKeyPicker("MenuKeybind", {
    Default = "Insert", NoUI = true, Text = "Menu keybind",
})
UIGroup:AddButton({ Text = "Unload", Func = function() Library:Unload() end })

Library.ToggleKeybind = Options.MenuKeybind

-- ---- Watermark ----
local wm = Library:AddDraggableLabel("Neverlose | Arsenal | 0 MS")
task.spawn(function()
    while task.wait(1) do
        if Library.Unloaded then break end
        pcall(function()
            local ping = math.floor(v5:GetNetworkPing() * 1000)
            wm:SetText("Neverlose | Arsenal | " .. ping .. " MS")
        end)
    end
end)

-- ============================================================
-- Addons
-- ============================================================
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("NeverloseArsenal")
SaveManager:SetFolder("NeverloseArsenal/Arsenal")
SaveManager:SetSubFolder("default")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

Library:OnUnload(function()
    v108.Enabled = false
    v114()
    print("Neverlose Unloaded!")
end)

Notify("Arsenal", "Loaded! ESP colors added, Bhop side by side.", 5)

-- ============================================================
-- Final render loops (unchanged)
-- ============================================================
local v136 = 0
v3.RenderStepped:Connect(function()
    if not v108.Enabled then return end
    local v400 = tick()
    if (v400 - v136) >= (1 / 60) then
        for _, v597 in ipairs(v1:GetPlayers()) do
            if v597 ~= v5 then
                if not v105.ESP[v597] then v110(v597) end
                v113(v597)
            end
        end
        v136 = v400
    end
end)

task.spawn(function()
    while true do
        task.wait(0.05)
        v106.Rainbow = Color3.fromHSV(tick() % 1, 1, 1)
    end
end)
