local Players = game:GetService("Players")
local Plr = game.Players.LocalPlayer
local Char = Plr.Character
local humanoid = Char.Humanoid
local hrp = humanoidRootPart

local Window = Luna:CreateWindow({
	Name = "Shark ESP",
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
			Parameter = "YourDiscordID" -- like "sharkhub" for discord.gg/sharkhub
		}
	}
})

