-- act
---@diagnostic disable: lowercase-global

Act = Object:new{
	id=0,title='',smallTitle='',cardUpgradedChance=0,drawBackground=noop,
	weakEncounterCount=2,weakEncounters={},exclusiveEncounters={},strongEncounters={},eliteEncounters={},bossEncounters={},
}
function Act:new(o)
	local r = Object.new(self,o)
	normalize(r.weakEncounters)
	normalize(r.strongEncounters)
	normalize(r.eliteEncounters)
	normalize(r.bossEncounters)
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
	local _,item = rollList(random,encounters)
	return item and item.item or CultistEncounter
end

function defaultExclusiveCheck(candidate,encounters,checkCount)
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
end

function generateEncountersByList(random,result,source,count,exclusiveCheck)
	local skipCheck = false
	if type(exclusiveCheck) ~= 'function' then
		local oldCheck = exclusiveCheck
		skipCheck = oldCheck >= #source
		exclusiveCheck = function (candidate,encounters)
			return defaultExclusiveCheck(candidate,encounters,oldCheck)
		end
	end
	for i = 1,count do
		local candidate
		repeat
			candidate = rollEncounters(source,random)
		until exclusiveCheck(candidate,result) or skipCheck
		table.insert(result,candidate)
	end
end

Exordium = Act:new{
	id=1,title='Exordium',smallTitle='Act 1',cardUpgradedChance=0,
	weakEncounterCount=3,
	weakEncounters={
		{item=CultistEncounter,power=2},
		{item=TwoLouseEncounter,power=2},
		{item=JawWormEncounter,power=2},
		{item=SmallSlimesEncounter,power=2},
	},
	strongEncounters={
		{item=LotsOfSlimesEncounter,power=1},
		{item=ThreeLouseEncounter,power=2},
		{item=TwoFungiBeastEncounter,power=2},
	},
	exclusiveEncounters={
		[TwoLouseEncounter]={ThreeLouseEncounter},
		[SmallSlimesEncounter]={LotsOfSlimesEncounter},
	},
}
function Exordium:drawBackground()
	sprmap(30,0,30,17,0,0)
end

TheCity = Act:new{id=2,title='The City',smallTitle='Act 2',cardUpgradedChance=0.25}

TheBeyond = Act:new{id=3,title='The Beyond',smallTitle='Act 3',cardUpgradedChance=0.5}

TheEnding = Act:new{id=4,title='The Ending',smallTitle='Final Act',cardUpgradedChance=0.5}

acts = { Exordium,TheCity,TheBeyond,TheEnding }
