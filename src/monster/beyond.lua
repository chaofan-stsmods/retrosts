-- beyond monsters
---@diagnostic disable: lowercase-global

OrbWalker = Monster:new{ maxHp=96,width=6,height=3,laserDmg=10,clawDmg=15 }
function OrbWalker:init(random)
	self.maxHp = ascension >= 7 and random:randInt(92,102) or random:randInt(90,96)
	if ascension >= 2 then
		self.laserDmg = 11
		self.clawDmg = 16
	end
end

function OrbWalker:drawImage()
	sprmap(60,30,4,3,self.x+8,self.y,0)
	spr(261,self.x+40,self.y+12,0)
end

function OrbWalker:onCombatStart()
	addAction(ApplyPowerAction:new(self,StrengthUpPower:new(self,ascension>=17 and 5 or 3)))
	Monster.onCombatStart(self)
end

function OrbWalker:laser()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(MakeTempCardToDiscardPileAction:new(Burn:new(),1,{duration=1}))
	addAction(MakeTempCardToDrawPileAction:new(Burn:new()))
	addAction(NextIntentAction:new(self))
end

function OrbWalker:claw()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function OrbWalker:nextIntent()
	self:rollIntent({
		{'laser','attackDebuff',self.laserDmg,power=60,limit=2},
		{'claw','attack',self.clawDmg,power=40,limit=2},
	})
end

StrengthUpPower = Power:new{icon=265}
function StrengthUpPower:onTurnEnd()
	addAction(ApplyPowerAction:new(self.owner,StrengthPower:new(self.owner,self.amount)))
end

Darkling = Monster:new{ maxHp=56,width=4,height=3,chompDmg=8,nipDmg=7,canChomp=true }
function Darkling:init(random)
	self.maxHp = ascension >= 7 and random:randInt(50,59) or random:randInt(48,56)
	if ascension >= 2 then
		self.chompDmg = 9
		self.nipDmg = random:randInt(9,13)
	else
		self.nipDmg = random:randInt(7,11)
	end
end

function Darkling:drawImage()
	sprmap(74,27,5,3,self.x,self.y,8)
end

function Darkling:onCombatStart()
	addAction(ApplyPowerAction:new(self,LifeLinkPower:new(self)))
	Monster.onCombatStart(self)
end

function Darkling:chomp()
	for _=1,self.intentAttackCount do
		addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	end
	addAction(NextIntentAction:new(self))
end

function Darkling:nip()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function Darkling:defend()
	addAction(GainBlockAction:new{target=self,value=12})
	if ascension >= 17 then
		addAction(ApplyPowerAction:new(self,StrengthPower:new(self,1)))
	end
	addAction(NextIntentAction:new(self))
end

function Darkling:count()
	addAction(EffectAction:new(TextEffect:new{color=12,text='Regrowing...',x=self.x+self.width*4,y=self.y,ySpeed=-0.5}))
	addAction(SetIntentAction:new(self,'reincarnate','buff'))
end

function Darkling:reincarnate()
	addAction(AnonymousAction:new(function ()
		self.canInteract = true
	end))
	addAction(HealAction:new{target=self,value=math.floor(self.maxHp/2)})
	addAction(ApplyPowerAction:new(self,LifeLinkPower:new(self)))
	player:triggerEvent('onSpawnMonster',self)
	addAction(NextIntentAction:new(self))
end

function Darkling:nextIntent(first)
	if first then
		self:rollIntent({
			{'nip','attack',self.nipDmg,power=50},
			{'defend',ascension >= 17 and 'defendBuff' or 'defend',power=50},
		})
	else
		if self.canChomp then
			self:rollIntent({
				{'chomp','attackDebuff',self.chompDmg,2,power=40,limit=1},
				{'defend',ascension >= 17 and 'defendBuff' or 'defend',power=30,limit=1},
				{'nip','attack',self.nipDmg,power=30,limit=2},
			})
		else
			self:rollIntent({
				{'defend',ascension >= 17 and 'defendBuff' or 'defend',power=30,limit=1},
				{'nip','attack',self.nipDmg,power=30,limit=2},
			})
		end
	end
end

LifeLinkPower = Power:new{icon=427,stackable=false}
function LifeLinkPower:onDeath()
	if table.anyMatch(enemies,function (enemy) return enemy.alive and enemy:getPower(LifeLinkPower) ~= nil end) then
		self.owner.alive = true
		self.owner.visible = true
		self.owner.powers = {}
		addAction(SetIntentAction:new(self.owner,'count','unknown',0,0,false))
	elseif table.allMatch(enemies,function (enemy) return not enemy.alive or (enemy.hp <= 0 and not enemy.canInteract) end) then
		for _, enemy in ipairs(enemies) do
			if enemy ~= self and enemy.alive then
				enemy:die()
			end
		end
	end
end

