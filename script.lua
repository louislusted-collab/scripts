local library, themes = loadstring(game:HttpGet("https://raw.githubusercontent.com/louislusted-collab/scripts/refs/heads/main/Library.lua?v=" .. tostring(tick())))()

-- ───────────────────────────────────────────
--  AIMBOT (embedded)
-- ───────────────────────────────────────────
do
    local game, workspace = game, workspace
    local getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick = getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick
    local Vector2new, Vector3zero, CFramenew, Color3fromRGB, Color3fromHSV, Drawingnew, TweenInfonew = Vector2.new, Vector3.zero, CFrame.new, Color3.fromRGB, Color3.fromHSV, Drawing.new, TweenInfo.new
    local mousemoverel, tablefind, tableremove, stringlower, stringsub, mathclamp = mousemoverel or (Input and Input.MouseMove), table.find, table.remove, string.lower, string.sub, math.clamp
    local GameMetatable = getrawmetatable and getrawmetatable(game) or {
        __index = function(self, Index) return self[Index] end,
        __newindex = function(self, Index, Value) self[Index] = Value end
    }
    local __index = GameMetatable.__index
    local __newindex = GameMetatable.__newindex
    local getrenderproperty, setrenderproperty = getrenderproperty or __index, setrenderproperty or __newindex
    local GetService = __index(game, "GetService")
    local RunService = GetService(game, "RunService")
    local UserInputService = GetService(game, "UserInputService")
    local TweenService = GetService(game, "TweenService")
    local Players = GetService(game, "Players")
    local LocalPlayer = __index(Players, "LocalPlayer")
    local Camera = __index(workspace, "CurrentCamera")
    local FindFirstChild, FindFirstChildOfClass = __index(game, "FindFirstChild"), __index(game, "FindFirstChildOfClass")
    local GetDescendants = __index(game, "GetDescendants")
    local WorldToViewportPoint = __index(Camera, "WorldToViewportPoint")
    local GetPartsObscuringTarget = __index(Camera, "GetPartsObscuringTarget")
    local GetMouseLocation = __index(UserInputService, "GetMouseLocation")
    local GetPlayers = __index(Players, "GetPlayers")
    local RequiredDistance, Typing, Running, ServiceConnections, Animation, OriginalSensitivity = 2000, false, false, {}
    local Connect = __index(game, "DescendantAdded").Connect
    local Disconnect = function(conn) return conn:Disconnect() end
    if ExunysDeveloperAimbot then
        pcall(function() ExunysDeveloperAimbot:Exit() end)
        pcall(function() ExunysDeveloperAimbot.FOVCircle:Remove() end)
        pcall(function() ExunysDeveloperAimbot.FOVCircleOutline:Remove() end)
        getgenv().ExunysDeveloperAimbot = nil
    end
    getgenv().ExunysDeveloperAimbot = {
        DeveloperSettings = {UpdateMode = "RenderStepped", TeamCheckOption = "TeamColor", RainbowSpeed = 1},
        Settings = {
            Enabled = true, TeamCheck = false, AliveCheck = true, WallCheck = false,
            OffsetToMoveDirection = false, OffsetIncrement = 15,
            Sensitivity = 0, Sensitivity2 = 3.5,
            LockMode = 1, LockPart = "Head",
            TriggerKey = Enum.UserInputType.MouseButton2, Toggle = false
        },
        FOVSettings = {
            Enabled = true, Visible = true, Radius = 90, NumSides = 60,
            Thickness = 1, Transparency = 1, Filled = false,
            RainbowColor = false, RainbowOutlineColor = false,
            Color = Color3fromRGB(255, 255, 255), OutlineColor = Color3fromRGB(0, 0, 0),
            LockedColor = Color3fromRGB(255, 150, 150)
        },
        Blacklisted = {},
        FOVCircleOutline = Drawingnew("Circle"),
        FOVCircle = Drawingnew("Circle")
    }
    local Environment = getgenv().ExunysDeveloperAimbot
    setrenderproperty(Environment.FOVCircle, "Visible", false)
    setrenderproperty(Environment.FOVCircleOutline, "Visible", false)
    local FixUsername = function(String)
        local Result
        for _, Value in next, GetPlayers(Players) do
            local Name = __index(Value, "Name")
            if stringsub(stringlower(Name), 1, #String) == stringlower(String) then Result = Name end
        end
        return Result
    end
    local GetRainbowColor = function()
        return Color3fromHSV(tick() % Environment.DeveloperSettings.RainbowSpeed / Environment.DeveloperSettings.RainbowSpeed, 1, 1)
    end
    local ConvertVector = function(Vector) return Vector2new(Vector.X, Vector.Y) end
    local CancelLock = function()
        Environment.Locked = nil
        setrenderproperty(Environment.FOVCircle, "Color", Environment.FOVSettings.Color)
        __newindex(UserInputService, "MouseDeltaSensitivity", OriginalSensitivity)
        if Animation then Animation:Cancel() end
    end
    local GetClosestPlayer = function()
        local Settings = Environment.Settings
        local LockPart = Settings.LockPart
        if not Environment.Locked then
            RequiredDistance = Environment.FOVSettings.Enabled and Environment.FOVSettings.Radius or 2000
            for _, Value in next, GetPlayers(Players) do
                local Character = __index(Value, "Character")
                local Humanoid = Character and FindFirstChildOfClass(Character, "Humanoid")
                if Value ~= LocalPlayer and not tablefind(Environment.Blacklisted, __index(Value, "Name")) and Character and FindFirstChild(Character, LockPart) and Humanoid then
                    local PartPosition = __index(Character[LockPart], "Position")
                    local TeamCheckOption = Environment.DeveloperSettings.TeamCheckOption
                    if Settings.TeamCheck and __index(Value, TeamCheckOption) == __index(LocalPlayer, TeamCheckOption) then continue end
                    if Settings.AliveCheck and __index(Humanoid, "Health") <= 0 then continue end
                    if Settings.WallCheck then
                        local BlacklistTable = GetDescendants(__index(LocalPlayer, "Character"))
                        for _, v in next, GetDescendants(Character) do BlacklistTable[#BlacklistTable + 1] = v end
                        if #GetPartsObscuringTarget(Camera, {PartPosition}, BlacklistTable) > 0 then continue end
                    end
                    local Vector, OnScreen = WorldToViewportPoint(Camera, PartPosition)
                    Vector = ConvertVector(Vector)
                    local Distance = (GetMouseLocation(UserInputService) - Vector).Magnitude
                    if Distance < RequiredDistance and OnScreen then
                        RequiredDistance, Environment.Locked = Distance, Value
                    end
                end
            end
        elseif (GetMouseLocation(UserInputService) - ConvertVector(WorldToViewportPoint(Camera, __index(__index(__index(Environment.Locked, "Character"), LockPart), "Position")))).Magnitude > RequiredDistance then
            CancelLock()
        end
    end
    local Load = function()
        OriginalSensitivity = __index(UserInputService, "MouseDeltaSensitivity")
        local Settings = Environment.Settings
        local FOVCircle = Environment.FOVCircle
        local FOVCircleOutline = Environment.FOVCircleOutline
        local FOVSettings = Environment.FOVSettings
        ServiceConnections.RenderSteppedConnection = Connect(__index(RunService, Environment.DeveloperSettings.UpdateMode), function()
            local OffsetToMoveDirection = Settings.OffsetToMoveDirection
            local LockPart = Settings.LockPart
            if FOVSettings.Enabled and Settings.Enabled then
                for Index, Value in next, FOVSettings do
                    if Index == "Color" then continue end
                    if pcall(getrenderproperty, FOVCircle, Index) then
                        setrenderproperty(FOVCircle, Index, Value)
                        setrenderproperty(FOVCircleOutline, Index, Value)
                    end
                end
                setrenderproperty(FOVCircle, "Color", (Environment.Locked and FOVSettings.LockedColor) or (FOVSettings.RainbowColor and GetRainbowColor()) or FOVSettings.Color)
                setrenderproperty(FOVCircleOutline, "Color", (FOVSettings.RainbowOutlineColor and GetRainbowColor()) or FOVSettings.OutlineColor)
                setrenderproperty(FOVCircleOutline, "Thickness", FOVSettings.Thickness + 1)
                setrenderproperty(FOVCircle, "Position", GetMouseLocation(UserInputService))
                setrenderproperty(FOVCircleOutline, "Position", GetMouseLocation(UserInputService))
            else
                setrenderproperty(FOVCircle, "Visible", false)
                setrenderproperty(FOVCircleOutline, "Visible", false)
            end
            if Running and Settings.Enabled then
                GetClosestPlayer()
                local Offset = OffsetToMoveDirection and __index(FindFirstChildOfClass(__index(Environment.Locked, "Character"), "Humanoid"), "MoveDirection") * (mathclamp(Settings.OffsetIncrement, 1, 30) / 10) or Vector3zero
                if Environment.Locked then
                    local LockedPosition_Vector3 = __index(__index(Environment.Locked, "Character")[LockPart], "Position")
                    local LockedPosition = WorldToViewportPoint(Camera, LockedPosition_Vector3 + Offset)
                    if Settings.LockMode == 2 then
                        mousemoverel((LockedPosition.X - GetMouseLocation(UserInputService).X) / Settings.Sensitivity2, (LockedPosition.Y - GetMouseLocation(UserInputService).Y) / Settings.Sensitivity2)
                    else
                        if Settings.Sensitivity > 0 then
                            Animation = TweenService:Create(Camera, TweenInfonew(Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFramenew(Camera.CFrame.Position, LockedPosition_Vector3)})
                            Animation:Play()
                        else
                            __newindex(Camera, "CFrame", CFramenew(Camera.CFrame.Position, LockedPosition_Vector3 + Offset))
                        end
                        __newindex(UserInputService, "MouseDeltaSensitivity", 0)
                    end
                    setrenderproperty(FOVCircle, "Color", FOVSettings.LockedColor)
                end
            end
        end)
        ServiceConnections.InputBeganConnection = Connect(__index(UserInputService, "InputBegan"), function(Input)
            if Typing then return end
            local TriggerKey = Settings.TriggerKey
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == TriggerKey or Input.UserInputType == TriggerKey then
                if Settings.Toggle then Running = not Running; if not Running then CancelLock() end
                else Running = true end
            end
        end)
        ServiceConnections.InputEndedConnection = Connect(__index(UserInputService, "InputEnded"), function(Input)
            if Settings.Toggle or Typing then return end
            local TriggerKey = Settings.TriggerKey
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == TriggerKey or Input.UserInputType == TriggerKey then
                Running = false; CancelLock()
            end
        end)
    end
    -- FIX: direct UIS connections instead of raw metatable (works on all executors)
    ServiceConnections.TypingStartedConnection = UserInputService.TextBoxFocused:Connect(function() Typing = true end)
    ServiceConnections.TypingEndedConnection   = UserInputService.TextBoxFocusReleased:Connect(function() Typing = false end)
    function Environment.Exit(self)
        for Index in next, ServiceConnections do Disconnect(ServiceConnections[Index]) end
        self.FOVCircle:Remove(); self.FOVCircleOutline:Remove()
        getgenv().ExunysDeveloperAimbot = nil
    end
    function Environment.Restart()
        for Index in next, ServiceConnections do Disconnect(ServiceConnections[Index]) end
        Load()
    end
    function Environment.Blacklist(self, Username)
        Username = FixUsername(Username)
        self.Blacklisted[#self.Blacklisted + 1] = Username
    end
    function Environment.Whitelist(self, Username)
        Username = FixUsername(Username)
        local Index = tablefind(self.Blacklisted, Username)
        tableremove(self.Blacklisted, Index)
    end
    function Environment.GetClosestPlayer()
        GetClosestPlayer()
        local Value = Environment.Locked
        CancelLock()
        return Value
    end
    Environment.Load = Load
    setmetatable(Environment, {__call = Load})
end

local dim2 = UDim2.new
local hex  = Color3.fromHex
local Aim  = ExunysDeveloperAimbot

Aim.Settings.Enabled    = false
Aim.FOVSettings.Visible = false

-- ───────────────────────────────────────────
--  SERVICES
-- ───────────────────────────────────────────
local Space   = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunSvc  = game:GetService("RunService")
local UIS     = game:GetService("UserInputService")
local Player  = Players.LocalPlayer
local Camera  = Space.CurrentCamera

-- ───────────────────────────────────────────
--  CHAMS ENGINE
-- ───────────────────────────────────────────
local CHAMS_TAG = "JefferyChams"
local ChamsSettings = {
    Enabled    = false,
    EnemyColor = Color3.fromRGB(180, 40, 40),
    AllyColor  = Color3.fromRGB(40, 180, 80),
    FillTr     = 0.5,
    OutTr      = 0.1,
    TeamCheck  = true,
}
local ChamsCons = {}

local function ApplyChams(char, plr)
    if not char or char:FindFirstChild(CHAMS_TAG) then return end
    if not ChamsSettings.Enabled then return end
    local h = Instance.new("Highlight")
    local isEnemy = (ChamsSettings.TeamCheck and plr.Team ~= Player.Team) or not ChamsSettings.TeamCheck
    h.Name                = CHAMS_TAG
    h.FillColor           = isEnemy and ChamsSettings.EnemyColor or ChamsSettings.AllyColor
    h.OutlineColor        = Color3.fromRGB(255, 255, 255)
    h.FillTransparency    = ChamsSettings.FillTr
    h.OutlineTransparency = ChamsSettings.OutTr
    h.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee             = char
    h.Parent              = char
end

local function RemoveChams(char)
    if not char then return end
    local h = char:FindFirstChild(CHAMS_TAG)
    if h then h:Destroy() end
end

local function HookPlayer(plr)
    if plr == Player then return end
    ChamsCons[plr] = plr.CharacterAdded:Connect(function(c)
        task.wait(0.1)
        ApplyChams(c, plr)
    end)
    if plr.Character then ApplyChams(plr.Character, plr) end
end

local function EnableChams()
    for _, plr in pairs(Players:GetPlayers()) do HookPlayer(plr) end
    ChamsCons["PlayerAdded"] = Players.PlayerAdded:Connect(HookPlayer)
end

local function DisableChams()
    for key, conn in pairs(ChamsCons) do
        if type(conn) == "RBXScriptConnection" then conn:Disconnect() end
        ChamsCons[key] = nil
    end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character then RemoveChams(plr.Character) end
    end
end

local function RefreshChams()
    DisableChams()
    if ChamsSettings.Enabled then EnableChams() end
end

-- ───────────────────────────────────────────
--  CATEGORY CHAMS ENGINE
-- ───────────────────────────────────────────
local CAT_CHAMS_TAG = "JefferyCatChams"
local CatChamsSettings = {
    Enabled       = false,
    PriorityColor = Color3.fromRGB(255, 255, 0),
    EnemyColor    = Color3.fromRGB(255, 0, 0),
    NeutralColor  = Color3.fromRGB(255, 255, 255),
    FriendlyColor = Color3.fromRGB(0, 255, 100),
    ShowFriendly  = false,
    FillTr        = 0.5,
    OutTr         = 0.1,
}
local CatChamsCons = {}

local function GetCatColor(plr)
    local cat = library.get_priority(plr) or "Neutral"
    if cat == "Priority" then return CatChamsSettings.PriorityColor
    elseif cat == "Enemy" then return CatChamsSettings.EnemyColor
    elseif cat == "Friendly" then return CatChamsSettings.FriendlyColor
    else return CatChamsSettings.NeutralColor end
end

local function ApplyCatChams(char, plr)
    if not char or char:FindFirstChild(CAT_CHAMS_TAG) then return end
    if not CatChamsSettings.Enabled then return end
    local cat = library.get_priority(plr) or "Neutral"
    if cat == "Friendly" and not CatChamsSettings.ShowFriendly then return end
    local h = Instance.new("Highlight")
    h.Name                = CAT_CHAMS_TAG
    h.FillColor           = GetCatColor(plr)
    h.OutlineColor        = GetCatColor(plr)
    h.FillTransparency    = CatChamsSettings.FillTr
    h.OutlineTransparency = CatChamsSettings.OutTr
    h.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee             = char
    h.Parent              = char
end

local function RemoveCatChams(char)
    if not char then return end
    local h = char:FindFirstChild(CAT_CHAMS_TAG)
    if h then h:Destroy() end
end

local function HookCatPlayer(plr)
    if plr == Player then return end
    CatChamsCons[plr] = plr.CharacterAdded:Connect(function(c)
        task.wait(0.1)
        ApplyCatChams(c, plr)
    end)
    if plr.Character then ApplyCatChams(plr.Character, plr) end
end

local function EnableCatChams()
    for _, plr in pairs(Players:GetPlayers()) do HookCatPlayer(plr) end
    CatChamsCons["PlayerAdded"] = Players.PlayerAdded:Connect(HookCatPlayer)
end

local function DisableCatChams()
    for key, conn in pairs(CatChamsCons) do
        if type(conn) == "RBXScriptConnection" then conn:Disconnect() end
        CatChamsCons[key] = nil
    end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character then RemoveCatChams(plr.Character) end
    end
end

local function RefreshCatChams()
    DisableCatChams()
    if CatChamsSettings.Enabled then EnableCatChams() end
end

-- ───────────────────────────────────────────
--  BACKTRACK ENGINE
-- ───────────────────────────────────────────
local BacktrackSettings = {
    Enabled = false,
    Ms      = 100,
    Color   = Color3.fromRGB(255, 165, 0),
}
local btConnections     = {}
local btData            = {}
local btPlayerAddedConn = nil
local btPlayerRemovConn = nil

local function SetupBacktrack(plr)
    if btData[plr] then return end
    if plr == Player then return end
    local part        = Instance.new("Part")
    part.Anchored     = true
    part.CanCollide   = false
    part.CastShadow   = false
    part.Transparency = 0.99
    part.Size         = Vector3.new(2, 5, 1)
    part.CFrame       = CFrame.new(0, -9999, 0)
    part.Parent       = Space
    local sb               = Instance.new("SelectionBox")
    sb.Color3              = BacktrackSettings.Color
    sb.LineThickness       = 0.07
    sb.SurfaceTransparency = 0.6
    sb.SurfaceColor3       = BacktrackSettings.Color
    sb.Adornee             = part
    sb.Visible             = false
    sb.Parent              = Space
    btData[plr] = { history = {}, part = part, box = sb }
    btConnections[plr] = RunSvc.Heartbeat:Connect(function()
        local d = btData[plr]
        if not d then return end
        local c   = plr.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if not hrp or not BacktrackSettings.Enabled then d.box.Visible = false return end
        local now = tick()
        table.insert(d.history, {t = now, cf = hrp.CFrame, size = hrp.Size})
        while d.history[1] and (now - d.history[1].t) > 0.2 do table.remove(d.history, 1) end
        local target = now - (BacktrackSettings.Ms / 1000)
        local best, bestDiff = nil, math.huge
        for _, entry in ipairs(d.history) do
            local diff = math.abs(entry.t - target)
            if diff < bestDiff then bestDiff = diff; best = entry end
        end
        if best then
            d.part.CFrame       = best.cf
            d.part.Size         = Vector3.new(best.size.X * 1.2, best.size.Y * 3, best.size.Z * 1.2)
            d.box.Color3        = BacktrackSettings.Color
            d.box.SurfaceColor3 = BacktrackSettings.Color
            d.box.Visible       = true
        else
            d.box.Visible = false
        end
    end)
end

local function CleanupBacktrack(plr)
    local d = btData[plr]
    if not d then return end
    if btConnections[plr] then btConnections[plr]:Disconnect(); btConnections[plr] = nil end
    pcall(function() d.part:Destroy() end)
    pcall(function() d.box:Destroy()  end)
    btData[plr] = nil
end

local function EnableBacktrack()
    for _, plr in pairs(Players:GetPlayers()) do SetupBacktrack(plr) end
    if not btPlayerAddedConn then btPlayerAddedConn = Players.PlayerAdded:Connect(SetupBacktrack) end
    if not btPlayerRemovConn then btPlayerRemovConn = Players.PlayerRemoving:Connect(CleanupBacktrack) end
end

local function DisableBacktrack()
    for plr in pairs(btData) do CleanupBacktrack(plr) end
    if btPlayerAddedConn then btPlayerAddedConn:Disconnect(); btPlayerAddedConn = nil end
    if btPlayerRemovConn then btPlayerRemovConn:Disconnect(); btPlayerRemovConn = nil end
end

-- ───────────────────────────────────────────
--  THIRD PERSON ENGINE
-- ───────────────────────────────────────────
local tpEnabled  = false
local tpDistance = 15
local tpKey      = Enum.KeyCode.V
local tpYaw      = 0
local tpPitch    = -0.3
local tpConns    = {}

local function enableThirdPerson()
    tpEnabled = true
    Camera.CameraType    = Enum.CameraType.Scriptable
    UIS.MouseBehavior    = Enum.MouseBehavior.LockCenter
    UIS.MouseIconEnabled = false
    local _, cy, _ = Camera.CFrame:ToEulerAnglesYXZ()
    tpYaw = cy
    tpConns[1] = RunSvc.RenderStepped:Connect(function()
        if not tpEnabled then return end
        local c = Player.Character
        if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local delta = UIS:GetMouseDelta()
        tpYaw   = tpYaw   - math.rad(delta.X * 0.4)
        tpPitch = math.clamp(tpPitch - math.rad(delta.Y * 0.4), math.rad(-80), math.rad(80))
        local focus = hrp.Position + Vector3.new(0, 2, 0)
        local camCF = CFrame.new(focus) * CFrame.Angles(0, tpYaw, 0) * CFrame.Angles(tpPitch, 0, 0) * CFrame.new(0, 0, tpDistance)
        Camera.CFrame = CFrame.new(camCF.Position, focus)
        for _, part in pairs(c:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then
                part.LocalTransparencyModifier = 0.4
            end
        end
    end)
end

local function disableThirdPerson()
    tpEnabled = false
    for _, conn in pairs(tpConns) do conn:Disconnect() end
    tpConns = {}
    Camera.CameraType    = Enum.CameraType.Custom
    UIS.MouseBehavior    = Enum.MouseBehavior.Default
    UIS.MouseIconEnabled = true
    local c = Player.Character
    if c then
        for _, part in pairs(c:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then
                part.LocalTransparencyModifier = 0
            end
        end
    end
end

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == tpKey then
        if tpEnabled then disableThirdPerson() else enableThirdPerson() end
    end
end)

Player.CharacterAdded:Connect(function()
    if tpEnabled then
        task.wait(0.5)
        Camera.CameraType    = Enum.CameraType.Scriptable
        UIS.MouseBehavior    = Enum.MouseBehavior.LockCenter
        UIS.MouseIconEnabled = false
    end
end)

-- ───────────────────────────────────────────
--  SILENT WALK ENGINE
-- ───────────────────────────────────────────
local silentWalkActive = false
local silentWalkConn   = nil
local originalSpeed    = 16

local function startSilentWalk()
    if silentWalkActive then return end
    silentWalkActive = true
    local c = Player.Character
    if c then
        local hum = c:FindFirstChild("Humanoid")
        if hum then originalSpeed = hum.WalkSpeed; hum.WalkSpeed = 0 end
    end
    silentWalkConn = RunSvc.Heartbeat:Connect(function()
        local char = Player.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        if not hum then return end
        if hum.WalkSpeed ~= 0 then originalSpeed = hum.WalkSpeed; hum.WalkSpeed = 0 end
    end)
end

local function stopSilentWalk()
    if not silentWalkActive then return end
    silentWalkActive = false
    if silentWalkConn then silentWalkConn:Disconnect(); silentWalkConn = nil end
    local c = Player.Character
    if c then
        local hum = c:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = originalSpeed end
    end
end

-- ───────────────────────────────────────────
--  FAKE LAG ENGINE (range-based)
-- ───────────────────────────────────────────
local fakeLagActive          = false
local fakeLagConn            = nil
local fakeLagFramesMin       = 5
local fakeLagFramesMax       = 15
local fakeLagIntervalMin     = 10
local fakeLagIntervalMax     = 30
local fakeLagCounter         = 0
local fakeLagFrozen          = false
local fakeLagFrozenCF        = nil
local fakeLagCurrentFrames   = 10
local fakeLagCurrentInterval = 20

local function startFakeLag()
    if fakeLagActive then return end
    fakeLagActive  = true
    fakeLagCounter = 0
    fakeLagFrozen  = false
    fakeLagCurrentInterval = math.random(fakeLagIntervalMin, fakeLagIntervalMax)
    fakeLagConn = RunSvc.Heartbeat:Connect(function()
        if not fakeLagActive then return end
        local c = Player.Character
        if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        fakeLagCounter = fakeLagCounter + 1
        if not fakeLagFrozen then
            if fakeLagCounter >= fakeLagCurrentInterval then
                fakeLagCounter         = 0
                fakeLagFrozen          = true
                fakeLagFrozenCF        = hrp.CFrame
                fakeLagCurrentFrames   = math.random(fakeLagFramesMin, fakeLagFramesMax)
                fakeLagCurrentInterval = math.random(fakeLagIntervalMin, fakeLagIntervalMax)
            end
        else
            hrp.CFrame = fakeLagFrozenCF
            if fakeLagCounter >= fakeLagCurrentFrames then
                fakeLagCounter = 0
                fakeLagFrozen  = false
            end
        end
    end)
end

local function stopFakeLag()
    if not fakeLagActive then return end
    fakeLagActive = false
    fakeLagFrozen = false
    if fakeLagConn then fakeLagConn:Disconnect(); fakeLagConn = nil end
end

-- ───────────────────────────────────────────
--  ANTI-AIM + SPIN ENGINE (merged)
-- ───────────────────────────────────────────
local aaToggled = false
local aaPitch   = 90
local aaActive  = false
local spinSpeed          = 0
local spinActive         = false
local spinPaused         = false
local shootPauseDuration = 0.25
local spinAngle          = 0

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        spinPaused = true
        task.delay(shootPauseDuration, function() spinPaused = false end)
    end
end)

local masterConn
local function startMasterLoop()
    if masterConn then return end
    masterConn = RunSvc.Heartbeat:Connect(function(dt)
        local c = Player.Character
        if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local pos = hrp.CFrame.Position
        local _, cy, _ = hrp.CFrame:ToEulerAnglesYXZ()
        local spinRot = spinActive and not spinPaused and spinSpeed ~= 0
        local aaRot   = aaActive
        if spinRot then
            spinAngle = spinAngle + spinSpeed * dt
            if spinAngle >= 360 then spinAngle = spinAngle - 360 end
            cy = math.rad(spinAngle)
        end
        if spinRot or aaRot then
            hrp.CFrame = CFrame.new(pos)
                * CFrame.Angles(0, cy, 0)
                * CFrame.Angles(aaRot and math.rad(aaPitch) or 0, 0, 0)
        end
    end)
end

local function stopMasterLoop()
    if masterConn then masterConn:Disconnect(); masterConn = nil end
end

local function startAntiAim()
    aaActive = true
    startMasterLoop()
end

local function stopAntiAim()
    aaActive = false
    local c = Player.Character
    if c then
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if hrp then
            local pos = hrp.CFrame.Position
            local _, cy, _ = hrp.CFrame:ToEulerAnglesYXZ()
            hrp.CFrame = CFrame.new(pos) * CFrame.Angles(0, cy, 0)
        end
    end
    if not spinActive then stopMasterLoop() end
end

local function startSpin()
    if spinActive then return end
    spinActive = true
    startMasterLoop()
end

local function stopSpin()
    if not spinActive then return end
    spinActive = false
    spinAngle  = 0
    if not aaActive then stopMasterLoop() end
end

Player.CharacterAdded:Connect(function(char)
    char:WaitForChild("Head", 5)
    if aaToggled then startAntiAim() end
end)

-- ───────────────────────────────────────────
--  PRIORITY TARGETING ENGINE
-- ───────────────────────────────────────────
local PRIORITY_ORDER = {Priority = 1, Enemy = 2, Neutral = 3, Friendly = math.huge}

local function getBestTarget()
    local bestPlayer   = nil
    local bestPriority = math.huge
    local bestDist     = math.huge
    local myHRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr == Player then continue end
        local cat = library.get_priority(plr) or "Neutral"
        if cat == "Friendly" then continue end
        local c   = plr.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        local hum = c and c:FindFirstChild("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then continue end
        if Aim.Settings.TeamCheck and plr.Team == Player.Team then continue end
        local dist = (myHRP.Position - hrp.Position).Magnitude
        local prio = PRIORITY_ORDER[cat] or 3
        if prio < bestPriority or (prio == bestPriority and dist < bestDist) then
            bestPriority = prio
            bestDist     = dist
            bestPlayer   = plr
        end
    end
    return bestPlayer
end

local function updateAimbotBlacklist()
    Aim.Blacklisted = {}
    local best = getBestTarget()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr == Player then continue end
        local cat = library.get_priority(plr) or "Neutral"
        if cat == "Friendly" then
            table.insert(Aim.Blacklisted, plr.Name)
            continue
        end
        if best and plr ~= best then
            local bestPrio = PRIORITY_ORDER[library.get_priority(best) or "Neutral"] or 3
            local thisPrio = PRIORITY_ORDER[cat] or 3
            if bestPrio < thisPrio then
                table.insert(Aim.Blacklisted, plr.Name)
            end
        end
    end
end

RunSvc.Heartbeat:Connect(function()
    if not Aim.Settings.Enabled then return end
    updateAimbotBlacklist()
end)

-- ───────────────────────────────────────────
--  ESP ENGINE
-- ───────────────────────────────────────────
local BoxSettings = {
    Box_Color        = Color3.fromRGB(255, 0, 0),
    Box_Thickness    = 2,
    Team_Check       = false,
    Team_Color       = false,
    Autothickness    = true,
    MasterEnabled    = false,
    BoxEnabled       = false,
    DistanceEnabled  = false,
    DistanceColor    = Color3.fromRGB(255, 255, 255),
    HealthbarEnabled = false,
    HealthHigh       = Color3.fromRGB(0, 255, 0),
    HealthLow        = Color3.fromRGB(255, 0, 0),
    NamesEnabled     = false,
    NamesColor       = Color3.fromRGB(255, 255, 255),
    WeaponEnabled    = false,
    WeaponColor      = Color3.fromRGB(255, 255, 255),
}
local activeBoxes = {}

local function NewLine(color, thickness)
    local line        = Drawing.new("Line")
    line.Visible      = false
    line.From         = Vector2.new(0, 0)
    line.To           = Vector2.new(0, 0)
    line.Color        = color
    line.Thickness    = thickness
    line.Transparency = 1
    return line
end

local function NewText()
    local t        = Drawing.new("Text")
    t.Visible      = false
    t.Text         = ""
    t.Size         = 13
    t.Center       = true
    t.Outline      = true
    t.OutlineColor = Color3.fromRGB(0, 0, 0)
    t.Color        = Color3.fromRGB(255, 255, 255)
    t.Font         = Drawing.Fonts.UI
    t.Transparency = 1
    return t
end

local function Vis(lib, state)
    for _, v in pairs(lib) do v.Visible = state end
end

local function Colorize(lib, color)
    for _, v in pairs(lib) do v.Color = color end
end

local function LerpColor(c1, c2, t)
    return Color3.new(
        c1.R + (c2.R - c1.R) * t,
        c1.G + (c2.G - c1.G) * t,
        c1.B + (c2.B - c1.B) * t
    )
end

local BLACK = Color3.fromRGB(0, 0, 0)

local function RemoveBox(plr)
    local data = activeBoxes[plr]
    if not data then return end
    for _, v in pairs(data.lines) do pcall(function() v:Remove() end) end
    pcall(function() data.hpOutline:Remove()  end)
    pcall(function() data.hpBg:Remove()       end)
    pcall(function() data.hpBar:Remove()      end)
    pcall(function() data.distText:Remove()   end)
    pcall(function() data.nameText:Remove()   end)
    pcall(function() data.weaponText:Remove() end)
    pcall(function() data.oripart:Destroy()   end)
    if data.conn then data.conn:Disconnect() end
    activeBoxes[plr] = nil
end

local function StartBox(plr)
    if activeBoxes[plr] then return end
    local char = plr.Character
    if not (char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart")) then return end
    local lines = {
        TL1 = NewLine(BoxSettings.Box_Color, BoxSettings.Box_Thickness),
        TL2 = NewLine(BoxSettings.Box_Color, BoxSettings.Box_Thickness),
        TR1 = NewLine(BoxSettings.Box_Color, BoxSettings.Box_Thickness),
        TR2 = NewLine(BoxSettings.Box_Color, BoxSettings.Box_Thickness),
        BL1 = NewLine(BoxSettings.Box_Color, BoxSettings.Box_Thickness),
        BL2 = NewLine(BoxSettings.Box_Color, BoxSettings.Box_Thickness),
        BR1 = NewLine(BoxSettings.Box_Color, BoxSettings.Box_Thickness),
        BR2 = NewLine(BoxSettings.Box_Color, BoxSettings.Box_Thickness),
    }
    local hpOutline  = NewLine(BLACK, 5)
    local hpBg       = NewLine(Color3.fromRGB(30, 30, 30), 3)
    local hpBar      = NewLine(Color3.fromRGB(0, 255, 0), 3)
    local distText   = NewText()
    local nameText   = NewText()
    local weaponText = NewText()
    local oripart        = Instance.new("Part")
    oripart.Parent       = Space
    oripart.Transparency = 1
    oripart.CanCollide   = false
    oripart.Anchored     = true
    oripart.Size         = Vector3.new(1, 1, 1)
    local data = {
        lines = lines, hpOutline = hpOutline, hpBg = hpBg, hpBar = hpBar,
        distText = distText, nameText = nameText, weaponText = weaponText,
        oripart = oripart, conn = nil,
    }
    activeBoxes[plr] = data
    data.conn = RunSvc.RenderStepped:Connect(function()
        local boxOn    = BoxSettings.MasterEnabled and BoxSettings.BoxEnabled
        local distOn   = BoxSettings.MasterEnabled and BoxSettings.DistanceEnabled
        local hpOn     = BoxSettings.MasterEnabled and BoxSettings.HealthbarEnabled
        local nameOn   = BoxSettings.MasterEnabled and BoxSettings.NamesEnabled
        local weaponOn = BoxSettings.MasterEnabled and BoxSettings.WeaponEnabled
        if not boxOn and not distOn and not hpOn and not nameOn and not weaponOn then
            Vis(lines, false)
            hpOutline.Visible=false; hpBg.Visible=false; hpBar.Visible=false
            distText.Visible=false; nameText.Visible=false; weaponText.Visible=false
            return
        end
        local c = plr.Character
        local _hum = c and c:FindFirstChild("Humanoid")
        local _hrp = c and c:FindFirstChild("HumanoidRootPart")
        if not (c and _hum and _hrp and _hum.Health > 0) then
            Vis(lines, false)
            hpOutline.Visible=false; hpBg.Visible=false; hpBar.Visible=false
            distText.Visible=false; nameText.Visible=false; weaponText.Visible=false
            if not Players:FindFirstChild(plr.Name) then RemoveBox(plr) end
            return
        end
        local hrp    = _hrp
        local hum    = _hum
        local _, vis = Camera:WorldToViewportPoint(hrp.Position)
        if not vis then
            Vis(lines, false)
            hpOutline.Visible=false; hpBg.Visible=false; hpBar.Visible=false
            distText.Visible=false; nameText.Visible=false; weaponText.Visible=false
            return
        end
        local myHRP   = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        local studs   = myHRP and math.floor((myHRP.Position - hrp.Position).Magnitude) or 0
        local camDist = (Camera.CFrame.p - hrp.Position).Magnitude
        local hpRatio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        oripart.Size   = Vector3.new(hrp.Size.X, hrp.Size.Y * 1.5, hrp.Size.Z)
        oripart.CFrame = CFrame.new(hrp.CFrame.Position, Camera.CFrame.Position)
        local SX, SY = oripart.Size.X, oripart.Size.Y
        local TL = Camera:WorldToViewportPoint((oripart.CFrame * CFrame.new( SX,  SY, 0)).p)
        local TR = Camera:WorldToViewportPoint((oripart.CFrame * CFrame.new(-SX,  SY, 0)).p)
        local BL = Camera:WorldToViewportPoint((oripart.CFrame * CFrame.new( SX, -SY, 0)).p)
        local BR = Camera:WorldToViewportPoint((oripart.CFrame * CFrame.new(-SX, -SY, 0)).p)
        if boxOn then
            if BoxSettings.Team_Check then
                Colorize(lines, plr.TeamColor == Player.TeamColor and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0))
            elseif BoxSettings.Team_Color then
                Colorize(lines, plr.TeamColor.Color)
            end
            local offset = math.clamp(1 / camDist * 750, 2, 300)
            lines.TL1.From=Vector2.new(TL.X,TL.Y); lines.TL1.To=Vector2.new(TL.X+offset,TL.Y)
            lines.TL2.From=Vector2.new(TL.X,TL.Y); lines.TL2.To=Vector2.new(TL.X,TL.Y+offset)
            lines.TR1.From=Vector2.new(TR.X,TR.Y); lines.TR1.To=Vector2.new(TR.X-offset,TR.Y)
            lines.TR2.From=Vector2.new(TR.X,TR.Y); lines.TR2.To=Vector2.new(TR.X,TR.Y+offset)
            lines.BL1.From=Vector2.new(BL.X,BL.Y); lines.BL1.To=Vector2.new(BL.X+offset,BL.Y)
            lines.BL2.From=Vector2.new(BL.X,BL.Y); lines.BL2.To=Vector2.new(BL.X,BL.Y-offset)
            lines.BR1.From=Vector2.new(BR.X,BR.Y); lines.BR1.To=Vector2.new(BR.X-offset,BR.Y)
            lines.BR2.From=Vector2.new(BR.X,BR.Y); lines.BR2.To=Vector2.new(BR.X,BR.Y-offset)
            if BoxSettings.Autothickness then
                local t = math.clamp(1 / camDist * 100, 1, 4)
                for _, ln in pairs(lines) do ln.Thickness = t end
            else
                for _, ln in pairs(lines) do ln.Thickness = BoxSettings.Box_Thickness end
            end
            Vis(lines, true)
        else Vis(lines, false) end
        if hpOn then
            local barGap       = math.clamp(1 / camDist * 60, 2, 6)
            local barX         = math.min(TL.X, BL.X) - barGap
            local barTop       = math.min(TL.Y, TR.Y)
            local barBottom    = math.max(BL.Y, BR.Y)
            local barHeight    = barBottom - barTop
            local barThickness = math.clamp(1 / camDist * 80, 2, 5)
            local fillTop      = barBottom - (barHeight * hpRatio)
            local hpColor      = LerpColor(BoxSettings.HealthLow, BoxSettings.HealthHigh, hpRatio)
            hpOutline.From=Vector2.new(barX,barTop); hpOutline.To=Vector2.new(barX,barBottom)
            hpOutline.Thickness=barThickness+2; hpOutline.Visible=true
            hpBg.From=Vector2.new(barX,barTop); hpBg.To=Vector2.new(barX,barBottom)
            hpBg.Thickness=barThickness; hpBg.Visible=true
            hpBar.From=Vector2.new(barX,fillTop); hpBar.To=Vector2.new(barX,barBottom)
            hpBar.Color=hpColor; hpBar.Thickness=barThickness; hpBar.Visible=hpRatio>0
        else hpOutline.Visible=false; hpBg.Visible=false; hpBar.Visible=false end
        local centreX  = (BL.X + BR.X) / 2
        local bottomY  = math.max(BL.Y, BR.Y)
        local fontSize = math.clamp(13 - (studs / 500) * 7, 6, 13)
        local gap      = math.clamp(1 / camDist * 120, 2, 10)
        if distOn then
            distText.Text=studs.." studs"; distText.Size=fontSize
            distText.Color=BoxSettings.DistanceColor
            distText.Position=Vector2.new(centreX,bottomY+gap); distText.Visible=true
        else distText.Visible=false end
        if weaponOn then
            local tool = c:FindFirstChildOfClass("Tool")
            if tool then
                local weaponY = distOn and (bottomY+gap+fontSize+2) or (bottomY+gap)
                weaponText.Text="⚔ "..tool.Name; weaponText.Size=fontSize
                weaponText.Color=BoxSettings.WeaponColor
                weaponText.Position=Vector2.new(centreX,weaponY); weaponText.Visible=true
            else weaponText.Visible=false end
        else weaponText.Visible=false end
        if nameOn then
            local head = c:FindFirstChild("Head")
            if head then
                local headPos, headVis = Camera:WorldToViewportPoint(head.Position)
                if headVis then
                    nameText.Text=plr.Name; nameText.Size=fontSize
                    nameText.Color=BoxSettings.NamesColor
                    nameText.Position=Vector2.new(headPos.X,headPos.Y-(fontSize+gap+10))
                    nameText.Visible=true
                else nameText.Visible=false end
            end
        else nameText.Visible=false end
    end)
end

local function StartAllBoxes()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player then coroutine.wrap(StartBox)(plr) end
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        if BoxSettings.MasterEnabled then coroutine.wrap(StartBox)(plr) end
    end)
end)

Players.PlayerRemoving:Connect(function(plr) RemoveBox(plr) end)

-- ───────────────────────────────────────────
--  MAIN WINDOW
-- ───────────────────────────────────────────
local window = library:window({
    name = os.date('Jeffery Main |  - %b %d %Y'),
    size = dim2(0, 750, 0, 782)
})

local Aiming  = window:tab({name = "Aiming"})
local Misc    = window:tab({name = "Misc"})
local Visuals = window:tab({name = "Visuals"})
local Rage    = window:tab({name = "Rage"})

-- ── Misc tab ──────────────────────────────
local mcol     = Misc:column()
local mscripts = mcol:section({name = "Scripts", toggle = false})

mscripts:button_holder({})
mscripts:button({name="Infinite Yield",callback=function()
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end)
    if not ok then warn("[Infinite Yield] Failed to load: " .. tostring(err)) end
end})

mscripts:button_holder({})
mscripts:button({name="Tornado",callback=function()
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Lukashub-coder/Super-ring-V5/refs/heads/main/By%20lukas!!"))()
    end)
    if not ok then warn("[Tornado] Failed to load: " .. tostring(err)) end
end})

