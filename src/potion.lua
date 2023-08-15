-- potion
---@diagnostic disable: lowercase-global

local allPotions
function getAllPotions()
	return allPotions
end

function getTrueRandomPotionType(random)
	return allPotions[random:randInt(#allPotions)]
end

function getRandomPotionType(random,noFruit)
	local roll = random:randInt(0,99)
	local rarity
	if roll < 65 then
		rarity = 'common'
	elseif roll < 90 then
		rarity = 'uncommon'
	else
		rarity = 'rare'
	end
	local allPotions = shallowcopy(getAllPotions())
	table.retainIf(allPotions,function (p) return p.rarity == rarity and (not noFruit or p == FruitJuice) end)
	return allPotions[random:randInt(#allPotions)]
end

function obtainPotion(potion)
	for i,v in ipairs(potions) do
		if v == Slot then
			potions[i] = potion
			return true
		end
	end
	return false
end

Potion = Object:new{name='',description='',icon=0,color={},canUseOutsideCombat=false,baseMagic=0,magic=0,enemyTarget=false,rarity='common',useTitle='Drink',use=noop}
function Potion:applyPowers()
	self.magic = self.baseMagic
end

function Potion:drawImage(x,y)
	for i,v in ipairs(self.color) do
		mapColor(i,v)
	end
	spr(self.icon,x,y,0)
	resetColors({1,2,3,4})
end

function Potion:canUse()
	return self.canUseOutsideCombat or (roomActionType == 'combat' and getmetatable(nearestWindow) == GameWindow and not inEnemyTurn)
end

function Potion:realCanUse()
	return self:canUse() and (self.canUseOutsideCombat or not table.allMatch(enemies,function (e) return not e.alive end))
end

Slot = Potion:new{icon=41}
function Slot:canUse()
	return false
end

FirePotion = Potion:new{
	name='Fire Potion',description='{63} !M!.',icon=100,color={1,2,4},baseMagic=20,enemyTarget=true,useTitle='Throw',rarity='common'
}
function FirePotion:use(target)
	return { DamageAction:new{target=target,source=player,value=self.magic,type='power'} }
end

LiquidMemories = Potion:new{
	name='Liquid Memories',description='Choose !M! card(s) in discard pile and return it to hand. It cost 0 this turn',
	icon=107,color={10,9},baseMagic=1,rarity='uncommon'
}
function LiquidMemories:use()
	local amount = self.magic
	return {
		AnonymousAction:new(function ()
			local cardItems = {}
			for i, card in ipairs(discardPile) do
				cardItems[i] = CardItem:new{card=card,x=240,y=136,tx=240,ty=136,isNotInHand=true}
			end
			if #cardItems == 0 then
				return
			elseif #cardItems <= amount then
				for _, cardItem in ipairs(cardItems) do
					table.remove(discardPile,table.indexOf(discardPile,cardItem.card))
					table.insert(hand,cardItem)
					cardItem.isNotInHand = false
					cardItem.card.costForOneTurnPlay = 0
					cardItem.card:applyPowers()
				end
			else
				openWindowAbove(CardGridSelectWindow:new{cardItems=cardItems,title='Choose a Card to Return to Hand',max=amount,min=amount},
					function (cards)
						for _, cardItem in ipairs(cards) do
							table.remove(discardPile,table.indexOf(discardPile,cardItem.card))
							table.insert(hand,cardItem)
							cardItem.isNotInHand = false
							cardItem.card.costForOneTurnPlay = 0
							cardItem.card:applyPowers()
						end
					end)
			end
		end)
	}
end

FruitJuice = Potion:new{
	name='Fruit Juice',description='Gain !M! max HP.',icon=106,color={5,5,4,4},baseMagic=5,canUseOutsideCombat=true,rarity='rare'
}
function FruitJuice:use()
	player:increaseMaxHp(self.magic)
end

allPotions = {
	FirePotion,LiquidMemories,FruitJuice
}
