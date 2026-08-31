local NORMAL = NORMAL_FONT_COLOR_CODE
local WHITE = HIGHLIGHT_FONT_COLOR_CODE
local GREY = GRAY_FONT_COLOR_CODE
local YELLOW = "|cffFFFF00"
local GREEN = "|cff00A000"
local BLUE = "|cff0070de"

local L = Tmog.L

Tmog.currentType = L["Cloth"]
Tmog.currentTab = "ITEMS"
Tmog.currentSlot = nil
Tmog.currentOutfit = nil
Tmog.currentPage = 1
Tmog.totalPages = 1
Tmog.PreviewFrames = {}
Tmog.PlayerSlotFrames = {}
Tmog.SharedItemsFrames = {}
Tmog.OutfitsSorted = {}
Tmog.ItemsSorted = {}
Tmog.CurrentGear = {} -- item ids equipped by TmogFramePlayerModel
Tmog.ActualGear = {} -- item ids your character is wearing, transmog item id is used if present
Tmog.StatusSlotsLookup = {} -- table for checking transmog status from server message
Tmog.SlotTypesMemory = {} -- stores last selected type for each slot
Tmog.PagesMemory = {} -- stores last selected page for each slot and type

function Tmog.OnLoad(self)
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:RegisterEvent("UNIT_MODEL_CHANGED")
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED")
	self:RegisterForDrag("LeftButton")
	TmogFrameRaceBackground:SetTexture("Interface\\AddOns\\Tmog\\Textures\\transmogbackground"..Tmog.playerRace)
	SetPortraitToTexture(TmogFramePortrait, "interface\\icons\\inv_chest_cloth_41")
	TmogFrameVersionText:SetText(Tmog.version)
	local frameName = self:GetName()
	table.insert(UISpecialFrames, frameName)
	self.firstLoad = true
	self.model = _G[frameName.."PlayerModel"]
	self.nextPreview = 0
	self.lastShownPreview = 1
	self.elapsed = 0

	for _, slot in pairs(Tmog.InventorySlots) do
		local types = Tmog.GetTypesForSlot(slot)
		Tmog.PagesMemory[slot] = {}
		Tmog.StatusSlotsLookup[slot] = true
		Tmog.SlotTypesMemory[slot] = types[1]
		for _, type in ipairs(types) do
			Tmog.PagesMemory[slot][type] = 1
		end
	end
	for i = 1, table.getn(Tmog.OrderLink) do
		for slotName, slot in pairs(Tmog.InventorySlots) do
			if slot == Tmog.OrderLink[i] then
				table.insert(Tmog.PlayerSlotFrames, _G["TmogFrame"..slotName])
				break
			end
		end
	end
end

function Tmog.OnEvent(self, event, arg1, arg2, arg3, arg4)
	if event == "ADDON_LOADED" then
		if arg1 ~= "Tmog" then return end
		Tmog.debugprint(event)
		self:UnregisterEvent("ADDON_LOADED")

		-- Saved Variables
		TMOG_CACHE = TMOG_CACHE or {}
		for _, slot in pairs(Tmog.InventorySlots) do
			if not TMOG_CACHE[slot] then TMOG_CACHE[slot] = {} end
		end
		-- convert old style variables
		for k, v in pairs(TMOG_CACHE) do
			for k2, v2 in pairs(v) do if v2 ~= 1 then TMOG_CACHE[k][k2] = 1 end end
		end
		if TMOG_LOCKED ~= nil then TmogConfig.locked = TMOG_LOCKED end
		if TMOG_POSITION ~= nil then
			TmogConfig.buttonX, TmogConfig.buttonY = TMOG_POSITION[1], TMOG_POSITION[2]
		end
		TMOG_PLAYER_OUTFITS = TMOG_PLAYER_OUTFITS or {}
		for k in pairs(TMOG_PLAYER_OUTFITS) do
			if type(k) == "string" then
				local new = {}
				for outfitName, outfitData in pairs(TMOG_PLAYER_OUTFITS) do
					outfitData.name = outfitName
					table.insert(new, outfitData)
				end
				TMOG_PLAYER_OUTFITS = new
				break
			end
		end
		TMOG_TRANSMOG_STATUS = TMOG_TRANSMOG_STATUS or {}

		UIDropDownMenu_Initialize(TmogFrameTypeDropDown, Tmog.TypeDropDown_Initialize)
		UIDropDownMenu_Initialize(TmogFrameOutfitOptionsDropDown, Tmog.OutfitOptionsDropDown_Initialize, "MENU")
		UIDropDownMenu_Initialize(TmogFrameOutfitsDropDown, Tmog.OutfitsDropDown_Initialize)
		UIDropDownMenu_SetWidth(140, TmogFrameTypeDropDown)
		UIDropDownMenu_SetWidth(130, TmogFrameOutfitsDropDown)

		TmogButton:SetMovable(not TmogConfig.locked)
		TmogButton:ClearAllPoints()
		TmogButton:SetPoint("CENTER", UIParent, "BOTTOMLEFT", TmogConfig.buttonX, TmogConfig.buttonY)

	elseif event == "PLAYER_ENTERING_WORLD" then
		Tmog.debugprint(event)
		self.model:SetUnit("player")
		if self.firstLoad then
			Tmog.Reset()
			self.firstLoad = nil
		end
		if self:IsShown() then
			self.model:Hide()
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

	elseif event == "UNIT_INVENTORY_CHANGED" then
		if arg1 ~= "player" then return end
		Tmog.debugprint(event)
		for slot in pairs(TMOG_CACHE) do
			local link = GetInventoryItemLink("player", slot)
			if link then
				local itemID = Tmog.IDFromLink(link)
				if itemID then
					Tmog.CacheItem(itemID)
					TMOG_CACHE[slot][itemID] = 1
					-- check if it shares appearance with other items and add those if it does
					local displayGroup = Tmog.ItemDisplayGroup[itemID]
					if displayGroup then
						for _, id in pairs(Tmog.DisplayGroups[displayGroup]) do
							Tmog.CacheItem(id)
							TMOG_CACHE[slot][id] = 1
						end
					end
				end
			end
		end

	elseif event == "UNIT_MODEL_CHANGED" then
		if arg1 ~= "player" then return end
		Tmog.debugprint(event)
		local model = self.model
		model:Show()
		model:SetPosition(0, 0, 0)
		model:SetUnit("player")
		model:SetPosition(model.z, model.x, model.y)
		Tmog.Dress(model)
		Tmog.UpdatePlayerSlotTextures()
		Tmog.UpdateOutfitButtons()

	elseif event == "CHAT_MSG_ADDON" then
		if not (string.find(arg1, "TW_TRANSMOG", 1, true) and arg4 == UnitName("player")) then return end
		Tmog.debugprint(arg1, arg2, arg4)

		local _, _, availableSlot, availableTransmogs = string.find(arg2, "AvailableTransmogs:(%d+):%d+:(.+)")
		local _, _, newTransmog = string.find(arg2, "NewTransmog:(%d+)")
		local _, _, transmogStatus = string.find(arg2, "TransmogStatus:(.+)")

		if availableTransmogs then
			local slot = tonumber(availableSlot)
			for itemID in string.gfind(availableTransmogs, "%d+") do
				itemID = tonumber(itemID)
				Tmog.CacheItem(itemID)
				TMOG_CACHE[slot][itemID] = 1
				-- check if it shares appearance with other items and add those if it does
				local displayGroup = Tmog.ItemDisplayGroup[itemID]
				if displayGroup then
					for _, id in pairs(Tmog.DisplayGroups[displayGroup]) do
						Tmog.CacheItem(id)
						TMOG_CACHE[slot][id] = 1
					end
				end
			end

		elseif newTransmog then
			local itemID = tonumber(newTransmog)
			local slot = Tmog.InventorySlotFromItemID(itemID)

			if not (slot and itemID) then return end

			Tmog.CacheItem(itemID)
			TMOG_CACHE[slot][itemID] = 1
			-- check if it shares appearance with other items and add those if it does
			local displayGroup = Tmog.ItemDisplayGroup[itemID]
			if displayGroup then
				for _, id in pairs(Tmog.DisplayGroups[displayGroup]) do
					Tmog.CacheItem(id)
					TMOG_CACHE[slot][id] = 1
				end
			end

		elseif transmogStatus then
			if not TMOG_TRANSMOG_STATUS then TMOG_TRANSMOG_STATUS = {} end

			for _, slot in pairs(Tmog.InventorySlots) do
				if not TMOG_TRANSMOG_STATUS[slot] then TMOG_TRANSMOG_STATUS[slot] = {} end
			end

			for slot in pairs(Tmog.StatusSlotsLookup) do
				Tmog.StatusSlotsLookup[slot] = true
			end

			for slot, itemID in string.gfind(transmogStatus, "(%d+):(%d+)") do
				slot = tonumber(slot)
				itemID = tonumber(itemID)
				if slot > 0 and itemID > 0 then
					local actualItemId = Tmog.IDFromLink(GetInventoryItemLink("player", slot)) or 0
					Tmog.StatusSlotsLookup[slot] = false
					if actualItemId > 0 then
						TMOG_TRANSMOG_STATUS[slot][actualItemId] = itemID
					end
				end
			end
			-- if we recieve 0 for some equipped item AND we have it in our TMOG_TRANSMOG_STATUS
			-- remove it from TMOG_TRANSMOG_STATUS
			for slot in pairs(Tmog.StatusSlotsLookup) do
				if Tmog.StatusSlotsLookup[slot] then
					local equippedItemID = Tmog.IDFromLink(GetInventoryItemLink("player", slot)) or 0
					if equippedItemID > 0 and TMOG_TRANSMOG_STATUS[slot][equippedItemID] then
						TMOG_TRANSMOG_STATUS[slot][equippedItemID] = nil
					end
				end
			end
		end

	elseif event == "DISPLAY_SIZE_CHANGED" then
		-- apparently model positions can look different on different resolutions
		-- so we need to take this into account when showing previews
		-- Tmog.Positions was made using 16:9 screen
		local relosutions = { GetScreenResolutions() }
		local current = GetCurrentResolution()
		local _, _, width, height = string.find(relosutions[current], "(%d+)x(%d+)")
		local value = 16 / 9 - tonumber(width) / tonumber(height)
		Tmog.offset = value
		local model = self.model
		model:SetPosition(0, 0, 0)
		model:SetUnit("player")
		model:SetPosition(model.z, model.x, model.y)
		Tmog.Dress(model)
		Tmog.debugprint(event, value, relosutions[current])
	end
