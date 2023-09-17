---@diagnostic disable lowercase-global

local purpleCards

WatcherEventListener = { lastCardPlayed=nil }
function WatcherEventListener:onCombatStart()
	self.lastCardPlayed = nil
end

function WatcherEventListener:onUseCard(card)
	self.lastCardPlayed = card
end

table.insert(playerEventListeners,WatcherEventListener)

local stanceIcons

Watcher = Player:new{ maxHp=72,width=6,height=5,y=44,tileBank=4,name='Watcher',energyYOffset=1 }
function Watcher:drawImage()
	if self.flipped then
		line(self.x+46,self.y+4,self.x-1,self.y+27,3)
		pix(self.x-2,self.y+27,3)
		map(21,9,3,4,self.x+8,self.y,0,1,flipRemap(21,3))
		map(24,9,2,1,self.x+32,self.y+19,0,1,flipRemap(24,2))
		spr(194,self.x+21,self.y+32,0,1,1)
		local icon = stanceIcons[self.stance] or stanceIcons[Neutral]
		icon.flip = true
		drawIcon(icon,self.x+46,self.y)
		icon.flip = false
	else
		line(self.x+1,self.y+4,self.x+48,self.y+27,3)
		pix(self.x+49,self.y+27,3)
		map(21,9,3,4,self.x+16,self.y,0)
		map(24,9,2,1,self.x,self.y+19,0)
		spr(194,self.x+19,self.y+32,0)
		local icon = stanceIcons[self.stance] or stanceIcons[Neutral]
		drawIcon(icon,self.x-6,self.y)
	end
end

function Watcher:drawCorpse()
	map(7,13,7,2,self.x-4,self.y+20,0)
end

function Watcher:getStartDeck()
	local deck = {}
	table.insert(deck,StrikePurple:new())
	table.insert(deck,StrikePurple:new())
	table.insert(deck,StrikePurple:new())
	table.insert(deck,StrikePurple:new())
	table.insert(deck,DefendPurple:new())
	table.insert(deck,DefendPurple:new())
	table.insert(deck,DefendPurple:new())
	table.insert(deck,DefendPurple:new())
	table.insert(deck,Eruption:new())
	table.insert(deck,Vigilance:new())
	return deck
end

function Watcher:getCards()
	return purpleCards
end

function Watcher:getStartRelics()
	return { PureWater:new() }
end

function Watcher:getAscensionMaxHPLoss()
	return 4
end

function Watcher:getMatchAndKeepCardType()
	return Neutralize
end

function Watcher:getRelics()
	return {
		PureWater,
		Damaru,
		Duality,TeardropLocket,
		CloakClasp,GoldenEye,
		HolyWater,VioletLotus,
		Melange,
	}
end

function Watcher:getPotions()
	return { BottledMiracle,StancePotion,Ambrosia }
end

function Watcher:getPronouns()
	return {vampires='sister'}
end

function Watcher:getSpireHeartText()
	return 'NL You prime your staff with divine energy...'
end

function Watcher:getEnding()
	return IroncladEnding:new()
end

function Watcher:resetPosition()
	Player.resetPosition(self)
	self.y = 44
end

function Watcher:drawEnergyIndicator()
	map(0,2,3,3,4,94,5)
	local energyText = energy .. '/' .. maxEnergy
	local width = strWidth(energyText)
	printShadowed(energyText,16-width/2,105+self.energyYOffset,12)
end

-- stances
Stance = Object:new{priority=160,draw=noop}

Neutral = Stance:new{}

Wrath = Stance:new{}
function Wrath:onAttack(damage)
	return damage * 2
end

function Wrath:onAttacked(damage)
	return damage * 2
end

function Wrath:draw()
	if math.floor(time()) % effectRandom:randInt(3,5) == 0 and getmetatable(nearestWindow) == GameWindow then
		local x = effectRandom:randInt(-12,12) + player.x + player.width * 4
		local y = effectRandom:randInt(4,player.height*8) + player.y
		addEffect(WrathEffect:new{x1=x,y1=y,y1Speed=effectRandom:randFloat(-0.4,-0.2)})
	end
end

Calm = Stance:new{}
function Calm:onExitStance()
	addAction(GainEnergyAction:new(2))
end

