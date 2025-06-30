local ScriptName = "Spectre011's Lua Utility Library" 
local Author = "Spectre011"
local ScriptVersion = "1.0.0"
local ReleaseDate = "15-06-2025"
local DiscordHandle = "not_spectre011"

--[[
======================================================================================
                       Spectre011's Lua Utility Library (Slib)                       
======================================================================================

A comprehensive utility library for RuneScape automation scripts to me used with ME,
providing robust parameter validation, debugging tools, helper functions and procedures
designed specifically for RuneScape automation scripts.

--------------------------------------------------------------------------------------
                                       CREDITS                                       
--------------------------------------------------------------------------------------

Primary Author: Spectre011 (Discord: not_spectre011)
GitHub: https://github.com/spectre011-code
AI Assistant: Claude (Anthropic) - Code generation and optimization

This library was developed with AI assistance for:
• Code structure and organization
• Documentation and error handling
• Testing and debugging utilities

======================================================================================

Changelog:
v1.0.0 - 15-06-2025
    - Initial release
]]

local API = require("api")

local Slib = {}

Slib.ChatMessages = API.GatherEvents_chat_check()

Slib.Interfaces = {}

Slib.Interfaces.TextInput = { 
    { { 1469,0,-1,0 }, { 1469,1,-1,0 } }
}

Slib.Interfaces.InstanceOptions = {
    { {1591,15,-1,0} }, -- Base
    { {1591,15,-1,0}, {1591,17,-1,0}, {1591,45,-1,0}, {1591,46,-1,0}, {1591,74,-1,0} }, -- Max Players
    { {1591,15,-1,0}, {1591,17,-1,0}, {1591,49,-1,0}, {1591,76,-1,0}, {1591,83,-1,0} }, -- Min Combat
    { {1591,15,-1,0}, {1591,17,-1,0}, {1591,50,-1,0}, {1591,85,-1,0}, {1591,94,-1,0} }, -- Spawn Speed
    { {1591,15,-1,0}, {1591,17,-1,0}, {1591,51,-1,0}, {1591,52,-1,0}, {1591,102,-1,0} } -- Protection

}

Slib.Interfaces.InstanceTimer = { 
    { { 861,0,-1,0 }, { 861,2,-1,0 }, { 861,4,-1,0 }, { 861,8,-1,0 } } -- 1
}

Slib.Interfaces.GWD1KillCounts = {
    { {601,11,-1,0}, {601,9,-1,0}, { 601,18,-1,0 } }, -- Armadyl
    { {601,11,-1,0}, {601,9,-1,0}, { 601,19,-1,0 } }, -- Bandos
    { {601,11,-1,0}, {601,9,-1,0}, { 601,20,-1,0 } }, -- Saradomin
    { {601,11,-1,0}, {601,9,-1,0}, { 601,21,-1,0 } }, -- Zamorak
    { {601,11,-1,0}, {601,9,-1,0}, { 601,22,-1,0 } }, -- Zaros
}

Slib.Interfaces.GWD2KillCounts = {
    { { 1746,0,-1,0 }, { 1746,38,-1,0 }, { 1746,41,-1,0 }, { 1746,43,-1,0 }, { 1746,47,-1,0 } },  -- Seren
    { { 1746,0,-1,0 }, { 1746,38,-1,0 }, { 1746,41,-1,0 }, { 1746,49,-1,0 }, { 1746,54,-1,0 } },  -- Sliske
    { { 1746,0,-1,0 }, { 1746,38,-1,0 }, { 1746,41,-1,0 }, { 1746,55,-1,0 }, { 1746,60,-1,0 } },  -- Zamorak
    { { 1746,0,-1,0 }, { 1746,38,-1,0 }, { 1746,41,-1,0 }, { 1746,61,-1,0 }, { 1746,66,-1,0 } },  -- Zaros
}

Slib.Interfaces.CurrencyPouch = {
    { {1473,0,-1,0}, {1473,13,-1,0}, {1473,17,-1,0}, {1473,18,-1,0}, {1473,21,-1,0} }
}

Slib.Interfaces.AreaLoot = {
    { {1622,4,-1,0}, {1622,6,-1,0}, {1622,1,-1,0}, {1622,11,-1,0} }
}

-- ##################################
-- #                                #
-- #       LOGGING FUNCTIONS        #
-- #                                #
-- ##################################

-- Logs a general message with Slib prefix
---@param Message string The message to log
---@return string Message The logged message
function Slib:Log(Message)
    if not self:Sanitize(Message, "string", "Message") then
        return ""
    end
    API.printlua("[Slib][LOG] " .. tostring(Message), 0, false)
    return Message
end

-- Logs an informational message with INFO level
---@param Message string The informational message to log
---@return string Message The logged message
function Slib:Info(Message)
    if not self:Sanitize(Message, "string", "Message") then
        return ""
    end
    API.printlua("[Slib][INFO] " .. tostring(Message), 7, false)
    return Message
end

-- Logs a warning message with WARN level
---@param Message string The warning message to log
---@return string Message The logged message
function Slib:Warn(Message)
    if not self:Sanitize(Message, "string", "Message") then
        return ""
    end
    API.printlua("[Slib][WARN] " .. tostring(Message), 2, false)
    return Message
end

-- Logs an error message with ERROR level
---@param Message string The error message to log
---@return string Message The logged message
function Slib:Error(Message)
    -- Manual validation to avoid circular dependency with sanitization system
    if Message == nil then
        API.printlua("[Slib][ERROR] Error function received nil message", 4, false)
        return ""
    end
    if type(Message) ~= "string" then
        API.printlua("[Slib][ERROR] Error function received non-string message: " .. tostring(Message), 4, false)
        return tostring(Message)
    end
    API.printlua("[Slib][ERROR] " .. tostring(Message), 4, false)
    return Message
end

-- ##################################
-- #                                #
-- #    SANITIZATION FUNCTIONS      #
-- #                                #
-- ##################################

-- Validates that a value matches the specified type(s) with support for complex types
---
--- **Basic Lua Types:**
---   - "string", "number", "boolean", "function", "table", "userdata", "thread"
---   - "any" - accepts any non-nil value (unless AllowNil is true)
---
--- **Enhanced Number Types:**
---   - "id" - non-negative integers (0, 1, 2, 3...)
---   - "positive_number" - numbers greater than 0
---   - "non_negative_number" - numbers >= 0  
---   - "integer" - whole numbers (positive, negative, or zero)
---
--- **Enhanced String Types:**
---   - "non_empty_string" - strings that aren't empty
---
--- **Table Types:**
---   - "table_of_strings" - array of strings
---   - "table_of_numbers" - array of numbers
---   - "table_of_ids" - array of non-negative integers
---   - "table_of_positive_numbers" - array of positive numbers
---   - "table_of_integers" - array of whole numbers
---   - "non_empty_table" - table that has at least one element
---
---
---@param Value any The value to validate
---@param ExpectedType string|table The expected type(s) - can be single type or array of types
---@param ParamName string|nil Optional parameter name for error messages (default: "Parameter")
---@param AllowNil boolean|nil Whether nil values should be considered valid (optional, default: false)
---@param CallingFunction string|nil Optional calling function name for error messages
---@return boolean IsValid True if validation passes, false otherwise (errors logged via self:Error)
function Slib:Sanitize(Value, ExpectedType, ParamName, AllowNil, CallingFunction)
    -- Set defaults
    ParamName = ParamName or "Parameter"
    if AllowNil == nil then
        AllowNil = false
    end
    
    -- Get calling function name for better error messages
    if not CallingFunction then
        CallingFunction = "Unknown"
        local Info = debug.getinfo(2, "n")
        if Info and Info.name then
            CallingFunction = Info.name
        end
    end
    
    -- Handle nil values
    if Value == nil then
        if AllowNil then
            return true
        else
            self:Error("[" .. CallingFunction .. "] " .. ParamName .. " cannot be nil")
            return false
        end
    end
    
    -- Ensure ExpectedType is a table for consistent processing
    local TypeTable = type(ExpectedType) == "table" and ExpectedType or {ExpectedType}
    
    -- Get actual type of the value
    local ActualType = type(Value)
    
    -- Check each expected type
    for _, ExpectedPattern in ipairs(TypeTable) do
        if type(ExpectedPattern) ~= "string" then
            self:Error("[" .. CallingFunction .. "] Invalid type specification: " .. tostring(ExpectedPattern))
            return false
        end
        
        -- Check basic Lua types
        if ExpectedPattern == ActualType then
            return true
        end
        
        -- Check for 'any' type (accepts anything except nil unless AllowNil is true)
        if ExpectedPattern == "any" then
            return true
        end
        
        -- Check for 'id' type (non-negative integer)
        if ExpectedPattern == "id" then
            if ActualType == "number" and Value >= 0 and math.floor(Value) == Value then
                return true
            end
        end
        
        -- Check for 'positive_number' type
        if ExpectedPattern == "positive_number" then
            if ActualType == "number" and Value > 0 then
                return true
            end
        end
        
        -- Check for 'non_negative_number' type
        if ExpectedPattern == "non_negative_number" then
            if ActualType == "number" and Value >= 0 then
                return true
            end
        end
        
        -- Check for 'integer' type
        if ExpectedPattern == "integer" then
            if ActualType == "number" and math.floor(Value) == Value then
                return true
            end
        end
        
        -- Check for 'non_empty_string' type
        if ExpectedPattern == "non_empty_string" then
            if ActualType == "string" and Value ~= "" then
                return true
            end
        end
        
        -- Check for table-based complex types
        if ActualType == "table" or ActualType == "userdata" then
            -- Check for 'table_of_strings'
            if ExpectedPattern == "table_of_strings" then
                for I, Item in ipairs(Value) do
                    if type(Item) ~= "string" then
                        self:Error("[" .. CallingFunction .. "] " .. ParamName .. " must be a table of strings (item " .. I .. " is " .. type(Item) .. ")")
                        return false
                    end
                end
                return true
            end
            
            -- Check for 'table_of_numbers'
            if ExpectedPattern == "table_of_numbers" then
                for I, Item in ipairs(Value) do
                    if type(Item) ~= "number" then
                        self:Error("[" .. CallingFunction .. "] " .. ParamName .. " must be a table of numbers (item " .. I .. " is " .. type(Item) .. ")")
                        return false
                    end
                end
                return true
            end
            
            -- Check for 'table_of_ids'
            if ExpectedPattern == "table_of_ids" then
                for I, Item in ipairs(Value) do
                    if type(Item) ~= "number" or Item < 0 or math.floor(Item) ~= Item then
                        self:Error("[" .. CallingFunction .. "] " .. ParamName .. " must be a table of IDs (non-negative integers) (item " .. I .. " is invalid)")
                        return false
                    end
                end
                return true
            end
            
            -- Check for 'table_of_positive_numbers'
            if ExpectedPattern == "table_of_positive_numbers" then
                for I, Item in ipairs(Value) do
                    if type(Item) ~= "number" or Item <= 0 then
                        self:Error("[" .. CallingFunction .. "] " .. ParamName .. " must be a table of positive numbers (item " .. I .. " is invalid)")
                        return false
                    end
                end
                return true
            end
            
            -- Check for 'table_of_integers'
            if ExpectedPattern == "table_of_integers" then
                for I, Item in ipairs(Value) do
                    if type(Item) ~= "number" or math.floor(Item) ~= Item then
                        self:Error("[" .. CallingFunction .. "] " .. ParamName .. " must be a table of integers (item " .. I .. " is invalid)")
                        return false
                    end
                end
                return true
            end
            
            -- Check for 'non_empty_table'
            if ExpectedPattern == "non_empty_table" then
                if next(Value) ~= nil then
                    return true
                else
                    self:Error("[" .. CallingFunction .. "] " .. ParamName .. " cannot be an empty table")
                    return false
                end
            end
            

        end
    end
    
    -- If no types matched, log error and return false
    local ExpectedStr = type(ExpectedType) == "table" and table.concat(ExpectedType, " or ") or tostring(ExpectedType)
    self:Error("[" .. CallingFunction .. "] " .. ParamName .. " must be " .. ExpectedStr .. " (got " .. ActualType .. ")")
    return false
end

-- Validates function parameters using the sanitization system
---
--- **Usage Examples:**
--- ```lua
--- -- Basic validation
--- if not self:ValidateParams({
---     {PlayerName, "non_empty_string", "PlayerName"},
---     {NpcIds, "table_of_ids", "NpcIds"},
---     {Range, "positive_number", "Range"}
--- }) then
---     return false
--- end
---
--- -- With optional parameters
--- if not self:ValidateParams({
---     {ItemId, "id", "ItemId"},
---     {Timeout, "positive_number", "Timeout", true}, -- AllowNil = true
---     {Options, "table", "Options", true}
--- }) then
---     return false
--- end
---
--- -- Multiple allowed types
--- if not self:ValidateParams({
---     {SearchCriteria, {"string", "table_of_strings"}, "SearchCriteria"},
---     {Coords, {"number", "table_of_numbers"}, "Coords"}
--- }) then
---     return false
--- end
--- ```
---
---@param Params table Array of parameter specs: {Value, ExpectedType, ParamName, AllowNil}
---   - **Value**: The parameter value to validate
---   - **ExpectedType**: Type(s) to validate against (see Sanitize documentation for all types)
---   - **ParamName**: Name for error messages (optional, defaults to "Parameter N")
---   - **AllowNil**: Whether nil is acceptable (optional, defaults to false)
---@return boolean AllValid True if all parameters are valid, false otherwise (errors logged via self:Error)
function Slib:ValidateParams(Params)
    -- Get calling function name for better error messages
    local CallingFunction = "Unknown"
    local Info = debug.getinfo(2, "n")
    if Info and Info.name then
        CallingFunction = Info.name
    end
    
    if not Params or type(Params) ~= "table" then
        self:Error("[" .. CallingFunction .. "] ValidateParams requires a table of parameter specifications")
        return false
    end
    
    for I, ParamSpec in ipairs(Params) do
        if type(ParamSpec) ~= "table" then
            self:Error("[" .. CallingFunction .. "] Parameter specification " .. I .. " must be a table")
            return false
        end
        
        -- Extract parameters with explicit nil checking to handle false values
        local Value
        if ParamSpec[1] ~= nil then
            Value = ParamSpec[1]
        else
            Value = ParamSpec.Value
        end
        
        local ExpectedType = ParamSpec[2] or ParamSpec.ExpectedType
        local ParamName = ParamSpec[3] or ParamSpec.ParamName or ("Parameter " .. I)
        
        local AllowNil
        if ParamSpec[4] ~= nil then
            AllowNil = ParamSpec[4]
        else
            AllowNil = ParamSpec.AllowNil or false
        end
        
        if not self:Sanitize(Value, ExpectedType, ParamName, AllowNil, CallingFunction) then
            return false
        end
    end
    
    return true
end

-- ##################################
-- #                                #
-- #       UTILITY FUNCTIONS        #
-- #                                #
-- ##################################

-- Generic sleep function that automatically determines the best precision based on duration
---@param Duration number The sleep duration (must be positive)
---@param Unit string The time unit: "ms", "s", "m", "h", "tick" (milliseconds, seconds, minutes, hours, ticks)
---@return boolean success True if sleep completed successfully, false if interrupted or invalid parameters
function Slib:Sleep(Duration, Unit)
    -- Parameter validation
    if not self:ValidateParams({
        {Duration, "positive_number", "Duration"},
        {Unit, "string", "Unit"}
    }) then
        return false
    end
    
    -- Normalize unit to lowercase
    Unit = string.lower(Unit)
    
    -- Handle tick-based sleep separately
    if Unit == "tick" or Unit == "ticks" or Unit == "t" then
        local StartTick = API.Get_tick()
        local TargetTick = StartTick + Duration
        
        while API.Read_LoopyLoop() and API.Get_tick() < TargetTick do
            -- Yield CPU briefly while waiting for ticks
            collectgarbage("step", 1)
        end
        
        return API.Get_tick() >= TargetTick
    end
    
    -- Convert duration to seconds and implement sleep logic for time-based units
    local TargetDuration
    local YieldInterval
    
    if Unit == "ms" or Unit == "milli" or Unit == "millisecond" or Unit == "milliseconds" then
        TargetDuration = Duration / 1000
        YieldInterval = 0.001  -- 1ms yield for precision
    elseif Unit == "s" or Unit == "sec" or Unit == "second" or Unit == "seconds" then
        TargetDuration = Duration
        YieldInterval = 0.01   -- 10ms yield for balance
    elseif Unit == "m" or Unit == "min" or Unit == "minute" or Unit == "minutes" then
        TargetDuration = Duration * 60
        YieldInterval = 0.1    -- 100ms yield for longer sleeps
    elseif Unit == "h" or Unit == "hr" or Unit == "hour" or Unit == "hours" then
        TargetDuration = Duration * 3600
        YieldInterval = 0.5    -- 500ms yield for very long sleeps
    else
        self:Error("Invalid time unit: " .. Unit .. ". Valid units: ms, s, m, h, tick")
        return false
    end
    
    -- Implement sleep logic
    local StartTime = os.clock()
    local LastYield = StartTime
    
    while API.Read_LoopyLoop() and (os.clock() - StartTime) < TargetDuration do
        -- Yield CPU at appropriate intervals based on duration
        if (os.clock() - LastYield) >= YieldInterval then
            -- Force garbage collection periodically to yield CPU
            collectgarbage("step", 1)
            LastYield = os.clock()
        end
    end
    
    return (os.clock() - StartTime) >= TargetDuration
end

