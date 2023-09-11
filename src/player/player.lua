-- player
---@diagnostic disable: lowercase-global

---@class Player : Creature
Player = {
	x=30,y=52,tileBank=1,name=nil,drawCorpse=noop,energyYOffset=0,maxOrbs=0,orbs=nil,
}
Creature:new(Player)

function Player:new(o)
	o = o or {}
	o.orbs = {}
	return Creature.new(self,o)
end

function Player:applyPowers()
	handApplyPowers()
	for _, orb in ipairs(self.orbs) do
		orb:applyPowers()
	end
	for _, enemy in ipairs(enemies) do
		enemy:applyPowers()
	end
end

function Player:drawAdditionalItems()
	local orbCount = #self.orbs
	for i=1,orbCount do
		if orbCount == 1 then
			self.orbs[i].tx = self.x+self.width*4
			self.orbs[i].ty = self.y-6
		else
			local r = orbCount*4+18
			local rad = (i-0.5)/orbCount*math.pi
			self.orbs[i].tx = self.x+self.width*4+r*math.cos(rad)
			self.orbs[i].ty = self.y+self.height*4-r*math.sin(rad)
		end
		self.orbs[i]:tick()
	end
end

function Player:getAscensionMaxHPLoss()
	return 0
end

function Player:onCombatStart()
	self.visible = true
	for i=1,self.maxOrbs do
		if self.orbs[i] == nil then
			self.orbs[i] = OrbSlot:new{owner=self}
		end
	end
	self:triggerEvent('onCombatStart')
	Creature.onCombatStart(self)
end

function Player:triggerEvent(name,...)
	for _, item in ipairs(sortByPriority(potions,relics,self.powers,table.map(hand,function(cardItem) return cardItem.card end))) do
		if item[name] then
			item[name](item,...)
		end
	end
	for _, orb in ipairs(self.orbs) do
		if orb[name] then
			orb[name](orb,...)
		end
	end
	for _, card in ipairs(drawPile) do
		card:triggerEvent(name,...)
	end
	for _, card in ipairs(discardPile) do
		card:triggerEvent(name,...)
	end
	for _, card in ipairs(exhaustPile) do
		card:triggerEvent(name,...)
	end
end

function Player:triggerConditionEvent(name,default,...)
	for _, item in ipairs(sortByPriority(potions,relics,self.powers,table.map(hand,function(cardItem) return cardItem.card end))) do
		if item[name] then
			local b = item[name](item,...)
			if b ~= nil then
				return b
			end
		end
	end
	return default
end

function Player:triggerReducerEvent(name,value,...)
	for _, item in ipairs(sortByPriority(potions,relics,self.powers,table.map(hand,function(cardItem) return cardItem.card end))) do
		if item[name] then
			value = item[name](item,value,...) or value
		end
	end
	return value
end

function Player:onTurnStart(turn)
	if turn == 1 then
		-- to avoid lose block at combat start
		self:triggerEvent('onTurnStart',turn)
	else
		Creature.onTurnStart(self,turn)
	end
end

function Player:onCombatEnd()
	self:triggerEvent('onCombatEnd')
	self.block = 0
	self.powers = {}
	self.orbs = {}
end

function Player:die()
	if not self:triggerConditionEvent('onBeforeDeath',true) and self.hp > 0 then
		return
	end
	clearSavedGame()
	switchWindow(LoseWindow:new())
	Creature.die(self)
end

function Player:getStartDeck()
	return {}
end

function Player:getStartRelics()
	return {}
end

function Player:getCards()
	return {}
end

function Player:getRelics()
	return {}
end

function Player:getPotions()
	return {}
end

function Player:getMatchAndKeepCardType()
	return Blind
end

function Player:talk(str,duration)
	addAction(TalkAction:new(self,str,{duration=duration}))
end

function Player:getPronouns()
	return {vampires='brother'}
end

function Player:resetPosition()
	self.x = 30
	self.y = 52
	self.flipped = false
	self.visible = true
end

function Player:getSpireHeartText()
	return 'NL You meet Spire Heart.'
end

function Player:getEnding()
	return IroncladEnding:new()
end

function sortByPriority(...)
	local result = {}
	local args = {...}
	local i = 0
	for _, arg in ipairs(args) do
		for _, item in ipairs(arg) do
			item.sortByPriorityIndex = i
			table.insert(result,item)
			i = i + 1
		end
	end
	table.sort(result,function (a, b)
		if a.priority == b.priority then
			return a.sortByPriorityIndex < b.sortByPriorityIndex
		end
		return a.priority < b.priority
	end)
	for _, item in ipairs(result) do
		item.sortByPriorityIndex = nil
	end
	return result
end

function gainGold(amount)
	gold = gold + player:triggerReducerEvent('onGainGold',amount)
end

function loseGold(amount)
	player:triggerEvent('onLoseGold',amount)
	gold = math.max(0,gold-amount)
end
