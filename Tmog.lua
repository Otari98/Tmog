-- Dressing room code - modified CosminPOP's Turtle_TransmogUI
-- Tooltip code - adapted from https://github.com/Zebouski/MoPGearTooltips/tree/masterturtle
local YELLOW = NORMAL_FONT_COLOR_CODE
local WHITE = HIGHLIGHT_FONT_COLOR_CODE
local GREEN = GREEN_FONT_COLOR_CODE
local GREY = GRAY_FONT_COLOR_CODE
local BLUE = "|cff0070de"

local tinsert = table.insert
local tremove = table.remove
local getn = table.getn
local strfind = string.find
local strlower = string.lower
local GetItemInfo = GetItemInfo

local version = GetAddOnMetadata("Tmog", "Version")
local debug = false
local _, playerClass = UnitClass("player")
local _, playerRace = UnitRace("player")

local playerModelLight   = { 1, 0, -0.3, -1, -1,   0.55, 1.0, 1.0, 1.0,   0.8, 1.0, 1.0, 1.0 }
local previewNormalLight = { 1, 0, -0.3,  0, -1,   0.65, 1.0, 1.0, 1.0,   0.8, 1.0, 1.0, 1.0 }
local previewHighlight   = { 1, 0, -0.3,  0, -1,   0.9,  1.0, 1.0, 1.0,   0.8, 1.0, 1.0, 1.0 }
local FSLight            = { 1, 0, -0.5, -1, -0.7, 0.42, 1.0, 1.0, 1.0,   0.8, 1.0, 1.0, 1.0 }

local TmogTip = CreateFrame("Frame", "TmogTip", GameTooltip)
local TmogTooltip = TmogTooltip or CreateFrame("GameTooltip", "TmogTooltip", nil, "GameTooltipTemplate")
TmogTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

local Tmog = CreateFrame("Frame")
Tmog:RegisterEvent("UNIT_INVENTORY_CHANGED")
Tmog:RegisterEvent("CHAT_MSG_ADDON")
Tmog:RegisterEvent("PLAYER_ENTERING_WORLD")
Tmog:RegisterEvent("ADDON_LOADED")

Tmog.currentGear = {}
Tmog.previewButtons = {}
Tmog.actualGear = {} -- actual gear + transmog
Tmog.sex = UnitSex("player") -- 3 - female, 2 - male
Tmog.race = strlower(playerRace)
Tmog.currentType = "Cloth"
Tmog.currentSlot = nil
Tmog.currentPage = 1
Tmog.totalPages = 1
Tmog.currentTypesList = {} -- available types for current slot
Tmog.currentOutfit = nil
Tmog.collected = true -- check box
Tmog.notCollected = true -- check box
Tmog.onlyUsable = false -- check box
Tmog.ignoreLevel = false -- check box
Tmog.canDualWeild = playerClass == "WARRIOR" or playerClass == "HUNTER" or playerClass == "ROGUE"
Tmog.currentTab = "items"
Tmog.flush = true

Tmog.typesDefault = {
    "Cloth",
    "Leather",
    "Mail",
    "Plate",
}
Tmog.typesMisc = {
    "Cloth",
    "Leather",
    "Mail",
    "Plate",
    "Miscellaneous",
}
Tmog.typesBack = {
    "Cloth",
}
Tmog.typesShirt = {
    "Miscellaneous",
}
Tmog.typesMh = {
    "Daggers",
    "One-Handed Axes",
    "One-Handed Swords",
    "One-Handed Maces",
    "Fist Weapons",
    "Polearms",
    "Staves",
    "Two-Handed Axes",
    "Two-Handed Swords",
    "Two-Handed Maces",
}
Tmog.typesOh = {
    "Daggers",
    "One-Handed Axes",
    "One-Handed Swords",
    "One-Handed Maces",
    "Fist Weapons",
    "Miscellaneous",
    "Shields",
}
Tmog.typesRanged = {
    "Bows",
    "Guns",
    "Crossbows",
    "Wands",
}
-- store last selected type for each slot
Tmog.slots = {
    [1] = "Cloth",
    [3] = "Cloth",
    [4] = "Miscellaneous",
    [5] = "Cloth",
    [6] = "Cloth",
    [7] = "Cloth",
    [8] = "Cloth",
    [9] = "Cloth",
    [10] = "Cloth",
    [15] = "Cloth",
    [16] = "Daggers",
    [17] = "Daggers",
    [18] = "Bows",
    [19] = "Miscellaneous",
}
-- these slots change type together
Tmog.linkedSlots = {
    [1] = true,
    [3] = true,
    [5] = true,
    [6] = true,
    [7] = true,
    [8] = true,
    [9] = true,
    [10] = true
}
-- store last selected page for each slot and type
Tmog.pages = {
    [1] = {
        ["Cloth"] = 1,
        ["Leather"] = 1,
        ["Mail"] = 1,
        ["Plate"] = 1,
        ["Miscellaneous"] = 1,
    },
    [3] = {
        ["Cloth"] = 1,
        ["Leather"] = 1,
        ["Mail"] = 1,
        ["Plate"] = 1,
    },
    [4] = {
        ["Miscellaneous"] = 1,
    },
    [5] = {
        ["Cloth"] = 1,
        ["Leather"] = 1,
        ["Mail"] = 1,
        ["Plate"] = 1,
        ["Miscellaneous"] = 1,
    },
    [6] = {
        ["Cloth"] = 1,
        ["Leather"] = 1,
        ["Mail"] = 1,
        ["Plate"] = 1,
    },
    [7] = {
        ["Cloth"] = 1,
        ["Leather"] = 1,
        ["Mail"] = 1,
        ["Plate"] = 1,
    },
    [8] = {
        ["Cloth"] = 1,
        ["Leather"] = 1,
        ["Mail"] = 1,
        ["Plate"] = 1,
        ["Miscellaneous"] = 1,
    },
    [9] = {
        ["Cloth"] = 1,
        ["Leather"] = 1,
        ["Mail"] = 1,
        ["Plate"] = 1,
    },
    [10] = {
        ["Cloth"] = 1,
        ["Leather"] = 1,
        ["Mail"] = 1,
        ["Plate"] = 1,
    },
    [15] = {
        ["Cloth"] = 1
    },
    [16] = {
        ["Daggers"] = 1,
        ["One-Handed Axes"] = 1,
        ["One-Handed Swords"] = 1,
        ["One-Handed Maces"] = 1,
        ["Fist Weapons"] = 1,
        ["Two-Handed Axes"] = 1,
        ["Two-Handed Swords"] = 1,
        ["Two-Handed Maces"] = 1,
        ["Polearms"] = 1,
        ["Staves"] = 1,
    },
    [17] = {
        ["Daggers"] = 1,
        ["One-Handed Axes"] = 1,
        ["One-Handed Swords"] = 1,
        ["One-Handed Maces"] = 1,
        ["Fist Weapons"] = 1,
        ["Miscellaneous"] = 1,
        ["Shields"] = 1,
    },
    [18] = {
        ["Bows"] = 1,
        ["Guns"] = 1,
        ["Crossbows"] = 1,
        ["Wands"] = 1,
    },
    [19] = {
        ["Miscellaneous"] = 1,
    },
}
-- bad items for "Ony Usable" check box
Tmog.unusable = {
    [1] = {
        ["Cloth"] = {},
        ["Leather"] = {},
        ["Mail"] = {},
        ["Plate"] = {},
        ["Miscellaneous"] = {},
        ["SearchResult"] = {},
    },
    [3] = {
        ["Cloth"] = {},
        ["Leather"] = {},
        ["Mail"] = {},
        ["Plate"] = {},
        ["SearchResult"] = {},
    },
    [4] = {
        ["Miscellaneous"] = {},
        ["SearchResult"] = {},
    },
    [5] = {
        ["Cloth"] = {},
        ["Leather"] = {},
        ["Mail"] = {},
        ["Plate"] = {},
        ["Miscellaneous"] = {},
        ["SearchResult"] = {},
    },
    [6] = {
        ["Cloth"] = {},
        ["Leather"] = {},
        ["Mail"] = {},
        ["Plate"] = {},
        ["SearchResult"] = {},
    },
    [7] = {
        ["Cloth"] = {},
        ["Leather"] = {},
        ["Mail"] = {},
        ["Plate"] = {},
        ["SearchResult"] = {},
    },
    [8] = {
        ["Cloth"] = {},
        ["Leather"] = {},
        ["Mail"] = {},
        ["Plate"] = {},
        ["Miscellaneous"] = {},
        ["SearchResult"] = {},
    },
    [9] = {
        ["Cloth"] = {},
        ["Leather"] = {},
        ["Mail"] = {},
        ["Plate"] = {},
        ["SearchResult"] = {},
    },
    [10] = {
        ["Cloth"] = {},
        ["Leather"] = {},
        ["Mail"] = {},
        ["Plate"] = {},
        ["SearchResult"] = {},
    },
    [15] = {
        ["Cloth"] = {},
        ["SearchResult"] = {},
    },
    [16] = {
        ["Daggers"] = {},
        ["One-Handed Axes"] = {},
        ["One-Handed Swords"] = {},
        ["One-Handed Maces"] = {},
        ["Fist Weapons"] = {},
        ["Two-Handed Axes"] = {},
        ["Two-Handed Swords"] = {},
        ["Two-Handed Maces"] = {},
        ["Polearms"] = {},
        ["Staves"] = {},
        ["SearchResult"] = {},
    },
    [17] = {
        ["Daggers"] = {},
        ["One-Handed Axes"] = {},
        ["One-Handed Swords"] = {},
        ["One-Handed Maces"] = {},
        ["Fist Weapons"] = {},
        ["Miscellaneous"] = {},
        ["Shields"] = {},
        ["SearchResult"] = {},
    },
    [18] = {
        ["Bows"] = {},
        ["Guns"] = {},
        ["Crossbows"] = {},
        ["Wands"] = {},
        ["SearchResult"] = {},
    },
    [19] = {
        ["Miscellaneous"] = {},
        ["SearchResult"] = {},
    },
}

Tmog.inventorySlots = {
    ["HeadSlot"] = 1,
    ["ShoulderSlot"] = 3,
    ["ChestSlot"] = 5,
    ["WaistSlot"] = 6,
    ["LegsSlot"] = 7,
    ["FeetSlot"] = 8,
    ["WristSlot"] = 9,
    ["HandsSlot"] = 10,
    ["BackSlot"] = 15,
    ["MainHandSlot"] = 16,
    ["SecondaryHandSlot"] = 17,
    ["RangedSlot"] = 18,
    ["ShirtSlot"] = 4,
    ["TabardSlot"] = 19
}

local InventoryTypeToSlot = {
    ["INVTYPE_HEAD"] = 1,
    ["INVTYPE_SHOULDER"] = 3,
    ["INVTYPE_CHEST"] = 5,
    ["INVTYPE_ROBE"] = 5,
    ["INVTYPE_WAIST"] = 6,
    ["INVTYPE_LEGS"] = 7,
    ["INVTYPE_FEET"] = 8,
    ["INVTYPE_WRIST"] = 9,
    ["INVTYPE_HAND"] = 10,
    ["INVTYPE_CLOAK"] = 15,
    ["INVTYPE_WEAPONMAINHAND"] = 16,
    ["INVTYPE_2HWEAPON"] = 16,
    ["INVTYPE_WEAPON"] = 16,
    ["INVTYPE_WEAPONOFFHAND"] = 17,
    ["INVTYPE_HOLDABLE"] = 17,
    ["INVTYPE_SHIELD"] = 17,
    ["INVTYPE_RANGED"] = 18,
    ["INVTYPE_RANGEDRIGHT"] = 18,
    ["INVTYPE_TABARD"] = 19,
    ["INVTYPE_BODY"] = 4,
    ["INVTYPE_RELIC"] = 18,
}

local druid = {
    ["Cloth"] = true,
    ["Leather"] = true,
    ["Staff"] = true,
    ["Mace"] = true,
    ["Dagger"] = true,
    ["Polearm"] = true,
    ["Fist Weapon"] = true,

    ["Daggers"] = true,
    ["One-Handed Maces"] = true,
    ["Fist Weapons"] = true,
    ["Two-Handed Maces"] = true,
    ["Polearms"] = true,
    ["Staves"] = true,
    ["Miscellaneous"] = true,
}

local shaman = {
    ["Cloth"] = true,
    ["Leather"] = true,
    ["Mail"] = true,
    ["Staff"] = true,
    ["Mace"] = true,
    ["Dagger"] = true,
    ["Axe"] = true,
    ["Fist Weapon"] = true,
    ["Shield"] = true,

    ["Daggers"] = true,
    ["One-Handed Axes"] = true,
    ["One-Handed Maces"] = true,
    ["Fist Weapons"] = true,
    ["Two-Handed Axes"] = true,
    ["Two-Handed Maces"] = true,
    ["Staves"] = true,
    ["Shields"] = true,
    ["Miscellaneous"] = true,
}

local paladin = {
    ["Cloth"] = true,
    ["Leather"] = true,
    ["Mail"] = true,
    ["Plate"] = true,
    ["Mace"] = true,
    ["Sword"] = true,
    ["Axe"] = true,
    ["Polearm"] = true,
    ["Shield"] = true,

    ["One-Handed Axes"] = true,
    ["One-Handed Swords"] = true,
    ["One-Handed Maces"] = true,
    ["Two-Handed Axes"] = true,
    ["Two-Handed Swords"] = true,
    ["Two-Handed Maces"] = true,
    ["Polearms"] = true,
    ["Shields"] = true,
    ["Miscellaneous"] = true,
}

local mage = {
    ["Cloth"] = true,
    ["Staff"] = true,
    ["Sword"] = true,
    ["Dagger"] = true,
    ["Wand"] = true,

    ["Staves"] = true,
    ["Daggers"] = true,
    ["One-Handed Swords"] = true,
    ["Wands"] = true,
    ["Miscellaneous"] = true,
}

local warlock = {
    ["Cloth"] = true,
    ["Staff"] = true,
    ["Sword"] = true,
    ["Dagger"] = true,
    ["Wand"] = true,

    ["Staves"] = true,
    ["Daggers"] = true,
    ["One-Handed Swords"] = true,
    ["Wands"] = true,
    ["Miscellaneous"] = true,
}

local priest = {
    ["Cloth"] = true,
    ["Staff"] = true,
    ["Mace"] = true,
    ["Dagger"] = true,
    ["Wand"] = true,

    ["Staves"] = true,
    ["Daggers"] = true,
    ["One-Handed Maces"] = true,
    ["Wands"] = true,
    ["Miscellaneous"] = true,
}

local warrior = {
    ["Cloth"] = true,
    ["Leather"] = true,
    ["Mail"] = true,
    ["Plate"] = true,
    ["Staff"] = true,
    ["Mace"] = true,
    ["Dagger"] = true,
    ["Polearm"] = true,
    ["Sword"] = true,
    ["Axe"] = true,
    ["Fist Weapon"] = true,
    ["Shield"] = true,
    ["Bow"] = true,

    ["Daggers"] = true,
    ["Fist Weapons"] = true,
    ["Staves"] = true,
    ["One-Handed Axes"] = true,
    ["One-Handed Swords"] = true,
    ["One-Handed Maces"] = true,
    ["Two-Handed Axes"] = true,
    ["Two-Handed Swords"] = true,
    ["Two-Handed Maces"] = true,
    ["Polearms"] = true,
    ["Shields"] = true,
    ["Bows"] = true,
    ["Guns"] = true,
    ["Crossbows"] = true,
    ["Miscellaneous"] = true,
}

