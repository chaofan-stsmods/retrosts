-- relic
---@diagnostic disable: lowercase-global

local colorlessRelics

Relic = Object:new{name='',description='',counter=-1,icon=0,tier='common',colorName='colorless',priority=50}

function Relic:canSpwan()
	return true
end

function Relic:drawImage(x,y,hideCounter)
	spr(self.icon,x,y,0)
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

GoldenIdol = Relic:new{name='Golden Idol',icon=24,tier='special',description='Enemies drop #11#25%#12# more #4#Gold.'}
function GoldenIdol:onAddBonusGoldReward(bonusGold,amount)
	return bonusGold + amount * 0.25
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

colorlessRelics = {
	-- special
	Circlet,NeowsLament,GoldenIdol,OddMushroom,
	-- common
	Anchor,
	-- uncommon
	EternalFeather,
	-- rare
	Calipers,
}
