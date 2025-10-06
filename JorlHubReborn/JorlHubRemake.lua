if not game:IsLoaded() then
    repeat task.wait() until game:IsLoaded()
end

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Jorl Hub Remake Key System",
    SubTitle = "Created.. Organized, by Waylon.",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Key System", Icon = "" })
}
local Section = Tabs.Main:AddSection("Key System")

Tabs.Main:AddButton({
    Title = "Get Key",
    Description = "Get The Key [Discord Server]",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/W8tfTZVJ")
            Fluent:Notify({
                Title = "Key Copied!",
                Content = "Discord link copied to clipboard.",
                SubContent = "Paste in your browser.",
                Duration = 10
            })
        elseif toclipboard then
            toclipboard("https://discord.gg/W8tfTZVJ")
            Fluent:Notify({
                Title = "Key Copied!",
                Content = "Discord link copied",
                Duration = 10
            })
        else
            Fluent:Notify({
                Title = "Low UNC Executor",
                Content = "Executor does not support clipboard.",
                SubContent = "https://discord.gg/W8tfTZVJ",
                Duration = 10
            })
        end
    end
})

local Input = Tabs.Main:AddInput("Input", {
    Title = "Enter Key",
    Description = "Put your key inside of here.",
    Default = "",
    Placeholder = "",
    Numeric = false,
    Finished = true,
    Callback = function(Value)
        if Value == "RemakeOfJorlHub1233333YOUNGPERSONONTHEBLOCKWHAT" or "RemakeOfJorlHub1233333YOUNGPERSONONTHEBLOCKWHAT " or " RemakeOfJorlHub1233333YOUNGPERSONONTHEBLOCKWHAT" then
            -- Setups (Experimental)
local cloneref = cloneref or function(a) return a end
local Players = cloneref(game:GetService("Players")) or game:GetService("Players") or game.Players
local Plr = cloneref(game.Players.LocalPlayer) or Players.LocalPlayer or game.Players.LocalPlayer
local Char = cloneref(Plr.Character) or cloneref(Plr.CharacterAdded:Wait()) or Plr.Character or Plr.CharacterAdded:Wait()
local Hum = cloneref(Char:FindFirstChild("Humanoid")) or cloneref(Char:WaitForChild("Humanoid")) or Players.LocalPlayer.Character:WaitForChild("Humanoid")
local Hrp = cloneref(Char:FindFirstChild("HumanoidRootPart")) or cloneref(Char:WaitForChild("HumanoidRootPart")) or Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")
local Workspace = cloneref(game:GetService("Workspace")) or game:GetService("Workspace") or game.Workspace or game.workspace
local Version = "Version 3"
-- End of Setups (Experimental)

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Jorl Hub",
    SubTitle = "Created.. Organized, by Waylon.",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false, 
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl 
})


    local Tabs = {
        Main = Window:AddTab({ Title = "Universal", Icon = "" }),
        Settings = Window:AddTab({ Title = "Settings", Icon = "" }),
        AG = Window:AddTab({ Title = "All Games", Icon = "" }),
        TSB = Window:AddTab({ Title = "The Strongest Battlegrounds", Icon = "" }),
        JJI = Window:AddTab({ Title = "Jujutsu Infinite", Icon = "" }),
        SMS = Window:AddTab({ Title = "Supermarket Simulator", Icon = "" }),
        BF = Window:AddTab({ Title = "Blox Fruits", Icon = "" }),
        BL = Window:AddTab({ Title = "Blue Lock: Rivals", Icon = "" }),
        CW = Window:AddTab({ Title = "Combat Warriors", Icon = "" }),
        DH = Window:AddTab({ Title = "Da Hood", Icon = "" }),
        SH = Window:AddTab({ Title = "Sweet Home", Icon = "" }),
        RV = Window:AddTab({ Title = "Rivals", Icon = "" }),
        NL = Window:AddTab({ Title = "Ninja Legends", Icon = "" }),
        FC = Window:AddTab({ Title = "Fisch", Icon = "" }),
        AUT = Window:AddTab({ Title = "A Universal Time", Icon = "" }),
        DSBA = Window:AddTab({ Title = "Burning Ashes New Era / Demon Slayer Burning Ashes", Icon = "" }),
        Ars = Window:AddTab({ Title = "Arsenal", Icon = "" }),
        Bds = Window:AddTab({ Title = "Baddies", Icon = "" }),
        BN2 = Window:AddTab({ Title = "Break in 2", Icon = "" }),
        LT2 = Window:AddTab({ Title = "Lumber Tycoon 2", Icon = "" }),
        JJS = Window:AddTab({ Title = "Jujutsu Shenanigans", Icon = "" }),
        Sab = Window:AddTab({ Title = "Steal A Brainrot", Icon = "" })

}

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Fluent:Notify({
    Title = "Welcome",
    Content = "Welcome to Jorl Hub!",
    SubContent = "COUNTRY ROADS!!! TAKE ME HOME!", 
    Duration = 10
})

