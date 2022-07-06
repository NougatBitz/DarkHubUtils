local game              = game
local GetService        = game.GetService
local FindFirstChild    = game.FindFirstChild

local UserInputService  = GetService(game, "UserInputService")
local Workspace         = GetService(game, "Workspace")

local Camera            = Workspace.CurrentCamera


--// cross compatibility
local is_executor_closure = is_synapse_function or isexecutorclosure or (function() return false end)

local getinfo             = getinfo or (debug and debug.getinfo) or (debug.info and (function(f)
    local name, func, source, line = debug.info(f, "nfsl")
    return { source = "=" .. source; short_src = source; what = source == "[C]" and "C" or "Lua"; name = name; func = func; currentline = line; }
end))

local is_cpp_closure      = iscclosure or is_cclosure or ( function(f) return getinfo(f).what == "C" end )
local is_lua_closure      = islclosure or is_lclosure or ( function(f) return not is_cpp_closure(f) end )

function FunctionCheck(Function, FuncTable)
    for i, FunctionInfo in next, FuncTable do
        local FFunctionInfo = getinfo(Function)

        local FunctionName  = FunctionInfo.name 
        local FFunctionName = FFunctionInfo.name


        if FunctionName == FFunctionName then

            local ScriptCheck = FunctionInfo.script_check
            local StorageName = FunctionInfo.storage_name

            if ScriptCheck then
                local IsValidScript = ScriptCheck(FFunctionInfo.source)
                if IsValidScript then
                    return StorageName or FunctionName
                end
                return false
            end

            return StorageName or FunctionName
        end
    end
end

local Functions = {}

Functions.GetMouse = function()
    return UserInputService.GetMouseLocation(UserInputService)
end

Functions.VisibleCheck = function(Settings)
    if Settings.RayCheck == false then
        local ScreenVector, OnScreen = Camera.WorldToViewportPoint(Camera, Settings.End)
        return OnScreen, ScreenVector
    end

    local PartAncestor = Settings.Part.Parent
    local Start, End = Settings.Start, Settings.End

    local Distance  = (Start - End).Magnitude
    local Unit      = (End - Start).Unit

    local HitPart, HitPosition = Workspace.FindPartOnRayWithIgnoreList(
        Workspace, 
        Ray.new(Start, Unit * Distance),
        Settings.IgnoreList
    )
    local ScreenVector

    local IsAncestorOfRayPart = PartAncestor:IsAncestorOf(HitPart)
    local Visible             = IsAncestorOfRayPart or ( (HitPart == nil) or (HitPart.Transparency ~= 0) )

    if Visible then
        ScreenVector, OnScreen = Camera.WorldToViewportPoint(Camera, HitPosition or End)

        if Settings.OnScreen and (not OnScreen) then
            Visible = false
        end
    end

    return Visible, ScreenVector
end

Functions.GetClosestPlayerToMouse = function(Players, Validate, MaxDistance, Settings)
    local MaxDistance = MaxDistance or math.huge
    local Closest, ClosestPart = nil, nil

    for index, value in next, Players do
        local CharacterPart = Validate(index, value)
        if CharacterPart then
            local PartVisible, ScreenVector = Functions.VisibleCheck({
                Start       = Settings.Start,
                End         = CharacterPart.Position;
                Part        = CharacterPart;
                OnScreen    = Settings.OnScreen or true;
                RayCheck    = Settings.RayCheck or true;
                IgnoreList  = Settings.IgnoreList or {}
            })
            if PartVisible and ScreenVector then
               
                local Distance = ( (Settings.Mouse or Functions.GetMouse)() - Vector2.new(ScreenVector.X, ScreenVector.Y) ).Magnitude
                if (Distance < MaxDistance) then
                    MaxDistance = Distance

                    Closest     = value
                    ClosestPart = CharacterPart
                end

            end
        end
    end

    return Closest, ClosestPart
end

Functions.GetFunctionsFromGC = function(FunctionTable)
    local TempFunctions = {}
    
    for i, v in next, getgc() do
        if type(v) == "function" and is_lua_closure(v) and (not is_executor_closure(v)) then
            local valid_name = FunctionCheck(v, FunctionTable)
        
            if valid_name then
                TempFunctions[valid_name] = v
            end
        end
    end

    return TempFunctions
end

Functions.GetTableFromGC = function(x)
    local Result

    for i, v in next, getgc(true) do
        if type(v) == "table" then
            for i2, v2 in next, v do
                if v2 == x or i2 == x then
                    Result = v
                    break
                end
            end
        end
    end

    return Result
end

return Functions




--[[
local LocalPlayer       = game.Players.LocalPlayer
local LocalCharacter    = LocalPlayer.Character
local LocalHead         = LocalCharacter.Head
local ValidatePlayer    = function(i,v)
    if v.Character and v.Character:FindFirstChild("Head") then
        return v.Character.Head
    end
    return "NONE"
end

local Closest, Position =  Functions.GetClosestPlayerToMouse(game.Players:GetPlayers(), ValidatePlayer, math.huge, {
    Start       = LocalHead.Position;
    IgnoreList  = {
        LocalCharacter, 
        workspace.CurrentCamera
    };
})
warn(Closest)]]