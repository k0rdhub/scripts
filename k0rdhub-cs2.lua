--[[
    K0rdHub — Deadshot Modules
    Player ESP, Team ESP, Tracers, Aim Assist, Aim Lock,
    Auto-Bhop, No Recoil, Anti-Flash, Dark Visuals

    RIGHT SHIFT toggles the menu
]]

--// Services
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local TeleportService  = game:GetService("TeleportService")
local Lighting         = game:GetService("Lighting")

--// Constants
local HUB_NAME = "K0rdHub"
local LOGO     = "rbxassetid://77399633524161"
local TABS     = { "ALL", "MOVEMENT", "LEGIT", "GLOBAL", "VISUALS", "MISC" }
local CONFIG   = "CONFIGURATION"

local env = (getgenv and getgenv()) or _G
if env.K0rdHub and env.K0rdHub.Destroy then
    pcall(function() env.K0rdHub:Destroy(true) end)
end
pcall(function()
    local old = CoreGui:FindFirstChild(HUB_NAME)
    if old then old:Destroy() end
end)

--// Theme
local Theme = {
    Accent  = Color3.fromRGB(255, 45, 60),
    Text    = Color3.fromRGB(242, 242, 245),
    SubText = Color3.fromRGB(150, 150, 160),
    Off     = Color3.fromRGB(58, 58, 66),
    Dialog  = Color3.fromRGB(12, 12, 14),
}

--// Tween presets
local QUINT = Enum.EasingStyle.Quint
local EASE = {
    Fast = TweenInfo.new(0.15, QUINT, Enum.EasingDirection.Out),
    Med  = TweenInfo.new(0.30, QUINT, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(0.50, QUINT, Enum.EasingDirection.Out),
    Pop  = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    In   = TweenInfo.new(0.25, QUINT, Enum.EasingDirection.In),
}

local function tween(obj, info, goal)
    local t = TweenService:Create(obj, info, goal)
    t:Play()
    return t
end

local function new(class, props, children)
    local inst = Instance.new(class)
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v else inst[k] = v end
    end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    inst.Parent = parent
    return inst
end

local function corner(parent, r)
    return new("UICorner", { CornerRadius = UDim.new(0, r), Parent = parent })
end
local function pill(parent)
    return new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = parent })
end
local function padding(parent, l, r, t, b)
    return new("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or 0),
        PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0),
        Parent = parent,
    })
end

local Connections = {}
local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Connections, c)
    return c
end

--// Accent system
local AccentValue = Instance.new("Color3Value")
AccentValue.Value = Theme.Accent
local AccentBinds = {}
local accentTween

local function bindAccent(fn)
    fn(Theme.Accent)
    table.insert(AccentBinds, fn)
end

AccentValue.Changed:Connect(function(c)
    Theme.Accent = c
    for _, fn in ipairs(AccentBinds) do fn(c) end
end)

local function setAccent(color, instant)
    if accentTween then accentTween:Cancel() end
    if instant then
        AccentValue.Value = color
    else
        accentTween = tween(AccentValue, TweenInfo.new(0.4, QUINT, Enum.EasingDirection.Out), { Value = color })
    end
end

--// ScreenGui
local Gui = new("ScreenGui", {
    Name = HUB_NAME,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 999,
})
do
    local ok = pcall(function() Gui.Parent = CoreGui end)
    if not ok or not Gui.Parent then
        Gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
end

--// State
local Hub = { Modules = {} }
local Open, Destroyed = false, false
local openToken = 0
local ToggleKey = Enum.KeyCode.RightShift
local Loaded = false
local Listening = nil
local Rainbow = false
local NotificationsEnabled = true
local CurrentTab = "ALL"
local rainbowMod

------------------------------------------------------------------------
-- ROOT / MAIN WINDOW
------------------------------------------------------------------------
local Root = new("Frame", {
    Name = "Root",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(680, 440),
    BackgroundTransparency = 1,
    Parent = Gui,
})
local UserScale = new("UIScale", { Scale = 1, Parent = Root })

local Main = new("CanvasGroup", {
    Name = "Main",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.2,
    GroupTransparency = 1,
    Visible = false,
    Parent = Root,
})
corner(Main, 12)
local OpenScale = new("UIScale", { Scale = 0.9, Parent = Main })
local MainStroke = new("UIStroke", { Thickness = 1.5, Transparency = 0.35, Parent = Main })
bindAccent(function(c) MainStroke.Color = c end)

local DragBar = new("Frame", {
    Name = "DragBar", Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Parent = Main,
})

------------------------------------------------------------------------
-- SIDEBAR
------------------------------------------------------------------------
local Sidebar = new("Frame", {
    Name = "Sidebar", Size = UDim2.new(0, 180, 1, 0), BackgroundTransparency = 1, Parent = Main,
})
new("Frame", {
    Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0),
    BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.92,
    BorderSizePixel = 0, Parent = Sidebar,
})

local Logo = new("ImageLabel", {
    Position = UDim2.fromOffset(16, 10), Size = UDim2.fromOffset(36, 36),
    BackgroundTransparency = 1, Image = LOGO, ScaleType = Enum.ScaleType.Fit, Parent = Sidebar,
})
corner(Logo, 8)
local LogoStroke = new("UIStroke", { Thickness = 1.5, Transparency = 0.5, Parent = Logo })
bindAccent(function(c) LogoStroke.Color = c end)

local NameLabel = new("TextLabel", {
    Position = UDim2.fromOffset(62, 10), Size = UDim2.fromOffset(110, 20),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left, RichText = true, Text = "", Parent = Sidebar,
})
bindAccent(function(c)
    NameLabel.Text = '<font color="#FFFFFF">K0rd</font><font color="#' .. c:ToHex() .. '">Hub</font>'
end)
new("TextLabel", {
    Position = UDim2.fromOffset(62, 30), Size = UDim2.fromOffset(110, 14),
    BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11,
    TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left,
    Text = "deadshot  ·  v2.0", Parent = Sidebar,
})

new("TextLabel", {
    Position = UDim2.fromOffset(22, 62), Size = UDim2.fromOffset(120, 12),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 10,
    TextColor3 = Color3.fromRGB(95, 95, 105), TextXAlignment = Enum.TextXAlignment.Left,
    Text = "CATEGORIES", Parent = Sidebar,
})

local Indicator = new("Frame", {
    Size = UDim2.new(1, -24, 0, 34), Position = UDim2.new(0, 12, 0, 80),
    BackgroundTransparency = 0.85, Parent = Sidebar,
})
corner(Indicator, 8)
local IndBar = new("Frame", {
    AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
    Size = UDim2.fromOffset(3, 18), BorderSizePixel = 0, Parent = Indicator,
})
pill(IndBar)
bindAccent(function(c) Indicator.BackgroundColor3 = c; IndBar.BackgroundColor3 = c end)

local TabButtons = {}
local function makeTab(name, position)
    local b = new("TextButton", {
        Name = name, Position = position, Size = UDim2.new(1, -24, 0, 34),
        BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
        AutoButtonColor = false, Font = Enum.Font.GothamMedium, TextSize = 12,
        TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left,
        Text = name, Parent = Sidebar,
    })
    corner(b, 8)
    padding(b, 16)
    TabButtons[name] = b
    return b
