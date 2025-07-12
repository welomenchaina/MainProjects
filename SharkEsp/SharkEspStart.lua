

local SharkFile = "https://raw.githubusercontent.com/welomenchaina/MainProjects/refs/heads/main/SharkEsp.lua"

local function load(link)
    loadstring(game:HttpGet(link, true))()
end

local function waituntil()
    repeat task.wait() until game:IsLoaded()
    return game:IsLoaded()
end

if not game:IsLoaded() then
    waituntil()
end

if game:IsLoaded() then
    load(SharkFile)
end
