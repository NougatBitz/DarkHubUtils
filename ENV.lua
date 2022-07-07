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
                    local old_script
                    for i3, v3 in next, v do
                        if type(v3) == "function" then
                            local cur_script = getfenv(v3).script
                            if not old_script then old_script = cur_script end
                            if old_script ~= cur_script then
                                continue
                            end
                        end
                    end
                    Result = v
                    break
                end
            end
        end
    end

    return Result
end

return Functions
