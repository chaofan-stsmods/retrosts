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

Power = Object:new{
	owner=nil,amount=0,stackable=true,debuff=false,turnBased=false,maxAmount=999,icon=40,priority=100,
	hpReductColor=nil,onAmountUpdated=noop,
}
function Power:new(owner,amount)
	local result
	if amount == nil and not isCreature(owner) then
		result = Object.new(self,owner)
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
		--print(tostring(power.amount),left,y+3,color,false,1,true)
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

function TurnBasedPower:onTurnStart()
	if self.owner ~= player then
		return
	end
	if self.keepForOneTurn then
		self.keepForOneTurn = false
		return
	end
	addAction(ReducePowerAction:new(self,1))
end

function TurnBasedPower:onTurnEnd()
	if self.owner == player then
		return
	end
	if self.keepForOneTurn then
		self.keepForOneTurn = false
		return
	end
	addAction(ReducePowerAction:new(self,1))
end

VulnerablePower = TurnBasedPower:new{debuff=true,icon=icons.Vulnerable,priority=150}
function VulnerablePower:onAttacked(damage,source)
	return damage * source:triggerReducerEvent('modifyVulnerableFactor',self.owner:triggerReducerEvent('modifyVulnerableFactor',1.5),true)
end

RitualPower = Power:new{icon=73,skipFirst=false}
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
end

StrengthPower = PositiveBuffNegativeDebuffPower:new{icon=icons.Strength}
function StrengthPower:onAttack(damage)
	return damage + self.amount
end

DexterityPower = PositiveBuffNegativeDebuffPower:new{icon=icons.Dexterity}
function DexterityPower:modifyBlock(block)
	return block + self.amount
end

FocusPower = PositiveBuffNegativeDebuffPower:new{icon=icons.Focus}

WeakPower = TurnBasedPower:new{debuff=true,icon=icons.Weak,priority=150}
function WeakPower:onAttack(damage,target)
	local factor = 0.75
	if target then
		factor = target:triggerReducerEvent('modifyWeakFactor',factor)
	end
	return damage * factor
end

FrailPower = TurnBasedPower:new{debuff=true,icon=icons.Frail,priority=150}
function FrailPower:modifyBlock(block)
	return block * 0.75
end

LoseStrengthPower = Power:new{debuff=true,icon=59}
function LoseStrengthPower:onTurnEnd()
	addAction(ApplyPowerAction:new(self.owner,StrengthPower:new(self.owner,-self.amount)))
	addAction(RemovePowerAction:new(self))
end

LoseDexterityPower = Power:new{debuff=true,icon=59}
function LoseDexterityPower:onTurnEnd()
	addAction(ApplyPowerAction:new(self.owner,DexterityPower:new(self.owner,-self.amount)))
	addAction(RemovePowerAction:new(self))
end

NoDrawPower = Power:new{debuff=true,icon=15,stackable=false}
function NoDrawPower:onTurnEnd()
	addAction(RemovePowerAction:new(self))
end

MetallicizePower = Power:new{icon=icons.Metallicize}
function MetallicizePower:onTurnEnd()
	addAction(GainBlockAction:new{target=self.owner,value=self.amount})
end

BarricadePower = Power:new{icon=18,stackable=false}
function BarricadePower:onBeforeTurnStartLoseBlock(block)
	return 0
end

MinionPower = Power:new{icon=21,stackable=false}

ArtifactPower = Power:new{icon=22}
function ArtifactPower:onBeforeGainPower(power)
	if power.debuff then
		addAction(1,ReducePowerAction:new(self,1))
		local owner = self.owner
		addEffect(TextEffect:new{x=owner.x+owner.width*4,y=owner.y,text='Negated',color=12,ySpeed=-0.5})
		return false
	end
end

RegenerateMonsterPower = Power:new{icon=13}
function RegenerateMonsterPower:onTurnEnd()
	addAction(HealAction:new{target=self.owner,value=self.amount})
end

RegeneratePlayerPower = Power:new{icon=13,turnBased=true}
function RegeneratePlayerPower:onTurnEnd()
	addAction(HealAction:new{target=self.owner,value=self.amount})
	addAction(ReducePowerAction:new(self,1))
end

PlatedArmorPower = Power:new{icon=62}
function PlatedArmorPower:onTurnEnd()
	addAction(GainBlockAction:new{target=self.owner,value=self.amount})
end

function PlatedArmorPower:onDamaged(value,source,type)
	if value > 0 and type == 'attack' and source ~= self.owner then
		addAction(ReducePowerAction:new(self,1))
	end
end

ConfusionPower = Power:new{icon=36,stackable=false}
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

ShackledPower = Power:new{icon=9}
function ShackledPower:onTurnEnd()
	addAction(ApplyPowerAction:new(self.owner,StrengthPower:new(self.owner,self.amount)))
	addAction(RemovePowerAction:new(self))
end

VigorPower = Power:new{icon=253}
function VigorPower:onAttack(damage)
	return damage + self.amount
end

function VigorPower:onUseCard(card)
	if card.type == 'attack' then
		addAction(RemovePowerAction:new(self))
	end
end

ThornsPower = Power:new{icon=29}
function ThornsPower:onDamaged(_,source,type)
	if type == 'attack' then
		addAction(1,DamageAction:new{source=self.owner,target=source,value=self.amount,type='power'})
	end
end

GainBlockNextTurnPower = Power:new{icon=14}
function GainBlockNextTurnPower:onTurnStart()
	addAction(GainBlockAction:new{target=self.owner,value=self.amount})
	addAction(RemovePowerAction:new(self))
end

DrawCardNextTurnPower = Power:new{icon=icons.DrawCardNextTurn}
function DrawCardNextTurnPower:onTurnStart()
	addAction(DrawCardAction:new(self.amount))
	addAction(RemovePowerAction:new(self))
end

BufferPower = Power:new{icon=0}
function BufferPower:onBeforeHpLoss(value)
	if value > 0 then
		addAction(1,ReducePowerAction:new(self,1))
		local owner = self.owner
		addEffect(TextEffect:new{x=owner.x+owner.width*4,y=owner.y,text='Blocked',color=12,ySpeed=-0.5})
		return 0
	end
end

function BufferPower:drawImage(x,y)
	for i=3,5 do
		rect(x+5-i,y+i-3,5,6,i)
	end
	return Power.drawImage(self,x,y)
end

IntangiblePower = TurnBasedPower:new{icon=35,priority=200}
function IntangiblePower:onAttacked()
	return 1
end

function IntangiblePower:onBeforeDamaged()
	return 1
end

NoBlockPower = TurnBasedPower:new{icon=25,priority=200}
function NoBlockPower:modifyBlock()
	return 0
end