end

function Tmog.OnUpdate(self, elapsed)
	-- self.elapsed = self.elapsed - elapsed
	-- if self.elapsed > 0 then return end
	-- self.elapsed = 0.001
	if self.nextPreview > self.lastShownPreview then return end
	for _ = 1, Tmog.modelsDressedPerFrame do
		local frame = Tmog.PreviewFrames[self.nextPreview]
		if frame then
			local model = frame.model
			if not model:IsShown() then
				model:Show()
				model:SetPosition(0, 0, 0)
				model:SetUnit("player")
				model:SetPosition(model.z, model.x, model.y)
				model:Undress()
			end
			for _, itemID in ipairs(model.items) do model:TryOn(itemID) end
		end
		self.nextPreview = self.nextPreview + 1
		if self.nextPreview > self.lastShownPreview then break end
	end
end

function Tmog.OnShow(self)
	local model = self.model
	model:SetPosition(0, 0, 0)
	model:SetUnit("player")
	model:SetPosition(model.z, model.x, model.y)
	Tmog.Dress(model)
	Tmog.UpdatePlayerSlotTextures()
	Tmog.UpdateOutfitButtons()
	PlaySound("igCharacterInfoOpen")
end

function Tmog.OnHide(self)
	for _, frame in pairs(Tmog.PreviewFrames) do
		frame.model:Hide()
	end
	self.nextPreview = 0
	PlaySound("igCharacterInfoClose")
end

function Tmog.ResetPosition()
	local model = TmogFrame.model
	model:SetPosition(0, 0, 0)
	model:SetFacing(Tmog.defaultRotation)
	model.z, model.x, model.y = model:GetPosition()
end

function Tmog.PlayerModel_OnMouseDown(self, button)
	TmogFrameSearchBox:ClearFocus()
	DropDownList1:Hide()
	self.startX, self.startY = GetCursorPosition()
	self.mouseButton = button
end

function Tmog.PlayerModel_OnMouseUp(self, button)
	self.z, self.x, self.y = self:GetPosition()
	self.mouseButton = nil
end

function Tmog.PlayerModel_OnUpdate(self, elapsed)
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

function Tmog.PlayerModel_OnMouseWheel(self, delta)
	local z, x, y = self:GetPosition()
	z = z + delta
	self:SetPosition(z, x, y)
	self.z = z
end

function Tmog.PlayerModel_OnLoad(self)
	self.z, self.x, self.y = 0, 0, 0
	self:SetFacing(Tmog.defaultRotation)
	self:SetLight(unpack(Tmog.Light.playerModel))
end

function Tmog.Reset()
	Tmog.currentOutfit = nil
	TmogFramePlayerModel:SetPosition(0, 0, 0)
	TmogFramePlayerModel:SetPosition(TmogFramePlayerModel.z, TmogFramePlayerModel.x, TmogFramePlayerModel.y)

	for _, slot in pairs(Tmog.InventorySlots) do
		Tmog.CurrentGear[slot] = 0
		local link = GetInventoryItemLink("player", slot)
		Tmog.ActualGear[slot] = link and Tmog.IDFromLink(link) or 0
	end

	for slot in pairs(TMOG_TRANSMOG_STATUS) do
		local link = GetInventoryItemLink("player", slot)
		local id = Tmog.IDFromLink(link) or 0
		for actualItemID, transmogID in pairs(TMOG_TRANSMOG_STATUS[slot]) do
			if actualItemID == id then Tmog.ActualGear[slot] = transmogID end
		end
	end

	for _, slot in pairs(Tmog.InventorySlots) do
		Tmog.CurrentGear[slot] = Tmog.ActualGear[slot]
	end

	Tmog.Dress(TmogFramePlayerModel)
	Tmog.UpdatePlayerSlotTextures()
	Tmog.UpdateSelection()
	Tmog.UpdateOutfitButtons()
