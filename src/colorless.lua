-- colorless
---@diagnostic disable: lowercase-global

local colorlessCards
local curseCards

function getColorlessCards()
	return colorlessCards
end

function getCurseCards()
	return curseCards
end

ColorlessCard = Card:new{color={14,15},costIcon=46,typeIconColor=13,colorName='colorless'}

Wound = ColorlessCard:new{ name='Wound',description='Unplayable.',rarity='special',baseCost=-2,type='status',baseCanUse=false,canUpgrade=false,playerTarget=true }

Dazed = ColorlessCard:new{ name='Dazed',description='Unplayable. NL Ethereal.',rarity='special',baseCost=-2,type='status',baseCanUse=false,canUpgrade=false,ethereal=true,playerTarget=true }

Slimed = ColorlessCard:new{ name='Slimed',description='Exhaust.',rarity='special',baseCost=1,type='status',canUpgrade=false,exhaust=true,playerTarget=true }

Burn = ColorlessCard:new{
	name='Burn',description='Unplayable. NL At the end of turn, {63} !M! to you.',rarity='special',baseCost=-2,type='status',
	baseCanUse=false,canUpgrade=false,baseMagic=2,upgrade={baseMagic=4},autoPlayOnEndTurn=true,playerTarget=true
}
function Burn:use()
	return { DamageAction:new{source=player,target=player,value=self.magic,type='power'} }
end

BandageUp = ColorlessCard:new{
	name='Bandage Up',description='Heal !M! HP. NL Exhaust.',baseCost=0,type='skill',rarity='uncommon',
	playerTarget=true,baseMagic=4,upgrade={baseMagic=6},exhaust=true,canGenerateInCombat=false
}
function BandageUp:use()
	return { HealAction:new{target=player,value=self.magic} }
end

Blind = ColorlessCard:new{
	name='Blind',description='Apply !M! {61}.',baseCost=0,type='skill',rarity='uncommon',
	enemyTarget=true,baseMagic=2,upgrade={description='Apply !M! {61} to all enemies.',toAllEnemies=true}
}
function Blind:use(target)
	if self.toAllEnemies then
		local result = {}
		for _, enemy in ipairs(enemies) do
			table.insert(result,ApplyPowerAction:new(WeakPower:new(enemy,self.magic)))
		end
		return result
	else
		return { ApplyPowerAction:new(WeakPower:new(target,self.magic)) }
	end
end

Finesse = ColorlessCard:new{
	name='Finesse',description='Gain !B! {47}. NL Draw a card.',baseCost=0,type='skill',rarity='uncommon',
	playerTarget=true,baseBlock=2,upgrade={baseBlock=4}
}
function Finesse:use()
	return { GainBlockAction:new{target=player,value=self.block}, DrawCardAction:new(1) }
end

MasterOfStrategy = ColorlessCard:new{
	name='Master of Strategy',description='Draw !M! cards. NL Exhaust.',baseCost=0,type='skill',rarity='rare',
	playerTarget=true,baseMagic=3,upgrade={baseMagic=4},exhaust=true
}
function MasterOfStrategy:use()
	return { DrawCardAction:new(self.magic) }
end

HandOfGreed = ColorlessCard:new{
	name='Hand of Greed',description='{63} !D!. NL If fatal, gain !M! {7}.',baseCost=2,rarity='rare',
	enemyTarget=true,baseMagic=20,baseDamage=20,upgrade={baseMagic=25,baseDamage=25}
}
function HandOfGreed:use(target)
	local damageAction = DamageAction:new{source=player,target=target,value=self.damage}
	return {
		damageAction,
		FatalAction:new{target=target,action=damageAction,callback=function ()
			gold = gold + self.magic
		end}
	}
end

ThinkingAhead = ColorlessCard:new{
	name='Thinking Ahead',description='Draw !M! cards. NL Put a card from hand on the top of draw pile. NL Exhaust.',baseCost=0,type='skill',rarity='rare',
	playerTarget=true,baseMagic=2,upgrade={exhaust=false,description='Draw !M! cards. NL Put a card from hand on the top of draw pile.'},exhaust=true
}
function ThinkingAhead:use()
	return {
		DrawCardAction:new(self.magic),
		AnonymousAction:new(function ()
			if #hand == 0 then
				return
			elseif #hand == 1 then
				addAction(1,PutCardOnDrawCardTopAction:new{cardItem=hand[1],show=true})
				removeHand(1)
			else
				openWindowAbove(HandSelectWindow:new{cardItems=hand,title='Choose a Card to Put on Top of Draw Pile',max=1},function (cards)
					for _, cardItem in ipairs(cards) do
						local cardIndex = table.indexOf(hand,cardItem)
						addAction(1,PutCardOnDrawCardTopAction:new{cardItem=cardItem})
						removeHand(cardIndex)
					end
				end)
			end
		end)
	}
end

colorlessCards = {
	Wound,Dazed,Burn,Slimed,BandageUp,Blind,Finesse,MasterOfStrategy,HandOfGreed,ThinkingAhead
}

CurseCard = Card:new{color={15,0},costIcon=46,typeIconColor=13,colorName='curse',type='curse',rarity='common',baseCost=-2,baseCanUse=false,canUpgrade=false,playerTarget=true}

AscendersBane = CurseCard:new{
	name='Ascender\'s Bane',description='Unplayable. NL Ethereal. NL Cannot be removed from deck.',
	rarity='special',ethereal=true,canRemove=false
}
Injury = CurseCard:new{ name='Injury',description='Unplayable.' }
Clumsy = CurseCard:new{ name='Clumsy',description='Unplayable. NL Ethereal.',ethereal=true }
Writhe = CurseCard:new{ name='Writhe',description='Unplayable. NL Innate.',innate=true }
Regret = CurseCard:new{ name='Regret',description='Unplayable. NL At the end of turn, lose HP equal to the number of cards in hand.',autoPlayOnEndTurn=true }
function Regret:use()
	return { DamageAction:new{source=player,target=player,value=#hand+1,type='hpLoss'} }
end

Decay = CurseCard:new{ name='Decay',description='Unplayable. NL At the end of turn, {63} 2 to you.',autoPlayOnEndTurn=true }
function Decay:use()
	return { DamageAction:new{source=player,target=player,value=2,type='power'} }
end

Doubt = CurseCard:new{ name='Doubt',description='Unplayable. NL At the end of your turn, gain 1 {61}.',autoPlayOnEndTurn=true }
function Doubt:use()
	return { ApplyPowerAction:new(WeakPower:new(player,1,true)) }
end

Parasite = CurseCard:new{ name='Parasite',description='Unplayable. NL If transformed or removed from deck, lose 3 Max HP.' }
function Parasite:onRemoveFromDeck()
	player:decreaseMaxHp(3)
end

curseCards = {
	AscendersBane,Injury,Clumsy,Writhe,Regret,Decay,Doubt
}
