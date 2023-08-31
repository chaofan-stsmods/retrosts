-- monster
---@diagnostic disable: lowercase-global

---@class Monster : Creature
Monster = {
	intent='takeTurn',intentType='attack',intentBaseDamage=0,intentDamage=0,intentAttackCount=1,showIntent=false,lockIntentDamage=false,
	takeTurn=noop,createRandom=nil,init=noop,lastIntent=nil,lastSecondIntent=nil,type='monster',
}
Creature:new(Monster)

function Monster:new(o)
	local r = Creature.new(self,o)
	if r.createRandom then
		r:init(r.createRandom)
		r.hp = r.maxHp
	end
	return r
end

function Monster:applyPowers()
	if self.lockIntentDamage or not self.alive then
		return
	end
	local damage = self.intentBaseDamage

	damage = self:triggerReducerEvent('onAttack',damage,player)
	damage = player:triggerReducerEvent('onAttacked',damage,self)

	self.intentDamage = math.floor(damage)
end

function Monster:onCombatStart()
	addAction(NextIntentAction:new(self,true,false))
	Creature.onCombatStart(self)
end

function Monster:onTurnEnd()
	Creature.onTurnEnd(self)
	addAction(AllEnemyTurnEndAction:new(self))
end

function Monster:enemyTurn()
	self.lockIntentDamage = true
	self[self.intent](self)
	self.lastSecondIntent = self.lastIntent
	self.lastIntent = self.intent
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

function Monster:die()
	Creature.die(self)
	player:triggerEvent('onMonsterDeath',self)
	checkCombatEnd()
end

function Monster:lastIntentIs(intent)
	return self.lastIntent == intent
end

function Monster:lastTwoIntentsAre(intent)
	return self.lastIntent == intent and self.lastSecondIntent == intent
end

function Monster:oneOfLastTwoIntentsIs(intent)
	return self.lastIntent == intent or self.lastSecondIntent == intent
end

intentSpriteMap = {
	attack={icons.AttackIntent},defend={icons.Block},attackDefend={icons.Block,icons.AttackIntent},buff={77},
	attackBuff={77,icons.AttackIntent},defendBuff={79},debuff={78},attackDebuff={78,icons.AttackIntent},
	strongDebuff={78},escape={72},stun={23}
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
			mapColor(7,8)
			mapColor(6,2)
			mapColor(5,12)
		end
		for i, intentSprite in ipairs(intentSprites) do
			drawIcon(intentSprite,intentX+(#intentSprites-i)*2,intentY-(#intentSprites-i)*2)
		end
		if self.intentType == 'strongDebuff' then
			resetColors{5,6,7}
		end
	elseif self.intentType == 'unknown' then
		printShadowed('?',intentX-3,intentY+2,4)
		printShadowed('?',intentX+5,intentY+2,4)
		printShadowed('?',intentX+1,intentY+1,4)
	elseif self.intentType == 'sleep' then
		printShadowed('z',intentX+6,intentY+4,3)
		printShadowed('z',intentX+2,intentY+2,4)
		printShadowed('Z',intentX-2,intentY,4)
	end
	if self.intentType:sub(1,6) == 'attack' then
		local damageStr = tostring(self.intentDamage)
		if self.intentAttackCount > 1 then
			damageStr = damageStr .. 'x' .. tostring(self.intentAttackCount)
		end
		local width = strWidth(damageStr,false,true)
		print(damageStr,intentX-width/2,intentY+5,isDarken and 13 or 12,false,1,true)
	end
end

function Monster:nextIntent(firstTurn)
end

function Monster:rollIntent(intentDefinition)
	local random = aiRand
	normalize(intentDefinition)
	local def,i = rollList(random,intentDefinition)
	if (def.limit == 1 and self:lastIntentIs(def[1])) or (def.limit == 2 and self:lastTwoIntentsAre(def[1])) then
		table.remove(intentDefinition,i)
		normalize(intentDefinition)
		def = rollList(random,intentDefinition)
	end
	self:setIntent(table.unpack(def))
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

HideMonsterAction = Action:new{target=nil,duration=10}
function HideMonsterAction:tick()
	if self.duration == self.startDuration then
		self.target.visible = false
	end
	Action.tick(self)
end

SpawnMonsterAction = Action:new{target=nil,index=nil,duration=20}
function SpawnMonsterAction:tick()
	if self.duration == self.startDuration then
		if self.index == nil then
			table.insert(enemies,self.target)
		else
			enemies[self.index] = self.target
		end
		self.target:onCombatStart()
	end
	Action.tick(self)
end

SuicideAction = Action:new{target=nil,duration=10}
function SuicideAction:tick()
	if self.duration == self.startDuration then
		self.target:die()
	end
	Action.tick(self)
end

EscapeAction = Action:new{target=nil,duration=30}
function EscapeAction:tick()
	if self.duration == self.startDuration then
		local target = self.target
		target:die()
		target.flipped = true
		addEffect(CreatureEffect:new{target=target,x=target.x,y=target.y,xSpeed=1})
	end
	Action.tick(self)
end
