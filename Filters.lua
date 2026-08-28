local L = Tmog.L

function Tmog.FiltersButton_OnClick(self, button)
	if not TmogFrameFiltersDropDown.initialize then
		UIDropDownMenu_Initialize(TmogFrameFiltersDropDown, function()
			local info = UIDropDownMenu_CreateInfo()
			info.keepShownOnClick = true

			info.text = L["Collected"]
			info.checked = Tmog.collected
			info.func = Tmog.CollectedToggle
			info.disabled = nil
			UIDropDownMenu_AddButton(info)

			info.text = L["Not collected"]
			info.checked = Tmog.notCollected
			info.func = Tmog.NotCollectedToggle
			info.disabled = nil
			UIDropDownMenu_AddButton(info)

			info.text = L["Only usable"]
			info.checked = Tmog.onlyUsable
			info.func = function()
				Tmog.UsableToggle()
				local button = DropDownList1Button4
				local invisibleButton = DropDownList1Button4InvisibleButton
				if Tmog.onlyUsable then
					button:Enable()
					invisibleButton:Hide()
				else
					button:Disable()
					invisibleButton:Show()
				end
			end
			info.disabled = nil
			UIDropDownMenu_AddButton(info)

			info.text = L["Ignore level"]
			info.checked = Tmog.ignoreLevel
			info.func = Tmog.IgnoreLevelToggle
			info.disabled = not Tmog.onlyUsable
			UIDropDownMenu_AddButton(info)
		end, "MENU")
	end
	ToggleDropDownMenu(1, nil, TmogFrameFiltersDropDown, self:GetName(), 0, 0)
end

function Tmog.ResetUnusableTable()
	for k in pairs(Tmog.Unusable) do
		for k2 in pairs(Tmog.Unusable[k]) do
			for k3 in pairs(Tmog.Unusable[k][k2]) do
				Tmog.Unusable[k][k2][k3] = nil
			end
		end
	end
end

function Tmog.CollectedToggle()
	Tmog.collected = not Tmog.collected
	Tmog.flush = true
	if Tmog.currentSlot then
		Tmog.ResetPages()
		Tmog.DrawPreviews()
	end
end

function Tmog.NotCollectedToggle()
	Tmog.notCollected = not Tmog.notCollected
	Tmog.flush = true
	if Tmog.currentSlot then
		Tmog.ResetPages()
		Tmog.DrawPreviews()
	end
end

function Tmog.UsableToggle()
	Tmog.onlyUsable = not Tmog.onlyUsable
	Tmog.flush = true
	if Tmog.currentSlot then
		Tmog.ResetPages()
		Tmog.ResetUnusableTable()
		Tmog.DrawPreviews()
	end
end

function Tmog.IgnoreLevelToggle()
	Tmog.ignoreLevel = not Tmog.ignoreLevel
	Tmog.flush = true
	if Tmog.currentSlot then
		Tmog.ResetPages()
		Tmog.ResetUnusableTable()
		Tmog.DrawPreviews()
	end
end
