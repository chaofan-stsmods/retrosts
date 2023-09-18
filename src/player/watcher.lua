---@diagnostic disable lowercase-global

local purpleCards

WatcherEventListener = { lastCardPlayed=nil,mantraGainThisCombat=0 }
function WatcherEventListener:onCombatStart()
	self.lastCardPlayed = nil
	self.mantraGainThisCombat = 0
end

function WatcherEventListener:onUseCard(card)
	self.lastCardPlayed = card
end

function WatcherEventListener:onAppliedPower(power)
	if getmetatable(power) == MantraPower then
		self.mantraGainThisCombat = self.mantraGainThisCombat + power.amount
	end
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
	map(21,13,8,3,self.x-12,self.y+20,0)
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
DivinityEffect = Effect:new{duration=#divinityEffectIconSequence*divinityEffectIconInterval,x=0,y=0,darken=false}
function DivinityEffect:tick()
	Effect.tick(self)
	local icon = divinityEffectIcons[divinityEffectIconSequence[math.ceil(self.duration/divinityEffectIconInterval)]]
	local wasDarken = isDarken
	if self.darken and not isDarken then
		darkenColors()
	end
	drawIcon(icon,self.x-4,self.y-4)
	if self.darken and not wasDarken then
		resetColors()
	end
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
	name='Eruption',description='Damage !D!. NL Enter Wrath.',rarity='basic',baseCost=2,playerTarget=true,
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

FlurryOfBlows = PurpleCard:new{
	name='Flurry of Blows',description='{Damage} !D!. NL When stance is changed, return this from discard pile to hand.',
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
	name='Halt',description='Gain !B! {Block}. NL If you are in Wrath, gain !M! additional {Block}.',rarity='common',type='skill',baseCost=0,
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

MarkPower = Power:new{icon=248,debuff=true,description='Whenever you play Pressure Points, loses #11#!A!#12# HP.'}

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

BattleHymn = PurpleCard:new{
	name='Battle Hymn',description='At the start of each turn, add a Smite into hand.',rarity='uncommon',type='power',baseCost=1,
	playerTarget=true,upgrade={description='Innate. NL At the start of each turn, add a Smite into hand.',innate=true},
}
function BattleHymn:use()
	return { ApplyPowerAction:new(player,BattleHymnPower:new(player,1)) }
end

BattleHymnPower = Power:new{icon=196,description='At the start of each turn, add #11#!A!#12# Smite{s} into hand.'}
function BattleHymnPower:onTurnStart()
	addAction(MakeTempCardToHandAction:new(Smite:new(),self.amount))
end

CarveReality = PurpleCard:new{
	name='Carve Reality',description='{Damage} !D!. NL Add a Smite into hand.',rarity='uncommon',baseCost=1,
	baseDamage=6,playerTarget=true,enemyTarget=true,upgrade={baseDamage=10},
}
function CarveReality:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage},MakeTempCardToHandAction:new(Smite:new()) }
end

Collect = PurpleCard:new{
	name='Collect',description='Put a Miracle+ into hand at the start of next X turns. NL Exhaust.',rarity='uncommon',
	type='skill',baseCost=-1,playerTarget=true,upgrade={description='Put a Miracle+ into hand at the start of next X+1 turns. NL Exhaust.'},exhaust=true,
}
function Collect:use(_,energyOnUse,free)
	local upgraded = self.upgraded
	return {
		XCardAction:new(function (amount)
			if upgraded then
				amount = amount + 1
			end
			return { ApplyPowerAction:new(player,CollectPower:new(player,amount)) }
		end,energyOnUse,free)
	}
end

CollectPower = TurnBasedPower:new{icon=211,description='At the start of next #11#!A!#12# turn{s}, put a Miracle+ into hand.'}
function CollectPower:onTurnStart()
	local card = Miracle:new()
	card:upgrade()
	addAction(MakeTempCardToHandAction:new(card))
	TurnBasedPower.onTurnStart(self)
end

Conclude = PurpleCard:new{
	name='Conclude',description='{Damage} !D! to all enemies. NL End your turn.',rarity='uncommon',baseCost=1,baseDamage=12,
	playerTarget=true,enemyTarget=true,toAllEnemies=true,upgrade={baseDamage=16},
}
function Conclude:use()
	addAction(EndTurnAction:new())
	return {
		AnonymousAction:new(function ()
			disableAllUseCardActions()
		end),
		DamageAllEnemiesAction:new{source=player,value=self.multiDamage},
	}
end

DeceiveReality = PurpleCard:new{
	name='Deceive Reality',description='Gain !B! {Block}. NL Add a Safety into hand.',rarity='uncommon',type='skill',baseCost=1,
	baseBlock=4,playerTarget=true,upgrade={baseBlock=7},
}
function DeceiveReality:use()
	return { GainBlockAction:new{target=player,value=self.block},MakeTempCardToHandAction:new(Safety:new()) }
end

