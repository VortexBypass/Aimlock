local UserInputService = game:GetService("UserInputService")

local PC_AIM_LOCK_KEY = Enum.KeyCode.E
local PC_SAFETY_LOCK_KEY = Enum.KeyCode.Q
local lastQClick = 0
local DOUBLE_CLICK_TIME = 0.5

if AimlockSettings then
    AimlockCreateCrosshair()
    AimlockCreateNotification("🖥️ PC CONTROLS LOADED\n• E: Toggle Aimlock\n• Double Q: Safety Lock", Color3.new(0, 1, 1))
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == PC_AIM_LOCK_KEY then
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
            AimlockCreateNotification("❌ E KEY BLOCKED\nSafety Lock is active\nDouble-click Q to disable", Color3.new(1, 0.5, 0))
        end
    end
    
    if input.KeyCode == PC_SAFETY_LOCK_KEY then
        local currentTime = tick()
        if currentTime - lastQClick <= DOUBLE_CLICK_TIME then
            AimlockSettings.SafetyLockEnabled = not AimlockSettings.SafetyLockEnabled
            
            if AimlockSettings.SafetyLockEnabled then
                AimlockCreateNotification("🔒 SAFETY LOCK ENABLED\nE key is now disabled\nAimlock: FORCED OFF", Color3.new(1, 0.5, 0))
                if AimlockSettings.AimLockEnabled then
                    AimlockSettings.AimLockEnabled = false
                end
            else
                AimlockCreateNotification("🔓 SAFETY LOCK DISABLED\nE key is now enabled", Color3.new(0, 1, 0))
            end
        end
        lastQClick = currentTime
    end
end)
