---@diagnostic disable: lowercase-global
-- actions

actions = {}
runningAction = nil
function resetActions()
	actions = {}
	runningAction = nil
end

function addAction(pos,action)
	if action == nil then
		table.insert(actions,pos)
	else
		table.insert(actions,pos,action)
	end
end

function tickActions()
	if #actions > 0 and runningAction == nil then
		runningAction = table.remove(actions,1)
	end
	if runningAction then
		runningAction:tick()
		if runningAction.isDone then
			runningAction = nil
		end
	end
end

Action = Object:new{isDone=false,duration=10,startDuration=10}
function Action:new(o)
	if o and o.duration then
		o.startDuration = o.duration
	end
	return Object.new(self,o)
end

function Action:tick()
	self.duration = self.duration - 1
	if self.duration <= 0 then
		self.isDone = true
	end
end

DrawCardAction = Action:new()
function DrawCardAction:new(numCards)
	return Action.new(self,{numCards=numCards,duration=3})
end

function DrawCardAction:tick()
	if self.numCards <= 0 then
		self.isDone = true
		return
	end
	if self.numCards > #drawPile then
		addAction(1,ShuffleAction:new())
		addAction(2,DrawCardAction:new(self.numCards - #drawPile))
		self.numCards = #drawPile
	end
	self.duration = self.duration - 1
	if self.duration <= 0 then
		self.duration = 3
		self.numCards = self.numCards - 1
		if #hand > HAND_LIMIT or #drawPile == 0 then
			self.isDone = true
			return
		end
		local card = table.remove(drawPile,#drawPile)
		table.insert(hand,CardItem:new{card=card})
		card:applyPowers()
	end
end

ShuffleAction = Action:new()
function ShuffleAction:tick()
	for i=#discardPile,1,-1 do
		table.insert(drawPile,table.remove(discardPile,i))
	end
	shuffleRand:shuffle(drawPile)
	self.isDone = true
end

UseCardAction = Action:new{cardItem=nil,target=nil,duration=20}
function UseCardAction:new(cardItem,target)
	cardItem.isNotInHand = true
	cardItem.ty = cardItem.ty - 16
	if not cardItem.card.enemyTarget or cardItem.card.toAllEnemies then
		target = nil
	end
	return Action.new(self,{cardItem=cardItem,target=target})
end

function UseCardAction:tick()
	if self.duration == self.startDuration then
		local card = self.cardItem.card
		self.cardItem.tx = 120
		self.cardItem.ty = 68
		card:applyPowers(self.target)
		if not card:canUse() then
			self.isDone = true
			self.cardItem.isNotInHand = false
			return
		end
		local handIndex = table.indexOf(hand,self.cardItem)
		if handIndex then
			removeHand(handIndex)
			table.insert(limbo,self.cardItem)
		end
		local cardActions = card:use(self.target) or {}
		for i = 1, #cardActions do
			addAction(i,cardActions[i])
		end
		addAction(#cardActions+1,UseCardEndAction:new(self.cardItem,self.target))
		if card.cost > 0 then
			energy = energy - card.cost
		end
	end
	Action.tick(self)
end

UseCardEndAction = Action:new{cardItem=nil,target=nil,duration=20}
function UseCardEndAction:new(cardItem,target)
	return Action.new(self,{cardItem=cardItem,target=target})
end

function UseCardEndAction:tick()
	local card = self.cardItem.card
	if card.type == 'power' then
		self.cardItem.tx = player.x+player.width*4
		self.cardItem.ty = player.y+player.height*4
	elseif card.exhaust then
		self.cardItem.tx = 120
		self.cardItem.ty = -32
	else
		self.cardItem.tx = 240
		self.cardItem.ty = 136
	end
	Action.tick(self)
	if self.isDone or (math.abs(self.cardItem.tx - self.cardItem.x) < 2 and math.abs(self.cardItem.ty - self.cardItem.y) < 2) then
		local limboIndex = table.indexOf(limbo,self.cardItem)
		if limboIndex then
			table.remove(limbo,limboIndex)
		end
		card:resetPowers()
		if card.type ~= 'power' then
			if card.exhaust then
				table.insert(exhaustPile,self.cardItem.card)
			else
				table.insert(discardPile,self.cardItem.card)
			end
		end
		handApplyPowers()
		self.isDone = true
	end
end

DamageAction = Action:new{source=nil,target=nil,value=nil,type=nil,duration=10}
function DamageAction:tick()
	if not self.source.alive then
		self.isDone = true
		return
	end
	if self.duration == self.startDuration then
		self.target:damage(self.source,self.value,self.type)
	end
	Action.tick(self)
end

DamageAllEnemiesAction = Action:new{source=nil,value=nil,type=nil,duration=10}
function DamageAllEnemiesAction:tick()
	if not self.source.alive then
		self.isDone = true
		return
	end
	if self.duration == self.startDuration then
		for i, enemy in ipairs(enemies) do
			if enemy.alive then
				enemy:damage(self.source,self.value[i],self.type)
			end
		end
	end
	Action.tick(self)
end

DamageRandomEnemyAction = Action:new{source=nil,value=nil,type=nil,duration=10}
function DamageRandomEnemyAction:tick()
	if not self.source.alive then
		self.isDone = true
		return
	end
	if self.duration == self.startDuration then
		local aliveEnemies = {}
		for i, enemy in ipairs(enemies) do
			if enemy.alive then
				table.insert(aliveEnemies,{enemy=enemy,damage=self.value[i]})
			end
		end
		local target = aliveEnemies[miscRand:randInt(#aliveEnemies)]
		target.enemy:damage(self.source,target.damage,self.type)
	end
	Action.tick(self)
end

GainBlockAction = Action:new{target=nil,value=nil,duration=10}
function GainBlockAction:tick()
	if self.duration == self.startDuration and self.target.alive then
		self.target.block = self.target.block + self.value
	end
	Action.tick(self)
end

EndTurnAction = Action:new{duration=10}
function EndTurnAction:tick()
	if self.duration == self.startDuration then
		for i = #actions,1,-1 do
			if getmetatable(actions[i]) == UseCardAction then
				table.remove(actions,i)
			end
		end
		addAction(DiscardAllCardsAction:new())
		player:onTurnEnd()
		for _, enemy in ipairs(enemies) do
			if enemy.alive then
				enemy:onTurnStart()
			end
		end
		for _, enemy in ipairs(enemies) do
			if enemy.alive then
				enemy:enemyTurn()
			end
		end
		for _, enemy in ipairs(enemies) do
			if enemy.alive then
				enemy:onTurnEnd()
			end
		end
		addAction(NewTurnAction:new())
	end
	Action.tick(self)
end

DiscardAllCardsAction = Action:new{duration=20}
function DiscardAllCardsAction:tick()
	Action.tick(self)
	for i = #hand,1,-1 do
		local cardItem = hand[i]
		cardItem.isNotInHand = true
		cardItem.tx = 240
		cardItem.ty = 136
		if self.isDone or (math.abs(cardItem.tx - cardItem.x) < 2 and math.abs(cardItem.ty - cardItem.y) < 2) then
			removeHand(i)
			table.insert(discardPile,cardItem.card)
		end
	end
	if #hand == 0 then
		self.isDone = true
	end
end

NewTurnAction = Action:new{duration=10}
function NewTurnAction:tick()
	if self.duration == self.startDuration then
		player:onTurnStart()
		addAction(DrawCardAction:new(5))
		energy = maxEnergy
	end
	Action.tick(self)
	if self.isDone then
		inEnemyTurn = false
		turn = turn + 1
	end
end

ReducePowerAction = Action:new{duration=10}
function ReducePowerAction:new(power,amount)
	return Action.new(self,{power=power,amount=amount})
end

function ReducePowerAction:tick()
	if self.duration == self.startDuration then
		local power = self.power
		local owner = power.owner
		power.amount = power.amount - self.amount
		if power.amount == 0 then
			owner:removePower(power)
		else
			power:onAmountUpdated()
		end
		owner:applyPowers()
	end
	Action.tick(self)
end

ApplyPowerAction = Action:new{duration=10}
function ApplyPowerAction:new(power)
	return Action.new(self,{power=power})
end

function ApplyPowerAction:tick()
	if self.duration == self.startDuration then
		local power = self.power
		local owner = power.owner
		local existingPower = owner:getPower(getmetatable(power))
		if existingPower then
			existingPower.amount = limit(existingPower.amount+power.amount,-existingPower.maxAmount,existingPower.maxAmount)
			if existingPower.amount == 0 then
				owner:removePower(existingPower)
			else
				existingPower:onAmountUpdated()
			end
		else
			owner:addPower(power)
		end
		owner:applyPowers()
	end
	Action.tick(self)
end

GainEnergyAction = Action:new{duration=10}
function GainEnergyAction:new(amount)
	return Action.new(self,{amount=amount})
end

function GainEnergyAction:tick()
	if self.duration == self.startDuration then
		energy = energy + self.amount
	end
	Action.tick(self)
end

XCardAction = Action:new()
function XCardAction:new(callback)
	return Action.new(self,{callback=callback})
end

function XCardAction:tick()
	if self.duration == self.startDuration then
		if self.callback then
			local actions = self.callback(energy) or {}
			for i = 1, #actions do
				addAction(i,actions[i])
			end
		end
		energy = 0
	end
	Action.tick(self)
end

AnonymousAction = Action:new()
function AnonymousAction:new(callback)
	return Action.new(self,{callback=callback})
end

function AnonymousAction:tick()
	if self.callback then
		self.callback()
	end
	self.isDone = true
end

MakeTempCardToDiscardPileAction = Action:new{duration=30}
function MakeTempCardToDiscardPileAction:new(card,amount)
	amount = amount or 1
	return Action.new(self,{card=card,amount=amount})
end

local cardPositionCandidates = {{80,68},{160,68},{40,68},{200,68},{100,28},{140,28},{60,28},{180,28}}
function MakeTempCardToDiscardPileAction:tick()
	if self.duration == self.startDuration then
		for _ = 1,self.amount do
			local card = self.card:copy()
			table.insert(discardPile,card)
			card:resetPowers()
			local cardItem = CardItem:new{card=card,x=0,y=136}
			local effect = CardEffect:new{cardItem=cardItem,pauseDuration=30,duration=50,tx=240,ty=136}
			local useCandidates = false
			for j = 1,#cardPositionCandidates do
				if table.allMatch(effects,function (e) return e.useCardPosition ~= j end) then
					useCandidates = true
					cardItem.tx,cardItem.ty = table.unpack(cardPositionCandidates[j])
					effect.useCardPosition = j
					break
				end
			end
			if not useCandidates then
				cardItem.tx,cardItem.ty = miscRand:randInt(32,208),miscRand:randInt(40,104)
			end
			addEffect(effect)
		end
	end
	Action.tick(self)
end