end
for i, name in ipairs(TABS) do
    makeTab(name, UDim2.new(0, 12, 0, 80 + (i - 1) * 38))
end
new("Frame", {
    Position = UDim2.new(0, 20, 1, -62), Size = UDim2.new(1, -40, 0, 1),
    BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.92,
    BorderSizePixel = 0, Parent = Sidebar,
})
makeTab(CONFIG, UDim2.new(0, 12, 1, -48))

------------------------------------------------------------------------
-- TOP BAR
------------------------------------------------------------------------
new("Frame", {
    Position = UDim2.new(0, 180, 0, 56), Size = UDim2.new(1, -180, 0, 1),
    BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.92,
    BorderSizePixel = 0, Parent = Main,
})

local SearchFrame = new("Frame", {
    Position = UDim2.fromOffset(196, 11), Size = UDim2.new(1, -252, 0, 34),
    BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.94, Parent = Main,
})
corner(SearchFrame, 8)
local SearchStroke = new("UIStroke", { Thickness = 1, Transparency = 0.9, Parent = SearchFrame })
bindAccent(function(c) SearchStroke.Color = c end)

local SearchIcon = new("TextLabel", {
    Position = UDim2.fromOffset(10, 0), Size = UDim2.fromOffset(20, 34),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14,
    TextColor3 = Theme.SubText, Text = "⌕", Parent = SearchFrame,
})
local SearchBox = new("TextBox", {
    Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -44, 1, 0),
    BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13,
    TextColor3 = Theme.Text, PlaceholderColor3 = Color3.fromRGB(110, 110, 120),
    PlaceholderText = "Search modules...", Text = "", ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = SearchFrame,
})
connect(SearchBox.Focused, function()
    tween(SearchStroke, EASE.Fast, { Transparency = 0.25 })
    tween(SearchFrame, EASE.Fast, { BackgroundTransparency = 0.9 })
    tween(SearchIcon, EASE.Fast, { TextColor3 = Theme.Accent })
end)
connect(SearchBox.FocusLost, function()
    tween(SearchStroke, EASE.Fast, { Transparency = 0.9 })
    tween(SearchFrame, EASE.Fast, { BackgroundTransparency = 0.94 })
    tween(SearchIcon, EASE.Fast, { TextColor3 = Theme.SubText })
end)

local CloseBtn = new("TextButton", {
    Position = UDim2.new(1, -46, 0, 11), Size = UDim2.fromOffset(34, 34),
    BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.94,
    AutoButtonColor = false, Font = Enum.Font.GothamBold, TextSize = 14,
    TextColor3 = Theme.SubText, Text = "X", Parent = Main,
})
corner(CloseBtn, 8)
connect(CloseBtn.MouseEnter, function()
    tween(CloseBtn, EASE.Fast, { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.15, TextColor3 = Color3.new(1, 1, 1) })
end)
connect(CloseBtn.MouseLeave, function()
    tween(CloseBtn, EASE.Fast, { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.94, TextColor3 = Theme.SubText })
end)

------------------------------------------------------------------------
-- BODY
------------------------------------------------------------------------
local Body = new("Frame", {
    Position = UDim2.fromOffset(180, 57), Size = UDim2.new(1, -180, 1, -57),
    BackgroundTransparency = 1, ClipsDescendants = true, Parent = Main,
})

local HeaderTitle = new("TextLabel", {
    Position = UDim2.fromOffset(16, 10), Size = UDim2.new(0.6, 0, 0, 20),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 15,
    TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Text = "ALL", Parent = Body,
})
local HeaderCount = new("TextLabel", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 12),
    Size = UDim2.new(0.4, 0, 0, 16), BackgroundTransparency = 1, Font = Enum.Font.Gotham,
    TextSize = 12, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Right,
    Text = "0 modules", Parent = Body,
})

local Scroll = new("ScrollingFrame", {
    Position = UDim2.fromOffset(16, 40), Size = UDim2.new(1, -32, 1, -52),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
    ScrollBarImageTransparency = 0.2, CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
    Parent = Body,
})
bindAccent(function(c) Scroll.ScrollBarImageColor3 = c end)
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Scroll })
padding(Scroll, 0, 8, 2, 8)

local Empty = new("Frame", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = Body,
})
new("UIListLayout", {
    Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = Empty,
})
local ChickenHolder = new("Frame", {
    Size = UDim2.fromOffset(70, 70), BackgroundTransparency = 1, LayoutOrder = 1, Parent = Empty,
})
local Chicken = new("TextLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
    TextSize = 46, Text = "🐔", Parent = ChickenHolder,
})
tween(Chicken, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    Position = UDim2.new(0.5, 0, 0.5, -7), Rotation = 6,
})
new("TextLabel", {
    Size = UDim2.new(1, -40, 0, 28), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
    TextSize = 22, TextColor3 = Theme.Text, Text = "Nothing here but us chickens!",
    LayoutOrder = 2, Parent = Empty,
})
new("TextLabel", {
    Size = UDim2.new(1, -60, 0, 36), BackgroundTransparency = 1, Font = Enum.Font.Gotham,
    TextSize = 13, TextColor3 = Theme.SubText, TextWrapped = true,
    Text = "If you were looking for something specific here, we probably don't have it. :P",
    LayoutOrder = 3, Parent = Empty,
})

------------------------------------------------------------------------
-- TOASTS
------------------------------------------------------------------------
local Toasts = new("Frame", {
    AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -20),
    Size = UDim2.new(0, 280, 1, -40), BackgroundTransparency = 1, Parent = Gui,
})
new("UIListLayout", {
    Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Bottom,
    HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder, Parent = Toasts,
})

function Hub:Notify(title, text, duration)
    if not NotificationsEnabled or Destroyed then return end
    duration = duration or 3
    local wrap = new("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Parent = Toasts })
    local toast = new("CanvasGroup", {
        Position = UDim2.new(1, 30, 0, 0), Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.15,
        GroupTransparency = 1, Parent = wrap,
    })
    corner(toast, 10)
    local ts = new("UIStroke", { Thickness = 1, Transparency = 0.6, Parent = toast })
    local bar = new("Frame", { Size = UDim2.new(0, 4, 1, 0), BorderSizePixel = 0, Parent = toast })
    local prog = new("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0, Parent = toast,
    })
    bindAccent(function(c) ts.Color = c; bar.BackgroundColor3 = c; prog.BackgroundColor3 = c end)
    new("TextLabel", {
        Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -26, 0, 16), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left, Text = title or HUB_NAME, Parent = toast,
    })
    new("TextLabel", {
        Position = UDim2.fromOffset(16, 26), Size = UDim2.new(1, -26, 0, 16), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        Text = text or "", Parent = toast,
    })
    tween(toast, EASE.Slow, { Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0 })
    tween(prog, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) })
    task.delay(duration, function()
        if not wrap.Parent then return end
        tween(toast, EASE.In, { Position = UDim2.new(1, 30, 0, 0), GroupTransparency = 1 })
        task.wait(0.28)
        wrap:Destroy()
    end)
end

------------------------------------------------------------------------
-- REFRESH / TAB LOGIC
------------------------------------------------------------------------
local refreshToken = 0
local emptyShown = false

