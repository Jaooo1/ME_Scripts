ScriptName = "Creature of Fenkenstrain Quest"
Author = "Jao"
ScriptVersion = "1.0.0"
ReleaseDate = "29-06-2025"
DiscordHandle = "jao"

--[[
Changelog:
v1.0.0 - 29-06-2025-06-2025
    - Initial release
    - Basic quest structure
    - Simple dialog system
    - Basic error handling
    - Quest flow management
]]

local API = require("api")
local QUEST = require("quest")
local LODESTONES = require("lodestones")
local UTILS = require("utils")
local Slib = require("slib")
local AdventureInterface = {{1500, 0, -1, 0}, {1500, 1, -1, 0}, {1500, 22, -1, 0}}
API.Write_fake_mouse_do(false)
API.SetMaxIdleTime(10)
-- Item IDs for requirements check
local REQUIRED_ITEMS = {
    BRONZE_WIRE = {
        id = 1794,
        quantity = 3
    },
    THREAD = {
        id = 1734,
        quantity = 5
    },
    SILVER_BAR = {
        id = 2355,
        quantity = 1
    },
    NEEDLE = {
        id = 1733,
        quantity = 1
    }
}

-- Requirements checking function
local function CheckRequiredItems()
    local missingItems = {}

    for itemName, itemData in pairs(REQUIRED_ITEMS) do
        local currentCount

        -- Use different API method for thread (stackable item)
        if itemName == "THREAD" then
            currentCount = API.InvStackSize(itemData.id) or 0
        else
            currentCount = API.InvItemcount_1(itemData.id)
        end

        if currentCount < itemData.quantity then
            table.insert(missingItems, itemName .. ": have " .. currentCount .. ", need " .. itemData.quantity)
        end
    end

    if #missingItems > 0 then
        print("Missing required items:")
        for i, item in ipairs(missingItems) do
            print("- " .. item)
        end
        return false
    else
        return true
    end
end

local function CheckQuestRequirements()
    local currentCrafting = API.XPLevelTable(API.GetSkillXP("CRAFTING"))
    local currentThieving = API.XPLevelTable(API.GetSkillXP("THIEVING"))

    -- Get quest data using Quest:Get API
    local restlessGhostQuest = Quest:Get("The Restless Ghost")
    local isRestlessGhostComplete = restlessGhostQuest and restlessGhostQuest:isComplete() or false

    local missingRequirements = {}

    -- Check Crafting level
    if currentCrafting < 20 then
        table.insert(missingRequirements, "Crafting level 20 (current: " .. currentCrafting .. ")")
    end

    -- Check Thieving level
    if currentThieving < 25 then
        table.insert(missingRequirements, "Thieving level 25 (current: " .. currentThieving .. ")")
    end

    -- Check The Restless Ghost quest completion
    if not isRestlessGhostComplete then
        table.insert(missingRequirements, "The Restless Ghost quest completion (current status: " ..
            (isRestlessGhostComplete and "Complete" or "Not complete"))
    end

    if #missingRequirements > 0 then
        print("Missing quest requirements:")
        for i, requirement in ipairs(missingRequirements) do
            print("- " .. requirement)
        end
        return false
    else
        return true
    end
end

-- Combined requirements and items checking function
local function CheckAllRequirements()
    local hasRequiredItems = CheckRequiredItems()
    local hasQuestRequirements = CheckQuestRequirements()

    return hasRequiredItems and hasQuestRequirements
end

local function IsAcceptQuestInterfaceOpen()
    return #API.ScanForInterfaceTest2Get(true, AdventureInterface) > 0
end

--------------------START GUI STUFF--------------------
local CurrentStatus = "Starting"
local QuestProgress = 0
local IdleTicks = 0
local UIComponents = {}

local function GetComponentAmount()
    local amount = 0
    for i, v in pairs(UIComponents) do
        amount = amount + 1
    end
    return amount
end

local function GetComponentByName(componentName)
    for i, v in pairs(UIComponents) do
        if v[1] == componentName then
            return v;
        end
    end
end

