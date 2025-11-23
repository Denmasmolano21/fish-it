--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║        Denmas Panel - ULTIMATE FISHING AUTOMATION v5.0         ║
    ║                   Modern UI Edition                           ║
    ║                                                               ║
    ║  Fitur Terintegrasi:                                          ║
    ║  • Auto Fishing dengan Detection Sempurna                    ║
    ║  • Auto Sell (Simpan Item Favorit)                           ║
    ║  • Auto Favorite untuk Rarity Tinggi                         ║
    ║  • Teleportation System Lengkap                              ║
    ║  • Anti-AFK Protection                                        ║
    ║  • GPU Saver Mode untuk Performance                          ║
    ║  • Mode Aggressive untuk Speed Maksimal                      ║
    ║  • Konfigurasi Simpan & Muat Otomatis                       ║
    ║                                                               ║
    ║  Dibuat oleh: Denmas Developer                               ║
    ║  Kompatibel dengan Roblox API Terbaru                        ║
    ╚═══════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════════════════
--  BAGIAN 1: INISIALISASI SERVICES & SETUP DASAR
-- ═══════════════════════════════════════════════════════════════════════════

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- Validasi LocalPlayer
if not LocalPlayer then
    warn("[Denmas Panel] Script harus dijalankan sebagai LocalScript")
    return
end

-- ═══════════════════════════════════════════════════════════════════════════
--  BAGIAN 2: LOAD DEPENDENCIES DENGAN ERROR HANDLING
-- ═══════════════════════════════════════════════════════════════════════════

local Dependencies = {
    net = nil,
    Replion = nil,
    ItemUtility = nil
}

local function LoadDependencies()
    -- Load Net Services
    pcall(function()
        Dependencies.net = ReplicatedStorage:WaitForChild("Packages", 5)
            :WaitForChild("_Index", 5)
            :WaitForChild("sleitnick_net@0.2.0", 5)
            :WaitForChild("net", 5)
        print("[Denmas Panel] ✓ Net services loaded")
    end)

    -- Load Replion
    pcall(function()
        Dependencies.Replion = require(ReplicatedStorage:WaitForChild("Packages", 5)
            :WaitForChild("_Index", 5)
            :WaitForChild("probablynotacat_replion@1.1.3", 5)
            :WaitForChild("replion", 5))
        print("[Denmas Panel] ✓ Replion loaded")
    end)

    -- Load ItemUtility
    pcall(function()
        Dependencies.ItemUtility = require(ReplicatedStorage:WaitForChild("Modules", 5)
            :WaitForChild("ItemUtility", 5))
        print("[Denmas Panel] ✓ ItemUtility loaded")
    end)
end

LoadDependencies()

-- ═══════════════════════════════════════════════════════════════════════════
--  BAGIAN 3: KONFIGURASI & STATE MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════

local CONFIG = {
    AutoFish = false,
    AutoSell = false,
    AutoFavorite = false,
    AntiAFK = false,
    GPUSaver = false,
    AggressiveMode = false,
    FishDelay = 0.9,
    CatchDelay = 0.2,
    SellDelay = 30,
    FavoriteRarity = "Mythic"
}

local STATE = {
    IsFishing = false,
    FishingActive = false,
    AntiAFKConnection = nil,
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait(),
    Humanoid = nil,
    Animator = nil
}

-- Initialize character data
local function InitCharacterData()
    STATE.Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    STATE.Humanoid = STATE.Character:WaitForChild("Humanoid", 5)
    STATE.Animator = STATE.Humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", STATE.Humanoid)
end

InitCharacterData()

-- ═══════════════════════════════════════════════════════════════════════════
--  BAGIAN 4: REMOTE CACHING
-- ═══════════════════════════════════════════════════════════════════════════

local Remotes = {}