local function refresh(animate)
    refreshToken += 1
    local tok = refreshToken
    local query = SearchBox.Text:lower()
    local shown = 0

    for _, m in ipairs(Hub.Modules) do
        local inTab = (CurrentTab == "ALL" and m.Tab ~= CONFIG) or m.Tab == CurrentTab
        local match = query == ""
            or m.Name:lower():find(query, 1, true) ~= nil
            or m.Desc:lower():find(query, 1, true) ~= nil
        local vis = inTab and match
        if vis then
            shown += 1
            if animate then
                m.Card.GroupTransparency = 1
                m.Card.Visible = true
                task.delay((shown - 1) * 0.035, function()
                    if tok == refreshToken then tween(m.Card, EASE.Med, { GroupTransparency = 0 }) end
                end)
            else
                m.Card.Visible = true
                m.Card.GroupTransparency = 0
            end
        else
            m.Card.Visible = false
        end
    end

    HeaderTitle.Text = CurrentTab
    HeaderCount.Text = shown .. (shown == 1 and " module" or " modules")
    SearchBox.PlaceholderText = "Search modules in " .. CurrentTab .. "..."

    if shown == 0 then
        if not emptyShown then
            emptyShown = true
            Empty.Visible = true
            tween(Chicken, EASE.Slow, { TextTransparency = 0 })
        end
    else
        emptyShown = false
        Empty.Visible = false
    end
end

local function selectTab(name)
    CurrentTab = name
    local btn = TabButtons[name]
    tween(Indicator, EASE.Med, { Position = btn.Position })
    for n, b in pairs(TabButtons) do
        tween(b, EASE.Med, { TextColor3 = (n == name) and Theme.Text or Theme.SubText })
        tween(b, EASE.Fast, { BackgroundTransparency = 1 })
    end
    Scroll.CanvasPosition = Vector2.new(0, 0)
    refresh(true)
end

for name, b in pairs(TabButtons) do
    connect(b.MouseButton1Click, function() selectTab(name) end)
    connect(b.MouseEnter, function()
        if CurrentTab ~= name then tween(b, EASE.Fast, { BackgroundTransparency = 0.94, TextColor3 = Theme.Text }) end
    end)
    connect(b.MouseLeave, function()
        if CurrentTab ~= name then tween(b, EASE.Fast, { BackgroundTransparency = 1, TextColor3 = Theme.SubText }) end
    end)
end
connect(SearchBox:GetPropertyChangedSignal("Text"), function() refresh(false) end)

------------------------------------------------------------------------
-- MODULE CARDS
------------------------------------------------------------------------
local ModuleCount = 0
local WHITE = Color3.new(1, 1, 1)

local function makeCard(height)
    ModuleCount += 1
    local card = new("CanvasGroup", {
        Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = WHITE, BackgroundTransparency = 0.94,
        LayoutOrder = ModuleCount, Parent = Scroll,
    })
    corner(card, 10)
    local stroke = new("UIStroke", { Thickness = 1, Transparency = 0.9, Color = WHITE, Parent = card })
    connect(card.MouseEnter, function()
        tween(stroke, EASE.Fast, { Transparency = 0.45, Color = Theme.Accent })
        tween(card, EASE.Fast, { BackgroundTransparency = 0.9 })
    end)
    connect(card.MouseLeave, function()
        tween(stroke, EASE.Fast, { Transparency = 0.9, Color = WHITE })
        tween(card, EASE.Fast, { BackgroundTransparency = 0.94 })
    end)
    return card, stroke
end

local function cardLabels(card, m, height)
    local hasDesc = m.Desc ~= ""
    new("TextLabel", {
        Position = UDim2.fromOffset(14, hasDesc and 10 or math.floor((height - 18) / 2)),
        Size = UDim2.new(1, -140, 0, 18), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
        TextSize = 14, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Text = m.Name, Parent = card,
    })
    if hasDesc then
        new("TextLabel", {
            Position = UDim2.fromOffset(14, 29), Size = UDim2.new(1, -140, 0, 16),
            BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12,
            TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, Text = m.Desc, Parent = card,
        })
    end
end

local function hitButton(card)
    return new("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5, Parent = card,
    })
end

local function isPress(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end
local function isMove(i)
    return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

local builders = {}

builders.Toggle = function(m, cfg)
    local card = makeCard(56)
    cardLabels(card, m, 56)
    local state = cfg.Default == true
    local sw = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0),
        Size = UDim2.fromOffset(42, 22), BackgroundColor3 = Theme.Off, Parent = card,
    })
    pill(sw)
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(16, 16), BackgroundColor3 = WHITE, Parent = sw,
    })
    pill(knob)
    local function render()
        tween(sw, EASE.Fast, { BackgroundColor3 = state and Theme.Accent or Theme.Off })
        tween(knob, EASE.Pop, { Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) })
    end
    bindAccent(function(c) if state then sw.BackgroundColor3 = c end end)
    render()
    function m.Set(v, silent)
        state = v and true or false
        render()
        if not silent then task.spawn(m.Callback, state) end
    end
    function m.Get() return state end
    connect(hitButton(card).MouseButton1Click, function()
        m.Set(not state)
        Hub:Notify(m.Name, state and "Enabled" or "Disabled", 1.8)
    end)
    return card
end

builders.Button = function(m, cfg)
    local card = makeCard(56)
    cardLabels(card, m, 56)
    local btn = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0),
        Size = UDim2.fromOffset(64, 26), BackgroundTransparency = 0.8, Parent = card,
    })
    corner(btn, 7)
    local lbl = new("TextLabel", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
        TextSize = 11, Text = cfg.ButtonText or "RUN", Parent = btn,
    })
    bindAccent(function(c) btn.BackgroundColor3 = c; lbl.TextColor3 = c end)
    function m.Get() return nil end
    function m.Set() end
    connect(hitButton(card).MouseButton1Click, function()
        tween(btn, EASE.Fast, { BackgroundTransparency = 0.2, Size = UDim2.fromOffset(58, 24) })
        tween(lbl, EASE.Fast, { TextColor3 = WHITE })
        task.delay(0.12, function()
            tween(btn, EASE.Pop, { BackgroundTransparency = 0.8, Size = UDim2.fromOffset(64, 26) })
            tween(lbl, EASE.Med, { TextColor3 = Theme.Accent })
        end)
        task.spawn(m.Callback)
    end)
    return card
end

builders.Keybind = function(m, cfg)
    local card = makeCard(56)
    cardLabels(card, m, 56)
    local key = cfg.Default or Enum.KeyCode.Unknown
    local box = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0),
        Size = UDim2.fromOffset(84, 26), BackgroundColor3 = WHITE, BackgroundTransparency = 0.9, Parent = card,
    })
    corner(box, 7)
    local lbl = new("TextLabel", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
        TextSize = 11, TextColor3 = Theme.Text, Text = key.Name, Parent = box,
    })
    function m.Get() return key end
    function m.Set(k, silent)
        key = k; lbl.Text = k.Name
        tween(lbl, EASE.Fast, { TextColor3 = Theme.Text })
        tween(box, EASE.Fast, { BackgroundTransparency = 0.9 })
        if not silent then task.spawn(m.Callback, k) end
    end
    m._listen = function() lbl.Text = "..."; tween(lbl, EASE.Fast, { TextColor3 = Theme.Accent }); tween(box, EASE.Fast, { BackgroundTransparency = 0.8 }) end
    m._cancel = function() lbl.Text = key.Name; tween(lbl, EASE.Fast, { TextColor3 = Theme.Text }); tween(box, EASE.Fast, { BackgroundTransparency = 0.9 }) end
    connect(hitButton(card).MouseButton1Click, function() Listening = m; m._listen() end)
    return card
