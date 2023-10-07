---@diagnostic disable: lowercase-global

local greenCards

SilentEventListener = { numAttackPlayed=0 }
function SilentEventListener:onTurnStart()
	self.numAttackPlayed = 0
end

function SilentEventListener:onUseCard(card)
	if card.type == 'attack' then
		self.numAttackPlayed = self.numAttackPlayed + 1
	end
end

table.insert(playerEventListeners,SilentEventListener)

Silent = Player:new{ maxHp=70,width=6,height=4,tileBank=2,name='Silent',energyYOffset=1 }
function Silent:drawImage()
	if self.flipped then
		map(7,9,5,4,self.x+8,self.y,0,1,flipRemap(7,5))
		pix(self.x+33,self.y+12,11)
		pix(self.x+32,self.y+13,11)
	else
		map(7,9,5,4,self.x,self.y,0)
		pix(self.x+14,self.y+12,11)
		pix(self.x+15,self.y+13,11)
	end
end

function Silent:drawCorpse()
	map(7,13,7,2,self.x-4,self.y+20,0)
end

function Silent:getStartDeck()
	local deck = {}
	table.insert(deck,StrikeGreen:new())
	table.insert(deck,StrikeGreen:new())
	table.insert(deck,StrikeGreen:new())
	table.insert(deck,StrikeGreen:new())
	table.insert(deck,StrikeGreen:new())
	table.insert(deck,DefendGreen:new())
	table.insert(deck,DefendGreen:new())
	table.insert(deck,DefendGreen:new())
	table.insert(deck,DefendGreen:new())
	table.insert(deck,DefendGreen:new())
	table.insert(deck,Survivor:new())
	table.insert(deck,Neutralize:new())
	return deck
end

function Silent:getCards()
	return greenCards
end

function Silent:getStartRelics()
	return { RingOfTheSnake:new() }
end

function Silent:getAscensionMaxHPLoss()
	return 4
end

function Silent:getMatchAndKeepCardType()
	return Neutralize
end

function Silent:getRelics()
	return {
		RingOfTheSnake,
		SneckoSkull,
		NinjaScroll,PaperKrane,
		TheSpecimen,Tingsha,ToughBandages,
		RingOfTheSerpent,WristBlade,HoveringKite,
		TwistedFunnel,
	}
end

function Silent:getPotions()
	return { PoisonPotion,CunningPotion,GhostInAJar }
end

function Silent:getPronouns()
	return {vampires='sister'}
end

function Silent:getSpireHeartText()
	return 'NL You prepare your daggers...'
end

function Silent:getEnding()
	return SilentEnding:new()
end

-- cards

GreenCard = Card:new{color={7,15},typeIconColor=5,colorName='green'}

StrikeGreen = GreenCard:new{ name='Strike',description='{Damage} !D!.',rarity='basic',baseCost=1,baseDamage=6,enemyTarget=true,upgrade={baseDamage=9},tags={'strike','basicStrike'} }
function StrikeGreen:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

DefendGreen = GreenCard:new{ name='Defend',description='Gain !B! {Block}.',rarity='basic',type='skill',baseCost=1,baseBlock=5,playerTarget=true,upgrade={baseBlock=8},tags={'basicDefend'} }
function DefendGreen:use()
	return { GainBlockAction:new{target=player,value=self.block} }
end

Neutralize = GreenCard:new{
	name='Neutralize',description='{Damage} !D!. NL Apply !M! {Weak}.',rarity='basic',baseCost=0,baseDamage=3,baseMagic=1,
	enemyTarget=true,upgrade={baseDamage=4,baseMagic=2},
}
function Neutralize:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage}, ApplyPowerAction:new(player,WeakPower:new(target,self.magic)) }
end

Survivor = GreenCard:new{
	name='Survivor',description='Gain !B! {Block}. NL Discard 1 card.',rarity='basic',type='skill',baseCost=1,baseBlock=8,
	playerTarget=true,upgrade={baseBlock=11},
}
function Survivor:use()
	return { GainBlockAction:new{target=player,value=self.block}, SelectDiscardHandAction:new(1) }
end

Acrobatics = GreenCard:new{
	name='Acrobatics',description='Draw !M! cards. NL Discard 1 card.',rarity='common',type='skill',baseCost=1,baseMagic=3,
	playerTarget=true,upgrade={baseMagic=4},
}
function Acrobatics:use()
	return { DrawCardAction:new(self.magic), SelectDiscardHandAction:new(1) }
end

Backflip = GreenCard:new{
	name='Backflip',description='Gain !B! {Block}. NL Draw 2 cards.',rarity='common',type='skill',baseCost=1,baseBlock=5,
	playerTarget=true,upgrade={baseBlock=8},
}
function Backflip:use()
	return { GainBlockAction:new{target=player,value=self.block}, DrawCardAction:new(2) }
end

Bane = GreenCard:new{
	name='Bane',description='{Damage} !D!. NL If the enemy has {Poison}, {Damage} !D! again.',
	rarity='common',baseCost=1,baseDamage=7,enemyTarget=true,upgrade={baseDamage=10},
}
function Bane:applyPowers(target)
	self.displayAttackCount = target and target:getPower(PoisonPower) and 2 or 1
	GreenCard.applyPowers(self,target)
end

function Bane:resetPowers()
	self.displayAttackCount = 1
	GreenCard.resetPowers(self)
end

function Bane:use(target)
	local actions = { DamageAction:new{target=target,source=player,value=self.damage} }
	if target:getPower(PoisonPower) then
		table.insert(actions,DamageAction:new{target=target,source=player,value=self.damage})
	end
	return actions
end

PoisonPower = Power:new{
	icon=icons.Poison,debuff=true,healthBarColor=6,
	description='At the start of turn, lose #11#!A!#12# HP, then reduce {Poison} by #11#1#12#.'
}
function PoisonPower:onTurnStart()
	addAction(DamageAction:new{target=self.owner,source=player,value=self.amount,color=6,type='hpLoss'})
	addAction(ReducePowerAction:new(self,1))
end

BladeDance = GreenCard:new{
	name='Blade Dance',description='Add !M! Shivs into hand.',rarity='common',type='skill',baseCost=1,baseMagic=3,
	playerTarget=true,upgrade={baseMagic=4},
}
function BladeDance:use()
	return { MakeTempCardToHandAction:new(Shiv:new(),self.magic) }
end

CloakAndDagger = GreenCard:new{
	name='Cloak and Dagger',description='Gain !B! {Block}. NL Add !M! Shiv into hand.',rarity='common',type='skill',baseCost=1,baseBlock=6,
	playerTarget=true,baseMagic=1,upgrade={baseMagic=2,description='Gain !B! {Block}. NL Add !M! Shivs into hand.'},
}
function CloakAndDagger:use()
	return { GainBlockAction:new{target=player,value=self.block}, MakeTempCardToHandAction:new(Shiv:new(),self.magic) }
