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
function UseCardAction:new(cardIndex,target)
	local cardItem = hand[cardIndex]
	cardItem.isNotInHand = true
	cardItem.ty = cardItem.ty - 16
	if not cardItem.card.enemyTarget or cardItem.card.toAllEnemy then
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
		local cardActions = card:use(self.target) or {}
		for i = 1, #cardActions do
			addAction(i,cardActions[i])
		end
		addAction(#cardActions+1,UseCardEndAction:new(self.cardItem,self.target))
		if card.cost == -1 then
			energy = 0
		elseif card.cost > 0 then
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
	self.cardItem.tx = 240
	self.cardItem.ty = 136
	Action.tick(self)
	if self.isDone or (math.abs(self.cardItem.tx - self.cardItem.x) < 2 and math.abs(self.cardItem.ty - self.cardItem.y) < 2) then
		for i = #hand,1,-1 do
			if hand[i] == self.cardItem then
				removeHand(i)
				break
			end
		end
		table.insert(discardPile,self.cardItem.card)
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

GainBlockAction = Action:new{target=nil,value=nil,duration=10}
function GainBlockAction:tick()
	if self.duration == self.startDuration then
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
			owner:removePower(self.power)
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
			existingPower:onAmountUpdated()
		else
			owner:addPower(power)
		end
		owner:applyPowers()
	end
	Action.tick(self)
end