end

builders.Slider = function(m, cfg)
    local card = makeCard(74)
    cardLabels(card, m, 74)
    local min, max = cfg.Min or 0, cfg.Max or 100
    local inc = cfg.Increment or 1
    local suffix = cfg.Suffix or ""
    local value = cfg.Default or min

    local valLabel = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 10), Size = UDim2.fromOffset(90, 18),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right, Text = "", Parent = card,
    })
    bindAccent(function(c) valLabel.TextColor3 = c end)

    local track = new("Frame", {
        Position = UDim2.new(0, 14, 0, 56), Size = UDim2.new(1, -28, 0, 6),
        BackgroundColor3 = WHITE, BackgroundTransparency = 0.88, Parent = card,
    })
    pill(track)
    local fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), Parent = track })
    pill(fill)
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(14, 14), BackgroundColor3 = WHITE, Parent = track,
    })
    pill(knob)
    bindAccent(function(c) fill.BackgroundColor3 = c end)

    local function fmt(v)
        if inc >= 1 then return string.format("%d%s", v, suffix) end
        return string.format("%.2f%s", v, suffix)
    end
    local function apply(v, silent)
        v = math.clamp(math.floor(v / inc + 0.5) * inc, min, max)
        v = tonumber(string.format("%.4f", v))
        value = v
        local a = (max - min) == 0 and 0 or (v - min) / (max - min)
        local ti = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        tween(fill, ti, { Size = UDim2.new(a, 0, 1, 0) })
        tween(knob, ti, { Position = UDim2.new(a, 0, 0.5, 0) })
        valLabel.Text = fmt(v)
        if not silent then task.spawn(m.Callback, v) end
    end
    m.Set = apply
    function m.Get() return value end
    apply(value, true)

    local dragging = false
    local function fromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        apply(min + (max - min) * rel)
    end
    local hit = new("TextButton", {
        Position = UDim2.new(0, 8, 0, 46), Size = UDim2.new(1, -16, 0, 26),
        BackgroundTransparency = 1, Text = "", ZIndex = 5, Parent = card,
    })
    connect(hit.InputBegan, function(i)
        if isPress(i) then dragging = true; tween(knob, EASE.Fast, { Size = UDim2.fromOffset(18, 18) }); fromX(i.Position.X) end
    end)
    connect(UserInputService.InputChanged, function(i)
        if dragging and isMove(i) then fromX(i.Position.X) end
    end)
    connect(UserInputService.InputEnded, function(i)
        if dragging and isPress(i) then dragging = false; tween(knob, EASE.Pop, { Size = UDim2.fromOffset(14, 14) }) end
    end)
    return card
end

builders.Color = function(m, cfg)
    local card = makeCard(110)
    cardLabels(card, m, 110)
    local presets = {
        Color3.fromRGB(255, 45, 60), Color3.fromRGB(255, 140, 40), Color3.fromRGB(255, 214, 60),
        Color3.fromRGB(60, 220, 120), Color3.fromRGB(50, 210, 255), Color3.fromRGB(70, 120, 255),
        Color3.fromRGB(160, 90, 255), Color3.fromRGB(255, 90, 180),
    }
    local function picked(c, instant)
        if Rainbow and rainbowMod then rainbowMod.Set(false) end
        setAccent(c, instant); task.spawn(m.Callback, c)
    end
    for i, c in ipairs(presets) do
        local s = new("TextButton", {
            Position = UDim2.fromOffset(14 + (i - 1) * 32, 52), Size = UDim2.fromOffset(24, 24),
            BackgroundColor3 = c, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = card,
        })
        pill(s)
        local st = new("UIStroke", { Thickness = 2, Color = WHITE, Transparency = 1, Parent = s })
        connect(s.MouseEnter, function()
            tween(s, EASE.Pop, { Size = UDim2.fromOffset(28, 28), Position = UDim2.fromOffset(12 + (i - 1) * 32, 50) })
            tween(st, EASE.Fast, { Transparency = 0.2 })
        end)
        connect(s.MouseLeave, function()
            tween(s, EASE.Med, { Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(14 + (i - 1) * 32, 52) })
            tween(st, EASE.Fast, { Transparency = 1 })
        end)
        connect(s.MouseButton1Click, function() picked(c, false) end)
    end

    local hue = new("Frame", {
        Position = UDim2.new(0, 14, 0, 90), Size = UDim2.new(1, -28, 0, 10), BackgroundColor3 = WHITE, Parent = card,
    })
    pill(hue)
    local kp = {}
    for i = 0, 6 do
        table.insert(kp, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6 % 1 + (i == 6 and 0.9999 or 0), 0.85, 1)))
    end
    kp[7] = ColorSequenceKeypoint.new(1, Color3.fromHSV(0, 0.85, 1))
    new("UIGradient", { Color = ColorSequence.new(kp), Parent = hue })
    local hk = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(6, 18), BackgroundColor3 = WHITE, Parent = hue,
    })
    corner(hk, 3)
    local dragging = false
    local function fromX(x)
        local rel = math.clamp((x - hue.AbsolutePosition.X) / math.max(hue.AbsoluteSize.X, 1), 0, 1)
        tween(hk, TweenInfo.new(0.06), { Position = UDim2.new(rel, 0, 0.5, 0) })
        picked(Color3.fromHSV(math.min(rel, 0.999), 0.85, 1), true)
    end
    local hhit = new("TextButton", {
        Position = UDim2.new(0, 8, 0, 82), Size = UDim2.new(1, -16, 0, 26),
        BackgroundTransparency = 1, Text = "", ZIndex = 5, Parent = card,
    })
    connect(hhit.InputBegan, function(i) if isPress(i) then dragging = true; fromX(i.Position.X) end end)
    connect(UserInputService.InputChanged, function(i) if dragging and isMove(i) then fromX(i.Position.X) end end)
    connect(UserInputService.InputEnded, function(i) if dragging and isPress(i) then dragging = false end end)
    function m.Get() return Theme.Accent end
    function m.Set(c) setAccent(c) end
    return card
end

function Hub:AddModule(cfg)
    cfg = cfg or {}
    local tab = (cfg.Tab or "MISC"):upper()
    local valid = tab == CONFIG
    for _, t in ipairs(TABS) do if t == tab and t ~= "ALL" then valid = true end end
    if not valid then tab = "MISC" end

    local m = {
        Name = cfg.Name or "Unnamed",
        Desc = cfg.Description or "",
        Tab = tab,
        Type = cfg.Type or "Toggle",
        Callback = cfg.Callback or function() end,
    }
    local build = builders[m.Type] or builders.Toggle
    m.Card = build(m, cfg)
    m.Card.Name = m.Name
    table.insert(Hub.Modules, m)
    refresh(false)
    return m
