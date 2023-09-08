---@diagnostic disable: lowercase-global

local greenCards

TheSilent = Player:new{ maxHp=70,width=6,height=4,tileBank=2,name='The Silent',energyYOffset=1 }
function TheSilent:drawImage()
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

function TheSilent:drawCorpse()
	map(0,13,7,3,self.x-4,self.y+20,0)
end

function TheSilent:getStartDeck()
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

function TheSilent:getCards()
	return greenCards
end

function TheSilent:getStartRelics()
	return { RingOfTheSnake:new() }
end

function TheSilent:getAscensionMaxHPLoss()
	return 4
end

function TheSilent:getMatchAndKeepCardType()
	return Neutralize
end

function TheSilent:getRelics()
	return { RingOfTheSnake }
end

function TheSilent:getPotions()
	return { }
end

function TheSilent:getSpireHeartText()
	return 'NL You prepare your daggers...'
end

-- cards

GreenCard = Card:new{color={7,15},costIcon=201,typeIconColor=5,colorName='green'}

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
end

function Bane:use(target)
	local actions = { DamageAction:new{target=target,source=player,value=self.damage} }
	if target:getPower(PoisonPower) then
		table.insert(actions,DamageAction:new{target=target,source=player,value=self.damage})
	end
	return actions
end

PoisonPower = Power:new{icon=icons.Poison,debuff=true}
function PoisonPower:onTurnStart()
	addAction(1,DamageAction:new{target=self.owner,source=player,value=self.amount})
	addAction(2,ReducePowerAction:new(self,1))
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

EnergizedPower = Power:new{icon=211}
function EnergizedPower:onTurnStart()
	addAction(1,GainEnergyAction:new(self.amount))
	addAction(2,RemovePowerAction:new(self))
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
		table.insert(result,ApplyPowerAction:new(player,StrengthPower:new(enemy,-self.magic)))
		table.insert(result,ApplyPowerAction:new(player,ShackledPower:new(enemy,self.magic)))
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
	baseCost=2,baseDamage=12,playerTarget=true,enemyTarget=true,upgrade={baseDamage=16},discarded=false,
}
function SneakyStrike:onTurnStart()
	self.discarded = false
end

function SneakyStrike:onDiscard()
	self.discarded = true
end

function SneakyStrike:use(target)
	local actions = { DamageAction:new{target=target,source=player,value=self.damage} }
	if self.discarded then
		table.insert(actions,GainEnergyAction:new(2))
	end
	return actions
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

AccuracyPower = Power:new{icon=196}
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
				addAction(1,DiscardAction:new{cardItem=cardItem,duration=1})
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

BlurPower = TurnBasedPower:new{icon=212}
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
	name='Caltrops',description='Whenever you are attacked, {Damage} !M! back.',rarity='uncommon',type='skill',
	baseCost=1,baseMagic=3,playerTarget=true,upgrade={baseMagic=5},
}
function Caltrops:use()
	return { ApplyPowerAction:new(player,ThornsPower:new(player,self.magic)) }
end

Catalyst = GreenCard:new{
	name='Catalyst',description='Double the enemy\'s {Poison}.',rarity='uncommon',type='skill',baseCost=1,baseMagic=1,
	enemyTarget=true,upgrade={description='Triple the enemy\'s {Poison}.',baseMagic=2},
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
	name='Choke',description='{Damage} !D!. NL Whenever you play a card this turn, the enemy loses !M! HP.',rarity='uncommon',type='skill',
	baseCost=2,baseDamage=12,baseMagic=3,enemyTarget=true,upgrade={baseMagic=5},
}
function Choke:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage}, ApplyPowerAction:new(player,ChokePower:new(target,self.magic)) }
end

ChokePower = Power:new{icon=197}
function ChokePower:onUseCard()
	addAction(DamageAction:new{target=self.owner,source=player,value=self.amount,type='hpLoss'})
end

function ChokePower:onTurnStart()
	addAction(RemovePowerAction:new(self))
end

Concentrate = GreenCard:new{
	name='Concentrate',description='Discard !M! card. NL Gain {Energy}{Energy}.',rarity='uncommon',type='skill',baseCost=0,baseMagic=3,
	playerTarget=true,upgrade={baseMagic=2},
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

function Eviscerate:onDiscard()
	self.numDiscarded = self.numDiscarded + 1
end

function Eviscerate:onModifyCost(cost,card)
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
	enemyTarget=true,upgrade={baseDamage=8},displayAttackCount='?',numAttackPlayed=0,
}
function Finisher:onTurnStart()
	self.numAttackPlayed = 0
end

function Finisher:onUseCard(card)
	if card.type == 'attack' then
		self.numAttackPlayed = self.numAttackPlayed + 1
	end
end

function Finisher:applyPowers(target)
	self.displayAttackCount = self.numAttackPlayed
	GreenCard.applyPowers(self,target)
end

function Finisher:resetPowers()
	self.displayAttackCount = '?'
	GreenCard.resetPowers(self)
end

function Finisher:use(target)
	local result = {}
	for i=1,self.numAttackPlayed do
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

function Flechettes:onDraw()
	if table.anyMatch(hand,function (cardItem) return cardItem.card == self end) then
		self.displayAttackCount = table.count(hand,function (cardItem) return cardItem.card.type == 'skill' end)
	end
end

function Flechettes:onRemoveHand()
	if table.anyMatch(hand,function (cardItem) return cardItem.card == self end) then
		self.displayAttackCount = table.count(hand,function (cardItem) return cardItem.card.type == 'skill' end)
	end
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

greenCards = {
	StrikeGreen,DefendGreen,Neutralize,Survivor,Acrobatics,Backflip,Bane,BladeDance,CloakAndDagger,DaggerSpray,DaggerThrow,
	DeadlyPoison,Deflect,DodgeAndRoll,FlyingKnee,Outmaneuver,PiercingWail,PoisonedStab,Prepared,QuickSlash,Slice,SneakyStrike,
	SuckerPunch,Accuracy,AllOutAttack,BackStab,Blur,BouncingFlask,CalculatedGamble,Caltrops,Catalyst,Choke,Concentrate,
	CrippingCloud,Dash,Distraction,EndlessAgony,EscapePlan,Eviscerate,Expertise,Finisher,Flechettes,
}

-- relics

GreenRelic = Relic:new{colorName='green'}

RingOfTheSnake = GreenRelic:new{name='Ring of the Snake',icon=243,tier='basic',description='At the start of each combat, draw #11#2#12# additional cards.'}
function RingOfTheSnake:onTurnStartPostDraw(turn)
	if turn == 1 then
		addAction(DrawCardAction:new(2))
	end
end
