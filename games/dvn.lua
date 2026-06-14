return function(window, library)
    local Players        = game:GetService("Players")
    local RunSvc         = game:GetService("RunService")
    local UIS            = game:GetService("UserInputService")
    local TweenService   = game:GetService("TweenService")
    local Space          = game:GetService("Workspace")
    local Camera         = Space.CurrentCamera
    local Player         = Players.LocalPlayer

    local function LerpColor(c1, c2, t)
        return Color3.new(
            c1.R + (c2.R - c1.R) * t,
            c1.G + (c2.G - c1.G) * t,
            c1.B + (c2.B - c1.B) * t
        )
    end

    -- ── NPC / Boss sets ───────────────────────
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

    -- ── NPC cache ─────────────────────────────
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

    local activeNpcBoxes = {}

    local function DestroyNpcBox(model)
        local d = activeNpcBoxes[model]
        if not d then return end
        for _, l in pairs(d.lines) do pcall(function() l:Remove() end) end
        pcall(function() d.hpOut:Remove()    end)
        pcall(function() d.hpBg:Remove()     end)
        pcall(function() d.hpBar:Remove()    end)
        pcall(function() d.nameText:Remove() end)
        pcall(function() d.distText:Remove() end)
        pcall(function() d.ori:Destroy()     end)
        activeNpcBoxes[model] = nil
    end

    local NPC_CHAMS_TAG = "JefferyDvNChams"

    local function RemoveNpcChams(model)
        local h = model and model:FindFirstChild(NPC_CHAMS_TAG)
        if h then h:Destroy() end
    end

    local function ApplyNpcChams(model)
        if not model or not model.Parent then return end
        if not NpcEsp.ChamsEnabled then return end
        if model:FindFirstChild(NPC_CHAMS_TAG) then return end
        local col = NpcEsp.CategoryColors and (CAT_COLOR[model.Name] or NpcEsp.DefaultColor) or NpcEsp.DefaultColor
        local h = Instance.new("Highlight")
        h.Name=NPC_CHAMS_TAG; h.FillColor=col; h.OutlineColor=col
        h.FillTransparency=NpcEsp.FillTr; h.OutlineTransparency=NpcEsp.OutTr
        h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        h.Adornee=model; h.Parent=model
    end

    local function StartNpcCache()
        BuildNpcCache()
        if not npcCacheAddConn then
            npcCacheAddConn = Space.DescendantAdded:Connect(function(desc)
                if desc:IsA("Model") and NPC_SET[desc.Name] then
                    cachedNpcs[desc] = true
                    if NpcEsp.ChamsEnabled then task.wait(0.8); ApplyNpcChams(desc) end
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

    local function NpcColor(model)
        if NpcEsp.CategoryColors then return CAT_COLOR[model.Name] or NpcEsp.DefaultColor end
        return NpcEsp.DefaultColor
    end

    local function GetNpcRoot(model)
        return model:FindFirstChild("HumanoidRootPart")
            or model:FindFirstChild("Torso")
            or model.PrimaryPart
    end

    local function RefreshNpcChams()
        for model in pairs(cachedNpcs) do
            RemoveNpcChams(model)
            if NpcEsp.ChamsEnabled then ApplyNpcChams(model) end
        end
    end

    -- ── NPC ESP ───────────────────────────────
    local npcEspConn = nil

    local function MkLine(col)
        local l = Drawing.new("Line"); l.Visible=false
        l.Color=col or Color3.new(1,1,1); l.Thickness=1; l.Transparency=1
        return l
    end
    local function MkText()
        local t = Drawing.new("Text"); t.Visible=false; t.Size=13; t.Center=true
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
                if not hrp or not hum or hum.Health <= 0 then
                    if activeNpcBoxes[model] then DestroyNpcBox(model) end
                    RemoveNpcChams(model)
                    cachedNpcs[model] = nil
                else
                local _, vis = Camera:WorldToViewportPoint(hrp.Position)
                local d = GetOrMakeNpcBox(model)
                if vis then
                local col     = NpcColor(model)
                local camDist = (camPos - hrp.Position).Magnitude
                local studs   = myHRP and math.floor((myHRP.Position - hrp.Position).Magnitude) or 0
                local hpRatio = math.clamp(hum.Health / math.max(hum.MaxHealth,1), 0, 1)
                d.ori.CFrame = CFrame.new(hrp.CFrame.Position, camPos)
                local SX,SY = 2,3
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
                else HideNpcBox(d) end  -- if vis
                end  -- else (not dead)
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
            if hrp and hum and hum.Health>0 then
                local sp,onScreen=Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local dist=(mouse-Vector2.new(sp.X,sp.Y)).Magnitude
                    local tier=(NpcAim.BossPriority and BOSS_SET[model.Name]) and 1 or 2
                    if tier<bestTier or (tier==bestTier and dist<bestDist) then
                        bestTier=tier; bestDist=dist; best=model
                    end
                end
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
                    TweenService:Create(Camera,
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

    -- ── UI ────────────────────────────────────
    local DvN   = window:tab({name = "DvN"})
    local dvcol = DvN:column()
    local npcESPsec, npcAIMsec = dvcol:multi_section({names = {"NPC ESP", "NPC Aimbot"}})

    npcESPsec:toggle({name="Enabled",    flag="dvn_esp_enabled",   callback=function(s) NpcEsp.Enabled=s; if s then EnableNpcEsp() else DisableNpcEsp() end end})
    npcESPsec:toggle({name="Boxes",      flag="dvn_esp_boxes",     callback=function(s) NpcEsp.BoxEnabled   =s end})
    npcESPsec:toggle({name="Names",      flag="dvn_esp_names",     callback=function(s) NpcEsp.NamesEnabled =s end})
    npcESPsec:toggle({name="Healthbar",  flag="dvn_esp_hp",        callback=function(s) NpcEsp.HealthEnabled=s end})
    npcESPsec:toggle({name="Distance",   flag="dvn_esp_dist",      callback=function(s) NpcEsp.DistEnabled  =s end})
    npcESPsec:toggle({name="Category Colors", flag="dvn_esp_catcolors", tooltip="Each enemy type gets a unique color", callback=function(s)
        NpcEsp.CategoryColors=s; if NpcEsp.ChamsEnabled then RefreshNpcChams() end
    end})
    local npcChamsT=npcESPsec:toggle({name="Chams", flag="dvn_chams_enabled", tooltip="Highlight NPCs through walls", callback=function(s)
        NpcEsp.ChamsEnabled=s
        if s then for model in pairs(cachedNpcs) do ApplyNpcChams(model) end
        else for model in pairs(cachedNpcs) do RemoveNpcChams(model) end end
    end})
    npcChamsT:colorpicker({name="Default Color", flag="dvn_chams_defcol", color=Color3.fromHex("#FF5050"), callback=function(c)
        NpcEsp.DefaultColor=c; if NpcEsp.ChamsEnabled then RefreshNpcChams() end
    end})
    npcESPsec:slider({name="Chams Fill Transparency",    flag="dvn_chams_filltr", min=0,max=1,default=0.5,interval=0.01,callback=function(v) NpcEsp.FillTr=v; if NpcEsp.ChamsEnabled then RefreshNpcChams() end end})
    npcESPsec:slider({name="Chams Outline Transparency", flag="dvn_chams_outtr",  min=0,max=1,default=0.1,interval=0.01,callback=function(v) NpcEsp.OutTr=v;  if NpcEsp.ChamsEnabled then RefreshNpcChams() end end})

    npcAIMsec:toggle({name="Enabled",      flag="dvn_aim_enabled",  callback=function(s) NpcAim.Enabled=s; if s then EnableNpcAimbot() else DisableNpcAimbot() end end})
        :keybind({name="Aimbot Key", flag="dvn_aim_key", callback=function(k) if k then NpcAim.TriggerKey=k end end})
    npcAIMsec:toggle({name="Toggle Mode",  flag="dvn_aim_toggle",   callback=function(s) NpcAim.Toggle      =s end})
    npcAIMsec:toggle({name="Boss Priority",flag="dvn_aim_bossprio", tooltip="Target bosses before regular Noobs", callback=function(s) NpcAim.BossPriority=s end})
    npcAIMsec:dropdown({name="Lock Part",  flag="dvn_aim_lockpart", items={"HumanoidRootPart","Head","UpperTorso"}, default="HumanoidRootPart", callback=function(v) NpcAim.LockPart=v end})
    npcAIMsec:dropdown({name="Lock Mode",  flag="dvn_aim_lockmode", items={"CFrame","mousemoverel"},               default="CFrame",           callback=function(v) NpcAim.LockMode=v=="CFrame" and 1 or 2 end})
    npcAIMsec:slider({name="FOV Radius",        flag="dvn_aim_fov",   min=10,  max=1000, default=150, interval=1,    callback=function(v) NpcAim.FovRadius   =v end})
    npcAIMsec:slider({name="Sensitivity",       flag="dvn_aim_sens",  min=0,   max=1,    default=0,   interval=0.01, callback=function(v) NpcAim.Sensitivity =v end})
    npcAIMsec:slider({name="Mouse Sensitivity", flag="dvn_aim_sens2", min=0.1, max=5,    default=3.5, interval=0.1,  callback=function(v) NpcAim.Sensitivity2=v end})
end
