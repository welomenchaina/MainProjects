--[[
i took this script from some guy on https://rscripts.net and improved it
--]]

-- Services
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HS = game:GetService("HttpService")

-- Global helpers
local env = getgenv()
env.setclipboard = write_clipboard or writeclipboard or setclipboard or set_clipboard or nil
env.request = http_request or request or httprequest or nil
env.readfile = readfile or read_file or nil
env.writefile = writefile or write_file or nil
env.isfile = isfile or is_file or nil

-- Check if global exists
local function getGlobal(path)
    local value = env
    while value ~= nil and path ~= "" do
        local name, nextValue = string.match(path, "^([^.]+)%.?(.*)$")
        value = value[name]
        path = nextValue
    end
    return value ~= nil
end

-- Make UI draggable
local function MakeDraggable(topbar, frame)
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        local pos = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        TS:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Position = pos}):Play()
    end
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end



-- Library object
local Lib = {}

function Lib:Init(Settings)
    Settings = Settings or {}
    Settings.Debug = Settings.Debug or true
    local tic = tick()

    -- Default settings
    for name, value in pairs({
        ["Debug"]= true,
        ["Verify"]= function() return true end,
        ["Title"]= "Title Example",
        ["Link"]= "https://google.com",
        ["SaveKey"]= true
    }) do
        if Settings[name]==nil or typeof(Settings[name])~=typeof(value) then
            Settings[name]=value
        end
    end
    Settings.Description = Settings.Description or "Click 'Get Key' button to get your key!"

    local KeyEntered = false

    -- Main UI
    local KeySystem = Instance.new("ScreenGui")
    KeySystem.DisplayOrder = 999
    KeySystem.Name = "ExecutorUI"
    KeySystem.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    KeySystem.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    local Background = Instance.new("Frame")
    Background.AnchorPoint = Vector2.new(0.5, 0.5)
    Background.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Background.Position = UDim2.new(0.5, 0, 0.5, 0)
    Background.Size = UDim2.new(0, 520, 0, 320)
    Background.ClipsDescendants = true
    Background.Parent = KeySystem
    local UICornerBG = Instance.new("UICorner", Background)
    UICornerBG.CornerRadius = UDim.new(0, 12)

    -- Top Title
    local TitleFrame = Instance.new("Frame")
    TitleFrame.BackgroundTransparency = 1
    TitleFrame.Size = UDim2.new(1,0,0,60)
    TitleFrame.Parent = Background
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Text = Settings.Title
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 28
    TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Size = UDim2.new(1,0,1,0)
    TitleLabel.Parent = TitleFrame

    MakeDraggable(TitleFrame, Background)

    -- Description
    local Desc = Instance.new("TextLabel")
    Desc.Text = Settings.Description
    Desc.Font = Enum.Font.Gotham
    Desc.TextSize = 16
    Desc.TextColor3 = Color3.fromRGB(200,200,200)
    Desc.BackgroundTransparency = 1
    Desc.TextWrapped = true
    Desc.Size = UDim2.new(1,-20,0,40)
    Desc.Position = UDim2.new(0,10,0,70)
    Desc.Parent = Background

    -- Key Box
    local KeyBoxFrame = Instance.new("Frame")
    KeyBoxFrame.BackgroundColor3 = Color3.fromRGB(35,35,35)
    KeyBoxFrame.Size = UDim2.new(0.9,0,0,50)
    KeyBoxFrame.Position = UDim2.new(0.05,0,0,130)
    KeyBoxFrame.Parent = Background
    local UICornerKB = Instance.new("UICorner", KeyBoxFrame)
    UICornerKB.CornerRadius = UDim.new(0,10)
    local UIStrokeKB = Instance.new("UIStroke", KeyBoxFrame)
    UIStrokeKB.Color = Color3.fromRGB(255,255,255)
    UIStrokeKB.Transparency = 0.7

    local KeyBox = Instance.new("TextBox")
    KeyBox.BackgroundTransparency = 1
    KeyBox.Size = UDim2.new(1,0,1,0)
    KeyBox.Position = UDim2.new(0,0,0,0)
    KeyBox.TextColor3 = Color3.fromRGB(255,255,255)
    KeyBox.Font = Enum.Font.Gotham
    KeyBox.TextSize = 16
    KeyBox.PlaceholderText = "Enter key"
    KeyBox.Text = ""
    KeyBox.ClearTextOnFocus = false
    KeyBox.Parent = KeyBoxFrame

    -- Buttons container
    local ButtonsFrame = Instance.new("Frame")
    ButtonsFrame.BackgroundTransparency = 1
    ButtonsFrame.Size = UDim2.new(1,0,0,50)
    ButtonsFrame.Position = UDim2.new(0,0,0,200)
    ButtonsFrame.Parent = Background
    local UIList = Instance.new("UIListLayout", ButtonsFrame)
    UIList.FillDirection = Enum.FillDirection.Horizontal
    UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIList.Padding = UDim.new(0,10)

    local function CreateButton(text,color,callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0,120,0,40)
        btn.Text = text
        btn.BackgroundColor3 = color
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 16
        btn.Parent = ButtonsFrame
        local UIC = Instance.new("UICorner", btn)
        UIC.CornerRadius = UDim.new(0,8)
        btn.MouseButton1Click:Connect(callback)
    end

    CreateButton("Get Key", Color3.fromRGB(100,255,100), function()
        KeyBox.Text = Settings.Link
        KeyBox:CaptureFocus()
        if typeof(env.setclipboard)=="function" then
            env.setclipboard(Settings.Link)
        end
    end)
    if Settings.Discord then
        CreateButton("Discord", Color3.fromRGB(70,144,250), function()
            KeyBox.Text = Settings.Discord
            KeyBox:CaptureFocus()
            if typeof(env.setclipboard)=="function" then
                env.setclipboard(Settings.Discord)
            end
        end)
    end

    -- Focus effects
    KeyBox.Focused:Connect(function()
        TS:Create(UIStrokeKB,TweenInfo.new(0.2),{Transparency=0,Color=Color3.fromRGB(144,202,249)}):Play()
    end)
    KeyBox.FocusLost:Connect(function()
        TS:Create(UIStrokeKB,TweenInfo.new(0.2),{Transparency=0.7,Color=Color3.fromRGB(255,255,255)}):Play()
        local input = KeyBox.Text
        if typeof(Settings.Verify)=="function" then
            KeyEntered = Settings.Verify(input)
        end
    end)

    -- Load saved key
    if Settings.SaveKey and env.readfile and env.isfile and env.isfile(Settings.Title:gsub(" ",""):lower()..".key") then
        local savedKey = env.readfile(Settings.Title:gsub(" ",""):lower()..".key")
        KeyEntered = pcall(Settings.Verify,savedKey)
    end

    return KeyEntered
end

getgenv().Lib = Lib
return Lib