end

DaggerSpray = GreenCard:new{
	name='Dagger Spray',description='{Damage} !D! to all enemies twice.',rarity='common',baseCost=1,baseDamage=4,
	enemyTarget=true,toAllEnemies=true,upgrade={baseDamage=6},displayAttackCount=2,
}
function DaggerSpray:use()
	return { DamageAllEnemiesAction:new{source=player,value=self.multiDamage}, DamageAllEnemiesAction:new{source=player,value=self.multiDamage} }
end

DaggerThrow = GreenCard:new{
	name='Dagger Throw',description='{Damage} !D!. NL Draw 1 card. NL Discard 1 card.',rarity='common',baseCost=1,baseDamage=9,
	playerTarget=true,enemyTarget=true,upgrade={baseDamage=12},
}
function DaggerThrow:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage}, DrawCardAction:new(1), SelectDiscardHandAction:new(1) }
end

DeadlyPoison = GreenCard:new{
	name='Deadly Poison',description='Apply !M! {Poison}.',rarity='common',type='skill',baseCost=1,baseMagic=5,
	enemyTarget=true,upgrade={baseMagic=7},
}
function DeadlyPoison:use(target)
	return { ApplyPowerAction:new(player,PoisonPower:new(target,self.magic)) }
end

Deflect = GreenCard:new{
	name='Deflect',description='Gain !B! {Block}.',rarity='common',type='skill',baseCost=0,baseBlock=4,
	playerTarget=true,upgrade={baseBlock=7},
}
function Deflect:use()
	return { GainBlockAction:new{target=player,value=self.block} }
end

DodgeAndRoll = GreenCard:new{
	name='Dodge and Roll',description='Gain !B! {Block}. NL Next turn, gain !B! {Block}.',rarity='common',type='skill',baseCost=1,baseBlock=4,
	playerTarget=true,upgrade={baseBlock=6},
}
function DodgeAndRoll:use()
	return { GainBlockAction:new{target=player,value=self.block}, ApplyPowerAction:new(player,GainBlockNextTurnPower:new(player,self.block)) }
end

FlyingKnee = GreenCard:new{
	name='Flying Knee',description='{Damage} !D!. NL Next turn, gain {Energy}.',rarity='common',baseCost=1,baseDamage=8,
	playerTarget=true,enemyTarget=true,upgrade={baseDamage=11},
}
function FlyingKnee:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage}, ApplyPowerAction:new(player,EnergizedPower:new(player,1)) }
end

EnergizedPower = Power:new{icon=211,description='Gain #11#!A!#12# additional {Energy} next turn.'}
function EnergizedPower:onTurnStart()
	addAction(GainEnergyAction:new(self.amount))
	addAction(RemovePowerAction:new(self))
end

Outmaneuver = GreenCard:new{
	name='Outmaneuver',description='Next turn, gain {Energy}{Energy}.',rarity='common',type='skill',baseCost=1,baseMagic=2,
	playerTarget=true,upgrade={baseMagic=3,description='Next turn, gain {Energy}{Energy}{Energy}.'},
}
function Outmaneuver:use()
	return { ApplyPowerAction:new(player,EnergizedPower:new(player,self.magic)) }
end

PiercingWail = GreenCard:new{
	name='Piercing Wail',description='All enemies lose !M! {Strength} this turn. NL Exhaust.',rarity='common',type='skill',baseCost=1,baseMagic=6,
	enemyTarget=true,toAllEnemies=true,upgrade={baseMagic=8},exhaust=true,
}
function PiercingWail:use()
	local result = {}
	for _, enemy in ipairs(enemies) do
		local action = ApplyPowerAction:new(player,StrengthPower:new(enemy,-self.magic))
		table.insert(result,action)
		table.insert(result,AnonymousAction:new(function ()
			if action.succeeded then
				addAction(1,ApplyPowerAction:new(player,ShackledPower:new(enemy,self.magic)))
			end
		end))
	end
	return result
end

PoisonedStab = GreenCard:new{
	name='Poisoned Stab',description='{Damage} !D!. NL Apply !M! {Poison}.',rarity='common',baseCost=1,baseDamage=6,baseMagic=3,
	enemyTarget=true,upgrade={baseDamage=8,baseMagic=4},
}
function PoisonedStab:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage}, ApplyPowerAction:new(player,PoisonPower:new(target,self.magic)) }
end

Prepared = GreenCard:new{
	name='Prepared',description='Draw !M! cards. NL Discard !M! card.',rarity='common',type='skill',baseCost=0,baseMagic=1,
	playerTarget=true,upgrade={baseMagic=2},
}
function Prepared:use()
	return { DrawCardAction:new(self.magic), SelectDiscardHandAction:new(self.magic) }
end

QuickSlash = GreenCard:new{
	name='Quick Slash',description='{Damage} !D!. NL Draw 1 card.',rarity='common',baseCost=1,baseDamage=8,
	playerTarget=true,enemyTarget=true,upgrade={baseDamage=12},
}
function QuickSlash:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage}, DrawCardAction:new(1) }
end

Slice = GreenCard:new{
	name='Slice',description='{Damage} !D!.',rarity='common',baseCost=0,baseDamage=6,
	enemyTarget=true,upgrade={baseDamage=9},
}
function Slice:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

SneakyStrike = GreenCard:new{
	name='Sneaky Strike',description='{Damage} !D!. NL If you have discarded a card this turn, gain {Energy}{Energy}.',rarity='common',
	baseCost=2,baseDamage=12,playerTarget=true,enemyTarget=true,upgrade={baseDamage=16},discarded=false,tags={'strike'},
}
function SneakyStrike:onTurnStart()
	self.discarded = false
end

function SneakyStrike:onDiscardFromHand()
	self.discarded = true
end

function SneakyStrike:use(target)
	local actions = { DamageAction:new{target=target,source=player,value=self.damage} }
	if self.discarded then
		table.insert(actions,GainEnergyAction:new(2))
	end
	return actions
end

function SneakyStrike:checkGlow()
	if self.discarded then
		return 4
	end
end

SuckerPunch = GreenCard:new{
	name='Sucker Punch',description='{Damage} !D!. NL Apply !M! {Weak}.',rarity='common',baseCost=1,baseDamage=7,baseMagic=1,
	enemyTarget=true,upgrade={baseDamage=9,baseMagic=2},
}
function SuckerPunch:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage}, ApplyPowerAction:new(player,WeakPower:new(target,self.magic)) }
end

