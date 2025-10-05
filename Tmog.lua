-- Dressing room code - modified CosminPOP's Turtle_TransmogUI
-- Tooltip code - adapted from https://github.com/Zebouski/MoPGearTooltips/tree/masterturtle
local _G = _G or getfenv(0)
local tinsert = table.insert
local tremove = table.remove
local concat = table.concat
local getn = table.getn
local strfind = string.find
local strlower = string.lower
local format = string.format
local strsub = string.sub
local gsub = string.gsub
local GetItemInfo = GetItemInfo

local NORMAL = NORMAL_FONT_COLOR_CODE
local WHITE = HIGHLIGHT_FONT_COLOR_CODE
local GREY = GRAY_FONT_COLOR_CODE
local YELLOW = "|cffFFFF00"
local GREEN = "|cff00A000"
local BLUE = "|cff0070de"

local _, playerClass = UnitClass("player")
local _, playerRace = UnitRace("player")

local L = Tmog.L

Tmog.version = GetAddOnMetadata("Tmog", "Version")
Tmog.race = strlower(playerRace)
Tmog.currentType = L["Cloth"]
Tmog.currentTab = "ITEMS"

Tmog.currentSlot = nil
Tmog.currentOutfit = nil
Tmog.selectedButton = nil

Tmog.sex = UnitSex("player") - 1 -- 2 - female, 1 - male
Tmog.currentPage = 1
Tmog.totalPages = 1
Tmog.itemsPerPage = 15
Tmog.loadingTimeMax = 2

Tmog.verbose = false
Tmog.collected = true
Tmog.notCollected = true
Tmog.onlyUsable = false
Tmog.ignoreLevel = false
Tmog.flush = true
Tmog.canDualWeild = playerClass == "WARRIOR" or playerClass == "HUNTER" or playerClass == "ROGUE"

Tmog.PreviewButtons = {}
Tmog.CurrentGear = {}
Tmog.ActualGear = {} -- actual gear + transmog
Tmog.SharedItemsFrames = {}

Tmog.DressOrder = { 1, 3, 4, 5, 6, 7, 8, 9, 10, 15, 18, 16, 17, 19 } -- equip ranged first, then main hand, then offhand

Tmog.playerModelLight = 	{ 1, 0, -0.3, -1, -1,   0.55, 1.0, 1.0, 1.0,   0.8, 1.0, 1.0, 1.0 }
Tmog.previewNormalLight = 	{ 1, 0, -0.3,  0, -1,   0.65, 1.0, 1.0, 1.0,   0.8, 1.0, 1.0, 1.0 }
Tmog.previewHighlight = 	{ 1, 0, -0.3,  0, -1,   0.9,  1.0, 1.0, 1.0,   0.8, 1.0, 1.0, 1.0 }
Tmog.fullScreenLight = 		{ 1, 0, -0.5, -1, -0.7, 0.42, 1.0, 1.0, 1.0,   0.8, 1.0, 1.0, 1.0 }

Tmog.TooltipsToHook = {
	["GameTooltip"] = true,
	["TmogTooltip"] = true,
	["AtlasLootTooltip"] = true,
	["AtlasLootTooltip2"] = true,
	["ItemRefTooltip"] = true,
}

-- these slots change type together
local LinkedSlots = {
	[1] = true,
	[3] = true,
	[5] = true,
	[6] = true,
	[7] = true,
	[8] = true,
	[9] = true,
	[10] = true
}

local InventorySlots = {
	["HeadSlot"] = 1,
	["ShoulderSlot"] = 3,
	["ShirtSlot"] = 4,
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
}

Tmog.classEquipTable = {
	DRUID = {
		[L["Cloth"]] = true,
		[L["Leather"]] = true,
		[L["Daggers"]] = true,
		[L["One-Handed Maces"]] = true,
		[L["Fist Weapons"]] = true,
		[L["Two-Handed Maces"]] = true,
		[L["Polearms"]] = true,
		[L["Staves"]] = true,
		[L["Miscellaneous"]] = true,
	},
	SHAMAN = {
		[L["Cloth"]] = true,
		[L["Leather"]] = true,
		[L["Mail"]] = true,
		[L["Daggers"]] = true,
		[L["One-Handed Axes"]] = true,
		[L["One-Handed Maces"]] = true,
		[L["Fist Weapons"]] = true,
		[L["Two-Handed Axes"]] = true,
		[L["Two-Handed Maces"]] = true,
		[L["Staves"]] = true,
		[L["Shields"]] = true,
		[L["Miscellaneous"]] = true,
	},
	PALADIN = {
		[L["Cloth"]] = true,
		[L["Leather"]] = true,
		[L["Mail"]] = true,
		[L["Plate"]] = true,
		[L["One-Handed Axes"]] = true,
		[L["One-Handed Swords"]] = true,
		[L["One-Handed Maces"]] = true,
		[L["Two-Handed Axes"]] = true,
		[L["Two-Handed Swords"]] = true,
		[L["Two-Handed Maces"]] = true,
		[L["Polearms"]] = true,
		[L["Shields"]] = true,
		[L["Miscellaneous"]] = true,
	},
	MAGE = {
		[L["Cloth"]] = true,
		[L["Staves"]] = true,
		[L["Daggers"]] = true,
		[L["One-Handed Swords"]] = true,
		[L["Wands"]] = true,
		[L["Miscellaneous"]] = true,
	},
	WARLOCK = {
		[L["Cloth"]] = true,
		[L["Staves"]] = true,
		[L["Daggers"]] = true,
		[L["One-Handed Swords"]] = true,
		[L["Wands"]] = true,
		[L["Miscellaneous"]] = true,
	},
	PRIEST = {
		[L["Cloth"]] = true,
		[L["Staves"]] = true,
		[L["Daggers"]] = true,
		[L["One-Handed Maces"]] = true,
		[L["Wands"]] = true,
		[L["Miscellaneous"]] = true,
	},
	WARRIOR = {
		[L["Cloth"]] = true,
		[L["Leather"]] = true,
		[L["Mail"]] = true,
		[L["Plate"]] = true,
		[L["Daggers"]] = true,
		[L["Fist Weapons"]] = true,
		[L["Staves"]] = true,
		[L["One-Handed Axes"]] = true,
		[L["One-Handed Swords"]] = true,
		[L["One-Handed Maces"]] = true,
		[L["Two-Handed Axes"]] = true,
		[L["Two-Handed Swords"]] = true,
		[L["Two-Handed Maces"]] = true,
		[L["Polearms"]] = true,
		[L["Shields"]] = true,
		[L["Bows"]] = true,
		[L["Guns"]] = true,
		[L["Crossbows"]] = true,
		[L["Miscellaneous"]] = true,
	},
	ROGUE = {
		[L["Cloth"]] = true,
		[L["Leather"]] = true,
		[L["Daggers"]] = true,
		[L["Fist Weapons"]] = true,
		[L["One-Handed Axes"]] = true,
		[L["One-Handed Swords"]] = true,
		[L["One-Handed Maces"]] = true,
		[L["Bows"]] = true,
		[L["Guns"]] = true,
		[L["Crossbows"]] = true,
		[L["Miscellaneous"]] = true,
	},
	HUNTER = {
		[L["Cloth"]] = true,
		[L["Leather"]] = true,
		[L["Mail"]] = true,
		[L["Daggers"]] = true,
		[L["Fist Weapons"]] = true,
		[L["Staves"]] = true,
		[L["One-Handed Axes"]] = true,
		[L["One-Handed Swords"]] = true,
		[L["Two-Handed Axes"]] = true,
		[L["Two-Handed Swords"]] = true,
		[L["Polearms"]] = true,
		[L["Bows"]] = true,
		[L["Guns"]] = true,
		[L["Crossbows"]] = true,
		[L["Miscellaneous"]] = true,
	}
}

