---@diagnostic disable: lowercase-global

Ironclad = Player:new{ maxHp=80,width=5,height=4 }
function Ironclad:drawImage()
	map(0,17,self.width,self.height,self.x-8,self.y,0)
end

function Ironclad:getStartDeck()
	local deck = {}
	local strike = Strike:new()
	table.insert(deck,Metallicize:new())
	table.insert(deck,Sentinel:new())
	table.insert(deck,SecondWind:new())
	table.insert(deck,PowerThrough:new())
	table.insert(deck,SeverSoul:new())
	local defend = Defend:new()
	defend:upgrade()
	table.insert(deck,Havoc:new())
	table.insert(deck,Bloodletting:new())
	table.insert(deck,RecklessCharge:new())
	table.insert(deck,Armaments:new())
	table.insert(deck,Barricade:new())
	return deck
end

RedCard = Card:new{color={2,1},costIcon=45,typeIconColor=4}

Strike = RedCard:new{ name='Strike',description='{63} !D!.',rarity='basic',cost=1,baseDamage=6,enemyTarget=true,upgrade={baseDamage=9},tags={'strike'} }
function Strike:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

Defend = RedCard:new{ name='Defend',description='Gain !B! {47}.',rarity='basic',type='skill',cost=1,baseBlock=5,playerTarget=true,upgrade={baseBlock=8},tags={'defend'} }
function Defend:use()
	return { GainBlockAction:new{target=player,value=self.block} }
end

Bash = RedCard:new{
	name='Bash',description='{63} !D!. NL Apply !M! {60}.',rarity='basic',cost=2,enemyTarget=true,baseDamage=8,baseMagic=2,
	upgrade={baseDamage=10,baseMagic=3},
}
function Bash:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage}, ApplyPowerAction:new(VulnerablePower:new(target,self.magic)) }
end

BodySlam = RedCard:new{ name='Body Slam',description='{63} equal to your {47}.',rarity='common',cost=1,enemyTarget=true,upgrade={cost=0} }
function BodySlam:applyPowers(target)
	self.baseDamage = player.block
	self.description='{63} equal to your {47}. NL ({63} !D!.)'
	RedCard.applyPowers(self,target)
end

function BodySlam:resetPowers()
	self.description='{63} equal to your {47}.'
	RedCard.resetPowers(self)
end

function BodySlam:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

Clash = RedCard:new{
	name='Clash',description='Can only be played if every card in hand is {57}. NL {63} !D!.',rarity='common',
	cost=0,enemyTarget=true,baseDamage=14,upgrade={baseDamage=18}
}
function Clash:canUse()
	return RedCard.canUse(self) and table.allMatch(hand,function (cardItem) return cardItem.card.type == 'attack' end)
end

function Clash:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

Cleave = RedCard:new{
	name='Cleave',description='{63} !D! to all enemies.',rarity='common',cost=1,enemyTarget=true,toAllEnemies=true,baseDamage=8,upgrade={baseDamage=11}
}
function Cleave:use()
	return { DamageAllEnemiesAction:new{source=player,value=self.multiDamage} }
end

Clothesline = RedCard:new{
	name='Clothesline',description='{63} !D!. NL Apply !M! {61}.',rarity='common',cost=2,enemyTarget=true,baseDamage=12,baseMagic=2,
	upgrade={baseDamage=14,baseMagic=3},
}
function Clothesline:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage}, ApplyPowerAction:new(WeakPower:new(target,self.magic)) }
end

Inflame = RedCard:new{ name='Inflame',description='Gain !M! {76<}.',rarity='uncommon',type='power',cost=1,playerTarget=true,baseMagic=2,upgrade={baseMagic=3} }
function Inflame:use()
	return { ApplyPowerAction:new(StrengthPower:new(player,self.magic)) }
end

IronWave = RedCard:new{
	name='Iron Wave',description='Gain !B! {47}. NL {63} !D!.',rarity='common',cost=1,baseDamage=5,baseBlock=5,
	playerTarget=true,enemyTarget=true,upgrade={baseDamage=7,baseBlock=7}
}
function IronWave:use(target)
	return { GainBlockAction:new{target=player,value=self.block}, DamageAction:new{target=target,source=player,value=self.damage} }
