if not game:IsLoaded() then
    repeat task.wait() until game:IsLoaded()
end

local Players = game:GetService("Players")
local Plr = Players.LocalPlayer
local Char = Plr.Character or Plr.CharacterAdded:Wait()
local Hum = Char:WaitForChild("Humanoid")
local Hrp = Char:WaitForChild("HumanoidRootPart")
local workspace = game:GetService("Workspace")

getgenv().Speed = nil
getgenv().JP = nil
getgenv().Gravity = nil

task.spawn(function()
    while true do
        if not Hum.UseJumpPower then
            Hum.UseJumpPower = true
        end
        task.wait(0.05)
    end
end)

getgenv().Settings = {
    WalkSpeed = getgenv().Speed or Hum.WalkSpeed,
    JumpPower = getgenv().JP or Hum.JumpPower,
    Gravity = getgenv().Gravity or workspace.Gravity
}

getgenv().Services = {
    HttpService = game:GetService("HttpService"),
    RunService = game:GetService("RunService")
    ]

local Settings = getgenv().Settings
local Services = getgenv().Services

task.spawn(function()
    while true do
        Hum.WalkSpeed = Settings.WalkSpeed
        Hum.JumpPower = Settings.JumpPower
        workspace.Gravity = Settings.Gravity
        task.wait(0.05)
    end
end)