Repulsor = Monster:new{ maxHp=35,width=4,height=3,attackDmg=11 }
function Repulsor:init(random)
	self.maxHp = ascension >= 7 and random:randInt(31,38) or random:randInt(29,35)
	if ascension >= 2 then
		self.attackDmg = 13
	end
end

function Repulsor:drawImage()
	sprmap(22,30,3,2,self.x+8,self.y+4,0)
end

function Repulsor:attack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function Repulsor:debuff()
	addAction(MakeTempCardToDrawPileAction:new(Dazed:new(),2))
	addAction(NextIntentAction:new(self))
end

function Repulsor:nextIntent()
	self:rollIntent({
		{'attack','attack',self.attackDmg,power=20,limit=1},
		{'debuff','debuff',power=80},
	})
end

Exploder = Monster:new{ maxHp=30,width=4,height=3,attackDmg=9 }
function Exploder:init(random)
	self.maxHp = ascension >= 7 and random:randInt(30,35) or 30
	if ascension >= 2 then
		self.attackDmg = 11
	end
end

function Exploder:drawImage()
	sprmap(18,30,2,2,self.x+8,self.y+4,0)
end

function Exploder:onCombatStart()
	addAction(ApplyPowerAction:new(self,ExplosivePower:new(self,3)))
	Monster.onCombatStart(self)
end

function Exploder:attack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function Exploder:explode()
	addAction(DamageAction:new{target=player,source=self,value=30,type='power'})
	addAction(SuicideAction:new{target=self})
end

function Exploder:nextIntent()
	if self:lastTwoIntentsAre('attack') then
		self:setIntent('explode','unknown')
	else
		self:setIntent('attack','attack',self.attackDmg)
	end
end

ExplosivePower = TurnBasedPower:new{icon=19}

Spiker = Monster:new{ maxHp=56,width=4,height=3,attackDmg=7,spikeCount=6 }
function Spiker:init(random)
	self.maxHp = ascension >= 7 and random:randInt(44,60) or random:randInt(42,56)
	if ascension >= 2 then
		self.attackDmg = 9
	end
end

function Spiker:drawImage()
	sprmap(20,30,2,2,self.x+8,self.y+4,0)
end

function Spiker:onCombatStart()
	addAction(ApplyPowerAction:new(self,ThornsPower:new(self,ascension>=17 and 7 or (ascension>=2 and 4 or 3))))
	Monster.onCombatStart(self)
end

function Spiker:attack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function Spiker:spike()
	self.spikeCount = self.spikeCount - 1
	addAction(ApplyPowerAction:new(self,ThornsPower:new(self,2)))
	addAction(NextIntentAction:new(self))
end

function Spiker:nextIntent()
	if self.spikeCount > 0 then
		self:rollIntent{
			{'attack','attack',self.attackDmg,power=50,limit=1},
			{'spike','buff',power=50},
		}
	else
		self:setIntent('attack','attack',self.attackDmg)
	end
end

SpireGrowth = Monster:new{ maxHp=170,width=6,height=5,tackleDmg=16,smashDmg=22 }
function SpireGrowth:init()
	self.maxHp = ascension >= 7 and 190 or 170
	if ascension >= 2 then
		self.tackleDmg = 18
		self.smashDmg = 25
	end
end

function SpireGrowth:drawImage()
	sprmap(101,17,7,5,self.x-8,self.y,0)
end

function SpireGrowth:tackle()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function SpireGrowth:smash()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function SpireGrowth:constrict()
	addAction(ApplyPowerAction:new(self,ConstrictedPower:new(player,ascension>=17 and 12 or 10,self)))
	addAction(NextIntentAction:new(self))
end

function SpireGrowth:nextIntent()
	if ascension>=17 and player:getPower(ConstrictedPower) == nil and not self:lastIntentIs('constrict') then
		self:setIntent('constrict','strongDebuff')
	elseif aiRand:randBool() and not self:lastTwoIntentsAre('tackle') then
		self:setIntent('tackle','attack',self.tackleDmg)
	elseif player:getPower(ConstrictedPower) == nil and not self:lastIntentIs('constrict') then
		self:setIntent('constrict','strongDebuff')
	elseif not self:lastTwoIntentsAre('smash') then
		self:setIntent('smash','attack',self.smashDmg)
	else
		self:setIntent('tackle','attack',self.tackleDmg)
	end
end

ConstrictedPower = Power:new{icon=288,debuff=true,priority=180}
function ConstrictedPower:new(owner,amount,source)
	local r = Power.new(self,owner,amount)
	r.source = source
	return r
end

function ConstrictedPower:onTurnEnd()
	addAction(DamageAction:new{target=self.owner,source=self.source,value=self.amount,type='power'})
end

Transient = Monster:new{ maxHp=999,width=7,height=5,attackDmg=30 }
function Transient:init()
	if ascension >= 2 then
		self.attackDmg = 40
	end
end

function Transient:drawImage()
	sprmap(92,23,5,5,self.x+8,self.y+3,8)
end

