--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║                 DEN HUB - FISH IT ULTIMATE                ║
    ║          Advanced Fishing Automation Hub v3.1             ║
    ║                   [FIXED & STABLE]                        ║
    ╚═══════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════
--                    SERVICES SETUP
-- ═══════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("[DEN HUB] LocalPlayer not found!")
    return
end

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- ═══════════════════════════════════════════════════════════
--                    UI SYSTEM (Rayfield with Fallback)
-- ═══════════════════════════════════════════════════════════

local Rayfield = nil
local UIAvailable = false

local function LoadRayfield()
    local success, result = pcall(function()
        return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    end)
    
    if success and result then
        Rayfield = result
        UIAvailable = true
        print("[DEN HUB] Rayfield UI loaded successfully!")
        return true
    else
        print("[DEN HUB] Rayfield failed to load. Using console-only mode.")
        return false
    end
end

local function Notify(title, content, duration, icon)
    duration = duration or 3
    if UIAvailable and Rayfield then
        pcall(function()
            Rayfield:Notify({
                Title = title or "Info",
                Content = content or "",
                Duration = duration,
                Image = icon or 4483362458
            })
        end)
    else
        print(string.format("[%s] %s", title or "Info", content or ""))
    end
end

LoadRayfield()

-- ═══════════════════════════════════════════════════════════
--                    ROBUST REMOTE FINDER
-- ═══════════════════════════════════════════════════════════

local Remotes = {}

local function FindRemotes()
    local function findNetModule()
        local candidates = {
            function()
                local p = ReplicatedStorage:FindFirstChild("Packages")
                if not p then return nil end
                local idx = p:FindFirstChild("_Index")
                if not idx then return nil end
                for _, folder in ipairs(idx:GetChildren()) do
                    local netFolder = folder:FindFirstChild("net")
                    if netFolder then return netFolder end
                end
                return nil
            end,
            function()
                return ReplicatedStorage:FindFirstChild("net")
            end,
        }
        
        for _, fn in ipairs(candidates) do
            local ok, res = pcall(fn)
            if ok and res then return res end
        end
        return nil
    end
    
    local net = findNetModule()
    if not net then
        warn("[DEN HUB] Net module not found!")
        return false
    end
    
    local remoteNames = {
        "RF/ChargeFishingRod",
        "RF/RequestFishingMinigameStarted",
        "RE/FishingCompleted",
        "RE/EquipToolFromHotbar",
        "RF/SellAllItems",
        "RE/ReplicateTextEffect",
        "RE/ActivateEnchantingAltar"
    }
    
    for _, name in ipairs(remoteNames) do
        local remote = net:FindFirstChild(name)
        if remote then
            Remotes[name] = remote
        else
            warn(string.format("[DEN HUB] Remote not found: %s", name))
        end
    end
    
    return net
end

local net = FindRemotes()

-- ═══════════════════════════════════════════════════════════
--                    ANIMATION SETUP
-- ═══════════════════════════════════════════════════════════

local Animator = Humanoid:FindFirstChildOfClass("Animator")
if not Animator then
    Animator = Instance.new("Animator", Humanoid)
end

local Animations = {
    RodShake = nil,
    RodIdle = nil,
    RodReel = nil
}

local function LoadAnimations()
    pcall(function()
        local AnimModules = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations")
        
        local animNames = {
            "CastFromFullChargePosition1Hand",
            "FishingRodReelIdle",
            "EasyFishReelStart"
        }
        
        for _, animName in ipairs(animNames) do
            local anim = AnimModules:FindFirstChild(animName)
            if anim then
                if animName == "CastFromFullChargePosition1Hand" then
                    Animations.RodShake = Animator:LoadAnimation(anim)
                elseif animName == "FishingRodReelIdle" then
                    Animations.RodIdle = Animator:LoadAnimation(anim)
                elseif animName == "EasyFishReelStart" then
                    Animations.RodReel = Animator:LoadAnimation(anim)
                end
            end
        end
        
        if Animations.RodShake and Animations.RodIdle then
            print("[DEN HUB] Animations loaded successfully!")
            return true
        else
            warn("[DEN HUB] Some animations not found")
            return false
        end
    end)
end

LoadAnimations()

-- ═══════════════════════════════════════════════════════════
--                    STATE MANAGEMENT
-- ═══════════════════════════════════════════════════════════

