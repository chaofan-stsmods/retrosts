-- city-monsters
---@diagnostic disable: lowercase-global

CorruptHeart = Monster:new{ maxHp=750,width=8,height=7,bashDmg=40,bloodHitCount=12,numAttacked=0,numBuffed=0 }
function CorruptHeart:init()
	self.maxHp = ascension >= 9 and 800 or 750
	if ascension >= 4 then
		self.bashDmg = 45
		self.bloodHitCount = 15
	end
end

function CorruptHeart:drawImage()
	sprmap(62,17,9,10,self.x,self.y-24,0)
end

function CorruptHeart:onCombatStart()
	addAction(ApplyPowerAction:new(InvinciblePower:new(self,ascension>=19 and 200 or 300)))
	addAction(ApplyPowerAction:new(BeatOfDeathPower:new(self,ascension>=19 and 2 or 1)))
	Monster.onCombatStart(self)
end

function CorruptHeart:debuff()
	addAction(ApplyPowerAction:new(VulnerablePower:new(player,2,true)))
	addAction(ApplyPowerAction:new(WeakPower:new(player,2,true)))
	addAction(ApplyPowerAction:new(FrailPower:new(player,2,true)))
	addAction(MakeTempCardToDrawPileAction:new(Dazed:new(),1,{pauseDuration=40,cardPosition=4}))
	addAction(MakeTempCardToDrawPileAction:new(Slimed:new(),1,{pauseDuration=35,cardPosition=2}))
	addAction(MakeTempCardToDrawPileAction:new(Wound:new(),1,{pauseDuration=30,cardPosition=1}))
	addAction(MakeTempCardToDrawPileAction:new(Burn:new(),1,{pauseDuration=25,cardPosition=3}))
	addAction(MakeTempCardToDrawPileAction:new(Void:new(),1,{pauseDuration=20,cardPosition=5}))
	addAction(NextIntentAction:new(self))
end

function CorruptHeart:bash()
	self.numAttacked = self.numAttacked + 1
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function CorruptHeart:bloodHit()
	self.numAttacked = self.numAttacked + 1
	for _=1,self.intentAttackCount do
		addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	end
	addAction(NextIntentAction:new(self))
end

function CorruptHeart:buff()
	self.numAttacked = 0
	self.numBuffed = self.numBuffed + 1
	local strPower = self:getPower(StrengthPower)
	local strAmt = 2 + (strPower and strPower.amount < 0 and -strPower.amount or 0)
	addAction(ApplyPowerAction:new(StrengthPower:new(self,strAmt)))
	if self.numBuffed == 1 then
		addAction(ApplyPowerAction:new(ArtifactPower:new(self,2)))
	elseif self.numBuffed == 2 then
		addAction(ApplyPowerAction:new(BeatOfDeathPower:new(self,1)))
	elseif self.numBuffed == 3 then
		addAction(ApplyPowerAction:new(PainfulStabsPower:new(self)))
	elseif self.numBuffed == 4 then
		addAction(ApplyPowerAction:new(StrengthPower:new(self,10)))
	else
		addAction(ApplyPowerAction:new(StrengthPower:new(self,50)))
	end
end

function CorruptHeart:nextIntent(first)
	if first then
		self:setIntent('debuff','strongDebuff')
		return
	end
	if self.numAttacked == 0 then
		self:rollIntent{
			{'bash','attack',self.bashDmg,power=50},
			{'bloodHit','attack',2,self.bloodHitCount,power=50},
		}
	elseif self.numAttacked == 1 then
		if self:lastIntentIs('bash') then
			self:setIntent('bloodHit','attack',2,self.bloodHitCount)
		else
			self:setIntent('bash','attack',self.bashDmg)
		end
	else
		self:setIntent('buff','buff')
	end
end

InvinciblePower = Power:new{icon=430}
function InvinciblePower:new(owner,amount)
	local result = Power.new(self,owner,amount)
	result.initialAmount = amount
	return result
end

function InvinciblePower:onTurnStart()
	self.amount = self.initialAmount
end

function InvinciblePower:onBeforeHpLoss(value)
	if self.amount > value then
		self.amount = self.amount - value
		return value
	else
		value = math.min(value,self.amount)
		self.amount = 0
		if value == 0 then
			addEffect(TextEffect:new{x=self.owner.x+self.owner.width*4,y=self.owner.y,text='Blocked',color=12,ySpeed=-0.5})
		end
		return value
	end
end

BeatOfDeathPower = Power:new{icon=431}
function BeatOfDeathPower:onUseCard()
	addAction(DamageAction:new{target=player,source=self.owner,value=self.amount,type='power'})
end

-- encounters
CorruptHeartEncounter = Encounter:new{spriteBank=5,name='CorruptHeart',enemyInfo={encItem(CorruptHeart,0,4)},mapIcon=332}