end

function Tmog.SelectType(type)
	if TmogFrameSharedItems:IsShown() then
		TmogFrameSharedItems:Hide()
	end
	UIDropDownMenu_SetText(type, TmogFrameTypeDropDown)
	Tmog.currentType = type
	Tmog.currentPage = 1
	Tmog.UpdatePreviewsData()
	if TmogLoadingFrame.queueTimer > 0 then
		Tmog.HidePagination()
		Tmog.HidePreviews()
	end
	if Tmog.currentSlot and Tmog.currentType and Tmog.PagesMemory[Tmog.currentSlot][Tmog.currentType] then
		Tmog.SlotTypesMemory[Tmog.currentSlot] = type
		if Tmog.LinkedSlots[Tmog.currentSlot] then
			for slot in pairs(Tmog.SlotTypesMemory) do
				if Tmog.LinkedSlots[slot] then Tmog.SlotTypesMemory[slot] = type end
			end
		end
		Tmog.GoToPage(Tmog.PagesMemory[Tmog.currentSlot][Tmog.currentType])
	else
		Tmog.UpdatePreviews()
	end
end

function Tmog.HidePreviews()
	for index in pairs(Tmog.PreviewFrames) do
		local buttonName = Tmog.PreviewFrames[index]:GetName()
		_G[buttonName.."ItemModel"]:SetAlpha(0)
		_G[buttonName.."Button"]:Hide()
		_G[buttonName.."ButtonCheck"]:Hide()
	end
	TmogFrame.lastShownPreview = 0
	TmogFrame.nextPreview = 0
end

local LoadingFrame = CreateFrame("Frame", "TmogLoadingFrame")
LoadingFrame.queueIDs = {}
LoadingFrame.queueTimer = 0
LoadingFrame.dotStrings = { [0] = "", [1] = ".", [2] = "..", [3] = "..." }
LoadingFrame.dotCount = 0
LoadingFrame.dotTimer = 0.3

LoadingFrame:SetScript("OnUpdate", function(self, elapsed)
	self = self or this
	elapsed = elapsed or arg1

	if self.queueTimer == 0 then
		TmogFrameLoadingTexture:Hide()
		return
	end

	if self.dotTimer <= 0 then
		self.dotCount = self.dotCount + 1
		if self.dotCount > 3 then self.dotCount = 0 end
		TmogFrameLoadingTextureText:SetText(L["Loading"].." "..self.dotStrings[self.dotCount])
		self.dotTimer = 0.3
	else
		self.dotTimer = self.dotTimer - elapsed
	end

	local allCached = true
	for id in pairs(self.queueIDs) do
		if not GetItemInfo(id) then allCached = false end
	end
	for _, frame in pairs(Tmog.PreviewFrames) do
		frame.button:EnableMouse(false)
	end
	TmogFrameLoadingTexture:Show()
	if allCached or self.queueTimer <= 0 then
		self.queueTimer = 0
		TmogFrameLoadingTexture:Hide()
		for _, frame in pairs(Tmog.PreviewFrames) do
			frame.button:EnableMouse(true)
		end
		Tmog.UpdatePreviews()
	else
		self.queueTimer = self.queueTimer - elapsed
	end
end)