end

PommelStrike = RedCard:new{
	name='Pommel Strike',description='{63} !D!. NL Draw !M! card.',rarity='common',cost=1,baseDamage=9,baseMagic=1,
	playerTarget=true,enemyTarget=true,upgrade={baseDamage=10,baseMagic=2,description='{63} !D!. NL Draw !M! cards.'},tags={'strike'}
}
function PommelStrike:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage}, DrawCardAction:new(self.magic) }
end

ShrugItOff = RedCard:new{
	name='Shrug It Off',description='Gain !B! {47}. NL Draw !M! card.',rarity='common',type='skill',cost=1,baseBlock=8,baseMagic=1,
	playerTarget=true,upgrade={baseBlock=11}
}
function ShrugItOff:use()
	return { GainBlockAction:new{target=player,value=self.block}, DrawCardAction:new(self.magic) }
end

SwordBoomerang = RedCard:new{
	name='Sword Boomerang',description='{63} !D! to a random enemy !M! times.',rarity='common',cost=1,baseDamage=3,baseMagic=3,
	enemyTarget=true,toAllEnemies=true,upgrade={baseMagic=4}
}
function SwordBoomerang:use()
	local result = {}
	for i = 1, self.magic do
		result[i] = DamageRandomEnemyAction:new{source=player,value=self.multiDamage}
	end
	return result
end

Thunderclap = RedCard:new{
	name='Thunderclap',description='{63} !D! and apply !M! {60} to all enemies.',rarity='common',cost=1,baseDamage=4,baseMagic=1,
	enemyTarget=true,toAllEnemies=true,upgrade={baseMagic=7}
}
function Thunderclap:use()
	local result = {}
	table.insert(result,DamageAllEnemiesAction:new{source=player,value=self.multiDamage})
	for _, enemy in ipairs(enemies) do
		table.insert(result,ApplyPowerAction:new(VulnerablePower:new(enemy,self.magic)))
	end
	return result
end

TwinStrike = RedCard:new{ name='Twin Strike',description='{63} !D! twice.',rarity='common',cost=1,baseDamage=5,enemyTarget=true,upgrade={baseDamage=7},tags={'strike'} }
function TwinStrike:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage},DamageAction:new{target=target,source=player,value=self.damage} }
end

PerfectedStrike = RedCard:new{
	name='Perfected Strike',description='{63} !D!. NL +!M! damage for ALL your "Strike" card.',rarity='common',
	cost=2,baseDamage=6,baseMagic=2,enemyTarget=true,upgrade={baseMagic=3},tags={'strike'}
}
function PerfectedStrike:applyPowers(target)
	local oldBaseDamage = self.baseDamage
	local hasSelf = false
	for _, card in ipairs(drawPile) do
		if table.indexOf(card.tags,'strike') then
			self.baseDamage = self.baseDamage + self.magic
			hasSelf = hasSelf or card == self
		end
	end
	for _, card in ipairs(discardPile) do
		if table.indexOf(card.tags,'strike') then
			self.baseDamage = self.baseDamage + self.magic
			hasSelf = hasSelf or card == self
		end
	end
	for _, cardItem in ipairs(hand) do
		if table.indexOf(cardItem.card.tags,'strike') then
			self.baseDamage = self.baseDamage + self.magic
			hasSelf = hasSelf or cardItem.card == self
		end
	end
	if not hasSelf then
		self.baseDamage = self.baseDamage + self.magic
	end
	RedCard.applyPowers(self,target)
	self.baseDamage = oldBaseDamage
end

function PerfectedStrike:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

HeavyBlade = RedCard:new{
	name='Heavy Blade',description='{63} !D!. NL {76<} affects this card !M! times.',rarity='common',
	cost=2,baseDamage=14,baseMagic=3,enemyTarget=true,upgrade={baseMagic=5}
}
function HeavyBlade:applyPowers(target)
	local strength = player:getPower(StrengthPower)
	local originalAmount
	if strength then
		originalAmount = strength.amount
		strength.amount = strength.amount * self.magic
	end
	RedCard.applyPowers(self,target)
	if strength then
		strength.amount = originalAmount
	end
