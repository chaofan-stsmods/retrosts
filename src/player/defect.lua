---@diagnostic disable: lowercase-global

local blueCards

Defect = Player:new{ maxHp=75,width=6,height=4,tileBank=3,name='Defect',maxOrbs=3 }
function Defect:drawImage()
	if self.flipped then
		map(14,9,4,4,self.x+8,self.y,0,1,flipRemap(14,4))
	else
		map(14,9,4,4,self.x+8,self.y,0)
	end
end

function Defect:drawCorpse()
	map(7,13,7,2,self.x-4,self.y+20,0)
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
	}
end

function Defect:getPotions()
	return {  }
end

function Defect:getPronouns()
	return {vampires='broken one'}
end

function Defect:getSpireHeartText()
	return 'NL You charge your core to its maximum...'
end

function Defect:getEnding()
	return IroncladEnding:new()
end

-- orbs

Orb = Object:new{owner=nil,x=0,y=0,tx=0,ty=0,icon=nil,evoking=false,applyPowers=noop,drawNumbers=noop,onEvoke=noop}
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

OrbSlot = Orb:new{icon=icons.OrbSlot}

Lightning = Orb:new{icon=icons.Lightning,value=3,evokeValue=8}
function Lightning:applyPowers()
	self.value = math.max(0,3+self:getFocusAmount())
	self.evokeValue = math.max(0,8+self:getFocusAmount())
end

function Lightning:drawNumbers()
	local text = self.evoking and tostring(self.evokeValue) or tostring(self.value)
	printGlowed(text,self.x+4-strWidth(text,false,true)/2,self.y,self.evoking and 10 or 12,15,1,true)
end

function Lightning:onEvoke()
	return { DamageRandomEnemyAction:new{source=self.owner,value=self.evokeValue,type='power'} }
end

function Lightning:onPassive()
	return { DamageRandomEnemyAction:new{source=self.owner,value=self.value,type='power'} }
end

function Lightning:onTurnEnd()
	for _,action in ipairs(self:onPassive()) do
		addAction(action)
	end
end

Frost = Orb:new{icon=icons.Frost,value=2,evokeValue=5}
function Frost:applyPowers()
	self.value = math.max(0,2+self:getFocusAmount())
	self.evokeValue = math.max(0,5+self:getFocusAmount())
end

function Frost:drawNumbers()
	local text = self.evoking and tostring(self.evokeValue) or tostring(self.value)
	printGlowed(text,self.x+4-strWidth(text,false,true)/2,self.y,self.evoking and 10 or 12,15,1,true)
end

function Frost:onEvoke()
	return { GainBlockAction:new{target=self.owner,value=self.evokeValue} }
end

function Frost:onPassive()
	return { GainBlockAction:new{target=self.owner,value=self.value} }
end

function Frost:onTurnEnd()
	for _,action in ipairs(self:onPassive()) do
		addAction(action)
	end
end

Dark = Orb:new{icon=icons.Dark,value=6,evokeValue=6}
function Dark:applyPowers()
	self.value = math.max(0,6+self:getFocusAmount())
end

function Dark:drawNumbers()
	local text = tostring(self.evokeValue)
	printGlowed(text,self.x+4-strWidth(text,false,true)/2,self.y,10,15,1,true)
	text = tostring(self.value)
	printGlowed(text,self.x+4-strWidth(text,false,true)/2,self.y-7,12,15,1,true)
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
			addAction(1,DamageAction:new{source=self.owner,target=target,value=evokeValue,type='power'})
		end)
	}
end

function Dark:onPassive()
	local value = self.value
	return { AnonymousAction:new(function () self.evokeValue = self.evokeValue + value end) }
end

function Dark:onTurnEnd()
	for _,action in ipairs(self:onPassive()) do
		addAction(action)
	end
end

Plasma = Orb:new{icon=icons.Plasma,value=1,evokeValue=2}
function Plasma:drawNumbers()
	if self.evoking then
		local text = tostring(self.evokeValue)
		printGlowed(text,self.x+4-strWidth(text,false,true)/2,self.y,10,15,1,true)
	end
end

function Plasma:onEvoke()
	return { GainEnergyAction:new(self.evokeValue) }
end

function Plasma:onPassive()
	return { GainEnergyAction:new(self.value) }
end

function Plasma:onTurnStart()
	for _,action in ipairs(self:onPassive()) do
		addAction(action)
	end
end

-- cards

BlueCard = Card:new{color={9,15},typeIconColor=11,colorName='blue',channelCount=0,evokeCount=0}

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

ReboundPower = Power:new{icon=249}
function ReboundPower:onUseCard(_,_,action)
	action.rebound = true
	addAction(ReducePowerAction:new(self,1))
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

blueCards = {
	StrikeBlue,DefendBlue,Zap,Dualcast,BallLightning,Barrage,BeamCell,ChargeBattery,Claw,ColdSnap,CompileDriver,
	Coolheaded,GoForTheEyes,Hologram,Leap,Rebound,Recursion,Stack,SteamBarrier,Streamline,SweepingBeam,Turbo,
}

-- relics
CrackedCore = Relic:new{ name='Cracked Core',tier='basic',icon=243,description='At the start of each combat, channel 1 {Lightning}.' }
function CrackedCore:onCombatStart()
	addAction(ChannelAction:new(Lightning:new{owner=player}))
end
