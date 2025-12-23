--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║                 DEN HUB - FISH IT ULTIMATE                ║
    ║          Advanced Fishing Automation Hub v3.0             ║
    ╚═══════════════════════════════════════════════════════════╝
    
    Features: Auto Fish, Auto Potion/Totem, Statistics, Event Notifications,
    Smart Farming, Auto Quest, Shiny Detector, Webhook, and more!
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
local rodRemote = net:WaitForChild("RF/ChargeFishingRod")
local miniGameRemote = net:WaitForChild("RF/RequestFishingMinigameStarted")
local finishRemote = net:WaitForChild("RE/FishingCompleted")
local equipRemote = net:WaitForChild("RE/EquipToolFromHotbar")
local sellRemote = net:WaitForChild("RF/SellAllItems")

local AnimModules = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations")
local Humanoid = Character:WaitForChild("Humanoid")
local Animator = Humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", Humanoid)
local RodShakeAnim = Animator:LoadAnimation(AnimModules:WaitForChild("CastFromFullChargePosition1Hand"))
local RodIdleAnim = Animator:LoadAnimation(AnimModules:WaitForChild("FishingRodReelIdle"))

-- State Management
local State = {
    AutoFish = false, PerfectCast = true, AutoFavorite = false, AutoSell = false,
    AntiAFK = true, FishingActive = false, DelayInitialized = false,
    AutoPotion = false, AutoTotem = false, SmartFarming = false,
    AutoQuest = false, EventNotifications = true, WebhookEnabled = false
}

local Stats = {
    TotalCaught = 0, SecretCaught = 0, MythicCaught = 0, LegendaryCaught = 0,
    ShinyCount = 0, MutationCount = 0, TotalEarnings = 0, SessionStart = tick()
}

local RodDelays = {
    ["Element Rod"] = {custom = 0.9, bypass = 1.2}, ["Ares Rod"] = {custom = 1.12, bypass = 1.45},
    ["Angler Rod"] = {custom = 1.12, bypass = 1.45}, ["Ghostfinn Rod"] = {custom = 1.12, bypass = 1.45},
    ["Astral Rod"] = {custom = 1.9, bypass = 1.45}, ["Chrome Rod"] = {custom = 2.3, bypass = 2},
    ["Lucky Rod"] = {custom = 3.5, bypass = 3.6}, ["Starter Rod"] = {custom = 4.3, bypass = 4.2},
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
    {name = "Kohana", pos = Vector3.new(-658, 3, 719)},
    {name = "Winter Fest", pos = Vector3.new(1611, 4, 3280)},
}

local WebhookURL = ""
local LastPotionUse, LastTotemUse, LastSellTime = 0, 0, 0
local CurrentLocationIndex, CatchesAtLocation = 1, 0

-- Utility Functions
local function SafePcall(func, ...) return pcall(func, ...) end

local function SendWebhook(title, msg, color)
    if not State.WebhookEnabled or WebhookURL == "" then return end
    SafePcall(function()
        request({Url = WebhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({embeds = {{title = title, description = msg, color = color or 3447003}}})})
    end)
end

local function GetSessionTime()
    local e = tick() - Stats.SessionStart
    return string.format("%02d:%02d:%02d", math.floor(e/3600), math.floor((e%3600)/60), math.floor(e%60))
end

local function UpdateDelayBasedOnRod()
    if State.DelayInitialized then return end
    local display = LocalPlayer.PlayerGui:WaitForChild("Backpack"):WaitForChild("Display")
    for _, tile in ipairs(display:GetChildren()) do
        local itemName = tile:FindFirstChild("Inner") and tile.Inner:FindFirstChild("Tags") and tile.Inner.Tags:FindFirstChild("ItemName")
        if itemName and RodDelays[itemName.Text] then
            CurrentDelay.Custom = RodDelays[itemName.Text].custom
            CurrentDelay.Bypass = RodDelays[itemName.Text].bypass
            State.DelayInitialized = true
            return
        end
    end
end

-- Auto Potion/Totem System
local function UsePotion()
    if not State.AutoPotion or os.time() - LastPotionUse < 300 then return end
    SafePcall(function()
        equipRemote:FireServer(2)
        task.wait(0.5)
        local useItem = net:FindFirstChild("RE/UseItem")
        if useItem then useItem:FireServer() LastPotionUse = os.time()
            Rayfield:Notify({Title = "Potion Used", Content = "Luck Potion activated!", Duration = 3, Image = 4483362458})
        end
    end)
