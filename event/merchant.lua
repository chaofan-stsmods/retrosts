-- merchant
---@diagnostic disable: lowercase-global

MerchantEvent = Event:new{screen='entry',spritebank=2,random=nil,goods=nil,cardRemoval=nil}
function MerchantEvent:new()
	local o = Event.new(self)
	o.random = makeRand(act.id,room.id,1)
	table.insert(o.options,{description='[Talk]'})
	table.insert(o.options,{description='[Leave]'})
	o:generateGoods()
	return o
end

function MerchantEvent:drawBackground()
	act:drawBackground()
	player:drawImage()
	sprmap(25,45,7,4,130,64,0)
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
local mapPowerRarity = {common='uncommon',uncommon='rare',rare='rare'}
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
		card1[i] = CardItem:new({card=card,isNotInHand=true,basePrice=cardPrice[card.rarity]*random:randFloat(0.9,1.1)})
	end

	local saleCardItem = card1[random:randInt(#card1)]
	saleCardItem.sale = true
	saleCardItem.basePrice = saleCardItem.basePrice / 2

	for i,playerCardType in ipairs(card2) do
		local card = playerCardType:new()
		card2[i] = CardItem:new({card=card,isNotInHand=true,basePrice=cardPrice[card.rarity]*random:randFloat(0.9,1.1)*1.2})
	end

	for i=1,3 do
		local tier
		if i<3 then
			local roll = random:randInt(0,99)
			tier = roll < 48 and 'common' or (roll < 82 and 'uncommon' or 'rare')
		else
			tier = 'shop'
		end
		local relic = getRelicTypeByTier(tier):new()
		relic.basePrice = relicPrice[relic.tier]*random:randFloat(0.95,1.05)
		relics[i] = relic
	end

	for i=1,3 do
		potion = getRandomPotionType(random)
		potion.basePrice = potionPrice[potion.rarity]*random:randFloat(0.95,1.05)
		potions[i] = potion
	end

	self.goods = goods
	self:modifyPrices()

	self.cardRemoval = {price=self:getCardRemovalPrice(),sold=false}
end

function MerchantEvent:modifyPrices()
	local card1,card2,relics,potions = self.goods.card1,self.goods.card2,self.goods.relics,self.goods.potions
	for _, item in ipairs(card1) do
		self:modifyPrice(item)
	end
	for _, item in ipairs(card2) do
		self:modifyPrice(item)
	end
	for _, item in ipairs(relics) do
		self:modifyPrice(item)
	end
	for _, item in ipairs(potions) do
		self:modifyPrice(item)
	end
end

function MerchantEvent:modifyPrice(item)
	local price = item.basePrice
	if ascension >= 16 then
		price = price * 1.1
	end
	item.price = math.floor(price+0.5)
end

function MerchantEvent:getCardRemovalPrice()
	return shopRemoveCount*25+75
end

function MerchantEvent:showMerchant()
	openWindowAbove(MerchantWindow:new{goods=self.goods,cardRemoval=self.cardRemoval})
end

-- window
MerchantWindow = Window:new{name='MerchantWindow',goods=nil,cardRemoval=nil}
function MerchantWindow:onOpen()
	queueSync(4,1)
	queueSync(2,currentEvent.spritebank)
	queueSync(1,player.tileBank)
end

function MerchantWindow:tick()
	sprmap(32,34,28,17,16,0,0)

	for i,cardItem in ipairs(self.goods.card1) do
		cardItem.tx = -6+i*42
		cardItem.ty = 44
		cardItem:tick()
		local str = tostring(cardItem.price)
		printGlowed(str,cardItem.tx-strWidth(str)/2,66,4)
	end

	for i,cardItem in ipairs(self.goods.card2) do
		cardItem.tx = -6+i*42
		cardItem.ty = 100
		cardItem:tick()
		local str = tostring(cardItem.price)
		printGlowed(str,cardItem.tx-strWidth(str)/2,122,4)
	end

	for i,relic in ipairs(self.goods.relics) do
		local x = 90+24*i
		local y = 80
		relic:drawImage(x,y,true)
		local str = tostring(relic.price)
		printGlowed(str,x+4-strWidth(str)/2,y+10,4)
	end

	for i,potion in ipairs(self.goods.potions) do
		local x = 90+24*i
		local y = 108
		potion:drawImage(90+24*i,y)
		local str = tostring(potion.price)
		printGlowed(str,x+4-strWidth(str)/2,y+10,4)
	end

	sprmap(0,34,4,5,188,80)
	printShadowed('Card',204-strWidth('Card',false,true)/2,86,12,nil,1,true)
	printShadowed('Removal',204-strWidth('Removal',false,true)/2,96,12,nil,1,true)
	printShadowed('Service',204-strWidth('Service',false,true)/2,106,12,nil,1,true)
	local str = tostring(self.cardRemoval.price)
	printGlowed(str,204-strWidth(str)/2,122,4)

	if btnp(5) then
		self:close()
	end
	
	tickEffects()
	tickTopBar(true)
end
