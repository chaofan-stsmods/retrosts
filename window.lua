-- window
---@diagnostic disable: lowercase-global

window = nil
nearestWindow = nil

Window = Object:new{child=nil,parent=nil,tick=noop,tickBelow=noop,name='',onOpen=noop,single=true}
function Window:windowTick()
	if self.child ~= nil then
		self:tickBelow()
		self.child:windowTick()
	else
		self:tick()
	end
end

function Window:onWindowOpen()
	if self.child ~= nil then
		self.child:onWindowOpen()
	else
		-- debug
		local str = '{'
		local w = window
		while w do
			str = str..w.name..','
			w = w.child
		end
		str = str:sub(1,#str-1)..'}'
		trace(self.name..':onOpen '..str)
		-- enddebug
		self:onOpen()
	end
end

function Window:open(childWindow,onClose)
	if self == nearestWindow then
		nearestWindow = childWindow
	end
	self.child = childWindow
	self.child.parent = self
	self.child.onClose = onClose
	childWindow:onWindowOpen()
end

function Window:close(output)
	if self.parent == nil then
		return
	end
	if self == nearestWindow then
		nearestWindow = self.parent
	end
	self.parent.child = self.child
	if self.child ~= nil then
		self.child.parent = self.parent
	end
	if self.onClose then
		self.onClose(output)
	end
	if self.parent.child == nil then
		self.parent:onWindowOpen()
	end
end

function switchWindow(targetWindow)
	window = targetWindow
	nearestWindow = window
	while nearestWindow.child do
		nearestWindow = nearestWindow.child
	end
	nearestWindow:onWindowOpen()
end

function openWindowAbove(targetWindow,onClose)
	if targetWindow.single then
		closeWindowsWithType(getmetatable(targetWindow))
	end
	nearestWindow:open(targetWindow,onClose)
end

function closeWindowsWithType(windowType,output)
	local w = window
	while w ~= nil do
		if getmetatable(w) == windowType then
			w:close(output)
		end
		w = w.child
	end
end

function closeChildWindows(output)
	local w = window.child
	while w ~= nil do
		w:close(output)
		w = w.child
	end
end

-- instance
TitleSelectionWindow = Window:new{selection=1,options={},onOption=noop}
function TitleSelectionWindow:onOpen()
	queueSync(1|4,0)
end

function TitleSelectionWindow:tick()
	if btnp(0) then
		self.selection = self.selection - 1
	elseif btnp(1) then
		self.selection = self.selection + 1
	end
	self.selection = limit(self.selection,1,#self.options)

	if btnp(4) then
		self:onOption(self.selection)
	elseif btnp(5) then
		self:close()
	end

	map(0,0,30,17,0,0)
	local startY = 128-#self.options*8
	for i=1,#self.options do
		local color = i == self.selection and 4 or 12
		printShadowed(self.options[i],10,startY,color)
		startY = startY + 8
	end
end

TitleWindow = TitleSelectionWindow:new{options={'New Game','Card List','Exit'},name='TitleWindow'}
function TitleWindow:onOption()
	if self.selection == #self.options then
		exit()
	elseif self.selection == 2 then
		self:open(CardListWindow:new())
	elseif self.selection == 1 then
		self:open(CharacterSelectWindow:new())
	end
end

CharacterSelectWindow = TitleSelectionWindow:new{selection=1,options={'Ironclad','Silent','Defect','Watcher'},name='CharacterSelectWindow'}
function CharacterSelectWindow:onOption()
	startGame(self.options[self.selection])
end

CardListWindow = Window:new{name='CardListWindow',gridUI=nil,cardItems=nil}
local rarityPriority = {basic=0,special=1,common=2,uncommon=3,rare=4}
local colorPriority = {red=0,colorless=10}
function CardListWindow:new()
	local cardItems = {}
	for _,cardType in ipairs(Ironclad:getCards()) do
		table.insert(cardItems,CardItem:new{card=cardType:new(),isNotInHand=true})
	end
	for _,cardType in ipairs(getColorlessCards()) do
		table.insert(cardItems,CardItem:new{card=cardType:new(),isNotInHand=true})
	end
	table.sort(cardItems,function (a, b)
		if a.card.rarity == b.card.rarity and a.card.colorName == b.card.colorName then
			return a.card.name < b.card.name
		elseif a.card.colorName == b.card.colorName then
			return rarityPriority[a.card.rarity] < rarityPriority[b.card.rarity]
		else
			return colorPriority[a.card.colorName] < colorPriority[b.card.colorName]
		end
	end)
	local gridUI = CardGridUI:new(cardItems)
	local r = Window.new(self,{gridUI=gridUI,cardItems=cardItems})
	gridUI.cursorOnSelf = true
	gridUI.onSelect = function (selection)
		r:gridUISelect(selection)
	end
	return r
end

function CardListWindow:onOpen()
	queueSync(1|4,1)
end

function CardListWindow:tick()
	cls(0)
	self.gridUI:tick()
	if btnp(5) then
		self:close()
	end
end

function CardListWindow:gridUISelect(selection)
	local cardItem = self.cardItems[selection]
	if cardItem.card.upgraded then
		cardItem.card = getmetatable(cardItem.card):new()
	else
		cardItem.card:upgrade()
		cardItem.card:showUpgrade()
	end
end

LoseWindow = Window:new{name='LoseWindow'}
function LoseWindow:onOpen()
	queueSync(1|4,1)
end

function LoseWindow:tick()
	cls(0)
	player:tick()
	for i=1,#enemies do
		enemies[i]:tick()
	end
	tickEffects()
	tickTopBar()
	local str = 'You Lose!'
	local strWidth = strWidth(str,false,false,3)
	printShadowed('You Lose!',120-strWidth/2,30,3,1,3)
	if btnp(4) or btnp(5) then
		switchWindow(TitleWindow:new())
	end
end

GameWindow = Window:new{name='GameWindow'}
function GameWindow:onOpen()
	if self.child == nil then
		queueSync(1|4,1)
		if roomType == 'combat' then
			queueSync(2,combatSpriteBank)
		elseif roomType == 'event' and currentEvent ~= nil then
			queueSync(2,currentEvent.spritebank)
		end
	end
end

function GameWindow:tick()
	if roomType == 'combat' then
		combat()
	elseif roomType == 'event' and currentEvent ~= nil then
		event()
	end
end

function GameWindow:tickBelow()
	if roomType == 'combat' then
		darkenColors()
		drawActBackground()
		player:drawImage()
		for _, enemy in ipairs(enemies) do
			if enemy.visible then
				enemy:drawImage()
			end
		end
		resetColors()
	else
		cls(0)
	end
end
