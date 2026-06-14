return function(window, library)
    local Players = game:GetService("Players")
    local Player  = Players.LocalPlayer

    -- ── Billboard ESP folder ──────────────────
    local MM2ESPFolder = Instance.new("Folder")
    MM2ESPFolder.Name   = "MM2ESP"
    MM2ESPFolder.Parent = game:GetService("CoreGui")

    local mm2Esp = { All = false, Murder = false, Sheriff = false }

    local function MM2AddBillboard(plr)
        local bb              = Instance.new("BillboardGui")
        bb.Name               = plr.Name .. "MM2BB"
        bb.AlwaysOnTop        = true
        bb.Size               = UDim2.new(0, 200, 0, 50)
        bb.ExtentsOffset      = Vector3.new(0, 3, 0)
        bb.Enabled            = false
        bb.Parent             = MM2ESPFolder

        local lbl                     = Instance.new("TextLabel")
        lbl.TextSize                  = 20
        lbl.Text                      = plr.Name
        lbl.Font                      = Enum.Font.FredokaOne
        lbl.BackgroundTransparency    = 1
        lbl.Size                      = UDim2.new(1, 0, 1, 0)
        lbl.TextStrokeTransparency    = 0
        lbl.TextStrokeColor3          = Color3.new(0, 0, 0)
        lbl.Parent                    = bb

        repeat
            task.wait()
            pcall(function()
                local c  = plr.Character
                local bp = plr:FindFirstChild("Backpack")
                if c then bb.Adornee = c:FindFirstChild("Head") end
                local hasKnife = (c and c:FindFirstChild("Knife")) or (bp and bp:FindFirstChild("Knife"))
                local hasGun   = (c and c:FindFirstChild("Gun"))   or (bp and bp:FindFirstChild("Gun"))
                if hasKnife then
                    lbl.TextColor3 = Color3.fromRGB(255, 0, 0)
                    bb.Enabled     = mm2Esp.Murder
                elseif hasGun then
                    lbl.TextColor3 = Color3.fromRGB(0, 100, 255)
                    bb.Enabled     = mm2Esp.Sheriff
                else
                    lbl.TextColor3 = Color3.fromRGB(0, 255, 0)
                    bb.Enabled     = mm2Esp.All
                end
            end)
        until not plr.Parent
    end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player then coroutine.wrap(MM2AddBillboard)(plr) end
    end
    Players.PlayerAdded:Connect(function(plr)
        if plr ~= Player then coroutine.wrap(MM2AddBillboard)(plr) end
    end)
    Players.PlayerRemoving:Connect(function(plr)
        local bb = MM2ESPFolder:FindFirstChild(plr.Name .. "MM2BB")
        if bb then bb:Destroy() end
    end)

    -- ── UI ────────────────────────────────────
    local MM2    = window:tab({name = "MM2"})
    local mm2col = MM2:column()
    local mm2trade, mm2roles, mm2esp, mm2misc = mm2col:multi_section({names = {"Trading", "Roles", "ESP", "Misc"}})

    -- Trading
    local mm2TargetName = ""
    mm2trade:textbox({
        placeholder = "Enter player name...",
        flag        = "mm2_player_name",
        callback    = function(v) mm2TargetName = v end,
    })
    mm2trade:button_holder({})
    mm2trade:button({name = "Force Trade", callback = function()
        if mm2TargetName == "" then return end
        local target = Players:FindFirstChild(mm2TargetName)
        if not target then return end
        pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            RS:WaitForChild("Trade"):WaitForChild("SendRequest"):InvokeServer(target)
            RS:WaitForChild("Trade"):WaitForChild("AcceptRequest"):FireServer()
        end)
    end})

    -- Roles
    mm2roles:button_holder({})
    mm2roles:button({name = "Chat Expose Roles", callback = function()
        local RS  = game:GetService("ReplicatedStorage")
        local evt = RS:WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest")
        for _, plr in pairs(Players:GetPlayers()) do
            local bp = plr:FindFirstChild("Backpack")
            if bp then
                if bp:FindFirstChild("Knife") then
                    pcall(function() evt:FireServer(plr.Name .. ": Has The Knife", "normalchat") end)
                end
                if bp:FindFirstChild("Gun") then
                    pcall(function() evt:FireServer(plr.Name .. ": Has The Gun", "normalchat") end)
                end
            end
        end
    end})

    local mm2GunLbl  = mm2roles:label({name = "Gun: Not Dropped"})
    local mm2MurdLbl = mm2roles:label({name = "Murderer: Unknown"})
    local mm2SherLbl = mm2roles:label({name = "Sheriff:  Unknown"})

    task.spawn(function()
        while task.wait(1) do
            pcall(function()
                mm2GunLbl.set(workspace:FindFirstChild("GunDrop") and "Gun: Dropped" or "Gun: Not Dropped")
            end)
            local murd, sher = "Unknown", "Unknown"
            for _, plr in ipairs(Players:GetPlayers()) do
                local c  = plr.Character
                local bp = plr:FindFirstChild("Backpack")
                if c and bp then
                    if c:FindFirstChild("Knife") or bp:FindFirstChild("Knife") then murd = plr.Name end
                    if c:FindFirstChild("Gun")   or bp:FindFirstChild("Gun")   then sher = plr.Name end
                end
            end
            pcall(function() mm2MurdLbl.set("Murderer: " .. murd) end)
            pcall(function() mm2SherLbl.set("Sheriff:  " .. sher) end)
        end
    end)

    -- ESP toggles
    mm2esp:toggle({name = "All Players ESP",  flag = "mm2_all_esp",     callback = function(s) mm2Esp.All     = s end})
    mm2esp:toggle({name = "Murder ESP",       flag = "mm2_murder_esp",  callback = function(s) mm2Esp.Murder  = s end})
    mm2esp:toggle({name = "Sheriff ESP",      flag = "mm2_sheriff_esp", callback = function(s) mm2Esp.Sheriff = s end})

    -- Misc
    mm2misc:button_holder({})
    mm2misc:button({name = "Get Every Emote", callback = function()
        pcall(function()
            local Emotes = Player.PlayerGui:WaitForChild("MainGUI"):WaitForChild("Game"):FindFirstChild("Emotes")
            if Emotes then
                require(game:GetService("ReplicatedStorage").Modules.EmoteModule).GeneratePage(
                    {"headless","zombie","zen","ninja","floss","dab","sit"}, Emotes, "Free Emotes"
                )
            end
        end)
    end})

    mm2misc:button_holder({})
    mm2misc:button({name = "Get Every Weapon (Client)", callback = function()
        pcall(function()
            local DataBase   = getrenv()._G.Database
            local PlayerData = getrenv()._G.PlayerData
            local newOwned   = {}
            for i in next, DataBase.Item do newOwned[i] = 999999999 end
            local weapons = PlayerData.Weapons
            game:GetService("RunService"):BindToRenderStep("MM2WeaponUpdate", 0, function()
                weapons.Owned = newOwned
            end)
            Player.Character.Humanoid.Health = 0
        end)
    end})
end
