--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║                      DEN HUB - FISH IT                    ║
    ║              Advanced Fishing Automation Hub              ║
    ║                    Version: 1.0.0                         ║
    ║                  Author: @denmas_.                        ║
    ╚═══════════════════════════════════════════════════════════╝
    
    Features:
    - Advanced Auto Fishing System with Rod Detection
    - Auto Favorite (Secret, Mythic, Legendary, Epic)
    - Smart Auto Sell System
    - Complete Teleport System
    - Auto Enchant Rod
    - Anti-AFK Protection
    - Server Hop & Rejoin
    - FPS Booster
    - And many more...
]]

-- ═══════════════════════════════════════════════════════════
--                      LOAD RAYFIELD UI
-- ═══════════════════════════════════════════════════════════

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ═══════════════════════════════════════════════════════════
--                    SERVICES & VARIABLES
-- ═══════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Network Remotes
local net = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

local rodRemote = net:WaitForChild("RF/ChargeFishingRod")
local miniGameRemote = net:WaitForChild("RF/RequestFishingMinigameStarted")
local finishRemote = net:WaitForChild("RE/FishingCompleted")
local equipRemote = net:WaitForChild("RE/EquipToolFromHotbar")
local sellRemote = net:WaitForChild("RF/SellAllItems")

-- Animations
local AnimModules = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations")
local RodIdle = AnimModules:WaitForChild("FishingRodReelIdle")
local RodReel = AnimModules:WaitForChild("EasyFishReelStart")
local RodShake = AnimModules:WaitForChild("CastFromFullChargePosition1Hand")

local Animator = Humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", Humanoid)
local RodShakeAnim = Animator:LoadAnimation(RodShake)
local RodIdleAnim = Animator:LoadAnimation(RodIdle)
local RodReelAnim = Animator:LoadAnimation(RodReel)

-- ═══════════════════════════════════════════════════════════
--                      STATE MANAGEMENT
-- ═══════════════════════════════════════════════════════════

-- Denmas Unified Hub (denhub.lua)
-- Menggabungkan fitur utama dari denmas.lua / denmas2.lua / denmas3.lua / premium.lua
-- Fitur: WindUI, AutoFish, AutoSell, AutoFavorite, AntiAFK, BoostFPS, Teleport, ServerHop, Utilities

-- NOTE: Designed to run inside a Roblox executor that supports `loadstring`, `HttpGet`, and typical task APIs.

-- ====== Services & basic setup ======
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

if not LocalPlayer then return end

-- ====== Load WindUI (remote small UI framework used in originals) ======
local success, WindUI = pcall(function()
    local url = "https://raw.githubusercontent.com/Denmasmolano21/fish-it/refs/heads/main/main.lua"
    local src = game:HttpGet(url)
    return loadstring(src)()
end)

if not success then
    warn("[Denhub] WindUI gagal dimuat; UI dinonaktifkan")
    WindUI = nil
end

-- ====== Helpers & notifications (wrap WindUI if available) ======
local function Notify(title, content, duration, kind)
    duration = duration or 3
    if WindUI and WindUI.Notify then
        WindUI:Notify({Title = title or "Info", Content = content or "", Duration = duration, Icon = (kind == "ok" and "circle-check") or (kind == "err" and "circle-x") or "info"})
    else
        pcall(function() print(string.format("[%s] %s", title or "Info", content or "")) end)
    end
end

-- ====== Find net remotes robustly ======
local function findNetModule()
    -- try common package path then fallback to direct child named 'net'
    local candidates = {
        function()
            local p = ReplicatedStorage:FindFirstChild("Packages")
            if not p then return nil end
            local idx = p:FindFirstChild("_Index")
            if not idx then return nil end
            local netPkg = idx:FindFirstChild("sleitnick_net@0.2.0") or idx:FindFirstChildWhichIsA and idx:FindFirstChildWhichIsA("ModuleScript")
            if netPkg and netPkg:FindFirstChild("net") then return netPkg:FindFirstChild("net") end
            return nil
        end,
        function()
            return ReplicatedStorage:FindFirstChild("net") or ReplicatedStorage:FindFirstChild("Net")
        end
    }
    for _,fn in ipairs(candidates) do
        local ok, res = pcall(fn)
        if ok and res then return res end
    end
    return nil
