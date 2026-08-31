local NORMAL = NORMAL_FONT_COLOR_CODE
local WHITE = HIGHLIGHT_FONT_COLOR_CODE
local GREY = GRAY_FONT_COLOR_CODE
local YELLOW = "|cffFFFF00"
local GREEN = "|cff00A000"
local BLUE = "|cff0070de"
local L = Tmog.L

local TmogTooltip = CreateFrame("GameTooltip", "TmogTooltip", UIParent, "GameTooltipTemplate")
TmogTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

local TmogScanTooltip = CreateFrame("GameTooltip", "TmogScanTooltip", nil, "GameTooltipTemplate")
TmogScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

local original_SetTooltipMoney = SetTooltipMoney
function SetTooltipMoney(frame, money)
	if frame.insideHook then
		frame.tooltipMoney = money or 0
	else
		original_SetTooltipMoney(frame, money)
	end
end

function Tmog.HookTooltip(frame)
	if not (frame and type(frame.GetFrameType) == "function" and frame:GetFrameType() == "GameTooltip") then
		return
	end

	if type(frame.HookScript) == "function" then
		frame:HookScript("OnTooltipSetItem", function(self)
			local itemName, itemLink, itemID = self:GetItem()
			self.itemID = itemID or Tmog.IDFromLink(itemLink)
		end)
		frame:HookScript("OnTooltipCleared", function(self)
			self.itemID = nil
			self.tmogLine = nil
			self.tooltipMoney = 0
		end)
		for _, method in pairs({
			"SetBagItem","SetInventoryItem","SetLootRollItem","SetLootItem","SetMerchantItem","SetQuestLogItem",
			"SetQuestItem","SetHyperlink","SetInboxItem","SetCraftItem","SetCraftSpell","SetTradeSkillItem",
			"SetAuctionItem","SetAuctionSellItem","SetTradePlayerItem","SetTradeTargetItem","SetAction","SetBuybackItem"
		}) do
			hooksecurefunc(frame, method, Tmog.ExtendTooltip)
		end
		return
	end

	local original_SetBagItem = frame.SetBagItem
	function frame.SetBagItem(self, container, slot)
		self.insideHook = true
		local hasCooldown, repairCost = original_SetBagItem(self, container, slot)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetContainerItemLink(container, slot))
		Tmog.ExtendTooltip(self)
		return hasCooldown, repairCost
	end

	local original_SetInventoryItem = frame.SetInventoryItem
	function frame.SetInventoryItem(self, unit, slot, nameOnly)
		self.insideHook = true
		local hasItem, hasCooldown, repairCost = original_SetInventoryItem(self, unit, slot, nameOnly)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetInventoryItemLink(unit, slot))
		Tmog.ExtendTooltip(self)
		return hasItem, hasCooldown, repairCost
	end

	local original_SetLootRollItem = frame.SetLootRollItem
	function frame.SetLootRollItem(self, id)
		self.insideHook = true
		original_SetLootRollItem(self, id)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetLootRollItemLink(id))
		Tmog.ExtendTooltip(self)
	end

	local original_SetLootItem = frame.SetLootItem
	function frame.SetLootItem(self, slot)
		self.insideHook = true
		original_SetLootItem(self, slot)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetLootSlotLink(slot))
		Tmog.ExtendTooltip(self)
	end

	local original_SetMerchantItem = frame.SetMerchantItem
	function frame.SetMerchantItem(self, merchantIndex)
		self.insideHook = true
		original_SetMerchantItem(self, merchantIndex)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetMerchantItemLink(merchantIndex))
		Tmog.ExtendTooltip(self)
	end

	local original_SetQuestLogItem = frame.SetQuestLogItem
	function frame.SetQuestLogItem(self, itemType, index)
		self.insideHook = true
		original_SetQuestLogItem(self, itemType, index)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetQuestLogItemLink(itemType, index))
		Tmog.ExtendTooltip(self)
	end

	local original_SetQuestItem = frame.SetQuestItem
	function frame.SetQuestItem(self, itemType, index)
		self.insideHook = true
		original_SetQuestItem(self, itemType, index)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetQuestItemLink(itemType, index))
		Tmog.ExtendTooltip(self)
	end

	local original_SetHyperlink = frame.SetHyperlink
	function frame.SetHyperlink(self, arg1)
		self.insideHook = true
		original_SetHyperlink(self, arg1)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(arg1)
		Tmog.ExtendTooltip(self)
	end

	local original_SetInboxItem = frame.SetInboxItem
	function frame.SetInboxItem(self, mailID, attachmentIndex)
		self.insideHook = true
		original_SetInboxItem(self, mailID, attachmentIndex)
		self.insideHook = nil
		if GetInboxItemLink then
			self.itemID = Tmog.IDFromLink(GetInboxItemLink(mailID, attachmentIndex))
		else
			self.itemID = Tmog.GetItemIDByName(GetInboxItem(mailID, attachmentIndex))
		end
		Tmog.ExtendTooltip(self)
	end

	local original_SetCraftItem = frame.SetCraftItem
	function frame.SetCraftItem(self, skill, slot)
		self.insideHook = true
		original_SetCraftItem(self, skill, slot)
		self.nsideHook = nil
		self.itemID = Tmog.IDFromLink(GetCraftReagentItemLink(skill, slot))
		Tmog.ExtendTooltip(self)
	end

	local original_SetCraftSpell = frame.SetCraftSpell
	function frame.SetCraftSpell(self, slot)
		self.insideHook = true
		original_SetCraftSpell(self, slot)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetCraftItemLink(slot))
		Tmog.ExtendTooltip(self)
	end

	local original_SetTradeSkillItem = frame.SetTradeSkillItem
	function frame.SetTradeSkillItem(self, skillIndex, reagentIndex)
		self.insideHook = true
		original_SetTradeSkillItem(self, skillIndex, reagentIndex)
		self.insideHook = nil
		if reagentIndex then
			self.itemID = Tmog.IDFromLink(GetTradeSkillReagentItemLink(skillIndex, reagentIndex))
		else
			self.itemID = Tmog.IDFromLink(GetTradeSkillItemLink(skillIndex))
		end
		Tmog.ExtendTooltip(self)
	end

	local original_SetAuctionItem = frame.SetAuctionItem
	function frame.SetAuctionItem(self, atype, index)
		self.insideHook = true
		original_SetAuctionItem(self, atype, index)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetAuctionItemLink(atype, index))
		Tmog.ExtendTooltip(self)
	end

	local original_SetAuctionSellItem = frame.SetAuctionSellItem
	function frame.SetAuctionSellItem(self)
		self.insideHook = true
		original_SetAuctionSellItem(self)
		self.insideHook = nil
		local name, texture, stackSize, quality, canUse, price, maxStack, link = GetAuctionSellItemInfo()
		if link then
			self.itemID = Tmog.IDFromLink(link)
		else
			self.itemID = Tmog.GetItemIDByName(name)
		end
		Tmog.ExtendTooltip(self)
	end

	local original_SetTradePlayerItem = frame.SetTradePlayerItem
	function frame.SetTradePlayerItem(self, index)
		self.insideHook = true
		original_SetTradePlayerItem(self, index)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetTradePlayerItemLink(index))
		Tmog.ExtendTooltip(self)
	end

	local original_SetTradeTargetItem = frame.SetTradeTargetItem
	function frame.SetTradeTargetItem(self, index)
		self.insideHook = true
		original_SetTradeTargetItem(self, index)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetTradeTargetItemLink(index))
		Tmog.ExtendTooltip(self)
	end

	local original_OnHide = frame:GetScript("OnHide")
	frame:SetScript("OnHide", function()
		if original_OnHide then original_OnHide(frame) end
		frame.itemID = nil
		frame.tmogLine = nil
		frame.tooltipMoney = 0
	end)
