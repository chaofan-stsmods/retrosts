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

NeowEvent = Event:new{screen='entry',spritebank=0,words='Greetings...',random=nil}
function NeowEvent:new(random)
	local o = Event.new(self)
	o.random = random
	table.insert(o.options,{description='[Talk]'})
	return o
end

function NeowEvent:drawBackground()
	act:drawBackground()
	player:drawImage()
	sprmap(16,34,13,10,136,16)
	drawTalkBubble(self.words,85,46,50,31,140,78,12,15)
end

function NeowEvent:onOption(selection)
	if self.screen == 'entry' then
		self.screen = 'rewards'
		self.words = 'Choose...'
		self.options = {}
		self.selectedOption = 0
		generateNeowRewards(self.options,self.random)
	elseif self.screen == 'rewards' then
		self.words = 'Granted...'
		self.options[self.selectedOption].onSelect()
		self.screen = 'exit'
		self.options = {}
		self.selectedOption = 0
		table.insert(self.options,{description='[Leave]'})
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

function generateNeowRewards(options,random)
	local oid = random:randInt(6)
	local option
	if oid == 1 then
		option = {description='[ #5#Choose a card to obtain #12#]',onSelect=function ()
			local cards = table.map(generateCardTypesForReward(3,random,false,function () return random:rand() < 0.33 and 'uncommon' or 'common' end),
				function (cardType) return cardType:new() end)
			openWindowAbove(CardRewardWindow:new{cards=cards,canClose=false}, function (cardItem)
				if cardItem then
					cardItem.large = false
					addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=1,duration=20,tx=240,ty=0})
					table.insert(deck,cardItem.card)
				end
			end)
		end}
	elseif oid == 2 then
		option = {description='[ #5#Obtain a random rare card #12#]',onSelect=function ()
			local card = getPlayerCardTypeByRarity('rare',random):new()
			local cardItem = CardItem:new{card=card,x=0,y=136,tx=120,ty=68,isNotInHand=true}
			addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=30,duration=50,tx=240,ty=0})
			table.insert(deck,cardItem.card)
		end}
	elseif oid == 3 then
		option = {description='[ #5#Remove a card from your deck #12#]',onSelect=function ()
			removeCardFromDeck(1)
		end}
	elseif oid == 4 then
		option = {description='[ #5#Upgrade a card #12#]',onSelect=function ()
			upgradeCardFromDeck(1)
		end}
	elseif oid == 5 then
		option = {description='[ #5#Transform a card #12#]',onSelect=function ()
			transformCardFromDeck(1,random)
		end}
	elseif oid == 6 then
		option = {description='[ #5#Choose a colorless card to obtain #12#]',onSelect=function ()
			-- TODO
			local cards = table.map(generateCardTypesForReward(3,random,false,function () return random:rand() < 0.33 and 'uncommon' or 'common' end),
				function (cardType) return cardType:new() end)
			openWindowAbove(CardRewardWindow:new{cards=cards,canClose=false}, function (cardItem)
				if cardItem then
					cardItem.large = false
					addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=1,duration=20,tx=240,ty=0})
					table.insert(deck,cardItem.card)
				end
			end)
		end}
	end
	options[1] = option

	oid = random:randInt(5)
	if oid == 1 then
		option = {description='[ #5#Obtain 3 random potions #12#]',onSelect=function ()
		end}
	elseif oid == 2 then
		option = {description='[ #5#Obtain a random common relic #12#]',onSelect=function ()
			obtainRelic(getRelicTypeByTier('common'):new())
		end}
	elseif oid == 3 then
		local maxHp = math.floor(player.maxHp/10)
		option = {description='[ #5#Max HP +'..maxHp..' #12#]',onSelect=function ()
			player:increaseMaxHp(maxHp)
		end}
	elseif oid == 4 then
		option = {description='[ #5#Enemies in your next three combats have 1 HP #12#]',onSelect=function ()
			obtainRelic(NeowsLament:new())
		end}
	elseif oid == 5 then
		option = {description='[ #5#Obtain 100 gold #12#]',onSelect=function ()
			gold = gold + 100
		end}
	end
	options[2] = option

	local nid = random:randInt(4)
	local negative
	if nid == 1 then
		local maxHp = math.floor(player.maxHp/10)
		negative = {description='[ #3#Lose '..maxHp..' max HP ',onSelect=function ()
			player:decreaseMaxHp(maxHp)
		end}
	elseif nid == 2 then
		negative = {description='[ #3#Lose all gold ',onSelect=function ()
			gold = 0
		end}
	elseif nid == 3 then
		negative = {description='[ #3#Obtain a curse ',onSelect=function ()
			-- TODO curse
			local card = Wound:new()
			local cardItem = CardItem:new{card=card,x=0,y=136,tx=120,ty=68,isNotInHand=true}
			addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=30,duration=50,tx=240,ty=0})
			table.insert(deck,cardItem.card)
		end}
	elseif nid == 4 then
		local damage = math.floor(player.hp/10)*3
		negative = {description='[ #3#Take '..damage..' damage ',onSelect=function ()
			player:damage(player,damage,'hpLoss')
		end}
	end

	oid = random:randInt(nid == 4 and 7 or 6)
	if nid ~= 4 and oid >= nid + 4 then
		old = oid + 1
	end
	if oid == 1 then
		option = {description='#5#Choose a rare colorless card to obtain #12#]',onSelect=function ()
			-- TODO colorless
			local cards = table.map(generateCardTypesForReward(3,random,false,function () return 'rare' end),
				function (cardType) return cardType:new() end)
			openWindowAbove(CardRewardWindow:new{cards=cards,canClose=false}, function (cardItem)
				if cardItem then
					cardItem.large = false
					addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=1,duration=20,tx=240,ty=0})
					table.insert(deck,cardItem.card)
				end
			end)
		end}
	elseif oid == 2 then
		option = {description='#5#Obtain a random rare relic #12#]',onSelect=function ()
			obtainRelic(getRelicTypeByTier('rare'):new())
		end}
	elseif oid == 3 then
		option = {description='#5#Choose a rare card to obtain #12#]',onSelect=function ()
			local cards = table.map(generateCardTypesForReward(3,random,false,function () return 'rare' end),
				function (cardType) return cardType:new() end)
			openWindowAbove(CardRewardWindow:new{cards=cards,canClose=false}, function (cardItem)
				if cardItem then
					cardItem.large = false
					addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=1,duration=20,tx=240,ty=0})
					table.insert(deck,cardItem.card)
				end
			end)
		end}
	elseif oid == 4 then
		option = {description='#5#Transform 2 cards #12#]',onSelect=function ()
			transformCardFromDeck(2,random)
		end}
	elseif oid == 5 then
		local maxHp = math.floor(player.maxHp/10)*2
		option = {description='#5#Max HP +'..maxHp..' #12#]',onSelect=function ()
			player:increaseMaxHp(maxHp)
		end}
	elseif oid == 6 then
		option = {description='#5#Obtain 250 gold #12#]',onSelect=function ()
			gold = gold + 250
		end}
	elseif oid == 7 then
		option = {description='#5#Remove 2 cards #12#]',onSelect=function ()
			removeCardFromDeck(2)
		end}
	end
	
	options[3] = {description=negative.description..option.description,onSelect=function ()
		negative.onSelect()
		option.onSelect()
	end}

	options[4] = {description='[ #3#Lose your starting relic #5#Obtain a random boss relic #12#]',onSelect=function ()
		table.remove(relics,1)
		obtainRelic(getRelicTypeByTier('boss'):new())
	end}