-- Sleeps for a random duration between min and max values
---@param MinDuration number The minimum sleep duration (must be positive)
---@param MaxDuration number The maximum sleep duration (must be greater than MinDuration)
---@param Unit string The time unit: "ms", "s", "m", "h", "tick" (milliseconds, seconds, minutes, hours, ticks)
---@return boolean success True if sleep completed successfully, false if interrupted or invalid parameters
function Slib:RandomSleep(MinDuration, MaxDuration, Unit)
    -- Parameter validation
    if not self:ValidateParams({
        {MinDuration, "positive_number", "MinDuration"},
        {MaxDuration, "positive_number", "MaxDuration"},
        {Unit, "string", "Unit"}
    }) then
        return false
    end
    
    -- Validate min/max relationship
    if MinDuration >= MaxDuration then
        self:Error("[RandomSleep] MinDuration must be less than MaxDuration")
        return false
    end
    
    -- Generate random duration
    local Duration
    if string.lower(Unit) == "tick" or string.lower(Unit) == "ticks" or string.lower(Unit) == "t" then
        -- For ticks, use integer values
        Duration = math.random(MinDuration, MaxDuration)
        self:Info(string.format("[RandomSleep] Sleeping for %d %s", Duration, Unit))
    else
        -- For time-based units, use decimal values
        Duration = MinDuration + math.random() * (MaxDuration - MinDuration)
        self:Info(string.format("[RandomSleep] Sleeping for %.2f %s", Duration, Unit))
    end
    
    -- Use existing Sleep function
    return self:Sleep(Duration, Unit)
end

-- Sleeps until a condition is met or timeout occurs
---@param ConditionFunc function The function to check (should return boolean)
---@param TimeoutSeconds number|nil Maximum wait time in seconds (optional, default: 30)
---@param CheckIntervalMs number|nil How often to check condition in milliseconds (optional, default: 100)
---@return boolean success True if condition was met, false if timeout or error occurred
function Slib:SleepUntil(ConditionFunc, TimeoutSeconds, CheckIntervalMs)
    -- Set defaults
    TimeoutSeconds = TimeoutSeconds or 30
    CheckIntervalMs = CheckIntervalMs or 100
    
    -- Parameter validation
    if not self:ValidateParams({
        {ConditionFunc, "function", "ConditionFunc"},
        {TimeoutSeconds, "positive_number", "TimeoutSeconds"},
        {CheckIntervalMs, "positive_number", "CheckIntervalMs"}
    }) then
        return false
    end
    
    local StartTime = os.clock()
    local MaxTime = TimeoutSeconds
    local CheckCount = 0
    
    self:Info("Waiting for condition with " .. TimeoutSeconds .. "s timeout, checking every " .. CheckIntervalMs .. "ms...")
    
    while API.Read_LoopyLoop() do
        CheckCount = CheckCount + 1
        
        -- Check timeout
        if (os.clock() - StartTime) >= MaxTime then
            self:Warn("Timeout reached (" .. TimeoutSeconds .. "s) after " .. CheckCount .. " condition checks")
            return false
        end
        
        -- Test condition with error handling
        local Success, Result = pcall(ConditionFunc)
        if not Success then
            self:Error("Condition function error: " .. tostring(Result))
            return false
        end
        
        if Result then
            local Elapsed = os.clock() - StartTime
            self:Info("Condition met after " .. string.format("%.2f", Elapsed) .. " seconds (" .. CheckCount .. " checks)")
            return true
        end
        
        -- Sleep between checks
        self:Sleep(CheckIntervalMs, "ms")
    end
    
    self:Warn("Loop stopped while waiting for condition after " .. CheckCount .. " checks")
    return false
end

-- Converts a character to its corresponding Windows Virtual-Key code
-- Only supports letters (A-Z, a-z), numbers (0-9), and spaces
---@param char string Single character to convert (letters, numbers, spaces only)
---@return number|nil vkCode Virtual-Key code for the character, or nil if unsupported character
function Slib:CharToVirtualKey(char)
    -- Parameter validation
    if not self:ValidateParams({
        {char, "string", "char"}
    }) then
        self:Error("[CharToVirtualKey] Invalid character parameter")
        return nil
    end
    
    if #char ~= 1 then
        self:Error("[CharToVirtualKey] Parameter must be a single character, received: '" .. char .. "'")
        return nil
    end
    
    local byte = string.byte(char)
    
    -- Space character
    if char == " " then
        return 0x20 -- VK_SPACE
    end
    
    -- Letters A-Z (convert both uppercase and lowercase to uppercase VK codes)
    if (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122) then
        local upperChar = string.upper(char)
        return string.byte(upperChar) -- VK_A=0x41 through VK_Z=0x5A
    end
    
    -- Numbers 0-9 (Virtual-Key codes match ASCII values)
    if byte >= 48 and byte <= 57 then
        return byte -- VK_0=0x30 through VK_9=0x39
    end
    
    -- Unsupported character
    self:Error(string.format("[CharToVirtualKey] Unsupported character: '%s' (ASCII: %d, Hex: 0x%02X)", 
        char, byte, byte))
    self:Error("[CharToVirtualKey] Only letters (A-Z, a-z), numbers (0-9), and spaces are supported")
    
    return nil
end

-- ##################################
-- #                                #
-- #       DEBUG FUNCTIONS          #
-- #                                #
-- ##################################