local Positions = {
	[1] = {
		bloodelf = { { 10.8,  0,   -3.4, 0.61, }, { 8.8,  0.2, -2.7, 0.61, }, },
		scourge =  { { 6.8,   0,   -2.2, 0.61, }, { 7.8, -0.5, -2.7, 0.61, }, },
		orc =      { { 8.8,   0,   -2.7, 0.2,  }, { 9.1,  0,   -2.7, 0.61, }, },
		gnome =    { { 3.8,   0,   -1,   0.61, }, { 3.8,  0,   -1,   0.61, }, },
		dwarf =    { { 6.3,   0,   -1.2, 0.61, }, { 6.3,  0,   -1.7, 0.61, }, },
		tauren =   { { 8.8,  -0.5, -2.2, 0.3,  }, { 8.8, -0.5, -1.7, 0.61, }, },
		nightelf = { { 11.8,  0,   -3.7, 0.61, }, { 11.8, 0,   -3.2, 0.61, }, },
		human =    { { 8.8,   0,   -3.2, 0.61, }, { 7.8,  0,   -2.7, 0.61, }, },
		troll =	   { { 10.8, -0.5, -2.2, 0.3,  }, { 11.1, 0,   -3,   0.61, }, },
		goblin =   { { 5.3,   0,   -1.3, 0.61, }, { 6.3,  0,   -0.7, 0.61, }, },
	},
	[3] = {
		bloodelf = { { 7.8, 0.5, -2.7, 0.61, }, { 7.8, 0.5, -2.2, 0.61, }, },
		scourge =  { { 5.8, 0.5, -1.7, 0.61, }, { 6.8, 0,   -1.7, 0.61, }, },
		orc =      { { 5.3, 0.5, -1.7, 0.61, }, { 6.3, 0.5, -1.7, 0.61, }, },
		gnome =    { { 2.8, 0.5, -0.2, 0.61, }, { 2.8, 0.5, -0.2, 0.61, }, },
		dwarf =    { { 4.8, 0.5, -0.9, 0.61, }, { 4.8, 0.2, -0.9, 0.61, }, },
		tauren =   { { 5.3, 0.5, -2.2, 0.61, }, { 5.8, 0.5, -1.7, 0.61, }, },
		nightelf = { { 8.8, 0.5, -2.2, 0.61, }, { 8.8, 0.5, -1.7, 0.61, }, },
		human =    { { 5.8, 0.5, -1.7, 0.61, }, { 5.8, 0.5, -1.7, 0.61, }, },
		troll =	   { { 7.8, 0.5, -1.7, 0.61, }, { 9.1, 0.5, -1.7, 0.61, }, },
		goblin =   { { 4.3, 0.5, -0.2, 0.61, }, { 4.8, 0.5, -0.2, 0.61, }, },
	},
	[5] = {
		bloodelf = { { 7.8,  0.1, -1.2, 0.3, }, { 6.8,  0.3, -1.2, 0.3, }, },
		scourge =  { { 5.8,  0.1, -1.2, 0.3, }, { 5.8,  0.1, -1.2, 0.3, }, },
		orc =      { { 5.8,  0.1, -1.2, 0.3, }, { 6.8,  0.1, -0.7, 0.3, }, },
		gnome =    { { 3.8,  0.1,  0.6, 0.3, }, { 3.8,  0.1,  0.6, 0.3, }, },
		dwarf =    { { 4.5,  0.1,  0.3, 0.3, }, { 4.5,  0.1,  0.3, 0.3, }, },
		tauren =   { { 5.8, -0.1, -0.2, 0.3, }, { 5.8, -0.1, -0.2, 0.3, }, },
		nightelf = { { 8.8,  0.1, -1.2, 0.3, }, { 8.8,  0.1, -1.2, 0.3, }, },
		human =    { { 5.8,  0.1, -1.2, 0.3, }, { 5.8,  0.1, -1.2, 0.3, }, },
		troll =	   { { 7.8, -0.1, -0.2, 0.3, }, { 7.8, -0.1, -0.2, 0.3, }, },
		goblin =   { { 4.3,  0.1,  0.3, 0.3, }, { 4.8,  0.1,  0.3, 0.3, }, },
	},
	[6] = {
		bloodelf = { { 10, 0, -0.6, 0.31, }, { 8.3, 0.3, -0.4, 0.31, }, },
		scourge =  { { 8,  0, -0.4, 0.31, }, { 8,   0,   -0.4, 0.31, }, },
		orc =      { { 8,  0, -0.4, 0.31, }, { 8,   0,   -0.4, 0.31, }, },
		gnome =    { { 4,  0,  1.1, 0.31, }, { 4,   0,	1.1, 0.31, }, },
		dwarf =    { { 5,  0,  0.6, 0.31, }, { 5,   0,	0.6, 0.31, }, },
		tauren =   { { 9,  0, -0.1, 0.31, }, { 8,   0,	1.6, 0.31, }, },
		nightelf = { { 10, 0, -0.4, 0.31, }, { 10,  0,   -0.4, 0.31, }, },
		human =    { { 7,  0, -0.4, 0.31, }, { 7,   0,   -0.9, 0.31, }, },
		troll =	   { { 10, 0, -0.4, 0.31, }, { 10,  0,   -0.4, 0.31, }, },
		goblin =   { { 6,  0,  1.1, 0.31, }, { 7,   0,	1.1, 0.31, }, },
	},
	[7] = {
		bloodelf = { { 7.8, 0, 0.6, 0.31, }, { 5.8, 0.3, 0.9, 0.31, }, },
		scourge =  { { 5.8, 0, 0.9, 0.31, }, { 7.1, 0,   0.9, 0.31, }, },
		orc =      { { 5.8, 0, 0.9, 0.31, }, { 5.8, 0,   0.9, 0.31, }, },
		gnome =    { { 3.8, 0, 1.1, 0.31, }, { 3.8, 0,   1.1, 0.31, }, },
		dwarf =    { { 4.8, 0, 1.4, 0.31, }, { 4.8, 0,   1.4, 0.31, }, },
		tauren =   { { 6.8, 0, 0.9, 0.31, }, { 5.8, 0,   1.9, 0.31, }, },
		nightelf = { { 8.8, 0, 0.9, 0.31, }, { 8.8, 0,   0.9, 0.31, }, },
		human =    { { 5.8, 0, 0.9, 0.31, }, { 5.8, 0,   0.9, 0.31, }, },
		troll =	   { { 7.8, 0, 0.9, 0.31, }, { 7.8, 0,   1.9, 0.31, }, },
		goblin =   { { 4.9, 0, 1.2, 0.31, }, { 5.3, 0,   0.9, 0.31, }, },
	},
	[8] = {
		bloodelf = { { 8.8, -0.3, 1.5, 1.2,  }, { 6.3,  0.4, 1.7, 0,	}, },
		scourge =  { { 5.8,  0,   1.5, 0.61, }, { 7.1,  0,   1.5, 0.61, }, },
		orc =      { { 5.8,  0,   1.5, 0.61, }, { 5.8,  0,   1.5, 0.61, }, },
		gnome =    { { 4.8,  0,   1.4, 0.61, }, { 4.3,  0.1, 1.4, 0.61, }, },
		dwarf =    { { 4.8,  0,   2.1, 0.61, }, { 5.3, -0.2, 1.9, 0.1,  }, },
		tauren =   { { 6.8,  0,   1.5, 0.61, }, { 6.8,  0,   2.5, 0.61, }, },
		nightelf = { { 8.8,  0,   1.8, 0.3,  }, { 8.8,  0,   1.8, 0.3,  }, },
		human =    { { 6.8,  0,   1.5, 0.3,  }, { 5.8,  0,   1.5, 0.61, }, },
		troll =	   { { 7.8,  0,   1.5, 0.61, }, { 8.8,  0,   2.5, 0.61, }, },
		goblin =   { { 4.8,  0,   1.8, 1.2,  }, { 5.3,  0,   1.5, 0.61, }, },
	},
	[9] = {
		bloodelf = { { 8.8,  0.4, -0.3, 1.5, }, { 7.3,  0.4, -0.3, 1.5, }, },
		scourge =  { { 5.8,  0.4, -0.3, 1.5, }, { 7.1, -0.1, -0.3, 1.5, }, },
		orc =      { { 5.8,  0.4, -0.3, 1.5, }, { 6.3,  0.4, -0.3, 1.5, }, },
		gnome =    { { 4.3,  0.4,  0.7, 1.5, }, { 4.3,  0.4,  0.7, 1.5, }, },
		dwarf =    { { 4.6,  0.1,  0.8, 1.5, }, { 5.2,  0.1,  0.6, 1.5, }, },
		tauren =   { { 5.8,  0.2, -0.3, 1.5, }, { 7.1,  0.2,  1,   1.5, }, },
		nightelf = { { 10.8, 0.4, -0.3, 1.5, }, { 10.8, 0.4, -0.3, 1.5, }, },
		human =    { { 6.8,  0.4, -0.3, 1.5, }, { 5.8,  0.4, -0.3, 1.5, }, },
		troll =	   { { 7.8,  0.4,  0.6, 1.5, }, { 9.8,  0.4,  0.6, 1.5, }, },
		goblin =   { { 4.8,  0.4,  1.2, 1.5, }, { 4.8,  0.4,  1.2, 1.5, }, },
	},
	[15] = {
		bloodelf = { { 7.8, -0.3, -1,   3.2, }, { 4.8, 0, -1,   3.2, }, },
		scourge =  { { 4.8, 0,	-1,   3.2, }, { 5.8, 0,  0,   3.2, }, },
		orc =      { { 4.8, 0,	-1,   3.2, }, { 4.8, 0, -0.2, 3.2, }, },
		gnome =    { { 2.8, 0,	 0.7, 3.2, }, { 2.8, 0,  0.7, 3.2, }, },
		dwarf =    { { 3.8, 0,	 0.5, 3.2, }, { 3.8, 0,  0.5, 3.2, }, },
		tauren =   { { 5.6, 0,	 0.2, 3.2, }, { 5.6, 0,  0.2, 3.2, }, },
		nightelf = { { 7.8, 0,	-1,   3.2, }, { 7.8, 0, -1,   3.2, }, },
		human =    { { 4.8, 0,	-1,   3.2, }, { 4.8, 0, -1,   3.2, }, },
		troll =	   { { 6.8, 0,	-1,   3.2, }, { 7.8, 0,  0,   3.2, }, },
		goblin =   { { 3.8, 0,	 0.5, 3.2, }, { 4.3, 0,  0.5, 3.2, }, },
	},
	[16] = {
		bloodelf = { { 6.8, 0, 0.4, 0.61, }, { 6.3, 0.2, 0.4, 0.61, }, },
		scourge =  { { 3.8, 0, 0.4, 0.61, }, { 3.8, 0, 0.4,   0.61, }, },
		orc =      { { 3.8, 0, 0.4, 0.61, }, { 4.8, 0, 0.4,   0.61, }, },
		gnome =    { { 1.8, 0, 0.4, 0.61, }, { 1.8, 0, 0.4,   0.61, }, },
		dwarf =    { { 2.8, 0, 0.4, 0.61, }, { 2.8, 0, 0.4,   0.61, }, },
		tauren =   { { 3.8, 0, 0.4, 0.61, }, { 3.8, 0, 0.4,   0.61, }, },
		nightelf = { { 6.8, 0, 0.4, 0.61, }, { 6.8, 0, 0.4,   0.61, }, },
		human =    { { 3.8, 0, 0.4, 0.61, }, { 3.8, 0, 0.4,   0.61, }, },
		troll =	   { { 5.8, 0, 1.4, 0.61, }, { 5.8, 0, 0.4,   0.61, }, },
		goblin =   { { 3.3, 0, 0.9, 0.9,  }, { 3.3, 0, 0.4,   0.61, }, },
	},
	[18] = {
		bloodelf = { { 6.8, 0, 0.4, -0.61, }, { 6.3, 0.2, 0.4, -1,	}, },
		scourge =  { { 3.8, 0, 0.4, -0.61, }, { 3.8, 0,   0.4, -0.61, }, },
		orc =      { { 3.8, 0, 0.4, -0.61, }, { 4.8, 0,   0.4, -0.61, }, },
		gnome =    { { 1.8, 0, 0.4, -0.61, }, { 1.8, 0,   0.4, -0.61, }, },
		dwarf =    { { 2.8, 0, 0.4, -0.61, }, { 2.8, 0,   0.4, -0.61, }, },
		tauren =   { { 3.8, 0, 0.4, -0.61, }, { 3.8, 0,   0.4, -0.61, }, },
		nightelf = { { 6.8, 0, 0.4, -0.61, }, { 6.8, 0,   0.4, -0.61, }, },
		human =    { { 3.8, 0, 0.4, -0.61, }, { 3.8, 0,   0.4, -0.61, }, },
		troll =	   { { 5.8, 0, 1.4, -0.61, }, { 5.8, 0,   0.4, -0.61, }, },
		goblin =   { { 3.3, 0, 0.9, -0.61, }, { 3.3, 0,   0.4, -0.61, }, },
	},
}
Positions[4] = Positions[5]
Positions[19] = Positions[5]
Positions[10] = Positions[9]
Positions[17] = Positions[16]

if not UIDropDownMenu_CreateInfo then
	local info = {}
	UIDropDownMenu_CreateInfo = function()
		for k in pairs(info) do
			info[k] = nil
		end
		return info
	end
end

Tmog.dropdownTypes = {
	default = {
		L["Cloth"],
		L["Leather"],
		L["Mail"],
		L["Plate"],
	},
	misc = {
		L["Cloth"],
		L["Leather"],
		L["Mail"],
		L["Plate"],
		L["Miscellaneous"],
	},
	back = {
		L["Cloth"],
	},
	shirt = {
		L["Miscellaneous"],
	},
	mh = {
		L["Daggers"],
		L["One-Handed Axes"],
		L["One-Handed Swords"],
		L["One-Handed Maces"],
		L["Fist Weapons"],
		L["Polearms"],
		L["Staves"],
		L["Two-Handed Axes"],
		L["Two-Handed Swords"],
		L["Two-Handed Maces"],
	},
	oh = {
		L["Daggers"],
		L["One-Handed Axes"],
		L["One-Handed Swords"],
		L["One-Handed Maces"],
		L["Fist Weapons"],
		L["Miscellaneous"],
		L["Shields"],
	},
	ranged = {
		L["Bows"],
		L["Guns"],
		L["Crossbows"],
		L["Wands"],
	},
}

function Tmog.GetTypesForSlot(slot)
	local types
	if slot == 1 or slot == 5 or slot == 8 then
		types = Tmog.dropdownTypes.misc
	elseif slot == 15 then
		types = Tmog.dropdownTypes.back
	elseif slot == 4 or slot == 19 then
		types = Tmog.dropdownTypes.shirt
	elseif slot == 10 or slot == 6 or slot == 7 or slot == 3 or slot == 9 then
		types = Tmog.dropdownTypes.default
	elseif slot == 16 then
		types = Tmog.dropdownTypes.mh
	elseif slot == 17 then
		types = Tmog.dropdownTypes.oh
	elseif slot == 18 then
		types = Tmog.dropdownTypes.ranged
	end
	return types
end

-- table for checking transmog status
local StatusSlotsLookup = {}

-- store last selected type for each slot
local SlotTypesMemory = {}

-- store last selected page for each slot and type
local PagesMemory = {}

-- items for preview buttons
local DrawTable = {}

-- bad items for "Ony Usable" check box
local Unusable = {}

for _, slot in pairs(InventorySlots) do
	local types = Tmog.GetTypesForSlot(slot)
	PagesMemory[slot] = {}
	DrawTable[slot] = {}
	Unusable[slot] = {}
	StatusSlotsLookup[slot] = true
	SlotTypesMemory[slot] = types[1]
	for _, type in ipairs(types) do
		PagesMemory[slot][type] = 1
		DrawTable[slot][type] = {}
		Unusable[slot][type] = {}
	end
	DrawTable[slot]["SearchResult"] = {}
	Unusable[slot]["SearchResult"] = {}
end

function Tmog.print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("["..BLUE.."Tmog|r] "..tostring(msg))
end

function Tmog.debug(...)
	if not Tmog.verbose then
		return
	end
	local size = getn(arg)
	for i = 1, size do
		arg[i] = tostring(arg[i])
	end
	local msg = size > 1 and concat(arg, ", ") or tostring(arg[1])
	local time = GetTime()
	DEFAULT_CHAT_FRAME:AddMessage("["..BLUE.."Tmog|r]["..GREY..format("%.3f", time).."|r] "..msg)
	return msg, time
end

local function strsplit(str, delimiter)
	local splitresult = {}
	local from = 1
	local delim_from, delim_to = strfind(str, delimiter, from, true)
	while delim_from do
		tinsert(splitresult, strsub(str, from, delim_from - 1))
		from = delim_to + 1
		delim_from, delim_to = strfind(str, delimiter, from, true)
	end
	tinsert(splitresult, strsub(str, from))
	return splitresult
end

local function strtrim(s)
	return gsub(s or "", "^%s*(.-)%s*$", "%1")
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
		for k, v in pairs(set) do
			if v == value then
				return k
			end
		end
	end
	if key and not value then
		return set[key] ~= nil
	end
	return set[key] == value
end

local function tsize(t)
	if type(t) ~= "table" then
		return 0
	end
	local size = 0
	for _ in pairs(t) do
		size = size + 1
	end
	return size
end

function Tmog.InventorySlotFromItemID(itemID)
	if not itemID then
		return nil
	end
	local _, _, _, _, _, _, _, slot  = GetItemInfo(itemID)
	return InventoryTypeToSlot[slot or ""]
end

function Tmog.IDFromLink(link)
	if not link then
		return nil
	end
	local _, _, id = strfind(link, "item:(%d+)")
	return tonumber(id)
end

local IDcache = {}
function Tmog.GetItemIDByName(name)
	if not name then
		return nil
	end
	if IDcache[name] then
		if IDcache[name] ~= 0 then
			return IDcache[name]
		else
			return nil
		end
	end
	for itemID = 1, 99999 do
		local itemName = GetItemInfo(itemID)
		if itemName and itemName == name then
			IDcache[name] = itemID
			return itemID
		end
	end
	IDcache[name] = 0
	return nil
end

local insideHook = false
local tooltipMoney = 0
local HookSetTooltipMoney = SetTooltipMoney
function SetTooltipMoney(frame, money)
	if insideHook then
		tooltipMoney = money or 0
	else
		HookSetTooltipMoney(frame, money)
	end
end

