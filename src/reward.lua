-- reward
---@diagnostic disable: lowercase-global

RewardWindow = Window:new{rewards=nil,selection=0,title='Rewards',canClose=false,name='RewardWindow',single=false}
function RewardWindow:onOpen()
	if roomActionType == 'combat' then
		queueSync(2,combatSpriteBank)
	else
		queueSync(2,currentEvent.spriteBank)
	end
	queueSync(1,player.tileBank)
end

function RewardWindow:tick()
	rect(72,26,96,96,15)
	rect(80,122,80,6,15)
	spr(500,72,122,0)
	spr(500,160,122,0,1,1)
	drawBanner(56,18,16)
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
			if reward.type == 'potion' or reward.type == 'relic' then
				drawItemTooltip(reward.value,168,34,9)
			end
			mapColor(14,13)
		end
		spr(470,76,y,0)
		spr(470,76,y+8,0,1,2)
		spr(470,156,y,0,1,1)
		spr(470,156,y+8,0,1,3)
		rect(84,y+1,72,14,14)
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
		if reward.showLink then
			spr(466,116,y-5,0)
		end
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
		gainGold(reward.value)
		self:collectRewardComplete()
	elseif reward.type == 'key' then
		_G[reward.value] = true
		self:collectRewardComplete()
	elseif reward.type == 'card' then
		openWindowAbove(CardRewardWindow:new{cards=reward.value},function (cardItem)
			if cardItem then
				cardItem.large = false
				addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=1,duration=20,tx=240,ty=0})
				obtainCard(cardItem.card)
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
	local reward = table.remove(self.rewards,self.selection)
	if reward.link then
		local linkIndex = table.indexOf(self.rewards,reward.link)
		if linkIndex then
			table.remove(self.rewards,linkIndex)
		end
	end
	if #self.rewards == 0 then
		self.selection = 0
		self:onComplete()
	else
		self.selection = limit(self.selection,1,#self.rewards)
	end
end

function RewardWindow:onComplete()
	if nearestWindow ~= self then
		return
	end
	self:onProceed()
end

function RewardWindow:onProceed()
	if room.type == 'boss' then
		act:bossRoomProceed()
		return
	end
	openWindowAbove(MapWindow:new())
end

-- generate

function generateRewards(random)
	local rewards = {}
	generateGoldReward(rewards,random)
	generateStolenGoldReward(rewards)
	generateCardRewards(rewards,random)
	generateRelicRewards(rewards,random)
	generatePotionRewards(rewards,random)
	return rewards
end

function generateGoldReward(rewards,random)
	local amount = nil
	if room.type == 'monster' or room.eventType == 'monster' then
		amount = random:randInt(10,20)
	elseif room.type == 'elite' then
		amount = random:randInt(25,35)
	elseif room.type == 'boss' then
		amount = random:randInt(95,105)
		if ascension >= 13 then
			amount = math.floor(amount*0.75+0.5)
		end
	end
	if amount then
		addGoldReward(rewards,amount)
	end
end

function generateStolenGoldReward(rewards)
	local stolenGold = 0
	for _, enemy in ipairs(enemies) do
		if enemy.goldStolen then
			stolenGold = stolenGold + enemy.goldStolen
		end
	end
	if stolenGold > 0 then
		addGoldReward(rewards,stolenGold,' (Stolen)',false)
	end
end

function addGoldReward(rewards,amount,suffix,bonus)
	bonus = bonus or bonus == nil
	local bonusGold = 0
	if bonus then
		bonusGold = player:triggerReducerEvent('onAddBonusGoldReward',bonusGold,amount)
	end
	bonusGold = math.floor(bonusGold+0.5)
	if bonusGold > 0 then
		table.insert(rewards,{title=amount..'(+'..bonusGold..') Gold'..(suffix or ''),icon=7,type='gold',value=amount+bonusGold})
	else
		table.insert(rewards,{title=amount..' Gold'..(suffix or ''),icon=7,type='gold',value=amount})
	end
end

local rareCardRandOffset = 5
local initRareCardRandOffset = 5
local rareCardRandOffsetGrow = -1
local minRareCardRandOffset = -40
local potionRandOffset = 0
function resetRewardGenerator()
	rareCardRandOffset = initRareCardRandOffset
	potionRandOffset = 0
end

function saveRewardGenerator(index)
	pmem(index,(rareCardRandOffset-minRareCardRandOffset) | ((potionRandOffset+200) << 16))
end

function loadRewardGenerator(index)
	local val32 = pmem(index)
	rareCardRandOffset = (val32 & 0xffff) + minRareCardRandOffset
	potionRandOffset = (val32 >> 16) - 200
end

function getPlayerCardType(random,rarity,type)
	local allCardTypes = shallowcopy(player:getCards())
	table.retainIf(allCardTypes,function (cardType)
		return ((rarity == nil and (cardType.rarity == 'common' or cardType.rarity == 'uncommon' or cardType.rarity == 'rare'))
				or cardType.rarity == rarity) and
			(type == nil or cardType.type == type)
	end)
	return allCardTypes[random:randInt(#allCardTypes)]
end

function getColorlessCardType(random,rarity,type)
	local allCardTypes = shallowcopy(getColorlessCards())
	table.retainIf(allCardTypes,function (cardType)
		return ((rarity == nil and (cardType.rarity == 'common' or cardType.rarity == 'uncommon' or cardType.rarity == 'rare'))
				or cardType.rarity == rarity) and
			(type == nil or cardType.type == type)
	end)
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
	local cardCount = player:triggerReducerEvent('modifyCardRewardCount',3)
	local cardTypes = generateCardTypesForReward(cardCount,random,true)

	local reward = {
		title='Add a card to deck',
		icon=room.type == 'boss' and 465 or 464,
		type='card',
		value={}
	}
	for i, cardType in ipairs(cardTypes) do
		local card = cardType:new()
		reward.value[i] = card
		if card.rarity ~= 'rare' and card:canUpgrade() and random:rand() < act.cardUpgradedChance * (ascension >= 12 and 0.5 or 1) then
			card:upgrade()
			card:resetPowers()
		end
		player:triggerEvent('onPreviewObtainCard',card)
	end

	player:triggerEvent('modifyCardReward',reward)
	table.insert(rewards,reward)
end

function generateColorlessCardRarity(random)
	return random:rand() < 0.3 and 'rare' or 'uncommon'
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
	elseif isInShop() then
		rareCardChance = 9
	end
	rareCardChance = player:triggerReducerEvent('onModifyRareCardChance',rareCardChance)
	if roll < rareCardChance then
		return 'rare'
	elseif roll < rareCardChance + uncommonCardChance then
		return 'uncommon'
	else
		return 'common'
	end
end

local fallbackTiers = {common='uncommon',uncommon='rare',shop='uncommon'}
function getRelicTier(random)
	local roll = random:randInt(0,99)
	local tier = 'uncommon'
	if roll < act.commonRelicChance then
		tier = 'common'
	elseif roll >= act.commonRelicChance + act.uncommonRelicChance then
		tier = 'rare'
	end
	return tier
end

function generateRelicRewards(rewards,random)
	if room.type ~= 'elite' then
		return
	end

	addRelicReward(rewards,getRandomRelic(random):new())

	if room.hasKey then
		table.insert(rewards,{title='Emerald key',icon=467,type='key',value='emeraldKeyObtained'})
	end
end

function addRelicReward(rewards,relic)
	table.insert(rewards,{title=relic.name,icon=relic.icon,type='relic',value=relic})
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

function getRandomRelic(random,tier)
	tier = tier or getRelicTier(random)
	return getRelicTypeByTier(tier):new()
end

function getRandomNonBottleRelic(random,tier)
	tier = tier or getRelicTier(random)
	local relicType
	repeat
		relicType = getRelicTypeByTier(tier)
	until table.indexOf(relicType.tags,'bottle') == nil
	return relicType:new()
end

function generatePotionRewards(rewards,random)
	local chance = 40 + potionRandOffset
	if hasRelic(WhiteBeastStatue) then
		chance = 100
	end

	if #rewards >= 4 then
		chance = 0
	end

	if random:randInt(0,99) < chance then
		local potion = getRandomPotionType(random):new()
		addPotionReward(rewards,potion)
		potionRandOffset = potionRandOffset - 10
	else
		potionRandOffset = potionRandOffset + 10
	end
end

function addPotionReward(rewards,potion)
	table.insert(rewards,{title=potion.name,type='potion',value=potion})
end

-- cardselect
CardRewardWindow = Window:new{name='CardRewardWindow',title='Choose a Card',cards=nil,selection=0,single=false,canClose=true}
function CardRewardWindow:onOpen()
	if roomActionType == 'combat' then
		queueSync(2,combatSpriteBank)
	else
		queueSync(2,currentEvent.spriteBank)
	end
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
	drawBanner(56,18,16)
	local width = strWidth(self.title)
	printGlowed(self.title,120-width/2,21,12)
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
		if self.selection ~= i then
			cardItem.large = false
			cardItem:tick()
		end
	end
	if self.selection <= #self.cards and self.selection > 0 then
		local cardItem = self.cards[self.selection]
		cardItem.large = true
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