EmptyMind = PurpleCard:new{
	name='Empty Mind',description='Draw !M! cards. NL Exit stance.',rarity='uncommon',type='skill',baseCost=1,
	baseMagic=2,playerTarget=true,upgrade={baseMagic=3},
}
function EmptyMind:use()
	return { DrawCardAction:new(self.magic),ChangeStanceAction:new(Neutral) }
end

Fasting = PurpleCard:new{
	name='Fasting',description='Gain !M! {Strength}. NL Gain !M! {Dexterity}. NL Gain 1 less {Energy} at the start of each turn.',rarity='uncommon',
	type='power',baseCost=2,baseMagic=3,playerTarget=true,upgrade={baseMagic=4},
}
function Fasting:use()
	return {
		ApplyPowerAction:new(player,StrengthPower:new(player,self.magic)),
		ApplyPowerAction:new(player,DexterityPower:new(player,self.magic)),
		ApplyPowerAction:new(player,FastingPower:new(player,1))
	}
end

FastingPower = Power:new{icon=232,debuff=true,description='At the start of turn, lose #11#!A!#12# {Energy}.'}
function FastingPower:onTurnStart()
	addAction(GainEnergyAction:new(-self.amount))
end

FearNoEvil = PurpleCard:new{
	name='Fear No Evil',description='{Damage} !D!. NL If the enemy intends to attack, enter Calm.',rarity='uncommon',
	baseCost=1,baseDamage=8,playerTarget=true,enemyTarget=true,upgrade={baseDamage=11},
}
function FearNoEvil:use(target)
	return {
		DamageAction:new{target=target,source=player,value=self.damage},
		AnonymousAction:new(function ()
			if target.intentType:sub(1,6) == 'attack' then
				addAction(ChangeStanceAction:new(Calm))
			end
		end),
	}
end

ForeignInfluence = PurpleCard:new{
	name='Foreign Influence',description='Choose 1 of 3 any color {Attack} to add into hand. NL Exhaust.',rarity='uncommon',type='skill',
	baseCost=1,playerTarget=true,upgrade={description='Choose 1 of 3 any color {Attack} to add into hand. It costs 0 this turn. NL Exhaust.'},exhaust=true,
}
function ForeignInfluence:use()
	local upgraded = self.upgraded
	return {
		AnonymousAction:new(function ()
			local cards = {}
			for i = 1, 3 do
				local rarity = 'rare'
				local roll = miscRand:randInt(0,99)
				if roll < 55 then
					rarity = 'common'
				elseif roll < 85 then
					rarity = 'uncommon'
				end
				local card
				repeat
					card = getAllPlayerCardType(miscRand,rarity,'attack'):new()
				until card.canGenerateInCombat and not table.anyMatch(cards,function (c) return getmetatable(c) == getmetatable(card) end)
				cards[i] = card
			end
			openWindowAbove(CardRewardWindow:new{cards=cards,canClose=true},function (cardItem)
				if not cardItem then
					return
				end
				if cardItem.card:getCost() >= 0 and upgraded then
					cardItem.card.costForOneTurnPlay = 0
				end
				addAction(1,MakeTempCardToHandAction:new(cardItem.card,1,{cardItem=cardItem}))
			end)
		end)
	}
end

Foresight = PurpleCard:new{
	name='Foresight',description='At start of turn, scry !M!.',rarity='uncommon',type='power',baseCost=1,
	baseMagic=3,playerTarget=true,upgrade={baseMagic=4},
}
function Foresight:use()
	return { ApplyPowerAction:new(player,ForesightPower:new(player,self.magic)) }
end

ForesightPower = Power:new{icon=214,description='At the start of turn, scry #11#!A!#12#.'}
function ForesightPower:onTurnStart()
	addAction(AnonymousAction:new(function ()
		if #drawPile == 0 then
			addAction(1,ShuffleAction:new())
		end
	end))
	addAction(ScryAction:new(self.amount))
end

Indignation = PurpleCard:new{
	name='Indignation',description='If you are in Wrath, apply !M! {Vulnerable} to all enemies, otherwise enter Wrath.',rarity='uncommon',
	type='skill',baseCost=1,baseMagic=3,playerTarget=true,enemyTarget=true,toAllEnemies=true,upgrade={baseMagic=4},
}
function Indignation:use()
	if player.stance == Wrath then
		local result = {}
		for _, enemy in ipairs(enemies) do
			table.insert(result,ApplyPowerAction:new(player,VulnerablePower:new(enemy,self.magic)))
		end
		return result
	else
		return { ChangeStanceAction:new(Wrath) }
	end
end

InnerPeace = PurpleCard:new{
	name='Inner Peace',description='If you are in Calm, draw !M! cards, otherwise enter Calm.',rarity='uncommon',type='skill',baseCost=1,
	playerTarget=true,baseMagic=3,upgrade={baseMagic=4},
}
function InnerPeace:use()
	if player.stance == Calm then
		return { DrawCardAction:new(self.magic) }
	else
		return { ChangeStanceAction:new(Calm) }
	end
end