function Tmog.HookTooltip(tooltip)
	Tmog.debug("hooking tooltip", tooltip)

	local HookSetLootRollItem    = tooltip.SetLootRollItem
	local HookSetLootItem        = tooltip.SetLootItem
	local HookSetMerchantItem    = tooltip.SetMerchantItem
	local HookSetQuestLogItem    = tooltip.SetQuestLogItem
	local HookSetQuestItem       = tooltip.SetQuestItem
	local HookSetHyperlink       = tooltip.SetHyperlink
	local HookSetBagItem         = tooltip.SetBagItem
	local HookSetInboxItem       = tooltip.SetInboxItem
	local HookSetInventoryItem   = tooltip.SetInventoryItem
	local HookSetCraftItem       = tooltip.SetCraftItem
	local HookSetCraftSpell      = tooltip.SetCraftSpell
	local HookSetTradeSkillItem  = tooltip.SetTradeSkillItem
	local HookSetAuctionItem     = tooltip.SetAuctionItem
	local HookSetAuctionSellItem = tooltip.SetAuctionSellItem
	local HookSetTradePlayerItem = tooltip.SetTradePlayerItem
	local HookSetTradeTargetItem = tooltip.SetTradeTargetItem

	local original_OnHide = tooltip:GetScript("OnHide")
	tooltip:SetScript("OnHide", function()
		if original_OnHide then
			original_OnHide()
		end
		this.itemID = nil
		tooltipMoney = 0
	end)

	local IDFromLink = Tmog.IDFromLink
	local GetItemIDByName = Tmog.GetItemIDByName
	local ExtendTooltip = Tmog.ExtendTooltip

	function tooltip.SetLootRollItem(self, id)
		insideHook = true
		HookSetLootRollItem(self, id)
		insideHook = false
		self.itemID = IDFromLink(GetLootRollItemLink(id))
		ExtendTooltip(self)
	end

	function tooltip.SetLootItem(self, slot)
		insideHook = true
		HookSetLootItem(self, slot)
		insideHook = false
		self.itemID = IDFromLink(GetLootSlotLink(slot))
		ExtendTooltip(self)
	end

	function tooltip.SetMerchantItem(self, merchantIndex)
		insideHook = true
		HookSetMerchantItem(self, merchantIndex)
		insideHook = false
		self.itemID = IDFromLink(GetMerchantItemLink(merchantIndex))
		ExtendTooltip(self)
	end

	function tooltip.SetQuestLogItem(self, itemType, index)
		insideHook = true
		HookSetQuestLogItem(self, itemType, index)
		insideHook = false
		self.itemID = IDFromLink(GetQuestLogItemLink(itemType, index))
		ExtendTooltip(self)
	end

	function tooltip.SetQuestItem(self, itemType, index)
		insideHook = true
		HookSetQuestItem(self, itemType, index)
		insideHook = false
		self.itemID = IDFromLink(GetQuestItemLink(itemType, index))
		ExtendTooltip(self)
	end

	function tooltip.SetHyperlink(self, arg1)
		insideHook = true
		HookSetHyperlink(self, arg1)
		insideHook = false
		self.itemID = IDFromLink(arg1)
		ExtendTooltip(self)
	end

	function tooltip.SetBagItem(self, container, slot)
		insideHook = true
		local hasCooldown, repairCost = HookSetBagItem(self, container, slot)
		insideHook = false
		self.itemID = IDFromLink(GetContainerItemLink(container, slot))
		ExtendTooltip(self)
		return hasCooldown, repairCost
	end

	function tooltip.SetInboxItem(self, mailID, attachmentIndex)
		insideHook = true
		HookSetInboxItem(self, mailID, attachmentIndex)
		insideHook = false
		self.itemID = GetItemIDByName(GetInboxItem(mailID))
		ExtendTooltip(self)
	end

	function tooltip.SetInventoryItem(self, unit, slot)
		insideHook = true
		local hasItem, hasCooldown, repairCost = HookSetInventoryItem(self, unit, slot)
		insideHook = false
		self.itemID = IDFromLink(GetInventoryItemLink(unit, slot))
		ExtendTooltip(self)
		return hasItem, hasCooldown, repairCost
	end

	function tooltip.SetCraftItem(self, skill, slot)
		insideHook = true
		HookSetCraftItem(self, skill, slot)
		insideHook = false
		self.itemID = IDFromLink(GetCraftReagentItemLink(skill, slot))
		ExtendTooltip(self)
	end

	function tooltip.SetCraftSpell(self, slot)
		insideHook = true
		HookSetCraftSpell(self, slot)
		insideHook = false
		self.itemID = IDFromLink(GetCraftItemLink(slot))
		ExtendTooltip(self)
	end

	function tooltip.SetTradeSkillItem(self, skillIndex, reagentIndex)
		insideHook = true
		HookSetTradeSkillItem(self, skillIndex, reagentIndex)
		insideHook = false
		if reagentIndex then
			self.itemID = IDFromLink(GetTradeSkillReagentItemLink(skillIndex, reagentIndex))
		else
			self.itemID = IDFromLink(GetTradeSkillItemLink(skillIndex))
		end
		ExtendTooltip(self)
	end

	function tooltip.SetAuctionItem(self, atype, index)
		insideHook = true
		HookSetAuctionItem(self, atype, index)
		insideHook = false
		self.itemID = IDFromLink(GetAuctionItemLink(atype, index))
		ExtendTooltip(self)
	end

	function tooltip.SetAuctionSellItem(self)
		insideHook = true
		HookSetAuctionSellItem(self)
		insideHook = false
		self.itemID = GetItemIDByName(GetAuctionSellItemInfo())
		ExtendTooltip(self)
	end

	function tooltip.SetTradePlayerItem(self, index)
		insideHook = true
		HookSetTradePlayerItem(self, index)
		insideHook = false
		self.itemID = IDFromLink(GetTradePlayerItemLink(index))
		ExtendTooltip(self)
	end

	function tooltip.SetTradeTargetItem(self, index)
		insideHook = true
		HookSetTradeTargetItem(self, index)
		insideHook = false
		self.itemID = IDFromLink(GetTradeTargetItemLink(index))
		ExtendTooltip(self)
	end
end

local TmogTooltip = CreateFrame("GameTooltip", "TmogTooltip", UIParent, "GameTooltipTemplate")
TmogTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

local TmogScanTooltip = CreateFrame("GameTooltip", "TmogScanTooltip", nil, "GameTooltipTemplate")
TmogScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

local originalTooltip = {}
-- return slot if this is gear and unit can equip it
function Tmog.GetTransmogSlot(itemID, unit, tooltip)
	itemID = tonumber(itemID)
	if not itemID then return nil end
	unit = unit or "player"
	local itemName, itemLink, itemQuality, itemLevel, itemType, itemSubType, itemCount, itemEquipLoc, itemTexture = GetItemInfo(itemID)
	if itemEquipLoc and itemEquipLoc ~= "" then
		local class, classEn = UnitClass(unit)
		local tableToCheck = Tmog.classEquipTable[classEn]
		Tmog.debug(itemID, itemName, itemType, itemSubType, itemEquipLoc)
		if itemEquipLoc == "INVTYPE_HOLDABLE" then
			return InventoryTypeToSlot[itemEquipLoc]
		end
		if tableToCheck[itemSubType] and InventoryTypeToSlot[itemEquipLoc] then
			if not (classEn == "WARRIOR" or classEn == "HUNTER" or classEn == "ROGUE") and itemEquipLoc == "INVTYPE_WEAPONOFFHAND" then
				Tmog.debug("cant dual weild")
				return nil
			end
			if itemType == L["Weapon"] and itemSubType == L["Miscellaneous"] then
				Tmog.debug("not a real weapon")
				return nil
			end
			-- check if its class restricted item
			for k in pairs(originalTooltip) do
				originalTooltip[k] = nil
			end
			if not tooltip then
				tooltip = TmogScanTooltip
				tooltip:ClearLines()
				tooltip:SetHyperlink("item:"..itemID)
			end
			local tooltipName = tooltip:GetName()
			for row = 1, 15 do
				local tooltipRowLeft = _G[tooltipName .. "TextLeft" .. row]
				if tooltipRowLeft then
					local rowtext = tooltipRowLeft:GetText()
					if rowtext then
						originalTooltip[row] = rowtext
					end
				end
			end
			for row = 1, tsize(originalTooltip) do
				if originalTooltip[row] then
					local _, _, classesRow = strfind(originalTooltip[row], (gsub(ITEM_CLASSES_ALLOWED, "%%s", "(.*)")))
					if classesRow then
						if not strfind(classesRow, class, 1, true) then
							Tmog.debug("bad class")
							return nil
						end
					end
				end
			end
			return InventoryTypeToSlot[itemEquipLoc]
		end
	end
end

-- Return true if item can be transmogged in general
do
	local cache = {}
	function Tmog.Transmogable(itemID)
		itemID = tonumber(itemID)
		if not itemID then return nil end
		if cache[itemID] then return cache[itemID] == 1 end
		local itemName, itemLink, itemQuality, itemLevel, itemType, itemSubType, itemCount, itemEquipLoc, itemTexture = GetItemInfo(itemID)
		if not itemName then return nil end
		if itemEquipLoc ~= "" and InventoryTypeToSlot[itemEquipLoc] then
			if (itemType == L["Weapon"] and itemSubType == L["Miscellaneous"]) or (itemSubType == L["Fishing Pole"]) then
				cache[itemID] = 0
				return false
			else
				cache[itemID] = 1
				return true
			end
		end
		return false
	end
end

do
	local cache = {}
	function Tmog.IsKnownAppearance(itemID)
		itemID = tonumber(itemID)
		if not itemID then return nil end
		if cache[itemID] then return cache[itemID] == 1 end
		for k, v in pairs(TmogGearDB) do
			for k2, v2 in pairs(v) do
				if v2[itemID] then
					cache[itemID] = 1
					return true
				end
			end
		end
		cache[itemID] = 0
		return false
	end
end

local WrappingLines = {
	["^Set:"] = gsub("^"..ITEM_SET_BONUS, "%%s", ""),
	["^%(%d%) Set:"] = gsub(gsub(ITEM_SET_BONUS_GRAY, "%(%%d%)", "^%%(%%d%%)"), "%%s", ""),
	["^Effect:"] = gsub("^"..ITEM_SPELL_EFFECT, "%%s", ""),
	["^Equip:"] = "^"..ITEM_SPELL_TRIGGER_ONEQUIP,
	["^Chance on hit:"] = "^"..ITEM_SPELL_TRIGGER_ONPROC,
	["^Use:"] = "^"..ITEM_SPELL_TRIGGER_ONUSE,
	["^\nRequires"] = "^\n"..gsub(ITEM_REQ_SKILL, "%%s", "")
}

local lines = {}
for i = 1, 30 do
	lines[i] = {}
end

local function AddCollectionStatus(slot, itemID, tooltip)
	local name = tooltip:GetName()
	local numLines = tooltip:NumLines()
	local left, right
	local leftText, rightText
	local rL, gL, bL
	local rR, gR, bR
	local status, wrap

	for i in pairs(lines) do
		for j in pairs(lines[i]) do
			lines[i][j] = nil
		end
	end

	for i = 1, numLines do
		left = _G[name .. "TextLeft" .. i]
		right = _G[name .. "TextRight" .. i]
		leftText = left:GetText()
		rightText = right:IsShown() and right:GetText()
		rL, gL, bL = left:GetTextColor()
		rR, gR, bR = right:GetTextColor()
		lines[i][1] = leftText
		lines[i][2] = rightText
		lines[i][3] = rL
		lines[i][4] = gL
		lines[i][5] = bL
		lines[i][6] = rR
		lines[i][7] = gR
		lines[i][8] = bR
	end

	if not lines[1][1] then
		return
	end

	if TMOG_CACHE[slot][itemID] then
		status = GREEN..L["Collected"].."|r"
	else
		status = YELLOW..L["Not collected"].."|r"
	end

	tooltip:SetText(lines[1][1], lines[1][3], lines[1][4], lines[1][5], 1, false)

	if numLines < 28 then
		tooltip:AddLine(status)
	elseif lines[2][1] then
		lines[2][1] = status.."\n"..lines[2][1]
	end

	for i = 2, getn(lines) do
		if lines[i][2] then
			tooltip:AddDoubleLine(lines[i][1], lines[i][2], lines[i][3], lines[i][4], lines[i][5], lines[i][6], lines[i][7], lines[i][8])
		else
			wrap = false
			if strsub(lines[i][1] or "", 1, 1) == "\"" then
				wrap = true
			else
				for _, pattern in pairs(WrappingLines) do
					if strfind(lines[i][1] or "", pattern) then
						wrap = true
						break
					end
				end
			end
			tooltip:AddLine(lines[i][1], lines[i][3], lines[i][4], lines[i][5], wrap)
		end
	end
end

local lastItemName = nil
local lastSlot = nil
function Tmog.ExtendTooltip(tooltip)
	local itemID = tonumber(tooltip.itemID)
	if itemID then
		local itemName = GetItemInfo(itemID)
		if itemName ~= lastItemName then
			local slot = Tmog.GetTransmogSlot(itemID, "player", tooltip)
			lastItemName = itemName
			lastSlot = slot
		end
		if lastSlot then
			AddCollectionStatus(lastSlot, itemID, tooltip)
		end
		if tooltip ~= TmogTooltip and Tmog.Transmogable(itemID) then
			local string
			if not DisplayIdDB[itemID] then
				if not Tmog.IsKnownAppearance(itemID) then
					string = NORMAL..L["Unknown appearance"].."|r"
				else
					string = NORMAL..L["Unique appearance"].."|r"
				end
			else
				string = NORMAL..L["Non-unique appearance"].."|r"
			end
			local numLines = tooltip:NumLines()
			if numLines < 30 then
				tooltip:AddLine(string)
			else
				local lastLine = _G[tooltip:GetName().."TextLeft"..numLines]
				lastLine:SetText(lastLine:GetText().."\n"..string)
			end
		end
		tooltip:Show()
	end
	if tooltipMoney > 0 then
		HookSetTooltipMoney(tooltip, tooltipMoney)
		tooltip:Show()
	end
end

local original_OnShow = GameTooltip:GetScript("OnShow")
GameTooltip:SetScript("OnShow", function()
	if original_OnShow then
		original_OnShow()
	end
	if aux_frame and aux_frame:IsShown() then
		local frame = GetMouseFocus()
		
		if not frame then return end

		local parent = frame:GetParent()
		
		if not (parent and parent.row and parent.row.record) then return end

		GameTooltip.itemID = tonumber(parent.row.record.item_id)
		Tmog.ExtendTooltip(GameTooltip)
	end
end)

