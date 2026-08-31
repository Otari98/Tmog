function Tmog.FullScreenModel_OnLoad(self)
	self.z, self.x, self.y, self.f = -3, 0, 0, 0
	self:SetLight(unpack(Tmog.Light.fullscreenModel))
end

function Tmog.FullScreenModel_OnShow(self)
	UIFrameFadeIn(self, 0.3, 0, 1)
	self:SetWidth(GetScreenWidth() + 5)
	self:SetHeight(GetScreenHeight() + 5)
	self:SetPosition(0, 0, 0)
	self:SetUnit("player")
	Tmog.Dress(self)
	self:SetPosition(self.z, self.x, self.y)
	self:SetFacing(self.f)
end

function Tmog.FullScreenModel_OnHide(self)
	self.z, self.x, self.y = self:GetPosition()
	self.f = self:GetFacing()
end

function Tmog.FullScreenModel_OnUpdate(self, elapsed)
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

function Tmog.FullScreenModel_OnMouseWheel(self, delta)
	local z, x, y = self:GetPosition()
	z = z + delta
	self:SetPosition(z, x, y)
	self.z = z
end

function Tmog.FullScreenModel_OnMouseDown(self, button)
	self.startX, self.startY = GetCursorPosition()
	self.mouseButton = button
end

function Tmog.FullScreenModel_OnMouseUp(self, button)
	self.z, self.x, self.y = self:GetPosition()
	self.mouseButton = nil
end

function Tmog.FullScreen_OnUpdate(self, elapsed)
	if not self.fadeTime then return end
    self.fadeTime= self.fadeTime - elapsed
	if self.fadeTime <= 0 then
		self.fadeTime = nil
		self:Hide()
	end
end

function Tmog.FullScreen_OnKeyDown(self, key)
	local screenshotKey = GetBindingKey("SCREENSHOT")
	if key == "ESCAPE" then
		self.fadeTime = 0.3
		UIFrameFadeOut(TmogFrameFullScreenModel, 0.3, 1, 0)
	elseif screenshotKey and key == screenshotKey then
		RunBinding("SCREENSHOT")
	end
end