function Tmog.UpdatePreviews()
	local row, col, size = 0, 0, 0
	local firstIndex = (Tmog.currentPage - 1) * Tmog.itemsPerPage + 1
	local lastIndex = Tmog.currentPage * Tmog.itemsPerPage

	if Tmog.currentTab == "ITEMS" then
		size = table.getn(Tmog.ItemsSorted)

		if size == 0 or LoadingFrame.queueTimer > 0 or (not TmogConfig.collected and not TmogConfig.notCollected) or not Tmog.currentSlot then
			Tmog.HidePreviews()
			Tmog.HidePagination()
			-- Tmog.currentPage = 1
			return
		end

		if Tmog.currentPage == Tmog.totalPages then
			Tmog.HidePreviews()
		end

		local itemIDEquipped = Tmog.CurrentGear[Tmog.currentSlot] or 0
		local displayGroupEquipped = itemIDEquipped > 0 and Tmog.ItemDisplayGroup[itemIDEquipped]
		local previewIndex = 1

		for i = firstIndex, lastIndex do
			local itemID = Tmog.ItemsSorted[i]
			if not itemID then break end

			local displayGroup = Tmog.ItemDisplayGroup[itemID]
			local name, _, quality, _, _, subType, _, invType = GetItemInfo(itemID)
			name = name or ""
			quality = quality or 1

			local frame = Tmog.PreviewFrames[previewIndex]
			if not frame then
				frame = CreateFrame("Frame", "TmogFramePreview" .. previewIndex, TmogFrame, "TmogPreviewTemplate")
				frame:SetPoint("TOPLEFT", TmogFrame, "TOPLEFT", 263 + col * 90, -105 - 120 * row)
				frame:SetID(previewIndex)
				frame.model:SetLight(unpack(Tmog.Light.previewNormal))
				Tmog.PreviewFrames[previewIndex] = frame
			end
			frame:Show()
			frame.name = name
			frame.itemID = itemID
			frame.displayGroup = displayGroup

			local button = frame.button
			button:Show()
			button:SetID(i)

			if TMOG_CACHE[Tmog.currentSlot][itemID] then
				button.check:Show()
			else
				button.check:Hide()
			end

			if itemID == itemIDEquipped or (displayGroup and displayGroupEquipped and displayGroup == displayGroupEquipped) then
				button:LockHighlight()
			else
				button:UnlockHighlight()
			end

			local border = button.border
			local r, g, b = GetItemQualityColor(quality or 1)
			border:SetVertexColor(r, g, b)
			if quality == 2 then
				border:SetAlpha(0.2)
			elseif quality == 0 then
				border:SetAlpha(0.1)
			else
				border:SetAlpha(0.4)
			end

			if TmogTooltip:IsOwned(button) then
				Tmog.PreviewButton_OnEnter(button)
			end

			local positionInfo
			if Tmog.Positions[subType] and Tmog.Positions[subType][Tmog.playerRace] then
				positionInfo = Tmog.Positions[subType][Tmog.playerRace][Tmog.playerSex]
				if invType == "INVTYPE_WEAPONOFFHAND" then
					positionInfo = Tmog.Positions[subType][Tmog.playerRace][Tmog.playerSex + 2]
				end
			elseif Tmog.Positions[invType] and Tmog.Positions[invType][Tmog.playerRace] then
				positionInfo = Tmog.Positions[invType][Tmog.playerRace][Tmog.playerSex]
			end
			local z = positionInfo[1] or 0
			local x = positionInfo[2] or 0
			local y = positionInfo[3] or 0
			local f = positionInfo[4] or Tmog.defaultRotation
			local offset = Tmog.offset or 0
			z = z + (offset * z)/2
			x = x + (offset * x)/2
			y = y + (offset * y)/2

			local model = frame.model
			model.z, model.x, model.y = z, x, y
			model:SetPosition(0, 0, 0)
			model:SetUnit("player")
			model:Undress()
			for _ = table.getn(model.items), 1, -1 do table.remove(model.items) end
			table.insert(model.items, itemID)
			if invType == "INVTYPE_CHEST" or invType == "INVTYPE_ROBE" or invType == "INVTYPE_TABARD" or invType == "INVTYPE_BODY" or invType == "INVTYPE_CLOAK" or invType == "INVTYPE_WAIST" or invType == "INVTYPE_LEGS" then
				table.insert(model.items, 18421) -- evil hack to hide long beard and hair
			end
			model:SetPosition(z, x, y)
			model:SetFacing(f)
			model:SetAlpha(1)
			-- previews are showning right shoulder, these only have left one
			if itemID == 12588 or itemID == 65014 then
				model:SetPosition(z, -x, y)
				model:SetFacing(-f)
			end

			col = col + 1
			if col == Tmog.maxColumns then row = row + 1 col = 0 end
			previewIndex = previewIndex + 1
		end

		if TmogFramePreview1ButtonPlus then
			TmogFramePreview1ButtonPlus:Hide()
			TmogFramePreview1ButtonPlusPushed:Hide()
		end
		TmogFrame.nextPreview = 1
		TmogFrame.lastShownPreview = previewIndex - 1

	elseif Tmog.currentTab == "OUTFITS" then
		Tmog.HidePreviews()
		local previewIndex = 1
		local frame = Tmog.PreviewFrames[1]
		if not frame then
			frame = CreateFrame("Frame", "TmogFramePreview1", TmogFrame, "TmogPreviewTemplate")
			frame:SetPoint("TOPLEFT", TmogFrame, "TOPLEFT", 263 , -105)
			frame:SetID(1)
			frame.model:SetLight(unpack(Tmog.Light.previewNormal))
			Tmog.PreviewFrames[1] = frame
		end
		if not frame.button.plus then
			frame.button.plus = frame.button:CreateTexture("TmogFramePreview1ButtonPlus", "OVERLAY")
			frame.button.plus:SetTexture("Interface\\AddOns\\Tmog\\Textures\\big_plus_normal")
			frame.button.plus:SetWidth(128)
			frame.button.plus:SetHeight(128)
			frame.button.plus:SetPoint("TOPLEFT", -20, 0)
			frame.button.plus:Hide()
			frame.button.plusPushed = frame.button:CreateTexture("TmogFramePreview1ButtonPlusPushed", "OVERLAY")
			frame.button.plusPushed:SetTexture("Interface\\AddOns\\Tmog\\Textures\\big_plus_pushed")
			frame.button.plusPushed:SetWidth(128)
			frame.button.plusPushed:SetHeight(128)
			frame.button.plusPushed:SetPoint("TOPLEFT", -20, 0)
			frame.button.plusPushed:Hide()
			frame.button.plusHighlight = frame.button:CreateTexture("TmogFramePreview1ButtonPlusHighlight", "HIGHLIGHT")
			frame.button.plusHighlight:SetTexture("Interface\\AddOns\\Tmog\\Textures\\big_plus_highlight")
			frame.button.plusHighlight:SetWidth(128)
			frame.button.plusHighlight:SetHeight(128)
			frame.button.plusHighlight:SetPoint("TOPLEFT", -20, 0)
			frame.button.plusHighlight:SetBlendMode("ADD")
			frame.button.plusHighlight:Hide()
		end
		if Tmog.currentPage == 1 then
			frame:Show()
			frame.name = L["New outfit"]
			frame.itemID = nil
			frame.displayGroup = nil
			frame.model:SetAlpha(0)
			frame.button:Show()
			frame.button:SetID(0)
			frame.button:UnlockHighlight()
			frame.button.plus:Show()
			frame.button.plusPushed:Hide()
			frame.button.border:SetAlpha(0.4)
			frame.button.border:SetVertexColor(1, 0.82, 0)
			col = 1
			previewIndex = 2
			TmogFrame.nextPreview = 2
		else
			frame.button.plus:Hide()
			frame.button.plusPushed:Hide()
			firstIndex = firstIndex - 1
			TmogFrame.nextPreview = 1
		end
		lastIndex = lastIndex - 1

		for i = firstIndex, lastIndex do
			local outfitData = Tmog.OutfitsSorted[i]
			if not outfitData then break end
			local name = outfitData.name
			local frame = Tmog.PreviewFrames[previewIndex]
			if not frame then
				frame = CreateFrame("Frame", "TmogFramePreview" .. previewIndex, TmogFrame, "TmogPreviewTemplate")
				frame:SetPoint("TOPLEFT", TmogFrame, "TOPLEFT", 263 + col * 90, -105 - 120 * row)
				frame:SetID(previewIndex)
				frame.model:SetLight(unpack(Tmog.Light.previewNormal))
				Tmog.PreviewFrames[previewIndex] = frame
			end
			frame:Show()
			frame.name = name
			frame.itemID = nil
			frame.displayGroup = nil

			local button = frame.button
			button:Show()
			button:SetID(i)

			if name == Tmog.currentOutfit then
				button:LockHighlight()
			else
				button:UnlockHighlight()
			end

			local positionInfo = Tmog.PositionsOutfit
			local z = positionInfo[1] or 0
			local x = positionInfo[2] or 0
			local y = positionInfo[3] or 0
			local f = positionInfo[4] or Tmog.defaultRotation
			local model = frame.model
			model:SetPosition(0, 0, 0)
			model:SetUnit("player")
			model:Undress()
			model:SetFacing(f)
			model:SetPosition(z, x, y)
			model:SetAlpha(1)
			model.z, model.x, model.y = z, x, y

			local collectedAll = true
			for _ = table.getn(model.items), 1, -1 do table.remove(model.items) end
			for _, slot in ipairs(Tmog.OrderDress) do
				local itemID = outfitData[slot]
				if itemID then
					table.insert(model.items, itemID)
					if not TMOG_CACHE[slot][itemID] then collectedAll = false end
				end
			end

			if collectedAll then
				button.check:Show()
			else
				button.check:Hide()
			end

			button.border:SetAlpha(0.4)
			button.border:SetVertexColor(1, 0.82, 0)

			if TmogTooltip:IsOwned(button) then
				Tmog.PreviewButton_OnEnter(button)
			end

			col = col + 1
			if col == Tmog.maxColumns then row = row + 1 col = 0 end
			previewIndex = previewIndex + 1
		end
		size = table.getn(Tmog.OutfitsSorted) + 1
		TmogFrame.lastShownPreview = previewIndex - 1
	end

	Tmog.totalPages = math.ceil(size / Tmog.itemsPerPage)
	TmogFramePageText:SetText(Tmog.currentPage .. "/" .. Tmog.totalPages)

	if Tmog.currentPage == 1 then
		TmogFramePrevPage:Disable()
		TmogFrameFirstPage:Disable()
	else
		TmogFramePrevPage:Enable()
		TmogFrameFirstPage:Enable()
	end

	if Tmog.currentPage == Tmog.totalPages or size < Tmog.itemsPerPage then
		TmogFrameNextPage:Disable()
		TmogFrameLastPage:Disable()
	else
		TmogFrameNextPage:Enable()
		TmogFrameLastPage:Enable()
	end

	if Tmog.totalPages > 1 then
		Tmog.ShowPagination()
	else
		Tmog.HidePagination()
	end
	Tmog.UpdateOutfitButtons()
