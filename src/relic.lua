-- relic
---@diagnostic disable: lowercase-global

local colorlessRelics

---@class Relic : Object
Relic = {
	name='',description='',counter=-1,saved=0,icon=0,
	tier='common',colorName='colorless',tags={},
	priority=70,onObtained=noop,onLost=noop
}
Object:new(Relic)

function Relic:canSpwan()
	return true
end

function Relic:drawImage(x,y,hideCounter)
	drawIcon(self.icon,x,y)
	if self.counter >= 0 and not hideCounter then
		local counterStr = tostring(self.counter)
		local width = strWidth(counterStr,false,true)
		printGlowed(counterStr,math.min(x+5,x+12-width),y+3,12,15,1,true)
	end
end

function Relic:save()
	local counterPart = self.counter < 0 and 0 or ((self.counter << 1) | 1)
	return (self.saved << 11) | counterPart
end

function Relic:load(meta)
	if meta & 1 ~= 0 then
		self.counter = (meta >> 1) & 0x3FF
	else
		self.counter = -1
	end
	self.saved = (meta >> 11) & 0x1FF
end

function Relic:onObtainRelic(relic)
	if relic == self then
		self:onObtained()
	end
end

function Relic:onLoseRelic(relic)
	if relic == self then
		self:onLost()
	end
end

function getColorlessRelics()
	return colorlessRelics
end

function generateRelicPools(random)
	local result = {common={},uncommon={},rare={},shop={},boss={}}
	for _, relicType in ipairs(getColorlessRelics()) do
		local pool = result[relicType.tier]
		if pool then
			table.insert(pool,relicType)
		end
	end
	for _, relicType in ipairs(player:getRelics()) do
		local pool = result[relicType.tier]
		if pool then
			table.insert(pool,relicType)
		end
	end
	random:shuffle(result.common)
	random:shuffle(result.uncommon)
	random:shuffle(result.rare)
	random:shuffle(result.shop)
	random:shuffle(result.boss)
	return result
end

function obtainRelic(relic)
	if player:triggerConditionEvent('onBeforeObtainRelic',true,relic) then
		table.insert(relics,relic)
		player:triggerEvent('onObtainRelic',relic)
	end
end

function loseRelic(relic)
	local index = table.indexOf(relics,relic)
	if index then
		player:triggerEvent('onLoseRelic',relic)
		table.remove(relics,index)
	end
end

function hasRelic(relicType)
	return table.anyMatch(relics,function(relic) return getmetatable(relic) == relicType end)
end

function getRelic(relicType)
	for _,relic in ipairs(relics) do
		if getmetatable(relic) == relicType then
			return relic
		end
	end
end

Circlet = Relic:new{name='Circlet',description='Collect as many as you can.',icon=55,tier='special',counter=1}
function Circlet:onBeforeObtainRelic(relic)
	if getmetatable(relic) == Circlet then
		self.counter = self.counter + 1
		return false
	end
end

NeowsLament = Relic:new{name='Neow\'s Lament',description='Enemies in your first #11#3#12# combats will have #11#1#12# HP.',icon=68,tier='special',counter=3}
function NeowsLament:load(...)
	Relic.load(self,...)
	if self.counter == -1 then
		self.description = 'This relic has been used up.'
	end
end

function NeowsLament:onCombatStart()
	if self.counter ~= -1 then
		addAction(AnonymousAction:new(function ()
			for _, enemy in ipairs(enemies) do
				if enemy.alive then
					enemy.hp = 1
				end
			end
		end))
		self.counter = self.counter - 1
		if self.counter == 0 then
			self.counter = -1
			self.description = 'This relic has been used up.'
		end
	end
end

GoldenIdol = Relic:new{name='Golden Idol',icon=Icon:new{image=24,colorMap={[5]=4,[6]=3,[7]=2,[9]=1,[10]=2}},tier='special',description='Enemies drop #11#25%#12# more #4#Gold.'}
function GoldenIdol:onAddBonusGoldReward(bonusGold,amount)
	return bonusGold + amount * 0.25
end

BloodyIdol = Relic:new{name='Bloody Idol',icon=Icon:new{image=24,colorMap={1,14,13,12,2,2,1,8,2,2,11,12,13,14,2}},tier='special',description='Whenever you gain #4#Gold#12#, heal #11#5#12# HP.'}
function BloodyIdol:onGainGold(amount)
	if amount > 0 then
		player:heal(5)
	end
end

OddMushroom = Relic:new{name='Odd Mushroom',icon=26,tier='special',description='When you have {Vulnerable}, take #11#25%#12# more attack damage rather than #11#50%.'}
function OddMushroom:onModifyVulnerableFactor(factor,isAttacking)
	if isAttacking then
		return factor
	end
	return factor - 0.25
end

Anchor = Relic:new{name='Anchor',icon=27,tier='common',description='Start each combat with #11#10#12# {Block}.'}
function Anchor:onCombatStart()
	addAction(GainBlockAction:new{target=player,value=10})
end

