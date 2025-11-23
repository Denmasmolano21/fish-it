-------------------------------------------
----- INITIALIZATION
-------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

if not LocalPlayer then
    warn("[DennHub] Script must be executed as LocalScript")
    return
end

-- Load net services
local net
local netSuccess = pcall(function()
    net = ReplicatedStorage:WaitForChild("Packages", 5)
        :WaitForChild("_Index", 5)
        :WaitForChild("sleitnick_net@0.2.0", 5)
        :WaitForChild("net", 5)
end)

if not netSuccess or not net then
    warn("[DennHub] Failed to load net remotes")
    return
end

local state = {
    AutoFish = false,
    AutoSell = false,
    AntiAFK = true
}

-- Cache remotes
local rodRemote = net:FindFirstChild("RF/ChargeFishingRod")
local miniGameRemote = net:FindFirstChild("RF/RequestFishingMinigameStarted")
local finishRemote = net:FindFirstChild("RE/FishingCompleted")

-------------------------------------------
----- CREATE GUI
-------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DennHubUI"
ScreenGui.DisplayOrder = 999
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5)

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 23, 30)
MainFrame.Size = UDim2.new(0, 650, 0, 480)
MainFrame.Position = UDim2.new(0.5, -325, 0.5, -240)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true

local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(60, 65, 80)
MainStroke.Thickness = 1

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 28, 35)
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 2

local TitleCorner = Instance.new("UICorner", TitleBar)
TitleCorner.CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Parent = TitleBar
Title.Text = "DennHub | Fish It v2.1"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, -120, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 2

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TitleBar
CloseBtn.Text = "×"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 24
CloseBtn.BackgroundColor3 = Color3.fromRGB(240, 80, 80)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -45, 0, 5)
CloseBtn.BorderSizePixel = 0
CloseBtn.ZIndex = 3

local CloseCorner = Instance.new("UICorner", CloseBtn)
CloseCorner.CornerRadius = UDim.new(0, 8)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Sidebar (Tabs Container)
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Parent = MainFrame
Sidebar.BackgroundColor3 = Color3.fromRGB(25, 28, 35)
Sidebar.Size = UDim2.new(0, 160, 1, -50)
Sidebar.Position = UDim2.new(0, 0, 0, 50)
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 1

local SidebarList = Instance.new("UIListLayout", Sidebar)
SidebarList.Padding = UDim.new(0, 5)
SidebarList.FillDirection = Enum.FillDirection.Vertical
SidebarList.HorizontalAlignment = Enum.HorizontalAlignment.Center

local SidebarPadding = Instance.new("UIPadding", Sidebar)
SidebarPadding.PaddingTop = UDim.new(0, 10)

-- Content Container
local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Parent = MainFrame
ContentContainer.BackgroundColor3 = Color3.fromRGB(20, 23, 30)
ContentContainer.Size = UDim2.new(1, -160, 1, -50)
ContentContainer.Position = UDim2.new(0, 160, 0, 50)
ContentContainer.BorderSizePixel = 0
ContentContainer.ClipsDescendants = true
ContentContainer.ZIndex = 1

-------------------------------------------
----- UI COMPONENT CREATORS
-------------------------------------------

local function CreateToggle(parent, text, defaultState, callback)
    local frame = Instance.new("Frame")
    frame.Name = "Toggle"
    frame.Parent = parent
    frame.Size = UDim2.new(1, -30, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(30, 33, 40)
    frame.BorderSizePixel = 0

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 14
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 15, 0, 0)
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left

    local toggleFrame = Instance.new("Frame")
    toggleFrame.Parent = frame
    toggleFrame.BackgroundColor3 = Color3.fromRGB(40, 43, 50)
    toggleFrame.Size = UDim2.new(0, 60, 0, 30)
    toggleFrame.Position = UDim2.new(1, -70, 0.5, -15)
    toggleFrame.BorderSizePixel = 0
    
    local tc = Instance.new("UICorner", toggleFrame)
    tc.CornerRadius = UDim.new(1, 0)

    local toggleBtn = Instance.new("Frame")
    toggleBtn.Parent = toggleFrame
    toggleBtn.BackgroundColor3 = defaultState and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(200, 60, 60)
    toggleBtn.Size = UDim2.new(0, 24, 0, 24)
    toggleBtn.Position = defaultState and UDim2.new(1, -27, 0.5, -12) or UDim2.new(0, 3, 0.5, -12)
    toggleBtn.BorderSizePixel = 0
    
    local tbc = Instance.new("UICorner", toggleBtn)
    tbc.CornerRadius = UDim.new(1, 0)

    local clickDetector = Instance.new("TextButton")
    clickDetector.Parent = toggleFrame
    clickDetector.Size = UDim2.new(1, 0, 1, 0)
    clickDetector.BackgroundTransparency = 1
    clickDetector.Text = ""

    local toggleState = defaultState or false

    clickDetector.MouseButton1Click:Connect(function()
        toggleState = not toggleState
        if toggleState then
            toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
            toggleBtn:TweenPosition(UDim2.new(1, -27, 0.5, -12), "Out", "Quad", 0.2, true)
        else
            toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
            toggleBtn:TweenPosition(UDim2.new(0, 3, 0.5, -12), "Out", "Quad", 0.2, true)
        end
        callback(toggleState)
    end)
    
    return frame
