local WEBSITE = "https://octowow.st/db/?item="
local L = Tmog.L

function Tmog.ImportOutfit(outfit)
	Tmog.currentOutfit = nil
	TmogFrameSaveOutfit:Disable()
	TmogFrameSelectedOutfitText:SetText(string.format(L.FMT_SELECTED_OUTFIT, Tmog.currentOutfit or ""))
	TmogFramePlayerModel:Undress()

	for _, InventorySlotId in pairs(Tmog.InventorySlots) do
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

function TmogFrameShareOutfit_OnClick(outfit)
	outfit = outfit or Tmog.currentOutfit
	if not outfit or not TMOG_PLAYER_OUTFITS[outfit] then return end

	local code = "T.O.L."
	local dbLinks = ""

	for slot, id in pairs(TMOG_PLAYER_OUTFITS[outfit]) do
		code = code..slot..":"..id..";"
		local slotName = ""
		for k, v in pairs(Tmog.InventorySlots) do
			if v == slot then slotName = _G[strupper(k)] end
		end
		dbLinks = dbLinks.."**"..slotName.."**: "..GetItemInfo(id).." "..WEBSITE..id.."\n"
	end

	TmogFrameShareDialog:Show()
	TmogFrameShareDialogEditBox:SetText(code)
	TmogFrameShareDialogEditBox:HighlightText()
	TmogFrameShareDialogEditBox2:SetText(dbLinks)
end

function Tmog.ValidateOutfitCode(code)
	local info = Tmog.ParseOutfitLink(code)

	if info then
		local outfit = {}
		for index, itemID in ipairs(info) do
			local slot = Tmog.LinkSlotOrder[index]
			if slot then outfit[slot] = itemID end
		end
		return outfit
	end

	local signature = string.find(code, "T.O.L.", 1, true)
	if signature then
		code = string.sub(code, signature)
		code = Tmog.strtrim(code)
	else
		return nil
	end

	code = string.sub(code, 7)

	if string.find(code, "[^%d:;]") then
		return nil
	end

	local slotItemPairs = Tmog.strsplit(code, ";")
	local outfit = {}
	local slot, item

	for i = 1, Tmog.tsize(slotItemPairs) do
		_, _, slot, item = string.find(slotItemPairs[i], "(%d+):(%d+)")
		slot = tonumber(slot)
		item = tonumber(item)
		if slot and item then outfit[slot] = item end
	end

	for invSlot, itemID in pairs(outfit) do
		Tmog.CacheItem(itemID)
		-- local _, _, _, _, itemType, itemSubType, _, loc  = GetItemInfo(itemID)
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

function Tmog.LoadOutfit(outfit)
	if IsShiftKeyDown() then
		Tmog.LinkOutfit(outfit)
		return
	end

	Tmog.currentOutfit = outfit
	TmogFrameSaveOutfit:Disable()
	TmogFrameSelectedOutfitText:SetText(string.format(L.FMT_SELECTED_OUTFIT, Tmog.currentOutfit or ""))

	TmogFramePlayerModel:Undress()

	for _, InventorySlotId in pairs(Tmog.InventorySlots) do
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
	Tmog.UpdateSelection()
end

function Tmog.SaveOutfit()
	TMOG_PLAYER_OUTFITS[Tmog.currentOutfit] = {}

	for InventorySlotId, itemID in pairs(Tmog.CurrentGear) do
		if itemID ~= 0 then
			TMOG_PLAYER_OUTFITS[Tmog.currentOutfit][InventorySlotId] = itemID
		end
	end

	TmogFrameSaveOutfit:Disable()
	TmogFrameSelectedOutfitText:SetText(string.format(L.FMT_SELECTED_OUTFIT, Tmog.currentOutfit or ""))

	if Tmog.currentTab == "OUTFITS" then
		Tmog.DrawPreviews()
	end
end

function Tmog.DeleteOutfit(outfit)
	outfit = outfit or Tmog.currentOutfit
	if not outfit or not TMOG_PLAYER_OUTFITS[outfit] then return end

	TMOG_PLAYER_OUTFITS[outfit] = nil
	if outfit == Tmog.currentOutfit then
		Tmog.currentOutfit = nil
		TmogFrameSaveOutfit:Disable()
	end
	TmogFrameSelectedOutfitText:SetText(string.format(L.FMT_SELECTED_OUTFIT, Tmog.currentOutfit or ""))

	if Tmog.currentTab == "OUTFITS" then
		Tmog.HidePreviews()
		Tmog.DrawPreviews()
	end
end

function Tmog.RenameOutfit(oldName, newName)
	newName = Tmog.strtrim(newName)
	if not TMOG_PLAYER_OUTFITS[oldName] or newName == "" then return end
	TMOG_PLAYER_OUTFITS[newName] = TMOG_PLAYER_OUTFITS[oldName]
	TMOG_PLAYER_OUTFITS[oldName] = nil
	if oldName == Tmog.currentOutfit then
		Tmog.currentOutfit = newName
	end
	if Tmog.currentTab == "OUTFITS" then
		Tmog.HidePreviews()
		Tmog.DrawPreviews()
	end