end

function HeavyBlade:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

Bloodletting = RedCard:new{
	name='Bloodletting',description='Lose 3 HP. NL Gain {62}{62}.',rarity='uncommon',type='skill',cost=0,
	baseMagic=2,playerTarget=true,upgrade={baseMagic=3,description='Lose 3 HP. NL Gain {62}{62}{62}.'}
}
function Bloodletting:use()
	return { DamageAction:new{target=player,source=player,type='hploss',value=3}, GainEnergyAction:new(self.magic) }
end

Entrench = RedCard:new{ name='Entrench',description='Double your {47}.',rarity='uncommon',type='skill',cost=2,playerTarget=true,upgrade={cost=1} }
function Entrench:use()
	return { AnonymousAction:new(function()
		addAction(1,GainBlockAction:new{target=player,value=player.block})
	end) }
end

Hemokinesis = RedCard:new{ name='Hemokinesis',description='Lose 2 HP. NL {63} !D!.',rarity='uncommon',cost=1,baseDamage=15,enemyTarget=true,upgrade={baseDamage=20} }
function Hemokinesis:use(target)
	return { DamageAction:new{target=player,source=player,type='hploss',value=2}, DamageAction:new{target=target,source=player,value=self.damage} }
end

Rampage = RedCard:new{
	name='Rampage',description='{63} !D!. NL +!M! damage this combat.',rarity='uncommon',cost=1,baseDamage=8,baseMagic=5,
	enemyTarget=true,upgrade={baseMagic=8}
}
function Rampage:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage}, AnonymousAction:new(function ()
		self.baseDamage = self.baseDamage + self.magic
	end) }
end

SpotWeakness = RedCard:new{
	name='Spot Weakness',description='If the enemy intends to attack, gain !M! {76<}.',rarity='uncommon',type='skill',
	cost=1,playerTarget=true,enemyTarget=true,baseMagic=3,upgrade={baseMagic=4}
}
function SpotWeakness:use(target)
	return { AnonymousAction:new(function()
		if target.intentType:sub(1,6) == 'attack' then
			addAction(1,ApplyPowerAction:new(StrengthPower:new(player,self.magic)))
		end
	end) }
end

Uppercut = RedCard:new{
	name='Uppercut',description='{63} !D!. NL Apply !M! {60} and {61}.',rarity='uncommon',cost=2,enemyTarget=true,baseDamage=13,baseMagic=1,
	upgrade={baseMagic=2},
}
function Uppercut:use(target)
	return {
		DamageAction:new{target=target,source=player,value=self.damage},
		ApplyPowerAction:new(VulnerablePower:new(target,self.magic)),
		ApplyPowerAction:new(WeakPower:new(target,self.magic)),
	}
end

Whirlwind = RedCard:new{
	name='Whirlwind',description='{63} !D! to all enemies X times.',rarity='uncommon',cost=-1,enemyTarget=true,toAllEnemies=true,
	baseDamage=5,upgrade={baseDamage=8},
}
function Whirlwind:use()
	return {
		XCardAction:new(function (amount)
			local result = {}
			for i = 1, amount do
				result[i] = DamageAllEnemiesAction:new{source=player,value=self.multiDamage}
			end
			return result
		end)
	}
end

Bludgeon = RedCard:new{ name='Bludgeon',description='{63} !D!.',rarity='rare',cost=3,baseDamage=32,enemyTarget=true,upgrade={baseDamage=42} }
function Bludgeon:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

Offering = RedCard:new{
	name='Offering',description='Lose 6 HP. NL Gain {62}{62}. NL Draw !M! cards. NL Exhaust.',rarity='rare',type='skill',cost=0,
	baseMagic=3,playerTarget=true,upgrade={baseMagic=5},exhaust=true,
}
function Offering:use()
	return { DamageAction:new{target=player,source=player,type='hploss',value=6}, GainEnergyAction:new(2), DrawCardAction:new(self.magic) }