Accuracy = GreenCard:new{
	name='Accuracy',description='Shivs +!M! damage.',rarity='uncommon',type='power',baseCost=1,baseMagic=4,
	playerTarget=true,upgrade={baseMagic=6},
}
function Accuracy:use()
	return { ApplyPowerAction:new(player,AccuracyPower:new(player,self.magic)) }
end

AccuracyPower = Power:new{icon=196,description='Shivs +#11#!A!#12# damage.'}
function AccuracyPower:onAttack(damage,_,card)
	if getmetatable(card) == Shiv then
		return damage + self.amount
	end
end

AllOutAttack = GreenCard:new{
	name='All Out Attack',description='{Damage} !D! to all enemies. NL Discard 1 card at random.',rarity='uncommon',baseCost=1,baseDamage=10,
	playerTarget=true,enemyTarget=true,toAllEnemies=true,upgrade={baseDamage=14},
}
function AllOutAttack:use()
	return {
		DamageAllEnemiesAction:new{source=player,value=self.multiDamage},
		AnonymousAction:new(function ()
			if #hand == 0 then
				return
			else
				local cardIndex = miscRand:randInt(#hand)
				local cardItem = hand[cardIndex]
				removeHand(cardIndex)
				addAction(1,DiscardAction:new{cardItem=cardItem,show=true})
			end
		end)
	}
end

BackStab = GreenCard:new{
	name='Backstab',description='Innate. NL {Damage} !D!. NL Exhaust.',rarity='uncommon',baseCost=0,baseDamage=11,
	enemyTarget=true,innate=true,exhaust=true,upgrade={baseDamage=15},
}
function BackStab:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

Blur = GreenCard:new{
	name='Blur',description='Gain !B! {Block}. NL {Block} is not removed at the start of next turn.',rarity='uncommon',type='skill',
	baseCost=1,baseBlock=5,playerTarget=true,upgrade={baseBlock=8},
}
function Blur:use()
	return { GainBlockAction:new{target=player,value=self.block}, ApplyPowerAction:new(player,BlurPower:new(player,1)) }
end

BlurPower = TurnBasedPower:new{icon=212,description='{Block} is not removed at the start of next #11#!A!#12# turn{s}.'}
function BlurPower:onBeforeTurnStartLoseBlock()
	return 0
end

BouncingFlask = GreenCard:new{
	name='Bouncing Flask',description='Apply 3 {Poison} to a random enemy !M! times.',rarity='uncommon',type='skill',baseCost=2,baseMagic=3,
	enemyTarget=true,toAllEnemies=true,upgrade={baseMagic=4},
}
function BouncingFlask:use()
	local result = {}
	for i=1,self.magic do
		result[i] = AnonymousAction:new(function ()
			local target = getRandomInteractableEnemy()
			if target then
				addAction(1,ApplyPowerAction:new(player,PoisonPower:new(target,3)))
			end
		end)
	end
	return result
end

CalculatedGamble = GreenCard:new{
	name='Calculated Gamble',description='Discard your hand, then draw that many cards. NL Exhaust.',rarity='uncommon',type='skill',baseCost=0,
	playerTarget=true,exhaust=true,upgrade={description='Discard your hand, then draw that many cards.',exhaust=false},
}
function CalculatedGamble:use()
	return {
		AnonymousAction:new(function ()
			local amount = #hand
			addAction(1,SelectDiscardHandAction:new(HAND_LIMIT))
			addAction(2,DrawCardAction:new(amount))
		end)
	}
end

Caltrops = GreenCard:new{
	name='Caltrops',description='Whenever you are attacked, {Damage} !M! back.',rarity='uncommon',type='power',
	baseCost=1,baseMagic=3,playerTarget=true,upgrade={baseMagic=5},
}
function Caltrops:use()
	return { ApplyPowerAction:new(player,ThornsPower:new(player,self.magic)) }
end

Catalyst = GreenCard:new{
	name='Catalyst',description='Double the enemy\'s {Poison}. NL Exhaust.',rarity='uncommon',type='skill',baseCost=1,baseMagic=1,
	enemyTarget=true,upgrade={description='Triple the enemy\'s {Poison}. NL Exhaust.',baseMagic=2},exhaust=true,
}
function Catalyst:use(target)
	return {
		AnonymousAction:new(function ()
			local poison = target:getPower(PoisonPower)
			if poison then
				addAction(1,ApplyPowerAction:new(player,PoisonPower:new(target,poison.amount*self.magic)))
			end
		end)
	}
end

Choke = GreenCard:new{
	name='Choke',description='{Damage} !D!. NL Whenever you play a card this turn, the enemy loses !M! HP.',rarity='uncommon',
	baseCost=2,baseDamage=12,baseMagic=3,enemyTarget=true,upgrade={baseMagic=5},
}
function Choke:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage}, ApplyPowerAction:new(player,ChokePower:new(target,self.magic)) }
end

ChokePower = Power:new{icon=197,debuff=true,description='Whenever you play a card this turn, loses #11#!A!#12# HP.'}
function ChokePower:onUseCard()
	addAction(DamageAction:new{target=self.owner,source=player,value=self.amount,type='hpLoss'})
end

function ChokePower:onTurnStart()
	addAction(RemovePowerAction:new(self))
end

Concentrate = GreenCard:new{
	name='Concentrate',description='Discard !M! card. NL Gain {Energy}{Energy}.',rarity='uncommon',type='skill',baseCost=0,baseMagic=3,
	playerTarget=true,upgrade={baseMagic=2},preferSmallMagic=true,
}
function Concentrate:use()
	return { SelectDiscardHandAction:new(self.magic), GainEnergyAction:new(2) }
end

CrippingCloud = GreenCard:new{
	name='Crippling Cloud',description='Apply !M! {Poison} and 2 {Weak} to all enemies. NL Exhaust.',rarity='uncommon',type='skill',
	baseCost=2,baseMagic=4,enemyTarget=true,toAllEnemies=true,upgrade={baseMagic=7},exhaust=true,
}
function CrippingCloud:use()
	local result = {}
	for _, enemy in ipairs(enemies) do
		table.insert(result,ApplyPowerAction:new(player,PoisonPower:new(enemy,self.magic)))
		table.insert(result,ApplyPowerAction:new(player,WeakPower:new(enemy,2)))
	end
	return result
end

Dash = GreenCard:new{
	name='Dash',description='Gain !B! {Block}. NL {Damage} !D!.',rarity='uncommon',baseCost=2,baseBlock=10,baseDamage=10,
	playerTarget=true,enemyTarget=true,upgrade={baseBlock=13,baseDamage=13},
}
function Dash:use(target)
	return { GainBlockAction:new{target=player,value=self.block}, DamageAction:new{target=target,source=player,value=self.damage} }
end