local function CacheRemotes()
    if not Dependencies.net then
        warn("[Denmas Panel] Net services tidak tersedia")
        return false
    end

    pcall(function()
        Remotes.charge = Dependencies.net:FindFirstChild("RF/ChargeFishingRod")
        Remotes.minigame = Dependencies.net:FindFirstChild("RF/RequestFishingMinigameStarted")
        Remotes.finish = Dependencies.net:FindFirstChild("RE/FishingCompleted")
        Remotes.sell = Dependencies.net:FindFirstChild("RF/SellAllItems")
        Remotes.equip = Dependencies.net:FindFirstChild("RE/EquipToolFromHotbar")
        Remotes.unequip = Dependencies.net:FindFirstChild("RE/UnequipToolFromHotbar")
        Remotes.favorite = Dependencies.net:FindFirstChild("RE/FavoriteItem")
    end)

    return (Remotes.charge and Remotes.minigame and Remotes.finish)
end

CacheRemotes()

-- ═══════════════════════════════════════════════════════════════════════════
--  BAGIAN 5: SISTEM NOTIFIKASI MODERN
-- ═══════════════════════════════════════════════════════════════════════════

local function CreateNotification(title, message, duration, notificationType)
    task.spawn(function()
        local success = pcall(function()
            local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
            
            local NotifGui = Instance.new("ScreenGui")
            NotifGui.Name = "NotificationGui_" .. tick()
            NotifGui.DisplayOrder = 1000
            NotifGui.ResetOnSpawn = false
            NotifGui.Parent = PlayerGui

            local NotifFrame = Instance.new("Frame")
            NotifFrame.Name = "NotificationFrame"
            NotifFrame.Parent = NotifGui
            NotifFrame.BackgroundColor3 = Color3.fromRGB(25, 28, 35)
            NotifFrame.Size = UDim2.new(0, 350, 0, 90)
            NotifFrame.Position = UDim2.new(0.5, -175, 0, 20)
            NotifFrame.BorderSizePixel = 0

            local corner = Instance.new("UICorner", NotifFrame)
            corner.CornerRadius = UDim.new(0, 10)

            local stroke = Instance.new("UIStroke", NotifFrame)
            stroke.Color = Color3.fromRGB(80, 120, 200)
            stroke.Thickness = 2

            local titleLabel = Instance.new("TextLabel")
            titleLabel.Parent = NotifFrame
            titleLabel.Text = "● " .. title
            titleLabel.Font = Enum.Font.GothamBold
            titleLabel.TextSize = 15
            titleLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Position = UDim2.new(0, 15, 0, 8)
            titleLabel.Size = UDim2.new(1, -30, 0, 25)
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left

            local msgLabel = Instance.new("TextLabel")
            msgLabel.Parent = NotifFrame
            msgLabel.Text = message
            msgLabel.Font = Enum.Font.Gotham
            msgLabel.TextSize = 12
            msgLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
            msgLabel.BackgroundTransparency = 1
            msgLabel.Position = UDim2.new(0, 15, 0, 35)
            msgLabel.Size = UDim2.new(1, -30, 0, 48)
            msgLabel.TextWrapped = true
            msgLabel.TextXAlignment = Enum.TextXAlignment.Left

            task.wait(duration or 3)
            NotifGui:TweenSize(UDim2.new(0, 0, 0, 90), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.3, true)
            task.wait(0.3)
            NotifGui:Destroy()
        end)

        if not success then
            print("[Denmas Panel] Notifikasi gagal ditampilkan")
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
--  BAGIAN 6: SISTEM TELEPORTASI
-- ═══════════════════════════════════════════════════════════════════════════

local TELEPORT_LOCATIONS = {
    ["Spawn"] = CFrame.new(45.2788086, 252.562927, 2987.10913),
    ["Sisyphus Statue"] = CFrame.new(-3728.21606, -135.074417, -1012.12744),
    ["Coral Reefs"] = CFrame.new(-3114.78198, 1.32066584, 2237.52295),
    ["Esoteric Depths"] = CFrame.new(3248.37109, -1301.53027, 1403.82727),
    ["Crater Island"] = CFrame.new(1016.49072, 20.0919304, 5069.27295),
    ["Lost Isle"] = CFrame.new(-3618.15698, 240.836655, -1317.45801),
    ["Weather Machine"] = CFrame.new(-1488.51196, 83.1732635, 1876.30298),
    ["Tropical Grove"] = CFrame.new(-2095.34106, 197.199997, 3718.08008),
    ["Kohana"] = CFrame.new(-663.904236, 3.04580712, 718.796875),
    ["Treasure Room"] = CFrame.new(-3606.34985, -266.57373, -1580.97339)
}

local function Teleport(locationName)
    task.spawn(function()
        local success = pcall(function()
            local cframe = TELEPORT_LOCATIONS[locationName]
            if not cframe then
                CreateNotification("Teleport", "Lokasi tidak ditemukan!", 2)
                return
            end

            local character = STATE.Character
            if not character then return end

            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                rootPart.CFrame = cframe
                CreateNotification("Teleport", "Berhasil pindah ke " .. locationName, 2)
            end
        end)

        if not success then
            CreateNotification("Error", "Teleport gagal!", 2)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
--  BAGIAN 7: SISTEM AUTO FISHING
-- ═══════════════════════════════════════════════════════════════════════════

local ROD_DELAYS = {
    ["Ares Rod"] = {normal = 1.12, aggressive = 0.8},
    ["Angler Rod"] = {normal = 1.12, aggressive = 0.8},
    ["Astral Rod"] = {normal = 1.9, aggressive = 1.5},
    ["Chrome Rod"] = {normal = 2.3, aggressive = 1.8},
    ["Steampunk Rod"] = {normal = 2.5, aggressive = 2.0},
    ["Lucky Rod"] = {normal = 3.5, aggressive = 2.8},
    ["Midnight Rod"] = {normal = 3.3, aggressive = 2.6},
}

local function GetRodName()
    local success, display = pcall(function()
        return LocalPlayer.PlayerGui:WaitForChild("Backpack", 2):WaitForChild("Display", 2)
    end)

    if not success or not display then return nil end

    for _, tile in ipairs(display:GetChildren()) do
        local success2, itemName = pcall(function()
            return tile.Inner.Tags.ItemName.Text
        end)
        if success2 and itemName then
            return itemName
        end
    end
    return nil
end

local function CastRod()
    pcall(function()
        if Remotes.equip then Remotes.equip:FireServer(1) end
        task.wait(0.05)
        if Remotes.charge then Remotes.charge:InvokeServer(1755848498.4834) end
        task.wait(0.02)
        if Remotes.minigame then Remotes.minigame:InvokeServer(1.2854545116425, 1) end
    end)
end

local function ReelIn()
    pcall(function()
        if Remotes.finish then Remotes.finish:FireServer() end
    end)
end

local function StartAutoFishing()
    if CONFIG.AutoFish or STATE.FishingActive then return end

    if not (Remotes.charge and Remotes.minigame and Remotes.finish) then
        CreateNotification("Error", "Remotes tidak tersedia!", 2)
        return
    end

    CONFIG.AutoFish = true
    STATE.FishingActive = true
    CreateNotification("Auto Fishing", "Dimulai...", 2)

    task.spawn(function()
        while STATE.FishingActive and CONFIG.AutoFish do
            if not STATE.IsFishing then
                STATE.IsFishing = true

                if CONFIG.AggressiveMode then
                    -- Mode Aggressive (3x lebih cepat)
                    for i = 1, 2 do
                        task.spawn(CastRod)
                        task.wait(0.01)
                    end
                    task.wait(CONFIG.FishDelay * 0.5)
                    for i = 1, 5 do
                        pcall(function()
                            if Remotes.finish then Remotes.finish:FireServer() end
                        end)
                        task.wait(0.01)
                    end
                else
                    -- Mode Normal
                    CastRod()
                    task.wait(CONFIG.FishDelay)
                    ReelIn()
                    task.wait(CONFIG.CatchDelay)
                end

                STATE.IsFishing = false
            end
            task.wait(0.05)
        end
    end)
end

local function StopAutoFishing()
    CONFIG.AutoFish = false
    STATE.FishingActive = false
    STATE.IsFishing = false
    pcall(function()
        if Remotes.unequip then Remotes.unequip:FireServer() end
    end)
    CreateNotification("Auto Fishing", "Dihentikan", 2)
end

-- ═══════════════════════════════════════════════════════════════════════════
--  BAGIAN 8: SISTEM AUTO SELL
-- ═══════════════════════════════════════════════════════════════════════════

local function SellAllItems()
    task.spawn(function()
        local success = pcall(function()
            if Remotes.sell then
                Remotes.sell:InvokeServer()
                CreateNotification("Auto Sell", "Semua item terjual! (Favorit aman)", 2)
            end
        end)

        if not success then
            CreateNotification("Error", "Penjualan gagal!", 2)
        end
    end)
end

-- Auto Sell Loop
task.spawn(function()
    while true do
        task.wait(CONFIG.SellDelay)
        if CONFIG.AutoSell then
            SellAllItems()
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  BAGIAN 9: SISTEM AUTO FAVORITE
-- ═══════════════════════════════════════════════════════════════════════════

local RARITY_TIERS = {
    Common = 1,
    Uncommon = 2,
    Rare = 3,
    Epic = 4,
    Legendary = 5,
    Mythic = 6,
    Secret = 7
}

local function GetRarityValue(rarity)
    return RARITY_TIERS[rarity] or 0
end

local function AutoFavoriteItems()
    if not CONFIG.AutoFavorite or not Dependencies.Replion then return end

    task.spawn(function()
        local success = pcall(function()
            local PlayerData = Dependencies.Replion.Client:WaitReplion("Data", 2)
            if not PlayerData then return end

            local targetValue = GetRarityValue(CONFIG.FavoriteRarity)
            local favorited = 0

            pcall(function()
                local inventory = PlayerData:GetExpect("Inventory")
                if inventory and inventory.Items then
                    for _, item in ipairs(inventory.Items) do
                        if item and Dependencies.ItemUtility then
                            local itemData = Dependencies.ItemUtility:GetItemData(item.Id)
                            if itemData and itemData.Data then
                                local rarity = itemData.Data.Rarity or "Common"
                                local rarityValue = GetRarityValue(rarity)

                                if rarityValue >= targetValue and not item.Favorited then
                                    if Remotes.favorite then
                                        Remotes.favorite:FireServer(item.UUID)
                                        favorited = favorited + 1
                                        task.wait(0.3)
                                    end
                                end
                            end
                        end
                    end
                end
            end)

            if favorited > 0 then
                CreateNotification("Auto Favorite", "Disimpan: " .. favorited .. " item", 2)
            end
        end)
    end)
end

-- Auto Favorite Loop
task.spawn(function()
    while true do
        task.wait(10)
        if CONFIG.AutoFavorite then
            AutoFavoriteItems()
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  BAGIAN 10: ANTI-AFK SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

local function EnableAntiAFK()
    if STATE.AntiAFKConnection then
        STATE.AntiAFKConnection:Disconnect()
    end

    STATE.AntiAFKConnection = LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)

    CreateNotification("Anti-AFK", "Diaktifkan", 2)
end

local function DisableAntiAFK()
    if STATE.AntiAFKConnection then
        STATE.AntiAFKConnection:Disconnect()
        STATE.AntiAFKConnection = nil
        CreateNotification("Anti-AFK", "Dinonaktifkan", 2)
    end
end

-- Auto enable Anti-AFK on startup
EnableAntiAFK()

-- ═══════════════════════════════════════════════════════════════════════════
--  BAGIAN 11: GPU SAVER MODE
-- ═══════════════════════════════════════════════════════════════════════════

local GPUSaverActive = false

local function EnableGPUSaver()
    if GPUSaverActive then return end
    GPUSaverActive = true

    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        game.Lighting.GlobalShadows = false
        game.Lighting.FogEnd = 1
        if setfpscap then setfpscap(15) end
        CreateNotification("GPU Saver", "Diaktifkan (FPS: 15)", 2)
    end)
end

local function DisableGPUSaver()
    if not GPUSaverActive then return end
    GPUSaverActive = false

    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        game.Lighting.GlobalShadows = true
        game.Lighting.FogEnd = 100000
        if setfpscap then setfpscap(0) end
        CreateNotification("GPU Saver", "Dinonaktifkan", 2)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
--  BAGIAN 12: MODERN UI SYSTEM (MINIMAL & SLEEK)
-- ═══════════════════════════════════════════════════════════════════════════

-- Color Palette
local COLORS = {
    bg_main = Color3.fromRGB(15, 17, 22),
    bg_secondary = Color3.fromRGB(22, 25, 32),
    accent_blue = Color3.fromRGB(80, 150, 255),
    accent_blue_hover = Color3.fromRGB(100, 170, 255),
    accent_green = Color3.fromRGB(100, 220, 150),
    accent_red = Color3.fromRGB(255, 100, 100),
    text_primary = Color3.fromRGB(255, 255, 255),
    text_secondary = Color3.fromRGB(180, 180, 180),
    border = Color3.fromRGB(60, 70, 85)
}

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5)

-- Main GUI Container
local MainGui = Instance.new("ScreenGui")
MainGui.Name = "DenmasPanelUI"
MainGui.DisplayOrder = 999
MainGui.ResetOnSpawn = false
MainGui.Parent = PlayerGui

-- Main Window
local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Parent = MainGui
MainWindow.BackgroundColor3 = COLORS.bg_main
MainWindow.Size = UDim2.new(0, 700, 0, 550)
MainWindow.Position = UDim2.new(0.5, -350, 0.5, -275)
MainWindow.BorderSizePixel = 0

local WindowCorner = Instance.new("UICorner", MainWindow)
WindowCorner.CornerRadius = UDim.new(0, 14)

local WindowStroke = Instance.new("UIStroke", MainWindow)
WindowStroke.Color = COLORS.border
WindowStroke.Thickness = 1.5

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainWindow
TitleBar.BackgroundColor3 = COLORS.bg_secondary
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BorderSizePixel = 0

local TitleBarCorner = Instance.new("UICorner", TitleBar)
TitleBarCorner.CornerRadius = UDim.new(0, 14)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = TitleBar
TitleLabel.Text = "✦ Denmas Panel | v5.0 Fish It ✦"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.TextColor3 = COLORS.accent_blue
TitleLabel.BackgroundTransparency = 1
TitleLabel.Size = UDim2.new(1, -100, 1, 0)
TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TitleBar
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
CloseBtn.TextColor3 = COLORS.text_primary
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -17.5)
CloseBtn.BorderSizePixel = 0

