-- player
---@diagnostic disable: lowercase-global

Player = Creature:new{
	x=30,y=52,
}
function Player:applyPowers()
	handApplyPowers()
	for _, enemy in ipairs(enemies) do
		enemy:applyPowers()
	end
end

function Player:onCombatStart()
	self:triggerEvent('onCombatStart')
	Creature.onCombatStart(self)
end

function Player:triggerEvent(name,...)
	for _, relic in ipairs(relics) do
		if relic[name] then
			relic[name](relic,...)
		end
	end
	Creature.triggerEvent(self,name,...)
	for _, hand in ipairs(hand) do
		hand.card:triggerEvent(name,...)
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

function Player:onCombatEnd()
	self:triggerEvent('onCombatEnd')
	self.block = 0
	self.powers = {}
end

function Player:die()
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