Distraction = GreenCard:new{
	name='Distraction',description='Add a random {Skill} into hand. NL It costs 0 this turn. NL Exhaust.',rarity='uncommon',type='skill',baseCost=1,
	playerTarget=true,upgrade={baseCost=0},exhaust=true,
}
function Distraction:use()
	local randomType = getPlayerCardType(miscRand,nil,'skill',true)
	local card = randomType:new()
	card.costForOneTurnPlay = 0
	return { MakeTempCardToHandAction:new(card,1) }
end

EndlessAgony = GreenCard:new{
	name='Endless Agony',description='{Damage} !D!. NL Whenever you draw this card, add a copy of it into hand. NL Exhaust.',rarity='uncommon',baseCost=0,
	enemyTarget=true,baseDamage=4,upgrade={baseDamage=6},exhaust=true,
}
function EndlessAgony:onDraw(card)
	if card == self then
		addAction(MakeTempCardToHandAction:new(self:copy(),1))
	end
end

function EndlessAgony:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

EscapePlan = GreenCard:new{
	name='Escape Plan',description='Draw 1 card. NL If you draw a {Skill}, gain !B! Block.',rarity='uncommon',type='skill',baseCost=0,baseBlock=3,
	playerTarget=true,upgrade={baseBlock=5},
}
function EscapePlan:use()
	local drawCardAction = DrawCardAction:new(1)
	return { drawCardAction, AnonymousAction:new(function ()
		local card = drawCardAction.cardDrawn[1]
		if card and card.type == 'skill' then
			addAction(1,GainBlockAction:new{target=player,value=self.block})
		end
	end) }
end

Eviscerate = GreenCard:new{
	name='Eviscerate',description='Costs 1 less {Energy} for each card discarded this turn. NL {Damage} !D!, 3 times.',rarity='uncommon',
	baseCost=3,baseDamage=7,enemyTarget=true,upgrade={baseDamage=9},numDiscarded=0,displayAttackCount=3,
}
function Eviscerate:onTurnStart()
	self.numDiscarded = 0
end

function Eviscerate:onDiscardFromHand()
	self.numDiscarded = self.numDiscarded + 1
end

function Eviscerate:onConfused(card)
	if card == self then
		self.numDiscarded = 0
	end
end

function Eviscerate:modifyCost(cost,card)
	if card == self then
		return math.max(0, cost - self.numDiscarded)
	end
end

function Eviscerate:use(target)
	return {
		DamageAction:new{target=target,source=player,value=self.damage},
		DamageAction:new{target=target,source=player,value=self.damage},
		DamageAction:new{target=target,source=player,value=self.damage},
	}
end

Expertise = GreenCard:new{
	name='Expertise',description='Draw cards until you have !M! in hand.',rarity='uncommon',type='skill',baseCost=1,baseMagic=6,
	playerTarget=true,upgrade={baseMagic=7},
}
function Expertise:use()
	return {
		AnonymousAction:new(function ()
			addAction(1,DrawCardAction:new(self.magic-#hand))
		end)
	}
end

Finisher = GreenCard:new{
	name='Finisher',description='{Damage} !D! for each {Attack} played this turn.',rarity='uncommon',baseCost=1,baseDamage=6,
	enemyTarget=true,upgrade={baseDamage=8},displayAttackCount='?'
}
function Finisher:applyPowers(target)
	self.displayAttackCount = SilentEventListener.numAttackPlayed
	GreenCard.applyPowers(self,target)
end

function Finisher:resetPowers()
	self.displayAttackCount = '?'
	GreenCard.resetPowers(self)
end

function Finisher:use(target)
	local result = {}
	for i=1,SilentEventListener.numAttackPlayed do
		result[i] = DamageAction:new{target=target,source=player,value=self.damage}
	end
	return result
end

Flechettes = GreenCard:new{
	name='Flechettes',description='{Damage} !D! for each {Skill} in hand.',rarity='uncommon',baseCost=1,baseDamage=4,
	enemyTarget=true,upgrade={baseDamage=6},displayAttackCount='?'
}
function Flechettes:applyPowers(target)
	self.displayAttackCount = table.count(hand,function (cardItem) return cardItem.card.type == 'skill' end)
	GreenCard.applyPowers(self,target)
end

function Flechettes:resetPowers()
	self.displayAttackCount = '?'
	GreenCard.resetPowers(self)
end

function Flechettes:use(target)
	return {
		AnonymousAction:new(function ()
			local attackCount = table.count(hand,function (cardItem) return cardItem.card.type == 'skill' end)
			for i=1,attackCount do
				addAction(i,DamageAction:new{target=target,source=player,value=self.damage})
			end
		end)
	}
end

Footwork = GreenCard:new{
	name='Footwork',description='Gain !M! {Dexterity}.',rarity='uncommon',type='power',baseCost=1,baseMagic=2,
	playerTarget=true,upgrade={baseMagic=3},
}
function Footwork:use()
	return { ApplyPowerAction:new(player,DexterityPower:new(player,self.magic)) }
end

HeelHook = GreenCard:new{
	name='Heel Hook',description='{Damage} !D!. NL If the enemy has {Weak}, gain {Energy} and draw 1 card.',rarity='uncommon',baseCost=1,baseDamage=5,
	enemyTarget=true,upgrade={baseDamage=8},
}
function HeelHook:use(target)
	local actions = { DamageAction:new{target=target,source=player,value=self.damage} }
	if target:getPower(WeakPower) then
		table.insert(actions,GainEnergyAction:new(1))
		table.insert(actions,DrawCardAction:new(1))
	end
	return actions
end

function HeelHook:checkGlow()
	if table.anyMatch(enemies,function (enemy) return enemy.canInteract and enemy:getPower(WeakPower) ~= nil end) then
		return 4
	end
end

InfiniteBlades = GreenCard:new{
	name='Infinite Blades',description='At the start of turn, add a Shiv into hand.',rarity='uncommon',type='power',baseCost=1,
	playerTarget=true,upgrade={description='Innate. NL At the start of turn, add a Shiv into hand.',innate=true},
}
function InfiniteBlades:use()
	return { ApplyPowerAction:new(player,InfiniteBladesPower:new(player,1)) }
end

InfiniteBladesPower = Power:new{icon=213,description='At the start of turn, add #11#!A!#12# Shiv{s} into hand.'}
function InfiniteBladesPower:onTurnStart()
	addAction(MakeTempCardToHandAction:new(Shiv:new(),self.amount))
end

LegSweep = GreenCard:new{
	name='Leg Sweep',description='Apply !M! {Weak}. NL Gain !B! {Block}.',rarity='uncommon',type='skill',baseCost=2,baseMagic=2,baseBlock=11,
	playerTarget=true,enemyTarget=true,upgrade={baseMagic=3,baseBlock=14},
}
function LegSweep:use(target)
	return { ApplyPowerAction:new(player,WeakPower:new(target,self.magic)), GainBlockAction:new{target=player,value=self.block} }
end

MasterfulStab = GreenCard:new{
	name='Masterful Stab',description='Costs 1 additional {Energy} for each time you lose HP this combat. NL {Damage} !D!.',rarity='uncommon',
	baseCost=0,baseDamage=12,enemyTarget=true,upgrade={baseDamage=16}
}
function MasterfulStab:onDamaged(value)
	if value > 0 then
		self:modifyBaseCost(1)
	end
end

function MasterfulStab:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

NoxiousFumes = GreenCard:new{
	name='Noxious Fumes',description='At the start of turn, apply !M! {Poison} to all enemies.',rarity='uncommon',type='power',baseCost=1,
	playerTarget=true,baseMagic=2,upgrade={baseMagic=3},
}
function NoxiousFumes:use()
	return { ApplyPowerAction:new(player,NoxiousFumesPower:new(player,self.magic)) }
end

NoxiousFumesPower = Power:new{icon=198,description='At the start of turn, apply #11#!A!#12# {Poison} to all enemies.'}
function NoxiousFumesPower:onTurnStart()
	for _, enemy in ipairs(enemies) do
		addAction(ApplyPowerAction:new(player,PoisonPower:new(enemy,self.amount)))
	end
end

Predator = GreenCard:new{
	name='Predator',description='{Damage} !D!. NL Next turn, draw 2 additional cards.',rarity='uncommon',baseCost=2,baseDamage=15,
	playerTarget=true,enemyTarget=true,upgrade={baseDamage=20},
}
function Predator:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage}, ApplyPowerAction:new(player,DrawCardNextTurnPower:new(player,2)) }
end

