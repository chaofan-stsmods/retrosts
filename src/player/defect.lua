---@diagnostic disable: lowercase-global

local blueCards

DefectEventListener = { frostChanneled=0,lightningChanneled=0,cardsPlayedThisTurn=0 }
function DefectEventListener:onCombatStart()
	self.frostChanneled = 0
	self.lightningChanneled = 0
end

function DefectEventListener:onTurnStart()
	self.cardsPlayedThisTurn = 0
end

function DefectEventListener:onChannel(orb)
	if getmetatable(orb) == Frost then
		self.frostChanneled = self.frostChanneled + 1
	elseif getmetatable(orb) == Lightning then
		self.lightningChanneled = self.lightningChanneled + 1
	end
end

function DefectEventListener:onUseCard(card)
	self.cardsPlayedThisTurn = self.cardsPlayedThisTurn + 1
end

table.insert(playerEventListeners,DefectEventListener)

Defect = Player:new{ maxHp=75,width=6,height=4,tileBank=3,name='Defect',maxOrbs=3 }
function Defect:drawImage()
	if self.flipped then
		map(14,9,4,4,self.x+8,self.y,0,1,flipRemap(14,4))
	else
		map(14,9,4,4,self.x+8,self.y,0)
	end
end

function Defect:drawCorpse()
	map(14,13,7,3,self.x-4,self.y+14,0)
end

function Defect:getStartDeck()
	local deck = {}
	table.insert(deck,StrikeBlue:new())
	table.insert(deck,StrikeBlue:new())
	table.insert(deck,StrikeBlue:new())
	table.insert(deck,StrikeBlue:new())
	table.insert(deck,DefendBlue:new())
	table.insert(deck,DefendBlue:new())
	table.insert(deck,DefendBlue:new())
	table.insert(deck,DefendBlue:new())
	table.insert(deck,Zap:new())
	table.insert(deck,Dualcast:new())
	return deck
end

function Defect:getCards()
	return blueCards
end

function Defect:getStartRelics()
	return { CrackedCore:new() }
end

function Defect:getAscensionMaxHPLoss()
	return 4
end

function Defect:getMatchAndKeepCardType()
	return Zap
end

function Defect:getRelics()
	return {
		CrackedCore,
		DataDisk,
		GoldPlatedCables,SymbioticVirus,
		EmotionChip,
		FrozenCore,Inserter,NuclearBattery,
		RunicCapacitor,
	}
end

function Defect:getPotions()
	return { FocusPotion,PotionOfCapacity,EssenceOfDarkness }
end

function Defect:getPronouns()
	return {vampires='broken one'}
end

function Defect:getSpireHeartText()
	return 'NL You charge your core to its maximum...'
end

function Defect:getEnding()
	return DefectEnding:new()
end

-- orbs

Orb = Object:new{
	owner=nil,x=0,y=0,tx=0,ty=0,icon=nil,evoking=false,showEvokeValue=false,
	applyPowers=noop,drawNumbers=noop,onEvoke=noop,
}
function Orb:new(o)
	local r = Object.new(self,o)
	if r.owner ~= nil then
		r.x = r.owner.x + r.owner.width*4
		r.y = r.owner.y + r.owner.height*4
	end
	return r
end

function Orb:tick()
	drawIcon(self.icon,self.x-4,self.y-4)
	self:drawNumbers()
	self.x = lerp(self.x,self.tx,0.2)
	self.y = lerp(self.y,self.ty,0.2)
end

function Orb:getFocusAmount()
	local focus = self.owner:getPower(FocusPower)
	return focus and focus.amount or 0
end

function Orb:resetPosition()
	self.x = self.owner.x + self.owner.width*4
	self.y = self.owner.y + self.owner.height*4
end

function Orb:drawTooltips()
	drawItemTooltip(self,self.x+7,self.y-7)
end

OrbSlot = Orb:new{icon=icons.OrbSlot,description='Orbs can be channeled into these slots.'}

Lightning = Orb:new{
	icon=icons.Lightning,value=3,evokeValue=8,
	description='Passive: At the end of turn, {Damage} #11#!value!#12# to a random enemy. NL Evoke: {Damage} #11#!evokeValue!#12# to a random enemy.'
}
function Lightning:applyPowers()
	self.value = math.max(0,3+self:getFocusAmount())
	self.evokeValue = math.max(0,8+self:getFocusAmount())
end

function Lightning:drawNumbers()
	local showEvoke = self.evoking or self.showEvokeValue
	local text = showEvoke and tostring(self.evokeValue) or tostring(self.value)
	printGlowed(text,self.x+4-strWidth(text,false,true)/2,self.y,showEvoke and 10 or 12,15,1,true)
end

function Lightning.modifyOrbDamage(damage,target)
	return target:triggerReducerEvent('onHitByOrb',damage)
end

function Lightning:onEvoke()
	return self:damage(self.evokeValue)
end

function Lightning:onPassive(noEvent)
	if not noEvent then
		player:triggerEvent('onOrbPassive',self)
	end
	return self:damage(self.value)
end

function Lightning:damage(value)
	if self.owner:getPower(ElectrodynamicsPower) then
		return { DamageAllEnemiesAction:new{source=self.owner,value=value,type='power',onModifyDamage=self.modifyOrbDamage} }
	else
		return { DamageRandomEnemyAction:new{source=self.owner,value=value,type='power',onModifyDamage=self.modifyOrbDamage} }
	end
end

function Lightning:onTurnEnd()
	for _,action in ipairs(self:onPassive()) do
		addAction(action)
	end
end

Frost = Orb:new{
	icon=icons.Frost,value=2,evokeValue=5,
	description='Passive: At the end of turn, gain #11#!value!#12# {Block}. NL Evoke: Gain #11#!evokeValue!#12# {Block}.'
}
function Frost:applyPowers()
	self.value = math.max(0,2+self:getFocusAmount())
	self.evokeValue = math.max(0,5+self:getFocusAmount())
end

function Frost:drawNumbers()
	local showEvoke = self.evoking or self.showEvokeValue
	local text = showEvoke and tostring(self.evokeValue) or tostring(self.value)
	printGlowed(text,self.x+4-strWidth(text,false,true)/2,self.y,showEvoke and 10 or 12,15,1,true)
end

function Frost:onEvoke()
	return { GainBlockAction:new{target=self.owner,value=self.evokeValue} }
end

function Frost:onPassive(noEvent)
	if not noEvent then
		player:triggerEvent('onOrbPassive',self)
	end
	return { GainBlockAction:new{target=self.owner,value=self.value} }
end

function Frost:onTurnEnd()
	for _,action in ipairs(self:onPassive()) do
		addAction(action)
	end
end

Dark = Orb:new{
	icon=icons.Dark,value=6,evokeValue=6,
	description='Passive: At the end of turn, increase this orb\'s damage by #11#!value!#12#. NL Evoke: {Damage} #11#!evokeValue!#12# to the enemy with lowest HP.'
}
function Dark:applyPowers()
	self.value = math.max(0,6+self:getFocusAmount())
end

function Dark:drawNumbers()
	local text = tostring(self.evokeValue)
	printGlowed(text,self.x+4-strWidth(text,false,true)/2,self.y,10,15,1,true)
	text = tostring(self.value)
	printGlowed(text,self.x+4-strWidth(text,false,true)/2,self.y-6,12,15,1,true)
end

function Dark:onEvoke()
	local evokeValue = self.evokeValue
	return {
		AnonymousAction:new(function ()
			local target = nil
			for _,enemy in ipairs(enemies) do
				if enemy.canInteract and (target == nil or enemy.hp < target.hp) then
					target = enemy
				end
			end
			if target ~= nil then
				local damage = target:triggerReducerEvent('onHitByOrb',evokeValue)
				addAction(1,DamageAction:new{source=self.owner,target=target,value=damage,type='power'})
			end
		end)
	}
end

function Dark:onPassive(noEvent)
	if not noEvent then
		player:triggerEvent('onOrbPassive',self)
	end
	local value = self.value
	return { AnonymousAction:new(function () self.evokeValue = self.evokeValue + value end) }
end