end

function Tmog.ShowPagination()
	TmogFramePrevPage:Show()
	TmogFrameNextPage:Show()
	TmogFramePageText:Show()
	TmogFrameFirstPage:Show()
	TmogFrameLastPage:Show()
end

function Tmog.HidePagination()
	TmogFramePrevPage:Hide()
	TmogFrameNextPage:Hide()
	TmogFramePageText:Hide()
	TmogFrameFirstPage:Hide()
	TmogFrameLastPage:Hide()
end

function Tmog.GoToPage(page)
	if LoadingFrame.queueTimer > 0 then return end
	if not Tmog.currentPage or not Tmog.totalPages then return end

	Tmog.currentPage = tonumber(page) or 1

	if Tmog.currentPage > Tmog.totalPages then Tmog.currentPage = Tmog.totalPages end

	if Tmog.currentTab == "ITEMS" and Tmog.currentSlot and Tmog.currentType and TmogFrameSearchBox:GetText() == "" then
		Tmog.PagesMemory[Tmog.currentSlot][Tmog.currentType] = Tmog.currentPage
	end
	if TmogFrameSharedItems:IsShown() then
		TmogFrameSharedItems:Hide()
	end
	Tmog.UpdatePreviews()
end

function Tmog.UpdateSelection()
	for i = 1, Tmog.tsize(Tmog.PreviewFrames) do
		Tmog.PreviewFrames[i].button:UnlockHighlight()
	end
	if Tmog.currentTab == "OUTFITS" then
		if Tmog.currentPage ~= 1 then
			TmogFramePreview1ButtonPlus:Hide()
			TmogFramePreview1ButtonPlusPushed:Hide()
		end
		if not Tmog.currentOutfit then return end
		for i = 1, Tmog.tsize(Tmog.PreviewFrames) do
			if Tmog.PreviewFrames[i].name == Tmog.currentOutfit then
				Tmog.PreviewFrames[i].button:LockHighlight()
				break
			end
		end
	elseif Tmog.currentTab == "ITEMS" then
		if TmogFramePreview1ButtonPlus and TmogFramePreview1ButtonPlusPushed then
			TmogFramePreview1ButtonPlus:Hide()
			TmogFramePreview1ButtonPlusPushed:Hide()
		end
		if not Tmog.currentSlot then return end
		local itemIDEquipped = Tmog.CurrentGear[Tmog.currentSlot] or 0
		local displayGroupEquipped = itemIDEquipped > 0 and Tmog.ItemDisplayGroup[itemIDEquipped]
		for i = 1, Tmog.tsize(Tmog.PreviewFrames) do
			local displayGroup = Tmog.PreviewFrames[i].displayGroup
			local itemID = Tmog.PreviewFrames[i].itemID
			if itemID == itemIDEquipped or (displayGroup and displayGroupEquipped and displayGroup == displayGroupEquipped) then
				Tmog.PreviewFrames[i].button:LockHighlight()
			end
		end
	end
end

function Tmog.PlayerSlot_OnLoad(self)
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	local frameName = self:GetName()
	local slotName = string.gsub(frameName, "TmogFrame(.+)", "%1", 1)
	local id, backgroundTexture = GetInventorySlotInfo(slotName)
	self.backgroundTexture = backgroundTexture
	self.slotName = slotName
	self.icon = _G[frameName.."ItemIcon"]
	self.border = _G[frameName.."Border"]
	self.borderFull = _G[frameName.."BorderFull"]
	self.borderHighlight = _G[frameName.."BorderHighlight"]
end

function Tmog.PlayerSlot_OnClick(self, button)
	local slot = self:GetID()
	DropDownList1:Hide()
	TmogFrameSharedItems:Hide()

	if IsShiftKeyDown() then
		Tmog.LinkItem(Tmog.CurrentGear[slot])

	elseif button == "RightButton" then
		if Tmog.CurrentGear[slot] == 0 then
			if Tmog.ActualGear[slot] == 0 then return end
			TmogFramePlayerModel:TryOn(Tmog.ActualGear[slot])
			Tmog.CurrentGear[slot] = Tmog.ActualGear[slot]
			Tmog.UpdateOutfitButtons()
			Tmog.UpdatePlayerSlotTextures()
			if Tmog.currentTab == "ITEMS" then
				Tmog.UpdateSelection()
			end
		else
			Tmog.UndressSlot(slot)
		end
		if TmogTooltip:IsOwned(self) then
			Tmog.PlayerSlot_OnEnter(self)
		end
		PlaySound("igMainMenuOptionCheckBoxOn")
	else
		local switched = false
		if Tmog.currentTab == "OUTFITS" then
			Tmog.SwitchTab("ITEMS")
			switched = true
		end
		if Tmog.currentSlot == slot and not switched then
			TmogFrameTypeDropDown:Hide()
			TmogFrameFiltersButton:Hide()
			Tmog.HidePagination()
			Tmog.HideBorders()
			Tmog.HidePreviews()
			Tmog.currentSlot = nil
			PlaySound("InterfaceSound_LostTargetUnit")
			return
		end
		Tmog.currentSlot = slot
		Tmog.currentType = Tmog.SlotTypesMemory[slot]
		if TmogFrameSearchBox:GetText() == "" then
			Tmog.currentPage = Tmog.PagesMemory[slot][Tmog.currentType]
		else
			Tmog.currentPage = 1
		end
		UIDropDownMenu_SetText(Tmog.currentType, TmogFrameTypeDropDown)
		Tmog.UpdatePreviewsData()
		Tmog.HideBorders()
		self.borderFull:Show()
		if table.getn(Tmog.GetTypesForSlot(slot)) > 1 then
			TmogFrameTypeDropDown:Show()
		else
			TmogFrameTypeDropDown:Hide()
		end
		TmogFrameFiltersButton:Show()
		Tmog.UpdatePreviews()
		PlaySound("igCreatureAggroSelect")
	end
end

