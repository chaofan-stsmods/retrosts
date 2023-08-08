-- exordium-monsters
---@diagnostic disable: lowercase-global

Cultist = Monster:new{ maxHp=51,width=4,height=4,ritual=3 }
function Cultist:init(random)
	self.maxHp = ascension >= 7 and random:randInt(50,56) or random:randInt(48,54)
	if ascension >= 17 then
		self.ritual = 5
	elseif ascension >= 2 then
		self.ritual = 4
	end
end

function Cultist:drawImage()
	sprmap(5,17,self.width,self.height,self.x,self.y,0)
end

function Cultist:buff()
	local power = RitualPower:new(self,self.ritual)
	power.skipFirst = true
	addAction(ApplyPowerAction:new(power))
	addAction(SetIntentAction:new(self,'attack','attack',6,1))
end

function Cultist:attack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(SetIntentAction:new(self,'attack','attack',6,1))
end

function Cultist:nextIntent()
	self:setIntent('buff','buff')
end

LouseNormal = Monster:new{ maxHp=10,width=4,height=2,curlUp=4,dmg=7 }
function LouseNormal:init(random)
	self.maxHp = ascension >= 7 and random:randInt(11,16) or random:randInt(10,15)
	if ascension >= 17 then
		self.dmg,self.curlUp = random:randInt(6,8),random:randInt(9,12)
	elseif ascension >= 2 then
		self.dmg,self.curlUp = random:randInt(6,8),random:randInt(4,8)
	else
		self.dmg,self.curlUp = random:randInt(5,7),random:randInt(3,7)
	end
end

function LouseNormal:onCombatStart()
	addAction(ApplyPowerAction:new(CurlUpPower:new(self,self.curlUp)))
	Monster.onCombatStart(self)
end

function LouseNormal:drawImage()
	sprmap(9,17,2,self.height,self.x+8,self.y,0)
end

function LouseNormal:buff()
	addAction(ApplyPowerAction:new(StrengthPower:new(self,ascension >= 17 and 4 or 3)))
	addAction(NextIntentAction:new(self))
end

function LouseNormal:attack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function LouseNormal:nextIntent()
	self:rollIntent({
		{'attack','attack',self.dmg,power=75,limit=2},
		{'buff','buff',power=25,limit=ascension >= 17 and 1 or 2},
	})
end

LouseDefensive = LouseNormal:new{ maxHp=10,width=4,height=2,curlUp=4,dmg=7 }
function LouseDefensive:init(random)
	LouseNormal.init(self,random)
	if ascension >= 7 then
		self.maxHp = random:randInt(12,18)
	else
		self.maxHp = random:randInt(11,17)
	end
end

function LouseDefensive:drawImage()
	sprmap(9,19,1,1,self.x+8,self.y+8,0)
	mapColor(4,5)
	mapColor(2,6)
	sprmap(10,19,1,1,self.x+16,self.y+8,0)
	resetColors{2,4}
end

function LouseDefensive:debuff()
	addAction(ApplyPowerAction:new(WeakPower:new(player,2,true)))
	addAction(NextIntentAction:new(self))
end

function LouseDefensive:nextIntent()
	self:rollIntent({
		{'attack','attack',self.dmg,power=75,limit=2},
		{'debuff','debuff',power=25,limit=ascension >= 17 and 1 or 2},
	})
end

CurlUpPower = Power:new{icon=448}
function CurlUpPower:onHpLoss()
	addAction(GainBlockAction:new{target=self.owner,value=self.amount})
	addAction(ReducePowerAction:new(self,self.amount))
end

JawWorm = Monster:new{ maxHp=10,width=4,height=3,bellowStr=3,bellowBlock=6,chompDmg=11,thrashDmg=7,thrashBlock=5 }
function JawWorm:init(random)
	self.maxHp = ascension >= 7 and random:randInt(42,46) or random:randInt(40,44)
	if ascension >= 17 then
		self.bellowStr,self.bellowBlock,self.chompDmg = 5,9,12
	elseif ascension >= 2 then
		self.bellowStr,self.bellowBlock,self.chompDmg = 4,6,12
	else
		self.bellowStr,self.bellowBlock,self.chompDmg = 3,6,11
	end
end

function JawWorm:onCombatStart()
	if act.id > 1 then
		addAction(ApplyPowerAction:new(StrengthPower:new(self,self.bellowStr)))
		addAction(GainBlockAction:new{target=self,value=self.bellowBlock})
	end
	Monster.onCombatStart(self)
end