local function AddBackground(name, widthMultiplier, heightMultiplier, colour)
    widthMultiplier = widthMultiplier or 1
    heightMultiplier = heightMultiplier or 1
    colour = colour or ImColor.new(0, 0, 0, 255) -- Preto
    Background = API.CreateIG_answer();
    Background.box_name = "Background" .. GetComponentAmount();
    Background.box_start = FFPOINT.new(30, 0, 0)
    Background.box_size = FFPOINT.new(400 * widthMultiplier, 20 * heightMultiplier, 0)
    Background.colour = colour
    UIComponents[GetComponentAmount() + 1] = {name, Background, "Background"}
end

local function AddLabel(name, text, colour)
    colour = colour or ImColor.new(255, 0, 0) -- Letras vermelhas por padrão
    Label = API.CreateIG_answer()
    Label.box_name = "Label" .. GetComponentAmount()
    Label.colour = colour;
    Label.string_value = text
    UIComponents[GetComponentAmount() + 1] = {name, Label, "Label"}
end

local function GUIDraw()
    for i = 1, GetComponentAmount() do
        local componentKind = UIComponents[i][3]
        local component = UIComponents[i][2]
        if componentKind == "Background" then
            component.box_size = FFPOINT.new(component.box_size.x, 25 * GetComponentAmount(), 0)
            API.DrawSquareFilled(component)
        elseif componentKind == "Label" then
            component.box_start = FFPOINT.new(40, 10 + ((i - 2) * 25), 0)
            API.DrawTextAt(component)
        end
    end
end

local function CreateGUI()
    AddBackground("Background", 0.85, 1, ImColor.new(0, 0, 0, 255)) -- Preto
    AddLabel("Author/Version", ScriptName .. " v" .. ScriptVersion .. " by " .. Author, ImColor.new(255, 0, 0)) -- Texto vermelho
    AddLabel("Status", "Status: " .. CurrentStatus, ImColor.new(255, 0, 0)) -- Texto vermelho

    -- Requirements Status
    local craftingLevel = API.XPLevelTable(API.GetSkillXP("CRAFTING"))
    local thievingLevel = API.XPLevelTable(API.GetSkillXP("THIEVING"))

    -- Get quest data using Quest:Get API
    local restlessGhostQuest = Quest:Get("The Restless Ghost")
    local isRestlessGhostComplete = restlessGhostQuest and restlessGhostQuest:isComplete() or false

    -- Crafting level check
    local craftingColor = craftingLevel >= 20 and ImColor.new(0, 255, 0) or ImColor.new(255, 0, 0)
    AddLabel("CraftingLevel", "Crafting: " .. craftingLevel .. "/20", craftingColor)

    -- Thieving level check
    local thievingColor = thievingLevel >= 25 and ImColor.new(0, 255, 0) or ImColor.new(255, 0, 0)
    AddLabel("ThievingLevel", "Thieving: " .. thievingLevel .. "/25", thievingColor)

    -- Restless Ghost quest check
    local questColor = isRestlessGhostComplete and ImColor.new(0, 255, 0) or ImColor.new(255, 0, 0)
    local questText = isRestlessGhostComplete and "Restless Ghost: Complete" or "Restless Ghost: Not Complete"
    AddLabel("RestlessGhost", questText, questColor)

end

local function UpdateStatus(newStatus)
    CurrentStatus = newStatus
    local statusLabel = GetComponentByName("Status")
    if statusLabel then
        statusLabel[2].string_value = "Quest progress: " .. CurrentStatus
    end

    -- Update requirements in real time
    local craftingLevel = API.XPLevelTable(API.GetSkillXP("CRAFTING"))
    local thievingLevel = API.XPLevelTable(API.GetSkillXP("THIEVING"))

    -- Get quest data using Quest:Get API
    local restlessGhostQuest = Quest:Get("The Restless Ghost")
    local isRestlessGhostComplete = restlessGhostQuest and restlessGhostQuest:isComplete() or false

    -- Update Crafting level
    local craftingComponent = GetComponentByName("CraftingLevel")
    if craftingComponent then
        craftingComponent[2].string_value = "Crafting: " .. craftingLevel .. "/20"
        craftingComponent[2].colour = craftingLevel >= 20 and ImColor.new(0, 255, 0) or ImColor.new(255, 0, 0)
    end

    -- Update Thieving level
    local thievingComponent = GetComponentByName("ThievingLevel")
    if thievingComponent then
        thievingComponent[2].string_value = "Thieving: " .. thievingLevel .. "/25"
        thievingComponent[2].colour = thievingLevel >= 25 and ImColor.new(0, 255, 0) or ImColor.new(255, 0, 0)
    end

    -- Update Restless Ghost quest status
    local questComponent = GetComponentByName("RestlessGhost")
    if questComponent then
        local questText = isRestlessGhostComplete and "Restless Ghost: Complete" or "Restless Ghost: Not Complete"
        questComponent[2].string_value = questText
        questComponent[2].colour = isRestlessGhostComplete and ImColor.new(0, 255, 0) or ImColor.new(255, 0, 0)
    end

