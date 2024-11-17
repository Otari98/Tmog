-------------------------------
----------- TOOLTIP -----------
-------------------------------

-- adapted from https://github.com/Zebouski/MoPGearTooltips/tree/masterturtle
local GAME_YELLOW = "|cffffd200"

local t_debug = false

TRANSMOG_CACHE = TRANSMOG_CACHE or {
    [1] = {}, --HeadSlot
    [3] = {}, --ShoulderSlot
    [5] = {}, --ChestSlot
    [6] = {}, --WaistSlot
    [7] = {}, --LegsSlot
    [8] = {}, --FeetSlot
    [9] = {}, --WristSlot
    [10] = {}, --HandsSlot
    [15] = {}, --BackSlot
    [16] = {}, --MainHandSlot
    [17] = {}, --SecondaryHandSlot
    [18] = {} --RangedSlot
}
-- strings from game tooltips to determine if this item can be used for transmog
local gearslots = {
    "Head",
    "Shoulder",
    "Back",
    "Chest",
    "Wrist",
    "Hands",
    "Waist",
    "Legs",
    "Feet",
    "Ranged",
    "Crossbow",
    "Gun",
    "Wand",
    "Two-Hand",
    "Main Hand",
    "One-Hand",
    "Off Hand",
    "Held In Off-hand",
  }
-- Skip items unequipable for player class (this is right text only)
local tmog_druid = {
    ["Cloth"]=true,
    ["Leather"]=true,
    ["Staff"]=true,
    ["Mace"]=true,
    ["Dagger"]=true,
    ["Polearm"]=true,
    ["Fist Weapon"]=true
}

local tmog_shaman = {
    ["Cloth"]=true,
    ["Leather"]=true,
    ["Mail"]=true,
    ["Staff"]=true,
    ["Mace"]=true,
    ["Dagger"]=true,
    ["Axe"]=true,
    ["Fist Weapon"]=true,
    ["Shield"]=true
}

local tmog_paladin = {
    ["Cloth"]=true,
    ["Leather"]=true,
    ["Mail"]=true,
    ["Plate"]=true,
    ["Staff"]=true,
    ["Mace"]=true,
    ["Sword"]=true,
    ["Axe"]=true,
    ["Polearm"]=true,
    ["Shield"]=true
}

local tmog_magelock = {
    ["Cloth"]=true,
    ["Staff"]=true,
    ["Sword"]=true,
    ["Dagger"]=true,
    ["Wand"]=true
}

local tmog_priest = {
    ["Cloth"]=true,
    ["Staff"]=true,
    ["Mace"]=true,
    ["Dagger"]=true,
    ["Wand"]=true
}

local tmog_warrior = {
    ["Cloth"]=true,
    ["Leather"]=true,
    ["Mail"]=true,
    ["Plate"]=true,
    ["Staff"]=true,
    ["Mace"]=true,
    ["Dagger"]=true,
    ["Polearm"]=true,
    ["Sword"]=true,
    ["Axe"]=true,
    ["Fist Weapon"]=true,
    ["Shield"]=true,
    ["Bow"]=true
}

local tmog_rogue = {
    ["Cloth"]=true,
    ["Leather"]=true,
    ["Mace"]=true,
    ["Dagger"]=true,
    ["Sword"]=true,
    ["Fist Weapon"]=true,
    ["Bow"]=true
}

local tmog_hunter = {
    ["Cloth"]=true,
    ["Leather"]=true,
    ["Mail"]=true,
    ["Staff"]=true,
    ["Dagger"]=true,
    ["Sword"]=true,
    ["Polearm"]=true,
    ["Fist Weapon"]=true,
    ["Axe"]=true,
    ["Bow"]=true
}

local suffixes = {
    [" of the Owl"]=true,
    [" of the Eagle"]=true,
    [" of the Whale"]=true,
    [" of the Bear"]=true,
    [" of the Monkey"]=true,
    [" of the Falcon"]=true,
    [" of the Wolf"]=true,
    [" of the Tiger"]=true,
    [" of the Gorilla"]=true,
    [" of the Boar"]=true,

    [" of Strength"]=true,
    [" of Agility"]=true,
    [" of Stamina"]=true,
    [" of Intellect"]=true,
    [" of Spirit"]=true,

    [" of Power"]=true,
    [" of Marksmanship"]=true,
    [" of Healing"]=true,

    [" of Fiery Wrath"]=true,
    [" of Frozen Wrath"]=true,
    [" of Nature's Wrath"]=true,
    [" of Shadow Wrath"]=true,
    [" of Arcane Wrath"]=true,

    [" of Arcane Resistance"]=true,
    [" of Fire Resistance"]=true,
    [" of Frost Resistance"]=true,
    [" of Shadow Resistance"]=true,
    [" of Nature Resistance"]=true,

    [" of Defense"]=true,
    [" of Blocking"]=true,
}

local function tmog_print(a)
    if not a then
        ChatFrame2:AddMessage('Attempt to print a nil value.')
        return
    end
    ChatFrame2:AddMessage(GAME_YELLOW .. a)
end

local function tmog_debug(a)
    if t_debug ~= true then return end
    if type(a) == 'boolean' then
        if a then
            tmog_print('|cff0070de[DEBUG]|cffffffff[true]')
        else
            tmog_print('|cff0070de[DEBUG]|cffffffff[false]')
        end
        return true
    end
    tmog_print('|cff0070de[DEBUG:' .. GetTime() .. ']|cffffffff[' .. a .. ']')
end

local function strsplit(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delimiter, from, 1, true)
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from, true)
    end
    table.insert(result, string.sub(str, from))
    return result
end

local function AddToSet(set, key)
    if not set or not key then return end
    set[key] = true
end

local function SetContains(set, key)
    if not set or not key then return end
    return set[key] ~= nil
end

local function InvenotySlotFromItemID(itemID)
    if not itemID then
        return
    end
    local name, itemstring, quality, level, class, subclass, max_stack, slot  = GetItemInfo(itemID)
    local id = nil
    if slot == "INVTYPE_HEAD"
        then id = 1
    elseif slot == "INVTYPE_SHOULDER"
        then id = 3
    elseif slot == "INVTYPE_CHEST" or
            slot == "INVTYPE_ROBE"
        then id = 5
    elseif slot == "INVTYPE_WAIST"
        then id = 6
    elseif slot == "INVTYPE_LEGS"
        then id = 7
    elseif slot == "INVTYPE_FEET"
        then id = 8
    elseif slot == "INVTYPE_WRIST"
        then id = 9
    elseif slot == "INVTYPE_HAND"
        then id = 10
    elseif slot == "INVTYPE_CLOAK"
        then id = 15
    elseif slot == "INVTYPE_WEAPONMAINHAND" or
            slot == 'INVTYPE_2HWEAPON' or
            slot == 'INVTYPE_WEAPON'
        then id = 16
    elseif slot == 'INVTYPE_WEAPONOFFHAND' or
            slot == 'INVTYPE_HOLDABLE' or
            slot == 'INVTYPE_SHIELD'
        then id = 17
    elseif slot == "INVTYPE_RANGED" or
            slot == "INVTYPE_RANGEDRIGHT"
        then id = 18
    end
    return id
end

local HookSetItemRef = SetItemRef
SetItemRef = function(link, text, button)
    local item = string.find(link, "item:.*")
    HookSetItemRef(link, text, button)
    if not IsShiftKeyDown() and not IsControlKeyDown() and item then
        TmogTip.extendTooltip(ItemRefTooltip, "ItemRefTooltip")
    end
end

local function FixName(name)
    if not name then return end
    local suffix = ""
    for k,v in pairs(suffixes) do
        if string.find(name, k, 1, true) then
            suffix = k
            break
        end
    end
    return string.gsub(name, suffix, "")
end

local Tmog = CreateFrame("Frame")
local TmogTip = CreateFrame("Frame", "TmogTip", GameTooltip)
local TmogTooltip = getglobal("TmogTooltip") or CreateFrame("GameTooltip", "TmogTooltip", nil, "GameTooltipTemplate")
local TmogScanTooltip = getglobal("TmogScanTooltip") or CreateFrame("GameTooltip", "TmogScanTooltip", nil, "GameTooltipTemplate")
TmogTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
TmogScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

Tmog:RegisterEvent("UNIT_INVENTORY_CHANGED")
Tmog:RegisterEvent("CHAT_MSG_ADDON")
Tmog:RegisterEvent("PLAYER_ENTERING_WORLD")

