if getgenv()._JADE_ADMIN_LOADED then return end
getgenv()._JADE_ADMIN_LOADED = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local function safe_pcall(f, ...)
    local ok, res = pcall(f, ...)
    if not ok then
        warn("[Jade Admin] Error:", res)
    end
    return ok, res
end

local function getGuiParent()
    if typeof(gethui) == "function" then
        local ok, ui = pcall(gethui)
        if ok and typeof(ui) == "Instance" then
            return ui
        end
    end
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
        return LocalPlayer.PlayerGui
    end
    if game.CoreGui then
        return game.CoreGui
    end
    return game:GetService("StarterGui")
end

local state = {
    flingActive = false,
    player = nil,
    character = nil,
    humanoidRootPart = nil,
    connections = {},
    charConnections = {},
    blackHoleActive = false,
    folder = nil,
    part = nil,
    att1 = nil,
    chatConnection = nil,
    playerRemovingConnection = nil,
    autoBringConn = nil,
    fly = {
        enabled = false,
        speed = 100,
        bv = nil,
        bg = nil,
        inputBegan = nil,
        inputEnded = nil,
        renderConn = nil,
        charConn = nil,
        keys = {},
        toggleKeyConn = nil,
        mobileGui = nil,
        mobileButton = nil,
        mobileButtonConn = nil,
    },
    noclip = {
        enabled = false,
        conn = nil,
    },
    infiniteJump = {
        enabled = false,
        power = 100,
        conn = nil,
        origJumpPower = nil,
        charConn = nil,
    },
    walkSpeed = nil,
    jumpPower = nil,
}

local function disconnectAll()
    for _, conn in pairs(state.connections) do
        if typeof(conn) == "RBXScriptConnection" then
            safe_pcall(function() conn:Disconnect() end)
        end
    end
    state.connections = {}
end

local function disconnectCharConnections()
    for _, conn in pairs(state.charConnections) do
        if typeof(conn) == "RBXScriptConnection" then
            safe_pcall(function() conn:Disconnect() end)
        end
    end
    state.charConnections = {}
end

local function cleanupFolderAndPart()
    if state.folder then safe_pcall(function() state.folder:Destroy() end) end
    state.folder = nil
    state.part = nil
    state.att1 = nil
end

local function setupFolderAndPart()
    cleanupFolderAndPart()
    local Folder = Instance.new("Folder")
    Folder.Name = "PartsFling_Folder"
    Folder.Parent = Workspace
    local Part = Instance.new("Part")
    Part.Name = "PartsFling_AlignPart"
    Part.Anchored = true
    Part.CanCollide = false
    Part.Transparency = 1
    Part.Size = Vector3.new(1,1,1)
    Part.Parent = Folder
    local Attachment1 = Instance.new("Attachment")
    Attachment1.Name = "PartsFling_Attachment"
    Attachment1.Parent = Part
    state.folder = Folder
    state.part = Part
    state.att1 = Attachment1
end

setupFolderAndPart()

if not getgenv().Network then
    getgenv().Network = {
        BaseParts = {},
        Velocity = Vector3.new(14.46262424, 14.46262424, 14.46262424)
    }
    getgenv().Network.RetainPart = function(Part)
        if Part:IsA("BasePart") and Part:IsDescendantOf(Workspace) then
            table.insert(getgenv().Network.BaseParts, Part)
            Part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            Part.CanCollide = false
        end
    end
    local function EnablePartControl()
        if LocalPlayer then
            LocalPlayer.ReplicationFocus = Workspace
        end
        RunService.Heartbeat:Connect(function()
            safe_pcall(function()
                if sethiddenproperty and LocalPlayer then
                    sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
                end
                for _, Part in pairs(getgenv().Network.BaseParts) do
                    if Part:IsDescendantOf(Workspace) then
                        Part.Velocity = getgenv().Network.Velocity
                    end
                end
            end)
        end)
    end
    EnablePartControl()
end

local function isSafeTargetPart(v)
    if not v:IsA("BasePart") then return false end
    if v.Anchored then return false end
    if v.Parent and (
        v.Parent:FindFirstChildOfClass("Humanoid") or
        v.Parent:FindFirstChild("Head") or
        v.Name == "Handle" or
        v.Parent:IsA("Tool") or
        v.Parent:IsA("Accessory") or
        (v.Parent:IsA("Model") and v.Parent:FindFirstChildOfClass("Humanoid"))
    ) then
        return false
    end
    if v:IsDescendantOf(Workspace.Terrain) then return false end
    if state.folder and v:IsDescendantOf(state.folder) then return false end
    return true