-- Prints all the buffs currently active with detailed information
---@return boolean Success True if buffs were found and printed, false if no buffs or error occurred
function Slib:PrintBuffs()
    -- Protected API call with validation
    local Buffs = API.Buffbar_GetAllIDs()
    
    -- Check if API returned valid data
    if not Buffs then
        self:Error("API returned nil for buffs")
        return false
    end
    
    if type(Buffs) ~= "table" and type(Buffs) ~= "userdata" then
        self:Error("API returned invalid buff data type: " .. type(Buffs))
        return false
    end
    
    if #Buffs == 0 then
        self:Info("No buffs currently active")
        return false
    end
    
    self:Info("Found " .. #Buffs .. " active buffs:")
    print("")
    
    -- Safe iteration with bounds checking
    for I = 1, #Buffs do
        local Buff = Buffs[I]
        
        -- Check if buff exists and is valid
        if not Buff then
            self:Warn("Skipping nil buff at index " .. I)
            goto continue
        end
        
        if type(Buff) ~= "table" and type(Buff) ~= "userdata" then
            self:Warn("Skipping invalid buff at index " .. I .. " (type: " .. type(Buff) .. ")")
            goto continue
        end
        
        -- Format buff information with nice borders
        print("+=========================+")
        print("|         BUFF #" .. I .. "         |")
        print("+=========================+")
        print("|   ID             : " .. tostring(Buff.id or "N/A"))
        print("|   Found          : " .. tostring(Buff.found or "N/A"))
        print("|   Text           : " .. tostring(Buff.text or "N/A"))
        print("|   Conv Text      : " .. tostring(Buff.conv_text or "N/A"))
        
        -- Add additional fields if they exist
        if Buff.duration then
            print("|   Duration       : " .. tostring(Buff.duration))
        end
        
        if Buff.remaining then
            print("|   Remaining      : " .. tostring(Buff.remaining))
        end
        
        if Buff.stacks then
            print("|   Stacks         : " .. tostring(Buff.stacks))
        end
        
        if Buff.icon then
            print("|   Icon           : " .. tostring(Buff.icon))
        end
        
        print("+=========================+")
        print("")
        
        ::continue::
    end
    
    self:Info("Buff scan completed successfully")
    return true
end

-- Prints all the debuffs currently active with detailed information
---@return boolean Success True if debuffs were found and printed, false if no debuffs or error occurred
function Slib:PrintDebuffs()
    -- Protected API call with validation
    local Debuffs = API.DeBuffbar_GetAllIDs()
    
    -- Check if API returned valid data
    if not Debuffs then
        self:Error("API returned nil for debuffs")
        return false
    end
    
    if type(Debuffs) ~= "table" and type(Debuffs) ~= "userdata" then
        self:Error("API returned invalid debuff data type: " .. type(Debuffs))
        return false
    end
    
    if #Debuffs == 0 then
        self:Info("No debuffs currently active")
        return false
    end
    
    self:Info("Found " .. #Debuffs .. " active debuffs:")
    print("")
    
    -- Safe iteration with bounds checking
    for I = 1, #Debuffs do
        local Debuff = Debuffs[I]
        
        -- Check if debuff exists and is valid
        if not Debuff then
            self:Warn("Skipping nil debuff at index " .. I)
            goto continue
        end
        
        if type(Debuff) ~= "table" and type(Debuff) ~= "userdata" then
            self:Warn("Skipping invalid debuff at index " .. I .. " (type: " .. type(Debuff) .. ")")
            goto continue
        end
        
        -- Format debuff information with nice borders
        print("+=========================+")
        print("|        DEBUFF #" .. I .. "        |")
        print("+=========================+")
        print("|   ID             : " .. tostring(Debuff.id or "N/A"))
        print("|   Found          : " .. tostring(Debuff.found or "N/A"))
        print("|   Text           : " .. tostring(Debuff.text or "N/A"))
        print("|   Conv Text      : " .. tostring(Debuff.conv_text or "N/A"))
        
        -- Add additional fields if they exist
        if Debuff.duration then
            print("|   Duration       : " .. tostring(Debuff.duration))
        end
        
        if Debuff.remaining then
            print("|   Remaining      : " .. tostring(Debuff.remaining))
        end
        
        if Debuff.stacks then
            print("|   Stacks         : " .. tostring(Debuff.stacks))
        end
        
        if Debuff.icon then
            print("|   Icon           : " .. tostring(Debuff.icon))
        end
        
        print("+=========================+")
        print("")
        
        ::continue::
    end
    
    self:Info("Debuff scan completed successfully")
    return true
end

-- Prints container contents with detailed information for each item (93 = inventory, 94 = equipment, 95 = bank)
---@param ContainerId number
---@return boolean Success
function Slib:PrintContainer(ContainerId)
    -- Parameter validation
    if not self:Sanitize(ContainerId, "number", "ContainerId") then
        return false
    end
    
    -- API call to get container contents
    local Items = API.Container_Get_all(ContainerId)
    
    -- Check if API returned valid data
    if not Items then
        self:Error("API returned nil for container " .. ContainerId)
        return false
    end
    
    if type(Items) ~= "table" and type(Items) ~= "userdata" then
        self:Error("API returned invalid container data type: " .. type(Items))
        return false
    end
    
    if #Items == 0 then
        self:Info("Container " .. ContainerId .. " is empty")
        return false
    end

    -- Count valid items (items with valid item_id >= 0)
    local ValidItemCount = 0
    for I = 1, #Items do
        local Item = Items[I]
        if Item and Item.item_id and Item.item_id >= 0 then
            ValidItemCount = ValidItemCount + 1
        end
    end
    
    if ValidItemCount == 0 then
        self:Info("Container " .. ContainerId .. " has no valid items")
        return false
    end
    
    self:Info("=== Container " .. ContainerId .. " Contents ===")
    self:Info("Valid items: " .. ValidItemCount .. " / " .. #Items .. " total slots")
    print("")

    -- Safe iteration with bounds checking
    for I = 1, #Items do
        local Item = Items[I]
        local ItemName = nil
        if Item and Item.item_id and Item.item_id >= 0 and Item.Get then
            local Success, ItemData = pcall(Item.Get, Item, Item.item_id)
            if Success and ItemData and ItemData.name then
                ItemName = ItemData.name
            end
        elseif Item and Item.item_id and Item.item_id >= 0 and Item.Get == nil and Item.Get ~= nil then
            -- fallback if Item is not a class instance, try global Item
            if Item.Get then
                local Success, ItemData = pcall(Item.Get, Item.item_id)
                if Success and ItemData and ItemData.name then
                    ItemName = ItemData.name
                end
            end
        elseif _G.Item and _G.Item.Get then
            local Success, ItemData = pcall(_G.Item.Get, _G.Item, Item.item_id)
            if Success and ItemData and ItemData.name then
                ItemName = ItemData.name
            end
        end
        
        -- Check if item exists and is valid
        if not Item then
            self:Warn("Skipping nil item at slot " .. I)
            goto continue
        end
        
        if type(Item) ~= "table" and type(Item) ~= "userdata" then
            self:Warn("Skipping invalid item at slot " .. I .. " (type: " .. type(Item) .. ")")
            goto continue
        end
        
        -- Only print items that have a valid item_id (>= 0)
        if not Item.item_id or Item.item_id < 0 then
            goto continue
        end
        
        -- Format item information with nice borders
        print("+========================+")
        print("|      ITEM SLOT #" .. I .. "      |")
        print("+========================+")
        print("|   Item Name      : " .. tostring(ItemName or "N/A"))
        print("|   Item ID        : " .. tostring(Item.item_id or "N/A"))
        print("|   Item Stack     : " .. tostring(Item.item_stack or "N/A"))
        print("|   Item Slot      : " .. tostring(Item.item_slot or "N/A"))
        
        -- Print Extra_mem table if it exists
        print("|   Extra_mem      :")
        if Item.Extra_mem then
            if type(Item.Extra_mem) == "table" or type(Item.Extra_mem) == "userdata" then
                local MemCount = 0
                for K, V in pairs(Item.Extra_mem) do
                    print("|     " .. tostring(K) .. " : " .. tostring(V))
                    MemCount = MemCount + 1
                end
                if MemCount == 0 then
                    print("|     (empty)")
                end
            else
                print("|     (type: " .. type(Item.Extra_mem) .. ", value: " .. tostring(Item.Extra_mem) .. ")")
            end
        else
            print("|     N/A")
        end
        
        -- Print Extra_ints table if it exists
        print("|   Extra_ints     :")
        if Item.Extra_ints then
            if type(Item.Extra_ints) == "table" or type(Item.Extra_ints) == "userdata" then
                local IntCount = 0
                for K, V in pairs(Item.Extra_ints) do
                    print("|     " .. tostring(K) .. " : " .. tostring(V))
                    IntCount = IntCount + 1
                end
                if IntCount == 0 then
                    print("|     (empty)")
                end
            else
                print("|     (type: " .. type(Item.Extra_ints) .. ", value: " .. tostring(Item.Extra_ints) .. ")")
            end
        else
            print("|     N/A")
        end
        
        print("+========================+")
        print("")
        
        ::continue::
    end
    
    self:Info("Container scan completed successfully")
    return true
end

-- Prints all abilities from specified ability bar(s)
---@param BarId number|table
---@return boolean Success
function Slib:PrintAbilityBar(BarId)
    -- Parameter validation
    if not self:Sanitize(BarId, {"number", "table_of_numbers"}, "BarId") then
        return false
    end
    
    -- Ensure BarId is a table for consistent processing
    local BarTable = type(BarId) == "table" and BarId or {BarId}
    
    -- Validate range (0-4) for each bar ID
    for I, Bar in ipairs(BarTable) do
        if Bar < 0 or Bar > 4 then
            self:Error("BarId must be between 0-4, got: " .. Bar .. " at index " .. I)
            return false
        end
    end
    
    local TotalAbilities = 0
    local ProcessedBars = 0
    
    -- Process each ability bar
    for _, Bar in ipairs(BarTable) do
        local BarInfo = API.GetABarInfo(Bar)
        
        if not BarInfo then
            self:Warn("Unable to get ability bar " .. Bar)
            goto continue
        end
        
        if type(BarInfo) ~= "table" and type(BarInfo) ~= "userdata" then
            self:Warn("Invalid data type for bar " .. Bar .. ": " .. type(BarInfo))
            goto continue
        end
        
        if #BarInfo == 0 then
            self:Info("Ability bar " .. Bar .. " is empty")
            goto continue
        end
        
        -- Count valid abilities in this bar
        local ValidAbilities = 0
        for I = 1, #BarInfo do
            local Ability = BarInfo[I]
            if Ability and Ability.id and Ability.id ~= 65535 then
                ValidAbilities = ValidAbilities + 1
            end
        end
        
        if ValidAbilities == 0 then
            self:Info("No valid abilities found in bar " .. Bar)
            goto continue
        end
        
        self:Info("=== Ability Bar " .. Bar .. " ===")
        self:Info("Found " .. ValidAbilities .. " abilities:")
        print("")
        
        -- Safe iteration through abilities
        for I = 1, #BarInfo do
            local Ability = BarInfo[I]
            
            -- Check if ability exists and is valid
            if not Ability then
                self:Warn("Skipping nil ability at slot " .. I .. " in bar " .. Bar)
                goto continue_ability
            end
            
            if type(Ability) ~= "table" and type(Ability) ~= "userdata" then
                self:Warn("Skipping invalid ability at slot " .. I .. " in bar " .. Bar .. " (type: " .. type(Ability) .. ")")
                goto continue_ability
            end
            
            -- Skip empty/invalid abilities (ID 65535 is empty slot)
            if not Ability.id or Ability.id == 65535 then
                goto continue_ability
            end
            
            -- Format ability information with nice borders
            print("+========================+")
            print("|     ABILITY SLOT #" .. string.format("%-2s", I) .. "   |")
            print("|        (Bar " .. Bar .. ")         |")
            print("+========================+")
            print("|   slot           : " .. tostring(Ability.slot or "N/A"))
            print("|   id             : " .. tostring(Ability.id or "N/A"))
            print("|   name           : " .. tostring(Ability.name or "N/A"))
            print("|   hotkey         : " .. tostring(Ability.hotkey or "N/A"))
            print("|   cooldown_timer : " .. tostring(Ability.cooldown_timer or "N/A"))
            print("|   action         : " .. tostring(Ability.action or "N/A"))
            print("|   enabled        : " .. tostring(Ability.enabled or "N/A"))

            -- Print ability info if it exists
            if Ability.info then
                local Info = Ability.info
                print("|                        ")
                print("|     --- info ---       ")
                print("|   x              : " .. tostring(Info.x or "N/A"))
                print("|   xs             : " .. tostring(Info.xs or "N/A"))
                print("|   y              : " .. tostring(Info.y or "N/A"))
                print("|   ys             : " .. tostring(Info.ys or "N/A"))
                print("|   box_x          : " .. tostring(Info.box_x or "N/A"))
                print("|   box_y          : " .. tostring(Info.box_y or "N/A"))
                print("|   scroll_y       : " .. tostring(Info.scroll_y or "N/A"))
                print("|   id1            : " .. tostring(Info.id1 or "N/A"))
                print("|   id2            : " .. tostring(Info.id2 or "N/A"))
                print("|   id3            : " .. tostring(Info.id3 or "N/A"))
                print("|   itemid1        : " .. tostring(Info.itemid1 or "N/A"))
                print("|   itemid1_size   : " .. tostring(Info.itemid1_size or "N/A"))
                print("|   itemid2        : " .. tostring(Info.itemid2 or "N/A"))
                print("|   hov            : " .. tostring(Info.hov or "N/A"))
                print("|   textids        : " .. tostring(Info.textids or "N/A"))
                print("|   textitem       : " .. tostring(Info.textitem or "N/A"))
                print("|   memloc         : " .. tostring(Info.memloc or "N/A"))
                print("|   memloctop      : " .. tostring(Info.memloctop or "N/A"))
                print("|   index          : " .. tostring(Info.index or "N/A"))
                print("|   fullpath       : " .. tostring(Info.fullpath or "N/A"))
                print("|   fullIDpath     : " .. tostring(Info.fullIDpath or "N/A"))
                print("|   notvisible     : " .. tostring(Info.notvisible or "N/A"))
                print("|   OP             : " .. tostring(Info.OP or "N/A"))
                print("|   xy             : " .. tostring(Info.xy or "N/A"))
                print("|   xy.x           : " .. tostring(Info.xy.x or "N/A"))
                print("|   xy.y           : " .. tostring(Info.xy.y or "N/A"))
            else
                print("|   info           : N/A")
            end
            
            print("+========================+")
            print("")
            
            TotalAbilities = TotalAbilities + 1
            
            ::continue_ability::
        end
        
        ProcessedBars = ProcessedBars + 1
        
        ::continue::
    end
    
    if ProcessedBars == 0 then
        self:Error("No ability bars could be processed")
        return false
    end
    
    self:Info("Ability scan completed - processed " .. ProcessedBars .. " bar(s) with " .. TotalAbilities .. " total abilities")
    return true
end

-- Prints all objects with specified parameters
---@param Id number|table
---@param Range number
---@param Type number|table
---@return boolean Success
function Slib:PrintObjects(Id, Range, Type)
    -- Parameter validation
    if not self:ValidateParams({
        {Id, {"number", "table_of_numbers"}, "Id"},
        {Range, "non_negative_number", "Range"},
        {Type, {"number", "table_of_numbers"}, "Type"}
    }) then
        return false
    end
    
    -- Ensure Id and Type are tables
    local IdTable = type(Id) == "table" and Id or {Id}
    local TypeTable = type(Type) == "table" and Type or {Type}
    
    -- Direct API call
    local Objects = API.GetAllObjArray1(IdTable, Range, TypeTable)
    
    -- Check if API returned valid data
    if not Objects then
        self:Error("API returned nil")
        return false
    end
    
    if type(Objects) ~= "table" and type(Objects) ~= "userdata" then
        self:Error("API returned invalid data type: " .. type(Objects))
        return false
    end
    
    if #Objects == 0 then
        self:Info("No objects found matching criteria")
        return false
    end
    
    self:Info("Found " .. #Objects .. " objects:")
    
    -- Safe iteration with bounds checking
    for I = 1, #Objects do
        local Object = Objects[I]
        
        -- Check if object exists and is valid
        if not Object then
            self:Warn("Skipping nil object at index " .. I)
            goto continue
        end
        
        if type(Object) ~= "table" and type(Object) ~= "userdata" then
            self:Warn("Skipping invalid object at index " .. I .. " (type: " .. type(Object) .. ")")
            goto continue
        end
        
        -- Direct object printing
        print("+==============================+")
        print("|          OBJECT #" .. I .. "           |")
        print("+==============================+")
        print("|    Name           : " .. tostring(Object.Name or "N/A"))
        print("|    Id             : " .. tostring(Object.Id or "N/A"))
        print("|    Type           : " .. tostring(Object.Type or "N/A"))
        print("|    Life           : " .. tostring(Object.Life or "N/A"))
        print("|    Action         : " .. tostring(Object.Action or "N/A"))
        print("|    Anim           : " .. tostring(Object.Anim or "N/A"))
        print("|    Amount         : " .. tostring(Object.Amount or "N/A"))
        print("|    Distance       : " .. tostring(Object.Distance or "N/A"))
        print("|    Floor          : " .. tostring(Object.Floor or "N/A"))
        print("|    CalcX          : " .. tostring(Object.CalcX or "N/A"))
        print("|    CalcY          : " .. tostring(Object.CalcY or "N/A"))
        print("|    TileX          : " .. tostring(Object.TileX or "N/A") .. " (÷512: " .. tostring(Object.TileX and (Object.TileX/512) or "N/A") .. ")")
        print("|    TileY          : " .. tostring(Object.TileY or "N/A") .. " (÷512: " .. tostring(Object.TileY and (Object.TileY/512) or "N/A") .. ")")
        print("|    TileZ          : " .. tostring(Object.TileZ or "N/A") .. " (÷512: " .. tostring(Object.TileZ and (Object.TileZ/512) or "N/A") .. ")")
        print("|    Tile_XYZ.x     : " .. tostring(Object.Tile_XYZ and Object.Tile_XYZ.x or "N/A"))
        print("|    Tile_XYZ.y     : " .. tostring(Object.Tile_XYZ and Object.Tile_XYZ.y or "N/A"))
        print("|    Tile_XYZ.z     : " .. tostring(Object.Tile_XYZ and Object.Tile_XYZ.z or "N/A"))
        print("|    Pixel_XYZ.x    : " .. tostring(Object.Pixel_XYZ and Object.Pixel_XYZ.x or "N/A"))
        print("|    Pixel_XYZ.y    : " .. tostring(Object.Pixel_XYZ and Object.Pixel_XYZ.y or "N/A"))
        print("|    Pixel_XYZ.z    : " .. tostring(Object.Pixel_XYZ and Object.Pixel_XYZ.z or "N/A"))
        print("|    Mem            : " .. tostring(Object.Mem or "N/A"))
        print("|    MemE           : " .. tostring(Object.MemE or "N/A"))
        print("|    Unique_Id      : " .. tostring(Object.Unique_Id or "N/A"))
        print("|    Cmb_lv         : " .. tostring(Object.Cmb_lv or "N/A"))
        print("|    ItemIndex      : " .. tostring(Object.ItemIndex or "N/A"))
        print("|    Bool1          : " .. tostring(Object.Bool1 or "N/A"))
        print("|    ViewP          : " .. tostring(Object.ViewP or "N/A"))
        print("|    ViewF          : " .. tostring(Object.ViewF or "N/A"))
        print("+==============================+")
        print("")
        
        ::continue::
    end
    
    return true
end

-- Prints info about specified VarBit(s)
---@param Vb number|table
---@return boolean Success
function Slib:PrintVb(Vb)
    -- Parameter validation
    if not self:Sanitize(Vb, {"number", "table_of_numbers"}, "Vb") then
        return false
    end
    
    -- Ensure Vb is a table for consistent processing
    local VbTable = type(Vb) == "table" and Vb or {Vb}
    
    local TotalFound = 0
    local ProcessedVbs = 0
    
    -- Process each VarBit
    for _, VbId in ipairs(VbTable) do
        local Var = API.VB_FindPSettinOrder(VbId)
        
        if not Var then
            self:Warn("VarBit " .. VbId .. " not found")
            goto continue
        end
        
        if type(Var) ~= "table" and type(Var) ~= "userdata" then
            self:Warn("Invalid data type for VarBit " .. VbId .. ": " .. type(Var))
            goto continue
        end
        
        -- Format VarBit information with nice borders
        print("+========================+")
        print("|      VARBIT #" .. string.format("%-2s", VbId) .. "      |")
        print("+========================+")
        print("|   id             : " .. tostring(Var.id or "N/A"))
        print("|   state          : " .. tostring(Var.state or "N/A"))
        print("|   addr           : " .. tostring(Var.addr or "N/A"))
        print("|   indexaddr_orig : " .. tostring(Var.indexaddr_orig or "N/A"))
        print("+========================+")
        print("")
        
        TotalFound = TotalFound + 1
        ProcessedVbs = ProcessedVbs + 1
        
        ::continue::
    end
    
    if ProcessedVbs == 0 then
        self:Error("No VarBits could be processed")
        return false
    end
    
    self:Info("VarBit scan completed - processed " .. ProcessedVbs .. " VarBit(s), found " .. TotalFound .. " valid")
    return true
end

-- Prints detailed information about interface elements
---@param TargetUnder boolean
---@param InterfaceToScan table
---@return boolean Success
function Slib:PrintInterfaceInfo(TargetUnder, InterfaceToScan)
    -- Parameter validation
    if not self:ValidateParams({
        {TargetUnder, "boolean", "TargetUnder"},
        {InterfaceToScan, "table", "InterfaceToScan"}
    }) then
        return false
    end
    
    -- API call to get interface elements
    local Interface = API.ScanForInterfaceTest2Get(TargetUnder, InterfaceToScan)
    
    if not Interface then
        self:Error("Failed to scan interface")
        return false
    end
    
    if type(Interface) ~= "table" and type(Interface) ~= "userdata" then
        self:Error("Invalid data type returned from API: " .. type(Interface))
        return false
    end
    
    if #Interface == 0 then
        self:Info("No interface elements found")
        return false
    end
    
    self:Info("Found " .. #Interface .. " interface elements:")
    print("")
    
    -- Safe iteration through interface elements
    for I = 1, #Interface do
        local Element = Interface[I]
        
        -- Check if element exists and is valid
        if not Element then
            self:Warn("Skipping nil element at index " .. I)
            goto continue_element
        end
        
        if type(Element) ~= "table" and type(Element) ~= "userdata" then
            self:Warn("Skipping invalid element at index " .. I .. " (type: " .. type(Element) .. ")")
            goto continue_element
        end
        
        -- Format interface element information with nice borders
        print("+=============================================+")
        print("|       ELEMENT #" .. string.format("%-2s", I) .. "                    |")
        print("+=============================================+")
        print("|   x              : " .. tostring(Element.x or "N/A"))
        print("|   xs             : " .. tostring(Element.xs or "N/A"))
        print("|   y              : " .. tostring(Element.y or "N/A"))
        print("|   ys             : " .. tostring(Element.ys or "N/A"))
        print("|   box_x          : " .. tostring(Element.box_x or "N/A"))
        print("|   box_y          : " .. tostring(Element.box_y or "N/A"))
        print("|   scroll_y       : " .. tostring(Element.scroll_y or "N/A"))
        print("|   id1            : " .. tostring(Element.id1 or "N/A"))
        print("|   id2            : " .. tostring(Element.id2 or "N/A"))
        print("|   id3            : " .. tostring(Element.id3 or "N/A"))
        print("|   itemid1        : " .. tostring(Element.itemid1 or "N/A"))
        print("|   itemid1_size   : " .. tostring(Element.itemid1_size or "N/A"))
        print("|   itemid2        : " .. tostring(Element.itemid2 or "N/A"))
        print("|   hov            : " .. tostring(Element.hov or "N/A"))
        print("|   textids        : " .. tostring(Element.textids or "N/A"))
        print("|   textitem       : " .. tostring(Element.textitem or "N/A"))
        print("|   memloc         : " .. tostring(Element.memloc or "N/A"))
        print("|   memloctop      : " .. tostring(Element.memloctop or "N/A"))
        print("|   index          : " .. tostring(Element.index or "N/A"))
        print("|   fullpath       : " .. tostring(Element.fullpath or "N/A"))
        print("|   fullIDpath     : " .. tostring(Element.fullIDpath or "N/A"))
        print("|   notvisible     : " .. tostring(Element.notvisible or "N/A"))
        print("|   OP             : " .. tostring(Element.OP or "N/A"))
        print("|   xy             : " .. tostring(Element.xy or "N/A"))
        print("|   xy.x           : " .. tostring(Element.xy.x or "N/A"))
        print("|   xy.y           : " .. tostring(Element.xy.y or "N/A"))
        
        -- Add memory read information if memloc is available
        if Element.memloc and type(Element.memloc) == "number" then
            print("|                                ")
            print("|     --- MEMORY READS ---       ")
            print("|                                ")
            
            -- Define API constants
            local ApiConstants = {
                {name = "I_00textP", value = API.I_00textP},
                {name = "I_itemids3", value = API.I_itemids3},
                {name = "I_itemids", value = API.I_itemids},
                {name = "I_itemstack", value = API.I_itemstack},
                {name = "I_slides", value = API.I_slides},
                {name = "I_buffb", value = API.I_buffb}
            }
            
            -- Group memory reads by function type
            local MemReadGroups = {
                {
                    name = "Mem_Read_char",
                    func = API.Mem_Read_char,
                    reads = {
                        {name = "memloc", offset = 0}
                    }
                },
                {
                    name = "Mem_Read_short", 
                    func = API.Mem_Read_short,
                    reads = {
                        {name = "memloc", offset = 0}
                    }
                },
                {
                    name = "Mem_Read_int",
                    func = API.Mem_Read_int,
                    reads = {
                        {name = "memloc", offset = 0}
                    }
                },
                {
                    name = "Mem_Read_uint64",
                    func = API.Mem_Read_uint64,
                    reads = {
                        {name = "memloc", offset = 0}
                    }
                },
                {
                    name = "ReadCharsLimit",
                    func = API.ReadCharsLimit,
                    reads = {}
                }
            }
            
            -- Add constant combinations to each group
            for _, Constant in ipairs(ApiConstants) do
                if Constant.value and type(Constant.value) == "number" then
                    -- Add to Mem_Read functions
                    for _, Group in ipairs(MemReadGroups) do
                        if Group.name ~= "ReadCharsLimit" then
                            table.insert(Group.reads, {name = "memloc+" .. Constant.name, offset = Constant.value})
                        end
                    end
                    
                    -- Add to ReadCharsLimit group
                    table.insert(MemReadGroups[5].reads, {name = "memloc+" .. Constant.name, offset = Constant.value, limit = 255})
                end
            end
            
            -- Build all function names first to determine max width
            local allFunctionNames = {}
            for _, Group in ipairs(MemReadGroups) do
                for _, Read in ipairs(Group.reads) do
                    local FunctionName = Group.name .. "(" .. Read.name .. ")"
                    if Group.func == API.ReadCharsLimit then
                        FunctionName = Group.name .. "(" .. Read.name .. ", 255)"
                    end
                    table.insert(allFunctionNames, FunctionName)
                end
            end
            local maxFuncNameLen = 0
            for _, name in ipairs(allFunctionNames) do
                if #name > maxFuncNameLen then maxFuncNameLen = #name end
            end
            maxFuncNameLen = math.max(maxFuncNameLen, 20)  -- minimum width for aesthetics
            local formatString = string.format("|   %%-%ds : %%s", maxFuncNameLen)

            -- Process each group
            local funcIdx = 1
            for _, Group in ipairs(MemReadGroups) do
                for _, Read in ipairs(Group.reads) do
                    local FunctionName = Group.name .. "(" .. Read.name .. ")"
                    if Group.func == API.ReadCharsLimit then
                        FunctionName = Group.name .. "(" .. Read.name .. ", 255)"
                    end
                    local Success, Result = pcall(function()
                        if Group.func == API.ReadCharsLimit then
                            return Group.func(Element.memloc + Read.offset, Read.limit)
                        else
                            return Group.func(Element.memloc + Read.offset)
                        end
                    end)
                    if Success and Result then
                        local FormattedResult
                        local ResultType = type(Result)
                        if ResultType == "number" then
                            -- Helper function to safely format numbers
                            local function SafeFormat(result, hexFormat, hexWidth)
                                -- Check if number is finite and within safe integer range
                                if result ~= result then -- NaN check
                                    return "NaN"
                                elseif result == math.huge then
                                    return "Infinity"
                                elseif result == -math.huge then
                                    return "-Infinity"
                                elseif math.abs(result) > 9007199254740991 then -- 2^53 - 1 (safe integer limit)
                                    return string.format("%.0f (too large for hex)", result)
                                elseif result < 0 then
                                    return string.format("%.0f (negative)", result)
                                elseif math.floor(result) ~= result then
                                    return string.format("%.6f (fractional)", result)
                                else
                                    -- Safe to format as integer and hex
                                    local success, formattedHex = pcall(string.format, hexFormat, result)
                                    local success2, formattedDec = pcall(string.format, "%.0f", result)
                                    if success and success2 then
                                        return formattedHex .. " (" .. formattedDec .. ")"
                                    else
                                        return tostring(result) .. " (format error)"
                                    end
                                end
                            end
                            
                            if Group.func == API.Mem_Read_char then
                                FormattedResult = SafeFormat(Result, "0x%02X", 2)
                            elseif Group.func == API.Mem_Read_short then
                                FormattedResult = SafeFormat(Result, "0x%04X", 4)
                            elseif Group.func == API.Mem_Read_int then
                                FormattedResult = SafeFormat(Result, "0x%08X", 8)
                            elseif Group.func == API.Mem_Read_uint64 then
                                FormattedResult = SafeFormat(Result, "0x%016X", 16)
                            else
                                FormattedResult = tostring(Result)
                            end
                        elseif ResultType == "string" then
                            if Result == "" then
                                FormattedResult = '"" (empty string)'
                            else
                                local EscapedResult = string.gsub(Result, "[\0-\31\127-\255]", function(c)
                                    local byteVal = string.byte(c)
                                    if byteVal and byteVal >= 0 and byteVal <= 255 then
                                        return string.format("\\x%02X", byteVal)
                                    else
                                        return "\\x??"
                                    end
                                end)
                                if string.len(EscapedResult) > 50 then
                                    EscapedResult = string.sub(EscapedResult, 1, 47) .. "..."
                                end
                                FormattedResult = '"' .. EscapedResult .. '"'
                            end
                        else
                            -- Handle other types (boolean, table, etc.)
                            FormattedResult = tostring(Result) .. " (" .. ResultType .. ")"
                        end
                        
                        -- Create function name with proper alignment
                        local FunctionName = Group.name .. "(" .. Read.name .. ")"
                        if Group.func == API.ReadCharsLimit then
                            FunctionName = Group.name .. "(" .. Read.name .. ", 255)"
                        end
                        
                        print(string.format(formatString, FunctionName, FormattedResult))
                    else
                        -- Create function name with proper alignment
                        local FunctionName = Group.name .. "(" .. Read.name .. ")"
                        if Group.func == API.ReadCharsLimit then
                            FunctionName = Group.name .. "(" .. Read.name .. ", 255)"
                        end
                        
                        local ErrorMsg = "Error"
                        if not Success then
                            ErrorMsg = "Failed"
                        elseif not Result then
                            ErrorMsg = "No Result"
                        end
                        
                        print(string.format(formatString, FunctionName, ErrorMsg))
                    end
                end
            end
        else
            print("|                                ")
            print("|     --- MEMORY READS ---       ")
            print("|   No memloc available          ")
        end
        
        print("+=============================================+")
        print("")
        
        ::continue_element::
    end
    
    self:Info("Interface scan completed successfully")
    return true
end

-- Prints all fields of a QuestData object
---@param QuestIdsOrNames number|string|table
---@return boolean Success
function Slib:PrintQuestData(QuestIdsOrNames)
    -- Parameter validation
    if not self:Sanitize(QuestIdsOrNames, {"number", "string", "table_of_strings", "table_of_numbers"}, "QuestIdsOrNames") then
        return false
    end
    
    -- Ensure QuestIdsOrNames is a table for consistent processing
    local QuestTable = type(QuestIdsOrNames) == "table" and QuestIdsOrNames or {QuestIdsOrNames}
    
    local TotalFound = 0
    local ProcessedQuests = 0
    
    -- Process each quest
    for _, QuestId in ipairs(QuestTable) do
        -- API call to get quest data
        local QuestData = Quest:Get(QuestId)
        
        if not QuestData then
            self:Warn("Quest not found: " .. tostring(QuestId))
            goto continue
        end
        
        if type(QuestData) ~= "table" and type(QuestData) ~= "userdata" then
            self:Warn("Invalid quest data type for " .. tostring(QuestId) .. ": " .. type(QuestData))
            goto continue
        end

        self:Info("=== Quest: " .. tostring(QuestId) .. " ===")
        print("")
    
        -- Format quest information with nice borders
        print("+================================+")
        print("|           QUEST DATA           |")
        print("+================================+")
        print("|   id                 : " .. tostring(QuestData.id or "N/A"))
        print("|   name               : " .. tostring(QuestData.name or "N/A"))
        print("|   list_name          : " .. tostring(QuestData.list_name or "N/A"))
        print("|   members            : " .. tostring(QuestData.members or "N/A"))
        print("|   category           : " .. tostring(QuestData.category or "N/A"))
        print("|   difficulty         : " .. tostring(QuestData.difficulty or "N/A"))
        print("|   points_reward      : " .. tostring(QuestData.points_reward or "N/A"))
        print("|   points_required    : " .. tostring(QuestData.points_required or "N/A"))
        print("|   progress_start_bit : " .. tostring(QuestData.progress_start_bit or "N/A"))
        print("|   progress_end_bit   : " .. tostring(QuestData.progress_end_bit or "N/A"))
        print("|   progress_varbit    : " .. tostring(QuestData.progress_varbit or "N/A"))
        print("|                                ")
        print("|     --- Methods ---            ")
        
        -- Call methods safely
        if QuestData.getProgress then
            local Success, Progress = pcall(QuestData.getProgress, QuestData)
            print("|   getProgress()      : " .. tostring(Success and Progress or "Error"))
        else
            print("|   getProgress()      : N/A")
        end
        
        if QuestData.isStarted then
            local Success, Started = pcall(QuestData.isStarted, QuestData)
            print("|   isStarted()        : " .. tostring(Success and Started or "Error"))
        else
            print("|   isStarted()        : N/A")
        end
        
        if QuestData.isComplete then
            local Success, Complete = pcall(QuestData.isComplete, QuestData)
            print("|   isComplete()       : " .. tostring(Success and Complete or "Error"))
        else
            print("|   isComplete()       : N/A")
        end
        
        print("|                                ")
        print("|   --- Required Quests ---      ")
        
        -- Print required quests with debugging
        if QuestData.required_quests then
            if (type(QuestData.required_quests) == "table" or type(QuestData.required_quests) == "userdata") and #QuestData.required_quests > 0 then
                for I, ReqQuest in ipairs(QuestData.required_quests) do
                    if ReqQuest and (type(ReqQuest) == "table" or type(ReqQuest) == "userdata") then
                        local ReqQuestId = tostring(ReqQuest.id or "N/A")
                        local ReqQuestName = tostring(ReqQuest.name or "N/A")
                        -- Split long lines to fit within border
                        print("|   [" .. I .. "] ID: " .. ReqQuestId)
                        if string.len(ReqQuestName) > 25 then
                            print("|       Name: " .. string.sub(ReqQuestName, 1, 22) .. "...")
                        else
                            print("|       Name: " .. ReqQuestName)
                        end
                    else
                        print("|   [" .. I .. "] Invalid quest data     ")
                    end
                end
            else
                print("|   None                         ")
            end
        else
            print("|   N/A                          ")
        end

        print("|                                ")
        print("|   --- Required Skills ---      ")
        
        -- Print required skills with debugging  
        if QuestData.required_skills then
            if (type(QuestData.required_skills) == "table" or type(QuestData.required_skills) == "userdata") and #QuestData.required_skills > 0 then
                for I, Skill in ipairs(QuestData.required_skills) do
                    if Skill and (type(Skill) == "table" or type(Skill) == "userdata") then
                        local SkillId = Skill.id or "N/A"
                        local SkillLevel = tostring(Skill.level or "N/A")
                        
                        -- Get skill name from API
                        local SkillName = "Unknown"
                        if SkillId ~= "N/A" then
                            local SkillData = API.GetSkillById(SkillId)
                            if SkillData and SkillData.name then
                                SkillName = SkillData.name
                            else
                                SkillName = "ID:" .. tostring(SkillId)
                            end
                        end
                        
                        print("|   [" .. I .. "] " .. SkillName .. " Level: " .. SkillLevel)
                    else
                        print("|   [" .. I .. "] Invalid skill data    ")
                    end
                end
            else
                print("|   None                         ")
            end
        else
            print("|   N/A                          ")
        end
        
        print("+================================+")
        print("")
        
        TotalFound = TotalFound + 1
        ProcessedQuests = ProcessedQuests + 1
        
        ::continue::
    end
    
    if ProcessedQuests == 0 then
        self:Error("No quests could be processed")
        return false
    end
    
    self:Info("Quest data scan completed - processed " .. ProcessedQuests .. " quest(s), found " .. TotalFound .. " valid")
    return true
end

-- Prints all items in the currency pouch with detailed information
---@return boolean Success True if currency pouch items were found and printed, false if no items or error occurred
function Slib:PrintCurrencyPouch()
    if not self.Interfaces or not self.Interfaces.CurrencyPouch then
        self:Error("CurrencyPouch interface not defined")
        return false
    end
    
    local TotalFound = 0
    local ProcessedInterfaces = 0
    
    -- Process each interface configuration
    for I = 1, #self.Interfaces.CurrencyPouch do
        local Interface = API.ScanForInterfaceTest2Get(true, self.Interfaces.CurrencyPouch[I])
        
        -- Count valid items in this interface
        local ValidItems = 0
        for _, Item in pairs(Interface) do
            if Item and Item.itemid1 and Item.itemid1 >= 0 then
                ValidItems = ValidItems + 1
            end
        end
        
        if ValidItems > 0 then
            self:Info("=== Currency Pouch Interface " .. I .. " ===")
            self:Info("Found " .. ValidItems .. " items:")
            print("")
            
            -- Process each item
            for _, Item in pairs(Interface) do
                if Item and Item.itemid1 and Item.itemid1 >= 0 then
                    TotalFound = TotalFound + 1
                    -- Format item information with nice borders
                    print("+================================+")
                    print("|      CURRENCY ITEM #" .. string.format("%-2s", TotalFound) .. "       |")
                    print("+================================+")
                    print("|   x              : " .. tostring(Item.x or "N/A"))
                    print("|   xs             : " .. tostring(Item.xs or "N/A"))
                    print("|   y              : " .. tostring(Item.y or "N/A"))
                    print("|   ys             : " .. tostring(Item.ys or "N/A"))
                    print("|   box_x          : " .. tostring(Item.box_x or "N/A"))
                    print("|   box_y          : " .. tostring(Item.box_y or "N/A"))
                    print("|   scroll_y       : " .. tostring(Item.scroll_y or "N/A"))
                    print("|   id1            : " .. tostring(Item.id1 or "N/A"))
                    print("|   id2            : " .. tostring(Item.id2 or "N/A"))
                    print("|   id3            : " .. tostring(Item.id3 or "N/A"))
                    print("|   itemid1        : " .. tostring(Item.itemid1 or "N/A"))
                    print("|   itemid1_size   : " .. tostring(Item.itemid1_size or "N/A"))
                    print("|   itemid2        : " .. tostring(Item.itemid2 or "N/A"))
                    print("|   hov            : " .. tostring(Item.hov or "N/A"))
                    print("|   textids        : " .. tostring(Item.textids or "N/A"))
                    print("|   textitem       : " .. tostring(Item.textitem or "N/A"))
                    print("|   memloc         : " .. tostring(Item.memloc or "N/A"))
                    print("|   memloctop      : " .. tostring(Item.memloctop or "N/A"))
                    print("|   index          : " .. tostring(Item.index or "N/A"))
                    print("|   fullpath       : " .. tostring(Item.fullpath or "N/A"))
                    print("|   fullIDpath     : " .. tostring(Item.fullIDpath or "N/A"))
                    print("|   notvisible     : " .. tostring(Item.notvisible or "N/A"))
                    print("|   OP             : " .. tostring(Item.OP or "N/A"))
                    print("|   xy             : " .. tostring(Item.xy or "N/A"))
                    
                    print("+================================+")
                    print("")
                end
            end
        end
        
        ProcessedInterfaces = ProcessedInterfaces + 1
        
        ::continue::
    end
    
    if ProcessedInterfaces == 0 then
        self:Error("No currency pouch interfaces could be processed")
        return false
    end
    
    if TotalFound == 0 then
        self:Info("No currency items found in pouch")
        return false
    end
    
    self:Info("Currency pouch scan completed - processed " .. ProcessedInterfaces .. " interface(s), found " .. TotalFound .. " items")
    return true
end

-- Prints a table's contents in a formatted, readable way
---@param Tbl table The table to print (supports nested tables)
---@return boolean success True if table was printed successfully, false if invalid table
function Slib:PrintTable(Tbl)
    -- Parameter validation
    if not self:Sanitize(Tbl, "table", "Tbl") then
        return false
    end
    
    -- Try to get the variable name from debug info
    local TableName = "Table"
    
    -- Helper function to recursively print table contents
    local function printTableRecursive(tbl, indent)
        local spacing = string.rep("  ", indent)
        
        -- Sort keys for consistent output
        local keys = {}
        for key in pairs(tbl) do
            table.insert(keys, key)
        end
        
        table.sort(keys, function(a, b)
            local aType = type(a)
            local bType = type(b)
            if aType == bType then
                return tostring(a) < tostring(b)
            else
                return aType == "number" and bType ~= "number"
            end
        end)
        
        for _, key in ipairs(keys) do
            local value = tbl[key]
            local keyStr = type(key) == "string" and key or "[" .. tostring(key) .. "]"
            
            if type(value) == "table" then
                print(spacing .. keyStr .. " = {")
                printTableRecursive(value, indent + 1)
                print(spacing .. "}")
            elseif type(value) == "string" then
                print(spacing .. keyStr .. ' = "' .. tostring(value) .. '"')
            elseif type(value) == "function" then
                print(spacing .. keyStr .. " = [Function]")
            elseif type(value) == "userdata" then
                print(spacing .. keyStr .. " = [UserData]")
            else
                print(spacing .. keyStr .. " = " .. tostring(value))
            end
        end
    end
    
    -- Check if table is empty
    if next(Tbl) == nil then
        print(TableName .. " = {} (empty)")
        return true
    end
    
    -- Print the table
    print(TableName .. " = {")
    printTableRecursive(Tbl, 1)
    print("}")
    
    return true
end

-- ##################################
-- #                                #
-- #       HELPER FUNCTIONS         #
-- #                                #
-- ##################################

-- Checks if the player is in a specified area (circular radius)
---@param X number The center X coordinate
---@param Y number The center Y coordinate  
---@param Z number The Z coordinate (floor/plane)
---@param Radius number The radius in tiles (must be non-negative)
---@return boolean inArea True if player is within the specified circular area, false otherwise
function Slib:IsPlayerInArea(X, Y, Z, Radius)
    -- Parameter validation
    if not self:ValidateParams({
        {X, "number", "X"},
        {Y, "number", "Y"},
        {Z, "number", "Z"},
        {Radius, "non_negative_number", "Radius"}
    }) then
        return false
    end
    
    -- Get player coordinates safely
    local Coord = API.PlayerCoord()
    if not Coord then
        self:Error("Failed to get player coordinates")
        return false
    end
    
    -- Calculate distance
    local Dx = Coord.x - X
    local Dy = Coord.y - Y
    local Distance = math.sqrt(Dx^2 + Dy^2)
    
    -- Check if player is in area
    local InArea = Distance <= Radius and Coord.z == Z
    return InArea
end

-- Checks if the player is in a rectangular area
---@param MinX number The minimum X coordinate (left boundary)
---@param MaxX number The maximum X coordinate (right boundary)
---@param MinY number The minimum Y coordinate (top boundary)
---@param MaxY number The maximum Y coordinate (bottom boundary)
---@param Z number The Z coordinate (floor/plane)
---@return boolean inArea True if player is within the specified rectangular area, false otherwise
function Slib:IsPlayerInRectangle(MinX, MaxX, MinY, MaxY, Z)
    -- Parameter validation
    if not self:ValidateParams({
        {MinX, "number", "MinX"},
        {MaxX, "number", "MaxX"},
        {MinY, "number", "MinY"},
        {MaxY, "number", "MaxY"},
        {Z, "number", "Z"}
    }) then
        return false
    end
    
    local Coord = API.PlayerCoord()
    if not Coord then
        self:Error("Failed to get player coordinates")
        return false
    end
    
    local InArea = Coord.x >= MinX and Coord.x <= MaxX and 
                   Coord.y >= MinY and Coord.y <= MaxY and 
                   Coord.z == Z
    
    return InArea
end

-- Checks if the player is at the specified coordinates
---@param X number The exact X coordinate
---@param Y number The exact Y coordinate
---@param Z number The exact Z coordinate (floor/plane)
---@return boolean atCoords True if player is at the exact coordinates, false otherwise
function Slib:IsPlayerAtCoords(X, Y, Z)
    -- Parameter validation
    if not self:ValidateParams({
        {X, "number", "X"},
        {Y, "number", "Y"},
        {Z, "number", "Z"}
    }) then
        return false
    end
    
    -- Get player coordinates safely
    local Coord = API.PlayerCoord()
    if not Coord then
        self:Error("Failed to get player coordinates")
        return false
    end
    
    local AtCoords = Coord.x == X and Coord.y == Y and Coord.z == Z
    return AtCoords
end

-- Gets the current instance timer text
---@return string timerText The instance timer text, or empty string if not found/unavailable
function Slib:GetInstanceTimer()
    if not self.Interfaces or not self.Interfaces.InstanceTimer then
        self:Error("InstanceTimer interface not defined")
        return ""
    end
    
    local Result = API.ScanForInterfaceTest2Get(false, self.Interfaces.InstanceTimer[1])
    if not Result then
        self:Warn("Failed to scan instance timer interface")
        return ""
    end
    
    if type(Result) ~= "table" and type(Result) ~= "userdata" then
        self:Error("Invalid result type from interface scan: " .. type(Result))
        return ""
    end
    
    if #Result == 0 then
        self:Warn("No timer interface elements found")
        return ""
    end
    
    local Element = Result[1]
    if not Element or not Element.textids then
        self:Warn("Timer element or textids not found")
        return ""
    end

    return tostring(Element.textids)
end

-- Checks if the instance timer matches a specific time value
---@param TimeToCheck string The time string to check for
---@return boolean matches True if timer matches the specified time, false otherwise
function Slib:InstanceTimerCheck(TimeToCheck)
    -- Parameter validation
    if not self:ValidateParams({
        {TimeToCheck, "string", "TimeToCheck"}
    }) then
        return false
    end
    
    local TimerText = self:GetInstanceTimer()
    
    -- Safety checks for nil or invalid return values
    if not TimerText then
        self:Warn("GetInstanceTimer returned nil")
        return false
    end
    
    if type(TimerText) ~= "string" then
        self:Warn("GetInstanceTimer returned non-string value: " .. type(TimerText))
        return false
    end
    
    if TimerText == "" then
        return false
    end
    
    local Found = string.find(TimerText, TimeToCheck, 1, true)
    return Found ~= nil
end

-- Retrieves the kill counts for GWD1 (God Wars Dungeon 1) followers
---@return table<string, number>|nil killCounts Table containing kill counts for each faction, or nil if failed to retrieve data
function Slib:GetGWD1KillCounts()

    local FactionNames = { "Armadyl", "Bandos", "Saradomin", "Zamorak", "Zaros" }
    local Results = {}
    local SuccessCount = 0

    -- Process each faction
    for i, BaseAddress in ipairs(self.Interfaces.GWD1KillCounts) do
        local FactionName = FactionNames[i]
        
        -- Scan interface for faction data
        local Data = API.ScanForInterfaceTest2Get(false, BaseAddress)
        if not Data then
            self:Warn(string.format("[GetGWD1KillCounts] Failed to scan interface for %s", FactionName))
            Results[FactionName] = 0
            goto continue
        end
        
        if type(Data) ~= "table" and type(Data) ~= "userdata" then
            self:Error(string.format("[GetGWD1KillCounts] Invalid data type for %s: %s", FactionName, type(Data)))
            Results[FactionName] = 0
            goto continue
        end
        
        if #Data == 0 then
            self:Warn(string.format("[GetGWD1KillCounts] No interface data found for %s", FactionName))
            Results[FactionName] = 0
            goto continue
        end
        
        -- Get the first element and validate it
        local Element = Data[1]
        if not Element or not Element.memloc then
            self:Warn(string.format("[GetGWD1KillCounts] Invalid element data for %s", FactionName))
            Results[FactionName] = 0
            goto continue
        end
        
        -- Read kill count from memory
        local Amount = API.ReadCharsLimit(Element.memloc + API.I_itemids3, 255)
        if not Amount then
            self:Warn(string.format("[GetGWD1KillCounts] Failed to read kill count for %s", FactionName))
            Results[FactionName] = 0
            goto continue
        end
        
        -- Convert to number
        local KillCount = tonumber(Amount)
        if not KillCount then
            self:Warn(string.format("[GetGWD1KillCounts] Invalid kill count value for %s: %s", FactionName, tostring(Amount)))
            Results[FactionName] = 0
            goto continue
        end
        
        Results[FactionName] = KillCount
        SuccessCount = SuccessCount + 1
        self:Info(string.format("[GetGWD1KillCounts] %s kill count: %d", FactionName, KillCount))
        
        ::continue::
    end

    -- Print formatted results
    if SuccessCount > 0 then
        self:Info("=== GWD1 Kill Counts ===")
        print("+========================+")
        print("|      GWD1 KILLS        |")
        print("+========================+")
        print("|   Armadyl   : " .. string.format("%-8s", tostring(Results.Armadyl or 0)) .. " |")
        print("|   Bandos    : " .. string.format("%-8s", tostring(Results.Bandos or 0)) .. " |")
        print("|   Saradomin : " .. string.format("%-8s", tostring(Results.Saradomin or 0)) .. " |")
        print("|   Zamorak   : " .. string.format("%-8s", tostring(Results.Zamorak or 0)) .. " |")
        print("|   Zaros     : " .. string.format("%-8s", tostring(Results.Zaros or 0)) .. " |")
        print("+========================+")

        return Results
    else
        self:Error("[GetGWD1KillCounts] Failed to retrieve any kill counts")
        return nil
    end
end

-- Retrieves the kill counts for GWD2 (God Wars Dungeon 2) followers
---@return table<string, number>|nil killCounts Table containing kill counts for each faction, or nil if failed to retrieve data
function Slib:GetGWD2KillCounts()

    local FactionNames = { "Seren", "Sliske", "Zamorak", "Zaros" }
    local Results = {}
    local SuccessCount = 0

    -- Process each faction
    for i, BaseAddress in ipairs(self.Interfaces.GWD2KillCounts) do
        local FactionName = FactionNames[i]
        
        -- Scan interface for faction data
        local Data = API.ScanForInterfaceTest2Get(false, BaseAddress)
        if not Data then
            self:Warn(string.format("[GetGWD2KillCounts] Failed to scan interface for %s", FactionName))
            Results[FactionName] = 0
            goto continue
        end
        
        if type(Data) ~= "table" and type(Data) ~= "userdata" then
            self:Error(string.format("[GetGWD2KillCounts] Invalid data type for %s: %s", FactionName, type(Data)))
            Results[FactionName] = 0
            goto continue
        end
        
        if #Data == 0 then
            self:Warn(string.format("[GetGWD2KillCounts] No interface data found for %s", FactionName))
            Results[FactionName] = 0
            goto continue
        end
        
        -- Get the first element and validate it
        local Element = Data[1]
        if not Element or not Element.memloc then
            self:Warn(string.format("[GetGWD2KillCounts] Invalid element data for %s", FactionName))
            Results[FactionName] = 0
            goto continue
        end
        
        -- Read kill count from memory
        local Amount = API.ReadCharsLimit(Element.memloc + API.I_itemids3, 255)
        if not Amount then
            self:Warn(string.format("[GetGWD2KillCounts] Failed to read kill count for %s", FactionName))
            Results[FactionName] = 0
            goto continue
        end
        
        -- Convert to number
        local KillCount = tonumber(Amount)
        if not KillCount then
            self:Warn(string.format("[GetGWD2KillCounts] Invalid kill count value for %s: %s", FactionName, tostring(Amount)))
            Results[FactionName] = 0
            goto continue
        end
        
        Results[FactionName] = KillCount
        SuccessCount = SuccessCount + 1
        self:Info(string.format("[GetGWD2KillCounts] %s kill count: %d", FactionName, KillCount))
        
        ::continue::
    end

    -- Print formatted results
    if SuccessCount > 0 then
        self:Info("=== GWD2 Kill Counts ===")
        print("+========================+")
        print("|      GWD2 KILLS        |")
        print("+========================+")
        print("|   Seren    : " .. string.format("%-8s", tostring(Results.Seren or 0)) .. " |")
        print("|   Sliske   : " .. string.format("%-8s", tostring(Results.Sliske or 0)) .. " |")
        print("|   Zamorak  : " .. string.format("%-8s", tostring(Results.Zamorak or 0)) .. " |")
        print("|   Zaros    : " .. string.format("%-8s", tostring(Results.Zaros or 0)) .. " |")
        print("+========================+")

        return Results
    else
        self:Error("[GetGWD2KillCounts] Failed to retrieve any kill counts")
        return nil
    end
end

-- Checks recent chat messages for specified patterns and returns true if any are found
---@param Patterns string|table The pattern(s) to search for in chat messages
---@param DebugPrint boolean|nil Whether to print debug information (optional, default: false)
---@return boolean found True if any pattern was found in recent messages, false otherwise
function Slib:RecentMessageCheck(Patterns, DebugPrint)
    -- Parameter validation
    if not self:ValidateParams({
        {Patterns, {"string", "table_of_strings"}, "Patterns"},
        {DebugPrint, "boolean", "DebugPrint", true} -- allow_nil = true
    }) then
        return false
    end
    
    -- Convert single string to table for consistent processing
    local PatternTable = type(Patterns) == "table" and Patterns or {Patterns}
    
    -- Default debug_print to false
    DebugPrint = DebugPrint or false
    
    -- Gather recent chat messages
    self.ChatMessages = API.GatherEvents_chat_check()
    if not self.ChatMessages then
        self:Warn("Failed to gather chat self.ChatMessages")
        return false
    end
    
    if type(self.ChatMessages) ~= "table" and type(self.ChatMessages) ~= "userdata" then
        self:Error("Invalid self.ChatMessages data type: " .. type(self.ChatMessages))
        return false
    end
    
    if #self.ChatMessages == 0 then
        return false
    end
    
    -- Process each message
    for i, Message in ipairs(self.ChatMessages) do
        -- Validate message structure
        if not Message or not Message.text then
            if DebugPrint then
                self:Warn("Skipping invalid message at index " .. i)
            end
            goto continue_message
        end
        
        -- Debug print if requested
        if DebugPrint then
            print(string.format("[Chat Message] %s", Message.text))
        end
        
        -- Check message against all patterns (case insensitive)
        for _, Pattern in ipairs(PatternTable) do
            if string.find(string.lower(Message.text), string.lower(Pattern)) then
                if DebugPrint then
                    print(string.format("[RecentMessageCheck] Pattern matched: '%s'", Pattern))
                end
                return true
            end
        end
        
        ::continue_message::
    end
    
    -- No patterns matched
    return false
end

-- Waits for a specific object to appear within range
---@param ObjID number|table The object ID(s) to wait for
---@param Range number Maximum search distance in tiles
---@param ObjType number|table The object type(s) to search for
---@param TimeoutSeconds number Maximum wait time in seconds
---@return boolean found True if object was found within timeout, false otherwise
function Slib:WaitForObjectToAppear(ObjID, Range, ObjType, TimeoutSeconds)
    -- Parameter validation
    if not self:ValidateParams({
        {ObjID, {"number", "table_of_numbers"}, "ObjID"},
        {Range, "positive_number", "Range"},
        {ObjType, {"number", "table_of_numbers"}, "ObjType"},
        {TimeoutSeconds, "positive_number", "TimeoutSeconds"}
    }) then
        return false
    end
    
    -- Convert single numbers to tables for consistent processing
    local ObjIdTable = type(ObjID) == "table" and ObjID or {ObjID}
    local ObjTypeTable = type(ObjType) == "table" and ObjType or {ObjType}
    
    local StartTime = os.clock()
    local MaxTime = TimeoutSeconds
    
    -- Create descriptive strings for logging
    local ObjIdStr = type(ObjID) == "table" and table.concat(ObjIdTable, ", ") or tostring(ObjID)
    local ObjTypeStr = type(ObjType) == "table" and table.concat(ObjTypeTable, ", ") or tostring(ObjType)
    
    self:Info("Waiting for object ID(s) [" .. ObjIdStr .. "] (Type(s) [" .. ObjTypeStr .. "]) within range " .. Range .. " tiles...")
    
    while API.Read_LoopyLoop() do
        -- Check timeout
        if (os.clock() - StartTime) >= MaxTime then
            self:Warn("Timeout reached (" .. TimeoutSeconds .. "s) while waiting for object ID(s) [" .. ObjIdStr .. "]")
            return false
        end
        
        -- Search for the objects
        local Objects = API.GetAllObjArray1(ObjIdTable, Range, ObjTypeTable)
        
        if not Objects then
            self:Warn("API returned nil for object search")
            goto continue_wait
        end
        
        if type(Objects) ~= "table" and type(Objects) ~= "userdata" then
            self:Error("Invalid objects data type: " .. type(Objects))
            return false
        end
        
        if #Objects > 0 then
            -- Check each object to find exact match
            for _, Object in ipairs(Objects) do
                if not Object then
                    goto continue_object
                end
                
                local Id = Object.Id or 0
                local ObjectType = Object.Type or 0
                
                -- Check if this object matches any of our target IDs and types
                local IdMatch = false
                local TypeMatch = false
                
                for _, TargetId in ipairs(ObjIdTable) do
                    if Id == TargetId then
                        IdMatch = true
                        break
                    end
                end
                
                for _, TargetType in ipairs(ObjTypeTable) do
                    if ObjectType == TargetType then
                        TypeMatch = true
                        break
                    end
                end
                
                if IdMatch and TypeMatch then
                    local Elapsed = os.clock() - StartTime
                    self:Info("Object found! ID " .. Id .. " (Type " .. ObjectType .. ") after " .. string.format("%.1f", Elapsed) .. " seconds")
                    return true
                end
                
                ::continue_object::
            end
        end
        
        ::continue_wait::
        
        -- Short sleep to prevent excessive CPU usage
        self:Sleep(200, "ms")
    end
    
    self:Warn("Loop stopped while waiting for object ID(s) [" .. ObjIdStr .. "]")
    return false
end

-- Waits for a specific object to appear within range using GetAllObjArray2 (supports x, y, z parameters)
---@param ObjID number|table The object ID(s) to wait for
---@param Range number Maximum search distance in tiles
---@param ObjType number|table The object type(s) to search for
---@param x number The x coordinate to search from
---@param y number The y coordinate to search from
---@param z number The z coordinate to search from
---@param TimeoutSeconds number Maximum wait time in seconds
---@return boolean found True if object was found within timeout, false otherwise
function Slib:WaitForObjectToAppear2(ObjID, Range, ObjType, x, y, z, TimeoutSeconds)
    -- Parameter validation
    if not self:ValidateParams({
        {ObjID, {"number", "table_of_numbers"}, "ObjID"},
        {Range, "positive_number", "Range"},
        {ObjType, {"number", "table_of_numbers"}, "ObjType"},
        {x, "number", "x"},
        {y, "number", "y"},
        {z, "number", "z"},
        {TimeoutSeconds, "positive_number", "TimeoutSeconds"}
    }) then
        return false
    end
    
    -- Convert single numbers to tables for consistent processing
    local ObjIdTable = type(ObjID) == "table" and ObjID or {ObjID}
    local ObjTypeTable = type(ObjType) == "table" and ObjType or {ObjType}
    
    local StartTime = os.clock()
    local MaxTime = TimeoutSeconds
    
    -- Create descriptive strings for logging
    local ObjIdStr = type(ObjID) == "table" and table.concat(ObjIdTable, ", ") or tostring(ObjID)
    local ObjTypeStr = type(ObjType) == "table" and table.concat(ObjTypeTable, ", ") or tostring(ObjType)
    local TileStr = "from tile (" .. tostring(x) .. ", " .. tostring(y) .. ", " .. tostring(z) .. ")"
    
    self:Info("Waiting for object ID(s) [" .. ObjIdStr .. "] (Type(s) [" .. ObjTypeStr .. "]) within range " .. Range .. " tiles " .. TileStr .. "...")
    
    -- Construct WPOINT from x, y, z
    local Tile = WPOINT.new(x, y, z)
    
    while API.Read_LoopyLoop() do
        -- Check timeout
        if (os.clock() - StartTime) >= MaxTime then
            self:Warn("Timeout reached (" .. TimeoutSeconds .. "s) while waiting for object ID(s) [" .. ObjIdStr .. "]")
            return false
        end
        
        -- Search for the objects using GetAllObjArray2
        local Objects = API.GetAllObjArray2(ObjIdTable, Range, ObjTypeTable, Tile)
        
        if not Objects then
            self:Warn("API returned nil for object search")
            goto continue_wait
        end
        
        if type(Objects) ~= "table" and type(Objects) ~= "userdata" then
            self:Error("Invalid objects data type: " .. type(Objects))
            return false
        end
        
        if #Objects > 0 then
            -- Check each object to find exact match
            for _, Object in ipairs(Objects) do
                if not Object then
                    goto continue_object
                end
                
                local Id = Object.Id or 0
                local ObjectType = Object.Type or 0
                
                -- Check if this object matches any of our target IDs and types
                local IdMatch = false
                local TypeMatch = false
                
                for _, TargetId in ipairs(ObjIdTable) do
                    if Id == TargetId then
                        IdMatch = true
                        break
                    end
                end
                
                for _, TargetType in ipairs(ObjTypeTable) do
                    if ObjectType == TargetType then
                        TypeMatch = true
                        break
                    end
                end
                
                if IdMatch and TypeMatch then
                    local Elapsed = os.clock() - StartTime
                    self:Info("Object found! ID " .. Id .. " (Type " .. ObjectType .. ") after " .. string.format("%.1f", Elapsed) .. " seconds")
                    return true
                end
                
                ::continue_object::
            end
        end
        
        ::continue_wait::
        
        -- Short sleep to prevent excessive CPU usage
        self:Sleep(200, "ms")
    end
    
    self:Warn("Loop stopped while waiting for object ID(s) [" .. ObjIdStr .. "]")
    return false
end

-- Finds the nearest object with specified ID(s) and type(s) within range
---@param ObjId number|table The object ID(s) to search for
---@param Distance number Maximum search distance in tiles
---@param ObjType number|table The object type(s) to search for
---@return table|nil nearest_object The nearest matching object, or nil if none found
function Slib:FindObj(ObjId, Distance, ObjType)
    -- Parameter validation
    if not self:ValidateParams({
        {ObjId, {"number", "table_of_numbers"}, "ObjId"},
        {Distance, "id", "Distance"},
        {ObjType, {"number", "table_of_numbers"}, "ObjType"}
    }) then
        return nil
    end
    
    -- Convert to tables for API call
    local ObjIdTable = type(ObjId) == "table" and ObjId or {ObjId}
    local ObjTypeTable = type(ObjType) == "table" and ObjType or {ObjType}
    
    -- Search for objects
    local Objects = API.GetAllObjArray1(ObjIdTable, Distance, ObjTypeTable)
    
    if not Objects or #Objects == 0 then
        return nil
    end
    
    -- Find nearest object
    local NearestObj = nil
    local NearestDistance = math.huge
    
    for _, Obj in ipairs(Objects) do
        if Obj and Obj.Distance and Obj.Distance < NearestDistance then
            NearestObj = Obj
            NearestDistance = Obj.Distance
        end
    end
    
    return NearestObj
end

-- Finds the nearest object with specified ID(s) and type(s) within range using GetAllObjArray2 (supports x, y, z parameters)
---@param ObjId number|table The object ID(s) to search for
---@param Distance number Maximum search distance in tiles
---@param ObjType number|table The object type(s) to search for
---@param x number The x coordinate to search from
---@param y number The y coordinate to search from
---@param z number The z coordinate to search from
---@return table|nil nearest_object The nearest matching object, or nil if none found
function Slib:FindObj2(ObjId, Distance, ObjType, x, y, z)
    -- Parameter validation
    if not self:ValidateParams({
        {ObjId, {"number", "table_of_numbers"}, "ObjId"},
        {Distance, "id", "Distance"},
        {ObjType, {"number", "table_of_numbers"}, "ObjType"},
        {x, "number", "x"},
        {y, "number", "y"},
        {z, "number", "z"}
    }) then
        return nil
    end
    
    -- Convert to tables for API call
    local ObjIdTable = type(ObjId) == "table" and ObjId or {ObjId}
    local ObjTypeTable = type(ObjType) == "table" and ObjType or {ObjType}
    
    -- Construct WPOINT from x, y, z
    local Tile = WPOINT.new(x, y, z)
    
    -- Search for objects using GetAllObjArray2
    local Objects = API.GetAllObjArray2(ObjIdTable, Distance, ObjTypeTable, Tile)
    
    if not Objects or #Objects == 0 then
        return nil
    end
    
    -- Find nearest object
    local NearestObj = nil
    local NearestDistance = math.huge
    
    for _, Obj in ipairs(Objects) do
        if Obj and Obj.Distance and Obj.Distance < NearestDistance then
            NearestObj = Obj
            NearestDistance = Obj.Distance
        end
    end
    
    return NearestObj
end

-- Checks if the currency pouch contains an item with the given ID or any ID in a list
---@param Ids number|table The item ID or list of item IDs to check for
---@return boolean found True if at least one of the IDs is found in the currency pouch, false otherwise
function Slib:CurrencyPouchContains(Ids)
    -- Parameter validation
    if not self:Sanitize(Ids, {"number", "table_of_ids"}, "Ids") then
        return false
    end
    
    -- Convert to table for consistent processing
    local IdTable = type(Ids) == "table" and Ids or {Ids}
    
    -- Track which IDs have been found
    local found = {}
    for _, id in ipairs(IdTable) do
        found[id] = false
    end
    
    -- Scan all currency pouch interfaces
    for I = 1, #self.Interfaces.CurrencyPouch do
        local Interface = API.ScanForInterfaceTest2Get(true, self.Interfaces.CurrencyPouch[I])
        if Interface and (type(Interface) == "table" or type(Interface) == "userdata") then
            for _, Item in pairs(Interface) do
                if Item and Item.itemid1 and Item.itemid1 >= 0 then
                    if found[Item.itemid1] == false then
                        found[Item.itemid1] = true
                    end
                end
            end
        end
    end
    -- Check if all IDs were found
    for _, id in ipairs(IdTable) do
        if not found[id] then
            return false
        end
    end
    return true
end

-- Checks if the area loot interface is currently open
---@return boolean isOpen True if area loot interface is open, false otherwise
function Slib:AreaLootIsOpen()
    -- Validate that AreaLoot interface is defined
    if not self.Interfaces or not self.Interfaces.AreaLoot or not self.Interfaces.AreaLoot[1] then
        self:Error("[AreaLootIsOpen] AreaLoot interface not defined")
        return false
    end
    
    -- Scan for the area loot interface
    local Interface = API.ScanForInterfaceTest2Get(true, self.Interfaces.AreaLoot[1])
    if not Interface then
        return false
    end
    
    -- Validate interface data type
    if type(Interface) ~= "table" and type(Interface) ~= "userdata" then
        self:Error("[AreaLootIsOpen] Invalid interface data type: " .. type(Interface))
        return false
    end

    if #Interface > 0 then
        return true
    end
    
    return false
end

-- Retrieves all items currently visible in the area loot interface
---@return table|nil items Array of items {itemId, slotId} or nil if interface closed or no items found
function Slib:AreaLootGetItems()
    -- Check if area loot is open
    if not self:AreaLootIsOpen() then
        self:Warn("[AreaLootGetItems] Area loot interface is not open")
        return nil
    end
    
    -- Validate that AreaLoot interface is defined
    if not self.Interfaces or not self.Interfaces.AreaLoot or not self.Interfaces.AreaLoot[1] then
        self:Error("[AreaLootGetItems] AreaLoot interface not defined")
        return nil
    end
    
    -- Scan for the area loot interface
    local Interface = API.ScanForInterfaceTest2Get(true, self.Interfaces.AreaLoot[1])
    if not Interface then
        self:Error("[AreaLootGetItems] Failed to scan area loot interface")
        return nil
    end
    
    -- Validate interface data type
    if type(Interface) ~= "table" and type(Interface) ~= "userdata" then
        self:Error("[AreaLootGetItems] Invalid interface data type: " .. type(Interface))
        return nil
    end
    
    local Items = {}
    local ItemCount = 0
    
    -- Process each interface element
    for I, Item in pairs(Interface) do
        -- Validate item structure
        if not Item then
            self:Warn("[AreaLootGetItems] Skipping nil item at index " .. tostring(I))
            goto continue_item
        end
        
        if type(Item) ~= "table" and type(Item) ~= "userdata" then
            self:Warn("[AreaLootGetItems] Skipping invalid item at index " .. tostring(I) .. " (type: " .. type(Item) .. ")")
            goto continue_item
        end
        
        -- Check for valid item ID (not -1 which indicates empty slot)
        if Item.itemid1 and Item.itemid1 ~= -1 and Item.itemid1 >= 0 then
            ItemCount = ItemCount + 1
            table.insert(Items, {Item.itemid1, Item.id3 or 0})
        end
        
        ::continue_item::
    end
    
    if ItemCount == 0 then
        self:Info("[AreaLootGetItems] No valid items found in area loot")
        return {}
    end

    return Items
end

-- Checks if the area loot contains all specified item IDs
---@param ItemIds number|table The item ID or table of item IDs to check for
---@return boolean allFound True if all specified items are found in area loot, false otherwise
function Slib:AreaLootContains(ItemIds)
    -- Parameter validation
    if not self:Sanitize(ItemIds, {"number", "table_of_ids"}, "ItemIds") then
        return false
    end
    
    -- Convert to table for consistent processing
    local IdTable = type(ItemIds) == "table" and ItemIds or {ItemIds}
    
    if not self:AreaLootIsOpen() then
        return false
    end

    local Items = self:AreaLootGetItems()
    if not Items then
        return false
    end
    
    -- Track which IDs have been found
    local foundIds = {}
    for _, targetId in ipairs(IdTable) do
        foundIds[targetId] = false
    end
    
    -- Check each item in area loot against all target IDs
    for _, item in pairs(Items) do
        for _, targetId in ipairs(IdTable) do
            if item[1] == targetId then
                foundIds[targetId] = true
                self:Info("Item " .. targetId .. " found in area loot")
            end
        end
    end
    
    -- Check if all IDs were found
    for _, targetId in ipairs(IdTable) do
        if not foundIds[targetId] then
            self:Info("Item " .. targetId .. " not found in area loot")
            return false
        end
    end
    
    self:Info("All specified items found in area loot")
    return true
end

-- Checks if the instance interface is currently open
---@return boolean IsOpen True if instance interface is open, false otherwise
function Slib:InstanceInterfaceIsOpen()
    local Interface = API.ScanForInterfaceTest2Get(true, self.Interfaces.InstanceOptions[1])
    return #Interface > 0
end

-- Retrieves all available instance interface options and settings
---@return table|nil Options Table containing instance options or nil if interface is closed
---@return table Options.MaxPlayers Maximum players interface element
---@return table Options.MinCombat Minimum combat level interface element  
---@return table Options.SpawnSpeed Spawn speed interface element
---@return table Options.Protection Protection interface element
---@return boolean Options.PracticeMode Practice mode enabled state
---@return boolean Options.HardMode Hard mode enabled state
function Slib:GetInstanceInterfaceOptions()
    -- Validate interface state before proceeding
    if not self:InstanceInterfaceIsOpen() then
        self:Error("[GetInstanceInterfaceOptions] Instance interface is not open")
        return nil
    end

    -- Retrieve interface elements for each option
    local MaxPlayersRaw = API.ScanForInterfaceTest2Get(true, self.Interfaces.InstanceOptions[2])
    local MinCombatRaw = API.ScanForInterfaceTest2Get(true, self.Interfaces.InstanceOptions[3])
    local SpawnSpeedRaw = API.ScanForInterfaceTest2Get(true, self.Interfaces.InstanceOptions[4])
    local ProtectionRaw = API.ScanForInterfaceTest2Get(true, self.Interfaces.InstanceOptions[5])
    
    -- Parse values with proper nil checking
    local MaxPlayersTreated = tonumber(API.ReadCharsLimit(MaxPlayersRaw[1].memloc + API.I_itemids3, 255))
    local MinCombatTreated = tonumber(API.ReadCharsLimit(MinCombatRaw[1].memloc + API.I_itemids3, 255))
    local SpawnSpeedTreated = tostring(SpawnSpeedRaw[1].textids)
    local ProtectionTreated = tostring(ProtectionRaw[1].textids)

    
    -- Get mode settings from varbits (convert 0/1 to false/true)
    local PracticeMode = API.GetVarbitValue(27142) == 1
    local HardMode = API.GetVarbitValue(27141) == 1

    -- Debug output for interface values
    if MaxPlayersTreated then
        print("Max Players: " .. tostring(MaxPlayersTreated))
    end
    if MinCombatTreated then
        print("Min Combat: " .. tostring(MinCombatTreated))
    end
    if SpawnSpeedTreated then
        print("Spawn Speed: " .. SpawnSpeedTreated)
    end
    if ProtectionTreated then
        print("Protection: " .. ProtectionTreated)
    end
    print("Practice Mode: " .. tostring(PracticeMode))
    print("Hard Mode: " .. tostring(HardMode))

    -- Return structured options table
    return {
        MaxPlayers = MaxPlayersTreated,
        MinCombat = MinCombatTreated,
        SpawnSpeed = SpawnSpeedTreated,
        Protection = ProtectionTreated,
        PracticeMode = PracticeMode,
        HardMode = HardMode
    }
end

-- Checks if the text input interface is currently open
---@return boolean IsOpen True if text input interface is open, false otherwise
function Slib:TextInputIsOpen()
    local Interface = API.ScanForInterfaceTest2Get(true, self.Interfaces.TextInput[1])
    return #Interface > 0
end

-- Gets the player's facing direction as a compass direction
---@return string direction The compass direction: "N", "NE", "E", "SE", "S", "SW", "W", "NW"
function Slib:PlayerFacing()
    local Azimuth = API.calculatePlayerOrientation()
    
    if not Azimuth then
        self:Error("[PlayerFacing] Failed to get player orientation")
        return "N" -- Default fallback
    end
    
    -- Normalize azimuth to 0-360 range
    Azimuth = Azimuth % 360
    if Azimuth < 0 then
        Azimuth = Azimuth + 360
    end
    
    -- Convert azimuth to compass direction
    -- Each direction covers 45° (360° / 8 = 45°)
    -- Centered on: N=0°, NE=45°, E=90°, SE=135°, S=180°, SW=225°, W=270°, NW=315°
    local Direction
    if Azimuth >= 337.5 or Azimuth < 22.5 then
        Direction = "N"
    elseif Azimuth >= 22.5 and Azimuth < 67.5 then
        Direction = "NE"
    elseif Azimuth >= 67.5 and Azimuth < 112.5 then
        Direction = "E"
    elseif Azimuth >= 112.5 and Azimuth < 157.5 then
        Direction = "SE"
    elseif Azimuth >= 157.5 and Azimuth < 202.5 then
        Direction = "S"
    elseif Azimuth >= 202.5 and Azimuth < 247.5 then
        Direction = "SW"
    elseif Azimuth >= 247.5 and Azimuth < 292.5 then
        Direction = "W"
    elseif Azimuth >= 292.5 and Azimuth < 337.5 then
        Direction = "NW"
    end
    
    self:Info("[PlayerFacing] Player facing " .. Direction .. " (" .. string.format("%.1f", Azimuth) .. "°)")
    return Direction
end

-- Checks if any object with specified ID and type has Bool1 property set to 1 within range
---@param ObjId number|table The object ID(s) to search for
---@param Range number Maximum search distance in tiles
---@param ObjType number|table The object type(s) to search for
---@return boolean hasBool1Object True if at least one object with Bool1=1 is found, false otherwise
function Slib:CheckObjectBool1(ObjId, Range, ObjType)
    -- Parameter validation
    if not self:ValidateParams({
        {ObjId, {"number", "table_of_numbers"}, "ObjId"},
        {Range, "non_negative_number", "Range"},
        {ObjType, {"number", "table_of_numbers"}, "ObjType"}
    }) then
        return false
    end
    
    -- Convert to tables for API call
    local ObjIdTable = type(ObjId) == "table" and ObjId or {ObjId}
    local ObjTypeTable = type(ObjType) == "table" and ObjType or {ObjType}
    
    -- Search for objects
    local Objects = API.GetAllObjArray1(ObjIdTable, Range, ObjTypeTable)
    
    if not Objects then
        self:Warn("[CheckObjectBool1] API returned nil for object search")
        return false
    end
    
    if type(Objects) ~= "table" and type(Objects) ~= "userdata" then
        self:Error("[CheckObjectBool1] Invalid objects data type: " .. type(Objects))
        return false
    end
    
    if #Objects == 0 then
        return false
    end
    
    -- Check each object for Bool1 property
    local Bool1Count = 0
    for _, Object in ipairs(Objects) do
        if Object and Object.Bool1 == 1 then
            Bool1Count = Bool1Count + 1
        end
    end
    
    if Bool1Count > 0 then
        self:Info("[CheckObjectBool1] Found " .. Bool1Count .. " object(s) with Bool1=1")
        return true
    end
    
    return false
end

-- ##################################
-- #                                #
-- #           PROCEDURES           #
-- #                                #
-- ##################################

-- Walks to specified coordinates
---@param X number The target X coordinate
---@param Y number The target Y coordinate
---@param Z number The target Z coordinate (floor/plane)
---@return boolean success True if walk was initiated or player is already at destination, false on failure
function Slib:WalkToCoordinates(X, Y, Z)
    self:Info("[WalkToCoordinates] Starting walk to coordinates (" .. X .. ", " .. Y .. ", " .. Z .. ")...")
    -- Parameter validation
    if not self:ValidateParams({
        {X, "number", "X"},
        {Y, "number", "Y"},
        {Z, "number", "Z"}
    }) then
        self:Error("[WalkToCoordinates] Parameter validation failed")
        return false
    end
    
    -- Check if already at destination
    local AtDest = self:IsPlayerAtCoords(X, Y, Z)
    if AtDest then
        self:Info("[WalkToCoordinates] Already at destination coordinates")
        return true
    end

    local WalkResult = API.DoAction_Tile(WPOINT.new(X, Y, Z))
    if not WalkResult then
        self:Error("[WalkToCoordinates] Failed to initiate walk to (" .. X .. ", " .. Y .. ", " .. Z .. ")")
        return false
    end

    return true
end

-- Dives to the specified coordinates using Bladed Dive or regular Dive
---@param X number The target X coordinate
---@param Y number The target Y coordinate
---@param Z number The target Z coordinate
---@return boolean success True if dive was successful, false if abilities on cooldown or dive failed
function Slib:Dive(X, Y, Z)
    -- Parameter validation
    if not self:ValidateParams({
        {X, "number", "X"},
        {Y, "number", "Y"},
        {Z, "number", "Z"}
    }) then
        return false
    end

    self:Info(string.format("[Dive] Attempting to dive to coordinates (%d, %d, %d)", X, Y, Z))
    
    -- Check Bladed Dive ability
    local BladedDive = API.GetABs_id(30331)
    if not BladedDive then
        self:Error("[Dive] Failed to get Bladed Dive ability info")
        return false
    end
    
    -- Check regular Dive ability
    local RegularDive = API.GetABs_id(23714)
    if not RegularDive then
        self:Error("[Dive] Failed to get regular Dive ability info")
        return false
    end
    
    -- Check if either ability is available
    local BladedDiveReady = BladedDive.id ~= 0 and BladedDive.enabled and BladedDive.cooldown_timer < 1
    local RegularDiveReady = RegularDive.id ~= 0 and RegularDive.enabled and RegularDive.cooldown_timer < 1
    
    if not (BladedDiveReady or RegularDiveReady) then
        self:Warn("[Dive] No dive abilities available (on cooldown or disabled)")
        return false
    end
    
    -- Create target point
    local TargetPoint = WPOINT.new(X, Y, Z)
    
    -- Try Bladed Dive first
    if BladedDiveReady then
        self:Info("[Dive] Attempting Bladed Dive...")
        if API.DoAction_BDive_Tile(TargetPoint) then
            self:Info("[Dive] Bladed Dive successful")
            return true
        end
        self:Warn("[Dive] Bladed Dive failed")
    end
    
    -- Try regular Dive as fallback
    if RegularDiveReady then
        self:Info("[Dive] Attempting regular Dive...")
        if API.DoAction_Dive_Tile(TargetPoint) then
            self:Info("[Dive] Regular Dive successful")
            return true
        end
        self:Warn("[Dive] Regular Dive failed")
    end
    
    self:Error("[Dive] All dive attempts failed")
    return false
end

-- Uses an ability by its ID
---@param AbilityId number The ID of the ability to use
---@return boolean success True if ability was used successfully, false if ability not found, on cooldown, or disabled
function Slib:UseAbilityById(AbilityId)
    -- Parameter validation
    if not self:ValidateParams({
        {AbilityId, "id", "AbilityId"}
    }) then
        return false
    end

    self:Info(string.format("[UseAbilityById] Attempting to use ability with ID: %d", AbilityId))
    
    -- Get ability information
    local Ability = API.GetABs_id(AbilityId)
    if not Ability or Ability.id == 0 then
        self:Error(string.format("[UseAbilityById] Ability with ID %d not found", AbilityId))
        return false
    end
    
    -- Check if ability is available
    if not Ability.enabled then
        self:Info(string.format("[UseAbilityById] Ability %d is currently disabled", AbilityId))
        return false
    end
    
    -- Check cooldown
    if Ability.cooldown_timer >= 1 then
        self:Info(string.format("[UseAbilityById] Ability %d is on cooldown (%.1f seconds remaining)", AbilityId, Ability.cooldown_timer))
        return false
    end
    
    -- Attempt to use the ability
    self:Info(string.format("[UseAbilityById] Using ability %d", AbilityId))
    return API.DoAction_Ability_Direct(Ability, 1, API.OFF_ACT_GeneralInterface_route)
end

-- Uses an ability by name if it exists and is enabled. ExactMatch is used to check if the ability name is exact.
---@param AbilityName string
---@param ExactMatch boolean
---@return boolean
function Slib:UseAbilityByName(AbilityName, ExactMatch)
    self:Info("[UseAbilityByName] Attempting to use ability: " .. AbilityName .. " (ExactMatch: " .. tostring(ExactMatch) .. ")")
    -- Parameter validation
    if not self:ValidateParams({
        {AbilityName, "non_empty_string", "AbilityName"},
        {ExactMatch, "boolean", "ExactMatch"}
    }) then
        self:Error("[UseAbilityByName] Parameter validation failed")
        return false
    end
    
    -- Get ability information using GetABs_name
    local Ability = API.GetABs_name(AbilityName, ExactMatch)
    if not Ability then
        self:Warn("[UseAbilityByName] Ability not found: " .. AbilityName)
        return false
    end
    
    if type(Ability) ~= "table" and type(Ability) ~= "userdata" then
        self:Error("[UseAbilityByName] Invalid ability data type: " .. type(Ability))
        return false
    end
    
    -- Check if ability is enabled
    if not Ability.enabled then
        self:Warn("[UseAbilityByName] Ability is not enabled: " .. AbilityName)
        return false
    end
    
    self:Info("[UseAbilityByName] Ability found and enabled. Attempting to use...")
    -- Attempt to use the ability
    local Result = API.DoAction_Ability(AbilityName,1,API.OFF_ACT_GeneralInterface_route,ExactMatch)
    if not Result then
        self:Error("[UseAbilityByName] Failed to use ability: " .. AbilityName)
        return false
    end
    
    self:Info("[UseAbilityByName] Ability used successfully: " .. AbilityName)
    return true
end

-- Moves the player to target coordinates using Dive and Surge
---@param X number The target X coordinate
---@param Y number The target Y coordinate  
---@param Z number The target Z coordinate
---@return boolean success True if movement was successful, false on failure
function Slib:MoveTo(X, Y, Z)
    -- Parameter validation
    if not self:ValidateParams({
        {X, "number", "X"},
        {Y, "number", "Y"},
        {Z, "number", "Z"}
    }) then
        return false
    end
    
    self:Info(string.format("[MoveTo] Starting movement to coordinates (%d, %d, %d)", X, Y, Z))
    
    -- Check if already at destination
    if self:IsPlayerAtCoords(X, Y, Z) then
        self:Info("[MoveTo] Already at destination")
        return true
    end
    
    local LastWalkTarget = nil
    local PlayerName = API.GetLocalPlayerName()
    local StuckCheckCount = 0
    local LastPosition = nil
    local MaxStuckChecks = 10  -- Fail after 10 consecutive checks of no movement/position change
    
    if not PlayerName then
        self:Error("[MoveTo] Failed to get player name")
        return false
    end
    
    while API.Read_LoopyLoop() do
        -- Check if we've reached the destination
        if self:IsPlayerAtCoords(X, Y, Z) then
            self:Info("[MoveTo] Successfully reached destination")
            return true
        end
        
        -- Get current player position
        local CurrentPos = API.PlayerCoord()
        if not CurrentPos then
            self:Error("[MoveTo] Failed to get player coordinates")
            return false
        end
        
        -- Calculate distance to target
        local DistanceToTarget = math.sqrt((X - CurrentPos.x)^2 + (Y - CurrentPos.y)^2)
        -- Only show position info every 10 iterations to reduce spam
        LoopCount = (LoopCount or 0) + 1
        if LoopCount % 10 == 1 then
            self:Info(string.format("[MoveTo] Position: (%d, %d, %d), Distance: %.1f", 
                CurrentPos.x, CurrentPos.y, CurrentPos.z, DistanceToTarget))
        end
        
        -- Check if player is moving
        local IsMoving = API.IsPlayerMoving_(PlayerName)
        
        -- Stuck detection - check if position hasn't changed and player isn't moving
        if LastPosition then
            local PositionChanged = (CurrentPos.x ~= LastPosition.x or CurrentPos.y ~= LastPosition.y)
            if not PositionChanged and not IsMoving then
                StuckCheckCount = StuckCheckCount + 1
                self:Warn(string.format("[MoveTo] Player appears stuck (check %d/%d)", StuckCheckCount, MaxStuckChecks))
                if StuckCheckCount >= MaxStuckChecks then
                    self:Error("[MoveTo] Player stuck - movement failed")
                    return false
                end
            else
                StuckCheckCount = 0  -- Reset stuck counter if player moved or position changed
            end
        end
        LastPosition = {x = CurrentPos.x, y = CurrentPos.y, z = CurrentPos.z}
        
        -- Try dive/surge when player is moving to enhance movement speed
        if IsMoving then
                -- Try dive first if available (bladed dive preferred over regular dive)
                local BladedDive = API.GetABs_id(30331)
                local RegularDive = API.GetABs_id(23714)
                
                local CanBladedDive = BladedDive and BladedDive.id ~= 0 and BladedDive.enabled and BladedDive.cooldown_timer < 1
                local CanRegularDive = RegularDive and RegularDive.id ~= 0 and RegularDive.enabled and RegularDive.cooldown_timer < 1
                
                if (CanBladedDive or CanRegularDive) and DistanceToTarget > 1 then
                    -- Dive directly to destination if within 10 tiles, otherwise dive 10 tiles toward destination
                    if DistanceToTarget <= 10 then
                        -- Dive directly to destination
                        if self:Dive(X, Y, Z) then
                            self:Info("[MoveTo] Dive to destination successful")
                            self:RandomSleep(100, 200, "ms")  -- Short delay after dive
                            -- Continue walking from new position toward destination
                            local WalkDistance = math.random(15, 30)
                            if DistanceToTarget > WalkDistance then
                                -- Calculate new intermediate walk point
                                local NewPos = API.PlayerCoord()
                                if NewPos then
                                    local DirectionX = X - NewPos.x
                                    local DirectionY = Y - NewPos.y
                                    local DirectionLength = math.sqrt(DirectionX^2 + DirectionY^2)
                                    local NormalizedX = DirectionX / DirectionLength
                                    local NormalizedY = DirectionY / DirectionLength
                                    local WalkX = math.floor(NewPos.x + (NormalizedX * WalkDistance))
                                    local WalkY = math.floor(NewPos.y + (NormalizedY * WalkDistance))
                                    self:WalkToCoordinates(WalkX, WalkY, Z)
                                    LastWalkTarget = {x = WalkX, y = WalkY, z = Z}
                                end
                            else
                                self:WalkToCoordinates(X, Y, Z)
                                LastWalkTarget = {x = X, y = Y, z = Z}
                            end
                            goto continue_loop
                        end
                    else
                        -- Dive 10 tiles toward destination (max dive range)
                        local DiveRange = 10  -- Maximum dive distance
                        local DirectionX = X - CurrentPos.x
                        local DirectionY = Y - CurrentPos.y
                        local DirectionLength = math.sqrt(DirectionX^2 + DirectionY^2)
                        
                        -- Calculate dive point (10 tiles toward destination)
                        local NormalizedX = DirectionX / DirectionLength
                        local NormalizedY = DirectionY / DirectionLength
                        local DiveX = math.floor(CurrentPos.x + (NormalizedX * DiveRange))
                        local DiveY = math.floor(CurrentPos.y + (NormalizedY * DiveRange))
                        
                        if self:Dive(DiveX, DiveY, Z) then
                            self:Info("[MoveTo] Dive toward destination successful")
                            self:RandomSleep(200, 400, "ms")  -- Short delay after dive
                            -- Continue walking from new position toward destination
                            local WalkDistance = math.random(15, 30)
                            if DistanceToTarget > WalkDistance then
                                -- Calculate new intermediate walk point from new position
                                local NewPos = API.PlayerCoord()
                                if NewPos then
                                    local NewDirectionX = X - NewPos.x
                                    local NewDirectionY = Y - NewPos.y
                                    local NewDirectionLength = math.sqrt(NewDirectionX^2 + NewDirectionY^2)
                                    local NewNormalizedX = NewDirectionX / NewDirectionLength
                                    local NewNormalizedY = NewDirectionY / NewDirectionLength
                                    local WalkX = math.floor(NewPos.x + (NewNormalizedX * WalkDistance))
                                    local WalkY = math.floor(NewPos.y + (NewNormalizedY * WalkDistance))
                                    self:WalkToCoordinates(WalkX, WalkY, Z)
                                    LastWalkTarget = {x = WalkX, y = WalkY, z = Z}
                                end
                            else
                                self:WalkToCoordinates(X, Y, Z)
                                LastWalkTarget = {x = X, y = Y, z = Z}
                            end
                            goto continue_loop
                        end
                    end
                end
                
                -- Try surge if available and facing a compatible direction
                local Surge = API.GetABs_id(14233)
                local CanSurge = Surge and Surge.id ~= 0 and Surge.enabled and Surge.cooldown_timer < 1
                
                if CanSurge then
                    -- Get player facing direction using PlayerFacing helper function
                    local PlayerDirection = self:PlayerFacing()
                    
                    -- Determine target direction (walk target if available, otherwise destination)
                    local TargetX, TargetY
                    if LastWalkTarget then
                        TargetX = LastWalkTarget.x
                        TargetY = LastWalkTarget.y
                    else
                        TargetX = X
                        TargetY = Y
                    end
                    
                    local DeltaX = TargetX - CurrentPos.x
                    local DeltaY = TargetY - CurrentPos.y
                    
                    -- Calculate required movement direction based on position deltas
                    local MovementDirection
                    if math.abs(DeltaX) > math.abs(DeltaY) then
                        -- More horizontal movement
                        if DeltaX > 0 then
                            MovementDirection = math.abs(DeltaY) > math.abs(DeltaX) * 0.4 and (DeltaY > 0 and "NE" or "SE") or "E"
                        else
                            MovementDirection = math.abs(DeltaY) > math.abs(DeltaX) * 0.4 and (DeltaY > 0 and "NW" or "SW") or "W"
                        end
                    else
                        -- More vertical movement
                        if DeltaY > 0 then
                            MovementDirection = math.abs(DeltaX) > math.abs(DeltaY) * 0.4 and (DeltaX > 0 and "NE" or "NW") or "N"
                        else
                            MovementDirection = math.abs(DeltaX) > math.abs(DeltaY) * 0.4 and (DeltaX > 0 and "SE" or "SW") or "S"
                        end
                    end
                    
                    -- Check if player is facing movement direction or compatible adjacent direction
                    local CanSurgeInDirection = false
                    if PlayerDirection == MovementDirection then
                        CanSurgeInDirection = true
                    else
                        -- Allow surge for adjacent compass directions (e.g., N and NE are compatible)
                        local CompatibleDirections = {
                            N = {"NE", "NW"},
                            NE = {"N", "E"},
                            E = {"NE", "SE"},
                            SE = {"E", "S"},
                            S = {"SE", "SW"},
                            SW = {"S", "W"},
                            W = {"SW", "NW"},
                            NW = {"W", "N"}
                        }
                        
                        if CompatibleDirections[PlayerDirection] then
                            for _, compatDir in ipairs(CompatibleDirections[PlayerDirection]) do
                                if compatDir == MovementDirection then
                                    CanSurgeInDirection = true
                                    break
                                end
                            end
                        end
                    end
                    
                    if CanSurgeInDirection then
                        if self:UseAbilityById(14233) then  -- Surge ability ID
                            self:Info("[MoveTo] Surge successful")
                            self:RandomSleep(200, 400, "ms")  -- Short delay after surge
                            -- Continue walking from new position toward destination
                            local WalkDistance = math.random(15, 30)
                            local NewPos = API.PlayerCoord()
                            if NewPos then
                                local NewDistanceToTarget = math.sqrt((X - NewPos.x)^2 + (Y - NewPos.y)^2)
                                if NewDistanceToTarget > WalkDistance then
                                    -- Calculate new intermediate walk point from post-surge position
                                    local DirectionX = X - NewPos.x
                                    local DirectionY = Y - NewPos.y
                                    local DirectionLength = math.sqrt(DirectionX^2 + DirectionY^2)
                                    local NormalizedX = DirectionX / DirectionLength
                                    local NormalizedY = DirectionY / DirectionLength
                                    local WalkX = math.floor(NewPos.x + (NormalizedX * WalkDistance))
                                    local WalkY = math.floor(NewPos.y + (NormalizedY * WalkDistance))
                                    self:WalkToCoordinates(WalkX, WalkY, Z)
                                    LastWalkTarget = {x = WalkX, y = WalkY, z = Z}
                                else
                                    self:WalkToCoordinates(X, Y, Z)
                                    LastWalkTarget = {x = X, y = Y, z = Z}
                                end
                            end
                            goto continue_loop
                        end
                    end
                end
        else
            -- Player not moving - initiate or restart walking
            local ShouldWalk = false
            local DistanceToLastWalk = 0
            
            if LastWalkTarget == nil then
                -- First iteration, always walk
                ShouldWalk = true
                self:Info("[MoveTo] Initiating walk")
            else
                -- Calculate distance to last walk target
                DistanceToLastWalk = math.sqrt((LastWalkTarget.x - CurrentPos.x)^2 + (LastWalkTarget.y - CurrentPos.y)^2)
                
                if DistanceToLastWalk <= 7 then
                    ShouldWalk = true
                else
                    ShouldWalk = true
                    self:Info("[MoveTo] Restarting walk")
                end
            end
            
            if ShouldWalk then
                -- Walk 15-30 random tiles toward destination
                local WalkDistance = math.random(15, 30)
                
                -- Walk directly to destination if within walk distance, otherwise walk intermediate distance
                if DistanceToTarget <= WalkDistance then
                    if self:WalkToCoordinates(X, Y, Z) then
                        LastWalkTarget = {x = X, y = Y, z = Z}
                        self:Info("[MoveTo] Walking to destination")
                    else
                        self:Error("[MoveTo] Failed to walk to target coordinates")
                        return false
                    end
                else
                    -- Calculate intermediate walk point toward destination
                    local DirectionX = X - CurrentPos.x
                    local DirectionY = Y - CurrentPos.y
                    local DirectionLength = math.sqrt(DirectionX^2 + DirectionY^2)
                    
                    -- Normalize direction vector and scale to walk distance
                    local NormalizedX = DirectionX / DirectionLength
                    local NormalizedY = DirectionY / DirectionLength
                    
                    local WalkX = math.floor(CurrentPos.x + (NormalizedX * WalkDistance))
                    local WalkY = math.floor(CurrentPos.y + (NormalizedY * WalkDistance))
                    
                    if self:WalkToCoordinates(WalkX, WalkY, Z) then
                        LastWalkTarget = {x = WalkX, y = WalkY, z = Z}
                        self:Info(string.format("[MoveTo] Walking %d tiles toward target", WalkDistance))
                    else
                        self:Error("[MoveTo] Failed to walk to intermediate coordinates")
                        return false
                    end
                end
                
                -- Brief delay after initiating walk to allow movement to start
                self:RandomSleep(500, 1000, "ms")
            else
                -- Wait briefly for movement status update
                self:Sleep(200, "ms")
            end
        end
        
        ::continue_loop::
        
        -- Small delay before next loop iteration
        self:Sleep(200, "ms")
    end
    
    -- Movement loop exited without success (should not normally reach here)
    self:Error("[MoveTo] Movement loop ended unexpectedly")
    return false
end

-- Teleports the player to Guthix Memorial using the Memory Strand currency from the currency pouch
---@return boolean success True if teleport was successful, false if Memory Strand not found or teleport failed
function Slib:MemoryStrandTeleport()
    if not self:CurrencyPouchContains(39486) then
        self:Error("[MemoryStrandTeleport] Memory Strand not found in currency pouch")
        return false
    end

    local PouchLoaded = true
    local Bonds = API.ScanForInterfaceTest2Get(true, self.Interfaces.CurrencyPouch[1])[1]

    if Bonds and Bonds.itemid2 == 0 then
        API.DoAction_Interface(0x24, 0x9A3E, 1, 1473, 10, 4097, API.OFF_ACT_GeneralInterface_route) -- Open currency pouch
        PouchLoaded = false
    end

    while API.Read_LoopyLoop() and not (self:IsPlayerInArea(2265, 3554, 0, 20) or self:IsPlayerInArea(2293, 3554, 0, 5)) do
        self:Info("[MemoryStrandTeleport] Attempting to use Memory Strand teleport...")
        API.DoAction_Interface(0x24,0x9A3E,1,1473,21,10,API.OFF_ACT_GeneralInterface_route) -- Memory Strand teleport
        self:SleepUntil(function()
            return self:IsPlayerInArea(2265, 3554, 0, 20) or self:IsPlayerInArea(2293, 3554, 0, 20)
        end, 6, 100)
    end

    if not PouchLoaded then
        API.DoAction_Interface(0x24, 0x9A3E, 1, 1473, 15, -1, API.OFF_ACT_GeneralInterface_route) -- Close currency pouch
        PouchLoaded = true
    end

    return true
end

-- Uses incense sticks and keep them active
---@param BuffID number
---@return boolean
function Slib:CheckIncenseStick(BuffID)
    -- Parameter validation
    if not self:ValidateParams({
        {BuffID, "id", "buffID"}
    }) then
        return false
    end

    self:Info("[CheckIncenseStick] Checking incense stick buff: " .. BuffID)
    
    -- Get all active buffs
    local buffs = API.Buffbar_GetAllIDs()
    if not buffs then
        self:Error("[CheckIncenseStick] Failed to get buff information")
        return false
    end
    
    -- Check if the buff is active
    local found = false
    for _, object in ipairs(buffs) do
        if object.id == BuffID then
            found = true
            self:Info("[CheckIncenseStick] Found active incense stick buff")
            
            -- Parse buff information
            local time, level = string.match(object.text, "(%d+)%a* %((%d+)%)")
            time = tonumber(time)
            level = tonumber(level)
            
            if not time or not level then
                self:Error("[CheckIncenseStick] Failed to parse buff time or level")
                return false
            end
            
            -- Check and maintain buff level
            if level < 4 then
                self:Info("[CheckIncenseStick] Buff level low (" .. level .. "), applying overload...")
                API.DoAction_Inventory1(BuffID,0,2,API.OFF_ACT_GeneralInterface_route)
                for i = 1, 5 do
                    API.DoAction_Inventory1(BuffID,0,1,API.OFF_ACT_GeneralInterface_route)
                    self:RandomSleep(50, 100, "ms")
                end
            end
            
            -- Check and extend duration if needed with granular approach
            local interactions = 0
            if time < 50 then
                if time < 10 then
                    interactions = 5
                elseif time < 20 then
                    interactions = 4
                elseif time < 30 then
                    interactions = 3
                elseif time < 40 then
                    interactions = 2
                else -- time < 50
                    interactions = 1
                end
                
                self:Info("[CheckIncenseStick] Buff duration low (" .. time .. "m), extending " .. interactions .. " times...")
                for i = 1, interactions do
                    API.DoAction_Inventory1(BuffID,0,1,API.OFF_ACT_GeneralInterface_route)
                    self:RandomSleep(100, 300, "ms")
                end
            end
            break
        end
    end
    
    -- If buff not found, apply new buff
    if not found then
        self:Info("[CheckIncenseStick] Buff not active, applying new buff...")
        -- Apply overload
        API.DoAction_Inventory1(BuffID,0,2,API.OFF_ACT_GeneralInterface_route)
        self:RandomSleep(100, 300, "ms")
        
        -- Extend multiple times
        self:Info("[CheckIncenseStick] Extending new buff...")
        for i = 1, 5 do
            API.DoAction_Inventory1(BuffID,0,1,API.OFF_ACT_GeneralInterface_route)
            self:RandomSleep(100, 300, "ms")
        end
        self:Info("[CheckIncenseStick] New buff applied and extended")
        return true
    end

    return true
end

-- Recharges silverhawk boots when stored feathers are below minimum quantity
---@param MinQuantity number The minimum quantity of feathers to maintain
---@return boolean success True if boots were recharged successfully, false if no boots found or no feathers available
function Slib:RechargeSilverhawkBoots(MinQuantity)
    -- Parameter validation
    if not self:ValidateParams({
        {MinQuantity, "positive_number", "MinQuantity"}
    }) then
        return false
    end
   
    -- Check if boots are equipped
    local Boots = API.Container_Get_s(94, 30924)  -- 94 = equipment, 30924 = silverhawk boots
    if not Boots or not Boots.item_id or Boots.item_id ~= 30924 then
        self:Error("[RechargeSilverhawkBoots] Silverhawk boots not found in equipment")
        return false
    end
    
    local CurrentFeathers = Boots.Extra_ints[2]
    self:Info(string.format("[RechargeSilverhawkBoots] Current feathers: %d (Minimum: %d)", CurrentFeathers, MinQuantity))
    
    -- Check if recharge is needed
    if CurrentFeathers >= MinQuantity then
        self:Info("[RechargeSilverhawkBoots] Feather quantity sufficient")
        return false
    end
    
    -- Check for regular silverhawk feathers
    local HasFeathers = API.CheckInvStuff0(30915)
    if HasFeathers then
        self:Info("[RechargeSilverhawkBoots] Using regular silverhawk feathers")
        API.DoAction_Inventory1(30915,0,1,API.OFF_ACT_GeneralInterface_route)
        return true
    end

    -- Check for silverhawk down
    local HasDown = API.CheckInvStuff0(34823)
    if HasDown then
        self:Info("[RechargeSilverhawkBoots] Using silverhawk down")
        API.DoAction_Inventory1(34823,0,1,API.OFF_ACT_GeneralInterface_route)
        return true
    end
    
    self:Warn("[RechargeSilverhawkBoots] No feathers or down found in inventory")
    return false
end

-- Takes specified items from the area loot interface, prioritizing last slot first
---@param ItemIds number|table|string The item ID, table of item IDs, or strings ("custom", "all") to take from area loot
---@return boolean success True if all specified items were taken successfully, false otherwise
function Slib:AreaLootTakeItems(ItemIds)
    -- Parameter validation
    if not self:Sanitize(ItemIds, {"number", "table_of_ids", "string"}, "ItemIds") then
        return false
    end

     -- Check if area loot is open
     if not self:AreaLootIsOpen() then
        self:Error("[AreaLootTakeItems] Area loot interface is not open")
        return false
    end
    
    -- Handle special string cases
    if type(ItemIds) == "string" then
        local lowerItemIds = string.lower(ItemIds)
        
        if lowerItemIds == "custom" then
            self:Info("[AreaLootTakeItems] Taking custom loot selection...")
            API.DoAction_Interface(0x24, 0xffffffff, 1, 1622, 30, -1, API.OFF_ACT_GeneralInterface_route)
            return true
        elseif lowerItemIds == "all" then
            self:Info("[AreaLootTakeItems] Taking all loot...")
            API.DoAction_Interface(0x24, 0xffffffff, 1, 1622, 22, -1, API.OFF_ACT_GeneralInterface_route)
            return true
        else
            self:Error("[AreaLootTakeItems] Invalid string parameter: '" .. ItemIds .. "'. Valid options: 'custom', 'all'")
            return false
        end
    end
    
    -- Convert to table for consistent processing
    local IdTable = type(ItemIds) == "table" and ItemIds or {ItemIds}

    -- Get all items in area loot
    local Items = self:AreaLootGetItems()
    if not Items or #Items == 0 then
        self:Warn("[AreaLootTakeItems] No items found in area loot")
        return false
    end
    
    -- Track which IDs we need to take
    local targetIds = {}
    for _, id in ipairs(IdTable) do
        targetIds[id] = true
    end
    
    -- Find matching items and sort by slot (highest slot first for last-slot-first priority)
    local matchingItems = {}
    for _, item in ipairs(Items) do
        local itemId = item[1]
        local itemSlot = item[2]
        
        if targetIds[itemId] then
            table.insert(matchingItems, {itemId = itemId, slot = itemSlot})
            self:Info("[AreaLootTakeItems] Found target item: ID " .. itemId .. " in slot " .. itemSlot)
        end
    end
    
    if #matchingItems == 0 then
        self:Warn("[AreaLootTakeItems] No matching items found in area loot")
        return false
    end
    
    -- Sort by slot in descending order (highest slot first = last slot first)
    table.sort(matchingItems, function(a, b)
        return a.slot > b.slot
    end)
    
    local takenCount = 0
    local totalToTake = #matchingItems
        
    -- Take each matching item, starting from the last slot
    for i, item in ipairs(matchingItems) do
        local itemId = item.itemId
        local itemSlot = item.slot
        
        self:Info("[AreaLootTakeItems] Taking item " .. i .. "/" .. totalToTake .. ": ID " .. itemId .. " from slot " .. itemSlot)
        API.DoAction_Interface(0xffffffff, itemId, 1, 1622, 11, itemSlot, API.OFF_ACT_GeneralInterface_route)
        takenCount = takenCount + 1
            
        -- Small delay between taking items to prevent spam
        self:RandomSleep(50, 300, "ms")
    end
    
    local success = takenCount == totalToTake
    if success then
        self:Info("[AreaLootTakeItems] Successfully took all " .. takenCount .. " items from area loot")
    else
        self:Warn("[AreaLootTakeItems] Only took " .. takenCount .. "/" .. totalToTake .. " items from area loot")
    end
    
    return success
end

-- Types text character by character using virtual key codes with timing delays
---@param Text string The text to type character by character
---@return boolean success True if text was typed successfully, false if invalid parameters or typing failed
function Slib:TypeText(Text)
    -- Parameter validation
    if not self:ValidateParams({
        {Text, "non_empty_string", "Text"}
    }) then
        return false
    end
    
    self:Info("[TypeText] Starting to type text: '" .. Text .. "' (" .. #Text .. " characters)")
    
    local SuccessfulChars = 0
    local TotalChars = #Text
    
    -- Iterate through each character in the text string
    for CharacterIndex = 1, TotalChars do
        -- Extract the current character from the text
        local CurrentCharacter = Text:sub(CharacterIndex, CharacterIndex)
        
        -- Convert the character to its virtual key code
        local VirtualKeyCode = self:CharToVirtualKey(CurrentCharacter)
        
        -- Validate that we got a valid key code
        if not VirtualKeyCode or VirtualKeyCode == 0 then
            self:Error("[TypeText] Failed to get virtual key code for character: '" .. CurrentCharacter .. "' at position " .. CharacterIndex)
            return false
        end
        
        -- Press the key with timing delays (40ms press, 60ms release)
        local KeyResult = API.KeyboardPress2(VirtualKeyCode, 40, 60)
        if not KeyResult then
            self:Error("[TypeText] Failed to send key press for character: '" .. CurrentCharacter .. "' (VK: " .. VirtualKeyCode .. ") at position " .. CharacterIndex)
            return false
        end
        
        SuccessfulChars = SuccessfulChars + 1
        
        -- Small delay between characters to prevent input buffer overflow
        if CharacterIndex < TotalChars then
            self:Sleep(50, "ms")
        end
    end
    
    if SuccessfulChars == TotalChars then
        self:Info("[TypeText] Successfully typed all " .. TotalChars .. " characters")
        return true
    else
        self:Error("[TypeText] Only typed " .. SuccessfulChars .. "/" .. TotalChars .. " characters successfully")
        return false
    end
end

-- Sets instance interface options to specified values
---@param MaxPlayers number|nil Target maximum players (or nil to skip)
---@param MinCombat number|nil Target minimum combat level (or nil to skip)
---@param SpawnSpeed string|nil Target spawn speed ("Standard", "Fast", "Fastest", or nil to skip)
---@param Protection string|nil Target protection ("FFA", "PIN", "Friends only", "Friends Chat only", or nil to skip)
---@param PracticeMode boolean|nil Target practice mode state (or nil to skip)
---@param HardMode boolean|nil Target hard mode state (or nil to skip)
---@return boolean Success True if all settings were applied successfully
function Slib:SetInstanceInterfaceOptions(MaxPlayers, MinCombat, SpawnSpeed, Protection, PracticeMode, HardMode)
    -- Parameter validation
    if not self:ValidateParams({
        {MaxPlayers, "positive_number", "MaxPlayers", true}, -- allow_nil = true
        {MinCombat, "non_negative_number", "MinCombat", true}, -- allow_nil = true
        {SpawnSpeed, "string", "SpawnSpeed", true}, -- allow_nil = true
        {Protection, "string", "Protection", true}, -- allow_nil = true
        {PracticeMode, "boolean", "PracticeMode", true}, -- allow_nil = true
        {HardMode, "boolean", "HardMode", true} -- allow_nil = true
    }) then
        return false
    end
    
    -- Validate SpawnSpeed against allowed values
    if SpawnSpeed ~= nil then
        local ValidSpawnSpeeds = {"Standard", "Fast", "Fastest"}
        local SpeedValid = false
        for _, ValidSpeed in ipairs(ValidSpawnSpeeds) do
            if SpawnSpeed == ValidSpeed then
                SpeedValid = true
                break
            end
        end
        if not SpeedValid then
            self:Error("[SetInstanceInterfaceOptions] Invalid SpawnSpeed. Must be one of: Standard, Fast, Fastest (got: " .. tostring(SpawnSpeed) .. ")")
            return false
        end
    end
    
    -- Validate Protection against allowed values
    if Protection ~= nil then
        local ValidProtections = {"FFA", "PIN", "Friends only", "Friends Chat only"}
        local ProtectionValid = false
        for _, ValidProtection in ipairs(ValidProtections) do
            if Protection == ValidProtection then
                ProtectionValid = true
                break
            end
        end
        if not ProtectionValid then
            self:Error("[SetInstanceInterfaceOptions] Invalid Protection. Must be one of: FFA, PIN, Friends only, Friends Chat only (got: " .. tostring(Protection) .. ")")
            return false
        end
    end

    if not self:InstanceInterfaceIsOpen() then
        self:Error("[SetInstanceInterfaceOptions] Instance interface is not open")
        return false
    end

    local CurrentOptions = self:GetInstanceInterfaceOptions()
    if not CurrentOptions then
        self:Error("[SetInstanceInterfaceOptions] Failed to get current interface options")
        return false
    end

    for i = 1, 2 do --Needed to run 2 times in case HM is checked and practice mode is passed as true
        -- Set PracticeMode
        if PracticeMode ~= nil and CurrentOptions.PracticeMode ~= PracticeMode then
            API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1591, 113, -1, API.OFF_ACT_GeneralInterface_route)
            self:RandomSleep(600, 1000, "ms")
        end

        -- Set HardMode
        if HardMode ~= nil and CurrentOptions.HardMode ~= HardMode then
            API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1591, 4, -1, API.OFF_ACT_GeneralInterface_route)
            self:RandomSleep(600, 1000, "ms")
        end
        self:RandomSleep(1000, 3000, "ms")
    end

    CurrentOptions = self:GetInstanceInterfaceOptions() --Update options in case HM checkbox was checked, which makes MaxPlayers always 1 on the first read

    -- Set MaxPlayers
    if MaxPlayers and CurrentOptions.MaxPlayers then
        local Difference = MaxPlayers - CurrentOptions.MaxPlayers
        if Difference > 0 then
            for i = 1, Difference do
                API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1591, 25, -1, API.OFF_ACT_GeneralInterface_route)
                self:RandomSleep(100, 300, "ms")
            end
        elseif Difference < 0 then
            for i = 1, math.abs(Difference) do
                API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1591, 24, -1, API.OFF_ACT_GeneralInterface_route)
                self:RandomSleep(100, 300, "ms")
            end
        end
    end

    -- Set MinCombat
    if MinCombat and CurrentOptions.MinCombat then
        local Difference = MinCombat - CurrentOptions.MinCombat
        if Difference > 0 then
            for i = 1, Difference do
                API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1591, 29, -1, API.OFF_ACT_GeneralInterface_route)
                self:RandomSleep(100, 300, "ms")
            end
        elseif Difference < 0 then
            for i = 1, math.abs(Difference) do
                API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1591, 28, -1, API.OFF_ACT_GeneralInterface_route)
                self:RandomSleep(100, 300, "ms")
            end
        end
    end

    -- Set SpawnSpeed
    if SpawnSpeed then
        local SpawnSpeedMap = {["Standard"] = 1, ["Fast"] = 2, ["Fastest"] = 3}
        local CurrentSpeedMap = {["Standard"] = 1, ["Fast"] = 2, ["Fastest"] = 3}

        local TargetIndex = SpawnSpeedMap[SpawnSpeed]
        local CurrentIndex = CurrentSpeedMap[CurrentOptions.SpawnSpeed]

        if TargetIndex and CurrentIndex then
            local Difference = TargetIndex - CurrentIndex
            if Difference > 0 then
                for i = 1, Difference do
                    API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1591, 33, -1, API.OFF_ACT_GeneralInterface_route)
                    self:RandomSleep(100, 300, "ms")
                end
            elseif Difference < 0 then
                for i = 1, math.abs(Difference) do
                    API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1591, 32, -1, API.OFF_ACT_GeneralInterface_route)
                    self:RandomSleep(100, 300, "ms")
                end
            end
        end
    end

    -- Set Protection
    if Protection then
        local ProtectionMap = {["FFA"] = 1, ["PIN"] = 2, ["Friends only"] = 3, ["Friends Chat only"] = 4}

        -- Helper function to get protection index from current value
        local function GetProtectionIndex(ProtectionValue)
            if not ProtectionValue then
                return nil
            end

            if ProtectionValue == "FFA" then
                return 1
            elseif ProtectionValue:match("^PIN:") then -- Handles "PIN: 1", "PIN: 2", etc.
                return 2
            elseif ProtectionValue == "Friends only" then
                return 3
            elseif ProtectionValue == "Friends Chat only" then
                return 4
            end
            return nil
        end

        local TargetIndex = ProtectionMap[Protection]
        local CurrentIndex = GetProtectionIndex(CurrentOptions.Protection)

        if TargetIndex and CurrentIndex then
            local Difference = TargetIndex - CurrentIndex
            if Difference > 0 then
                for i = 1, Difference do
                    API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1591, 37, -1, API.OFF_ACT_GeneralInterface_route)
                    self:RandomSleep(100, 300, "ms")
                end
            elseif Difference < 0 then
                for i = 1, math.abs(Difference) do
                    API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1591, 36, -1, API.OFF_ACT_GeneralInterface_route)
                    self:RandomSleep(100, 300, "ms")
                end
            end
        end
    end

    self:Info("[SetInstanceInterfaceOptions] Successfully applied interface settings")
    return true
