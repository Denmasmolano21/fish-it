--================================================--
--   DENNMAS LITE UI (Tanpa WindUI / Tanpa Library)
--================================================--

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

-- KEYBIND BUKA/TUTUP UI
local toggleKey = Enum.KeyCode.G

-- STATE
local autoFish = false
local autoSell = false

--================================================--
--  UI CREATOR (GUI SEDERHANA)
--================================================--

local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local AutoFishBtn = Instance.new("TextButton")
local AutoSellBtn = Instance.new("TextButton")

ScreenGui.Parent = player:WaitForChild("PlayerGui")

Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderSizePixel = 0
Frame.Position = UDim2.new(0.35, 0, 0.25, 0)
Frame.Size = UDim2.new(0, 300, 0, 180)
Frame.Visible = true

Title.Parent = Frame
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "DennHub - Simple UI"
Title.TextColor3 = Color3.fromRGB(200, 150, 255)
Title.TextSize = 20

AutoFishBtn.Parent = Frame
AutoFishBtn.Position = UDim2.new(0, 20, 0, 50)
AutoFishBtn.Size = UDim2.new(0, 260, 0, 40)
AutoFishBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
AutoFishBtn.TextColor3 = Color3.fromRGB(255,255,255)
AutoFishBtn.Text = "Auto Fish: OFF"
AutoFishBtn.TextSize = 18

AutoSellBtn.Parent = Frame
AutoSellBtn.Position = UDim2.new(0, 20, 0, 105)
AutoSellBtn.Size = UDim2.new(0, 260, 0, 40)
AutoSellBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
AutoSellBtn.TextColor3 = Color3.fromRGB(255,255,255)
AutoSellBtn.Text = "Auto Sell: OFF"
AutoSellBtn.TextSize = 18

--================================================--
--   AUTO FISH SEDERHANA
--================================================--

local RS = game:GetService("ReplicatedStorage")
local net = RS:WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

local rod = net["RF/ChargeFishingRod"]
local mini = net["RF/RequestFishingMinigameStarted"]
local finish = net["RE/FishingCompleted"]

local function doAutoFish()
    while autoFish do
        pcall(function()
            local t = workspace:GetServerTimeNow()
            rod:InvokeServer(t)
            mini:InvokeServer(-0.74999, 1)
            task.wait(1.4)
            finish:FireServer()
        end)
        task.wait()
    end
end

--================================================--
--   AUTO SELL SEDERHANA
--================================================--

local function doAutoSell()
    while autoSell do
        pcall(function()
            local sell = net:FindFirstChild("RF/SellAllItems")
            if sell then sell:InvokeServer() end
        end)
        task.wait(30)
    end
end

--================================================--
--   BUTTON CALLBACK
--================================================--

AutoFishBtn.MouseButton1Click:Connect(function()
    autoFish = not autoFish
    AutoFishBtn.Text = "Auto Fish: " .. (autoFish and "ON" or "OFF")
    if autoFish then task.spawn(doAutoFish) end
end)

AutoSellBtn.MouseButton1Click:Connect(function()
    autoSell = not autoSell
    AutoSellBtn.Text = "Auto Sell: " .. (autoSell and "ON" or "OFF")
    if autoSell then task.spawn(doAutoSell) end
end)

--================================================--
--  TOGGLE UI DENGAN TOMBOL 'G'
--================================================--

mouse.KeyDown:Connect(function(key)
    if key:lower() == toggleKey.Name:lower() then
        Frame.Visible = not Frame.Visible
    end
end)

--================================================--
print("DennHub Simple UI Loaded")
