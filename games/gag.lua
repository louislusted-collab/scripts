return function(window, library)
    local Players  = game:GetService("Players")
    local RS       = game:GetService("ReplicatedStorage")
    local Space    = game:GetService("Workspace")
    local VIM      = game:GetService("VirtualInputManager")
    local Player   = Players.LocalPlayer

    -- ── Remote capture (hooks __namecall to record FireServer calls) ──
    local captured    = {}  -- captured[key] = {remote, method, args}
    local captureNext = nil -- set to a key string to capture 1 remote call
    local hookActive  = false

    pcall(function()
        local mt = getrawmetatable(game)
        local old = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local m = getnamecallmethod()
            if captureNext and (m == "FireServer" or m == "InvokeServer") then
                local key = captureNext
                captureNext = nil
                captured[key] = {remote = self, method = m, args = {...}}
                library:notification({text = "Captured: " .. key, time = 3})
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
        hookActive = true
    end)

    local function fireCapture(key)
        local c = captured[key]
        if not c then return false end
        pcall(function()
            if c.method == "FireServer" then
                c.remote:FireServer(table.unpack(c.args))
            else
                c.remote:InvokeServer(table.unpack(c.args))
            end
        end)
        return true
    end

    -- ── State ─────────────────────────────────
    local state = {
        AutoHarvest  = false,
        AutoSell     = false,
        AutoPlant    = false,
        AutoShop     = false,
        AutoSteal    = false,
        AutoWater    = false,
        HarvestDelay = 0.15,
    }
    local threads = {}

    -- ── Helpers ───────────────────────────────
    local function tpTo(pos)
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end
    end

    local function getPos(obj)
        if obj:IsA("Model")    then return obj.PrimaryPart and obj.PrimaryPart.Position
        elseif obj:IsA("BasePart") then return obj.Position end
    end

    local function firePrompt(p)
        if p and p.Parent then pcall(function() fireproximityprompt(p) end) end
    end

    local function clickBtn(btn)
        -- try getconnections first (most reliable in executors)
        local fired = false
        pcall(function()
            for _, sig in pairs({btn.MouseButton1Click, btn.Activated}) do
                for _, c in pairs(getconnections(sig)) do
                    pcall(function() c:Fire() end)
                    fired = true
                end
            end
        end)
        if not fired then
            pcall(function()
                local pos = btn.AbsolutePosition + btn.AbsoluteSize * 0.5
                VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true,  game, 1)
                task.wait(0.05)
                VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
            end)
        end
    end

    local function findGuiButton(keywords)
        for _, obj in pairs(Player.PlayerGui:GetDescendants()) do
            if obj.Visible and (obj:IsA("TextButton") or obj:IsA("ImageButton")) then
                local label = ((obj:IsA("TextButton") and obj.Text) or "") .. " " .. obj.Name
                for _, child in pairs(obj:GetChildren()) do
                    if child:IsA("TextLabel") then label = label .. " " .. child.Text end
                end
                local low = label:lower()
                for _, kw in ipairs(keywords) do
                    if low:find(kw, 1, true) then return obj end
                end
            end
        end
    end

    local function getPrompts(keywords)
        local found = {}
        for _, obj in pairs(Space:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                local at = obj.ActionText:lower()
                local ot = obj.ObjectText:lower()
                for _, kw in ipairs(keywords) do
                    if at:find(kw, 1, true) or ot:find(kw, 1, true) then
                        table.insert(found, obj); break
                    end
                end
            end
        end
        return found
    end

    local function fireAll(keywords, delay, checkFn)
        for _, p in pairs(getPrompts(keywords)) do
            if checkFn and not checkFn() then break end
            local pos = getPos(p.Parent)
            if pos then tpTo(pos); task.wait(0.1) end
            firePrompt(p)
            task.wait(delay or 0.15)
        end
    end

    -- ── Bag full (100/100 fruits) ──────────────
    local function isBagFull()
        for _, obj in pairs(Player.PlayerGui:GetDescendants()) do
            if obj:IsA("TextLabel") then
                local cur, max = obj.Text:match("(%d+)%s*/%s*(%d+)")
                if cur and max then
                    local c, m = tonumber(cur), tonumber(max)
                    if m and m > 0 and c >= m then return true end
                end
            end
        end
        return false
    end

    -- ── Actions ───────────────────────────────
    local HARVEST_KW = {"harvest","collect","pick","gather","reap","take"}

    local function doHarvest()
        if isBagFull() then
            -- sell first, then continue
            if not fireCapture("sell") then
                local btn = findGuiButton({"sell"})
                if btn then clickBtn(btn); task.wait(1.5) end
            end
        end
        fireAll(HARVEST_KW, state.HarvestDelay, function() return state.AutoHarvest end)
    end

    local function doSell()
        -- 1. Try captured remote (most reliable)
        if fireCapture("sell") then return end
        -- 2. Try GUI button
        local btn = findGuiButton({"sell"})
        if btn then clickBtn(btn); return end
        -- 3. Try proximity prompt
        local prompts = getPrompts({"sell","vendor","market","trade"})
        if #prompts > 0 then
            local p = prompts[1]
            local pos = getPos(p.Parent)
            if pos then tpTo(pos); task.wait(0.1) end
            firePrompt(p)
        end
    end

    local PLANT_KW = {"plant","sow","seed","insert","grow","place"}

    local function doPlant()
        if not fireCapture("plant") then
            local btn = findGuiButton({"plant","sow"})
            if btn then clickBtn(btn); task.wait(0.3); return end
            fireAll(PLANT_KW, 0.3, function() return state.AutoPlant end)
        end
    end

    local WATER_KW = {"water","sprinkle","irrigat"}
    local function doWater()
        fireAll(WATER_KW, 0.2, function() return state.AutoWater end)
    end

    local function doShop()
        if not fireCapture("shop") then
            local btn = findGuiButton({"seeds","seed shop","shop","buy"})
            if btn then clickBtn(btn) end
        end
    end

    local function doSteal()
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= Player then
                if not state.AutoSteal then break end
                for _, obj in pairs(Space:GetDescendants()) do
                    if not state.AutoSteal then break end
                    local isOthers = obj:GetAttribute("Owner") == plr.Name
                        or obj:GetAttribute("OwnerId") == plr.UserId
                    if isOthers then
                        local p = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if p then
                            local pos = getPos(obj)
                            if pos then tpTo(pos); task.wait(0.1) end
                            firePrompt(p); task.wait(0.2)
                        end
                    end
                end
            end
        end
    end

    -- ── Loops ─────────────────────────────────
    local function startLoop(key, interval, fn)
        if threads[key] then task.cancel(threads[key]) end
        threads[key] = task.spawn(function()
            while state[key] do pcall(fn); task.wait(interval) end
        end)
    end
    local function stopLoop(key)
        state[key] = false
        if threads[key] then task.cancel(threads[key]); threads[key] = nil end
    end

    -- ── UI ────────────────────────────────────
    local GAG  = window:tab({name = "GAG 2"})
    local gcol = GAG:column()
    local farm, shopSec, stealSec, capSec = gcol:multi_section({names = {"Farm", "Shop", "Steal", "Capture"}})

    -- Farm
    farm:toggle({name = "Auto Harvest", flag = "gag_harvest", callback = function(s)
        state.AutoHarvest = s
        if s then startLoop("AutoHarvest", 1, doHarvest) else stopLoop("AutoHarvest") end
    end})
    farm:toggle({name = "Auto Sell",    flag = "gag_sell",    callback = function(s)
        state.AutoSell = s
        if s then startLoop("AutoSell", 3, doSell) else stopLoop("AutoSell") end
    end})
    farm:toggle({name = "Auto Plant",   flag = "gag_plant",   callback = function(s)
        state.AutoPlant = s
        if s then startLoop("AutoPlant", 2, doPlant) else stopLoop("AutoPlant") end
    end})
    farm:toggle({name = "Auto Water",   flag = "gag_water",   callback = function(s)
        state.AutoWater = s
        if s then startLoop("AutoWater", 2, doWater) else stopLoop("AutoWater") end
    end})
    farm:button_holder({})
    farm:button({name = "Sell Now",    callback = function() task.spawn(pcall, doSell)    end})
    farm:button({name = "Harvest Now", callback = function() task.spawn(pcall, doHarvest) end})
    farm:slider({name = "Harvest Delay", flag = "gag_hdelay", min = 0.05, max = 2, default = 0.15, interval = 0.05, suffix = "s", callback = function(v)
        state.HarvestDelay = v
    end})

    -- Shop
    local SEEDS = {"Carrot","Strawberry","Blueberry","Tomato","Corn","Watermelon","Pumpkin","Sunflower","Rose","Bamboo","Cactus","Mushroom","Grape","Mango","Coconut"}
    shopSec:dropdown({name = "Seed", flag = "gag_seed", items = SEEDS, default = "Carrot", callback = function(v)
        state.PlantSeed = v
    end})
    shopSec:slider({name = "Buy Amount", flag = "gag_buyamt", min = 1, max = 99, default = 1, interval = 1})
    shopSec:toggle({name = "Auto Shop", flag = "gag_shop", callback = function(s)
        state.AutoShop = s
        if s then startLoop("AutoShop", 5, doShop) else stopLoop("AutoShop") end
    end})
    shopSec:button_holder({})
    shopSec:button({name = "Buy Now", callback = function() task.spawn(pcall, doShop) end})

    -- Steal
    stealSec:toggle({name = "Auto Steal", flag = "gag_steal", callback = function(s)
        state.AutoSteal = s
        if s then startLoop("AutoSteal", 2, doSteal) else stopLoop("AutoSteal") end
    end})
    stealSec:button_holder({})
    stealSec:button({name = "Steal Now", callback = function() task.spawn(pcall, doSteal) end})

    -- Capture section: press button then do the action in-game to record its remote
    local hookStatus = hookActive and "Hook: active" or "Hook: not supported"
    capSec:label({name = hookStatus})
    capSec:button_holder({})
    capSec:button({name = "Capture Sell",  callback = function()
        captureNext = "sell"
        library:notification({text = "Click the Sell button in-game now", time = 4})
    end})
    capSec:button({name = "Capture Plant", callback = function()
        captureNext = "plant"
        library:notification({text = "Plant a seed in-game now", time = 4})
    end})
    capSec:button({name = "Capture Shop",  callback = function()
        captureNext = "shop"
        library:notification({text = "Buy something in-game now", time = 4})
    end})
    capSec:button_holder({})
    capSec:button({name = "Clear Captures", callback = function()
        captured = {}
        captureNext = nil
        library:notification({text = "Captures cleared", time = 2})
    end})

    -- Scan debug buttons
    capSec:button_holder({})
    capSec:button({name = "Scan Prompts", callback = function()
        local seen, count = {}, 0
        for _, obj in pairs(Space:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                local k = obj.ActionText.."|"..obj.ObjectText
                if not seen[k] then
                    seen[k] = true; count = count + 1
                    print("[GAG] Prompt Action='"..obj.ActionText.."' Object='"..obj.ObjectText.."' Parent="..obj.Parent.Name)
                end
            end
        end
        library:notification({text = count.." prompts - check F9", time = 4})
    end})
    capSec:button({name = "Scan GUI Buttons", callback = function()
        local count = 0
        for _, obj in pairs(Player.PlayerGui:GetDescendants()) do
            if obj.Visible and (obj:IsA("TextButton") or obj:IsA("ImageButton")) then
                count = count + 1
                local txt = obj:IsA("TextButton") and obj.Text or "(img)"
                print("[GAG] Button '"..txt.."' Name='"..obj.Name.."' "..obj:GetFullName())
            end
        end
        library:notification({text = count.." buttons - check F9", time = 4})
    end})
end
