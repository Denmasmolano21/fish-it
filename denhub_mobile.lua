--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║              DEN HUB - FISH IT [MOBILE]                  ║
    ║         Optimized for Mobile Executors (HP/Phone)        ║
    ║                   Version: 3.2 MOBILE                    ║
    ╚═══════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════
--                    MOBILE SETUP
-- ═══════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- ═══════════════════════════════════════════════════════════
--                    MOBILE UI SYSTEM
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
        return true
    else
        return false
    end
end

local function Notify(title, content, duration)
    duration = duration or 2
    if UIAvailable and Rayfield then
        pcall(function()
            Rayfield:Notify({
                Title = title or "Info",
                Content = content or "",
                Duration = duration,
                Image = 4483362458
            })
        end)
    end
end

LoadRayfield()

-- ═══════════════════════════════════════════════════════════
--                    FIND NET REMOTES
-- ═══════════════════════════════════════════════════════════

local Remotes = {}
local net = nil

local function FindNet()
    -- Coba path pertama
    local p = ReplicatedStorage:FindFirstChild("Packages")
    if p then
        local idx = p:FindFirstChild("_Index")
        if idx then
            for _, folder in ipairs(idx:GetChildren()) do
                local netFolder = folder:FindFirstChild("net")
                if netFolder then
                    net = netFolder
                    return true
                end
            end
        end
    end
    
    -- Coba direct
    net = ReplicatedStorage:FindFirstChild("net")
    if net then return true end
    
    return false
end

local function FindAllRemotes()
    if not net then return false end
    
    local remoteNames = {
        "RF/ChargeFishingRod",
        "RF/RequestFishingMinigameStarted",
        "RE/EquipToolFromHotbar",
        "RF/SellAllItems",
        "RE/FishingCompleted"
    }
    
    for _, name in ipairs(remoteNames) do
        local remote = net:FindFirstChild(name)
        if remote then
            Remotes[name] = remote
        end
    end
    
    return next(Remotes) ~= nil
end

if not FindNet() then
    Notify("ERROR", "Net tidak ditemukan!", 5)
    return
end

if not FindAllRemotes() then
    Notify("ERROR", "Remotes tidak ditemukan!", 5)
    return
end

Notify("SUCCESS", "Net remotes loaded!", 1)

-- ═══════════════════════════════════════════════════════════
--                    STATE & CONFIG
-- ═══════════════════════════════════════════════════════════

local State = {
    AutoFish = false,
    AutoSell = false,
    AntiAFK = true,
    FishingActive = false,
}

local Stats = {
    TotalCaught = 0,
    SessionStart = tick()
}

local Config = {
    CastDelay = 1.2,  -- Delay antara cast
    Notification = true
}

-- ═══════════════════════════════════════════════════════════
--                    UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════

local function GetSessionTime()
    local elapsed = tick() - Stats.SessionStart
    return string.format("%02d:%02d", math.floor(elapsed/60), math.floor(elapsed%60))
end

-- ═══════════════════════════════════════════════════════════
--                    AUTO FISH (SIMPLIFIED)
-- ═══════════════════════════════════════════════════════════