end

local net = findNetModule()

-- Remote names used across scripts
local REMOTE_NAMES = {
    charge = "RF/ChargeFishingRod",
    minigame = "RF/RequestFishingMinigameStarted",
    finish = "RE/FishingCompleted",
    replicateText = "RE/ReplicateTextEffect",
}

local Remotes = {}
if net then
    for key,name in pairs(REMOTE_NAMES) do
        local ok, r = pcall(function() return net:FindFirstChild(name) end)
        Remotes[key] = ok and r or nil
    end
end

-- ====== State flags ======
local STATE = {
    AutoFish = false,
    AutoSell = false,
    AutoFavorite = false,
    AntiAFK = true,
    BoostFPS = true,
}

-- ====== Utility features ======
local function EnableAntiAFK()
    pcall(function()
        LocalPlayer.Idled:Connect(function()
            VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end)
        Notify("Anti-AFK", "Aktif", 2, "ok")
    end)
end

local function BoostFPS()
    pcall(function()
        -- simple safe optimizations
        local Lighting = game:GetService("Lighting")
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e9
        pcall(function() settings().Rendering.QualityLevel = "Level01" end)
        Notify("BoostFPS", "Pengaturan grafis disederhanakan", 2, "ok")
    end)
end

if STATE.AntiAFK then EnableAntiAFK() end
if STATE.BoostFPS then BoostFPS() end

-- ====== Core Auto-Fish (safe, relies on remotes when available) ======
local AutoFishLoop
local function StartAutoFish()
    if STATE.AutoFish then return end
    STATE.AutoFish = true
    Notify("AutoFish", "Dimulai", 2, "ok")
    AutoFishLoop = task.spawn(function()
        while STATE.AutoFish do
            pcall(function()
                -- primary method: invoke `charge` remote if available
                if Remotes.charge and Remotes.charge.FireServer then
                    Remotes.charge:FireServer()
                else
                    -- fallback: try to activate the rod object in backpack/character
                    local rod = LocalPlayer.Backpack:FindFirstChild("Rod") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Rod"))
                    if rod and rod.Activate then pcall(function() rod:Activate() end) end
                end
            end)
            -- wait a bit; tuned conservatively
            task.wait(1.2)
            pcall(function()
                if Remotes.finish and Remotes.finish.FireServer then
                    -- attempt to complete fishing if needed (compatibility call)
                    Remotes.finish:FireServer()
                end
            end)
            task.wait(0.6)
        end
    end)
end

local function StopAutoFish()
    STATE.AutoFish = false
    Notify("AutoFish", "Dihentikan", 2, "ok")
end

-- ====== AutoSell (periodic) ======
local lastSell = 0
local AUTO_SELL_DELAY = 60
local function startAutoSellLoop()
    if Remotes.charge == nil then -- rough heuristic: require net
        if not STATE.AutoSell then STATE.AutoSell = false end
        return
    end
    task.spawn(function()
        while STATE.AutoSell do
            local now = tick()
            if now - lastSell >= AUTO_SELL_DELAY then
                lastSell = now
                pcall(function()
                    -- best-effort: call a sell remote if known in net
                    local sellRemote = net and (net:FindFirstChild("RF/SellAll") or net:FindFirstChild("RE/SellAll"))
                    if sellRemote and sellRemote.FireServer then
                        sellRemote:FireServer()
                        Notify("AutoSell", "Menjual item non-favorit", 2)
                    else
                        -- fallback: print notice
                        Notify("AutoSell", "Tidak menemukan remote jual otomatis", 2, "err")
                    end
                end)
            end
            task.wait(5)
        end
    end)
end

