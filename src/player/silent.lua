---@diagnostic disable: lowercase-global

local greenCards

TheSilent = Player:new{ maxHp=70,width=6,height=4,tileBank=2,name='The Silent',energyYOffset=1 }
function TheSilent:drawImage()
	if self.flipped then
		map(7,9,5,4,self.x+8,self.y,0,1,flipRemap(7,5))
		pix(self.x+33,self.y+12,11)
		pix(self.x+32,self.y+13,11)
	else
		map(7,9,5,4,self.x,self.y,0)
		pix(self.x+14,self.y+12,11)
		pix(self.x+15,self.y+13,11)
	end
end

function TheSilent:drawCorpse()
	map(0,13,7,3,self.x-4,self.y+20,0)
end

function TheSilent:getStartDeck()
	local deck = {}
	table.insert(deck,StrikeGreen:new())
	table.insert(deck,StrikeGreen:new())
	table.insert(deck,StrikeGreen:new())
	table.insert(deck,StrikeGreen:new())
	table.insert(deck,StrikeGreen:new())
	table.insert(deck,DefendGreen:new())
	table.insert(deck,DefendGreen:new())
	table.insert(deck,DefendGreen:new())
	table.insert(deck,DefendGreen:new())
	table.insert(deck,DefendGreen:new())
	table.insert(deck,Survivor:new())
	table.insert(deck,Neutralize:new())
	return deck
end

function TheSilent:getCards()
	return greenCards
end

function TheSilent:getStartRelics()
	return { RingOfTheSnake:new() }
end

function TheSilent:getAscensionMaxHPLoss()
	return 4
end

function TheSilent:getMatchAndKeepCardType()
	return Neutralize
end

function TheSilent:getRelics()
	return { RingOfTheSnake }
end

function TheSilent:getPotions()
	return { }
end

function TheSilent:getSpireHeartText()
	return 'NL You prepare your daggers...'
end

-- cards

GreenCard = Card:new{color={7,15},costIcon=201,typeIconColor=5,colorName='green'}

StrikeGreen = GreenCard:new{ name='Strike',description='{Damage} !D!.',rarity='basic',baseCost=1,baseDamage=6,enemyTarget=true,upgrade={baseDamage=9},tags={'strike','basicStrike'} }
function StrikeGreen:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

DefendGreen = GreenCard:new{ name='Defend',description='Gain !B! {Block}.',rarity='basic',type='skill',baseCost=1,baseBlock=5,playerTarget=true,upgrade={baseBlock=8},tags={'basicDefend'} }
function DefendGreen:use()
	return { GainBlockAction:new{target=player,value=self.block} }
end

Neutralize = GreenCard:new{
	name='Neutralize',description='{Damage} !D!. NL Apply !M! {Weak}.',rarity='basic',baseCost=0,baseDamage=3,baseMagic=1,
	enemyTarget=true,upgrade={baseDamage=4,baseMagic=2},
}
function Neutralize:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage}, ApplyPowerAction:new(player,WeakPower:new(target,self.magic)) }
end

Survivor = GreenCard:new{
	name='Survivor',description='Gain !B! {Block}. NL Discard 1 card.',rarity='basic',type='skill',baseCost=1,baseBlock=8,
	playerTarget=true,upgrade={baseBlock=11},
}
function Survivor:use()
	return {
		GainBlockAction:new{target=player,value=self.block},
		AnonymousAction:new(function ()
			if #hand == 0 then
				return
			else
				openWindowAbove(HandSelectWindow:new{cardItems=hand,title='Choose a Card to Discard',max=1},function (cards)
					for i,cardItem in ipairs(cards) do
						local cardIndex = table.indexOf(hand,cardItem)
						removeHand(cardIndex)
						addAction(i,DiscardAction:new{cardItem=cardItem,duration=1})
					end
				end)
			end
		end),
	}
end

greenCards = {
	StrikeGreen,DefendGreen,Neutralize,Survivor,
}

-- relics

GreenRelic = Relic:new{colorName='green'}

RingOfTheSnake = GreenRelic:new{name='Ring of the Snake',icon=243,tier='basic',description='At the start of each combat, draw #11#2#12# additional cards.'}
function RingOfTheSnake:onTurnStartPostDraw(turn)
	if turn == 1 then
		addAction(DrawCardAction:new(2))
	end
end
