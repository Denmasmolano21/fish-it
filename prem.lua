-- ====================================================================
--  AUTO FISH V4.0 - RAYFIELD UI EDITION
--  
--  Dibuat oleh: Denmas Developer
--  Deskripsi: Script otomasi penangkapan ikan dengan UI Rayfield
--  Fitur: Auto Fishing, Auto Sell, Auto Catch, GPU Saver, Auto Favorite
--  Versi: 4.0 (Optimized & Clean Code)
-- ====================================================================

-- ====== PEMERIKSAAN DEPENDENCY KRITIS ======
local success, errorMsg = pcall(function()
    local services = {
        game = game,
        workspace = workspace,
        Players = game:GetService("Players"),
        RunService = game:GetService("RunService"),
        ReplicatedStorage = game:GetService("ReplicatedStorage"),
        HttpService = game:GetService("HttpService")
    }
    
    for serviceName, service in pairs(services) do
        if not service then
            error("Service kritis tidak ditemukan: " .. serviceName)
        end
    end
    
    local LocalPlayer = game:GetService("Players").LocalPlayer
    if not LocalPlayer then
        error("LocalPlayer tidak tersedia")
    end
    
    return true
end)

if not success then
    error("[Auto Fish] Pemeriksaan dependency gagal: " .. tostring(errorMsg))
    return
end

-- ====================================================================
--                        LAYANAN UTAMA
-- ====================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- ====================================================================
--                    KONFIGURASI
-- ====================================================================
local CONFIG_FOLDER = "OptimizedAutoFish"
local CONFIG_FILE = CONFIG_FOLDER .. "/config_" .. LocalPlayer.UserId .. ".json"

local DefaultConfig = {
    AutoFish = false,
    AutoSell = false,
    AutoCatch = false,
    GPUSaver = false,
    BlatantMode = false,
    FishDelay = 0.9,
    CatchDelay = 0.2,
    SellDelay = 30,
    TeleportLocation = "Sisyphus Statue",
    AutoFavorite = true,
    FavoriteRarity = "Mythic"
}

local Config = {}
for k, v in pairs(DefaultConfig) do Config[k] = v end