local rogue = {
    ["Cloth"] = true,
    ["Leather"] = true,
    ["Mace"] = true,
    ["Dagger"] = true,
    ["Sword"] = true,
    ["Fist Weapon"] = true,
    ["Bow"] = true,
    ["Axe"] = true,

    ["Daggers"] = true,
    ["Fist Weapons"] = true,
    ["One-Handed Axes"] = true,
    ["One-Handed Swords"] = true,
    ["One-Handed Maces"] = true,
    ["Bows"] = true,
    ["Guns"] = true,
    ["Crossbows"] = true,
    ["Miscellaneous"] = true,
}

local hunter = {
    ["Cloth"] = true,
    ["Leather"] = true,
    ["Mail"] = true,
    ["Staff"] = true,
    ["Dagger"] = true,
    ["Sword"] = true,
    ["Polearm"] = true,
    ["Fist Weapon"] = true,
    ["Axe"] = true,
    ["Bow"] = true,

    ["Daggers"] = true,
    ["Fist Weapons"] = true,
    ["Staves"] = true,
    ["One-Handed Axes"] = true,
    ["One-Handed Swords"] = true,
    ["Two-Handed Axes"] = true,
    ["Two-Handed Swords"] = true,
    ["Polearms"] = true,
    ["Bows"] = true,
    ["Guns"] = true,
    ["Crossbows"] = true,
    ["Miscellaneous"] = true,
}

local function print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("["..BLUE.."Tmog|r] "..(msg or "nil"))
end

local function tmog_debug(...)
    if debug ~= true then
        return
    end
    local size = getn(arg)
    for i = 1, size do
        arg[i] = tostring(arg[i])
    end
    local msg = arg[1] or "nil"
    if size > 1 then
        for i = 2, size do
            msg = msg..", "..arg[i]
        end
    end
    local time = GREY..GetTime().."|r"
    DEFAULT_CHAT_FRAME:AddMessage("["..BLUE.."Tmog|r]["..time.."] "..msg)
end

local function strsplit(str, delimiter)
    local splitresult = {}
    local from = 1
    local delim_from, delim_to = strfind(str, delimiter, from, true)
    while delim_from do
        tinsert(splitresult, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = strfind(str, delimiter, from, true)
    end
    tinsert(splitresult, string.sub(str, from))
    return splitresult
end

local function strtrim(s)
	return (string.gsub(s or "", "^%s*(.-)%s*$", "%1"))
end

local function AddToSet(set, key, value)
    if not set or not key then
        return
    end
    if not value then
        set[key] = true
    else
        set[key] = value
    end
end

local function SetContains(set, key, value)
    if not set then
        return false
    end
    if not key and value then
        for _, v in pairs(set) do
            if v == value then
                return true
            end
        end
    end
    if key and not value then
        return set[key] ~= nil
    end
    return set[key] == value
end

local function InvenotySlotFromItemID(itemID)
    if not itemID then
        return nil
    end
    local _, _, _, _, _, _, _, slot  = GetItemInfo(itemID)
    if SetContains(InventoryTypeToSlot, slot) then
        return InventoryTypeToSlot[slot]
    end
    return nil
end

local function GetTableForClass(class)
    if class == "DRUID" then
        return druid
    elseif class == "PALADIN" then
        return paladin
    elseif class == "SHAMAN" then
        return shaman
    elseif class == "MAGE" then
        return mage
    elseif class == "WARLOCK" then
        return warlock
    elseif class == "PRIEST" then
        return priest
    elseif class == "WARRIOR" then
        return warrior
    elseif class == "ROGUE" then
        return rogue
    elseif class == "HUNTER" then
        return hunter
    end
end

local lastSearchName = nil
local lastSearchID = nil
local function GetItemIDByName(name)
    if not name then
        return nil
    end
	if name ~= lastSearchName then
    	for itemID = 1, 99999 do
      		local itemName = GetItemInfo(itemID)
      		if (itemName and itemName == name) then
        		lastSearchID = itemID
				break
     		end
    	end
		lastSearchName = name
  	end
	return lastSearchID
end

local HookSetLootRollItem       = GameTooltip.SetLootRollItem
local HookSetLootItem           = GameTooltip.SetLootItem
local HookSetMerchantItem       = GameTooltip.SetMerchantItem
local HookSetQuestLogItem       = GameTooltip.SetQuestLogItem
local HookSetQuestItem          = GameTooltip.SetQuestItem
local HookSetHyperlink          = GameTooltip.SetHyperlink
local HookSetBagItem            = GameTooltip.SetBagItem
local HookSetInboxItem          = GameTooltip.SetInboxItem
local HookSetInventoryItem      = GameTooltip.SetInventoryItem
local HookSetCraftItem          = GameTooltip.SetCraftItem
local HookSetCraftSpell         = GameTooltip.SetCraftSpell
local HookSetTradeSkillItem     = GameTooltip.SetTradeSkillItem
local HookSetAuctionItem        = GameTooltip.SetAuctionItem
local HookSetAuctionSellItem    = GameTooltip.SetAuctionSellItem
local HookSetTradePlayerItem    = GameTooltip.SetTradePlayerItem
local HookSetTradeTargetItem    = GameTooltip.SetTradeTargetItem
local HookSetItemRef            = SetItemRef

function GameTooltip.SetLootRollItem(self, id)
    local _, _, itemID = strfind(GetLootRollItemLink(id) or "", "item:(%d+)")
    GameTooltip.itemID = itemID
    return HookSetLootRollItem(self, id)
end

function GameTooltip.SetLootItem(self, slot)
    local _, _, itemID = strfind(GetLootSlotLink(slot) or "", "item:(%d+)")
    GameTooltip.itemID = itemID
    HookSetLootItem(self, slot)
end

function GameTooltip.SetMerchantItem(self, merchantIndex)
    local _, _, itemID = strfind(GetMerchantItemLink(merchantIndex) or "", "item:(%d+)")
    GameTooltip.itemID = itemID
    return HookSetMerchantItem(self, merchantIndex)
end

function GameTooltip.SetQuestLogItem(self, itemType, index)
    local _, _, itemID = strfind(GetQuestLogItemLink(itemType, index) or "", "item:(%d+)")
    GameTooltip.itemID = itemID
    if not GameTooltip.itemID then
        return
    end
    return HookSetQuestLogItem(self, itemType, index)
end

function GameTooltip.SetQuestItem(self, itemType, index)
    local _, _, itemID = strfind(GetQuestItemLink(itemType, index) or "", "item:(%d+)")
    GameTooltip.itemID = itemID
    return HookSetQuestItem(self, itemType, index)
end

function GameTooltip.SetHyperlink(self, arg1)
    local _, _, id = strfind(arg1 or "", "item:(%d+)")
    GameTooltip.itemID = id
    return HookSetHyperlink(self, arg1)
end

function GameTooltip.SetBagItem(self, container, slot)
	local _, _, id = strfind(GetContainerItemLink(container, slot) or "", "item:(%d+)")
	GameTooltip.itemID = id
    return HookSetBagItem(self, container, slot)
end

function GameTooltip.SetInboxItem(self, mailID, attachmentIndex)
	local itemName = GetInboxItem(mailID)
	GameTooltip.itemID = GetItemIDByName(itemName)
	return HookSetInboxItem(self, mailID, attachmentIndex)
end

function GameTooltip.SetInventoryItem(self, unit, slot)
	local _, _, id = strfind(GetInventoryItemLink(unit, slot) or "", "item:(%d+)")
	GameTooltip.itemID = id
	return HookSetInventoryItem(self, unit, slot)
end

function GameTooltip.SetCraftItem(self, skill, slot)
	local _, _, id = strfind(GetCraftReagentItemLink(skill, slot) or "", "item:(%d+)")
	GameTooltip.itemID = id
	return HookSetCraftItem(self, skill, slot)
end

function GameTooltip.SetCraftSpell(self, slot)
    local _, _, id = strfind(GetCraftItemLink(slot) or "", "item:(%d+)")
    GameTooltip.itemID = id
    return HookSetCraftSpell(self, slot)
end

function GameTooltip.SetTradeSkillItem(self, skillIndex, reagentIndex)
	if reagentIndex then
		local _, _, id = strfind(GetTradeSkillReagentItemLink(skillIndex, reagentIndex) or "", "item:(%d+)")
		GameTooltip.itemID = id
	else
		local _, _, id = strfind(GetTradeSkillItemLink(skillIndex) or "", "item:(%d+)")
		GameTooltip.itemID = id
	end
	return HookSetTradeSkillItem(self, skillIndex, reagentIndex)
end

function GameTooltip.SetAuctionItem(self, atype, index)
	local itemName = GetAuctionItemInfo(atype, index)
	GameTooltip.itemID = GetItemIDByName(itemName)
	return HookSetAuctionItem(self, atype, index)
end

function GameTooltip.SetAuctionSellItem(self)
	local itemName = GetAuctionSellItemInfo()
	GameTooltip.itemID = GetItemIDByName(itemName)
	return HookSetAuctionSellItem(self)
end

function GameTooltip.SetTradePlayerItem(self, index)
	local _, _, id = strfind(GetTradePlayerItemLink(index) or "", "item:(%d+)")
	GameTooltip.itemID = id
	return HookSetTradePlayerItem(self, index)
end

function GameTooltip.SetTradeTargetItem(self, index)
    local _, _, id = strfind(GetTradeTargetItemLink(index) or "", "item:(%d+)")
    GameTooltip.itemID = id
	return HookSetTradeTargetItem(self, index)
end

function SetItemRef(link, text, button)
    local item, _, id = strfind(link or "", "item:(%d+)")
	ItemRefTooltip.itemID = id
    HookSetItemRef(link, text, button)
    if not IsShiftKeyDown() and not IsControlKeyDown() and item then
        TmogTip.ExtendTooltip(ItemRefTooltip)
    end
end

local firstLoad = true
Tmog:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        TmogFramePlayerModel:SetUnit("player")

        if firstLoad then
            Tmog_Reset()
            firstLoad = false
        end

        if TmogFrame:IsVisible() then
            TmogFrame:Hide()
        end

        return
    end

    if event == "ADDON_LOADED" and arg1 == "Tmog" then
        Tmog:UnregisterEvent("ADDON_LOADED")

        TmogFrameTitleText:SetText("Tmog v."..version)

        -- Saved Variables
        TMOG_CACHE = TMOG_CACHE or {
            [1] = {},  -- HeadSlot
            [3] = {},  -- ShoulderSlot
            [5] = {},  -- ChestSlot
            [6] = {},  -- WaistSlot
            [7] = {},  -- LegsSlot
            [8] = {},  -- FeetSlot
            [9] = {},  -- WristSlot
            [10] = {}, -- HandsSlot
            [15] = {}, -- BackSlot
            [16] = {}, -- MainHandSlot
            [17] = {}, -- SecondaryHandSlot
            [18] = {}  -- RangedSlot
        }
        for _, InventorySlotId in pairs(Tmog.inventorySlots) do
            if InventorySlotId ~= 4 and InventorySlotId ~= 19 then
                if not TMOG_CACHE[InventorySlotId] then
                    TMOG_CACHE[InventorySlotId] = {}
                end
            end
        end
        TMOG_PLAYER_OUTFITS = TMOG_PLAYER_OUTFITS or {}
        TMOG_TRANSMOG_STATUS = TMOG_TRANSMOG_STATUS or {}
        TMOG_POSITION = TMOG_POSITION or { 760, 600 }
        TMOG_LOCKED = TMOG_LOCKED or false

        UIDropDownMenu_Initialize(TmogFrameTypeDropDown, Tmog_TypeDropDown_Initialize)
        UIDropDownMenu_Initialize(TmogFrameOutfitsDropDown, Tmog_OutfitsDropDown_Initialize)
        UIDropDownMenu_SetWidth(100, TmogFrameTypeDropDown)
        UIDropDownMenu_SetWidth(115, TmogFrameOutfitsDropDown)

        TmogButton:SetMovable(not TMOG_LOCKED)
        TmogButton:ClearAllPoints()
        TmogButton:SetPoint("CENTER", UIParent, "BOTTOMLEFT", unpack(TMOG_POSITION or {TmogButton:GetCenter()}))

        return
    end

    if debug and event == "CHAT_MSG_ADDON" and (strfind(arg1, "TW_TRANSMOG", 1, true) or strfind(arg1, "TW_CHAT_MSG_WHISPER", 1, true)) then
        tmog_debug(arg1, arg2, arg3, arg4)
    end

    if event == "CHAT_MSG_ADDON" and strfind(arg1, "TW_TRANSMOG", 1, true) and arg4 == UnitName("player") then
        if strfind(arg2, "AvailableTransmogs", 1, true) then
            local data = strsplit(arg2, ":")
            local InventorySlotId = tonumber(data[2])

            for i, itemID in pairs(data) do
                if i > 3 then
                    itemID = tonumber(itemID)

                    if itemID then
                        local itemName = GetItemInfo(itemID)

                        if itemName then
                            if not SetContains(TMOG_CACHE[InventorySlotId], itemID, itemName) then
                                AddToSet(TMOG_CACHE[InventorySlotId], itemID, itemName)
                            end

                            -- check if it shares appearance with other items and add those if it does
                            if SetContains(DisplayIdDB, itemID) then
                                for _, id in pairs(DisplayIdDB[itemID]) do
                                    Tmog:CacheItem(id)
                                    local name = GetItemInfo(id)
                                    if not SetContains(TMOG_CACHE[InventorySlotId], id, name) then
                                        AddToSet(TMOG_CACHE[InventorySlotId], id, name)
                                    end
                                end
                            end
                        end
                    end
                end
            end

        elseif strfind(arg2, "NewTransmog", 1, true) then
            local _, _, itemID = strfind(arg2, "NewTransmog:(%d+)")
            itemID = tonumber(itemID)
            local slot = InvenotySlotFromItemID(itemID)
            local itemName = GetItemInfo(itemID)

            if slot and itemName then
                AddToSet(TMOG_CACHE[slot], itemID, itemName)

                -- check if it shares appearance with other items and add those if it does
                if SetContains(DisplayIdDB, itemID, itemName) then
                    for _, id in pairs(DisplayIdDB[itemID]) do
                        Tmog:CacheItem(id)
                        local name = GetItemInfo(id)
                        if not SetContains(TMOG_CACHE[slot], id, name) then
                            AddToSet(TMOG_CACHE[slot], id, name)
                        end
                    end
                end
            end

        elseif strfind(arg2, "TransmogStatus", 1, true) then
            local data = string.gsub(arg2, "TransmogStatus:", "")

            if data then
                local TransmogStatus = strsplit(data, ",")

                if not TMOG_TRANSMOG_STATUS then
                    TMOG_TRANSMOG_STATUS = {}
                end

                for _, InventorySlotId in pairs(Tmog.inventorySlots) do
                    if not TMOG_TRANSMOG_STATUS[InventorySlotId] then
                        TMOG_TRANSMOG_STATUS[InventorySlotId] = {}
                    end
                end

                for _, d in pairs(TransmogStatus) do
                    local _, _, InventorySlotId, itemID = strfind(d, "(%d+):(%d+)")
                    InventorySlotId = tonumber(InventorySlotId)
                    if InventorySlotId and InventorySlotId ~= 0 then
                        itemID = tonumber(itemID)
                        local link = GetInventoryItemLink("player", InventorySlotId)
                        local actualItemId = Tmog:IDFromLink(link) or 0

                        if actualItemId ~= 0 then
                            if not TMOG_TRANSMOG_STATUS[InventorySlotId][actualItemId] then
                                TMOG_TRANSMOG_STATUS[InventorySlotId][actualItemId] = 0
                            end
                            TMOG_TRANSMOG_STATUS[InventorySlotId][actualItemId] = itemID
                        end
                    end
                end
            end
        end

        return
    end

    if event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
        for slot in pairs(TMOG_CACHE) do
            local link = GetInventoryItemLink("player", slot)

            if link then
                local itemID = Tmog:IDFromLink(link)

                if itemID then
                    Tmog:CacheItem(itemID)
                    local itemName = GetItemInfo(itemID)

                    if not SetContains(TMOG_CACHE[slot], itemID, itemName) then
                        AddToSet(TMOG_CACHE[slot], itemID, itemName)
                    end

                    -- check if it shares appearance with other items and add those if it does
                    if SetContains(DisplayIdDB, itemID) then
                        for _, id in pairs(DisplayIdDB[itemID]) do
                            Tmog:CacheItem(id)
                            local name = GetItemInfo(id)
                            if not SetContains(TMOG_CACHE[slot], id, name) then
                                AddToSet(TMOG_CACHE[slot], id, name)
                            end
                        end
                    end
                end
            end
        end

        return
    end
end)