Tmog:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        TmogFramePlayerModel:SetUnit("player")
        Tmog_Reset()

        if TmogFrame:IsVisible() then
            TmogFrame:Hide()
        end

        TmogFramePortrait:SetTexture("Interface\\Addons\\Tmog\\Tmog_Portrait")
        return
    end
    if event == "CHAT_MSG_ADDON" and string.find(arg1, "TW_TRANSMOG", 1, true) and arg4 == UnitName("player") then
        tmog_debug(event)
        tmog_debug(arg1)
        tmog_debug(arg2)
        tmog_debug(arg3)
        tmog_debug(arg4)
        if string.find(arg2, "AvailableTransmogs", 1, true) then
            local ex = strsplit(arg2, ":")
            tmog_debug("ex4: [" .. ex[4] .."]")
            local InventorySlotId = tonumber(ex[2])
            for i, itemID in ex do
                if i > 3 then
                    itemID = tonumber(itemID)
                    if itemID then
                        local itemName = GetItemInfo(itemID)
                        if itemName then
                            if not SetContains(TRANSMOG_CACHE[InventorySlotId], itemName) then
                                AddToSet(TRANSMOG_CACHE[InventorySlotId], itemName)
                            end
                            -- check if it shares Display ID with other items and add those if it does
                            if SetContains(DisplayIdDB, itemName) then
                                for k,v in pairs(DisplayIdDB[itemName]) do
                                    if not SetContains(TRANSMOG_CACHE[InventorySlotId], v) then
                                        AddToSet(TRANSMOG_CACHE[InventorySlotId], v)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return
        end
        if string.find(arg2, "NewTransmog", 1, true) then
            local ex = strsplit(arg2, ":")
            tmog_debug("id: ".. ex[2])
            local slot = InvenotySlotFromItemID(ex[2])
            local itemName = GetItemInfo(ex[2])
            if slot and itemName then
                tmog_debug("slot: "..slot)
                AddToSet(TRANSMOG_CACHE[slot], itemName)
                -- check if it shares Display ID with other items and add those if it does
                if SetContains(DisplayIdDB, itemName) then
                    for k,v in pairs(DisplayIdDB[itemName]) do
                        if not SetContains(TRANSMOG_CACHE[slot], v) then
                            AddToSet(TRANSMOG_CACHE[slot], v)
                        end
                    end
                end
            end
            return
        end
        if string.find(arg2, "TransmogStatus", 1, true) then
            local dataEx = strsplit(arg2, "TransmogStatus:")
            if dataEx[2] then
                local TransmogStatus = strsplit(dataEx[2], ",")
                if not TMOG_TRANSMOG_STATUS then
                    TMOG_TRANSMOG_STATUS = {}
                end
                for _, InventorySlotId in Tmog.inventorySlots do
                    if not TMOG_TRANSMOG_STATUS[InventorySlotId] then
                        TMOG_TRANSMOG_STATUS[InventorySlotId] = {}
                    end
                end
                for _, d in TransmogStatus do
                    local slotEx = strsplit(d, ":")
                    local InventorySlotId = tonumber(slotEx[1])
                    local itemID = tonumber(slotEx[2])
                    local link = GetInventoryItemLink("player", InventorySlotId)
                    local actualItemId = Tmog:IDFromLink(link) or 0
                    if actualItemId ~= 0 and InventorySlotId then
                        if not TMOG_TRANSMOG_STATUS[InventorySlotId][actualItemId] then
                            TMOG_TRANSMOG_STATUS[InventorySlotId][actualItemId] = 0
                        end
                        TMOG_TRANSMOG_STATUS[InventorySlotId][actualItemId] = itemID
                    end
                end
            end
            return
        end
    elseif event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
        tmog_debug(event)
        tmog_debug(arg1)
        for k,v in pairs(TRANSMOG_CACHE) do
            if TmogScanTooltip:SetInventoryItem("player", k) then
                local itemName = getglobal(TmogScanTooltip:GetName() .. "TextLeft1"):GetText()
                -- get rid of suffixes
                itemName = FixName(itemName)
                --tmog_debug(itemName)
                if itemName then
                    if not SetContains(TRANSMOG_CACHE[k], itemName) then
                        AddToSet(TRANSMOG_CACHE[k], itemName)
                    end
                    -- check if it shares Display ID with other items and add those if it does
                    if SetContains(DisplayIdDB, itemName) then
                        for _,v2 in pairs(DisplayIdDB[itemName]) do
                            if not SetContains(TRANSMOG_CACHE[k], v) then
                                AddToSet(TRANSMOG_CACHE[k], v2)
                            end
                        end
                    end
                end
            end
        end
    end
end)

local function GetTableForClass(class)
    if class == "DRUID" then
        return tmog_druid
    elseif class == "PALADIN" then
        return tmog_paladin
    elseif class == "SHAMAN" then
        return tmog_shaman
    elseif class == "MAGE" or class == "WARLOCK" then
        return tmog_magelock
    elseif class == "PRIEST" then
        return tmog_priest
    elseif class == "WARRIOR" then
        return tmog_warrior
    elseif class == "ROGUE" then
        return tmog_rogue
    elseif class == "HUNTER" then
        return tmog_hunter
    end
end

-- return true and slot if this is gear and we can equip it
function IsGear(tooltipTypeStr)
    local originalTooltip = {}
    local isGear = false
    local slot = nil
    -- collect left lines of the original tooltip into lua table
    for row = 1, 30 do
        local tooltipRowLeft = getglobal(tooltipTypeStr .. 'TextLeft' .. row)
        if tooltipRowLeft then
            local rowtext = tooltipRowLeft:GetText()
            if rowtext then
                originalTooltip[row] = {}
                originalTooltip[row].text = rowtext
            end
        end
    end
    local _, class = UnitClass("player")
    local tableToCheck = GetTableForClass(class)
    local canEquip = false
    for row=1, table.getn(originalTooltip) do
        -- check if its class restricted item
        if originalTooltip[row].text then
            local _, _, classesRow = string.find(originalTooltip[row].text, "Classes: (.*)")
            if classesRow then
                if not string.find(classesRow, UnitClass("player"),1,true) then
                    tmog_debug("Bad class")
                    return false, nil
                end
            end
            -- skip recipies
            if string.find(originalTooltip[row].text, "Pattern:",1,true) or
                string.find(originalTooltip[row].text, "Plans:",1,true) or
                string.find(originalTooltip[row].text, "Schematic:",1,true) then
                tmog_debug("Recipie")
                return false, nil
            end
        end
    end
    local off_hand = false
    for row=1, table.getn(originalTooltip) do
        if originalTooltip[row].text then
            -- Gear is guaranteed to be labeled with the slot it occupies.
            for _, v in ipairs(gearslots) do
                if v == originalTooltip[row].text then
                    if v == "Back" then
                        tmog_debug("Cloak")
                        return true, 15 -- everyone can equip
                    elseif v == "Held In Off-hand" then
                        tmog_debug("Off hand holdable")
                        return true, 17 -- everyone can equip
                    elseif v == "Head" then
                        slot = 1
                    elseif v == "Shoulder" then
                        slot = 3
                    elseif v == "Chest" then
                        slot = 5
                    elseif v == "Waist" then
                        slot = 6
                    elseif v == "Legs" then
                        slot = 7
                    elseif v == "Feet" then
                        slot = 8
                    elseif v == "Wrist" then
                        slot = 9
                    elseif v == "Hands" then
                        slot = 10
                    elseif v == "Main Hand" or v == "Two-Hand" or v == "One-Hand" then
                        slot = 16
                    elseif v == "Off Hand" then
                        slot = 17
                        off_hand = true -- some classes cant dual weild, will need to double check later
                    elseif v == "Ranged" then
                        slot = 18
                    elseif (v == "Gun" or v == "Crossbow") and (class == "WARRIOR" or class == "ROGUE" or class == "HUNTER") then
                        tmog_debug("Gun/Xbow, class - "..class)
                        return true, 18
                    elseif v == "Wand" and (class == "MAGE" or class == "WARLOCK" or class == "PRIEST") then
                        tmog_debug("Wand, class - "..class)
                        return true, 18
                    else
                        tmog_debug("Bad text left")
                        return false, nil
                    end
                    isGear = true
                end
            end
        end
    end
    if isGear then
        -- looking at the first line on the right
        local gearType
        for row=1, 30 do
            local tooltipRowRight = getglobal(tooltipTypeStr .. 'TextRight' .. row)
            if tooltipRowRight then
                local rowtext = tooltipRowRight:GetText()
                if rowtext and not string.find(rowtext, "Speed",1,true) -- ignore weapon speed
                        and not string.find(rowtext, "%d") then -- ignore digits
                    gearType = rowtext
                    tmog_debug(gearType)
                    break
                end
            end
        end
        if gearType then
            if SetContains(tableToCheck, gearType) then
                canEquip = true
                if off_hand and gearType ~= "Shield" and not (class == "WARRIOR" or class == "ROGUE" or class == "HUNTER") then
                    canEquip = false
                    tmog_debug("Cant dual weild")
                else
                    tmog_debug("Can Equip")
                end
            end
        end
    end

    if not canEquip then
        tmog_debug("Cant transmog")
        return false, nil
    end
    return isGear, slot
