return function(window, library)
    local Players  = game:GetService("Players")
    local RS       = game:GetService("ReplicatedStorage")
    local Space    = game:GetService("Workspace")
    local Player   = Players.LocalPlayer

    -- ── State ─────────────────────────────────
    local state = {
        AutoHarvest = false,
        AutoSell    = false,
        AutoPlant   = false,
        AutoShop    = false,
        AutoSteal   = false,
        AutoWater   = false,
        PlantSeed   = "Carrot",
        BuyAmount   = 1,
        HarvestDelay = 0.15,
        LoopDelay   = 1,
    }

    local threads = {}

    -- ── Helpers ───────────────────────────────
    local function tpTo(pos)
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end
    end

    local function getPos(obj)
        if obj:IsA("Model") then
            return obj.PrimaryPart and obj.PrimaryPart.Position or nil
        elseif obj:IsA("BasePart") then
            return obj.Position
        end
        return nil
    end

    local function firePrompt(prompt)
        if prompt and prompt.Parent then
            pcall(function() fireproximityprompt(prompt) end)
        end
    end

    -- scan all prompts and filter by keyword match on ActionText or ObjectText
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

    -- fire the first matching prompt (for sell/shop which are single static objects)
    local function fireFirst(keywords)
        local prompts = getPrompts(keywords)
        if #prompts == 0 then return false end
        local prompt = prompts[1]
        local pos = getPos(prompt.Parent)
        if pos then tpTo(pos); task.wait(0.1) end
        firePrompt(prompt)
        return true
    end

    -- fire all matching prompts (for harvest which has many targets)
    local function fireAll(keywords, delay, checkFn)
        local prompts = getPrompts(keywords)
        for _, prompt in pairs(prompts) do
            if checkFn and not checkFn() then break end
            local pos = getPos(prompt.Parent)
            if pos then tpTo(pos); task.wait(0.1) end
            firePrompt(prompt)
            task.wait(delay or 0.15)
        end
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

    -- Harvest: find prompts with harvest/collect/pick keywords
    local HARVEST_KW = {"harvest","collect","pick","gather","reap","take"}

    local function doHarvest()
        fireAll(HARVEST_KW, state.HarvestDelay, function() return state.AutoHarvest end)
    end

    -- Sell: walk to the sell stand and fire its prompt
    local SELL_KW = {"sell","vendor","market","shop","store","cash","money"}

    local function doSell()
        fireFirst(SELL_KW)
    end

    -- Plant: find empty plot prompts and plant the selected seed
    -- GAG2 likely shows a "Plant" prompt on empty soil tiles
    local PLANT_KW = {"plant","sow","seed","insert","grow","put"}

    local function doPlant()
        fireAll(PLANT_KW, 0.3, function() return state.AutoPlant end)
    end

    -- Water: find watering prompts
    local WATER_KW = {"water","sprinkle","irrigat"}

    local function doWater()
        fireAll(WATER_KW, 0.2, function() return state.AutoWater end)
    end

    -- Shop: buy seeds from shop
    local SHOP_KW = {"buy","purchase","shop","seed shop","store"}

    local function doShop()
        fireFirst(SHOP_KW)
    end

    -- Steal: scan other players' owned objects for harvestable crops
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
    local GAG    = window:tab({name = "GAG 2"})
    local gcol   = GAG:column()
    local farm, shopSec, stealSec, dbg = gcol:multi_section({names = {"Farm", "Shop", "Steal", "Debug"}})

    -- Farm
    farm:toggle({name = "Auto Harvest", flag = "gag_harvest", callback = function(s)
        state.AutoHarvest = s
        if s then startLoop("AutoHarvest", state.LoopDelay, doHarvest) else stopLoop("AutoHarvest") end
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
    farm:button({name = "Sell Now", callback = function()
        task.spawn(pcall, doSell)
    end})
    farm:button({name = "Harvest Now", callback = function()
        task.spawn(pcall, doHarvest)
    end})
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
    shopSec:button({name = "Buy Now", callback = function()
        task.spawn(pcall, doShop)
    end})

    -- Steal
    stealSec:toggle({name = "Auto Steal", flag = "gag_steal", callback = function(s)
        state.AutoSteal = s
        if s then startLoop("AutoSteal", 2, doSteal) else stopLoop("AutoSteal") end
    end})
    stealSec:button_holder({})
    stealSec:button({name = "Steal Now", callback = function()
        task.spawn(pcall, doSteal)
    end})

    -- Debug: scan the game and print what we find
    dbg:button_holder({})
    dbg:button({name = "Scan Prompts", callback = function()
        local count = 0
        local seen = {}
        for _, obj in pairs(Space:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                local key = obj.ActionText .. "|" .. obj.ObjectText
                if not seen[key] then
                    seen[key] = true
                    count = count + 1
                    print("[GAG] Prompt: Action='" .. obj.ActionText .. "' Object='" .. obj.ObjectText .. "' Parent=" .. obj.Parent.Name)
                end
            end
        end
        library:notification({text = "Found " .. count .. " unique prompts - check F9 console", time = 5})
    end})
    dbg:button({name = "Scan Remotes", callback = function()
        local count = 0
        for _, obj in pairs(RS:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                count = count + 1
                print("[GAG] Remote (" .. obj.ClassName .. "): " .. obj:GetFullName())
            end
        end
        library:notification({text = "Found " .. count .. " remotes - check F9 console", time = 5})
    end})
end