function Calm:draw()
	if math.floor(time()) % effectRandom:randInt(4,6) == 0 and getmetatable(nearestWindow) == GameWindow then
		local x = effectRandom:randInt(-4,28) + player.x + player.width * 4
		local y = effectRandom:randInt(6,player.height*8-4) + player.y
		addEffect(CalmEffect:new{x1=x,y1=y,x1Speed=effectRandom:randFloat(-0.4,-0.3)})
	end
end

Divinity = Stance:new{}
function Divinity:onEnterStance()
	addAction(GainEnergyAction:new(3))
end

function Divinity:onAttack(damage)
	return damage * 3
end

function Divinity:onTurnStart(turn)
	if turn ~= 1 then
		addAction(ChangeStanceAction:new(Neutral))
	end
end

function Divinity:draw()
	if math.floor(time()) % effectRandom:randInt(14,16) == 0 and getmetatable(nearestWindow) == GameWindow then
		local x = effectRandom:randInt(-16,16) + player.x + player.width * 4
		local y = effectRandom:randInt(4,player.height*8-4) + player.y
		addEffect(DivinityEffect:new{x=x,y=y})
	end
end

stanceIcons = {
	[Neutral] = Icon:new{image=210,colorMap={[10]=4,[11]=4,[15]=4}},
	[Wrath] = Icon:new{image=210,colorMap={[10]=2,[11]=3}},
	[Calm] = Icon:new{image=210},
	[Divinity] = Icon:new{image=210,colorMap={[10]=8,[11]=8}},
}

WrathEffect = Effect:new{duration=40,x1=0,y1=0,x2=0,y2=0,y1Speed=-0.4,y2Speed=-0.1}
function WrathEffect:new(o)
	local r = Effect.new(self,o)
	r.x2 = r.x1
	r.y2 = r.y1
	return r
end

function WrathEffect:tick()
	self.y1 = self.y1 + self.y1Speed
	self.y2 = self.y2 + self.y2Speed
	if self.y1 > self.y2 then
		self.isDone = true
		return
	end
	self.y2Speed = self.y2Speed - 0.01
	line(self.x1,self.y1,self.x2,self.y2,3)
	Effect.tick(self)
end

CalmEffect = Effect:new{duration=80,x1=0,y1=0,x2=0,y2=0,x1Speed=-0.4,x2Speed=-0.05,y1Speed=0.1,y2Speed=0.03}
function CalmEffect:new(o)
	local r = Effect.new(self,o)
	r.x2 = r.x1
	r.y2 = r.y1
	r.k = r.y1Speed / r.x1Speed
	r.y2Speed = r.x2Speed * r.k
	return r
end

function CalmEffect:tick()
	self.y1 = self.y1 + self.y1Speed
	self.y2 = self.y2 + self.y2Speed
	self.x1 = self.x1 + self.x1Speed
	self.x2 = self.x2 + self.x2Speed
	if self.x1 > self.x2 then
		self.isDone = true
		return
	end
	self.x2Speed = self.x2Speed - 0.01
	self.y2Speed = self.y2Speed - 0.01 * self.k
	line(self.x1,self.y1,self.x2,self.y2,11)
	Effect.tick(self)
end

local divinityEffectIcons = {
	Icon:new{image=195,colorMap={0,8,0,8,0,8,0,8},transparentColor={0,1,3,5,7}},
	Icon:new{image=195,colorMap={0,0,8,8,0,0,8,8},transparentColor={0,1,2,5,6}},
	Icon:new{image=195,colorMap={0,0,0,0,8,8,8,8},transparentColor={0,1,2,3,4}},
	Icon:new{image=195,colorMap={0,0,0,0,1,1,1,1},transparentColor={0,1,2,3,4}},
}
local divinityEffectIconSequence = { 4,3,2,1,1,1,2,3,4 }
local divinityEffectIconInterval = 6
DivinityEffect = Effect:new{duration=#divinityEffectIconSequence*divinityEffectIconInterval,x=0,y=0}
function DivinityEffect:tick()
	Effect.tick(self)
	local icon = divinityEffectIcons[divinityEffectIconSequence[math.ceil(self.duration/divinityEffectIconInterval)]]
	drawIcon(icon,self.x-4,self.y-4)
end

-- cards

PurpleCard = Card:new{color={8,1},typeIconColor=4,colorName='purple'}

StrikePurple = PurpleCard:new{ name='Strike',description='{Damage} !D!.',rarity='basic',baseCost=1,baseDamage=6,enemyTarget=true,upgrade={baseDamage=9},tags={'strike','basicStrike'} }
function StrikePurple:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

DefendPurple = PurpleCard:new{ name='Defend',description='Gain !B! {Block}.',rarity='basic',type='skill',baseCost=1,baseBlock=5,playerTarget=true,upgrade={baseBlock=8},tags={'basicDefend'} }
function DefendPurple:use()
	return { GainBlockAction:new{target=player,value=self.block} }
end

Eruption = PurpleCard:new{
	name='Eruption',description='Damage {Energy}. NL Enter Wrath.',rarity='basic',baseCost=2,playerTarget=true,
	baseDamage=9,enemyTarget=true,upgrade={baseCost=1},
}
function Eruption:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage},ChangeStanceAction:new(Wrath) }
end

