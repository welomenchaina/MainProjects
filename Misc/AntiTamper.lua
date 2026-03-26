repeat task.wait() until game:IsLoaded()

local lp = game:GetService("Players").LocalPlayer
local run = game:GetService("RunService")
local mps = game:GetService("MarketplaceService")

local msg = "cheat detected, get rekt lol"

local function busted(why)
	warn("[!!] " .. msg .. " | " .. why)
end

local mt = getrawmetatable(game)
local _nc = mt.__namecall
local _idx = mt.__index
setreadonly(mt, false)

mt.__index = newcclosure(function(self, k)
	local src = debug.info(2, "s")
	if (k == "Source" or k == "Bytecode") and not checkcaller() and src ~= "[C]" then
		busted("src/bytecode read from " .. tostring(src))
		return ""
	end
	return _idx(self, k)
end)

mt.__namecall = newcclosure(function(self, ...)
	local method = getnamecallmethod()
	local src = debug.info(2, "s")

	if not checkcaller() and src ~= "[C]" then
		if method == "require" then
			busted("require() hook")
			return nil
		end

		if method == "Clone" and (self:IsA("LocalScript") or self:IsA("ModuleScript")) then
			busted("script clone attempt")
			return nil
		end

		if method == "GetDescendants" or method == "GetChildren" then
			local res = _nc(self, ...)
			if type(res) == "table" then
				local clean = {}
				for _, obj in ipairs(res) do
					if not (obj:IsA("LocalScript") or obj:IsA("ModuleScript")) then
						table.insert(clean, obj)
					end
				end
				return clean
			end
			return res
		end
	end

	return _nc(self, ...)
end)

setreadonly(mt, true)

local gameInfo = mps:GetProductInfo(game.PlaceId)

local expectedTypes = {
	Name = "string",
	Description = "string",
	Creator = "table",
	CreatorType = "string",
	CreatorId = "number",
	AssetId = "number",
	IsForSale = "boolean",
	ProductType = "string",
	Updated = "string",
	Created = "string",
	IconImageAssetId = "number",
	IsPublicDomain = "boolean",
}

local snap = {
	AssetId = gameInfo.AssetId,
	CreatorId = gameInfo.CreatorId,
	Name = gameInfo.Name,
}

local function chkGame()
	local ok, fresh = pcall(function() return mps:GetProductInfo(game.PlaceId) end)
	if not ok then busted("mps fetch failed") return end

	for key, expectedType in pairs(expectedTypes) do
		if fresh[key] ~= nil and type(fresh[key]) ~= expectedType then
			busted(key .. " wrong type, expected " .. expectedType .. " got " .. type(fresh[key]))
		end
	end

	if fresh.AssetId ~= snap.AssetId then busted("AssetId flipped") end
	if fresh.CreatorId ~= snap.CreatorId then busted("CreatorId changed") end
	if fresh.Name ~= snap.Name then busted("game name changed") end
	if fresh.AssetId ~= game.PlaceId then busted("placeid mismatch") end
	if type(fresh.Creator) ~= "table" or fresh.Creator.Id ~= snap.CreatorId then
		busted("creator table weird")
	end
end

local function chkGc()
	local n = 0
	for _, f in ipairs(getgc()) do
		if type(f) == "function" and not islclosure(f) then n+=1 end
	end
	if n > 5000 then busted("gc flooded: " .. n) end
end

local function chkSpoofs()
	local dummy = Instance.new("Part")
	if typeof(dummy) ~= "Instance" then busted("typeof spoofed") end
	dummy:Destroy()
	if typeof(game) ~= "DataModel" then busted("game obj spoofed") end
	if type(print) ~= "function" then busted("type() spoofed") end
end

local function chkDebug()
	if not islclosure(debug.getupvalues) and not isexecutorclosure(debug.getupvalues) then
		busted("debug.getupvalues hooked")
	end
end

local function chkMt()
	local cur = getrawmetatable(game)
	if cur.__namecall ~= mt.__namecall then busted("__namecall swapped") end
	if cur.__index ~= mt.__index then busted("__index swapped") end
end

run.Heartbeat:Connect(chkMt)

task.spawn(function()
	while task.wait(5) do
		pcall(chkGc)
		pcall(chkSpoofs)
		pcall(chkDebug)
		pcall(chkGame)
	end
end)

pcall(chkSpoofs)
pcall(chkDebug)
pcall(chkGame)

warn("antitamper on")