local function StartAutoFish()
    if State.AutoFish then return end
    
    if not Remotes["RF/ChargeFishingRod"] or not Remotes["RF/RequestFishingMinigameStarted"] then
        Notify("ERROR", "Fishing remotes missing!", 3)
        return
    end
    
    State.AutoFish = true
    Notify("FISHING", "Started!", 2)
    
    task.spawn(function()
        while State.AutoFish do
            pcall(function()
                State.FishingActive = true
                
                -- Equip rod
                if Remotes["RE/EquipToolFromHotbar"] then
                    Remotes["RE/EquipToolFromHotbar"]:FireServer(1)
                    task.wait(0.15)
                end
                
                -- Charge
                pcall(function()
                    Remotes["RF/ChargeFishingRod"]:InvokeServer(workspace:GetServerTimeNow())
                end)
                
                task.wait(0.3)
                
                -- Reel (multiple attempts with different coords)
                local reelSuccess = false
                local coords = {{x = 0, y = 0}, {x = -0.5, y = 1}, {x = -0.75, y = 1}}
                
                for _, coord in ipairs(coords) do
                    local ok = pcall(function()
                        Remotes["RF/RequestFishingMinigameStarted"]:InvokeServer(coord.x, coord.y)
                    end)
                    if ok then
                        reelSuccess = true
                        break
                    end
                end
                
                if reelSuccess then
                    Stats.TotalCaught = Stats.TotalCaught + 1
                    if Config.Notification and Stats.TotalCaught % 5 == 0 then
                        Notify("FISH", "Caught: " .. Stats.TotalCaught, 1)
                    end
                end
                
                State.FishingActive = false
                task.wait(Config.CastDelay)
            end)
        end
    end)
end

local function StopAutoFish()
    State.AutoFish = false
    Notify("FISHING", "Stopped! Total: " .. Stats.TotalCaught, 2)
end

-- ═══════════════════════════════════════════════════════════
--                    AUTO SELL
-- ═══════════════════════════════════════════════════════════

local LastSellTime = 0

local function SellNow()
    if not Remotes["RF/SellAllItems"] then
        Notify("ERROR", "Sell remote missing!", 2)
        return
    end
    
    if tick() - LastSellTime < 5 then
        Notify("WAIT", "Cooldown: " .. math.ceil(5 - (tick() - LastSellTime)) .. "s", 1)
        return
    end
    
    pcall(function()
        Remotes["RF/SellAllItems"]:InvokeServer()
        LastSellTime = tick()
        Notify("SOLD", "Items sold!", 2)
    end)
end

local function StartAutoSell()
    State.AutoSell = true
    Notify("AUTO SELL", "Started!", 2)
    
    task.spawn(function()
        while State.AutoSell do
            if tick() - LastSellTime >= 60 then
                SellNow()
            end
            task.wait(10)
        end
    end)
end

local function StopAutoSell()
    State.AutoSell = false
    Notify("AUTO SELL", "Stopped!", 2)
end

-- ═══════════════════════════════════════════════════════════
--                    ANTI AFK
-- ═══════════════════════════════════════════════════════════