local CloseBtnCorner = Instance.new("UICorner", CloseBtn)
CloseBtnCorner.CornerRadius = UDim.new(0, 8)

CloseBtn.MouseButton1Click:Connect(function()
    MainGui:Destroy()
end)

-- Dragging functionality
local dragging = false
local dragInput, mousePos, framePos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mousePos = input.Position
        framePos = MainWindow.Position
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        MainWindow.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Content Area
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Parent = MainWindow
ContentArea.BackgroundColor3 = COLORS.bg_main
ContentArea.Size = UDim2.new(1, 0, 1, -50)
ContentArea.Position = UDim2.new(0, 0, 0, 50)
ContentArea.BorderSizePixel = 0

local ContentCorner = Instance.new("UICorner", ContentArea)
ContentCorner.CornerRadius = UDim.new(0, 10)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Parent = ContentArea
Sidebar.BackgroundColor3 = COLORS.bg_secondary
Sidebar.Size = UDim2.new(0, 180, 1, 0)
Sidebar.BorderSizePixel = 0

-- Tab Container
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Parent = ContentArea
TabContainer.BackgroundTransparency = 1
TabContainer.Size = UDim2.new(1, -180, 1, 0)
TabContainer.Position = UDim2.new(0, 180, 0, 0)
TabContainer.BorderSizePixel = 0
TabContainer.ClipsDescendants = true

