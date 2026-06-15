--[[
    Improved Universal Skeleton ESP
    Fixed issues:
    - No duplicate lines on toggle
    - New players get ESP even if enabled before they join
    - Global control methods
]]

local WAIT = task.wait
local TBINSERT = table.insert
local TBFIND = table.find
local TBREMOVE = table.remove
local V2 = Vector2.new
local ROUND = math.round

local RS = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local To2D = Camera.WorldToViewportPoint
local LocalPlayer = game.Players.LocalPlayer

local Library = {}
Library.__index = Library

-- Line helper
function Library:NewLine(info)
    local l = Drawing.new("Line")
    l.Visible = info.Visible or true
    l.Color = info.Color or Color3.fromRGB(0,255,0)
    l.Transparency = info.Transparency or 1
    l.Thickness = info.Thickness or 1
    return l
end

function Library:Smoothen(v)
    return V2(ROUND(v.X), ROUND(v.Y))
end

-- Skeleton Object (improved)
local Skeleton = {
    Removed = false,
    Player = nil,
    Visible = false,
    Lines = {},
    Color = Color3.fromRGB(0,255,0),
    Alpha = 1,
    Thickness = 1,
    DoSubsteps = true,
    Connection = nil,
}
Skeleton.__index = Skeleton

function Skeleton:UpdateStructure()
    if not self.Player.Character then return end

    self:RemoveLines()

    for _, part in next, self.Player.Character:GetChildren() do
        if not part:IsA("BasePart") then continue end
        for _, link in next, part:GetChildren() do
            if not link:IsA("Motor6D") then continue end
            TBINSERT(
                self.Lines,
                {
                    Library:NewLine({
                        Visible = self.Visible,
                        Color = self.Color,
                        Transparency = self.Alpha,
                        Thickness = self.Thickness,
                    }),
                    Library:NewLine({
                        Visible = self.Visible,
                        Color = self.Color,
                        Transparency = self.Alpha,
                        Thickness = self.Thickness,
                    }),
                    part.Name,
                    link.Name
                }
            )
        end
    end
end

function Skeleton:SetVisible(State)
    for _, l in pairs(self.Lines) do
        l[1].Visible = State
        l[2].Visible = State
    end
end

function Skeleton:SetColor(Color)
    self.Color = Color
    for _, l in pairs(self.Lines) do
        l[1].Color = Color
        l[2].Color = Color
    end
end

function Skeleton:SetAlpha(Alpha)
    self.Alpha = Alpha
    for _, l in pairs(self.Lines) do
        l[1].Transparency = Alpha
        l[2].Transparency = Alpha
    end
end

function Skeleton:SetThickness(Thickness)
    self.Thickness = Thickness
    for _, l in pairs(self.Lines) do
        l[1].Thickness = Thickness
        l[2].Thickness = Thickness
    end
end

function Skeleton:SetDoSubsteps(State)
    self.DoSubsteps = State
end

function Skeleton:Update()
    if self.Removed then return end

    local Character = self.Player.Character
    if not Character then
        self:SetVisible(false)
        if not self.Player.Parent then
            self:Remove()
        end
        return
    end

    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then
        self:SetVisible(false)
        return
    end

    -- Apply current settings
    self:SetColor(self.Color)
    self:SetAlpha(self.Alpha)
    self:SetThickness(self.Thickness)

    local updateNeeded = false
    for _, l in pairs(self.Lines) do
        local part = Character:FindFirstChild(l[3])
        if not part then
            l[1].Visible = false
            l[2].Visible = false
            updateNeeded = true
            continue
        end

        local link = part:FindFirstChild(l[4])
        if not (link and link.Part0 and link.Part1) then
            l[1].Visible = false
            l[2].Visible = false
            updateNeeded = true
            continue
        end

        local part0 = link.Part0
        local part1 = link.Part1

        if self.DoSubsteps and link.C0 and link.C1 then
            local c0 = link.C0
            local c1 = link.C1

            local part0p, v1 = To2D(Camera, part0.CFrame.p)
            local part0cp, v2 = To2D(Camera, (part0.CFrame * c0).p)
            if v1 and v2 then
                l[1].From = V2(part0p.x, part0p.y)
                l[1].To = V2(part0cp.x, part0cp.y)
                l[1].Visible = true
            else
                l[1].Visible = false
            end

            local part1p, v3 = To2D(Camera, part1.CFrame.p)
            local part1cp, v4 = To2D(Camera, (part1.CFrame * c1).p)
            if v3 and v4 then
                l[2].From = V2(part1p.x, part1p.y)
                l[2].To = V2(part1cp.x, part1cp.y)
                l[2].Visible = true
            else
                l[2].Visible = false
            end
        else
            local part0p, v1 = To2D(Camera, part0.CFrame.p)
            local part1p, v2 = To2D(Camera, part1.CFrame.p)
            if v1 and v2 then
                l[1].From = V2(part0p.x, part0p.y)
                l[1].To = V2(part1p.x, part1p.y)
                l[1].Visible = true
            else
                l[1].Visible = false
            end
            l[2].Visible = false
        end
    end

    if updateNeeded or #self.Lines == 0 then
        self:UpdateStructure()
    end