end

local function ForcePart(v)
    if not isSafeTargetPart(v) then return end
    safe_pcall(function()
        for _, x in ipairs(v:GetChildren()) do
            if x:IsA("BodyMover") or x:IsA("RocketPropulsion") then
                x:Destroy()
            end
        end
        for _, n in ipairs({"Attachment", "AlignPosition", "Torque"}) do
            local c = v:FindFirstChild(n)
            if c then c:Destroy() end
        end
        v.CanCollide = false
        local Torque = Instance.new("Torque", v)
        Torque.Torque = Vector3.new(100000, 100000, 100000)
        local AlignPosition = Instance.new("AlignPosition", v)
        local Attachment2 = Instance.new("Attachment", v)
        Torque.Attachment0 = Attachment2
        AlignPosition.MaxForce = math.huge
        AlignPosition.MaxVelocity = math.huge
        AlignPosition.Responsiveness = 200
        AlignPosition.Attachment0 = Attachment2
        AlignPosition.Attachment1 = state.att1
    end)
end

local function trim(s)
    return (tostring(s or ""):match("^%s*(.-)%s*$") or "")
end

local function getPlayer(name)
    name = trim(name)
    if name == "" then return nil end
    local lowerName = string.lower(name)
    local players = Players:GetPlayers()
    for _, p in ipairs(players) do
        if string.lower(p.Name or "") == lowerName then
            return p
        end
    end
    for _, p in ipairs(players) do
        local d = p.DisplayName or ""
        if d ~= "" and string.lower(d) == lowerName then
            return p
        end
    end
    for _, p in ipairs(players) do
        if string.find(string.lower(p.Name or ""), lowerName, 1, true) == 1 then
            return p
        end
    end
    for _, p in ipairs(players) do
        local d = p.DisplayName or ""
        if d ~= "" and string.find(string.lower(d), lowerName, 1, true) == 1 then
            return p
        end
    end
    for _, p in ipairs(players) do
        if string.find(string.lower(p.Name or ""), lowerName, 1, true) then
            return p
        end
    end
    for _, p in ipairs(players) do
        local d = p.DisplayName or ""
        if d ~= "" and string.find(string.lower(d), lowerName, 1, true) then
            return p
        end
    end
    return nil
end

local function setStatus(txt, ok)
    if ok then
        print("[Jade Admin] " .. (txt or ""))
    else
        warn("[Jade Admin] " .. (txt or ""))
    end
end

local function findAnyCharacterPart(char)
    if not char then return nil end
    local candidates = { "HumanoidRootPart", "LowerTorso", "Torso", "UpperTorso", "Head" }
    for _, name in ipairs(candidates) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then return p end
    end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") then
            return d
        end
    end
    return nil
end