end

local function UseTotem()
    if not State.AutoTotem or os.time() - LastTotemUse < 1800 then return end
    SafePcall(function()
        equipRemote:FireServer(3)
        task.wait(0.5)
        local placeTotem = net:FindFirstChild("RE/PlaceTotem")
        if placeTotem then placeTotem:FireServer(HumanoidRootPart.Position) LastTotemUse = os.time()
            Rayfield:Notify({Title = "Totem Placed", Content = "Luck Totem active!", Duration = 3, Image = 4483362458})
        end
    end)
end

-- Event Notification System
local Events = {"Shark Hunt", "Meteor Rain", "Black Hole", "Ghost Worm"}
local ActiveEvents = {}
local function CheckForEvents()
    if not State.EventNotifications then return end
    local props = workspace:FindFirstChild("Props")
    if not props then return end
    for _, eventName in ipairs(Events) do
        if props:FindFirstChild(eventName) and not ActiveEvents[eventName] then
            ActiveEvents[eventName] = true
            Rayfield:Notify({Title = "Event Active!", Content = eventName .. " spawned!", Duration = 5, Image = 4483362458})
            SendWebhook("🎉 Event", eventName .. " is active!", 65280)
        elseif not props:FindFirstChild(eventName) then ActiveEvents[eventName] = nil end
    end
end

-- Shiny/Mutation Detector
local REReplicateTextEffect = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ReplicateTextEffect"]
REReplicateTextEffect.OnClientEvent:Connect(function(data)
    if State.AutoFish and State.FishingActive and data and data.TextData then
        if data.TextData.EffectType == "Exclaim" then
            local myHead = Character:FindFirstChild("Head")
            if myHead and data.Container == myHead then
                for i = 1, 3 do task.wait(CurrentDelay.Bypass) finishRemote:FireServer() end
            end
        end
        local text = tostring(data.TextData.Text or "")
        if text:lower():find("shiny") then
            Stats.ShinyCount = Stats.ShinyCount + 1
            Rayfield:Notify({Title = "✨ SHINY!", Content = "Shiny caught!", Duration = 5, Image = 4483362458})
            SendWebhook("✨ Shiny", "Shiny fish caught!", 16766720)
        elseif text:lower():find("mutation") then
            Stats.MutationCount = Stats.MutationCount + 1
            Rayfield:Notify({Title = "🧬 MUTATION!", Content = "Mutation caught!", Duration = 5, Image = 4483362458})
            SendWebhook("🧬 Mutation", "Mutated fish caught!", 16711935)
        end
    end
end)

-- Auto Fishing
local function StartAutoFish()
    if State.AutoFish then return end
    State.AutoFish = true
    UpdateDelayBasedOnRod()
    Rayfield:Notify({Title = "Auto Fish", Content = "Started!", Duration = 3, Image = 4483362458})
    
    task.spawn(function()
        while State.AutoFish do
            SafePcall(function()
                State.FishingActive = true
                equipRemote:FireServer(1)
                task.wait(0.1)
                
                local chargeRemote = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/ChargeFishingRod"]
                chargeRemote:InvokeServer(workspace:GetServerTimeNow())
                task.wait(0.5)
                
                RodShakeAnim:Play()
                rodRemote:InvokeServer(workspace:GetServerTimeNow())
                
                local x = -0.75 + (math.random(-500, 500) / 10000000)
                local y = 1 + (math.random(-500, 500) / 10000000)
                
                RodIdleAnim:Play()
                miniGameRemote:InvokeServer(x, y)
                Stats.TotalCaught = Stats.TotalCaught + 1
                
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
    RodIdleAnim:Stop() RodShakeAnim:Stop()
end

-- Auto Favorite
local AllowedTiers = {["Secret"] = true, ["Mythic"] = true, ["Legendary"] = true, ["Epic"] = true}
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
                            if base.Data.Tier == "Secret" then Stats.SecretCaught = Stats.SecretCaught + 1 end
                        end
                    end
                end
            end)
            task.wait(5)
        end
    end)
end

