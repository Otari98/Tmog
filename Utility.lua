local NORMAL = NORMAL_FONT_COLOR_CODE
local WHITE = HIGHLIGHT_FONT_COLOR_CODE
local GREY = GRAY_FONT_COLOR_CODE
local YELLOW = "|cffFFFF00"
local GREEN = "|cff00A000"
local BLUE = "|cff0070de"
local L = Tmog.L

function Tmog.CacheItem(linkOrID)
	if not linkOrID or linkOrID == 0 then return false end
	if tonumber(linkOrID) then
		if GetItemInfo(linkOrID) then return true end
		TmogScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
		TmogScanTooltip:SetHyperlink("item:"..linkOrID)
		Tmog.debug("Caching "..linkOrID)
		return false
	else
		if type(linkOrID) ~= "string" then return false end
		local _, _, item = string.find(linkOrID, "(item:%d+)")
		if item then
			if GetItemInfo(item) then return true end
			TmogScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
			TmogScanTooltip:SetHyperlink(item)
			Tmog.debug("Caching "..item)
		end
		return false
	end
end

function Tmog.IsRed(r, g, b)
	if not r then return false end
	return r > 0.9 and g < 0.2 and b < 0.2
end

function Tmog.InventorySlotFromItemID(itemID)
	if not itemID then return nil end
	local _, _, _, _, _, _, _, slot  = GetItemInfo(itemID)
	return Tmog.InventoryTypeToSlot[slot or ""]
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
			return Tmog.InventoryTypeToSlot[itemEquipLoc]
		end
		if tableToCheck[itemSubType] and Tmog.InventoryTypeToSlot[itemEquipLoc] then
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
			for row = 1, Tmog.tsize(originalTooltip) do
				if originalTooltip[row] then
					local _, _, classesRow = string.find(originalTooltip[row], (string.gsub(ITEM_CLASSES_ALLOWED, "%%s", "(.*)")))
					if classesRow then
						if not string.find(classesRow, class, 1, true) then
							Tmog.debug("bad class")
							return nil
						end
					end
				end
			end
			return Tmog.InventoryTypeToSlot[itemEquipLoc]
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
		for outfitName, outfitItems in pairs(TMOG_PLAYER_OUTFITS) do
			for _, outfitItemID in pairs(outfitItems) do
				local g1 = Tmog.ItemDisplayGroup[outfitItemID]
				local g2 = Tmog.ItemDisplayGroup[itemID]
				if itemID == outfitItemID or (g1 and g2 and g1 == g2) then
					table.insert(result, outfitName)
					break
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

function Tmog.IsUsableItem(id)
	if Tmog.Unusable[Tmog.currentSlot][Tmog.currentType][id] then
		return false
	end
	local isUsable = true
	for i = 2, 15 do
		_G["TmogScanTooltipTextLeft"..i]:SetTextColor(0,0,0)
		_G["TmogScanTooltipTextRight"..i]:SetTextColor(0,0,0)
	end
	TmogScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
	TmogScanTooltip:SetHyperlink("item:"..id)
	for i = 2, 15 do
		local text = _G["TmogScanTooltipTextLeft"..i]:GetText() or ""
		local leftR, leftG, leftB = _G["TmogScanTooltipTextLeft"..i]:GetTextColor()
		local rightR, rightG, rightB = _G["TmogScanTooltipTextRight"..i]:GetTextColor()
		if Tmog.IsRed(leftR, leftG, leftB) or Tmog.IsRed(rightR, rightG, rightB) then
			if not (Tmog.ignoreLevel and string.find(text, "^"..(string.gsub(ITEM_MIN_LEVEL, "%%d", "")))) then
				isUsable = false
				Tmog.Unusable[Tmog.currentSlot][Tmog.currentType][id] = true
			end
			break
		end
	end
	local _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(id)
	if not Tmog.canDualWeild and (itemEquipLoc == "INVTYPE_WEAPONOFFHAND" or (itemEquipLoc == "INVTYPE_WEAPON" and Tmog.currentSlot == 17)) then
		isUsable = false
		Tmog.Unusable[Tmog.currentSlot][Tmog.currentType][id] = true
	end
	return isUsable
end

function Tmog.print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("["..BLUE.."Tmog|r] "..tostring(msg))
end

function Tmog.debug(...)
	if not Tmog.verbose then return end
	local size = table.getn(arg)
	for i = 1, size do arg[i] = tostring(arg[i]) end
	local msg = size > 1 and table.concat(arg, ", ") or tostring(arg[1])
	local time = GetTime()
	DEFAULT_CHAT_FRAME:AddMessage("["..BLUE.."Tmog|r]["..GREY..string.format("%.3f", time).."|r] "..msg)
	return msg, time
end

function Tmog.strsplit(str, delimiter)
	local splitresult = {}
	local from = 1
	local delim_from, delim_to = string.find(str, delimiter, from, true)
	while delim_from do
		table.insert(splitresult, string.sub(str, from, delim_from - 1))
		from = delim_to + 1
		delim_from, delim_to = string.find(str, delimiter, from, true)
	end
	table.insert(splitresult, string.sub(str, from))
	return splitresult
end

function Tmog.strtrim(s)
	return (string.gsub(s or "", "^%s*(.-)%s*$", "%1"))
end

function Tmog.SetContains(set, key, value)
	if not set then return false end
	if not key and value then
		for k, v in pairs(set) do
			if v == value then return k end
		end
	end
	if key and not value then return set[key] ~= nil end
	return set[key] == value
end

function Tmog.tsize(t)
	if type(t) ~= "table" then return 0 end
	local size = 0
	for _ in pairs(t) do size = size + 1 end
	return size
end
