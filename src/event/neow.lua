-- neow
---@diagnostic disable: lowercase-global

NeowEvent = Event:new{screen='intro',spriteBank=3,words='Greetings...',random=nil}
function NeowEvent:init()
	self.random = makeRand(1)
	table.insert(self.options,{description='[Talk]'})
end

function NeowEvent:drawBackground()
	act:drawBackground()
	player:drawImage()
	sprmap(16,34,13,10,136,16,0)
	drawTalkBubble(self.words,85,46,50,31,140,78,12,15)
end

function NeowEvent:onOption(selection)
	if self.screen == 'intro' then
		self.screen = 'rewards'
		self.words = 'Choose...'
		self.options = {}
		self.selectedOption = 0
		generateNeowRewards(self.options,self.random)
	elseif self.screen == 'rewards' then
		self.words = 'Granted...'
		self.options[selection].onSelect()
		self.screen = 'leave'
		self.options = {{description='[Leave]'}}
		self.selectedOption = 0
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
			local card = getPlayerCardType(random,'rare'):new()
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
			local cards = table.map(generateCardTypesForReward(3,random,false,function () return 'uncommon' end,getColorlessCards()),
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
			local rewards = {}
			for i=1,3 do
				local potion = getTrueRandomPotionType(random):new()
				rewards[i] = {type='potion',title=potion.name,value=potion}
			end
			local rewardWindow = RewardWindow:new{rewards=rewards,canClose=true}
			rewardWindow.onProceed = function (self) self:close() end
			openWindowAbove(rewardWindow)
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
			gainGold(100)
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
			loseGold(gold)
		end}
	elseif nid == 3 then
		negative = {description='[ #3#Obtain a curse ',onSelect=function ()
			local card = getCurseCardType(random):new()
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
			local cards = table.map(generateCardTypesForReward(3,random,false,function () return 'rare' end,getColorlessCards()),
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
			gainGold(250)
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