function Transient:onCombatStart()
	addAction(ApplyPowerAction:new(self,FadingPower:new(self,ascension>=17 and 6 or 5)))
	addAction(ApplyPowerAction:new(self,ShiftingPower:new(self)))
	Monster.onCombatStart(self)
end

function Transient:attack()
	self.attackDmg = self.attackDmg + 10
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function Transient:nextIntent()
	self:setIntent('attack','attack',self.attackDmg)
end

FadingPower = TurnBasedPower:new{icon=Icon:new{image=263,transparentColor=8}}
function FadingPower:onTurnEnd()
	if self.amount == 1 then
		addAction(SuicideAction:new{target=self.owner})
	end
	TurnBasedPower.onTurnEnd(self)
end

ShiftingPower = Power:new{icon=308,stackable=false}
function ShiftingPower:onDamaged(value)
	if value > 0 then
		local power = StrengthPower:new(self.owner,-value)
		power.isFromShifting = true
		addAction(ApplyPowerAction:new(self.owner,power))
		addAction(AnonymousAction:new(function ()
			if power.applied then
				addAction(1,ApplyPowerAction:new(self.owner,ShackledPower:new(self.owner,value)))
			end
		end))
	end
end

function ShiftingPower:onAppliedPower(power)
	if power.isFromShifting then
		power.applied = true
	end
end

TheMaw = Monster:new{ maxHp=300,width=7,height=5,nomDmg=5,slamDmg=25,strAmt=3,debuffAmt=3,usedRoar=false,numTurn=1 }
function TheMaw:init()
	self.maxHp = ascension >= 7 and 350 or 300
	if ascension >= 2 then
		self.slamDmg = 30
	end
	if ascension >= 17 then
		self.strAmt = 5
		self.debuffAmt = 5
	end
end

function TheMaw:drawImage()
	sprmap(95,17,6,5,self.x+8,self.y,0)
end

function TheMaw:enemyTurn()
	self.numTurn = self.numTurn + 1
	Monster.enemyTurn(self)
end

function TheMaw:roar()
	self.usedRoar = true
	addAction(ApplyPowerAction:new(self,WeakPower:new(player,self.debuffAmt,true)))
	addAction(ApplyPowerAction:new(self,FrailPower:new(player,self.debuffAmt,true)))
	addAction(NextIntentAction:new(self))
end

function TheMaw:nom()
	for _=1,self.intentAttackCount do
		addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	end
	addAction(NextIntentAction:new(self))
end

function TheMaw:slam()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function TheMaw:buff()
	addAction(ApplyPowerAction:new(self,StrengthPower:new(self,self.strAmt)))
	addAction(NextIntentAction:new(self))
end

function TheMaw:nextIntent()
	if not self.usedRoar then
		self:setIntent('roar','strongDebuff')
	elseif aiRand:randBool() and not self:lastIntentIs('nom') then
		self:setIntent('nom','attack',self.nomDmg,math.floor((self.numTurn+1)/2))
	elseif self:lastIntentIs('slam') or self:lastIntentIs('nom') then
		self:setIntent('buff','buff')
	else
		self:setIntent('slam','attack',self.slamDmg)
	end
end

WrithingMass = Monster:new{ maxHp=160,width=8,height=5,bigHitDmg=32,multiHitDmg=7,blockDmg=15,debuffDmg=10,usedParasite=false }
function WrithingMass:init()
	self.maxHp = ascension >= 7 and 175 or 160
	if ascension >= 2 then
		self.bigHitDmg = 38
		self.multiHitDmg = 9
		self.blockDmg = 16
		self.debuffDmg = 12
	end
end

function WrithingMass:drawImage()
	sprmap(40,23,8,5,self.x-4,self.y,0)
end

function WrithingMass:onCombatStart()
	addAction(ApplyPowerAction:new(self,ReactivePower:new(self)))
	addAction(ApplyPowerAction:new(self,MalleablePower:new(self,3)))
	Monster.onCombatStart(self)
end

function WrithingMass:bigHit()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function WrithingMass:multiHit()
	for _=1,self.intentAttackCount do
		addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	end
	addAction(NextIntentAction:new(self))
end

function WrithingMass:attackDefend()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(GainBlockAction:new{target=self,value=self.blockDmg})
	addAction(NextIntentAction:new(self))
end

function WrithingMass:attackDebuff()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(ApplyPowerAction:new(player,WeakPower:new(player,2,true)))
	addAction(ApplyPowerAction:new(player,VulnerablePower:new(player,2,true)))
	addAction(NextIntentAction:new(self))
end

function WrithingMass:parasite()
	self.usedParasite = true
	addAction(AnonymousAction:new(function ()
		obtainCardWithEffect(Parasite:new())
	end))
	addAction(NextIntentAction:new(self))
end

