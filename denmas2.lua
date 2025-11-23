-------------------------------------------
----- =======[ INITIALIZATION ] =======
-------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

-- Verify script environment
if not LocalPlayer then
    warn("[DennHub] Script must be executed as LocalScript")
    return
end

-- Global Services with timeout protection
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

-- Cache remotes with FindFirstChild fallback
local rodRemote = net:FindFirstChild("RF/ChargeFishingRod")
local miniGameRemote = net:FindFirstChild("RF/RequestFishingMinigameStarted")
local finishRemote = net:FindFirstChild("RE/FishingCompleted")

-------------------------------------------
----- =======[ MODERN UI ] =======
-------------------------------------------

-- Create ScreenGui with proper setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DennHubUI"
ScreenGui.DisplayOrder = 999
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5)

if not ScreenGui.Parent then
    warn("[DennHub] Failed to create ScreenGui")
    return
end

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
Title.Text = "Denmas Developer | Fish It"
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
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -50, 0, 5)
CloseBtn.BorderSizePixel = 0
local CloseCorner = Instance.new("UICorner", CloseBtn)
CloseCorner.CornerRadius = UDim.new(0, 6)

-- Add hover effect to close button
CloseBtn.MouseEnter:Connect(function()
    CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
end)
CloseBtn.MouseLeave:Connect(function()
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
end)

CloseBtn.MouseButton1Click:Connect(function()
    if ScreenGui then
        ScreenGui:Destroy()
    end
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

local TabAutoFishing = CreateTabButton("Auto Fishing")
local TabUtility = CreateTabButton("Utility")
local TabSettings = CreateTabButton("Settings")

--// Pages Container
local Pages = Instance.new("Frame")
Pages.Parent = MainFrame
Pages.Size = UDim2.new(1, -150, 1, -50)
Pages.Position = UDim2.new(0, 150, 0, 50)
Pages.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
Pages.BorderSizePixel = 0
Pages.ClipsDescendants = true

local PagesCorner = Instance.new("UICorner", Pages)
PagesCorner.CornerRadius = UDim.new(0, 8)

--// Function to create page
local function CreatePage()
    local page = Instance.new("ScrollingFrame")
    page.Parent = Pages
    page.Size = UDim2.new(1, 0, 1, 0)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.ScrollBarThickness = 6
    page.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    page.BorderSizePixel = 0
    page.TopImage = ""
    page.BottomImage = ""
    page.MidImage = ""
    
    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 12)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.FillDirection = Enum.FillDirection.Vertical
    
    layout.Changed:Connect(function(prop)
        if prop == "AbsoluteContentSize" then
            page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end
    end)
    
    local padding = Instance.new("UIPadding", page)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.PaddingTop = UDim.new(0, 12)
    padding.PaddingBottom = UDim.new(0, 12)
    
    return page
end

local PageAutoFishing = CreatePage()
local PageUtility = CreatePage()
local PageSettings = CreatePage()

-- Make sure first page is visible by default
PageAutoFishing.Visible = true
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
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = frame.Parent:FindFirstChildOfClass("UIListLayout") and (frame.Parent:FindFirstChildOfClass("UIListLayout").AbsoluteContentSize.Y / 50 + 1) or 1

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextColor3 = Color3.fromRGB(235, 235, 235)
    label.TextSize = 15
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 14, 0, 0)
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left

    local toggleFrame = Instance.new("Frame")
    toggleFrame.Parent = frame
    toggleFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toggleFrame.Size = UDim2.new(0, 60, 0, 30)
    toggleFrame.Position = UDim2.new(1, -74, 0.1, 0)
    toggleFrame.BorderSizePixel = 0
    local tc = Instance.new("UICorner", toggleFrame)
    tc.CornerRadius = UDim.new(0, 15)

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Parent = toggleFrame
    toggleBtn.Text = ""
    toggleBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    toggleBtn.Size = UDim2.new(0, 26, 0, 26)
    toggleBtn.Position = UDim2.new(0, 2, 0.2, 0)
    toggleBtn.BorderSizePixel = 0
    local tbc = Instance.new("UICorner", toggleBtn)
    tbc.CornerRadius = UDim.new(0, 13)

    local state = false

    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
            toggleBtn.Position = UDim2.new(0, 32, 0.2, 0)
        else
            toggleBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
            toggleBtn.Position = UDim2.new(0, 2, 0.2, 0)
        end
        callback(state)
    end)
    
    return toggleBtn
