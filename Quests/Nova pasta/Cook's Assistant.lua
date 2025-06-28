ScriptName = "Cook's Assistant Quest"
Author = "Jao"


local API = require("api")
local LODESTONES = require("lodestones")
local QUEST = require("quest")
local UTILS = require("utils")
local AdventureInterface = {{1500, 0, -1, 0}, {1500, 1, -1, 0}, {1500, 22, -1, 0}}
API.Read_LoopyLoop()
API.SetMaxIdleTime(10)
startTime, afk, questStart = os.time(), os.time(), os.time()

-- Quest data - Using the Quest API properly
local questData = Quest:Get("Cook's Assistant")

-- Verify quest was found
if not questData then
    print("ERROR: Could not find Cook's Assistant quest!")
    API.Write_LoopyLoop(false)
    return
end

ID = {
    COOK = 278,
    MILK = 1927,
    EGG = 15412,
    FLOUR = 15414,
    BUCKET = 1925,
    DAIRY_COW = 47721,
    CHICKEN = 1459,
    WHEAT = 1947,
    GRAIN = 1940,
    WINDMILL_DOOR = 45966,
    WINDMILL_STAIRSUP = 36775,
    WINDMILL_STAIRSDOWN = 36797,
    WINDMILL_CONTROLS = 2718,
    FLOUR_BIN = 36878,
    GENERAL_STORE_KEEPER = 528,
    MILLIE_MILLER = 3806
}
local ChatOptions = {
    "What's wrong?", "I'll get the ingredients for you.", 
    "I'm looking for extra fine flour.",
    "I'm fine, thanks.", "I have the ingredients!"
}

-- Step control
CURRENT_STEP = 1
TOTAL_STEPS = 10

-- Print quest information
print("=== Cook's Assistant Quest Bot ===")
print("Quest ID: " .. questData.id)
print("Members Only: " .. tostring(questData.members))
print("Points Reward: " .. questData.points_reward)
print("Points Required: " .. questData.points_required)


local function HandleDialog()
    if not QUEST:DialogBoxOpen() then
        return false
    end

    while API.Read_LoopyLoop() and QUEST:DialogBoxOpen() do
        if QUEST:HasOption() then
            QUEST:OptionSelector(ChatOptions)
        else
            QUEST:PressSpace()
        end
        QUEST:Sleep(0.2)
    end

    return true
end

local function IsAcceptQuestInterfaceOpen()
    return #API.ScanForInterfaceTest2Get(true, AdventureInterface) > 0
end

