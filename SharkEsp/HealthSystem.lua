local function gethealth()
return game.Players.LocalPlayer.Character.Humanoid.Health
end

local UseSettings = nil

if UseSettings == true then
getgenv().InfiniteHp = nil -- this is client sided and wont actually work
getgenv().HealthToTake = 0
getgenv().SetHealthTo = 0 -- change to desired health amount this is server sided
else
game.Players.LocalPlayer.Character.Humanoid.Health = gethealth()
end

local function checkall()
local plr = game.Players.LocalPlayer
local char = plr.Character
local humanoid = char.Humanoid
local hrp = humanoidRootPart

if plr and char and humanoid and hrp then
if not game:IsLoaded() then
 repeat task.wait() until game:IsLoaded()
end
end
end

checkall()

local function sethealth(health)
    game.Players.LocalPlayer.Character.Humanoid.Health = health
end



local function takehealth(health)
local plr = game.Players.LocalPlayer
local hum = plr.Character.Humanoid
local h = hum.Health
if plr and hum and h then
hum:TakeDamage(health)
end
end

local humanoidhealth = game.Players.LocalPlayer.Character.Humanoid.Health

humanoidhealth = gethealth()

local function infinitehp()
-- note this isnt real and will not work this is client sided
humanoidhealth = math.huge
end

takehealth(getgenv().HealthToTake)

if getgenv().SetHealthTo == 0 or nil then
humanoidhealth = gethealth()
else
sethealth(getgenv().SetHealthTo)
end

if getgenv().InfiniteHp then
infinitehp()
else
humanoidhealth = gethealth()
end
