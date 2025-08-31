if not game:IsLoaded() then
    repeat task.wait() until game:IsLoaded()
end

local cloneref = cloneref or function(...) return ... end
local Players = cloneref(game:GetService("Players"))
local Lp = cloneref(Players.LocalPlayer)
local Character = cloneref(Lp.Character or Lp.CharacterAdded:Wait())
local Humanoid = cloneref(Character:WaitForChild("Humanoid"))
local HumanoidRootPart = cloneref(Character:WaitForChild("HumanoidRootPart"))
local MarketplaceService = cloneref(game:GetService("MarketplaceService"))
local placeName = cloneref(MarketplaceService:GetProductInfo(game.PlaceId).Name)
local Workspace = cloneref(game:GetService("Workspace"))

getgenv().Speed = nil
getgenv().Gravity = nil
getgenv().JumpPower = nil

getgenv().Presets = {
    WalkSpeed = getgenv().Speed or Humanoid.WalkSpeed,
    Gravity = getgenv().Gravity or Workspace.Gravity,
    JumpPower = getgenv().JumpPower or Humanoid.JumpPower
}

spawn(function()
    while true do
        task.wait(0.03) 
        Humanoid.WalkSpeed = getgenv().Presets.WalkSpeed
        Workspace.Gravity = getgenv().Presets.Gravity
        Humanoid.JumpPower = getgenv().Presets.JumpPower
        Humanoid.UseJumpPower = true
    end
end)



local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Lateral Hub",
   LoadingTitle = "TRAIN THAT SHIT *Augh..*",
   LoadingSubtitle = "Gooning Lair 🤜🥩",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "LateralHub",
      FileName = "KaydenceAndFaelen"
   },
   Discord = {
      Enabled = false,
      Invite = "",
      RememberJoins = false
   },
   KeySystem = true
})

local main = Window:CreateTab("Main", 4483362458) 

local Input = Tab:CreateInput({
    Name = "Walkspeed Changer",
    CurrentValue = "",
    PlaceholderText = "60",
    RemoveTextAfterFocusLost = true,
    Flag = "Input1",
    Callback = function(Text)
getgenv().Speed = Text
    end,
 })

 local Input = Tab:CreateInput({
    Name = "JumpPower Changer",
    CurrentValue = "",
    PlaceholderText = "196.2",
    RemoveTextAfterFocusLost = true,
    Flag = "Input2",
    Callback = function(Text)
getgenv().JumpPower = Text
    end,
 })
 
 local Input = Tab:CreateInput({
    Name = "Gravity Changer",
    CurrentValue = "",
    PlaceholderText = "196.2",
    RemoveTextAfterFocusLost = true,
    Flag = "Input3",
    Callback = function(Text)
getgenv().Gravity = Text
    end,
 })