end

------------------------------------------------------------------------
-- OPEN / CLOSE / CONFIRM POPUP
------------------------------------------------------------------------
function Hub:SetOpen(state)
    if Destroyed then return end
    Open = state
    openToken += 1
    local tok = openToken
    if state then
        Main.Visible = true
        tween(OpenScale, EASE.Pop, { Scale = 1 })
        tween(Main, EASE.Med, { GroupTransparency = 0 })
    else
        tween(OpenScale, EASE.In, { Scale = 0.92 })
        tween(Main, EASE.In, { GroupTransparency = 1 })
        task.delay(0.27, function()
            if tok == openToken and not Open then Main.Visible = false end
        end)
    end
end

local Overlay = new("Frame", {
    Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
    Visible = false, Active = true, ZIndex = 50, Parent = Main,
})
corner(Overlay, 12)
local Dialog = new("CanvasGroup", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(330, 160), BackgroundColor3 = Theme.Dialog,
    GroupTransparency = 1, Parent = Overlay,
})
corner(Dialog, 12)
local DialogScale = new("UIScale", { Scale = 0.85, Parent = Dialog })
local DialogStroke = new("UIStroke", { Thickness = 1.5, Transparency = 0.3, Parent = Dialog })
bindAccent(function(c) DialogStroke.Color = c end)
new("TextLabel", {
    Position = UDim2.fromOffset(20, 20), Size = UDim2.new(1, -40, 0, 46), BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold, TextSize = 17, TextColor3 = Theme.Text, TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    Text = "Are you sure to close k0rdhub?", Parent = Dialog,
})
new("TextLabel", {
    Position = UDim2.fromOffset(20, 68), Size = UDim2.new(1, -40, 0, 30), BackgroundTransparency = 1,
    Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.SubText, TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    Text = "The hub will be fully unloaded. Run the script again to bring it back.", Parent = Dialog,
})
local function dialogButton(text, x, accent)
    local b = new("TextButton", {
        Position = UDim2.new(x, x == 0 and 20 or 6, 1, -54), Size = UDim2.new(0.5, -26, 0, 36),
        BackgroundColor3 = WHITE, BackgroundTransparency = 0.92, AutoButtonColor = false,
        Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.Text, Text = text, Parent = Dialog,
    })
    corner(b, 8)
    local rest = accent and 0.1 or 0.92
    if accent then
        bindAccent(function(c) b.BackgroundColor3 = c end)
        b.BackgroundTransparency = rest
    end
    connect(b.MouseEnter, function() tween(b, EASE.Fast, { BackgroundTransparency = accent and 0 or 0.82 }) end)
    connect(b.MouseLeave, function() tween(b, EASE.Fast, { BackgroundTransparency = rest }) end)
    return b
end
local CancelBtn = dialogButton("Cancel", 0, false)
local ConfirmBtn = dialogButton("Close", 0.5, true)

local confirmOpen = false
local function showConfirm()
    if confirmOpen then return end
    confirmOpen = true
    Overlay.Visible = true; DialogScale.Scale = 0.85
    tween(Overlay, EASE.Med, { BackgroundTransparency = 0.45 })
    tween(Dialog, EASE.Med, { GroupTransparency = 0 })
    tween(DialogScale, EASE.Pop, { Scale = 1 })
end
local function hideConfirm()
    if not confirmOpen then return end
    confirmOpen = false
    tween(Overlay, EASE.In, { BackgroundTransparency = 1 })
    tween(Dialog, EASE.In, { GroupTransparency = 1 })
    tween(DialogScale, EASE.In, { Scale = 0.9 })
    task.delay(0.26, function() if not confirmOpen then Overlay.Visible = false end end)
end
Hub.ShowConfirm = showConfirm

connect(CloseBtn.MouseButton1Click, showConfirm)
connect(CancelBtn.MouseButton1Click, hideConfirm)

-- dragging
do
    local dragging, dragStart, startPos
    connect(DragBar.InputBegan, function(i)
        if isPress(i) then dragging, dragStart, startPos = true, i.Position, Root.Position end
    end)
    connect(UserInputService.InputChanged, function(i)
        if dragging and isMove(i) then
            local d = i.Position - dragStart
            tween(Root, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y),
            })
        end
    end)
    connect(UserInputService.InputEnded, function(i) if isPress(i) then dragging = false end end)
end