end

function Tmog.NewOutfitPopup()
	StaticPopup_Show("TMOG_NEW_OUTFIT_CHOISE")
end

function Tmog.UpdateOutfitButtons()
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
		TmogFrameSelectedOutfitText:SetText(string.format(L.FMT_SELECTED_OUTFIT, Tmog.currentOutfit or ""))
	else
		TmogFrameSaveOutfit:Disable()
		TmogFrameSelectedOutfitText:SetText(string.format(L.FMT_SELECTED_OUTFIT, Tmog.currentOutfit or ""))
	end
end

function Tmog.LinkOutfit(outfit)
	if not outfit or outfit == "" then return end

	-- local code = "T.O.L."
	-- for slot, id in pairs(TMOG_PLAYER_OUTFITS[outfit]) do
	-- 	code = code..slot..":"..id..";"
	-- end

	local link = Tmog.GetOutfitLink(outfit)
	if not link then return end

	if WIM_EditBoxInFocus then
		WIM_EditBoxInFocus:Insert(link)
	elseif ChatFrameEditBox:IsShown() then
		ChatFrameEditBox:Insert(link)
	end
end

Tmog.LinkSlotOrder = { 1, 3, 15, 5, 4, 19, 9, 10, 6, 7, 8, 16, 17, 18 }
local base = string.len([[!"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{]])
local asciiOffset = 33
local charsPerItem = 3

function Tmog.ParseOutfitLink(link)
	if not (link and string.find(link, "outfit:")) then return nil end
	local payload = string.gsub(link, "^.*outfit:(.+).*$", "%1", 1)
	local t = {}
	for i = 1, string.len(payload), charsPerItem do
		local group = string.sub(payload, i, i + charsPerItem - 1)
		local sum = 0
		for j = 1, string.len(group) do
			local a = string.byte(group, j) - asciiOffset
			local b = math.pow(base, charsPerItem - j)
			sum = sum + a * b
		end
		table.insert(t, sum)
	end
	return table.getn(t) > 0 and t or nil
end

function Tmog.GetOutfitLink(outfit)
	if not outfit or outfit == "" or not TMOG_PLAYER_OUTFITS[outfit] then return "" end
	local link = ""
	for i = 1, table.getn(Tmog.LinkSlotOrder) do
		local slot = Tmog.LinkSlotOrder[i]
		local code = ""
		local itemID = TMOG_PLAYER_OUTFITS[outfit][slot]
		if itemID then
			for _ = 1, charsPerItem do
				code = string.char(mod(itemID, base) + asciiOffset)..code
				itemID = floor(itemID / base)
			end
		else
			code = string.rep(string.char(asciiOffset), charsPerItem)
		end
		link = link..code
	end
	return link ~= "" and string.format("|cffff80ff|Houtfit:%s|h[%s]|h|r", link, outfit) or ""
end

local original_SetItemRef = SetItemRef
function SetItemRef(link, text, button)
	if string.sub(link or "", 1, 6) == "outfit" then
		local info = Tmog.ParseOutfitLink(link)
		if not info then return end
		if IsControlKeyDown() then
			DressUpItem(0)
			if DressUpFrame:IsShown() then
				DressUpModel:Undress()
				for index, itemID in ipairs(info) do
					if itemID > 0 then DressUpModel:TryOn(itemID) end
				end
			end
		elseif IsShiftKeyDown() then
			local staticPopup = StaticPopup_Visible("TMOG_IMPORT_OUTFIT")
			if staticPopup then
				_G[staticPopup.."EditBox"]:SetText(link)
			elseif WIM_EditBoxInFocus then
				WIM_EditBoxInFocus:Insert(text)
			elseif ChatFrameEditBox:IsVisible() then
				ChatFrameEditBox:Insert(text)
			end
		else
			ShowUIPanel(ItemRefTooltip)
			if not ItemRefTooltip:IsVisible() then
				ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
			end
			ItemRefTooltip:SetText(string.gsub(text, "^.*|h%[(.+)%]|h.*$", "%1", 1), 1, 1, 1, 1, true)
			for index, itemID in ipairs(info) do
				local slot = Tmog.LinkSlotOrder[index]
				local slotName
				for k, v in pairs(Tmog.InventorySlots) do
					if v == slot then slotName = k end
				end
				if slotName and itemID > 0 then
					slotName = _G[strupper(slotName)]
					local itemName, _, quality = GetItemInfo(itemID)
					if itemName then
						local _, _, _, color = GetItemQualityColor(quality or 1)
						ItemRefTooltip:AddLine(slotName..": "..color..itemName)
					end
				end
			end
			ItemRefTooltip:Show()
		end
	else
		return original_SetItemRef(link, text, button)
	end
end