LikeWater = PurpleCard:new{
	name='Like Water',description='At the end of turn, if you are in Calm, gain !M! {Block}.',rarity='uncommon',type='power',baseCost=1,
	baseMagic=5,playerTarget=true,upgrade={baseMagic=7},
}
function LikeWater:use()
	return { ApplyPowerAction:new(player,LikeWaterPower:new(player,self.magic)) }
end

LikeWaterPower = Power:new{icon=215,description='At the end of turn, if you are in Calm, gain #11#!A!#12# {Block}.'}
function LikeWaterPower:onTurnEnd()
	if player.stance == Calm then
		addAction(GainBlockAction:new{target=player,value=self.amount})
	end
end

Meditate = PurpleCard:new{
	name='Meditate',description='Put a card from discard pile into hand and Retain. NL Enter Calm. NL End your turn.',rarity='uncommon',
	type='skill',baseCost=1,playerTarget=true,baseMagic=1,
	upgrade={baseMagic=2,description='Put !M! card from discard pile into hand and Retain. NL Enter Calm. NL End your turn.'},
}
function Meditate:use()
	local amount = self.magic
	addAction(EndTurnAction:new())
	return {
		AnonymousAction:new(function ()
			disableAllUseCardActions()
			local cardItems = {}
			for i, card in ipairs(discardPile) do
				cardItems[i] = CardItem:new{card=card,x=240,y=136,tx=240,ty=136,isNotInHand=true}
			end
			if #cardItems == 0 then
				return
			elseif #cardItems <= amount then
				for _, cardItem in ipairs(cardItems) do
					table.remove(discardPile,table.indexOf(discardPile,cardItem.card))
					insertHand(cardItem)
					cardItem.card.tempRetain = true
				end
			else
				local title = amount == 1 and 'Choose a Card to Put into Hand' or 'Choose Cards to Put into Hand ({#}/'..amount..')'
				openWindowAbove(CardGridSelectWindow:new{cardItems=cardItems,title=title,min=amount,max=amount},
					function (cards)
						for _, cardItem in ipairs(cards) do
							table.remove(discardPile,table.indexOf(discardPile,cardItem.card))
							insertHand(cardItem)
							cardItem.card.tempRetain = true
						end
					end)
			end
		end),
		ChangeStanceAction:new(Calm),
	}
end

MentalFortress = PurpleCard:new{
	name='Mental Fortress',description='Whenever you change stances, gain !M! {Block}.',rarity='uncommon',type='power',baseCost=1,
	baseMagic=4,playerTarget=true,upgrade={baseMagic=6},
}
function MentalFortress:use()
	return { ApplyPowerAction:new(player,MentalFortressPower:new(player,self.magic)) }
end

MentalFortressPower = Power:new{icon=216,description='Whenever you change stances, gain #11#!A!#12# {Block}.'}
function MentalFortressPower:onEnterStance()
	addAction(GainBlockAction:new{target=player,value=self.amount})
end

Nirvana = PurpleCard:new{
	name='Nirvana',description='Whenever you scry, gain !M! {Block}.',rarity='uncommon',type='power',baseCost=1,
	baseMagic=3,playerTarget=true,upgrade={baseMagic=4},
}
function Nirvana:use()
	return { ApplyPowerAction:new(player,NirvanaPower:new(player,self.magic)) }
end

NirvanaPower = Power:new{icon=201,description='Whenever you scry, gain #11#!A!#12# {Block}.'}
function NirvanaPower:onScry()
	addAction(GainBlockAction:new{target=player,value=self.amount})
end

Perseverance = PurpleCard:new{
	name='Perseverance',description='Retain. NL Gain !B! {Block}. NL When retained, this card +!M! {Block} gain this combat.',
	rarity='uncommon',type='skill',baseCost=1,baseBlock=5,baseMagic=2,playerTarget=true,upgrade={baseBlock=7,baseMagic=3},retain=true,
}
function Perseverance:use()
	return { GainBlockAction:new{target=player,value=self.block} }
end

function Perseverance:onRetain(card)
	if card == self then
		self.baseBlock = self.baseBlock + self.magic
		self:applyPowers()
	end
end

Pray = PurpleCard:new{
	name='Pray',description='Gain !M! {MantraCard}. NL Shuffle an Insight into draw pile.',rarity='uncommon',type='skill',baseCost=1,
	baseMagic=3,playerTarget=true,upgrade={baseMagic=4},
}
function Pray:use()
	return {
		ApplyPowerAction:new(player,MantraPower:new(player,self.magic)),
		MakeTempCardToDrawPileAction:new(Insight:new())
	}
end

ReachHeaven = PurpleCard:new{
	name='Reach Heaven',description='{Damage} !D!. NL Shuffle a Through Violence into draw pile.',rarity='uncommon',
	baseCost=2,baseDamage=10,enemyTarget=true,playerTarget=true,upgrade={baseDamage=15},
}
function ReachHeaven:use(target)
	return {
		DamageAction:new{target=target,source=player,value=self.damage},
		MakeTempCardToDrawPileAction:new(ThroughViolence:new())
	}
end

