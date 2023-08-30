-- potion
---@diagnostic disable: lowercase-global

local allPotions
function getAllPotions()
	return allPotions
end

function generatePotionPool()
	local pool = shallowcopy(allPotions)
	for _, relicType in ipairs(player:getPotions()) do
		table.insert(pool,relicType)
	end
	return pool
end

function getTrueRandomPotionType(random)
	return potionPool[random:randInt(#potionPool)]
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
	local potions = shallowcopy(potionPool)
	table.retainIf(potions,function (p) return p.rarity == rarity and (not noFruit or p == FruitJuice) end)
	return potions[random:randInt(#potions)]
end

function obtainPotion(potion)
	for i,v in ipairs(potions) do
		if v == PotionSlot then
			potions[i] = potion
			return true
		end
	end
	return false
end

function losePotion(potion)
	local index = table.indexOf(potions,potion)
	if index then
		potions[index] = PotionSlot
	end
end

---@class Potion : Object
Potion = {
	name='',description='',icon=Icon:new{image=0},canUseOutsideCombat=false,baseMagic=0,magic=0,timer=0,
	enemyTarget=false,rarity='common',useTitle='Drink',use=noop,priority=50
}
Object:new(Potion)

function Potion:new(o)
	o = o or {}
	o.magic = o.baseMagic
	return Object.new(self,o)
end

function Potion:applyPowers()
	self.magic = self.baseMagic
end

local rainbowSpeed = 0.1
function Potion:drawImage(x,y)
	self.timer = (self.timer + 1) % math.floor(Icon.rainbowLength/rainbowSpeed)
	drawIcon(self.icon,x,y,math.floor(self.timer*rainbowSpeed)+1)
end

function Potion:canUse()
	return (self.canUseOutsideCombat and (currentEvent == nil or currentEvent.canOperatePotion)) or
		(roomActionType == 'combat' and getmetatable(nearestWindow) == GameWindow and
			not inEnemyTurn and table.anyMatch(enemies,function (e) return e.alive end))
end

function Potion:canDiscard()
	return currentEvent == nil or currentEvent.canOperatePotion
end

PotionSlot = Potion:new{icon=Icon:new{image=41}}
function PotionSlot:canUse()
	return false
end

FirePotion = Potion:new{
	name='Fire Potion',description='{Damage} #11#!M!#12#.',icon=Icon:new{image=100,colorMap={1,2,4}},baseMagic=20,enemyTarget=true,useTitle='Throw',rarity='common'
}
function FirePotion:use(target)
	return { DamageAction:new{target=target,source=player,value=self.magic,type='power'} }
end

LiquidMemories = Potion:new{
	name='Liquid Memories',description='Choose #11#!M!#12# card(s) in discard pile and return it to hand. It cost 0 this turn',
	icon=Icon:new{image=107,colorMap={10,9}},baseMagic=1,rarity='uncommon'
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
	name='Fruit Juice',description='Gain #11#!M!#12# max HP.',icon=Icon:new{image=106,colorMap={5,5,4,4}},baseMagic=5,canUseOutsideCombat=true,rarity='rare'
}
function FruitJuice:use()
	player:increaseMaxHp(self.magic)
end

AttackPotion = Potion:new{
	name='Attack Potion',icon=Icon:new{image=101,colorMap={2,2,3}},baseMagic=1,rarity='common',
	description='Choose #11#1#12# of #11#3#12# random {Attack} cards to add to your hand, it costs #11#0#12# this turn.'
}
function AttackPotion:applyPowers()
	Potion.applyPowers(self)
	if self.magic > 1 then
		self.description = 'Choose #11#1#12# of #11#3#12# random {Attack} cards and add #11#!M!#12# copies to your hand, they cost #11#0#12# this turn.'
	end
end

function AttackPotion:use()
	return { DiscoveryAction:new{amount=self.magic,type='attack',cost=0} }
end

SkillPotion = Potion:new{
	name='Skill Potion',icon=Icon:new{image=101,colorMap={5,6,5}},baseMagic=1,rarity='common',
	description='Choose #11#1#12# of #11#3#12# random {Skill} cards to add to your hand, it costs #11#0#12# this turn.'
}
function SkillPotion:applyPowers()
	Potion.applyPowers(self)
	if self.magic > 1 then
		self.description = 'Choose #11#1#12# of #11#3#12# random {Skill} cards and add #11#!M!#12# copies to your hand, they cost #11#0#12# this turn.'
	end
end

function SkillPotion:use()
	return { DiscoveryAction:new{amount=self.magic,type='skill',cost=0} }
end

PowerPotion = Potion:new{
	name='Power Potion',icon=Icon:new{image=101,colorMap={11,13,11}},baseMagic=1,rarity='common',
	description='Choose #11#1#12# of #11#3#12# random {Power} cards to add to your hand, it costs #11#0#12# this turn.'
}
function PowerPotion:applyPowers()
	Potion.applyPowers(self)
	if self.magic > 1 then
		self.description = 'Choose #11#1#12# of #11#3#12# random {Power} cards and add #11#!M!#12# copies to your hand, they cost #11#0#12# this turn.'
	end
end

function PowerPotion:use()
	return { DiscoveryAction:new{amount=self.magic,type='power',cost=0} }
end

ColorlessPotion = Potion:new{
	name='Colorless Potion',icon=Icon:new{image=101,colorMap={12,13,13}},baseMagic=1,rarity='common',
	description='Choose #11#1#12# of #11#3#12# random colorless cards to add to your hand, it costs #11#0#12# this turn.'
}
function ColorlessPotion:applyPowers()
	Potion.applyPowers(self)
	if self.magic > 1 then
		self.description = 'Choose #11#1#12# of #11#3#12# random colorless cards and add #11#!M!#12# copies to your hand, they cost #11#0#12# this turn.'
	end
end

function ColorlessPotion:use()
	return { DiscoveryAction:new{amount=self.magic,cost=0,colorless=true} }
end

BlessingOfTheForge = Potion:new{
	name='Blessing of the Forge',icon=Icon:new{image=103,colorMap={2,3}},rarity='common',description='Upgrade all cards in your hand for the rest of combat.'
}
function BlessingOfTheForge:use()
	return {
		AnonymousAction:new(function ()
			local handCopy = shallowcopy(hand)
			table.retainIf(handCopy,HandSelectUpgradeWindow.filter)
			for _, cardItem in ipairs(handCopy) do
				cardItem.card:upgrade()
				cardItem.card:applyPowers()
			end
		end)
	}
end

BlockPotion = Potion:new{
	name='Block Potion',icon=Icon:new{image=98,colorMap={10,13,11,11,13}},baseMagic=12,rarity='common',
	description='Gain #11#!M!#12# {Block}.'
}
function BlockPotion:use()
	return { GainBlockAction:new{target=player,value=self.magic} }
end

DexterityPotion = Potion:new{
	name='Dexterity Potion',icon=Icon:new{image=98,colorMap={6,6,5,5,6}},baseMagic=2,rarity='common',
	description='Gain #11#!M!#12# {Dexterity}.'
}
function DexterityPotion:use()
	return { ApplyPowerAction:new(DexterityPower:new(player,self.magic)) }
end

StrengthPotion = Potion:new{
	name='Strength Potion',icon=Icon:new{image=98,colorMap={15,15,15,3,3}},baseMagic=2,rarity='common',
	description='Gain #11#!M!#12# {Strength}.'
}
function StrengthPotion:use()
	return { ApplyPowerAction:new(StrengthPower:new(player,self.magic)) }
end

EnergyPotion = Potion:new{
	name='Energy Potion',icon=Icon:new{image=99,colorMap={3,4,4}},baseMagic=2,rarity='common',
	description='Gain #11#!M!#12# {Energy}.'
}
function EnergyPotion:use()
	return { GainEnergyAction:new(self.magic) }
end

ExplosivePotion = Potion:new{
	name='Explosive Potion',icon=Icon:new{image=96,colorMap={4,4,4,4,3,3}},baseMagic=10,rarity='common',useTitle='Throw',
	description='{Damage} #11#!M!#12# to all enemies.'
}
function ExplosivePotion:use()
	return { DamageAllEnemiesAction:new{source=player,value=self.magic,type='power'} }
end

FearPotion = Potion:new{
	name='Fear Potion',icon=Icon:new{image=96,colorMap={2,2,15,15,15,2}},baseMagic=3,rarity='common',useTitle='Throw',
	description='Apply #11#!M!#12# {Vulnerable}.',enemyTarget=true,
}
function FearPotion:use(target)
	return { ApplyPowerAction:new(VulnerablePower:new(target,self.magic)) }
end

FlexPotion = Potion:new{
	name='Flex Potion',icon=Icon:new{image=102,colorMap={15,2,15,2}},baseMagic=5,rarity='common',
	description='Gain #11#!M!#12# temporary {Strength}.',
}
function FlexPotion:use()
	return {
		ApplyPowerAction:new(StrengthPower:new(player,self.magic)),
		ApplyPowerAction:new(LoseStrengthPower:new(player,self.magic)),
	}
end

SpeedPotion = Potion:new{
	name='Speed Potion',icon=Icon:new{image=99,colorMap={6,5,5}},baseMagic=5,rarity='common',
	description='Gain #11#!M!#12# temporary {Dexterity}.'
}
function SpeedPotion:use()
	return {
		ApplyPowerAction:new(DexterityPower:new(player,self.magic)),
		ApplyPowerAction:new(LoseDexterityPower:new(player,self.magic)),
	}
end

SwiftPotion = Potion:new{
	name='Swift Potion',icon=Icon:new{image=96,colorMap={9,11,9,11,9,11}},baseMagic=3,rarity='common',
	description='Draw #11#!M!#12# cards.'
}
function SwiftPotion:use()
	return { DrawCardAction:new(self.magic) }
end

WeakPotion = Potion:new{
	name='Weak Potion',icon=Icon:new{image=96,colorMap={1,1,8,8,1,1}},baseMagic=3,rarity='common',useTitle='Throw',
	description='Apply #11#!M!#12# {Weak}.',enemyTarget=true,
}
function WeakPotion:use(target)
	return { ApplyPowerAction:new(WeakPower:new(target,self.magic)) }
end

CultistPotion = Potion:new{
	name='Cultist Potion',icon=Icon:new{image=108,colorMap={15,9}},baseMagic=1,rarity='rare',
	description='Gain #11#!M!#12# {73}.',
}
function CultistPotion:use()
	return { ApplyPowerAction:new(RitualPower:new(player,self.magic)) }
end

EntropicBrew = Potion:new{
	name='Entropic Brew',icon=Icon:new{image=97,colorMap={-1,-1},isRainbow=true},rarity='rare',canUseOutsideCombat=true,
	description='Fill all your empty potion slots with random potions.'
}
function EntropicBrew:use()
	for i, potion in ipairs(potions) do
		if potion == PotionSlot then
			potions[i] = getRandomPotionType(potionRand or makeRand(act.id,room.id,6)):new()
		end
	end
end

FairyInABottle = Potion:new{
	name='Fairy in a Bottle',icon=Icon:new{image=102,colorMap={7,7,5,5}},rarity='rare',baseMagic=30,
	description='When you would die, heal to #11#!M!%#12# of your Max HP instead and discard this potion.'
}
function FairyInABottle:canUse()
	return false
end

function FairyInABottle:drawImage(x,y)
	Potion.drawImage(self,x,y)
	circ(x+2,y+1,1,5)
	circ(x+6,y+4,1,5)
end

function FairyInABottle:onBeforeDeath()
	local index = table.indexOf(potions,self)
	if index then
		potions[index] = PotionSlot
		player:heal(math.max(1,math.floor(player.maxHp*self.magic/100)))
		return false
	end
end

SmokeBomb = Potion:new{
	name='Smoke Bomb',icon=Icon:new{image=100,colorMap={14,13,14}},rarity='rare',description='Escape from a non-boss combat. Receive no rewards.',
	useTitle='Throw',
}
function SmokeBomb:canUse()
	return table.allMatch(enemies,function (e) return e.type ~= 'boss' end)
end

function SmokeBomb:use()
	return {
		PlayerEscapeAction:new(),
		EndCombatAction:new{escaped=true,secondary=false}
	}
end

SneckoOil = Potion:new{
	name='Snecko Oil',icon=109,rarity='rare',baseMagic=5,description='Draw #11#!M!#12# cards. Randomize the cost of cards in your hand.'
}
function SneckoOil:use()
	return {
		DrawCardAction:new(self.magic),
		AnonymousAction:new(function ()
			for _, cardItem in ipairs(hand) do
				local card = cardItem.card
				if card.baseCost >= 0 then
					local newCost = miscRand:randInt(0,3)
					if newCost ~= card.baseCost then
						card.baseCost = newCost
						card.costForOneTurnPlay = nil
						card.costForOnePlay = nil
						card.baseCostModified = true
						card:applyPowers()
					end
				end
			end
		end)
	}
end

AncientPotion = Potion:new{
	name='Ancient Potion',icon=Icon:new{image=102,colorMap={4,11,4,11}},rarity='uncommon',baseMagic=1,
	description='Gain #11#!M!#12# {22}.'
}
function AncientPotion:use()
	return { ApplyPowerAction:new(ArtifactPower:new(player,self.magic)) }
end

DistilledChaos = Potion:new{
	name='Distilled Chaos',icon=Icon:new{image=104,colorMap={-2,-1},isRainbow=true},rarity='uncommon',baseMagic=3,
	description='Play the top #11#!M!#12# cards of your draw pile.'
}
function DistilledChaos:use()
	local result = {}
	for i=1,self.magic do
		result[i] = PlayTopCardAction:new{randomTarget=true}
	end
	return result
end

DuplicationPotion = Potion:new{
	name='Duplication Potion',icon=Icon:new{image=101,colorMap={-1,13,-1},isRainbow=true},rarity='uncommon',baseMagic=1,
	description='This turn, your next card is played twice.'
}
function DuplicationPotion:applyPowers()
	Potion.applyPowers(self)
	if self.magic > 1 then
		self.description = 'This turn, your next #11#!M!#12# cards are played twice.'
	end
end

function DuplicationPotion:use()
	return { ApplyPowerAction:new(DuplicationPower:new(player,self.magic)) }
end

DuplicationPower = Power:new{icon=20}
function DuplicationPower:onUseCard(_,target,useCardAction)
	if not useCardAction.isDoubleTap then
		local cardItem = useCardAction.cardItem:copy()
		local action = UseCardAction:new{cardItem=cardItem,isDoubleTap=true,tempCard=true,free=true,target=target,energyOnUse=useCardAction.energyOnUse}
		action.useCardPosition = fillCardPosition(cardItem)
		table.insert(limbo,cardItem)
		addAction(ReducePowerAction:new(self,1))
		addAction(action)
	end
end

EssenceOfSteel = Potion:new{
	name='Essence of Steel',icon=Icon:new{image=103,colorMap={7,7}},rarity='uncommon',baseMagic=4,
	description='Gain #11#!M!#12# {62}.'
}
function EssenceOfSteel:use()
	return { ApplyPowerAction:new(PlatedArmorPower:new(player,self.magic)) }
end

GamblersBrew = Potion:new{
	name='Gambler\'s Brew',icon=Icon:new{image=98,colorMap={14,14,13,13,14}},rarity='uncommon',
	description='Discard any number of cards then draw that many.'
}
function GamblersBrew:use()
	return {
		AnonymousAction:new(function ()
			if #hand == 0 then
				return
			else
				openWindowAbove(HandSelectWindow:new{cardItems=hand,title='Choose any Card to Discard',min=0},function (cards)
					for i,cardItem in ipairs(cards) do
						local cardIndex = table.indexOf(hand,cardItem)
						addAction(i,DiscardAction:new{cardItem=cardItem,duration=1})
						removeHand(cardIndex)
					end
					if #cards > 0 then
						addAction(#cards+1,DrawCardAction:new(#cards))
					end
				end)
			end
		end)
	}
end

LiquidBronze = Potion:new{
	name='Liquid Bronze',icon=Icon:new{image=105,colorMap={10,4}},rarity='uncommon',baseMagic=3,
	description='Gain #11#!M!#12# {29}.'
}
function LiquidBronze:use()
	return { ApplyPowerAction:new(ThornsPower:new(player,self.magic)) }
end

RegenPotion = Potion:new{
	name='Regen Potion',icon=Icon:new{image=106,colorMap={13,13,12,12}},rarity='uncommon',baseMagic=5,
	description='Gain #11#!M!#12# {13}.'
}
function RegenPotion:use()
	return { ApplyPowerAction:new(RegeneratePlayerPower:new(player,self.magic)) }
end

allPotions = {
	-- common
	FirePotion,AttackPotion,SkillPotion,PowerPotion,ColorlessPotion,BlessingOfTheForge,BlockPotion,
	DexterityPotion,StrengthPotion,EnergyPotion,ExplosivePotion,FearPotion,FlexPotion,SpeedPotion,
	SwiftPotion,WeakPotion,
	-- uncommon
	LiquidMemories,AncientPotion,DistilledChaos,DuplicationPotion,EssenceOfSteel,GamblersBrew,
	LiquidBronze,RegenPotion,
	-- rare
	FruitJuice,CultistPotion,EntropicBrew,FairyInABottle,SmokeBomb,SneckoOil,
}
