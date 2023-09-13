---@diagnostic disable: lowercase-global
-- actions

---@type Action[]
actions = {}
---@type Action[]
secondaryActions = {}
---@type Action?
runningAction = nil
function resetActions()
	actions = {}
	secondaryActions = {}
	runningAction = nil
end

function addAction(pos,action)
	if action == nil then
		local queue = pos.secondary and secondaryActions or actions
		table.insert(queue,pos)
	else
		local queue = action.secondary and secondaryActions or actions
		table.insert(queue,pos,action)
	end
end

function tickActions()
	if runningAction == nil then
		if #actions > 0 then
			runningAction = table.remove(actions,1)
		elseif #secondaryActions > 0 then
			runningAction = table.remove(secondaryActions,1)
		end
	end
	if runningAction then
		runningAction:tick()
		if runningAction.isDone then
			runningAction = nil
		end
	end
end

---@class Action : Object
---@field duration integer?
---@field startDuration integer?
Action = {isDone=false,duration=10,startDuration=10,secondary=false}
Object:new(Action)

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

WaitAction = Action:new()
function WaitAction:new(duration)
	return Action.new(self,{duration=duration})
end

DrawCardAction = Action:new{cardDrawn=nil}
function DrawCardAction:new(numCards,o)
	o = o or {}
	o.numCards = numCards
	o.duration = o.duration or 3
	o.cardDrawn = o.cardDrawn or {}
	return Action.new(self,o)
end

