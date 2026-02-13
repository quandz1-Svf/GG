-- auto trang bi voi
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer


local TARGET_NAME = "Strawberry Elephant"
local TARGET_MUTATION = "Money"
local MAX_LEVEL = 150
local CHECK_DELAY = 1


local AutoEquipEnabled = false
local CurrentTool = nil


local gui = Instance.new("ScreenGui")
gui.Name = "AutoEquipElephantUI"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(260, 120)
frame.Position = UDim2.fromScale(0.02, 0.35)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundTransparency = 1
title.Text = "🐘 Auto Equip Elephant"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(255, 200, 120)

local toggle = Instance.new("TextButton", frame)
toggle.Size = UDim2.fromOffset(200, 40)
toggle.Position = UDim2.fromOffset(30, 60)
toggle.Text = "STATUS: OFF"
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 14
toggle.TextColor3 = Color3.new(1,1,1)
toggle.BackgroundColor3 = Color3.fromRGB(90, 30, 30)
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 8)


toggle.MouseButton1Click:Connect(function()
	AutoEquipEnabled = not AutoEquipEnabled

	if AutoEquipEnabled then
		toggle.Text = "STATUS: ON"
		toggle.BackgroundColor3 = Color3.fromRGB(30, 120, 60)
	else
		toggle.Text = "STATUS: OFF"
		toggle.BackgroundColor3 = Color3.fromRGB(90, 30, 30)
		CurrentTool = nil
	end
end)


local function isValidPet(tool)
	if not tool or not tool:IsA("Tool") then return false end
	if tool:GetAttribute("BrainrotName") ~= TARGET_NAME then return false end
	if tool:GetAttribute("Mutation") ~= TARGET_MUTATION then return false end

	local lv = tool:GetAttribute("Level")
	if type(lv) ~= "number" then return false end
	if lv >= MAX_LEVEL then return false end

	return true
end

local function getEquippedPet()
	local char = LocalPlayer.Character
	if not char then return nil end

	for _, tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") then
			return tool
		end
	end
	return nil
end

local function findPetInBackpack()
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if not backpack then return nil end

	for _, tool in ipairs(backpack:GetChildren()) do
		if isValidPet(tool) then
			return tool
		end
	end
	return nil
end


task.spawn(function()
	while true do
		task.wait(CHECK_DELAY)

		if not AutoEquipEnabled then
			continue
		end

		local char = LocalPlayer.Character
		if not char then
			CurrentTool = nil
			continue
		end

		
		local equipped = getEquippedPet()
		if equipped then
			if isValidPet(equipped) then
				-- vẫn hợp lệ → giữ
				CurrentTool = equipped
				continue
			else
				
				pcall(function()
					equipped.Parent = LocalPlayer.Backpack
				end)
				CurrentTool = nil
			end
		end

		
		local newPet = findPetInBackpack()
		if newPet then
			pcall(function()
				char.Humanoid:EquipTool(newPet)
				CurrentTool = newPet
			end)
		else
		
			CurrentTool = nil
		end
	end
end)