function WrithingMass:nextIntent(first)
	if first then
		self:rollIntent{
			{'multiHit','attack',self.multiHitDmg,3,power=33},
			{'attackDefend','attackDefend',self.blockDmg,power=33},
			{'attackDebuff','attackDebuff',self.debuffDmg,power=34},
		}
	elseif not self.usedParasite then
		self:rollIntent{
			{'bigHit','attack',self.bigHitDmg,power=10,limit=1},
			{'parasite','strongDebuff',power=10,limit=1},
			{'attackDebuff','attackDebuff',self.debuffDmg,power=20,limit=1},
			{'multiHit','attack',self.multiHitDmg,3,power=30,limit=1},
			{'attackDefend','attackDefend',self.blockDmg,power=30,limit=1},
		}
	else
		self:rollIntent{
			{'bigHit','attack',self.bigHitDmg,power=10,limit=1},
			{'attackDebuff','attackDebuff',self.debuffDmg,power=20,limit=1},
			{'multiHit','attack',self.multiHitDmg,3,power=30,limit=1},
			{'attackDefend','attackDefend',self.blockDmg,power=30,limit=1},
		}
	end
end

ReactivePower = Power:new{icon=344,stackable=false}
function ReactivePower:onDamaged()
	addAction(AnonymousAction:new(function ()
		self.owner.lastSecondIntent = self.owner.lastIntent
		self.owner.lastIntent = self.owner.intent
	end))
	addAction(NextIntentAction:new(self.owner,false,false))
end

Reptomancer = Monster:new{ maxHp=190,width=6,height=5,strikeDmg=13,biteDmg=30,daggerCount=1,type='elite' }
function Reptomancer:init(random)
	self.maxHp = ascension >= 8 and random:randInt(190,200) or random:randInt(180,190)
	if ascension >= 3 then
		self.strikeDmg = 16
		self.biteDmg = 34
	end
	self.daggerCount = ascension >= 18 and 2 or 1
end

function Reptomancer:drawImage()
	sprmap(89,23,3,5,self.x+16,self.y,0)
end

function Reptomancer:onCombatStart()
	for _,e in ipairs(enemies) do
		if e ~= self then
			addAction(ApplyPowerAction:new(self,MinionPower:new(e)))
		end
	end
	Monster.onCombatStart(self)
end

function Reptomancer:strike()
	for _=1,self.intentAttackCount do
		addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	end
	addAction(ApplyPowerAction:new(self,WeakPower:new(player,1,true)))
	addAction(NextIntentAction:new(self))
end

function Reptomancer:bite()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

local summonOrder = {5,2,4,1}
function Reptomancer:summon()
	local possessed = {}
	for _=1,self.daggerCount do
		local index = nil
		for i=1,4 do
			local enemy = enemies[summonOrder[i]]
			if not enemy.alive and not possessed[summonOrder[i]] then
				index = summonOrder[i]
				break
			end
		end
		if index then
			local target = enemies[index]
			possessed[index] = true
			local dagger = SnakeDagger:new{createRandom=self.createRandom}
			local tx,ty = target.x+target.width*4-dagger.width*4,target.y+target.height*8-dagger.height*8
			dagger.x,dagger.y = tx,ty
			addAction(SpawnMonsterAction:new{target=dagger,index=index})
			addAction(ApplyPowerAction:new(self,MinionPower:new(dagger)))
		end
	end
	addAction(NextIntentAction:new(self))
end

function Reptomancer:nextIntent(first)
	if first then
		self:setIntent('summon','unknown')
	else
		self:rollIntent({
			{'strike','attackDebuff',self.strikeDmg,2,power=33,limit=1},
			{'summon','unknown',power=33,limit=2},
			{'bite','attack',self.biteDmg,power=34,limit=1},
		})
		if self.intent == 'summon' and table.count(enemies,function (enemy) return enemy.alive end) >= 5 then
			self:setIntent('strike','attackDebuff',self.strikeDmg,2)
		end
	end
end

SnakeDagger = Monster:new{ maxHp=20,width=4,height=2 }
function SnakeDagger:init(random)
	self.maxHp = random:randInt(20,25)
end

function SnakeDagger:drawImage()
	sprmap(86,21,3,2,self.x+4,self.y,0)
end

function SnakeDagger:drawIntent()
	self.y = self.y + 6
	Monster.drawIntent(self)
	self.y = self.y - 6
end

function SnakeDagger:wound()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(MakeTempCardToDiscardPileAction:new(Wound:new()))
	addAction(NextIntentAction:new(self))
end

function SnakeDagger:explode()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(DamageAction:new{target=self,source=self,value=self.hp,type='hpLoss'})
end

function SnakeDagger:nextIntent(first)
	if first then
		self:setIntent('wound','attackDebuff',9)
	else
		self:setIntent('explode','attack',25)
	end
end

GiantHead = Monster:new{ maxHp=500,width=9,height=5,glareDmg=13,attackDmg=30,countdown=5,maxAttackDmg=60,type='elite' }
function GiantHead:init()
	self.maxHp = ascension >= 8 and 520 or 500
	self.attackDmg = ascension >= 3 and 40 or 30
	self.countdown = ascension >= 18 and 4 or 5
	self.maxAttackDmg = self.attackDmg + 30
