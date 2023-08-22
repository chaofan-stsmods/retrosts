-- relic
---@diagnostic disable: lowercase-global

local colorlessRelics

Relic = Object:new{name='',description='',counter=-1,icon=0,iconColorMap={},tier='common',colorName='colorless',priority=50}

function Relic:canSpwan()
	return true
end

function Relic:drawImage(x,y,hideCounter)
	for key, value in pairs(self.iconColorMap) do
		mapColor(key,value)
	end
	spr(self.icon,x,y,0)
	for key, _ in pairs(self.iconColorMap) do
		resetColor(key)
	end
	if self.counter >= 0 and not hideCounter then
		local counterStr = tostring(self.counter)
		local width = strWidth(counterStr,false,true)
		printGlowed(counterStr,math.min(x+5,x+12-width),y+3,12,15,1,true)
	end
end

function Relic:save()
	return self.counter < 0 and 0 or ((self.counter << 1) | 1)
end

function Relic:load(meta)
	if meta & 1 ~= 0 then
		self.counter = meta >> 1
	else
		self.counter = -1
	end
end

function getColorlessRelics()
	return colorlessRelics
end

function generateRelicPools(random)
	local result = {common={},uncommon={},rare={},shop={},boss={}}
	for _, relicType in ipairs(getColorlessRelics()) do
		local pool = result[relicType.tier]
		if pool then
			table.insert(pool,relicType)
		end
	end
	for _, relicType in ipairs(player:getRelics()) do
		local pool = result[relicType.tier]
		if pool then
			table.insert(pool,relicType)
		end
	end
	random:shuffle(result.common)
	random:shuffle(result.uncommon)
	random:shuffle(result.rare)
	random:shuffle(result.shop)
	random:shuffle(result.boss)
	return result
end

function obtainRelic(relic)
	if player:triggerConditionEvent('onBeforeObtainRelic',true,relic) then
		table.insert(relics,relic)
		player:triggerEvent('onObtainRelic',relic)
	end
end

function loseRelic(relic)
	local index = table.indexOf(relics,relic)
	if index then
		table.remove(relics,index)
	end
end

Circlet = Relic:new{name='Circlet',description='Collect as many as you can.',icon=55,tier='special',counter=1}
function Circlet:onBeforeObtainRelic(relic)
	if getmetatable(relic) == Circlet then
		self.counter = self.counter + 1
		return false
	end
	return nil
end

NeowsLament = Relic:new{name='Neow\'s Lament',description='Enemies in your first #11#3#12# combats will have #11#1#12# HP.',icon=68,tier='special',counter=3}
function NeowsLament:load(...)
	Relic.load(self,...)
	if self.counter == -1 then
		self.description = 'This relic has been used up.'
	end
end

function NeowsLament:onCombatStart()
	if self.counter ~= -1 then
		for _, enemy in ipairs(enemies) do
			if enemy.alive then
				enemy.hp = 1
			end
		end
		self.counter = self.counter - 1
		if self.counter == 0 then
			self.counter = -1
			self.description = 'This relic has been used up.'
		end
	end
end

GoldenIdol = Relic:new{name='Golden Idol',icon=24,iconColorMap={[5]=4,[6]=3,[7]=2,[9]=1,[10]=2},tier='special',description='Enemies drop #11#25%#12# more #4#Gold.'}
function GoldenIdol:onAddBonusGoldReward(bonusGold,amount)
	return bonusGold + amount * 0.25
end

BloodyIdol = Relic:new{name='Bloody Idol',icon=24,iconColorMap={1,14,13,12,2,2,1,8,2,2,11,12,13,14,2},tier='special',description='Whenever you gain #4#Gold#12#, heal #10#5#12# HP.'}
function BloodyIdol:onGainGold(amount)
	if amount > 0 then
		player:heal(5)
	end
end

OddMushroom = Relic:new{name='Odd Mushroom',icon=26,tier='special',description='When you have {60}, take #11#25%#12# more attack damage rather than #11#50%.'}
function OddMushroom:onModifyVulnerableFactor(factor,isAttacking)
	if isAttacking then
		return factor
	end
	return 1.25
end

Anchor = Relic:new{name='Anchor',icon=27,tier='common',description='Start each combat with #11#10#12# {47}.'}
function Anchor:onCombatStart()
	addAction(GainBlockAction:new{target=player,value=10})
end