local originalTooltip = {}
-- return slot if this is gear and we can equip it
local function IsGear(itemID, tooltip)
    local itemName, itemLink, itemQuality, itemLevel, itemType, itemSubType, itemCount, itemEquipLoc, itemTexture = GetItemInfo(itemID)
    local tableToCheck = GetTableForClass(playerClass)
    tmog_debug(itemID, itemName, itemType, itemSubType, itemEquipLoc)
    if SetContains(tableToCheck, itemSubType) and SetContains(InventoryTypeToSlot, itemEquipLoc) then
        if not Tmog.canDualWeild and itemEquipLoc == "INVTYPE_WEAPONOFFHAND" then
            tmog_debug("cant dual weild")
            return nil
        end
        if itemType == "Weapon" and itemSubType == "Miscellaneous" then
            tmog_debug("not a real weapon")
            return nil
        end
        if itemEquipLoc == "INVTYPE_BODY" or itemEquipLoc == "INVTYPE_TABARD" then
            tmog_debug("shirt or tabard")
            return nil
        end
        -- check if its class restricted item
        for k in pairs(originalTooltip) do
            originalTooltip[k] = nil
        end
        local tooltipName = tooltip:GetName()
        for row = 1, 15 do
            local tooltipRowLeft = getglobal(tooltipName .. "TextLeft" .. row)
            if tooltipRowLeft then
                local rowtext = tooltipRowLeft:GetText()
                if rowtext then
                    originalTooltip[row] = rowtext
                end
            end
        end
        for row = 1, Tmog:tableSize(originalTooltip) do
            if originalTooltip[row] then
                local _, _, classesRow = strfind(originalTooltip[row], "Classes: (.*)")
                if classesRow then
                    if not strfind(classesRow, UnitClass("player"), 1, true) then
                        tmog_debug("bad class")
                        return nil
                    end
                end
            end
        end
        return InventoryTypeToSlot[itemEquipLoc]
    end
end

local LastItemName = nil
local LastSlot = nil
function TmogTip.ExtendTooltip(tooltip)
    local tooltipName = tooltip:GetName()
    local itemName = getglobal(tooltipName .. "TextLeft1"):GetText()
    local line2 = getglobal(tooltipName .. "TextLeft2")

    if not itemName or not tooltip.itemID or not line2 or IsShiftKeyDown() then
        return
    end

    local itemID = tonumber(tooltip.itemID)
    Tmog:CacheItem(itemID)
    itemName = GetItemInfo(itemID)

    if itemName ~= LastItemName then
        local slot = IsGear(itemID, tooltip)
        LastItemName = itemName
        LastSlot = slot

        if not slot then
            return
        end

        if line2:GetText() then
            if SetContains(TMOG_CACHE[slot], itemID, itemName) then
                line2:SetText(GREY.."In your collection|r\n"..line2:GetText())
            else
                line2:SetText(YELLOW.."Not collected|r\n"..line2:GetText())
            end
        end
    elseif LastSlot then
        if line2:GetText() then
            -- tooltips have max 30 lines so dont just AddLine, insert into 2nd line of the tooltip instead to avoid hitting lines cap
            if SetContains(TMOG_CACHE[LastSlot], itemID, LastItemName) then
                line2:SetText(GREY.."In your collection|r\n"..line2:GetText())
            else
                line2:SetText(YELLOW.."Not collected|r\n"..line2:GetText())
            end
        end
    end

    tooltip:Show()
end

ItemRefTooltip:SetScript("OnHide", function()
    ItemRefTooltip.itemID = nil
end)

TmogTip:SetScript("OnHide", function()
    GameTooltip.itemID = nil
end)

TmogTip:SetScript("OnShow", function()
    if aux_frame and aux_frame:IsVisible() then
        if GetMouseFocus():GetParent() then
            if GetMouseFocus():GetParent().row then
                if GetMouseFocus():GetParent().row.record.item_id then
                    GameTooltip.itemID = GetMouseFocus():GetParent().row.record.item_id
                end
            end
        end
    end
    TmogTip.ExtendTooltip(GameTooltip)
end)

TmogTooltip:SetScript("OnHide", function()
    TmogTooltip.itemID = nil
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

    atlas:SetScript("OnShow", function()
        if GetMouseFocus().dressingroomID and GetMouseFocus().dressingroomID ~= 0 and
                strsub(GetMouseFocus().itemID or "", 1, 1) ~= "s" and strsub(GetMouseFocus().itemID or "", 1, 1) ~= "e" then
            AtlasLootTooltip.itemID = GetMouseFocus().dressingroomID
        end
        TmogTip.ExtendTooltip(AtlasLootTooltip)
    end)

    atlas2:SetScript("OnShow", function()
        if GetMouseFocus().dressingroomID and GetMouseFocus().dressingroomID ~= 0 and
                strsub(GetMouseFocus().itemID or "", 1, 1) ~= "s" and strsub(GetMouseFocus().itemID or "", 1, 1) ~= "e" then
            AtlasLootTooltip2.itemID = GetMouseFocus().dressingroomID
        end
        TmogTip.ExtendTooltip(AtlasLootTooltip2)
    end)

    atlas:SetScript("OnHide", function()
        AtlasLootTooltip.itemID = nil
    end)
    
    atlas2:SetScript("OnHide", function()
        AtlasLootTooltip2.itemID = nil
    end)
end)

-------------------------------
------- ITEM BROWSER ----------
-------------------------------
function TmogFrame_OnLoad()
    this:RegisterForDrag("LeftButton")

    TmogFrameRaceBackground:SetTexture("Interface\\AddOns\\Tmog\\Textures\\transmogbackground"..Tmog.race)

    TmogFrameSaveOutfit:Disable()
    TmogFrameDeleteOutfit:Disable()

    UIDropDownMenu_SetText("Outfits", TmogFrameOutfitsDropDown)

    TmogFrameCollected:SetChecked(Tmog.collected)
    TmogFrameNotCollected:SetChecked(Tmog.notCollected)
    TmogFrameUsable:SetChecked(Tmog.onlyUsable)

    tinsert(UISpecialFrames, "TmogFrame")
end

local cacheZ, cacheX, cacheY = 0, 0, 0
local showingHelm = 1
local showingCloak = 1
function TmogFrame_OnShow()
    showingHelm = ShowingHelm()
    showingCloak = ShowingCloak()

    TmogFramePlayerModel:SetPosition(cacheZ, cacheX, cacheY)
    TmogFramePlayerModel:Undress()

    for slot, itemID in pairs(Tmog.currentGear) do
        if slot ~= 18 and slot ~= 17 and slot ~= 16 then
            if (slot == 1 and showingHelm == 1) or
                (slot == 15 and showingCloak == 1) or
                (slot ~= 1 and slot ~= 15)
                then
                TmogFramePlayerModel:TryOn(itemID)
            end
        end
    end
    TmogFramePlayerModel:TryOn(Tmog.currentGear[18])
    TmogFramePlayerModel:TryOn(Tmog.currentGear[16])
    TmogFramePlayerModel:TryOn(Tmog.currentGear[17])

    Tmog:DrawPreviews()
    PlaySound("igCharacterInfoOpen")
end

function TmogFrame_OnHide()
    cacheZ, cacheX, cacheY = TmogFramePlayerModel:GetPosition()
    TmogFramePlayerModel:SetPosition(0,0,0)
    PlaySound("igCharacterInfoClose")
end

function Tmog_ResetPosition()
    TmogFramePlayerModel:SetPosition(0,0,0)
    TmogFramePlayerModel:SetFacing(0.3)
    cacheZ, cacheX, cacheY = TmogFramePlayerModel:GetPosition()
end

function TmogModel_OnLoad()
    TmogFramePlayerModel:SetFacing(0.3)
    cacheZ, cacheX, cacheY = TmogFramePlayerModel:GetPosition()
    TmogFramePlayerModel:SetLight(unpack(playerModelLight))

    TmogFramePlayerModel:SetScript("OnMouseUp", function()
        cacheZ, cacheX, cacheY = TmogFramePlayerModel:GetPosition()
        TmogFramePlayerModel:SetScript("OnUpdate", nil)
    end)

    TmogFramePlayerModel:SetScript("OnMouseWheel", function()
        local Z, X, Y = TmogFramePlayerModel:GetPosition()
        Z = (arg1 > 0 and Z + 1 or Z - 1)
        TmogFramePlayerModel:SetPosition(Z, X, Y)
        cacheZ = Z
    end)

    TmogFramePlayerModel:SetScript("OnMouseDown", function()
        local StartX, StartY = GetCursorPosition()
        local EndX, EndY, Z, X, Y

        if arg1 == "LeftButton" then
            TmogFramePlayerModel:SetScript("OnUpdate", function()
                EndX, EndY = GetCursorPosition()
                TmogFramePlayerModel:SetFacing((EndX - StartX) / 34 + TmogFramePlayerModel:GetFacing())
                StartX, StartY = GetCursorPosition()
            end)

        elseif arg1 == "RightButton" then
            TmogFramePlayerModel:SetScript("OnUpdate", function()
                EndX, EndY = GetCursorPosition()

                Z, X, Y = TmogFramePlayerModel:GetPosition()
                X = (EndX - StartX) / 45 + X
                Y = (EndY - StartY) / 45 + Y

                TmogFramePlayerModel:SetPosition(Z, X, Y)
                StartX, StartY = GetCursorPosition()
            end)
        end

        TmogFrameSearchBox:ClearFocus()
        DropDownList1:Hide()
    end)
end

function Tmog_Reset()
    Tmog.currentOutfit = nil
    TmogFrameSaveOutfit:Disable()
    TmogFrameDeleteOutfit:Disable()
    TmogFrameShareOutfit:Disable()
    UIDropDownMenu_SetText("Outfits", TmogFrameOutfitsDropDown)

    TmogFramePlayerModel:SetPosition(0, 0, 0)
    TmogFramePlayerModel:Dress()
    TmogFramePlayerModel:SetPosition(cacheZ, cacheX, cacheY)
    -- Fix tabard
    local tabardLink = GetInventoryItemLink("player",19)
    if tabardLink then
        TmogFramePlayerModel:TryOn(Tmog:IDFromLink(tabardLink))
    end

    for _, InventorySlotId in pairs(Tmog.inventorySlots) do
        Tmog.actualGear[InventorySlotId] = 0
    end

    for _, InventorySlotId in pairs(Tmog.inventorySlots) do
        Tmog.currentGear[InventorySlotId] = 0
    end

    for _, InventorySlotId in pairs(Tmog.inventorySlots) do
        local link = GetInventoryItemLink("player", InventorySlotId)
        Tmog.actualGear[InventorySlotId] = Tmog:IDFromLink(link) or 0
    end

    for slot in pairs(TMOG_TRANSMOG_STATUS) do
        local link = GetInventoryItemLink("player", slot)
        local id = Tmog:IDFromLink(link) or 0

        for actualItemID, transmogID in pairs(TMOG_TRANSMOG_STATUS[slot]) do
            if actualItemID == id then
                Tmog.actualGear[slot] = transmogID
            end
        end
    end

    for _, InventorySlotId in pairs(Tmog.inventorySlots) do
        Tmog.currentGear[InventorySlotId] = Tmog.actualGear[InventorySlotId]
    end

    Tmog:UpdateItemTextures()
    Tmog:RemoveSelection()
end

function Tmog_SelectType(typeStr)
    if TmogFrameSharedItems:IsVisible() then
        TmogFrameSharedItems:Hide()
    end
    UIDropDownMenu_SetText(typeStr, TmogFrameTypeDropDown)
    Tmog.currentType = typeStr
    Tmog.currentPage = 1
    Tmog.flush = true
    if Tmog.currentSlot and Tmog.currentType and Tmog.pages[Tmog.currentSlot][Tmog.currentType] then
        Tmog.slots[Tmog.currentSlot] = typeStr
        if SetContains(Tmog.linkedSlots, Tmog.currentSlot) then
            for k in Tmog.slots do
                if SetContains(Tmog.linkedSlots, k) and SetContains(Tmog.pages[k], typeStr) then
                    Tmog.slots[k] = typeStr
                end
            end
        end
        Tmog_ChangePage(Tmog.pages[Tmog.currentSlot][Tmog.currentType] - 1)
        return
    end

    Tmog:DrawPreviews()
end

function Tmog:HidePreviews()
    for index in pairs(Tmog.previewButtons) do
        getglobal("TmogFramePreview" .. index .. "ItemModel"):SetAlpha(0)
        getglobal("TmogFramePreview" .. index .. "Button"):Hide()
        getglobal("TmogFramePreview" .. index .. "ButtonCheck"):Hide()
    end
end

local function IsRed(tooltipLine)
    local r, g, b = getglobal(tooltipLine):GetTextColor()
    if r > 0.9 and g < 0.2 and b < 0.2 then
        return true
    end
    return false
end

local TmogScanTooltip = TmogScanTooltip or CreateFrame("GameTooltip", "TmogScanTooltip", nil, "GameTooltipTemplate")
TmogScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