end

local function CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Name = "Button"
    btn.Parent = parent
    btn.Text = text
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.Size = UDim2.new(1, -30, 0, 45)
    btn.BackgroundColor3 = Color3.fromRGB(50, 120, 220)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BorderSizePixel = 0

    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(callback)
    
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(60, 140, 240)
    end)
    
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(50, 120, 220)
    end)
    
    return btn
end

local function CreateLabel(parent, title, content)
    local frame = Instance.new("Frame")
    frame.Name = "Label"
    frame.Parent = parent
    frame.Size = UDim2.new(1, -30, 0, 65)
    frame.BackgroundColor3 = Color3.fromRGB(30, 33, 40)
    frame.BorderSizePixel = 0

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = frame
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 15
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, -20, 0, 22)
    titleLabel.Position = UDim2.new(0, 10, 0, 8)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local contentLabel = Instance.new("TextLabel")
    contentLabel.Parent = frame
    contentLabel.Text = content
    contentLabel.Font = Enum.Font.Gotham
    contentLabel.TextSize = 12
    contentLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
    contentLabel.BackgroundTransparency = 1
    contentLabel.Position = UDim2.new(0, 10, 0, 30)
    contentLabel.Size = UDim2.new(1, -20, 0, 28)
    contentLabel.TextWrapped = true
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
    contentLabel.TextYAlignment = Enum.TextYAlignment.Top
    
    return frame
end

local function CreateDropdown(parent, title, options, callback)
    local selectedValue = options[1]
    
    local frame = Instance.new("Frame")
    frame.Name = "Dropdown"
    frame.Parent = parent
    frame.Size = UDim2.new(1, -30, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(30, 33, 40)
    frame.BorderSizePixel = 0

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Text = title
    label.Font = Enum.Font.Gotham
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 14
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 15, 0, 0)
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left

    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Parent = frame
    dropdownBtn.Text = selectedValue
    dropdownBtn.Font = Enum.Font.Gotham
    dropdownBtn.TextSize = 13
    dropdownBtn.Size = UDim2.new(0, 200, 0, 35)
    dropdownBtn.Position = UDim2.new(1, -210, 0.5, -17.5)
    dropdownBtn.BackgroundColor3 = Color3.fromRGB(40, 43, 50)
    dropdownBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    dropdownBtn.BorderSizePixel = 0
    
    local dc = Instance.new("UICorner", dropdownBtn)
    dc.CornerRadius = UDim.new(0, 6)

    local isOpen = false
    local dropList = nil

    dropdownBtn.MouseButton1Click:Connect(function()
        if isOpen and dropList then
            dropList:Destroy()
            isOpen = false
        else
            dropList = Instance.new("Frame")
            dropList.Parent = dropdownBtn
            dropList.BackgroundColor3 = Color3.fromRGB(35, 38, 45)
            dropList.Size = UDim2.new(1, 0, 0, math.min(#options * 30, 150))
            dropList.Position = UDim2.new(0, 0, 1, 2)
            dropList.BorderSizePixel = 0
            dropList.ZIndex = 10
            
            local dlc = Instance.new("UICorner", dropList)
            dlc.CornerRadius = UDim.new(0, 6)

            local dlScroll = Instance.new("ScrollingFrame", dropList)
            dlScroll.Size = UDim2.new(1, 0, 1, 0)
            dlScroll.BackgroundTransparency = 1
            dlScroll.ScrollBarThickness = 4
            dlScroll.ScrollBarImageColor3 = Color3.fromRGB(60, 65, 80)
            dlScroll.CanvasSize = UDim2.new(0, 0, 0, #options * 30)
            dlScroll.BorderSizePixel = 0

            local dlLayout = Instance.new("UIListLayout", dlScroll)
            dlLayout.Padding = UDim.new(0, 0)

            for _, option in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Parent = dlScroll
                optBtn.Text = option
                optBtn.Font = Enum.Font.Gotham
                optBtn.TextSize = 13
                optBtn.Size = UDim2.new(1, 0, 0, 30)
                optBtn.BackgroundColor3 = Color3.fromRGB(40, 43, 50)
                optBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
                optBtn.BorderSizePixel = 0
                optBtn.ZIndex = 11

                optBtn.MouseButton1Click:Connect(function()
                    selectedValue = option
                    dropdownBtn.Text = selectedValue
                    callback(selectedValue)
                    if dropList then
                        dropList:Destroy()
                    end
                    isOpen = false
                end)

                optBtn.MouseEnter:Connect(function()
                    optBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 220)
                end)

                optBtn.MouseLeave:Connect(function()
                    optBtn.BackgroundColor3 = Color3.fromRGB(40, 43, 50)
                end)
            end
            
            isOpen = true
        end
    end)
    
    return frame
end

-------------------------------------------
----- CREATE PAGES
-------------------------------------------

local Pages = {}

local function CreatePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Parent = ContentContainer
    page.Size = UDim2.new(1, 0, 1, 0)
    page.Position = UDim2.new(0, 0, 0, 0)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.ScrollBarThickness = 6
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarImageColor3 = Color3.fromRGB(60, 65, 80)
    page.Visible = false
    
    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 12)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 30)
    end)
    
    local padding = Instance.new("UIPadding", page)
    padding.PaddingLeft = UDim.new(0, 15)
    padding.PaddingRight = UDim.new(0, 15)
    padding.PaddingTop = UDim.new(0, 15)
    padding.PaddingBottom = UDim.new(0, 15)
    
    Pages[name] = page
    return page
