-- adapted from https://github.com/Zebouski/MoPGearTooltips/tree/masterturtle
local _G, _ = _G or getfenv()
local TmogTip = CreateFrame("Frame", "TmogTip", GameTooltip)
local tmog = CreateFrame("Frame")
local GAME_YELLOW = "|cffffd200"
local strfind = string.find
local tonumber = tonumber
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
TRANSMOG_GEARSLOTS = {
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
local tmog_druid = {["Cloth"]=true,["Leather"]=true,["Staff"]=true,["Mace"]=true,["Dagger"]=true,["Polearm"]=true,["Fist Weapon"]=true}
local tmog_shaman = {["Cloth"]=true,["Leather"]=true,["Mail"]=true,["Staff"]=true, ["Mace"]=true, ["Dagger"]=true,["Axe"]=true,["Fist Weapon"]=true,["Shield"]=true}
local tmog_paladin = {["Cloth"]=true, ["Leather"]=true,["Mail"]=true,["Plate"]=true,["Staff"]=true,["Mace"]=true,["Sword"]=true,["Axe"]=true,["Polearm"]=true,["Shield"]=true}
local tmog_magelock = {["Cloth"]=true,["Staff"]=true,["Sword"]=true,["Dagger"]=true,["Wand"]=true}
local tmog_priest = {["Cloth"]=true,["Staff"]=true,["Mace"]=true,["Dagger"]=true,["Wand"]=true}
local tmog_warrior = {["Cloth"]=true,["Leather"]=true,["Mail"]=true,["Plate"]=true,["Staff"]=true,["Mace"]=true,["Dagger"]=true,["Polearm"]=true,["Sword"]=true,
    ["Axe"]=true,["Fist Weapon"]=true,["Shield"]=true,["Bow"]=true}
local tmog_rogue = {["Cloth"]=true,["Leather"]=true,["Mace"]=true,["Dagger"]=true,["Sword"]=true,["Fist Weapon"]=true,["Bow"]=true}
local tmog_hunter = {["Cloth"]=true,["Leather"]=true,["Mail"]=true,["Staff"]=true,["Dagger"]=true,["Sword"]=true,["Polearm"]=true,["Fist Weapon"]=true,["Axe"]=true,["Bow"]=true}

local function tmog_print(a)
    if a == nil then
        ChatFrame2:AddMessage('Attempt to print a nil value.')
        return false
    end
    ChatFrame2:AddMessage(GAME_YELLOW .. a)
end

local function strsplit(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = strfind(str, delimiter, from, 1, true)
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = strfind(str, delimiter, from, true)
    end
    table.insert(result, string.sub(str, from))
    return result
end

function AddToSet(set, key)
    if not set or not key then return end
    set[key] = true
end

function SetContains(set, key)
    if not set or not key then return end
    return set[key] ~= nil
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


function InvenotySlotFromItemID(itemID)
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
    elseif slot == "INVTYPE_BACK" or --?
            slot == "INVTYPE_CLOAK"
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

local LastSearchName = nil
local lastSearchLink = nil
local function GetItemLinkByName(name)
	if name ~= LastSearchName then
    	for itemID = 1, 90000 do
      		local itemName, hyperLink, itemQuality = GetItemInfo(itemID)
      		if (itemName and itemName == name) then
        		local _, _, _, hex = GetItemQualityColor(tonumber(itemQuality))
        		lastSearchLink = hex.. "|H"..hyperLink.."|h["..itemName.."]|h|r"
     		end
    	end
		LastSearchName = name
  	end
	return lastSearchLink
end

local HookSetItemRef = SetItemRef
SetItemRef = function(link, text, button)
    local item = string.find(link, "item:(%d+):.*")
    ItemRefTooltip.itemLink = link
    HookSetItemRef(link, text, button)
    if not IsShiftKeyDown() and not IsControlKeyDown() and item then
        TmogTip.extendTooltip(ItemRefTooltip, "ItemRefTooltip")
    end
end

local HookSetHyperlink = GameTooltip.SetHyperlink
function GameTooltip.SetHyperlink(self, arg1)
  if arg1 then
    local _, _, linktype = string.find(arg1, "^(.-):(.+)$")
    if linktype == "item" then
      GameTooltip.itemLink = arg1
    end
  end

  return HookSetHyperlink(self, arg1)
end

local HookSetBagItem = GameTooltip.SetBagItem
function GameTooltip.SetBagItem(self, container, slot)
  GameTooltip.itemLink = GetContainerItemLink(container, slot)
  _, GameTooltip.itemCount = GetContainerItemInfo(container, slot)
  return HookSetBagItem(self, container, slot)
end

local HookSetQuestLogItem = GameTooltip.SetQuestLogItem
function GameTooltip.SetQuestLogItem(self, itemType, index)
  GameTooltip.itemLink = GetQuestLogItemLink(itemType, index)
  if not GameTooltip.itemLink then return end
  return HookSetQuestLogItem(self, itemType, index)
end

local HookSetQuestItem = GameTooltip.SetQuestItem
function GameTooltip.SetQuestItem(self, itemType, index)
  GameTooltip.itemLink = GetQuestItemLink(itemType, index)
  return HookSetQuestItem(self, itemType, index)
end

local HookSetLootItem = GameTooltip.SetLootItem
function GameTooltip.SetLootItem(self, slot)
  GameTooltip.itemLink = GetLootSlotLink(slot)
  HookSetLootItem(self, slot)
end

local HookSetInboxItem = GameTooltip.SetInboxItem
function GameTooltip.SetInboxItem(self, mailID, attachmentIndex)
  local itemName = GetInboxItem(mailID)
  GameTooltip.itemLink = GetItemLinkByName(itemName)
  return HookSetInboxItem(self, mailID, attachmentIndex)
end

local HookSetInventoryItem = GameTooltip.SetInventoryItem
function GameTooltip.SetInventoryItem(self, unit, slot)
  GameTooltip.itemLink = GetInventoryItemLink(unit, slot)
  return HookSetInventoryItem(self, unit, slot)
end

local HookSetLootRollItem = GameTooltip.SetLootRollItem
function GameTooltip.SetLootRollItem(self, id)
  GameTooltip.itemLink = GetLootRollItemLink(id)
  return HookSetLootRollItem(self, id)
end

local HookSetMerchantItem = GameTooltip.SetMerchantItem
function GameTooltip.SetMerchantItem(self, merchantIndex)
  GameTooltip.itemLink = GetMerchantItemLink(merchantIndex)
  return HookSetMerchantItem(self, merchantIndex)
end

local HookSetCraftItem = GameTooltip.SetCraftItem
function GameTooltip.SetCraftItem(self, skill, slot)
  GameTooltip.itemLink = GetCraftReagentItemLink(skill, slot)
  return HookSetCraftItem(self, skill, slot)
end

local HookSetCraftSpell = GameTooltip.SetCraftSpell
function GameTooltip.SetCraftSpell(self, slot)
  GameTooltip.itemLink = GetCraftItemLink(slot)
  return HookSetCraftSpell(self, slot)
end

local HookSetTradeSkillItem = GameTooltip.SetTradeSkillItem
function GameTooltip.SetTradeSkillItem(self, skillIndex, reagentIndex)
  if reagentIndex then
    GameTooltip.itemLink = GetTradeSkillReagentItemLink(skillIndex, reagentIndex)
  else
    GameTooltip.itemLink = GetTradeSkillItemLink(skillIndex)
  end
  return HookSetTradeSkillItem(self, skillIndex, reagentIndex)
end

local HookSetAuctionItem = GameTooltip.SetAuctionItem
function GameTooltip.SetAuctionItem(self, atype, index)
  local itemName, _, itemCount = GetAuctionItemInfo(atype, index)
  GameTooltip.itemCount = itemCount
  GameTooltip.itemLink = GetItemLinkByName(itemName)
  return HookSetAuctionItem(self, atype, index)
end

local HookSetAuctionSellItem = GameTooltip.SetAuctionSellItem
function GameTooltip.SetAuctionSellItem(self)
  local itemName, _, itemCount = GetAuctionSellItemInfo()
  GameTooltip.itemCount = itemCount
  GameTooltip.itemLink = GetItemLinkByName(itemName)
  return HookSetAuctionSellItem(self)
end

local HookSetTradePlayerItem = GameTooltip.SetTradePlayerItem
function GameTooltip.SetTradePlayerItem(self, index)
  GameTooltip.itemLink = GetTradePlayerItemLink(index)
  return HookSetTradePlayerItem(self, index)
end

local HookSetTradeTargetItem = GameTooltip.SetTradeTargetItem
function GameTooltip.SetTradeTargetItem(self, index)
  GameTooltip.itemLink = GetTradeTargetItemLink(index)
  return HookSetTradeTargetItem(self, index)
end

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

function FixName(name)
    if not name then return end
    local suffix = ""
    for k,v in pairs(suffixes) do
        if strfind(name, k, 1, true) then
            suffix = k
            break
        end
    end
    return string.gsub(name, suffix, "")
end

local TmogTooltip = getglobal("TmogTooltip") or CreateFrame("GameTooltip", "TmogTooltip", nil, "GameTooltipTemplate")
TmogTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
tmog:RegisterEvent("UNIT_INVENTORY_CHANGED")
tmog:RegisterEvent("CHAT_MSG_ADDON")
tmog:SetScript("OnEvent", function()
    if event == "CHAT_MSG_ADDON" and strfind(arg1, "TW_TRANSMOG", 1, true)then
        tmog_debug(event)
        tmog_debug(arg1)
        tmog_debug(arg2)
        tmog_debug(arg3)
        tmog_debug(arg4)
        if strfind(arg2, "AvailableTransmogs", 1, true) and arg4 == UnitName("player") then
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
        if strfind(arg2, "NewTransmog", 1, true) and arg4 == UnitName("player") then
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
    elseif event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
        tmog_debug(event)
        tmog_debug(arg1)
        for k,v in pairs(TRANSMOG_CACHE) do
            if TmogTooltip:SetInventoryItem("player", k) then
                local itemName = getglobal(TmogTooltip:GetName() .. "TextLeft1"):GetText()
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

local originalTooltip = {}
-- return true and slot if this is gear and we can equip it
function IsGear(tooltipTypeStr)
    local isGear = false
    local slot = nil
    -- collect left lines of the original tooltip into lua table
    for row = 1, 30 do
        local tooltipRowLeft = _G[tooltipTypeStr .. 'TextLeft' .. row]
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
            local _, _, classesRow = strfind(originalTooltip[row].text, "Classes: (.*)")
            if classesRow then
                if not strfind(classesRow, UnitClass("player"),1,true) then
                    tmog_debug("Bad class")
                    return false, nil
                end
            end
            -- skip recipies
            if strfind(originalTooltip[row].text, "Pattern:",1,true) or
                strfind(originalTooltip[row].text, "Plans:",1,true) or
                strfind(originalTooltip[row].text, "Schematic:",1,true) then
                tmog_debug("Recipie")
                return false, nil
            end
        end
    end
    local off_hand = false
    for row=1, table.getn(originalTooltip) do
        if originalTooltip[row].text then
            -- Gear is guaranteed to be labeled with the slot it occupies.
            for _, v in ipairs(TRANSMOG_GEARSLOTS) do
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
            local tooltipRowRight = _G[tooltipTypeStr .. 'TextRight' .. row]
            if tooltipRowRight then
                local rowtext = tooltipRowRight:GetText()
                if rowtext and not strfind(rowtext, "Speed",1,true) then
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
                    tmog_debug("off hand, not shield, bad class")
                end
                tmog_debug("Can Equip")
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
    -- get rid of suffixes
    if tooltip.itemLink then
        local _, _, itemID = string.find(tooltip.itemLink, "item:(%d+):.*")
        if itemID then
            itemName = GetItemInfo(itemID)
        end
    else
        itemName = FixName(itemName)
    end
    if not isGear or not itemName or not tLabel then return end
    if itemName == LastItemName then
        if tLabel then
            if tLabel:GetText() then
                if SetContains(TRANSMOG_CACHE[LastSlot], LastItemName) then
                    tLabel:SetText(GAME_YELLOW..'In your collection|r\n'..tLabel:GetText())
                else
                    tLabel:SetText(GAME_YELLOW..'Not collected (or not cached yet)|r\n'..tLabel:GetText())
                end
            end
        end
    else
        LastItemName = itemName
        LastSlot = slot
        -- tooltips have max 30 lines so dont just AddLine, insert into 2nd line of the tooltip instead to avoid hitting lines cap
        if tLabel then
            if tLabel:GetText() then
                if SetContains(TRANSMOG_CACHE[slot], itemName) then
                    tLabel:SetText(GAME_YELLOW..'In your collection|r\n'..tLabel:GetText())
                else
                    tLabel:SetText(GAME_YELLOW..'Not collected (or not cached yet)|r\n'..tLabel:GetText())
                end
            end
        end
    end
    tooltip:Show()
end

TmogTip:SetScript("OnHide", function()
    GameTooltip.itemLink = nil
    ItemRefTooltip.itemLink = nil
    -- clear right text otherwise it will collect bunch of random strings and mess things up
    for row=1, table.getn(originalTooltip) do
        _G["GameTooltip" .. 'TextRight' .. row]:SetText("")
    end
end)

TmogTip:SetScript("OnShow", function()
    TmogTip.extendTooltip(GameTooltip, "GameTooltip")
end)

-- adapted from http://shagu.org/ShaguTweaks/
tmog.HookAddonOrVariable = function(addon, func)
    local lurker = CreateFrame("Frame", nil)
    lurker.func = func
    lurker:RegisterEvent("ADDON_LOADED")
    lurker:RegisterEvent("VARIABLES_LOADED")
    lurker:RegisterEvent("PLAYER_ENTERING_WORLD")
    lurker:SetScript("OnEvent",function()
      if IsAddOnLoaded(addon) or _G[addon] then
        this:func()
        this:UnregisterAllEvents()
      end
    end)
end

tmog.HookAddonOrVariable("AtlasLoot", function()
    local atlas = CreateFrame("Frame", nil, AtlasLootTooltip)
    local atlas2 = CreateFrame("Frame", nil, AtlasLootTooltip2)
    atlas2:SetScript("OnHide", function()
        for row=1, 30 do
            _G["AtlasLootTooltip2" .. 'TextRight' .. row]:SetText("")
        end
    end)
    atlas:SetScript("OnHide", function()
        for row=1, 30 do
            _G["AtlasLootTooltip" .. 'TextRight' .. row]:SetText("")
        end
    end)
    atlas:SetScript("OnShow", function()
        TmogTip.extendTooltip(AtlasLootTooltip, "AtlasLootTooltip")
    end)
    atlas2:SetScript("OnShow", function()
        TmogTip.extendTooltip(AtlasLootTooltip2, "AtlasLootTooltip2")
    end)
end)
