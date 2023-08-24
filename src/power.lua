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
	owner=nil,amount=0,stackable=true,debuff=false,turnBased=false,maxAmount=999,icon=40,iconflip=0,iconColorMap={},priority=100,
	onTurnStart=noop,
	onTurnEnd=noop,
	onAttacked=function(self,damage,source,card) return damage end,
	onAttack=function(self,damage,target,card) return damage end,
	onAmountUpdated=noop,
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
	for key,value in pairs(self.iconColorMap) do
		mapColor(key,value)
	end
	spr(self.icon,x,y,0,1,self.iconflip)
	for key,_ in pairs(self.iconColorMap) do
		resetColor(key)
	end
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

VulnerablePower = TurnBasedPower:new{debuff=true,icon=60}
function VulnerablePower:onAttacked(damage)
	return damage * self.owner:triggerReducerEvent('onModifyVulnerableFactor',1.5)
end

RitualPower = Power:new{icon=73,skipFirst=false}
function RitualPower:onTurnEnd()
	if self.skipFirst then
		self.skipFirst = false
		return
	end
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

DexterityPower = PositiveBuffNegativeDebuffPower:new{icon=1}
function DexterityPower:onModifyBlock(block)
	return block + self.amount
end

WeakPower = TurnBasedPower:new{debuff=true,icon=61,priority=150}
function WeakPower:onAttack(damage)
	return damage * 0.75
end

FrailPower = TurnBasedPower:new{debuff=true,icon=75,priority=150}
function FrailPower:onModifyBlock(block)
	return block * 0.75
end

LoseStrengthPower = Power:new{debuff=true,icon=14}
function LoseStrengthPower:onTurnEnd()
	addAction(ApplyPowerAction:new(StrengthPower:new(self.owner,-self.amount)))
	addAction(ReducePowerAction:new(self,self.amount))
end

NoDrawPower = Power:new{debuff=true,icon=15,stackable=false}
function NoDrawPower:onTurnEnd()
	addAction(ReducePowerAction:new(self,self.amount))
end

MetallicizePower = Power:new{icon=46,iconColorMap={[13]=12,[14]=13,[15]=14}}
function MetallicizePower:onTurnEnd()
	addAction(GainBlockAction:new{target=self.owner,value=self.amount})
end

BarricadePower = Power:new{icon=18,stackable=false}
function BarricadePower:onBeforeTurnStartLoseBlock(block)
	return 0
end

MinionPower = Power:new{icon=21,stackable=false}

ArtifactPower = Power:new{icon=22}
function ArtifactPower:onBeforeApplyPower(power)
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