function Tmog:IsUsableItem(id)
    if SetContains(Tmog.unusable[Tmog.currentSlot][Tmog.currentType], id) then
        return false
    end
    local isUsable = true
	for i = 2, 15 do
		getglobal("TmogScanTooltipTextLeft"..i):SetTextColor(0,0,0)
		getglobal("TmogScanTooltipTextRight"..i):SetTextColor(0,0,0)
	end
    TmogScanTooltip:ClearLines()
    TmogScanTooltip:SetHyperlink("item:"..id)
    for i = 2, 15 do
        local text = getglobal("TmogScanTooltipTextLeft"..i):GetText() or ""
        if (IsRed("TmogScanTooltipTextLeft"..i) or IsRed("TmogScanTooltipTextRight"..i)) then
            if strfind(text, "^Requires Level") then
                if not Tmog.ignoreLevel then
                    isUsable = false
                    Tmog.unusable[Tmog.currentSlot][Tmog.currentType][id] = true
                end
            else
                isUsable = false
                Tmog.unusable[Tmog.currentSlot][Tmog.currentType][id] = true
            end
        end
    end
    local _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(id)
    if not Tmog.canDualWeild and (itemEquipLoc == "INVTYPE_WEAPONOFFHAND" or (itemEquipLoc == "INVTYPE_WEAPON" and Tmog.currentSlot == 17)) then
        isUsable = false
        Tmog.unusable[Tmog.currentSlot][Tmog.currentType][id] = true
    end
    return isUsable
end

local drawTable = {
    [1] = {
        ["Cloth"] = {},
        ["Leather"] = {},
        ["Mail"] = {},
        ["Plate"] = {},
        ["Miscellaneous"] = {},
        ["SearchResult"] = {},
    },
    [3] = {
        ["Cloth"] = {},
        ["Leather"] = {},
        ["Mail"] = {},
        ["Plate"] = {},
        ["SearchResult"] = {},
    },
    [4] = {
        ["Miscellaneous"] = {},
        ["SearchResult"] = {},
    },
    [5] = {
        ["Cloth"] = {},
        ["Leather"] = {},
        ["Mail"] = {},
        ["Plate"] = {},
        ["Miscellaneous"] = {},
        ["SearchResult"] = {},
    },
    [6] = {
        ["Cloth"] = {},
        ["Leather"] = {},
        ["Mail"] = {},
        ["Plate"] = {},
        ["SearchResult"] = {},
    },
    [7] = {
        ["Cloth"] = {},
        ["Leather"] = {},
        ["Mail"] = {},
        ["Plate"] = {},
        ["SearchResult"] = {},
    },
    [8] = {
        ["Cloth"] = {},
        ["Leather"] = {},
        ["Mail"] = {},
        ["Plate"] = {},
        ["Miscellaneous"] = {},
        ["SearchResult"] = {},
    },
    [9] = {
        ["Cloth"] = {},
        ["Leather"] = {},
        ["Mail"] = {},
        ["Plate"] = {},
        ["SearchResult"] = {},
    }, 
    [10] = {
        ["Cloth"] = {},
        ["Leather"] = {},
        ["Mail"] = {},
        ["Plate"] = {},
        ["SearchResult"] = {},
    },
    [15] = {
        ["Cloth"] = {},
        ["SearchResult"] = {},
    },
    [16] = {
        ["Daggers"] = {},
        ["One-Handed Axes"] = {},
        ["One-Handed Swords"] = {},
        ["One-Handed Maces"] = {},
        ["Fist Weapons"] = {},
        ["Two-Handed Axes"] = {},
        ["Two-Handed Swords"] = {},
        ["Two-Handed Maces"] = {},
        ["Polearms"] = {},
        ["Staves"] = {},
        ["SearchResult"] = {},
    },
    [17] = {
        ["Daggers"] = {},
        ["One-Handed Axes"] = {},
        ["One-Handed Swords"] = {},
        ["One-Handed Maces"] = {},
        ["Fist Weapons"] = {},
        ["Miscellaneous"] = {},
        ["Shields"] = {},
        ["SearchResult"] = {},
    },
    [18] = {
        ["Bows"] = {},
        ["Guns"] = {},
        ["Crossbows"] = {},
        ["Wands"] = {},
        ["SearchResult"] = {},
    },
    [19] = {
        ["Miscellaneous"] = {},
        ["SearchResult"] = {},
    },
}

