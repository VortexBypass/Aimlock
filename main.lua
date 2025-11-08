local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local TargetTeamName = "Hider"
local PlayerTeamName = "Seeker"
local AIM_SMOOTHNESS = 1
local MAX_AIM_DISTANCE = 90

getgenv().AimlockSettings = {
    AimLockEnabled = false,
    SafetyLockEnabled = false,
    PlatformSelected = false,
    CurrentTarget = nil
}

local currentNotification = nil
local messageQueue = {}
local espFolders = {}

local function createESP(targetPlayer)
    if not targetPlayer.Character then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "AimlockESP"
    highlight.FillColor = Color3.new(0, 0, 1) -- Blue color for Hiders
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = targetPlayer.Character
    
    espFolders[targetPlayer] = highlight
    
    targetPlayer.CharacterAdded:Connect(function(character)
        wait(1)
        if targetPlayer.Team and targetPlayer.Team.Name == TargetTeamName then
            local newHighlight = Instance.new("Highlight")
            newHighlight.Name = "AimlockESP"
            newHighlight.FillColor = Color3.new(0, 0, 1) -- Blue color for Hiders
            newHighlight.OutlineColor = Color3.new(1, 1, 1)
            newHighlight.FillTransparency = 0.5
            newHighlight.OutlineTransparency = 0
            newHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            newHighlight.Parent = character
            espFolders[targetPlayer] = newHighlight
        end
    end)
    
    targetPlayer.CharacterRemoving:Connect(function()
        if espFolders[targetPlayer] then
            espFolders[targetPlayer]:Destroy()
            espFolders[targetPlayer] = nil
        end
    end)
end

local function initializeESP()
    local localPlayer = Players.LocalPlayer
    local SeekerTeam = game:GetService("Teams"):FindFirstChild(PlayerTeamName)
    local HiderTeam = game:GetService("Teams"):FindFirstChild(TargetTeamName)
    
    if not SeekerTeam or not HiderTeam then
        createNotification("⚠️ Teams not configured properly\nESP may not work", Color3.new(1, 1, 0))
        return
    end
    
    localPlayer:GetPropertyChangedSignal("Team"):Connect(function()
        for player, highlight in pairs(espFolders) do
            if highlight then
                highlight:Destroy()
            end
        end
        espFolders = {}
        
        if localPlayer.Team == SeekerTeam then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer and player.Team == HiderTeam then
                    createESP(player)
                end
            end
        end
    end)
    
    if localPlayer.Team == SeekerTeam then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and player.Team == HiderTeam then
                createESP(player)
            end
        end
        
        Players.PlayerAdded:Connect(function(player)
            player:WaitForChild("Team")
            if localPlayer.Team == SeekerTeam and player.Team == HiderTeam then
                createESP(player)
            end
        end)
        
        local function onTeamChange(player, newTeam)
            if player == localPlayer then return end
            
            if localPlayer.Team == SeekerTeam and newTeam == HiderTeam then
                if not espFolders[player] then
                    createESP(player)
                end
            else
                if espFolders[player] then
                    espFolders[player]:Destroy()
                    espFolders[player] = nil
                end
            end
        end
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                player:GetPropertyChangedSignal("Team"):Connect(function()
                    onTeamChange(player, player.Team)
                end)
            end
        end
    end
end