local function applyWalkJumpToChar(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if state.walkSpeed then
            safe_pcall(function() hum.WalkSpeed = state.walkSpeed end)
        end
        if state.jumpPower then
            safe_pcall(function() hum.JumpPower = state.jumpPower end)
        end
    end
end

local function clearCharacterState()
    state.humanoidRootPart = nil
    state.character = nil
    disconnectCharConnections()
end

local function attachToCharacter(char)
    if not char or not char:IsA("Model") then return end
    disconnectCharConnections()
    state.character = char
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        local ok, res = pcall(function()
            return char:WaitForChild("HumanoidRootPart", 2)
        end)
        hrp = ok and res or nil
    end
    if hrp and hrp:IsA("BasePart") then
        state.humanoidRootPart = hrp
    else
        state.humanoidRootPart = findAnyCharacterPart(char)
    end
    applyWalkJumpToChar(char)
    if state.blackHoleActive then
        setStatus("Attached to " .. (state.player and state.player.Name or "target") .. "'s character.", true)
    end
    local descAddedConn = char.DescendantAdded:Connect(function(desc)
        if not state.character then return end
        if desc and desc:IsA("BasePart") then
            if desc.Name == "HumanoidRootPart" then
                state.humanoidRootPart = desc
                setStatus("HumanoidRootPart detected.", true)
            elseif not state.humanoidRootPart then
                state.humanoidRootPart = desc
                setStatus("Found new body part to attach.", true)
            end
        end
    end)
    table.insert(state.charConnections, descAddedConn)
    local childRemovedConn = char.ChildRemoved:Connect(function(child)
        if child == state.humanoidRootPart then
            local fallback = findAnyCharacterPart(char)
            state.humanoidRootPart = fallback
            if fallback then
                setStatus("HumanoidRootPart removed — switched to fallback.", true)
            else
                setStatus("HumanoidRootPart removed — waiting for new parts.", false)
            end
        end
    end)
    table.insert(state.charConnections, childRemovedConn)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum:IsA("Humanoid") then
        local diedConn = hum.Died:Connect(function()
            setStatus("Target died — searching for new body part.", true)
            delay(0.15, function()
                local fallback = findAnyCharacterPart(char)
                state.humanoidRootPart = fallback
            end)
        end)
        table.insert(state.charConnections, diedConn)
    else
        local humAdded = char.ChildAdded:Connect(function(child)
            if child and child:IsA("Humanoid") and not child.Parent == nil then
                local diedConn2 = child.Died:Connect(function()
                    setStatus("Target died — searching for new body part.", true)
                    delay(0.15, function()
                        local fallback = findAnyCharacterPart(char)
                        state.humanoidRootPart = fallback
                    end)
                end)
                table.insert(state.charConnections, diedConn2)
                safe_pcall(function() humAdded:Disconnect() end)
            end
        end)
        table.insert(state.charConnections, humAdded)
    end
end

local function stopFlinging()
    state.flingActive = false
    disconnectAll()
    setStatus("Flinging stopped.", true)
end

local function startFlinging()
    if not state.character or not state.att1 then
        setStatus("No character/attachment ready! Wait for respawn.", false)
        return
    end
    if not state.humanoidRootPart or not state.humanoidRootPart:IsDescendantOf(state.character) then
        local fallback = findAnyCharacterPart(state.character)
        if fallback then
            state.humanoidRootPart = fallback
        else
            setStatus("No body part found to attach to.", false)
        end
    end
    state.flingActive = true
    for _, v in ipairs(Workspace:GetDescendants()) do
        ForcePart(v)
    end
    table.insert(state.connections, Workspace.DescendantAdded:Connect(function(v)
        if state.flingActive then ForcePart(v) end
    end))
    table.insert(state.connections, RunService.RenderStepped:Connect(function()
        if state.flingActive and state.att1 then
            safe_pcall(function()
                if (not state.humanoidRootPart) or (state.character and not state.humanoidRootPart:IsDescendantOf(state.character)) then
                    if state.player then
                        local curChar = state.player.Character
                        state.character = curChar or state.character
                        local newPart = findAnyCharacterPart(curChar or state.character)
                        if newPart then
                            state.humanoidRootPart = newPart
                        end
                    end
                end
                if state.humanoidRootPart and state.humanoidRootPart:IsA("BasePart") then
                    state.att1.WorldCFrame = state.humanoidRootPart.CFrame
                end
            end)
        end
    end))
    local hum = state.character and state.character:FindFirstChildOfClass("Humanoid")
    if hum then
        table.insert(state.connections, hum.Died:Connect(function()
            setStatus("Target died — continuing fling.", true)
            local fallback = findAnyCharacterPart(state.character)
            if fallback then
                state.humanoidRootPart = fallback
            else
                state.humanoidRootPart = nil
            end
        end))
    end
    if state.player then
        table.insert(state.connections, state.player.AncestryChanged:Connect(function(_, parent)
            if not parent then
                setStatus("Target left game.", false)
                unbringPartsCommand()
            end
        end))
    end
end

local function onCharacterSpawned()
    local char = state.player and state.player.Character
    if char then
        attachToCharacter(char)
    end
end

local function bringPartsCommand(arg)
    safe_pcall(function()
        local p
        if typeof(arg) == "Instance" and arg:IsA("Player") then
            p = arg
        else
            local name = tostring(arg or "")
            if name ~= "" then
                p = getPlayer(name)
            else
                p = nil
            end
        end
        if not p then
            setStatus("Chat: no player specified/found.", false)
            return
        end
        disconnectAll()
        disconnectCharConnections()
        state.player = p
        setStatus("Chat: Player found: " .. p.Name, true)
        table.insert(state.connections, state.player.CharacterAdded:Connect(function(char)
            delay(0.05, function()
                attachToCharacter(char)
            end)
        end))
        if state.player.Character then
            attachToCharacter(state.player.Character)
        else
            local ok, char = pcall(function() return state.player.CharacterAdded:Wait(3) end)
            if ok and char then
                attachToCharacter(char)
            end
        end
        if not state.att1 then
            setupFolderAndPart()
        end
        if not state.blackHoleActive then
            state.blackHoleActive = true
            setStatus("Flinging enabled via chat.", true)
            startFlinging()
        else
            setStatus("Switched fling target via chat.", true)
            startFlinging()
        end
    end)
end

local function unbringPartsCommand(arg)
    safe_pcall(function()
        local currentAtt = state.att1
        if currentAtt then
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("BasePart") then
                    for _, child in ipairs(v:GetChildren()) do
                        if child:IsA("AlignPosition") or child:IsA("AlignOrientation") or child:IsA("Torque") then
                            safe_pcall(function() child:Destroy() end)
                        end
                        if child:IsA("Attachment") and (child.Name == "PartsFling_Attach_Internal" or child.Name == "PartsFling_Attach_Internal_O") then
                            safe_pcall(function() child:Destroy() end)
                        end
                    end
                    safe_pcall(function()
                        v.AssemblyLinearVelocity = Vector3.new(0,0,0)
                        v.Velocity = Vector3.new(0,0,0)
                        v.CanCollide = true
                    end)
                    if getgenv().Network and getgenv().Network.BaseParts then
                        for i = #getgenv().Network.BaseParts, 1, -1 do
                            if getgenv().Network.BaseParts[i] == v then
                                table.remove(getgenv().Network.BaseParts, i)
                            end
                        end
                    end
                end
            end
        end
        stopFlinging()
        clearCharacterState()
        cleanupFolderAndPart()
        state.player = nil
        state.blackHoleActive = false
        state.flingActive = false
        setStatus("Flinging disabled / parts recalled.", true)
        if not arg or trim(tostring(arg)) == "" then
            safe_pcall(function()
                if LocalPlayer then
                    LocalPlayer:LoadCharacter()
                end
            end)
        end
    end)
end

local function getPlayerFromMouseTarget()
    local ok, mouse = pcall(function() return LocalPlayer:GetMouse() end)
    if not ok or not mouse then return nil end
    local target = mouse.Target
    if not target then return nil end
    local char = target:FindFirstAncestorOfClass("Model")
    if not char then return nil end
    local p = Players:GetPlayerFromCharacter(char)
    return p
end

local function isValidTargetPlayer(p)
    if not p or not p.Character then return false end
    if p == LocalPlayer then return false end
    local hum = p.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health ~= nil and hum.Health <= 0 then return false end
    local main = findAnyCharacterPart(p.Character)
    if not main then return false end
    return true
end

local function playerPartsCount(p)
    if not p or not p.Character then return 0 end
    local count = 0
    for _, d in ipairs(p.Character:GetDescendants()) do
        if d:IsA("BasePart") then count = count + 1 end
    end
    return count
end

local function autoDetectTarget()
    local p = getPlayerFromMouseTarget()
    if isValidTargetPlayer(p) then return p end
    local best, bestDist = nil, math.huge
    local myPos
    local myChar = LocalPlayer and LocalPlayer.Character
    if myChar then
        local myPart = findAnyCharacterPart(myChar)
        if myPart then myPos = myPart.Position end
    end
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and isValidTargetPlayer(pl) then
            local part = findAnyCharacterPart(pl.Character)
            if part and myPos then
                local d = (part.Position - myPos).Magnitude
                if d < bestDist then
                    bestDist = d
                    best = pl
                end
            elseif not myPos then
                best = pl
                break
            end
        end
    end
    if best then return best end
    local mostParts, mostPl = 0, nil
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and isValidTargetPlayer(pl) then
            local c = playerPartsCount(pl)
            if c > mostParts then
                mostParts = c
                mostPl = pl
            end
        end
    end
    return mostPl
end

local function enableFly(speed)
    if state.fly.enabled then
        state.fly.speed = tonumber(speed) or state.fly.speed
        setStatus("Fly speed set to " .. tostring(state.fly.speed), true)
        return
    end
    local char = LocalPlayer.Character
    if not char then
        local ok, c = pcall(function() return LocalPlayer.CharacterAdded:Wait(3) end)
        char = ok and c or nil
    end
    if not char then
        setStatus("No character to attach fly to.", false)
        return
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        setStatus("No HumanoidRootPart found.", false)
        return
    end
    state.fly.enabled = true
    state.fly.speed = tonumber(speed) or state.fly.speed or 100
    state.fly.keys = {}
    state.fly.bv = Instance.new("BodyVelocity")
    state.fly.bv.Parent = hrp
    state.fly.bv.MaxForce = Vector3.new(1e5,1e5,1e5)
    state.fly.bv.Velocity = Vector3.new(0,0,0)
    state.fly.bg = Instance.new("BodyGyro")
    state.fly.bg.Parent = hrp
    state.fly.bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
    state.fly.bg.CFrame = hrp.CFrame

    state.fly.inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            state.fly.keys[tostring(input.KeyCode.Name)] = true
        end
    end)
    state.fly.inputEnded = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            state.fly.keys[tostring(input.KeyCode.Name)] = nil
        end
    end)

    state.fly.renderConn = RunService.RenderStepped:Connect(function()
        if not state.fly.enabled then return end
        local cam = Workspace.CurrentCamera
        if not cam then return end
        local hrp2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp2 then return end
        local forward = cam.CFrame.LookVector
        local right = cam.CFrame.RightVector
        local moveVec = Vector3.new(0,0,0)
        if state.fly.keys["W"] then moveVec = moveVec + forward end
        if state.fly.keys["S"] then moveVec = moveVec - forward end
        if state.fly.keys["A"] then moveVec = moveVec - right end
        if state.fly.keys["D"] then moveVec = moveVec + right end
        if state.fly.keys["Space"] then moveVec = moveVec + Vector3.new(0,1,0) end
        if state.fly.keys["LeftControl"] or state.fly.keys["C"] then moveVec = moveVec - Vector3.new(0,1,0) end
        if state.fly.keys["LeftShift"] or state.fly.keys["RightShift"] then
            moveVec = moveVec * 2
        end
        if moveVec.Magnitude > 0 then
            moveVec = moveVec.Unit * state.fly.speed
        else
            moveVec = Vector3.new(0,0,0)
        end
        pcall(function() state.fly.bv.Velocity = moveVec end)
        pcall(function()
            if state.fly.bg and hrp2 then
                state.fly.bg.CFrame = CFrame.new(hrp2.Position, hrp2.Position + cam.CFrame.LookVector)
            end
        end)
    end)

    state.fly.charConn = LocalPlayer.CharacterAdded:Connect(function(char2)
        delay(0.1, function()
            if not state.fly.enabled then return end
            enableFly(state.fly.speed)
        end)
    end)
    setStatus("Fly enabled. Use WASD + Space/LCtrl, Shift to boost.", true)