mscripts:button_holder({})
mscripts:button({name="Unlock All Skins",callback=function()
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/akucursed/RobloxScripts/refs/heads/main/CombatSurf_UnlockAll_Skins"))()
    end)
    if not ok then warn("[Unlock All Skins] Failed to load: " .. tostring(err)) end
end})

-- ── Aiming tab ────────────────────────────
local column = Aiming:column()
local selec, lock, triggerbot = column:multi_section({names = {"Selection", "Lock", "Triggerbot"}})

    selec:toggle({name="Enabled",flag="aim_enabled",callback=function(s) Aim.Settings.Enabled=s end}):keybind({name="Aimbot Key",flag="aim_key",callback=function(k) Aim.Settings.TriggerKey=k end})
    selec:toggle({name="Toggle Mode",flag="aim_toggle",callback=function(s) Aim.Settings.Toggle=s end})
    selec:toggle({name="Team Check",flag="aim_teamcheck",callback=function(s) Aim.Settings.TeamCheck=s end})
    selec:toggle({name="Wall Check",flag="aim_wallcheck",callback=function(s) Aim.Settings.WallCheck=s end})
    selec:toggle({name="Alive Check",flag="aim_alivecheck",callback=function(s) Aim.Settings.AliveCheck=s end})
    selec:dropdown({name="Lock Part",flag="aim_lockpart",items={"Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso"},default="Head",callback=function(v) Aim.Settings.LockPart=v end})
    selec:dropdown({name="Lock Mode",flag="aim_lockmode",items={"CFrame","mousemoverel"},default="CFrame",callback=function(v) local m={CFrame=1,mousemoverel=2} Aim.Settings.LockMode=m[v] end})
    selec:slider({name="Sensitivity",flag="aim_sensitivity",min=0,max=1,default=0,interval=0.01,callback=function(v) Aim.Settings.Sensitivity=v end})
    selec:slider({name="Mouse Sensitivity",flag="aim_sensitivity2",min=0.1,max=5,default=1,interval=0.1,callback=function(v) Aim.Settings.Sensitivity2=v end})
    selec:toggle({name="Offset To Move Direction",flag="aim_offset",callback=function(s) Aim.Settings.OffsetToMoveDirection=s end})
    selec:slider({name="Offset Increment",flag="aim_offsetamt",min=0,max=100,default=15,interval=1,callback=function(v) Aim.Settings.OffsetIncrement=v end})

    lock:toggle({name="Show FOV",flag="fov_visible",callback=function(s) Aim.FOVSettings.Visible=s end})
    lock:toggle({name="FOV Filled",flag="fov_filled",callback=function(s) Aim.FOVSettings.Filled=s end})
    lock:toggle({name="FOV Rainbow",flag="fov_rainbow",callback=function(s) Aim.FOVSettings.RainbowColor=s end})
    lock:colorpicker({name="FOV Color",flag="fov_color",color=hex("#FFFFFF"),callback=function(c) Aim.FOVSettings.Color=c end})
    lock:colorpicker({name="FOV Outline Color",flag="fov_outline_color",color=hex("#000000"),callback=function(c) Aim.FOVSettings.OutlineColor=c end})
    lock:colorpicker({name="FOV Locked Color",flag="fov_locked_color",color=hex("#FF9696"),callback=function(c) Aim.FOVSettings.LockedColor=c end})
    lock:slider({name="FOV Radius",flag="fov_radius",min=10,max=1000,default=90,interval=1,callback=function(v) Aim.FOVSettings.Radius=v end})
    lock:slider({name="FOV Thickness",flag="fov_thickness",min=1,max=10,default=1,interval=1,callback=function(v) Aim.FOVSettings.Thickness=v end})
    lock:slider({name="FOV Transparency",flag="fov_transparency",min=0,max=1,default=1,interval=0.01,callback=function(v) Aim.FOVSettings.Transparency=v end})
    lock:slider({name="FOV Sides",flag="fov_sides",min=3,max=100,default=60,interval=1,callback=function(v) Aim.FOVSettings.NumSides=v end})

    triggerbot:toggle({name="Enabled",flag="tb_enabled",callback=function(s) Aim.Settings.Enabled=s end})