local function createNotification(message, color)
    if currentNotification then
        table.insert(messageQueue, {message = message, color = color})
        return
    end
    
    color = color or Color3.new(1, 1, 1)
    
    local screenGui = Instance.new("ScreenGui")
    local frame = Instance.new("Frame")
    local label = Instance.new("TextLabel")
    local uICorner = Instance.new("UICorner")
    local uIStroke = Instance.new("UIStroke")
    
    screenGui.Name = "CurrentNotification"
    screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    frame.Size = UDim2.new(0, 300, 0, 60)
    frame.Position = UDim2.new(1, -320, 1, -80)
    frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    frame.BackgroundTransparency = 0.3
    frame.Parent = screenGui
    
    uICorner.CornerRadius = UDim.new(0, 8)
    uICorner.Parent = frame
    
    uIStroke.Color = color
    uIStroke.Thickness = 2
    uIStroke.Parent = frame
    
    label.Size = UDim2.new(1, -20, 1, -10)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextColor3 = color
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextWrapped = true
    label.Parent = frame
    
    local startPosition = UDim2.new(1, 100, 1, -80)
    frame.Position = startPosition
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(frame, tweenInfo, {Position = UDim2.new(1, -320, 1, -80)})
    tween:Play()
    
    currentNotification = screenGui
    
    delay(4, function()
        local fadeTween = TweenService:Create(frame, tweenInfo, {Position = startPosition})
        fadeTween:Play()
        fadeTween.Completed:Wait()
        screenGui:Destroy()
        currentNotification = nil
        
        if #messageQueue > 0 then
            local nextMsg = table.remove(messageQueue, 1)
            wait(0.5)
            createNotification(nextMsg.message, nextMsg.color)
        end
    end)
end

local function findNearestPlayerToCrosshair()
    local localPlayer = Players.LocalPlayer
    local camera = Workspace.CurrentCamera
    local localCharacter = localPlayer.Character
    if not localCharacter then return nil end

    local nearestPlayer = nil
    local shortestDistance = math.huge

    local TargetTeam = game:GetService("Teams"):FindFirstChild(TargetTeamName)
    if not TargetTeam then
        return nil
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Team == TargetTeam and player.Character then
            local head = player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")

            if head and humanoid and humanoid.Health > 0 and rootPart then
                local screenPos, onScreen = camera:WorldToScreenPoint(head.Position)
                if onScreen then
                    local distanceFromCrosshair = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)).Magnitude
                    local distanceToPlayer = (rootPart.Position - localCharacter.HumanoidRootPart.Position).Magnitude

                    if distanceFromCrosshair < shortestDistance and distanceToPlayer <= MAX_AIM_DISTANCE then
                        nearestPlayer = player
                        shortestDistance = distanceFromCrosshair
                    end
                end
            end
        end
    end
    return nearestPlayer
end