end

LimitBreak = RedCard:new{
	name='Limit Break',description='Double your {76<}. NL Exhaust.',rarity='rare',type='skill',cost=1,
	playerTarget=true,upgrade={exhaust=false,description='Double your {76<}.'},exhaust=true,
}
function LimitBreak:use()
	return { AnonymousAction:new(function()
		local strength = player:getPower(StrengthPower)
		if strength then
			addAction(1,ApplyPowerAction:new(StrengthPower:new(player,strength.amount)))
		end
	end) }
end

Impervious = RedCard:new{
	name='Impervious',description='Gain !B! {47}. NL Exhaust.',rarity='rare',type='skill',cost=2,baseBlock=30,
	playerTarget=true,upgrade={baseBlock=40},exhaust=true
}
function Impervious:use()
	return { GainBlockAction:new{target=player,value=self.block} }
end

Shockwave = RedCard:new{
	name='Shockwave',description='Apply !M! {60} and {61} to all enemies. NL Exhaust.',rarity='uncommon',type='skill',cost=2,baseMagic=3,
	enemyTarget=true,toAllEnemies=true,upgrade={baseMagic=5},exhaust=true
}
function Shockwave:use()
	local result = {}
	for _, enemy in ipairs(enemies) do
		table.insert(result,ApplyPowerAction:new(VulnerablePower:new(enemy,self.magic)))
		table.insert(result,ApplyPowerAction:new(WeakPower:new(enemy,self.magic)))
	end
	return result
end

SeeingRed = RedCard:new{
	name='Seeing Red',description='Gain {62}{62}. NL Exhaust.',rarity='uncommon',type='skill',cost=1,
	baseMagic=2,playerTarget=true,upgrade={cost=0},exhaust=true,
}
function SeeingRed:use()
	return { GainEnergyAction:new(self.magic) }
end

Pummel = RedCard:new{
	name='Pummel',description='{63} !D!, !M! times.',rarity='uncommon',cost=1,baseDamage=2,baseMagic=4,
	enemyTarget=true,upgrade={baseMagic=5},exhaust=true,
}
function Pummel:use(target)
	local result = {}
	for i = 1, self.magic do
		result[i] = DamageAction:new{target=target,source=player,value=self.damage}
	end
	return result
end

Intimidate = RedCard:new{
	name='Intimidate',description='Apply !M! {61} to all enemies. NL Exhaust.',rarity='uncommon',type='skill',cost=0,baseMagic=1,
	enemyTarget=true,toAllEnemies=true,upgrade={baseMagic=2},exhaust=true
}
function Intimidate:use()
	local result = {}
	for _, enemy in ipairs(enemies) do
		table.insert(result,ApplyPowerAction:new(WeakPower:new(enemy,self.magic)))
	end
	return result
end

Disarm = RedCard:new{
	name='Disarm',description='Enemy loses !M! {76<}. NL Exhaust.',rarity='uncommon',type='skill',cost=1,baseMagic=2,
	enemyTarget=true,upgrade={baseMagic=3},exhaust=true
}
function Disarm:use(target)
	return { ApplyPowerAction:new(StrengthPower:new(target,-self.magic)) }
end

Flex = RedCard:new{
	name='Flex',description='Gain !M! temporary {76<}.',rarity='common',type='skill',cost=0,baseMagic=2,
	playerTarget=true,upgrade={baseMagic=4}
}
function Flex:use()
	return { ApplyPowerAction:new(StrengthPower:new(player,self.magic)),ApplyPowerAction:new(LoseStrengthPower:new(player,self.magic)) }
end

Anger = RedCard:new{
	name='Anger',description='{63} !D!. NL Add a copy of this card into discard pile.',rarity='common',cost=0,
	baseDamage=6,enemyTarget=true,upgrade={baseDamage=8}
}
function Anger:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage},MakeTempCardToDiscardPileAction:new(self,1) }
end

