local UserInputService = game:GetService("UserInputService")

local AIM_LOCK_TOGGLE_KEY = Enum.KeyCode.ButtonL2
local SAFETY_LOCK_KEY = Enum.KeyCode.ButtonX
local lastSquareClick = 0
local DOUBLE_CLICK_TIME = 0.5

if AimlockSettings then
    AimlockCreateCrosshair()
    AimlockCreateNotification("🎮 CONTROLLER CONTROLS LOADED\n• L2: Toggle Aimlock\n• Double Square: Safety Lock", Color3.new(0, 1, 1))
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == SAFETY_LOCK_KEY then
        local currentTime = tick()
        if currentTime - lastSquareClick <= DOUBLE_CLICK_TIME then
            AimlockSettings.SafetyLockEnabled = not AimlockSettings.SafetyLockEnabled
            
            if AimlockSettings.SafetyLockEnabled then
                AimlockCreateNotification("🔒 SAFETY LOCK ENABLED\nL2 is now disabled\nAimlock: FORCED OFF", Color3.new(1, 0.5, 0))
                if AimlockSettings.AimLockEnabled then
                    AimlockSettings.AimLockEnabled = false
                end
            else
                AimlockCreateNotification("🔓 SAFETY LOCK DISABLED\nL2 is now enabled", Color3.new(0, 1, 0))
            end
        end
        lastSquareClick = currentTime
    end
    
    if input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == AIM_LOCK_TOGGLE_KEY then
        if not gameProcessed and not AimlockSettings.SafetyLockEnabled then
            AimlockSettings.AimLockEnabled = not AimlockSettings.AimLockEnabled
            
            if AimlockSettings.AimLockEnabled then
                local target = AimlockFindNearestPlayer()
                if target then
                    AimlockCreateNotification("🎯 AIMLOCK: ON\nTargeting Hider: " .. target.Name, Color3.new(0, 1, 0))
                else
                    AimlockCreateNotification("🎯 AIMLOCK ON\nNo Hiders found in range", Color3.new(1, 1, 0))
                    AimlockSettings.AimLockEnabled = false
                end
            else
                AimlockCreateNotification("🎯 AIMLOCK: OFF", Color3.new(1, 0, 0))
            end
        elseif AimlockSettings.SafetyLockEnabled then
            AimlockCreateNotification("❌ L2 BLOCKED\nSafety Lock is active\nDouble-click Square to disable", Color3.new(1, 0.5, 0))
        end
    end
end)
