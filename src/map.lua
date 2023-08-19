-- map
---@diagnostic disable: lowercase-global

mapScreenAvailableSelections = {}
mapScreenX = 0
mapScreenY = 1
mapScreenSelectionMode = false

MapWindow = Window:new{name='MapWindow',scroll=0,scrollSpeed=0,maxScroll=440,bossPosition=-424,bossY=16,canClose=true}
function MapWindow:onOpen()
	queueSync(1,1)
	queueSync(2,0)

	local height = #stsMap
	self.bossPosition = 56-height*32
	self.maxScroll = 16-self.bossPosition
	self.bossY = height+1
	self.scroll = limit(mapScreenY*32-80,0,self.maxScroll)
end

function MapWindow:tick()
	cls(0)
	self:drawMap(self.scroll)
	tickEffects()
	self:mapControls()
	tickTopBar(true)
end

local roomIconMap = {event=303,monster=285,rest=301,treasure=302,shop=317,elite=286,strongElite=287}
function MapWindow:drawMap(y)
	local backgroundOffset = y % 8
	for i = 0,16 do
		sprmap(0,1,30,1,0,i*8+backgroundOffset,0)
	end
	if stsMap == nil then
		return
	end
	if mapScreenSelectionMode then
		mapColor(15,13)
	end
	for i = 1,#stsMap do
		for j = 1,#stsMap[i] do
			local room = stsMap[i][j]
			if room.hasEdge then
				self:drawRoom(room,20+(j-1)*32,112-(i-1)*32+y)
			end
		end
	end
	local bossDrawY = y+self.bossPosition
	if self.bossY <= currentRoomY then
		resetColor(15)
	end
	if y > -64 then
		if (mapScreenY == self.bossY and mapScreenSelectionMode) or
			(currentRoomY == self.bossY and not mapScreenSelectionMode) then
			drawSelectionBox(88-2,bossDrawY-2,68,68,15)
		end
		spr(bossEncounters[nextBossEncounterIndex].mapIcon or 257,88,bossDrawY,12,2,0,0,4,4)
	end
	resetColor(15)
end

function MapWindow:mapControls()
	self:scrollMapControl()
	self:selectMapControl()
end

function MapWindow:scrollMapControl()
	if cursorOnTopBar then
		self.scrollSpeed = self.scrollSpeed*0.8
	elseif btn(0) then
		self.scrollSpeed = limit(self.scrollSpeed+1,-4,4) or 0
	elseif btn(1) then
		self.scrollSpeed = limit(self.scrollSpeed-1,-4,4) or 0
	else
		self.scrollSpeed = self.scrollSpeed*0.8
	end
	self.scroll = self.scroll + self.scrollSpeed
	if self.scroll < 0 then
		self.scroll = 0
	elseif self.scroll > self.maxScroll then
		self.scroll = self.maxScroll
	end
end

function MapWindow:selectMapControl()
	if cursorOnTopBar then
		mapScreenX = 0
		return
	end

	if btnp(5) and self.canClose then
		self:close()
		return
	end

	if not mapScreenSelectionMode or mapScreenY < 1 or mapScreenY > self.bossY then
		return
	end

	if mapScreenY == self.bossY then
		mapScreenX = 1
	else
		local function validRoom(i) return stsMap[mapScreenY][i].hasEdge and table.indexOf(mapScreenAvailableSelections,i) end
		if mapScreenX == 0 then
			mapScreenX = nextOrOtherIndexInTableIf(stsMap[mapScreenY],mapScreenX,validRoom)
		end

		if btnp(2) then
			mapScreenX = previousOrOtherIndexInTableIf(stsMap[mapScreenY],mapScreenX,validRoom)
		elseif btnp(3) then
			mapScreenX = nextOrOtherIndexInTableIf(stsMap[mapScreenY],mapScreenX,validRoom)
		end
	end

	if btnp(4) then
		enterRoom(mapScreenX)
	end
end

local function rightEdge(rx,ry)
	spr(288,rx+12,ry-12,12)
	spr(288,rx+20,ry-20,12)
end

local function leftEdge(rx,ry)
	spr(288,rx-12,ry-12,12,1,1)
	spr(288,rx-20,ry-20,12,1,1)
end

local function middleEdge(rx,ry)
	spr(272,rx,ry-12,12)
	spr(272,rx,ry-20,12)
end