local function SetupAntiAFK()
    pcall(function()
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
--                    TELEPORT
-- ═══════════════════════════════════════════════════════════

local IslandCoords = {
    {name = "Kohana", pos = Vector3.new(-658, 3, 719)},
    {name = "Tropical Grove", pos = Vector3.new(-2038, 3, 3650)},
    {name = "Coral Reefs", pos = Vector3.new(-3095, 1, 2177)},
    {name = "Weather Machine", pos = Vector3.new(-1471, -3, 1929)},
    {name = "Esoteric Depths", pos = Vector3.new(3157, -1303, 1439)},
}

local function TeleportTo(pos)
    HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
    Notify("TP", "Teleported!", 1)
end

-- ═══════════════════════════════════════════════════════════
--                    MOBILE UI
-- ═══════════════════════════════════════════════════════════

if UIAvailable and Rayfield then
    local Window = Rayfield:CreateWindow({
        Name = "DEN HUB MOBILE",
        LoadingTitle = "Loading...",
        LoadingSubtitle = "v3.2",
        ConfigurationSaving = {Enabled = false},
        KeySystem = false,
    })

    -- FISHING TAB
    local FishingTab = Window:CreateTab("🎣 FISH", 4483362458)
    
    FishingTab:CreateToggle({
        Name = "AUTO FISH",
        CurrentValue = false,
        Callback = function(Value)
            if Value then StartAutoFish() else StopAutoFish() end
        end,
    })

    FishingTab:CreateInput({
        Name = "Delay (detik)",
        PlaceholderText = "1.2",
        Callback = function(Text)
            local num = tonumber(Text)
            if num and num > 0 then
                Config.CastDelay = num
                Notify("CONFIG", "Delay: " .. num, 1)
            end
        end,
    })

    FishingTab:CreateButton({
        Name = "Sell All Now",
        Callback = function()
            SellNow()
        end,
    })

    -- SELL TAB
    local SellTab = Window:CreateTab("💰 SELL", 4483362458)
    
    SellTab:CreateToggle({
        Name = "AUTO SELL",
        CurrentValue = false,
        Callback = function(Value)
            if Value then StartAutoSell() else StopAutoSell() end
        end,
    })

    -- TELEPORT TAB
    local TpTab = Window:CreateTab("🗺️ TP", 4483362458)
    
    local islandNames = {}
    for _, island in ipairs(IslandCoords) do
        table.insert(islandNames, island.name)
    end

    TpTab:CreateDropdown({
        Name = "Island",
        Options = islandNames,
        CurrentOption = islandNames[1] or "Kohana",
        Callback = function(Option)
            for _, island in ipairs(IslandCoords) do
                if island.name == Option then
                    TeleportTo(island.pos)
                    break
                end
            end
        end,
    })

    -- STATS TAB
    local StatsTab = Window:CreateTab("📊 STATS", 4483362458)
    
    local CaughtLabel = StatsTab:CreateLabel("Caught: 0")
    local TimeLabel = StatsTab:CreateLabel("Time: 00:00")
    local StatusLabel = StatsTab:CreateLabel("Status: Idle")

    task.spawn(function()
        while task.wait(1) do
            pcall(function()
                CaughtLabel:Set("Caught: " .. Stats.TotalCaught)
                TimeLabel:Set("Time: " .. GetSessionTime())
                
                local status = "Idle"
                if State.AutoFish then status = "🎣 Fishing" end
                if State.AutoSell then status = status .. " | 💰 Selling" end
                StatusLabel:Set("Status: " .. status)
            end)
        end
    end)

    -- SETTINGS TAB
    local SettingsTab = Window:CreateTab("⚙️ CONFIG", 4483362458)
    
    SettingsTab:CreateToggle({
        Name = "Notifications",
        CurrentValue = true,
        Callback = function(Value)
            Config.Notification = Value
        end,
    })

    SettingsTab:CreateToggle({
        Name = "Anti-AFK",
        CurrentValue = true,
        Callback = function(Value)
            State.AntiAFK = Value
        end,
    })

    SettingsTab:CreateButton({
        Name = "Close UI",
        Callback = function()
            Rayfield:Destroy()
        end,
    })

    Rayfield:Notify({
        Title = "DEN HUB",
        Content = "Mobile v3.2 loaded!",
        Duration = 3,
        Image = 4483362458,
    })
else
    warn("[DEN HUB] Rayfield not available - console only")
end

-- ═══════════════════════════════════════════════════════════
--                    GLOBAL COMMANDS
-- ═══════════════════════════════════════════════════════════

_G.DENHUB = {
    -- Fishing
    Fish = StartAutoFish,
    StopFish = StopAutoFish,
    
    -- Selling
    Sell = SellNow,
    AutoSell = StartAutoSell,
    StopSell = StopAutoSell,
    
    -- Config
    SetDelay = function(delay) 
        Config.CastDelay = delay
        return "Delay: " .. delay
    end,
    
    -- Teleport
    Go = function(islandName)
        for _, island in ipairs(IslandCoords) do
            if island.name == islandName then
                TeleportTo(island.pos)
                return
            end
        end
    end,
    
    -- Info
    Stats = Stats,
    Status = function()
        return {
            fishing = State.AutoFish,
            selling = State.AutoSell,
            caught = Stats.TotalCaught,
            time = GetSessionTime()
        }
    end
}

-- Simple mobile commands
_G.FishStart = StartAutoFish
_G.FishStop = StopAutoFish
_G.SellAll = SellNow