Vigilance = PurpleCard:new{
	name='Vigilance',description='Gain !B! {Block}. NL Enter Calm.',rarity='basic',type='skill',baseCost=2,playerTarget=true,
	baseBlock=8,upgrade={baseBlock=12},
}
function Vigilance:use()
	return { GainBlockAction:new{target=player,value=self.block},ChangeStanceAction:new(Calm) }
end

MantraPower = Power:new{icon=icons.Mantra,description='When you obtain #11#10#12# {Mantra}, enter Divinity.'}
function MantraPower:onAmountUpdated()
	if self.amount >= 10 then
		self.amount = self.amount % 10
		addAction(1,ChangeStanceAction:new(Divinity))
		if self.amount == 0 then
			addAction(2,RemovePowerAction:new(self))
		end
	end
end

BowlingBash = PurpleCard:new{
	name='Bowling Bash',description='{Damage} !D! for each enemy in combat.',rarity='common',baseCost=1,
	baseDamage=7,enemyTarget=true,upgrade={baseDamage=10},displayAttackCount='?'
}
function BowlingBash:applyPowers(target)
	self.displayAttackCount = table.count(enemies,function (enemy) return enemy.canInteract end)
	PurpleCard.applyPowers(self,target)
end

function BowlingBash:resetPowers()
	self.displayAttackCount = '?'
	PurpleCard.resetPowers(self)
end

function BowlingBash:use(target)
	local actions = {}
	for _,enemy in ipairs(enemies) do
		if enemy.canInteract then
			table.insert(actions,DamageAction:new{target=target,source=player,value=self.damage})
		end
	end
	return actions
end

Consecrate = PurpleCard:new{
	name='Consecrate',description='{Damage} !D! to all enemies.',rarity='common',baseCost=0,
	baseDamage=5,enemyTarget=true,toAllEnemies=true,upgrade={baseDamage=8},
}
function Consecrate:use()
	return { DamageAllEnemiesAction:new{source=player,value=self.multiDamage} }
end

Crescendo = PurpleCard:new{
	name='Crescendo',description='Retain. NL Enter Wrath. NL Exhaust.',rarity='common',type='skill',baseCost=1,
	playerTarget=true,upgrade={baseCost=0},retain=true,exhaust=true,
}
function Crescendo:use()
	return { ChangeStanceAction:new(Wrath) }
end

CrushJoints = PurpleCard:new{
	name='Crush Joints',description='{Damage} !D!. NL If the last card played this combat was a {Skill}, apply !M! {Vulnerable}.',rarity='common',baseCost=1,
	baseDamage=8,baseMagic=1,enemyTarget=true,upgrade={baseDamage=10,baseMagic=2},
}
function CrushJoints:use(target)
	local actions = { DamageAction:new{target=target,source=player,value=self.damage} }
	local lastCardPlayed = WatcherEventListener.lastCardPlayed
	if lastCardPlayed and lastCardPlayed.type == 'skill' then
		table.insert(actions,ApplyPowerAction:new(player,VulnerablePower:new(target,self.magic)))
	end
	return actions
end

function CrushJoints:checkGlow()
	local lastCardPlayed = WatcherEventListener.lastCardPlayed
	if lastCardPlayed and lastCardPlayed.type == 'skill' then
		return 4
	end
end