end

--// FUNCTION: create button
local function CreateButton(parent, text, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1, 0, 0, 45)
    frame.BackgroundColor3 = Color3.fromRGB(50, 120, 220)
    frame.BorderSizePixel = 0

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)

    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)

    btn.MouseButton1Click:Connect(callback)
    btn.MouseEnter:Connect(function()
        frame.BackgroundColor3 = Color3.fromRGB(60, 130, 230)
    end)
    btn.MouseLeave:Connect(function()
        frame.BackgroundColor3 = Color3.fromRGB(50, 120, 220)
    end)
end

--// FUNCTION: create label
local function CreateLabel(parent, title, content)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1, 0, 0, 65)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    frame.BorderSizePixel = 0

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 6)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = frame
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, -20, 0, 25)
    titleLabel.Position = UDim2.new(0, 10, 0, 8)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local contentLabel = Instance.new("TextLabel")
    contentLabel.Parent = frame
    contentLabel.Text = content
    contentLabel.Font = Enum.Font.Gotham
    contentLabel.TextSize = 12
    contentLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    contentLabel.BackgroundTransparency = 1
    contentLabel.Position = UDim2.new(0, 10, 0, 28)
    contentLabel.Size = UDim2.new(1, -20, 0, 32)
    contentLabel.TextWrapped = true
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
    contentLabel.TextYAlignment = Enum.TextYAlignment.Top
end

