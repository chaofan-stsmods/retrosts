-- city-monsters
---@diagnostic disable: lowercase-global

Mugger = Looter:new{ blockAmt=11,swipeDmg=10,lungeDmg=16 }
function Mugger:init(random)
	self.maxHp = ascension >= 7 and random:randInt(50,54) or random:randInt(48,52)
	if ascension >= 2 then
		self.swipeDmg,self.lungeDmg = 11,18
	end
	self.goldAmt = ascension >= 17 and 20 or 15
end

function Mugger:drawImage()
	if self.flipped then
		sprmap(0,25,3,2,self.x+8,self.y,0,1,flipRemap(0,3))
		mapColors(0,1,14,15,14,5,6,7,8,3,4,11,15,13,14,1)
		sprmap(1,27,2,2,self.x+8,self.y+16,0,1,flipRemap(1,2))
		mapColor(2,11)
		sprmap(0,27,1,2,self.x+24,self.y+16,0,1,flipRemap(0,1))
		resetColors()
	else
		sprmap(0,25,3,2,self.x,self.y,0)
		mapColors(0,1,14,15,14,5,6,7,8,3,4,11,15,13,14,1)
		sprmap(1,27,2,2,self.x+8,self.y+16,0)
		mapColor(2,11)
		sprmap(0,27,1,2,self.x,self.y+16,0)
		resetColors()
	end
end

Byrd = Monster:new{ maxHp=51,width=4,height=5,peckCount=5,swoopDmg=12,flying=true }
function Byrd:init(random)
	self.maxHp = ascension >= 7 and random:randInt(26,33) or random:randInt(25,31)
	if ascension >= 2 then
		self.swoopDmg = 14
		self.peckCount = 6
	end
end

function Byrd:drawImage()
	if self.flying then
		sprmap(19,27,4,3,self.x,self.y+4,0)
	else
		sprmap(23,27,4,2,self.x,self.y+24,0)
	end
end

function Byrd:onCombatStart()
	addAction(ApplyPowerAction:new(FlightPower:new(self,ascension>=17 and 4 or 3)))
	Monster.onCombatStart(self)
end

function Byrd:onFlightRemoved()
	self.flying = false
	addAction(SetIntentAction:new(self,'stun','stun',0,0,false))
end

function Byrd:buff()
	addAction(ApplyPowerAction:new(StrengthPower:new(self,1)))
	addAction(NextIntentAction:new(self))
end

function Byrd:swoop()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function Byrd:peck()
	for _=1,self.intentAttackCount do
		addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	end
	addAction(NextIntentAction:new(self))
end

function Byrd:stun()
	addAction(SetIntentAction:new(self,'littleAttack','attack',3))
end

function Byrd:littleAttack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(SetIntentAction:new(self,'fly','unknown'))
end

function Byrd:fly()
	addAction(AnonymousAction:new(function ()
		self.flying = true
	end))
	addAction(ApplyPowerAction:new(FlightPower:new(self,ascension>=17 and 4 or 3)))
	addAction(NextIntentAction:new(self))
end

function Byrd:nextIntent(first)
	if first then
		if aiRand:rand() < 0.375 then
			self:setIntent('buff','buff')
		else
			self:setIntent('peck','attack',1,self.peckCount)
		end
		return
	end

	self:rollIntent({
		{'peck','attack',1,self.peckCount,power=50,limit=2},
		{'swoop','attack',self.swoopDmg,power=20,limit=1},
		{'buff','buff',power=30,limit=1},
	})
end

FlightPower = Power:new{icon=419}
function FlightPower:new(owner,amount)
	local result = Power.new(self,owner,amount)
	result.initialAmount = amount
	return result
end

function FlightPower:onAttacked(damage)
	return damage / 2
end

function FlightPower:onTurnStart()
	self:setAmount(self.initialAmount)
end

