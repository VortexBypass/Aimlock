-- Mobile Platform Logic for Aimlock
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Mobile floating button only
local function createMobileGUI()
    local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local MobileGui = Instance.new("ScreenGui")
    MobileGui.Name = "MobileAimlockGUI"
    MobileGui.ResetOnSpawn = false
    MobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    MobileGui.Parent = PlayerGui
    
    -- Floating Button Only
    local FloatingButton = Instance.new("TextButton")
    FloatingButton.Name = "FloatingButton"
    FloatingButton.Size = UDim2.new(0, 80, 0, 80)
    FloatingButton.Position = UDim2.new(0.8, 0, 0.7, 0)
    FloatingButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    FloatingButton.BackgroundTransparency = 0.3
    FloatingButton.Text = "AIM\nOFF"
    FloatingButton.TextColor3 = Color3.new(1, 1, 1)
    FloatingButton.TextSize = 14
    FloatingButton.Font = Enum.Font.GothamBold
    FloatingButton.TextWrapped = true
    FloatingButton.Parent = MobileGui
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 40)
    UICorner.Parent = FloatingButton
    
    -- Dragging functionality
    local dragging = false
    local dragInput, dragStart, startPos
    
    FloatingButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = FloatingButton.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    FloatingButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            FloatingButton.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X,
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Button functionality
    FloatingButton.MouseButton1Click:Connect(function()
        if not Settings.SafetyLockEnabled then
            Settings.AimLockEnabled = not Settings.AimLockEnabled
            if Settings.AimLockEnabled then
                local target = findNearestPlayerToCrosshair()
                if target then
                    createNotification("🎯 AIMLOCK: ON\nTargeting Hider: " .. target.Name, Color3.new(0, 1, 0))
                    FloatingButton.Text = "AIM\nON"
                    FloatingButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
                else
                    createNotification("🎯 AIMLOCK ON\nNo Hiders found in range", Color3.new(1, 1, 0))
                    Settings.AimLockEnabled = false
                end
            else
                createNotification("🎯 AIMLOCK: OFF", Color3.new(1, 0, 0))
                FloatingButton.Text = "AIM\nOFF"
                FloatingButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
            end
        else
            createNotification("❌ Cannot toggle aimlock\nSafety Lock is active", Color3.new(1, 0.5, 0))
        end
    end)
    
    return MobileGui
end

-- Initialize mobile GUI
if UserInputService.TouchEnabled then
    spawn(function()
        wait(1)
        createMobileGUI()
        createNotification("📱 MOBILE DETECTED\nUse floating button for aimlock", Color3.new(0, 1, 1))
    end)
end
