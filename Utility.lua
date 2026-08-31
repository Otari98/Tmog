local NORMAL = NORMAL_FONT_COLOR_CODE
local WHITE = HIGHLIGHT_FONT_COLOR_CODE
local GREY = GRAY_FONT_COLOR_CODE
local YELLOW = "|cffFFFF00"
local GREEN = "|cff00A000"
local BLUE = "|cff0070de"
local L = Tmog.L

if not UIDropDownMenu_CreateInfo then
	local info = {}
	UIDropDownMenu_CreateInfo = function()
		for k in pairs(info) do info[k] = nil end
		return info
	end
end

function Tmog.CacheItem(linkOrID)
	if not linkOrID or linkOrID == 0 then return nil end
	if tonumber(linkOrID) then
		local itemName, itemLink, itemQuality, itemLevel, itemType, itemSubType, itemCount, itemEquipLoc, itemTexture = GetItemInfo(linkOrID)
		if itemName then return itemName, itemQuality, itemTexture end
		TmogScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
		TmogScanTooltip:SetHyperlink("item:"..linkOrID)
		return nil
	else
		if type(linkOrID) ~= "string" then return nil end
		local _, _, itemString = string.find(linkOrID, "(item:%d+)")
		if itemString then
			local itemName, itemLink, itemQuality, itemLevel, itemType, itemSubType, itemCount, itemEquipLoc, itemTexture = GetItemInfo(itemString)
			if itemName then return itemName, itemQuality, itemTexture end
			TmogScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
			TmogScanTooltip:SetHyperlink(itemString)
		end
		return nil
	end
end

function Tmog.IsRed(r, g, b)
	if not r then return false end
	return r > 0.9 and g < 0.2 and b < 0.2
end

function Tmog.InventorySlotFromItemID(itemID)
	if not itemID then return nil end
	local _, _, _, _, _, _, _, invType  = GetItemInfo(itemID)
	return Tmog.InventoryTypeToSlot[invType or ""]
end

function Tmog.IDFromLink(link)
	if not link then return nil end
	local _, _, id = string.find(link, "item:(%d+)")
	return tonumber(id)
end

local IDcache = {}
function Tmog.GetItemIDByName(name)
	if not name then return nil end
	if IDcache[name] then
		if IDcache[name] ~= 0 then return IDcache[name]
		else return nil end
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

local allowedClassesPattern = string.gsub(ITEM_CLASSES_ALLOWED, "%%s", "(.*)")
-- return slot if this is gear and unit can equip it
function Tmog.GetTransmogSlot(itemID, unit, tooltip)
	itemID = tonumber(itemID)
	if not itemID then return nil end
	unit = unit or "player"
	local itemName, itemLink, itemQuality, itemLevel, itemType, itemSubType, itemCount, itemEquipLoc, itemTexture = GetItemInfo(itemID)
	if itemEquipLoc and itemEquipLoc ~= "" then
		local class, classEn = UnitClass(unit)
		local tableToCheck = Tmog.classEquipTable[classEn]
		Tmog.debugprint(itemID, itemName, itemType, itemSubType, itemEquipLoc)
		local invSlot = Tmog.InventoryTypeToSlot[itemEquipLoc]
		if itemEquipLoc == "INVTYPE_HOLDABLE" then
			return invSlot
		end
		if tableToCheck[itemSubType] and invSlot then
			if not (classEn == "WARRIOR" or classEn == "HUNTER" or classEn == "ROGUE") and itemEquipLoc == "INVTYPE_WEAPONOFFHAND" then
				Tmog.debugprint("cant dual weild")
				return nil
			end
			if itemType == L["Weapon"] and itemSubType == L["Miscellaneous"] then
				Tmog.debugprint("not a real weapon")
				return nil
			end
			-- check if its class restricted item
			if not tooltip then
				tooltip = TmogScanTooltip
				tooltip:ClearLines()
				tooltip:SetHyperlink("item:"..itemID)
			end
			local tooltipName = tooltip:GetName()
			for row = 1, 15 do
				local tooltipRowLeft = _G[tooltipName.."TextLeft"..row]
				if tooltipRowLeft then
					local rowtext = tooltipRowLeft:GetText()
					if rowtext then
						local _, _, classes = string.find(rowtext, allowedClassesPattern)
						if classes then
							if not string.find(classes, class, 1, true) then
								Tmog.debugprint("bad class")
								return nil
							end
						end
					end
				end
			end
			return invSlot
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
		if itemEquipLoc ~= "" and Tmog.InventoryTypeToSlot[itemEquipLoc] then
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
		for k, v in pairs(Tmog.ItemDB) do
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

do
	local result = {}
	function Tmog.GetOutfitsWithItem(itemID)
		for i = table.getn(result), 1, -1 do table.remove(result, i) end
		itemID = tonumber(itemID)
		if not itemID then return result end
		for index, outfitData in pairs(TMOG_PLAYER_OUTFITS) do
			for _, outfitItemID in pairs(outfitData) do
				if type(outfitItemID) == "number" then
					local g1 = Tmog.ItemDisplayGroup[outfitItemID]
					local g2 = Tmog.ItemDisplayGroup[itemID]
					if itemID == outfitItemID or (g1 and g2 and g1 == g2) then
						table.insert(result, outfitData.name)
						break
					end
				end
			end
		end
		return result
	end
end

do
	local items = {}
	function Tmog.GetSameAppearanceItems(itemID, t)
		if not Tmog.IsKnownAppearance(itemID) then return nil end
		local displayGroup = Tmog.ItemDisplayGroup[itemID]
		if not displayGroup then return nil end
		if not Tmog.DisplayGroups[displayGroup] then return nil end
		local ret = type(t) == "table" and t or items
		for i = table.getn(ret), 1, -1 do table.remove(ret, i) end
		for _, id in pairs(Tmog.DisplayGroups[displayGroup]) do
			if Tmog.CacheItem(id) and id ~= itemID then table.insert(ret, table.getn(ret), id) end
		end
		return ret
	end
end

function Tmog.print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("["..BLUE.."Tmog|r] "..tostring(msg))
end

function Tmog.debugprint(...)
	if not TmogConfig.debug then return end
	for i = 1, table.getn(arg) do arg[i] = tostring(arg[i]) end
	local msg = table.concat(arg, " ")
	local time = GetTime()
	DEFAULT_CHAT_FRAME:AddMessage("["..BLUE.."Tmog|r]["..GREY..string.format("%.3f", time).."|r] "..msg)
	return msg, time
end

function Tmog.strtrim(s)
	return (string.gsub(s or "", "^%s*(.-)%s*$", "%1"))
end

function Tmog.tkey(t, value)
	if type(t) ~= "table" then return nil end
	for k, v in pairs(t) do
		if v == value then return k end
	end
	return nil
end

function Tmog.tsize(t)
	if type(t) ~= "table" then return 0 end
	local size = 0
	for _ in pairs(t) do size = size + 1 end
	return size
end

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