end

-- Create all pages
local PageAutoFishing = CreatePage("AutoFishing")
local PageUtility = CreatePage("Utility")
local PageSettings = CreatePage("Settings")

-------------------------------------------
----- AUTO FISHING SYSTEM
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

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid", 5)
local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

local RodIdle, RodReel, RodShake
pcall(function()
    RodIdle = ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("Animations", 5):WaitForChild("FishingRodReelIdle", 5)
    RodReel = ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("Animations", 5):WaitForChild("EasyFishReelStart", 5)
    RodShake = ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("Animations", 5):WaitForChild("CastFromFullChargePosition1Hand", 5)
end)

local RodShakeAnim = RodShake and animator:LoadAnimation(RodShake)
local RodIdleAnim = RodIdle and animator:LoadAnimation(RodIdle)
local RodReelAnim = RodReel and animator:LoadAnimation(RodReel)

local function getValidRodName()
    local success, display = pcall(function()
        return LocalPlayer.PlayerGui:WaitForChild("Backpack"):WaitForChild("Display")
    end)
    
    if not success or not display then return nil end
    
    for _, tile in ipairs(display:GetChildren()) do
        local success2, itemNamePath = pcall(function()
            return tile.Inner.Tags.ItemName
        end)
        if success2 and itemNamePath and itemNamePath:IsA("TextLabel") then
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

        local myHead = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
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
    
    if not (rodRemote and miniGameRemote and finishRemote) then
        warn("[DennHub] Remotes not available")
        return
    end
    
    state.AutoFish = true
    updateDelayBasedOnRod()
    
    task.spawn(function()
        while state.AutoFish do
            local success = pcall(function()
                FishingActive = true

                local equipRemote = net:FindFirstChild("RE/EquipToolFromHotbar")
                if equipRemote then
                    equipRemote:FireServer(1)
                    task.wait(0.1)
                end

                local chargeRemote = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/ChargeFishingRod"]
                if chargeRemote then
                    chargeRemote:InvokeServer(workspace:GetServerTimeNow())
                    task.wait(0.5)
                end

                local timestamp = workspace:GetServerTimeNow()
                if RodShakeAnim then
                    RodShakeAnim:Play()
                end
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

                if RodIdleAnim then
                    RodIdleAnim:Play()
                end
                miniGameRemote:InvokeServer(x, y)

                task.wait(customDelay)
                FishingActive = false
            end)
            
            if not success then
                task.wait(1)
            end
        end
    end)
end

function StopAutoFish()
    state.AutoFish = false
    FishingActive = false
    pcall(function()
        if RodIdleAnim then RodIdleAnim:Stop() end
        if RodShakeAnim then RodShakeAnim:Stop() end
        if RodReelAnim then RodReelAnim:Stop() end
    end)
end

-------------------------------------------
----- TELEPORT SYSTEM
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
    if not islandCoords[islandName] then
        warn("[DennHub] Island not found: " .. tostring(islandName))
        return
    end
    
    pcall(function()
        local position = islandCoords[islandName]
        local charFolder = workspace:WaitForChild("Characters", 5)
        local char = charFolder and charFolder:FindFirstChild(LocalPlayer.Name)
        if not char then
            warn("[DennHub] Character not found in workspace")
            return
        end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
        end
    end)