-------------------------------
------- ITEM BROWSER ----------
-------------------------------
function TmogFrame_OnLoad()
	TmogFrame:RegisterEvent("ADDON_LOADED")
	TmogFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	TmogFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
	TmogFrame:RegisterEvent("CHAT_MSG_ADDON")

	TmogFrame:RegisterForDrag("LeftButton")

	TmogFrameRaceBackground:SetTexture("Interface\\AddOns\\Tmog\\Textures\\transmogbackground"..Tmog.race)

	TmogFrameSaveOutfit:Disable()
	TmogFrameDeleteOutfit:Disable()

	UIDropDownMenu_SetText(L["Outfits"], TmogFrameOutfitsDropDown)
	TmogFrameVersionText:SetText(Tmog.version)

	TmogFrameCollected:SetChecked(Tmog.collected)
	TmogFrameNotCollected:SetChecked(Tmog.notCollected)
	TmogFrameUsable:SetChecked(Tmog.onlyUsable)

	tinsert(UISpecialFrames, "TmogFrame")
end

local firstLoad = true
function TmogFrame_OnEvent()
	if event == "PLAYER_ENTERING_WORLD" then
		TmogFramePlayerModel:SetUnit("player")

		if firstLoad then
			Tmog.Reset()
			firstLoad = false
		end

		if TmogFrame:IsShown() then
			TmogFrame:Hide()
		end

		for tooltipName, doHook in pairs(Tmog.TooltipsToHook) do
			if doHook then
				local tooltip = _G[tooltipName]
				if tooltip then
					Tmog.HookTooltip(tooltip)
					Tmog.TooltipsToHook[tooltipName] = false
				end
			end
		end

		return
	end

	if event == "ADDON_LOADED" and arg1 == "Tmog" then
		TmogFrame:UnregisterEvent("ADDON_LOADED")

		-- Saved Variables
		TMOG_CACHE = TMOG_CACHE or {
			[1] = {},  -- HeadSlot
			[3] = {},  -- ShoulderSlot
			[4] = {},  -- ShirtSlot
			[5] = {},  -- ChestSlot
			[6] = {},  -- WaistSlot
			[7] = {},  -- LegsSlot
			[8] = {},  -- FeetSlot
			[9] = {},  -- WristSlot
			[10] = {}, -- HandsSlot
			[15] = {}, -- BackSlot
			[16] = {}, -- MainHandSlot
			[17] = {}, -- SecondaryHandSlot
			[18] = {}, -- RangedSlot
			[19] = {}, -- TabardSlot
		}
		for _, InventorySlotId in pairs(InventorySlots) do
			if not TMOG_CACHE[InventorySlotId] then
				TMOG_CACHE[InventorySlotId] = {}
			end
		end
		TMOG_PLAYER_OUTFITS = TMOG_PLAYER_OUTFITS or {}
		TMOG_TRANSMOG_STATUS = TMOG_TRANSMOG_STATUS or {}
		TMOG_POSITION = TMOG_POSITION or { 760, 600 }
		TMOG_LOCKED = TMOG_LOCKED or false

		UIDropDownMenu_Initialize(TmogFrameTypeDropDown, Tmog.TypeDropDown_Initialize)
		UIDropDownMenu_Initialize(TmogFrameOutfitsDropDown, Tmog.OutfitsDropDown_Initialize)
		UIDropDownMenu_SetWidth(100, TmogFrameTypeDropDown)
		UIDropDownMenu_SetWidth(115, TmogFrameOutfitsDropDown)

		TmogButton:SetMovable(not TMOG_LOCKED)
		TmogButton:ClearAllPoints()
		TmogButton:SetPoint("CENTER", UIParent, "BOTTOMLEFT", unpack(TMOG_POSITION or {TmogButton:GetCenter()}))

		return
	end

	if strfind(arg1, "TW_CHAT_MSG_WHISPER", 1, true) then
		Tmog.debug(arg1, arg2, arg3, arg4)
	end

	if event == "CHAT_MSG_ADDON" and strfind(arg1, "TW_TRANSMOG", 1, true) and arg4 == UnitName("player") then
		Tmog.debug(arg1, arg2, arg3, arg4)

		if strfind(arg2, "AvailableTransmogs", 1, true) then
			local data = strsplit(arg2, ":")
			local InventorySlotId = tonumber(data[2])

			for i = 4, getn(data) do
				local itemID = tonumber(data[i])
				if itemID then
					local itemName = GetItemInfo(itemID)

					if itemName then
						if not TMOG_CACHE[InventorySlotId][itemID] then
							AddToSet(TMOG_CACHE[InventorySlotId], itemID, itemName)
						end

						-- check if it shares appearance with other items and add those if it does
						if DisplayIdDB[itemID] then
							for _, id in pairs(DisplayIdDB[itemID]) do
								Tmog.CacheItem(id)
								local name = GetItemInfo(id)
								if not TMOG_CACHE[InventorySlotId][id] then
									AddToSet(TMOG_CACHE[InventorySlotId], id, name)
								end
							end
						end
					end
				end
			end

		elseif strfind(arg2, "NewTransmog", 1, true) then
			local _, _, itemID = strfind(arg2, "NewTransmog:(%d+)")
			itemID = tonumber(itemID)
			local slot = Tmog.InventorySlotFromItemID(itemID)
			local itemName = GetItemInfo(itemID)

			if slot and itemName then
				AddToSet(TMOG_CACHE[slot], itemID, itemName)

				-- check if it shares appearance with other items and add those if it does
				if DisplayIdDB[itemID] then
					for _, id in pairs(DisplayIdDB[itemID]) do
						Tmog.CacheItem(id)
						local name = GetItemInfo(id)
						if not SetContains(TMOG_CACHE[slot], id, name) then
							AddToSet(TMOG_CACHE[slot], id, name)
						end
					end
				end
			end

		elseif strfind(arg2, "TransmogStatus", 1, true) then
			local data = gsub(arg2, "TransmogStatus:", "")

			if data then
				local TransmogStatus = strsplit(data, ",")

				if not TMOG_TRANSMOG_STATUS then
					TMOG_TRANSMOG_STATUS = {}
				end

				for _, InventorySlotId in pairs(InventorySlots) do
					if not TMOG_TRANSMOG_STATUS[InventorySlotId] then
						TMOG_TRANSMOG_STATUS[InventorySlotId] = {}
					end
				end

				for k in pairs(StatusSlotsLookup) do
					StatusSlotsLookup[k] = true
				end

				for _, d in pairs(TransmogStatus) do
					local _, _, InventorySlotId, itemID = strfind(d, "(%d+):(%d+)")
					InventorySlotId = tonumber(InventorySlotId)
					if InventorySlotId and InventorySlotId ~= 0 then
						itemID = tonumber(itemID)
						local link = GetInventoryItemLink("player", InventorySlotId)
						local actualItemId = Tmog.IDFromLink(link) or 0
						StatusSlotsLookup[InventorySlotId] = false
						if actualItemId ~= 0 then
							TMOG_TRANSMOG_STATUS[InventorySlotId][actualItemId] = itemID
						end
					end
				end
				-- if we recieve 0 for some equipped item AND we have it in our TMOG_TRANSMOG_STATUS
				-- remove it from TMOG_TRANSMOG_STATUS
				for k in pairs(StatusSlotsLookup) do
					if StatusSlotsLookup[k] then
						local equippedItemLink = GetInventoryItemLink("player", k)
						local equippedItemID = Tmog.IDFromLink(equippedItemLink) or 0
						if equippedItemID ~= 0 and TMOG_TRANSMOG_STATUS[k][equippedItemID] then
							TMOG_TRANSMOG_STATUS[k][equippedItemID] = nil
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
				local itemID = Tmog.IDFromLink(link)

				if itemID then
					Tmog.CacheItem(itemID)
					local itemName = GetItemInfo(itemID)

					if not TMOG_CACHE[slot][itemID] then
						AddToSet(TMOG_CACHE[slot], itemID, itemName)
					end

					-- check if it shares appearance with other items and add those if it does
					if DisplayIdDB[itemID] then
						for _, id in pairs(DisplayIdDB[itemID]) do
							Tmog.CacheItem(id)
							local name = GetItemInfo(id)
							if not TMOG_CACHE[slot][id] then
								AddToSet(TMOG_CACHE[slot], id, name)
							end
						end
					end
				end
			end
		end

		return
	end
end

local cacheZ, cacheX, cacheY = 0, 0, 0
function TmogFrame_OnShow()
	TmogFramePlayerModel:SetPosition(cacheZ, cacheX, cacheY)
	Tmog.Dress(TmogFramePlayerModel)
	Tmog.DrawPreviews()
	Tmog.UpdateItemTextures()
	PlaySound("igCharacterInfoOpen")
end

function TmogFrame_OnHide()
	cacheZ, cacheX, cacheY = TmogFramePlayerModel:GetPosition()
	TmogFramePlayerModel:SetPosition(0,0,0)
	PlaySound("igCharacterInfoClose")
end

function Tmog.ResetPosition()
	TmogFramePlayerModel:SetPosition(0,0,0)
	TmogFramePlayerModel:SetFacing(0.3)
	cacheZ, cacheX, cacheY = TmogFramePlayerModel:GetPosition()
end

function TmogFramePlayerModel_OnLoad()
	TmogFramePlayerModel:SetFacing(0.3)
	cacheZ, cacheX, cacheY = TmogFramePlayerModel:GetPosition()
	TmogFramePlayerModel:SetLight(unpack(Tmog.playerModelLight))

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

function Tmog.Reset()
	Tmog.currentOutfit = nil
	TmogFrameSaveOutfit:Disable()
	TmogFrameDeleteOutfit:Disable()
	TmogFrameShareOutfit:Disable()
	UIDropDownMenu_SetText(L["Outfits"], TmogFrameOutfitsDropDown)

	TmogFramePlayerModel:SetPosition(0, 0, 0)
	TmogFramePlayerModel:Dress()
	TmogFramePlayerModel:SetPosition(cacheZ, cacheX, cacheY)

	-- Fix tabard
	local tabardLink = GetInventoryItemLink("player", 19)
	if tabardLink then
		TmogFramePlayerModel:TryOn(Tmog.IDFromLink(tabardLink))
	end

	for _, InventorySlotId in pairs(InventorySlots) do
		Tmog.CurrentGear[InventorySlotId] = 0
		local link = GetInventoryItemLink("player", InventorySlotId)
		if link then
			Tmog.ActualGear[InventorySlotId] = Tmog.IDFromLink(link)
		else
			Tmog.ActualGear[InventorySlotId] = 0
		end
	end

	for slot in pairs(TMOG_TRANSMOG_STATUS) do
		local link = GetInventoryItemLink("player", slot)
		local id = Tmog.IDFromLink(link) or 0

		for actualItemID, transmogID in pairs(TMOG_TRANSMOG_STATUS[slot]) do
			if actualItemID == id then
				Tmog.ActualGear[slot] = transmogID
			end
		end
	end

	for _, InventorySlotId in pairs(InventorySlots) do
		Tmog.CurrentGear[InventorySlotId] = Tmog.ActualGear[InventorySlotId]
	end

	Tmog.UpdateItemTextures()
	Tmog.RemoveSelection()
end

function Tmog.SelectType(typeStr)
	if TmogFrameSharedItems:IsShown() then
		TmogFrameSharedItems:Hide()
	end
	UIDropDownMenu_SetText(typeStr, TmogFrameTypeDropDown)
	Tmog.currentType = typeStr
	Tmog.currentPage = 1
	Tmog.flush = true
	if Tmog.currentSlot and Tmog.currentType and PagesMemory[Tmog.currentSlot][Tmog.currentType] then
		SlotTypesMemory[Tmog.currentSlot] = typeStr
		if LinkedSlots[Tmog.currentSlot] then
			for k in SlotTypesMemory do
				if LinkedSlots[k] and PagesMemory[k][typeStr] then
					SlotTypesMemory[k] = typeStr
				end
			end
		end
		Tmog.ChangePage(PagesMemory[Tmog.currentSlot][Tmog.currentType] - 1)
		return
	end

	Tmog.DrawPreviews()
end

function Tmog.HidePreviews()
	for index in pairs(Tmog.PreviewButtons) do
		local buttonName = Tmog.PreviewButtons[index]:GetName()
		_G[buttonName.."ItemModel"]:SetAlpha(0)
		_G[buttonName.."Button"]:Hide()
		_G[buttonName.."ButtonCheck"]:Hide()
	end
end

local function IsRed(tooltipLine)
	local r, g, b = _G[tooltipLine]:GetTextColor()
	if r > 0.9 and g < 0.2 and b < 0.2 then
		return true
	end
	return false
end

function Tmog.IsUsableItem(id)
	if Unusable[Tmog.currentSlot][Tmog.currentType][id] then
		return false
	end
	local isUsable = true
	for i = 2, 15 do
		_G["TmogScanTooltipTextLeft"..i]:SetTextColor(0,0,0)
		_G["TmogScanTooltipTextRight"..i]:SetTextColor(0,0,0)
	end
	TmogScanTooltip:ClearLines()
	TmogScanTooltip:SetHyperlink("item:"..id)
	for i = 2, 15 do
		local text = _G["TmogScanTooltipTextLeft"..i]:GetText() or ""
		if (IsRed("TmogScanTooltipTextLeft"..i) or IsRed("TmogScanTooltipTextRight"..i)) then
			if strfind(text, "^"..(gsub(ITEM_MIN_LEVEL, "%%d", ""))) then
				if not Tmog.ignoreLevel then
					isUsable = false
					Unusable[Tmog.currentSlot][Tmog.currentType][id] = true
				end
			else
				isUsable = false
				Unusable[Tmog.currentSlot][Tmog.currentType][id] = true
			end
		end
	end
	local _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(id)
	if not Tmog.canDualWeild and (itemEquipLoc == "INVTYPE_WEAPONOFFHAND" or (itemEquipLoc == "INVTYPE_WEAPON" and Tmog.currentSlot == 17)) then
		isUsable = false
		Unusable[Tmog.currentSlot][Tmog.currentType][id] = true
	end
	return isUsable
