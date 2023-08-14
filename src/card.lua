-- card
---@diagnostic disable: lowercase-global

Card = Object:new{
	name='',description='',type='attack',rarity='common',
	color={2,1},costIcon=45,typeIconColor=4,colorName='',
	baseCost=0,cost=0,costForOneTurnPlay=nil,costForOnePlay=nil,
	damage=0,baseDamage=0,block=0,baseBlock=0,magic=0,baseMagic=0,multiDamage={},
	enemyTarget=false,playerTarget=false,toAllEnemies=false,
	exhaust=false,ethereal=false,innate=false,autoPlayOnEndTurn=false,
	upgrade=noop,upgraded=false,tags={},canGenerateInCombat=true,canRemove=true,
}
function Card:new(o)
	local r = Object.new(self,o)
	if type(r.upgrade) == 'table' then
		local upgradeTable = r.upgrade
		r.upgrade = function (self)
			self:upgradeValues(upgradeTable)
		end
	end
	if type(r.baseCanUse) == 'boolean' then
		local canUseValue = r.baseCanUse
		r.baseCanUse = function (self) return canUseValue end
	end
	if type(r.canUpgrade) == 'boolean' then
		local canUpgradeValue = r.canUpgrade
		r.canUpgrade = function (self) return canUpgradeValue end
	end
	r:resetPowers()
	return r
end

function Card:use(target,energyOnUse,free)
	return {}
end

function Card:baseCanUse(free)
	return self:getCost() <= energy or free
end

function Card:canUse(free)
	return player:triggerConditionEvent('canUseCard',self:baseCanUse(free),self) and not inEnemyTurn
end

function Card:getCost()
	if self.cost < 0 then
		return self.cost
	end
	return self.costForOneTurnPlay or self.costForOnePlay or self.cost
end

function Card:applyPowers(target)
	local damage = self.baseDamage

	damage = player:triggerReducerEvent('onAttack',damage,target,self)
	if self.toAllEnemies then
		self.multiDamage = {}
		local minDamage = 9999999
		local maxDamage = 0
		for i,enemy in ipairs(enemies) do
			if enemy.alive then
				local targetDamage = damage
				targetDamage = enemy:triggerReducerEvent('onAttacked',targetDamage,player,self)
				targetDamage = math.floor(targetDamage)
				self.multiDamage[i] = targetDamage
				minDamage = math.min(minDamage,targetDamage)
				maxDamage = math.max(maxDamage,targetDamage)
			else
				self.multiDamage[i] = 0
			end
		end
		if minDamage == maxDamage then
			damage = minDamage
		end
	elseif target ~= nil then
		damage = target:triggerReducerEvent('onAttacked',damage,player,self)
	end

	self.damage = math.floor(damage)

	local block = self.baseBlock
	block = player:triggerReducerEvent('onModifyBlock',block,self)
	self.block = math.floor(block)

	self.magic = self.baseMagic

	local cost = self.baseCost
	cost = player:triggerReducerEvent('onModifyCost',cost,self)
	self.cost = math.floor(cost)
end

function Card:resetPowers()
	self.damage = self.baseDamage
	self.block = self.baseBlock
	self.magic = self.baseMagic
	self.cost = self.baseCost
end

function Card:showUpgrade()
	self.damage,self.baseDamage = self.baseDamage,self.damage
	self.block,self.baseBlock = self.baseBlock,self.block
	self.magic,self.baseMagic = self.baseMagic,self.magic
	self.cost,self.baseCost = self.baseCost,self.cost
end

function Card:canUpgrade()
	return not self.upgraded
end

function Card:upgradeValues(o)
	if self.upgraded then
		return
	end
	for key, value in pairs(o) do
		self[key] = value
	end
	self.upgraded = true
	self.name = self.name .. '+'
end

function Card:triggerEvent(name,...)
	if self[name] then
		self[name](self,...)
	end
end

