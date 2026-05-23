local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Uh Universal Fps",
    Footer = "Aimlock + ESP",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
})

local Tabs = {
    Aim = Window:AddTab("Aimlock", "crosshair"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Colors = Window:AddTab("Colors", "palette"),
    Settings = Window:AddTab("Settings", "settings"),
}

local Options = Library.Options
local Toggles = Library.Toggles

local cfg = {
    aimEnabled = true,
    aimSmooth = 1,
    aimTeamCheck = false,
    aimWallCheck = true,
    espEnabled = true,
    showBox = true,
    showTracer = true,
    showName = true,
    showHealth = true,
    showSkeleton = true,
    espTeamCheck = false,
    maxDistance = 2000,
    lineThickness = 1,
    tracerOrigin = "Bottom",
    boxColor = Color3.fromRGB(255, 70, 90),
    tracerColor = Color3.fromRGB(255, 70, 90),
    nameColor = Color3.fromRGB(255, 255, 255),
    skeletonColor = Color3.fromRGB(255, 70, 90),
    healthHigh = Color3.fromRGB(60, 230, 120),
    healthLow = Color3.fromRGB(220, 40, 40),
}

local function ownRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function ownHead()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("Head")
end

local function aimPart(char)
    return char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
end

local function isAlive(player)
    if not player.Character then return false end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function sameTeam(player)
    return LocalPlayer.Team and player.Team and player.Team == LocalPlayer.Team
end

local function eligibleForEsp(player)
    if player == LocalPlayer or not isAlive(player) then return false end
    if cfg.espTeamCheck and sameTeam(player) then return false end
    return true
end

local function eligibleForAim(player)
    if player == LocalPlayer or not isAlive(player) then return false end
    if cfg.aimTeamCheck and sameTeam(player) then return false end
    return true
end

local function hasLineOfSight(targetPart)
    if not cfg.aimWallCheck then return true end
    local head = ownHead()
    if not head or not targetPart then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = {LocalPlayer.Character}
    if targetPart.Parent then table.insert(exclude, targetPart.Parent) end
    params.FilterDescendantsInstances = exclude
    params.IgnoreWater = true
    local result = workspace:Raycast(head.Position, targetPart.Position - head.Position, params)
    return result == nil
end

local function closestEnemy()
    local hrp = ownRoot()
    if not hrp then return nil end
    local pick, pickDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if eligibleForAim(p) then
            local part = aimPart(p.Character)
            if part and hasLineOfSight(part) then
                local d = (part.Position - hrp.Position).Magnitude
                if d < pickDist then
                    pickDist = d
                    pick = part
                end
            end
        end
    end
    return pick
end

local holding = false

UIS.InputBegan:Connect(function(input, processed)
    if processed or not cfg.aimEnabled then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holding = true
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holding = false
    end
end)

local R6_BONES = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}

local R15_BONES = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}

local function makeLine(thickness)
    local line = Drawing.new("Line")
    line.Visible = false
    line.Thickness = thickness or 1
    line.Transparency = 1
    return line
end

local function makeText()
    local text = Drawing.new("Text")
    text.Visible = false
    text.Size = 13
    text.Center = true
    text.Outline = true
    text.OutlineColor = Color3.new(0, 0, 0)
    text.Font = 2
    return text
end

local function makeSquare()
    local sq = Drawing.new("Square")
    sq.Visible = false
    sq.Thickness = 1
    sq.Filled = false
    sq.Transparency = 1
    return sq
end

local drawings = {}

local function buildFor(player)
    if player == LocalPlayer then return end
    local set = {
        box = makeSquare(),
        boxOutline = makeSquare(),
        tracer = makeLine(),
        name = makeText(),
        healthText = makeText(),
        healthBg = makeLine(3),
        healthBar = makeLine(2),
        bones = {},
    }
    set.boxOutline.Color = Color3.new(0, 0, 0)
    set.boxOutline.Thickness = 3
    for i = 1, 15 do
        set.bones[i] = makeLine()
    end
    drawings[player] = set
end

local function hideSet(set)
    set.box.Visible = false
    set.boxOutline.Visible = false
    set.tracer.Visible = false
    set.name.Visible = false
    set.healthText.Visible = false
    set.healthBg.Visible = false
    set.healthBar.Visible = false
    for _, bone in ipairs(set.bones) do
        bone.Visible = false
    end
end

local function teardownFor(player)
    local set = drawings[player]
    if not set then return end
    for key, value in pairs(set) do
        if key == "bones" then
            for _, bone in ipairs(value) do bone:Remove() end
        else
            value:Remove()
        end
    end
    drawings[player] = nil
end

for _, player in ipairs(Players:GetPlayers()) do
    buildFor(player)
end

Players.PlayerAdded:Connect(buildFor)
Players.PlayerRemoving:Connect(teardownFor)

local function bonesFor(char)
    return char:FindFirstChild("UpperTorso") and R15_BONES or R6_BONES
end

local function tracerStart()
    local size = Camera.ViewportSize
    if cfg.tracerOrigin == "Top" then
        return Vector2.new(size.X / 2, 0)
    elseif cfg.tracerOrigin == "Center" then
        return Vector2.new(size.X / 2, size.Y / 2)
    end
    return Vector2.new(size.X / 2, size.Y)