function Dark:onTurnEnd()
	for _,action in ipairs(self:onPassive()) do
		addAction(action)
	end
end

Plasma = Orb:new{
	icon=icons.Plasma,value=1,evokeValue=2,
	description='Passive: At the start of turn, gain {Energy}. NL Evoke: Gain {Energy}{Energy}. NL {Plasma} is unaffected by {Focus}.'
}
function Plasma:drawNumbers()
	if self.evoking or self.showEvokeValue then
		local text = tostring(self.evokeValue)
		printGlowed(text,self.x+4-strWidth(text,false,true)/2,self.y,10,15,1,true)
	end
end

function Plasma:onEvoke()
	return { GainEnergyAction:new(self.evokeValue) }
end

function Plasma:onPassive(noEvent)
	if not noEvent then
		player:triggerEvent('onOrbPassive',self)
	end
	return { GainEnergyAction:new(self.value) }
end

function Plasma:onTurnStart()
	for _,action in ipairs(self:onPassive()) do
		addAction(action)
	end
end

local orbTypes = {Lightning,Frost,Dark,Plasma}

-- cards

BlueCard = Card:new{color={9,15},typeIconColor=11,colorName='blue'}

StrikeBlue = BlueCard:new{ name='Strike',description='{Damage} !D!.',rarity='basic',baseCost=1,baseDamage=6,enemyTarget=true,upgrade={baseDamage=9},tags={'strike','basicStrike'} }
function StrikeBlue:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

DefendBlue = BlueCard:new{ name='Defend',description='Gain !B! {Block}.',rarity='basic',type='skill',baseCost=1,baseBlock=5,playerTarget=true,upgrade={baseBlock=8},tags={'basicDefend'} }
function DefendBlue:use()
	return { GainBlockAction:new{target=player,value=self.block} }
end

Zap = BlueCard:new{ name='Zap',description='Channel 1 {Lightning}.',rarity='basic',type='skill',baseCost=1,playerTarget=true,channelCount=1,upgrade={baseCost=0} }
function Zap:use()
	return { ChannelAction:new(Lightning:new{owner=player}) }
end

Dualcast = BlueCard:new{ name='Dualcast',description='Evoke your next Orb twice.',rarity='basic',type='skill',baseCost=1,playerTarget=true,evokeCount=1,upgrade={baseCost=0} }
function Dualcast:use()
	return { EvokeAction:new{amount=2} }
end

BallLightning = BlueCard:new{
	name='Ball Lightning',description='{Damage} !D!. NL Channel 1 {Lightning}.',rarity='common',baseCost=1,baseDamage=7,
	enemyTarget=true,playerTarget=true,upgrade={baseDamage=10},channelCount=1,
}
function BallLightning:use(target)
	return {
		DamageAction:new{target=target,source=player,value=self.damage},
		ChannelAction:new(Lightning:new{owner=player})
	}
end

Barrage = BlueCard:new{
	name='Barrage',description='{Damage} !D! for each Channeled Orb.',rarity='common',baseCost=1,baseDamage=4,
	enemyTarget=true,upgrade={baseDamage=6},displayAttackCount='?',
}
function Barrage:applyPowers(target)
	self.displayAttackCount = table.count(player.orbs,function (orb) return getmetatable(orb) ~= OrbSlot end)
	BlueCard.applyPowers(self,target)
end

function Barrage:resetPowers()
	self.displayAttackCount = '?'
	BlueCard.resetPowers(self)
end

function Barrage:use(target)
	local actions = {}
	for _,orb in ipairs(player.orbs) do
		if getmetatable(orb) ~= OrbSlot then
			table.insert(actions,DamageAction:new{target=target,source=player,value=self.damage})
		end
	end
	return actions
end

BeamCell = BlueCard:new{
	name='Beam Cell',description='{Damage} !D!. NL Apply !M! {Vulnerable}.',rarity='common',baseCost=0,baseDamage=3,baseMagic=1,
	enemyTarget=true,upgrade={baseDamage=4,baseMagic=2},
}
function BeamCell:use(target)
	return {
		DamageAction:new{target=target,source=player,value=self.damage},
		ApplyPowerAction:new(player,VulnerablePower:new(target,self.magic)),
	}
end

ChargeBattery = BlueCard:new{
	name='Charge Battery',description='Gain !B! {Block}. NL Next turn, gain {Energy}.',rarity='common',type='skill',baseCost=1,baseBlock=7,
	playerTarget=true,upgrade={baseBlock=10},
}
function ChargeBattery:use()
	return {
		GainBlockAction:new{target=player,value=self.block},
		ApplyPowerAction:new(player,EnergizedPower:new(player,1)),
	}
end

Claw = BlueCard:new{
	name='Claw',description='{Damage} !D!. NL Claw cards +!M! damage this combat.',rarity='common',baseCost=0,baseDamage=3,baseMagic=2,
	enemyTarget=true,upgrade={baseDamage=5,baseMagic=2},
}
function Claw:use(target)
	local damageIncrease = self.magic
	return {
		DamageAction:new{target=target,source=player,value=self.damage},
		AnonymousAction:new(function ()
			local selfUpdated = false
			for _,card in ipairs(discardPile) do
				if getmetatable(card) == Claw then
					card.baseDamage = card.baseDamage + damageIncrease
					card:resetPowers()
					selfUpdated = selfUpdated or card == self
				end
			end
			for _,card in ipairs(drawPile) do
				if getmetatable(card) == Claw then
					card.baseDamage = card.baseDamage + damageIncrease
					card:resetPowers()
					selfUpdated = selfUpdated or card == self
				end
			end
			for _,cardItem in ipairs(hand) do
				if getmetatable(cardItem.card) == Claw then
					cardItem.card.baseDamage = cardItem.card.baseDamage + damageIncrease
					cardItem.card:applyPowers()
					selfUpdated = selfUpdated or cardItem.card == self
				end
			end
			if not selfUpdated then
				self.baseDamage = self.baseDamage + damageIncrease
			end
		end)
	}
end

ColdSnap = BlueCard:new{
	name='Cold Snap',description='{Damage} !D!. NL Channel 1 {Frost}.',rarity='common',baseCost=1,baseDamage=6,
	enemyTarget=true,playerTarget=true,upgrade={baseDamage=9},channelCount=1,
}
function ColdSnap:use(target)
	return {
		DamageAction:new{target=target,source=player,value=self.damage},
		ChannelAction:new(Frost:new{owner=player}),
	}
end

CompileDriver = BlueCard:new{
	name='Compile Driver',description='{Damage} !D!. NL Draw 1 card for each unique Orb you have.',rarity='common',baseCost=1,baseDamage=7,
	enemyTarget=true,playerTarget=true,upgrade={baseDamage=10},
}
function CompileDriver:use(target)
	return {
		DamageAction:new{target=target,source=player,value=self.damage},
		AnonymousAction:new(function ()
			local uniqueOrbs = {}
			local count = 0
			for _,orb in ipairs(player.orbs) do
				local orbType = getmetatable(orb)
				if orbType ~= OrbSlot and uniqueOrbs[orbType] == nil then
					uniqueOrbs[orbType] = true
					count = count + 1
				end
			end
			if count > 0 then
				addAction(1,DrawCardAction:new(count))
			end
		end),
	}
end

Coolheaded = BlueCard:new{
	name='Coolheaded',description='Channel 1 {Frost}. NL Draw !M! card.',rarity='common',type='skill',baseCost=1,baseMagic=1,
	playerTarget=true,upgrade={baseMagic=2,description='Channel 1 {Frost}. NL Draw !M! cards.'},channelCount=1,
}
function Coolheaded:use()
	return {
		ChannelAction:new(Frost:new{owner=player}),
		DrawCardAction:new(self.magic),
	}
end

GoForTheEyes = BlueCard:new{
	name='Go for the Eyes',description='{Damage} !D!. NL If the enemy intends to attack, apply !M! {Weak}.',rarity='common',baseCost=0,
	baseDamage=3,baseMagic=1,enemyTarget=true,upgrade={baseDamage=4,baseMagic=2},
}
function GoForTheEyes:use(target)
	return {
		DamageAction:new{target=target,source=player,value=self.damage},
		AnonymousAction:new(function ()
			if target.intentType:sub(1,6) == 'attack' then
				addAction(ApplyPowerAction:new(target,WeakPower:new(target,self.magic)))
			end
		end),
	}
