-- card
---@diagnostic disable: lowercase-global

---@class Card : Object
---@field costForOnePlay integer?
---@field costForOneTurnPlay integer?
Card = {
	name='',description='',type='attack',rarity='common',
	color={2,1},costIcon=201,typeIconColor=4,colorName='',
	baseCost=0,cost=0,costForOneTurnPlay=nil,costForOnePlay=nil,baseCostModified=false,
	damage=0,baseDamage=0,block=0,baseBlock=0,magic=0,baseMagic=0,multiDamage={},displayAttackCount=1,displayDamage=nil,
	enemyTarget=false,playerTarget=false,toAllEnemies=false,
	exhaust=false,ethereal=false,innate=false,autoPlayOnEndTurn=false,
	upgrade=noop,upgraded=false,tags={},canGenerateInCombat=true,canRemove=true,linkedBottle=nil,
	onRemoveFromDeck=noop,priority=120,descriptionWidth=53,
}
Object:new(Card)

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
	local hasTarget = target ~= nil
	if target == true then
		target = nil
	end

	damage = player:triggerReducerEvent('onAttack',damage,target,self)
	if self.toAllEnemies and hasTarget then
		self.multiDamage = {}
		local minDamage = 9999999
		local maxDamage = 0
		for i,enemy in ipairs(enemies) do
			if enemy.canInteract then
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

	self.damage = math.max(0,math.floor(damage))

	local block = self.baseBlock
	block = player:triggerReducerEvent('onModifyBlock',block,self)
	self.block = math.max(0,math.floor(block))

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

function Card:save()
	return self.upgraded and 1 or 0
end

function Card:load(meta)
	if meta > 0 then
		self:upgrade()
		self:resetPowers()
	end
end

---@class CardItem : Object
---@field card Card
---@field tx integer
---@field ty integer
---@field isNotInHand boolean
---@field large boolean
CardItem = { x=0,y=136,tx=0,ty=136,large=false,isNotInHand=false,showWhiteCost=false,glow=nil,flipped=false }
Object:new(CardItem)

cardTypeToSprIndex = {attack=icons.Attack,skill=icons.Skill,power=icons.Power,status=icons.Status,curse=icons.Curse}
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
	l = math.floor(l)
	t = math.floor(t)
	if self.glow ~= nil then
		rect(l-1,t,self.large and 58 or 34,self.large and 57 or 41,self.glow)
	end
	if self.flipped then
		drawCardFlipped(self.large,l,t)
	else	
		drawCardBack(self.card,self.large,l,t)
		drawCost(self.card,l,t,self.isNotInHand,self.showWhiteCost)

		stackClip(l+1,t,self.large and 54 or 30,self.large and 56 or 40)
		drawTitle(self,l,t)
		drawDescription(self.card,self.card.description,l+3,t+9,self.large and 53 or 29,self.large and 999 or 3)
		popClip()

		if self.card.linkedBottle and getmetatable(nearestWindow) == CardGridSelectWindow then
			self.card.linkedBottle:drawImage(l+(self.large and 48 or 24),t-6,true)
		end
	end
end

function drawCardFlipped(large,l,t)
	if large then
		rect(l+7,t+7,42,42,4)
		sprmap(14,2,7,7,l,t,0,1,function (tile,x) return tile,x==20 and 1 or 0 end)
		sprmap(25,2,2,3,l+20,t+16,0,1,function (tile,x) return tile,x==26 and 1 or 0 end)
	else
		rect(l+7,t+7,18,26,4)
		sprmap(21,2,4,5,l,t,0,1,function (tile,x) return tile,x==24 and 1 or 0 end)
		sprmap(25,2,2,3,l+8,t+8,0,1,function (tile,x) return tile,x==26 and 1 or 0 end)
	end
end