EternalFeather = Relic:new{name='Eternal Feather',icon=73,tier='uncommon',description='For every #11#5#12# cards in deck, heal #11#3#12# HP whenever you enter a Rest Site.'}
function EternalFeather:onEnterRoom(room)
	if room.type == 'rest' then
		player:heal(3*math.floor(#deck/5))
	end
end

Calipers = Relic:new{name='Calipers',icon=28,tier='rare',description='At the start of your turn, lose #11#15#12# {47} rather than all.'}
function Calipers:onBeforeTurnStartLoseBlock(block)
	return math.min(block,15)
end

EnergyRelic = Relic:new{tier='boss'}
function EnergyRelic:onObtainRelic()
	maxEnergy = maxEnergy + 1
end

function EnergyRelic:onLoseRelic()
	maxEnergy = maxEnergy - 1
end

CoffeeDripper = EnergyRelic:new{name='Coffee Dripper',icon=173,description='Gain {202} at the start of your turn. You can no longer #4#Rest#12# at Rest Sites.'}
function CoffeeDripper:onModifyCampfireOptions(options)
	for _, option in ipairs(options) do
		if option.name == 'Rest' then
			option.locked = true
			break
		end
	end
end

FusionHammer = EnergyRelic:new{name='Fusion Hammer',icon=177,description='Gain {202} at the start of your turn. You can no longer #4#Smith#12# at Rest Sites.'}
function FusionHammer:onModifyCampfireOptions(options)
	for _, option in ipairs(options) do
		if option.name == 'Smith' then
			option.locked = true
			break
		end
	end
end

Ectoplasm = EnergyRelic:new{name='Ectoplasm',icon=175,description='Gain {202} at the start of your turn. You can no longer gain #4#Gold#12#.'}
function Ectoplasm:onGainGold()
	return 0
end

function Ectoplasm:canSpawn()
	return act.id == 1
end

WarpedTongs = Relic:new{name='Warped Tongs',icon=45,tier='special',description='At the start of your turn, #4#Upgrade#12# a random card in your hand for the rest of combat.'}
function WarpedTongs:onTurnStartPostDraw()
	addAction(AnonymousAction:new(function()
		local candidates = table.map(hand,function(cardItem) return cardItem.card end)
		table.retainIf(candidates,function(card) return card:canUpgrade() end)
		if #candidates == 0 then
			return
		end
		local card
		if #candidates == 1 then
			card = candidates[0]
		else
			card = candidates[miscRand:randInt(#candidates)]
		end
		card:upgrade()
		card:resetPowers()
	end))
end

SpiritPoop = Relic:new{name='Spirit Poop',icon=238,tier='special',description='It\'s unpleasant.'}

CultistMask = Relic:new{name='Cultist Mask',icon=187,tier='special',description='You feel more talkative.'}
function CultistMask:onCombatStart()
	player:talk('@CAW!@ NL @CAAAW@')
end

FaceOfCleric = Relic:new{name='Face of Cleric',icon=189,tier='special',description='At the end of combat, raise your Max HP by #10#1.'}
function FaceOfCleric:onCombatEnd()
	player:increaseMaxHp(1)
end

GremlinMask = Relic:new{name='Gremlin Visage',icon=190,tier='special',description='Start each combat with #10#1#12# {61}.'}
function GremlinMask:onCombatStart()
	addAction(ApplyPowerAction:new(WeakPower:new(player,1,true)))
end

NlothsMask = Relic:new{name='N\'loth\'s Hungry Face',counter=1,icon=239,tier='special',description='The next non-Boss chest you open is empty.'}
function NlothsMask:onOpenNonBossChest(rewards)
	if self.counter <= 0 then
		return
	end
	self.counter = self.counter - 1
	for i,reward in ipairs(rewards) do
		if reward.type == 'relic' then
			table.remove(rewards,i)
			if reward.link then
				local linkIndex = table.indexOf(rewards,reward.link)
				if linkIndex then
					table.remove(rewards,linkIndex)
				end
			end
			break
		end
	end

	if self.counter == 0 then
		self.counter = -1
	end
end

SsserpentHead = Relic:new{name='Ssserpent Head',icon=254,tier='special',description='Whenever you enter a #4#?#12# room, gain #10#50 #4#Gold.'}
function SsserpentHead:onEnterRoom(room)
	if room.type == 'event' then
		gainGold(50)
	end
end

NlothsGift = Relic:new{name='N\'loth\'s Gift',icon=223,tier='special',description='Triple the chance of finding #4#Rare#12# cards from combat rewards.'}
function NlothsGift:onModifyRareCardChance(chance)
	if room.type ~= 'shop' or roomActionType == 'combat' then
		return chance * 3
	end
end

colorlessRelics = {
	-- special
	Circlet,NeowsLament,GoldenIdol,OddMushroom,WarpedTongs,SpiritPoop,CultistMask,FaceOfCleric,GremlinMask,NlothsMask,SsserpentHead,NlothsGift,BloodyIdol,
	-- common
	Anchor,
	-- uncommon
	EternalFeather,
	-- rare
	Calipers,
	-- boss
	CoffeeDripper,FusionHammer,Ectoplasm,
}