Rushdown = PurpleCard:new{
	name='Rushdown',description='Whenever you enter Wrath, draw !M! cards.',rarity='uncommon',type='power',baseCost=1,
	baseMagic=2,playerTarget=true,upgrade={baseCost=0},
}
function Rushdown:use()
	return { ApplyPowerAction:new(player,RushdownPower:new(player,self.magic)) }
end

RushdownPower = Power:new{icon=202,description='Whenever you enter Wrath, draw #11#!A!#12# cards.'}
function RushdownPower:onEnterStance(stance)
	if stance == Wrath then
		addAction(DrawCardAction:new(self.amount))
	end
end

Sanctity = PurpleCard:new{
	name='Sanctity',description='Gain !B! {Block}. NL If the last card played this combat was a {Skill}, draw !M! cards.',
	rarity='uncommon',type='skill',baseCost=1,baseBlock=6,baseMagic=2,playerTarget=true,upgrade={baseBlock=9},
}
function Sanctity:use()
	local actions = { GainBlockAction:new{target=player,value=self.block} }
	local lastCardPlayed = WatcherEventListener.lastCardPlayed
	if lastCardPlayed and lastCardPlayed.type == 'skill' then
		table.insert(actions,DrawCardAction:new(self.magic))
	end
	return actions
end

function Sanctity:checkGlow()
	local lastCardPlayed = WatcherEventListener.lastCardPlayed
	if lastCardPlayed and lastCardPlayed.type == 'skill' then
		return 4
	end
end

SandsOfTime = PurpleCard:new{
	name='Sands of Time',description='Retain. NL {Damage} !D!. NL When retained, lower its cost by 1 this combat.',
	rarity='uncommon',baseCost=4,baseDamage=20,enemyTarget=true,upgrade={baseDamage=26},retain=true,
}
function SandsOfTime:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

function SandsOfTime:onRetain(card)
	if card == self then
		self:modifyBaseCost(-1)
		self:applyPowers()
	end
end

SignatureMove = PurpleCard:new{
	name='Signature Move',description='Can only be played if this is the only Attack in hand. NL {Damage} !D!.',
	rarity='uncommon',baseCost=2,baseDamage=30,enemyTarget=true,upgrade={baseDamage=40},
}
function SignatureMove:baseCanUse(free)
	return PurpleCard.baseCanUse(self,free) and
		table.allMatch(hand,function (cardItem) return cardItem.card.type ~= 'attack' or cardItem.card == self end)
end

function SignatureMove:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

function SignatureMove:checkGlow()
	if table.allMatch(hand,function (cardItem) return cardItem.card.type ~= 'attack' or cardItem.card == self end) then
		return 4
	end
end

SimmeringFury = PurpleCard:new{
	name='Simmering Fury',description='At the start of next turn, enter Wrath and draw !M! cards.',
	rarity='uncommon',type='skill',baseCost=1,baseMagic=2,playerTarget=true,upgrade={baseMagic=3},
}
function SimmeringFury:use()
	return {
		ApplyPowerAction:new(player,SimmeringFuryPower:new(player)),
		ApplyPowerAction:new(player,DrawCardNextTurnPower:new(player,self.magic)),
	}
end

SimmeringFuryPower = Power:new{icon=17,stackable=false,description='At the start of next turn, enter Wrath.'}
function SimmeringFuryPower:onTurnStart()
	addAction(ChangeStanceAction:new(Wrath))
	addAction(RemovePowerAction:new(self))
end

Study = PurpleCard:new{
	name='Study',description='At the end of turn, shuffle an Insight into draw pile.',rarity='uncommon',type='power',baseCost=2,
	playerTarget=true,upgrade={baseCost=1},
}
function Study:use()
	return { ApplyPowerAction:new(player,StudyPower:new(player,1)) }
end

StudyPower = Power:new{icon=icons.DrawCardEveryTurn,description='At the end of turn, shuffle #11#!A!#12# Insight{s} into draw pile.'}
function StudyPower:onTurnEnd()
	addAction(MakeTempCardToDrawPileAction:new(Insight:new(),self.amount))
end

Swivel = PurpleCard:new{
	name='Swivel',description='Gain !B! {Block}. NL The next {Attack} you play costs 0.',rarity='uncommon',type='skill',baseCost=2,
	baseBlock=8,playerTarget=true,upgrade={baseBlock=11},
}
function Swivel:use()
	return {
		GainBlockAction:new{target=player,value=self.block},
		ApplyPowerAction:new(player,SwivelPower:new(player,1))
	}
end

SwivelPower = Power:new{icon=199,description='The next #11#!A!#12# {Attack} you play cost{!s} 0.'}
function SwivelPower:modifyCost(cost,card)
	if card.type == 'attack' then
		return 0
	end
end

function SwivelPower:onUseCard(card)
	if card.type == 'attack' then
		addAction(ReducePowerAction:new(self,1))
	end
end

