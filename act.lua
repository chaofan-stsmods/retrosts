-- act
---@diagnostic disable: lowercase-global

Act = Object:new{
	id=0,title='',smallTitle='',cardUpgradedChance=0,drawBackground=noop,
	weakEncounterCount=2,weakEncounters={},exclusiveEncounters={},strongEncounters={},eliteEncounters={},bossEncounters={},
}
function Act:new(o)
	local r = Object.new(self,o)
	r.weakEncounters = normalizeEncounters(r.weakEncounters)
	r.strongEncounters = normalizeEncounters(r.strongEncounters)
	r.eliteEncounters = normalizeEncounters(r.eliteEncounters)
	r.bossEncounters = normalizeEncounters(r.bossEncounters)
	return r
end

function Act:playEntryEffect()
	addEffect(TextEffect:new{duration=120,color=11,text=self.smallTitle,x=120,y=17,small=false,shadow=15})
	addEffect(TextEffect:new{duration=120,color=4,text=self.title,x=120,y=24,small=false,scale=3,shadow=15})
end

function Act:generateEncounters(random)
	local monsterEncounters = {}
	generateEncountersByList(random,monsterEncounters,self.weakEncounters,self.weakEncounterCount,2)
	generateEncountersByList(random,monsterEncounters,self.strongEncounters,1,function(...) return self:exclusiveListCheck(...) end)
	generateEncountersByList(random,monsterEncounters,self.strongEncounters,14,2)
	local eliteEncounters = {}
	generateEncountersByList(random,eliteEncounters,self.eliteEncounters,10,1)
	local bossEncounter = rollEncounters(self.bossEncounters,random)

	trace(table.concat(table.map(monsterEncounters,function (e) return e.name end),','))
	trace(table.concat(table.map(eliteEncounters,function (e) return e.name end),','))
	trace(bossEncounter.name)

	return monsterEncounters,eliteEncounters,bossEncounter
end

function Act:exclusiveListCheck(candidate,encounters)
	local lastEncounter = encounters[#encounters]
	if lastEncounter == nil then
		return true
	end
	local exclusiveEncounters = self.exclusiveEncounters[lastEncounter]
	if exclusiveEncounters == nil then
		return true
	end
	return table.indexOf(exclusiveEncounters,candidate) == nil
end

function rollEncounters(encounters,random)
	local roll = random:rand()
	local sum = 0
	for _, encounterItem in ipairs(encounters) do
		sum = sum + encounterItem.power
		if sum >= roll then
			return encounterItem.item
		end
	end
	return CultistEncounter
end

function normalizeEncounters(encounters)
	local sum = 0
	for _, encounterItem in ipairs(encounters) do
		sum = sum + encounterItem.power
	end
	return table.map(encounters,function (encounterItem)
		return {item=encounterItem.item,power=encounterItem.power/sum}
	end)
end

function defaultExclusiveCheck(candidate,encounters,checkCount)
	return true
	--[[ -- return true before we have enough encounters
	if type(checkCount) ~= 'number' then
		return true
	end
	for i = 0,checkCount-1 do
		local encounter = encounters[#encounters-i]
		if encounter and encounter == candidate then
			return false
		end
	end
	return true
	]]--
end

function generateEncountersByList(random,result,source,count,exclusiveCheck)
	if type(exclusiveCheck) ~= 'function' then
		local oldCheck = exclusiveCheck
		exclusiveCheck = function (candidate,encounters)
			return defaultExclusiveCheck(candidate,encounters,oldCheck)
		end
	end
	for i = 1,count do
		local candidate
		repeat
			candidate = rollEncounters(source,random)
		until exclusiveCheck(candidate,result)
		table.insert(result,candidate)
	end
end

CultistEncounter = Encounter:new{spriteBank=1,name='Cultist',enemyInfo={encItem(Cultist,0,0)}}
TwoLouseEncounter = Encounter:new{spriteBank=1,name='TwoLouse',enemyInfo={}}
function TwoLouseEncounter:setupEnemies(random)
	self.enemyInfo = {}
	self.enemyInfo[1] = random:randBool() and encItem(LouseNormal,-24,0) or encItem(LouseDefensive,-24,0)
	self.enemyInfo[2] = random:randBool() and encItem(LouseNormal,24,0) or encItem(LouseDefensive,24,0)
	Encounter.setupEnemies(self,random)
end

Exordium = Act:new{
	id=1,title='Exordium',smallTitle='Act 1',cardUpgradedChance=0,
	weakEncounterCount=3,
	weakEncounters={
		{item=CultistEncounter,power=1},
		{item=TwoLouseEncounter,power=1},
	}
}
function Exordium:drawBackground()
	sprmap(30,0,30,17,0,0)
end

TheCity = Act:new{id=2,title='The City',smallTitle='Act 2',cardUpgradedChance=0.25}

TheBeyond = Act:new{id=3,title='The Beyond',smallTitle='Act 3',cardUpgradedChance=0.5}

TheEnding = Act:new{id=4,title='The Ending',smallTitle='Final Act',cardUpgradedChance=0.5}

acts = { Exordium,TheCity,TheBeyond,TheEnding }