end

-------------------------------------------
----- POPULATE PAGES WITH CONTENT
-------------------------------------------

-- AUTO FISHING PAGE
CreateLabel(PageAutoFishing, "Auto Fishing", "Automated fishing with perfect cast")
CreateToggle(PageAutoFishing, "Enable Auto Fish", false, function(value)
    if value then
        StartAutoFish()
    else
        StopAutoFish()
    end
end)
CreateToggle(PageAutoFishing, "Perfect Cast", true, function(value)
    PerfectCast = value
end)
CreateButton(PageAutoFishing, "Stop Fishing", function()
    StopAutoFish()
end)

-- UTILITY PAGE
CreateLabel(PageUtility, "Teleportation", "Travel to different islands")

local islandNames = {}
for name, _ in pairs(islandCoords) do
    table.insert(islandNames, name)
end
table.sort(islandNames)

CreateDropdown(PageUtility, "Select Island", islandNames, function(island)
    TeleportToIsland(island)
end)

CreateLabel(PageUtility, "Server Management", "Manage your connection")

CreateButton(PageUtility, "Rejoin Server", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

CreateButton(PageUtility, "Server Hop", function()
    task.spawn(function()
        pcall(function()
            local placeId = game.PlaceId
            local servers = {}
            local cursor = ""
            local attempts = 0

            repeat
                if attempts >= 3 then break end
                attempts = attempts + 1
                
                local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
                if cursor ~= "" then
                    url = url .. "&cursor=" .. cursor
                end

                local success, result = pcall(function()
                    return HttpService:JSONDecode(game:HttpGet(url))
                end)

                if success and result and result.data then
                    for _, server in pairs(result.data) do
                        if server.playing and server.maxPlayers then
                            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                                table.insert(servers, server.id)
                            end
                        end
                    end
                    cursor = result.nextPageCursor or ""
                else
                    cursor = ""
                end
                
                task.wait(0.5)
            until not cursor or #servers > 0

            if #servers > 0 then
                local targetServer = servers[math.random(1, #servers)]
                TeleportService:TeleportToPlaceInstance(placeId, targetServer, LocalPlayer)
            end
        end)
    end)
end)

-- SETTINGS PAGE
CreateLabel(PageSettings, "General Settings", "Configure preferences")
CreateToggle(PageSettings, "Anti-AFK", true, function(value)
    state.AntiAFK = value
    if value then
        local connections = getconnections(LocalPlayer.Idled)
        if connections and #connections > 0 then
            for _, connection in ipairs(connections) do
                if connection and connection.Connected then
                    pcall(function()
                        connection:Disable()
                    end)
                end
            end
        end
    end
end)
CreateLabel(PageSettings, "About", "DennHub Fish It v2.1 | @denmas._")

-------------------------------------------
----- TAB BUTTONS & SWITCHING
-------------------------------------------

local selectedTab = nil

local function CreateTabButton(name, icon, page)
    local btn = Instance.new("TextButton")
    btn.Name = "Tab_" .. name
    btn.Parent = Sidebar
    btn.Text = icon .. " " .. name
    btn.Size = UDim2.new(1, -16, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(30, 33, 40)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 8)
    
    btn.MouseButton1Click:Connect(function()
        -- Hide all pages
        for _, p in pairs(Pages) do
            p.Visible = false
        end
        
        -- Reset all tab colors
        for _, tab in pairs(Sidebar:GetChildren()) do
            if tab:IsA("TextButton") then
                tab.BackgroundColor3 = Color3.fromRGB(30, 33, 40)
                tab.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
        end
        
        -- Show selected page
        page.Visible = true
        
        -- Highlight selected tab
        btn.BackgroundColor3 = Color3.fromRGB(50, 120, 220)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        selectedTab = btn
    end)
    
    return btn
end

-- Create tab buttons
local TabAutoFishing = CreateTabButton("Auto Fishing", "⚙", PageAutoFishing)
local TabUtility = CreateTabButton("Utility", "🔧", PageUtility)
local TabSettings = CreateTabButton("Settings", "⚡", PageSettings)

-------------------------------------------
----- INITIALIZATION
-------------------------------------------

local cleanup = function()
    StopAutoFish()
    if ScreenGui then
        ScreenGui:Destroy()
    end
end

game:BindToClose(cleanup)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    StopAutoFish()
end)

-- Show first tab by default
task.wait(0.1)
PageAutoFishing.Visible = true
TabAutoFishing.BackgroundColor3 = Color3.fromRGB(50, 120, 220)
TabAutoFishing.TextColor3 = Color3.fromRGB(255, 255, 255)
selectedTab = TabAutoFishing

print("[DennHub] Fish It v2.1 Loaded Successfully!")