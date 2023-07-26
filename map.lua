-- map
---@diagnostic disable: lowercase-global

local mapScreenScroll = 0
local mapScreenScrollSpeed = 0
local mapTop = 440
local bossPosition = -424
local bossY = 16
mapScreenAvailableSelections = {1,2,3,4,5,6,7}
mapScreenX = 0
mapScreenY = 1
mapScreenSelectionMode = true
function mapScreen()
	cls(0)
	drawMap(mapScreenScroll)
	drawTopBar()
	scrollMapControl()
	selectMapControl()
end

local roomIconMap = {event=503,monster=499,rest=501,treasure=502,shop=504,elite=500,strongElite=507}
function drawMap(y)
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
				drawRoom(room,20+(j-1)*32,112-(i-1)*32+y)
			end
		end
	end
	local bossDrawY = y+bossPosition
	if bossY <= #playerPath then
		resetColor(15)
	end
	if y > -64 then
		spr(257,88,bossDrawY,12,2,0,0,4,4)
	end
	resetColor(15)
end

function scrollMapControl()
	if btn(0) then
		mapScreenScrollSpeed = limit(mapScreenScrollSpeed+1,-4,4) or 0
	elseif btn(1) then
		mapScreenScrollSpeed = limit(mapScreenScrollSpeed-1,-4,4) or 0
	else
		mapScreenScrollSpeed = mapScreenScrollSpeed*0.8
	end
	mapScreenScroll = mapScreenScroll + mapScreenScrollSpeed
	if mapScreenScroll < 0 then
		mapScreenScroll = 0
	elseif mapScreenScroll > mapTop then
		mapScreenScroll = mapTop
	end
end

function selectMapControl()
	if not mapScreenSelectionMode or mapScreenY < 1 or mapScreenY > bossY then
		return
	end

	if mapScreenY == bossY then
		mapScreenX = 1
		return
	end

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

local function rightEdge(rx,ry)
	spr(506,rx+12,ry-12,12)
	spr(506,rx+20,ry-20,12)
end

local function leftEdge(rx,ry)
	spr(506,rx-12,ry-12,12,1,1)
	spr(506,rx-20,ry-20,12,1,1)
end

local function middleEdge(rx,ry)
	spr(505,rx,ry-12,12)
	spr(505,rx,ry-20,12)
end

function drawRoom(room,rx,ry)
	if ry > -10 and ry < 160 then
		local inPlayerPath = room.y <= #playerPath and playerPath[room.y] == room.x
		if inPlayerPath or (room.y == mapScreenY and table.indexOf(mapScreenAvailableSelections,room.x)) then
			mapColor(15,15)
		elseif mapScreenSelectionMode then
			mapColor(15,13)
		end
		spr(roomIconMap[room.type] or 503,rx,ry,12)
		if (mapScreenSelectionMode and room.x == mapScreenX and room.y == mapScreenY) or
			(not mapScreenSelectionMode and room.x == currentRoomX and room.y == currentRoomY) then
			drawSelectionBox(rx-2,ry-2,12,12,15)
		end
		if room.completed then
			spr(508,rx+4,ry+6,12)
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
					if nextRoom.y <= #playerPath and playerPath[nextRoom.y] == nextRoom.x then
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
			local room = {id=(i-1)*width+j-1,x=j,y=i,previous={},next={},type=nil,hasEdge=false,completed=false}
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
	local eliteCount = math.floor(#unassignedRooms*0.08+0.5)
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
	bossPosition = 56-height*32
	mapTop = 16-bossPosition
	bossY = height+1

	local bossRoom = {id=height*width,x=1,y=bossY,previous={},next={},type=nil,hasEdge=false,completed=false}
	for j=1,width do
		local room = map[height][j]
		if room.hasEdge then
			addMapEdge(room,bossRoom)
		end
	end

	return map
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
	if (roomType == 'elite' or roomType == 'rest') and (room.y <= 5 or room.y >= 14) then
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