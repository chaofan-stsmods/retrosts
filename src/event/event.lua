-- event
---@diagnostic disable: lowercase-global

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

-- event generator

local monsterChance = 0.1
local shopChance = 0.03
local treasureChance = 0.02
function resetEventGenerator()
	monsterChance = 0.1
	shopChance = 0.03
	treasureChance = 0.02
end

function generateEventRoomType(random)
	local roll = random:rand()
	if roll < monsterChance then
		monsterChance = 0.1
		return 'monster'
	else
		monsterChance = monsterChance + 0.1
		roll = roll - monsterChance
	end

	if roll < shopChance then
		shopChance = 0.03
		return 'shop'
	else
		shopChance = shopChance + 0.03
		roll = roll - shopChance
	end

	if roll < treasureChance then
		treasureChance = 0.02
		return 'treasure'
	else
		treasureChance = treasureChance + 0.02
		roll = roll - treasureChance
	end

	return 'event'
end


-- event instance

Event = Object:new{
	spritebank=nil,options={},selectedOption=0,
	onOption=noop,init=noop
}
function Event:new(o)
	o = o or {}
	o.options = o.options or {}
	local r = Object.new(self,o)
	r:init()
	return r
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
		printColorStr(option.description,x+4,y+i*10+1,true,12,option.locked and 13 or nil)
		if self.selectedOption == i or option.locked then
			resetColors{13,14,15}
		end
	end
end

function Event:drawOptionButton(x,y,width)
	spr(12,x,y,0)
	for i=2,width-1 do
		spr(13,x+i*8-8,y,0)
	end
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
	if self.selectedOption == 0 then
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

TextEvent = Event:new{name='',description='',spritebank=0}

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
