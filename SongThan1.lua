-- auto trade all mutation
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local TradeRemote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RF/Trade.SendGift")

local MIN_LEVEL = 150
local TRADE_DELAY = 10
local TradeEnabled, IsTrading = false, false
local TargetPlayer, SelectedPetName = nil, nil
local CooldownTime = 0

local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "RGB_Mobile_Pro_V5"
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
TitleBar.Text = " Bố Mày Là Số 1 "
TitleBar.Font = Enum.Font.GothamBold
TitleBar.TextSize = 14
TitleBar.TextColor3 = Color3.new(1, 1, 1)
TitleBar.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

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
    
    if IsTrading then
        timerLbl.Text = "TRADING..."
        timerLbl.TextColor3 = Color3.new(1, 1, 0)
    elseif CooldownTime > 0 then
        timerLbl.Text = string.format("WAIT: %.1fs", CooldownTime)
        timerLbl.TextColor3 = Color3.new(1, 0.4, 0.4)
    else
        timerLbl.Text = "READY!"
        timerLbl.TextColor3 = Color3.new(0.4, 1, 0.4)
    end
end)

local function updatePetList()
    local pets = {}
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        local lvl = tonumber(tool:GetAttribute("Level")) or 0
        if tool:IsA("Tool") and lvl >= MIN_LEVEL then
            local name = tool:GetAttribute("BrainrotName") or tool.Name
            pets[name] = (pets[name] or 0) + 1
        end
    end
    for _, v in ipairs(PetSide:GetChildren()) do
        if v:IsA("TextButton") then v:Destroy() end
    end
    for name, count in pairs(pets) do
        local b = Instance.new("TextButton", PetSide)
        b.Size = UDim2.new(0.95, 0, 0, 35)
        b.BackgroundColor3 = Color3.fromRGB(30,30,30)
        b.BorderSizePixel = 0
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)

        local n = Instance.new("TextLabel", b)
        n.Size = UDim2.new(0.6, 0, 1, 0)
        n.Position = UDim2.fromOffset(8, 0)
        n.Text = name
        n.TextColor3 = Color3.new(1, 1, 1)
        n.BackgroundTransparency = 1
        n.TextXAlignment = Enum.TextXAlignment.Left
        n.Font = Enum.Font.Gotham
        n.TextSize = 10

        local c = Instance.new("TextLabel", b)
        c.Size = UDim2.new(0.3, 0, 1, 0)
        c.Position = UDim2.fromScale(0.65, 0)
        c.Text = "x"..count
        c.TextColor3 = Color3.new(0.4, 1, 0.4)
        c.BackgroundTransparency = 1
        c.Font = Enum.Font.GothamBold
        c.TextSize = 11
    end
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if not TradeEnabled or IsTrading or CooldownTime > 0 or not TargetPlayer then continue end
        
        local targetPet = nil
        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
            local lvl = tonumber(tool:GetAttribute("Level")) or 0
            if tool:IsA("Tool") and lvl >= MIN_LEVEL then
                targetPet = tool
                break
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

floatBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

toggleBtn.MouseButton1Click:Connect(function()
    TradeEnabled = not TradeEnabled
    toggleBtn.Text = TradeEnabled and "STATUS: ON" or "STATUS: OFF"
    toggleBtn.BackgroundColor3 = TradeEnabled and Color3.fromRGB(30, 80, 30) or Color3.fromRGB(80, 30, 30)
    BtnStroke.Enabled = TradeEnabled
end)