end

-- cache these so that game donesnt explode
local LastItemName = nil
local LastSlot = nil
function TmogTip.extendTooltip(tooltip, tooltipTypeStr)
    local itemName = getglobal(tooltip:GetName() .. "TextLeft1"):GetText()
    local isGear, slot = IsGear(tooltipTypeStr)
    local tLabel = getglobal(tooltip:GetName() .. "TextLeft2")
    if not isGear or not itemName or not tLabel then return end
    -- get rid of suffixes
    itemName = FixName(itemName)
    if itemName == LastItemName then
        if tLabel then
            if tLabel:GetText() then
                -- tooltips have max 30 lines so dont just AddLine, insert into 2nd line of the tooltip instead to avoid hitting lines cap
                if SetContains(TRANSMOG_CACHE[LastSlot], LastItemName) then
                    tLabel:SetText(GAME_YELLOW..'In your collection|r\n'..tLabel:GetText())
                else
                    tLabel:SetText(GAME_YELLOW..'Not collected|r\n'..tLabel:GetText())
                end
            end
        end
    else
        LastItemName = itemName
        LastSlot = slot
        if tLabel then
            if tLabel:GetText() then
                -- tooltips have max 30 lines so dont just AddLine, insert into 2nd line of the tooltip instead to avoid hitting lines cap
                if SetContains(TRANSMOG_CACHE[slot], itemName) then
                    tLabel:SetText(GAME_YELLOW..'In your collection|r\n'..tLabel:GetText())
                else
                    tLabel:SetText(GAME_YELLOW..'Not collected|r\n'..tLabel:GetText())
                end
            end
        end
    end
    tooltip:Show()
end

ItemRefTooltip:SetScript("OnHide", function()
    -- clear right text otherwise it will collect bunch of random strings and mess things up
    for row=1, 30 do
        getglobal("ItemRefTooltipTextRight" .. row):SetText("")
    end
end)

TmogTip:SetScript("OnHide", function()
    for row=1, 30 do
        getglobal("GameTooltipTextRight" .. row):SetText("")
    end
end)

TmogTip:SetScript("OnShow", function()
    TmogTip.extendTooltip(GameTooltip, "GameTooltip")
end)

TmogTooltip:SetScript("OnHide", function()
    for row=1, 30 do
        getglobal("TmogTooltipTextRight" .. row):SetText("")
    end
end)

-- adapted from http://shagu.org/ShaguTweaks/
Tmog.HookAddonOrVariable = function(addon, func)
    local lurker = CreateFrame("Frame", nil)
    lurker.func = func
    lurker:RegisterEvent("ADDON_LOADED")
    lurker:RegisterEvent("VARIABLES_LOADED")
    lurker:RegisterEvent("PLAYER_ENTERING_WORLD")
    lurker:SetScript("OnEvent",function()
      if IsAddOnLoaded(addon) or getglobal(addon) then
        this:func()
        this:UnregisterAllEvents()
      end
    end)
end

Tmog.HookAddonOrVariable("AtlasLoot", function()
    local atlas = CreateFrame("Frame", nil, AtlasLootTooltip)
    local atlas2 = CreateFrame("Frame", nil, AtlasLootTooltip2)
    atlas2:SetScript("OnHide", function()
        for row=1, 30 do
            getglobal("AtlasLootTooltip2" .. 'TextRight' .. row):SetText("")
        end
    end)
    atlas:SetScript("OnHide", function()
        for row=1, 30 do
            getglobal("AtlasLootTooltip" .. 'TextRight' .. row):SetText("")
        end
    end)
    atlas:SetScript("OnShow", function()
        TmogTip.extendTooltip(AtlasLootTooltip, "AtlasLootTooltip")
    end)
    atlas2:SetScript("OnShow", function()
        TmogTip.extendTooltip(AtlasLootTooltip2, "AtlasLootTooltip2")
    end)
end)

-------------------------------
------- ITEM BROWSER ----------
-------------------------------
-- Modified CosminPOP's Turtle_TransmogUI
TMOG_CURRENT_GEAR = {}
TMOG_PREVIEW_BUTTONS = {}
TMOG_SEARCH_STRING = nil

local _, race = UnitRace('player')
Tmog.race = string.lower(race)
Tmog.currentType = "Cloth"
Tmog.currentSlot = nil
Tmog.currentPage = 1
Tmog.ipp = 15 --items per page
Tmog.actualGear = {} -- actual gear + transmog
Tmog.currentTypesList = {} -- available types for current slot
Tmog.currentOutfit = nil
Tmog.collected = true --check box
Tmog.notCollected = true --check box
Tmog.currentTab = 'items'

Tmog.typesDefault = {
    [1]="Cloth",
    [2]="Leather",
    [3]="Mail",
    [4]="Plate",
}
Tmog.typesMisc = {
    [1]="Cloth",
    [2]="Leather",
    [3]="Mail",
    [4]="Plate",
    [5]="Miscellaneous",
}
Tmog.typesBack = {
    [1]="Cloth",
}
Tmog.typesShirt = {
    [1]="Miscellaneous",
}
Tmog.typesMh = {
    [1]="Daggers",
    [2]="One-Handed Axes",
    [3]="One-Handed Swords",
    [4]="One-Handed Maces",
    [5]="Fist Weapons",
    [6]="Two-Handed Axes",
    [7]="Two-Handed Swords",
    [8]="Two-Handed Maces",
    [9]="Polearms",
    [10]="Staves",
    [11]="Fishing Pole",
}
Tmog.typesOh = {
    [1]="Daggers",
    [2]="One-Handed Axes",
    [3]="One-Handed Swords",
    [4]="One-Handed Maces",
    [5]="Fist Weapons",
    [6]="Miscellaneous",
    [7]="Shields",
}
Tmog.typesRanged = {
    [1]="Bows",
    [2]="Guns",
    [3]="Crossbows",
    [4]="Wands",
}

Tmog.inventorySlots = {
    ['HeadSlot'] = 1,
    ['ShoulderSlot'] = 3,
    ['ChestSlot'] = 5,
    ['WaistSlot'] = 6,
    ['LegsSlot'] = 7,
    ['FeetSlot'] = 8,
    ['WristSlot'] = 9,
    ['HandsSlot'] = 10,
    ['BackSlot'] = 15,
    ['MainHandSlot'] = 16,
    ['SecondaryHandSlot'] = 17,
    ['RangedSlot'] = 18,
    ['ShirtSlot'] = 4,
    ['TabardSlot'] = 19
}

function Tmog_OnLoad()
    TmogFrameRaceBackground:SetTexture("Interface\\TransmogFrame\\transmogbackground"..Tmog.race)

    UIDropDownMenu_Initialize(TmogFrameTypeDropDown, TypeDropDown_Initialize)
    UIDropDownMenu_SetWidth(100, TmogFrameTypeDropDown)

    if not TMOG_PLAYER_OUTFITS then
        TMOG_PLAYER_OUTFITS = {}
    end
    if not TMOG_TRANSMOG_STATUS then
        TMOG_TRANSMOG_STATUS = {}
    end

    if not TMOG_CURRENT_GEAR then
        TMOG_CURRENT_GEAR = {}
    end

    UIDropDownMenu_Initialize(TmogFrameOutfitsDropDown, OutfitsDropDown_Initialize)
    UIDropDownMenu_SetWidth(115, TmogFrameOutfitsDropDown)
    TmogFrameSaveOutfit:Disable()
    TmogFrameDeleteOutfit:Disable()

    UIDropDownMenu_SetText("Outfits", TmogFrameOutfitsDropDown)

    TmogFrameCollected:SetChecked(Tmog.collected)
    TmogFrameNotCollected:SetChecked(Tmog.notCollected)

    tinsert(UISpecialFrames, "TmogFrame")
