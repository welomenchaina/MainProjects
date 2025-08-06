local env = getgenv()
local Players = game:GetService("Players")
local Plr = Players.LocalPlayer
local function gethwid()
    return game:GetService("RbxAnalyticsService"):GetClientId()
end
local hwid = gethwid()
local id = Plr.UserId
if not game:IsLoaded() then
    repeat task.wait() until game:IsLoaded()
end

local function Tag(name, color, role, rank)
    local character = Plr.Character or Plr.CharacterAdded:Wait()
    local head = character:WaitForChild("Head")
    if head:FindFirstChild("CustomTag") then
        head.CustomTag:Destroy()
    end

    local tagGui = Instance.new("BillboardGui")
    tagGui.Name = "CustomTag"
    tagGui.Adornee = head
    tagGui.Size = UDim2.new(0, 180, 0, 100)
    tagGui.StudsOffset = Vector3.new(0, 3.2, 0)
    tagGui.AlwaysOnTop = true
    tagGui.Parent = head

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = tagGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local function createLabel(text, posY, scale, font, stroke)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, scale, 0)
        label.Position = UDim2.new(0, 0, posY, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = color
        label.TextStrokeColor3 = Color3.fromRGB(10, 10, 10)
        label.TextStrokeTransparency = stroke
        label.Font = font
        label.TextScaled = true
        label.Text = text
        label.Parent = frame
        return label
    end

    createLabel(rank or "", 0, 0.3, Enum.Font.GothamBlack, 0.2)
    local mid = createLabel(name, 0.3, 0.4, Enum.Font.GothamBold, 0.1)
    mid.TextSize = 36
    createLabel(role, 0.7, 0.3, Enum.Font.GothamMedium, 0.3)

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(50,50,55)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25,25,30))
    }
    gradient.Rotation = 90
    gradient.Parent = frame
end

env.EnabledTagSystem = true

if env.EnabledTagSystem then
    if id == 4634914591 or hwid == "a69024b1-3117-42ba-b85a-abb3e4ef19d2" then
        Tag("StinkyMan", Color3.fromRGB(120, 140, 50), "Asshole", "Shitman")
    end
    if id == 8888015275 or hwid == "75E6415A-C824-4F9B-A4E7-6C04413AA95F" then
        Tag("Owner", Color3.fromRGB(60, 110, 130), "Waylon", "Founder")
    end
end