-- ── Visuals tab ───────────────────────────
local esp
local function update_elements()
    if esp and esp.refresh_elements then esp.refresh_elements() end
end

local vcol    = Visuals:column()
local section = vcol:section({name = "General", toggle = false})

section:toggle({name="Enabled",flag="Enabled",callback=function(state)
    BoxSettings.MasterEnabled = state
    if state then StartAllBoxes()
    else
        for _, data in pairs(activeBoxes) do
            Vis(data.lines,false)
            data.hpOutline.Visible=false;data.hpBg.Visible=false;data.hpBar.Visible=false
            data.distText.Visible=false;data.nameText.Visible=false;data.weaponText.Visible=false
        end
    end
    update_elements()
end})

section:toggle({name="Names",flag="Names",callback=function(s) BoxSettings.NamesEnabled=s if s and BoxSettings.MasterEnabled then StartAllBoxes() end update_elements() end}):colorpicker({flag="Name_Color",color=hex("#FFFFFF"),callback=function(c) BoxSettings.NamesColor=c for _,d in pairs(activeBoxes) do d.nameText.Color=c end update_elements() end})

local boxToggle = section:toggle({name="Boxes",flag="Boxes",callback=function(s) BoxSettings.BoxEnabled=s if s and BoxSettings.MasterEnabled then StartAllBoxes() elseif not s then for _,d in pairs(activeBoxes) do Vis(d.lines,false) end end update_elements() end})
boxToggle:colorpicker({name="Box Color",flag="Box_Color",callback=function(c) BoxSettings.Box_Color=c for _,d in pairs(activeBoxes) do Colorize(d.lines,c) end update_elements() end})
section:dropdown({name="Box Type",flag="Box_Type",items={"Corner","Full"},default="Corner",callback=update_elements})

