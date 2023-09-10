---@diagnostic disable: lowercase-global

local blueCards

Defect = Player:new{ maxHp=75,width=6,height=4,tileBank=3,name='Defect',maxOrbs=3 }
function Defect:drawImage()
	if self.flipped then
		map(14,9,4,4,self.x+8,self.y,0,1,flipRemap(14,4))
	else
		map(14,9,4,4,self.x+8,self.y,0)
	end
end

function Defect:drawCorpse()
	map(7,13,7,2,self.x-4,self.y+20,0)
end

function Defect:getStartDeck()
	local deck = {}
	table.insert(deck,StrikeBlue:new())
	table.insert(deck,StrikeBlue:new())
	table.insert(deck,StrikeBlue:new())
	table.insert(deck,StrikeBlue:new())
	table.insert(deck,DefendBlue:new())
	table.insert(deck,DefendBlue:new())
	table.insert(deck,DefendBlue:new())
	table.insert(deck,DefendBlue:new())
	table.insert(deck,Zap:new())
	table.insert(deck,Dualcast:new())
	return deck
end

function Defect:getCards()
	return blueCards
end

function Defect:getStartRelics()
	return { CrackedCore:new() }
end

function Defect:getAscensionMaxHPLoss()
	return 4
end

function Defect:getMatchAndKeepCardType()
	return Neutralize
end

function Defect:getRelics()
	return {
		CrackedCore,
	}
end

function Defect:getPotions()
	return {  }
end

function Defect:getPronouns()
	return {vampires='broken one'}
end

function Defect:getSpireHeartText()
	return 'NL You charge your core to its maximum...'
end

-- orbs

Orb = Object:new{owner=nil,x=0,y=0,tx=0,ty=0,icon=nil,evoking=false,applyPowers=noop,drawNumbers=noop,onEvoke=noop}
function Orb:new(o)
	local r = Object.new(self,o)
	if r.owner ~= nil then
		r.x = r.owner.x + r.owner.width*4
		r.y = r.owner.y + r.owner.height*4
	end
	return r
end

function Orb:tick()
	drawIcon(self.icon,self.x-4,self.y-4)
	self:drawNumbers()
	self.x = lerp(self.x,self.tx,0.2)
	self.y = lerp(self.y,self.ty,0.2)
end

OrbSlot = Orb:new{icon=icons.OrbSlot}

Lightning = Orb:new{icon=icons.Lightning,value=3,evokeValue=8}
function Lightning:drawNumbers()
	local text = self.evoking and tostring(self.evokeValue) or tostring(self.value)
	printGlowed(text,self.x+4-strWidth(text,false,true)/2,self.y,self.evoking and 10 or 12,15,1,true)
end

function Lightning:onEvoke()
	return { DamageRandomEnemyAction:new{source=self.owner,value=self.evokeValue,type='power'} }
end

function Lightning:onTurnEnd()
	addAction(DamageRandomEnemyAction:new{source=self.owner,value=self.value,type='power'})
end

-- cards

BlueCard = Card:new{color={9,15},typeIconColor=11,colorName='blue'}

StrikeBlue = BlueCard:new{ name='Strike',description='{Damage} !D!.',rarity='basic',baseCost=1,baseDamage=6,enemyTarget=true,upgrade={baseDamage=9},tags={'strike','basicStrike'} }
function StrikeBlue:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

DefendBlue = BlueCard:new{ name='Defend',description='Gain !B! {Block}.',rarity='basic',type='skill',baseCost=1,baseBlock=5,playerTarget=true,upgrade={baseBlock=8},tags={'basicDefend'} }
function DefendBlue:use()
	return { GainBlockAction:new{target=player,value=self.block} }
end

Zap = BlueCard:new{ name='Zap',description='Channel !M! {Lightning}.',rarity='basic',type='skill',baseCost=1,baseMagic=1,upgrade={baseCost=0} }
function Zap:use()
	return { ChannelAction:new(Lightning:new{owner=player}) }
end

Dualcast = BlueCard:new{ name='Dualcast',description='Evoke your next Orb twice.',rarity='basic',type='skill',baseCost=1,upgrade={baseCost=0} }
function Dualcast:use()
	return { EvokeAction:new{amount=2} }
end

blueCards = {
	StrikeBlue,DefendBlue,Zap,Dualcast,
}

-- relics
CrackedCore = Relic:new{ name='Cracked Core',tier='basic',icon=243,description='At the start of each combat, channel 1 {Lightning}.' }
function CrackedCore:onCombatStart()
	addAction(ChannelAction:new(Lightning:new{owner=player}))
end