end

local LoadingFrame = CreateFrame("Frame", "TmogLoadingFrame")
LoadingFrame.queueIDs = {}
LoadingFrame.queueTimer = 0
LoadingFrame.dotStrings = { [0] = "", [1] = ".", [2] = "..", [3] = "..." }
LoadingFrame.dotCount = 0
LoadingFrame.dotTimer = 0.3

LoadingFrame:SetScript("OnUpdate", function()
	if this.queueTimer == 0 then
		TmogFrameLoadingTexture:Hide()
		return
	end

	if this.dotTimer <= 0 then
		this.dotCount = this.dotCount + 1
		if this.dotCount > 3 then
			this.dotCount = 0
		end
		TmogFrameLoadingTextureText:SetText(L["Loading"].." "..this.dotStrings[this.dotCount])
		this.dotTimer = 0.3
	else
		this.dotTimer = this.dotTimer - arg1
	end

	local allCached = true
	for id in pairs(this.queueIDs) do
		if not GetItemInfo(id) then
			allCached = false
		end
	end
	for _, frame in pairs(Tmog.PreviewButtons) do
		_G[frame:GetName().."Button"]:EnableMouse(false)
	end
	TmogFrameLoadingTexture:Show()
	if allCached or this.queueTimer < 0 then
		this.queueTimer = 0
		Tmog.DrawPreviews()
		TmogFrameLoadingTexture:Hide()
		for _, frame in pairs(Tmog.PreviewButtons) do
			_G[frame:GetName().."Button"]:EnableMouse(true)
		end
	else
		this.queueTimer = this.queueTimer - arg1
	end
end)

function Tmog.DrawPreviews(noDraw)
	local searchStr = TmogFrameSearchBox:GetText() or ""
	searchStr = strlower(searchStr)
	searchStr = strtrim(searchStr)
	local index = 0
	local row = 0
	local col = 0
	local itemIndex = 1
	local outfitIndex = 1
	local lowerLimit = (Tmog.currentPage - 1) * Tmog.itemsPerPage
	local upperLimit = Tmog.currentPage * Tmog.itemsPerPage
	local type = Tmog.currentType

	if Tmog.currentTab == "ITEMS" then
		if (not Tmog.collected and not Tmog.notCollected) or not Tmog.currentSlot then
			Tmog.HidePreviews()
			Tmog.HidePagination()
			Tmog.currentPage = 1
			return
		end

		if searchStr ~= "" then
			type = "SearchResult"
		end

		if Tmog.flush then
			Tmog.debug("flushing", "slot "..Tmog.currentSlot, " type "..type)
			for i = getn(DrawTable[Tmog.currentSlot][type]), 1, -1 do
				tremove(DrawTable[Tmog.currentSlot][type], i)
			end

			if type == "SearchResult" then
				for k in pairs(TmogGearDB[Tmog.currentSlot]) do
					for itemID in pairs(TmogGearDB[Tmog.currentSlot][k]) do
						if Tmog.CacheItem(itemID) then
							if strfind(strlower(GetItemInfo(itemID)), searchStr, 1 ,true) then
								tinsert(DrawTable[Tmog.currentSlot][type], itemID)
							end
						elseif not LoadingFrame.queueIDs[itemID] then
							LoadingFrame.queueTimer = Tmog.loadingTimeMax
							LoadingFrame.queueIDs[itemID] = true
						end
					end
				end
			else
				for itemID in pairs(TmogGearDB[Tmog.currentSlot][type]) do
					if Tmog.CacheItem(itemID) then
						tinsert(DrawTable[Tmog.currentSlot][type], itemID)
					elseif not LoadingFrame.queueIDs[itemID] then
						LoadingFrame.queueTimer = Tmog.loadingTimeMax
						LoadingFrame.queueIDs[itemID] = true
					end
				end
			end
			-- remove duplicates
			if type ~= "SearchResult" then
				for _, id in ipairs(DrawTable[Tmog.currentSlot][type]) do
					if DisplayIdDB[id] then
						for _, duplicate in pairs(DisplayIdDB[id]) do
							local i = tonumber(SetContains(DrawTable[Tmog.currentSlot][type], nil, duplicate))
							if i then
								tremove(DrawTable[Tmog.currentSlot][type], i)
							end
						end
					end
				end
			end
			if not Tmog.notCollected then
				for i = getn(DrawTable[Tmog.currentSlot][type]), 1, -1 do
					if not TMOG_CACHE[Tmog.currentSlot][DrawTable[Tmog.currentSlot][type][i]] then
						tremove(DrawTable[Tmog.currentSlot][type], i)
					end
				end
			elseif not Tmog.collected then
				for i = getn(DrawTable[Tmog.currentSlot][type]), 1, -1 do
					if TMOG_CACHE[Tmog.currentSlot][DrawTable[Tmog.currentSlot][type][i]] then
						tremove(DrawTable[Tmog.currentSlot][type], i)
					end
				end
			end
			-- if "usable" checked, remove unusable items
			if Tmog.onlyUsable then
				for i = getn(DrawTable[Tmog.currentSlot][type]), 1, -1 do
					if not Tmog.IsUsableItem(DrawTable[Tmog.currentSlot][type][i]) then
						tremove(DrawTable[Tmog.currentSlot][type], i)
					end
				end
			end
			Tmog.totalPages = ceil(getn(DrawTable[Tmog.currentSlot][type]) / Tmog.itemsPerPage)
			sort(DrawTable[Tmog.currentSlot][type], Tmog.Sort)
			if LoadingFrame.queueTimer > 0 then
				return
			end
		end

		-- nothing to show
		if not DrawTable[Tmog.currentSlot][type] or next(DrawTable[Tmog.currentSlot][type]) == nil then
			Tmog.HidePreviews()
			Tmog.HidePagination()
			Tmog.currentPage = 1
			return
		end

		if noDraw then
			Tmog.flush = false
			return
		end

		if Tmog.currentPage == Tmog.totalPages then
			Tmog.HidePreviews()
		end

		local frame, button

		for i = 1, getn(DrawTable[Tmog.currentSlot][type]) do
			local itemID = DrawTable[Tmog.currentSlot][type][i]
			local name, _, quality = GetItemInfo(itemID)
			name = name or TmogGearDB[Tmog.currentSlot][type][itemID]
			quality = quality or 1

			if index >= lowerLimit and index < upperLimit then
				if not Tmog.PreviewButtons[itemIndex] then
					Tmog.PreviewButtons[itemIndex] = CreateFrame("Frame", "TmogFramePreview" .. itemIndex, TmogFrame, "TmogFramePreviewTemplate")
					Tmog.PreviewButtons[itemIndex]:SetPoint("TOPLEFT", TmogFrame, "TOPLEFT", 263 + col * 90, -105 - 120 * row)
					_G["TmogFramePreview" .. itemIndex .. "ItemModel"]:SetLight(unpack(Tmog.previewNormalLight))
				end
				frame = Tmog.PreviewButtons[itemIndex]
				frame:Show()
				frame.name = name
				frame.id = itemID

				button = _G["TmogFramePreview"..itemIndex.."Button"]
				button:Show()
				button:SetID(itemID)

				Tmog.CacheItem(itemID)
				if TMOG_CACHE[Tmog.currentSlot][itemID] then
					_G["TmogFramePreview" .. itemIndex .. "ButtonCheck"]:Show()
				else
					_G["TmogFramePreview" .. itemIndex .. "ButtonCheck"]:Hide()
				end

				if itemID == Tmog.CurrentGear[Tmog.currentSlot] then
					button:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_selected")
				else
					button:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_normal")
				end

				local border = _G["TmogFramePreview" .. itemIndex .. "ButtonBorder"]
				local r, g, b = GetItemQualityColor(quality or 1)
				border:SetVertexColor(r, g, b)
				border:SetAlpha(0.4)
				if quality == 2 then
					border:SetAlpha(0.2)
				elseif quality == 0 then
					border:SetAlpha(0.1)
				end

				Tmog.AddItemTooltip(button)

				-- this is for updating tooltip while scrolling with mousewheel
				if GetMouseFocus() == button then
					button:Hide()
					button:Show()
				end

				local model = _G["TmogFramePreview" .. itemIndex .. "ItemModel"]
				local z = Positions[Tmog.currentSlot][Tmog.race][Tmog.sex][1]
				local x = Positions[Tmog.currentSlot][Tmog.race][Tmog.sex][2]
				local y = Positions[Tmog.currentSlot][Tmog.race][Tmog.sex][3]
				local f = Positions[Tmog.currentSlot][Tmog.race][Tmog.sex][4]
				model:SetPosition(0, 0, 0)
				model:SetUnit("player")
				model:Undress()
				model:SetPosition(z, x, y)
				model:SetFacing(f)

				-- oh / ranged
				if Tmog.currentSlot == 17 or Tmog.currentSlot == 18 then
					local _, _, _, _, _, _, _, loc  = GetItemInfo(itemID)
					if loc == "INVTYPE_RANGED" or loc == "INVTYPE_WEAPONOFFHAND" or loc == "INVTYPE_HOLDABLE" then
						model:SetFacing(-0.61)
						if Tmog.race == "bloodelf" then
							if Tmog.sex == 2 then
								model:SetFacing(-1)
							end
						end
					else
						model:SetFacing(0.61)
						if Tmog.race == "goblin" then
							if Tmog.sex == 1 then
								model:SetFacing(0.9)
							end
						end
					end
					-- shield
					if loc == "INVTYPE_SHIELD" then
						model:SetFacing(-1.5)
						if Tmog.race == "scourge" then
							if Tmog.sex == 2 then
								model:SetFacing(-1)
								z = z + 2
								y = y - 0.5
							end
						end
						if Tmog.race == "goblin" then
							if Tmog.sex == 2 then
								x = x - 0.3
							end
							z = z + 0.2
						end
						if Tmog.race == "orc" then
							if Tmog.sex == 2 then
								x = x - 0.8
							end
						end
						if Tmog.race == "nightelf"then
							x = x - 0.3
							y = y - 1
						end
						if Tmog.race == "bloodelf" then
							y = y - 1
						end
						model:SetPosition(z, x, y)
					end
				end

				model:TryOn(itemID)
				model:SetAlpha(1)

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

		local size = getn(DrawTable[Tmog.currentSlot][type])
		Tmog.totalPages = ceil(size / Tmog.itemsPerPage)
		TmogFramePageText:SetText(GENERIC_PAGE.." " .. Tmog.currentPage .. "/" .. Tmog.totalPages)

		if Tmog.currentPage == 1 then
			TmogFrameLeftArrow:Disable()
			TmogFrameFirstPage:Disable()
		else
			TmogFrameLeftArrow:Enable()
			TmogFrameFirstPage:Enable()
		end

		if Tmog.currentPage == Tmog.totalPages or size < Tmog.itemsPerPage then
			TmogFrameRightArrow:Disable()
			TmogFrameLastPage:Disable()
		else
			TmogFrameRightArrow:Enable()
			TmogFrameLastPage:Enable()
		end
		Tmog.flush = false

	elseif Tmog.currentTab == "OUTFITS" then
		if noDraw then
			return
		end

		Tmog.HidePreviews()

		local frame, button
		-- big plus button
		if Tmog.currentPage == 1 then
			if not Tmog.PreviewButtons[1] then
				Tmog.PreviewButtons[1] = CreateFrame("Frame", "TmogFramePreview1", TmogFrame, "TmogFramePreviewTemplate")
				Tmog.PreviewButtons[1]:SetPoint("TOPLEFT", TmogFrame, "TOPLEFT", 263 , -105)
			end

			frame = Tmog.PreviewButtons[1]
			frame:Show()

			frame.name = L["New outfit"]

			button = TmogFramePreview1Button
			button:Show()
			button:SetID(0)
			button:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_normal")

			TmogFramePreview1ButtonPlus:Show()
			TmogFramePreview1ButtonPlusPushed:Hide()
			TmogFramePreview1ItemModel:SetAlpha(0)
			Tmog.AddOutfitTooltip(button, frame.name)
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

			if index >= lowerLimit and index < upperLimit and outfitIndex <= Tmog.itemsPerPage then
				if not Tmog.PreviewButtons[outfitIndex] then
					Tmog.PreviewButtons[outfitIndex] = CreateFrame("Frame", "TmogFramePreview" .. outfitIndex, TmogFrame, "TmogFramePreviewTemplate")
					Tmog.PreviewButtons[outfitIndex]:SetPoint("TOPLEFT", TmogFrame, "TOPLEFT", 263 + col * 90, -105 - 120 * row)
					_G["TmogFramePreview" .. outfitIndex .. "ItemModel"]:SetLight(unpack(Tmog.previewNormalLight))
				end
				frame = Tmog.PreviewButtons[outfitIndex]
				frame:Show()
				frame.name = name

				button = _G["TmogFramePreview" .. outfitIndex .. "Button"]
				button:Show()
				button:SetID(outfitIndex)

				if name == Tmog.currentOutfit then
					button:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_selected")
				else
					button:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_normal")
				end

				Tmog.AddOutfitTooltip(button, name)

				local model = _G["TmogFramePreview" .. outfitIndex .. "ItemModel"]
				model:SetPosition(0, 0, 0)
				model:SetUnit("player")
				model:Undress()
				model:SetFacing(0.3)
				model:SetPosition(1.5, 0, 0)
				model:SetAlpha(1)

				local collectedAll = true
				for slot, itemID in pairs(TMOG_PLAYER_OUTFITS[name]) do
					model:TryOn(itemID)
					if collectedAll then
						if not TMOG_CACHE[slot][itemID] then
							collectedAll = false
						end
					end
				end

				if collectedAll then
					_G["TmogFramePreview" .. outfitIndex .. "ButtonCheck"]:Show()
				else
					_G["TmogFramePreview" .. outfitIndex .. "ButtonCheck"]:Hide()
				end

				_G["TmogFramePreview" .. outfitIndex .. "ButtonBorder"]:SetAlpha(0.4)
				_G["TmogFramePreview" .. outfitIndex .. "ButtonBorder"]:SetVertexColor(1, 0.82, 0)

				col = col + 1
				if col == 5 then
					row = row + 1
					col = 0
				end
				outfitIndex = outfitIndex + 1
			end
			index = index + 1
		end

		local size = tsize(TMOG_PLAYER_OUTFITS) + 1
		Tmog.totalPages = ceil(size / Tmog.itemsPerPage)
		TmogFramePageText:SetText(GENERIC_PAGE.." " .. Tmog.currentPage .. "/" .. Tmog.totalPages)

		if Tmog.currentPage == 1 then
			TmogFrameLeftArrow:Disable()
			TmogFrameFirstPage:Disable()
		else
			TmogFrameLeftArrow:Enable()
			TmogFrameFirstPage:Enable()
		end

		if (Tmog.currentPage == Tmog.totalPages) or (size < Tmog.itemsPerPage) then
			TmogFrameRightArrow:Disable()
			TmogFrameLastPage:Disable()
		else
			TmogFrameRightArrow:Enable()
			TmogFrameLastPage:Enable()
		end
	end

	if Tmog.totalPages > 1 then
		Tmog.ShowPagination()
	else
		Tmog.HidePagination()
	end
