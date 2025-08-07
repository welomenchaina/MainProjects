
local init = loadstring(game:HttpGet("https://raw.githubusercontent.com/welomenchaina/MainProjects/refs/heads/main/Systems/AuraicFunctions.lua",true))()

init:load()

if not game:IsLoaded() then
    init:Freeze()
    task.wait(5)
    init:Thaw()
end

local workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local team = plr.Team
local VU = game:GetService("VirtualUser")


local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/master/source.lua", true))()

local Window = Luna:CreateWindow({
    Name = "Jit Universal,
    Subtitle = nil,
    LogoID = "122945680110913",
    LoadingEnabled = true,
    LoadingTitle = "Jit Universal",
    LoadingSubtitle = "We are humans, not horses",

    ConfigSettings = {
        RootFolder = nil,
        ConfigFolder = "JitUniversal"
    },

    KeySystem = false,
    KeySettings = {
        Title = "Luna Example Key",
        Subtitle = "Key System",
        Note = "Best Key System Ever! Also, Please Use A HWID Keysystem like Pelican, Luarmor etc. that provide key strings based on your HWID since putting a simple string is very easy to bypass",
        SaveInRoot = false,
        SaveKey = true,
        Key = {"Example Key"},
        SecondAction = {
            Enabled = true,
            Type = "Link",
            Parameter = ""
        }
    }
})

Window:CreateHomeTab({
    SupportedExecutors = {"Wave", "Delta", "Swift", "Xenith"}, 
    DiscordInvite = "w7CxvgbK4Z", 
    Icon = 2, 
})

local Credits = Window:CreateTab({
    Name = "Credits",
    Icon = "album",
    ImageSource = "Lucide",
    ShowTitle = false 
})

local Player = Window:CreateTab({
    Name = "Player",
    Icon = "anchor",
    ImageSource = "Lucide",
    ShowTitle = false 
})

local UiMenu = Window:CreateTab({
    Name = "Ui Menu",
    Icon = "cross",
    ImageSource = "Lucide",
    ShowTitle = false 
})

Player:CreateSection("Player Exploits")
Credits:CreateSection("Credits | TY!")

local function Notify(message)
    Luna:Notification({ 
        Title = "Jit Universal",
        Icon = "crown",
        ImageSource = "Lucide",
        Content = message
    })
end

Notify("Welcome To Jit Universal!")

Credits:CreateDivider()

local Label = Credits:CreateLabel({
    Text = "Creator - Waylon (@waylontheevident on discord)",
    Style = 2 
})

Credits:CreateDivider()

local ResetButton = Player:CreateButton({
    Name = "Reset",
    Description = nil, 
    Callback = function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
    humanoid:ChangeState(Enum.HumanoidStateType.Dead)
    end
})

local TpToolGiver = Tab:CreateInput({
    Name = "Tp-Tool Giver",
    PlaceholderText = "Name Of Tool",
    CurrentValue = "TpTool",
    Numeric = false,
    Enter = false,
    Callback = function(Text)
        if not Text or Text == "" then return end
        local tool = Instance.new("Tool")
        tool.Name = Text
        tool.Parent = plr.Backpack
    end
}, "tptoolgiver")


local SpeedChanger = Player:CreateSlider({
    Name = "Speed Changer",
    Range = {0, 250},
    Increment = 1,
    CurrentValue = hum.Walkspeed,
    Callback = function(Value)
        if hum and hum.WalkSpeed then
            hum.WalkSpeed = Value
        elseif char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = Value
        end
    end
}, "Walkspeed")

local GravityChanger = Player:CreateSlider({
    Name = "Gravity Changer",
    Range = {0, 500}, 
    Increment = 1,
    CurrentValue = workspace.Gravity,
    Callback = function(Value)
        if workspace.Gravity then
        workspace.Gravity = Value
        end
    end
}, "Gravity")


local FreezeThaw = Player:CreateToggle({
    Name = "Freeze Yourself",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            init:Freeze()
        else
            init:Thaw()
        end
    end
}, "Freezer/Thawer")


Players.LocalPlayer.Idled:Connect(function()
    VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait()
    VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

local connection

local AntiAfk = Player:CreateToggle({
    Name = "Anti-AFK",
    Description = nil,
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            connection = game:GetService("Players").LocalPlayer.Idled:Connect(function()
                VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait()
                VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        else
            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
    end
}, "AntiAFK")

UiMenu:BuildConfigSection()
UiMenu:BuildThemeSection() 


local UiDestroy = UiMenu:CreateButton({
    Name = "Destroy Ui",
    Description = nil, 
    Callback = function()
Luna:Destroy()
    end
})