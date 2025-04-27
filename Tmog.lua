-- Dressing room code - modified CosminPOP's Turtle_TransmogUI
-- Tooltip code - adapted from https://github.com/Zebouski/MoPGearTooltips/tree/masterturtle
local NORMAL = NORMAL_FONT_COLOR_CODE
local YELLOW = "|cffFFFF00"
local WHITE = HIGHLIGHT_FONT_COLOR_CODE
local GREEN = "|cff00A000" -- GREEN_FONT_COLOR_CODE
local GREY = GRAY_FONT_COLOR_CODE
local BLUE = "|cff0070de"

local tinsert = table.insert
local tremove = table.remove
local getn = table.getn
local strfind = string.find
local strlower = string.lower
local GetItemInfo = GetItemInfo

local version = GetAddOnMetadata("Tmog", "Version")
local verbose = false
local _, playerClass = UnitClass("player")
local _, playerRace = UnitRace("player")

local playerModelLight   = { 1, 0, -0.3, -1, -1,   0.55, 1.0, 1.0, 1.0,   0.8, 1.0, 1.0, 1.0 }
local previewNormalLight = { 1, 0, -0.3,  0, -1,   0.65, 1.0, 1.0, 1.0,   0.8, 1.0, 1.0, 1.0 }
local previewHighlight   = { 1, 0, -0.3,  0, -1,   0.9,  1.0, 1.0, 1.0,   0.8, 1.0, 1.0, 1.0 }
local FSLight            = { 1, 0, -0.5, -1, -0.7, 0.42, 1.0, 1.0, 1.0,   0.8, 1.0, 1.0, 1.0 }

local TmogTooltip = CreateFrame("GameTooltip", "TmogTooltip", UIParent, "GameTooltipTemplate")
TmogTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

local Tmog = {}
local PreviewButtons = {}
local CurrentGear = {}
local ActualGear = {} -- actual gear + transmog
local sex = UnitSex("player") - 1 -- 2 - female, 1 - male
local race = strlower(playerRace)
local currentType = "Cloth"
local currentSlot = nil
local currentPage = 1
local totalPages = 1
local itemsPerPage = 15
local CurrentTypesList = {} -- available types for current slot
local currentOutfit = nil
local collected = true -- check box
local notCollected = true -- check box
local onlyUsable = false -- check box
local ignoreLevel = false -- check box
local canDualWeild = playerClass == "WARRIOR" or playerClass == "HUNTER" or playerClass == "ROGUE"
local currentTab = "items"
local flush = true

