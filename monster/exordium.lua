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
	rect(self.x+16,self.y+6,3,1,10)
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

CurlUpPower = Power:new{icon=448,triggered=false}
function CurlUpPower:onHpLoss()
	if not self.triggered then
		self.triggered = true
		addAction(GainBlockAction:new{target=self.owner,value=self.amount})
		addAction(ReducePowerAction:new(self,self.amount))
	end
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
	pix(self.x+16,self.y+6,10)
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

SpikeSlimeL = Monster:new{ maxHp=70,width=5,height=3,dmg=18,splitting=false }
function SpikeSlimeL:init(random)
	self.maxHp = ascension >= 7 and random:randInt(67,73) or random:randInt(64,70)
	self.dmg = ascension >= 2 and 18 or 16
	self:addPower(SplitPower:new(self))
end

function SpikeSlimeL:drawImage()
	sprmap(24,17,self.width,self.height,self.x,self.y,0)
end

function SpikeSlimeL:attack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(MakeTempCardToDiscardPileAction:new(Slimed:new(),2))
	addAction(NextIntentAction:new(self))
end

function SpikeSlimeL:debuff()
	addAction(ApplyPowerAction:new(FrailPower:new(player,ascension >= 17 and 3 or 2,true)))
	addAction(NextIntentAction:new(self))
end

function SpikeSlimeL:split()
	addAction(HideMonsterAction:new{target=self})
	local splitted1 = SpikeSlimeM:new{createRandom=self.createRandom,x=self.x-24,y=self.y+8}
	local splitted2 = SpikeSlimeM:new{createRandom=self.createRandom,x=self.x+24,y=self.y+8}
	splitted1.maxHp,splitted1.hp = self.hp,self.hp
	splitted2.maxHp,splitted2.hp = self.hp,self.hp
	addAction(SpawnMonsterAction:new{target=splitted1})
	addAction(SpawnMonsterAction:new{target=splitted2})
	addAction(SuicideAction:new{target=self})
end

function SpikeSlimeL:nextIntent()
	self:rollIntent({
		{'attack','attackDebuff',self.dmg,power=30,limit=2},
		{'debuff','debuff',power=70,limit=ascension >= 17 and 1 or 2},
	})
end

SplitPower = Power:new{icon=450,stackable=false}
function SplitPower:onDamaged()
	local owner = self.owner
	if owner.alive and not owner.splitting and owner.hp <= math.floor(owner.maxHp/2) then
		addAction(SetIntentAction:new(owner,'split','unknown',0,0,false))
		owner.splitting = true
	end
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

AcidSlimeL = Monster:new{ maxHp=10,width=5,height=3,attackDmg=10,woundDmg=7 }
function AcidSlimeL:init(random)
	self.maxHp = ascension >= 7 and random:randInt(68,72) or random:randInt(65,69)
	self.woundDmg = ascension >= 2 and 12 or 11
	self.attackDmg = ascension >= 2 and 18 or 16
	self:addPower(SplitPower:new(self))
end

function AcidSlimeL:drawImage()
	mapColor(13,5)
	mapColor(14,6)
	sprmap(24,20,self.width,self.height,self.x,self.y,0)
	resetColors{13,14}
end

function AcidSlimeL:attack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function AcidSlimeL:wound()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(MakeTempCardToDiscardPileAction:new(Slimed:new(),2))
	addAction(NextIntentAction:new(self))
end

function AcidSlimeL:debuff()
	addAction(ApplyPowerAction:new(WeakPower:new(player,2,true)))
	addAction(NextIntentAction:new(self))
end