EternalFeather = Relic:new{name='Eternal Feather',icon=73,tier='uncommon',description='For every #11#5#12# cards in deck, heal #11#3#12# HP whenever you enter a Rest Site.'}
function EternalFeather:onEnterRoom(_,roomType)
	if roomType == 'rest' then
		player:heal(3*math.floor(#deck/5))
	end
end

Calipers = Relic:new{name='Calipers',icon=28,tier='rare',description='At the start of your turn, lose #11#15#12# {Block} rather than all.'}
function Calipers:onBeforeTurnStartLoseBlock(block)
	return math.min(block,15)
end

EnergyRelic = Relic:new{tier='boss'}
function EnergyRelic:onObtained()
	maxEnergy = maxEnergy + 1
end

function EnergyRelic:onLost()
	maxEnergy = maxEnergy - 1
end

CoffeeDripper = EnergyRelic:new{name='Coffee Dripper',icon=173,description='Gain {Energy} at the start of your turn. You can no longer #4#Rest#12# at Rest Sites.'}
function CoffeeDripper:onModifyCampfireOptions(options)
	for _, option in ipairs(options) do
		if option.name == 'Rest' then
			option.locked = true
			break
		end
	end
end

FusionHammer = EnergyRelic:new{name='Fusion Hammer',icon=177,description='Gain {Energy} at the start of your turn. You can no longer #4#Smith#12# at Rest Sites.'}
function FusionHammer:onModifyCampfireOptions(options)
	for _, option in ipairs(options) do
		if option.name == 'Smith' then
			option.locked = true
			break
		end
	end
end

Ectoplasm = EnergyRelic:new{name='Ectoplasm',icon=175,description='Gain {Energy} at the start of your turn. You can no longer gain #4#Gold#12#.'}
function Ectoplasm:onGainGold()
	return 0
end

function Ectoplasm:canSpawn()
	return act.id <= 1
end

WarpedTongs = Relic:new{name='Warped Tongs',icon=45,tier='special',description='At the start of your turn, #4#Upgrade#12# a random card in your hand for the rest of combat.'}
function WarpedTongs:onTurnStartPostDraw()
	addAction(AnonymousAction:new(function()
		local candidates = table.map(hand,function(cardItem) return cardItem.card end)
		table.retainIf(candidates,function(card) return card:canUpgrade() end)
		if #candidates == 0 then
			return
		end
		local card
		if #candidates == 1 then
			card = candidates[0]
		else
			card = candidates[miscRand:randInt(#candidates)]
		end
		card:upgrade()
		card:resetPowers()
	end))
end

SpiritPoop = Relic:new{name='Spirit Poop',icon=238,tier='special',description='It\'s unpleasant.'}

CultistMask = Relic:new{name='Cultist Mask',icon=187,tier='special',description='You feel more talkative.'}
function CultistMask:onCombatStart()
	player:talk('@CAW!@ NL @CAAAW@')
end

FaceOfCleric = Relic:new{name='Face of Cleric',icon=189,tier='special',description='At the end of combat, raise your Max HP by #11#1.'}
function FaceOfCleric:onCombatEnd()
	player:increaseMaxHp(1)
end

GremlinMask = Relic:new{name='Gremlin Visage',icon=190,tier='special',description='Start each combat with #11#1#12# {Weak}.'}
function GremlinMask:onCombatStart()
	addAction(ApplyPowerAction:new(player,WeakPower:new(player,1,true)))
end

NlothsMask = Relic:new{name='N\'loth\'s Hungry Face',counter=1,icon=239,priority=80,tier='special',description='The next non-Boss chest you open is empty.'}
function NlothsMask:onOpenNonBossChest(rewards)
	if self.counter <= 0 then
		return
	end
	self.counter = self.counter - 1
	for i,reward in ipairs(rewards) do
		if reward.type == 'relic' then
			table.remove(rewards,i)
			if reward.link then
				local linkIndex = table.indexOf(rewards,reward.link)
				if linkIndex then
					table.remove(rewards,linkIndex)
				end
			end
			break
		end
	end

	if self.counter == 0 then
		self.counter = -1
	end
end

SsserpentHead = Relic:new{name='Ssserpent Head',icon=254,tier='special',description='Whenever you enter a #4#?#12# room, gain #11#50 #4#Gold.'}
function SsserpentHead:onEnterRoom(room)
	if room.type == 'event' then
		gainGold(50)
	end
end

NlothsGift = Relic:new{name='N\'loth\'s Gift',icon=223,tier='special',description='Triple the chance of finding #4#Rare#12# cards from combat rewards.'}
function NlothsGift:onModifyRareCardChance(chance)
	if not isRoomType('shop') or roomActionType == 'combat' then
		return chance * 3
	end
end

PotionBelt = Relic:new{name='Potion Belt',icon=11,tier='common',description='Upon pickup, gain #11#2#12# Potion slots.'}
function PotionBelt:canSpawn()
	return floor <= 48
end

function PotionBelt:onObtained()
	table.insert(potions,PotionSlot)
	table.insert(potions,PotionSlot)
end

PreservedInsect = Relic:new{name='Preserved Insect',icon=16,tier='common',description='Enemies in Elite combats have #11#25%#12# less HP.'}
function PreservedInsect:canSpawn()
	return floor <= 52
end

function PreservedInsect:onCombatStart()
	if combatType == 'elite' then
		for _, enemy in ipairs(enemies) do
			if enemy.alive then
				enemy.hp = math.min(enemy.hp, math.ceil(enemy.maxHp * 0.75))
			end
		end
	end
end

Akabeko = Relic:new{name='Akabeko',icon=30,tier='common',description='Your first {Attack} each combat deals #11#8#12# additional damage.'}
function Akabeko:onCombatStart()
	addAction(ApplyPowerAction:new(player,VigorPower:new(player,8)))
end

AncientTeaSet = Relic:new{name='Ancient Tea Set',icon=31,tier='common',description='Whenever you enter a Rest Site, start the next combat with {Energy} {Energy}.'}
function AncientTeaSet:canSpawn()
	return floor <= 48
end

function AncientTeaSet:onEnterRoom(_,roomType)
	if roomType == 'rest' then
		self.saved = 1
	end
end

function AncientTeaSet:onCombatStart()
	if self.saved == 1 then
		addAction(GainEnergyAction:new(2))
		self.saved = 0
	end
end

ArtOfWar = Relic:new{name='Art of War',icon=32,tier='common',notPlayAttack=false,description='If you do not play any {Attack} during your turn, gain an additional {Energy} next turn.'}
function ArtOfWar:onCombatStart()
	self.notPlayAttack = false
end

function ArtOfWar:onTurnStart()
	if self.notPlayAttack then
		addAction(GainEnergyAction:new(1))
	end
	self.notPlayAttack = true
end

function ArtOfWar:onUseCard(card)
	if card.type == 'attack' then
		self.notPlayAttack = false
	end
end

BagOfMarbles = Relic:new{name='Bag of Marbles',icon=33,tier='common',description='At the start of each combat, apply #11#1#12# {Vulnerable} to ALL enemies.'}
function BagOfMarbles:onCombatStart()
	for _, enemy in ipairs(enemies) do
		if enemy.alive then
			addAction(ApplyPowerAction:new(player,VulnerablePower:new(enemy,1)))
		end
	end
end

BagOfPreparation = Relic:new{name='Bag of Preparation',icon=34,tier='common',description='At the start of each combat, draw #11#2#12# additional cards.'}
function BagOfPreparation:onTurnStartPostDraw(turn)
	if turn == 1 then
		addAction(DrawCardAction:new(2))
	end
end

RegalPillow = Relic:new{name='Regal Pillow',icon=39,tier='common',description='Whenever you #4#Rest#12#, heal an additional #11#15#12# HP.'}
function RegalPillow:canSpawn()
	return floor <= 48
end

BloodVial = Relic:new{name='Blood Vial',icon=42,tier='common',description='At the start of each combat, heal #11#2#12# HP.'}
function BloodVial:onCombatStart()
	player:heal(2)
end

BronzeScales = Relic:new{name='Bronze Scales',icon=43,tier='common',description='Start each combat with 3 {29}.'}
function BronzeScales:onCombatStart()
	addAction(ApplyPowerAction:new(player,ThornsPower:new(player,3)))
end

CentennialPuzzle = Relic:new{name='Centennial Puzzle',icon=44,tier='common',activated=false,description='The first time you lose HP each combat, draw #11#3#12# card.'}
function CentennialPuzzle:onCombatStart()
	self.activated = true
end

function CentennialPuzzle:onDamaged(value)
	if self.activated and value > 0 then
		addAction(DrawCardAction:new(3))
		self.activated = false
	end
end

CeramicFish = Relic:new{name='Ceramic Fish',icon=70,tier='common',description='Whenever you add a card to your deck, gain #11#9 #4#Gold.'}
function CeramicFish:canSpawn()
	return floor <= 48
end

function CeramicFish:onObtainCard()
	gainGold(9)
end

DreamCatcher = Relic:new{name='Dream Catcher',icon=71,tier='common',description='Whenever you #4#Rest#12#, you may add a card to your deck.'}
function DreamCatcher:canSpawn()
	return floor <= 48
end

function DreamCatcher:onRest(campfireEvent)
	local rewards = {}
	generateCardRewards(rewards,campfireEvent.random)
	openWindowAbove(CardRewardWindow:new{cards=rewards[1].value,buttons=rewards[1].buttons,title='Dreaming?'}, function(cardItem)
		if cardItem and getmetatable(cardItem) == CardItem then
			cardItem.large = false
			addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=1,duration=20,tx=240,ty=0})
			obtainCard(cardItem.card)
		end
	end)
end

HappyFlower = Relic:new{name='Happy Flower',icon=86,tier='common',counter=0,description='Every #11#3#12# turns, gain {Energy}.'}
function HappyFlower:onTurnStart()
	self.counter = self.counter + 1
	if self.counter == 3 then
		self.counter = 0
		addAction(GainEnergyAction:new(1))
	end
end

JuzuBracelet = Relic:new{name='Juzu Bracelet',icon=87,tier='common',description='Normal enemy combats are no longer encountered in #4#?#12# rooms.'}
function JuzuBracelet:canSpawn()
	return floor <= 48
end

function JuzuBracelet:modifyEventRoomType(result)
	if result == 'monster' then
		return 'event'
	end
end

Lantern = Relic:new{name='Lantern',icon=88,tier='common',description='Start each combat with an additional {Energy}.'}
function Lantern:onCombatStart()
	addAction(GainEnergyAction:new(1))
end

MawBank = Relic:new{name='Maw Bank',icon=89,tier='common',description='Whenever you climb a floor, gain #11#12 #4#Gold#12#. No longer works when you spend any #4#Gold#12# at a shop.'}
function MawBank:canSpawn()
	return floor <= 48 and not isRoomType('shop')
end

function MawBank:onEnterRoom()
	if self.saved == 0 then
		gainGold(12)
	end
end

function MawBank:onLoseGold()
	if isRoomType('shop') then
		self.saved = 1
		self.description = 'This relic has been used up.'
	end
end

function MawBank:load(...)
	Relic.load(self,...)
	if self.saved == 1 then
		self.description = 'This relic has been used up.'
	end
end

MealTicket = Relic:new{name='Meal Ticket',icon=90,tier='common',description='Whenever you enter a shop, heal #11#15#12# HP.'}
function MealTicket:canSpawn()
	return floor <= 48
end

function MealTicket:onEnterRoom(_,roomType)
	if roomType == 'shop' then
		player:heal(15)
	end
end

Nunchaku = Relic:new{name='Nunchaku',icon=91,tier='common',counter=0,description='Every time you play #11#10#12# {Attack}, gain {Energy}.'}
function Nunchaku:onUseCard(card)
	if card.type == 'attack' then
		self.counter = self.counter + 1
		if self.counter == 10 then
			self.counter = 0
			addAction(GainEnergyAction:new(1))
		end
	end
end

OddlySmoothStone = Relic:new{name='Oddly Smooth Stone',icon=92,tier='common',description='Start each combat with #11#1#12# {Dexterity}.'}
function OddlySmoothStone:onCombatStart()
	addAction(ApplyPowerAction:new(player,DexterityPower:new(player,1)))
end

Omamori = Relic:new{name='Omamori',icon=93,tier='common',counter=2,description='Negate the next #11#2#12# {Curse} you obtain.'}
function Omamori:canSpawn()
	return floor <= 48
end

function Omamori:load(...)
	Relic.load(self,...)
	if self.counter == -1 then
		self.description = 'This relic has been used up.'
	end
end

function Omamori:onBeforeObtainCard(card)
	if card.type == 'curse' and self.counter > 0 then
		self.counter = self.counter - 1
		if self.counter == 0 then
			self.counter = -1
			self.description = 'This relic has been used up.'
		end
		return false
	end
end

Orichalcum = Relic:new{name='Orichalcum',icon=94,tier='common',description='If you end your turn without {Block}, gain #11#6#12# {Block}.'}
function Orichalcum:onTurnEnd()
	if player.block == 0 then
		addAction(GainBlockAction:new{target=player,value=6})
	end
end

PenNib = Relic:new{name='Pen Nib',icon=95,tier='common',counter=0,priority=200,description='Every #11#10th#12# {Attack} you play deals double damage.'}
function PenNib:onAttack(damage)
	if self.counter == 9 then
		return damage * 2
	end
end

function PenNib:onUseCard(card)
	if card.type == 'attack' then
		self.counter = self.counter + 1
		if self.counter == 10 then
			self.counter = 0
		end
	end
end

SmilingMask = Relic:new{name='Smiling Mask',icon=110,tier='common',priority=80,description='The Merchant\'s card removal service now always costs #11#50 #4#Gold.'}
function SmilingMask:canSpwan()
	return not isRoomType('shop') and floor <= 48
end

function SmilingMask:modifyShopPrice(_,type)
	if type == 'cardRemoval' then
		return 50
	end
end

Strawberry = Relic:new{name='Strawberry',icon=111,tier='common',description='Upon pickup, raise your Max HP by #11#7#12#.'}
function Strawberry:onObtained()
	player:increaseMaxHp(7)
end

TheBoot = Relic:new{name='The Boot',icon=112,tier='common',description='Whenever you would deal #11#4#12# or less unblocked attack damage, increase it to #11#5#12#.'}
function TheBoot:onBeforeReduceHp(damage,target,type)
	if damage > 0 and damage <= 4 and type == 'attack' then
		return 5
	end
end

TinyChest = Relic:new{name='Tiny Chest',icon=113,tier='common',counter=0,description='Every #11#4th #4#?#12# room is a #4#Treasure#12# room.'}
function TinyChest:canSpawn()
	return floor <= 35
end

function TinyChest:modifyEventRoomTypeBeforeUpdateChance(result)
	self.counter = self.counter + 1
	if self.counter == 4 then
		self.counter = 0
		return 'treasure'
	end
end

ToyOrnithopter = Relic:new{name='Toy Ornithopter',icon=114,tier='common',description='Whenever you use a potion, heal #11#5#12# HP.'}
function ToyOrnithopter:onUsePotion(_,inCombat)
	if inCombat then
		addAction(1,HealAction:new{target=player,value=5})
	else
		player:heal(5)
	end
end

Vajra = Relic:new{name='Vajra',icon=115,tier='common',description='Start each combat with #11#1#12# {Strength}.'}
function Vajra:onCombatStart()
	addAction(ApplyPowerAction:new(player,StrengthPower:new(player,1)))
end

WarPaint = Relic:new{name='War Paint',icon=116,tier='common',description='Upon pickup, #4#Upgrade #11#2#12# random {Skill}.'}
function WarPaint:onObtained()
	local random = makeRand(act.id,room.id,7)
	local cards = shallowcopy(deck)
	table.retainIf(cards,function(c) return c:canUpgrade() and c.type == 'skill' end)
	random:shuffle(cards)
	local toBeUpgraded = table.map({cards[1],cards[2]},function (card)
		return CardItem:new{card=card,x=240,y=0,isNotInHand=true}
	end)
	upgradeCardsWithEffect(toBeUpgraded)
end

Whetstone = Relic:new{name='Whetstone',icon=117,tier='common',description='Upon pickup, #4#Upgrade #11#2#12# random {Attack}.'}
function Whetstone:onObtained()
	local random = makeRand(act.id,room.id,7)
	local cards = shallowcopy(deck)
	table.retainIf(cards,function(c) return c:canUpgrade() and c.type == 'attack' end)
	random:shuffle(cards)
	local toBeUpgraded = table.map({cards[1],cards[2]},function (card)
		return CardItem:new{card=card,x=240,y=0,isNotInHand=true}
	end)
	upgradeCardsWithEffect(toBeUpgraded)
end

BlueCandle = Relic:new{name='Blue Candle',icon=118,tier='uncommon',description='#4#Unplayable#12# {Curse} can now be played. NL Whenever you play a {Curse}, lose #11#1#12# HP.'}
function BlueCandle:canUseCard(card)
	if card.type == 'curse' and not card:baseCanUse(true) then
		return true
	end
end

function BlueCandle:onUseCard(card,_,action)
	if card.type == 'curse' then
		action.exhaust = true
		addAction(DamageAction:new{target=player,source=player,value=1,type='hpLoss'})
	end
end

BottleRelic = Relic:new{tier='uncommon',tags={'bottle'},linkedCard=nil}
function BottleRelic:onObtained()
	local cards = shallowcopy(deck)
	table.retainIf(cards,function(c) return self:condition(c) end)
	local cardItems = table.map(cards,function (card) return CardItem:new{card=card,x=240,y=0,isNotInHand=true} end)
	if #cardItems == 0 then
		return
	end
	local gridView = CardGridSelectWindow:new{title='Choose a Card for '..self.name,cardItems=cardItems,min=1,max=1,canClose=false}
	openWindowAbove(gridView, function (cardItems)
		if not cardItems then
			return
		end
		self:linkCard(cardItems[1].card)
	end)
end

function BottleRelic:onLost()
	self:unlinkCard()
end

function BottleRelic:canSpwan()
	return table.anyMatch(deck,function(card) return card.rarity ~= 'basic' and self:condition(card) end)
end

function BottleRelic:condition(_)
	return true
end

function BottleRelic:linkCard(card)
	self.linkedCard = card
	self.cardOldCanRemove = card.canRemove
	card.linkedBottle = self
	card.canRemove = false
	self.description = 'Start each combat with '..card.name..' in your hand.'
end

function BottleRelic:unlinkCard()
	local card = self.linkedCard
	if card then
		card.linkedBottle = nil
		card.canRemove = self.cardOldCanRemove
	end
end

function BottleRelic:save()
	if self.linkedCard then
		return table.indexOf(deck,self.linkedCard) or 0
	else
		return 0
	end
end

function BottleRelic:load(meta)
	if meta > 0 then
		self:linkCard(deck[meta])
	end
end

BottledFlame = BottleRelic:new{name='Bottled Flame',icon=119,description='Upon pickup, choose a {Attack}. Start each combat with this card in your hand.'}
function BottledFlame:condition(card)
	return card.type == 'attack' and not card.linkedBottle
end

BottledLightning = BottleRelic:new{name='Bottled Lightning',icon=120,description='Upon pickup, choose a {Skill}. Start each combat with this card in your hand.'}
function BottledLightning:condition(card)
	return card.type == 'skill' and not card.linkedBottle
end

BottledTornado = BottleRelic:new{name='Bottled Tornado',icon=121,description='Upon pickup, choose a {Power}. Start each combat with this card in your hand.'}
function BottledTornado:condition(card)
	return card.type == 'power' and not card.linkedBottle
end

DarkstonePeriapt = Relic:new{name='Darkstone Periapt',icon=122,tier='uncommon',description='Whenever you obtain a {Curse}, increase your Max HP by #11#6#12#.'}
function DarkstonePeriapt:canSpawn()
	return floor <= 48
end

function DarkstonePeriapt:onObtainCard(card)
	if card.type == 'curse' then
		player:increaseMaxHp(6)
	end
end

GremlinHorn = Relic:new{name='Gremlin Horn',icon=126,tier='uncommon',description='Whenever an enemy dies, gain #11#1#12# {Energy} and draw #11#1#12# card.'}
function GremlinHorn:onMonsterDeath()
	addAction(GainEnergyAction:new(1))
	addAction(DrawCardAction:new(1))
end

HornCleat = Relic:new{name='Horn Cleat',icon=127,tier='uncommon',description='At the start of your 2nd turn, gain #11#14#12# {Block}.'}
function HornCleat:onCombatStart()
	self.counter = 0
end

function HornCleat:onTurnStart(turn)
	if turn < 2 then
		self.counter = turn
	elseif turn == 2 then
		addAction(GainBlockAction:new{target=player,value=14})
		self.counter = -1
	end
end

function HornCleat:onCombatEnd()
	self.counter = -1
end

FrozenEgg = Relic:new{name='Frozen Egg',icon=123,tier='uncommon',description='Whenever you add a {Power} into your deck, #4#Upgrade#12# it.'}
function FrozenEgg:canSpawn()
	return floor <= 48
end

function FrozenEgg:onPreviewObtainCard(card)
	self:onObtainCard(card)
end

function FrozenEgg:onObtainCard(card)
	if card.type == 'power' and not card.upgraded and card:canUpgrade() then
		card:upgrade()
		card:resetPowers()
	end
end

MoltenEgg = Relic:new{name='Molten Egg',icon=124,tier='uncommon',description='Whenever you add a {Attack} into your deck, #4#Upgrade#12# it.'}
function MoltenEgg:canSpawn()
	return floor <= 48
end

function MoltenEgg:onPreviewObtainCard(card)
	self:onObtainCard(card)
end

function MoltenEgg:onObtainCard(card)
	if card.type == 'attack' and not card.upgraded and card:canUpgrade() then
		card:upgrade()
		card:resetPowers()
	end
end

ToxicEgg = Relic:new{name='Toxic Egg',icon=125,tier='uncommon',description='Whenever you add a {Skill} into your deck, #4#Upgrade#12# it.'}
function ToxicEgg:canSpawn()
	return floor <= 48
end

function ToxicEgg:onPreviewObtainCard(card)
	self:onObtainCard(card)
end

function ToxicEgg:onObtainCard(card)
	if card.type == 'skill' and not card.upgraded and card:canUpgrade() then
		card:upgrade()
		card:resetPowers()
	end
end

InkBottle = Relic:new{name='Ink Bottle',icon=128,counter=0,tier='uncommon',description='Whenever you play #11#10#12# cards, draw #11#1#12# card.'}
function InkBottle:onUseCard()
	self.counter = self.counter + 1
	if self.counter == 10 then
		self.counter = 0
		addAction(DrawCardAction:new(1))
	end
end

Kunai = Relic:new{name='Kunai',icon=134,tier='uncommon',description='Every time you play #11#3#12# {Attack} in a single turn, gain #11#1#12# {Dexterity}.'}
function Kunai:onTurnStart()
	self.counter = 0
end

function Kunai:onUseCard(card)
	if card.type == 'attack' then
		self.counter = self.counter + 1
		if self.counter == 3 then
			self.counter = 0
			addAction(ApplyPowerAction:new(player,DexterityPower:new(player,1)))
		end
	end
end

function Kunai:onCombatEnd()
	self.counter = -1
end

Shuriken = Relic:new{name='Shuriken',icon=135,tier='uncommon',description='Every time you play #11#3#12# {Attack} in a single turn, gain #11#1#12# {Strength}.'}
function Shuriken:onTurnStart()
	self.counter = 0
end

function Shuriken:onUseCard(card)
	if card.type == 'attack' then
		self.counter = self.counter + 1
		if self.counter == 3 then
			self.counter = 0
			addAction(ApplyPowerAction:new(player,StrengthPower:new(player,1)))
		end
	end
end

function Shuriken:onCombatEnd()
	self.counter = -1
end

OrnamentalFan = Relic:new{name='Ornamental Fan',icon=136,tier='uncommon',description='Every time you play #11#3#12# {Attack} in a single turn, gain #11#4#12# {Block}.'}
function OrnamentalFan:onTurnStart()
	self.counter = 0
end

function OrnamentalFan:onUseCard(card)
	if card.type == 'attack' then
		self.counter = self.counter + 1
		if self.counter == 3 then
			self.counter = 0
			addAction(GainBlockAction:new{target=player,value=4})
		end
	end
end

function OrnamentalFan:onCombatEnd()
	self.counter = -1
end

LetterOpener = Relic:new{name='Letter Opener',icon=129,tier='uncommon',description='Every time you play #11#3#12# {Skill} in a single turn, {Damage} #11#5#12# to all enemies.'}
function LetterOpener:onTurnStart()
	self.counter = 0
end

function LetterOpener:onUseCard(card)
	if card.type == 'skill' then
		self.counter = self.counter + 1
		if self.counter == 3 then
			self.counter = 0
			addAction(DamageAllEnemiesAction:new{source=player,value=5,type='power'})
		end
	end
end

function LetterOpener:onCombatEnd()
	self.counter = -1
end

Matryoshka = Relic:new{name='Matryoshka',icon=130,tier='uncommon',counter=2,description='The next #11#2#12# non-Boss chests you open contain #11#2 #4#Relics.'}
function Matryoshka:canSpawn()
	return floor <= 40
end

function Matryoshka:load(...)
	Relic.load(self,...)
	if self.counter == -1 then
		self.description = 'This relic has been used up.'
	end
end

function Matryoshka:onOpenNonBossChest(rewards)
	if self.counter <= 0 then
		return
	end
	self.counter = self.counter - 1

	local rand = makeRand(act.id,room.id,2)
	local relic
	if rand:rand() < 0.75 then
		relic = getRandomRelic(rand,'common')
	else
		relic = getRandomRelic(rand,'uncommon')
	end

	addRelicReward(rewards,relic)
	if self.counter == 0 then
		self.counter = -1
		self.description = 'This relic has been used up.'
	end
end

MeatOnTheBone = Relic:new{name='Meat on the Bone',icon=131,tier='uncommon',description='If your HP is at or below #11#50%#12# at the end of combat, heal #11#12#12# HP.'}
function MeatOnTheBone:canSpawn()
	return floor <= 48
end

function MeatOnTheBone:onCombatEnd()
	if player.hp <= player.maxHp * 0.5 then
		player:heal(12)
	end
end

MercuryHourglass = Relic:new{name='Mercury Hourglass',icon=132,tier='uncommon',description='At the start of your turn, {Damage} #11#3#12# to all enemies.'}
function MercuryHourglass:onTurnStart()
	addAction(DamageAllEnemiesAction:new{source=player,value=3,type='power'})
end

MummifiedHand = Relic:new{name='Mummified Hand',icon=133,tier='uncommon',description='Whenever you play a {Power}, a random card in your hand costs #11#0#12# for the turn.'}
function MummifiedHand:onUseCard(card)
	if card.type == 'power' then
		addAction(AnonymousAction:new(function ()
			local candidates = shallowcopy(hand)
			table.retainIf(candidates,function(c) return c.card:getCost() > 0 end)
			if #candidates > 0 then
				local card = candidates[miscRand:randInt(#candidates)]
				card.card.costForOneTurnPlay = 0
			end
		end))
	end
end

Pantograph = Relic:new{name='Pantograph',icon=137,tier='uncommon',description='At the start of boss combats, heal #11#25#12# HP.'}
function Pantograph:onCombatStart()
	if table.anyMatch(enemies,function(enemy) return enemy.type == 'boss' end) then
		player:heal(25)
	end
end

Pear = Relic:new{name='Pear',icon=138,tier='uncommon',description='Upon pickup, raise your Max HP by #11#10#12#.'}
function Pear:onObtained()
	player:increaseMaxHp(10)
end

QuestionCard = Relic:new{name='Question Card',icon=139,tier='uncommon',description='Future card rewards have #11#1#12# additional card to choose from.'}
function QuestionCard:canSpawn()
	return floor <= 48
end

function QuestionCard:modifyCardRewardCount(value)
	return value + 1
end

StrikeDummy = Relic:new{name='Strike Dummy',icon=141,tier='uncommon',description='Cards containing \"Strike\" deal #11#3#12# additional damage.'}
function StrikeDummy:onAttack(damage,_,card)
	if table.indexOf(card.tags,'strike') then
		return damage + 3
	end
end

Sundial = Relic:new{name='Sundial',icon=142,tier='uncommon',counter=0,description='Every #11#3#12# times you shuffle your draw pile, gain {Energy} {Energy}.'}
function Sundial:onShuffle()
	self.counter = self.counter + 1
	if self.counter == 3 then
		self.counter = 0
		addAction(GainEnergyAction:new(2))
	end
end

TheCourier = Relic:new{name='The Courier',icon=143,tier='uncommon',description='The Merchant restocks cards, relics, and potions. All prices are reduced by #11#20%#12#.'}
function TheCourier:canSpwan()
	return not isRoomType('shop') and floor <= 48
end

function TheCourier:modifyShopPrice(price)
	return price * 0.8
end

WhiteBeastStatue = Relic:new{name='White Beast Statue',icon=144,tier='uncommon',description='Potions always appear in combat rewards.'}
function WhiteBeastStatue:modifyPotionChance()
	return 100
end

SingingBowl = Relic:new{name='Singing Bowl',icon=140,tier='uncommon',description='When adding cards into your deck, you may raise your Max HP by #11#2#12# instead.'}
function SingingBowl:canSpawn()
	return floor <= 48
end

function SingingBowl:modifyCardReward(reward)
	reward.buttons = reward.buttons or {}
	table.insert(reward.buttons,{title='+2 Max HP', onSelect=function ()
		player:increaseMaxHp(2)
	end})
end

BirdFacedUrn = Relic:new{name='Bird-Faced Urn',icon=145,tier='rare',description='Whenever you play a {Power}, heal #11#2#12# HP.'}
function BirdFacedUrn:onUseCard(card)
	if card.type == 'power' then
		addAction(HealAction:new{target=player,value=2})
	end
end

CaptainsWheel = Relic:new{name='Captain\'s Wheel',icon=146,tier='rare',description='At the start of your 3rd turn, gain #11#18#12# {Block}.'}
function CaptainsWheel:onCombatStart()
	self.counter = 0
end

function CaptainsWheel:onTurnStart(turn)
	if turn < 3 then
		self.counter = turn
	elseif turn == 3 then
		addAction(GainBlockAction:new{target=player,value=18})
		self.counter = -1
	end
end

function CaptainsWheel:onCombatEnd()
	self.counter = -1
end

DeadBranch = Relic:new{name='Dead Branch',icon=147,tier='rare',description='Whenever you #4#Exhaust#12# a card, add a random card into your hand.'}
function DeadBranch:onExhaust()
	local cardType
	repeat
		cardType = getPlayerCardType(miscRand)
	until cardType.canGenerateInCombat
	addAction(MakeTempCardToHandAction:new(cardType:new()))
end

DuVuDoll = Relic:new{name='Du-Vu Doll',icon=148,tier='rare',counter=0,description='For each {Curse} in your deck, start each combat with #11#1#12# {Strength}.'}
function DuVuDoll:onCombatStart()
	if self.counter > 0 then
		addAction(ApplyPowerAction:new(player,StrengthPower:new(player,self.counter)))
	end
end

function DuVuDoll:onObtained()
	self.counter = table.count(deck, function(card) return card.type == 'curse' end)
end

function DuVuDoll:onObtainCard(card)
	if card.type == 'curse' then
		self.counter = self.counter + 1
	end
end

function DuVuDoll:onRemoveCard(card)
	if card.type == 'curse' then
		self.counter = self.counter - 1
	end
end

FossilizedHelix = Relic:new{name='Fossilized Helix',icon=149,tier='rare',description='Prevent the first time you would lose HP each combat.'}
function FossilizedHelix:onCombatStart()
	addAction(ApplyPowerAction:new(player,BufferPower:new(player,1)))
end

GamblingChip = Relic:new{name='Gambling Chip',icon=150,tier='rare',priority=80,description='At the start of each combat, discard any number of cards, then draw that many cards.'}
function GamblingChip:onTurnStartPostDraw(turn)
	if turn > 1 then
		return
	end
	addAction(AnonymousAction:new(function ()
		if #hand == 0 then
			return
		else
			openWindowAbove(HandSelectWindow:new{cardItems=hand,title='Choose any Card to Discard',min=0},function (cards)
				for i,cardItem in ipairs(cards) do
					addAction(i,DiscardAction:new{cardItem=cardItem,duration=1})
				end
				if #cards > 0 then
					addAction(#cards+1,DrawCardAction:new(#cards))
				end
				for _,cardItem in ipairs(cards) do
					local cardIndex = table.indexOf(hand,cardItem)
					removeHand(cardIndex)
				end
			end)
		end
	end))
end

Ginger = Relic:new{name='Ginger',icon=151,tier='rare',description='You can no longer become {Weak}.'}
function Ginger:onBeforeApplyPower(power)
	if getmetatable(power) == WeakPower then
		local owner = self.owner
		addEffect(TextEffect:new{x=owner.x+owner.width*4,y=owner.y,text='Immune',color=12,ySpeed=-0.5})
		return false
	end
end

Turnip = Relic:new{name='Turnip',icon=166,tier='rare',description='You can no longer become {Frail}.'}
function Turnip:onBeforeApplyPower(power)
	if getmetatable(power) == FrailPower then
		local owner = self.owner
		addEffect(TextEffect:new{x=owner.x+owner.width*4,y=owner.y,text='Immune',color=12,ySpeed=-0.5})
		return false
	end
end

CampfireRelic = Relic:new{tags={'campfire'}}
function CampfireRelic:canSpawn()
	if floor >= 48 then
		return false
	end
	return table.count(relics, function (relic)
		return table.anyMatch(relic.tags, function (tag)
			return tag == 'campfire'
		end)
	end) < 2
end

Girya = CampfireRelic:new{name='Girya',icon=152,tier='rare',counter=0,description='You can now gain {Strength} at Rest Sites (up to 3 times).'}
function Girya:onModifyCampfireOptions(options,event)
	table.insert(options,{
		name='Lift',description='Start battles with +1 Strength. (Max 3)',icon=388,
		locked=self.counter>=3,
		onSelect=function()
			self.counter = self.counter + 1
			event:completeCampfire()
		end
	})
end

function Girya:onCombatStart()
	if self.counter > 0 then
		addAction(ApplyPowerAction:new(player,StrengthPower:new(player,self.counter)))
	end
end

IceCream = Relic:new{name='Ice Cream',icon=153,tier='rare',description='Energy is now conserved between turns.'}
function IceCream:onTurnStartResetEnergy(targetEnergy,currentEnergy)
	return targetEnergy + currentEnergy
end

IncenseBurner = Relic:new{name='Incense Burner',icon=154,tier='rare',counter=0,description='Every #11#6#12# turns, gain #11#1#12# {35}.'}
function IncenseBurner:onTurnStart(turn)
	self.counter = self.counter + 1
	if self.counter == 6 then
		self.counter = 0
		addAction(ApplyPowerAction:new(player,IntangiblePower:new(player,1)))
	end
end

LizardTail = Relic:new{name='Lizard Tail',icon=155,tier='rare',counter=1,description='When you would die, heal to #11#50%#12# of your Max HP instead (works once).'}
function LizardTail:onBeforeDeath()
	if self.saved == 0 then
		self.saved = 1
		self.counter = -1
		self.description = 'This relic has been used up.'
		player:heal(math.max(1,math.floor(player.maxHp/2)))
		return false
	end
end

function LizardTail:load(...)
	Relic.load(self,...)
	if self.saved == 1 then
		self.description = 'This relic has been used up.'
	end
end

Mango = Relic:new{name='Mango',icon=156,tier='rare',description='Upon pickup, raise your Max HP by #11#14#12#.'}
function Mango:onObtained()
	player:increaseMaxHp(14)
end

OldCoin = Relic:new{name='Old Coin',icon=157,tier='rare',description='Upon pickup, gain #11#300 #4#Gold.'}
function OldCoin:canSpwan()
	return not isRoomType('shop') and floor <= 48
end

function OldCoin:onObtained()
	gainGold(300)
end

PeacePipe = CampfireRelic:new{name='Peace Pipe',icon=158,tier='rare',description='You can now remove cards from your deck at Rest Sites.'}
function PeacePipe:onModifyCampfireOptions(options,event)
	table.insert(options,{
		name='Toke',description='Remove a card from your deck.',icon=416,
		onSelect=function()
			removeCardFromDeck(1,true,function (completed)
				if completed then
					event:completeCampfire()
				end
			end)
		end
	})
end

PocketWatch = Relic:new{name='Pocket Watch',icon=159,tier='rare',description='Whenever you play #11#3#12# or less cards during your turn, draw #11#3#12# additional cards at the start of your next turn.'}
function PocketWatch:onCombatStart()
	self.counter = 0
end

function PocketWatch:onTurnStart(turn)
	if self.counter <= 3 and turn > 1 then
		addAction(DrawCardAction:new(3))
	end
	self.counter = 0
end

function PocketWatch:onUseCard()
	self.counter = self.counter + 1
end

function PocketWatch:onCombatEnd()
	self.counter = -1
end

PrayerWheel = Relic:new{name='Prayer Wheel',icon=160,tier='rare',description='Normal enemies drop an additional card reward.'}
function PrayerWheel:canSpawn()
	return floor <= 48
end

Shovel = CampfireRelic:new{name='Shovel',icon=161,tier='rare',description='You can now #4#Dig#12# for relics at Rest Sites.'}
function Shovel:onModifyCampfireOptions(options,event)
	table.insert(options,{
		name='Dig',description='Dig up a random relic.',icon=368,
		onSelect=function()
			local rewards = {}
			addRelicReward(rewards,getRandomRelic(makeRand(act.id,room.id,7)))
			local rewardWindow = RewardWindow:new{rewards=rewards,canClose=true,onProceed=function(self) self:close() end}
			openWindowAbove(rewardWindow,function ()
				event:completeCampfire()
			end)
		end
	})
end

StoneCalendar = Relic:new{name='Stone Calendar',icon=162,tier='rare',description='At the end of turn #11#7#12#, {Damage} #11#52#12# to all enemies.'}
function StoneCalendar:onTurnStart(turn)
	self.counter = turn
end

function StoneCalendar:onTurnEnd()
	if self.counter == 7 then
		addAction(DamageAllEnemiesAction:new{source=player,value=52,type='power'})
	end
end

function StoneCalendar:onCombatEnd()
	self.counter = -1
end

ThreadAndNeedle = Relic:new{name='Thread and Needle',icon=163,tier='rare',description='Start each combat with 4 {62}.'}
function ThreadAndNeedle:onCombatStart()
	addAction(ApplyPowerAction:new(player,PlatedArmorPower:new(player,4)))
end

Torii = Relic:new{name='Torii',icon=164,tier='rare',description='Whenever you would receive #11#5#12# or less unblocked attack damage, reduce it to #11#1#12#.'}
function Torii:onBeforeHpLoss(value,_,type)
	if value <= 5 and value > 0 and type == 'attack' then
		return 1
	end
end

TungstenRod = Relic:new{name='Tungsten Rod',icon=165,tier='rare',priority=200,description='Whenever you would lose HP, lose #11#1#12# less HP.'}
function TungstenRod:onBeforeHpLoss(value)
	if value > 0 then
		return value - 1
	end
end

UnceasingTop = Relic:new{name='Unceasing Top',icon=167,tier='rare',description='Whenever you have no cards in hand during your turn, draw a card.'}
function UnceasingTop:onRemoveHand()
	if not inEnemyTurn and #hand == 0 and (#drawPile > 0 or #discardPile > 0) and
		not table.anyMatch(actions,function (action) return getmetatable(action) == DrawCardAction end) then
		addAction(DrawCardAction:new(1))
	end
end

WingBoots = Relic:new{name='Wing Boots',icon=168,tier='rare',counter=3,description='You may ignore paths when choosing the next room to travel to #11#3#12# times.'}
function WingBoots:canSpawn()
	return floor <= 40
end

function WingBoots:canFly()
	return self.counter > 0
end

function WingBoots:onFly()
	if self.counter > 0 then
		self.counter = self.counter - 1
		if self.counter == 0 then
			self.counter = -1
			self.description = 'This relic has been used up.'
		end
	end
end

function WingBoots:load(...)
	Relic.load(self,...)
	if self.counter == -1 then
		self.description = 'This relic has been used up.'
	end
end

Astrolabe = Relic:new{name='Astrolabe',icon=169,tier='boss',description='Upon pickup, transform #11#3#12# cards then upgrade them.'}
function Astrolabe:onObtained()
	transformCardFromDeck(3,makeRand(act.id,room.id,7),false,function (completed,transformedCards)
		if completed then
			for _,card in ipairs(transformedCards) do
				if card:canUpgrade() then
					card:upgrade()
					card:resetPowers()
				end
			end
		end
	end,'Choose a Card for '..self.name)
end

BlackStar = Relic:new{name='Black Star',icon=170,tier='boss',description='Elites drop an additional relic when defeated.'}

BustedCrown = EnergyRelic:new{name='Busted Crown',icon=171,tier='boss',description='Gain {Energy} at the start of your turn. Future card rewards have #11#2#12# less cards to choose from.'}
function BustedCrown:modifyCardRewardCount(value)
	return value - 2
end

CallingBell = Relic:new{name='Calling Bell',icon=172,tier='boss',description='Upon pickup, obtain a unique {Curse} and #11#3#12# relics.'}
function CallingBell:onObtained()
	local rewards = {}
	local random = makeRand(act.id,room.id,7)

	openWindowAbove(CardRewardWindow:new{cards={CurseOfTheBell:new()},title='The Bell Tolls...',canClose=false},function (cardItem)
		if cardItem then
			cardItem.large = false
			addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=1,duration=20,tx=240,ty=0})
			obtainCard(cardItem.card)
		end

		addRelicReward(rewards,getRandomRelic(random,'common'))
		addRelicReward(rewards,getRandomRelic(random,'uncommon'))
		addRelicReward(rewards,getRandomRelic(random,'rare'))
		openWindowAbove(RewardWindow:new{rewards=rewards,canClose=true,onProceed=function(self) self:close() end})
	end)
end

CursedKey = EnergyRelic:new{name='Cursed Key',icon=174,tier='boss',description='Gain {Energy} at the start of your turn. Whenever you open a non-Boss chest, obtain a {Curse}.'}
function CursedKey:onOpenNonBossChest()
	local random = makeRand(act.id,room.id,7)
	local cardItem = CardItem:new{card=getCurseCardType(random):new(),x=0,y=136,tx=120,ty=68,isNotInHand=true}
	addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=30,duration=50,tx=240,ty=0})
	obtainCard(cardItem.card)
end

EmptyCage = Relic:new{name='Empty Cage',icon=176,tier='boss',description='Upon pickup, remove #11#2#12# cards from your deck.'}
function EmptyCage:onObtained()
	if #deck > 0 then
		removeCardFromDeck(2,false)
	end
end

PandorasBox = Relic:new{name='Pandora\'s Box',icon=178,tier='boss',description='Upon pickup, Transform all Strike and Defend cards.'}
function PandorasBox:onObtained()
	local basicCards = {}
	for i=#deck,1,-1 do
		local card = deck[i]
		if table.anyMatch(card.tags,function (tag) return tag == 'basicStrike' or tag == 'basicDefend' end) then
			table.insert(basicCards,card)
			removeCard(card)
		end
	end
	local random = makeRand(act.id,room.id,7)
	local transformedCards = {}
	for i,card in ipairs(basicCards) do
		transformedCards[i] = CardItem:new{card=getTransformedCard(random,card),x=0,y=136,isNotInHand=true}
	end
	openWindowAbove(
		CardGridSelectWindow:new{cardItems=transformedCards,title='Pandora\'s Box has been opened...',min=0,max=0,canClose=true},
		function ()
			for _,cardItem in ipairs(transformedCards) do
				addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=1,duration=20,tx=240,ty=0})
				obtainCard(cardItem.card)
			end
		end)