CutThroughFate = PurpleCard:new{
	name='Cut Through Fate',description='{Damage} !D!. NL Scry !M!. NL Draw 1 card.',rarity='common',baseCost=1,
	baseDamage=7,baseMagic=2,enemyTarget=true,upgrade={baseDamage=9,baseMagic=3},
}
function CutThroughFate:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage},ScryAction:new(self.magic),DrawCardAction:new(1) }
end

EmptyBody = PurpleCard:new{
	name='Empty Body',description='Gain !B! {Block}. NL Exit stance.',rarity='common',type='skill',baseCost=1,
	baseBlock=7,playerTarget=true,upgrade={baseBlock=10},
}
function EmptyBody:use()
	return { GainBlockAction:new{target=player,value=self.block},ChangeStanceAction:new(Neutral) }
end

EmptyFist = PurpleCard:new{
	name='Empty Fist',description='{Damage} !D!. NL Exit stance.',rarity='common',baseCost=1,
	baseDamage=9,enemyTarget=true,upgrade={baseDamage=14},
}
function EmptyFist:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage},ChangeStanceAction:new(Neutral) }
end

Evaluate = PurpleCard:new{
	name='Evaluate',description='Gain !B! {Block}. NL Shuffle an Insight into draw pile.',rarity='common',type='skill',baseCost=1,
	baseBlock=6,playerTarget=true,upgrade={baseBlock=10},
}
function Evaluate:use()
	return { GainBlockAction:new{target=player,value=self.block},MakeTempCardToDrawPileAction:new(Insight:new()) }
end

-- TODO description is too long
FlurryOfBlows = PurpleCard:new{
	name='Flurry of Blows',description='{Damage} !D!. NL Whenever you change stances, return this from discard pile to hand.',
	rarity='common',baseCost=0,baseDamage=4,enemyTarget=true,upgrade={baseDamage=6},
}
function FlurryOfBlows:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

function FlurryOfBlows:onEnterStance()
	if table.anyMatch(discardPile,function (card) return card == self end) then
		addAction(AnonymousAction:new(function ()
			table.remove(discardPile,table.indexOf(discardPile,self))
			insertHand(CardItem:new{card=self,x=240,y=136})
		end))
	end
end

FlyingSleeves = PurpleCard:new{
	name='Flying Sleeves',description='Retain. NL {Damage} !D! twice.',rarity='common',baseCost=1,
	baseDamage=4,enemyTarget=true,upgrade={baseDamage=6},displayAttackCount=2,retain=true,
}
function FlyingSleeves:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage},DamageAction:new{target=target,source=player,value=self.damage} }
end

FollowUp = PurpleCard:new{
	name='Follow-Up',description='{Damage} !D!. NL If the last card played this combat was a {Attack}, gain {Energy}.',rarity='common',
	baseCost=1,baseDamage=7,enemyTarget=true,playerTarge=true,upgrade={baseDamage=11},
}
function FollowUp:use(target)
	local actions = { DamageAction:new{target=target,source=player,value=self.damage} }
	local lastCardPlayed = WatcherEventListener.lastCardPlayed
	if lastCardPlayed and lastCardPlayed.type == 'attack' then
		table.insert(actions,GainEnergyAction:new(1))
	end
	return actions
end

function FollowUp:checkGlow()
	local lastCardPlayed = WatcherEventListener.lastCardPlayed
	if lastCardPlayed and lastCardPlayed.type == 'attack' then
		return 4
	end
end

Halt = PurpleCard:new{
	name='Halt',description='Gain !B! {Block}. NL Wrath: Gain !M! additional {Block}.',rarity='common',type='skill',baseCost=0,
	baseBlock=3,baseMagic=9,playerTarget=true,upgrade={baseBlock=4,baseMagic=14},
}
function Halt:applyPowers(target)
	local oldBaseBlock = self.baseBlock
	self.baseBlock = self.baseMagic
	PurpleCard.applyPowers(self,target)
	local magic = self.block
	self.baseBlock = oldBaseBlock
	PurpleCard.applyPowers(self,target)
	self.magic = magic
end

function Halt:use()
	local actions = { GainBlockAction:new{target=player,value=self.block} }
	if player.stance == Wrath then
		table.insert(actions,GainBlockAction:new{target=player,value=self.magic})
	end
	return actions
end

