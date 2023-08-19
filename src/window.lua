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
		trace(self.name..'('..tostring(self)..'):onOpen '..str)
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
		closeWindowsIf(function (w) return getmetatable(w) == getmetatable(targetWindow) end)
	end
	nearestWindow:open(targetWindow,onClose)
end

function findWindow(windowType)
	local w = window
	while w ~= nil do
		if windowType == getmetatable(w) then
			return w
		end
		w = w.child
	end
end

function closeWindowsIf(condition,output)
	local w = window
	while w ~= nil do
		if condition(w) then
			w:close(output)
		end
		w = w.child
	end
end

function closeChildWindows(output)
	local w = window.child
	if w == nil then
		window:onOpen()
	end
	while w ~= nil do
		w:close(output)
		w = w.child
	end
end

-- instance
TitleSelectionWindow = Window:new{selection=1,options={},onOption=noop}
function TitleSelectionWindow:onOpen()
	queueSync(1,0)
end

function TitleSelectionWindow:tick()
	if btnp(0) then
		self.selection = limit(self.selection-1,1,#self.options)
	elseif btnp(1) then
		self.selection = limit(self.selection+1,1,#self.options)
	end

	if btnp(4) then
		self:onOption(self.selection)
	elseif btnp(5) then
		self:close()
	end

	map(0,51,30,17,0,0)
	local startY = 128-#self.options*8
	for i=1,#self.options do
		local color = i == self.selection and 4 or 12
		printShadowed(self.options[i],10,startY,color)
		startY = startY + 8
	end
end

TitleWindow = TitleSelectionWindow:new{options={'New Game','Card List','Exit'},name='TitleWindow'}
function TitleWindow:new(o)
	o = o or {}
	if hasSave() then
		o.options = {'Continue','New Game','Card List','Exit'}
	end
	return TitleSelectionWindow.new(self,o)
end

function TitleWindow:onOption()
	if self.selection == #self.options then
		exit()
	elseif self.options[self.selection] == 'Card List' then
		self:open(CardListWindow:new())
	elseif self.options[self.selection] == 'Continue' then
		loadGame()
	elseif self.options[self.selection] == 'New Game' then
		self:open(CharacterSelectWindow:new())
	end
end

CharacterSelectWindow = TitleSelectionWindow:new{selection=1,options=nil,ascension=0,name='CharacterSelectWindow'}
local ascensionEffects = {
	'Elites spawn more often',
	'Normal enemies are deadlier',
	'Elites are deadlier',
	'Bosses are deadlier',
	'Heal less after Boss battles',
	'Start each run damaged',
	'Normal enemies are tougher',
	'Elites are tougher',
	'Bosses are tougher',
	'Start each run cursed',
	'Fewer Potion Slots',
	'Upgraded cards appear less often',
	'Poor bosses',
	'Lower Max HP',
	'Unfavorable Events',
	'Shops are more costly',
	'Normal enemies are more challenging',
	'Elites are more challenging',
	'Bosses are more challenging',
	'Double Boss',
}
function CharacterSelectWindow:new(o)
	o = o or {}
	o.options = table.map(characters,function(c) return c.name end)
	return TitleSelectionWindow.new(self,o)
end

function CharacterSelectWindow:tick()
	TitleSelectionWindow.tick(self)

	local ascensionY = 8
	printShadowed('Ascension Level',120-strWidth('Ascension Level')/2,ascensionY,12)
	printShadowed(tostring(self.ascension),120-strWidth(tostring(self.ascension))/2,ascensionY+8,12)

	if self.ascension < 20 then
		tri(132-3,ascensionY+9,132-3,ascensionY+15,132+3,ascensionY+12,15)
		tri(131-3,ascensionY+8,131-3,ascensionY+14,131+3,ascensionY+11,4)
	end

	if self.ascension > 0 then
		tri(109+3,ascensionY+9,109+3,ascensionY+15,109-3,ascensionY+12,15)
		tri(108+3,ascensionY+8,108+3,ascensionY+14,108-3,ascensionY+11,4)
		printShadowed(tostring(ascensionEffects[self.ascension]),120-strWidth(tostring(ascensionEffects[self.ascension]))/2,ascensionY+16,12)
	end

	if btnp(2) then
		self.ascension = limit(self.ascension-1,0,20)
	elseif btnp(3) then
		self.ascension = limit(self.ascension+1,0,20)
	end
end

function CharacterSelectWindow:onOption()
	startGame(characters[self.selection],self.ascension)
end

CardListWindow = Window:new{name='CardListWindow',gridUI=nil,cardItems=nil}
local rarityPriority = {basic=0,special=1,common=2,uncommon=3,rare=4}
local colorPriority = {red=0,colorless=10,curse=11}
function CardListWindow:new()
	local cardItems = {}
	for _,cardType in ipairs(Ironclad:getCards()) do
		table.insert(cardItems,CardItem:new{card=cardType:new(),isNotInHand=true})
	end
	for _,cardType in ipairs(getColorlessCards()) do
		table.insert(cardItems,CardItem:new{card=cardType:new(),isNotInHand=true})
	end
	for _,cardType in ipairs(getCurseCards()) do
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
	queueSync(1,1)
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
	queueSync(1,player.tileBank)
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
		queueSync(1,player.tileBank)
		if roomActionType == 'combat' or roomActionType == 'eventCombat' then
			queueSync(2,combatSpriteBank)
		elseif roomActionType == 'event' and currentEvent ~= nil then
			queueSync(2,currentEvent.spriteBank)
		end
	end
end

function GameWindow:tick()
	if roomActionType == 'combat' or roomActionType == 'eventCombat' then
		combat()
	elseif roomActionType == 'event' and currentEvent ~= nil then
		event()
	end
end

function GameWindow:tickBelow()
	if roomActionType == 'combat' then
		darkenColors()
		act:drawBackground()
		player:drawImage()
		for _, enemy in ipairs(enemies) do
			if enemy.visible then
				enemy:drawImage()
			end
		end
		resetColors()
	else
		darkenColors()
		eventBelow()
		resetColors()
	end
end