local TypesDefault = {
    "Cloth",
    "Leather",
    "Mail",
    "Plate",
}
local TypesMisc = {
    "Cloth",
    "Leather",
    "Mail",
    "Plate",
    "Miscellaneous",
}
local TypesBack = {
    "Cloth",
}
local TypesShirt = {
    "Miscellaneous",
}
local TypesMH = {
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
local TypesOH = {
    "Daggers",
    "One-Handed Axes",
    "One-Handed Swords",
    "One-Handed Maces",
    "Fist Weapons",
    "Miscellaneous",
    "Shields",
}
local TypesRanged = {
    "Bows",
    "Guns",
    "Crossbows",
    "Wands",
}
-- store last selected type for each slot
local SlotsTypes = {
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
-- store last selected page for each slot and type
local Pages = {
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
local Unusable = {
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
    ["INVTYPE_RELIC"] = 18,
}

local Druid = {
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

local Shaman = {
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

local Paladin = {
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

local Mage = {
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

local Warlock = {
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

local Priest = {
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

local Warrior = {
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

local Rogue = {
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

local Hunter = {
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

local Positions = {
    [1] = {
        bloodelf =  { { 10.8,  0,   -3.4, 0.61, }, { 8.8,  0.2, -2.7, 0.61, }, },
        scourge =   { { 6.8,   0,   -2.2, 0.61, }, { 7.8, -0.5, -2.7, 0.61, }, },
        orc =       { { 8.8,   0,   -2.7, 0.2,  }, { 9.1,  0,   -2.7, 0.61, }, },
        gnome =     { { 3.8,   0,   -1,   0.61, }, { 3.8,  0,   -1,   0.61, }, },
        dwarf =     { { 6.3,   0,   -1.2, 0.61, }, { 6.3,  0,   -1.7, 0.61, }, },
        tauren =    { { 8.8,  -0.5, -2.2, 0.3,  }, { 8.8, -0.5, -1.7, 0.61, }, },
        nightelf =  { { 11.8,  0,   -3.7, 0.61, }, { 11.8, 0,   -3.2, 0.61, }, },
        human =     { { 8.8,   0,   -3.2, 0.61, }, { 7.8,  0,   -2.7, 0.61, }, },
        troll =     { { 10.8, -0.5, -2.2, 0.3,  }, { 11.1, 0,   -3,   0.61, }, },
        goblin =    { { 5.3,   0,   -1.3, 0.61, }, { 6.3,  0,   -0.7, 0.61, }, },
    },
    [3] = {
        bloodelf =  { { 7.8, 0.5, -2.7, 0.61, }, { 7.8, 0.5, -2.2, 0.61, }, },
        scourge =   { { 5.8, 0.5, -1.7, 0.61, }, { 6.8, 0,   -1.7, 0.61, }, },
        orc =       { { 5.3, 0.5, -1.7, 0.61, }, { 6.3, 0.5, -1.7, 0.61, }, },
        gnome =     { { 2.8, 0.5, -0.2, 0.61, }, { 2.8, 0.5, -0.2, 0.61, }, },
        dwarf =     { { 4.8, 0.5, -0.9, 0.61, }, { 4.8, 0.2, -0.9, 0.61, }, },
        tauren =    { { 5.3, 0.5, -2.2, 0.61, }, { 5.8, 0.5, -1.7, 0.61, }, },
        nightelf =  { { 8.8, 0.5, -2.2, 0.61, }, { 8.8, 0.5, -1.7, 0.61, }, },
        human =     { { 5.8, 0.5, -1.7, 0.61, }, { 5.8, 0.5, -1.7, 0.61, }, },
        troll =     { { 7.8, 0.5, -1.7, 0.61, }, { 9.1, 0.5, -1.7, 0.61, }, },
        goblin =    { { 4.3, 0.5, -0.2, 0.61, }, { 4.8, 0.5, -0.2, 0.61, }, },
    },
    [5] = {
        bloodelf =  { { 7.8,  0.1, -1.2, 0.3, }, { 6.8,  0.3, -1.2, 0.3, }, },
        scourge =   { { 5.8,  0.1, -1.2, 0.3, }, { 5.8,  0.1, -1.2, 0.3, }, },
        orc =       { { 5.8,  0.1, -1.2, 0.3, }, { 6.8,  0.1, -0.7, 0.3, }, },
        gnome =     { { 3.8,  0.1,  0.6, 0.3, }, { 3.8,  0.1,  0.6, 0.3, }, },
        dwarf =     { { 4.5,  0.1,  0.3, 0.3, }, { 4.5,  0.1,  0.3, 0.3, }, },
        tauren =    { { 5.8, -0.1, -0.2, 0.3, }, { 5.8, -0.1, -0.2, 0.3, }, },
        nightelf =  { { 8.8,  0.1, -1.2, 0.3, }, { 8.8,  0.1, -1.2, 0.3, }, },
        human =     { { 5.8,  0.1, -1.2, 0.3, }, { 5.8,  0.1, -1.2, 0.3, }, },
        troll =     { { 7.8, -0.1, -0.2, 0.3, }, { 7.8, -0.1, -0.2, 0.3, }, },
        goblin =    { { 4.3,  0.1,  0.3, 0.3, }, { 4.8,  0.1,  0.3, 0.3, }, },
    },
    [6] = {
        bloodelf =  { { 10, 0, -0.6, 0.31, }, { 8.3, 0.3, -0.4, 0.31, }, },
        scourge =   { { 8,  0, -0.4, 0.31, }, { 8,   0,   -0.4, 0.31, }, },
        orc =       { { 8,  0, -0.4, 0.31, }, { 8,   0,   -0.4, 0.31, }, },
        gnome =     { { 4,  0,  1.1, 0.31, }, { 4,   0,    1.1, 0.31, }, },
        dwarf =     { { 5,  0,  0.6, 0.31, }, { 5,   0,    0.6, 0.31, }, },
        tauren =    { { 9,  0, -0.1, 0.31, }, { 8,   0,    1.6, 0.31, }, },
        nightelf =  { { 10, 0, -0.4, 0.31, }, { 10,  0,   -0.4, 0.31, }, },
        human =     { { 7,  0, -0.4, 0.31, }, { 7,   0,   -0.9, 0.31, }, },
        troll =     { { 10, 0, -0.4, 0.31, }, { 10,  0,   -0.4, 0.31, }, },
        goblin =    { { 6,  0,  1.1, 0.31, }, { 7,   0,    1.1, 0.31, }, },
    },
    [7] = {
        bloodelf =  { { 7.8, 0, 0.6, 0.31, }, { 5.8, 0.3, 0.9, 0.31, }, },
        scourge =   { { 5.8, 0, 0.9, 0.31, }, { 7.1, 0,   0.9, 0.31, }, },
        orc =       { { 5.8, 0, 0.9, 0.31, }, { 5.8, 0,   0.9, 0.31, }, },
        gnome =     { { 3.8, 0, 1.1, 0.31, }, { 3.8, 0,   1.1, 0.31, }, },
        dwarf =     { { 4.8, 0, 1.4, 0.31, }, { 4.8, 0,   1.4, 0.31, }, },
        tauren =    { { 6.8, 0, 0.9, 0.31, }, { 5.8, 0,   1.9, 0.31, }, },
        nightelf =  { { 8.8, 0, 0.9, 0.31, }, { 8.8, 0,   0.9, 0.31, }, },
        human =     { { 5.8, 0, 0.9, 0.31, }, { 5.8, 0,   0.9, 0.31, }, },
        troll =     { { 7.8, 0, 0.9, 0.31, }, { 7.8, 0,   1.9, 0.31, }, },
        goblin =    { { 4.9, 0, 1.2, 0.31, }, { 5.3, 0,   0.9, 0.31, }, },
    },
    [8] = {
        bloodelf =  { { 8.8, -0.3, 1.5, 1.2,  }, { 6.3,  0.4, 1.7, 0,    }, },
        scourge =   { { 5.8,  0,   1.5, 0.61, }, { 7.1,  0,   1.5, 0.61, }, },
        orc =       { { 5.8,  0,   1.5, 0.61, }, { 5.8,  0,   1.5, 0.61, }, },
        gnome =     { { 4.8,  0,   1.4, 0.61, }, { 4.3,  0.1, 1.4, 0.61, }, },
        dwarf =     { { 4.8,  0,   2.1, 0.61, }, { 5.3, -0.2, 1.9, 0.1,  }, },
        tauren =    { { 6.8,  0,   1.5, 0.61, }, { 6.8,  0,   2.5, 0.61, }, },
        nightelf =  { { 8.8,  0,   1.8, 0.3,  }, { 8.8,  0,   1.8, 0.3,  }, },
        human =     { { 6.8,  0,   1.5, 0.3,  }, { 5.8,  0,   1.5, 0.61, }, },
        troll =     { { 7.8,  0,   1.5, 0.61, }, { 8.8,  0,   2.5, 0.61, }, },
        goblin =    { { 4.8,  0,   1.8, 1.2,  }, { 5.3,  0,   1.5, 0.61, }, },
    },
    [9] = {
        bloodelf =  { { 8.8,  0.4, -0.3, 1.5, }, { 7.3,  0.4, -0.3, 1.5, }, },
        scourge =   { { 5.8,  0.4, -0.3, 1.5, }, { 7.1, -0.1, -0.3, 1.5, }, },
        orc =       { { 5.8,  0.4, -0.3, 1.5, }, { 6.3,  0.4, -0.3, 1.5, }, },
        gnome =     { { 4.3,  0.4,  0.7, 1.5, }, { 4.3,  0.4,  0.7, 1.5, }, },
        dwarf =     { { 4.6,  0.1,  0.8, 1.5, }, { 5.2,  0.1,  0.6, 1.5, }, },
        tauren =    { { 5.8,  0.2, -0.3, 1.5, }, { 7.1,  0.2,  1,   1.5, }, },
        nightelf =  { { 10.8, 0.4, -0.3, 1.5, }, { 10.8, 0.4, -0.3, 1.5, }, },
        human =     { { 6.8,  0.4, -0.3, 1.5, }, { 5.8,  0.4, -0.3, 1.5, }, },
        troll =     { { 7.8,  0.4,  0.6, 1.5, }, { 9.8,  0.4,  0.6, 1.5, }, },
        goblin =    { { 4.8,  0.4,  1.2, 1.5, }, { 4.8,  0.4,  1.2, 1.5, }, },
    },
    [15] = {
        bloodelf =  { { 7.8, -0.3, -1,   3.2, }, { 4.8, 0, -1,   3.2, }, },
        scourge =   { { 4.8, 0,    -1,   3.2, }, { 5.8, 0,  0,   3.2, }, },
        orc =       { { 4.8, 0,    -1,   3.2, }, { 4.8, 0, -0.2, 3.2, }, },
        gnome =     { { 2.8, 0,     0.7, 3.2, }, { 2.8, 0,  0.7, 3.2, }, },
        dwarf =     { { 3.8, 0,     0.5, 3.2, }, { 3.8, 0,  0.5, 3.2, }, },
        tauren =    { { 5.6, 0,     0.2, 3.2, }, { 5.6, 0,  0.2, 3.2, }, },
        nightelf =  { { 7.8, 0,    -1,   3.2, }, { 7.8, 0, -1,   3.2, }, },
        human =     { { 4.8, 0,    -1,   3.2, }, { 4.8, 0, -1,   3.2, }, },
        troll =     { { 6.8, 0,    -1,   3.2, }, { 7.8, 0,  0,   3.2, }, },
        goblin =    { { 3.8, 0,     0.5, 3.2, }, { 4.3, 0,  0.5, 3.2, }, },
    },
    [16] = {
        bloodelf =  { { 6.8, 0, 0.4, 0.61, }, { 6.3, 0.2, 0.4, 0.61, }, },
        scourge =   { { 3.8, 0, 0.4, 0.61, }, { 3.8, 0, 0.4,   0.61, }, },
        orc =       { { 3.8, 0, 0.4, 0.61, }, { 4.8, 0, 0.4,   0.61, }, },
        gnome =     { { 1.8, 0, 0.4, 0.61, }, { 1.8, 0, 0.4,   0.61, }, },
        dwarf =     { { 2.8, 0, 0.4, 0.61, }, { 2.8, 0, 0.4,   0.61, }, },
        tauren =    { { 3.8, 0, 0.4, 0.61, }, { 3.8, 0, 0.4,   0.61, }, },
        nightelf =  { { 6.8, 0, 0.4, 0.61, }, { 6.8, 0, 0.4,   0.61, }, },
        human =     { { 3.8, 0, 0.4, 0.61, }, { 3.8, 0, 0.4,   0.61, }, },
        troll =     { { 5.8, 0, 1.4, 0.61, }, { 5.8, 0, 0.4,   0.61, }, },
        goblin =    { { 3.3, 0, 0.9, 0.9,  }, { 3.3, 0, 0.4,   0.61, }, },
    },
    [18] = {
        bloodelf =  { { 6.8, 0, 0.4, -0.61, }, { 6.3, 0.2, 0.4, -1,    }, },
        scourge =   { { 3.8, 0, 0.4, -0.61, }, { 3.8, 0,   0.4, -0.61, }, },
        orc =       { { 3.8, 0, 0.4, -0.61, }, { 4.8, 0,   0.4, -0.61, }, },
        gnome =     { { 1.8, 0, 0.4, -0.61, }, { 1.8, 0,   0.4, -0.61, }, },
        dwarf =     { { 2.8, 0, 0.4, -0.61, }, { 2.8, 0,   0.4, -0.61, }, },
        tauren =    { { 3.8, 0, 0.4, -0.61, }, { 3.8, 0,   0.4, -0.61, }, },
        nightelf =  { { 6.8, 0, 0.4, -0.61, }, { 6.8, 0,   0.4, -0.61, }, },
        human =     { { 3.8, 0, 0.4, -0.61, }, { 3.8, 0,   0.4, -0.61, }, },
        troll =     { { 5.8, 0, 1.4, -0.61, }, { 5.8, 0,   0.4, -0.61, }, },
        goblin =    { { 3.3, 0, 0.9, -0.61, }, { 3.3, 0,   0.4, -0.61, }, },
    },
}
Positions[4] = Positions[5]
Positions[19] = Positions[5]
Positions[10] = Positions[9]
Positions[17] = Positions[16]

local function print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("["..BLUE.."Tmog|r] "..(msg or "nil"))
end

local function debug(...)
    if verbose ~= true then
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

local function ceil(num)
    if num > math.floor(num) then
        return math.floor(num + 1)
    end
    return math.floor(num + 0.5)
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

local function IDFromLink(link)
    if not link then
        return nil
    end
    local _, _, id = strfind(link, "item:(%d+)")
    if id then
        return tonumber(id)
    end
    return nil
end

local function GetTableForClass(class)
    if class == "DRUID" then
        return Druid
    elseif class == "PALADIN" then
        return Paladin
    elseif class == "SHAMAN" then
        return Shaman
    elseif class == "MAGE" then
        return Mage
    elseif class == "WARLOCK" then
        return Warlock
    elseif class == "PRIEST" then
        return Priest
    elseif class == "WARRIOR" then
        return Warrior
    elseif class == "ROGUE" then
        return Rogue
    elseif class == "HUNTER" then
        return Hunter
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
      		if itemName and itemName == name then
        		lastSearchID = itemID
				break
     		end
    	end
		lastSearchName = name
  	end
	return lastSearchID
end

local function HookTooltip(tooltip)
    local HookSetLootRollItem       = tooltip.SetLootRollItem
    local HookSetLootItem           = tooltip.SetLootItem
    local HookSetMerchantItem       = tooltip.SetMerchantItem
    local HookSetQuestLogItem       = tooltip.SetQuestLogItem
    local HookSetQuestItem          = tooltip.SetQuestItem
    local HookSetHyperlink          = tooltip.SetHyperlink
    local HookSetBagItem            = tooltip.SetBagItem
    local HookSetInboxItem          = tooltip.SetInboxItem
    local HookSetInventoryItem      = tooltip.SetInventoryItem
    local HookSetCraftItem          = tooltip.SetCraftItem
    local HookSetCraftSpell         = tooltip.SetCraftSpell
    local HookSetTradeSkillItem     = tooltip.SetTradeSkillItem
    local HookSetAuctionItem        = tooltip.SetAuctionItem
    local HookSetAuctionSellItem    = tooltip.SetAuctionSellItem
    local HookSetTradePlayerItem    = tooltip.SetTradePlayerItem
    local HookSetTradeTargetItem    = tooltip.SetTradeTargetItem

    local original_OnHide = tooltip:GetScript("OnHide")
    tooltip:SetScript("OnHide", function()
        if original_OnHide then
            original_OnHide()
        end
        this.itemID = nil
    end)

    function tooltip.SetLootRollItem(self, id)
        HookSetLootRollItem(self, id)
        local _, _, itemID = strfind(GetLootRollItemLink(id) or "", "item:(%d+)")
        self.itemID = itemID
        Tmog_ExtendTooltip(self)
    end

    function tooltip.SetLootItem(self, slot)
        HookSetLootItem(self, slot)
        local _, _, itemID = strfind(GetLootSlotLink(slot) or "", "item:(%d+)")
        self.itemID = itemID
        Tmog_ExtendTooltip(self)
    end

    function tooltip.SetMerchantItem(self, merchantIndex)
        HookSetMerchantItem(self, merchantIndex)
        local _, _, itemID = strfind(GetMerchantItemLink(merchantIndex) or "", "item:(%d+)")
        self.itemID = itemID
        Tmog_ExtendTooltip(self)
    end

    function tooltip.SetQuestLogItem(self, itemType, index)
        HookSetQuestLogItem(self, itemType, index)
        local _, _, itemID = strfind(GetQuestLogItemLink(itemType, index) or "", "item:(%d+)")
        self.itemID = itemID
        Tmog_ExtendTooltip(self)
    end

    function tooltip.SetQuestItem(self, itemType, index)
        HookSetQuestItem(self, itemType, index)
        local _, _, itemID = strfind(GetQuestItemLink(itemType, index) or "", "item:(%d+)")
        self.itemID = itemID
        Tmog_ExtendTooltip(self)
    end

    function tooltip.SetHyperlink(self, arg1)
        HookSetHyperlink(self, arg1)
        local _, _, id = strfind(arg1 or "", "item:(%d+)")
        self.itemID = id
        Tmog_ExtendTooltip(self)
    end

    function tooltip.SetBagItem(self, container, slot)
        local hasCooldown, repairCost = HookSetBagItem(self, container, slot)
        local _, _, id = strfind(GetContainerItemLink(container, slot) or "", "item:(%d+)")
        self.itemID = id
        Tmog_ExtendTooltip(self)
        return hasCooldown, repairCost
    end

    function tooltip.SetInboxItem(self, mailID, attachmentIndex)
        HookSetInboxItem(self, mailID, attachmentIndex)
        local itemName = GetInboxItem(mailID)
        self.itemID = GetItemIDByName(itemName)
        Tmog_ExtendTooltip(self)
    end

    function tooltip.SetInventoryItem(self, unit, slot)
        local hasItem, hasCooldown, repairCost = HookSetInventoryItem(self, unit, slot)
        local _, _, id = strfind(GetInventoryItemLink(unit, slot) or "", "item:(%d+)")
        self.itemID = id
        Tmog_ExtendTooltip(self)
        return hasItem, hasCooldown, repairCost
    end

    function tooltip.SetCraftItem(self, skill, slot)
        HookSetCraftItem(self, skill, slot)
        local _, _, id = strfind(GetCraftReagentItemLink(skill, slot) or "", "item:(%d+)")
        self.itemID = id
        Tmog_ExtendTooltip(self)
    end

    function tooltip.SetCraftSpell(self, slot)
        HookSetCraftSpell(self, slot)
        local _, _, id = strfind(GetCraftItemLink(slot) or "", "item:(%d+)")
        self.itemID = id
        Tmog_ExtendTooltip(self)
    end

    function tooltip.SetTradeSkillItem(self, skillIndex, reagentIndex)
        HookSetTradeSkillItem(self, skillIndex, reagentIndex)
        if reagentIndex then
            local _, _, id = strfind(GetTradeSkillReagentItemLink(skillIndex, reagentIndex) or "", "item:(%d+)")
            self.itemID = id
        else
            local _, _, id = strfind(GetTradeSkillItemLink(skillIndex) or "", "item:(%d+)")
            self.itemID = id
        end
        Tmog_ExtendTooltip(self)
    end

    function tooltip.SetAuctionItem(self, atype, index)
        HookSetAuctionItem(self, atype, index)
        local itemName = GetAuctionItemInfo(atype, index)
        self.itemID = GetItemIDByName(itemName)
        Tmog_ExtendTooltip(self)
    end

    function tooltip.SetAuctionSellItem(self)
        HookSetAuctionSellItem(self)
        local itemName = GetAuctionSellItemInfo()
        self.itemID = GetItemIDByName(itemName)
        Tmog_ExtendTooltip(self)
    end

    function tooltip.SetTradePlayerItem(self, index)
        HookSetTradePlayerItem(self, index)
        local _, _, id = strfind(GetTradePlayerItemLink(index) or "", "item:(%d+)")
        self.itemID = id
        Tmog_ExtendTooltip(self)
    end

    function tooltip.SetTradeTargetItem(self, index)
        HookSetTradeTargetItem(self, index)
        local _, _, id = strfind(GetTradeTargetItemLink(index) or "", "item:(%d+)")
        self.itemID = id
        Tmog_ExtendTooltip(self)
    end
end

HookTooltip(GameTooltip)
HookTooltip(ItemRefTooltip)
HookTooltip(TmogTooltip)

local originalTooltip = {}
-- return slot if this is gear and we can equip it
local function IsGear(itemID, tooltip)
    local itemName, itemLink, itemQuality, itemLevel, itemType, itemSubType, itemCount, itemEquipLoc, itemTexture = GetItemInfo(itemID)
    local tableToCheck = GetTableForClass(playerClass)
    -- (TWoW bug)
    if itemSubType == "-" then
        itemSubType = "Miscellaneous"
    end

    debug(itemID, itemName, itemType, itemSubType, itemEquipLoc)
    if SetContains(tableToCheck, itemSubType) and SetContains(InventoryTypeToSlot, itemEquipLoc) then
        if not canDualWeild and itemEquipLoc == "INVTYPE_WEAPONOFFHAND" then
            debug("cant dual weild")
            return nil
        end
        if itemType == "Weapon" and itemSubType == "Miscellaneous" then
            debug("not a real weapon")
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
        for row = 1, tsize(originalTooltip) do
            if originalTooltip[row] then
                local _, _, classesRow = strfind(originalTooltip[row], "Classes: (.*)")
                if classesRow then
                    if not strfind(classesRow, UnitClass("player"), 1, true) then
                        debug("bad class")
                        return nil
                    end
                end
            end
        end
        return InventoryTypeToSlot[itemEquipLoc]
    end
end

local WrappingLines = {
    ["Set: %s"] = gsub("^"..ITEM_SET_BONUS, " %%s", ""),
    ["(%d) Set: %s"] = gsub(gsub(ITEM_SET_BONUS_GRAY, "%(%%d%)", "^%%(%%d%%)"), " %%s", ""),
    ["Effect: %s"] = gsub("^"..ITEM_SPELL_EFFECT, " %%s", ""),
    ["Equip:"] = "^"..ITEM_SPELL_TRIGGER_ONEQUIP,
    ["Chance on hit:"] = "^"..ITEM_SPELL_TRIGGER_ONPROC,
    ["Use:"] = "^"..ITEM_SPELL_TRIGGER_ONUSE,
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
        left = getglobal(name .. "TextLeft" .. i)
        right = getglobal(name .. "TextRight" .. i)
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

    if SetContains(TMOG_CACHE[slot], itemID) then
        status = GREEN.."Collected|r"
    else
        status = YELLOW.."Not collected|r"
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

    tooltip:Show()
end

local lastItemName = nil
local lastSlot = nil
function Tmog_ExtendTooltip(tooltip)
    local tooltipName = tooltip:GetName()
    local itemName = getglobal(tooltipName .. "TextLeft1"):GetText()
    local line2 = getglobal(tooltipName .. "TextLeft2")

    if not itemName or not tooltip.itemID or not line2 then
        return
    end

    local itemID = tonumber(tooltip.itemID)
    Tmog:CacheItem(itemID)
    itemName = GetItemInfo(itemID)

    if itemName ~= lastItemName then
        local slot = IsGear(itemID, tooltip)
        lastItemName = itemName
        lastSlot = slot

        if not slot then
            return
        end

        if line2:GetText() then
            AddCollectionStatus(slot, itemID, tooltip)
        end

    elseif lastSlot then
        if line2:GetText() then
            AddCollectionStatus(lastSlot, itemID, tooltip)
        end
    end

    tooltip:Show()
end

local original_OnShow = GameTooltip:GetScript("OnShow")
GameTooltip:SetScript("OnShow", function()
    if original_OnShow then
        original_OnShow()
    end
    if aux_frame and aux_frame:IsVisible() then
        if GetMouseFocus():GetParent() then
            if GetMouseFocus():GetParent().row then
                if GetMouseFocus():GetParent().row.record.item_id then
                    GameTooltip.itemID = GetMouseFocus():GetParent().row.record.item_id
                    Tmog_ExtendTooltip(GameTooltip)
                end
            end
        end
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

    TmogFrameRaceBackground:SetTexture("Interface\\AddOns\\Tmog\\Textures\\transmogbackground"..race)

    TmogFrameSaveOutfit:Disable()
    TmogFrameDeleteOutfit:Disable()

    UIDropDownMenu_SetText("Outfits", TmogFrameOutfitsDropDown)

    TmogFrameCollected:SetChecked(collected)
    TmogFrameNotCollected:SetChecked(notCollected)
    TmogFrameUsable:SetChecked(onlyUsable)

    tinsert(UISpecialFrames, "TmogFrame")
end

local firstLoad = true
local atlasLootHooked = false
function TmogFrame_OnEvent()
    if event == "PLAYER_ENTERING_WORLD" then
        TmogFramePlayerModel:SetUnit("player")

        if firstLoad then
            Tmog_Reset()
            firstLoad = false
        end

        if TmogFrame:IsVisible() then
            TmogFrame:Hide()
        end

        if not atlasLootHooked then
            if AtlasLootTooltip then
                HookTooltip(AtlasLootTooltip)
                HookTooltip(AtlasLootTooltip2)
            end
            atlasLootHooked = true
        end

        return
    end

    if event == "ADDON_LOADED" and arg1 == "Tmog" then
        TmogFrame:UnregisterEvent("ADDON_LOADED")

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
            [18] = {}, -- RangedSlot
            [4] = {},  -- ShirtSlot 
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

        UIDropDownMenu_Initialize(TmogFrameTypeDropDown, Tmog_TypeDropDown_Initialize)
        UIDropDownMenu_Initialize(TmogFrameOutfitsDropDown, Tmog_OutfitsDropDown_Initialize)
        UIDropDownMenu_SetWidth(100, TmogFrameTypeDropDown)
        UIDropDownMenu_SetWidth(115, TmogFrameOutfitsDropDown)

        TmogButton:SetMovable(not TMOG_LOCKED)
        TmogButton:ClearAllPoints()
        TmogButton:SetPoint("CENTER", UIParent, "BOTTOMLEFT", unpack(TMOG_POSITION or {TmogButton:GetCenter()}))

        return
    end

    if verbose and event == "CHAT_MSG_ADDON" and (strfind(arg1, "TW_TRANSMOG", 1, true) or strfind(arg1, "TW_CHAT_MSG_WHISPER", 1, true)) then
        debug(arg1, arg2, arg3, arg4)
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

                for _, InventorySlotId in pairs(InventorySlots) do
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
                        local actualItemId = IDFromLink(link) or 0

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
                local itemID = IDFromLink(link)

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
end

local cacheZ, cacheX, cacheY = 0, 0, 0
local showingHelm = 1
local showingCloak = 1
function TmogFrame_OnShow()
    showingHelm = ShowingHelm()
    showingCloak = ShowingCloak()

    TmogFramePlayerModel:SetPosition(cacheZ, cacheX, cacheY)
    TmogFramePlayerModel:Undress()

    for slot, itemID in pairs(CurrentGear) do
        if slot ~= 18 and slot ~= 17 and slot ~= 16 then
            if (slot == 1 and showingHelm == 1) or
                (slot == 15 and showingCloak == 1) or
                (slot ~= 1 and slot ~= 15)
                then
                TmogFramePlayerModel:TryOn(itemID)
            end
        end
    end
    TmogFramePlayerModel:TryOn(CurrentGear[18])
    TmogFramePlayerModel:TryOn(CurrentGear[16])
    TmogFramePlayerModel:TryOn(CurrentGear[17])

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
    currentOutfit = nil
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
        TmogFramePlayerModel:TryOn(IDFromLink(tabardLink))
    end

    for _, InventorySlotId in pairs(InventorySlots) do
        ActualGear[InventorySlotId] = 0
    end

    for _, InventorySlotId in pairs(InventorySlots) do
        CurrentGear[InventorySlotId] = 0
    end

    for _, InventorySlotId in pairs(InventorySlots) do
        local link = GetInventoryItemLink("player", InventorySlotId)
        ActualGear[InventorySlotId] = IDFromLink(link) or 0
    end

    for slot in pairs(TMOG_TRANSMOG_STATUS) do
        local link = GetInventoryItemLink("player", slot)
        local id = IDFromLink(link) or 0

        for actualItemID, transmogID in pairs(TMOG_TRANSMOG_STATUS[slot]) do
            if actualItemID == id then
                ActualGear[slot] = transmogID
            end
        end
    end

    for _, InventorySlotId in pairs(InventorySlots) do
        CurrentGear[InventorySlotId] = ActualGear[InventorySlotId]
    end

    Tmog:UpdateItemTextures()
    Tmog:RemoveSelection()
end

function Tmog_SelectType(typeStr)
    if TmogFrameSharedItems:IsVisible() then
        TmogFrameSharedItems:Hide()
    end
    UIDropDownMenu_SetText(typeStr, TmogFrameTypeDropDown)
    currentType = typeStr
    currentPage = 1
    flush = true
    if currentSlot and currentType and Pages[currentSlot][currentType] then
        SlotsTypes[currentSlot] = typeStr
        if SetContains(LinkedSlots, currentSlot) then
            for k in SlotsTypes do
                if SetContains(LinkedSlots, k) and SetContains(Pages[k], typeStr) then
                    SlotsTypes[k] = typeStr
                end
            end
        end
        Tmog_ChangePage(Pages[currentSlot][currentType] - 1)
        return
    end

    Tmog:DrawPreviews()
end

function Tmog:HidePreviews()
    for index in pairs(PreviewButtons) do
        local buttonName = PreviewButtons[index]:GetName()
        getglobal(buttonName.."ItemModel"):SetAlpha(0)
        getglobal(buttonName.."Button"):Hide()
        getglobal(buttonName.."ButtonCheck"):Hide()
    end
end

local function IsRed(tooltipLine)
    local r, g, b = getglobal(tooltipLine):GetTextColor()
    if r > 0.9 and g < 0.2 and b < 0.2 then
        return true
    end
    return false
end

local TmogScanTooltip = CreateFrame("GameTooltip", "TmogScanTooltip", nil, "GameTooltipTemplate")
TmogScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

function Tmog:IsUsableItem(id)
    if SetContains(Unusable[currentSlot][currentType], id) then
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
                if not ignoreLevel then
                    isUsable = false
                    Unusable[currentSlot][currentType][id] = true
                end
            else
                isUsable = false
                Unusable[currentSlot][currentType][id] = true
            end
        end
    end
    local _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(id)
    if not canDualWeild and (itemEquipLoc == "INVTYPE_WEAPONOFFHAND" or (itemEquipLoc == "INVTYPE_WEAPON" and currentSlot == 17)) then
        isUsable = false
        Unusable[currentSlot][currentType][id] = true
    end
    return isUsable
end

local DrawTable = {
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
    local index = 0
    local row = 0
    local col = 0
    local itemIndex = 1
    local outfitIndex = 1
    local lowerLimit = (currentPage - 1) * itemsPerPage
    local upperLimit = currentPage * itemsPerPage
    local type = currentType

    if currentTab == "items" then
        if (not collected and not notCollected) or not currentSlot then
            Tmog:HidePreviews()
            Tmog:HidePagination()
            currentPage = 1
            return
        end

        if searchStr ~= "" then
            type = "SearchResult"
        end
        if flush then
            debug("flushing", "slot "..currentSlot, " type "..type)
            for k in pairs(DrawTable[currentSlot][type]) do
                DrawTable[currentSlot][type][k] = nil
            end

            -- only Collected checked
            if collected and not notCollected then
                if searchStr ~= "" then
                    for k in pairs(TmogGearDB[currentSlot]) do
                        for itemID, itemName in pairs(TmogGearDB[currentSlot][k]) do
                            if SetContains(TMOG_CACHE[currentSlot], itemID) then
                                local name = strlower(itemName)
                                if strfind(name, searchStr, 1 ,true) then
                                    DrawTable[currentSlot][type][itemID] = itemName
                                end
                            end
                        end
                    end
                elseif TmogGearDB[currentSlot][type] then
                    for itemID, name in pairs(TmogGearDB[currentSlot][type]) do
                        if SetContains(TMOG_CACHE[currentSlot], itemID) then
                            DrawTable[currentSlot][type][itemID] = name
                        end
                    end
                end
            -- only Not Collected checked
            elseif notCollected and not collected then
                if searchStr ~= "" then
                    for k in pairs(TmogGearDB[currentSlot]) do
                        for itemID, itemName in pairs(TmogGearDB[currentSlot][k]) do
                            if not SetContains(TMOG_CACHE[currentSlot], itemID) then
                                local name = strlower(itemName)
                                if strfind(name, searchStr, 1 ,true) then
                                    DrawTable[currentSlot][type][itemID] = itemName
                                end
                            end
                        end
                    end
                elseif TmogGearDB[currentSlot][type] then
                    for itemID, name in pairs(TmogGearDB[currentSlot][type]) do
                        if not SetContains(TMOG_CACHE[currentSlot], itemID) then
                            DrawTable[currentSlot][type][itemID] = name
                        end
                    end
                end
            -- both checked
            elseif collected and notCollected then
                if searchStr ~= "" then
                    for k in pairs(TmogGearDB[currentSlot]) do
                        for itemID, itemName in pairs(TmogGearDB[currentSlot][k]) do
                            local name = strlower(itemName)
                            if strfind(name, searchStr, 1 ,true) then
                                DrawTable[currentSlot][type][itemID] = itemName
                            end
                        end
                    end
                elseif TmogGearDB[currentSlot][type] then
                    for itemID, name in pairs(TmogGearDB[currentSlot][type]) do
                        DrawTable[currentSlot][type][itemID] = name 
                    end
                end
            end
            -- remove no longer existing items 
            for k in pairs(DrawTable[currentSlot][type]) do
                Tmog:CacheItem(k)
                if not GetItemInfo(k) then
                    DrawTable[currentSlot][type][k] = nil
                end
            end
            -- if usable checked, remove unusable items
            if onlyUsable then
                for k in pairs(DrawTable[currentSlot][type]) do
                    if not Tmog:IsUsableItem(k) then
                        DrawTable[currentSlot][type][k] = nil
                    end
                end
            end
            -- remove duplicates
            if searchStr == "" and type ~= "SearchResult" then
                for k1 in pairs(DrawTable[currentSlot][type]) do
                    if SetContains(DisplayIdDB, k1) then
                        for _, v in pairs(DisplayIdDB[k1]) do
                            if DrawTable[currentSlot][type][v] then
                                DrawTable[currentSlot][type][v] = nil
                            end
                        end
                    end
                end
            end
            totalPages = ceil(tsize(DrawTable[currentSlot][type]) / itemsPerPage)
            sorted = Tmog:Sort(DrawTable[currentSlot][type])
        end

        -- nothing to show
        if not DrawTable[currentSlot][type] or next(DrawTable[currentSlot][type]) == nil then
            Tmog:HidePreviews()
            Tmog:HidePagination()
            currentPage = 1
            return
        end

        if noDraw then
            flush = false
            return
        end

        if currentPage == totalPages then
            Tmog:HidePreviews()
        end

        local frame, button

        for i = 1, tsize(sorted) do
            local itemID = sorted[i][1]
            local name = sorted[i][2]
            local quality = sorted[i][3]

            if index >= lowerLimit and index < upperLimit then
                if not PreviewButtons[itemIndex] then
                    PreviewButtons[itemIndex] = CreateFrame("Frame", "TmogFramePreview" .. itemIndex, TmogFrame, "TmogFramePreviewTemplate")
                    PreviewButtons[itemIndex]:SetPoint("TOPLEFT", TmogFrame, "TOPLEFT", 263 + col * 90, -105 - 120 * row)
                    getglobal("TmogFramePreview" .. itemIndex .. "ItemModel"):SetLight(unpack(previewNormalLight))
                end
                frame = PreviewButtons[itemIndex]
                frame:Show()
                frame.name = name
                frame.id = itemID

                button = getglobal("TmogFramePreview"..itemIndex.."Button")
                button:Show()
                button:SetID(itemID)
                
                Tmog:CacheItem(itemID)
                if SetContains(TMOG_CACHE[currentSlot], itemID) then
                    getglobal("TmogFramePreview" .. itemIndex .. "ButtonCheck"):Show()
                else
                    getglobal("TmogFramePreview" .. itemIndex .. "ButtonCheck"):Hide()
                end

                if itemID == CurrentGear[currentSlot] then
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
                local z = Positions[currentSlot][race][sex][1]
                local x = Positions[currentSlot][race][sex][2]
                local y = Positions[currentSlot][race][sex][3]
                local f = Positions[currentSlot][race][sex][4]
                model:SetPosition(0, 0, 0)
                model:SetUnit("player")
                model:Undress()
                model:SetPosition(z, x, y)
                model:SetFacing(f)
                
                -- oh / ranged
                if currentSlot == 17 or currentSlot == 18 then
                    local _, _, _, _, _, _, _, loc  = GetItemInfo(itemID)
                    if loc == "INVTYPE_RANGED" or loc == "INVTYPE_WEAPONOFFHAND" or loc == "INVTYPE_HOLDABLE" then
                        model:SetFacing(-0.61)
                        if race == "bloodelf" then
                            if sex == 2 then
                                model:SetFacing(-1)
                            end
                        end
                    else
                        model:SetFacing(0.61)
                        if race == "goblin" then
                            if sex == 1 then
                                model:SetFacing(0.9)
                            end
                        end
                    end
                    -- shield
                    if loc == "INVTYPE_SHIELD" then
                        model:SetFacing(-1.5)
                        if race == "scourge" then
                            if sex == 2 then
                                model:SetFacing(-1)
                                z = z + 2
                                y = y - 0.5
                            end
                        end
                        if race == "goblin" then
                            if sex == 2 then
                                x = x - 0.3
                            end
                            z = z + 0.2
                        end
                        if race == "orc" then
                            if sex == 2 then
                                x = x - 0.8
                            end
                        end
                        if race == "nightelf"then
                            x = x - 0.3
                            y = y - 1
                        end
                        if race == "bloodelf" then
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

        local size = tsize(sorted)
        totalPages = ceil(size / itemsPerPage)
        TmogFramePageText:SetText("Page " .. currentPage .. "/" .. totalPages)
    
        if currentPage == 1 then
            TmogFrameLeftArrow:Disable()
            TmogFrameFirstPage:Disable()
        else
            TmogFrameLeftArrow:Enable()
            TmogFrameFirstPage:Enable()
        end
    
        if currentPage == totalPages or size < itemsPerPage then
            TmogFrameRightArrow:Disable()
            TmogFrameLastPage:Disable()
        else
            TmogFrameRightArrow:Enable()
            TmogFrameLastPage:Enable()
        end
        flush = false

    elseif currentTab == "outfits" then
        if noDraw then
            return
        end

        Tmog:HidePreviews()
        
        local frame, button
        -- big plus button
        if currentPage == 1 then
            if not PreviewButtons[1] then
                PreviewButtons[1] = CreateFrame("Frame", "TmogFramePreview1", TmogFrame, "TmogFramePreviewTemplate")
                PreviewButtons[1]:SetPoint("TOPLEFT", TmogFrame, "TOPLEFT", 263 , -105)
            end

            frame = PreviewButtons[1]
            frame:Show()
            
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

            if index >= lowerLimit and index < upperLimit and outfitIndex <= itemsPerPage then
                if not PreviewButtons[outfitIndex] then
                    PreviewButtons[outfitIndex] = CreateFrame("Frame", "TmogFramePreview" .. outfitIndex, TmogFrame, "TmogFramePreviewTemplate")
                    PreviewButtons[outfitIndex]:SetPoint("TOPLEFT", TmogFrame, "TOPLEFT", 263 + col * 90, -105 - 120 * row)
                    getglobal("TmogFramePreview" .. outfitIndex .. "ItemModel"):SetLight(unpack(previewNormalLight))
                end
                frame = PreviewButtons[outfitIndex]
                frame:Show()
                frame.name = name

                button = getglobal("TmogFramePreview" .. outfitIndex .. "Button")
                button:Show()
                button:SetID(outfitIndex)

                if name == currentOutfit then
                    button:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_selected")
                else
                    button:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_normal")
                end

                Tmog_AddOutfitTooltip(button, name)

                local model = getglobal("TmogFramePreview" .. outfitIndex .. "ItemModel")
                model:SetPosition(0, 0, 0)
                model:SetUnit("player")
                model:Undress()
                model:SetFacing(0.3)
                model:SetPosition(1.5, 0, 0)
                model:SetAlpha(1)

                for _, itemID in pairs(TMOG_PLAYER_OUTFITS[name]) do
                    model:TryOn(itemID)
                end

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

        local size = tsize(TMOG_PLAYER_OUTFITS) + 1
        totalPages = ceil(size / itemsPerPage)
        TmogFramePageText:SetText("Page " .. currentPage .. "/" .. totalPages)
    
        if currentPage == 1 then
            TmogFrameLeftArrow:Disable()
            TmogFrameFirstPage:Disable()
        else
            TmogFrameLeftArrow:Enable()
            TmogFrameFirstPage:Enable()
        end
    
        if (currentPage == totalPages) or (size < itemsPerPage) then
            TmogFrameRightArrow:Disable()
            TmogFrameLastPage:Disable()
        else
            TmogFrameRightArrow:Enable()
            TmogFrameLastPage:Enable()
        end
    end

    if totalPages > 1 then
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
    if not currentPage or not totalPages then
        return
    end

    if currentTab == "items" and not currentSlot then
        return
    end
    -- get total pages
    Tmog:DrawPreviews(1)
    
    if (currentPage + dir < 1) or (currentPage + dir > totalPages) then
        return
    end

    if destination then
        if destination == "last" then
            dir = totalPages - currentPage
        elseif destination == "first" then
            dir = 1 - currentPage
        end
    end

    currentPage = currentPage + dir
    Tmog:DrawPreviews()

    if currentTab == "items" then
        Pages[currentSlot][currentType] = currentPage
    end

    if TmogFrameSharedItems:IsVisible() then
        TmogFrameSharedItems:Hide()
    end
end

function Tmog:RemoveSelection()
    if currentTab == "outfits" then

        if not (currentPage == 1) then
            TmogFramePreview1ButtonPlus:Hide()
            TmogFramePreview1ButtonPlusPushed:Hide()
        end

        for index = 1, tsize(PreviewButtons) do
            getglobal("TmogFramePreview"..index.."Button"):SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_normal")
        end

    elseif currentTab == "items" then

        for index = 1, tsize(PreviewButtons) do
            if PreviewButtons[index].id ~= CurrentGear[currentSlot] then
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
        Tmog:LinkItem(CurrentGear[InventorySlotId])

    elseif rightClick then
        
        if CurrentGear[InventorySlotId] == 0 then
            if ActualGear[InventorySlotId] == 0 then
                return
            end
            TmogFramePlayerModel:TryOn(ActualGear[InventorySlotId])
            CurrentGear[InventorySlotId] = ActualGear[InventorySlotId]
        else
            TmogFramePlayerModel:Undress()

            for slot, itemID in pairs(CurrentGear) do
                if slot ~= InventorySlotId and slot ~= 18 then
                    if (slot == 1 and showingHelm == 1) or (slot == 15 and showingCloak == 1) or
                        (CurrentGear[slot] ~= ActualGear[slot]) or (slot ~= 1 and slot ~= 15)
                        then
                        TmogFramePlayerModel:TryOn(itemID)
                    end
                end
            end

            CurrentGear[InventorySlotId] = 0
        end

        Tmog:EnableOutfitSaveButton()
        Tmog:UpdateItemTextures()
        --update tooltip
        this:Hide()
        this:Show()

        if currentTab == "items" then
            Tmog:RemoveSelection()
        end
        PlaySound("igMainMenuOptionCheckBoxOn")
    else
        currentSlot = InventorySlotId
        flush = true
        if currentTab == "outfits" then
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
        currentType = SlotsTypes[InventorySlotId]
        
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
            currentSlot = nil
            TmogFrameSearchBox:Hide()
            PlaySound("InterfaceSound_LostTargetUnit")
        end

        Tmog_Search()
        PlaySound("igCreatureAggroSelect")
    end
    DropDownList1:Hide()
end

function Tmog:UpdateItemTextures()
    for slotName, InventorySlotId in pairs(InventorySlots) do
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
            if GetInventoryItemLink("player", InventorySlotId) or GetItemInfo(CurrentGear[InventorySlotId]) then
                local _, _, _, _, _, _, _, _, tex = GetItemInfo(CurrentGear[InventorySlotId])
    
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

        if currentTab == "items" then
            
            if IsShiftKeyDown() then
                Tmog:LinkItem(itemId)
            else
                TmogFramePlayerModel:TryOn(itemId)
                CurrentGear[currentSlot] = itemId
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

        elseif currentTab == "outfits" then

            if this:GetID() == 0 then
                Tmog_NewOutfitPopup()
                return
            end

            local outfit = PreviewButtons[this:GetID()].name
            if IsShiftKeyDown() then
                Tmog:LinkOutfit(outfit)
                return
            end
            currentOutfit = outfit

            Tmog_LoadOutfit(outfit)
            Tmog:RemoveSelection()
            this:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_selected")
            PlaySound("igMainMenuOptionCheckBoxOn")
        end

    elseif arg1 == "RightButton" then

        if currentTab ~= "items" then
            TmogFrameSharedItems:Hide()
            return
        end

        selectedButton = this

        for i = 1, tsize(sharedItems) do
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
                    if onlyUsable and not Tmog:IsUsableItem(id) then
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

        for i = 1, tsize(t) do

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
        local numLines = TmogTooltip:NumLines()

        if numLines and numLines > 0 then
            local lastLine = getglobal("TmogTooltipTextLeft"..numLines)  
            if lastLine:GetText() then
                lastLine:SetText(lastLine:GetText().."\n\n"..NORMAL.."ItemID: "..itemID)
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

    for _, InventorySlotId in pairs(InventorySlots) do
        CurrentGear[InventorySlotId] = 0
    end

    Tmog:UpdateItemTextures()
    Tmog:EnableOutfitSaveButton()

    if currentTab == "items" then
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

                    for k, v in pairs(InventorySlots) do
                        if v == slot then
                            slotName = k
                        end
                    end

                    if slotName then
                        slotName = getglobal(strupper(slotName))
                        local itemName, _, quality = GetItemInfo(itemID)
                        local _, _, _, color = GetItemQualityColor(quality)
                        local isCollected = SetContains(TMOG_CACHE[slot], itemID, itemName)
                        local status = ""

                        if isCollected then
                            status = NORMAL.."Collected"
                        else
                            status = GREY.."Not collected"
                        end

                        if color then
                            TmogTooltip:AddDoubleLine(slotName..": "..color..itemName, status)
                        else
                            TmogTooltip:AddDoubleLine(slotName..": "..itemName, status)
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
        local numLines = TmogTooltip:NumLines()

        if numLines and numLines > 0 then
            local lastLine = getglobal("TmogTooltipTextLeft"..numLines)

            if lastLine:GetText() then
                lastLine:SetText(lastLine:GetText().."\n\n"..NORMAL.."ItemID: "..itemID)
                local name = GetItemInfo(itemID)

                if name and SetContains(DisplayIdDB, itemID) then
                    if not onlyUsable then
                        lastLine:SetText(lastLine:GetText().."\n\n"..NORMAL.."Shares Appearance With:")
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
                                lastLine:SetText(lastLine:GetText().."\n\n"..NORMAL.."Shares Appearance With:")
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
        for slot in pairs(InventorySlots) do
            getglobal("TmogFrame"..slot):Hide()
        end
        TmogFrameRevert:Hide()
        TmogFrameFullScreenButton:Hide()
        TmogFrameHideUI:SetText("ShowUI")
        hidden = true
    else
        for slot in pairs(InventorySlots) do
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

    currentOutfit = outfit
    TmogFrameSaveOutfit:Disable()

    TmogFrameDeleteOutfit:Enable()
    TmogFrameShareOutfit:Enable()

    TmogFramePlayerModel:Undress()

    for _, InventorySlotId in pairs(InventorySlots) do
        CurrentGear[InventorySlotId] = 0
    end

    for slot, itemID in pairs(TMOG_PLAYER_OUTFITS[outfit]) do
        if slot ~= 17 and slot ~= 16 then
            TmogFramePlayerModel:TryOn(itemID)
            CurrentGear[slot] = itemID
        end
    end
    if TMOG_PLAYER_OUTFITS[outfit][18] then
        TmogFramePlayerModel:TryOn(TMOG_PLAYER_OUTFITS[outfit][18])
        CurrentGear[18] = TMOG_PLAYER_OUTFITS[outfit][18]
    end
    if TMOG_PLAYER_OUTFITS[outfit][16] then
        TmogFramePlayerModel:TryOn(TMOG_PLAYER_OUTFITS[outfit][16])
        CurrentGear[16] = TMOG_PLAYER_OUTFITS[outfit][16]
    end
    if TMOG_PLAYER_OUTFITS[outfit][17] then
        TmogFramePlayerModel:TryOn(TMOG_PLAYER_OUTFITS[outfit][17])
        CurrentGear[17] = TMOG_PLAYER_OUTFITS[outfit][17]
    end

    Tmog:UpdateItemTextures()
    Tmog:RemoveSelection()

    for i = 1, tsize(PreviewButtons) do
        if PreviewButtons[i].name == outfit then
            getglobal("TmogFramePreview"..i.."Button"):SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\item_bg_selected")
        end
    end
end

function Tmog:EnableOutfitSaveButton()
    if currentOutfit ~= nil then
        TmogFrameSaveOutfit:Enable()
        TmogFrameDeleteOutfit:Enable()
        TmogFrameShareOutfit:Enable()
    end
end

function Tmog_SaveOutfit()
    TMOG_PLAYER_OUTFITS[currentOutfit] = {}

    for InventorySlotId, itemID in pairs(CurrentGear) do
        if itemID ~= 0 then
            TMOG_PLAYER_OUTFITS[currentOutfit][InventorySlotId] = itemID
        end
    end

    TmogFrameSaveOutfit:Disable()

    if currentTab == "outfits" then
        Tmog:DrawPreviews()
    end
end

function Tmog_DeleteOutfit()
    TMOG_PLAYER_OUTFITS[currentOutfit] = nil
    currentOutfit = nil

    TmogFrameSaveOutfit:Disable()
    TmogFrameDeleteOutfit:Disable()
    TmogFrameShareOutfit:Disable()
    UIDropDownMenu_SetText("Outfits", TmogFrameOutfitsDropDown)

    if currentTab == "outfits" then
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
        if currentTab == "outfits" then
            if currentPage == 1 then
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
        if currentTab == "outfits" then
            if currentPage == 1 then
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
        currentOutfit = outfitName
        TmogFrameDeleteOutfit:Enable()
        TmogFrameShareOutfit:Enable()
        Tmog_SaveOutfit()
        getglobal(this:GetParent():GetName() .. "EditBox"):SetText("")
    end,

    OnCancel = function()
        if currentTab == "outfits" then
            if currentPage == 1 then
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
    button1 = YES,
    button2 = NO,

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
    button1 = OKAY,
    button2 = CANCEL,
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
    if collected then
        collected = false
    else
        collected = true
    end

    TmogFrameCollected:SetChecked(collected)
    flush = true
    if currentSlot then
        currentPage = 1
        for k in pairs(Pages) do
            for i in pairs(Pages[k]) do
                Pages[k][i] = 1
            end
        end
        Tmog:DrawPreviews()
    end
end

function Tmog_NotCollectedToggle()
    if notCollected then
        notCollected = false
    else
        notCollected = true
    end

    TmogFrameNotCollected:SetChecked(notCollected)
    flush = true
    if currentSlot then
        currentPage = 1
        for k in pairs(Pages) do
            for i in pairs(Pages[k]) do
                Pages[k][i] = 1
            end
        end
        Tmog:DrawPreviews()
    end
end

function Tmog_UsableToggle()
    if onlyUsable then
        onlyUsable = false
        TmogFrameIgnoreLevel:Disable()
        TmogFrameIgnoreLevelText:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
    else
        onlyUsable = true
        TmogFrameIgnoreLevel:Enable()
        TmogFrameIgnoreLevelText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
    end
    this:SetChecked(onlyUsable)
    flush = true
    if currentSlot then
        currentPage = 1
        for k in pairs(Pages) do
            for i in pairs(Pages[k]) do
                Pages[k][i] = 1
            end
        end
        if onlyUsable then
            Unusable[currentSlot][currentType] = {}
        end
        Tmog:DrawPreviews()
    end
end

function Tmog_IgnoreLevelToggle()
    if ignoreLevel then
        ignoreLevel = false
    else
        ignoreLevel = true
    end
    this:SetChecked(ignoreLevel)
    flush = true
    if currentSlot then
        currentPage = 1
        for k in pairs(Pages) do
            for i in pairs(Pages[k]) do
                Pages[k][i] = 1
            end
        end
        for k in pairs(Unusable) do
            for k2 in pairs(Unusable[k]) do
                for k3 in pairs(Unusable[k][k2]) do
                    Unusable[k][k2][k3] = nil
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
        Tmog_SelectType(currentType)
        return
    end
    flush = true
    currentPage = 1
    Tmog:DrawPreviews()
end

function Tmog_SwitchTab(which)
    if currentTab == which then
        return
    end

    currentTab = which

    if which == "items" then
        TmogFrameItemsButton:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\tab_active")
        TmogFrameItemsButton:SetPushedTexture("Interface\\AddOns\\Tmog\\Textures\\tab_active")
        TmogFrameOutfitsButton:SetNormalTexture("Interface\\AddOns\\Tmog\\Textures\\tab_inactive")
        TmogFrameOutfitsButton:SetPushedTexture("Interface\\AddOns\\Tmog\\Textures\\tab_inactive")

        if currentSlot then
            if currentSlot ~= 15 and currentSlot ~= 4 and currentSlot ~= 19 then
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
        currentPage = 1
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
    local itemID = CurrentGear[this:GetID()]

    Tmog:CacheItem(itemID)
    local name, _, quality = GetItemInfo(itemID)

    if name and quality then
        local r, g, b = GetItemQualityColor(quality)

        TmogTooltip:SetText(name, r, g, b)

        if SetContains(TMOG_CACHE[slot], itemID, name)then
            TmogTooltip:AddLine(GREEN.."Collected|r")
        else
            TmogTooltip:AddLine(YELLOW.."Not collected|r")
        end

        TmogTooltip:AddLine(NORMAL.."\nItemID: "..itemID.."|r", 1, 1, 1)
        TmogTooltip:Show()
    end

    if not name then
        local text = getglobal(strupper(strsub(this:GetName(), 10)))

        TmogTooltip:SetText(text)
        TmogTooltip:Show()
    end
end

function Tmog_OutfitsDropDown_Initialize()
    if tsize(TMOG_PLAYER_OUTFITS) < 30 then
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
        info.checked = currentOutfit == name
        info.func = Tmog_LoadOutfit
        info.tooltipTitle = name
        local descText, slotName = "", ""

        for slot, itemID in pairs(data) do
            Tmog:CacheItem(itemID)

            for k, v in pairs(InventorySlots) do
                if v == slot then
                    slotName = k
                end
            end

            if slotName then
                slotName = getglobal(strupper(slotName))
                Tmog:CacheItem(itemID)
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

local info = {}
function Tmog_TypeDropDown_Initialize()
    if currentSlot == 1 or
        currentSlot == 5 or
        currentSlot == 8
        then
        CurrentTypesList = TypesMisc

    elseif currentSlot == 15 then
        CurrentTypesList = TypesBack

    elseif currentSlot == 4 or currentSlot == 19 then
        CurrentTypesList = TypesShirt

    elseif currentSlot == 10 or
            currentSlot == 6 or
            currentSlot == 7 or
            currentSlot == 3 or
            currentSlot == 9
        then
        CurrentTypesList = TypesDefault

    elseif currentSlot == 16 then
        CurrentTypesList = TypesMH

    elseif currentSlot == 17 then
        CurrentTypesList = TypesOH

    elseif currentSlot == 18 then
        CurrentTypesList = TypesRanged
    end
    
    for _, v in pairs(CurrentTypesList) do
        info.text = v
        info.arg1 = v
        info.checked = currentType == v
        info.func = Tmog_SelectType
        if onlyUsable then
            if SetContains(GetTableForClass(playerClass), v) then
                if not (not canDualWeild and currentSlot == 17 and v ~= "Shields" and v ~= "Miscellaneous") then
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
        return false
    end

    if tonumber(linkOrID) then
        if GetItemInfo(linkOrID) then
            return true
        else
            GameTooltip:SetHyperlink("item:"..linkOrID)
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
            end
        end
    end
end

function Tmog_ImportOutfit(outfit)
    currentOutfit = nil
    TmogFrameSaveOutfit:Disable()
    TmogFrameDeleteOutfit:Disable()
    UIDropDownMenu_SetText("Outfits", TmogFrameOutfitsDropDown)

    TmogFramePlayerModel:Undress()

    for _, InventorySlotId in pairs(InventorySlots) do
        CurrentGear[InventorySlotId] = 0
    end

    for slot, itemID in pairs(outfit) do
        Tmog:CacheItem(itemID)
        CurrentGear[slot] = itemID
        TmogFramePlayerModel:TryOn(itemID)
    end

    Tmog:UpdateItemTextures()
end

function Tmog_ImportOutfit_OnClick()
    StaticPopup_Show("TMOG_IMPORT_OUTFIT")
end

function Tmog_ShareOutfit_OnClick()
    local code = "T.O.L."

    for slot, id in pairs(TMOG_PLAYER_OUTFITS[currentOutfit]) do
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

    for i = 1, tsize(slotItemPairs) do
        _, _, slot, item = strfind(slotItemPairs[i], "(%d+):(%d+)")
        slot = tonumber(slot)
        item = tonumber(item)
        AddToSet(outfit, slot, item)
    end

    for invSlot, itemID in pairs(outfit) do
        Tmog:CacheItem(itemID)
        local _, _, _, _, itemType, itemSubType, _, loc  = GetItemInfo(itemID)
        -- if not TmogGearDB[itemID] then
        --     return nil
        -- end
        -- if not itemType or not itemSubType or not loc then
        --     return nil
        -- end
        -- if itemType ~= "Armor" and itemType ~= "Weapon" then
        --     return nil
        -- end
        -- if not SetContains(InventoryTypeToSlot, loc, invSlot) and not (invSlot == 17 and loc == "INVTYPE_WEAPON") then
        --     return nil
        -- end
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
    for slot, itemID in pairs(CurrentGear) do
        if slot ~= 18 and slot ~= 17 and slot ~= 16 then
            if (slot == 1 and showingHelm == 1) or
                (slot == 1 and showingHelm ~= 1 and ActualGear[1] ~= CurrentGear[1]) or
                (slot == 15 and showingCloak == 1) or
                (slot == 15 and showingCloak ~= 1 and ActualGear[15] ~= CurrentGear[15]) or
                (slot ~= 1 and slot ~= 15)
            then
                this:TryOn(itemID)
            end
        end
    end
    this:TryOn(CurrentGear[18])
    this:TryOn(CurrentGear[16])
    this:TryOn(CurrentGear[17])
end

local fade
function Tmog_FS_OnUpdate()
    if not fade then
        return
    end
    if (GetTime() - fade) > 0.3 then
        fade = nil
        this:Hide()
    end
end

function TmogFrameFullScreen_OnKeyDown()
    local screenshotKey = GetBindingKey("SCREENSHOT")
    if arg1 == "ESCAPE" then
        this:SetScript("OnKeyDown", nil)
        fade = GetTime()
        UIFrameFadeOut(TmogFrameFullScreenModel, 0.3, 1, 0)
    elseif screenshotKey and (arg1 == screenshotKey) then
        RunBinding("SCREENSHOT")
    end
end

local debugState = verbose
local pendingIDs = {}
local requestInterval = 10
local tick = requestInterval

local keysdeleted = 0
local namesrestored = 0
local sharedadded = 0

local function RepairStop()
    debug(format("Cache Repair Finished: bad items deleted: %d, item names restored: %d, missing shared items added: %d", keysdeleted, namesrestored, sharedadded))
    verbose = debugState
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
                debug("bad item "..id..": requesting info from server, try #"..tonumber(value))
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
    debug("Cache Repair Started")
    for slot in pairs(TMOG_CACHE) do
        for id, name in pairs(TMOG_CACHE[slot]) do
            Tmog:CacheItem(id)
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
        debug(format("Cache Repair Finished: bad items deleted: %d, item names restored: %d, missing shared items added: %d", keysdeleted, namesrestored, sharedadded))
        verbose = debugState
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
        verbose = not verbose
        if verbose then
            print("debug is on")
        else
            print("debug is off")
        end

    elseif strfind(cmd, "db$") then
        verbose = true
        Tmog:RepairPlayerCache()
    else
        print(NORMAL.."/tmog show|r"..WHITE.." - toggle dressing room|r")
        print(NORMAL.."/tmog reset|r"..WHITE.." - reset minimap button position|r")
        print(NORMAL.."/tmog lock|r"..WHITE.." - lock/unlock minimap button|r")
        print(NORMAL.."/tmog debug|r"..WHITE.." - print debug messages in chat|r")
        print(NORMAL.."/tmog db|r"..WHITE.." - attempt to repair this character's cache (can fix minor bugs)|r")
    end
end