CardItem = Object:new{ x=0,y=136,tx=0,ty=136,card=nil,large=false,isNotInHand=false,showWhiteCost=false,glow=nil}
cardTypeToSprIndex = {attack=57,skill=58,power=59,status=55,curse=56}
cardRarityColor = {basic={14,15},common={14,15},special={14,15},uncommon={10,9},rare={4,3}}
function CardItem:tick()
	self.x = lerp(self.x,self.tx,0.2)
	self.y = lerp(self.y,self.ty,0.2)
	local l,t
	if self.large then
		l = self.x-28
		t = self.y-28
	else
		l = self.x-16
		t = self.y-20
	end
	if t < -60 or t > 140 then
		return
	end
	if self.glow ~= nil then
		rect(l-1,t,self.large and 58 or 34,self.large and 57 or 41,self.glow)
	end
	drawCardBack(self.card,self.large,l,t)
	drawCost(self.card,l,t,self.isNotInHand,self.showWhiteCost)
	drawTitle(self.card,self.large,l,t)
	drawDescription(self.card,self.card.description,l+3,t+10,self.large and 51 or 27,self.large and 999 or 3)
end

function drawCardBack(card,large,l,t)
	mapColor(14,card.color[1])
	mapColor(15,card.color[2])
	mapColor(3,card.typeIconColor)
	mapColor(10,cardRarityColor[card.rarity][1])
	mapColor(9,cardRarityColor[card.rarity][2])
	if large then
		rect(l+7,t+7,42,42,14)
		map(3,2,7,7,l,t,0)
		--spr(cardTypeToSprIndex[card.type],l+48,t,0)
	else
		rect(l+7,t+7,18,26,14)
		map(10,2,4,5,l,t,0)
	end
	local typeLeft = card.baseCost >= -1 and l+8 or l+1
	spr(29,typeLeft,t-6,0)
	spr(cardTypeToSprIndex[card.type],typeLeft,t-6,0)
	resetColors{3,9,10,14,15}
end

