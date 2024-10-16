local tmog = CreateFrame("Frame")
local GAME_YELLOW = "|cffffd200"
local strfind = string.find
local tonumber = tonumber
local s_debugging = false
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
-- strings from game tooltips to determine if this is a transmoggable item
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
local tmog_shaman = {["Cloth"]=true,["Leather"]=true,["Mail"]=true,["Staff"]=true, ["Mace"]=true, ["Dagger"]=true,["Axe"]=true,["Fist Weapon"]=true}
local tmog_paladin = {["Cloth"]=true, ["Leather"]=true,["Mail"]=true,["Plate"]=true,["Staff"]=true,["Mace"]=true,["Sword"]=true,["Axe"]=true,["Polearm"]=true}
local tmog_magelock = {["Cloth"]=true,["Staff"]=true,["Sword"]=true,["Dagger"]=true,["Wand"]=true}
local tmog_priest = {["Cloth"]=true,["Staff"]=true,["Mace"]=true,["Dagger"]=true,["Wand"]=true}
local tmog_warrior = {["Cloth"]=true,["Leather"]=true,["Mail"]=true,["Plate"]=true,["Staff"]=true,["Mace"]=true,["Dagger"]=true,["Polearm"]=true,["Sword"]=true,
    ["Axe"]=true,["Fist Weapon"]=true,["Shield"]=true,["Bow"]=true}
local tmog_rogue = {["Cloth"]=true,["Leather"]=true,["Mace"]=true,["Dagger"]=true,["Sword"]=true,["Fist Weapon"]=true,["Bow"]=true}
local tmog_hunter = {["Cloth"]=true,["Leather"]=true,["Mail"]=true,["Staff"]=true,["Dagger"]=true,["Sword"]=true,["Polearm"]=true,["Fist Weapon"]=true,["Axe"]=true,["Bow"]=true}

local function s_print(a)
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


local function s_debug(a)
    if s_debugging ~= true then return end
    if type(a) == 'boolean' then
        if a then
            s_print('|cff0070de[DEBUG]|cffffffff[true]')
        else
            s_print('|cff0070de[DEBUG]|cffffffff[false]')
        end
        return true
    end
    s_print('|cff0070de[DEBUG:' .. GetTime() .. ']|cffffffff[' .. a .. ']')
end


function InvenotySlotFromItemID(itemID)
    if not itemID then return end
    local name, itemstring, quality, level, class, subclass, max_stack, slot, texture = GetItemInfo(itemID)
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
    elseif slot == "INVTYPE_BACK" or
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

local function GetItemLinkByName(name)
    for itemID = 1, 90000 do
      local itemName, hyperLink, itemQuality = GetItemInfo(itemID)
      if (itemName and itemName == name) then
        local _, _, _, hex = GetItemQualityColor(tonumber(itemQuality))
        return hex.. "|H"..hyperLink.."|h["..itemName.."]|h|r"
      end
    end
  end

local HookSetItemRef = SetItemRef
SetItemRef = function(link, text, button)
    local _, _, id = string.find(link, "item:(%d+):.*")
    if id then
        ItemRefTooltip.itemLink = id
    end
    HookSetItemRef(link, text, button)
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
  local itemName, itemTexture, inboxItemCount, inboxItemQuality = GetInboxItem(mailID)
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