end

CreateGUI()
GUIDraw()
--------------------END GUI STUFF--------------------

--------------------START END TABLE STUFF--------------------
local EndTable = {{"-"}}
EndTable[1] = {"Thanks for using my script!"}
EndTable[2] = {" "}
EndTable[3] = {"Script Name: " .. ScriptName}
EndTable[4] = {"Author: " .. Author}
EndTable[5] = {"Version: " .. ScriptVersion}
EndTable[6] = {"Release Date: " .. ReleaseDate}
EndTable[7] = {"Discord: " .. DiscordHandle}
--------------------END END TABLE STUFF--------------------
local ID = {
    -- Items
    MARBLE_AMULET = 4187,
    OBSIDIAN_AMULET = 4188,
    STAR_AMULET = 4183,
    PICKLED_BRAIN = 4199,
    DECAPITATED_HEAD = 4197,
    DECAPITATED_HEAD_WITH_BRAIN = 4198,
    ARMS = 4195,
    LEGS = 4196,
    TORSO = 4194,
    NEEDLE = 1733,
    THREAD = 1734,
    BRONZE_WIRE = 1794,
    SILVER_BAR = 2355,
    SHED_KEY = 4186,
    CAVERNKEY = 4184,
    GARDEN_BRUSH = 4190,
    GARDEN_CANE = 4189,
    EXTENDED_BRUSH = 4193,
    CONDUCTOR_MOULD = 4200,
    CONDUCTOR = 4201,
}

-- Enhanced Slib MoveTo function
local function MoveTo(x, y, z)
    return Slib:MoveTo(x, y, z)
end

-- Chat Options for dialog handling
local ChatOptions = {"I'm looking for a quest.", "Do you know where the key to the shed is?", "Yes.", "Yes, I'll help you.", "Continue.", "What help do you need?",
                     "The Joy of Gravedigging", "Handy Maggot Avoidance Techniques",
                     "Do you know anything about the castle?",
                      "Take pickled brain", "Yes, take it.", "Yes, lead the way.", "Dig",
                     "Search", "I have the ingredients.", "What's wrong?", "Braindead.", "Grave-digging.",
                     "I have some body parts for you.", "I'm ready for my reward.", "I'll buy one.", "What happened to your head?"}

-- Quest specific IDs and configuration

-- Door Functions for better organization and reusability
local function OpenEntranceDoor()
    if API.DoAction_Object_valid2(0x31, API.OFF_ACT_GeneralObject_route0, {5183}, 30, WPOINT.new(3548, 3535, 10), true) then -- Entrance Door
        QUEST:Sleep(5)
        return true
    end
    return false
end

local function OpenMiddleSouthDoor()
    if API.DoAction_Object_valid2(0x31, API.OFF_ACT_GeneralObject_route0, {5183}, 30, WPOINT.new(3548, 3543, 10), true) then -- Middle south door
        QUEST:Sleep(5)
        return true
    end
    return false
end

local function OpenMiddleNorthDoor()
    if API.DoAction_Object_valid2(0x31, API.OFF_ACT_GeneralObject_route0, {5183}, 30, WPOINT.new(3548, 3551, 10), true) then -- Middle North Door
        QUEST:Sleep(5)
        return true
    end
    return false
end

local function OpenEastern1stDoor()
    if API.DoAction_Object_valid2(0x31, API.OFF_ACT_GeneralObject_route0, {1530}, 30, WPOINT.new(3552, 3555, 10), true) then -- eastern1stDoor
        QUEST:Sleep(5)
        return true
    end
    return false
end

local function OpenEastern2ndDoor()
    if API.DoAction_Object_valid2(0x31, API.OFF_ACT_GeneralObject_route0, {1530}, 30, WPOINT.new(3557, 3555, 10), true) then -- eastern2ndDoor
        QUEST:Sleep(5)
        return true
    end
    return false