end

local function disableFly()
    state.fly.enabled = false
    if state.fly.inputBegan and typeof(state.fly.inputBegan) == "RBXScriptConnection" then
        safe_pcall(function() state.fly.inputBegan:Disconnect() end)
    end
    if state.fly.inputEnded and typeof(state.fly.inputEnded) == "RBXScriptConnection" then
        safe_pcall(function() state.fly.inputEnded:Disconnect() end)
    end
    if state.fly.renderConn and typeof(state.fly.renderConn) == "RBXScriptConnection" then
        safe_pcall(function() state.fly.renderConn:Disconnect() end)
    end
    if state.fly.charConn and typeof(state.fly.charConn) == "RBXScriptConnection" then
        safe_pcall(function() state.fly.charConn:Disconnect() end)
    end
    if state.fly.bv and state.fly.bv.Parent then safe_pcall(function() state.fly.bv:Destroy() end) end
    if state.fly.bg and state.fly.bg.Parent then safe_pcall(function() state.fly.bg:Destroy() end) end
    state.fly.bv = nil
    state.fly.bg = nil
    state.fly.inputBegan = nil
    state.fly.inputEnded = nil
    state.fly.renderConn = nil
    state.fly.charConn = nil
    state.fly.keys = {}
    setStatus("Fly disabled.", true)
