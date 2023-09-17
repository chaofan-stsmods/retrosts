-- colorless
---@diagnostic disable: lowercase-global

local colorlessCards
local curseCards

function getColorlessCards()
	return colorlessCards
end

function getCurseCards()
	return curseCards
end

ColorlessCard = Card:new{color={14,15},costIcon=46,typeIconColor=13,colorName='colorless'}

Wound = ColorlessCard:new{ name='Wound',description='Unplayable.',rarity='special',baseCost=-2,type='status',baseCanUse=false,canUpgrade=false,playerTarget=true }

Dazed = ColorlessCard:new{ name='Dazed',description='Unplayable. NL Ethereal.',rarity='special',baseCost=-2,type='status',baseCanUse=false,canUpgrade=false,ethereal=true,playerTarget=true }

Slimed = ColorlessCard:new{ name='Slimed',description='Exhaust.',rarity='special',baseCost=1,type='status',canUpgrade=false,exhaust=true,playerTarget=true }

Burn = ColorlessCard:new{
	name='Burn',description='Unplayable. NL At the end of turn, {Damage} !M! to you.',rarity='special',baseCost=-2,type='status',
	baseCanUse=false,canUpgrade=false,baseMagic=2,upgrade={baseMagic=4},autoPlayOnEndTurn=true,playerTarget=true
}
function Burn:autoPlay()
	return { DamageAction:new{source=player,target=player,value=self.magic,type='power'} }
end

Void = ColorlessCard:new{ name='Void',description='Unplayable. NL Ethereal. NL Whenever this card is drawn, lose {Energy}.',rarity='special',baseCost=-2,type='status',baseCanUse=false,canUpgrade=false,ethereal=true,playerTarget=true }
function Void:onDraw(card)
	if card == self then
		addAction(GainEnergyAction:new(-1))
	end
end

BandageUp = ColorlessCard:new{
	name='Bandage Up',description='Heal !M! HP. NL Exhaust.',baseCost=0,type='skill',rarity='uncommon',
	playerTarget=true,baseMagic=4,upgrade={baseMagic=6},exhaust=true,canGenerateInCombat=false
}
function BandageUp:use()
	return { HealAction:new{target=player,value=self.magic} }
end

Blind = ColorlessCard:new{
	name='Blind',description='Apply !M! {Weak}.',baseCost=0,type='skill',rarity='uncommon',
	enemyTarget=true,baseMagic=2,upgrade={description='Apply !M! {Weak} to all enemies.',toAllEnemies=true}
}
function Blind:use(target)
	if self.toAllEnemies then
		local result = {}
		for _, enemy in ipairs(enemies) do
			table.insert(result,ApplyPowerAction:new(player,WeakPower:new(enemy,self.magic)))
		end
		return result
	else
		return { ApplyPowerAction:new(player,WeakPower:new(target,self.magic)) }
	end
end

Finesse = ColorlessCard:new{
	name='Finesse',description='Gain !B! {Block}. NL Draw 1 card.',baseCost=0,type='skill',rarity='uncommon',
	playerTarget=true,baseBlock=2,upgrade={baseBlock=4}
}
function Finesse:use()
	return { GainBlockAction:new{target=player,value=self.block}, DrawCardAction:new(1) }
end

MasterOfStrategy = ColorlessCard:new{
	name='Master of Strategy',description='Draw !M! cards. NL Exhaust.',baseCost=0,type='skill',rarity='rare',
	playerTarget=true,baseMagic=3,upgrade={baseMagic=4},exhaust=true
}
function MasterOfStrategy:use()
	return { DrawCardAction:new(self.magic) }
end

HandOfGreed = ColorlessCard:new{
	name='Hand of Greed',description='{Damage} !D!. NL If fatal, gain !M! Gold.',baseCost=2,rarity='rare',
	enemyTarget=true,baseMagic=20,baseDamage=20,upgrade={baseMagic=25,baseDamage=25}
}
function HandOfGreed:use(target)
	local damageAction = DamageAction:new{source=player,target=target,value=self.damage}
	return {
		damageAction,
		FatalAction:new{target=target,action=damageAction,callback=function ()
			gainGold(self.magic)
		end}
	}
end

