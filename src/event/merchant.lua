-- merchant
---@diagnostic disable: lowercase-global

MerchantEvent = Event:new{screen='intro',spriteBank=2,random=nil,goods=nil,cardRemoval=nil}
function MerchantEvent:init()
	self.random = self.random or makeRand(act.id,room.id,1)
	table.insert(self.options,{description='[Talk]'})
	table.insert(self.options,{description='[Leave]'})
	self:generateGoods()
end

function MerchantEvent:drawBackground()
	act:drawBackground()
	player:drawImage()
	sprmap(25,45,7,4,130,64,0)
	spr(7,170,73,0,1,1)
	drawTalkBubble('Welcome!',95,32,50,31,152,64,12,15)
end

function MerchantEvent:onOption(selection)
	if selection == 1 then
		self:showMerchant()
	elseif selection == 2 then
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

local cardPrice = {basic=9999,special=9999,common=50,uncommon=75,rare=150}
local relicPrice = {basic=300,special=400,common=150,uncommon=250,rare=300,shop=150,boss=999}
local potionPrice = {common=50,uncommon=75,rare=100}
local mapPowerRarity = {common='uncommon',uncommon='uncommon',rare='rare'}
function MerchantEvent:generateGoods()
	local random = self.random
	local card1,card2,relics,potions = {},{},{},{}
	local goods = {card1=card1,card2=card2,relics=relics,potions=potions}
	card1[1] = getPlayerCardType(random,generateCardRarity(self.random),'attack')
	repeat
		card1[2] = getPlayerCardType(random,generateCardRarity(self.random),'attack')
	until card1[1] ~= card1[2]
	card1[3] = getPlayerCardType(random,generateCardRarity(self.random),'skill')
	repeat
		card1[4] = getPlayerCardType(random,generateCardRarity(self.random),'skill')
	until card1[3] ~= card1[4]
	card1[5] = getPlayerCardType(random,mapPowerRarity[generateCardRarity(self.random)],'power')

	card2[1] = getColorlessCardType(random,'uncommon')
	card2[2] = getColorlessCardType(random,'rare')

	for i,playerCardType in ipairs(card1) do
		local card = playerCardType:new()
		card1[i] = CardItem:new({card=card,x=120,y=-40,isNotInHand=true,basePrice=cardPrice[card.rarity]*random:randFloat(0.9,1.1)})
		player:triggerEvent('onPreviewObtainCard',card)
	end

	local saleCardItem = card1[random:randInt(#card1)]
	saleCardItem.sale = true
	saleCardItem.basePrice = saleCardItem.basePrice / 2

	for i,playerCardType in ipairs(card2) do
		local card = playerCardType:new()
		card2[i] = CardItem:new({card=card,x=120,y=-40,isNotInHand=true,basePrice=cardPrice[card.rarity]*random:randFloat(0.9,1.1)*1.2})
		player:triggerEvent('onPreviewObtainCard',card)
	end

	for i=1,3 do
		local tier
		if i<3 then
			tier = self:rollRelicTier()
		else
			tier = 'shop'
		end
		local relic = getRelicTypeByTier(tier):new()
		relic.basePrice = relicPrice[relic.tier]*random:randFloat(0.95,1.05)
		relics[i] = relic
	end

	for i=1,3 do
		local potion = getRandomPotionType(random):new()
		potion.basePrice = potionPrice[potion.rarity]*random:randFloat(0.95,1.05)
		potions[i] = potion
	end

	self.goods = goods

	self.cardRemoval = {basePrice=self:getCardRemovalPrice(),sold=false}
	self:modifyPrices()
end

function MerchantEvent:rollRelicTier()
	local roll = self.random:randInt(0,99)
	return roll < 48 and 'common' or (roll < 82 and 'uncommon' or 'rare')
end

function MerchantEvent:modifyPrices()
	local card1,card2,relics,potions = self.goods.card1,self.goods.card2,self.goods.relics,self.goods.potions
	for _, item in ipairs(card1) do
		self:modifyPrice(item,'card')
	end
	for _, item in ipairs(card2) do
		self:modifyPrice(item,'card')
	end
	for _, item in ipairs(relics) do
		self:modifyPrice(item,'relic')
	end
	for _, item in ipairs(potions) do
		self:modifyPrice(item,'potion')
	end
	self:modifyPrice(self.cardRemoval,'cardRemoval')
end

function MerchantEvent:modifyPrice(item,type)
	local price = item.basePrice
	if ascension >= 16 and type ~= 'cardRemoval' then
		price = price * 1.1
	end
	price = player:triggerReducerEvent('modifyShopPrice',price,type,item)
	item.price = math.floor(price+0.5)
end

function MerchantEvent:getCardRemovalPrice()
	return shopRemoveCount*25+75
end

function MerchantEvent:showMerchant()
	openWindowAbove(MerchantWindow:new{goods=self.goods,cardRemoval=self.cardRemoval,event=self})
end

function MerchantEvent:tryRestock(type,item)
	if not hasRelic(TheCourier) then
		return
	end

	local result = nil
	local random = self.random
	if type == 'card' then
		if item.colorName == 'colorless' then
			local card = getColorlessCardType(random,generateColorlessCardRarity(random)):new()
			result = CardItem:new({card=card,x=120,y=-40,isNotInHand=true,basePrice=cardPrice[card.rarity]*random:randFloat(0.9,1.1)*1.2})
			player:triggerEvent('onPreviewObtainCard',card)
		else
			local cardType = getPlayerCardType(random,generateCardRarity(random),item.type)
			if cardType == nil then
				cardType = getPlayerCardType(random,mapPowerRarity[generateCardRarity(random)],item.type)
			end
			result = CardItem:new({card=cardType:new(),x=120,y=-40,isNotInHand=true,basePrice=cardPrice[cardType.rarity]*random:randFloat(0.9,1.1)})
			player:triggerEvent('onPreviewObtainCard',result.card)
		end

	elseif type == 'relic' then
		local relic = getRelicTypeByTier(self:rollRelicTier()):new()
		relic.basePrice = relicPrice[relic.tier]*random:randFloat(0.95,1.05)
		result = relic

	elseif type == 'potion' then
		local potion = getRandomPotionType(random):new()
		potion.basePrice = potionPrice[potion.rarity]*random:randFloat(0.95,1.05)
		result = potion
	end

	if result then
		self:modifyPrice(result,type)
		return result
	end
end

-- window
---@class MerchantWindow : Window
---@field goods {card1:any[],card2:any[],relics:any[],potions:any[]}?
---@field cardRemoval {price:number,sold:boolean}?
MerchantWindow = {name='MerchantWindow',goods=nil,cardRemoval=nil,selectionType='card1',event=nil,selection=0,yOffset=-136}
Window:new(MerchantWindow)

function MerchantWindow:onOpen()
	queueSync(2,currentEvent.spriteBank)
	queueSync(1,player.tileBank)
end

function MerchantWindow:tick()
	sprmap(32,34,28,17,16,self.yOffset,0)
	self:drawGoods()
	self.yOffset = lerp(self.yOffset,0,0.2)
	self:merchantControls()
	tickEffects()
	tickTopBar(true)
end

local function drawPrice(x,y,price)
	local str = tostring(price)
	printGlowed(str,x-strWidth(str)/2,y,price > gold and 2 or 4)
end

function MerchantWindow:drawGoods()
	for i,cardItem in ipairs(self.goods.card1) do
		if not cardItem.sold then
			cardItem.tx = -6+i*42
			cardItem.ty = 44+self.yOffset
			if self.selectionType ~= 'card1' or i ~= self.selection then
				cardItem.large = false
				cardItem:tick()
				if cardItem.sale then
					spr(411,cardItem.x+10,cardItem.y-18,0,1,0,0,2,2)
				end
				drawPrice(cardItem.tx,cardItem.ty+22,cardItem.price)
			end
		end
	end

	for i,cardItem in ipairs(self.goods.card2) do
		if not cardItem.sold then
			cardItem.tx = -6+i*42
			cardItem.ty = 100+self.yOffset
			if self.selectionType ~= 'card2' or i ~= self.selection then
				cardItem.large = false
				cardItem:tick()
				drawPrice(cardItem.tx,cardItem.ty+22,cardItem.price)
			end
		end
	end

	for i,relic in ipairs(self.goods.relics) do
		if not relic.sold then
			local x = 90+24*i
			local y = 80+self.yOffset
			relic:drawImage(x,y,true)
			drawPrice(x+4,y+10,relic.price)
		end
	end

	for i,potion in ipairs(self.goods.potions) do
		if not potion.sold then
			local x = 90+24*i
			local y = 108+self.yOffset
			potion:drawImage(90+24*i,y)
			drawPrice(x+4,y+10,potion.price)
		end
	end

	local cardRemovalY = 80+self.yOffset
	sprmap(0,34,4,5,188,cardRemovalY)
	if self.cardRemoval.sold then
		printShadowed('Sold',204-strWidth('Sold')/2,cardRemovalY+10,4)
		printShadowed('Out',204-strWidth('Out')/2,cardRemovalY+20,4)
	else
		printShadowed('Card',204-strWidth('Card',false,true)/2,cardRemovalY+6,4,nil,1,true)
		printShadowed('Removal',204-strWidth('Removal',false,true)/2,cardRemovalY+16,4,nil,1,true)
		printShadowed('Service',204-strWidth('Service',false,true)/2,cardRemovalY+26,4,nil,1,true)
		drawPrice(204,cardRemovalY+42,self.cardRemoval.price)
	end

	if self.selectionType == 'card1' and self.selection > 0 and self.selection <= #self.goods.card1 then
		local cardItem = self.goods.card1[self.selection]
		if not cardItem.sold then
			cardItem.large = true
			cardItem:tick()
			if cardItem.sale then
				spr(411,cardItem.x+22,cardItem.y-26,0,1,0,0,2,2)
			end
			drawPrice(cardItem.tx,cardItem.ty+22,cardItem.price)
		end
	elseif self.selectionType == 'card2' and self.selection > 0 and self.selection <= #self.goods.card2 then
		local cardItem = self.goods.card2[self.selection]
		if not cardItem.sold then
			cardItem.large = true
			cardItem:tick()
			drawPrice(cardItem.tx,cardItem.ty+22,cardItem.price)
		end
	elseif self.selectionType == 'relic' and self.selection > 0 then
		local x = 90+24*self.selection
		local y = 80+self.yOffset
		drawSelectionBox(x-2,y-2,12,12,12)
		drawItemTooltip(self.goods.relics[self.selection],x-82,y+10,nil,true)
	elseif self.selectionType == 'potion' and self.selection > 0 then
		local x = 90+24*self.selection
		local y = 108+self.yOffset
		drawSelectionBox(x-2,y-2,12,12,12)
		drawItemTooltip(self.goods.potions[self.selection],x-82,y+10,nil,true)
	elseif self.selectionType == 'cardRemoval' and not self.cardRemoval.sold then
		drawSelectionBox(186,cardRemovalY-2,36,44,12)
	end
end

function MerchantWindow:merchantControls()
	if cursorOnTopBar then
		if self.selectionType ~= 'topbar' then
			self.selectionType = 'topbar'
		end
		return
	elseif self.selectionType == 'topbar' then
		self.selectionType = 'card1'
	end

	if btnp(5) then
		self:close()
		return
	end

	local function isNotSold(i,t) return t[i] and not t[i].sold end
	if self.selectionType == 'card1' then
		if self.selection == 0 and #self.goods.card1 > 0 then
			self.selection = nextOrOtherIndexInTableIf(self.goods.card1,self.selection,isNotSold)
			if self.selection == 0 then
				self.selectionType = 'card2'
				return
			end
		end

		if btnp(1) then
			if self.selection < 3 then
				self.selectionType = 'card2'
				if not isNotSold(self.selection,self.goods.card2) then
					self.selection = 0
				end
			elseif self.selection < 5 then
				self.selectionType = 'relic'
				self.selection = self.selection == 3 and 1 or 3
				if not isNotSold(self.selection,self.goods.relics) then
					self.selection = 0
				end
			else
				if not self.cardRemoval.sold then
					self.selectionType = 'cardRemoval'
				end
			end
		elseif btnp(2) then
			self.selection = previousOrOtherIndexInTableIf(self.goods.card1,self.selection,isNotSold)
		elseif btnp(3) then
			self.selection = nextOrOtherIndexInTableIf(self.goods.card1,self.selection,isNotSold)
		elseif btnp(4) then
			local cardItem = self.goods.card1[self.selection]
			if not cardItem.sold and cardItem.price <= gold then
				loseGold(cardItem.price)
				cardItem.large = false
				addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=1,duration=20,tx=240,ty=0})
				obtainCard(cardItem.card)
				self.goods.card1[self.selection] = self.event:tryRestock('card',cardItem.card) or {sold=true}
				if self.goods.card1[self.selection].sold then
					self.selection = 0
				end
			end
		end
	elseif self.selectionType == 'card2' then
		if self.selection == 0 and #self.goods.card2 > 0 then
			self.selection = nextOrOtherIndexInTableIf(self.goods.card2,self.selection,isNotSold)
			if self.selection == 0 then
				self.selectionType = 'relic'
				return
			end
		end

		if btnp(0) then
			self.selectionType = 'card1'
			if not isNotSold(self.selection,self.goods.card1) then
				self.selection = 0
			end
		elseif btnp(2) then
			self.selection = previousOrOtherIndexInTableIf(self.goods.card2,self.selection,isNotSold)
		elseif btnp(3) then
			local oldSelection = self.selection
			self.selection = nextOrOtherIndexInTableIf(self.goods.card2,self.selection,isNotSold)
			if oldSelection == self.selection then
				self.selectionType = 'relic'
				self.selection = 0
			end
		elseif btnp(4) then
			local cardItem = self.goods.card2[self.selection]
			if not cardItem.sold and cardItem.price <= gold then
				loseGold(cardItem.price)
				cardItem.large = false
				addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=1,duration=20,tx=240,ty=0})
				obtainCard(cardItem.card)
				self.goods.card2[self.selection] = self.event:tryRestock('card',cardItem.card) or {sold=true}
				if self.goods.card2[self.selection].sold then
					self.selection = 0
				end
			end
		end
	elseif self.selectionType == 'relic' then
		if self.selection == 0 and #self.goods.relics > 0 then
			self.selection = nextOrOtherIndexInTableIf(self.goods.relics,self.selection,isNotSold)
			if self.selection == 0 then
				self.selectionType = 'potion'
				return
			end
		end

		if btnp(0) then
			self.selectionType = 'card1'
			self.selection = self.selection < 3 and 3 or 4
			if not isNotSold(self.selection,self.goods.card1) then
				self.selection = 0
			end
		elseif btnp(1) then
			self.selectionType = 'potion'
			if not isNotSold(self.selection,self.goods.potions) then
				self.selection = 0
			end
		elseif btnp(2) then
			local oldSelection = self.selection
			self.selection = previousOrOtherIndexInTableIf(self.goods.relics,self.selection,isNotSold)
			if oldSelection == self.selection then
				self.selectionType = 'card2'
				self.selection = nextOrOtherIndexInTableIf(self.goods.card2,#self.goods.card2,isNotSold)
			end
		elseif btnp(3) then
			local oldSelection = self.selection
			self.selection = nextOrOtherIndexInTableIf(self.goods.relics,self.selection,isNotSold)
			if oldSelection == self.selection then
				self.selectionType = 'cardRemoval'
			end
		elseif btnp(4) then
			local relic = self.goods.relics[self.selection]
			if not relic.sold and relic.price <= gold then
				loseGold(relic.price)
				relic.price = nil
				relic.basePrice = nil
				obtainRelic(relic)
				self.goods.relics[self.selection] = self.event:tryRestock('relic',relic) or {sold=true}
				if self.goods.relics[self.selection].sold then
					self.selection = 0
				end
			end
		end
	elseif self.selectionType == 'potion' then
		if self.selection == 0 and #self.goods.potions > 0 then
			self.selection = nextOrOtherIndexInTableIf(self.goods.potions,self.selection,isNotSold)
			if self.selection == 0 then
				self.selectionType = 'cardRemoval'
				return
			end
		end

		if btnp(0) then
			self.selectionType = 'relic'
			if not isNotSold(self.selection,self.goods.relics) then
				self.selection = 0
			end
		elseif btnp(2) then
			local oldSelection = self.selection
			self.selection = previousOrOtherIndexInTableIf(self.goods.potions,self.selection,isNotSold)
			if oldSelection == self.selection then
				self.selectionType = 'card2'
				self.selection = nextOrOtherIndexInTableIf(self.goods.card2,#self.goods.card2,isNotSold)
			end
		elseif btnp(3) then
			local oldSelection = self.selection
			self.selection = nextOrOtherIndexInTableIf(self.goods.potions,self.selection,isNotSold)
			if oldSelection == self.selection then
				self.selectionType = 'cardRemoval'
			end
		elseif btnp(4) then
			local potion = self.goods.potions[self.selection]
			if not potion.sold and potion.price <= gold and obtainPotion(potion) then
				loseGold(potion.price)
				potion.price = nil
				potion.basePrice = nil
				self.goods.potions[self.selection] = self.event:tryRestock('potion',potion) or {sold=true}
				if self.goods.potions[self.selection].sold then
					self.selection = 0
				end
			end
		end
	elseif self.selectionType == 'cardRemoval' then
		if self.cardRemoval.sold then
			self.selectionType = 'card1'
			self.selection = 0
			return
		end

		if btnp(0) then
			self.selectionType = 'card1'
			self.selection = 5
			if not isNotSold(self.selection,self.goods.card1) then
				self.selection = 0
			end
		elseif btnp(2) then
			self.selectionType = 'relic'
			self.selection = nextOrOtherIndexInTableIf(self.goods.relics,#self.goods.relics,isNotSold)
		elseif btnp(4) then
			if not self.cardRemoval.sold and self.cardRemoval.price <= gold then
				removeCardFromDeck(1,true,function (completed)
					if completed then
						loseGold(self.cardRemoval.price)
						self.cardRemoval.sold = true
						self.selection = 0
						shopRemoveCount = shopRemoveCount + 1
					end
				end)
			end
		end

	end
end
