-------------------------------------------
----- =======[ INITIALIZATION ] =======
-------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- Global Services
local net = ReplicatedStorage:WaitForChild("Packages")
	:WaitForChild("_Index")
	:WaitForChild("sleitnick_net@0.2.0")
	:WaitForChild("net")

local state = {
	AutoFish = false,
	AutoSell = false,
	AntiAFK = true
}

-- Remotes
local rodRemote = net:WaitForChild("RF/ChargeFishingRod")
local miniGameRemote = net:WaitForChild("RF/RequestFishingMinigameStarted")
local finishRemote = net:WaitForChild("RE/FishingCompleted")

-------------------------------------------
----- =======[ MODERN UI ] =======
-------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DennHubUI"
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

--// Main Window
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Size = UDim2.new(0, 550, 0, 450)
MainFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.BackgroundTransparency = 0.05

local Shadow = Instance.new("UICorner", MainFrame)
Shadow.CornerRadius = UDim.new(0, 10)

local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(90, 90, 90)
UIStroke.Thickness = 1

--// Title Bar with Close Button
local TitleBar = Instance.new("Frame")
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BorderSizePixel = 0

local TitleCorner = Instance.new("UICorner", TitleBar)
TitleCorner.CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Parent = TitleBar
Title.Text = "🎣 DennHub - Fish It"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TitleBar
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -50, 0, 5)
local CloseCorner = Instance.new("UICorner", CloseBtn)
CloseCorner.CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function()
	ScreenGui:Destroy()
end)

--// Tabs Bar
local Tabs = Instance.new("Frame")
Tabs.Parent = MainFrame
Tabs.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Tabs.Size = UDim2.new(0, 140, 1, -50)
Tabs.Position = UDim2.new(0, 0, 0, 50)
Tabs.BorderSizePixel = 0

local TabsCorner = Instance.new("UICorner", Tabs)
TabsCorner.CornerRadius = UDim.new(0, 0)

local TabList = Instance.new("UIListLayout", Tabs)
TabList.Padding = UDim.new(0, 4)
TabList.FillDirection = Enum.FillDirection.Vertical

local selectedTab = nil

--// Function to create tab button
local function CreateTabButton(name)
    local btn = Instance.new("TextButton")
    btn.Parent = Tabs
    btn.Text = name
    btn.Size = UDim2.new(1, -8, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 6)
    
    btn.MouseEnter:Connect(function()
        if btn ~= selectedTab then
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        end
    end)
    
    btn.MouseLeave:Connect(function()
        if btn ~= selectedTab then
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end
    end)
    
    return btn
end

local TabAutoFishing = CreateTabButton("🎣 Auto Fishing")
local TabUtility = CreateTabButton("🗺️ Utility")
local TabSettings = CreateTabButton("⚙️ Settings")

--// Pages Container
local Pages = Instance.new("Frame")
Pages.Parent = MainFrame
Pages.Size = UDim2.new(1, -150, 1, -50)
Pages.Position = UDim2.new(0, 150, 0, 50)
Pages.BackgroundTransparency = 1

--// Function to create page
local function CreatePage()
    local page = Instance.new("ScrollingFrame")
    page.Parent = Pages
    page.Size = UDim2.new(1, 0, 1, 0)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.ScrollBarThickness = 5
    page.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    page.BorderSizePixel = 0
    
    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.FillDirection = Enum.FillDirection.Vertical
    
    layout.Changed:Connect(function(prop)
        if prop == "AbsoluteContentSize" then
            page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
        end
    end)
    
    return page
end

local PageAutoFishing = CreatePage()
local PageUtility = CreatePage()
local PageSettings = CreatePage()

PageUtility.Visible = false
PageSettings.Visible = false

--// Switch tab function
local function SwitchTab(page, tabBtn)
    PageAutoFishing.Visible = false
    PageUtility.Visible = false
    PageSettings.Visible = false
    page.Visible = true
    
    -- Reset all tabs
    TabAutoFishing.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    TabUtility.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    TabSettings.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    
    -- Highlight selected tab
    tabBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    selectedTab = tabBtn