end

RunService.RenderStepped:Connect(function()
    if holding and cfg.aimEnabled then
        local target = closestEnemy()
        if target then
            local goal = CFrame.new(Camera.CFrame.Position, target.Position)
            if cfg.aimSmooth >= 0.99 then
                Camera.CFrame = goal
            else
                Camera.CFrame = Camera.CFrame:Lerp(goal, cfg.aimSmooth)
            end
        end
    end

    local hrp = ownRoot()
    local origin = tracerStart()

    for player, set in pairs(drawings) do
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")

        if not cfg.espEnabled or not eligibleForEsp(player) or not root or not head then
            hideSet(set)
        else
            local distance = hrp and (root.Position - hrp.Position).Magnitude or 0
            if distance > cfg.maxDistance then
                hideSet(set)
            else
                local headScreen, headOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local footScreen, footOn = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

                if not (headOn and footOn) then
                    hideSet(set)
                else
                    local boxHeight = math.abs(headScreen.Y - footScreen.Y)
                    local boxWidth = boxHeight * 0.55
                    local boxPos = Vector2.new(headScreen.X - boxWidth / 2, headScreen.Y)
                    local boxSize = Vector2.new(boxWidth, boxHeight)

                    if cfg.showBox then
                        set.boxOutline.Position = boxPos
                        set.boxOutline.Size = boxSize
                        set.boxOutline.Thickness = cfg.lineThickness + 2
                        set.boxOutline.Visible = true
                        set.box.Position = boxPos
                        set.box.Size = boxSize
                        set.box.Color = cfg.boxColor
                        set.box.Thickness = cfg.lineThickness
                        set.box.Visible = true
                    else
                        set.box.Visible = false
                        set.boxOutline.Visible = false
                    end

                    if cfg.showTracer then
                        set.tracer.From = origin
                        set.tracer.To = Vector2.new(footScreen.X, footScreen.Y)
                        set.tracer.Color = cfg.tracerColor
                        set.tracer.Thickness = cfg.lineThickness
                        set.tracer.Visible = true
                    else
                        set.tracer.Visible = false
                    end

                    if cfg.showName then
                        set.name.Position = Vector2.new(headScreen.X, headScreen.Y - 28)
                        set.name.Text = player.DisplayName ~= player.Name
                            and (player.DisplayName .. " (@" .. player.Name .. ")")
                            or player.Name
                        set.name.Color = cfg.nameColor
                        set.name.Visible = true
                    else
                        set.name.Visible = false
                    end

                    if cfg.showHealth then
                        local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        local barX = boxPos.X - 6
                        set.healthBg.From = Vector2.new(barX, boxPos.Y)
                        set.healthBg.To = Vector2.new(barX, boxPos.Y + boxSize.Y)
                        set.healthBg.Color = Color3.new(0, 0, 0)
                        set.healthBg.Visible = true
                        set.healthBar.From = Vector2.new(barX, boxPos.Y + boxSize.Y)
                        set.healthBar.To = Vector2.new(barX, boxPos.Y + boxSize.Y - (boxSize.Y * ratio))
                        set.healthBar.Color = cfg.healthLow:Lerp(cfg.healthHigh, ratio)
                        set.healthBar.Visible = true
                        set.healthText.Position = Vector2.new(boxPos.X + boxSize.X + 14, boxPos.Y + boxSize.Y - 6)
                        set.healthText.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
                        set.healthText.Color = Color3.new(1, 1, 1)
                        set.healthText.Visible = true
                    else
                        set.healthBg.Visible = false
                        set.healthBar.Visible = false
                        set.healthText.Visible = false
                    end

                    if cfg.showSkeleton then
                        local pairs_ = bonesFor(char)
                        for i, pair in ipairs(pairs_) do
                            local a = char:FindFirstChild(pair[1])
                            local b = char:FindFirstChild(pair[2])
                            local bone = set.bones[i]
                            if a and b and bone then
                                local aScreen, aOn = Camera:WorldToViewportPoint(a.Position)
                                local bScreen, bOn = Camera:WorldToViewportPoint(b.Position)
                                if aOn and bOn then
                                    bone.From = Vector2.new(aScreen.X, aScreen.Y)
                                    bone.To = Vector2.new(bScreen.X, bScreen.Y)
                                    bone.Color = cfg.skeletonColor
                                    bone.Thickness = cfg.lineThickness
                                    bone.Visible = true
                                else
                                    bone.Visible = false
                                end
                            elseif bone then
                                bone.Visible = false
                            end
                        end
                        for i = #pairs_ + 1, #set.bones do
                            set.bones[i].Visible = false
                        end
                    else
                        for _, bone in ipairs(set.bones) do
                            bone.Visible = false
                        end
                    end
                end
            end
        end
    end
end)

