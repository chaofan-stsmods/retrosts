---@diagnostic disable: lowercase-global

Ironclad = Player:new{ maxHp=80,width=5,height=4 }
function Ironclad:drawImage()
	map(0,17,self.width,self.height,self.x-8,self.y,0)
end

function Ironclad:getStartDeck()
	local deck = {}
	local strike = Strike:new()
	table.insert(deck,strike)
	table.insert(deck,strike)
	table.insert(deck,strike)
	table.insert(deck,strike)
	table.insert(deck,strike)
	local defend = Defend:new()
	table.insert(deck,defend)
	table.insert(deck,defend)
	table.insert(deck,defend)
	table.insert(deck,defend)
	table.insert(deck,Bash:new())
	return deck
end

Strike = Card:new{ name='Strike',description='{63} !D!.',rarity='basic',cost=1,baseDamage=6,damage=6,enemyTarget=true }
function Strike:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

Defend = Card:new{ name='Defend',description='Gain !B! {47}.',rarity='basic',type='skill',cost=1,baseBlock=5,block=5,playerTarget=true }
function Defend:use()
	return { GainBlockAction:new{target=player,value=self.block} }
end

Bash = Card:new{ name='Bash',description='{63} !D!. NL Apply !M! {60}.',rarity='basic',cost=2,enemyTarget=true,baseDamage=8,damage=8,baseMagic=2,magic=2 }
function Bash:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage}, ApplyPowerAction:new(VulnerablePower:new(target,self.magic)) }
end