end

function GoForTheEyes:checkGlow()
	if table.anyMatch(enemies,function (enemy) return enemy.canInteract and enemy.intentType:sub(1,6) == 'attack' end) then
		return 4
	end
end

Hologram = BlueCard:new{
	name='Hologram',description='Gain !B! {Block}. NL Put a card from discard pile into hand. NL Exhaust.',rarity='common',
	type='skill',baseCost=1,baseBlock=3,playerTarget=true,exhaust=true,
	upgrade={baseBlock=5,exhaust=false,description='Gain !B! {Block}. NL Put a card from discard pile into hand.'},
}
function Hologram:use()
	return {
		GainBlockAction:new{target=player,value=self.block},
		AnonymousAction:new(function ()
			local cardItems = {}
			for i, card in ipairs(discardPile) do
				cardItems[i] = CardItem:new{card=card,x=240,y=136,tx=240,ty=136,isNotInHand=true}
			end
			if #cardItems == 0 then
				return
			elseif #cardItems == 1 then
				local cardItem = cardItems[1]
				table.remove(discardPile,table.indexOf(discardPile,cardItem.card))
				insertHand(cardItem)
			else
				openWindowAbove(CardGridSelectWindow:new{cardItems=cardItems,title='Choose a Card to Put into Hand',max=1},
					function (cards)
						for _, cardItem in ipairs(cards) do
							table.remove(discardPile,table.indexOf(discardPile,cardItem.card))
							insertHand(cardItem)
						end
					end)
			end
		end),
	}
end

Leap = BlueCard:new{
	name='Leap',description='Gain !B! {Block}.',rarity='common',type='skill',baseCost=1,baseBlock=9,
	playerTarget=true,upgrade={baseBlock=12},
}
function Leap:use()
	return { GainBlockAction:new{target=player,value=self.block} }
end

Rebound = BlueCard:new{
	name='Rebound',description='{Damage} !D!. NL Put the next card you play this turn on top of draw pile.',rarity='common',
	baseCost=1,baseDamage=9,enemyTarget=true,playerTarget=true,upgrade={baseDamage=12},
}
function Rebound:use(target)
	return {
		DamageAction:new{target=target,source=player,value=self.damage},
		ApplyPowerAction:new(player,ReboundPower:new(player,1)),
	}
end

ReboundPower = Power:new{icon=249,description='The next #11#!A!#12# card{s} you play this turn are placed on top of draw pile.'}
function ReboundPower:onUseCard(_,_,action)
	action.rebound = true
	addAction(1,ReducePowerAction:new(self,1))
end

function ReboundPower:onTurnEnd()
	addAction(RemovePowerAction:new(self))
end

Recursion = BlueCard:new{
	name='Recursion',description='Evoke your next Orb. NL Channel the Orb that was just Evoked.',rarity='common',type='skill',baseCost=1,
	playerTarget=true,evokeCount=1,upgrade={baseCost=0},
}
function Recursion:use()
	return { AnonymousAction:new(function ()
		local orb = player.orbs[1]
		if getmetatable(orb) == OrbSlot then
			return
		end
		addAction(1,EvokeAction:new{amount=1})
		orb = orb:copy()
		orb:resetPosition()
		addAction(2,ChannelAction:new(orb))
	end) }
end

Stack = BlueCard:new{
	name='Stack',description='Gain {Block} equal to the number of cards in discard pile.',rarity='common',type='skill',baseCost=1,
	playerTarget=true,upgrade={description='Gain {Block} equal to the number of cards in discard pile +3.'},
}
function Stack:applyPowers(target)
	self.baseBlock = #discardPile + (self.upgraded and 3 or 0)
	self.description = 'Gain {Block} equal to the number of cards in discard pile' .. (self.upgraded and ' +3' or '') .. '. NL (!B! {Block})'
	BlueCard.applyPowers(self,target)
end

function Stack:resetPowers()
	self.description = 'Gain {Block} equal to the number of cards in discard pile' .. (self.upgraded and ' +3' or '') .. '.'
	BlueCard.resetPowers(self)
end

function Stack:use()
	return { GainBlockAction:new{target=player,value=self.block} }
end

SteamBarrier = BlueCard:new{
	name='Steam Barrier',description='Gain !B! {Block}. NL This card -1 {Block} this combat.',rarity='common',type='skill',baseCost=0,baseBlock=6,
	playerTarget=true,
}
function SteamBarrier:use()
	return {
		GainBlockAction:new{target=player,value=self.block},
		AnonymousAction:new(function ()
			self.baseBlock = self.baseBlock - 1
		end),
	}
end

function SteamBarrier:upgrade()
	self:upgradeValues({baseBlock=self.baseBlock+2})
end

Streamline = BlueCard:new{
	name='Streamline',description='{Damage} !D!. NL Reduce this card\'s cost by 1 this combat.',rarity='common',baseCost=2,baseDamage=15,
	enemyTarget=true,upgrade={baseDamage=20},
}
function Streamline:use(target)
	return {
		DamageAction:new{target=target,source=player,value=self.damage},
		AnonymousAction:new(function ()
			self.baseCost = math.max(0,self.baseCost-1)
			self.baseCostModified = true
		end),
	}
end

SweepingBeam = BlueCard:new{
	name='Sweeping Beam',description='{Damage} !D! to all enemies. NL Draw 1 card.',rarity='common',baseCost=1,baseDamage=6,
	enemyTarget=true,toAllEnemies=true,playerTarget=true,upgrade={baseDamage=9},
}
function SweepingBeam:use()
	return {
		DamageAllEnemiesAction:new{source=player,value=self.multiDamage},
		DrawCardAction:new(1),
	}
end

Turbo = BlueCard:new{
	name='TURBO',description='Gain {Energy}{Energy}. NL Add a Void into discard pile.',rarity='common',type='skill',baseCost=0,baseMagic=2,
	playerTarget=true,upgrade={baseMagic=3,description='Gain {Energy}{Energy}{Energy}. NL Add a Void into discard pile.'},
}
function Turbo:use()
	return {
		GainEnergyAction:new(self.magic),
		MakeTempCardToDiscardPileAction:new(Void:new()),
	}
end

Aggregate = BlueCard:new{
	name='Aggregate',description='Gain {Energy} for every !M! cards in draw pile.',rarity='uncommon',type='skill',baseCost=1,baseMagic=4,
	playerTarget=true,upgrade={baseMagic=3},preferSmallMagic=true,
}
function Aggregate:use()
	local magic = self.magic
	return { AnonymousAction:new(function ()
		local amount = #drawPile//magic
		if amount > 0 then
			addAction(1,GainEnergyAction:new(amount))
		end
	end) }
end

AutoShields = BlueCard:new{
	name='Auto-Shields',description='If you have no {Block}, gain !B! {Block}.',rarity='uncommon',type='skill',baseCost=1,baseBlock=11,
	playerTarget=true,upgrade={baseBlock=15},
}
function AutoShields:use()
	local block = self.block
	return { AnonymousAction:new(function ()
		if player.block == 0 then
			addAction(1,GainBlockAction:new{target=player,value=block})
		end
	end) }
end

Blizzard = BlueCard:new{
	name='Blizzard',description='{Damage} equal to !M! times the number of {Frost} channeled this combat to all enemies.',rarity='uncommon',
	baseCost=1,baseMagic=2,enemyTarget=true,toAllEnemies=true,upgrade={baseMagic=3},displayDamage='?',
}
function Blizzard:applyPowers(target)
	self.displayDamage = false
	self.baseDamage = self.baseMagic * DefectEventListener.frostChanneled
	BlueCard.applyPowers(self,target)
end

function Blizzard:resetPowers()
	self.displayDamage = '?'
	BlueCard.resetPowers(self)
end

function Blizzard:use()
	return { DamageAllEnemiesAction:new{source=player,value=self.multiDamage} }
end