function FlightPower:onDamaged(value,source,type)
	if value > 0 and source == player and type == 'attack' then
		addAction(ReducePowerAction:new(self,1))
		addAction(AnonymousAction:new(function()
			if self.owner.flying and not self.owner:getPower(FlightPower) then
				self.owner:onFlightRemoved()
			end
		end))
	end
end

SphericGuardian = Monster:new{ maxHp=20,width=4,height=4,attackDmg=10 }
function SphericGuardian:init()
	self.attackDmg = ascension >= 2 and 11 or 10
end

function SphericGuardian:drawImage()
	local layers = {
		{name='sprmap',z=0,15,29,3,3,self.x+4,self.y,0},
		{name='spr',z=math.cos(time()*0.003),373,self.x+self.width*4-4+math.sin(time()*0.003)*15,self.y+self.height*4-4+math.cos(time()*0.003)*10,0},
		{name='spr',z=math.cos(time()*0.003+2.75),389,self.x+self.width*4-4+math.sin(time()*0.003+2.75)*14,self.y+3*4-4+math.cos(time()*0.003+2.75)*12,0},
	}
	table.sort(layers,function (a, b) return a.z < b.z end)
	for _,layer in ipairs(layers) do
		_G[layer.name](table.unpack(layer))
	end
end

function SphericGuardian:onCombatStart()
	addAction(ApplyPowerAction:new(BarricadePower:new(self)))
	addAction(ApplyPowerAction:new(ArtifactPower:new(self,3)))
	addAction(GainBlockAction:new{target=self,value=40})
	Monster.onCombatStart(self)
end

function SphericGuardian:defend()
	addAction(GainBlockAction:new{target=self,value=ascension >= 17 and 35 or 25})
	addAction(SetIntentAction:new(self,'frailAttack','attackDebuff',self.attackDmg))
end

function SphericGuardian:frailAttack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(ApplyPowerAction:new(FrailPower:new(player,5,true)))
	addAction(SetIntentAction:new(self,'dualAttack','attack',self.attackDmg,2))
end

function SphericGuardian:dualAttack()
	for _=1,self.intentAttackCount do
		addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	end
	addAction(SetIntentAction:new(self,'defendAttack','attackDefend',self.attackDmg))
end

function SphericGuardian:defendAttack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(GainBlockAction:new{target=self,value=15})
	addAction(SetIntentAction:new(self,'dualAttack','attack',self.attackDmg,2))
end

function SphericGuardian:nextIntent()
	self:setIntent('defend','defend')
end

Chosen = Monster:new{ maxHp=99,width=4,height=4,zapDmg=18,debilitateDmg=10,pokeDmg=5,usedHex=false }
function Chosen:init(random)
	self.maxHp = ascension >= 7 and random:randInt(98,103) or random:randInt(95,99)
	if ascension >= 2 then
		self.zapDmg,self.debilitateDmg,self.pokeDmg = 21,12,6
	end
end

function Chosen:drawImage()
	sprmap(24,23,3,self.height,self.x+6,self.y,0)
end

function Chosen:hex()
	self.usedHex = true
	addAction(ApplyPowerAction:new(HexPower:new(player,1)))
	addAction(NextIntentAction:new(self))
end

function Chosen:debilitate()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(ApplyPowerAction:new(VulnerablePower:new(player,2,true)))
	addAction(NextIntentAction:new(self))
end

function Chosen:debuff()
	addAction(ApplyPowerAction:new(WeakPower:new(player,3,true)))
	addAction(ApplyPowerAction:new(StrengthPower:new(self,3)))
	addAction(NextIntentAction:new(self))
end

function Chosen:zap()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function Chosen:poke()
	for _=1,self.intentAttackCount do
		addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	end
	addAction(NextIntentAction:new(self))
end