end

function removeCardFromDeck(amount)
	local cardItems = table.map(deck, function (card) return CardItem:new{card=card,x=240,y=0,isNotInHand=true} end)
	local gridView = CardGridSelectWindow:new{title='Choose a Card to Remove',cardItems=cardItems,min=amount,max=amount}
	if amount > 1 then
		gridView.title = 'Choose Cards to Remove ({#}/'..amount..')'
	end
	openWindowAbove(gridView, function (cards)
		local startX,stepX = placeCardsInARow(#cards)
		for i, cardItem in ipairs(cards) do
			table.remove(deck,table.indexOf(deck,cardItem.card))
			cardItem.tx = startX+stepX*i
			cardItem.ty = 68
			cardItem.large = false
			addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=10,duration=30,tx=120,ty=-30})
		end
	end)
end

function upgradeCardFromDeck(amount)
	local cardItems = table.map(deck, function (card) return CardItem:new{card=card,x=240,y=0,isNotInHand=true} end)
	table.retainIf(cardItems,function (cardItem) return cardItem.card:canUpgrade() end)
	local gridView = CardGridSelectWindow:new{title='Choose a Card to Upgrade',cardItems=cardItems,min=amount,max=amount}
	if amount > 1 then
		gridView.title = 'Choose Cards to Upgrade ({#}/'..amount..')'
	end
	openWindowAbove(gridView, function (cards)
		local startX,stepX = placeCardsInARow(#cards)
		for i, cardItem in ipairs(cards) do
			cardItem.tx = startX+stepX*i
			cardItem.ty = 68
			cardItem.large = false
			addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=30,duration=50,tx=120,ty=-30})
			addEffect(AnonymousEffect:new{duration=10,callback=function (duration)
				if duration == 1 then
					cardItem.card:upgrade()
				end
			end})
		end
	end)
end

function transformCardFromDeck(amount,random)
	local cardItems = table.map(deck, function (card) return CardItem:new{card=card,x=240,y=0,isNotInHand=true} end)
	local gridView = CardGridSelectWindow:new{title='Choose a Card to Transform',cardItems=cardItems,min=amount,max=amount}
	if amount > 1 then
		gridView.title = 'Choose Cards to Transform ({#}/'..amount..')'
	end
	openWindowAbove(gridView, function (cards)
		-- TODO color less
		local playerCardTypes = shallowcopy(player:getCards())
		table.retainIf(playerCardTypes,function (card) return card.rarity == 'common' or card.rarity == 'uncommon' or card.rarity == 'rare' end)
		local startX,stepX = placeCardsInARow(#cards)
		for i, cardItem in ipairs(cards) do
			local thisCardTypes = shallowcopy(playerCardTypes)
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
	end)
end