-- keyboard
connect(UserInputService.InputBegan, function(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if Listening then
        local l = Listening; Listening = nil
        if input.KeyCode == Enum.KeyCode.Escape then l._cancel() else l.Set(input.KeyCode) end
        return
    end
    if input.KeyCode == Enum.KeyCode.Escape and confirmOpen then hideConfirm(); return end
    if input.KeyCode == ToggleKey and Loaded then Hub:SetOpen(not Open) end
end)

-- rainbow
connect(RunService.Heartbeat, function()
    if Rainbow then setAccent(Color3.fromHSV((os.clock() * 0.12) % 1, 0.85, 1), true) end
end)

------------------------------------------------------------------------
-- CONFIGURATION TAB
------------------------------------------------------------------------
Hub:AddModule({ Name = "Accent Color", Description = "Pick a preset or drag the hue bar", Tab = CONFIG, Type = "Color" })
rainbowMod = Hub:AddModule({ Name = "Rainbow Accent", Description = "Cycle the accent color continuously", Tab = CONFIG, Type = "Toggle", Default = false, Callback = function(s) Rainbow = s end })
Hub:AddModule({ Name = "Background Transparency", Description = "How see-through the window is", Tab = CONFIG, Type = "Slider", Min = 0, Max = 0.9, Default = 0.2, Increment = 0.01, Callback = function(v) tween(Main, EASE.Fast, { BackgroundTransparency = v }) end })
Hub:AddModule({ Name = "UI Scale", Description = "Resize the whole menu", Tab = CONFIG, Type = "Slider", Min = 0.7, Max = 1.3, Default = 1, Increment = 0.05, Callback = function(v) tween(UserScale, EASE.Fast, { Scale = v }) end })
Hub:AddModule({ Name = "Menu Keybind", Description = "Click, then press a key to rebind", Tab = CONFIG, Type = "Keybind", Default = Enum.KeyCode.RightShift, Callback = function(k) ToggleKey = k; Hub:Notify("Keybind", "Menu key set to " .. k.Name, 2) end })
Hub:AddModule({ Name = "Notifications", Description = "Show toast popups when modules change", Tab = CONFIG, Type = "Toggle", Default = true, Callback = function(s) NotificationsEnabled = s end })
Hub:AddModule({ Name = "Rejoin Server", Description = "Teleport back into this server", Tab = CONFIG, Type = "Button", ButtonText = "REJOIN", Callback = function()
    pcall(function()
        if #Players:GetPlayers() <= 1 then
            Players.LocalPlayer:Kick("\nRejoining..."); task.wait()
            TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
        end
    end)
end })
Hub:AddModule({ Name = "Copy Game ID", Description = "Copies the current PlaceId to your clipboard", Tab = CONFIG, Type = "Button", ButtonText = "COPY", Callback = function()
    local ok = pcall(function() setclipboard(tostring(game.PlaceId)) end)
    Hub:Notify("Game ID", ok and ("Copied " .. game.PlaceId) or "Clipboard not supported", 2)
end })
Hub:AddModule({ Name = "Unload K0rdHub", Description = "Close and fully remove the hub", Tab = CONFIG, Type = "Button", ButtonText = "UNLOAD", Callback = showConfirm })

------------------------------------------------------------------------
-- GAME MODULE INITIALIZATION
------------------------------------------------------------------------
local RS  = game:GetService("ReplicatedStorage")
local PS  = Players.LocalPlayer.PlayerScripts

local function gameReq(parent, path)
    local obj = parent
    for _, p in ipairs(path:split(".")) do
        obj = obj and obj:FindFirstChild(p)
    end
    if not obj then return nil end
    local ok, r = pcall(require, obj)
    return ok and r or nil
end

local GameState        = gameReq(PS, "Client.Net.GameState")
local InputSampler     = gameReq(PS, "Client.Net.InputSampler")
local CmdSender        = gameReq(PS, "Client.Net.CmdSender")
local WeaponSim        = gameReq(RS, "Shared.Sim.WeaponSim")
local WeaponPrediction = gameReq(PS, "Client.Net.WeaponPrediction")
local Units            = gameReq(RS, "Shared.Util.Units")
local CmdCodec         = gameReq(RS, "Shared.Net.CmdCodec")

local DS_Characters = workspace:FindFirstChild("DS_Characters")
local IN_JUMP   = (CmdCodec and CmdCodec.IN and CmdCodec.IN.JUMP)   or 2
local IN_ATTACK = (CmdCodec and CmdCodec.IN and CmdCodec.IN.ATTACK) or 1

------------------------------------------------------------------------
-- MODULE STATE
------------------------------------------------------------------------
local S = {
    playerESP   = false,
    teamESP     = false,
    tracers     = false,
    aimAssist   = false,
    aimLock     = false,
    aimSoftness = 5,
    aimFOV      = 200,
    autoBhop    = false,
    noRecoil    = false,
    antiFlash   = false,
    darkVisuals = false,
}

------------------------------------------------------------------------
-- ESP DRAWING CACHE
------------------------------------------------------------------------
local espDraw    = {}   -- [entityId] = { box, name, dist, tracer }
local highlights = {}   -- [entityId] = Highlight
local DEAD_Y    = 999_000_000

local function findHead(model)
    for _, d in ipairs(model:GetDescendants()) do
        if d.Name == "head_0" and d:IsA("Bone") then return d end
    end
    return nil
end

local function getDraw(id)
    if espDraw[id] then return espDraw[id] end
    local d = {}
    d.box = Drawing.new("Square");  d.box.Thickness = 1;  d.box.Filled = false;  d.box.Visible = false
    d.name = Drawing.new("Text");   d.name.Size = 13;     d.name.Center = true;   d.name.Outline = true; d.name.Visible = false
    d.dist = Drawing.new("Text");   d.dist.Size = 11;     d.dist.Center = true;   d.dist.Outline = true; d.dist.Visible = false; d.dist.Color = Color3.fromRGB(200,200,200)
    d.tracer = Drawing.new("Line"); d.tracer.Thickness = 1; d.tracer.Visible = false
    espDraw[id] = d
    return d
end

local function hideDraw(id)
    local d = espDraw[id]; if not d then return end
    d.box.Visible = false; d.name.Visible = false; d.dist.Visible = false; d.tracer.Visible = false
end
local function hideAllDraw()
    for id in pairs(espDraw) do hideDraw(id) end
end

local function removeHL(id)
    if highlights[id] then pcall(function() highlights[id]:Destroy() end); highlights[id] = nil end
end
local function removeAllHL()
    for id in pairs(highlights) do removeHL(id) end
end

local function espColor(team)
    if S.teamESP then
        if team == 2 then return Color3.fromRGB(255, 165, 0) end -- T orange
        if team == 3 then return Color3.fromRGB(80, 160, 255) end -- CT blue
    end
    return Color3.new(1, 1, 1) -- white
end

------------------------------------------------------------------------
-- AIM HELPERS
------------------------------------------------------------------------
local function dirToAngles(dir)
    local pitch = -math.deg(math.asin(math.clamp(dir.Y, -1, 1)))
    local yaw   = math.deg(math.atan2(-dir.Z, dir.X))
    return pitch, yaw
end

local function angleDelta(a, b)
    local d = (a - b) % 360
    return d > 180 and d - 360 or d
end

local function closestEnemy(maxPx)
    if not GameState or not DS_Characters then return nil end
    local cam = workspace.CurrentCamera
    local center = cam.ViewportSize / 2
    local best, bestD = nil, maxPx

    for _, e in pairs(GameState.others) do
        if e.Alive == 1 and e.Team ~= GameState.team then
            local m = DS_Characters:FindFirstChild("Player" .. e.Id)
            if m then
                local head = findHead(m)
                if head then
                    local sp, vis = cam:WorldToViewportPoint(head.WorldPosition)
                    if vis then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d < bestD then best = head.WorldPosition; bestD = d end
                    end
                end
            end
        end
    end
    return best
end

------------------------------------------------------------------------
-- BHOP HOOK
------------------------------------------------------------------------
local origCreateCmd
local function setBhop(on)
    S.autoBhop = on
    if on and InputSampler and not origCreateCmd then
        origCreateCmd = InputSampler.createCmd
        InputSampler.createCmd = function(...)
            local cmd = origCreateCmd(...)
            if S.autoBhop and type(cmd) == "table" and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                cmd.buttons = bit32.bor(cmd.buttons or 0, IN_JUMP)
            end
            return cmd
        end
    elseif not on and origCreateCmd then
        InputSampler.createCmd = origCreateCmd; origCreateCmd = nil
    end
end

------------------------------------------------------------------------
-- NO RECOIL HOOK
------------------------------------------------------------------------
local origPunchStep, origCameraPunch
local function setNoRecoil(on)
    S.noRecoil = on
    if not WeaponSim then return end
    if on then
        if not origPunchStep then origPunchStep = WeaponSim.punchStep end
        if not origCameraPunch then origCameraPunch = WeaponSim.cameraPunch end
        WeaponSim.punchStep   = function(...) end          -- no-op: prevent recoil accumulation
        WeaponSim.cameraPunch = function(...) return 0, 0 end -- no visual punch
    else
        if origPunchStep   then WeaponSim.punchStep   = origPunchStep end
        if origCameraPunch then WeaponSim.cameraPunch = origCameraPunch end
    end
end

------------------------------------------------------------------------
-- ANTI-FLASH
------------------------------------------------------------------------
local flashConns = {}
local function blockFlashGui(gui)
    if gui.Name ~= "DS_Flash" then return end
    for _, c in ipairs(gui:GetDescendants()) do
        pcall(function()
            if c:IsA("Frame") then c.BackgroundTransparency = 1 end
            if c:IsA("ImageLabel") then c.ImageTransparency = 1 end
        end)
    end
end
local function setAntiFlash(on)
    S.antiFlash = on
    local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end
    if on then
        local fl = pg:FindFirstChild("DS_Flash")
        if fl then blockFlashGui(fl) end
        flashConns[1] = pg.ChildAdded:Connect(function(c) if S.antiFlash then blockFlashGui(c) end end)
        flashConns[2] = pg.DescendantAdded:Connect(function(c)
            if not S.antiFlash then return end
            local sg = c:FindFirstAncestorOfClass("ScreenGui")
            if sg and sg.Name == "DS_Flash" then
                pcall(function()
                    if c:IsA("Frame") then c.BackgroundTransparency = 1 end
                    if c:IsA("ImageLabel") then c.ImageTransparency = 1 end
                end)
            end
        end)
    else
        for _, c in ipairs(flashConns) do pcall(function() c:Disconnect() end) end
        flashConns = {}
        local fl = pg:FindFirstChild("DS_Flash")
        if fl then
            for _, c in ipairs(fl:GetDescendants()) do
                pcall(function()
                    if c:IsA("Frame") then c.BackgroundTransparency = 0 end
                    if c:IsA("ImageLabel") then c.ImageTransparency = 0 end
                end)
            end
        end
    end
end

------------------------------------------------------------------------
-- DARK VISUALS
------------------------------------------------------------------------
local origLight = {}
local function setDarkVisuals(on)
    S.darkVisuals = on
    if on then
        origLight.Ambient        = Lighting.Ambient
        origLight.Brightness     = Lighting.Brightness
        origLight.OutdoorAmbient = Lighting.OutdoorAmbient
        origLight.ClockTime      = Lighting.ClockTime

        Lighting.Ambient        = Color3.fromRGB(0, 0, 0)
        Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
        Lighting.Brightness     = 0.08
        Lighting.ClockTime      = 0

        local cc = Lighting:FindFirstChild("K0rdCC") or Instance.new("ColorCorrectionEffect")
        cc.Name = "K0rdCC"; cc.Parent = Lighting
        cc.Brightness = -0.25; cc.Contrast = 0.25; cc.Saturation = -0.35

        for _, c in ipairs(Lighting:GetChildren()) do
            if c:IsA("Atmosphere") then
                c.Density = 0.75; c.Color = Color3.fromRGB(8, 8, 16)
            end
        end
    else
        if origLight.Ambient        then Lighting.Ambient        = origLight.Ambient end
        if origLight.Brightness     then Lighting.Brightness     = origLight.Brightness end
        if origLight.OutdoorAmbient then Lighting.OutdoorAmbient = origLight.OutdoorAmbient end
        if origLight.ClockTime      then Lighting.ClockTime      = origLight.ClockTime end

        local cc = Lighting:FindFirstChild("K0rdCC")
        if cc then cc:Destroy() end

        for _, c in ipairs(Lighting:GetChildren()) do
            if c:IsA("Atmosphere") then c.Density = 0.3; c.Color = Color3.fromRGB(199, 199, 199) end
        end
    end
end

------------------------------------------------------------------------
-- REGISTER MODULES
------------------------------------------------------------------------
-- ── VISUALS ──
Hub:AddModule({ Name = "Player ESP", Description = "Box ESP + highlight + distance", Tab = "VISUALS", Type = "Toggle", Callback = function(s)
    S.playerESP = s; if not s then hideAllDraw(); removeAllHL() end
end })
Hub:AddModule({ Name = "Team ESP", Description = "CT = blue  ·  T = orange", Tab = "VISUALS", Type = "Toggle", Callback = function(s) S.teamESP = s end })
Hub:AddModule({ Name = "Tracers", Description = "Lines from bottom of screen to players", Tab = "VISUALS", Type = "Toggle", Callback = function(s)
    S.tracers = s; if not s then for _, d in pairs(espDraw) do d.tracer.Visible = false end end
end })
Hub:AddModule({ Name = "Dark Visuals", Description = "Night mode — ESPs glow brighter", Tab = "VISUALS", Type = "Toggle", Callback = function(s) setDarkVisuals(s) end })
Hub:AddModule({ Name = "Anti-Flash", Description = "Block flashbang screen effect", Tab = "VISUALS", Type = "Toggle", Callback = function(s) setAntiFlash(s) end })

-- ── LEGIT ──
Hub:AddModule({ Name = "Aim Assist", Description = "Soft aim at closest enemy (hold RMB/LMB)", Tab = "LEGIT", Type = "Toggle", Callback = function(s) S.aimAssist = s end })
Hub:AddModule({ Name = "Aim Softness", Description = "Lower = slower, smoother aim", Tab = "LEGIT", Type = "Slider", Min = 1, Max = 100, Default = 5, Increment = 1, Callback = function(v) S.aimSoftness = v end })
Hub:AddModule({ Name = "Aim FOV", Description = "Screen-pixel radius to search targets", Tab = "LEGIT", Type = "Slider", Min = 50, Max = 800, Default = 200, Increment = 10, Suffix = "px", Callback = function(v) S.aimFOV = v end })
Hub:AddModule({ Name = "Aim Lock", Description = "Instant snap aim — rage (hold RMB/LMB)", Tab = "LEGIT", Type = "Toggle", Callback = function(s) S.aimLock = s end })
Hub:AddModule({ Name = "No Recoil", Description = "Removes visual + punch recoil", Tab = "LEGIT", Type = "Toggle", Callback = function(s) setNoRecoil(s) end })

-- ── MOVEMENT ──
Hub:AddModule({ Name = "Auto-Bhop", Description = "Hold space to bunny hop", Tab = "MOVEMENT", Type = "Toggle", Callback = function(s) setBhop(s) end })

------------------------------------------------------------------------
-- MAIN RENDER LOOP
------------------------------------------------------------------------
local renderConn
renderConn = connect(RunService.RenderStepped, function()
    if Destroyed then renderConn:Disconnect(); hideAllDraw(); removeAllHL(); return end
    local cam = workspace.CurrentCamera
    if not cam or not GameState or not DS_Characters then return end

    local vpSize       = cam.ViewportSize
    local screenBottom = Vector2.new(vpSize.X / 2, vpSize.Y)
    local activeIds    = {}

    for _, entity in pairs(GameState.others) do
        local id     = entity.Id
        activeIds[id] = true
        local alive  = entity.Alive == 1
        local model  = DS_Characters:FindFirstChild("Player" .. id)

        if alive and model then
            local root = model:FindFirstChild("RootPart")
            local head = findHead(model)

            if root and root.Position.Y < DEAD_Y and head then
                local headWP = head.WorldPosition + Vector3.new(0, 0.5, 0)
                local feetWP = root.Position + Vector3.new(0, -2.5, 0)
                local hsp, onScreen = cam:WorldToViewportPoint(headWP)
                local fsp = cam:WorldToViewportPoint(feetWP)
                local col  = espColor(entity.Team)
                local dist = (cam.CFrame.Position - root.Position).Magnitude

                if onScreen then
                    local d = getDraw(id)

                    -- Box ESP
                    if S.playerESP then
                        local h = math.abs(fsp.Y - hsp.Y)
                        local w = h * 0.55
                        d.box.Size     = Vector2.new(w, h)
                        d.box.Position = Vector2.new(hsp.X - w / 2, hsp.Y)
                        d.box.Color    = col; d.box.Visible = true

                        d.name.Text     = "Player" .. id
                        d.name.Position = Vector2.new(hsp.X, hsp.Y - 16)
                        d.name.Color    = col; d.name.Visible = true

                        d.dist.Text     = string.format("%.0fm", dist)
                        d.dist.Position = Vector2.new(fsp.X, fsp.Y + 2)
                        d.dist.Color    = col; d.dist.Visible = true
                    else
                        d.box.Visible = false; d.name.Visible = false; d.dist.Visible = false
                    end

                    -- Tracers
                    if S.tracers then
                        d.tracer.From  = screenBottom
                        d.tracer.To    = Vector2.new(fsp.X, fsp.Y)
                        d.tracer.Color = col; d.tracer.Visible = true
                    else
                        d.tracer.Visible = false
                    end
                else
                    hideDraw(id)
                end

                -- Highlight
                if S.playerESP then
                    if not highlights[id] or not highlights[id].Parent then
                        pcall(function()
                            local hl = Instance.new("Highlight")
                            hl.Name = "K0rdHL"
                            hl.FillTransparency    = 0.65
                            hl.OutlineTransparency = 0
                            hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
                            hl.FillColor    = col
                            hl.OutlineColor = col
                            hl.Parent       = model
                            highlights[id]  = hl
                        end)
                    else
                        highlights[id].FillColor    = col
                        highlights[id].OutlineColor = col
                    end
                else
                    removeHL(id)
                end
            else
                hideDraw(id); removeHL(id)
            end
        else
            hideDraw(id); removeHL(id)
        end
    end

    -- cleanup stale
    for id in pairs(espDraw)    do if not activeIds[id] then hideDraw(id) end end
    for id in pairs(highlights) do if not activeIds[id] then removeHL(id) end end

    -- ── Aim Assist / Lock ──
    if (S.aimAssist or S.aimLock) and InputSampler then
        local hold = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                  or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        if hold then
            local tgt = closestEnemy(S.aimFOV)
            if tgt then
                local tp, ty = dirToAngles((tgt - cam.CFrame.Position).Unit)
                local cp, cy = InputSampler.viewAngles()
                if S.aimLock then
                    InputSampler.setAngles(tp, ty)
                elseif S.aimAssist then
                    local sm = math.clamp(S.aimSoftness / 100, 0.01, 1)
                    InputSampler.setAngles(cp + angleDelta(tp, cp) * sm, cy + angleDelta(ty, cy) * sm)
                end
            end
        end
    end
end)

------------------------------------------------------------------------
-- DESTROY CLEANUP (extend original)
------------------------------------------------------------------------
connect(ConfirmBtn.MouseButton1Click, function()
    -- Cleanup game hooks
    pcall(function() if origCreateCmd   then InputSampler.createCmd   = origCreateCmd end end)
    pcall(function() if origPunchStep   then WeaponSim.punchStep     = origPunchStep end end)
    pcall(function() if origCameraPunch then WeaponSim.cameraPunch   = origCameraPunch end end)
    pcall(setAntiFlash, false)
    pcall(setDarkVisuals, false)
    hideAllDraw(); removeAllHL()
    for _, d in pairs(espDraw) do
        pcall(function() d.box:Remove() end)
        pcall(function() d.name:Remove() end)
        pcall(function() d.dist:Remove() end)
        pcall(function() d.tracer:Remove() end)
    end
    espDraw = {}

    -- UI destroy
    Destroyed = true; Rainbow = false
    local function cleanup()
        for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
        AccentValue:Destroy(); Gui:Destroy()
        if env.K0rdHub == Hub then env.K0rdHub = nil end
    end
    tween(OpenScale, EASE.In, { Scale = 0.85 })
    tween(Main, EASE.In, { GroupTransparency = 1 })
    task.delay(0.3, cleanup)
end)

------------------------------------------------------------------------
-- LAUNCH
------------------------------------------------------------------------
Indicator.Position = TabButtons.ALL.Position
TabButtons.ALL.TextColor3 = Theme.Text
refresh(false)

local function playIntro()
    local Loader = new("CanvasGroup", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(280, 210), BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.2, GroupTransparency = 1, Parent = Gui,
    })
    corner(Loader, 14)
    local LScale = new("UIScale", { Scale = 0.8, Parent = Loader })
    local LStroke = new("UIStroke", { Thickness = 1.5, Transparency = 0.35, Parent = Loader })

    local ring = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 22),
        Size = UDim2.fromOffset(84, 84), BackgroundTransparency = 1, Parent = Loader,
    })
    pill(ring)
    local ringStroke = new("UIStroke", { Thickness = 3, Color = WHITE, Parent = ring })
    local ringGrad = new("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.7, 1),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = ringStroke,
    })
    tween(ringGrad, TweenInfo.new(1.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Rotation = 360 })

    local logo = new("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(54, 54), BackgroundTransparency = 1, Image = LOGO,
        ScaleType = Enum.ScaleType.Fit, Parent = ring,
    })
    corner(logo, 10)
    tween(logo, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Size = UDim2.fromOffset(60, 60),
    })

    local title = new("TextLabel", {
        Position = UDim2.fromOffset(0, 118), Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack, TextSize = 20, RichText = true, Text = "", Parent = Loader,
    })
    local status = new("TextLabel", {
        Position = UDim2.fromOffset(0, 144), Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.SubText, Text = "", Parent = Loader,
    })
    local track = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 174),
        Size = UDim2.new(1, -60, 0, 4), BackgroundColor3 = WHITE, BackgroundTransparency = 0.88, Parent = Loader,
    })
    pill(track)
    local fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), Parent = track })
    pill(fill)

    bindAccent(function(c)
        LStroke.Color = c
        ringGrad.Color = ColorSequence.new(c)
        fill.BackgroundColor3 = c
        title.Text = '<font color="#FFFFFF">K0rd</font><font color="#' .. c:ToHex() .. '">Hub</font>'
    end)

    tween(LScale, EASE.Pop, { Scale = 1 })
    tween(Loader, EASE.Med, { GroupTransparency = 0 })
    task.wait(0.45)

    local steps = {
        { "Initializing...",       0.25 },
        { "Loading game modules...", 0.5 },
        { "Building interface...", 0.85 },
        { "Ready!",               1    },
    }
    for _, s in ipairs(steps) do
        if Destroyed then return end
        status.Text = s[1]
        tween(fill, TweenInfo.new(0.45, QUINT, Enum.EasingDirection.Out), { Size = UDim2.new(s[2], 0, 1, 0) })
        task.wait(0.5)
    end
    task.wait(0.15)
    if Destroyed then return end

    tween(LScale, EASE.In, { Scale = 1.12 })
    tween(Loader, EASE.In, { GroupTransparency = 1 })
    task.wait(0.3)
    if Destroyed then return end
    Loader:Destroy()

    Loaded = true
    Hub:SetOpen(true)
    task.delay(0.6, function()
        Hub:Notify("K0rdHub loaded", "Press RIGHT SHIFT to toggle · " .. (GameState and ("Team " .. (GameState.team == 3 and "CT" or "T")) or "no game state"), 4)
    end)
end
task.spawn(playIntro)

Hub.SetAccent = function(_, c) setAccent(c) end
env.K0rdHub = Hub
return Hub