function Chosen:nextIntent(first)
	if ascension < 17 and first then
		self:setIntent('poke','attack',self.pokeDmg,2)
		return
	end

	if not self.usedHex then
		self:setIntent('hex','strongDebuff')
	elseif not self:lastIntentIs('debilitate') and not self:lastIntentIs('debuff') then
		self:rollIntent{
			{'debilitate','attackDebuff',self.debilitateDmg,power=50},
			{'debuff','debuff',power=50},
		}
	else
		self:rollIntent{
			{'zap','attack',self.zapDmg,power=40},
			{'poke','attack',self.pokeDmg,2,power=60},
		}
	end
end

HexPower = Power:new{icon=325}
function HexPower:onUseCard(card)
	if card.type ~= 'attack' then
		addAction(MakeTempCardToDrawPileAction:new(Dazed:new()))
	end
end

ShellParasite = Monster:new{ maxHp=70,width=6,height=4,doubleStrikeDmg=6,fellDmg=18,suckDmg=10,stunned=false }
function ShellParasite:init(random)
	self.maxHp = ascension >= 7 and random:randInt(70,75) or random:randInt(68,72)
	if ascension >= 2 then
		self.doubleStrikeDmg,self.fellDmg,self.suckDmg = 7,21,12
	end
end

function ShellParasite:drawImage()
	sprmap(14,25,5,self.height,self.x+4,self.y,0)
end

function ShellParasite:onCombatStart()
	addAction(ApplyPowerAction:new(PlatedArmorPower:new(self,14)))
	addAction(GainBlockAction:new{target=self,value=14})
	Monster.onCombatStart(self)
end

function ShellParasite:fell()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(ApplyPowerAction:new(FrailPower:new(player,2,true)))
	addAction(NextIntentAction:new(self))
end

function ShellParasite:doubleStrike()
	for _=1,self.intentAttackCount do
		addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	end
	addAction(NextIntentAction:new(self))
end

function ShellParasite:suck()
	local damageAction = DamageAction:new{target=player,source=self,value=self.intentDamage}
	addAction(damageAction)
	addAction(AnonymousAction:new(function ()
		if damageAction.damageDealt and damageAction.damageDealt > 0 then
			addAction(1,HealAction:new{target=self,value=damageAction.damageDealt})
		end
	end))
	addAction(NextIntentAction:new(self))
end

function ShellParasite:stun()
	addAction(NextIntentAction:new(self))
end

function ShellParasite:nextIntent(first)
	if first then
		if ascension >= 17 then
			self:setIntent('fell','attackDebuff',self.fellDmg)
		else
			self:rollIntent{
				{'doubleStrike','attack',self.doubleStrikeDmg,2,power=50},
				{'suck','attackBuff',self.suckDmg,power=50},
			}
		end
		return
	end

	self:rollIntent{
		{'fell','attackDebuff',self.fellDmg,power=20,limit=1},
		{'doubleStrike','attack',self.doubleStrikeDmg,2,power=40,limit=2},
		{'suck','attackBuff',self.suckDmg,power=40,limit=2},
	}
end

function ShellParasite:damage(...)
	Monster.damage(self,...)
	addAction(AnonymousAction:new(function()
		if not self.stunned and not self:getPower(PlatedArmorPower) then
			addAction(SetIntentAction:new(self,'stun','stun',0,0,false))
			self.stunned = true
		end
	end))
end

Centurion = Monster:new{ maxHp=80,width=4,height=5,blockAmt=15,slashDmg=12,furyDmg=6 }
function Centurion:init(random)
	self.maxHp = ascension >= 7 and random:randInt(78,83) or random:randInt(76,80)
	self.blockAmt = ascension >= 17 and 20 or 15
	if ascension >= 2 then
		self.slashDmg,self.furyDmg = 14,7
	end
end

function Centurion:drawImage()
	sprmap(53,22,3,self.height,self.x+4,self.y,8)
end

function Centurion:defend()
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

function Centurion:slash()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function Centurion:fury()
	for _=1,self.intentAttackCount do
		addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	end
	addAction(NextIntentAction:new(self))