BootSequence = BlueCard:new{
	name='Boot Sequence',description='Innate. NL Gain !B! {Block}. NL Exhaust.',rarity='uncommon',type='skill',
	baseCost=0,baseBlock=10,playerTarget=true,upgrade={baseBlock=13},exhaust=true,innate=true,
}
function BootSequence:use()
	return { GainBlockAction:new{target=player,value=self.block} }
end

Bullseye = BlueCard:new{
	name='Bullseye',description='{Damage} !D!. NL Apply !M! {212}.',rarity='uncommon',baseCost=1,enemyTarget=true,
	baseDamage=8,baseMagic=2,upgrade={baseDamage=11,baseMagic=3},
}
function Bullseye:use(target)
	return {
		DamageAction:new{target=target,source=player,value=self.damage},
		ApplyPowerAction:new(target,BullseyePower:new(target,self.magic)),
	}
end

BullseyePower = TurnBasedPower:new{icon=212,debuff=true,description='Receives #11#50%#12# more damage from orbs for #11#!A!#12# turn{s}.'}
function BullseyePower:onHitByOrb(damage)
	return damage * 1.5
end

Capacitor = BlueCard:new{
	name='Capacitor',description='Gain !M! orb slots.',rarity='uncommon',type='power',baseCost=1,baseMagic=2,playerTarget=true,
	upgrade={baseMagic=3},
}
function Capacitor:use()
	return { AddOrbSlotAction:new(self.magic) }
end

