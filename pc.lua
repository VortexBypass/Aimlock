-- PC Platform Logic for Aimlock
local UserInputService = game:GetService("UserInputService")

-- PC Configuration
local PC_AIM_LOCK_KEY = Enum.KeyCode.E
local PC_SAFETY_LOCK_KEY = Enum.KeyCode.Q

-- Double click detection for PC
local lastQClick = 0
local DOUBLE_CLICK_TIME = 0.5

-- PC Input Handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- PC: E key for aimlock
    if input.KeyCode == PC_AIM_LOCK_KEY then
        if not gameProcessed and not Settings.SafetyLockEnabled then
            Settings.AimLockEnabled = not Settings.AimLockEnabled
            
            if Settings.AimLockEnabled then
                local target = findNearestPlayerToCrosshair()
                if target then
                    createNotification("🎯 AIMLOCK: ON\nTargeting Hider: " .. target.Name, Color3.new(0, 1, 0))
                else
                    createNotification("🎯 AIMLOCK ON\nNo Hiders found in range", Color3.new(1, 1, 0))
                    Settings.AimLockEnabled = false
                end
            else
                createNotification("🎯 AIMLOCK: OFF", Color3.new(1, 0, 0))
            end
        elseif Settings.SafetyLockEnabled then
            createNotification("❌ E KEY BLOCKED\nSafety Lock is active\nDouble-click Q to disable", Color3.new(1, 0.5, 0))
        end
    end
    
    -- PC: Double Q for safety lock
    if input.KeyCode == PC_SAFETY_LOCK_KEY then
        local currentTime = tick()
        if currentTime - lastQClick <= DOUBLE_CLICK_TIME then
            -- Double click detected
            Settings.SafetyLockEnabled = not Settings.SafetyLockEnabled
            
            if Settings.SafetyLockEnabled then
                createNotification("🔒 SAFETY LOCK ENABLED\nE key is now disabled\nAimlock: FORCED OFF", Color3.new(1, 0.5, 0))
                if Settings.AimLockEnabled then
                    Settings.AimLockEnabled = false
                end
            else
                createNotification("🔓 SAFETY LOCK DISABLED\nE key is now enabled", Color3.new(0, 1, 0))
            end
        end
        lastQClick = currentTime
    end
end)

-- Initialize PC notifications
if UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled then
    spawn(function()
        wait(1)
        createNotification("🖥️ PC CONTROLS DETECTED\n• E: Toggle Aimlock\n• Double Q: Safety Lock", Color3.new(0, 1, 1))
    end)
end