JustLucky = PurpleCard:new{
	name='Just Lucky',description='Scry !M!. NL Gain !B! {Block}. NL {Damage} !D!.',rarity='common',baseCost=0,
	baseMagic=1,baseBlock=2,baseDamage=3,enemyTarget=true,playerTarge=true,upgrade={baseMagic=2,baseBlock=3,baseDamage=4},
}
function JustLucky:use(target)
	return {
		ScryAction:new(self.magic),
		GainBlockAction:new{target=player,value=self.block},
		DamageAction:new{target=target,source=player,value=self.damage}
	}
end

PressurePoints = PurpleCard:new{
	name='Pressure Points',description='Apply !M! {248}. NL All enemies lose HP equal to their {248}.',rarity='common',type='skill',
	baseCost=1,baseMagic=8,enemyTarget=true,upgrade={baseMagic=11},
}
function PressurePoints:use(target)
	return {
		ApplyPowerAction:new(target,MarkPower:new(target,self.magic)),
		AnonymousAction:new(function ()
			local index = 1
			for _,enemy in ipairs(enemies) do
				if enemy.canInteract then
					local mark = enemy:getPower(MarkPower)
					if mark then
						addAction(index,DamageAction:new{target=enemy,source=player,value=mark.amount,type='hpLoss'})
						index = index + 1
					end
				end
			end
		end)
	}
end

MarkPower = Power:new{icon=248,description='Whenever you play Pressure Points, loses #11#!A!#12# HP.'}

Prostrate = PurpleCard:new{
	name='Prostrate',description='Gain !M! {MantraCard}. NL Gain !B! {Block}.',rarity='common',type='skill',baseCost=0,
	baseBlock=4,baseMagic=2,playerTarget=true,upgrade={baseMagic=3},
}
function Prostrate:use()
	return {
		ApplyPowerAction:new(player,MantraPower:new(player,self.magic)),
		GainBlockAction:new{target=player,value=self.block},
	}
end

Protect = PurpleCard:new{
	name='Protect',description='Retain. NL Gain !B! {Block}.',rarity='common',type='skill',baseCost=2,
	baseBlock=12,playerTarget=true,upgrade={baseBlock=16},retain=true,
}
function Protect:use()
	return { GainBlockAction:new{target=player,value=self.block} }
end

SashWhip = PurpleCard:new{
	name='Sash Whip',description='{Damage} !D!. NL If the last card played this combat was a {Attack}, apply !M! {Weak}.',rarity='common',
	baseCost=1,baseDamage=8,baseMagic=1,enemyTarget=true,upgrade={baseDamage=10,baseMagic=2},
}
function SashWhip:use(target)
	local actions = { DamageAction:new{target=target,source=player,value=self.damage} }
	local lastCardPlayed = WatcherEventListener.lastCardPlayed
	if lastCardPlayed and lastCardPlayed.type == 'attack' then
		table.insert(actions,ApplyPowerAction:new(target,WeakPower:new(target,self.magic)))
	end
	return actions
end

function SashWhip:checkGlow()
	local lastCardPlayed = WatcherEventListener.lastCardPlayed
	if lastCardPlayed and lastCardPlayed.type == 'attack' then
		return 4
	end
end

ThirdEye = PurpleCard:new{
	name='Third Eye',description='Gain !B! {Block}. NL Scry !M!.',rarity='common',type='skill',baseCost=1,
	baseBlock=7,baseMagic=3,playerTarget=true,upgrade={baseBlock=9,baseMagic=5},
}
function ThirdEye:use()
	return { GainBlockAction:new{target=player,value=self.block},ScryAction:new(self.magic) }
end

Tranquility = PurpleCard:new{
	name='Tranquility',description='Retain. NL Enter Calm. NL Exhaust.',rarity='common',type='skill',baseCost=1,
	playerTarget=true,upgrade={baseCost=0},exhaust=true,retain=true,
}
function Tranquility:use()
	return { ChangeStanceAction:new(Calm) }
end

purpleCards = {
	StrikePurple,DefendPurple,Eruption,Vigilance,BowlingBash,Consecrate,Crescendo,CrushJoints,CutThroughFate,EmptyBody,
	EmptyFist,Evaluate,FlurryOfBlows,FlyingSleeves,FollowUp,Halt,JustLucky,PressurePoints,Prostrate,Protect,SashWhip,
	ThirdEye,Tranquility,
}