end

function Tmog.ShowPagination()
	TmogFrameLeftArrow:Show()
	TmogFrameRightArrow:Show()
	TmogFramePageText:Show()
	TmogFrameFirstPage:Show()
	TmogFrameLastPage:Show()
end

function Tmog.HidePagination()
	TmogFrameLeftArrow:Hide()
	TmogFrameRightArrow:Hide()
	TmogFramePageText:Hide()
	TmogFrameFirstPage:Hide()
	TmogFrameLastPage:Hide()
end

function Tmog.ChangePage(dir, destination)
	if TmogFrameLoadingTexture:IsShown() then
		return
	end

	if not Tmog.currentPage or not Tmog.totalPages then
		return
	end

	if Tmog.currentTab == "ITEMS" and not Tmog.currentSlot then
		return
	end
	-- get total pages
	Tmog.DrawPreviews(1)

	if (Tmog.currentPage + dir < 1) or (Tmog.currentPage + dir > Tmog.totalPages) then
		return
	end

	if destination then
		if destination == "LAST" then
			dir = Tmog.totalPages - Tmog.currentPage
		elseif destination == "FIRST" then
			dir = 1 - Tmog.currentPage
		end
	end

	Tmog.currentPage = Tmog.currentPage + dir
	Tmog.DrawPreviews()

	if Tmog.currentTab == "ITEMS" then
		PagesMemory[Tmog.currentSlot][Tmog.currentType] = Tmog.currentPage
	end

	if TmogFrameSharedItems:IsShown() then
		TmogFrameSharedItems:Hide()
	end
end

function Tmog.RemoveSelection()
	if Tmog.currentTab == "OUTFITS" then

		if Tmog.currentPage ~= 1 then
			TmogFramePreview1ButtonPlus:Hide()
			TmogFramePreview1ButtonPlusPushed:Hide()
		end

		for index = 1, tsize(Tmog.PreviewButtons) do
			_G["TmogFramePreview"..index.."Button"]:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_normal")
		end

	elseif Tmog.currentTab == "ITEMS" then

		for index = 1, tsize(Tmog.PreviewButtons) do
			if Tmog.PreviewButtons[index].id ~= Tmog.CurrentGear[Tmog.currentSlot] then
				_G["TmogFramePreview"..index.."Button"]:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_normal")
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
		Tmog.LinkItem(Tmog.CurrentGear[InventorySlotId])

	elseif rightClick then

		if Tmog.CurrentGear[InventorySlotId] == 0 then
			if Tmog.ActualGear[InventorySlotId] == 0 then
				return
			end
			TmogFramePlayerModel:TryOn(Tmog.ActualGear[InventorySlotId])
			Tmog.CurrentGear[InventorySlotId] = Tmog.ActualGear[InventorySlotId]
			Tmog.ToggleOutfitButtons()
			Tmog.UpdateItemTextures()
			if Tmog.currentTab == "ITEMS" then
				Tmog.RemoveSelection()
			end
		else
			Tmog.UndressSlot(InventorySlotId)
		end
		--update tooltip
		this:Hide()
		this:Show()
		PlaySound("igMainMenuOptionCheckBoxOn")
	else
		Tmog.currentSlot = InventorySlotId
		Tmog.flush = true
		if Tmog.currentTab == "OUTFITS" then
			if _G[this:GetName().."BorderFull"]:IsShown() then
				Tmog.SwitchTab("ITEMS")
				Tmog.Search()
				return
			else
				Tmog.SwitchTab("ITEMS")
			end
		end

		Tmog.HidePagination()
		UIDropDownMenu_Initialize(TmogFrameTypeDropDown, Tmog.TypeDropDown_Initialize)
		TmogFrameSearchBox:Show()
		Tmog.currentType = SlotTypesMemory[InventorySlotId]

		if not _G[this:GetName().."BorderFull"]:IsShown() then
			Tmog.HideBorders()
			_G[this:GetName().."BorderFull"]:Show()
			-- shirt / tabard / cloak
			if InventorySlotId == 4 or InventorySlotId == 19 or InventorySlotId == 15 then
				TmogFrameTypeDropDown:Hide()
			else
				TmogFrameTypeDropDown:Show()
			end
		else
			TmogFrameTypeDropDown:Hide()
			Tmog.HideBorders()
			Tmog.currentSlot = nil
			TmogFrameSearchBox:Hide()
			PlaySound("InterfaceSound_LostTargetUnit")
		end

		Tmog.Search()
		PlaySound("igCreatureAggroSelect")
	end
	DropDownList1:Hide()
end

function Tmog.UpdateItemTextures()
	for slotName, InventorySlotId in pairs(InventorySlots) do
		local frame = _G["TmogFrame"..slotName]
		local icon = _G[frame:GetName() .. "ItemIcon"]
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
			if GetInventoryItemLink("player", InventorySlotId) or GetItemInfo(Tmog.CurrentGear[InventorySlotId]) then
				local _, _, _, _, _, _, _, _, tex = GetItemInfo(Tmog.CurrentGear[InventorySlotId])

				if tex then
					icon:SetTexture(tex)
				end
			end
		end
	end
end

local SharedItems = {}
function TmogTry(itemId, mouseButton, noSelect)
	mouseButton = mouseButton or arg1
	if mouseButton == "LeftButton" then

		if Tmog.currentTab == "ITEMS" then

			if IsShiftKeyDown() then
				Tmog.LinkItem(itemId)
			else
				if Tmog.currentSlot == 16 then
					Tmog.UndressSlot(Tmog.currentSlot)
				end
				TmogFramePlayerModel:TryOn(itemId)
				Tmog.CurrentGear[Tmog.currentSlot] = itemId
				Tmog.ToggleOutfitButtons()
				Tmog.UpdateItemTextures()
				Tmog.RemoveSelection()
				if not noSelect then
					this:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_selected")
				else
					Tmog.selectedButton:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_selected")
				end
				PlaySound("igMainMenuOptionCheckBoxOn")
			end

			if TmogFrameSharedItems:IsShown() then
				TmogFrameSharedItems:Hide()
			end

		elseif Tmog.currentTab == "OUTFITS" then

			if this:GetID() == 0 then
				Tmog.NewOutfitPopup()
				return
			end

			local outfit = Tmog.PreviewButtons[this:GetID()].name
			if IsShiftKeyDown() then
				Tmog.LinkOutfit(outfit)
				return
			end
			Tmog.currentOutfit = outfit

			Tmog.LoadOutfit(outfit)
			Tmog.RemoveSelection()
			this:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_selected")
			PlaySound("igMainMenuOptionCheckBoxOn")
		end

	elseif mouseButton == "RightButton" then

		if Tmog.currentTab ~= "ITEMS" then
			TmogFrameSharedItems:Hide()
			return
		end

		Tmog.selectedButton = this

		for i = 1, tsize(Tmog.SharedItemsFrames) do
			Tmog.SharedItemsFrames[i]:Hide()
		end

		TmogFrameSharedItems:ClearAllPoints()
		TmogFrameSharedItems:SetPoint("TOPLEFT", this, "BOTTOMLEFT", -2, 12)

		for k in pairs(SharedItems) do
			SharedItems[k] = nil
		end
		local index = 1

		if DisplayIdDB[itemId] then

			for _, id in pairs(DisplayIdDB[itemId]) do

				Tmog.CacheItem(id)
				local name, _, quality, _, _, _, _, _, tex = GetItemInfo(id)

				if name and quality then
					local r, g, b = GetItemQualityColor(quality)
					if not (Tmog.onlyUsable and not Tmog.IsUsableItem(id)) then
						SharedItems[index] = {name = "", id = 0, color = { r = 0, g = 0, b = 0 }, tex = ""}
						SharedItems[index].name = name
						SharedItems[index].id = id
						SharedItems[index].color.r = r
						SharedItems[index].color.g = g
						SharedItems[index].color.b = b
						SharedItems[index].tex = tex
						index = index + 1
					end
				end
			end
		end

		if not next(SharedItems) then
			TmogFrameSharedItems:Hide()
			return
		end

		if TmogFrameSharedItems:IsShown() then
			TmogFrameSharedItems:Hide()
		else
			TmogFrameSharedItems:Show()
		end

		local widestText = 0

		for i = 1, tsize(SharedItems) do

			if not Tmog.SharedItemsFrames[i] then
				Tmog.SharedItemsFrames[i] = CreateFrame("Button", "TmogFrameSharedItem"..i, TmogFrameSharedItems, "TmogSharedItemTemplate")
			end

			Tmog.SharedItemsFrames[i]:Show()
			Tmog.SharedItemsFrames[i]:SetID(SharedItems[i].id)
			Tmog.SharedItemsFrames[i]:SetPoint("TOPLEFT", TmogFrameSharedItems, 10 , -10 - ((i - 1) * 20))

			TmogFrameSharedItems:SetHeight(40 + (i - 1) * 20)

			_G["TmogFrameSharedItem"..i.."IconTexture"]:SetTexture(SharedItems[i].tex)
			_G["TmogFrameSharedItem"..i.."Name"]:SetText(SharedItems[i].name)
			_G["TmogFrameSharedItem"..i.."Name"]:SetTextColor(SharedItems[i].color.r, SharedItems[i].color.g, SharedItems[i].color.b)

			local width = _G["TmogFrameSharedItem"..i.."Name"]:GetStringWidth()

			if width > widestText then
				widestText = width
			end

			Tmog.AddSharedItemTooltip(Tmog.SharedItemsFrames[i])
		end

		TmogFrameSharedItems:SetWidth(45 + widestText)
	end

	DropDownList1:Hide()
end

function Tmog.AddSharedItemTooltip(frame)
	local buttonText = _G[frame:GetName().."Name"]
	local originalR, originalG, originalB = buttonText:GetTextColor()

	frame:SetScript("OnEnter", function()
		TmogTooltip:SetOwner(this, "ANCHOR_LEFT", -(this:GetWidth() / 4) + 30, -(this:GetHeight() / 4))
		buttonText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)

		local itemID = this:GetID()

		Tmog.CacheItem(itemID)
		TmogTooltip.itemID = itemID
		TmogTooltip:SetHyperlink("item:"..tostring(itemID))
		local numLines = TmogTooltip:NumLines()

		if numLines and numLines > 0 then
			local lastLine = _G["TmogTooltipTextLeft"..numLines]
			if lastLine:GetText() then
				lastLine:SetText(lastLine:GetText().."\n\n"..NORMAL.."ItemID: "..itemID)
			end
		end

		TmogTooltip:Show()
	end)

	frame:SetScript("OnLeave", function()
		buttonText:SetTextColor(originalR, originalG, originalB)
		TmogTooltip:Hide()
		TmogTooltip.itemID = nil
	end)
end

function Tmog.LinkItem(itemId)
	if not itemId or itemId == 0 then
		return
	end

	Tmog.CacheItem(itemId)
	local itemName, _, quality = GetItemInfo(itemId)
	local _, _, _, color = GetItemQualityColor(quality)

	if WIM_EditBoxInFocus then
		WIM_EditBoxInFocus:Insert(color.."|Hitem:"..itemId..":0:0:0|h["..itemName.."]|h|r")
	elseif ChatFrameEditBox:IsShown() then
		ChatFrameEditBox:Insert(color.."|Hitem:"..itemId..":0:0:0|h["..itemName.."]|h|r")
	end
end

function Tmog.LinkOutfit(outfit)
	if not outfit or outfit == "" then
		return
	end

	local code = "T.O.L."
	for slot, id in pairs(TMOG_PLAYER_OUTFITS[outfit]) do
		code = code..slot..":"..id..";"
	end

	if WIM_EditBoxInFocus then
		WIM_EditBoxInFocus:Insert(code)
	elseif ChatFrameEditBox:IsShown() then
		ChatFrameEditBox:Insert(code)
	end
end

function Tmog.Dress(model)
	local showingHelm = ShowingHelm()
	local showingCloak = ShowingCloak()
	model:Undress()
	for _, slot in ipairs(Tmog.DressOrder) do
		if (slot == 1 and showingHelm == 1) or (slot == 1 and showingHelm ~= 1 and Tmog.ActualGear[1] ~= Tmog.CurrentGear[1]) or
			(slot == 15 and showingCloak == 1) or (slot == 15 and showingCloak ~= 1 and Tmog.ActualGear[15] ~= Tmog.CurrentGear[15]) or
			(slot ~= 1 and slot ~= 15)
		then
			model:TryOn(Tmog.CurrentGear[slot])
		end
	end