local function createPlatformSelection()
    local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local SelectionGui = Instance.new("ScreenGui")
    SelectionGui.Name = "PlatformSelection"
    SelectionGui.ResetOnSpawn = false
    SelectionGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    SelectionGui.Parent = PlayerGui
    
    local Background = Instance.new("Frame")
    Background.Size = UDim2.new(0, 350, 0, 250)
    Background.Position = UDim2.new(0.5, -175, 0.5, -125)
    Background.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    Background.BackgroundTransparency = 0.1
    Background.Parent = SelectionGui
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = Background
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.new(1, 1, 1)
    UIStroke.Thickness = 2
    UIStroke.Parent = Background
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 50)
    Title.Position = UDim2.new(0, 0, 0, 10)
    Title.BackgroundTransparency = 1
    Title.Text = "Select Your Platform"
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.TextSize = 24
    Title.Font = Enum.Font.GothamBold
    Title.Parent = Background
    
    local PCButton = Instance.new("TextButton")
    PCButton.Size = UDim2.new(0, 300, 0, 50)
    PCButton.Position = UDim2.new(0.5, -150, 0.3, 0)
    PCButton.BackgroundColor3 = Color3.new(0.2, 0.4, 0.8)
    PCButton.Text = "🖥️ PC"
    PCButton.TextColor3 = Color3.new(1, 1, 1)
    PCButton.TextSize = 20
    PCButton.Font = Enum.Font.GothamBold
    PCButton.Parent = Background
    
    local MobileButton = Instance.new("TextButton")
    MobileButton.Size = UDim2.new(0, 300, 0, 50)
    MobileButton.Position = UDim2.new(0.5, -150, 0.5, 0)
    MobileButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.4)
    MobileButton.Text = "📱 Mobile"
    MobileButton.TextColor3 = Color3.new(1, 1, 1)
    MobileButton.TextSize = 20
    MobileButton.Font = Enum.Font.GothamBold
    MobileButton.Parent = Background
    
    local ControllerButton = Instance.new("TextButton")
    ControllerButton.Size = UDim2.new(0, 300, 0, 50)
    ControllerButton.Position = UDim2.new(0.5, -150, 0.7, 0)
    ControllerButton.BackgroundColor3 = Color3.new(0.8, 0.4, 0.2)
    ControllerButton.Text = "🎮 Controller"
    ControllerButton.TextColor3 = Color3.new(1, 1, 1)
    ControllerButton.TextSize = 20
    ControllerButton.Font = Enum.Font.GothamBold
    ControllerButton.Parent = Background
    
    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 8)
    ButtonCorner.Parent = PCButton
    ButtonCorner:Clone().Parent = MobileButton
    ButtonCorner:Clone().Parent = ControllerButton
    
    PCButton.MouseButton1Click:Connect(function()
        SelectionGui:Destroy()
        AimlockSettings.PlatformSelected = true
        getgenv().AimlockCreateNotification = createNotification
        getgenv().AimlockFindNearestPlayer = findNearestPlayerToCrosshair
        loadstring(game:HttpGet("https://raw.githubusercontent.com/VortexBypass/Aimlock/refs/heads/main/pc.lua"))()
    end)
    
    MobileButton.MouseButton1Click:Connect(function()
        SelectionGui:Destroy()
        AimlockSettings.PlatformSelected = true
        getgenv().AimlockCreateNotification = createNotification
        getgenv().AimlockFindNearestPlayer = findNearestPlayerToCrosshair
        loadstring(game:HttpGet("https://raw.githubusercontent.com/VortexBypass/Aimlock/refs/heads/main/mobile.lua"))()
    end)
    
    ControllerButton.MouseButton1Click:Connect(function()
        SelectionGui:Destroy()
        AimlockSettings.PlatformSelected = true
        getgenv().AimlockCreateNotification = createNotification
        getgenv().AimlockFindNearestPlayer = findNearestPlayerToCrosshair
        loadstring(game:HttpGet("https://raw.githubusercontent.com/VortexBypass/Aimlock/refs/heads/main/controller.lua"))()
    end)
    
    return SelectionGui
end

RunService.Heartbeat:Connect(function()
    if AimlockSettings.PlatformSelected and AimlockSettings.AimLockEnabled and not AimlockSettings.SafetyLockEnabled then
        if AimlockSettings.CurrentTarget and AimlockSettings.CurrentTarget.Character and AimlockSettings.CurrentTarget.Character:FindFirstChild("Head") then
            local camera = Workspace.CurrentCamera
            local targetHead = AimlockSettings.CurrentTarget.Character.Head
            local currentCFrame = camera.CFrame
            local targetCFrame = CFrame.new(currentCFrame.Position, targetHead.Position)
            camera.CFrame = currentCFrame:Lerp(targetCFrame, AIM_SMOOTHNESS)
        else
            if AimlockSettings.AimLockEnabled then
                AimlockSettings.AimLockEnabled = false
                AimlockSettings.CurrentTarget = nil
                createNotification("🎯 TARGET LOST\nAimlock disabled", Color3.new(1, 0.5, 0))
            end
        end
    end
end)

spawn(function()
    wait(1)
    createPlatformSelection()
    initializeESP()
    
    wait(6)
    local TargetTeam = game:GetService("Teams"):FindFirstChild(TargetTeamName)
    local PlayerTeam = game:GetService("Teams"):FindFirstChild(PlayerTeamName)
    if not TargetTeam then
        createNotification("⚠️ HIDER Team not found\nScript may not work", Color3.new(1, 1, 0))
    end
    if not PlayerTeam then
        createNotification("⚠️ SEEKER Team not found\nScript may not work", Color3.new(1, 1, 0))
    end
end)

print("Aimlock Platform Selection loaded - Select your platform")