-- relics
PurpleRelic = Relic:new{colorName='purple'}

PureWater = PurpleRelic:new{
	name='Pure Water',tier='basic',icon=Icon:new{image=243,colorMap={10,10,12,[8]=11},transparentColor={0,4}},
	description='At the start of each combat, add a Miracle to hand.'
}
function PureWater:onCombatStart()
	addAction(MakeTempCardToHandAction:new(Miracle:new()))
end

Damaru = PurpleRelic:new{ name='Damaru',tier='common',icon=244,description='At the start of turn, gain #11#1#12# {Mantra}.' }
function Damaru:onTurnStart()
	addAction(ApplyPowerAction:new(player,MantraPower:new(player,5)))
end

Duality = PurpleRelic:new{ name='Duality',tier='uncommon',icon=229,description='Whenever you play a {Attack}, gain #11#1#12# temporary {Dexterity}.' }
function Duality:onUseCard(card)
	if card.type == 'attack' then
		addAction(ApplyPowerAction:new(player,DexterityPower:new(player,1)))
		addAction(ApplyPowerAction:new(player,LoseDexterityPower:new(player,1)))
	end
end

TeardropLocket = PurpleRelic:new{ name='Teardrop Locket',tier='uncommon',icon=230,description='Start each combat in Calm.' }
function TeardropLocket:onCombatStart()
	addAction(ChangeStanceAction:new(Calm))
end

CloakClasp = PurpleRelic:new{ name='Cloak Clasp',tier='rare',icon=231,description='At the end of turn, gain #11#1#12# {Block} for each card in hand.' }
function CloakClasp:onTurnEnd()
	addAction(GainBlockAction:new{target=player,value=#hand})
end

GoldenEye = PurpleRelic:new{ name='Golden Eye',tier='rare',icon=245,description='Whenever you Scry, Scry #11#2#12# additional cards.' }
function GoldenEye:modifyScryAmount(amount)
	return amount + 2
end

Melange = PurpleRelic:new{ name='Melange',tier='shop',icon=246,description='Whenever you shuffle draw pile, Scry #11#3#12#.' }
function Melange:onShuffle()
	addAction(ScryAction:new(3))
end

HolyWater = PurpleRelic:new{ name='Holy Water',tier='boss',icon=243,replaces=PureWater,description='Replaces #8#Pure Water#12#. At the start of each combat, add #11#3#12# Miracles into your hand.' }
function HolyWater:onCombatStart()
	addAction(MakeTempCardToHandAction:new(Miracle:new(),3))
end

VioletLotus = PurpleRelic:new{ name='Violet Lotus',tier='boss',icon=247,description='Whenever you exit Calm, gain an additional {Energy}.' }
function VioletLotus:onExitStance(stance)
	if stance == Calm then
		addAction(GainEnergyAction:new(1))
	end
end

-- potions
BottledMiracle = Potion:new{
	name='Bottled Miracle',icon=Icon:new{image=100,colorMap={13,4,4}},baseMagic=2,description='Add #11#!M!#12# Miracles to your hand.',rarity='common'
}
function BottledMiracle:use()
	return { MakeTempCardToHandAction:new(Miracle:new(),self.magic) }
end

StancePotion = Potion:new{
	name='Stance Potion',icon=Icon:new{image=100,colorMap={1,8,1}},description='Enter Calm or Wrath.',rarity='uncommon',
}
function StancePotion:use()
	return { AnonymousAction:new(function ()
		local calm = ColorlessCard:new{name='Calm',description='Upon exiting Calm, gain {Energy}{Energy}.',rarity='special',type='skill',baseCost=-2}
		local wrath = ColorlessCard:new{name='Wrath',description='Deal and receive double attack damage.',rarity='special',type='skill',baseCost=-2}
		openWindowAbove(CardRewardWindow:new{cards={wrath,calm},title='Choose One',canClose=false},function (cardItem)
			if cardItem.card == calm then
				addAction(ChangeStanceAction:new(Calm))
			else
				addAction(ChangeStanceAction:new(Wrath))
			end
		end)
	end) }
end

Ambrosia = Potion:new{
	name='Ambrosia',icon=Icon:new{image=107,colorMap={1,8}},description='Enter Divinity.',rarity='rare',
}
function Ambrosia:use()
	return { ChangeStanceAction:new(Divinity) }
end
