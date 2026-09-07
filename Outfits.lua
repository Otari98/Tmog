local WEBSITE = "https://octowow.st/db/?item="
local NORMAL = NORMAL_FONT_COLOR_CODE
local WHITE = HIGHLIGHT_FONT_COLOR_CODE
local GREY = GRAY_FONT_COLOR_CODE
local YELLOW = "|cffFFFF00"
local GREEN = "|cff00A000"
local BLUE = "|cff0070de"
local PINK = "|cffff80ff"

local L = Tmog.L

function Tmog.GetOutfitByName(outfitName)
	for index, value in pairs(TMOG_PLAYER_OUTFITS) do
		if value.name == outfitName then return value, index end
	end
	return nil, nil
end

function Tmog.ImportOutfit(outfitData)
	Tmog.currentOutfit = nil
	Tmog.UpdateOutfitButtons()
	TmogFramePlayerModel:Undress()

	for _, InventorySlotId in pairs(Tmog.InventorySlots) do
		Tmog.CurrentGear[InventorySlotId] = 0
	end

	for slot, itemID in pairs(outfitData) do
		Tmog.CacheItem(itemID)
		Tmog.CurrentGear[slot] = itemID
		TmogFramePlayerModel:TryOn(itemID)
	end

	Tmog.UpdatePlayerSlotTextures()
end

function Tmog.ShareOutfit(outfit)
	outfit = outfit or Tmog.currentOutfit
	local outfitData = Tmog.GetOutfitByName(outfit)
	if not outfitData then return end

	local code = "T.O.L."
	local dbLinks = ""

	for slot, id in pairs(outfitData) do
		if type(id) == "number" then
			code = code..slot..":"..id..";"
			local slotName = Tmog.InventorySlotToString[slot]
			dbLinks = dbLinks.."**"..slotName.."**: "..GetItemInfo(id).." "..WEBSITE..id.."\n"
		end
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
			local slot = Tmog.OrderLink[index]
			if slot then 
				Tmog.CacheItem(itemID)
				outfit[slot] = itemID
			end
		end
		return outfit
	end

	local signature = string.find(code, "T.O.L.", 1, true)
	if not signature then return nil end

	code = string.sub(code, signature)
	code = Tmog.strtrim(code)

	if string.find(code, "[^%d:;]") then return nil end

	local outfit = {}
	for slot, item in string.gfind(code, "(%d+):(%d+)") do
		slot = tonumber(slot)
		item = tonumber(item)
		if slot and item then
			outfit[slot] = item
			Tmog.CacheItem(itemID)
		end
	end

	return outfit
end

function Tmog.LoadOutfit(outfit)
	local outfitData = Tmog.GetOutfitByName(outfit)
	if not outfitData then return end

	Tmog.currentOutfit = outfit
	TmogFramePlayerModel:Undress()

	for _, InventorySlotId in pairs(Tmog.InventorySlots) do
		Tmog.CurrentGear[InventorySlotId] = 0
	end

	for _, slot in ipairs(Tmog.OrderDress) do
		local itemID = outfitData[slot]
		if itemID then
			TmogFramePlayerModel:TryOn(itemID)
			Tmog.CurrentGear[slot] = itemID
		end
	end

	Tmog.UpdatePlayerSlotTextures()
	Tmog.UpdateSelection()
	Tmog.UpdateOutfitButtons()
end

function Tmog.SaveOutfit()
	if not Tmog.currentOutfit then return end

	local _, index = Tmog.GetOutfitByName(Tmog.currentOutfit)
	if not index then
		index = 1
		table.insert(TMOG_PLAYER_OUTFITS, index, { name = Tmog.currentOutfit })
	end

	for InventorySlotId, itemID in pairs(Tmog.CurrentGear) do
		TMOG_PLAYER_OUTFITS[index][InventorySlotId] = itemID > 0 and itemID or nil
	end

	if Tmog.currentTab == "OUTFITS" then
		Tmog.UpdatePreviewsData()
		Tmog.UpdatePreviews()
	end
	Tmog.UpdateOutfitButtons()
end

function Tmog.DeleteOutfit(outfit)
	local outfitData, outfitIndex = Tmog.GetOutfitByName(outfit)
	if not outfitIndex then return end

	table.remove(TMOG_PLAYER_OUTFITS, outfitIndex)
	if outfit == Tmog.currentOutfit then
		Tmog.currentOutfit = nil
	end
	if Tmog.currentTab == "OUTFITS" then
		Tmog.UpdatePreviewsData()
		Tmog.UpdatePreviews()
	end
	DropDownList1:Hide()
	TmogDeleteOutfitButton:Hide()
	Tmog.UpdateOutfitButtons()