function drawCardBack(card,large,l,t)
	mapColor(14,card.color[1])
	mapColor(15,card.color[2])
	mapColor(10,cardRarityColor[card.rarity][1])
	mapColor(9,cardRarityColor[card.rarity][2])
	if large then
		rect(l,t+8,56,40,14)
		rect(l+8,t+48,40,8,14)
		rect(l,t+8,1,40,15)
		rect(l+55,t+8,1,40,15)
		rect(l+8,t+55,40,1,15)
		rect(l+8,t+1,40,1,14)
		rect(l+8,t+2,40,5,10)
		rect(l+8,t+7,40,1,9)
		map(3,2,7,7,l,t,0,1,function(tile,x) return tile,x==9 and 1 or 0 end)
	else
		rect(l,t+8,32,24,14)
		rect(l+8,t+32,16,8,14)
		rect(l,t+8,1,24,15)
		rect(l+31,t+8,1,24,15)
		rect(l+8,t+39,16,1,15)
		rect(l+8,t+1,16,1,14)
		rect(l+8,t+2,16,5,10)
		rect(l+8,t+7,16,1,9)
		map(10,2,4,5,l,t,0,1,function(tile,x) return tile,x==13 and 1 or 0 end)
	end
	local typeLeft = card.baseCost >= -1 and l+8 or l+1
	local typeWidth = 8
	local damageStr = ''
	if card.type == 'attack' then
		damageStr = tostring(card.displayDamage or card.damage)
		if type(card.displayAttackCount) ~= 'number' or card.displayAttackCount > 1 then
			damageStr = damageStr .. 'x' .. tostring(card.displayAttackCount)
		elseif card.displayAttackCount == 0 then
			damageStr = '0'
		end
		typeWidth = typeWidth + strWidth(damageStr,false,true) + 1
	end
	rect(typeLeft,t-4,typeWidth,6,14)
	rect(typeLeft+1,t-5,typeWidth-2,1,14)
	drawIcon(cardTypeToSprIndex[card.type],typeLeft,t-5,card.typeIconColor)
	resetColors{3,9,10,14,15}
	if card.type == 'attack' then
		local color = 12
		if not card.displayDamage then
			if card.damage > card.baseDamage then
				color = 5
			elseif card.damage < card.baseDamage then
				color = 3
			end
		end
		print(damageStr,typeLeft+8,t-4,color,false,1,true)
	end
end