local hpToggle = section:toggle({name="Healthbar",flag="Healthbar",callback=function(s) BoxSettings.HealthbarEnabled=s if s and BoxSettings.MasterEnabled then StartAllBoxes() elseif not s then for _,d in pairs(activeBoxes) do d.hpOutline.Visible=false;d.hpBg.Visible=false;d.hpBar.Visible=false end end update_elements() end})
hpToggle:colorpicker({name="High HP Color",flag="Health_High",color=hex("#00FF00"),callback=function(c) BoxSettings.HealthHigh=c update_elements() end})
hpToggle:colorpicker({name="Low HP Color",flag="Health_Low",color=hex("#FF0000"),callback=function(c) BoxSettings.HealthLow=c update_elements() end})

section:toggle({name="Distance",flag="Distance",callback=function(s) BoxSettings.DistanceEnabled=s if s and BoxSettings.MasterEnabled then StartAllBoxes() elseif not s then for _,d in pairs(activeBoxes) do d.distText.Visible=false end end update_elements() end}):colorpicker({name="Distance Color",flag="Distance_Color",color=hex("#FFFFFF"),callback=function(c) BoxSettings.DistanceColor=c for _,d in pairs(activeBoxes) do d.distText.Color=c end update_elements() end})

section:toggle({name="Weapon",flag="Weapon",callback=function(s) BoxSettings.WeaponEnabled=s if s and BoxSettings.MasterEnabled then StartAllBoxes() elseif not s then for _,d in pairs(activeBoxes) do d.weaponText.Visible=false end end update_elements() end}):colorpicker({name="Weapon Color",flag="Weapon_Color",color=hex("#FFFFFF"),callback=function(c) BoxSettings.WeaponColor=c for _,d in pairs(activeBoxes) do d.weaponText.Color=c end update_elements() end})