end

local function toggleFly(arg)
    local a = tostring(arg or "")
    if a == "" then
        if state.fly.enabled then disableFly() else enableFly() end
        return
    end
    local la = string.lower(a)
    if la == "on" or la == "true" or la == "1" then
        enableFly()
        return
    end
    if la == "off" or la == "false" or la == "0" then
        disableFly()
        return
    end
    local n = tonumber(a)
    if n then
        if state.fly.enabled then
            state.fly.speed = n
            setStatus("Fly speed set to " .. tostring(n), true)
        else
            enableFly(n)
        end
        return
    end
    if state.fly.enabled then disableFly() else enableFly() end
end

local function createMobileToggleButton()
    if not UserInputService.TouchEnabled then return end
    if state.fly.mobileGui and state.fly.mobileGui.Parent then return end
    local parent = getGuiParent()
    if not parent then return end
    local existing = parent:FindFirstChild("JadeAdmin_MobileGui")
    if existing then
        state.fly.mobileGui = existing
        local btn = existing:FindFirstChild("FlyToggleButton")
        if btn then state.fly.mobileButton = btn end
    else
        local gui = Instance.new("ScreenGui")
        gui.Name = "JadeAdmin_MobileGui"
        gui.ResetOnSpawn = false
        gui.Parent = parent
        local btn = Instance.new("TextButton")
        btn.Name = "FlyToggleButton"
        btn.Parent = gui
        btn.AnchorPoint = Vector2.new(0.5, 0.5)
        btn.Position = UDim2.new(0.85, 0, 0.88, 0)
        btn.Size = UDim2.new(0.13, 0, 0.10, 0)
        btn.Text = "Fly"
        btn.TextScaled = true
        btn.BackgroundTransparency = 0.2
        btn.ZIndex = 10
        state.fly.mobileGui = gui
        state.fly.mobileButton = btn
    end
    if state.fly.mobileButton and not state.fly.mobileButtonConn then
        state.fly.mobileButtonConn = state.fly.mobileButton.Activated:Connect(function()
            toggleFly()
        end)
    end