function Tmog.PlayerSlot_OnDoubleClick(self, button)
	-- local invSlot = self:GetID()
	-- local itemID = Tmog.CurrentGear[invSlot]
	-- if itemID > 0 then
	-- 	local itemName, itemLink, itemQuality, itemLevel, itemType, itemSubType, itemCount, itemEquipLoc, itemTexture = GetItemInfo(itemID)
	-- 	local types = Tmog.GetTypesForSlot(invSlot)
	-- 	if Tmog.tkey(types, itemSubType) then
	-- 		Tmog.SelectType(itemSubType)
	-- 		local displayGroup = Tmog.ItemDisplayGroup[itemID]
	-- 		local destination
	-- 		for index, value in pairs(Tmog.ItemsSorted) do
	-- 			local valueDisplayGroup = Tmog.ItemDisplayGroup[value]
	-- 			if value == itemID or (displayGroup and valueDisplayGroup and displayGroup == valueDisplayGroup) then
	-- 				destination = index
	-- 			end
	-- 		end
	-- 		if destination then
	-- 			Tmog.GoToPage(math.ceil(destination / Tmog.itemsPerPage))
	-- 		end
	-- 	end
	-- end
end

function Tmog.PlayerSlot_OnEnter(self)
	local slot = self:GetID()
	local itemID = Tmog.CurrentGear[slot]
	local itemName, _, quality = GetItemInfo(itemID)

	TmogTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", 0, 0)
	if itemName and quality then
		local r, g, b = GetItemQualityColor(quality)
		TmogTooltip:SetText(itemName, r, g, b)
		if TMOG_CACHE[slot][itemID] then
			TmogTooltip:AddLine(GREEN..L["Collected"].."|r")
		else
			TmogTooltip:AddLine(YELLOW..L["Not collected"].."|r")
		end
		TmogTooltip:AddLine(" ")
		TmogTooltip:AddLine("ItemID: "..itemID, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
	else
		TmogTooltip:SetText(Tmog.InventorySlotToString[slot])
	end
	TmogTooltip:Show()
end

function Tmog.UpdatePlayerSlotTextures()
	for _, frame in pairs(Tmog.PlayerSlotFrames) do
		local _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(Tmog.CurrentGear[frame:GetID()] or 0)
		if itemTexture then
			frame.icon:SetTexture(itemTexture)
		else
			frame.icon:SetTexture(frame.backgroundTexture)
		end
	end
end

function Tmog.SharedItem_OnClick(self, button)
	local itemID = self.itemID
	if not itemID then return end

	if IsShiftKeyDown() then
		Tmog.LinkItem(itemID)
	else
		if Tmog.currentSlot == 16 then
			Tmog.UndressSlot(Tmog.currentSlot)
		end
		TmogFramePlayerModel:TryOn(itemID)
		Tmog.CurrentGear[Tmog.currentSlot] = itemID
		Tmog.UpdateOutfitButtons()
		Tmog.UpdatePlayerSlotTextures()
		Tmog.UpdateSelection()
		TmogFrameSharedItems:Hide()
		PlaySound("igMainMenuOptionCheckBoxOn")
	end
end

function Tmog.SharedItem_OnEnter(self)
	local itemID = self.itemID
	if not itemID then return end

	self.r, self.g, self.b = self.name:GetTextColor()
	self.name:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)

	TmogTooltip.itemID = itemID
	TmogTooltip:SetOwner(self, "ANCHOR_LEFT", -6, -5)
	TmogTooltip:SetHyperlink("item:"..tostring(itemID))
	local numLines = TmogTooltip:NumLines()

	if numLines > 0 then
		local lastLine = _G["TmogTooltipTextLeft"..numLines]
		if lastLine:GetText() then
			lastLine:SetText(lastLine:GetText().."\n\n"..NORMAL.."ItemID: "..itemID.."|r")
		end
	end

	TmogTooltip:Show()
end

function Tmog.SharedItem_OnLeave(self)
	self.name:SetTextColor(self.r, self.g, self.b)
	TmogTooltip:Hide()
	TmogTooltip.itemID = nil
end

function Tmog.LinkItem(itemID)
	local itemName, itemQuality, itemTexture = Tmog.CacheItem(itemID)
	if not itemName then return end

	local _, _, _, color = GetItemQualityColor(itemQuality)

	if WIM_EditBoxInFocus then
		WIM_EditBoxInFocus:Insert(color.."|Hitem:"..itemID..":0:0:0|h["..itemName.."]|h|r")
	elseif ChatFrameEditBox:IsShown() then
		ChatFrameEditBox:Insert(color.."|Hitem:"..itemID..":0:0:0|h["..itemName.."]|h|r")
	end
end

function Tmog.Dress(model)
	local showingHelm = ShowingHelm()
	local showingCloak = ShowingCloak()
	model:Undress()
	for _, slot in ipairs(Tmog.OrderDress) do
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

	for _, slot in pairs(Tmog.InventorySlots) do
		Tmog.CurrentGear[slot] = 0
	end

	Tmog.UpdatePlayerSlotTextures()
	Tmog.UpdateOutfitButtons()

	if Tmog.currentTab == "ITEMS" then
		Tmog.UpdateSelection()
	end
end

function Tmog.UndressSlot(invSlot)
	Tmog.CurrentGear[invSlot] = 0
	Tmog.Dress(TmogFramePlayerModel)
	Tmog.UpdateOutfitButtons()
	Tmog.UpdatePlayerSlotTextures()
	if Tmog.currentTab == "ITEMS" then
		Tmog.UpdateSelection()
	end
end

function Tmog.HideBorders()
	for _, frame in pairs(Tmog.PlayerSlotFrames) do
		frame.borderFull:Hide()
	end
end

function Tmog.Preview_OnLoad(self)
	local frameName = self:GetName()
	self.model = _G[frameName.."ItemModel"]
	self.button = _G[frameName.."Button"]
	self.button:SetFrameLevel(self.model:GetFrameLevel() + 2)
end

function Tmog.PreviewButton_OnLoad(self)
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	local frameName = self:GetName()
	self.border = _G[frameName.."Border"]
	self.check = _G[frameName.."Check"]
end

function Tmog.PreviewButton_OnMouseDown(self, button)
	if self.plus and self:GetID() == 0 then
		self.plus:Hide()
		self.plusHighlight:Hide()
		self.plusPushed:Show()
	end
end

function Tmog.PreviewButton_OnMouseUp(self, button)
	if self.plus and self:GetID() == 0 then
		self.plusPushed:Hide()
		self.plus:Show()
	end
end