function JawWorm:drawImage()
	sprmap(11,17,self.width,self.height,self.x,self.y,0)
end

function JawWorm:thrash()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(GainBlockAction:new{target=self,value=self.thrashBlock})
	addAction(NextIntentAction:new(self))
end

function JawWorm:bellow()
	addAction(ApplyPowerAction:new(StrengthPower:new(self,self.bellowStr)))
	addAction(GainBlockAction:new{target=self,value=self.bellowBlock})
	addAction(NextIntentAction:new(self))
end

function JawWorm:chomp()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function JawWorm:nextIntent(first)
	if first and act.id <= 1 then
		self:setIntent('chomp','attack',self.chompDmg)
		return
	end

	self:rollIntent({
		{'chomp','attack',self.chompDmg,power=25,limit=1},
		{'thrash','attackDefend',self.thrashDmg,power=30,limit=2},
		{'bellow','defendBuff',power=45,limit=1},
	})
end

SpikeSlimeS = Monster:new{ maxHp=10,width=4,height=2,dmg=5 }
function SpikeSlimeS:init(random)
	self.maxHp = ascension >= 7 and random:randInt(11,15) or random:randInt(10,14)
	self.dmg = ascension >= 2 and 6 or 5
end

function SpikeSlimeS:drawImage()
	sprmap(15,17,2,1,self.x+8,self.y+8,0)
end

function SpikeSlimeS:attack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function SpikeSlimeS:nextIntent()
	self:setIntent('attack','attack',self.dmg)
end

SpikeSlimeM = Monster:new{ maxHp=10,width=4,height=2,dmg=5 }
function SpikeSlimeM:init(random)
	self.maxHp = ascension >= 7 and random:randInt(29,34) or random:randInt(28,32)
	self.dmg = ascension >= 2 and 10 or 8
end

function SpikeSlimeM:drawImage()
	sprmap(17,17,3,2,self.x+4,self.y,0)
end

function SpikeSlimeM:attack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(MakeTempCardToDiscardPileAction:new(Slimed:new(),1))
	addAction(NextIntentAction:new(self))
end

function SpikeSlimeM:debuff()
	addAction(ApplyPowerAction:new(FrailPower:new(player,1,true)))
	addAction(NextIntentAction:new(self))
end

function SpikeSlimeM:nextIntent()
	self:rollIntent({
		{'attack','attackDebuff',self.dmg,power=30,limit=2},
		{'debuff','debuff',power=70,limit=ascension >= 17 and 1 or 2},
	})
end

AcidSlimeS = Monster:new{ maxHp=10,width=4,height=2,dmg=3 }
function AcidSlimeS:init(random)
	self.maxHp = ascension >= 7 and random:randInt(9,13) or random:randInt(8,12)
	self.dmg = ascension >= 2 and 4 or 3
end

function AcidSlimeS:drawImage()
	sprmap(15,18,2,1,self.x+8,self.y+8,0)
end

function AcidSlimeS:attack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(SetIntentAction:new(self,'debuff','debuff'))
end

function AcidSlimeS:debuff()
	addAction(ApplyPowerAction:new(WeakPower:new(player,1,true)))
	addAction(SetIntentAction:new(self,'attack','attack',self.dmg))
end

function AcidSlimeS:nextIntent()
	if ascension >= 17 then
		self:setIntent('debuff','debuff')
	else
		self:rollIntent({
			{'attack','attack',self.dmg,power=50},
			{'debuff','debuff',power=50},
		})
	end
end

AcidSlimeM = Monster:new{ maxHp=10,width=4,height=2,attackDmg=10,woundDmg=7 }
function AcidSlimeM:init(random)
	self.maxHp = ascension >= 7 and random:randInt(29,34) or random:randInt(28,32)
	self.woundDmg = ascension >= 2 and 8 or 7
	self.attackDmg = ascension >= 2 and 12 or 10
end

function AcidSlimeM:drawImage()
	sprmap(17,19,3,2,self.x+4,self.y,0)
end

function AcidSlimeM:attack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function AcidSlimeM:wound()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(MakeTempCardToDiscardPileAction:new(Slimed:new(),1))
	addAction(NextIntentAction:new(self))
end

function AcidSlimeM:debuff()
	addAction(ApplyPowerAction:new(WeakPower:new(player,1,true)))
	addAction(NextIntentAction:new(self))
end