Armaments = RedCard:new{
	name='Armaments',description='Gain !B! {47}. NL Upgrade a card in hand for the combat.',rarity='common',type='skill',cost=1,baseBlock=5,
	playerTarget=true,upgrade={description='Gain !B! {47}. NL Upgrade all cards in hand for the combat.'}
}
function Armaments:use()
	return {
		GainBlockAction:new{target=player,value=self.block},
		AnonymousAction:new(function ()
			local handCopy = shallowcopy(hand)
			table.retainIf(handCopy,HandSelectUpgradeWindow.filter)
			if #handCopy == 0 then
				return
			end
			if #handCopy == 1 or self.upgraded then
				for _, cardItem in ipairs(handCopy) do
					cardItem.card:upgrade()
					cardItem.card:applyPowers()
				end
			else
				openWindowAbove(HandSelectUpgradeWindow:new{cardItems=hand},function (cards)
					for _, cardItem in ipairs(cards) do
						cardItem.card:upgrade()
						cardItem.card:applyPowers()
					end
				end)
			end
		end)
	}
end

PowerThrough = RedCard:new{
	name='Power Through',description='Add !M! Wounds into hand. NL Gain !B! {47}.',rarity='uncommon',type='skill',cost=1,baseBlock=15,baseMagic=2,
	upgrade={baseBlock=20},playerTarget=true
}
function PowerThrough:use()
	return { GainBlockAction:new{target=player,value=self.block}, MakeTempCardToHandAction:new(Wound:new(),self.magic) }
end

Havoc = RedCard:new{
	name='Havoc',description='Play the top card of draw pile and exhaust it.',rarity='common',type='skill',cost=1,
	upgrade={cost=0},enemyTarget=true,toAllEnemies=true,playerTarget=true
}
function Havoc:use()
	return { PlayTopCardAction:new{randomTarget=true,exhaust=true} }
end

TrueGrit = RedCard:new{
	name='True Grit',description='Gain !B! {47}. NL Exhaust a card at random.',rarity='common',type='skill',cost=1,baseBlock=7,
	playerTarget=true,upgrade={baseBlock=9,description='Gain !B! {47}. NL Exhaust a card.'}
}
function TrueGrit:use()
	return {
		GainBlockAction:new{target=player,value=self.block},
		AnonymousAction:new(function ()
			if #hand == 0 then
				return
			end
			if not self.upgraded or #hand == 1 then
				local cardIndex = miscRand:randInt(#hand)
				addAction(1,ExhaustCardAction:new{cardItem=hand[cardIndex],show=true})
				removeHand(cardIndex)
			else
				openWindowAbove(HandSelectWindow:new{cardItems=hand,title='Choose a Card to Exhaust',max=1},function (cards)
					for _, cardItem in ipairs(cards) do
						local cardIndex = table.indexOf(hand,cardItem)
						addAction(1,ExhaustCardAction:new{cardItem=cardItem})
						removeHand(cardIndex)
					end
				end)
			end
		end)
	}
end

Warcry = RedCard:new{
	name='Warcry',description='Draw !M! card. NL Put a card from hand onto the top of draw pile. NL Exhaust.',rarity='common',type='skill',cost=0,baseMagic=1,
	playerTarget=true,upgrade={baseMagic=2,description='Draw !M! cards. NL Put a card from hand onto the top of draw pile. NL Exhaust.'},exhaust=true
}
function Warcry:use()
	return {
		DrawCardAction:new(self.magic),
		AnonymousAction:new(function ()
			if #hand == 0 then
				return
			end
			if #hand == 1 then
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

WildStrike = RedCard:new{
	name='Wild Strike',description='{63} !D!. NL Shuffle a Wound into draw pile.',rarity='common',cost=1,baseDamage=12,
	playerTarget=true,enemyTarget=true,upgrade={baseDamage=17},tags={'strike'}
}
function WildStrike:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage}, MakeTempCardToDrawPileAction:new(Wound:new()) }
end

BattleTrance = RedCard:new{
	name='Battle Trance',description='Draw !M! card. NL You cannot draw additional cards this turn.',rarity='uncommon',type='skill',
	cost=0,baseMagic=3,playerTarget=true,upgrade={baseMagic=4}
}
function BattleTrance:use()
	return { DrawCardAction:new(self.magic), ApplyPowerAction:new(NoDrawPower:new(player)) }
end

BloodForBlood = RedCard:new{
	name='Blood for Blood',description='Costs 1 less {62} each time you lose HP this combat. NL {63} !D!.',rarity='uncommon',
	cost=4,baseDamage=18,enemyTarget=true
}
function BloodForBlood:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

function BloodForBlood:onHpLoss()
	self.cost = self.cost - 1
end

function BloodForBlood:upgrade()
	self.cost = self.cost - 1
	self:upgradeValues({baseDamage=22})
end

BurningPact = RedCard:new{
	name='Burning Pact',description='Exhaust a card. NL Draw !M! cards.',rarity='uncommon',type='skill',cost=1,baseMagic=2,
	playerTarget=true,upgrade={baseMagic=3}
}
function BurningPact:use()
	return {
		AnonymousAction:new(function ()
			if #hand == 0 then
				return
			end
			if #hand == 1 then
				addAction(1,ExhaustCardAction:new{cardItem=hand[1],show=true})
				removeHand(1)
			else
				openWindowAbove(HandSelectWindow:new{cardItems=hand,title='Choose a Card to Exhaust',max=1},function (cards)
					for _, cardItem in ipairs(cards) do
						local cardIndex = table.indexOf(hand,cardItem)
						addAction(1,ExhaustCardAction:new{cardItem=cardItem})
						removeHand(cardIndex)
					end
				end)
			end
		end),
		DrawCardAction:new(self.magic)
	}
end

Carnage = RedCard:new{
	name='Carnage',description='{63} !D!. NL Ethereal.',rarity='uncommon',cost=2,baseDamage=20,
	enemyTarget=true,upgrade={baseDamage=28},ethereal=true
}
function Carnage:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage} }
end

