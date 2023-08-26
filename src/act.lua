-- act
---@diagnostic disable: lowercase-global

---@class Act : Object
Act = {
	id=0,title='',smallTitle='',cardUpgradedChance=0,drawBackground=noop,commonRelicChance=50,uncommonRelicChance=33,
	weakEncounterCount=2,weakEncounters={},exclusiveEncounters={},strongEncounters={},eliteEncounters={},bossEncounters={},
	events={}
}
Object:new(Act)

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
	local bossEncounters = {}
	generateEncountersByList(random,bossEncounters,self.bossEncounters,2,1)

	trace(table.concat(table.map(monsterEncounters,function (e) return e.name end),','))
	trace(table.concat(table.map(eliteEncounters,function (e) return e.name end),','))
	trace(table.concat(table.map(bossEncounters,function (e) return e.name end),','))

	return monsterEncounters,eliteEncounters,bossEncounters
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

function Act:bossRoomProceed()
	enterRoom(1)
end

function Act:generateMap(random)
	return generateMap(random,7,15,6)
end

function rollEncounters(encounters,random)
	local item = rollList(random,encounters)
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
		{item=TwoFungiBeastsEncounter,power=2},
		{item=LargeSlimeEncounter,power=2},
		{item=SlaverBlueEncounter,power=2},
		{item=SlaverRedEncounter,power=1},
		{item=LooterEncounter,power=2},
		{item=ExordiumThugsEncounter,power=1.5},
		{item=ExordiumWildlifeEncounter,power=1.5},
		{item=GremlinGangEncounter,power=1},
	},
	exclusiveEncounters={
		[TwoLouseEncounter]={ThreeLouseEncounter},
		[SmallSlimesEncounter]={LotsOfSlimesEncounter,LargeSlimeEncounter},
	},
	eliteEncounters={
		{item=GremlinNobEncounter,power=1},
		{item=ThreeSentryEncounter,power=1},
		{item=LagavulinEncounter,power=1},
	},
	bossEncounters={
		{item=SlimeBossEncounter,power=1},
		{item=HexaghostEncounter,power=1},
		{item=TheGuardianEncounter,power=1},
	},
	events={
		BigFish,TheCleric,WingStatue,WorldOfGoop,TheSsssserpent,LivingWall,ScrapOoze,ShiningLight,DeadAdventurer,Mushrooms,GoldenIdolEvent
	}
}
function Exordium:drawBackground()
	sprmap(30,0,30,17,0,0)
end

TheCity = Act:new{
	id=2,title='The City',smallTitle='Act 2',cardUpgradedChance=0.25,
	weakEncounters={
		{item=TwoThievesEncounter,power=2},
		{item=ThreeByrdsEncounter,power=2},
		{item=SphericGuardianEncounter,power=2},
		{item=Chosen,power=2},
		{item=ShellParasiteEncounter,power=2},
	},
	strongEncounters={
		{item=ThreeCultistsEncounter,power=3},
		{item=SentryAndSphereEncounter,power=2},
		{item=ByrdAndChosenEncounter,power=2},
		{item=CultistAndChosenEncounter,power=3},
		{item=ShellParasiteAndFungiEncounter,power=3},
		{item=CenturionAndMysticEncounter,power=6},
		{item=SnakePlantEncounter,power=6},
		{item=SneckoEncounter,power=3},
	},
	exclusiveEncounters={
		[SphericGuardianEncounter]={SentryAndSphereEncounter},
		[ChosenEncounter]={CultistAndChosenEncounter,ByrdAndChosenEncounter},
		[ShellParasiteEncounter]={ShellParasiteAndFungiEncounter},
		[ThreeByrdsEncounter]={ByrdAndChosenEncounter},
	},
	eliteEncounters={
		{item=SlaversEncounter,power=1},
		{item=GremlinLeaderEncounter,power=1},
		{item=BookOfStabbingEncounter,power=1},
	},
	bossEncounters={
		{item=TheCollector,power=1},
	},
}
function TheCity:drawBackground()
	sprmap(60,0,30,17,0,0)
	if currentEncounter == TheCollectorEncounter and #enemies == 3 then
		local collector = enemies[3]
		sprmap(71,17,8,10,collector.x+4,collector.y-16,8)
	end
end

TheBeyond = Act:new{id=3,title='The Beyond',smallTitle='Act 3',cardUpgradedChance=0.5}
function TheBeyond:drawBackground()
	sprmap(90,0,30,17,0,0)
end

TheEnding = Act:new{
	id=4,title='The Ending',smallTitle='Final Act',cardUpgradedChance=0.5,commonRelicChance=0,uncommonRelicChance=100,
	bossEncounters={
		{item=CorruptHeartEncounter,power=1},
	},
}
function TheEnding:drawBackground()
	sprmap(120,0,30,17,0,0)
end

acts = { Exordium,TheCity,TheBeyond,TheEnding }