end

function Centurion:nextIntent()
	if table.count(enemies,function(e) return e.alive end) == 1 then
		self:rollIntent{
			{'fury','attack',self.furyDmg,3,power=35,limit=2},
			{'slash','attack',self.slashDmg,power=65,limit=2},
		}
	else
		self:rollIntent{
			{'defend','defend',power=35,limit=2},
			{'slash','attack',self.slashDmg,power=65,limit=2},
		}
	end
end

Mystic = Monster:new{ maxHp=50,width=4,height=4,strAmt=2,attackDmg=8,healAmt=16 }
function Mystic:init(random)
	self.maxHp = ascension >= 7 and random:randInt(50,58) or random:randInt(48,56)
	self.strAmt = ascension >= 17 and 4 or (ascension >= 2 and 3 or 2)
	self.attackDmg = ascension >= 2 and 9 or 8
	self.healAmt = ascension >= 17 and 20 or 16
end

function Mystic:drawImage()
	sprmap(56,21,4,self.height,self.x-6,self.y,0)
end

function Mystic:healAll()
	for _,e in ipairs(enemies) do
		addAction(HealAction:new{target=e,value=self.healAmt})
	end
	addAction(NextIntentAction:new(self))
end

function Mystic:attack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(ApplyPowerAction:new(FrailPower:new(player,2)))
	addAction(NextIntentAction:new(self))
end

function Mystic:strengthen()
	for _,e in ipairs(enemies) do
		addAction(ApplyPowerAction:new(StrengthPower:new(e,self.strAmt)))
	end
	addAction(NextIntentAction:new(self))
end

function Mystic:nextIntent()
	local needToHeal = 0
	for _,e in ipairs(enemies) do
		if e.alive then
			needToHeal = needToHeal + e.maxHp - e.hp
		end
	end
	if needToHeal > 15 and (ascension < 17 or needToHeal > 20) and not self:lastTwoIntentsAre('healAll') then
		self:setIntent('healAll','buff')
		return
	end
	self:rollIntent{
		{'attack','attackDebuff',self.attackDmg,power=60,limit=ascension>=17 and 1 or 2},
		{'strengthen','buff',power=40,limit=2},
	}
end

SnakePlant = Monster:new{ maxHp=80,width=6,height=6,rainBlowsDmg=7 }
function SnakePlant:init(random)
	self.maxHp = ascension >= 7 and random:randInt(78,82) or random:randInt(75,79)
	if ascension >= 2 then
		self.rainBlowsDmg = 8
	end
end

function SnakePlant:drawImage()
	sprmap(30,27,self.width,self.height,self.x,self.y,0)
end

function SnakePlant:onCombatStart()
	addAction(ApplyPowerAction:new(MalleablePower:new(self,3)))
	Monster.onCombatStart(self)
end

function SnakePlant:rainBlows()
	for _=1,self.intentAttackCount do
		addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	end
	addAction(NextIntentAction:new(self))
end

function SnakePlant:spores()
	addAction(ApplyPowerAction:new(FrailPower:new(player,2,true)))
	addAction(ApplyPowerAction:new(WeakPower:new(player,2,true)))
	addAction(NextIntentAction:new(self))
end

function SnakePlant:nextIntent()
	if ascension >= 17 then
		if aiRand:rand() < 0.65 then
			if self:lastTwoIntentsAre('rainBlows') then
				self:setIntent('spores','strongDebuff')
			else
				self:setIntent('rainBlows','attack',self.rainBlowsDmg,3)
			end
		elseif self:oneOfLastTwoIntentsIs('spores') then
			self:setIntent('rainBlows','attack',self.rainBlowsDmg,3)
		else
			self:setIntent('spores','strongDebuff')
		end
	else
		self:rollIntent{
			{'rainBlows','attack',self.rainBlowsDmg,3,power=65,limit=2},
			{'spores','strongDebuff',power=35,limit=1},
		}
	end
