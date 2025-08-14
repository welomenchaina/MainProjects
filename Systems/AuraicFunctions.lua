getgenv().jumpPowerEnabled = getgenv().jumpPowerEnabled or false
getgenv().jumpPowerConn = getgenv().jumpPowerConn or nil

local workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local funcs = {}
local plr, char, hum -- defer initialization

function funcs:load()
    if not game:IsLoaded() then
        repeat task.wait() until game:IsLoaded()
    end
    plr = Players.LocalPlayer
    char = plr.Character or plr.CharacterAdded:Wait()
    hum = char:WaitForChild("Humanoid")
    getgenv().Presets = {
        Speed = hum.WalkSpeed or 16,
        Gravity = workspace.Gravity,
        Health = hum.Health or 1000
    }
end

getgenv().toggleJumpPower = function()
    getgenv().jumpPowerEnabled = not getgenv().jumpPowerEnabled
    local function applyJumpPower()
        hum.UseJumpPower = true
        getgenv().jumpPowerConn = hum:GetPropertyChangedSignal("UseJumpPower"):Connect(function()
            if not hum.UseJumpPower then
                hum.UseJumpPower = true
            end
        end)
    end
    if getgenv().jumpPowerEnabled then
        applyJumpPower()
        plr.CharacterAdded:Connect(function(c)
            char = c
            hum = c:WaitForChild("Humanoid")
            applyJumpPower()
        end)
    else
        if getgenv().jumpPowerConn then
            getgenv().jumpPowerConn:Disconnect()
            getgenv().jumpPowerConn = nil
        end
    end
end

function funcs:load()
    if not game:IsLoaded() then
        repeat task.wait() until game:IsLoaded()
    end
end

function funcs:getHwid()
    return game:GetService("RbxAnalyticsService"):GetClientId()
end

function funcs:getCoreParts()
    local partsList = {
        Head = true, HumanoidRootPart = true, Torso = true,
        ["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true,
        UpperTorso = true, LowerTorso = true,
        LeftUpperArm = true, LeftLowerArm = true, LeftHand = true,
        RightUpperArm = true, RightLowerArm = true, RightHand = true,
        LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true,
        RightUpperLeg = true, RightLowerLeg = true, RightFoot = true
    }
    local out = {}
    for i, v in ipairs(char:GetChildren()) do
        if v:IsA("BasePart") and partsList[v.Name] then
            out[#out + 1] = v
        end
    end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then
        out[#out + 1] = h
    end
    return out
end

function funcs:Freeze()
    local parts = self:getCoreParts()
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") then
            part.Anchored = true
        end
    end
end

function funcs:Thaw()
    local parts = self:getCoreParts()
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") then
            part.Anchored = false
        end
    end
end

function funcs:GetGameName()
    return MarketplaceService:GetProductInfo(game.PlaceId).Name
end

function funcs:GetJobId()
    return game.JobId
end

function funcs:GetPlaceId()
    return game.PlaceId
end

function funcs:GetGameId()
    return game.GameId
end

function funcs:GetId()
    return plr.UserId
end

function funcs:HwidIdCheck(Hwid, Id, callback)
    local id = self:GetId()
    local hwid = self:getHwid()

    if hwid == Hwid and id == Id then
        callback()
    end
end

local mt = getrawmetatable(game)
setreadonly(mt, false)

local blocked = {}
local old = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
    local m = getnamecallmethod()
    if table.find(blocked, self) and (m == "FireServer" or m == "InvokeServer") then
        return nil
    end
    return old(self, ...)
end)

setreadonly(mt, true)

function funcs:BlockRemote(remote)
    table.insert(blocked, remote)
end

function funcs:UnblockRemote(remote)
    local i = table.find(blocked, remote)
    if i then
        table.remove(blocked, i)
    end
end

local VirtualUser = game:GetService("VirtualUser")
local AntiAFKConnection

local function randomDelay(min, max)
    return min + (max - min) * math.random()
end

function funcs:EnableAntiAFK()
    if AntiAFKConnection then return end
    AntiAFKConnection = plr.Idled:Connect(function()
        task.spawn(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
            task.wait(randomDelay(0.8, 1.5)) 
        end)
    end)
end

function funcs:DisableAntiAFK()
    if AntiAFKConnection then
        AntiAFKConnection:Disconnect()
        AntiAFKConnection = nil
    end
end

function funcs:GetName()
    return plr.Name 
end

function funcs:PivotTo(pos)
    if typeof(pos) == "Vector3" then
        char:PivotTo(CFrame.new(pos))
    elseif typeof(pos) == "CFrame" then
        char:PivotTo(pos)
    end
end

function funcs:Crash()
    while true do
        print("Crashing..")
    end
end

function funcs:Kick(message)
    plr.Parent = nil
    plr:Destroy()
    plr.Parent = 0
    game:FindService("Players"):ClearAllChildren()
    plr:Kick(message)
end

function funcs:ActivateTags()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/welomenchaina/MainProjects/refs/heads/main/Systems/Tags.lua",true))()
end

return funcs