local function questFunction()
    -- Anti-idle
    UTILS:antiIdle()
    if IsAcceptQuestInterfaceOpen() then
        print("Accepting quest interface detected. Clicking accept.")
        API.DoAction_Interface(0x24, 0xffffffff, 1, 1500, 409, -1, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(2000, 500)
        return
    end

    -- Handle dialogs first
    if HandleDialog() then
        return
    end

    -- Handle cutscenes
    if QUEST:IsInCutscene() then
        print("In cutscene, waiting...")
        QUEST:Sleep(2)
        return
    end

    -- Get current quest progress
    local progress = questData:getProgress()
    print("Current Step: " .. CURRENT_STEP .. "/" .. TOTAL_STEPS .. " | Quest Progress: " .. progress)

    -- STEP 1: Check if quest is already complete
    if CURRENT_STEP == 1 then
        if questData:isComplete() then
            print("Quest already completed!")
            API.Write_LoopyLoop(false)
            return
        end

        CURRENT_STEP = 2
        goto continue
    end

    -- STEP 2: Go to Lumbridge if not there
    if CURRENT_STEP == 2 then
        if not questData:isStarted() and not QUEST:IsPlayerInArea(3220, 3220, 0, 50) then
            print("Step 2: Teleporting to Lumbridge...")
            LODESTONES.LUMBRIDGE.Teleport()

        else
            CURRENT_STEP = 3
            goto continue
        end
    end

    -- STEP 3: Start quest with Cook
    if CURRENT_STEP == 3 then
        if not questData:isStarted() then
            print("Step 3: Starting quest with Cook...")

            -- Move to castle
            if not QUEST:IsPlayerInArea(3208, 3214, 0, 5) then
                QUEST:MoveTo(3208, 3214, 0, 3)
            end

            -- Talk to cook
            if API.DoAction_NPC(0x2c, API.OFF_ACT_InteractNPC_route, {ID.COOK}, 50) then
                print("[DEBUG] Interacting with Cook NPC...")

                -- Espera até que o diálogo comece (com timeout)
                local timeout = os.time() + 5
                while os.time() < timeout do
                    if QUEST:DialogBoxOpen() then
                        HandleDialog()
                        return
                    end

                    QUEST:Sleep(0.2)
                end

                print("[DEBUG] No dialog appeared after interacting with NPC.")
            end

        else
            CURRENT_STEP = 5 -- Quest already started, skip to ingredients
            goto continue
        end
    end

    -- STEP 5: Get milk from cow
    if CURRENT_STEP == 5 then
        print("Step 5: Getting milk from cow...")
        if API.InvItemcount_String("Top-quality milk") == 0 then
            -- Move to cow field gate
            QUEST:MoveTo(3251, 3266, 0, 5)
            QUEST:Sleep(1)

            -- Open gate if needed
            if API.DoAction_Object_valid1(0x31, API.OFF_ACT_GeneralObject_route0, {45210}, 10, true) then
                QUEST:Sleep(2)
                API.WaitUntilMovingEnds(5, 3)
            end

            -- Move closer to cows
            QUEST:MoveTo(3262, 3277, 0, 1)

            if API.InvItemcount_1(ID.BUCKET) == 0 then
                API.DoAction_G_Items1(0x2d, {ID.BUCKET}, 10)
                QUEST:Sleep(2)
                API.DoAction_Loot_w({ID.BUCKET}, 10, API.PlayerCoordfloat(), 10)
                QUEST:Sleep(1)
            end
            -- Milk cow
            if API.DoAction_Object1(0x29, API.OFF_ACT_GeneralObject_route0, {ID.DAIRY_COW}, 50) then
                QUEST:Sleep(2)
                API.WaitUntilMovingandAnimEnds(10, 3)
            end

        else
            CURRENT_STEP = 6
            goto continue
        end
    end

    -- STEP 6: Get egg
    if CURRENT_STEP == 6 then
        if API.InvItemcount_String("Super large egg") == 0 then
            print("Step 6: Getting egg from chicken coop...")

            -- Move to chicken coop area
            QUEST:MoveTo(3206, 3281, 0, 2)
            API.DoAction_Object_valid1(0x31, API.OFF_ACT_GeneralObject_route0, {45208}, 10, true)
            QUEST:Sleep(3)
            API.WaitUntilMovingEnds()
            -- Look for egg on ground or in coop
            if QUEST:DoesObjectExist(ID.EGG, 20, 3) then
                API.DoAction_Loot_w({ID.EGG}, 10, API.PlayerCoordfloat(), 10)
                QUEST:Sleep(3)
            else

                print("Waiting for egg to respawn...")
                QUEST:Sleep(5)

            end
        else
            CURRENT_STEP = 7
            goto continue
        end
    end

    -- STEP 7: Get wheat
    if CURRENT_STEP == 7 then
        if API.InvItemcount_1(ID.WHEAT) == 0 and API.InvItemcount_String("Extra fine flour") == 0 then
            print("Step 7: Getting wheat...")

            -- Move to wheat field
            QUEST:MoveTo(3167, 3296, 0, 2)
            -- Open gate
            API.DoAction_Object_valid1(0x31, API.OFF_ACT_GeneralObject_route0, {45210}, 10, true)
            QUEST:Sleep(5)
            -- Pick wheat
            Interact:Object("Wheat", "Pick", 30)
            QUEST:Sleep(2)
            while API.InvItemcount_1(1947) < 1 do
                API.RandomSleep2(300, 150)
            end
        else
            CURRENT_STEP = 8
            goto continue
        end
    end

    -- STEP 8: Talk to Millie Miller for extra fine flour
    if CURRENT_STEP == 8 then
        print("Step 8: Going to windmill...")

        -- Enter windmill
        if not QUEST:IsPlayerInArea(3165, 3304, 0, 2) then
            if API.DoAction_Object_valid1(0x31, API.OFF_ACT_GeneralObject_route0, {ID.WINDMILL_DOOR}, 10, true) then
                QUEST:Sleep(2)
                API.WaitUntilMovingEnds(5, 3)
            end
        end
        QUEST:Sleep(2)
        if API.InvItemcount_1(1931) == 0 then
            print("Getting pot!")
            API.DoAction_G_Items1(0x2d, {1931}, 10)
            QUEST:Sleep(4)
            API.DoAction_Loot_w({1931}, 10, API.PlayerCoordfloat(), 10)
            QUEST:Sleep(1)
        end
        -- Talk to Millie Miller
        if API.DoAction_NPC(0x2c, API.OFF_ACT_InteractNPC_route, {ID.MILLIE_MILLER}, 50) then
            QUEST:Sleep(4)
            -- Wait for dialog and let handleDialogs() take care of options
            if QUEST:DialogBoxOpen() then
                print("Dialog with Millie started")
                HandleDialog()
            end
            QUEST:Sleep(2)
        end
        CURRENT_STEP = 8.5
        goto continue
    end

    -- STEP 8.5: Make extra fine flour at windmill
    if CURRENT_STEP == 8.5 then
        if API.InvItemcount_String("Extra fine flour") == 0 then
            if API.InvItemcount_1(ID.WHEAT) > 0 then
                print("Step 8.5: Making extra fine flour at windmill...")

                -- Go upstairs
                API.DoAction_Object1(0x29, API.OFF_ACT_GeneralObject_route1, {36795}, 50)
                QUEST:Sleep(6)

                -- Use wheat on hopper
                API.DoAction_Inventory1(1947, 0, 0, API.OFF_ACT_Bladed_interface_route)
                API.RandomSleep2(600, 150)
                API.DoAction_Object1(0x24, API.OFF_ACT_GeneralObject_route00, {70034}, 50)
                QUEST:Sleep(4)

                -- Operate controls
                API.DoAction_Object1(0x31, API.OFF_ACT_GeneralObject_route0, {ID.WINDMILL_CONTROLS}, 50)
                QUEST:Sleep(4)

                -- Go downstairs
                API.DoAction_Object1(0x29, API.OFF_ACT_GeneralObject_route1, {36797}, 50)
                QUEST:Sleep(4)

                -- Wait for flour to be ready and collect it
                QUEST:WaitForObjectToAppear(ID.FLOUR_BIN, 0)
                API.DoAction_Object1(0x29, API.OFF_ACT_GeneralObject_route0, {ID.FLOUR_BIN}, 50);
                QUEST:Sleep(3)
            else
                print("ERROR: No wheat available!")
                CURRENT_STEP = 7 -- Go back to get wheat
                goto continue
            end
        else
            CURRENT_STEP = 9
            goto continue
        end
    end

    -- STEP 9: Return to cook with all ingredients
    if CURRENT_STEP == 9 then
        -- Check if we have all ingredients
        local hasMilk = API.InvItemcount_String("Top-quality milk") > 0
        local hasEgg = API.InvItemcount_String("Super large egg") > 0
        local hasFlour = API.InvItemcount_String("Extra fine flour") > 0

        if hasMilk and hasEgg and hasFlour then
            print("Step 9: All ingredients collected! Returning to cook...")

            -- Move to castle
            if not QUEST:IsPlayerInArea(3208, 3214, 0, 5) then
                LODESTONES.LUMBRIDGE.Teleport()
                QUEST:MoveTo(3208, 3214, 0, 3)
            end

            -- Talk to cook
            if API.DoAction_NPC(0x2c, API.OFF_ACT_InteractNPC_route, {ID.COOK}, 50) then
                -- Wait for dialog
                if QUEST:DialogBoxOpen() then
                    print("Finishing Quest")
                    HandleDialog()
                end
            end
            API.RandomSleep2(2000, 500)
            CURRENT_STEP = 10

        else
            print("ERROR: Missing ingredients!")
            print("Milk: " .. tostring(hasMilk))
            print("Egg: " .. tostring(hasEgg))
            print("Flour: " .. tostring(hasFlour))
            -- Go back to get missing ingredients
            if not hasMilk then
                CURRENT_STEP = 5
            elseif not hasEgg then
                CURRENT_STEP = 6
            elseif not hasFlour then
                CURRENT_STEP = 7
            end
        end
    end

    if CURRENT_STEP == 10 then
        -- Check if quest completed
        if questData:isComplete() then
            print("=== QUEST COMPLETED! ===")
            print("Time taken: " .. os.difftime(os.time(), questStart) .. " seconds")
            print("Quest Points earned: " .. questData.points_reward)
            API.Write_LoopyLoop(false)
        end
    end

    ::continue::
end

-- Main execution loop
print("\nStarting quest bot...")
print("Current Quest Progress: " .. questData:getProgress())

while (API.Read_LoopyLoop()) do
    
    UTILS:gameStateChecks()
    questFunction()
    QUEST:Sleep(0.2)
end

print("Script ended")