local sorted = {}
function Tmog:DrawPreviews(noDraw)
    local searchStr = TmogFrameSearchBox:GetText() or ""
    searchStr = strlower(searchStr)
    searchStr = strtrim(searchStr)

    local slot = Tmog.currentSlot
    local type = Tmog.currentType
    local race = Tmog.race
    local sex = Tmog.sex
    local index = 0
    local row = 0
    local col = 0
    local itemIndex = 1
    local outfitIndex = 1
    local ipp = 15 -- items per page

    if Tmog.currentTab == "items" then
        if (not Tmog.collected and not Tmog.notCollected) or not slot then
            Tmog:HidePreviews()
            Tmog:HidePagination()
            Tmog.currentPage = 1
            return
        end

        if searchStr ~= "" then
            type = "SearchResult"
        end
        if Tmog.flush then
            tmog_debug("flushing", "slot "..slot, " type "..type)
            for k in pairs(drawTable[slot][type]) do
                drawTable[slot][type][k] = nil
            end

            -- only Collected checked
            if Tmog.collected and not Tmog.notCollected then
                if searchStr ~= "" then
                    for k in pairs(TmogGearDB[slot]) do
                        for itemID, itemName in pairs(TmogGearDB[slot][k]) do
                            if SetContains(TMOG_CACHE[slot], itemID) then
                                local name = strlower(itemName)
                                if strfind(name, searchStr, 1 ,true) then
                                    drawTable[slot][type][itemID] = itemName
                                end
                            end
                        end
                    end
                elseif TmogGearDB[slot][type] then
                    for itemID, name in pairs(TmogGearDB[slot][type]) do
                        if SetContains(TMOG_CACHE[slot], itemID) then
                            drawTable[slot][type][itemID] = name
                        end
                    end
                end
            -- only Not Collected checked
            elseif Tmog.notCollected and not Tmog.collected then
                if searchStr ~= "" then
                    for k in pairs(TmogGearDB[slot]) do
                        for itemID, itemName in pairs(TmogGearDB[slot][k]) do
                            if not SetContains(TMOG_CACHE[slot], itemID) then
                                local name = strlower(itemName)
                                if strfind(name, searchStr, 1 ,true) then
                                    drawTable[slot][type][itemID] = itemName
                                end
                            end
                        end
                    end
                elseif TmogGearDB[slot][type] then
                    for itemID, name in pairs(TmogGearDB[slot][type]) do
                        if not SetContains(TMOG_CACHE[slot], itemID) then
                            drawTable[slot][type][itemID] = name
                        end
                    end
                end
            -- both checked
            elseif Tmog.collected and Tmog.notCollected then
                if searchStr ~= "" then
                    for k in pairs(TmogGearDB[slot]) do
                        for itemID, itemName in pairs(TmogGearDB[slot][k]) do
                            local name = strlower(itemName)
                            if strfind(name, searchStr, 1 ,true) then
                                drawTable[slot][type][itemID] = itemName
                            end
                        end
                    end
                elseif TmogGearDB[slot][type] then
                    for itemID, name in pairs(TmogGearDB[slot][type]) do
                        drawTable[slot][type][itemID] = name 
                    end
                end
            end
            -- remove no longer existing items 
            for k in pairs(drawTable[slot][type]) do
                Tmog:CacheItem(k)
                if not GetItemInfo(k) then
                    drawTable[slot][type][k] = nil
                end
            end
            -- if usable checked, remove unusable items
            if Tmog.onlyUsable then
                for k in pairs(drawTable[slot][type]) do
                    if not Tmog:IsUsableItem(k) then
                        drawTable[slot][type][k] = nil
                    end
                end
            end
            -- remove duplicates
            if searchStr == "" and type ~= "SearchResult" then
                for k1 in pairs(drawTable[slot][type]) do
                    if SetContains(DisplayIdDB, k1) then
                        for _, v in pairs(DisplayIdDB[k1]) do
                            if drawTable[slot][type][v] then
                                drawTable[slot][type][v] = nil
                            end
                        end
                    end
                end
            end
            Tmog.totalPages = Tmog:ceil(Tmog:tableSize(drawTable[slot][type]) / ipp)
            sorted = Tmog:Sort(drawTable[slot][type])
        end

        -- nothing to show
        if not drawTable[slot][type] or next(drawTable[slot][type]) == nil then
            Tmog:HidePreviews()
            Tmog:HidePagination()
            Tmog.currentPage = 1
            return
        end

        if noDraw then
            Tmog.flush = false
            return
        end

        if Tmog.currentPage == Tmog.totalPages then
            Tmog:HidePreviews()
        end

        local frame, button

        for i = 1, Tmog:tableSize(sorted) do
            local itemID = sorted[i][1]
            local name = sorted[i][2]
            local quality = sorted[i][3]

            if index >= (Tmog.currentPage - 1) * ipp and index < Tmog.currentPage * ipp then
                if not Tmog.previewButtons[itemIndex] then
                    Tmog.previewButtons[itemIndex] = CreateFrame("Frame", "TmogFramePreview" .. itemIndex, TmogFrame, "TmogFramePreviewTemplate")
                end
                frame = Tmog.previewButtons[itemIndex]
                frame:Show()
                frame:SetPoint("TOPLEFT", TmogFrame, "TOPLEFT", 263 + col * 90, -105 - 120 * row)
                frame.name = name
                frame.id = itemID

                button = getglobal("TmogFramePreview"..itemIndex.."Button")
                button:Show()
                button:SetID(itemID)
                
                Tmog:CacheItem(itemID)
                if SetContains(TMOG_CACHE[slot], itemID) then
                    getglobal("TmogFramePreview" .. itemIndex .. "ButtonCheck"):Show()
                else
                    getglobal("TmogFramePreview" .. itemIndex .. "ButtonCheck"):Hide()
                end

                if itemID == Tmog.currentGear[slot] then
                    button:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_selected")
                else
                    button:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_normal")
                end
                
                if quality then
                    local border = getglobal("TmogFramePreview" .. itemIndex .. "ButtonBorder")
                    local r, g, b, color = GetItemQualityColor(quality)
                    Tmog_AddItemTooltip(button, color .. name)
                    border:SetVertexColor(r, g, b)
                    border:SetAlpha(0.4)
                    if quality == 2 then
                        border:SetAlpha(0.2)
                    elseif quality == 0 then
                        border:SetAlpha(0.1)
                    end
                else
                    Tmog_AddItemTooltip(button, name)
                end

                -- this is for updating tooltip while scrolling with mousewheel
                if MouseIsOver(button) then
                    button:Hide()
                    button:Show()
                end

                local model = getglobal("TmogFramePreview" .. itemIndex .. "ItemModel")
                local Z, X, Y = model:GetPosition()
                model:SetUnit("player")
                model:Undress()
                model:SetFacing(0.61)

                if race == "nightelf" then
                    Z = Z + 3
                end
                if race == "bloodelf" and sex == 2 then
                    Z = Z + 3
                end
                if race == "gnome" then
                    Z = Z - 3
                    Y = Y + 1.5
                end
                if race == "dwarf" then
                    Y = Y + 1
                    Z = Z - 1
                end
                if race == "troll" then
                    Z = Z + 2
                end
                if race == "goblin" then
                    Z = Z - 0.5
                end
                -- head
                if slot == 1 then
                    if race == "tauren" then
                        Z = Z + 2
                        X = X - 0.5
                        if sex == 2 then
                            model:SetFacing(0.3)
                        else
                            Y = Y + 0.5
                        end
                    end
                    if race == "troll" then
                        if sex == 2 then
                            model:SetFacing(0.3)
                            X = X - 0.5
                            Z = Z + 2
                        else
                            Y = Y - 0.8
                            Z = Z + 2.3
                        end
                    end
                    if race == "orc" then
                        if sex == 2 then
                            model:SetFacing(0.2)
                        else
                            model:SetFacing(0.6)
                            Z = Z + 0.3
                        end
                        Z = Z + 2
                        Y = Y - 0.5
                    end
                    if race == "goblin"  then
                        Y = Y + 1.5
                    end
                    if race == "dwarf" then
                        Z = Z + 0.5
                        if sex == 3 then
                            Y = Y - 0.5
                        end
                    end
                    if race == "nightelf" then
                        Z = Z + 2
                        Y = Y - 1
                        if sex == 2 then
                            Y = Y - 0.5
                        end
                    end
                    if race == "bloodelf" then
                        if sex == 2 then
                            Z = Z + 1
                            Y = Y - 1.2
                        else
                            Z = Z + 2
                            X = X + 0.2
                            Y = Y - 0.5
                        end
                    end
                    if race == "human" then
                        if sex == 3 then
                            Z = Z + 1
                            Y = Y - 0.5
                        else
                            Y = Y - 1
                            Z = Z + 2
                        end
                    end
                    if race == "gnome" then
                        Y = Y - 0.3
                    end
                    if race == "scourge" then
                        if sex == 3 then
                            Z = Z + 1
                            Y = Y - 0.5
                            X = X - 0.5
                        end
                    end
                    model:SetPosition(Z + 6.8, X, Y - 2.2)
                end
                -- shoulder
                if slot == 3 then
                    if race == "tauren" then
                        if sex == 2 then
                            Z = Z - 0.5
                            Y = Y - 0.5
                        end
                    end
                    if race == "troll" then
                        if sex == 3 then
                            Z = Z + 1.3
                        end
                    end
                    if race == "dwarf" then
                        Y = Y - 0.2
                        if sex == 3 then
                            X = X - 0.3
                        end
                    end
                    if race == "goblin" then
                        Y = Y + 1.5
                        Z = Z - 0.5
                    end
                    if race == "bloodelf" then
                        if sex == 3 then
                            Z = Z + 2
                            Y = Y - 0.5
                        else
                            Z = Z - 1
                            Y = Y - 1
                        end
                    end
                    if race == "orc" then
                        if sex == 3 then
                            Z = Z + 0.5
                        else
                            Z = Z - 0.5
                        end
                    end
                    if race == "scourge" then
                        if sex == 3 then
                            Z = Z + 1
                            X = X - 0.5
                        end
                    end
                    if race == "nightelf" then
                        if sex == 2 then
                            Y = Y - 0.5
                        end
                    end
                    model:SetPosition(Z + 5.8, X + 0.5, Y - 1.7)
                end
                -- cloak
                if slot == 15 then
                    model:SetFacing(3.2)
                    if race == "bloodelf"then
                        if sex == 2 then
                            X = X - 0.3
                        end
                    end
                    if race == "goblin" then
                        Y = Y + 1.5
                    end
                    if race == "dwarf" then
                        Y = Y + 0.5
                    end
                    if race == "gnome" then
                        Z = Z + 1
                        Y = Y + 0.2
                    end
                    if race == "orc" and sex == 3 then
                        Y = Y + 0.8
                    end
                    if race == "scourge" then
                        if sex == 3 then
                            Z = Z + 1
                            Y = Y + 1
                        end
                    end
                    if race == "tauren" then
                        Y = Y + 1.2
                        Z = Z + 0.8
                    end
                    if race == "troll" then
                        if sex == 3 then
                            Z = Z + 1
                            Y = Y + 1
                        end
                    end
                    model:SetPosition(Z + 4.8, X, Y - 1)
                end
                -- chest / shirt / tabard
                if slot == 5 or slot == 4 or slot == 19 then
                    if race == "bloodelf" then
                        if sex == 3 then
                            Z = Z + 2
                            X = X + 0.2
                        end
                        Z = Z - 1
                    end
                    if race == "tauren" or race == "troll" then
                        X = X - 0.2
                        Y = Y + 1
                    end
                    if race == "goblin" then
                        Y = Y + 1.5
                        Z = Z - 0.5
                    end
                    if race == "orc" then
                        if sex == 3 then
                            Z = Z + 1
                            Y = Y + 0.5
                        end
                    end
                    if race == "dwarf" then
                        Y = Y + 0.5
                        Z = Z - 0.3
                    end
                    if race == "gnome" then
                        Z = Z + 1
                        Y = Y + 0.3
                    end
                    model:SetFacing(0.3)
                    model:SetPosition(Z + 5.8, X + 0.1, Y - 1.2)
                end
                -- hands / bracer
                if slot == 10 or slot == 9 then
                    model:SetFacing(1.5)
                    if race == "human" then
                        if sex == 2 then
                            Z = Z + 1
                        end
                    end
                    if race == "gnome" then
                        Y = Y - 0.5
                        Z = Z + 1.5
                    end
                    if race == "tauren" then
                        X = X - 0.2
                        if sex == 3 then
                            Y = Y + 1.3
                            Z = Z + 1.3
                        end
                    end
                    if race == "dwarf" then
                        Z = Z - 0.2
                        X = X - 0.3
                        Y = Y - 0.1
                        if sex == 3 then
                            Z = Z + 0.6
                        elseif sex == 2 then
                            Y = Y + 0.2
                        end
                    end
                    if race == "troll" then
                        Y = Y + 0.9
                        if sex == 3 then
                            Z = Z + 2
                        end
                    end
                    if race == "goblin" then
                        Y = Y + 1.5
                        Z = Z - 0.5
                    end
                    if race == "nightelf" then
                        Z = Z + 2
                    end
                    if race == "bloodelf" then
                        if sex == 3 then
                            Z = Z + 1.5
                        end
                    end
                    if race == "orc" and sex == 3 then
                        Z = Z + 0.5
                    end
                    if race == "scourge" then
                        if sex == 3 then
                            Z = Z + 1.3
                            X = X - 0.5
                        end
                    end
                    model:SetPosition(Z + 5.8, X + 0.4, Y - 0.3)
                end
                -- belt
                if slot == 6 then
                    model:SetFacing(0.31)
                    if race == "tauren" then
                        if sex == 3 then
                            Y = Y + 2
                        else
                            Z = Z + 1
                            Y = Y + 0.3
                        end
                    end
                    if race == "goblin" then
                        Y = Y + 1.5
                        Z = Z - 0.5
                    end
                    if race == "dwarf" then
                        Z = Z - 2
                    end
                    if race == "gnome" then
                        Z = Z - 1
                    end
                    if race == "nightelf" then
                        Z = Z - 1
                    end
                    if race == "bloodelf" then
                        if sex == 3 then
                            Z = Z + 0.3
                            X = X + 0.3
                        else
                            Z = Z - 1
                            Y = Y - 0.2
                        end
                    end
                    if race == "human" then
                        if sex == 3 then
                            Z = Z - 1
                            Y = Y - 0.5
                        else
                            Z = Z - 1
                        end
                    end
                    model:SetPosition(Z + 8, X, Y - 0.4)
                end
                -- pants
                if slot == 7 then
                    model:SetFacing(0.31)
                    if race == "bloodelf" then
                        if sex == 2 then
                            Z = Z - 1
                            Y = Y - 0.3
                        else
                            X = X + 0.3
                        end
                    end
                    if race == "goblin" then
                        if sex == 2 then
                            Y = Y + 0.3
                        end
                    end
                    if race == "gnome" then
                        Z = Z + 1
                        Y = Y - 1.3
                    end
                    if race == "dwarf" then
                        Y = Y - 0.5
                    end
                    if race == "tauren" then
                        if sex == 3 then
                            Y = Y + 1
                        else
                            Z = Z + 1
                        end
                    end
                    if race == "scourge" then
                        if sex == 3 then
                            Z = Z + 1.3
                        end
                    end
                    if race == "troll" then
                        if sex == 3 then
                            Y = Y + 1
                        end
                    end
                    model:SetPosition(Z + 5.8, X, Y + 0.9)
                end
                -- boots
                if slot == 8 then
                    model:SetFacing(0.61)
                    if race == "bloodelf" then
                        if sex == 2 then
                            X = X - 0.3
                            model:SetFacing(1.2)
                        else
                            model:SetFacing(0)
                            Z = Z + 0.5
                            Y = Y + 0.2
                            X = X + 0.4
                        end
                    end
                    if race == "goblin" then
                        if sex == 2 then
                            model:SetFacing(1.2)
                            Y = Y + 0.3
                        end
                    end
                    if race == "gnome" then
                        Z = Z + 1
                        Y = Y - 1.6
                        if sex == 2 then
                            Z = Z + 1
                        elseif sex == 3 then
                            Z = Z + 0.5
                            X = X + 0.1
                        end
                    end
                    if race == "dwarf" then
                        Y = Y - 0.6
                        if sex == 3 then
                            Z = Z + 0.5
                            X = X - 0.2
                            model:SetFacing(0.1)
                        elseif sex == 2 then
                            Y = Y + 0.2
                        end
                    end
                    if race == "tauren" then
                        if sex == 3 then
                            Y = Y + 1
                            Z = Z + 1
                        else
                            Z = Z + 1
                        end
                    end
                    if race == "scourge" then
                        if sex == 3 then
                            Z = Z + 1.3
                        end
                    end
                    if race == "troll" then
                        if sex == 3 then
                            Z = Z + 1
                            Y = Y + 1
                        end
                    end
                    if race == "nightelf" then
                        Y = Y + 0.3
                        model:SetFacing(0.3)
                    end
                    if race == "human" then
                        if sex == 2 then
                            Z = Z + 1
                            model:SetFacing(0.3)
                        end
                    end
                    model:SetPosition(Z + 5.8, X, Y + 1.5)
                end
                -- mh
                if slot == 16 then
                    model:SetFacing(0.61)
                    if race == "gnome" then
                        Y = Y - 1.5
                        Z = Z + 1
                    end
                    if race == "dwarf" then
                        Y = Y - 1
                    end
                    if race == "bloodelf" then
                        if sex == 3 then
                            Z = Z + 2.5
                            X = X + 0.2
                        end
                    end
                    if race == "orc" then
                        if sex == 3 then
                            Z = Z + 1
                        end
                    end
                    if race == "troll" then
                        if sex == 2 then
                            Y = Y + 1
                        end
                    end
                    if race == "goblin" then
                        if sex == 2 then
                            model:SetFacing(0.9)
                            Y = Y + 0.5
                        end
                    end
                    model:SetPosition(Z + 3.8, X, Y + 0.4)
                end
                -- oh / ranged
                if slot == 17 or slot == 18 then
                    local _, _, _, _, _, _, _, loc  = GetItemInfo(itemID)
                    if loc == "INVTYPE_RANGED" or loc == "INVTYPE_WEAPONOFFHAND" or loc == "INVTYPE_HOLDABLE" then
                        model:SetFacing(-0.61)
                        if race == "bloodelf" then
                            if sex == 3 then
                                model:SetFacing(-1)
                            end
                        end
                    else
                        model:SetFacing(0.61)
                        if race == "goblin" then
                            if sex == 2 then
                                model:SetFacing(0.9)
                            end
                        end
                    end
                    -- shield
                    if loc == "INVTYPE_SHIELD" then
                        model:SetFacing(-1.5)
                        if race == "scourge" then
                            if sex == 3 then
                                model:SetFacing(-1)
                                Z = Z + 2
                                Y = Y - 0.5
                            end
                        end
                        if race == "goblin" then
                            if sex == 3 then
                                X = X - 0.3
                            end
                            Z = Z + 0.2
                        end
                        if race == "orc" then
                            if sex == 3 then
                                X = X - 0.8
                            end
                        end
                        if race == "nightelf"then
                            X = X - 0.3
                            Y = Y - 1
                        end
                        if race == "bloodelf" then
                            Y = Y - 1
                        end
                    end

                    if race == "troll" then
                        if sex == 2 then
                            Y = Y + 1
                        end
                    end
                    if race == "bloodelf" then
                        if sex == 3 then
                            Z = Z + 2.5
                            X = X + 0.2
                        end
                    end
                    if race == "gnome" then
                        Y = Y - 1.5
                        Z = Z + 1
                    end
                    if race == "dwarf" then
                        Y = Y - 1
                    end
                    if race == "orc" then
                        if sex == 3 then
                            Z = Z + 1
                        end
                    end
                    if race == "goblin" then
                        if sex == 2 then
                            Y = Y + 0.5
                        end
                    end
                    model:SetPosition(Z + 3.8, X, Y + 0.4)
                end

                model:TryOn(itemID)
                model:SetAlpha(1)
                model:SetLight(unpack(previewNormalLight))

                col = col + 1
                if col == 5 then
                    row = row + 1
                    col = 0
                end
                itemIndex = itemIndex + 1
            end
            index = index + 1
        end

        TmogFramePreview1ButtonPlus:Hide()
        TmogFramePreview1ButtonPlusPushed:Hide()

        Tmog.totalPages = Tmog:ceil(Tmog:tableSize(sorted) / ipp)
        TmogFramePageText:SetText("Page " .. Tmog.currentPage .. "/" .. Tmog.totalPages)
    
        if Tmog.currentPage == 1 then
            TmogFrameLeftArrow:Disable()
            TmogFrameFirstPage:Disable()
        else
            TmogFrameLeftArrow:Enable()
            TmogFrameFirstPage:Enable()
        end
    
        if Tmog.currentPage == Tmog.totalPages or Tmog:tableSize(sorted) < ipp then
            TmogFrameRightArrow:Disable()
            TmogFrameLastPage:Disable()
        else
            TmogFrameRightArrow:Enable()
            TmogFrameLastPage:Enable()
        end
        Tmog.flush = false

    elseif Tmog.currentTab == "outfits" then
        if noDraw then
            return
        end

        Tmog:HidePreviews()
        
        local frame, button
        --big plus button
        if Tmog.currentPage == 1 then
            if not Tmog.previewButtons[1] then
                Tmog.previewButtons[1] = CreateFrame("Frame", "TmogFramePreview1", TmogFrame, "TmogFramePreviewTemplate")
            end

            frame = Tmog.previewButtons[1]
            frame:Show()
            frame:SetPoint("TOPLEFT", TmogFrame, "TOPLEFT", 263 , -105)
            frame.name = "New Outfit"

            button = TmogFramePreview1Button
            button:Show()
            button:SetID(0)
            button:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_normal")

            TmogFramePreview1ButtonPlus:Show()
            TmogFramePreview1ButtonPlusPushed:Hide()
            TmogFramePreview1ItemModel:SetAlpha(0)
            Tmog_AddOutfitTooltip(button, frame.name)
            TmogFramePreview1ButtonBorder:SetAlpha(0.4)
            TmogFramePreview1ButtonBorder:SetVertexColor(1, 0.82, 0)
            col = 1
            outfitIndex = 2
            index = index + 1
        else
            index = index + 1
            TmogFramePreview1ButtonPlus:Hide()
            TmogFramePreview1ButtonPlusPushed:Hide()
        end

        for name in pairs(TMOG_PLAYER_OUTFITS) do

            if index >= (Tmog.currentPage - 1) * ipp and index < Tmog.currentPage * ipp and outfitIndex <= ipp then
                if not Tmog.previewButtons[outfitIndex] then
                    Tmog.previewButtons[outfitIndex] = CreateFrame("Frame", "TmogFramePreview" .. outfitIndex, TmogFrame, "TmogFramePreviewTemplate")
                end
                frame = Tmog.previewButtons[outfitIndex]
                frame:Show()
                frame:SetPoint("TOPLEFT", TmogFrame, "TOPLEFT", 263 + col * 90, -105 - 120 * row)
                frame.name = name

                button = getglobal("TmogFramePreview" .. outfitIndex .. "Button")
                button:Show()
                button:SetID(outfitIndex)

                if name == Tmog.currentOutfit then
                    button:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_selected")
                else
                    button:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_normal")
                end

                Tmog_AddOutfitTooltip(button, name)

                local model = getglobal("TmogFramePreview" .. outfitIndex .. "ItemModel")
                local Z, X, Y = model:GetPosition()
                model:SetUnit("player")
                model:Undress()
                model:SetFacing(0.3)
                model:SetPosition(Z + 1.5, X, Y)
                
                for _, itemID in pairs(TMOG_PLAYER_OUTFITS[name]) do
                    model:TryOn(itemID)
                end
                model:SetAlpha(1)
                model:SetLight(unpack(previewNormalLight))
                getglobal("TmogFramePreview" .. outfitIndex .. "ButtonBorder"):SetAlpha(0.4)
                getglobal("TmogFramePreview" .. outfitIndex .. "ButtonBorder"):SetVertexColor(1, 0.82, 0)
                col = col + 1
                if col == 5 then
                    row = row + 1
                    col = 0
                end
                outfitIndex = outfitIndex + 1
            end
            index = index + 1
        end

        Tmog.totalPages = Tmog:ceil((Tmog:tableSize(TMOG_PLAYER_OUTFITS) + 1) / ipp)
        TmogFramePageText:SetText("Page " .. Tmog.currentPage .. "/" .. Tmog.totalPages)
    
        if Tmog.currentPage == 1 then
            TmogFrameLeftArrow:Disable()
            TmogFrameFirstPage:Disable()
        else
            TmogFrameLeftArrow:Enable()
            TmogFrameFirstPage:Enable()
        end
    
        if (Tmog.currentPage == Tmog.totalPages) or ((Tmog:tableSize(TMOG_PLAYER_OUTFITS) + 1) < ipp) then
            TmogFrameRightArrow:Disable()
            TmogFrameLastPage:Disable()
        else
            TmogFrameRightArrow:Enable()
            TmogFrameLastPage:Enable()
        end
    end

    if Tmog.totalPages > 1 then
        Tmog:ShowPagination()
    else
        Tmog:HidePagination()
    end
end

function Tmog:ShowPagination()
    TmogFrameLeftArrow:Show()
    TmogFrameRightArrow:Show()
    TmogFramePageText:Show()
    TmogFrameFirstPage:Show()
    TmogFrameLastPage:Show()
end

function Tmog:HidePagination()
    TmogFrameLeftArrow:Hide()
    TmogFrameRightArrow:Hide()
    TmogFramePageText:Hide()
    TmogFrameFirstPage:Hide()
    TmogFrameLastPage:Hide()
end

function Tmog_ChangePage(dir, destination)
    if not Tmog.currentPage or not Tmog.totalPages then
        return
    end

    if Tmog.currentTab == "items" and not Tmog.currentSlot then
        return
    end
    -- get total pages
    Tmog:DrawPreviews(1)
    
    if (Tmog.currentPage + dir < 1) or (Tmog.currentPage + dir > Tmog.totalPages) then
        return
    end

    if destination then
        if destination == "last" then
            dir = Tmog.totalPages - Tmog.currentPage
        elseif destination == "first" then
            dir = 1 - Tmog.currentPage
        end
    end

    Tmog.currentPage = Tmog.currentPage + dir
    Tmog:DrawPreviews()

    if Tmog.currentTab == "items" then
        Tmog.pages[Tmog.currentSlot][Tmog.currentType] = Tmog.currentPage
    end

    if TmogFrameSharedItems:IsVisible() then
        TmogFrameSharedItems:Hide()
    end
