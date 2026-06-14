return function(window, library)
    local TDS    = window:tab({name = "TDS"})
    local tdscol = TDS:column()
    local tdssec = tdscol:section({name = "Scripts", toggle = false})

    tdssec:button_holder({})
    tdssec:button({name = "Main Hub", callback = function()
        local ok, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/DuxiiT/auto-strat/refs/heads/main/Library.lua"))()
        end)
        if not ok then warn("[TDS Main Hub] Failed: " .. tostring(err)) end
    end})
end
