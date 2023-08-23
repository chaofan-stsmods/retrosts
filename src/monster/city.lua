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
	addAction(AnonymousAction:new(function ()
		self.flying = false
	end))
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

-- encounters
TwoThievesEncounter = Encounter:new{spriteBank=1,name='TwoThieves',enemyInfo={encItem(Looter,-24,0),encItem(Mugger,24,0)}}
ThreeCultistsEncounter = Encounter:new{spriteBank=1,name='ThreeCultists',enemyInfo={encItem(Cultist,-48,1),encItem(Cultist,0,0),encItem(Cultist,48,0)}}
ThreeByrdsEncounter = Encounter:new{spriteBank=1,name='ThreeByrds',enemyInfo={encItem(Byrd,-48,0),encItem(Byrd,0,0),encItem(Byrd,48,0)}}