end

safe_pcall(function() createMobileToggleButton() end)

if not UserInputService.TouchEnabled then
    if state.fly.toggleKeyConn and typeof(state.fly.toggleKeyConn) == "RBXScriptConnection" then
        safe_pcall(function() state.fly.toggleKeyConn:Disconnect() end)
    end
    state.fly.toggleKeyConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.E then
            toggleFly()
        end
    end)
end

local function tryHttpGet(url)
    local ok, res, body
    ok, body = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if ok and body then
        return true, body
    end
    if syn and syn.request then
        ok, res = pcall(syn.request, {Url = url; Method = "GET"})
        if ok and res and (res.Body or res.body) then
            return true, (res.Body or res.body)
        end
    end
    if http_request then
        ok, res = pcall(http_request, {Url = url; Method = "GET"})
        if ok and res and (res.Body or res.body) then
            return true, (res.Body or res.body)
        end
    end
    if request then
        ok, res = pcall(request, {Url = url; Method = "GET"})
        if ok and res and (res.Body or res.body) then
            return true, (res.Body or res.body)
        end
    end
    return false, nil
end

local function rejoinCurrentServer()
    safe_pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

local function serverHop()
    safe_pcall(function()
        local placeId = tostring(game.PlaceId)
        local currentJob = tostring(game.JobId)
        local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
        local success, body = tryHttpGet(url)
        local picked = nil
        if success and body then
            local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
            if ok and type(data) == "table" and data.data then
                for _, server in ipairs(data.data) do
                    if server.playing < (server.maxPlayers or 0) and tostring(server.id) ~= currentJob then
                        picked = tostring(server.id)
                        break
                    end
                end
            end
        end
        if picked then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, picked, LocalPlayer)
            return
        end
        local ok, reserved = pcall(function() return TeleportService:ReserveServer(game.PlaceId) end)
        if ok and reserved then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, reserved, LocalPlayer)
            return
        end
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

local function respawnPlayer()
    safe_pcall(function()
        if LocalPlayer then
            LocalPlayer:LoadCharacter()
        end
    end)
end

local function setWalkSpeed(value)
    value = tonumber(value)
    if not value then
        setStatus("Invalid walkspeed value.", false)
        return
    end
    state.walkSpeed = value
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            safe_pcall(function() hum.WalkSpeed = state.walkSpeed end)
        end
    end
    setStatus("WalkSpeed set to " .. tostring(state.walkSpeed), true)
end

local function setJumpPower(value)
    value = tonumber(value)
    if not value then
        setStatus("Invalid jumppower value.", false)
        return
    end
    state.jumpPower = value
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            safe_pcall(function() hum.JumpPower = state.jumpPower end)
        end
    end
    setStatus("JumpPower set to " .. tostring(state.jumpPower), true)