end

function Tmog.RenameOutfit(oldName, newName)
	newName = Tmog.strtrim(newName)
	local outfitData = Tmog.GetOutfitByName(oldName)
	if not outfitData or newName == "" or newName == oldName then return end

	outfitData.name = newName
	if oldName == Tmog.currentOutfit then
		Tmog.currentOutfit = newName
	end
	if Tmog.currentTab == "OUTFITS" then
		Tmog.UpdatePreviewsData()
		Tmog.UpdatePreviews()
	end
	Tmog.UpdateOutfitButtons()
end

function Tmog.NewOutfitPopup()
	StaticPopup_Show("TMOG_NEW_OUTFIT")
end

function Tmog.UpdateOutfitButtons()
    TmogFrameSaveOutfit:Disable()
	UIDropDownMenu_SetText(Tmog.currentOutfit or L["Select outfit"], TmogFrameOutfitsDropDown)
	local outfitData = Tmog.GetOutfitByName(Tmog.currentOutfit)
	if outfitData then
		for slot, itemID in pairs(Tmog.CurrentGear) do
			if itemID ~= 0 and not outfitData[slot] then
				TmogFrameSaveOutfit:Enable()
				break
			elseif outfitData[slot] and outfitData[slot] ~= itemID then
				TmogFrameSaveOutfit:Enable()
			end
		end
	end
end

function Tmog.LinkOutfit(outfit)
	if not outfit or outfit == "" then return end

	local link = Tmog.GetOutfitLink(outfit)
	if WIM_EditBoxInFocus then
		WIM_EditBoxInFocus:Insert(link)
	elseif ChatFrameEditBox:IsShown() then
		ChatFrameEditBox:Insert(link)
	end
end

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
	local outfitData = Tmog.GetOutfitByName(outfit)
	if not outfitData then return "" end
	local link = ""
	for i = 1, table.getn(Tmog.OrderLink) do
		local slot = Tmog.OrderLink[i]
		local code = ""
		local itemID = outfitData[slot]
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
	return link ~= "" and string.format(PINK.."|Houtfit:%s|h[%s]|h|r", link, outfit) or ""
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
				local slot = Tmog.OrderLink[index]
				local slotName = slot and Tmog.InventorySlotToString[slot]
				if slotName and itemID > 0 then
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

function Tmog.OutfitOptionsDropDown_Initialize()
	if not UIDROPDOWNMENU_MENU_VALUE then return end
	if not Tmog.PreviewFrames[UIDROPDOWNMENU_MENU_VALUE] then return end

	local outfit = Tmog.PreviewFrames[UIDROPDOWNMENU_MENU_VALUE].name
	local info = UIDropDownMenu_CreateInfo()
	info.text = outfit
	info.isTitle = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info)

	info = UIDropDownMenu_CreateInfo()
	info.text = L["Rename"]
	info.notCheckable = true
	info.func = function() StaticPopup_Show("TMOG_OUTFIT_RENAME", nil, nil, outfit) end
	UIDropDownMenu_AddButton(info)

	info = UIDropDownMenu_CreateInfo()
	info.text = L["Share"]
	info.notCheckable = true
	info.func = Tmog.ShareOutfit
	info.arg1 = outfit
	UIDropDownMenu_AddButton(info)

	info = UIDropDownMenu_CreateInfo()
	info.text = DELETE
	info.notCheckable = true
	info.func = function() StaticPopup_Show("TMOG_CONFIRM_DELETE_OUTFIT", outfit, nil, outfit) end
	UIDropDownMenu_AddButton(info)
end

