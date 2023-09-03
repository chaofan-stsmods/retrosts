-- save
---@diagnostic disable: lowercase-global

--[[
Game properties:
0: 0 No save, low 8 bits: 1~4 Player ID, 8~15 bits: ascension, 16~31 bits: seed lower 16 bits
1: seed remaining bits
2: low 16 bits: hp, high 16 bits: maxHp
3: common, uncommon, rare, shop each 8 bits
4: low 8 bits boss relics, 8~15 bits floor, remaining gold
5: low 8 bits max energy, 8~15 bits shop remove count, 16 rubyKey, 17 emeraldKey, 18, sapphireKey
6: one time events
Act properties:
7: act id, next monster encounter id, next elite encounter id, next boss encounter id, each 8 bits
8: act events
9: common events
10: reward generator
11: event generator
12: currentX, currentY, special room id each 8 bits
13 ~ 14: player path, each item 3 bits
15: 1 bit completed, 3 bits event room type, 12 bits event type, 16 bits event meta
Variable length properties:
16: num cards 16 bits, num relics 10 bits, num potion 6 bits
17 ~ N: cards
N+1 ~ N+M: relics
N+M+1 ~ N+M+L: potions
]]--

function hasSave()
	return pmem(0) ~= 0
end

local function saveListBits(index,current,fullList)
	local r = 0
	for _, item in ipairs(current) do
		local indexInFullList = table.indexOf(fullList,item)
		if indexInFullList then
			r = r | (1 << (indexInFullList - 1))
		end
	end
	pmem(index,r)
end

local function loadListBits(index,fullList)
	local result = {}
	local r = pmem(index)
	local indexInFullList = 1
	while r > 0 do
		if r & 1 ~= 0 then
			table.insert(result,fullList[indexInFullList])
		end
		r = r >> 1
		indexInFullList = indexInFullList + 1
	end
	return result
end

---@type table<number,Card>
local cardTypeMapForSave = nil
local function assignCardIndex()
	if cardTypeMapForSave ~= nil then
		return
	end

	cardTypeMapForSave = {}
	for i, card in ipairs(getColorlessCards()) do
		card.saveIndex = i
		cardTypeMapForSave[card.saveIndex] = card
	end
	for i, card in ipairs(getCurseCards()) do
		card.saveIndex = i + 256
		cardTypeMapForSave[card.saveIndex] = card
	end
	for ci, character in ipairs(characters) do
		for i, card in ipairs(character:getCards()) do
			card.saveIndex = i + 256 * (ci + 1)
			cardTypeMapForSave[card.saveIndex] = card
		end
	end
end

---@type table<number,Relic>
local relicTypeMapForSave = nil
local function assignRelicIndex()
	if relicTypeMapForSave ~= nil then
		return
	end

	relicTypeMapForSave = {}
	for i, relic in ipairs(getColorlessRelics()) do
		relic.saveIndex = i
		relicTypeMapForSave[relic.saveIndex] = relic
	end
	for ci, character in ipairs(characters) do
		for i, relic in ipairs(character:getRelics()) do
			relic.saveIndex = i + 256 * (ci + 1)
			relicTypeMapForSave[relic.saveIndex] = relic
		end
	end
end

---@type table<number,Event>
local eventTypeMapForSave = nil
local function assignEventIndex()
	if eventTypeMapForSave ~= nil then
		return
	end

	eventTypeMapForSave = {}
	for i, event in ipairs(getCommonEvents()) do
		event.saveIndex = i
		eventTypeMapForSave[event.saveIndex] = event
	end
	for i, event in ipairs(getOneTimeEvents()) do
		event.saveIndex = i + 64
		eventTypeMapForSave[event.saveIndex] = event
	end
	for ai, act in ipairs(acts) do
		for i, event in ipairs(act.events) do
			event.saveIndex = i + 64 * (ai + 1)
			eventTypeMapForSave[event.saveIndex] = event
		end
	end
end