function drawCost(card,l,t,isNotInHand,showWhiteCost)
	t = t-5
	local cost = card:getCost()
	if cost >= 0 then
		spr(card.costIcon,l,t,0)
		local costStr = cost == -1 and 'X' or tostring(cost)
		local txtWidth = strWidth(costStr)
		local color = (isNotInHand or showWhiteCost or card:canUse()) and 12 or 1
		if color == 12 and cost ~= card.baseCost then
			color = 5
		end
		printShadowed(costStr,l+4-txtWidth//2,t+1,color)
	elseif cost == -1 then
		spr(card.costIcon,l,t,0)
		spr(54,l,t,7)
	end
end

function drawTitle(card,large,l,t)
	local titleStart = l+2
	local cardName = card.name
	if #cardName > 8 and not large then
		cardName = cardName:sub(1,8)
	end
	local color = card.upgraded and 5 or 12
	if card.rarity == 'rare' then
		color = card.upgraded and 6 or 0
	end
	print(cardName,titleStart,t+2,color,false,1,true)
end

function drawDescription(card,description,x,y,lineWidth,maxLine,color)
	color = color or 12
	local originalColor = color
	maxLine = maxLine or 999
	local currentX = x
	local currentY = y
	local maxY = y+8*(maxLine-1)
	local maxX = x
	for word in description:gmatch('([^ ]+)') do
		if word == 'NL' then
			currentX = x
			currentY = currentY + 8
			if currentY > maxY then
				return maxX-x,maxY
			end
		else
			local lastStart = 1
			local findStart,findEnd,findStr = findMinimal(word,{'({%d+<?})','(!%w!)','(#%d+#)'},lastStart)
			while findStart and findEnd and findStr do
				local strBeforeFind = word:sub(lastStart,findStart-1)
				if #strBeforeFind > 0 then
					currentX,currentY = moveLimitLineWidthAndPrint(strBeforeFind,currentX,currentY,x,lineWidth,maxY,color)
					if currentY > maxY then
						return maxX-x,maxY
					end
					maxX = math.max(maxX,currentX)
				end
				if findStr:sub(1,1) == '{' then
					local flip = findStr:sub(#findStr-1,#findStr-1) == '<'
					local sprId = tonumber(findStr:sub(2,#findStr-1-(flip and 1 or 0)))
					if sprId then
						currentX,currentY = moveLimitLineWidth(currentX,currentY,x,8,lineWidth)
						if currentY > maxY then
							return maxX-x,maxY
						end
						if sprId >= 55 and sprId <= 59 then
							mapColor(3,card.typeIconColor)
							spr(sprId,currentX,currentY-2,0,1,flip and 1 or 0)
							resetColor(3)
						else
							spr(sprId,currentX,currentY-2,0,1,flip and 1 or 0)
						end
						currentX = currentX + 8
						maxX = math.max(maxX,currentX)
					end
				elseif findStr:sub(1,1) == '!' then
					local type = findStr:sub(2,2)
					local base = 0
					local value = 0
					if type == 'D' then
						base = card.baseDamage
						value = card.damage
					elseif type == 'B' then
						base = card.baseBlock
						value = card.block
					elseif type == 'M' then
						base = card.baseMagic
						value = card.magic
					end
					local valueColor = base > value and 3 or (base < value and 5 or 12)
					if type == 'M' and base > value then valueColor = 5 end
					currentX,currentY = moveLimitLineWidthAndPrint(tostring(value),currentX,currentY,x,lineWidth,maxY,valueColor)
					if currentY > maxY then
						return maxX-x,maxY
					end
					maxX = math.max(maxX,currentX)
				elseif findStr:sub(1,1) == '#' then
					local colorStr = findStr:sub(2,#findStr-1)
					color = #colorStr == 0 and originalColor or tonumber(colorStr)
				end
				lastStart = findEnd + 1
				findStart,findEnd,findStr = findMinimal(word,{'({%d+})','(!%w!)','(#%d+#)'},lastStart)
			end
			local strAfterFind = word:sub(lastStart,#word)
			if #strAfterFind > 0 then
				currentX,currentY = moveLimitLineWidthAndPrint(strAfterFind,currentX,currentY,x,lineWidth,maxY,color)
				if currentY > maxY then
					return maxX-x,maxY
				end
				maxX = math.max(maxX,currentX)
			end
			currentX = currentX + 3
		end
	end
	return maxX-x,currentY+8
end

function findMinimal(str, patterns, init)
	local minimal = {nil}
	for i = 1, #patterns do
		local result = {string.find(str, patterns[i], init)}
		if minimal[1] == nil or (result[1] and result[1] < minimal[1]) then
			minimal = result
		end
	end
	return table.unpack(minimal)
end

function moveLimitLineWidth(currentX,currentY,x,width,lineWidth)
	if currentX == x and width > lineWidth then
		return currentX,currentY
	end
	if currentX - x + width > lineWidth then
		currentY = currentY + 8
		currentX = x
	end
	return currentX,currentY
end

function moveLimitLineWidthAndPrint(str,currentX,currentY,x,lineWidth,maxY,color)
	color = color or 12
	local strWidth = strWidth(str,false,true)
	currentX,currentY = moveLimitLineWidth(currentX,currentY,x,strWidth,lineWidth)
	if currentY > maxY then
		return currentX,currentY
	end
	print(str,currentX,currentY,color,false,1,true)
	currentX = currentX + strWidth
	return currentX,currentY
end

function removeCardFromDeck(amount,canClose,onClose)
	local cardItems = table.map(deck, function (card) return CardItem:new{card=card,x=240,y=0,isNotInHand=true} end)
	table.retainIf(cardItems,function (cardItem) return cardItem.card.canRemove end)
	if #cardItems == 0 then
		if onClose then
			onClose(false)
		end
		return false
	end
	local oldAmount = amount
	amount = math.min(amount,#cardItems)
	local gridView = CardGridSelectWindow:new{title='Choose a Card to Remove',cardItems=cardItems,min=amount,max=amount,canClose=canClose or false}
	if amount > 1 then
		gridView.title = 'Choose Cards to Remove ({#}/'..oldAmount..')'
	end
	openWindowAbove(gridView, function (cards)
		if not cards then
			if onClose then
				onClose(false)
			end
			return
		end
		local startX,stepX = placeCardsInARow(#cards)
		for i, cardItem in ipairs(cards) do
			table.remove(deck,table.indexOf(deck,cardItem.card))
			cardItem.tx = startX+stepX*i
			cardItem.ty = 68
			cardItem.large = false
			addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=10,duration=30,tx=120,ty=-30})
		end
		if onClose then
			onClose(true)
		end
	end)
	return true
end

function upgradeCardFromDeck(amount,canClose,onClose)
	local cardItems = table.map(deck, function (card) return CardItem:new{card=card,x=240,y=0,isNotInHand=true} end)
	table.retainIf(cardItems,function (cardItem) return cardItem.card:canUpgrade() end)
	if #cardItems == 0 then
		if onClose then
			onClose(false)
		end
		return false
	end
	local oldAmount = amount
	amount = math.min(amount,#cardItems)
	local gridView = CardGridSelectWindow:new{title='Choose a Card to Upgrade',cardItems=cardItems,min=amount,max=amount,canClose=canClose or false}
	if amount > 1 then
		gridView.title = 'Choose Cards to Upgrade ({#}/'..oldAmount..')'
	end
	openWindowAbove(gridView, function (cards)
		if not cards then
			if onClose then
				onClose(false)
			end
			return
		end
		local startX,stepX = placeCardsInARow(#cards)
		for i, cardItem in ipairs(cards) do
			cardItem.tx = startX+stepX*i
			cardItem.ty = 68
			cardItem.large = false
			addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=30,duration=50,tx=120,ty=-30})
			addEffect(AnonymousEffect:new{duration=10,callback=function (duration)
				if duration == 1 then
					cardItem.card:upgrade()
					cardItem.card:resetPowers()
				end
			end})
		end
		if onClose then
			onClose(true)
		end
	end)
	return true
end

function transformCardFromDeck(amount,random,canClose,onClose)
	local cardItems = table.map(deck, function (card) return CardItem:new{card=card,x=240,y=0,isNotInHand=true} end)
	table.retainIf(cardItems,function (cardItem) return cardItem.card.canRemove end)
	if #cardItems == 0 then
		if onClose then
			onClose(false)
		end
		return false
	end
	local oldAmount = amount
	amount = math.min(amount,#cardItems)
	local gridView = CardGridSelectWindow:new{title='Choose a Card to Transform',cardItems=cardItems,min=amount,max=amount,canClose=canClose or false}
	if amount > 1 then
		gridView.title = 'Choose Cards to Transform ({#}/'..oldAmount..')'
	end
	openWindowAbove(gridView, function (cards)
		if not cards then
			if onClose then
				onClose(false)
			end
			return
		end
		local startX,stepX = placeCardsInARow(#cards)
		for i, cardItem in ipairs(cards) do
			local thisCardTypes
			if cardItem.card.colorName == 'colorless' then
				thisCardTypes = shallowcopy(getColorlessCards())
				table.retainIf(thisCardTypes,function (card) return card.rarity == 'common' or card.rarity == 'uncommon' or card.rarity == 'rare' end)
			elseif cardItem.card.colorName == 'curse' then
				thisCardTypes = shallowcopy(getCurseCards())
				table.retainIf(thisCardTypes,function (card) return card.rarity == 'common' or card.rarity == 'uncommon' or card.rarity == 'rare' end)
			else
				thisCardTypes = shallowcopy(player:getCards())
				table.retainIf(thisCardTypes,function (card) return card.rarity == 'common' or card.rarity == 'uncommon' or card.rarity == 'rare' end)
			end
			table.retainIf(thisCardTypes,function (card) return getmetatable(cardItem.card) ~= card end)
			local randomCard = thisCardTypes[random:randInt(#thisCardTypes)]:new()
			table.remove(deck,table.indexOf(deck,cardItem.card))
			table.insert(deck,randomCard)
			cardItem.tx = startX+stepX*i
			cardItem.ty = 68
			cardItem.large = false
			addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=30,duration=50,tx=240,ty=0})
			addEffect(AnonymousEffect:new{duration=10,callback=function (duration)
				if duration == 1 then
					cardItem.card = randomCard
				end
			end})
		end
		if onClose then
			onClose(true)
		end
	end)
	return true
end

-- hand ui
HandUI = Object:new{cardItems=nil,selection=0,cursorOnSelf=false,hideSelection=false,onSelect=noop,justChangedSelection=false}
function HandUI:new(cardItems)
	return Object.new(self,{cardItems=cardItems})
end

function HandUI:tick()
	self:drawCards()
	self:handControls()
end

function HandUI:drawCards()
	local handWidth
	local handDistance
	local handStart
	if #self.cardItems < 7 then
		handWidth = #self.cardItems * 24 + 8
		handDistance = 24
		handStart = 120 - handWidth / 2 + 16 - handDistance
	else
		handWidth = 180
		handDistance = (handWidth - 32) / (#self.cardItems - 1)
		handStart = 30
	end
	if self.hideSelection then
		for i = 1,#self.cardItems do
			if not self.cardItems[i].isNotInHand then
				self.cardItems[i].tx = handStart + i * handDistance
				self.cardItems[i].ty = 136
			end
			self.cardItems[i].large = false
			self.cardItems[i]:tick()
		end
	else
		for i = 1,#self.cardItems do
			if not self.cardItems[i].isNotInHand then
				self.cardItems[i].tx = handStart + i * handDistance
				self.cardItems[i].ty = 136
			end
			self.cardItems[i].large = false
			if self.selection == i and not self.cursorOnSelf then
				self.cardItems[i].ty = 128
			end
			if self.selection ~= i or not self.cursorOnSelf then
				self.cardItems[i]:tick()
			end
		end
		if self.cursorOnSelf and self.selection <= #self.cardItems and self.selection >= 1 then
			local index = self.selection
			if self.cardItems[index].isNotInHand then
				self.cardItems[index].large = false
			else
				self.cardItems[index].ty = 108
				self.cardItems[index].large = true
			end
			self.cardItems[index]:tick()
		end
	end
end

function HandUI:handControls()
	self.justChangedSelection = false
	if not self.cursorOnSelf then
		return
	end

	local function cardIsInHand(i) return not self.cardItems[i].isNotInHand end

	local oldSelection = self.selection
	if self.selection > #self.cardItems then
		self.selection = #self.cardItems
	end
	if self.selection == 0 and #self.cardItems > 0 then
		self.selection = nextOrOtherIndexInTableIf(self.cardItems,self.selection,cardIsInHand)
	end

	if btnp(2) then
		self.selection = previousOrOtherIndexInTableIf(self.cardItems,self.selection,cardIsInHand)
	elseif btnp(3) then
		self.selection = nextOrOtherIndexInTableIf(self.cardItems,self.selection,cardIsInHand)
	elseif btnp(4) and self.selection >= 1 and self.selection <= #self.cardItems then
		local oldSelection = self.selection
		self.selection = keepCurrentIndexInTableIf(self.cardItems,oldSelection,cardIsInHand)
		if oldSelection == self.selection then
			self.onSelect(self.selection)
		end
	end
	
	if oldSelection ~= self.selection then
		self.justChangedSelection = true
	end
end

-- grid UI
CardGridUI = Object:new{cardItems=nil,selection=0,cursorOnSelf=false,onSelect=noop,top=0,ty=0,y=0}
function CardGridUI:new(cardItems)
	return Object.new(self,{cardItems=cardItems})
end

function CardGridUI:tick()
	self:drawCards()
	self:gridControls()
end

function CardGridUI:drawCards()
	self.y = lerp(self.y,self.ty,0.2)
	for i, cardItem in ipairs(self.cardItems) do
		local row,col = math.floor((i-1)/5),(i-1)%5
		local x,y = 28+col*46,self.top+36+row*56-self.y
		cardItem.tx = x
		cardItem.ty = y
		cardItem.large = self.cursorOnSelf and self.selection == i
		if self.selection ~= i then
			cardItem:tick()
		end
	end
	if self.selection > 0 and self.selection <= #self.cardItems then
		self.cardItems[self.selection]:tick()
	end
end

function CardGridUI:gridControls()
	if not self.cursorOnSelf then
		return
	end
	
	if self.selection > #self.cardItems then
		self.selection = #self.cardItems
	end
	if self.selection == 0 and #self.cardItems > 0 then
		self.selection = 1
	end

	local pressed = false
	if btnp(0) then
		self.selection = limit(self.selection-5,1,#self.cardItems)
		pressed = true
	elseif btnp(1) then
		self.selection = limit(self.selection+5,1,#self.cardItems)
		pressed = true
	elseif btnp(2) then
		self.selection = limit(self.selection-1,1,#self.cardItems)
		pressed = true
	elseif btnp(3) then
		self.selection = limit(self.selection+1,1,#self.cardItems)
		pressed = true
	elseif btnp(4) and self.selection >= 1 and self.selection <= #self.cardItems then
		self.onSelect(self.selection)
	end

	if pressed then
		local row = math.floor((self.selection-1)/5)
		local y = self.top+36+row*56-self.y
		if y < 36+self.top then
			self.ty = row*56
		elseif y > 100 then
			self.ty = self.top+row*56-64
		end
	end
end

-- hand select UI
HandSelectWindow = Window:new{
	name='HandSelectWindow',selectedCards=nil,title='Choose a card',cardItems=nil,single=false,
	cursorOnSelectedCards=false,selection=0,max=999,min=1,filter=nil
}
function HandSelectWindow:new(o)
	o.originalCardItems = o.cardItems
	o.cardItems = shallowcopy(o.cardItems)
	for i = 1,#o.cardItems do
		local cardItem = o.cardItems[i]:copy()
		cardItem.originalIndex = i
		cardItem.isNotInHand = false
		cardItem.showWhiteCost = true
		o.cardItems[i] = cardItem
	end
	o.filter = o.filter or self.filter
	if o.filter then
		table.retainIf(o.cardItems,o.filter)
	end
	local handUI = HandUI:new(o.cardItems)
	handUI.cursorOnSelf = true
	o.handUI = handUI
	o.selectedCards = {}
	r = Window.new(self,o)
	handUI.onSelect = function (selection)
		r:handUISelect(selection)
	end
	return r
end

function HandSelectWindow:tick()
	self:drawTitle()
	self:drawSelectedCards()
	self.handUI:tick()
	self:selectedCardsControls()
	tickTopBar(true)
end

function HandSelectWindow:drawTitle()
	local str = self.title:gsub('{#}',tostring(#self.selectedCards))
	printShadowed(str,120-strWidth(str)/2,16,12)
end

function HandSelectWindow:drawSelectedCards()
	local startX,stepX = placeCardsInARow(#self.selectedCards)
	for i, cardItem in ipairs(self.selectedCards) do
		cardItem.tx = startX+i*stepX
		cardItem.ty = 60
		if not self.cursorOnSelectedCards or self.selection ~= i then
			cardItem.large = false
			cardItem:tick()
		end
	end
	if self.cursorOnSelectedCards and self.selection > 0 and self.selection <= #self.selectedCards then
		self.selectedCards[self.selection].large = true
		self.selectedCards[self.selection]:tick()
	end
end

function HandSelectWindow:selectedCardsControls()
	self.handUI.cursorOnSelf = not cursorOnTopBar and not self.cursorOnSelectedCards
	if cursorOnTopBar then
		return
	end

	if self.cursorOnSelectedCards then
		if self.selection == 0 and #self.selectedCards > 0 then
			self.selection = 1
		end
		if btnp(1) and #self.cardItems > 0 then
			self.cursorOnSelectedCards = false
			self.handUI.cursorOnSelf = true
		elseif btnp(2) then
			self.selection = limit(self.selection-1,1,#self.selectedCards)
		elseif btnp(3) then
			self.selection = limit(self.selection+1,1,#self.selectedCards)
		elseif btnp(4) then
			local cardItem = table.remove(self.selectedCards,self.selection)
			table.insert(self.cardItems,cardItem)
			table.sort(self.cardItems,function(a,b) return a.originalIndex < b.originalIndex end)
			self.selection = limit(self.selection,1,#self.selectedCards)
			if #self.selectedCards == 0 then
				self.cursorOnSelectedCards = false
				self.handUI.cursorOnSelf = true
			end
		end
	else
		if btnp(0) and #self.selectedCards > 0 then
			self.cursorOnSelectedCards = true
			self.handUI.cursorOnSelf = false
			self.selection = limit(self.selection,1,#self.selectedCards) or 0
		end
	end

	if btnp(7) and #self.selectedCards >= self.min then
		self:close()
	end
end

function HandSelectWindow:handUISelect(selection)
	if self.max == 1 then
		local selectedCardItem = table.remove(self.cardItems,selection)
		for i = #self.selectedCards,1,-1 do
			local cardItem = table.remove(self.selectedCards,i)
			table.insert(self.cardItems,cardItem)
		end
		table.sort(self.cardItems,function(a,b) return a.originalIndex < b.originalIndex end)
		table.insert(self.selectedCards,selectedCardItem)
	else
		if #self.selectedCards < self.max then
			local cardItem = table.remove(self.cardItems,selection)
			table.insert(self.selectedCards,cardItem)
		end
	end
end

function HandSelectWindow:close()
	for _, cardItem in ipairs(self.cardItems) do
		local originalCardItem = self.originalCardItems[cardItem.originalIndex]
		if originalCardItem then
			originalCardItem.x = cardItem.x
			originalCardItem.y = cardItem.y
			originalCardItem.tx = cardItem.tx
			originalCardItem.ty = cardItem.ty
		end
	end
	local output = {}
	for _, cardItem in ipairs(self.selectedCards) do
		local originalCardItem = self.originalCardItems[cardItem.originalIndex]
		if originalCardItem then
			originalCardItem.x = cardItem.x
			originalCardItem.y = cardItem.y
			originalCardItem.tx = cardItem.tx
			originalCardItem.ty = cardItem.ty
			table.insert(output,originalCardItem)
		end
	end

	Window.close(self,output)
end

HandSelectUpgradeWindow = HandSelectWindow:new{
	name='HandSelectUpgradeWindow',title='Choose a Card to Upgrade',max=1,min=1,cardItems={},
	selectedPreview=nil,upgradedPreview=nil,
	filter=function (cardItem) return cardItem.card:canUpgrade() end
}
function HandSelectUpgradeWindow:new(o)
	o = o or {}
	o.selectedPreview = CardItem:new{showWhiteCost=true}
	o.upgradedPreview = CardItem:new{showWhiteCost=true}
	return HandSelectWindow.new(self,o)
end

function HandSelectUpgradeWindow:drawSelectedCards()
	if #self.selectedCards == 0 then
		return
	end
	local cardItem = self.selectedCards[1]
	local selectedPreview = self.selectedPreview
	local upgradedPreview = self.upgradedPreview
	if selectedPreview.card == nil or getmetatable(selectedPreview.card) ~= getmetatable(cardItem.card) then
		selectedPreview.card = cardItem.card:copy()
		selectedPreview.card:resetPowers()
		selectedPreview.x = cardItem.x
		selectedPreview.y = cardItem.y
		upgradedPreview.card = cardItem.card:copy()
		upgradedPreview.card:resetPowers()
		upgradedPreview.card:upgrade()
		upgradedPreview.card:showUpgrade()
		upgradedPreview.x = cardItem.x
		upgradedPreview.y = cardItem.y
	end

	selectedPreview.ty = 60
	upgradedPreview.ty = 60
	if self.selection == 1 and self.cursorOnSelectedCards then
		selectedPreview.tx = 76
		selectedPreview.large = true
		upgradedPreview.tx = 164
		upgradedPreview.large = true
	else
		selectedPreview.tx = 88
		selectedPreview.large = false
		upgradedPreview.tx = 152
		upgradedPreview.large = false
	end
	selectedPreview:tick()
	upgradedPreview:tick()
	cardItem.x = selectedPreview.x
	cardItem.y = selectedPreview.y
	for i = -1, 1 do
		tri(120-3-i*8,56,120-3-i*8,64,120+3-i*8,60,4)
	end
end

-- grid select window
CardGridSelectWindow = Window:new{
	name='CardGridSelectWindow',selectedCards=nil,title='Choose a card',cardItems=nil,single=false,
	max=999,min=1,canClose=false,
}
function CardGridSelectWindow:onOpen()
	if roomType == 'combat' then
		queueSync(2,combatSpriteBank)
	else
		queueSync(2,currentEvent.spritebank)
	end
	queueSync(1,player.tileBank)
end

function CardGridSelectWindow:new(o)
	local gridUI = CardGridUI:new(o.cardItems)
	gridUI.cursorOnSelf = true
	gridUI.top = 24
	o.maxY = math.ceil(#o.cardItems/5-1)*56-64+gridUI.top
	o.height = 120
	o.gridUI = gridUI
	o.selectedCards = {}
	r = Window.new(self,o)
	gridUI.onSelect = function (selection)
		r:gridUISelect(selection)
	end
	return r
end

function CardGridSelectWindow:tick()
	local str = self.title:gsub('{#}',tostring(#self.selectedCards))
	print(str,120-strWidth(str)/2,18,12)
	if self.maxY > 0 then
		local t=16+self.gridUI.y/(self.maxY+self.height)*112
		local b=16+(self.gridUI.y+self.height)/(self.maxY+self.height)*112
		rect(234,t,4,b-t,14)
	end
	clip(0,24,240,136)
	self.gridUI:tick()
	clip()
	self:selectedCardsControls()
	tickTopBar(true)
end

function CardGridSelectWindow:gridUISelect(selection)
	local cardItem = self.cardItems[selection]
	local selectionIndex = table.indexOf(self.selectedCards,cardItem)
	if selectionIndex then
		cardItem.glow = nil
		table.remove(self.selectedCards,selectionIndex)
	elseif self.max == 1 then
		for i=#self.selectedCards,1,-1 do
			self.selectedCards[i].glow = nil
			table.remove(self.selectedCards,i)
		end
		cardItem.glow = 11
		table.insert(self.selectedCards,cardItem)
	elseif #self.selectedCards < self.max then
		cardItem.glow = 11
		table.insert(self.selectedCards,cardItem)
	end
end

function CardGridSelectWindow:selectedCardsControls()
	self.gridUI.cursorOnSelf = not cursorOnTopBar
	if cursorOnTopBar then
		return
	end

	if btnp(5) and self.canClose then
		self:cancel()
	elseif btnp(7) and #self.selectedCards >= self.min then
		self:close()
	end
end

function CardGridSelectWindow:close()
	for _, cardItem in ipairs(self.selectedCards) do
		cardItem.glow = nil
	end
	Window.close(self,self.selectedCards)
end

function CardGridSelectWindow:cancel()
	Window.close(self,nil)
end