end

PhilosophersStone = EnergyRelic:new{name='Philosopher\'s Stone',icon=179,tier='boss',description='Gain {Energy} at the start of your turn. All enemies start each combat with #11#1#12# {Strength}.'}
function PhilosophersStone:onCombatStart()
	for _,enemy in ipairs(enemies) do
		addAction(ApplyPowerAction:new(player,StrengthPower:new(enemy,1)))
	end
end

RunicDome = EnergyRelic:new{name='Runic Dome',icon=180,tier='boss',description='Gain {Energy} at the start of your turn. You can no longer see enemy intents.'}

RunicPryamid = Relic:new{name='Runic Pyramid',icon=181,tier='boss',description='At the end of your turn, you no longer discard your hand.'}

SacredBark = Relic:new{name='Sacred Bark',icon=220,tier='boss',description='Double the effectiveness of potions.'}
function SacredBark:onObtained()
	for _,potion in ipairs(potions) do
		potion:applyPowers()
	end
end

function SacredBark:modifyPotionValue(value)
	return value * 2
end

SlaversCollar = Relic:new{name='Slaver\'s Collar',icon=182,tier='boss',activated=false,description='During Boss and Elite combats, gain {Energy} at the start of your turn.'}
function SlaversCollar:onCombatStart()
	if combatType == 'elite' or table.anyMatch(enemies,function (enemy) return enemy.type == 'boss' end) then
		maxEnergy = maxEnergy + 1
		self.activated = true
	end