ThinkingAhead = ColorlessCard:new{
	name='Thinking Ahead',description='Draw !M! cards. NL Put a card from hand on the top of draw pile. NL Exhaust.',baseCost=0,type='skill',rarity='rare',
	playerTarget=true,baseMagic=2,upgrade={exhaust=false,description='Draw !M! cards. NL Put a card from hand on the top of draw pile.'},exhaust=true
}
function ThinkingAhead:use()
	return {
		DrawCardAction:new(self.magic),
		AnonymousAction:new(function ()
			if #hand == 0 then
				return
			elseif #hand == 1 then
				addAction(1,PutCardOnDrawCardTopAction:new{cardItem=hand[1],show=true})
				removeHand(1)
			else
				openWindowAbove(HandSelectWindow:new{cardItems=hand,title='Choose a Card to Put on Top of Draw Pile',max=1},function (cards)
					for _, cardItem in ipairs(cards) do
						local cardIndex = table.indexOf(hand,cardItem)
						addAction(1,PutCardOnDrawCardTopAction:new{cardItem=cardItem})
						removeHand(cardIndex)
					end
				end)
			end
		end)
	}
end

JAX = ColorlessCard:new{
	name='J.A.X.',description='Lose 3 HP. NL Gain !M! {Strength}.',baseCost=0,type='skill',rarity='special',
	playerTarget=true,baseMagic=2,upgrade={baseMagic=3},
}
function JAX:use()
	return {
		DamageAction:new{source=player,target=player,value=3,type='hpLoss'},
		ApplyPowerAction:new(player,StrengthPower:new(player,self.magic))
	}
end

Apparition = ColorlessCard:new{
	name='Apparition',description='Ethereal. NL Gain 1 {35}. NL Exhaust.',baseCost=1,type='skill',rarity='special',
	playerTarget=true,upgrade={ethereal=false,description='Gain 1 {35}. NL Exhaust.'},exhaust=true,ethereal=true,
}
function Apparition:use()
	return { ApplyPowerAction:new(player,IntangiblePower:new(player,1)) }
end

RitualDagger = ColorlessCard:new{
	name='Ritual Dagger',description='{Damage} !D!. NL If Fatal, this card +!M! damage permanently. NL Exhaust.',
	baseCost=1,baseDamage=15,baseMagic=3,type='attack',rarity='special',enemyTarget=true,upgrade={baseMagic=5},exhaust=true,
	source=nil,
}
function RitualDagger:use(target)
	local damageAction = DamageAction:new{source=player,target=target,value=self.damage}
	return {
		damageAction,
		FatalAction:new{target=target,action=damageAction,callback=function ()
			self.baseDamage = self.baseDamage + self.magic
			self:applyPowers()
			if self.source and table.indexOf(deck,self.source) then
				self.source.baseDamage = self.source.baseDamage + self.magic
				self.source:resetPowers()
			end
		end}
	}
end

function RitualDagger:copy()
	local copied = ColorlessCard.copy(self)
	copied.source = self
	return copied
end

function RitualDagger:save()
	return ColorlessCard.save(self) | (self.baseDamage << 1)
end

function RitualDagger:load(meta)
	ColorlessCard.load(self,meta & 1)
	self.baseDamage = meta >> 1
	self.damage = self.baseDamage
end

Bite = ColorlessCard:new{
	name='Bite',description='{Damage} !D!. NL Heal !M! HP.',baseCost=1,baseDamage=7,baseMagic=2,type='attack',rarity='special',
	enemyTarget=true,upgrade={baseDamage=8,baseMagic=3},canGenerateInCombat=false,
}
function Bite:use(target)
	return {
		DamageAction:new{source=player,target=target,value=self.damage},
		HealAction:new{target=player,value=self.magic}
	}
end