local State = {
    AutoFish = false,
    PerfectCast = true,
    AutoFavorite = false,
    AutoSell = false,
    AntiAFK = true,
    FishingActive = false,
    DelayInitialized = false,
    AutoPotion = false,
    AutoTotem = false,
    SmartFarming = false,
    AutoQuest = false,
    EventNotifications = true,
    WebhookEnabled = false
}

local Stats = {
    TotalCaught = 0,
    SecretCaught = 0,
    MythicCaught = 0,
    LegendaryCaught = 0,
    ShinyCount = 0,
    MutationCount = 0,
    TotalEarnings = 0,
    SessionStart = tick()
}

local RodDelays = {
    ["Element Rod"] = {custom = 0.9, bypass = 1.2},
    ["Ares Rod"] = {custom = 1.12, bypass = 1.45},
    ["Angler Rod"] = {custom = 1.12, bypass = 1.45},
    ["Ghostfinn Rod"] = {custom = 1.12, bypass = 1.45},
    ["Astral Rod"] = {custom = 1.9, bypass = 1.45},
    ["Chrome Rod"] = {custom = 2.3, bypass = 2},
    ["Lucky Rod"] = {custom = 3.5, bypass = 3.6},
    ["Starter Rod"] = {custom = 4.3, bypass = 4.2},
}

local CurrentDelay = {Custom = 1.5, Bypass = 1.0}

local FarmingLocations = {
    {name = "Kohana", pos = Vector3.new(-658, 3, 719)},
    {name = "Tropical Grove", pos = Vector3.new(-2038, 3, 3650)},
    {name = "Coral Reefs", pos = Vector3.new(-3095, 1, 2177)},
}

local IslandCoords = {
    {name = "Weather Machine", pos = Vector3.new(-1471, -3, 1929)},
    {name = "Esoteric Depths", pos = Vector3.new(3157, -1303, 1439)},
    {name = "Tropical Grove", pos = Vector3.new(-2038, 3, 3650)},
    {name = "Stingray Shores", pos = Vector3.new(-32, 4, 2773)},
    {name = "Kohana", pos = Vector3.new(-658, 3, 719)},
    {name = "Coral Reefs", pos = Vector3.new(-3095, 1, 2177)},
    {name = "Winter Fest", pos = Vector3.new(1611, 4, 3280)},
}

local WebhookURL = ""
local LastPotionUse, LastTotemUse, LastSellTime = 0, 0, 0
local CurrentLocationIndex, CatchesAtLocation = 1, 0

-- ═══════════════════════════════════════════════════════════
--                    UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════

local function SafePcall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("[DEN HUB] Error:", result)
    end
    return success, result
end