local SharedItems = {}
function Tmog.PreviewButton_OnClick(self, button)
	local itemID = self:GetParent().itemID
	DropDownList1:Hide()

	if button == "LeftButton" then
		if Tmog.currentTab == "ITEMS" then
			if IsShiftKeyDown() then
				Tmog.LinkItem(itemID)
			else
				if Tmog.currentSlot == 16 then
					Tmog.UndressSlot(Tmog.currentSlot)
				end
				TmogFramePlayerModel:TryOn(itemID)
				Tmog.CurrentGear[Tmog.currentSlot] = itemID
				Tmog.UpdateOutfitButtons()
				Tmog.UpdatePlayerSlotTextures()
				Tmog.UpdateSelection()
				PlaySound("igMainMenuOptionCheckBoxOn")
			end
			TmogFrameSharedItems:Hide()
		elseif Tmog.currentTab == "OUTFITS" then
			if self:GetID() == 0 then
				StaticPopup_Show("TMOG_NEW_OUTFIT")
				return
			end
			local outfit = Tmog.PreviewFrames[self:GetParent():GetID()].name
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
			if self:GetID() <= 0 then return end
			ToggleDropDownMenu(1, self:GetParent():GetID(), TmogFrameOutfitOptionsDropDown, "cursor")
			TmogFrameSharedItems:Hide()
			return
		end

		if TmogFrameSharedItems:IsShown() then
			TmogFrameSharedItems:Hide()
			return
		end

		for i = table.getn(SharedItems), 1, -1 do table.remove(SharedItems, i) end
		local displayGroup = Tmog.ItemDisplayGroup[itemID]
		if displayGroup then
			for _, id in pairs(Tmog.DisplayGroups[displayGroup]) do
				local itemName, itemQuality, itemTexture = Tmog.CacheItem(id)
				if itemName and id ~= itemID then
					local r, g, b = GetItemQualityColor(itemQuality)
					if not (TmogConfig.onlyUsable and not Tmog.IsUsableItem(id)) then
						table.insert(SharedItems, { name = itemName, itemID = id, r = r, g = g, b = b, tex = itemTexture })
					end
				end
			end
		end

		if not next(SharedItems) then
			TmogFrameSharedItems:Hide()
			return
		end

		for i = 1, table.getn(Tmog.SharedItemsFrames) do
			Tmog.SharedItemsFrames[i]:Hide()
		end

		local widestText = 0
		for i = 1, table.getn(SharedItems) do
			local frame = Tmog.SharedItemsFrames[i]
			if not frame then
				frame = CreateFrame("Button", "TmogFrameSharedItem"..i, TmogFrameSharedItems, "TmogSharedItemTemplate")
				frame:SetID(i)
				Tmog.SharedItemsFrames[i] = frame
			end
			frame:Show()
			frame:SetPoint("TOPLEFT", TmogFrameSharedItems, 10 , -10 - ((i - 1) * 20))
			frame.itemID = SharedItems[i].itemID
			frame.icon:SetTexture(SharedItems[i].tex)
			frame.name:SetText(SharedItems[i].name)
			frame.name:SetTextColor(SharedItems[i].r, SharedItems[i].g, SharedItems[i].b)
			local width = frame.name:GetStringWidth()
			TmogFrameSharedItems:SetHeight(40 + (i - 1) * 20)
			if width > widestText then widestText = width end
		end
		TmogFrameSharedItems:SetWidth(45 + widestText)
		TmogFrameSharedItems:ClearAllPoints()
		TmogFrameSharedItems:SetPoint("TOPLEFT", self, "BOTTOMLEFT", -2, 12)
		TmogFrameSharedItems:Show()
	end
end

function Tmog.PreviewButton_OnEnter(self)
	self:GetParent().model:SetLight(unpack(Tmog.Light.previewHighlight))

	if Tmog.currentTab == "ITEMS" then
		local itemID = self:GetParent().itemID
		TmogTooltip.itemID = itemID
		TmogTooltip:SetOwner(self, "ANCHOR_RIGHT", -5, -8)
		TmogTooltip:SetHyperlink("item:"..itemID)

		local numLines = TmogTooltip:NumLines() or 0
		if numLines == 0 then return end

		local lastLine = _G["TmogTooltipTextLeft"..numLines]
		if not (lastLine and lastLine:GetText()) then return end

		lastLine:SetText(lastLine:GetText().."\n\n"..NORMAL.."ItemID: "..itemID.."|r")
		local displayGroup = Tmog.ItemDisplayGroup[itemID]
		if displayGroup then
			local duplicates = ""
			local numDuplicates = 0
			for _, id in pairs(Tmog.DisplayGroups[displayGroup]) do
				local itemName, itemQuality, itemTexture = Tmog.CacheItem(id)
				if itemName and id ~= itemID and (not TmogConfig.onlyUsable or Tmog.IsUsableItem(id)) then
					numDuplicates = numDuplicates + 1
					local _, _, _, color = GetItemQualityColor(itemQuality or 1)
					duplicates = duplicates.."\n"..color..itemName.."|r"
				end
			end
			if numDuplicates > 0 then
				duplicates = NORMAL..L["Shares appearance with"]..":|r"..duplicates
				lastLine:SetText(lastLine:GetText().."\n\n"..duplicates)
			end
		end
		TmogTooltip:Show()

	elseif Tmog.currentTab == "OUTFITS" then
		local tooltipTitle = self:GetParent().name
		if not tooltipTitle then return end

		TmogTooltip:SetOwner(self, "ANCHOR_RIGHT", -5, -8)

		if self:GetID() == 0 then
			if not self.plusPushed:IsShown() then
				self.plusHighlight:Show()
			end
			TmogTooltip:AddLine(tooltipTitle, 1, 1, 1, true)
			TmogTooltip:AddLine(L["Create an outfit from selected items."], 1, 0.82, 0, true)
		else
			TmogTooltip:AddDoubleLine(tooltipTitle, " ", 1, 1, 1, 1, 1, 1)
			local outfitData = TMOG_PLAYER_OUTFITS[self:GetID()]
			local numItemsInOutfit = 0
			local numCollected = 0
			if outfitData then
				numItemsInOutfit = Tmog.tsize(outfitData) - 1
				for slot, itemID in pairs(outfitData) do
					if type(itemID) == "number" then
						local slotName = Tmog.InventorySlotToString[slot]
						local itemName, itemQuality, itemTexture = Tmog.CacheItem(itemID)
						if itemName and slotName then
							local _, _, _, color = GetItemQualityColor(itemQuality or 1)
							local status = ""
							if TMOG_CACHE[slot][itemID] then
								status = NORMAL..L["Collected"].."|r"
								numCollected = numCollected + 1
							else
								status = GREY..L["Not collected"].."|r"
							end
							TmogTooltip:AddDoubleLine(slotName..": "..color..itemName, status)
						end
					end
				end
			end
			self:GetParent().model:SetLight(unpack(Tmog.Light.previewHighlight))
			TmogTooltipTextRight1:SetText(string.format("(%d/%d)", numCollected, numItemsInOutfit))
			TmogTooltip:AddLine(L["<Shift-Click to link outfit to chat>"])
		end
		TmogTooltip:Show()
	end
end

function Tmog.PreviewButton_OnLeave(self)
	self:GetParent().model:SetLight(unpack(Tmog.Light.previewNormal))
	if self.plusHighlight then
		self.plusHighlight:Hide()
	end
	TmogTooltip:Hide()
	TmogTooltip.itemID = nil
