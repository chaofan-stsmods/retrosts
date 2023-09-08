-- window
---@diagnostic disable: lowercase-global

---@type Window
window = nil
---@type Window
nearestWindow = nil

---@class Window : Object
---@field child Window?
---@field parent Window?
---@field onClose fun(output: any): nil
Window = {child=nil,parent=nil,tick=noop,tickBelow=noop,name='',onOpen=noop,single=true}
Object:new(Window)

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

TitleWindow = TitleSelectionWindow:new{options={'New Game','Card List','Relic Collection','Potion Lab'},name='TitleWindow'}
function TitleWindow:new(o)
	o = o or {}
	if hasSave() then
		o.options = {'Continue','New Game','Card List','Relic Collection','Potion Lab'}
	end
	return TitleSelectionWindow.new(self,o)
end

function TitleWindow:onOption()
	if self.options[self.selection] == 'Card List' then
		self:open(CardListWindow:new())
	elseif self.options[self.selection] == 'Relic Collection' then
		self:open(RelicCollectionWindow:new())
	elseif self.options[self.selection] == 'Potion Lab' then
		self:open(PotionLabWindow:new())
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

CardListWindow = Window:new{name='CardListWindow',gridUI=nil,allCardItems=nil,tileBanks=nil,cardItemsIndex=1}
local rarityPriority = {basic=0,special=1,common=2,uncommon=3,rare=4}
function CardListWindow:new()
	local allCardItems = {}
	local tileBanks = {}
	local cardItems
	for _,character in ipairs(characters) do
		cardItems = {}
		for _,cardType in ipairs(character:getCards()) do
			table.insert(cardItems,CardItem:new{card=cardType:new(),isNotInHand=true})
		end
		table.insert(allCardItems,cardItems)
		table.insert(tileBanks,character.tileBank)
	end
	cardItems = {}
	for _,cardType in ipairs(getColorlessCards()) do
		table.insert(cardItems,CardItem:new{card=cardType:new(),isNotInHand=true})
	end
	table.insert(allCardItems,cardItems)
	table.insert(tileBanks,1)
	cardItems = {}
	for _,cardType in ipairs(getCurseCards()) do
		table.insert(cardItems,CardItem:new{card=cardType:new(),isNotInHand=true})
	end
	table.insert(allCardItems,cardItems)
	table.insert(tileBanks,1)
	for _,cardItems in ipairs(allCardItems) do
		table.sort(cardItems,function (a, b)
			if a.card.rarity == b.card.rarity then
				return a.card.name < b.card.name
			else
				return rarityPriority[a.card.rarity] < rarityPriority[b.card.rarity]
			end
		end)
	end
	local gridUI = CardGridUI:new(allCardItems[1])
	local r = Window.new(self,{gridUI=gridUI,allCardItems=allCardItems,tileBanks=tileBanks})
	gridUI.cursorOnSelf = true
	gridUI.onSelect = function (selection)
		r:gridUISelect(selection)
	end
	return r
end

function CardListWindow:onOpen()
	queueSync(1,self.tileBanks[self.cardItemsIndex] or 1)
end

function CardListWindow:tick()
	cls(0)
	self.gridUI:tick()
	if btnp(6) then
		if self.cardItemsIndex > 1 then
			self.cardItemsIndex = self.cardItemsIndex - 1
			self.gridUI.cardItems = self.allCardItems[self.cardItemsIndex]
			self.gridUI.selection = 1
			self.gridUI:scrollToSelection()
			queueSync(1,self.tileBanks[self.cardItemsIndex] or 1)
		end
	elseif btnp(7) then
		if self.cardItemsIndex < #self.allCardItems then
			self.cardItemsIndex = self.cardItemsIndex + 1
			self.gridUI.cardItems = self.allCardItems[self.cardItemsIndex]
			self.gridUI.selection = 1
			self.gridUI:scrollToSelection()
			queueSync(1,self.tileBanks[self.cardItemsIndex] or 1)
		end
	elseif btnp(5) then
		self:close()
	end
end

function CardListWindow:gridUISelect(selection)
	local cardItem = self.gridUI.cardItems[selection]
	if cardItem.card.upgraded then
		cardItem.card = getmetatable(cardItem.card):new()
	else
		cardItem.card:upgrade()
		cardItem.card:showUpgrade()
	end
end

ItemCollectionWindow = Window:new{name='RelicCollectionWindow',scrollY=0,targetScrollY=0,items=nil,poolSelection=0,itemSelection=1}
local itemPoolNames = {'basic','common','uncommon','rare','boss','shop','special'}
local itemPoolDisplayNames = {basic='Starter',special='Event'}
function ItemCollectionWindow:new(items)
	return Window.new(self,{items=items})
end

function ItemCollectionWindow:onOpen()
	queueSync(1,1)
end