end

function GiantHead:drawImage()
	sprmap(97,22,8,5,self.x+4,self.y,0)
end

function GiantHead:onCombatStart()
	addAction(ApplyPowerAction:new(self,SlowPower:new(self,0)))
	Monster.onCombatStart(self)
end

function GiantHead:glare()
	self:talk('~#2#'..tostring(self.countdown)..'...~')
	self.countdown = self.countdown - 1
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function GiantHead:debuff()
	self:talk('~#2#'..tostring(self.countdown)..'...~')
	self.countdown = self.countdown - 1
	addAction(ApplyPowerAction:new(player,WeakPower:new(player,1,true)))
	addAction(NextIntentAction:new(self))
end

function GiantHead:attack()
	local text = ({
		'~It~ ~is~ ~time~',
		'~Good~ ~Bye~',
		'~Tick~ ~Tock~ NL ~Tick~ ~Tock~',
		'~Why~ ~are~ ~you~ NL ~still~ ~here?~'
	})[effectRandom:randInt(4)]
	self:talk(text)
	self.attackDmg = math.min(self.attackDmg+5,self.maxAttackDmg)
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function GiantHead:nextIntent()
	if self.countdown > 0 then
		self:rollIntent({
			{'glare','attack',self.glareDmg,power=50,limit=2},
			{'debuff','debuff',power=50,limit=2},
		})
	else
		self:setIntent('attack','attack',self.attackDmg)
	end
end

function GiantHead:talk(text,duration)
	addAction(TalkAction:new(self,text,{xOffset=8,yOffset=8,boxXOffset=12,boxYOffset=4,duration=duration}))
end

SlowPower = Power:new{icon=342,debuff=true}
function SlowPower:onTurnStart()
	self.amount = 0
end

function SlowPower:onAttacked(damage)
	return damage * (1+self.amount*0.1)
end

function SlowPower:onUseCard()
	self.amount = self.amount + 1
end

Nemesis = Monster:new{ maxHp=185,width=6,height=6,fireDmg=6,scytheDmg=45,type='elite' }
function Nemesis:init()
	self.maxHp = ascension >= 8 and 200 or 185
	self.fireDmg = ascension >= 3 and 7 or 6
end

function Nemesis:drawImage()
	sprmap(108,17,5,7,self.x+2,self.y-8,0)
end

function Nemesis:enemyTurn()
	Monster.enemyTurn(self)
	if not self:getPower(IntangiblePower) then
		addAction(ApplyPowerAction:new(self,IntangiblePower:new(self,1,true)))
	end
end

function Nemesis:fire()
	for _=1,self.intentAttackCount do
		addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	end
	addAction(NextIntentAction:new(self))
end

function Nemesis:scythe()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function Nemesis:burn()
	addAction(MakeTempCardToDiscardPileAction:new(Burn:new(),ascension>=18 and 5 or 3))
	addAction(NextIntentAction:new(self))
end

function Nemesis:nextIntent(first)
	if first then
		self:rollIntent({
			{'fire','attack',self.fireDmg,3,power=50},
			{'burn','debuff',power=50},
		})
	else
		self:rollIntent({
			{'fire','attack',self.fireDmg,3,power=35,limit=2},
			{'scythe','attack',self.scytheDmg,power=30,limit=1},
			{'burn','debuff',power=35,limit=1},
		})
	end
end

AwakenedOne = Monster:new{ maxHp=300,width=8,height=3,slashDmg=20,soulStrikeDmg=6,echoDmg=40,sludgeDmg=18,tackleDmg=10,awakened=false,type='boss' }
function AwakenedOne:init()
	self.maxHp = ascension >= 9 and 320 or 300
end

function AwakenedOne:drawImage()
	sprmap(6,25,8,3,self.x+3,self.y,0)
	if self.awakened then
		rect(self.x-1,self.y+15,15,1,11)
		rect(self.x+6,self.y+10,1,11,11)
		spr(411,self.x+3,self.y+12,0)

		spr(412,self.x+8,self.y-4,0)
		spr(412,self.x+12,self.y-6,0)
		spr(412,self.x+8,self.y+4,0,1,1)
		spr(412,self.x+14,self.y+2,0,1,1)
		spr(412,self.x+24,self.y-5,0,1,1)
		spr(412,self.x+30,self.y-3,0,1,1)
		spr(413,self.x+16,self.y-5,0)
		spr(413,self.x+20,self.y-5,0,1,1)
	end
end

