local NORMAL = NORMAL_FONT_COLOR_CODE
local WHITE = HIGHLIGHT_FONT_COLOR_CODE
local GREY = GRAY_FONT_COLOR_CODE
local YELLOW = "|cffFFFF00"
local GREEN = "|cff00A000"
local BLUE = "|cff0070de"
local L = Tmog.L

local requestInterval = 1
local maxattempts = 3
local pendingIDs = {}
local tick = 0
local keysdeleted = 0
local namesrestored = 0
local sharedadded = 0

local function RepairStop()
    Tmog.print(string.format(L["Cache repair finished: bad items deleted: %d, item names restored: %d, missing shared items added: %d"], keysdeleted, namesrestored, sharedadded))
    TmogRepairFrame:SetScript("OnUpdate", nil)
end

local function OnUpdate()
    tick = tick + arg1
    if tick < requestInterval then return end
    tick = 0
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
            if value > maxattempts then
                TMOG_CACHE[tbl.slot][id] = nil
                pendingIDs[id] = nil
                keysdeleted = keysdeleted + 1
                if not next(pendingIDs) then
                    RepairStop()
                    return
                end
            else
                Tmog.print(string.format(L["bad item %d, requesting info from server, try #%d"], id, tonumber(value)))
                local itemName = Tmog.CacheItem(id)
                pendingIDs[id].value = itemName or (value + 1)
            end
        end
    end
end

function Tmog.RepairStart()
    pendingIDs = {}
    tick = 0
    keysdeleted = 0
    namesrestored = 0
    sharedadded = 0
    Tmog.print(L["Cache repair started."])
    for slot in pairs(TMOG_CACHE) do
        for id, name in pairs(TMOG_CACHE[slot]) do
            Tmog.CacheItem(id)
            if type(id) ~= "number" then
                TMOG_CACHE[slot][id] = nil
                keysdeleted = keysdeleted + 1
            elseif name == true then
                pendingIDs[id] = { slot = slot, value = 1 }
            end
        end
    end
    for slot in pairs(TMOG_CACHE) do
        for itemID in pairs(TMOG_CACHE[slot]) do
            local displayGroup = Tmog.ItemDisplayGroup[itemID]
            if displayGroup then
                for _, id in pairs(Tmog.DisplayGroups[displayGroup]) do
                    Tmog.CacheItem(id)
                    if not TMOG_CACHE[slot][id] then
                        TMOG_CACHE[slot][id] = 1
                        sharedadded = sharedadded + 1
                    end
                end
            end
        end
    end
    TmogRepairFrame = TmogRepairFrame or CreateFrame("Frame", "TmogRepairFrame")
    TmogRepairFrame:SetScript("OnUpdate", OnUpdate)
end

SLASH_TMOG1 = "/tmog"
SlashCmdList["TMOG"] = function(cmd)
	cmd = string.lower(Tmog.strtrim(cmd))

	if string.find(cmd, "show$") then
		Tmog.ToggleFrame()

	elseif string.find(cmd, "reset$") then
		TmogButton:ClearAllPoints()
        TmogConfig.buttonX = 760
        TmogConfig.buttonY = 600
		TmogButton:SetPoint("CENTER", UIParent, "BOTTOMLEFT", TmogConfig.buttonX, TmogConfig.buttonY)

	elseif string.find(cmd, "wipe$") then
		for k, v in pairs(TMOG_CACHE) do
			for k2, v2 in pairs(v) do TMOG_CACHE[k][k2] = nil end
		end
		Tmog.print(L["collection has been reset"])

	elseif string.find(cmd, "lock$") then
		TmogButton:SetMovable(not TmogButton:IsMovable())
		TmogConfig.locked = not TmogConfig.locked
		if not TmogConfig.locked then
			Tmog.print(L["minimap button unlocked"])
		else
			Tmog.print(L["minimap button locked"])
		end

	elseif string.find(cmd, "debug$") then
		TmogConfig.debug = not TmogConfig.debug
		if TmogConfig.debug then
			Tmog.print(L["debug is on"])
		else
			Tmog.print(L["debug is off"])
		end

	elseif string.find(cmd, "repair$") then
		Tmog.RepairStart()
	else
		Tmog.print(NORMAL.."/tmog show|r - "..L["toggle dressing room"])
		Tmog.print(NORMAL.."/tmog reset|r - "..L["reset minimap button position"])
		Tmog.print(NORMAL.."/tmog wipe|r - "..L["reset this character's collection"])
		Tmog.print(NORMAL.."/tmog lock|r - "..L["lock/unlock minimap button"])
		Tmog.print(NORMAL.."/tmog debug|r - "..L["print debug messages in chat"])
		Tmog.print(NORMAL.."/tmog repair|r - "..L["attempt to repair this character's cache (can fix minor bugs)"])
	end
end
