local L = Tmog.L


StaticPopupDialogs["TMOG_NEW_OUTFIT"] = {
	text = L["Enter outfit name:"],
	button1 = SAVE,
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
		_G[this:GetName().."EditBox"]:SetFocus()
		_G[this:GetName() .. "EditBox"]:SetScript("OnEnterPressed", function()
			StaticPopup1Button1:Click()
		end)

		_G[this:GetName() .. "EditBox"]:SetScript("OnEscapePressed", function()
			_G[this:GetParent():GetName() .. "EditBox"]:SetText("")
			StaticPopup1Button2:Click()
		end)
	end,

	OnAccept = function()
		local outfitName = _G[this:GetParent():GetName() .. "EditBox"]:GetText()
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

		if TMOG_PLAYER_OUTFITS[outfitName] then
			StaticPopup_Show("TMOG_OUTFIT_EXISTS")
			return
		end

		Tmog.currentOutfit = outfitName
		Tmog.SaveOutfit()
		_G[this:GetParent():GetName() .. "EditBox"]:SetText("")
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

	timeout = 0,
	whileDead = 0,
	hideOnEscape = 1,
}

StaticPopupDialogs["TMOG_OUTFIT_RENAME"] = {
	text = L["Enter outfit name:"],
	button1 = OKAY,
	button2 = CANCEL,
	hasEditBox = 1,
	OnAccept = function()
		local dialog = this:GetParent()
		local newName = _G[dialog:GetName() .. "EditBox"]:GetText()
		Tmog.RenameOutfit(dialog.data, newName)
	end,
	EditBoxOnEnterPressed = function()
		StaticPopupDialogs["TMOG_OUTFIT_RENAME"].OnAccept()
		this:GetParent():Hide()
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
}

StaticPopupDialogs["TMOG_OUTFIT_EXISTS"] = {
	text = L["Outfit with this name already exists."],
	button1 = OKAY,
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

StaticPopupDialogs["TMOG_NEW_OUTFIT_CHOISE"] = {
	text = "",
	button1 = "Selected Items",
	button2 = "Import",
	OnAccept = function() StaticPopup_Show("TMOG_NEW_OUTFIT") end,
	OnCancel = function() StaticPopup_Show("TMOG_IMPORT_OUTFIT") end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
}

StaticPopupDialogs["TMOG_IMPORT_OUTFIT"] = {
	text = L["Enter outfit code:"],
	button1 = OKAY,
	button2 = CANCEL,
	hasEditBox = 1,
	OnShow = function()
		_G[this:GetName().."EditBox"]:SetFocus()
		_G[this:GetName().."EditBox"]:SetText("")
		_G[this:GetName() .. "EditBox"]:SetScript("OnEnterPressed", function()
			StaticPopup1Button1:Click()
		end)

		_G[this:GetName() .. "EditBox"]:SetScript("OnEscapePressed", function()
			_G[this:GetParent():GetName() .. "EditBox"]:SetText("")
			StaticPopup1Button2:Click()
		end)
	end,
	OnAccept = function()
		local code = _G[this:GetParent():GetName() .. "EditBox"]:GetText()
		_G[this:GetParent():GetName() .. "EditBox"]:SetText("")
		local outfit = Tmog.ValidateOutfitCode(code)
		if not outfit then
			StaticPopup_Show("TMOG_BAD_OUTFIT_CODE")
			return
		end
		Tmog.ImportOutfit(outfit)
		this:GetParent():Hide()
		StaticPopup_Show("TMOG_NEW_OUTFIT")
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
}