end

function Tmog.Undress()
	TmogFramePlayerModel:Undress()

	for _, InventorySlotId in pairs(InventorySlots) do
		Tmog.CurrentGear[InventorySlotId] = 0
	end

	Tmog.UpdateItemTextures()
	Tmog.ToggleOutfitButtons()

	if Tmog.currentTab == "ITEMS" then
		Tmog.RemoveSelection()
	end
end

function Tmog.UndressSlot(InventorySlotId)
	TmogFramePlayerModel:Undress()
	for slot, itemID in pairs(Tmog.CurrentGear) do
		if slot ~= InventorySlotId and slot ~= 18 then
			if (slot == 1 and ShowingHelm() == 1) or (slot == 15 and ShowingCloak() == 1) or
				(Tmog.CurrentGear[slot] ~= Tmog.ActualGear[slot]) or (slot ~= 1 and slot ~= 15)
				then
				TmogFramePlayerModel:TryOn(itemID)
			end
		end
	end
	Tmog.CurrentGear[InventorySlotId] = 0
	Tmog.ToggleOutfitButtons()
	Tmog.UpdateItemTextures()
	if Tmog.currentTab == "ITEMS" then
		Tmog.RemoveSelection()
	end
end

function Tmog.HideBorders()
	for k in pairs(InventorySlots) do
		_G["TmogFrame"..k.."BorderFull"]:Hide()
	end
end

function Tmog.AddOutfitTooltip(frame, outfit)
	frame:SetScript("OnEnter", function()

		TmogTooltip:SetOwner(this, "ANCHOR_RIGHT", -(this:GetWidth() / 4) + 15, -(this:GetHeight() / 4) + 20)

		if outfit then
			TmogTooltip:AddDoubleLine(outfit, "", 1, 1, 1, 1, 1, 1)
		end
		local numItemsInOutfit = 0
		local numCollected = 0

		for name in pairs(TMOG_PLAYER_OUTFITS) do

			if name == outfit then
				numItemsInOutfit = tsize(TMOG_PLAYER_OUTFITS[name])

				for slot, itemID in pairs(TMOG_PLAYER_OUTFITS[name]) do
					local slotName

					for k, v in pairs(InventorySlots) do
						if v == slot then
							slotName = k
						end
					end

					if slotName then
						slotName = _G[strupper(slotName)]
						local itemName, _, quality = GetItemInfo(itemID)
						if itemName then
							local _, _, _, color = GetItemQualityColor(quality or 1)
							local status = ""

							if TMOG_CACHE[slot][itemID] then
								status = NORMAL..L["Collected"]
								numCollected = numCollected + 1
							else
								status = GREY..L["Not collected"]
							end

							TmogTooltip:AddDoubleLine(slotName..": "..color..itemName, status)
						end
					end
				end
			end
		end
		if this:GetID() == 0 then
			if not _G[this:GetName().."PlusPushed"]:IsShown() then
				_G[this:GetName().."PlusHighlight"]:Show()
			end
			TmogTooltip:AddLine(L["Create an outfit from currently selected items."], 1, 0.82, 0, 1, true)
		else
			_G[this:GetParent():GetName().."ItemModel"]:SetLight(unpack(Tmog.previewHighlight))
			TmogTooltipTextRight1:SetText("("..numCollected.."/"..numItemsInOutfit..")")
			TmogTooltipTextRight1:Show()
		end
		TmogTooltip:Show()
	end)

	frame:SetScript("OnLeave", function()
		_G[this:GetParent():GetName().."ItemModel"]:SetLight(unpack(Tmog.previewNormalLight))
		TmogTooltip:Hide()
		_G[this:GetName().."PlusHighlight"]:Hide()
	end)
end

function Tmog.AddItemTooltip(frame)
	frame:SetScript("OnEnter", function()
		TmogTooltip:SetOwner(this, "ANCHOR_RIGHT", -(this:GetWidth() / 4) + 15, -(this:GetHeight() / 4) + 20)
		local itemID = this:GetID()
		Tmog.CacheItem(itemID)
		TmogTooltip.itemID = itemID
		TmogTooltip:SetHyperlink("item:"..itemID)
		local numLines = TmogTooltip:NumLines()

		if numLines and numLines > 0 then
			local lastLine = _G["TmogTooltipTextLeft"..numLines]

			if lastLine:GetText() then
				lastLine:SetText(lastLine:GetText().."\n\n"..NORMAL.."ItemID: "..itemID)
				local name = GetItemInfo(itemID)

				if name and DisplayIdDB[itemID] then
					if not Tmog.onlyUsable then
						lastLine:SetText(lastLine:GetText().."\n\n"..NORMAL..L["Shares appearance with"]..":")
						for _, id in pairs(DisplayIdDB[itemID]) do
							Tmog.CacheItem(id)
							local similarItem, _, quality = GetItemInfo(id)
							if similarItem then
								local _, _, _, color = GetItemQualityColor(quality or 1)
								lastLine:SetText(lastLine:GetText().."\n"..color..similarItem)
							end
						end
					else
						local proceed = false
						for _, id in pairs(DisplayIdDB[itemID]) do
							Tmog.CacheItem(itemID)
							if Tmog.IsUsableItem(id) then
								proceed = true
								break
							end
						end
						if proceed then
							lastLine:SetText(lastLine:GetText().."\n\n"..NORMAL..L["Shares appearance with"]..":")
							for _, id in pairs(DisplayIdDB[itemID]) do
								Tmog.CacheItem(id)
								local similarItem, _, quality = GetItemInfo(id)
								if similarItem then
									if not Tmog.IsUsableItem(id) then
										-- continue
									else
										local _, _, _, color = GetItemQualityColor(quality or 1)
										lastLine:SetText(lastLine:GetText().."\n"..color..similarItem)
									end
								end
							end
						end
					end
				end
			end
		end
		_G[this:GetParent():GetName().."ItemModel"]:SetLight(unpack(Tmog.previewHighlight))
		TmogTooltip:Show()
	end)

	frame:SetScript("OnLeave", function()
		TmogTooltip:Hide()
		TmogTooltip.itemID = nil
		_G[this:GetParent():GetName().."ItemModel"]:SetLight(unpack(Tmog.previewNormalLight))
	end)
end

local hidden = false
function Tmog.HideUI()
	if not hidden then
		for slot in pairs(InventorySlots) do
			_G["TmogFrame"..slot]:Hide()
		end
		TmogFrameRevert:Hide()
		TmogFrameFullScreenButton:Hide()
		TmogFrameHideUI:SetText(L["Show UI"])
		hidden = true
	else
		for slot in pairs(InventorySlots) do
			_G["TmogFrame"..slot]:Show()
		end
		TmogFrameRevert:Show()
		TmogFrameFullScreenButton:Show()
		TmogFrameHideUI:SetText(L["Hide UI"])
		hidden = false
	end
end

function Tmog.LoadOutfit(outfit)
	if IsShiftKeyDown() then
		Tmog.LinkOutfit(outfit)
		return
	end
	UIDropDownMenu_SetText(outfit, TmogFrameOutfitsDropDown)

	Tmog.currentOutfit = outfit
	TmogFrameSaveOutfit:Disable()

	TmogFrameDeleteOutfit:Enable()
	TmogFrameShareOutfit:Enable()

	TmogFramePlayerModel:Undress()

	for _, InventorySlotId in pairs(InventorySlots) do
		Tmog.CurrentGear[InventorySlotId] = 0
	end

	for _, slot in ipairs(Tmog.DressOrder) do
		local itemID = TMOG_PLAYER_OUTFITS[outfit][slot]
		if itemID then
			TmogFramePlayerModel:TryOn(itemID)
			Tmog.CurrentGear[slot] = itemID
		end
	end

	Tmog.UpdateItemTextures()
	Tmog.RemoveSelection()

	for i = 1, tsize(Tmog.PreviewButtons) do
		if Tmog.PreviewButtons[i].name == outfit then
			_G["TmogFramePreview"..i.."Button"]:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_selected")
		end
	end
end

function Tmog.ToggleOutfitButtons()
	if Tmog.currentOutfit ~= nil then
		TmogFrameSaveOutfit:Disable()
		for slot, itemID in pairs(Tmog.CurrentGear) do
			if itemID ~= 0 and not TMOG_PLAYER_OUTFITS[Tmog.currentOutfit][slot] then
				TmogFrameSaveOutfit:Enable()
				break
			elseif TMOG_PLAYER_OUTFITS[Tmog.currentOutfit][slot] and TMOG_PLAYER_OUTFITS[Tmog.currentOutfit][slot] ~= itemID then
				TmogFrameSaveOutfit:Enable()
			end
		end
		TmogFrameDeleteOutfit:Enable()
		TmogFrameShareOutfit:Enable()
	else
		TmogFrameSaveOutfit:Disable()
		TmogFrameDeleteOutfit:Disable()
		TmogFrameShareOutfit:Disable()
	end
end

function Tmog.SaveOutfit()
	TMOG_PLAYER_OUTFITS[Tmog.currentOutfit] = {}

	for InventorySlotId, itemID in pairs(Tmog.CurrentGear) do
		if itemID ~= 0 then
			TMOG_PLAYER_OUTFITS[Tmog.currentOutfit][InventorySlotId] = itemID
		end
	end

	TmogFrameSaveOutfit:Disable()

	if Tmog.currentTab == "OUTFITS" then
		Tmog.DrawPreviews()
	end
end

function Tmog.DeleteOutfit()
	TMOG_PLAYER_OUTFITS[Tmog.currentOutfit] = nil
	Tmog.currentOutfit = nil

	TmogFrameSaveOutfit:Disable()
	TmogFrameDeleteOutfit:Disable()
	TmogFrameShareOutfit:Disable()
	UIDropDownMenu_SetText(L["Outfits"], TmogFrameOutfitsDropDown)

	if Tmog.currentTab == "OUTFITS" then
		Tmog.HidePreviews()
		Tmog.DrawPreviews()
	end
end

function Tmog.NewOutfitPopup()
	StaticPopup_Show("TMOG_NEW_OUTFIT")
end

StaticPopupDialogs["TMOG_NEW_OUTFIT"] = {
	text = L["Enter outfit name:"],
	button1 = SAVE,
	button2 = CANCEL,
	hasEditBox = 1,

	OnShow = function()
		if Tmog.currentTab == "OUTFITS" then
			if Tmog.currentPage == 1 then
				TmogFramePreview1ButtonPlus:Hide()
				TmogFramePreview1ButtonPlusPushed:Show()
			else
				TmogFramePreview1ButtonPlus:Hide()
				TmogFramePreview1ButtonPlusPushed:Hide()
			end
		end
		_G[this:GetName().."EditBox"]:SetFocus()
		_G[this:GetName() .. "EditBox"]:SetScript("OnEnterPressed", function()
			StaticPopup1Button1:Click()
		end)

		_G[this:GetName() .. "EditBox"]:SetScript("OnEscapePressed", function()
			_G[this:GetParent():GetName() .. "EditBox"]:SetText("")
			StaticPopup1Button2:Click()
		end)
	end,

	OnAccept = function()
		local outfitName = _G[this:GetParent():GetName() .. "EditBox"]:GetText()
		if Tmog.currentTab == "OUTFITS" then
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
		Tmog.SaveOutfit()
		_G[this:GetParent():GetName() .. "EditBox"]:SetText("")
	end,

	OnCancel = function()
		if Tmog.currentTab == "OUTFITS" then
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
	text = L["Outfit with this name already exists."],
	button1 = OKAY,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
}

StaticPopupDialogs["TMOG_OUTFIT_EMPTY_NAME"] = {
	text = L["Outfit name not valid."],
	button1 = OKAY,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
}

StaticPopupDialogs["TMOG_CONFIRM_DELETE_OUTFIT"] = {
	text = L["Delete outfit?"],
	button1 = YES,
	button2 = NO,

	OnAccept = function()
		Tmog.DeleteOutfit()
	end,

	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
}

StaticPopupDialogs["TMOG_BAD_OUTFIT_CODE"] = {
	text = L["Invalid outfit code."],
	button1 = OKAY,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
}

StaticPopupDialogs["TMOG_IMPORT_OUTFIT"] = {
	text = L["Enter outfit code:"],
	button1 = OKAY,
	button2 = CANCEL,
	hasEditBox = 1,

	OnShow = function()
		_G[this:GetName().."EditBox"]:SetFocus()
		_G[this:GetName().."EditBox"]:SetText("")
		_G[this:GetName() .. "EditBox"]:SetScript("OnEnterPressed", function()
			StaticPopup1Button1:Click()
		end)

		_G[this:GetName() .. "EditBox"]:SetScript("OnEscapePressed", function()
			_G[this:GetParent():GetName() .. "EditBox"]:SetText("")
			StaticPopup1Button2:Click()
		end)
	end,

	OnAccept = function()
		local code = _G[this:GetParent():GetName() .. "EditBox"]:GetText()
		_G[this:GetParent():GetName() .. "EditBox"]:SetText("")
		local outfit = Tmog.ValidateOutfitCode(code)
		if not outfit then
			StaticPopup_Show("TMOG_BAD_OUTFIT_CODE")
			return
		end
		Tmog.ImportOutfit(outfit)
		this:GetParent():Hide()
		Tmog.NewOutfitPopup()
		TmogFrameShareOutfit:Disable()
	end,

	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
}

function Tmog.ResetPages()
	Tmog.currentPage = 1
	for k in pairs(PagesMemory) do
		for i in pairs(PagesMemory[k]) do
			PagesMemory[k][i] = 1
		end
	end
end

function Tmog.ResetUnusableTable()
	for k in pairs(Unusable) do
		for k2 in pairs(Unusable[k]) do
			for k3 in pairs(Unusable[k][k2]) do
				Unusable[k][k2][k3] = nil
			end
		end
	end