local chamsToggle = section:toggle({name="Chams",flag="Chams",tooltip="Highlights players through walls",callback=function(s) ChamsSettings.Enabled=s RefreshChams() update_elements() end})
chamsToggle:colorpicker({name="Enemy Color",flag="Chams_Enemy",color=hex("#B42828"),callback=function(c) ChamsSettings.EnemyColor=c RefreshChams() end})
chamsToggle:colorpicker({name="Ally Color",flag="Chams_Ally",color=hex("#28B450"),callback=function(c) ChamsSettings.AllyColor=c RefreshChams() end})
section:toggle({name="Chams Team Check",flag="Chams_TeamCheck",callback=function(s) ChamsSettings.TeamCheck=s RefreshChams() end})
section:slider({name="Chams Fill Transparency",flag="Chams_FillTr",min=0,max=1,default=0.5,interval=0.01,callback=function(v) ChamsSettings.FillTr=v RefreshChams() end})
section:slider({name="Chams Outline Transparency",flag="Chams_OutTr",min=0,max=1,default=0.1,interval=0.01,callback=function(v) ChamsSettings.OutTr=v RefreshChams() end})

local catChamsToggle = section:toggle({name="Category Chams",flag="CatChams",tooltip="Highlights players based on priority category",callback=function(s) CatChamsSettings.Enabled=s RefreshCatChams() update_elements() end})
catChamsToggle:colorpicker({name="Priority Color",flag="CatChams_Priority",color=hex("#FFFF00"),callback=function(c) CatChamsSettings.PriorityColor=c RefreshCatChams() end})
catChamsToggle:colorpicker({name="Enemy Color",flag="CatChams_Enemy",color=hex("#FF0000"),callback=function(c) CatChamsSettings.EnemyColor=c RefreshCatChams() end})
catChamsToggle:colorpicker({name="Neutral Color",flag="CatChams_Neutral",color=hex("#FFFFFF"),callback=function(c) CatChamsSettings.NeutralColor=c RefreshCatChams() end})
catChamsToggle:colorpicker({name="Friendly Color",flag="CatChams_Friendly",color=hex("#00FF64"),callback=function(c) CatChamsSettings.FriendlyColor=c RefreshCatChams() end})
section:toggle({name="Show Friendly Chams",flag="CatChams_ShowFriendly",callback=function(s) CatChamsSettings.ShowFriendly=s RefreshCatChams() end})
section:slider({name="Category Fill Transparency",flag="CatChams_FillTr",min=0,max=1,default=0.5,interval=0.01,callback=function(v) CatChamsSettings.FillTr=v RefreshCatChams() end})
section:slider({name="Category Outline Transparency",flag="CatChams_OutTr",min=0,max=1,default=0.1,interval=0.01,callback=function(v) CatChamsSettings.OutTr=v RefreshCatChams() end})