function AcidSlimeM:nextIntent()
	if ascension >= 17 then
		self:rollIntent({
			{'wound','attackDebuff',self.woundDmg,power=40,limit=2},
			{'attack','attack',self.attackDmg,power=40,limit=2},
			{'debuff','debuff',power=20,limit=1},
		})
	else
		self:rollIntent({
			{'wound','attackDebuff',self.woundDmg,power=30,limit=2},
			{'attack','attack',self.attackDmg,power=40,limit=1},
			{'debuff','debuff',power=30,limit=2},
		})
	end
end

FungiBeast = Monster:new{ maxHp=24,width=4,height=3,dmg=6,strAmt=3 }
function FungiBeast:init(random)
	self.maxHp = ascension >= 7 and random:randInt(24,28) or random:randInt(22,28)
	if ascension >= 17 then
		self.strAmt = 5
	elseif ascension >= 2 then
		self.strAmt = 4
	end
end

function FungiBeast:onCombatStart()
	addAction(ApplyPowerAction:new(SporeCloudPower:new(self,2)))
	Monster.onCombatStart(self)
end

function FungiBeast:drawImage()
	sprmap(20,17,self.width,self.height,self.x,self.y,0)
end

function FungiBeast:attack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function FungiBeast:buff()
	addAction(ApplyPowerAction:new(StrengthPower:new(self,self.strAmt)))
	addAction(NextIntentAction:new(self))
end

function FungiBeast:nextIntent()
	self:rollIntent({
		{'attack','attack',self.dmg,power=60,limit=2},
		{'buff','buff',power=40,limit=1},
	})
end

SporeCloudPower = Power:new{icon=449}
function SporeCloudPower:onDeath()
	addAction(ApplyPowerAction:new(VulnerablePower:new(player,self.amount)))
end


-- encounters
CultistEncounter = Encounter:new{spriteBank=1,name='Cultist',enemyInfo={encItem(Cultist)}}
TwoLouseEncounter = Encounter:new{spriteBank=1,name='TwoLouse',enemyInfo={}}
function TwoLouseEncounter:setupEnemies(random)
	self.enemyInfo = {}
	self.enemyInfo[1] = random:randBool() and encItem(LouseNormal,-24,0) or encItem(LouseDefensive,-24,0)
	self.enemyInfo[2] = random:randBool() and encItem(LouseNormal,24,0) or encItem(LouseDefensive,24,0)
	Encounter.setupEnemies(self,random)
end
JawWormEncounter = Encounter:new{spriteBank=1,name='JawWorm',enemyInfo={encItem(JawWorm)}}
SmallSlimesEncounter = Encounter:new{spriteBank=1,name='SmallSlimes',enemyInfo={}}
function SmallSlimesEncounter:setupEnemies(random)
	if random:randBool() then
		self.enemyInfo = {encItem(AcidSlimeS,-24,0),encItem(SpikeSlimeM,24,0)}
	else
		self.enemyInfo = {encItem(SpikeSlimeS,-24,0),encItem(AcidSlimeM,24,0)}
	end
	Encounter.setupEnemies(self,random)
end
LotsOfSlimesEncounter = Encounter:new{spriteBank=1,name='LotsOfSlimes',enemyInfo={}}
function LotsOfSlimesEncounter:setupEnemies(random)
	local enemies = {AcidSlimeS,AcidSlimeS,SpikeSlimeS,SpikeSlimeS,SpikeSlimeS}
	random:shuffle(enemies)
	self.enemyInfo = {}
	self.enemyInfo[1] = encItem(enemies[1],-70,-5)
	self.enemyInfo[2] = encItem(enemies[2],-40,5)
	self.enemyInfo[3] = encItem(enemies[3],-10,-5)
	self.enemyInfo[4] = encItem(enemies[4],20,5)
	self.enemyInfo[5] = encItem(enemies[5],50,-5)
	Encounter.setupEnemies(self,random)
end
ThreeLouseEncounter = Encounter:new{spriteBank=1,name='ThreeLouse',enemyInfo={}}
function ThreeLouseEncounter:setupEnemies(random)
	self.enemyInfo = {}
	self.enemyInfo[1] = random:randBool() and encItem(LouseNormal,-44,0) or encItem(LouseDefensive,-44,0)
	self.enemyInfo[2] = random:randBool() and encItem(LouseNormal,0,0) or encItem(LouseDefensive,0,0)
	self.enemyInfo[3] = random:randBool() and encItem(LouseNormal,44,0) or encItem(LouseDefensive,44,0)
	Encounter.setupEnemies(self,random)
end
TwoFungiBeastEncounter = Encounter:new{spriteBank=1,name='TwoFungiBeast',enemyInfo={encItem(FungiBeast,-24,0),encItem(FungiBeast,24,0)}}
