-- reward
---@diagnostic disable: lowercase-global

RewardWindow = Window:new{rewards=nil,selection=0,title='Rewards',canClose=false,name='RewardWindow'}
function RewardWindow:onOpen()
	queueSync(2,0)
	queueSync(4,1)
	queueSync(1,player.tileBank)
end

function RewardWindow:tick()
	sprmap(0,36,12,13,72,26,0)
	sprmap(0,34,16,2,56,18,0)
	printGlowed(self.title,120-strWidth(self.title)/2,21,12)
	self:drawRewards()
	self:rewardControls()
	tickEffects()
	tickTopBar(true)
end

function RewardWindow:drawRewards()
	for i, reward in ipairs(self.rewards) do
		local y = 16+i*18
		if self.selection == i then
			mapColor(14,13)
		end
		sprmap(0,49,11,2,76,y,0)
		if self.selection == i then
			resetColor(14)
		end
		if reward.type == 'potion' then
			reward.value:drawImage(79,y+4)
		else
			spr(reward.icon,79,y+4,0)
		end
		print(reward.title,90,y+5,12,false,1,true)
	end
end

function RewardWindow:rewardControls()
	if cursorOnTopBar then
		self.selection = 0
		return
	end

	if self.selection == 0 and #self.rewards > 0 then
		self.selection = limit(self.selection,1,#self.rewards)
	end

	if #self.rewards > 0 then
		if btnp(0) then
			self.selection = limit(self.selection-1,1,#self.rewards)
		elseif btnp(1) then
			self.selection = limit(self.selection+1,1,#self.rewards)
		end
	end

	if btnp(4) then
		self:collectReward()
	elseif btnp(5) and self.canClose then
		self:close()
	elseif btnp(7) then
		self:onProceed()
	end
end

function RewardWindow:collectReward()
	if self.selection == 0 then
		return
	end

	local reward = self.rewards[self.selection]
	if reward.type == 'gold' then
		gold = gold + reward.value
		self:collectRewardComplete()
	elseif reward.type == 'key' then
		_G[reward.value] = true
		self:collectRewardComplete()
	elseif reward.type == 'card' then
		openWindowAbove(CardRewardWindow:new{cards=reward.value},function (cardItem)
			if cardItem then
				cardItem.large = false
				addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=1,duration=20,tx=240,ty=0})
				table.insert(deck,cardItem.card)
				self:collectRewardComplete()
			end
		end)
	elseif reward.type == 'relic' then
		obtainRelic(reward.value)
		self:collectRewardComplete()
	elseif reward.type == 'potion' then
		if obtainPotion(reward.value) then
			self:collectRewardComplete()
		end
	end
end

function RewardWindow:collectRewardComplete()
	table.remove(self.rewards,self.selection)
	if #self.rewards == 0 then
		self.selection = 0
		self:onComplete()
	else
		self.selection = limit(self.selection,1,#self.rewards)
	end
end

function RewardWindow:onComplete()
	self:onProceed()
end

function RewardWindow:onProceed()
	openWindowAbove(MapWindow:new())
end

-- generate

function generateRewards(random)
	local rewards = {}
	generateGoldReward(rewards,random)
	generateCardRewards(rewards,random)
	generateRelicRewards(rewards,random)
	--table.insert(rewards,{title='Sapphire key',icon=463,type='key',value='sapphireKeyObtained'})
	return rewards
end

function generateGoldReward(rewards,random)
	local gold = nil
	if room.type == 'monster' then
		gold = random:randInt(10,20)
	elseif room.type == 'elite' then
		gold = random:randInt(25,35)
	elseif room.type == 'boss' then
		gold = random:randInt(95,105)
	end
	if gold then
		table.insert(rewards,{title=gold..' Gold',icon=7,type='gold',value=gold})
	end
end

local rareCardRandOffset = 5
local initRareCardRandOffset = 5
local rareCardRandOffsetGrow = -1
local minRareCardRandOffset = -40
function resetCardRewardGenerator()
	rareCardRandOffset = initRareCardRandOffset
end

function getPlayerCardTypeByRarity(rarity,random)
	local allCardTypes = shallowcopy(player:getCards())
	table.retainIf(allCardTypes,function (cardType) return cardType.rarity == rarity end)
	return allCardTypes[random:randInt(#allCardTypes)]
end

function getCurseCardType(random)
	local allCardTypes = shallowcopy(getCurseCards())
	table.retainIf(allCardTypes,function (cardType) return cardType.rarity ~= 'special' end)
	return allCardTypes[random:randInt(#allCardTypes)]
end

function generateCardTypesForReward(cardCount,random,affectRareChance,cardRaritygenerator,cardSet)
	cardSet = cardSet or player:getCards()
	cardRaritygenerator = cardRaritygenerator or generateCardRarity
	local cardTypes = {}
	for _=1,cardCount do
		local rarity = cardRaritygenerator(random)
		if affectRareChance then
			if rarity == 'rare' then
				rareCardRandOffset = initRareCardRandOffset
			elseif rarity == 'common' then
				rareCardRandOffset = math.max(rareCardRandOffset+rareCardRandOffsetGrow,minRareCardRandOffset)
			end
		end
		local allCardTypes = shallowcopy(cardSet)
		table.retainIf(allCardTypes,function (cardType) return cardType.rarity == rarity end)
		local cardType
		repeat
			cardType = allCardTypes[random:randInt(#allCardTypes)]
		until table.indexOf(cardTypes,cardType) == nil
		table.insert(cardTypes,cardType)
	end
	return cardTypes
end

function generateCardRewards(rewards,random)
	local cardCount = 3
	local cardTypes = generateCardTypesForReward(cardCount,random,true)

	local reward = {
		title='Add a card to deck',
		icon=room.type == 'boss' and 447 or 431,
		type='card',
		value={}
	}
	for i, cardType in ipairs(cardTypes) do
		local card = cardType:new()
		reward.value[i] = card
		if card.rarity ~= 'rare' and card:canUpgrade() and random:rand() < act.cardUpgradedChance then
			card:upgrade()
			card:resetPowers()
		end
	end

	table.insert(rewards,reward)
end

function generateCardRarity(random)
	local roll = random:randInt(0,99)+rareCardRandOffset
	local rareCardChance = 3
	local uncommonCardChance = 37
	if room.type == 'boss' then
		rareCardChance = 999
	elseif room.type == 'elite' then
		rareCardChance = 10
		uncommonCardChance = 40
	elseif room.type == 'shop' then
		rareCardChance = 9
	end
	if roll < rareCardChance then
		return 'rare'
	elseif roll < rareCardChance + uncommonCardChance then
		return 'uncommon'
	else
		return 'common'
	end
end

local fallbackTiers = {common='uncommon',uncommon='rare',shop='uncommon'}
function generateRelicRewards(rewards,random)
	if room.type ~= 'elite' then
		return
	end

	local roll = random:randInt(0,99)
	local tier = 'uncommon'
	if roll < 50 then
		tier = 'common'
	elseif roll > 82 then
		tier = 'rare'
	end

	local relic = getRelicTypeByTier(tier):new()
	table.insert(rewards,{title=relic.name,icon=relic.icon,type='relic',value=relic})

	if room.hasKey then
		table.insert(rewards,{title='Emerald key',icon=462,type='key',value='emeraldKeyObtained'})
	end
end

function getRelicTypeByTier(tier)
	local relic
	repeat
		while tier ~= nil and #relicPools[tier] == 0 do
			tier = fallbackTiers[tier]
		end
		if tier == nil then
			relic = Circlet
		else
			relic = table.remove(relicPools[tier],#relicPools[tier])
		end
	until relic:canSpwan()
	return relic
end

-- cardselect
CardRewardWindow = Window:new{name='CardRewardWindow',cards=nil,selection=0,single=false,canClose=true}
function CardRewardWindow:onOpen()
	queueSync(2,0)
	queueSync(4,1)
	queueSync(1,player.tileBank)
	local replace = false
	for i, card in ipairs(self.cards) do
		if getmetatable(card) ~= CardItem then
			if not replace then
				replace = true
				self.cards = shallowcopy(self.cards)
			end
			self.cards[i] = CardItem:new{x=120,y=68,tx=120,ty=68,card=card,isNotInHand=true}
		end
	end
end

function CardRewardWindow:tick()
	sprmap(0,34,16,2,56,18,0)
	local title = 'Choose a Card'
	local width = strWidth(title)
	printGlowed(title,120-width/2,21,12)
	self:drawCards()
	self:cardRewardControls()
	tickEffects()
	tickTopBar(true)
end

function CardRewardWindow:drawCards()
	local startX = 120-(48*#self.cards-48)/2
	for i, cardItem in ipairs(self.cards) do
		local x = startX-48+i*48
		cardItem.tx = x
		cardItem.large = self.selection==i
		cardItem:tick()
	end
end

function CardRewardWindow:cardRewardControls()
	if cursorOnTopBar then
		self.selection = 0
		return
	end

	if self.selection == 0 and #self.cards > 0 then
		self.selection = limit(self.selection,1,#self.cards)
	end

	if #self.cards > 0 then
		if btnp(2) then
			self.selection = limit(self.selection-1,1,#self.cards)
		elseif btnp(3) then
			self.selection = limit(self.selection+1,1,#self.cards)
		end
	end

	if btnp(4) then
		self:close(self.cards[self.selection])
	elseif btnp(5) and self.canClose then
		self:close(nil)
	end
end