end

local function OpenWestern2ndDoor()
    if API.DoAction_Object_valid2(0x31, API.OFF_ACT_GeneralObject_route0, {1530}, 30, WPOINT.new(3540, 3555, 10), true) then -- western2ndDoor
        QUEST:Sleep(5)
        return true
    end
    return false
end

local function OpenWestern1stDoor()
    if API.DoAction_Object_valid2(0x31, API.OFF_ACT_GeneralObject_route0, {1530}, 30, WPOINT.new(3545, 3555, 10), true) then -- western1stDoor
        QUEST:Sleep(5)
        return true
    end
    return false
end

local function OpenNorthDoor()
    if API.DoAction_Object_valid2(0x31, API.OFF_ACT_GeneralObject_route0, {5183}, 30, WPOINT.new(3549, 3558, 10), true) then -- northDoor
        QUEST:Sleep(4)
        return true
    end
    return false
end

local function findNpc(npcid, distance)
    local distance = distance or 20
    local npcs = API.GetAllObjArrayInteract({npcid}, distance, {1})
    if #npcs > 0 then
        return npcs[1]
    else
        return false
    end
end

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

-- Handles dialog interactions
local function IsItemOnGround(itemID)
    return #API.GetAllObjArray1({itemID}, 15, {3}) > 0
end

-- Enhanced Interact system configuration
-- Set default interaction sleep times
Interact:SetSleep(1000, 500, 200)

-- Utility functions
-- Check if item is on ground
local function HasItem(itemID, quantity)
    quantity = quantity or 1
    return API.InvItemcount_1(itemID) >= quantity
end

-- Quest items list for ground collection
local questItems = {ID.ARMS, ID.LEGS, ID.TORSO, ID.DECAPITATED_HEAD, ID.PICKLED_BRAIN, ID.SHED_KEY, ID.CAVERNKEY}

-- Main execution with enhanced error handling


