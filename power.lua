---@diagnostic disable: lowercase-global
-- powers

Power = Object:new{
	owner=nil,amount=0,stackable=true,debuff=false,turnBased=false,maxAmount=999,icon=40,iconflip=0,priority=100,
	onTurnStart=noop,
	onTurnEnd=noop,
	onAttacked=function(self,damage,source,card) return damage end,
	onAttack=function(self,damage,target,card) return damage end,
	onAmountUpdated=noop,
}
function Power:new(owner,amount)
	local result
	if amount == nil then
		result = Object.new(self,owner)
	else
		result = Object.new(self,{owner=owner,amount=amount})
	end
	result:onAmountUpdated()
	return result
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
	if self.keepForOneTurn then
		self.keepForOneTurn = false
		return
	end
	addAction(ReducePowerAction:new(self,1))
end

VulnerablePower = TurnBasedPower:new{debuff=true,icon=60}
function VulnerablePower:onAttacked(damage)
	return damage * 1.5
end

RitualPower = Power:new{icon=73}
function RitualPower:onTurnEnd()
	addAction(ApplyPowerAction:new(StrengthPower:new(self.owner,self.amount)))
end

PositiveBuffNegativeDebuffPower = Power:new()
function PositiveBuffNegativeDebuffPower:onAmountUpdated()
	self.debuff = self.amount < 0
end

StrengthPower = PositiveBuffNegativeDebuffPower:new{icon=76,iconflip=1}
function StrengthPower:onAttack(damage)
	return damage + self.amount
end