function ItemCollectionWindow:tick()
	cls(0)
	local y = math.floor(-self.scrollY)
	local sx = 20
	for pi,poolName in ipairs(itemPoolNames) do
		local pool = self.items[poolName]
		if pool then
			local x = sx
			printShadowed(itemPoolDisplayNames[poolName] or poolName:sub(1,1):upper()..poolName:sub(2),x,y+2,4)
			y = y + 12
			for ri,relic in ipairs(pool) do
				relic:drawImage(x,y,true)
				if pi == self.poolSelection and ri == self.itemSelection then
					drawSelectionBox(x-2,y-2,12,12)
					drawItemTooltip(relic,sx+120+2,2)
					self.targetScrollY = y+self.scrollY-68
				end
				x = x + 12
				if x - sx >= 120 then
					x = sx
					y = y + 12
				end
			end
			if x > sx then
				y = y + 12
			end
		end
	end

	self.scrollY = limit(lerp(self.scrollY,self.targetScrollY,0.2),-2,y+self.scrollY-134)

	if self.poolSelection == 0 then
		repeat
			self.poolSelection = self.poolSelection + 1
		until self.poolSelection > #itemPoolNames or (self.items[itemPoolNames[self.poolSelection]] and #self.items[itemPoolNames[self.poolSelection]] > 0)
		if self.poolSelection > #itemPoolNames then
			self.poolSelection = 0
		end
	end

	if btnp(0) then
		if self.itemSelection > 10 then
			self.itemSelection = self.itemSelection - 10
		else
			local oldPoolSelection = self.poolSelection
			repeat
				self.poolSelection = self.poolSelection - 1
			until self.poolSelection == 0 or (self.items[itemPoolNames[self.poolSelection]] and #self.items[itemPoolNames[self.poolSelection]] > 0)
			if self.poolSelection == 0 then
				self.poolSelection = oldPoolSelection
			else
				local relicCount = #self.items[itemPoolNames[self.poolSelection]]
				self.itemSelection = limit(math.floor((relicCount-1)/10)*10+self.itemSelection,1,relicCount)
			end
		end
	elseif btnp(1) then
		if self.itemSelection <= #self.items[itemPoolNames[self.poolSelection]] - 10 then
			self.itemSelection = self.itemSelection + 10
		else
			local oldPoolSelection = self.poolSelection
			repeat
				self.poolSelection = self.poolSelection + 1
			until self.poolSelection > #itemPoolNames or (self.items[itemPoolNames[self.poolSelection]] and #self.items[itemPoolNames[self.poolSelection]] > 0)
			if self.poolSelection > #itemPoolNames then
				self.poolSelection = oldPoolSelection
			else
				self.itemSelection = limit((self.itemSelection-1)%10+1,1,#self.items[itemPoolNames[self.poolSelection]])
			end
		end
	elseif btnp(2) then
		if self.itemSelection > 1 then
			self.itemSelection = self.itemSelection - 1
		end
	elseif btnp(3) then
		if self.itemSelection < #self.items[itemPoolNames[self.poolSelection]] then
			self.itemSelection = self.itemSelection + 1
		end
	elseif btnp(5) then
		self:close()
	end
end

RelicCollectionWindow = ItemCollectionWindow:new{name='RelicCollectionWindow'}
function RelicCollectionWindow:new()
	local relics = {}
	for _,character in ipairs(characters) do
		for _,relicType in ipairs(character:getRelics()) do
			table.insert(relics,relicType:new())
		end
	end
	for _,relicType in ipairs(getColorlessRelics()) do
		if relicType ~= Circlet then
			table.insert(relics,relicType:new())
		end
	end

	table.sort(relics,function(a,b) return a.name < b.name end)

	local relicWithPools = {}
	for _, relicType in ipairs(relics) do
		local pool = relicWithPools[relicType.tier]
		if not pool then
			pool = {}
			relicWithPools[relicType.tier] = pool
		end
		table.insert(pool,relicType)
	end

	return ItemCollectionWindow.new(self,relicWithPools)
end

PotionLabWindow = ItemCollectionWindow:new{name='PotionLabWindow'}
function PotionLabWindow:new()
	local potions = {}
	for _,character in ipairs(characters) do
		for _,potionType in ipairs(character:getPotions()) do
			table.insert(potions,potionType:new())
		end
	end
	for _,potionType in ipairs(getAllPotions()) do
		table.insert(potions,potionType:new())
	end

	table.sort(potions,function(a,b) return a.name < b.name end)

	local potionWithPools = {}
	for _, potionType in ipairs(potions) do
		local pool = potionWithPools[potionType.rarity]
		if not pool then
			pool = {}
			potionWithPools[potionType.rarity] = pool
		end
		table.insert(pool,potionType)
	end

	return ItemCollectionWindow.new(self,potionWithPools)
end

LoseWindow = Window:new{name='LoseWindow',title='You Lose!'}
function LoseWindow:onOpen()
	queueSync(1,5)
end

function LoseWindow:tick()
	darkenColors()
	act:drawBackground()
	resetColors()
	player:drawCorpse()
	for _,enemy in ipairs(enemies) do
		if enemy.visible then
			enemy:drawImage()
		end
	end
	tickEffects()
	tickTopBar(false)
	drawBanner(56,18,16)
	printGlowed(self.title,120-strWidth(self.title)/2,21,12)
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
	if roomActionType == 'combat' or roomActionType == 'eventCombat' then
		darkenColors()
		act:drawBackground()
		if player.visible then
			player:drawImage()
		end
		for _, enemy in ipairs(enemies) do
			if enemy.visible then
				enemy:drawImage()
				enemy:drawIntent()
			end
		end
		resetColors()
	else
		darkenColors()
		eventBelow()
		resetColors()
	end
end

VictoryWindow = Window:new{name='LoseWindow',title='Victory!'}
function VictoryWindow:tick()
	darkenColors()
	currentEvent:tick()
	resetColors()
	tickEffects()
	tickTopBar(false)
	drawBanner(56,18,16)
	printGlowed(self.title,120-strWidth(self.title)/2,21,12)
	if btnp(4) or btnp(5) then
		switchWindow(TitleWindow:new())
	end
end