end

function Tmog.CollectedToggle()
	Tmog.collected = not Tmog.collected
	TmogFrameCollected:SetChecked(Tmog.collected)
	Tmog.flush = true
	if Tmog.currentSlot then
		Tmog.ResetPages()
		Tmog.DrawPreviews()
	end
end

function Tmog.NotCollectedToggle()
	Tmog.notCollected = not Tmog.notCollected
	TmogFrameNotCollected:SetChecked(Tmog.notCollected)
	Tmog.flush = true
	if Tmog.currentSlot then
		Tmog.ResetPages()
		Tmog.DrawPreviews()
	end
end

function Tmog.UsableToggle()
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
		Tmog.ResetPages()
		if Tmog.onlyUsable then
			Tmog.ResetUnusableTable()
		end
		Tmog.DrawPreviews()
	end
end

function Tmog.IgnoreLevelToggle()
	if Tmog.ignoreLevel then
		Tmog.ignoreLevel = false
	else
		Tmog.ignoreLevel = true
	end
	this:SetChecked(Tmog.ignoreLevel)
	Tmog.flush = true
	if Tmog.currentSlot then
		Tmog.ResetPages()
		Tmog.ResetUnusableTable()
		Tmog.DrawPreviews()
	end
end

function TmogFrame_Toggle()
	if TmogFrame:IsShown() then
		HideUIPanel(TmogFrame)
	else
		ShowUIPanel(TmogFrame)
	end
end

function Tmog.Search()
	if TmogFrameSharedItems:IsShown() then
		TmogFrameSharedItems:Hide()
	end

	if TmogFrameSearchBox:GetText() == "" then
		Tmog.SelectType(Tmog.currentType)
		return
	end
	Tmog.flush = true
	Tmog.currentPage = 1
	Tmog.DrawPreviews()
end

function Tmog.SwitchTab(which)
	if Tmog.currentTab == which then
		return
	end

	Tmog.currentTab = which

	if which == "ITEMS" then
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
			Tmog.HidePreviews()
			Tmog.HidePagination()
		end

		TmogFrameCollected:Show()
		TmogFrameNotCollected:Show()
		TmogFrameUsable:Show()
		TmogFrameIgnoreLevel:Show()
		TmogFrameShareOutfit:Hide()
		TmogFrameImportOutfit:Hide()

	elseif which == "OUTFITS" then
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

		Tmog.DrawPreviews()
	end

	TmogFrameSharedItems:Hide()
	DropDownList1:Hide()
end

function TmogPlayerSlot_OnEnter()
	TmogTooltip:SetOwner(this, "ANCHOR_TOPRIGHT", 0, 0)

	local slot = this:GetID()
	local itemID = Tmog.CurrentGear[this:GetID()]

	Tmog.CacheItem(itemID)
	local name, _, quality = GetItemInfo(itemID)

	if name and quality then
		local r, g, b = GetItemQualityColor(quality)

		TmogTooltip:SetText(name, r, g, b)

		if TMOG_CACHE[slot][itemID] then
			TmogTooltip:AddLine(GREEN..L["Collected"].."|r")
		else
			TmogTooltip:AddLine(YELLOW..L["Not collected"].."|r")
		end

		TmogTooltip:AddLine(NORMAL.."\nItemID: "..itemID.."|r", 1, 1, 1)
		TmogTooltip:Show()
	end

	if not name then
		local text = _G[strupper(strsub(this:GetName(), 10))]

		TmogTooltip:SetText(text)
		TmogTooltip:Show()
	end
end


function Tmog.OutfitsDropDown_Initialize()
	local info = UIDropDownMenu_CreateInfo()

	if tsize(TMOG_PLAYER_OUTFITS) < 30 then
		info.text = GREEN.."+ "..L["New outfit"]
		info.value = 1
		info.arg1 = 1
		info.checked = false
		info.func = Tmog.NewOutfitPopup
		info.tooltipTitle = L["New outfit"]
		info.tooltipText = L["Create an outfit from currently selected items."]
		UIDropDownMenu_AddButton(info)
	end

	for name, data in pairs(TMOG_PLAYER_OUTFITS) do
		info.text = name
		info.value = name
		info.arg1 = name
		info.checked = Tmog.currentOutfit == name
		info.func = Tmog.LoadOutfit
		info.tooltipTitle = name
		local descText, slotName = "", ""

		for slot, itemID in pairs(data) do
			Tmog.CacheItem(itemID)

			for k, v in pairs(InventorySlots) do
				if v == slot then
					slotName = k
				end
			end

			if slotName then
				slotName = _G[strupper(slotName)]
				Tmog.CacheItem(itemID)
				local itemName, _, quality = GetItemInfo(itemID)

				if itemName then

					if quality then
						local _, _, _, color = GetItemQualityColor(quality)
						if color then
							descText = descText..NORMAL..slotName..":|r "..color.. itemName.."|r\n"
						else
							descText = descText..NORMAL..slotName..":|r ".. itemName.."|r\n"
						end
					else
						descText = descText..NORMAL..slotName..":|r ".. itemName.."|r\n"
					end
				end
			end
		end

		info.tooltipText = descText
		UIDropDownMenu_AddButton(info)
	end
end

function Tmog.TypeDropDown_Initialize()
	local types = Tmog.GetTypesForSlot(Tmog.currentSlot)

	if not types then
		return
	end

	local info = UIDropDownMenu_CreateInfo()
	for _, v in pairs(types) do
		info.text = v
		info.arg1 = v
		info.checked = Tmog.currentType == v
		info.func = Tmog.SelectType
		if Tmog.onlyUsable then
			if Tmog.classEquipTable[playerClass][v] then
				if not (not Tmog.canDualWeild and Tmog.currentSlot == 17 and v ~= L["Shields"] and v ~= L["Miscellaneous"]) then
					UIDropDownMenu_AddButton(info)
				end
			end
		else
			UIDropDownMenu_AddButton(info)
		end
	end
end

function Tmog.CacheItem(linkOrID)
	if not linkOrID or linkOrID == 0 then
		return false
	end

	if tonumber(linkOrID) then
		if GetItemInfo(linkOrID) then
			return true
		else
			GameTooltip:SetHyperlink("item:"..linkOrID)
			Tmog.debug("Caching "..linkOrID)
		end
	else
		if type(linkOrID) ~= "string" then
			return false
		end
		local _, _, item = strfind(linkOrID, "(item:%d+)")
		if item then
			if GetItemInfo(item) then
				return true
			else
				GameTooltip:SetHyperlink(item)
				Tmog.debug("Caching "..item)
			end
		end
	end
end

function Tmog.ImportOutfit(outfit)
	Tmog.currentOutfit = nil
	TmogFrameSaveOutfit:Disable()
	TmogFrameDeleteOutfit:Disable()
	UIDropDownMenu_SetText(L["Outfits"], TmogFrameOutfitsDropDown)

	TmogFramePlayerModel:Undress()

	for _, InventorySlotId in pairs(InventorySlots) do
		Tmog.CurrentGear[InventorySlotId] = 0
	end

	for slot, itemID in pairs(outfit) do
		Tmog.CacheItem(itemID)
		Tmog.CurrentGear[slot] = itemID
		TmogFramePlayerModel:TryOn(itemID)
	end

	Tmog.UpdateItemTextures()
end

function TmogFrameImportOutfit_OnClick()
	StaticPopup_Show("TMOG_IMPORT_OUTFIT")
end

function TmogFrameShareOutfit_OnClick()
	local code = "T.O.L."

	for slot, id in pairs(TMOG_PLAYER_OUTFITS[Tmog.currentOutfit]) do
		code = code..slot..":"..id..";"
	end

	TmogFrameShareDialog:Show()
	TmogFrameShareDialogEditBox:SetText(code)
	TmogFrameShareDialogEditBox:HighlightText()
end

function Tmog.ValidateOutfitCode(code)
	local signature = strfind(code, "T.O.L.", 1, true)
	if signature then
		code = strsub(code, signature)
		code = strtrim(code)
	else
		return nil
	end

	code = strsub(code, 7)

	if strfind(code, "[^%d:;]") then
		return nil
	end

	local slotItemPairs = strsplit(code, ";")
	local outfit = {}
	local slot, item

	for i = 1, tsize(slotItemPairs) do
		_, _, slot, item = strfind(slotItemPairs[i], "(%d+):(%d+)")
		slot = tonumber(slot)
		item = tonumber(item)
		AddToSet(outfit, slot, item)
	end

	for invSlot, itemID in pairs(outfit) do
		Tmog.CacheItem(itemID)
		local _, _, _, _, itemType, itemSubType, _, loc  = GetItemInfo(itemID)
		-- if not TmogGearDB[itemID] then
		--	 return nil
		-- end
		-- if not itemType or not itemSubType or not loc then
		--	 return nil
		-- end
		-- if itemType ~= L["Armor"] and itemType ~= L["Weapon"] then
		--	 return nil
		-- end
		-- if not SetContains(InventoryTypeToSlot, loc, invSlot) and not (invSlot == 17 and loc == "INVTYPE_WEAPON") then
		--	 return nil
		-- end
	end

	return outfit
end

function Tmog.Sort(a, b)
	local nameA, _, qualityA = GetItemInfo(a)
	local nameB, _, qualityB = GetItemInfo(b)
	if not nameA or not nameB then return false end
	if qualityA == qualityB then
		return nameA < nameB
	else
		return qualityA > qualityB
	end
end

function TmogFrameFullScreenModel_OnLoad()
	this:SetLight(unpack(Tmog.fullScreenLight))
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
	this:SetWidth(GetScreenWidth()+5)
	this:SetHeight(GetScreenHeight()+5)
	this:SetUnit("player")
	this:SetFacing(0)
	this:SetPosition(-3, 0, 0)
	Tmog.Dress(this)
end

function TmogFrameFullScreen_OnUpdate()
	if not this.fadeTime then
		return
	end
	if (GetTime() - this.fadeTime) > 0.3 then
		this.fadeTime = nil
		this:Hide()
	end
end

function TmogFrameFullScreen_OnKeyDown()
	local screenshotKey = GetBindingKey("SCREENSHOT")
	if arg1 == "ESCAPE" then
		this:SetScript("OnKeyDown", nil)
		this.fadeTime = GetTime()
		UIFrameFadeOut(TmogFrameFullScreenModel, 0.3, 1, 0)
	elseif screenshotKey and (arg1 == screenshotKey) then
		RunBinding("SCREENSHOT")
	end
end

local debugState = Tmog.verbose
local pendingIDs = {}
local requestInterval = 10
local tick = requestInterval

local keysdeleted = 0
local namesrestored = 0
local sharedadded = 0

local function RepairStop()
	Tmog.debug(format(L["Cache repair finished: bad items deleted: %d, item names restored: %d, missing shared items added: %d"], keysdeleted, namesrestored, sharedadded))
	Tmog.verbose = debugState
	TmogFrame:SetScript("OnUpdate", nil)
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
				Tmog.debug(format(L["bad item %d, requesting info from server, try #%d"], id, tonumber(value)))
				Tmog.CacheItem(id)
				pendingIDs[id].value = (GetItemInfo(id)) or (value + 1)
			end
		end
	end
end

function Tmog.RepairPlayerCache()
	local pending = false
	keysdeleted = 0
	namesrestored = 0
	sharedadded = 0
	Tmog.debug(L["Cache repair started."])
	for slot in pairs(TMOG_CACHE) do
		for id, name in pairs(TMOG_CACHE[slot]) do
			Tmog.CacheItem(id)
			if type(id) ~= "number" then
				TMOG_CACHE[slot][id] = nil
				keysdeleted = keysdeleted + 1
			elseif name == true then
				pendingIDs[id] = { slot = slot, value = 1 }
				if not TmogFrame:GetScript("OnUpdate") then
					TmogFrame:SetScript("OnUpdate", OnUpdate)
					pending = true
				end
			end
		end
	end
	for slot in pairs(TMOG_CACHE) do
		for itemID in pairs(TMOG_CACHE[slot]) do
			if DisplayIdDB[itemID] then
				for _, id in pairs(DisplayIdDB[itemID]) do
					Tmog.CacheItem(id)
					local name = GetItemInfo(id)
					if not TMOG_CACHE[slot][id] then
						AddToSet(TMOG_CACHE[slot], id, name)
						sharedadded = sharedadded + 1
					end
				end
			end
		end
	end
	if not pending then
		Tmog.debug(format(L["Cache repair finished: bad items deleted: %d, item names restored: %d, missing shared items added: %d"], keysdeleted, namesrestored, sharedadded))
		Tmog.verbose = debugState
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
			Tmog.print(L["minimap button unlocked"])
		else
			Tmog.print(L["minimap button locked"])
		end

	elseif strfind(cmd, "debug$") then
		Tmog.verbose = not Tmog.verbose
		if Tmog.verbose then
			Tmog.print(L["debug is on"])
		else
			Tmog.print(L["debug is off"])
		end

	elseif strfind(cmd, "db$") then
		Tmog.verbose = true
		Tmog.RepairPlayerCache()
	else
		Tmog.print(NORMAL.."/tmog show|r"..WHITE.." - "..L["toggle dressing room"].."|r")
		Tmog.print(NORMAL.."/tmog reset|r"..WHITE.." - "..L["reset minimap button position"].."|r")
		Tmog.print(NORMAL.."/tmog lock|r"..WHITE.." - "..L["lock/unlock minimap button"].."|r")
		Tmog.print(NORMAL.."/tmog debug|r"..WHITE.." - "..L["print debug messages in chat"].."|r")
		Tmog.print(NORMAL.."/tmog db|r"..WHITE.." - "..L["attempt to repair this character's cache (can fix minor bugs)"].."|r")
	end
end
