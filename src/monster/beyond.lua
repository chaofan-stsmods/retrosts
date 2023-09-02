-- beyond monsters
---@diagnostic disable: lowercase-global

OrbWalker = Monster:new{ maxHp=51,width=6,height=3,laserDmg=10,clawDmg=15 }
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

-- encounters
OrbWalkerEncounter = Encounter:new{spriteBank=6,name='OrbWalker',enemyInfo={encItem(OrbWalker,0,0)}}

-- events
TwoOrbWalkersEncounter = Encounter:new{spriteBank=6,name='TwoOrbWalkers',enemyInfo={encItem(OrbWalker,-32,0),encItem(OrbWalker,32,0)}}