-- Daftar Lokasi Teleport
local LOCATIONS = {
    ["Spawn"] = CFrame.new(45.2788086, 252.562927, 2987.10913, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    ["Sisyphus Statue"] = CFrame.new(-3728.21606, -135.074417, -1012.12744, -0.977224171, 7.74980258e-09, -0.212209702, 1.566994e-08, 1, -3.5640408e-08, 0.212209702, -3.81539813e-08, -0.977224171),
    ["Coral Reefs"] = CFrame.new(-3114.78198, 1.32066584, 2237.52295, -0.304758579, 1.6556676e-08, -0.952429652, -8.50574935e-08, 1, 4.46003305e-08, 0.952429652, 9.46036067e-08, -0.304758579),
    ["Esoteric Depths"] = CFrame.new(3248.37109, -1301.53027, 1403.82727, -0.920208454, 7.76270355e-08, 0.391428679, 4.56261056e-08, 1, -9.10549289e-08, -0.391428679, -6.5930152e-08, -0.920208454),
    ["Crater Island"] = CFrame.new(1016.49072, 20.0919304, 5069.27295, 0.838976264, 3.30379857e-09, -0.544168055, 2.63538391e-09, 1, 1.01344115e-08, 0.544168055, -9.93662219e-09, 0.838976264),
    ["Lost Isle"] = CFrame.new(-3618.15698, 240.836655, -1317.45801, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    ["Weather Machine"] = CFrame.new(-1488.51196, 83.1732635, 1876.30298, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    ["Tropical Grove"] = CFrame.new(-2095.34106, 197.199997, 3718.08008),
    ["Mount Hallow"] = CFrame.new(2136.62305, 78.9163895, 3272.50439, -0.977613986, -1.77645827e-08, 0.210406482, -2.42338203e-08, 1, -2.81680421e-08, -0.210406482, -3.26364251e-08, -0.977613986),
    ["Treasure Room"] = CFrame.new(-3606.34985, -266.57373, -1580.97339, 0.998743415, 1.12141152e-13, -0.0501160324, -1.56847693e-13, 1, -8.88127842e-13, 0.0501160324, 8.94872392e-13, 0.998743415),
    ["Kohana"] = CFrame.new(-663.904236, 3.04580712, 718.796875, -0.100799225, -2.14183729e-08, -0.994906783, -1.12300391e-08, 1, -2.03902459e-08, 0.994906783, 9.11752096e-09, -0.100799225),
    ["Underground Cellar"] = CFrame.new(2109.52148, -94.1875076, -708.609131, 0.418592364, 3.34794485e-08, -0.908174217, -5.24141512e-08, 1, 1.27060247e-08, 0.908174217, 4.22825366e-08, 0.418592364),
    ["Ancient Jungle"] = CFrame.new(1831.71362, 6.62499952, -299.279175, 0.213522509, 1.25553285e-07, -0.976938128, -4.32026184e-08, 1, 1.19074642e-07, 0.976938128, 1.67811702e-08, 0.213522509),
    ["Sacred Temple"] = CFrame.new(1466.92151, -21.8750591, -622.835693, -0.764787138, 8.14444334e-09, 0.644283056, 2.31097452e-08, 1, 1.4791004e-08, -0.644283056, 2.6201187e-08, -0.764787138)
}

-- ====================================================================
--                     FUNGSI KONFIGURASI
-- ====================================================================
local function ensureFolder()
    if not isfolder or not makefolder then return false end
    if not isfolder(CONFIG_FOLDER) then
        pcall(function() makefolder(CONFIG_FOLDER) end)
    end
    return isfolder(CONFIG_FOLDER)
end

local function saveConfig()
    if not writefile or not ensureFolder() then return end
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
        print("[Konfigurasi] Pengaturan tersimpan")
    end)
end

local function loadConfig()
    if not readfile or not isfile or not isfile(CONFIG_FILE) then return end
    pcall(function()
        local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
        for k, v in pairs(data) do
            if DefaultConfig[k] ~= nil then Config[k] = v end
        end
        print("[Konfigurasi] Pengaturan dimuat")
    end)
end

loadConfig()

-- ====================================================================
--                     EVENT JARINGAN
-- ====================================================================
local function getNetworkEvents()
    local net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
    return {
        fishing = net:WaitForChild("RE/FishingCompleted"),
        sell = net:WaitForChild("RF/SellAllItems"),
        charge = net:WaitForChild("RF/ChargeFishingRod"),
        minigame = net:WaitForChild("RF/RequestFishingMinigameStarted"),
        cancel = net:WaitForChild("RF/CancelFishingInputs"),
        equip = net:WaitForChild("RE/EquipToolFromHotbar"),
        unequip = net:WaitForChild("RE/UnequipToolFromHotbar"),
        favorite = net:WaitForChild("RE/FavoriteItem")
    }
end

local Events = getNetworkEvents()

-- ====================================================================
--                     MODUL UNTUK FAVORIT OTOMATIS
-- ====================================================================
local ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
local Replion = require(ReplicatedStorage.Packages.Replion)
local PlayerData = Replion.Client:WaitReplion("Data")

-- ====================================================================
--                     SISTEM KELANGKAAN
-- ====================================================================
local RarityTiers = {
    Common = 1,
    Uncommon = 2,
    Rare = 3,
    Epic = 4,
    Legendary = 5,
    Mythic = 6,
    Secret = 7
}

local function getRarityValue(rarity)
    return RarityTiers[rarity] or 0
end

local function getFishRarity(itemData)
    if not itemData or not itemData.Data then return "Common" end
    return itemData.Data.Rarity or "Common"
end

-- ====================================================================
--                     SISTEM TELEPORT
-- ====================================================================
local Teleport = {}

function Teleport.to(locationName)
    local cframe = LOCATIONS[locationName]
    if not cframe then
        warn("[Teleport] Lokasi tidak ditemukan: " .. tostring(locationName))
        return false
    end
    
    local success = pcall(function()
        local character = LocalPlayer.Character
        if not character then return end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        rootPart.CFrame = cframe
        print("[Teleport] Berhasil pindah ke " .. locationName)
    end)
    
    return success
end

-- ====================================================================
--                     PENGHEMAT GPU
-- ====================================================================
local gpuActive = false
local whiteScreen = nil

local function enableGPU()
    if gpuActive then return end
    gpuActive = true
    
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        game.Lighting.GlobalShadows = false
        game.Lighting.FogEnd = 1
        setfpscap(8)
    end)
    
    whiteScreen = Instance.new("ScreenGui")
    whiteScreen.ResetOnSpawn = false
    whiteScreen.DisplayOrder = 999999
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    frame.Parent = whiteScreen
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 400, 0, 100)
    label.Position = UDim2.new(0.5, -200, 0.5, -50)
    label.BackgroundTransparency = 1
    label.Text = "GPU SAVER AKTIF\n\nAuto Fish Berjalan..."
    label.TextColor3 = Color3.new(0, 1, 0)
    label.TextSize = 28
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Parent = frame
    
    whiteScreen.Parent = game.CoreGui
    print("[GPU] Penghemat GPU diaktifkan")