while API.Read_LoopyLoop() do
    -- Check all requirements at the start of each loop iteration
    QuestProgress = Quest:Get("Creature of Fenkenstrain"):getProgress()
    print("Quest Progress: " .. tonumber(QuestProgress))
    UpdateStatus(tonumber(QuestProgress) .. "/8")
    GUIDraw()


    -- Idle ticks check
    if IdleTicks > 0 then
        print("Idle ticks greater than 0: " .. tonumber(IdleTicks) .. ". Skipping cycle.")
        goto continue
    end

    -- Handle dialogs
    if QUEST:DialogBoxOpen() then
        print("Handling dialogs.")
        HandleDialog()
        IdleTicks = 2
        goto continue
    end

    -- Player in combat check
    if API.LocalPlayer_IsInCombat_() then
        print("Player in combat. Skipping cycle.")
        IdleTicks = 3
        goto continue
    end

    -- Player animating check
    if API.IsPlayerAnimating_(API.GetLocalPlayerName(), 15) then
        print("Player animating. Skipping cycle.")
        goto continue
    end

    -- Player moving check
    if API.IsPlayerMoving_(API.GetLocalPlayerName()) then
        print("Player moving. Skipping cycle.")
        goto continue
    end

    -- Cutscene check
    if QUEST:IsInCutscene() then
        print("Player in cutscene. Skipping cycle.")
        goto continue
    end

    if IsAcceptQuestInterfaceOpen() then
        print("Accepting quest interface detected. Clicking accept.")
        API.DoAction_Interface(0x24, 0xffffffff, 1, 1500, 409, -1, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(2000, 500)
        goto continue
    end

    -- Collect quest items from ground
    for _, itemID in ipairs(questItems) do
        if IsItemOnGround(itemID) then
            print("Collecting item from ground: " .. itemID)
            API.DoAction_G_Items1(0x2d, {itemID}, 50)
            IdleTicks = 2
            break
        end
    end

    if QuestProgress == 0 then -- Quest not started
        if not CheckAllRequirements() then
            print("ERROR: Not all requirements are met. Stopping script.")
            print("Required items: 3 bronze wire, 5 thread, 1 silver bar, 1 needle")
            print("Required levels: 20 Crafting, 25 Thieving")
            print("Required quest: The Restless Ghost (completed)")
            API.Write_LoopyLoop(false)
        end
        print("Starting quest - talking to Dr. Fenkenstrain")
        if not QUEST:IsPlayerInArea(3548, 3529, 0, 15) then
            LODESTONES.CANIFIS.Teleport()
            QUEST:MoveTo(3548, 3529,0,2)
        end

        -- Open first castle door at specific tile
        OpenEntranceDoor()
        -- Open second castle door at specific tile
        OpenMiddleSouthDoor()

        -- Talk to Dr. Fenkenstrain
        if Interact:NPC("Dr Fenkenstrain", "Talk-to", 50) then
            QUEST:WaitForDialogBox(10)
            HandleDialog()
            IdleTicks = 3
        end
        goto continue

    elseif QuestProgress == 1 then -- Quest started - read books
        print("Reading bookcases for research")
        if not HasItem(ID.STAR_AMULET) then
            OpenMiddleNorthDoor()
            OpenEastern1stDoor()
            OpenEastern2ndDoor()

            QUEST:MoveTo(3559, 3550, 0, 1)
            QUEST:Sleep(1)
            -- Go upstairs if not already there
            Interact:Object("Staircase", "Climb-up", 50)
            QUEST:Sleep(3)

            if QUEST:IsPlayerInArea(3559, 3554, 1, 3) then

                Interact:Object("Door", "Open", 4)
                QUEST:Sleep(2)
                -- Read both bookcases for research
                if Interact:Object("Bookcase", "Search", 50) then
                QUEST:WaitForDialogBox(5)
                HandleDialog()
                end
                QUEST:MoveTo(3539, 3554, 1, 2)
                Interact:Object("Door", "Open", 4)
                QUEST:Sleep(2)
                -- Read second bookcase  
                if Interact:Object("Bookcase", "Search", 50) then
                    QUEST:WaitForDialogBox(5)
                    HandleDialog()
                end
            
            else
                QUEST:Sleep(1)
            end
        end
        QUEST:Sleep(1)
        if HasItem(ID.MARBLE_AMULET) and HasItem(ID.OBSIDIAN_AMULET) and not HasItem(ID.STAR_AMULET) then
            API.DoAction_Inventory1(ID.MARBLE_AMULET, 0, 0, API.OFF_ACT_Bladed_interface_route)
            QUEST:Sleep(1)
            API.DoAction_Inventory1(ID.OBSIDIAN_AMULET, 0, 0, API.OFF_ACT_GeneralInterface_route1)
            QUEST:Sleep(2)
            IdleTicks = 3
            Interact:Object("Staircase", "Climb-down", 50)
            QUEST:Sleep(5)
            OpenWestern2ndDoor()
            OpenWestern1stDoor()
            OpenNorthDoor()
        end
        

        if not HasItem(ID.DECAPITATED_HEAD) then
            -- Talk to gardener ghost
            if Interact:NPC("Gardener Ghost", "Talk-to", 50) then
                QUEST:WaitForDialogBox(10)
                HandleDialog()
                IdleTicks = 2
            end

            OpenNorthDoor()
            OpenMiddleNorthDoor()
            OpenMiddleSouthDoor()
            OpenEntranceDoor()
            -- Lead to haunted woods and dig
            if MoveTo(3611, 3491, 0) then
                -- Try digging at grave locations
                if Interact:Object("Grave", "Dig", 5) then
                    QUEST:Sleep(8)
                end
            end
        end

        print("Getting pickled brain from Canifis tavern")

        if not HasItem(ID.PICKLED_BRAIN) and not HasItem(ID.DECAPITATED_HEAD_WITH_BRAIN) then
            LODESTONES.CANIFIS.Teleport()
            if MoveTo(3494, 3477, 0) then
                if API.DoAction_G_Items1(0x2d, {4199}, 50) then
                    QUEST:Sleep(2)
                    QUEST:WaitForDialogBox(5)
                    HandleDialog()
                end
            end
        end

        -- Combine head with brain
        if HasItem(ID.PICKLED_BRAIN) and HasItem(ID.DECAPITATED_HEAD) and not HasItem(ID.DECAPITATED_HEAD_WITH_BRAIN) then
            API.DoAction_Inventory1(ID.DECAPITATED_HEAD, 0, 0, API.OFF_ACT_Bladed_interface_route)
            QUEST:Sleep(1)
            API.DoAction_Inventory1(ID.PICKLED_BRAIN, 0, 0, API.OFF_ACT_GeneralInterface_route1)
            QUEST:Sleep(2)
        end
        IdleTicks = 2

        -- Get body parts
        print("Collecting arms, legs and torso from dungeon and graves")
        if not (HasItem(ID.ARMS) and HasItem(ID.LEGS) and HasItem(ID.TORSO)) then
            if HasItem(ID.STAR_AMULET) and MoveTo(3575, 3529, 0) then
                API.DoAction_Inventory1(4183, 0, 0, API.OFF_ACT_Bladed_interface_route)
                API.RandomSleep2(400, 150, 300)
                API.DoAction_Object2(0x24, API.OFF_ACT_GeneralObject_route00, {5167}, 50, WPOINT.new(3578, 3527, 0));
                QUEST:WaitForDialogBox(5)
                HandleDialog()
                if Interact:Object("Memorial", "Push", 50) then
                    QUEST:Sleep(6)
                end
            end
        end
        -- If in dungeon, fight experiments for body parts
        if findNpc(1676, 50) and not (HasItem(ID.ARMS) and HasItem(ID.LEGS) and HasItem(ID.TORSO)) then
            print("Player is in the area, but missing body parts.")
            MoveTo(3557, 9946, 0)
            API.RandomSleep2(600, 300)
            API.DoAction_NPC(0x2a, API.OFF_ACT_AttackNPC_route, {1676}, 50)
            API.RandomSleep2(600, 300)
            API.WaitUntilMovingEnds()
            while API.LocalPlayer_IsInCombat_() do
                QUEST:Sleep(2)
            end
            QUEST:Sleep(2)
            -- Loot key 
            if API.DoAction_G_Items1(0x2d, {4184}, 50) then
                API.RandomSleep2(2000, 300)
                API.WaitUntilMovingEnds()
                API.DoAction_Loot_w({4184}, 10, API.PlayerCoordfloat(), 10)
                QUEST:Sleep(2)
            else
                QUEST:Sleep(2)
            end
        end

        if HasItem(ID.CAVERNKEY) then
            if QUEST:MoveTo(3514, 9957, 0, 1) then
                if Interact:Object("Entrance", "Open", 50) then
                    while not QUEST:IsPlayerInArea(3510, 9957, 0, 1) do
                        QUEST:Sleep(1)
                    end
                    if Interact:Object("Chest", "Search", 50) then
                        QUEST:Sleep(10)
                    end
                    if Interact:Object("Ladder", "Climb-up", 50) then
                        QUEST:Sleep(4)
                    end
                end
            end
        end

        if QUEST:IsPlayerInArea(3504, 3569, 0, 10) then
            API.DoAction_Object2(0x29, API.OFF_ACT_GeneralObject_route1, {5168}, 50, WPOINT.new(3502, 3576, 0));
            QUEST:Sleep(8)
            if HasItem(ID.TORSO) then
                API.DoAction_Object2(0x29, API.OFF_ACT_GeneralObject_route1, {5168}, 50, WPOINT.new(3504, 3577, 0))
                QUEST:Sleep(6)
                if HasItem(ID.ARMS) then
                    API.DoAction_Object2(0x29, API.OFF_ACT_GeneralObject_route1, {5168}, 50, WPOINT.new(3506, 3576, 0))
                    QUEST:Sleep(6)
                end
            end
        end
        if (HasItem(ID.ARMS) and HasItem(ID.LEGS) and HasItem(ID.TORSO)) then
            print("Collected all body parts.")
            LODESTONES.CANIFIS.Teleport()
            MoveTo(3548, 3529, 0)
            OpenEntranceDoor()
            OpenMiddleSouthDoor()
            OpenMiddleNorthDoor()
            Interact:NPC("Dr Fenkenstrain", "Talk-to", 50)
            QUEST:WaitForDialogBox(10)
            IdleTicks = 3
            HandleDialog()
            Interact:NPC("Dr Fenkenstrain", "Talk-to", 50)
            QUEST:WaitForDialogBox(10)
            IdleTicks = 3
            HandleDialog()
        end
        goto continue 

    elseif QuestProgress == 3 then -- Create lightning conductor
        print("Creating lightning conductor components")
        if not HasItem(ID.CONDUCTOR) then
            OpenMiddleNorthDoor()
            OpenNorthDoor()
            Interact:NPC("Gardener Ghost", "Talk-to", 50)
            QUEST:WaitForDialogBox(10)
            HandleDialog()
            IdleTicks = 2
        -- get garden brush
            if not HasItem(ID.GARDEN_BRUSH) then
                if HasItem(ID.SHED_KEY) then
                    API.DoAction_Object2(0x31, API.OFF_ACT_GeneralObject_route0, {5174}, 50, WPOINT.new(3548, 3565, 0));
                    QUEST:Sleep(1)
                    while not QUEST:IsPlayerInArea(3547, 3565, 0, 1) do
                        QUEST:Sleep(1)
                    end
                else
                    print("Shed key not found. Cannot access shed.")
                end
            end
            if Interact:Object("Cupboard", "Open", 50) then
                QUEST:Sleep(3)
                if Interact:Object("Open Cupboard", "Search", 50) then
                    QUEST:Sleep(2)
                end
            end

            API.DoAction_Object2(0x31, API.OFF_ACT_GeneralObject_route0, {5174}, 50, WPOINT.new(3548, 3565, 0));
            QUEST:Sleep(3)
            -- Get garden canes
            for i = 1, 3 do
                if Interact:Object("Pile of canes", "Take-from", 50) then
                    QUEST:Sleep(1)
                end
            end

            if HasItem(ID.GARDEN_BRUSH) and HasItem(ID.GARDEN_CANE, 3) and not HasItem(ID.EXTENDED_BRUSH) then
                print("Making extended brush.")
                API.DoAction_Inventory1(ID.GARDEN_CANE, 0, 0, API.OFF_ACT_Bladed_interface_route)
                QUEST:Sleep(1)
                API.DoAction_Inventory1(ID.GARDEN_BRUSH, 0, 0, API.OFF_ACT_GeneralInterface_route1)
                QUEST:Sleep(1)
                API.DoAction_Inventory1(ID.GARDEN_CANE, 0, 0, API.OFF_ACT_Bladed_interface_route)
                QUEST:Sleep(1)
                API.DoAction_Inventory1(4191, 0, 0, API.OFF_ACT_GeneralInterface_route1)
                QUEST:Sleep(1)
                API.DoAction_Inventory1(ID.GARDEN_CANE, 0, 0, API.OFF_ACT_Bladed_interface_route)
                QUEST:Sleep(1)
                API.DoAction_Inventory1(4192, 0, 0, API.OFF_ACT_GeneralInterface_route1)
                QUEST:Sleep(1)
            end

            -- Go upstairs and get conductor mould from fireplace
            OpenNorthDoor()
            OpenWestern1stDoor()
            OpenWestern2ndDoor()
            -- Go upstairs if not already there
            Interact:Object("Staircase", "Climb-up", 50)
            QUEST:Sleep(3)

            while not QUEST:IsPlayerInArea(3538, 3554, 1, 3) do
                QUEST:Sleep(1)
            end
            Interact:Object("Door", "Open", 4)
            QUEST:Sleep(3)
            -- Get conductor mould from fireplace
            if HasItem(ID.EXTENDED_BRUSH) and not HasItem(ID.CONDUCTOR_MOULD) then
                API.DoAction_Inventory1(ID.EXTENDED_BRUSH, 0, 0, API.OFF_ACT_Bladed_interface_route)
                QUEST:Sleep(1)
                API.DoAction_Object1(0x24, API.OFF_ACT_GeneralObject_route00, {5165}, 50)
                QUEST:Sleep(6)
            end
       
            -- Make conductor at furnace
            if HasItem(ID.CONDUCTOR_MOULD) and HasItem(ID.SILVER_BAR) and not HasItem(ID.CONDUCTOR) then
                LODESTONES.AL_KHARID.Teleport()

                if Interact:Object("Furnace", "Smelt", 50) then
                    QUEST:Sleep(6)
                    if API.Compare2874Status(85, false) then
                        API.DoAction_Interface(0xffffffff, 0x933, 1, 37, 62, 1, API.OFF_ACT_GeneralInterface_route)
                        QUEST:Sleep(1)
                        API.DoAction_Interface(0xffffffff, 0x1069, 1, 37, 103, 9, API.OFF_ACT_GeneralInterface_route)
                        QUEST:Sleep(1)
                        API.DoAction_Interface(0x24, 0xffffffff, 1, 37, 163, -1, API.OFF_ACT_GeneralInterface_route)
                        QUEST:Sleep(3)
                        API.DoAction_Tile(WPOINT.new(3289,3190,0))
                    end
                end
            end
        end

        -- Install conductor on roof
        if HasItem(ID.CONDUCTOR) then
            LODESTONES.CANIFIS.Teleport()
            QUEST:MoveTo(3549, 3534, 0, 1)
            OpenEntranceDoor()
            OpenMiddleSouthDoor()
            OpenMiddleNorthDoor()
            OpenWestern1stDoor()
            OpenWestern2ndDoor()
            Interact:Object("Staircase", "Climb-up", 50)
            QUEST:Sleep(3)
            while not QUEST:IsPlayerInArea(3537, 3554, 1, 10) do
                QUEST:Sleep(1)
            end
            QUEST:MoveTo(3549, 3543, 1, 1)
            Interact:Object("Door", "Open", 4)
            QUEST:Sleep(3)
            Interact:Object("Ladder", "Climb-up", 50)
            QUEST:Sleep(3)
            Interact:Object("Lightning conductor", "Repair", 50)
            QUEST:Sleep(5)
        end
        
        goto continue

    elseif QuestProgress == 4 then -- Talk to Dr. Fenkenstrain
        Interact:Object("Ladder", "Climb-down", 50)
        QUEST:Sleep(3)
        Interact:Object("Door", "Open", 10)
        QUEST:Sleep(3)
        QUEST:MoveTo(3538, 3554, 1, 1)
        Interact:Object("Staircase", "Climb-down", 50)
        QUEST:Sleep(3)
        OpenWestern2ndDoor()
        OpenWestern1stDoor()
        OpenMiddleNorthDoor()
        Interact:NPC("Dr Fenkenstrain", "Talk-to", 50)
        QUEST:WaitForDialogBox(10)
        HandleDialog()
        QUEST:Sleep(2)
        IdleTicks = 2
        goto continue

    elseif QuestProgress == 5 then
        print("Finalizing quest completion")

        -- Talk to monster on roof
        QUEST:MoveTo(3539, 3550, 0, 1)
        Interact:Object("Staircase", "Climb-up", 50)
        QUEST:Sleep(3)
        QUEST:MoveTo(3548, 3551, 1, 1)
        Interact:Object("Door", "Open", 4)
        QUEST:Sleep(3)
        Interact:Object("Ladder", "Climb-up", 50)
        QUEST:Sleep(3)
        Interact:NPC("Fenkenstrain's Monster", "Talk-to", 50)
        QUEST:WaitForDialogBox(10)
        HandleDialog()
        IdleTicks = 2
        goto continue

    elseif QuestProgress == 6 then -- Get ring of charos
        print("Getting ring of charos from Dr. Fenkenstrain")
        Interact:Object("Ladder", "Climb-down", 50)
        QUEST:Sleep(2)
        Interact:Object("Door", "Open", 8)
        QUEST:Sleep(3)
        QUEST:MoveTo(3538, 3554, 1, 1)
        Interact:Object("Staircase", "Climb-down", 50)
        QUEST:Sleep(3)
        OpenWestern2ndDoor()
        OpenWestern1stDoor()
        OpenMiddleNorthDoor()
        Interact:NPC("Dr Fenkenstrain", "Pickpocket", 50)
        QUEST:Sleep(10)
        goto continue

    elseif QuestProgress == 8 then -- Quest complete
        print("\n=== QUEST COMPLETED! ===")
        print("Rewards: 2 Quest Points, 1000 Thieving XP, 1000 Crafting XP, Ring of charos")
        API.Write_LoopyLoop(false)
        break

    else
        print("Unknown Quest Progress: " .. tonumber(QuestProgress))
        IdleTicks = 5
    end

    ::continue::
    QUEST:Sleep(0.6)
    IdleTicks = math.max(IdleTicks - 1, 0)
    collectgarbage("collect")
end

API.DrawTable(EndTable)
print("----------//----------")
print("Script Name: " .. ScriptName)
print("Author: " .. Author)
print("Version: " .. ScriptVersion)
print("Release Date: " .. ReleaseDate)
print("Discord: " .. DiscordHandle)
print("----------//----------")

