-- player
---@diagnostic disable: lowercase-global

Player = Creature:new{
	x=30,y=52,
	getStartDeck=function() return {} end
}
function Player:applyPowers()
	handApplyPowers()
	for _, enemy in ipairs(enemies) do
		enemy:applyPowers()
	end
end

function Player:triggerEvent(name,...)
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
	self.block = 0
	self.powers = {}
end

function Player:die()
	switchWindow(LoseWindow:new())
	Creature.die(self)
end