local btToggle = section:toggle({name="Backtrack",flag="Backtrack",tooltip="Shows where player was X ms ago",callback=function(s) BacktrackSettings.Enabled=s if s then EnableBacktrack() else DisableBacktrack() end update_elements() end})
btToggle:colorpicker({name="Backtrack Color",flag="Backtrack_Color",color=hex("#FFA500"),callback=function(c) BacktrackSettings.Color=c end})
section:slider({name="Backtrack MS",flag="Backtrack_MS",min=0,max=200,default=100,interval=1,suffix="ms",callback=function(v) BacktrackSettings.Ms=v end})

local tpToggle = section:toggle({name="Third Person",flag="ThirdPerson",tooltip="Toggle with keybind (default V)",callback=function(state)
    if state then enableThirdPerson() else disableThirdPerson() end
    update_elements()
end})
tpToggle:keybind({name="Third Person Key",flag="tp_key",key=Enum.KeyCode.V,callback=function(keydata)
    if keydata and keydata.key then tpKey = keydata.key end
end})
section:slider({name="Camera Distance",flag="tp_distance",min=5,max=50,default=15,interval=1,suffix=" st",callback=function(value)
    tpDistance = value
end})

esp = window.esp_section:esp_preview({})

-- ── Rage tab ──────────────────────────────
local rcol = Rage:column()
local antiaim, spin, silentwalk, fakelag = rcol:multi_section({names = {"Anti-Aim", "Spin", "Silent Walk", "Fake Lag"}})

    antiaim:toggle({name="Enabled",flag="aa_enabled",tooltip="Tilts character forward so head goes inside torso",callback=function(state) aaToggled=state if state then startAntiAim() else stopAntiAim() end end})
    antiaim:slider({name="Tilt Amount",flag="aa_pitch",min=0,max=60,default=0,interval=0.1,suffix="°",callback=function(value) aaPitch=value end})

    spin:toggle({name="Enabled",flag="spin_enabled",tooltip="Spins HRP. Pauses on shoot.",callback=function(state) if state then startSpin() else stopSpin() end end})
    spin:slider({name="Speed",flag="spin_speed",min=0,max=2700,default=0,interval=1,suffix="°/s",callback=function(value) spinSpeed=value if value>0 then startSpin() else stopSpin() end end})
    spin:slider({name="Shoot Pause",flag="spin_pause",min=0,max=1,default=0.25,interval=0.01,suffix="s",callback=function(value) shootPauseDuration=value end})

    silentwalk:toggle({name="Enabled",flag="sw_enabled",tooltip="Sets WalkSpeed to 0 on server so you appear frozen to others",callback=function(state) if state then startSilentWalk() else stopSilentWalk() end end})

    fakelag:toggle({name="Enabled",flag="fl_enabled",tooltip="Randomly freezes your position creating stutter effect",callback=function(state) if state then startFakeLag() else stopFakeLag() end end})
    fakelag:slider({name="Freeze Min",flag="fl_frames_min",min=1,max=30,default=5,interval=1,callback=function(value) fakeLagFramesMin=value end})
    fakelag:slider({name="Freeze Max",flag="fl_frames_max",min=1,max=30,default=15,interval=1,callback=function(value) fakeLagFramesMax=value end})
    fakelag:slider({name="Interval Min",flag="fl_interval_min",min=5,max=60,default=10,interval=1,callback=function(value) fakeLagIntervalMin=value end})
    fakelag:slider({name="Interval Max",flag="fl_interval_max",min=5,max=60,default=30,interval=1,callback=function(value) fakeLagIntervalMax=value end})

Aiming.open_tab()

-- ───────────────────────────────────────────
--  Init
-- ───────────────────────────────────────────
Aim.Load()

-- ───────────────────────────────────────────
--  DUMMIES VS NOOBS TAB
-- ───────────────────────────────────────────
local TweenService_NPC = game:GetService("TweenService")

local NPC_SET = {
    Infantry=true,  Cloaker=true,    Shielder=true,  Saboteur=true,
    Grenadier=true, Jetpacker=true,  Gunner=true,    Sniper=true,
    Engineer=true,  Sentry=true,     Teleporter=true,
    Ranger=true,    APU=true,        Tank=true,       Platform=true,
    Tranquilizer=true, Medic=true,   Administrator=true,
    Informant=true, Confidant=true,  Agitator=true,  Agreement=true,
    Jagant=true,    Bombardier=true, Combatant=true, Dreadnought=true,
    Daedalus=true,  Tempest=true,    Fusilier=true,  Lelantos=true,
    Gaia=true,      Hermes=true,     Prometheus=true,
    Achilles=true,  Trident=true,    Sparta=true,
    Ares=true,      Mastermind=true, Chassis=true,
}

local BOSS_SET = {
    Daedalus=true, Tempest=true, Fusilier=true, Lelantos=true,
    Gaia=true,     Hermes=true,  Prometheus=true,
    Achilles=true, Trident=true, Sparta=true,
    Ares=true,     Mastermind=true, Chassis=true,
}

local CAT_COLOR = {
    Infantry=Color3.fromRGB(100,220,100),   Cloaker=Color3.fromRGB(100,220,100),
    Shielder=Color3.fromRGB(100,220,100),   Saboteur=Color3.fromRGB(100,220,100),
    Grenadier=Color3.fromRGB(255,220,0),    Jetpacker=Color3.fromRGB(255,220,0),
    Gunner=Color3.fromRGB(255,220,0),       Sniper=Color3.fromRGB(255,220,0),
    Engineer=Color3.fromRGB(0,200,255),     Sentry=Color3.fromRGB(0,200,255),
    Teleporter=Color3.fromRGB(0,200,255),
    Ranger=Color3.fromRGB(255,140,0),       APU=Color3.fromRGB(255,140,0),
    Tank=Color3.fromRGB(255,140,0),         Platform=Color3.fromRGB(255,140,0),
    Tranquilizer=Color3.fromRGB(180,0,255), Medic=Color3.fromRGB(180,0,255),
    Administrator=Color3.fromRGB(180,0,255),
    Informant=Color3.fromRGB(255,100,200),  Confidant=Color3.fromRGB(255,100,200),
    Agitator=Color3.fromRGB(255,100,200),   Agreement=Color3.fromRGB(255,100,200),
    Jagant=Color3.fromRGB(255,100,200),     Bombardier=Color3.fromRGB(255,100,200),
    Combatant=Color3.fromRGB(255,100,200),  Dreadnought=Color3.fromRGB(255,100,200),
    Daedalus=Color3.fromRGB(255,50,50),     Tempest=Color3.fromRGB(255,50,50),
    Fusilier=Color3.fromRGB(255,50,50),     Lelantos=Color3.fromRGB(255,50,50),
    Gaia=Color3.fromRGB(255,50,50),         Hermes=Color3.fromRGB(255,50,50),
    Prometheus=Color3.fromRGB(255,50,50),   Achilles=Color3.fromRGB(255,50,50),
    Trident=Color3.fromRGB(255,50,50),      Sparta=Color3.fromRGB(255,50,50),
    Ares=Color3.fromRGB(255,0,0),           Mastermind=Color3.fromRGB(255,0,0),
    Chassis=Color3.fromRGB(255,0,0),
}

local NpcEsp = {
    Enabled=false, BoxEnabled=false, NamesEnabled=false,
    HealthEnabled=false, DistEnabled=false, ChamsEnabled=false,
    CategoryColors=true, DefaultColor=Color3.fromRGB(255,80,80),
    FillTr=0.5, OutTr=0.1,
}

local NpcAim = {
    Enabled=false, Toggle=false, BossPriority=true,
    LockPart="HumanoidRootPart", LockMode=1,
    FovRadius=150, Sensitivity=0, Sensitivity2=3.5,
    TriggerKey=Enum.UserInputType.MouseButton2,
}

-- ── Cached NPC list ───────────────────────
local cachedNpcs      = {}
local npcCacheAddConn = nil
local npcCacheRemConn = nil