end

local function disableGPU()
    if not gpuActive then return end
    gpuActive = false
    
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        game.Lighting.GlobalShadows = true
        game.Lighting.FogEnd = 100000
        setfpscap(0)
    end)
    
    if whiteScreen then
        whiteScreen:Destroy()
        whiteScreen = nil
    end
    print("[GPU] Penghemat GPU dinonaktifkan")
end

-- ====================================================================
--                     ANTI-AFK
-- ====================================================================
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

print("[Anti-AFK] Perlindungan aktif")

-- ====================================================================
--                     FAVORIT OTOMATIS
-- ====================================================================
local favoritedItems = {}

local function isItemFavorited(uuid)
    local success, result = pcall(function()
        local items = PlayerData:GetExpect("Inventory").Items
        for _, item in ipairs(items) do
            if item.UUID == uuid then
                return item.Favorited == true
            end
        end
        return false
    end)
    return success and result or false
end

local function autoFavoriteByRarity()
    if not Config.AutoFavorite then return end
    
    local targetRarity = Config.FavoriteRarity
    local targetValue = getRarityValue(targetRarity)
    
    if targetValue < 6 then
        targetValue = 6
    end
    
    local favorited = 0
    local skipped = 0
    
    local success = pcall(function()
        local items = PlayerData:GetExpect("Inventory").Items
        
        if not items or #items == 0 then return end
        
        for i, item in ipairs(items) do
            local data = ItemUtility:GetItemData(item.Id)
            if data and data.Data then
                local itemName = data.Data.Name or "Unknown"
                local rarity = getFishRarity(data)
                local rarityValue = getRarityValue(rarity)
                
                if rarityValue >= targetValue and rarityValue >= 6 then
                    if not isItemFavorited(item.UUID) and not favoritedItems[item.UUID] then
                        Events.favorite:FireServer(item.UUID)
                        favoritedItems[item.UUID] = true
                        favorited = favorited + 1
                        print("[Favorit Otomatis] #" .. favorited .. " - " .. itemName .. " (" .. rarity .. ")")
                        task.wait(0.3)
                    else
                        skipped = skipped + 1
                    end
                end
            end
        end
    end)
    
    if favorited > 0 then
        print("[Favorit Otomatis] Selesai! Disimpan: " .. favorited)
    end
end

task.spawn(function()
    while true do
        task.wait(10)
        if Config.AutoFavorite then
            autoFavoriteByRarity()
        end
    end
end)

-- ====================================================================
--                     LOGIKA PENANGKAPAN IKAN
-- ====================================================================
local isFishing = false
local fishingActive = false

local function castRod()
    pcall(function()
        Events.equip:FireServer(1)
        task.wait(0.05)
        Events.charge:InvokeServer(1755848498.4834)
        task.wait(0.02)
        Events.minigame:InvokeServer(1.2854545116425, 1)
        print("[Penangkapan] Pancing dilempar")
    end)
end

local function reelIn()
    pcall(function()
        Events.fishing:FireServer()
        print("[Penangkapan] Pancing ditarik")
    end)
end

local function blatantFishingLoop()
    while fishingActive and Config.BlatantMode do
        if not isFishing then
            isFishing = true
            
            pcall(function()
                Events.equip:FireServer(1)
                task.wait(0.01)
                
                task.spawn(function()
                    Events.charge:InvokeServer(1755848498.4834)
                    task.wait(0.01)
                    Events.minigame:InvokeServer(1.2854545116425, 1)
                end)
                
                task.wait(0.05)
                
                task.spawn(function()
                    Events.charge:InvokeServer(1755848498.4834)
                    task.wait(0.01)
                    Events.minigame:InvokeServer(1.2854545116425, 1)
                end)
            end)
            
            task.wait(Config.FishDelay)
            
            for i = 1, 5 do
                pcall(function() 
                    Events.fishing:FireServer() 
                end)
                task.wait(0.01)
            end
            
            task.wait(Config.CatchDelay * 0.5)
            
            isFishing = false
            print("[Mode Agresif] Siklus cepat")
        else
            task.wait(0.01)
        end
    end
end

local function normalFishingLoop()
    while fishingActive and not Config.BlatantMode do
        if not isFishing then
            isFishing = true
            
            castRod()
            task.wait(Config.FishDelay)
            reelIn()
            task.wait(Config.CatchDelay)
            
            isFishing = false
        else
            task.wait(0.1)
        end
    end
end

local function fishingLoop()
    while fishingActive do
        if Config.BlatantMode then
            blatantFishingLoop()
        else
            normalFishingLoop()
        end
        task.wait(0.1)
    end
