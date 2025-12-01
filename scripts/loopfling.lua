local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

getgenv().FPDH = workspace.FallenPartsDestroyHeight

local LoopFlingGUI = Instance.new("ScreenGui")
LoopFlingGUI.Name = "LoopFlingGUI"
LoopFlingGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
LoopFlingGUI.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 250)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -125)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "LOOP FLING GUI"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16

local UICorner2 = Instance.new("UICorner")
UICorner2.CornerRadius = UDim.new(0, 8)
UICorner2.Parent = Title

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 25, 0, 25)
CloseButton.Position = UDim2.new(1, -30, 0, 8)
CloseButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Text = "X"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 14

local UICorner3 = Instance.new("UICorner")
UICorner3.CornerRadius = UDim.new(0, 4)
UICorner3.Parent = CloseButton

local PlayerInput = Instance.new("TextBox")
PlayerInput.Size = UDim2.new(0.8, 0, 0, 35)
PlayerInput.Position = UDim2.new(0.1, 0, 0.2, 0)
PlayerInput.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
PlayerInput.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerInput.PlaceholderText = "Enter player name (all, others, random, or name)"
PlayerInput.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
PlayerInput.Font = Enum.Font.Gotham
PlayerInput.TextSize = 12
PlayerInput.Text = ""
PlayerInput.ClearTextOnFocus = false

local UICorner4 = Instance.new("UICorner")
UICorner4.CornerRadius = UDim.new(0, 4)
UICorner4.Parent = PlayerInput