-- ====== AutoFavorite (simple heuristic) ======
local function startAutoFavoriteLoop()
    task.spawn(function()
        while STATE.AutoFavorite do
            pcall(function()
                -- Attempt to call favorite remote if present
                local favRemote = net and (net:FindFirstChild("RE/ToggleFavourite") or net:FindFirstChild("RF/ToggleFavorite"))
                if favRemote and favRemote.FireServer then
                    -- This is conservative; real calls may require args. Skip auto-call unless known.
                end
            end)
            task.wait(10)
        end
    end)
end

-- ====== Simple utility functions ======
local function RejoinServer()
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
end

local function ServerHop()
    -- tries to find another server (basic fallback using TeleportService:GetPlayerPlaceInstances isn't exposed; we call TeleportService:Teleport to same place to force server change)
    pcall(function() TeleportService:Teleport(game.PlaceId) end)
end

-- ====== Manual helper: Sell all (best-effort) ======
local function SellAllNow()
    pcall(function()
        local sellRemote = net and (net:FindFirstChild("RF/SellAll") or net:FindFirstChild("RE/SellAll"))
        if sellRemote and sellRemote.FireServer then
            sellRemote:FireServer()
            Notify("Sell All", "Permintaan jual dikirim", 2, "ok")
        else
            Notify("Sell All", "Remote jual otomatis tidak ditemukan", 3, "err")
        end
    end)
end

-- ====== Minimal WindUI GUI wiring ======
if WindUI then
    local Window = WindUI:CreateWindow({Title = "Denmas Hub Unified", Author = "denmas._", KeySystem = false})
    Window:SetToggleKey(Enum.KeyCode.G)

    local autoTab = Window:Tab({Title = "Auto", Icon = "fish"})
    local utilTab = Window:Tab({Title = "Utility", Icon = "settings"})
    local settingsTab = Window:Tab({Title = "Settings", Icon = "user-cog"})

    local autoSection = autoTab:Section({Title = "Automation", Icon = "sparkles"})

    autoSection:Toggle({Title = "Auto Fish", Description = "Casting & reeling loop", Default = false, Callback = function(val)
        if val then StartAutoFish() else StopAutoFish() end
    end})

    autoSection:Toggle({Title = "Auto Sell", Description = "Coba jual otomatis setiap 60s", Default = false, Callback = function(val)
        STATE.AutoSell = val
        if val then startAutoSellLoop() end
    end})

    autoSection:Toggle({Title = "Auto Favorite (best-effort)", Description = "Coba lindungi fish berharga (terbatas)", Default = false, Callback = function(val)
        STATE.AutoFavorite = val
        if val then startAutoFavoriteLoop() end
    end})

    autoSection:Button({Title = "Sell All Now", Description = "Jual semua ikan non-favorit (manual)", Callback = function()
        SellAllNow()
    end})

    local utilSection = utilTab:Section({Title = "Server & Visual", Icon = "server"})
    utilSection:Button({Title = "Rejoin", Description = "Reconnect ke server yang sama", Callback = RejoinServer})
    utilSection:Button({Title = "Server Hop", Description = "Coba pindah server", Callback = ServerHop})
    utilSection:Toggle({Title = "Anti-AFK", Description = "Mencegah kick karena AFK", Default = STATE.AntiAFK, Callback = function(v)
        STATE.AntiAFK = v
        if v then EnableAntiAFK() end
    end})

    local settingsSection = settingsTab:Section({Title = "Preferences", Icon = "sliders"})
    settingsSection:Toggle({Title = "Boost FPS", Description = "Sederhanakan grafis", Default = STATE.BoostFPS, Callback = function(v)
        STATE.BoostFPS = v
        if v then BoostFPS() end
    end})

    WindUI:Notify({Title = "Denmas Hub", Content = "Unified script loaded", Duration = 4, Image = "square-check-big"})
end

-- ====== Lightweight console feedback for non-UI users ======
print("[Denhub] Loaded. Toggle AutoFish via UI (G) or use exposed functions:")
print("Start/Stop AutoFish: StartAutoFish(), StopAutoFish()")
print("SellAllNow() | RejoinServer() | ServerHop()")

-- Expose some functions to the global environment for power users
_G.DENHUB = {
    StartAutoFish = StartAutoFish,
    StopAutoFish = StopAutoFish,
    SellAllNow = SellAllNow,
    RejoinServer = RejoinServer,
    ServerHop = ServerHop,
    State = STATE,
}

-- Auto-start some safe features
if STATE.AutoFish then StartAutoFish() end
if STATE.AutoSell then startAutoSellLoop() end
if STATE.AutoFavorite then startAutoFavoriteLoop() end

    ["Angler Rod"] = {custom = 1.12, bypass = 1.45},
    ["Ghostfinn Rod"] = {custom = 1.12, bypass = 1.45},
    ["Astral Rod"] = {custom = 1.9, bypass = 1.45},
    ["Chrome Rod"] = {custom = 2.3, bypass = 2},
    ["Steampunk Rod"] = {custom = 2.5, bypass = 2.3},
    ["Lucky Rod"] = {custom = 3.5, bypass = 3.6},
    ["Midnight Rod"] = {custom = 3.3, bypass = 3.4},
    ["Demascus Rod"] = {custom = 3.9, bypass = 3.8},
    ["Grass Rod"] = {custom = 3.8, bypass = 3.9},
    ["Luck Rod"] = {custom = 4.2, bypass = 4.1},
    ["Carbon Rod"] = {custom = 4, bypass = 3.8},
    ["Lava Rod"] = {custom = 4.2, bypass = 4.1},
    ["Starter Rod"] = {custom = 4.3, bypass = 4.2},
}

