--===============================--
--        DENNHUB – FISH IT      --
--        LITE VERSION          --
--      Optimized for DELTA      --
--===============================--

-- WindUI RAW (Delta Compatible)
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/FootageSUS/WindUI/main/main.lua"
))()

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local net = RS.Packages._Index["sleitnick_net@0.2.0"].net

local rodRemote      = net["RF/ChargeFishingRod"]
local miniGameRemote = net["RF/RequestFishingMinigameStarted"]
local finishRemote   = net["RE/FishingCompleted"]

local state = { AutoSell = false, AutoFav = false }
local HttpService = game:GetService("HttpService")

--===============--
--  BASIC NOTIFY --
--===============--

local function Notify(t, msg, ico)
    WindUI:Notify({
        Title = t,
        Content = msg,
        Icon = ico or "circle-check",
        Duration = 3
    })
end

--===============--
--   ANTI-AFK     --
--===============--

task.spawn(function()
    local vu = game:GetService("VirtualUser")
    LP.Idled:Connect(function()
        vu:Button2Down(Vector2.new(), workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(), workspace.CurrentCamera.CFrame)
    end)
end)

--===============--
--   BOOST FPS    --
--===============--

for _,v in ipairs(game:GetDescendants()) do
    if v:IsA("BasePart") then
        v.Material = Enum.Material.SmoothPlastic
        v.Reflectance = 0
    elseif v:IsA("Decal") or v:IsA("Texture") then
        v.Transparency = 1
    end
end
settings().Rendering.QualityLevel = "Level01"

--===============--
--   MAIN WINDOW  --
--===============--

local Window = WindUI:CreateWindow({
    Title = "DennHub - Lite",
    Icon = "fish",
    Size = UDim2.fromOffset(550,420),
    Theme = "Indigo"
})

Window:SetToggleKey(Enum.KeyCode.G)

local Tab = Window:Tab({ Title = "Auto Fishing", Icon = "fish" })
local Util = Window:Tab({ Title = "Utility", Icon = "settings" })
local Set  = Window:Tab({ Title = "Settings", Icon = "user-cog" })

--===============--
--   AUTO FISH V2 --
--===============--

local auto = {
    Enabled = false,
    Perfect = true,
    Delay = 1.45
}

local function AutoFishLoop()
    task.spawn(function()
        while auto.Enabled do
            pcall(function()
                local equip = net["RE/EquipToolFromHotbar"]
                equip:FireServer(1)
                task.wait(0.2)

                local now = workspace:GetServerTimeNow()
                rodRemote:InvokeServer(now)

                local x = auto.Perfect and -0.74999 or math.random(-1000,1000)/1000
                local y = auto.Perfect and 1 or math.random()

                miniGameRemote:InvokeServer(x,y)
                task.wait(auto.Delay)

                for _ = 1,2 do
                    finishRemote:FireServer()
                    task.wait(0.1)
                end
            end)
            task.wait()
        end
    end)
end

Tab:Toggle({
    Title = "Auto Fish V2",
    Content = "Stable auto fishing",
    Callback = function(v)
        auto.Enabled = v
        if v then AutoFishLoop() end
    end
})

Tab:Toggle({
    Title = "Perfect Cast",
    Content = "Always perfect",
    Value = true,
    Callback = function(v) auto.Perfect = v end
})

Tab:Input({
    Title = "Cast Delay",
    Placeholder = "Default: 1.45",
    Callback = function(v)
        auto.Delay = tonumber(v) or 1.45
        Notify("Delay Updated", auto.Delay.."s", "info")
    end
})

--===============--
--    AUTO SELL   --
--===============--

local lastSell = 0
Tab:Toggle({
    Title = "Auto Sell",
    Content = "Sell non-favorited items",
    Callback = function(v)
        state.AutoSell = v
        if not v then return end

        task.spawn(function()
            while state.AutoSell do
                pcall(function()
                    if os.time() - lastSell < 40 then return end

                    local sell = net:FindFirstChild("RF/SellAllItems")
                    if sell then
                        sell:InvokeServer()
                        lastSell = os.time()
                        Notify("Auto Sell", "Sold Items!", "circle-check")
                    end
                end)
                task.wait(15)
            end
        end)
    end
})

--===============--
--   AUTO FAVORITE
--===============--

local tiers = { Secret=true, Mythic=true, Legendary=true }

Tab:Toggle({
    Title = "Auto Favorite",
    Content = "Protect high-tier fish",
    Callback = function(v)
        state.AutoFav = v
        
        task.spawn(function()
            while state.AutoFav do
                pcall(function()
                    if not Replion or not ItemUtility then return end
                    local Data = Replion.Client:WaitReplion("Data")
                    local items = Data:Get({"Inventory","Items"})
                    for _,item in ipairs(items) do
                        local d = ItemUtility:GetItemData(item.Id)
                        if d and tiers[d.Data.Tier] then
                            item.Favorited = true
                        end
                    end
                end)
                task.wait(6)
            end
        end)
    end
})

--===============--
--  MANUAL SELL   --
--===============--

Tab:Button({
    Title = "Sell All",
    Content = "Manual sell",
    Callback = function()
        local s = net:FindFirstChild("RF/SellAllItems")
        if s then
            s:InvokeServer()
            Notify("Sell All", "Success", "circle-check")
        end
    end
})

--===============--
--   ENCHANT ROD  --
--===============--

Tab:Button({
    Title = "Auto Enchant",
    Content = "Teleport + enchant",
    Callback = function()
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local ENCHANT_POS = Vector3.new(3231, -1303, 1402)

        hrp.CFrame = CFrame.new(ENCHANT_POS + Vector3.new(0,5,0))
        task.wait(1)

        local act = net["RE/ActivateEnchantingAltar"]
        pcall(function()
            act:FireServer()
            task.wait(6)
            Notify("Enchant", "Success!")
        end)
    end
})

--===============--
--     UTILITY    --
--===============--

-- Rejoin
Util:Button({
    Title = "Rejoin",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId)
    end
})

-- Server Hop
Util:Button({
    Title = "Server Hop",
    Callback = function()
        local pid = game.PlaceId
        local servers = HttpService:JSONDecode(
            game:HttpGet("https://games.roblox.com/v1/games/"..pid.."/servers/Public?sortOrder=Asc&limit=100")
        )

        for _,s in ipairs(servers.data) do
            if s.playing < s.maxPlayers then
                game:GetService("TeleportService"):TeleportToPlaceInstance(pid, s.id, LP)
                return
            end
        end
        Notify("Server Hop", "No empty server!")
    end
})

--===============--
--    SETTINGS    --
--===============--

Set:Toggle({
    Title = "Anti AFK",
    Value = true
})

Set:Button({
    Title = "Clean UI",
    Callback = function()
        Notify("Info", "Lite Version Active", "info")
    end
})

Notify("DennHub Lite", "Loaded Successfully!", "circle-check")
