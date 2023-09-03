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

Reptomancer = Monster:new{ maxHp=190,width=6,height=5,strikeDmg=13,biteDmg=30,daggerCount=1 }
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

-- encounters
OrbWalkerEncounter = Encounter:new{spriteBank=6,name='OrbWalker',enemyInfo={encItem(OrbWalker,0,0)}}

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

-- events
TwoOrbWalkersEncounter = Encounter:new{spriteBank=6,name='TwoOrbWalkers',enemyInfo={encItem(OrbWalker,-32,0),encItem(OrbWalker,32,0)}}
