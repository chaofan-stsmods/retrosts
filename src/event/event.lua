-- event
---@diagnostic disable: lowercase-global

---@type Event
currentEvent=nil
function event()
	if currentEvent then
		currentEvent:tick()
	else
		cls(0)
	end
	tickEffects()
	tickTopBar(true)
end

function eventBelow()
	if currentEvent then
		currentEvent:tickBelow()
	else
		cls(0)
	end
end

local function getCommonAndOneTimeEvents()
	local result = {}
	for _, event in ipairs(commonEvents) do
		if event:isAvailable() then
			table.insert(result,event)
		end
	end
	for _, event in ipairs(oneTimeEvents) do
		if event:isAvailable() then
			table.insert(result,event)
		end
	end
	return result
end

local function getActEvents()
	local result = {}
	for _, event in ipairs(actEvents) do
		if event:isAvailable() then
			table.insert(result,event)
		end
	end
	return result
end

function rollEventType(random)
	local list
	if random:rand() < 0.25 then
		list = getCommonAndOneTimeEvents()
		if #list == 0 then
			list = getActEvents()
		end
	else
		list = getActEvents()
		if #list == 0 then
			list = getCommonAndOneTimeEvents()
		end
	end

	local eventType = list[random:randInt(#list)]
	local function isNotThisEvent(e) return e ~= eventType end
	table.retainIf(actEvents,isNotThisEvent)
	table.retainIf(commonEvents,isNotThisEvent)
	table.retainIf(oneTimeEvents,isNotThisEvent)
	return eventType
end

-- event generator

local monsterChance = 10
local shopChance = 3
local treasureChance = 2
function resetEventGenerator()
	monsterChance = 10
	shopChance = 3
	treasureChance = 2
end

function saveEventGenerator(index)
	pmem(index, monsterChance | (shopChance << 8) | (treasureChance << 16))
end

function loadEventGenerator(index)
	local val32 = pmem(index)
	monsterChance = val32 & 0xff
	shopChance = (val32 >> 8) & 0xff
	treasureChance = (val32 >> 16) & 0xff
end

function generateEventRoomType(random)
	local roll = random:randInt(0,99)
	local result = nil
	trace('generateEventRoomType '..roll..' chances:'..table.concat({monsterChance,shopChance,treasureChance},','))
	if roll < monsterChance then
		monsterChance = 10
		result = 'monster'
	else
		roll = roll - monsterChance
		monsterChance = monsterChance + 10
	end

	if roll < shopChance and result == nil then
		shopChance = 3
		result = 'shop'
	else
		roll = roll - shopChance
		shopChance = shopChance + 3
	end

	if roll < treasureChance and result == nil then
		treasureChance = 2
		result = 'treasure'
	else
		roll = roll - treasureChance
		treasureChance = treasureChance + 2
	end

	result = result or 'event'
	result = player:triggerReducerEvent('modifyEventRoomType',result)

	trace('generateEventRoomType result: '..result..' chances:'..table.concat({monsterChance,shopChance,treasureChance},','))
	return result
end

-- event instance

---@class Event : Object
Event = {
	spriteBank=nil,options={},selectedOption=0,canOperatePotion=true,
	onOption=noop,init=noop,drawForeground=noop,onCombatEnd=noop,load=noop,
}
Object:new(Event)

function Event:new(o)
	o = o or {}
	o.options = o.options or {}
	local r = Object.new(self,o)
	r:init()
	return r
end

function Event:isAvailable()
	return true
end

function Event:drawBackground(below)
	cls(0)
end

function Event:drawOptions()
	local x = 8
	local y = 136-10*#self.options-16
	for i, option in ipairs(self.options) do
		if self.selectedOption == i then
			mapColor(15,14)
			mapColor(14,13)
			mapColor(13,12)
		end
		if option.locked then
			mapColor(15,0)
			mapColor(14,15)
			mapColor(13,14)
		end
		self:drawOptionButton(x,y+i*10,28)
		clip(x+4,y+i*10,216,8)
		local xOffset = 0
		if option.strWidth and option.strWidth > 216 then
			local d = option.strWidth - 216
			local f = 2
			local p = ((option.timer or 0) + 1) % (2 * d * f + 60)
			option.timer = p
			xOffset = p<30 and 0 or (p-30<d*f and (-p+30)/f or (p<60+d*f and -d or (p-60-2*d*f)/f))
		end
		option.strWidth = printColorStr(option.description,x+4+xOffset,y+i*10+1,true,12,option.locked and 13 or nil)
		clip()
		if self.selectedOption == i or option.locked then
			resetColors{13,14,15}
		end
	end
	local selectedOption = self.options[self.selectedOption]
	if selectedOption then
		if selectedOption.cardItem then
			local cardItem = selectedOption.cardItem
			local cardY = y+self.selectedOption*10-28
			cardItem.x,cardItem.tx = 210,210
			cardItem.y,cardItem.ty = cardY,cardY
			cardItem.large = true
			cardItem.isNotInHand = true
			cardItem:tick()
		end
		if selectedOption.item then
			local itemX = selectedOption.cardItem and 102 or 158
			drawItemTooltip(selectedOption.item,itemX,y+self.selectedOption*10,10,true)
		end
	end
end

function Event:drawOptionButton(x,y,width)
	spr(12,x,y,0)
	rect(x+8,y,width*8-16,1,13)
	rect(x+8,y+1,width*8-16,6,14)
	rect(x+8,y+7,width*8-16,1,15)
	spr(12,x+width*8-8,y,0,1,1)
end

function Event:tick()
	self:drawBackground()
	self:drawOptions()
	self:eventControls()
end

function Event:tickBelow()
	self:drawBackground(true)
end

function Event:eventControls()
	if cursorOnTopBar then
		self.selectedOption = 0
		return
	end

	local function validOption(i) return not self.options[i].locked end
	if self.selectedOption == 0 or self.selectedOption > #self.options then
		self.selectedOption = nextOrOtherIndexInTableIf(self.options,self.selectedOption,validOption)
	end

	if btnp(0) then
		self.selectedOption = previousOrOtherIndexInTableIf(self.options,self.selectedOption,validOption)
	elseif btnp(1) then
		self.selectedOption = nextOrOtherIndexInTableIf(self.options,self.selectedOption,validOption)
	elseif btnp(4) then
		self:onOption(self.selectedOption)
	end
end

-- text event

TextEvent = Event:new{name='',description='',spriteBank=0}

function TextEvent:drawBackground(below)
	if below then
		cls(15)
	else
		cls(13)
	end
	mapColor(14,0)
	drawTooltipBox(4,28,29,13)
	resetColors{14}
	spr(396,1,20,0,1,0,0,2,2)
	rect(17,20,120,11,4)
	rect(17,31,120,1,3)
	spr(398,137,20,0,1,0,0,2,2)
	if below then
		printGlowed(self.name,78-strWidth(self.name)/2,23,14,0)
		drawDescription(nil,self.description,9,36,222,999,14)
	else
		printGlowed(self.name,78-strWidth(self.name)/2,23,12,15)
		drawDescription(nil,self.description,9,36,222,999,12)
	end
end

-- combat text event

CombatTextEvent = Event:new{description=''}
function CombatTextEvent:drawBackground(below)
	act:drawBackground()
	self:drawForeground(below)
	if below then
		drawDescription(nil,self.description,9,20,222,999,14)
	else
		drawDescription(nil,self.description,9,20,222,999,12)
	end
end