function AwakenedOne:onCombatStart()
	addAction(ApplyPowerAction:new(self,RegenerateMonsterPower:new(self,ascension>=19 and 15 or 10)))
	addAction(ApplyPowerAction:new(self,CuriosityPower:new(self,ascension>=19 and 2 or 1)))
	addAction(ApplyPowerAction:new(self,UnawakenedPower:new(self)))
	if ascension >= 4 then
		addAction(ApplyPowerAction:new(self,StrengthPower:new(self,2)))
	end
	Monster.onCombatStart(self)
end

function AwakenedOne:slash()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function AwakenedOne:soulStrike()
	for _=1,self.intentAttackCount do
		addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	end
	addAction(NextIntentAction:new(self))
end

function AwakenedOne:echo()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function AwakenedOne:sludge()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(MakeTempCardToDrawPileAction:new(Void:new()))
	addAction(NextIntentAction:new(self))
end

function AwakenedOne:tackle()
	for _=1,self.intentAttackCount do
		addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	end
	addAction(NextIntentAction:new(self))
end

function AwakenedOne:rebirth()
	addAction(AnonymousAction:new(function ()
		self.canInteract = true
		self.awakened = true
	end))
	addAction(HealAction:new{target=self,value=self.maxHp})
	addAction(SetIntentAction:new(self,'echo','attack',self.echoDmg))
end

function AwakenedOne:nextIntent(first)
	if first then
		self:setIntent('slash','attack',self.slashDmg)
	else
		if self.awakened then
			self:rollIntent({
				{'sludge','attackDebuff',self.sludgeDmg,power=50,limit=2},
				{'tackle','attack',self.tackleDmg,3,power=50,limit=2},
			})
		else
			self:rollIntent({
				{'soulStrike','attack',self.soulStrikeDmg,4,power=25,limit=1},
				{'slash','attack',power=75,limit=2}
			})
		end
	end
end

function AwakenedOne:die()
	Monster.die(self)
	local talked = false
	if not self.alive then
		for _,enemy in ipairs(enemies) do
			if enemy.alive and enemy ~= self then
				if not talked then
					addAction(TalkAction:new(enemy,'~No~ ~.~ ~.~ ~.~ ~no~ ~.~ ~.~ NL ~.~ ~.~ ~no~ ~.~ ~.~ ~.~',{duration=120}))
					talked = true
				end
				addAction(EscapeAction:new{target=enemy})
			end
		end
	end
end

CuriosityPower = Power:new{icon=434}
function CuriosityPower:onUseCard(card)
	if card.type == 'power' then
		addAction(ApplyPowerAction:new(self.owner,StrengthPower:new(self.owner,self.amount)))
	end
end

UnawakenedPower = Power:new{icon=435,stackable=false}
function UnawakenedPower:onDeath()
	self.owner.alive = true
	self.owner.visible = true
	table.retainIf(self.owner.powers,function (power)
		local powerType = getmetatable(power)
		return not power.debuff and powerType ~= ShackledPower and powerType ~= CuriosityPower and powerType ~= UnawakenedPower
	end)
	addAction(TalkAction:new(self.owner,'~Grr~ ~.~ ~.~ ~.~',{duration=120}))
	addAction(SetIntentAction:new(self.owner,'rebirth','unknown',0,0,false))
end

Donu = Monster:new{ maxHp=250,width=8,height=5,beamDmg=10,type='boss' }
function Donu:init()
	self.maxHp = ascension >= 9 and 265 or 250
	if ascension >= 4 then
		self.beamDmg = 12
	end
end

function Donu:drawImage()
	sprmap(79,26,5,5,self.x+12,self.y,0)
end

function Donu:onCombatStart()
	addAction(ApplyPowerAction:new(self,ArtifactPower:new(self,ascension>=19 and 3 or 2)))
	Monster.onCombatStart(self)
end

function Donu:beam()
	for _=1,self.intentAttackCount do
		addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	end
	addAction(NextIntentAction:new(self))
end

function Donu:buff()
	for _,enemy in ipairs(enemies) do
		if enemy.alive then
			addAction(ApplyPowerAction:new(enemy,StrengthPower:new(enemy,3)))
		end
	end
	addAction(NextIntentAction:new(self))
end

function Donu:nextIntent()
	if self:lastIntentIs('buff') then
		self:setIntent('beam','attack',self.beamDmg,2)
	else
		self:setIntent('buff','buff')
	end
end

Deca = Monster:new{ maxHp=250,width=8,height=5,beamDmg=10,type='boss' }
function Deca:init()
	self.maxHp = ascension >= 9 and 265 or 250
	if ascension >= 4 then
		self.beamDmg = 12
	end
end

function Deca:drawImage()
	sprmap(84,26,5,5,self.x+12,self.y,0)
end

function Deca:onCombatStart()
	addAction(ApplyPowerAction:new(self,ArtifactPower:new(self,ascension>=19 and 3 or 2)))
	Monster.onCombatStart(self)
end

function Deca:beam()
	for _=1,self.intentAttackCount do
		addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	end
	addAction(MakeTempCardToDiscardPileAction:new(Dazed:new(),2))
	addAction(NextIntentAction:new(self))