local ExamplesLabel = Instance.new("TextLabel")
ExamplesLabel.Size = UDim2.new(0.8, 0, 0, 20)
ExamplesLabel.Position = UDim2.new(0.1, 0, 0.38, 0)
ExamplesLabel.BackgroundTransparency = 1
ExamplesLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
ExamplesLabel.Text = "Examples: all, others, random, PlayerName"
ExamplesLabel.Font = Enum.Font.Gotham
ExamplesLabel.TextSize = 10
ExamplesLabel.TextXAlignment = Enum.TextXAlignment.Left

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0.6, 0, 0, 45)
ToggleButton.Position = UDim2.new(0.2, 0, 0.55, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(70, 140, 200)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Text = "START LOOP FLING"
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 16

local UICorner5 = Instance.new("UICorner")
UICorner5.CornerRadius = UDim.new(0, 6)
UICorner5.Parent = ToggleButton

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 25)
StatusLabel.Position = UDim2.new(0, 0, 0.8, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.Text = "Status: Inactive"
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 14

CloseButton.Parent = Title
Title.Parent = MainFrame
PlayerInput.Parent = MainFrame
ExamplesLabel.Parent = MainFrame
ToggleButton.Parent = MainFrame
StatusLabel.Parent = MainFrame
MainFrame.Parent = LoopFlingGUI
LoopFlingGUI.Parent = PlayerGui

local isActive = false
local flingLoop = nil
local respawnConnection = nil

local function GetPlayer(Name)
    Name = Name:lower()
    local AllBool = false
    
    if Name == "all" or Name == "others" then
        AllBool = true
        return nil, AllBool
    elseif Name == "random" then
        local GetPlayers = Players:GetPlayers()
        if table.find(GetPlayers, Player) then 
            table.remove(GetPlayers, table.find(GetPlayers, Player)) 
        end
        return GetPlayers[math.random(#GetPlayers)], AllBool
    elseif Name ~= "random" and Name ~= "all" and Name ~= "others" then
        for _, x in next, Players:GetPlayers() do
            if x ~= Player then
                if x.Name:lower():match("^"..Name) then
                    return x, AllBool
                elseif x.DisplayName:lower():match("^"..Name) then
                    return x, AllBool
                end
            end
        end
    else
        return nil, AllBool
    end
end

local function IsTargetValid(TargetPlayer)
    if not TargetPlayer then return false end
    if not TargetPlayer.Character then return false end
    
    local TCharacter = TargetPlayer.Character
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    
    if not THumanoid then return false end
    if THumanoid.Health <= 0 then return false end
    
    return true
end

local function CleanupFling()
    workspace.FallenPartsDestroyHeight = getgenv().FPDH
    
    local Character = Player.Character
    if Character then
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        local RootPart = Humanoid and Humanoid.RootPart
        
        if RootPart then
            local BV = RootPart:FindFirstChild("EpixVel")
            if BV then
                BV:Destroy()
            end
        end
        
        if Humanoid then
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
            workspace.CurrentCamera.CameraSubject = Humanoid
        end
    end
end

local function SkidFling(TargetPlayer)
    if not IsTargetValid(TargetPlayer) then return end
    
    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart

    local TCharacter = TargetPlayer.Character
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")

    if Character and Humanoid and RootPart then
        if RootPart.Velocity.Magnitude < 50 then
            getgenv().OldPos = RootPart.CFrame
        end
        
        if THumanoid and THumanoid.Sit then
            return
        end
        
        if THead then
            workspace.CurrentCamera.CameraSubject = THead
        elseif not THead and Handle then
            workspace.CurrentCamera.CameraSubject = Handle
        elseif THumanoid and TRootPart then
            workspace.CurrentCamera.CameraSubject = THumanoid
        end
        
        if not TCharacter:FindFirstChildWhichIsA("BasePart") then
            return
        end
        
        local FPos = function(BasePart, Pos, Ang)
            if not isActive then return end
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end
        
        local SFBasePart = function(BasePart)
            local TimeToWait = 2
            local Time = tick()
            local Angle = 0

            repeat
                if RootPart and THumanoid and isActive then
                    if BasePart.Velocity.Magnitude < 50 then
                        Angle = Angle + 100

                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    else
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        
                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5 ,0), CFrame.Angles(math.rad(-90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                    end
                else
                    break
                end
            until not isActive or BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or not TargetPlayer.Character == TCharacter or (THumanoid and THumanoid.Sit) or Humanoid.Health <= 0 or tick() > Time + TimeToWait
        end
        
        workspace.FallenPartsDestroyHeight = 0/0
        
        local BV = Instance.new("BodyVelocity")
        BV.Name = "EpixVel"
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
        BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
        
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        
        if TRootPart and THead then
            if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
                SFBasePart(THead)
            else
                SFBasePart(TRootPart)
            end
        elseif TRootPart and not THead then
            SFBasePart(TRootPart)
        elseif not TRootPart and THead then
            SFBasePart(THead)
        elseif not TRootPart and not THead and Accessory and Handle then
            SFBasePart(Handle)
        else
            return
        end
        
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = Humanoid
        
        if getgenv().OldPos then
            repeat
                if RootPart and isActive then
                    RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                    Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                    Humanoid:ChangeState("GettingUp")
                    for _, x in pairs(Character:GetChildren()) do
                        if x:IsA("BasePart") then
                            x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
                        end
                    end
                    task.wait()
                end
            until not isActive or not RootPart or not getgenv().OldPos or (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
        end
        
        workspace.FallenPartsDestroyHeight = getgenv().FPDH
    end
end

local function StartLoopFling()
    local targetName = PlayerInput.Text
    if targetName == "" then
        return
    end
    
    isActive = true
    ToggleButton.Text = "STOP LOOP FLING"
    ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
    StatusLabel.Text = "Status: Active - Target: " .. targetName
    
    if not getgenv().Welcome then 
        getgenv().Welcome = true
    end
    
    flingLoop = coroutine.create(function()
        while isActive do
            local TargetPlayer, AllBool = GetPlayer(targetName)
            
            if AllBool then
                for _, x in next, Players:GetPlayers() do
                    if isActive and IsTargetValid(x) then
                        SkidFling(x)
                    end
                    if isActive then
                        task.wait(0.1)
                    end
                end
            elseif TargetPlayer and TargetPlayer ~= Player then
                if TargetPlayer.UserId ~= 1414978355 and IsTargetValid(TargetPlayer) then
                    SkidFling(TargetPlayer)
                end
            end
            
            if isActive then
                task.wait(0.1)
            end
        end
    end)
    
    coroutine.resume(flingLoop)
end

local function StopLoopFling()
    isActive = false
    ToggleButton.Text = "START LOOP FLING"
    ToggleButton.BackgroundColor3 = Color3.fromRGB(70, 140, 200)
    StatusLabel.Text = "Status: Inactive"
    
    CleanupFling()
end

ToggleButton.MouseButton1Click:Connect(function()
    if isActive then
        StopLoopFling()
    else
        StartLoopFling()
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    StopLoopFling()
    LoopFlingGUI:Destroy()
end)

respawnConnection = Player.CharacterAdded:Connect(function()
    if isActive then
        task.wait(2)
        if isActive then
            StartLoopFling()
        end
    end
end)
