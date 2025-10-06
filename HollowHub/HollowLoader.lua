

if not game:IsLoaded() then repeat task.wait() until game:IsLoaded() end

local cloneref = cloneref or function(v) return v end

local Players = cloneref(game:GetService("Players"))
local workspace = cloneref(game:GetService("Workspace"))

local Pl = cloneref(Players.LocalPlayer) or Players.LocalPlayer
local Char = cloneref(Pl.Character) or cloneref(Pl.Character) or cloneref(Pl.CharacterAdded:Wait()) or Pl.Character or Pl.CharacterAdded:Wait()
local Hum = cloneref(Char:FindFirstChild("Humanoid")) or cloneref(Char:WaitForChild("Humanoid")) or Char:FindFirstChild("Humanoid") or Char:FindFirstChildOfClass("Humanoid") or Char:WaitForChild("Humanoid") or Char.Humanoid
local Hrp = cloneref(Char:FindFirstChild("HumanoidRootPart")) or cloneref(Char:WaitForChild("HumanoidRootPart")) or Char:FindFirstChild("HumanoidRootPart") or Char:WaitForChild("HumanoidRootPart") or Char.HumanoidRootPart
local gID = tostring(game.GameId or game.PlaceId or 0)
local pID = tostring(game.PlaceId or 0)
local pUID = Pl.UserId

local function PivotTo(Cframe)
    if not Cframe then return end
    Char:PivotTo(CFrame.new(Cframe))
end

local Games = {
    [115235776084989] = function() 
        
    end,
    [192800] = function()
        print("Running script for game 192800")
    end
}

task.wait(2)
local func = Games[tonumber(gID)]
if func then
    func()
else
    
end