local function Divide(Name, Tab)
    local Section = Tab:AddSection(Name)
end


Tabs.Main:AddButton({
    Title = "Reset",
    Description = "Kills you!",
    Callback = function()
        if Hum.Health then
        Hum.Health=0
        else
            Fluent:Notify({
                Title = "Failed",
                Content = "The command failed",
                SubContent = "Report it to the owner", 
                Duration = 10
            })
        end
    end
})

Divide("Local Player", Tabs.Main)

local LockedWalkSpeed = Hum.WalkSpeed or Hum.WalkSpeed

local Slider = Tabs.Main:AddSlider("Slider", {
    Title = "WalkSpeed Changer",
    Description = "Constant Updater To Speed Walking",
    Default = LockedWalkSpeed,
    Min = 0,
    Max = 600,
    Rounding = 1,
    Callback = function(Value)
        LockedWalkSpeed = Value
    end
})

task.spawn(function()
    while task.wait(0.1) do
        if Hum and Hum.WalkSpeed ~= LockedWalkSpeed then
            Hum.WalkSpeed = LockedWalkSpeed
        end
    end
end)




local LockedJumpPower = Hum.JumpPower or math.huge

local Slider = Tabs.Main:AddSlider("Slider", {
    Title = "JumpPower Changer",
    Description = "Changes how high you jump",
    Default = LockedJumpPower,
    Min = 0,
    Max = 200,
    Rounding = 1,
    Callback = function(Value)
        LockedJumpPower = Value
    end
})

task.spawn(function()
    while task.wait(0.1) do
        if Hum then
            Hum.UseJumpPower = true
            if Hum.JumpPower ~= LockedJumpPower then
                Hum.JumpPower = LockedJumpPower
            end
        end
    end
end)



local LockedGravity = workspace.Gravity

local Slider = Tabs.Main:AddSlider("Slider", {
    Title = "Gravity Changer",
    Description = "Changes game gravity",
    Default = LockedGravity,
    Min = 0,
    Max = 200,
    Rounding = 1,
    Callback = function(Value)
        LockedGravity = Value
    end
})

task.spawn(function()
    while task.wait(0.1) do
        if workspace.Gravity ~= LockedGravity then
            workspace.Gravity = LockedGravity
        end
    end
end)

Divide("Other Scripts", Tabs.Main)
Tabs.Main:AddButton({
    Title = "Infinite Yield",
    Description = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end
})

Tabs.Main:AddButton({
    Title = "Dex [File Explorer]",
    Description = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
    end
})

Divide("Scripts", Tabs.Sab)
Tabs.Sab:AddButton({
    Title = "Lumin Hub",
    Description = "",
    Callback = function()
        loadstring(game:HttpGet("https://lumin-hub.lol/loader.lua",true))()
    end
})

Tabs.Sab:AddButton({
    Title = "Xenith Hub",
    Description = "",
    Callback = function()
        loadstring(game:HttpGet("https://api.luarmor.net/files/v4/loaders/d7be76c234d46ce6770101fded39760c.lua"))()
    end
})

Tabs.SH:AddButton({
    Title = "Jorl Hub Sweet Home Script",
    Description = "Exclusive to Jorl Hub",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/welomenchaina/Sourced10/refs/heads/main/SweetHome",true))()
    end
})

Tabs.DH:AddButton({
    Title = "Faded Hub",
    Description = "Click to run one of the best dahood scripts",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/NighterEpic/Faded-Grid/main/YesEpic"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("Faded Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})