end

function SlaversCollar:onCombatEnd()
	if self.activated then
		maxEnergy = maxEnergy - 1
		self.activated = false
	end
end

SneckoEye = Relic:new{name='Snecko Eye',icon=183,tier='boss',priority=60,description='At the start of each turn, draw #11#2#12# additional cards. Start each combat with {36}.'}
function SneckoEye:onCombatStart()
	addAction(ApplyPowerAction:new(player,ConfusionPower:new(player)))
end

function SneckoEye:onTurnStartPostDraw()
	addAction(DrawCardAction:new(2))
end

Sozu = EnergyRelic:new{name='Sozu',icon=184,tier='boss',description='Gain {Energy} at the start of your turn. You can no longer obtain potions.'}
function Sozu:onBeforeObtainPotion()
	return false
end

TinyHouse = Relic:new{
	name='Tiny House',icon=185,tier='boss',
	description='Upon pickup, obtain #11#1#12# potion. NL Gain #11#50 #4#Gold#12#. NL Raise your Max HP by #11#5#12#. NL Obtain #11#1#12# card. NL Upgrade #11#1#12# random card.'
}
function TinyHouse:onObtained()
	local rewards = {}
	local random = makeRand(act.id,room.id,7)
	addGoldReward(rewards,50,nil,false)
	addPotionReward(rewards,getTrueRandomPotionType(random):new())
	player:increaseMaxHp(5)
	generateCardRewards(rewards,random)

	local cards = shallowcopy(deck)
	table.retainIf(cards,function(c) return c:canUpgrade() end)
	if #cards > 0 then
		upgradeCardsWithEffect({CardItem:new{card=cards[random:randInt(#cards)],x=240,y=0,isNotInHand=true}})
	end

	openWindowAbove(RewardWindow:new{rewards=rewards,canClose=true,title='Tiny House!',onProceed=function(self) self:close() end})
end

VelvetChoker = EnergyRelic:new{name='Velvet Choker',icon=186,tier='boss',priority=0,description='Gain {Energy} at the start of your turn. You can no longer play more than #11#6#12# cards per turn.'}
function VelvetChoker:onUseCard()
	self.counter = self.counter + 1
end

function VelvetChoker:canUseCard()
	if self.counter >= 6 then
		return false
	end
end

function VelvetChoker:onTurnStart()
	self.counter = 0
end

function VelvetChoker:onCombatEnd()
	self.counter = -1
end

Cauldron = Relic:new{name='Cauldron',icon=48,tier='shop',description='Upon pickup, brews #11#5#12# random potions.'}
function Cauldron:onObtained()
	local rewards = {}
	local random = makeRand(act.id,room.id,7)
	for _=1,5 do
		addPotionReward(rewards,getTrueRandomPotionType(random):new())
	end
	openWindowAbove(RewardWindow:new{rewards=rewards,canClose=true,title='Blup blip bloop!',onProceed=function(self) self:close() end})
end

ChemicalX = Relic:new{name='Chemical X',icon=49,tier='shop',description='The effects of your cost #11#X#12# cards are increased by #11#2#12#.'}
function ChemicalX:modifyXCardAmount(amount)
	return amount + 2
end

ClockworkSouvenir = Relic:new{name='Clockwork Souvenir',icon=50,tier='shop',description='Start each combat with #11#1#12# {22}.'}
function ClockworkSouvenir:onCombatStart()
	addAction(ApplyPowerAction:new(player,ArtifactPower:new(player,1)))
end

DollysMirror = Relic:new{name='Dolly\'s Mirror',icon=64,tier='shop',description='Upon pickup, obtain an additional copy of a card in your deck.'}
function DollysMirror:onObtained()
	duplicateCardFromDeck(1,false,nil,'Choose a Card to Copy')
end

FrozenEye = Relic:new{name='Frozen Eye',icon=65,tier='shop',description='When viewing your #4#Draw Pile#12#, the cards are now shown in order.'}

HandDrill = Relic:new{name='Hand Drill',icon=66,tier='shop',description='Whenever you break an enemy\'s {Block}, apply #11#2#12# {Vulnerable}.'}
function HandDrill:onBreakBlock(target)
	addAction(ApplyPowerAction:new(player,VulnerablePower:new(target,2)))
end

LeesWaffle = Relic:new{name='Lee\'s Waffle',icon=80,tier='shop',description='Upon pickup, raise your Max HP by #11#7#12# and heal all HP.'}
function LeesWaffle:onObtained()
	player:increaseMaxHp(7)
	player:heal(player.maxHp)
end

MedicalKit = Relic:new{name='Medical Kit',icon=81,tier='shop',description='Unplayable {Status} cards can now be played. Whenever you play a {Status} card, exhaust it.'}
function MedicalKit:canUseCard(card)
	if card.type == 'status' and not card:baseCanUse(true) then
		return true
	end
end

function MedicalKit:onUseCard(card,_,action)
	if card.type == 'status' then
		action.exhaust = true
	end
end

MembershipCard = Relic:new{name='Membership Card',icon=82,tier='shop',description='#11#50%#12# discount on all products!'}
function MembershipCard:modifyShopPrice(price)
	return price * 0.5
end

function MembershipCard:onObtained()
	if currentEvent and getmetatable(currentEvent) == MerchantEvent then
		currentEvent:modifyPrices()
	end
end

OrangePellets = Relic:new{
	name='Orange Pellets',icon=53,tier='shop',power=false,attack=false,skill=false,
	description='Whenever you play a {Power}, {Attack}, and {Skill} in the same turn, remove all of your debuffs.'
}
function OrangePellets:onTurnStart()
	self.power = false
	self.attack = false
	self.skill = false
end

function OrangePellets:onUseCard(card)
	if card.type == 'power' then
		self.power = true
	elseif card.type == 'attack' then
		self.attack = true
	elseif card.type == 'skill' then
		self.skill = true
	end
	if self.power and self.attack and self.skill then
		self.power = false
		self.attack = false
		self.skill = false
		addAction(RemoveDebuffsAction:new(player))
	end
end

Orrery = Relic:new{name='Orrery',icon=69,tier='shop',description='Upon pickup, choose and add #11#5#12# cards to your deck.'}
function Orrery:onObtained()
	local rewards = {}
	local random = makeRand(act.id,room.id,7)
	for _=1,5 do
		generateCardRewards(rewards,random)
	end
	openWindowAbove(RewardWindow:new{rewards=rewards,canClose=true,title='Knowledge!',onProceed=function(self) self:close() end})
end

SlingOfCourage = Relic:new{name='Sling of Courage',icon=85,tier='shop',description='Start each Elite combat with #11#2#12# {Strength}.'}
function SlingOfCourage:onCombatStart()
	if combatType == 'elite' then
		addAction(ApplyPowerAction:new(player,StrengthPower:new(player,2)))
	end
end

StrangeSpoon = Relic:new{name='Strange Spoon',icon=205,tier='shop',description='Cards which exhaust when played will instead discard #11#50%#12# of the time.'}

TheAbacus = Relic:new{name='The Abacus',icon=221,tier='shop',description='Whenever you shuffle your draw pile, gain #11#6#12# {Block}.'}
function TheAbacus:onShuffle()
	addAction(GainBlockAction:new{target=player,value=6})
end

Toolbox = Relic:new{name='Toolbox',icon=237,tier='shop',description='At the start of each combat, choose #11#1#12# of #11#3#12# random colorless cards and add the chosen card into your hand.'}
function Toolbox:onCombatStart()
	addAction(DiscoveryAction:new{colorless=true,amount=1})
end

Enchiridion = Relic:new{name='Enchiridion',icon=188,tier='special',description='At the start of each combat, add a random {Power} card into your hand. It costs #11#0#12# for that turn.'}
function Enchiridion:onTurnStartPostDraw(turn)
	if turn == 1 then
		local card = getPlayerCardType(miscRand,nil,'power'):new()
		card.costForOneTurnPlay = 0
		addAction(MakeTempCardToHandAction:new(card,1,{cardItem=CardItem:new{card=card,x=getRelicX(table.indexOf(relics,self) or 1),y=13}}))
	end
end

MarkOfTheBloom = Relic:new{name='Mark of the Bloom',icon=191,tier='special',priority=200,description='You can no longer heal.'}
function MarkOfTheBloom:onBeforeHeal()
	return 0
end

MutagenicStrength = Relic:new{name='Mutagenic Strength',icon=207,tier='special',description='Start each combat with #11#3#12# {Strength}. At the end of your first turn, lose #11#3#12# {Strength}.'}
function MutagenicStrength:onCombatStart()
	addAction(ApplyPowerAction:new(player,StrengthPower:new(player,3)))
	addAction(ApplyPowerAction:new(player,LoseStrengthPower:new(player,3)))
end

Necronomicon = Relic:new{name='Necronomicon',icon=255,tier='special',activated=false,description='The first {Attack} played each turn that costs #11#2#12# or more is played twice. Upon pickup, obtain a special {Curse}.'}
function Necronomicon:onObtained()
	local cardItem = CardItem:new{card=Necronomicurse:new(),x=0,y=136,tx=120,ty=68,isNotInHand=true}
	addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=30,duration=50,tx=240,ty=0})
	obtainCard(cardItem.card)
end

function Necronomicon:onTurnStart()
	self.activated = true
end

function Necronomicon:onUseCard(card,target,useCardAction)
	if card.type == 'attack' and card.cost >= 2 and self.activated and not useCardAction.isDoubleTap then
		self.activated = false

		local cardItem = useCardAction.cardItem:copy()
		local action = UseCardAction:new{cardItem=cardItem,isDoubleTap=true,tempCard=true,free=true,target=target,energyOnUse=useCardAction.energyOnUse}
		action.useCardPosition = fillCardPosition(cardItem,2)
		table.insert(limbo,cardItem)
		addAction(action)
	end
end

NilrysCodex = Relic:new{name='Nilry\'s Codex',icon=206,tier='special',description='At the end of your turn, you may shuffle #11#1#12# of #11#3#12# random cards into your draw pile.'}
function NilrysCodex:onTurnEnd()
	addAction(DiscoveryAction:new{target='drawPile',canClose=true})
end

colorlessRelics = {
	-- special
	Circlet,NeowsLament,GoldenIdol,OddMushroom,WarpedTongs,SpiritPoop,CultistMask,FaceOfCleric,GremlinMask,NlothsMask,
	SsserpentHead,NlothsGift,BloodyIdol,Enchiridion,MarkOfTheBloom,MutagenicStrength,Necronomicon,NilrysCodex,
	-- common
	Anchor,PotionBelt,PreservedInsect,Akabeko,AncientTeaSet,ArtOfWar,BagOfMarbles,BagOfPreparation,RegalPillow,BloodVial,
	BronzeScales,CentennialPuzzle,CeramicFish,DreamCatcher,HappyFlower,JuzuBracelet,Lantern,MawBank,MealTicket,Nunchaku,
	OddlySmoothStone,Omamori,Orichalcum,PenNib,SmilingMask,Strawberry,TheBoot,TinyChest,ToyOrnithopter,Vajra,WarPaint,
	Whetstone,
	-- uncommon
	EternalFeather,BlueCandle,BottledFlame,BottledLightning,BottledTornado,DarkstonePeriapt,GremlinHorn,HornCleat,
	FrozenEgg,MoltenEgg,ToxicEgg,InkBottle,Kunai,Shuriken,OrnamentalFan,LetterOpener,Matryoshka,MeatOnTheBone,MercuryHourglass,
	MummifiedHand,Pantograph,Pear,QuestionCard,StrikeDummy,Sundial,TheCourier,WhiteBeastStatue,SingingBowl,
	-- rare
	Calipers,BirdFacedUrn,CaptainsWheel,DeadBranch,DuVuDoll,FossilizedHelix,GamblingChip,Ginger,Turnip,Girya,IceCream,
	IncenseBurner,LizardTail,Mango,OldCoin,PeacePipe,PocketWatch,PrayerWheel,Shovel,StoneCalendar,ThreadAndNeedle,Torii,
	TungstenRod,UnceasingTop,WingBoots,
	-- boss
	CoffeeDripper,FusionHammer,Ectoplasm,Astrolabe,BlackStar,BustedCrown,CallingBell,CursedKey,EmptyCage,PandorasBox,
	PhilosophersStone,RunicDome,RunicPryamid,SacredBark,SlaversCollar,SneckoEye,Sozu,TinyHouse,VelvetChoker,
	-- shop
	Cauldron,ChemicalX,ClockworkSouvenir,DollysMirror,FrozenEye,HandDrill,LeesWaffle,MedicalKit,MembershipCard,OrangePellets,
	Orrery,SlingOfCourage,StrangeSpoon,TheAbacus,Toolbox,
}
