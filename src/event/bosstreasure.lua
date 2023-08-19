-- boss treasure
---@diagnostic disable: lowercase-global

BossTreasureEvent = Event:new{screen='entry',spriteBank=2,random=nil,relics=nil,relicOption=1,opened=false}
function BossTreasureEvent:init()
	self.random = self.random or makeRand(act.id,room.id,1)
	table.insert(self.options,{description='[Open]'})
	table.insert(self.options,{description='[Proceed]'})
	self.relics = {}
	for i = 1, 3 do
		self.relics[i] = getRelicTypeByTier('boss'):new()
	end
end

local relicLocations = {
	{116,34},
	{101,51},
	{131,51},
}
function BossTreasureEvent:drawBackground()
	if self.opened then
		darkenColors()
		act:drawBackground()
		resetColors()
		player:drawImage()
		sprmap(4,34,5,4,160,56,0)
		drawTalkBubble('',85,20,70,51,167,73,7)
		drawBanner(56,18,16)
		local title = 'Choose a Relic'
		local width = strWidth(title)
		printGlowed(title,120-width/2,21,12)
		for i = 1, 3 do
			mapColors(0,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15)
			self.relics[i]:drawImage(relicLocations[i][1]+1,relicLocations[i][2]+1)
			resetColors()
			self.relics[i]:drawImage(relicLocations[i][1],relicLocations[i][2])
			if i == self.relicOption then
				drawSelectionBox(relicLocations[i][1]-2,relicLocations[i][2]-2,12,12)
			end
		end
	else
		act:drawBackground()
		player:drawImage()
		sprmap(4,34,5,4,160,56,0)
	end
end

function BossTreasureEvent:onOption(selection)
	if self.screen == 'entry' then
		if selection == 1 then
			self.opened = true
		elseif selection == 2 then
			self:proceed()
		end
	else
		self:proceed()
	end
end

function BossTreasureEvent:proceed()
	startAct(act.id+1)
	room.completed = true
	prepareMapSelection()
	openWindowAbove(MapWindow:new{canClose=false})
end

function BossTreasureEvent:drawOptions()
	if not self.opened then
		Event.drawOptions(self)
	end
end

function BossTreasureEvent:eventControls()
	if not self.opened then
		Event.eventControls(self)
	else
		if btnp(0) then
			self.relicOption = 1
		elseif btnp(1) then
			self.relicOption = limit(self.relicOption+1,1,3)
		elseif btnp(2) then
			self.relicOption = 2
		elseif btnp(3) then
			self.relicOption = 3
		elseif btnp(4) then
			obtainRelic(self.relics[self.relicOption])
			self.opened = false
			self.screen = 'leave'
			self.options = {self.options[2]}
		elseif btnp(5) or btnp(7) then
			self.opened = false
		end
	end
end
