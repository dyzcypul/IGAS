-- Author      : Kurapica
-- Create Date : 2012/08/27
-- Change Log  :

-- Check Version
local version = 2
if not IGAS:NewAddon("IGAS.Widget.IFElementPanel", version) then
	return
end

import "System.Collections"

__Doc__[[IFElementPanel provides features to build an panel to contain elements of same class in a grid, the elements are generated by the IFElementPanel]]
interface "IFElementPanel"
	extend "IList"

	local function AdjustElement(element, self)
		if not element.ID then return end

		element.Width = self.ElementWidth
		element.Height = self.ElementHeight

		local posX = (self.Orientation == Orientation.HORIZONTAL and (element.ID - 1) % self.ColumnCount or floor((element.ID - 1) / self.RowCount)) * (self.ElementWidth + self.HSpacing)
		local posY = (self.Orientation == Orientation.HORIZONTAL and floor((element.ID - 1) / self.ColumnCount) or (element.ID - 1) % self.RowCount) * (self.ElementHeight + self.VSpacing)

		element:ClearAllPoints()

		if self.TopToBottom then
			element:SetPoint("TOP", 0, - posY)
		else
			element:SetPoint("BOTTOM", 0, posY)
		end

		if self.LeftToRight then
			element:SetPoint("LEFT", posX, 0)
		else
			element:SetPoint("RIGHT", - posX, 0)
		end
	end

	local function AdjustPanel(self)
		if self.KeepMaxSize then
			self.Width = self.ColumnCount * self.ElementWidth + (self.ColumnCount - 1) * self.HSpacing + self.MarginLeft + self.MarginRight
			self.Height = self.RowCount * self.ElementHeight + (self.RowCount - 1) * self.VSpacing + self.MarginTop + self.MarginBottom
		elseif self.AutoSize then
			local i = self.Count

			while i > 0 do
				if self:GetChild(self.ElementPrefix .. i).Visible then
					break
				end
				i = i - 1
			end

			local row
			local column

			if self.Orientation == Orientation.HORIZONTAL then
				row = ceil(i / self.ColumnCount)
				column = row == 1 and i or self.ColumnCount
			else
				column = ceil(i / self.RowCount)
				row = column == 1 and i or self.RowCount
			end

			self.Width = column * self.ElementWidth + (column - 1) * self.HSpacing + self.MarginLeft + self.MarginRight
			self.Height = row * self.ElementHeight + (row - 1) * self.VSpacing + self.MarginTop + self.MarginBottom
		end
	end

	local function Reduce(self, index)
		index = index or self.RowCount * self.ColumnCount

		if index < self.Count then
			local ele

			for i = self.Count, index + 1, -1 do
				ele = self:GetChild(self.ElementPrefix .. i)
				self:Fire("OnElementRemove", ele)
				ele:Dispose()

				self.__ElementPanel_Count = i - 1
			end

			AdjustPanel(self)
		end
	end

	local function Generate(self, index)
		if self.ElementType and index > self.Count then
			local ele

			for i = self.Count + 1, index do
				ele = self.ElementType(self.ElementPrefix .. i, self)
				ele.ID = i

				AdjustElement(ele, self)

				self:Fire("OnElementAdd", ele)

				self.__ElementPanel_Count = i
			end

			AdjustPanel(self)
		end
	end

	local function nextItem(self, index)
		index = index + 1
		if self:GetChild(self.ElementPrefix .. index) then
			return index, self:GetChild(self.ElementPrefix .. index)
		end
	end

	local function RefreshAll(self)
		Reduce(self)
		self:Each(AdjustElement, self)
	end

	local function RefreshElement(self)
		self:Each(AdjustElement, self)
	end

	__Doc__[[Element is an accessor to the IFElementPanel's elements, used like object.Element[i].Prop = value]]
	class "Element"

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
	    function Element(self, elementPanel)
			self.__ElementPanel = elementPanel
	    end

		------------------------------------------------------
		-- __index
		------------------------------------------------------
		function __index(self, index)
			self = self.__ElementPanel

			if type(index) == "number" and index >= 1 and index <= self.ColumnCount * self.RowCount then
				index = floor(index)

				if self:GetChild(self.ElementPrefix .. index) then return self:GetChild(self.ElementPrefix .. index) end

				if self.ElementType then
					Generate(self, index)

					return self:GetChild(self.ElementPrefix .. index)
				else
					return nil
				end
			end
		end
	endclass "Element"

	------------------------------------------------------
	-- Event
	------------------------------------------------------
	__Doc__[[
		<desc>Fired when an element is added</desc>
		<param name="element">System.Widget.Region, the new element that added to the panel</param>
	]]
	event "OnElementAdd"

	__Doc__[[
		<desc>Fired when an element is removed</desc>
		<param name="element">System.Widget.Region, the new element that removed from the panel</param>
	]]
	event "OnElementRemove"

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	function GetIterator(self, key)
		return nextItem, self, tonumber(key) or 0
	end

	function Each(self, ...)
		IList.Each(self, ...)

		return AdjustPanel(self)
	end

	__Doc__[[Update the panel size manually]]
	function UpdatePanelSize(self)
		local autoSize = self.AutoSize
		self.AutoSize = true
		AdjustPanel(self)
		self.AutoSize = autoSize
	end

	------------------------------------------------------
	-- Property
	------------------------------------------------------
	__Doc__[[The columns's count]]
	__Handler__( RefreshAll )
	property "ColumnCount" { Type = PositiveNumber, Default = 99 }

	__Doc__[[The row's count]]
	__Handler__( RefreshAll )
	property "RowCount" { Type = PositiveNumber, Default = 99 }

	__Doc__[[The elements's max count]]
	property "MaxCount" { Get = function(self) return self.ColumnCount * self.RowCount end }

	__Doc__[[The element's width]]
	__Handler__( RefreshElement )
	property "ElementWidth" { Type = PositiveNumber, Default = 16 }

	__Doc__[[The element's height]]
	__Handler__( RefreshElement )
	property "ElementHeight" { Type = PositiveNumber, Default = 16 }

	__Doc__[[The element's count]]
	property "Count" {
		Field = "__ElementPanel_Count",
		Set = function(self, cnt)
			if cnt > self.RowCount * self.ColumnCount then
				error("Count can't be more than "..self.RowCount * self.ColumnCount, 2)
			end

			if cnt > self.Count then
				if self.ElementType then
					Generate(self, cnt)
				else
					error("ElementType not set.", 2)
				end
			elseif cnt < self.Count then
				Reduce(self, cnt)
			end
		end,
		Type = NaturalNumber,
	}

	__Doc__[[The orientation for elements]]
	__Handler__( RefreshElement )
	property "Orientation" { Type = Orientation, Default = Orientation.HORIZONTAL }

	__Doc__[[Whether the elements start from left to right]]
	__Handler__( RefreshElement )
	property "LeftToRight" { Type = Boolean, Default = true }

	__Doc__[[Whether the elements start from top to bottom]]
	__Handler__( RefreshElement )
	property "TopToBottom" { Type = Boolean, Default = true }

	__Doc__[[The element's type]]
	property "ElementType" { Type = Class }

	__Doc__[[The horizontal spacing]]
	__Handler__( RefreshElement )
	property "HSpacing" { Type = NaturalNumber }

	__Doc__[[The vertical spacing]]
	__Handler__( RefreshElement )
	property "VSpacing" { Type = NaturalNumber }

	__Doc__[[Whether the elementPanel is autosize]]
	property "AutoSize" { Type = Boolean }

	__Doc__[[The top margin]]
	__Handler__( AdjustPanel )
	property "MarginTop" { Type = NaturalNumber }

	__Doc__[[The bottom margin]]
	__Handler__( AdjustPanel )
	property "MarginBottom" { Type = NaturalNumber }

	__Doc__[[The left margin]]
	__Handler__( AdjustPanel )
	property "MarginLeft" { Type = NaturalNumber }

	__Doc__[[The right margin]]
	__Handler__( AdjustPanel )
	property "MarginRight" { Type = NaturalNumber }

	__Doc__[[The Element accessor, used like obj.Element[i].]]
	property "Element" {
		Get = function(self)
			self.__ElementPanel_Element = self.__ElementPanel_Element or Element(self)
			return self.__ElementPanel_Element
		end,
	}

	__Doc__[[The prefix for the element's name]]
	property "ElementPrefix" { Type = String, Default = "Element" }

	__Doc__[[Whether the elementPanel should keep it's max size]]
	__Handler__( AdjustPanel )
	property "KeepMaxSize" { Type = Boolean }

	------------------------------------------------------
	-- Initialize
	------------------------------------------------------
endinterface "IFElementPanel"