end

local function gotoPlayer(name)
    local p
    local nm = tostring(name or "")
    if trim(nm) == "" then
        p = autoDetectTarget()
        if not p then
            setStatus("No player specified and auto-detect failed.", false)
            return
        end
    else
        p = getPlayer(nm)
        if not p then
            setStatus("Player not found: " .. tostring(nm), false)
            return
        end
    end
    if p == LocalPlayer then
        setStatus("Cannot goto yourself.", false)
        return
    end
    if not p.Character then
        setStatus("Target has no character.", false)
        return
    end
    local targetPart = findAnyCharacterPart(p.Character)
    if not targetPart then
        setStatus("Target has no usable body part.", false)
        return
    end
    if not LocalPlayer.Character then
        setStatus("No local character to move.", false)
        return
    end
    local myPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or findAnyCharacterPart(LocalPlayer.Character)
    if not myPart then
        setStatus("No local body part to move.", false)
        return
    end
    safe_pcall(function()
        local forwardOffset = (targetPart.CFrame.LookVector * 2)
        local upOffset = Vector3.new(0, 3, 0)
        myPart.CFrame = targetPart.CFrame + forwardOffset + upOffset
    end)
    setStatus("Teleported to " .. p.Name, true)
end

local function tryHandleShortcutCommands(cmd, arg)
    local lc = string.lower(cmd)
    if lc == "rejoin" then
        rejoinCurrentServer()
        return true
    elseif lc == "serverhop" or lc == "shop" then
        serverHop()
        return true
    elseif lc == "respawn" or lc == "re" then
        respawnPlayer()
        return true
    elseif lc == "walkspeed" then
        setWalkSpeed(arg)
        return true
    elseif lc == "jumppower" then
        setJumpPower(arg)
        return true
    elseif lc == "goto" then
        gotoPlayer(arg)
        return true
    end
    return false
end

local function enableNoclip()
    if state.noclip.enabled then
        setStatus("Noclip already enabled.", true)
        return
    end
    state.noclip.enabled = true
    state.noclip.conn = RunService.Stepped:Connect(function()
        local char = LocalPlayer and LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = false end)
            end
        end
    end)
    setStatus("Noclip enabled.", true)
end

local function disableNoclip()
    state.noclip.enabled = false
    if state.noclip.conn and typeof(state.noclip.conn) == "RBXScriptConnection" then
        safe_pcall(function() state.noclip.conn:Disconnect() end)
    end
    state.noclip.conn = nil
    local char = LocalPlayer and LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = true end)
            end
        end
    end
    setStatus("Noclip disabled.", true)
end

local function toggleNoclip(arg)
    local a = tostring(arg or "")
    if a == "" then
        if state.noclip.enabled then disableNoclip() else enableNoclip() end
        return
    end
    local la = string.lower(a)
    if la == "on" or la == "true" or la == "1" then
        enableNoclip()
        return
    end
    if la == "off" or la == "false" or la == "0" then
        disableNoclip()
        return
    end
    if state.noclip.enabled then disableNoclip() else enableNoclip() end
end

local function enableInfiniteJump(power)
    if state.infiniteJump.enabled then
        state.infiniteJump.power = tonumber(power) or state.infiniteJump.power
        setStatus("InfiniteJump power set to " .. tostring(state.infiniteJump.power), true)
        return
    end
    state.infiniteJump.enabled = true
    state.infiniteJump.power = tonumber(power) or state.infiniteJump.power or 100
    state.infiniteJump.conn = UserInputService.JumpRequest:Connect(function()
        local char = LocalPlayer and LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            safe_pcall(function()
                if not state.infiniteJump.origJumpPower then
                    state.infiniteJump.origJumpPower = hum.JumpPower
                end
                hum.JumpPower = state.infiniteJump.power
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end)
        end
    end)
    state.infiniteJump.charConn = LocalPlayer.CharacterAdded:Connect(function(char2)
        delay(0.1, function()
            if not state.infiniteJump.enabled then return end
            enableInfiniteJump(state.infiniteJump.power)
        end)
    end)
    setStatus("InfiniteJump enabled. Power: " .. tostring(state.infiniteJump.power), true)
end