function drawCost(card,l,t,isNotInHand,showWhiteCost)
	t = t-5
	local cost = card:getCost()
	if cost >= 0 then
		spr(card.costIcon,l,t,0)
		local costStr = cost == -1 and 'X' or tostring(cost)
		local txtWidth = strWidth(costStr)
		local color = (isNotInHand or showWhiteCost or (card:canUse() and not endTurnPressed)) and 12 or 1
		if color == 12 and (cost ~= card.baseCost or card.baseCostModified) then
			color = 5
		end
		printShadowed(costStr,l+4-txtWidth//2,t+1,color)
	elseif cost == -1 then
		spr(card.costIcon,l,t,0)
		spr(54,l,t,7)
	end
end

function drawTitle(cardItem,l,t)
	local card = cardItem.card
	local titleStart = l+2
	local cardName = card.name
	local color = card.upgraded and 5 or 12
	if card.rarity == 'rare' then
		color = card.upgraded and 6 or 0
	end

	local xOffset = 0
	local titleWidth = cardItem.titleWidth
	if cardItem.large and titleWidth and titleWidth > 54 then
		local d = titleWidth - 54
		local f = 2
		local p = ((cardItem.titleTimer or 0) + 1) % (2 * d * f + 60)
		cardItem.titleTimer = p
		xOffset = p<30 and 0 or (p-30<d*f and (-p+30)/f or (p<60+d*f and -d or (p-60-2*d*f)/f))
	end

	cardItem.titleWidth = print(cardName,titleStart+xOffset,t+2,color,false,1,true)
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
			local xOffset,yOffset = 0,0
			if word:sub(1,1) == '~' and word:sub(-1,-1) == '~' then
				yOffset = math.sin(currentX*173+currentY*31+time()*0.003)*1.2
				word = word:sub(2,-2)
			end
			if word:sub(1,1) == '@' and word:sub(-1,-1) == '@' then
				xOffset = effectRandom:randInt(-1,1)
				yOffset = effectRandom:randInt(-1,1)
				word = word:sub(2,-2)
			end

			local lastStart = 1
			local findStart,findEnd,findStr = findMinimal(word,{'({%w+})','(!%w!)','(#%d+#)'},lastStart)
			while findStart and findEnd and findStr do
				local strBeforeFind = word:sub(lastStart,findStart-1)
				if #strBeforeFind > 0 then
					currentX,currentY = moveLimitLineWidthAndPrint(strBeforeFind,currentX,currentY,x,lineWidth,maxY,color,xOffset,yOffset)
					if currentY > maxY then
						return maxX-x,maxY
					end
					maxX = math.max(maxX,currentX)
				end
				if findStr:sub(1,1) == '{' then
					local iconName = findStr:sub(2,-2)
					local isNumber = iconName:match('%d+') ~= nil
					local sprId = isNumber and tonumber(iconName) or nil
					local icon = icons[iconName] or sprId
					if icon then
						currentX,currentY = moveLimitLineWidth(currentX,currentY,x,8,lineWidth)
						if currentY > maxY then
							return maxX-x,maxY
						end
						drawIcon(icon,currentX+xOffset,currentY+yOffset-1,card.typeIconColor or color)
						currentX = currentX + 9
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
					local valueColor = base > value and 3 or (base < value and 5 or color)
					if type == 'M' and base > value then valueColor = 5 end
					currentX,currentY = moveLimitLineWidthAndPrint(tostring(value),currentX,currentY,x,lineWidth,maxY,valueColor,xOffset,yOffset)
					if currentY > maxY then
						return maxX-x,maxY
					end
					maxX = math.max(maxX,currentX)
				elseif findStr:sub(1,1) == '#' then
					local colorStr = findStr:sub(2,#findStr-1)
					color = #colorStr == 0 and originalColor or tonumber(colorStr)
				end
				lastStart = findEnd + 1
				findStart,findEnd,findStr = findMinimal(word,{'({%w+})','(!%w!)','(#%d+#)'},lastStart)
			end
			local strAfterFind = word:sub(lastStart,#word)
			if #strAfterFind > 0 then
				currentX,currentY = moveLimitLineWidthAndPrint(strAfterFind,currentX,currentY,x,lineWidth,maxY,color,xOffset,yOffset)
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

function moveLimitLineWidthAndPrint(str,currentX,currentY,x,lineWidth,maxY,color,xOffset,yOffset)
	color = isDarken and 14 or color or 12
	local strWidth = strWidth(str,false,true)
	currentX,currentY = moveLimitLineWidth(currentX,currentY,x,strWidth,lineWidth)
	if currentY > maxY then
		return currentX,currentY
	end
	print(str,currentX+xOffset,currentY+yOffset,color,false,1,true)
	currentX = currentX + strWidth
	return currentX,currentY
end

function obtainCard(card)
	if player:triggerConditionEvent('onBeforeObtainCard',true,card) then
		table.insert(deck,card)
		player:triggerEvent('onObtainCard',card)
		return true
	end
	return false
end

function removeCard(card)
	removeCardByIndex(table.indexOf(deck,card))
end

function removeCardByIndex(index)
	local card = deck[index]
	table.remove(deck,index)
	card:onRemoveFromDeck()
	player:triggerEvent('onRemoveCard',card)
end

function removeCardFromDeck(amount,canClose,onClose,title)
	title = title or 'Choose a Card to Remove'
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
	local gridView = CardGridSelectWindow:new{title=title,cardItems=cardItems,min=amount,max=amount,canClose=canClose or false}
	if amount > 1 then
		gridView.title = title..' ({#}/'..oldAmount..')'
	end
	openWindowAbove(gridView, function (cards)
		if not cards then
			if onClose then
				onClose(false)
			end
			return
		end
		removeCardsWithEffect(cards)
		if onClose then
			onClose(true,cards)
		end
	end)
	return true
end

function removeCardsWithEffect(cardItems,duration)
	duration = duration or 10
	local startX,stepX = placeCardsInARow(#cardItems)
	for i, cardItem in ipairs(cardItems) do
		removeCard(cardItem.card)
		cardItem.tx = startX+stepX*i
		cardItem.ty = 68
		cardItem.large = false
		addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=duration+effectRandom:randInt(-10,10),duration=duration+20,tx=startX+stepX*i,ty=-30})
	end
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
	local gridView = CardGridSelectUpgradeWindow:new{title='Choose a Card to Upgrade',cardItems=cardItems,min=amount,max=amount,canClose=canClose or false}
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
		upgradeCardsWithEffect(cards)
		if onClose then
			onClose(true)
		end
	end)
	return true
end

function upgradeCardsWithEffect(cardItems)
	local startX,stepX = placeCardsInARow(#cardItems)
	for i, cardItem in ipairs(cardItems) do
		cardItem.tx = startX+stepX*i
		cardItem.ty = 68
		cardItem.large = false
		addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=30,duration=50,tx=240,ty=0})
		addEffect(AnonymousEffect:new{duration=10,callback=function (duration)
			if duration == 1 then
				cardItem.card:upgrade()
				cardItem.card:resetPowers()
			end
		end})
	end