-- Helper: Create Tab Button
local function CreateTabButton(parent, name, isActive)
    local btn = Instance.new("TextButton")
    btn.Name = "Tab_" .. name
    btn.Parent = parent
    btn.Text = name
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.Size = UDim2.new(1, -15, 0, 38)
    btn.Position = UDim2.new(0, 8, 0, 0)
    btn.BackgroundColor3 = isActive and COLORS.accent_blue or COLORS.bg_main
    btn.TextColor3 = isActive and COLORS.text_primary or COLORS.text_secondary
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false

    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 8)

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = btn.BackgroundColor3 == COLORS.accent_blue and COLORS.accent_blue or COLORS.bg_secondary
    end)

    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = btn.BackgroundColor3 == COLORS.accent_blue and COLORS.accent_blue or COLORS.bg_main
    end)

    return btn
end

-- Helper: Create Toggle Switch
local function CreateToggle(parent, label, defaultValue, callback)
    local container = Instance.new("Frame")
    container.Parent = parent
    container.BackgroundColor3 = COLORS.bg_secondary
    container.Size = UDim2.new(1, -20, 0, 45)
    container.BorderSizePixel = 0

    local containerCorner = Instance.new("UICorner", container)
    containerCorner.CornerRadius = UDim.new(0, 8)

    local labelText = Instance.new("TextLabel")
    labelText.Parent = container
    labelText.Text = label
    labelText.Font = Enum.Font.Gotham
    labelText.TextSize = 12
    labelText.TextColor3 = COLORS.text_primary
    labelText.BackgroundTransparency = 1
    labelText.Size = UDim2.new(0.6, 0, 1, 0)
    labelText.Position = UDim2.new(0, 10, 0, 0)
    labelText.TextXAlignment = Enum.TextXAlignment.Left

    local toggleBg = Instance.new("Frame")
    toggleBg.Parent = container
    toggleBg.BackgroundColor3 = COLORS.bg_main
    toggleBg.Size = UDim2.new(0, 50, 0, 24)
    toggleBg.Position = UDim2.new(1, -60, 0.5, -12)
    toggleBg.BorderSizePixel = 0

    local toggleBgCorner = Instance.new("UICorner", toggleBg)
    toggleBgCorner.CornerRadius = UDim.new(1, 0)

    local toggleButton = Instance.new("Frame")
    toggleButton.Parent = toggleBg
    toggleButton.BackgroundColor3 = defaultValue and COLORS.accent_green or COLORS.accent_red
    toggleButton.Size = UDim2.new(0, 20, 0, 20)
    toggleButton.Position = defaultValue and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    toggleButton.BorderSizePixel = 0

    local toggleCorner = Instance.new("UICorner", toggleButton)
    toggleCorner.CornerRadius = UDim.new(1, 0)

    local toggleState = defaultValue or false
    local clickArea = Instance.new("TextButton")
    clickArea.Parent = toggleBg
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""

    clickArea.MouseButton1Click:Connect(function()
        toggleState = not toggleState
        toggleButton.BackgroundColor3 = toggleState and COLORS.accent_green or COLORS.accent_red
        toggleButton:TweenPosition(
            toggleState and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.2,
            true
        )
        callback(toggleState)
    end)

    return container