end

local maxLines = 30
function Tmog.ExtendTooltip(self)
    self = self or this
	local itemID = tonumber(self.itemID)
	if itemID and self ~= TmogTooltip and Tmog.Transmogable(itemID) then
		local line = ""
		local outfits = Tmog.GetOutfitsWithItem(itemID)
		local numOutfits = table.getn(outfits)
		local items = Tmog.GetSameAppearanceItems(itemID)
		local numItems = items and table.getn(items) or 0
		if numOutfits > 0 then
			line = GREY.." ("..string.format(L["Outfits: %s"], table.concat(outfits, ", "))..")|r"
		end
		if not items then
			if not Tmog.IsKnownAppearance(itemID) then
				line = NORMAL..L["Unknown appearance"].." (?)|r"..line
			else
				line = NORMAL..L["Unique appearance"].."|r"..line
			end
		else
			if numItems > 0 then
				line = NORMAL..L["Non-unique appearance"].." ("..numItems..")|r"..line
			else
				line = NORMAL..L["Non-unique appearance"].." (?)|r"..line
			end
			-- if IsShiftKeyDown() then
			-- 	for i = 1, numItems do
			-- 		local name, _, quality = GetItemInfo(items[i])
			-- 		local _, _, _, color = GetItemQualityColor(quality)
			-- 		items[i] = color..name.."|r"
			-- 	end
			-- 	line = line.."\n  "..concat(items, "\n  ")
			-- end
		end
		local slot = Tmog.GetTransmogSlot(itemID, "player", self)
		if slot then
			if TMOG_CACHE[slot][itemID] then
				line = "("..GREEN..L["Collected"].."|r"..") "..line
			else
				line = "("..YELLOW..L["Not collected"].."|r"..") "..line
			end
		end
		local numLines = self:NumLines()
		if numLines > maxLines then maxLines = numLines end
		if numLines < maxLines then
			self:AddLine(line, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, numOutfits > 1)
		else
			local lastLine = _G[self:GetName().."TextLeft"..numLines]
			lastLine:SetText(lastLine:GetText().."\n"..line)
		end
		self.tmogLine = line
		self:Show()
	end
	local money = self.tooltipMoney or 0
	if money > 0 then
		original_SetTooltipMoney(self, money)
		self:Show()
	end
end

local original_OnShow = GameTooltip:GetScript("OnShow")
GameTooltip:SetScript("OnShow", function()
	if original_OnShow then original_OnShow(GameTooltip) end

	if aux_frame and aux_frame:IsShown() then
		local frame = GetMouseFocus()
		if not frame then return end
		local parent = frame:GetParent()
		if not (parent and parent.row and parent.row.record) then return end

		GameTooltip.itemID = tonumber(parent.row.record.item_id)
		Tmog.ExtendTooltip(GameTooltip)
	end
end)