end

function transformCardFromDeck(amount,random,canClose,onClose,title)
	title = title or 'Choose a Card to Transform'
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
	local gridView = CardGridSelectWindow:new{title=title,cardItems=cardItems,min=amount,max=amount,canClose=canClose or false}
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
		local transformedCards = transformCardsWithEffect(random,cards)
		if onClose then
			onClose(true,transformedCards)
		end
	end)
	return true
end

function transformCardsWithEffect(random,cardItems)
	local startX,stepX = placeCardsInARow(#cardItems)
	local transformedCards = {}
	for i, cardItem in ipairs(cardItems) do
		local randomCard = getTransformedCard(random,cardItem.card)
		transformedCards[i] = randomCard
		removeCard(cardItem.card)
		obtainCard(randomCard)
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
	return transformedCards
end

function getTransformedCard(random,card)
	local thisCardTypes
	if card.colorName == 'colorless' then
		thisCardTypes = shallowcopy(getColorlessCards())
		table.retainIf(thisCardTypes,function (c) return c.rarity == 'common' or c.rarity == 'uncommon' or c.rarity == 'rare' end)
	elseif card.colorName == 'curse' then
		thisCardTypes = shallowcopy(getCurseCards())
		table.retainIf(thisCardTypes,function (c) return c.rarity == 'common' or c.rarity == 'uncommon' or c.rarity == 'rare' end)
	else
		thisCardTypes = shallowcopy(player:getCards())
		table.retainIf(thisCardTypes,function (c) return c.rarity == 'common' or c.rarity == 'uncommon' or c.rarity == 'rare' end)
	end
	table.retainIf(thisCardTypes,function (c) return getmetatable(card) ~= c end)
	return thisCardTypes[random:randInt(#thisCardTypes)]:new()
end

function duplicateCardFromDeck(amount,canClose,onClose,title)
	title = title or 'Choose a Card to Duplicate'
	local cardItems = table.map(deck, function (card) return CardItem:new{card=card,x=240,y=0,isNotInHand=true} end)
	if #cardItems == 0 then
		if onClose then
			onClose(false)
		end
		return false
	end
	local oldAmount = amount
	amount = math.min(amount,#cardItems)
	local gridView = CardGridSelectWindow:new{title=title,cardItems=cardItems,min=amount,max=amount,canClose=canClose or false}
	if amount > 1 then
		gridView.title = title..' ({#}/'..oldAmount..')'
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
			obtainCard(cardItem.card:copy())
			cardItem.tx = startX+stepX*i
			cardItem.ty = 68
			cardItem.large = false
			addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=20,duration=40,tx=240,ty=0})
			addEffect(CardEffect:new{cardItem=cardItem:copy(),pauseDuration=40,duration=60,tx=240,ty=0})
		end
		if onClose then
			onClose(true,cards)
		end
	end)
	return true
end

function obtainCardWithEffect(card,x,y)
	local cardItem = CardItem:new{card=card,x=0,y=136,tx=x or 120,ty=y or 68,isNotInHand=true}
	addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=30,duration=50,tx=240,ty=0})
	obtainCard(cardItem.card)
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
		self:scrollToSelection()
	end
