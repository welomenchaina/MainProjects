--[[
    ╔═══════════════════════════════════════════════════════════════════════════════════════╗
    ║   ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗    ██╗   ██╗██╗                         ║
    ║   ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝    ██║   ██║██║                         ║
    ║   ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗    ██║   ██║██║                         ║
    ║   ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║    ██║   ██║██║                         ║
    ║   ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║    ╚██████╔╝██║                         ║
    ║   ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝     ╚═════╝ ╚═╝                         ║
    ║                                                                                       ║
    ║                           Premium UI Library for Roblox                               ║
    ║                                      By Ryu                                           ║
    ╚═══════════════════════════════════════════════════════════════════════════════════════╝
    
    Usage:
        local NexusUI = loadstring(game:HttpGet("YOUR_URL"))()
        local Window = NexusUI:CreateWindow({Title = "My Script"})
]]

local _modules = {}
local _loaded = {}

local function _require(name)
    name = name:gsub("%.", "/")
    
    if _loaded[name] then return _loaded[name] end
    
    local variations = {name, name .. "/init", "NexusUI/" .. name}
    
    for _, path in ipairs(variations) do
        if _modules[path] then
            _loaded[name] = _modules[path]()
            return _loaded[name]
        end
    end
    
    error("Module not found: " .. name)
end


-- Module: Core/Services
_modules["Core/Services"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                       GUI Framework                           ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
    ]]
    
    local Services = {}
    
    local function getService(name)
        local service = game:GetService(name)
        return if cloneref then cloneref(service) else service
    end
    
    Services.TweenService = getService("TweenService")
    Services.UserInputService = getService("UserInputService")
    Services.RunService = getService("RunService")
    Services.Players = getService("Players")
    Services.CoreGui = getService("CoreGui")
    Services.HttpService = getService("HttpService")
    Services.SoundService = getService("SoundService")
    Services.Workspace = getService("Workspace")
    Services.Lighting = getService("Lighting")
    Services.TextService = getService("TextService")
    Services.GuiService = getService("GuiService")
    
    -- Derived values
    Services.LocalPlayer = Services.Players.LocalPlayer
    Services.Camera = Services.Workspace.CurrentCamera
    Services.Mouse = Services.LocalPlayer:GetMouse()
    
    -- Environment check
    Services.IsStudio = Services.RunService:IsStudio()
    
    return Services
    
end

-- Module: Packages/Flipper
_modules["Packages/Flipper"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                       GUI Framework                           ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
    ]]
    
    local Flipper = {}
    
    -- ============================================
    -- SIGNAL (Event System)
    -- ============================================
    
    local Signal = {}
    Signal.__index = Signal
    
    function Signal.new()
        return setmetatable({
            _listeners = {}
        }, Signal)
    end
    
    function Signal:Connect(callback)
        local connection = {
            _callback = callback,
            _connected = true
        }
        
        function connection:Disconnect()
            self._connected = false
        end
        
        table.insert(self._listeners, connection)
        return connection
    end
    
    function Signal:Fire(...)
        for _, connection in ipairs(self._listeners) do
            if connection._connected then
                task.spawn(connection._callback, ...)
            end
        end
    end
    
    Flipper.Signal = Signal
    
    -- ============================================
    -- BASE MOTOR
    -- ============================================
    
    local BaseMotor = {}
    BaseMotor.__index = BaseMotor
    
    function BaseMotor.new()
        return setmetatable({
            _onStep = Signal.new(),
            _onComplete = Signal.new()
        }, BaseMotor)
    end
    
    function BaseMotor:onStep(callback)
        return self._onStep:Connect(callback)
    end
    
    function BaseMotor:onComplete(callback)
        return self._onComplete:Connect(callback)
    end
    
    function BaseMotor:start()
        if self._connection then return end
        
        self._connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
            self:step(dt)
        end)
    end
    
    function BaseMotor:stop()
        if self._connection then
            self._connection:Disconnect()
            self._connection = nil
        end
    end
    
    Flipper.BaseMotor = BaseMotor
    
    -- ============================================
    -- SPRING GOAL
    -- ============================================
    
    local Spring = {}
    Spring.__index = Spring
    
    function Spring.new(targetValue, options)
        options = options or {}
        
        return setmetatable({
            _type = "Spring",
            _targetValue = targetValue,
            _frequency = options.frequency or 4,
            _dampingRatio = options.dampingRatio or 1
        }, Spring)
    end
    
    function Spring:step(state, dt)
        local d = self._dampingRatio
        local f = self._frequency * 2 * math.pi
        local g = self._targetValue
        local p0 = state.value
        local v0 = state.velocity or 0
        
        local offset = p0 - g
        local decay = math.exp(-d * f * dt)
        
        local p1, v1
        
        if d == 1 then
            -- Critically damped
            p1 = (offset * (1 + f * dt) + v0 * dt) * decay + g
            v1 = (v0 * (1 - f * dt) - offset * f * f * dt) * decay
        elseif d < 1 then
            -- Under damped
            local c = math.sqrt(1 - d * d)
            local i = math.cos(f * c * dt)
            local j = math.sin(f * c * dt)
            
            p1 = (offset * i + (v0 + offset * d * f) / (f * c) * j) * decay + g
            v1 = (v0 * i - (v0 * d + offset * f) / c * j) * decay
        else
            -- Over damped
            local c = math.sqrt(d * d - 1)
            local r1 = -f * (d - c)
            local r2 = -f * (d + c)
            local co2 = (v0 - offset * r1) / (2 * f * c)
            local co1 = offset - co2
            
            local e1 = co1 * math.exp(r1 * dt)
            local e2 = co2 * math.exp(r2 * dt)
            
            p1 = e1 + e2 + g
            v1 = r1 * e1 + r2 * e2
        end
        
        local complete = math.abs(v1) < 0.001 and math.abs(p1 - g) < 0.001
        
        return {
            value = complete and g or p1,
            velocity = v1,
            complete = complete
        }
    end
    
    Flipper.Spring = Spring
    
    -- ============================================
    -- INSTANT GOAL
    -- ============================================
    
    local Instant = {}
    Instant.__index = Instant
    
    function Instant.new(targetValue)
        return setmetatable({
            _type = "Instant",
            _targetValue = targetValue
        }, Instant)
    end
    
    function Instant:step()
        return {
            value = self._targetValue,
            velocity = 0,
            complete = true
        }
    end
    
    Flipper.Instant = Instant
    
    -- ============================================
    -- LINEAR GOAL
    -- ============================================
    
    local Linear = {}
    Linear.__index = Linear
    
    function Linear.new(targetValue, options)
        options = options or {}
        
        return setmetatable({
            _type = "Linear",
            _targetValue = targetValue,
            _velocity = options.velocity or 1
        }, Linear)
    end
    
    function Linear:step(state, dt)
        local p0 = state.value
        local v = self._velocity
        local g = self._targetValue
        
        local dv = v * dt
        local p1
        
        if p0 < g then
            p1 = math.min(p0 + dv, g)
        else
            p1 = math.max(p0 - dv, g)
        end
        
        return {
            value = p1,
            velocity = v,
            complete = p1 == g
        }
    end
    
    Flipper.Linear = Linear
    
    -- ============================================
    -- SINGLE MOTOR
    -- ============================================
    
    local SingleMotor = setmetatable({}, {__index = BaseMotor})
    SingleMotor.__index = SingleMotor
    
    function SingleMotor.new(initialValue, useImplicitConnections)
        local self = setmetatable(BaseMotor.new(), SingleMotor)
        
        self._state = {
            value = initialValue,
            velocity = 0,
            complete = true
        }
        self._goal = nil
        self._useImplicitConnections = useImplicitConnections ~= false
        
        return self
    end
    
    function SingleMotor:step(dt)
        if not self._goal then return end
        
        self._state = self._goal:step(self._state, dt)
        self._onStep:Fire(self._state.value)
        
        if self._state.complete then
            if self._useImplicitConnections then
                self:stop()
            end
            self._onComplete:Fire()
        end
    end
    
    function SingleMotor:getValue()
        return self._state.value
    end
    
    function SingleMotor:setGoal(goal)
        self._goal = goal
        self._state.complete = false
        
        if self._useImplicitConnections then
            self:start()
        end
    end
    
    Flipper.SingleMotor = SingleMotor
    
    -- ============================================
    -- GROUP MOTOR
    -- ============================================
    
    local GroupMotor = setmetatable({}, {__index = BaseMotor})
    GroupMotor.__index = GroupMotor
    
    function GroupMotor.new(initialValues, useImplicitConnections)
        local self = setmetatable(BaseMotor.new(), GroupMotor)
        
        self._states = {}
        self._goals = {}
        self._useImplicitConnections = useImplicitConnections ~= false
        
        for key, value in pairs(initialValues) do
            self._states[key] = {
                value = value,
                velocity = 0,
                complete = true
            }
        end
        
        return self
    end
    
    function GroupMotor:step(dt)
        local allComplete = true
        local values = {}
        
        for key, state in pairs(self._states) do
            local goal = self._goals[key]
            if goal then
                self._states[key] = goal:step(state, dt)
                if not self._states[key].complete then
                    allComplete = false
                end
            end
            values[key] = self._states[key].value
        end
        
        self._onStep:Fire(values)
        
        if allComplete then
            if self._useImplicitConnections then
                self:stop()
            end
            self._onComplete:Fire()
        end
    end
    
    function GroupMotor:getValue()
        local values = {}
        for key, state in pairs(self._states) do
            values[key] = state.value
        end
        return values
    end
    
    function GroupMotor:setGoal(goals)
        for key, goal in pairs(goals) do
            self._goals[key] = goal
            if self._states[key] then
                self._states[key].complete = false
            end
        end
        
        if self._useImplicitConnections then
            self:start()
        end
    end
    
    Flipper.GroupMotor = GroupMotor
    
    -- ============================================
    -- UTILITY
    -- ============================================
    
    function Flipper.isMotor(value)
        return type(value) == "table" and (
            getmetatable(getmetatable(value) or {}) == BaseMotor or
            getmetatable(value) == SingleMotor or
            getmetatable(value) == GroupMotor
        )
    end
    
    return Flipper
    
end

-- Module: Themes
_modules["Themes"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                       GUI Framework                           ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
    ]]
    
    local Themes = {
        Names = {"Dark", "Light", "Ocean", "AmberGlow", "Amethyst", "Green", "Bloom", "DarkBlue", "Serenity", "Rose", "Aqua", "Darker", "Cyberpunk", "Sunset", "Forest", "Lavender", "Crimson", "Ice", "Mocha", "Neon", "Slate", "Copper", "Emerald", "Sapphire", "Dracula", "Nord", "Gruvbox"}
    }
    
    -- ============================================
    -- DARK THEME (Default)
    -- ============================================
    Themes.Dark = {
        -- Main
        TextColor = Color3.fromRGB(240, 240, 240),
        Background = Color3.fromRGB(25, 25, 25),
        Topbar = Color3.fromRGB(34, 34, 34),
        Shadow = Color3.fromRGB(20, 20, 20),
        
        -- Notifications
        NotificationBackground = Color3.fromRGB(20, 20, 20),
        NotificationActionsBackground = Color3.fromRGB(230, 230, 230),
        
        -- Tabs
        Tab = Color3.fromRGB(80, 80, 80),
        TabStroke = Color3.fromRGB(85, 85, 85),
        TabBackgroundSelected = Color3.fromRGB(210, 210, 210),
        TabTextColor = Color3.fromRGB(240, 240, 240),
        SelectedTabTextColor = Color3.fromRGB(50, 50, 50),
        
        -- Elements
        Element = Color3.fromRGB(35, 35, 35),
        ElementBackground = Color3.fromRGB(35, 35, 35),
        ElementBackgroundHover = Color3.fromRGB(40, 40, 40),
        SecondaryElementBackground = Color3.fromRGB(25, 25, 25),
        ElementStroke = Color3.fromRGB(50, 50, 50),
        SecondaryElementStroke = Color3.fromRGB(40, 40, 40),
        ElementBorder = Color3.fromRGB(50, 50, 50),
        ElementTransparency = 0.89,
        HoverChange = 0.04,
        
        -- Slider
        SliderBackground = Color3.fromRGB(50, 138, 220),
        SliderProgress = Color3.fromRGB(50, 138, 220),
        SliderStroke = Color3.fromRGB(58, 163, 255),
        
        -- Toggle
        ToggleBackground = Color3.fromRGB(30, 30, 30),
        ToggleEnabled = Color3.fromRGB(0, 146, 214),
        ToggleDisabled = Color3.fromRGB(100, 100, 100),
        ToggleEnabledStroke = Color3.fromRGB(0, 170, 255),
        ToggleDisabledStroke = Color3.fromRGB(125, 125, 125),
        ToggleEnabledOuterStroke = Color3.fromRGB(100, 100, 100),
        ToggleDisabledOuterStroke = Color3.fromRGB(65, 65, 65),
        
        -- Dropdown
        DropdownSelected = Color3.fromRGB(40, 40, 40),
        DropdownUnselected = Color3.fromRGB(30, 30, 30),
        
        -- Input
        Input = Color3.fromRGB(30, 30, 30),
        InputFocused = Color3.fromRGB(25, 25, 25),
        InputStroke = Color3.fromRGB(65, 65, 65),
        InputIndicator = Color3.fromRGB(100, 100, 100),
        PlaceholderColor = Color3.fromRGB(178, 178, 178),
        InElementBorder = Color3.fromRGB(50, 50, 50),
        
        -- Dialog
        Dialog = Color3.fromRGB(30, 30, 30),
        DialogBorder = Color3.fromRGB(50, 50, 50),
        DialogButton = Color3.fromRGB(35, 35, 35),
        DialogButtonBorder = Color3.fromRGB(60, 60, 60),
        DialogHolder = Color3.fromRGB(25, 25, 25),
        DialogHolderLine = Color3.fromRGB(40, 40, 40),
        DialogInput = Color3.fromRGB(35, 35, 35),
        DialogInputLine = Color3.fromRGB(100, 100, 100),
        
        -- Text
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(170, 170, 170),
        
        -- Special
        Hover = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(0, 146, 214),
        TitleBarLine = Color3.fromRGB(50, 50, 50),
        
        -- Acrylic
        AcrylicMain = Color3.fromRGB(20, 20, 20),
        AcrylicBorder = Color3.fromRGB(100, 100, 100),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))
        }),
        AcrylicNoise = 0.9
    }
    
    -- ============================================
    -- LIGHT THEME
    -- ============================================
    Themes.Light = {
        TextColor = Color3.fromRGB(40, 40, 40),
        Background = Color3.fromRGB(245, 245, 245),
        Topbar = Color3.fromRGB(230, 230, 230),
        Shadow = Color3.fromRGB(200, 200, 200),
        
        NotificationBackground = Color3.fromRGB(250, 250, 250),
        NotificationActionsBackground = Color3.fromRGB(240, 240, 240),
        
        Tab = Color3.fromRGB(235, 235, 235),
        TabStroke = Color3.fromRGB(215, 215, 215),
        TabBackgroundSelected = Color3.fromRGB(255, 255, 255),
        TabTextColor = Color3.fromRGB(80, 80, 80),
        SelectedTabTextColor = Color3.fromRGB(0, 0, 0),
        
        Element = Color3.fromRGB(240, 240, 240),
        ElementBackground = Color3.fromRGB(240, 240, 240),
        ElementBackgroundHover = Color3.fromRGB(225, 225, 225),
        SecondaryElementBackground = Color3.fromRGB(235, 235, 235),
        ElementStroke = Color3.fromRGB(210, 210, 210),
        SecondaryElementStroke = Color3.fromRGB(210, 210, 210),
        ElementBorder = Color3.fromRGB(200, 200, 200),
        ElementTransparency = 0.89,
        HoverChange = 0.04,
        
        SliderBackground = Color3.fromRGB(150, 180, 220),
        SliderProgress = Color3.fromRGB(100, 150, 200),
        SliderStroke = Color3.fromRGB(120, 170, 220),
        
        ToggleBackground = Color3.fromRGB(220, 220, 220),
        ToggleEnabled = Color3.fromRGB(0, 146, 214),
        ToggleDisabled = Color3.fromRGB(150, 150, 150),
        ToggleEnabledStroke = Color3.fromRGB(0, 170, 255),
        ToggleDisabledStroke = Color3.fromRGB(170, 170, 170),
        ToggleEnabledOuterStroke = Color3.fromRGB(100, 100, 100),
        ToggleDisabledOuterStroke = Color3.fromRGB(180, 180, 180),
        
        DropdownSelected = Color3.fromRGB(230, 230, 230),
        DropdownUnselected = Color3.fromRGB(220, 220, 220),
        
        Input = Color3.fromRGB(240, 240, 240),
        InputFocused = Color3.fromRGB(250, 250, 250),
        InputStroke = Color3.fromRGB(180, 180, 180),
        InputIndicator = Color3.fromRGB(150, 150, 150),
        PlaceholderColor = Color3.fromRGB(140, 140, 140),
        InElementBorder = Color3.fromRGB(200, 200, 200),
        
        Dialog = Color3.fromRGB(250, 250, 250),
        DialogBorder = Color3.fromRGB(200, 200, 200),
        DialogButton = Color3.fromRGB(240, 240, 240),
        DialogButtonBorder = Color3.fromRGB(180, 180, 180),
        DialogHolder = Color3.fromRGB(235, 235, 235),
        DialogHolderLine = Color3.fromRGB(200, 200, 200),
        DialogInput = Color3.fromRGB(245, 245, 245),
        DialogInputLine = Color3.fromRGB(150, 150, 150),
        
        Text = Color3.fromRGB(40, 40, 40),
        SubText = Color3.fromRGB(100, 100, 100),
        
        Hover = Color3.fromRGB(0, 0, 0),
        Accent = Color3.fromRGB(0, 146, 214),
        TitleBarLine = Color3.fromRGB(200, 200, 200),
        
        AcrylicMain = Color3.fromRGB(255, 255, 255),
        AcrylicBorder = Color3.fromRGB(200, 200, 200),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 245, 245))
        }),
        AcrylicNoise = 0.96
    }
    
    -- ============================================
    -- OCEAN THEME
    -- ============================================
    Themes.Ocean = {
        TextColor = Color3.fromRGB(230, 240, 240),
        Background = Color3.fromRGB(20, 30, 30),
        Topbar = Color3.fromRGB(25, 40, 40),
        Shadow = Color3.fromRGB(15, 20, 20),
        
        NotificationBackground = Color3.fromRGB(25, 35, 35),
        NotificationActionsBackground = Color3.fromRGB(230, 240, 240),
        
        Tab = Color3.fromRGB(40, 60, 60),
        TabStroke = Color3.fromRGB(50, 70, 70),
        TabBackgroundSelected = Color3.fromRGB(100, 180, 180),
        TabTextColor = Color3.fromRGB(210, 230, 230),
        SelectedTabTextColor = Color3.fromRGB(20, 50, 50),
        
        Element = Color3.fromRGB(30, 50, 50),
        ElementBackground = Color3.fromRGB(30, 50, 50),
        ElementBackgroundHover = Color3.fromRGB(40, 60, 60),
        SecondaryElementBackground = Color3.fromRGB(30, 45, 45),
        ElementStroke = Color3.fromRGB(45, 70, 70),
        SecondaryElementStroke = Color3.fromRGB(40, 65, 65),
        ElementBorder = Color3.fromRGB(50, 80, 80),
        ElementTransparency = 0.89,
        HoverChange = 0.04,
        
        SliderBackground = Color3.fromRGB(0, 110, 110),
        SliderProgress = Color3.fromRGB(0, 140, 140),
        SliderStroke = Color3.fromRGB(0, 160, 160),
        
        ToggleBackground = Color3.fromRGB(30, 50, 50),
        ToggleEnabled = Color3.fromRGB(0, 130, 130),
        ToggleDisabled = Color3.fromRGB(70, 90, 90),
        ToggleEnabledStroke = Color3.fromRGB(0, 160, 160),
        ToggleDisabledStroke = Color3.fromRGB(85, 105, 105),
        ToggleEnabledOuterStroke = Color3.fromRGB(50, 100, 100),
        ToggleDisabledOuterStroke = Color3.fromRGB(45, 65, 65),
        
        DropdownSelected = Color3.fromRGB(30, 60, 60),
        DropdownUnselected = Color3.fromRGB(25, 40, 40),
        
        Input = Color3.fromRGB(30, 50, 50),
        InputFocused = Color3.fromRGB(25, 45, 45),
        InputStroke = Color3.fromRGB(50, 70, 70),
        InputIndicator = Color3.fromRGB(0, 140, 140),
        PlaceholderColor = Color3.fromRGB(140, 160, 160),
        InElementBorder = Color3.fromRGB(50, 80, 80),
        
        Dialog = Color3.fromRGB(25, 40, 40),
        DialogBorder = Color3.fromRGB(50, 80, 80),
        DialogButton = Color3.fromRGB(30, 50, 50),
        DialogButtonBorder = Color3.fromRGB(50, 80, 80),
        DialogHolder = Color3.fromRGB(20, 35, 35),
        DialogHolderLine = Color3.fromRGB(40, 65, 65),
        DialogInput = Color3.fromRGB(30, 50, 50),
        DialogInputLine = Color3.fromRGB(0, 140, 140),
        
        Text = Color3.fromRGB(230, 240, 240),
        SubText = Color3.fromRGB(150, 180, 180),
        
        Hover = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(0, 180, 180),
        TitleBarLine = Color3.fromRGB(50, 80, 80),
        
        AcrylicMain = Color3.fromRGB(20, 35, 35),
        AcrylicBorder = Color3.fromRGB(60, 100, 100),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 45, 45)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 30, 30))
        }),
        AcrylicNoise = 0.9
    }
    
    -- ============================================
    -- AMBER GLOW THEME
    -- ============================================
    Themes.AmberGlow = {
        TextColor = Color3.fromRGB(255, 245, 230),
        Background = Color3.fromRGB(45, 30, 20),
        Topbar = Color3.fromRGB(55, 40, 25),
        Shadow = Color3.fromRGB(35, 25, 15),
        
        NotificationBackground = Color3.fromRGB(50, 35, 25),
        NotificationActionsBackground = Color3.fromRGB(245, 230, 215),
        
        Tab = Color3.fromRGB(75, 50, 35),
        TabStroke = Color3.fromRGB(90, 60, 45),
        TabBackgroundSelected = Color3.fromRGB(230, 180, 100),
        TabTextColor = Color3.fromRGB(250, 220, 200),
        SelectedTabTextColor = Color3.fromRGB(50, 30, 10),
        
        Element = Color3.fromRGB(60, 45, 35),
        ElementBackground = Color3.fromRGB(60, 45, 35),
        ElementBackgroundHover = Color3.fromRGB(70, 50, 40),
        SecondaryElementBackground = Color3.fromRGB(55, 40, 30),
        ElementStroke = Color3.fromRGB(85, 60, 45),
        SecondaryElementStroke = Color3.fromRGB(75, 50, 35),
        ElementBorder = Color3.fromRGB(100, 70, 50),
        ElementTransparency = 0.89,
        HoverChange = 0.04,
        
        SliderBackground = Color3.fromRGB(220, 130, 60),
        SliderProgress = Color3.fromRGB(250, 150, 75),
        SliderStroke = Color3.fromRGB(255, 170, 85),
        
        ToggleBackground = Color3.fromRGB(55, 40, 30),
        ToggleEnabled = Color3.fromRGB(240, 130, 30),
        ToggleDisabled = Color3.fromRGB(90, 70, 60),
        ToggleEnabledStroke = Color3.fromRGB(255, 160, 50),
        ToggleDisabledStroke = Color3.fromRGB(110, 85, 75),
        ToggleEnabledOuterStroke = Color3.fromRGB(200, 100, 50),
        ToggleDisabledOuterStroke = Color3.fromRGB(75, 60, 55),
        
        DropdownSelected = Color3.fromRGB(70, 50, 40),
        DropdownUnselected = Color3.fromRGB(55, 40, 30),
        
        Input = Color3.fromRGB(60, 45, 35),
        InputFocused = Color3.fromRGB(55, 40, 30),
        InputStroke = Color3.fromRGB(90, 65, 50),
        InputIndicator = Color3.fromRGB(250, 150, 75),
        PlaceholderColor = Color3.fromRGB(190, 150, 130),
        InElementBorder = Color3.fromRGB(100, 70, 50),
        
        Dialog = Color3.fromRGB(55, 40, 25),
        DialogBorder = Color3.fromRGB(100, 70, 50),
        DialogButton = Color3.fromRGB(60, 45, 35),
        DialogButtonBorder = Color3.fromRGB(100, 70, 50),
        DialogHolder = Color3.fromRGB(45, 30, 20),
        DialogHolderLine = Color3.fromRGB(80, 55, 40),
        DialogInput = Color3.fromRGB(60, 45, 35),
        DialogInputLine = Color3.fromRGB(250, 150, 75),
        
        Text = Color3.fromRGB(255, 245, 230),
        SubText = Color3.fromRGB(200, 170, 140),
        
        Hover = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(255, 160, 50),
        TitleBarLine = Color3.fromRGB(100, 70, 50),
        
        AcrylicMain = Color3.fromRGB(45, 30, 20),
        AcrylicBorder = Color3.fromRGB(120, 80, 50),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(55, 40, 30)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 25, 15))
        }),
        AcrylicNoise = 0.9
    }
    
    -- ============================================
    -- AMETHYST THEME
    -- ============================================
    Themes.Amethyst = {
        TextColor = Color3.fromRGB(240, 240, 240),
        Background = Color3.fromRGB(30, 20, 40),
        Topbar = Color3.fromRGB(40, 25, 50),
        Shadow = Color3.fromRGB(20, 15, 30),
        
        NotificationBackground = Color3.fromRGB(35, 20, 40),
        NotificationActionsBackground = Color3.fromRGB(240, 240, 250),
        
        Tab = Color3.fromRGB(60, 40, 80),
        TabStroke = Color3.fromRGB(70, 45, 90),
        TabBackgroundSelected = Color3.fromRGB(180, 140, 200),
        TabTextColor = Color3.fromRGB(230, 230, 240),
        SelectedTabTextColor = Color3.fromRGB(50, 20, 50),
        
        Element = Color3.fromRGB(45, 30, 60),
        ElementBackground = Color3.fromRGB(45, 30, 60),
        ElementBackgroundHover = Color3.fromRGB(50, 35, 70),
        SecondaryElementBackground = Color3.fromRGB(40, 30, 55),
        ElementStroke = Color3.fromRGB(70, 50, 85),
        SecondaryElementStroke = Color3.fromRGB(65, 45, 80),
        ElementBorder = Color3.fromRGB(80, 55, 100),
        ElementTransparency = 0.89,
        HoverChange = 0.04,
        
        SliderBackground = Color3.fromRGB(100, 60, 150),
        SliderProgress = Color3.fromRGB(130, 80, 180),
        SliderStroke = Color3.fromRGB(150, 100, 200),
        
        ToggleBackground = Color3.fromRGB(45, 30, 55),
        ToggleEnabled = Color3.fromRGB(120, 60, 150),
        ToggleDisabled = Color3.fromRGB(94, 47, 117),
        ToggleEnabledStroke = Color3.fromRGB(140, 80, 170),
        ToggleDisabledStroke = Color3.fromRGB(124, 71, 150),
        ToggleEnabledOuterStroke = Color3.fromRGB(90, 40, 120),
        ToggleDisabledOuterStroke = Color3.fromRGB(80, 50, 110),
        
        DropdownSelected = Color3.fromRGB(50, 35, 70),
        DropdownUnselected = Color3.fromRGB(35, 25, 50),
        
        Input = Color3.fromRGB(45, 30, 60),
        InputFocused = Color3.fromRGB(40, 25, 55),
        InputStroke = Color3.fromRGB(80, 50, 110),
        InputIndicator = Color3.fromRGB(130, 80, 180),
        PlaceholderColor = Color3.fromRGB(178, 150, 200),
        InElementBorder = Color3.fromRGB(80, 55, 100),
        
        Dialog = Color3.fromRGB(40, 25, 50),
        DialogBorder = Color3.fromRGB(80, 55, 100),
        DialogButton = Color3.fromRGB(45, 30, 60),
        DialogButtonBorder = Color3.fromRGB(80, 55, 100),
        DialogHolder = Color3.fromRGB(30, 20, 40),
        DialogHolderLine = Color3.fromRGB(60, 40, 75),
        DialogInput = Color3.fromRGB(45, 30, 60),
        DialogInputLine = Color3.fromRGB(130, 80, 180),
        
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(180, 160, 200),
        
        Hover = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(150, 100, 200),
        TitleBarLine = Color3.fromRGB(80, 55, 100),
        
        AcrylicMain = Color3.fromRGB(30, 20, 40),
        AcrylicBorder = Color3.fromRGB(100, 65, 130),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 28, 55)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 15, 35))
        }),
        AcrylicNoise = 0.9
    }
    
    -- ============================================
    -- GREEN THEME
    -- ============================================
    Themes.Green = {
        TextColor = Color3.fromRGB(30, 60, 30),
        Background = Color3.fromRGB(235, 245, 235),
        Topbar = Color3.fromRGB(210, 230, 210),
        Shadow = Color3.fromRGB(200, 220, 200),
        
        NotificationBackground = Color3.fromRGB(240, 250, 240),
        NotificationActionsBackground = Color3.fromRGB(220, 235, 220),
        
        Tab = Color3.fromRGB(215, 235, 215),
        TabStroke = Color3.fromRGB(190, 210, 190),
        TabBackgroundSelected = Color3.fromRGB(245, 255, 245),
        TabTextColor = Color3.fromRGB(50, 80, 50),
        SelectedTabTextColor = Color3.fromRGB(20, 60, 20),
        
        Element = Color3.fromRGB(225, 240, 225),
        ElementBackground = Color3.fromRGB(225, 240, 225),
        ElementBackgroundHover = Color3.fromRGB(210, 225, 210),
        SecondaryElementBackground = Color3.fromRGB(235, 245, 235),
        ElementStroke = Color3.fromRGB(180, 200, 180),
        SecondaryElementStroke = Color3.fromRGB(180, 200, 180),
        ElementBorder = Color3.fromRGB(160, 190, 160),
        ElementTransparency = 0.89,
        HoverChange = 0.04,
        
        SliderBackground = Color3.fromRGB(90, 160, 90),
        SliderProgress = Color3.fromRGB(70, 130, 70),
        SliderStroke = Color3.fromRGB(100, 180, 100),
        
        ToggleBackground = Color3.fromRGB(215, 235, 215),
        ToggleEnabled = Color3.fromRGB(60, 130, 60),
        ToggleDisabled = Color3.fromRGB(150, 175, 150),
        ToggleEnabledStroke = Color3.fromRGB(80, 150, 80),
        ToggleDisabledStroke = Color3.fromRGB(130, 150, 130),
        ToggleEnabledOuterStroke = Color3.fromRGB(100, 160, 100),
        ToggleDisabledOuterStroke = Color3.fromRGB(160, 180, 160),
        
        DropdownSelected = Color3.fromRGB(225, 240, 225),
        DropdownUnselected = Color3.fromRGB(210, 225, 210),
        
        Input = Color3.fromRGB(235, 245, 235),
        InputFocused = Color3.fromRGB(245, 255, 245),
        InputStroke = Color3.fromRGB(180, 200, 180),
        InputIndicator = Color3.fromRGB(70, 130, 70),
        PlaceholderColor = Color3.fromRGB(120, 140, 120),
        InElementBorder = Color3.fromRGB(160, 190, 160),
        
        Dialog = Color3.fromRGB(230, 245, 230),
        DialogBorder = Color3.fromRGB(160, 190, 160),
        DialogButton = Color3.fromRGB(220, 235, 220),
        DialogButtonBorder = Color3.fromRGB(160, 190, 160),
        DialogHolder = Color3.fromRGB(215, 230, 215),
        DialogHolderLine = Color3.fromRGB(180, 200, 180),
        DialogInput = Color3.fromRGB(235, 245, 235),
        DialogInputLine = Color3.fromRGB(70, 130, 70),
        
        Text = Color3.fromRGB(30, 60, 30),
        SubText = Color3.fromRGB(80, 110, 80),
        
        Hover = Color3.fromRGB(0, 0, 0),
        Accent = Color3.fromRGB(60, 140, 60),
        TitleBarLine = Color3.fromRGB(180, 200, 180),
        
        AcrylicMain = Color3.fromRGB(240, 250, 240),
        AcrylicBorder = Color3.fromRGB(160, 200, 160),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(245, 255, 245)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 245, 230))
        }),
        AcrylicNoise = 0.96
    }
    
    -- ============================================
    -- DARK BLUE THEME
    -- ============================================
    Themes.DarkBlue = {
        TextColor = Color3.fromRGB(230, 230, 230),
        Background = Color3.fromRGB(20, 25, 30),
        Topbar = Color3.fromRGB(30, 35, 40),
        Shadow = Color3.fromRGB(15, 20, 25),
        
        NotificationBackground = Color3.fromRGB(25, 30, 35),
        NotificationActionsBackground = Color3.fromRGB(45, 50, 55),
        
        Tab = Color3.fromRGB(35, 40, 45),
        TabStroke = Color3.fromRGB(45, 50, 60),
        TabBackgroundSelected = Color3.fromRGB(40, 70, 100),
        TabTextColor = Color3.fromRGB(200, 200, 200),
        SelectedTabTextColor = Color3.fromRGB(255, 255, 255),
        
        Element = Color3.fromRGB(30, 35, 40),
        ElementBackground = Color3.fromRGB(30, 35, 40),
        ElementBackgroundHover = Color3.fromRGB(40, 45, 50),
        SecondaryElementBackground = Color3.fromRGB(35, 40, 45),
        ElementStroke = Color3.fromRGB(45, 50, 60),
        SecondaryElementStroke = Color3.fromRGB(40, 45, 55),
        ElementBorder = Color3.fromRGB(50, 60, 75),
        ElementTransparency = 0.89,
        HoverChange = 0.04,
        
        SliderBackground = Color3.fromRGB(0, 90, 180),
        SliderProgress = Color3.fromRGB(0, 120, 210),
        SliderStroke = Color3.fromRGB(0, 150, 240),
        
        ToggleBackground = Color3.fromRGB(35, 40, 45),
        ToggleEnabled = Color3.fromRGB(0, 120, 210),
        ToggleDisabled = Color3.fromRGB(70, 70, 80),
        ToggleEnabledStroke = Color3.fromRGB(0, 150, 240),
        ToggleDisabledStroke = Color3.fromRGB(75, 75, 85),
        ToggleEnabledOuterStroke = Color3.fromRGB(20, 100, 180),
        ToggleDisabledOuterStroke = Color3.fromRGB(55, 55, 65),
        
        DropdownSelected = Color3.fromRGB(30, 70, 90),
        DropdownUnselected = Color3.fromRGB(25, 30, 35),
        
        Input = Color3.fromRGB(25, 30, 35),
        InputFocused = Color3.fromRGB(20, 25, 30),
        InputStroke = Color3.fromRGB(45, 50, 60),
        InputIndicator = Color3.fromRGB(0, 120, 210),
        PlaceholderColor = Color3.fromRGB(150, 150, 160),
        InElementBorder = Color3.fromRGB(50, 60, 75),
        
        Dialog = Color3.fromRGB(25, 30, 35),
        DialogBorder = Color3.fromRGB(50, 60, 75),
        DialogButton = Color3.fromRGB(30, 35, 40),
        DialogButtonBorder = Color3.fromRGB(50, 60, 75),
        DialogHolder = Color3.fromRGB(20, 25, 30),
        DialogHolderLine = Color3.fromRGB(40, 50, 60),
        DialogInput = Color3.fromRGB(30, 35, 40),
        DialogInputLine = Color3.fromRGB(0, 120, 210),
        
        Text = Color3.fromRGB(230, 230, 230),
        SubText = Color3.fromRGB(160, 165, 175),
        
        Hover = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(0, 150, 255),
        TitleBarLine = Color3.fromRGB(50, 60, 75),
        
        AcrylicMain = Color3.fromRGB(20, 25, 30),
        AcrylicBorder = Color3.fromRGB(60, 80, 110),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 40, 50)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 20, 25))
        }),
        AcrylicNoise = 0.9
    }
    
    -- ============================================
    -- BLOOM (Pink/Rose) THEME
    -- ============================================
    Themes.Bloom = {
        TextColor = Color3.fromRGB(60, 40, 50),
        Background = Color3.fromRGB(255, 240, 245),
        Topbar = Color3.fromRGB(250, 220, 225),
        Shadow = Color3.fromRGB(230, 190, 195),
        
        NotificationBackground = Color3.fromRGB(255, 235, 240),
        NotificationActionsBackground = Color3.fromRGB(245, 215, 225),
        
        Tab = Color3.fromRGB(240, 210, 220),
        TabStroke = Color3.fromRGB(230, 200, 210),
        TabBackgroundSelected = Color3.fromRGB(255, 225, 235),
        TabTextColor = Color3.fromRGB(80, 40, 60),
        SelectedTabTextColor = Color3.fromRGB(50, 30, 50),
        
        Element = Color3.fromRGB(255, 235, 240),
        ElementBackground = Color3.fromRGB(255, 235, 240),
        ElementBackgroundHover = Color3.fromRGB(245, 220, 230),
        SecondaryElementBackground = Color3.fromRGB(255, 235, 240),
        ElementStroke = Color3.fromRGB(230, 200, 210),
        SecondaryElementStroke = Color3.fromRGB(230, 200, 210),
        ElementBorder = Color3.fromRGB(220, 180, 195),
        ElementTransparency = 0.89,
        HoverChange = 0.04,
        
        SliderBackground = Color3.fromRGB(240, 130, 160),
        SliderProgress = Color3.fromRGB(250, 160, 180),
        SliderStroke = Color3.fromRGB(255, 180, 200),
        
        ToggleBackground = Color3.fromRGB(240, 210, 220),
        ToggleEnabled = Color3.fromRGB(255, 140, 170),
        ToggleDisabled = Color3.fromRGB(200, 180, 185),
        ToggleEnabledStroke = Color3.fromRGB(250, 160, 190),
        ToggleDisabledStroke = Color3.fromRGB(210, 180, 190),
        ToggleEnabledOuterStroke = Color3.fromRGB(220, 160, 180),
        ToggleDisabledOuterStroke = Color3.fromRGB(190, 170, 180),
        
        DropdownSelected = Color3.fromRGB(250, 220, 225),
        DropdownUnselected = Color3.fromRGB(240, 210, 220),
        
        Input = Color3.fromRGB(255, 235, 240),
        InputFocused = Color3.fromRGB(255, 245, 250),
        InputStroke = Color3.fromRGB(220, 190, 200),
        InputIndicator = Color3.fromRGB(250, 160, 180),
        PlaceholderColor = Color3.fromRGB(170, 130, 140),
        InElementBorder = Color3.fromRGB(220, 180, 195),
        
        Dialog = Color3.fromRGB(255, 235, 240),
        DialogBorder = Color3.fromRGB(220, 180, 195),
        DialogButton = Color3.fromRGB(245, 225, 235),
        DialogButtonBorder = Color3.fromRGB(220, 180, 195),
        DialogHolder = Color3.fromRGB(240, 215, 225),
        DialogHolderLine = Color3.fromRGB(220, 190, 200),
        DialogInput = Color3.fromRGB(250, 235, 240),
        DialogInputLine = Color3.fromRGB(250, 160, 180),
        
        Text = Color3.fromRGB(60, 40, 50),
        SubText = Color3.fromRGB(120, 90, 100),
        
        Hover = Color3.fromRGB(0, 0, 0),
        Accent = Color3.fromRGB(255, 140, 180),
        TitleBarLine = Color3.fromRGB(220, 190, 200),
        
        AcrylicMain = Color3.fromRGB(255, 245, 250),
        AcrylicBorder = Color3.fromRGB(230, 190, 210),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 245, 250)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(250, 235, 245))
        }),
        AcrylicNoise = 0.96
    }
    
    -- ============================================
    -- SERENITY THEME
    -- ============================================
    Themes.Serenity = {
        TextColor = Color3.fromRGB(50, 55, 60),
        Background = Color3.fromRGB(240, 245, 250),
        Topbar = Color3.fromRGB(215, 225, 235),
        Shadow = Color3.fromRGB(200, 210, 220),
        
        NotificationBackground = Color3.fromRGB(210, 220, 230),
        NotificationActionsBackground = Color3.fromRGB(225, 230, 240),
        
        Tab = Color3.fromRGB(200, 210, 220),
        TabStroke = Color3.fromRGB(180, 190, 200),
        TabBackgroundSelected = Color3.fromRGB(175, 185, 200),
        TabTextColor = Color3.fromRGB(50, 55, 60),
        SelectedTabTextColor = Color3.fromRGB(30, 35, 40),
        
        Element = Color3.fromRGB(210, 220, 230),
        ElementBackground = Color3.fromRGB(210, 220, 230),
        ElementBackgroundHover = Color3.fromRGB(220, 230, 240),
        SecondaryElementBackground = Color3.fromRGB(200, 210, 220),
        ElementStroke = Color3.fromRGB(190, 200, 210),
        SecondaryElementStroke = Color3.fromRGB(180, 190, 200),
        ElementBorder = Color3.fromRGB(170, 185, 200),
        ElementTransparency = 0.89,
        HoverChange = 0.04,
        
        SliderBackground = Color3.fromRGB(200, 220, 235),
        SliderProgress = Color3.fromRGB(70, 130, 180),
        SliderStroke = Color3.fromRGB(150, 180, 220),
        
        ToggleBackground = Color3.fromRGB(210, 220, 230),
        ToggleEnabled = Color3.fromRGB(70, 160, 210),
        ToggleDisabled = Color3.fromRGB(180, 180, 180),
        ToggleEnabledStroke = Color3.fromRGB(60, 150, 200),
        ToggleDisabledStroke = Color3.fromRGB(140, 140, 140),
        ToggleEnabledOuterStroke = Color3.fromRGB(100, 120, 140),
        ToggleDisabledOuterStroke = Color3.fromRGB(120, 120, 130),
        
        DropdownSelected = Color3.fromRGB(220, 230, 240),
        DropdownUnselected = Color3.fromRGB(200, 210, 220),
        
        Input = Color3.fromRGB(220, 230, 240),
        InputFocused = Color3.fromRGB(230, 240, 250),
        InputStroke = Color3.fromRGB(180, 190, 200),
        InputIndicator = Color3.fromRGB(70, 130, 180),
        PlaceholderColor = Color3.fromRGB(150, 150, 150),
        InElementBorder = Color3.fromRGB(170, 185, 200),
        
        Dialog = Color3.fromRGB(220, 230, 240),
        DialogBorder = Color3.fromRGB(170, 185, 200),
        DialogButton = Color3.fromRGB(210, 220, 230),
        DialogButtonBorder = Color3.fromRGB(170, 185, 200),
        DialogHolder = Color3.fromRGB(200, 210, 220),
        DialogHolderLine = Color3.fromRGB(175, 190, 205),
        DialogInput = Color3.fromRGB(220, 230, 240),
        DialogInputLine = Color3.fromRGB(70, 130, 180),
        
        Text = Color3.fromRGB(50, 55, 60),
        SubText = Color3.fromRGB(100, 110, 120),
        
        Hover = Color3.fromRGB(0, 0, 0),
        Accent = Color3.fromRGB(70, 160, 210),
        TitleBarLine = Color3.fromRGB(180, 195, 210),
        
        AcrylicMain = Color3.fromRGB(235, 245, 255),
        AcrylicBorder = Color3.fromRGB(170, 195, 220),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 250, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(225, 235, 245))
        }),
        AcrylicNoise = 0.96
    }
    
    -- ============================================
    -- ROSE THEME
    -- ============================================
    Themes.Rose = {
        TextColor = Color3.fromRGB(245, 235, 240),
        Background = Color3.fromRGB(35, 25, 30),
        Topbar = Color3.fromRGB(45, 30, 38),
        Shadow = Color3.fromRGB(25, 18, 22),
        
        NotificationBackground = Color3.fromRGB(40, 28, 35),
        NotificationActionsBackground = Color3.fromRGB(245, 235, 240),
        
        Tab = Color3.fromRGB(70, 45, 55),
        TabStroke = Color3.fromRGB(85, 55, 68),
        TabBackgroundSelected = Color3.fromRGB(200, 140, 160),
        TabTextColor = Color3.fromRGB(235, 220, 228),
        SelectedTabTextColor = Color3.fromRGB(40, 25, 32),
        
        Element = Color3.fromRGB(50, 35, 42),
        ElementBackground = Color3.fromRGB(50, 35, 42),
        ElementBackgroundHover = Color3.fromRGB(60, 42, 52),
        SecondaryElementBackground = Color3.fromRGB(45, 32, 40),
        ElementStroke = Color3.fromRGB(75, 52, 62),
        SecondaryElementStroke = Color3.fromRGB(68, 48, 58),
        ElementBorder = Color3.fromRGB(90, 60, 75),
        ElementTransparency = 0.89,
        HoverChange = 0.04,
        
        SliderBackground = Color3.fromRGB(180, 100, 130),
        SliderProgress = Color3.fromRGB(220, 130, 160),
        SliderStroke = Color3.fromRGB(240, 150, 180),
        
        ToggleBackground = Color3.fromRGB(50, 35, 42),
        ToggleEnabled = Color3.fromRGB(200, 100, 130),
        ToggleDisabled = Color3.fromRGB(90, 65, 75),
        ToggleEnabledStroke = Color3.fromRGB(220, 120, 150),
        ToggleDisabledStroke = Color3.fromRGB(105, 78, 90),
        ToggleEnabledOuterStroke = Color3.fromRGB(160, 80, 110),
        ToggleDisabledOuterStroke = Color3.fromRGB(75, 55, 65),
        
        DropdownSelected = Color3.fromRGB(60, 42, 52),
        DropdownUnselected = Color3.fromRGB(45, 32, 40),
        
        Input = Color3.fromRGB(50, 35, 42),
        InputFocused = Color3.fromRGB(45, 32, 38),
        InputStroke = Color3.fromRGB(85, 58, 70),
        InputIndicator = Color3.fromRGB(220, 130, 160),
        PlaceholderColor = Color3.fromRGB(170, 145, 155),
        InElementBorder = Color3.fromRGB(90, 60, 75),
        
        Dialog = Color3.fromRGB(45, 30, 38),
        DialogBorder = Color3.fromRGB(90, 60, 75),
        DialogButton = Color3.fromRGB(50, 35, 42),
        DialogButtonBorder = Color3.fromRGB(90, 60, 75),
        DialogHolder = Color3.fromRGB(38, 26, 32),
        DialogHolderLine = Color3.fromRGB(70, 48, 58),
        DialogInput = Color3.fromRGB(50, 35, 42),
        DialogInputLine = Color3.fromRGB(220, 130, 160),
        
        Text = Color3.fromRGB(245, 235, 240),
        SubText = Color3.fromRGB(190, 170, 180),
        
        Hover = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(230, 140, 170),
        TitleBarLine = Color3.fromRGB(90, 60, 75),
        
        AcrylicMain = Color3.fromRGB(35, 25, 30),
        AcrylicBorder = Color3.fromRGB(110, 75, 90),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 32, 40)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 20, 25))
        }),
        AcrylicNoise = 0.9
    }
    
    -- ============================================
    -- AQUA THEME
    -- ============================================
    Themes.Aqua = {
        TextColor = Color3.fromRGB(235, 245, 250),
        Background = Color3.fromRGB(15, 30, 40),
        Topbar = Color3.fromRGB(20, 40, 55),
        Shadow = Color3.fromRGB(10, 20, 30),
        
        NotificationBackground = Color3.fromRGB(18, 35, 48),
        NotificationActionsBackground = Color3.fromRGB(230, 245, 250),
        
        Tab = Color3.fromRGB(30, 60, 80),
        TabStroke = Color3.fromRGB(40, 75, 100),
        TabBackgroundSelected = Color3.fromRGB(80, 180, 220),
        TabTextColor = Color3.fromRGB(200, 230, 245),
        SelectedTabTextColor = Color3.fromRGB(15, 40, 55),
        
        Element = Color3.fromRGB(25, 50, 68),
        ElementBackground = Color3.fromRGB(25, 50, 68),
        ElementBackgroundHover = Color3.fromRGB(32, 62, 85),
        SecondaryElementBackground = Color3.fromRGB(22, 45, 62),
        ElementStroke = Color3.fromRGB(40, 75, 100),
        SecondaryElementStroke = Color3.fromRGB(35, 68, 92),
        ElementBorder = Color3.fromRGB(50, 90, 120),
        ElementTransparency = 0.89,
        HoverChange = 0.04,
        
        SliderBackground = Color3.fromRGB(0, 140, 180),
        SliderProgress = Color3.fromRGB(0, 180, 220),
        SliderStroke = Color3.fromRGB(0, 200, 250),
        
        ToggleBackground = Color3.fromRGB(25, 50, 68),
        ToggleEnabled = Color3.fromRGB(0, 160, 200),
        ToggleDisabled = Color3.fromRGB(50, 80, 100),
        ToggleEnabledStroke = Color3.fromRGB(0, 190, 240),
        ToggleDisabledStroke = Color3.fromRGB(60, 95, 118),
        ToggleEnabledOuterStroke = Color3.fromRGB(0, 120, 160),
        ToggleDisabledOuterStroke = Color3.fromRGB(40, 70, 90),
        
        DropdownSelected = Color3.fromRGB(30, 65, 88),
        DropdownUnselected = Color3.fromRGB(22, 45, 62),
        
        Input = Color3.fromRGB(25, 50, 68),
        InputFocused = Color3.fromRGB(20, 42, 58),
        InputStroke = Color3.fromRGB(45, 85, 115),
        InputIndicator = Color3.fromRGB(0, 180, 220),
        PlaceholderColor = Color3.fromRGB(130, 170, 190),
        InElementBorder = Color3.fromRGB(50, 90, 120),
        
        Dialog = Color3.fromRGB(20, 40, 55),
        DialogBorder = Color3.fromRGB(50, 90, 120),
        DialogButton = Color3.fromRGB(25, 50, 68),
        DialogButtonBorder = Color3.fromRGB(50, 90, 120),
        DialogHolder = Color3.fromRGB(15, 32, 45),
        DialogHolderLine = Color3.fromRGB(38, 72, 95),
        DialogInput = Color3.fromRGB(25, 50, 68),
        DialogInputLine = Color3.fromRGB(0, 180, 220),
        
        Text = Color3.fromRGB(235, 245, 250),
        SubText = Color3.fromRGB(160, 200, 220),
        
        Hover = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(0, 200, 255),
        TitleBarLine = Color3.fromRGB(50, 90, 120),
        
        AcrylicMain = Color3.fromRGB(15, 30, 40),
        AcrylicBorder = Color3.fromRGB(60, 110, 145),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 45, 62)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 25, 35))
        }),
        AcrylicNoise = 0.9
    }
    
    -- ============================================
    -- DARKER THEME (Ultra Dark)
    -- ============================================
    Themes.Darker = {
        TextColor = Color3.fromRGB(230, 230, 230),
        Background = Color3.fromRGB(12, 12, 14),
        Topbar = Color3.fromRGB(18, 18, 22),
        Shadow = Color3.fromRGB(5, 5, 8),
        
        NotificationBackground = Color3.fromRGB(15, 15, 18),
        NotificationActionsBackground = Color3.fromRGB(220, 220, 220),
        
        Tab = Color3.fromRGB(30, 30, 35),
        TabStroke = Color3.fromRGB(40, 40, 48),
        TabBackgroundSelected = Color3.fromRGB(180, 180, 190),
        TabTextColor = Color3.fromRGB(220, 220, 225),
        SelectedTabTextColor = Color3.fromRGB(20, 20, 25),
        
        Element = Color3.fromRGB(22, 22, 26),
        ElementBackground = Color3.fromRGB(22, 22, 26),
        ElementBackgroundHover = Color3.fromRGB(28, 28, 34),
        SecondaryElementBackground = Color3.fromRGB(18, 18, 22),
        ElementStroke = Color3.fromRGB(35, 35, 42),
        SecondaryElementStroke = Color3.fromRGB(30, 30, 36),
        ElementBorder = Color3.fromRGB(40, 40, 50),
        ElementTransparency = 0.89,
        HoverChange = 0.04,
        
        SliderBackground = Color3.fromRGB(60, 60, 70),
        SliderProgress = Color3.fromRGB(100, 100, 120),
        SliderStroke = Color3.fromRGB(120, 120, 140),
        
        ToggleBackground = Color3.fromRGB(22, 22, 26),
        ToggleEnabled = Color3.fromRGB(100, 100, 120),
        ToggleDisabled = Color3.fromRGB(50, 50, 60),
        ToggleEnabledStroke = Color3.fromRGB(120, 120, 140),
        ToggleDisabledStroke = Color3.fromRGB(60, 60, 72),
        ToggleEnabledOuterStroke = Color3.fromRGB(80, 80, 95),
        ToggleDisabledOuterStroke = Color3.fromRGB(38, 38, 46),
        
        DropdownSelected = Color3.fromRGB(28, 28, 34),
        DropdownUnselected = Color3.fromRGB(20, 20, 24),
        
        Input = Color3.fromRGB(20, 20, 24),
        InputFocused = Color3.fromRGB(16, 16, 20),
        InputStroke = Color3.fromRGB(40, 40, 50),
        InputIndicator = Color3.fromRGB(100, 100, 120),
        PlaceholderColor = Color3.fromRGB(120, 120, 130),
        InElementBorder = Color3.fromRGB(40, 40, 50),
        
        Dialog = Color3.fromRGB(18, 18, 22),
        DialogBorder = Color3.fromRGB(40, 40, 50),
        DialogButton = Color3.fromRGB(22, 22, 26),
        DialogButtonBorder = Color3.fromRGB(40, 40, 50),
        DialogHolder = Color3.fromRGB(14, 14, 18),
        DialogHolderLine = Color3.fromRGB(32, 32, 40),
        DialogInput = Color3.fromRGB(20, 20, 24),
        DialogInputLine = Color3.fromRGB(100, 100, 120),
        
        Text = Color3.fromRGB(230, 230, 230),
        SubText = Color3.fromRGB(140, 140, 150),
        
        Hover = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(130, 130, 150),
        TitleBarLine = Color3.fromRGB(40, 40, 50),
        
        AcrylicMain = Color3.fromRGB(10, 10, 12),
        AcrylicBorder = Color3.fromRGB(50, 50, 65),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 18, 22)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 10))
        }),
        AcrylicNoise = 0.92
    }
    
    -- ============================================
    -- CYBERPUNK THEME (Neon Pink/Cyan)
    -- ============================================
    Themes.Cyberpunk = {
        TextColor = Color3.fromRGB(255, 255, 255),
        Background = Color3.fromRGB(15, 10, 25),
        Topbar = Color3.fromRGB(25, 15, 40),
        Shadow = Color3.fromRGB(10, 5, 18),
        
        NotificationBackground = Color3.fromRGB(20, 12, 35),
        NotificationActionsBackground = Color3.fromRGB(255, 50, 150),
        
        Tab = Color3.fromRGB(60, 30, 80),
        TabStroke = Color3.fromRGB(255, 0, 128),
        TabBackgroundSelected = Color3.fromRGB(255, 50, 150),
        TabTextColor = Color3.fromRGB(255, 255, 255),
        SelectedTabTextColor = Color3.fromRGB(255, 255, 255),
        
        Element = Color3.fromRGB(30, 20, 50),
        ElementBackground = Color3.fromRGB(30, 20, 50),
        ElementBackgroundHover = Color3.fromRGB(40, 28, 65),
        SecondaryElementBackground = Color3.fromRGB(20, 12, 35),
        ElementStroke = Color3.fromRGB(100, 50, 150),
        SecondaryElementStroke = Color3.fromRGB(80, 40, 120),
        ElementBorder = Color3.fromRGB(100, 50, 150),
        ElementTransparency = 0.85,
        HoverChange = 0.05,
        
        SliderBackground = Color3.fromRGB(255, 0, 128),
        SliderProgress = Color3.fromRGB(255, 0, 128),
        SliderStroke = Color3.fromRGB(0, 255, 255),
        
        ToggleBackground = Color3.fromRGB(25, 15, 40),
        ToggleEnabled = Color3.fromRGB(0, 255, 255),
        ToggleDisabled = Color3.fromRGB(80, 50, 100),
        ToggleEnabledStroke = Color3.fromRGB(0, 255, 255),
        ToggleDisabledStroke = Color3.fromRGB(100, 60, 120),
        ToggleEnabledOuterStroke = Color3.fromRGB(100, 100, 150),
        ToggleDisabledOuterStroke = Color3.fromRGB(60, 40, 80),
        
        DropdownSelected = Color3.fromRGB(40, 25, 60),
        DropdownUnselected = Color3.fromRGB(25, 15, 40),
        
        Input = Color3.fromRGB(25, 15, 40),
        InputFocused = Color3.fromRGB(20, 12, 35),
        InputStroke = Color3.fromRGB(150, 50, 200),
        InputIndicator = Color3.fromRGB(255, 0, 128),
        PlaceholderColor = Color3.fromRGB(150, 120, 180),
        InElementBorder = Color3.fromRGB(100, 50, 150),
        
        Dialog = Color3.fromRGB(25, 15, 40),
        DialogBorder = Color3.fromRGB(255, 0, 128),
        DialogButton = Color3.fromRGB(35, 22, 55),
        DialogButtonBorder = Color3.fromRGB(150, 50, 200),
        DialogHolder = Color3.fromRGB(18, 10, 30),
        DialogHolderLine = Color3.fromRGB(80, 40, 120),
        DialogInput = Color3.fromRGB(30, 18, 48),
        DialogInputLine = Color3.fromRGB(200, 100, 255),
        
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(200, 180, 220),
        
        Hover = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(255, 0, 128),
        TitleBarLine = Color3.fromRGB(100, 50, 150),
        
        AcrylicMain = Color3.fromRGB(15, 10, 25),
        AcrylicBorder = Color3.fromRGB(150, 50, 200),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 15, 50)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 5, 18))
        }),
        AcrylicNoise = 0.88
    }
    
    -- ============================================
    -- SUNSET THEME (Orange/Purple Gradient)
    -- ============================================
    Themes.Sunset = {
        TextColor = Color3.fromRGB(255, 255, 255),
        Background = Color3.fromRGB(35, 20, 40),
        Topbar = Color3.fromRGB(50, 28, 55),
        Shadow = Color3.fromRGB(25, 15, 30),
        
        NotificationBackground = Color3.fromRGB(40, 22, 45),
        NotificationActionsBackground = Color3.fromRGB(255, 140, 60),
        
        Tab = Color3.fromRGB(80, 45, 70),
        TabStroke = Color3.fromRGB(255, 120, 80),
        TabBackgroundSelected = Color3.fromRGB(255, 140, 60),
        TabTextColor = Color3.fromRGB(255, 255, 255),
        SelectedTabTextColor = Color3.fromRGB(50, 30, 40),
        
        Element = Color3.fromRGB(55, 32, 58),
        ElementBackground = Color3.fromRGB(55, 32, 58),
        ElementBackgroundHover = Color3.fromRGB(70, 42, 72),
        SecondaryElementBackground = Color3.fromRGB(40, 22, 45),
        ElementStroke = Color3.fromRGB(120, 70, 100),
        SecondaryElementStroke = Color3.fromRGB(100, 55, 85),
        ElementBorder = Color3.fromRGB(120, 70, 100),
        ElementTransparency = 0.87,
        HoverChange = 0.05,
        
        SliderBackground = Color3.fromRGB(255, 120, 50),
        SliderProgress = Color3.fromRGB(255, 140, 60),
        SliderStroke = Color3.fromRGB(255, 180, 100),
        
        ToggleBackground = Color3.fromRGB(45, 25, 50),
        ToggleEnabled = Color3.fromRGB(255, 140, 60),
        ToggleDisabled = Color3.fromRGB(100, 60, 80),
        ToggleEnabledStroke = Color3.fromRGB(255, 180, 100),
        ToggleDisabledStroke = Color3.fromRGB(120, 75, 95),
        ToggleEnabledOuterStroke = Color3.fromRGB(150, 90, 120),
        ToggleDisabledOuterStroke = Color3.fromRGB(80, 50, 65),
        
        DropdownSelected = Color3.fromRGB(70, 40, 65),
        DropdownUnselected = Color3.fromRGB(50, 28, 52),
        
        Input = Color3.fromRGB(50, 28, 52),
        InputFocused = Color3.fromRGB(45, 25, 48),
        InputStroke = Color3.fromRGB(180, 100, 120),
        InputIndicator = Color3.fromRGB(255, 140, 60),
        PlaceholderColor = Color3.fromRGB(180, 150, 170),
        InElementBorder = Color3.fromRGB(120, 70, 100),
        
        Dialog = Color3.fromRGB(50, 28, 55),
        DialogBorder = Color3.fromRGB(255, 140, 60),
        DialogButton = Color3.fromRGB(60, 35, 62),
        DialogButtonBorder = Color3.fromRGB(180, 100, 120),
        DialogHolder = Color3.fromRGB(35, 20, 40),
        DialogHolderLine = Color3.fromRGB(100, 60, 85),
        DialogInput = Color3.fromRGB(55, 32, 58),
        DialogInputLine = Color3.fromRGB(255, 160, 80),
        
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(220, 190, 210),
        
        Hover = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(255, 140, 60),
        TitleBarLine = Color3.fromRGB(120, 70, 100),
        
        AcrylicMain = Color3.fromRGB(30, 18, 35),
        AcrylicBorder = Color3.fromRGB(180, 100, 120),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 35, 62)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 15, 30))
        }),
        AcrylicNoise = 0.88
    }
    
    -- ============================================
    -- FOREST THEME (Deep Green)
    -- ============================================
    Themes.Forest = {
        TextColor = Color3.fromRGB(235, 245, 235),
        Background = Color3.fromRGB(18, 30, 22),
        Topbar = Color3.fromRGB(25, 42, 30),
        Shadow = Color3.fromRGB(12, 22, 15),
        
        NotificationBackground = Color3.fromRGB(20, 35, 25),
        NotificationActionsBackground = Color3.fromRGB(100, 180, 100),
        
        Tab = Color3.fromRGB(45, 75, 50),
        TabStroke = Color3.fromRGB(80, 140, 90),
        TabBackgroundSelected = Color3.fromRGB(100, 180, 100),
        TabTextColor = Color3.fromRGB(235, 245, 235),
        SelectedTabTextColor = Color3.fromRGB(20, 35, 25),
        
        Element = Color3.fromRGB(28, 48, 32),
        ElementBackground = Color3.fromRGB(28, 48, 32),
        ElementBackgroundHover = Color3.fromRGB(35, 58, 40),
        SecondaryElementBackground = Color3.fromRGB(20, 35, 25),
        ElementStroke = Color3.fromRGB(55, 90, 60),
        SecondaryElementStroke = Color3.fromRGB(45, 75, 50),
        ElementBorder = Color3.fromRGB(55, 90, 60),
        ElementTransparency = 0.88,
        HoverChange = 0.04,
        
        SliderBackground = Color3.fromRGB(80, 160, 90),
        SliderProgress = Color3.fromRGB(100, 180, 100),
        SliderStroke = Color3.fromRGB(130, 200, 130),
        
        ToggleBackground = Color3.fromRGB(22, 38, 26),
        ToggleEnabled = Color3.fromRGB(100, 180, 100),
        ToggleDisabled = Color3.fromRGB(60, 90, 65),
        ToggleEnabledStroke = Color3.fromRGB(130, 200, 130),
        ToggleDisabledStroke = Color3.fromRGB(75, 110, 80),
        ToggleEnabledOuterStroke = Color3.fromRGB(70, 100, 75),
        ToggleDisabledOuterStroke = Color3.fromRGB(45, 65, 48),
        
        DropdownSelected = Color3.fromRGB(38, 62, 42),
        DropdownUnselected = Color3.fromRGB(25, 42, 30),
        
        Input = Color3.fromRGB(25, 42, 30),
        InputFocused = Color3.fromRGB(22, 38, 26),
        InputStroke = Color3.fromRGB(70, 120, 75),
        InputIndicator = Color3.fromRGB(100, 180, 100),
        PlaceholderColor = Color3.fromRGB(140, 170, 145),
        InElementBorder = Color3.fromRGB(55, 90, 60),
        
        Dialog = Color3.fromRGB(25, 42, 30),
        DialogBorder = Color3.fromRGB(100, 180, 100),
        DialogButton = Color3.fromRGB(32, 52, 36),
        DialogButtonBorder = Color3.fromRGB(70, 120, 75),
        DialogHolder = Color3.fromRGB(18, 30, 22),
        DialogHolderLine = Color3.fromRGB(50, 80, 55),
        DialogInput = Color3.fromRGB(28, 48, 32),
        DialogInputLine = Color3.fromRGB(120, 180, 125),
        
        Text = Color3.fromRGB(235, 245, 235),
        SubText = Color3.fromRGB(160, 190, 165),
        
        Hover = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(100, 180, 100),
        TitleBarLine = Color3.fromRGB(55, 90, 60),
        
        AcrylicMain = Color3.fromRGB(15, 25, 18),
        AcrylicBorder = Color3.fromRGB(70, 120, 75),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 48, 32)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 22, 15))
        }),
        AcrylicNoise = 0.90
    }
    
    -- ============================================
    -- LAVENDER THEME (Soft Purple Pastels)
    -- ============================================
    Themes.Lavender = {
        TextColor = Color3.fromRGB(60, 50, 80),
        Background = Color3.fromRGB(245, 240, 250),
        Topbar = Color3.fromRGB(235, 228, 245),
        Shadow = Color3.fromRGB(200, 190, 215),
        
        NotificationBackground = Color3.fromRGB(240, 235, 250),
        NotificationActionsBackground = Color3.fromRGB(160, 130, 200),
        
        Tab = Color3.fromRGB(210, 200, 230),
        TabStroke = Color3.fromRGB(180, 165, 210),
        TabBackgroundSelected = Color3.fromRGB(160, 130, 200),
        TabTextColor = Color3.fromRGB(80, 65, 110),
        SelectedTabTextColor = Color3.fromRGB(255, 255, 255),
        
        Element = Color3.fromRGB(235, 230, 245),
        ElementBackground = Color3.fromRGB(235, 230, 245),
        ElementBackgroundHover = Color3.fromRGB(225, 218, 240),
        SecondaryElementBackground = Color3.fromRGB(240, 235, 250),
        ElementStroke = Color3.fromRGB(200, 188, 220),
        SecondaryElementStroke = Color3.fromRGB(210, 200, 228),
        ElementBorder = Color3.fromRGB(200, 188, 220),
        ElementTransparency = 0.75,
        HoverChange = 0.04,
        
        SliderBackground = Color3.fromRGB(160, 130, 200),
        SliderProgress = Color3.fromRGB(160, 130, 200),
        SliderStroke = Color3.fromRGB(180, 150, 215),
        
        ToggleBackground = Color3.fromRGB(230, 224, 242),
        ToggleEnabled = Color3.fromRGB(160, 130, 200),
        ToggleDisabled = Color3.fromRGB(200, 192, 215),
        ToggleEnabledStroke = Color3.fromRGB(180, 150, 215),
        ToggleDisabledStroke = Color3.fromRGB(210, 200, 225),
        ToggleEnabledOuterStroke = Color3.fromRGB(175, 160, 195),
        ToggleDisabledOuterStroke = Color3.fromRGB(200, 192, 215),
        
        DropdownSelected = Color3.fromRGB(225, 218, 240),
        DropdownUnselected = Color3.fromRGB(235, 230, 248),
        
        Input = Color3.fromRGB(250, 248, 255),
        InputFocused = Color3.fromRGB(240, 235, 252),
        InputStroke = Color3.fromRGB(190, 175, 210),
        InputIndicator = Color3.fromRGB(160, 130, 200),
        PlaceholderColor = Color3.fromRGB(150, 140, 170),
        InElementBorder = Color3.fromRGB(200, 188, 220),
        
        Dialog = Color3.fromRGB(240, 235, 250),
        DialogBorder = Color3.fromRGB(160, 130, 200),
        DialogButton = Color3.fromRGB(235, 230, 248),
        DialogButtonBorder = Color3.fromRGB(190, 175, 210),
        DialogHolder = Color3.fromRGB(245, 240, 252),
        DialogHolderLine = Color3.fromRGB(210, 200, 225),
        DialogInput = Color3.fromRGB(250, 248, 255),
        DialogInputLine = Color3.fromRGB(160, 140, 185),
        
        Text = Color3.fromRGB(60, 50, 80),
        SubText = Color3.fromRGB(120, 105, 145),
        
        Hover = Color3.fromRGB(0, 0, 0),
        Accent = Color3.fromRGB(160, 130, 200),
        TitleBarLine = Color3.fromRGB(200, 188, 220),
        
        AcrylicMain = Color3.fromRGB(242, 238, 250),
        AcrylicBorder = Color3.fromRGB(185, 170, 205),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 235, 250)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 225, 245))
        }),
        AcrylicNoise = 0.75
    }
    
    -- ============================================
    -- CRIMSON THEME (Deep Reds/Blacks)
    -- ============================================
    Themes.Crimson = {
        TextColor = Color3.fromRGB(255, 245, 245),
        Background = Color3.fromRGB(20, 12, 15),
        Topbar = Color3.fromRGB(35, 18, 22),
        Shadow = Color3.fromRGB(15, 8, 10),
        
        NotificationBackground = Color3.fromRGB(25, 14, 18),
        NotificationActionsBackground = Color3.fromRGB(180, 50, 60),
        
        Tab = Color3.fromRGB(65, 30, 38),
        TabStroke = Color3.fromRGB(120, 45, 55),
        TabBackgroundSelected = Color3.fromRGB(180, 50, 60),
        TabTextColor = Color3.fromRGB(255, 245, 245),
        SelectedTabTextColor = Color3.fromRGB(255, 255, 255),
        
        Element = Color3.fromRGB(35, 18, 22),
        ElementBackground = Color3.fromRGB(35, 18, 22),
        ElementBackgroundHover = Color3.fromRGB(48, 25, 30),
        SecondaryElementBackground = Color3.fromRGB(25, 14, 18),
        ElementStroke = Color3.fromRGB(80, 35, 42),
        SecondaryElementStroke = Color3.fromRGB(65, 28, 35),
        ElementBorder = Color3.fromRGB(80, 35, 42),
        ElementTransparency = 0.87,
        HoverChange = 0.05,
        
        SliderBackground = Color3.fromRGB(180, 50, 60),
        SliderProgress = Color3.fromRGB(200, 60, 70),
        SliderStroke = Color3.fromRGB(220, 80, 90),
        
        ToggleBackground = Color3.fromRGB(30, 15, 18),
        ToggleEnabled = Color3.fromRGB(200, 60, 70),
        ToggleDisabled = Color3.fromRGB(80, 40, 48),
        ToggleEnabledStroke = Color3.fromRGB(220, 80, 90),
        ToggleDisabledStroke = Color3.fromRGB(100, 50, 58),
        ToggleEnabledOuterStroke = Color3.fromRGB(100, 50, 60),
        ToggleDisabledOuterStroke = Color3.fromRGB(60, 30, 36),
        
        DropdownSelected = Color3.fromRGB(50, 25, 30),
        DropdownUnselected = Color3.fromRGB(35, 18, 22),
        
        Input = Color3.fromRGB(35, 18, 22),
        InputFocused = Color3.fromRGB(30, 15, 18),
        InputStroke = Color3.fromRGB(100, 45, 52),
        InputIndicator = Color3.fromRGB(180, 50, 60),
        PlaceholderColor = Color3.fromRGB(160, 130, 135),
        InElementBorder = Color3.fromRGB(80, 35, 42),
        
        Dialog = Color3.fromRGB(35, 18, 22),
        DialogBorder = Color3.fromRGB(180, 50, 60),
        DialogButton = Color3.fromRGB(45, 22, 28),
        DialogButtonBorder = Color3.fromRGB(100, 45, 52),
        DialogHolder = Color3.fromRGB(20, 12, 15),
        DialogHolderLine = Color3.fromRGB(70, 32, 38),
        DialogInput = Color3.fromRGB(40, 20, 25),
        DialogInputLine = Color3.fromRGB(160, 60, 70),
        
        Text = Color3.fromRGB(255, 245, 245),
        SubText = Color3.fromRGB(190, 165, 170),
        
        Hover = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(200, 60, 70),
        TitleBarLine = Color3.fromRGB(80, 35, 42),
        
        AcrylicMain = Color3.fromRGB(18, 10, 12),
        AcrylicBorder = Color3.fromRGB(100, 45, 52),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 20, 25)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 8, 10))
        }),
        AcrylicNoise = 0.90
    }
    
    -- ============================================
    -- ICE THEME (Cool Blues/Whites)
    -- ============================================
    Themes.Ice = {
        TextColor = Color3.fromRGB(40, 55, 75),
        Background = Color3.fromRGB(240, 248, 255),
        Topbar = Color3.fromRGB(230, 240, 250),
        Shadow = Color3.fromRGB(200, 218, 235),
        
        NotificationBackground = Color3.fromRGB(235, 245, 255),
        NotificationActionsBackground = Color3.fromRGB(100, 160, 220),
        
        Tab = Color3.fromRGB(200, 220, 240),
        TabStroke = Color3.fromRGB(170, 195, 220),
        TabBackgroundSelected = Color3.fromRGB(100, 160, 220),
        TabTextColor = Color3.fromRGB(50, 70, 100),
        SelectedTabTextColor = Color3.fromRGB(255, 255, 255),
        
        Element = Color3.fromRGB(230, 240, 250),
        ElementBackground = Color3.fromRGB(230, 240, 250),
        ElementBackgroundHover = Color3.fromRGB(220, 232, 245),
        SecondaryElementBackground = Color3.fromRGB(235, 245, 255),
        ElementStroke = Color3.fromRGB(190, 210, 230),
        SecondaryElementStroke = Color3.fromRGB(200, 218, 238),
        ElementBorder = Color3.fromRGB(190, 210, 230),
        ElementTransparency = 0.75,
        HoverChange = 0.04,
        
        SliderBackground = Color3.fromRGB(100, 160, 220),
        SliderProgress = Color3.fromRGB(100, 160, 220),
        SliderStroke = Color3.fromRGB(130, 185, 240),
        
        ToggleBackground = Color3.fromRGB(225, 238, 250),
        ToggleEnabled = Color3.fromRGB(100, 160, 220),
        ToggleDisabled = Color3.fromRGB(180, 198, 218),
        ToggleEnabledStroke = Color3.fromRGB(130, 185, 240),
        ToggleDisabledStroke = Color3.fromRGB(195, 210, 228),
        ToggleEnabledOuterStroke = Color3.fromRGB(160, 180, 200),
        ToggleDisabledOuterStroke = Color3.fromRGB(185, 200, 218),
        
        DropdownSelected = Color3.fromRGB(218, 232, 248),
        DropdownUnselected = Color3.fromRGB(230, 242, 255),
        
        Input = Color3.fromRGB(248, 252, 255),
        InputFocused = Color3.fromRGB(240, 248, 255),
        InputStroke = Color3.fromRGB(175, 195, 218),
        InputIndicator = Color3.fromRGB(100, 160, 220),
        PlaceholderColor = Color3.fromRGB(130, 150, 175),
        InElementBorder = Color3.fromRGB(190, 210, 230),
        
        Dialog = Color3.fromRGB(235, 245, 255),
        DialogBorder = Color3.fromRGB(100, 160, 220),
        DialogButton = Color3.fromRGB(230, 242, 255),
        DialogButtonBorder = Color3.fromRGB(175, 195, 218),
        DialogHolder = Color3.fromRGB(242, 250, 255),
        DialogHolderLine = Color3.fromRGB(200, 218, 235),
        DialogInput = Color3.fromRGB(248, 252, 255),
        DialogInputLine = Color3.fromRGB(120, 155, 195),
        
        Text = Color3.fromRGB(40, 55, 75),
        SubText = Color3.fromRGB(100, 125, 155),
        
        Hover = Color3.fromRGB(0, 0, 0),
        Accent = Color3.fromRGB(100, 160, 220),
        TitleBarLine = Color3.fromRGB(190, 210, 230),
        
        AcrylicMain = Color3.fromRGB(238, 248, 255),
        AcrylicBorder = Color3.fromRGB(170, 192, 218),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(235, 245, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(225, 238, 250))
        }),
        AcrylicNoise = 0.72
    }
    
    -- ============================================
    -- MOCHA THEME (Warm Browns/Coffee)
    -- ============================================
    Themes.Mocha = {
        TextColor = Color3.fromRGB(250, 245, 240),
        Background = Color3.fromRGB(32, 25, 22),
        Topbar = Color3.fromRGB(45, 35, 30),
        Shadow = Color3.fromRGB(22, 18, 15),
        
        NotificationBackground = Color3.fromRGB(38, 30, 26),
        NotificationActionsBackground = Color3.fromRGB(165, 120, 80),
        
        Tab = Color3.fromRGB(75, 58, 48),
        TabStroke = Color3.fromRGB(110, 85, 65),
        TabBackgroundSelected = Color3.fromRGB(165, 120, 80),
        TabTextColor = Color3.fromRGB(250, 245, 240),
        SelectedTabTextColor = Color3.fromRGB(35, 28, 24),
        
        Element = Color3.fromRGB(48, 38, 32),
        ElementBackground = Color3.fromRGB(48, 38, 32),
        ElementBackgroundHover = Color3.fromRGB(58, 46, 40),
        SecondaryElementBackground = Color3.fromRGB(38, 30, 26),
        ElementStroke = Color3.fromRGB(80, 62, 52),
        SecondaryElementStroke = Color3.fromRGB(68, 54, 45),
        ElementBorder = Color3.fromRGB(80, 62, 52),
        ElementTransparency = 0.87,
        HoverChange = 0.04,
        
        SliderBackground = Color3.fromRGB(165, 120, 80),
        SliderProgress = Color3.fromRGB(180, 135, 95),
        SliderStroke = Color3.fromRGB(200, 155, 115),
        
        ToggleBackground = Color3.fromRGB(42, 34, 28),
        ToggleEnabled = Color3.fromRGB(180, 135, 95),
        ToggleDisabled = Color3.fromRGB(90, 72, 62),
        ToggleEnabledStroke = Color3.fromRGB(200, 155, 115),
        ToggleDisabledStroke = Color3.fromRGB(110, 88, 75),
        ToggleEnabledOuterStroke = Color3.fromRGB(100, 80, 68),
        ToggleDisabledOuterStroke = Color3.fromRGB(70, 58, 50),
        
        DropdownSelected = Color3.fromRGB(62, 48, 42),
        DropdownUnselected = Color3.fromRGB(48, 38, 32),
        
        Input = Color3.fromRGB(48, 38, 32),
        InputFocused = Color3.fromRGB(42, 34, 28),
        InputStroke = Color3.fromRGB(100, 78, 65),
        InputIndicator = Color3.fromRGB(165, 120, 80),
        PlaceholderColor = Color3.fromRGB(160, 145, 135),
        InElementBorder = Color3.fromRGB(80, 62, 52),
        
        Dialog = Color3.fromRGB(45, 35, 30),
        DialogBorder = Color3.fromRGB(165, 120, 80),
        DialogButton = Color3.fromRGB(55, 44, 38),
        DialogButtonBorder = Color3.fromRGB(100, 78, 65),
        DialogHolder = Color3.fromRGB(32, 25, 22),
        DialogHolderLine = Color3.fromRGB(72, 56, 48),
        DialogInput = Color3.fromRGB(52, 42, 36),
        DialogInputLine = Color3.fromRGB(145, 110, 80),
        
        Text = Color3.fromRGB(250, 245, 240),
        SubText = Color3.fromRGB(195, 180, 170),
        
        Hover = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(180, 135, 95),
        TitleBarLine = Color3.fromRGB(80, 62, 52),
        
        AcrylicMain = Color3.fromRGB(28, 22, 18),
        AcrylicBorder = Color3.fromRGB(95, 75, 62),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 40, 34)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 18, 15))
        }),
        AcrylicNoise = 0.90
    }
    
    -- ============================================
    -- NEON THEME (Bright Fluorescent)
    -- ============================================
    Themes.Neon = {
        TextColor = Color3.fromRGB(255, 255, 255),
        Background = Color3.fromRGB(8, 8, 12),
        Topbar = Color3.fromRGB(15, 15, 22),
        Shadow = Color3.fromRGB(5, 5, 8),
        
        NotificationBackground = Color3.fromRGB(12, 12, 18),
        NotificationActionsBackground = Color3.fromRGB(0, 255, 128),
        
        Tab = Color3.fromRGB(30, 30, 45),
        TabStroke = Color3.fromRGB(0, 255, 128),
        TabBackgroundSelected = Color3.fromRGB(0, 255, 128),
        TabTextColor = Color3.fromRGB(255, 255, 255),
        SelectedTabTextColor = Color3.fromRGB(0, 0, 0),
        
        Element = Color3.fromRGB(18, 18, 28),
        ElementBackground = Color3.fromRGB(18, 18, 28),
        ElementBackgroundHover = Color3.fromRGB(25, 25, 38),
        SecondaryElementBackground = Color3.fromRGB(12, 12, 18),
        ElementStroke = Color3.fromRGB(0, 200, 100),
        SecondaryElementStroke = Color3.fromRGB(0, 150, 75),
        ElementBorder = Color3.fromRGB(0, 200, 100),
        ElementTransparency = 0.88,
        HoverChange = 0.05,
        
        SliderBackground = Color3.fromRGB(0, 255, 128),
        SliderProgress = Color3.fromRGB(0, 255, 128),
        SliderStroke = Color3.fromRGB(100, 255, 180),
        
        ToggleBackground = Color3.fromRGB(15, 15, 22),
        ToggleEnabled = Color3.fromRGB(0, 255, 128),
        ToggleDisabled = Color3.fromRGB(50, 50, 70),
        ToggleEnabledStroke = Color3.fromRGB(100, 255, 180),
        ToggleDisabledStroke = Color3.fromRGB(70, 70, 95),
        ToggleEnabledOuterStroke = Color3.fromRGB(0, 180, 90),
        ToggleDisabledOuterStroke = Color3.fromRGB(40, 40, 55),
        
        DropdownSelected = Color3.fromRGB(25, 25, 38),
        DropdownUnselected = Color3.fromRGB(15, 15, 22),
        
        Input = Color3.fromRGB(15, 15, 22),
        InputFocused = Color3.fromRGB(12, 12, 18),
        InputStroke = Color3.fromRGB(0, 200, 100),
        InputIndicator = Color3.fromRGB(0, 255, 128),
        PlaceholderColor = Color3.fromRGB(120, 140, 130),
        InElementBorder = Color3.fromRGB(0, 200, 100),
        
        Dialog = Color3.fromRGB(15, 15, 22),
        DialogBorder = Color3.fromRGB(0, 255, 128),
        DialogButton = Color3.fromRGB(22, 22, 32),
        DialogButtonBorder = Color3.fromRGB(0, 200, 100),
        DialogHolder = Color3.fromRGB(8, 8, 12),
        DialogHolderLine = Color3.fromRGB(0, 150, 75),
        DialogInput = Color3.fromRGB(18, 18, 28),
        DialogInputLine = Color3.fromRGB(0, 220, 110),
        
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(150, 180, 165),
        
        Hover = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(0, 255, 128),
        TitleBarLine = Color3.fromRGB(0, 180, 90),
        
        AcrylicMain = Color3.fromRGB(6, 6, 10),
        AcrylicBorder = Color3.fromRGB(0, 180, 90),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 20, 18)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 5, 8))
        }),
        AcrylicNoise = 0.92
    }
    
    -- ============================================
    -- SLATE THEME (Gray Tones)
    -- ============================================
    Themes.Slate = {
        TextColor = Color3.fromRGB(235, 235, 240),
        Background = Color3.fromRGB(40, 44, 52),
        Topbar = Color3.fromRGB(55, 60, 70),
        Shadow = Color3.fromRGB(30, 33, 40),
        
        NotificationBackground = Color3.fromRGB(48, 52, 62),
        NotificationActionsBackground = Color3.fromRGB(140, 150, 170),
        
        Tab = Color3.fromRGB(80, 88, 100),
        TabStroke = Color3.fromRGB(100, 110, 125),
        TabBackgroundSelected = Color3.fromRGB(140, 150, 170),
        TabTextColor = Color3.fromRGB(235, 235, 240),
        SelectedTabTextColor = Color3.fromRGB(45, 50, 58),
        
        Element = Color3.fromRGB(55, 60, 70),
        ElementBackground = Color3.fromRGB(55, 60, 70),
        ElementBackgroundHover = Color3.fromRGB(65, 72, 82),
        SecondaryElementBackground = Color3.fromRGB(48, 52, 62),
        ElementStroke = Color3.fromRGB(85, 92, 105),
        SecondaryElementStroke = Color3.fromRGB(75, 82, 95),
        ElementBorder = Color3.fromRGB(85, 92, 105),
        ElementTransparency = 0.87,
        HoverChange = 0.04,
        
        SliderBackground = Color3.fromRGB(140, 150, 170),
        SliderProgress = Color3.fromRGB(150, 162, 182),
        SliderStroke = Color3.fromRGB(175, 185, 205),
        
        ToggleBackground = Color3.fromRGB(50, 55, 65),
        ToggleEnabled = Color3.fromRGB(150, 162, 182),
        ToggleDisabled = Color3.fromRGB(85, 92, 105),
        ToggleEnabledStroke = Color3.fromRGB(175, 185, 205),
        ToggleDisabledStroke = Color3.fromRGB(105, 112, 125),
        ToggleEnabledOuterStroke = Color3.fromRGB(115, 125, 140),
        ToggleDisabledOuterStroke = Color3.fromRGB(72, 78, 90),
        
        DropdownSelected = Color3.fromRGB(68, 75, 88),
        DropdownUnselected = Color3.fromRGB(55, 60, 70),
        
        Input = Color3.fromRGB(55, 60, 70),
        InputFocused = Color3.fromRGB(50, 55, 65),
        InputStroke = Color3.fromRGB(110, 118, 132),
        InputIndicator = Color3.fromRGB(140, 150, 170),
        PlaceholderColor = Color3.fromRGB(145, 152, 165),
        InElementBorder = Color3.fromRGB(85, 92, 105),
        
        Dialog = Color3.fromRGB(55, 60, 70),
        DialogBorder = Color3.fromRGB(140, 150, 170),
        DialogButton = Color3.fromRGB(65, 72, 82),
        DialogButtonBorder = Color3.fromRGB(110, 118, 132),
        DialogHolder = Color3.fromRGB(40, 44, 52),
        DialogHolderLine = Color3.fromRGB(80, 88, 100),
        DialogInput = Color3.fromRGB(60, 66, 78),
        DialogInputLine = Color3.fromRGB(130, 140, 158),
        
        Text = Color3.fromRGB(235, 235, 240),
        SubText = Color3.fromRGB(165, 172, 185),
        
        Hover = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(150, 162, 182),
        TitleBarLine = Color3.fromRGB(85, 92, 105),
        
        AcrylicMain = Color3.fromRGB(35, 38, 45),
        AcrylicBorder = Color3.fromRGB(100, 108, 122),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(58, 64, 75)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 33, 40))
        }),
        AcrylicNoise = 0.88
    }
    
    -- ============================================
    -- COPPER THEME (Metallic Oranges)
    -- ============================================
    Themes.Copper = {
        TextColor = Color3.fromRGB(255, 248, 240),
        Background = Color3.fromRGB(35, 28, 25),
        Topbar = Color3.fromRGB(50, 38, 32),
        Shadow = Color3.fromRGB(25, 20, 18),
        
        NotificationBackground = Color3.fromRGB(42, 32, 28),
        NotificationActionsBackground = Color3.fromRGB(200, 130, 80),
        
        Tab = Color3.fromRGB(85, 60, 48),
        TabStroke = Color3.fromRGB(140, 95, 70),
        TabBackgroundSelected = Color3.fromRGB(200, 130, 80),
        TabTextColor = Color3.fromRGB(255, 248, 240),
        SelectedTabTextColor = Color3.fromRGB(40, 30, 25),
        
        Element = Color3.fromRGB(55, 42, 35),
        ElementBackground = Color3.fromRGB(55, 42, 35),
        ElementBackgroundHover = Color3.fromRGB(68, 52, 44),
        SecondaryElementBackground = Color3.fromRGB(42, 32, 28),
        ElementStroke = Color3.fromRGB(100, 72, 58),
        SecondaryElementStroke = Color3.fromRGB(85, 62, 50),
        ElementBorder = Color3.fromRGB(100, 72, 58),
        ElementTransparency = 0.86,
        HoverChange = 0.05,
        
        SliderBackground = Color3.fromRGB(200, 130, 80),
        SliderProgress = Color3.fromRGB(215, 145, 95),
        SliderStroke = Color3.fromRGB(235, 170, 120),
        
        ToggleBackground = Color3.fromRGB(48, 36, 30),
        ToggleEnabled = Color3.fromRGB(215, 145, 95),
        ToggleDisabled = Color3.fromRGB(95, 72, 60),
        ToggleEnabledStroke = Color3.fromRGB(235, 170, 120),
        ToggleDisabledStroke = Color3.fromRGB(118, 90, 75),
        ToggleEnabledOuterStroke = Color3.fromRGB(120, 88, 70),
        ToggleDisabledOuterStroke = Color3.fromRGB(75, 58, 50),
        
        DropdownSelected = Color3.fromRGB(72, 55, 46),
        DropdownUnselected = Color3.fromRGB(55, 42, 35),
        
        Input = Color3.fromRGB(55, 42, 35),
        InputFocused = Color3.fromRGB(48, 36, 30),
        InputStroke = Color3.fromRGB(130, 95, 78),
        InputIndicator = Color3.fromRGB(200, 130, 80),
        PlaceholderColor = Color3.fromRGB(175, 155, 145),
        InElementBorder = Color3.fromRGB(100, 72, 58),
        
        Dialog = Color3.fromRGB(50, 38, 32),
        DialogBorder = Color3.fromRGB(200, 130, 80),
        DialogButton = Color3.fromRGB(62, 48, 40),
        DialogButtonBorder = Color3.fromRGB(130, 95, 78),
        DialogHolder = Color3.fromRGB(35, 28, 25),
        DialogHolderLine = Color3.fromRGB(88, 65, 55),
        DialogInput = Color3.fromRGB(58, 45, 38),
        DialogInputLine = Color3.fromRGB(180, 120, 85),
        
        Text = Color3.fromRGB(255, 248, 240),
        SubText = Color3.fromRGB(200, 180, 168),
        
        Hover = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(215, 145, 95),
        TitleBarLine = Color3.fromRGB(100, 72, 58),
        
        AcrylicMain = Color3.fromRGB(30, 24, 22),
        AcrylicBorder = Color3.fromRGB(120, 88, 70),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(58, 45, 38)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 20, 18))
        }),
        AcrylicNoise = 0.88
    }
    
    -- ============================================
    -- EMERALD THEME (Rich Greens)
    -- ============================================
    Themes.Emerald = {
        TextColor = Color3.fromRGB(240, 255, 245),
        Background = Color3.fromRGB(12, 35, 28),
        Topbar = Color3.fromRGB(18, 48, 38),
        Shadow = Color3.fromRGB(8, 25, 20),
        
        NotificationBackground = Color3.fromRGB(15, 42, 33),
        NotificationActionsBackground = Color3.fromRGB(50, 180, 120),
        
        Tab = Color3.fromRGB(35, 85, 68),
        TabStroke = Color3.fromRGB(60, 130, 100),
        TabBackgroundSelected = Color3.fromRGB(50, 180, 120),
        TabTextColor = Color3.fromRGB(240, 255, 245),
        SelectedTabTextColor = Color3.fromRGB(12, 35, 28),
        
        Element = Color3.fromRGB(22, 55, 44),
        ElementBackground = Color3.fromRGB(22, 55, 44),
        ElementBackgroundHover = Color3.fromRGB(28, 68, 54),
        SecondaryElementBackground = Color3.fromRGB(15, 42, 33),
        ElementStroke = Color3.fromRGB(45, 95, 75),
        SecondaryElementStroke = Color3.fromRGB(38, 80, 62),
        ElementBorder = Color3.fromRGB(45, 95, 75),
        ElementTransparency = 0.87,
        HoverChange = 0.04,
        
        SliderBackground = Color3.fromRGB(50, 180, 120),
        SliderProgress = Color3.fromRGB(65, 195, 135),
        SliderStroke = Color3.fromRGB(85, 215, 155),
        
        ToggleBackground = Color3.fromRGB(18, 48, 38),
        ToggleEnabled = Color3.fromRGB(65, 195, 135),
        ToggleDisabled = Color3.fromRGB(45, 85, 68),
        ToggleEnabledStroke = Color3.fromRGB(85, 215, 155),
        ToggleDisabledStroke = Color3.fromRGB(58, 105, 85),
        ToggleEnabledOuterStroke = Color3.fromRGB(50, 110, 85),
        ToggleDisabledOuterStroke = Color3.fromRGB(35, 68, 55),
        
        DropdownSelected = Color3.fromRGB(32, 72, 58),
        DropdownUnselected = Color3.fromRGB(22, 55, 44),
        
        Input = Color3.fromRGB(22, 55, 44),
        InputFocused = Color3.fromRGB(18, 48, 38),
        InputStroke = Color3.fromRGB(60, 115, 92),
        InputIndicator = Color3.fromRGB(50, 180, 120),
        PlaceholderColor = Color3.fromRGB(130, 175, 155),
        InElementBorder = Color3.fromRGB(45, 95, 75),
        
        Dialog = Color3.fromRGB(18, 48, 38),
        DialogBorder = Color3.fromRGB(50, 180, 120),
        DialogButton = Color3.fromRGB(26, 62, 50),
        DialogButtonBorder = Color3.fromRGB(60, 115, 92),
        DialogHolder = Color3.fromRGB(12, 35, 28),
        DialogHolderLine = Color3.fromRGB(42, 88, 70),
        DialogInput = Color3.fromRGB(24, 58, 46),
        DialogInputLine = Color3.fromRGB(70, 160, 115),
        
        Text = Color3.fromRGB(240, 255, 245),
        SubText = Color3.fromRGB(160, 200, 180),
        
        Hover = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(65, 195, 135),
        TitleBarLine = Color3.fromRGB(45, 95, 75),
        
        AcrylicMain = Color3.fromRGB(10, 30, 24),
        AcrylicBorder = Color3.fromRGB(55, 105, 85),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 60, 48)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 25, 20))
        }),
        AcrylicNoise = 0.90
    }
    
    -- ============================================
    -- SAPPHIRE THEME (Deep Blues)
    -- ============================================
    Themes.Sapphire = {
        TextColor = Color3.fromRGB(235, 245, 255),
        Background = Color3.fromRGB(12, 22, 45),
        Topbar = Color3.fromRGB(18, 32, 62),
        Shadow = Color3.fromRGB(8, 15, 32),
        
        NotificationBackground = Color3.fromRGB(15, 28, 55),
        NotificationActionsBackground = Color3.fromRGB(60, 120, 200),
        
        Tab = Color3.fromRGB(35, 60, 105),
        TabStroke = Color3.fromRGB(60, 95, 155),
        TabBackgroundSelected = Color3.fromRGB(60, 120, 200),
        TabTextColor = Color3.fromRGB(235, 245, 255),
        SelectedTabTextColor = Color3.fromRGB(255, 255, 255),
        
        Element = Color3.fromRGB(22, 40, 75),
        ElementBackground = Color3.fromRGB(22, 40, 75),
        ElementBackgroundHover = Color3.fromRGB(30, 52, 92),
        SecondaryElementBackground = Color3.fromRGB(15, 28, 55),
        ElementStroke = Color3.fromRGB(50, 80, 135),
        SecondaryElementStroke = Color3.fromRGB(42, 68, 115),
        ElementBorder = Color3.fromRGB(50, 80, 135),
        ElementTransparency = 0.86,
        HoverChange = 0.04,
        
        SliderBackground = Color3.fromRGB(60, 120, 200),
        SliderProgress = Color3.fromRGB(75, 140, 220),
        SliderStroke = Color3.fromRGB(100, 165, 240),
        
        ToggleBackground = Color3.fromRGB(18, 32, 62),
        ToggleEnabled = Color3.fromRGB(75, 140, 220),
        ToggleDisabled = Color3.fromRGB(45, 70, 115),
        ToggleEnabledStroke = Color3.fromRGB(100, 165, 240),
        ToggleDisabledStroke = Color3.fromRGB(62, 95, 145),
        ToggleEnabledOuterStroke = Color3.fromRGB(55, 92, 150),
        ToggleDisabledOuterStroke = Color3.fromRGB(38, 58, 95),
        
        DropdownSelected = Color3.fromRGB(32, 55, 100),
        DropdownUnselected = Color3.fromRGB(22, 40, 75),
        
        Input = Color3.fromRGB(22, 40, 75),
        InputFocused = Color3.fromRGB(18, 32, 62),
        InputStroke = Color3.fromRGB(65, 100, 160),
        InputIndicator = Color3.fromRGB(60, 120, 200),
        PlaceholderColor = Color3.fromRGB(140, 165, 200),
        InElementBorder = Color3.fromRGB(50, 80, 135),
        
        Dialog = Color3.fromRGB(18, 32, 62),
        DialogBorder = Color3.fromRGB(60, 120, 200),
        DialogButton = Color3.fromRGB(28, 48, 88),
        DialogButtonBorder = Color3.fromRGB(65, 100, 160),
        DialogHolder = Color3.fromRGB(12, 22, 45),
        DialogHolderLine = Color3.fromRGB(45, 72, 120),
        DialogInput = Color3.fromRGB(25, 44, 82),
        DialogInputLine = Color3.fromRGB(80, 130, 195),
        
        Text = Color3.fromRGB(235, 245, 255),
        SubText = Color3.fromRGB(160, 185, 220),
        
        Hover = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(75, 140, 220),
        TitleBarLine = Color3.fromRGB(50, 80, 135),
        
        AcrylicMain = Color3.fromRGB(10, 18, 38),
        AcrylicBorder = Color3.fromRGB(58, 92, 150),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 45, 85)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 15, 32))
        }),
        AcrylicNoise = 0.90
    }
    
    -- ============================================
    -- DRACULA THEME 
    -- ============================================
    Themes.Dracula = {
        TextColor = Color3.fromRGB(248, 248, 242),
        Background = Color3.fromRGB(40, 42, 54),
        Topbar = Color3.fromRGB(50, 52, 68),
        Shadow = Color3.fromRGB(30, 31, 41),
        
        NotificationBackground = Color3.fromRGB(45, 47, 60),
        NotificationActionsBackground = Color3.fromRGB(68, 71, 90),
        
        Tab = Color3.fromRGB(68, 71, 90),
        TabStroke = Color3.fromRGB(98, 114, 164),
        TabBackgroundSelected = Color3.fromRGB(189, 147, 249),
        TabTextColor = Color3.fromRGB(248, 248, 242),
        SelectedTabTextColor = Color3.fromRGB(40, 42, 54),
        
        Element = Color3.fromRGB(50, 52, 68),
        ElementBackground = Color3.fromRGB(50, 52, 68),
        ElementBackgroundHover = Color3.fromRGB(60, 62, 80),
        SecondaryElementBackground = Color3.fromRGB(45, 47, 62),
        ElementStroke = Color3.fromRGB(68, 71, 90),
        SecondaryElementStroke = Color3.fromRGB(62, 65, 85),
        ElementBorder = Color3.fromRGB(68, 71, 90),
        ElementTransparency = 0.88,
        HoverChange = 0.04,
        
        SliderBackground = Color3.fromRGB(139, 233, 253),
        SliderProgress = Color3.fromRGB(189, 147, 249),
        SliderStroke = Color3.fromRGB(255, 121, 198),
        
        ToggleBackground = Color3.fromRGB(50, 52, 68),
        ToggleEnabled = Color3.fromRGB(80, 250, 123),
        ToggleDisabled = Color3.fromRGB(98, 114, 164),
        ToggleEnabledStroke = Color3.fromRGB(80, 250, 123),
        ToggleDisabledStroke = Color3.fromRGB(108, 124, 174),
        ToggleEnabledOuterStroke = Color3.fromRGB(60, 190, 93),
        ToggleDisabledOuterStroke = Color3.fromRGB(58, 60, 78),
        
        DropdownSelected = Color3.fromRGB(60, 62, 80),
        DropdownUnselected = Color3.fromRGB(50, 52, 68),
        
        Input = Color3.fromRGB(50, 52, 68),
        InputFocused = Color3.fromRGB(45, 47, 60),
        InputStroke = Color3.fromRGB(98, 114, 164),
        InputIndicator = Color3.fromRGB(189, 147, 249),
        PlaceholderColor = Color3.fromRGB(98, 114, 164),
        InElementBorder = Color3.fromRGB(68, 71, 90),
        
        Dialog = Color3.fromRGB(45, 47, 60),
        DialogBorder = Color3.fromRGB(98, 114, 164),
        DialogButton = Color3.fromRGB(55, 57, 75),
        DialogButtonBorder = Color3.fromRGB(98, 114, 164),
        DialogHolder = Color3.fromRGB(40, 42, 54),
        DialogHolderLine = Color3.fromRGB(68, 71, 90),
        DialogInput = Color3.fromRGB(55, 57, 75),
        DialogInputLine = Color3.fromRGB(189, 147, 249),
        
        Text = Color3.fromRGB(248, 248, 242),
        SubText = Color3.fromRGB(98, 114, 164),
        
        Hover = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(189, 147, 249),
        TitleBarLine = Color3.fromRGB(68, 71, 90),
        
        AcrylicMain = Color3.fromRGB(40, 42, 54),
        AcrylicBorder = Color3.fromRGB(98, 114, 164),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 52, 68)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 31, 41))
        }),
        AcrylicNoise = 0.90
    }
    
    -- ============================================
    -- NORD THEME (Arctic-inspired)
    -- ============================================
    Themes.Nord = {
        TextColor = Color3.fromRGB(236, 239, 244),
        Background = Color3.fromRGB(46, 52, 64),
        Topbar = Color3.fromRGB(59, 66, 82),
        Shadow = Color3.fromRGB(36, 41, 51),
        
        NotificationBackground = Color3.fromRGB(59, 66, 82),
        NotificationActionsBackground = Color3.fromRGB(76, 86, 106),
        
        Tab = Color3.fromRGB(67, 76, 94),
        TabStroke = Color3.fromRGB(76, 86, 106),
        TabBackgroundSelected = Color3.fromRGB(136, 192, 208),
        TabTextColor = Color3.fromRGB(229, 233, 240),
        SelectedTabTextColor = Color3.fromRGB(46, 52, 64),
        
        Element = Color3.fromRGB(59, 66, 82),
        ElementBackground = Color3.fromRGB(59, 66, 82),
        ElementBackgroundHover = Color3.fromRGB(67, 76, 94),
        SecondaryElementBackground = Color3.fromRGB(52, 59, 73),
        ElementStroke = Color3.fromRGB(76, 86, 106),
        SecondaryElementStroke = Color3.fromRGB(70, 79, 98),
        ElementBorder = Color3.fromRGB(76, 86, 106),
        ElementTransparency = 0.88,
        HoverChange = 0.04,
        
        SliderBackground = Color3.fromRGB(129, 161, 193),
        SliderProgress = Color3.fromRGB(136, 192, 208),
        SliderStroke = Color3.fromRGB(143, 188, 187),
        
        ToggleBackground = Color3.fromRGB(59, 66, 82),
        ToggleEnabled = Color3.fromRGB(163, 190, 140),
        ToggleDisabled = Color3.fromRGB(76, 86, 106),
        ToggleEnabledStroke = Color3.fromRGB(163, 190, 140),
        ToggleDisabledStroke = Color3.fromRGB(86, 96, 116),
        ToggleEnabledOuterStroke = Color3.fromRGB(133, 160, 110),
        ToggleDisabledOuterStroke = Color3.fromRGB(56, 62, 76),
        
        DropdownSelected = Color3.fromRGB(67, 76, 94),
        DropdownUnselected = Color3.fromRGB(59, 66, 82),
        
        Input = Color3.fromRGB(59, 66, 82),
        InputFocused = Color3.fromRGB(52, 59, 73),
        InputStroke = Color3.fromRGB(76, 86, 106),
        InputIndicator = Color3.fromRGB(136, 192, 208),
        PlaceholderColor = Color3.fromRGB(76, 86, 106),
        InElementBorder = Color3.fromRGB(76, 86, 106),
        
        Dialog = Color3.fromRGB(52, 59, 73),
        DialogBorder = Color3.fromRGB(76, 86, 106),
        DialogButton = Color3.fromRGB(62, 70, 86),
        DialogButtonBorder = Color3.fromRGB(76, 86, 106),
        DialogHolder = Color3.fromRGB(46, 52, 64),
        DialogHolderLine = Color3.fromRGB(67, 76, 94),
        DialogInput = Color3.fromRGB(62, 70, 86),
        DialogInputLine = Color3.fromRGB(136, 192, 208),
        
        Text = Color3.fromRGB(236, 239, 244),
        SubText = Color3.fromRGB(129, 161, 193),
        
        Hover = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(136, 192, 208),
        TitleBarLine = Color3.fromRGB(76, 86, 106),
        
        AcrylicMain = Color3.fromRGB(46, 52, 64),
        AcrylicBorder = Color3.fromRGB(76, 86, 106),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(59, 66, 82)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(36, 41, 51))
        }),
        AcrylicNoise = 0.90
    }
    
    -- ============================================
    -- GRUVBOX THEME (Retro warm palette)
    -- ============================================
    Themes.Gruvbox = {
        TextColor = Color3.fromRGB(235, 219, 178),
        Background = Color3.fromRGB(40, 40, 40),
        Topbar = Color3.fromRGB(50, 48, 47),
        Shadow = Color3.fromRGB(29, 32, 33),
        
        NotificationBackground = Color3.fromRGB(50, 48, 47),
        NotificationActionsBackground = Color3.fromRGB(80, 73, 69),
        
        Tab = Color3.fromRGB(60, 56, 54),
        TabStroke = Color3.fromRGB(80, 73, 69),
        TabBackgroundSelected = Color3.fromRGB(215, 153, 33),
        TabTextColor = Color3.fromRGB(235, 219, 178),
        SelectedTabTextColor = Color3.fromRGB(40, 40, 40),
        
        Element = Color3.fromRGB(50, 48, 47),
        ElementBackground = Color3.fromRGB(50, 48, 47),
        ElementBackgroundHover = Color3.fromRGB(60, 56, 54),
        SecondaryElementBackground = Color3.fromRGB(45, 43, 42),
        ElementStroke = Color3.fromRGB(80, 73, 69),
        SecondaryElementStroke = Color3.fromRGB(70, 64, 60),
        ElementBorder = Color3.fromRGB(102, 92, 84),
        ElementTransparency = 0.88,
        HoverChange = 0.04,
        
        SliderBackground = Color3.fromRGB(215, 153, 33),
        SliderProgress = Color3.fromRGB(250, 189, 47),
        SliderStroke = Color3.fromRGB(254, 128, 25),
        
        ToggleBackground = Color3.fromRGB(50, 48, 47),
        ToggleEnabled = Color3.fromRGB(152, 151, 26),
        ToggleDisabled = Color3.fromRGB(80, 73, 69),
        ToggleEnabledStroke = Color3.fromRGB(184, 187, 38),
        ToggleDisabledStroke = Color3.fromRGB(90, 83, 79),
        ToggleEnabledOuterStroke = Color3.fromRGB(122, 121, 16),
        ToggleDisabledOuterStroke = Color3.fromRGB(60, 56, 54),
        
        DropdownSelected = Color3.fromRGB(60, 56, 54),
        DropdownUnselected = Color3.fromRGB(50, 48, 47),
        
        Input = Color3.fromRGB(50, 48, 47),
        InputFocused = Color3.fromRGB(45, 43, 42),
        InputStroke = Color3.fromRGB(80, 73, 69),
        InputIndicator = Color3.fromRGB(215, 153, 33),
        PlaceholderColor = Color3.fromRGB(146, 131, 116),
        InElementBorder = Color3.fromRGB(102, 92, 84),
        
        Dialog = Color3.fromRGB(45, 43, 42),
        DialogBorder = Color3.fromRGB(102, 92, 84),
        DialogButton = Color3.fromRGB(55, 52, 50),
        DialogButtonBorder = Color3.fromRGB(102, 92, 84),
        DialogHolder = Color3.fromRGB(40, 40, 40),
        DialogHolderLine = Color3.fromRGB(80, 73, 69),
        DialogInput = Color3.fromRGB(55, 52, 50),
        DialogInputLine = Color3.fromRGB(215, 153, 33),
        
        Text = Color3.fromRGB(235, 219, 178),
        SubText = Color3.fromRGB(168, 153, 132),
        
        Hover = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(215, 153, 33),
        TitleBarLine = Color3.fromRGB(80, 73, 69),
        
        AcrylicMain = Color3.fromRGB(40, 40, 40),
        AcrylicBorder = Color3.fromRGB(102, 92, 84),
        AcrylicGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 48, 47)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(29, 32, 33))
        }),
        AcrylicNoise = 0.90
    }
    
    return Themes
    
    
end

-- Module: Core/Creator
_modules["Core/Creator"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                       GUI Framework                           ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
    ]]
    local Creator = {}
    Creator.Signals = {}
    Creator.Themes = {}
    Creator.ThemeObjects = {}
    Creator.DefaultProperties = {}
    
    local Services = _require("Core/Services")
    local TweenService = Services.TweenService
    
    -- ============================================
    -- ELEMENT FACTORY
    -- ============================================
    
    function Creator.New(className, properties, children)
        local instance = Instance.new(className)
        
        -- Apply default properties for this class
        if Creator.DefaultProperties[className] then
            for prop, value in pairs(Creator.DefaultProperties[className]) do
                instance[prop] = value
            end
        end
        
        -- Apply provided properties
        if properties then
            for prop, value in pairs(properties) do
                if prop == "ThemeTag" then
                    Creator.ApplyThemeTag(instance, value)
                else
                    instance[prop] = value
                end
            end
        end
        
        -- Add children
        if children then
            for _, child in ipairs(children) do
                if typeof(child) == "Instance" then
                    child.Parent = instance
                end
            end
        end
        
        return instance
    end
    
    -- ============================================
    -- THEME TAG SYSTEM
    -- ============================================
    
    function Creator.ApplyThemeTag(object, tags)
        if not Creator.ThemeObjects[object] then
            Creator.ThemeObjects[object] = {}
        end
        
        for property, themeProp in pairs(tags) do
            Creator.ThemeObjects[object][property] = themeProp
        end
        
        -- Apply current theme immediately
        Creator.UpdateObjectTheme(object)
        
        -- Clean up on destroy
        object.Destroying:Connect(function()
            Creator.ThemeObjects[object] = nil
        end)
    end
    
    function Creator.UpdateObjectTheme(object)
        local tags = Creator.ThemeObjects[object]
        if not tags then return end
        
        local theme = Creator.GetCurrentTheme()
        for property, themeProp in pairs(tags) do
            if theme[themeProp] ~= nil then
                object[property] = theme[themeProp]
            end
        end
    end
    
    function Creator.UpdateAllThemes()
        for object, _ in pairs(Creator.ThemeObjects) do
            if object and object.Parent then
                Creator.UpdateObjectTheme(object)
            else
                Creator.ThemeObjects[object] = nil
            end
        end
    end
    
    function Creator.GetCurrentTheme()
        return Creator.CurrentTheme or Creator.Themes.Dark or {}
    end
    
    function Creator.SetTheme(theme)
        if type(theme) == "string" then
            Creator.CurrentTheme = Creator.Themes[theme]
        elseif type(theme) == "table" then
            Creator.CurrentTheme = theme
        end
        Creator.UpdateAllThemes()
    end
    
    function Creator.GetThemeProperty(property)
        local theme = Creator.GetCurrentTheme()
        return theme[property]
    end
    
    function Creator.OverrideTag(object, tags)
        Creator.ApplyThemeTag(object, tags)
    end
    
    -- ============================================
    -- SIGNAL MANAGEMENT
    -- ============================================
    
    function Creator.AddSignal(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(Creator.Signals, connection)
        return connection
    end
    
    function Creator.Disconnect()
        for _, connection in ipairs(Creator.Signals) do
            if connection and connection.Connected then
                connection:Disconnect()
            end
        end
        Creator.Signals = {}
    end
    
    -- ============================================
    -- SPRING MOTOR (Animation helper)
    -- ============================================
    
    function Creator.SpringMotor(initial, object, property, instant, skipTheme)
        local Flipper = _require("Packages.Flipper")
        local motor = Flipper.SingleMotor.new(initial)
        
        motor:onStep(function(value)
            if object and object.Parent then
                object[property] = value
            end
        end)
        
        local function setGoal(target, useInstant)
            if useInstant then
                motor:setGoal(Flipper.Instant.new(target))
            else
                motor:setGoal(Flipper.Spring.new(target, {
                    frequency = 6,
                    dampingRatio = 1
                }))
            end
        end
        
        return motor, setGoal
    end
    
    -- ============================================
    -- UTILITY FUNCTIONS
    -- ============================================
    
    function Creator.Tween(object, properties, duration, style, direction, callback)
        if not object or not object.Parent then return nil end
        
        local tween = TweenService:Create(
            object,
            TweenInfo.new(
                duration or 0.3,
                style or Enum.EasingStyle.Quart,
                direction or Enum.EasingDirection.Out
            ),
            properties
        )
        
        if callback then
            tween.Completed:Connect(callback)
        end
        
        tween:Play()
        return tween
    end
    
    function Creator.MakeDraggable(object, dragObject, enableTaptic)
        local dragging = false
        local relative = nil
        
        local offset = Vector2.zero
        local screenGui = object:FindFirstAncestorWhichIsA("ScreenGui")
        if screenGui and screenGui.IgnoreGuiInset then
            offset = offset + Services.GuiService:GetGuiInset()
        end
        
        dragObject.InputBegan:Connect(function(input, processed)
            if processed then return end
            
            local inputType = input.UserInputType.Name
            if inputType == "MouseButton1" or inputType == "Touch" then
                dragging = true
                relative = object.AbsolutePosition + object.AbsoluteSize * object.AnchorPoint - Services.UserInputService:GetMouseLocation()
            end
        end)
        
        Services.UserInputService.InputEnded:Connect(function(input)
            if not dragging then return end
            local inputType = input.UserInputType.Name
            if inputType == "MouseButton1" or inputType == "Touch" then
                dragging = false
            end
        end)
        
        Services.RunService.RenderStepped:Connect(function()
            if dragging then
                local position = Services.UserInputService:GetMouseLocation() + relative + offset
                Creator.Tween(object, {Position = UDim2.fromOffset(position.X, position.Y)}, 0.1, Enum.EasingStyle.Quad)
            end
        end)
    end
    
    return Creator
    
end

-- Module: Core/Customizer
_modules["Core/Customizer"] = function()
    --[[
        NexusUI Customization System
        customization for all aspects of the UI
    ]]
    
    local Customizer = {}
    Customizer.Presets = {}
    Customizer.CustomStyles = {}
    
    local Creator, Themes
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Themes = _require("Themes")
    end
    
    -- ============================================
    -- THEME CUSTOMIZATION
    -- ============================================
    
    -- Create a custom theme from scratch
    function Customizer.CreateTheme(name, colors)
        InitDependencies()
        
        -- Start with dark theme as base
        local newTheme = {}
        for key, value in pairs(Themes.Dark) do
            newTheme[key] = value
        end
        
        -- Override with custom colors
        for key, value in pairs(colors) do
            newTheme[key] = value
        end
        
        Themes[name] = newTheme
        table.insert(Themes.Names, name)
        
        return newTheme
    end
    
    function Customizer.ModifyTheme(themeName, modifications)
        InitDependencies()
        
        local theme = Themes[themeName]
        if not theme then return end
        
        for key, value in pairs(modifications) do
            theme[key] = value
        end
        
        Creator.UpdateAllThemes()
    end
    
    -- Create theme from single accent color
    function Customizer.CreateThemeFromAccent(name, accentColor, isDark)
        InitDependencies()
        
        local h, s, v = accentColor:ToHSV()
        
        local base = isDark ~= false and Themes.Dark or Themes.Light
        local newTheme = {}
        for key, value in pairs(base) do
            newTheme[key] = value
        end
        
        -- Generate colors from accent
        newTheme.Accent = accentColor
        newTheme.SliderProgress = accentColor
        newTheme.SliderStroke = Color3.fromHSV(h, s * 0.8, math.min(v * 1.2, 1))
        newTheme.ToggleEnabled = accentColor
        newTheme.ToggleEnabledStroke = Color3.fromHSV(h, s * 0.8, math.min(v * 1.2, 1))
        newTheme.TabBackgroundSelected = Color3.fromHSV(h, s * 0.3, isDark ~= false and 0.9 or 0.3)
        newTheme.InputIndicator = accentColor
        
        Themes[name] = newTheme
        table.insert(Themes.Names, name)
        
        return newTheme
    end
    
    -- ============================================
    -- ELEMENT STYLING
    -- ============================================
    
    -- Custom element styles
    Customizer.ElementStyles = {
        Default = {
            CornerRadius = 8,
            Padding = 12,
            ElementSpacing = 5,
            FontFamily = "rbxasset://fonts/families/GothamSSm.json",
            TitleSize = 14,
            DescriptionSize = 12,
            AnimationSpeed = 0.3
        },
        Rounded = {
            CornerRadius = 16,
            Padding = 16,
            ElementSpacing = 8
        },
        Sharp = {
            CornerRadius = 0,
            Padding = 10,
            ElementSpacing = 4
        },
        Compact = {
            CornerRadius = 4,
            Padding = 8,
            ElementSpacing = 3,
            TitleSize = 12,
            DescriptionSize = 10
        },
        Large = {
            CornerRadius = 12,
            Padding = 20,
            ElementSpacing = 10,
            TitleSize = 18,
            DescriptionSize = 14
        }
    }
    
    function Customizer.SetElementStyle(styleName)
        local style = Customizer.ElementStyles[styleName]
        if style then
            Customizer.CurrentStyle = style
            -- Merge with default
            for key, value in pairs(Customizer.ElementStyles.Default) do
                if Customizer.CurrentStyle[key] == nil then
                    Customizer.CurrentStyle[key] = value
                end
            end
        end
    end
    
    function Customizer.CreateElementStyle(name, style)
        -- Merge with default
        local newStyle = {}
        for key, value in pairs(Customizer.ElementStyles.Default) do
            newStyle[key] = value
        end
        for key, value in pairs(style) do
            newStyle[key] = value
        end
        Customizer.ElementStyles[name] = newStyle
    end
    
    function Customizer.GetStyle()
        return Customizer.CurrentStyle or Customizer.ElementStyles.Default
    end
    
    -- ============================================
    -- WINDOW CUSTOMIZATION
    -- ============================================
    
    Customizer.WindowStyles = {
        Default = {
            Width = 580,
            Height = 460,
            TabWidth = 150,
            TitleBarHeight = 42,
            CornerRadius = 8,
            Shadow = true,
            Acrylic = false,
            Draggable = true
        },
        Compact = {
            Width = 450,
            Height = 380,
            TabWidth = 120,
            TitleBarHeight = 36,
            CornerRadius = 6
        },
        Wide = {
            Width = 720,
            Height = 500,
            TabWidth = 180,
            TitleBarHeight = 48,
            CornerRadius = 10
        },
        Mobile = {
            Width = 340,
            Height = 500,
            TabWidth = 100,
            TitleBarHeight = 40,
            CornerRadius = 16
        },
        Fullscreen = {
            Width = 0, -- Will be calculated
            Height = 0,
            TabWidth = 200,
            TitleBarHeight = 50,
            CornerRadius = 0
        }
    }
    
    function Customizer.GetWindowStyle(styleName)
        return Customizer.WindowStyles[styleName] or Customizer.WindowStyles.Default
    end
    
    -- ============================================
    -- ANIMATION PRESETS
    -- ============================================
    
    Customizer.AnimationPresets = {
        Smooth = {
            EasingStyle = Enum.EasingStyle.Quart,
            EasingDirection = Enum.EasingDirection.Out,
            Duration = 0.3
        },
        Bouncy = {
            EasingStyle = Enum.EasingStyle.Back,
            EasingDirection = Enum.EasingDirection.Out,
            Duration = 0.4
        },
        Snappy = {
            EasingStyle = Enum.EasingStyle.Exponential,
            EasingDirection = Enum.EasingDirection.Out,
            Duration = 0.15
        },
        Elastic = {
            EasingStyle = Enum.EasingStyle.Elastic,
            EasingDirection = Enum.EasingDirection.Out,
            Duration = 0.5
        },
        Linear = {
            EasingStyle = Enum.EasingStyle.Linear,
            EasingDirection = Enum.EasingDirection.Out,
            Duration = 0.2
        }
    }
    
    function Customizer.SetAnimationPreset(presetName)
        Customizer.CurrentAnimation = Customizer.AnimationPresets[presetName]
    end
    
    function Customizer.GetAnimation()
        return Customizer.CurrentAnimation or Customizer.AnimationPresets.Smooth
    end
    
    -- ============================================
    -- FONT CUSTOMIZATION
    -- ============================================
    
    Customizer.Fonts = {
        Default = "rbxasset://fonts/families/GothamSSm.json",
        Modern = "rbxasset://fonts/families/SourceSansPro.json",
        Classic = "rbxasset://fonts/families/Arial.json",
        Elegant = "rbxasset://fonts/families/Nunito.json",
        Gaming = "rbxasset://fonts/families/Bangers.json",
        Mono = "rbxasset://fonts/families/RobotoMono.json"
    }
    
    Customizer.CurrentFont = Customizer.Fonts.Default
    
    function Customizer.SetFont(fontName)
        if Customizer.Fonts[fontName] then
            Customizer.CurrentFont = Customizer.Fonts[fontName]
        else
            Customizer.CurrentFont = fontName -- Custom font path
        end
    end
    
    -- ============================================
    -- ICON PACKS
    -- ============================================
    
    Customizer.IconPacks = {
        Lucide = {
            Home = "rbxassetid://10723407389",
            Settings = "rbxassetid://10734950309",
            User = "rbxassetid://10747384394",
            Bell = "rbxassetid://10734929283",
            Save = "rbxassetid://10747373176",
            Search = "rbxassetid://10734931426",
            Menu = "rbxassetid://10734931582",
            Close = "rbxassetid://9886659671",
            Minimize = "rbxassetid://9886659276",
            Maximize = "rbxassetid://9886659406",
            Check = "rbxassetid://10747379159",
            X = "rbxassetid://10747384687",
            Plus = "rbxassetid://10747377799",
            Minus = "rbxassetid://10747376353",
            Heart = "rbxassetid://10747380085",
            Star = "rbxassetid://10747382398",
            Play = "rbxassetid://10747377545",
            Pause = "rbxassetid://10747376832",
            Music = "rbxassetid://10747376099",
            Image = "rbxassetid://10747379814",
            Video = "rbxassetid://10747384133",
            Folder = "rbxassetid://10747378801",
            File = "rbxassetid://10747378517",
            Download = "rbxassetid://10747378080",
            Upload = "rbxassetid://10747383892",
            Refresh = "rbxassetid://10747377295",
            Lock = "rbxassetid://10747375633",
            Unlock = "rbxassetid://10747383637",
            Eye = "rbxassetid://10747378251",
            EyeOff = "rbxassetid://10747378382"
        }
    }
    
    Customizer.CurrentIconPack = "Lucide"
    
    function Customizer.GetIcon(iconName)
        local pack = Customizer.IconPacks[Customizer.CurrentIconPack]
        return pack and pack[iconName]
    end
    
    function Customizer.AddIconPack(name, icons)
        Customizer.IconPacks[name] = icons
    end
    
    -- ============================================
    -- PRESET THEMES (Gaming, Minimal, Neon, etc.)
    -- ============================================
    
    Customizer.Presets.Gaming = function()
        return Customizer.CreateTheme("Gaming", {
            TextColor = Color3.fromRGB(255, 255, 255),
            Background = Color3.fromRGB(10, 10, 15),
            Topbar = Color3.fromRGB(15, 15, 22),
            Accent = Color3.fromRGB(0, 255, 128),
            SliderProgress = Color3.fromRGB(0, 255, 128),
            ToggleEnabled = Color3.fromRGB(0, 255, 128),
            TabBackgroundSelected = Color3.fromRGB(0, 255, 128),
            ElementBorder = Color3.fromRGB(0, 255, 128)
        })
    end
    
    Customizer.Presets.Neon = function()
        return Customizer.CreateTheme("Neon", {
            Background = Color3.fromRGB(5, 5, 15),
            Accent = Color3.fromRGB(255, 0, 255),
            SliderProgress = Color3.fromRGB(255, 0, 255),
            ToggleEnabled = Color3.fromRGB(0, 255, 255),
            ElementBorder = Color3.fromRGB(100, 0, 255)
        })
    end
    
    Customizer.Presets.Minimal = function()
        Customizer.SetElementStyle("Compact")
        Customizer.SetAnimationPreset("Snappy")
    end
    
    Customizer.Presets.Luxury = function()
        return Customizer.CreateTheme("Luxury", {
            Background = Color3.fromRGB(20, 15, 10),
            Topbar = Color3.fromRGB(30, 25, 18),
            Accent = Color3.fromRGB(212, 175, 55),
            SliderProgress = Color3.fromRGB(212, 175, 55),
            ToggleEnabled = Color3.fromRGB(212, 175, 55),
            ElementBorder = Color3.fromRGB(100, 80, 40)
        })
    end
    
    return Customizer
    
end

-- Module: Core/Builder
_modules["Core/Builder"] = function()
    --[[
        NexusUI Simple Builder API
        Super easy, chainable API for creating UI
        
        Usage:
            local UI = NexusUI.Build()
                :Window({Title = "My App"})
                :Tab({Title = "Main", Icon = "Home"})
                :Button({Title = "Click Me", Callback = function() print("Hi") end})
                :Toggle({Title = "Enable", Default = true})
                :Slider({Title = "Speed", Min = 0, Max = 100})
                :Tab({Title = "Settings"})
                :Dropdown({Title = "Theme", Values = {"Dark", "Light"}})
                :Done()
    ]]
    
    local Builder = {}
    Builder.__index = Builder
    
    -- Create new builder instance
    function Builder.new(NexusUI)
        local self = setmetatable({}, Builder)
        
        self.NexusUI = NexusUI
        self.Window = nil
        self.CurrentTab = nil
        self.CurrentSection = nil
        self.Elements = {}
        
        return self
    end
    
    -- Create window
    function Builder:Window(options)
        self.Window = self.NexusUI:CreateWindow(options)
        return self
    end
    
    -- Add tab
    function Builder:Tab(options)
        if not self.Window then
            error("NexusUI Builder: Must create Window before Tab")
        end
        self.CurrentTab = self.Window:AddTab(options)
        self.CurrentSection = nil -- Reset section
        return self
    end
    
    -- Add section
    function Builder:Section(title)
        if not self.CurrentTab then
            error("NexusUI Builder: Must create Tab before Section")
        end
        self.CurrentSection = self.CurrentTab:AddSection(title)
        return self
    end
    
    -- Helper to get parent
    function Builder:GetParent()
        return self.CurrentSection or self.CurrentTab
    end
    
    -- Add button
    function Builder:Button(options)
        local parent = self:GetParent()
        if not parent then error("NexusUI Builder: Must create Tab first") end
        
        local element = parent:AddButton(options)
        if options.Flag then
            self.Elements[options.Flag] = element
        end
        return self
    end
    
    -- Add toggle
    function Builder:Toggle(options)
        local parent = self:GetParent()
        if not parent then error("NexusUI Builder: Must create Tab first") end
        
        local element = parent:AddToggle(options)
        if options.Flag then
            self.Elements[options.Flag] = element
            self.NexusUI:RegisterFlag(options.Flag, element)
        end
        return self
    end
    
    -- Add slider
    function Builder:Slider(options)
        local parent = self:GetParent()
        if not parent then error("NexusUI Builder: Must create Tab first") end
        
        local element = parent:AddSlider(options)
        if options.Flag then
            self.Elements[options.Flag] = element
            self.NexusUI:RegisterFlag(options.Flag, element)
        end
        return self
    end
    
    -- Add dropdown
    function Builder:Dropdown(options)
        local parent = self:GetParent()
        if not parent then error("NexusUI Builder: Must create Tab first") end
        
        local element = parent:AddDropdown(options)
        if options.Flag then
            self.Elements[options.Flag] = element
            self.NexusUI:RegisterFlag(options.Flag, element)
        end
        return self
    end
    
    -- Add input
    function Builder:Input(options)
        local parent = self:GetParent()
        if not parent then error("NexusUI Builder: Must create Tab first") end
        
        local element = parent:AddInput(options)
        if options.Flag then
            self.Elements[options.Flag] = element
            self.NexusUI:RegisterFlag(options.Flag, element)
        end
        return self
    end
    
    -- Add keybind
    function Builder:Keybind(options)
        local parent = self:GetParent()
        if not parent then error("NexusUI Builder: Must create Tab first") end
        
        local element = parent:AddKeybind(options)
        if options.Flag then
            self.Elements[options.Flag] = element
            self.NexusUI:RegisterFlag(options.Flag, element)
        end
        return self
    end
    
    -- Add color picker
    function Builder:ColorPicker(options)
        local parent = self:GetParent()
        if not parent then error("NexusUI Builder: Must create Tab first") end
        
        local element = parent:AddColorPicker(options)
        if options.Flag then
            self.Elements[options.Flag] = element
            self.NexusUI:RegisterFlag(options.Flag, element)
        end
        return self
    end
    
    -- Add paragraph
    function Builder:Paragraph(options)
        local parent = self:GetParent()
        if not parent then error("NexusUI Builder: Must create Tab first") end
        
        parent:AddParagraph(options)
        return self
    end
    
    -- Add image gallery
    function Builder:ImageGallery(options)
        local parent = self:GetParent()
        if not parent then error("NexusUI Builder: Must create Tab first") end
        
        local element = parent:AddImageGallery(options)
        if options.Flag then
            self.Elements[options.Flag] = element
        end
        return self
    end
    
    -- Add image button
    function Builder:ImageButton(options)
        local parent = self:GetParent()
        if not parent then error("NexusUI Builder: Must create Tab first") end
        
        local element = parent:AddImageButton(options)
        return self
    end
    
    -- Add frame animation (video)
    function Builder:FrameAnimation(options)
        local parent = self:GetParent()
        if not parent then error("NexusUI Builder: Must create Tab first") end
        
        local element = parent:AddFrameAnimation(options)
        if options.Flag then
            self.Elements[options.Flag] = element
        end
        return self
    end
    
    -- Add profile card
    function Builder:ProfileCard(options)
        local parent = self:GetParent()
        if not parent then error("NexusUI Builder: Must create Tab first") end
        
        local element = parent:AddProfileCard(options)
        return self
    end
    
    -- Add divider
    function Builder:Divider()
        local parent = self:GetParent()
        if not parent then error("NexusUI Builder: Must create Tab first") end
        
        parent:AddDivider()
        return self
    end
    
    -- Generic add method for any element
    function Builder:Add(elementType, options)
        local parent = self:GetParent()
        if not parent then error("NexusUI Builder: Must create Tab first") end
        
        local methodName = "Add" .. elementType
        if parent[methodName] then
            local element = parent[methodName](parent, options)
            if options and options.Flag then
                self.Elements[options.Flag] = element
            end
        end
        return self
    end
    
    -- Shorthand methods for all elements
    function Builder:Checkbox(options) return self:Add("Checkbox", options) end
    function Builder:Radio(options) return self:Add("RadioButton", options) end
    function Builder:Textbox(options) return self:Add("Textbox", options) end
    function Builder:SearchBox(options) return self:Add("SearchBox", options) end
    function Builder:Table(options) return self:Add("Table", options) end
    function Builder:StatCard(options) return self:Add("StatCard", options) end
    function Builder:Timer(options) return self:Add("Timer", options) end
    function Builder:Badge(options) return self:Add("Badge", options) end
    function Builder:Card(options) return self:Add("Card", options) end
    function Builder:Accordion(options) return self:Add("Accordion", options) end
    function Builder:Tabs(options) return self:Add("Tabs", options) end
    function Builder:List(options) return self:Add("List", options) end
    function Builder:Stepper(options) return self:Add("Stepper", options) end
    function Builder:RangeSlider(options) return self:Add("RangeSlider", options) end
    function Builder:Avatar(options) return self:Add("Avatar", options) end
    function Builder:Chip(options) return self:Add("Chip", options) end
    function Builder:Breadcrumb(options) return self:Add("Breadcrumb", options) end
    function Builder:Rating(options) return self:Add("Rating", options) end
    function Builder:Alert(options) return self:Add("Alert", options) end
    function Builder:CodeBlock(options) return self:Add("CodeBlock", options) end
    function Builder:Carousel(options) return self:Add("Carousel", options) end
    function Builder:MusicPlayer(options) return self:Add("MusicPlayer", options) end
    function Builder:Grid(options) return self:Add("Grid", options) end
    function Builder:Tooltip(options) return self:Add("Tooltip", options) end
    function Builder:ProgressBar(options) return self:Add("ProgressBar", options) end
    function Builder:RichText(options) return self:Add("RichText", options) end
    function Builder:VideoPlayer(options) return self:Add("VideoPlayer", options) end
    
    -- ============================================
    -- QUICK ACTIONS
    -- ============================================
    
    -- Quick theme selector
    function Builder:ThemeSelector(options)
        options = options or {}
        options.Title = options.Title or "Theme"
        options.Values = self.NexusUI:GetThemes()
        options.Default = options.Default or "Dark"
        options.Callback = function(themeName)
            self.NexusUI:SetTheme(themeName)
        end
        
        return self:Dropdown(options)
    end
    
    -- Quick config saver
    function Builder:ConfigSaver(configName)
        configName = configName or "default"
        
        return self:Section("Config")
            :Button({
                Title = "Save Config",
                Callback = function()
                    self.NexusUI:SaveConfig(configName)
                    self.Window:Notify({Title = "Saved", Content = "Config saved!", Duration = 2})
                end
            })
            :Button({
                Title = "Load Config",
                Callback = function()
                    local success = self.NexusUI:LoadConfig(configName)
                    self.Window:Notify({
                        Title = success and "Loaded" or "Error",
                        Content = success and "Config loaded!" or "No config found",
                        Duration = 2
                    })
                end
            })
    end
    
    -- ============================================
    -- FINISH / GET RESULTS
    -- ============================================
    
    -- Finish building and return window
    function Builder:Done()
        return self.Window, self.Elements
    end
    
    -- Get element by flag
    function Builder:Get(flag)
        return self.Elements[flag]
    end
    
    -- Get all elements
    function Builder:GetAll()
        return self.Elements
    end
    
    return Builder
    
end

-- Module: Utils/DeviceDetection
_modules["Utils/DeviceDetection"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                       GUI Framework                           ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
    ]]
    local DeviceDetection = {}
    
    local Services
    local function InitDependencies()
        local root = script.Parent.Parent
        Services = _require("Core/Services")
    end
    
    -- Device types
    DeviceDetection.DeviceTypes = {
        Mobile = "Mobile",
        Tablet = "Tablet",
        Desktop = "Desktop"
    }
    
    -- Detect device type
    function DeviceDetection.GetDeviceType()
        InitDependencies()
        
        local isMobile = Services.UserInputService.TouchEnabled
        local isKeyboard = Services.UserInputService.KeyboardEnabled
        local isMouse = Services.UserInputService.MouseEnabled
        
        if isMobile and not (isKeyboard and isMouse) then
            -- Check screen size for tablet vs phone
            local screenSize = Services.Camera.ViewportSize
            local aspectRatio = screenSize.X / screenSize.Y
            
            -- Tablets typically have aspect ratios closer to 4:3
            if math.min(screenSize.X, screenSize.Y) > 600 then
                return DeviceDetection.DeviceTypes.Tablet
            end
            return DeviceDetection.DeviceTypes.Mobile
        end
        
        return DeviceDetection.DeviceTypes.Desktop
    end
    
    -- Get responsive value based on device
    function DeviceDetection.GetValue(mobileValue, tabletValue, desktopValue)
        local deviceType = DeviceDetection.GetDeviceType()
        
        if deviceType == DeviceDetection.DeviceTypes.Mobile then
            return mobileValue
        elseif deviceType == DeviceDetection.DeviceTypes.Tablet then
            return tabletValue
        else
            return desktopValue
        end
    end
    
    -- Is mobile device
    function DeviceDetection.IsMobile()
        return DeviceDetection.GetDeviceType() == DeviceDetection.DeviceTypes.Mobile
    end
    
    -- Is tablet
    function DeviceDetection.IsTablet()
        return DeviceDetection.GetDeviceType() == DeviceDetection.DeviceTypes.Tablet
    end
    
    -- Is desktop
    function DeviceDetection.IsDesktop()
        return DeviceDetection.GetDeviceType() == DeviceDetection.DeviceTypes.Desktop
    end
    
    -- Is touch enabled
    function DeviceDetection.IsTouchEnabled()
        InitDependencies()
        return Services.UserInputService.TouchEnabled
    end
    
    -- Get safe area insets (for notched devices)
    function DeviceDetection.GetSafeAreaInsets()
        InitDependencies()
        local guiInset = Services.GuiService:GetGuiInset()
        return {
            Top = guiInset.Y,
            Bottom = 0,
            Left = 0,
            Right = 0
        }
    end
    
    return DeviceDetection
    
end

-- Module: Utils/ConfigManager
_modules["Utils/ConfigManager"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                       GUI Framework                           ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
    ]]
    local ConfigManager = {}
    
    local Services
    local function InitDependencies()
        local root = script.Parent.Parent
        Services = _require("Core/Services")
    end
    
    ConfigManager.Flags = {}
    ConfigManager.ConfigFolder = "NexusUI"
    
    -- Set config folder name
    function ConfigManager.SetFolder(folderName)
        ConfigManager.ConfigFolder = folderName
    end
    
    -- Check if file system access is available
    function ConfigManager.HasFileAccess()
        return (writefile and readfile and isfile and makefolder and isfolder) ~= nil
    end
    
    -- Create folder if doesn't exist
    function ConfigManager.EnsureFolder()
        if not ConfigManager.HasFileAccess() then return false end
        
        if not isfolder(ConfigManager.ConfigFolder) then
            makefolder(ConfigManager.ConfigFolder)
        end
        return true
    end
    
    -- Build config from flags
    function ConfigManager.BuildConfig()
        InitDependencies()
        
        local config = {}
        
        for flagName, flagData in pairs(ConfigManager.Flags) do
            if flagData.Element then
                if flagData.Element.GetValue then
                    config[flagName] = flagData.Element:GetValue()
                elseif flagData.Element.Value ~= nil then
                    config[flagName] = flagData.Element.Value
                end
            end
        end
        
        return config
    end
    
    -- Save config to file
    function ConfigManager.Save(configName)
        if not ConfigManager.HasFileAccess() then
            warn("NexusUI: File system access not available, cannot save config")
            return false
        end
        
        ConfigManager.EnsureFolder()
        
        local config = ConfigManager.BuildConfig()
        local json = Services.HttpService:JSONEncode(config)
        local path = ConfigManager.ConfigFolder .. "/" .. configName .. ".json"
        
        local success, err = pcall(function()
            writefile(path, json)
        end)
        
        if not success then
            warn("NexusUI: Failed to save config: " .. tostring(err))
        end
        
        return success
    end
    
    -- Load config from file
    function ConfigManager.Load(configName)
        InitDependencies()
        
        if not ConfigManager.HasFileAccess() then
            warn("NexusUI: File system access not available, cannot load config")
            return false
        end
        
        local path = ConfigManager.ConfigFolder .. "/" .. configName .. ".json"
        
        if not isfile(path) then
            return false
        end
        
        local success, result = pcall(function()
            local json = readfile(path)
            return Services.HttpService:JSONDecode(json)
        end)
        
        if not success then
            warn("NexusUI: Failed to load config: " .. tostring(result))
            return false
        end
        
        -- Apply config to flags
        for flagName, value in pairs(result) do
            local flagData = ConfigManager.Flags[flagName]
            if flagData and flagData.Element then
                if flagData.Element.Set then
                    flagData.Element:Set(value, true)
                end
            end
        end
        
        return true
    end
    
    -- Register a flag
    function ConfigManager.RegisterFlag(flagName, element)
        ConfigManager.Flags[flagName] = {
            Element = element
        }
    end
    
    -- Delete config
    function ConfigManager.Delete(configName)
        if not ConfigManager.HasFileAccess() then return false end
        
        local path = ConfigManager.ConfigFolder .. "/" .. configName .. ".json"
        
        if isfile(path) then
            delfile(path)
            return true
        end
        
        return false
    end
    
    -- List configs
    function ConfigManager.List()
        if not ConfigManager.HasFileAccess() then return {} end
        
        ConfigManager.EnsureFolder()
        
        local configs = {}
        if listfiles then
            for _, file in ipairs(listfiles(ConfigManager.ConfigFolder)) do
                if file:match("%.json$") then
                    local name = file:match("([^/\\]+)%.json$")
                    if name then
                        table.insert(configs, name)
                    end
                end
            end
        end
        
        return configs
    end
    
    return ConfigManager
    
end

-- Module: Utils/ConfigStore
_modules["Utils/ConfigStore"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                       GUI Framework                           ║
        ║                          By Ryu                               ║
        ║               CONFIG STORE v1.0 (.skid)                       ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        Custom config storage system for saving GUI settings
        File extension: .skid
        
        Usage:
            local ConfigStore = NexusUI.ConfigStore
            ConfigStore:CreateConfig("MyScript", {Theme = "Dark", Volume = 50})
            ConfigStore:Save()
            ConfigStore:Load()
            ConfigStore:Set("Volume", 75)
            local vol = ConfigStore:Get("Volume")
    ]]
    
    local ConfigStore = {}
    ConfigStore.__index = ConfigStore
    
    local HttpService = game:GetService("HttpService")
    
    -- Default folder for configs
    ConfigStore.DefaultFolder = "NexusUI_Configs"
    ConfigStore.Extension = ".skid"
    
    -- Active configs registry
    ConfigStore.Configs = {}
    ConfigStore.ActiveConfig = nil
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- CONFIG CLASS
    -- ════════════════════════════════════════════════════════════════════════════════
    
    local Config = {}
    Config.__index = Config
    
    function Config.new(name, defaults, folder)
        local self = setmetatable({}, Config)
        
        self.Name = name
        self.Folder = folder or ConfigStore.DefaultFolder
        self.FilePath = self.Folder .. "/" .. name .. ConfigStore.Extension
        self.Defaults = defaults or {}
        self.Data = {}
        self.AutoSave = true
        self.SaveDebounce = false
        self.LastSaved = 0
        self.Callbacks = {}  -- Change listeners
        
        -- Deep copy defaults
        for key, value in pairs(self.Defaults) do
            if type(value) == "table" then
                self.Data[key] = self:DeepCopy(value)
            else
                self.Data[key] = value
            end
        end
        
        return self
    end
    
    function Config:DeepCopy(original)
        local copy = {}
        for key, value in pairs(original) do
            if type(value) == "table" then
                copy[key] = self:DeepCopy(value)
            else
                copy[key] = value
            end
        end
        return copy
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- GETTERS & SETTERS
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function Config:Get(key, default)
        if self.Data[key] ~= nil then
            return self.Data[key]
        end
        return default or self.Defaults[key]
    end
    
    function Config:Set(key, value)
        local oldValue = self.Data[key]
        self.Data[key] = value
        
        -- Fire callbacks
        if self.Callbacks[key] then
            for _, callback in ipairs(self.Callbacks[key]) do
                task.spawn(callback, value, oldValue)
            end
        end
        
        -- Auto-save with debounce
        if self.AutoSave and not self.SaveDebounce then
            self.SaveDebounce = true
            task.delay(1, function()
                self.SaveDebounce = false
                self:Save()
            end)
        end
        
        return self
    end
    
    function Config:SetMultiple(data)
        for key, value in pairs(data) do
            self:Set(key, value)
        end
        return self
    end
    
    function Config:GetAll()
        return self.Data
    end
    
    function Config:Reset(key)
        if key then
            self.Data[key] = self.Defaults[key]
        else
            -- Reset all
            self.Data = {}
            for k, v in pairs(self.Defaults) do
                if type(v) == "table" then
                    self.Data[k] = self:DeepCopy(v)
                else
                    self.Data[k] = v
                end
            end
        end
        
        if self.AutoSave then
            self:Save()
        end
        
        return self
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- CHANGE LISTENERS
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function Config:OnChange(key, callback)
        if not self.Callbacks[key] then
            self.Callbacks[key] = {}
        end
        table.insert(self.Callbacks[key], callback)
        return self
    end
    
    function Config:OffChange(key, callback)
        if self.Callbacks[key] then
            for i, cb in ipairs(self.Callbacks[key]) do
                if cb == callback then
                    table.remove(self.Callbacks[key], i)
                    break
                end
            end
        end
        return self
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- FILE I/O
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function Config:Save()
        if not writefile then
            warn("[ConfigStore] writefile not available")
            return false
        end
        
        local success, err = pcall(function()
            -- Ensure folder exists
            if not isfolder(self.Folder) then
                makefolder(self.Folder)
            end
            
            -- Build .skid format
            local content = self:Serialize()
            writefile(self.FilePath, content)
            self.LastSaved = os.time()
        end)
        
        if not success then
            warn("[ConfigStore] Save failed:", err)
        end
        
        return success
    end
    
    function Config:Load()
        if not readfile or not isfile then
            warn("[ConfigStore] readfile not available")
            return false
        end
        
        if not isfile(self.FilePath) then
            -- No saved config, use defaults
            return false
        end
        
        local success, err = pcall(function()
            local content = readfile(self.FilePath)
            local data = self:Deserialize(content)
            
            -- Merge with defaults (keep new defaults if config doesn't have them)
            for key, value in pairs(self.Defaults) do
                if data[key] == nil then
                    data[key] = value
                end
            end
            
            self.Data = data
        end)
        
        if not success then
            warn("[ConfigStore] Load failed:", err)
            return false
        end
        
        return true
    end
    
    function Config:Delete()
        if delfile and isfile(self.FilePath) then
            delfile(self.FilePath)
            return true
        end
        return false
    end
    
    function Config:Exists()
        return isfile and isfile(self.FilePath) or false
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- SERIALIZATION 
    -- ════════════════════════════════════════════════════════════════════════════════
    
    --[[
        .skid format is a custom readable format:
        
        # NexusUI Config File
        # Created: 2026-01-31
        # Script: MyScript
        
        [Settings]
        Theme = "Dark"
        Volume = 50
        Enabled = true
        
        [Keybinds]
        Toggle = "RightControl"
        Kill = "K"
    ]]
    
    function Config:Serialize()
        local lines = {}
        
        -- Header
        table.insert(lines, "# ═══════════════════════════════════════")
        table.insert(lines, "# NexusUI Config File (.skid)")
        table.insert(lines, "# Script: " .. self.Name)
        table.insert(lines, string.format("# Created: %s", os.date("%Y-%m-%d %H:%M:%S")))
        table.insert(lines, "# ═══════════════════════════════════════")
        table.insert(lines, "")
        
        -- Separate nested tables and flat values
        local flatData = {}
        local nestedData = {}
        
        for key, value in pairs(self.Data) do
            if type(value) == "table" then
                nestedData[key] = value
            else
                flatData[key] = value
            end
        end
        
        -- Main section
        if next(flatData) then
            table.insert(lines, "[Main]")
            for key, value in pairs(flatData) do
                table.insert(lines, self:SerializeValue(key, value))
            end
            table.insert(lines, "")
        end
        
        -- Nested sections
        for sectionName, sectionData in pairs(nestedData) do
            table.insert(lines, "[" .. sectionName .. "]")
            for key, value in pairs(sectionData) do
                table.insert(lines, self:SerializeValue(key, value))
            end
            table.insert(lines, "")
        end
        
        return table.concat(lines, "\n")
    end
    
    function Config:SerializeValue(key, value)
        local valueType = type(value)
        
        if valueType == "string" then
            return string.format('%s = "%s"', key, value:gsub('"', '\\"'))
        elseif valueType == "number" then
            return string.format('%s = %s', key, tostring(value))
        elseif valueType == "boolean" then
            return string.format('%s = %s', key, tostring(value))
        elseif valueType == "table" then
            -- Inline array for simple tables
            local json = HttpService:JSONEncode(value)
            return string.format('%s = %s', key, json)
        else
            return string.format('%s = "%s"', key, tostring(value))
        end
    end
    
    function Config:Deserialize(content)
        local data = {}
        local currentSection = "Main"
        
        for line in content:gmatch("[^\n]+") do
            line = line:match("^%s*(.-)%s*$")  -- Trim
            
            -- Skip comments and empty lines
            if line == "" or line:sub(1, 1) == "#" then
                -- Skip
            elseif line:match("^%[(.+)%]$") then
                -- Section header
                currentSection = line:match("^%[(.+)%]$")
                if currentSection ~= "Main" then
                    data[currentSection] = data[currentSection] or {}
                end
            else
                -- Key = Value
                local key, value = line:match("^([%w_]+)%s*=%s*(.+)$")
                if key and value then
                    local parsedValue = self:ParseValue(value)
                    
                    if currentSection == "Main" then
                        data[key] = parsedValue
                    else
                        data[currentSection][key] = parsedValue
                    end
                end
            end
        end
        
        return data
    end
    
    function Config:ParseValue(valueStr)
        -- Remove quotes for strings
        if valueStr:match('^"(.-)"$') then
            return valueStr:match('^"(.-)"$'):gsub('\\"', '"')
        end
        
        -- Boolean
        if valueStr == "true" then return true end
        if valueStr == "false" then return false end
        
        -- Number
        local num = tonumber(valueStr)
        if num then return num end
        
        -- JSON array/object
        if valueStr:sub(1, 1) == "{" or valueStr:sub(1, 1) == "[" then
            local success, result = pcall(function()
                return HttpService:JSONDecode(valueStr)
            end)
            if success then return result end
        end
        
        -- Default to string
        return valueStr
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- CONFIG STORE MAIN METHODS
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function ConfigStore:CreateConfig(name, defaults, options)
        options = options or {}
        
        local config = Config.new(name, defaults, options.Folder)
        config.AutoSave = options.AutoSave ~= false
        
        -- Try to load existing
        config:Load()
        
        -- Register
        self.Configs[name] = config
        self.ActiveConfig = config
        
        return config
    end
    
    function ConfigStore:GetConfig(name)
        return self.Configs[name]
    end
    
    function ConfigStore:SetActiveConfig(name)
        local config = self.Configs[name]
        if config then
            self.ActiveConfig = config
        end
        return config
    end
    
    -- Shorthand methods using active config
    function ConfigStore:Get(key, default)
        if self.ActiveConfig then
            return self.ActiveConfig:Get(key, default)
        end
        return default
    end
    
    function ConfigStore:Set(key, value)
        if self.ActiveConfig then
            self.ActiveConfig:Set(key, value)
        end
        return self
    end
    
    function ConfigStore:Save()
        if self.ActiveConfig then
            return self.ActiveConfig:Save()
        end
        return false
    end
    
    function ConfigStore:Load()
        if self.ActiveConfig then
            return self.ActiveConfig:Load()
        end
        return false
    end
    
    function ConfigStore:Reset(key)
        if self.ActiveConfig then
            self.ActiveConfig:Reset(key)
        end
        return self
    end
    
    function ConfigStore:OnChange(key, callback)
        if self.ActiveConfig then
            self.ActiveConfig:OnChange(key, callback)
        end
        return self
    end
    
    -- List all saved configs
    function ConfigStore:ListSavedConfigs(folder)
        folder = folder or self.DefaultFolder
        local configs = {}
        
        if listfiles and isfolder(folder) then
            for _, file in ipairs(listfiles(folder)) do
                if file:match(self.Extension .. "$") then
                    local name = file:match("([^/\\]+)" .. self.Extension .. "$")
                    table.insert(configs, name)
                end
            end
        end
        
        return configs
    end
    
    -- Import config from JSON
    function ConfigStore:ImportFromJSON(name, jsonString)
        local success, data = pcall(function()
            return HttpService:JSONDecode(jsonString)
        end)
        
        if success and data then
            local config = self:CreateConfig(name, data)
            config:Save()
            return config
        end
        
        return nil
    end
    
    -- Export config to JSON
    function ConfigStore:ExportToJSON(name)
        local config = self.Configs[name]
        if config then
            return HttpService:JSONEncode(config.Data)
        end
        return nil
    end
    
    return ConfigStore
    
end

-- Module: Utils/AssetManager
_modules["Utils/AssetManager"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                       GUI Framework                           ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
    ]]
        
    local AssetManager = {}
    
    local Services
    local function InitDependencies()
        local root = script.Parent.Parent
        Services = _require("Core/Services")
    end
    
    AssetManager.AssetFolder = "NexusUI/Assets"
    AssetManager.Cache = {}
    AssetManager.Downloading = {}
    
    -- Check if file system access is available
    function AssetManager.HasFileAccess()
        return (writefile and readfile and isfile and makefolder and isfolder) ~= nil
    end
    
    -- Ensure asset folder exists
    function AssetManager.EnsureFolder()
        if not AssetManager.HasFileAccess() then return false end
        
        if not isfolder("NexusUI") then
            makefolder("NexusUI")
        end
        if not isfolder(AssetManager.AssetFolder) then
            makefolder(AssetManager.AssetFolder)
        end
        return true
    end
    
    -- Get cached asset path
    function AssetManager.GetCachedPath(assetName)
        return AssetManager.AssetFolder .. "/" .. assetName
    end
    
    -- Check if asset is cached
    function AssetManager.IsCached(assetName)
        if not AssetManager.HasFileAccess() then return false end
        return isfile(AssetManager.GetCachedPath(assetName))
    end
    
    -- Download asset
    function AssetManager.Download(url, assetName, callback)
        InitDependencies()
        
        if not AssetManager.HasFileAccess() then
            if callback then callback(false, "File system access not available") end
            return
        end
        
        -- Check if already cached
        if AssetManager.IsCached(assetName) then
            if callback then callback(true, AssetManager.GetCachedPath(assetName)) end
            return
        end
        
        -- Check if already downloading
        if AssetManager.Downloading[assetName] then
            -- Wait for download to complete
            task.spawn(function()
                repeat task.wait() until not AssetManager.Downloading[assetName]
                if callback then callback(AssetManager.IsCached(assetName), AssetManager.GetCachedPath(assetName)) end
            end)
            return
        end
        
        AssetManager.Downloading[assetName] = true
        AssetManager.EnsureFolder()
        
        task.spawn(function()
            local success, result = pcall(function()
                local response
                if game and game.HttpGet then
                    response = game:HttpGet(url)
                elseif request then
                    local req = request({Url = url, Method = "GET"})
                    response = req.Body
                elseif http_request then
                    local req = http_request({Url = url, Method = "GET"})
                    response = req.Body
                elseif syn and syn.request then
                    local req = syn.request({Url = url, Method = "GET"})
                    response = req.Body
                end
                
                if response then
                    writefile(AssetManager.GetCachedPath(assetName), response)
                end
                
                return response ~= nil
            end)
            
            AssetManager.Downloading[assetName] = nil
            
            if callback then
                callback(success and result, success and AssetManager.GetCachedPath(assetName) or tostring(result))
            end
        end)
    end
    
    -- Download multiple assets with progress
    function AssetManager.DownloadMultiple(assets, progressCallback, completeCallback)
        local total = #assets
        local completed = 0
        local results = {}
        
        for i, asset in ipairs(assets) do
            AssetManager.Download(asset.url, asset.name, function(success, path)
                completed = completed + 1
                results[asset.name] = {success = success, path = path}
                
                if progressCallback then
                    progressCallback(completed, total, asset.name, success)
                end
                
                if completed >= total and completeCallback then
                    completeCallback(results)
                end
            end)
        end
    end
    
    -- Load cached asset as content (for images)
    function AssetManager.LoadImage(assetName)
        if not AssetManager.IsCached(assetName) then
            return nil
        end
        
        local path = AssetManager.GetCachedPath(assetName)
        
        if getcustomasset then
            return getcustomasset(path)
        elseif getsynasset then
            return getsynasset(path)
        end
        
        return nil
    end
    
    -- Clear cache
    function AssetManager.ClearCache()
        if not AssetManager.HasFileAccess() then return end
        
        if isfolder(AssetManager.AssetFolder) then
            if listfiles and delfile then
                for _, file in ipairs(listfiles(AssetManager.AssetFolder)) do
                    pcall(function()
                        delfile(file)
                    end)
                end
            end
        end
        
        AssetManager.Cache = {}
    end
    
    -- Get cache size (approximate)
    function AssetManager.GetCacheSize()
        if not AssetManager.HasFileAccess() then return 0 end
        
        local size = 0
        if listfiles and isfile then
            for _, file in ipairs(listfiles(AssetManager.AssetFolder) or {}) do
                if isfile(file) then
                    local content = readfile(file)
                    if content then
                        size = size + #content
                    end
                end
            end
        end
        
        return size
    end
    
    return AssetManager
    
end

-- Module: Utils/SoundManager
_modules["Utils/SoundManager"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                       GUI Framework                           ║
        ║                          By Ryu                               ║
        ║             SOUND PLAYER v2.1 (Enhanced Presets)              ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        Advanced Sound Management System
        
        Features:
        - Global/Music/SFX volume controls
        - 25+ Sound effects with presets
        - Music playback with crossfade
        - Sound categories and pools
        - Positional audio support
        - Audio visualization data
        - Playlist management
        
        Usage:
            local Sound = NexusUI.Sound
            
            -- Quick play
            Sound:PlayPreset("Click")
            Sound:PlayMusic("rbxassetid://123456")
            
            -- All available presets
            Sound:PlayPreset("Notification")
            Sound:PlayPreset("Success")
            Sound:PlayPreset("Error")
    ]]
    
    local SoundPlayer = {}
    SoundPlayer.__index = SoundPlayer
    
    -- Services
    local SoundService = game:GetService("SoundService")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- STATE
    -- ════════════════════════════════════════════════════════════════════════════════
    
    SoundPlayer.Enabled = true
    SoundPlayer.GlobalVolume = 1.0       -- 0-1
    SoundPlayer.MusicVolume = 0.7        -- 0-1
    SoundPlayer.SFXVolume = 1.0          -- 0-1
    
    SoundPlayer.Sounds = {}              -- Active sound instances
    SoundPlayer.CurrentMusic = nil       -- Current music track
    SoundPlayer.NextMusic = nil          -- For crossfade
    SoundPlayer.Playlist = {}            -- Music playlist
    SoundPlayer.PlaylistIndex = 0
    SoundPlayer.ShuffleMode = false
    SoundPlayer.RepeatMode = "none"      -- none, one, all
    
    -- Sound container
    SoundPlayer.Container = nil
    SoundPlayer.Initialized = false
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- PRESETS (25+ sounds for all UI interactions)
    -- ════════════════════════════════════════════════════════════════════════════════
    
    SoundPlayer.Presets = {
        -- UI Sounds (Primary)
        Click       = {Id = 6895079853, Volume = 0.4, Pitch = 1.0},
        Hover       = {Id = 6895079709, Volume = 0.25, Pitch = 1.1},
        Toggle      = {Id = 6895079946, Volume = 0.35, Pitch = 1.0},
        Success     = {Id = 6895079946, Volume = 0.5, Pitch = 1.2},
        Error       = {Id = 6895080346, Volume = 0.5, Pitch = 0.9},
        Warning     = {Id = 6895080346, Volume = 0.4, Pitch = 1.0},
        
        -- Notifications (ALL ALIASES TO PREVENT NIL ERRORS)
        Notify      = {Id = 6895079569, Volume = 0.45, Pitch = 1.0},
        Notification = {Id = 6895079569, Volume = 0.45, Pitch = 1.0},
        Alert       = {Id = 6895079569, Volume = 0.5, Pitch = 0.95},
        Popup       = {Id = 4590657391, Volume = 0.4, Pitch = 1.0},
        Message     = {Id = 6895079569, Volume = 0.35, Pitch = 1.1},
        Info        = {Id = 6895079569, Volume = 0.4, Pitch = 1.05},
        
        -- Actions
        Open        = {Id = 6895079853, Volume = 0.3, Pitch = 1.1},
        Close       = {Id = 6895079853, Volume = 0.3, Pitch = 0.9},
        Confirm     = {Id = 6895079946, Volume = 0.5, Pitch = 1.1},
        Cancel      = {Id = 6895080346, Volume = 0.4, Pitch = 0.85},
        
        -- Typing
        Type        = {Id = 5765439036, Volume = 0.2, Pitch = 1.0},
        Backspace   = {Id = 5765439036, Volume = 0.15, Pitch = 0.85},
        Enter       = {Id = 6895079946, Volume = 0.3, Pitch = 1.0},
        
        -- Slider
        Slide       = {Id = 6895079709, Volume = 0.2, Pitch = 1.2},
        SlideEnd    = {Id = 6895079853, Volume = 0.25, Pitch = 1.0},
        
        -- Dropdown
        Expand      = {Id = 6895079853, Volume = 0.25, Pitch = 1.15},
        Collapse    = {Id = 6895079853, Volume = 0.25, Pitch = 0.95},
        Select      = {Id = 6895079946, Volume = 0.3, Pitch = 1.05},
        
        -- Tab Navigation
        TabSwitch   = {Id = 6895079709, Volume = 0.3, Pitch = 1.0},
        TabClick    = {Id = 6895079853, Volume = 0.25, Pitch = 1.05}
    }
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- INITIALIZATION
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function SoundPlayer:Init()
        if self.Initialized then return self end
        
        -- Create container for sounds
        pcall(function()
            self.Container = Instance.new("Folder")
            self.Container.Name = "NexusUI_Sounds"
            self.Container.Parent = SoundService
            
            -- Music subfolder
            self.MusicFolder = Instance.new("Folder")
            self.MusicFolder.Name = "Music"
            self.MusicFolder.Parent = self.Container
            
            -- SFX subfolder
            self.SFXFolder = Instance.new("Folder")
            self.SFXFolder.Name = "SFX"
            self.SFXFolder.Parent = self.Container
        end)
        
        self.Initialized = true
        return self
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- VOLUME CONTROLS
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function SoundPlayer:SetVolume(volume)
        -- Accept 0-100 or 0-1
        if volume > 1 then
            volume = volume / 100
        end
        self.GlobalVolume = math.clamp(volume, 0, 1)
        self:UpdateAllVolumes()
        return self
    end
    
    function SoundPlayer:SetMusicVolume(volume)
        if volume > 1 then
            volume = volume / 100
        end
        self.MusicVolume = math.clamp(volume, 0, 1)
        
        if self.CurrentMusic then
            local target = (self.CurrentMusic.BaseVolume or 0.5) * self.GlobalVolume * self.MusicVolume
            pcall(function()
                TweenService:Create(self.CurrentMusic, TweenInfo.new(0.2), {Volume = target}):Play()
            end)
        end
        
        return self
    end
    
    function SoundPlayer:SetSFXVolume(volume)
        if volume > 1 then
            volume = volume / 100
        end
        self.SFXVolume = math.clamp(volume, 0, 1)
        self:UpdateAllVolumes()
        return self
    end
    
    function SoundPlayer:GetVolume()
        return math.floor(self.GlobalVolume * 100)
    end
    
    function SoundPlayer:GetMusicVolume()
        return math.floor(self.MusicVolume * 100)
    end
    
    function SoundPlayer:GetSFXVolume()
        return math.floor(self.SFXVolume * 100)
    end
    
    function SoundPlayer:UpdateAllVolumes()
        for _, sound in pairs(self.Sounds) do
            if sound and sound.Parent and sound.BaseVolume then
                pcall(function()
                    sound.Volume = sound.BaseVolume * self.GlobalVolume * self.SFXVolume
                end)
            end
        end
    end
    
    function SoundPlayer:SetEnabled(enabled)
        self.Enabled = enabled
        
        if not enabled then
            self:StopAll()
        end
        
        return self
    end
    
    function SoundPlayer:IsEnabled()
        return self.Enabled
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- SOUND EFFECTS
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function SoundPlayer:Play(options)
        if not self.Enabled then return nil end
        self:Init()
        
        if type(options) == "string" or type(options) == "number" then
            options = {Id = options}
        end
        
        options = options or {}
        local Id = options.Id or options.SoundId
        if not Id then return nil end
        
        local Volume = options.Volume or 0.5
        local Pitch = options.Pitch or options.PlaybackSpeed or 1.0
        local Loop = options.Loop or options.Looped or false
        local Name = options.Name or tostring(Id)
        local Timeout = options.Timeout or 10
        
        -- Normalize ID
        if type(Id) == "number" then
            Id = "rbxassetid://" .. Id
        end
        
        local sound
        local success = pcall(function()
            -- Create sound
            sound = Instance.new("Sound")
            sound.Name = "SFX_" .. Name
            sound.SoundId = Id
            sound.Volume = 0  -- Start at 0, fade in
            sound.PlaybackSpeed = Pitch
            sound.Looped = Loop
            sound.RollOffMode = Enum.RollOffMode.Linear
            sound.Parent = self.SFXFolder or SoundService
            
            -- Store base volume
            sound.BaseVolume = Volume
            
            -- Calculate final volume
            local finalVolume = Volume * self.GlobalVolume * self.SFXVolume
            
            -- Play immediately
            sound.Volume = finalVolume
            sound:Play()
            
            -- Track
            self.Sounds[Name] = sound
            
            -- Cleanup for non-looped sounds
            if not Loop then
                local connection
                connection = sound.Ended:Connect(function()
                    if connection then connection:Disconnect() end
                    self.Sounds[Name] = nil
                    if sound and sound.Parent then
                        sound:Destroy()
                    end
                end)
                
                -- Timeout safety
                task.delay(Timeout, function()
                    if sound and sound.Parent then
                        self.Sounds[Name] = nil
                        sound:Destroy()
                    end
                end)
            end
        end)
        
        if not success then
            return nil
        end
        
        return sound
    end
    
    function SoundPlayer:PlayPreset(presetName, overrides)
        if not presetName then return nil end
        
        local preset = self.Presets[presetName]
        if not preset then
            -- Try case-insensitive search
            for name, p in pairs(self.Presets) do
                if name:lower() == presetName:lower() then
                    preset = p
                    break
                end
            end
        end
        
        if not preset then
            warn("[NexusUI SoundPlayer] Unknown preset: " .. tostring(presetName))
            return nil
        end
        
        local options = {}
        for k, v in pairs(preset) do
            options[k] = v
        end
        
        if overrides then
            for k, v in pairs(overrides) do
                options[k] = v
            end
        end
        
        options.Name = presetName
        return self:Play(options)
    end
    
    function SoundPlayer:Stop(name, fade)
        local sound = self.Sounds[name]
        if not sound then return end
        
        fade = fade or 0.1
        
        pcall(function()
            if fade > 0 then
                TweenService:Create(sound, TweenInfo.new(fade), {Volume = 0}):Play()
                task.delay(fade, function()
                    self.Sounds[name] = nil
                    if sound and sound.Parent then
                        sound:Destroy()
                    end
                end)
            else
                self.Sounds[name] = nil
                sound:Destroy()
            end
        end)
    end
    
    function SoundPlayer:StopAll()
        for name, sound in pairs(self.Sounds) do
            pcall(function()
                if sound and sound.Parent then
                    sound:Destroy()
                end
            end)
        end
        self.Sounds = {}
        
        self:StopMusic(0)
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- MUSIC PLAYBACK
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function SoundPlayer:PlayMusic(options, crossfade)
        if not self.Enabled then return nil end
        self:Init()
        
        crossfade = crossfade or 1.5
        
        if type(options) == "string" or type(options) == "number" then
            options = {Id = options}
        end
        
        options = options or {}
        local Id = options.Id or options.SoundId
        if not Id then return nil end
        
        local Volume = options.Volume or 0.5
        local Pitch = options.Pitch or options.PlaybackSpeed or 1.0
        local StartTime = options.StartTime or 0
        
        -- Normalize ID
        if type(Id) == "number" then
            Id = "rbxassetid://" .. Id
        end
        
        local music
        local success = pcall(function()
            -- Crossfade out current music
            if self.CurrentMusic then
                local oldMusic = self.CurrentMusic
                TweenService:Create(oldMusic, TweenInfo.new(crossfade), {Volume = 0}):Play()
                task.delay(crossfade, function()
                    if oldMusic and oldMusic.Parent then
                        oldMusic:Destroy()
                    end
                end)
            end
            
            -- Create new music
            music = Instance.new("Sound")
            music.Name = "Music"
            music.SoundId = Id
            music.Volume = 0
            music.PlaybackSpeed = Pitch
            music.Looped = options.Loop ~= false
            music.TimePosition = StartTime
            music.Parent = self.MusicFolder or SoundService
            
            music.BaseVolume = Volume
            
            -- Fade in
            local targetVolume = Volume * self.GlobalVolume * self.MusicVolume
            music:Play()
            TweenService:Create(music, TweenInfo.new(crossfade), {Volume = targetVolume}):Play()
            
            self.CurrentMusic = music
            
            -- Handle track end for playlists
            if not music.Looped then
                music.Ended:Connect(function()
                    self:OnMusicEnded()
                end)
            end
        end)
        
        if not success then
            return nil
        end
        
        return music
    end
    
    function SoundPlayer:StopMusic(fadeOut)
        fadeOut = fadeOut or 1.5
        
        if self.CurrentMusic then
            local music = self.CurrentMusic
            self.CurrentMusic = nil
            
            pcall(function()
                if fadeOut > 0 then
                    TweenService:Create(music, TweenInfo.new(fadeOut), {Volume = 0}):Play()
                    task.delay(fadeOut, function()
                        if music and music.Parent then
                            music:Destroy()
                        end
                    end)
                else
                    music:Destroy()
                end
            end)
        end
    end
    
    function SoundPlayer:PauseMusic()
        if self.CurrentMusic then
            pcall(function()
                self.CurrentMusic:Pause()
            end)
        end
    end
    
    function SoundPlayer:ResumeMusic()
        if self.CurrentMusic then
            pcall(function()
                self.CurrentMusic:Resume()
            end)
        end
    end
    
    function SoundPlayer:SetMusicPosition(time)
        if self.CurrentMusic then
            pcall(function()
                self.CurrentMusic.TimePosition = time
            end)
        end
    end
    
    function SoundPlayer:GetMusicPosition()
        if self.CurrentMusic then
            local pos = 0
            pcall(function()
                pos = self.CurrentMusic.TimePosition
            end)
            return pos
        end
        return 0
    end
    
    function SoundPlayer:GetMusicLength()
        if self.CurrentMusic then
            local len = 0
            pcall(function()
                len = self.CurrentMusic.TimeLength
            end)
            return len
        end
        return 0
    end
    
    function SoundPlayer:IsMusicPlaying()
        if self.CurrentMusic then
            local playing = false
            pcall(function()
                playing = self.CurrentMusic.IsPlaying
            end)
            return playing
        end
        return false
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- PLAYLIST
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function SoundPlayer:SetPlaylist(tracks)
        self.Playlist = tracks or {}
        self.PlaylistIndex = 0
        return self
    end
    
    function SoundPlayer:AddToPlaylist(track)
        table.insert(self.Playlist, track)
        return self
    end
    
    function SoundPlayer:ClearPlaylist()
        self.Playlist = {}
        self.PlaylistIndex = 0
        return self
    end
    
    function SoundPlayer:PlayNext()
        if #self.Playlist == 0 then return end
        
        if self.ShuffleMode then
            self.PlaylistIndex = math.random(1, #self.Playlist)
        else
            self.PlaylistIndex = self.PlaylistIndex + 1
            if self.PlaylistIndex > #self.Playlist then
                if self.RepeatMode == "all" then
                    self.PlaylistIndex = 1
                else
                    return
                end
            end
        end
        
        local track = self.Playlist[self.PlaylistIndex]
        self:PlayMusic(track)
    end
    
    function SoundPlayer:PlayPrevious()
        if #self.Playlist == 0 then return end
        
        self.PlaylistIndex = self.PlaylistIndex - 1
        if self.PlaylistIndex < 1 then
            self.PlaylistIndex = #self.Playlist
        end
        
        local track = self.Playlist[self.PlaylistIndex]
        self:PlayMusic(track)
    end
    
    function SoundPlayer:SetShuffle(enabled)
        self.ShuffleMode = enabled
        return self
    end
    
    function SoundPlayer:SetRepeat(mode)
        self.RepeatMode = mode  -- "none", "one", "all"
        return self
    end
    
    function SoundPlayer:OnMusicEnded()
        if self.RepeatMode == "one" and self.CurrentMusic then
            pcall(function()
                self.CurrentMusic.TimePosition = 0
                self.CurrentMusic:Play()
            end)
        elseif #self.Playlist > 0 then
            self:PlayNext()
        end
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- CUSTOM PRESETS
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function SoundPlayer:AddPreset(name, options)
        self.Presets[name] = options
        return self
    end
    
    function SoundPlayer:RemovePreset(name)
        self.Presets[name] = nil
        return self
    end
    
    function SoundPlayer:GetPresets()
        local names = {}
        for name in pairs(self.Presets) do
            table.insert(names, name)
        end
        return names
    end
    
    function SoundPlayer:HasPreset(name)
        return self.Presets[name] ~= nil
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- AUDIO ANALYSIS (Visualization data)
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function SoundPlayer:GetLoudness()
        if self.CurrentMusic then
            local loudness = 0
            pcall(function()
                loudness = self.CurrentMusic.PlaybackLoudness
            end)
            return loudness
        end
        return 0
    end
    
    function SoundPlayer:OnLoudnessChanged(callback, interval)
        interval = interval or 0.05
        
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if not self.CurrentMusic then return end
            
            local loudness = 0
            pcall(function()
                loudness = self.CurrentMusic.PlaybackLoudness
            end)
            local normalized = math.clamp(loudness / 500, 0, 1)
            callback(loudness, normalized)
        end)
        
        return connection
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- UTILITY
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function SoundPlayer:Preload(soundIds)
        local ContentProvider = game:GetService("ContentProvider")
        local assets = {}
        
        for _, id in ipairs(soundIds) do
            if type(id) == "number" then
                id = "rbxassetid://" .. id
            end
            
            local sound = Instance.new("Sound")
            sound.SoundId = id
            table.insert(assets, sound)
        end
        
        task.spawn(function()
            pcall(function()
                ContentProvider:PreloadAsync(assets)
            end)
            
            for _, sound in ipairs(assets) do
                sound:Destroy()
            end
        end)
    end
    
    function SoundPlayer:GetActiveCount()
        local count = 0
        for _ in pairs(self.Sounds) do
            count = count + 1
        end
        return count
    end
    
    -- Shorthand aliases
    SoundPlayer.SFX = SoundPlayer.PlayPreset
    SoundPlayer.Music = SoundPlayer.PlayMusic
    
    return SoundPlayer
    
end

-- Module: Utils/Animate
_modules["Utils/Animate"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                       GUI Framework                           ║
        ║                          By Ryu                               ║
        ║               ENHANCED ANIMATIONS v2.0                        ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        Advanced animation library with prebuilt effects
        
        Usage:
            local Animations = NexusUI.Animations
            Animations.FadeIn(element, 0.3)
            Animations.SlideIn(element, "Left", 0.3)
            Animations.Bounce(element)
            Animations.Pulse(element)
            Animations.Shake(element)
    ]]
    
    local Animations = {}
    
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- CORE TWEEN HELPER
    -- ════════════════════════════════════════════════════════════════════════════════
    
    local function Tween(object, properties, duration, easingStyle, easingDirection)
        easingStyle = easingStyle or Enum.EasingStyle.Quart
        easingDirection = easingDirection or Enum.EasingDirection.Out
        
        local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection)
        local tween = TweenService:Create(object, tweenInfo, properties)
        tween:Play()
        return tween
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- FADE ANIMATIONS
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function Animations.FadeIn(element, duration, callback)
        duration = duration or 0.3
        element.Visible = true
        
        local transparencyProp = element:IsA("ImageLabel") or element:IsA("ImageButton") 
            and "ImageTransparency" or "BackgroundTransparency"
        
        element[transparencyProp] = 1
        local tween = Tween(element, {[transparencyProp] = 0}, duration)
        
        -- Fade text if applicable
        if element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then
            element.TextTransparency = 1
            Tween(element, {TextTransparency = 0}, duration)
        end
        
        if callback then
            tween.Completed:Connect(callback)
        end
        
        return tween
    end
    
    function Animations.FadeOut(element, duration, destroy, callback)
        duration = duration or 0.3
        
        local transparencyProp = element:IsA("ImageLabel") or element:IsA("ImageButton") 
            and "ImageTransparency" or "BackgroundTransparency"
        
        local tween = Tween(element, {[transparencyProp] = 1}, duration)
        
        if element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then
            Tween(element, {TextTransparency = 1}, duration)
        end
        
        tween.Completed:Connect(function()
            element.Visible = false
            if destroy then element:Destroy() end
            if callback then callback() end
        end)
        
        return tween
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- SLIDE ANIMATIONS
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function Animations.SlideIn(element, direction, duration, callback)
        direction = direction or "Left"
        duration = duration or 0.35
        
        local originalPosition = element.Position
        local offset = UDim2.fromOffset(0, 0)
        
        if direction == "Left" then
            offset = UDim2.fromOffset(-element.AbsoluteSize.X - 50, 0)
        elseif direction == "Right" then
            offset = UDim2.fromOffset(element.AbsoluteSize.X + 50, 0)
        elseif direction == "Top" then
            offset = UDim2.fromOffset(0, -element.AbsoluteSize.Y - 50)
        elseif direction == "Bottom" then
            offset = UDim2.fromOffset(0, element.AbsoluteSize.Y + 50)
        end
        
        element.Position = originalPosition + offset
        element.Visible = true
        
        local tween = Tween(element, {Position = originalPosition}, duration, Enum.EasingStyle.Back)
        
        if callback then
            tween.Completed:Connect(callback)
        end
        
        return tween
    end
    
    function Animations.SlideOut(element, direction, duration, destroy, callback)
        direction = direction or "Left"
        duration = duration or 0.3
        
        local originalPosition = element.Position
        local targetPosition = element.Position
        
        if direction == "Left" then
            targetPosition = originalPosition + UDim2.fromOffset(-element.AbsoluteSize.X - 50, 0)
        elseif direction == "Right" then
            targetPosition = originalPosition + UDim2.fromOffset(element.AbsoluteSize.X + 50, 0)
        elseif direction == "Top" then
            targetPosition = originalPosition + UDim2.fromOffset(0, -element.AbsoluteSize.Y - 50)
        elseif direction == "Bottom" then
            targetPosition = originalPosition + UDim2.fromOffset(0, element.AbsoluteSize.Y + 50)
        end
        
        local tween = Tween(element, {Position = targetPosition}, duration, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        
        tween.Completed:Connect(function()
            element.Visible = false
            element.Position = originalPosition
            if destroy then element:Destroy() end
            if callback then callback() end
        end)
        
        return tween
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- SCALE ANIMATIONS
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function Animations.ScaleIn(element, duration, callback)
        duration = duration or 0.3
        
        local originalSize = element.Size
        element.Size = UDim2.fromOffset(0, 0)
        element.Visible = true
        
        local tween = Tween(element, {Size = originalSize}, duration, Enum.EasingStyle.Back)
        
        if callback then
            tween.Completed:Connect(callback)
        end
        
        return tween
    end
    
    function Animations.ScaleOut(element, duration, destroy, callback)
        duration = duration or 0.25
        
        local originalSize = element.Size
        local tween = Tween(element, {Size = UDim2.fromOffset(0, 0)}, duration, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        
        tween.Completed:Connect(function()
            element.Visible = false
            element.Size = originalSize
            if destroy then element:Destroy() end
            if callback then callback() end
        end)
        
        return tween
    end
    
    function Animations.PopIn(element, duration, callback)
        duration = duration or 0.35
        
        local originalSize = element.Size
        element.Size = UDim2.new(originalSize.X.Scale * 1.2, originalSize.X.Offset * 1.2, originalSize.Y.Scale * 1.2, originalSize.Y.Offset * 1.2)
        element.BackgroundTransparency = 1
        element.Visible = true
        
        Tween(element, {BackgroundTransparency = 0}, duration * 0.5)
        local tween = Tween(element, {Size = originalSize}, duration, Enum.EasingStyle.Elastic)
        
        if callback then
            tween.Completed:Connect(callback)
        end
        
        return tween
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- ATTENTION ANIMATIONS
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function Animations.Bounce(element, intensity, duration)
        intensity = intensity or 1.15
        duration = duration or 0.4
        
        local originalSize = element.Size
        local bigSize = UDim2.new(
            originalSize.X.Scale * intensity, originalSize.X.Offset * intensity,
            originalSize.Y.Scale * intensity, originalSize.Y.Offset * intensity
        )
        
        Tween(element, {Size = bigSize}, duration * 0.4, Enum.EasingStyle.Quad)
        task.delay(duration * 0.4, function()
            Tween(element, {Size = originalSize}, duration * 0.6, Enum.EasingStyle.Elastic)
        end)
    end
    
    function Animations.Shake(element, intensity, duration)
        intensity = intensity or 8
        duration = duration or 0.4
        
        local originalPosition = element.Position
        local shakeCount = 8
        local interval = duration / shakeCount
        
        for i = 1, shakeCount do
            task.delay(interval * (i - 1), function()
                local offset = (i % 2 == 0) and intensity or -intensity
                offset = offset * (1 - (i / shakeCount))  -- Decay
                Tween(element, {Position = originalPosition + UDim2.fromOffset(offset, 0)}, interval * 0.9)
            end)
        end
        
        task.delay(duration, function()
            Tween(element, {Position = originalPosition}, 0.1)
        end)
    end
    
    function Animations.Pulse(element, pulses, interval)
        pulses = pulses or 3
        interval = interval or 0.5
        
        for i = 1, pulses do
            task.delay(interval * (i - 1), function()
                Tween(element, {BackgroundTransparency = 0.5}, interval * 0.4)
                task.delay(interval * 0.4, function()
                    Tween(element, {BackgroundTransparency = 0}, interval * 0.5)
                end)
            end)
        end
    end
    
    function Animations.Glow(element, color, duration, pulses)
        color = color or Color3.fromRGB(0, 146, 214)
        duration = duration or 1.5
        pulses = pulses or 2
        
        local stroke = element:FindFirstChildOfClass("UIStroke")
        if not stroke then
            stroke = Instance.new("UIStroke")
            stroke.Thickness = 2
            stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            stroke.Parent = element
        end
        
        local originalColor = stroke.Color
        local originalTransparency = stroke.Transparency
        
        for i = 1, pulses do
            task.delay((duration / pulses) * (i - 1), function()
                stroke.Color = color
                Tween(stroke, {Transparency = 0}, duration / pulses / 2)
                task.delay(duration / pulses / 2, function()
                    Tween(stroke, {Transparency = 0.7}, duration / pulses / 2)
                end)
            end)
        end
        
        task.delay(duration, function()
            stroke.Color = originalColor
            stroke.Transparency = originalTransparency
        end)
    end
    
    function Animations.Wiggle(element, angle, duration)
        angle = angle or 5
        duration = duration or 0.5
        
        local wiggleCount = 6
        local interval = duration / wiggleCount
        
        for i = 1, wiggleCount do
            task.delay(interval * (i - 1), function()
                local rotation = (i % 2 == 0) and angle or -angle
                rotation = rotation * (1 - (i / wiggleCount))
                Tween(element, {Rotation = rotation}, interval * 0.9)
            end)
        end
        
        task.delay(duration, function()
            Tween(element, {Rotation = 0}, 0.1)
        end)
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- CONTINUOUS ANIMATIONS
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function Animations.Spin(element, speed, clockwise)
        speed = speed or 2  -- Seconds per rotation
        clockwise = clockwise ~= false
        
        local connection
        local currentRotation = element.Rotation
        
        connection = RunService.Heartbeat:Connect(function(dt)
            if not element or not element.Parent then
                connection:Disconnect()
                return
            end
            
            local rotationSpeed = (360 / speed) * dt
            currentRotation = currentRotation + (clockwise and rotationSpeed or -rotationSpeed)
            element.Rotation = currentRotation
        end)
        
        return connection
    end
    
    function Animations.Float(element, distance, speed)
        distance = distance or 5
        speed = speed or 2
        
        local connection
        local originalY = element.Position.Y.Offset
        local time = 0
        
        connection = RunService.Heartbeat:Connect(function(dt)
            if not element or not element.Parent then
                connection:Disconnect()
                return
            end
            
            time = time + dt
            local offset = math.sin(time * speed) * distance
            element.Position = UDim2.new(
                element.Position.X.Scale, element.Position.X.Offset,
                element.Position.Y.Scale, originalY + offset
            )
        end)
        
        return connection
    end
    
    function Animations.Rainbow(element, speed, property)
        speed = speed or 3
        property = property or "BackgroundColor3"
        
        local connection
        local time = 0
        
        connection = RunService.Heartbeat:Connect(function(dt)
            if not element or not element.Parent then
                connection:Disconnect()
                return
            end
            
            time = time + dt
            local hue = (time * speed) % 1
            element[property] = Color3.fromHSV(hue, 0.8, 1)
        end)
        
        return connection
    end
    
    function Animations.Breathe(element, minTransparency, maxTransparency, speed)
        minTransparency = minTransparency or 0
        maxTransparency = maxTransparency or 0.3
        speed = speed or 1.5
        
        local connection
        local time = 0
        
        connection = RunService.Heartbeat:Connect(function(dt)
            if not element or not element.Parent then
                connection:Disconnect()
                return
            end
            
            time = time + dt
            local alpha = (math.sin(time * speed * math.pi * 2) + 1) / 2
            element.BackgroundTransparency = minTransparency + (maxTransparency - minTransparency) * alpha
        end)
        
        return connection
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- TRANSITION ANIMATIONS
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function Animations.FlipH(element, duration, callback)
        duration = duration or 0.3
        
        local uiScale = element:FindFirstChildOfClass("UIScale")
        if not uiScale then
            uiScale = Instance.new("UIScale")
            uiScale.Parent = element
        end
        
        Tween(uiScale, {Scale = Vector2.new(0, 1)}, duration / 2)
        task.delay(duration / 2, function()
            if callback then callback() end
            Tween(uiScale, {Scale = Vector2.new(1, 1)}, duration / 2)
        end)
    end
    
    function Animations.FlipV(element, duration, callback)
        duration = duration or 0.3
        
        local uiScale = element:FindFirstChildOfClass("UIScale")
        if not uiScale then
            uiScale = Instance.new("UIScale")
            uiScale.Parent = element
        end
        
        Tween(uiScale, {Scale = Vector2.new(1, 0)}, duration / 2)
        task.delay(duration / 2, function()
            if callback then callback() end
            Tween(uiScale, {Scale = Vector2.new(1, 1)}, duration / 2)
        end)
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- UTILITY
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function Animations.StopAll(element)
        -- Cancel all tweens on element
        for _, child in ipairs(element:GetChildren()) do
            if child:IsA("Tween") then
                child:Cancel()
            end
        end
    end
    
    function Animations.Chain(animations)
        -- Execute animations in sequence
        local index = 1
        
        local function runNext()
            if index <= #animations then
                local anim = animations[index]
                index = index + 1
                
                local tween = anim.func(table.unpack(anim.args or {}))
                if tween and tween.Completed then
                    tween.Completed:Connect(runNext)
                else
                    task.delay(anim.duration or 0.3, runNext)
                end
            end
        end
        
        runNext()
    end
    
    return Animations
    
end

-- Module: Utils/Tooltip
_modules["Utils/Tooltip"] = function()
    --[[
        NexusUI Tooltip Utility
        Add tooltips to any element
    ]]
    
    local Tooltip = {}
    
    local Creator, Animate
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Animate = _require("Utils/Animate")
    end
    
    local activeTooltip = nil
    
    --[[
        Add a tooltip to any GUI element
        
        @param element - The GUI element to add tooltip to
        @param options - Tooltip configuration:
            - Text: Tooltip text (required)
            - Position: "Top", "Bottom", "Left", "Right" (default: "Top")
            - Delay: Show delay in seconds (default: 0.5)
            - MaxWidth: Maximum width (default: 200)
    ]]
    function Tooltip.Add(element, options)
        InitDependencies()
        
        if typeof(options) == "string" then
            options = {Text = options}
        end
        
        local Text = options.Text or ""
        local Position = options.Position or "Top"
        local Delay = options.Delay or 0.5
        local MaxWidth = options.MaxWidth or 200
        
        local hoverStart = 0
        local tooltipFrame = nil
        
        local function showTooltip()
            if activeTooltip then
                activeTooltip:Destroy()
            end
            
            -- Find screen gui
            local screenGui = element:FindFirstAncestorWhichIsA("ScreenGui")
            if not screenGui then return end
            
            -- Create tooltip
            tooltipFrame = Creator.New("Frame", {
                Size = UDim2.fromOffset(0, 0),
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundTransparency = 0.1,
                ZIndex = 100,
                Parent = screenGui,
                ThemeTag = {BackgroundColor3 = "Topbar"}
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)}),
                Creator.New("UIPadding", {
                    PaddingTop = UDim.new(0, 6),
                    PaddingBottom = UDim.new(0, 6),
                    PaddingLeft = UDim.new(0, 10),
                    PaddingRight = UDim.new(0, 10)
                }),
                Creator.New("UIStroke", {
                    Transparency = 0.7,
                    ThemeTag = {Color = "ElementBorder"}
                }),
                Creator.New("TextLabel", {
                    Size = UDim2.new(0, MaxWidth, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.XY,
                    Text = Text,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                    TextSize = 12,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    ThemeTag = {TextColor3 = "Text"}
                })
            })
            
            -- Position tooltip
            local absPos = element.AbsolutePosition
            local absSize = element.AbsoluteSize
            
            local x, y
            if Position == "Top" then
                x = absPos.X + absSize.X / 2
                y = absPos.Y - 10
                tooltipFrame.AnchorPoint = Vector2.new(0.5, 1)
            elseif Position == "Bottom" then
                x = absPos.X + absSize.X / 2
                y = absPos.Y + absSize.Y + 10
                tooltipFrame.AnchorPoint = Vector2.new(0.5, 0)
            elseif Position == "Left" then
                x = absPos.X - 10
                y = absPos.Y + absSize.Y / 2
                tooltipFrame.AnchorPoint = Vector2.new(1, 0.5)
            elseif Position == "Right" then
                x = absPos.X + absSize.X + 10
                y = absPos.Y + absSize.Y / 2
                tooltipFrame.AnchorPoint = Vector2.new(0, 0.5)
            end
            
            tooltipFrame.Position = UDim2.fromOffset(x, y)
            
            -- Animate in
            tooltipFrame.BackgroundTransparency = 1
            Animate.Tween(tooltipFrame, {BackgroundTransparency = 0.1}, 0.15, "Smooth")
            
            activeTooltip = tooltipFrame
        end
        
        local function hideTooltip()
            if tooltipFrame then
                Animate.Tween(tooltipFrame, {BackgroundTransparency = 1}, 0.1, "Smooth")
                task.delay(0.1, function()
                    if tooltipFrame then
                        tooltipFrame:Destroy()
                        tooltipFrame = nil
                    end
                end)
            end
            if activeTooltip == tooltipFrame then
                activeTooltip = nil
            end
        end
        
        -- Mouse events
        Creator.AddSignal(element.MouseEnter, function()
            hoverStart = tick()
            task.delay(Delay, function()
                if tick() - hoverStart >= Delay - 0.01 and element.Parent then
                    showTooltip()
                end
            end)
        end)
        
        Creator.AddSignal(element.MouseLeave, function()
            hoverStart = 0
            hideTooltip()
        end)
        
        return {
            SetText = function(newText)
                Text = newText
            end,
            Destroy = function()
                hideTooltip()
            end
        }
    end
    
    -- Hide all tooltips
    function Tooltip.HideAll()
        if activeTooltip then
            activeTooltip:Destroy()
            activeTooltip = nil
        end
    end
    
    return Tooltip
    
end

-- Module: Utils/Platform
_modules["Utils/Platform"] = function()
    --[[
        NexusUI Cross-Platform Utility
        Full compatibility: PC, Mobile, Console, VR
    ]]
    
    local Platform = {}
    
    local Services
    local function InitDependencies()
        local root = script.Parent.Parent
        Services = _require("Core/Services")
    end
    
    -- Platform types
    Platform.Types = {
        PC = "PC",
        Mobile = "Mobile",
        Tablet = "Tablet",
        Console = "Console",
        VR = "VR"
    }
    
    -- Detect current platform
    function Platform.Detect()
        InitDependencies()
        
        local UIS = Services.UserInputService
        local GS = Services.GuiService
        
        -- Check VR first
        if UIS.VREnabled then
            return Platform.Types.VR
        end
        
        -- Check console
        if GS:IsTenFootInterface() then
            return Platform.Types.Console
        end
        
        -- Check touch devices
        if UIS.TouchEnabled then
            local viewport = workspace.CurrentCamera.ViewportSize
            local minDim = math.min(viewport.X, viewport.Y)
            
            -- Tablets typically have larger screens
            if minDim > 600 then
                return Platform.Types.Tablet
            end
            return Platform.Types.Mobile
        end
        
        return Platform.Types.PC
    end
    
    -- Platform checks
    function Platform.IsPC() return Platform.Detect() == Platform.Types.PC end
    function Platform.IsMobile() return Platform.Detect() == Platform.Types.Mobile end
    function Platform.IsTablet() return Platform.Detect() == Platform.Types.Tablet end
    function Platform.IsConsole() return Platform.Detect() == Platform.Types.Console end
    function Platform.IsVR() return Platform.Detect() == Platform.Types.VR end
    function Platform.IsTouch() return Platform.IsMobile() or Platform.IsTablet() end
    function Platform.IsController() return Platform.IsConsole() end
    
    -- Get responsive value based on platform
    function Platform.Value(values)
        local platform = Platform.Detect()
        return values[platform] or values.Default or values.PC
    end
    
    -- Get appropriate UI scale
    function Platform.GetUIScale()
        local platform = Platform.Detect()
        if platform == Platform.Types.Mobile then return 0.9
        elseif platform == Platform.Types.Tablet then return 1.0
        elseif platform == Platform.Types.Console then return 1.2
        elseif platform == Platform.Types.VR then return 1.5
        else return 1.0 end
    end
    
    -- Get touch-friendly sizes
    function Platform.GetElementHeight()
        return Platform.Value({
            PC = 36,
            Mobile = 44,
            Tablet = 40,
            Console = 50,
            VR = 60,
            Default = 36
        })
    end
    
    function Platform.GetPadding()
        return Platform.Value({
            PC = 8,
            Mobile = 12,
            Tablet = 10,
            Console = 16,
            VR = 20,
            Default = 8
        })
    end
    
    function Platform.GetFontSize()
        return Platform.Value({
            PC = 14,
            Mobile = 16,
            Tablet = 15,
            Console = 18,
            VR = 22,
            Default = 14
        })
    end
    
    -- Get input type name for display
    function Platform.GetInputName(keyCode)
        local platform = Platform.Detect()
        
        if platform == Platform.Types.Console then
            -- Xbox/PlayStation button names
            local consoleNames = {
                [Enum.KeyCode.ButtonA] = "🅰",
                [Enum.KeyCode.ButtonB] = "🅱",
                [Enum.KeyCode.ButtonX] = "🅧",
                [Enum.KeyCode.ButtonY] = "🅨",
                [Enum.KeyCode.ButtonL1] = "LB",
                [Enum.KeyCode.ButtonR1] = "RB",
                [Enum.KeyCode.ButtonL2] = "LT",
                [Enum.KeyCode.ButtonR2] = "RT",
                [Enum.KeyCode.DPadUp] = "⬆",
                [Enum.KeyCode.DPadDown] = "⬇",
                [Enum.KeyCode.DPadLeft] = "⬅",
                [Enum.KeyCode.DPadRight] = "➡"
            }
            return consoleNames[keyCode] or keyCode.Name
        end
        
        return keyCode.Name
    end
    
    -- Adapt UI for platform
    function Platform.AdaptWindow(windowOptions)
        local platform = Platform.Detect()
        local adapted = {}
        for k, v in pairs(windowOptions) do adapted[k] = v end
        
        if platform == Platform.Types.Mobile then
            adapted.Size = adapted.Size or UDim2.fromScale(0.95, 0.9)
            adapted.Position = UDim2.fromScale(0.5, 0.5)
        elseif platform == Platform.Types.Console then
            adapted.Size = adapted.Size or UDim2.fromOffset(700, 550)
        elseif platform == Platform.Types.VR then
            adapted.Size = adapted.Size or UDim2.fromOffset(800, 600)
        end
        
        return adapted
    end
    
    -- Handle different input methods
    function Platform.OnInput(element, handlers)
        InitDependencies()
        
        local platform = Platform.Detect()
        local UIS = Services.UserInputService
        
        -- Mouse/Touch click
        if handlers.Click then
            element.Activated:Connect(handlers.Click)
        end
        
        -- Hover (PC only)
        if handlers.Hover and platform == Platform.Types.PC then
            element.MouseEnter:Connect(handlers.Hover)
        end
        
        -- Unhover
        if handlers.Unhover and platform == Platform.Types.PC then
            element.MouseLeave:Connect(handlers.Unhover)
        end
        
        -- Long press (Mobile/Tablet)
        if handlers.LongPress and Platform.IsTouch() then
            local pressing = false
            local pressStart = 0
            
            element.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    pressing = true
                    pressStart = tick()
                    
                    task.delay(0.5, function()
                        if pressing and tick() - pressStart >= 0.5 then
                            handlers.LongPress()
                        end
                    end)
                end
            end)
            
            element.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    pressing = false
                end
            end)
        end
        
        -- Gamepad select (Console)
        if handlers.GamepadSelect and platform == Platform.Types.Console then
            element.SelectionGained:Connect(handlers.GamepadSelect)
        end
    end
    
    return Platform
    
end

-- Module: Utils/ImageLoader
_modules["Utils/ImageLoader"] = function()
    --[[
        NexusUI Image Loader Utility
        Load images from RAW URLs (not just rbxassetid)
        Supports: Imgur, Discord CDN, GitHub, any direct image URL
    ]]
    
    local ImageLoader = {}
    ImageLoader.Cache = {}
    ImageLoader.LoadingImages = {}
    
    local Services
    local function InitDependencies()
        local root = script.Parent.Parent
        Services = _require("Core/Services")
    end
    
    -- Check if URL is a raw image link
    function ImageLoader.IsRawUrl(url)
        if type(url) ~= "string" then return false end
        return url:match("^https?://") ~= nil
    end
    
    -- Check if it's an rbxassetid
    function ImageLoader.IsAssetId(value)
        if type(value) == "number" then return true end
        if type(value) == "string" then
            return value:match("^rbxassetid://") ~= nil
        end
        return false
    end
    
    -- Convert any image source to usable format
    function ImageLoader.Resolve(source)
        if not source then return "" end
        
        -- Already an asset ID
        if type(source) == "number" then
            return "rbxassetid://" .. source
        end
        
        -- Already formatted asset
        if type(source) == "string" and source:match("^rbxassetid://") then
            return source
        end
        
        -- Raw URL - need to download and cache
        if ImageLoader.IsRawUrl(source) then
            return ImageLoader.LoadFromUrl(source)
        end
        
        return source
    end
    
    -- Load image from raw URL (requires file system access)
    function ImageLoader.LoadFromUrl(url, callback)
        InitDependencies()
        
        -- Check cache first
        if ImageLoader.Cache[url] then
            if callback then callback(true, ImageLoader.Cache[url]) end
            return ImageLoader.Cache[url]
        end
        
        -- Check if already loading
        if ImageLoader.LoadingImages[url] then
            -- Wait for it
            if callback then
                task.spawn(function()
                    while ImageLoader.LoadingImages[url] do
                        task.wait(0.1)
                    end
                    callback(ImageLoader.Cache[url] ~= nil, ImageLoader.Cache[url])
                end)
            end
            return nil
        end
        
        -- Check file system access
        if not (writefile and readfile and isfile and getcustomasset) then
            -- No file system, return URL directly (might work in some cases)
            if callback then callback(false, url) end
            return url
        end
        
        ImageLoader.LoadingImages[url] = true
        
        -- Generate filename from URL hash
        local filename = "NexusUI/ImageCache/" .. Services.HttpService:GenerateGUID(false) .. ".png"
        
        task.spawn(function()
            local success = pcall(function()
                -- Create folder
                if not isfolder("NexusUI") then makefolder("NexusUI") end
                if not isfolder("NexusUI/ImageCache") then makefolder("NexusUI/ImageCache") end
                
                -- Download image
                local response
                if game and game.HttpGet then
                    response = game:HttpGet(url)
                elseif request then
                    local req = request({Url = url, Method = "GET"})
                    response = req.Body
                elseif http_request then
                    local req = http_request({Url = url, Method = "GET"})
                    response = req.Body
                elseif syn and syn.request then
                    local req = syn.request({Url = url, Method = "GET"})
                    response = req.Body
                end
                
                if response then
                    writefile(filename, response)
                    
                    -- Get custom asset
                    local asset
                    if getcustomasset then
                        asset = getcustomasset(filename)
                    elseif getsynasset then
                        asset = getsynasset(filename)
                    end
                    
                    if asset then
                        ImageLoader.Cache[url] = asset
                    end
                end
            end)
            
            ImageLoader.LoadingImages[url] = nil
            
            if callback then
                callback(success and ImageLoader.Cache[url] ~= nil, ImageLoader.Cache[url] or url)
            end
        end)
        
        return nil -- Return nil while loading, use callback for async
    end
    
    -- Set image on ImageLabel/ImageButton with auto-detection
    function ImageLoader.SetImage(imageObject, source, placeholder)
        if not imageObject then return end
        
        -- Set placeholder first
        if placeholder then
            imageObject.Image = ImageLoader.Resolve(placeholder)
        end
        
        if ImageLoader.IsRawUrl(source) then
            -- Async load from URL
            ImageLoader.LoadFromUrl(source, function(success, asset)
                if success and asset and imageObject.Parent then
                    imageObject.Image = asset
                elseif not success then
                    -- Keep URL as fallback (won't display but no error)
                    imageObject.Image = placeholder or ""
                end
            end)
        else
            -- Direct asset
            imageObject.Image = ImageLoader.Resolve(source)
        end
    end
    
    -- Preload multiple images
    function ImageLoader.Preload(sources, onProgress, onComplete)
        local total = #sources
        local loaded = 0
        local results = {}
        
        for _, source in ipairs(sources) do
            if ImageLoader.IsRawUrl(source) then
                ImageLoader.LoadFromUrl(source, function(success, asset)
                    loaded = loaded + 1
                    results[source] = asset
                    
                    if onProgress then
                        onProgress(loaded, total, source, success)
                    end
                    
                    if loaded >= total and onComplete then
                        onComplete(results)
                    end
                end)
            else
                loaded = loaded + 1
                results[source] = ImageLoader.Resolve(source)
                
                if onProgress then
                    onProgress(loaded, total, source, true)
                end
                
                if loaded >= total and onComplete then
                    onComplete(results)
                end
            end
        end
    end
    
    -- Clear image cache
    function ImageLoader.ClearCache()
        ImageLoader.Cache = {}
        
        if isfolder and delfolder then
            pcall(function()
                if isfolder("NexusUI/ImageCache") then
                    delfolder("NexusUI/ImageCache")
                end
            end)
        end
    end
    
    return ImageLoader
    
end

-- Module: Utils/Icons
_modules["Utils/Icons"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                       GUI Framework                           ║
        ║                          By Ryu                               ║
        ║                     PREBUILT ICONS v1.0                       ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        Usage:
            local Icons = NexusUI.Icons
            Tab:AddButton({
                Title = "Join Discord",
                Icon = Icons.Discord
            })
            
            -- Or by name
            Tab:AddButton({
                Title = "Login",
                Icon = Icons.Get("Google")
            })
    ]]
    
    local Icons = {}
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- SOCIAL & BRAND ICONS (using free Roblox asset IDs)
    -- ════════════════════════════════════════════════════════════════════════════════
    
    -- Social Media
    Icons.Discord = "rbxassetid://7733717447"
    Icons.Twitter = "rbxassetid://7733715400"  
    Icons.YouTube = "rbxassetid://7733679686"
    Icons.Twitch = "rbxassetid://7733717096"
    Icons.TikTok = "rbxassetid://7733875813"
    Icons.Instagram = "rbxassetid://7733882200"
    Icons.Facebook = "rbxassetid://7733960981"
    Icons.Reddit = "rbxassetid://7733960548"
    Icons.LinkedIn = "rbxassetid://7733687252"
    Icons.GitHub = "rbxassetid://7733658504"
    
    -- Services & Apps
    Icons.Google = "rbxassetid://7734006531"
    Icons.Apple = "rbxassetid://7733993426"
    Icons.Microsoft = "rbxassetid://7734009897"
    Icons.Steam = "rbxassetid://7733717283"
    Icons.Spotify = "rbxassetid://7733717176"
    Icons.PayPal = "rbxassetid://7733690310"
    Icons.Amazon = "rbxassetid://7733993559"
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- UI ICONS (Common Actions)
    -- ════════════════════════════════════════════════════════════════════════════════
    
    -- Navigation
    Icons.Home = "rbxassetid://7733960981"
    Icons.Settings = "rbxassetid://7743879203"
    Icons.Menu = "rbxassetid://7733658504"
    Icons.Back = "rbxassetid://7734048966"
    Icons.Forward = "rbxassetid://7734048822"
    Icons.Up = "rbxassetid://7734047951"
    Icons.Down = "rbxassetid://7734047822"
    Icons.Left = "rbxassetid://7734047702"
    Icons.Right = "rbxassetid://7734047577"
    
    -- Actions
    Icons.Search = "rbxassetid://7734053495"
    Icons.Plus = "rbxassetid://7743878653"
    Icons.Minus = "rbxassetid://7743878440"
    Icons.Close = "rbxassetid://7743878326"
    Icons.Check = "rbxassetid://10709790644"
    Icons.Edit = "rbxassetid://7734053098"
    Icons.Delete = "rbxassetid://7734053230"
    Icons.Copy = "rbxassetid://7734034509"
    Icons.Paste = "rbxassetid://7734034397"
    Icons.Save = "rbxassetid://7734034285"
    Icons.Download = "rbxassetid://7734034165"
    Icons.Upload = "rbxassetid://7734034045"
    Icons.Refresh = "rbxassetid://7734033925"
    Icons.Lock = "rbxassetid://7734033805"
    Icons.Unlock = "rbxassetid://7734033685"
    Icons.Eye = "rbxassetid://7734033565"
    Icons.EyeOff = "rbxassetid://7734033445"
    
    -- Media
    Icons.Play = "rbxassetid://7734020045"
    Icons.Pause = "rbxassetid://7734019925"
    Icons.Stop = "rbxassetid://7734019805"
    Icons.Previous = "rbxassetid://7734019685"
    Icons.Next = "rbxassetid://7734019565"
    Icons.Volume = "rbxassetid://7734019445"
    Icons.VolumeMute = "rbxassetid://7734019325"
    Icons.Fullscreen = "rbxassetid://7734019205"
    
    -- Communication
    Icons.Chat = "rbxassetid://7734008998"
    Icons.Message = "rbxassetid://7734008878"
    Icons.Notification = "rbxassetid://7734008758"
    Icons.Bell = "rbxassetid://7734008638"
    Icons.Mail = "rbxassetid://7734008518"
    Icons.Phone = "rbxassetid://7734008398"
    
    -- User
    Icons.User = "rbxassetid://7733687140"
    Icons.Users = "rbxassetid://7733687028"
    Icons.Profile = "rbxassetid://7733686916"
    Icons.Crown = "rbxassetid://7733686804"
    Icons.Star = "rbxassetid://7733686692"
    Icons.Heart = "rbxassetid://7733686580"
    
    -- Status
    Icons.Success = "rbxassetid://7733960981"
    Icons.Warning = "rbxassetid://7743879203"
    Icons.Error = "rbxassetid://7743878326"
    Icons.Info = "rbxassetid://7733687252"
    Icons.Question = "rbxassetid://7733687364"
    Icons.Loading = "rbxassetid://7734020165"
    
    -- Gaming
    Icons.Controller = "rbxassetid://7733679798"
    Icons.Trophy = "rbxassetid://7733679910"
    Icons.Target = "rbxassetid://7733680022"
    Icons.Sword = "rbxassetid://7733680134"
    Icons.Shield = "rbxassetid://7733680246"
    Icons.Magic = "rbxassetid://7733680358"
    Icons.Coin = "rbxassetid://7733680470"
    Icons.Gem = "rbxassetid://7733680582"
    
    -- Files & Folders
    Icons.File = "rbxassetid://7733694600"
    Icons.Folder = "rbxassetid://7733694712"
    Icons.FolderOpen = "rbxassetid://7733694824"
    Icons.Document = "rbxassetid://7733694936"
    Icons.Image = "rbxassetid://7733695048"
    Icons.Video = "rbxassetid://7733695160"
    Icons.Audio = "rbxassetid://7733695272"
    Icons.Code = "rbxassetid://7733695384"
    
    -- Misc
    Icons.Link = "rbxassetid://7733700100"
    Icons.Unlink = "rbxassetid://7733700212"
    Icons.Clock = "rbxassetid://7733700324"
    Icons.Calendar = "rbxassetid://7733700436"
    Icons.Map = "rbxassetid://7733700548"
    Icons.Globe = "rbxassetid://7733700660"
    Icons.Sun = "rbxassetid://7733700772"
    Icons.Moon = "rbxassetid://7733700884"
    Icons.Key = "rbxassetid://7733700996"
    Icons.Gift = "rbxassetid://7733701108"
    Icons.Fire = "rbxassetid://7733701220"
    Icons.Bolt = "rbxassetid://7733701332"
    Icons.Sparkle = "rbxassetid://7733701444"
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- HELPER FUNCTIONS
    -- ════════════════════════════════════════════════════════════════════════════════
    
    -- Get icon by name (case-insensitive)
    function Icons.Get(name)
        local normalizedName = name:gsub("^%l", string.upper)
        return Icons[normalizedName] or Icons.Question
    end
    
    -- Get all icon names
    function Icons.GetNames()
        local names = {}
        for name, value in pairs(Icons) do
            if type(value) == "string" then
                table.insert(names, name)
            end
        end
        table.sort(names)
        return names
    end
    
    -- Check if icon exists
    function Icons.Has(name)
        local normalizedName = name:gsub("^%l", string.upper)
        return Icons[normalizedName] ~= nil
    end
    
    -- Category groups for easy access
    Icons.Categories = {
        Social = {"Discord", "Twitter", "YouTube", "Twitch", "TikTok", "Instagram", "Facebook", "Reddit", "LinkedIn", "GitHub"},
        Services = {"Google", "Apple", "Microsoft", "Steam", "Spotify", "PayPal", "Amazon"},
        Navigation = {"Home", "Settings", "Menu", "Back", "Forward", "Up", "Down", "Left", "Right"},
        Actions = {"Search", "Plus", "Minus", "Close", "Check", "Edit", "Delete", "Copy", "Paste", "Save", "Download", "Upload", "Refresh", "Lock", "Unlock", "Eye", "EyeOff"},
        Media = {"Play", "Pause", "Stop", "Previous", "Next", "Volume", "VolumeMute", "Fullscreen"},
        Communication = {"Chat", "Message", "Notification", "Bell", "Mail", "Phone"},
        User = {"User", "Users", "Profile", "Crown", "Star", "Heart"},
        Status = {"Success", "Warning", "Error", "Info", "Question", "Loading"},
        Gaming = {"Controller", "Trophy", "Target", "Sword", "Shield", "Magic", "Coin", "Gem"},
        Files = {"File", "Folder", "FolderOpen", "Document", "Image", "Video", "Audio", "Code"},
        Misc = {"Link", "Unlink", "Clock", "Calendar", "Map", "Globe", "Sun", "Moon", "Key", "Gift", "Fire", "Bolt", "Sparkle"}
    }
    
    -- Get icons by category
    function Icons.GetCategory(category)
        local categoryIcons = {}
        local categoryNames = Icons.Categories[category]
        if categoryNames then
            for _, name in ipairs(categoryNames) do
                categoryIcons[name] = Icons[name]
            end
        end
        return categoryIcons
    end
    
    return Icons
    
end

-- Module: Utils/HWID
_modules["Utils/HWID"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                       GUI Framework                           ║
        ║                          By Ryu                               ║
        ║                      HWID UTILS v1.0                          ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        Hardware ID and Security Utilities
        
        Features:
        • Real MAC address retrieval (multiple methods)
        • HWID generation from hardware fingerprints
        • Executor-specific HWID functions
        • Hashed ID generation for security
        • Machine fingerprinting
        
        Usage:
            local HWID = require(path.to.HWID)
            local hwid = HWID:Get()           -- Get best available HWID
            local mac = HWID:GetMAC()         -- Get MAC address
            local hash = HWID:GetHashed()     -- Get SHA256 hashed HWID
    ]]
    
    local HWID = {}
    
    local HttpService = game:GetService("HttpService")
    local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
    local Players = game:GetService("Players")
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- EXECUTOR DETECTION
    -- ════════════════════════════════════════════════════════════════════════════════
    
    local function getExecutorName()
        if syn then return "Synapse"
        elseif KRNL_LOADED then return "Krnl"
        elseif fluxus then return "Fluxus"
        elseif getexecutorname then return getexecutorname()
        elseif identifyexecutor then return identifyexecutor()
        else return "Unknown"
        end
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- HWID RETRIEVAL METHODS (Priority Order)
    -- ════════════════════════════════════════════════════════════════════════════════
    
    -- Method 1: Direct HWID functions (most reliable for specific executors)
    local function getDirectHWID()
        local methods = {
            gethwid,
            get_hwid,
            getHWID,
            HWID,
            hwid,
            identifyhwid,
            getdeviceid,
            get_device_id,
            getmachineid,
            getFingerprint
        }
        
        for _, method in ipairs(methods) do
            if type(method) == "function" then
                local success, result = pcall(method)
                if success and result and type(result) == "string" and #result > 0 then
                    return result
                end
            end
        end
        
        return nil
    end
    
    -- Method 2: Synapse X specific
    local function getSynapseHWID()
        if syn and syn.cache_replace then
            local success, result = pcall(function()
                return syn.request({
                    Url = "http://127.0.0.1:21587/gethwid",
                    Method = "GET"
                }).Body
            end)
            if success and result then
                return result
            end
        end
        
        if syn and syn.crypto_custom then
            local success, result = pcall(function()
                local hwid_raw = syn.crypto_custom("hwid", "get", {})
                return hwid_raw
            end)
            if success and result then
                return result
            end
        end
        
        return nil
    end
    
    -- Method 3: Krnl specific
    local function getKrnlHWID()
        if KRNL_LOADED and request then
            local success, result = pcall(function()
                return request({
                    Url = "http://localhost:19876/hwid",
                    Method = "GET"
                }).Body
            end)
            if success and result then
                return result
            end
        end
        
        return nil
    end
    
    -- Method 4: Script-Ware specific
    local function getScriptWareHWID()
        if ScriptWare then
            local success, result = pcall(function()
                if ScriptWare.HWID then
                    return ScriptWare.HWID
                elseif ScriptWare.GetHWID then
                    return ScriptWare.GetHWID()
                end
            end)
            if success and result then
                return result
            end
        end
        
        return nil
    end
    
    -- Method 5: MAC Address retrieval (multiple methods)
    local function getMACAddress()
        local macMethods = {
            getmacaddress,
            get_mac_address,
            getMACAddress,
            getMAC,
            get_mac,
            mac_address,
            getNetworkMAC,
            getnetworkaddress
        }
        
        for _, method in ipairs(macMethods) do
            if type(method) == "function" then
                local success, result = pcall(method)
                if success and result and type(result) == "string" and #result > 0 then
                    return result
                end
            end
        end
        
        -- Try through executor-specific methods
        if syn and syn.request then
            local success, result = pcall(function()
                return syn.request({
                    Url = "http://127.0.0.1:21587/getmac",
                    Method = "GET"
                }).Body
            end)
            if success and result and result ~= "" then
                return result
            end
        end
        
        return nil
    end
    
    -- Method 6: Generate fingerprint from Roblox data
    local function generateFingerprint()
        local components = {}
        
        -- Player ID
        local player = Players.LocalPlayer
        if player then
            table.insert(components, tostring(player.UserId))
            table.insert(components, player.Name)
        end
        
        -- Client ID from analytics
        pcall(function()
            local clientId = RbxAnalyticsService:GetClientId()
            if clientId then
                table.insert(components, clientId)
            end
        end)
        
        -- Session ID
        pcall(function()
            local sessionId = RbxAnalyticsService:GetSessionId()
            if sessionId then
                table.insert(components, sessionId)
            end
        end)
        
        -- Job ID
        if game.JobId and game.JobId ~= "" then
            table.insert(components, game.JobId)
        end
        
        -- Combine components
        if #components > 0 then
            return table.concat(components, "-")
        end
        
        return nil
    end
    
    -- Method 7: Hash-based pseudo HWID (fallback)
    local function generatePseudoHWID()
        local seed = {}
        
        -- Collect various identifiers
        local player = Players.LocalPlayer
        if player then
            table.insert(seed, player.UserId)
            table.insert(seed, player.Name)
            table.insert(seed, player.AccountAge)
        end
        
        -- Add timestamp variance
        table.insert(seed, math.floor(os.time() / 86400)) -- Daily component
        
        -- Generate hash-like string
        local combined = table.concat(seed, ":")
        local hash = 0
        for i = 1, #combined do
            hash = ((hash * 31) + string.byte(combined, i)) % 2147483647
        end
        
        return string.format("PSEUDO-%08X-%04X-%04X-%04X-%012X",
            hash % 0xFFFFFFFF,
            (hash / 0x10000) % 0xFFFF,
            (hash / 0x100) % 0xFFFF,
            hash % 0xFFFF,
            (hash * 11) % 0xFFFFFFFFFFFF
        )
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- PUBLIC API
    -- ════════════════════════════════════════════════════════════════════════════════
    
    -- Get the best available HWID using priority chain
    function HWID:Get()
        -- Try direct HWID first (fastest, most reliable)
        local hwid = getDirectHWID()
        if hwid then return hwid end
        
        -- Try Synapse-specific
        hwid = getSynapseHWID()
        if hwid then return hwid end
        
        -- Try Krnl-specific
        hwid = getKrnlHWID()
        if hwid then return hwid end
        
        -- Try Script-Ware specific
        hwid = getScriptWareHWID()
        if hwid then return hwid end
        
        -- Try MAC address (hardware based)
        local mac = getMACAddress()
        if mac then return "MAC-" .. mac end
        
        -- Try fingerprint
        local fingerprint = generateFingerprint()
        if fingerprint then return "FP-" .. fingerprint end
        
        -- Fallback to pseudo HWID
        return generatePseudoHWID()
    end
    
    -- Get MAC address specifically
    function HWID:GetMAC()
        return getMACAddress() or "UNKNOWN"
    end
    
    -- Get executor name
    function HWID:GetExecutor()
        return getExecutorName()
    end
    
    -- Check if real HWID is available
    function HWID:IsRealHWID()
        local hwid = getDirectHWID() or getSynapseHWID() or getKrnlHWID() or getScriptWareHWID()
        return hwid ~= nil
    end
    
    -- Check if MAC address is available
    function HWID:HasMAC()
        return getMACAddress() ~= nil
    end
    
    -- Get hashed version of HWID (for security)
    function HWID:GetHashed()
        local hwid = self:Get()
        
        -- Try to use executor's hash function
        if syn and syn.crypt and syn.crypt.hash then
            local success, hash = pcall(function()
                return syn.crypt.hash(hwid)
            end)
            if success then return hash end
        end
        
        -- Simple hash implementation
        local hash = 5381
        for i = 1, #hwid do
            hash = ((hash * 33) ~ string.byte(hwid, i)) % 2147483647
        end
        
        return string.format("%08X%08X%08X%08X",
            hash % 0xFFFFFFFF,
            (hash * 7) % 0xFFFFFFFF,
            (hash * 13) % 0xFFFFFFFF,
            (hash * 17) % 0xFFFFFFFF
        )
    end
    
    -- Get detailed info
    function HWID:GetInfo()
        return {
            HWID = self:Get(),
            MAC = self:GetMAC(),
            Executor = self:GetExecutor(),
            IsReal = self:IsRealHWID(),
            HasMAC = self:HasMAC(),
            Hashed = self:GetHashed()
        }
    end
    
    -- Verify HWID against a list (for key systems)
    function HWID:Verify(allowedList)
        local currentHWID = self:Get()
        local hashedHWID = self:GetHashed()
        
        for _, allowed in ipairs(allowedList) do
            if allowed == currentHWID or allowed == hashedHWID then
                return true
            end
        end
        
        return false
    end
    
    return HWID
    
end

-- Module: Utils/ControlBar
_modules["Utils/ControlBar"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║               CONTROL BAR STYLES v1.0                         ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        Window Control Bar Styles: Windows, macOS, Linux, Modern, etc.
    ]]
    
    local ControlBar = {}
    local TweenService = game:GetService("TweenService")
    
    local Styles = {
        Windows = {
            Layout = "right", ButtonSize = Vector2.new(46, 32), ButtonSpacing = 0,
            Buttons = {
                {Type = "minimize", Icon = "—", IconSize = 14, HoverColor = Color3.fromRGB(50, 50, 55), NormalColor = Color3.fromRGB(30, 30, 35), TextColor = Color3.fromRGB(200, 200, 200)},
                {Type = "maximize", Icon = "□", IconSize = 12, HoverColor = Color3.fromRGB(50, 50, 55), NormalColor = Color3.fromRGB(30, 30, 35), TextColor = Color3.fromRGB(200, 200, 200)},
                {Type = "close", Icon = "×", IconSize = 18, HoverColor = Color3.fromRGB(232, 17, 35), NormalColor = Color3.fromRGB(30, 30, 35), TextColor = Color3.fromRGB(200, 200, 200)}
            }
        },
        macOS = {
            Layout = "left", ButtonSize = Vector2.new(14, 14), ButtonSpacing = 8, Padding = 12,
            Buttons = {
                {Type = "close", Icon = "✕", IconSize = 8, NormalColor = Color3.fromRGB(255, 95, 87), HoverColor = Color3.fromRGB(255, 110, 102), Circular = true, ShowIconOnHover = true},
                {Type = "minimize", Icon = "−", IconSize = 10, NormalColor = Color3.fromRGB(255, 189, 46), HoverColor = Color3.fromRGB(255, 200, 80), Circular = true, ShowIconOnHover = true},
                {Type = "maximize", Icon = "⤢", IconSize = 8, NormalColor = Color3.fromRGB(40, 200, 64), HoverColor = Color3.fromRGB(60, 220, 84), Circular = true, ShowIconOnHover = true}
            }
        },
        Modern = {
            Layout = "right", ButtonSize = Vector2.new(32, 32), ButtonSpacing = 8, Padding = 10,
            Buttons = {
                {Type = "minimize", Icon = "−", IconSize = 16, NormalColor = Color3.fromRGB(50, 50, 55), HoverColor = Color3.fromRGB(70, 70, 75), TextColor = Color3.fromRGB(180, 180, 180), Rounded = true, CornerRadius = 8},
                {Type = "close", Icon = "×", IconSize = 18, NormalColor = Color3.fromRGB(50, 50, 55), HoverColor = Color3.fromRGB(220, 60, 60), TextColor = Color3.fromRGB(180, 180, 180), Rounded = true, CornerRadius = 8}
            }
        },
        Minimal = {
            Layout = "right", ButtonSize = Vector2.new(40, 28), ButtonSpacing = 0, Padding = 8,
            Buttons = {{Type = "close", Icon = "×", IconSize = 16, NormalColor = Color3.new(0,0,0), NormalTransparency = 1, HoverColor = Color3.fromRGB(220, 60, 60), HoverTransparency = 0.2, TextColor = Color3.fromRGB(150, 150, 150)}}
        }
    }
    
    function ControlBar:Apply(parent, styleName, callbacks)
        callbacks = callbacks or {}
        local style = Styles[styleName] or Styles.Modern
        
        local container = Instance.new("Frame")
        container.Name = "ControlBar"
        container.BackgroundTransparency = 1
        container.Parent = parent
        
        local totalWidth = (style.Padding or 0) * 2
        for i, b in ipairs(style.Buttons) do totalWidth = totalWidth + style.ButtonSize.X + (i < #style.Buttons and style.ButtonSpacing or 0) end
        
        container.Size = UDim2.new(0, totalWidth, 0, style.ButtonSize.Y + 8)
        container.Position = style.Layout == "left" and UDim2.fromOffset(0, 4) or UDim2.new(1, 0, 0, 4)
        container.AnchorPoint = style.Layout == "left" and Vector2.new(0, 0) or Vector2.new(1, 0)
        
        local xOffset = style.Padding or 0
        for _, btn in ipairs(style.Buttons) do
            local button = Instance.new("TextButton")
            button.Size = UDim2.fromOffset(style.ButtonSize.X, style.ButtonSize.Y)
            button.Position = UDim2.new(0, xOffset, 0.5, 0)
            button.AnchorPoint = Vector2.new(0, 0.5)
            button.BackgroundColor3 = btn.NormalColor
            button.BackgroundTransparency = btn.NormalTransparency or 0
            button.Text = btn.ShowIconOnHover and "" or (btn.Icon or "")
            button.TextColor3 = btn.TextColor or Color3.new(1,1,1)
            button.TextSize = btn.IconSize or 14
            button.Font = Enum.Font.GothamBold
            button.AutoButtonColor = false
            button.Parent = container
            
            if btn.Circular then Instance.new("UICorner", button).CornerRadius = UDim.new(1, 0)
            elseif btn.Rounded then Instance.new("UICorner", button).CornerRadius = UDim.new(0, btn.CornerRadius or 6) end
            
            button.MouseEnter:Connect(function()
                TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = btn.HoverColor, BackgroundTransparency = btn.HoverTransparency or 0}):Play()
                if btn.ShowIconOnHover then button.Text = btn.Icon end
            end)
            button.MouseLeave:Connect(function()
                TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = btn.NormalColor, BackgroundTransparency = btn.NormalTransparency or 0}):Play()
                if btn.ShowIconOnHover then button.Text = "" end
            end)
            button.MouseButton1Click:Connect(function()
                if btn.Type == "close" and callbacks.OnClose then callbacks.OnClose()
                elseif btn.Type == "minimize" and callbacks.OnMinimize then callbacks.OnMinimize()
                elseif btn.Type == "maximize" and callbacks.OnMaximize then callbacks.OnMaximize() end
            end)
            
            xOffset = xOffset + style.ButtonSize.X + style.ButtonSpacing
        end
        return container
    end
    
    function ControlBar:GetStyles() local n = {} for k in pairs(Styles) do table.insert(n, k) end return n end
    function ControlBar:AddStyle(name, def) Styles[name] = def end
    
    return ControlBar
    
end

-- Module: Utils/AssetLoader
_modules["Utils/AssetLoader"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                   ASSET LOADER v1.0                           ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        External Asset Loading from URLs (GitHub, etc.)
        
        Supported:
        • Images: PNG, WebP, JPG, GIF
        • Sounds: MP3, M4A, OGG, WAV
        • Data: JSON, TXT
        
        Usage:
            local Assets = require(path.to.AssetLoader)
            local imageUrl = Assets:LoadImage("https://raw.githubusercontent.com/user/repo/main/image.png")
            Assets:LoadSound("https://example.com/sound.mp3", function(soundId) end)
    ]]
    
    local AssetLoader = {}
    
    local HttpService = game:GetService("HttpService")
    local ContentProvider = game:GetService("ContentProvider")
    
    AssetLoader.Cache = {}
    AssetLoader.BaseURL = "https://raw.githubusercontent.com/"
    
    -- Get request function
    local function getRequestFunc()
        return syn and syn.request or http_request or request or http and http.request
    end
    
    -- Load image from URL (returns asset ID or URL)
    function AssetLoader:LoadImage(url, callback)
        if not url then return nil end
        
        -- Check cache
        if self.Cache[url] then
            if callback then callback(self.Cache[url]) end
            return self.Cache[url]
        end
        
        -- For GitHub raw URLs, can use directly in some cases
        if url:match("raw.githubusercontent.com") or url:match("github.com/.-/raw/") then
            local finalUrl = url
            self.Cache[url] = finalUrl
            if callback then callback(finalUrl) end
            return finalUrl
        end
        
        -- Try to fetch and create asset
        local requestFunc = getRequestFunc()
        if requestFunc then
            task.spawn(function()
                local success, response = pcall(function()
                    return requestFunc({Url = url, Method = "GET"})
                end)
                
                if success and response and response.Body then
                    -- Store URL for use
                    self.Cache[url] = url
                    if callback then callback(url) end
                else
                    if callback then callback(nil) end
                end
            end)
        else
            -- Fallback: return URL directly
            self.Cache[url] = url
            if callback then callback(url) end
            return url
        end
        
        return url
    end
    
    -- Load sound from URL
    function AssetLoader:LoadSound(url, callback)
        if not url then return nil end
        
        if self.Cache[url] then
            if callback then callback(self.Cache[url]) end
            return self.Cache[url]
        end
        
        -- External sounds need special handling
        local requestFunc = getRequestFunc()
        if requestFunc then
            task.spawn(function()
                local success, response = pcall(function()
                    return requestFunc({Url = url, Method = "GET"})
                end)
                
                if success and response then
                    self.Cache[url] = url
                    if callback then callback(url) end
                else
                    if callback then callback(nil) end
                end
            end)
        else
            self.Cache[url] = url  
            if callback then callback(url) end
        end
        
        return url
    end
    
    -- Load JSON data from URL
    function AssetLoader:LoadJSON(url, callback)
        local requestFunc = getRequestFunc()
        if not requestFunc then
            if callback then callback(nil) end
            return nil
        end
        
        task.spawn(function()
            local success, response = pcall(function()
                return requestFunc({Url = url, Method = "GET"})
            end)
            
            if success and response and response.Body then
                local data = nil
                pcall(function() data = HttpService:JSONDecode(response.Body) end)
                self.Cache[url] = data
                if callback then callback(data) end
            else
                if callback then callback(nil) end
            end
        end)
    end
    
    -- Load text from URL
    function AssetLoader:LoadText(url, callback)
        local requestFunc = getRequestFunc()
        if not requestFunc then
            if callback then callback(nil) end
            return nil
        end
        
        task.spawn(function()
            local success, response = pcall(function()
                return requestFunc({Url = url, Method = "GET"})
            end)
            
            if success and response and response.Body then
                self.Cache[url] = response.Body
                if callback then callback(response.Body) end
            else
                if callback then callback(nil) end
            end
        end)
    end
    
    -- Preload multiple assets
    function AssetLoader:PreloadAssets(urls, onComplete)
        local loaded = 0
        local total = #urls
        
        for _, url in ipairs(urls) do
            self:LoadImage(url, function()
                loaded = loaded + 1
                if loaded >= total and onComplete then
                    onComplete()
                end
            end)
        end
    end
    
    -- Build GitHub raw URL
    function AssetLoader:GitHubRaw(user, repo, branch, path)
        return string.format("https://raw.githubusercontent.com/%s/%s/%s/%s", user, repo, branch or "main", path)
    end
    
    -- Clear cache
    function AssetLoader:ClearCache()
        self.Cache = {}
    end
    
    return AssetLoader
    
end

-- Module: Components/Dialog
_modules["Components/Dialog"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                       GUI Framework                           ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
    ]]
    local Dialog = {}
    Dialog.__index = Dialog
    
    local Creator
    local Flipper
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Flipper = _require("Packages/Flipper")
    end
    
    function Dialog.new(window, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Dialog"
        local Content = options.Content or ""
        local Buttons = options.Buttons or {}
        
        local self = setmetatable({
            ButtonCount = 0
        }, Dialog)
        
        -- Tint overlay
        self.TintFrame = Creator.New("TextButton", {
            Text = "",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            Parent = window.Root
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)})
        })
        
        -- Animation motors
        self.TintMotor, self.SetTint = Creator.SpringMotor(1, self.TintFrame, "BackgroundTransparency")
        
        -- Button holder
        self.ButtonHolder = Creator.New("Frame", {
            Size = UDim2.new(1, -40, 1, -40),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            BackgroundTransparency = 1
        }, {
            Creator.New("UIListLayout", {
                Padding = UDim.new(0, 10),
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder
            })
        })
        
        -- Button holder frame
        self.ButtonHolderFrame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, 70),
            Position = UDim2.new(0, 0, 1, -70),
            ThemeTag = {BackgroundColor3 = "DialogHolder"}
        }, {
            Creator.New("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                ThemeTag = {BackgroundColor3 = "DialogHolderLine"}
            }),
            self.ButtonHolder
        })
        
        -- Title
        self.TitleLabel = Creator.New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
            Text = Title,
            TextSize = 20,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 22),
            Position = UDim2.fromOffset(20, 20),
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Content
        self.ContentLabel = Creator.New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            Text = Content,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Size = UDim2.new(1, -40, 0, 60),
            Position = UDim2.fromOffset(20, 50),
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "SubText"}
        })
        
        -- Scale for animation
        self.Scale = Creator.New("UIScale", {Scale = 1.1})
        self.ScaleMotor, self.SetScale = Creator.SpringMotor(1.1, self.Scale, "Scale")
        
        -- Root dialog
        self.Root = Creator.New("CanvasGroup", {
            Size = UDim2.fromOffset(320, 180),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            GroupTransparency = 1,
            Parent = self.TintFrame,
            ThemeTag = {BackgroundColor3 = "Dialog"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {
                Transparency = 0.5,
                ThemeTag = {Color = "DialogBorder"}
            }),
            self.Scale,
            self.TitleLabel,
            self.ContentLabel,
            self.ButtonHolderFrame
        })
        
        self.RootMotor, self.SetRootTransparency = Creator.SpringMotor(1, self.Root, "GroupTransparency")
        
        -- Add buttons
        for _, buttonConfig in ipairs(Buttons) do
            self:AddButton(buttonConfig.Title, buttonConfig.Callback)
        end
        
        -- Open dialog
        self:Open()
        
        return self
    end
    
    function Dialog:AddButton(title, callback)
        self.ButtonCount = self.ButtonCount + 1
        callback = callback or function() end
        
        local button = Creator.New("TextButton", {
            Size = UDim2.new(0, 100, 0, 32),
            Text = "",
            Parent = self.ButtonHolder,
            ThemeTag = {BackgroundColor3 = "DialogButton"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 4)}),
            Creator.New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Transparency = 0.65,
                ThemeTag = {Color = "DialogButtonBorder"}
            }),
            Creator.New("TextLabel", {
                Text = title or "Button",
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                TextSize = 14,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "Text"}
            })
        })
        
        -- Resize buttons to fit
        for _, child in ipairs(self.ButtonHolder:GetChildren()) do
            if child:IsA("TextButton") then
                child.Size = UDim2.new(1 / self.ButtonCount, -(((self.ButtonCount - 1) * 10) / self.ButtonCount), 0, 32)
            end
        end
        
        -- Hover effect
        local motor, setTransparency = Creator.SpringMotor(1, button, "BackgroundTransparency", true)
        
        Creator.AddSignal(button.MouseEnter, function()
            setTransparency(0.97)
        end)
        
        Creator.AddSignal(button.MouseLeave, function()
            setTransparency(1)
        end)
        
        Creator.AddSignal(button.MouseButton1Click, function()
            callback()
            self:Close()
        end)
        
        return button
    end
    
    function Dialog:Open()
        self.Scale.Scale = 1.1
        self.SetTint(0.75)
        self.SetRootTransparency(0)
        self.SetScale(1)
    end
    
    function Dialog:Close()
        self.SetTint(1)
        self.SetRootTransparency(1)
        self.SetScale(1.1)
        
        task.delay(0.15, function()
            self.TintFrame:Destroy()
        end)
    end
    
    return Dialog
    
end

-- Module: Components/Notification
_modules["Components/Notification"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║              Notification Component v2.15                     ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        Features:
        • Multiple notification types (info, success, warning, error)
        • Action buttons
        • Progress bar support
        • Stacking and queue management
        • Custom icons
        • Sound effects
        • Click callbacks
    ]]
    
    local Notification = {}
    Notification.__index = Notification
    
    local Creator
    local Flipper
    local Icons
    local Services
    
    local NotificationHolder
    local ActiveNotifications = {}
    local MAX_VISIBLE = 5
    
    local NOTIFICATION_TYPES = {
        info = {
            Icon = "rbxassetid://7734033615", -- Info icon
            Color = Color3.fromRGB(59, 130, 246), -- Blue
            Sound = nil
        },
        success = {
            Icon = "rbxassetid://7733960981", -- Check icon
            Color = Color3.fromRGB(34, 197, 94), -- Green
            Sound = nil
        },
        warning = {
            Icon = "rbxassetid://7743879203", -- Warning icon
            Color = Color3.fromRGB(234, 179, 8), -- Yellow
            Sound = nil
        },
        error = {
            Icon = "rbxassetid://7733961353", -- Error icon
            Color = Color3.fromRGB(239, 68, 68), -- Red
            Sound = nil
        }
    }
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Flipper = _require("Packages/Flipper")
        Services = _require("Core/Services")
        
        local iconsSuccess, iconsModule = pcall(function()
            return _require("Utils/Icons")
        end)
        if iconsSuccess then
            Icons = iconsModule
        end
    end
    
    function Notification.Init(screenGui)
        InitDependencies()
        
        if NotificationHolder then return end
        
        NotificationHolder = Creator.New("Frame", {
            Position = UDim2.new(1, -20, 1, -20),
            Size = UDim2.new(0, 340, 1, -20),
            AnchorPoint = Vector2.new(1, 1),
            BackgroundTransparency = 1,
            ZIndex = 1000,
            Parent = screenGui
        }, {
            Creator.New("UIListLayout", {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                Padding = UDim.new(0, 12)
            })
        })
    end
    
    function Notification.new(screenGui, options)
        InitDependencies()
        Notification.Init(screenGui)
        
        options = options or {}
        local Title = options.Title or "Notification"
        local Content = options.Content or ""
        local SubContent = options.SubContent or ""
        local Duration = options.Duration or 5
        local Type = options.Type or "info" -- info, success, warning, error
        local Icon = options.Icon
        local ShowProgress = options.ShowProgress or false
        local Actions = options.Actions or {} -- {{Text = "OK", Callback = function() end}}
        local OnClick = options.OnClick
        local Closable = options.Closable ~= false -- Default true
        local Persistent = options.Persistent or false
        
        local typeConfig = NOTIFICATION_TYPES[Type] or NOTIFICATION_TYPES.info
        
        local self = setmetatable({
            Closed = false,
            Paused = false
        }, Notification)
        
        -- Resolve icon
        local iconAsset = Icon or typeConfig.Icon
        if type(iconAsset) == "string" and not iconAsset:match("^rbxassetid://") then
            if Icons and Icons.Get then
                iconAsset = Icons.Get(iconAsset) or typeConfig.Icon
            else
                iconAsset = typeConfig.Icon
            end
        end
        
        -- Icon frame
        self.IconFrame = Creator.New("Frame", {
            Size = UDim2.fromOffset(36, 36),
            Position = UDim2.fromOffset(12, 12),
            BackgroundColor3 = typeConfig.Color,
            BackgroundTransparency = 0.9
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("ImageLabel", {
                Image = iconAsset,
                Size = UDim2.fromOffset(18, 18),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                ImageColor3 = typeConfig.Color
            })
        })
        
        -- Title label
        self.Title = Creator.New("TextLabel", {
            Position = UDim2.new(0, 58, 0, 12),
            Text = Title,
            RichText = true,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, Closable and -80 or -70, 0, 16),
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Content label
        self.ContentLabel = Creator.New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            Text = Content,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            TextWrapped = true,
            Visible = Content ~= "",
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Subcontent label
        self.SubContentLabel = Creator.New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            Text = SubContent,
            TextSize = 11,
            TextTransparency = 0.4,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            TextWrapped = true,
            Visible = SubContent ~= "",
            ThemeTag = {TextColor3 = "SubText"}
        })
        
        -- Label holder
        self.LabelHolder = Creator.New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(58, 30),
            Size = UDim2.new(1, -70, 0, 0)
        }, {
            Creator.New("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4)
            }),
            self.ContentLabel,
            self.SubContentLabel
        })
        
        -- Action buttons
        if #Actions > 0 then
            self.ActionsHolder = Creator.New("Frame", {
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -12, 0, 0),
                AnchorPoint = Vector2.new(1, 0)
            }, {
                Creator.New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    Padding = UDim.new(0, 8)
                })
            })
            
            for _, action in ipairs(Actions) do
                local isPrimary = action.Primary or false
                local actionButton = Creator.New("TextButton", {
                    Text = action.Text or "Action",
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
                    TextSize = 11,
                    Size = UDim2.new(0, 60, 0, 26),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = isPrimary and 0.1 or 0.9,
                    Parent = self.ActionsHolder,
                    ThemeTag = {
                        BackgroundColor3 = isPrimary and "Accent" or "Element",
                        TextColor3 = isPrimary and "Background" or "Text"
                    }
                }, {
                    Creator.New("UICorner", {CornerRadius = UDim.new(0, 4)}),
                    Creator.New("UIPadding", {
                        PaddingLeft = UDim.new(0, 10),
                        PaddingRight = UDim.new(0, 10)
                    })
                })
                
                Creator.AddSignal(actionButton.MouseButton1Click, function()
                    if action.Callback then
                        action.Callback()
                    end
                    if action.CloseOnClick ~= false then
                        self:Close()
                    end
                end)
            end
        end
        
        -- Progress bar
        if ShowProgress and Duration then
            self.ProgressBar = Creator.New("Frame", {
                Size = UDim2.new(1, 0, 0, 3),
                Position = UDim2.new(0, 0, 1, 0),
                AnchorPoint = Vector2.new(0, 1),
                BackgroundTransparency = 0.8,
                ThemeTag = {BackgroundColor3 = "ElementBorder"}
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(0, 2)}),
                Creator.New("Frame", {
                    Name = "Fill",
                    Size = UDim2.fromScale(1, 1),
                    BackgroundColor3 = typeConfig.Color,
                    Parent = self.ProgressBar
                }, {
                    Creator.New("UICorner", {CornerRadius = UDim.new(0, 2)})
                })
            })
        end
        
        -- Close button
        if Closable then
            self.CloseButton = Creator.New("TextButton", {
                Text = "",
                Position = UDim2.new(1, -8, 0, 8),
                Size = UDim2.fromOffset(20, 20),
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1
            }, {
                Creator.New("ImageLabel", {
                    Image = "rbxassetid://7743878326",
                    Size = UDim2.fromOffset(12, 12),
                    Position = UDim2.fromScale(0.5, 0.5),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    ImageTransparency = 0.3,
                    ThemeTag = {ImageColor3 = "Text"}
                })
            })
            
            Creator.AddSignal(self.CloseButton.MouseButton1Click, function()
                self:Close()
            end)
        end
        
        -- Accent bar on left side
        self.AccentBar = Creator.New("Frame", {
            Size = UDim2.new(0, 4, 1, -8),
            Position = UDim2.fromOffset(4, 4),
            BackgroundColor3 = typeConfig.Color
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 2)})
        })
        
        -- Background frame
        self.Background = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 0.05,
            ThemeTag = {BackgroundColor3 = "Background"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 10)}),
            Creator.New("UIStroke", {
                Transparency = 0.7,
                ThemeTag = {Color = "ElementBorder"}
            })
        })
        
        -- Root
        local rootChildren = {
            self.Background,
            self.AccentBar,
            self.IconFrame,
            self.Title,
            self.LabelHolder,
            Closable and self.CloseButton or nil,
            ShowProgress and self.ProgressBar or nil,
            #Actions > 0 and self.ActionsHolder or nil
        }
        
        self.Root = Creator.New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.fromScale(1.2, 0)
        }, rootChildren)
        
        -- Click callback
        if OnClick then
            local clickDetector = Creator.New("TextButton", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = -1,
                Parent = self.Root
            })
            Creator.AddSignal(clickDetector.MouseButton1Click, function()
                OnClick()
                self:Close()
            end)
        end
        
        -- Holder for animation
        self.Holder = Creator.New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 200),
            ClipsDescendants = true,
            Parent = NotificationHolder
        }, {
            self.Root
        })
        
        -- Animation motor
        self.Motor = Flipper.GroupMotor.new({Scale = 1.2, Offset = 0})
        self.Motor:onStep(function(values)
            self.Root.Position = UDim2.new(values.Scale, values.Offset, 0, 0)
        end)
        
        -- Pause on hover
        Creator.AddSignal(self.Root.MouseEnter, function()
            self.Paused = true
        end)
        
        Creator.AddSignal(self.Root.MouseLeave, function()
            self.Paused = false
        end)
        
        -- Open animation
        task.defer(function()
            -- Calculate height
            local hasActions = #Actions > 0
            local contentHeight = self.LabelHolder.AbsoluteSize.Y
            local actionsHeight = hasActions and 38 or 0
            local progressHeight = ShowProgress and 6 or 0
            local totalHeight = math.max(60, 42 + contentHeight + actionsHeight + progressHeight)
            
            -- Position actions
            if hasActions then
                self.ActionsHolder.Position = UDim2.new(1, -12, 0, 42 + contentHeight + 8)
            end
            
            self.Holder.Size = UDim2.new(1, 0, 0, totalHeight)
            self.Motor:setGoal({
                Scale = Flipper.Spring.new(0, {frequency = 6, dampingRatio = 0.8}),
                Offset = Flipper.Spring.new(0, {frequency = 6})
            })
        end)
        
        -- Progress animation and auto close
        if Duration and not Persistent then
            local startTime = tick()
            local progressFill = self.ProgressBar and self.ProgressBar:FindFirstChild("Fill")
            
            task.spawn(function()
                while not self.Closed do
                    task.wait(0.016) -- ~60fps
                    if not self.Paused then
                        local elapsed = tick() - startTime
                        local progress = 1 - (elapsed / Duration)
                        
                        if progressFill then
                            progressFill.Size = UDim2.new(math.max(0, progress), 0, 1, 0)
                        end
                        
                        if elapsed >= Duration then
                            self:Close()
                            break
                        end
                    else
                        startTime = tick() - (Duration * (progressFill and (1 - progressFill.Size.X.Scale) or 0))
                    end
                end
            end)
        end
        
        -- Track active notifications
        table.insert(ActiveNotifications, self)
        
        return self
    end
    
    function Notification:Close()
        if self.Closed then return end
        self.Closed = true
        
        self.Motor:setGoal({
            Scale = Flipper.Spring.new(1.2, {frequency = 6}),
            Offset = Flipper.Spring.new(0, {frequency = 6})
        })
        
        task.delay(0.3, function()
            -- Remove from active
            for i, notif in ipairs(ActiveNotifications) do
                if notif == self then
                    table.remove(ActiveNotifications, i)
                    break
                end
            end
            
            if self.Holder then
                self.Holder:Destroy()
            end
        end)
    end
    
    -- Static method to show quick notification
    function Notification.Show(screenGui, title, content, notifType, duration)
        return Notification.new(screenGui, {
            Title = title,
            Content = content,
            Type = notifType or "info",
            Duration = duration or 5,
            ShowProgress = true
        })
    end
    
    -- Clear all notifications
    function Notification.ClearAll()
        for _, notif in ipairs(ActiveNotifications) do
            notif:Close()
        end
    end
    
    return Notification
    
end

-- Module: Components/Section
_modules["Components/Section"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                       GUI Framework                           ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
    ]]
    
    local Section = {}
    Section.__index = Section
    
    local Creator
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
    end
    
    function Section.new(tab, title)
        InitDependencies()
        
        local self = setmetatable({}, Section)
        
        self.Tab = tab
        self.Title = title or "Section"
        
        -- Container layout
        local Layout = Creator.New("UIListLayout", {
            Padding = UDim.new(0, 5)
        })
        
        -- Container frame
        self.Container = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, 26),
            Position = UDim2.fromOffset(0, 24),
            BackgroundTransparency = 1
        }, {
            Layout
        })
        
        -- Root frame
        self.Root = Creator.New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 26),
            LayoutOrder = 7,
            Parent = tab.Container
        }, {
            Creator.New("TextLabel", {
                RichText = true,
                Text = title,
                FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold),
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -16, 0, 18),
                Position = UDim2.fromOffset(0, 2),
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "Text"}
            }),
            self.Container
        })
        
        -- Auto-size section based on content
        Creator.AddSignal(Layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            self.Container.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y)
            self.Root.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y + 25)
        end)
        
        self.ScrollFrame = tab.Container
        
        return self
    end
    
    -- Element methods for Section
    function Section:AddButton(options)
        local Elements = _require("Elements.Button")
        return Elements.new(self.Container, options)
    end
    
    function Section:AddToggle(options)
        local Elements = _require("Elements.Toggle")
        return Elements.new(self.Container, options)
    end
    
    function Section:AddSlider(options)
        local Elements = _require("Elements.Slider")
        return Elements.new(self.Container, options)
    end
    
    function Section:AddDropdown(options)
        local Elements = _require("Elements.Dropdown")
        return Elements.new(self.Container, options)
    end
    
    function Section:AddInput(options)
        local Elements = _require("Elements.Input")
        return Elements.new(self.Container, options)
    end
    
    function Section:AddKeybind(options)
        local Elements = _require("Elements.Keybind")
        return Elements.new(self.Container, options)
    end
    
    function Section:AddColorPicker(options)
        local Elements = _require("Elements.ColorPicker")
        return Elements.new(self.Container, options)
    end
    
    function Section:AddParagraph(options)
        local Elements = _require("Elements.Paragraph")
        return Elements.new(self.Container, options)
    end
    
    return Section
    
end

-- Module: Components/Tab
_modules["Components/Tab"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                       GUI Framework                           ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
    ]]
    
    local Tab = {}
    Tab.__index = Tab
    
    local Creator
    local Flipper
    local Elements
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Flipper = _require("Packages/Flipper")
    end
    
    function Tab.new(window, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Tab"
        local Icon = options.Icon
        
        local self = setmetatable({}, Tab)
        
        window.TabCount = window.TabCount + 1
        local tabIndex = window.TabCount
        
        self.Window = window
        self.Name = Title
        self.Icon = Icon
        self.Selected = false
        
        -- Tab button
        self.Frame = Creator.New("TextButton", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundTransparency = 1,
            Text = "",
            Parent = window.TabHolder,
            ThemeTag = {BackgroundColor3 = "Tab"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)}),
            Creator.New("TextLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = Icon and UDim2.new(0, 30, 0.5, 0) or UDim2.new(0, 12, 0.5, 0),
                Text = Title,
                RichText = true,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -12, 1, 0),
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "Text"}
            })
        })
        
        -- Icon
        if Icon then
            self.IconLabel = Creator.New("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.fromOffset(16, 16),
                Position = UDim2.new(0, 8, 0.5, 0),
                BackgroundTransparency = 1,
                Image = type(Icon) == "number" and ("rbxassetid://" .. Icon) or Icon,
                Parent = self.Frame,
                ThemeTag = {ImageColor3 = "Text"}
            })
        end
        
        -- Content container (scrolling frame)
        local ListLayout = Creator.New("UIListLayout", {
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        
        self.ContainerFrame = Creator.New("ScrollingFrame", {
            Size = UDim2.new(1, -10, 1, -30),
            Position = UDim2.new(0, 0, 0, 28),
            BackgroundTransparency = 1,
            Visible = false,
            BottomImage = "rbxassetid://6889812791",
            MidImage = "rbxassetid://6889812721",
            TopImage = "rbxassetid://6276641225",
            ScrollBarImageTransparency = 0.95,
            ScrollBarThickness = 3,
            CanvasSize = UDim2.fromScale(0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Parent = window.ContainerHolder,
            ThemeTag = {ScrollBarImageColor3 = "Text"}
        }, {
            ListLayout,
            Creator.New("UIPadding", {
                PaddingRight = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 1),
                PaddingTop = UDim.new(0, 1),
                PaddingBottom = UDim.new(0, 1)
            })
        })
        
        -- Auto-size canvas
        Creator.AddSignal(ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            self.ContainerFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 2)
        end)
        
        -- Animation motor
        self.Motor, self.SetTransparency = Creator.SpringMotor(1, self.Frame, "BackgroundTransparency")
        
        -- Hover effects
        Creator.AddSignal(self.Frame.MouseEnter, function()
            self.SetTransparency(self.Selected and 0.85 or 0.89)
        end)
        
        Creator.AddSignal(self.Frame.MouseLeave, function()
            self.SetTransparency(self.Selected and 0.89 or 1)
        end)
        
        Creator.AddSignal(self.Frame.MouseButton1Down, function()
            self.SetTransparency(0.92)
        end)
        
        Creator.AddSignal(self.Frame.MouseButton1Up, function()
            self.SetTransparency(self.Selected and 0.85 or 0.89)
        end)
        
        -- Click to select
        Creator.AddSignal(self.Frame.MouseButton1Click, function()
            window:SelectTab(tabIndex)
        end)
        
        -- Register tab
        window.Tabs[tabIndex] = self
        self.Container = self.ContainerFrame
        self.ScrollFrame = self.ContainerFrame
        
        -- Select first tab automatically
        if tabIndex == 1 then
            task.defer(function()
                window:SelectTab(1)
            end)
        end
        
        return self
    end
    
    -- Add section
    function Tab:AddSection(title)
        local Section = _require("Components/Section")
        return Section.new(self, title)
    end
    
    -- Element methods (delegate to Elements module)
    function Tab:AddButton(options)
        local Elements = _require("Elements.Button")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddToggle(options)
        local Elements = _require("Elements.Toggle")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddSlider(options)
        local Elements = _require("Elements.Slider")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddDropdown(options)
        local Elements = _require("Elements.Dropdown")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddInput(options)
        local Elements = _require("Elements.Input")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddKeybind(options)
        local Elements = _require("Elements.Keybind")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddColorPicker(options)
        local Elements = _require("Elements.ColorPicker")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddParagraph(options)
        local Elements = _require("Elements.Paragraph")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddImageGallery(options)
        local Elements = _require("Elements.ImageGallery")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddImageButton(options)
        local Elements = _require("Elements.ImageButton")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddVideoPlayer(options)
        local Elements = _require("Elements.VideoPlayer")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddFrameAnimation(options)
        local Elements = _require("Elements.FrameAnimation")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddProfileCard(options)
        local Elements = _require("Elements.ProfileCard")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddProgressBar(options)
        local Elements = _require("Elements.ProgressBar")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddRichText(options)
        local Elements = _require("Elements.RichText")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddDivider(options)
        local Elements = _require("Elements.Divider")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddCheckbox(options)
        local Elements = _require("Elements.Checkbox")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddRadioButton(options)
        local Elements = _require("Elements.RadioButton")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddTextbox(options)
        local Elements = _require("Elements.Textbox")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddSearchBox(options)
        local Elements = _require("Elements.SearchBox")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddTable(options)
        local Elements = _require("Elements.Table")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddStatCard(options)
        local Elements = _require("Elements.StatCard")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddTimer(options)
        local Elements = _require("Elements.Timer")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddBadge(options)
        local Elements = _require("Elements.Badge")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddCard(options)
        local Elements = _require("Elements.Card")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddAccordion(options)
        local Elements = _require("Elements.Accordion")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddTabs(options)
        local Elements = _require("Elements.TabsElement")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddList(options)
        local Elements = _require("Elements.List")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddStepper(options)
        local Elements = _require("Elements.Stepper")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddRangeSlider(options)
        local Elements = _require("Elements.RangeSlider")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddAvatar(options)
        local Elements = _require("Elements.Avatar")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddChip(options)
        local Elements = _require("Elements.Chip")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddBreadcrumb(options)
        local Elements = _require("Elements.Breadcrumb")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddRating(options)
        local Elements = _require("Elements.Rating")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddAlert(options)
        local Elements = _require("Elements.Alert")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddCodeBlock(options)
        local Elements = _require("Elements.CodeBlock")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddCarousel(options)
        local Elements = _require("Elements.Carousel")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddMusicPlayer(options)
        local Elements = _require("Elements.MusicPlayer")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddGrid(options)
        local Elements = _require("Elements.Grid")
        return Elements.new(self.Container, options)
    end
    
    function Tab:AddTooltip(options)
        local Elements = _require("Elements.TooltipElement")
        return Elements.new(self.Container, options)
    end
    
    return Tab
    
end

-- Module: Components/Window
_modules["Components/Window"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                       GUI Framework                           ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
    ]]
    
    local Window = {}
    Window.__index = Window
    
    local Creator
    local Flipper
    local Themes
    local Services
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Flipper = _require("Packages/Flipper")
        Themes = _require("Themes")
        Services = _require("Core/Services")
        
        -- Initialize Creator themes
        Creator.Themes = Themes
        Creator.CurrentTheme = Themes.Dark
    end
    
    function Window.new(options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "NexusUI"
        local SubTitle = options.SubTitle or options.Subtitle or ""
        local Size = options.Size or UDim2.fromOffset(580, 460)
        local Theme = options.Theme or "Dark"
        local TabWidth = options.TabWidth or 150
        local Resizable = options.Resizable ~= false
        local MinSize = options.MinSize or Vector2.new(400, 300)
        local MaxSize = options.MaxSize or Vector2.new(1200, 800)
        local ToggleKey = options.ToggleKey or Enum.KeyCode.RightShift
        local BackgroundImage = options.BackgroundImage
        local BackgroundTransparency = options.BackgroundTransparency or 0
        local Padding = options.Padding or 8
        
        -- Set theme
        Creator.SetTheme(Theme)
        
        local self = setmetatable({}, Window)
        
        self.Title = Title
        self.SubTitle = SubTitle
        self.Tabs = {}
        self.TabCount = 0
        self.SelectedTab = 0
        self.Minimized = false
        self.Maximized = false
        self.Hidden = false
        self.Resizable = Resizable
        self.MinSize = MinSize
        self.MaxSize = MaxSize
        self.ToggleKey = ToggleKey
        self.OriginalSize = Size
        self.TabWidth = TabWidth
        
        -- Create ScreenGui
        self.ScreenGui = Creator.New("ScreenGui", {
            Name = "NexusUI_" .. Services.HttpService:GenerateGUID(false),
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            IgnoreGuiInset = true
        })
        
        -- Parent to CoreGui or PlayerGui
        local success = pcall(function()
            if gethui then
                self.ScreenGui.Parent = gethui()
            elseif syn and syn.protect_gui then
                syn.protect_gui(self.ScreenGui)
                self.ScreenGui.Parent = Services.CoreGui
            else
                self.ScreenGui.Parent = Services.CoreGui
            end
        end)
        
        if not success then
            self.ScreenGui.Parent = Services.LocalPlayer:WaitForChild("PlayerGui")
        end
        
        -- Main container
        self.Root = Creator.New("Frame", {
            Size = Size,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Parent = self.ScreenGui,
            ThemeTag = {BackgroundColor3 = "Background"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 10)})
        })
        
        -- Background image (optional)
        if BackgroundImage then
            self.BackgroundImage = Creator.New("ImageLabel", {
                Image = BackgroundImage,
                Size = UDim2.fromScale(1, 1),
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.fromScale(0, 0),
                BackgroundTransparency = 1,
                ImageTransparency = BackgroundTransparency,
                ScaleType = Enum.ScaleType.Crop,
                ZIndex = 0,
                Parent = self.Root
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(0, 10)})
            })
        end
        
        -- Border stroke
        Creator.New("UIStroke", {
            Transparency = 0.5,
            Thickness = 1,
            Parent = self.Root,
            ThemeTag = {Color = "ElementBorder"}
        })
        
        -- Shadow
        self.Shadow = Creator.New("ImageLabel", {
            Image = "rbxassetid://8992230677",
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(99, 99, 99, 99),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(1, 60, 1, 58),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1,
            ImageTransparency = 0.6,
            ZIndex = -1,
            Parent = self.Root,
            ThemeTag = {ImageColor3 = "Shadow"}
        })
        
        -- Title bar
        self.TitleBar = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, 42),
            BackgroundTransparency = 1,
            Parent = self.Root
        }, {
            Creator.New("UIListLayout", {
                Padding = UDim.new(0, 5),
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center
            }),
            Creator.New("UIPadding", {
                PaddingLeft = UDim.new(0, 16)
            })
        })
        
        -- Title text
        self.TitleLabel = Creator.New("TextLabel", {
            Text = Title,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromScale(0, 1),
            BackgroundTransparency = 1,
            Parent = self.TitleBar,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Subtitle
        if SubTitle ~= "" then
            self.SubTitleLabel = Creator.New("TextLabel", {
                Text = SubTitle,
                TextTransparency = 0.4,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.fromScale(0, 1),
                BackgroundTransparency = 1,
                Parent = self.TitleBar,
                ThemeTag = {TextColor3 = "Text"}
            })
        end
        
        -- Title bar divider
        self.TitleBarLine = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 0, 42),
            BackgroundTransparency = 0.5,
            Parent = self.Root,
            ThemeTag = {BackgroundColor3 = "TitleBarLine"}
        })
        
        -- Control buttons container
        self.ButtonContainer = Creator.New("Frame", {
            Size = UDim2.new(0, 110, 0, 42),
            Position = UDim2.new(1, -4, 0, 0),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            Parent = self.Root
        })
        
        -- Control buttons
        self:CreateControlButton("Close", UDim2.new(1, -4, 0, 4), "rbxassetid://9886659671", function()
            self:Destroy()
        end, Color3.fromRGB(255, 100, 100))
        
        self:CreateControlButton("Maximize", UDim2.new(1, -40, 0, 4), "rbxassetid://9886659406", function()
            self:ToggleMaximize()
        end)
        
        self:CreateControlButton("Minimize", UDim2.new(1, -76, 0, 4), "rbxassetid://9886659276", function()
            self:ToggleMinimize()
        end)
        
        -- Left side: Tab holder
        self.TabHolder = Creator.New("ScrollingFrame", {
            Size = UDim2.new(0, TabWidth, 1, -52),
            Position = UDim2.new(0, Padding, 0, 48),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            ScrollBarImageTransparency = 0.7,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Parent = self.Root,
            ThemeTag = {ScrollBarImageColor3 = "SubText"}
        }, {
            Creator.New("UIListLayout", {
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            Creator.New("UIPadding", {
                PaddingTop = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4)
            })
        })
        
        -- Tab selector indicator
        self.TabSelector = Creator.New("Frame", {
            Size = UDim2.new(0, 3, 0, 24),
            Position = UDim2.new(0, 4, 0, 55),
            BackgroundTransparency = 0,
            Parent = self.Root,
            ThemeTag = {BackgroundColor3 = "Accent"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 2)})
        })
        
        -- Selector animation motor
        self.SelectorMotor = Flipper.SingleMotor.new(0)
        self.SelectorMotor:onStep(function(value)
            self.TabSelector.Position = UDim2.new(0, 4, 0, 55 + value)
        end)
        
        -- Right side: Content container
        self.ContainerHolder = Creator.New("Frame", {
            Size = UDim2.new(1, -TabWidth - (Padding * 2 + 4), 1, -56),
            Position = UDim2.new(0, TabWidth + Padding + 4, 0, 50),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Parent = self.Root
        })
        
        -- Tab display title
        self.TabDisplay = Creator.New("TextLabel", {
            Size = UDim2.new(1, 0, 0, 24),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
            TextSize = 18,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.ContainerHolder,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Content position and transparency motors
        self.ContainerPosMotor = Flipper.SingleMotor.new(94)
        self.ContainerBackMotor = Flipper.SingleMotor.new(0)
        
        -- Make window draggable
        Creator.MakeDraggable(self.Root, self.TitleBar)
        
        -- Resizable handle (bottom right corner)
        if Resizable then
            self:CreateResizeHandle()
        end
        
        -- Toggle keybind
        Creator.AddSignal(Services.UserInputService.InputBegan, function(input, processed)
            if processed then return end
            if input.KeyCode == self.ToggleKey then
                self:Toggle()
            end
        end)
        
        return self
    end
    
    function Window:CreateControlButton(name, position, icon, callback, hoverColor)
        local button = Creator.New("TextButton", {
            Size = UDim2.new(0, 34, 1, -8),
            Position = position,
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            Text = "",
            Parent = self.ButtonContainer,
            ThemeTag = {BackgroundColor3 = "Text"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 7)}),
            Creator.New("ImageLabel", {
                Image = icon,
                Size = UDim2.fromOffset(16, 16),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Name = "Icon",
                ThemeTag = {ImageColor3 = "Text"}
            })
        })
        
        local motor, setTransparency = Creator.SpringMotor(1, button, "BackgroundTransparency")
        
        Creator.AddSignal(button.MouseEnter, function()
            setTransparency(0.92)
            if hoverColor then
                Creator.Tween(button, {BackgroundColor3 = hoverColor}, 0.15)
            end
        end)
        
        Creator.AddSignal(button.MouseLeave, function()
            setTransparency(1, true)
        end)
        
        Creator.AddSignal(button.MouseButton1Down, function()
            setTransparency(0.88)
        end)
        
        Creator.AddSignal(button.MouseButton1Up, function()
            setTransparency(0.92)
        end)
        
        Creator.AddSignal(button.MouseButton1Click, callback)
        
        return button
    end
    
    function Window:CreateResizeHandle()
        local resizing = false
        local startPos
        local startSize
        
        self.ResizeHandle = Creator.New("TextButton", {
            Size = UDim2.fromOffset(20, 20),
            Position = UDim2.new(1, -2, 1, -2),
            AnchorPoint = Vector2.new(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            Parent = self.Root,
            ZIndex = 10
        }, {
            Creator.New("ImageLabel", {
                Image = "rbxassetid://5574655095",
                Size = UDim2.fromOffset(12, 12),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                ImageTransparency = 0.5,
                Rotation = 90,
                ThemeTag = {ImageColor3 = "SubText"}
            })
        })
        
        Creator.AddSignal(self.ResizeHandle.MouseButton1Down, function()
            resizing = true
            startPos = Services.UserInputService:GetMouseLocation()
            startSize = self.Root.AbsoluteSize
        end)
        
        Creator.AddSignal(Services.UserInputService.InputChanged, function(input)
            if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
                local currentPos = Services.UserInputService:GetMouseLocation()
                local delta = currentPos - startPos
                
                local newWidth = math.clamp(startSize.X + delta.X, self.MinSize.X, self.MaxSize.X)
                local newHeight = math.clamp(startSize.Y + delta.Y, self.MinSize.Y, self.MaxSize.Y)
                
                self.Root.Size = UDim2.fromOffset(newWidth, newHeight)
            end
        end)
        
        Creator.AddSignal(Services.UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = false
            end
        end)
    end
    
    function Window:AddTab(options)
        local Tab = _require("Components/Tab")
        return Tab.new(self, options)
    end
    
    function Window:SelectTab(index)
        self.SelectedTab = index
        
        for i, tab in pairs(self.Tabs) do
            tab.SetTransparency(1)
            tab.Selected = false
            tab.ContainerFrame.Visible = false
        end
        
        local selectedTab = self.Tabs[index]
        if selectedTab then
            selectedTab.SetTransparency(0.89)
            selectedTab.Selected = true
            selectedTab.ContainerFrame.Visible = true
            self.TabDisplay.Text = selectedTab.Name
            
            -- Animate selector
            local tabPos = selectedTab.Frame.AbsolutePosition.Y - self.TabHolder.AbsolutePosition.Y
            self.SelectorMotor:setGoal(Flipper.Spring.new(tabPos, {frequency = 6}))
        end
    end
    
    function Window:ToggleMinimize()
        self.Minimized = not self.Minimized
        
        if self.Minimized then
            self.OriginalSize = self.Root.Size
            Creator.Tween(self.Root, {Size = UDim2.fromOffset(self.Root.AbsoluteSize.X, 42)}, 0.3)
        else
            Creator.Tween(self.Root, {Size = self.OriginalSize}, 0.3)
        end
    end
    
    function Window:ToggleMaximize()
        self.Maximized = not self.Maximized
        
        if self.Maximized then
            self.PreMaxSize = self.Root.Size
            self.PreMaxPos = self.Root.Position
            Creator.Tween(self.Root, {
                Size = UDim2.new(1, -40, 1, -40),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }, 0.3)
        else
            Creator.Tween(self.Root, {
                Size = self.PreMaxSize or self.OriginalSize,
                Position = self.PreMaxPos or UDim2.new(0.5, 0, 0.5, 0)
            }, 0.3)
        end
    end
    
    function Window:Toggle()
        if self.Hidden then
            self:Show()
        else
            self:Hide()
        end
    end
    
    function Window:Hide()
        self.Hidden = true
        Creator.Tween(self.Root, {Position = UDim2.new(0.5, 0, 1.5, 0)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    end
    
    function Window:Show()
        self.Hidden = false
        Creator.Tween(self.Root, {Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.4, Enum.EasingStyle.Back)
    end
    
    function Window:SetBackgroundImage(imageId, transparency)
        if self.BackgroundImage then
            self.BackgroundImage.Image = imageId
            self.BackgroundImage.ImageTransparency = transparency or 0
        else
            self.BackgroundImage = Creator.New("ImageLabel", {
                Image = imageId,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                ImageTransparency = transparency or 0,
                ScaleType = Enum.ScaleType.Crop,
                ZIndex = 0,
                Parent = self.Root
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(0, 10)})
            })
        end
    end
    
    function Window:SetSize(size)
        Creator.Tween(self.Root, {Size = size}, 0.3)
    end
    
    function Window:Destroy()
        Creator.Disconnect()
        self.ScreenGui:Destroy()
    end
    
    function Window:Notify(options)
        local Notification = _require("Components/Notification")
        return Notification.new(self.ScreenGui, options)
    end
    
    function Window:Dialog(options)
        local Dialog = _require("Components/Dialog")
        return Dialog.new(self, options)
    end
    
    return Window
    
end

-- Module: Components/LoadingScreen
_modules["Components/LoadingScreen"] = function()
    --[[
        NexusUI Loading Screen Component
        Beautiful animated loading screen with progress, custom images, music, and effects
    ]]
    
    local LoadingScreen = {}
    LoadingScreen.__index = LoadingScreen
    
    local Creator, Flipper, Services
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Flipper = _require("Packages/Flipper")
        Services = _require("Core/Services")
    end
    
    function LoadingScreen.new(options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Loading..."
        local Subtitle = options.Subtitle or "Please wait"
        local LogoImage = options.Logo -- Custom logo image
        local BackgroundImage = options.Background -- Custom background
        local BackgroundColor = options.BackgroundColor or Color3.fromRGB(15, 15, 18)
        local AccentColor = options.AccentColor or Color3.fromRGB(100, 150, 255)
        local Music = options.Music -- Background music ID
        local LoadingStyle = options.Style or "Modern" -- Modern, Minimal, Gaming, Cinematic
        local BlurBackground = options.Blur ~= false
        local Particles = options.Particles ~= false
        
        local self = setmetatable({}, LoadingScreen)
        self.Progress = 0
        self.Tasks = {}
        self.CurrentTask = ""
        self.Completed = false
        
        -- Create ScreenGui
        self.ScreenGui = Creator.New("ScreenGui", {
            Name = "NexusUI_LoadingScreen",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            IgnoreGuiInset = true,
            DisplayOrder = 999
        })
        
        -- Parent
        pcall(function()
            if gethui then
                self.ScreenGui.Parent = gethui()
            elseif syn and syn.protect_gui then
                syn.protect_gui(self.ScreenGui)
                self.ScreenGui.Parent = Services.CoreGui
            else
                self.ScreenGui.Parent = Services.CoreGui
            end
        end)
        
        -- Blur effect
        if BlurBackground then
            self.Blur = Instance.new("BlurEffect")
            self.Blur.Size = 0
            self.Blur.Parent = Services.Lighting
        end
        
        -- Background
        self.Background = Creator.New("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = BackgroundColor,
            Parent = self.ScreenGui
        })
        
        -- Background image overlay
        if BackgroundImage then
            self.BackgroundImage = Creator.New("ImageLabel", {
                Size = UDim2.fromScale(1, 1),
                Image = type(BackgroundImage) == "number" and ("rbxassetid://" .. BackgroundImage) or BackgroundImage,
                ImageTransparency = 0.3,
                ScaleType = Enum.ScaleType.Crop,
                BackgroundTransparency = 1,
                Parent = self.Background
            })
            
            -- Animated gradient overlay
            Creator.New("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.new(0.1, 0.1, 0.1)),
                    ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0))
                }),
                Transparency = NumberSequence.new(0.5),
                Rotation = 45,
                Parent = self.BackgroundImage
            })
        end
        
        -- Particle effects
        if Particles then
            self:CreateParticles()
        end
        
        -- Content container
        self.Content = Creator.New("Frame", {
            Size = UDim2.fromOffset(400, 350),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Parent = self.Background
        })
        
        -- Logo
        if LogoImage then
            self.Logo = Creator.New("ImageLabel", {
                Size = UDim2.fromOffset(120, 120),
                Position = UDim2.new(0.5, 0, 0, 0),
                AnchorPoint = Vector2.new(0.5, 0),
                Image = type(LogoImage) == "number" and ("rbxassetid://" .. LogoImage) or LogoImage,
                BackgroundTransparency = 1,
                Parent = self.Content
            })
            
            -- Logo glow
            self.LogoGlow = Creator.New("ImageLabel", {
                Size = UDim2.fromOffset(180, 180),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Image = "rbxassetid://5028857084", -- Glow effect
                ImageColor3 = AccentColor,
                ImageTransparency = 0.7,
                BackgroundTransparency = 1,
                ZIndex = -1,
                Parent = self.Logo
            })
            
            -- Animate logo rotation
            self:AnimateLogo()
        end
        
        -- Title
        self.TitleLabel = Creator.New("TextLabel", {
            Size = UDim2.new(1, 0, 0, 40),
            Position = UDim2.new(0, 0, 0, LogoImage and 140 or 80),
            Text = Title,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
            TextSize = 32,
            TextColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 1,
            Parent = self.Content
        })
        
        -- Subtitle with typewriter effect
        self.SubtitleLabel = Creator.New("TextLabel", {
            Size = UDim2.new(1, 0, 0, 24),
            Position = UDim2.new(0, 0, 0, LogoImage and 185 or 125),
            Text = "",
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 16,
            TextColor3 = Color3.fromRGB(180, 180, 180),
            BackgroundTransparency = 1,
            Parent = self.Content
        })
        self:TypewriterEffect(Subtitle)
        
        -- Progress bar container
        self.ProgressContainer = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, 6),
            Position = UDim2.new(0, 0, 0, LogoImage and 240 or 180),
            BackgroundColor3 = Color3.fromRGB(40, 40, 45),
            Parent = self.Content
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
        })
        
        -- Progress bar fill with gradient
        self.ProgressFill = Creator.New("Frame", {
            Size = UDim2.fromScale(0, 1),
            BackgroundColor3 = AccentColor,
            Parent = self.ProgressContainer
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)}),
            Creator.New("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, AccentColor),
                    ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
                }),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.8, 0),
                    NumberSequenceKeypoint.new(1, 0.6)
                })
            })
        })
        
        -- Animated shimmer on progress bar
        self:CreateProgressShimmer()
        
        -- Progress percentage
        self.ProgressText = Creator.New("TextLabel", {
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 0, LogoImage and 255 or 195),
            Text = "0%",
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            TextSize = 14,
            TextColor3 = Color3.fromRGB(150, 150, 150),
            BackgroundTransparency = 1,
            Parent = self.Content
        })
        
        -- Current task label
        self.TaskLabel = Creator.New("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18),
            Position = UDim2.new(0, 0, 0, LogoImage and 280 or 220),
            Text = "",
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 13,
            TextColor3 = Color3.fromRGB(120, 120, 120),
            BackgroundTransparency = 1,
            Parent = self.Content
        })
        
        -- Tips section
        if options.Tips and #options.Tips > 0 then
            self:CreateTipsSection(options.Tips)
        end
        
        -- Play music
        if Music then
            self:PlayMusic(Music, options.MusicVolume or 0.5)
        end
        
        -- Animate entrance
        self:AnimateIn()
        
        return self
    end
    
    function LoadingScreen:CreateParticles()
        self.ParticleContainer = Creator.New("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Parent = self.Background
        })
        
        -- Create floating particles
        for i = 1, 30 do
            task.spawn(function()
                local particle = Creator.New("Frame", {
                    Size = UDim2.fromOffset(math.random(2, 6), math.random(2, 6)),
                    Position = UDim2.fromScale(math.random(), math.random()),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BackgroundTransparency = math.random(70, 90) / 100,
                    Parent = self.ParticleContainer
                }, {
                    Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
                })
                
                -- Animate particle
                while particle.Parent do
                    local duration = math.random(8, 15)
                    local targetY = particle.Position.Y.Scale - 0.3
                    
                    Creator.Tween(particle, {
                        Position = UDim2.fromScale(
                            particle.Position.X.Scale + (math.random() - 0.5) * 0.1,
                            targetY
                        ),
                        BackgroundTransparency = 1
                    }, duration)
                    
                    task.wait(duration)
                    
                    -- Reset particle
                    particle.Position = UDim2.fromScale(math.random(), 1.1)
                    particle.BackgroundTransparency = math.random(70, 90) / 100
                end
            end)
        end
    end
    
    function LoadingScreen:CreateProgressShimmer()
        local shimmer = Creator.New("Frame", {
            Size = UDim2.new(0.3, 0, 1, 0),
            Position = UDim2.fromScale(-0.3, 0),
            BackgroundTransparency = 1,
            Parent = self.ProgressFill
        }, {
            Creator.New("UIGradient", {
                Color = ColorSequence.new(Color3.new(1, 1, 1)),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.5, 0.5),
                    NumberSequenceKeypoint.new(1, 1)
                })
            })
        })
        
        -- Animate shimmer
        task.spawn(function()
            while shimmer.Parent do
                shimmer.Position = UDim2.fromScale(-0.3, 0)
                Creator.Tween(shimmer, {Position = UDim2.fromScale(1.3, 0)}, 1.5)
                task.wait(2)
            end
        end)
    end
    
    function LoadingScreen:AnimateLogo()
        if not self.Logo then return end
        
        task.spawn(function()
            while self.Logo and self.Logo.Parent do
                -- Gentle floating animation
                Creator.Tween(self.Logo, {Position = UDim2.new(0.5, 0, 0, -5)}, 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                task.wait(2)
                Creator.Tween(self.Logo, {Position = UDim2.new(0.5, 0, 0, 5)}, 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                task.wait(2)
            end
        end)
        
        -- Glow pulse
        if self.LogoGlow then
            task.spawn(function()
                while self.LogoGlow and self.LogoGlow.Parent do
                    Creator.Tween(self.LogoGlow, {ImageTransparency = 0.5, Size = UDim2.fromOffset(200, 200)}, 1.5)
                    task.wait(1.5)
                    Creator.Tween(self.LogoGlow, {ImageTransparency = 0.8, Size = UDim2.fromOffset(170, 170)}, 1.5)
                    task.wait(1.5)
                end
            end)
        end
    end
    
    function LoadingScreen:TypewriterEffect(text)
        task.spawn(function()
            for i = 1, #text do
                if not self.SubtitleLabel or not self.SubtitleLabel.Parent then break end
                self.SubtitleLabel.Text = string.sub(text, 1, i)
                task.wait(0.03)
            end
        end)
    end
    
    function LoadingScreen:CreateTipsSection(tips)
        self.TipsLabel = Creator.New("TextLabel", {
            Size = UDim2.new(1, -40, 0, 40),
            Position = UDim2.new(0.5, 0, 1, -60),
            AnchorPoint = Vector2.new(0.5, 1),
            Text = "💡 " .. tips[1],
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 14,
            TextColor3 = Color3.fromRGB(140, 140, 150),
            TextWrapped = true,
            BackgroundTransparency = 1,
            Parent = self.Background
        })
        
        -- Rotate tips
        if #tips > 1 then
            task.spawn(function()
                local index = 1
                while self.TipsLabel and self.TipsLabel.Parent do
                    task.wait(5)
                    index = index % #tips + 1
                    Creator.Tween(self.TipsLabel, {TextTransparency = 1}, 0.3)
                    task.wait(0.3)
                    self.TipsLabel.Text = "💡 " .. tips[index]
                    Creator.Tween(self.TipsLabel, {TextTransparency = 0}, 0.3)
                end
            end)
        end
    end
    
    function LoadingScreen:PlayMusic(musicId, volume)
        self.Music = Instance.new("Sound")
        self.Music.SoundId = type(musicId) == "number" and ("rbxassetid://" .. musicId) or musicId
        self.Music.Volume = 0
        self.Music.Looped = true
        self.Music.Parent = Services.SoundService
        self.Music:Play()
        
        -- Fade in
        Creator.Tween(self.Music, {Volume = volume}, 2)
    end
    
    function LoadingScreen:AnimateIn()
        self.Background.BackgroundTransparency = 1
        self.Content.Position = UDim2.new(0.5, 0, 0.6, 0)
        
        Creator.Tween(self.Background, {BackgroundTransparency = 0}, 0.5)
        Creator.Tween(self.Content, {Position = UDim2.fromScale(0.5, 0.5)}, 0.8, Enum.EasingStyle.Back)
        
        if self.Blur then
            Creator.Tween(self.Blur, {Size = 20}, 0.5)
        end
    end
    
    function LoadingScreen:SetProgress(progress, taskName)
        progress = math.clamp(progress, 0, 100)
        self.Progress = progress
        
        Creator.Tween(self.ProgressFill, {Size = UDim2.fromScale(progress / 100, 1)}, 0.3)
        self.ProgressText.Text = math.floor(progress) .. "%"
        
        if taskName then
            self.CurrentTask = taskName
            self.TaskLabel.Text = taskName
        end
    end
    
    function LoadingScreen:AddTask(name)
        table.insert(self.Tasks, {name = name, completed = false})
        return #self.Tasks
    end
    
    function LoadingScreen:CompleteTask(index)
        if self.Tasks[index] then
            self.Tasks[index].completed = true
        end
        
        local completed = 0
        for _, task in ipairs(self.Tasks) do
            if task.completed then completed = completed + 1 end
        end
        
        self:SetProgress((completed / #self.Tasks) * 100)
    end
    
    function LoadingScreen:Finish(callback)
        self.Completed = true
        self:SetProgress(100, "Complete!")
        
        task.delay(0.5, function()
            -- Fade out music
            if self.Music then
                Creator.Tween(self.Music, {Volume = 0}, 1)
            end
            
            -- Fade out blur
            if self.Blur then
                Creator.Tween(self.Blur, {Size = 0}, 0.5)
            end
            
            -- Animate out
            Creator.Tween(self.Content, {
                Position = UDim2.new(0.5, 0, 0.4, 0)
            }, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            
            Creator.Tween(self.Background, {BackgroundTransparency = 1}, 0.8, nil, nil, function()
                if self.Music then self.Music:Destroy() end
                if self.Blur then self.Blur:Destroy() end
                self.ScreenGui:Destroy()
                
                if callback then callback() end
            end)
        end)
    end
    
    return LoadingScreen
    
end

-- Module: Components/BootAnimation
_modules["Components/BootAnimation"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                       GUI Framework                           ║
        ║                          By Ryu                               ║
        ║                   BOOT ANIMATION v1.0                         ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        Features:
        • Animated boot sequence with logo
        • Multiple boot animation styles
        • Progress bar with stages
        • Smooth fade transitions
        • Customizable duration and messages
        • Skip on click option
        
        Usage:
            NexusUI:ShowBootAnimation({
                Duration = 3,
                LogoImage = "rbxassetid://12345",
                Title = "My Script",
                Style = "Modern" -- Minimal, Modern, Cinematic, Pulse
            })
    ]]
    
    local BootAnimation = {}
    BootAnimation.__index = BootAnimation
    
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- BOOT ANIMATION STYLES
    -- ════════════════════════════════════════════════════════════════════════════════
    
    local AnimationStyles = {
        -- Minimal: Simple fade with progress
        Minimal = function(self)
            -- Fade in
            TweenService:Create(self.Container, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
            TweenService:Create(self.Logo, TweenInfo.new(0.5), {ImageTransparency = 0}):Play()
            TweenService:Create(self.TitleLabel, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
            
            task.wait(0.5)
            self:AnimateProgress()
            task.wait(self.Duration)
            
            -- Fade out
            TweenService:Create(self.Container, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
            task.wait(0.5)
        end,
        
        -- Modern: Slide in with scale
        Modern = function(self)
            self.LogoContainer.Position = UDim2.new(0.5, 0, 0.4, 0)
            self.LogoContainer.Size = UDim2.fromOffset(0, 0)
            
            -- Container fade
            TweenService:Create(self.Container, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
            task.wait(0.2)
            
            -- Logo scale in
            TweenService:Create(self.LogoContainer, TweenInfo.new(0.6, Enum.EasingStyle.Back), {
                Size = UDim2.fromOffset(100, 100)
            }):Play()
            TweenService:Create(self.Logo, TweenInfo.new(0.3), {ImageTransparency = 0}):Play()
            
            task.wait(0.4)
            
            -- Title fade
            TweenService:Create(self.TitleLabel, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
            TweenService:Create(self.SubtitleLabel, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
            
            task.wait(0.3)
            self:AnimateProgress()
            task.wait(self.Duration)
            
            -- Fade out sequence
            TweenService:Create(self.ProgressFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            TweenService:Create(self.ProgressFill, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            task.wait(0.2)
            TweenService:Create(self.SubtitleLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            TweenService:Create(self.TitleLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            task.wait(0.2)
            TweenService:Create(self.LogoContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = UDim2.fromOffset(0, 0)
            }):Play()
            task.wait(0.3)
            TweenService:Create(self.Container, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            task.wait(0.3)
        end,
        
        -- Cinematic: Full screen with dramatic entrance
        Cinematic = function(self)
            -- Setup initial state
            self.LogoContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
            self.LogoContainer.Size = UDim2.fromOffset(150, 150)
            self.Logo.ImageTransparency = 1
            
            -- Full black screen
            TweenService:Create(self.Container, TweenInfo.new(0.8), {BackgroundTransparency = 0}):Play()
            task.wait(0.8)
            
            -- Logo fade in with glow effect
            TweenService:Create(self.Logo, TweenInfo.new(1), {ImageTransparency = 0}):Play()
            
            -- Pulsing glow
            task.spawn(function()
                for i = 1, 3 do
                    if not self.Container.Parent then break end
                    TweenService:Create(self.LogoContainer, TweenInfo.new(0.5), {
                        Size = UDim2.fromOffset(160, 160)
                    }):Play()
                    task.wait(0.5)
                    TweenService:Create(self.LogoContainer, TweenInfo.new(0.5), {
                        Size = UDim2.fromOffset(150, 150)
                    }):Play()
                    task.wait(0.5)
                end
            end)
            
            task.wait(1.2)
            
            -- Move logo up, show title
            TweenService:Create(self.LogoContainer, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {
                Position = UDim2.new(0.5, 0, 0.35, 0),
                Size = UDim2.fromOffset(80, 80)
            }):Play()
            
            task.wait(0.5)
            TweenService:Create(self.TitleLabel, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
            task.wait(0.3)
            TweenService:Create(self.SubtitleLabel, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
            
            task.wait(0.3)
            self:AnimateProgress()
            task.wait(self.Duration)
            
            -- Cinematic fade out
            TweenService:Create(self.Container, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
            task.wait(1)
        end,
        
        -- Pulse: Continuous pulsing animation
        Pulse = function(self)
            -- Fade in
            TweenService:Create(self.Container, TweenInfo.new(0.4), {BackgroundTransparency = 0}):Play()
            TweenService:Create(self.Logo, TweenInfo.new(0.4), {ImageTransparency = 0}):Play()
            TweenService:Create(self.TitleLabel, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
            TweenService:Create(self.SubtitleLabel, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
            
            task.wait(0.4)
            
            -- Start progress and pulse
            task.spawn(function()
                self:AnimateProgress()
            end)
            
            -- Pulse animation
            local pulseCount = math.floor(self.Duration / 0.8)
            for i = 1, pulseCount do
                if not self.Container.Parent then break end
                TweenService:Create(self.Logo, TweenInfo.new(0.4), {Size = UDim2.fromOffset(85, 85)}):Play()
                task.wait(0.4)
                TweenService:Create(self.Logo, TweenInfo.new(0.4), {Size = UDim2.fromOffset(80, 80)}):Play()
                task.wait(0.4)
            end
            
            task.wait(self.Duration - (pulseCount * 0.8))
            
            -- Fade out
            TweenService:Create(self.Container, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
            task.wait(0.5)
        end
    }
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- CONSTRUCTOR
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function BootAnimation.new(screenGui, options)
        options = options or {}
        
        local self = setmetatable({}, BootAnimation)
        
        self.Duration = options.Duration or 2.5
        self.Title = options.Title or "NexusUI"
        self.Subtitle = options.Subtitle or "Loading..."
        self.LogoImage = options.LogoImage or "rbxassetid://10734950309"
        self.Style = options.Style or "Modern"
        self.AccentColor = options.AccentColor or Color3.fromRGB(0, 170, 255)
        self.BackgroundColor = options.BackgroundColor or Color3.fromRGB(15, 15, 20)
        self.CanSkip = options.CanSkip ~= false
        self.OnComplete = options.OnComplete or function() end
        self.LoadingStages = options.LoadingStages or {"Initializing...", "Loading modules...", "Starting..."}
        
        self.ScreenGui = screenGui
        self.Completed = false
        
        -- Create UI
        self:CreateUI()
        
        return self
    end
    
    function BootAnimation:CreateUI()
        -- Main container (full screen overlay)
        self.Container = Instance.new("Frame")
        self.Container.Name = "BootAnimation"
        self.Container.Size = UDim2.fromScale(1, 1)
        self.Container.Position = UDim2.fromScale(0, 0)
        self.Container.BackgroundColor3 = self.BackgroundColor
        self.Container.BackgroundTransparency = 1
        self.Container.BorderSizePixel = 0
        self.Container.ZIndex = 9999
        self.Container.Parent = self.ScreenGui
        
        -- Logo container (for scaling)
        self.LogoContainer = Instance.new("Frame")
        self.LogoContainer.Name = "LogoContainer"
        self.LogoContainer.Size = UDim2.fromOffset(80, 80)
        self.LogoContainer.Position = UDim2.new(0.5, 0, 0.38, 0)
        self.LogoContainer.AnchorPoint = Vector2.new(0.5, 0.5)
        self.LogoContainer.BackgroundTransparency = 1
        self.LogoContainer.Parent = self.Container
        
        -- Logo image
        self.Logo = Instance.new("ImageLabel")
        self.Logo.Name = "Logo"
        self.Logo.Size = UDim2.fromScale(1, 1)
        self.Logo.Position = UDim2.fromScale(0.5, 0.5)
        self.Logo.AnchorPoint = Vector2.new(0.5, 0.5)
        self.Logo.BackgroundTransparency = 1
        self.Logo.Image = self.LogoImage
        self.Logo.ImageTransparency = 1
        self.Logo.ScaleType = Enum.ScaleType.Fit
        self.Logo.Parent = self.LogoContainer
        
        -- Title
        self.TitleLabel = Instance.new("TextLabel")
        self.TitleLabel.Name = "Title"
        self.TitleLabel.Size = UDim2.new(1, 0, 0, 36)
        self.TitleLabel.Position = UDim2.new(0.5, 0, 0.52, 0)
        self.TitleLabel.AnchorPoint = Vector2.new(0.5, 0)
        self.TitleLabel.BackgroundTransparency = 1
        self.TitleLabel.Font = Enum.Font.GothamBold
        self.TitleLabel.TextSize = 28
        self.TitleLabel.Text = self.Title
        self.TitleLabel.TextColor3 = Color3.new(1, 1, 1)
        self.TitleLabel.TextTransparency = 1
        self.TitleLabel.Parent = self.Container
        
        -- Subtitle (loading stage)
        self.SubtitleLabel = Instance.new("TextLabel")
        self.SubtitleLabel.Name = "Subtitle"
        self.SubtitleLabel.Size = UDim2.new(1, 0, 0, 20)
        self.SubtitleLabel.Position = UDim2.new(0.5, 0, 0.52, 42)
        self.SubtitleLabel.AnchorPoint = Vector2.new(0.5, 0)
        self.SubtitleLabel.BackgroundTransparency = 1
        self.SubtitleLabel.Font = Enum.Font.Gotham
        self.SubtitleLabel.TextSize = 14
        self.SubtitleLabel.Text = self.Subtitle
        self.SubtitleLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        self.SubtitleLabel.TextTransparency = 1
        self.SubtitleLabel.Parent = self.Container
        
        -- Progress bar background
        self.ProgressFrame = Instance.new("Frame")
        self.ProgressFrame.Name = "ProgressBackground"
        self.ProgressFrame.Size = UDim2.new(0.35, 0, 0, 4)
        self.ProgressFrame.Position = UDim2.new(0.5, 0, 0.62, 0)
        self.ProgressFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        self.ProgressFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        self.ProgressFrame.BackgroundTransparency = 1
        self.ProgressFrame.BorderSizePixel = 0
        self.ProgressFrame.Parent = self.Container
        
        local progressCorner = Instance.new("UICorner")
        progressCorner.CornerRadius = UDim.new(1, 0)
        progressCorner.Parent = self.ProgressFrame
        
        -- Progress bar fill
        self.ProgressFill = Instance.new("Frame")
        self.ProgressFill.Name = "ProgressFill"
        self.ProgressFill.Size = UDim2.new(0, 0, 1, 0)
        self.ProgressFill.Position = UDim2.fromScale(0, 0)
        self.ProgressFill.BackgroundColor3 = self.AccentColor
        self.ProgressFill.BackgroundTransparency = 1
        self.ProgressFill.BorderSizePixel = 0
        self.ProgressFill.Parent = self.ProgressFrame
        
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = self.ProgressFill
        
        -- Gradient on progress fill
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, self.AccentColor),
            ColorSequenceKeypoint.new(1, Color3.new(
                math.min(self.AccentColor.R + 0.2, 1),
                math.min(self.AccentColor.G + 0.2, 1),
                math.min(self.AccentColor.B + 0.2, 1)
            ))
        })
        gradient.Parent = self.ProgressFill
        
        -- "Made with Nexus" watermark
        self.Watermark = Instance.new("TextLabel")
        self.Watermark.Name = "Watermark"
        self.Watermark.Size = UDim2.new(1, 0, 0, 16)
        self.Watermark.Position = UDim2.new(0.5, 0, 1, -30)
        self.Watermark.AnchorPoint = Vector2.new(0.5, 0)
        self.Watermark.BackgroundTransparency = 1
        self.Watermark.Font = Enum.Font.Gotham
        self.Watermark.TextSize = 12
        self.Watermark.Text = "✨ Made with NexusUI"
        self.Watermark.TextColor3 = Color3.fromRGB(100, 100, 100)
        self.Watermark.TextTransparency = 0.3
        self.Watermark.Parent = self.Container
        
        -- Skip button (if enabled)
        if self.CanSkip then
            self.SkipButton = Instance.new("TextButton")
            self.SkipButton.Name = "Skip"
            self.SkipButton.Size = UDim2.new(0, 80, 0, 28)
            self.SkipButton.Position = UDim2.new(1, -20, 1, -20)
            self.SkipButton.AnchorPoint = Vector2.new(1, 1)
            self.SkipButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            self.SkipButton.BackgroundTransparency = 0.3
            self.SkipButton.Font = Enum.Font.GothamMedium
            self.SkipButton.TextSize = 12
            self.SkipButton.Text = "Skip ›"
            self.SkipButton.TextColor3 = Color3.fromRGB(180, 180, 180)
            self.SkipButton.AutoButtonColor = false
            self.SkipButton.Parent = self.Container
            
            local skipCorner = Instance.new("UICorner")
            skipCorner.CornerRadius = UDim.new(0, 6)
            skipCorner.Parent = self.SkipButton
            
            self.SkipButton.MouseButton1Click:Connect(function()
                self:Skip()
            end)
            
            self.SkipButton.MouseEnter:Connect(function()
                TweenService:Create(self.SkipButton, TweenInfo.new(0.2), {
                    BackgroundTransparency = 0.1,
                    TextColor3 = Color3.new(1, 1, 1)
                }):Play()
            end)
            
            self.SkipButton.MouseLeave:Connect(function()
                TweenService:Create(self.SkipButton, TweenInfo.new(0.2), {
                    BackgroundTransparency = 0.3,
                    TextColor3 = Color3.fromRGB(180, 180, 180)
                }):Play()
            end)
        end
    end
    
    function BootAnimation:AnimateProgress()
        -- Show progress bar
        TweenService:Create(self.ProgressFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
        TweenService:Create(self.ProgressFill, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
        
        task.wait(0.3)
        
        -- Animate progress with stages
        local stageCount = #self.LoadingStages
        local stageDuration = self.Duration / stageCount
        
        for i, stage in ipairs(self.LoadingStages) do
            if self.Completed then break end
            
            self.SubtitleLabel.Text = stage
            
            local targetProgress = i / stageCount
            TweenService:Create(self.ProgressFill, TweenInfo.new(stageDuration, Enum.EasingStyle.Quad), {
                Size = UDim2.new(targetProgress, 0, 1, 0)
            }):Play()
            
            task.wait(stageDuration)
        end
    end
    
    function BootAnimation:Play()
        task.spawn(function()
            local styleFunc = AnimationStyles[self.Style] or AnimationStyles.Modern
            styleFunc(self)
            
            -- Cleanup
            if not self.Completed then
                self.Completed = true
                self:Destroy()
                self.OnComplete()
            end
        end)
    end
    
    function BootAnimation:Skip()
        if self.Completed then return end
        self.Completed = true
        
        -- Quick fade out
        TweenService:Create(self.Container, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        
        task.delay(0.3, function()
            self:Destroy()
            self.OnComplete()
        end)
    end
    
    function BootAnimation:Destroy()
        if self.Container then
            self.Container:Destroy()
            self.Container = nil
        end
    end
    
    return BootAnimation
    
end

-- Module: Components/KeySystem
_modules["Components/KeySystem"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                       GUI Framework                           ║
        ║                          By Ryu                               ║
        ║              KEY SYSTEM v2.0 (External API)                   ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        Enhanced Key System with External Verification Endpoints
        
        Usage for Script Developers:
        
        1. STATIC KEY LIST:
            NexusUI:CreateKeySystem({
                Keys = {"KEY-ABC123", "KEY-DEF456"},
                Discord = "discord.gg/yourserver"
            })
        
        2. EXTERNAL API VERIFICATION:
            NexusUI:CreateKeySystem({
                VerifyURL = "https://your-api.com/verify",
                Method = "POST",  -- GET or POST
                Headers = {["Authorization"] = "Bearer token"},
                BodyFormat = {key = "{KEY}", hwid = "{HWID}"},
                SuccessField = "valid",  -- JSON response field to check
                SuccessValue = true,     -- Expected value for success
                ErrorField = "message",  -- Field for error message
                Discord = "discord.gg/yourserver"
            })
        
        3. LINKVERTISE/GETKEY FLOW:
            NexusUI:CreateKeySystem({
                GetKeyURL = "https://link.to/getkey",
                CheckpointURL = "https://your-api.com/checkpoint/{KEY}",
                Keys = {"valid-key"},
                Discord = "discord.gg/yourserver"
            })
        
        4. HWID LOCKED:
            NexusUI:CreateKeySystem({
                VerifyURL = "https://api.com/verify",
                HWIDLocked = true,  -- Sends HWID with request
                SaveKey = true      -- Persists key locally
            })
    ]]
    
    local KeySystem = {}
    KeySystem.__index = KeySystem
    
    local Creator
    local Services
    local HttpService = game:GetService("HttpService")
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Services = _require("Core/Services")
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- HWID GENERATION
    -- ════════════════════════════════════════════════════════════════════════════════
    
    local function GetHWID()
        local hwid = ""
        
        local success, result = pcall(function()
            if gethwid then
                return gethwid()
            elseif get_hwid then
                return get_hwid()
            elseif getexecutorname and identifyexecutor then
                -- Fallback: generate pseudo-HWID
                local player = game:GetService("Players").LocalPlayer
                local executor = identifyexecutor and identifyexecutor() or "Unknown"
                local userId = player and player.UserId or 0
                return HttpService:GenerateGUID(false) .. "-" .. tostring(userId) .. "-" .. executor
            end
            return "UNKNOWN-HWID"
        end)
        
        return success and result or "UNKNOWN-HWID"
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- CONSTRUCTOR
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function KeySystem.new(options)
        InitDependencies()
        
        options = options or {}
        
        local self = setmetatable({}, KeySystem)
        
        -- Basic settings
        self.Title = options.Title or "Key System"
        self.Subtitle = options.Subtitle or "Enter your key to continue"
        self.Logo = options.Logo
        self.BackgroundImage = options.BackgroundImage
        self.Discord = options.Discord
        self.MaxAttempts = options.MaxAttempts or 5
        self.KeyName = options.KeyName or "NexusUI_Key"
        self.SaveKey = options.SaveKey ~= false
        
        -- Static keys (local validation)
        self.Keys = options.Keys or {}
        
        -- External API verification
        self.VerifyURL = options.VerifyURL
        self.Method = options.Method or "POST"
        self.Headers = options.Headers or {}
        self.BodyFormat = options.BodyFormat or {key = "{KEY}"}
        self.SuccessField = options.SuccessField or "success"
        self.SuccessValue = options.SuccessValue
        self.ErrorField = options.ErrorField or "message"
        self.Timeout = options.Timeout or 10
        
        -- GetKey URL flow
        self.GetKeyURL = options.GetKeyURL
        self.CheckpointURL = options.CheckpointURL
        
        -- HWID options
        self.HWIDLocked = options.HWIDLocked or false
        self.HWID = self.HWIDLocked and GetHWID() or nil
        
        -- Custom validation callback
        self.ValidateCallback = options.ValidateCallback
        
        -- Callbacks
        self.OnSuccess = options.OnSuccess or function() end
        self.OnFailure = options.OnFailure or function() end
        
        -- State
        self.Validated = false
        self.Attempts = 0
        
        -- Check for saved key first (instant bypass)
        if self.SaveKey then
            local savedKey = self:GetSavedKey()
            if savedKey then
                self:ValidateKeyAsync(savedKey, function(valid, message)
                    if valid then
                        self.Validated = true
                        task.defer(function()
                            self.OnSuccess()
                        end)
                    else
                        -- Key expired or invalid, show UI
                        self:CreateUI()
                    end
                end)
                
                if self.Validated then
                    return self
                end
            end
        end
        
        -- No valid saved key, show UI
        self:CreateUI()
        
        return self
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- KEY VALIDATION
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function KeySystem:ValidateKey(key)
        if not key or key == "" then
            return false, "Key cannot be empty"
        end
        
        -- 1. Custom callback validation
        if self.ValidateCallback then
            local result, message = self.ValidateCallback(key, self.HWID)
            return result, message or (result and "Valid" or "Invalid key")
        end
        
        -- 2. Static key list validation
        if #self.Keys > 0 then
            for _, validKey in ipairs(self.Keys) do
                if key == validKey then
                    return true, "Key validated!"
                end
            end
            return false, "Invalid key"
        end
        
        return false, "No validation method configured"
    end
    
    function KeySystem:ValidateKeyAsync(key, callback)
        if not key or key == "" then
            callback(false, "Key cannot be empty")
            return
        end
        
        -- 1. Custom callback
        if self.ValidateCallback then
            local result, message = self.ValidateCallback(key, self.HWID)
            callback(result, message or (result and "Valid" or "Invalid key"))
            return
        end
        
        -- 2. External API verification
        if self.VerifyURL then
            self:VerifyWithAPI(key, callback)
            return
        end
        
        -- 3. Static key list
        if #self.Keys > 0 then
            for _, validKey in ipairs(self.Keys) do
                if key == validKey then
                    callback(true, "Key validated!")
                    return
                end
            end
            callback(false, "Invalid key")
            return
        end
        
        callback(false, "No validation method configured")
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- EXTERNAL API VERIFICATION
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function KeySystem:VerifyWithAPI(key, callback)
        if not request and not syn and not http_request then
            callback(false, "HTTP requests not supported")
            return
        end
        
        local httpRequest = request or syn.request or http_request
        
        -- Build request body
        local body = {}
        for field, value in pairs(self.BodyFormat) do
            local processed = tostring(value)
            processed = processed:gsub("{KEY}", key)
            processed = processed:gsub("{HWID}", self.HWID or "")
            processed = processed:gsub("{USERID}", tostring(game:GetService("Players").LocalPlayer.UserId))
            processed = processed:gsub("{USERNAME}", game:GetService("Players").LocalPlayer.Name)
            body[field] = processed
        end
        
        -- Build URL with GET params if needed
        local url = self.VerifyURL
        if self.Method == "GET" then
            local params = {}
            for k, v in pairs(body) do
                table.insert(params, k .. "=" .. HttpService:UrlEncode(tostring(v)))
            end
            if #params > 0 then
                url = url .. "?" .. table.concat(params, "&")
            end
        end
        
        -- Make request
        task.spawn(function()
            local success, response = pcall(function()
                return httpRequest({
                    Url = url,
                    Method = self.Method,
                    Headers = self.Method == "POST" and 
                        table.merge({["Content-Type"] = "application/json"}, self.Headers) or 
                        self.Headers,
                    Body = self.Method == "POST" and HttpService:JSONEncode(body) or nil
                })
            end)
            
            if not success then
                callback(false, "Request failed: " .. tostring(response))
                return
            end
            
            if response.StatusCode ~= 200 then
                callback(false, "Server error: " .. tostring(response.StatusCode))
                return
            end
            
            -- Parse response
            local parseSuccess, data = pcall(function()
                return HttpService:JSONDecode(response.Body)
            end)
            
            if not parseSuccess then
                callback(false, "Invalid server response")
                return
            end
            
            -- Check success field
            local isValid = false
            if self.SuccessValue ~= nil then
                isValid = data[self.SuccessField] == self.SuccessValue
            else
                isValid = data[self.SuccessField] == true or data[self.SuccessField] == "true"
            end
            
            if isValid then
                callback(true, data[self.ErrorField] or "Key validated!")
            else
                callback(false, data[self.ErrorField] or "Invalid key")
            end
        end)
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- UI CREATION
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function KeySystem:CreateUI()
        -- Create ScreenGui
        self.ScreenGui = Creator.New("ScreenGui", {
            Name = "NexusUI_KeySystem",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Global,
            DisplayOrder = 50,
            IgnoreGuiInset = true
        })
        
        -- Parent to CoreGui
        local success = pcall(function()
            if gethui then
                self.ScreenGui.Parent = gethui()
            elseif syn and syn.protect_gui then
                syn.protect_gui(self.ScreenGui)
                self.ScreenGui.Parent = game:GetService("CoreGui")
            else
                self.ScreenGui.Parent = game:GetService("CoreGui")
            end
        end)
        
        if not success then
            self.ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        end
        
        -- Background
        self.Background = Creator.New("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(10, 10, 15),
            Parent = self.ScreenGui
        })
        
        -- Background Image
        if self.BackgroundImage then
            Creator.New("ImageLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Image = self.BackgroundImage,
                ImageTransparency = 0.75,
                ScaleType = Enum.ScaleType.Crop,
                Parent = self.Background
            })
        end
        
        -- Gradient overlay
        Creator.New("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.4,
            Parent = self.Background
        }, {
            Creator.New("UIGradient", {
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 20))
                })
            })
        })
        
        -- Main Container
        self.Container = Creator.New("Frame", {
            Size = UDim2.fromOffset(400, 480),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(22, 22, 28),
            BackgroundTransparency = 0.05,
            Parent = self.Background
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 16)}),
            Creator.New("UIStroke", {
                Thickness = 2,
                Color = Color3.fromRGB(60, 120, 200),
                Transparency = 0.4
            })
        })
        
        -- Shadow
        Creator.New("ImageLabel", {
            Size = UDim2.new(1, 70, 1, 70),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Image = "rbxassetid://5028857472",
            ImageColor3 = Color3.new(0, 0, 0),
            ImageTransparency = 0.35,
            BackgroundTransparency = 1,
            ZIndex = -1,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(24, 24, 276, 276),
            Parent = self.Container
        })
        
        -- Logo
        local logoY = 40
        if self.Logo then
            Creator.New("ImageLabel", {
                Size = UDim2.fromOffset(80, 80),
                Position = UDim2.new(0.5, 0, 0, logoY),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                Image = self.Logo,
                Parent = self.Container
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(0, 16)})
            })
            logoY = logoY + 95
        else
            Creator.New("ImageLabel", {
                Size = UDim2.fromOffset(72, 72),
                Position = UDim2.new(0.5, 0, 0, logoY),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                Image = "rbxassetid://7733700996",
                ImageColor3 = Color3.fromRGB(60, 140, 220),
                Parent = self.Container
            })
            logoY = logoY + 88
        end
        
        -- Title
        Creator.New("TextLabel", {
            Size = UDim2.new(1, -40, 0, 30),
            Position = UDim2.new(0.5, 0, 0, logoY),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Text = self.Title,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
            TextSize = 24,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Parent = self.Container
        })
        
        -- Subtitle
        Creator.New("TextLabel", {
            Size = UDim2.new(1, -40, 0, 22),
            Position = UDim2.new(0.5, 0, 0, logoY + 35),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Text = self.Subtitle,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 14,
            TextColor3 = Color3.fromRGB(160, 165, 180),
            Parent = self.Container
        })
        
        -- HWID Label (if HWID locked)
        if self.HWIDLocked and self.HWID then
            Creator.New("TextLabel", {
                Size = UDim2.new(1, -40, 0, 18),
                Position = UDim2.new(0.5, 0, 0, logoY + 60),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                Text = "HWID: " .. self.HWID:sub(1, 20) .. "...",
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                TextSize = 11,
                TextColor3 = Color3.fromRGB(100, 105, 120),
                Parent = self.Container
            })
        end
        
        -- Key Input
        local inputY = logoY + (self.HWIDLocked and 95 or 80)
        self.InputFrame = Creator.New("Frame", {
            Size = UDim2.new(1, -48, 0, 50),
            Position = UDim2.new(0.5, 0, 0, inputY),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = Color3.fromRGB(18, 18, 24),
            BackgroundTransparency = 0.3,
            Parent = self.Container
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 12)}),
            Creator.New("UIStroke", {
                Thickness = 1.5,
                Color = Color3.fromRGB(50, 55, 70),
                Transparency = 0.3
            })
        })
        
        self.KeyInput = Creator.New("TextBox", {
            Size = UDim2.new(1, -24, 1, 0),
            Position = UDim2.fromOffset(12, 0),
            BackgroundTransparency = 1,
            Text = "",
            PlaceholderText = "Enter your key here...",
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 15,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            PlaceholderColor3 = Color3.fromRGB(100, 105, 120),
            TextXAlignment = Enum.TextXAlignment.Center,
            ClearTextOnFocus = false,
            Parent = self.InputFrame
        })
        
        -- Status Label
        self.StatusLabel = Creator.New("TextLabel", {
            Size = UDim2.new(1, -40, 0, 20),
            Position = UDim2.new(0.5, 0, 0, inputY + 58),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Text = "",
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 13,
            TextColor3 = Color3.fromRGB(255, 100, 100),
            Parent = self.Container
        })
        
        -- Validate Button
        local buttonY = inputY + 88
        self.ValidateButton = Creator.New("TextButton", {
            Size = UDim2.new(1, -48, 0, 48),
            Position = UDim2.new(0.5, 0, 0, buttonY),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = Color3.fromRGB(60, 120, 200),
            Text = "🔓 Validate Key",
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
            TextSize = 16,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Parent = self.Container
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 12)})
        })
        
        -- Validate button events
        self.ValidateButton.MouseButton1Click:Connect(function()
            self:TryValidate()
        end)
        
        self.KeyInput.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                self:TryValidate()
            end
        end)
        
        -- Get Key Button
        if self.GetKeyURL then
            local getKeyY = buttonY + 58
            self.GetKeyButton = Creator.New("TextButton", {
                Size = UDim2.new(1, -48, 0, 42),
                Position = UDim2.new(0.5, 0, 0, getKeyY),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = Color3.fromRGB(35, 38, 48),
                Text = "🔑 Get Key",
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
                TextSize = 14,
                TextColor3 = Color3.fromRGB(220, 220, 230),
                Parent = self.Container
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(0, 10)})
            })
            
            self.GetKeyButton.MouseButton1Click:Connect(function()
                if setclipboard then
                    setclipboard(self.GetKeyURL)
                    self.StatusLabel.Text = "📋 Link copied to clipboard!"
                    self.StatusLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
                end
            end)
            buttonY = getKeyY
        end
        
        -- Discord Button
        if self.Discord then
            local discordY = buttonY + 52
            self.DiscordButton = Creator.New("TextButton", {
                Size = UDim2.fromOffset(160, 38),
                Position = UDim2.new(0.5, 0, 0, discordY),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = Color3.fromRGB(88, 101, 242),
                Text = "💬 Discord",
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
                TextSize = 13,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                Parent = self.Container
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(0, 10)})
            })
            
            self.DiscordButton.MouseButton1Click:Connect(function()
                if setclipboard then
                    setclipboard(self.Discord)
                    self.StatusLabel.Text = "💬 Discord link copied!"
                    self.StatusLabel.TextColor3 = Color3.fromRGB(88, 101, 242)
                end
            end)
        end
        
        -- Attempts counter
        self.AttemptsLabel = Creator.New("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18),
            Position = UDim2.new(0.5, 0, 1, -28),
            AnchorPoint = Vector2.new(0.5, 1),
            BackgroundTransparency = 1,
            Text = string.format("Attempts: 0/%d", self.MaxAttempts),
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 11,
            TextColor3 = Color3.fromRGB(80, 85, 100),
            Parent = self.Container
        })
        
        -- Open animation
        self.Container.Size = UDim2.fromOffset(0, 0)
        Creator.Tween(self.Container, {Size = UDim2.fromOffset(400, 480)}, 0.4, Enum.EasingStyle.Back)
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- VALIDATION PROCESS
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function KeySystem:TryValidate()
        local key = self.KeyInput.Text
        
        self.Attempts = self.Attempts + 1
        self.AttemptsLabel.Text = string.format("Attempts: %d/%d", self.Attempts, self.MaxAttempts)
        
        -- Show loading state
        self.ValidateButton.Text = "⏳ Validating..."
        
        self:ValidateKeyAsync(key, function(valid, message)
            if valid then
                self:OnKeyValid(key, message)
            else
                self:OnKeyInvalid(message)
            end
        end)
    end
    
    function KeySystem:OnKeyValid(key, message)
        self.Validated = true
        self.StatusLabel.Text = "✅ " .. (message or "Key validated!")
        self.StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        self.ValidateButton.Text = "✅ Success!"
        self.ValidateButton.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
        
        -- Save key
        if self.SaveKey then
            self:SaveKeyData(key)
        end
        
        -- Animate out
        task.delay(1, function()
            Creator.Tween(self.Container, {
                Size = UDim2.fromOffset(0, 0),
                BackgroundTransparency = 1
            }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            
            Creator.Tween(self.Background, {BackgroundTransparency = 1}, 0.3)
            
            task.delay(0.4, function()
                if self.ScreenGui then
                    self.ScreenGui:Destroy()
                end
                self.OnSuccess()
            end)
        end)
    end
    
    function KeySystem:OnKeyInvalid(message)
        if self.Attempts >= self.MaxAttempts then
            self.StatusLabel.Text = "❌ Max attempts reached!"
            self.ValidateButton.Text = "🚫 Access Denied"
            self.ValidateButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
            self.KeyInput.TextEditable = false
            
            self.OnFailure(self.Attempts)
        else
            self.StatusLabel.Text = "❌ " .. (message or "Invalid key")
            self.StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            self.ValidateButton.Text = "🔓 Validate Key"
            
            -- Shake animation
            self:ShakeInput()
        end
    end
    
    function KeySystem:ShakeInput()
        local original = self.InputFrame.Position
        for i = 1, 8 do
            local offset = (i % 2 == 0) and 10 or -10
            offset = offset * (1 - (i / 8))
            Creator.Tween(self.InputFrame, {
                Position = original + UDim2.fromOffset(offset, 0)
            }, 0.04)
            task.wait(0.04)
        end
        Creator.Tween(self.InputFrame, {Position = original}, 0.04)
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- KEY PERSISTENCE
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function KeySystem:GetSavedKey()
        if not readfile or not isfile then return nil end
        
        local success, content = pcall(function()
            local path = "NexusUI/" .. self.KeyName .. ".key"
            if isfile(path) then
                return readfile(path)
            end
            return nil
        end)
        
        return success and content or nil
    end
    
    function KeySystem:SaveKeyData(key)
        if not writefile then return end
        
        pcall(function()
            if not isfolder("NexusUI") then
                makefolder("NexusUI")
            end
            writefile("NexusUI/" .. self.KeyName .. ".key", key)
        end)
    end
    
    function KeySystem:ClearSavedKey()
        if not delfile or not isfile then return end
        
        local path = "NexusUI/" .. self.KeyName .. ".key"
        if isfile(path) then
            delfile(path)
        end
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- PUBLIC API
    -- ════════════════════════════════════════════════════════════════════════════════
    
    function KeySystem:OnValidated(callback)
        self.OnSuccess = callback
        
        if self.Validated then
            callback()
        end
        
        return self
    end
    
    function KeySystem:OnFailed(callback)
        self.OnFailure = callback
        return self
    end
    
    function KeySystem:IsValidated()
        return self.Validated
    end
    
    function KeySystem:GetHWID()
        return self.HWID or GetHWID()
    end
    
    return KeySystem
    
end

-- Module: Components/Popup
_modules["Components/Popup"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                       GUI Framework                           ║
        ║                          By Ryu                               ║
        ║                       POPUP v1.0                              ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        Usage:
            NexusUI:Popup({
                Type = "Confirm",  -- Confirm, Alert, Input, Custom
                Title = "Important",
                Content = "Are you sure?",
                Buttons = {"Yes", "No"},
                Icon = Icons.Warning,
                Callback = function(result) end
            })
    ]]
    
    local Popup = {}
    Popup.__index = Popup
    
    local Creator
    local Flipper
    local Services
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Flipper = _require("Packages/Flipper")
        Services = _require("Core/Services")
    end
    
    -- ════════════════════════════════════════════════════════════════════════════════
    -- POPUP TYPES
    -- ════════════════════════════════════════════════════════════════════════════════
    
    local PopupTypes = {
        Confirm = {
            Icon = "rbxassetid://7743879203",
            IconColor = Color3.fromRGB(255, 200, 50),
            DefaultButtons = {"Confirm", "Cancel"}
        },
        Alert = {
            Icon = "rbxassetid://7743878326",
            IconColor = Color3.fromRGB(255, 100, 100),
            DefaultButtons = {"OK"}
        },
        Success = {
            Icon = "rbxassetid://10709790644",
            IconColor = Color3.fromRGB(100, 255, 100),
            DefaultButtons = {"OK"}
        },
        Info = {
            Icon = "rbxassetid://7733687252",
            IconColor = Color3.fromRGB(100, 150, 255),
            DefaultButtons = {"OK"}
        },
        Input = {
            Icon = "rbxassetid://7734053098",
            IconColor = Color3.fromRGB(150, 150, 255),
            DefaultButtons = {"Submit", "Cancel"},
            HasInput = true
        },
        Custom = {
            Icon = nil,
            IconColor = nil,
            DefaultButtons = {"OK"}
        }
    }
    
    function Popup.new(options)
        InitDependencies()
        
        options = options or {}
        local Type = options.Type or "Alert"
        local Title = options.Title or "Popup"
        local Content = options.Content or ""
        local Buttons = options.Buttons or PopupTypes[Type].DefaultButtons
        local Icon = options.Icon or PopupTypes[Type].Icon
        local IconColor = options.IconColor or PopupTypes[Type].IconColor
        local Callback = options.Callback or function() end
        local Placeholder = options.Placeholder or "Enter here..."
        local DefaultValue = options.DefaultValue or ""
        local Animation = options.Animation or "Scale"  -- Scale, Fade, Slide
        local Closeable = options.Closeable ~= false
        
        local self = setmetatable({}, Popup)
        self.Callback = Callback
        self.Result = nil
        self.InputValue = DefaultValue
        self.Closed = false
        
        -- Create ScreenGui
        self.ScreenGui = Creator.New("ScreenGui", {
            Name = "NexusUI_Popup_" .. Services.HttpService:GenerateGUID(false),
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Global,
            DisplayOrder = 100
        })
        
        -- Parent to CoreGui
        local success = pcall(function()
            if gethui then
                self.ScreenGui.Parent = gethui()
            elseif syn and syn.protect_gui then
                syn.protect_gui(self.ScreenGui)
                self.ScreenGui.Parent = game:GetService("CoreGui")
            else
                self.ScreenGui.Parent = game:GetService("CoreGui")
            end
        end)
        
        if not success then
            self.ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        end
        
        -- Backdrop (darkens screen)
        self.Backdrop = Creator.New("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            Parent = self.ScreenGui
        })
        
        -- Popup container
        local popupWidth = 340
        local hasInput = PopupTypes[Type].HasInput
        local popupHeight = hasInput and 220 or 180
        
        self.Container = Creator.New("Frame", {
            Size = UDim2.fromOffset(popupWidth, popupHeight),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 0.05,
            Parent = self.ScreenGui,
            ThemeTag = {BackgroundColor3 = "Dialog"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 14)}),
            Creator.New("UIStroke", {
                Thickness = 1.5,
                Transparency = 0.5,
                ThemeTag = {Color = "Accent"}
            })
        })
        
        -- Shadow
        Creator.New("ImageLabel", {
            Size = UDim2.new(1, 40, 1, 40),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Image = "rbxassetid://5028857472",
            ImageColor3 = Color3.new(0, 0, 0),
            ImageTransparency = 0.5,
            BackgroundTransparency = 1,
            ZIndex = -1,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(24, 24, 276, 276),
            Parent = self.Container
        })
        
        -- Icon
        if Icon then
            self.IconLabel = Creator.New("ImageLabel", {
                Size = UDim2.fromOffset(48, 48),
                Position = UDim2.new(0.5, 0, 0, 24),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                Image = Icon,
                ImageColor3 = IconColor or Color3.new(1, 1, 1),
                Parent = self.Container
            })
        end
        
        -- Title
        local titleY = Icon and 80 or 20
        self.TitleLabel = Creator.New("TextLabel", {
            Size = UDim2.new(1, -24, 0, 24),
            Position = UDim2.new(0.5, 0, 0, titleY),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Text = Title,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
            TextSize = 18,
            Parent = self.Container,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Content
        self.ContentLabel = Creator.New("TextLabel", {
            Size = UDim2.new(1, -32, 0, 40),
            Position = UDim2.new(0.5, 0, 0, titleY + 28),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Text = Content,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 14,
            TextWrapped = true,
            TextTransparency = 0.3,
            Parent = self.Container,
            ThemeTag = {TextColor3 = "SubText"}
        })
        
        -- Input field (if Input type)
        if hasInput then
            self.InputFrame = Creator.New("Frame", {
                Size = UDim2.new(1, -32, 0, 38),
                Position = UDim2.new(0.5, 0, 0, titleY + 75),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 0.85,
                Parent = self.Container,
                ThemeTag = {BackgroundColor3 = "Input"}
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
                Creator.New("UIStroke", {
                    Transparency = 0.7,
                    ThemeTag = {Color = "InputStroke"}
                })
            })
            
            self.InputBox = Creator.New("TextBox", {
                Size = UDim2.new(1, -16, 1, 0),
                Position = UDim2.fromOffset(8, 0),
                BackgroundTransparency = 1,
                Text = DefaultValue,
                PlaceholderText = Placeholder,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                Parent = self.InputFrame,
                ThemeTag = {TextColor3 = "Text", PlaceholderColor3 = "PlaceholderColor"}
            })
            
            Creator.AddSignal(self.InputBox:GetPropertyChangedSignal("Text"), function()
                self.InputValue = self.InputBox.Text
            end)
        end
        
        -- Buttons container
        local buttonY = hasInput and (popupHeight - 55) or (popupHeight - 50)
        self.ButtonContainer = Creator.New("Frame", {
            Size = UDim2.new(1, -24, 0, 38),
            Position = UDim2.new(0.5, 0, 0, buttonY),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Parent = self.Container
        }, {
            Creator.New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 10),
                HorizontalAlignment = Enum.HorizontalAlignment.Center
            })
        })
        
        -- Create buttons
        local buttonWidth = (#Buttons == 1) and 120 or (popupWidth - 44) / #Buttons - 5
        
        for i, buttonText in ipairs(Buttons) do
            local isPrimary = i == 1
            
            local button = Creator.New("TextButton", {
                Size = UDim2.fromOffset(buttonWidth, 36),
                BackgroundTransparency = isPrimary and 0 or 0.85,
                Text = buttonText,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
                TextSize = 13,
                Parent = self.ButtonContainer,
                ThemeTag = {
                    BackgroundColor3 = isPrimary and "Accent" or "DialogButton",
                    TextColor3 = isPrimary and "Background" or "Text"
                }
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)})
            })
            
            -- Hover effect
            local hoverMotor, setHover = Creator.SpringMotor(isPrimary and 0 or 0.85, button, "BackgroundTransparency")
            
            Creator.AddSignal(button.MouseEnter, function()
                setHover(isPrimary and 0.1 or 0.75)
            end)
            
            Creator.AddSignal(button.MouseLeave, function()
                setHover(isPrimary and 0 or 0.85)
            end)
            
            Creator.AddSignal(button.MouseButton1Click, function()
                self.Result = buttonText
                if hasInput then
                    self.Callback(buttonText, self.InputValue)
                else
                    self.Callback(buttonText)
                end
                self:Close()
            end)
        end
        
        -- Close button (X)
        if Closeable then
            local closeBtn = Creator.New("TextButton", {
                Size = UDim2.fromOffset(28, 28),
                Position = UDim2.new(1, -8, 0, 8),
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Text = "✕",
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
                TextSize = 16,
                Parent = self.Container,
                ThemeTag = {TextColor3 = "SubText"}
            })
            
            Creator.AddSignal(closeBtn.MouseButton1Click, function()
                self.Result = nil
                self.Callback(nil)
                self:Close()
            end)
        end
        
        -- Click backdrop to close
        if Closeable then
            Creator.AddSignal(self.Backdrop.MouseButton1Click, function()
                self.Result = nil
                self.Callback(nil)
                self:Close()
            end)
        end
        
        -- Open animation
        self:PlayOpenAnimation(Animation)
        
        return self
    end
    
    function Popup:PlayOpenAnimation(animationType)
        local bd = self.Backdrop
        local container = self.Container
        
        -- Fade in backdrop
        Creator.Tween(bd, {BackgroundTransparency = 0.5}, 0.2)
        
        if animationType == "Scale" then
            container.Size = UDim2.fromOffset(0, 0)
            Creator.Tween(container, {Size = UDim2.fromOffset(340, self.Container.AbsoluteSize.Y or 180)}, 0.25, Enum.EasingStyle.Back)
        elseif animationType == "Fade" then
            container.BackgroundTransparency = 1
            for _, child in ipairs(container:GetDescendants()) do
                if child:IsA("GuiObject") then
                    child.Visible = false
                end
            end
            Creator.Tween(container, {BackgroundTransparency = 0.05}, 0.2)
            task.delay(0.1, function()
                for _, child in ipairs(container:GetDescendants()) do
                    if child:IsA("GuiObject") then
                        child.Visible = true
                    end
                end
            end)
        elseif animationType == "Slide" then
            container.Position = UDim2.new(0.5, 0, -0.5, 0)
            Creator.Tween(container, {Position = UDim2.fromScale(0.5, 0.5)}, 0.3, Enum.EasingStyle.Back)
        end
    end
    
    function Popup:Close()
        if self.Closed then return end
        self.Closed = true
        
        -- Close animation
        Creator.Tween(self.Backdrop, {BackgroundTransparency = 1}, 0.15)
        Creator.Tween(self.Container, {
            Size = UDim2.fromOffset(0, 0),
            BackgroundTransparency = 1
        }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        
        task.delay(0.25, function()
            if self.ScreenGui then
                self.ScreenGui:Destroy()
            end
        end)
    end
    
    function Popup:Await()
        repeat task.wait() until self.Closed
        return self.Result, self.InputValue
    end
    
    return Popup
    
end

-- Module: Elements/Accordion
_modules["Elements/Accordion"] = function()
    --[[
        NexusUI Accordion Element
        Collapsible sections
    ]]
    
    local Accordion = {}
    Accordion.__index = Accordion
    
    local Creator, Flipper
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Flipper = _require("Packages/Flipper")
    end
    
    function Accordion.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Section"
        local Content = options.Content or ""
        local Icon = options.Icon
        local DefaultOpen = options.Open or false
        local OnToggle = options.OnToggle or function() end
        
        local self = setmetatable({}, Accordion)
        self.Open = DefaultOpen
        
        local headerHeight = 40
        local contentHeight = 0
        
        -- Arrow icon
        self.Arrow = Creator.New("TextLabel", {
            Size = UDim2.fromOffset(16, 16),
            Position = UDim2.new(1, -12, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            Text = DefaultOpen and "▼" or "▶",
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 10,
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "SubText"}
        })
        
        -- Header
        self.Header = Creator.New("TextButton", {
            Size = UDim2.new(1, 0, 0, headerHeight),
            Text = "",
            BackgroundTransparency = 0.92,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            -- Icon
            Icon and Creator.New("ImageLabel", {
                Size = UDim2.fromOffset(18, 18),
                Position = UDim2.new(0, 12, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                Image = type(Icon) == "number" and ("rbxassetid://" .. Icon) or Icon,
                BackgroundTransparency = 1,
                ThemeTag = {ImageColor3 = "Text"}
            }) or nil,
            -- Title
            Creator.New("TextLabel", {
                Size = UDim2.new(1, -60, 1, 0),
                Position = UDim2.fromOffset(Icon and 38 or 12, 0),
                Text = Title,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "Text"}
            }),
            self.Arrow
        })
        
        -- Content container
        self.ContentContainer = Creator.New("Frame", {
            Size = UDim2.new(1, -24, 0, 0),
            Position = UDim2.fromOffset(12, headerHeight),
            BackgroundTransparency = 1,
            ClipsDescendants = true
        })
        
        -- Content label (if string content provided)
        if type(Content) == "string" and Content ~= "" then
            self.ContentLabel = Creator.New("TextLabel", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Text = Content,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                BackgroundTransparency = 1,
                Parent = self.ContentContainer,
                ThemeTag = {TextColor3 = "Text"}
            })
        end
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, headerHeight),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Parent = parent
        }, {
            self.Header,
            self.ContentContainer
        })
        
        -- Animation
        self.HeightMotor = Flipper.SingleMotor.new(DefaultOpen and 1 or 0)
        self.HeightMotor:onStep(function(value)
            local maxHeight = self:GetContentHeight()
            self.Frame.Size = UDim2.new(1, 0, 0, headerHeight + maxHeight * value)
            self.ContentContainer.Size = UDim2.new(1, -24, 0, maxHeight * value)
        end)
        
        if DefaultOpen then
            task.defer(function()
                local h = self:GetContentHeight()
                self.Frame.Size = UDim2.new(1, 0, 0, headerHeight + h)
                self.ContentContainer.Size = UDim2.new(1, -24, 0, h)
            end)
        end
        
        -- Click handler
        Creator.AddSignal(self.Header.MouseButton1Click, function()
            self:Toggle()
        end)
        
        self.OnToggle = OnToggle
        self.Root = self.Frame
        return self
    end
    
    function Accordion:GetContentHeight()
        local height = 0
        for _, child in ipairs(self.ContentContainer:GetChildren()) do
            if child:IsA("GuiObject") then
                height = height + child.AbsoluteSize.Y
            end
        end
        return math.max(height + 12, 40)
    end
    
    function Accordion:Toggle()
        self.Open = not self.Open
        self.Arrow.Text = self.Open and "▼" or "▶"
        self.HeightMotor:setGoal(Flipper.Spring.new(self.Open and 1 or 0, {frequency = 5}))
        self.OnToggle(self.Open)
    end
    
    function Accordion:SetOpen(open)
        if self.Open ~= open then
            self:Toggle()
        end
    end
    
    -- Add custom content to the accordion
    function Accordion:GetContainer()
        return self.ContentContainer
    end
    
    return Accordion
    
end

-- Module: Elements/Alert
_modules["Elements/Alert"] = function()
    --[[
        NexusUI Alert Element
        Styled alert/notice box
    ]]
    
    local Alert = {}
    Alert.__index = Alert
    
    local Creator
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
    end
    
    function Alert.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Type = options.Type or "Info" -- Info, Success, Warning, Error
        local Title = options.Title
        local Content = options.Content or ""
        local Closable = options.Closable or false
        local OnClose = options.OnClose or function() end
        
        local self = setmetatable({}, Alert)
        
        local colors = {
            Info = {bg = Color3.fromRGB(50, 80, 150), icon = "ℹ"},
            Success = {bg = Color3.fromRGB(40, 120, 80), icon = "✓"},
            Warning = {bg = Color3.fromRGB(180, 120, 30), icon = "⚠"},
            Error = {bg = Color3.fromRGB(150, 50, 50), icon = "✕"}
        }
        
        local style = colors[Type] or colors.Info
        local hasTitle = Title ~= nil
        
        -- Icon
        self.IconLabel = Creator.New("TextLabel", {
            Size = UDim2.fromOffset(28, 28),
            Position = UDim2.new(0, 12, 0, hasTitle and 16 or 10),
            Text = style.icon,
            TextSize = 18,
            TextColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 1
        })
        
        -- Title
        if hasTitle then
            self.TitleLabel = Creator.New("TextLabel", {
                Size = UDim2.new(1, -60, 0, 20),
                Position = UDim2.fromOffset(48, 10),
                Text = Title,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
                TextSize = 14,
                TextColor3 = Color3.new(1, 1, 1),
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1
            })
        end
        
        -- Content
        self.ContentLabel = Creator.New("TextLabel", {
            Size = UDim2.new(1, -60, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.fromOffset(48, hasTitle and 32 or 10),
            Text = Content,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 13,
            TextColor3 = Color3.fromRGB(230, 230, 230),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            BackgroundTransparency = 1
        })
        
        -- Close button
        if Closable then
            self.CloseBtn = Creator.New("TextButton", {
                Size = UDim2.fromOffset(24, 24),
                Position = UDim2.new(1, -8, 0, 8),
                AnchorPoint = Vector2.new(1, 0),
                Text = "✕",
                TextSize = 14,
                TextColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 1
            })
            
            Creator.AddSignal(self.CloseBtn.MouseButton1Click, function()
                OnClose()
                self.Frame:Destroy()
            end)
        end
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, hasTitle and 60 or 48),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = style.bg,
            Parent = parent
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIPadding", {PaddingBottom = UDim.new(0, 12)}),
            self.IconLabel,
            hasTitle and self.TitleLabel or nil,
            self.ContentLabel,
            Closable and self.CloseBtn or nil
        })
        
        self.Root = self.Frame
        return self
    end
    
    function Alert:SetContent(content)
        self.ContentLabel.Text = content
    end
    
    return Alert
    
end

-- Module: Elements/Avatar
_modules["Elements/Avatar"] = function()
    --[[
        NexusUI Avatar Element
        Display user avatar or custom image
    ]]
    
    local Avatar = {}
    Avatar.__index = Avatar
    
    local Creator, ImageLoader
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        ImageLoader = _require("Utils/ImageLoader")
    end
    
    function Avatar.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local UserId = options.UserId
        local Image = options.Image -- Raw URL or rbxassetid
        local Size = options.Size or 50
        local Rounded = options.Rounded ~= false
        local BorderColor = options.BorderColor
        local Status = options.Status -- "online", "offline", "away", "busy"
        local Initials = options.Initials -- Fallback text if no image
        local Callback = options.Callback
        
        local self = setmetatable({}, Avatar)
        
        -- Avatar container
        self.Container = Creator.New("Frame", {
            Size = UDim2.fromOffset(Size, Size),
            BackgroundTransparency = 1,
            Parent = parent
        })
        
        -- Avatar image
        self.ImageLabel = Creator.New("ImageLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(60, 60, 80),
            Parent = self.Container,
            ThemeTag = not UserId and not Image and {BackgroundColor3 = "Accent"} or nil
        }, {
            Creator.New("UICorner", {CornerRadius = Rounded and UDim.new(1, 0) or UDim.new(0, 8)})
        })
        
        -- Set image
        if UserId then
            -- Roblox avatar
            local thumbType = Enum.ThumbnailType.HeadShot
            local thumbSize = Enum.ThumbnailSize.Size100x100
            
            task.spawn(function()
                local content = game:GetService("Players"):GetUserThumbnailAsync(UserId, thumbType, thumbSize)
                if content and self.ImageLabel.Parent then
                    self.ImageLabel.Image = content
                end
            end)
        elseif Image then
            -- Custom image (raw URL or rbxassetid)
            ImageLoader.SetImage(self.ImageLabel, Image)
        elseif Initials then
            -- Show initials
            Creator.New("TextLabel", {
                Size = UDim2.fromScale(1, 1),
                Text = Initials:sub(1, 2):upper(),
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
                TextSize = Size * 0.4,
                TextColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 1,
                Parent = self.ImageLabel
            })
        end
        
        -- Border
        if BorderColor then
            Creator.New("UIStroke", {
                Thickness = 2,
                Color = BorderColor,
                Parent = self.ImageLabel
            })
        end
        
        -- Status indicator
        if Status then
            local statusColors = {
                online = Color3.fromRGB(67, 181, 129),
                offline = Color3.fromRGB(116, 127, 141),
                away = Color3.fromRGB(250, 166, 26),
                busy = Color3.fromRGB(240, 71, 71)
            }
            
            self.StatusIndicator = Creator.New("Frame", {
                Size = UDim2.fromOffset(Size * 0.28, Size * 0.28),
                Position = UDim2.new(1, -Size * 0.1, 1, -Size * 0.1),
                AnchorPoint = Vector2.new(1, 1),
                BackgroundColor3 = statusColors[Status] or statusColors.offline,
                Parent = self.Container
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)}),
                Creator.New("UIStroke", {Thickness = 2, ThemeTag = {Color = "Background"}})
            })
        end
        
        -- Click handler
        if Callback then
            local clickBtn = Creator.New("TextButton", {
                Size = UDim2.fromScale(1, 1),
                Text = "",
                BackgroundTransparency = 1,
                Parent = self.Container
            })
            Creator.AddSignal(clickBtn.MouseButton1Click, Callback)
        end
        
        self.Root = self.Container
        self.Frame = self.Container
        return self
    end
    
    function Avatar:SetImage(image)
        ImageLoader.SetImage(self.ImageLabel, image)
    end
    
    function Avatar:SetStatus(status)
        if self.StatusIndicator then
            local statusColors = {
                online = Color3.fromRGB(67, 181, 129),
                offline = Color3.fromRGB(116, 127, 141),
                away = Color3.fromRGB(250, 166, 26),
                busy = Color3.fromRGB(240, 71, 71)
            }
            self.StatusIndicator.BackgroundColor3 = statusColors[status] or statusColors.offline
        end
    end
    
    return Avatar
    
end

-- Module: Elements/Badge
_modules["Elements/Badge"] = function()
    --[[
        NexusUI Badge Element
        Small badge/tag display
    ]]
    
    local Badge = {}
    Badge.__index = Badge
    
    local Creator
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
    end
    
    function Badge.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Text = options.Text or "Badge"
        local Color = options.Color or Color3.fromRGB(100, 150, 255)
        local TextColor = options.TextColor or Color3.new(1, 1, 1)
        local Size = options.Size or "Medium" -- Small, Medium, Large
        local Rounded = options.Rounded ~= false
        local Icon = options.Icon
        local Closable = options.Closable or false
        local OnClose = options.OnClose or function() end
        
        local self = setmetatable({}, Badge)
        
        local sizes = {
            Small = {height = 18, fontSize = 10, padding = 6},
            Medium = {height = 24, fontSize = 12, padding = 10},
            Large = {height = 32, fontSize = 14, padding = 14}
        }
        local s = sizes[Size] or sizes.Medium
        
        -- Badge frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(0, 0, 0, s.height),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Color,
            Parent = parent
        }, {
            Creator.New("UICorner", {CornerRadius = Rounded and UDim.new(1, 0) or UDim.new(0, 4)}),
            Creator.New("UIPadding", {
                PaddingLeft = UDim.new(0, s.padding),
                PaddingRight = UDim.new(0, s.padding)
            }),
            Creator.New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 4)
            })
        })
        
        -- Icon
        if Icon then
            self.IconLabel = Creator.New("ImageLabel", {
                Size = UDim2.fromOffset(s.fontSize, s.fontSize),
                Image = type(Icon) == "number" and ("rbxassetid://" .. Icon) or Icon,
                ImageColor3 = TextColor,
                BackgroundTransparency = 1,
                Parent = self.Frame
            })
        end
        
        -- Text
        self.TextLabel = Creator.New("TextLabel", {
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = Text,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            TextSize = s.fontSize,
            TextColor3 = TextColor,
            BackgroundTransparency = 1,
            Parent = self.Frame
        })
        
        -- Close button
        if Closable then
            self.CloseBtn = Creator.New("TextButton", {
                Size = UDim2.fromOffset(s.fontSize, s.fontSize),
                Text = "✕",
                TextSize = s.fontSize - 2,
                TextColor3 = TextColor,
                BackgroundTransparency = 1,
                Parent = self.Frame
            })
            
            Creator.AddSignal(self.CloseBtn.MouseButton1Click, function()
                OnClose()
                self.Frame:Destroy()
            end)
        end
        
        self.Root = self.Frame
        return self
    end
    
    function Badge:SetText(text)
        self.TextLabel.Text = text
    end
    
    function Badge:SetColor(color)
        self.Frame.BackgroundColor3 = color
    end
    
    return Badge
    
end

-- Module: Elements/Breadcrumb
_modules["Elements/Breadcrumb"] = function()
    --[[
        NexusUI Breadcrumb Element
        Navigation breadcrumbs
    ]]
    
    local Breadcrumb = {}
    Breadcrumb.__index = Breadcrumb
    
    local Creator
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
    end
    
    function Breadcrumb.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Items = options.Items or {} -- {"Home", "Settings", "Profile"}
        local Separator = options.Separator or "›"
        local Callback = options.Callback or function() end
        
        local self = setmetatable({}, Breadcrumb)
        self.Items = Items
        self.Callback = Callback
        
        -- Container
        self.Container = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            Parent = parent
        }, {
            Creator.New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 6)
            })
        })
        
        self.Root = self.Container
        self.Frame = self.Container
        self.Separator = Separator
        
        self:Render()
        
        return self
    end
    
    function Breadcrumb:Render()
        -- Clear existing
        for _, child in ipairs(self.Container:GetChildren()) do
            if not child:IsA("UIListLayout") then child:Destroy() end
        end
        
        for i, item in ipairs(self.Items) do
            local text = type(item) == "table" and item.Text or tostring(item)
            local isLast = i == #self.Items
            
            -- Breadcrumb item
            local itemBtn = Creator.New("TextButton", {
                Size = UDim2.new(0, 0, 0, 24),
                AutomaticSize = Enum.AutomaticSize.X,
                Text = text,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", isLast and Enum.FontWeight.Medium or Enum.FontWeight.Regular),
                TextSize = 13,
                BackgroundTransparency = 1,
                Parent = self.Container,
                ThemeTag = {TextColor3 = isLast and "Text" or "SubText"}
            }, {
                Creator.New("UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4)})
            })
            
            if not isLast then
                -- Hover effect
                Creator.AddSignal(itemBtn.MouseEnter, function()
                    Creator.Tween(itemBtn, {TextTransparency = 0}, 0.15)
                end)
                Creator.AddSignal(itemBtn.MouseLeave, function()
                    Creator.Tween(itemBtn, {TextTransparency = 0.4}, 0.15)
                end)
                itemBtn.TextTransparency = 0.4
                
                -- Click
                Creator.AddSignal(itemBtn.MouseButton1Click, function()
                    self.Callback(i, item)
                end)
                
                -- Separator
                Creator.New("TextLabel", {
                    Size = UDim2.new(0, 0, 0, 24),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Text = self.Separator,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                    TextSize = 13,
                    TextTransparency = 0.5,
                    BackgroundTransparency = 1,
                    Parent = self.Container,
                    ThemeTag = {TextColor3 = "SubText"}
                })
            end
        end
    end
    
    function Breadcrumb:SetItems(items)
        self.Items = items
        self:Render()
    end
    
    function Breadcrumb:Push(item)
        table.insert(self.Items, item)
        self:Render()
    end
    
    function Breadcrumb:Pop()
        table.remove(self.Items)
        self:Render()
    end
    
    return Breadcrumb
    
end

-- Module: Elements/Button
_modules["Elements/Button"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                   Button Component v2.15                      ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        Features:
        - Icon support (left/right positioning)
        - Variants: primary, secondary, outline, ghost, danger, success
        - Loading state with spinner animation
        - Ripple click effect
        - Disabled state
        - Size variants: small, medium, large
    ]]
    
    local Button = {}
    Button.__index = Button
    
    local Creator
    local Flipper
    local Icons
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Flipper = _require("Packages/Flipper")
        Icons = _require("Utils/Icons")
    end
    
    -- Variant configurations
    local Variants = {
        default = {
            background = "Element",
            backgroundTransparency = 0.89,
            text = "Text",
            stroke = "ElementBorder",
            strokeTransparency = 0.5,
            hoverTransparency = 0.85
        },
        primary = {
            background = "Accent",
            backgroundTransparency = 0,
            text = "Background",
            stroke = "Accent",
            strokeTransparency = 0.3,
            hoverTransparency = 0.1
        },
        secondary = {
            background = "SecondaryElementBackground",
            backgroundTransparency = 0.3,
            text = "Text",
            stroke = "SecondaryElementStroke",
            strokeTransparency = 0.5,
            hoverTransparency = 0.2
        },
        outline = {
            background = "Element",
            backgroundTransparency = 1,
            text = "Accent",
            stroke = "Accent",
            strokeTransparency = 0,
            hoverTransparency = 0.9
        },
        ghost = {
            background = "Element",
            backgroundTransparency = 1,
            text = "Text",
            stroke = "ElementBorder",
            strokeTransparency = 1,
            hoverTransparency = 0.9
        },
        danger = {
            background = "Element",
            backgroundTransparency = 0.2,
            text = "Text",
            stroke = "ElementBorder",
            strokeTransparency = 0.5,
            hoverTransparency = 0.1,
            customBackground = Color3.fromRGB(220, 53, 69)
        },
        success = {
            background = "Element",
            backgroundTransparency = 0.2,
            text = "Text",
            stroke = "ElementBorder",
            strokeTransparency = 0.5,
            hoverTransparency = 0.1,
            customBackground = Color3.fromRGB(40, 167, 69)
        }
    }
    
    -- Size configurations
    local Sizes = {
        small = { height = 28, fontSize = 12, iconSize = 14, padding = 8 },
        medium = { height = 36, fontSize = 14, iconSize = 16, padding = 12 },
        large = { height = 48, fontSize = 16, iconSize = 20, padding = 16 }
    }
    
    function Button.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Button"
        local Description = options.Description
        local Callback = options.Callback or function() end
        local Icon = options.Icon
        local IconPosition = options.IconPosition or "left" -- "left" or "right"
        local Variant = options.Variant or "default"
        local Size = options.Size or "medium"
        local Disabled = options.Disabled or false
        local Loading = options.Loading or false
        
        local self = setmetatable({}, Button)
        
        self.Callback = Callback
        self.Disabled = Disabled
        self.Loading = Loading
        
        -- Get variant and size config
        local variantConfig = Variants[Variant] or Variants.default
        local sizeConfig = Sizes[Size] or Sizes.medium
        
        local hasDescription = Description ~= nil
        local hasIcon = Icon ~= nil
        local height = hasDescription and (sizeConfig.height + 12) or sizeConfig.height
        
        -- Resolve icon to asset ID
        local iconAsset = nil
        if hasIcon then
            if type(Icon) == "string" then
                if Icon:match("^rbxassetid://") then
                    iconAsset = Icon
                else
                    iconAsset = Icons.Get(Icon) or Icons.Question
                end
            end
        end
        
        -- Calculate label position based on icon
        local labelXOffset = sizeConfig.padding
        if hasIcon and IconPosition == "left" then
            labelXOffset = labelXOffset + sizeConfig.iconSize + 6
        end
        
        -- Icon element (left position)
        if hasIcon and IconPosition == "left" then
            self.Icon = Creator.New("ImageLabel", {
                Image = iconAsset,
                Size = UDim2.fromOffset(sizeConfig.iconSize, sizeConfig.iconSize),
                Position = UDim2.new(0, sizeConfig.padding, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                ImageColor3 = variantConfig.text ~= "Background" and Color3.fromRGB(255, 255, 255) or nil,
                ThemeTag = variantConfig.text ~= "Background" and {ImageColor3 = variantConfig.text} or nil
            })
        end
        
        -- Icon element (right position)
        if hasIcon and IconPosition == "right" then
            self.Icon = Creator.New("ImageLabel", {
                Image = iconAsset,
                Size = UDim2.fromOffset(sizeConfig.iconSize, sizeConfig.iconSize),
                Position = UDim2.new(1, -sizeConfig.padding - sizeConfig.iconSize, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                ThemeTag = {ImageColor3 = variantConfig.text}
            })
        end
        
        -- Loading spinner
        self.Spinner = Creator.New("ImageLabel", {
            Image = "rbxassetid://7734020165",
            Size = UDim2.fromOffset(sizeConfig.iconSize, sizeConfig.iconSize),
            Position = UDim2.new(0, sizeConfig.padding, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Visible = Loading,
            ThemeTag = {ImageColor3 = variantConfig.text}
        })
        
        -- Label
        local labelWidth = hasIcon and (hasIcon and IconPosition == "right" and -sizeConfig.padding - sizeConfig.iconSize - 6 or -labelXOffset) or -sizeConfig.padding * 2
        self.Label = Creator.New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            Text = Loading and "Loading..." or Title,
            TextSize = sizeConfig.fontSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, labelWidth, 0, sizeConfig.fontSize),
            Position = hasDescription and UDim2.fromOffset(labelXOffset, 9) or UDim2.new(0, labelXOffset, 0.5, 0),
            AnchorPoint = hasDescription and Vector2.zero or Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            TextTransparency = Disabled and 0.5 or 0,
            ThemeTag = {TextColor3 = variantConfig.text}
        })
        
        -- Description
        if hasDescription then
            self.Description = Creator.New("TextLabel", {
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                Text = Description,
                TextSize = 12,
                TextTransparency = Disabled and 0.6 or 0.4,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -labelXOffset - sizeConfig.padding, 0, 12),
                Position = UDim2.fromOffset(labelXOffset, 27),
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "SubText"}
            })
        end
        
        -- Ripple container (for click effect)
        self.RippleContainer = Creator.New("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ClipsDescendants = true
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)})
        })
        
        -- Frame (button)
        local frameProps = {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = variantConfig.backgroundTransparency,
            Text = "",
            Parent = parent,
            AutoButtonColor = false,
            Active = not Disabled
        }
        
        -- Apply custom background color for danger/success variants
        if variantConfig.customBackground then
            frameProps.BackgroundColor3 = variantConfig.customBackground
        else
            frameProps.ThemeTag = {BackgroundColor3 = variantConfig.background}
        end
        
        local children = {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {
                Transparency = variantConfig.strokeTransparency,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                ThemeTag = {Color = variantConfig.stroke}
            }),
            self.RippleContainer,
            self.Label,
            hasDescription and self.Description or nil,
            hasIcon and self.Icon or nil,
            Loading and self.Spinner or nil
        }
        
        self.Frame = Creator.New("TextButton", frameProps, children)
        
        -- Animation motors
        self.HoverMotor, self.SetHover = Creator.SpringMotor(
            variantConfig.backgroundTransparency, 
            self.Frame, 
            "BackgroundTransparency"
        )
        
        -- Spinner rotation animation
        if Loading then
            self:StartSpinnerAnimation()
        end
        
        -- Hover effects (only if not disabled)
        if not Disabled then
            Creator.AddSignal(self.Frame.MouseEnter, function()
                if not self.Disabled and not self.Loading then
                    self.SetHover(variantConfig.hoverTransparency)
                end
            end)
            
            Creator.AddSignal(self.Frame.MouseLeave, function()
                self.SetHover(variantConfig.backgroundTransparency)
            end)
            
            Creator.AddSignal(self.Frame.MouseButton1Down, function()
                if not self.Disabled and not self.Loading then
                    self.SetHover(variantConfig.backgroundTransparency + 0.05)
                end
            end)
            
            Creator.AddSignal(self.Frame.MouseButton1Up, function()
                if not self.Disabled and not self.Loading then
                    self.SetHover(variantConfig.hoverTransparency)
                end
            end)
            
            Creator.AddSignal(self.Frame.MouseButton1Click, function()
                if not self.Disabled and not self.Loading then
                    self:CreateRipple()
                    self.Callback()
                end
            end)
        end
        
        self.Root = self.Frame
        self.VariantConfig = variantConfig
        self.SizeConfig = sizeConfig
        self.Title = Title
        
        return self
    end
    
    -- Create ripple effect on click
    function Button:CreateRipple()
        local ripple = Creator.New("Frame", {
            Size = UDim2.fromOffset(0, 0),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.7,
            Parent = self.RippleContainer
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
        })
        
        local maxSize = math.max(self.Frame.AbsoluteSize.X, self.Frame.AbsoluteSize.Y) * 2
        
        Creator.Tween(ripple, {
            Size = UDim2.fromOffset(maxSize, maxSize),
            BackgroundTransparency = 1
        }, 0.5)
        
        task.delay(0.5, function()
            if ripple and ripple.Parent then
                ripple:Destroy()
            end
        end)
    end
    
    -- Start spinner animation
    function Button:StartSpinnerAnimation()
        if not self.Spinner then return end
        
        task.spawn(function()
            while self.Loading and self.Spinner and self.Spinner.Parent do
                self.Spinner.Rotation = self.Spinner.Rotation + 10
                task.wait(0.03)
            end
        end)
    end
    
    -- Set loading state
    function Button:SetLoading(loading)
        self.Loading = loading
        
        if self.Spinner then
            self.Spinner.Visible = loading
        end
        
        if loading then
            self.Label.Text = "Loading..."
            self:StartSpinnerAnimation()
        else
            self.Label.Text = self.Title
        end
        
        self.Frame.Active = not loading and not self.Disabled
    end
    
    -- Set disabled state
    function Button:SetDisabled(disabled)
        self.Disabled = disabled
        self.Frame.Active = not disabled and not self.Loading
        self.Label.TextTransparency = disabled and 0.5 or 0
        
        if self.Description then
            self.Description.TextTransparency = disabled and 0.6 or 0.4
        end
        
        if self.Icon then
            self.Icon.ImageTransparency = disabled and 0.5 or 0
        end
    end
    
    function Button:SetTitle(title)
        self.Title = title
        if not self.Loading then
            self.Label.Text = title
        end
    end
    
    function Button:SetCallback(callback)
        self.Callback = callback
    end
    
    function Button:SetIcon(icon)
        if self.Icon then
            local iconAsset = icon
            if type(icon) == "string" and not icon:match("^rbxassetid://") then
                iconAsset = Icons.Get(icon) or Icons.Question
            end
            self.Icon.Image = iconAsset
        end
    end
    
    function Button:Destroy()
        if self.Frame then
            self.Frame:Destroy()
        end
    end
    
    return Button
    
end

-- Module: Elements/Card
_modules["Elements/Card"] = function()
    --[[
        NexusUI Card Element
        Container card with header, content, footer
    ]]
    
    local Card = {}
    Card.__index = Card
    
    local Creator, ImageLoader
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        ImageLoader = _require("Utils/ImageLoader")
    end
    
    function Card.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title
        local Subtitle = options.Subtitle
        local Content = options.Content
        local Image = options.Image -- Raw URL or rbxassetid
        local ImageHeight = options.ImageHeight or 120
        local Actions = options.Actions or {} -- {Title, Callback}
        local Elevated = options.Elevated or false
        
        local self = setmetatable({}, Card)
        
        local hasImage = Image ~= nil
        local hasTitle = Title ~= nil
        local hasContent = Content ~= nil
        local hasActions = #Actions > 0
        
        local currentY = 0
        local children = {}
        
        -- Image
        if hasImage then
            self.ImageLabel = Creator.New("ImageLabel", {
                Size = UDim2.new(1, 0, 0, ImageHeight),
                Position = UDim2.fromOffset(0, 0),
                ScaleType = Enum.ScaleType.Crop,
                BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)})
            })
            ImageLoader.SetImage(self.ImageLabel, Image)
            table.insert(children, self.ImageLabel)
            currentY = ImageHeight
        end
        
        -- Title section
        if hasTitle then
            self.TitleLabel = Creator.New("TextLabel", {
                Size = UDim2.new(1, -24, 0, 22),
                Position = UDim2.fromOffset(12, currentY + 12),
                Text = Title,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "Text"}
            })
            table.insert(children, self.TitleLabel)
            currentY = currentY + 34
            
            if Subtitle then
                self.SubtitleLabel = Creator.New("TextLabel", {
                    Size = UDim2.new(1, -24, 0, 16),
                    Position = UDim2.fromOffset(12, currentY),
                    Text = Subtitle,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                    TextSize = 12,
                    TextTransparency = 0.4,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    ThemeTag = {TextColor3 = "SubText"}
                })
                table.insert(children, self.SubtitleLabel)
                currentY = currentY + 20
            end
        end
        
        -- Content
        if hasContent then
            self.ContentLabel = Creator.New("TextLabel", {
                Size = UDim2.new(1, -24, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.fromOffset(12, currentY + 8),
                Text = Content,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "Text"}
            })
            table.insert(children, self.ContentLabel)
            currentY = currentY + 60 -- Estimate
        end
        
        -- Actions
        if hasActions then
            currentY = currentY + 8
            
            self.ActionsContainer = Creator.New("Frame", {
                Size = UDim2.new(1, -24, 0, 32),
                Position = UDim2.fromOffset(12, currentY),
                BackgroundTransparency = 1
            }, {
                Creator.New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    Padding = UDim.new(0, 8)
                })
            })
            
            for _, action in ipairs(Actions) do
                local btn = Creator.New("TextButton", {
                    Size = UDim2.new(0, 0, 0, 28),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Text = action.Title or action[1] or "Action",
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
                    TextSize = 12,
                    Parent = self.ActionsContainer,
                    ThemeTag = {BackgroundColor3 = "Accent", TextColor3 = "Text"}
                }, {
                    Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)}),
                    Creator.New("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)})
                })
                
                Creator.AddSignal(btn.MouseButton1Click, action.Callback or action[2] or function() end)
            end
            
            table.insert(children, self.ActionsContainer)
            currentY = currentY + 40
        end
        
        currentY = currentY + 12
        
        -- Add base elements
        table.insert(children, Creator.New("UICorner", {CornerRadius = UDim.new(0, 10)}))
        table.insert(children, Creator.New("UIStroke", {Transparency = Elevated and 0.7 or 0.5, ThemeTag = {Color = "ElementBorder"}}))
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, currentY),
            BackgroundTransparency = 0.85,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, children)
        
        -- Elevation shadow
        if Elevated then
            Creator.New("ImageLabel", {
                Size = UDim2.new(1, 20, 1, 20),
                Position = UDim2.fromOffset(-10, 5),
                Image = "rbxassetid://5554236805",
                ImageTransparency = 0.6,
                ScaleType = Enum.ScaleType.Slice,
                SliceCenter = Rect.new(23, 23, 277, 277),
                BackgroundTransparency = 1,
                ZIndex = -1,
                Parent = self.Frame
            })
        end
        
        self.Root = self.Frame
        return self
    end
    
    return Card
    
end

-- Module: Elements/Carousel
_modules["Elements/Carousel"] = function()
    --[[
        NexusUI Carousel Element
        Auto-scrolling content carousel
    ]]
    
    local Carousel = {}
    Carousel.__index = Carousel
    
    local Creator, ImageLoader
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        ImageLoader = _require("Utils/ImageLoader")
    end
    
    function Carousel.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Items = options.Items or {} -- {Image, Title, Description, Callback}
        local Height = options.Height or 180
        local AutoPlay = options.AutoPlay ~= false
        local Interval = options.Interval or 5
        local ShowDots = options.Dots ~= false
        local ShowArrows = options.Arrows or false
        
        local self = setmetatable({}, Carousel)
        self.Items = Items
        self.Current = 1
        self.Playing = AutoPlay
        
        -- Carousel container
        self.ViewFrame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, Height),
            BackgroundTransparency = 1,
            ClipsDescendants = true
        })
        
        -- Slides container
        self.SlidesContainer = Creator.New("Frame", {
            Size = UDim2.fromScale(#Items, 1),
            BackgroundTransparency = 1,
            Parent = self.ViewFrame
        }, {
            Creator.New("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal})
        })
        
        -- Create slides
        for i, item in ipairs(Items) do
            local slide = Creator.New("Frame", {
                Size = UDim2.new(1 / #Items, 0, 1, 0),
                BackgroundTransparency = 1,
                Parent = self.SlidesContainer
            })
            
            -- Image
            if item.Image then
                local img = Creator.New("ImageLabel", {
                    Size = UDim2.fromScale(1, 1),
                    ScaleType = Enum.ScaleType.Crop,
                    BackgroundColor3 = Color3.fromRGB(30, 30, 40),
                    Parent = slide
                }, {
                    Creator.New("UICorner", {CornerRadius = UDim.new(0, 10)}),
                    -- Gradient overlay for text
                    Creator.New("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
                            ColorSequenceKeypoint.new(0.5, Color3.new(0, 0, 0)),
                            ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0))
                        }),
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 1),
                            NumberSequenceKeypoint.new(0.6, 1),
                            NumberSequenceKeypoint.new(1, 0.3)
                        }),
                        Rotation = 90
                    })
                })
                ImageLoader.SetImage(img, item.Image)
            end
            
            -- Title
            if item.Title then
                Creator.New("TextLabel", {
                    Size = UDim2.new(1, -24, 0, 24),
                    Position = UDim2.new(0, 12, 1, -50),
                    Text = item.Title,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
                    TextSize = 18,
                    TextColor3 = Color3.new(1, 1, 1),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Parent = slide
                })
            end
            
            -- Description
            if item.Description then
                Creator.New("TextLabel", {
                    Size = UDim2.new(1, -24, 0, 18),
                    Position = UDim2.new(0, 12, 1, -26),
                    Text = item.Description,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                    TextSize = 13,
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Parent = slide
                })
            end
            
            -- Click handler
            if item.Callback then
                local btn = Creator.New("TextButton", {
                    Size = UDim2.fromScale(1, 1),
                    Text = "",
                    BackgroundTransparency = 1,
                    Parent = slide
                })
                Creator.AddSignal(btn.MouseButton1Click, item.Callback)
            end
        end
        
        -- Navigation dots
        if ShowDots and #Items > 1 then
            self.DotsContainer = Creator.New("Frame", {
                Size = UDim2.new(0, #Items * 16, 0, 10),
                Position = UDim2.new(0.5, 0, 1, -16),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1
            }, {
                Creator.New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    Padding = UDim.new(0, 6)
                })
            })
            
            self.Dots = {}
            for i = 1, #Items do
                local dot = Creator.New("TextButton", {
                    Size = UDim2.fromOffset(8, 8),
                    Text = "",
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BackgroundTransparency = i == 1 and 0.3 or 0.7,
                    Parent = self.DotsContainer
                }, {
                    Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
                })
                
                Creator.AddSignal(dot.MouseButton1Click, function()
                    self:GoTo(i)
                end)
                
                self.Dots[i] = dot
            end
        end
        
        -- Arrow navigation
        if ShowArrows and #Items > 1 then
            local function createArrow(text, isLeft)
                local arrow = Creator.New("TextButton", {
                    Size = UDim2.fromOffset(32, 32),
                    Position = isLeft and UDim2.new(0, 8, 0.5, 0) or UDim2.new(1, -8, 0.5, 0),
                    AnchorPoint = isLeft and Vector2.new(0, 0.5) or Vector2.new(1, 0.5),
                    Text = text,
                    TextSize = 18,
                    TextColor3 = Color3.new(1, 1, 1),
                    BackgroundColor3 = Color3.new(0, 0, 0),
                    BackgroundTransparency = 0.5
                }, {
                    Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
                })
                
                Creator.AddSignal(arrow.MouseButton1Click, function()
                    if isLeft then self:Previous() else self:Next() end
                end)
                
                return arrow
            end
            
            self.LeftArrow = createArrow("‹", true)
            self.RightArrow = createArrow("›", false)
        end
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, Height + (ShowDots and 20 or 0)),
            BackgroundTransparency = 1,
            Parent = parent
        }, {
            self.ViewFrame,
            ShowDots and self.DotsContainer or nil,
            ShowArrows and self.LeftArrow or nil,
            ShowArrows and self.RightArrow or nil
        })
        
        -- Auto-play
        if AutoPlay and #Items > 1 then
            task.spawn(function()
                while self.Playing and self.Frame.Parent do
                    task.wait(Interval)
                    if self.Playing then
                        self:Next()
                    end
                end
            end)
        end
        
        self.Root = self.Frame
        return self
    end
    
    function Carousel:GoTo(index)
        if index < 1 then index = #self.Items end
        if index > #self.Items then index = 1 end
        
        self.Current = index
        
        -- Animate slide
        local targetX = -(index - 1) / #self.Items
        Creator.Tween(self.SlidesContainer, {Position = UDim2.fromScale(targetX, 0)}, 0.4, "Smooth")
        
        -- Update dots
        if self.Dots then
            for i, dot in ipairs(self.Dots) do
                Creator.Tween(dot, {BackgroundTransparency = i == index and 0.3 or 0.7}, 0.2)
            end
        end
    end
    
    function Carousel:Next() self:GoTo(self.Current + 1) end
    function Carousel:Previous() self:GoTo(self.Current - 1) end
    function Carousel:Play() self.Playing = true end
    function Carousel:Pause() self.Playing = false end
    
    return Carousel
    
end

-- Module: Elements/Checkbox
_modules["Elements/Checkbox"] = function()
    --[[
        NexusUI Checkbox Element
        Simple checkbox with label
    ]]
    
    local Checkbox = {}
    Checkbox.__index = Checkbox
    
    local Creator, Flipper
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Flipper = _require("Packages/Flipper")
    end
    
    function Checkbox.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Checkbox"
        local Default = options.Default or false
        local Callback = options.Callback or function() end
        
        local self = setmetatable({}, Checkbox)
        self.Value = Default
        self.Callback = Callback
        
        -- Checkbox box
        self.CheckBox = Creator.New("Frame", {
            Size = UDim2.fromOffset(20, 20),
            Position = UDim2.new(0, 12, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 0.9,
            ThemeTag = {BackgroundColor3 = Default and "Accent" or "Input"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 4)}),
            Creator.New("UIStroke", {ThemeTag = {Color = Default and "Accent" or "InputStroke"}}),
            Creator.New("ImageLabel", {
                Size = UDim2.fromOffset(14, 14),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Image = "rbxassetid://10747379159", -- Checkmark
                ImageTransparency = Default and 0 or 1,
                BackgroundTransparency = 1,
                ThemeTag = {ImageColor3 = "Text"}
            })
        })
        
        self.CheckMark = self.CheckBox:FindFirstChild("ImageLabel")
        
        -- Title
        self.TitleLabel = Creator.New("TextLabel", {
            Size = UDim2.new(1, -50, 1, 0),
            Position = UDim2.fromOffset(42, 0),
            Text = Title,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Frame
        self.Frame = Creator.New("TextButton", {
            Size = UDim2.new(1, 0, 0, 36),
            Text = "",
            BackgroundTransparency = 1,
            Parent = parent
        }, {
            self.CheckBox,
            self.TitleLabel
        })
        
        -- Click handler
        Creator.AddSignal(self.Frame.MouseButton1Click, function()
            self:Toggle()
        end)
        
        self.Root = self.Frame
        return self
    end
    
    function Checkbox:Toggle()
        self.Value = not self.Value
        self:UpdateVisual()
        self.Callback(self.Value)
    end
    
    function Checkbox:UpdateVisual()
        Creator.Tween(self.CheckMark, {ImageTransparency = self.Value and 0 or 1}, 0.2)
        Creator.OverrideTag(self.CheckBox, {BackgroundColor3 = self.Value and "Accent" or "Input"})
    end
    
    function Checkbox:Set(value)
        self.Value = value
        self:UpdateVisual()
    end
    
    function Checkbox:GetValue() return self.Value end
    
    return Checkbox
    
end

-- Module: Elements/Chip
_modules["Elements/Chip"] = function()
    --[[
        NexusUI Chip Element
        Selectable tag/filter chips
    ]]
    
    local Chip = {}
    Chip.__index = Chip
    
    local Creator, ImageLoader
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        ImageLoader = _require("Utils/ImageLoader")
    end
    
    function Chip.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Text = options.Text or "Chip"
        local Icon = options.Icon -- Raw URL or rbxassetid
        local Selected = options.Selected or false
        local Selectable = options.Selectable ~= false
        local Deletable = options.Deletable or false
        local Callback = options.Callback or function() end
        local OnDelete = options.OnDelete or function() end
        
        local self = setmetatable({}, Chip)
        self.Selected = Selected
        self.Callback = Callback
        
        -- Chip frame
        self.Frame = Creator.New("TextButton", {
            Size = UDim2.new(0, 0, 0, 28),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = "",
            BackgroundTransparency = Selected and 0.7 or 0.9,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = Selected and "Accent" or "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)}),
            Creator.New("UIStroke", {ThemeTag = {Color = Selected and "Accent" or "ElementBorder"}}),
            Creator.New("UIPadding", {
                PaddingLeft = UDim.new(0, Icon and 8 or 12),
                PaddingRight = UDim.new(0, Deletable and 4 or 12)
            }),
            Creator.New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 6)
            })
        })
        
        -- Icon
        if Icon then
            self.IconLabel = Creator.New("ImageLabel", {
                Size = UDim2.fromOffset(16, 16),
                BackgroundTransparency = 1,
                Parent = self.Frame,
                ThemeTag = {ImageColor3 = "Text"}
            })
            ImageLoader.SetImage(self.IconLabel, Icon)
        end
        
        -- Text
        self.TextLabel = Creator.New("TextLabel", {
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = Text,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 12,
            BackgroundTransparency = 1,
            Parent = self.Frame,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Delete button
        if Deletable then
            self.DeleteBtn = Creator.New("TextButton", {
                Size = UDim2.fromOffset(18, 18),
                Text = "✕",
                TextSize = 10,
                BackgroundTransparency = 0.8,
                Parent = self.Frame,
                ThemeTag = {BackgroundColor3 = "Element", TextColor3 = "Text"}
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
            })
            
            Creator.AddSignal(self.DeleteBtn.MouseButton1Click, function()
                OnDelete()
                self.Frame:Destroy()
            end)
        end
        
        -- Click handler
        if Selectable then
            Creator.AddSignal(self.Frame.MouseButton1Click, function()
                self:Toggle()
            end)
        end
        
        self.Root = self.Frame
        return self
    end
    
    function Chip:Toggle()
        self.Selected = not self.Selected
        self:UpdateVisual()
        self.Callback(self.Selected)
    end
    
    function Chip:UpdateVisual()
        Creator.Tween(self.Frame, {BackgroundTransparency = self.Selected and 0.7 or 0.9}, 0.2)
        Creator.OverrideTag(self.Frame, {BackgroundColor3 = self.Selected and "Accent" or "Element"})
    end
    
    function Chip:SetSelected(selected)
        self.Selected = selected
        self:UpdateVisual()
    end
    
    function Chip:SetText(text)
        self.TextLabel.Text = text
    end
    
    return Chip
    
end

-- Module: Elements/CodeBlock
_modules["Elements/CodeBlock"] = function()
    --[[
        NexusUI Code Block Element
        Syntax-highlighted code display
    ]]
    
    local CodeBlock = {}
    CodeBlock.__index = CodeBlock
    
    local Creator
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
    end
    
    function CodeBlock.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Code"
        local Code = options.Code or ""
        local Language = options.Language or "lua"
        local ShowLineNumbers = options.LineNumbers ~= false
        local Copyable = options.Copyable ~= false
        local MaxHeight = options.MaxHeight or 200
        
        local self = setmetatable({}, CodeBlock)
        self.Code = Code
        
        -- Title bar
        self.TitleBar = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 0.85,
            ThemeTag = {BackgroundColor3 = "Topbar"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            -- Title
            Creator.New("TextLabel", {
                Size = UDim2.new(0.5, 0, 1, 0),
                Position = UDim2.fromOffset(12, 0),
                Text = Title .. " (" .. Language .. ")",
                FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json"),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "SubText"}
            })
        })
        
        -- Copy button
        if Copyable then
            self.CopyBtn = Creator.New("TextButton", {
                Size = UDim2.fromOffset(50, 24),
                Position = UDim2.new(1, -8, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                Text = "Copy",
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                TextSize = 11,
                Parent = self.TitleBar,
                ThemeTag = {BackgroundColor3 = "Accent", TextColor3 = "Text"}
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(0, 4)})
            })
            
            Creator.AddSignal(self.CopyBtn.MouseButton1Click, function()
                if setclipboard then
                    setclipboard(self.Code)
                    self.CopyBtn.Text = "Copied!"
                    task.delay(1, function()
                        if self.CopyBtn.Parent then
                            self.CopyBtn.Text = "Copy"
                        end
                    end)
                end
            end)
        end
        
        -- Code content
        local lines = {}
        for line in (Code .. "\n"):gmatch("(.-)\n") do
            table.insert(lines, line)
        end
        
        local codeHeight = math.min(#lines * 18, MaxHeight)
        
        -- Line numbers
        local lineNumText = ""
        if ShowLineNumbers then
            for i = 1, #lines do
                lineNumText = lineNumText .. i .. "\n"
            end
        end
        
        self.CodeContainer = Creator.New("ScrollingFrame", {
            Size = UDim2.new(1, 0, 0, codeHeight),
            Position = UDim2.fromOffset(0, 32),
            BackgroundTransparency = 0.92,
            ScrollBarThickness = 3,
            CanvasSize = UDim2.fromOffset(0, #lines * 18),
            ThemeTag = {BackgroundColor3 = "Input", ScrollBarImageColor3 = "Text"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)})
        })
        
        -- Line numbers
        if ShowLineNumbers then
            Creator.New("TextLabel", {
                Size = UDim2.new(0, 35, 0, #lines * 18),
                Position = UDim2.fromOffset(8, 8),
                Text = lineNumText,
                FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json"),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextTransparency = 0.5,
                BackgroundTransparency = 1,
                Parent = self.CodeContainer,
                ThemeTag = {TextColor3 = "SubText"}
            })
        end
        
        -- Code text
        Creator.New("TextLabel", {
            Size = UDim2.new(1, ShowLineNumbers and -55 or -16, 0, #lines * 18),
            Position = UDim2.fromOffset(ShowLineNumbers and 50 or 8, 8),
            Text = Code,
            FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json"),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            BackgroundTransparency = 1,
            Parent = self.CodeContainer,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, codeHeight + 40),
            BackgroundTransparency = 1,
            Parent = parent
        }, {
            self.TitleBar,
            self.CodeContainer
        })
        
        self.Root = self.Frame
        return self
    end
    
    function CodeBlock:SetCode(code)
        self.Code = code
        -- Would need to re-render, simplified for now
    end
    
    return CodeBlock
    
end

-- Module: Elements/ColorPicker
_modules["Elements/ColorPicker"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                ColorPicker Component v2.15                    ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        Features:
        • Full HSV color picker
        • Color presets
        • Hex/RGB input
        • Opacity/alpha slider
        • Recent colors
        • Copy/paste hex values
        • Compact and expanded modes
    ]]
    
    local ColorPicker = {}
    ColorPicker.__index = ColorPicker
    
    -- Default color presets
    local DEFAULT_PRESETS = {
        Color3.fromRGB(255, 0, 0),      -- Red
        Color3.fromRGB(255, 127, 0),    -- Orange
        Color3.fromRGB(255, 255, 0),    -- Yellow
        Color3.fromRGB(0, 255, 0),      -- Green
        Color3.fromRGB(0, 255, 255),    -- Cyan
        Color3.fromRGB(0, 127, 255),    -- Sky Blue
        Color3.fromRGB(0, 0, 255),      -- Blue
        Color3.fromRGB(127, 0, 255),    -- Purple
        Color3.fromRGB(255, 0, 255),    -- Magenta
        Color3.fromRGB(255, 0, 127),    -- Pink
        Color3.fromRGB(255, 255, 255),  -- White
        Color3.fromRGB(128, 128, 128),  -- Gray
        Color3.fromRGB(0, 0, 0),        -- Black
        Color3.fromRGB(139, 69, 19),    -- Brown
    }
    
    local Creator
    local Flipper
    local Services
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Flipper = _require("Packages/Flipper")
        Services = _require("Core/Services")
    end
    
    -- Helper functions
    local function ColorToHex(color)
        return string.format("#%02X%02X%02X", 
            math.floor(color.R * 255), 
            math.floor(color.G * 255), 
            math.floor(color.B * 255))
    end
    
    local function HexToColor(hex)
        hex = hex:gsub("#", "")
        if #hex == 6 then
            local r = tonumber(hex:sub(1, 2), 16) or 255
            local g = tonumber(hex:sub(3, 4), 16) or 255
            local b = tonumber(hex:sub(5, 6), 16) or 255
            return Color3.fromRGB(r, g, b)
        end
        return Color3.fromRGB(255, 255, 255)
    end
    
    function ColorPicker.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "ColorPicker"
        local Description = options.Description
        local Default = options.Default or Color3.fromRGB(255, 255, 255)
        local DefaultAlpha = options.DefaultAlpha or 1
        local ShowAlpha = options.ShowAlpha or false
        local ShowPresets = options.ShowPresets ~= false -- Default true
        local ShowHexInput = options.ShowHexInput ~= false -- Default true
        local Presets = options.Presets or DEFAULT_PRESETS
        local Disabled = options.Disabled or false
        local Callback = options.Callback or function() end
        local Flag = options.Flag
        
        local self = setmetatable({}, ColorPicker)
        
        self.Value = Default
        self.Alpha = DefaultAlpha
        self.Callback = Callback
        self.Open = false
        self.Hue = 0
        self.Sat = 0
        self.Val = 1
        self.ShowAlpha = ShowAlpha
        self.ShowPresets = ShowPresets
        self.ShowHexInput = ShowHexInput
        self.Presets = Presets
        self.Disabled = Disabled
        self.Flag = Flag
        self.RecentColors = {}
        
        -- Initialize from default
        self.Hue, self.Sat, self.Val = Default:ToHSV()
        
        local hasDescription = Description ~= nil
        local closedHeight = hasDescription and 48 or 36
        local pickerHeight = 160
        if ShowPresets then pickerHeight = pickerHeight + 50 end
        if ShowHexInput then pickerHeight = pickerHeight + 35 end
        if ShowAlpha then pickerHeight = pickerHeight + 30 end
        
        -- Color preview box (clickable)
        self.ColorPreviewButton = Creator.New("TextButton", {
            Size = UDim2.fromOffset(42, 22),
            Position = UDim2.new(1, -12, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = Default,
            BackgroundTransparency = 1 - DefaultAlpha,
            Text = "",
            AutoButtonColor = false,
            Active = not Disabled
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)}),
            Creator.New("UIStroke", {
                Transparency = 0.4,
                Thickness = 1.5,
                ThemeTag = {Color = "ElementBorder"}
            }),
            -- Checkered background for transparency
            Creator.New("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.fromRGB(200, 200, 200),
                ZIndex = -1
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)})
            })
        })
        
        -- Picker content container
        self.PickerContent = Creator.New("Frame", {
            Size = UDim2.new(1, -24, 0, pickerHeight),
            Position = UDim2.new(0, 12, 0, closedHeight + 8),
            BackgroundTransparency = 1,
            Visible = false
        })
        
        local yOffset = 0
        
        -- Saturation/Value Picker (main color area)
        self.SatValPicker = Creator.New("ImageButton", {
            Size = UDim2.new(1, 0, 0, 100),
            Position = UDim2.fromOffset(0, yOffset),
            Image = "rbxassetid://4155801252",
            ImageColor3 = Color3.fromHSV(self.Hue, 1, 1),
            AutoButtonColor = false,
            Active = not Disabled,
            Parent = self.PickerContent
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {
                Transparency = 0.5,
                ThemeTag = {Color = "ElementBorder"}
            })
        })
        
        -- Value gradient overlay
        Creator.New("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(0, 0, 0),
            Parent = self.SatValPicker
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIGradient", {
                Color = ColorSequence.new(Color3.new(1, 1, 1)),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1)
                }),
                Rotation = -90
            })
        })
        
        -- SatVal Cursor
        self.SatValCursor = Creator.New("Frame", {
            Size = UDim2.fromOffset(16, 16),
            Position = UDim2.new(self.Sat, 0, 1 - self.Val, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Default,
            Parent = self.SatValPicker,
            ZIndex = 5
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)}),
            Creator.New("UIStroke", {
                Thickness = 2,
                Color = Color3.new(1, 1, 1)
            })
        })
        
        yOffset = yOffset + 110
        
        -- Hue Slider
        self.HueSlider = Creator.New("ImageButton", {
            Size = UDim2.new(1, 0, 0, 16),
            Position = UDim2.new(0, 0, 0, yOffset),
            Image = "rbxassetid://3641079629",
            AutoButtonColor = false,
            Active = not Disabled,
            Parent = self.PickerContent
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
        })
        
        -- Hue Cursor
        self.HueCursor = Creator.New("Frame", {
            Size = UDim2.new(0, 8, 1, 4),
            Position = UDim2.new(self.Hue, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.new(1, 1, 1),
            Parent = self.HueSlider
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 3)}),
            Creator.New("UIStroke", {
                Thickness = 1.5,
                Color = Color3.new(0.2, 0.2, 0.2)
            })
        })
        
        yOffset = yOffset + 26
        
        -- Alpha Slider
        if ShowAlpha then
            self.AlphaSlider = Creator.New("ImageButton", {
                Size = UDim2.new(1, 0, 0, 16),
                Position = UDim2.new(0, 0, 0, yOffset),
                AutoButtonColor = false,
                Active = not Disabled,
                BackgroundColor3 = Color3.fromRGB(200, 200, 200),
                Parent = self.PickerContent
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)}),
                Creator.New("Frame", {
                    Name = "AlphaFill",
                    Size = UDim2.fromScale(1, 1),
                    BackgroundColor3 = Default,
                    Parent = self.PickerContent
                }, {
                    Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)}),
                    Creator.New("UIGradient", {
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 1),
                            NumberSequenceKeypoint.new(1, 0)
                        })
                    })
                })
            })
            
            -- Alpha Cursor
            self.AlphaCursor = Creator.New("Frame", {
                Size = UDim2.new(0, 8, 1, 4),
                Position = UDim2.new(DefaultAlpha, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(1, 1, 1),
                Parent = self.AlphaSlider
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(0, 3)}),
                Creator.New("UIStroke", {
                    Thickness = 1.5,
                    Color = Color3.new(0.2, 0.2, 0.2)
                })
            })
            
            yOffset = yOffset + 26
        end
        
        -- Hex Input
        if ShowHexInput then
            self.HexContainer = Creator.New("Frame", {
                Size = UDim2.new(1, 0, 0, 28),
                Position = UDim2.new(0, 0, 0, yOffset),
                BackgroundTransparency = 1,
                Parent = self.PickerContent
            })
            
            Creator.New("TextLabel", {
                Text = "HEX:",
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
                TextSize = 11,
                Size = UDim2.fromOffset(35, 28),
                BackgroundTransparency = 1,
                Parent = self.HexContainer,
                ThemeTag = {TextColor3 = "SubText"}
            })
            
            self.HexInput = Creator.New("TextBox", {
                Text = ColorToHex(Default),
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
                TextSize = 12,
                Size = UDim2.new(0, 80, 0, 24),
                Position = UDim2.fromOffset(40, 2),
                BackgroundTransparency = 0.9,
                ClearTextOnFocus = false,
                TextEditable = not Disabled,
                Parent = self.HexContainer,
                ThemeTag = {BackgroundColor3 = "Input", TextColor3 = "Text"}
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(0, 4)}),
                Creator.New("UIStroke", {
                    Transparency = 0.6,
                    ThemeTag = {Color = "InputStroke"}
                }),
                Creator.New("UIPadding", {PaddingLeft = UDim.new(0, 6)})
            })
            
            -- RGB display
            self.RGBLabel = Creator.New("TextLabel", {
                Text = string.format("R:%d G:%d B:%d", 
                    math.floor(Default.R * 255), 
                    math.floor(Default.G * 255), 
                    math.floor(Default.B * 255)),
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                TextSize = 10,
                Size = UDim2.new(0, 100, 0, 28),
                Position = UDim2.new(1, 0, 0, 0),
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                TextTransparency = 0.3,
                Parent = self.HexContainer,
                ThemeTag = {TextColor3 = "SubText"}
            })
            
            -- Hex input handler
            Creator.AddSignal(self.HexInput.FocusLost, function(enterPressed)
                if enterPressed then
                    local color = HexToColor(self.HexInput.Text)
                    self:Set(color, self.Alpha)
                else
                    self.HexInput.Text = ColorToHex(self.Value)
                end
            end)
            
            yOffset = yOffset + 32
        end
        
        -- Color Presets
        if ShowPresets then
            self.PresetsContainer = Creator.New("Frame", {
                Size = UDim2.new(1, 0, 0, 44),
                Position = UDim2.new(0, 0, 0, yOffset),
                BackgroundTransparency = 1,
                Parent = self.PickerContent
            }, {
                Creator.New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDim.new(0, 6),
                    VerticalAlignment = Enum.VerticalAlignment.Center
                })
            })
            
            -- Create preset buttons
            for _, preset in ipairs(Presets) do
                local presetButton = Creator.New("TextButton", {
                    Size = UDim2.fromOffset(22, 22),
                    BackgroundColor3 = preset,
                    Text = "",
                    AutoButtonColor = false,
                    Active = not Disabled,
                    Parent = self.PresetsContainer
                }, {
                    Creator.New("UICorner", {CornerRadius = UDim.new(0, 4)}),
                    Creator.New("UIStroke", {
                        Transparency = 0.5,
                        ThemeTag = {Color = "ElementBorder"}
                    })
                })
                
                Creator.AddSignal(presetButton.MouseButton1Click, function()
                    if not self.Disabled then
                        self:Set(preset, self.Alpha)
                    end
                end)
            end
        end
        
        -- Title
        self.Label = Creator.New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
            Text = Title,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -70, 0, 14),
            Position = hasDescription and UDim2.fromOffset(12, 9) or UDim2.new(0, 12, 0.5, 0),
            AnchorPoint = hasDescription and Vector2.zero or Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            TextTransparency = Disabled and 0.5 or 0,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Description
        if hasDescription then
            self.DescriptionLabel = Creator.New("TextLabel", {
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                Text = Description,
                TextSize = 12,
                TextTransparency = Disabled and 0.6 or 0.4,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -70, 0, 12),
                Position = UDim2.fromOffset(12, 27),
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "SubText"}
            })
        end
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, closedHeight),
            BackgroundTransparency = 0.89,
            ClipsDescendants = true,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 10)}),
            Creator.New("UIStroke", {
                Transparency = 0.5,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                ThemeTag = {Color = "ElementBorder"}
            }),
            self.Label,
            hasDescription and self.DescriptionLabel or nil,
            self.ColorPreviewButton,
            self.PickerContent
        })
        
        self.ClosedHeight = closedHeight
        self.PickerHeight = pickerHeight
        
        -- Animation motor
        self.HeightMotor = Flipper.SingleMotor.new(closedHeight)
        self.HeightMotor:onStep(function(value)
            self.Frame.Size = UDim2.new(1, 0, 0, value)
        end)
        
        -- Toggle picker on preview click
        if not Disabled then
            Creator.AddSignal(self.ColorPreviewButton.MouseButton1Click, function()
                self:Toggle()
            end)
        end
        
        -- SatVal drag handling
        local satValDragging = false
        
        local function updateSatVal(input)
            if self.Disabled then return end
            local absPos = self.SatValPicker.AbsolutePosition
            local absSize = self.SatValPicker.AbsoluteSize
            local relX = math.clamp((input.Position.X - absPos.X) / absSize.X, 0, 1)
            local relY = math.clamp((input.Position.Y - absPos.Y) / absSize.Y, 0, 1)
            
            self.Sat = relX
            self.Val = 1 - relY
            self:UpdateColor()
        end
        
        Creator.AddSignal(self.SatValPicker.InputBegan, function(input)
            if not self.Disabled and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                satValDragging = true
                updateSatVal(input)
            end
        end)
        
        Creator.AddSignal(Services.UserInputService.InputChanged, function(input)
            if satValDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateSatVal(input)
            end
        end)
        
        Creator.AddSignal(Services.UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                satValDragging = false
            end
        end)
        
        -- Hue drag handling
        local hueDragging = false
        
        local function updateHue(input)
            if self.Disabled then return end
            local absPos = self.HueSlider.AbsolutePosition
            local absSize = self.HueSlider.AbsoluteSize
            local relX = math.clamp((input.Position.X - absPos.X) / absSize.X, 0, 1)
            
            self.Hue = relX
            self.SatValPicker.ImageColor3 = Color3.fromHSV(self.Hue, 1, 1)
            self:UpdateColor()
        end
        
        Creator.AddSignal(self.HueSlider.InputBegan, function(input)
            if not self.Disabled and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                hueDragging = true
                updateHue(input)
            end
        end)
        
        Creator.AddSignal(Services.UserInputService.InputChanged, function(input)
            if hueDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateHue(input)
            end
        end)
        
        Creator.AddSignal(Services.UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                hueDragging = false
            end
        end)
        
        -- Alpha drag handling
        if ShowAlpha and self.AlphaSlider then
            local alphaDragging = false
            
            local function updateAlpha(input)
                if self.Disabled then return end
                local absPos = self.AlphaSlider.AbsolutePosition
                local absSize = self.AlphaSlider.AbsoluteSize
                local relX = math.clamp((input.Position.X - absPos.X) / absSize.X, 0, 1)
                
                self.Alpha = relX
                self:UpdateColor()
            end
            
            Creator.AddSignal(self.AlphaSlider.InputBegan, function(input)
                if not self.Disabled and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    alphaDragging = true
                    updateAlpha(input)
                end
            end)
            
            Creator.AddSignal(Services.UserInputService.InputChanged, function(input)
                if alphaDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateAlpha(input)
                end
            end)
            
            Creator.AddSignal(Services.UserInputService.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    alphaDragging = false
                end
            end)
        end
        
        self.Root = self.Frame
        
        return self
    end
    
    function ColorPicker:UpdateColor()
        self.Value = Color3.fromHSV(self.Hue, self.Sat, self.Val)
        self.ColorPreviewButton.BackgroundColor3 = self.Value
        self.ColorPreviewButton.BackgroundTransparency = 1 - self.Alpha
        self.SatValCursor.Position = UDim2.new(self.Sat, 0, 1 - self.Val, 0)
        self.HueCursor.Position = UDim2.new(self.Hue, 0, 0.5, 0)
        self.SatValCursor.BackgroundColor3 = self.Value
        
        if self.AlphaCursor then
            self.AlphaCursor.Position = UDim2.new(self.Alpha, 0, 0.5, 0)
        end
        
        if self.HexInput then
            self.HexInput.Text = ColorToHex(self.Value)
        end
        
        if self.RGBLabel then
            self.RGBLabel.Text = string.format("R:%d G:%d B:%d", 
                math.floor(self.Value.R * 255), 
                math.floor(self.Value.G * 255), 
                math.floor(self.Value.B * 255))
        end
        
        self.Callback(self.Value, self.Alpha)
    end
    
    function ColorPicker:Toggle()
        if self.Disabled then return end
        
        self.Open = not self.Open
        
        if self.Open then
            self.PickerContent.Visible = true
            local targetHeight = self.ClosedHeight + self.PickerHeight + 16
            self.HeightMotor:setGoal(Flipper.Spring.new(targetHeight, {frequency = 6, dampingRatio = 0.8}))
        else
            self.HeightMotor:setGoal(Flipper.Spring.new(self.ClosedHeight, {frequency = 6, dampingRatio = 0.8}))
            task.delay(0.3, function()
                if not self.Open then
                    self.PickerContent.Visible = false
                end
            end)
        end
    end
    
    function ColorPicker:Set(color, alpha, noCallback)
        if self.Disabled then return end
        
        self.Value = color
        if alpha then self.Alpha = alpha end
        
        self.Hue, self.Sat, self.Val = color:ToHSV()
        self.ColorPreviewButton.BackgroundColor3 = color
        self.ColorPreviewButton.BackgroundTransparency = 1 - self.Alpha
        self.SatValPicker.ImageColor3 = Color3.fromHSV(self.Hue, 1, 1)
        self.SatValCursor.Position = UDim2.new(self.Sat, 0, 1 - self.Val, 0)
        self.SatValCursor.BackgroundColor3 = color
        self.HueCursor.Position = UDim2.new(self.Hue, 0, 0.5, 0)
        
        if self.AlphaCursor then
            self.AlphaCursor.Position = UDim2.new(self.Alpha, 0, 0.5, 0)
        end
        
        if self.HexInput then
            self.HexInput.Text = ColorToHex(color)
        end
        
        if self.RGBLabel then
            self.RGBLabel.Text = string.format("R:%d G:%d B:%d", 
                math.floor(color.R * 255), 
                math.floor(color.G * 255), 
                math.floor(color.B * 255))
        end
        
        if not noCallback then
            self.Callback(color, self.Alpha)
        end
    end
    
    function ColorPicker:SetDisabled(disabled)
        self.Disabled = disabled
        self.ColorPreviewButton.Active = not disabled
        
        if self.Label then
            self.Label.TextTransparency = disabled and 0.5 or 0
        end
        
        if self.DescriptionLabel then
            self.DescriptionLabel.TextTransparency = disabled and 0.6 or 0.4
        end
    end
    
    function ColorPicker:GetValue()
        return self.Value, self.Alpha
    end
    
    function ColorPicker:GetHex()
        return ColorToHex(self.Value)
    end
    
    function ColorPicker:Destroy()
        if self.Frame then
            self.Frame:Destroy()
        end
    end
    
    return ColorPicker
    
end

-- Module: Elements/Divider
_modules["Elements/Divider"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                  Divider Component v2.15                      ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        Features:
        • Simple horizontal divider
        • Optional text label
        • Customizable thickness
    ]]
    
    local Divider = {}
    Divider.__index = Divider
    
    local Creator
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
    end
    
    function Divider.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Text = options.Text
        local Thickness = options.Thickness or 1
        local Padding = options.Padding or 8
        
        local self = setmetatable({}, Divider)
        
        local hasText = Text ~= nil
        local height = hasText and 24 or (Padding * 2 + Thickness)
        
        if hasText then
            -- Divider with text
            self.LeftLine = Creator.New("Frame", {
                Size = UDim2.new(0.5, -30, 0, Thickness),
                Position = UDim2.new(0, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 0.5,
                ThemeTag = {BackgroundColor3 = "ElementBorder"}
            })
            
            self.Label = Creator.New("TextLabel", {
                Text = Text,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                TextSize = 11,
                Size = UDim2.fromOffset(60, 20),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                TextTransparency = 0.4,
                ThemeTag = {TextColor3 = "SubText"}
            })
            
            self.RightLine = Creator.New("Frame", {
                Size = UDim2.new(0.5, -30, 0, Thickness),
                Position = UDim2.new(1, 0, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 0.5,
                ThemeTag = {BackgroundColor3 = "ElementBorder"}
            })
            
            self.Frame = Creator.New("Frame", {
                Size = UDim2.new(1, 0, 0, height),
                BackgroundTransparency = 1,
                Parent = parent
            }, {
                self.LeftLine,
                self.Label,
                self.RightLine
            })
        else
            -- Simple line divider
            self.Line = Creator.New("Frame", {
                Size = UDim2.new(1, 0, 0, Thickness),
                Position = UDim2.fromScale(0, 0.5),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 0.5,
                ThemeTag = {BackgroundColor3 = "ElementBorder"}
            })
            
            self.Frame = Creator.New("Frame", {
                Size = UDim2.new(1, 0, 0, height),
                BackgroundTransparency = 1,
                Parent = parent
            }, {
                self.Line
            })
        end
        
        self.Root = self.Frame
        
        return self
    end
    
    function Divider:Destroy()
        if self.Frame then
            self.Frame:Destroy()
        end
    end
    
    return Divider
    
end

-- Module: Elements/Dropdown
_modules["Elements/Dropdown"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                  Dropdown Component v2.15                     ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        Features:
        • Single and multi-select modes
        • Search/filter functionality
        • Option groups with headers
        • Icons per option
        • Clear button
        • Virtualization for large lists
        • Custom option descriptions
        • Disabled state
        • Creatable (add new options by typing)
    ]]
    
    local Dropdown = {}
    Dropdown.__index = Dropdown
    
    local Creator
    local Flipper
    local Services
    local Icons
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Flipper = _require("Packages/Flipper")
        Services = _require("Core/Services")
        Icons = _require("Utils/Icons")
    end
    
    function Dropdown.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Dropdown"
        local Description = options.Description
        local Values = options.Values or {} -- Can be strings or {Value, Icon, Description, Group}
        local Default = options.Default
        local Multi = options.Multi or false
        local MaxVisibleItems = options.MaxVisibleItems or 6
        local Searchable = options.Searchable or false
        local Clearable = options.Clearable or false
        local Creatable = options.Creatable or false
        local Disabled = options.Disabled or false
        local Placeholder = options.Placeholder or "Select..."
        local Callback = options.Callback or function() end
        local Flag = options.Flag
        
        local self = setmetatable({}, Dropdown)
        
        self.Values = Values
        self.Multi = Multi
        self.Callback = Callback
        self.Open = false
        self.Options = {}
        self.Groups = {}
        self.MaxVisibleItems = MaxVisibleItems
        self.Searchable = Searchable
        self.Clearable = Clearable
        self.Creatable = Creatable
        self.Disabled = Disabled
        self.Placeholder = Placeholder
        self.Flag = Flag
        self.FilteredOptions = {}
        
        if Multi then
            self.Value = Default or {}
        else
            self.Value = Default or ""
        end
        
        local hasDescription = Description ~= nil
        local closedHeight = hasDescription and 50 or 38
        local optionHeight = 32
        local optionPadding = 4
        local searchHeight = Searchable and 36 or 0
        
        -- Helper to get option value from complex option
        local function getOptionValue(opt)
            if type(opt) == "table" then
                return opt.Value or opt[1]
            end
            return opt
        end
        
        local function getOptionIcon(opt)
            if type(opt) == "table" then
                return opt.Icon or opt[2]
            end
            return nil
        end
        
        local function getOptionDesc(opt)
            if type(opt) == "table" then
                return opt.Description or opt[3]
            end
            return nil
        end
        
        local function getOptionGroup(opt)
            if type(opt) == "table" then
                return opt.Group or opt[4]
            end
            return nil
        end
        
        -- Selected text display
        local function getSelectedText()
            if Multi then
                if #self.Value == 0 then
                    return self.Placeholder
                elseif #self.Value == 1 then
                    return tostring(self.Value[1])
                else
                    return string.format("%d selected", #self.Value)
                end
            else
                return self.Value == "" and self.Placeholder or tostring(self.Value)
            end
        end
        
        self.GetSelectedText = getSelectedText
        self.GetOptionValue = getOptionValue
        self.GetOptionIcon = getOptionIcon
        self.GetOptionDesc = getOptionDesc
        self.GetOptionGroup = getOptionGroup
        
        -- Title Label
        self.Label = Creator.New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
            Text = Title,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -160, 0, 16),
            Position = hasDescription and UDim2.fromOffset(14, 10) or UDim2.new(0, 14, 0.5, 0),
            AnchorPoint = hasDescription and Vector2.zero or Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            TextTransparency = Disabled and 0.5 or 0,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Description
        if hasDescription then
            self.DescriptionLabel = Creator.New("TextLabel", {
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                Text = Description,
                TextSize = 12,
                TextTransparency = Disabled and 0.6 or 0.4,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -160, 0, 14),
                Position = UDim2.fromOffset(14, 28),
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "SubText"}
            })
        end
        
        -- Selected value display
        self.SelectedLabel = Creator.New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            Text = getSelectedText(),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Size = UDim2.new(0, Clearable and 90 or 110, 0, 16),
            Position = UDim2.new(1, Clearable and -56 or -38, 0, hasDescription and 10 or 11),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            TextTransparency = Disabled and 0.5 or 0,
            ThemeTag = {TextColor3 = "SubText"}
        })
        
        -- Clear button
        if Clearable then
            self.ClearButton = Creator.New("TextButton", {
                Size = UDim2.fromOffset(16, 16),
                Position = UDim2.new(1, -36, 0, hasDescription and 10 or 11),
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Text = "",
                Visible = (Multi and #self.Value > 0) or (not Multi and self.Value ~= ""),
                ZIndex = 5
            }, {
                Creator.New("ImageLabel", {
                    Image = "rbxassetid://7743878326", -- X icon
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    ThemeTag = {ImageColor3 = "SubText"}
                })
            })
            
            Creator.AddSignal(self.ClearButton.MouseButton1Click, function()
                if not self.Disabled then
                    if Multi then
                        self.Value = {}
                    else
                        self.Value = ""
                    end
                    self:UpdateSelectedDisplay()
                    self:UpdateOptionVisuals()
                    self.Callback(self.Value)
                    self.ClearButton.Visible = false
                end
            end)
        end
        
        -- Arrow icon with rotation animation
        self.ArrowIcon = Creator.New("ImageLabel", {
            Image = "rbxassetid://10709790948",
            Size = UDim2.fromOffset(16, 16),
            Position = UDim2.new(1, -14, 0, hasDescription and 10 or 11),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            ImageTransparency = Disabled and 0.5 or 0,
            ThemeTag = {ImageColor3 = "SubText"}
        })
        
        -- Search input (if searchable)
        if Searchable then
            self.SearchContainer = Creator.New("Frame", {
                Size = UDim2.new(1, -16, 0, 32),
                Position = UDim2.fromOffset(8, 8),
                BackgroundTransparency = 0.9,
                ThemeTag = {BackgroundColor3 = "Element"}
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)}),
                Creator.New("UIStroke", {
                    Transparency = 0.6,
                    ThemeTag = {Color = "ElementBorder"}
                }),
                Creator.New("ImageLabel", {
                    Image = "rbxassetid://7734053495", -- Search icon
                    Size = UDim2.fromOffset(14, 14),
                    Position = UDim2.fromOffset(10, 9),
                    BackgroundTransparency = 1,
                    ThemeTag = {ImageColor3 = "SubText"}
                })
            })
            
            self.SearchInput = Creator.New("TextBox", {
                Size = UDim2.new(1, -36, 1, 0),
                Position = UDim2.fromOffset(28, 0),
                BackgroundTransparency = 1,
                Text = "",
                PlaceholderText = "Search...",
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                Parent = self.SearchContainer,
                ThemeTag = {TextColor3 = "Text", PlaceholderColor3 = "SubText"}
            })
            
            -- Search functionality
            Creator.AddSignal(self.SearchInput:GetPropertyChangedSignal("Text"), function()
                self:FilterOptions(self.SearchInput.Text)
            end)
        end
        
        -- Options List Layout
        self.OptionsLayout = Creator.New("UIListLayout", {
            Padding = UDim.new(0, optionPadding),
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center
        })
        
        -- Scrollable option list
        self.OptionsList = Creator.New("ScrollingFrame", {
            Size = UDim2.new(1, -16, 1, Searchable and -48 or -16),
            Position = UDim2.fromOffset(8, Searchable and 44 or 8),
            BackgroundTransparency = 1,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100),
            ScrollBarImageTransparency = 0.3,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.fromScale(0, 0),
            ClipsDescendants = true,
            BorderSizePixel = 0
        }, {
            self.OptionsLayout
        })
        
        -- Dropdown container
        local containerChildren = {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {
                Transparency = 0.5,
                Thickness = 1,
                ThemeTag = {Color = "Accent"}
            }),
            self.OptionsList
        }
        
        if Searchable then
            table.insert(containerChildren, self.SearchContainer)
        end
        
        self.OptionsContainer = Creator.New("Frame", {
            Size = UDim2.new(1, -16, 0, 0),
            Position = UDim2.new(0, 8, 0, closedHeight + 4),
            BackgroundTransparency = 0.05,
            ClipsDescendants = true,
            ZIndex = 100,
            ThemeTag = {BackgroundColor3 = "SecondaryElementBackground"}
        }, containerChildren)
        
        -- Main Frame
        local frameChildren = {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 10)}),
            Creator.New("UIStroke", {
                Transparency = 0.5,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                ThemeTag = {Color = "ElementBorder"}
            }),
            self.Label,
            hasDescription and self.DescriptionLabel or nil,
            self.SelectedLabel,
            Clearable and self.ClearButton or nil,
            self.ArrowIcon,
            self.OptionsContainer
        }
        
        self.Frame = Creator.New("TextButton", {
            Size = UDim2.new(1, 0, 0, closedHeight),
            BackgroundTransparency = 0.88,
            Text = "",
            ClipsDescendants = false,
            Parent = parent,
            AutoButtonColor = false,
            Active = not Disabled,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, frameChildren)
        
        -- Process and add all options (with group support)
        self:ProcessValues(Values)
        
        self.ClosedHeight = closedHeight
        self.OptionHeight = optionHeight
        self.OptionPadding = optionPadding
        self.SearchHeight = searchHeight
        
        -- Animation motors
        self.HeightMotor = Flipper.SingleMotor.new(closedHeight)
        self.HeightMotor:onStep(function(value)
            self.Frame.Size = UDim2.new(1, 0, 0, value)
        end)
        
        self.ArrowMotor = Flipper.SingleMotor.new(0)
        self.ArrowMotor:onStep(function(value)
            self.ArrowIcon.Rotation = value
        end)
        
        self.ContainerHeightMotor = Flipper.SingleMotor.new(0)
        self.ContainerHeightMotor:onStep(function(value)
            self.OptionsContainer.Size = UDim2.new(1, -16, 0, value)
        end)
        
        -- Click to toggle dropdown
        if not Disabled then
            Creator.AddSignal(self.Frame.MouseButton1Click, function()
                self:Toggle()
            end)
        end
        
        -- Hover effect
        self.HoverMotor, self.SetHover = Creator.SpringMotor(0.88, self.Frame, "BackgroundTransparency")
        
        if not Disabled then
            Creator.AddSignal(self.Frame.MouseEnter, function()
                self.SetHover(0.82)
            end)
            
            Creator.AddSignal(self.Frame.MouseLeave, function()
                if not self.Open then
                    self.SetHover(0.88)
                end
            end)
        end
        
        -- Close when clicking outside
        Creator.AddSignal(Services.UserInputService.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if self.Open then
                    local mousePos = input.Position
                    local framePos = self.Frame.AbsolutePosition
                    local frameSize = self.Frame.AbsoluteSize
                    
                    local isInside = mousePos.X >= framePos.X and 
                                     mousePos.X <= framePos.X + frameSize.X and
                                     mousePos.Y >= framePos.Y and 
                                     mousePos.Y <= framePos.Y + frameSize.Y
                    
                    if not isInside then
                        task.defer(function()
                            self:Toggle()
                        end)
                    end
                end
            end
        end)
        
        self.Root = self.Frame
        
        return self
    end
    
    -- Process values with group support
    function Dropdown:ProcessValues(values)
        local currentGroup = nil
        local layoutOrder = 0
        
        for i, opt in ipairs(values) do
            local value = self.GetOptionValue(opt)
            local icon = self.GetOptionIcon(opt)
            local desc = self.GetOptionDesc(opt)
            local group = self.GetOptionGroup(opt)
            
            -- Add group header if new group
            if group and group ~= currentGroup then
                currentGroup = group
                layoutOrder = layoutOrder + 1
                self:AddGroupHeader(group, layoutOrder)
            end
            
            layoutOrder = layoutOrder + 1
            self:AddOption(value, layoutOrder, icon, desc)
        end
    end
    
    -- Add group header
    function Dropdown:AddGroupHeader(groupName, order)
        local header = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            Parent = self.OptionsList,
            LayoutOrder = order
        }, {
            Creator.New("TextLabel", {
                Text = groupName:upper(),
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
                TextSize = 10,
                TextTransparency = 0.4,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -24, 1, 0),
                Position = UDim2.fromOffset(12, 0),
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "SubText"}
            })
        })
        
        self.Groups[groupName] = header
    end
    
    function Dropdown:AddOption(value, order, icon, desc)
        local isSelected = false
        if self.Multi then
            isSelected = table.find(self.Value, value) ~= nil
        else
            isSelected = self.Value == value
        end
        
        local hasIcon = icon ~= nil
        local hasDesc = desc ~= nil
        local optHeight = hasDesc and 44 or self.OptionHeight
        
        -- Resolve icon
        local iconAsset = nil
        if hasIcon then
            if type(icon) == "string" then
                if icon:match("^rbxassetid://") then
                    iconAsset = icon
                else
                    iconAsset = Icons.Get(icon) or Icons.Question
                end
            end
        end
        
        -- Option container
        local optionFrame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, optHeight),
            BackgroundTransparency = isSelected and 0.85 or 1,
            Parent = self.OptionsList,
            LayoutOrder = order or 0,
            ThemeTag = {BackgroundColor3 = isSelected and "Accent" or "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)}),
            Creator.New("UIPadding", {
                PaddingLeft = UDim.new(0, hasIcon and 6 or 12),
                PaddingRight = UDim.new(0, 12)
            })
        })
        
        -- Icon (if exists)
        local iconLabel = nil
        if hasIcon then
            iconLabel = Creator.New("ImageLabel", {
                Image = iconAsset,
                Size = UDim2.fromOffset(18, 18),
                Position = UDim2.new(0, 0, 0.5, hasDesc and -4 or 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                Parent = optionFrame,
                ThemeTag = {ImageColor3 = isSelected and "Accent" or "Text"}
            })
        end
        
        -- Option text label
        local optionLabel = Creator.New("TextLabel", {
            Text = tostring(value),
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            TextSize = 13,
            Size = UDim2.new(1, hasIcon and -50 or -30, 0, hasDesc and 16 or optHeight),
            Position = UDim2.fromOffset(hasIcon and 24 or 0, hasDesc and 6 or 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = optionFrame,
            ThemeTag = {TextColor3 = isSelected and "Accent" or "Text"}
        })
        
        -- Description (if exists)
        local descLabel = nil
        if hasDesc then
            descLabel = Creator.New("TextLabel", {
                Text = desc,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                TextSize = 11,
                TextTransparency = 0.4,
                Size = UDim2.new(1, hasIcon and -50 or -30, 0, 12),
                Position = UDim2.fromOffset(hasIcon and 24 or 0, 24),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = optionFrame,
                ThemeTag = {TextColor3 = "SubText"}
            })
        end
        
        -- Checkmark/selection indicator
        local checkmark
        if self.Multi then
            checkmark = Creator.New("ImageLabel", {
                Image = isSelected and "rbxassetid://10709790644" or "",
                Size = UDim2.fromOffset(16, 16),
                Position = UDim2.new(1, 0, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Parent = optionFrame,
                ThemeTag = {ImageColor3 = "Accent"}
            })
        else
            checkmark = Creator.New("Frame", {
                Size = UDim2.fromOffset(8, 8),
                Position = UDim2.new(1, 0, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = isSelected and 0 or 1,
                Parent = optionFrame,
                ThemeTag = {BackgroundColor3 = "Accent"}
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
            })
        end
        
        -- Hover button overlay
        local hoverButton = Creator.New("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            Parent = optionFrame,
            ZIndex = 2
        })
        
        -- Store reference
        self.Options[value] = {
            Frame = optionFrame,
            Button = hoverButton,
            Label = optionLabel,
            Icon = iconLabel,
            DescLabel = descLabel,
            Checkmark = checkmark,
            Selected = isSelected
        }
        
        -- Hover effects
        Creator.AddSignal(hoverButton.MouseEnter, function()
            if not self.Options[value].Selected then
                Creator.Tween(optionFrame, {BackgroundTransparency = 0.9}, 0.1)
            end
        end)
        
        Creator.AddSignal(hoverButton.MouseLeave, function()
            if not self.Options[value].Selected then
                Creator.Tween(optionFrame, {BackgroundTransparency = 1}, 0.1)
            end
        end)
        
        -- Selection handler
        Creator.AddSignal(hoverButton.MouseButton1Click, function()
            if self.Disabled then return end
            
            if self.Multi then
                local index = table.find(self.Value, value)
                if index then
                    table.remove(self.Value, index)
                    self.Options[value].Selected = false
                    Creator.Tween(optionFrame, {BackgroundTransparency = 1}, 0.15)
                    Creator.OverrideTag(optionFrame, {BackgroundColor3 = "Element"})
                    Creator.OverrideTag(optionLabel, {TextColor3 = "Text"})
                    if checkmark then checkmark.Image = "" end
                    if iconLabel then Creator.OverrideTag(iconLabel, {ImageColor3 = "Text"}) end
                else
                    table.insert(self.Value, value)
                    self.Options[value].Selected = true
                    Creator.Tween(optionFrame, {BackgroundTransparency = 0.85}, 0.15)
                    Creator.OverrideTag(optionFrame, {BackgroundColor3 = "Accent"})
                    Creator.OverrideTag(optionLabel, {TextColor3 = "Accent"})
                    if checkmark then checkmark.Image = "rbxassetid://10709790644" end
                    if iconLabel then Creator.OverrideTag(iconLabel, {ImageColor3 = "Accent"}) end
                end
                
                self:UpdateSelectedDisplay()
                self.Callback(self.Value)
            else
                -- Deselect all others first
                for v, opt in pairs(self.Options) do
                    if opt.Selected and v ~= value then
                        opt.Selected = false
                        Creator.Tween(opt.Frame, {BackgroundTransparency = 1}, 0.15)
                        Creator.OverrideTag(opt.Frame, {BackgroundColor3 = "Element"})
                        Creator.OverrideTag(opt.Label, {TextColor3 = "Text"})
                        if opt.Icon then Creator.OverrideTag(opt.Icon, {ImageColor3 = "Text"}) end
                        if opt.Checkmark and opt.Checkmark:IsA("Frame") then
                            opt.Checkmark.BackgroundTransparency = 1
                        end
                    end
                end
                
                -- Select current
                self.Value = value
                self.Options[value].Selected = true
                Creator.Tween(optionFrame, {BackgroundTransparency = 0.85}, 0.15)
                Creator.OverrideTag(optionFrame, {BackgroundColor3 = "Accent"})
                Creator.OverrideTag(optionLabel, {TextColor3 = "Accent"})
                if iconLabel then Creator.OverrideTag(iconLabel, {ImageColor3 = "Accent"}) end
                if checkmark and checkmark:IsA("Frame") then
                    checkmark.BackgroundTransparency = 0
                end
                
                self:UpdateSelectedDisplay()
                self.Callback(value)
                self:Toggle()
            end
            
            -- Update clear button visibility
            if self.ClearButton then
                self.ClearButton.Visible = (self.Multi and #self.Value > 0) or (not self.Multi and self.Value ~= "")
            end
        end)
        
        return optionFrame
    end
    
    -- Filter options based on search query
    function Dropdown:FilterOptions(query)
        query = query:lower()
        
        for value, opt in pairs(self.Options) do
            local visible = query == "" or tostring(value):lower():find(query, 1, true)
            opt.Frame.Visible = visible
        end
        
        -- Also handle group headers
        for groupName, header in pairs(self.Groups) do
            local hasVisibleItems = false
            for value, opt in pairs(self.Options) do
                if opt.Frame.Visible then
                    hasVisibleItems = true
                    break
                end
            end
            header.Visible = hasVisibleItems or query == ""
        end
    end
    
    function Dropdown:UpdateSelectedDisplay()
        self.SelectedLabel.Text = self.GetSelectedText()
    end
    
    function Dropdown:UpdateOptionVisuals()
        for value, opt in pairs(self.Options) do
            local isSelected = false
            if self.Multi then
                isSelected = table.find(self.Value, value) ~= nil
            else
                isSelected = self.Value == value
            end
            
            opt.Selected = isSelected
            opt.Frame.BackgroundTransparency = isSelected and 0.85 or 1
            Creator.OverrideTag(opt.Frame, {BackgroundColor3 = isSelected and "Accent" or "Element"})
            Creator.OverrideTag(opt.Label, {TextColor3 = isSelected and "Accent" or "Text"})
            if opt.Icon then Creator.OverrideTag(opt.Icon, {ImageColor3 = isSelected and "Accent" or "Text"}) end
            
            if self.Multi then
                if opt.Checkmark then opt.Checkmark.Image = isSelected and "rbxassetid://10709790644" or "" end
            else
                if opt.Checkmark and opt.Checkmark:IsA("Frame") then
                    opt.Checkmark.BackgroundTransparency = isSelected and 0 or 1
                end
            end
        end
    end
    
    function Dropdown:Toggle()
        if self.Disabled then return end
        
        self.Open = not self.Open
        
        if self.Open then
            local optionCount = 0
            for _ in pairs(self.Options) do optionCount = optionCount + 1 end
            
            local visibleCount = math.min(optionCount, self.MaxVisibleItems)
            local optionsHeight = visibleCount * (self.OptionHeight + self.OptionPadding) + 16
            if self.Searchable then
                optionsHeight = optionsHeight + 40
            end
            local totalHeight = self.ClosedHeight + optionsHeight + 8
            
            self.HeightMotor:setGoal(Flipper.Spring.new(totalHeight, {frequency = 6, dampingRatio = 0.8}))
            self.ContainerHeightMotor:setGoal(Flipper.Spring.new(optionsHeight, {frequency = 6, dampingRatio = 0.8}))
            self.ArrowMotor:setGoal(Flipper.Spring.new(180, {frequency = 6}))
            
            self.SetHover(0.82)
            
            -- Focus search if searchable
            if self.Searchable and self.SearchInput then
                task.defer(function()
                    self.SearchInput:CaptureFocus()
                end)
            end
        else
            self.HeightMotor:setGoal(Flipper.Spring.new(self.ClosedHeight, {frequency = 6, dampingRatio = 0.8}))
            self.ContainerHeightMotor:setGoal(Flipper.Spring.new(0, {frequency = 6, dampingRatio = 0.8}))
            self.ArrowMotor:setGoal(Flipper.Spring.new(0, {frequency = 6}))
            
            self.SetHover(0.88)
            
            -- Clear search
            if self.Searchable and self.SearchInput then
                self.SearchInput.Text = ""
                self:FilterOptions("")
            end
        end
    end
    
    function Dropdown:Set(value, noCallback)
        if self.Disabled then return end
        
        if self.Multi then
            self.Value = type(value) == "table" and value or {value}
        else
            self.Value = value
        end
        
        self:UpdateSelectedDisplay()
        self:UpdateOptionVisuals()
        
        if self.ClearButton then
            self.ClearButton.Visible = (self.Multi and #self.Value > 0) or (not self.Multi and self.Value ~= "")
        end
        
        if not noCallback then
            self.Callback(self.Value)
        end
    end
    
    function Dropdown:SetDisabled(disabled)
        self.Disabled = disabled
        self.Frame.Active = not disabled
        
        if self.Label then
            self.Label.TextTransparency = disabled and 0.5 or 0
        end
        
        if self.DescriptionLabel then
            self.DescriptionLabel.TextTransparency = disabled and 0.6 or 0.4
        end
        
        if self.SelectedLabel then
            self.SelectedLabel.TextTransparency = disabled and 0.5 or 0
        end
        
        if self.ArrowIcon then
            self.ArrowIcon.ImageTransparency = disabled and 0.5 or 0
        end
    end
    
    function Dropdown:GetValue()
        return self.Value
    end
    
    function Dropdown:SetValues(values)
        -- Clear existing
        for _, opt in pairs(self.Options) do
            if opt.Frame then opt.Frame:Destroy() end
        end
        for _, header in pairs(self.Groups) do
            if header then header:Destroy() end
        end
        self.Options = {}
        self.Groups = {}
        
        self.Values = values
        self:ProcessValues(values)
        
        -- Reset selection if needed
        if self.Multi then
            local validValues = {}
            for _, v in ipairs(self.Value) do
                if self.Options[v] then
                    table.insert(validValues, v)
                end
            end
            self.Value = validValues
        else
            if not self.Options[self.Value] then
                self.Value = ""
            end
        end
        
        self:UpdateSelectedDisplay()
    end
    
    function Dropdown:Destroy()
        if self.Frame then
            self.Frame:Destroy()
        end
    end
    
    return Dropdown
    
end

-- Module: Elements/FrameAnimation
_modules["Elements/FrameAnimation"] = function()
    --[[
        NexusUI Frame Animation (Image Sequence Video)
        Play video as image sequences at configurable FPS
        Perfect for executors that don't support VideoFrame
    ]]
    
    local FrameAnimation = {}
    FrameAnimation.__index = FrameAnimation
    
    local Creator, Services
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Services = _require("Core/Services")
    end
    
    --[[
        Creates a new frame-based animation
        
        @param parent - Parent GUI element
        @param options - Configuration table:
            - Title: Display title
            - Frames: Array of image IDs/URLs (the "video" frames)
            - FPS: Frames per second (default 12)
            - Size: UDim2 size (default fills parent)
            - AutoPlay: Start playing immediately
            - Looped: Loop the animation
            - OnComplete: Callback when finished
    ]]
    function FrameAnimation.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title
        local Frames = options.Frames or {}
        local FPS = options.FPS or 12
        local Size = options.Size or UDim2.new(1, -24, 0, 150)
        local AutoPlay = options.AutoPlay or false
        local Looped = options.Looped or false
        local ShowControls = options.Controls ~= false
        local OnComplete = options.OnComplete
        
        local self = setmetatable({}, FrameAnimation)
        
        self.Frames = Frames
        self.FPS = FPS
        self.CurrentFrame = 1
        self.Playing = false
        self.Looped = Looped
        self.OnComplete = OnComplete
        
        local hasTitle = Title ~= nil
        local height = Size.Y.Offset + (hasTitle and 40 or 0) + (ShowControls and 40 or 0)
        
        -- Title
        if hasTitle then
            self.TitleLabel = Creator.New("TextLabel", {
                Size = UDim2.new(1, -24, 0, 20),
                Position = UDim2.fromOffset(12, 8),
                Text = Title,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "Text"}
            })
        end
        
        -- Image display
        self.ImageDisplay = Creator.New("ImageLabel", {
            Size = Size,
            Position = UDim2.fromOffset(12, hasTitle and 34 or 12),
            Image = Frames[1] and (type(Frames[1]) == "number" and ("rbxassetid://" .. Frames[1]) or Frames[1]) or "",
            ScaleType = Enum.ScaleType.Fit,
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.5
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)})
        })
        
        -- Controls
        if ShowControls then
            self.ControlsFrame = Creator.New("Frame", {
                Size = UDim2.new(1, -24, 0, 32),
                Position = UDim2.new(0, 12, 1, -40),
                BackgroundTransparency = 1
            })
            
            -- Play button
            self.PlayButton = Creator.New("TextButton", {
                Size = UDim2.fromOffset(32, 32),
                Text = "▶",
                TextSize = 14,
                Parent = self.ControlsFrame,
                ThemeTag = {BackgroundColor3 = "Element", TextColor3 = "Text"}
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)})
            })
            
            -- Frame counter
            self.FrameCounter = Creator.New("TextLabel", {
                Size = UDim2.fromOffset(80, 32),
                Position = UDim2.fromOffset(40, 0),
                Text = "1 / " .. #Frames,
                TextSize = 12,
                BackgroundTransparency = 1,
                Parent = self.ControlsFrame,
                ThemeTag = {TextColor3 = "SubText"}
            })
            
            -- Progress bar
            self.ProgressBar = Creator.New("Frame", {
                Size = UDim2.new(1, -140, 0, 6),
                Position = UDim2.new(0, 125, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 0.7,
                Parent = self.ControlsFrame,
                ThemeTag = {BackgroundColor3 = "SliderBackground"}
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
            })
            
            self.ProgressFill = Creator.New("Frame", {
                Size = UDim2.fromScale(0, 1),
                Parent = self.ProgressBar,
                ThemeTag = {BackgroundColor3 = "SliderProgress"}
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
            })
            
            -- Play button handler
            Creator.AddSignal(self.PlayButton.MouseButton1Click, function()
                if self.Playing then
                    self:Pause()
                else
                    self:Play()
                end
            end)
            
            -- Click progress to seek
            Creator.AddSignal(self.ProgressBar.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local relX = (input.Position.X - self.ProgressBar.AbsolutePosition.X) / self.ProgressBar.AbsoluteSize.X
                    self:GoToFrame(math.ceil(relX * #self.Frames))
                end
            end)
        end
        
        -- Main frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 0.89,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {
                Transparency = 0.5,
                ThemeTag = {Color = "ElementBorder"}
            }),
            hasTitle and self.TitleLabel or nil,
            self.ImageDisplay,
            ShowControls and self.ControlsFrame or nil
        })
        
        -- Auto play
        if AutoPlay then
            task.defer(function()
                self:Play()
            end)
        end
        
        self.Root = self.Frame
        
        return self
    end
    
    function FrameAnimation:Play()
        if #self.Frames == 0 then return end
        
        self.Playing = true
        if self.PlayButton then
            self.PlayButton.Text = "⏸"
        end
        
        -- Animation loop
        task.spawn(function()
            local frameDelay = 1 / self.FPS
            
            while self.Playing do
                -- Update image
                local frame = self.Frames[self.CurrentFrame]
                self.ImageDisplay.Image = type(frame) == "number" and ("rbxassetid://" .. frame) or frame
                
                -- Update UI
                if self.FrameCounter then
                    self.FrameCounter.Text = self.CurrentFrame .. " / " .. #self.Frames
                end
                if self.ProgressFill then
                    self.ProgressFill.Size = UDim2.fromScale(self.CurrentFrame / #self.Frames, 1)
                end
                
                -- Wait for next frame
                task.wait(frameDelay)
                
                -- Advance frame
                self.CurrentFrame = self.CurrentFrame + 1
                
                if self.CurrentFrame > #self.Frames then
                    if self.Looped then
                        self.CurrentFrame = 1
                    else
                        self.Playing = false
                        self.CurrentFrame = #self.Frames
                        if self.PlayButton then
                            self.PlayButton.Text = "▶"
                        end
                        if self.OnComplete then
                            self.OnComplete()
                        end
                    end
                end
            end
        end)
    end
    
    function FrameAnimation:Pause()
        self.Playing = false
        if self.PlayButton then
            self.PlayButton.Text = "▶"
        end
    end
    
    function FrameAnimation:Stop()
        self.Playing = false
        self.CurrentFrame = 1
        self:UpdateDisplay()
        if self.PlayButton then
            self.PlayButton.Text = "▶"
        end
    end
    
    function FrameAnimation:GoToFrame(frameIndex)
        frameIndex = math.clamp(frameIndex, 1, #self.Frames)
        self.CurrentFrame = frameIndex
        self:UpdateDisplay()
    end
    
    function FrameAnimation:UpdateDisplay()
        local frame = self.Frames[self.CurrentFrame]
        if frame then
            self.ImageDisplay.Image = type(frame) == "number" and ("rbxassetid://" .. frame) or frame
        end
        if self.FrameCounter then
            self.FrameCounter.Text = self.CurrentFrame .. " / " .. #self.Frames
        end
        if self.ProgressFill then
            self.ProgressFill.Size = UDim2.fromScale(self.CurrentFrame / #self.Frames, 1)
        end
    end
    
    function FrameAnimation:SetFPS(fps)
        self.FPS = math.clamp(fps, 1, 60)
    end
    
    function FrameAnimation:SetFrames(frames)
        self.Frames = frames
        self.CurrentFrame = 1
        self:UpdateDisplay()
    end
    
    -- Static helper: Generate frame IDs from a base ID pattern
    function FrameAnimation.GenerateFrameIds(baseId, count, padding)
        padding = padding or 3
        local frames = {}
        for i = 1, count do
            local frameNum = string.format("%0" .. padding .. "d", i)
            table.insert(frames, baseId .. frameNum)
        end
        return frames
    end
    
    return FrameAnimation
    
end

-- Module: Elements/Grid
_modules["Elements/Grid"] = function()
    --[[
        NexusUI Grid Element
        Grid layout for items
    ]]
    
    local Grid = {}
    Grid.__index = Grid
    
    local Creator, ImageLoader
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        ImageLoader = _require("Utils/ImageLoader")
    end
    
    function Grid.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title
        local Items = options.Items or {}
        local Columns = options.Columns or 3
        local ItemHeight = options.ItemHeight or 100
        local Gap = options.Gap or 8
        local MaxRows = options.MaxRows or 3
        local OnItemClick = options.OnItemClick or function() end
        
        local self = setmetatable({}, Grid)
        self.Items = Items
        self.OnItemClick = OnItemClick
        
        local hasTitle = Title ~= nil
        local rows = math.ceil(#Items / Columns)
        local visibleRows = math.min(rows, MaxRows)
        local gridHeight = visibleRows * (ItemHeight + Gap) - Gap
        
        -- Title
        if hasTitle then
            self.TitleLabel = Creator.New("TextLabel", {
                Size = UDim2.new(1, -24, 0, 20),
                Position = UDim2.fromOffset(12, 8),
                Text = Title,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "Text"}
            })
        end
        
        -- Grid container
        self.GridContainer = Creator.New("ScrollingFrame", {
            Size = UDim2.new(1, -24, 0, gridHeight),
            Position = UDim2.fromOffset(12, hasTitle and 32 or 8),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            CanvasSize = UDim2.fromOffset(0, rows * (ItemHeight + Gap)),
            ThemeTag = {ScrollBarImageColor3 = "Text"}
        }, {
            Creator.New("UIGridLayout", {
                CellSize = UDim2.new(1 / Columns, -(Gap * (Columns - 1) / Columns), 0, ItemHeight),
                CellPadding = UDim2.fromOffset(Gap, Gap)
            })
        })
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, (hasTitle and 36 or 12) + gridHeight),
            BackgroundTransparency = 0.89,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {Transparency = 0.5, ThemeTag = {Color = "ElementBorder"}}),
            hasTitle and self.TitleLabel or nil,
            self.GridContainer
        })
        
        self.Columns = Columns
        self.ItemHeight = ItemHeight
        self.Gap = Gap
        
        self:Render()
        
        self.Root = self.Frame
        return self
    end
    
    function Grid:Render()
        -- Clear existing
        for _, child in ipairs(self.GridContainer:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        
        for i, item in ipairs(self.Items) do
            local itemFrame = Creator.New("Frame", {
                BackgroundTransparency = 0.9,
                Parent = self.GridContainer,
                ThemeTag = {BackgroundColor3 = "Element"}
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)})
            })
            
            -- Image
            if item.Image then
                local img = Creator.New("ImageLabel", {
                    Size = UDim2.new(1, 0, 1, item.Title and -24 or 0),
                    ScaleType = Enum.ScaleType.Crop,
                    BackgroundTransparency = 1,
                    Parent = itemFrame
                }, {
                    Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)})
                })
                ImageLoader.SetImage(img, item.Image)
            end
            
            -- Title
            if item.Title then
                Creator.New("TextLabel", {
                    Size = UDim2.new(1, -8, 0, 20),
                    Position = UDim2.new(0, 4, 1, -22),
                    Text = item.Title,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                    TextSize = 12,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    BackgroundTransparency = 1,
                    Parent = itemFrame,
                    ThemeTag = {TextColor3 = "Text"}
                })
            end
            
            -- Click
            local btn = Creator.New("TextButton", {
                Size = UDim2.fromScale(1, 1),
                Text = "",
                BackgroundTransparency = 1,
                Parent = itemFrame
            })
            
            Creator.AddSignal(btn.MouseButton1Click, function()
                self.OnItemClick(i, item)
            end)
            
            -- Hover effect
            Creator.AddSignal(btn.MouseEnter, function()
                Creator.Tween(itemFrame, {BackgroundTransparency = 0.8}, 0.15)
            end)
            Creator.AddSignal(btn.MouseLeave, function()
                Creator.Tween(itemFrame, {BackgroundTransparency = 0.9}, 0.15)
            end)
        end
    end
    
    function Grid:SetItems(items)
        self.Items = items
        self:Render()
    end
    
    function Grid:AddItem(item)
        table.insert(self.Items, item)
        self:Render()
    end
    
    return Grid
    
end

-- Module: Elements/ImageButton
_modules["Elements/ImageButton"] = function()
    --[[
        NexusUI Image Button Element
        Clickable image with hover effects and badges
    ]]
    
    local ImageButton = {}
    ImageButton.__index = ImageButton
    
    local Creator, Flipper, Animate
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Flipper = _require("Packages/Flipper")
        Animate = _require("Utils/Animate")
    end
    
    function ImageButton.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title
        local Description = options.Description
        local Image = options.Image
        local ImageSize = options.ImageSize or UDim2.fromOffset(50, 50)
        local Badge = options.Badge -- Number or text for badge
        local BadgeColor = options.BadgeColor or Color3.fromRGB(255, 60, 60)
        local HoverImage = options.HoverImage
        local Callback = options.Callback or function() end
        
        local self = setmetatable({}, ImageButton)
        
        self.Image = Image
        self.HoverImage = HoverImage
        self.Callback = Callback
        
        local hasTitle = Title ~= nil
        local hasDescription = Description ~= nil
        local height = hasDescription and 60 or (hasTitle and 50 or 60)
        
        -- Image
        self.ImageLabel = Creator.New("ImageLabel", {
            Size = ImageSize,
            Position = UDim2.new(0, 12, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Image = type(Image) == "number" and ("rbxassetid://" .. Image) or Image,
            ScaleType = Enum.ScaleType.Fit,
            BackgroundTransparency = 1
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)})
        })
        
        -- Badge
        if Badge then
            self.BadgeLabel = Creator.New("TextLabel", {
                Size = UDim2.fromOffset(20, 20),
                Position = UDim2.new(1, -2, 0, -2),
                AnchorPoint = Vector2.new(1, 0),
                Text = tostring(Badge),
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
                TextSize = 11,
                TextColor3 = Color3.new(1, 1, 1),
                BackgroundColor3 = BadgeColor,
                Parent = self.ImageLabel
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
            })
        end
        
        local textX = 12 + ImageSize.X.Offset + 12
        
        -- Title
        if hasTitle then
            self.TitleLabel = Creator.New("TextLabel", {
                Size = UDim2.new(1, -textX - 12, 0, 18),
                Position = hasDescription and UDim2.fromOffset(textX, 12) or UDim2.new(0, textX, 0.5, 0),
                AnchorPoint = hasDescription and Vector2.zero or Vector2.new(0, 0.5),
                Text = Title,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "Text"}
            })
        end
        
        -- Description
        if hasDescription then
            self.DescriptionLabel = Creator.New("TextLabel", {
                Size = UDim2.new(1, -textX - 12, 0, 14),
                Position = UDim2.fromOffset(textX, 32),
                Text = Description,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTransparency = 0.4,
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "SubText"}
            })
        end
        
        -- Button frame
        self.Frame = Creator.New("TextButton", {
            Size = UDim2.new(1, 0, 0, height),
            Text = "",
            BackgroundTransparency = 0.89,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {
                Transparency = 0.5,
                ThemeTag = {Color = "ElementBorder"}
            }),
            self.ImageLabel,
            hasTitle and self.TitleLabel or nil,
            hasDescription and self.DescriptionLabel or nil
        })
        
        -- Hover animation
        self.HoverMotor, self.SetHover = Creator.SpringMotor(0.89, self.Frame, "BackgroundTransparency")
        
        Creator.AddSignal(self.Frame.MouseEnter, function()
            self.SetHover(0.82)
            Animate.Tween(self.ImageLabel, {Size = UDim2.fromOffset(ImageSize.X.Offset * 1.05, ImageSize.Y.Offset * 1.05)}, 0.2, "Bounce")
            if self.HoverImage then
                self.ImageLabel.Image = type(self.HoverImage) == "number" and ("rbxassetid://" .. self.HoverImage) or self.HoverImage
            end
        end)
        
        Creator.AddSignal(self.Frame.MouseLeave, function()
            self.SetHover(0.89)
            Animate.Tween(self.ImageLabel, {Size = ImageSize}, 0.2, "Smooth")
            if self.HoverImage then
                self.ImageLabel.Image = type(self.Image) == "number" and ("rbxassetid://" .. self.Image) or self.Image
            end
        end)
        
        -- Click
        Creator.AddSignal(self.Frame.MouseButton1Click, function()
            Animate.Pop(self.ImageLabel, 0.9, 0.1)
            self.Callback()
        end)
        
        self.Root = self.Frame
        
        return self
    end
    
    function ImageButton:SetImage(image)
        self.Image = image
        self.ImageLabel.Image = type(image) == "number" and ("rbxassetid://" .. image) or image
    end
    
    function ImageButton:SetBadge(value)
        if self.BadgeLabel then
            self.BadgeLabel.Text = tostring(value)
            self.BadgeLabel.Visible = value ~= nil and value ~= 0
        end
    end
    
    return ImageButton
    
end

-- Module: Elements/ImageGallery
_modules["Elements/ImageGallery"] = function()
    --[[
        NexusUI Image Gallery Element
        Display images in carousel, grid, or slideshow
    ]]
    
    local ImageGallery = {}
    ImageGallery.__index = ImageGallery
    
    local Creator, Flipper, Services
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Flipper = _require("Packages/Flipper")
        Services = _require("Core/Services")
    end
    
    function ImageGallery.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Gallery"
        local Images = options.Images or {} -- Array of image IDs or URLs
        local Style = options.Style or "Carousel" -- Carousel, Grid, Slideshow
        local ImageSize = options.ImageSize or UDim2.fromOffset(200, 120)
        local AutoPlay = options.AutoPlay or false
        local Interval = options.Interval or 5
        local Callback = options.Callback or function() end
        
        local self = setmetatable({}, ImageGallery)
        self.Images = Images
        self.CurrentIndex = 1
        self.Style = Style
        self.AutoPlay = AutoPlay
        self.Playing = AutoPlay
        
        local height = Style == "Grid" and 180 or 180
        
        -- Title
        self.TitleLabel = Creator.New("TextLabel", {
            Size = UDim2.new(1, -12, 0, 20),
            Position = UDim2.fromOffset(12, 8),
            Text = Title,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Image container
        self.ImageContainer = Creator.New("Frame", {
            Size = UDim2.new(1, -24, 0, 120),
            Position = UDim2.fromOffset(12, 34),
            BackgroundTransparency = 1,
            ClipsDescendants = true
        })
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 0.89,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {
                Transparency = 0.5,
                ThemeTag = {Color = "ElementBorder"}
            }),
            self.TitleLabel,
            self.ImageContainer
        })
        
        if Style == "Carousel" then
            self:CreateCarousel()
        elseif Style == "Grid" then
            self:CreateGrid()
        elseif Style == "Slideshow" then
            self:CreateSlideshow()
        end
        
        -- Navigation dots
        if #Images > 1 and Style ~= "Grid" then
            self:CreateDots()
        end
        
        -- Auto play
        if AutoPlay and Style ~= "Grid" then
            self:StartAutoPlay()
        end
        
        self.Root = self.Frame
        
        return self
    end
    
    function ImageGallery:CreateCarousel()
        -- Carousel layout
        local layout = Creator.New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        
        self.CarouselHolder = Creator.New("Frame", {
            Size = UDim2.new(0, #self.Images * 160, 1, 0),
            BackgroundTransparency = 1,
            Parent = self.ImageContainer
        }, {layout})
        
        for i, img in ipairs(self.Images) do
            local imgFrame = Creator.New("ImageButton", {
                Size = UDim2.fromOffset(150, 100),
                Image = type(img) == "number" and ("rbxassetid://" .. img) or img,
                ScaleType = Enum.ScaleType.Crop,
                Parent = self.CarouselHolder
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)})
            })
            
            Creator.AddSignal(imgFrame.MouseButton1Click, function()
                self:OpenFullscreen(i)
            end)
        end
        
        -- Navigation arrows
        self:CreateNavArrows()
    end
    
    function ImageGallery:CreateGrid()
        local layout = Creator.New("UIGridLayout", {
            CellSize = UDim2.fromOffset(80, 60),
            CellPadding = UDim2.fromOffset(8, 8),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        
        local gridHolder = Creator.New("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Parent = self.ImageContainer
        }, {layout})
        
        for i, img in ipairs(self.Images) do
            local imgFrame = Creator.New("ImageButton", {
                Image = type(img) == "number" and ("rbxassetid://" .. img) or img,
                ScaleType = Enum.ScaleType.Crop,
                Parent = gridHolder
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(0, 4)})
            })
            
            Creator.AddSignal(imgFrame.MouseButton1Click, function()
                self:OpenFullscreen(i)
            end)
        end
    end
    
    function ImageGallery:CreateSlideshow()
        self.SlideshowImage = Creator.New("ImageLabel", {
            Size = UDim2.fromScale(1, 1),
            Image = self.Images[1] and (type(self.Images[1]) == "number" and ("rbxassetid://" .. self.Images[1]) or self.Images[1]) or "",
            ScaleType = Enum.ScaleType.Fit,
            BackgroundTransparency = 1,
            Parent = self.ImageContainer
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)})
        })
        
        self:CreateNavArrows()
    end
    
    function ImageGallery:CreateNavArrows()
        -- Left arrow
        self.LeftArrow = Creator.New("TextButton", {
            Size = UDim2.fromOffset(30, 30),
            Position = UDim2.new(0, 5, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Text = "◀",
            TextSize = 16,
            BackgroundTransparency = 0.5,
            Parent = self.ImageContainer,
            ThemeTag = {BackgroundColor3 = "Background", TextColor3 = "Text"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
        })
        
        -- Right arrow
        self.RightArrow = Creator.New("TextButton", {
            Size = UDim2.fromOffset(30, 30),
            Position = UDim2.new(1, -5, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            Text = "▶",
            TextSize = 16,
            BackgroundTransparency = 0.5,
            Parent = self.ImageContainer,
            ThemeTag = {BackgroundColor3 = "Background", TextColor3 = "Text"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
        })
        
        Creator.AddSignal(self.LeftArrow.MouseButton1Click, function()
            self:Previous()
        end)
        
        Creator.AddSignal(self.RightArrow.MouseButton1Click, function()
            self:Next()
        end)
    end
    
    function ImageGallery:CreateDots()
        self.DotsHolder = Creator.New("Frame", {
            Size = UDim2.new(0, #self.Images * 14, 0, 10),
            Position = UDim2.new(0.5, 0, 1, -20),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Parent = self.Frame
        }, {
            Creator.New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 6),
                HorizontalAlignment = Enum.HorizontalAlignment.Center
            })
        })
        
        self.Dots = {}
        for i = 1, #self.Images do
            local dot = Creator.New("Frame", {
                Size = UDim2.fromOffset(8, 8),
                BackgroundColor3 = i == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100),
                BackgroundTransparency = i == 1 and 0 or 0.5,
                Parent = self.DotsHolder
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
            })
            table.insert(self.Dots, dot)
        end
    end
    
    function ImageGallery:UpdateDots()
        if not self.Dots then return end
        for i, dot in ipairs(self.Dots) do
            Creator.Tween(dot, {
                BackgroundColor3 = i == self.CurrentIndex and Color3.new(1, 1, 1) or Color3.fromRGB(100, 100, 100),
                BackgroundTransparency = i == self.CurrentIndex and 0 or 0.5
            }, 0.2)
        end
    end
    
    function ImageGallery:GoTo(index)
        index = math.clamp(index, 1, #self.Images)
        self.CurrentIndex = index
        
        if self.Style == "Carousel" and self.CarouselHolder then
            Creator.Tween(self.CarouselHolder, {
                Position = UDim2.fromOffset(-(index - 1) * 160, 0)
            }, 0.3)
        elseif self.Style == "Slideshow" and self.SlideshowImage then
            Creator.Tween(self.SlideshowImage, {ImageTransparency = 1}, 0.2, nil, nil, function()
                local img = self.Images[index]
                self.SlideshowImage.Image = type(img) == "number" and ("rbxassetid://" .. img) or img
                Creator.Tween(self.SlideshowImage, {ImageTransparency = 0}, 0.2)
            end)
        end
        
        self:UpdateDots()
    end
    
    function ImageGallery:Next()
        local next = self.CurrentIndex + 1
        if next > #self.Images then next = 1 end
        self:GoTo(next)
    end
    
    function ImageGallery:Previous()
        local prev = self.CurrentIndex - 1
        if prev < 1 then prev = #self.Images end
        self:GoTo(prev)
    end
    
    function ImageGallery:StartAutoPlay()
        self.Playing = true
        task.spawn(function()
            while self.Playing and self.Frame and self.Frame.Parent do
                task.wait(self.Interval or 5)
                if self.Playing then self:Next() end
            end
        end)
    end
    
    function ImageGallery:StopAutoPlay()
        self.Playing = false
    end
    
    function ImageGallery:OpenFullscreen(index)
        -- Fullscreen viewer
        local screenGui = self.Frame:FindFirstAncestorWhichIsA("ScreenGui")
        if not screenGui then return end
        
        local img = self.Images[index]
        
        local overlay = Creator.New("TextButton", {
            Size = UDim2.fromScale(1, 1),
            Text = "",
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.3,
            Parent = screenGui
        })
        
        local fullImage = Creator.New("ImageLabel", {
            Size = UDim2.new(0.8, 0, 0.8, 0),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Image = type(img) == "number" and ("rbxassetid://" .. img) or img,
            ScaleType = Enum.ScaleType.Fit,
            BackgroundTransparency = 1,
            Parent = overlay
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 12)})
        })
        
        Creator.AddSignal(overlay.MouseButton1Click, function()
            overlay:Destroy()
        end)
    end
    
    function ImageGallery:SetImages(images)
        self.Images = images
        -- Rebuild gallery
    end
    
    return ImageGallery
    
end

-- Module: Elements/Input
_modules["Elements/Input"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                   Input Component v2.15                       ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        Features:
        • Validation with custom rules
        • Input types: text, password, email, number, url
        • Password visibility toggle
        • Character counter
        • Icons (prefix/suffix)
        • Clear button
        • Autosuggest/autocomplete
        • Disabled and readonly states
        • Error and success states
    ]]
    
    local Input = {}
    Input.__index = Input
    
    local Creator
    local Flipper
    local Services
    local Icons
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Flipper = _require("Packages/Flipper")
        Services = _require("Core/Services")
        Icons = _require("Utils/Icons")
    end
    
    -- Validation patterns
    local ValidationPatterns = {
        email = "^[%w%.%-_]+@[%w%.%-]+%.[%a]+$",
        url = "^https?://[%w%.%-]+[%w/%.%-_]*$",
        alphanumeric = "^[%w]+$",
        alpha = "^[%a]+$"
    }
    
    function Input.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Input"
        local Description = options.Description
        local Default = options.Default or ""
        local Placeholder = options.Placeholder or "Enter text..."
        local Numeric = options.Numeric or false
        local Finished = options.Finished or false
        local Callback = options.Callback or function() end
        local InputType = options.InputType or "text" -- text, password, email, number, url
        local MaxLength = options.MaxLength
        local MinLength = options.MinLength
        local ShowCharCount = options.ShowCharCount or false
        local Clearable = options.Clearable or false
        local Icon = options.Icon
        local IconPosition = options.IconPosition or "left"
        local Validation = options.Validation -- function(value) return isValid, errorMessage end
        local Pattern = options.Pattern -- regex pattern for validation
        local Required = options.Required or false
        local Disabled = options.Disabled or false
        local Readonly = options.Readonly or false
        local Suggestions = options.Suggestions or {} -- autocomplete suggestions
        local Flag = options.Flag
        
        local self = setmetatable({}, Input)
        
        self.Value = Default
        self.Callback = Callback
        self.Numeric = Numeric or (InputType == "number")
        self.InputType = InputType
        self.MaxLength = MaxLength
        self.MinLength = MinLength
        self.Validation = Validation
        self.Pattern = Pattern
        self.Required = Required
        self.Disabled = Disabled
        self.Readonly = Readonly
        self.Suggestions = Suggestions
        self.IsPasswordVisible = false
        self.IsValid = true
        self.ErrorMessage = nil
        self.Flag = Flag
        
        local hasDescription = Description ~= nil
        local hasIcon = Icon ~= nil
        local height = hasDescription and 48 or 36
        
        -- Resolve icon
        local iconAsset = nil
        if hasIcon then
            if type(Icon) == "string" then
                if Icon:match("^rbxassetid://") then
                    iconAsset = Icon
                else
                    iconAsset = Icons.Get(Icon) or Icons.Question
                end
            end
        end
        
        -- Calculate input width considering icons and buttons
        local inputWidthOffset = -24
        local inputXOffset = 8
        
        if hasIcon and IconPosition == "left" then
            inputWidthOffset = inputWidthOffset - 22
            inputXOffset = inputXOffset + 22
        end
        if hasIcon and IconPosition == "right" then
            inputWidthOffset = inputWidthOffset - 22
        end
        if InputType == "password" then
            inputWidthOffset = inputWidthOffset - 26
        end
        if Clearable then
            inputWidthOffset = inputWidthOffset - 22
        end
        
        -- Icon element
        if hasIcon then
            local iconPos = IconPosition == "left" 
                and UDim2.fromOffset(8, 0) 
                or UDim2.new(1, InputType == "password" and -52 or (Clearable and -32 or -8), 0, 0)
            
            self.IconLabel = Creator.New("ImageLabel", {
                Image = iconAsset,
                Size = UDim2.fromOffset(16, 16),
                Position = UDim2.new(iconPos.X.Scale, iconPos.X.Offset, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                ImageTransparency = Disabled and 0.5 or 0,
                ThemeTag = {ImageColor3 = "SubText"}
            })
        end
        
        -- Input box
        self.InputBox = Creator.New("TextBox", {
            Size = UDim2.new(1, inputWidthOffset, 1, 0),
            Position = UDim2.fromOffset(inputXOffset, 0),
            Text = InputType == "password" and string.rep("•", #Default) or Default,
            PlaceholderText = Placeholder,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            ClearTextOnFocus = false,
            ClipsDescendants = true,
            TextEditable = not Disabled and not Readonly,
            TextTransparency = Disabled and 0.5 or 0,
            ThemeTag = {
                TextColor3 = "Text",
                PlaceholderColor3 = "PlaceholderColor"
            }
        })
        
        -- Store actual value for password type
        if InputType == "password" then
            self.ActualValue = Default
        end
        
        -- Password visibility toggle
        if InputType == "password" then
            self.PasswordToggle = Creator.New("TextButton", {
                Size = UDim2.fromOffset(20, 20),
                Position = UDim2.new(1, Clearable and -28 or -6, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 5
            }, {
                Creator.New("ImageLabel", {
                    Name = "Icon",
                    Image = "rbxassetid://7734033565", -- Eye icon
                    Size = UDim2.fromOffset(16, 16),
                    Position = UDim2.fromScale(0.5, 0.5),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    ThemeTag = {ImageColor3 = "SubText"}
                })
            })
            
            Creator.AddSignal(self.PasswordToggle.MouseButton1Click, function()
                if not self.Disabled then
                    self.IsPasswordVisible = not self.IsPasswordVisible
                    local iconLabel = self.PasswordToggle:FindFirstChild("Icon")
                    if iconLabel then
                        iconLabel.Image = self.IsPasswordVisible 
                            and "rbxassetid://7734033445" -- Eye off
                            or "rbxassetid://7734033565" -- Eye
                    end
                    self.InputBox.Text = self.IsPasswordVisible 
                        and self.ActualValue 
                        or string.rep("•", #self.ActualValue)
                end
            end)
        end
        
        -- Clear button
        if Clearable then
            self.ClearButton = Creator.New("TextButton", {
                Size = UDim2.fromOffset(16, 16),
                Position = UDim2.new(1, -6, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Text = "",
                Visible = #Default > 0,
                ZIndex = 5
            }, {
                Creator.New("ImageLabel", {
                    Image = "rbxassetid://7743878326", -- X icon
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    ThemeTag = {ImageColor3 = "SubText"}
                })
            })
            
            Creator.AddSignal(self.ClearButton.MouseButton1Click, function()
                if not self.Disabled and not self.Readonly then
                    self:Set("")
                    self.InputBox:CaptureFocus()
                end
            end)
        end
        
        -- Input container with border
        local inputChildren = {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)}),
            Creator.New("UIStroke", {
                Name = "InputStroke",
                Transparency = 0.6,
                ThemeTag = {Color = "InputStroke"}
            }),
            self.InputBox,
            hasIcon and self.IconLabel or nil,
            InputType == "password" and self.PasswordToggle or nil,
            Clearable and self.ClearButton or nil
        }
        
        self.InputContainer = Creator.New("Frame", {
            Size = UDim2.new(0, 140, 0, 26),
            Position = UDim2.new(1, -12, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 0.9,
            ThemeTag = {BackgroundColor3 = "Input"}
        }, inputChildren)
        
        -- Character counter
        if ShowCharCount then
            self.CharCounter = Creator.New("TextLabel", {
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                Text = MaxLength and string.format("%d/%d", #Default, MaxLength) or tostring(#Default),
                TextSize = 10,
                TextTransparency = 0.5,
                Size = UDim2.new(0, 50, 0, 10),
                Position = UDim2.new(1, -12, 1, -8),
                AnchorPoint = Vector2.new(1, 1),
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "SubText"}
            })
        end
        
        -- Error message label
        self.ErrorLabel = Creator.New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            Text = "",
            TextSize = 10,
            TextColor3 = Color3.fromRGB(220, 53, 69),
            Size = UDim2.new(1, -160, 0, 10),
            Position = UDim2.new(0, 12, 1, -6),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = false
        })
        
        -- Title
        self.Label = Creator.New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            Text = Title .. (Required and " *" or ""),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -160, 0, 14),
            Position = hasDescription and UDim2.fromOffset(12, 9) or UDim2.new(0, 12, 0.5, 0),
            AnchorPoint = hasDescription and Vector2.zero or Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            TextTransparency = Disabled and 0.5 or 0,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Description
        if hasDescription then
            self.DescriptionLabel = Creator.New("TextLabel", {
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                Text = Description,
                TextSize = 12,
                TextTransparency = Disabled and 0.6 or 0.4,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -160, 0, 12),
                Position = UDim2.fromOffset(12, 27),
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "SubText"}
            })
        end
        
        -- Suggestions dropdown
        if #Suggestions > 0 then
            self.SuggestionsContainer = Creator.New("Frame", {
                Size = UDim2.new(0, 140, 0, 0),
                Position = UDim2.new(1, -12, 0, height + 2),
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 0.05,
                ClipsDescendants = true,
                Visible = false,
                ZIndex = 100,
                ThemeTag = {BackgroundColor3 = "SecondaryElementBackground"}
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)}),
                Creator.New("UIStroke", {
                    Transparency = 0.5,
                    ThemeTag = {Color = "Accent"}
                }),
                Creator.New("UIListLayout", {
                    Padding = UDim.new(0, 2),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
            })
            
            self.SuggestionItems = {}
        end
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 0.89,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {
                Transparency = 0.5,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                ThemeTag = {Color = "ElementBorder"}
            }),
            self.Label,
            hasDescription and self.DescriptionLabel or nil,
            self.InputContainer,
            ShowCharCount and self.CharCounter or nil,
            self.ErrorLabel,
            self.SuggestionsContainer
        })
        
        -- Focus effects
        local inputStroke = self.InputContainer:FindFirstChild("InputStroke")
        
        Creator.AddSignal(self.InputBox.Focused, function()
            if not self.Disabled then
                Creator.OverrideTag(self.InputContainer, {BackgroundColor3 = "InputFocused"})
                if inputStroke then
                    Creator.OverrideTag(inputStroke, {Color = "Accent"})
                end
                
                -- Show suggestions
                if #self.Suggestions > 0 then
                    self:FilterSuggestions(self.InputBox.Text)
                end
            end
        end)
        
        Creator.AddSignal(self.InputBox.FocusLost, function(enterPressed)
            Creator.OverrideTag(self.InputContainer, {BackgroundColor3 = "Input"})
            if inputStroke and self.IsValid then
                Creator.OverrideTag(inputStroke, {Color = "InputStroke"})
            end
            
            -- Hide suggestions
            if self.SuggestionsContainer then
                self.SuggestionsContainer.Visible = false
                self.SuggestionsContainer.Size = UDim2.new(0, 140, 0, 0)
            end
            
            local value = InputType == "password" and self.ActualValue or self.InputBox.Text
            
            -- Process based on type
            if self.Numeric or InputType == "number" then
                value = tonumber(value) or 0
                self.InputBox.Text = tostring(value)
            end
            
            self.Value = value
            
            -- Validate
            self:Validate()
            
            if Finished and enterPressed then
                if self.IsValid then
                    self.Callback(value)
                end
            elseif not Finished then
                self.Callback(value)
            end
        end)
        
        -- Text changed
        Creator.AddSignal(self.InputBox:GetPropertyChangedSignal("Text"), function()
            if self.Disabled or self.Readonly then return end
            
            local text = self.InputBox.Text
            
            -- Handle password type
            if InputType == "password" and not self.IsPasswordVisible then
                -- Calculate what was typed
                local lenDiff = #text - #self.ActualValue
                if lenDiff > 0 then
                    -- Characters added
                    local newChars = text:sub(#self.ActualValue + 1)
                    self.ActualValue = self.ActualValue .. newChars
                elseif lenDiff < 0 then
                    -- Characters removed
                    self.ActualValue = self.ActualValue:sub(1, #text)
                end
                self.InputBox.Text = string.rep("•", #self.ActualValue)
                text = self.ActualValue
            end
            
            -- Enforce max length
            if MaxLength and #text > MaxLength then
                if InputType == "password" then
                    self.ActualValue = self.ActualValue:sub(1, MaxLength)
                    self.InputBox.Text = self.IsPasswordVisible 
                        and self.ActualValue 
                        or string.rep("•", MaxLength)
                else
                    self.InputBox.Text = text:sub(1, MaxLength)
                end
                text = text:sub(1, MaxLength)
            end
            
            -- Numeric filter
            if self.Numeric or InputType == "number" then
                local filtered = text:gsub("[^%d%.%-]", "")
                if filtered ~= text then
                    self.InputBox.Text = filtered
                    text = filtered
                end
            end
            
            -- Update character counter
            if ShowCharCount and self.CharCounter then
                self.CharCounter.Text = MaxLength 
                    and string.format("%d/%d", #text, MaxLength) 
                    or tostring(#text)
            end
            
            -- Update clear button visibility
            if Clearable and self.ClearButton then
                self.ClearButton.Visible = #text > 0
            end
            
            -- Filter suggestions
            if #self.Suggestions > 0 then
                self:FilterSuggestions(text)
            end
        end)
        
        self.Root = self.Frame
        
        return self
    end
    
    -- Validate input
    function Input:Validate()
        local value = self.InputType == "password" and self.ActualValue or self.Value
        local inputStroke = self.InputContainer:FindFirstChild("InputStroke")
        
        self.IsValid = true
        self.ErrorMessage = nil
        
        -- Required check
        if self.Required and (value == "" or value == nil) then
            self.IsValid = false
            self.ErrorMessage = "This field is required"
        end
        
        -- Min length check
        if self.IsValid and self.MinLength and #tostring(value) < self.MinLength then
            self.IsValid = false
            self.ErrorMessage = string.format("Minimum %d characters required", self.MinLength)
        end
        
        -- Pattern check
        if self.IsValid and self.Pattern and value ~= "" then
            local pattern = ValidationPatterns[self.Pattern] or self.Pattern
            if not tostring(value):match(pattern) then
                self.IsValid = false
                self.ErrorMessage = "Invalid format"
            end
        end
        
        -- Built-in type validation
        if self.IsValid and value ~= "" then
            if self.InputType == "email" and not tostring(value):match(ValidationPatterns.email) then
                self.IsValid = false
                self.ErrorMessage = "Invalid email format"
            elseif self.InputType == "url" and not tostring(value):match(ValidationPatterns.url) then
                self.IsValid = false
                self.ErrorMessage = "Invalid URL format"
            end
        end
        
        -- Custom validation
        if self.IsValid and self.Validation and value ~= "" then
            local valid, msg = self.Validation(value)
            if not valid then
                self.IsValid = false
                self.ErrorMessage = msg or "Invalid input"
            end
        end
        
        -- Update UI
        if self.ErrorLabel then
            self.ErrorLabel.Text = self.ErrorMessage or ""
            self.ErrorLabel.Visible = not self.IsValid
        end
        
        if inputStroke then
            if not self.IsValid then
                inputStroke.Color = Color3.fromRGB(220, 53, 69)
            else
                Creator.OverrideTag(inputStroke, {Color = "InputStroke"})
            end
        end
        
        return self.IsValid
    end
    
    -- Filter and show suggestions
    function Input:FilterSuggestions(query)
        if not self.SuggestionsContainer then return end
        
        -- Clear existing
        for _, item in pairs(self.SuggestionItems) do
            if item then item:Destroy() end
        end
        self.SuggestionItems = {}
        
        query = query:lower()
        local matches = {}
        
        for _, suggestion in ipairs(self.Suggestions) do
            if query == "" or tostring(suggestion):lower():find(query, 1, true) then
                table.insert(matches, suggestion)
                if #matches >= 5 then break end
            end
        end
        
        if #matches == 0 then
            self.SuggestionsContainer.Visible = false
            self.SuggestionsContainer.Size = UDim2.new(0, 140, 0, 0)
            return
        end
        
        for i, match in ipairs(matches) do
            local item = Creator.New("TextButton", {
                Size = UDim2.new(1, -8, 0, 26),
                Position = UDim2.fromOffset(4, 0),
                BackgroundTransparency = 1,
                Text = tostring(match),
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = i,
                Parent = self.SuggestionsContainer,
                ThemeTag = {TextColor3 = "Text"}
            }, {
                Creator.New("UIPadding", {PaddingLeft = UDim.new(0, 8)})
            })
            
            Creator.AddSignal(item.MouseEnter, function()
                Creator.OverrideTag(item, {BackgroundColor3 = "Element"})
                item.BackgroundTransparency = 0.9
            end)
            
            Creator.AddSignal(item.MouseLeave, function()
                item.BackgroundTransparency = 1
            end)
            
            Creator.AddSignal(item.MouseButton1Click, function()
                self:Set(match)
                self.SuggestionsContainer.Visible = false
                self.Callback(match)
            end)
            
            table.insert(self.SuggestionItems, item)
        end
        
        self.SuggestionsContainer.Visible = true
        self.SuggestionsContainer.Size = UDim2.new(0, 140, 0, #matches * 28 + 8)
    end
    
    function Input:Set(value)
        if self.Disabled then return end
        
        self.Value = value
        
        if self.InputType == "password" then
            self.ActualValue = tostring(value)
            self.InputBox.Text = self.IsPasswordVisible 
                and self.ActualValue 
                or string.rep("•", #self.ActualValue)
        else
            self.InputBox.Text = tostring(value)
        end
        
        if self.CharCounter then
            self.CharCounter.Text = self.MaxLength 
                and string.format("%d/%d", #tostring(value), self.MaxLength) 
                or tostring(#tostring(value))
        end
        
        if self.ClearButton then
            self.ClearButton.Visible = #tostring(value) > 0
        end
    end
    
    function Input:SetDisabled(disabled)
        self.Disabled = disabled
        self.InputBox.TextEditable = not disabled and not self.Readonly
        self.InputBox.TextTransparency = disabled and 0.5 or 0
        
        if self.Label then
            self.Label.TextTransparency = disabled and 0.5 or 0
        end
        
        if self.DescriptionLabel then
            self.DescriptionLabel.TextTransparency = disabled and 0.6 or 0.4
        end
        
        if self.IconLabel then
            self.IconLabel.ImageTransparency = disabled and 0.5 or 0
        end
    end
    
    function Input:GetValue()
        if self.InputType == "password" then
            return self.ActualValue
        end
        return self.Value
    end
    
    function Input:IsValidInput()
        return self:Validate()
    end
    
    function Input:Destroy()
        if self.Frame then
            self.Frame:Destroy()
        end
    end
    
    return Input
    
end

-- Module: Elements/Keybind
_modules["Elements/Keybind"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                  Keybind Component v2.15                      ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        Features:
        • Conflict detection with other keybinds
        • Key combination support (Ctrl+Key, Shift+Key)
        • Blacklist for system keys
        • Hold-to-interact mode
        • Visual focus indicators
        • Clear/unbind button
        • Disabled state
    ]]
    
    local Keybind = {}
    Keybind.__index = Keybind
    
    -- Static registry for conflict detection
    Keybind.Registry = {}
    
    local Creator
    local Flipper
    local Services
    
    local BLACKLIST = {
        Enum.KeyCode.Unknown,
        Enum.KeyCode.W,
        Enum.KeyCode.A,
        Enum.KeyCode.S,
        Enum.KeyCode.D,
        Enum.KeyCode.Slash,
        Enum.KeyCode.Tab,
        Enum.KeyCode.Escape,
        Enum.KeyCode.Backspace,
        Enum.KeyCode.Space,
        Enum.KeyCode.Return
    }
    
    local MODIFIER_KEYS = {
        [Enum.KeyCode.LeftControl] = "Ctrl",
        [Enum.KeyCode.RightControl] = "Ctrl",
        [Enum.KeyCode.LeftShift] = "Shift",
        [Enum.KeyCode.RightShift] = "Shift",
        [Enum.KeyCode.LeftAlt] = "Alt",
        [Enum.KeyCode.RightAlt] = "Alt"
    }
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Flipper = _require("Packages/Flipper")
        Services = _require("Core/Services")
    end
    
    function Keybind.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Keybind"
        local Description = options.Description
        local Default = options.Default
        local HoldToInteract = options.HoldToInteract or false
        local AllowModifiers = options.AllowModifiers ~= false -- Default true
        local DetectConflicts = options.DetectConflicts ~= false -- Default true
        local Clearable = options.Clearable ~= false -- Default true
        local Disabled = options.Disabled or false
        local Callback = options.Callback or function() end
        local ChangedCallback = options.ChangedCallback or function() end
        local Flag = options.Flag
        
        local self = setmetatable({}, Keybind)
        
        self.Value = Default
        self.Modifier = nil -- Ctrl, Shift, Alt
        self.Callback = Callback
        self.ChangedCallback = ChangedCallback
        self.HoldToInteract = HoldToInteract
        self.AllowModifiers = AllowModifiers
        self.DetectConflicts = DetectConflicts
        self.Clearable = Clearable
        self.Disabled = Disabled
        self.Flag = Flag
        self.Listening = false
        self.Holding = false
        self.ConflictWarning = nil
        
        local hasDescription = Description ~= nil
        local height = hasDescription and 48 or 36
        
        -- Register this keybind
        if Flag then
            Keybind.Registry[Flag] = self
        end
        
        -- Format keybind display
        local function getKeyDisplay()
            if not self.Value then return "None" end
            local display = ""
            if self.Modifier then
                display = self.Modifier .. "+"
            end
            return display .. self.Value.Name
        end
        
        self.GetKeyDisplay = getKeyDisplay
        
        -- Keybind button
        self.KeybindButton = Creator.New("TextButton", {
            Size = UDim2.new(0, 90, 0, 24),
            Position = UDim2.new(1, Clearable and -32 or -12, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            Text = getKeyDisplay(),
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            TextSize = 11,
            BackgroundTransparency = 0.9,
            AutoButtonColor = false,
            Active = not Disabled,
            TextTransparency = Disabled and 0.5 or 0,
            ThemeTag = {
                BackgroundColor3 = "Input",
                TextColor3 = "Text"
            }
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)}),
            Creator.New("UIStroke", {
                Name = "ButtonStroke",
                Transparency = 0.6,
                ThemeTag = {Color = "InputStroke"}
            })
        })
        
        -- Clear button
        if Clearable then
            self.ClearButton = Creator.New("TextButton", {
                Size = UDim2.fromOffset(16, 16),
                Position = UDim2.new(1, -12, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Text = "",
                Visible = Default ~= nil,
                Active = not Disabled,
                ZIndex = 5
            }, {
                Creator.New("ImageLabel", {
                    Image = "rbxassetid://7743878326", -- X icon
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    ThemeTag = {ImageColor3 = "SubText"}
                })
            })
            
            Creator.AddSignal(self.ClearButton.MouseButton1Click, function()
                if not self.Disabled then
                    self:Clear()
                end
            end)
        end
        
        -- Conflict warning icon
        self.ConflictIcon = Creator.New("ImageLabel", {
            Image = "rbxassetid://7743879203", -- Warning icon
            Size = UDim2.fromOffset(14, 14),
            Position = UDim2.new(1, Clearable and -134 or -114, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            ImageColor3 = Color3.fromRGB(255, 193, 7),
            Visible = false,
            ZIndex = 5
        })
        
        -- Title
        self.Label = Creator.New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            Text = Title,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -130, 0, 14),
            Position = hasDescription and UDim2.fromOffset(12, 9) or UDim2.new(0, 12, 0.5, 0),
            AnchorPoint = hasDescription and Vector2.zero or Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            TextTransparency = Disabled and 0.5 or 0,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Description
        if hasDescription then
            self.DescriptionLabel = Creator.New("TextLabel", {
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                Text = Description,
                TextSize = 12,
                TextTransparency = Disabled and 0.6 or 0.4,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -130, 0, 12),
                Position = UDim2.fromOffset(12, 27),
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "SubText"}
            })
        end
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 0.89,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {
                Transparency = 0.5,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                ThemeTag = {Color = "ElementBorder"}
            }),
            self.Label,
            hasDescription and self.DescriptionLabel or nil,
            self.KeybindButton,
            Clearable and self.ClearButton or nil,
            self.ConflictIcon
        })
        
        -- Click to listen
        if not Disabled then
            Creator.AddSignal(self.KeybindButton.MouseButton1Click, function()
                if self.Listening or self.Disabled then return end
                
                self.Listening = true
                self.KeybindButton.Text = "..."
                
                local stroke = self.KeybindButton:FindFirstChild("ButtonStroke")
                if stroke then
                    Creator.OverrideTag(stroke, {Color = "Accent"})
                end
            end)
        end
        
        -- Capture key
        Creator.AddSignal(Services.UserInputService.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if self.Listening then
                    -- Skip modifier-only presses
                    if MODIFIER_KEYS[input.KeyCode] then
                        return
                    end
                    
                    -- Check blacklist
                    if table.find(BLACKLIST, input.KeyCode) then
                        self.Listening = false
                        self.KeybindButton.Text = self.GetKeyDisplay()
                        local stroke = self.KeybindButton:FindFirstChild("ButtonStroke")
                        if stroke then
                            Creator.OverrideTag(stroke, {Color = "InputStroke"})
                        end
                        return
                    end
                    
                    -- Capture modifier if held
                    local modifier = nil
                    if self.AllowModifiers then
                        if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or 
                           Services.UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
                            modifier = "Ctrl"
                        elseif Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or 
                               Services.UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
                            modifier = "Shift"
                        elseif Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or 
                               Services.UserInputService:IsKeyDown(Enum.KeyCode.RightAlt) then
                            modifier = "Alt"
                        end
                    end
                    
                    -- Check for conflicts
                    local conflict = nil
                    if self.DetectConflicts then
                        conflict = self:CheckConflict(input.KeyCode, modifier)
                    end
                    
                    self.Value = input.KeyCode
                    self.Modifier = modifier
                    self.KeybindButton.Text = self.GetKeyDisplay()
                    self.Listening = false
                    
                    -- Show/hide conflict warning
                    self.ConflictIcon.Visible = conflict ~= nil
                    self.ConflictWarning = conflict
                    
                    local stroke = self.KeybindButton:FindFirstChild("ButtonStroke")
                    if stroke then
                        if conflict then
                            stroke.Color = Color3.fromRGB(255, 193, 7)
                        else
                            Creator.OverrideTag(stroke, {Color = "InputStroke"})
                        end
                    end
                    
                    -- Update clear button
                    if self.ClearButton then
                        self.ClearButton.Visible = true
                    end
                    
                    self.ChangedCallback(input.KeyCode, modifier)
                elseif self.Value and input.KeyCode == self.Value and not self.Disabled then
                    -- Check modifier match
                    local modifierMatch = true
                    if self.Modifier then
                        local modDown = false
                        if self.Modifier == "Ctrl" then
                            modDown = Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or 
                                      Services.UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
                        elseif self.Modifier == "Shift" then
                            modDown = Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or 
                                      Services.UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
                        elseif self.Modifier == "Alt" then
                            modDown = Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or 
                                      Services.UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)
                        end
                        modifierMatch = modDown
                    end
                    
                    if modifierMatch then
                        if self.HoldToInteract then
                            self.Holding = true
                        else
                            self.Callback(self.Value, self.Modifier)
                        end
                    end
                end
            end
        end)
        
        -- Key release (for hold mode)
        Creator.AddSignal(Services.UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if self.HoldToInteract and self.Holding and self.Value and input.KeyCode == self.Value then
                    self.Holding = false
                    self.Callback(self.Value, self.Modifier)
                end
            end
        end)
        
        self.Root = self.Frame
        
        return self
    end
    
    -- Check for conflicts with other keybinds
    function Keybind:CheckConflict(keyCode, modifier)
        for flag, keybind in pairs(Keybind.Registry) do
            if keybind ~= self and keybind.Value == keyCode and keybind.Modifier == modifier then
                return flag
            end
        end
        return nil
    end
    
    function Keybind:Set(keyCode, modifier)
        if self.Disabled then return end
        
        self.Value = keyCode
        self.Modifier = modifier
        self.KeybindButton.Text = self.GetKeyDisplay()
        
        if self.ClearButton then
            self.ClearButton.Visible = keyCode ~= nil
        end
        
        -- Check conflict
        if self.DetectConflicts then
            local conflict = self:CheckConflict(keyCode, modifier)
            self.ConflictIcon.Visible = conflict ~= nil
            self.ConflictWarning = conflict
        end
        
        self.ChangedCallback(keyCode, modifier)
    end
    
    function Keybind:SetDisabled(disabled)
        self.Disabled = disabled
        self.KeybindButton.Active = not disabled
        self.KeybindButton.TextTransparency = disabled and 0.5 or 0
        
        if self.Label then
            self.Label.TextTransparency = disabled and 0.5 or 0
        end
        
        if self.DescriptionLabel then
            self.DescriptionLabel.TextTransparency = disabled and 0.6 or 0.4
        end
        
        if self.ClearButton then
            self.ClearButton.Active = not disabled
        end
    end
    
    function Keybind:GetValue()
        return self.Value, self.Modifier
    end
    
    function Keybind:GetKeyString()
        return self.GetKeyDisplay()
    end
    
    function Keybind:Clear()
        if self.Flag and Keybind.Registry[self.Flag] then
            -- Keep in registry but clear value
        end
        
        self.Value = nil
        self.Modifier = nil
        self.KeybindButton.Text = "None"
        self.ConflictIcon.Visible = false
        self.ConflictWarning = nil
        
        if self.ClearButton then
            self.ClearButton.Visible = false
        end
        
        local stroke = self.KeybindButton:FindFirstChild("ButtonStroke")
        if stroke then
            Creator.OverrideTag(stroke, {Color = "InputStroke"})
        end
        
        self.ChangedCallback(nil, nil)
    end
    
    function Keybind:Destroy()
        -- Remove from registry
        if self.Flag and Keybind.Registry[self.Flag] then
            Keybind.Registry[self.Flag] = nil
        end
        
        if self.Frame then
            self.Frame:Destroy()
        end
    end
    
    return Keybind
    
end

-- Module: Elements/List
_modules["Elements/List"] = function()
    --[[
        NexusUI List Element
        Scrollable list with items
    ]]
    
    local List = {}
    List.__index = List
    
    local Creator, ImageLoader
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        ImageLoader = _require("Utils/ImageLoader")
    end
    
    function List.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title
        local Items = options.Items or {}
        local MaxHeight = options.MaxHeight or 200
        local Selectable = options.Selectable or false
        local MultiSelect = options.MultiSelect or false
        local OnSelect = options.OnSelect or function() end
        
        local self = setmetatable({}, List)
        self.Items = Items
        self.Selected = MultiSelect and {} or nil
        self.OnSelect = OnSelect
        self.ItemFrames = {}
        
        local hasTitle = Title ~= nil
        local itemHeight = 36
        
        -- Title
        if hasTitle then
            self.TitleLabel = Creator.New("TextLabel", {
                Size = UDim2.new(1, -24, 0, 20),
                Position = UDim2.fromOffset(12, 8),
                Text = Title,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "Text"}
            })
        end
        
        -- Items container
        self.ItemsContainer = Creator.New("ScrollingFrame", {
            Size = UDim2.new(1, -24, 0, math.min(#Items * itemHeight, MaxHeight)),
            Position = UDim2.fromOffset(12, hasTitle and 32 or 8),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            CanvasSize = UDim2.fromOffset(0, #Items * itemHeight),
            ThemeTag = {ScrollBarImageColor3 = "Text"}
        }, {
            Creator.New("UIListLayout", {Padding = UDim.new(0, 2)})
        })
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, (hasTitle and 36 or 12) + math.min(#Items * itemHeight, MaxHeight)),
            BackgroundTransparency = 0.89,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {Transparency = 0.5, ThemeTag = {Color = "ElementBorder"}}),
            hasTitle and self.TitleLabel or nil,
            self.ItemsContainer
        })
        
        self.Selectable = Selectable
        self.MultiSelect = MultiSelect
        self.ItemHeight = itemHeight
        
        -- Render items
        self:Render()
        
        self.Root = self.Frame
        return self
    end
    
    function List:Render()
        -- Clear existing
        for _, child in ipairs(self.ItemsContainer:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        self.ItemFrames = {}
        
        for i, item in ipairs(self.Items) do
            local text = type(item) == "table" and (item.Text or item.Title) or tostring(item)
            local icon = type(item) == "table" and item.Icon
            local description = type(item) == "table" and item.Description
            
            local itemFrame = Creator.New("Frame", {
                Size = UDim2.new(1, 0, 0, self.ItemHeight),
                BackgroundTransparency = 0.95,
                Parent = self.ItemsContainer,
                ThemeTag = {BackgroundColor3 = "Element"}
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)})
            })
            
            local textX = 8
            
            -- Icon
            if icon then
                local iconLabel = Creator.New("ImageLabel", {
                    Size = UDim2.fromOffset(20, 20),
                    Position = UDim2.new(0, 8, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Parent = itemFrame,
                    ThemeTag = {ImageColor3 = "Text"}
                })
                ImageLoader.SetImage(iconLabel, icon)
                textX = 36
            end
            
            -- Text
            Creator.New("TextLabel", {
                Size = UDim2.new(1, -textX - 8, 0, description and 16 or 20),
                Position = UDim2.new(0, textX, 0, description and 6 or 8),
                Text = text,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                Parent = itemFrame,
                ThemeTag = {TextColor3 = "Text"}
            })
            
            if description then
                Creator.New("TextLabel", {
                    Size = UDim2.new(1, -textX - 8, 0, 12),
                    Position = UDim2.new(0, textX, 0, 22),
                    Text = description,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                    TextSize = 11,
                    TextTransparency = 0.5,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Parent = itemFrame,
                    ThemeTag = {TextColor3 = "SubText"}
                })
            end
            
            -- Click handler
            if self.Selectable then
                local clickBtn = Creator.New("TextButton", {
                    Size = UDim2.fromScale(1, 1),
                    Text = "",
                    BackgroundTransparency = 1,
                    Parent = itemFrame
                })
                
                Creator.AddSignal(clickBtn.MouseButton1Click, function()
                    self:SelectItem(i, item)
                end)
            end
            
            self.ItemFrames[i] = itemFrame
        end
        
        self.ItemsContainer.CanvasSize = UDim2.fromOffset(0, #self.Items * self.ItemHeight)
    end
    
    function List:SelectItem(index, item)
        if self.MultiSelect then
            if self.Selected[index] then
                self.Selected[index] = nil
                Creator.Tween(self.ItemFrames[index], {BackgroundTransparency = 0.95}, 0.15)
            else
                self.Selected[index] = item
                Creator.Tween(self.ItemFrames[index], {BackgroundTransparency = 0.8}, 0.15)
            end
            self.OnSelect(self.Selected)
        else
            -- Deselect old
            if self.Selected then
                local oldFrame = self.ItemFrames[self.Selected]
                if oldFrame then
                    Creator.Tween(oldFrame, {BackgroundTransparency = 0.95}, 0.15)
                end
            end
            
            self.Selected = index
            Creator.Tween(self.ItemFrames[index], {BackgroundTransparency = 0.8}, 0.15)
            self.OnSelect(item, index)
        end
    end
    
    function List:SetItems(items)
        self.Items = items
        self.Selected = self.MultiSelect and {} or nil
        self:Render()
    end
    
    function List:AddItem(item)
        table.insert(self.Items, item)
        self:Render()
    end
    
    function List:RemoveItem(index)
        table.remove(self.Items, index)
        self:Render()
    end
    
    return List
    
end

-- Module: Elements/MusicPlayer
_modules["Elements/MusicPlayer"] = function()
    --[[
        NexusUI Music Player Element
        Audio player with controls
        Supports raw URLs (via asset download) and rbxassetid
    ]]
    
    local MusicPlayer = {}
    MusicPlayer.__index = MusicPlayer
    
    local Creator, Services, ImageLoader
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Services = _require("Core/Services")
        ImageLoader = _require("Utils/ImageLoader")
    end
    
    function MusicPlayer.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Unknown Track"
        local Artist = options.Artist or "Unknown Artist"
        local Cover = options.Cover -- Raw URL or rbxassetid
        local SoundId = options.SoundId -- Can be number or "rbxassetid://..."
        local Volume = options.Volume or 0.5
        local Looped = options.Looped or false
        
        local self = setmetatable({}, MusicPlayer)
        self.Playing = false
        self.Volume = Volume
        
        -- Create sound
        self.Sound = Instance.new("Sound")
        self.Sound.Volume = Volume
        self.Sound.Looped = Looped
        self.Sound.Parent = Services.SoundService
        
        if SoundId then
            if type(SoundId) == "number" then
                self.Sound.SoundId = "rbxassetid://" .. SoundId
            else
                self.Sound.SoundId = SoundId
            end
        end
        
        -- Cover art
        self.CoverImage = Creator.New("ImageLabel", {
            Size = UDim2.fromOffset(60, 60),
            Position = UDim2.new(0, 12, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Color3.fromRGB(40, 40, 50),
            ThemeTag = not Cover and {BackgroundColor3 = "Accent"} or nil
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            -- Music icon if no cover
            not Cover and Creator.New("TextLabel", {
                Size = UDim2.fromScale(1, 1),
                Text = "🎵",
                TextSize = 24,
                BackgroundTransparency = 1
            }) or nil
        })
        
        if Cover then
            ImageLoader.SetImage(self.CoverImage, Cover)
        end
        
        -- Track info
        self.TitleLabel = Creator.New("TextLabel", {
            Size = UDim2.new(1, -170, 0, 18),
            Position = UDim2.fromOffset(84, 16),
            Text = Title,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        self.ArtistLabel = Creator.New("TextLabel", {
            Size = UDim2.new(1, -170, 0, 14),
            Position = UDim2.fromOffset(84, 36),
            Text = Artist,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 12,
            TextTransparency = 0.4,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "SubText"}
        })
        
        -- Progress bar
        self.ProgressBar = Creator.New("Frame", {
            Size = UDim2.new(1, -170, 0, 4),
            Position = UDim2.fromOffset(84, 58),
            BackgroundTransparency = 0.7,
            ThemeTag = {BackgroundColor3 = "SliderBackground"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
        })
        
        self.ProgressFill = Creator.New("Frame", {
            Size = UDim2.fromScale(0, 1),
            Parent = self.ProgressBar,
            ThemeTag = {BackgroundColor3 = "Accent"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
        })
        
        -- Control buttons
        self.PlayBtn = Creator.New("TextButton", {
            Size = UDim2.fromOffset(36, 36),
            Position = UDim2.new(1, -48, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Text = "▶",
            TextSize = 16,
            ThemeTag = {BackgroundColor3 = "Accent", TextColor3 = "Text"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
        })
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, 80),
            BackgroundTransparency = 0.89,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 10)}),
            Creator.New("UIStroke", {Transparency = 0.5, ThemeTag = {Color = "ElementBorder"}}),
            self.CoverImage,
            self.TitleLabel,
            self.ArtistLabel,
            self.ProgressBar,
            self.PlayBtn
        })
        
        -- Play/Pause handler
        Creator.AddSignal(self.PlayBtn.MouseButton1Click, function()
            if self.Playing then
                self:Pause()
            else
                self:Play()
            end
        end)
        
        -- Progress update
        Creator.AddSignal(Services.RunService.Heartbeat, function()
            if self.Sound.IsLoaded and self.Sound.TimeLength > 0 then
                local progress = self.Sound.TimePosition / self.Sound.TimeLength
                self.ProgressFill.Size = UDim2.fromScale(progress, 1)
            end
        end)
        
        self.Root = self.Frame
        return self
    end
    
    function MusicPlayer:Play()
        self.Sound:Play()
        self.Playing = true
        self.PlayBtn.Text = "⏸"
    end
    
    function MusicPlayer:Pause()
        self.Sound:Pause()
        self.Playing = false
        self.PlayBtn.Text = "▶"
    end
    
    function MusicPlayer:Stop()
        self.Sound:Stop()
        self.Playing = false
        self.PlayBtn.Text = "▶"
    end
    
    function MusicPlayer:SetVolume(vol)
        self.Volume = vol
        self.Sound.Volume = vol
    end
    
    function MusicPlayer:SetTrack(soundId, title, artist)
        if type(soundId) == "number" then
            self.Sound.SoundId = "rbxassetid://" .. soundId
        else
            self.Sound.SoundId = soundId
        end
        if title then self.TitleLabel.Text = title end
        if artist then self.ArtistLabel.Text = artist end
    end
    
    function MusicPlayer:Destroy()
        self.Sound:Stop()
        self.Sound:Destroy()
        self.Frame:Destroy()
    end
    
    return MusicPlayer
    
end

-- Module: Elements/NumberInput
_modules["Elements/NumberInput"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                NumberInput Component v2.15                    ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        Features:
        • Increment/decrement buttons
        • Min/max limits
        • Step value
        • Keyboard input
        • Scroll to change value
        • Disabled state
    ]]
    
    local NumberInput = {}
    NumberInput.__index = NumberInput
    
    local Creator
    local Flipper
    local Services
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Flipper = _require("Packages/Flipper")
        Services = _require("Core/Services")
    end
    
    function NumberInput.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Number"
        local Description = options.Description
        local Default = options.Default or 0
        local Min = options.Min or 0
        local Max = options.Max or 100
        local Step = options.Step or 1
        local Suffix = options.Suffix or ""
        local Disabled = options.Disabled or false
        local Callback = options.Callback or function() end
        local Flag = options.Flag
        
        local self = setmetatable({}, NumberInput)
        
        self.Value = math.clamp(Default, Min, Max)
        self.Min = Min
        self.Max = Max
        self.Step = Step
        self.Suffix = Suffix
        self.Callback = Callback
        self.Disabled = Disabled
        self.Flag = Flag
        
        local hasDescription = Description ~= nil
        local height = hasDescription and 48 or 36
        
        -- Decrement button
        self.DecrementButton = Creator.New("TextButton", {
            Size = UDim2.fromOffset(24, 24),
            Position = UDim2.new(1, -100, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Text = "-",
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
            TextSize = 16,
            BackgroundTransparency = 0.9,
            AutoButtonColor = false,
            Active = not Disabled and self.Value > Min,
            ThemeTag = {BackgroundColor3 = "Element", TextColor3 = "Text"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)}),
            Creator.New("UIStroke", {
                Transparency = 0.6,
                ThemeTag = {Color = "ElementBorder"}
            })
        })
        
        -- Value display/input
        self.ValueInput = Creator.New("TextBox", {
            Size = UDim2.fromOffset(50, 24),
            Position = UDim2.new(1, -72, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Text = tostring(self.Value) .. Suffix,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            TextSize = 13,
            BackgroundTransparency = 0.9,
            ClearTextOnFocus = true,
            TextEditable = not Disabled,
            ThemeTag = {BackgroundColor3 = "Input", TextColor3 = "Text"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 4)})
        })
        
        -- Increment button
        self.IncrementButton = Creator.New("TextButton", {
            Size = UDim2.fromOffset(24, 24),
            Position = UDim2.new(1, -12, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            Text = "+",
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
            TextSize = 16,
            BackgroundTransparency = 0.9,
            AutoButtonColor = false,
            Active = not Disabled and self.Value < Max,
            ThemeTag = {BackgroundColor3 = "Element", TextColor3 = "Text"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)}),
            Creator.New("UIStroke", {
                Transparency = 0.6,
                ThemeTag = {Color = "ElementBorder"}
            })
        })
        
        -- Title
        self.Label = Creator.New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            Text = Title,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -120, 0, 14),
            Position = hasDescription and UDim2.fromOffset(12, 9) or UDim2.new(0, 12, 0.5, 0),
            AnchorPoint = hasDescription and Vector2.zero or Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            TextTransparency = Disabled and 0.5 or 0,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Description
        if hasDescription then
            self.DescriptionLabel = Creator.New("TextLabel", {
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                Text = Description,
                TextSize = 12,
                TextTransparency = Disabled and 0.6 or 0.4,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -120, 0, 12),
                Position = UDim2.fromOffset(12, 27),
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "SubText"}
            })
        end
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 0.89,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {
                Transparency = 0.5,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                ThemeTag = {Color = "ElementBorder"}
            }),
            self.Label,
            hasDescription and self.DescriptionLabel or nil,
            self.DecrementButton,
            self.ValueInput,
            self.IncrementButton
        })
        
        -- Button handlers
        local function updateButtonStates()
            self.DecrementButton.Active = not self.Disabled and self.Value > self.Min
            self.IncrementButton.Active = not self.Disabled and self.Value < self.Max
            
            -- Visual feedback
            self.DecrementButton.BackgroundTransparency = self.DecrementButton.Active and 0.9 or 0.95
            self.IncrementButton.BackgroundTransparency = self.IncrementButton.Active and 0.9 or 0.95
        end
        
        if not Disabled then
            -- Decrement
            Creator.AddSignal(self.DecrementButton.MouseButton1Click, function()
                if self.Value > self.Min then
                    self:Set(self.Value - self.Step)
                end
            end)
            
            -- Increment
            Creator.AddSignal(self.IncrementButton.MouseButton1Click, function()
                if self.Value < self.Max then
                    self:Set(self.Value + self.Step)
                end
            end)
            
            -- Manual input
            Creator.AddSignal(self.ValueInput.FocusLost, function(enterPressed)
                local num = tonumber(self.ValueInput.Text:gsub(self.Suffix, ""))
                if num then
                    self:Set(num)
                else
                    self.ValueInput.Text = tostring(self.Value) .. self.Suffix
                end
            end)
            
            -- Scroll to change value
            Creator.AddSignal(self.Frame.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseWheel then
                    -- Note: MouseWheel not available in Roblox, but keeping for future compatibility
                end
            end)
            
            -- Hover effects
            Creator.AddSignal(self.DecrementButton.MouseEnter, function()
                if self.DecrementButton.Active then
                    Creator.Tween(self.DecrementButton, {BackgroundTransparency = 0.8}, 0.1)
                end
            end)
            
            Creator.AddSignal(self.DecrementButton.MouseLeave, function()
                Creator.Tween(self.DecrementButton, {BackgroundTransparency = 0.9}, 0.1)
            end)
            
            Creator.AddSignal(self.IncrementButton.MouseEnter, function()
                if self.IncrementButton.Active then
                    Creator.Tween(self.IncrementButton, {BackgroundTransparency = 0.8}, 0.1)
                end
            end)
            
            Creator.AddSignal(self.IncrementButton.MouseLeave, function()
                Creator.Tween(self.IncrementButton, {BackgroundTransparency = 0.9}, 0.1)
            end)
        end
        
        updateButtonStates()
        self.UpdateButtonStates = updateButtonStates
        
        self.Root = self.Frame
        
        return self
    end
    
    function NumberInput:Set(value, noCallback)
        if self.Disabled then return end
        
        -- Round to step
        value = math.floor(value / self.Step + 0.5) * self.Step
        value = math.clamp(value, self.Min, self.Max)
        
        -- Handle decimal display
        if self.Step < 1 then
            local decimals = math.max(0, -math.floor(math.log10(self.Step)))
            value = math.floor(value * 10^decimals + 0.5) / 10^decimals
        end
        
        self.Value = value
        self.ValueInput.Text = tostring(value) .. self.Suffix
        self.UpdateButtonStates()
        
        if not noCallback then
            self.Callback(value)
        end
    end
    
    function NumberInput:SetDisabled(disabled)
        self.Disabled = disabled
        self.ValueInput.TextEditable = not disabled
        
        if self.Label then
            self.Label.TextTransparency = disabled and 0.5 or 0
        end
        
        if self.DescriptionLabel then
            self.DescriptionLabel.TextTransparency = disabled and 0.6 or 0.4
        end
        
        self.UpdateButtonStates()
    end
    
    function NumberInput:GetValue()
        return self.Value
    end
    
    function NumberInput:Destroy()
        if self.Frame then
            self.Frame:Destroy()
        end
    end
    
    return NumberInput
    
end

-- Module: Elements/Paragraph
_modules["Elements/Paragraph"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                       GUI Framework                           ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
    ]]
    
    local Paragraph = {}
    Paragraph.__index = Paragraph
    
    local Creator
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
    end
    
    function Paragraph.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Paragraph"
        local Content = options.Content or ""
        
        local self = setmetatable({}, Paragraph)
        
        -- Content label
        self.ContentLabel = Creator.New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            Text = Content,
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, -24, 0, 0),
            Position = UDim2.fromOffset(12, 28),
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "SubText"}
        })
        
        -- Title
        self.TitleLabel = Creator.New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
            Text = Title,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -24, 0, 14),
            Position = UDim2.fromOffset(12, 10),
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, 50),
            BackgroundTransparency = 0.89,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {
                Transparency = 0.5,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                ThemeTag = {Color = "ElementBorder"}
            }),
            self.TitleLabel,
            self.ContentLabel
        })
        
        -- Update height based on content
        Creator.AddSignal(self.ContentLabel:GetPropertyChangedSignal("AbsoluteSize"), function()
            self.Frame.Size = UDim2.new(1, 0, 0, self.ContentLabel.AbsoluteSize.Y + 40)
        end)
        
        -- Initial height calculation
        task.defer(function()
            self.Frame.Size = UDim2.new(1, 0, 0, self.ContentLabel.AbsoluteSize.Y + 40)
        end)
        
        self.Root = self.Frame
        
        return self
    end
    
    function Paragraph:SetTitle(title)
        self.TitleLabel.Text = title
    end
    
    function Paragraph:SetContent(content)
        self.ContentLabel.Text = content
    end
    
    return Paragraph
    
end

-- Module: Elements/ProfileCard
_modules["Elements/ProfileCard"] = function()
    --[[
        NexusUI Profile Card Element
        Display user profile with avatar, stats, and badges
    ]]
    
    local ProfileCard = {}
    ProfileCard.__index = ProfileCard
    
    local Creator, Services
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Services = _require("Core/Services")
    end
    
    function ProfileCard.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Profile"
        local UserId = options.UserId or Services.LocalPlayer.UserId
        local Username = options.Username
        local DisplayName = options.DisplayName
        local AvatarType = options.AvatarType or "Bust" -- Bust, Full, Headshot
        local Stats = options.Stats or {} -- {Kills = 10, Deaths = 5, etc.}
        local Badges = options.Badges or {} -- Array of badge image IDs
        local ShowOnline = options.ShowOnline ~= false
        local CustomAvatar = options.CustomAvatar -- Custom avatar URL/ID
        local Bio = options.Bio
        local Callback = options.Callback
        
        local self = setmetatable({}, ProfileCard)
        
        -- Get avatar thumbnail
        local avatarUrl
        if CustomAvatar then
            avatarUrl = type(CustomAvatar) == "number" and ("rbxassetid://" .. CustomAvatar) or CustomAvatar
        else
            local thumbType = AvatarType == "Full" and Enum.ThumbnailType.AvatarThumbnail or
                             AvatarType == "Headshot" and Enum.ThumbnailType.HeadShot or
                             Enum.ThumbnailType.AvatarBust
            avatarUrl = Services.Players:GetUserThumbnailAsync(UserId, thumbType, Enum.ThumbnailSize.Size150x150)
        end
        
        -- Get username if not provided
        if not Username then
            local success, result = pcall(function()
                return Services.Players:GetNameFromUserIdAsync(UserId)
            end)
            Username = success and result or "Unknown"
        end
        
        -- Calculate height based on content
        local height = 120
        if Bio then height = height + 30 end
        if #Stats > 0 then height = height + 50 end
        if #Badges > 0 then height = height + 40 end
        
        -- Avatar
        self.Avatar = Creator.New("ImageLabel", {
            Size = UDim2.fromOffset(80, 80),
            Position = UDim2.fromOffset(16, 16),
            Image = avatarUrl,
            BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)}),
            Creator.New("UIStroke", {
                Thickness = 3,
                ThemeTag = {Color = "Accent"}
            })
        })
        
        -- Online indicator
        if ShowOnline then
            self.OnlineIndicator = Creator.New("Frame", {
                Size = UDim2.fromOffset(16, 16),
                Position = UDim2.new(1, -4, 1, -4),
                AnchorPoint = Vector2.new(1, 1),
                BackgroundColor3 = Color3.fromRGB(0, 200, 100),
                Parent = self.Avatar
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)}),
                Creator.New("UIStroke", {
                    Thickness = 2,
                    ThemeTag = {Color = "Background"}
                })
            })
        end
        
        -- Display name
        self.DisplayNameLabel = Creator.New("TextLabel", {
            Size = UDim2.new(1, -120, 0, 22),
            Position = UDim2.fromOffset(110, 18),
            Text = DisplayName or Username,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
            TextSize = 18,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Username
        self.UsernameLabel = Creator.New("TextLabel", {
            Size = UDim2.new(1, -120, 0, 16),
            Position = UDim2.fromOffset(110, 42),
            Text = "@" .. Username,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 0.4,
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "SubText"}
        })
        
        -- User ID
        self.UserIdLabel = Creator.New("TextLabel", {
            Size = UDim2.new(1, -120, 0, 14),
            Position = UDim2.fromOffset(110, 60),
            Text = "ID: " .. tostring(UserId),
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 0.5,
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "SubText"}
        })
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 0.89,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {
                Transparency = 0.5,
                ThemeTag = {Color = "ElementBorder"}
            }),
            self.Avatar,
            self.DisplayNameLabel,
            self.UsernameLabel,
            self.UserIdLabel
        })
        
        local nextY = 105
        
        -- Bio
        if Bio then
            self.BioLabel = Creator.New("TextLabel", {
                Size = UDim2.new(1, -32, 0, 24),
                Position = UDim2.fromOffset(16, nextY),
                Text = Bio,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                BackgroundTransparency = 1,
                Parent = self.Frame,
                ThemeTag = {TextColor3 = "SubText"}
            })
            nextY = nextY + 30
        end
        
        -- Stats
        if #Stats > 0 or next(Stats) then
            self.StatsContainer = Creator.New("Frame", {
                Size = UDim2.new(1, -32, 0, 40),
                Position = UDim2.fromOffset(16, nextY),
                BackgroundTransparency = 1,
                Parent = self.Frame
            }, {
                Creator.New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDim.new(0, 20),
                    VerticalAlignment = Enum.VerticalAlignment.Center
                })
            })
            
            for statName, statValue in pairs(Stats) do
                Creator.New("Frame", {
                    Size = UDim2.fromOffset(60, 40),
                    BackgroundTransparency = 1,
                    Parent = self.StatsContainer
                }, {
                    Creator.New("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 20),
                        Text = tostring(statValue),
                        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
                        TextSize = 16,
                        BackgroundTransparency = 1,
                        ThemeTag = {TextColor3 = "Text"}
                    }),
                    Creator.New("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 14),
                        Position = UDim2.fromOffset(0, 22),
                        Text = statName,
                        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                        TextSize = 11,
                        TextTransparency = 0.4,
                        BackgroundTransparency = 1,
                        ThemeTag = {TextColor3 = "SubText"}
                    })
                })
            end
            nextY = nextY + 50
        end
        
        -- Badges
        if #Badges > 0 then
            self.BadgesContainer = Creator.New("Frame", {
                Size = UDim2.new(1, -32, 0, 30),
                Position = UDim2.fromOffset(16, nextY),
                BackgroundTransparency = 1,
                Parent = self.Frame
            }, {
                Creator.New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDim.new(0, 8)
                })
            })
            
            for _, badge in ipairs(Badges) do
                Creator.New("ImageLabel", {
                    Size = UDim2.fromOffset(28, 28),
                    Image = type(badge) == "number" and ("rbxassetid://" .. badge) or badge,
                    BackgroundTransparency = 1,
                    Parent = self.BadgesContainer
                }, {
                    Creator.New("UICorner", {CornerRadius = UDim.new(0, 4)})
                })
            end
        end
        
        -- Click callback
        if Callback then
            local button = Creator.New("TextButton", {
                Size = UDim2.fromScale(1, 1),
                Text = "",
                BackgroundTransparency = 1,
                Parent = self.Frame
            })
            
            Creator.AddSignal(button.MouseButton1Click, function()
                Callback(UserId, Username)
            end)
        end
        
        self.Root = self.Frame
        
        return self
    end
    
    function ProfileCard:SetOnlineStatus(isOnline)
        if self.OnlineIndicator then
            self.OnlineIndicator.BackgroundColor3 = isOnline and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(100, 100, 100)
        end
    end
    
    function ProfileCard:UpdateStats(stats)
        -- Implementation for updating stats dynamically
    end
    
    return ProfileCard
    
end

-- Module: Elements/ProgressBar
_modules["Elements/ProgressBar"] = function()
    --[[
        NexusUI Progress Bar Element
        Animated progress bar with labels
    ]]
    
    local ProgressBar = {}
    ProgressBar.__index = ProgressBar
    
    local Creator, Flipper
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Flipper = _require("Packages/Flipper")
    end
    
    function ProgressBar.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Progress"
        local Progress = options.Progress or 0
        local Max = options.Max or 100
        local ShowPercent = options.ShowPercent ~= false
        local ShowValue = options.ShowValue or false
        local BarColor = options.BarColor
        local Animated = options.Animated ~= false
        local Height = options.Height or 20
        local Striped = options.Striped or false
        
        local self = setmetatable({}, ProgressBar)
        self.Progress = Progress
        self.Max = Max
        
        -- Title
        self.TitleLabel = Creator.New("TextLabel", {
            Size = UDim2.new(0.5, -6, 0, 18),
            Position = UDim2.fromOffset(12, 8),
            Text = Title,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Percentage/Value label
        self.ValueLabel = Creator.New("TextLabel", {
            Size = UDim2.new(0.5, -18, 0, 18),
            Position = UDim2.new(0.5, 6, 0, 8),
            Text = ShowPercent and math.floor((Progress / Max) * 100) .. "%" or (ShowValue and Progress .. "/" .. Max or ""),
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Right,
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "SubText"}
        })
        
        -- Progress bar background
        self.BarBackground = Creator.New("Frame", {
            Size = UDim2.new(1, -24, 0, Height),
            Position = UDim2.fromOffset(12, 32),
            BackgroundTransparency = 0.7,
            ClipsDescendants = true,
            ThemeTag = {BackgroundColor3 = "SliderBackground"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, Height / 2)})
        })
        
        -- Progress bar fill
        self.BarFill = Creator.New("Frame", {
            Size = UDim2.fromScale(math.clamp(Progress / Max, 0, 1), 1),
            Parent = self.BarBackground,
            ThemeTag = BarColor and nil or {BackgroundColor3 = "SliderProgress"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, Height / 2)}),
            Creator.New("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.new(0.9, 0.9, 0.9))
                }),
                Rotation = 90
            })
        })
        
        if BarColor then
            self.BarFill.BackgroundColor3 = BarColor
        end
        
        -- Striped effect
        if Striped then
            self:AddStripes()
        end
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, 58 + Height - 20),
            BackgroundTransparency = 0.89,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {
                Transparency = 0.5,
                ThemeTag = {Color = "ElementBorder"}
            }),
            self.TitleLabel,
            self.ValueLabel,
            self.BarBackground
        })
        
        -- Animation motor
        if Animated then
            self.ProgressMotor = Flipper.SingleMotor.new(Progress / Max)
            self.ProgressMotor:onStep(function(value)
                self.BarFill.Size = UDim2.fromScale(value, 1)
            end)
        end
        
        self.Root = self.Frame
        
        return self
    end
    
    function ProgressBar:AddStripes()
        local stripes = Creator.New("Frame", {
            Size = UDim2.new(2, 0, 1, 0),
            BackgroundTransparency = 1,
            Parent = self.BarFill
        })
        
        for i = 0, 20 do
            Creator.New("Frame", {
                Size = UDim2.new(0, 10, 1, 0),
                Position = UDim2.fromOffset(i * 20, 0),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0.8,
                Rotation = -45,
                Parent = stripes
            })
        end
        
        -- Animate stripes
        task.spawn(function()
            while stripes and stripes.Parent do
                stripes.Position = UDim2.fromOffset(0, 0)
                Creator.Tween(stripes, {Position = UDim2.fromOffset(-40, 0)}, 1, Enum.EasingStyle.Linear)
                task.wait(1)
            end
        end)
    end
    
    function ProgressBar:SetProgress(value, animate)
        value = math.clamp(value, 0, self.Max)
        self.Progress = value
        
        local percent = value / self.Max
        
        if self.ProgressMotor and animate ~= false then
            self.ProgressMotor:setGoal(Flipper.Spring.new(percent, {frequency = 4}))
        else
            self.BarFill.Size = UDim2.fromScale(percent, 1)
        end
        
        -- Update label
        if self.ShowPercent then
            self.ValueLabel.Text = math.floor(percent * 100) .. "%"
        elseif self.ShowValue then
            self.ValueLabel.Text = value .. "/" .. self.Max
        end
    end
    
    function ProgressBar:Increment(amount)
        self:SetProgress(self.Progress + (amount or 1))
    end
    
    function ProgressBar:SetMax(max)
        self.Max = max
        self:SetProgress(self.Progress)
    end
    
    function ProgressBar:SetColor(color)
        self.BarFill.BackgroundColor3 = color
    end
    
    return ProgressBar
    
end

-- Module: Elements/RadioButton
_modules["Elements/RadioButton"] = function()
    --[[
        NexusUI Radio Button Element
        Single-select from group
    ]]
    
    local RadioButton = {}
    RadioButton.__index = RadioButton
    RadioButton.Groups = {}
    
    local Creator
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
    end
    
    function RadioButton.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Option"
        local Group = options.Group or "default"
        local Value = options.Value or Title
        local Default = options.Default or false
        local Callback = options.Callback or function() end
        
        local self = setmetatable({}, RadioButton)
        self.Value = Value
        self.Group = Group
        self.Selected = Default
        self.Callback = Callback
        
        -- Register in group
        if not RadioButton.Groups[Group] then
            RadioButton.Groups[Group] = {}
        end
        table.insert(RadioButton.Groups[Group], self)
        
        -- Radio circle
        self.Circle = Creator.New("Frame", {
            Size = UDim2.fromOffset(20, 20),
            Position = UDim2.new(0, 12, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            ThemeTag = {BackgroundColor3 = "Input"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)}),
            Creator.New("UIStroke", {Thickness = 2, ThemeTag = {Color = Default and "Accent" or "InputStroke"}}),
            Creator.New("Frame", {
                Size = UDim2.fromOffset(10, 10),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = Default and 0 or 1,
                ThemeTag = {BackgroundColor3 = "Accent"}
            }, {
                Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
            })
        })
        
        self.Dot = self.Circle:FindFirstChildWhichIsA("Frame")
        self.Stroke = self.Circle:FindFirstChild("UIStroke")
        
        -- Title
        self.TitleLabel = Creator.New("TextLabel", {
            Size = UDim2.new(1, -50, 1, 0),
            Position = UDim2.fromOffset(42, 0),
            Text = Title,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Frame
        self.Frame = Creator.New("TextButton", {
            Size = UDim2.new(1, 0, 0, 36),
            Text = "",
            BackgroundTransparency = 1,
            Parent = parent
        }, {
            self.Circle,
            self.TitleLabel
        })
        
        -- Click
        Creator.AddSignal(self.Frame.MouseButton1Click, function()
            self:Select()
        end)
        
        self.Root = self.Frame
        return self
    end
    
    function RadioButton:Select()
        -- Deselect others in group
        for _, radio in ipairs(RadioButton.Groups[self.Group] or {}) do
            if radio ~= self and radio.Selected then
                radio.Selected = false
                radio:UpdateVisual()
            end
        end
        
        self.Selected = true
        self:UpdateVisual()
        self.Callback(self.Value)
    end
    
    function RadioButton:UpdateVisual()
        Creator.Tween(self.Dot, {BackgroundTransparency = self.Selected and 0 or 1}, 0.2)
        Creator.OverrideTag(self.Stroke, {Color = self.Selected and "Accent" or "InputStroke"})
    end
    
    function RadioButton:GetValue() return self.Selected and self.Value or nil end
    
    return RadioButton
    
end

-- Module: Elements/RangeSlider
_modules["Elements/RangeSlider"] = function()
    --[[
        NexusUI Range Slider Element
        Dual-handle slider for selecting a range
    ]]
    
    local RangeSlider = {}
    RangeSlider.__index = RangeSlider
    
    local Creator, Services
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Services = _require("Core/Services")
    end
    
    function RangeSlider.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Range"
        local Min = options.Min or 0
        local Max = options.Max or 100
        local DefaultMin = options.DefaultMin or Min
        local DefaultMax = options.DefaultMax or Max
        local Step = options.Step or 1
        local Suffix = options.Suffix or ""
        local Callback = options.Callback or function() end
        
        local self = setmetatable({}, RangeSlider)
        self.Min = Min
        self.Max = Max
        self.ValueMin = DefaultMin
        self.ValueMax = DefaultMax
        self.Step = Step
        self.Callback = Callback
        self.Dragging = nil
        
        -- Title
        self.TitleLabel = Creator.New("TextLabel", {
            Size = UDim2.new(0.5, 0, 0, 18),
            Position = UDim2.fromOffset(12, 8),
            Text = Title,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Value display
        self.ValueLabel = Creator.New("TextLabel", {
            Size = UDim2.new(0.5, -24, 0, 18),
            Position = UDim2.new(0.5, 0, 0, 8),
            Text = DefaultMin .. Suffix .. " - " .. DefaultMax .. Suffix,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Right,
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "SubText"}
        })
        
        -- Track
        self.Track = Creator.New("Frame", {
            Size = UDim2.new(1, -24, 0, 6),
            Position = UDim2.new(0, 12, 0, 40),
            BackgroundTransparency = 0.7,
            ThemeTag = {BackgroundColor3 = "SliderBackground"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
        })
        
        -- Range fill
        local minPercent = (DefaultMin - Min) / (Max - Min)
        local maxPercent = (DefaultMax - Min) / (Max - Min)
        
        self.RangeFill = Creator.New("Frame", {
            Size = UDim2.fromScale(maxPercent - minPercent, 1),
            Position = UDim2.fromScale(minPercent, 0),
            Parent = self.Track,
            ThemeTag = {BackgroundColor3 = "SliderProgress"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
        })
        
        -- Min handle
        self.MinHandle = Creator.New("TextButton", {
            Size = UDim2.fromOffset(16, 16),
            Position = UDim2.new(minPercent, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Text = "",
            Parent = self.Track,
            ThemeTag = {BackgroundColor3 = "Accent"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)}),
            Creator.New("UIStroke", {Thickness = 2, Color = Color3.new(1, 1, 1), Transparency = 0.3})
        })
        
        -- Max handle
        self.MaxHandle = Creator.New("TextButton", {
            Size = UDim2.fromOffset(16, 16),
            Position = UDim2.new(maxPercent, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Text = "",
            Parent = self.Track,
            ThemeTag = {BackgroundColor3 = "Accent"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)}),
            Creator.New("UIStroke", {Thickness = 2, Color = Color3.new(1, 1, 1), Transparency = 0.3})
        })
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, 60),
            BackgroundTransparency = 0.89,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {Transparency = 0.5, ThemeTag = {Color = "ElementBorder"}}),
            self.TitleLabel,
            self.ValueLabel,
            self.Track
        })
        
        self.Suffix = Suffix
        
        -- Drag handlers
        local function setupDrag(handle, isMin)
            Creator.AddSignal(handle.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    self.Dragging = isMin and "min" or "max"
                end
            end)
        end
        
        setupDrag(self.MinHandle, true)
        setupDrag(self.MaxHandle, false)
        
        Creator.AddSignal(Services.UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                self.Dragging = nil
            end
        end)
        
        Creator.AddSignal(Services.UserInputService.InputChanged, function(input)
            if self.Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local relX = (input.Position.X - self.Track.AbsolutePosition.X) / self.Track.AbsoluteSize.X
                relX = math.clamp(relX, 0, 1)
                
                local value = Min + relX * (Max - Min)
                value = math.floor(value / Step + 0.5) * Step
                value = math.clamp(value, Min, Max)
                
                if self.Dragging == "min" then
                    if value < self.ValueMax then
                        self.ValueMin = value
                    end
                else
                    if value > self.ValueMin then
                        self.ValueMax = value
                    end
                end
                
                self:UpdateVisual()
                self.Callback(self.ValueMin, self.ValueMax)
            end
        end)
        
        self.Root = self.Frame
        return self
    end
    
    function RangeSlider:UpdateVisual()
        local minPercent = (self.ValueMin - self.Min) / (self.Max - self.Min)
        local maxPercent = (self.ValueMax - self.Min) / (self.Max - self.Min)
        
        self.MinHandle.Position = UDim2.new(minPercent, 0, 0.5, 0)
        self.MaxHandle.Position = UDim2.new(maxPercent, 0, 0.5, 0)
        self.RangeFill.Position = UDim2.fromScale(minPercent, 0)
        self.RangeFill.Size = UDim2.fromScale(maxPercent - minPercent, 1)
        
        self.ValueLabel.Text = self.ValueMin .. self.Suffix .. " - " .. self.ValueMax .. self.Suffix
    end
    
    function RangeSlider:SetRange(min, max)
        self.ValueMin = math.clamp(min, self.Min, self.Max)
        self.ValueMax = math.clamp(max, self.Min, self.Max)
        self:UpdateVisual()
    end
    
    function RangeSlider:GetRange() return self.ValueMin, self.ValueMax end
    
    return RangeSlider
    
end

-- Module: Elements/Rating
_modules["Elements/Rating"] = function()
    --[[
        NexusUI Rating Element
        Star rating input
    ]]
    
    local Rating = {}
    Rating.__index = Rating
    
    local Creator
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
    end
    
    function Rating.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title
        local Default = options.Default or 0
        local Max = options.Max or 5
        local AllowHalf = options.AllowHalf or false
        local ReadOnly = options.ReadOnly or false
        local Size = options.Size or 24
        local Callback = options.Callback or function() end
        
        local self = setmetatable({}, Rating)
        self.Value = Default
        self.Max = Max
        self.Callback = Callback
        self.Stars = {}
        
        local hasTitle = Title ~= nil
        
        -- Title
        if hasTitle then
            self.TitleLabel = Creator.New("TextLabel", {
                Size = UDim2.new(0.5, 0, 0, 20),
                Position = UDim2.fromOffset(12, 8),
                Text = Title,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "Text"}
            })
        end
        
        -- Stars container
        self.StarsContainer = Creator.New("Frame", {
            Size = UDim2.new(0, Max * (Size + 4), 0, Size),
            Position = hasTitle and UDim2.new(1, -12, 0.5, 0) or UDim2.fromScale(0.5, 0.5),
            AnchorPoint = hasTitle and Vector2.new(1, 0.5) or Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1
        }, {
            Creator.New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 4)
            })
        })
        
        -- Create stars
        for i = 1, Max do
            local isFilled = i <= Default
            
            local star = Creator.New("TextButton", {
                Size = UDim2.fromOffset(Size, Size),
                Text = isFilled and "★" or "☆",
                TextSize = Size,
                BackgroundTransparency = 1,
                Parent = self.StarsContainer,
                ThemeTag = {TextColor3 = isFilled and "Accent" or "SubText"}
            })
            
            self.Stars[i] = star
            
            if not ReadOnly then
                Creator.AddSignal(star.MouseEnter, function()
                    self:PreviewRating(i)
                end)
                
                Creator.AddSignal(star.MouseButton1Click, function()
                    self:SetRating(i)
                end)
            end
        end
        
        if not ReadOnly then
            Creator.AddSignal(self.StarsContainer.MouseLeave, function()
                self:ShowRating(self.Value)
            end)
        end
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, hasTitle and 44 or Size + 16),
            BackgroundTransparency = 0.89,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {Transparency = 0.5, ThemeTag = {Color = "ElementBorder"}}),
            hasTitle and self.TitleLabel or nil,
            self.StarsContainer
        })
        
        self.Root = self.Frame
        return self
    end
    
    function Rating:PreviewRating(rating)
        for i, star in ipairs(self.Stars) do
            local isFilled = i <= rating
            star.Text = isFilled and "★" or "☆"
            Creator.OverrideTag(star, {TextColor3 = isFilled and "Accent" or "SubText"})
        end
    end
    
    function Rating:ShowRating(rating)
        for i, star in ipairs(self.Stars) do
            local isFilled = i <= rating
            star.Text = isFilled and "★" or "☆"
            Creator.OverrideTag(star, {TextColor3 = isFilled and "Accent" or "SubText"})
        end
    end
    
    function Rating:SetRating(rating)
        self.Value = rating
        self:ShowRating(rating)
        self.Callback(rating)
    end
    
    function Rating:GetRating() return self.Value end
    
    return Rating
    
end

-- Module: Elements/RichText
_modules["Elements/RichText"] = function()
    --[[
        NexusUI Rich Text Element
        Display formatted text with markdown-like syntax
    ]]
    
    local RichText = {}
    RichText.__index = RichText
    
    local Creator
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
    end
    
    function RichText.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title
        local Content = options.Content or ""
        local TextSize = options.TextSize or 14
        local Selectable = options.Selectable or false
        
        local self = setmetatable({}, RichText)
        
        local hasTitle = Title ~= nil
        
        -- Title
        if hasTitle then
            self.TitleLabel = Creator.New("TextLabel", {
                Size = UDim2.new(1, -24, 0, 20),
                Position = UDim2.fromOffset(12, 8),
                Text = Title,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
                TextSize = 15,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "Text"}
            })
        end
        
        -- Content label with RichText enabled
        self.ContentLabel = Creator.New("TextLabel", {
            Size = UDim2.new(1, -24, 0, 0),
            Position = UDim2.fromOffset(12, hasTitle and 32 or 12),
            Text = Content,
            RichText = true,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = TextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Selectable = Selectable,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, 50),
            BackgroundTransparency = 0.89,
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {
                Transparency = 0.5,
                ThemeTag = {Color = "ElementBorder"}
            }),
            Creator.New("UIPadding", {
                PaddingBottom = UDim.new(0, 12)
            }),
            hasTitle and self.TitleLabel or nil,
            self.ContentLabel
        })
        
        self.Root = self.Frame
        
        return self
    end
    
    function RichText:SetContent(content)
        self.ContentLabel.Text = content
    end
    
    function RichText:SetTitle(title)
        if self.TitleLabel then
            self.TitleLabel.Text = title
        end
    end
    
    -- Helper: Format text with simple markdown
    function RichText.Format(text)
        -- **bold** -> <b>bold</b>
        text = text:gsub("%*%*(.-)%*%*", "<b>%1</b>")
        -- *italic* -> <i>italic</i>
        text = text:gsub("%*(.-)%*", "<i>%1</i>")
        -- __underline__ -> <u>underline</u>
        text = text:gsub("__(.-)__", "<u>%1</u>")
        -- ~~strike~~ -> <s>strike</s>
        text = text:gsub("~~(.-)~~", "<s>%1</s>")
        -- `code` -> <font color="#aaa">code</font>
        text = text:gsub("`(.-)`", '<font color="#aaaaaa">%1</font>')
        -- [color:red]text[/color] -> <font color="red">text</font>
        text = text:gsub("%[color:(.-)%](.-)%[/color%]", '<font color="%1">%2</font>')
        -- [size:20]text[/size] -> <font size="20">text</font>
        text = text:gsub("%[size:(.-)%](.-)%[/size%]", '<font size="%1">%2</font>')
        -- Newlines
        text = text:gsub("\\n", "\n")
        
        return text
    end
    
    return RichText
    
end

-- Module: Elements/SearchBox
_modules["Elements/SearchBox"] = function()
    --[[
        NexusUI Search Box Element
        Searchable input with results
    ]]
    
    local SearchBox = {}
    SearchBox.__index = SearchBox
    
    local Creator
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
    end
    
    function SearchBox.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Search"
        local Placeholder = options.Placeholder or "Search..."
        local Items = options.Items or {}
        local MaxResults = options.MaxResults or 5
        local OnSelect = options.OnSelect or function() end
        local OnSearch = options.OnSearch or function() end
        
        local self = setmetatable({}, SearchBox)
        self.Items = Items
        self.OnSelect = OnSelect
        self.OnSearch = OnSearch
        self.Results = {}
        
        -- Search input
        self.SearchInput = Creator.New("TextBox", {
            Size = UDim2.new(1, -48, 0, 28),
            Position = UDim2.fromOffset(36, 8),
            Text = "",
            PlaceholderText = Placeholder,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 13,
            ClearTextOnFocus = false,
            BackgroundTransparency = 0.9,
            ThemeTag = {BackgroundColor3 = "Input", TextColor3 = "Text", PlaceholderColor3 = "PlaceholderColor"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)}),
            Creator.New("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})
        })
        
        -- Search icon
        self.SearchIcon = Creator.New("ImageLabel", {
            Size = UDim2.fromOffset(18, 18),
            Position = UDim2.new(0, 12, 0, 13),
            Image = "rbxassetid://10734931426",
            BackgroundTransparency = 1,
            ThemeTag = {ImageColor3 = "SubText"}
        })
        
        -- Results container
        self.ResultsContainer = Creator.New("Frame", {
            Size = UDim2.new(1, -24, 0, 0),
            Position = UDim2.fromOffset(12, 44),
            BackgroundTransparency = 1,
            ClipsDescendants = true
        }, {
            Creator.New("UIListLayout", {Padding = UDim.new(0, 2)})
        })
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, 44),
            BackgroundTransparency = 0.89,
            ClipsDescendants = true,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {Transparency = 0.5, ThemeTag = {Color = "ElementBorder"}}),
            self.SearchIcon,
            self.SearchInput,
            self.ResultsContainer
        })
        
        -- Search logic
        Creator.AddSignal(self.SearchInput:GetPropertyChangedSignal("Text"), function()
            self:Search(self.SearchInput.Text)
        end)
        
        Creator.AddSignal(self.SearchInput.FocusLost, function()
            task.delay(0.2, function()
                self:HideResults()
            end)
        end)
        
        self.Root = self.Frame
        return self
    end
    
    function SearchBox:Search(query)
        self.OnSearch(query)
        
        -- Clear old results
        for _, child in ipairs(self.ResultsContainer:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        
        if query == "" then
            self:HideResults()
            return
        end
        
        -- Filter items
        self.Results = {}
        local queryLower = query:lower()
        
        for _, item in ipairs(self.Items) do
            local itemText = type(item) == "table" and item.Text or tostring(item)
            if itemText:lower():find(queryLower, 1, true) then
                table.insert(self.Results, item)
                if #self.Results >= (self.MaxResults or 5) then break end
            end
        end
        
        -- Show results
        if #self.Results > 0 then
            for i, result in ipairs(self.Results) do
                local text = type(result) == "table" and result.Text or tostring(result)
                
                local resultBtn = Creator.New("TextButton", {
                    Size = UDim2.new(1, 0, 0, 28),
                    Text = text,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 0.9,
                    Parent = self.ResultsContainer,
                    ThemeTag = {BackgroundColor3 = "Element", TextColor3 = "Text"}
                }, {
                    Creator.New("UICorner", {CornerRadius = UDim.new(0, 4)}),
                    Creator.New("UIPadding", {PaddingLeft = UDim.new(0, 8)})
                })
                
                Creator.AddSignal(resultBtn.MouseButton1Click, function()
                    self.SearchInput.Text = text
                    self.OnSelect(result)
                    self:HideResults()
                end)
            end
            
            self.Frame.Size = UDim2.new(1, 0, 0, 44 + #self.Results * 30 + 8)
        else
            self:HideResults()
        end
    end
    
    function SearchBox:HideResults()
        for _, child in ipairs(self.ResultsContainer:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        self.Frame.Size = UDim2.new(1, 0, 0, 44)
    end
    
    function SearchBox:SetItems(items)
        self.Items = items
    end
    
    return SearchBox
    
end

-- Module: Elements/SegmentedControl
_modules["Elements/SegmentedControl"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║              SegmentedControl Component v2.15                 ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        Features:
        • Multiple segment options
        • Animated selection indicator
        • Icons per segment
        • Disabled state
        • Compact/full width modes
    ]]
    
    local SegmentedControl = {}
    SegmentedControl.__index = SegmentedControl
    
    local Creator
    local Flipper
    local Icons
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Flipper = _require("Packages/Flipper")
        Icons = _require("Utils/Icons")
    end
    
    function SegmentedControl.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "SegmentedControl"
        local Description = options.Description
        local Segments = options.Segments or {"Option 1", "Option 2"} -- Can be strings or {Value, Icon}
        local Default = options.Default or 1
        local FullWidth = options.FullWidth ~= false -- Default true
        local Disabled = options.Disabled or false
        local Callback = options.Callback or function() end
        local Flag = options.Flag
        
        local self = setmetatable({}, SegmentedControl)
        
        self.Segments = Segments
        self.Value = Default
        self.SelectedIndex = Default
        self.Callback = Callback
        self.Disabled = Disabled
        self.Flag = Flag
        self.SegmentButtons = {}
        
        local hasDescription = Description ~= nil
        local height = hasDescription and 58 or 46
        local segmentHeight = 28
        local segmentPadding = 4
        
        -- Helper to get segment value/icon
        local function getSegmentValue(seg)
            if type(seg) == "table" then
                return seg.Value or seg[1]
            end
            return seg
        end
        
        local function getSegmentIcon(seg)
            if type(seg) == "table" then
                return seg.Icon or seg[2]
            end
            return nil
        end
        
        -- Calculate segment width
        local segmentCount = #Segments
        local segmentWidth = FullWidth and (1 / segmentCount) or nil
        
        -- Segments container
        self.SegmentsContainer = Creator.New("Frame", {
            Size = FullWidth and UDim2.new(1, -24, 0, segmentHeight) or UDim2.fromOffset(segmentCount * 80 + (segmentCount - 1) * 4, segmentHeight),
            Position = UDim2.new(1, -12, 0, hasDescription and 24 or (height - segmentHeight) / 2),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 0.95,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)}),
            Creator.New("UIPadding", {
                PaddingLeft = UDim.new(0, segmentPadding),
                PaddingRight = UDim.new(0, segmentPadding),
                PaddingTop = UDim.new(0, segmentPadding),
                PaddingBottom = UDim.new(0, segmentPadding)
            })
        })
        
        -- Selection indicator (animated background)
        local indicatorWidth = FullWidth 
            and (1 / segmentCount) 
            or (80 / (segmentCount * 80 + (segmentCount - 1) * 4))
        local indicatorPos = (Default - 1) * (1 / segmentCount)
        
        self.SelectionIndicator = Creator.New("Frame", {
            Size = UDim2.new(indicatorWidth, -segmentPadding, 1, 0),
            Position = UDim2.new(indicatorPos, 0, 0, 0),
            BackgroundTransparency = 0.1,
            ZIndex = 1,
            Parent = self.SegmentsContainer,
            ThemeTag = {BackgroundColor3 = "Accent"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 4)})
        })
        
        -- Create segment buttons
        for i, segment in ipairs(Segments) do
            local value = getSegmentValue(segment)
            local icon = getSegmentIcon(segment)
            local isSelected = (i == Default)
            
            -- Resolve icon
            local iconAsset = nil
            if icon then
                if type(icon) == "string" then
                    if icon:match("^rbxassetid://") then
                        iconAsset = icon
                    else
                        iconAsset = Icons.Get(icon) or nil
                    end
                end
            end
            
            local hasIcon = iconAsset ~= nil
            
            local segmentChildren = {
                Creator.New("UICorner", {CornerRadius = UDim.new(0, 4)})
            }
            
            -- Icon
            if hasIcon then
                table.insert(segmentChildren, Creator.New("ImageLabel", {
                    Image = iconAsset,
                    Size = UDim2.fromOffset(14, 14),
                    Position = UDim2.new(0.5, -20, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    ThemeTag = {ImageColor3 = isSelected and "Background" or "Text"}
                }))
            end
            
            -- Label
            table.insert(segmentChildren, Creator.New("TextLabel", {
                Name = "Label",
                Text = tostring(value),
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
                TextSize = 12,
                Size = UDim2.fromScale(1, 1),
                Position = hasIcon and UDim2.fromOffset(8, 0) or UDim2.new(),
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = isSelected and "Background" or "Text"}
            }))
            
            local segmentButton = Creator.New("TextButton", {
                Size = FullWidth and UDim2.new(1 / segmentCount, -segmentPadding / 2, 1, 0) or UDim2.fromOffset(80, segmentHeight - segmentPadding * 2),
                Position = FullWidth 
                    and UDim2.new((i - 1) / segmentCount, 0, 0, 0) 
                    or UDim2.fromOffset((i - 1) * (80 + 4), 0),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                Active = not Disabled,
                ZIndex = 2,
                Parent = self.SegmentsContainer
            }, segmentChildren)
            
            self.SegmentButtons[i] = {
                Button = segmentButton,
                Value = value,
                Selected = isSelected
            }
            
            -- Click handler
            Creator.AddSignal(segmentButton.MouseButton1Click, function()
                if not self.Disabled then
                    self:Select(i)
                end
            end)
        end
        
        -- Animation motor for indicator
        self.IndicatorMotor = Flipper.SingleMotor.new(indicatorPos)
        self.IndicatorMotor:onStep(function(pos)
            self.SelectionIndicator.Position = UDim2.new(pos, 0, 0, 0)
        end)
        
        -- Title
        self.Label = Creator.New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            Text = Title,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(0.4, 0, 0, 14),
            Position = hasDescription and UDim2.fromOffset(12, 9) or UDim2.new(0, 12, 0.5, 0),
            AnchorPoint = hasDescription and Vector2.zero or Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            TextTransparency = Disabled and 0.5 or 0,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Description
        if hasDescription then
            self.DescriptionLabel = Creator.New("TextLabel", {
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                Text = Description,
                TextSize = 12,
                TextTransparency = Disabled and 0.6 or 0.4,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(0.4, 0, 0, 12),
                Position = UDim2.fromOffset(12, 27),
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "SubText"}
            })
        end
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 0.89,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {
                Transparency = 0.5,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                ThemeTag = {Color = "ElementBorder"}
            }),
            self.Label,
            hasDescription and self.DescriptionLabel or nil,
            self.SegmentsContainer
        })
        
        self.Root = self.Frame
        
        return self
    end
    
    function SegmentedControl:Select(index)
        if self.Disabled or index == self.SelectedIndex then return end
        
        local segmentCount = #self.Segments
        
        -- Update previous selection
        local prevSegment = self.SegmentButtons[self.SelectedIndex]
        if prevSegment then
            prevSegment.Selected = false
            local label = prevSegment.Button:FindFirstChild("Label")
            if label then
                Creator.OverrideTag(label, {TextColor3 = "Text"})
            end
        end
        
        -- Update new selection
        self.SelectedIndex = index
        self.Value = self.SegmentButtons[index].Value
        self.SegmentButtons[index].Selected = true
        
        local label = self.SegmentButtons[index].Button:FindFirstChild("Label")
        if label then
            Creator.OverrideTag(label, {TextColor3 = "Background"})
        end
        
        -- Animate indicator
        local targetPos = (index - 1) / segmentCount
        self.IndicatorMotor:setGoal(Flipper.Spring.new(targetPos, {frequency = 8, dampingRatio = 0.8}))
        
        self.Callback(self.Value, index)
    end
    
    function SegmentedControl:Set(indexOrValue, noCallback)
        if self.Disabled then return end
        
        local targetIndex = nil
        
        if type(indexOrValue) == "number" then
            targetIndex = indexOrValue
        else
            for i, seg in ipairs(self.SegmentButtons) do
                if seg.Value == indexOrValue then
                    targetIndex = i
                    break
                end
            end
        end
        
        if targetIndex and targetIndex ~= self.SelectedIndex then
            local prevCallback = self.Callback
            if noCallback then
                self.Callback = function() end
            end
            self:Select(targetIndex)
            self.Callback = prevCallback
        end
    end
    
    function SegmentedControl:SetDisabled(disabled)
        self.Disabled = disabled
        
        for _, seg in ipairs(self.SegmentButtons) do
            seg.Button.Active = not disabled
        end
        
        if self.Label then
            self.Label.TextTransparency = disabled and 0.5 or 0
        end
        
        if self.DescriptionLabel then
            self.DescriptionLabel.TextTransparency = disabled and 0.6 or 0.4
        end
    end
    
    function SegmentedControl:GetValue()
        return self.Value, self.SelectedIndex
    end
    
    function SegmentedControl:Destroy()
        if self.Frame then
            self.Frame:Destroy()
        end
    end
    
    return SegmentedControl
    
end

-- Module: Elements/Slider
_modules["Elements/Slider"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                   Slider Component v2.15                      ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        Features:
        - Range mode (dual-handle for min/max)
        - Step markers visual indicators
        - Floating value tooltip
        - Gradient fill colors
        - Vertical orientation option
        - Click-to-edit value input
        - Disabled state
        - Size variants
    ]]
    
    local Slider = {}
    Slider.__index = Slider
    
    local Creator
    local Flipper
    local Services
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Flipper = _require("Packages/Flipper")
        Services = _require("Core/Services")
    end
    
    -- Size configurations
    local Sizes = {
        small = { height = 44, barHeight = 6, knobSize = 14, fontSize = 12 },
        medium = { height = 52, barHeight = 10, knobSize = 18, fontSize = 14 },
        large = { height = 64, barHeight = 14, knobSize = 24, fontSize = 16 }
    }
    
    function Slider.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Slider"
        local Description = options.Description or ""
        local Min = (options.Min ~= nil) and options.Min or 0
        local Max = (options.Max ~= nil) and options.Max or 100
        local Default = (options.Default ~= nil) and options.Default or Min
        local Increment = (options.Increment ~= nil) and options.Increment or 1
        local Suffix = options.Suffix or ""w
        local Callback = options.Callback or function() end
        local Size = options.Size or "medium"
        local Disabled = (options.Disabled ~= nil) and options.Disabled or false
        local ShowSteps = (options.ShowSteps ~= nil) and options.ShowSteps or false
        local ShowTooltip = (options.ShowTooltip ~= nil) and options.ShowTooltip or true
        local GradientColors = options.GradientColors -- {Color3, Color3} for gradient fill
        local Flag = options.Flag
   
        
        local self = setmetatable({}, Slider)
        
        self.Value = Default
        self.Min = Min
        self.Max = Max
        self.Increment = Increment
        self.Callback = Callback
        self.Dragging = false
        self.Suffix = Suffix
        self.Disabled = Disabled
        self.Flag = Flag
        self.ShowTooltip = ShowTooltip
        
        -- Get size config
        local sizeConfig = Sizes[Size] or Sizes.medium
        
        local hasDescription = Description ~= nil
        local height = hasDescription and (sizeConfig.height + 10) or sizeConfig.height
        
        -- Title
        self.Label = Creator.New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            Text = Title,
            TextSize = sizeConfig.fontSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -90, 0, sizeConfig.fontSize),
            Position = UDim2.fromOffset(12, 10),
            BackgroundTransparency = 1,
            TextTransparency = Disabled and 0.5 or 0,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Description
        if hasDescription then
            self.DescriptionLabel = Creator.New("TextLabel", {
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                Text = Description,
                TextSize = 12,
                TextTransparency = Disabled and 0.6 or 0.4,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -90, 0, 12),
                Position = UDim2.fromOffset(12, 26),
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "SubText"}
            })
        end
        
        -- Value display (clickable to edit)
        self.ValueLabel = Creator.New("TextButton", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
            Text = tostring(Default) .. Suffix,
            TextSize = sizeConfig.fontSize - 1,
            TextXAlignment = Enum.TextXAlignment.Right,
            Size = UDim2.new(0, 70, 0, sizeConfig.fontSize),
            Position = UDim2.new(1, -12, 0, 10),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            TextTransparency = Disabled and 0.5 or 0,
            ThemeTag = {TextColor3 = "Accent"}
        })
        
        -- Value input box (hidden by default)
        self.ValueInput = Creator.New("TextBox", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
            Text = tostring(Default),
            TextSize = sizeConfig.fontSize - 1,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.new(0, 60, 0, 22),
            Position = UDim2.new(1, -12, 0, 6),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 0.8,
            Visible = false,
            ClearTextOnFocus = false,
            ThemeTag = {TextColor3 = "Accent", BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 4)}),
            Creator.New("UIStroke", {
                Thickness = 1,
                ThemeTag = {Color = "Accent"}
            })
        })
        
        -- Progress bar fill
        local initialPercent = (Default - Min) / (Max - Min)
        
        local fillChildren = {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
        }
        
        -- Add gradient if specified
        if GradientColors and #GradientColors >= 2 then
            table.insert(fillChildren, Creator.New("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, GradientColors[1]),
                    ColorSequenceKeypoint.new(1, GradientColors[2])
                })
            }))
            self.Fill = Creator.New("Frame", {
                Size = UDim2.new(initialPercent, 0, 1, 0),
                BackgroundColor3 = GradientColors[1],
                BackgroundTransparency = Disabled and 0.5 or 0
            }, fillChildren)
        else
            self.Fill = Creator.New("Frame", {
                Size = UDim2.new(initialPercent, 0, 1, 0),
                BackgroundTransparency = Disabled and 0.5 or 0,
                ThemeTag = {BackgroundColor3 = "SliderProgress"}
            }, fillChildren)
        end
        
        -- Floating tooltip
        self.Tooltip = Creator.New("Frame", {
            Size = UDim2.fromOffset(50, 24),
            Position = UDim2.new(initialPercent, 0, 0, -30),
            AnchorPoint = Vector2.new(0.5, 1),
            BackgroundTransparency = 0.1,
            Visible = false,
            ZIndex = 10,
            ThemeTag = {BackgroundColor3 = "Accent"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)}),
            Creator.New("TextLabel", {
                Name = "Value",
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
                Text = tostring(Default) .. Suffix,
                TextSize = 11,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                ZIndex = 11
            }),
            -- Triangle pointer
            Creator.New("ImageLabel", {
                Image = "rbxassetid://7734048966", -- Down arrow
                Size = UDim2.fromOffset(10, 6),
                Position = UDim2.new(0.5, 0, 1, -1),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                Rotation = 180,
                ZIndex = 10,
                ThemeTag = {ImageColor3 = "Accent"}
            })
        })
        
        -- Knob with shadow
        self.Knob = Creator.New("Frame", {
            Size = UDim2.fromOffset(sizeConfig.knobSize, sizeConfig.knobSize),
            Position = UDim2.new(initialPercent, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            ZIndex = 2
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)}),
            Creator.New("UIStroke", {
                Thickness = 2,
                ThemeTag = {Color = "Accent"}
            }),
            -- Shadow
            Creator.New("ImageLabel", {
                Image = "rbxassetid://5554236805",
                Size = UDim2.fromOffset(sizeConfig.knobSize + 6, sizeConfig.knobSize + 6),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                ImageTransparency = 0.7,
                ZIndex = 1
            }),
            self.Tooltip
        })
        
        -- Step markers container
        self.StepMarkersContainer = nil
        if ShowSteps and Increment > 0 then
            self.StepMarkersContainer = Creator.New("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                ZIndex = 0
            })
            
            local stepCount = math.floor((Max - Min) / Increment)
            if stepCount <= 20 then -- Only show if reasonable number of steps
                for i = 0, stepCount do
                    local pos = i / stepCount
                    Creator.New("Frame", {
                        Size = UDim2.fromOffset(2, sizeConfig.barHeight + 4),
                        Position = UDim2.new(pos, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 0.7,
                        Parent = self.StepMarkersContainer,
                        ThemeTag = {BackgroundColor3 = "SubText"}
                    }, {
                        Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
                    })
                end
            end
        end
        
        -- Slider bar (clickable area)
        local barChildren = {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)}),
            self.Fill,
            self.Knob
        }
        
        if self.StepMarkersContainer then
            table.insert(barChildren, self.StepMarkersContainer)
        end
        
        self.SliderBar = Creator.New("TextButton", {
            Size = UDim2.new(1, -24, 0, sizeConfig.barHeight),
            Position = UDim2.new(0, 12, 1, -14),
            AnchorPoint = Vector2.new(0, 1),
            BackgroundTransparency = Disabled and 0.8 or 0.6,
            Text = "",
            AutoButtonColor = false,
            Active = not Disabled,
            ThemeTag = {BackgroundColor3 = "SliderBackground"}
        }, barChildren)
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 0.89,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {
                Transparency = 0.5,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                ThemeTag = {Color = "ElementBorder"}
            }),
            self.Label,
            hasDescription and self.DescriptionLabel or nil,
            self.ValueLabel,
            self.ValueInput,
            self.SliderBar
        })
        
        -- Animation motors
        self.KnobMotor = Flipper.SingleMotor.new(1)
        self.KnobMotor:onStep(function(scale)
            if self.Knob then
                self.Knob.Size = UDim2.fromOffset(sizeConfig.knobSize * scale, sizeConfig.knobSize * scale)
            end
        end)
        
        -- Drag functionality
        local function updateValue(input)
            if self.Disabled then return end
            
            local barAbsPos = self.SliderBar.AbsolutePosition.X
            local barAbsSize = self.SliderBar.AbsoluteSize.X
            local mouseX = input.Position.X
            
            local relativeX = math.clamp((mouseX - barAbsPos) / barAbsSize, 0, 1)
            local rawValue = Min + (Max - Min) * relativeX
            local steppedValue = math.floor(rawValue / Increment + 0.5) * Increment
            steppedValue = math.clamp(steppedValue, Min, Max)
            
            -- Round for display
            if Increment >= 1 then
                steppedValue = math.floor(steppedValue)
            else
                -- Round to appropriate decimal places
                local decimals = math.max(0, -math.floor(math.log10(Increment)))
                steppedValue = math.floor(steppedValue * 10^decimals + 0.5) / 10^decimals
            end
            
            self:Set(steppedValue, true)
        end
        
        if not Disabled then
            Creator.AddSignal(self.SliderBar.MouseButton1Down, function()
                self.Dragging = true
                self.KnobMotor:setGoal(Flipper.Spring.new(1.15, {frequency = 8}))
                if ShowTooltip then
                    self.Tooltip.Visible = true
                end
            end)
            
            Creator.AddSignal(self.SliderBar.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    self.Dragging = true
                    self.KnobMotor:setGoal(Flipper.Spring.new(1.15, {frequency = 8}))
                    if ShowTooltip then
                        self.Tooltip.Visible = true
                    end
                    updateValue(input)
                end
            end)
            
            Creator.AddSignal(Services.UserInputService.InputChanged, function(input)
                if self.Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateValue(input)
                end
            end)
            
            Creator.AddSignal(Services.UserInputService.InputEnded, function(input)
                if self.Dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    self.Dragging = false
                    self.KnobMotor:setGoal(Flipper.Spring.new(1, {frequency = 8}))
                    self.Tooltip.Visible = false
                    self.Callback(self.Value)
                end
            end)
            
            -- Click value label to edit
            Creator.AddSignal(self.ValueLabel.MouseButton1Click, function()
                if not self.Disabled then
                    self.ValueLabel.Visible = false
                    self.ValueInput.Visible = true
                    self.ValueInput.Text = tostring(self.Value)
                    self.ValueInput:CaptureFocus()
                end
            end)
            
            Creator.AddSignal(self.ValueInput.FocusLost, function(enterPressed)
                self.ValueInput.Visible = false
                self.ValueLabel.Visible = true
                
                if enterPressed then
                    local num = tonumber(self.ValueInput.Text)
                    if num then
                        local steppedValue = math.floor(num / Increment + 0.5) * Increment
                        steppedValue = math.clamp(steppedValue, Min, Max)
                        self:Set(steppedValue)
                    end
                end
            end)
        end
        
        -- Hover effect on frame
        self.HoverMotor, self.SetHover = Creator.SpringMotor(0.89, self.Frame, "BackgroundTransparency")
        
        Creator.AddSignal(self.Frame.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and not self.Disabled then
                self.SetHover(0.85)
            end
        end)
        
        Creator.AddSignal(self.Frame.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                self.SetHover(0.89)
            end
        end)
        
        self.Root = self.Frame
        self.SizeConfig = sizeConfig
        
        return self
    end
    
    function Slider:Set(value, skipCallback)
        if self.Disabled then return end
        
        value = math.clamp(value, self.Min, self.Max)
        self.Value = value
        
        local percent = (value - self.Min) / (self.Max - self.Min)
        
        -- Update visuals with smooth tween if not dragging
        if self.Dragging then
            self.Fill.Size = UDim2.new(percent, 0, 1, 0)
            self.Knob.Position = UDim2.new(percent, 0, 0.5, 0)
        else
            Creator.Tween(self.Fill, {Size = UDim2.new(percent, 0, 1, 0)}, 0.08)
            Creator.Tween(self.Knob, {Position = UDim2.new(percent, 0, 0.5, 0)}, 0.08)
        end
        
        -- Update tooltip position
        if self.Tooltip then
            self.Tooltip.Position = UDim2.new(0, 0, 0, -30)
            local tooltipLabel = self.Tooltip:FindFirstChild("Value")
            if tooltipLabel then
                tooltipLabel.Text = tostring(value) .. self.Suffix
            end
        end
        
        self.ValueLabel.Text = tostring(value) .. self.Suffix
        
        if not skipCallback and self.Callback then
            self.Callback(value)
        end
    end
    
    function Slider:SetDisabled(disabled)
        self.Disabled = disabled
        self.SliderBar.Active = not disabled
        
        if self.Label then
            self.Label.TextTransparency = disabled and 0.5 or 0
        end
        
        if self.DescriptionLabel then
            self.DescriptionLabel.TextTransparency = disabled and 0.6 or 0.4
        end
        
        if self.Fill then
            self.Fill.BackgroundTransparency = disabled and 0.5 or 0
        end
        
        if self.SliderBar then
            self.SliderBar.BackgroundTransparency = disabled and 0.8 or 0.6
        end
    end
    
    function Slider:SetTitle(title)
        if self.Label then
            self.Label.Text = title
        end
    end
    
    function Slider:GetValue()
        return self.Value
    end
    
    function Slider:Destroy()
        if self.Frame then
            self.Frame:Destroy()
        end
    end
    
    return Slider
    
end

-- Module: Elements/StatCard
_modules["Elements/StatCard"] = function()
    --[[
        NexusUI Stat Card Element
        Display stats with icon/label/value
    ]]
    
    local StatCard = {}
    StatCard.__index = StatCard
    
    local Creator, ImageLoader
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        ImageLoader = _require("Utils/ImageLoader")
    end
    
    function StatCard.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Stat"
        local Value = options.Value or "0"
        local Icon = options.Icon -- Supports raw URL or rbxassetid
        local IconColor = options.IconColor
        local Suffix = options.Suffix or ""
        local Prefix = options.Prefix or ""
        local Trend = options.Trend -- "up", "down", or nil
        local TrendValue = options.TrendValue
        local Compact = options.Compact or false
        
        local self = setmetatable({}, StatCard)
        self.Value = Value
        
        local height = Compact and 50 or 70
        
        -- Icon
        if Icon then
            self.IconLabel = Creator.New("ImageLabel", {
                Size = UDim2.fromOffset(Compact and 24 or 32, Compact and 24 or 32),
                Position = UDim2.new(0, 12, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                ThemeTag = IconColor and nil or {ImageColor3 = "Accent"}
            })
            if IconColor then self.IconLabel.ImageColor3 = IconColor end
            ImageLoader.SetImage(self.IconLabel, Icon)
        end
        
        local textX = Icon and (Compact and 46 or 56) or 12
        
        -- Title
        self.TitleLabel = Creator.New("TextLabel", {
            Size = UDim2.new(1, -textX - 12, 0, 16),
            Position = UDim2.fromOffset(textX, Compact and 8 or 12),
            Text = Title,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 0.4,
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "SubText"}
        })
        
        -- Value
        self.ValueLabel = Creator.New("TextLabel", {
            Size = UDim2.new(1, -textX - 60, 0, 26),
            Position = UDim2.fromOffset(textX, Compact and 26 or 32),
            Text = Prefix .. tostring(Value) .. Suffix,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
            TextSize = Compact and 18 or 22,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Trend indicator
        if Trend then
            local trendColor = Trend == "up" and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(255, 80, 80)
            local trendIcon = Trend == "up" and "▲" or "▼"
            
            self.TrendLabel = Creator.New("TextLabel", {
                Size = UDim2.fromOffset(50, 20),
                Position = UDim2.new(1, -12, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                Text = trendIcon .. " " .. (TrendValue or ""),
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
                TextSize = 12,
                TextColor3 = trendColor,
                TextXAlignment = Enum.TextXAlignment.Right,
                BackgroundTransparency = 1
            })
        end
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 0.89,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {Transparency = 0.5, ThemeTag = {Color = "ElementBorder"}}),
            Icon and self.IconLabel or nil,
            self.TitleLabel,
            self.ValueLabel,
            Trend and self.TrendLabel or nil
        })
        
        self.Suffix = Suffix
        self.Prefix = Prefix
        self.Root = self.Frame
        return self
    end
    
    function StatCard:SetValue(value, animate)
        if animate then
            -- Animated counter
            local startVal = tonumber(self.Value) or 0
            local endVal = tonumber(value) or 0
            local duration = 0.5
            local startTime = tick()
            
            task.spawn(function()
                while true do
                    local elapsed = tick() - startTime
                    local progress = math.min(elapsed / duration, 1)
                    local currentVal = math.floor(startVal + (endVal - startVal) * progress)
                    self.ValueLabel.Text = self.Prefix .. tostring(currentVal) .. self.Suffix
                    
                    if progress >= 1 then break end
                    task.wait()
                end
            end)
        else
            self.ValueLabel.Text = self.Prefix .. tostring(value) .. self.Suffix
        end
        self.Value = value
    end
    
    return StatCard
    
end

-- Module: Elements/Stepper
_modules["Elements/Stepper"] = function()
    --[[
        NexusUI Stepper Element (Number input with +/- buttons)
    ]]
    
    local Stepper = {}
    Stepper.__index = Stepper
    
    local Creator
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
    end
    
    function Stepper.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Value"
        local Default = options.Default or 0
        local Min = options.Min or 0
        local Max = options.Max or 100
        local Step = options.Step or 1
        local Callback = options.Callback or function() end
        
        local self = setmetatable({}, Stepper)
        self.Value = Default
        self.Min = Min
        self.Max = Max
        self.Step = Step
        self.Callback = Callback
        
        -- Minus button
        self.MinusBtn = Creator.New("TextButton", {
            Size = UDim2.fromOffset(32, 32),
            Position = UDim2.new(1, -100, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Text = "−",
            TextSize = 20,
            ThemeTag = {BackgroundColor3 = "Element", TextColor3 = "Text"}
        }, {Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)})})
        
        -- Value display
        self.ValueLabel = Creator.New("TextLabel", {
            Size = UDim2.fromOffset(50, 32),
            Position = UDim2.new(1, -64, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Text = tostring(Default),
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            TextSize = 14,
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Plus button
        self.PlusBtn = Creator.New("TextButton", {
            Size = UDim2.fromOffset(32, 32),
            Position = UDim2.new(1, -12, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            Text = "+",
            TextSize = 18,
            ThemeTag = {BackgroundColor3 = "Accent", TextColor3 = "Text"}
        }, {Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)})})
        
        -- Title
        self.TitleLabel = Creator.New("TextLabel", {
            Size = UDim2.new(0.5, 0, 1, 0),
            Position = UDim2.fromOffset(12, 0),
            Text = Title,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, 44),
            BackgroundTransparency = 0.89,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {Transparency = 0.5, ThemeTag = {Color = "ElementBorder"}}),
            self.TitleLabel,
            self.MinusBtn,
            self.ValueLabel,
            self.PlusBtn
        })
        
        -- Button handlers
        Creator.AddSignal(self.MinusBtn.MouseButton1Click, function()
            self:Decrement()
        end)
        
        Creator.AddSignal(self.PlusBtn.MouseButton1Click, function()
            self:Increment()
        end)
        
        self.Root = self.Frame
        return self
    end
    
    function Stepper:Increment()
        self:SetValue(self.Value + self.Step)
    end
    
    function Stepper:Decrement()
        self:SetValue(self.Value - self.Step)
    end
    
    function Stepper:SetValue(value)
        self.Value = math.clamp(value, self.Min, self.Max)
        self.ValueLabel.Text = tostring(self.Value)
        self.Callback(self.Value)
    end
    
    function Stepper:GetValue() return self.Value end
    
    return Stepper
    
end

-- Module: Elements/Table
_modules["Elements/Table"] = function()
    --[[
        NexusUI Table Element
        Sortable data table with columns
    ]]
    
    local Table = {}
    Table.__index = Table
    
    local Creator
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
    end
    
    function Table.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title
        local Columns = options.Columns or {"Column 1", "Column 2"}
        local Data = options.Data or {}
        local RowHeight = options.RowHeight or 28
        local MaxRows = options.MaxRows or 5
        local Sortable = options.Sortable ~= false
        local OnRowClick = options.OnRowClick
        
        local self = setmetatable({}, Table)
        self.Columns = Columns
        self.Data = Data
        self.SortColumn = nil
        self.SortAsc = true
        
        local hasTitle = Title ~= nil
        local headerHeight = 30
        local contentHeight = math.min(#Data, MaxRows) * RowHeight
        local height = (hasTitle and 30 or 0) + headerHeight + contentHeight + 20
        
        -- Title
        if hasTitle then
            self.TitleLabel = Creator.New("TextLabel", {
                Size = UDim2.new(1, -24, 0, 20),
                Position = UDim2.fromOffset(12, 8),
                Text = Title,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "Text"}
            })
        end
        
        -- Header row
        local colWidth = 1 / #Columns
        self.HeaderRow = Creator.New("Frame", {
            Size = UDim2.new(1, -24, 0, headerHeight),
            Position = UDim2.fromOffset(12, hasTitle and 32 or 8),
            BackgroundTransparency = 0.9,
            ThemeTag = {BackgroundColor3 = "Topbar"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)}),
            Creator.New("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal})
        })
        
        for i, col in ipairs(Columns) do
            local headerCell = Creator.New("TextButton", {
                Size = UDim2.new(colWidth, 0, 1, 0),
                Text = col .. (Sortable and " ▼" or ""),
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
                TextSize = 12,
                BackgroundTransparency = 1,
                Parent = self.HeaderRow,
                ThemeTag = {TextColor3 = "Text"}
            })
            
            if Sortable then
                Creator.AddSignal(headerCell.MouseButton1Click, function()
                    self:Sort(i)
                end)
            end
        end
        
        -- Data rows container
        self.RowsContainer = Creator.New("ScrollingFrame", {
            Size = UDim2.new(1, -24, 0, contentHeight),
            Position = UDim2.fromOffset(12, (hasTitle and 32 or 8) + headerHeight + 4),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            CanvasSize = UDim2.fromOffset(0, #Data * RowHeight),
            ThemeTag = {ScrollBarImageColor3 = "Text"}
        }, {
            Creator.New("UIListLayout", {Padding = UDim.new(0, 2)})
        })
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 0.89,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {Transparency = 0.5, ThemeTag = {Color = "ElementBorder"}}),
            hasTitle and self.TitleLabel or nil,
            self.HeaderRow,
            self.RowsContainer
        })
        
        self.OnRowClick = OnRowClick
        self.RowHeight = RowHeight
        self:Render()
        
        self.Root = self.Frame
        return self
    end
    
    function Table:Render()
        -- Clear existing rows
        for _, child in ipairs(self.RowsContainer:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        
        local colWidth = 1 / #self.Columns
        
        for rowIndex, rowData in ipairs(self.Data) do
            local row = Creator.New("Frame", {
                Size = UDim2.new(1, 0, 0, self.RowHeight),
                BackgroundTransparency = rowIndex % 2 == 0 and 0.95 or 1,
                Parent = self.RowsContainer,
                ThemeTag = {BackgroundColor3 = "Element"}
            }, {
                Creator.New("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal})
            })
            
            for colIndex, cellValue in ipairs(rowData) do
                Creator.New("TextLabel", {
                    Size = UDim2.new(colWidth, 0, 1, 0),
                    Text = tostring(cellValue),
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                    TextSize = 12,
                    BackgroundTransparency = 1,
                    Parent = row,
                    ThemeTag = {TextColor3 = "Text"}
                })
            end
            
            if self.OnRowClick then
                local clickDetector = Creator.New("TextButton", {
                    Size = UDim2.fromScale(1, 1),
                    Text = "",
                    BackgroundTransparency = 1,
                    Parent = row
                })
                Creator.AddSignal(clickDetector.MouseButton1Click, function()
                    self.OnRowClick(rowIndex, rowData)
                end)
            end
        end
        
        self.RowsContainer.CanvasSize = UDim2.fromOffset(0, #self.Data * self.RowHeight)
    end
    
    function Table:Sort(columnIndex)
        if self.SortColumn == columnIndex then
            self.SortAsc = not self.SortAsc
        else
            self.SortColumn = columnIndex
            self.SortAsc = true
        end
        
        table.sort(self.Data, function(a, b)
            local valA = a[columnIndex]
            local valB = b[columnIndex]
            if self.SortAsc then
                return tostring(valA) < tostring(valB)
            else
                return tostring(valA) > tostring(valB)
            end
        end)
        
        self:Render()
    end
    
    function Table:SetData(data)
        self.Data = data
        self:Render()
    end
    
    function Table:AddRow(row)
        table.insert(self.Data, row)
        self:Render()
    end
    
    return Table
    
end

-- Module: Elements/TabsElement
_modules["Elements/TabsElement"] = function()
    --[[
        NexusUI Tabs Element (Inline tabs, not window tabs)
        Horizontal tab navigation within content
    ]]
    
    local TabsElement = {}
    TabsElement.__index = TabsElement
    
    local Creator
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
    end
    
    function TabsElement.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Tabs = options.Tabs or {} -- {Title, Content or OnSelect}
        local Default = options.Default or 1
        local Style = options.Style or "Pills" -- Pills, Underline, Boxed
        
        local self = setmetatable({}, TabsElement)
        self.Selected = Default
        self.Tabs = Tabs
        self.TabButtons = {}
        
        local tabBarHeight = 36
        
        -- Tab bar
        self.TabBar = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, tabBarHeight),
            BackgroundTransparency = 1
        }, {
            Creator.New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 4)
            })
        })
        
        -- Create tab buttons
        for i, tab in ipairs(Tabs) do
            local title = type(tab) == "table" and tab.Title or tostring(tab)
            local isSelected = i == Default
            
            local tabBtn = Creator.New("TextButton", {
                Size = UDim2.new(0, 0, 0, 30),
                AutomaticSize = Enum.AutomaticSize.X,
                Text = title,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", isSelected and Enum.FontWeight.Medium or Enum.FontWeight.Regular),
                TextSize = 13,
                BackgroundTransparency = Style == "Underline" and 1 or (isSelected and 0.85 or 0.95),
                Parent = self.TabBar,
                ThemeTag = {
                    BackgroundColor3 = isSelected and "Accent" or "Element",
                    TextColor3 = "Text"
                }
            }, {
                Creator.New("UICorner", {CornerRadius = Style == "Underline" and UDim.new(0, 0) or UDim.new(0, 6)}),
                Creator.New("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)})
            })
            
            -- Underline indicator
            if Style == "Underline" then
                Creator.New("Frame", {
                    Size = UDim2.new(1, 0, 0, 2),
                    Position = UDim2.new(0, 0, 1, 0),
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundTransparency = isSelected and 0 or 1,
                    Parent = tabBtn,
                    ThemeTag = {BackgroundColor3 = "Accent"}
                })
            end
            
            self.TabButtons[i] = tabBtn
            
            Creator.AddSignal(tabBtn.MouseButton1Click, function()
                self:Select(i)
            end)
        end
        
        -- Content container
        self.ContentContainer = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, 100),
            Position = UDim2.fromOffset(0, tabBarHeight + 8),
            BackgroundTransparency = 1
        })
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, 150),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = parent
        }, {
            self.TabBar,
            self.ContentContainer
        })
        
        self.Style = Style
        
        -- Show initial content
        self:ShowContent(Default)
        
        self.Root = self.Frame
        return self
    end
    
    function TabsElement:Select(index)
        if index == self.Selected then return end
        
        local oldIndex = self.Selected
        self.Selected = index
        
        -- Update button styles
        for i, btn in ipairs(self.TabButtons) do
            local isSelected = i == index
            
            if self.Style == "Underline" then
                local underline = btn:FindFirstChildWhichIsA("Frame")
                if underline then
                    Creator.Tween(underline, {BackgroundTransparency = isSelected and 0 or 1}, 0.2)
                end
            else
                Creator.Tween(btn, {BackgroundTransparency = isSelected and 0.85 or 0.95}, 0.2)
            end
            
            Creator.OverrideTag(btn, {BackgroundColor3 = isSelected and "Accent" or "Element"})
        end
        
        self:ShowContent(index)
    end
    
    function TabsElement:ShowContent(index)
        -- Clear old content
        for _, child in ipairs(self.ContentContainer:GetChildren()) do
            child:Destroy()
        end
        
        local tab = self.Tabs[index]
        if not tab then return end
        
        if type(tab) == "table" then
            if tab.OnSelect then
                tab.OnSelect(self.ContentContainer)
            elseif tab.Content then
                Creator.New("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Text = tab.Content,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                    TextSize = 13,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Parent = self.ContentContainer,
                    ThemeTag = {TextColor3 = "Text"}
                })
            end
        end
    end
    
    function TabsElement:GetContainer()
        return self.ContentContainer
    end
    
    return TabsElement
    
end

-- Module: Elements/Textbox
_modules["Elements/Textbox"] = function()
    --[[
        NexusUI Textbox Element (Multi-line)
        Large text input area
    ]]
    
    local Textbox = {}
    Textbox.__index = Textbox
    
    local Creator
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
    end
    
    function Textbox.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title
        local Default = options.Default or ""
        local Placeholder = options.Placeholder or "Enter text..."
        local Lines = options.Lines or 4
        local MaxChars = options.MaxChars
        local Callback = options.Callback or function() end
        
        local self = setmetatable({}, Textbox)
        self.Value = Default
        self.Callback = Callback
        
        local hasTitle = Title ~= nil
        local textHeight = Lines * 20
        local height = textHeight + (hasTitle and 30 or 0) + 20
        
        -- Title
        if hasTitle then
            self.TitleLabel = Creator.New("TextLabel", {
                Size = UDim2.new(1, -24, 0, 18),
                Position = UDim2.fromOffset(12, 8),
                Text = Title,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "Text"}
            })
        end
        
        -- Text input
        self.TextBox = Creator.New("TextBox", {
            Size = UDim2.new(1, -24, 0, textHeight),
            Position = UDim2.fromOffset(12, hasTitle and 32 or 10),
            Text = Default,
            PlaceholderText = Placeholder,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            MultiLine = true,
            TextWrapped = true,
            ClearTextOnFocus = false,
            BackgroundTransparency = 0.9,
            ThemeTag = {
                BackgroundColor3 = "Input",
                TextColor3 = "Text",
                PlaceholderColor3 = "PlaceholderColor"
            }
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)}),
            Creator.New("UIStroke", {ThemeTag = {Color = "InputStroke"}}),
            Creator.New("UIPadding", {
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8)
            })
        })
        
        -- Character counter
        if MaxChars then
            self.CharCounter = Creator.New("TextLabel", {
                Size = UDim2.fromOffset(60, 14),
                Position = UDim2.new(1, -12, 1, -18),
                AnchorPoint = Vector2.new(1, 1),
                Text = #Default .. "/" .. MaxChars,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Right,
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "SubText"}
            })
        end
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 0.89,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {Transparency = 0.5, ThemeTag = {Color = "ElementBorder"}}),
            hasTitle and self.TitleLabel or nil,
            self.TextBox,
            MaxChars and self.CharCounter or nil
        })
        
        -- Text changed
        Creator.AddSignal(self.TextBox:GetPropertyChangedSignal("Text"), function()
            local text = self.TextBox.Text
            
            if MaxChars and #text > MaxChars then
                self.TextBox.Text = text:sub(1, MaxChars)
                return
            end
            
            self.Value = self.TextBox.Text
            
            if self.CharCounter then
                self.CharCounter.Text = #self.Value .. "/" .. MaxChars
            end
        end)
        
        Creator.AddSignal(self.TextBox.FocusLost, function()
            self.Callback(self.Value)
        end)
        
        self.Root = self.Frame
        return self
    end
    
    function Textbox:Set(value)
        self.Value = value
        self.TextBox.Text = value
    end
    
    function Textbox:GetValue() return self.Value end
    function Textbox:Clear() self:Set("") end
    
    return Textbox
    
end

-- Module: Elements/Timer
_modules["Elements/Timer"] = function()
    --[[
        NexusUI Timer Element
        Countdown/Countup timer with controls
    ]]
    
    local Timer = {}
    Timer.__index = Timer
    
    local Creator
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
    end
    
    function Timer.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Timer"
        local Duration = options.Duration or 60 -- seconds
        local Countdown = options.Countdown ~= false
        local AutoStart = options.AutoStart or false
        local ShowControls = options.Controls ~= false
        local OnComplete = options.OnComplete or function() end
        local OnTick = options.OnTick or function() end
        
        local self = setmetatable({}, Timer)
        self.Duration = Duration
        self.TimeLeft = Countdown and Duration or 0
        self.Running = false
        self.Countdown = Countdown
        self.OnComplete = OnComplete
        self.OnTick = OnTick
        
        -- Format time
        local function formatTime(seconds)
            local mins = math.floor(seconds / 60)
            local secs = math.floor(seconds % 60)
            return string.format("%02d:%02d", mins, secs)
        end
        
        -- Timer display
        self.TimeDisplay = Creator.New("TextLabel", {
            Size = UDim2.new(0, 100, 0, 36),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Text = formatTime(self.TimeLeft),
            FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Bold),
            TextSize = 28,
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Title
        self.TitleLabel = Creator.New("TextLabel", {
            Size = UDim2.new(0.5, -10, 0, 16),
            Position = UDim2.fromOffset(12, 8),
            Text = Title,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "SubText"}
        })
        
        -- Controls
        local controlsChildren = {}
        if ShowControls then
            self.PlayBtn = Creator.New("TextButton", {
                Size = UDim2.fromOffset(32, 32),
                Position = UDim2.new(1, -80, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                Text = "▶",
                TextSize = 14,
                ThemeTag = {BackgroundColor3 = "Accent", TextColor3 = "Text"}
            }, {Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)})})
            
            self.ResetBtn = Creator.New("TextButton", {
                Size = UDim2.fromOffset(32, 32),
                Position = UDim2.new(1, -42, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                Text = "↻",
                TextSize = 16,
                ThemeTag = {BackgroundColor3 = "Element", TextColor3 = "Text"}
            }, {Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)})})
            
            Creator.AddSignal(self.PlayBtn.MouseButton1Click, function()
                if self.Running then self:Pause() else self:Start() end
            end)
            
            Creator.AddSignal(self.ResetBtn.MouseButton1Click, function()
                self:Reset()
            end)
            
            table.insert(controlsChildren, self.PlayBtn)
            table.insert(controlsChildren, self.ResetBtn)
        end
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, 60),
            BackgroundTransparency = 0.89,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {Transparency = 0.5, ThemeTag = {Color = "ElementBorder"}}),
            self.TitleLabel,
            self.TimeDisplay,
            unpack(controlsChildren)
        })
        
        self.FormatTime = formatTime
        
        if AutoStart then
            task.defer(function() self:Start() end)
        end
        
        self.Root = self.Frame
        return self
    end
    
    function Timer:Start()
        if self.Running then return end
        self.Running = true
        
        if self.PlayBtn then self.PlayBtn.Text = "⏸" end
        
        task.spawn(function()
            while self.Running do
                task.wait(1)
                
                if self.Countdown then
                    self.TimeLeft = self.TimeLeft - 1
                    if self.TimeLeft <= 0 then
                        self.TimeLeft = 0
                        self.Running = false
                        self.OnComplete()
                    end
                else
                    self.TimeLeft = self.TimeLeft + 1
                    if self.TimeLeft >= self.Duration then
                        self.Running = false
                        self.OnComplete()
                    end
                end
                
                self.TimeDisplay.Text = self.FormatTime(self.TimeLeft)
                self.OnTick(self.TimeLeft)
            end
            
            if self.PlayBtn then self.PlayBtn.Text = "▶" end
        end)
    end
    
    function Timer:Pause()
        self.Running = false
        if self.PlayBtn then self.PlayBtn.Text = "▶" end
    end
    
    function Timer:Reset()
        self.Running = false
        self.TimeLeft = self.Countdown and self.Duration or 0
        self.TimeDisplay.Text = self.FormatTime(self.TimeLeft)
        if self.PlayBtn then self.PlayBtn.Text = "▶" end
    end
    
    function Timer:SetDuration(duration)
        self.Duration = duration
        self:Reset()
    end
    
    function Timer:GetTime() return self.TimeLeft end
    
    return Timer
    
end

-- Module: Elements/Toggle
_modules["Elements/Toggle"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                      NEXUS UI LIBRARY                         ║
        ║                   Toggle Component v2.15                      ║
        ║                          By Ryu                               ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        Features:
        - Multiple styles: switch, checkbox, radio
        - Disabled state with visual feedback
        - Animated checkmark/X icons
        - Custom on/off colors
        - Size variants: small, medium, large
        - Smooth spring animations
    ]]
    
    local Toggle = {}
    Toggle.__index = Toggle
    
    local Creator
    local Flipper
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Flipper = _require("Packages/Flipper")
    end
    
    -- Size configurations
    local Sizes = {
        small = { height = 28, toggleWidth = 32, toggleHeight = 16, indicatorSize = 12, fontSize = 12 },
        medium = { height = 36, toggleWidth = 38, toggleHeight = 18, indicatorSize = 14, fontSize = 14 },
        large = { height = 48, toggleWidth = 48, toggleHeight = 24, indicatorSize = 18, fontSize = 16 }
    }
    
    -- Style configurations
    local Styles = {
        switch = "switch",
        checkbox = "checkbox",
        radio = "radio"
    }
    
    function Toggle.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Toggle"
        local Description = options.Description
        local Default = options.Default or false
        local Callback = options.Callback or function() end
        local Flag = options.Flag
        local Style = options.Style or "switch" -- "switch", "checkbox", "radio"
        local Size = options.Size or "medium"
        local Disabled = options.Disabled or false
        local OnColor = options.OnColor -- Custom on color
        local OffColor = options.OffColor -- Custom off color
        
        local self = setmetatable({}, Toggle)
        
        self.Value = Default
        self.Callback = Callback
        self.Flag = Flag
        self.Style = Style
        self.Disabled = Disabled
        
        -- Get size config
        local sizeConfig = Sizes[Size] or Sizes.medium
        
        local hasDescription = Description ~= nil
        local height = hasDescription and (sizeConfig.height + 12) or sizeConfig.height
        
        -- Create toggle control based on style
        if Style == "switch" then
            self:CreateSwitchToggle(sizeConfig, Default, OnColor, OffColor)
        elseif Style == "checkbox" then
            self:CreateCheckboxToggle(sizeConfig, Default, OnColor)
        elseif Style == "radio" then
            self:CreateRadioToggle(sizeConfig, Default, OnColor)
        else
            self:CreateSwitchToggle(sizeConfig, Default, OnColor, OffColor)
        end
        
        -- Title
        self.Label = Creator.New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            Text = Title,
            TextSize = sizeConfig.fontSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -60, 0, sizeConfig.fontSize),
            Position = hasDescription and UDim2.fromOffset(12, 9) or UDim2.new(0, 12, 0.5, 0),
            AnchorPoint = hasDescription and Vector2.zero or Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            TextTransparency = Disabled and 0.5 or 0,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Description
        if hasDescription then
            self.DescriptionLabel = Creator.New("TextLabel", {
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                Text = Description,
                TextSize = 12,
                TextTransparency = Disabled and 0.6 or 0.4,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -60, 0, 12),
                Position = UDim2.fromOffset(12, 27),
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "SubText"}
            })
        end
        
        -- Frame (button)
        self.Frame = Creator.New("TextButton", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 0.89,
            Text = "",
            Parent = parent,
            AutoButtonColor = false,
            Active = not Disabled,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {
                Transparency = 0.5,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                ThemeTag = {Color = "ElementBorder"}
            }),
            self.Label,
            hasDescription and self.DescriptionLabel or nil,
            self.ToggleFrame
        })
        
        -- Hover animation
        self.HoverMotor, self.SetHover = Creator.SpringMotor(0.89, self.Frame, "BackgroundTransparency")
        
        if not Disabled then
            Creator.AddSignal(self.Frame.MouseEnter, function()
                if not self.Disabled then
                    self.SetHover(0.85)
                end
            end)
            
            Creator.AddSignal(self.Frame.MouseLeave, function()
                self.SetHover(0.89)
            end)
            
            -- Toggle on click
            Creator.AddSignal(self.Frame.MouseButton1Click, function()
                if not self.Disabled then
                    self:Set(not self.Value)
                end
            end)
        end
        
        self.Root = self.Frame
        self.SizeConfig = sizeConfig
        
        return self
    end
    
    -- Create switch-style toggle (iOS style)
    function Toggle:CreateSwitchToggle(sizeConfig, default, onColor, offColor)
        -- Toggle indicator (circle)
        self.ToggleIndicator = Creator.New("Frame", {
            Size = UDim2.fromOffset(sizeConfig.indicatorSize, sizeConfig.indicatorSize),
            Position = default and UDim2.new(1, -sizeConfig.indicatorSize - 2, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)}),
            -- Shadow for depth
            Creator.New("ImageLabel", {
                Image = "rbxassetid://5554236805",
                Size = UDim2.fromOffset(sizeConfig.indicatorSize + 4, sizeConfig.indicatorSize + 4),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                ImageTransparency = 0.8,
                ZIndex = -1
            })
        })
        
        -- Toggle frame
        local toggleProps = {
            Size = UDim2.fromOffset(sizeConfig.toggleWidth, sizeConfig.toggleHeight),
            Position = UDim2.new(1, -12, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5)
        }
        
        if onColor and default then
            toggleProps.BackgroundColor3 = onColor
        elseif offColor and not default then
            toggleProps.BackgroundColor3 = offColor
        else
            toggleProps.ThemeTag = {BackgroundColor3 = default and "ToggleEnabled" or "ToggleDisabled"}
        end
        
        self.ToggleFrame = Creator.New("Frame", toggleProps, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)}),
            Creator.New("UIStroke", {
                Transparency = 0.5,
                ThemeTag = {Color = default and "ToggleEnabledStroke" or "ToggleDisabledStroke"}
            }),
            self.ToggleIndicator
        })
        
        -- Animation motor for switch
        self.IndicatorMotor = Flipper.SingleMotor.new(default and (sizeConfig.toggleWidth - sizeConfig.indicatorSize - 4) or 2)
        self.IndicatorMotor:onStep(function(value)
            if self.ToggleIndicator then
                self.ToggleIndicator.Position = UDim2.new(0, value, 0.5, 0)
            end
        end)
        
        self.OnColor = onColor
        self.OffColor = offColor
    end
    
    -- Create checkbox-style toggle
    function Toggle:CreateCheckboxToggle(sizeConfig, default, onColor)
        -- Checkmark icon
        self.Checkmark = Creator.New("ImageLabel", {
            Image = "rbxassetid://10709790644", -- Checkmark
            Size = UDim2.fromOffset(sizeConfig.indicatorSize - 4, sizeConfig.indicatorSize - 4),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ImageTransparency = default and 0 or 1,
            ImageColor3 = Color3.fromRGB(255, 255, 255)
        })
        
        local boxSize = sizeConfig.toggleHeight + 2
        
        local toggleProps = {
            Size = UDim2.fromOffset(boxSize, boxSize),
            Position = UDim2.new(1, -12, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5)
        }
        
        if onColor and default then
            toggleProps.BackgroundColor3 = onColor
        else
            toggleProps.ThemeTag = {BackgroundColor3 = default and "ToggleEnabled" or "Element"}
        end
        
        self.ToggleFrame = Creator.New("Frame", toggleProps, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 4)}),
            Creator.New("UIStroke", {
                Transparency = 0.3,
                Thickness = default and 0 or 1,
                ThemeTag = {Color = default and "ToggleEnabledStroke" or "ElementBorder"}
            }),
            self.Checkmark
        })
        
        -- Animation motor for checkbox
        self.CheckMotor = Flipper.SingleMotor.new(default and 0 or 1)
        self.CheckMotor:onStep(function(value)
            if self.Checkmark then
                self.Checkmark.ImageTransparency = value
                -- Scale animation
                local scale = 1 - (value * 0.3)
                self.Checkmark.Size = UDim2.fromOffset(
                    (sizeConfig.indicatorSize - 4) * scale,
                    (sizeConfig.indicatorSize - 4) * scale
                )
            end
        end)
        
        self.OnColor = onColor
    end
    
    -- Create radio-style toggle
    function Toggle:CreateRadioToggle(sizeConfig, default, onColor)
        -- Inner dot
        local dotSize = sizeConfig.indicatorSize - 6
        self.RadioDot = Creator.New("Frame", {
            Size = UDim2.fromOffset(default and dotSize or 0, default and dotSize or 0),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
        })
        
        local circleSize = sizeConfig.toggleHeight + 2
        
        local toggleProps = {
            Size = UDim2.fromOffset(circleSize, circleSize),
            Position = UDim2.new(1, -12, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5)
        }
        
        if onColor and default then
            toggleProps.BackgroundColor3 = onColor
        else
            toggleProps.ThemeTag = {BackgroundColor3 = default and "ToggleEnabled" or "Element"}
        end
        
        self.ToggleFrame = Creator.New("Frame", toggleProps, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)}),
            Creator.New("UIStroke", {
                Transparency = 0.3,
                Thickness = default and 0 or 2,
                ThemeTag = {Color = default and "ToggleEnabledStroke" or "ElementBorder"}
            }),
            self.RadioDot
        })
        
        -- Animation motor for radio
        local targetSize = default and dotSize or 0
        self.RadioMotor = Flipper.SingleMotor.new(targetSize)
        self.RadioMotor:onStep(function(value)
            if self.RadioDot then
                self.RadioDot.Size = UDim2.fromOffset(value, value)
            end
        end)
        
        self.OnColor = onColor
    end
    
    function Toggle:Set(value, skipCallback)
        if self.Disabled then return end
        
        self.Value = value
        local sizeConfig = self.SizeConfig
        
        if self.Style == "switch" then
            -- Animate indicator position
            local targetPos = value and (sizeConfig.toggleWidth - sizeConfig.indicatorSize - 4) or 2
            self.IndicatorMotor:setGoal(Flipper.Spring.new(targetPos, {frequency = 6}))
            
            -- Update colors
            if self.OnColor and value then
                self.ToggleFrame.BackgroundColor3 = self.OnColor
            elseif self.OffColor and not value then
                self.ToggleFrame.BackgroundColor3 = self.OffColor
            else
                Creator.OverrideTag(self.ToggleFrame, {
                    BackgroundColor3 = value and "ToggleEnabled" or "ToggleDisabled"
                })
            end
            
        elseif self.Style == "checkbox" then
            -- Animate checkmark
            self.CheckMotor:setGoal(Flipper.Spring.new(value and 0 or 1, {frequency = 8}))
            
            -- Update background
            if self.OnColor and value then
                self.ToggleFrame.BackgroundColor3 = self.OnColor
            else
                Creator.OverrideTag(self.ToggleFrame, {
                    BackgroundColor3 = value and "ToggleEnabled" or "Element"
                })
            end
            
            -- Update stroke
            local stroke = self.ToggleFrame:FindFirstChild("UIStroke")
            if stroke then
                stroke.Thickness = value and 0 or 1
            end
            
        elseif self.Style == "radio" then
            -- Animate dot
            local dotSize = sizeConfig.indicatorSize - 6
            self.RadioMotor:setGoal(Flipper.Spring.new(value and dotSize or 0, {frequency = 8}))
            
            -- Update background
            if self.OnColor and value then
                self.ToggleFrame.BackgroundColor3 = self.OnColor
            else
                Creator.OverrideTag(self.ToggleFrame, {
                    BackgroundColor3 = value and "ToggleEnabled" or "Element"
                })
            end
            
            -- Update stroke
            local stroke = self.ToggleFrame:FindFirstChild("UIStroke")
            if stroke then
                stroke.Thickness = value and 0 or 2
            end
        end
        
        -- Update stroke color for all styles
        local stroke = self.ToggleFrame:FindFirstChild("UIStroke")
        if stroke then
            Creator.OverrideTag(stroke, {
                Color = value and "ToggleEnabledStroke" or (self.Style == "switch" and "ToggleDisabledStroke" or "ElementBorder")
            })
        end
        
        if not skipCallback and self.Callback then
            self.Callback(value)
        end
    end
    
    function Toggle:SetDisabled(disabled)
        self.Disabled = disabled
        self.Frame.Active = not disabled
        
        if self.Label then
            self.Label.TextTransparency = disabled and 0.5 or 0
        end
        
        if self.DescriptionLabel then
            self.DescriptionLabel.TextTransparency = disabled and 0.6 or 0.4
        end
        
        if self.ToggleFrame then
            self.ToggleFrame.BackgroundTransparency = disabled and 0.5 or 0
        end
    end
    
    function Toggle:SetTitle(title)
        if self.Label then
            self.Label.Text = title
        end
    end
    
    function Toggle:GetValue()
        return self.Value
    end
    
    function Toggle:Destroy()
        if self.Frame then
            self.Frame:Destroy()
        end
    end
    
    return Toggle
    
end

-- Module: Elements/TooltipElement
_modules["Elements/TooltipElement"] = function()
    --[[
        NexusUI Tooltip Element (Inline, not utility)
        Info tooltip attached to content
    ]]
    
    local TooltipElement = {}
    TooltipElement.__index = TooltipElement
    
    local Creator
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
    end
    
    function TooltipElement.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Text = options.Text or "Info"
        local Tip = options.Tip or "Helpful information here"
        local Icon = options.Icon or "ℹ"
        
        local self = setmetatable({}, TooltipElement)
        
        -- Main content
        self.TextLabel = Creator.New("TextLabel", {
            Size = UDim2.new(1, -40, 0, 20),
            Position = UDim2.fromOffset(12, 8),
            Text = Text,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Info icon
        self.InfoIcon = Creator.New("TextButton", {
            Size = UDim2.fromOffset(20, 20),
            Position = UDim2.new(1, -12, 0, 8),
            AnchorPoint = Vector2.new(1, 0),
            Text = Icon,
            TextSize = 14,
            BackgroundTransparency = 0.9,
            ThemeTag = {BackgroundColor3 = "Accent", TextColor3 = "Text"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
        })
        
        -- Tooltip popup
        self.TipFrame = Creator.New("Frame", {
            Size = UDim2.new(1, -24, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.fromOffset(12, 36),
            BackgroundTransparency = 0.1,
            Visible = false,
            ThemeTag = {BackgroundColor3 = "Topbar"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)}),
            Creator.New("UIPadding", {
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10)
            }),
            Creator.New("TextLabel", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Text = Tip,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                TextSize = 12,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                ThemeTag = {TextColor3 = "Text"}
            })
        })
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundTransparency = 0.89,
            ClipsDescendants = false,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {Transparency = 0.5, ThemeTag = {Color = "ElementBorder"}}),
            self.TextLabel,
            self.InfoIcon,
            self.TipFrame
        })
        
        -- Toggle tooltip
        Creator.AddSignal(self.InfoIcon.MouseEnter, function()
            self.TipFrame.Visible = true
        end)
        
        Creator.AddSignal(self.InfoIcon.MouseLeave, function()
            self.TipFrame.Visible = false
        end)
        
        self.Root = self.Frame
        return self
    end
    
    return TooltipElement
    
end

-- Module: Elements/VideoPlayer
_modules["Elements/VideoPlayer"] = function()
    --[[
        NexusUI Video Player Element
        Play video content with full controls
    ]]
    
    local VideoPlayer = {}
    VideoPlayer.__index = VideoPlayer
    
    local Creator, Flipper, Services
    
    local function InitDependencies()
        local root = script.Parent.Parent
        Creator = _require("Core/Creator")
        Flipper = _require("Packages/Flipper")
        Services = _require("Core/Services")
    end
    
    function VideoPlayer.new(parent, options)
        InitDependencies()
        
        options = options or {}
        local Title = options.Title or "Video"
        local VideoId = options.VideoId or options.Video
        local AutoPlay = options.AutoPlay or false
        local Looped = options.Looped or false
        local ShowControls = options.Controls ~= false
        local Height = options.Height or 180
        
        local self = setmetatable({}, VideoPlayer)
        self.Playing = false
        self.Volume = 0.5
        self.Time = 0
        
        -- Title
        self.TitleLabel = Creator.New("TextLabel", {
            Size = UDim2.new(1, -12, 0, 20),
            Position = UDim2.fromOffset(12, 8),
            Text = Title,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Video frame
        self.VideoFrame = Creator.New("VideoFrame", {
            Size = UDim2.new(1, -24, 0, Height - 70),
            Position = UDim2.fromOffset(12, 34),
            Video = type(VideoId) == "number" and ("rbxassetid://" .. VideoId) or VideoId,
            Looped = Looped,
            Volume = self.Volume,
            BackgroundColor3 = Color3.new(0, 0, 0)
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)})
        })
        
        -- Controls container
        self.ControlsContainer = Creator.New("Frame", {
            Size = UDim2.new(1, -24, 0, 30),
            Position = UDim2.new(0, 12, 1, -40),
            BackgroundTransparency = 1
        })
        
        -- Play/Pause button
        self.PlayButton = Creator.New("TextButton", {
            Size = UDim2.fromOffset(30, 30),
            Position = UDim2.fromOffset(0, 0),
            Text = "▶",
            TextSize = 14,
            Parent = self.ControlsContainer,
            ThemeTag = {BackgroundColor3 = "Element", TextColor3 = "Text"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 6)})
        })
        
        -- Progress bar
        self.ProgressBar = Creator.New("Frame", {
            Size = UDim2.new(1, -120, 0, 6),
            Position = UDim2.new(0, 40, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 0.7,
            Parent = self.ControlsContainer,
            ThemeTag = {BackgroundColor3 = "SliderBackground"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
        })
        
        self.ProgressFill = Creator.New("Frame", {
            Size = UDim2.fromScale(0, 1),
            Parent = self.ProgressBar,
            ThemeTag = {BackgroundColor3 = "SliderProgress"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(1, 0)})
        })
        
        -- Time label
        self.TimeLabel = Creator.New("TextLabel", {
            Size = UDim2.fromOffset(60, 20),
            Position = UDim2.new(1, -60, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Text = "0:00",
            TextSize = 12,
            BackgroundTransparency = 1,
            Parent = self.ControlsContainer,
            ThemeTag = {TextColor3 = "SubText"}
        })
        
        -- Volume button
        self.VolumeButton = Creator.New("TextButton", {
            Size = UDim2.fromOffset(24, 24),
            Position = UDim2.new(1, 0, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            Text = "🔊",
            TextSize = 12,
            BackgroundTransparency = 1,
            Parent = self.ControlsContainer,
            ThemeTag = {TextColor3 = "Text"}
        })
        
        -- Frame
        self.Frame = Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, Height),
            BackgroundTransparency = 0.89,
            Parent = parent,
            ThemeTag = {BackgroundColor3 = "Element"}
        }, {
            Creator.New("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Creator.New("UIStroke", {
                Transparency = 0.5,
                ThemeTag = {Color = "ElementBorder"}
            }),
            self.TitleLabel,
            self.VideoFrame,
            ShowControls and self.ControlsContainer or nil
        })
        
        -- Play/Pause functionality
        Creator.AddSignal(self.PlayButton.MouseButton1Click, function()
            if self.Playing then
                self:Pause()
            else
                self:Play()
            end
        end)
        
        -- Click video to toggle
        Creator.AddSignal(self.VideoFrame.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if self.Playing then
                    self:Pause()
                else
                    self:Play()
                end
            end
        end)
        
        -- Progress click
        Creator.AddSignal(self.ProgressBar.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local relX = (input.Position.X - self.ProgressBar.AbsolutePosition.X) / self.ProgressBar.AbsoluteSize.X
                self:Seek(relX * self.VideoFrame.TimeLength)
            end
        end)
        
        -- Volume toggle
        Creator.AddSignal(self.VolumeButton.MouseButton1Click, function()
            if self.Volume > 0 then
                self.Volume = 0
                self.VolumeButton.Text = "🔇"
            else
                self.Volume = 0.5
                self.VolumeButton.Text = "🔊"
            end
            self.VideoFrame.Volume = self.Volume
        end)
        
        -- Update progress
        Creator.AddSignal(Services.RunService.Heartbeat, function()
            if self.VideoFrame.IsLoaded and self.VideoFrame.TimeLength > 0 then
                local progress = self.VideoFrame.TimePosition / self.VideoFrame.TimeLength
                self.ProgressFill.Size = UDim2.fromScale(progress, 1)
                
                local mins = math.floor(self.VideoFrame.TimePosition / 60)
                local secs = math.floor(self.VideoFrame.TimePosition % 60)
                self.TimeLabel.Text = string.format("%d:%02d", mins, secs)
            end
        end)
        
        -- Auto play
        if AutoPlay then
            task.defer(function()
                self:Play()
            end)
        end
        
        self.Root = self.Frame
        
        return self
    end
    
    function VideoPlayer:Play()
        self.Playing = true
        self.VideoFrame:Play()
        self.PlayButton.Text = "⏸"
    end
    
    function VideoPlayer:Pause()
        self.Playing = false
        self.VideoFrame:Pause()
        self.PlayButton.Text = "▶"
    end
    
    function VideoPlayer:Stop()
        self.Playing = false
        self.VideoFrame.TimePosition = 0
        self.VideoFrame:Pause()
        self.PlayButton.Text = "▶"
    end
    
    function VideoPlayer:Seek(time)
        self.VideoFrame.TimePosition = math.clamp(time, 0, self.VideoFrame.TimeLength)
    end
    
    function VideoPlayer:SetVolume(volume)
        self.Volume = math.clamp(volume, 0, 1)
        self.VideoFrame.Volume = self.Volume
    end
    
    function VideoPlayer:SetVideo(videoId)
        self.VideoFrame.Video = type(videoId) == "number" and ("rbxassetid://" .. videoId) or videoId
    end
    
    return VideoPlayer
    
end

-- Module: init
_modules["init"] = function()
    --[[
        ╔═══════════════════════════════════════════════════════════════╗
        ║                     NEXUS UI LIBRARY v2.15                    ║
        ║              The Ultimate Roblox GUI Framework                ║
        ║                                                               ║
        ║  🎨 50+ UI Elements  |  🎵 Music & Sound  |  🖼️ Images/Video ║
        ║  ⚡ Smooth Animations |  🎛️ Full Customization  |  💾 Config ║
        ║  🌐 Cross-Platform   |  🔗 Raw URL Support  |  📱 VR Ready   ║
        ╚═══════════════════════════════════════════════════════════════╝
        
        Usage:
            local NexusUI = require(path.to.NexusUI)
            
            -- Simple API
            local Window = NexusUI:CreateWindow({Title = "My App"})
            local Tab = Window:AddTab({Title = "Main"})
            Tab:AddButton({Title = "Click", Callback = function() end})
            
            -- Builder API (Chainable)
            local Window = NexusUI.Build()
                :Window({Title = "My App"})
                :Tab({Title = "Main"})
                :Button({Title = "Click", Callback = function() end})
                :Toggle({Title = "Enable", Flag = "Enabled"})
                :Done()
    ]]
    
    local NexusUI = {
        Version = "2.15.0",
        Branch = "main",
        Themes = nil,
        ActiveWindows = {},
        Flags = {},
        Platform = nil,
        ImageLoader = nil
    }
    
    -- Module references
    local Creator
    local Services
    local Themes
    local DeviceDetection
    local ConfigManager
    local AssetManager
    local SoundManager
    local Customizer
    local Animate
    local Tooltip
    local Flipper
    local Builder
    local Platform
    local ImageLoader
    
    -- Initialize all modules
    local function InitModules()
        local root = script
        
        -- Core
        Services = _require("Core/Services")
        Creator = _require("Core/Creator")
        Customizer = _require("Core/Customizer")
        Builder = _require("Core/Builder")
        
        -- Packages
        Flipper = _require("Packages/Flipper")
        
        -- Theme
        Themes = _require("Themes")
        Creator.Themes = Themes
        Creator.CurrentTheme = Themes.Dark
        
        -- Utils
        DeviceDetection = _require("Utils/DeviceDetection")
        ConfigManager = _require("Utils/ConfigManager")
        AssetManager = _require("Utils/AssetManager")
        SoundManager = _require("Utils/SoundManager")
        Animate = _require("Utils/Animate")
        Tooltip = _require("Utils/Tooltip")
        Platform = _require("Utils/Platform")
        ImageLoader = _require("Utils/ImageLoader")
        
        NexusUI.Themes = Themes
        NexusUI.Animate = Animate
        NexusUI.Sound = SoundManager
        NexusUI.Tooltip = Tooltip
        NexusUI.Customizer = Customizer
        NexusUI.Platform = Platform
        NexusUI.ImageLoader = ImageLoader
    end
    
    -- ============================================
    -- WINDOW CREATION
    -- ============================================
    
    function NexusUI:CreateWindow(options)
        if not Creator then InitModules() end
        
        local Window = _require("init/Components/Window")
        local window = Window.new(options)
        table.insert(NexusUI.ActiveWindows, window)
        return window
    end
    
    -- ============================================
    -- LOADING SCREEN
    -- ============================================
    
    function NexusUI:CreateLoadingScreen(options)
        if not Creator then InitModules() end
        
        local LoadingScreen = _require("init/Components/LoadingScreen")
        return LoadingScreen.new(options)
    end
    
    -- ============================================
    -- BUILDER API (Chainable)
    -- ============================================
    
    function NexusUI.Build()
        if not Creator then InitModules() end
        return Builder.new(NexusUI)
    end
    
    -- ============================================
    -- NOTIFICATIONS
    -- ============================================
    
    function NexusUI:Notify(options)
        if #NexusUI.ActiveWindows > 0 then
            return NexusUI.ActiveWindows[1]:Notify(options)
        end
    end
    
    -- ============================================
    -- THEME MANAGEMENT
    -- ============================================
    
    function NexusUI:SetTheme(theme)
        if not Creator then InitModules() end
        Creator.SetTheme(theme)
    end
    
    function NexusUI:GetThemes()
        if not Creator then InitModules() end
        return Themes.Names
    end
    
    function NexusUI:CreateTheme(name, colors)
        if not Creator then InitModules() end
        return Customizer.CreateTheme(name, colors)
    end
    
    function NexusUI:CreateThemeFromAccent(name, accentColor, isDark)
        if not Creator then InitModules() end
        return Customizer.CreateThemeFromAccent(name, accentColor, isDark)
    end
    
    -- ============================================
    -- CUSTOMIZATION
    -- ============================================
    
    function NexusUI:SetStyle(styleName)
        if not Creator then InitModules() end
        Customizer.SetElementStyle(styleName)
    end
    
    function NexusUI:SetAnimation(presetName)
        if not Creator then InitModules() end
        Customizer.SetAnimationPreset(presetName)
    end
    
    function NexusUI:SetFont(fontName)
        if not Creator then InitModules() end
        Customizer.SetFont(fontName)
    end
    
    function NexusUI:GetIcon(iconName)
        if not Creator then InitModules() end
        return Customizer.GetIcon(iconName)
    end
    
    -- ============================================
    -- CONFIG MANAGEMENT
    -- ============================================
    
    function NexusUI:SetConfigFolder(folder)
        if not Creator then InitModules() end
        ConfigManager.SetFolder(folder)
    end
    
    function NexusUI:SaveConfig(name)
        if not Creator then InitModules() end
        return ConfigManager.Save(name)
    end
    
    function NexusUI:LoadConfig(name)
        if not Creator then InitModules() end
        return ConfigManager.Load(name)
    end
    
    function NexusUI:DeleteConfig(name)
        if not Creator then InitModules() end
        return ConfigManager.Delete(name)
    end
    
    function NexusUI:ListConfigs()
        if not Creator then InitModules() end
        return ConfigManager.List()
    end
    
    function NexusUI:RegisterFlag(flagName, element)
        if not Creator then InitModules() end
        ConfigManager.RegisterFlag(flagName, element)
        NexusUI.Flags[flagName] = element
    end
    
    function NexusUI:GetFlag(flagName)
        return NexusUI.Flags[flagName]
    end
    
    -- ============================================
    -- SOUND MANAGEMENT
    -- ============================================
    
    function NexusUI:PlaySound(options)
        if not Creator then InitModules() end
        return SoundManager.PlaySound(options)
    end
    
    function NexusUI:PlayMusic(options)
        if not Creator then InitModules() end
        return SoundManager.PlayMusic(options)
    end
    
    function NexusUI:StopMusic(fadeOut)
        if not Creator then InitModules() end
        SoundManager.StopMusic(fadeOut)
    end
    
    function NexusUI:PlayPresetSound(name)
        if not Creator then InitModules() end
        return SoundManager.PlayPreset(name)
    end
    
    -- ============================================
    -- ASSET MANAGEMENT
    -- ============================================
    
    function NexusUI:DownloadAsset(url, name, callback)
        if not Creator then InitModules() end
        AssetManager.Download(url, name, callback)
    end
    
    function NexusUI:DownloadAssets(assets, progressCallback, completeCallback)
        if not Creator then InitModules() end
        AssetManager.DownloadMultiple(assets, progressCallback, completeCallback)
    end
    
    function NexusUI:LoadImage(name)
        if not Creator then InitModules() end
        return AssetManager.LoadImage(name)
    end
    
    function NexusUI:ClearAssetCache()
        if not Creator then InitModules() end
        AssetManager.ClearCache()
    end
    
    -- ============================================
    -- DEVICE DETECTION
    -- ============================================
    
    function NexusUI:GetDeviceType()
        if not Creator then InitModules() end
        return DeviceDetection.GetDeviceType()
    end
    
    function NexusUI:IsMobile()
        if not Creator then InitModules() end
        return DeviceDetection.IsMobile()
    end
    
    function NexusUI:IsDesktop()
        if not Creator then InitModules() end
        return DeviceDetection.IsDesktop()
    end
    
    function NexusUI:GetResponsiveValue(mobile, tablet, desktop)
        if not Creator then InitModules() end
        return DeviceDetection.GetValue(mobile, tablet, desktop)
    end
    
    -- ============================================
    -- ANIMATION UTILITIES
    -- ============================================
    
    function NexusUI:Tween(object, properties, duration, style)
        if not Creator then InitModules() end
        return Animate.Tween(object, properties, duration, style)
    end
    
    function NexusUI:FadeIn(object, duration)
        if not Creator then InitModules() end
        return Animate.FadeIn(object, duration)
    end
    
    function NexusUI:FadeOut(object, duration)
        if not Creator then InitModules() end
        return Animate.FadeOut(object, duration)
    end
    
    function NexusUI:SlideIn(object, direction, duration)
        if not Creator then InitModules() end
        return Animate.SlideIn(object, direction, duration)
    end
    
    function NexusUI:Shake(object, intensity, duration)
        if not Creator then InitModules() end
        return Animate.Shake(object, intensity, duration)
    end
    
    function NexusUI:Ripple(object, position, color)
        if not Creator then InitModules() end
        return Animate.Ripple(object, position, color)
    end
    
    -- ============================================
    -- TOOLTIP
    -- ============================================
    
    function NexusUI:AddTooltip(element, options)
        if not Creator then InitModules() end
        return Tooltip.Add(element, options)
    end
    
    -- ============================================
    -- PLATFORM / CROSS-PLATFORM
    -- ============================================
    
    function NexusUI:GetPlatform()
        if not Creator then InitModules() end
        return Platform.GetPlatform()
    end
    
    function NexusUI:IsVR()
        if not Creator then InitModules() end
        return Platform.IsVR()
    end
    
    function NexusUI:IsMobileDevice()
        if not Creator then InitModules() end
        return Platform.IsMobile()
    end
    
    function NexusUI:AdaptForPlatform()
        if not Creator then InitModules() end
        Platform.AdaptUI()
    end
    
    -- ============================================
    -- IMAGE LOADING (Raw URL Support)
    -- ============================================
    
    function NexusUI:LoadImageFromURL(imageLabel, url)
        if not Creator then InitModules() end
        return ImageLoader.SetImage(imageLabel, url)
    end
    
    function NexusUI:PreloadImage(url)
        if not Creator then InitModules() end
        return ImageLoader.Preload(url)
    end
    
    function NexusUI:ClearImageCache()
        if not Creator then InitModules() end
        ImageLoader.ClearCache()
    end
    
    -- ============================================
    -- GUI TOGGLE
    -- ============================================
    
    function NexusUI:ToggleGUI()
        for _, window in ipairs(NexusUI.ActiveWindows) do
            if window.ScreenGui then
                window.ScreenGui.Enabled = not window.ScreenGui.Enabled
            end
        end
    end
    
    function NexusUI:ShowGUI()
        for _, window in ipairs(NexusUI.ActiveWindows) do
            if window.ScreenGui then
                window.ScreenGui.Enabled = true
            end
        end
    end
    
    function NexusUI:HideGUI()
        for _, window in ipairs(NexusUI.ActiveWindows) do
            if window.ScreenGui then
                window.ScreenGui.Enabled = false
            end
        end
    end
    
    function NexusUI:GetTheme()
        if not Creator then InitModules() end
        return Creator.CurrentThemeName or "Dark"
    end
    
    -- ============================================
    -- CLEANUP
    -- ============================================
    
    function NexusUI:Destroy()
        for _, window in ipairs(NexusUI.ActiveWindows) do
            window:Destroy()
        end
        NexusUI.ActiveWindows = {}
        NexusUI.Flags = {}
        if SoundManager then SoundManager.StopAll() end
        if Creator then Creator.Disconnect() end
    end
    
    -- Initialize on require
    InitModules()
    
    return NexusUI
    
end

-- Initialize and return
return _require("init")
