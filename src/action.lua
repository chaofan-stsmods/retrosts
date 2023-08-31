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

DrawCardAction = Action:new()
function DrawCardAction:new(numCards)
	return Action.new(self,{numCards=numCards,duration=3})
end

function DrawCardAction:tick()
	if self.numCards <= 0 or player:getPower(NoDrawPower) or (#discardPile == 0 and #drawPile == 0) then
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
		if #hand >= HAND_LIMIT or #drawPile == 0 then
			self.isDone = true
			return
		end
		local card = table.remove(drawPile,#drawPile)
		table.insert(hand,CardItem:new{card=card})
		card:applyPowers()
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
	cardItem=nil,target=nil,secondary=false,exhaust=false,randomTarget=false,free=false,forceUse=false,energyOnUse=nil,
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
			local target = getRandomAliveEnemy()
			if target then
				self.target = target
			end
		end
		card:applyPowers(self.target)
		if not self.forceUse and (not card:canUse(self.free) or (self.target ~= nil and not self.target.alive)) then
			if self.fromHand and handIndex then
				self.cardItem.isNotInHand = false
				self.isDone = true
			else
				addAction(1,self:makeUseCardEndAction())
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
		addAction(#cardActions+1,self:makeUseCardEndAction())
		local cost = card:getCost()
		if cost > 0 and not self.free then
			energy = energy - cost
		end
	end
	Action.tick(self)
end

function UseCardAction:makeUseCardEndAction()
	return UseCardEndAction:new{
		cardItem=self.cardItem,exhaust=self.exhaust,
		useCardPosition=self.useCardPosition,tempCard=self.tempCard,
	}
end

UseCardEndAction = Action:new{cardItem=nil,exhaust=false,tempCard=false,duration=20}
function UseCardEndAction:tick()
	local card = self.cardItem.card
	local exhaust = card.exhaust or self.exhaust
	if card.type == 'power' then
		self.cardItem.tx = player.x+player.width*4
		self.cardItem.ty = player.y+player.height*4
	elseif exhaust or self.tempCard then
		--self.cardItem.tx = 120
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
		card.costForOneTurnPlay = nil
		card.costForOnePlay = nil
		card:resetPowers()
		if card.type ~= 'power' and not self.tempCard then
			if exhaust then
				table.insert(exhaustPile,self.cardItem.card)
				player:triggerEvent('onExhaust',card)
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
		if not potion:canUse() or not potionIndex or (self.target ~= nil and not self.target.alive) then
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

DamageAction = Action:new{source=nil,target=nil,value=nil,type=nil,duration=10}
function DamageAction:tick()
	if not self.source.alive then
		self.isDone = true
		return
	end
	if self.duration == self.startDuration then
		self.target:damage(self.source,self.value,self.type,self)
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

DamageRandomEnemyAction = Action:new{source=nil,value=nil,type=nil,duration=10}
function DamageRandomEnemyAction:tick()
	if not self.source.alive then
		self.isDone = true
		return
	end
	if self.duration == self.startDuration then
		local target,index = getRandomAliveEnemy()
		if target then
			if type(self.value) == 'number' then
				target:damage(self.source,self.value,self.type,self)
			else
				target:damage(self.source,self.value[index],self.type,self)
			end
		end
	end
	Action.tick(self)
end

GainBlockAction = Action:new{target=nil,value=nil,duration=10}
function GainBlockAction:tick()
	if self.duration == self.startDuration and self.target.alive then
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

EndTurnAction = Action:new{duration=10}
function EndTurnAction:tick()
	if self.duration == self.startDuration then
		for i = #secondaryActions,1,-1 do
			table.remove(secondaryActions,i)
		end
		addAction(AutoPlayOnEndTurnAction:new())
		addAction(ExhaustEtherealCardsAction:new())
		addAction(DiscardAllCardsAction:new())
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

ExhaustEtherealCardsAction = Action:new{secondary=true}
function ExhaustEtherealCardsAction:tick()
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
	self.isDone = true
end

DiscardAllCardsAction = Action:new{duration=20,secondary=true}
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
			cardItem.card:resetPowers()
			cardItem.card.costForOneTurnPlay = nil
		end
	end
	if #hand == 0 then
		self.isDone = true
	end
end

NewTurnAction = Action:new{duration=10,secondary=true,additionalCard=0}
function NewTurnAction:tick()
	if self.duration == self.startDuration then
		player:onTurnStart(turn + 1)
		addAction(DrawCardAction:new(5+self.additionalCard))
		player:triggerEvent('onTurnStartPostDraw', turn + 1)
		if turn ~= 0 then
			energy = player:triggerReducerEvent('onTurnStartResetEnergy',maxEnergy,energy)
		end
	end
	Action.tick(self)
	if self.isDone then
		inEnemyTurn = false
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

ApplyPowerAction = Action:new{duration=10}
function ApplyPowerAction:new(power)
	return Action.new(self,{power=power})
end

function ApplyPowerAction:tick()
	if self.duration == self.startDuration then
		local power = self.power
		local owner = power.owner
		if not owner:triggerConditionEvent('onBeforeApplyPower',true,power) then
			Action.tick(self)
			return
		end

		local existingPower = owner:getPower(getmetatable(power))
		if existingPower then
			existingPower:setAmount(existingPower.amount + power.amount)
			if existingPower.amount == 0 then
				owner:removePower(existingPower)
			end
		else
			owner:addPower(power)
		end
		owner:applyPowers()
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
			local actions = self.callback(self.energyOnUse or energy) or {}
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
function MakeTempCardToDiscardPileAction:new(card,amount)
	amount = amount or 1
	return Action.new(self,{card=card,amount=amount})
end

function MakeTempCardToDiscardPileAction:tick()
	if self.duration == self.startDuration then
		for _ = 1,self.amount do
			local card = self.card:copy()
			table.insert(discardPile,card)
			card:resetPowers()
			local cardItem = CardItem:new{card=card,x=0,y=136,isNotInHand=true}
			local effect = CardEffect:new{cardItem=cardItem,pauseDuration=30,duration=50,tx=240,ty=136}
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
			cardItem.isNotInHand = false
			card:applyPowers()
			table.insert(hand,cardItem)
		end
	end
	Action.tick(self)
end

MakeTempCardToDrawPileAction = Action:new{duration=10}
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
			table.insert(drawPile,miscRand:randInt(#drawPile+1),card)
			card:resetPowers()
			local cardItem = CardItem:new{card=card,x=0,y=136,isNotInHand=true}
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

DiscoveryAction = Action:new{duration=1,amount=1,cost=nil,type=nil,rarity=nil,colorless=false}
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
		openWindowAbove(CardRewardWindow:new{cards=cards,canClose=false},function (cardItem)
			cardItem.card.costForOneTurnPlay = self.cost
			addAction(1,MakeTempCardToHandAction:new(cardItem.card,self.amount,{cardItem=cardItem}))
		end)
	end
	Action.tick(self)
end

DiscardAction = Action:new{duration=30,cardItem=nil,show=false}
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

PlayerEscapeAction = Action:new{duration=30}
function PlayerEscapeAction:tick()
	if self.duration == self.startDuration then
		local target = player:copy()
		player.visible = false
		target.flipped = true
		addEffect(CreatureEffect:new{target=target,x=target.x,y=target.y,xSpeed=-1})
	end
	Action.tick(self)
end