end

function Tmog:CacheAllGearSlots()
    for _, InventorySlotId in Tmog.inventorySlots do
        local link = GetInventoryItemLink("player", InventorySlotId)
        Tmog.actualGear[InventorySlotId] = Tmog:IDFromLink(link) or 0
    end
    for slot, data in TMOG_TRANSMOG_STATUS do
        local link = GetInventoryItemLink("player", slot)
        local id = Tmog:IDFromLink(link) or 0
        for actualItemID, transmogID in TMOG_TRANSMOG_STATUS[slot] do
            if actualItemID == id then
                Tmog.actualGear[slot] = transmogID
            end
        end
    end
end

function OutfitsDropDown_Initialize()
    if Tmog:tableSize(TMOG_PLAYER_OUTFITS) < 30 then
        local _, _, _, color = GetItemQualityColor(2)

        local newOutfit = {}
        newOutfit.text = color .. "+ New Outfit"
        newOutfit.value = 1
        newOutfit.arg1 = 1
        newOutfit.checked = false
        newOutfit.func = Tmog_NewOutfitPopup
        UIDropDownMenu_AddButton(newOutfit)
    end
    
    for name, data in TMOG_PLAYER_OUTFITS do
        local info = {}
        info.text = name
        info.value = name
        info.arg1 = name
        info.checked = Tmog.currentOutfit == name
        info.func = Tmog_LoadOutfit
        UIDropDownMenu_AddButton(info)
    end

end

function TypeDropDown_Initialize()
    if Tmog.currentSlot == 1 or Tmog.currentSlot == 5 or Tmog.currentSlot == 8 then
        Tmog.currentTypesList = Tmog.typesMisc
    elseif Tmog.currentSlot == 15 then
        Tmog.currentTypesList = Tmog.typesBack
    elseif Tmog.currentSlot == 4 or Tmog.currentSlot == 19 then
        Tmog.currentTypesList = Tmog.typesShirt
    elseif Tmog.currentSlot == 10 or Tmog.currentSlot == 6 or Tmog.currentSlot == 7 or Tmog.currentSlot == 3 or Tmog.currentSlot == 9 then
        Tmog.currentTypesList = Tmog.typesDefault
    elseif Tmog.currentSlot == 16 then
        Tmog.currentTypesList = Tmog.typesMh
    elseif Tmog.currentSlot == 17 then
        Tmog.currentTypesList = Tmog.typesOh
    elseif Tmog.currentSlot == 18 then
        Tmog.currentTypesList = Tmog.typesRanged
    end
    
    for _, v in ipairs(Tmog.currentTypesList) do
        local info = {}
        info.text = v
        info.arg1 = v
        info.checked = Tmog.currentType == v
        info.func = Tmog_SelectType
        UIDropDownMenu_AddButton(info)
    end
end

function Tmog_SelectType(typeStr)
    UIDropDownMenu_SetText(typeStr, TmogFrameTypeDropDown)
    Tmog.currentType = typeStr
    Tmog.currentPage = 1
    Tmog:HidePreviews()
    Tmog:DrawPreviews(Tmog.currentSlot)
end

function Tmog:HidePreviews()
    for index, _ in TMOG_PREVIEW_BUTTONS do
        getglobal('TmogFramePreview' .. index):Hide()
        getglobal('TmogFramePreview' .. index .. 'ButtonCheck'):Hide()
    end
end