end

TabAutoFishing.MouseButton1Click:Connect(function() SwitchTab(PageAutoFishing, TabAutoFishing) end)
TabUtility.MouseButton1Click:Connect(function() SwitchTab(PageUtility, TabUtility) end)
TabSettings.MouseButton1Click:Connect(function() SwitchTab(PageSettings, TabSettings) end)

--// FUNCTION: create toggle
local function CreateToggle(parent, text, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1, -20, 0, 45)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    frame.BorderSizePixel = 0

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextColor3 = Color3.fromRGB(230, 230, 230)
    label.TextSize = 14
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Parent = frame
    toggleBtn.Text = "OFF"
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 13
    toggleBtn.Size = UDim2.new(0, 55, 0, 28)
    toggleBtn.Position = UDim2.new(1, -65, 0.15, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.BorderSizePixel = 0
    local c = Instance.new("UICorner", toggleBtn)
    c.CornerRadius = UDim.new(0, 5)

    local state = false

    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        toggleBtn.Text = state and "ON" or "OFF"
        toggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(100, 0, 0)
        callback(state)
    end)
    
    return toggleBtn
end

--// FUNCTION: create button
local function CreateButton(parent, text, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(40, 100, 200)
    frame.BorderSizePixel = 0

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 6)

    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)

    btn.MouseButton1Click:Connect(callback)
    btn.MouseEnter:Connect(function()
        frame.BackgroundColor3 = Color3.fromRGB(50, 120, 220)
    end)
    btn.MouseLeave:Connect(function()
        frame.BackgroundColor3 = Color3.fromRGB(40, 100, 200)
    end)
end

--// FUNCTION: create label
local function CreateLabel(parent, title, content)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1, -20, 0, auto)
    frame.BackgroundTransparency = 1

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = frame
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 13
    titleLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, 0, 0, 20)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local contentLabel = Instance.new("TextLabel")
    contentLabel.Parent = frame
    contentLabel.Text = content
    contentLabel.Font = Enum.Font.Gotham
    contentLabel.TextSize = 12
    contentLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    contentLabel.BackgroundTransparency = 1
    contentLabel.Position = UDim2.new(0, 0, 0, 22)
    contentLabel.Size = UDim2.new(1, 0, 0, 40)
    contentLabel.TextWrapped = true
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
end

