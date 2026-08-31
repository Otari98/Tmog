local L = Tmog.L

local itemMinLevelPattern = "^"..(string.gsub(ITEM_MIN_LEVEL, "%%d", ""))
local UsableCache = {}
function Tmog.IsUsableItem(id)
	if UsableCache[id] then return UsableCache[id] == 1 end
	local itemName, itemLink, itemQuality, itemLevel, itemType, itemSubType, itemCount, itemEquipLoc, itemTexture = GetItemInfo(id)
	if not itemName then return false end
	if not TmogConfig.ignoreLevel and itemLevel > UnitLevel("player") then return false end -- dont cache this result
	if not Tmog.classEquipTable[Tmog.playerClass][itemSubType] or (not Tmog.canDualWeild and (itemEquipLoc == "INVTYPE_WEAPONOFFHAND" or (itemEquipLoc == "INVTYPE_WEAPON" and Tmog.currentSlot == 17))) then
		UsableCache[id] = 0
		return false
	end
	for i = 2, 15 do
		_G["TmogScanTooltipTextLeft"..i]:SetTextColor(0, 0, 0)
		_G["TmogScanTooltipTextRight"..i]:SetTextColor(0, 0, 0)
	end
	TmogScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
	TmogScanTooltip:SetHyperlink("item:"..id)
	for i = 2, 15 do
		local text = _G["TmogScanTooltipTextLeft"..i]:GetText() or ""
		local leftR, leftG, leftB = _G["TmogScanTooltipTextLeft"..i]:GetTextColor()
		local rightR, rightG, rightB = _G["TmogScanTooltipTextRight"..i]:GetTextColor()
		if Tmog.IsRed(rightR, rightG, rightB) then
			UsableCache[id] = 0
			return false
		end
		if Tmog.IsRed(leftR, leftG, leftB) and not string.find(text, itemMinLevelPattern) then
			UsableCache[id] = 0
			return false
		end
	end
	UsableCache[id] = 1
	return true
end

function Tmog.FiltersButton_OnClick(self, button)
	if not TmogFrameFiltersDropDown.initialize then
		UIDropDownMenu_Initialize(TmogFrameFiltersDropDown, function()
			local info = UIDropDownMenu_CreateInfo()
			info.keepShownOnClick = true

			info.text = L["Collected"]
			info.checked = TmogConfig.collected
			info.func = Tmog.CollectedToggle
			info.disabled = nil
			info.tooltipTitle = L["Collected"]
			info.tooltipText = nil
			UIDropDownMenu_AddButton(info)

			info.text = L["Not collected"]
			info.checked = TmogConfig.notCollected
			info.func = Tmog.NotCollectedToggle
			info.disabled = nil
			info.tooltipTitle = L["Not collected"]
			info.tooltipText = nil
			UIDropDownMenu_AddButton(info)

			info.text = L["Only usable"]
			info.checked = TmogConfig.onlyUsable
			info.func = function()
				Tmog.UsableToggle()
				local button = DropDownList1Button4
				local invisibleButton = DropDownList1Button4InvisibleButton
				if TmogConfig.onlyUsable then
					button:Enable()
					invisibleButton:Hide()
				else
					button:Disable()
					invisibleButton:Show()
				end
			end
			info.disabled = nil
			info.tooltipTitle = L["Only usable"]
			info.tooltipText = L["Check this to only show items that you can equip. Can be inaccurate for quest rewards."]
			UIDropDownMenu_AddButton(info)

			info.text = L["Ignore level"]
			info.checked = TmogConfig.ignoreLevel
			info.func = Tmog.IgnoreLevelToggle
			info.disabled = not TmogConfig.onlyUsable
			info.tooltipTitle = L["Ignore level"]
			info.tooltipText = L["Check this to ignore level requirements while \"Only usable\" filter is active. Can be inaccurate for quest rewards."]
			UIDropDownMenu_AddButton(info)
		end, "MENU")
	end
	ToggleDropDownMenu(1, nil, TmogFrameFiltersDropDown, self:GetName(), 0, 0)
	PlaySound("igMainMenuOptionCheckBoxOn")
end

function Tmog.ResetPages()
	Tmog.currentPage = 1
	for slot in pairs(Tmog.PagesMemory) do
		for type in pairs(Tmog.PagesMemory[slot]) do Tmog.PagesMemory[slot][type] = 1 end
	end
end

function Tmog.CollectedToggle()
	TmogConfig.collected = not TmogConfig.collected
	if Tmog.currentSlot then
		Tmog.ResetPages()
        Tmog.UpdatePreviewsData()
		Tmog.UpdatePreviews()
	end
end

function Tmog.NotCollectedToggle()
	TmogConfig.notCollected = not TmogConfig.notCollected
	if Tmog.currentSlot then
		Tmog.ResetPages()
		Tmog.UpdatePreviewsData()
		Tmog.UpdatePreviews()
	end
end

function Tmog.UsableToggle()
	TmogConfig.onlyUsable = not TmogConfig.onlyUsable
	if Tmog.currentSlot then
		for k in pairs(UsableCache) do UsableCache[k] = nil end
		Tmog.ResetPages()
        Tmog.UpdatePreviewsData()
		Tmog.UpdatePreviews()
	end
end

function Tmog.IgnoreLevelToggle()
	TmogConfig.ignoreLevel = not TmogConfig.ignoreLevel
	if Tmog.currentSlot then
		for k in pairs(UsableCache) do UsableCache[k] = nil end
		Tmog.ResetPages()
        Tmog.UpdatePreviewsData()
		Tmog.UpdatePreviews()
	end
end