end

MalleablePower = Power:new{icon=303}
function MalleablePower:new(owner,amount)
	local result = Power.new(self,owner,amount)
	result.initialAmount = amount
	return result
end

function MalleablePower:onTurnEnd()
	self.amount = self.initialAmount
end

function MalleablePower:onDamaged(value,source,type)
	if value > 0 and source == player and type == 'attack' then
		addAction(GainBlockAction:new{target=self.owner,value=self.amount})
		self.amount = self.amount + 1
	end
end

Snecko = Monster:new{ maxHp=114,width=6,height=5,tailDmg=8,biteDmg=15 }
function Snecko:init(random)
	self.maxHp = ascension >= 7 and random:randInt(120,125) or random:randInt(114,120)
	if ascension >= 2 then
		self.tailDmg,self.biteDmg = 10,18
	end
end

function Snecko:drawImage()
	sprmap(48,22,5,self.height,self.x+4,self.y,0)
end

function Snecko:tail()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	if ascension >= 17 then
		addAction(ApplyPowerAction:new(WeakPower:new(player,2,true)))
	end
	addAction(ApplyPowerAction:new(VulnerablePower:new(player,2,true)))
	addAction(NextIntentAction:new(self))
end

function Snecko:bite()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function Snecko:confuse()
	addAction(ApplyPowerAction:new(ConfusionPower:new(player)))
	addAction(NextIntentAction:new(self))
end

function Snecko:nextIntent(first)
	if first then
		self:setIntent('confuse','strongDebuff')
		return
	end
	self:rollIntent{
		{'tail','attackDebuff',self.tailDmg,power=40},
		{'bite','attack',self.biteDmg,power=60,limit=2},
	}
end

Taskmaster = Monster:new{ maxHp=54,width=4,height=4,woundAmt=1 }
function Taskmaster:init(random)
	self.maxHp = ascension >= 7 and random:randInt(57,64) or random:randInt(54,60)
	self.woundAmt = ascension >= 18 and 3 or (ascension >= 3 and 2 or 1)
end

function Taskmaster:drawImage()
	sprmap(27,23,3,self.height,self.x+4,self.y,0)
end

function Taskmaster:attack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(MakeTempCardToDiscardPileAction:new(Wound:new(),self.woundAmt))
	if ascension >= 18 then
		addAction(ApplyPowerAction:new(StrengthPower:new(self,1)))
	end
	addAction(NextIntentAction:new(self))
end

function Taskmaster:nextIntent()
	self:setIntent('attack','attackDebuff',7)
end

GremlinLeader = Monster:new{ maxHp=148,width=6,height=5,strAmt=3,blockAmt=6 }
local gremlinPool = {
	GremlinWarrior,GremlinWarrior,
	GremlinThief,GremlinThief,
	GremlinFat,GremlinFat,
	GremlinTsundere,
	GremlinWizard,
}
function GremlinLeader:init(random)
	self.maxHp = ascension >= 8 and random:randInt(145,155) or random:randInt(140,148)
	self.strAmt = ascension >= 18 and 5 or (ascension >= 3 and 4 or 3)
	self.blockAmt = ascension >= 18 and 10 or 6
end

function GremlinLeader:drawImage()
	sprmap(25,29,5,self.height,self.x-3,self.y,8)
end

function GremlinLeader:onCombatStart()
	for _,e in ipairs(enemies) do
		if e ~= self then
			addAction(ApplyPowerAction:new(MinionPower:new(e)))
		end
	end
	Monster.onCombatStart(self)
end

function GremlinLeader:buff()
	local str = ({
		'Don\'t ever NL give up!',
		'We\'re not NL done yet!',
		'Get em boys!',
	})[effectRandom:randInt(1,3)]

	addAction(EffectAction:new(AnonymousEffect:new{duration=60,callback=function ()
		drawTalkBubble(str,self.x-65,self.y-25,60,35,self.x+8,self.y+6,12,15)
	end},10))
	for _,e in ipairs(enemies) do
		addAction(ApplyPowerAction:new(StrengthPower:new(e,self.strAmt)))
		if e ~= self then
			addAction(GainBlockAction:new{target=e,value=self.blockAmt})
		end
	end
	addAction(NextIntentAction:new(self))