function Tmog:DrawPreviews(InventorySlotId, searchStr)
    if self.currentPage == self.totalPages then
        self:HidePreviews()
    end
    TMOG_SEARCH_STRING = searchStr
    self.currentSlot = InventorySlotId
    local index = 0
    local row = 0
    local col = 0
    local itemIndex = 1
    local outfitIndex = 1
    local type = self.currentType

    if Tmog.currentTab == 'items' then

        if (not Tmog.collected and not Tmog.notCollected) or not InventorySlotId then
            self:HidePreviews()
            self:HidePagination()
            self.currentPage = 1
            return
        end

        local t = {}
        t[InventorySlotId] = {}

        if searchStr then
            type = "SearchResult"
        end

        t[InventorySlotId][type] = {}
        
        -- only Collected checked
        if Tmog.collected and not Tmog.notCollected then
            if searchStr then
                for k, _ in pairs(TmogGearDB[InventorySlotId]) do
                    for itemName, itemID in pairs(TmogGearDB[InventorySlotId][k]) do
                        if SetContains(TRANSMOG_CACHE[InventorySlotId], itemName) then
                            local name = string.lower(itemName)
                            if string.find(name, searchStr, 1 ,true) then
                                t[InventorySlotId][type][itemName] = itemID
                            end
                        end
                    end
                end
            else
                for name, itemID in pairs(TmogGearDB[InventorySlotId][type]) do
                    if SetContains(TRANSMOG_CACHE[InventorySlotId], name) then
                        t[InventorySlotId][type][name] = itemID
                    end
                end
            end
        -- only Not Collected checked
        elseif Tmog.notCollected and not Tmog.collected then
            if searchStr then
                for k, _ in pairs(TmogGearDB[InventorySlotId]) do
                    for itemName, itemID in pairs(TmogGearDB[InventorySlotId][k]) do
                        if not SetContains(TRANSMOG_CACHE[InventorySlotId], itemName) then
                            local name = string.lower(itemName)
                            if string.find(name, searchStr, 1 ,true) then
                                t[InventorySlotId][type][itemName] = itemID
                            end
                        end
                    end
                end
            else
                for name, itemID in pairs(TmogGearDB[InventorySlotId][type]) do
                    if not SetContains(TRANSMOG_CACHE[InventorySlotId], name) then
                        t[InventorySlotId][type][name] = itemID
                    end
                end
            end
        -- both checked
        elseif Tmog.collected and Tmog.notCollected then
            if searchStr then
                for k, _ in pairs(TmogGearDB[InventorySlotId]) do
                    for itemName, itemID in pairs(TmogGearDB[InventorySlotId][k]) do
                        local name = string.lower(itemName)
                        if itemName and string.find(name, searchStr, 1 ,true) then
                            t[InventorySlotId][type][itemName] = itemID
                        end
                    end
                end
            else
                t[InventorySlotId][type] = TmogGearDB[InventorySlotId][type]
            end
        end

        -- nothing to show
        if not t[InventorySlotId][type] or next(t[InventorySlotId][type]) == nil then
            self:HidePreviews()
            self:HidePagination()
            self.currentPage = 1
            return
        end

        for name, itemID in next, t[InventorySlotId][type] do

            if index >= (self.currentPage - 1) * self.ipp and index < self.currentPage * self.ipp then
                if not TMOG_PREVIEW_BUTTONS[itemIndex] then
                    TMOG_PREVIEW_BUTTONS[itemIndex] = CreateFrame('Frame', 'TmogFramePreview' .. itemIndex, TmogFrame, 'TmogFramePreviewTemplate')
                end

                TMOG_PREVIEW_BUTTONS[itemIndex]:SetPoint("TOPLEFT", TmogFrame, "TOPLEFT", 263 + col * 90, -105 - 120 * row)
                TMOG_PREVIEW_BUTTONS[itemIndex].name = name
                TMOG_PREVIEW_BUTTONS[itemIndex].id = itemID
                
                Tmog:CacheItem(itemID)

                if SetContains(TRANSMOG_CACHE[InventorySlotId], name) then
                    getglobal('TmogFramePreview' .. itemIndex .. 'ButtonCheck'):Show()
                else
                    getglobal('TmogFramePreview' .. itemIndex .. 'ButtonCheck'):Hide()
                end

                getglobal('TmogFramePreview' .. itemIndex .. 'Button'):SetID(itemID)

                local _, _, quality = GetItemInfo(itemID)
                if quality then
                    local _, _, _, color = GetItemQualityColor(quality)
                    Tmog_AddItemTooltip(getglobal('TmogFramePreview' .. itemIndex .. 'Button'), color .. name)
                else
                    Tmog_AddItemTooltip(getglobal('TmogFramePreview' .. itemIndex .. 'Button'), name)
                end

                TMOG_PREVIEW_BUTTONS[itemIndex]:Show()

                --this is for updating tooltip while scrolling with mousewheel
                if MouseIsOver(TMOG_PREVIEW_BUTTONS[itemIndex]) then
                    TMOG_PREVIEW_BUTTONS[itemIndex]:Hide()
                    TMOG_PREVIEW_BUTTONS[itemIndex]:Show()
                end

                local model = getglobal('TmogFramePreview' .. itemIndex .. 'ItemModel')
                model:SetUnit("player")
                model:SetRotation(0.61)

                local Z, X, Y = model:GetPosition(Z, X, Y)
                if self.race == 'nightelf' or self.race == "bloodelf" then
                    Z = Z + 3
                end
                if self.race == 'gnome' then
                    Z = Z - 3
                    Y = Y + 1.5
                end
                if self.race == 'dwarf' then
                    Y = Y + 1
                    Z = Z - 1
                end
                if self.race == 'troll' then
                    Z = Z + 2
                end
                if self.race == 'goblin' then
                    Z = Z - 0.5
                end
                -- head
                if InventorySlotId == 1 then
                    if self.race == 'tauren' or self.race == "troll"  then
                        model:SetRotation(0.3)
                        X = X - 0.5
                        Z = Z + 2
                    end
                    if self.race == "orc" then
                        model:SetRotation(0.2)
                        Z = Z + 2
                        Y = Y - 0.5
                    end
                    if self.race == 'goblin'  then
                        Y = Y + 1.5
                    end
                    if self.race == 'dwarf' then
                        Z = Z + 0.5
                    end
                    if self.race == 'nightelf' then
                        Z = Z + 2
                        Y = Y - 1
                    end
                    if self.race == "bloodelf" then
                        Z = Z + 1
                        Y = Y - 1.2
                    end
                    if self.race == "human" then
                        Z = Z + 1
                        Y = Y - 0.5
                    end
                    if self.race == "gnome" then
                        Y = Y - 0.3
                    end
                    model:SetPosition(Z + 6.8, X, Y - 2.2)
                end
                -- shoulder
                if InventorySlotId == 3 then
                    if self.race == 'dwarf' then
                        Y = Y - 0.2
                    end
                    if self.race == 'goblin' then
                        Y = Y + 1.5
                        Z = Z - 0.5
                    end

                    model:SetPosition(Z + 5.8, X + 0.5, Y - 1.7)
                end
                -- cloak
                if InventorySlotId == 15 then
                    model:SetRotation(3.2)
                    if self.race == 'goblin' then
                        Y = Y + 1.5
                    end
                    model:SetPosition(Z + 4.8, X, Y - 1)
                end
                -- chest
                if InventorySlotId == 5 or InventorySlotId == 4 or InventorySlotId == 19 then
                    if self.race == 'tauren' or self.race == "troll" then
                        model:SetRotation(0.3)
                        X = X - 0.2
                        Y = Y + 0.5
                    end
                    if self.race == 'goblin' then
                        Y = Y + 1.5
                        Z = Z - 0.5
                    end
                    model:SetRotation(0.61)
                    model:SetPosition(Z + 5.8, X + 0.1, Y - 1.2)
                end
                -- bracer
                if InventorySlotId == 9 then
                    model:SetRotation(1.5)
                    if self.race == 'tauren' then
                        X = X - 0.2
                    end
                    if self.race == 'gnome' then
                        Z = Z + 1
                    end
                    if self.race == 'dwarf' then
                        X = X - 0.3
                        Y = Y - 0.4
                    end
                    if self.race == 'troll' then
                        Y = Y + 0.6
                    end
                    if self.race == 'goblin' then
                        Z = Z - 0.5
                    end
                    model:SetPosition(Z + 5.8, X + 0.4, Y - 0.3)
                end
                -- hands
                if InventorySlotId == 10 or InventorySlotId == 9 then
                    model:SetRotation(1.5)
                    if self.race == 'gnome' then
                        Y = Y - 0.7
                        Z = Z + 0.5
                    end
                    if self.race == 'tauren' then
                        X = X - 0.2
                    end
                    if self.race == 'dwarf' then
                        Z = Z - 0.2
                        X = X - 0.3
                        Y = Y - 0.1
                    end
                    if self.race == 'troll' then
                        Y = Y + 0.9
                    end
                    if self.race == 'goblin' then
                        Y = Y + 1.5
                        Z = Z - 0.5
                    end
                    if self.race == 'nightelf' then
                        Z = Z + 2
                    end
                    model:SetPosition(Z + 5.8, X + 0.4, Y - 0.3)
                end
                -- belt
                if InventorySlotId == 6 then
                    model:SetRotation(0.31)

                    if self.race == 'tauren' then
                        Z = Z + 1
                        Y = Y + 0.3
                    end
                    if self.race == 'goblin' then
                        Y = Y + 1.5
                        Z = Z - 0.5
                    end
                    if self.race == 'dwarf' then
                        Z = Z - 2
                    end
                    if self.race == 'nightelf' or self.race == "bloodelf" then
                        Z = Z - 1
                    end
                    if self.race == "human" then
                        Z = Z - 1
                        Y = Y - 0.5
                    end
                    model:SetPosition(Z + 8, X, Y - 0.4)
                end
                -- pants
                if InventorySlotId == 7 then
                    model:SetRotation(0.31)
                    if self.race == 'gnome' then
                        Z = Z + 2
                        Y = Y - 1.3
                    end
                    if self.race == 'dwarf' then
                        Y = Y - 0.9
                    end
                    if self.race == 'tauren' then
                        Z = Z + 1
                    end
                    model:SetPosition(Z + 5.8, X, Y + 0.9)
                end
                -- boots
                if InventorySlotId == 8 then
                    model:SetRotation(0.61)
                    if self.race == 'gnome' then
                        Z = Z + 2
                        Y = Y - 1.6
                    end
                    if self.race == 'dwarf' then
                        Y = Y - 0.6
                    end
                    if self.race == 'tauren' then
                        Z = Z + 1
                    end
                    model:SetPosition(Z + 5.8, X, Y + 1.5)
                end

                -- mh
                if InventorySlotId == 16 then
                    model:SetRotation(0.61)
                    if self.race == 'gnome' then
                        Y = Y - 2
                    end
                    if self.race == 'dwarf' then
                        Y = Y - 1
                    end
                    model:SetPosition(Z + 3.8, X, Y + 0.4)

                end

                -- oh
                if InventorySlotId == 17 then
                    model:SetRotation(-0.61)

                    if self.race == 'gnome' then
                        Y = Y - 2
                    end
                    if self.race == 'dwarf' then
                        Y = Y - 1
                    end
                    model:SetPosition(Z + 3.8, X, Y + 0.4)
                end

                -- ranged
                if InventorySlotId == 18 then
                    model:SetRotation(-0.61)

                    if self.race == 'troll' then
                        Y = Y + 1.5
                    end
                    if self.race == 'goblin' then
                        Y = Y + 1
                    end
                    if self.race == 'gnome' then
                        Y = Y - 1.5
                    end
                    model:SetPosition(Z + 3.8, X, Y)
                end

                model:Undress()
                model:TryOn(itemID)

                col = col + 1
                if col == 5 then
                    row = row + 1
                    col = 0
                end
                itemIndex = itemIndex + 1
            end
            index = index + 1
        end
        self.totalPages = self:ceil(self:tableSize(t[InventorySlotId][type]) / self.ipp)
        TmogFramePageText:SetText("Page " .. self.currentPage .. "/" .. self.totalPages)
    
        if self.currentPage == 1 then
            TmogFrameLeftArrow:Disable()
        else
            TmogFrameLeftArrow:Enable()
        end
    
        if self.currentPage == self.totalPages or self:tableSize(t[InventorySlotId][type]) < self.ipp then
            TmogFrameRightArrow:Disable()
        else
            TmogFrameRightArrow:Enable()
        end
    elseif Tmog.currentTab == 'outfits' then
        self:HidePreviews()

        for name, _ in next, TMOG_PLAYER_OUTFITS do
            if index >= (self.currentPage - 1) * self.ipp and index < self.currentPage * self.ipp then
                if not TMOG_PREVIEW_BUTTONS[outfitIndex] then
                    TMOG_PREVIEW_BUTTONS[outfitIndex] = CreateFrame('Frame', 'TmogFramePreview' .. outfitIndex, TmogFrame, 'TmogFramePreviewTemplate')
                end

                TMOG_PREVIEW_BUTTONS[outfitIndex]:SetPoint("TOPLEFT", TmogFrame, "TOPLEFT", 263 + col * 90, -105 - 120 * row)
                TMOG_PREVIEW_BUTTONS[outfitIndex].name = name
                
                getglobal('TmogFramePreview' .. outfitIndex .. 'Button'):SetID(outfitIndex)

                Tmog_AddOutfitTooltip(getglobal('TmogFramePreview' .. outfitIndex .. 'Button'), name)

                TMOG_PREVIEW_BUTTONS[outfitIndex]:Show()

                local model = getglobal('TmogFramePreview' .. outfitIndex .. 'ItemModel')

                model:SetUnit("player")
                model:SetRotation(0.61)
                local Z, X, Y = model:GetPosition(Z, X, Y)

                model:SetPosition(Z + 1.5, X, Y)
                model:Undress()

                for _, itemID in (TMOG_PLAYER_OUTFITS[name]) do
                    model:TryOn(itemID)
                end

                col = col + 1
                if col == 5 then
                    row = row + 1
                    col = 0
                end

                outfitIndex = outfitIndex + 1
            end
            index = index + 1
        end
        self.totalPages = self:ceil(self:tableSize(TMOG_PLAYER_OUTFITS) / self.ipp)
        TmogFramePageText:SetText("Page " .. self.currentPage .. "/" .. self.totalPages)
    
        if self.currentPage == 1 then
            TmogFrameLeftArrow:Disable()
        else
            TmogFrameLeftArrow:Enable()
        end
    
        if self.currentPage == self.totalPages or self:tableSize(TMOG_PLAYER_OUTFITS) < self.ipp then
            TmogFrameRightArrow:Disable()
        else
            TmogFrameRightArrow:Enable()
        end
    end

    if self.totalPages > 1 then
        self:ShowPagination()
    else
        self:HidePagination()
    end
