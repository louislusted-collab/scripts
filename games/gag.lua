return function(window, library)
    local Players  = game:GetService("Players")
    local RunSvc   = game:GetService("RunService")
    local RS       = game:GetService("ReplicatedStorage")
    local Space    = game:GetService("Workspace")
    local Player   = Players.LocalPlayer

    -- ── State ─────────────────────────────────
    local state = {
        AutoPlant   = false,
        AutoHarvest = false,
        AutoSell    = false,
        AutoShop    = false,
        AutoSteal   = false,
        PlantDelay  = 0.5,
        SellDelay   = 2,
        ShopSeed    = "Carrot",
        ShopAmount  = 1,
    }

    local threads = {}

    -- ── Helpers ───────────────────────────────
    local function tpTo(pos)
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end
    end

    -- Try to fire common remote event naming patterns
    local function tryRemote(names, a1, a2)
        for _, name in ipairs(names) do
            local r = RS:FindFirstChild(name, true) or Space:FindFirstChild(name, true)
            if r then
                if r:IsA("RemoteEvent") then
                    pcall(function() r:FireServer(a1, a2) end)
                    return true
                elseif r:IsA("RemoteFunction") then
                    pcall(function() r:InvokeServer(a1, a2) end)
                    return true
                end
            end
        end
        return false
    end

    local function clickProximity(obj)
        if not obj then return end
        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            pcall(function() fireproximityprompt(prompt) end)
            return true
        end
        return false
    end

    local function findByNames(parent, names, recursive)
        for _, name in ipairs(names) do
            local found = recursive and parent:FindFirstChild(name, true) or parent:FindFirstChild(name)
            if found then return found end
        end
        return nil
    end

    -- ── Auto Plant ────────────────────────────
    local function doPlant()
        -- Remote approach
        local fired = tryRemote(
            {"PlantSeed","Plant","PlantCrop","SowSeed","Sow"},
            state.ShopSeed
        )
        if fired then return end

        -- ProximityPrompt scan: find empty plots belonging to local player
        for _, obj in pairs(Space:GetDescendants()) do
            if not state.AutoPlant then break end
            local name = obj.Name:lower()
            local isOwnedByMe = obj:GetAttribute("Owner") == Player.Name
                or obj:GetAttribute("OwnerId") == Player.UserId
                or obj:GetAttribute("PlayerId") == Player.UserId
            if (name:find("empt") or name:find("soil") or name:find("plot")) and (isOwnedByMe or not obj:GetAttribute("Owner")) then
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    local pos = obj:IsA("Model") and obj.PrimaryPart and obj.PrimaryPart.Position
                        or (obj:IsA("BasePart") and obj.Position)
                    if pos then tpTo(pos); task.wait(0.1) end
                    pcall(function() fireproximityprompt(prompt) end)
                    task.wait(state.PlantDelay)
                end
            end
        end
    end

    -- ── Auto Harvest ──────────────────────────
    local function doHarvest()
        local fired = tryRemote({"HarvestCrop","Harvest","HarvestAll","CollectCrop","Collect"})
        if fired then return end

        -- ProximityPrompt scan: find harvestable crops
        for _, obj in pairs(Space:GetDescendants()) do
            if not state.AutoHarvest then break end
            local name = obj.Name:lower()
            local isReady = obj:GetAttribute("Ready") == true
                or obj:GetAttribute("Grown") == true
                or obj:GetAttribute("Harvestable") == true
            -- match any crop-like name, or anything with a Ready attribute
            local looksLikeCrop = name:find("crop") or name:find("plant") or name:find("fruit")
                or name:find("harvest") or name:find("carrot") or name:find("tomato")
                or name:find("berry") or name:find("corn") or name:find("flower")
                or name:find("pumpkin") or name:find("melon") or name:find("bamboo")
            if looksLikeCrop or isReady then
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    local pos = obj:IsA("Model") and obj.PrimaryPart and obj.PrimaryPart.Position
                        or (obj:IsA("BasePart") and obj.Position)
                    if pos then tpTo(pos); task.wait(0.1) end
                    pcall(function() fireproximityprompt(prompt) end)
                    task.wait(0.15)
                end
            end
        end
    end

    -- ── Auto Sell ─────────────────────────────
    local function doSell()
        local fired = tryRemote({"SellAll","Sell","SellCrops","SellInventory","SellProduce","SellItems"})
        if fired then return end

        local sellObj = findByNames(Space, {"SellStand","SellNPC","Merchant","Seller","SellArea","Shop"}, true)
        if sellObj then
            local pos = sellObj:IsA("Model") and sellObj.PrimaryPart and sellObj.PrimaryPart.Position
                or (sellObj:IsA("BasePart") and sellObj.Position)
            if pos then tpTo(pos); task.wait(0.3) end
            clickProximity(sellObj)
        end
    end

    -- ── Auto Shop ─────────────────────────────
    local function doShop()
        local fired = tryRemote(
            {"BuySeed","Purchase","BuyItem","BuyCrop","BuyFromShop","ShopBuy"},
            state.ShopSeed, state.ShopAmount
        )
        if fired then return end

        local shopObj = findByNames(Space, {"SeedShop","Shop","Store","SeedStore","GardenShop"}, true)
        if shopObj then
            local pos = shopObj:IsA("Model") and shopObj.PrimaryPart and shopObj.PrimaryPart.Position
                or (shopObj:IsA("BasePart") and shopObj.Position)
            if pos then tpTo(pos); task.wait(0.2) end
            clickProximity(shopObj)
        end
    end

    -- ── Auto Steal ────────────────────────────
    local function doSteal()
        local fired = tryRemote({"StealCrop","Steal","StealItem","StealHarvest"})
        if fired then return end

        -- Scan for other players' ripe crops and swipe them
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= Player then
                if not state.AutoSteal then break end
                for _, obj in pairs(Space:GetDescendants()) do
                    if not state.AutoSteal then break end
                    local ownerMatch = obj:GetAttribute("Owner") == plr.Name
                        or obj:GetAttribute("OwnerId") == plr.UserId
                        or obj:GetAttribute("PlayerId") == plr.UserId
                    if ownerMatch then
                        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            local pos = obj:IsA("Model") and obj.PrimaryPart and obj.PrimaryPart.Position
                                or (obj:IsA("BasePart") and obj.Position)
                            if pos then tpTo(pos); task.wait(0.1) end
                            pcall(function() fireproximityprompt(prompt) end)
                            task.wait(0.15)
                        end
                    end
                end
            end
        end
    end

    -- ── Thread manager ────────────────────────
    local function startLoop(key, delay, fn)
        if threads[key] then task.cancel(threads[key]) end
        threads[key] = task.spawn(function()
            while state[key] do
                pcall(fn)
                task.wait(delay)
            end
        end)
    end

    local function stopLoop(key)
        state[key] = false
        if threads[key] then task.cancel(threads[key]); threads[key] = nil end
    end

    -- ── UI ────────────────────────────────────
    local GAG   = window:tab({name = "GAG 2"})
    local gcol  = GAG:column()
    local farming, shopSec, stealSec = gcol:multi_section({names = {"Farming", "Shop", "Steal"}})

    -- Farming
    farming:toggle({name = "Auto Plant",   flag = "gag_auto_plant",   callback = function(s)
        state.AutoPlant = s
        if s then startLoop("AutoPlant", state.PlantDelay + 0.5, doPlant) else stopLoop("AutoPlant") end
    end})
    farming:toggle({name = "Auto Harvest", flag = "gag_auto_harvest", callback = function(s)
        state.AutoHarvest = s
        if s then startLoop("AutoHarvest", 0.5, doHarvest) else stopLoop("AutoHarvest") end
    end})
    farming:toggle({name = "Auto Sell",    flag = "gag_auto_sell",    callback = function(s)
        state.AutoSell = s
        if s then startLoop("AutoSell", state.SellDelay, doSell) else stopLoop("AutoSell") end
    end})
    farming:slider({name = "Plant Delay", flag = "gag_plant_delay", min = 0.1, max = 5, default = 0.5, interval = 0.1, suffix = "s", callback = function(v)
        state.PlantDelay = v
    end})
    farming:slider({name = "Sell Delay",  flag = "gag_sell_delay",  min = 0.5, max = 10, default = 2, interval = 0.5, suffix = "s", callback = function(v)
        state.SellDelay = v
    end})

    -- Shop
    shopSec:dropdown({name = "Seed", flag = "gag_seed_type", items = {
        "Carrot","Strawberry","Blueberry","Tomato","Corn",
        "Watermelon","Pumpkin","Sunflower","Rose","Bamboo",
        "Cactus","Mushroom","Grape","Mango","Coconut",
    }, default = "Carrot", callback = function(v)
        state.ShopSeed = v
    end})
    shopSec:slider({name = "Buy Amount", flag = "gag_buy_amount", min = 1, max = 99, default = 1, interval = 1, callback = function(v)
        state.ShopAmount = v
    end})
    shopSec:toggle({name = "Auto Shop", flag = "gag_auto_shop", callback = function(s)
        state.AutoShop = s
        if s then startLoop("AutoShop", 3, doShop) else stopLoop("AutoShop") end
    end})

    -- Steal
    stealSec:toggle({name = "Auto Steal", flag = "gag_auto_steal", callback = function(s)
        state.AutoSteal = s
        if s then startLoop("AutoSteal", 1, doSteal) else stopLoop("AutoSteal") end
    end})
    stealSec:button_holder({})
    stealSec:button({name = "Steal All Now", callback = function()
        task.spawn(pcall, doSteal)
    end})
end