function DrawCardAction:tick()
	if self.numCards <= 0 or player:getPower(NoDrawPower) or (#discardPile == 0 and #drawPile == 0) then
		self.isDone = true
		return
	end
	if self.numCards > #drawPile then
		addAction(1,ShuffleAction:new())
		addAction(2,DrawCardAction:new(self.numCards-#drawPile,{cardDrawn=self.cardDrawn}))
		self.numCards = #drawPile
	end
	self.duration = self.duration - 1
	if self.duration <= 0 then
		self.duration = 3
		self.numCards = self.numCards - 1
		if #hand >= HAND_LIMIT or #drawPile == 0 then
			self.isDone = true
			return
		end
		local card = table.remove(drawPile,#drawPile)
		insertHand(CardItem:new{card=card})
		table.insert(self.cardDrawn,card)
		player:triggerEvent('onDraw',card)
	end
end

ShuffleAction = Action:new()
function ShuffleAction:tick()
	for i=#discardPile,1,-1 do
		table.insert(drawPile,table.remove(discardPile,i))
	end
	shuffleRand:shuffle(drawPile)
	player:triggerEvent('onShuffle')
	self.isDone = true
end

UseCardAction = Action:new{
	cardItem=nil,target=nil,secondary=false,exhaust=false,rebound=false,randomTarget=false,free=false,forceUse=false,energyOnUse=nil,
	tempCard=false,isDoubleTap=false,autoPlay=false,triggerOnUseCard=true,fromHand=false,tx=120,ty=68,duration=20
}
function UseCardAction:new(o)
	local cardItem = o.cardItem
	cardItem.isNotInHand = true
	if not cardItem.card.enemyTarget or cardItem.card.toAllEnemies then
		o.target = nil
	end
	return Action.new(self,o)
end

function UseCardAction:tick()
	if self.duration == self.startDuration then
		local card = self.cardItem.card
		self.cardItem.tx = self.tx
		self.cardItem.ty = self.ty
		local handIndex = table.indexOf(hand,self.cardItem)
		-- can't play a card that is not in hand
		if self.fromHand and handIndex == nil then
			self.isDone = true
			return
		end
		if self.randomTarget and card.enemyTarget and not card.toAllEnemies then
			local target = getRandomInteractableEnemy()
			if target then
				self.target = target
			end
		end
		if self.target == nil and card.enemyTarget and card.toAllEnemies then
			card:applyPowers(true)
		else
			card:applyPowers(self.target)
		end
		if not self.forceUse and (not card:canUse(self.free) or (self.target ~= nil and not self.target.canInteract)) then
			if self.fromHand and handIndex then
				self.cardItem.isNotInHand = false
				self.isDone = true
			else
				addAction(1,self:makeUseCardEndAction(false))
			end
			Action.tick(self)
			return
		end
		card.free = false
		if self.fromHand and handIndex then
			removeHand(handIndex)
			if not table.indexOf(limbo,self.cardItem) then
				table.insert(limbo,self.cardItem)
			end
		end
		trace('useCard '..card.name)
		self.energyOnUse = self.energyOnUse or energy
		local cardActions
		if self.autoPlay then
			cardActions = card:autoPlay(self.target,self.energyOnUse,self.free) or {}
		else
			cardActions = card:use(self.target,self.energyOnUse,self.free) or {}
		end
		for i,cardAction in ipairs(cardActions) do
			addAction(i,cardAction)
		end
		if not self.autoPlay and self.triggerOnUseCard then
			player:triggerEvent('onUseCard',card,self.target,self)
			for _, enemy in ipairs(enemies) do
				enemy:triggerEvent('onUseCard',card,self.target,self)
			end
		end
		addAction(#cardActions+1,self:makeUseCardEndAction(true))
		local cost = card:getCost()
		if cost > 0 and not self.free then
			energy = energy - cost
		end
	end
	Action.tick(self)
end

function UseCardAction:makeUseCardEndAction(used)
	return UseCardEndAction:new{
		cardItem=self.cardItem,exhaust=self.exhaust,rebound=self.rebound,used=used,
		useCardPosition=self.useCardPosition,tempCard=self.tempCard,
	}
end

UseCardEndAction = Action:new{cardItem=nil,exhaust=false,rebound=false,tempCard=false,used=true,duration=20}
function UseCardEndAction:tick()
	local card = self.cardItem.card
	if self.duration == self.startDuration then
		local exhaust = card.exhaust or self.exhaust
		if exhaust and not self.tempCard and self.used and hasRelic(StrangeSpoon) and miscRand:randBool() then
			exhaust = false
		end
		self.exhaust = exhaust
		if card.type == 'power' then
			self.cardItem.tx = player.x+player.width*4
			self.cardItem.ty = player.y+player.height*4
		elseif exhaust or self.tempCard then
			--self.cardItem.tx = 120
			self.cardItem.ty = -32
		elseif self.rebound then
			self.cardItem.tx = 0
			self.cardItem.ty = 136
		else
			self.cardItem.tx = 240
			self.cardItem.ty = 136
		end
	end
	Action.tick(self)
	if self.isDone or (math.abs(self.cardItem.tx - self.cardItem.x) < 2 and math.abs(self.cardItem.ty - self.cardItem.y) < 2) then
		local limboIndex = table.indexOf(limbo,self.cardItem)
		if limboIndex then
			table.remove(limbo,limboIndex)
		end
		card.costForOneTurnPlay = nil
		card.costForOnePlay = nil
		card:resetPowers()
		if card.type ~= 'power' and not self.tempCard then
			if self.exhaust then
				table.insert(exhaustPile,self.cardItem.card)
				player:triggerEvent('onExhaust',card)
			elseif self.rebound then
				table.insert(drawPile,self.cardItem.card)
			else
				table.insert(discardPile,self.cardItem.card)
			end
		end
		handApplyPowers()
		self.isDone = true
	end
end

UsePotionAction = Action:new{potion=nil,target=nil,duration=1,secondary=true}
function UsePotionAction:tick()
	if self.duration == self.startDuration then
		local potion = self.potion
		local potionIndex = table.indexOf(potions,potion)
		if not potion:canUse() or not potionIndex or (self.target ~= nil and not self.target.canInteract) then
			self.isDone = true
			return
		end
		potion:applyPowers()
		local potionActions = potion:use(self.target) or {}
		for i,potionAction in ipairs(potionActions) do
			addAction(i,potionAction)
		end
		player:triggerEvent('onUsePotion',potion,true,self.target)
		potions[potionIndex] = PotionSlot
	end
	Action.tick(self)
end

DamageAction = Action:new{source=nil,target=nil,value=nil,type=nil,color=2,duration=10}
function DamageAction:tick()
	if not self.source.alive and (self.type or 'attack') == 'attack' then
		self.isDone = true
		return
	end
	if self.duration == self.startDuration then
		self.target:damage(self.source,self.value,self.type,self)
	end
	Action.tick(self)
end

DamageAllEnemiesAction = Action:new{source=nil,value=nil,type=nil,color=2,duration=10}
function DamageAllEnemiesAction:tick()
	if not self.source.alive and (self.type or 'attack') == 'attack' then
		self.isDone = true
		return
	end
	if self.duration == self.startDuration then
		for i, enemy in ipairs(enemies) do
			if enemy.canInteract then
				if type(self.value) == 'number' then
					enemy:damage(self.source,self.value,self.type,self)
				else
					enemy:damage(self.source,self.value[i],self.type,self)
				end
			end
		end
	end
	Action.tick(self)
end

DamageRandomEnemyAction = Action:new{source=nil,value=nil,type=nil,color=2,duration=10,onModifyDamage=nil}
function DamageRandomEnemyAction:tick()
	if not self.source.alive and (self.type or 'attack') == 'attack' then
		self.isDone = true
		return
	end
	if self.duration == self.startDuration then
		local target,index = getRandomInteractableEnemy()
		if target then
			if type(self.value) == 'number' then
				local damage = self.value
				if self.onModifyDamage then
					damage = self.onModifyDamage(damage,target)
				end
				target:damage(self.source,math.floor(damage),self.type,self)
			else
				local damage = self.value[index]
				if self.onModifyDamage then
					damage = self.onModifyDamage(damage,target)
				end
				target:damage(self.source,math.floor(damage),self.type,self)
			end
		end
	end
	Action.tick(self)
end

GainBlockAction = Action:new{target=nil,value=nil,duration=10}
function GainBlockAction:tick()
	if self.duration == self.startDuration and self.target.canInteract then
		local oldBlock = self.target.block
		self.target.block = math.min(self.target.block+self.value,999)
		self.target:triggerEvent('onGainBlock',self.target.block-oldBlock)
	end
	Action.tick(self)
end

HealAction = Action:new{target=nil,value=nil,duration=10}
function HealAction:tick()
	if self.duration == self.startDuration and self.target.alive then
		self.target:heal(self.value)
	end
	Action.tick(self)
end

EndTurnAction = Action:new{duration=10,secondary=true}
function EndTurnAction:tick()
	if self.duration == self.startDuration then
		inEnemyTurn = true
		for i = #secondaryActions,1,-1 do
			table.remove(secondaryActions,i)
		end
		addAction(AutoPlayOnEndTurnAction:new())
		addAction(HandleRemainingCardsAction:new{shouldDiscard=not hasRelic(RunicPryamid)})
		player:onTurnEnd()
		for _, enemy in ipairs(enemies) do
			if enemy.alive then
				enemy:onTurnStart(turn)
			end
		end
		for _, enemy in ipairs(enemies) do
			if enemy.alive then
				addAction(EnemeyTurnAction:new{enemy=enemy})
			end
		end
		for _, enemy in ipairs(enemies) do
			if enemy.alive then
				addAction(EnemeyTurnEndAction:new{enemy=enemy})
			end
		end
		addAction(NewTurnAction:new())
	end
	Action.tick(self)
end

EnemeyTurnAction = Action:new{secondary=true,enemy=nil}
function EnemeyTurnAction:tick()
	self.enemy:enemyTurn()
	self.isDone = true
end

EnemeyTurnEndAction = Action:new{secondary=true,enemy=nil}
function EnemeyTurnEndAction:tick()
	if self.enemy.alive then
		self.enemy:onTurnEnd()
	end
	self.isDone = true
end

AutoPlayOnEndTurnAction = Action:new{secondary=true}
function AutoPlayOnEndTurnAction:tick()
	local autoPlayCards = {}
	for i = #hand,1,-1 do
		local cardItem = hand[i]
		if cardItem.card.autoPlayOnEndTurn then
			table.insert(autoPlayCards,cardItem)
		end
	end
	miscRand:shuffle(autoPlayCards)
	for i,cardItem in ipairs(autoPlayCards) do
		addAction(1,UseCardAction:new{cardItem=cardItem,secondary=true,forceUse=true,fromHand=true,autoPlay=true})
	end
	self.isDone = true
end

HandleRemainingCardsAction = Action:new{secondary=true,shouldDiscard=true}
function HandleRemainingCardsAction:tick()
	local etherealCards = {}
	for i = #hand,1,-1 do
		local cardItem = hand[i]
		if cardItem.card.ethereal then
			table.insert(etherealCards,cardItem)
		end
	end
	miscRand:shuffle(etherealCards)
	for i, cardItem in ipairs(etherealCards) do
		addAction(i,AnonymousAction:new(function()
			removeHand(table.indexOf(hand,cardItem))
			addAction(1,ExhaustCardAction:new{cardItem=cardItem,duration=5})
		end))
	end
	if self.shouldDiscard then
		addAction(#etherealCards+1,DiscardNonRetainCardsAction:new())
	end
	self.isDone = true
end

DiscardNonRetainCardsAction = Action:new{duration=20}
function DiscardNonRetainCardsAction:tick()
	Action.tick(self)
	local numRetained = 0
	for i = #hand,1,-1 do
		local cardItem = hand[i]
		if cardItem.card.retain or cardItem.card.tempRetain then
			numRetained = numRetained + 1
		else
			cardItem.isNotInHand = true
			cardItem.tx = 240
			cardItem.ty = 136
			if self.isDone or (math.abs(cardItem.tx - cardItem.x) < 2 and math.abs(cardItem.ty - cardItem.y) < 2) then
				removeHand(i)
				table.insert(discardPile,cardItem.card)
				cardItem.card:resetPowers()
				cardItem.card.costForOneTurnPlay = nil
			end
		end
	end
	if #hand == numRetained then
		for _,cardItem in ipairs(hand) do
			cardItem.card.tempRetain = false
			cardItem.card.costForOneTurnPlay = nil
		end
		self.isDone = true
	end
end

NewTurnAction = Action:new{duration=10,secondary=true,additionalCard=0}
function NewTurnAction:tick()
	if self.duration == self.startDuration then
		player:onTurnStart(turn + 1)
		addAction(DrawCardAction:new(player:triggerReducerEvent('modifyTurnStartDrawCount',5+self.additionalCard)))
		player:triggerEvent('onTurnStartPostDraw', turn + 1)
		if turn ~= 0 then
			energy = player:triggerReducerEvent('onTurnStartResetEnergy',maxEnergy,energy)
		end
	end
	Action.tick(self)
	if self.isDone then
		inEnemyTurn = false
		endTurnPressed = false
		turn = turn + 1
	end
end

EndCombatAction = Action:new{secondary=true,escaped=false}
function EndCombatAction:tick()
	combatEnd(self.escaped)
	self.isDone = true
end

ReducePowerAction = Action:new{duration=10}
function ReducePowerAction:new(power,amount)
	return Action.new(self,{power=power,amount=amount})
end

function ReducePowerAction:tick()
	if self.duration == self.startDuration then
		local power = self.power
		local owner = power.owner
		power:setAmount(power.amount - self.amount)
		if power.amount == 0 then
			owner:removePower(power)
		end
		owner:applyPowers()
	end
	Action.tick(self)
end

ApplyPowerAction = Action:new{duration=10,succeeded=false}
function ApplyPowerAction:new(source,power)
	return Action.new(self,{source=source,power=power})
end

function ApplyPowerAction:tick()
	if self.duration == self.startDuration then
		local power = self.power
		local owner = power.owner
		if not owner.canInteract then
			self.isDone = true
			return
		end
		self.source:triggerEvent('onBeforeApplyPower',power)
		if not owner:triggerConditionEvent('onBeforeGainPower',true,power) then
			Action.tick(self)
			return
		end

		local existingPower = owner:getPower(getmetatable(power))
		if existingPower then
			existingPower:stackPower(power)
			if existingPower.amount == 0 then
				owner:removePower(existingPower)
			end
		else
			owner:addPower(power)
		end
		owner:applyPowers()
		if power.debuff then
			owner:addDebuffAnimation()
		end
		self.succeeded = true
		self.source:triggerEvent('onAppliedPower',power)
	end
	Action.tick(self)
end

RemovePowerAction = Action:new{duration=10}
function RemovePowerAction:new(power)
	return Action.new(self,{power=power})
end

function RemovePowerAction:tick()
	if self.duration == self.startDuration then
		local power = self.power
		local owner = power.owner
		owner:removePower(power)
		owner:applyPowers()
	end
	Action.tick(self)
end

RemovePowerByTypeAction = Action:new{duration=10}
function RemovePowerByTypeAction:new(target,powerType)
	return Action.new(self,{target=target,powerType=powerType})
end

function RemovePowerByTypeAction:tick()
	if self.duration == self.startDuration then
		local powerType = self.powerType
		local owner = self.target
		local power = owner:getPower(powerType)
		if power then
			owner:removePower(power)
			owner:applyPowers()
		end
	end
	Action.tick(self)
end

GainEnergyAction = Action:new{duration=10}
function GainEnergyAction:new(amount)
	return Action.new(self,{amount=amount})
end

function GainEnergyAction:tick()
	if self.duration == self.startDuration then
		energy = math.max(0, energy + self.amount)
	end
	Action.tick(self)
end

XCardAction = Action:new{free=false,energyOnUse=nil}
function XCardAction:new(callback,energyOnUse,free)
	return Action.new(self,{callback=callback,energyOnUse=energyOnUse,free=free})
end

function XCardAction:tick()
	if self.duration == self.startDuration then
		if self.callback then
			local amount = self.energyOnUse or energy
			amount = player:triggerReducerEvent('modifyXCardAmount',amount)
			local actions = self.callback(amount) or {}
			for i = 1, #actions do
				addAction(i,actions[i])
			end
		end
		if not self.free then
			energy = 0
		end
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

local cardPositionCandidates = {{120,68},{80,68},{160,68},{40,68},{200,68},{100,28},{140,28},{60,28},{180,28}}
function fillCardPosition(cardItem,preferedPosition)
	if preferedPosition then
		cardItem.tx,cardItem.ty = table.unpack(cardPositionCandidates[preferedPosition])
		return preferedPosition
	end

	local useCandidates = false
	local start = inEnemyTurn and 1 or 2
	for j = start,#cardPositionCandidates do
		if table.allMatch(effects,function (e) return e.useCardPosition ~= j end) and
			table.allMatch(actions,function (e) return e.useCardPosition ~= j end) and
			table.allMatch(secondaryActions,function (e) return e.useCardPosition ~= j end) and
			(runningAction == nil or runningAction.useCardPosition ~= j) then
			useCandidates = true
			cardItem.tx,cardItem.ty = table.unpack(cardPositionCandidates[j])
			return j
		end
	end
	if not useCandidates then
		cardItem.tx,cardItem.ty = miscRand:randInt(32,208),miscRand:randInt(40,104)
	end
	return nil
end

MakeTempCardToDiscardPileAction = Action:new{duration=10}
function MakeTempCardToDiscardPileAction:new(card,amount,o)
	o = o or {}
	o.card = card
	o.amount = amount or 1
	return Action.new(self,o)
end

function MakeTempCardToDiscardPileAction:tick()
	if self.duration == self.startDuration then
		for _ = 1,self.amount do
			local card = self.card:copy()
			table.insert(discardPile,card)
			card:resetPowers()
			local cardItem = self.cardItem and self.cardItem:copy() or CardItem:new{card=card,x=0,y=136,isNotInHand=true}
			local additionalPause = self.pauseDuration or 0
			local effect = CardEffect:new{cardItem=cardItem,pauseDuration=30+additionalPause,duration=50+additionalPause,tx=240,ty=136}
			effect.useCardPosition = fillCardPosition(cardItem)
			addEffect(effect)
		end
	end
	Action.tick(self)
end

MakeTempCardToHandAction = Action:new{duration=10}
function MakeTempCardToHandAction:new(card,amount,o)
	o = o or {}
	o.card = card
	o.amount = amount or 1
	return Action.new(self,o)
end

function MakeTempCardToHandAction:tick()
	if self.duration == self.startDuration then
		if #hand+self.amount > HAND_LIMIT then
			addAction(1,MakeTempCardToDiscardPileAction:new(self.card,#hand+self.amount-HAND_LIMIT))
			if HAND_LIMIT-#hand > 0 then
				self.amount = HAND_LIMIT-#hand
			else
				self.isDone = true
				return
			end
		end
		for _ = 1,self.amount do
			local card = self.card:copy()
			local cardItem = self.cardItem and self.cardItem:copy() or CardItem:new{x=0,y=136}
			cardItem.card = card
			insertHand(cardItem)
		end
	end
	Action.tick(self)
end

MakeTempCardToDrawPileAction = Action:new{duration=10,putOnTop=false}
function MakeTempCardToDrawPileAction:new(card,amount,o)
	o = o or {}
	o.card = card
	o.amount = amount or 1
	return Action.new(self,o)
end

function MakeTempCardToDrawPileAction:tick()
	if self.duration == self.startDuration then
		for _ = 1,self.amount do
			local card = self.card:copy()
			if self.putOnTop then
				table.insert(drawPile,card)
			else
				table.insert(drawPile,miscRand:randInt(#drawPile+1),card)
			end
			card:resetPowers()
			local cardItem = self.cardItem and self.cardItem:copy() or CardItem:new{card=card,x=0,y=136,isNotInHand=true}
			local additionalPause = self.pauseDuration or 0
			local effect = CardEffect:new{cardItem=cardItem,pauseDuration=30+additionalPause,duration=50+additionalPause,tx=0,ty=136}
			effect.useCardPosition = fillCardPosition(cardItem,self.cardPosition)
			addEffect(effect)
		end
	end
	Action.tick(self)
end

PlayTopCardAction = Action:new{duration=10,target=nil,exhaust=false,randomTarget=false}
function PlayTopCardAction:tick()
	if self.duration == self.startDuration then
		if #drawPile == 0 then
			if #discardPile > 0 then
				addAction(1,ShuffleAction:new())
				addAction(2,PlayTopCardAction:new{target=self.target,exhaust=self.exhaust,randomTarget=self.randomTarget})
			end
			self.isDone = true
			return
		end
		local card = table.remove(drawPile,#drawPile)
		local cardItem = CardItem:new{card=card}
		table.insert(limbo,cardItem)
		local useCardAction = UseCardAction:new{cardItem=cardItem,exhaust=self.exhaust,randomTarget=self.randomTarget,target=self.target,free=true}
		useCardAction.useCardPosition = fillCardPosition(cardItem)
		useCardAction.tx,useCardAction.ty = cardItem.tx,cardItem.ty
		addAction(1,useCardAction)
	end
	Action.tick(self)
end

ExhaustCardAction = Action:new{duration=30,cardItem=nil,show=false}
function ExhaustCardAction:new(o)
	table.insert(limbo,o.cardItem)
	return Action.new(self,o)
end

function ExhaustCardAction:tick()
	if self.duration == self.startDuration then
		local cardItem = self.cardItem
		local card = cardItem.card
		card:resetPowers()
		local limboIndex = table.indexOf(limbo,cardItem)
		if limboIndex then
			table.remove(limbo,limboIndex)
		end
		card.costForOneTurnPlay = nil
		table.insert(exhaustPile,card)
		player:triggerEvent('onExhaust',card)
		cardItem.large = false
		local effect = CardEffect:new{cardItem=cardItem,pauseDuration=30,duration=50,tx=120,ty=-32}
		if self.show then
			effect.useCardPosition = fillCardPosition(cardItem)
		else
			effect.pauseDuration = 1
			effect.duration = 20
			effect.startDuration = 20
		end
		effect.tx = cardItem.tx
		addEffect(effect)
	end
	Action.tick(self)
end

PutCardOnDrawCardTopAction = Action:new{duration=30,cardItem=nil,show=false}
function PutCardOnDrawCardTopAction:tick()
	if self.duration == self.startDuration then
		local cardItem = self.cardItem
		local card = cardItem.card
		table.insert(drawPile,card)
		card:resetPowers()
		cardItem.large = false
		local effect = CardEffect:new{cardItem=cardItem,pauseDuration=30,duration=50,tx=0,ty=136}
		if self.show then
			effect.useCardPosition = fillCardPosition(cardItem)
		else
			effect.pauseDuration = 1
			effect.duration = 20
			effect.startDuration = 20
		end
		addEffect(effect)
	end
	Action.tick(self)
end

FatalAction = Action:new{target=nil,action=nil,callback=nil}
function FatalAction:tick()
	local target = self.target
	if target:getPower(MinionPower) == nil and not target.alive and self.callback and self.action.numKilled > 0 then
		self.callback()
	end
	self.isDone = true
end

EffectAction = Action:new{effect=nil,duration=1}
function EffectAction:new(effect,duration)
	return Action.new(self,{effect=effect,duration=duration or 1})
end

function EffectAction:tick()
	if self.duration == self.startDuration then
		addEffect(self.effect)
	end
	Action.tick(self)
end

TalkAction = EffectAction:new(nil)
function TalkAction:new(creature,text,additional)
	local xOffset = additional and additional.xOffset or 4
	local yOffset = additional and additional.yOffset or 4
	local boxXOffset = additional and additional.boxXOffset or 4
	local boxYOffset = additional and additional.boxYOffset or 4
	local duration = additional and additional.duration or 60
	if creature == player then
		return EffectAction.new(self,AnonymousEffect:new{duration=duration,callback=function ()
			drawTalkBubble(text,creature.x+creature.width*8+5-boxXOffset,creature.y-25+boxYOffset,60,35,creature.x+creature.width*8-xOffset,creature.y+yOffset,12,15)
		end},10)
	else
		return EffectAction.new(self,AnonymousEffect:new{duration=duration,callback=function ()
			drawTalkBubble(text,creature.x-65+boxXOffset,creature.y-25+boxYOffset,60,35,creature.x+xOffset,creature.y+yOffset,12,15)
		end},10)
	end
end

RemoveDebuffsAction = Action:new{target=nil,duration=1}
function RemoveDebuffsAction:new(target)
	return Action.new(self,{target=target})
end

function RemoveDebuffsAction:tick()
	if self.duration == self.startDuration then
		local index = 1
		for _,power in ipairs(self.target.powers) do
			if power.debuff then
				addAction(index,RemovePowerAction:new(power))
				index = index + 1
			end
		end
	end
	Action.tick(self)
end

DiscoveryAction = Action:new{duration=1,amount=1,cost=nil,type=nil,rarity=nil,colorless=false,canClose=false,target='hand'}
function DiscoveryAction:tick()
	if self.duration == self.startDuration then
		local cards = {}
		for i = 1, 3 do
			local card
			repeat
				if self.colorless then
					card = getColorlessCardType(miscRand,self.rarity,self.type):new()
				else
					card = getPlayerCardType(miscRand,self.rarity,self.type):new()
				end
			until card.canGenerateInCombat and not table.anyMatch(cards,function (c) return getmetatable(c) == getmetatable(card) end)
			cards[i] = card
		end
		openWindowAbove(CardRewardWindow:new{cards=cards,canClose=self.canClose},function (cardItem)
			if not cardItem then
				return
			end
			if cardItem.card:getCost() >= 0 then
				cardItem.card.costForOneTurnPlay = self.cost
			end
			if self.target == 'hand' then
				addAction(1,MakeTempCardToHandAction:new(cardItem.card,self.amount,{cardItem=cardItem}))
			elseif self.target == 'drawPile' then
				addAction(1,MakeTempCardToDrawPileAction:new(cardItem.card,self.amount,{cardItem=cardItem,pauseDuration=-29}))
			elseif self.target == 'discardPile' then
				addAction(1,MakeTempCardToDiscardPileAction:new(cardItem.card,self.amount,{cardItem=cardItem,pauseDuration=-29}))
			end
		end)
	end
	Action.tick(self)
end

DiscardAction = Action:new{duration=30,cardItem=nil,fromHand=true,show=false}
function DiscardAction:new(o)
	table.insert(limbo,o.cardItem)
	return Action.new(self,o)
end

function DiscardAction:tick()
	if self.duration == self.startDuration then
		local cardItem = self.cardItem
		local card = cardItem.card
		card:resetPowers()
		local limboIndex = table.indexOf(limbo,cardItem)
		if limboIndex then
			table.remove(limbo,limboIndex)
		end
		card.costForOneTurnPlay = nil
		table.insert(discardPile,card)
		if self.fromHand then
			player:triggerEvent('onDiscardFromHand',card)
		end
		cardItem.large = false
		local effect = CardEffect:new{cardItem=cardItem,pauseDuration=30,duration=50,tx=240,ty=136}
		if self.show then
			effect.useCardPosition = fillCardPosition(cardItem)
		else
			effect.pauseDuration = 1
			effect.duration = 20
			effect.startDuration = 20
		end
		addEffect(effect)
	end
	Action.tick(self)
end

PutCardInDrawPileAction = Action:new{duration=30,position=nil,cardItem=nil,show=false}
function PutCardInDrawPileAction:new(o)
	table.insert(limbo,o.cardItem)
	return Action.new(self,o)
end

function PutCardInDrawPileAction:tick()
	if self.duration == self.startDuration then
		local cardItem = self.cardItem
		local card = cardItem.card
		card:resetPowers()
		local limboIndex = table.indexOf(limbo,cardItem)
		if limboIndex then
			table.remove(limbo,limboIndex)
		end
		card.costForOneTurnPlay = nil
		table.insert(drawPile,self.position or (#drawPile+1),card)
		cardItem.large = false
		local effect = CardEffect:new{cardItem=cardItem,pauseDuration=30,duration=50,tx=0,ty=136}
		if self.show then
			effect.useCardPosition = fillCardPosition(cardItem)
		else
			effect.pauseDuration = 1
			effect.duration = 20
			effect.startDuration = 20
		end
		addEffect(effect)
	end
	Action.tick(self)
end

PlayerEscapeAction = Action:new{duration=30}
function PlayerEscapeAction:tick()
	if self.duration == self.startDuration then
		local target = player:copy()
		player.visible = false
		target.flipped = not target.flipped
		addEffect(CreatureEffect:new{target=target,x=target.x,y=target.y,xSpeed=target.flipped and -1 or 1})
	end
	Action.tick(self)
end

SelectDiscardHandAction = Action:new{duration=1}
function SelectDiscardHandAction:new(amount)
	return Action.new(self,{amount=amount})
end

function SelectDiscardHandAction:tick()
	if self.duration == self.startDuration then
		if #hand <= self.amount then
			for i=#hand,1,-1 do
				local cardItem = hand[i]
				removeHand(i)
				addAction(1,DiscardAction:new{cardItem=cardItem,duration=1})
			end
		else
			local title = self.amount == 1 and 'Choose a Card to Discard' or 'Choose Cards to Discard ({#}/'..self.amount..')'
			openWindowAbove(HandSelectWindow:new{cardItems=hand,title=title,min=self.amount,max=self.amount},function (cards)
				for i,cardItem in ipairs(cards) do
					local cardIndex = table.indexOf(hand,cardItem)
					removeHand(cardIndex)
					addAction(i,DiscardAction:new{cardItem=cardItem,duration=1})
				end
			end)
		end
	end
	Action.tick(self)
end

ChannelAction = Action:new{duration=10,orb=nil}
function ChannelAction:new(orb)
	return Action.new(self,{orb=orb})
end

function ChannelAction:tick()
	if self.duration == self.startDuration then
		if #player.orbs == 0 then
			self.isDone = true
			return
		end
		local channeled = false
		for i = 1, #player.orbs do
			local target = player.orbs[i]
			if getmetatable(target) == OrbSlot then
				player.orbs[i] = self.orb
				self.orb.x = target.x
				self.orb.y = target.y
				self.orb:applyPowers()
				channeled = true
				break
			end
		end
		if not channeled then
			addAction(1,EvokeAction:new())
			addAction(2,ChannelAction:new(self.orb))
			self.isDone = true
			return
		else
			player:triggerEvent('onChannel',self.orb)
			handApplyPowers()
		end
	end
	Action.tick(self)
end

EvokeAction = Action:new{duration=10,amount=1}
function EvokeAction:tick()
	if self.duration == self.startDuration then
		if #player.orbs == 0 then
			self.isDone = true
			return
		end
		local orb = player.orbs[1]
		if getmetatable(orb) == OrbSlot then
			self.isDone = true
			return
		end
		local allActions = { AnonymousAction:new(function () orb.evoking = true end) }
		orb:applyPowers()
		for _ = 1, self.amount do
			local actions = orb:onEvoke() or {}
			for _,action in ipairs(actions) do
				table.insert(allActions,action)
			end
		end
		table.insert(allActions,AnonymousAction:new(function ()
			table.remove(player.orbs,1)
			table.insert(player.orbs,OrbSlot:new{owner=player})
			handApplyPowers()
		end))
		for i,action in ipairs(allActions) do
			addAction(i,action)
		end
	end
	Action.tick(self)
end

AddOrbSlotAction = Action:new{duration=10,amount=1}
function AddOrbSlotAction:new(amount)
	return Action.new(self,{amount=amount})
end

function AddOrbSlotAction:tick()
	if self.duration == self.startDuration then
		for _=1,self.amount do
			if #player.orbs < 10 then
				table.insert(player.orbs,OrbSlot:new{owner=player})
			end
		end
	end
	Action.tick(self)
end

