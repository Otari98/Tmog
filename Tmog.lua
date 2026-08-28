_G = _G or getfenv(0)

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
Tmog.race = string.lower(playerRace)
Tmog.currentType = L["Cloth"]
Tmog.currentTab = "ITEMS"

Tmog.currentSlot = nil
Tmog.currentOutfit = nil

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
Tmog.OutfitsSorted = {}

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

Tmog.InventorySlots = {
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

Tmog.InventoryTypeToSlot = {
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
		for k in pairs(info) do info[k] = nil end
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
	if slot == 1 or slot == 5 or slot == 8 then
		return Tmog.dropdownTypes.misc
	elseif slot == 15 then
		return Tmog.dropdownTypes.back
	elseif slot == 4 or slot == 19 then
		return Tmog.dropdownTypes.shirt
	elseif slot == 16 then
		return Tmog.dropdownTypes.mh
	elseif slot == 17 then
		return Tmog.dropdownTypes.oh
	elseif slot == 18 then
		return Tmog.dropdownTypes.ranged
	else
		return Tmog.dropdownTypes.default
	end
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
Tmog.Unusable = {}

for _, slot in pairs(Tmog.InventorySlots) do
	local types = Tmog.GetTypesForSlot(slot)
	PagesMemory[slot] = {}
	Tmog.Unusable[slot] = {}
	StatusSlotsLookup[slot] = true
	SlotTypesMemory[slot] = types[1]
	for _, type in ipairs(types) do
		PagesMemory[slot][type] = 1
		Tmog.Unusable[slot][type] = {}
	end
	Tmog.Unusable[slot]["SearchResult"] = {}
end

function TmogFrame_OnLoad()
	TmogFrame:RegisterEvent("ADDON_LOADED")
	TmogFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	TmogFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
	TmogFrame:RegisterEvent("CHAT_MSG_ADDON")

	TmogFrame:RegisterForDrag("LeftButton")

	TmogFrameRaceBackground:SetTexture("Interface\\AddOns\\Tmog\\Textures\\transmogbackground"..Tmog.race)

	TmogFrameSaveOutfit:Disable()
	TmogFrameSelectedOutfitText:SetText(string.format(L.FMT_SELECTED_OUTFIT, Tmog.currentOutfit or ""))

	TmogFrameVersionText:SetText(Tmog.version)

	table.insert(UISpecialFrames, "TmogFrame")
	TmogFrame.firstLoad = true
end

function TmogFrame_OnEvent()
	if event == "PLAYER_ENTERING_WORLD" then
		TmogFramePlayerModel:SetUnit("player")

		if TmogFrame.firstLoad then
			Tmog.Reset()
			TmogFrame.firstLoad = nil
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
		for _, InventorySlotId in pairs(Tmog.InventorySlots) do
			if not TMOG_CACHE[InventorySlotId] then TMOG_CACHE[InventorySlotId] = {} end
		end
		for k, v in pairs(TMOG_CACHE) do
			for k2, v2 in pairs(v) do if v2 ~= 1 then TMOG_CACHE[k][k2] = 1 end end
		end
		TMOG_PLAYER_OUTFITS = TMOG_PLAYER_OUTFITS or {}
		TMOG_TRANSMOG_STATUS = TMOG_TRANSMOG_STATUS or {}
		TMOG_POSITION = TMOG_POSITION or { 760, 600 }
		TMOG_LOCKED = TMOG_LOCKED or false

		UIDropDownMenu_Initialize(TmogFrameTypeDropDown, Tmog.TypeDropDown_Initialize)
		UIDropDownMenu_SetWidth(140, TmogFrameTypeDropDown)

		TmogButton:SetMovable(not TMOG_LOCKED)
		TmogButton:ClearAllPoints()
		TmogButton:SetPoint("CENTER", UIParent, "BOTTOMLEFT", unpack(TMOG_POSITION or {TmogButton:GetCenter()}))

		return
	end

	if Tmog.verbose and string.find(arg1, "TW_CHAT_MSG_WHISPER", 1, true) then
		Tmog.debug(arg1, arg2, arg3, arg4)
	end

	if event == "CHAT_MSG_ADDON" and string.find(arg1, "TW_TRANSMOG", 1, true) and arg4 == UnitName("player") then
		Tmog.debug(arg1, arg2, arg3, arg4)

		if string.find(arg2, "AvailableTransmogs", 1, true) then
			local data = Tmog.strsplit(arg2, ":")
			local InventorySlotId = tonumber(data[2])
			
			if not InventorySlotId then return end

			for i = 4, table.getn(data) do
				local itemID = tonumber(data[i])
				if itemID then
					Tmog.CacheItem(itemID)
					TMOG_CACHE[InventorySlotId][itemID] = 1
					-- check if it shares appearance with other items and add those if it does
					local displayGroup = Tmog.ItemDisplayGroup[itemID]
					if displayGroup then
						for _, id in pairs(Tmog.DisplayGroups[displayGroup]) do
							Tmog.CacheItem(id)
							TMOG_CACHE[InventorySlotId][id] = 1
						end
					end
				end
			end

		elseif string.find(arg2, "NewTransmog", 1, true) then
			local _, _, itemID = string.find(arg2, "NewTransmog:(%d+)")
			itemID = tonumber(itemID)
			local InventorySlotId = Tmog.InventorySlotFromItemID(itemID)
			
			if not (InventorySlotId and itemID) then return end
			
			Tmog.CacheItem(itemID)
			TMOG_CACHE[InventorySlotId][itemID] = 1
			-- check if it shares appearance with other items and add those if it does
			local displayGroup = Tmog.ItemDisplayGroup[itemID]
			if displayGroup then
				for _, id in pairs(Tmog.DisplayGroups[displayGroup]) do
					Tmog.CacheItem(id)
					TMOG_CACHE[InventorySlotId][id] = 1
				end
			end

		elseif string.find(arg2, "TransmogStatus", 1, true) then
			local data = string.gsub(arg2, "TransmogStatus:", "")

			if not data then return end

			local TransmogStatus = Tmog.strsplit(data, ",")
			if not TMOG_TRANSMOG_STATUS then TMOG_TRANSMOG_STATUS = {} end

			for _, InventorySlotId in pairs(Tmog.InventorySlots) do
				if not TMOG_TRANSMOG_STATUS[InventorySlotId] then TMOG_TRANSMOG_STATUS[InventorySlotId] = {} end
			end

			for k in pairs(StatusSlotsLookup) do
				StatusSlotsLookup[k] = true
			end

			for _, d in pairs(TransmogStatus) do
				local _, _, InventorySlotId, itemID = string.find(d, "(%d+):(%d+)")
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

		return
	end

	if event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
		for InventorySlotId in pairs(TMOG_CACHE) do
			local link = GetInventoryItemLink("player", InventorySlotId)
			if link then
				local itemID = Tmog.IDFromLink(link)
				if itemID then
					Tmog.CacheItem(itemID)
					TMOG_CACHE[InventorySlotId][itemID] = 1
					-- check if it shares appearance with other items and add those if it does
					local displayGroup = Tmog.ItemDisplayGroup[itemID]
					if displayGroup then
						for _, id in pairs(Tmog.DisplayGroups[displayGroup]) do
							Tmog.CacheItem(id)
							TMOG_CACHE[InventorySlotId][id] = 1
						end
					end
				end
			end
		end

		return
	end
end

function TmogFrame_OnShow()
	TmogFramePlayerModel:SetPosition(TmogFramePlayerModel.z, TmogFramePlayerModel.x, TmogFramePlayerModel.y)
	Tmog.Dress(TmogFramePlayerModel)
	Tmog.DrawPreviews()
	Tmog.UpdateItemTextures()
	PlaySound("igCharacterInfoOpen")
end

function TmogFrame_OnHide()
	TmogFramePlayerModel.z, TmogFramePlayerModel.x, TmogFramePlayerModel.y = TmogFramePlayerModel:GetPosition()
	TmogFramePlayerModel:SetPosition(0, 0, 0)
	for i in pairs(Tmog.PreviewButtons) do
		Tmog.PreviewButtons[i]:Hide()
	end
	PlaySound("igCharacterInfoClose")
end

function Tmog.ResetPosition()
	TmogFramePlayerModel:SetPosition(0, 0, 0)
	TmogFramePlayerModel:SetFacing(0.3)
	TmogFramePlayerModel.z, TmogFramePlayerModel.x, TmogFramePlayerModel.y = TmogFramePlayerModel:GetPosition()
end

function TmogFramePlayerModel_OnMouseDown(self, button)
	TmogFrameSearchBox:ClearFocus()
	DropDownList1:Hide()
	self.startX, self.startY = GetCursorPosition()
	self.mouseButton = button
end

function TmogFramePlayerModel_OnMouseUp(self, button)
	self.z, self.x, self.y = self:GetPosition()
	self.mouseButton = nil
end

function TmogFramePlayerModel_OnUpdate(self, elapsed)
	if not self.mouseButton then return end
	if self.mouseButton == "LeftButton" then
		local endX, endY = GetCursorPosition()
		self:SetFacing((endX - self.startX) / 34 + self:GetFacing())
		self.startX, self.startY = GetCursorPosition()
	elseif self.mouseButton == "RightButton" then
		local endX, endY = GetCursorPosition()
		local z, x, y = self:GetPosition()
		x = (endX - self.startX) / 45 + x
		y = (endY - self.startY) / 45 + y
		self:SetPosition(z, x, y)
		self.startX, self.startY = GetCursorPosition()
	end
end

function TmogFramePlayerModel_OnMouseWheel(self, delta)
	local z, x, y = self:GetPosition()
	z = z + delta
	self:SetPosition(z, x, y)
	self.z = z
end

function TmogFramePlayerModel_OnLoad(self)
	self.z, self.x, self.y = 0, 0, 0
	self:SetFacing(0.3)
	self:SetLight(unpack(Tmog.playerModelLight))
end

function Tmog.Reset()
	Tmog.currentOutfit = nil
	TmogFrameSaveOutfit:Disable()
	TmogFrameSelectedOutfitText:SetText(string.format(L.FMT_SELECTED_OUTFIT, Tmog.currentOutfit or ""))

	TmogFramePlayerModel:SetPosition(0, 0, 0)
	TmogFramePlayerModel:Dress()
	TmogFramePlayerModel:SetPosition(cacheZ, cacheX, cacheY)

	-- Fix tabard
	local tabardLink = GetInventoryItemLink("player", 19)
	if tabardLink then
		TmogFramePlayerModel:TryOn(Tmog.IDFromLink(tabardLink))
	end

	for _, InventorySlotId in pairs(Tmog.InventorySlots) do
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

	for _, InventorySlotId in pairs(Tmog.InventorySlots) do
		Tmog.CurrentGear[InventorySlotId] = Tmog.ActualGear[InventorySlotId]
	end

	Tmog.UpdateItemTextures()
	Tmog.UpdateSelection()
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
	TmogFrame.previewsHidden = true
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
	searchStr = Tmog.strtrim(string.lower(searchStr))
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

		if searchStr ~= "" then type = "SearchResult" end

		if Tmog.flush then
			Tmog.debug("flushing", "slot "..Tmog.currentSlot, " type "..type)
			for i = table.getn(DrawTable), 1, -1 do
				table.remove(DrawTable, i)
			end

			if type == "SearchResult" then
				for k in pairs(Tmog.ItemDB[Tmog.currentSlot]) do
					for itemID in pairs(Tmog.ItemDB[Tmog.currentSlot][k]) do
						if Tmog.CacheItem(itemID) then
							if string.find(string.lower(GetItemInfo(itemID)), searchStr, 1 ,true) then
								table.insert(DrawTable, itemID)
							end
						elseif not LoadingFrame.queueIDs[itemID] then
							LoadingFrame.queueTimer = Tmog.loadingTimeMax
							LoadingFrame.queueIDs[itemID] = true
						end
					end
				end
			else
				for itemID in pairs(Tmog.ItemDB[Tmog.currentSlot][type]) do
					if Tmog.CacheItem(itemID) then
						table.insert(DrawTable, itemID)
					elseif not LoadingFrame.queueIDs[itemID] then
						LoadingFrame.queueTimer = Tmog.loadingTimeMax
						LoadingFrame.queueIDs[itemID] = true
					end
				end
			end
			if not Tmog.notCollected then
				for i = table.getn(DrawTable), 1, -1 do
					if not TMOG_CACHE[Tmog.currentSlot][DrawTable[i]] then
						table.remove(DrawTable, i)
					end
				end
			elseif not Tmog.collected then
				for i = table.getn(DrawTable), 1, -1 do
					if TMOG_CACHE[Tmog.currentSlot][DrawTable[i]] then
						table.remove(DrawTable, i)
					end
				end
			end
			-- if "usable" checked, remove unusable items
			if Tmog.onlyUsable then
				for i = table.getn(DrawTable), 1, -1 do
					if not Tmog.IsUsableItem(DrawTable[i]) then
						table.remove(DrawTable, i)
					end
				end
			end
			-- remove duplicates
			if type ~= "SearchResult" then
				for _, id in ipairs(DrawTable) do
					local displayGroup = Tmog.ItemDisplayGroup[id]
					if displayGroup then
						for _, itemID in pairs(Tmog.DisplayGroups[displayGroup]) do
							if itemID ~= id then
								local i = tonumber(Tmog.SetContains(DrawTable, nil, itemID))
								if i then table.remove(DrawTable, i) end
							end
						end
					end
				end
			end
			Tmog.totalPages = ceil(table.getn(DrawTable) / Tmog.itemsPerPage)
			sort(DrawTable, Tmog.Sort)
			if LoadingFrame.queueTimer > 0 then
				return
			end
		end

		-- nothing to show
		if not next(DrawTable) then
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
		local itemIDEquipped = Tmog.CurrentGear[Tmog.currentSlot]
		local displayGroupEquipped = itemIDEquipped and Tmog.ItemDisplayGroup[itemIDEquipped]
		for i = 1, table.getn(DrawTable) do
			local itemID = DrawTable[i]
			local displayGroup = Tmog.ItemDisplayGroup[itemID]
			local name, _, quality = GetItemInfo(itemID)
			name = name or ""
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
				frame.displayGroup = displayGroup

				button = _G["TmogFramePreview"..itemIndex.."Button"]
				button:Show()
				button:SetID(itemID)

				-- Tmog.CacheItem(itemID)
				if TMOG_CACHE[Tmog.currentSlot][itemID] then
					_G["TmogFramePreview" .. itemIndex .. "ButtonCheck"]:Show()
				else
					_G["TmogFramePreview" .. itemIndex .. "ButtonCheck"]:Hide()
				end

				if itemID == itemIDEquipped or (displayGroup and displayGroupEquipped and displayGroup == displayGroupEquipped) then
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

		local size = table.getn(DrawTable)
		Tmog.totalPages = ceil(size / Tmog.itemsPerPage)
		TmogFramePageText:SetText(Tmog.currentPage .. "/" .. Tmog.totalPages)

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
		if noDraw then return end

		Tmog.HidePreviews()

		local frame, button
		-- big plus button
		if Tmog.currentPage == 1 then
			if not Tmog.PreviewButtons[1] then
				Tmog.PreviewButtons[1] = CreateFrame("Frame", "TmogFramePreview1", TmogFrame, "TmogFramePreviewTemplate")
				Tmog.PreviewButtons[1]:SetPoint("TOPLEFT", TmogFrame, "TOPLEFT", 263 , -105)
				TmogFramePreview1ItemModel:SetLight(unpack(Tmog.previewNormalLight))
			end

			frame = Tmog.PreviewButtons[1]
			frame:Show()

			frame.name = L["New outfit"]
			frame.id = nil
			frame.displayGroup = nil

			button = TmogFramePreview1Button
			button:Show()
			button:SetID(0)
			button:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_normal")

			TmogFramePreview1ButtonPlus:Show()
			TmogFramePreview1ButtonPlusPushed:Hide()
			TmogFramePreview1ItemModel:SetAlpha(0)
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

		for i = table.getn(Tmog.OutfitsSorted), 1, -1 do table.remove(Tmog.OutfitsSorted) end
		for outfitName in pairs(TMOG_PLAYER_OUTFITS) do
			if searchStr == "" or string.find(string.lower(outfitName), searchStr, 1, true) then
				table.insert(Tmog.OutfitsSorted, outfitName)
			end
		end
		table.sort(Tmog.OutfitsSorted)

		for i = 1, table.getn(Tmog.OutfitsSorted) do
			local name = Tmog.OutfitsSorted[i]
			if index >= lowerLimit and index < upperLimit and outfitIndex <= Tmog.itemsPerPage then
				if not Tmog.PreviewButtons[outfitIndex] then
					Tmog.PreviewButtons[outfitIndex] = CreateFrame("Frame", "TmogFramePreview" .. outfitIndex, TmogFrame, "TmogFramePreviewTemplate")
					Tmog.PreviewButtons[outfitIndex]:SetPoint("TOPLEFT", TmogFrame, "TOPLEFT", 263 + col * 90, -105 - 120 * row)
					_G["TmogFramePreview" .. outfitIndex .. "ItemModel"]:SetLight(unpack(Tmog.previewNormalLight))
				end
				frame = Tmog.PreviewButtons[outfitIndex]
				frame:Show()
				frame.name = name
				frame.id = nil
				frame.displayGroup = nil

				button = _G["TmogFramePreview" .. outfitIndex .. "Button"]
				button:Show()
				button:SetID(outfitIndex)

				if name == Tmog.currentOutfit then
					button:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_selected")
				else
					button:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_normal")
				end

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
					if not TMOG_CACHE[slot][itemID] then collectedAll = false end
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

		local size = Tmog.tsize(TMOG_PLAYER_OUTFITS) + 1
		Tmog.totalPages = ceil(size / Tmog.itemsPerPage)
		TmogFramePageText:SetText(Tmog.currentPage .. "/" .. Tmog.totalPages)

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

	TmogFrameSelectedOutfitText:SetText(string.format(L.FMT_SELECTED_OUTFIT, Tmog.currentOutfit or ""))
	TmogFrame.previewsHidden = nil
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

function Tmog.UpdateSelection()
	for i = 1, Tmog.tsize(Tmog.PreviewButtons) do
		_G["TmogFramePreview"..i.."Button"]:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_normal")
	end
	if Tmog.currentTab == "OUTFITS" then
		if Tmog.currentPage ~= 1 then
			TmogFramePreview1ButtonPlus:Hide()
			TmogFramePreview1ButtonPlusPushed:Hide()
		end
		if not Tmog.currentOutfit then return end
		for i = 1, Tmog.tsize(Tmog.PreviewButtons) do
			if Tmog.PreviewButtons[i].name == Tmog.currentOutfit then
				_G["TmogFramePreview"..i.."Button"]:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_selected")
				break
			end
		end
	elseif Tmog.currentTab == "ITEMS" then
		if TmogFramePreview1ButtonPlus and TmogFramePreview1ButtonPlusPushed then
			TmogFramePreview1ButtonPlus:Hide()
			TmogFramePreview1ButtonPlusPushed:Hide()
		end
		if not Tmog.currentSlot then return end
		local itemIDEquipped = Tmog.CurrentGear[Tmog.currentSlot]
		local displayGroupEquipped = itemIDEquipped and Tmog.ItemDisplayGroup[itemIDEquipped]
		for i = 1, Tmog.tsize(Tmog.PreviewButtons) do
			local displayGroup = Tmog.PreviewButtons[i].displayGroup
			local itemID = Tmog.PreviewButtons[i].id
			if itemID == itemIDEquipped or (displayGroup and displayGroupEquipped and displayGroup == displayGroupEquipped) then
				_G["TmogFramePreview"..i.."Button"]:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_selected")
			end
		end
	end
end

function TmogPlayerSlot_OnClick(self, button)
	local slot = self:GetID()
	DropDownList1:Hide()

	if IsShiftKeyDown() then
		Tmog.LinkItem(Tmog.CurrentGear[slot])

	elseif button == "RightButton" then
		if Tmog.CurrentGear[slot] == 0 then
			if Tmog.ActualGear[slot] == 0 then
				return
			end
			TmogFramePlayerModel:TryOn(Tmog.ActualGear[slot])
			Tmog.CurrentGear[slot] = Tmog.ActualGear[slot]
			Tmog.UpdateOutfitButtons()
			Tmog.UpdateItemTextures()
			if Tmog.currentTab == "ITEMS" then
				Tmog.UpdateSelection()
			end
		else
			Tmog.UndressSlot(slot)
		end
		-- update tooltip
		self:Hide()
		self:Show()
		PlaySound("igMainMenuOptionCheckBoxOn")
	else
		Tmog.currentSlot = slot
		Tmog.flush = true
		if Tmog.currentTab == "OUTFITS" then
			if _G[self:GetName().."BorderFull"]:IsShown() then
				Tmog.SwitchTab("ITEMS")
				Tmog.Search()
				return
			else
				Tmog.SwitchTab("ITEMS")
			end
		end

		Tmog.HidePagination()
		UIDropDownMenu_Initialize(TmogFrameTypeDropDown, Tmog.TypeDropDown_Initialize)
		Tmog.currentType = SlotTypesMemory[slot]

		local fullBorder = _G[self:GetName().."BorderFull"]
		if not fullBorder:IsShown() then
			Tmog.HideBorders()
			fullBorder:Show()
			-- shirt / tabard / cloak
			if slot == 4 or slot == 19 or slot == 15 then
				TmogFrameTypeDropDown:Hide()
			else
				TmogFrameTypeDropDown:Show()
			end
			TmogFrameFiltersButton:Show()
		else
			TmogFrameTypeDropDown:Hide()
			TmogFrameFiltersButton:Hide()
			Tmog.HideBorders()
			Tmog.currentSlot = nil
			PlaySound("InterfaceSound_LostTargetUnit")
		end

		Tmog.Search()
		PlaySound("igCreatureAggroSelect")
	end
end

function Tmog.UpdateItemTextures()
	for slotName, slotID in pairs(Tmog.InventorySlots) do
		local frame = _G["TmogFrame"..slotName]
		local icon = _G[frame:GetName() .. "ItemIcon"]
		if frame then
			-- add paperdoll texture
			local _, _, texture = string.find(frame:GetName(), "TmogFrame(.+)Slot")
			texture = string.lower(texture)

			if texture == "wrist" then texture = texture .. "s"
			elseif texture == "back" then texture = "chest" end

			icon:SetTexture("Interface\\Paperdoll\\ui-paperdoll-slot-" .. texture)

			-- replace with item texture if possible
			if GetInventoryItemLink("player", slotID) or GetItemInfo(Tmog.CurrentGear[slotID]) then
				local _, _, _, _, _, _, _, _, tex = GetItemInfo(Tmog.CurrentGear[slotID])
				if tex then icon:SetTexture(tex) end
			end
		end
	end
end

function TmogSharedItem_OnEnter()
	local buttonText = _G[this:GetName().."Name"]
	local originalR, originalG, originalB = buttonText:GetTextColor()
	this.r, this.g, this.b = originalR, originalG, originalB
	TmogTooltip:SetOwner(this, "ANCHOR_LEFT", -6, -5)
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
end

function TmogSharedItem_OnLeave()
	_G[this:GetName().."Name"]:SetTextColor(this.r, this.g, this.b)
	TmogTooltip:Hide()
	TmogTooltip.itemID = nil
end

function Tmog.LinkItem(itemId)
	if not Tmog.CacheItem(itemId) then return end

	local itemName, _, quality = GetItemInfo(itemId)
	local _, _, _, color = GetItemQualityColor(quality)

	if WIM_EditBoxInFocus then
		WIM_EditBoxInFocus:Insert(color.."|Hitem:"..itemId..":0:0:0|h["..itemName.."]|h|r")
	elseif ChatFrameEditBox:IsShown() then
		ChatFrameEditBox:Insert(color.."|Hitem:"..itemId..":0:0:0|h["..itemName.."]|h|r")
	end
end

function Tmog.Dress(model)
	local showingHelm = ShowingHelm()
	local showingCloak = ShowingCloak()
	model:Undress()
	for _, slot in ipairs(Tmog.DressOrder) do
		if (slot == 1 and showingHelm) or (slot == 1 and not showingHelm and Tmog.ActualGear[1] ~= Tmog.CurrentGear[1]) or
			(slot == 15 and showingCloak) or (slot == 15 and not showingCloak and Tmog.ActualGear[15] ~= Tmog.CurrentGear[15]) or
			(slot ~= 1 and slot ~= 15)
		then
			model:TryOn(Tmog.CurrentGear[slot])
		end
	end
end

function Tmog.Undress()
	TmogFramePlayerModel:Undress()

	for _, InventorySlotId in pairs(Tmog.InventorySlots) do
		Tmog.CurrentGear[InventorySlotId] = 0
	end

	Tmog.UpdateItemTextures()
	Tmog.UpdateOutfitButtons()

	if Tmog.currentTab == "ITEMS" then
		Tmog.UpdateSelection()
	end
end

function Tmog.UndressSlot(InventorySlotId)
	TmogFramePlayerModel:Undress()
	for slot, itemID in pairs(Tmog.CurrentGear) do
		if slot ~= InventorySlotId and slot ~= 18 then
			if (slot == 1 and ShowingHelm()) or (slot == 15 and ShowingCloak()) or (Tmog.CurrentGear[slot] ~= Tmog.ActualGear[slot]) or (slot ~= 1 and slot ~= 15) then
				TmogFramePlayerModel:TryOn(itemID)
			end
		end
	end
	Tmog.CurrentGear[InventorySlotId] = 0
	Tmog.UpdateOutfitButtons()
	Tmog.UpdateItemTextures()
	if Tmog.currentTab == "ITEMS" then
		Tmog.UpdateSelection()
	end
end

function Tmog.HideBorders()
	for k in pairs(Tmog.InventorySlots) do
		_G["TmogFrame"..k.."BorderFull"]:Hide()
	end
end

local SharedItems = {}
function TmogFramePreview_OnClick(self, button)
	local itemId = self:GetID()
	if button == "LeftButton" then
		if Tmog.currentTab == "ITEMS" then
			if IsShiftKeyDown() then
				Tmog.LinkItem(itemId)
			else
				if Tmog.currentSlot == 16 then
					Tmog.UndressSlot(Tmog.currentSlot)
				end
				TmogFramePlayerModel:TryOn(itemId)
				Tmog.CurrentGear[Tmog.currentSlot] = itemId
				Tmog.UpdateOutfitButtons()
				Tmog.UpdateItemTextures()
				Tmog.UpdateSelection()
				PlaySound("igMainMenuOptionCheckBoxOn")
			end
			if TmogFrameSharedItems:IsShown() then
				TmogFrameSharedItems:Hide()
			end
		elseif Tmog.currentTab == "OUTFITS" then
			local id = self:GetID()
			if id == 0 then
				StaticPopup_Show("TMOG_NEW_OUTFIT_CHOISE")
				return
			end
			local outfit = Tmog.PreviewButtons[id].name
			if IsShiftKeyDown() then
				Tmog.LinkOutfit(outfit)
				return
			end
			Tmog.currentOutfit = outfit
			Tmog.LoadOutfit(outfit)
			Tmog.UpdateSelection()
			PlaySound("igMainMenuOptionCheckBoxOn")
		end
	elseif button == "RightButton" then
		if Tmog.currentTab == "OUTFITS" then
			local id = self:GetID()
			if id <= 0 then return end
			if not TmogFrameOutfitOptionsDropDown.initialize then
				UIDropDownMenu_Initialize(TmogFrameOutfitOptionsDropDown, function()
					local outfit = Tmog.PreviewButtons[id].name
					local info = UIDropDownMenu_CreateInfo()
					info.text = outfit
					info.isTitle = true
					info.notCheckable = true
					UIDropDownMenu_AddButton(info)

					info = UIDropDownMenu_CreateInfo()
					info.text = "Rename"
					info.notCheckable = true
					info.func = function()
						StaticPopup_Show("TMOG_OUTFIT_RENAME", nil, nil, outfit)
					end
					UIDropDownMenu_AddButton(info)

					info = UIDropDownMenu_CreateInfo()
					info.text = "Share"
					info.notCheckable = true
					info.func = TmogFrameShareOutfit_OnClick
					info.arg1 = outfit
					UIDropDownMenu_AddButton(info)

					info = UIDropDownMenu_CreateInfo()
					info.text = "Delete"
					info.notCheckable = true
					info.func = function()
						StaticPopup_Show("TMOG_CONFIRM_DELETE_OUTFIT", outfit, nil, outfit)
					end
					UIDropDownMenu_AddButton(info)
				end, "MENU")
			end
			ToggleDropDownMenu(1, nil, TmogFrameOutfitOptionsDropDown, "cursor")
			TmogFrameSharedItems:Hide()
			return
		end

		for i = 1, Tmog.tsize(Tmog.SharedItemsFrames) do
			Tmog.SharedItemsFrames[i]:Hide()
		end

		TmogFrameSharedItems:ClearAllPoints()
		TmogFrameSharedItems:SetPoint("TOPLEFT", self, "BOTTOMLEFT", -2, 12)

		for k in pairs(SharedItems) do SharedItems[k] = nil end
		local index = 1
		local displayGroup = Tmog.ItemDisplayGroup[itemId]
		if displayGroup then
			for _, id in pairs(Tmog.DisplayGroups[displayGroup]) do
				Tmog.CacheItem(id)
				local name, _, quality, _, _, _, _, _, tex = GetItemInfo(id)
				if name and quality and id ~= itemId then
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

		for i = 1, Tmog.tsize(SharedItems) do
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
			if width > widestText then widestText = width end
		end
		TmogFrameSharedItems:SetWidth(45 + widestText)
	end
	DropDownList1:Hide()
end

function TmogFramePreview_OnEnter(self)
	_G[this:GetParent():GetName().."ItemModel"]:SetLight(unpack(Tmog.previewHighlight))

	if Tmog.currentTab == "ITEMS" then
		local itemID = this:GetID()
		Tmog.CacheItem(itemID)
		TmogTooltip.itemID = itemID
		TmogTooltip:SetOwner(this, "ANCHOR_RIGHT", -5, -8)
		TmogTooltip:SetHyperlink("item:"..itemID)

		local numLines = TmogTooltip:NumLines() or 0
		if numLines == 0 then
			return
		end

		local lastLine = _G["TmogTooltipTextLeft"..numLines]
		if not (lastLine and lastLine:GetText()) then
			return
		end

		lastLine:SetText(lastLine:GetText().."\n\n"..NORMAL.."ItemID: "..itemID)
		local name = GetItemInfo(itemID)
		local displayGroup = Tmog.ItemDisplayGroup[itemID]
		if not (name and displayGroup) then
			TmogTooltip:Show()
			return
		end
		if not Tmog.onlyUsable then
			local similarItemsText = ""
			local numSimilarItems = 0
			for _, id in pairs(Tmog.DisplayGroups[displayGroup]) do
				Tmog.CacheItem(id)
				local similarItem, _, quality = GetItemInfo(id)
				if similarItem and id ~= itemID then
					numSimilarItems = numSimilarItems + 1
					local _, _, _, color = GetItemQualityColor(quality or 1)
					similarItemsText = similarItemsText.."\n"..color..similarItem.."|r"
				end
			end
			if numSimilarItems > 0 then
				similarItemsText = NORMAL..L["Shares appearance with"]..":|r"..similarItemsText
				lastLine:SetText(lastLine:GetText().."\n\n"..similarItemsText)
			end
		else
			local proceed = false
			for _, id in pairs(Tmog.DisplayGroups[displayGroup]) do
				Tmog.CacheItem(itemID)
				if id ~= itemID and Tmog.IsUsableItem(id) then
					proceed = true
					break
				end
			end
			if proceed then
				local similarItemsText = ""
				local numSimilarItems = 0
				for _, id in pairs(Tmog.DisplayGroups[displayGroup]) do
					Tmog.CacheItem(id)
					local similarItem, _, quality = GetItemInfo(id)
					if id ~= itemID and similarItem then
						if Tmog.IsUsableItem(id) then
							numSimilarItems = numSimilarItems + 1
							local _, _, _, color = GetItemQualityColor(quality or 1)
							similarItemsText = similarItemsText.."\n"..color..similarItem.."|r"
						end
					end
				end
				if numSimilarItems > 0 then
					similarItemsText = NORMAL..L["Shares appearance with"]..":|r"..similarItemsText
					lastLine:SetText(lastLine:GetText().."\n\n"..similarItemsText)
				end
			end
		end
		TmogTooltip:Show()

	elseif Tmog.currentTab == "OUTFITS" then
		local outfit = this:GetParent().name
		if not outfit then return end

		TmogTooltip:SetOwner(this, "ANCHOR_RIGHT", -5, -8)
		TmogTooltip:AddDoubleLine(outfit, "", 1, 1, 1, 1, 1, 1)

		local numItemsInOutfit = 0
		local numCollected = 0

		for name in pairs(TMOG_PLAYER_OUTFITS) do

			if name == outfit then
				numItemsInOutfit = Tmog.tsize(TMOG_PLAYER_OUTFITS[name])

				for slot, itemID in pairs(TMOG_PLAYER_OUTFITS[name]) do
					local slotName

					for k, v in pairs(Tmog.InventorySlots) do
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
			TmogTooltip:AddLine(L["Create an outfit from currently selected items or import from ingame link/code."], 1, 0.82, 0, 1, true)
		else
			_G[this:GetParent():GetName().."ItemModel"]:SetLight(unpack(Tmog.previewHighlight))
			TmogTooltipTextRight1:SetText("("..numCollected.."/"..numItemsInOutfit..")")
			TmogTooltipTextRight1:Show()
		end
		TmogTooltip:Show()
	end
end

function TmogFramePreview_OnLeave(self)
	_G[self:GetParent():GetName().."ItemModel"]:SetLight(unpack(Tmog.previewNormalLight))
	_G[self:GetName().."PlusHighlight"]:Hide()
	TmogTooltip:Hide()
	TmogTooltip.itemID = nil
end

local hidden = false
function Tmog.HideUI()
	if not hidden then
		for slot in pairs(Tmog.InventorySlots) do
			_G["TmogFrame"..slot]:Hide()
		end
		TmogFrameResetOutfit:Hide()
		TmogFrameFullScreenButton:Hide()
		TmogFrameHideUI:SetText(L["Show UI"])
		hidden = true
	else
		for slot in pairs(Tmog.InventorySlots) do
			_G["TmogFrame"..slot]:Show()
		end
		TmogFrameResetOutfit:Show()
		TmogFrameFullScreenButton:Show()
		TmogFrameHideUI:SetText(L["Hide UI"])
		hidden = false
	end
end

function Tmog.ResetPages()
	Tmog.currentPage = 1
	for k in pairs(PagesMemory) do
		for i in pairs(PagesMemory[k]) do
			PagesMemory[k][i] = 1
		end
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
	if Tmog.currentTab == which then return end

	Tmog.currentTab = which

	if which == "ITEMS" then
		TmogFrameTab1:SetTextColor(1, 1, 1)
		TmogFrameTab2:SetTextColor(1, 0.82, 0)
		TmogFrameTab1:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\tab_active")
		TmogFrameTab1:SetPushedTexture("Interface\\AddOns\\Tmog\\Textures\\tab_active")
		TmogFrameTab2:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\tab_inactive")
		TmogFrameTab2:SetPushedTexture("Interface\\AddOns\\Tmog\\Textures\\tab_inactive")

		if Tmog.currentSlot then
			if Tmog.currentSlot ~= 15 and Tmog.currentSlot ~= 4 and Tmog.currentSlot ~= 19 then
				TmogFrameTypeDropDown:Show()
			end
			TmogFrameFiltersButton:Show()
		else
			Tmog.HidePreviews()
			Tmog.HidePagination()
		end

	elseif which == "OUTFITS" then
		Tmog.currentPage = 1
		TmogFrameTab1:SetTextColor(1, 0.82, 0)
		TmogFrameTab2:SetTextColor(1, 1, 1)
		TmogFrameTab1:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\tab_inactive")
		TmogFrameTab1:SetPushedTexture("Interface\\AddOns\\Tmog\\Textures\\tab_inactive")
		TmogFrameTab2:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\tab_active")
		TmogFrameTab2:SetPushedTexture("Interface\\AddOns\\Tmog\\Textures\\tab_active")

		TmogFrameTypeDropDown:Hide()
		TmogFrameFiltersButton:Hide()

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
			TmogTooltip:AddLine(GREEN..L["Collected"])
		else
			TmogTooltip:AddLine(YELLOW..L["Not collected"])
		end

		TmogTooltip:AddLine(NORMAL.."\nItemID: "..itemID, 1, 1, 1)
		TmogTooltip:Show()
	end

	if not name then
		local text = _G[strupper(string.sub(this:GetName(), 10))]

		TmogTooltip:SetText(text)
		TmogTooltip:Show()
	end
end

function Tmog.TypeDropDown_Initialize()
	local types = Tmog.GetTypesForSlot(Tmog.currentSlot)

	if not types then return end

	local info = UIDropDownMenu_CreateInfo()
	for _, v in pairs(types) do
		info.text = v
		info.checked = Tmog.currentType == v
		info.func = Tmog.SelectType
		info.arg1 = v
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

function Tmog.Sort(a, b)
	local nameA, _, qualityA = GetItemInfo(a)
	local nameB, _, qualityB = GetItemInfo(b)
	if not nameA or not nameB then return false end
	if qualityA == qualityB then
		return a > b
		-- return nameA < nameB
	else
		return qualityA > qualityB
	end
end