end

function Tmog:RemoveSelection()
    if Tmog.currentTab == "outfits" then

        if not (Tmog.currentPage == 1) then
            TmogFramePreview1ButtonPlus:Hide()
            TmogFramePreview1ButtonPlusPushed:Hide()
        end

        for index = 1, Tmog:tableSize(Tmog.previewButtons) do
            getglobal("TmogFramePreview"..index.."Button"):SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_normal")
        end

    elseif Tmog.currentTab == "items" then

        for index = 1, Tmog:tableSize(Tmog.previewButtons) do
            if Tmog.previewButtons[index].id ~= Tmog.currentGear[Tmog.currentSlot] then
                getglobal("TmogFramePreview"..index.."Button"):SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_normal")
            end
        end
        if TmogFramePreview1ButtonPlus or TmogFramePreview1ButtonPlusPushed then
            TmogFramePreview1ButtonPlus:Hide()
            TmogFramePreview1ButtonPlusPushed:Hide()
        end
    end
end

function TmogSlot_OnClick(InventorySlotId, rightClick)
    if IsShiftKeyDown() then
        Tmog:LinkItem(Tmog.currentGear[InventorySlotId])

    elseif rightClick then
        
        if Tmog.currentGear[InventorySlotId] == 0 then
            if Tmog.actualGear[InventorySlotId] == 0 then
                return
            end
            TmogFramePlayerModel:TryOn(Tmog.actualGear[InventorySlotId])
            Tmog.currentGear[InventorySlotId] = Tmog.actualGear[InventorySlotId]
        else
            TmogFramePlayerModel:Undress()

            for slot, itemID in pairs(Tmog.currentGear) do
                if slot ~= InventorySlotId and slot ~= 18 then
                    if (slot == 1 and showingHelm == 1) or (slot == 15 and showingCloak == 1) or
                        (Tmog.currentGear[slot] ~= Tmog.actualGear[slot]) or (slot ~= 1 and slot ~= 15)
                        then
                        TmogFramePlayerModel:TryOn(itemID)
                    end
                end
            end

            Tmog.currentGear[InventorySlotId] = 0
        end

        Tmog:EnableOutfitSaveButton()
        Tmog:UpdateItemTextures()
        --update tooltip
        this:Hide()
        this:Show()

        if Tmog.currentTab == "items" then
            Tmog:RemoveSelection()
        end
        PlaySound("igMainMenuOptionCheckBoxOn")
    else
        Tmog.currentSlot = InventorySlotId
        Tmog.flush = true
        if Tmog.currentTab == "outfits" then
            if getglobal(this:GetName().."BorderFull"):IsVisible() then
                Tmog_SwitchTab("items")
                Tmog_Search()
                return
            else
                Tmog_SwitchTab("items")
            end
        end

        Tmog:HidePagination()
        UIDropDownMenu_Initialize(TmogFrameTypeDropDown, Tmog_TypeDropDown_Initialize)
        TmogFrameSearchBox:Show()
        Tmog.currentType = Tmog.slots[InventorySlotId]
        
        if not getglobal(this:GetName().."BorderFull"):IsVisible() then
            Tmog:HideBorders()
            getglobal(this:GetName().."BorderFull"):Show()
            -- shirt / tabard / cloak
            if InventorySlotId == 4 or InventorySlotId == 19 or InventorySlotId == 15 then
                TmogFrameTypeDropDown:Hide()
            else
                TmogFrameTypeDropDown:Show()
            end
        else
            TmogFrameTypeDropDown:Hide()
            Tmog:HideBorders()
            Tmog.currentSlot = nil
            TmogFrameSearchBox:Hide()
            PlaySound("InterfaceSound_LostTargetUnit")
        end

        Tmog_Search()
        PlaySound("igCreatureAggroSelect")
    end
    DropDownList1:Hide()
end

function Tmog:UpdateItemTextures()
    for slotName, InventorySlotId in pairs(Tmog.inventorySlots) do
        local frame = getglobal("TmogFrame"..slotName)
        local icon = getglobal(frame:GetName() .. "ItemIcon")
        if frame then
            -- add paperdoll texture
            local _, _, texture = strfind(frame:GetName(), "TmogFrame(.+)Slot")
            texture = strlower(texture)

            if texture == "wrist" then
                texture = texture .. "s"
            elseif texture == "back" then
                texture = "chest"
            end

            icon:SetTexture("Interface\\Paperdoll\\ui-paperdoll-slot-" .. texture)

            -- replace with item texture if possible
            if GetInventoryItemLink("player", InventorySlotId) or GetItemInfo(Tmog.currentGear[InventorySlotId]) then
                local _, _, _, _, _, _, _, _, tex = GetItemInfo(Tmog.currentGear[InventorySlotId])
    
                if tex then
                    icon:SetTexture(tex)
                end
            end
        end
    end
end

local sharedItems = {}
local t = {}
local selectedButton
function TmogTry(itemId, arg1, noSelect)
    if arg1 == "LeftButton" then

        if Tmog.currentTab == "items" then
            
            if IsShiftKeyDown() then
                Tmog:LinkItem(itemId)
            else
                TmogFramePlayerModel:TryOn(itemId)
                Tmog.currentGear[Tmog.currentSlot] = itemId
                Tmog:EnableOutfitSaveButton()
                Tmog:UpdateItemTextures()
                Tmog:RemoveSelection()
                if not noSelect then
                    this:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_selected")
                else
                    selectedButton:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_selected")
                end
                PlaySound("igMainMenuOptionCheckBoxOn")
            end

            if TmogFrameSharedItems:IsVisible() then
                TmogFrameSharedItems:Hide()
            end

        elseif Tmog.currentTab == "outfits" then

            if this:GetID() == 0 then
                Tmog_NewOutfitPopup()
                return
            end

            local outfit = Tmog.previewButtons[this:GetID()].name
            if IsShiftKeyDown() then
                Tmog:LinkOutfit(outfit)
                return
            end
            Tmog.currentOutfit = outfit

            Tmog_LoadOutfit(outfit)
            Tmog:RemoveSelection()
            this:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_selected")
            PlaySound("igMainMenuOptionCheckBoxOn")
        end

    elseif arg1 == "RightButton" then

        if Tmog.currentTab ~= "items" then
            TmogFrameSharedItems:Hide()
            return
        end

        selectedButton = this

        for i = 1, Tmog:tableSize(sharedItems) do
            getglobal("TmogFrameSharedItem"..i):Hide()
        end

        local cursorX, cursorY = GetCursorPosition()
        local uiScale = 0.9

        if GetCVar("useUiScale") == "1" then
		    uiScale = tonumber(GetCVar("uiscale")) or 0.9
		end

        cursorX = cursorX / uiScale
        cursorY =  cursorY / uiScale
        TmogFrameSharedItems:SetPoint("TOPLEFT", nil , "BOTTOMLEFT", cursorX + 2, cursorY - 2)
        
        for k in pairs(t) do
            t[k] = nil
        end
        local index = 1

        if SetContains(DisplayIdDB, itemId) then

            for _, id in pairs(DisplayIdDB[itemId]) do

                Tmog:CacheItem(id)
                local name, _, quality, _, _, _, _, _, tex = GetItemInfo(id)

                if name and quality then
                    local r, g, b = GetItemQualityColor(quality)
                    if Tmog.onlyUsable and not Tmog:IsUsableItem(id) then
                    else
                        t[index] = {name = "", id = 0, color = { r = 0, g = 0, b = 0 }, tex = ""}
                        t[index].name = name
                        t[index].id = id
                        t[index].color.r = r
                        t[index].color.g = g
                        t[index].color.b = b
                        t[index].tex = tex
                        index = index + 1
                    end
                end
            end
        end

        if not next(t) then
            TmogFrameSharedItems:Hide()
            return
        end

        if TmogFrameSharedItems:IsVisible() then
            TmogFrameSharedItems:Hide()
        else
            TmogFrameSharedItems:Show()
        end

        local widestText = 0

        for i = 1, Tmog:tableSize(t) do

            if not sharedItems[i] then
                sharedItems[i] = CreateFrame("Button", "TmogFrameSharedItem"..i, TmogFrameSharedItems, "TmogSharedItemTemplate")
            end

            sharedItems[i]:Show()
            sharedItems[i]:SetID(t[i].id)
            sharedItems[i]:SetPoint("TOPLEFT", TmogFrameSharedItems, 10 , -10 - ((i - 1) * 20))

            TmogFrameSharedItems:SetHeight(40 + (i - 1) * 20)

            getglobal("TmogFrameSharedItem"..i.."IconTexture"):SetTexture(t[i].tex)
            getglobal("TmogFrameSharedItem"..i.."Name"):SetText(t[i].name)
            getglobal("TmogFrameSharedItem"..i.."Name"):SetTextColor(t[i].color.r, t[i].color.g, t[i].color.b)

            local width = getglobal("TmogFrameSharedItem"..i.."Name"):GetStringWidth()

            if width > widestText then
                widestText = width
            end

            Tmog_AddSharedItemTooltip(sharedItems[i])
        end

        TmogFrameSharedItems:SetWidth(45 + widestText)
    end

    DropDownList1:Hide()
end

function Tmog_AddSharedItemTooltip(frame)
    local originalColor = { r = 1, g = 1, b = 1}
    local buttonText = getglobal(frame:GetName().."Name")
    originalColor.r, originalColor.g, originalColor.b = buttonText:GetTextColor()

    frame:SetScript("OnEnter", function()
        TmogTooltip:SetOwner(this, "ANCHOR_LEFT", -(this:GetWidth() / 4) + 30, -(this:GetHeight() / 4))
        buttonText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)

        local itemID = this:GetID()

        Tmog:CacheItem(itemID)
        TmogTooltip.itemID = itemID
        TmogTooltip:SetHyperlink("item:"..tostring(itemID))
        TmogTip.ExtendTooltip(TmogTooltip)

        local numLines = TmogTooltip:NumLines()

        if numLines and numLines > 0 then
            local lastLine = getglobal("TmogTooltipTextLeft"..numLines)  
            if lastLine:GetText() then
                lastLine:SetText(lastLine:GetText().."\n\n"..YELLOW.."ItemID: "..itemID)
            end
        end

        TmogTooltip:Show()
    end)

    frame:SetScript("OnLeave", function()
        buttonText:SetTextColor(originalColor.r,originalColor.g,originalColor.b)
        TmogTooltip:Hide()
        TmogTooltip.itemID = nil
    end)
end

function Tmog:LinkItem(itemId)
    if not itemId or itemId == 0 then
        return
    end

    Tmog:CacheItem(itemId)
    local itemName, _, quality = GetItemInfo(itemId)
    local _, _, _, color = GetItemQualityColor(quality)

    if WIM_EditBoxInFocus then
        WIM_EditBoxInFocus:Insert(color.."|Hitem:"..itemId..":0:0:0|h["..itemName.."]|h|r")
    elseif ChatFrameEditBox:IsVisible() then
        ChatFrameEditBox:Insert(color.."|Hitem:"..itemId..":0:0:0|h["..itemName.."]|h|r")
    end
end

function Tmog:LinkOutfit(outfit)
    if not outfit or outfit == "" then
        return
    end

    local code = "T.O.L."
    for slot, id in pairs(TMOG_PLAYER_OUTFITS[outfit]) do
        code = code..slot..":"..id..";"
    end

    if WIM_EditBoxInFocus then
        WIM_EditBoxInFocus:Insert(code)
    elseif ChatFrameEditBox:IsVisible() then
        ChatFrameEditBox:Insert(code)
    end
end

function Tmog_Undress()
    TmogFramePlayerModel:Undress()

    for _, InventorySlotId in pairs(Tmog.inventorySlots) do
        Tmog.currentGear[InventorySlotId] = 0
    end

    Tmog:UpdateItemTextures()
    Tmog:EnableOutfitSaveButton()

    if Tmog.currentTab == "items" then
        Tmog:RemoveSelection()
    end
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

function Tmog_AddOutfitTooltip(frame, outfit)
    frame:SetScript("OnEnter", function()

        TmogTooltip:SetOwner(this, "ANCHOR_RIGHT", -(this:GetWidth() / 4) + 15, -(this:GetHeight() / 4) + 20)

        if outfit then
            TmogTooltip:AddLine(WHITE .. outfit)
        end

        for name in pairs(TMOG_PLAYER_OUTFITS) do

            if name == outfit then

                for slot, itemID in pairs(TMOG_PLAYER_OUTFITS[name]) do
                    local slotName

                    for k, v in pairs(Tmog.inventorySlots) do
                        if v == slot then
                            slotName = k
                        end
                    end

                    if slotName then
                        slotName = TEXT(getglobal(strupper(slotName)))
                        local itemName, _, quality = GetItemInfo(itemID)
                        local _, _, _, color = GetItemQualityColor(quality)

                        if slot ~= 4 and slot ~= 19 then
                            local collected = SetContains(TMOG_CACHE[slot], itemID, itemName)
                            local status = ""

                            if collected then
                                status = YELLOW.."Collected"
                            else
                                status = GREY.."Not collected"
                            end

                            if color then
                                TmogTooltip:AddDoubleLine(slotName..": "..color..itemName, status)
                            else
                                TmogTooltip:AddDoubleLine(slotName..": "..itemName, status)
                            end
                        else
                            if color then
                                TmogTooltip:AddLine(slotName..": "..color..itemName)
                            else
                                TmogTooltip:AddLine(slotName..": "..itemName)
                            end
                        end
                    end
                end
            end
        end
        if this:GetID() == 0 then
            if not getglobal(this:GetName().."PlusPushed"):IsVisible() then
                getglobal(this:GetName().."PlusHighlight"):Show()
            end
        else
            getglobal(this:GetParent():GetName().."ItemModel"):SetLight(unpack(previewHighlight))
        end
        TmogTooltip:Show()
    end)

    frame:SetScript("OnLeave", function()
        getglobal(this:GetParent():GetName().."ItemModel"):SetLight(unpack(previewNormalLight))
        TmogTooltip:Hide()
        getglobal(this:GetName().."PlusHighlight"):Hide()
    end)
end