end

local hidden = false
function Tmog.HideUI()
	if not hidden then
		for _, frame in pairs(Tmog.PlayerSlotFrames) do
			frame:Hide()
		end
		TmogFrameResetOutfit:Hide()
		TmogFrameFullScreenButton:Hide()
		TmogFrameHideUI:SetText(L["Show UI"])
		hidden = true
	else
		for _, frame in pairs(Tmog.PlayerSlotFrames) do
			frame:Show()
		end
		TmogFrameResetOutfit:Show()
		TmogFrameFullScreenButton:Show()
		TmogFrameHideUI:SetText(L["Hide UI"])
		hidden = false
	end
end

function Tmog.ToggleFrame()
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
	if Tmog.currentTab == "ITEMS" and TmogFrameSearchBox:GetText() == "" and Tmog.currentSlot and Tmog.currentType then
		Tmog.currentPage = Tmog.PagesMemory[Tmog.currentSlot][Tmog.currentType]
	else
		Tmog.currentPage = 1
	end
	Tmog.UpdatePreviewsData()
	Tmog.UpdatePreviews()
end

function Tmog.SwitchTab(newTab)
	if Tmog.currentTab == newTab then return end

	Tmog.currentTab = newTab

	if newTab == "ITEMS" then
		TmogFrameTab1:Disable()
		TmogFrameTab2:Enable()
		TmogFrameImportOutfitButton:Hide()

		if Tmog.currentSlot and Tmog.currentType then
			if TmogFrameSearchBox:GetText() == "" then
				Tmog.currentPage = Tmog.PagesMemory[Tmog.currentSlot][Tmog.currentType]
			else
				Tmog.currentPage = 1
			end
			if table.getn(Tmog.GetTypesForSlot(Tmog.currentSlot)) > 1 then
				TmogFrameTypeDropDown:Show()
			else
				TmogFrameTypeDropDown:Hide()
			end
			TmogFrameFiltersButton:Show()
			Tmog.HidePreviews()
			Tmog.UpdatePreviewsData()
			Tmog.UpdatePreviews()
		else
			Tmog.HidePreviews()
			Tmog.HidePagination()
		end

	elseif newTab == "OUTFITS" then
		-- LoadingFrame.queueTimer = 0
		Tmog.currentPage = 1
		TmogFrameTab1:Enable()
		TmogFrameTab2:Disable()
		TmogFrameImportOutfitButton:Show()
		TmogFrameTypeDropDown:Hide()
		TmogFrameFiltersButton:Hide()
		Tmog.UpdatePreviewsData()
		Tmog.UpdatePreviews()
	end

	TmogFrameSharedItems:Hide()
	DropDownList1:Hide()
end

function Tmog.TypeDropDown_Initialize()
	local types = Tmog.GetTypesForSlot(Tmog.currentSlot)
	if not types then return end

	local info = UIDropDownMenu_CreateInfo()
	for _, type in pairs(types) do
		info.text = type
		info.checked = Tmog.currentType == type
		info.func = Tmog.SelectType
		info.arg1 = type
		if TmogConfig.onlyUsable then
			if Tmog.classEquipTable[Tmog.playerClass][type] then
				if not (not Tmog.canDualWeild and Tmog.currentSlot == 17 and type ~= L["Shields"] and type ~= L["Miscellaneous"]) then
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

local SkipList = {}
function Tmog.UpdatePreviewsData()
	local searchStr = Tmog.strtrim(string.lower(TmogFrameSearchBox:GetText()))
	local searching = searchStr ~= ""
	if Tmog.currentTab == "ITEMS" then
		if not (Tmog.currentSlot and Tmog.currentType) then return end
		for i = table.getn(Tmog.ItemsSorted), 1, -1 do table.remove(Tmog.ItemsSorted, i) end
		local collection = TMOG_CACHE[Tmog.currentSlot]
		if searching then
			for type in pairs(Tmog.ItemDB[Tmog.currentSlot]) do
				for itemID in pairs(Tmog.ItemDB[Tmog.currentSlot][type]) do
					local itemName = Tmog.CacheItem(itemID)
					if itemName then
						if string.find(string.lower(itemName), searchStr, 1, true) then
							local insert = Tmog.Transmogable(itemID)
							if not insert then
								Tmog.debugprint(string.format("ItemDB contains not transmogable item %d slot %d type %s", itemID, Tmog.currentSlot, Tmog.currentType))
							end
							if not TmogConfig.collected and collection[itemID] then insert = false end
							if not TmogConfig.notCollected and not collection[itemID] then insert = false end
							if TmogConfig.onlyUsable and not Tmog.IsUsableItem(itemID) then insert = false end
							if insert then table.insert(Tmog.ItemsSorted, itemID) end
						end
					elseif not LoadingFrame.queueIDs[itemID] then
						LoadingFrame.queueTimer = Tmog.loadingTimeMax
						LoadingFrame.queueIDs[itemID] = true
					end
				end
			end
		else
			for k in pairs(SkipList) do SkipList[k] = nil end
			for itemID in pairs(Tmog.ItemDB[Tmog.currentSlot][Tmog.currentType]) do
				local itemName = Tmog.CacheItem(itemID)
				if itemName then
					local insert = Tmog.Transmogable(itemID)
					if not insert then
						Tmog.debugprint(string.format("ItemDB contains not transmogable item %d slot %d type %s", itemID, Tmog.currentSlot, Tmog.currentType))
					end
					if not TmogConfig.collected and collection[itemID] then insert = false end
					if not TmogConfig.notCollected and not collection[itemID] then insert = false end
					if TmogConfig.onlyUsable and not Tmog.IsUsableItem(itemID) then insert = false end
					local displayGroup = Tmog.ItemDisplayGroup[itemID]
					if insert and displayGroup then
						insert = not SkipList[displayGroup]
						SkipList[displayGroup] = true
					end
					if insert then table.insert(Tmog.ItemsSorted, itemID) end
				elseif not LoadingFrame.queueIDs[itemID] then
					LoadingFrame.queueTimer = Tmog.loadingTimeMax
					LoadingFrame.queueIDs[itemID] = true
				end
			end
		end
		Tmog.totalPages = math.ceil(table.getn(Tmog.ItemsSorted) / Tmog.itemsPerPage)
		table.sort(Tmog.ItemsSorted, Tmog.Sort)
	elseif Tmog.currentTab == "OUTFITS" then
		for i = table.getn(Tmog.OutfitsSorted), 1, -1 do table.remove(Tmog.OutfitsSorted, i) end
		for i = 1, table.getn(TMOG_PLAYER_OUTFITS) do
			local data = TMOG_PLAYER_OUTFITS[i]
			if not searching or string.find(string.lower(data.name), searchStr, 1, true) then
				table.insert(Tmog.OutfitsSorted, data)
			end
		end
		Tmog.totalPages = math.ceil((table.getn(Tmog.OutfitsSorted) + 1) / Tmog.itemsPerPage)
	end
end
