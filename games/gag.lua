return function(window, library)
    local Players  = game:GetService("Players")
    local RS       = game:GetService("ReplicatedStorage")
    local Space    = game:GetService("Workspace")
    local VIM      = game:GetService("VirtualInputManager")
    local Player   = Players.LocalPlayer

    -- ── State ─────────────────────────────────
    local state = {
        AutoHarvest  = false,
        AutoSell     = false,
        AutoPlant    = false,
        AutoShop     = false,
        AutoSteal    = false,
        AutoWater    = false,
        PlantSeed    = "Carrot",
        BuyAmount    = 1,
        HarvestDelay = 0.15,
    }

    local threads = {}

    -- ── Helpers ───────────────────────────────
    local function tpTo(pos)
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end
    end

    local function getPos(obj)
        if obj:IsA("Model") then
            return obj.PrimaryPart and obj.PrimaryPart.Position
        elseif obj:IsA("BasePart") then
            return obj.Position
        end
    end

    local function firePrompt(prompt)
        if prompt and prompt.Parent then
            pcall(function() fireproximityprompt(prompt) end)
        end
    end

    -- click a ScreenGui button by its absolute screen position
    local function clickBtn(btn)
        pcall(function()
            local pos = btn.AbsolutePosition + btn.AbsoluteSize * 0.5
            VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true,  game, 1)
            task.wait(0.05)
            VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end)
    end

    -- find a visible ScreenGui button whose Text or Name contains any keyword
    local function findGuiButton(keywords)
        for _, obj in pairs(Player.PlayerGui:GetDescendants()) do
            if obj.Visible and (obj:IsA("TextButton") or obj:IsA("ImageButton")) then
                local label = ((obj:IsA("TextButton") and obj.Text) or "") .. obj.Name
                local lower = label:lower()
                for _, kw in ipairs(keywords) do
                    if lower:find(kw, 1, true) then return obj end
                end
            end
        end
    end

    -- ProximityPrompt scan
    local function getPrompts(keywords)
        local found = {}
        for _, obj in pairs(Space:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                local at = obj.ActionText:lower()
                local ot = obj.ObjectText:lower()
                for _, kw in ipairs(keywords) do
                    if at:find(kw, 1, true) or ot:find(kw, 1, true) then
                        table.insert(found, obj)
                        break
                    end
                end
            end
        end
        return found
    end

    local function fireFirst(keywords)
        local prompts = getPrompts(keywords)
        if #prompts > 0 then
            local p = prompts[1]
            local pos = getPos(p.Parent)
            if pos then tpTo(pos); task.wait(0.1) end
            firePrompt(p)
            return true
        end
        return false
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

    -- ── Bag full check ────────────────────────
    -- GAG2 uses a weight-based bag; scan PlayerGui for a weight/capacity label
    local function isBagFull()
        for _, obj in pairs(Player.PlayerGui:GetDescendants()) do
            if obj:IsA("TextLabel") then
                local t = obj.Text
                -- patterns: "54.26K / 60K", "18/20", "Full", etc.
                local cur, max = t:match("([%d%.]+[Kk]?)%s*/+%s*([%d%.]+[Kk]?)")
                if cur and max then
                    local function toNum(s)
                        s = s:gsub("[Kk]", "")
                        return tonumber(s) or 0
                    end
                    local c, m = toNum(cur), toNum(max)
                    if m > 0 and c >= m * 0.97 then return true end
                end
                if t:lower():find("full") or t:lower():find("bag full") then
                    return true
                end
            end
        end
        return false
    end

    -- ── Loops ─────────────────────────────────
    local function startLoop(key, interval, fn)
        if threads[key] then task.cancel(threads[key]) end
        threads[key] = task.spawn(function()
            while state[key] do
                pcall(fn)
                task.wait(interval)
            end
        end)
    end

    local function stopLoop(key)
        state[key] = false
        if threads[key] then task.cancel(threads[key]); threads[key] = nil end
    end

    -- ── Actions ───────────────────────────────
    local HARVEST_KW = {"harvest","collect","pick","gather","reap","take"}

    local function doHarvest()
        if isBagFull() then
            -- auto sell when bag is full, then continue
            local sellBtn = findGuiButton({"sell"})
            if sellBtn then clickBtn(sellBtn); task.wait(1) end
        end
        fireAll(HARVEST_KW, state.HarvestDelay, function() return state.AutoHarvest end)
    end

    -- Sell: try GUI button first (top bar "Sell" button), then prompt fallback
    local function doSell()
        local btn = findGuiButton({"sell"})
        if btn then clickBtn(btn); return end
        fireFirst({"sell","vendor","market"})
    end

    -- Plant: try GUI button first, then ProximityPrompt on soil/plot
    local PLANT_KW = {"plant","sow","seed","insert","grow"}

    local function doPlant()
        -- try clicking a "Seeds" or "Plant" GUI button
        local btn = findGuiButton({"plant","sow"})
        if btn then clickBtn(btn); task.wait(0.3); return end
        fireAll(PLANT_KW, 0.3, function() return state.AutoPlant end)
    end

    local WATER_KW = {"water","sprinkle","irrigat"}
    local function doWater()
        fireAll(WATER_KW, 0.2, function() return state.AutoWater end)
    end

    -- Shop: click the "Seeds" top bar button
    local function doShop()
        local btn = findGuiButton({"seeds","seed shop","shop","buy"})
        if btn then clickBtn(btn); return end
        fireFirst({"buy","purchase","shop"})
    end

    local function doSteal()
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= Player then
                if not state.AutoSteal then break end
                for _, obj in pairs(Space:GetDescendants()) do
                    if not state.AutoSteal then break end
                    local isOthers = obj:GetAttribute("Owner") == plr.Name
                        or obj:GetAttribute("OwnerId") == plr.UserId
                        or obj:GetAttribute("PlayerId") == plr.UserId
                    if isOthers then
                        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            local pos = getPos(obj)
                            if pos then tpTo(pos); task.wait(0.1) end
                            firePrompt(prompt)
                            task.wait(0.2)
                        end
                    end
                end
            end
        end
    end

    -- ── UI ────────────────────────────────────
    local GAG  = window:tab({name = "GAG 2"})
    local gcol = GAG:column()
    local farm, shopSec, stealSec, dbg = gcol:multi_section({names = {"Farm", "Shop", "Steal", "Debug"}})

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
    local SEEDS = {
        "Carrot","Strawberry","Blueberry","Tomato","Corn",
        "Watermelon","Pumpkin","Sunflower","Rose","Bamboo",
        "Cactus","Mushroom","Grape","Mango","Coconut",
    }
    shopSec:dropdown({name = "Seed", flag = "gag_seed", items = SEEDS, default = "Carrot", callback = function(v)
        state.PlantSeed = v
    end})
    shopSec:slider({name = "Buy Amount", flag = "gag_buyamt", min = 1, max = 99, default = 1, interval = 1, callback = function(v)
        state.BuyAmount = v
    end})
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

    -- Debug
    dbg:button_holder({})
    dbg:button({name = "Scan Prompts", callback = function()
        local seen, count = {}, 0
        for _, obj in pairs(Space:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                local key = obj.ActionText.."|"..obj.ObjectText
                if not seen[key] then
                    seen[key] = true; count = count + 1
                    print("[GAG] Prompt: Action='"..obj.ActionText.."' Object='"..obj.ObjectText.."' Parent="..obj.Parent.Name)
                end
            end
        end
        library:notification({text = count.." unique prompts - check F9", time = 5})
    end})
    dbg:button({name = "Scan GUI Buttons", callback = function()
        local count = 0
        for _, obj in pairs(Player.PlayerGui:GetDescendants()) do
            if obj.Visible and (obj:IsA("TextButton") or obj:IsA("ImageButton")) then
                count = count + 1
                local txt = obj:IsA("TextButton") and obj.Text or "(ImageButton)"
                print("[GAG] Button: '"..txt.."' Name='"..obj.Name.."' Path="..obj:GetFullName())
            end
        end
        library:notification({text = count.." buttons - check F9", time = 5})
    end})
    dbg:button({name = "Scan Remotes", callback = function()
        local count = 0
        for _, obj in pairs(RS:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                count = count + 1
                print("[GAG] Remote ("..obj.ClassName.."): "..obj:GetFullName())
            end
        end
        library:notification({text = count.." remotes - check F9", time = 5})
    end})
end