end

-- ====================================================================
--                     TANGKAPAN OTOMATIS
-- ====================================================================
task.spawn(function()
    while true do
        if Config.AutoCatch and not isFishing then
            pcall(function() 
                Events.fishing:FireServer() 
            end)
        end
        task.wait(Config.CatchDelay)
    end
end)

-- ====================================================================
--                     PENJUALAN OTOMATIS
-- ====================================================================
local function simpleSell()
    print("[Penjualan Otomatis] Menjual semua item yang tidak difavoritkan...")
    
    local sellSuccess = pcall(function()
        return Events.sell:InvokeServer()
    end)
    
    if sellSuccess then
        print("[Penjualan Otomatis] Berhasil dijual! (Ikan favorit aman)")
    else
        warn("[Penjualan Otomatis] Gagal menjual")
    end
end

task.spawn(function()
    while true do
        task.wait(Config.SellDelay)
        if Config.AutoSell then
            simpleSell()
        end
    end
end)

-- ====================================================================
--                     RAYFIELD UI
-- ====================================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Auto Fish V4.0 - Denmas Developer",
    LoadingTitle = "Otomasi Penangkapan Ikan",
    LoadingSubtitle = "Dibuat oleh Denmas Developer",
    ConfigurationSaving = {
        Enabled = false
    }
})

-- ====== TAB UTAMA ======
local MainTab = Window:CreateTab("Utama", 4483362458)

MainTab:CreateSection("Penangkapan Otomatis")

local BlatantToggle = MainTab:CreateToggle({
    Name = "Mode Agresif (3x Lebih Cepat)",
    CurrentValue = Config.BlatantMode,
    Callback = function(value)
        Config.BlatantMode = value
        print("[Mode Agresif] " .. (value and "DIAKTIFKAN - SANGAT CEPAT!" or "Dinonaktifkan - Kecepatan normal"))
        saveConfig()
    end
})

local AutoFishToggle = MainTab:CreateToggle({
    Name = "Penangkapan Otomatis",
    CurrentValue = Config.AutoFish,
    Callback = function(value)
        Config.AutoFish = value
        fishingActive = value
        
        if value then
            print("[Penangkapan Otomatis] Dimulai " .. (Config.BlatantMode and "(MODE AGRESIF)" or "(Mode Normal)"))
            task.spawn(fishingLoop)
        else
            print("[Penangkapan Otomatis] Berhenti")
            pcall(function() Events.unequip:FireServer() end)
        end
        
        saveConfig()
    end
})

local AutoCatchToggle = MainTab:CreateToggle({
    Name = "Tangkapan Otomatis (Kecepatan Ekstra)",
    CurrentValue = Config.AutoCatch,
    Callback = function(value)
        Config.AutoCatch = value
        print("[Tangkapan Otomatis] " .. (value and "Diaktifkan" or "Dinonaktifkan"))
        saveConfig()
    end
})

MainTab:CreateInput({
    Name = "Penundaan Ikan (detik)",
    PlaceholderText = "Default: 0.9",
    RemoveTextAfterFocusLost = false,
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 0.1 and num <= 10 then
            Config.FishDelay = num
            print("[Konfigurasi] Penundaan ikan diatur ke " .. num .. "d")
            saveConfig()
        else
            warn("[Konfigurasi] Penundaan tidak valid (harus 0.1-10)")
        end
    end
})

MainTab:CreateInput({
    Name = "Penundaan Tangkapan (detik)",
    PlaceholderText = "Default: 0.2",
    RemoveTextAfterFocusLost = false,
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 0.1 and num <= 10 then
            Config.CatchDelay = num
            print("[Konfigurasi] Penundaan tangkapan diatur ke " .. num .. "d")
            saveConfig()
        else
            warn("[Konfigurasi] Penundaan tidak valid (harus 0.1-10)")
        end
    end
})

MainTab:CreateSection("Penjualan Otomatis")

local AutoSellToggle = MainTab:CreateToggle({
    Name = "Penjualan Otomatis (Simpan Favorit)",
    CurrentValue = Config.AutoSell,
    Callback = function(value)
        Config.AutoSell = value
        print("[Penjualan Otomatis] " .. (value and "Diaktifkan" or "Dinonaktifkan"))
        saveConfig()
    end
})

MainTab:CreateInput({
    Name = "Penundaan Penjualan (detik)",
    PlaceholderText = "Default: 30",
    RemoveTextAfterFocusLost = false,
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 10 and num <= 300 then
            Config.SellDelay = num
            print("[Konfigurasi] Penundaan penjualan diatur ke " .. num .. "d")
            saveConfig()
        else
            warn("[Konfigurasi] Penundaan tidak valid (harus 10-300)")
        end
    end
})

