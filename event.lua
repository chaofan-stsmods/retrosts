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

function openEventScreen(event)
	currentEvent = event or currentEvent
	transferScreen('event')
	if currentEvent and currentEvent.spritebank then
		queueSync(2,currentEvent.spritebank)
	end
end

-- event instance

Event = Object:new{
	spritebank=nil,options={},selectedOption=0,
	onOption=noop
}
function Event:new(o)
	o = o or {}
	o.options = o.options or {}
	return Object.new(self,o)
end

function Event:drawBackground()
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
		printColorStr(option.description,x+4,y+i*10+1,true,option.locked and 13 or nil)
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

NeowEvent = Event:new{screen='entry',spritebank=0}
function NeowEvent:new(random)
	local o = Event.new(self)
	table.insert(o.options,{description='[ Obtain a card. ]'})
	table.insert(o.options,{description='[ Obtain a common relic. ]'})
	table.insert(o.options,{description='[ #3#Lose 25 HP. #5#Increase max HP by 14. #12#]'})
	table.insert(o.options,{description='[ #3#Lose starting relic. #5#Obtain a random boss relic. #12#]'})
	return o
end

function NeowEvent:drawBackground()
	map(30,0,30,17,0,0)
	player:drawImage()
	sprmap(16,34,13,10,136,16)
end

function NeowEvent:onOption()
	if self.screen == 'entry' then
		self.screen = 'exit'
		self.options = {}
		table.insert(self.options,{description='[Leave]'})
	else
		completeRoom()
		transferScreen('mapScreen')
	end
end
