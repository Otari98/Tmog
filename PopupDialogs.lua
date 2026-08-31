local L = Tmog.L

StaticPopupDialogs["TMOG_NEW_OUTFIT"] = {
	text = L["Enter outfit name:"],
	button1 = OKAY,
	button2 = CANCEL,
	hasEditBox = 1,
	OnShow = function()
		if Tmog.currentTab == "OUTFITS" then
			if Tmog.currentPage == 1 then
				TmogFramePreview1ButtonPlus:Hide()
				TmogFramePreview1ButtonPlusPushed:Show()
			else
				TmogFramePreview1ButtonPlus:Hide()
				TmogFramePreview1ButtonPlusPushed:Hide()
			end
		end
	end,
	OnAccept = function()
		local editBox = _G[this:GetParent():GetName() .. "EditBox"]
		local outfitName = editBox:GetText()
		if Tmog.currentTab == "OUTFITS" then
			if Tmog.currentPage == 1 then
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
		local outfitData = Tmog.GetOutfitByName(outfitName)
		if outfitData then
			StaticPopup_Show("TMOG_OUTFIT_EXISTS", nil, nil, outfitName)
			return
		end
		Tmog.currentOutfit = outfitName
		Tmog.SaveOutfit()
		editBox:SetText("")
	end,
	OnCancel = function()
		if Tmog.currentTab == "OUTFITS" then
			if Tmog.currentPage == 1 then
				TmogFramePreview1ButtonPlus:Show()
				TmogFramePreview1ButtonPlusPushed:Hide()
			else
				TmogFramePreview1ButtonPlus:Hide()
				TmogFramePreview1ButtonPlusPushed:Hide()
			end
		end
	end,
	EditBoxOnEnterPressed = function()
		StaticPopupDialogs["TMOG_NEW_OUTFIT"].OnAccept()
		this:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function()
		this:GetParent():Hide()
	end,
	timeout = 0,
	whileDead = 0,
	hideOnEscape = 1,
}

StaticPopupDialogs["TMOG_OUTFIT_RENAME"] = {
	text = L["Enter outfit name:"],
	button1 = OKAY,
	button2 = CANCEL,
	hasEditBox = 1,
	OnShow = function()
		local editBox = _G[this:GetName() .. "EditBox"]
		editBox:SetText(this.data)
		editBox:HighlightText()
	end,
	OnAccept = function()
		local dialog = this:GetParent()
		local newName = _G[dialog:GetName() .. "EditBox"]:GetText()
		Tmog.RenameOutfit(dialog.data, newName)
	end,
	EditBoxOnEnterPressed = function()
		StaticPopupDialogs["TMOG_OUTFIT_RENAME"].OnAccept()
		this:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function()
		this:GetParent():Hide()
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
}

StaticPopupDialogs["TMOG_OUTFIT_EXISTS"] = {
	text = L["Outfit with this name already exists. Do you want to overwrite it?"],
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		local outfitName = this:GetParent().data
		local outfitData = Tmog.GetOutfitByName(outfitName)
		if outfitName and outfitData then
			Tmog.currentOutfit = outfitName
			Tmog.SaveOutfit()
		end
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
}

StaticPopupDialogs["TMOG_OUTFIT_EMPTY_NAME"] = {
	text = L["Outfit name not valid."],
	button1 = OKAY,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
}

StaticPopupDialogs["TMOG_CONFIRM_DELETE_OUTFIT"] = {
	text = L["Delete outfit %s?"],
	button1 = YES,
	button2 = NO,
	OnAccept = function() Tmog.DeleteOutfit(this:GetParent().data) end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
}

StaticPopupDialogs["TMOG_BAD_OUTFIT_CODE"] = {
	text = L["Invalid outfit code."],
	button1 = OKAY,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
}

StaticPopupDialogs["TMOG_IMPORT_OUTFIT"] = {
	text = L["Enter outfit code or shift-click an outfit link from the chat window:"],
	button1 = OKAY,
	button2 = CANCEL,
	hasEditBox = 1,
	OnShow = function()
		_G[this:GetName().."EditBox"]:SetText("")
	end,
	OnAccept = function()
		local code = _G[this:GetParent():GetName().."EditBox"]:GetText()
		local outfitData = Tmog.ValidateOutfitCode(code)
		if not outfitData then
			StaticPopup_Show("TMOG_BAD_OUTFIT_CODE")
		else
			Tmog.ImportOutfit(outfitData)
			this:GetParent():Hide()
			StaticPopup_Show("TMOG_NEW_OUTFIT")
		end
	end,
	EditBoxOnEnterPressed = function()
		StaticPopupDialogs["TMOG_IMPORT_OUTFIT"].OnAccept()
		this:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function()
		this:GetParent():Hide()
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
}