Tabs.SH:AddButton({
    Title = "Anxiety Hub",
    Description = "Click to run one of the best Sweet Home scripts.",
    Callback = function()
        local scriptUrl = "https://pastebin.com/raw/banGHfYg"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("Anxiety Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})





Tabs.TSB:AddButton({
    Title = "Sans",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/Qaiddanial2904/ROBLOX-FREAKY-GOJO-REAL/refs/heads/main/SANS%20%5BREDACTED%5D"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})




Tabs.AG:AddButton({
    Title = "Unc Test",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://rawscripts.net/raw/Universal-Script-UNC-Test-13114"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.AG:AddButton({
    Title = "Infinite Yield",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.AG:AddButton({
    Title = "Vfly Gui",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "raw.githubusercontent.com/S33dedL0rdz/-Unknown-Roblox-Vfly-Script-.file/main/Rbxscript.c"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})


Tabs.AG:AddButton({
    Title = "FLY GUI V3!",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://rawscripts.net/raw/Universal-Script-Fly-Gui-V3-17541"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})


Tabs.AG:AddButton({
    Title = "Chat bypasser",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/shadow62x/catbypass/main/upfix"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.AG:AddButton({
    Title = "Ghost Hub",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/GhostPlayer352/Test4/main/GhostHub"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.TSB:AddButton({
    Title = "Toji",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/BronzeScripts/tsbg/refs/heads/main/Toji"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.TSB:AddButton({
    Title = "Gojo Normal",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/FoiLONE/Gojo-Moveset-TSB-by-Raga/main/1725724019929-Gojo.txt"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})



Tabs.TSB:AddButton({
    Title = "Hakari (Not Nosakatan)",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://pastebin.com/raw/eEDYWj8p"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})


Tabs.RV:AddButton({
    Title = "Rybowe Hub",
    Description = "Click to run one of the best Rivals scripts.",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/rybowe/rybowescripts/main/release.lua"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})


Tabs.NL:AddButton({
    Title = "Ninja Legends",
    Description = "Shady shit bro",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/welomenchaina/sourced5/refs/heads/main/Sourced5"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.FC:AddButton({
    Title = "Fisch Auto fish",
    Description = "Click this to start Auto Fishing!",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/welomenchaina/Sourced6/refs/heads/main/Sourced6"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.FC:AddButton({
    Title = "Porn Hub - might be broken",
    Description = "Click this to start Auto Fishing!",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/LHking123456/r3hsg8nudf6j4/refs/heads/main/Fisch"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.FC:AddButton({
    Title = "Goomba Hub - might be broken",
    Description = "Click this to start Goomba Hub!",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/JustLevel/goombahub/main/fisch.lua"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.AUT:AddButton({
    Title = "Flame Hub",
    Description = "Click this to start Flame Hub!",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/FlamesW/NEW/main/Launcher"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.AUT:AddButton({
    Title = "Lazy Hub",
    Description = "Click this to start Lazy Hub!",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/LioK251/RbScripts/main/loader.lua"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.DSBA:AddButton({
    Title = "Mikey Hub",
    Description = "Click this to start Lazy Hub!",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/RobloxScriptHub/MikeyHub-V2/main/Loader/Main"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.TSB:AddButton({
    Title = "Sukuna",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/zyrask/Nexus-Base/main/atomic-blademaster%20to%20sukuna"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})


Tabs.TSB:AddButton({
    Title = "Jester/Arcaura",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/Reapvitalized/TSB/refs/heads/main/ARCAURA.lua"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})



Tabs.TSB:AddButton({
    Title = "Jotaro",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/h8h88/hubfr/main/hubfr"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})


Tabs.TSB:AddButton({
    Title = "Naruto",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://pastebin.com/raw/Da0AwazD"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.TSB:AddButton({
    Title = "Sonic The HedgeHog",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://pastebin.com/raw/7V1mUBtQ"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.TSB:AddButton({
    Title = "Apophenia V2",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://pastefy.app/A0j3KKfK/raw"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.TSB:AddButton({
    Title = "Jun",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/Kenjihin69/Kenjihin69/refs/heads/main/Tp%20exploit%20saitama%20to%20jun"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.TSB:AddButton({
    Title = "Deku",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://pastefy.app/MNg2zcxz/raw"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.TSB:AddButton({
    Title = "Kazuma",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://rawscripts.net/raw/The-Strongest-Battlegrounds-kazuma-kiryu-moveset-17198"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.TSB:AddButton({
    Title = "Gojo",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/skibiditoiletfan2007/BaldyToSorcerer/main/Latest.lua"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.TSB:AddButton({
    Title = "Freaky Gojo",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/Qaiddanial2904/ROBLOX-FREAKY-GOJO-REAL/refs/heads/main/FREAKY%20FR%20GOJO"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.TSB:AddButton({
    Title = "Nosakatan",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://rawscripts.net/raw/The-Strongest-Battlegrounds-Hero-to-True-Nosakatan-18742"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.TSB:AddButton({
    Title = "Toji",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://pastebin.com/raw/VQnyWP5D"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.TSB:AddButton({
    Title = "Kj",
    Description = "Click to run one of the best TSB scripts.",
    Callback = function()
        local scriptUrl = "https://pastebin.com/raw/JKKZdLN5"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.TSB:AddButton({
    Title = "Kungfu Panda",
    Description = "Click to run one of the best Arsenal scripts.",
    Callback = function()
        local scriptUrl = "https://pastebin.com/raw/DqXUTANt"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.Ars:AddButton({
    Title = "Solaris.lol",
    Description = "Click to run one of the best Aresenal scripts.",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/toasty-dev/pissblox/main/solaris_bootstrapper.lua"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.Ars:AddButton({
    Title = "Thunder Client Solara",
    Description = "Click to run one of the best Arsenal scripts.",
    Callback = function()
        local scriptUrl = "https://api.luarmor.net/files/v3/loaders/b95e8fecdf824e41f4a030044b055add.lua"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})


Tabs.Bds:AddButton({
    Title = "Syrex Hub",
    Description = "Click to run one of the best Baddies scripts.",
    Callback = function()
        local scriptUrl = "https://syrexhub.netlify.app/raw/syrexhub"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})


Tabs.Bds:AddButton({
    Title = "Demonic hub",
    Description = "Click to run one of the best Baddies scripts.",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/Prosexy/Demonic-HUB-V2/main/DemonicHub_V2.lua"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.BN2:AddButton({
    Title = "Starry hub",
    Description = "Click to run one of the best Break In 2 scripts.",
    Callback = function()
        local scriptUrl = "https://www.cloudbin.org/love"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})


Tabs.RV:AddButton({
    Title = "Cracked",
    Description = "Click to run one of the best Rivals scripts.",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/cracklua/cracks/m/SilentRivals"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.RV:AddButton({
    Title = "God Hub",
    Description = "Click to run one of the best Rivals scripts.",
    Callback = function()
        local scriptUrl = "https://api.luarmor.net/files/v3/loaders/c56622b9897b159614c3e7889571afd5.lua"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.RV:AddButton({
    Title = "Nexam hub",
    Description = "Click to run one of the best Rivals scripts.",
    Callback = function()
        local scriptUrl = "https://api.luarmor.net/files/v3/loaders/e14fc8a88047414dae10ea96adf47f53.lua"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.FC:AddButton({
    Title = "Speed Hub",
    Description = "Click to run one of the best Fisch scripts.",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/AhmadV99/Speed-Hub-X/main/Speed%20Hub%20X.lua"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})


Tabs.LT2:AddButton({
    Title = "Kron Hub",
    Description = "Click to run one of the best Lumber Tycoon scripts.",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/DevKron/Kron_Hub/refs/heads/main/version_1.0"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.LT2:AddButton({
    Title = "Butter Hub",
    Description = "Click to run one of the best Lumber Tycoon scripts.",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/Butterisgood/Butter/main/Root2.lua"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.FC:AddButton({
    Title = "Speed Hub X",
    Description = "Click to run one of the best Fisch Scripts",
    Callback = function()
        local scriptUrl = "https://pastebin.com/raw/fDyAyZkU"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.TSB:AddButton({
    Title = "Titan Speaker Man",
    Description = "This is from the popular show skibidi toliet",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/softbf395/TSB-movesets/refs/heads/main/Titan%20TV%20man.lua"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.TSB:AddButton({
    Title = "Garou - Okarun",
    Description = "Turbo Granny!",
    Callback = function()
        local scriptUrl = "https://paste.ee/r/Pn4oj"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.TSB:AddButton({
    Title = "GT Chara",
    Description = "Perserverance, Patience, Determination HOLY SHITT!",
    Callback = function()
        local scriptUrl = "https://paste.ee/r/0yYkO"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})


Tabs.TSB:AddButton({
    Title = "Akaza",
    Description = "I only eat women's Pussy!",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/welomenchaina/Sourced8/refs/heads/main/Sourced8"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.JJI:AddButton({
    Title = "Vintu Hub",
    Description = "Luarmor - (Many executors not supported)",
    Callback = function()
        local scriptUrl = "https://api.luarmor.net/files/v3/loaders/f9caf82bff389f078eb1641ac0c0c131.lua"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.JJI:AddButton({
    Title = "Imp Hub",
    Description = "Jujutsu Infinite Script On Top",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/alan11ago/Hub/refs/heads/main/ImpHub.lua"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.JJI:AddButton({
    Title = "Solix Hub",
    Description = "Jujutsu Infinite Script On Top",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/debunked69/Solixreworkkeysystem/refs/heads/main/solix%20new%20keyui.lua"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.CW:AddButton({
    Title = "Stratos Hub",
    Description = "I summon thee the warrior of combat",
    Callback = function()
        local scriptUrl = "https://pastefy.app/h6W47mhM/raw"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.CW:AddButton({
    Title = "Shub V2 hub",
    Description = "I summon thee the warrior of combat",
    Callback = function()
        local scriptUrl = "https://pastefy.app/50B4Z9UK/raw"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.BL:AddButton({
    Title = "Noname Hub",
    Description = "LOCK IN AND GET BLUE",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/SkibidiCen/MainMenu/main/Code"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.BL:AddButton({
    Title = "Express Hub",
    Description = "LOCK IN AND GET BLUE",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/Theyfwdan/Theyfwdan/refs/heads/main/ExpressHubPaidVersion"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.BL:AddButton({
    Title = "Sendox Hub",
    Description = "LOCK IN AND GET BLUE",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/Mc4121ban/RobloxScirpt/refs/heads/main/ScriptHub"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.BL:AddButton({
    Title = "Freak Hub",
    Description = "LOCK IN AND GET BLUE",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/EXploitsgg/Fuck_Hub_Bluelockrivals/refs/heads/main/Fuck-Hub"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.BF:AddButton({
    Title = "Solix Hub",
    Description = "HOLY FUCKING SHIT ZEAHHAAHAHAHAHHAHAH",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/debunked69/Solixreworkkeysystem/refs/heads/main/solix%20new%20keyui.lua"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.BF:AddButton({
    Title = "Redz Hub",
    Description = "HOLY FUCKING SHIT ZEAHHAAHAHAHAHHAHAH",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/realredz/BloxFruits/refs/heads/main/Source.lua"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.BF:AddButton({
    Title = "Blacktrap",
    Description = "HOLY FUCKING SHIT ZEAHHAAHAHAHAHHAHAH",
    Callback = function()
        local scriptUrl = "https://lua-library.btteam.net/script-auth.txt"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.SMS:AddButton({
    Title = "Aqua Hub",
    Description = "Its supah dupah Markety",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/ExploiterGuy/Aqua-Hub/refs/heads/main/Supermarket%20Simulator%20%5BOPEN%20SOURCE%5D"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.SMS:AddButton({
    Title = "Aqua Hub",
    Description = "Its supah dupah Markety",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/Whoisgrace0/Main/main/LOL.lua"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.CC2:AddButton({
    Title = "Car Crushers II",
    Description = "Auto Farm & More",
    Callback = function()
        local scriptUrl = "https://rawscripts.net/raw/New-Car-Car-Crushers-2-BEST-AUTOFARM-AND-MORE-7496"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.DDRS:AddButton({
    Title = "Doors",
    Description = "Ong best doors script",
    Callback = function()
        local scriptUrl = "https://rawscripts.net/raw/DOORS-Astral-24468"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.PWS:AddButton({
    Title = "Pressure Washing Sim",
    Description = "Auto Farm & More",
    Callback = function()
        local scriptUrl = "lhttps://pastebin.com/raw/EfWuwtiS"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.ZA:AddButton({
    Title = "Zombie Attack",
    Description = "OP Zombie Attack",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/EclipseHub/Eclipse/main/Eclipse.lua"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.JJS:AddButton({
    Title = "Grimmjow",
    Description = "Pantera...... (Yuji)",
    Callback = function()
        local scriptUrl = "https://raw.githubusercontent.com/welomenchaina/Sourced8/refs/heads/main/Sourced8"
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl, true))()
        end)
        if success then
            print("TSB Script Executed with 100% ACCURACY!")
        else
            warn("Failed to execute script: " .. tostring(err))
        end
    end,
    Style = buttonStyle
})

Tabs.TSB:AddButton({
    Title = "Itachi (Exclusive, Non Tested)",
    Description = "GOT SOME TOP FROM THIS SEXY NIGGA HE FROM TENNESSEEE!!! SEARCH GAY NIGGERS ON 24KF LIFEEEE!!!",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/welomenchaina/Sourced10/refs/heads/main/GOONCENTRAL",true))()
    end
})


Window:SelectTab(1)
            Fluent:Notify({
                Title = "Key Accepted",
                Content = "Welcome to Jorl Hub!",
                Duration = 5
            })
        else
            Fluent:Notify({
                Title = "Invalid Key",
                Content = "That key is incorrect.",
                Duration = 5
            })
        end
    end
})