--// FUNCTION: create dropdown
local function CreateDropdown(parent, title, options, callback)
    local selectedValue = options[1]
    
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1, -20, 0, 45)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    frame.BorderSizePixel = 0

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Text = title
    label.Font = Enum.Font.Gotham
    label.TextColor3 = Color3.fromRGB(230, 230, 230)
    label.TextSize = 13
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(0.6, 0, 0.5, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left

    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Parent = frame
    dropdownBtn.Text = selectedValue
    dropdownBtn.Font = Enum.Font.Gotham
    dropdownBtn.TextSize = 12
    dropdownBtn.Size = UDim2.new(0, 100, 0, 28)
    dropdownBtn.Position = UDim2.new(1, -110, 0.15, 0)
    dropdownBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    dropdownBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    dropdownBtn.BorderSizePixel = 0
    local dc = Instance.new("UICorner", dropdownBtn)
    dc.CornerRadius = UDim.new(0, 5)

    local isOpen = false
    local dropList = nil

    dropdownBtn.MouseButton1Click:Connect(function()
        if isOpen then
            dropList:Destroy()
            isOpen = false
        else
            dropList = Instance.new("Frame")
            dropList.Parent = dropdownBtn
            dropList.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            dropList.Size = UDim2.new(1, 0, 0, #options * 25)
            dropList.Position = UDim2.new(0, 0, 1, 2)
            dropList.BorderSizePixel = 0
            local dlc = Instance.new("UICorner", dropList)
            dlc.CornerRadius = UDim.new(0, 4)

            local dlLayout = Instance.new("UIListLayout", dropList)
            dlLayout.Padding = UDim.new(0, 2)

            for _, option in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Parent = dropList
                optBtn.Text = option
                optBtn.Font = Enum.Font.Gotham
                optBtn.TextSize = 11
                optBtn.Size = UDim2.new(1, -4, 0, 22)
                optBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                optBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
                optBtn.BorderSizePixel = 0
                local oc = Instance.new("UICorner", optBtn)
                oc.CornerRadius = UDim.new(0, 3)

                optBtn.MouseButton1Click:Connect(function()
                    selectedValue = option
                    dropdownBtn.Text = selectedValue
                    callback(selectedValue)
                    dropList:Destroy()
                    isOpen = false
                end)
            end

            isOpen = true
        end
    end)
end

-------------------------------------------
----- =======[ AUTO FISHING SYSTEM ] =======
-------------------------------------------

local RodDelays = {
    ["Ares Rod"] = {custom = 1.12, bypass = 1.45},
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

local customDelay = 1
local BypassDelay = 0.5
local PerfectCast = true
local FishingActive = false

local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

-- Load animations
local RodIdle = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("FishingRodReelIdle")
local RodReel = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("EasyFishReelStart")
local RodShake = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("CastFromFullChargePosition1Hand")

local RodShakeAnim = animator:LoadAnimation(RodShake)
local RodIdleAnim = animator:LoadAnimation(RodIdle)
local RodReelAnim = animator:LoadAnimation(RodReel)

local function getValidRodName()
    local player = Players.LocalPlayer
    local display = player.PlayerGui:WaitForChild("Backpack"):WaitForChild("Display")
    for _, tile in ipairs(display:GetChildren()) do
        local success, itemNamePath = pcall(function()
            return tile.Inner.Tags.ItemName
        end)
        if success and itemNamePath and itemNamePath:IsA("TextLabel") then
            local name = itemNamePath.Text
            if RodDelays[name] then
                return name
            end
        end
    end
    return nil
end

local function updateDelayBasedOnRod()
    local rodName = getValidRodName()
    if rodName and RodDelays[rodName] then
        customDelay = RodDelays[rodName].custom
        BypassDelay = RodDelays[rodName].bypass
    end
end

local REReplicateTextEffect = net:WaitForChild("RE/ReplicateTextEffect")

REReplicateTextEffect.OnClientEvent:Connect(function(data)
    if state.AutoFish and FishingActive
    and data
    and data.TextData
    and data.TextData.EffectType == "Exclaim" then

        local myHead = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Head")
        if myHead and data.Container == myHead then
            task.spawn(function()
                for i = 1, 3 do
                    task.wait(BypassDelay)
                    finishRemote:FireServer()
                end
            end)
        end
    end
end)

function StartAutoFish()
    if state.AutoFish then return end
    
    state.AutoFish = true
    updateDelayBasedOnRod()
    
    task.spawn(function()
        while state.AutoFish do
            pcall(function()
                FishingActive = true

                local equipRemote = net:WaitForChild("RE/EquipToolFromHotbar")
                equipRemote:FireServer(1)
                task.wait(0.1)

                local chargeRemote = ReplicatedStorage
                    .Packages._Index["sleitnick_net@0.2.0"].net["RF/ChargeFishingRod"]
                chargeRemote:InvokeServer(workspace:GetServerTimeNow())
                task.wait(0.5)

                local timestamp = workspace:GetServerTimeNow()
                RodShakeAnim:Play()
                rodRemote:InvokeServer(timestamp)

                local baseX, baseY = -0.7499996423721313, 1
                local x, y
                if PerfectCast then
                    x = baseX + (math.random(-500, 500) / 10000000)
                    y = baseY + (math.random(-500, 500) / 10000000)
                else
                    x = math.random(-1000, 1000) / 1000
                    y = math.random(0, 1000) / 1000
                end

                RodIdleAnim:Play()
                miniGameRemote:InvokeServer(x, y)

                task.wait(customDelay)
                FishingActive = false
            end)
        end
    end)
end

function StopAutoFish()
    state.AutoFish = false
    FishingActive = false
    pcall(function()
        RodIdleAnim:Stop()
        RodShakeAnim:Stop()
        RodReelAnim:Stop()
    end)
end

-------------------------------------------
----- =======[ TELEPORT SYSTEM ] =======
-------------------------------------------

local islandCoords = {
    ["Weather Machine"] = Vector3.new(-1471, -3, 1929),
    ["Esoteric Depths"] = Vector3.new(3157, -1303, 1439),
    ["Tropical Grove"] = Vector3.new(-2038, 3, 3650),
    ["Stingray Shores"] = Vector3.new(-32, 4, 2773),
    ["Kohana Volcano"] = Vector3.new(-519, 24, 189),
    ["Coral Reefs"] = Vector3.new(-3095, 1, 2177),
    ["Crater Island"] = Vector3.new(968, 1, 4854),
    ["Kohana"] = Vector3.new(-658, 3, 719),
    ["Winter Fest"] = Vector3.new(1611, 4, 3280),
    ["Isoteric Island"] = Vector3.new(1987, 4, 1400),
    ["Treasure Hall"] = Vector3.new(-3600, -267, -1558),
    ["Lost Shore"] = Vector3.new(-3663, 38, -989),
    ["Sishypus Statue"] = Vector3.new(-3792, -135, -986)
}

local function TeleportToIsland(islandName)
    pcall(function()
        local position = islandCoords[islandName]
        if not position then return end
        
        local charFolder = workspace:WaitForChild("Characters", 5)
        local char = charFolder:FindFirstChild(LocalPlayer.Name)
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
        end
    end)
end

-------------------------------------------
----- =======[ PAGE CONTENT ] =======
-------------------------------------------

-- Auto Fishing Section
CreateLabel(PageAutoFishing, "🎣 Auto Fishing Controls", "Advanced automated fishing system")
CreateToggle(PageAutoFishing, "Auto Fish V2", function(value)
    if value then
        StartAutoFish()
    else
        StopAutoFish()
    end
end)

CreateToggle(PageAutoFishing, "Perfect Cast", function(value)
    PerfectCast = value
end)

CreateButton(PageAutoFishing, "Stop All Fishing", function()
    StopAutoFish()
end)

-- Utility Section
CreateLabel(PageUtility, "🗺️ Island Teleport", "Quick travel between islands")

local islandNames = {}
for name, _ in pairs(islandCoords) do
    table.insert(islandNames, name)
end
table.sort(islandNames)

CreateDropdown(PageUtility, "Select Island", islandNames, function(island)
    TeleportToIsland(island)
end)

CreateButton(PageUtility, "Rejoin Server", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

CreateButton(PageUtility, "Server Hop", function()
    pcall(function()
        local placeId = game.PlaceId
        local servers = {}
        local cursor = ""

        repeat
            local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
            if cursor ~= "" then
                url = url .. "&cursor=" .. cursor
            end

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
            local targetServer = servers[math.random(1, #servers)]
            TeleportService:TeleportToPlaceInstance(placeId, targetServer, LocalPlayer)
        end
    end)
end)

-- Settings Section
CreateLabel(PageSettings, "⚙️ Script Settings", "Configure your experience")

CreateToggle(PageSettings, "Anti AFK", function(value)
    state.AntiAFK = value
    if value then
        for i,v in next, getconnections(LocalPlayer.Idled) do
            v:Disable()
        end
    end
end)

CreateLabel(PageSettings, "📊 Script Info", "Version: 2.0 | Developer: @denmas._")

-- Initialize first tab
SwitchTab(PageAutoFishing, TabAutoFishing)

print("✅ DennHub - Fish It v2.0 Loaded Successfully!")