local function disableInfiniteJump()
    state.infiniteJump.enabled = false
    if state.infiniteJump.conn and typeof(state.infiniteJump.conn) == "RBXScriptConnection" then
        safe_pcall(function() state.infiniteJump.conn:Disconnect() end)
    end
    if state.infiniteJump.charConn and typeof(state.infiniteJump.charConn) == "RBXScriptConnection" then
        safe_pcall(function() state.infiniteJump.charConn:Disconnect() end)
    end
    state.infiniteJump.conn = nil
    state.infiniteJump.charConn = nil
    local char = LocalPlayer and LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            safe_pcall(function()
                if state.infiniteJump.origJumpPower then
                    hum.JumpPower = state.infiniteJump.origJumpPower
                elseif state.jumpPower then
                    hum.JumpPower = state.jumpPower
                end
            end)
        end
    end
    state.infiniteJump.origJumpPower = nil
    setStatus("InfiniteJump disabled.", true)
end

local function toggleInfiniteJump(arg)
    local a = tostring(arg or "")
    if a == "" then
        if state.infiniteJump.enabled then disableInfiniteJump() else enableInfiniteJump() end
        return
    end
    local la = string.lower(a)
    if la == "on" or la == "true" or la == "1" then
        enableInfiniteJump(state.infiniteJump.power)
        return
    end
    if la == "off" or la == "false" or la == "0" then
        disableInfiniteJump()
        return
    end
    local n = tonumber(a)
    if n then
        if state.infiniteJump.enabled then
            state.infiniteJump.power = n
            setStatus("InfiniteJump power set to " .. tostring(n), true)
        else
            enableInfiniteJump(n)
        end
        return
    end
    if state.infiniteJump.enabled then disableInfiniteJump() else enableInfiniteJump() end
end

local function processCommandString(commandString)
    if not commandString then return end
    local cmd, arg = commandString:match("^!?(%S+)%s*(.*)")
    if not cmd then return end
    local lc = string.lower(cmd)
    if tryHandleShortcutCommands(lc, arg) then
        return
    end
    if lc == "bringparts" then
        if not arg or #trim(arg) == 0 then
            local autoTarget = autoDetectTarget()
            if autoTarget then
                bringPartsCommand(autoTarget)
            else
                setStatus("Auto-detect found no target.", false)
            end
        else
            bringPartsCommand(arg)
        end
    elseif lc == "unbringparts" then
        unbringPartsCommand(arg)
    elseif lc == "fly" then
        toggleFly(arg)
    elseif lc == "unfly" then
        disableFly()
    elseif lc == "noclip" then
        toggleNoclip(arg)
    elseif lc == "clip" then
        disableNoclip()
    elseif lc == "infinitejump" or lc == "infjump" then
        toggleInfiniteJump(arg)
    end
end

local function chatHandler(msg)
    if not msg then return end
    local emoteCmd = msg:match("^/e%s+(.*)")
    if emoteCmd then
        processCommandString(emoteCmd)
        return
    end
    local hasBang = msg:match("^!")
    if hasBang then
        processCommandString(msg)
        return
    end
    local maybeCmd = msg:match("^(%S+)%s*(.*)")
    if maybeCmd then
        local cmdCandidate, argCandidate = msg:match("^(%S+)%s*(.*)")
        if cmdCandidate then
            local lc = string.lower(cmdCandidate)
            local known = {
                bringparts=true, unbringparts=true, fly=true, unfly=true,
                rejoin=true, serverhop=true, shop=true, respawn=true, re=true,
                walkspeed=true, jumppower=true, goto=true, noclip=true, clip=true,
                infinitejump=true, infjump=true
            }
            if known[lc] then
                processCommandString(msg)
                return
            end
        end
    end
end

if LocalPlayer then
    state.chatConnection = LocalPlayer.Chatted:Connect(chatHandler)
end

state.playerRemovingConnection = Players.PlayerRemoving:Connect(function(plr)
    if state.player and plr == state.player then
        setStatus("Target left game.", false)
        unbringPartsCommand()
    end
end)

Players.PlayerAdded:Connect(function(plr) end)

LocalPlayer.CharacterAdded:Connect(function(char)
    applyWalkJumpToChar(char)
    if state.fly.enabled then
        delay(0.1, function()
            enableFly(state.fly.speed)
        end)
    end
    if state.noclip.enabled then
        enableNoclip()
    end
    if state.infiniteJump.enabled then
        delay(0.1, function()
            enableInfiniteJump(state.infiniteJump.power)
        end)
    end
end)
