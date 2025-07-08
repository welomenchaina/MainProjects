local Players = game:GetService("Players")
local Plr = game.Players.LocalPlayer
local Char = Plr.Character
local humanoid = Char.Humanoid
local hrp = humanoidRootPart
local RunService = game:GetService("RunService")


local GameInformation = "https://raw.githubusercontent.com/welomenchaina/GoofyScripts/refs/heads/main/InformationPuller.lua"
local HealthSystem = "https://raw.githubusercontent.com/welomenchaina/MainProjects/refs/heads/main/HealthSystem.lua"
-- functions for the health system remember gethealth(), sethealth(), takehealth()

local function load(link)
    loadstring(game:HttpGet(link, true))()
end

load(HealthSystem)
load(GameInformation)

local function getplayersteam()
return Plr.Team
end


local Window = Luna:CreateWindow({
	Name = "Shark ESP 🦈 | " .. gameName,
	Subtitle = "Built with Luna",
	LogoID = "124233157237852", 
	LoadingEnabled = true,
	LoadingTitle = "Loading Shark ESP...",
	LoadingSubtitle = "Shh, you are my favorite user but.. don't tell the others!",

	ConfigSettings = {
		ConfigFolder = "SharkESP"
	},

	KeySystem = false,
	KeySettings = {
		Title = "Shark ESP Key",
		Subtitle = "Enter Key Below",
		Note = "Join our Discord to get your key.",
		SaveKey = true,
		Key = {"your-key-here"},
		SecondAction = {
			Enabled = true,
			Type = "discord",
			Parameter = "YourDiscordID" 
		}
	}
})

