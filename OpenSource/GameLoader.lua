if not game:IsLoaded() then repeat task.wait() until game:IsLoaded() end

local cloneref = cloneref or function(v) return v end
local Players = cloneref(game:GetService("Players"))
local Pl = cloneref(Players.LocalPlayer) or Players.PlayerAdded:Wait()
local Char = cloneref(Pl.Character) or Pl.Character or Pl.CharacterAdded:Wait()
local Hum = Char:FindFirstChild("Humanoid") or Char:WaitForChild("Humanoid")
local Hrp = Char:FindFirstChild("HumanoidRootPart") or Char:WaitForChild("HumanoidRootPart")
local rawGameId = tostring(game.GameId or game.PlaceId or 0)
local rawPlaceId = tostring(game.PlaceId or 0)

local function safeNotify(t)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", t)
    end)
end

local function httpGet(url)
    local ok, res
    local try = {
        function(u) return pcall(function() res = game:HttpGet(u, true) end) end,
        function(u) return pcall(function() res = HttpGet and HttpGet(u) end) end,
        function(u) return pcall(function() res = (syn and syn.request and syn.request{Url=u, Method="GET"} and syn.request{Url=u, Method="GET"}.Body) end) end,
        function(u) return pcall(function() res = (request and request{Url=u, Method="GET"} and request{Url=u, Method="GET"}.Body) end) end,
        function(u) return pcall(function() res = (http and http.request and http.request{Url=u, Method="GET"} and http.request{Url=u, Method="GET"}.Body) end) end
    }
    for _,fn in ipairs(try) do
        local s = fn(url)
        if s and res then return res end
    end
    return nil
end

local function safeLoad(url, name)
    local ok,body = pcall(httpGet, url)
    if not ok or not body or #body == 0 then
        safeNotify({Title = "Load failed"; Text = (name or url) .. " couldn't be fetched"; Duration = 4})
        return false
    end
    local f,err = loadstring(body)
    if not f then
        safeNotify({Title = "Compile error"; Text = (name or url); Duration = 4})
        return false
    end
    local suc,ret = pcall(f)
    if not suc then
        safeNotify({Title = "Runtime error"; Text = tostring(ret); Duration = 4})
        return false
    end
    return true
end

local loadedCache = {}

local function runMapping(m)
    local url = m.url
    local name = m.name or url
    if not url then return end
    if loadedCache[url] then return end
    task.spawn(function()
        local ok = safeLoad(url, name)
        if ok then
            loadedCache[url] = true
        end
    end)
end

local games = {
    ["game_place:8340680684:78296331391950"] = {url = "https://raw.githubusercontent.com/welomenchaina/MainProjects/refs/heads/main/Obfuscated/OneBlockScript.lua", name = "OneBlockMain"},
    ["game:8340680684"] = {notify = {Title="You need to be in the game"; Text="Go into the main game"; Duration=5}},
    ["game_generic:115235776084989"] = {url = "https://raw.githubusercontent.com/welomenchaina/Sourced10/refs/heads/main/SweetHome", name = "SweetHome"},
    ["game_generic:192800"] = {url = "https://raw.githubusercontent.com/welomenchaina/Loader/refs/heads/main/ScriptLoader", name = "ScriptLoader"},
    ["game_generic:13864661000"] = {url = "https://raw.githubusercontent.com/welomenchaina/Loader/refs/heads/main/ScriptLoader", name = "ScriptLoader"},
    ["game_generic:18687417158"] = {url = "https://raw.githubusercontent.com/welomenchaina/Loader/refs/heads/main/ScriptLoader", name = "ScriptLoader"},
    ["game_generic:126884695634066"] = {url = "https://raw.githubusercontent.com/welomenchaina/MainProjects/refs/heads/main/Ancient/AncientLoader.lua", name = "AncientLoader"},
    ["always"] = {url = "https://raw.githubusercontent.com/welomenchaina/Loader/refs/heads/main/ScriptLoader", name = "FallbackLoader"},
    ["game_generic:79546208627805"] = {url = "https://raw.githubusercontent.com/welomenchaina/MainProjects/refs/heads/main/Ancient/AncientLoader.lua", name = "AncientLoader"},
    ["game_generic:109983668079237"] = {url = "https://raw.githubusercontent.com/welomenchaina/Loader/refs/heads/main/DesireHubV2", name = "DesireHubV2"},
    ["game_generic:2376885433"] = {url = "https://raw.githubusercontent.com/welomenchaina/Loader/refs/heads/main/ScriptLoader", name = "ScriptLoader"}
}

local function lookupAndRun(gid, pid)
    local keyExact = ("game_place:%s:%s"):format(gid, pid)
    local keyGame = ("game:%s"):format(gid)
    local keyGeneric = ("game_generic:%s"):format(gid)
    if games[keyExact] then
        local m = games[keyExact]
        if m.url then runMapping(m) else if m.notify then pcall(safeNotify, m.notify) end end
        return true
    end
    if games[keyGeneric] then
        runMapping(games[keyGeneric])
        return true
    end
    if games[keyGame] then
        local m = games[keyGame]
        if m.url then runMapping(m) else if m.notify then pcall(safeNotify, m.notify) end end
        return true
    end
    if games["always"] then
        runMapping(games["always"])
        return true
    end
    return false
end

local success = lookupAndRun(rawGameId, rawPlaceId)
if not success then
    safeNotify({Title="No mapping"; Text="No script mapped for this game"; Duration=4})
end