function Tmog_AddItemTooltip(frame, text)
    frame:SetScript("OnEnter", function()
        TmogTooltip:SetOwner(this, "ANCHOR_RIGHT", -(this:GetWidth() / 4) + 15, -(this:GetHeight() / 4) + 20)

        if text then
            TmogTooltip:AddLine(WHITE .. text)
        end

        local itemID = this:GetID()
        Tmog:CacheItem(itemID)
        TmogTooltip.itemID = itemID
        TmogTooltip:SetHyperlink("item:"..itemID)
        TmogTip.ExtendTooltip(TmogTooltip)

        local numLines = TmogTooltip:NumLines()

        if numLines and numLines > 0 then
            local lastLine = getglobal("TmogTooltipTextLeft"..numLines)

            if lastLine:GetText() then
                lastLine:SetText(lastLine:GetText().."\n\n"..YELLOW.."ItemID: "..itemID)
                local name = GetItemInfo(itemID)

                if name and SetContains(DisplayIdDB, itemID) then
                    if not Tmog.onlyUsable then
                        lastLine:SetText(lastLine:GetText().."\n\n"..YELLOW.."Shares Appearance With:")
                        for _, id in pairs(DisplayIdDB[itemID]) do
                            Tmog:CacheItem(id)
                            local similarItem, _, quality = GetItemInfo(id)
    
                            if similarItem and quality then
                                local _, _, _, color = GetItemQualityColor(quality)

                                if color then
                                    lastLine:SetText(lastLine:GetText().."\n"..color..similarItem)
                                else
                                    lastLine:SetText(lastLine:GetText().."\n"..similarItem)
                                end
                            end
                        end
                    else
                        local proceed = false
                        for _, id in pairs(DisplayIdDB[itemID]) do
                            Tmog:CacheItem(itemID)
                            if Tmog:IsUsableItem(id) then
                                lastLine:SetText(lastLine:GetText().."\n\n"..YELLOW.."Shares Appearance With:")
                                proceed = true
                                break
                            end
                        end
                        if proceed then
                            for _, id in pairs(DisplayIdDB[itemID]) do
                                Tmog:CacheItem(id)
                                local similarItem, _, quality = GetItemInfo(id)
        
                                if similarItem and quality then
                                    if not Tmog:IsUsableItem(id) then
                                    else
                                        local _, _, _, color = GetItemQualityColor(quality)
        
                                        if color then
                                            lastLine:SetText(lastLine:GetText().."\n"..color..similarItem)
                                        else
                                            lastLine:SetText(lastLine:GetText().."\n"..similarItem)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        getglobal(this:GetParent():GetName().."ItemModel"):SetLight(unpack(previewHighlight))
        TmogTooltip:Show()
    end)

    frame:SetScript("OnLeave", function()
        TmogTooltip:Hide()
        TmogTooltip.itemID = nil
        getglobal(this:GetParent():GetName().."ItemModel"):SetLight(unpack(previewNormalLight))
    end)
end

local hidden = false
function Tmog_HideUI()
    if not hidden then
        for slot in pairs(Tmog.inventorySlots) do
            getglobal("TmogFrame"..slot):Hide()
        end
        TmogFrameRevert:Hide()
        TmogFrameFullScreenButton:Hide()
        TmogFrameHideUI:SetText("ShowUI")
        hidden = true
    else
        for slot in pairs(Tmog.inventorySlots) do
            getglobal("TmogFrame"..slot):Show()
        end
        TmogFrameRevert:Show()
        TmogFrameFullScreenButton:Show()
        TmogFrameHideUI:SetText("HideUI")
        hidden = false
    end
end

function Tmog_LoadOutfit(outfit)
    if IsShiftKeyDown() then
        Tmog:LinkOutfit(outfit)
        return
    end
    UIDropDownMenu_SetText(outfit, TmogFrameOutfitsDropDown)

    Tmog.currentOutfit = outfit
    TmogFrameSaveOutfit:Disable()

    TmogFrameDeleteOutfit:Enable()
    TmogFrameShareOutfit:Enable()

    TmogFramePlayerModel:Undress()

    for _, InventorySlotId in pairs(Tmog.inventorySlots) do
        Tmog.currentGear[InventorySlotId] = 0
    end

    for slot, itemID in pairs(TMOG_PLAYER_OUTFITS[outfit]) do
        if slot ~= 17 and slot ~= 16 then
            TmogFramePlayerModel:TryOn(itemID)
            Tmog.currentGear[slot] = itemID
        end
    end
    if TMOG_PLAYER_OUTFITS[outfit][18] then
        TmogFramePlayerModel:TryOn(TMOG_PLAYER_OUTFITS[outfit][18])
        Tmog.currentGear[18] = TMOG_PLAYER_OUTFITS[outfit][18]
    end
    if TMOG_PLAYER_OUTFITS[outfit][16] then
        TmogFramePlayerModel:TryOn(TMOG_PLAYER_OUTFITS[outfit][16])
        Tmog.currentGear[16] = TMOG_PLAYER_OUTFITS[outfit][16]
    end
    if TMOG_PLAYER_OUTFITS[outfit][17] then
        TmogFramePlayerModel:TryOn(TMOG_PLAYER_OUTFITS[outfit][17])
        Tmog.currentGear[17] = TMOG_PLAYER_OUTFITS[outfit][17]
    end

    Tmog:UpdateItemTextures()
    Tmog:RemoveSelection()

    for i = 1, Tmog:tableSize(Tmog.previewButtons) do
        local button = getglobal("TmogFramePreview"..i.."Button")

        if Tmog.previewButtons[i].name == outfit then
            button:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_selected")
        end
    end
end

function Tmog:EnableOutfitSaveButton()
    if Tmog.currentOutfit ~= nil then
        TmogFrameSaveOutfit:Enable()
        TmogFrameDeleteOutfit:Enable()
        TmogFrameShareOutfit:Enable()
    end
end

function Tmog_SaveOutfit()
    TMOG_PLAYER_OUTFITS[Tmog.currentOutfit] = {}

    for InventorySlotId, itemID in pairs(Tmog.currentGear) do
        if itemID ~= 0 then
            TMOG_PLAYER_OUTFITS[Tmog.currentOutfit][InventorySlotId] = itemID
        end
    end

    TmogFrameSaveOutfit:Disable()

    if Tmog.currentTab == "outfits" then
        Tmog:DrawPreviews()
    end
end

function Tmog_DeleteOutfit()
    TMOG_PLAYER_OUTFITS[Tmog.currentOutfit] = nil
    Tmog.currentOutfit = nil

    TmogFrameSaveOutfit:Disable()
    TmogFrameDeleteOutfit:Disable()
    TmogFrameShareOutfit:Disable()
    UIDropDownMenu_SetText("Outfits", TmogFrameOutfitsDropDown)

    if Tmog.currentTab == "outfits" then
        Tmog:HidePreviews()
        Tmog:DrawPreviews()
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
        if Tmog.currentTab == "outfits" then
            if Tmog.currentPage == 1 then
                TmogFramePreview1ButtonPlus:Hide()
                TmogFramePreview1ButtonPlusPushed:Show()
            else
                TmogFramePreview1ButtonPlus:Hide()
                TmogFramePreview1ButtonPlusPushed:Hide()
            end
        end
        getglobal(this:GetName().."EditBox"):SetFocus()
        getglobal(this:GetName() .. "EditBox"):SetScript("OnEnterPressed", function()
            StaticPopup1Button1:Click()
        end)

        getglobal(this:GetName() .. "EditBox"):SetScript("OnEscapePressed", function()
            getglobal(this:GetParent():GetName() .. "EditBox"):SetText("")
            StaticPopup1Button2:Click()
        end)
    end,

    OnAccept = function()
        local outfitName = getglobal(this:GetParent():GetName() .. "EditBox"):GetText()
        if Tmog.currentTab == "outfits" then
            if Tmog.currentPage == 1 then
                TmogFramePreview1ButtonPlus:Show()
                TmogFramePreview1ButtonPlusPushed:Hide()
            else
                TmogFramePreview1ButtonPlus:Hide()
                TmogFramePreview1ButtonPlusPushed:Hide()
            end
        end
        if outfitName == "" then
            StaticPopup_Show("TMOG_OUTFIT_EMPTY_NAME")
            return
        end

        if TMOG_PLAYER_OUTFITS[outfitName] then
            StaticPopup_Show("TMOG_OUTFIT_EXISTS")
            return
        end

        UIDropDownMenu_SetText(outfitName, TmogFrameOutfitsDropDown)
        Tmog.currentOutfit = outfitName
        TmogFrameDeleteOutfit:Enable()
        TmogFrameShareOutfit:Enable()
        Tmog_SaveOutfit()
        getglobal(this:GetParent():GetName() .. "EditBox"):SetText("")
    end,

    OnCancel = function()
        if Tmog.currentTab == "outfits" then
            if Tmog.currentPage == 1 then
                TmogFramePreview1ButtonPlus:Show()
                TmogFramePreview1ButtonPlusPushed:Hide()
            else
                TmogFramePreview1ButtonPlus:Hide()
                TmogFramePreview1ButtonPlusPushed:Hide()
            end
        end
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

StaticPopupDialogs["TMOG_BAD_OUTFIT_CODE"] = {
    text = "Invalid outfit code.",
    button1 = "Okay",
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1
}