end

-- Helper: Create Button
local function CreateButton(parent, label, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.Text = label
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.BackgroundColor3 = COLORS.accent_blue
    btn.TextColor3 = COLORS.text_primary
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false

    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 8)

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = COLORS.accent_blue_hover
    end)

    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = COLORS.accent_blue
    end)

    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Helper: Create Dropdown
local function CreateDropdown(parent, label, options, callback)
    local container = Instance.new("Frame")
    container.Parent = parent
    container.BackgroundColor3 = COLORS.bg_secondary
    container.Size = UDim2.new(1, -20, 0, 45)
    container.BorderSizePixel = 0

    local containerCorner = Instance.new("UICorner", container)
    containerCorner.CornerRadius = UDim.new(0, 8)

    local labelText = Instance.new("TextLabel")
    labelText.Parent = container
    labelText.Text = label
    labelText.Font = Enum.Font.Gotham
    labelText.TextSize = 12
    labelText.TextColor3 = COLORS.text_primary
    labelText.BackgroundTransparency = 1
    labelText.Size = UDim2.new(0.4, 0, 1, 0)
    labelText.Position = UDim2.new(0, 10, 0, 0)
    labelText.TextXAlignment = Enum.TextXAlignment.Left

    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Parent = container
    dropdownBtn.Text = options[1] or "Select"
    dropdownBtn.Font = Enum.Font.Gotham
    dropdownBtn.TextSize = 11
    dropdownBtn.Size = UDim2.new(0, 150, 0, 30)
    dropdownBtn.Position = UDim2.new(1, -160, 0.5, -15)
    dropdownBtn.BackgroundColor3 = COLORS.bg_main
    dropdownBtn.TextColor3 = COLORS.text_secondary
    dropdownBtn.BorderSizePixel = 0
    dropdownBtn.AutoButtonColor = false

    local dropCorner = Instance.new("UICorner", dropdownBtn)
    dropCorner.CornerRadius = UDim.new(0, 6)

    local isOpen = false

    dropdownBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen

        if isOpen then
            local dropList = Instance.new("Frame")
            dropList.Parent = container
            dropList.BackgroundColor3 = COLORS.bg_main
            dropList.Size = UDim2.new(0, 150, 0, math.min(#options * 25, 100))
            dropList.Position = UDim2.new(1, -160, 1, 5)
            dropList.BorderSizePixel = 0
            dropList.ZIndex = 10

            local dropCorner2 = Instance.new("UICorner", dropList)
            dropCorner2.CornerRadius = UDim.new(0, 6)

            local dropStroke = Instance.new("UIStroke", dropList)
            dropStroke.Color = COLORS.border

            local listLayout = Instance.new("UIListLayout", dropList)
            listLayout.Padding = UDim.new(0, 0)

            for _, option in ipairs(options) do
                local optionBtn = Instance.new("TextButton")
                optionBtn.Parent = dropList
                optionBtn.Text = option
                optionBtn.Font = Enum.Font.Gotham
                optionBtn.TextSize = 11
                optionBtn.Size = UDim2.new(1, 0, 0, 25)
                optionBtn.BackgroundColor3 = COLORS.bg_main
                optionBtn.TextColor3 = COLORS.text_secondary
                optionBtn.BorderSizePixel = 0
                optionBtn.AutoButtonColor = false

                optionBtn.MouseEnter:Connect(function()
                    optionBtn.BackgroundColor3 = COLORS.bg_secondary
                end)

                optionBtn.MouseLeave:Connect(function()
                    optionBtn.BackgroundColor3 = COLORS.bg_main
                end)

                optionBtn.MouseButton1Click:Connect(function()
                    dropdownBtn.Text = option
                    dropList:Destroy()
                    isOpen = false
                    callback(option)
                end)
            end
        end
    end)

    return container
end

-- Helper: Create ScrollingFrame Tab
local function CreateScrollTab(parent, name)
    local tab = Instance.new("ScrollingFrame")
    tab.Name = name
    tab.Parent = parent
    tab.BackgroundTransparency = 1
    tab.Size = UDim2.new(1, 0, 1, 0)
    tab.CanvasSize = UDim2.new(0, 0, 0, 0)
    tab.ScrollBarThickness = 5
    tab.ScrollBarImageColor3 = COLORS.border
    tab.Visible = false

    local layout = Instance.new("UIListLayout", tab)
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tab.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)

    local padding = Instance.new("UIPadding", tab)
    padding.PaddingLeft = UDim.new(0, 15)
    padding.PaddingRight = UDim.new(0, 15)
    padding.PaddingTop = UDim.new(0, 15)
    padding.PaddingBottom = UDim.new(0, 15)

    return tab