TalkToTheHand = PurpleCard:new{
	name='Talk to the Hand',description='{Damage} !D!. NL Whenever you attack this enemy, gain !M! {Block}. NL Exhaust.',rarity='uncommon',
	baseCost=1,baseDamage=5,baseMagic=2,enemyTarget=true,upgrade={baseDamage=7,baseMagic=3},exhaust=true,
}
function TalkToTheHand:use(target)
	return {
		DamageAction:new{target=target,source=player,value=self.damage},
		ApplyPowerAction:new(target,TalkToTheHandPower:new(target,self.magic))
	}
end

TalkToTheHandPower = Power:new{icon=249,debuff=true,description='Whenever you attack this enemy, gain #11#!A!#12# {Block}.'}
function TalkToTheHandPower:onDamaged(value,source,type)
	if source == player and type == 'attack' then
		addAction(1,GainBlockAction:new{target=player,value=self.amount})
	end
end

Tantrum = PurpleCard:new{
	name='Tantrum',description='{Damage} !D!, !M! times. NL Enter Wrath. NL Shuffle this card into draw pile.',rarity='uncommon',
	baseCost=1,baseDamage=3,baseMagic=3,enemyTarget=true,playerTarget=true,upgrade={baseDamage=3,baseMagic=4,displayAttackCount=4},
	toDrawPileOnPlay=true,displayAttackCount=3,
}
function Tantrum:use(target)
	local actions = {}
	for i = 1, self.magic do
		table.insert(actions,DamageAction:new{target=target,source=player,value=self.damage})
	end
	table.insert(actions,ChangeStanceAction:new(Wrath))
	return actions
end

Wallop = PurpleCard:new{
	name='Wallop',description='{Damage} !D!. NL Gain {Block} equal to unblocked damage dealt.',rarity='uncommon',
	baseCost=2,baseDamage=9,enemyTarget=true,playerTarget=true,upgrade={baseDamage=12},
}
function Wallop:use(target)
	return {
		DamageAction:new{target=target,source=player,value=self.damage,callback=function(action)
			if action.damageDealt > 0 then
				addAction(1,GainBlockAction:new{target=player,value=action.damageDealt})
			end
		end},
	}
end

WaveOfTheHand = PurpleCard:new{
	name='Wave of the Hand',description='Whenever you gain {Block} this turn, apply !M! {Weak} to all enemies.',rarity='uncommon',
	type='skill',baseCost=1,baseMagic=1,playerTarget=true,upgrade={baseMagic=2},
}
function WaveOfTheHand:use()
	return { ApplyPowerAction:new(player,WaveOfTheHandPower:new(player,self.magic)) }
end

WaveOfTheHandPower = Power:new{icon=233,description='Whenever you gain {Block} this turn, apply #11#!A!#12# {Weak} to all enemies.'}
function WaveOfTheHandPower:onGainBlock(value)
	if value <= 0 then
		return
	end
	for _, enemy in ipairs(enemies) do
		addAction(ApplyPowerAction:new(self.owner,WeakPower:new(enemy,self.amount)))
	end
end

function WaveOfTheHandPower:onRoundEnd()
	addAction(RemovePowerAction:new(self))
end

Weave = PurpleCard:new{
	name='Weave',description='{Damage} !D!. NL Whenever you scry, return this from discard pile to hand.',rarity='uncommon',baseCost=0,
	baseDamage=4,enemyTarget=true,upgrade={baseDamage=6},
}
function Weave:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

function Weave:onScried()
	if table.anyMatch(discardPile,function (card) return card == self end) then
		addAction(AnonymousAction:new(function ()
			table.remove(discardPile,table.indexOf(discardPile,self))
			insertHand(CardItem:new{card=self,x=240,y=136})
		end))
	end
end

WheelKick = PurpleCard:new{
	name='Wheel Kick',description='{Damage} !D!. NL Draw !M! cards.',rarity='uncommon',baseCost=2,baseDamage=15,
	baseMagic=2,enemyTarget=true,playerTarget=true,upgrade={baseDamage=20},
}
function WheelKick:use(target)
	return {
		DamageAction:new{target=target,source=player,value=self.damage},
		DrawCardAction:new(self.magic)
	}
end

WindmillStrike = PurpleCard:new{
	name='Windmill Strike',description='Retain. NL {Damage} !D!. NL When retained, this card +!M! damage this combat.',rarity='uncommon',
	baseCost=2,baseDamage=7,baseMagic=4,enemyTarget=true,upgrade={baseDamage=10,baseMagic=5},retain=true,tags={'strike'},
}
function WindmillStrike:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

function WindmillStrike:onRetain(card)
	if card == self then
		self.baseDamage = self.baseDamage + self.magic
		self:applyPowers()
	end
end

Worship = PurpleCard:new{
	name='Worship',description='Gain !M! {MantraCard}.',rarity='uncommon',type='skill',baseCost=2,
	baseMagic=5,playerTarget=true,upgrade={description='Retain. NL Gain !M! {MantraCard}.',retain=true},
}
function Worship:use()
	return { ApplyPowerAction:new(player,MantraPower:new(player,self.magic)) }
end