end

function Deca:defend()
	for _,enemy in ipairs(enemies) do
		if enemy.alive then
			addAction(GainBlockAction:new{target=enemy,value=16})
			if ascension >= 19 then
				addAction(ApplyPowerAction:new(enemy,PlatedArmorPower:new(enemy,3)))
			end
		end
	end
	addAction(NextIntentAction:new(self))
end

function Deca:nextIntent()
	if self:lastIntentIs('beam') then
		self:setIntent('defend','buff')
	else
		self:setIntent('beam','attack',self.beamDmg,2)
	end
end

TimeEater = Monster:new{ maxHp=456,width=8,height=5,reverbDmg=7,headSlamDmg=26,usedHaste=false,firstTurn=true,type='boss' }
function TimeEater:init()
	self.maxHp = ascension >= 9 and 480 or 456
	if ascension >= 4 then
		self.reverbDmg = 8
		self.headSlamDmg = 32
	end
end

function TimeEater:drawImage()
	sprmap(89,17,6,6,self.x+8,self.y-3,0)
end

function TimeEater:onCombatStart()
	addAction(ApplyPowerAction:new(self,TimeWarpPower:new(self,0)))
	Monster.onCombatStart(self)
end

function TimeEater:enemyTurn()
	if self.firstTurn then
		addAction(TalkAction:new(self,'~Ah...~ NL ~..company...~',{duration=120}))
		self.firstTurn = false
	end
	Monster.enemyTurn(self)
end

function TimeEater:reverb()
	for _=1,self.intentAttackCount do
		addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	end
	addAction(NextIntentAction:new(self))
end

function TimeEater:headSlam()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(ApplyPowerAction:new(self,DrawReductionPower:new(player,2)))
	if ascension >= 19 then
		addAction(MakeTempCardToDiscardPileAction:new(Slimed:new(),2))
	end
	addAction(NextIntentAction:new(self))
end

function TimeEater:defendDebuff()
	addAction(GainBlockAction:new{target=self,value=20})
	addAction(ApplyPowerAction:new(player,VulnerablePower:new(player,1,true)))
	addAction(ApplyPowerAction:new(player,WeakPower:new(player,1,true)))
	if ascension >= 19 then
		addAction(ApplyPowerAction:new(player,FrailPower:new(player,1,true)))
	end
	addAction(NextIntentAction:new(self))
end

function TimeEater:haste()
	self.usedHaste = true
	addAction(TalkAction:new(self,'~Foolish..~ NL @FOOOLISH!@',{duration=120}))
	addAction(RemoveDebuffsAction:new(self))
	addAction(RemovePowerByTypeAction:new(self,ShackledPower))
	addAction(HealAction:new{target=self,value=math.floor(self.maxHp/2-self.hp)})
	if ascension >= 19 then
		addAction(GainBlockAction:new{target=self,value=self.headSlamDmg})
	end
	addAction(NextIntentAction:new(self))
end

function TimeEater:nextIntent()
	if self.hp < self.maxHp / 2 and not self.usedHaste then
		self:setIntent('haste','buff')
	else
		self:rollIntent{
			{'reverb','attack',self.reverbDmg,3,power=45,limit=2},
			{'headSlam','attackDebuff',self.headSlamDmg,power=35,limit=1},
			{'defendDebuff','defendDebuff',power=20,limit=1},
		}
	end
end

TimeWarpPower = Power:new{icon=404}
function TimeWarpPower:onUseCard()
	self.amount = self.amount + 1
	if self.amount == 12 then
		self.amount = 0
		addAction(ApplyPowerAction:new(self.owner,StrengthPower:new(self.owner,2)))
		if not endTurnPressed then
			endTurnPressed = true
			addEffect(TimeWarpEffect:new())
			addAction(EndTurnAction:new())
		end
	end
end

require 'effect'
TimeWarpEffect = Effect:new{x=120,y=160,vx=-0.1,vy=-7,rotation=-0.4,duration=120}
function TimeWarpEffect:tick()
	Effect.tick(self)
	if self.duration > 80 then
		return
	end

	self.y = self.y + self.vy
	self.vy = self.vy + 0.23
	self.rotation = self.rotation + 0.1

	local x1,y1,r = self.x,self.y,self.rotation
	local d1,d2,d3,d4=math.sin(r-3.14159265/4),-math.cos(r-3.14159265/4),math.sin(r+3.14159265/4),-math.cos(r+3.14159265/4)
	local d = 1.414*32
	d1,d2,d3,d4 = d1*d,d2*d,d3*d,d4*d
	local icon = 404
	local u,v = 8*(icon%16),8*math.floor(icon/16)
	ttri(x1+d1,y1+d2,x1+d3,y1+d4,x1-d1,y1-d2,u,v,u+8,v,u+8,v+8,0,0)
	ttri(x1+d1,y1+d2,x1-d3,y1-d4,x1-d1,y1-d2,u,v,u,v+8,u+8,v+8,0,0)
