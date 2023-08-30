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

Circlet = Relic:new{name='Circlet',description='Collect as many as you can.',icon=55,tier='special',counter=1}
function Circlet:onBeforeObtainRelic(relic)
	if getmetatable(relic) == Circlet then
		self.counter = self.counter + 1
		return false
	end
	return nil
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
		for _, enemy in ipairs(enemies) do
			if enemy.alive then
				enemy.hp = 1
			end
		end
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
	return 1.25
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
	return act.id == 1
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
	addAction(ApplyPowerAction:new(WeakPower:new(player,1,true)))
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
	if not isInShop() or roomActionType == 'combat' then
		return chance * 3
	end
end

PotionBelt = Relic:new{name='Potion Belt',icon=11,tier='common',description='Upon pickup, gain #11#2#12# Potion slots.'}
function PotionBelt:onObtained()
	table.insert(potions,PotionSlot)
	table.insert(potions,PotionSlot)
end

PreservedInsect = Relic:new{name='Preserved Insect',icon=16,tier='common',description='Enemies in Elite combats have #11#25%#12# less HP.'}
function PreservedInsect:onCombatStart()
	if room.type == 'elite' then
		for _, enemy in ipairs(enemies) do
			if enemy.alive then
				enemy.hp = math.min(enemy.hp, math.ceil(enemy.maxHp * 0.75))
			end
		end
	end
end

Akabeko = Relic:new{name='Akabeko',icon=30,tier='common',description='Your first {Attack} each combat deals #11#8#12# additional damage.'}
function Akabeko:onCombatStart()
	addAction(ApplyPowerAction:new(VigorPower:new(player,8)))
end

AncientTeaSet = Relic:new{name='Ancient Tea Set',icon=31,tier='common',description='Whenever you enter a Rest Site, start the next combat with {Energy} {Energy}.'}
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
			addAction(ApplyPowerAction:new(VulnerablePower:new(enemy,1)))
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

BloodVial = Relic:new{name='Blood Vial',icon=42,tier='common',description='At the start of each combat, heal #11#2#12# HP.'}
function BloodVial:onCombatStart()
	player:heal(2)
end

BronzeScales = Relic:new{name='Bronze Scales',icon=43,tier='common',description='Start each combat with 3 {29}.'}
function BronzeScales:onCombatStart()
	addAction(ApplyPowerAction:new(ThornsPower:new(player,3)))
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
function CeramicFish:onObtainCard()
	gainGold(9)
end

DreamCatcher = Relic:new{name='Dream Catcher',icon=71,tier='common',description='Whenever you #4#Rest#12#, you may add a card to your deck.'}
function DreamCatcher:onRest(campfireEvent)
	local rewards = {}
	generateCardRewards(rewards,campfireEvent.random)
	openWindowAbove(CardRewardWindow:new{cards=rewards[1].value,title='Dreaming?'}, function(cardItem)
		if cardItem then
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
function MawBank:onEnterRoom()
	if self.saved == 0 then
		gainGold(12)
	end
end

function MawBank:onLoseGold()
	if isInShop() then
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
	addAction(ApplyPowerAction:new(DexterityPower:new(player,1)))
end

Omamori = Relic:new{name='Omamori',icon=93,tier='common',counter=2,description='Negate the next #11#2#12# {Curse} you obtain.'}
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
	return not isInShop()
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
	addAction(ApplyPowerAction:new(StrengthPower:new(player,1)))
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
			addAction(ApplyPowerAction:new(DexterityPower:new(player,1)))
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
			addAction(ApplyPowerAction:new(StrengthPower:new(player,1)))
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
	return not isInShop()
end

function TheCourier:modifyShopPrice(price)
	return price * 0.8
end

WhiteBeastStatue = Relic:new{name='White Beast Statue',icon=144,tier='uncommon',description='Potions always appear in combat rewards.'}

SingingBowlOption = ColorlessCard:new{baseCost=-2,rarity='special',type='skill',name='Singing Bowl',description='Raise your Max HP by #11#2#12# without adding cards.'}
SingingBowl = Relic:new{name='Singing Bowl',icon=140,tier='uncommon',description='When adding cards into your deck, you may raise your Max HP by #11#2#12# instead.'}
function SingingBowl:modifyCardReward(reward)
	table.insert(reward.value,SingingBowlOption)
end

function SingingBowl:onBeforeObtainCard(card)
	if card == SingingBowlOption then
		player:increaseMaxHp(2)
		return false
	end
end

colorlessRelics = {
	-- special
	Circlet,NeowsLament,GoldenIdol,OddMushroom,WarpedTongs,SpiritPoop,CultistMask,FaceOfCleric,GremlinMask,NlothsMask,
	SsserpentHead,NlothsGift,BloodyIdol,
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
	Calipers,
	-- boss
	CoffeeDripper,FusionHammer,Ectoplasm,
}