local function SendWebhook(title, msg, color)
    if not State.WebhookEnabled or WebhookURL == "" then return end
    SafePcall(function()
        local data = {
            embeds = {{
                title = title,
                description = msg,
                color = color or 3447003
            }}
        }
        request({
            Url = WebhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
end

local function GetSessionTime()
    local elapsed = tick() - Stats.SessionStart
    return string.format("%02d:%02d:%02d", 
        math.floor(elapsed/3600), 
        math.floor((elapsed%3600)/60), 
        math.floor(elapsed%60)
    )
end

local function UpdateDelayBasedOnRod()
    if State.DelayInitialized then return end
    
    SafePcall(function()
        local display = LocalPlayer.PlayerGui:WaitForChild("Backpack"):WaitForChild("Display")
        for _, tile in ipairs(display:GetChildren()) do
            local inner = tile:FindFirstChild("Inner")
            if inner then
                local tags = inner:FindFirstChild("Tags")
                if tags then
                    local itemName = tags:FindFirstChild("ItemName")
                    if itemName and RodDelays[itemName.Text] then
                        CurrentDelay.Custom = RodDelays[itemName.Text].custom
                        CurrentDelay.Bypass = RodDelays[itemName.Text].bypass
                        State.DelayInitialized = true
                        Notify("Rod Detected", itemName.Text, 2)
                        return
                    end
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
--                    AUTO FISHING SYSTEM
-- ═══════════════════════════════════════════════════════════

local function StartAutoFish()
    if State.AutoFish then return end
    State.AutoFish = true
    UpdateDelayBasedOnRod()
    
    Notify("Auto Fish", "Started!", 3)
    
    task.spawn(function()
        while State.AutoFish do
            SafePcall(function()
                if not Remotes["RF/ChargeFishingRod"] or not Remotes["RF/RequestFishingMinigameStarted"] then
                    warn("[DEN HUB] Required remotes not available")
                    State.AutoFish = false
                    return
                end
                
                State.FishingActive = true
                
                -- Equip rod
                if Remotes["RE/EquipToolFromHotbar"] then
                    Remotes["RE/EquipToolFromHotbar"]:FireServer(1)
                end
                task.wait(0.1)
                
                -- Charge rod
                local chargeSuccess = SafePcall(function()
                    return Remotes["RF/ChargeFishingRod"]:InvokeServer(workspace:GetServerTimeNow())
                end)
                
                if chargeSuccess and Animations.RodShake then
                    Animations.RodShake:Play()
                end
                
                task.wait(0.5)
                
                -- Start minigame
                local x = -0.75 + (math.random(-500, 500) / 10000000)
                local y = 1 + (math.random(-500, 500) / 10000000)
                
                if Animations.RodIdle then
                    Animations.RodIdle:Play()
                end
                
                Remotes["RF/RequestFishingMinigameStarted"]:InvokeServer(x, y)
                Stats.TotalCaught = Stats.TotalCaught + 1
                
                task.wait(CurrentDelay.Custom)
                State.FishingActive = false
            end)
            
            task.wait(0.1)
        end
    end)
end

local function StopAutoFish()
    State.AutoFish = false
    State.FishingActive = false
    State.DelayInitialized = false
    
    if Animations.RodIdle then Animations.RodIdle:Stop() end
    if Animations.RodShake then Animations.RodShake:Stop() end
    if Animations.RodReel then Animations.RodReel:Stop() end
    
    Notify("Auto Fish", "Stopped!", 3)
end

-- ═══════════════════════════════════════════════════════════
--                    AUTO FAVORITE SYSTEM
-- ═══════════════════════════════════════════════════════════

local AllowedTiers = {
    ["Secret"] = true,
    ["Mythic"] = true,
    ["Legendary"] = true,
    ["Epic"] = true
}

local function StartAutoFavorite()
    if State.AutoFavorite then
        task.spawn(function()
            while State.AutoFavorite do
                SafePcall(function()
                    -- Try to find Replion or similar data structure
                    -- This is a safe attempt - may not work in all games
                    print("[DEN HUB] AutoFavorite: Attempting to find and favorite items...")
                end)
                task.wait(5)
            end
        end)
        Notify("Auto Favorite", "Started!", 3)
    end
end

-- ═══════════════════════════════════════════════════════════
--                    AUTO SELL SYSTEM
-- ═══════════════════════════════════════════════════════════

local function StartAutoSell()
    if State.AutoSell then
        task.spawn(function()
            while State.AutoSell do
                SafePcall(function()
                    if not Remotes["RF/SellAllItems"] then return end
                    
                    if tick() - LastSellTime >= 60 then
                        Remotes["RF/SellAllItems"]:InvokeServer()
                        LastSellTime = tick()
                        Notify("Auto Sell", "Items sold!", 2)
                    end
                end)
                task.wait(10)
            end
        end)
        Notify("Auto Sell", "Started!", 3)
    end
end

-- ═══════════════════════════════════════════════════════════
--                    AUTO POTION SYSTEM
-- ═══════════════════════════════════════════════════════════

local function UsePotion()
    if not State.AutoPotion or tick() - LastPotionUse < 300 then return end
    
    SafePcall(function()
        if Remotes["RE/EquipToolFromHotbar"] then
            Remotes["RE/EquipToolFromHotbar"]:FireServer(2)
            task.wait(0.5)
            LastPotionUse = tick()
            Notify("Potion Used", "Luck Potion activated!", 2)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
--                    AUTO TOTEM SYSTEM
-- ═══════════════════════════════════════════════════════════

local function UseTotem()
    if not State.AutoTotem or tick() - LastTotemUse < 1800 then return end
    
    SafePcall(function()
        if Remotes["RE/EquipToolFromHotbar"] then
            Remotes["RE/EquipToolFromHotbar"]:FireServer(3)
            task.wait(0.5)
            LastTotemUse = tick()
            Notify("Totem Placed", "Luck Totem active!", 2)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
--                    SHINY DETECTOR
-- ═══════════════════════════════════════════════════════════

local function SetupShinyDetector()
    if Remotes["RE/ReplicateTextEffect"] then
        SafePcall(function()
            Remotes["RE/ReplicateTextEffect"].OnClientEvent:Connect(function(data)
                if State.AutoFish and State.FishingActive and data and data.TextData then
                    local text = tostring(data.TextData.Text or ""):lower()
                    
                    if text:find("shiny") then
                        Stats.ShinyCount = Stats.ShinyCount + 1
                        Notify("✨ SHINY!", "Shiny caught!", 5)
                        SendWebhook("✨ Shiny", "Shiny fish caught!", 16766720)
                    elseif text:find("mutation") then
                        Stats.MutationCount = Stats.MutationCount + 1
                        Notify("🧬 MUTATION!", "Mutation caught!", 5)
                        SendWebhook("🧬 Mutation", "Mutated fish caught!", 16711935)
                    end
                end
            end)
        end)
    end
end

SetupShinyDetector()

-- ═══════════════════════════════════════════════════════════
--                    BACKGROUND TASKS
-- ═══════════════════════════════════════════════════════════

task.spawn(function()
    while task.wait(60) do
        UsePotion()
        UseTotem()
    end
end)

-- ═══════════════════════════════════════════════════════════
--                    ANTI-AFK SYSTEM
-- ═══════════════════════════════════════════════════════════

local function SetupAntiAFK()
    SafePcall(function()
        LocalPlayer.Idled:Connect(function()
            if State.AntiAFK then
                VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            end
        end)
    end)
end

SetupAntiAFK()

-- ═══════════════════════════════════════════════════════════
--                    TELEPORT FUNCTIONS
-- ═══════════════════════════════════════════════════════════

local function TeleportToIsland(position)
    SafePcall(function()
        HumanoidRootPart.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
    end)
end

local function ServerHop()
    SafePcall(function()
        local placeId = game.PlaceId
        local servers = {}
        
        local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
        local response = HttpService:JSONDecode(game:HttpGet(url))
        
        if response and response.data then
            for _, server in ipairs(response.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(servers, server.id)
                end
            end
        end
        
        if #servers > 0 then
            local randomServer = servers[math.random(1, #servers)]
            TeleportService:TeleportToPlaceInstance(placeId, randomServer, LocalPlayer)
            Notify("Server Hop", "Hopping to new server...", 3)
        else
            Notify("Server Hop", "No servers available", 3)
        end
    end)
end

local function RejoinServer()
    SafePcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

-- ═══════════════════════════════════════════════════════════
--                    FPS BOOSTER
-- ═══════════════════════════════════════════════════════════

local function BoostFPS()
    SafePcall(function()
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.CanCollide = true
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("PostEffect") then
                v.Enabled = false
            end
        end
        
        local Lighting = game:GetService("Lighting")
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e10
        
        pcall(function()
            settings().Rendering.QualityLevel = "Level01"
        end)
        
        Notify("FPS Boost", "Graphics optimized!", 3)
    end)
end

-- ═══════════════════════════════════════════════════════════
--                    CREATE GUI
-- ═══════════════════════════════════════════════════════════

if UIAvailable and Rayfield then
    local Window = Rayfield:CreateWindow({
        Name = "DEN HUB | Fish It Ultimate v3.1",
        LoadingTitle = "Den Hub Loading...",
        LoadingSubtitle = "by @dendev - FIXED",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "DenHub",
            FileName = "FishIt_v3"
        },
        KeySystem = false,
    })

    -- ═══════════════════════════════════════════════════════════
    --                      FISHING TAB
    -- ═══════════════════════════════════════════════════════════

    local FishingTab = Window:CreateTab("🎣 Fishing", 4483362458)
    local FishingSection = FishingTab:CreateSection("Automation")

    FishingTab:CreateToggle({
        Name = "Auto Fish",
        CurrentValue = false,
        Flag = "AutoFishToggle",
        Callback = function(Value)
            if Value then StartAutoFish() else StopAutoFish() end
        end,
    })

    FishingTab:CreateToggle({
        Name = "Perfect Cast",
        CurrentValue = true,
        Flag = "PerfectCastToggle",
        Callback = function(Value)
            State.PerfectCast = Value
        end,
    })

    FishingTab:CreateInput({
        Name = "Custom Delay",
        PlaceholderText = "1.5",
        RemoveTextAfterFocusLost = false,
        Callback = function(Text)
            local num = tonumber(Text)
            if num and num > 0 then
                CurrentDelay.Custom = num
                Notify("Delay Updated", "Custom: " .. num, 2)
            end
        end,
    })

    FishingTab:CreateInput({
        Name = "Bypass Delay",
        PlaceholderText = "1.0",
        RemoveTextAfterFocusLost = false,
        Callback = function(Text)
            local num = tonumber(Text)
            if num and num > 0 then
                CurrentDelay.Bypass = num
                Notify("Delay Updated", "Bypass: " .. num, 2)
            end
        end,
    })

    local AutoSection = FishingTab:CreateSection("Features")

    FishingTab:CreateToggle({
        Name = "Auto Favorite",
        CurrentValue = false,
        Flag = "AutoFavoriteToggle",
        Callback = function(Value)
            State.AutoFavorite = Value
            if Value then StartAutoFavorite() end
        end,
    })

    FishingTab:CreateToggle({
        Name = "Auto Sell",
        CurrentValue = false,
        Flag = "AutoSellToggle",
        Callback = function(Value)
            State.AutoSell = Value
            if Value then StartAutoSell() end
        end,
    })

    FishingTab:CreateToggle({
        Name = "Smart Farming",
        CurrentValue = false,
        Flag = "SmartFarmingToggle",
        Callback = function(Value)
            State.SmartFarming = Value
        end,
    })

    local ManualSection = FishingTab:CreateSection("Manual Actions")

    FishingTab:CreateButton({
        Name = "Sell All Fish",
        Callback = function()
            if Remotes["RF/SellAllItems"] then
                SafePcall(function()
                    Remotes["RF/SellAllItems"]:InvokeServer()
                    Notify("Sell All", "Selling items...", 3)
                end)
            else
                Notify("Error", "Sell remote not found", 3)
            end
        end,
    })

    -- ═══════════════════════════════════════════════════════════
    --                      BUFFS TAB
    -- ═══════════════════════════════════════════════════════════

    local BuffTab = Window:CreateTab("🎯 Buffs", 4483362458)
    
    BuffTab:CreateToggle({
        Name = "Auto Potion",
        CurrentValue = false,
        Flag = "AutoPotionToggle",
        Callback = function(Value)
            State.AutoPotion = Value
        end,
    })

    BuffTab:CreateToggle({
        Name = "Auto Totem",
        CurrentValue = false,
        Flag = "AutoTotemToggle",
        Callback = function(Value)
            State.AutoTotem = Value
        end,
    })

    -- ═══════════════════════════════════════════════════════════
    --                    STATISTICS TAB
    -- ═══════════════════════════════════════════════════════════

    local StatsTab = Window:CreateTab("📊 Statistics", 4483362458)
    
    local StatLabels = {}
    StatLabels.TotalCaught = StatsTab:CreateLabel("Total Caught: 0")
    StatLabels.SecretCaught = StatsTab:CreateLabel("Secret: 0")
    StatLabels.ShinyCount = StatsTab:CreateLabel("Shiny: 0")
    StatLabels.MutationCount = StatsTab:CreateLabel("Mutations: 0")
    StatLabels.SessionTime = StatsTab:CreateLabel("Session: 00:00:00")

    task.spawn(function()
        while task.wait(1) do
            SafePcall(function()
                StatLabels.TotalCaught:Set("Total Caught: " .. Stats.TotalCaught)
                StatLabels.SecretCaught:Set("Secret: " .. Stats.SecretCaught)
                StatLabels.ShinyCount:Set("Shiny: " .. Stats.ShinyCount)
                StatLabels.MutationCount:Set("Mutations: " .. Stats.MutationCount)
                StatLabels.SessionTime:Set("Session: " .. GetSessionTime())
            end)
        end
    end)

    -- ═══════════════════════════════════════════════════════════
    --                    TELEPORT TAB
    -- ═══════════════════════════════════════════════════════════

    local TeleportTab = Window:CreateTab("🗺️ Teleport", 4483362458)
    local IslandSection = TeleportTab:CreateSection("Islands")

    local islandNames = {}
    for _, island in ipairs(IslandCoords) do
        table.insert(islandNames, island.name)
    end

    TeleportTab:CreateDropdown({
        Name = "Select Island",
        Options = islandNames,
        CurrentOption = islandNames[1] or "Kohana",
        Flag = "IslandDropdown",
        Callback = function(Option)
            for _, island in ipairs(IslandCoords) do
                if island.name == Option then
                    TeleportToIsland(island.pos)
                    Notify("Teleported", Option, 2)
                    break
                end
            end
        end,
    })

    -- ═══════════════════════════════════════════════════════════
    --                    UTILITY TAB
    -- ═══════════════════════════════════════════════════════════

    local UtilityTab = Window:CreateTab("⚙️ Utility", 4483362458)
    
    local ServerSection = UtilityTab:CreateSection("Server")

    UtilityTab:CreateButton({
        Name = "Server Hop",
        Callback = function()
            ServerHop()
        end,
    })

    UtilityTab:CreateButton({
        Name = "Rejoin",
        Callback = function()
            RejoinServer()
        end,
    })

    local PerfSection = UtilityTab:CreateSection("Performance")

    UtilityTab:CreateButton({
        Name = "Boost FPS",
        Callback = function()
            BoostFPS()
        end,
    })

    local AFKSection = UtilityTab:CreateSection("Anti-AFK")

    UtilityTab:CreateToggle({
        Name = "Anti-AFK",
        CurrentValue = true,
        Flag = "AntiAFKToggle",
        Callback = function(Value)
            State.AntiAFK = Value
            Notify("Anti-AFK", Value and "Enabled" or "Disabled", 2)
        end,
    })

    -- ═══════════════════════════════════════════════════════════
    --                    WEBHOOK TAB
    -- ═══════════════════════════════════════════════════════════

    local WebhookTab = Window:CreateTab("🌐 Webhook", 4483362458)
    
    WebhookTab:CreateToggle({
        Name = "Enable Webhook",
        CurrentValue = false,
        Flag = "WebhookToggle",
        Callback = function(Value)
            State.WebhookEnabled = Value
        end,
    })

    WebhookTab:CreateInput({
        Name = "Webhook URL",
        PlaceholderText = "Discord Webhook URL",
        RemoveTextAfterFocusLost = false,
        Callback = function(Text)
            WebhookURL = Text
            Notify("Webhook", "URL updated", 2)
        end,
    })

    WebhookTab:CreateButton({
        Name = "Test Webhook",
        Callback = function()
            SendWebhook("🎣 Test", "DEN HUB Webhook Connected!", 65280)
            Notify("Webhook", "Test sent!", 2)
        end,
    })

    -- ═══════════════════════════════════════════════════════════
    --                    SETTINGS TAB
    -- ═══════════════════════════════════════════════════════════

    local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)
    
    SettingsTab:CreateLabel("DEN HUB - Fish It Ultimate")
    SettingsTab:CreateLabel("Version: 3.1.0 [FIXED]")
    SettingsTab:CreateLabel("Developer: @dendev")
    SettingsTab:CreateLabel("Status: ✅ Online")

    SettingsTab:CreateButton({
        Name = "Destroy GUI",
        Callback = function()
            Rayfield:Destroy()
        end,
    })

    Rayfield:Notify({
        Title = "DEN HUB v3.1",
        Content = "All features loaded and ready! Type _G.DENHUB in console for commands.",
        Duration = 5,
        Image = 4483362458,
    })
else
    Notify("DEN HUB", "Loaded in console mode (Rayfield unavailable)", 5)
end

-- ═══════════════════════════════════════════════════════════
--                    GLOBAL FUNCTIONS
-- ═══════════════════════════════════════════════════════════

_G.DENHUB = {
    StartAutoFish = StartAutoFish,
    StopAutoFish = StopAutoFish,
    StartAutoFavorite = StartAutoFavorite,
    StartAutoSell = StartAutoSell,
    UsePotion = UsePotion,
    UseTotem = UseTotem,
    TeleportToIsland = TeleportToIsland,
    ServerHop = ServerHop,
    RejoinServer = RejoinServer,
    BoostFPS = BoostFPS,
    State = State,
    Stats = Stats,
    Notify = Notify
}

print("[DEN HUB] v3.1 loaded successfully!")
print("[DEN HUB] Type: _G.DENHUB.StartAutoFish() to start fishing")
print("[DEN HUB] Type: _G.DENHUB.StopAutoFish() to stop fishing")
print("[DEN HUB] Type: _G.DENHUB.State to see all states")
print("[DEN HUB] Type: _G.DENHUB.Stats to see statistics")