local CurrentDelay = {
    Custom = 1.5,
    Bypass = 1.0
}

-- ═══════════════════════════════════════════════════════════
--                      UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════

local function SafePcall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("[DEN HUB] Error:", result)
    end
    return success, result
end

local function GetValidRodName()
    local success, rodName = SafePcall(function()
        local display = LocalPlayer.PlayerGui:WaitForChild("Backpack"):WaitForChild("Display")
        for _, tile in ipairs(display:GetChildren()) do
            if tile:FindFirstChild("Inner") and tile.Inner:FindFirstChild("Tags") then
                local itemName = tile.Inner.Tags:FindFirstChild("ItemName")
                if itemName and itemName:IsA("TextLabel") then
                    local name = itemName.Text
                    if RodDelays[name] then
                        return name
                    end
                end
            end
        end
        return nil
    end)
    return success and rodName or nil
end

local function UpdateDelayBasedOnRod(showNotification)
    if State.DelayInitialized then return end
    
    local rodName = GetValidRodName()
    if rodName and RodDelays[rodName] then
        CurrentDelay.Custom = RodDelays[rodName].custom
        CurrentDelay.Bypass = RodDelays[rodName].bypass
        State.DelayInitialized = true
        
        if showNotification and State.AutoFish then
            Rayfield:Notify({
                Title = "Rod Detected",
                Content = string.format("%s | Delay: %.2fs | Bypass: %.2fs", rodName, CurrentDelay.Custom, CurrentDelay.Bypass),
                Duration = 3,
                Image = 4483362458,
            })
        end
    else
        CurrentDelay.Custom = 4.0
        CurrentDelay.Bypass = 1.0
        State.DelayInitialized = true
        
        if showNotification and State.AutoFish then
            Rayfield:Notify({
                Title = "Default Delay Applied",
                Content = "No valid rod detected. Using default timing.",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end
end

local function SetupRodWatcher()
    local display = LocalPlayer.PlayerGui:WaitForChild("Backpack"):WaitForChild("Display")
    display.ChildAdded:Connect(function()
        task.wait(0.1)
        if not State.DelayInitialized then
            UpdateDelayBasedOnRod(true)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
--                   AUTO FISHING SYSTEM
-- ═══════════════════════════════════════════════════════════

local REReplicateTextEffect = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ReplicateTextEffect"]

REReplicateTextEffect.OnClientEvent:Connect(function(data)
    if not State.AutoFish or not State.FishingActive then return end
    
    if data and data.TextData and data.TextData.EffectType == "Exclaim" then
        local myHead = Character and Character:FindFirstChild("Head")
        if myHead and data.Container == myHead then
            task.spawn(function()
                for i = 1, 3 do
                    task.wait(CurrentDelay.Bypass)
                    finishRemote:FireServer()
                end
            end)
        end
    end
end)

local function StartAutoFish()
    if State.AutoFish then return end
    State.AutoFish = true
    UpdateDelayBasedOnRod(true)
    
    Rayfield:Notify({
        Title = "Auto Fish Started",
        Content = "Fishing automation is now active!",
        Duration = 3,
        Image = 4483362458,
    })
    
    task.spawn(function()
        while State.AutoFish do
            SafePcall(function()
                State.FishingActive = true
                
                -- Equip rod
                equipRemote:FireServer(1)
                task.wait(0.1)
                
                -- Charge rod
                local chargeRemote = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/ChargeFishingRod"]
                chargeRemote:InvokeServer(workspace:GetServerTimeNow())
                task.wait(0.5)
                
                -- Cast
                local timestamp = workspace:GetServerTimeNow()
                RodShakeAnim:Play()
                rodRemote:InvokeServer(timestamp)
                
                -- Calculate cast position
                local baseX, baseY = -0.7499996423721313, 1
                local x, y
                
                if State.PerfectCast then
                    x = baseX + (math.random(-500, 500) / 10000000)
                    y = baseY + (math.random(-500, 500) / 10000000)
                else
                    x = math.random(-1000, 1000) / 1000
                    y = math.random(0, 1000) / 1000
                end
                
                RodIdleAnim:Play()
                miniGameRemote:InvokeServer(x, y)
                
                task.wait(CurrentDelay.Custom)
                State.FishingActive = false
            end)
        end
    end)
end

local function StopAutoFish()
    State.AutoFish = false
    State.FishingActive = false
    State.DelayInitialized = false
    
    RodIdleAnim:Stop()
    RodShakeAnim:Stop()
    RodReelAnim:Stop()
    
    Rayfield:Notify({
        Title = "Auto Fish Stopped",
        Content = "Fishing automation has been disabled.",
        Duration = 3,
        Image = 4483362458,
    })
end

-- ═══════════════════════════════════════════════════════════
--                  AUTO FAVORITE SYSTEM
-- ═══════════════════════════════════════════════════════════

local AllowedTiers = {
    ["Secret"] = true,
    ["Mythic"] = true,
    ["Legendary"] = true,
    ["Epic"] = true
}

local function StartAutoFavorite()
    task.spawn(function()
        while State.AutoFavorite do
            SafePcall(function()
                if not Replion or not ItemUtility then return end
                
                local DataReplion = Replion.Client:WaitReplion("Data")
                local items = DataReplion and DataReplion:Get({"Inventory", "Items"})
                
                if type(items) == "table" then
                    for _, item in ipairs(items) do
                        local base = ItemUtility:GetItemData(item.Id)
                        if base and base.Data and AllowedTiers[base.Data.Tier] and not item.Favorited then
                            item.Favorited = true
                        end
                    end
                end
            end)
            task.wait(5)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
--                   AUTO SELL SYSTEM
-- ═══════════════════════════════════════════════════════════

local LastSellTime = 0
local AUTO_SELL_THRESHOLD = 60
local AUTO_SELL_DELAY = 60

local function StartAutoSell()
    task.spawn(function()
        while State.AutoSell do
            SafePcall(function()
                if not Replion then return end
                
                local DataReplion = Replion.Client:WaitReplion("Data")
                local items = DataReplion and DataReplion:Get({"Inventory", "Items"})
                
                if type(items) == "table" then
                    local unfavoritedCount = 0
                    for _, item in ipairs(items) do
                        if not item.Favorited then
                            unfavoritedCount = unfavoritedCount + (item.Count or 1)
                        end
                    end
                    
                    if unfavoritedCount >= AUTO_SELL_THRESHOLD and os.time() - LastSellTime >= AUTO_SELL_DELAY then
                        sellRemote:InvokeServer()
                        LastSellTime = os.time()
                        
                        Rayfield:Notify({
                            Title = "Auto Sell",
                            Content = string.format("Sold %d non-favorited items!", unfavoritedCount),
                            Duration = 3,
                            Image = 4483362458,
                        })
                    end
                end
            end)
            task.wait(10)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
--                    TELEPORT FUNCTIONS
-- ═══════════════════════════════════════════════════════════

local IslandCoords = {
    {name = "Weather Machine", pos = Vector3.new(-1471, -3, 1929)},
    {name = "Esoteric Depths", pos = Vector3.new(3157, -1303, 1439)},
    {name = "Tropical Grove", pos = Vector3.new(-2038, 3, 3650)},
    {name = "Stingray Shores", pos = Vector3.new(-32, 4, 2773)},
    {name = "Kohana Volcano", pos = Vector3.new(-519, 24, 189)},
    {name = "Coral Reefs", pos = Vector3.new(-3095, 1, 2177)},
    {name = "Crater Island", pos = Vector3.new(968, 1, 4854)},
    {name = "Kohana", pos = Vector3.new(-658, 3, 719)},
    {name = "Winter Fest", pos = Vector3.new(1611, 4, 3280)},
    {name = "Isoteric Island", pos = Vector3.new(1987, 4, 1400)},
    {name = "Treasure Hall", pos = Vector3.new(-3600, -267, -1558)},
    {name = "Lost Shore", pos = Vector3.new(-3663, 38, -989)},
    {name = "Sisyphus Statue", pos = Vector3.new(-3792, -135, -986)}
}

local function TeleportToIsland(position)
    SafePcall(function()
        local char = workspace:FindFirstChild("Characters"):FindFirstChild(LocalPlayer.Name)
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
        end
    end)
end

local Events = {"Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain"}

local function TeleportToEvent(eventName)
    SafePcall(function()
        local props = workspace:FindFirstChild("Props")
        if props and props:FindFirstChild(eventName) then
            local boat = props[eventName]:FindFirstChild("Fishing Boat")
            if boat then
                HumanoidRootPart.CFrame = boat:GetPivot() + Vector3.new(0, 15, 0)
                Rayfield:Notify({
                    Title = "Event Teleport",
                    Content = "Teleported to " .. eventName,
                    Duration = 3,
                    Image = 4483362458,
                })
                return
            end
        end
        Rayfield:Notify({
            Title = "Event Not Found",
            Content = eventName .. " is not currently active!",
            Duration = 3,
            Image = 4483362458,
        })
    end)
end

-- ═══════════════════════════════════════════════════════════
--                   UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════

local function SellAllFish()
    SafePcall(function()
        Rayfield:Notify({
            Title = "Selling Fish",
            Content = "Selling all non-favorited fish...",
            Duration = 3,
            Image = 4483362458,
        })
        
        task.wait(1)
        local success = sellRemote:InvokeServer()
        
        if success then
            Rayfield:Notify({
                Title = "Sold Successfully",
                Content = "All fish have been sold!",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end)
end

local function AutoEnchantRod()
    SafePcall(function()
        local ENCHANT_POS = Vector3.new(3231, -1303, 1402)
        
        Rayfield:Notify({
            Title = "Auto Enchant",
            Content = "Place Enchant Stone in slot 5, then wait...",
            Duration = 5,
            Image = 4483362458,
        })
        
        task.wait(3)
        
        local slot5 = LocalPlayer.PlayerGui.Backpack.Display:GetChildren()[10]
        local itemName = slot5 and slot5:FindFirstChild("Inner") and slot5.Inner:FindFirstChild("Tags") and slot5.Inner.Tags:FindFirstChild("ItemName")
        
        if not itemName or not itemName.Text:lower():find("enchant") then
            Rayfield:Notify({
                Title = "Error",
                Content = "Slot 5 doesn't contain Enchant Stone!",
                Duration = 3,
                Image = 4483362458,
            })
            return
        end
        
        local originalPos = HumanoidRootPart.Position
        HumanoidRootPart.CFrame = CFrame.new(ENCHANT_POS + Vector3.new(0, 5, 0))
        task.wait(1.2)
        
        local activateEnchant = net:WaitForChild("RE/ActivateEnchantingAltar")
        equipRemote:FireServer(5)
        task.wait(0.5)
        activateEnchant:FireServer()
        task.wait(7)
        
        HumanoidRootPart.CFrame = CFrame.new(originalPos + Vector3.new(0, 3, 0))
        
        Rayfield:Notify({
            Title = "Enchant Complete",
            Content = "Rod has been enchanted successfully!",
            Duration = 3,
            Image = 4483362458,
        })
    end)
end

local function BoostFPS()
    SafePcall(function()
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            end
        end
        
        local Lighting = game:GetService("Lighting")
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then
                effect.Enabled = false
            end
        end
        
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e10
        settings().Rendering.QualityLevel = "Level01"
        
        Rayfield:Notify({
            Title = "FPS Boost",
            Content = "Graphics optimized for better performance!",
            Duration = 3,
            Image = 4483362458,
        })
    end)
end

local function ServerHop()
    SafePcall(function()
        local placeId = game.PlaceId
        local servers = {}
        local cursor = ""
        
        repeat
            local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
            if cursor ~= "" then url = url .. "&cursor=" .. cursor end
            
            local success, result = pcall(function()
                return HttpService:JSONDecode(game:HttpGet(url))
            end)
            
            if success and result and result.data then
                for _, server in pairs(result.data) do
                    if server.playing < server.maxPlayers and server.id ~= game.JobId then
                        table.insert(servers, server.id)
                    end
                end
                cursor = result.nextPageCursor or ""
            else
                break
            end
        until not cursor or #servers > 0
        
        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(placeId, servers[math.random(1, #servers)], LocalPlayer)
        else
            Rayfield:Notify({
                Title = "Server Hop Failed",
                Content = "No available servers found!",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
--                   ANTI-AFK SYSTEM
-- ═══════════════════════════════════════════════════════════

local function SetupAntiAFK()
    for _, connection in pairs(getconnections(LocalPlayer.Idled)) do
        connection:Disable()
    end
    
    LocalPlayer.Idled:Connect(function()
        if State.AntiAFK then
            VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
--                      CREATE GUI
-- ═══════════════════════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = "DEN HUB | Fish It",
    LoadingTitle = "Den Hub Loading...",
    LoadingSubtitle = "by @dendev",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "DenHub",
        FileName = "FishIt"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false,
})

-- ═══════════════════════════════════════════════════════════
--                      FISHING TAB
-- ═══════════════════════════════════════════════════════════

local FishingTab = Window:CreateTab("🎣 Auto Fishing", 4483362458)
local FishingSection = FishingTab:CreateSection("Fishing Automation")

FishingTab:CreateToggle({
    Name = "Auto Fish",
    CurrentValue = false,
    Flag = "AutoFishToggle",
    Callback = function(Value)
        if Value then
            StartAutoFish()
        else
            StopAutoFish()
        end
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
    PlaceholderText = "Default: 1.5",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then
            CurrentDelay.Custom = num
            Rayfield:Notify({
                Title = "Delay Updated",
                Content = "Custom delay set to " .. num .. "s",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end,
})

FishingTab:CreateInput({
    Name = "Bypass Delay",
    PlaceholderText = "Default: 1.0",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then
            CurrentDelay.Bypass = num
            Rayfield:Notify({
                Title = "Delay Updated",
                Content = "Bypass delay set to " .. num .. "s",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end,
})

local AutoSection = FishingTab:CreateSection("Automation Features")

FishingTab:CreateToggle({
    Name = "Auto Favorite",
    CurrentValue = false,
    Flag = "AutoFavoriteToggle",
    Callback = function(Value)
        State.AutoFavorite = Value
        if Value then
            StartAutoFavorite()
            Rayfield:Notify({
                Title = "Auto Favorite",
                Content = "Now protecting valuable fish!",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end,
})

FishingTab:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = false,
    Flag = "AutoSellToggle",
    Callback = function(Value)
        State.AutoSell = Value
        if Value then
            StartAutoSell()
            Rayfield:Notify({
                Title = "Auto Sell",
                Content = "Selling when count > 60",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end,
})

local ManualSection = FishingTab:CreateSection("Manual Actions")

FishingTab:CreateButton({
    Name = "Sell All Fish",
    Callback = function()
        SellAllFish()
    end,
})

FishingTab:CreateButton({
    Name = "Auto Enchant Rod",
    Callback = function()
        AutoEnchantRod()
    end,
})

-- ═══════════════════════════════════════════════════════════
--                      TELEPORT TAB
-- ═══════════════════════════════════════════════════════════

local TeleportTab = Window:CreateTab("🗺️ Teleports", 4483362458)
local IslandSection = TeleportTab:CreateSection("Island Teleports")

local islandNames = {}
for _, island in ipairs(IslandCoords) do
    table.insert(islandNames, island.name)
end

TeleportTab:CreateDropdown({
    Name = "Select Island",
    Options = islandNames,
    CurrentOption = islandNames[1],
    Flag = "IslandDropdown",
    Callback = function(Option)
        for _, island in ipairs(IslandCoords) do
            if island.name == Option then
                TeleportToIsland(island.pos)
                Rayfield:Notify({
                    Title = "Teleported",
                    Content = "You are now at " .. Option,
                    Duration = 3,
                    Image = 4483362458,
                })
                break
            end
        end
    end,
})

local EventSection = TeleportTab:CreateSection("Event Teleports")

TeleportTab:CreateDropdown({
    Name = "Select Event",
    Options = Events,
    CurrentOption = Events[1],
    Flag = "EventDropdown",
    Callback = function(Option)
        TeleportToEvent(Option)
    end,
})

-- ═══════════════════════════════════════════════════════════
--                      UTILITY TAB
-- ═══════════════════════════════════════════════════════════

local UtilityTab = Window:CreateTab("⚙️ Utility", 4483362458)
local ServerSection = UtilityTab:CreateSection("Server Management")

UtilityTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        ServerHop()
    end,
})

UtilityTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

local PerformanceSection = UtilityTab:CreateSection("Performance")

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
        Rayfield:Notify({
            Title = "Anti-AFK",
            Content = Value and "Enabled" or "Disabled",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

-- ═══════════════════════════════════════════════════════════
--                      SETTINGS TAB
-- ═══════════════════════════════════════════════════════════

local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)
local InfoSection = SettingsTab:CreateSection("Information")

SettingsTab:CreateLabel("DEN HUB - Fish It")
SettingsTab:CreateLabel("Version: 1.0.0")
SettingsTab:CreateLabel("Developer: @denmas_.")
SettingsTab:CreateLabel("Status: ✅ Online")

local ConfigSection = SettingsTab:CreateSection("Configuration")

SettingsTab:CreateButton({
    Name = "Destroy GUI",
    Callback = function()
        Rayfield:Destroy()
    end,
})

-- ═══════════════════════════════════════════════════════════
--                      INITIALIZE
-- ═══════════════════════════════════════════════════════════

SetupRodWatcher()
SetupAntiAFK()

Rayfield:Notify({
    Title = "DEN HUB Loaded",
    Content = "All features ready! Happy fishing!",
    Duration = 5,
    Image = 4483362458,
})