-- Auto Sell
local function StartAutoSell()
    task.spawn(function()
        while State.AutoSell do
            SafePcall(function()
                if not Replion then return end
                local DataReplion = Replion.Client:WaitReplion("Data")
                local items = DataReplion and DataReplion:Get({"Inventory", "Items"})
                if type(items) == "table" then
                    local count = 0
                    for _, item in ipairs(items) do if not item.Favorited then count = count + (item.Count or 1) end end
                    if count >= 60 and os.time() - LastSellTime >= 60 then
                        sellRemote:InvokeServer()
                        LastSellTime = os.time()
                        Rayfield:Notify({Title = "Auto Sell", Content = "Sold " .. count .. " items!", Duration = 3, Image = 4483362458})
                    end
                end
            end)
            task.wait(10)
        end
    end)
end

-- Smart Farming
local function RotateFarmingLocation()
    CatchesAtLocation = CatchesAtLocation + 1
    if State.SmartFarming and CatchesAtLocation >= 50 then
        CatchesAtLocation = 0
        CurrentLocationIndex = (CurrentLocationIndex % #FarmingLocations) + 1
        local location = FarmingLocations[CurrentLocationIndex]
        StopAutoFish()
        HumanoidRootPart.CFrame = CFrame.new(location.pos + Vector3.new(0, 5, 0))
        task.wait(2)
        Rayfield:Notify({Title = "Location Rotated", Content = location.name, Duration = 3, Image = 4483362458})
        StartAutoFish()
    end
end

-- Background Tasks
task.spawn(function() while task.wait(60) do UsePotion() UseTotem() end end)
task.spawn(function() while task.wait(15) do CheckForEvents() end end)

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    if State.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

-- GUI Creation
local Window = Rayfield:CreateWindow({
    Name = "DEN HUB | Fish It Ultimate v3.0",
    LoadingTitle = "Den Hub Loading...",
    LoadingSubtitle = "by @dendev",
    ConfigurationSaving = {Enabled = true, FolderName = "DenHub", FileName = "FishIt"},
    KeySystem = false,
})

-- Fishing Tab
local FishingTab = Window:CreateTab("🎣 Fishing", 4483362458)
FishingTab:CreateToggle({Name = "Auto Fish", CurrentValue = false, Callback = function(v) if v then StartAutoFish() else StopAutoFish() end end})
FishingTab:CreateToggle({Name = "Perfect Cast", CurrentValue = true, Callback = function(v) State.PerfectCast = v end})
FishingTab:CreateToggle({Name = "Auto Favorite", CurrentValue = false, Callback = function(v) State.AutoFavorite = v if v then StartAutoFavorite() end end})
FishingTab:CreateToggle({Name = "Auto Sell", CurrentValue = false, Callback = function(v) State.AutoSell = v if v then StartAutoSell() end end})
FishingTab:CreateToggle({Name = "Smart Farming", CurrentValue = false, Callback = function(v) State.SmartFarming = v end})

FishingTab:CreateInput({Name = "Custom Delay", PlaceholderText = "1.5", Callback = function(t)
    local n = tonumber(t) if n then CurrentDelay.Custom = n end
end})

FishingTab:CreateButton({Name = "Sell All Fish", Callback = function() sellRemote:InvokeServer() end})
FishingTab:CreateButton({Name = "Auto Enchant Rod", Callback = function()
    local ENCHANT_POS = Vector3.new(3231, -1303, 1402)
    HumanoidRootPart.CFrame = CFrame.new(ENCHANT_POS + Vector3.new(0, 5, 0))
    task.wait(1)
    equipRemote:FireServer(5)
    task.wait(0.5)
    net:WaitForChild("RE/ActivateEnchantingAltar"):FireServer()
end})

-- Buffs Tab
local BuffTab = Window:CreateTab("🎯 Buffs", 4483362458)
BuffTab:CreateToggle({Name = "Auto Use Potions", CurrentValue = false, Callback = function(v) State.AutoPotion = v end})
BuffTab:CreateToggle({Name = "Auto Place Totems", CurrentValue = false, Callback = function(v) State.AutoTotem = v end})
BuffTab:CreateInput({Name = "Potion Slot", PlaceholderText = "2", Callback = function(t) local n = tonumber(t) if n then PotionSlot = n end end})
BuffTab:CreateInput({Name = "Totem Slot", PlaceholderText = "3", Callback = function(t) local n = tonumber(t) if n then TotemSlot = n end end})

-- Statistics Tab
local StatsTab = Window:CreateTab("📊 Statistics", 4483362458)
local StatLabels = {}
StatLabels.TotalCaught = StatsTab:CreateLabel("Total Caught: 0")
StatLabels.SecretCaught = StatsTab:CreateLabel("Secret: 0")
StatLabels.ShinyCount = StatsTab:CreateLabel("Shiny: 0")
StatLabels.MutationCount = StatsTab:CreateLabel("Mutations: 0")
StatLabels.SessionTime = StatsTab:CreateLabel("Session: 00:00:00")

task.spawn(function()
    while task.wait(1) do
        StatLabels.TotalCaught:Set("Total Caught: " .. Stats.TotalCaught)
        StatLabels.SecretCaught:Set("Secret: " .. Stats.SecretCaught)
        StatLabels.ShinyCount:Set("Shiny: " .. Stats.ShinyCount)
        StatLabels.MutationCount:Set("Mutations: " .. Stats.MutationCount)
        StatLabels.SessionTime:Set("Session: " .. GetSessionTime())
    end
end)

-- Teleport Tab
local TeleportTab = Window:CreateTab("🗺️ Teleport", 4483362458)
local islandNames = {}
for _, island in ipairs(IslandCoords) do table.insert(islandNames, island.name) end

TeleportTab:CreateDropdown({Name = "Select Island", Options = islandNames, CurrentOption = islandNames[1],
    Callback = function(opt)
        for _, island in ipairs(IslandCoords) do
            if island.name == opt then
                HumanoidRootPart.CFrame = CFrame.new(island.pos + Vector3.new(0, 5, 0))
                Rayfield:Notify({Title = "Teleported", Content = opt, Duration = 3, Image = 4483362458})
                break
            end
        end
    end
})

TeleportTab:CreateDropdown({Name = "Teleport to Event", Options = Events, CurrentOption = Events[1],
    Callback = function(opt)
        local props = workspace:FindFirstChild("Props")
        if props and props:FindFirstChild(opt) then
            local boat = props[opt]:FindFirstChild("Fishing Boat")
            if boat then HumanoidRootPart.CFrame = boat:GetPivot() + Vector3.new(0, 15, 0) end
        end
    end
})

-- Utility Tab
local UtilityTab = Window:CreateTab("⚙️ Utility", 4483362458)
UtilityTab:CreateToggle({Name = "Event Notifications", CurrentValue = true, Callback = function(v) State.EventNotifications = v end})
UtilityTab:CreateToggle({Name = "Anti-AFK", CurrentValue = true, Callback = function(v) State.AntiAFK = v end})
UtilityTab:CreateButton({Name = "Boost FPS", Callback = function()
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic
        elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1 end
    end
    settings().Rendering.QualityLevel = "Level01"
    Rayfield:Notify({Title = "FPS Boost", Content = "Applied!", Duration = 3, Image = 4483362458})
end})

UtilityTab:CreateButton({Name = "Server Hop", Callback = function()
    local servers = {}
    local result = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100"))
    for _, server in pairs(result.data) do
        if server.playing < server.maxPlayers and server.id ~= game.JobId then table.insert(servers, server.id) end
    end
    if #servers > 0 then TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(#servers)], LocalPlayer) end
end})

UtilityTab:CreateButton({Name = "Rejoin", Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end})

-- Webhook Tab
local WebhookTab = Window:CreateTab("🌐 Webhook", 4483362458)
WebhookTab:CreateToggle({Name = "Enable Webhook", CurrentValue = false, Callback = function(v) State.WebhookEnabled = v end})
WebhookTab:CreateInput({Name = "Webhook URL", PlaceholderText = "Discord Webhook URL", Callback = function(t) WebhookURL = t end})
WebhookTab:CreateButton({Name = "Test Webhook", Callback = function() SendWebhook("🎣 Test", "Webhook connected!", 65280) end})

-- Settings Tab
local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)
SettingsTab:CreateLabel("DEN HUB - Fish It Ultimate")
SettingsTab:CreateLabel("Version: 3.0.0")
SettingsTab:CreateLabel("Developer: @dendev")
SettingsTab:CreateButton({Name = "Destroy GUI", Callback = function() Rayfield:Destroy() end})

Rayfield:Notify({Title = "DEN HUB v3.0", Content = "All features loaded!", Duration = 5, Image = 4483362458})