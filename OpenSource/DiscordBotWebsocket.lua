-- improved version of https://github.com/random-projects-coz-bored-and-ye/Websocket-Discord-bot/tree/main 

local init = loadstring(game:HttpGet("https://raw.githubusercontent.com/welomenchaina/MainProjects/refs/heads/main/Systems/AuraicFunctions.lua",true))()


local ws = WebSocket
local asdasd = ws.connect("ws://127.0.0.1:3000")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("Connected to the websocket :3")

asdasd.OnMessage:Connect(function(msg)
    local textToSay = string.match(msg, "^say%s+(.*)")
    if textToSay then
        print("Detected text:", textToSay)
        local localPlayer = Players.LocalPlayer

        if TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService then
        ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(textToSay, "All")
        else
        local channels = TextChatService.TextChannels
        local general = channels.RBXGeneral

        general:SendAsync(textToSay)
    end
        end

    if msg == "kill" then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        humanoid:ChangeState(Enum.HumanoidStateType.Dead)
        print("killed :3")
    end

    if msg == "rejoin" then
        local ts = game:GetService("TeleportService")
        local p = game:GetService("Players").LocalPlayer
        ts:Teleport(game.PlaceId, p)
        print("Rejoining :3")
    end
end)


local Players = game:GetService("Players")
local p = game.Players.LocalPlayer


if msg == "crash" then
    while true do
        print ("crashing..")
    end
init:Kick("Bye..")
end

getgenv().FreezeActive=nil
if msg == "freeze" then
    getgenv().FreezeActive=true
local f=false
init:Freeze()
task.spawn(function()
    while task.wait(0.1) do
        if getgenv().FreezeActive then
            for _,v in ipairs(init:getCoreParts()) do
                if v:IsA("BasePart") and not v.Anchored then
                    if not f then getgenv().FreezeTriggered=true f=true end
                    init:Freeze()
                    break
                end
            end
        end
    end
end)

if msg == "thaw" then
    getgenv().FreezeActive = false
    init:Thaw()
end