WreathOfFlame = PurpleCard:new{
	name='Wreath of Flame',description='Your next {Attack} deals !M! additional damage.',rarity='uncommon',type='skill',baseCost=1,
	baseMagic=5,playerTarget=true,upgrade={baseMagic=8},
}
function WreathOfFlame:use()
	return { ApplyPowerAction:new(player,VigorPower:new(player,self.magic)) }
end

Alpha = PurpleCard:new{
	name='Alpha',description='Shuffle a Beta into your draw pile. NL Exhaust.',rarity='rare',type='skill',baseCost=1,
	playerTarget=true,upgrade={description='Innate. NL Shuffle a Beta into your draw pile. NL Exhaust.',innate=true},exhaust=true,
}
function Alpha:use()
	return { MakeTempCardToDrawPileAction:new(Beta:new()) }
end

Blasphemy = PurpleCard:new{
	name='Blasphemy',description='Enter Divinity. NL Die next turn. NL Exhaust.',rarity='rare',type='skill',baseCost=1,
	playerTarget=true,upgrade={description='Retain. NL Enter Divinity. NL Die next turn. NL Exhaust.',retain=true},exhaust=true,
}
function Blasphemy:use()
	return {
		ChangeStanceAction:new(Divinity),
		ApplyPowerAction:new(player,BlasphemyPower:new(player))
	}
end

BlasphemyPower = Power:new{icon=212,stackable=false,description='At the start of turn, die.'}
function BlasphemyPower:onTurnStart()
	addAction(DamageAction:new{target=self.owner,source=self.owner,value=114514,type='hpLoss'})
	addAction(RemovePowerAction:new(self))
end

Brilliance = PurpleCard:new{
	name='Brilliance',description='{Damage} !D!. NL Deals additional damage equal to {MantraCard} gained this combat.',rarity='rare',
	baseCost=1,baseDamage=12,enemyTarget=true,upgrade={baseDamage=16},
}
function Brilliance:applyPowers(target)
	self.baseDamage = self.baseDamage + WatcherEventListener.mantraGainThisCombat
	PurpleCard.applyPowers(self,target)
	self.baseDamage = self.baseDamage - WatcherEventListener.mantraGainThisCombat
end

function Brilliance:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

ConjureBlade = PurpleCard:new{
	name='Conjure Blade',description='Shuffle an Expunger into draw pile. NL Exhaust.',rarity='rare',type='skill',baseCost=-1,
	playerTarget=true,upgrade={description='Shuffle an Expunger with X+1 into draw pile. NL Exhaust.'},exhaust=true,
}
function ConjureBlade:use()
	local upgraded = self.upgraded
	return {
		XCardAction:new(function (amount)
			if upgraded then
				amount = amount + 1
			end
			return { MakeTempCardToDrawPileAction:new(Expunger:new(amount)) }
		end,energyOnUse,free)
	}
end

DeusExMachina = PurpleCard:new{
	name='Deus Ex Machina',description='Unplayable. NL When you draw this card, add !M! Miracles to hand and Exhaust.',rarity='rare',
	type='skill',baseCost=-2,baseMagic=2,upgrade={baseMagic=3},baseCanUse=false,
}
function DeusExMachina:onDraw(card)
	if card == self then
		addAction(1,AnonymousAction:new(function ()
			local cardIndex = nil
			for j,cardItem in ipairs(hand) do
				if cardItem.card == card then
					cardIndex = j
					break
				end
			end
			if cardIndex then
				addAction(1,ExhaustCardAction:new{cardItem=hand[cardIndex],show=true})
				removeHand(cardIndex)
			end
		end))
		addAction(2,MakeTempCardToHandAction:new(Miracle:new(),self.magic))
	end
end

DevaForm = PurpleCard:new{
	name='Deva Form',description='Ethereal. NL At the start of turn, gain {Energy} and increase this gain by !M!.',rarity='rare',
	type='power',baseCost=3,baseMagic=1,playerTarget=true,ethereal=true,
	upgrade={description='At the start of turn, gain {Energy} and increase this gain by !M!.',ethereal=false},
}
function DevaForm:use()
	return { ApplyPowerAction:new(player,DevaFormPower:new(player,self.magic)) }
end

DevaFormPower = Power:new{icon=197,energy=1,description='At the start of turn, gain #11#!energy!#12# {Energy} and increase this by #11#!A!#12#.'}
function DevaFormPower:stackPower(power)
	self.energy = self.energy + power.energy
	Power.stackPower(self,power)
end

function DevaFormPower:onTurnStart()
	addAction(GainEnergyAction:new(self.energy))
	self.energy = self.energy + self.amount
end

Devotion = PurpleCard:new{
	name='Devotion',description='At the start of turn, gain !M! {MantraCard}.',rarity='rare',type='power',baseCost=1,
	baseMagic=2,playerTarget=true,upgrade={baseMagic=3},
}
function Devotion:use()
	return { ApplyPowerAction:new(player,DevotionPower:new(player,self.magic)) }
end

DevotionPower = Power:new{icon=213,description='At the start of turn, gain #11#!A!#12# {Mantra}.'}
function DevotionPower:onTurnStart()
	addAction(ApplyPowerAction:new(self.owner,MantraPower:new(self.owner,self.amount)))
