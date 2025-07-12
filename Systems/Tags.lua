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
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local head = character:WaitForChild("Head")

    if head:FindFirstChild("CustomTag") then
        head.CustomTag:Destroy()
    end

    local tagGui = Instance.new("BillboardGui")
    tagGui.Name = "CustomTag"
    tagGui.Adornee = head
    tagGui.Size = UDim2.new(0, 120, 0, 80)
    tagGui.StudsOffset = Vector3.new(0, 3, 0)
    tagGui.AlwaysOnTop = true
    tagGui.Parent = head

    local rankLabel = Instance.new("TextLabel")
    rankLabel.Size = UDim2.new(1, 0, 0.33, 0)
    rankLabel.Position = UDim2.new(0, 0, 0, 0)
    rankLabel.BackgroundTransparency = 1
    rankLabel.TextColor3 = color
    rankLabel.TextStrokeTransparency = 0.3
    rankLabel.Font = Enum.Font.GothamBlack
    rankLabel.TextScaled = true
    rankLabel.Text = rank or ""
    rankLabel.Parent = tagGui

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.33, 0)
    nameLabel.Position = UDim2.new(0, 0, 0.33, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = color
    nameLabel.TextStrokeTransparency = 0.4
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.Text = name
    nameLabel.Parent = tagGui

    local roleLabel = Instance.new("TextLabel")
    roleLabel.Size = UDim2.new(1, 0, 0.33, 0)
    roleLabel.Position = UDim2.new(0, 0, 0.66, 0)
    roleLabel.BackgroundTransparency = 1
    roleLabel.TextColor3 = color
    roleLabel.TextStrokeTransparency = 0.5
    roleLabel.Font = Enum.Font.Gotham
    roleLabel.TextScaled = true
    roleLabel.Text = role
    roleLabel.Parent = tagGui
end

env.EnabledTagSystem = nil
env.EnabledTagSystem = true
local enabledsys = env.EnabledTagSystem

if enabledsys then
    if id == 4634914591 and hwid == "a69024b1-3117-42ba-b85a-abb3e4ef19d2" then
        Tag("StinkyMan", Color3.fromRGB(85, 93, 35), "Asshole", "Shitman")
    end
end