end

-- Starts a new instance
---@return boolean
function Slib:InstanceStart()
    if not self:InstanceInterfaceIsOpen() then
        self:Error("[InstanceStart] Instance interface is not open")
        return false
    end

    API.DoAction_Interface(0x24, 0xffffffff, 1, 1591, 60, -1, API.OFF_ACT_GeneralInterface_route)
    self:Info("[InstanceStart] Started instance")

    return true
end

-- Joins another player's instance by typing their name
---@param PlayerName string The name of the player whose instance to join
---@return boolean Success True if join sequence completed successfully, false if interface not open or invalid name
function Slib:InstanceJoin(PlayerName)
    -- Validate interface state
    if not self:InstanceInterfaceIsOpen() then
        self:Error("[InstanceJoin] Instance interface is not open")
        return false
    end

    -- Validate PlayerName parameter
    if not self:ValidateParams({
        {PlayerName, "non_empty_string", "PlayerName"}
    }) then
        self:Error("[InstanceJoin] Invalid player name provided")
        return false
    end

    self:Info("[InstanceJoin] Initiating join to player: " .. PlayerName)
    
    -- Open text input dialog
    local Result = API.DoAction_Interface(0x24, 0xffffffff, 1, 1591, 108, -1, API.OFF_ACT_GeneralInterface_route)
    if not Result then
        self:Error("[InstanceJoin] Failed to open text input dialog")
        return false
    end

    -- Wait for text input interface to open
    local InputOpened = self:SleepUntil(function()
        return self:TextInputIsOpen()
    end, 10, 100)

    if not InputOpened then
        self:Error("[InstanceJoin] Text input interface failed to open within timeout")
        return false
    end

    -- Safety delay to ensure interface is fully loaded
    self:RandomSleep(2000, 4000, "ms")

    -- Type player name using TypeText function
    self:Info("[InstanceJoin] Typing player name: " .. PlayerName)
    if not self:TypeText(PlayerName) then
        self:Error("[InstanceJoin] Failed to type player name")
        return false
    end
    
    -- Confirm input with Enter key
    self:Info("[InstanceJoin] Confirming input with Enter key")
    local EnterResult = API.KeyboardPress2(0x0D, 50, 80) -- VK_RETURN
    if not EnterResult then
        self:Error("[InstanceJoin] Failed to send Enter key")
        return false
    end
    
    self:Info("[InstanceJoin] Successfully completed join sequence for: " .. PlayerName)
    return true
end

-- Rejoins an existing instance
---@return boolean
function Slib:InstanceRejoin()
    if not self:InstanceInterfaceIsOpen() then
        self:Error("[InstanceRejoin] Instance interface is not open")
        return false
    end
    
    API.DoAction_Interface(0x24, 0xffffffff, 1, 1591, 122, -1, API.OFF_ACT_GeneralInterface_route)
    self:Info("[InstanceRejoin] Rejoined instance")
        
    return true
end

return Slib
