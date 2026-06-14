return function(window, library)
    local Players = game:GetService("Players")
    local RS      = game:GetService("ReplicatedStorage")
    local Space   = game:GetService("Workspace")
    local VIM     = game:GetService("VirtualInputManager")
    local Player  = Players.LocalPlayer

    -- ── Remote capture ────────────────────────────────────────────────────────
    local captured    = {}
    local captureNext = nil
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

    -- ── State ─────────────────────────────────────────────────────────────────
    local state = {
        AutoHarvest   = false,
        AutoSell      = false,
        AutoPlant     = false,
        AutoShovel    = false,
        AutoWater     = false,
        AutoSprinkler = false,
        AutoShopSeed  = false,
        AutoShopGear  = false,
        AutoShopPet   = false,
        AutoOpenPacks = false,
        AutoSteal     = false,
        HarvestDelay  = 0.15,
        PlantSeed     = "Carrot",
        BuyAmount     = 1,
        SellFull      = true,
    }
    local threads = {}

    -- ── Helpers ───────────────────────────────────────────────────────────────
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

    local function firePrompt(p)
        if p and p.Parent then pcall(function() fireproximityprompt(p) end) end
    end

    local function clickBtn(btn)
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
                local pn = obj.Parent.Name:lower()
                for _, kw in ipairs(keywords) do
                    if at:find(kw, 1, true) or ot:find(kw, 1, true) or pn:find(kw, 1, true) then
                        table.insert(found, obj)
                        break
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

    -- ── Tool equip ───────────────────────────────────────────────────────────
    local function equipTool(namePart)
        local char = Player.Character
        local bp   = Player.Backpack
        if not char or not bp then return false end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return false end
        local low = namePart:lower()
        for _, tool in pairs(bp:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower():find(low, 1, true) then
                pcall(function() hum:EquipTool(tool) end)
                return true
            end
        end
        return false
    end

    local function unequipTool()
        local char = Player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum:UnequipTools() end) end
    end

    -- ── Bag full (100/100 fruits) ─────────────────────────────────────────────
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

    local function getBagCount()
        local best = nil
        for _, obj in pairs(Player.PlayerGui:GetDescendants()) do
            if obj:IsA("TextLabel") then
                local cur, max = obj.Text:match("(%d+)%s*/%s*(%d+)")
                if cur and max then
                    local c, m = tonumber(cur), tonumber(max)
                    if m and m > 10 then best = {c = c, m = m} end
                end
            end
        end
        return best
    end

    -- ── Sell ─────────────────────────────────────────────────────────────────
    local SELL_KW = {"sell","vendor","market","shop","merchant","trader","npc","stall","store","cash","money"}

    local function doSell()
        if fireCapture("sell") then return end
        local btn = findGuiButton({"sell all","sell","cash out","submit"})
        if btn then clickBtn(btn); task.wait(0.5); return end
        local prompts = getPrompts(SELL_KW)
        if #prompts > 0 then
            local p = prompts[1]
            local pos = getPos(p.Parent)
            if pos then tpTo(pos); task.wait(0.15) end
            firePrompt(p)
        end
    end

    -- ── Harvest ──────────────────────────────────────────────────────────────
    local HARVEST_KW = {"harvest","collect","pick","gather","reap","take"}

    local function doHarvest()
        if state.SellFull and isBagFull() then
            doSell(); task.wait(1.5)
        end
        fireAll(HARVEST_KW, state.HarvestDelay, function() return state.AutoHarvest end)
    end

    -- ── Plant ────────────────────────────────────────────────────────────────
    local PLANT_KW = {"plant","sow","seed","insert","grow","place","pot","soil","plot"}

    local function doPlant()
        if fireCapture("plant") then return end
        local btn = findGuiButton({"plant","sow","seed"})
        if btn then clickBtn(btn); task.wait(0.3); return end
        -- try equipping seeds tool first
        equipTool("seed")
        task.wait(0.2)
        fireAll(PLANT_KW, 0.3, function() return state.AutoPlant end)
        unequipTool()
    end

    -- ── Shovel ───────────────────────────────────────────────────────────────
    local SHOVEL_KW = {"shovel","dig","remove","clear","uproot","destroy","delete","till"}

    local function doShovel()
        if fireCapture("shovel") then return end
        local gotTool = equipTool("shovel")
        if gotTool then task.wait(0.2) end
        fireAll(SHOVEL_KW, 0.3, function() return state.AutoShovel end)
        if gotTool then unequipTool() end
    end

    -- ── Water ────────────────────────────────────────────────────────────────
    local WATER_KW = {"water","irrigat","hydrat","sprinkl"}

    local function doWater()
        if fireCapture("water") then return end
        local gotTool = equipTool("watering") or equipTool("water can") or equipTool("can")
        if gotTool then task.wait(0.2) end
        fireAll(WATER_KW, 0.2, function() return state.AutoWater end)
        if gotTool then unequipTool() end
    end

    -- ── Sprinkler ────────────────────────────────────────────────────────────
    local SPRINK_KW = {"sprinkler","place sprinkler","install","set sprinkler"}

    local function doSprinkler()
        if fireCapture("sprinkler") then return end
        local gotTool = equipTool("sprinkler")
        if gotTool then task.wait(0.2) end
        fireAll(SPRINK_KW, 0.5, function() return state.AutoSprinkler end)
        if gotTool then
            -- also try clicking empty soil plots with tool equipped
            for _, obj in pairs(Space:GetDescendants()) do
                if not state.AutoSprinkler then break end
                local name = obj.Name:lower()
                if (name:find("soil") or name:find("plot") or name:find("tile")) and obj:IsA("BasePart") then
                    local pos = obj.Position
                    tpTo(pos); task.wait(0.1)
                    -- fire any prompt on parent
                    local pp = obj.Parent
                    if pp then
                        local p2 = pp:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if p2 then firePrompt(p2) end
                    end
                    task.wait(0.3)
                end
            end
            unequipTool()
        end
    end

    -- ── Shop ─────────────────────────────────────────────────────────────────
    local function doShopSeed()
        if fireCapture("shop_seed") then return end
        -- try opening seed shop GUI button
        local btn = findGuiButton({"seed shop","buy seeds","seeds","sprout","shop"})
        if btn then
            clickBtn(btn); task.wait(0.5)
            -- now try finding the seed we want and clicking buy
            local seedBtn = findGuiButton({state.PlantSeed:lower(), "buy", "purchase"})
            if seedBtn then
                for i = 1, state.BuyAmount do
                    clickBtn(seedBtn); task.wait(0.1)
                end
            end
            return
        end
        -- try proximity prompt on seed shop NPC
        local prompts = getPrompts({"seed","shop","sprout","buy","purchase","store"})
        if #prompts > 0 then
            local p = prompts[1]
            local pos = getPos(p.Parent)
            if pos then tpTo(pos); task.wait(0.15) end
            firePrompt(p)
        end
    end

    local function doShopGear()
        if fireCapture("shop_gear") then return end
        local btn = findGuiButton({"gear shop","tools","gear","wrench","equipment","shop"})
        if btn then clickBtn(btn); task.wait(0.5); return end
        local prompts = getPrompts({"gear","tool","equipment","wrench","supply"})
        if #prompts > 0 then
            local p = prompts[1]
            local pos = getPos(p.Parent)
            if pos then tpTo(pos); task.wait(0.15) end
            firePrompt(p)
        end
    end

    local function doShopPet()
        if fireCapture("shop_pet") then return end
        local btn = findGuiButton({"pet shop","pets","paw","adopt","buy pet"})
        if btn then clickBtn(btn); task.wait(0.5); return end
        local prompts = getPrompts({"pet","adopt","paw","animal","companion"})
        if #prompts > 0 then
            local p = prompts[1]
            local pos = getPos(p.Parent)
            if pos then tpTo(pos); task.wait(0.15) end
            firePrompt(p)
        end
    end

    local function doOpenPacks()
        if fireCapture("open_pack") then return end
        -- find seed packs / crates in inventory GUI
        local btn = findGuiButton({"open pack","seed pack","open all","open crate","unbox","open box"})
        if btn then
            for i = 1, 99 do
                if not state.AutoOpenPacks then break end
                clickBtn(btn); task.wait(0.3)
            end
            return
        end
        -- try proximity prompt to open packs
        local prompts = getPrompts({"open","pack","crate","box","unbox","seed pack"})
        if #prompts > 0 then
            local p = prompts[1]
            firePrompt(p); task.wait(0.3)
        end
    end

    -- ── Steal ────────────────────────────────────────────────────────────────
    local function doSteal()
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= Player then
                if not state.AutoSteal then break end
                for _, obj in pairs(Space:GetDescendants()) do
                    if not state.AutoSteal then break end
                    local ownerId = obj:GetAttribute("OwnerId") or obj:GetAttribute("PlayerId")
                    local ownerName = obj:GetAttribute("Owner") or obj:GetAttribute("PlayerName")
                    local isOther = (ownerId == plr.UserId) or (ownerName == plr.Name)
                    if isOther then
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

    -- ── Mutation scanner ──────────────────────────────────────────────────────
    local function getMutationInfo()
        local results = {}
        for _, obj in pairs(Space:GetDescendants()) do
            -- check for mutation attribute (common names games use)
            local mutation = obj:GetAttribute("Mutation")
                or obj:GetAttribute("MutationType")
                or obj:GetAttribute("Rarity")
                or obj:GetAttribute("Type")
            if mutation and mutation ~= "" and mutation ~= "Normal" and mutation ~= "Common" then
                local name = obj.Name
                local pos  = getPos(obj)
                table.insert(results, {name = name, mutation = tostring(mutation), pos = pos})
            end
        end
        -- also check TextLabels for mutation indicators
        for _, obj in pairs(Player.PlayerGui:GetDescendants()) do
            if obj:IsA("TextLabel") then
                local low = obj.Text:lower()
                if low:find("rainbow") or low:find("gold") or low:find("prismatic")
                    or low:find("mutation") or low:find("shimmer") or low:find("radiant") then
                    table.insert(results, {name = "UI: " .. obj.Text, mutation = obj.Text, pos = nil})
                end
            end
        end
        return results
    end

    -- ── Stock predictor ───────────────────────────────────────────────────────
    local function getStockInfo()
        local info = {}
        -- try to find stock data in ReplicatedStorage
        pcall(function()
            for _, obj in pairs(RS:GetDescendants()) do
                local lowName = obj.Name:lower()
                if lowName:find("stock") or lowName:find("shop") or lowName:find("inventory")
                    or lowName:find("available") or lowName:find("seed") then
                    if obj:IsA("StringValue") or obj:IsA("IntValue") or obj:IsA("NumberValue") then
                        table.insert(info, obj.Name .. ": " .. tostring(obj.Value))
                    end
                end
            end
        end)
        -- try PlayerGui for stock display
        for _, obj in pairs(Player.PlayerGui:GetDescendants()) do
            if obj:IsA("TextLabel") then
                local low = obj.Text:lower()
                if low:find("stock") or low:find("available") or low:find("time") then
                    local parent = obj.Parent and obj.Parent.Name or "?"
                    table.insert(info, parent .. ": " .. obj.Text)
                end
            end
        end
        return info
    end

    -- ── Loop manager ──────────────────────────────────────────────────────────
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

    -- ── UI ────────────────────────────────────────────────────────────────────
    local GAG  = window:tab({name = "GAG 2"})
    local gcol = GAG:column()

    local farmSec, shopSec, stealSec, infoSec, capSec =
        gcol:multi_section({names = {"Farm", "Shop", "Steal", "Info", "Capture"}})

    -- ┌── FARM ─────────────────────────────────────────────────────────────────
    farmSec:toggle({name = "Auto Harvest", flag = "gag_harvest", default = false, callback = function(s)
        state.AutoHarvest = s
        if s then startLoop("AutoHarvest", 1.5, doHarvest) else stopLoop("AutoHarvest") end
    end})

    farmSec:toggle({name = "Sell when Full", flag = "gag_sellfull", default = true, callback = function(s)
        state.SellFull = s
    end})

    farmSec:toggle({name = "Auto Sell", flag = "gag_sell", default = false, callback = function(s)
        state.AutoSell = s
        if s then startLoop("AutoSell", 3, doSell) else stopLoop("AutoSell") end
    end})

    farmSec:toggle({name = "Auto Plant", flag = "gag_plant", default = false, callback = function(s)
        state.AutoPlant = s
        if s then startLoop("AutoPlant", 2, doPlant) else stopLoop("AutoPlant") end
    end})

    farmSec:toggle({name = "Auto Shovel", flag = "gag_shovel", default = false, callback = function(s)
        state.AutoShovel = s
        if s then startLoop("AutoShovel", 2, doShovel) else stopLoop("AutoShovel") end
    end})

    farmSec:toggle({name = "Auto Water", flag = "gag_water", default = false, callback = function(s)
        state.AutoWater = s
        if s then startLoop("AutoWater", 2, doWater) else stopLoop("AutoWater") end
    end})

    farmSec:toggle({name = "Auto Sprinkler", flag = "gag_sprinkler", default = false, callback = function(s)
        state.AutoSprinkler = s
        if s then startLoop("AutoSprinkler", 5, doSprinkler) else stopLoop("AutoSprinkler") end
    end})

    farmSec:slider({name = "Harvest Delay", flag = "gag_hdelay", min = 0.05, max = 2, default = 0.15,
        interval = 0.05, suffix = "s", callback = function(v) state.HarvestDelay = v end})

    farmSec:button_holder({})
    farmSec:button({name = "Harvest Now", callback = function() task.spawn(pcall, doHarvest) end})
    farmSec:button({name = "Sell Now",    callback = function() task.spawn(pcall, doSell)    end})
    farmSec:button({name = "Plant Now",   callback = function() task.spawn(pcall, doPlant)   end})
    farmSec:button({name = "Shovel Now",  callback = function() task.spawn(pcall, doShovel)  end})

    -- ┌── SHOP ─────────────────────────────────────────────────────────────────
    local SEEDS = {
        "Carrot","Strawberry","Blueberry","Tomato","Corn",
        "Watermelon","Pumpkin","Sunflower","Rose","Bamboo",
        "Cactus","Mushroom","Grape","Mango","Coconut","Apple",
        "Lemon","Pepper","Potato","Beet","Radish","Onion",
    }

    shopSec:dropdown({name = "Seed Type", flag = "gag_seed", items = SEEDS, default = "Carrot",
        callback = function(v) state.PlantSeed = v end})

    shopSec:slider({name = "Buy Amount", flag = "gag_buyamt", min = 1, max = 99, default = 1,
        interval = 1, callback = function(v) state.BuyAmount = v end})

    shopSec:toggle({name = "Auto Buy Seeds", flag = "gag_shopSeed", default = false, callback = function(s)
        state.AutoShopSeed = s
        if s then startLoop("AutoShopSeed", 8, doShopSeed) else stopLoop("AutoShopSeed") end
    end})

    shopSec:toggle({name = "Auto Buy Gear", flag = "gag_shopGear", default = false, callback = function(s)
        state.AutoShopGear = s
        if s then startLoop("AutoShopGear", 10, doShopGear) else stopLoop("AutoShopGear") end
    end})

    shopSec:toggle({name = "Auto Buy Pets", flag = "gag_shopPet", default = false, callback = function(s)
        state.AutoShopPet = s
        if s then startLoop("AutoShopPet", 10, doShopPet) else stopLoop("AutoShopPet") end
    end})

    shopSec:toggle({name = "Auto Open Packs", flag = "gag_openPacks", default = false, callback = function(s)
        state.AutoOpenPacks = s
        if s then startLoop("AutoOpenPacks", 1, doOpenPacks) else stopLoop("AutoOpenPacks") end
    end})

    shopSec:button_holder({})
    shopSec:button({name = "Buy Seeds Now", callback = function() task.spawn(pcall, doShopSeed) end})
    shopSec:button({name = "Buy Gear Now",  callback = function() task.spawn(pcall, doShopGear) end})
    shopSec:button({name = "Buy Pets Now",  callback = function() task.spawn(pcall, doShopPet)  end})
    shopSec:button({name = "Open Packs Now",callback = function() task.spawn(pcall, doOpenPacks)end})

    -- ┌── STEAL ────────────────────────────────────────────────────────────────
    stealSec:toggle({name = "Auto Steal", flag = "gag_steal", default = false, callback = function(s)
        state.AutoSteal = s
        if s then startLoop("AutoSteal", 2, doSteal) else stopLoop("AutoSteal") end
    end})
    stealSec:button_holder({})
    stealSec:button({name = "Steal Now", callback = function() task.spawn(pcall, doSteal) end})

    -- ┌── INFO ─────────────────────────────────────────────────────────────────
    local mutLabel   = infoSec:label({name = "Mutations: press Scan"})
    local stockLabel = infoSec:label({name = "Stock: press Scan"})
    infoSec:button_holder({})

    infoSec:button({name = "Scan Mutations", callback = function()
        local results = getMutationInfo()
        if #results == 0 then
            pcall(function() mutLabel.set("Mutations: none found") end)
            library:notification({text = "No mutations found", time = 3})
        else
            local out = "Mutations: "
            for i, r in ipairs(results) do
                out = out .. r.mutation .. "(" .. r.name .. ")"
                if i < #results then out = out .. ", " end
                print("[GAG] Mutation: " .. r.mutation .. " on " .. r.name)
            end
            pcall(function() mutLabel.set(out:sub(1, 60)) end)
            library:notification({text = #results .. " mutations - check F9", time = 4})
        end
    end})

    infoSec:button({name = "Scan Stock", callback = function()
        local results = getStockInfo()
        if #results == 0 then
            pcall(function() stockLabel.set("Stock: none found") end)
            library:notification({text = "No stock data found", time = 3})
        else
            for _, r in ipairs(results) do print("[GAG] Stock: " .. r) end
            pcall(function() stockLabel.set(results[1] and results[1]:sub(1, 50) or "Stock: see F9") end)
            library:notification({text = #results .. " stock entries - check F9", time = 4})
        end
    end})

    infoSec:button({name = "Scan Wild Pets", callback = function()
        local count = 0
        for _, obj in pairs(Space:GetDescendants()) do
            local low = obj.Name:lower()
            if low:find("pet") or low:find("wild") or low:find("spawn") then
                local pos = getPos(obj)
                if pos then
                    count = count + 1
                    print("[GAG] Wild object: " .. obj.Name .. " at " .. tostring(pos))
                end
            end
        end
        library:notification({text = count .. " wild objects - check F9", time = 4})
    end})

    -- ┌── CAPTURE ──────────────────────────────────────────────────────────────
    local hookStatus = hookActive and "Hook: active" or "Hook: not supported"
    capSec:label({name = hookStatus})
    capSec:label({name = "Click Capture, then do action in game"})

    capSec:button_holder({})
    capSec:button({name = "Capture Sell",     callback = function()
        captureNext = "sell"
        library:notification({text = "Click Sell in-game now", time = 5})
    end})
    capSec:button({name = "Capture Plant",    callback = function()
        captureNext = "plant"
        library:notification({text = "Plant a seed in-game now", time = 5})
    end})
    capSec:button({name = "Capture Shovel",   callback = function()
        captureNext = "shovel"
        library:notification({text = "Use shovel in-game now", time = 5})
    end})
    capSec:button({name = "Capture Water",    callback = function()
        captureNext = "water"
        library:notification({text = "Water a plant in-game now", time = 5})
    end})
    capSec:button({name = "Capture Sprinkler",callback = function()
        captureNext = "sprinkler"
        library:notification({text = "Place sprinkler in-game now", time = 5})
    end})
    capSec:button({name = "Capture Buy Seed", callback = function()
        captureNext = "shop_seed"
        library:notification({text = "Buy a seed in-game now", time = 5})
    end})
    capSec:button({name = "Capture Open Pack",callback = function()
        captureNext = "open_pack"
        library:notification({text = "Open a pack in-game now", time = 5})
    end})

    capSec:button_holder({})
    capSec:button({name = "Clear Captures", callback = function()
        captured = {}
        captureNext = nil
        library:notification({text = "Captures cleared", time = 2})
    end})
    capSec:button({name = "List Captures", callback = function()
        local count = 0
        for k, v in pairs(captured) do
            count = count + 1
            print("[GAG] Captured '" .. k .. "': " .. v.remote:GetFullName() .. " (" .. v.method .. ")")
        end
        library:notification({text = count .. " captures active - see F9", time = 3})
    end})

    -- Debug scan buttons
    capSec:button_holder({})
    capSec:button({name = "Scan All Prompts", callback = function()
        local seen, count = {}, 0
        for _, obj in pairs(Space:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                local k = obj.ActionText .. "|" .. obj.ObjectText
                if not seen[k] then
                    seen[k] = true; count = count + 1
                    print("[GAG] Prompt Action='" .. obj.ActionText .. "' Object='" .. obj.ObjectText .. "' Parent=" .. obj.Parent.Name)
                end
            end
        end
        library:notification({text = count .. " prompts - check F9", time = 4})
    end})
    capSec:button({name = "Scan GUI Buttons", callback = function()
        local count = 0
        for _, obj in pairs(Player.PlayerGui:GetDescendants()) do
            if obj.Visible and (obj:IsA("TextButton") or obj:IsA("ImageButton")) then
                count = count + 1
                local txt = obj:IsA("TextButton") and obj.Text or "(img)"
                print("[GAG] Button '" .. txt .. "' Name='" .. obj.Name .. "' " .. obj:GetFullName())
            end
        end
        library:notification({text = count .. " buttons - check F9", time = 4})
    end})
    capSec:button({name = "Scan RS Remotes", callback = function()
        local count = 0
        for _, obj in pairs(RS:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                count = count + 1
                print("[GAG] Remote: " .. obj:GetFullName())
            end
        end
        library:notification({text = count .. " remotes - check F9", time = 4})
    end})
    capSec:button({name = "Dump Bag Info", callback = function()
        local bag = getBagCount()
        if bag then
            library:notification({text = "Bag: " .. bag.c .. "/" .. bag.m, time = 4})
        else
            library:notification({text = "Bag UI not found", time = 3})
        end
    end})
end
