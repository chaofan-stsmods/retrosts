---@diagnostic disable: lowercase-global

Player = Creature:new{
    x=30,y=52,
    getStartDeck=function() return {} end
}
function Player:applyPowers()
	for _, cardItem in ipairs(hand) do
		cardItem.card:applyPowers()
	end
	for _, enemy in ipairs(enemies) do
		enemy:applyPowers()
	end
end