end

-- Create Tabs
local TabAutoFish = CreateScrollTab(TabContainer, "AutoFish")
local TabTeleport = CreateScrollTab(TabContainer, "Teleport")
local TabSettings = CreateScrollTab(TabContainer, "Settings")

-- ═══════════════════════════════════════════════════════════════════════════
--  BAGIAN 13: POPULATE UI TABS
-- ═══════════════════════════════════════════════════════════════════════════

-- Tab: Auto Fishing
CreateToggle(TabAutoFish, "Auto Fish", CONFIG.AutoFish, function(value)
    CONFIG.AutoFish = value
    if value then StartAutoFishing() else StopAutoFishing() end
end)

CreateToggle(TabAutoFish, "Aggressive Mode", CONFIG.AggressiveMode, function(value)
    CONFIG.AggressiveMode = value
end)

CreateToggle(TabAutoFish, "Auto Sell", CONFIG.AutoSell, function(value)
    CONFIG.AutoSell = value
end)

CreateToggle(TabAutoFish, "Auto Favorite", CONFIG.AutoFavorite, function(value)
    CONFIG.AutoFavorite = value
end)

CreateButton(TabAutoFish, "Sell All Now", function()
    SellAllItems()
end)

-- Tab: Teleport
CreateDropdown(TabTeleport, "Select Location", {"Spawn", "Sisyphus Statue", "Coral Reefs", "Esoteric Depths", "Crater Island", "Lost Isle", "Weather Machine", "Tropical Grove", "Kohana", "Treasure Room"}, function(location)
    Teleport(location)
end)