end

DrawReductionPower = TurnBasedPower:new{icon=405,debuff=true}
function DrawReductionPower:modifyTurnStartDrawCount(count)
	return count - 1
end

-- encounters
OrbWalkerEncounter = Encounter:new{spriteBank=6,name='OrbWalker',enemyInfo={encItem(OrbWalker,0,0)}}
ThreeDarklingsEncounter = Encounter:new{spriteBank=4,name='ThreeDarkling',enemyInfo={encItem(Darkling,-48,0),encItem(Darkling,0,0,{canChomp=false}),encItem(Darkling,48,1)}}
ThreeShapesEncounter = Encounter:new{spriteBank=3,name='ThreeShapes',enemyInfo={}}
function ThreeShapesEncounter:setupEnemies(random)
	local enemies = {Repulsor,Repulsor,Exploder,Exploder,Spiker,Spiker}
	random:shuffle(enemies)
	self.enemyInfo = {}
	self.enemyInfo[1] = encItem(enemies[1],-48,-1)
	self.enemyInfo[2] = encItem(enemies[2],0,1)
	self.enemyInfo[3] = encItem(enemies[3],48,2)
	Encounter.setupEnemies(self,random)
end
FourShapesEncounter = Encounter:new{spriteBank=3,name='FourShapes',enemyInfo={}}
function FourShapesEncounter:setupEnemies(random)
	local enemies = {Repulsor,Repulsor,Exploder,Exploder,Spiker,Spiker}
	random:shuffle(enemies)
	self.enemyInfo = {}
	self.enemyInfo[1] = encItem(enemies[1],-68,-2)
	self.enemyInfo[2] = encItem(enemies[2],-26,-4)
	self.enemyInfo[3] = encItem(enemies[3],16,-6)
	self.enemyInfo[4] = encItem(enemies[4],54,2)
	Encounter.setupEnemies(self,random)
end
SphereAndTwoShapesEncounter = Encounter:new{spriteBank=3,name='SphereAndTwoShapes',enemyInfo={}}
function SphereAndTwoShapesEncounter:setupEnemies(random)
	local enemies = {Repulsor,Exploder,Spiker}
	self.enemyInfo = {}
	self.enemyInfo[1] = encItem(enemies[random:randInt(3)],-48,0)
	self.enemyInfo[2] = encItem(enemies[random:randInt(3)],0,0)
	self.enemyInfo[3] = encItem(SphericGuardian,48,1)
	Encounter.setupEnemies(self,random)
end
ThreeJawWormEncounter = Encounter:new{spriteBank=1,name='ThreeJawWorm',enemyInfo={encItem(JawWorm,-48,0),encItem(JawWorm,0,0),encItem(JawWorm,48,1)}}
SpireGrowthEncounter = Encounter:new{spriteBank=7,name='SpireGrowth',enemyInfo={encItem(SpireGrowth,0,0)}}
TransientEncounter = Encounter:new{spriteBank=7,name='Transient',enemyInfo={encItem(Transient,0,0)}}
TheMawEncounter = Encounter:new{spriteBank=6,name='TheMaw',enemyInfo={encItem(TheMaw,0,0)}}
WrithingMassEncounter = Encounter:new{spriteBank=4,name='WrithingMass',enemyInfo={encItem(WrithingMass,0,0)}}

-- elite
ReptomancerEncounter = Encounter:new{
	spriteBank=6,name='Reptomancer',type='elite',
	enemyInfo={
		encItem(MonsterSlot,-52,-40),
		encItem(SnakeDagger,-48,0),
		encItem(Reptomancer,0,4),
		encItem(MonsterSlot,48,-38),
		encItem(SnakeDagger,52,2),
	}
}
GiantHeadEncounter = Encounter:new{spriteBank=7,name='GiantHead',type='elite',enemyInfo={encItem(GiantHead,0,0)}}
NemesisEncounter = Encounter:new{spriteBank=7,name='Nemesis',type='elite',enemyInfo={encItem(Nemesis,0,0)}}

-- boss
AwakenedOneEncounter = Encounter:new{spriteBank=1,name='AwakenedOne',type='boss',enemyInfo={encItem(Cultist,-60,2),encItem(Cultist,-15,1),encItem(AwakenedOne,42,0)},mapIcon=384}
DonuAndDecaEncounter = Encounter:new{spriteBank=6,name='DonuAndDeca',type='boss',enemyInfo={encItem(Deca,-34,0),encItem(Donu,34,0)},mapIcon=392}
TimeEaterEncounter = Encounter:new{spriteBank=6,name='TimeEater',type='boss',enemyInfo={encItem(TimeEater,0,0)},mapIcon=388}

-- events
TwoOrbWalkersEncounter = Encounter:new{spriteBank=6,name='TwoOrbWalkers',enemyInfo={encItem(OrbWalker,-32,0),encItem(OrbWalker,32,0)}}