MainTab:CreateButton({
    Name = "Jual Semua Sekarang",
    Callback = function()
        simpleSell()
    end
})

-- ====== TAB TELEPORT ======
local TeleportTab = Window:CreateTab("Teleport", nil)

TeleportTab:CreateSection("Lokasi")

for locationName, _ in pairs(LOCATIONS) do
    TeleportTab:CreateButton({
        Name = locationName,
        Callback = function()
            Teleport.to(locationName)
        end
    })
end

-- ====== TAB PENGATURAN ======
local SettingsTab = Window:CreateTab("Pengaturan", 4483362458)

SettingsTab:CreateSection("Performa")

local GPUToggle = SettingsTab:CreateToggle({
    Name = "Mode Penghemat GPU",
    CurrentValue = Config.GPUSaver,
    Callback = function(value)
        Config.GPUSaver = value
        if value then
            enableGPU()
        else
            disableGPU()
        end
        saveConfig()
    end
})

SettingsTab:CreateSection("Favorit Otomatis")

local AutoFavoriteToggle = SettingsTab:CreateToggle({
    Name = "Simpan Ikan sebagai Favorit",
    CurrentValue = Config.AutoFavorite,
    Callback = function(value)
        Config.AutoFavorite = value
        print("[Favorit Otomatis] " .. (value and "Diaktifkan" or "Dinonaktifkan"))
        saveConfig()
    end
})

local FavoriteRarityDropdown = SettingsTab:CreateDropdown({
    Name = "Tingkat Kelangkaan Favorit",
    Options = {"Mythic", "Secret"},
    CurrentOption = Config.FavoriteRarity,
    Callback = function(option)
        Config.FavoriteRarity = option
        print("[Konfigurasi] Tingkat kelangkaan diatur ke: " .. option)
        saveConfig()
    end
})

SettingsTab:CreateButton({
    Name = "Simpan Semua Mythic/Secret Sekarang",
    Callback = function()
        autoFavoriteByRarity()
    end
})

-- ====== TAB INFORMASI ======
local InfoTab = Window:CreateTab("Informasi", 4483362458)

InfoTab:CreateParagraph({
    Title = "Fitur Utama",
    Content = [[
- Penangkapan Ikan Cepat dengan Mode Agresif
- Penjualan Otomatis (Simpan Ikan Favorit)
- Tangkapan Otomatis untuk Kecepatan Ekstra
- Mode Penghemat GPU
- Perlindungan Anti-AFK
- Penyimpanan Konfigurasi Otomatis
- Sistem Teleport Lengkap
- Simpan Favorit Otomatis (Mythic & Secret)
    ]]
})

InfoTab:CreateParagraph({
    Title = "Dibuat oleh Denmas Developer",
    Content = [[
Script ini dikembangkan dengan fokus pada:

- Performa tinggi dan optimasi kode
- Antarmuka yang bersih dan profesional
- Fitur lengkap untuk otomasi penangkapan ikan
- Stabilitas dan keandalan tinggi

Untuk informasi lebih lanjut atau laporan bug,
hubungi Denmas Developer.
    ]]
})

InfoTab:CreateParagraph({
    Title = "Cara Kerja Mode Agresif",
    Content = [[
Mode Agresif bekerja dengan:

1. Melempar 2 pancing secara bersamaan
2. Waktu tunggu ikan yang efisien
3. Menarik pancing 5x untuk tangkapan instan
4. Penundaan siklus 50% lebih cepat
5. Hasil: ~40% penangkapan lebih cepat

Catatan: Mode ini membutuhkan koneksi stabil
    ]]
})

InfoTab:CreateParagraph({
    Title = "Pengaturan Rekomendasi",
    Content = [[
Untuk pengalaman terbaik:

- Penundaan Ikan: 0.9 detik
- Penundaan Tangkapan: 0.2 detik
- Penundaan Penjualan: 30 detik
- Mode: Normal atau Agresif sesuai preferensi

Gunakan GPU Saver jika CPU tinggi
    ]]
})

-- ====== NOTIFIKASI STARTUP ======
Rayfield:Notify({
    Title = "Auto Fish Dimuat",
    Content = "Dibuat oleh Denmas Developer | Ready to fish!",
    Duration = 5,
    Image = 4483362458
})

print("[Auto Fish] Script berhasil dimuat")
print("[Auto Fish] Dibuat oleh: Denmas Developer")
print("[Auto Fish] Versi: 4.0 (Clean & Optimized)")