Dropkick = RedCard:new{
	name='Dropkick',description='{63} !D!. NL If enemy has {60}, gain {62} and draw 1 card.',rarity='uncommon',cost=1,baseDamage=5,
	enemyTarget=true,playerTarget=true,upgrade={baseDamage=8}
}
function Dropkick:use(target)
	local r = { DamageAction:new{target=target,source=player,value=self.damage} }
	if target:getPower(VulnerablePower) then
		table.insert(r,GainEnergyAction:new(1))
		table.insert(r,DrawCardAction:new(1))
	end
	return r
end

DualWield = RedCard:new{
	name='Dual Wield',description='Choose a {57} or {59}. Add a copy of that card into hand.',rarity='uncommon',type='skill',cost=1,baseMagic=1,
	playerTarget=true,upgrade={baseMagic=2,description='Choose a {57} or {59}. Add !M! copies of that card into hand.'}
}
function DualWield:use()
	local function isAttackOrPower(cardItem) return cardItem.card.type == 'attack' or cardItem.card.type == 'power' end
	return {
		AnonymousAction:new(function ()
			local validCards = shallowcopy(hand)
			table.retainIf(validCards,isAttackOrPower)
			if #validCards == 0 then
				return
			end
			if #validCards == 1 then
				addAction(1,MakeTempCardToHandAction:new(validCards[1].card,self.magic))
			else
				openWindowAbove(HandSelectWindow:new{cardItems=hand,title='Choose a Card to Copy',max=1,filter=isAttackOrPower},
					function (cards)
						for _, cardItem in ipairs(cards) do
							addAction(1,MakeTempCardToHandAction:new(cardItem.card,self.magic))
						end
					end)
			end
		end)
	}
end

GhostlyArmor = RedCard:new{
	name='GhostlyArmor',description='Gain !B! {47}. NL Ethereal.',rarity='uncommon',type='skill',cost=1,baseBlock=10,
	playerTarget=true,upgrade={baseBlock=13},ethereal=true
}
function GhostlyArmor:use()
	return { GainBlockAction:new{target=player,value=self.block} }
end