end

function GremlinLeader:attack()
	for _=1,self.intentAttackCount do
		addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	end
	addAction(NextIntentAction:new(self))
end

function GremlinLeader:summon()
	local possessed = {}
	for _=1,2 do
		local index = nil
		for i=#enemies,1,-1 do
			local enemy = enemies[i]
			if not enemy.alive and not possessed[i] then
				index = i
				break
			end
		end
		if index then
			local target = enemies[index]
			possessed[index] = true
			local gremlin = gremlinPool[aiRand:randInt(#gremlinPool)]:new{createRandom=self.createRandom}
			local tx,ty = target.x+target.width*4-gremlin.width*4,target.y+target.height*8-gremlin.height*8
			gremlin.visible = false
			gremlin.x,gremlin.y = 250,ty
			addAction(EffectAction:new(AnonymousEffect:new{callback=function ()
				gremlin:drawImage()
				gremlin.x = lerp(gremlin.x,tx,0.2)
				if math.abs(gremlin.x - tx) < 1 then
					gremlin.x = tx
					gremlin.visible = true
					return true
				end
				return false
			end}))
			addAction(SpawnMonsterAction:new{target=gremlin,index=index})
			addAction(ApplyPowerAction:new(MinionPower:new(gremlin)))
		end
	end
	addAction(NextIntentAction:new(self))
end

function GremlinLeader:nextIntent()
	local gremlinCount = self:gremlinCount()
	if gremlinCount == 0 then
		self:rollIntent{
			{'summon','unknown',power=75,limit=1},
			{'attack','attack',6,3,power=25,limit=1},
		}
	elseif gremlinCount == 1 then
		self:rollIntent{
			{'summon','unknown',power=50,limit=1},
			{'attack','attack',6,3,power=20,limit=1},
			{'buff','defendBuff',power=30,limit=1},
		}
	else
		self:rollIntent{
			{'attack','attack',6,3,power=34,limit=1},
			{'buff','defendBuff',power=66,limit=1},
		}
	end
end

function GremlinLeader:gremlinCount()
	return table.count(enemies,function(e) return e.alive and e ~= self end)
end

function GremlinLeader:die()
	Monster.die(self)
	for _,enemy in ipairs(enemies) do
		if enemy.alive and enemy ~= self then
			addAction(EscapeAction:new{target=enemy})
		end
	end
end

BookOfStabbing = Monster:new{ maxHp=164,width=6,height=6,stabDmg=6,bigStabDmg=21,stabCount=2 }
function BookOfStabbing:init(random)
	self.maxHp = ascension >= 8 and random:randInt(168,172) or random:randInt(160,164)
	if ascension >= 3 then
		self.stabDmg,self.bigStabDmg = 7,24
	end
end

function BookOfStabbing:drawImage()
	sprmap(42,28,self.width,self.height,self.x,self.y,0)
end

function BookOfStabbing:onCombatStart()
	addAction(ApplyPowerAction:new(PainfulStabsPower:new(self)))
	Monster.onCombatStart(self)
end

function BookOfStabbing:stab()
	self.stabCount = self.stabCount + 1
	for _=1,self.intentAttackCount do
		addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	end
	addAction(NextIntentAction:new(self))
end

function BookOfStabbing:bigStab()
	if ascension >= 18 then
		self.stabCount = self.stabCount + 1
	end
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function BookOfStabbing:nextIntent()
	self:rollIntent{
		{'stab','attack',self.stabDmg,self.stabCount,power=85,limit=2},
		{'bigStab','attack',self.bigStabDmg,power=15,limit=1},
	}
end

PainfulStabsPower = Power:new{icon=276,stackable=false}
function PainfulStabsPower:onDamageDealt(value,target,type)
	if value > 0 and target == player and type == 'attack' then
		addAction(MakeTempCardToDiscardPileAction:new(Wound:new(),1))
	end
end

TheCollector = Monster:new{ maxHp=282,width=8,height=6,blockAmt=15,rakeDmg=18,strAmt=3,debuffAmt=3,numTurn=1,debuffUsed=false }
function TheCollector:init()
	if ascension >= 9 then
		self.maxHp = 300
		self.blockAmt = ascension >= 19 and 23 or 18
	end
	self.rakeDmg = ascension >= 4 and 21 or 18
	self.debuffAmt = ascension >= 19 and 5 or 3
	self.strAmt = ascension >= 19 and 5 or (ascension >= 4 and 4 or 3)
end

function TheCollector:drawImage()
	sprmap(51,27,5,self.height,self.x+12,self.y,8)
end

function TheCollector:rake()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function TheCollector:debuff()
	self.debuffUsed = true
	addAction(EffectAction:new(AnonymousEffect:new{duration=60,callback=function ()
		drawTalkBubble('@You@ @are@ @mine!@',self.x-65,self.y-25,60,35,self.x+8,self.y+6,12,15)
	end},10))
	addAction(ApplyPowerAction:new(WeakPower:new(player,self.debuffAmt,true)))
	addAction(ApplyPowerAction:new(VulnerablePower:new(player,self.debuffAmt,true)))
	addAction(ApplyPowerAction:new(FrailPower:new(player,self.debuffAmt,true)))
	addAction(NextIntentAction:new(self))
end

function TheCollector:defend()
	addAction(GainBlockAction:new{target=self,value=self.blockAmt})
	for _, enemy in ipairs(enemies) do
		if enemy.alive then
			addAction(ApplyPowerAction:new(StrengthPower:new(enemy,self.strAmt)))
		end
	end
	addAction(NextIntentAction:new(self))
end

function TheCollector:summon()
	for i = 1,2 do
		if not enemies[i].alive then
			local torchHead = TorchHead:new{createRandom=self.createRandom}
			local target = enemies[i]
			torchHead.x,torchHead.y = target.x+target.width*4-torchHead.width*4,target.y+target.height*8-torchHead.height*8
			addAction(SpawnMonsterAction:new{target=torchHead,index=i})
			addAction(ApplyPowerAction:new(MinionPower:new(torchHead)))
		end
	end
	addAction(NextIntentAction:new(self))
end

function TheCollector:enemyTurn()
	self.numTurn = self.numTurn + 1
	Monster.enemyTurn(self)
end

function TheCollector:nextIntent()
	if self.numTurn == 1 then
		self:setIntent('summon','unknown')
	elseif self.numTurn == 4 then
		self:setIntent('debuff','strongDebuff')
	elseif table.anyMatch(enemies,function (e) return e ~= self and not e.alive end) then
		self:rollIntent{
			{'summon','unknown',power=25,limit=1},
			{'rake','attack',self.rakeDmg,power=45,limit=2},
			{'defend','defendBuff',power=30,limit=1},
		}
	else
		self:rollIntent{
			{'rake','attack',self.rakeDmg,power=70,limit=2},
			{'defend','defendBuff',power=30,limit=1},
		}
	end
end

function TheCollector:die()
	Monster.die(self)
	for _,enemy in ipairs(enemies) do
		if enemy.alive and enemy ~= self then
			addAction(SuicideAction:new{target=enemy})
		end
	end
end

TorchHead = Monster:new{ maxHp=40,width=4,height=3 }
function TorchHead:init(random)
	self.maxHp = ascension >= 9 and random:randInt(40,45) or random:randInt(38,40)
	if ascension >= 4 then
		self.attackDmg = 12
	end
end

function TorchHead:drawImage()
	sprmap(48,27,3,self.height,self.x-2,self.y,0)
end

function TorchHead:attack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function TorchHead:nextIntent()
	self:setIntent('attack','attack',7)
end

-- encounters
TwoThievesEncounter = Encounter:new{spriteBank=1,name='TwoThieves',enemyInfo={encItem(Looter,-24,0),encItem(Mugger,24,0)}}
ThreeCultistsEncounter = Encounter:new{spriteBank=1,name='ThreeCultists',enemyInfo={encItem(Cultist,-48,1),encItem(Cultist,0,0),encItem(Cultist,48,0)}}
ThreeByrdsEncounter = Encounter:new{spriteBank=1,name='ThreeByrds',enemyInfo={encItem(Byrd,-48,0),encItem(Byrd,0,0),encItem(Byrd,48,0)}}
SphericGuardianEncounter = Encounter:new{spriteBank=3,name='SphericGuardian',enemyInfo={encItem(SphericGuardian,0,0)}}
SentryAndSphereEncounter = Encounter:new{spriteBank=3,name='SentryAndSphere',enemyInfo={encItem(SphericGuardian,20,0),encItem(Sentry,-30,1)}}
ChosenEncounter = Encounter:new{spriteBank=1,name='Chosen',enemyInfo={encItem(Chosen,0,0)}}
ByrdAndChosenEncounter = Encounter:new{spriteBank=1,name='ByrdAndChosen',enemyInfo={encItem(Byrd,-24,3),encItem(Chosen,24,0)}}
CultistAndChosenEncounter = Encounter:new{spriteBank=1,name='CultistAndChosen',enemyInfo={encItem(Cultist,-24,-1),encItem(Chosen,24,0)}}
ShellParasiteEncounter = Encounter:new{spriteBank=1,name='ShellParasite',enemyInfo={encItem(ShellParasite,0,0)}}
ShellParasiteAndFungiEncounter = Encounter:new{spriteBank=1,name='ShellParasiteAndFungi',enemyInfo={encItem(ShellParasite,-20,2),encItem(FungiBeast,28,0)}}
CenturionAndMysticEncounter = Encounter:new{spriteBank=4,name='CenturionAndMystic',enemyInfo={encItem(Centurion,-24,0),encItem(Mystic,24,2)}}
SnakePlantEncounter = Encounter:new{spriteBank=4,name='SnakePlant',enemyInfo={encItem(SnakePlant,0,0)}}
SneckoEncounter = Encounter:new{spriteBank=3,name='Snecko',enemyInfo={encItem(Snecko,0,0)}}

-- elite encounters
SlaversEncounter = Encounter:new{spriteBank=1,name='Slavers',enemyInfo={encItem(SlaverBlue,-48,0),encItem(Taskmaster,0,0),encItem(SlaverRed,48,1)}}
GremlinLeaderEncounter = Encounter:new{spriteBank=3,name='GremlinLeader'}
function GremlinLeaderEncounter:setupEnemies(random)
	self.enemyInfo = {}
	self.enemyInfo[1] = encItem(MonsterSlot,-72,6)
	self.enemyInfo[2] = encItem(gremlinPool[random:randInt(#gremlinPool)],-30,-1)
	self.enemyInfo[3] = encItem(gremlinPool[random:randInt(#gremlinPool)],12,-6)
	self.enemyInfo[4] = encItem(GremlinLeader,50,7)
	Encounter.setupEnemies(self,random)
end
BookOfStabbingEncounter = Encounter:new{spriteBank=5,name='BookOfStabbing',enemyInfo={encItem(BookOfStabbing,0,0)}}

-- boss encounters
TheCollectorEncounter = Encounter:new{spriteBank=5,name='TheCollector',enemyInfo={encItem(MonsterSlot,-58,1),encItem(MonsterSlot,-14,2),encItem(TheCollector,40,-3)},mapIcon=324}
