-- utils
---@diagnostic disable: lowercase-global

function strWidth(str,fixed,small,scale)
	scale = scale or 1
	return print(str,0,-8*scale,0,fixed,scale,small)
end

function printColorStr(str,x,y,small,color,lockColor)
	color = lockColor or color or 12
	local originalX = x
	local originalColor = color
	local lastStart = 1
	local findStart,findEnd,findStr = str:find('(#%d+#)',lastStart)
	while findStart and findEnd and findStr do
		x = x + print(str:sub(lastStart,findStart-1),x,y,color,false,1,small)
		if lockColor == nil then
			local colorStr = findStr:sub(2,#findStr-1)
			color = #colorStr == 0 and originalColor or tonumber(colorStr) or color
		end
		lastStart = findEnd+1
		findStart,findEnd,findStr = str:find('(#%d+#)',lastStart)
	end
	x = x + print(str:sub(lastStart),x,y,color,false,1,small)
	return x - originalX
end

function printShadowed(str,x,y,color,shadowColor,scale,small)
	scale = scale or 1
	print(str,x+1,y+1,shadowColor or 15,false,scale,small)
	print(str,x,y,color,false,scale,small)
end

function printGlowed(str,x,y,color,glowColor,scale,smallFont)
	scale = scale or 1
	print(str,x+1,y,glowColor or 15,false,scale,smallFont)
	print(str,x-1,y,glowColor or 15,false,scale,smallFont)
	print(str,x,y-1,glowColor or 15,false,scale,smallFont)
	print(str,x,y+1,glowColor or 15,false,scale,smallFont)
	return print(str,x,y,color,false,scale,smallFont)
end

function drawTalkBubble(str,x,y,w,h,tx,ty,color,textColor)
	color = color or 12
	color = color or 15
	if w > h then
		circ(x+h/2,y+h/2,h/2,color)
		circ(x+w-h/2,y+h/2,h/2,color)
		rect(x+h/2,y,w-h,h,color)
	else
		circ(x+w/2,y+w/2,w/2,color)
		circ(x+w/2,y+h-w/2,w/2,color)
		rect(x,y+w/2,w,h-w,color)
	end
	local cx,cy = x+w/2,y+h/2
	local d = math.atan(ty-cy,tx-cx)
	tri(cx+w/3*math.cos(d-0.4),cy+h/3*math.sin(d-0.4),
		cx+w/3*math.cos(d+0.4),cy+h/3*math.sin(d+0.4),
		tx,ty,
		color)
	local tw,th = drawDescription(nil,str,-w*2,0,w,999,textColor)
	drawDescription(nil,str,x+(w-tw)/2,y+(h-th)/2+2,w,999,textColor)
end

function limit(num,min,max)
	if min > max then return nil end
	if num < min then return min end
	if num > max then return max end
	return num
end

function shallowcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key,orig_value in pairs(orig) do
			copy[orig_key] = orig_value
		end
	else -- number,string,boolean,etc
		copy = orig
	end
	return copy
end

function lerp(from,to,progress,threshold)
	threshold = threshold or 1
	if math.abs(from - to) < threshold then
		return to
	end
	return from * (1 - progress) + to * progress
end

function drawSelectionBox(x,y,w,h,color,l)
	color = color or 4
	l = l or 3
	line(x,y,x+l,y,color)
	line(x,y,x,y+l,color)
	line(x+w-1,y,x+w-l-1,y,color)
	line(x+w-1,y,x+w-1,y+l,color)
	line(x+w-1,y+h-1,x+w-l-1,y+h-1,color)
	line(x+w-1,y+h-1,x+w-1,y+h-l-1,color)
	line(x,y+h-1,x+l,y+h-1,color)
	line(x,y+h-1,x,y+h-l-1,color)
end

function drawBezier(count,x0,y0,x1,y1,x2,y2)
	for i = 1,count-1 do
		local t = i / count
		local a = (1-t)^2
		local b = 2*t*(1-t)
		local c = t^2
		local x = math.floor(a*x0 + b*x1 + c*x2 + 0.5)
		local y = math.floor(a*y0 + b*y1 + c*y2 + 0.5)
		rect(x-2,y-2,4,4,2)
		rectb(x-2,y-2,4,4,1)
	end
end

function drawItemTooltip(item,x,y,width,bottomAlign)
	width = width or 10
	local _,h = drawDescription(item,item.description,-80,0,(width-1)*8,999,12)
	local boxX = math.min(x,240-width*8)
	if bottomAlign then
		y = y-math.floor(h/8+2.5)*8
	end
	drawTooltipBox(boxX,y,width,math.floor(h/8+2.5))
	print(item.name,boxX+4,y+4,4,false,1,true)
	drawDescription(item,item.description,boxX+4,y+14,(width-1)*8,999,12)
end

function drawTooltipBox(x,y,w,h)
	spr(83,x,y,0,1,2)
	spr(83,x+w*8-8,y,0,1,3)
	spr(83,x+w*8-8,y+h*8-8,0,1,1)
	spr(83,x,y+h*8-8,0,1,0)
	rect(x,y+8,w*8,h*8-16,14)
	rect(x+8,y,w*8-16,8,14)
	rect(x+8,y+h*8-8,w*8-16,8,14)
	line(x,y+8,x,y+h*8-9,15)
	line(x+w*8-1,y+8,x+w*8-1,y+h*8-9,15)
	line(x+8,y,x+w*8-9,y,15)
	line(x+8,y+h*8-1,x+w*8-9,y+h*8-1,15)
end

function drawBanner(x,y,w)
	spr(480,x,y,0,1,0,0,3,2)
	spr(480,x+(w-3)*8,y,0,1,1,0,3,2)
	rect(x+24,y,(w-6)*8,11,4)
	rect(x+24,y+11,(w-6)*8,1,3)
end

function sprmap(x, y, w, h, sx, sy, colorkey, scale, remap)
	poke4(2*0x03FFC,3)
	map(x, y, w, h, sx, sy, colorkey or -1, scale or 1, remap or nil)
	poke4(2*0x03FFC,2)
end

function flipRemap(x,w)
	return function (_,x0,y)
		return mget(x+w-1-(x0-x),y),1
	end
end

isDarken = false
local darkenColorList = {0,0,15,14,14,14,15,0,15,15,14,14,14,14,15,0}
--{0,0,1,2,3,6,7,0,1,15,9,10,13,14,15,0}
function mapColor(from,to)
	poke4(PALETTE_MAP*2+from,isDarken and darkenColorList[to+1] or to)
end

function mapColors(...)
	local args = {...}
	for i = 0,math.min(#args-1,15) do
		poke4(PALETTE_MAP*2+i,isDarken and darkenColorList[args[i+1]+1] or args[i+1])
	end
end

function darkenColors()
	mapColors(table.unpack(darkenColorList))
	isDarken = true
end

function greyColors()
	mapColors(0,15,14,13,12,13,14,15,13,14,13,12,12,13,14,15)
end

function resetColor(color)
	mapColor(color,color)
end

function resetColors(colors)
	if colors == nil then
		isDarken = false
		for i = 0,8 do
			poke(PALETTE_MAP+i,i*2+(i*2+1)*16)
		end
	else
		for _, color in ipairs(colors) do
			resetColor(color)
		end
	end
end

local syncCache = {0,0,0,0,0,0,0}
local function syncCacheSetCompare(mask,bank)
	local same = true
	for i=1,7 do
		if mask&1 == 1 and syncCache[i] ~= bank then
			syncCache[i] = bank
			same = false
		end
		mask=mask>>1
	end
	return not same
end

local syncQueue = {}
local hasSync = false
function queueSync(mask,bank)
	if not hasSync then
		if syncCacheSetCompare(mask,bank) then
			trace('sync ' .. mask .. ' ' .. bank)
			sync(mask,bank)
			hasSync = true
		else
			trace('sync cached ' .. mask .. ' ' .. bank)
		end
		return
	end
	trace('queuesync ' .. mask .. ' ' .. bank)
	table.insert(syncQueue,table.pack(mask,bank))
end

function doSync()
	while #syncQueue > 0 do
		local mask,bank = table.unpack(table.remove(syncQueue,1))
		if syncCacheSetCompare(mask,bank) then
			trace('sync ' .. mask .. ' ' .. bank)
			sync(mask,bank)
			break
		else
			trace('sync cached ' .. mask .. ' ' .. bank)
		end
	end
	hasSync = #syncQueue > 0
end

function makeRand(actId,roomId,index)
	actId = actId or 0
	roomId = roomId or 0
	index = index or 0
	return Random:new(seed+10000*actId+20*roomId+2*index)
end

function placeCardsInARow(amount)
	local startX,stepX
	if amount <= 5 then
		startX = 120-(amount*48-48)/2-48
		stepX = 48
	else
		stepX = 192/(amount-1)
		startX = 24-stepX
	end
	return startX,stepX
end

function normalize(list,key)
	key = key or 'power'
	local sum = 0
	for _, item in ipairs(list) do
		sum = sum + item[key]
	end
	for _, item in ipairs(list) do
		item[key] = item[key]/sum
	end
end

function rollList(random,list,key)
	key = key or 'power'
	local sum = 0
	local roll = random:rand()
	for i,item in ipairs(list) do
		sum = sum + item[key]
		if sum >= roll then
			return item,i
		end
	end
	return list[#list],#list
end

function noop() end

-- table

function table:indexOf(item)
	for index, value in ipairs(self) do
		if value == item then
			return index
		end
	end
	return nil
end

function table:allMatch(condition)
	for _, value in ipairs(self) do
		if not condition(value) then
			return false
		end
	end
	return true
end

function table:anyMatch(condition)
	for _, value in ipairs(self) do
		if condition(value) then
			return true
		end
	end
	return false
end

function table:retainIf(condition)
	for i = #self,1,-1 do
		if not condition(self[i],i) then
			table.remove(self,i)
		end
	end
end

function table:map(func)
	local r = {}
	for index, value in ipairs(self) do
		table.insert(r,func(value,index))
	end
	return r
end

function table:count(condition)
	local count = 0
	for _, value in ipairs(self) do
		if condition(value) then
			count = count + 1
		end
	end
	return count
end

-- selection

function keepCurrentIndexInTableIf(table,currentIndex,condition)
	currentIndex = limit(currentIndex,1,#table)
	if currentIndex == nil then
		return 0
	end
	if condition(currentIndex) then
		return currentIndex
	end
	return previousOrOtherIndexInTableIf(table,currentIndex,condition)
end

function previousOrOtherIndexInTableIf(table,currentIndex,condition)
	local previous = previousIndexInTableIf(table,currentIndex,condition)
	if previous == 0 then
		return nextIndexInTableIf(table,currentIndex,condition)
	end
	return previous
end

function nextOrOtherIndexInTableIf(table,currentIndex,condition)
	local next = nextIndexInTableIf(table,currentIndex,condition)
	if next == 0 then
		return previousIndexInTableIf(table,currentIndex,condition)
	end
	return next
end

function previousIndexInTableIf(table,currentIndex,condition)
	currentIndex = limit(currentIndex,1,#table)
	if currentIndex == nil then
		return 0
	end
	local condition = condition or function () return true end
	local previousIndex = currentIndex
	repeat
		previousIndex = previousIndex - 1
	until previousIndex < 1 or condition(previousIndex,table)
	if previousIndex < 1 then
		if not condition(currentIndex,table) then
			return 0
		end
		return currentIndex
	end
	return previousIndex
end

function nextIndexInTableIf(table,currentIndex,condition)
	if currentIndex == 0 and #table > 0 and condition(1,table) then
		return 1
	end
	currentIndex = limit(currentIndex,1,#table)
	if currentIndex == nil then
		return 0
	end
	local condition = condition or function () return true end
	local nextIndex = currentIndex
	repeat
		nextIndex = nextIndex + 1
	until nextIndex > #table or condition(nextIndex,table)
	if nextIndex > #table then
		if not condition(currentIndex,table) then
			return 0
		end
		return currentIndex
	end
	return nextIndex
end

-- objects

Object = {}
function Object:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Object:copy()
	local result = shallowcopy(self)
	setmetatable(result,getmetatable(self))
	return result
end

-- random
local A1, A2 = 727595, 798405  -- 5^17=D20*A1+A2
local D20, D40 = 1048576, 1099511627776  -- 2^20, 2^40

Random = Object:new{x1=0,x2=1}
function Random:new(seed,x2)
	seed = math.floor(seed or tstamp())
	local x1 = seed
	if x2 == nil then
		x1 = math.floor(seed/D20)
		x2 = seed - x1*D20
	end
	x1 = x1 % D20
	x2 = x2 % D20
	x2 = math.floor(x2/2)*2+1
	return Object.new(self,{x1=x1,x2=x2})
end

function Random:randRaw()
	local x1 = self.x1
	local x2 = self.x2
	local u = x2*A2
	local v = (x1*A2 + x2*A1) % D20
	v = (v*D20 + u) % D40
	self.x1 = math.floor(v/D20)
	self.x2 = v - self.x1*D20
	return v
end

function Random:rand()
	return self:randRaw()/D40
end

function Random:randInt(from,to)
	if to == nil then
		to = from
		from = 1
	end
	if from == to then
		return to
	end
	return math.floor(self:rand() * (to-from+1)) + from
end

function Random:randFloat(from,to)
	return self:rand() * (to-from) + from
end

function Random:randBool()
	return self:rand() > 0.5
end

function Random:shuffle(array)
	for i = #array,1,-1 do
		local j = self:randInt(i)
		array[i],array[j] = array[j],array[i]
	end
end