local function BuildNpcCache()
    cachedNpcs = {}
    for _, desc in ipairs(Space:GetDescendants()) do
        if desc:IsA("Model") and NPC_SET[desc.Name] then
            cachedNpcs[desc] = true
        end
    end
end

local function StartNpcCache()
    BuildNpcCache()
    if not npcCacheAddConn then
        npcCacheAddConn = Space.DescendantAdded:Connect(function(desc)
            if desc:IsA("Model") and NPC_SET[desc.Name] then
                cachedNpcs[desc] = true
                if NpcEsp.ChamsEnabled then
                    task.wait(0.1)
                    ApplyNpcChams(desc)
                end
            end
        end)
    end
    if not npcCacheRemConn then
        npcCacheRemConn = Space.DescendantRemoving:Connect(function(desc)
            if cachedNpcs[desc] then
                cachedNpcs[desc] = nil
                if activeNpcBoxes[desc] then DestroyNpcBox(desc) end
            end
        end)
    end
end

-- ── Helpers ───────────────────────────────
local function NpcColor(model)
    if NpcEsp.CategoryColors then return CAT_COLOR[model.Name] or NpcEsp.DefaultColor end
    return NpcEsp.DefaultColor
end

local function GetNpcRoot(model)
    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("Torso")
        or model.PrimaryPart
end

-- ── Chams ─────────────────────────────────
local NPC_CHAMS_TAG = "JefferyDvNChams"

local function ApplyNpcChams(model)
    if not model or not model.Parent then return end
    if not NpcEsp.ChamsEnabled then return end
    if model:FindFirstChild(NPC_CHAMS_TAG) then return end
    local col = NpcColor(model)
    local h = Instance.new("Highlight")
    h.Name=NPC_CHAMS_TAG; h.FillColor=col; h.OutlineColor=col
    h.FillTransparency=NpcEsp.FillTr; h.OutlineTransparency=NpcEsp.OutTr
    h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee=model; h.Parent=model
end

local function RemoveNpcChams(model)
    local h = model and model:FindFirstChild(NPC_CHAMS_TAG)
    if h then h:Destroy() end
end

local function RefreshNpcChams()
    for model in pairs(cachedNpcs) do
        RemoveNpcChams(model)
        if NpcEsp.ChamsEnabled then ApplyNpcChams(model) end
    end
end

local function EnableNpcChams()
    for model in pairs(cachedNpcs) do ApplyNpcChams(model) end
end

local function DisableNpcChams()
    for model in pairs(cachedNpcs) do RemoveNpcChams(model) end
end

-- ── ESP ───────────────────────────────────
local activeNpcBoxes = {}
local npcEspConn     = nil

local function MkLine(col)
    local l=Drawing.new("Line"); l.Visible=false
    l.Color=col or Color3.new(1,1,1); l.Thickness=1; l.Transparency=1
    return l
end
local function MkText()
    local t=Drawing.new("Text"); t.Visible=false; t.Size=13; t.Center=true
    t.Outline=true; t.OutlineColor=Color3.new(0,0,0)
    t.Color=Color3.new(1,1,1); t.Font=Drawing.Fonts.UI; t.Transparency=1
    return t
end

local function GetOrMakeNpcBox(model)
    if activeNpcBoxes[model] then return activeNpcBoxes[model] end
    local c = NpcColor(model)
    local lines = {
        TL1=MkLine(c),TL2=MkLine(c),TR1=MkLine(c),TR2=MkLine(c),
        BL1=MkLine(c),BL2=MkLine(c),BR1=MkLine(c),BR2=MkLine(c),
    }
    local hpOut=MkLine(Color3.new(0,0,0)); hpOut.Thickness=5
    local hpBg=MkLine(Color3.fromRGB(30,30,30)); hpBg.Thickness=3
    local hpBar=MkLine(Color3.fromRGB(0,255,0)); hpBar.Thickness=3
    local ori=Instance.new("Part")
    ori.Anchored=true; ori.CanCollide=false; ori.CastShadow=false
    ori.Transparency=1; ori.Size=Vector3.new(4,6,0.1)
    ori.CFrame=CFrame.new(0,-9999,0); ori.Parent=Space
    local data={lines=lines,hpOut=hpOut,hpBg=hpBg,hpBar=hpBar,
                nameText=MkText(),distText=MkText(),ori=ori}
    activeNpcBoxes[model]=data
    return data
end

local function HideNpcBox(d)
    if not d then return end
    for _,l in pairs(d.lines) do l.Visible=false end
    d.hpOut.Visible=false; d.hpBg.Visible=false; d.hpBar.Visible=false
    d.nameText.Visible=false; d.distText.Visible=false
end

function DestroyNpcBox(model)
    local d=activeNpcBoxes[model]
    if not d then return end
    for _,l in pairs(d.lines) do pcall(function() l:Remove() end) end
    pcall(function() d.hpOut:Remove() end); pcall(function() d.hpBg:Remove() end)
    pcall(function() d.hpBar:Remove() end); pcall(function() d.nameText:Remove() end)
    pcall(function() d.distText:Remove() end); pcall(function() d.ori:Destroy() end)
    activeNpcBoxes[model]=nil
end

local function EnableNpcEsp()
    if npcEspConn then return end
    StartNpcCache()
    npcEspConn = RunSvc.RenderStepped:Connect(function()
        if not NpcEsp.Enabled then
            for _,d in pairs(activeNpcBoxes) do HideNpcBox(d) end
            return
        end
        local myHRP  = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        local camPos = Camera.CFrame.p
        for model in pairs(cachedNpcs) do
            local hrp = GetNpcRoot(model)
            local hum = model:FindFirstChildOfClass("Humanoid")
            -- FIX: destroy box + remove chams + evict from cache on death
            if not hrp or not hum or hum.Health <= 0 then
                if activeNpcBoxes[model] then DestroyNpcBox(model) end
                RemoveNpcChams(model)
                cachedNpcs[model] = nil
                continue
            end
            local _, vis = Camera:WorldToViewportPoint(hrp.Position)
            local d = GetOrMakeNpcBox(model)
            if not vis then HideNpcBox(d); continue end
            local col     = NpcColor(model)
            local camDist = (camPos - hrp.Position).Magnitude
            local studs   = myHRP and math.floor((myHRP.Position - hrp.Position).Magnitude) or 0
            local hpRatio = math.clamp(hum.Health / math.max(hum.MaxHealth,1), 0, 1)
            d.ori.CFrame = CFrame.new(hrp.CFrame.Position, camPos)
            local SX,SY = 2, 3
            local TL=Camera:WorldToViewportPoint((d.ori.CFrame*CFrame.new( SX, SY,0)).p)
            local TR=Camera:WorldToViewportPoint((d.ori.CFrame*CFrame.new(-SX, SY,0)).p)
            local BL=Camera:WorldToViewportPoint((d.ori.CFrame*CFrame.new( SX,-SY,0)).p)
            local BR=Camera:WorldToViewportPoint((d.ori.CFrame*CFrame.new(-SX,-SY,0)).p)
            if NpcEsp.BoxEnabled then
                local off=math.clamp(1/camDist*750,2,300)
                local th=math.clamp(1/camDist*100,1,4)
                for _,ln in pairs(d.lines) do ln.Color=col; ln.Thickness=th end
                d.lines.TL1.From=Vector2.new(TL.X,TL.Y); d.lines.TL1.To=Vector2.new(TL.X+off,TL.Y)
                d.lines.TL2.From=Vector2.new(TL.X,TL.Y); d.lines.TL2.To=Vector2.new(TL.X,TL.Y+off)
                d.lines.TR1.From=Vector2.new(TR.X,TR.Y); d.lines.TR1.To=Vector2.new(TR.X-off,TR.Y)
                d.lines.TR2.From=Vector2.new(TR.X,TR.Y); d.lines.TR2.To=Vector2.new(TR.X,TR.Y+off)
                d.lines.BL1.From=Vector2.new(BL.X,BL.Y); d.lines.BL1.To=Vector2.new(BL.X+off,BL.Y)
                d.lines.BL2.From=Vector2.new(BL.X,BL.Y); d.lines.BL2.To=Vector2.new(BL.X,BL.Y-off)
                d.lines.BR1.From=Vector2.new(BR.X,BR.Y); d.lines.BR1.To=Vector2.new(BR.X-off,BR.Y)
                d.lines.BR2.From=Vector2.new(BR.X,BR.Y); d.lines.BR2.To=Vector2.new(BR.X,BR.Y-off)
                for _,ln in pairs(d.lines) do ln.Visible=true end
            else for _,ln in pairs(d.lines) do ln.Visible=false end end
            if NpcEsp.HealthEnabled then
                local barGap=math.clamp(1/camDist*60,2,6)
                local barX=math.min(TL.X,BL.X)-barGap
                local barTop=math.min(TL.Y,TR.Y); local barBot=math.max(BL.Y,BR.Y)
                local bt=math.clamp(1/camDist*80,2,5)
                local fillTop=barBot-((barBot-barTop)*hpRatio)
                local hpCol=LerpColor(Color3.fromRGB(255,0,0),Color3.fromRGB(0,255,0),hpRatio)
                d.hpOut.From=Vector2.new(barX,barTop); d.hpOut.To=Vector2.new(barX,barBot); d.hpOut.Thickness=bt+2; d.hpOut.Visible=true
                d.hpBg.From=Vector2.new(barX,barTop);  d.hpBg.To=Vector2.new(barX,barBot);  d.hpBg.Thickness=bt;   d.hpBg.Visible=true
                d.hpBar.From=Vector2.new(barX,fillTop); d.hpBar.To=Vector2.new(barX,barBot); d.hpBar.Color=hpCol; d.hpBar.Thickness=bt; d.hpBar.Visible=hpRatio>0
            else d.hpOut.Visible=false; d.hpBg.Visible=false; d.hpBar.Visible=false end
            local cx=(BL.X+BR.X)/2; local botY=math.max(BL.Y,BR.Y)
            local fs=math.clamp(13-(studs/500)*7,6,13)
            local gap=math.clamp(1/camDist*120,2,10)
            if NpcEsp.NamesEnabled then
                d.nameText.Text=model.Name; d.nameText.Color=col; d.nameText.Size=fs
                d.nameText.Position=Vector2.new(cx,math.min(TL.Y,TR.Y)-fs-gap); d.nameText.Visible=true
            else d.nameText.Visible=false end
            if NpcEsp.DistEnabled then
                d.distText.Text=studs.." studs"; d.distText.Color=Color3.new(1,1,1); d.distText.Size=fs
                d.distText.Position=Vector2.new(cx,botY+gap); d.distText.Visible=true
            else d.distText.Visible=false end
        end
    end)