local TmogTooltip = getglobal("TmogTooltip") or CreateFrame("GameTooltip", "TmogTooltip", nil, "GameTooltipTemplate")
TmogTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
tmog:RegisterEvent("UNIT_INVENTORY_CHANGED")
tmog:RegisterEvent("CHAT_MSG_ADDON")
tmog:SetScript("OnEvent", function()
    if event == "CHAT_MSG_ADDON" and strfind(arg1, "TW_TRANSMOG", 1, true)then
        s_debug(event)
        s_debug(arg1)
        s_debug(arg2)
        s_debug(arg3)
        s_debug(arg4)
        if strfind(arg2, "AvailableTransmogs", 1, true) and arg4 == UnitName("player") then
            local ex = strsplit(arg2, ":")
            s_debug("ex4: [" .. ex[4] .."]")
            local InventorySlotId = tonumber(ex[2])
            for i, itemID in ex do
                if i > 3 then
                    itemID = tonumber(itemID)
                    if itemID then
                        local itemName, itemString, itemQuality, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(itemID)
                        if itemName and not SetContains(TRANSMOG_CACHE[InventorySlotId], itemName) then
                            AddToSet(TRANSMOG_CACHE[InventorySlotId], itemName)
                        end
                    end
                end
            end
            return
        end
        if strfind(arg2, "NewTransmog", 1, true) and arg4 == UnitName("player") then
            local ex = strsplit(arg2, ":")
            s_debug("id: ".. ex[2])
            local slot = InvenotySlotFromItemID(ex[2])
            local itemName, itemString, itemQuality, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(ex[2])
            if slot and itemName then
                s_debug("slot: "..slot)
                AddToSet(TRANSMOG_CACHE[slot], itemName)
            end
            return
        end
    elseif event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
        s_debug(event)
        s_debug(arg1)
        for k,v in pairs(TRANSMOG_CACHE) do
            if TmogTooltip:SetInventoryItem("player", k) then
                local itemName = getglobal(TmogTooltip:GetName() .. "TextLeft1"):GetText()
                s_debug(itemName)
                if itemName and not SetContains(TRANSMOG_CACHE[k], itemName) then
                    AddToSet(TRANSMOG_CACHE[k], itemName)
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

-- adapted from https://github.com/Zebouski/MoPGearTooltips/tree/masterturtle
local _G, _ = _G or getfenv()
local TmogTip = CreateFrame("Frame", "TmogTip", GameTooltip)

-- return true and slot if this is gear
function IsGear(tooltipTypeStr)
    local originalTooltip = {}
    local isGear = false
    local slot = nil
    for row = 1, 30 do
        local tooltipRowLeft = _G[tooltipTypeStr .. 'TextLeft' .. row]
        local tooltipRowRight = _G[tooltipTypeStr .. 'TextRight' .. row]
        if tooltipRowLeft then
            local rowtext = tooltipRowLeft:GetText()
            if rowtext then
                originalTooltip[row] = {}
                originalTooltip[row].text = rowtext
                if tooltipRowRight:GetText() then
                    originalTooltip[row].textR = tooltipRowRight:GetText()
                end
            end
        end
    end
    local _, class = UnitClass("player")
    local tableToCheck = GetTableForClass(class)
    local canEquip = false
    for row=1, table.getn(originalTooltip) do
        -- check if its class restricted item
        local classesRow = strfind(originalTooltip[row].text, "Classes:",1,true)
        if classesRow then
            local playerClass = strfind(originalTooltip[row].text, UnitClass("player"),1,true)
            if not playerClass then
                return false, nil
            end
        end
        -- skip recipies
        if strfind(originalTooltip[row].text, "Pattern:",1,true) or
            strfind(originalTooltip[row].text, "Plans:",1,true) or
            strfind(originalTooltip[row].text, "Schematic:",1,true) then
            return false, nil
        end
        -- Gear is guaranteed to be labeled with the slot it occupies.
        for _, v in ipairs(TRANSMOG_GEARSLOTS) do
            if v == originalTooltip[row].text then
                if v == "Back" then return true, 15 -- everyone can equip
                elseif v == "Held In Off-hand" then return true, 16 -- everyone can equip
                elseif v == "Head" then slot = 1
                elseif v == "Shoulder" then slot = 3
                elseif v == "Chest" then slot = 5
                elseif v == "Waist" then slot = 6
                elseif v == "Legs" then slot = 7
                elseif v == "Feet" then slot = 8
                elseif v == "Wrist" then slot = 9
                elseif v == "Hands" then slot = 10
                elseif v == "Main Hand" or v == "Two-Hand" or v == "One-Hand" then slot = 16
                elseif v == "Off Hand" then slot = 17
                elseif v == "Ranged" then slot = 18
                elseif (v == "Gun" or v == "Crossbow") and (class == "WARRIOR" or class == "ROGUE" or class == "HUNTER") then return true, 18
                elseif v == "Wand" and (class == "MAGE" or class == "WARLOCK" or class == "PRIEST") then return true, 18
                else return false, nil
                end
                isGear = true
            end
        end
        if originalTooltip[row].textR then
            if SetContains(tableToCheck, originalTooltip[row].textR) then
                canEquip = true
            end
        end
    end
    if not canEquip then return false, nil end
    return isGear, slot
end

-- cache these so that game donesnt explode
local LastItemName = nil
local LastSlot = nil
function TmogTip.extendTooltip(tooltip, tooltipTypeStr)
    local itemName = getglobal(tooltip:GetName() .. "TextLeft1"):GetText()
    local isGear, slot = IsGear(tooltipTypeStr)
    local tLabel = getglobal(tooltip:GetName() .. "TextLeft2")
    if not isGear then return end
    if itemName == LastItemName then
        if tLabel then
            if SetContains(TRANSMOG_CACHE[LastSlot], LastItemName) then
                tLabel:SetText(GAME_YELLOW..'In your collection|r\n'..tLabel:GetText())
            else
                tLabel:SetText(GAME_YELLOW..'Not collected (or not cached yet)|r\n'..tLabel:GetText())
            end
        end
    else
        LastItemName = itemName
        LastSlot = slot
        -- tooltips have max 30 lines so dont just AddLine, insert into 2nd line of the tooltip instead to avoid hitting lines cap
        if tLabel then
            if SetContains(TRANSMOG_CACHE[slot], itemName) then
                tLabel:SetText(GAME_YELLOW..'In your collection|r\n'..tLabel:GetText())
            else
                tLabel:SetText(GAME_YELLOW..'Not collected (or not cached yet)|r\n'..tLabel:GetText())
            end
        end
    end
    tooltip:Show()
end

TmogTip:SetScript("OnHide", function()
    GameTooltip.itemLink = nil
end)

TmogTip:SetScript("OnShow", function()
    if GameTooltip.itemLink then
        local _, _, itemLink = string.find(GameTooltip.itemLink, "(item:%d+:%d+:%d+:%d+)");
        if not itemLink then
            return false
        end
        TmogTip.extendTooltip(GameTooltip, "GameTooltip")
    end
end)

ItemRefTooltip:SetScript("OnHide", function()
    ItemRefTooltip.itemLink = nil
end)

ItemRefTooltip:SetScript("OnShow", function()
    if ItemRefTooltip.itemLink then
        TmogTip.extendTooltip(ItemRefTooltip, "ItemRefTooltip")
    end
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
    atlas:SetScript("OnShow", function()
        TmogTip.extendTooltip(AtlasLootTooltip, "AtlasLootTooltip")
    end)
    atlas2:SetScript("OnShow", function()
        TmogTip.extendTooltip(AtlasLootTooltip2, "AtlasLootTooltip2")
    end)
end)