end

function Tmog:ShowPagination()
    TmogFrameLeftArrow:Show()
    TmogFrameRightArrow:Show()
    TmogFramePageText:Show()
end

function Tmog:HidePagination()
    TmogFrameLeftArrow:Hide()
    TmogFrameRightArrow:Hide()
    TmogFramePageText:Hide()
end

function Tmog_ChangePage(dir)
    if not Tmog.currentPage or not Tmog.totalPages then return end
    if (Tmog.currentPage + dir < 1) or (Tmog.currentPage + dir > Tmog.totalPages) then
        return
    end
    Tmog.currentPage = Tmog.currentPage + dir
    Tmog:DrawPreviews(Tmog.currentSlot, TMOG_SEARCH_STRING)
end

function Tmog:tableSize(t)
    if type(t) ~= 'table' then
        return 0
    end
    local size = 0
    for i, d in t do
        size = size + 1
    end
    return size
end

function Tmog:ceil(num)
    if num > math.floor(num) then
        return math.floor(num + 1)
    end
    return math.floor(num + 0.5)
end

function Tmog:IDFromLink(link)
    if not link then return nil end
    local itemSplit = strsplit(link, ':')
    if itemSplit[2] and tonumber(itemSplit[2]) then
        return tonumber(itemSplit[2])
    end
    return nil
end

function TmogSlot_OnClick(InventorySlotId, rightClick)
    CloseDropDownMenus()

    if rightClick then
        if TMOG_CURRENT_GEAR[InventorySlotId] == 0 then
            TmogFramePlayerModel:TryOn(Tmog.actualGear[InventorySlotId])
            TMOG_CURRENT_GEAR[InventorySlotId] = Tmog.actualGear[InventorySlotId]
        else
            TmogFramePlayerModel:Undress()
            for slot, itemID in next, TMOG_CURRENT_GEAR do
                if slot ~= InventorySlotId then
                    TmogFramePlayerModel:TryOn(itemID)
                end
            end
            TMOG_CURRENT_GEAR[InventorySlotId] = 0
        end

        Tmog:EnableOutfitSaveButton()
        Tmog:UpdateItemTextures()
        --update tooltip
        this:Hide()
        this:Show()
    else
        Tmog.currentPage = 1
        Tmog.currentSlot = InventorySlotId
        if Tmog.currentTab == 'outfits' then
            if getglobal(this:GetName().."BorderFull"):IsVisible() then
                Tmog_switchTab('items')
                return
            else
                Tmog_switchTab('items')
            end
        end
        Tmog:HidePreviews()
        Tmog:HidePagination()

        UIDropDownMenu_Initialize(TmogFrameTypeDropDown, TypeDropDown_Initialize)
        TmogFrameSearchBox:Show()
        TmogFrameSearchButton:Show()

        local found = false
        for k,v in Tmog.currentTypesList do
            if v == Tmog.currentType then
                found = true
            end
        end
        if not found then
            Tmog.currentType = "Cloth"
        end

        if not getglobal(this:GetName().."BorderFull"):IsVisible() then
            Tmog:HideBorders()
            getglobal(this:GetName().."BorderFull"):Show()
            if InventorySlotId == 4 or InventorySlotId == 19 then
                Tmog.currentType = "Miscellaneous"
                TmogFrameTypeDropDown:Hide()
            elseif (InventorySlotId == 16 or InventorySlotId == 17) and not found then
                Tmog.currentType = "Daggers"
                TmogFrameTypeDropDown:Show()
            elseif InventorySlotId == 18 then
                Tmog.currentType = "Bows"
                TmogFrameTypeDropDown:Show()
            elseif InventorySlotId == 15 then
                Tmog.currentType = "Cloth"
                TmogFrameTypeDropDown:Hide()
            else
                TmogFrameTypeDropDown:Show()
            end
            Tmog_SelectType(Tmog.currentType)
            UIDropDownMenu_SetText(Tmog.currentType, TmogFrameTypeDropDown)
        else
            TmogFrameTypeDropDown:Hide()
            Tmog:HideBorders()
            Tmog.currentSlot = nil
            TmogFrameSearchBox:Hide()
            TmogFrameSearchButton:Hide()
        end
        TmogFrameSearchButton:Click()
    end
end

function Tmog:FixTabard()
    local link = GetInventoryItemLink("player",19)
    if link then
        TmogFramePlayerModel:TryOn(Tmog:IDFromLink(link))
    end
end

function TmogFrame_OnShow()
    if Tmog.race == "scourge" then Tmog.race = "undead" end
    TmogFrameRaceBackground:SetTexture("Interface\\TransmogFrame\\transmogbackground"..Tmog.race)

    Tmog_Reset()

    TmogFramePlayerModel:SetScript('OnMouseUp', function(self)
        TmogFramePlayerModel:SetScript('OnUpdate', nil)
    end)

    TmogFramePlayerModel:SetScript('OnMouseWheel', function(self, spining)
        local Z, X, Y = TmogFramePlayerModel:GetPosition()
        Z = (arg1 > 0 and Z + 1 or Z - 1)
        TmogFramePlayerModel:SetPosition(Z, X, Y)
    end)

    TmogFramePlayerModel:SetScript('OnMouseDown', function()
        TmogFrameSearchBox:ClearFocus()
        CloseDropDownMenus()
        local StartX, StartY = GetCursorPosition()
        local EndX, EndY, Z, X, Y
        if arg1 == 'LeftButton' then
            TmogFramePlayerModel:SetScript('OnUpdate', function(self)
                EndX, EndY = GetCursorPosition()
                TmogFramePlayerModel.rotation = (EndX - StartX) / 34 + TmogFramePlayerModel:GetFacing()
                TmogFramePlayerModel:SetFacing(TmogFramePlayerModel.rotation)
                StartX, StartY = GetCursorPosition()
            end)
        elseif arg1 == 'RightButton' then
            TmogFramePlayerModel:SetScript('OnUpdate', function(self)
                EndX, EndY = GetCursorPosition()

                Z, X, Y = TmogFramePlayerModel:GetPosition(Z, X, Y)
                X = (EndX - StartX) / 45 + X
                Y = (EndY - StartY) / 45 + Y

                TmogFramePlayerModel:SetPosition(Z, X, Y)
                StartX, StartY = GetCursorPosition()
            end)
        end
    end)

    Tmog:UpdateItemTextures()
    Tmog:HidePreviews()

    if Tmog.currentSlot then
        Tmog:DrawPreviews(Tmog.currentSlot)
    end