end

Establishment = PurpleCard:new{
	name='Establishment',description='Whenever a card is re- tained, reduce its cost by 1 this combat.',rarity='rare',type='power',
	baseCost=1,playerTarget=true,upgrade={description='Innate. NL Whenever a card is re- tained, reduce its cost by 1 this combat.',innate=true},
}
function Establishment:use()
	return { ApplyPowerAction:new(player,EstablishmentPower:new(player,1)) }
end

EstablishmentPower = Power:new{icon=198,description='Whenever a card is retained, reduce its cost by #11#!A!#12# this combat.'}
function EstablishmentPower:onRetain(card)
	card:modifyBaseCost(-self.amount)
	card:applyPowers()
end

Judgement = PurpleCard:new{
	name='Judgement',description='If the enemy has !M! or less HP, set their NL HP to 0.',rarity='rare',type='skill',baseCost=1,
	baseMagic=30,enemyTarget=true,upgrade={baseMagic=40},
}
function Judgement:use(target)
	local magic = self.magic
	return {
		EffectAction:new(TextEffect:new{x=target.x+target.width*4,y=target.y,text='JUDGED',scale=2,color=4,ySpeed=-0.5}),
		AnonymousAction:new(function ()
			if not target.canInteract then
				return
			end
			if target.hp <= magic then
				target.hp = 0
				target:die()
			end
		end)
	}
end

