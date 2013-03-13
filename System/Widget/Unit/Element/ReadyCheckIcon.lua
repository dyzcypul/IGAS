﻿-- Author      : Kurapica
-- Create Date : 2012/06/25
-- Change Log  :

-- Check Version
local version = 1
if not IGAS:NewAddon("IGAS.Widget.Unit.ReadyCheckIcon", version) then
	return
end

class "ReadyCheckIcon"
	inherit "Texture"
	extend "IFReadyCheck"

	doc [======[
		@name ReadyCheckIcon
		@type class
		@desc The ready check indicator
	]======]

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
	function ReadyCheckIcon(self)
		self.Height = 16
		self.Width = 16
	end
endclass "ReadyCheckIcon"