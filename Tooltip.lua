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

function Tmog.HookTooltip(tooltip)
	if not (tooltip and type(tooltip.GetFrameType) == "function" and tooltip:GetFrameType() == "GameTooltip") then
		return
	end

	if type(tooltip.HookScript) == "function" then
		tooltip:HookScript("OnTooltipSetItem", function(self)
			local itemName, itemLink, itemID = self:GetItem()
			self.itemID = itemID or Tmog.IDFromLink(itemLink)
		end)
		tooltip:HookScript("OnTooltipCleared", function(self)
			self.itemID = nil
			self.tmogLine = nil
			self.tooltipMoney = 0
		end)
		for _, method in pairs({
			"SetBagItem","SetInventoryItem","SetLootRollItem","SetLootItem","SetMerchantItem","SetQuestLogItem",
			"SetQuestItem","SetHyperlink","SetInboxItem","SetCraftItem","SetCraftSpell","SetTradeSkillItem",
			"SetAuctionItem","SetAuctionSellItem","SetTradePlayerItem","SetTradeTargetItem","SetAction","SetBuybackItem"
		}) do
			hooksecurefunc(tooltip, method, Tmog.ExtendTooltip)
		end
		return
	end

	local original_SetBagItem = tooltip.SetBagItem
	function tooltip.SetBagItem(self, container, slot)
		self.insideHook = true
		local hasCooldown, repairCost = original_SetBagItem(self, container, slot)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetContainerItemLink(container, slot))
		Tmog.ExtendTooltip(self)
		return hasCooldown, repairCost
	end

	local original_SetInventoryItem = tooltip.SetInventoryItem
	function tooltip.SetInventoryItem(self, unit, slot, nameOnly)
		self.insideHook = true
		local hasItem, hasCooldown, repairCost = original_SetInventoryItem(self, unit, slot, nameOnly)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetInventoryItemLink(unit, slot))
		Tmog.ExtendTooltip(self)
		return hasItem, hasCooldown, repairCost
	end

	local original_SetLootRollItem = tooltip.SetLootRollItem
	function tooltip.SetLootRollItem(self, id)
		self.insideHook = true
		original_SetLootRollItem(self, id)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetLootRollItemLink(id))
		Tmog.ExtendTooltip(self)
	end

	local original_SetLootItem = tooltip.SetLootItem
	function tooltip.SetLootItem(self, slot)
		self.insideHook = true
		original_SetLootItem(self, slot)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetLootSlotLink(slot))
		Tmog.ExtendTooltip(self)
	end

	local original_SetMerchantItem = tooltip.SetMerchantItem
	function tooltip.SetMerchantItem(self, merchantIndex)
		self.insideHook = true
		original_SetMerchantItem(self, merchantIndex)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetMerchantItemLink(merchantIndex))
		Tmog.ExtendTooltip(self)
	end

	local original_SetQuestLogItem = tooltip.SetQuestLogItem
	function tooltip.SetQuestLogItem(self, itemType, index)
		self.insideHook = true
		original_SetQuestLogItem(self, itemType, index)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetQuestLogItemLink(itemType, index))
		Tmog.ExtendTooltip(self)
	end

	local original_SetQuestItem = tooltip.SetQuestItem
	function tooltip.SetQuestItem(self, itemType, index)
		self.insideHook = true
		original_SetQuestItem(self, itemType, index)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetQuestItemLink(itemType, index))
		Tmog.ExtendTooltip(self)
	end

	local original_SetHyperlink = tooltip.SetHyperlink
	function tooltip.SetHyperlink(self, arg1)
		self.insideHook = true
		original_SetHyperlink(self, arg1)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(arg1)
		Tmog.ExtendTooltip(self)
	end

	local original_SetInboxItem = tooltip.SetInboxItem
	function tooltip.SetInboxItem(self, mailID, attachmentIndex)
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

	local original_SetCraftItem = tooltip.SetCraftItem
	function tooltip.SetCraftItem(self, skill, slot)
		self.insideHook = true
		original_SetCraftItem(self, skill, slot)
		self.nsideHook = nil
		self.itemID = Tmog.IDFromLink(GetCraftReagentItemLink(skill, slot))
		Tmog.ExtendTooltip(self)
	end

	local original_SetCraftSpell = tooltip.SetCraftSpell
	function tooltip.SetCraftSpell(self, slot)
		self.insideHook = true
		original_SetCraftSpell(self, slot)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetCraftItemLink(slot))
		Tmog.ExtendTooltip(self)
	end

	local original_SetTradeSkillItem = tooltip.SetTradeSkillItem
	function tooltip.SetTradeSkillItem(self, skillIndex, reagentIndex)
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

	local original_SetAuctionItem = tooltip.SetAuctionItem
	function tooltip.SetAuctionItem(self, atype, index)
		self.insideHook = true
		original_SetAuctionItem(self, atype, index)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetAuctionItemLink(atype, index))
		Tmog.ExtendTooltip(self)
	end

	local original_SetAuctionSellItem = tooltip.SetAuctionSellItem
	function tooltip.SetAuctionSellItem(self)
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

	local original_SetTradePlayerItem = tooltip.SetTradePlayerItem
	function tooltip.SetTradePlayerItem(self, index)
		self.insideHook = true
		original_SetTradePlayerItem(self, index)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetTradePlayerItemLink(index))
		Tmog.ExtendTooltip(self)
	end

	local original_SetTradeTargetItem = tooltip.SetTradeTargetItem
	function tooltip.SetTradeTargetItem(self, index)
		self.insideHook = true
		original_SetTradeTargetItem(self, index)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetTradeTargetItemLink(index))
		Tmog.ExtendTooltip(self)
	end

	local original_OnHide = tooltip:GetScript("OnHide")
	tooltip:SetScript("OnHide", function()
		if original_OnHide then original_OnHide(tooltip) end
		tooltip.itemID = nil
		tooltip.tmogLine = nil
		tooltip.tooltipMoney = 0
	end)
end

local maxLines = 30
function Tmog.ExtendTooltip(frame)
	local itemID = tonumber(frame.itemID)
	if itemID and frame ~= TmogTooltip and Tmog.Transmogable(itemID) then
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
				line = L["Unknown appearance"].." (?)"..line
			else
				line = L["Unique appearance"]..line
			end
		else
			if numItems > 0 then
				line = L["Non-unique appearance"].." ("..numItems..")"..line
			else
				line = L["Non-unique appearance"].." (?)"..line
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
		local slot = Tmog.GetTransmogSlot(itemID, "player", frame)
		if slot then
			if TMOG_CACHE[slot][itemID] then
				line = "("..GREEN..L["Collected"].."|r"..") "..line
			else
				line = "("..YELLOW..L["Not collected"].."|r"..") "..line
			end
		end
		local numLines = frame:NumLines()
		if numLines > maxLines then maxLines = numLines end
		if numLines < maxLines then
			frame:AddLine(line, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, numOutfits > 1)
		else
			local lastLine = _G[frame:GetName().."TextLeft"..numLines]
			lastLine:SetText(lastLine:GetText().."\n"..line)
		end
		frame.tmogLine = line
		frame:Show()
	end
	local money = frame.tooltipMoney or 0
	if money > 0 then
		original_SetTooltipMoney(frame, money)
		frame:Show()
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