function AcidSlimeL:split()
	addAction(HideMonsterAction:new{target=self})
	local splitted1 = AcidSlimeM:new{createRandom=self.createRandom,x=self.x-24,y=self.y+8}
	local splitted2 = AcidSlimeM:new{createRandom=self.createRandom,x=self.x+24,y=self.y+8}
	splitted1.maxHp,splitted1.hp = self.hp,self.hp
	splitted2.maxHp,splitted2.hp = self.hp,self.hp
	addAction(SpawnMonsterAction:new{target=splitted1})
	addAction(SpawnMonsterAction:new{target=splitted2})
	addAction(SuicideAction:new{target=self})
end

function AcidSlimeL:nextIntent()
	if ascension >= 17 then
		self:rollIntent({
			{'wound','attackDebuff',self.woundDmg,power=40,limit=2},
			{'attack','attack',self.attackDmg,power=30,limit=2},
			{'debuff','debuff',power=30,limit=1},
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
	addAction(ApplyPowerAction:new(VulnerablePower:new(player,self.amount,inEnemyTurn)))
end

SlaverBlue = Monster:new{ maxHp=50,width=4,height=4,stabDmg=12,rakeDmg=7 }
function SlaverBlue:init(random)
	self.maxHp = ascension >= 7 and random:randInt(48,52) or random:randInt(46,50)
	if ascension >= 2 then
		self.stabDmg,self.rakeDmg = 13,8
	end
end

function SlaverBlue:drawImage()
	sprmap(0,21,6,self.height,self.x-16,self.y,0)
	rect(self.x,self.y+21,8,1,13)
end

function SlaverBlue:stab()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function SlaverBlue:rake()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(ApplyPowerAction:new(WeakPower:new(player,ascension>=17 and 2 or 1,true)))
	addAction(NextIntentAction:new(self))
end

function SlaverBlue:nextIntent()
	self:rollIntent({
		{'stab','attack',self.stabDmg,power=60,limit=2},
		{'rake','attackDebuff',self.rakeDmg,power=40,limit=ascension>=17 and 1 or 2},
	})
end

SlaverRed = Monster:new{ maxHp=50,width=4,height=4,stabDmg=13,scrapeDmg=8,usedEntangle=false }
function SlaverRed:init(random)
	self.maxHp = ascension >= 7 and random:randInt(48,52) or random:randInt(46,50)
	if ascension >= 2 then
		self.stabDmg,self.scrapeDmg = 14,9
	end
end

function SlaverRed:drawImage()
	mapColor(9,2)
	mapColor(15,1)
	sprmap(6,21,7,self.height,self.x-16,self.y,0)
	rect(self.x-12,self.y+21,4,1,13)
	resetColors{9,15}
end

function SlaverRed:stab()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function SlaverRed:scrape()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(ApplyPowerAction:new(VulnerablePower:new(player,ascension>=17 and 2 or 1,true)))
	addAction(NextIntentAction:new(self))
end

function SlaverRed:entangle()
	self.usedEntangle = true
	addAction(ApplyPowerAction:new(EntanglePower:new(player,1,true)))
	addAction(NextIntentAction:new(self))
end

function SlaverRed:nextIntent(firstTurn)
	if firstTurn then
		self:setIntent('stab','attack',self.stabDmg)
	elseif not self.usedEntangle then
		if aiRand:randInt(0,99) < 25 then
			self:setIntent('entangle','strongDebuff')
		elseif not self:lastIntentIs('scrape') and (ascension < 17 or not self:lastTwoIntentsAre('scrape')) then
			self:setIntent('scrape','attackDebuff',self.scrapeDmg)
		else
			self:setIntent('stab','attack',self.stabDmg)
		end
	else
		self:rollIntent({
			{'stab','attack',self.stabDmg,power=55,limit=2},
			{'scrape','attackDebuff',self.scrapeDmg,power=45,limit=ascension>=17 and 1 or 2},
		})
	end
end

EntanglePower = TurnBasedPower:new{icon=451,debuff=true}
function EntanglePower:canUseCard(card)
	if card.type == 'attack' then
		return false
	end
end

Looter = Monster:new{ maxHp=50,width=4,height=4,swipeDmg=10,lungeDmg=12,goldAmt=15,swipeCount=0,blockAmt=6,goldStolen=0 }
function Looter:init(random)
	self.maxHp = ascension >= 7 and random:randInt(46,50) or random:randInt(44,48)
	if ascension >= 2 then
		self.swipeDmg,self.lungeDmg = 11,14
	end
	self.goldAmt = ascension >= 17 and 20 or 15
end

function Looter:onCombatStart()
	addAction(ApplyPowerAction:new(ThieveryPower:new(self,self.goldAmt)))
	Monster.onCombatStart(self)
end

function Looter:drawImage()
	if self.flipped then
		sprmap(13,21,3,self.height,self.x+8,self.y,0,1,flipRemap(13,3))
	else
		sprmap(13,21,3,self.height,self.x,self.y,0)
	end
end

function Looter:swipe()
	self.swipeCount = self.swipeCount+1
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(ThieveryAction:new{owner=self,amount=self.goldAmt})
	if self.swipeCount == 2 then
		if aiRand:rand() < 0.5 then
			addAction(SetIntentAction:new(self,'defend','defend'))
		else
			addAction(SetIntentAction:new(self,'lunge','attack',self.lungeDmg))
		end
	else
		addAction(SetIntentAction:new(self,'swipe','attack',self.swipeDmg))
	end
end

function Looter:lunge()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(ThieveryAction:new{owner=self,amount=self.goldAmt})
	addAction(SetIntentAction:new(self,'defend','defend'))
end

function Looter:defend()
	addAction(GainBlockAction:new{target=self,value=self.blockAmt})
	addAction(SetIntentAction:new(self,'escape','escape'))
end

function Looter:escape()
	self.goldStolen = 0
	addAction(EscapeAction:new{target=self})
end

function Looter:nextIntent()
	self:setIntent('swipe','attack',self.swipeDmg)
end

ThieveryPower = Power:new{icon=418}
ThieveryAction = Action:new{owner=nil,amount=15}
function ThieveryAction:tick()
	local amount = math.min(gold,self.amount)
	gold = gold - amount
	self.owner.goldStolen = self.owner.goldStolen + amount
	self.isDone = true
end

GremlinNob = Monster:new{ maxHp=90,width=5,height=6,bashDmg=6,rushDmg=14,usedBellow=false }
function GremlinNob:init(random)
	self.maxHp = ascension >= 8 and random:randInt(85,90) or random:randInt(82,86)
	if ascension >= 3 then
		self.bashDmg,self.rushDmg = 8,16
	end
end

function GremlinNob:drawImage()
	sprmap(19,21,self.width,self.height,self.x+10,self.y,0)
end

function GremlinNob:bellow()
	self.usedBellow = true
	addAction(ApplyPowerAction:new(AngerPower:new(self,ascension>=18 and 3 or 2)))
	addAction(NextIntentAction:new(self))
end

function GremlinNob:bash()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(ApplyPowerAction:new(VulnerablePower:new(player,2,true)))
	addAction(NextIntentAction:new(self))
end

function GremlinNob:rush()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function GremlinNob:nextIntent()
	if not self.usedBellow then
		self:setIntent('bellow','buff')
	elseif ascension >= 18 then
		if not self:oneOfLastTwoIntentsIs('bash') then
			self:setIntent('bash','attackDebuff',self.bashDmg)
		else
			self:setIntent('rush','attack',self.rushDmg)
		end
	else
		self:rollIntent({
			{'bash','attackDebuff',self.bashDmg,power=33},
			{'rush','attack',self.rushDmg,power=67,limit=2},
		})
	end
end

AngerPower = Power:new{icon=17}
function AngerPower:onUseCard(card)
	if card.type == 'skill' then
		addAction(ApplyPowerAction:new(StrengthPower:new(self.owner,self.amount)))
	end
end

GremlinThief = Monster:new{ maxHp=15,width=4,height=2,dmg=9 }
function GremlinThief:init(random)
	self.maxHp = ascension >= 7 and random:randInt(11,15) or random:randInt(10,14)
	if ascension >= 2 then
		self.dmg = 10
	end
end

function GremlinThief:drawImage()
	sprmap(0,29,2,2,self.x+8,self.y,0)
end

function GremlinThief:attack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function GremlinThief:nextIntent()
	self:setIntent('attack','attack',self.dmg)
end

GremlinFat = Monster:new{ maxHp=15,width=4,height=6,dmg=4 }
function GremlinFat:init(random)
	self.maxHp = ascension >= 7 and random:randInt(14,18) or random:randInt(13,17)
	if ascension >= 2 then
		self.dmg = 5
	end
end

function GremlinFat:drawImage()
	sprmap(11,28,2,6,self.x+8,self.y,0)
end

function GremlinFat:attack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(ApplyPowerAction:new(WeakPower:new(player,1,true)))
	if ascension >= 17 then
		addAction(ApplyPowerAction:new(FrailPower:new(player,1,true)))
	end
	addAction(NextIntentAction:new(self))
end

function GremlinFat:nextIntent()
	self:setIntent('attack','attackDebuff',self.dmg)
end

GremlinWarrior = Monster:new{ maxHp=15,width=4,height=3,dmg=4 }
function GremlinWarrior:init(random)
	self.maxHp = ascension >= 7 and random:randInt(21,25) or random:randInt(20,24)
	if ascension >= 2 then
		self.dmg = 5
	end
end

function GremlinWarrior:onCombatStart()
	addAction(ApplyPowerAction:new(AngryPower:new(self,ascension >= 17 and 2 or 1)))
	Monster.onCombatStart(self)
end

function GremlinWarrior:drawImage()
	sprmap(6,28,3,3,self.x+4,self.y,0)
end

function GremlinWarrior:attack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function GremlinWarrior:nextIntent()
	self:setIntent('attack','attack',self.dmg)
end

AngryPower = Power:new{icon=17}
function AngryPower:onDamaged(value,source,type)
	if value > 0 and source == player and type == 'attack' then
		addAction(1,ApplyPowerAction:new(StrengthPower:new(self.owner,self.amount)))
	end
end

GremlinWizard = Monster:new{ maxHp=22,width=4,height=3,dmg=25,numCharged=1 }
function GremlinWizard:init(random)
	self.maxHp = ascension >= 7 and random:randInt(22,26) or random:randInt(21,25)
	if ascension >= 2 then
		self.dmg = 30
	end
end

function GremlinWizard:drawImage()
	sprmap(2,29,4,3,self.x-4,self.y,0)
end

function GremlinWizard:charge()
	self.numCharged = self.numCharged + 1
	if self.numCharged == 3 then
		addAction(SetIntentAction:new(self,'attack','attack',self.dmg))
	else
		addAction(SetIntentAction:new(self,'charge','unknown'))
	end
end

function GremlinWizard:attack()
	self.numCharged = 0
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	if ascension >= 17 then
		addAction(SetIntentAction:new(self,'attack','attack',self.dmg))
	else
		addAction(SetIntentAction:new(self,'charge','unknown'))
	end
end

function GremlinWizard:nextIntent()
	self:setIntent('charge','unknown')
end

GremlinTsundere = Monster:new{ maxHp=15,width=4,height=4,dmg=6,blockAmt=7 }
function GremlinTsundere:init(random)
	self.maxHp = ascension >= 7 and random:randInt(13,17) or random:randInt(12,15)
	if ascension >= 17 then
		self.dmg = 8
		self.blockAmt = 11
	elseif ascension >= 2 then
		self.dmg = 8
		self.blockAmt = 8
	end
end

function GremlinTsundere:drawImage()
	sprmap(9,28,2,4,self.x+8,self.y,0)
end

function GremlinTsundere:defend()
	addAction(AnonymousAction:new(function ()
		local targets = shallowcopy(enemies)
		table.retainIf(targets,function(e) return e.alive and e ~= self end)
		local target
		if #targets > 0 then
			target = targets[aiRand:randInt(#targets)]
		else
			target = self
		end
		addAction(1,GainBlockAction:new{target=target,value=self.blockAmt})
	end))
	addAction(NextIntentAction:new(self))
end

function GremlinTsundere:attack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function GremlinTsundere:nextIntent()
	if table.count(enemies,function(e) return e.alive end) > 1 then
		self:setIntent('defend','defend')
	else
		self:setIntent('attack','attack',self.dmg)
	end
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
LargeSlimeEncounter = Encounter:new{spriteBank=1,name='LargeSlime',enemyInfo={}}
function LargeSlimeEncounter:setupEnemies(random)
	self.enemyInfo = {}
	self.enemyInfo[1] = random:randBool() and encItem(SpikeSlimeL) or encItem(AcidSlimeL)
	Encounter.setupEnemies(self,random)
end
SlaverBlueEncounter = Encounter:new{spriteBank=1,name='SlaverBlue',enemyInfo={encItem(SlaverBlue)}}
SlaverRedEncounter = Encounter:new{spriteBank=1,name='SlaverRed',enemyInfo={encItem(SlaverRed)}}
LooterEncounter = Encounter:new{spriteBank=1,name='Looter',enemyInfo={encItem(Looter)}}

local weakWildlife = {{item=LouseNormal,power=0.5},{item=LouseDefensive,power=0.5},{item=SpikeSlimeM,power=1},{item=AcidSlimeM,power=1}}
local strongHumanoid = {{item=SlaverBlue,power=0.5},{item=SlaverRed,power=0.5},{item=Cultist,power=1},{item=Looter,power=1}}
local strongWildlife = {{item=FungiBeast,power=1},{item=JawWorm,power=1}}
normalize(weakWildlife)
normalize(strongHumanoid)
normalize(strongWildlife)
ExordiumThugsEncounter = Encounter:new{spriteBank=1,name='ExordiumThugs',enemyInfo={}}
function ExordiumThugsEncounter:setupEnemies(random)
	self.enemyInfo = {}
	self.enemyInfo[1] = encItem(rollList(random,weakWildlife).item,-24,0)
	self.enemyInfo[2] = encItem(rollList(random,strongHumanoid).item,24,0)
	Encounter.setupEnemies(self,random)
end
ExordiumWildlifeEncounter = Encounter:new{spriteBank=1,name='ExordiumWildlife',enemyInfo={}}
function ExordiumWildlifeEncounter:setupEnemies(random)
	self.enemyInfo = {}
	self.enemyInfo[1] = encItem(rollList(random,strongWildlife).item,-24,0)
	self.enemyInfo[2] = encItem(rollList(random,weakWildlife).item,24,0)
	Encounter.setupEnemies(self,random)
end
GremlinGangEncounter = Encounter:new{spriteBank=3,name='GremlinGang',enemyInfo={}}
function GremlinGangEncounter:setupEnemies(random)
	local targets = {
		GremlinWarrior,GremlinWarrior,
		GremlinThief,GremlinThief,
		GremlinFat,GremlinFat,
		GremlinTsundere,
		GremlinWizard,
	}
	random:shuffle(targets)
	self.enemyInfo = {}
	self.enemyInfo[1] = encItem(targets[1],-62,2)
	self.enemyInfo[2] = encItem(targets[2],-20,-3)
	self.enemyInfo[3] = encItem(targets[3],22,-8)
	self.enemyInfo[4] = encItem(targets[4],52,8)
	Encounter.setupEnemies(self,random)
end

-- elite encounters
GremlinNobEncounter = Encounter:new{spriteBank=1,name='GremlinNob',enemyInfo={encItem(GremlinNob)}}
