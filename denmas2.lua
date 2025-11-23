--// Modern UI Without WindUI
--// Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DennHubUI"
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

--// Main Window
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Size = UDim2.new(0, 500, 0, 330)
MainFrame.Position = UDim2.new(0.35, 0, 0.25, 0)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.BackgroundTransparency = 0.05

-- Shadow
local Shadow = Instance.new("UICorner", MainFrame)
Shadow.CornerRadius = UDim.new(0, 10)

local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(90, 90, 90)
UIStroke.Thickness = 1

--// Title Bar
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Text = "DennHub - Modern UI"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, -20, 0, 40)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left

--// Tabs Bar
local Tabs = Instance.new("Frame")
Tabs.Parent = MainFrame
Tabs.BackgroundTransparency = 1
Tabs.Size = UDim2.new(0, 150, 1, -40)
Tabs.Position = UDim2.new(0, 0, 0, 40)

local TabList = Instance.new("UIListLayout", Tabs)
TabList.Padding = UDim.new(0, 6)

--// Function to create tab button
local function CreateTabButton(name)
    local btn = Instance.new("TextButton")
    btn.Parent = Tabs
    btn.Text = name
    btn.Size = UDim2.new(1, -10, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 16
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.AutoButtonColor = true
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 8)
    return btn
end

local TabAutoFishing = CreateTabButton("Auto Fishing")
local TabUtility = CreateTabButton("Utility")
local TabSettings = CreateTabButton("Settings")

--// Pages Container
local Pages = Instance.new("Frame")
Pages.Parent = MainFrame
Pages.Size = UDim2.new(1, -170, 1, -40)
Pages.Position = UDim2.new(0, 160, 0, 40)
Pages.BackgroundTransparency = 1

--// Function to create page
local function CreatePage()
    local page = Instance.new("ScrollingFrame")
    page.Parent = Pages
    page.Size = UDim2.new(1, 0, 1, 0)
    page.CanvasSize = UDim2.new(0, 0, 0, 600)
    page.ScrollBarThickness = 4
    page.BackgroundTransparency = 1

    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    return page
end

local PageAutoFishing = CreatePage()
local PageUtility = CreatePage()
local PageSettings = CreatePage()

PageUtility.Visible = false
PageSettings.Visible = false

--// Switch tab function
local function SwitchTab(page)
    PageAutoFishing.Visible = false
    PageUtility.Visible = false
    PageSettings.Visible = false
    page.Visible = true
end

TabAutoFishing.MouseButton1Click:Connect(function() SwitchTab(PageAutoFishing) end)
TabUtility.MouseButton1Click:Connect(function() SwitchTab(PageUtility) end)
TabSettings.MouseButton1Click:Connect(function() SwitchTab(PageSettings) end)

--// FUNCTION: create toggle
local function CreateToggle(parent, text, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextColor3 = Color3.fromRGB(230, 230, 230)
    label.TextSize = 16
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Parent = frame
    toggleBtn.Text = "OFF"
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 14
    toggleBtn.Size = UDim2.new(0, 60, 0, 26)
    toggleBtn.Position = UDim2.new(1, -70, 0.18, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    local c = Instance.new("UICorner", toggleBtn)

    local state = false

    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        toggleBtn.Text = state and "ON" or "OFF"
        toggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(100, 0, 0)
        callback(state)
    end)
end

--// Auto Fishing Page Content
CreateToggle(PageAutoFishing, "Auto Fishing", function(state)
    print("Auto Fish:", state)
end)

CreateToggle(PageAutoFishing, "Auto Perfect Cast", function(state)
    print("Perfect Cast:", state)
end)

CreateToggle(PageAutoFishing, "Auto Sell", function(state)
    print("Auto Sell:", state)
end)

--// Utility Page Content
CreateToggle(PageUtility, "Auto Reconnect", function(state)
    print("Reconnect:", state)
end)

--// Settings Page Content
CreateToggle(PageSettings, "Anti AFK", function(state)
    print("Anti AFK:", state)
end)

print("Modern UI Loaded!")