Madness = ColorlessCard:new{
	name='Madness',description='Reduce the cost of a random card in hand to 0 this combat. NL Exhaust.',baseCost=1,type='skill',
	rarity='uncommon',playerTarget=true,exhaust=true,upgrade={baseCost=0},
}
function Madness:use()
	return {AnonymousAction:new(function ()
		local candidates = shallowcopy(hand)
		table.retainIf(candidates,function(c) return c.card:getCost() > 0 end)
		if #candidates > 0 then
			local card = candidates[miscRand:randInt(#candidates)]
			card.card.baseCost = 0
			card.card.cost = 0
			card.card.baseCostModified = true
		end
	end)}
end

DarkShackles = ColorlessCard:new{
	name='Dark Shackles',description='Enemy loses !M! Strength this turn. NL Exhaust.',baseCost=0,type='skill',rarity='uncommon',
	enemyTarget=true,baseMagic=9,upgrade={baseMagic=15},exhaust=true,
}
function DarkShackles:use(target)
	local action = ApplyPowerAction:new(player,StrengthPower:new(target,-self.magic))
	return {
		action,
		AnonymousAction:new(function ()
			if action.succeeded then
				addAction(1,ApplyPowerAction:new(player,ShackledPower:new(target,self.magic)))
			end
		end),
	}
end

DeepBreath = ColorlessCard:new{
	name='Deep Breath',description='Shuffle your discard pile into your draw pile. NL Draw !M! card.',baseCost=0,type='skill',rarity='uncommon',
	playerTarget=true,baseMagic=1,upgrade={baseMagic=2,description='Shuffle your discard pile into your draw pile. NL Draw !M! cards.'},
}
function DeepBreath:use()
	local actions = {}
	if #discardPile > 0 then
		table.insert(actions,ShuffleAction:new())
	end
	table.insert(actions,DrawCardAction:new(self.magic))
	return actions
end

Discovery = ColorlessCard:new{
	name='Discovery',description='Choose 1 of 3 random cards to add into hand. It costs 0 this turn. NL Exhaust.',baseCost=1,type='skill',rarity='uncommon',
	playerTarget=true,exhaust=true,upgrade={description='Choose 1 of 3 random cards to add into hand. It costs 0 this turn.',exhaust=false},
}
function Discovery:use()
	return { DiscoveryAction:new{cost=0} }
end

DramaticEntrance = ColorlessCard:new{
	name='Dramatic Entrance',description='Innate. NL {Damage} !D! to all enemies. NL Exhaust.',baseCost=0,type='attack',rarity='uncommon',
	enemyTarget=true,toAllEnemies=true,innate=true,exhaust=true,baseDamage=8,upgrade={baseDamage=12},
}
function DramaticEntrance:use()
	return { DamageAllEnemiesAction:new{source=player,value=self.multiDamage} }
end

Enlightenment = ColorlessCard:new{
	name='Enlightenment',description='Reduce the cost of all cards in your hand to 1 this turn.',baseCost=0,type='skill',rarity='uncommon',
	playerTarget=true,upgrade={description='Reduce the cost of all cards in your hand to 1 this combat.'},
}
function Enlightenment:use()
	return {
		AnonymousAction:new(function ()
			for _, cardItem in ipairs(hand) do
				local card = cardItem.card
				if card:getCost() > 1 then
					if self.upgraded then
						card.baseCost = 1
						card.baseCostModified = true
					else
						card.costForOneTurnPlay = 1
					end
					card:applyPowers()
				end
			end
		end)
	}
end

FlashOfSteel = ColorlessCard:new{
	name='Flash of Steel',description='{Damage} !D!. NL Draw 1 card.',baseCost=0,type='attack',rarity='uncommon',
	enemyTarget=true,baseDamage=3,upgrade={baseDamage=6},
}
function FlashOfSteel:use(target)
	return { DamageAction:new{source=player,target=target,value=self.damage}, DrawCardAction:new(1) }
end

ForeThought = ColorlessCard:new{
	name='Forethought',description='Put a card to the bottom of draw pile. It costs 0 until played.',baseCost=0,type='skill',rarity='uncommon',
	playerTarget=true,upgrade={description='Put any num- ber of cards to the bottom of draw pile. They cost 0 until played.',descriptionWidth=54},
}
function ForeThought:use()
	return {
		AnonymousAction:new(function ()
			if #hand == 0 then
				return
			elseif #hand == 1 and not self.upgraded then
				local card = hand[1].card
				addAction(1,PutCardInDrawPileAction:new{cardItem=hand[1],position=1,show=true,duration=10})
				if card:getCost() > 0 then
					card.costForOnePlay = 0
				end
				removeHand(1)
			else
				local title = self.upgraded and 'Choose Cards to Put on Bottom of Draw Pile' or 'Choose a Card to Put on Bottom of Draw Pile'
				openWindowAbove(HandSelectWindow:new{cardItems=hand,title=title,min=self.upgraded and 0 or 1,max=self.upgraded and HAND_LIMIT or 1},function (cards)
					for _, cardItem in ipairs(cards) do
						local cardIndex = table.indexOf(hand,cardItem)
						addAction(1,PutCardInDrawPileAction:new{cardItem=cardItem,position=1,duration=1})
						if cardItem.card:getCost() > 0 then
							cardItem.card.costForOnePlay = 0
						end
						removeHand(cardIndex)
					end
				end)
			end
		end)
	}
end

GoodInstincts = ColorlessCard:new{
	name='Good Instincts',description='Gain !B! {Block}.',baseCost=0,type='skill',rarity='uncommon',
	playerTarget=true,baseBlock=6,upgrade={baseBlock=9},
}
function GoodInstincts:use()
	return { GainBlockAction:new{target=player,value=self.block} }
end

Impatience = ColorlessCard:new{
	name='Impatience',description='If you have no {Attack} in your hand, draw !M! cards.',baseCost=0,type='skill',rarity='uncommon',
	playerTarget=true,baseMagic=2,upgrade={baseMagic=3},
}
function Impatience:use()
	return {
		AnonymousAction:new(function ()
			if table.allMatch(hand,function (cardItem) return cardItem.card.type ~= 'attack' end) then
				addAction(1,DrawCardAction:new(self.magic))
			end
		end)
	}
end

function Impatience:checkGlow()
	if table.allMatch(hand,function (cardItem) return cardItem.card.type ~= 'attack' end) then
		return 4
	end
end

JackOfAllTrades = ColorlessCard:new{
	name='Jack of All Trades',description='Add !M! random colorless card into hand. NL Exhaust.',baseCost=0,type='skill',rarity='uncommon',
	playerTarget=true,exhaust=true,baseMagic=1,upgrade={baseMagic=2,description='Add !M! random colorless cards into hand. NL Exhaust.'}
}
function JackOfAllTrades:use()
	local result = {}
	for i=1,self.magic do
		local cardType = getColorlessCardType(miscRand,nil,nil,true)
		local card = cardType:new()
		result[i] = MakeTempCardToHandAction:new(card,1)
	end
	return result
end

MindBlast = ColorlessCard:new{
	name='Mind Blast',description='Innate. NL Deal damage equal to the number of cards in draw pile.',baseCost=2,type='attack',rarity='uncommon',
	enemyTarget=true,upgrade={baseCost=1},innate=true,displayDamage='?'
}
function MindBlast:applyPowers(target)
	self.displayDamage = false
	self.baseDamage = #drawPile
	ColorlessCard.applyPowers(self,target)
end

function MindBlast:resetPowers()
	self.displayDamage = '?'
	ColorlessCard.resetPowers(self)
end

function MindBlast:onDraw()
	self:applyPowers()
end

function MindBlast:use(target)
	return { DamageAction:new{source=player,target=target,value=self.damage} }
end

Panacea = ColorlessCard:new{
	name='Panacea',description='Gain !M! {22}. NL Exhaust.',baseCost=0,type='skill',rarity='uncommon',
	playerTarget=true,baseMagic=1,upgrade={baseMagic=2},exhaust=true,
}
function Panacea:use()
	return { ApplyPowerAction:new(player,ArtifactPower:new(player,self.magic)) }
end

PanicButton = ColorlessCard:new{
	name='Panic Button',description='Gain !B! {Block}. NL You cannot gain Block from cards for !M! turns. NL Exhaust.',
	baseCost=0,type='skill',rarity='uncommon',playerTarget=true,baseBlock=30,baseMagic=2,upgrade={baseBlock=40},exhaust=true,
}
function PanicButton:use()
	return {
		GainBlockAction:new{target=player,value=self.block},
		ApplyPowerAction:new(player,NoBlockPower:new(player,self.magic))
	}
end

Purity = ColorlessCard:new{
	name='Purity',description='Exhaust up to !M! cards in your hand. NL Exhaust.',baseCost=0,type='skill',rarity='uncommon',
	playerTarget=true,baseMagic=3,upgrade={baseMagic=5},exhaust=true,
}
function Purity:use()
	return {
		AnonymousAction:new(function ()
			if #hand == 0 then
				return
			else
				openWindowAbove(HandSelectWindow:new{cardItems=hand,title='Choose Cards to Exhaust ({#}/'..self.magic..')',min=0,max=self.magic},function (cards)
					effectRandom:shuffle(cards)
					for i,cardItem in ipairs(cards) do
						local cardIndex = table.indexOf(hand,cardItem)
						addAction(i,ExhaustCardAction:new{cardItem=cardItem,duration=10})
						removeHand(cardIndex)
					end
				end)
			end
		end)
	}
end

SwiftStrike = ColorlessCard:new{
	name='Swift Strike',description='{Damage} !D!.',baseCost=0,type='attack',rarity='uncommon',
	enemyTarget=true,baseDamage=7,upgrade={baseDamage=10},tags={'strike'},
}
function SwiftStrike:use(target)
	return { DamageAction:new{source=player,target=target,value=self.damage} }
end

Trip = ColorlessCard:new{
	name='Trip',description='Apply !M! {Vulnerable}.',baseCost=0,type='skill',rarity='uncommon',
	enemyTarget=true,baseMagic=2,upgrade={description='Apply !M! {Vulnerable} to all enemies.',toAllEnemies=true}
}
function Trip:use(target)
	if self.toAllEnemies then
		local result = {}
		for _, enemy in ipairs(enemies) do
			table.insert(result,ApplyPowerAction:new(player,VulnerablePower:new(enemy,self.magic)))
		end
		return result
	else
		return { ApplyPowerAction:new(player,VulnerablePower:new(target,self.magic)) }
	end
end

Apotheosis = ColorlessCard:new{
	name='Apotheosis',description='Upgrade all your cards for the rest of combat. NL Exhaust.',baseCost=2,type='skill',rarity='rare',
	playerTarget=true,exhaust=true,upgrade={baseCost=1}
}
function Apotheosis:use()
	return { AnonymousAction:new(function ()
		for _, cardItem in ipairs(hand) do
			local card = cardItem.card
			if card:canUpgrade() then
				card:upgrade()
				card:applyPowers()
			end
		end
		for _, card in ipairs(drawPile) do
			if card:canUpgrade() then
				card:upgrade()
				card:resetPowers()
			end
		end
		for _, card in ipairs(discardPile) do
			if card:canUpgrade() then
				card:upgrade()
				card:resetPowers()
			end
		end
		for _, card in ipairs(exhaustPile) do
			if card:canUpgrade() then
				card:upgrade()
				card:resetPowers()
			end
		end
	end) }
end

Chrysalis = ColorlessCard:new{
	name='Chrysalis',description='Shuffle !M! random {Skill} into draw pile. They cost 0 this combat. NL Exhaust.',baseCost=2,type='skill',rarity='rare',
	playerTarget=true,exhaust=true,baseMagic=3,upgrade={baseMagic=5},
}
function Chrysalis:use()
	local result = {}
	for i=1,self.magic do
		local cardType = getPlayerCardType(miscRand,nil,'skill',true)
		local card = cardType:new()
		if card:getCost() > 0 then
			card.baseCost = 0
			card.cost = 0
			card.baseCostModified = true
		end
		result[i] = MakeTempCardToDrawPileAction:new(card,1,{pauseDuration=60-i*9})
	end
	return result
end

Metamorphosis = ColorlessCard:new{
	name='Metamorphosis',description='Shuffle !M! random {Attack} into draw pile. They cost 0 this combat. NL Exhaust.',baseCost=2,type='skill',rarity='rare',
	playerTarget=true,exhaust=true,baseMagic=3,upgrade={baseMagic=5},
}
function Metamorphosis:use()
	local result = {}
	for i=1,self.magic do
		local cardType = getPlayerCardType(miscRand,nil,'attack',true)
		local card = cardType:new()
		if card:getCost() > 0 then
			card.baseCost = 0
			card.cost = 0
			card.baseCostModified = true
		end
		result[i] = MakeTempCardToDrawPileAction:new(card,1,{pauseDuration=60-i*9})
	end
	return result
end

Magnetism = ColorlessCard:new{
	name='Magnetism',description='At the start of turn, add a random colorless card into hand.',baseCost=2,type='power',rarity='rare',
	playerTarget=true,upgrade={baseCost=1},
}
function Magnetism:use()
	return { ApplyPowerAction:new(player,MagnetismPower:new(player)) }
end

MagnetismPower = Power:new{icon=63,description='At the start of turn, add #11#!A!#12# random colorless card{s} into your hand.'}
function MagnetismPower:onTurnStart()
	for _=1,self.amount do
		addAction(MakeTempCardToHandAction:new(getColorlessCardType(miscRand,nil,nil,true):new()))
	end
end

Mayhem = ColorlessCard:new{
	name='Mayhem',description='At the start of turn, play the top card of draw pile.',baseCost=2,type='power',rarity='rare',
	playerTarget=true,upgrade={baseCost=1},
}
function Mayhem:use()
	return { ApplyPowerAction:new(player,MayhemPower:new(player)) }
end

MayhemPower = Power:new{icon=84,description='At the start of turn, play the top #11#!A!#12# card{s} of draw pile.'}
function MayhemPower:onTurnStart()
	local amount = self.amount
	addAction(AnonymousAction:new(function ()
		for _=1,amount do
			addAction(PlayTopCardAction:new{randomTarget=true})
		end
	end))
end

Panache = ColorlessCard:new{
	name='Panache',description='Every time you play 5 cards in a single turn, {Damage} !M! to all enemies.',baseCost=0,type='power',rarity='rare',
	playerTarget=true,baseMagic=10,upgrade={baseMagic=14},
}
function Panache:use()
	return { ApplyPowerAction:new(player,PanachePower:new(player,self.magic)) }
end

PanachePower = Power:new{icon=76,damage=0,description='If you play #11#!A!#12# more card{s} this turn, {Damage} #11#!damage!#12# to all enemies.'}
function PanachePower:new(owner,damage)
	local o = Power.new(self,owner)
	o.amount = 5
	o.damage = damage
	return o
end

function PanachePower:stackPower(power)
	self.damage = self.damage + power.damage
end

function PanachePower:onTurnStart()
	self.amount = 5
end

function PanachePower:onUseCard()
	self.amount = self.amount - 1
	if self.amount == 0 then
		self.amount = 5
		addAction(DamageAllEnemiesAction:new{source=self.owner,value=self.damage,type='power'})
	end
end

SadisticNature = ColorlessCard:new{
	name='Sadistic Nature',description='Whenever you apply a debuff to an enemy, {Damage} !M!.',baseCost=0,type='power',rarity='rare',
	playerTarget=true,baseMagic=5,upgrade={baseMagic=7},
}
function SadisticNature:use()
	return { ApplyPowerAction:new(player,SadisticNaturePower:new(player,self.magic)) }
end

SadisticNaturePower = Power:new{icon=67,description='Whenever you apply a debuff to an enemy, {Damage} #11#!A!#12#.'}
function SadisticNaturePower:onAppliedPower(power)
	if power.debuff and power.owner ~= player then
		addAction(DamageAction:new{source=self.owner,target=power.owner,value=self.amount,type='power'})
	end
end

SecretTechnique = ColorlessCard:new{
	name='Secret Technique',description='Put a {Skill} from draw pile into hand. NL Exhaust.',baseCost=0,type='skill',rarity='rare',
	playerTarget=true,exhaust=true,upgrade={description='Put a {Skill} from draw pile into hand.',exhaust=false},
}
function SecretTechnique:baseCanUse(free)
	return ColorlessCard.baseCanUse(self,free) and table.anyMatch(drawPile,function (card) return card.type == 'skill' end)
end

function SecretTechnique:use()
	return { SecretAction:new{type='skill'} }
end

SecretWeapon = ColorlessCard:new{
	name='Secret Weapon',description='Put a {Attack} from draw pile into hand. NL Exhaust.',baseCost=0,type='skill',rarity='rare',
	playerTarget=true,exhaust=true,upgrade={description='Put a {Attack} from draw pile into hand.',exhaust=false},
}
function SecretWeapon:baseCanUse(free)
	return ColorlessCard.baseCanUse(self,free) and table.anyMatch(drawPile,function (card) return card.type == 'attack' end)
end

function SecretWeapon:use()
	return { SecretAction:new{type='attack'} }
end

SecretAction = Action:new{type='attack',duration=10}
function SecretAction:tick()
	if self.duration == self.startDuration then
		local cards = shallowcopy(drawPile)
		table.retainIf(cards,function (card) return card.type == self.type end)
		local cardItems = {}
		for i, card in ipairs(cards) do
			cardItems[i] = CardItem:new{card=card,x=0,y=136,tx=240,ty=136,isNotInHand=true}
		end
		if #cardItems == 0 then
			return
		elseif #cardItems == 1 then
			local cardItem = cardItems[1]
			table.remove(drawPile,table.indexOf(drawPile,cardItem.card))
			insertHand(cardItem)
		else
			effectRandom:shuffle(cardItems)
			openWindowAbove(CardGridSelectWindow:new{cardItems=cardItems,title='Choose a Card to Put into Hand',max=1},
				function (cards)
					for _, cardItem in ipairs(cards) do
						table.remove(drawPile,table.indexOf(drawPile,cardItem.card))
						insertHand(cardItem)
					end
				end)
		end
	end
	Action.tick(self)
end

TheBomb = ColorlessCard:new{
	name='The Bomb',description='At the end of 3 turns, {Damage} !M! to all enemies.',baseCost=2,type='skill',rarity='rare',
	playerTarget=true,baseMagic=40,upgrade={baseMagic=50},
}
function TheBomb:use()
	return { ApplyPowerAction:new(player,TheBombPower:new(player,self.magic)) }
end

TheBombPower = Power:new{icon=10,damage=0,turnBased=true,description='At the end of #11#!A!#12# turn{s}, {Damage} #11#!damage!#12# to all enemies.'}
function TheBombPower:new(owner,damage)
	local o = Power.new(self,owner)
	o.amount = 3
	o.damage = damage
	-- making different bomb not to stack
	return Power.new(o,nil)
end

function TheBombPower:onTurnEnd()
	self.amount = self.amount - 1
	if self.amount == 0 then
		addAction(RemovePowerAction:new(self))
		addAction(DamageAllEnemiesAction:new{source=self.owner,value=self.damage,type='power'})
	end
end

Transmutation = ColorlessCard:new{
	name='Transmutation',description='Add X random colorless cards to hand. They cost 0 this turn. NL Exhaust.',
	baseCost=-1,type='skill',rarity='rare',playerTarget=true,exhaust=true,
	upgrade={description='Add X random upgraded col- orless cards to hand. They cost 0 this turn. Exhaust.'},
}
function Transmutation:use(_,energyOnUse,free)
	local upgraded = self.upgraded
	return {
		XCardAction:new(function (amount)
			local result = {}
			for i = 1, amount do
				local card = getColorlessCardType(miscRand,nil,nil,true):new()
				if card:getCost() > 0 then
					card.costForOneTurnPlay = 0
				end
				if upgraded then
					card:upgrade()
					card:resetPowers()
				end
				result[i] = MakeTempCardToHandAction:new(card,1,{duration=1})
			end
			return result
		end,energyOnUse,free)
	}
end

Violence = ColorlessCard:new{
	name='Violence',description='Put !M! random {Attack} from draw pile into hand. NL Exhaust.',baseCost=0,type='skill',rarity='rare',
	playerTarget=true,baseMagic=3,upgrade={baseMagic=4},exhaust=true,
}
function Violence:use()
	local cards = shallowcopy(drawPile)
	table.retainIf(cards,function (card) return card.type == 'attack' end)
	local cardItems = {}
	for i, card in ipairs(cards) do
		cardItems[i] = CardItem:new{card=card,x=0,y=136,tx=240,ty=136,isNotInHand=true}
	end
	miscRand:shuffle(cardItems)

	local result = {}
	for i=1,math.min(#cardItems,self.magic) do
		local cardItem = cardItems[i]
		result[i] = AnonymousAction:new(function ()
			table.remove(drawPile,table.indexOf(drawPile,cardItem.card))
			insertHand(cardItem)
		end)
	end
	result[#result+1] = WaitAction:new(10)
	return result
end

Shiv = ColorlessCard:new{
	name='Shiv',description='{Damage} !D!. NL Exhaust.',baseCost=0,type='attack',rarity='special',
	enemyTarget=true,baseDamage=4,upgrade={baseDamage=6},exhaust=true,
}
function Shiv:use(target)
	return { DamageAction:new{source=player,target=target,value=self.damage} }
end

Miracle = ColorlessCard:new{
	name='Miracle',description='Retain. NL Gain {Energy}. NL Exhaust.',baseCost=0,type='skill',rarity='special',
	playerTarget=true,baseMagic=1,upgrade={baseMagic=2,description='Retain. NL Gain {Energy}{Energy}. NL Exhaust.'},exhaust=true,
	retain=true,
}
function Miracle:use()
	return { GainEnergyAction:new(self.magic) }
end

Insight = ColorlessCard:new{
	name='Insight',description='Retain. NL Draw !M! cards. NL Exhaust.',baseCost=0,type='skill',rarity='special',
	playerTarget=true,baseMagic=2,upgrade={baseMagic=3},exhaust=true,retain=true,
}
function Insight:use()
	return { DrawCardAction:new(self.magic) }
end

colorlessCards = {
	-- status
	Wound,Dazed,Burn,Slimed,Void,
	-- uncommon
	BandageUp,Blind,Finesse,DarkShackles,DeepBreath,Discovery,DramaticEntrance,Enlightenment,FlashOfSteel,
	ForeThought,GoodInstincts,Impatience,JackOfAllTrades,Madness,MindBlast,Panacea,PanicButton,Purity,
	SwiftStrike,Trip,
	-- rare
	MasterOfStrategy,HandOfGreed,ThinkingAhead,Apotheosis,Chrysalis,Metamorphosis,Magnetism,Mayhem,Panache,
	SadisticNature,SecretTechnique,SecretWeapon,TheBomb,Transmutation,Violence,
	-- special
	JAX,Apparition,RitualDagger,Bite,Shiv,
}

CurseCard = Card:new{color={15,0},costIcon=46,typeIconColor=13,colorName='curse',type='curse',rarity='common',baseCost=-2,baseCanUse=false,canUpgrade=false,playerTarget=true}

AscendersBane = CurseCard:new{
	name='Ascender\'s Bane',description='Unplayable. NL Ethereal. NL Cannot be removed from deck.',
	rarity='special',ethereal=true,canRemove=false
}
Injury = CurseCard:new{ name='Injury',description='Unplayable.' }
Clumsy = CurseCard:new{ name='Clumsy',description='Unplayable. NL Ethereal.',ethereal=true }
Writhe = CurseCard:new{ name='Writhe',description='Unplayable. NL Innate.',innate=true }
Regret = CurseCard:new{ name='Regret',description='Unplayable. NL At the end of turn, lose HP equal to the number of cards in hand.',autoPlayOnEndTurn=true }
function Regret:autoPlay()
	return { DamageAction:new{source=player,target=player,value=#hand+1,type='hpLoss'} }
end

Decay = CurseCard:new{ name='Decay',description='Unplayable. NL At the end of turn, {Damage} 2 to you.',autoPlayOnEndTurn=true }
function Decay:autoPlay()
	return { DamageAction:new{source=player,target=player,value=2,type='power'} }
end

Doubt = CurseCard:new{ name='Doubt',description='Unplayable. NL At the end of your turn, gain 1 {Weak}.',autoPlayOnEndTurn=true }
function Doubt:autoPlay()
	return { ApplyPowerAction:new(player,WeakPower:new(player,1,true)) }
end

Shame = CurseCard:new{ name='Shame',description='Unplayable. NL At the end of your turn, gain 1 {Frail}.',autoPlayOnEndTurn=true }
function Shame:autoPlay()
	return { ApplyPowerAction:new(player,FrailPower:new(player,1,true)) }
end

Parasite = CurseCard:new{ name='Parasite',description='Unplayable. NL If transformed or removed from deck, lose 3 Max HP.' }
function Parasite:onRemoveFromDeck()
	player:decreaseMaxHp(3)
end

Pain = CurseCard:new{ name='Pain',description='Unplayable. NL While in hand, NL lose 1 HP whenever you play another card.' }
function Pain:onUseCard()
	if table.anyMatch(hand,function (cardItem) return cardItem.card == self end) then
		addAction(DamageAction:new{source=player,target=player,value=1,type='hpLoss'})
	end
end

CurseOfTheBell = CurseCard:new{ name='Curse of the Bell',rarity='special',canRemove=false,description='Unplayable. NL Cannot be removed from your deck.' }

Necronomicurse = CurseCard:new{ name='Necronomicurse',rarity='special',canRemove=false,description='Unplayable. NL There is no escape from this Curse.' }
function Necronomicurse:onExhaust(card)
	if card == self then
		local card = Necronomicurse:new()
		addAction(MakeTempCardToHandAction:new(card,1,{cardItem=CardItem:new{card=card,x=getRelicX(table.indexOf(relics,getRelic(Necronomicon)) or 1),y=13}}))
	end
end

Normality = CurseCard:new{ name='Normality',cardUsed=0,priority=20,description='Unplayable. NL  While in hand, you cannot play more than 3 cards this turn.' }
function Normality:onTurnStart()
	self.cardUsed = 0
end

function Normality:onUseCard()
	self.cardUsed = self.cardUsed + 1
end

function Normality:canUseCard()
	if self.cardUsed >= 3 and table.anyMatch(hand,function (cardItem) return cardItem.card == self end) then
		return false
	end
end

curseCards = {
	AscendersBane,Injury,Clumsy,Writhe,Regret,Decay,Doubt,Pain,Shame,Parasite,CurseOfTheBell,Necronomicurse,Normality,
}