end

function CardGridUI:scrollToSelection()
	local row = math.floor((self.selection-1)/5)
	local y = self.top+36+row*56-self.y
	if y < 36+self.top then
		self.ty = row*56
	elseif y > 100 then
		self.ty = self.top+row*56-64
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
	printShadowed(str,120-strWidth(str)/2,18,12)
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
function CardGridSelectWindow:new(o)
	o.cardItems = o.cardItems or {}
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

function CardGridSelectWindow:onOpen()
	if roomActionType == 'combat' then
		queueSync(2,combatSpriteBank)
	else
		queueSync(2,currentEvent.spriteBank)
	end
	queueSync(1,player.tileBank)
end

function CardGridSelectWindow:tick()
	local str = self.title:gsub('{#}',tostring(#self.selectedCards))
	print(str,120-strWidth(str)/2,18,12)
	if self.maxY > 0 then
		local t=16+self.gridUI.y/(self.maxY+self.height)*112
		local b=16+(self.gridUI.y+self.height)/(self.maxY+self.height)*112
		rect(234,t,4,b-t,14)
	end
	stackClip(0,24,240,136)
	self.gridUI:tick()
	popClip()
	self:selectedCardsControls()
	tickTopBar(true)
end

function CardGridSelectWindow:gridUISelect(selection)
	local cardItem = self.cardItems[selection]
	local selectionIndex = table.indexOf(self.selectedCards,cardItem)
	if selectionIndex then
		cardItem.glow = nil
		self:onUnselectCard(selectionIndex)
	elseif self.max == 1 then
		for i=#self.selectedCards,1,-1 do
			self.selectedCards[i].glow = nil
			self:onUnselectCard(i)
		end
		cardItem.glow = 11
		self:onSelectCard(cardItem)
	elseif #self.selectedCards < self.max then
		cardItem.glow = 11
		self:onSelectCard(cardItem)
	end
end

function CardGridSelectWindow:onSelectCard(cardItem)
	table.insert(self.selectedCards,cardItem)
end

function CardGridSelectWindow:onUnselectCard(index)
	table.remove(self.selectedCards,index)
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

CardGridSelectUpgradeWindow = CardGridSelectWindow:new{name='CardGridSelectUpgradeWindow',title='Choose a card to Upgrade',upgradedCards=nil}
function CardGridSelectUpgradeWindow:onSelectCard(cardItem)
	cardItem.originalCard = cardItem.card
	cardItem.card = cardItem.card:copy()
	cardItem.card:resetPowers()
	cardItem.card:upgrade()
	cardItem.card:showUpgrade()
	table.insert(self.selectedCards,cardItem)
end

function CardGridSelectUpgradeWindow:onUnselectCard(index)
	local cardItem = self.selectedCards[index]
	cardItem.card = cardItem.originalCard
	cardItem.originalCard = nil
	table.remove(self.selectedCards,index)
end

function CardGridSelectUpgradeWindow:resetCards()
	for _, cardItem in ipairs(self.selectedCards) do
		cardItem.card = cardItem.originalCard
		cardItem.originalCard = nil
	end
end

function CardGridSelectUpgradeWindow:close(...)
	self:resetCards()
	CardGridSelectWindow.close(self,...)
end

function CardGridSelectUpgradeWindow:cancel(...)
	self:resetCards()
	CardGridSelectWindow.cancel(self,...)
end