Reflex = GreenCard:new{
	name='Reflex',description='Unplayable. NL If this card is discarded from hand, draw !M! cards.',rarity='uncommon',type='skill',baseCost=-2,
	baseMagic=2,playerTarget=true,upgrade={baseMagic=3},baseCanUse=false,
}
function Reflex:onDiscardFromHand(card)
	if card == self then
		addAction(DrawCardAction:new(self.magic))
	end
end

RiddleWithHoles = GreenCard:new{
	name='Riddle with Holes',description='{Damage} !D!, 5 times.',rarity='uncommon',baseCost=2,baseDamage=3,
	enemyTarget=true,upgrade={baseDamage=4},displayAttackCount=5,
}
function RiddleWithHoles:use(target)
	local result = {}
	for i=1,5 do
		result[i] = DamageAction:new{target=target,source=player,value=self.damage}
	end
	return result
end

Setup = GreenCard:new{
	name='Setup',description='Put a card from hand on top of draw pile. NL It costs 0 until played.',rarity='uncommon',type='skill',
	baseCost=1,playerTarget=true,upgrade={baseCost=0},
}
function Setup:use()
	return {
		AnonymousAction:new(function ()
			if #hand == 0 then
				return
			elseif #hand == 1 then
				local card = hand[1].card
				addAction(1,PutCardInDrawPileAction:new{cardItem=hand[1],show=true,duration=10})
				if card:getCost() > 0 then
					card.costForOnePlay = 0
				end
				removeHand(1)
			else
				local title = 'Choose a Card to Put on Top of Draw Pile'
				openWindowAbove(HandSelectWindow:new{cardItems=hand,title=title,max=1},function (cards)
					for i, cardItem in ipairs(cards) do
						local cardIndex = table.indexOf(hand,cardItem)
						addAction(i,PutCardInDrawPileAction:new{cardItem=cardItem,duration=1})
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

Skewer = GreenCard:new{
	name='Skewer',description='{Damage} !D!, X times.',rarity='uncommon',baseCost=-1,baseDamage=7,
	enemyTarget=true,upgrade={baseDamage=10},displayAttackCount='X',
}
function Skewer:use(target,energyOnUse,free)
	return {
		XCardAction:new(function (amount)
			local result = {}
			for i = 1, amount do
				result[i] = DamageAction:new{target=target,source=player,value=self.damage}
			end
			return result
		end,energyOnUse,free)
	}
end

Tactican = GreenCard:new{
	name='Tactician',description='Unplayable. NL If this card is discarded from hand, gain {Energy}.',rarity='uncommon',type='skill',
	baseCost=-2,baseMagic=1,playerTarget=true,baseCanUse=false,
	upgrade={baseMagic=2,description='Unplayable. NL If this card is discarded from hand, gain {Energy}{Energy}.'},
}
function Tactican:onDiscardFromHand(card)
	if card == self then
		addAction(GainEnergyAction:new(self.magic))
	end
end

Terror = GreenCard:new{
	name='Terror',description='Apply !M! {Vulnerable}. NL Exhaust.',rarity='uncommon',type='skill',baseCost=1,baseMagic=99,
	enemyTarget=true,upgrade={baseCost=0},exhaust=true,
}
function Terror:use(target)
	return { ApplyPowerAction:new(player,VulnerablePower:new(target,self.magic)) }
end

WellLaidPlans = GreenCard:new{
	name='Well-Laid Plans',description='At the end of turn, retain up to !M! card.',rarity='uncommon',type='power',baseCost=1,baseMagic=1,
	playerTarget=true,upgrade={baseMagic=2,description='At the end of turn, retain up to !M! cards.'},
}
function WellLaidPlans:use()
	return { ApplyPowerAction:new(player,WellLaidPlansPower:new(player,self.magic)) }
end

WellLaidPlansPower = Power:new{icon=214,priority=150,description='At the end of turn, you may retain #11#!A!#12# card{s}.'}
function WellLaidPlansPower:onTurnEnd()
	if not hasRelic(RunicPryamid) and table.anyMatch(hand,function (cardItem) return not cardItem.card.retain and not cardItem.card.tempRetain end) then
		addAction(AnonymousAction:new(function ()
			local title = self.amount == 1 and 'Choose a Card to Retain' or 'Choose Cards to Retain ({#}/'..self.amount..')'
			openWindowAbove(HandSelectWindow:new{cardItems=hand,title=title,min=0,max=self.amount},function (cards)
				for _, cardItem in ipairs(cards) do
					cardItem.card.tempRetain = true
				end
			end)
		end))
	end
end

AThousandCuts = GreenCard:new{
	name='A Thousand Cuts',description='Whenever you play a card, {Damage} !M! to all enemies.',rarity='rare',type='power',baseCost=2,baseMagic=1,
	playerTarget=true,upgrade={baseMagic=2},
}
function AThousandCuts:use()
	return { ApplyPowerAction:new(player,AThousandCutsPower:new(player,self.magic)) }
end

AThousandCutsPower = Power:new{icon=199,description='Whenever you play a card, {Damage} #11#!A!#12# to all enemies.'}
function AThousandCutsPower:onUseCard()
	addAction(DamageAllEnemiesAction:new{source=self.owner,value=self.amount,type='power'})
end

Adrenaline = GreenCard:new{
	name='Adrenaline',description='Gain {Energy}. NL Draw 2 cards. NL Exhaust.',rarity='rare',type='skill',baseCost=0,baseMagic=1,
	playerTarget=true,upgrade={baseMagic=2,description='Gain {Energy}{Energy}. NL Draw 2 cards. NL Exhaust.'},exhaust=true,
}
function Adrenaline:use()
	return { GainEnergyAction:new(self.magic), DrawCardAction:new(2) }
end

AfterImage = GreenCard:new{
	name='After Image',description='Whenever you play a card, gain !M! {Block}.',rarity='rare',type='power',baseCost=1,baseMagic=1,
	playerTarget=true,upgrade={innate=true,description='Innate. NL Whenever you play a card, gain !M! {Block}.'},
}
function AfterImage:use()
	return { ApplyPowerAction:new(player,AfterImagePower:new(player,self.magic)) }
end

AfterImagePower = Power:new{icon=215,description='Whenever you play a card, gain #11#!A!#12# {Block}.'}
function AfterImagePower:onUseCard()
	addAction(GainBlockAction:new{target=self.owner,value=self.amount})
end

Alchemize = GreenCard:new{
	name='Alchemize',description='Obtain a random potion. NL Exhaust.',rarity='rare',type='skill',baseCost=1,
	playerTarget=true,upgrade={baseCost=0},exhaust=true,canGenerateInCombat=false,
}
function Alchemize:use()
	return { AnonymousAction:new(function ()
		local potion = getRandomPotionType(potionRand,true):new()
		obtainPotion(potion)
	end) }
end

BulletTime = GreenCard:new{
	name='Bullet Time',description='Reduce cost of all cards in hand to 0 this turn. You cannot draw more cards.',rarity='rare',
	type='skill',baseCost=3,playerTarget=true,upgrade={baseCost=2},
}
function BulletTime:use()
	return {
		ApplyPowerAction:new(player,NoDrawPower:new(player)),
		AnonymousAction:new(function ()
			for _, cardItem in ipairs(hand) do
				if cardItem.card:getCost() > 0 then
					cardItem.card.costForOneTurnPlay = 0
				end
			end
			handApplyPowers()
		end)
	}
end

Burst = GreenCard:new{
	name='Burst',description='This turn, your next {Skill} is played twice.',rarity='rare',type='skill',baseCost=1,baseMagic=1,
	playerTarget=true,upgrade={baseMagic=2,description='This turn, your next !M! {Skill} are played twice.'},
}
function Burst:use()
	return { ApplyPowerAction:new(player,BurstPower:new(player,self.magic)) }
end

BurstPower = Power:new{icon=232,description='your next #11#!A!#12# {Skill} {is} played twice this turn.'}
function BurstPower:onUseCard(card,target,useCardAction)
	if card.type == 'skill' and not useCardAction.isDoubleTap then
		local cardItem = useCardAction.cardItem:copy()
		local action = UseCardAction:new{cardItem=cardItem,isDoubleTap=true,tempCard=true,free=true,target=target,energyOnUse=useCardAction.energyOnUse}
		action.useCardPosition = fillCardPosition(cardItem,2)
		table.insert(limbo,cardItem)
		addAction(1,ReducePowerAction:new(self,1))
		addAction(action)
	end
end

function BurstPower:onTurnEnd()
	addAction(RemovePowerAction:new(self))
end

CorpseExplosion = GreenCard:new{
	name='Corpse Explosion',description='Apply !M! {Poison}. NL When the enemy dies, {Damage} equal to its Max HP to all enemies.',rarity='rare',type='skill',
	baseCost=2,baseMagic=6,enemyTarget=true,upgrade={baseMagic=9},
}
function CorpseExplosion:use(target)
	return { ApplyPowerAction:new(player,PoisonPower:new(target,self.magic)), ApplyPowerAction:new(player,CorpseExplosionPower:new(target,1)), }
end

CorpseExplosionPower = Power:new{icon=200,debuff=true,description='On death, deal damage equal to its Max HP #11#!A!#12# time{s} to all enemies.'}
function CorpseExplosionPower:onDeath()
	if self.owner.hp > 0 or self.owner.alive then
		return
	end
	addAction(DamageAllEnemiesAction:new{source=player,value=self.owner.maxHp*self.amount,type='power'})
end

DieDieDie = GreenCard:new{
	name='Die Die Die',description='{Damage} !D! to all enemies. NL Exhaust.',rarity='rare',baseCost=1,baseDamage=13,
	enemyTarget=true,toAllEnemies=true,upgrade={baseDamage=17},exhaust=true,
}
function DieDieDie:use()
	return { DamageAllEnemiesAction:new{source=player,value=self.multiDamage} }
end

Doppelganger = GreenCard:new{
	name='Doppleganger',description='Next turn, draw X cards and gain X {Energy}. NL Exhaust.',rarity='rare',type='skill',baseCost=-1,
	playerTarget=true,upgrade={description='Next turn, draw X+1 cards and gain X+1 {Energy}. NL Exhaust.'},exhaust=true,
}
function Doppelganger:use(_,energyOnUse,free)
	return {
		XCardAction:new(function (amount)
			amount = self.upgraded and (amount + 1) or amount
			if amount > 0 then
				return {
					ApplyPowerAction:new(player,DrawCardNextTurnPower:new(player,amount)),
					ApplyPowerAction:new(player,EnergizedPower:new(player,amount)),
				}
			end
		end,energyOnUse,free)
	}
end

Envenom = GreenCard:new{
	name='Envenom',description='Whenever a {Attack} deals unblocked damage, apply 1 {Poison}.',rarity='rare',type='power',baseCost=2,
	playerTarget=true,upgrade={baseCost=1},
}
function Envenom:use()
	return { ApplyPowerAction:new(player,EnvenomPower:new(player,1)) }
end

EnvenomPower = Power:new{icon=216,description='Whenever a {Attack} deals unblocked damage, apply #11#!A!#12# {Poison}.'}
function EnvenomPower:onDamageDealt(value,target,type)
	if type == 'attack' and value > 0 then
		addAction(ApplyPowerAction:new(player,PoisonPower:new(target,self.amount)))
	end
end

GlassKnife = GreenCard:new{
	name='Glass Knife',description='{Damage} !D! twice. NL This card -2 damage this combat.',rarity='rare',baseCost=1,baseDamage=8,
	enemyTarget=true,displayAttackCount=2,
}
function GlassKnife:use(target)
	return {
		DamageAction:new{target=target,source=player,value=self.damage},
		DamageAction:new{target=target,source=player,value=self.damage},
		AnonymousAction:new(function ()
			self.baseDamage = self.baseDamage - 2
		end),
	}
end

function GlassKnife:upgrade()
	self:upgradeValues({baseDamage=self.baseDamage+4})
end

GrandFinale = GreenCard:new{
	name='Grand Finale',description='Can only be played if draw pile is empty. NL {Damage} !D! to all enemies.',rarity='rare',baseCost=0,
	enemyTarget=true,toAllEnemies=true,baseDamage=50,upgrade={baseDamage=60},
}
function GrandFinale:baseCanUse(free)
	return GreenCard.baseCanUse(self,free) and #drawPile == 0
end

function GrandFinale:use()
	return { DamageAllEnemiesAction:new{source=player,value=self.multiDamage} }
end

function GrandFinale:checkGlow()
	if #drawPile == 0 then
		return 4
	end
end

Malaise = GreenCard:new{
	name='Malaise',description='Enemy loses X {Strength}. NL Apply X {Weak}. NL Exhaust.',rarity='rare',type='skill',baseCost=-1,
	enemyTarget=true,upgrade={description='Enemy loses X+1 {Strength}. NL Apply X+1 {Weak}. NL Exhaust.'},exhaust=true,
}
function Malaise:use(target,energyOnUse,free)
	return {
		XCardAction:new(function (amount)
			amount = self.upgraded and (amount + 1) or amount
			if amount > 0 then
				return {
					ApplyPowerAction:new(player,StrengthPower:new(target,-amount)),
					ApplyPowerAction:new(player,WeakPower:new(target,amount)),
				}
			end
		end,energyOnUse,free)
	}
end

Nightmare = GreenCard:new{
	name='Nightmare',description='Choose a card. NL Next turn, add 3 copies of that card into hand. NL Exhaust.',rarity='rare',type='skill',
	baseCost=3,playerTarget=true,upgrade={baseCost=2},exhaust=true,
}
function Nightmare:use()
	return {
		AnonymousAction:new(function ()
			if #hand == 0 then
				return
			elseif #hand == 1 then
				local card = hand[1].card
				addAction(ApplyPowerAction:new(player,NightmarePower:new(player,card:copy())))
			else
				local title = 'Choose a Card to Copy'
				openWindowAbove(HandSelectWindow:new{cardItems=hand,title=title,max=1},function (cards)
					for _, cardItem in ipairs(cards) do
						local card = cardItem.card
						addAction(ApplyPowerAction:new(player,NightmarePower:new(player,card:copy())))
					end
				end)
			end
		end)
	}
end

NightmarePower = Power:new{icon=217,card=nil,stackable=false}
function NightmarePower:new(owner,card)
	local o = Power.new(self,owner)
	o.amount = 1
	o.card = card
	o.description = 'Add #11#3#12# '..card.name..' into your hand next turn.'
	-- making different nightmares not to stack
	return Power.new(o,nil)
end

function NightmarePower:onTurnStart()
	addAction(RemovePowerAction:new(self))
	addAction(MakeTempCardToHandAction:new(self.card,3))
end

PhantasmalKiller = GreenCard:new{
	name='Phantasmal Killer',description='Next turn, your {Attack} deal double damage.',rarity='rare',type='skill',baseCost=1,
	playerTarget=true,upgrade={baseCost=0}
}
function PhantasmalKiller:use()
	return { ApplyPowerAction:new(player,PhantasmalKillerPower:new(player)) }
end

PhantasmalKillerPower = Power:new{icon=201,description='{Attack} deal double damage for the next #11#!A!#12# turn{s}.'}
function PhantasmalKillerPower:onTurnStart()
	addAction(RemovePowerAction:new(self))
	addAction(ApplyPowerAction:new(self.owner,DoubleDamagePower:new(self.owner,self.amount)))
end

DoubleDamagePower = TurnBasedPower:new{icon=202,priority=150,description='{Attack} deal double damage for #11#!A!#12# turn{s}.'}
function DoubleDamagePower:onAttack(damage)
	return damage * 2
end

StormOfSteel = GreenCard:new{
	name='Storm of Steel',description='Discard your hand. NL Add 1 Shiv into hand for each card discarded.',rarity='rare',type='skill',baseCost=1,
	playerTarget=true,upgrade={description='Discard your hand. NL Add 1 Shiv+ into hand for each card discarded.'},
}
function StormOfSteel:use()
	return {
		AnonymousAction:new(function ()
			local cardCount = #hand
			if cardCount > 0 then
				addAction(1,SelectDiscardHandAction:new(cardCount))
				local card = Shiv:new()
				if self.upgraded then
					card:upgrade()
				end
				addAction(2,MakeTempCardToHandAction:new(card,cardCount))
			end
		end)
	}
end

ToolsOfTheTrade = GreenCard:new{
	name='Tools of the Trade',description='At the start of turn, draw 1 card and discard 1 card.',rarity='rare',type='power',baseCost=1,
	playerTarget=true,upgrade={baseCost=0},
}
function ToolsOfTheTrade:use()
	return { ApplyPowerAction:new(player,ToolsOfTheTradePower:new(player)) }
end

ToolsOfTheTradePower = Power:new{icon=233,description='At the start of turn, draw #11#!A!#12# card and discard #11#!A!#12# card.'}
function ToolsOfTheTradePower:onTurnStartPostDraw()
	addAction(DrawCardAction:new(self.amount))
	addAction(SelectDiscardHandAction:new(self.amount))
end

Unload = GreenCard:new{
	name='Unload',description='{Damage} !D!. NL Discard all non-{Attack} in hand.',rarity='rare',baseCost=1,baseDamage=14,
	enemyTarget=true,upgrade={baseDamage=18},
}
function Unload:use(target)
	return {
		DamageAction:new{target=target,source=player,value=self.damage},
		AnonymousAction:new(function ()
			local targetCards = shallowcopy(hand)
			table.retainIf(targetCards,function (cardItem) return cardItem.card.type ~= 'attack' end)
			for i, cardItem in ipairs(targetCards) do
				local cardIndex = table.indexOf(hand,cardItem)
				removeHand(cardIndex)
				addAction(i,DiscardAction:new{cardItem=cardItem,duration=1})
			end
		end)
	}
end

WraithForm = GreenCard:new{
	name='Wraith Form',description='Gain !M! {35}. NL At the end of turn, lose 1 {Dexterity}.',rarity='rare',type='power',
	baseCost=3,baseMagic=2,playerTarget=true,upgrade={baseMagic=3},
}
function WraithForm:use()
	return { ApplyPowerAction:new(player,IntangiblePower:new(player,self.magic)), ApplyPowerAction:new(player,WraithFormPower:new(player,-1)) }
end

WraithFormPower = Power:new{icon=195,debuff=true,description='At the end of turn, lose #11#!A!#12# {Dexterity}.'}
function WraithFormPower:onTurnEnd()
	addAction(ApplyPowerAction:new(self.owner,DexterityPower:new(self.owner,self.amount)))
end

greenCards = {
	StrikeGreen,DefendGreen,Neutralize,Survivor,Acrobatics,Backflip,Bane,BladeDance,CloakAndDagger,DaggerSpray,DaggerThrow,
	DeadlyPoison,Deflect,DodgeAndRoll,FlyingKnee,Outmaneuver,PiercingWail,PoisonedStab,Prepared,QuickSlash,Slice,SneakyStrike,
	SuckerPunch,Accuracy,AllOutAttack,BackStab,Blur,BouncingFlask,CalculatedGamble,Caltrops,Catalyst,Choke,Concentrate,
	CrippingCloud,Dash,Distraction,EndlessAgony,EscapePlan,Eviscerate,Expertise,Finisher,Flechettes,Footwork,HeelHook,
	InfiniteBlades,LegSweep,MasterfulStab,NoxiousFumes,Predator,Reflex,RiddleWithHoles,Setup,Skewer,Tactican,Terror,
	WellLaidPlans,AThousandCuts,Adrenaline,AfterImage,Alchemize,BulletTime,Burst,CorpseExplosion,DieDieDie,Doppelganger,
	Envenom,GlassKnife,GrandFinale,Malaise,Nightmare,PhantasmalKiller,StormOfSteel,ToolsOfTheTrade,Unload,WraithForm,
}

-- relics

GreenRelic = Relic:new{colorName='green'}

RingOfTheSnake = GreenRelic:new{name='Ring of the Snake',icon=243,tier='basic',description='At the start of each combat, draw #11#2#12# additional cards.'}
function RingOfTheSnake:onTurnStartPostDraw(turn)
	if turn == 1 then
		addAction(DrawCardAction:new(2))
	end
end

SneckoSkull = GreenRelic:new{name='Snecko Skull',icon=227,tier='common',description='Whenever you apply {Poison}, apply an additional #11#1#12# {Poison}.'}
function SneckoSkull:onBeforeApplyPower(power)
	if getmetatable(power) == PoisonPower then
		power.amount = power.amount + 1
	end
end

NinjaScroll = GreenRelic:new{name='Ninja Scroll',icon=228,tier='uncommon',description='At the start of each combat, add #11#3#12# Shivs into hand.'}
function NinjaScroll:onCombatStart()
	addAction(MakeTempCardToHandAction:new(Shiv:new(),3))
end

PaperKrane = GreenRelic:new{name='Paper Krane',icon=244,tier='uncommon',description='Enemies with {Weak} deal #11#40%#12# less damage rather than #11#25%#12#.'}
function PaperKrane:modifyWeakFactor(factor)
	return factor - 0.15
end

TheSpecimen = GreenRelic:new{name='The Specimen',icon=229,tier='rare',description='Whenever an enemy dies, transfer any {Poison} it has to a random enemy.'}
function TheSpecimen:onMonsterDeath(monster)
	local poison = monster:getPower(PoisonPower)
	if poison then
		local amount = poison.amount
		addAction(AnonymousAction:new(function ()
			local target = getRandomInteractableEnemy()
			if target then
				addAction(1,ApplyPowerAction:new(player,PoisonPower:new(target,amount)))
			end
		end))
	end
end

Tingsha = GreenRelic:new{name='Tingsha',icon=245,tier='rare',description='Whenever you discard a card during your turn, {Damage} #11#3#12# to a random enemy.'}
function Tingsha:onDiscardFromHand()
	addAction(AnonymousAction:new(function ()
		local target = getRandomInteractableEnemy()
		if target then
			addAction(1,DamageAction:new{target=target,source=player,value=3,type='power'})
		end
	end))
end

ToughBandages = GreenRelic:new{name='Tough Bandages',icon=230,tier='rare',description='Whenever you discard a card during your turn, gain #11#3#12# {Block}.'}
function ToughBandages:onDiscardFromHand()
	addAction(GainBlockAction:new{target=player,value=3})
end

RingOfTheSerpent = GreenRelic:new{name='Ring of the Serpent',icon=246,tier='boss',replaces=RingOfTheSnake,description='Replaces #5#Ring of the Snake#12#. At the start of your turn, draw #11#1#12# additional card.'}
function RingOfTheSerpent:onTurnStartPostDraw()
	addAction(DrawCardAction:new(1))
end

WristBlade = GreenRelic:new{name='Wrist Blade',icon=248,tier='boss',description='{Attack} that costs #11#0#12# deal #11#4#12# additional damage.'}
function WristBlade:onAttack(damage,_,card)
	if card.type == 'attack' and card:getCost() == 0 then
		return damage + 4
	end
end

HoveringKite = GreenRelic:new{name='Hovering Kite',icon=247,tier='boss',discarded=false,description='The first time you discard a card each turn, gain {Energy}.'}
function HoveringKite:onDiscardFromHand()
	if not self.discarded then
		self.discarded = true
		addAction(GainEnergyAction:new(1))
	end
end

function HoveringKite:onTurnStart()
	self.discarded = false
end

TwistedFunnel = GreenRelic:new{name='Twisted Funnel',icon=231,tier='shop',description='At the start of each combat, apply #11#4#12# {Poison} to ALL enemies.'}
function TwistedFunnel:onTurnStart(turn)
	if turn ~= 1 then
		return
	end
	for _, enemy in ipairs(enemies) do
		addAction(ApplyPowerAction:new(player,PoisonPower:new(enemy,4)))
	end
end

-- potions
PoisonPotion = Potion:new{
	name='Poison Potion',icon=Icon:new{image=97,colorMap={6,7}},baseMagic=6,rarity='common',
	description='Apply #11#!M!#12# {Poison}.',enemyTarget=true,useTitle='Throw'
}
function PoisonPotion:use(target)
	return { ApplyPowerAction:new(player,PoisonPower:new(target,self.magic)) }
end

GhostInAJar = Potion:new{
	name='Ghost in a Jar',icon=249,rarity='rare',description='Gain #11#!M!#12# {35}.',baseMagic=1,
}
function GhostInAJar:use()
	return { ApplyPowerAction:new(player,IntangiblePower:new(player,self.magic)) }
end

CunningPotion = Potion:new{
	name='Cunning Potion',icon=Icon:new{image=105,colorMap={14,13}},rarity='uncommon',description='Add #11#!M!#12# Shiv+ to hand.',baseMagic=3,
}
function CunningPotion:use()
	local card = Shiv:new()
	card:upgrade()
	card:resetPowers()
	return { MakeTempCardToHandAction:new(card,self.magic) }
end