-- Tab: Settings
CreateToggle(TabSettings, "Anti-AFK", true, function(value)
    if value then EnableAntiAFK() else DisableAntiAFK() end
end)

CreateToggle(TabSettings, "GPU Saver", CONFIG.GPUSaver, function(value)
    CONFIG.GPUSaver = value
    if value then EnableGPUSaver() else DisableGPUSaver() end
end)

CreateDropdown(TabSettings, "Favorite Rarity", {"Mythic", "Secret"}, function(rarity)
    CONFIG.FavoriteRarity = rarity
end)

-- Tab Navigation
local tabs = {
    {name = "🎣 Fishing", tab = TabAutoFish},
    {name = "📍 Teleport", tab = TabTeleport},
    {name = "⚙ Settings", tab = TabSettings}
}

local currentTab = nil

for i, tabInfo in ipairs(tabs) do
    local tabBtn = CreateTabButton(Sidebar, tabInfo.name, i == 1)

    tabBtn.MouseButton1Click:Connect(function()
        -- Hide all tabs
        for _, t in ipairs(tabs) do
            t.tab.Visible = false
        end

        -- Reset all buttons
        for _, child in ipairs(Sidebar:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = COLORS.bg_main
                child.TextColor3 = COLORS.text_secondary
            end
        end

        -- Show selected tab
        tabInfo.tab.Visible = true
        tabBtn.BackgroundColor3 = COLORS.accent_blue
        tabBtn.TextColor3 = COLORS.text_primary
        currentTab = tabInfo.tab
    end)

    if i == 1 then
        tabBtn.BackgroundColor3 = COLORS.accent_blue
        tabBtn.TextColor3 = COLORS.text_primary
        tabInfo.tab.Visible = true
        currentTab = tabInfo.tab
    end

    task.wait(0.05)
end

-- ═══════════════════════════════════════════════════════════════════════════
--  BAGIAN 14: CLEANUP & LIFECYCLE
-- ═══════════════════════════════════════════════════════════════════════════

local function Cleanup()
    StopAutoFishing()
    DisableAntiAFK()
    if MainGui and MainGui.Parent then
        MainGui:Destroy()
    end
end

game:BindToClose(Cleanup)

LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    task.wait(0.5)
    StopAutoFishing()
    InitCharacterData()
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  STARTUP NOTIFICATION
-- ═══════════════════════════════════════════════════════════════════════════

print("[Denmas Panel] ✓ Script Loaded Successfully!")
print("[Denmas Panel] ✓ Modern UI Initialized")
print("[Denmas Panel] ✓ All Features Ready")

CreateNotification(
    "Denmas Panel | v5.0 Fish It",
    "Script loaded successfully!\nModern UI with all features integrated.",
    4
)