end

function Skeleton:Enable()
    if self.Visible then return end
    self.Visible = true
    self:RemoveLines()
    self:UpdateStructure()
    if self.Connection then self.Connection:Disconnect() end
    self.Connection = RS.Heartbeat:Connect(function()
        if not self.Visible then
            self:SetVisible(false)
            if self.Connection then self.Connection:Disconnect() end
            self.Connection = nil
            return
        end
        self:Update()
    end)
end

function Skeleton:Disable()
    self.Visible = false
    self:SetVisible(false)
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
end

function Skeleton:Toggle()
    if self.Visible then
        self:Disable()
    else
        self:Enable()
    end
end

function Skeleton:RemoveLines()
    for _, l in pairs(self.Lines) do
        l[1]:Remove()
        l[2]:Remove()
    end
    self.Lines = {}
end

function Skeleton:Remove()
    self.Removed = true
    self:Disable()
    self:RemoveLines()
end

function Library:NewSkeleton(Player, Enabled, Color, Alpha, Thickness, DoSubsteps)
    if not Player then error("Missing Player argument (#1)") end
    local s = setmetatable({}, Skeleton)
    s.Player = Player
    s.Bind = Player.UserId
    if DoSubsteps ~= nil then s.DoSubsteps = DoSubsteps end
    if Color then s:SetColor(Color) end
    if Alpha then s:SetAlpha(Alpha) end
    if Thickness then s:SetThickness(Thickness) end
    if Enabled then s:Enable() end
    return s
end

-- Manager for global control
local SkeletonManager = {}
SkeletonManager.__index = SkeletonManager

function SkeletonManager:New(EnabledByDefault, DefaultColor, DefaultAlpha, DefaultThickness, DefaultDoSubsteps)
    local mgr = setmetatable({}, SkeletonManager)
    mgr.Skeletons = {}
    mgr.Enabled = EnabledByDefault or false
    mgr.DefaultColor = DefaultColor or Color3.fromRGB(0,255,0)
    mgr.DefaultAlpha = DefaultAlpha or 1
    mgr.DefaultThickness = DefaultThickness or 1
    mgr.DefaultDoSubsteps = (DefaultDoSubsteps ~= nil) and DefaultDoSubsteps or true
    mgr.Connection = nil
    mgr:Setup()
    return mgr
end

function SkeletonManager:Setup()
    -- Create skeletons for existing players (excluding local)
    for _, plr in ipairs(game.Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            self:AddPlayer(plr)
        end
    end
    -- Listen for new players
    game.Players.PlayerAdded:Connect(function(plr)
        if plr ~= LocalPlayer then
            self:AddPlayer(plr)
        end
    end)
    -- Listen for player removal
    game.Players.PlayerRemoving:Connect(function(plr)
        self:RemovePlayer(plr)
    end)
end

function SkeletonManager:AddPlayer(plr)
    if self.Skeletons[plr] then return end
    local s = Library:NewSkeleton(plr, self.Enabled, self.DefaultColor, self.DefaultAlpha, self.DefaultThickness, self.DefaultDoSubsteps)
    self.Skeletons[plr] = s
    return s
end

function SkeletonManager:RemovePlayer(plr)
    local s = self.Skeletons[plr]
    if s then
        s:Remove()
        self.Skeletons[plr] = nil
    end
end

function SkeletonManager:EnableAll()
    self.Enabled = true
    for _, s in pairs(self.Skeletons) do
        s:Enable()
    end
    -- Also for future players, they will be created with Enabled = true automatically in AddPlayer (if called after)
    -- But AddPlayer is already triggered on PlayerAdded, and it uses current self.Enabled
end

function SkeletonManager:DisableAll()
    self.Enabled = false
    for _, s in pairs(self.Skeletons) do
        s:Disable()
    end
end

function SkeletonManager:ToggleAll()
    if self.Enabled then
        self:DisableAll()
    else
        self:EnableAll()
    end
end

function SkeletonManager:SetColorForAll(color)
    self.DefaultColor = color
    for _, s in pairs(self.Skeletons) do
        s:SetColor(color)
    end
end

function SkeletonManager:SetAlphaForAll(alpha)
    self.DefaultAlpha = alpha
    for _, s in pairs(self.Skeletons) do
        s:SetAlpha(alpha)
    end
end

function SkeletonManager:SetThicknessForAll(thickness)
    self.DefaultThickness = thickness
    for _, s in pairs(self.Skeletons) do
        s:SetThickness(thickness)
    end
end

function SkeletonManager:Destroy()
    for _, s in pairs(self.Skeletons) do
        s:Remove()
    end
    self.Skeletons = {}
end

-- Return both the original Library and the Manager for flexibility
return {
    Library = Library,
    Manager = SkeletonManager,
    NewSkeleton = Library.NewSkeleton,
}
