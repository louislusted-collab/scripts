return function(window, library)
    local NDS    = window:tab({name = "NDS"})
    local ndscol = NDS:column()
    local ndssec = ndscol:section({name = "Scripts", toggle = false})

    ndssec:button_holder({})
    ndssec:button({name = "God Mode", callback = function()
        local ok, err = pcall(function()
            loadstring(game:HttpGet("https://rawscripts.net/raw/Natural-Disaster-Survival-NATURAL-DISASTER-GOD-MODE-200705"))()
        end)
        if not ok then warn("[NDS God Mode] Failed: " .. tostring(err)) end
    end})
end
