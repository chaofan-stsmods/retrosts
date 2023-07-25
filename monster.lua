-- monster
---@diagnostic disable: lowercase-global

Monster = Creature:new{
	intent='takeTurn',intentType='attack',intentBaseDamage=0,intentDamage=0,intentAttackCount=1,showIntent=false,lockIntentDamage=false,
	takeTurn=noop,
	nextIntent=function(self,firstTurn) end,
}

function Monster:applyPowers()
	if self.lockIntentDamage then
		return
	end
	local damage = self.intentBaseDamage

	for _, power in ipairs(self.powers) do
		damage = power:onAttack(damage,player)
	end

	for _, power in ipairs(player.powers) do
		damage = power:onAttacked(damage,self)
	end

	self.intentDamage = math.floor(damage)
end

function Monster:onCombatStart()
	addAction(NextIntentAction:new(self,true,false))
	Creature:onCombatStart()
end

function Monster:onTurnEnd()
	addAction(AllEnemyTurnEndAction:new(self))
	Creature:onTurnEnd()
end

function Monster:enemyTurn()
	self.lockIntentDamage = true
	self[self.intent](self)
	addAction(EnemyTurnEndAction:new(self))
end

function Monster:setIntent(id,type,baseDamage,attackCount)
	baseDamage = baseDamage or 0
	attackCount = attackCount or 1
	self.intent = id
	self.intentType = type
	self.intentBaseDamage = baseDamage
	self.intentAttackCount = attackCount
	self:applyPowers()
end

function Monster:tick()
	Creature.tick(self)
	if self.visible then
		self:drawIntent()
	end
end

intentSpriteMap = {
	attack={76},defend={47},attackDefend={76,47},buff={77},attackBuff={76,77},defendBuff={79},debuff={78},attackDebuff={76,78},
	strongDebuff={77}
}
function Monster:drawIntent()
	if not self.showIntent then
		return
	end
	local intentX = self.x+self.width*4-4
	local intentY = self.y-16
	local intentSprites = intentSpriteMap[self.intentType]
	if intentSprites then
		if self.intentType == 'strongDebuff' then
			mapColor(7,1)
			mapColor(6,2)
			mapColor(5,3)
		end
		for _, intentSprite in ipairs(intentSprites) do
			spr(intentSprite,intentX,intentY,0)
		end
		if self.intentType == 'strongDebuff' then
			resetColors{5,6,7}
		end
	end
	if self.intentType:sub(1,6) == 'attack' then
		local damageStr = tostring(self.intentDamage)
		if self.intentAttackCount > 1 then
			damageStr = damageStr .. 'x' .. tostring(self.intentAttackCount)
		end
		local width = strWidth(damageStr,false,true)
		print(damageStr,intentX-width/2,intentY+5,12,false,1,true)
	end
end

-- actions

NextIntentAction = Action:new{duration=5}
function NextIntentAction:new(owner,firstTurn,hideIntent)
	hideIntent = hideIntent == nil and true or hideIntent
	return Action.new(self,{owner=owner,firstTurn=firstTurn,hideIntent=hideIntent})
end

function NextIntentAction:tick()
	if self.duration == self.startDuration then
		local owner = self.owner;
		owner:nextIntent(self.firstTurn)
		owner.showIntent = not self.hideIntent
	end
	Action.tick(self)
end

EnemyTurnEndAction = Action:new{duration=5}
function EnemyTurnEndAction:new(owner)
	return Action.new(self,{owner=owner})
end

function EnemyTurnEndAction:tick()
	if self.duration == self.startDuration then
		local owner = self.owner;
		owner.showIntent = false
		owner.lockIntentDamage = false
		owner:applyPowers()
	end
	Action.tick(self)
end

AllEnemyTurnEndAction = Action:new{duration=5}
function AllEnemyTurnEndAction:new(owner)
	return Action.new(self,{owner=owner})
end

function AllEnemyTurnEndAction:tick()
	if self.duration == self.startDuration then
		local owner = self.owner;
		owner.showIntent = true
	end
	Action.tick(self)
end

SetIntentAction = Action:new{duration=5}
function SetIntentAction:new(owner,id,type,damage,attackCount,hideIntent)
	hideIntent = hideIntent == nil and true or hideIntent
	return Action.new(self,{owner=owner,args=table.pack(id,type,damage,attackCount),hideIntent=hideIntent})
end

function SetIntentAction:tick()
	if self.duration == self.startDuration then
		local owner = self.owner;
		owner:setIntent(table.unpack(self.args))
		if self.hideIntent then
			owner.showIntent = false
		end
	end
	Action.tick(self)
end

-- instances

Cultist = Monster:new{ maxHp=51,x=160,y=48,width=4,height=4 }
function Cultist:drawImage()
	sprmap(5,17,self.width,self.height,self.x,self.y,0,1)
end

function Cultist:buff()
	addAction(ApplyPowerAction:new(RitualPower:new(self,3)))
	addAction(SetIntentAction:new(self,'attack','attack',6,1))
end

function Cultist:attack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(SetIntentAction:new(self,'attack','attack',6,1))
end

function Cultist:nextIntent()
	self:setIntent('buff','buff')
end