function MapWindow:drawRoom(room,rx,ry)
	if ry > -10 and ry < 160 then
		local inPlayerPath = room.y <= #playerPath and playerPath[room.y] == room.x
		if inPlayerPath or (room.y == mapScreenY and table.indexOf(mapScreenAvailableSelections,room.x)) then
			mapColor(15,15)
		elseif mapScreenSelectionMode then
			mapColor(15,13)
		end
		if room.hasKey and room.type == 'elite' then
			spr(roomIconMap.strongElite,rx,ry,12)
		else
			spr(roomIconMap[room.type] or 503,rx,ry,12)
		end
		if (mapScreenSelectionMode and room.x == mapScreenX and room.y == mapScreenY) or
			(not mapScreenSelectionMode and room.x == currentRoomX and room.y == currentRoomY) then
			drawSelectionBox(rx-2,ry-2,12,12,15)
		end
		if room.completed then
			spr(304,rx+4,ry+6,12)
		end
		if room.y == 15 then
			if room.x <= 2 then
				rightEdge(rx,ry)
			elseif room.x <= 5 then
				middleEdge(rx,ry)
			else
				leftEdge(rx,ry)
			end
		else
			for _, nextRoom in ipairs(room.next) do
				if mapScreenSelectionMode then
					if inPlayerPath and ((nextRoom.y <= #playerPath and playerPath[nextRoom.y] == nextRoom.x) or
						(nextRoom.y == mapScreenY and table.indexOf(mapScreenAvailableSelections,nextRoom.x))) then
						mapColor(15,15)
					else
						mapColor(15,13)
					end
				end
				if nextRoom.x > room.x then
					rightEdge(rx,ry)
				elseif nextRoom.x < room.x then
					leftEdge(rx,ry)
				else
					middleEdge(rx,ry)
				end
			end
		end
	end
end

-- generate

function generateMap(random,width,height,count)
	local map = {}
	for i=1,height do
		map[i] = {}
		for j=1,width do
			local room = {id=(i-1)*width+j,x=j,y=i,previous={},next={},type=nil,hasEdge=false,hasKey=false,completed=false}
			if i == 1 then
				room.type = 'monster'
			elseif i == height then
				room.type = 'rest'
			elseif i == 9 then
				room.type = 'treasure'
			end
			map[i][j] = room
		end
	end

	local rows = {}
	for i=1,width do rows[i] = i end
	random:shuffle(rows)
	for i=1,count do
		if i <= 2 then
			generatePath(random,map,rows[i],width,height)
		else
			generatePath(random,map,random:randInt(width),width,height)
		end
	end

	local unassignedRooms = {}
	for i=height,1,-1 do
		for j=1,width do
			local room = map[i][j]
			if room.hasEdge and room.type == nil then
				table.insert(unassignedRooms,room)
			end
		end
	end

	local shopCount = math.floor(#unassignedRooms*0.05+0.5)
	local restCount = math.floor(#unassignedRooms*0.12+0.5)
	local eliteCount = math.floor(#unassignedRooms*0.08*(ascension>=1 and 1.6 or 1)+0.5)
	local eventCount = math.floor(#unassignedRooms*0.22+0.5)
	local monsterCount = #unassignedRooms-shopCount-restCount-eliteCount-eventCount

	local roomPool = {}
	for _=1,shopCount do table.insert(roomPool,'shop') end
	for _=1,restCount do table.insert(roomPool,'rest') end
	for _=1,eliteCount do table.insert(roomPool,'elite') end
	for _=1,eventCount do table.insert(roomPool,'event') end
	for _=1,monsterCount do table.insert(roomPool,'monster') end

	random:shuffle(roomPool)
	assignRooms(unassignedRooms,roomPool)
	if not emeraldKeyObtained then
		local eliteRooms = {}
		for i=height,1,-1 do
			for j=1,width do
				local room = map[i][j]
				if room.hasEdge and room.type == 'elite' then
					table.insert(eliteRooms,room)
				end
			end
		end
		if #eliteRooms > 0 then
			eliteRooms[random:randInt(#eliteRooms)].hasKey = true
		end
	end

	local bossRoom = {id=height*width+1,x=1,y=height+1,previous={},next={},type='boss',hasEdge=false,completed=false}
	for j=1,width do
		local room = map[height][j]
		if room.hasEdge then
			addMapEdge(room,bossRoom)
		end
	end
	local bossTreasureRoom = {id=height*width+2,x=1,y=height+2,previous={},next={},type='bossTreasure',hasEdge=false,completed=false}
	addMapEdge(bossRoom,bossTreasureRoom)

	local otherRooms = {bossRoom,bossTreasureRoom}
	for i, room in ipairs(otherRooms) do
		room.specialRoomId = i
	end

	return map,otherRooms
end

function generatePath(random,map,startX,width,height)
	local currentRoom = map[1][startX]
	local currentX = startX
	for i = 2, height do
		local nextX
		local nextRoom
		repeat
			nextX = random:randInt(limit(currentX-1,1,width),limit(currentX+1,1,width))
			nextRoom = map[i][nextX]
		until (nextX == currentX or table.indexOf(map[i-1][nextX].next,map[i][currentX]) == nil) and
			(i ~= height or (nextX > 1 and nextX < width))
		addMapEdge(currentRoom,nextRoom)
		currentRoom = nextRoom
		currentX = nextX
	end
end

function addMapEdge(currentRoom,nextRoom)
	if table.indexOf(currentRoom.next,nextRoom) == nil then
		table.insert(currentRoom.next,nextRoom)
		table.insert(nextRoom.previous,currentRoom)
		currentRoom.hasEdge, nextRoom.hasEdge = true, true
	end
end

function assignRooms(unassignedRooms,roomPool)
	repeat
		local hasChanged = false
		for i = #unassignedRooms,1,-1 do
			local room = unassignedRooms[i]
			for j = #roomPool,1,-1 do
				if canAssignRoom(room,roomPool[j]) then
					room.type = roomPool[j]
					table.remove(unassignedRooms,i)
					table.remove(roomPool,j)
					hasChanged = true
					break
				end
			end
		end
	until #unassignedRooms == 0 or not hasChanged

	for _, room in ipairs(unassignedRooms) do
		room.type = 'monster'
	end
end

function canAssignRoom(room,roomType)
	if (roomType == 'elite' or roomType == 'rest') and room.y <= 5 then
		return false
	end
	if roomType == 'rest' and room.y >= 14 then
		return false
	end
	if roomType == 'elite' or roomType == 'rest' or roomType == 'shop' then
		for _, previousRoom in ipairs(room.previous) do
			if previousRoom.type == roomType then
				return false
			end
		end
	end
	for _, previousRoom in ipairs(room.previous) do
		for _, siblingRoom in ipairs(previousRoom.next) do
			if siblingRoom ~= room and siblingRoom.type == roomType then
				return false
			end
		end
	end
	return true
end