function Tmog.OutfitsDropDown_Initialize()
	if not TMOG_PLAYER_OUTFITS then return end

	local info = UIDropDownMenu_CreateInfo()

	if table.getn(TMOG_PLAYER_OUTFITS) < UIDROPDOWNMENU_MAXBUTTONS then
		info.text = GREEN_FONT_COLOR_CODE..L["New outfit"].."|r"
		info.value = 0
		info.checked = nil
		info.func = StaticPopup_Show
		info.arg1 = "TMOG_NEW_OUTFIT"
		info.tooltipTitle = L["New outfit"]
		info.tooltipText = L["Create an outfit from selected items."]
		UIDropDownMenu_AddButton(info)
	end

	for i = 1, table.getn(TMOG_PLAYER_OUTFITS) do
		local outfitData = TMOG_PLAYER_OUTFITS[i]
		local name = outfitData.name
		info.text = name
		info.value = name
		info.checked = Tmog.currentOutfit == name
		info.func = Tmog.LoadOutfit
		info.arg1 = name
		info.tooltipTitle = name
		local tooltipText, slotName = "", ""

		for slot, itemID in pairs(outfitData) do
			if type(itemID) == "number" then
				slotName = Tmog.InventorySlotToString[slot]
				local itemName, itemQuality, itemTexture = Tmog.CacheItem(itemID)
				if itemName and slotName then
					local _, _, _, color = GetItemQualityColor(itemQuality)
					tooltipText = tooltipText..NORMAL..slotName..":|r "..color.. itemName.."|r\n"
				end
			end
		end
		info.tooltipText = tooltipText
		UIDropDownMenu_AddButton(info)
	end
end

function Tmog.DeleteOutfitButton_OnLoad(self)
	for i = 2, UIDROPDOWNMENU_MAXBUTTONS do
		local button = _G["DropDownList1Button"..i]
		local onEnter = button:GetScript("OnEnter")
		local onLeave = button:GetScript("OnLeave")
		button:SetScript("OnEnter", function(self)
			self = self or this
			if UIDROPDOWNMENU_OPEN_MENU == "TmogFrameOutfitsDropDown" then
				TmogDeleteOutfitButton:Show()
				TmogDeleteOutfitButton:ClearAllPoints()
				TmogDeleteOutfitButton:SetPoint("LEFT", self:GetName().."InvisibleButton", "RIGHT", 8, 0)
				TmogDeleteOutfitButton:SetFrameLevel(self:GetFrameLevel() + 2)
				TmogDeleteOutfitButton.parent = self
			else
				TmogDeleteOutfitButton:Hide()
			end
			if onEnter then return onEnter(self) end
		end)
		button:SetScript("OnLeave", function(self)
			self = self or this
			if GetMouseFocus() ~= TmogDeleteOutfitButton and TmogDeleteOutfitButton:IsShown() then
				TmogDeleteOutfitButton:Hide()
			end
			if onLeave then return onLeave(self) end
		end)
	end
	local onHide = DropDownList1:GetScript("OnHide")
	DropDownList1:SetScript("OnHide", function(self)
		self = self or this
		TmogDeleteOutfitButton:Hide()
		if onHide then return onHide(self) end
	end)
end

function Tmog.DeleteOutfitButton_OnClick(self)
	UIDropDownMenu_StartCounting(DropDownList1)
	if self.parent then
		StaticPopup_Show("TMOG_CONFIRM_DELETE_OUTFIT", self.parent.value, nil, self.parent.value)
	end
end

function Tmog.DeleteOutfitButton_OnEnter(self)
	UIDropDownMenu_StopCounting(DropDownList1)
	if self.parent then _G[self.parent:GetName().."Highlight"]:Show() end
	TmogTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
	TmogTooltip:SetText(L["Delete outfit"])
end

function Tmog.DeleteOutfitButton_OnLeave(self)
	if self.parent then _G[self.parent:GetName().."Highlight"]:Hide() end
	TmogTooltip:Hide()
	self:Hide()
end

local original_Show = DropDownList1Button1.Show
function DropDownList1Button1.Show(self)
	if UIDROPDOWNMENU_OPEN_MENU == "TmogFrameOutfitsDropDown" and self.value == 0 then
		if not self.plusIcon then
			self.plusIcon = self:CreateTexture(self:GetName().."TmogPlusIcon", "ARTWORK")
			self.plusIcon:SetPoint("LEFT", 4, 0)
			self.plusIcon:SetWidth(16)
			self.plusIcon:SetHeight(16)
			self.plusIcon:SetTexture("Interface\\Addons\\Tmog\\textures\\Character-Plus")
		end
		self.plusIcon:Show()
	elseif self.plusIcon then
		self.plusIcon:Hide()
	end
	return original_Show(self)
end

local original_OnShow = DropDownList1:GetScript("OnShow")
DropDownList1:SetScript("OnShow", function(self)
	self = self or this
	if original_OnShow then original_OnShow(self) end
	if UIDROPDOWNMENU_OPEN_MENU == "TmogFrameOutfitsDropDown" then
		self:SetWidth(self:GetWidth() + 20)
	end
end)