local eventRoomTypes = {'event','monster','shop','treasure','elite'}
function saveGame(completed,eventMeta)
	if #deck + #relics + #potions > 223 then
		trace('Save game: too many cards/relics/potions. Skip save.')
		return
	end

	local index = 0
	local playerId = table.indexOf(characters,getmetatable(player))
	local seedLower = seed & 0xffff
	pmem(index,playerId | (ascension << 8) | (seedLower << 16))
	pmem(index+1,seed >> 16)
	pmem(index+2,player.hp | (player.maxHp << 16))
	pmem(index+3,#relicPools.common | (#relicPools.uncommon << 8) | (#relicPools.rare << 16) | (#relicPools.shop << 24))
	pmem(index+4,#relicPools.boss | (floor << 8) | (gold << 16))
	pmem(index+5,maxEnergy | (shopRemoveCount << 8) | (rubyKeyObtained and (1<<16) or 0) |
		(emeraldKeyObtained and (1<<17) or 0) | (sapphireKeyObtained and (1<<18) or 0))
	saveListBits(index+6,oneTimeEvents,getOneTimeEvents())
	pmem(index+7,act.id | (nextMonsterEncounterIndex << 8) | (nextEliteEncounterIndex << 16) | (nextBossEncounterIndex << 24))
	saveListBits(index+8,actEvents,act.events)
	saveListBits(index+9,commonEvents,getCommonEvents())
	saveRewardGenerator(index+10)
	saveEventGenerator(index+11)
	pmem(index+12,currentRoomX | (currentRoomY << 8) | ((room.specialRoomId or 0) << 16))
	local pathVal = 0
	for i = 1,math.min(10,#playerPath) do
		pathVal = pathVal | (playerPath[i] << (i-1)*3)
	end
	pmem(index+13,pathVal)
	pathVal = 0
	for i = 11,#playerPath do
		pathVal = pathVal | (playerPath[i] << (i-11)*3)
	end
	pmem(index+14,pathVal)

	assignEventIndex()
	pmem(index+15,(completed and 1 or 0) | ((table.indexOf(eventRoomTypes,room.eventType) or 0) << 1) |
		((currentEvent and currentEvent.saveIndex or 0) << 4) | ((eventMeta or 0) << 16))

	pmem(index+16,#deck | (#relics << 16) | (#potions << 26))

	assignCardIndex()
	index = 17
	for _,card in ipairs(deck) do
		pmem(index, (card:save() << 12) | card.saveIndex)
		index = index + 1
	end
	assignRelicIndex()
	for _,relic in ipairs(relics) do
		pmem(index, (relic:save() << 12) | relic.saveIndex)
		index = index + 1
	end
	for _,potion in ipairs(potions) do
		if potion == PotionSlot then
			pmem(index,0)
		else
			pmem(index,table.indexOf(potionPool,getmetatable(potion)) or 0)
		end
		index = index + 1
	end
end

function clearSavedGame()
	pmem(0,0)
end

function loadGame()
	local index = 0
	local val32 = pmem(index)
	local playerId = val32 & 0xff
	player = characters[playerId]:new()
	ascension = (val32 >> 8) & 0xff
	seed = (val32 >> 16) & 0xffff
	seed = seed | (pmem(index+1) << 16)
	val32 = pmem(index+2)
	player.hp,player.maxHp = val32 & 0xffff,val32 >> 16
	relicPools = generateRelicPools(makeRand(0))
	potionPool = generatePotionPool()
	val32 = pmem(index+3)
	local num = val32 & 0xff
	table.retainIf(relicPools.common, function (_,i) return i<=num end)
	num = (val32 >> 8) & 0xff
	table.retainIf(relicPools.uncommon, function (_,i) return i<=num end)
	num = (val32 >> 16) & 0xff
	table.retainIf(relicPools.rare, function (_,i) return i<=num end)
	num = (val32 >> 24) & 0xff
	table.retainIf(relicPools.shop, function (_,i) return i<=num end)
	val32 = pmem(index+4)
	num = val32 & 0xff
	table.retainIf(relicPools.boss, function (_,i) return i<=num end)
	floor = (val32 >> 8) & 0xff
	gold = val32 >> 16
	val32 = pmem(index+5)
	maxEnergy = val32 & 0xff
	shopRemoveCount = (val32 >> 8) & 0xff
	rubyKeyObtained = val32 & (1<<16) ~= 0
	emeraldKeyObtained = val32 & (1<<17) ~= 0
	sapphireKeyObtained = val32 & (1<<18) ~= 0
	oneTimeEvents = loadListBits(index+6,getOneTimeEvents())
	inCombat = false

	-- act

	val32 = pmem(index+7)
	local actId = val32 & 0xff
	act = acts[actId]
	local mapRandom = makeRand(actId)
	stsMap,specialRooms = act:generateMap(mapRandom)
	monsterEncounters,eliteEncounters,bossEncounters = act:generateEncounters(mapRandom)
	nextMonsterEncounterIndex = (val32 >> 8) & 0xff
	nextEliteEncounterIndex = (val32 >> 16) & 0xff
	nextBossEncounterIndex = val32 >> 24
	actEvents = loadListBits(index+8,act.events)
	commonEvents = loadListBits(index+9,getCommonEvents())
	loadRewardGenerator(index+10)
	loadEventGenerator(index+11)
	val32 = pmem(index+12)
	currentRoomX = val32 & 0xff
	currentRoomY = (val32 >> 8) & 0xff
	local specialRoomId = (val32 >> 16) & 0xff

	playerPath = {}
	local pathVal = pmem(index+13)
	for _ = 1,10 do
		local v = pathVal & 0x7
		if v ~= 0 then
			table.insert(playerPath,v)
		end
		pathVal = pathVal >> 3
	end
	pathVal = pmem(index+14)
	for _ = 1,10 do
		local v = pathVal & 0x7
		if v ~= 0 then
			table.insert(playerPath,v)
		end
		pathVal = pathVal >> 3
	end
	for y, x in ipairs(playerPath) do
		stsMap[y][x].completed = true
	end

	assignEventIndex()
	val32 = pmem(index+15)
	local roomCompleted = val32 & 1 ~= 0
	local eventRoomType = eventRoomTypes[(val32 >> 1) & 0x7]
	local eventType = eventTypeMapForSave[(val32 >> 4) & 0xfff]
	local eventMeta = val32 >> 16

	-- other game

	val32 = pmem(index+16)
	local deckSize = val32 & 0xffff
	local relicSize = (val32 >> 16) & 0x3ff
	local potionCount = val32 >> 26

	assignCardIndex()
	deck = {}
	index = 17
	for i = 1,deckSize do
		val32 = pmem(index)
		local saveIndex = val32 & 0xfff
		local meta = val32 >> 12
		deck[i] = cardTypeMapForSave[saveIndex]:new()
		deck[i]:load(meta)
		index = index + 1
	end

	assignRelicIndex()
	relics = {}
	for i = 1,relicSize do
		val32 = pmem(index)
		local saveIndex = val32 & 0xfff
		local meta = val32 >> 12
		relics[i] = relicTypeMapForSave[saveIndex]:new()
		relics[i]:load(meta)
		index = index + 1
	end

	potions = {}
	for i = 1,potionCount do
		val32 = pmem(index)
		if val32 == 0 then
			potions[i] = PotionSlot
		else
			potions[i] = potionPool[val32]:new()
			potions[i]:applyPowers()
		end
		index = index + 1
	end

	-- load complete

	if floor == 0 then
		room = {id=0,x=0,y=0,previous={},next={},type=nil,completed=false}
		for _, nextRoom in ipairs(stsMap[1]) do
			table.insert(room.next,nextRoom)
		end
		roomActionType = 'event'
		currentEvent = NeowEvent:new()
	end
	cursorOnTopBar = false

	switchWindow(GameWindow:new())

	if floor ~= 0 then
		if specialRoomId ~= 0 then
			room = specialRooms[specialRoomId]
		else
			room = stsMap[currentRoomY][currentRoomX]
		end

		prepareRoom(roomCompleted and {eventRoomType=eventRoomType,eventType=eventType} or nil)

		if roomCompleted then
			if roomActionType == 'combat' then
				loadCombatEnd(eventMeta)
			elseif roomActionType == 'event' then
				currentEvent:load(eventMeta)
			end
		end
	end
end

function saveNoteForYourselfCard(card)
	assignCardIndex()
	pmem(255, (card:save() << 12) | card.saveIndex)
end

function loadNoteForYourselfCard()
	assignCardIndex()
	local val32 = pmem(255)
	if val32 == 0 then
		return IronWave:new()
	end

	local saveIndex = val32 & 0xfff
	local meta = val32 >> 12
	local card = cardTypeMapForSave[saveIndex]:new()
	card:load(meta)
	return card
end