do
    local group = Tabs.Aim:AddLeftGroupbox("Aimlock")
    group:AddToggle("AimEnabled", {
        Text = "Enable Aimlock",
        Default = true,
        Callback = function(v) cfg.aimEnabled = v end,
    })
    group:AddSlider("AimSmooth", {
        Text = "Smoothness",
        Tooltip = "1 = instant snap, lower = smoother drag",
        Default = 1, Min = 0.05, Max = 1, Rounding = 2,
        Callback = function(v) cfg.aimSmooth = v end,
    })
    group:AddToggle("AimWallCheck", {
        Text = "Wallcheck",
        Tooltip = "Skip targets that have walls in the way",
        Default = true,
        Callback = function(v) cfg.aimWallCheck = v end,
    })
    group:AddToggle("AimTeam", {
        Text = "Ignore teammates",
        Default = false,
        Callback = function(v) cfg.aimTeamCheck = v end,
    })
    group:AddLabel("Hold right mouse button to lock onto the closest visible enemy.")
end

do
    local group = Tabs.Visuals:AddLeftGroupbox("ESP")
    group:AddToggle("EspEnabled", {
        Text = "Master ESP Toggle",
        Default = true,
        Callback = function(v) cfg.espEnabled = v end,
    })
    group:AddToggle("BoxEnabled", {
        Text = "Boxes",
        Default = true,
        Callback = function(v) cfg.showBox = v end,
    })
    group:AddToggle("TracerEnabled", {
        Text = "Tracers",
        Default = true,
        Callback = function(v) cfg.showTracer = v end,
    })
    group:AddToggle("NameEnabled", {
        Text = "Names",
        Default = true,
        Callback = function(v) cfg.showName = v end,
    })
    group:AddToggle("HealthEnabled", {
        Text = "Health Bar",
        Default = true,
        Callback = function(v) cfg.showHealth = v end,
    })
    group:AddToggle("SkeletonEnabled", {
        Text = "Skeleton",
        Default = true,
        Callback = function(v) cfg.showSkeleton = v end,
    })

    local right = Tabs.Visuals:AddRightGroupbox("Tuning")
    right:AddToggle("EspTeamCheck", {
        Text = "Ignore teammates (ESP)",
        Default = false,
        Callback = function(v) cfg.espTeamCheck = v end,
    })
    right:AddSlider("MaxDistance", {
        Text = "Max Distance",
        Default = 2000, Min = 50, Max = 5000, Rounding = 0, Suffix = " studs",
        Callback = function(v) cfg.maxDistance = v end,
    })
    right:AddSlider("Thickness", {
        Text = "Line Thickness",
        Default = 1, Min = 1, Max = 5, Rounding = 0,
        Callback = function(v) cfg.lineThickness = v end,
    })
    right:AddDropdown("TracerOrigin", {
        Values = {"Top", "Center", "Bottom"},
        Default = "Bottom",
        Text = "Tracer Origin",
        Callback = function(v) cfg.tracerOrigin = v end,
    })
end

do
    local group = Tabs.Colors:AddLeftGroupbox("Element Colors")
    group:AddLabel("Box"):AddColorPicker("BoxColor", {
        Default = cfg.boxColor,
        Title = "Box Color",
        Callback = function(v) cfg.boxColor = v end,
    })
    group:AddLabel("Tracer"):AddColorPicker("TracerColor", {
        Default = cfg.tracerColor,
        Title = "Tracer Color",
        Callback = function(v) cfg.tracerColor = v end,
    })
    group:AddLabel("Name"):AddColorPicker("NameColor", {
        Default = cfg.nameColor,
        Title = "Name Color",
        Callback = function(v) cfg.nameColor = v end,
    })
    group:AddLabel("Skeleton"):AddColorPicker("SkeletonColor", {
        Default = cfg.skeletonColor,
        Title = "Skeleton Color",
        Callback = function(v) cfg.skeletonColor = v end,
    })

    local right = Tabs.Colors:AddRightGroupbox("Health Bar")
    right:AddLabel("Full Health"):AddColorPicker("HealthHigh", {
        Default = cfg.healthHigh,
        Title = "Full HP Color",
        Callback = function(v) cfg.healthHigh = v end,
    })
    right:AddLabel("Low Health"):AddColorPicker("HealthLow", {
        Default = cfg.healthLow,
        Title = "Low HP Color",
        Callback = function(v) cfg.healthLow = v end,
    })
    right:AddLabel("Health bar fades from Low to Full as HP rises.")
end

do
    local menu = Tabs.Settings:AddLeftGroupbox("Menu")
    menu:AddButton({Text = "Unload", Func = function()
        for player in pairs(drawings) do teardownFor(player) end
        Library:Unload()
    end})
    menu:AddLabel("Menu keybind"):AddKeyPicker("MenuKey", {
        Default = "RightShift", NoUI = true, Text = "Menu",
    })
    Library.ToggleKeybind = Options.MenuKey

    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({"MenuKey"})
    ThemeManager:SetFolder("UniversalESPnaimbot")
    SaveManager:SetFolder("UniversalESPnaimbot/configs")
    SaveManager:BuildConfigSection(Tabs.Settings)
    ThemeManager:ApplyToTab(Tabs.Settings)
    SaveManager:LoadAutoloadConfig()
end

Library:Notify({Title = "Loaded", Description = "Hold RMB to aimlock", Time = 3})