end

local function DisableNpcEsp()
    if npcEspConn then npcEspConn:Disconnect(); npcEspConn=nil end
    for model,d in pairs(activeNpcBoxes) do HideNpcBox(d); DestroyNpcBox(model) end
end

-- ── NPC Aimbot ────────────────────────────
local npcAimbotRunning=false; local npcAimbotLocked=nil
local npcAimbotConn=nil; local npcAimIBConn=nil; local npcAimIEConn=nil
local npcAimTyping=false

local npcFovCircle  = Drawing.new("Circle")
local npcFovOutline = Drawing.new("Circle")
for _,c in pairs({npcFovCircle,npcFovOutline}) do
    c.Visible=false; c.NumSides=60; c.Filled=false; c.Transparency=1
end

UIS.TextBoxFocused:Connect(function()       npcAimTyping=true  end)
UIS.TextBoxFocusReleased:Connect(function() npcAimTyping=false end)

local function GetBestNpc()
    local mouse=UIS:GetMouseLocation()
    local best,bestDist,bestTier=nil,NpcAim.FovRadius,math.huge
    for model in pairs(cachedNpcs) do
        local hrp=model:FindFirstChild(NpcAim.LockPart) or GetNpcRoot(model)
        local hum=model:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health<=0 then continue end
        local sp,onScreen=Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then continue end
        local dist=(mouse-Vector2.new(sp.X,sp.Y)).Magnitude
        local tier=(NpcAim.BossPriority and BOSS_SET[model.Name]) and 1 or 2
        if tier<bestTier or (tier==bestTier and dist<bestDist) then
            bestTier=tier; bestDist=dist; best=model
        end
    end
    return best
end

local function EnableNpcAimbot()
    if npcAimbotConn then return end
    StartNpcCache()
    npcAimbotConn = RunSvc.RenderStepped:Connect(function()
        if NpcAim.Enabled then
            local mp=UIS:GetMouseLocation()
            npcFovOutline.Visible=true; npcFovOutline.Position=mp
            npcFovOutline.Radius=NpcAim.FovRadius; npcFovOutline.Thickness=2; npcFovOutline.Color=Color3.new(0,0,0)
            npcFovCircle.Visible=true; npcFovCircle.Position=mp
            npcFovCircle.Radius=NpcAim.FovRadius; npcFovCircle.Thickness=1
            npcFovCircle.Color=npcAimbotLocked and Color3.fromRGB(255,100,100) or Color3.new(1,1,1)
        else
            npcFovCircle.Visible=false; npcFovOutline.Visible=false
        end
        if not npcAimbotRunning or not NpcAim.Enabled then return end
        if npcAimbotLocked then
            if not npcAimbotLocked.Parent or not cachedNpcs[npcAimbotLocked] then
                npcAimbotLocked=nil
            else
                local hum=npcAimbotLocked:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health<=0 then npcAimbotLocked=nil end
            end
        end
        if not npcAimbotLocked then npcAimbotLocked=GetBestNpc() end
        if not npcAimbotLocked then return end
        local hrp=npcAimbotLocked:FindFirstChild(NpcAim.LockPart) or GetNpcRoot(npcAimbotLocked)
        if not hrp then npcAimbotLocked=nil; return end
        if NpcAim.LockMode==2 then
            local sp=Camera:WorldToViewportPoint(hrp.Position)
            local mp=UIS:GetMouseLocation()
            mousemoverel((sp.X-mp.X)/NpcAim.Sensitivity2,(sp.Y-mp.Y)/NpcAim.Sensitivity2)
        else
            if NpcAim.Sensitivity>0 then
                TweenService_NPC:Create(Camera,
                    TweenInfo.new(NpcAim.Sensitivity,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),
                    {CFrame=CFrame.new(Camera.CFrame.Position,hrp.Position)}
                ):Play()
            else
                Camera.CFrame=CFrame.new(Camera.CFrame.Position,hrp.Position)
            end
        end
    end)
    npcAimIBConn=UIS.InputBegan:Connect(function(input,gpe)
        if gpe or npcAimTyping then return end
        if input.UserInputType==NpcAim.TriggerKey then
            if NpcAim.Toggle then
                npcAimbotRunning=not npcAimbotRunning
                if not npcAimbotRunning then npcAimbotLocked=nil end
            else npcAimbotRunning=true end
        end
    end)
    npcAimIEConn=UIS.InputEnded:Connect(function(input)
        if NpcAim.Toggle or npcAimTyping then return end
        if input.UserInputType==NpcAim.TriggerKey then
            npcAimbotRunning=false; npcAimbotLocked=nil
        end
    end)
end

local function DisableNpcAimbot()
    npcAimbotRunning=false; npcAimbotLocked=nil
    npcFovCircle.Visible=false; npcFovOutline.Visible=false
    if npcAimbotConn then npcAimbotConn:Disconnect(); npcAimbotConn=nil end
    if npcAimIBConn  then npcAimIBConn:Disconnect();  npcAimIBConn=nil  end
    if npcAimIEConn  then npcAimIEConn:Disconnect();  npcAimIEConn=nil  end
end

-- ── DvN UI ────────────────────────────────
local DvN   = window:tab({name="DvN"})
local dvcol = DvN:column()
local npcESPsec, npcAIMsec = dvcol:multi_section({names={"NPC ESP","NPC Aimbot"}})

npcESPsec:toggle({name="Enabled",flag="dvn_esp_enabled",callback=function(s)
    NpcEsp.Enabled=s; if s then EnableNpcEsp() else DisableNpcEsp() end
end})
npcESPsec:toggle({name="Boxes",    flag="dvn_esp_boxes", callback=function(s) NpcEsp.BoxEnabled   =s end})
npcESPsec:toggle({name="Names",    flag="dvn_esp_names", callback=function(s) NpcEsp.NamesEnabled =s end})
npcESPsec:toggle({name="Healthbar",flag="dvn_esp_hp",    callback=function(s) NpcEsp.HealthEnabled=s end})
npcESPsec:toggle({name="Distance", flag="dvn_esp_dist",  callback=function(s) NpcEsp.DistEnabled  =s end})
npcESPsec:toggle({name="Category Colors",flag="dvn_esp_catcolors",tooltip="Each enemy type gets a unique color",callback=function(s)
    NpcEsp.CategoryColors=s; if NpcEsp.ChamsEnabled then RefreshNpcChams() end
end})
local npcChamsT=npcESPsec:toggle({name="Chams",flag="dvn_chams_enabled",tooltip="Highlight NPCs through walls",callback=function(s)
    NpcEsp.ChamsEnabled=s; if s then EnableNpcChams() else DisableNpcChams() end
end})
npcChamsT:colorpicker({name="Default Color",flag="dvn_chams_defcol",color=hex("#FF5050"),callback=function(c)
    NpcEsp.DefaultColor=c; if NpcEsp.ChamsEnabled then RefreshNpcChams() end
end})
npcESPsec:slider({name="Chams Fill Transparency",flag="dvn_chams_filltr",min=0,max=1,default=0.5,interval=0.01,callback=function(v)
    NpcEsp.FillTr=v; if NpcEsp.ChamsEnabled then RefreshNpcChams() end
end})
npcESPsec:slider({name="Chams Outline Transparency",flag="dvn_chams_outtr",min=0,max=1,default=0.1,interval=0.01,callback=function(v)
    NpcEsp.OutTr=v; if NpcEsp.ChamsEnabled then RefreshNpcChams() end
end})

npcAIMsec:toggle({name="Enabled",flag="dvn_aim_enabled",callback=function(s)
    NpcAim.Enabled=s; if s then EnableNpcAimbot() else DisableNpcAimbot() end
end}):keybind({name="Aimbot Key",flag="dvn_aim_key",callback=function(k) if k then NpcAim.TriggerKey=k end end})
npcAIMsec:toggle({name="Toggle Mode",  flag="dvn_aim_toggle",   callback=function(s) NpcAim.Toggle      =s end})
npcAIMsec:toggle({name="Boss Priority",flag="dvn_aim_bossprio", tooltip="Target bosses before regular Noobs",callback=function(s) NpcAim.BossPriority=s end})
npcAIMsec:dropdown({name="Lock Part",flag="dvn_aim_lockpart",items={"HumanoidRootPart","Head","UpperTorso"},default="HumanoidRootPart",callback=function(v) NpcAim.LockPart=v end})
npcAIMsec:dropdown({name="Lock Mode",flag="dvn_aim_lockmode",items={"CFrame","mousemoverel"},default="CFrame",callback=function(v) NpcAim.LockMode=v=="CFrame" and 1 or 2 end})
npcAIMsec:slider({name="FOV Radius",       flag="dvn_aim_fov",   min=10, max=1000,default=150,interval=1,   callback=function(v) NpcAim.FovRadius   =v end})
npcAIMsec:slider({name="Sensitivity",      flag="dvn_aim_sens",  min=0,  max=1,   default=0,  interval=0.01,callback=function(v) NpcAim.Sensitivity =v end})
npcAIMsec:slider({name="Mouse Sensitivity",flag="dvn_aim_sens2", min=0.1,max=5,   default=3.5,interval=0.1, callback=function(v) NpcAim.Sensitivity2=v end})

-- ───────────────────────────────────────────
--  TDS TAB
-- ───────────────────────────────────────────
local TDS    = window:tab({name = "TDS"})
local tdscol = TDS:column()
local tdssec = tdscol:section({name = "Scripts", toggle = false})

tdssec:button_holder({})
tdssec:button({name="Main Hub",callback=function()
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DuxiiT/auto-strat/refs/heads/main/Library.lua"))()
    end)
    if not ok then warn("[Main Hub] Failed to load: " .. tostring(err)) end
end})

-- ───────────────────────────────────────────
library:config_list_update()

for index, value in themes.preset do
    pcall(function() library:update_theme(index, value) end)
end

task.wait()
library.old_config = library:get_config()