--// FUNCTION: create dropdown
local function CreateDropdown(parent, title, options, callback)
    local selectedValue = options[1]
    
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Text = title
    label.Font = Enum.Font.Gotham
    label.TextColor3 = Color3.fromRGB(235, 235, 235)
    label.TextSize = 14
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 14, 0, 5)
    label.Size = UDim2.new(0.6, 0, 0.5, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left

    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Parent = frame
    dropdownBtn.Text = selectedValue
    dropdownBtn.Font = Enum.Font.Gotham
    dropdownBtn.TextSize = 13
    dropdownBtn.Size = UDim2.new(0, 110, 0, 32)
    dropdownBtn.Position = UDim2.new(1, -124, 0.08, 0)
    dropdownBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
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
            dropList.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            dropList.Size = UDim2.new(1, 0, 0, math.min(#options * 28, 150))
            dropList.Position = UDim2.new(0, 0, 1, 2)
            dropList.BorderSizePixel = 0
            dropList.ZIndex = 10
            local dlc = Instance.new("UICorner", dropList)
            dlc.CornerRadius = UDim.new(0, 4)

            local dlScroll = Instance.new("ScrollingFrame", dropList)
            dlScroll.Size = UDim2.new(1, 0, 1, 0)
            dlScroll.BackgroundTransparency = 1
            dlScroll.ScrollBarThickness = 3
            dlScroll.CanvasSize = UDim2.new(0, 0, 0, #options * 28)
            dlScroll.TopImage = ""
            dlScroll.BottomImage = ""
            dlScroll.MidImage = ""

            local dlLayout = Instance.new("UIListLayout", dlScroll)
            dlLayout.Padding = UDim.new(0, 0)

            for _, option in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Parent = dlScroll
                optBtn.Text = option
                optBtn.Font = Enum.Font.Gotham
                optBtn.TextSize = 12
                optBtn.Size = UDim2.new(1, 0, 0, 28)
                optBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                optBtn.TextColor3 = Color3.fromRGB(210, 210, 210)
                optBtn.BorderSizePixel = 0
                optBtn.ZIndex = 11

                optBtn.MouseButton1Click:Connect(function()
                    selectedValue = option
                    dropdownBtn.Text = selectedValue
                    callback(selectedValue)
                    dropList:Destroy()
                    isOpen = false
                end)

                optBtn.MouseEnter:Connect(function()
                    optBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                end)

                optBtn.MouseLeave:Connect(function()
                    optBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
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

-- Initialize character and animations with error handling
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
if not character then
    warn("[DennHub] Failed to get character")
    return
end

local humanoid = character:WaitForChild("Humanoid", 5)
if not humanoid then
    warn("[DennHub] Failed to get humanoid")
    return
end

local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

-- Load animations with timeout
local RodIdle, RodReel, RodShake
local animSuccess = pcall(function()
    RodIdle = ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("Animations", 5):WaitForChild("FishingRodReelIdle", 5)
    RodReel = ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("Animations", 5):WaitForChild("EasyFishReelStart", 5)
    RodShake = ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("Animations", 5):WaitForChild("CastFromFullChargePosition1Hand", 5)
end)

if not animSuccess or not (RodIdle and RodReel and RodShake) then
    warn("[DennHub] Failed to load animations")
    return
end

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

                local chargeRemote = ReplicatedStorage
                    .Packages._Index["sleitnick_net@0.2.0"].net["RF/ChargeFishingRod"]
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
        else
            warn("[DennHub] HumanoidRootPart not found")
        end
    end)
end

-------------------------------------------
----- =======[ PAGE CONTENT ] =======
-------------------------------------------

-- Auto Fishing Section
CreateLabel(PageAutoFishing, "Auto Fishing Controls", "Advanced automated fishing system with rod detection and perfect cast support")

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
CreateLabel(PageUtility, "Island Teleportation", "Quickly travel between different islands and locations")

local islandNames = {}
for name, _ in pairs(islandCoords) do
    table.insert(islandNames, name)
end
table.sort(islandNames)

CreateDropdown(PageUtility, "Select Island", islandNames, function(island)
    TeleportToIsland(island)
end)

CreateLabel(PageUtility, "Server Management", "Manage your connection and server experience")

CreateButton(PageUtility, "Rejoin Server", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

CreateButton(PageUtility, "Server Hop", function()
    task.spawn(function()
        pcall(function()
            local placeId = game.PlaceId
            if not placeId then
                warn("[DennHub] Invalid PlaceId")
                return
            end
            
            local servers = {}
            local cursor = ""
            local attempts = 0
            local maxAttempts = 3

            repeat
                if attempts >= maxAttempts then break end
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
                    warn("[DennHub] Failed to fetch servers: HTTP request error")
                    cursor = ""
                end
                
                task.wait(0.5)
            until not cursor or #servers > 0

            if #servers > 0 then
                local targetServer = servers[math.random(1, #servers)]
                TeleportService:TeleportToPlaceInstance(placeId, targetServer, LocalPlayer)
            else
                warn("[DennHub] No available servers found")
            end
        end)
    end)
end)

-- Settings Section
CreateLabel(PageSettings, "General Settings", "Configure script behavior and preferences")

CreateToggle(PageSettings, "Anti-AFK", function(value)
    state.AntiAFK = value
    if value then
        -- Disconnect idle connections to prevent AFK kick
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

CreateLabel(PageSettings, "Script Information", "Version 2.1 - Modern Edition | Created by @denmas._")

-- Cleanup on script stop/unload
local cleanup = function()
    StopAutoFish()
    if ScreenGui then
        ScreenGui:Destroy()
    end
end

-- Handle script cleanup
game:BindToClose(cleanup)

-- Handle character respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    StopAutoFish()
end)

task.wait(0.1)

-- Initialize first tab as visible AFTER all content is added
PageAutoFishing.Visible = true
TabAutoFishing.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
selectedTab = TabAutoFishing

print("[DennHub] Fish It v2.1 Loaded Successfully!")
