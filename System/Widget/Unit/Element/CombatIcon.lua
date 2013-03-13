﻿-- Author      : Kurapica
-- Create Date : 2012/06/25
-- Change Log  :

-- Check Version
local version = 1
if not IGAS:NewAddon("IGAS.Widget.Unit.CombatIcon", version) then
	return
end

class "CombatIcon"
	inherit "Texture"
	extend "IFCombat"

	doc [======[
		@name CombatIcon
		@type class
		@desc The combat indicator
	]======]

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
	function CombatIcon(self)
		self.Height = 32
		self.Width = 32
	end
endclass "CombatIcon"