RecklessCharge = RedCard:new{
	name='Reckless Charge',description='{63} !D!. NL Shuffle a Dazed into draw pile.',rarity='uncommon',cost=0,baseDamage=7,
	playerTarget=true,enemyTarget=true,upgrade={baseDamage=10}
}
function RecklessCharge:use(target)
	return { DamageAction:new{target=target,source=player,value=self.damage}, MakeTempCardToDrawPileAction:new(Dazed:new()) }
end

Metallicize = RedCard:new{ name='Metallicize',description='At the end of turn, gain !M! {47}.',rarity='uncommon',type='power',cost=1,playerTarget=true,baseMagic=3,upgrade={baseMagic=4} }
function Metallicize:use()
	return { ApplyPowerAction:new(MetallicizePower:new(player,self.magic)) }
end

Rage = RedCard:new{
	name='Rage',description='Whenever you play a {57} this turn, gain !M! {47}.',rarity='uncommon',type='skill',cost=0,baseMagic=3,
	playerTarget=true,upgrade={baseMagic=5}
}
function Rage:use()
	return { ApplyPowerAction:new(RagePower:new(player,self.magic)) }
end

RagePower = Power:new{icon=17}
function RagePower:onUseCard(card)
	if card.type == 'attack' then
		addAction(GainBlockAction:new{target=self.owner,value=self.amount})
	end
end

function RagePower:onTurnEnd()
	addAction(ReducePowerAction:new(self,self.amount))
end

SecondWind = RedCard:new{
	name='Second Wind',description='Exhaust all non-{57} in hand, gain !B! {47} for each card exhausted.',rarity='uncommon',type='skill',
	cost=1,baseBlock=5,playerTarget=true,upgrade={baseBlock=7}
}
function SecondWind:use()
	local function isNotAttack(cardItem) return cardItem.card.type ~= 'attack' end
	return {
		AnonymousAction:new(function ()
			local targetCards = shallowcopy(hand)
			table.retainIf(targetCards,isNotAttack)
			miscRand:shuffle(targetCards)
			
			for _ = 1,#targetCards do
				addAction(1,GainBlockAction:new{target=player,value=self.block})
			end

			for _, cardItem in ipairs(targetCards) do
				local cardIndex = table.indexOf(hand,cardItem)
				addAction(1,ExhaustCardAction:new{cardItem=cardItem,duration=5})
				removeHand(cardIndex)
			end
		end)
	}
end

SeverSoul = RedCard:new{
	name='Sever Soul',description='Exhaust all non-{57} in hand. NL {63} !D!.',rarity='uncommon',cost=2,baseDamage=16,
	playerTarget=true,enemyTarget=true,upgrade={baseDamage=22}
}
function SeverSoul:use(target)
	local function isNotAttack(cardItem) return cardItem.card.type ~= 'attack' end
	return {
		AnonymousAction:new(function ()
			local targetCards = shallowcopy(hand)
			table.retainIf(targetCards,isNotAttack)
			miscRand:shuffle(targetCards)

			for _, cardItem in ipairs(targetCards) do
				local cardIndex = table.indexOf(hand,cardItem)
				addAction(1,ExhaustCardAction:new{cardItem=cardItem,duration=5})
				removeHand(cardIndex)
			end
		end),
		DamageAction:new{target=target,source=player,value=self.damage}
	}
end

Sentinel = RedCard:new{
	name='Sentinel',description='Gain !B! {47}. NL When this card is exhausted, gain {62}{62}.',rarity='uncommon',type='skill',cost=1,baseBlock=5,
	baseMagic=2,playerTarget=true,upgrade={baseBlock=8,baseMagic=3,description='Gain !B! {47}. NL When this card is exhausted, gain {62}{62}{62}.'}
}
function Sentinel:use()
	return { GainBlockAction:new{target=player,value=self.block} }
end

function Sentinel:onExhaust()
	addAction(GainEnergyAction:new(self.magic))
end

Barricade = RedCard:new{
	name='Barricade',description='{47} is not removed at the start of turn.',rarity='rare',type='power',cost=3,playerTarget=true,
	upgrade={cost=2}
}
function Barricade:use()
	return { ApplyPowerAction:new(BarricadePower:new(player)) }
end