end

function Tmog:UpdateItemTextures()
    -- add paperdoll textures
    for slotName, InventorySlotId in Tmog.inventorySlots do
        local frame = getglobal("TmogFrame"..slotName)
        if frame then
            local texture
            local texEx = strsplit(frame:GetName(), 'Slot')
            texture = string.lower(texEx[1])
            texture = string.gsub(texture,"tmogframe","")
            if texture == 'wrist' then
                texture = texture .. 's'
            end
            if texture == 'back' then
                texture = 'chest'
            end
            getglobal(frame:GetName() .. 'ItemIcon'):SetTexture('Interface\\Paperdoll\\ui-paperdoll-slot-' .. texture)
        end
    end

    -- add item textures
    for slotName, InventorySlotId in Tmog.inventorySlots do
        if GetInventoryItemLink('player', InventorySlotId) or GetItemInfo(TMOG_CURRENT_GEAR[InventorySlotId]) then
            local _, _, _, _, _, _, _, _, tex = GetItemInfo(TMOG_CURRENT_GEAR[InventorySlotId])
            local frame = getglobal("TmogFrame"..slotName)

            if frame and tex then
                frame:Enable()
                frame:SetID(InventorySlotId)
                getglobal(frame:GetName() .. 'ItemIcon'):SetTexture(tex)
            end
        end
    end
end

function TmogFrame_OnHide()
    PlaySound("igCharacterInfoClose")
end

function TmogTry(itemId)
    CloseDropDownMenus()
    if Tmog.currentTab == 'items' then
        TmogFramePlayerModel:TryOn(itemId)
        TMOG_CURRENT_GEAR[Tmog.currentSlot] = itemId
        Tmog:EnableOutfitSaveButton()
        Tmog:UpdateItemTextures()
    elseif Tmog.currentTab == 'outfits' then
        local outfit = TMOG_PREVIEW_BUTTONS[this:GetID()].name
        Tmog.currentOutfit = outfit
        Tmog_LoadOutfit(outfit)
    end
end

function Tmog_RemoveCurrentGear()
    TmogFramePlayerModel:Undress()
    for _, InventorySlotId in Tmog.inventorySlots do
        TMOG_CURRENT_GEAR[InventorySlotId] = 0
    end
    Tmog:UpdateItemTextures()
end

function Tmog_ResetPosition()
    TmogFramePlayerModel:SetPosition(0,0,0)
    TmogModel_OnLoad()
end

function TmogModel_OnLoad()
    TmogFramePlayerModel.rotation = 0.61
    TmogFramePlayerModel:SetRotation(TmogFramePlayerModel.rotation)
end

function Tmog_Reset()
    Tmog.currentOutfit = nil
    TmogFrameSaveOutfit:Disable()
    TmogFrameDeleteOutfit:Disable()
    UIDropDownMenu_SetText("Outfits", TmogFrameOutfitsDropDown)

    TmogFramePlayerModel:SetPosition(0,0,0)
    TmogModel_OnLoad()
    TmogFramePlayerModel:Dress()
    Tmog:FixTabard()

    for _, InventorySlotId in Tmog.inventorySlots do
        Tmog.actualGear[InventorySlotId] = 0
    end

    for _, InventorySlotId in Tmog.inventorySlots do
        TMOG_CURRENT_GEAR[InventorySlotId] = 0
    end

    Tmog:CacheAllGearSlots()

    for _, InventorySlotId in Tmog.inventorySlots do
        TMOG_CURRENT_GEAR[InventorySlotId] = Tmog.actualGear[InventorySlotId]
    end

    Tmog:UpdateItemTextures()
end

function Tmog:HideBorders()
    TmogFrameHeadSlotBorderFull:Hide()
    TmogFrameShoulderSlotBorderFull:Hide()
    TmogFrameBackSlotBorderFull:Hide()
    TmogFrameChestSlotBorderFull:Hide()
    TmogFrameWristSlotBorderFull:Hide()
    TmogFrameHandsSlotBorderFull:Hide()
    TmogFrameWaistSlotBorderFull:Hide()
    TmogFrameLegsSlotBorderFull:Hide()
    TmogFrameFeetSlotBorderFull:Hide()
    TmogFrameMainHandSlotBorderFull:Hide()
    TmogFrameSecondaryHandSlotBorderFull:Hide()
    TmogFrameShirtSlotBorderFull:Hide()
    TmogFrameTabardSlotBorderFull:Hide()
    TmogFrameRangedSlotBorderFull:Hide()
end

function Tmog:GetItemIDByName(name)
    for k, v in pairs(TmogGearDB) do
        for k2,v2 in pairs(TmogGearDB[k]) do
            for itemName, itemID in pairs(TmogGearDB[k][k2]) do
                if itemName == name then
                    return itemID
                end
            end
        end
    end
	return nil
end

function Tmog:CacheItem(linkOrID)
    if not linkOrID or linkOrID == 0 then
        return
    end

    if tonumber(linkOrID) then
        if GetItemInfo(linkOrID) then
            -- item ok, break
            return true
        else
            local item = "item:" .. linkOrID .. ":0:0:0"
            local _, _, itemLink = string.find(item, "(item:%d+:%d+:%d+:%d+)")
            linkOrID = itemLink
        end
    else
        if string.find(linkOrID, "|", 1, true) then
            local _, _, itemLink = string.find(linkOrID, "(item:%d+:%d+:%d+:%d+)")
            linkOrID = itemLink
            if GetItemInfo(self:IDFromLink(linkOrID)) then
                -- item ok, break
                return true
            end
        end
    end

    GameTooltip:SetHyperlink(linkOrID)
end

function Tmog_AddOutfitTooltip(frame, outfit)
    frame:SetScript("OnEnter", function()

        TmogTooltip:SetOwner(this, "ANCHOR_RIGHT", -(this:GetWidth() / 4) + 15, -(this:GetHeight() / 4) + 20)

        if outfit then
            TmogTooltip:AddLine(HIGHLIGHT_FONT_COLOR_CODE .. outfit)
        end

        for name, data in TMOG_PLAYER_OUTFITS do
            if name == outfit then
                for slot, itemID in TMOG_PLAYER_OUTFITS[name] do
                    local slotName
                    for k,v in Tmog.inventorySlots do
                        if v == slot then
                            slotName = k
                        end
                    end
                    if slotName then
                        slotName = TEXT(getglobal(strupper(slotName)))
                        local itemName, _, quality = GetItemInfo(itemID)
                        local _, _, _, color = GetItemQualityColor(quality)
                        if color then
                            TmogTooltip:AddLine(slotName..": "..color..itemName)
                        else
                            TmogTooltip:AddLine(slotName..": "..itemName)
                        end
                    end
                end
            end
        end
        TmogTooltip:Show()
    end)

    frame:SetScript("OnLeave", function()
        TmogTooltip:Hide()
    end)
end

function Tmog_AddItemTooltip(frame, text)
    frame:SetScript("OnEnter", function()

        TmogTooltip:SetOwner(this, "ANCHOR_RIGHT", -(this:GetWidth() / 4) + 15, -(this:GetHeight() / 4) + 20)

        if text then
            TmogTooltip:AddLine(HIGHLIGHT_FONT_COLOR_CODE .. text)
        end

        Tmog:CacheItem(this:GetID())
        TmogTooltip.itemID = this:GetID()
        TmogTooltip:SetHyperlink("item:"..tostring(this:GetID()))
        TmogTip.extendTooltip(TmogTooltip, "TmogTooltip")

        local numLines = TmogTooltip:NumLines()
        if numLines and numLines > 0 then
            local lastLine = getglobal("TmogTooltipTextLeft"..numLines)
            if lastLine:GetText() then
                lastLine:SetText(lastLine:GetText().."\n\n"..GAME_YELLOW.."ItemID: "..this:GetID())
                local name = GetItemInfo(this:GetID())
                if name and SetContains(DisplayIdDB, name) then
                    lastLine:SetText(lastLine:GetText().."\n\n"..GAME_YELLOW.."Shares Appearance With:")
                    for k,v in DisplayIdDB[name] do
                        local id = Tmog:GetItemIDByName(v)
                        if id then
                            Tmog:CacheItem(id)
                            local _, _, quality = GetItemInfo(id)
                            if quality then
                                local _, _, _, color = GetItemQualityColor(quality)
                                if color then
                                    lastLine:SetText(lastLine:GetText().."\n"..color..v)
                                else
                                    lastLine:SetText(lastLine:GetText().."\n"..v)
                                end
                            end
                        end
                    end
                end
            end
        end

        TmogTooltip:Show()
    end)

    frame:SetScript("OnLeave", function()
        TmogTooltip:Hide()
        TmogTooltip.itemID = nil
    end)
