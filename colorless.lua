-- colorless
---@diagnostic disable: lowercase-global

local colorlessCards

ColorlessCard = Card:new{color={14,15},costIcon=46,typeIconColor=13,colorName='colorless'}

Wound = ColorlessCard:new{ name='Wound',description='Unplayable.',rarity='special',baseCost=-2,type='status',canUse=false,canUpgrade=false }

Dazed = ColorlessCard:new{ name='Dazed',description='Unplayable. NL Ethereal.',rarity='special',baseCost=-2,type='status',canUse=false,canUpgrade=false,ethereal=true }

Burn = ColorlessCard:new{
	name='Burn',description='Unplayable. NL At the end of turn, {63} !M! to you.',rarity='special',baseCost=-2,type='status',
	canUse=false,canUpgrade=false,baseMagic=2,upgrade={baseMagic=4},autoPlayOnEndTurn=true
}
function Burn:use()
	return { DamageAction:new{source=player,target=player,value=self.magic} }
end

colorlessCards = {
	Wound,Dazed,Burn
}

function getColorlessCards()
	return colorlessCards
end