LessonLearned = PurpleCard:new{
	name='Lesson Learned',description='{Damage} !D!. NL If Fatal, upgrade a random card in deck. NL Exhaust.',rarity='rare',baseCost=2,
	baseDamage=10,enemyTarget=true,exhaust=true,upgrade={baseDamage=13},
}
function LessonLearned:use(target)
	local damageAction = DamageAction:new{source=player,target=target,value=self.damage}
	return {
		damageAction,
		FatalAction:new{target=target,action=damageAction,callback=function ()
			local cards = shallowcopy(deck)
			table.retainIf(cards,function(c) return c:canUpgrade() end)
			if #cards > 0 then
				local card = cards[miscRand:randInt(#cards)]
				upgradeCardsWithEffect({CardItem:new{card=card,x=240,y=0,isNotInHand=true}})
			end
		end}
	}
end

MasterReality = PurpleCard:new{
	name='Master Reality',description='Whenever a card is created during combat, upgrade it.',rarity='rare',type='power',baseCost=1,
	playerTarget=true,upgrade={baseCost=0},
}
function MasterReality:use()
	return { ApplyPowerAction:new(player,MasterRealityPower:new(player)) }
end

MasterRealityPower = Power:new{icon=200,stackable=false,description='Whenever a card is created during combat, upgrade it.'}
function MasterRealityPower:onTempCardMade(card)
	if card:canUpgrade() then
		card:upgrade()
	end
end

Omniscience = PurpleCard:new{
	name='Omniscience',description='Choose a card in draw pile. NL Play the chosen card twice and exhaust it. NL Exhaust.',rarity='rare',
	type='skill',baseCost=4,playerTarget=true,upgrade={baseCost=3},exhaust=true,
}
function Omniscience:use()
	return {
		AnonymousAction:new(function()
			local cardItems = {}
			for i, card in ipairs(drawPile) do
				cardItems[i] = CardItem:new{card=card,x=0,y=136,tx=240,ty=136,isNotInHand=true}
			end
			if #cardItems == 0 then
				return
			elseif #cardItems == 1 then
				self:playCardTwice(cardItem[1])
			else
				table.sort(cardItems,function (a, b) return a.card.name < b.card.name end)
				openWindowAbove(CardGridSelectWindow:new{cardItems=cardItems,title='Choose a Card to play.',max=1},
					function (cards)
						for _, cardItem in ipairs(cards) do
							self:playCardTwice(cardItem)
						end
					end)
			end
		end)
	}
end

function Omniscience:playCardTwice(cardItem)
	table.remove(drawPile,table.indexOf(drawPile,cardItem.card))
	cardItem.large = false
	local action = UseCardAction:new{cardItem=cardItem,isDoubleTap=false,randomTarget=true,exhaust=true,free=true,target=target,energyOnUse=energy}
	action.useCardPosition = fillCardPosition(cardItem,2)
	table.insert(limbo,cardItem)
	addAction(1,action)
	cardItem = cardItem:copy()
	action = UseCardAction:new{cardItem=cardItem,isDoubleTap=true,temp=true,randomTarget=true,exhaust=true,free=true,target=target,energyOnUse=energy}
	action.useCardPosition = fillCardPosition(cardItem,2)
	table.insert(limbo,cardItem)
	addAction(2,action)
end

Ragnarok = PurpleCard:new{
	name='Ragnarok',description='{Damage} !D! to a random enemy !M! times.',rarity='rare',baseCost=3,baseDamage=5,baseMagic=5,enemyTarget=true,
	toAllEnemies=true,upgrade={baseDamage=6,baseMagic=6,displayAttackCount=6},displayAttackCount=5,
}
function Ragnarok:use(target)
	local actions = {}
	for i = 1, self.magic do
		actions[i] = DamageRandomEnemyAction:new{target=target,source=player,value=self.damage}
	end
	return actions
end

Scrawl = PurpleCard:new{
	name='Scrawl',description='Draw cards until hand is full. NL Exhaust.',rarity='rare',type='skill',baseCost=1,playerTarget=true,
	upgrade={baseCost=0},exhaust=true,
}
function Scrawl:use()
	return { DrawCardAction:new(HAND_LIMIT) }
end

SpiritShield = PurpleCard:new{
	name='Spirit Shield',description='Gain !M! {Block} for each card in hand.',rarity='rare',type='skill',baseCost=2,playerTarget=true,
	baseMagic=3,upgrade={baseMagic=4},
}
function SpiritShield:applyPowers(target)
	self.baseBlock = table.count(hand,function (cardItem) return cardItem.card ~= self end) * self.baseMagic
	self.description = 'Gain !M! {Block} for each card in hand. NL (!B! {Block})'
	BlueCard.applyPowers(self,target)
end

function SpiritShield:resetPowers()
	self.description = 'Gain !M! {Block} for each card in hand.'
	BlueCard.resetPowers(self)
end

function SpiritShield:use()
	return { GainBlockAction:new{target=player,value=self.block} }
end

Vault = PurpleCard:new{
	name='Vault',description='Take an extra turn after this one. NL End your turn. NL Exhaust.',rarity='rare',type='skill',baseCost=3,
	playerTarget=true,upgrade={baseCost=2},exhaust=true,
}
function Vault:use()
	addAction(EndTurnAction:new{skipEnemyTurn=true})
	return {}
end

Wish = PurpleCard:new{
	name='Wish',description='Choose one: NL Gain !B! {62}, !D! {Strength}, or !M! Gold. NL Exhaust.',rarity='rare',type='skill',
	baseCost=3,playerTarget=true,baseBlock=6,baseDamage=3,baseMagic=25,upgrade={baseBlock=8,baseDamage=4,baseMagic=30},exhaust=true,
}
function Wish:applyPowers()
	PurpleCard.applyPowers(self)
	self.block = self.baseBlock
	self.damage = self.baseDamage
	self.magic = self.baseMagic
end

function Wish:use()
	local block,damage,magic = self.block,self.damage,self.magic
	return { AnonymousAction:new(function ()
		local liveForever = ColorlessCard:new{name='Live Forever',description='Gain '..block..' {62}.',rarity='special',type='power',baseCost=-2}
		local becomeAlmighty = ColorlessCard:new{name='Become Almighty',description='Gain '..damage..' {Strength}.',rarity='special',type='power',baseCost=-2}
		local fameAndFortune = ColorlessCard:new{name='Fame and Fortune',description='Gain '..magic..' Gold.',rarity='special',type='skill',baseCost=-2}
		openWindowAbove(CardRewardWindow:new{cards={becomeAlmighty,fameAndFortune,liveForever},title='Choose One',canClose=false},
			function (cardItem)
				if cardItem.card == liveForever then
					addAction(1,ApplyPowerAction:new(player,PlatedArmorPower:new(player,block)))
				elseif cardItem.card == becomeAlmighty then
					addAction(1,ApplyPowerAction:new(player,StrengthPower:new(player,damage)))
				else
					addAction(1,AnonymousAction:new(function ()
						gainGold(magic)
					end))
				end
			end)
	end) }
end

purpleCards = {
	StrikePurple,DefendPurple,Eruption,Vigilance,BowlingBash,Consecrate,Crescendo,CrushJoints,CutThroughFate,EmptyBody,
	EmptyFist,Evaluate,FlurryOfBlows,FlyingSleeves,FollowUp,Halt,JustLucky,PressurePoints,Prostrate,Protect,SashWhip,
	ThirdEye,Tranquility,BattleHymn,CarveReality,Collect,Conclude,DeceiveReality,EmptyMind,Fasting,FearNoEvil,ForeignInfluence,
	Foresight,Indignation,InnerPeace,LikeWater,Meditate,MentalFortress,Nirvana,Perseverance,Pray,ReachHeaven,Rushdown,
	Sanctity,SandsOfTime,SignatureMove,SimmeringFury,Study,Swivel,TalkToTheHand,Tantrum,Wallop,WaveOfTheHand,Weave,WheelKick,
	WindmillStrike,Worship,WreathOfFlame,Alpha,Blasphemy,Brilliance,ConjureBlade,DeusExMachina,DevaForm,Devotion,Establishment,
	Judgement,LessonLearned,MasterReality,Omniscience,Ragnarok,Scrawl,SpiritShield,Vault,Wish,
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

GoldenEye = PurpleRelic:new{ name='Golden Eye',tier='rare',icon=245,description='Whenever you scry, Scry #11#2#12# additional cards.' }
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
				addAction(1,ChangeStanceAction:new(Calm))
			else
				addAction(1,ChangeStanceAction:new(Wrath))
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