end

local hidden = false
function Tmog_HideUI()
    if not hidden then
        for slot,v in pairs(Tmog.inventorySlots) do
            getglobal("TmogFrame"..slot):Hide()
        end
        TmogFrameRevert:Hide()
        TmogFrameHideUI:SetText("ShowUI")
        hidden = true
    else
        for slot,v in pairs(Tmog.inventorySlots) do
            getglobal("TmogFrame"..slot):Show()
        end
        TmogFrameRevert:Show()
        TmogFrameHideUI:SetText("HideUI")
        hidden = false
    end
end

function Tmog_LoadOutfit(outfit)
    UIDropDownMenu_SetText(outfit, TmogFrameOutfitsDropDown)

    Tmog.currentOutfit = outfit
    Tmog:EnableOutfitSaveButton()
    TmogFrameDeleteOutfit:Enable()
    Tmog_RemoveCurrentGear()

    for slot, itemID in pairs(TMOG_PLAYER_OUTFITS[outfit]) do
        TmogFramePlayerModel:TryOn(itemID)
        TMOG_CURRENT_GEAR[slot] = itemID
    end
    Tmog:UpdateItemTextures()
end

function Tmog:EnableOutfitSaveButton()
    if self.currentOutfit ~= nil then
        TmogFrameSaveOutfit:Enable()
    end
end

function Tmog_SaveOutfit()
    TMOG_PLAYER_OUTFITS[Tmog.currentOutfit] = {}
    for InventorySlotId, itemID in pairs(TMOG_CURRENT_GEAR) do
        if itemID ~= 0 then
            TMOG_PLAYER_OUTFITS[Tmog.currentOutfit][InventorySlotId] = itemID
        end
    end
    TmogFrameSaveOutfit:Disable()
    if Tmog.currentTab == "outfits" then
        Tmog:HidePreviews()
        Tmog:DrawPreviews(Tmog.currentSlot)
    end
end

function Tmog_DeleteOutfit()
    TMOG_PLAYER_OUTFITS[Tmog.currentOutfit] = nil
    TmogFrameSaveOutfit:Disable()
    TmogFrameDeleteOutfit:Disable()
    Tmog.currentOutfit = nil
    UIDropDownMenu_SetText("Outfits", TmogFrameOutfitsDropDown)
    if Tmog.currentTab == "outfits" then
        Tmog:HidePreviews()
        Tmog:DrawPreviews(Tmog.currentSlot)
    end
end

function Tmog_NewOutfitPopup()
    StaticPopup_Show("TMOG_NEW_OUTFIT")
end

StaticPopupDialogs["TMOG_NEW_OUTFIT"] = {
    text = "Enter Outfit Name:",
    button1 = "Save",
    button2 = "Cancel",
    hasEditBox = 1,
    OnShow = function()
        getglobal(this:GetName().."EditBox"):SetFocus()
        getglobal(this:GetName() .. "EditBox"):SetScript("OnEnterPressed", function()
            StaticPopup1Button1:Click()
        end)
        getglobal(this:GetName() .. "EditBox"):SetScript("OnEscapePressed", function()
            getglobal(this:GetParent():GetName() .. "EditBox"):SetText('')
            StaticPopup1Button2:Click()
        end)
    end,
    OnAccept = function()
        local outfitName = getglobal(this:GetParent():GetName() .. "EditBox"):GetText()
        if outfitName == '' then
            StaticPopup_Show('TMOG_OUTFIT_EMPTY_NAME')
            return
        end
        if TMOG_PLAYER_OUTFITS[outfitName] then
            StaticPopup_Show('TMOG_OUTFIT_EXISTS')
            return
        end
        UIDropDownMenu_SetText(outfitName, TmogFrameOutfitsDropDown)
        Tmog.currentOutfit = outfitName
        Tmog:EnableOutfitSaveButton()
        Tmog_SaveOutfit()
        getglobal(this:GetParent():GetName() .. "EditBox"):SetText('')
    end,
    timeout = 0,
    whileDead = 0,
    hideOnEscape = 1,
}

StaticPopupDialogs["TMOG_OUTFIT_EXISTS"] = {
    text = "Outfit with this name already exists.",
    button1 = "Okay",
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1
}

StaticPopupDialogs["TMOG_OUTFIT_EMPTY_NAME"] = {
    text = "Outfit name not valid.",
    button1 = "Okay",
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1
}

StaticPopupDialogs["TMOG_CONFIRM_DELETE_OUTFIT"] = {
    text = "Delete Outfit?",
    button1 = TEXT(YES),
    button2 = TEXT(NO),
    OnAccept = function()
        Tmog_DeleteOutfit()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

function Tmog_CollectedToggle()
    if Tmog.collected then
        Tmog.collected = false
    else
        Tmog.collected = true
    end
    TmogFrameCollected:SetChecked(Tmog.collected)
    if Tmog.currentSlot then
        Tmog.currentPage = 1
        Tmog:HidePreviews()
        Tmog:DrawPreviews(Tmog.currentSlot, TMOG_SEARCH_STRING)
    end
end

function Tmog_NotCollectedToggle()
    if Tmog.notCollected then
        Tmog.notCollected = false
    else
        Tmog.notCollected = true
    end
    TmogFrameNotCollected:SetChecked(Tmog.notCollected)
    if Tmog.currentSlot then
        Tmog.currentPage = 1
        Tmog:HidePreviews()
        Tmog:DrawPreviews(Tmog.currentSlot, TMOG_SEARCH_STRING)
    end
end

function TmogFrame_Toggle()
	if TmogFrame:IsVisible() then
		HideUIPanel(TmogFrame)
	else
		ShowUIPanel(TmogFrame)
	end
end

function strtrim(s)
	return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function Tmog_Search(inputText)
    if not inputText then return end
	inputText = strtrim(inputText)
	if inputText == "" then
        Tmog_SelectType(Tmog.currentType)
        return
    end
    local searchText = string.lower(inputText)
    TMOG_SEARCH_STRING = searchText
    Tmog.currentPage = 1
    Tmog:HidePreviews()
    Tmog:DrawPreviews(Tmog.currentSlot, searchText)
end

function Tmog_switchTab(which)
    if Tmog.currentTab == which then
        return
    end
    Tmog.currentTab = which
    Tmog.currentPage = 1

    if which == 'items' then
        TmogFrameItemsButton:SetNormalTexture('Interface\\TransmogFrame\\tab_active')
        TmogFrameItemsButton:SetPushedTexture('Interface\\TransmogFrame\\tab_active')

        TmogFrameOutfitsButton:SetNormalTexture('Interface\\TransmogFrame\\tab_inactive')
        TmogFrameOutfitsButton:SetPushedTexture('Interface\\TransmogFrame\\tab_inactive')

        if Tmog.currentSlot then
            TmogFrameSearchButton:Click()
            if Tmog.currentSlot ~= 15 and Tmog.currentSlot ~= 4 and Tmog.currentSlot ~= 19 then
                TmogFrameTypeDropDown:Show()
            end
            TmogFrameSearchBox:Show()
            TmogFrameSearchButton:Show()
        else
            Tmog:HidePreviews()
        end
        
        TmogFrameCollected:Show()
        TmogFrameNotCollected:Show()

    elseif which == 'outfits' then
        TmogFrameOutfitsButton:SetNormalTexture('Interface\\TransmogFrame\\tab_active')
        TmogFrameOutfitsButton:SetPushedTexture('Interface\\TransmogFrame\\tab_active')

        TmogFrameItemsButton:SetNormalTexture('Interface\\TransmogFrame\\tab_inactive')
        TmogFrameItemsButton:SetPushedTexture('Interface\\TransmogFrame\\tab_inactive')

        TmogFrameTypeDropDown:Hide()
        TmogFrameCollected:Hide()
        TmogFrameNotCollected:Hide()
        TmogFrameSearchBox:Hide()
        TmogFrameSearchButton:Hide()

        Tmog:DrawPreviews(Tmog.currentSlot)
    end
end