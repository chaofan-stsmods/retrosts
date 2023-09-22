---@diagnostic disable: lowercase-global
-- powers

local function isCreature(obj)
	local objType = getmetatable(obj)
	for i = 1,3 do
		if objType == Creature then
			return true
		elseif objType == nil or type(objType) ~= 'table' then
			return false
		end
		objType = getmetatable(objType)
	end
	return false
end

allPowers = {}

Power = Object:new{
	owner=nil,amount=0,stackable=true,debuff=false,turnBased=false,maxAmount=999,icon=40,priority=100,
	hpReductColor=nil,onAmountUpdated=noop,
}
function Power:new(owner,amount)
	local result
	if amount == nil and not isCreature(owner) then
		result = Object.new(self,owner)
		table.insert(allPowers,result)
	else
		result = Object.new(self,{owner=owner,amount=amount or 1})
	end
	result:onAmountUpdated(0)
	return result
end

function Power:drawImage(x,y)
	drawIcon(self.icon,x,y)
	if self.stackable and self.amount ~= 0 then
		local color = self.turnBased and 12 or (self.amount > 0 and 5 or 3)
		local glowColor = self.turnBased and 15 or (self.amount > 0 and 7 or 1)
		local left = self.amount > 0 and x+5 or x+1
		local width = printGlowed(tostring(self.amount),left,y+3,color,glowColor,1,true)
		return left+width-x
	else
		return 8
	end
end

function Power:stackPower(power)
	self:setAmount(self.amount + power.amount)
end

function Power:setAmount(newAmount)
	local oldAmount = self.amount
	self.amount = limit(newAmount,-self.maxAmount,self.maxAmount)
	self:onAmountUpdated(self.amount - oldAmount)
end

TurnBasedPower = Power:new{turnBased=true}
function TurnBasedPower:new(owner,amount,keepForOneTurn)
	if amount == nil then
		return Power.new(self,owner)
	end
	local r = Power.new(self,owner,amount)
	r.keepForOneTurn = keepForOneTurn or false
	return r
end

function TurnBasedPower:onRoundEnd()
	if self.keepForOneTurn then
		self.keepForOneTurn = false
		return
	end
	addAction(ReducePowerAction:new(self,1))
end

VulnerablePower = TurnBasedPower:new{
	debuff=true,icon=icons.Vulnerable,priority=150,description='Receive #11#50%#12# more damage from {Attack} for #11#!A!#12# turn{s}.'
}
function VulnerablePower:onAttacked(damage,source)
	return damage * source:triggerReducerEvent('modifyVulnerableFactor',self.owner:triggerReducerEvent('modifyVulnerableFactor',1.5),true)
end

RitualPower = Power:new{icon=73,skipFirst=false,description='At the end of turn, gain #11#!A!#12# {Strength}.'}
function RitualPower:onTurnEnd()
	if self.skipFirst then
		self.skipFirst = false
		return
	end
	addAction(ApplyPowerAction:new(self.owner,StrengthPower:new(self.owner,self.amount)))
end

PositiveBuffNegativeDebuffPower = Power:new()
function PositiveBuffNegativeDebuffPower:onAmountUpdated()
	self.debuff = self.amount < 0
	if self.debuff then
		self.description = self.negativeDescription
	else
		self.description = self.positiveDescription
	end
end

StrengthPower = PositiveBuffNegativeDebuffPower:new{
	icon=icons.Strength,positiveDescription='Increases damage from {Attack} by #11#!A!#12#.',
	negativeDescription='Decreases damage from {Attack} by #11#!A!#12#.'
}
function StrengthPower:onAttack(damage)
	return damage + self.amount
end

DexterityPower = PositiveBuffNegativeDebuffPower:new{
	icon=icons.Dexterity,positiveDescription='Increases {Block} gained from cards by #11#!A!#12#.',
	negativeDescription='Decreases {Block} gained from cards by #11#!A!#12#.'
}
function DexterityPower:modifyBlock(block)
	return block + self.amount
end

FocusPower = PositiveBuffNegativeDebuffPower:new{
	icon=icons.Focus,positiveDescription='Increases the effectiveness of orbs by #11#!A!#12#.',
	negativeDescription='Decreases the effectiveness of orbs by #11#!A!#12#.'
}

WeakPower = TurnBasedPower:new{
	debuff=true,icon=icons.Weak,priority=150,description='{Attack} deal #11#25%#12# less damage for #11#!A!#12# turn{s}.'
}
function WeakPower:onAttack(damage,target)
	local factor = 0.75
	if target then
		factor = target:triggerReducerEvent('modifyWeakFactor',factor)
	end
	return damage * factor
end

FrailPower = TurnBasedPower:new{
	debuff=true,icon=icons.Frail,priority=150,description='Gain #11#25%#12# less {Block} from cards for #11#!A!#12# turn{s}.'
}
function FrailPower:modifyBlock(block)
	return block * 0.75
end

LoseStrengthPower = Power:new{debuff=true,icon=59,description='At the end of this turn, lose #11#!A!#12# {Strength}.'}
function LoseStrengthPower:onTurnEnd()
	addAction(ApplyPowerAction:new(self.owner,StrengthPower:new(self.owner,-self.amount)))
	addAction(RemovePowerAction:new(self))
end

LoseDexterityPower = Power:new{debuff=true,icon=59,description='At the end of this turn, lose #11#!A!#12# {Dexterity}.'}
function LoseDexterityPower:onTurnEnd()
	addAction(ApplyPowerAction:new(self.owner,DexterityPower:new(self.owner,-self.amount)))
	addAction(RemovePowerAction:new(self))