Chaos = BlueCard:new{
	name='Chaos',description='Channel !M! random orb.',rarity='uncommon',type='skill',baseCost=1,baseMagic=1,channelCount=1,
	playerTarget=true,upgrade={baseMagic=2,description='Channel !M! random orbs.',channelCount=2},
}
function Chaos:use()
	local actions = {}
	for i=1,self.magic do
		actions[i] = ChannelAction:new(orbTypes[miscRand:randInt(#orbTypes)]:new{owner=player})
	end
	return actions
end

Chill = BlueCard:new{
	name='Chill',description='Channel 1 {Frost} for each enemy in combat. NL Exhaust.',rarity='uncommon',type='skill',baseCost=0,playerTarget=true,
	upgrade={description='Innate. NL Channel 1 {Frost} for each enemy in combat. NL Exhaust.',innate=true},exhaust=true,
}
function Chill:applyPowers(target)
	self.channelCount = table.count(enemies,function (enemy) return enemy.canInteract end)
	BlueCard.applyPowers(self,target)
end

function Chill:use()
	return { AnonymousAction:new(function()
		for _,enemy in ipairs(enemies) do
			if enemy.canInteract then
				addAction(1,ChannelAction:new(Frost:new{owner=player}))
			end
		end
	end) }
end

Consume = BlueCard:new{
	name='Consume',description='Gain !M! {Focus}. NL Lose 1 orb slot.',rarity='uncommon',type='skill',baseCost=2,baseMagic=2,playerTarget=true,
	upgrade={baseMagic=3},
}
function Consume:use()
	return {
		ApplyPowerAction:new(player,FocusPower:new(player,self.magic)),
		AnonymousAction:new(function ()
			if #player.orbs > 0 then
				table.remove(player.orbs,#player.orbs)
			end
		end)
	}
end

Darkness = BlueCard:new{
	name='Darkness',description='Channel 1 {Dark}.',rarity='uncommon',type='skill',baseCost=1,playerTarget=true,
	upgrade={description='Channel 1 {Dark}. NL Trigger the passive ability of all {Dark}.'},channelCount=1,
}
function Darkness:use()
	local actions = { ChannelAction:new(Dark:new{owner=player}) }
	if self.upgraded then
		actions[2] = AnonymousAction:new(function ()
			local actions = {}
			for _,orb in ipairs(player.orbs) do
				if getmetatable(orb) == Dark then
					for _,action in ipairs(orb:onPassive()) do
						table.insert(actions,action)
					end
				end
			end
			for i,action in ipairs(actions) do
				addAction(i,action)
			end
		end)
	end
	return actions
end

Defragment = BlueCard:new{
	name='Defragment',description='Gain !M! {Focus}.',rarity='uncommon',type='power',baseCost=1,playerTarget=true,baseMagic=1,
	upgrade={baseMagic=2},
}
function Defragment:use()
	return { ApplyPowerAction:new(player,FocusPower:new(player,self.magic)) }
end

DoomAndGloom = BlueCard:new{
	name='Doom and Gloom',description='{Damage} !D! to all enemies. NL Channel 1 {Dark}.',rarity='uncommon',baseCost=2,baseDamage=10,
	playerTarget=true,enemyTarget=true,toAllEnemies=true,upgrade={baseDamage=14},channelCount=1,
}
function DoomAndGloom:use()
	return {
		DamageAllEnemiesAction:new{source=player,value=self.multiDamage},
		ChannelAction:new(Dark:new{owner=player}),
	}
end

DoubleEnergy = BlueCard:new{
	name='Double Energy',description='Double your {Energy}. NL Exhaust.',rarity='uncommon',type='skill',baseCost=1,playerTarget=true,
	upgrade={baseCost=0},exhaust=true,
}
function DoubleEnergy:use()
	return {
		AnonymousAction:new(function ()
			addAction(1,GainEnergyAction:new(energy))
		end)
	}
end

Equilibrium = BlueCard:new{
	name='Equilibrium',description='Gain !B! {Block}. NL Retain your hand this turn.',rarity='uncommon',type='skill',baseCost=2,playerTarget=true,
	baseBlock=13,upgrade={baseBlock=16},
}
function Equilibrium:use()
	return {
		GainBlockAction:new{target=player,value=self.block},
		ApplyPowerAction:new(player,EquilibriumPower:new(player,1)),
	}
end

EquilibriumPower = TurnBasedPower:new{icon=214,description='Retain your hand for #11#!A!#12# turn{s}.'}
function EquilibriumPower:onTurnEnd()
	addAction(AnonymousAction:new(function ()
		for _, cardItem in ipairs(hand) do
			cardItem.card.tempRetain = true
		end
	end))
end

FTL = BlueCard:new{
	name='FTL',description='{Damage} !D!. If you have played less than !M! cards this turn, draw 1 card.',rarity='uncommon',baseCost=0,
	enemyTarget=true,playerTarget=true,baseDamage=5,baseMagic=3,upgrade={baseDamage=6,baseMagic=4},
}
function FTL:checkGlow()
	if DefectEventListener.cardsPlayedThisTurn < self.magic then
		return 4
	end
end

function FTL:use(target)
	return {
		DamageAction:new{target=target,source=player,value=self.damage},
		AnonymousAction:new(function ()
			if DefectEventListener.cardsPlayedThisTurn - 1 < self.magic then
				addAction(1,DrawCardAction:new(1))
			end
		end),
	}
end

ForceField = BlueCard:new{
	name='Force Field',description='Costs 1 less {Energy} for each {Power} played this combat. NL Gain !B! {Block}.',rarity='uncommon',type='skill',baseCost=4,
	playerTarget=true,baseBlock=12,upgrade={baseBlock=16},
}
function ForceField:onUseCard(card)
	if card.type == 'power' then
		self:modifyBaseCost(-1)
	end
end

function ForceField:use()
	return { GainBlockAction:new{target=player,value=self.block} }
end

Fusion = BlueCard:new{
	name='Fusion',description='Channel 1 {Plasma}.',rarity='uncommon',type='skill',baseCost=2,playerTarget=true,channelCount=1,
	upgrade={baseCost=1},
}
function Fusion:use()
	return { ChannelAction:new(Plasma:new{owner=player}) }
end

GeneticAlgorithm = BlueCard:new{
	name='Genetic Algorithm',description='Gain !B! {Block}. NL This card NL +!M! {Block} permanently. NL Exhaust.',rarity='uncommon',
	type='skill',baseCost=1,playerTarget=true,baseBlock=1,baseMagic=2,upgrade={baseMagic=3},exhaust=true,source=nil,
}
function GeneticAlgorithm:use()
	return {
		GainBlockAction:new{target=player,value=self.block},
		AnonymousAction:new(function ()
			self.baseBlock = self.baseBlock + self.magic
			self:applyPowers()
			if self.source and table.indexOf(deck,self.source) then
				self.source.baseBlock = self.source.baseBlock + self.magic
				self.source:resetPowers()
			end
		end)
	}
end

function GeneticAlgorithm:copy()
	local copied = BlueCard.copy(self)
	copied.source = self
	return copied
end

function GeneticAlgorithm:save()
	return BlueCard.save(self) | (self.baseBlock << 1)
end

function GeneticAlgorithm:load(meta)
	BlueCard.load(self,meta & 1)
	self.baseBlock = meta >> 1
	self.block = self.baseBlock
end

Glacier = BlueCard:new{
	name='Glacier',description='Gain !B! {Block}. NL Channel 2 {Frost}.',rarity='uncommon',type='skill',baseCost=2,
	playerTarget=true,baseBlock=7,upgrade={baseBlock=10},channelCount=2,
}
function Glacier:use()
	return {
		GainBlockAction:new{target=player,value=self.block},
		ChannelAction:new(Frost:new{owner=player}),
		ChannelAction:new(Frost:new{owner=player}),
	}
end

Heatsinks = BlueCard:new{
	name='Heatsinks',description='Whenever you play a {Power}, draw !M! card.',rarity='uncommon',type='power',baseCost=1,baseMagic=1,
	playerTarget=true,upgrade={baseMagic=2,description='Whenever you play a {Power}, draw !M! cards.'},
}
function Heatsinks:use()
	return { ApplyPowerAction:new(player,HeatsinksPower:new(player,self.magic)) }
end

HeatsinksPower = Power:new{icon=216,description='Whenever you play a {Power}, draw #11#!A!#12# card{s}.'}
function HeatsinksPower:onUseCard(card)
	if card.type == 'power' then
		addAction(DrawCardAction:new(self.amount))
	end
end

HelloWorld = BlueCard:new{
	name='Hello World',description='At the start of turn, add a random common card into hand.',rarity='uncommon',type='power',baseCost=1,
	playerTarget=true,upgrade={description='Innate. NL At the start of turn, add a random common card into hand.',innate=true},
}
function HelloWorld:use()
	return { ApplyPowerAction:new(player,HelloWorldPower:new(player,1)) }
end

HelloWorldPower = Power:new{icon=201,description='At the start of turn, add #11#!A!#12# random common card{s} into hand.'}
function HelloWorldPower:onTurnStart()
	for _=1,self.amount do
		local card = getPlayerCardType(miscRand,'common',nil,true):new()
		addAction(MakeTempCardToHandAction:new(card))
	end
end

Loop = BlueCard:new{
	name='Loop',description='At the start of turn, trigger the passive ability of next orb.',rarity='uncommon',type='power',baseCost=1,
	playerTarget=true,baseMagic=1,upgrade={description='At the start of turn, trigger the passive ability of next orb !M! times.',baseMagic=2},
}
function Loop:use()
	return { ApplyPowerAction:new(player,LoopPower:new(player,self.magic)) }
end

LoopPower = Power:new{icon=217,description='At the start of turn, trigger the passive ability of next orb #11#!A!#12# times.'}
function LoopPower:onTurnStart()
	for _=1,self.amount do
		addAction(AnonymousAction:new(function ()
			local orb = player.orbs[1]
			if getmetatable(orb) == OrbSlot then
				return
			end
			for i,action in ipairs(orb:onPassive(true)) do
				addAction(i,action)
			end
		end))
	end
end

Melter = BlueCard:new{
	name='Melter',description='Remove all {Block} from the enemy. NL {Damage} !D!.',rarity='uncommon',baseCost=1,
	enemyTarget=true,baseDamage=10,upgrade={baseDamage=14},
}
function Melter:use(target)
	return {
		AnonymousAction:new(function ()
			target.block = 0
		end),
		DamageAction:new{target=target,source=player,value=self.damage},
	}
end

Overclock = BlueCard:new{
	name='Overclock',description='Draw !M! cards. NL Add a Burn into discard pile.',rarity='uncommon',type='skill',baseCost=0,baseMagic=2,
	playerTarget=true,upgrade={baseMagic=3},
}
function Overclock:use()
	return {
		DrawCardAction:new(self.magic),
		MakeTempCardToDiscardPileAction:new(Burn:new()),
	}
end

Recycle = BlueCard:new{
	name='Recycle',description='Exhaust 1 card. NL Gain {Energy} equal to its cost.',rarity='uncommon',type='skill',
	baseCost=1,playerTarget=true,upgrade={baseCost=0},
}
function Recycle:use()
	return {
		AnonymousAction:new(function ()
			if #hand == 0 then
				return
			elseif #hand == 1 then
				local cardIndex = 1
				local cost = hand[cardIndex].card:getCost()
				cost = cost == -1 and energy or cost
				addAction(1,ExhaustCardAction:new{cardItem=hand[cardIndex],show=true})
				if cost > 0 then
					addAction(2,GainEnergyAction:new(cost))
				end
				removeHand(cardIndex)
			else
				openWindowAbove(HandSelectWindow:new{cardItems=hand,title='Choose a Card to Exhaust',max=1},function (cards)
					for _, cardItem in ipairs(cards) do
						local cardIndex = table.indexOf(hand,cardItem)
						local cost = hand[cardIndex].card:getCost()
						cost = cost == -1 and energy or cost
						addAction(1,ExhaustCardAction:new{cardItem=cardItem})
						if cost > 0 then
							addAction(2,GainEnergyAction:new(cost))
						end
						removeHand(cardIndex)
					end
				end)
			end
		end)
	}
end

ReinforcedBody = BlueCard:new{
	name='Reinforced Body',description='Gain !B! {Block} X times.',rarity='uncommon',type='skill',baseCost=-1,
	playerTarget=true,baseBlock=7,upgrade={baseBlock=9},
}
function ReinforcedBody:use(_,energyOnUse,free)
	return {
		XCardAction:new(function (amount)
			local result = {}
			for i = 1, amount do
				result[i] = GainBlockAction:new{target=player,value=self.block}
			end
			return result
		end,energyOnUse,free)
	}
end

Reprogram = BlueCard:new{
	name='Reprogram',description='Lose !M! {Focus}. NL Gain !M! {Strength}. NL Gain !M! {Dexterity}.',rarity='uncommon',type='skill',baseCost=1,
	playerTarget=true,baseMagic=1,upgrade={baseMagic=2},
}
function Reprogram:use()
	return {
		ApplyPowerAction:new(player,FocusPower:new(player,-self.magic)),
		ApplyPowerAction:new(player,StrengthPower:new(player,self.magic)),
		ApplyPowerAction:new(player,DexterityPower:new(player,self.magic)),
	}
end

RipAndTear = BlueCard:new{
	name='Rip and Tear',description='{Damage} !D! to a random enemy twice.',rarity='uncommon',baseCost=1,
	enemyTarget=true,toAllEnemies=true,playerTarget=true,baseDamage=7,upgrade={baseDamage=9},displayAttackCount=2,
}
function RipAndTear:use()
	return {
		DamageRandomEnemyAction:new{source=player,value=self.multiDamage},
		DamageRandomEnemyAction:new{source=player,value=self.multiDamage},
	}
end

Scrape = BlueCard:new{
	name='Scrape',description='{Damage} !D!. NL Draw !M! cards. NL Discard all cards drawn this way that do not cost 0.',
	rarity='uncommon',baseCost=1,baseDamage=7,baseMagic=4,playerTarget=true,enemyTarget=true,upgrade={baseDamage=10,baseMagic=5},
}
function Scrape:use(target)
	local drawCardAction = DrawCardAction:new(self.magic)
	return {
		DamageAction:new{target=target,source=player,value=self.damage},
		drawCardAction,
		AnonymousAction:new(function ()
			local cards = {}
			for _,card in ipairs(drawCardAction.cardDrawn) do
				if card:getCost() ~= 0 then
					table.insert(cards,card)
				end
			end
			if #cards > 0 then
				local index = 1
				for _,card in ipairs(cards) do
					local cardIndex = nil
					for j,cardItem in ipairs(hand) do
						if cardItem.card == card then
							cardIndex = j
							break
						end
					end
					if cardIndex then
						addAction(index,DiscardAction:new{cardItem=hand[cardIndex],duration=1})
						removeHand(cardIndex)
						index = index + 1
					end
				end
			end
		end),
	}
end

SelfRepair = BlueCard:new{
	name='Self Repair',description='At the end of combat, heal !M! HP.',rarity='uncommon',type='power',baseCost=1,baseMagic=7,
	playerTarget=true,upgrade={baseMagic=10},canGenerateInCombat=false,
}
function SelfRepair:use()
	return { ApplyPowerAction:new(player,SelfRepairPower:new(player,self.magic)) }
end

SelfRepairPower = Power:new{icon=233,description='At the end of combat, heal #11#!A!#12# HP.'}
function SelfRepairPower:onCombatEnd()
	player:heal(self.amount)
end

Skim = BlueCard:new{
	name='Skim',description='Draw !M! cards.',rarity='uncommon',type='skill',baseCost=1,baseMagic=3,
	playerTarget=true,upgrade={baseMagic=4},
}
function Skim:use()
	return { DrawCardAction:new(self.magic) }
end

StaticDischarge = BlueCard:new{
	name='Static Discharge',description='Whenever you receive unblocked attack damage, channel !M! {Lightning}.',rarity='uncommon',type='power',
	baseCost=1,baseMagic=1,playerTarget=true,upgrade={baseMagic=2},
}
function StaticDischarge:use()
	return { ApplyPowerAction:new(player,StaticDischargePower:new(player,self.magic)) }
end

StaticDischargePower = Power:new{icon=248,description='Whenever you receive unblocked attack damage, channel #11#!A!#12# {Lightning}.'}
function StaticDischargePower:onDamaged(value,_,type)
	if value > 0 and type == 'attack' then
		for i=1,self.amount do
			addAction(i,ChannelAction:new(Lightning:new{owner=player}))
		end
	end
end

Storm = BlueCard:new{
	name='Storm',description='Whenever you play a {Power}, channel 1 {Lightning}.',rarity='uncommon',type='power',baseCost=1,
	playerTarget=true,upgrade={description='Innate. NL Whenever you play a {Power}, channel 1 {Lightning}.',innate=true},
}
function Storm:use()
	return { ApplyPowerAction:new(player,StormPower:new(player,1)) }
end

StormPower = Power:new{icon=232,description='Whenever you play a {Power}, channel #11#!A!#12# {Lightning}.'}
function StormPower:onUseCard(card)
	if card.type == 'power' then
		for _=1,self.amount do
			addAction(ChannelAction:new(Lightning:new{owner=player}))
		end
	end
end

Sunder = BlueCard:new{
	name='Sunder',description='{Damage} !D!. NL If this kills an enemy, gain {Energy}{Energy}{Energy}.',
	rarity='uncommon',baseCost=3,baseDamage=24,enemyTarget=true,upgrade={baseDamage=32},
}
function Sunder:use(target)
	local damageAction = DamageAction:new{target=target,source=player,value=self.damage}
	return {
		damageAction,
		AnonymousAction:new(function ()
			if damageAction.numKilled and damageAction.numKilled > 0 then
				addAction(1,GainEnergyAction:new(3))
			end
		end),
	}
end

Tempest = BlueCard:new{
	name='Tempest',description='Channel X {Lightning}. NL Exhaust.',rarity='uncommon',type='skill',baseCost=-1,
	playerTarget=true,upgrade={description='Channel X+1 {Lightning}. NL Exhaust.'},exhaust=true,
}
function Tempest:applyPowers(target)
	self.channelCount = energy + (self.upgraded and 1 or 0)
	BlueCard.applyPowers(self,target)
end

function Tempest:use(_,energyOnUse,free)
	local upgraded = self.upgraded
	return {
		XCardAction:new(function (amount)
			local actions = {}
			if upgraded then
				amount = amount + 1
			end
			for i = 1,amount do
				actions[i] = ChannelAction:new(Lightning:new{owner=player})
			end
			return actions
		end,energyOnUse,free)
	}
end

WhiteNoise = BlueCard:new{
	name='White Noise',description='Add a random {Power} into hand. NL It costs 0 this turn. NL Exhaust.',rarity='uncommon',
	type='skill',baseCost=1,playerTarget=true,upgrade={baseCost=0},exhaust=true,
}
function WhiteNoise:use()
	local randomType = getPlayerCardType(miscRand,nil,'power',true)
	local card = randomType:new()
	card.costForOneTurnPlay = 0
	return { MakeTempCardToHandAction:new(card,1) }
end

AllForOne = BlueCard:new{
	name='All for One',description='{Damage} !D!. NL Put all cost 0 cards from discard pile into hand.',rarity='rare',baseCost=2,
	playerTarget=true,enemyTarget=true,baseDamage=10,upgrade={baseDamage=14},
}
function AllForOne:use(target)
	local damageAction = DamageAction:new{target=target,source=player,value=self.damage}
	return {
		damageAction,
		AnonymousAction:new(function ()
			local cards = {}
			for _,card in ipairs(discardPile) do
				if card:getCost() == 0 then
					table.insert(cards,card)
				end
			end
			if #cards > 0 then
				for _,card in ipairs(cards) do
					if #hand > HAND_LIMIT then
						break
					end
					local cardItem = CardItem:new{card=card,x=240,y=136}
					table.remove(discardPile,table.indexOf(discardPile,card))
					insertHand(cardItem)
				end
			end
		end),
	}
end

Amplify = BlueCard:new{
	name='Amplify',description='This turn, your next {Power} is played twice.',rarity='rare',type='skill',baseCost=1,baseMagic=1,
	playerTarget=true,upgrade={baseMagic=2,description='This turn, your next !M! {Power} are played twice.'},
}
function Amplify:use()
	return { ApplyPowerAction:new(player,AmplifyPower:new(player,self.magic)) }
end

AmplifyPower = Power:new{icon=213,description='your next #11#!A!#12# {Power} {is} played twice this turn.'}
function AmplifyPower:onUseCard(card,target,useCardAction)
	if card.type == 'power' and not useCardAction.isDoubleTap then
		local cardItem = useCardAction.cardItem:copy()
		local action = UseCardAction:new{cardItem=cardItem,isDoubleTap=true,tempCard=true,free=true,target=target,energyOnUse=useCardAction.energyOnUse}
		action.useCardPosition = fillCardPosition(cardItem,2)
		table.insert(limbo,cardItem)
		addAction(1,ReducePowerAction:new(self,1))
		addAction(action)
	end
end

function AmplifyPower:onTurnEnd()
	addAction(RemovePowerAction:new(self))
end

BiasedCognition = BlueCard:new{
	name='Biased Cognition',description='Gain !M! {Focus}. NL At the start of turn, lose 1 {Focus}.',rarity='rare',type='power',baseCost=1,
	playerTarget=true,baseMagic=4,upgrade={baseMagic=5},
}
function BiasedCognition:use()
	return {
		ApplyPowerAction:new(player,FocusPower:new(player,self.magic)),
		ApplyPowerAction:new(player,BiasedCognitionPower:new(player,1)),
	}
end

BiasedCognitionPower = Power:new{icon=icons.Bias,debuff=true,description='At the start of turn, lose #11#!A!#12# {Focus}.'}
function BiasedCognitionPower:onTurnStart()
	addAction(ApplyPowerAction:new(self.owner,FocusPower:new(self.owner,-self.amount)))
end

Buffer = BlueCard:new{
	name='Buffer',description='Prevent the next time you would lose HP.',rarity='rare',type='power',baseCost=2,
	playerTarget=true,baseMagic=1,upgrade={baseMagic=2,description='Prevent the next !M! times you would lose HP.'},
}
function Buffer:use()
	return { ApplyPowerAction:new(player,BufferPower:new(player,self.magic)) }
end

CoreSurge = BlueCard:new{
	name='Core Surge',description='{Damage} !D!. NL Gain 1 {Artifact}. NL Exhaust.',rarity='rare',baseCost=1,
	playerTarget=true,enemyTarget=true,baseDamage=11,upgrade={baseDamage=15},exhaust=true,
}
function CoreSurge:use(target)
	return {
		DamageAction:new{target=target,source=player,value=self.damage},
		ApplyPowerAction:new(player,ArtifactPower:new(player,1)),
	}
end

CreativeAI = BlueCard:new{
	name='Creative AI',description='At the start of turn, add a random {Power} into hand.',rarity='rare',type='power',baseCost=3,
	playerTarget=true,upgrade={baseCost=2},
}
function CreativeAI:use()
	return { ApplyPowerAction:new(player,CreativeAIPower:new(player,1)) }
end

CreativeAIPower = Power:new{icon=200,description='At the start of turn, add #11#!A!#12# random {Power} into hand.'}
function CreativeAIPower:onTurnStart()
	for _=1,self.amount do
		local card = getPlayerCardType(miscRand,nil,'power',true):new()
		addAction(MakeTempCardToHandAction:new(card))
	end
end

EchoForm = BlueCard:new{
	name='Echo Form',description='Ethereal. NL The first card you play each turn is played twice.',rarity='rare',type='power',baseCost=3,
	playerTarget=true,upgrade={ethereal=false,description='The first card you play each turn is played twice.'},ethereal=true,
}
function EchoForm:use()
	return { ApplyPowerAction:new(player,EchoFormPower:new(player,1)) }
end

EchoFormPower = Power:new{icon=199,cardsPlayed=1,description='The first #11#!A!#12# card{s} you play each turn is played twice.'}
function EchoFormPower:new(...)
	local r = Power.new(self,...)
	r.cardsPlayed = DefectEventListener.cardsPlayedThisTurn + 1
	return r
end

function EchoFormPower:onUseCard(_,target,useCardAction)
	if not useCardAction.isDoubleTap and self.cardsPlayed < self.amount then
		local cardItem = useCardAction.cardItem:copy()
		local action = UseCardAction:new{cardItem=cardItem,isDoubleTap=true,tempCard=true,free=true,target=target,energyOnUse=useCardAction.energyOnUse}
		action.useCardPosition = fillCardPosition(cardItem,2)
		table.insert(limbo,cardItem)
		addAction(action)
		self.cardsPlayed = self.cardsPlayed + 1
	end
end

function EchoFormPower:onTurnStart()
	self.cardsPlayed = 0
end

Electrodynamics = BlueCard:new{
	name='Electrodynamics',description='{Lightning} now hits all enemies. NL Channel !M! {Lightning}.',rarity='rare',type='power',baseCost=2,
	playerTarget=true,baseMagic=2,upgrade={baseMagic=3,channelCount=3},channelCount=2,
}
function Electrodynamics:use()
	local actions = {
		ApplyPowerAction:new(player,ElectrodynamicsPower:new(player,self.magic)),
		ChannelAction:new(Lightning:new{owner=player}),
		ChannelAction:new(Lightning:new{owner=player}),
	}
	if self.upgraded then
		actions[4] = ChannelAction:new(Lightning:new{owner=player})
	end
	return actions
end

ElectrodynamicsPower = Power:new{icon=215,stackable=false,description='{Lightning} now hits all enemies.'}

Fission = BlueCard:new{
	name='Fission',description='Remove all orbs. Gain {Energy} and draw 1 card for each orb removed. NL Exhaust.',rarity='rare',type='skill',
	baseCost=0,playerTarget=true,upgrade={description='Evoke all orbs. Gain {Energy} and draw 1 card for each orb evoked. NL Exhaust.',evokeCount=10},
}
function Fission:use()
	local upgraded = self.upgraded
	return {
		AnonymousAction:new(function ()
			local numOrbs = 0
			local numEvokeAction = 0
			for i,orb in ipairs(player.orbs) do
				if getmetatable(orb) ~= OrbSlot then
					if upgraded then
						addAction(i,EvokeAction:new{duration=1})
					else
						player.orbs[i] = OrbSlot:new{owner=player,x=orb.x,y=orb.y}
					end
					numOrbs = numOrbs + 1
				else
					break
				end
			end
			if upgraded then
				numEvokeAction = numOrbs
			end
			addAction(numEvokeAction+1,GainEnergyAction:new(numOrbs))
			addAction(numEvokeAction+2,DrawCardAction:new(numOrbs))
		end)
	}
end

Hyperbeam = BlueCard:new{
	name='Hyperbeam',description='{Damage} !D! to all enemies. NL Lose 3 {Focus}.',rarity='rare',baseCost=2,
	playerTarget=true,enemyTarget=true,toAllEnemies=true,baseDamage=26,upgrade={baseDamage=34},
}
function Hyperbeam:use()
	return {
		DamageAllEnemiesAction:new{source=player,value=self.multiDamage},
		ApplyPowerAction:new(player,FocusPower:new(player,-3)),
	}
end

MachineLearning = BlueCard:new{
	name='Machine Learning',description='At the start of turn, draw 1 additional card.',rarity='rare',type='power',baseCost=1,
	playerTarget=true,upgrade={description='Innate. NL At the start of turn, draw 1 additional card.',innate=true},
}
function MachineLearning:use()
	return { ApplyPowerAction:new(player,MachineLearningPower:new(player,1)) }
end

MachineLearningPower = Power:new{icon=icons.DrawCardEveryTurn,description='At the start of turn, draw #11#!A!#12# additional card.'}
function MachineLearningPower:onTurnStartPostDraw()
	addAction(DrawCardAction:new(self.amount))
end

MeteorStrike = BlueCard:new{
	name='Meteor Strike',description='{Damage} !D!. NL Channel 3 {Plasma}.',rarity='rare',baseCost=5,
	playerTarget=true,enemyTarget=true,baseDamage=24,upgrade={baseDamage=30},channelCount=3,tags={'strike'},
}
function MeteorStrike:use(target)
	return {
		DamageAction:new{target=target,source=player,value=self.damage},
		ChannelAction:new(Plasma:new{owner=player}),
		ChannelAction:new(Plasma:new{owner=player}),
		ChannelAction:new(Plasma:new{owner=player}),
	}
end

Multicast = BlueCard:new{
	name='Multi-Cast',description='Evoke your next orb X times.',rarity='rare',type='skill',baseCost=-1,
	playerTarget=true,upgrade={description='Evoke your next orb X+1 times.'},evokeCount=1,
}
function Multicast:use(_,energyOnUse,free)
	local upgraded = self.upgraded
	return {
		XCardAction:new(function (amount)
			if upgraded then
				amount = amount + 1
			end
			return { EvokeAction:new{amount=amount} }
		end,energyOnUse,free)
	}
end

Rainbow = BlueCard:new{
	name='Rainbow',description='Channel 1 {Lightning}. NL Channel 1 {Frost}. NL Channel 1 {Dark}. NL Exhaust.',rarity='rare',type='skill',
	baseCost=2,playerTarget=true,upgrade={description='Channel 1 {Lightning}. NL Channel 1 {Frost}. NL Channel 1 {Dark}.',exhaust=false},
	exhaust=true,channelCount=3,
}
function Rainbow:use()
	return {
		ChannelAction:new(Lightning:new{owner=player}),
		ChannelAction:new(Frost:new{owner=player}),
		ChannelAction:new(Dark:new{owner=player}),
	}
end

Reboot = BlueCard:new{
	name='Reboot',description='Shuffle all your cards into your draw pile. NL Draw !M! cards. NL Exhaust.',rarity='rare',
	type='skill',baseCost=0,playerTarget=true,baseMagic=4,upgrade={baseMagic=6},exhaust=true,
}
function Reboot:use()
	return {
		AnonymousAction:new(function ()
			local count = #hand
			for i=1,#hand do
				local cardItem = hand[i]
				addAction(i,PutCardInDrawPileAction:new{cardItem=cardItem,duration=1})
			end
			for i=#hand,1,-1 do
				removeHand(i)
			end
			addAction(count+1,ShuffleAction:new())
		end),
		DrawCardAction:new(self.magic),
	}
end

Seek = BlueCard:new{
	name='Seek',description='Put !M! card from draw pile into hand. NL Exhaust.',rarity='rare',type='skill',baseCost=0,
	playerTarget=true,baseMagic=1,upgrade={description='Put !M! cards from draw pile into hand. NL Exhaust.',baseMagic=2},exhaust=true,
}
function Seek:use()
	local amount = self.magic
	return {
		AnonymousAction:new(function ()
			local cardItems = {}
			for i, card in ipairs(drawPile) do
				cardItems[i] = CardItem:new{card=card,x=0,y=136,tx=240,ty=136,isNotInHand=true}
			end
			if #cardItems == 0 then
				return
			elseif #cardItems <= amount then
				for _, cardItem in ipairs(cardItems) do
					table.remove(drawPile,table.indexOf(drawPile,cardItem.card))
					insertHand(cardItem)
				end
			else
				effectRandom:shuffle(cardItems)
				local title = amount == 1 and 'Choose a Card to Put into Hand' or 'Choose Cards to Put into Hand ({#}/'..tostring(amount)..')'
				openWindowAbove(CardGridSelectWindow:new{cardItems=cardItems,title=title,min=amount,max=amount},
					function (cards)
						for _, cardItem in ipairs(cards) do
							table.remove(drawPile,table.indexOf(drawPile,cardItem.card))
							insertHand(cardItem)
						end
					end)
			end
		end),
	}
end

ThunderStrike = BlueCard:new{
	name='Thunder Strike',description='{Damage} !D! to a random enemy for each {Lightning} channeled this combat.',rarity='rare',baseCost=3,
	playerTarget=true,enemyTarget=true,toAllEnemies=true,baseDamage=7,upgrade={baseDamage=9},displayAttackCount='?',tags={'strike'},
}
function ThunderStrike:applyPowers(target)
	self.displayAttackCount = DefectEventListener.lightningChanneled
	BlueCard.applyPowers(self,target)
end

function ThunderStrike:resetPowers()
	self.displayAttackCount = '?'
	BlueCard.resetPowers(self)
end

function ThunderStrike:use()
	local actions = {}
	for i=1,DefectEventListener.lightningChanneled do
		actions[i] = DamageRandomEnemyAction:new{source=player,value=self.multiDamage}
	end
	return actions
end

blueCards = {
	StrikeBlue,DefendBlue,Zap,Dualcast,BallLightning,Barrage,BeamCell,ChargeBattery,Claw,ColdSnap,CompileDriver,
	Coolheaded,GoForTheEyes,Hologram,Leap,Rebound,Recursion,Stack,SteamBarrier,Streamline,SweepingBeam,Turbo,
	Aggregate,AutoShields,Blizzard,BootSequence,Bullseye,Capacitor,Chaos,Chill,Consume,Darkness,Defragment,
	DoomAndGloom,DoubleEnergy,Equilibrium,FTL,ForceField,Fusion,GeneticAlgorithm,Glacier,Heatsinks,HelloWorld,
	Loop,Melter,Overclock,Recycle,ReinforcedBody,Reprogram,RipAndTear,Scrape,SelfRepair,Skim,StaticDischarge,
	Storm,Sunder,Tempest,WhiteNoise,AllForOne,Amplify,BiasedCognition,Buffer,CoreSurge,CreativeAI,EchoForm,
	Electrodynamics,Fission,Hyperbeam,MachineLearning,MeteorStrike,Multicast,Rainbow,Reboot,Seek,ThunderStrike,
}

-- relics
BlueRelic = Relic:new{colorName='blue'}

CrackedCore = BlueRelic:new{ name='Cracked Core',tier='basic',icon=243,description='At the start of each combat, channel #11#1#12# {Lightning}.' }
function CrackedCore:onCombatStart()
	addAction(ChannelAction:new(Lightning:new{owner=player}))
end

DataDisk = BlueRelic:new{ name='Data Disk',tier='common',icon=244,description='Start each combat with #11#1#12# {Focus}.' }
function DataDisk:onCombatStart()
	addAction(ApplyPowerAction:new(player,FocusPower:new(player,1)))
end

GoldPlatedCables = BlueRelic:new{ name='Gold-Plated Cables',tier='uncommon',icon=228,description='Your rightmost orb triggers its passive an additional time.' }
function GoldPlatedCables:onOrbPassive(orb)
	if #player.orbs > 0 and orb == player.orbs[1] then
		addAction(AnonymousAction:new(function ()
			for _,action in ipairs(orb:onPassive(true)) do
				addAction(action)
			end
		end))
	end
end

SymbioticVirus = BlueRelic:new{ name='Symbiotic Virus',tier='uncommon',icon=229,description='At the start of each combat, channel #11#1#12# {Dark}.' }
function SymbioticVirus:onCombatStart()
	addAction(ChannelAction:new(Dark:new{owner=player}))
end

EmotionChip = BlueRelic:new{ name='Emotion Chip',tier='rare',icon=245,damaged=false,description='If you lost HP during the previous turn, trigger the passive ability of all orbs at the start of turn.' }
function EmotionChip:onDamaged(value)
	if value > 0 then
		self.damaged = true
		self.counter = 1
	end
end

function EmotionChip:onTurnStart()
	if self.damaged then
		self.damaged = false
		self.counter = -1
		for _,orb in ipairs(player.orbs) do
			if getmetatable(orb) ~= OrbSlot then
				for _,action in ipairs(orb:onPassive()) do
					addAction(action)
				end
			end
		end
	end
end

FrozenCore = BlueRelic:new{ name='Frozen Core',tier='boss',icon=246,replaces=CrackedCore,description='Replaces #11#Cracked Core#12#. If you end turn with any empty Orb slots, channel #11#1#12# {Frost}.' }
function FrozenCore:onTurnEnd()
	if table.anyMatch(player.orbs,function(orb) return getmetatable(orb) == OrbSlot end) then
		local orb = Frost:new{owner=player}
		addAction(ChannelAction:new(orb))
		addAction(AnonymousAction:new(function ()
			for _,action in ipairs(orb:onPassive()) do
				addAction(action)
			end
		end))
	end
end

Inserter = BlueRelic:new{ name='Inserter',tier='boss',icon=231,counter=0,description='Every #11#2#12# turns, gain #11#1#12# orb slot.' }
function Inserter:onTurnStart()
	self.counter = self.counter + 1
	if self.counter == 2 then
		self.counter = 0
		addAction(AddOrbSlotAction:new(1))
	end
end

NuclearBattery = BlueRelic:new{ name='Nuclear Battery',tier='boss',icon=247,description='At the start of each combat, channel #11#1#12# {Plasma}.' }
function NuclearBattery:onCombatStart()
	addAction(ChannelAction:new(Plasma:new{owner=player}))
end

RunicCapacitor = BlueRelic:new{ name='Runic Capacitor',tier='shop',icon=230,description='Start each combat with #11#3#12# additional orb slots.' }
function RunicCapacitor:onCombatStart()
	addAction(AddOrbSlotAction:new(3))
end

-- potions
FocusPotion = Potion:new{
	name='Focus Potion',icon=Icon:new{image=98,colorMap={9,9,9,11,11}},rarity='common',description='Gain #11#!M!#12# {Focus}.',baseMagic=2,
}
function FocusPotion:use()
	return { ApplyPowerAction:new(player,FocusPower:new(player,self.magic)) }
end

EssenceOfDarkness = Potion:new{
	name='Essence of Darkness',icon=Icon:new{image=108,colorMap={14,13}},rarity='rare',description='Channel #11#!M!#12# {Dark} for each orb slot.',baseMagic=1,
}
function EssenceOfDarkness:use()
	return {
		AnonymousAction:new(function ()
			for i=1,#player.orbs*self.magic do
				addAction(i,ChannelAction:new(Dark:new{owner=player}))
			end
		end)
	}
end

PotionOfCapacity = Potion:new{
	name='Potion of Capacity',icon=Icon:new{image=100,colorMap={9,10,11}},rarity='uncommon',description='Gain #11#!M!#12# orb slots.',baseMagic=2,
}
function PotionOfCapacity:use()
	return { AddOrbSlotAction:new(self.magic) }
end
