-- relic
---@diagnostic disable: lowercase-global

local colorlessRelics

Relic = Object:new{name='',description='',counter=nil,icon=0,tier='common',colorName='colorless',priority=50}

function Relic:canSpwan()
	return true
end

function Relic:drawImage(x,y,hideCounter)
	spr(self.icon,x,y,0)
	if self.counter ~= nil and not hideCounter then
		local counterStr = tostring(self.counter)
		local width = strWidth(counterStr,false,true)
		printGlowed(counterStr,math.min(x+5,x+12-width),y+3,12,15,1,true)
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

NeowsLament = Relic:new{name='Neow\'s Lament',description='Enemies in your first #10#3#12# combats will have #10#1#12# HP.',icon=68,tier='special',counter=3}
function NeowsLament:onCombatStart()
	if self.counter ~= nil then
		for _, enemy in ipairs(enemies) do
			if enemy.alive then
				enemy.hp = 1
			end
		end
		self.counter = self.counter - 1
		if self.counter == 0 then
			self.counter = nil
		end
	end
end

GoldenIdol = Relic:new{name='Golden Idol',description='Enemies drop #10#25%#12# more #4#Gold.',icon=24,tier='special'}
function GoldenIdol:onAddBonusGoldReward(bonusGold,amount)
	return bonusGold + amount * 0.25
end

OddMushroom = Relic:new{name='Odd Mushroom',description='When #4#Vulnerable#12#, take #5#25%#12# more attack damage rather than #5#50%.',icon=26,tier='special'}
function OddMushroom:onModifyVulnerableFactor(factor)
	return 1.25
end

colorlessRelics = {
	Circlet,NeowsLament,GoldenIdol,OddMushroom
}