StaticPopupDialogs["TMOG_IMPORT_OUTFIT"] = {
    text = "Insert outfit code here:",
    button1 = TEXT(OKAY),
    button2 = TEXT(CANCEL),
    hasEditBox = 1,

    OnShow = function()
        getglobal(this:GetName().."EditBox"):SetFocus()
        getglobal(this:GetName().."EditBox"):SetText("")
        getglobal(this:GetName() .. "EditBox"):SetScript("OnEnterPressed", function()
            StaticPopup1Button1:Click()
        end)

        getglobal(this:GetName() .. "EditBox"):SetScript("OnEscapePressed", function()
            getglobal(this:GetParent():GetName() .. "EditBox"):SetText("")
            StaticPopup1Button2:Click()
        end)
    end,

    OnAccept = function()
        local code = getglobal(this:GetParent():GetName() .. "EditBox"):GetText()
        getglobal(this:GetParent():GetName() .. "EditBox"):SetText("")
        local outfit = Tmog:ValidateOutfitCode(code)
        if not outfit then
            StaticPopup_Show("TMOG_BAD_OUTFIT_CODE")
            return
        end
        Tmog_ImportOutfit(outfit)
        this:GetParent():Hide()
        Tmog_NewOutfitPopup()
        TmogFrameShareOutfit:Disable()
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
    Tmog.flush = true
    if Tmog.currentSlot then
        Tmog.currentPage = 1
        for k in pairs(Tmog.pages) do
            for i in pairs(Tmog.pages[k]) do
                Tmog.pages[k][i] = 1
            end
        end
        Tmog:DrawPreviews()
    end
end

function Tmog_NotCollectedToggle()
    if Tmog.notCollected then
        Tmog.notCollected = false
    else
        Tmog.notCollected = true
    end

    TmogFrameNotCollected:SetChecked(Tmog.notCollected)
    Tmog.flush = true
    if Tmog.currentSlot then
        Tmog.currentPage = 1
        for k in pairs(Tmog.pages) do
            for i in pairs(Tmog.pages[k]) do
                Tmog.pages[k][i] = 1
            end
        end
        Tmog:DrawPreviews()
    end
end

function Tmog_UsableToggle()
    if Tmog.onlyUsable then
        Tmog.onlyUsable = false
        TmogFrameIgnoreLevel:Disable()
        TmogFrameIgnoreLevelText:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
    else
        Tmog.onlyUsable = true
        TmogFrameIgnoreLevel:Enable()
        TmogFrameIgnoreLevelText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
    end
    this:SetChecked(Tmog.onlyUsable)
    Tmog.flush = true
    if Tmog.currentSlot then
        Tmog.currentPage = 1
        for k in pairs(Tmog.pages) do
            for i in pairs(Tmog.pages[k]) do
                Tmog.pages[k][i] = 1
            end
        end
        if Tmog.onlyUsable then
            Tmog.unusable[Tmog.currentSlot][Tmog.currentType] = {}
        end
        Tmog:DrawPreviews()
    end
end

function Tmog_IgnoreLevelToggle()
    if Tmog.ignoreLevel then
        Tmog.ignoreLevel = false
    else
        Tmog.ignoreLevel = true
    end
    this:SetChecked(Tmog.ignoreLevel)
    Tmog.flush = true
    if Tmog.currentSlot then
        Tmog.currentPage = 1
        for k in pairs(Tmog.pages) do
            for i in pairs(Tmog.pages[k]) do
                Tmog.pages[k][i] = 1
            end
        end
        for k in pairs(Tmog.unusable) do
            for k2 in pairs(Tmog.unusable[k]) do
                for k3 in pairs(Tmog.unusable[k][k2]) do
                    Tmog.unusable[k][k2][k3] = nil
                end
            end
        end
        Tmog:DrawPreviews()
    end
end

function TmogFrame_Toggle()
	if TmogFrame:IsVisible() then
		HideUIPanel(TmogFrame)
	else
		ShowUIPanel(TmogFrame)
	end
end

function Tmog_Search()
    if TmogFrameSharedItems:IsVisible() then
        TmogFrameSharedItems:Hide()
    end

	if TmogFrameSearchBox:GetText() == "" then
        Tmog_SelectType(Tmog.currentType)
        return
    end
    Tmog.flush = true
    Tmog.currentPage = 1
    Tmog:DrawPreviews()
end

function Tmog_SwitchTab(which)
    if Tmog.currentTab == which then
        return
    end

    Tmog.currentTab = which

    if which == "items" then
        TmogFrameItemsButton:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\tab_active")
        TmogFrameItemsButton:SetPushedTexture("Interface\\AddOns\\Tmog\\Textures\\tab_active")
        TmogFrameOutfitsButton:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\tab_inactive")
        TmogFrameOutfitsButton:SetPushedTexture("Interface\\AddOns\\Tmog\\Textures\\tab_inactive")

        if Tmog.currentSlot then
            if Tmog.currentSlot ~= 15 and Tmog.currentSlot ~= 4 and Tmog.currentSlot ~= 19 then
                TmogFrameTypeDropDown:Show()
            end
            TmogFrameSearchBox:Show()
        else
            Tmog:HidePreviews()
            Tmog:HidePagination()
        end
        
        TmogFrameCollected:Show()
        TmogFrameNotCollected:Show()
        TmogFrameUsable:Show()
        TmogFrameIgnoreLevel:Show()
        TmogFrameShareOutfit:Hide()
        TmogFrameImportOutfit:Hide()
    elseif which == "outfits" then
        Tmog.currentPage = 1
        TmogFrameOutfitsButton:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\tab_active")
        TmogFrameOutfitsButton:SetPushedTexture("Interface\\AddOns\\Tmog\\Textures\\tab_active")
        TmogFrameItemsButton:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\tab_inactive")
        TmogFrameItemsButton:SetPushedTexture("Interface\\AddOns\\Tmog\\Textures\\tab_inactive")

        TmogFrameTypeDropDown:Hide()
        TmogFrameCollected:Hide()
        TmogFrameNotCollected:Hide()
        TmogFrameUsable:Hide()
        TmogFrameIgnoreLevel:Hide()
        TmogFrameSearchBox:Hide()
        TmogFrameShareOutfit:Show()
        TmogFrameImportOutfit:Show()

        Tmog:DrawPreviews()
    end

    TmogFrameSharedItems:Hide()
    DropDownList1:Hide()
end

function Tmog_PlayerSlotOnEnter()
    TmogTooltip:SetOwner(this, "ANCHOR_TOPRIGHT", 0, 0)

    local slot = this:GetID()
    local itemID = Tmog.currentGear[this:GetID()]

    Tmog:CacheItem(itemID)
    local name, _, quality = GetItemInfo(itemID)

    if name and quality then
        local r, g, b = GetItemQualityColor(quality)

        TmogTooltip:SetText(name, r, g, b)

        if slot ~= 4 and slot ~= 19 then
            if SetContains(TMOG_CACHE[slot], itemID, name)then
                TmogTooltip:AddLine(GREY.."In your collection|r")
            else
                TmogTooltip:AddLine(YELLOW.."Not collected|r")
            end
        end

        TmogTooltip:AddLine(YELLOW.."\nItemID: "..itemID.."|r", 1, 1, 1)
        TmogTooltip:Show()
    end

    if not name then
        local text = TEXT(getglobal(strupper(strsub(this:GetName(), 10))))

        TmogTooltip:SetText(text)
        TmogTooltip:Show()
    end
end

function Tmog_OutfitsDropDown_Initialize()
    if Tmog:tableSize(TMOG_PLAYER_OUTFITS) < 30 then
        local newOutfit = {}
        newOutfit.text = GREEN .. "+ New Outfit"
        newOutfit.value = 1
        newOutfit.arg1 = 1
        newOutfit.checked = false
        newOutfit.func = Tmog_NewOutfitPopup
        UIDropDownMenu_AddButton(newOutfit)
    end

    for name, data in pairs(TMOG_PLAYER_OUTFITS) do
        local info = {}
        info.text = name
        info.value = name
        info.arg1 = name
        info.checked = Tmog.currentOutfit == name
        info.func = Tmog_LoadOutfit
        info.tooltipTitle = name
        local descText, slotName = "", ""

        for slot, itemID in pairs(data) do
            Tmog:CacheItem(itemID)

            for k, v in pairs(Tmog.inventorySlots) do
                if v == slot then
                    slotName = k
                end
            end

            if slotName then
                slotName = TEXT(getglobal(strupper(slotName)))
                Tmog:CacheItem(itemID)
                local itemName, _, quality = GetItemInfo(itemID)

                if itemName then

                    if quality then
                        local _, _, _, color = GetItemQualityColor(quality)
                        if color then
                            descText = descText..YELLOW..slotName..":|r "..color.. itemName.."|r\n"
                        else
                            descText = descText..YELLOW..slotName..":|r ".. itemName.."|r\n"
                        end
                    else
                        descText = descText..YELLOW..slotName..":|r ".. itemName.."|r\n"
                    end
                end
            end
        end

        info.tooltipText = descText
        UIDropDownMenu_AddButton(info)
    end
end

function Tmog_TypeDropDown_Initialize()
    if Tmog.currentSlot == 1 or
        Tmog.currentSlot == 5 or
        Tmog.currentSlot == 8
        then
        Tmog.currentTypesList = Tmog.typesMisc

    elseif Tmog.currentSlot == 15 then
        Tmog.currentTypesList = Tmog.typesBack

    elseif Tmog.currentSlot == 4 or Tmog.currentSlot == 19 then
        Tmog.currentTypesList = Tmog.typesShirt

    elseif Tmog.currentSlot == 10 or
            Tmog.currentSlot == 6 or
            Tmog.currentSlot == 7 or
            Tmog.currentSlot == 3 or
            Tmog.currentSlot == 9
        then
        Tmog.currentTypesList = Tmog.typesDefault

    elseif Tmog.currentSlot == 16 then
        Tmog.currentTypesList = Tmog.typesMh

    elseif Tmog.currentSlot == 17 then
        Tmog.currentTypesList = Tmog.typesOh

    elseif Tmog.currentSlot == 18 then
        Tmog.currentTypesList = Tmog.typesRanged
    end
    
    for _, v in pairs(Tmog.currentTypesList) do
        local info = {}
        info.text = v
        info.arg1 = v
        info.checked = Tmog.currentType == v
        info.func = Tmog_SelectType
        if Tmog.onlyUsable then
            if SetContains(GetTableForClass(playerClass), v) then
                if not (not Tmog.canDualWeild and Tmog.currentSlot == 17 and v ~= "Shields" and v ~= "Miscellaneous") then
                    UIDropDownMenu_AddButton(info)
                end
            end
        else
            UIDropDownMenu_AddButton(info)
        end
    end
end

function Tmog:CacheItem(linkOrID)
    if not linkOrID or linkOrID == 0 then
        return
    end

    if tonumber(linkOrID) then
        if GetItemInfo(linkOrID) then
            return true
        else
            local item = "item:" .. linkOrID .. ":0:0:0"
            local _, _, itemLink = strfind(item, "(item:%d+:%d+:%d+:%d+)")

            linkOrID = itemLink
        end
    else
        if type(linkOrID) ~= "string" then
            return
        end
        if strfind(linkOrID, "|", 1, true) then
            local _, _, itemLink = strfind(linkOrID, "(item:%d+:%d+:%d+:%d+)")

            linkOrID = itemLink

            if GetItemInfo(Tmog:IDFromLink(linkOrID)) then
                return true
            end
        end
    end

    GameTooltip:SetHyperlink(linkOrID)
end

function Tmog:tableSize(t)
    if type(t) ~= "table" then
        return 0
    end
    local size = 0
    for _ in pairs(t) do
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
    if not link then
        return nil
    end
    local _, _, id = strfind(link, "item:(%d+)")
    if id then
        return tonumber(id)
    end
    return nil
end

function Tmog_ImportOutfit(outfit)
    Tmog.currentOutfit = nil
    TmogFrameSaveOutfit:Disable()
    TmogFrameDeleteOutfit:Disable()
    UIDropDownMenu_SetText("Outfits", TmogFrameOutfitsDropDown)

    TmogFramePlayerModel:Undress()

    for _, InventorySlotId in pairs(Tmog.inventorySlots) do
        Tmog.currentGear[InventorySlotId] = 0
    end

    for slot, itemID in pairs(outfit) do
        Tmog:CacheItem(itemID)
        Tmog.currentGear[slot] = itemID
        TmogFramePlayerModel:TryOn(itemID)
    end

    Tmog:UpdateItemTextures()
end

function Tmog_ImportOutfit_OnClick()
    StaticPopup_Show("TMOG_IMPORT_OUTFIT")
end

function Tmog_ShareOutfit_OnClick()
    local code = "T.O.L."

    for slot, id in pairs(TMOG_PLAYER_OUTFITS[Tmog.currentOutfit]) do
        code = code..slot..":"..id..";"
    end

    TmogFrameShareDialog:Show()
    TmogFrameShareDialogEditBox:SetText(code)
    TmogFrameShareDialogEditBox:HighlightText()
end

function Tmog:ValidateOutfitCode(code)
    local signature = strfind(code, "T.O.L.", 1, true)
    if signature then
        code = string.sub(code, signature)
        code = strtrim(code)
    else
        return nil
    end

    code = string.sub(code, 7)

    if strfind(code, "[^%d:;]") then
        return nil
    end

    local slotItemPairs = strsplit(code, ";")
    local outfit = {}
    local slot, item

    for i = 1, Tmog:tableSize(slotItemPairs) do
        _, _, slot, item = strfind(slotItemPairs[i], "(%d+):(%d+)")
        slot = tonumber(slot)
        item = tonumber(item)
        AddToSet(outfit, slot, item)
    end

    for invSlot, itemID in pairs(outfit) do
        Tmog:CacheItem(itemID)
        local _, _, _, _, itemType, itemSubType, _, loc  = GetItemInfo(itemID)
        if not itemType or not itemSubType or not loc then
            return nil
        end
        if itemType ~= "Armor" and itemType ~= "Weapon" then
            return nil
        end
        if not SetContains(InventoryTypeToSlot, loc, invSlot) and not (invSlot == 17 and loc == "INVTYPE_WEAPON") then
            return nil
        end
    end

    return outfit
end

local function sortfunc(a, b)
    -- equal quality - sort by name
    if a[3] == b[3] then
        return a[2] < b[2]
    else
        -- otherwise sort by quality
        return a[3] > b[3]
    end
end

local sortResult = {}

function Tmog:Sort(unsorted)
    if not unsorted then
        return {}
    end

    for i = getn(sortResult), 1, -1 do
        tremove(sortResult, i)
    end

    for id, name in pairs(unsorted) do
        Tmog:CacheItem(id)
        local _, _, quality = GetItemInfo(id)
        tinsert(sortResult, { id, name, quality })
    end

    table.sort(sortResult, sortfunc)

    return sortResult
end

function TmogFrameFullScreenModel_OnLoad()
    this:SetLight(unpack(FSLight))
    this:SetModelScale(1)
    this:SetScript("OnMouseUp", function()
        this:SetScript("OnUpdate", nil)
    end)

    this:SetScript("OnMouseWheel", function()
        local Z, X, Y = this:GetPosition()
        Z = (arg1 > 0 and Z + 0.4 or Z - 0.4)
        this:SetPosition(Z, X, Y)
    end)

    this:SetScript("OnMouseDown", function()
        local StartX, StartY = GetCursorPosition()
        local EndX, EndY, Z, X, Y

        if arg1 == "LeftButton" then
            this:SetScript("OnUpdate", function()
                EndX, EndY = GetCursorPosition()
                this:SetFacing((EndX - StartX) / 34 + this:GetFacing())
                StartX, StartY = GetCursorPosition()
            end)

        elseif arg1 == "RightButton" then
            this:SetScript("OnUpdate", function()
                EndX, EndY = GetCursorPosition()

                Z, X, Y = this:GetPosition()
                X = (EndX - StartX) / 180 + X
                Y = (EndY - StartY) / 180 + Y

                this:SetPosition(Z, X, Y)
                StartX, StartY = GetCursorPosition()
            end)
        end
    end)
end

function TmogFrameFullScreenModel_OnShow()
    UIFrameFadeIn(this, 0.3, 0, 1)
    showingHelm = ShowingHelm()
    showingCloak = ShowingCloak()
    this:SetWidth(GetScreenWidth()+5)
    this:SetHeight(GetScreenHeight()+5)
    this:SetUnit("player")
    this:SetFacing(0)
    this:SetPosition(-3, 0, 0)
    this:Undress()
    for slot, itemID in pairs(Tmog.currentGear) do
        if slot ~= 18 and slot ~= 17 and slot ~= 16 then
            if (slot == 1 and showingHelm == 1) or
                (slot == 1 and showingHelm ~= 1 and Tmog.actualGear[1] ~= Tmog.currentGear[1]) or
                (slot == 15 and showingCloak == 1) or
                (slot == 15 and showingCloak ~= 1 and Tmog.actualGear[15] ~= Tmog.currentGear[15]) or
                (slot ~= 1 and slot ~= 15)
            then
                this:TryOn(itemID)
            end
        end
    end
    this:TryOn(Tmog.currentGear[18])
    this:TryOn(Tmog.currentGear[16])
    this:TryOn(Tmog.currentGear[17])
end

function Tmog_FS_OnUpdate()
    if not this.fade then
        return
    end
    if (GetTime() - this.fade) > 0.3 then
        this.fade = nil
        this:Hide()
    end
end

function TmogFrameFullScreen_OnKeyDown()
    local screenshotKey = GetBindingKey("SCREENSHOT")
    if arg1 == "ESCAPE" then
        this:SetScript("OnKeyDown", nil)
        this.fade = GetTime()
        UIFrameFadeOut(TmogFrameFullScreenModel, 0.3, 1, 0)
    elseif screenshotKey and (arg1 == screenshotKey) then
        RunBinding("SCREENSHOT")
    end
end

local debugState = debug
local pendingIDs = {}
local requestInterval = 10
local tick = requestInterval

local keysdeleted = 0
local namesrestored = 0
local sharedadded = 0

local function RepairStop()
    tmog_debug(format("Cache Repair Finished: bad items deleted: %d, item names restored: %d, missing shared items added: %d", keysdeleted, namesrestored, sharedadded))
    debug = debugState
    Tmog:SetScript("OnUpdate", nil)
end

local function OnUpdate()
    if tick > GetTime() then
        return
    else
        tick = GetTime() + requestInterval
    end
    if not next(pendingIDs) then
        RepairStop()
        return
    end
    for id, tbl in pairs(pendingIDs) do
        local value = tbl.value
        if type(value) == "string" then
            TMOG_CACHE[tbl.slot][id] = value
            pendingIDs[id] = nil
            namesrestored = namesrestored + 1
            if not next(pendingIDs) then
                RepairStop()
                return
            end
        else
            if value > 5 then
                TMOG_CACHE[tbl.slot][id] = nil
                pendingIDs[id] = nil
                keysdeleted = keysdeleted + 1
                if not next(pendingIDs) then
                    RepairStop()
                    return
                end
            else
                tmog_debug("bad item "..id..": requesting info from server, try #"..tonumber(value))
                Tmog:CacheItem(id)
                pendingIDs[id].value = (GetItemInfo(id)) or (value + 1)
            end
        end
    end
end


function Tmog:RepairPlayerCache()
    local pending = false
    keysdeleted = 0
    namesrestored = 0
    sharedadded = 0
    tmog_debug("Cache Repair Started")
    for slot in pairs(TMOG_CACHE) do
        for id, name in pairs(TMOG_CACHE[slot]) do
            Tmog:CacheItem(id)
            if type(id) ~= "number" then
                TMOG_CACHE[slot][id] = nil
                keysdeleted = keysdeleted + 1
            elseif name == true then
                pendingIDs[id] = { slot = slot, value = 1 }
                if not Tmog:GetScript("OnUpdate") then
                    Tmog:SetScript("OnUpdate", OnUpdate)
                    pending = true
                end
            end
        end
    end
    for slot in pairs(TMOG_CACHE) do
        for itemID in pairs(TMOG_CACHE[slot]) do
            if SetContains(DisplayIdDB, itemID) then
                for _, id in pairs(DisplayIdDB[itemID]) do
                    Tmog:CacheItem(id)
                    local name = GetItemInfo(id) or true
                    if not SetContains(TMOG_CACHE[slot], id, name) then
                        AddToSet(TMOG_CACHE[slot], id, name)
                        sharedadded = sharedadded + 1
                    end
                end
            end
        end
    end
    if not pending then
        tmog_debug(format("Cache Repair Finished: bad items deleted: %d, item names restored: %d, missing shared items added: %d", keysdeleted, namesrestored, sharedadded))
        debug = debugState
    end
end

SLASH_TMOG1 = "/tmog"
SlashCmdList["TMOG"] = function(msg)
    local cmd = strtrim(msg)
    cmd = strlower(cmd)

    if strfind(cmd, "show$") then
        TmogFrame_Toggle()

    elseif strfind(cmd, "reset$") then
        TmogButton:ClearAllPoints()
        TmogButton:SetPoint("CENTER", UIParent, 0, 0)

    elseif strfind(cmd, "lock$") then
        TmogButton:SetMovable(not TmogButton:IsMovable())
        TMOG_LOCKED = not TMOG_LOCKED
        if not TMOG_LOCKED then
            print("minimap button unlocked")
        else
            print("minimap button locked")
        end

    elseif strfind(cmd, "debug$") then
        debug = not debug
        if debug then
            print("debug is on")
        else
            print("debug is off")
        end

    elseif strfind(cmd, "db$") then
        debug = true
        Tmog:RepairPlayerCache()
    else
        print(YELLOW.."/tmog show|r"..WHITE.." - toggle dressing room|r")
        print(YELLOW.."/tmog reset|r"..WHITE.." - reset minimap button position|r")
        print(YELLOW.."/tmog lock|r"..WHITE.." - lock/unlock minimap button|r")
        print(YELLOW.."/tmog debug|r"..WHITE.." - print debug messages in chat|r")
        print(YELLOW.."/tmog db|r"..WHITE.." - attempt to repair this character's cache (can fix minor bugs)|r")
    end
end
