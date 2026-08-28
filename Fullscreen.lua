local L = Tmog.L

function TmogFrameFullScreenModel_OnLoad(self)
	self.z, self.x, self.y, self.f = -3, 0, 0, 0
	self:SetLight(unpack(Tmog.fullScreenLight))
end

function TmogFrameFullScreenModel_OnShow(self)
	UIFrameFadeIn(self, 0.3, 0, 1)
	self:SetWidth(GetScreenWidth() + 5)
	self:SetHeight(GetScreenHeight() + 5)
	self:SetPosition(0, 0, 0)
	self:SetUnit("player")
	Tmog.Dress(self)
	self:SetPosition(self.z, self.x, self.y)
	self:SetFacing(self.f)
end

function TmogFrameFullScreenModel_OnHide(self)
	self.z, self.x, self.y = self:GetPosition()
	self.f = self:GetFacing()
end

function TmogFrameFullScreenModel_OnUpdate(self, elapsed)
	if not self.mouseButton then return end
	if self.mouseButton == "LeftButton" then
		local endX, endY = GetCursorPosition()
		self:SetFacing((endX - self.startX) / 34 + self:GetFacing())
		self.startX, self.startY = GetCursorPosition()
	elseif self.mouseButton == "RightButton" then
		local endX, endY = GetCursorPosition()
		local z, x, y = self:GetPosition()
		x = (endX - self.startX) / 180 + x
		y = (endY - self.startY) / 180 + y
		self:SetPosition(z, x, y)
		self.startX, self.startY = GetCursorPosition()
	end
end

function TmogFrameFullScreenModel_OnMouseWheel(self, delta)
	local z, x, y = self:GetPosition()
	z = z + delta
	self:SetPosition(z, x, y)
	self.z = z
end

function TmogFrameFullScreenModel_OnMouseDown(self, button)
	self.startX, self.startY = GetCursorPosition()
	self.mouseButton = button
end

function TmogFrameFullScreenModel_OnMouseUp(self, button)
	self.z, self.x, self.y = self:GetPosition()
	self.mouseButton = nil
end

function TmogFrameFullScreen_OnUpdate()
	if not this.fadeTime then
		return
	end
	if (GetTime() - this.fadeTime) > 0.3 then
		this.fadeTime = nil
		this:Hide()
	end
end

function TmogFrameFullScreen_OnKeyDown()
	local screenshotKey = GetBindingKey("SCREENSHOT")
	if arg1 == "ESCAPE" then
		this:SetScript("OnKeyDown", nil)
		this.fadeTime = GetTime()
		UIFrameFadeOut(TmogFrameFullScreenModel, 0.3, 1, 0)
	elseif screenshotKey and (arg1 == screenshotKey) then
		RunBinding("SCREENSHOT")
	end
end