end

NoDrawPower = Power:new{debuff=true,icon=15,stackable=false,description='You cannot draw cards this turn.'}
function NoDrawPower:onTurnEnd()
	addAction(RemovePowerAction:new(self))
end

MetallicizePower = Power:new{icon=icons.Metallicize,description='At the end of turn, gain #11#!A!#12# {Block}.'}
function MetallicizePower:onTurnEnd()
	addAction(GainBlockAction:new{target=self.owner,value=self.amount})
end

BarricadePower = Power:new{icon=18,stackable=false,description='{Block} is not removed at the start of turn.'}
function BarricadePower:onBeforeTurnStartLoseBlock(block)
	return 0
end

MinionPower = Power:new{icon=21,stackable=false,description='Minions abandon combat without their leader.'}

ArtifactPower = Power:new{icon=22,description='Negates #11#!A!#12# debuff{s}.'}
function ArtifactPower:onBeforeGainPower(power)
	if power.debuff then
		addAction(1,ReducePowerAction:new(self,1))
		local owner = self.owner
		addEffect(TextEffect:new{x=owner.x+owner.width*4,y=owner.y,text='Negated',color=12,ySpeed=-0.5})
		return false
	end
end

RegenerateMonsterPower = Power:new{icon=13,description='At the end of turn, heals #11#!A!#12# HP.'}
function RegenerateMonsterPower:onTurnEnd()
	addAction(HealAction:new{target=self.owner,value=self.amount})
end

RegeneratePlayerPower = Power:new{icon=13,turnBased=true,description='At the end of turn, heals #11#!A!#12# HP, then reduce by #11#1#12#.'}
function RegeneratePlayerPower:onTurnEnd()
	addAction(HealAction:new{target=self.owner,value=self.amount})
	addAction(ReducePowerAction:new(self,1))
end

PlatedArmorPower = Power:new{icon=62,description='At the end of turn, gain #11#!A!#12# {Block}. Receiving unblocked damage from {Attack} reduces {62} by #11#1#12#.'}
function PlatedArmorPower:onTurnEnd()
	addAction(GainBlockAction:new{target=self.owner,value=self.amount})
end

function PlatedArmorPower:onDamaged(value,source,type)
	if value > 0 and type == 'attack' and source ~= self.owner then
		addAction(ReducePowerAction:new(self,1))
	end
end

ConfusionPower = Power:new{icon=36,stackable=false,debuff=true,description='Whenever you draw a card, randomize its cost.'}
function ConfusionPower:onDraw(card)
	if card.baseCost >= 0 then
		local newCost = miscRand:randInt(0,3)
		card.costForOneTurnPlay = nil
		card.costForOnePlay = nil
		if newCost ~= card.baseCost then
			card.baseCost = newCost
			card.baseCostModified = true
		end
		player:triggerEvent('onConfused',card)
		card:applyPowers()
	end
end

ShackledPower = Power:new{icon=9,description='At the end of this turn, gain #11#!A!#12# {Strength}.'}
function ShackledPower:onTurnEnd()
	addAction(ApplyPowerAction:new(self.owner,StrengthPower:new(self.owner,self.amount)))
	addAction(RemovePowerAction:new(self))
end

VigorPower = Power:new{icon=253,description='Next {Attack} deals #11#!A!#12# additional damage.'}
function VigorPower:onAttack(damage)
	return damage + self.amount
end

function VigorPower:onUseCard(card)
	if card.type == 'attack' then
		addAction(RemovePowerAction:new(self))
	end
end

ThornsPower = Power:new{icon=29,description='When attacked, {Damage} #11#!A!#12# back.'}
function ThornsPower:onDamaged(_,source,type)
	if type == 'attack' then
		addAction(1,DamageAction:new{source=self.owner,target=source,value=self.amount,type='power'})
	end
end

GainBlockNextTurnPower = Power:new{icon=14,description='Gain #11#!A!#12# {Block} next turn.'}
function GainBlockNextTurnPower:onTurnStart()
	addAction(GainBlockAction:new{target=self.owner,value=self.amount})
	addAction(RemovePowerAction:new(self))
end

DrawCardNextTurnPower = Power:new{icon=icons.DrawCardNextTurn,description='Draw #11#!A!#12# additional card{s} next turn.'}
function DrawCardNextTurnPower:onTurnStart()
	addAction(DrawCardAction:new(self.amount))
	addAction(RemovePowerAction:new(self))
end

BufferPower = Power:new{
	icon=Icon:new{draw=function(self,x,y) for i=3,5 do rect(x+5-i,y+i-3,5,6,i) end end},
	description='Prevent the next !A! time{s} you would lose HP.'
}
function BufferPower:onBeforeHpLoss(value)
	if value > 0 then
		addAction(1,ReducePowerAction:new(self,1))
		local owner = self.owner
		addEffect(TextEffect:new{x=owner.x+owner.width*4,y=owner.y,text='Blocked',color=12,ySpeed=-0.5})
		return 0
	end
end

IntangiblePower = TurnBasedPower:new{icon=35,priority=200,description='Reduce all damage taken and HP loss to #11#1#12# for #11#!A!#12# turn{s}.'}
function IntangiblePower:onAttacked()
	return 1
end

function IntangiblePower:onBeforeDamaged()
	return 1
end

NoBlockPower = TurnBasedPower:new{icon=25,debuff=true,priority=200,description='You cannot gain {Block} from cards.'}
function NoBlockPower:modifyBlock()
	return 0
end
